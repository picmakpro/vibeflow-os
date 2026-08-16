#!/usr/bin/env bash
# vibeflow-update.sh — Installeur/updateur scope-aware des modules vibeflow-os.
#
# Usage:
#   ./vibeflow-update.sh [--scope user|project|local] install <module>      # Installe un module
#   ./vibeflow-update.sh [--scope ...] install --with-deps <module>         # Installe la fermeture transitive
#   ./vibeflow-update.sh [--scope ...] install --all                        # Installe tous les modules dispo
#   ./vibeflow-update.sh [--scope ...] update <module>                      # Met à jour un module installé
#   ./vibeflow-update.sh [--scope ...] update --all                         # Met à jour tous les modules installés
#   ./vibeflow-update.sh [--scope ...] uninstall <module>                   # Désinstalle un module
#   ./vibeflow-update.sh [--scope ...] uninstall --all                      # Désinstalle TOUS les modules installés (lit le registre)
#   ./vibeflow-update.sh [--scope ...] rollback <module>                    # Restore depuis backup
#   ./vibeflow-update.sh [--scope ...] status                               # Liste modules installés + versions
#   ./vibeflow-update.sh sync                                               # No-op (source = cache, plus de git)
#
# Source : le cache local fourni par l'appelant (VIBEFLOW_CACHE, défaut .vibeflow-cache).
#   Plus de clone/pull git : le cache DOIT exister (sinon erreur). En prod, c'est le skill
#   /vibeflow-install (Phase 4) qui prépare le cache à partir du plugin packagé (Phase 5).
#
# Scope (cible d'install, spec §3) :
#   --scope user            → $HOME/.claude
#   --scope project | local → ./.claude   (local ajoute en plus les chemins au ./.gitignore)
#   env VF_SCOPE            → idem ; --scope l'emporte sur VF_SCOPE.
#
# Pré-requis : $VIBEFLOW_CACHE existe (dossier des modules + leurs module.json).

set -euo pipefail

# ---------- Helpers (définis tôt : utilisés dès le parsing) ----------
log() { echo "[vibeflow-update] $*" >&2; }
err() { echo "[vibeflow-update] ERROR: $*" >&2; exit 1; }

# ---------- Résolution du scope → TARGET_ROOT (SCOPE-01) ----------
# Défaut LEGACY = `project` (cible historique ./.claude). C'est un fallback APPEL-DIRECT
# (debug, run manuel, tests). EN PROD le skill /vibeflow-install (Phase 4) passe TOUJOURS un
# VF_SCOPE explicite à l'engine ET à ensure-deps.sh (un seul scope partout — cohérence ID4,
# spec §3/§8). Ce défaut engine `project` ne co-occurre donc JAMAIS en prod avec le défaut
# LEGACY `user` de ensure-deps.sh : pas de contradiction entre 03-01 et 03-02.
VF_SCOPE="${VF_SCOPE:-project}"

# Détecter `--scope <val>` AVANT cmd="$1" : on filtre les positionnels et on override VF_SCOPE.
_positional=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --scope)
      [ "$#" -ge 2 ] || err "--scope nécessite une valeur (user|project|local)"
      VF_SCOPE="$2"
      shift 2
      ;;
    --scope=*)
      VF_SCOPE="${1#--scope=}"
      shift
      ;;
    *)
      _positional+=("$1")
      shift
      ;;
  esac
done
# Restaurer les positionnels nettoyés (set -u : guard tableau vide).
if [ "${#_positional[@]}" -gt 0 ]; then
  set -- "${_positional[@]}"
else
  set --
fi

# Validation stricte : rejette tôt toute valeur incohérente.
case "$VF_SCOPE" in
  user|project|local) : ;;
  *) err "scope invalide : $VF_SCOPE (attendu user|project|local)" ;;
esac

# Résolution TARGET_ROOT depuis le scope.
case "$VF_SCOPE" in
  user)            TARGET_ROOT="$HOME/.claude" ;;
  project|local)   TARGET_ROOT="./.claude" ;;
esac
export VF_SCOPE

# ---------- Variables (toutes les cibles rebasées sur TARGET_ROOT) ----------
CACHE_DIR="${VIBEFLOW_CACHE:-.vibeflow-cache}"   # SEULE source (plus de clone)
INSTALLED_REGISTRY="$TARGET_ROOT/scripts/.vibeflow-installed"
BACKUP_DIR="$TARGET_ROOT/.backups"

# ---------- Cache (SCOPE-02 : plus de clone/pull, le cache doit exister) ----------
require_cache() {
  [ -d "$CACHE_DIR" ] || err "Cache introuvable : $CACHE_DIR (fournir VIBEFLOW_CACHE)"
}

list_available_modules() {
  require_cache
  for d in "$CACHE_DIR"/*/; do
    name=$(basename "$d")
    [ "$name" = "_internal" ] && continue
    if [ -f "${d}VERSION" ]; then
      echo "$name"
    fi
  done
}

module_version_available() {
  local mod="$1"
  cat "$CACHE_DIR/$mod/VERSION" 2>/dev/null || echo "—"
}

module_version_installed() {
  local mod="$1"
  if [ -f "$INSTALLED_REGISTRY" ]; then
    grep "^$mod=" "$INSTALLED_REGISTRY" 2>/dev/null | cut -d= -f2 || echo "—"
  else
    echo "—"
  fi
}

mark_installed() {
  local mod="$1"
  local version="$2"
  mkdir -p "$(dirname "$INSTALLED_REGISTRY")"
  touch "$INSTALLED_REGISTRY"
  # Remove old entry if exists
  grep -v "^$mod=" "$INSTALLED_REGISTRY" > "${INSTALLED_REGISTRY}.tmp" 2>/dev/null || true
  echo "$mod=$version" >> "${INSTALLED_REGISTRY}.tmp"
  mv "${INSTALLED_REGISTRY}.tmp" "$INSTALLED_REGISTRY"
}

mark_uninstalled() {
  local mod="$1"
  if [ -f "$INSTALLED_REGISTRY" ]; then
    grep -v "^$mod=" "$INSTALLED_REGISTRY" > "${INSTALLED_REGISTRY}.tmp" || true
    mv "${INSTALLED_REGISTRY}.tmp" "$INSTALLED_REGISTRY"
  fi
}

# ---------- Manifeste de pose (D-31-01/02/03, Phase 31 vague TRACER) ----------
# Le manifeste est le SOUS-PRODUIT de la pose : vf_place_file écrit ET consigne dans le même
# appel (via vf_record), jamais une énumération séparée du cache (Pitfall 1, 31-RESEARCH.md).
# Format : un chemin par ligne, relatif à TARGET_ROOT, LF, trié LC_ALL=C, jamais de répertoire.

vf_manifest_path() {
  local mod="$1"
  echo "$TARGET_ROOT/scripts/.vibeflow-manifest-$mod"
}

# Liste close des artefacts qu'un module NE possède PAS exclusivement (D-31-03). Point UNIQUE
# de définition — ne jamais dupliquer ces motifs ailleurs dans le fichier.
vf_manifest_excluded() {
  local relpath="$1"
  case "$relpath" in
    scripts/vf-portable.sh)       return 0 ;;  # propriété exclusive de l'engine (copy_engine_lib), partagée entre modules
    memory/*)                     return 0 ;;  # contenu vivant du lab semé par seed-registres.sh, pas un artefact de pose
    scripts/.vibeflow-installed)  return 0 ;;  # état du moteur, pas contenu de module
    scripts/.vibeflow-manifest-*) return 0 ;;  # le manifeste ne se consigne jamais lui-même (boucle de convergence)
    .backups/*)                   return 0 ;;  # filet de sécurité, jamais candidat à suppression automatique
  esac
  return 1
}

# Réduction textuelle des segments "." / ".." / "//" — SANS realpath (ADR-054 l'interdit).
# Implémentation privée de vf_rel_to_target, pas un des 7 points d'API du socle manifeste.
_vf_normalize_path() {
  local path="$1"
  local abs=0
  case "$path" in
    /*) abs=1 ;;
  esac
  local seg result i n=0
  local -a out=()
  local IFS=/
  set -f
  local -a parts
  parts=($path)
  set +f
  unset IFS
  for seg in "${parts[@]}"; do
    case "$seg" in
      ""|".") continue ;;
      "..")
        if [ "$n" -gt 0 ]; then
          n=$((n - 1))
        fi
        ;;
      *)
        out[$n]="$seg"
        n=$((n + 1))
        ;;
    esac
  done
  result=""
  i=0
  while [ "$i" -lt "$n" ]; do
    result="$result/${out[$i]}"
    i=$((i + 1))
  done
  if [ "$abs" -eq 1 ]; then
    [ -n "$result" ] || result="/"
    printf '%s\n' "$result"
  else
    printf '%s\n' "${result#/}"
  fi
}

# Normalise <chemin_dest> et émet sa forme relative à TARGET_ROOT sur stdout ; rc=1 si le
# chemin ne résout PAS sous TARGET_ROOT (cas docs/<mod>/, 636-641, hors manifeste par D-31-03 —
# ce n'est pas une erreur, ce chemin sort du manifeste, pas de la pose).
vf_rel_to_target() {
  local dest="$1"
  local norm_dest norm_target
  norm_dest="$(_vf_normalize_path "$dest")"
  norm_target="$(_vf_normalize_path "$TARGET_ROOT")"
  case "$norm_dest" in
    "$norm_target"/*)
      printf '%s\n' "${norm_dest#$norm_target/}"
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Consigne <chemin_dest> dans l'accumulateur courant si (a) il résout sous TARGET_ROOT et
# (b) il n'est pas dans la liste close d'exclusions. Silencieux dans les deux autres cas —
# ce n'est jamais une erreur, seulement une exclusion volontaire du manifeste.
vf_record() {
  local dest="$1"
  local rel
  rel="$(vf_rel_to_target "$dest")" || return 0
  vf_manifest_excluded "$rel" && return 0
  printf '%s\n' "$rel" >> "$VF_MANIFEST_TMP"
}

# Ouvre un accumulateur neuf pour <mod>. Appelé au début d'install_module.
vf_manifest_reset() {
  local mod="$1"
  local manifest_dir
  manifest_dir="$(dirname "$(vf_manifest_path "$mod")")"
  mkdir -p "$manifest_dir"
  VF_MANIFEST_MOD="$mod"
  VF_MANIFEST_TMP="$manifest_dir/.vibeflow-manifest-${mod}.tmp.$$"
  : > "$VF_MANIFEST_TMP"
}

# Trie l'accumulateur (LC_ALL=C sort -u), l'écrit atomiquement (tmp + mv, patron
# mark_installed:115-124) vers $(vf_manifest_path "$VF_MANIFEST_MOD"), puis referme le cycle.
# Un accumulateur vide produit un manifeste vide (pas de manifeste ABSENT — réservé au parc
# pré-Phase-31, D-31-07).
vf_manifest_flush() {
  local target sorted_tmp
  target="$(vf_manifest_path "$VF_MANIFEST_MOD")"
  sorted_tmp="${VF_MANIFEST_TMP}.sorted"
  LC_ALL=C sort -u "$VF_MANIFEST_TMP" > "$sorted_tmp"
  mv "$sorted_tmp" "$target"
  rm -f "$VF_MANIFEST_TMP"
  VF_MANIFEST_TMP=""
  VF_MANIFEST_MOD=""
}

# LE helper de pose fichier (D-31-01) : pose <src> vers <dest> (exécutable si [exec] fourni)
# ET consigne <dest> dans le même appel — le manifeste est un sous-produit, jamais une
# énumération séparée. Le rc de cp est capturé explicitement et propagé (échec de copie =
# échec de pose), y compris quand l'appelant place cet appel dans un contexte qui neutralise
# `set -e` (if/&&/||) — capturer et retourner le rc à la main est ce qui rend l'échec visible
# dans ce cas aussi.
vf_place_file() {
  local src="$1" dest="$2" mode="${3:-}"
  local rc=0
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest" || rc=$?
  if [ "$rc" -ne 0 ]; then
    return "$rc"
  fi
  if [ "$mode" = "exec" ]; then
    chmod +x "$dest"
  fi
  vf_record "$dest"
}

# ---------- Résolveur de fermeture transitive (intégration Phase 2) ----------
# Localise resolve-deps.sh : d'abord dans le cache (prod, bundlé par Phase 5/PLUG-02),
# sinon à côté de l'engine (dev/source). Renvoie le chemin du résolveur, ou vide si absent.
find_resolver() {
  local candidate
  candidate="$CACHE_DIR/_internal/resolve-deps.sh"
  if [ -f "$candidate" ]; then echo "$candidate"; return 0; fi
  candidate="$(dirname "$0")/resolve-deps.sh"
  if [ -f "$candidate" ]; then echo "$candidate"; return 0; fi
  echo ""
}

# resolve_closure <mod...> : émet sur stdout la fermeture transitive (1 module/ligne).
# Si le résolveur est ABSENT, fallback best-effort = renvoie les args bruts, MAIS loue
# un AVERTISSEMENT BRUYANT (warning visible) — closure incomplète = install possiblement cassée.
resolve_closure() {
  local resolver
  resolver="$(find_resolver)"
  if [ -z "$resolver" ]; then
    # Fallback résolveur-absent : warning BRUYANT (sur stderr, sans exit) — T-03-08.
    echo "[vibeflow-update] ERROR: ATTENTION : résolveur introuvable — fermeture transitive NON calculée. Les dépendances de $* ne seront PAS installées ; l'install peut être incomplète/cassée. (Phase 5/PLUG-02 doit bundler resolve-deps.sh dans le cache.)" >&2
    printf '%s\n' "$@"
    return 0
  fi
  # VF_MODULES_ROOT pointe sur le CACHE (les module.json y vivent), pas sur le repo.
  VF_MODULES_ROOT="$CACHE_DIR" bash "$resolver" "$@"
}

# ---------- Gitignore local (SCOPE-04) ----------
# Ajoute les chemins installés du module au ./.gitignore (cwd projet) UNIQUEMENT en scope local.
# Idempotent : pas de doublon (grep -qxF avant ajout). Crée .gitignore s'il manque.
gitignore_add_one() {
  local path="$1"
  # Création paresseuse du .gitignore au premier ajout.
  [ -f .gitignore ] || : > .gitignore
  if ! grep -qxF "$path" .gitignore; then
    echo "$path" >> .gitignore
    log "  gitignore += $path"
  fi
}

gitignore_add_paths() {
  local mod="$1"
  # Scope local seulement : user/project ne touchent JAMAIS au .gitignore.
  [ "$VF_SCOPE" = "local" ] || return 0

  local module_dir="$CACHE_DIR/$mod"

  # Skill racine.
  [ -f "$module_dir/SKILL.md" ] && gitignore_add_one ".claude/skills/$mod/"
  # Skills imbriqués.
  if [ -d "$module_dir/skills" ]; then
    for skill_dir in "$module_dir/skills/"*/; do
      [ -d "$skill_dir" ] || continue
      gitignore_add_one ".claude/skills/$(basename "$skill_dir")/"
    done
  fi
  # Agent module (D7) : AGENT.md + dossier references.
  if [ -f "$module_dir/AGENT.md" ]; then
    gitignore_add_one ".claude/agents/${mod}.md"
    gitignore_add_one ".claude/commands/${mod}.md"
    [ -d "$module_dir/references" ] && gitignore_add_one ".claude/agents/${mod}-references/"
  fi
  # Multi-agents module : agents/<name>.md.
  if [ -d "$module_dir/agents" ]; then
    for f in "$module_dir/agents/"*.md; do
      [ -f "$f" ] && gitignore_add_one ".claude/agents/$(basename "$f")"
    done
    [ -d "$module_dir/references" ] && [ ! -f "$module_dir/SKILL.md" ] && gitignore_add_one ".claude/agents/${mod}-references/"
  fi
  # Rules réellement posées.
  if [ -d "$module_dir/rules" ]; then
    for f in "$module_dir/rules/"*.md; do
      [ -f "$f" ] && gitignore_add_one ".claude/rules/$(basename "$f")"
    done
  fi
  # Scripts réellement posés (shell + Node).
  if [ -d "$module_dir/scripts" ]; then
    for f in "$module_dir/scripts/"*.sh "$module_dir/scripts/"*.mjs "$module_dir/scripts/"*.js; do
      [ -f "$f" ] && gitignore_add_one ".claude/scripts/$(basename "$f")"
    done
  fi
  # Registres mémoire (SCOPE-04) : si le module fournit un seeder de registres, les fichiers qu'il
  # crée — à l'install ET à chaque SessionStart — doivent suivre la promesse du scope local
  # (« rien ne sera committé »). Sans cette ligne, l'engine gitignorait ses propres artefacts mais
  # laissait les 5 registres semés apparaître en untracked dans le git status du projet. Le
  # sélecteur est le seeder lui-même (data-driven, pas de nom de module en dur).
  [ -f "$module_dir/scripts/seed-registres.sh" ] && gitignore_add_one ".claude/memory/"
  # Config template posé à côté d'un SKILL.md racine.
  [ -d "$module_dir/config" ] && [ -f "$module_dir/SKILL.md" ] && gitignore_add_one ".claude/skills/$mod/config/"
  # settings.json + settings.local.json (SCOPE-04, Phase 30 tâche 4, corrigé en revue) : en scope
  # LOCAL, `merge_module_hooks()` écrit dans $TARGET_ROOT/settings.json ET, depuis le routage
  # --settings-local (tâche 4), dans $TARGET_ROOT/settings.local.json pour toute entrée portant le
  # chemin absolu machine {{VF_BASH}}. La même promesse « rien ne sera committé » que le reste de
  # cette fonction s'applique aux DEUX fichiers : le premier vérifié initialement par lecture du
  # code (pas par convention supposée), le second ajouté après que la revue a testé — et invalidé —
  # l'hypothèse qu'une convention hors-dépôt (gitignore global du mainteneur) suffisait à couvrir un
  # lab cible frais. Sélecteur data-driven identique aux deux lignes (même style que
  # seed-registres.sh ci-dessus) : seul un module qui PORTE un fragment hooks/hooks.json (donc qui
  # écrit réellement dans ces fichiers à cette install) déclenche l'ajout.
  [ -f "$module_dir/hooks/hooks.json" ] && gitignore_add_one ".claude/settings.json"
  [ -f "$module_dir/hooks/hooks.json" ] && gitignore_add_one ".claude/settings.local.json"
  # Lib partagée de portabilité (Phase 30 tâche 2, copy_engine_lib()) : posée par l'ENGINE, pas
  # par un module — donc jamais vue par la boucle scripts/ plus haut (elle vient du cache
  # _internal, jamais de $module_dir/scripts). Gap constaté en tâche 4 lors de la vérification
  # manuelle de ce plan (Rule 2, deviation documentée au SUMMARY) : sans cette ligne,
  # .claude/scripts/vf-portable.sh échappait à la promesse « rien ne sera committé » du scope
  # local. Inconditionnel : copy_engine_lib() la pose à CHAQUE exécution de l'engine en scope
  # local, quel que soit le module installé — gitignore_add_one() reste idempotent.
  gitignore_add_one ".claude/scripts/vf-portable.sh"
}

# ---------- Commande d'incarnation (ADR-042) ----------
# Après pose d'un agent, générer sa commande slash `/agent` (incarnation FENÊTRE PRINCIPALE).
# Best-effort : ne JAMAIS faire échouer l'install si le générateur est absent. Idempotent
# (le générateur n'écrase jamais une commande existante).
find_command_generator() {
  local c
  c="$TARGET_ROOT/scripts/generate-agent-commands.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  c="$CACHE_DIR/conductor/scripts/generate-agent-commands.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  echo ""
}

generate_agent_command_for() {
  local mod="$1" gen
  gen="$(find_command_generator)"
  if [ -z "$gen" ]; then
    log "  (commande d'incarnation non générée — generate-agent-commands.sh absent, best-effort)"
    return 0
  fi
  if VF_TARGET_ROOT="$TARGET_ROOT" bash "$gen" --agent "$mod" >/dev/null 2>&1; then
    log "  commande d'incarnation → $TARGET_ROOT/commands/${mod}.md"
  else
    log "  (commande d'incarnation non générée pour $mod — best-effort)"
  fi
}

# ---------- Injection MCP dérivée du lab (ADR-051) ----------
# Un sous-agent (Task) n'hérite PAS des serveurs MCP de la session : il ne voit, côté MCP, que ce
# que son `tools:` autorise (`mcp__<serveur>__*`). Les agents exécutants (flag vf-mcp-consumer:true)
# doivent donc recevoir les serveurs que le LAB déclare dans son ./.mcp.json. Data-driven (aucun nom
# de serveur ni d'agent en dur) ; best-effort (jamais faire échouer l'install). Idempotent.
find_mcp_injector() {
  local c
  c="$TARGET_ROOT/scripts/inject-mcp-tools.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  c="$CACHE_DIR/dev-orchestrator/scripts/inject-mcp-tools.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  c="$(dirname "$0")/inject-mcp-tools.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  echo ""
}

inject_lab_mcp_into_agents() {
  local injector
  injector="$(find_mcp_injector)"
  if [ -z "$injector" ]; then
    log "  (injection MCP non exécutée — inject-mcp-tools.sh absent, best-effort)"
    return 0
  fi
  # Source = ./.mcp.json du LAB (cwd projet), quel que soit le scope (les serveurs MCP du projet y
  # vivent, pas dans TARGET_ROOT). Absent → le script no-op de lui-même.
  if bash "$injector" --target "$TARGET_ROOT/agents" --mcp-json "./.mcp.json" >/dev/null 2>&1; then
    log "  serveurs MCP du lab injectés dans les agents exécutants flaggés (vf-mcp-consumer, ADR-051)"
  else
    log "  (injection MCP best-effort — voir inject-mcp-tools.sh)"
  fi
}

# ---------- Lib partagée de portabilité (contrat PR #29, D-04, Phase 30) ----------
# vf-portable.sh (résolution Python centralisée, jqx, vf_guard_unavailable) est possédée par
# l'ENGINE — jamais par un module, sans quoi elle disparaîtrait à la désinstallation du module qui
# l'aurait portée (contrat §2). Posée par copy_engine_lib(), même patron de cascade que
# find_hooks_merger()/find_mcp_injector() ci-dessous : cache du plugin d'abord, lib voisine du
# script ensuite (aucun candidat relatif au répertoire courant).
find_engine_lib() {
  local c
  c="$CACHE_DIR/_internal/lib/vf-portable.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  c="$(dirname "$0")/lib/vf-portable.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  echo ""
}

# Idempotence INTRA-PROCESSUS (Phase 30, RESEARCH.md §copy_engine_lib) : appelée depuis DEUX
# chemins qui posent des fichiers chez l'utilisateur — install_module() et sync_module_governance()
# (le chemin « version inchangée » de update_module()) — sans ce garde-fou elle recopierait la lib
# à chaque module d'une boucle --all. Un seul appel a un effet ; les suivants sont des no-op.
VF_ENGINE_LIB_COPIED="0"

copy_engine_lib() {
  [ "$VF_ENGINE_LIB_COPIED" = "1" ] && return 0
  local src dest tmp
  src="$(find_engine_lib)"
  if [ -z "$src" ]; then
    # VG-3 (même discipline que merge_module_hooks) : jamais un retour neutre silencieux. Un lab
    # sans la lib casse le `source` des 3 consommateurs PYBIN au premier appel (Runtime State
    # Inventory, RESEARCH.md) — l'absence de lib est un échec d'install, pas un détail dégradé.
    log "  ERROR: vf-portable.sh introuvable dans le cache — lib de portabilité NON posée (installer/mettre à jour l'engine)"
    return 1
  fi
  mkdir -p "$TARGET_ROOT/scripts"
  dest="$TARGET_ROOT/scripts/vf-portable.sh"
  tmp="$dest.tmp.$$"
  # Écriture ATOMIQUE (copie vers un temporaire du MÊME répertoire, puis renommage) : une install
  # interrompue laisse soit l'ancienne lib, soit la nouvelle, jamais un fichier tronqué qu'un
  # consommateur sourcerait à moitié. SANS chmod +x : la lib est sourcée, jamais lancée seule.
  if cp "$src" "$tmp" 2>/dev/null && mv -f "$tmp" "$dest" 2>/dev/null; then
    VF_ENGINE_LIB_COPIED="1"
    log "  lib vf-portable.sh posée → $dest"
    return 0
  fi
  rm -f "$tmp" 2>/dev/null || true
  log "  ERROR: pose de vf-portable.sh ÉCHOUÉE → $dest"
  return 1
}

# ---------- Hooks de gouvernance (ADR-043) ----------
# Un module peut déclarer hooks/hooks.json (format Claude Code, placeholder {{VF_SCRIPTS}}).
# L'install MERGE le fragment dans le settings.json du scope ; l'uninstall le retire.
# La gouvernance est posée par la machine — plus jamais un snippet à copier-coller.
find_hooks_merger() {
  local c
  c="$CACHE_DIR/_internal/merge-hooks.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  c="$(dirname "$0")/merge-hooks.sh"; [ -f "$c" ] && { echo "$c"; return 0; }
  echo ""
}

scripts_prefix_for_scope() {
  # Chemins LITTÉRAUX dans settings.json, valables pour la forme SHELL uniquement (c'est le
  # shell qui exécute la commande qui les expanse). Pour la forme exec (`args`), merge-hooks.sh
  # dérive lui-même la variante exec-safe (hotfix v2.53.1) : "$HOME" → chemin absolu résolu à
  # l'install, "$CLAUDE_PROJECT_DIR" → placeholder harness ${CLAUDE_PROJECT_DIR} — car en forme
  # exec aucun shell n'intervient et le harness ne substitue que ses propres placeholders.
  case "$VF_SCOPE" in
    user) printf '%s' '"$HOME"/.claude/scripts' ;;
    *)    printf '%s' '"$CLAUDE_PROJECT_DIR"/.claude/scripts' ;;
  esac
}

merge_module_hooks() {
  local mod="$1"
  local fragment="$CACHE_DIR/$mod/hooks/hooks.json"
  [ -f "$fragment" ] || return 0
  local merger
  merger="$(find_hooks_merger)"
  if [ -z "$merger" ]; then
    # VG-3 : ce `return 0` faisait sortir l'install en succès après une gouvernance absente —
    # le lab existait en croyant avoir ses hooks. L'échec se propage désormais (set -e → abort,
    # mark_installed jamais atteint : le registre ne ment pas).
    log "  ERROR: merge-hooks.sh introuvable — hooks de $mod NON câblés (gouvernance absente !)"
    return 1
  fi
  # Backup du settings avant toute écriture.
  if [ -f "$TARGET_ROOT/settings.json" ]; then
    mkdir -p "$BACKUP_DIR"
    cp "$TARGET_ROOT/settings.json" "$BACKUP_DIR/settings-$(date +%Y%m%d-%H%M%S).json"
  fi
  # Routage --settings-local (Phase 30 tâche 4, D-01) : en scope project/local, merge-hooks.sh
  # bascule vers CE fichier les seules entrées portant {{VF_BASH}} — un chemin absolu de bash
  # résolu à CETTE install, donc machine-spécifique. Sans ce routage, un tel chemin atterrirait
  # dans settings.json de PROJET, qui voyage via git. Scope user : no-op assumé, $HOME/.claude est
  # déjà par-machine. Tableau vide sous `set -u` (bash 3.2 : ne JAMAIS expanser "${arr[@]}" d'un
  # tableau vide sans le garder derrière un test de longueur — même garde que `_positional` plus
  # haut dans ce fichier), jamais une variable non définie.
  local -a settings_local_args=()
  case "$VF_SCOPE" in
    project|local) settings_local_args=(--settings-local "$TARGET_ROOT/settings.local.json") ;;
  esac
  local merge_rc=0
  if [ "${#settings_local_args[@]}" -gt 0 ]; then
    bash "$merger" merge "$fragment" --settings "$TARGET_ROOT/settings.json" \
      --scripts-prefix "$(scripts_prefix_for_scope)" "${settings_local_args[@]}" || merge_rc=$?
  else
    bash "$merger" merge "$fragment" --settings "$TARGET_ROOT/settings.json" \
      --scripts-prefix "$(scripts_prefix_for_scope)" || merge_rc=$?
  fi
  if [ "$merge_rc" -eq 0 ]; then
    log "  hooks mergés → $TARGET_ROOT/settings.json"
  else
    log "  ERROR: merge hooks ÉCHOUÉ pour $mod — gouvernance NON câblée (corriger settings.json puis réinstaller)"
    return 1  # VG-3 : l'échec se propage (plus de succès silencieux sans gouvernance)
  fi
}

remove_module_hooks() {
  local mod="$1"
  local fragment="$CACHE_DIR/$mod/hooks/hooks.json"
  [ -f "$fragment" ] || return 0
  [ -f "$TARGET_ROOT/settings.json" ] || return 0
  local merger
  merger="$(find_hooks_merger)"
  [ -n "$merger" ] || { log "  (retrait hooks impossible — merge-hooks.sh absent)"; return 0; }
  # Même routage --settings-local que merge_module_hooks (Phase 30 tâche 4) : en mode remove,
  # merge-hooks.sh balaie les DEUX cibles quand --settings-local est fournie — sans ce miroir, une
  # désinstallation deviendrait partielle et laisserait un hook orphelin dans le settings local.
  local -a settings_local_args=()
  case "$VF_SCOPE" in
    project|local) settings_local_args=(--settings-local "$TARGET_ROOT/settings.local.json") ;;
  esac
  local remove_rc=0
  if [ "${#settings_local_args[@]}" -gt 0 ]; then
    bash "$merger" remove "$fragment" --settings "$TARGET_ROOT/settings.json" "${settings_local_args[@]}" || remove_rc=$?
  else
    bash "$merger" remove "$fragment" --settings "$TARGET_ROOT/settings.json" || remove_rc=$?
  fi
  if [ "$remove_rc" -eq 0 ]; then
    log "  hooks retirés de $TARGET_ROOT/settings.json"
  else
    log "  (retrait hooks échoué pour $mod — best-effort, nettoyer settings.json à la main)"
  fi
}

# ---------- Scripts (posés au TARGET_ROOT/scripts) ----------
# Copie les scripts d'un module (shell + Node) + le sous-dossier tests/. Extrait d'install_module
# pour être réutilisable par la resync gouvernance (update version inchangée).
copy_module_scripts() {
  local mod="$1"
  local module_dir="$CACHE_DIR/$mod"
  [ -d "$module_dir/scripts" ] || return 0
  mkdir -p "$TARGET_ROOT/scripts"
  for f in "$module_dir/scripts/"*.sh "$module_dir/scripts/"*.mjs "$module_dir/scripts/"*.js; do
    [ -f "$f" ] && cp "$f" "$TARGET_ROOT/scripts/" && chmod +x "$TARGET_ROOT/scripts/$(basename "$f")"
  done
  # Fichiers de DONNEES accompagnant les scripts (*.txt). Sans cette boucle, un module pouvait
  # referencer un fichier que l'engine ne posait JAMAIS chez l'utilisateur : c'est exactement ce
  # qui est arrive a `known-versions.txt` (infrastructure-audit), lu par audit-infra.sh en
  # $SCRIPTS_DIR/known-versions.txt et absent de toute install. Glob volontairement borne a *.txt
  # — assez large pour la whitelist, assez etroit pour ne pas ramasser les residus (*.bak) ni les
  # manifestes de config. Pas de chmod +x : ce sont des donnees, pas des executables.
  for f in "$module_dir/scripts/"*.txt; do
    [ -f "$f" ] && cp "$f" "$TARGET_ROOT/scripts/"
  done
  if [ -d "$module_dir/scripts/tests" ]; then
    mkdir -p "$TARGET_ROOT/scripts/tests/fixtures"
    cp -r "$module_dir/scripts/tests/"*.sh "$TARGET_ROOT/scripts/tests/" 2>/dev/null || true
    cp -r "$module_dir/scripts/tests/fixtures/"* "$TARGET_ROOT/scripts/tests/fixtures/" 2>/dev/null || true
    chmod +x "$TARGET_ROOT"/scripts/tests/*.sh 2>/dev/null || true
  fi
  log "  copied scripts/ → $TARGET_ROOT/scripts/"
}

# Resync gouvernance légère (Fix B) : re-pose les scripts + re-merge les hooks d'un module SANS
# backup ni re-copie complète. Appelée quand la version est INCHANGÉE — rend /vf-update
# auto-réparateur si un hooks.json a dérivé (nouveau hook posé sans bump de VERSION du module).
# Idempotent : merge-hooks dédup par basename, la copie de scripts écrase à l'identique.
# seed_module_registres : si le module fournit seed-registres.sh, instancier les registres canon
# manquants. Fonction plutôt qu'appel inline parce qu'elle a DEUX appelants (install_module et
# sync_module_governance) : c'est ce qui rend la mémoire transparente à l'update, y compris quand la
# version du module n'a pas bougé — le chemin « déjà à jour » ne repasse jamais par install_module.
# Sans ce second appel, un lab configuré avant cette version n'aurait ses registres qu'au prochain
# bump de consolidator, soit jamais si celui-ci n'évolue plus.
seed_module_registres() {
  local mod="$1"
  local seeder="$TARGET_ROOT/scripts/seed-registres.sh"
  [ -f "$CACHE_DIR/$mod/scripts/seed-registres.sh" ] || return 0
  [ -f "$seeder" ] || return 0
  if bash "$seeder" --quiet >/dev/null; then
    log "  registres mémoire vérifiés/instanciés → seed-registres.sh"
  else
    log "  (registres mémoire non instanciés — best-effort, voir seed-registres.sh)"
  fi
}

sync_module_governance() {
  local mod="$1"
  # Chemin « version inchangée » (D-04) : sans cet appel, un lab déjà à jour n'obtiendrait JAMAIS
  # la lib de portabilité — idempotent au sein du même processus (VF_ENGINE_LIB_COPIED).
  copy_engine_lib
  copy_module_scripts "$mod"
  merge_module_hooks "$mod"
  # Ordre imposé : le seeder est posé par copy_module_scripts juste au-dessus. L'appeler avant
  # rendrait le resync inerte sur un lab où le script n'a jamais été installé — exactement le cas
  # qu'on cherche à rattraper.
  seed_module_registres "$mod"
}

# ---------- Baseline obligatoire (INST-02a) ----------
# Un module module.json avec "mandatory": true est un INVARIANT du lab (aujourd'hui : conductor,
# le socle de gouvernance, et consolidator, le socle de mémoire). Data-driven, AUCUN nom de module
# en dur — la liste sort des manifestes présents dans le cache.
module_is_mandatory() {
  local mod="$1"
  local mj="$CACHE_DIR/$mod/module.json"
  [ -f "$mj" ] || return 1
  grep -Eq '"mandatory"[[:space:]]*:[[:space:]]*true' "$mj"
}

# ensure_mandatory_baseline : garantit que tout module `mandatory` est présent dans le lab.
# Corrige la lacune où `update --all` n'itère que sur le registre : un module mandatory publié
# APRÈS la config d'un lab (ex. conductor arrivé en v2.7.0) n'y atterrissait jamais — donc ni ses
# scripts ni ses hooks (bandeau de mise à jour). Installe la fermeture transitive des manquants.
ensure_mandatory_baseline() {
  require_cache
  local mod m
  for mod in $(list_available_modules); do
    module_is_mandatory "$mod" || continue
    [ "$(module_version_installed "$mod")" = "—" ] || continue
    log "Baseline (INST-02a) : module obligatoire '$mod' absent du lab → installation"
    while IFS= read -r m; do
      m="${m%$'\r'}"   # ceinture ADR-054 : jamais de nom de module \r-suffixé (résolveur sous jq Windows)
      [ -n "$m" ] || continue
      [ "$(module_version_installed "$m")" = "—" ] && install_module "$m"
    done < <(resolve_closure "$mod")
  done
}

# ---------- Modules retirés (convergence, CONS-01) ----------
# Un module supprimé du parc (ex. feature-dev-gates, fusionné dans software-architecture) laisse des
# artefacts ORPHELINS dans les labs qui l'avaient installé. uninstall_module lit les artefacts DEPUIS
# le cache — absent pour un module retiré — donc le nettoyage s'appuie sur un manifeste EN DUR :
# _internal/retired-modules.txt (format `module:artefact` relatif à TARGET_ROOT, une ligne/artefact ;
# `#` = commentaire). Idempotent : ne retire que ce qui existe encore. Appelé à `update --all`.
find_retired_manifest() {
  local c
  c="$CACHE_DIR/_internal/retired-modules.txt"; [ -f "$c" ] && { echo "$c"; return 0; }
  c="$(dirname "$0")/retired-modules.txt"; [ -f "$c" ] && { echo "$c"; return 0; }
  echo ""
}

cleanup_retired_modules() {
  local manifest
  manifest="$(find_retired_manifest)"
  [ -n "$manifest" ] || return 0
  local line mod artifact target in_registry
  while IFS= read -r line; do
    case "$line" in ''|\#*) continue ;; esac
    mod="${line%%:*}"
    artifact="${line#*:}"
    [ -n "$mod" ] && [ -n "$artifact" ] || continue
    target="$TARGET_ROOT/$artifact"
    in_registry="no"
    [ "$(module_version_installed "$mod")" = "—" ] || in_registry="yes"
    # Rien à faire si ni artefact orphelin ni entrée de registre pour ce module.
    if [ ! -e "$target" ] && [ "$in_registry" = "no" ]; then
      continue
    fi
    log "Module retiré '$mod' détecté dans ce lab → nettoyage (convergence)"
    [ -e "$target" ] && rm -rf "$target" && log "  removed $target"
    [ "$in_registry" = "yes" ] && mark_uninstalled "$mod"
  done < "$manifest"
}

# ---------- Install ----------
install_module() {
  local mod="$1"
  require_cache

  local module_dir="$CACHE_DIR/$mod"
  [ -d "$module_dir" ] || err "Module $mod introuvable dans $CACHE_DIR"

  vf_manifest_reset "$mod"

  local version
  version=$(module_version_available "$mod")
  log "Installation $mod $version (scope=$VF_SCOPE → $TARGET_ROOT)..."

  # Lib de portabilité (contrat PR #29, D-04) : posée une fois par exécution, avant le traitement
  # du module — idempotent au sein du même processus (VF_ENGINE_LIB_COPIED), donc sans coût
  # supplémentaire réel sur une boucle `install --all`/`--with-deps`.
  copy_engine_lib

  # Backup if existing install
  local installed
  installed=$(module_version_installed "$mod")
  if [ "$installed" != "—" ]; then
    log "  Module déjà installé ($installed). Backup avant overwrite..."
    backup_module "$mod"
  fi

  # Type 1 — Single-skill module : SKILL.md at module root
  if [ -f "$module_dir/SKILL.md" ]; then
    vf_place_file "$module_dir/SKILL.md" "$TARGET_ROOT/skills/$mod/SKILL.md"
    log "  copied SKILL.md → $TARGET_ROOT/skills/$mod/"
  fi

  # Type 2 — Multi-skills module : skills/<name>/SKILL.md (e.g., skill-creator with 2 nested skills)
  if [ -d "$module_dir/skills" ]; then
    for skill_dir in "$module_dir/skills/"*/; do
      [ -d "$skill_dir" ] || continue
      skill_name=$(basename "$skill_dir")
      mkdir -p "$TARGET_ROOT/skills/$skill_name"
      cp -r "$skill_dir"* "$TARGET_ROOT/skills/$skill_name/" 2>/dev/null || true
      log "  copied nested skill → $TARGET_ROOT/skills/$skill_name/"
    done
  fi

  # Type 3 — Agent module : AGENT.md → $TARGET_ROOT/agents/<mod>.md
  if [ -f "$module_dir/AGENT.md" ]; then
    mkdir -p "$TARGET_ROOT/agents"
    cp "$module_dir/AGENT.md" "$TARGET_ROOT/agents/${mod}.md"
    log "  copied AGENT.md → $TARGET_ROOT/agents/${mod}.md"
  fi

  # Type 3b — Multi-agents module : agents/<name>.md → $TARGET_ROOT/agents/<name>.md (chacun)
  # Symétrique du multi-skills (skills/<name>/). Un module peut livrer plusieurs agents.
  if [ -d "$module_dir/agents" ]; then
    mkdir -p "$TARGET_ROOT/agents"
    for agent_md in "$module_dir/agents/"*.md; do
      [ -f "$agent_md" ] || continue
      cp "$agent_md" "$TARGET_ROOT/agents/$(basename "$agent_md")"
      log "  copied agent → $TARGET_ROOT/agents/$(basename "$agent_md")"
    done
  fi

  # Type 4 — Doc-only module : content/ → docs/<mod>/
  # EXCEPTION scope : la doc reste relative au cwd PROJET (ce n'est pas du .claude),
  # donc PAS rebasée sur TARGET_ROOT même en scope user.
  if [ -d "$module_dir/content" ]; then
    local doc_target="docs/$mod"
    mkdir -p "$doc_target"
    cp -r "$module_dir/content/"* "$doc_target/" 2>/dev/null || true
    log "  copied content/ → $doc_target/ (doc module, hors TARGET_ROOT)"
  fi

  # Type 5 — Rules : rules/*.md → $TARGET_ROOT/rules/
  # Deux régimes selon le frontmatter : AVEC `paths:` → chargée à la lecture d'un fichier
  # correspondant (auto-scopée, Tier 2) ; SANS `paths:` → chargée inconditionnellement au
  # lancement, à la priorité de CLAUDE.md (globale, Tier 1). Voir patterns/05-regles.md.
  if [ -d "$module_dir/rules" ]; then
    mkdir -p "$TARGET_ROOT/rules"
    cp "$module_dir/rules/"*.md "$TARGET_ROOT/rules/" 2>/dev/null || true
    log "  copied rules/ → $TARGET_ROOT/rules/"
  fi

  # References folder at module root (companion to root SKILL.md)
  if [ -d "$module_dir/references" ] && [ -f "$module_dir/SKILL.md" ]; then
    mkdir -p "$TARGET_ROOT/skills/$mod/references"
    cp -r "$module_dir/references/"* "$TARGET_ROOT/skills/$mod/references/" 2>/dev/null || true
    log "  copied references/ → $TARGET_ROOT/skills/$mod/references/"
  fi

  # References folder for AGENT modules (D7) : un module agent (AGENT.md ou agents/ sans SKILL.md
  # racine) embarque ses references sous $TARGET_ROOT/agents/<mod>-references/ (chargées on-demand).
  if [ -d "$module_dir/references" ] && { [ -f "$module_dir/AGENT.md" ] || [ -d "$module_dir/agents" ]; } && [ ! -f "$module_dir/SKILL.md" ]; then
    mkdir -p "$TARGET_ROOT/agents/${mod}-references"
    cp -r "$module_dir/references/"* "$TARGET_ROOT/agents/${mod}-references/" 2>/dev/null || true
    log "  copied references/ → $TARGET_ROOT/agents/${mod}-references/"
  fi

  # Config folder at module root (companion to root SKILL.md) : templates de config projet.
  # Posé sous le dossier skill du module ; l'utilisateur copie le .example.json vers son projet.
  if [ -d "$module_dir/config" ] && [ -f "$module_dir/SKILL.md" ]; then
    mkdir -p "$TARGET_ROOT/skills/$mod/config"
    cp -r "$module_dir/config/"* "$TARGET_ROOT/skills/$mod/config/" 2>/dev/null || true
    log "  copied config/ → $TARGET_ROOT/skills/$mod/config/"
  fi

  # Scripts (top-level + tests subdir) : shell (.sh) et Node (.mjs/.js).
  copy_module_scripts "$mod"

  # Hook post-install (IDX-02 / D7) : si le module fournit build-gsd-index.sh, régénérer
  # l'index factuel in-place dans le dossier references agent. Best-effort : ne JAMAIS
  # faire échouer l'install si GSD est absent (l'index sera régénéré plus tard).
  if [ -f "$module_dir/scripts/build-gsd-index.sh" ] && [ -f "$TARGET_ROOT/scripts/build-gsd-index.sh" ]; then
    if VF_INDEX_OUT="$TARGET_ROOT/agents/${mod}-references/gsd-skills-index.md" \
       bash "$TARGET_ROOT/scripts/build-gsd-index.sh" >/dev/null 2>&1; then
      log "  index régénéré → $TARGET_ROOT/agents/${mod}-references/gsd-skills-index.md"
    else
      log "  (index non régénéré — GSD absent, best-effort)"
    fi
  fi

  # Hook post-install (IDX-02 / D7 / D-07) : second générateur, STRICTEMENT symétrique du premier
  # — table des capabilities par point de hook du moteur. Volontairement NON fusionné avec l'appel
  # ci-dessus en boucle générique : le premier est stabilisé depuis la Phase 1, et le refactorer
  # élargirait le périmètre à un fichier d'engine partagé par tous les modules, sans bénéfice.
  # Best-effort de la même façon : un moteur GSD absent au moment de l'install DÉGRADE (une ligne
  # de journal), il n'ampute jamais l'install d'un module.
  if [ -f "$module_dir/scripts/build-gsd-capabilities-index.sh" ] && [ -f "$TARGET_ROOT/scripts/build-gsd-capabilities-index.sh" ]; then
    if VF_CAPS_INDEX_OUT="$TARGET_ROOT/agents/${mod}-references/gsd-capabilities-index.md" \
       bash "$TARGET_ROOT/scripts/build-gsd-capabilities-index.sh" >/dev/null 2>&1; then
      log "  index capabilities régénéré → $TARGET_ROOT/agents/${mod}-references/gsd-capabilities-index.md"
    else
      log "  (index capabilities non régénéré — moteur GSD absent, best-effort)"
    fi
  fi

  # Hook post-install (D-03a, quick 260810-fh3) : troisième hook nommé, STRICTEMENT symétrique de
  # ses deux jumeaux ci-dessus (build-gsd-index.sh / build-gsd-capabilities-index.sh) — donc PAS de
  # refactoring en boucle générique (même motif que le commentaire du second hook : le premier est
  # stabilisé depuis la Phase 1, généraliser élargirait le périmètre à un fichier d'engine partagé
  # par tous les modules, sans bénéfice). Ce hook ne doit JAMAIS amputer l'install d'un module
  # (D-03a) : une chaîne d'outils design absente DÉGRADE (une ligne de journal), elle ne casse rien.
  # VF_SCOPE est HÉRITÉ de l'export de tête de ce script (ligne ~78) — rien à passer explicitement.
  #
  # `--quiet` SANS `2>&1` — et c'est le point entier du hook : le script parle sur stderr, ses
  # lignes de routine sont supprimées par --quiet, mais ses ANOMALIES (plugin absent ou désactivé,
  # geste réellement exécuté, étape manuelle quand l'auto-install n'a pas pu aboutir) doivent
  # traverser jusqu'au journal de l'install. Avaler stderr ici rejouerait, un cran plus loin, la
  # dégradation silencieuse que ce hook existe pour fermer. Seul stdout part au trou (le script
  # n'y écrit rien — garde de forme contre une future régression).
  if [ -f "$module_dir/scripts/ensure-design-deps.sh" ] && [ -f "$TARGET_ROOT/scripts/ensure-design-deps.sh" ]; then
    if bash "$TARGET_ROOT/scripts/ensure-design-deps.sh" --quiet >/dev/null; then
      log "  chaîne d'outils design vérifiée/corrigée → ensure-design-deps.sh"
    else
      log "  (chaîne d'outils design non vérifiée — best-effort, voir ensure-design-deps.sh)"
    fi
  fi

  # Hook post-install (mémoire) : quatrième hook nommé, même patron que ses trois jumeaux ci-dessus
  # — donc PAS de refactoring en boucle générique (cf. le commentaire du second hook). Instancie les
  # registres canoniques depuis les gabarits du module. Sans lui, `consolidator` s'installait entier
  # mais posait ses gabarits sans jamais les instancier : `.claude/memory/` n'existait pas et le lab
  # échouait son propre gate mémoire (mesuré 2026-08-15, cf. en-tête de seed-registres.sh).
  #
  # Best-effort de la même façon : le code retour est IGNORÉ, une mémoire non instanciée DÉGRADE
  # (une ligne de journal), elle n'ampute jamais l'install. Le script est non destructif et
  # idempotent — il ne sait que créer ce qui manque —, ce qui le rend sûr à rejouer ici à chaque
  # install ET dans sync_module_governance à chaque update.
  #
  # `--quiet` SANS `2>&1`, même raison que le hook design : les lignes de routine sont supprimées,
  # mais les anomalies (gabarits introuvables, création impossible) doivent traverser jusqu'au
  # journal — les avaler rejouerait la dégradation silencieuse que ce hook existe pour fermer.
  seed_module_registres "$mod"

  # Commande d'incarnation (ADR-042) : tout agent posé devient invocable nativement via `/<mod>`
  # dans la fenêtre principale. Après la copie des scripts ci-dessus, le générateur est dispo.
  if [ -f "$module_dir/AGENT.md" ]; then
    generate_agent_command_for "$mod"
  fi

  # Injection MCP dérivée du lab (ADR-051) : si ce module a posé des agents, injecter dans les
  # exécutants flaggés (vf-mcp-consumer) les serveurs MCP que le lab déclare dans ./.mcp.json.
  # Le balayage est filtré par le flag → les agents planif/revue/audit restent inchangés.
  if [ -f "$module_dir/AGENT.md" ] || [ -d "$module_dir/agents" ]; then
    inject_lab_mcp_into_agents
  fi

  # Hooks de gouvernance (ADR-043) : fragment hooks/hooks.json → mergé dans settings.json.
  merge_module_hooks "$mod"

  # SCOPE-04 : en scope local seulement, ajouter les chemins installés au ./.gitignore.
  gitignore_add_paths "$mod"

  vf_manifest_flush

  mark_installed "$mod" "$version"
  log "✓ $mod $version installé"
}

# ---------- Backup / Rollback ----------
backup_module() {
  local mod="$1"
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  local bdir="$BACKUP_DIR/$mod-$ts"
  mkdir -p "$bdir"
  [ -d "$TARGET_ROOT/skills/$mod" ] && cp -r "$TARGET_ROOT/skills/$mod" "$bdir/skills"
  # Agent module : AGENT.md installé + son dossier references (D7)
  [ -f "$TARGET_ROOT/agents/${mod}.md" ] && { mkdir -p "$bdir/agents"; cp "$TARGET_ROOT/agents/${mod}.md" "$bdir/agents/"; }
  [ -d "$TARGET_ROOT/agents/${mod}-references" ] && cp -r "$TARGET_ROOT/agents/${mod}-references" "$bdir/agent-references"
  # Scripts (les scripts du module sont mélangés avec les autres — backup uniquement les nommés dans le module)
  if [ -d "$CACHE_DIR/$mod/scripts" ]; then
    mkdir -p "$bdir/scripts"
    for f in "$CACHE_DIR/$mod/scripts/"*.sh; do
      name=$(basename "$f")
      [ -f "$TARGET_ROOT/scripts/$name" ] && cp "$TARGET_ROOT/scripts/$name" "$bdir/scripts/"
    done
  fi
  log "  backup → $bdir"
}

rollback_module() {
  local mod="$1"
  # Find latest backup
  local latest
  latest=$(ls -1dt "$BACKUP_DIR/$mod"-* 2>/dev/null | head -1)
  [ -z "$latest" ] && err "Aucun backup trouvé pour $mod dans $BACKUP_DIR"

  log "Rollback $mod depuis $latest..."
  if [ -d "$latest/skills" ]; then
    rm -rf "$TARGET_ROOT/skills/$mod"
    cp -r "$latest/skills" "$TARGET_ROOT/skills/$mod"
    log "  restored $TARGET_ROOT/skills/$mod"
  fi
  if [ -d "$latest/scripts" ]; then
    for f in "$latest/scripts/"*; do
      [ -f "$f" ] && cp "$f" "$TARGET_ROOT/scripts/" && chmod +x "$TARGET_ROOT/scripts/$(basename "$f")"
    done
    log "  restored scripts"
  fi
  log "✓ $mod rollback OK"
}

# ---------- Uninstall ----------
uninstall_module() {
  local mod="$1"
  log "Désinstallation $mod (scope=$VF_SCOPE → $TARGET_ROOT)..."
  backup_module "$mod"

  # Remove skill dir (Type 1 — skill mono)
  if [ -d "$TARGET_ROOT/skills/$mod" ]; then
    rm -rf "$TARGET_ROOT/skills/$mod"
    log "  removed $TARGET_ROOT/skills/$mod"
  fi

  # Remove nested skills (Type 2 — skills/<name>/, symétrique de l'install). On ne retire QUE les
  # skills que CE module possède (lus depuis le cache), jamais celui d'un autre module.
  if [ -d "$CACHE_DIR/$mod/skills" ]; then
    for skill_dir in "$CACHE_DIR/$mod/skills/"*/; do
      [ -d "$skill_dir" ] || continue
      skill_name=$(basename "$skill_dir")
      if [ -d "$TARGET_ROOT/skills/$skill_name" ]; then
        rm -rf "$TARGET_ROOT/skills/$skill_name"
        log "  removed $TARGET_ROOT/skills/$skill_name"
      fi
    done
  fi

  # Remove agent module (AGENT.md installé + dossier references D7)
  if [ -f "$TARGET_ROOT/agents/${mod}.md" ]; then
    rm -f "$TARGET_ROOT/agents/${mod}.md"
    log "  removed $TARGET_ROOT/agents/${mod}.md"
  fi
  # Remove multi-agents (only those owned by this module)
  if [ -d "$CACHE_DIR/$mod/agents" ]; then
    for f in "$CACHE_DIR/$mod/agents/"*.md; do
      [ -f "$f" ] || continue
      name=$(basename "$f")
      [ -f "$TARGET_ROOT/agents/$name" ] && rm "$TARGET_ROOT/agents/$name" && log "  removed $TARGET_ROOT/agents/$name"
    done
  fi
  if [ -d "$TARGET_ROOT/agents/${mod}-references" ]; then
    rm -rf "$TARGET_ROOT/agents/${mod}-references"
    log "  removed $TARGET_ROOT/agents/${mod}-references"
  fi

  # Commande d'incarnation générée (ADR-042) : la retirer avec l'agent.
  if [ -f "$TARGET_ROOT/commands/${mod}.md" ]; then
    rm -f "$TARGET_ROOT/commands/${mod}.md"
    log "  removed $TARGET_ROOT/commands/${mod}.md"
  fi

  # Remove scripts (only those owned by this module : shell + Node)
  if [ -d "$CACHE_DIR/$mod/scripts" ]; then
    for f in "$CACHE_DIR/$mod/scripts/"*.sh "$CACHE_DIR/$mod/scripts/"*.mjs "$CACHE_DIR/$mod/scripts/"*.js; do
      [ -f "$f" ] || continue
      name=$(basename "$f")
      [ -f "$TARGET_ROOT/scripts/$name" ] && rm "$TARGET_ROOT/scripts/$name" && log "  removed $TARGET_ROOT/scripts/$name"
    done
    # Miroir de copy_module_scripts : retirer aussi tests/ + fixtures/ de CE module, puis élaguer
    # les dossiers s'ils sont vides. rmdir (jamais rm -rf) car scripts/ et tests/ sont partagés.
    if [ -d "$CACHE_DIR/$mod/scripts/tests" ]; then
      for f in "$CACHE_DIR/$mod/scripts/tests/"*.sh; do
        [ -f "$f" ] || continue
        name=$(basename "$f")
        [ -f "$TARGET_ROOT/scripts/tests/$name" ] && rm "$TARGET_ROOT/scripts/tests/$name" && log "  removed $TARGET_ROOT/scripts/tests/$name"
      done
      for f in "$CACHE_DIR/$mod/scripts/tests/fixtures/"*; do
        [ -e "$f" ] || continue
        name=$(basename "$f")
        [ -e "$TARGET_ROOT/scripts/tests/fixtures/$name" ] && rm -rf "$TARGET_ROOT/scripts/tests/fixtures/$name" && log "  removed $TARGET_ROOT/scripts/tests/fixtures/$name"
      done
      rmdir "$TARGET_ROOT/scripts/tests/fixtures" 2>/dev/null || true
      rmdir "$TARGET_ROOT/scripts/tests" 2>/dev/null || true
    fi
    rmdir "$TARGET_ROOT/scripts" 2>/dev/null || true
  fi

  # Remove rules (only those owned by this module)
  if [ -d "$CACHE_DIR/$mod/rules" ]; then
    for f in "$CACHE_DIR/$mod/rules/"*.md; do
      name=$(basename "$f")
      [ -f "$TARGET_ROOT/rules/$name" ] && rm "$TARGET_ROOT/rules/$name" && log "  removed $TARGET_ROOT/rules/$name"
    done
  fi

  # Hooks de gouvernance (ADR-043) : retirer les entrées du module de settings.json.
  remove_module_hooks "$mod"

  mark_uninstalled "$mod"
  log "✓ $mod désinstallé"
}

# ---------- Status ----------
show_status() {
  require_cache
  printf "%-30s %-15s %-15s %s\n" "Module" "Installed" "Available" "Status"
  printf "%-30s %-15s %-15s %s\n" "------" "---------" "---------" "------"
  for mod in $(list_available_modules); do
    installed=$(module_version_installed "$mod")
    available=$(module_version_available "$mod")
    if [ "$installed" = "—" ]; then
      status="Not installed"
    elif [ "$installed" = "$available" ]; then
      status="Up to date"
    else
      status="Update available ($installed → $available)"
    fi
    printf "%-30s %-15s %-15s %s\n" "$mod" "$installed" "$available" "$status"
  done
}

# ---------- Update ----------
update_module() {
  local mod="$1"
  require_cache
  local installed available
  installed=$(module_version_installed "$mod")
  available=$(module_version_available "$mod")

  if [ "$installed" = "—" ]; then
    log "$mod n'est pas installé. Use 'install' au lieu de 'update'."
    return 1
  fi

  if [ "$installed" = "$available" ]; then
    # Version inchangée : pas de re-copie complète, mais on RE-SYNCHRONISE la gouvernance
    # (scripts + hooks). Rend /vf-update auto-réparateur si un hooks.json a dérivé sans bump
    # de VERSION — idempotent, best-effort.
    log "$mod déjà à jour ($installed) — resync gouvernance (scripts + hooks)"
    sync_module_governance "$mod"
    return 0
  fi

  log "Update $mod : $installed → $available"
  install_module "$mod"
}

# ---------- Main ----------
[ "$#" -lt 1 ] && {
  grep '^# ' "$0" | sed 's/^# //'
  exit 0
}

cmd="$1"
arg="${2:-}"

case "$cmd" in
  install)
    if [ "$arg" = "--all" ]; then
      require_cache
      for m in $(list_available_modules); do install_module "$m"; done
    elif [ "$arg" = "--with-deps" ]; then
      # install --with-deps <mod> : installe la fermeture transitive (résolveur câblé).
      deps_target="${3:-}"
      [ -n "$deps_target" ] || err "Usage: install --with-deps <module>"
      require_cache
      while IFS= read -r m; do
        m="${m%$'\r'}"   # ceinture ADR-054 : jamais de nom de module \r-suffixé (résolveur sous jq Windows)
        [ -n "$m" ] && install_module "$m"
      done < <(resolve_closure "$deps_target")
    elif [ -n "$arg" ]; then
      install_module "$arg"
    else
      err "Usage: install <module> | install --with-deps <module> | install --all"
    fi
    ;;
  update)
    if [ "$arg" = "--all" ]; then
      require_cache
      # Convergence AVANT la boucle : désenregistrer + nettoyer les modules retirés du parc
      # (CONS-01). Sinon la boucle tenterait d'`update_module` un module absent du cache
      # (install_module → err → abort) avant d'atteindre le nettoyage.
      cleanup_retired_modules
      if [ -f "$INSTALLED_REGISTRY" ]; then
        while IFS='=' read -r mod ver; do
          [ -n "$mod" ] && update_module "$mod"
        done < "$INSTALLED_REGISTRY"
        # Lab initialisé : garantir la baseline obligatoire (INST-02a). Un module `mandatory`
        # publié après la config du lab (conductor en v2.7.0, consolidator en v1.9.0) est ainsi
        # rattrapé au lieu d'être ignoré à vie — c'est ce qui posait ses scripts + hooks manquants
        # (bandeau /vf-update pour conductor ; registres + guards mémoire pour consolidator).
        ensure_mandatory_baseline
      else
        log "Aucun module installé"
      fi
    elif [ -n "$arg" ]; then
      update_module "$arg"
    else
      err "Usage: update <module> | update --all"
    fi
    ;;
  uninstall)
    if [ "$arg" = "--all" ]; then
      # uninstall --all : retire TOUS les modules listés dans le registre.
      # On fige la liste AVANT la boucle : uninstall_module → mark_uninstalled réécrit le
      # registre à chaque itération, donc on itère sur un snapshot, pas sur le fichier muté.
      if [ -f "$INSTALLED_REGISTRY" ]; then
        _to_remove=()
        while IFS='=' read -r mod _ver; do
          [ -n "$mod" ] && _to_remove+=("$mod")
        done < "$INSTALLED_REGISTRY"
        if [ "${#_to_remove[@]}" -eq 0 ]; then
          log "Aucun module installé (registre vide) — rien à désinstaller."
        else
          for mod in "${_to_remove[@]}"; do uninstall_module "$mod"; done
          log "✓ ${#_to_remove[@]} module(s) désinstallé(s)"
        fi
      else
        log "Aucun module installé (pas de registre) — rien à désinstaller."
      fi
    elif [ -n "$arg" ]; then
      uninstall_module "$arg"
    else
      err "Usage: uninstall <module> | uninstall --all"
    fi
    ;;
  rollback)
    [ -n "$arg" ] || err "Usage: rollback <module>"
    rollback_module "$arg"
    ;;
  status)
    show_status
    ;;
  sync)
    # No-op explicite (SCOPE-02) : la source est le cache fourni, plus de sync git.
    log "source = cache fourni (VIBEFLOW_CACHE=$CACHE_DIR), plus de sync git"
    ;;
  *)
    grep '^# ' "$0" | sed 's/^# //'
    exit 1
    ;;
esac
