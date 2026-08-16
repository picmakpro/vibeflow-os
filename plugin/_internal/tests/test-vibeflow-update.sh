#!/usr/bin/env bash
# test-vibeflow-update.sh — Suite de vérification de l'engine scope-aware (Phase 03-01).
#
# Couvre les 5 truths du plan, en ISOLATION TOTALE (HOME + cache mktemp) :
#   T1 (user)    — VF_SCOPE=user install dev-orchestrator → artefacts sous $HOME/.claude,
#                  RIEN sous ./.claude du lab.
#   T2 (project) — sans VF_SCOPE (défaut LEGACY project), install → artefacts sous ./.claude
#                  du lab ; rétro-compat dev-orchestrator (agent + references D7 présents).
#   T3 (local)   — VF_SCOPE=local install → ./.gitignore du lab contient les chemins ;
#                  2e run = pas de doublon (idempotent, grep -c == 1).
#   T3c (local)  — Phase 30 tâche 4 : .claude/settings.json (écrit par merge_module_hooks sur un
#                  module à hooks) est gitignoré exactement une fois, idempotent ; en scope
#                  project le même module ne crée/ne touche PAS .gitignore (SCOPE-04 borné).
#   T4 (no clone)— aucun `git clone`/`git pull` dans le source de l'engine (assert statique).
#   T5 (résolveur RÉELLEMENT exercé) — resolve-deps.sh copié dans $CACHE/_internal/, puis
#                  install --with-deps validator → fermeture {consolidator, infrastructure-audit,
#                  validator} installée. SKIP propre seulement si les module.json manquent
#                  (JAMAIS pour résolveur absent — on le copie).
#
# En prod, Phase 5 (PLUG-02) bundle resolve-deps.sh dans le cache du plugin ; ce test reproduit
# ce bundling en copiant le résolveur dans $CACHE/_internal/.
#
# ISOLATION : le vrai ~/.claude n'est JAMAIS touché. Défense principale = HOME=mktemp pour le
# scope user. Ceinture+bretelles = snapshot RÉCURSIF (find -type f) du vrai ~/.claude avant/après.
#
# Convention : asserts numérotés, helpers ok()/ko()/skip(), exit 0 si tout passe (SKIP non
# bloquant), exit 1 si au moins un KO. Calqué sur le pattern de test du repo.

set -uo pipefail

# Racines (test sous _internal/tests/ → engine et modules sous _internal/.. = REPO).
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERNAL_DIR="$(cd "$TESTS_DIR/.." && pwd)"
REPO="$(cd "$INTERNAL_DIR/.." && pwd)"
INSTALLER="$INTERNAL_DIR/vibeflow-update.sh"
RESOLVER="$INTERNAL_DIR/resolve-deps.sh"

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

# grep insensible à l'alias zsh (ugrep) : on force le binaire système.
GREP="$(command -v grep)"

echo "== test-vibeflow-update (engine: $INSTALLER) =="

# Snapshot du vrai ~/.claude AVANT la suite (garde-fou anti-pollution) — RESTREINT aux
# sous-chemins que l'engine sait écrire (agents/skills/scripts/rules/commands/settings.json).
# Un find sur TOUT ~/.claude était flaky : Claude Code lui-même y écrit en continu pendant la
# suite (projects/, todos/, logs…) → faux positif « POLLUÉ » sans aucun lien avec l'engine.
snapshot_home_claude() {
  find "$HOME/.claude/agents" "$HOME/.claude/skills" "$HOME/.claude/scripts" \
       "$HOME/.claude/rules" "$HOME/.claude/commands" "$HOME/.claude/settings.json" \
       -type f 2>/dev/null | wc -l | tr -d ' '
}
HOME_BEFORE=$(snapshot_home_claude)

# Helper : prépare un cache de test avec un module copié depuis le repo.
# Usage : prepare_module <cache_dir> <module>
prepare_module() {
  local cache="$1" mod="$2"
  mkdir -p "$cache/$mod"
  cp -r "$REPO/$mod/." "$cache/$mod/" 2>/dev/null || return 1
  [ -f "$cache/$mod/VERSION" ] || return 1
  return 0
}

# ---------------------------------------------------------------------------
# T1 (user) — install sous $HOME/.claude, RIEN sous ./.claude du lab
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
FAKE_HOME="$LAB/home"
mkdir -p "$FAKE_HOME"
if prepare_module "$CACHE" "dev-orchestrator"; then
  (cd "$LAB" && HOME="$FAKE_HOME" VF_SCOPE=user VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" install dev-orchestrator >/dev/null 2>&1)
  miss=0
  [ -f "$FAKE_HOME/.claude/agents/dev-orchestrator.md" ] \
    || { ko "T1 user : \$HOME/.claude/agents/dev-orchestrator.md manquant"; miss=1; }
  # RIEN ne doit apparaître sous ./.claude du lab (cwd projet).
  if [ -d "$LAB/.claude" ]; then
    ko "T1 user : ./.claude présent dans le lab (devrait être vide — scope user → \$HOME)"
    miss=1
  fi
  [ "$miss" -eq 0 ] && ok "T1 user : agent écrit sous \$HOME/.claude, rien sous ./.claude du lab"
else
  skip "T1 user : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T2 (project défaut) — install sous ./.claude du lab ; rétro-compat D7
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
if prepare_module "$CACHE" "dev-orchestrator"; then
  # Sans VF_SCOPE : défaut LEGACY project → ./.claude (comportement historique).
  (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" install dev-orchestrator >/dev/null 2>&1)
  miss=0
  [ -f "$LAB/.claude/agents/dev-orchestrator.md" ] \
    || { ko "T2 project : ./.claude/agents/dev-orchestrator.md manquant"; miss=1; }
  # Rétro-compat references D7 (au moins les 3 references canoniques — v2.0.0 :
  # vocabulary-map supprimée avec la façade, intent-routing la remplace comme canon).
  for ref in GSD-PIPELINE.md gsd-skills-index.md intent-routing.md; do
    [ -f "$LAB/.claude/agents/dev-orchestrator-references/$ref" ] \
      || { ko "T2 project : references/$ref manquant (rétro-compat D7)"; miss=1; }
  done
  [ "$miss" -eq 0 ] && ok "T2 project : artefacts sous ./.claude du lab (agent + references D7 présents)"
else
  skip "T2 project : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T3 (local → gitignore idempotent)
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
if prepare_module "$CACHE" "dev-orchestrator"; then
  (cd "$LAB" && VF_SCOPE=local VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" install dev-orchestrator >/dev/null 2>&1)
  # 2e run : doit rester idempotent (pas de doublon).
  (cd "$LAB" && VF_SCOPE=local VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" install dev-orchestrator >/dev/null 2>&1)
  miss=0
  if [ ! -f "$LAB/.gitignore" ]; then
    ko "T3 local : ./.gitignore non créé"
    miss=1
  else
    # Le chemin de l'agent dev-orchestrator doit être présent exactement une fois.
    n=$("$GREP" -cxF ".claude/agents/dev-orchestrator.md" "$LAB/.gitignore" || true)
    [ "${n:-0}" -eq 1 ] \
      || { ko "T3 local : .claude/agents/dev-orchestrator.md apparaît $n fois (attendu 1, idempotence)"; miss=1; }
  fi
  [ "$miss" -eq 0 ] && ok "T3 local : .gitignore contient le chemin agent, sans doublon après 2 runs (idempotent)"
else
  skip "T3 local : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T3b (local → registres mémoire sous SCOPE-04)
# Le seed post-install crée .claude/memory/ ; en scope local, la promesse « rien ne
# sera committé » doit couvrir ces fichiers-là aussi — pas seulement les artefacts
# que l'engine copie lui-même. Sans la ligne dédiée de gitignore_add_paths, les 5
# registres semés apparaissaient en untracked dans le git status du projet.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
if prepare_module "$CACHE" "consolidator"; then
  (cd "$LAB" && git init -q && VF_SCOPE=local VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" install consolidator >/dev/null 2>&1)
  miss=0
  n=$("$GREP" -cxF ".claude/memory/" "$LAB/.gitignore" 2>/dev/null || true)
  [ "${n:-0}" -eq 1 ] \
    || { ko "T3b local : .claude/memory/ absent du .gitignore (ou en doublon : $n)"; miss=1; }
  # Les registres doivent exister (seed exécuté) ET être invisibles au status.
  [ -f "$LAB/.claude/memory/DECISIONS.md" ] \
    || { ko "T3b local : registres non instanciés par le seed post-install"; miss=1; }
  leaked=$(cd "$LAB" && git status --porcelain | "$GREP" -c "memory" || true)
  [ "${leaked:-0}" -eq 0 ] \
    || { ko "T3b local : $leaked entrée(s) memory dans le git status — SCOPE-04 violé"; miss=1; }
  [ "$miss" -eq 0 ] && ok "T3b local : registres semés ET gitignorés (SCOPE-04 tenu jusqu'aux registres)"
else
  skip "T3b local : consolidator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T3c (local → .claude/settings.json + .claude/settings.local.json gitignorés, Phase 30 tâche 4 +
# correction ciblée post-revue) — un module qui PORTE un fragment hooks/hooks.json écrit dans
# $TARGET_ROOT/settings.json (merge_module_hooks) ET, depuis le routage --settings-local, dans
# $TARGET_ROOT/settings.local.json pour toute entrée portant {{VF_BASH}} ; en scope local, la
# promesse « rien ne sera committé » doit couvrir les DEUX fichiers. Avant ce plan, aucune ligne de
# gitignore_add_paths() ne couvrait settings.json — mesuré à la lecture réelle du fichier, pas
# supposé (voir SUMMARY, écart de comptage ~12 vs réel). settings.local.json est resté NON couvert
# une itération de plus : la revue a testé — et invalidé — l'hypothèse que la convention de nommage
# suffisait sans une entrée .gitignore explicite du DÉPÔT CIBLE (elle ne tenait que via le
# ~/.config/git/ignore personnel du mainteneur, absent sur un lab frais).
# Cas négatif : le même module en scope PROJECT ⇒ .gitignore n'est ni créé ni modifié (SCOPE-04
# reste borné au scope local, gitignore_add_paths() retourne tôt sur tout autre scope).
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
if prepare_module "$CACHE" "dev-orchestrator"; then
  (cd "$LAB" && git init -q && VF_SCOPE=local VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" install dev-orchestrator >/dev/null 2>&1)
  # 2e run sur le même lab : idempotence, pas de doublon.
  (cd "$LAB" && VF_SCOPE=local VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" install dev-orchestrator >/dev/null 2>&1)
  miss=0
  n=$("$GREP" -cxF ".claude/settings.json" "$LAB/.gitignore" 2>/dev/null || true)
  [ "${n:-0}" -eq 1 ] \
    || { ko "T3c local : .claude/settings.json apparaît $n fois dans .gitignore (attendu 1)"; miss=1; }
  [ "$miss" -eq 0 ] && ok "T3c local : .claude/settings.json gitignoré exactement une fois, idempotent après 2 runs"
  miss=0
  n=$("$GREP" -cxF ".claude/settings.local.json" "$LAB/.gitignore" 2>/dev/null || true)
  [ "${n:-0}" -eq 1 ] \
    || { ko "T3c local : .claude/settings.local.json apparaît $n fois dans .gitignore (attendu 1)"; miss=1; }
  [ "$miss" -eq 0 ] && ok "T3c local : .claude/settings.local.json gitignoré exactement une fois, idempotent après 2 runs (correction post-revue)"
else
  skip "T3c local : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

LAB="$(mktemp -d)"
CACHE="$LAB/cache"
if prepare_module "$CACHE" "dev-orchestrator"; then
  (cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" install dev-orchestrator >/dev/null 2>&1)
  if [ -f "$LAB/.gitignore" ]; then
    ko "T3c (négatif) project : .gitignore créé alors que le scope n'est pas local (SCOPE-04 violé)"
  else
    ok "T3c (négatif) project : .gitignore absent/inchangé — SCOPE-04 reste borné au scope local"
  fi
else
  skip "T3c (négatif) project : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T4 (no clone) — assert statique sur le source de l'engine
# ---------------------------------------------------------------------------
if "$GREP" -nE 'git clone|git pull' "$INSTALLER" >/dev/null 2>&1; then
  ko "T4 no-clone : 'git clone'/'git pull' encore présent dans l'engine"
else
  ok "T4 no-clone : aucun 'git clone'/'git pull' dans l'engine (source = cache fourni)"
fi

# ---------------------------------------------------------------------------
# T5 (résolveur RÉELLEMENT exercé) — fermeture transitive de validator
# ---------------------------------------------------------------------------
# En prod, Phase 5 (PLUG-02) bundle resolve-deps.sh dans le cache du plugin ; ce test
# reproduit ce bundling en copiant le résolveur dans $CACHE/_internal/.
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
# audit-architecture requis par validator depuis UAT F2 (Phase 4, même opt-in).
CLOSURE="validator consolidator infrastructure-audit audit-architecture"
copy_ok=1
for m in $CLOSURE; do
  prepare_module "$CACHE" "$m" || { copy_ok=0; break; }
  [ -f "$CACHE/$m/module.json" ] || { copy_ok=0; break; }
done
if [ "$copy_ok" -eq 0 ]; then
  skip "T5 résolveur : module.json de validator/consolidator/infrastructure-audit/audit-architecture non copiables"
elif [ ! -f "$RESOLVER" ]; then
  skip "T5 résolveur : resolve-deps.sh introuvable dans le repo ($RESOLVER)"
else
  # Copier le résolveur RÉEL dans le cache → resolve_closure le trouve et l'EXÉCUTE
  # (pas le fallback bruyant). C'est le chemin nominal de prod (PLUG-02).
  mkdir -p "$CACHE/_internal"
  cp "$RESOLVER" "$CACHE/_internal/resolve-deps.sh"
  (cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" install --with-deps validator >/dev/null 2>&1)
  miss=0
  # Fermeture installée : validator (agent), consolidator (skill), infrastructure-audit (skill).
  [ -f "$LAB/.claude/agents/validator.md" ] \
    || { ko "T5 résolveur : validator (agent) non installé"; miss=1; }
  [ -f "$LAB/.claude/skills/consolidator/SKILL.md" ] \
    || { ko "T5 résolveur : consolidator (dépendance) non installé"; miss=1; }
  [ -f "$LAB/.claude/skills/infrastructure-audit/SKILL.md" ] \
    || { ko "T5 résolveur : infrastructure-audit (dépendance) non installé"; miss=1; }
  [ -f "$LAB/.claude/skills/audit-architecture/SKILL.md" ] \
    || { ko "T5 résolveur : audit-architecture (dépendance, UAT F2) non installé"; miss=1; }
  [ "$miss" -eq 0 ] \
    && ok "T5 résolveur : --with-deps validator installe la fermeture {validator, consolidator, infrastructure-audit, audit-architecture} (résolveur RÉELLEMENT exercé)"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T6 (uninstall --all) — installe 2 modules puis les retire tous d'un coup
# ---------------------------------------------------------------------------
# Vérifie : après `uninstall --all`, les artefacts des 2 modules sont retirés ET le registre
# .vibeflow-installed est vide (aucune entrée résiduelle).
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
if prepare_module "$CACHE" "dev-orchestrator" && prepare_module "$CACHE" "consolidator"; then
  # Install des 2 modules (scope project → ./.claude du lab).
  (cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" install dev-orchestrator >/dev/null 2>&1)
  (cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" install consolidator >/dev/null 2>&1)
  # Retrait global.
  (cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" uninstall --all >/dev/null 2>&1)
  miss=0
  # Artefacts des 2 modules retirés.
  [ ! -f "$LAB/.claude/agents/dev-orchestrator.md" ] \
    || { ko "T6 uninstall --all : agent dev-orchestrator encore présent"; miss=1; }
  [ ! -d "$LAB/.claude/agents/dev-orchestrator-references" ] \
    || { ko "T6 uninstall --all : references dev-orchestrator encore présentes"; miss=1; }
  [ ! -d "$LAB/.claude/skills/consolidator" ] \
    || { ko "T6 uninstall --all : skill consolidator encore présent"; miss=1; }
  # Skills IMBRIQUÉS du module agent (Type 2 : skills/vf-*/) — le trou historique : l'uninstall
  # ne retirait que skills/<mod>, laissant les vf-* orphelins.
  [ ! -d "$LAB/.claude/skills/vf-dev" ] \
    || { ko "T6 uninstall --all : skill imbriqué vf-dev encore présent"; miss=1; }
  # Sous-dossier scripts/tests/ du module retiré (miroir de copy_module_scripts).
  [ ! -f "$LAB/.claude/scripts/tests/test-dag.sh" ] \
    || { ko "T6 uninstall --all : test-dag.sh (scripts/tests/) encore présent"; miss=1; }
  # Registre vide (plus aucune ligne module=version).
  REG="$LAB/.claude/scripts/.vibeflow-installed"
  if [ -f "$REG" ]; then
    n=$("$GREP" -cE '^[a-zA-Z]' "$REG" || true)
    [ "${n:-0}" -eq 0 ] \
      || { ko "T6 uninstall --all : registre non vide ($n entrée(s) résiduelle(s))"; miss=1; }
  fi
  [ "$miss" -eq 0 ] \
    && ok "T6 uninstall --all : 2 modules installés puis tous retirés, registre vide"
else
  skip "T6 uninstall --all : dev-orchestrator/consolidator non copiables dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T7 (cleanup modules retirés) — un lab qui avait feature-dev-gates converge à update --all
# ---------------------------------------------------------------------------
# Simule un lab ayant installé un module DEPUIS RETIRÉ (feature-dev-gates) : rule orpheline +
# entrée de registre. Après `update --all`, l'orphelin doit disparaître ET le registre être nettoyé,
# SANS casser un module valide encore installé (consolidator).
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
MANIFEST_SRC="$INTERNAL_DIR/retired-modules.txt"
if prepare_module "$CACHE" "consolidator" && [ -f "$MANIFEST_SRC" ]; then
  # Le manifeste des modules retirés doit vivre dans le cache (comme en prod, bundlé).
  mkdir -p "$CACHE/_internal"
  cp "$MANIFEST_SRC" "$CACHE/_internal/retired-modules.txt"
  # Install d'un module valide (crée le registre).
  (cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" install consolidator >/dev/null 2>&1)
  # Simuler l'état "feature-dev-gates encore installé" : artefact orphelin + entrée registre.
  mkdir -p "$LAB/.claude/rules"
  echo "# orphan" > "$LAB/.claude/rules/feature-dev-gates.md"
  echo "feature-dev-gates=v1.0.1" >> "$LAB/.claude/scripts/.vibeflow-installed"
  # Convergence.
  (cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" update --all >/dev/null 2>&1)
  miss=0
  [ ! -f "$LAB/.claude/rules/feature-dev-gates.md" ] \
    || { ko "T7 cleanup : rule orpheline feature-dev-gates.md encore présente"; miss=1; }
  REG="$LAB/.claude/scripts/.vibeflow-installed"
  if [ -f "$REG" ] && "$GREP" -q "^feature-dev-gates=" "$REG"; then
    ko "T7 cleanup : entrée registre feature-dev-gates non retirée"; miss=1
  fi
  # Module valide toujours là (le nettoyage n'a rien cassé).
  [ -d "$LAB/.claude/skills/consolidator" ] \
    || { ko "T7 cleanup : consolidator (module valide) cassé par le nettoyage"; miss=1; }
  [ "$miss" -eq 0 ] \
    && ok "T7 cleanup : module retiré (rule orpheline + registre) nettoyé à update --all, module valide intact"
else
  skip "T7 cleanup : consolidator non copiable ou manifeste retired-modules.txt absent"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T8 (VG-3) — module avec hooks mais merge-hooks.sh INTROUVABLE → install ÉCHOUE (exit ≠ 0)
# et le module n'est PAS marqué installé (le lab ne peut plus croire avoir sa gouvernance).
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
# Engine copié SEUL dans un dossier isolé : ni $CACHE/_internal/merge-hooks.sh ni le repli
# $(dirname $0)/merge-hooks.sh n'existent → merge_module_hooks doit propager l'échec.
mkdir -p "$LAB/engine" "$CACHE/hooked/scripts" "$CACHE/hooked/hooks"
cp "$INSTALLER" "$LAB/engine/vibeflow-update.sh"
echo v1.0.0 > "$CACHE/hooked/VERSION"
printf '{"name":"hooked","version":"v1.0.0"}\n' > "$CACHE/hooked/module.json"
printf '#!/usr/bin/env bash\necho x\n' > "$CACHE/hooked/scripts/hooked.sh"
printf '{"hooks":{"SessionStart":[{"matcher":"startup","hooks":[{"type":"command","command":"bash {{VF_SCRIPTS}}/hooked.sh || true"}]}]}}\n' > "$CACHE/hooked/hooks/hooks.json"
rc=0
(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" \
   bash "$LAB/engine/vibeflow-update.sh" install hooked >/dev/null 2>&1) || rc=$?
miss=0
[ "$rc" -ne 0 ] \
  || { ko "T8 VG-3 : install exit 0 malgré la gouvernance non câblée (merger absent)"; miss=1; }
if [ -f "$LAB/.claude/scripts/.vibeflow-installed" ] \
   && "$GREP" -q '^hooked=' "$LAB/.claude/scripts/.vibeflow-installed"; then
  ko "T8 VG-3 : module marqué installé alors que ses hooks ne sont pas câblés"; miss=1
fi
[ "$miss" -eq 0 ] \
  && ok "T8 VG-3 : merger absent → install échoue (rc=$rc) et registre non menteur"
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T9 (DISCRIMINANT) — les fichiers de DONNÉES *.txt d'un module sont posés chez l'utilisateur.
# Dette constatée le 2026-07-26 : copy_module_scripts() ne globbait que *.sh|*.mjs|*.js, donc
# `known-versions.txt` (lu par audit-infra.sh en $SCRIPTS_DIR/known-versions.txt) n'arrivait
# JAMAIS à l'install. Trois assertions, dont deux bornent le glob par le bas et par le haut :
# le .txt est posé (sinon la dette est intacte), le résidu .bak ne l'est PAS (sinon le glob
# ratisse trop large), et le .txt n'est pas exécutable (données ≠ exécutable).
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
mkdir -p "$CACHE/dataful/scripts"
echo v1.0.0 > "$CACHE/dataful/VERSION"
printf '{"name":"dataful","version":"v1.0.0"}\n' > "$CACHE/dataful/module.json"
printf '#!/usr/bin/env bash\necho x\n' > "$CACHE/dataful/scripts/dataful.sh"
printf '2.0.14\n2.0.15\n' > "$CACHE/dataful/scripts/known-versions.txt"
printf '#!/usr/bin/env bash\necho residu\n' > "$CACHE/dataful/scripts/dataful.sh.bak"
(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" \
   bash "$INSTALLER" install dataful >/dev/null 2>&1) || true
miss=0
[ -f "$LAB/.claude/scripts/known-versions.txt" ] \
  || { ko "T9 : known-versions.txt non posé — dette 'fichier de données jamais installé' intacte"; miss=1; }
[ ! -f "$LAB/.claude/scripts/dataful.sh.bak" ] \
  || { ko "T9 : résidu .bak posé — le glob de données ratisse trop large"; miss=1; }
[ ! -x "$LAB/.claude/scripts/known-versions.txt" ] \
  || { ko "T9 : known-versions.txt marqué exécutable — c'est une donnée, pas un script"; miss=1; }
[ "$miss" -eq 0 ] \
  && ok "T9 (DISCRIMINANT) : *.txt posé non exécutable, résidu .bak écarté"
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# Helper (Phase 30 tâche 07, PORT-02) — vérifie la forme exec TELLE QU'INSTALLÉE dans un
# settings*.json : chaque entrée VF (clé `args` présente) porte un `command` ABSOLU, EXISTANT,
# EXÉCUTABLE sur cette machine, et aucun placeholder {{...}} ne subsiste dans le fichier entier.
# `expect_n`, si fourni, doit égaler EXACTEMENT le nombre d'entrées exec trouvées — sinon KO en
# nommant les scripts présents (c'est ce qui fait rougir le cas sous mutation, tâche 2).
# Garde anti-vert-à-vide : 0 entrée est TOUJOURS un échec, `expect_n` fourni ou non.
# ---------------------------------------------------------------------------
check_exec_settings() {
  local settings="$1" expect_n="${2:-}"
  python3 - "$settings" "$expect_n" <<'PYEOF'
import json, os, sys
path, expect = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else "")
if not os.path.isfile(path):
    print(f"{path} : fichier absent (0 entrée VF posée — garde anti-vert-à-vide)")
    sys.exit(1)
raw = open(path, encoding="utf-8").read()
if "{{" in raw:
    print(f"{path} : placeholder littéral résiduel")
    sys.exit(1)
try:
    d = json.loads(raw) if raw.strip() else {}
except Exception as e:
    print(f"{path} : JSON invalide ({e})")
    sys.exit(1)
entries = []
for ev, groups in d.get("hooks", {}).items():
    for g in groups or []:
        for h in g.get("hooks", []) or []:
            if "args" in h:
                entries.append(h)
if not entries:
    print(f"{path} : 0 entrée VF (args) posée — garde anti-vert-à-vide")
    sys.exit(1)
if expect and str(len(entries)) != str(expect):
    names = []
    for h in entries:
        for a in h.get("args", []) or []:
            if isinstance(a, str) and (a.endswith(".sh") or a.endswith(".py")):
                names.append(a.rsplit("/", 1)[-1])
    print(f"{path} : {len(entries)} entrée(s) exec (attendu {expect}) — présentes : {sorted(names)}")
    sys.exit(1)
for h in entries:
    cmd = h.get("command", "")
    if not cmd.startswith("/") or not (os.path.isfile(cmd) and os.access(cmd, os.X_OK)):
        print(f"{path} : command non absolu/exécutable sur cette machine : {cmd!r}")
        sys.exit(1)
print(f"{path} : {len(entries)} entrée(s) exec, command absolu+exécutable, aucun placeholder")
sys.exit(0)
PYEOF
}

# ---------------------------------------------------------------------------
# T10 (forme exec TELLE QU'INSTALLÉE, PORT-02) — install réelle des deux modules du périmètre
# dev, assertions sur le settings.local.json PRODUIT (pas sur les fragments source — régression
# #38 : un gate qui n'exerce que l'arbre source ne prouve rien sur ce que l'install pose chez
# l'utilisateur). Les 5 entrées ({{VF_BASH}} dans les deux fragments) routent vers
# settings.local.json en scope project (défaut) — jamais settings.json.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
if prepare_module "$CACHE" "dev-orchestrator" && prepare_module "$CACHE" "software-architecture"; then
  (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install dev-orchestrator >/dev/null 2>&1)
  (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install software-architecture >/dev/null 2>&1)
  MSG=$(check_exec_settings "$LAB/.claude/settings.local.json" 5 2>&1); RC=$?
  if [ "$RC" -eq 0 ]; then
    ok "T10 exec install (as-installed) : $MSG"
  else
    ko "T10 exec install (as-installed) : $MSG"
  fi

  # T10-uninstall : désinstaller les deux modules laisse ZÉRO entrée VF résiduelle, settings
  # valides. Vérifié sur les DEUX fichiers (settings.json ET settings.local.json).
  (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" uninstall dev-orchestrator >/dev/null 2>&1)
  (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" uninstall software-architecture >/dev/null 2>&1)
  miss=0
  for f in "$LAB/.claude/settings.json" "$LAB/.claude/settings.local.json"; do
    if [ -f "$f" ]; then
      n=$(python3 -c "
import json
d = json.load(open('$f', encoding='utf-8'))
print(sum(len(h.get('hooks', [])) for gs in d.get('hooks', {}).values() for h in gs))
")
      [ "$n" -eq 0 ] || { ko "T10 uninstall : $f porte encore $n entrée(s) de hooks résiduelle(s)"; miss=1; }
      python3 -m json.tool "$f" >/dev/null 2>&1 || { ko "T10 uninstall : $f n'est plus un JSON valide"; miss=1; }
    fi
  done
  [ "$miss" -eq 0 ] && ok "T10 uninstall : dev-orchestrator + software-architecture retirés, zéro entrée VF résiduelle, settings valides"
else
  skip "T10 exec install : dev-orchestrator/software-architecture non copiables dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T10b (garde anti-vert-à-vide, prouvée) — check_exec_settings() échoue si le fichier n'a AUCUNE
# entrée VF, plutôt que de passer silencieusement sur un settings.local.json vide/inexistant.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
mkdir -p "$LAB/.claude"
printf '{"hooks":{}}\n' > "$LAB/.claude/settings.local.json"
MSG=$(check_exec_settings "$LAB/.claude/settings.local.json" 2>&1); RC=$?
if [ "$RC" -ne 0 ]; then
  ok "T10b garde anti-vert-à-vide : settings.local.json sans entrée VF fait échouer le cas ($MSG)"
else
  ko "T10b garde anti-vert-à-vide : settings.local.json vide a été accepté à tort"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T11 (compatibilité descendante à l'update, le scénario qui compte réellement — A-30-07-1) :
# un lab qui a installé dev-orchestrator AVANT cette phase porte ses 4 hooks en ANCIENNE forme
# shell dans settings.json (fragment shell + prefix littéral déjà résolu, comme le posait
# merge-hooks.sh avant la migration). On lance l'installeur ACTUEL (fragment migré, tâche 1) et on
# attend : les 4 anciennes entrées shell ont disparu de settings.json, remplacées par 4 entrées
# exec dans settings.local.json — une seule par script, aucun doublon nulle part.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
if prepare_module "$CACHE" "dev-orchestrator"; then
  mkdir -p "$LAB/.claude"
  OLD_FRAGMENT="$LAB/old-dev-orchestrator-hooks.json"
  cat > "$OLD_FRAGMENT" <<'EOF'
{
  "description": "Signaux de démarrage du moteur de dev (forme shell — état du parc AVANT la Phase 30 tâche 07).",
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          { "type": "command", "command": "bash {{VF_SCRIPTS}}/check-dev-bootstrap.sh --hook || true" },
          { "type": "command", "command": "bash {{VF_SCRIPTS}}/discover-unintegrated-docs.sh --hook || true" },
          { "type": "command", "command": "bash {{VF_SCRIPTS}}/check-doc-drift.sh --hook || true" },
          { "type": "command", "command": "bash {{VF_SCRIPTS}}/check-gsd-config.sh --hook || true" }
        ]
      }
    ]
  }
}
EOF
  # Simule le settings.json d'un lab déjà installé, EN DEHORS de l'installeur (le vécu d'un lab
  # existant, jamais réinstallé depuis) : merge direct de l'ancien fragment shell.
  bash "$INTERNAL_DIR/merge-hooks.sh" merge "$OLD_FRAGMENT" \
    --settings "$LAB/.claude/settings.json" \
    --scripts-prefix '"$CLAUDE_PROJECT_DIR"/.claude/scripts' >/dev/null 2>&1
  BEFORE_N=$(python3 -c "
import json
d = json.load(open('$LAB/.claude/settings.json', encoding='utf-8'))
print(sum(len(h.get('hooks', [])) for gs in d.get('hooks', {}).values() for h in gs))
" 2>/dev/null || echo 0)

  # Update réel : cache = état ACTUEL du repo (fragment migré par la tâche 1).
  (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install dev-orchestrator >/dev/null 2>&1)

  miss=0
  [ "$BEFORE_N" -eq 4 ] || { ko "T11 compat descendante : pré-seed shell invalide ($BEFORE_N entrées avant update, attendu 4)"; miss=1; }
  OLD_RESIDUAL=$(python3 -c "
import json
d = json.load(open('$LAB/.claude/settings.json', encoding='utf-8'))
names = set()
import re
pat = re.compile(r'([A-Za-z0-9._-]+\.(?:sh|py))')
for gs in d.get('hooks', {}).values():
    for g in gs:
        for h in g.get('hooks', []):
            names.update(pat.findall(h.get('command', '')))
            for a in h.get('args', []) or []:
                if isinstance(a, str):
                    names.update(pat.findall(a))
expected = {'check-dev-bootstrap.sh', 'discover-unintegrated-docs.sh', 'check-doc-drift.sh', 'check-gsd-config.sh'}
print(len(names & expected))
")
  [ "$OLD_RESIDUAL" -eq 0 ] || { ko "T11 compat descendante : $OLD_RESIDUAL ancienne(s) entrée(s) shell encore dans settings.json (attendu 0, purge cross-cible en échec)"; miss=1; }
  MSG=$(check_exec_settings "$LAB/.claude/settings.local.json" 4 2>&1) || { ko "T11 compat descendante : $MSG"; miss=1; }
  [ "$miss" -eq 0 ] \
    && ok "T11 compat descendante : lab shell pré-existant → update réel → 4 anciennes entrées purgées de settings.json, 4 entrées exec dans settings.local.json (une seule par script)"
else
  skip "T11 compat descendante : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T12 (mutation, discriminance de T10 prouvée) — remettre UNE entrée en forme shell dans le
# fragment dev-orchestrator (check-doc-drift.sh) doit faire rougir check_exec_settings(), en
# nommant l'entrée fautive absente du décompte exec. La régression jouée ici serait invisible à
# un test qui ne compterait que "au moins 1 entrée exec".
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
if prepare_module "$CACHE" "dev-orchestrator"; then
  # Mutation : un seul hook repasse en forme shell (perte du champ `args`), les 3 autres restent
  # en forme exec — reproduit exactement une régression partielle, pas un retour en bloc.
  python3 -c "
import json
p = '$CACHE/dev-orchestrator/hooks/hooks.json'
d = json.load(open(p, encoding='utf-8'))
group = d['hooks']['SessionStart'][0]
for h in group['hooks']:
    if 'check-doc-drift.sh' in ' '.join(h.get('args', [])):
        h.pop('args', None)
        h['command'] = 'bash {{VF_SCRIPTS}}/check-doc-drift.sh --hook || true'
json.dump(d, open(p, 'w', encoding='utf-8'), indent=2, ensure_ascii=False)
"
  (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install dev-orchestrator >/dev/null 2>&1)
  MSG=$(check_exec_settings "$LAB/.claude/settings.local.json" 4 2>&1); RC=$?
  # L'entrée fautive est celle des 4 scripts attendus ABSENTE du décompte exec — calculée par
  # différence d'ensemble, pour la nommer explicitement plutôt que de se contenter de "3 ≠ 4".
  FAUTIVE=$(python3 -c "
expected = {'check-dev-bootstrap.sh', 'discover-unintegrated-docs.sh', 'check-doc-drift.sh', 'check-gsd-config.sh'}
msg = '''$MSG'''
present = {n.strip(\"' \") for n in msg.split('[', 1)[-1].split(']', 1)[0].split(',')} if '[' in msg else set()
print(', '.join(sorted(expected - present)) or 'aucune (décompte inattendu)')
" 2>/dev/null)
  if [ "$RC" -ne 0 ] && [ "$FAUTIVE" = "check-doc-drift.sh" ]; then
    ok "T12 mutation (trace du rouge) : entrée fautive nommée = $FAUTIVE (remise en forme shell) → cas rouge ($MSG)"
  else
    ko "T12 mutation : la mutation shell aurait dû faire rougir le cas exec-count en nommant check-doc-drift.sh, obtenu rc=$RC entrée-fautive='$FAUTIVE' (msg=$MSG)"
  fi
else
  skip "T12 mutation : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# Garde-fou final : le vrai ~/.claude est inchangé (snapshot récursif avant=après).
# ---------------------------------------------------------------------------
HOME_AFTER=$(snapshot_home_claude)
if [ "$HOME_BEFORE" = "$HOME_AFTER" ]; then
  ok "Garde-fou : ~/.claude intact ($HOME_AFTER fichiers dans les zones engine avant=après)"
else
  ko "Garde-fou : ~/.claude POLLUÉ (avant=$HOME_BEFORE, après=$HOME_AFTER — zones agents/skills/scripts/rules/commands/settings)"
fi

# ---------------------------------------------------------------------------
echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ]
