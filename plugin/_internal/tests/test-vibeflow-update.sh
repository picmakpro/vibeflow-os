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

# Idem, pour ~/.codex/agents/vibeflow réel (T37/T38, 38-05 wiring adaptateur Codex) — les deux
# tests isolent HOME systématiquement, ce compteur n'est qu'une ceinture+bretelles.
snapshot_home_codex() {
  find "$HOME/.codex/agents/vibeflow" -type f 2>/dev/null | wc -l | tr -d ' '
}
HOME_CODEX_BEFORE=$(snapshot_home_codex)

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
# l'utilisateur). Les 6 entrées portant {{VF_BASH}} (5 de dev-orchestrator + 1 de
# software-architecture) routent vers settings.local.json en scope project (défaut) — jamais
# settings.json. check-hook-paths.sh (6e script dev-orchestrator) garde un command littéral
# 'bash' non substitué (dérogation ADR-071 documentée dans hooks.json) : il reste en
# settings.json, hors du décompte exec ci-dessous.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
if prepare_module "$CACHE" "dev-orchestrator" && prepare_module "$CACHE" "software-architecture"; then
  (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install dev-orchestrator >/dev/null 2>&1)
  (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install software-architecture >/dev/null 2>&1)
  MSG=$(check_exec_settings "$LAB/.claude/settings.local.json" 6 2>&1); RC=$?
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
# merge-hooks.sh avant la migration). On lance l'installeur ACTUEL (fragment migré, tâche 1 +
# 5e script check-requirements-survival.sh ajouté par la Phase 18) et on attend : les 4 anciennes
# entrées shell ont disparu de settings.json, remplacées par 5 entrées exec dans
# settings.local.json — une seule par script, aucun doublon nulle part (check-hook-paths.sh, 6e
# script du fragment actuel, reste hors décompte : command littéral non substitué, routé vers
# settings.json).
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
  MSG=$(check_exec_settings "$LAB/.claude/settings.local.json" 5 2>&1) || { ko "T11 compat descendante : $MSG"; miss=1; }
  [ "$miss" -eq 0 ] \
    && ok "T11 compat descendante : lab shell pré-existant → update réel → 4 anciennes entrées purgées de settings.json, 5 entrées exec dans settings.local.json (une seule par script)"
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
  # Mutation : un seul hook repasse en forme shell (perte du champ `args`), les 4 autres restent
  # en forme exec — reproduit exactement une régression partielle, pas un retour en bloc.
  # (check-hook-paths.sh, le 6e script du fragment, reste hors décompte : command littéral non
  # substitué, routé vers settings.json — jamais dans settings.local.json.)
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
  MSG=$(check_exec_settings "$LAB/.claude/settings.local.json" 5 2>&1); RC=$?
  # L'entrée fautive est celle des 5 scripts attendus ABSENTE du décompte exec — calculée par
  # différence d'ensemble, pour la nommer explicitement plutôt que de se contenter de "4 ≠ 5".
  FAUTIVE=$(python3 -c "
expected = {'check-dev-bootstrap.sh', 'discover-unintegrated-docs.sh', 'check-doc-drift.sh', 'check-gsd-config.sh', 'check-requirements-survival.sh'}
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
# T13 (ROLL-01) — backup_module symétrique : skills/ + agents/rollmod.md + agent-references/,
# jamais 2 catégories sur 3 (le trou mesuré au cadrage : agents/agent-references DÉJÀ backupés
# mais JAMAIS relus côté rollback avant ce lot).
# T14 (ROLL-03) — .version capturé au backup = version installée AU MOMENT du backup.
# T15 (ROLL-01..04, round-trip RÉEL) — install v1 -> install v2 (déclenche le backup auto) ->
# rollback -> CONTENU (marqueurs distincts v1/v2, pas seulement présence) ET registre restaurés
# à v1, jamais laissés à v2.
# T17 (ROLL-04, régression) — rollback d'un module JAMAIS backuppé échoue toujours bruyamment
# après le filtrage du glob (cas déjà couvert par le err existant, reconfirmé après ce lot).
#
# Layout du module de fixture : skills/rollmod/SKILL.md (Type 2, PAS de SKILL.md racine) +
# AGENT.md + references/ — un module avec SKILL.md racine route ses references/ sous
# skills/$mod/references/ (ligne ~1507), PAS agents/$mod-references/ (ligne ~1515, qui exige
# explicitement l'ABSENCE de SKILL.md racine) : ce layout est la SEULE combinaison qui peuple les
# 3 catégories (skills + agents + agent-references) simultanément.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
mkdir -p "$CACHE/rollmod/skills/rollmod" "$CACHE/rollmod/references"
echo v1.0.0 > "$CACHE/rollmod/VERSION"
printf '{"name":"rollmod","version":"v1.0.0"}\n' > "$CACHE/rollmod/module.json"
printf '# rollmod SKILL (MARKER-V1)\n' > "$CACHE/rollmod/skills/rollmod/SKILL.md"
printf '# rollmod AGENT (MARKER-V1)\n' > "$CACHE/rollmod/AGENT.md"
printf 'note v1\n' > "$CACHE/rollmod/references/note.md"

(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install rollmod >/dev/null 2>&1)
V1_REGISTRY=$("$GREP" '^rollmod=' "$LAB/.claude/scripts/.vibeflow-installed" 2>/dev/null | cut -d= -f2)

# Bump vers v2 dans le cache — contenu DISTINGUABLE (marqueur v2) : le round-trip (T15) doit
# prouver une restauration de CONTENU, pas seulement de présence de fichier.
echo v2.0.0 > "$CACHE/rollmod/VERSION"
printf '{"name":"rollmod","version":"v2.0.0"}\n' > "$CACHE/rollmod/module.json"
printf '# rollmod SKILL (MARKER-V2)\n' > "$CACHE/rollmod/skills/rollmod/SKILL.md"
printf '# rollmod AGENT (MARKER-V2)\n' > "$CACHE/rollmod/AGENT.md"
printf 'note v2\n' > "$CACHE/rollmod/references/note.md"
(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install rollmod >/dev/null 2>&1)
V2_REGISTRY=$("$GREP" '^rollmod=' "$LAB/.claude/scripts/.vibeflow-installed" 2>/dev/null | cut -d= -f2)

BDIR=$(ls -1dt "$LAB/.claude/.backups/rollmod"-* 2>/dev/null | "$GREP" -v -- '-removed$' | head -1)
miss=0
[ -n "$BDIR" ] && [ -d "$BDIR/skills" ] || { ko "T13 backup symétrique : skills/ absent du backup"; miss=1; }
[ -n "$BDIR" ] && [ -f "$BDIR/agents/rollmod.md" ] || { ko "T13 backup symétrique : agents/rollmod.md absent du backup"; miss=1; }
[ -n "$BDIR" ] && [ -d "$BDIR/agent-references" ] || { ko "T13 backup symétrique : agent-references/ absent du backup"; miss=1; }
[ "$miss" -eq 0 ] && ok "T13 (ROLL-01) : backup_module capture les 3 catégories (skills+agents+agent-references), jamais 2/3"

if [ -n "$BDIR" ] && [ -f "$BDIR/.version" ] && [ "$(cat "$BDIR/.version")" = "$V1_REGISTRY" ]; then
  ok "T14 (ROLL-03) : backup_module capture la version installée AU MOMENT du backup (.version=$V1_REGISTRY)"
else
  ko "T14 (ROLL-03) : .version du backup ne correspond pas à la version v1 capturée (attendu '$V1_REGISTRY', obtenu '$([ -n "$BDIR" ] && cat "$BDIR/.version" 2>/dev/null || echo absent)')"
fi

# Pré-condition du round-trip : le disque porte actuellement v2 (overwrite par le 2e install).
"$GREP" -q "MARKER-V2" "$LAB/.claude/agents/rollmod.md" 2>/dev/null \
  || ko "T15 pré-condition : contenu v2 attendu sur disque avant rollback (garde-fou du test lui-même)"

(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" rollback rollmod >/dev/null 2>&1)
miss=0
[ -f "$LAB/.claude/skills/rollmod/SKILL.md" ] || { ko "T15 round-trip : skills/rollmod/SKILL.md absent après rollback"; miss=1; }
[ -f "$LAB/.claude/agents/rollmod.md" ] || { ko "T15 round-trip : agents/rollmod.md absent après rollback"; miss=1; }
[ -d "$LAB/.claude/agents/rollmod-references" ] || { ko "T15 round-trip : agents/rollmod-references/ absent après rollback"; miss=1; }
"$GREP" -q "MARKER-V1" "$LAB/.claude/agents/rollmod.md" 2>/dev/null \
  || { ko "T15 round-trip : contenu restauré n'est pas le contenu v1 (marqueur v1 absent)"; miss=1; }
"$GREP" -q "MARKER-V2" "$LAB/.claude/agents/rollmod.md" 2>/dev/null \
  && { ko "T15 round-trip : contenu v2 encore présent après rollback (pas restauré)"; miss=1; }
POST_REGISTRY=$("$GREP" '^rollmod=' "$LAB/.claude/scripts/.vibeflow-installed" 2>/dev/null | cut -d= -f2)
[ "$POST_REGISTRY" = "$V1_REGISTRY" ] \
  || { ko "T15 round-trip : registre après rollback = '$POST_REGISTRY' (attendu '$V1_REGISTRY', la version v1 capturée au backup)"; miss=1; }
[ "$POST_REGISTRY" != "$V2_REGISTRY" ] \
  || { ko "T15 round-trip : registre encore à v2 ($V2_REGISTRY) après rollback — le registre ment"; miss=1; }
[ "$miss" -eq 0 ] \
  && ok "T15 (ROLL-01..04 round-trip) : install v1 -> install v2 -> rollback -> contenu ET registre restaurés à v1 (v1=$V1_REGISTRY, v2=$V2_REGISTRY)"

# T17 : rollback d'un module jamais backuppé (aucun répertoire pour lui) échoue bruyamment.
rc=0
(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" rollback never-backed-up >/dev/null 2>&1) || rc=$?
if [ "$rc" -ne 0 ]; then
  ok "T17 (ROLL-04, régression) : rollback sans AUCUN backup échoue bruyamment (rc=$rc) après le filtrage du glob"
else
  ko "T17 (ROLL-04, régression) : rollback sans backup a exit 0 — devrait échouer"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T16 (ROLL-04, DISCRIMINANT) — backup UNIQUEMENT `-removed` (répertoire de convergence écrit par
# vf_converge_apply, vide de tout sous-dossier skills/agents/scripts/hooks) : rollback échoue
# BRUYAMMENT, jamais `✓ … rollback OK` — c'est le mode d'échec dominant mesuré au cadrage
# (38-CONTEXT.md 216-234 : un `ls -1dt` non filtré triait ce répertoire en tête, `[ -d skills ]`
# y était faux, le `rm -rf` n'était jamais atteint, et la fonction annonçait quand même le succès).
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
mkdir -p "$LAB/.claude/.backups/onlyremoved-20260101-000000-removed"
OUT=$(cd "$LAB" && VF_SCOPE=project bash "$INSTALLER" rollback onlyremoved 2>&1)
rc=$?
miss=0
[ "$rc" -ne 0 ] || { ko "T16 (DISCRIMINANT) : rollback sur backup -removed-only a exit 0 (attendu échec)"; miss=1; }
if echo "$OUT" | "$GREP" -q '✓ onlyremoved rollback OK'; then
  ko "T16 (DISCRIMINANT) : '✓ onlyremoved rollback OK' présent malgré zéro action réelle — le défaut mesuré au cadrage"
  miss=1
fi
[ "$miss" -eq 0 ] \
  && ok "T16 (ROLL-04, DISCRIMINANT) : backup -removed-only -> rollback échoue bruyamment (rc=$rc), jamais '✓ rollback OK'"
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T18 (D-38-J, REMPLACE l'ancien T18/ROLL-02) — reproduit le cas de PROD, pas le cas qui n'arrive
# jamais : $CACHE_DIR n'est JAMAIS rafraîchi par ce script, c'est l'appelant (/vibeflow-install)
# qui le pré-remplit AVANT install_module — donc AVANT backup_module. Au moment où backup_module
# tourne pour le 2e install, le cache porte DÉJÀ le fragment NEW (v2), jamais plus le fragment OLD
# (v1) réellement mergé dans settings.json. L'ancien T18 avançait le cache APRÈS le 2e install
# (via un merge-hooks.sh CLI direct) — un scénario qui ne reproduit PAS l'ordre réel des
# événements en prod, et qui restait vert même sur le code AVANT ce correctif (le bug D-38-J
# n'était pas discriminé). Preuve que ce nouveau T18 est bien discriminant : `git stash` du
# correctif backup_module (lecture $TARGET_ROOT/.vibeflow-fragments/<mod>.json au lieu de
# $CACHE_DIR/<mod>/hooks/hooks.json) fait échouer cette assertion — le fragment OLD backuppé
# devient NEW (le cache déjà avancé), donc le rollback restaure NEW → assertions ci-dessous rouges.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
mkdir -p "$CACHE/hookflip/scripts" "$CACHE/hookflip/hooks"
echo v1.0.0 > "$CACHE/hookflip/VERSION"
printf '{"name":"hookflip","version":"v1.0.0"}\n' > "$CACHE/hookflip/module.json"
printf '#!/usr/bin/env bash\necho old\n' > "$CACHE/hookflip/scripts/hookflip-old.sh"
printf '{"hooks":{"SessionStart":[{"matcher":"startup","hooks":[{"type":"command","command":"bash {{VF_SCRIPTS}}/hookflip-old.sh || true"}]}]}}\n' > "$CACHE/hookflip/hooks/hooks.json"

(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install hookflip >/dev/null 2>&1)
"$GREP" -q "hookflip-old.sh" "$LAB/.claude/settings.json" 2>/dev/null \
  || ko "T18 pré-condition : fragment OLD non mergé après le 1er install (garde-fou du test)"
[ -f "$LAB/.claude/.vibeflow-fragments/hookflip.json" ] \
  || ko "T18 pré-condition : .vibeflow-fragments/hookflip.json non persisté après le 1er install (garde-fou du test)"

# LE CAS DE PROD (D-38-J) : le cache "avance" en v2 AVANT le 2e install, exactement comme
# /vibeflow-install le pré-remplit avant d'invoquer install_module. Au moment où install_module
# (donc backup_module) tourne pour v2, $CACHE_DIR/hookflip/hooks/hooks.json est DÉJÀ le fragment
# NEW — jamais OLD.
echo v2.0.0 > "$CACHE/hookflip/VERSION"
printf '{"name":"hookflip","version":"v2.0.0"}\n' > "$CACHE/hookflip/module.json"
printf '#!/usr/bin/env bash\necho new\n' > "$CACHE/hookflip/scripts/hookflip-new.sh"
printf '{"hooks":{"SessionStart":[{"matcher":"startup","hooks":[{"type":"command","command":"bash {{VF_SCRIPTS}}/hookflip-new.sh || true"}]}]}}\n' > "$CACHE/hookflip/hooks/hooks.json"
(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install hookflip >/dev/null 2>&1)
"$GREP" -q "hookflip-new.sh" "$LAB/.claude/settings.json" 2>/dev/null \
  || ko "T18 pré-condition : fragment NEW non mergé après le 2e install (garde-fou du test)"
BDIR=$(ls -1dt "$LAB/.claude/.backups/hookflip"-* 2>/dev/null | "$GREP" -v -- '-removed$' | head -1)
[ -n "$BDIR" ] && "$GREP" -q "hookflip-old.sh" "$BDIR/hooks/hooks.json" 2>/dev/null \
  || ko "T18 pré-condition : backup n'a PAS capturé OLD (backup=$BDIR) — reproduit le bug si KO ici AVANT le fix"

(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" rollback hookflip >/dev/null 2>&1)
miss=0
"$GREP" -q "hookflip-old.sh" "$LAB/.claude/settings.json" 2>/dev/null \
  || { ko "T18 (D-38-J) : fragment OLD absent de settings.json après rollback — le rollback des hooks était un no-op (cache déjà en v2 au moment du backup)"; miss=1; }
"$GREP" -q "hookflip-new.sh" "$LAB/.claude/settings.json" 2>/dev/null \
  && { ko "T18 (D-38-J) : fragment NEW encore présent après rollback"; miss=1; }
[ "$miss" -eq 0 ] \
  && ok "T18 (D-38-J) : rollback restaure le fragment hooks PERSISTÉ PAR MODULE (.vibeflow-fragments/<mod>.json), pas le fragment courant du cache déjà avancé (cas de prod, pas le cas qui n'arrive jamais)"
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T18b (D-38-J, condition 4 — rétro-compatibilité) — un lab installé AVANT cette persistance
# par-module n'a AUCUN .vibeflow-fragments/<mod>.json. backup_module doit le DIRE explicitement
# (jamais un silence) quand le module utilise pourtant des hooks (fragment présent dans le cache
# courant) : c'est le gate de fidélité appliqué à notre propre rollback — ne pas restaurer est
# acceptable, ne pas le dire ne l'est pas.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
mkdir -p "$CACHE/hookretro/hooks" "$LAB/.claude/scripts"
echo v1.0.0 > "$CACHE/hookretro/VERSION"
printf '{"name":"hookretro","version":"v1.0.0"}\n' > "$CACHE/hookretro/module.json"
printf '{"hooks":{"SessionStart":[{"matcher":"startup","hooks":[{"type":"command","command":"true"}]}]}}\n' > "$CACHE/hookretro/hooks/hooks.json"
# Simule un lab "pré-persistance" : entrée de registre posée à la main, PAS de
# .vibeflow-fragments/ (ce fichier n'existait pas avant ce lot) — un vrai lab pré-existant.
printf 'hookretro=v1.0.0\n' > "$LAB/.claude/scripts/.vibeflow-installed"
echo v2.0.0 > "$CACHE/hookretro/VERSION"
printf '{"name":"hookretro","version":"v2.0.0"}\n' > "$CACHE/hookretro/module.json"
OUT=$(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install hookretro 2>&1)
miss=0
echo "$OUT" | "$GREP" -qi "installé avant" \
  || { ko "T18b (D-38-J, rétro-compat) : aucun message explicite sur le fragment hooks non restaurable (sortie : $OUT)"; miss=1; }
BDIR=$(ls -1dt "$LAB/.claude/.backups/hookretro"-* 2>/dev/null | "$GREP" -v -- '-removed$' | head -1)
if [ -n "$BDIR" ] && [ -f "$BDIR/hooks/hooks.json" ]; then
  ko "T18b (D-38-J, rétro-compat) : hooks.json présent dans le backup alors qu'aucun fragment persisté n'existait (contenu fabriqué)"
  miss=1
fi
[ "$miss" -eq 0 ] \
  && ok "T18b (D-38-J, rétro-compat) : absence de fragment persisté DÉCLARÉE explicitement, jamais tue"
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T19 (ROLL-02, statique) — merge_module_hooks/remove_module_hooks portent bien le 2e paramètre
# optionnel fragment_override (acceptance criteria 38-03 tâche 2, non-régression des ~6 appelants
# existants : le défaut ${2:-…} retombe exactement sur le comportement d'avant ce lot).
# ---------------------------------------------------------------------------
N=$("$GREP" -c '\${2:-\$CACHE_DIR/\$mod/hooks/hooks\.json}' "$INSTALLER" 2>/dev/null || true)
if [ "${N:-0}" -ge 2 ]; then
  ok "T19 (ROLL-02, statique) : fragment_override présent sur les 2 fonctions ($N occurrence(s))"
else
  ko "T19 (ROLL-02, statique) : fragment_override attendu >=2 fois (merge+remove), trouvé ${N:-0}"
fi

# ---------------------------------------------------------------------------
# T20 (ROLL-05) — --dry-run rollback n'écrit RIEN sur disque (preuve find -newer), prévisualise ce
# qui serait restauré. Cas négatif implicite via T4/garde --dry-run déjà couvert par le nouveau
# message d'erreur (install/update/rollback) — la case *) reste inchangée pour uninstall/status/sync.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
mkdir -p "$CACHE/dryrollmod"
echo v1.0.0 > "$CACHE/dryrollmod/VERSION"
printf '{"name":"dryrollmod","version":"v1.0.0"}\n' > "$CACHE/dryrollmod/module.json"
printf '# skill v1\n' > "$CACHE/dryrollmod/SKILL.md"
(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install dryrollmod >/dev/null 2>&1)
echo v2.0.0 > "$CACHE/dryrollmod/VERSION"
printf '{"name":"dryrollmod","version":"v2.0.0"}\n' > "$CACHE/dryrollmod/module.json"
printf '# skill v2\n' > "$CACHE/dryrollmod/SKILL.md"
(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install dryrollmod >/dev/null 2>&1)

TS_MARK="$LAB/.ts-mark"; touch "$TS_MARK"; sleep 1
OUT=$(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" --dry-run rollback dryrollmod 2>&1)
rc=$?
miss=0
[ "$rc" -eq 0 ] || { ko "T20 (ROLL-05) : --dry-run rollback exit $rc (attendu 0)"; miss=1; }
echo "$OUT" | "$GREP" -q '\[dry-run\]' || { ko "T20 (ROLL-05) : aucune ligne [dry-run] dans la sortie"; miss=1; }
NEWER=$(find "$LAB/.claude" -newer "$TS_MARK" -type f 2>/dev/null || true)
[ -z "$NEWER" ] \
  || { ko "T20 (ROLL-05) : --dry-run rollback a écrit sur disque : $NEWER"; miss=1; }
[ "$miss" -eq 0 ] \
  && ok "T20 (ROLL-05) : --dry-run rollback n'écrit rien (preuve find -newer), prévisualise la restauration"
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T21 (38-CORR, DISCRIMINANT) — le glob de sélection de backup doit être ANCRÉ sur le nom EXACT
# du module, pas seulement préfixé. Cas réel de ce dépôt : `plugin/mobile-test/` ET
# `plugin/mobile-test-team/` coexistent. Deux backups posés CÔTE À CÔTE, celui du mauvais module
# ("mobile-test-team-...") PLUS RÉCENT (c'est la fraîcheur qui déclenche le bug : `ls -1dt` trie
# par mtime) — avant le fix, `rollback mobile-test` sélectionnait ce backup voisin et restaurait
# son contenu/sa version sous le nom "mobile-test", silencieusement.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
BACKUP="$LAB/.claude/.backups"
mkdir -p "$LAB/.claude/skills"
mkdir -p "$BACKUP/mobile-test-20260101-000000/skills"
echo "MARKER-MOBILETEST" > "$BACKUP/mobile-test-20260101-000000/skills/marker.md"
printf 'v-mobile-test\n' > "$BACKUP/mobile-test-20260101-000000/.version"
sleep 1
mkdir -p "$BACKUP/mobile-test-team-20260228-999999/skills"
echo "MARKER-MOBILETESTTEAM" > "$BACKUP/mobile-test-team-20260228-999999/skills/marker.md"
printf 'v-mobile-test-team\n' > "$BACKUP/mobile-test-team-20260228-999999/.version"

OUT=$(cd "$LAB" && VF_SCOPE=project bash "$INSTALLER" rollback mobile-test 2>&1)
miss=0
echo "$OUT" | "$GREP" -q 'depuis .*/mobile-test-team-' \
  && { ko "T21 (38-CORR, DISCRIMINANT) : rollback mobile-test a sélectionné le backup du voisin mobile-test-team-*"; miss=1; }
if [ -f "$LAB/.claude/skills/mobile-test/marker.md" ]; then
  "$GREP" -q 'MARKER-MOBILETEST$' "$LAB/.claude/skills/mobile-test/marker.md" \
    || { ko "T21 (38-CORR, DISCRIMINANT) : marker restauré n'est pas MARKER-MOBILETEST (obtenu : $(cat "$LAB/.claude/skills/mobile-test/marker.md" 2>/dev/null))"; miss=1; }
else
  ko "T21 (38-CORR, DISCRIMINANT) : skills/mobile-test/marker.md absent après rollback"
  miss=1
fi
REG=$("$GREP" '^mobile-test=' "$LAB/.claude/scripts/.vibeflow-installed" 2>/dev/null | cut -d= -f2)
[ "$REG" = "v-mobile-test" ] \
  || { ko "T21 (38-CORR, DISCRIMINANT) : registre mobile-test='$REG' (attendu 'v-mobile-test', jamais 'v-mobile-test-team')"; miss=1; }
[ "$miss" -eq 0 ] \
  && ok "T21 (38-CORR, DISCRIMINANT) : rollback mobile-test sélectionne SON backup, jamais celui plus récent de mobile-test-team-*"
rm -rf "$LAB"

# T16 (ROLL-04) doit rester vert après ce resserrement du glob : un backup -removed-only
# commence bien par un chiffre après le tiret ('...-removed' suit l'horodatage), donc il matche
# toujours `[0-9]*` puis reste filtré par `grep -v -- '-removed$'` — non-régression déjà couverte
# plus haut dans ce fichier (bloc T16), reconfirmée ici en commentaire pour la revue.

# ---------------------------------------------------------------------------
# T22 (D-38-K, condition B OBLIGATOIRE, DISCRIMINANT) — un `cp` qui échoue RÉELLEMENT à mi-
# restauration (permission retirée sur le fichier SOURCE du backup, jamais un `cp` simulé) doit
# faire déclarer le registre INCONSISTENT:<étape>:<version_cible>, sortir en échec, et NE JAMAIS
# laisser le registre porter la version PRÉ-rollback. `show_status` doit afficher cet état.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
mkdir -p "$CACHE/trapmod/skills/trapmod"
echo v1.0.0 > "$CACHE/trapmod/VERSION"
printf '{"name":"trapmod","version":"v1.0.0"}\n' > "$CACHE/trapmod/module.json"
printf '# trapmod v1\n' > "$CACHE/trapmod/skills/trapmod/SKILL.md"
(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install trapmod >/dev/null 2>&1)
echo v2.0.0 > "$CACHE/trapmod/VERSION"
printf '{"name":"trapmod","version":"v2.0.0"}\n' > "$CACHE/trapmod/module.json"
printf '# trapmod v2\n' > "$CACHE/trapmod/skills/trapmod/SKILL.md"
(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install trapmod >/dev/null 2>&1)
BDIR=$(ls -1dt "$LAB/.claude/.backups/trapmod"-* 2>/dev/null | "$GREP" -v -- '-removed$' | head -1)
miss=0
if [ -z "$BDIR" ] || [ ! -f "$BDIR/skills/SKILL.md" ]; then
  ko "T22 pré-condition : backup de trapmod introuvable ou incomplet (garde-fou du test)"
  miss=1
else
  # Échec RÉEL, jamais simulé : la SOURCE que rollback_module va `cp -r` perd son droit de
  # lecture — `cp` échoue avec "Permission denied", exactement le mode de panne du digest.
  chmod 000 "$BDIR/skills/SKILL.md"
  OUT=$(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" rollback trapmod 2>&1)
  rc=$?
  chmod 644 "$BDIR/skills/SKILL.md" 2>/dev/null || true
  [ "$rc" -ne 0 ] || { ko "T22 (D-38-K) : rollback avec cp en échec réel a exit 0 (attendu non-zéro)"; miss=1; }
  REG=$("$GREP" '^trapmod=' "$LAB/.claude/scripts/.vibeflow-installed" 2>/dev/null | cut -d= -f2)
  case "$REG" in
    INCONSISTENT:*) : ;;
    v2.0.0)
      ko "T22 (D-38-K) : registre trapmod='$REG' — encore la version PRÉ-rollback, le mensonge que ce lot ferme"
      miss=1
      ;;
    *)
      ko "T22 (D-38-K) : registre trapmod='$REG' (attendu un préfixe INCONSISTENT:)"
      miss=1
      ;;
  esac
  echo "$OUT" | "$GREP" -qi "INCOHÉRENT\|inconsistent" \
    || { ko "T22 (D-38-K) : aucun message explicite sur l'état incohérent dans la sortie du rollback"; miss=1; }
  STATUS_OUT=$(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" status 2>&1)
  echo "$STATUS_OUT" | "$GREP" -qi "trapmod.*INCONSISTENT" \
    || { ko "T22 (D-38-K) : 'status' n'affiche pas l'état INCONSISTENT pour trapmod (sortie : $STATUS_OUT)"; miss=1; }
fi
[ "$miss" -eq 0 ] \
  && ok "T22 (D-38-K, DISCRIMINANT) : cp en échec réel mi-restauration -> registre INCONSISTENT:<étape>:<cible>, rc≠0, 'status' l'affiche"
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T23 (D-38-K, piège bash 3.2) — DISCRIMINANT de la garde `set -E` elle-même : sans `set -E`, le
# `trap ERR` posé dans rollback_module ne se propagerait PAS dans la fonction sous bash 3.2 (le
# /bin/bash de macOS, plancher réel du repo) — la restauration échouerait bien (rc≠0, cohérent
# avec T22) mais SANS jamais écrire l'état INCONSISTENT au registre : le vert silencieux que
# cette phase existe pour tuer. Assertion statique bornée au VOISINAGE immédiat du `trap ERR` de
# rollback_module (jamais un `grep -c` global sur tout le fichier, qui compterait aussi la prose
# de ce commentaire) : `set -E` doit apparaître AVANT `trap .* ERR` dans les 10 lignes qui le
# précèdent.
# ---------------------------------------------------------------------------
TRAP_LINE=$("$GREP" -n "trap '_vf_rollback_mark_inconsistent" "$INSTALLER" | head -1 | cut -d: -f1)
if [ -z "$TRAP_LINE" ]; then
  ko "T23 (D-38-K) : trap ERR de rollback_module introuvable dans $INSTALLER"
else
  START=$((TRAP_LINE - 10))
  [ "$START" -lt 1 ] && START=1
  WINDOW=$(sed -n "${START},${TRAP_LINE}p" "$INSTALLER")
  if echo "$WINDOW" | "$GREP" -q '^\s*set -E\s*$'; then
    ok "T23 (D-38-K) : 'set -E' précède le 'trap ... ERR' de rollback_module (propagation en fonction, bash 3.2)"
  else
    ko "T23 (D-38-K) : aucun 'set -E' dans les 10 lignes précédant le trap ERR de rollback_module — le trap serait un vert silencieux sous bash 3.2"
  fi
fi

# ---------------------------------------------------------------------------
# Garde REAL_GSD_HOME (T24/T25/T26, FIDE-02, hermétisme) — T24/T26 exercent
# check-artifact-fidelity.sh via un install/update réel. Ce gate résout gsd-core par
# default_gsd_home() : `git rev-parse --show-toplevel` depuis $LAB (un mktemp -d, jamais un
# repo git) échoue puis retombe sur `pwd` ($LAB lui-même) — donc "$root/.claude/gsd-core"
# n'existe jamais ici, et la cascade retombe TOUJOURS sur `${CLAUDE_CONFIG_DIR:-$HOME/.claude}
# /gsd-core`. Contrairement à T1-T3 (plus haut dans ce fichier), T24/T26 ne posaient PAS
# HOME="$FAKE_HOME" : le $HOME de l'appelant du test — le VRAI $HOME/.claude/gsd-core de la
# machine — s'y glissait donc en silence. Ça passe ici et en CI (gsd-core y est posé), mais sur
# un poste neuf sans gsd-core, T24/T26 rendraient un faux KO sans rapport avec une régression.
# Repris du garde REAL_GSD_HOME de test-check-artifact-fidelity.sh (l. 37-44, même module) :
# skip propre si gsd-core est introuvable, jamais un rouge de circonstance.
# ---------------------------------------------------------------------------
ACTUAL_REPO_ROOT="$(cd "$REPO/.." && pwd)"
REAL_GSD_HOME=""
if [ -d "$ACTUAL_REPO_ROOT/.claude/gsd-core" ]; then
  REAL_GSD_HOME="$ACTUAL_REPO_ROOT/.claude/gsd-core"
elif [ -f "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core/VERSION" ]; then
  REAL_GSD_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core"
fi

# Prépare un HOME isolé sous $LAB avec gsd-core symlinké depuis REAL_GSD_HOME — jamais le vrai
# $HOME de la machine. L'install lui-même reste project-scope (VF_SCOPE par défaut), donc rien
# n'atterrit sous ce HOME isolé hormis la résolution de la cascade default_gsd_home().
fide_isolated_home() {
  local lab="$1" home
  home="$lab/home_fide"
  mkdir -p "$home/.claude"
  ln -s "$REAL_GSD_HOME" "$home/.claude/gsd-core"
  echo "$home"
}

# ---------------------------------------------------------------------------
# T24 (FIDE-02) — install d'un module à agents/*.md avec conductor présent dans le cache : la
# ligne `[fidelity]` doit apparaître VERBATIM sur le stdout de l'install (relayée telle quelle,
# jamais résumée) — c'est toute la substance de FIDE-02 : le périmètre perdu à la conversion
# est déclaré à la fin de la pose, pas dans un rapport séparé.
# ---------------------------------------------------------------------------
if [ -z "$REAL_GSD_HOME" ]; then
  skip "T24 (FIDE-02) : gsd-core introuvable sur ce poste (hermétique — jamais un faux KO)"
else
  LAB="$(mktemp -d)"
  CACHE="$LAB/cache"
  HOME_FIDE="$(fide_isolated_home "$LAB")"
  if prepare_module "$CACHE" "content-bundle" && prepare_module "$CACHE" "conductor"; then
    OUT=$(cd "$LAB" && HOME="$HOME_FIDE" VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install content-bundle 2>&1)
    miss=0
    echo "$OUT" | "$GREP" -q '^\[fidelity\] ' \
      || { ko "T24 (FIDE-02) : aucune ligne [fidelity] sur stdout de l'install (conductor présent au cache)"; miss=1; }
    echo "$OUT" | "$GREP" -q '^\[fidelity-recette\] ' \
      || { ko "T24 (FIDE-02) : aucune ligne [fidelity-recette] sur stdout de l'install"; miss=1; }
    [ "$miss" -eq 0 ] && ok "T24 (FIDE-02) : bannière de fidélité verbatim sur stdout de l'install (content-bundle -> codex)"
  else
    skip "T24 (FIDE-02) : content-bundle/conductor non copiables dans le cache de test"
  fi
  rm -rf "$LAB"
fi

# ---------------------------------------------------------------------------
# T25 (FIDE-02, best-effort) — conductor ABSENT du cache (gate introuvable aux 2 positions de
# find_fidelity_gate) : l'install continue SANS échouer, silence total (jamais de ligne
# [fidelity], jamais d'erreur qui dégraderait le reste du diagnostic d'install).
# ---------------------------------------------------------------------------
if [ -z "$REAL_GSD_HOME" ]; then
  skip "T25 (FIDE-02, best-effort) : gsd-core introuvable sur ce poste (hermétique — jamais un faux KO)"
else
  LAB="$(mktemp -d)"
  CACHE="$LAB/cache"
  HOME_FIDE="$(fide_isolated_home "$LAB")"
  if prepare_module "$CACHE" "content-bundle"; then
    OUT=$(cd "$LAB" && HOME="$HOME_FIDE" VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install content-bundle 2>&1)
    RC=$?
    miss=0
    [ "$RC" -eq 0 ] || { ko "T25 (FIDE-02, best-effort) : install a échoué (rc=$RC) alors que le gate est simplement absent"; miss=1; }
    echo "$OUT" | "$GREP" -q '^\[fidelity\] ' \
      && { ko "T25 (FIDE-02, best-effort) : ligne [fidelity] présente alors que conductor n'est PAS dans le cache (gate introuvable aux 2 positions)"; miss=1; }
    [ "$miss" -eq 0 ] && ok "T25 (FIDE-02, best-effort) : gate absent -> install continue (rc=0), silence total, aucune ligne [fidelity]"
  else
    skip "T25 (FIDE-02, best-effort) : content-bundle non copiable dans le cache de test"
  fi
  rm -rf "$LAB"
fi

# ---------------------------------------------------------------------------
# T26 (FIDE-02) — update réel (version bump) : la 2e couture (update_module, après
# vf_converge_apply) produit AUSSI la ligne [fidelity] — pas seulement install_module au premier
# install. Reproduit le couple v1 -> v2 déjà utilisé par T15 (ROLL) pour un module réel à agent.
# ---------------------------------------------------------------------------
if [ -z "$REAL_GSD_HOME" ]; then
  skip "T26 (FIDE-02) : gsd-core introuvable sur ce poste (hermétique — jamais un faux KO)"
else
  LAB="$(mktemp -d)"
  CACHE="$LAB/cache"
  HOME_FIDE="$(fide_isolated_home "$LAB")"
  if prepare_module "$CACHE" "content-bundle" && prepare_module "$CACHE" "conductor"; then
    (cd "$LAB" && HOME="$HOME_FIDE" VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" install content-bundle >/dev/null 2>&1)
    # Bump artificiel de version dans le cache pour forcer le chemin update (pas resync).
    echo "v9.9.9" > "$CACHE/content-bundle/VERSION"
    OUT=$(cd "$LAB" && HOME="$HOME_FIDE" VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" update content-bundle 2>&1)
    miss=0
    N_FID=$(echo "$OUT" | "$GREP" -c '^\[fidelity\] ' || true)
    [ "${N_FID:-0}" -ge 1 ] \
      || { ko "T26 (FIDE-02) : aucune ligne [fidelity] sur stdout de l'update (2e couture non exercée)"; miss=1; }
    [ "$miss" -eq 0 ] && ok "T26 (FIDE-02) : bannière de fidélité présente aussi sur un update réel (2e couture, après vf_converge_apply)"
  else
    skip "T26 (FIDE-02) : content-bundle/conductor non copiables dans le cache de test"
  fi
  rm -rf "$LAB"
fi

# ---------------------------------------------------------------------------
# Helper T27 — reproduit EXACTEMENT ce que fait un appelant RÉEL posé (find_runtime_cli_dispatch,
# identique dans ensure-deps.sh / ensure-design-deps.sh / check-plugin-update.sh) : extrait la
# fonction depuis le fichier RÉELLEMENT POSÉ sur disque (pas le source du repo — l'artefact déployé
# byte-identique), l'exécute avec $0 = ce même chemin posé (donc `dirname "$0")` = son répertoire
# réel), VIBEFLOW_CACHE tel que fourni par l'environnement appelant. `bash -c '...' "$posed"` : le
# 1er argument après le script devient $0 À L'INTÉRIEUR du script — c'est ce qui nous permet de
# forcer $0 sans jamais exécuter le corps (network/npm/side-effects) du caller réel.
# ---------------------------------------------------------------------------
resolve_via_posed_caller() {
  local posed="$1"
  bash -c '
    eval "$(sed -n "/^find_runtime_cli_dispatch()/,/^}/p" "$0")"
    cd "$(dirname "$0")" 2>/dev/null || exit 1
    find_runtime_cli_dispatch
  ' "$posed"
}

# ---------------------------------------------------------------------------
# T27 (DISCRIMINANT, correction ciblée jointure 38) — la table de dispatch runtime-aware doit
# résoudre en RÉGIME ÉTABLI, pas seulement à l'install initiale. Avant le fix : runtime-cli-
# dispatch.sh n'était copié NULLE PART sous $TARGET_ROOT/scripts/ (aucun `copy_runtime_dispatch`,
# aucun appel) — le candidat 1 de find_runtime_cli_dispatch() (VIBEFLOW_CACHE, non défini hors
# install) et le candidat 2 ($(dirname "$0")/…, fichier absent de ce répertoire) rendaient TOUS
# LES DEUX vides sur toute ré-invocation depuis $TARGET_ROOT/scripts/ (`/vf-update` étape 4c,
# `/vf-calibrate`, hook SessionStart). Reproduit ici via une INSTALLATION RÉELLE de conductor
# (qui embarque check-plugin-update.sh, l'un des 3 appelants réels), puis une RÉ-INVOCATION du
# fichier réellement posé, VIBEFLOW_CACHE **non défini** (le cas normal en régime établi) —
# jamais depuis la position source du cache.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
if prepare_module "$CACHE" "conductor"; then
  mkdir -p "$CACHE/_internal"
  cp "$INTERNAL_DIR/runtime-cli-dispatch.sh" "$CACHE/_internal/runtime-cli-dispatch.sh"
  (cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" install conductor >/dev/null 2>&1)
  POSED_DISPATCH="$LAB/.claude/scripts/runtime-cli-dispatch.sh"
  POSED_CALLER="$LAB/.claude/scripts/check-plugin-update.sh"
  miss=0
  [ -f "$POSED_DISPATCH" ] \
    || { ko "T27 pré-condition : runtime-cli-dispatch.sh non posé sous \$TARGET_ROOT/scripts/ après install (copy_runtime_dispatch absent/en échec)"; miss=1; }
  [ -f "$POSED_CALLER" ] \
    || { ko "T27 pré-condition : check-plugin-update.sh non posé sous \$TARGET_ROOT/scripts/ (garde-fou du test lui-même)"; miss=1; }
  if [ "$miss" -eq 0 ]; then
    # RÉ-INVOCATION depuis la position posée, VIBEFLOW_CACHE explicitement NON défini (unset, pas
    # vide) — le régime normal d'un hook SessionStart/`/vf-update` étape 4c/`/vf-calibrate`, PAS
    # le régime de l'install initiale où VIBEFLOW_CACHE pointe encore vers le cache. Sous-shell +
    # `unset` : la fonction resolve_via_posed_caller est déjà visible dans CE script (pas de
    # ré-imbrication de bash -c échappée), seule la variable d'environnement change de portée.
    RESOLVED=$(unset VIBEFLOW_CACHE; resolve_via_posed_caller "$POSED_CALLER")
    if [ "$RESOLVED" = "$POSED_DISPATCH" ]; then
      ok "T27 (DISCRIMINANT) : ré-invocation depuis \$TARGET_ROOT/scripts/ (VIBEFLOW_CACHE non défini) résout runtime-cli-dispatch.sh → $RESOLVED"
    else
      ko "T27 (DISCRIMINANT) : résolution en régime établi ÉCHOUÉE — attendu '$POSED_DISPATCH', obtenu '${RESOLVED:-<vide>}' (les deux candidats de la cascade rendent MISSING sans copy_runtime_dispatch)"
    fi
  fi
else
  skip "T27 : conductor non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T28 (TGT-01) — `--target <chemin>` pose réellement HORS de $HOME/.claude et ./.claude.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
CUSTOM_TARGET="$LAB/customtarget"
if prepare_module "$CACHE" "dev-orchestrator"; then
  (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" --target "$CUSTOM_TARGET" install dev-orchestrator >/dev/null 2>&1)
  miss=0
  [ -f "$CUSTOM_TARGET/agents/dev-orchestrator.md" ] \
    || { ko "T28 : \$CUSTOM_TARGET/agents/dev-orchestrator.md manquant sous --target"; miss=1; }
  [ ! -d "$LAB/.claude" ] \
    || { ko "T28 : ./.claude a été créé alors que --target était fourni (pas de repli implicite)"; miss=1; }
  [ "$miss" -eq 0 ] && ok "T28 (TGT-01) : --target <chemin> pose réellement hors de \$HOME/.claude et ./.claude"
else
  skip "T28 : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T29 (TGT-03, DISCRIMINANT) — le payload copié sous --target ne fige plus AUCUNE occurrence
# littérale '.claude/' : le fichier réel posé pointe vers la cible réellement choisie.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
CUSTOM_TARGET="$LAB/customtarget"
if prepare_module "$CACHE" "dev-orchestrator"; then
  (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" --target "$CUSTOM_TARGET" install dev-orchestrator >/dev/null 2>&1)
  POSED="$CUSTOM_TARGET/agents/dev-orchestrator.md"
  if [ -f "$POSED" ]; then
    residual=$("$GREP" -c '\.claude/' "$POSED" 2>/dev/null || true)
    residual="${residual:-0}"
    rewritten=$("$GREP" -c "$CUSTOM_TARGET" "$POSED" 2>/dev/null || true)
    rewritten="${rewritten:-0}"
    if [ "$residual" -eq 0 ] && [ "$rewritten" -gt 0 ]; then
      ok "T29 (TGT-03, DISCRIMINANT) : 0 occurrence '.claude/' résiduelle sur le fichier réellement posé, $rewritten occurrence(s) réécrite(s) vers \$CUSTOM_TARGET"
    else
      ko "T29 (TGT-03, DISCRIMINANT) : réécriture incomplète — résiduel='.claude/'=$residual (attendu 0), réécrit vers cible=$rewritten (attendu >0)"
    fi
    # Balayage global : AUCUN fichier posé sous la cible ne doit garder '.claude/' en dur (198
    # fichiers / 1130 occurrences mesurées au cadrage, périmètre hors _internal/).
    total_residual=$(find "$CUSTOM_TARGET" -type f -print0 2>/dev/null | xargs -0 "$GREP" -o '\.claude/' 2>/dev/null | wc -l | tr -d ' ')
    if [ "$total_residual" -eq 0 ]; then
      ok "T29b : balayage global sous \$CUSTOM_TARGET — 0 occurrence '.claude/' résiduelle (comptage sur le lab installé, pas lecture de code)"
    else
      ko "T29b : balayage global sous \$CUSTOM_TARGET — $total_residual occurrence(s) '.claude/' résiduelle(s) (attendu 0)"
    fi
  else
    ko "T29 pré-condition : $POSED manquant après install --target"
  fi
else
  skip "T29 : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T30 (TGT-01, non-régression) — sans --target, le comportement par défaut (scope user/project)
# reste inchangé : les mêmes assertions structurelles que T1/T2 continuent de passer (déjà
# couvertes ci-dessus) ; ce test vérifie en plus qu'AUCUNE réécriture n'a lieu sans --target — le
# coût de vf_rewrite_target_refs doit être nul par construction (VF_TARGET_OVERRIDE vide).
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
if prepare_module "$CACHE" "dev-orchestrator"; then
  (cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" install dev-orchestrator >/dev/null 2>&1)
  POSED="$LAB/.claude/agents/dev-orchestrator.md"
  if [ -f "$POSED" ]; then
    ref_count=$("$GREP" -c '\.claude/agents/dev-orchestrator-references' "$POSED" 2>/dev/null || true)
    ref_count="${ref_count:-0}"
    if [ "$ref_count" -gt 0 ]; then
      ok "T30 : sans --target, les références '.claude/agents/...' du payload restent INCHANGÉES ($ref_count occurrence(s), comportement legacy byte-identique)"
    else
      ko "T30 : sans --target, les références '.claude/agents/...' ont disparu du payload posé — régression du comportement par défaut"
    fi
  else
    ko "T30 pré-condition : $POSED manquant après install sans --target"
  fi
else
  skip "T30 : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T31 (TGT-02) — gitignore_add_paths() sous --target + scope local : les 16 littéraux résiduels
# suivent la cible réellement résolue (relative au cwd), jamais le littéral '.claude/'.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
CUSTOM_TARGET="$LAB/mytgt"
if prepare_module "$CACHE" "dev-orchestrator"; then
  (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" --scope local --target "$CUSTOM_TARGET" install dev-orchestrator >/dev/null 2>&1)
  miss=0
  [ -f "$LAB/.gitignore" ] || { ko "T31 pré-condition : .gitignore absent après install --scope local --target"; miss=1; }
  if [ "$miss" -eq 0 ]; then
    if "$GREP" -qxF "mytgt/agents/dev-orchestrator.md" "$LAB/.gitignore" \
       && ! "$GREP" -qF ".claude/agents/dev-orchestrator.md" "$LAB/.gitignore"; then
      ok "T31 (TGT-02) : .gitignore sous --target contient le chemin relatif à la cible réelle (mytgt/...), jamais le littéral .claude/"
    else
      ko "T31 (TGT-02) : .gitignore sous --target ne suit pas la cible réelle — contenu : $(cat "$LAB/.gitignore" | tr '\n' ' ')"
    fi
  fi
else
  skip "T31 : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T32 (TGT-02, DISCRIMINANT) — --target hors de l'arbre du repo (scope local) : .gitignore n'est
# JAMAIS modifié avec une entrée invalide (hors-arbre), le manque est journalisé.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
OUTSIDE="$(mktemp -d)"
CACHE="$LAB/cache"
if prepare_module "$CACHE" "dev-orchestrator"; then
  OUT=$(cd "$LAB" && VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" --scope local --target "$OUTSIDE/tgt" install dev-orchestrator 2>&1)
  if [ ! -f "$LAB/.gitignore" ] && echo "$OUT" | "$GREP" -qi 'hors'; then
    ok "T32 (TGT-02, DISCRIMINANT) : --target hors-arbre en scope local -> .gitignore NON modifié, manque journalisé"
  else
    ko "T32 (TGT-02, DISCRIMINANT) : --target hors-arbre — .gitignore existe=$([ -f "$LAB/.gitignore" ] && echo oui || echo non), avertissement absent de la sortie"
  fi
else
  skip "T32 : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB" "$OUTSIDE"

# ---------------------------------------------------------------------------
# T33 (TGT-02, DISCRIMINANT) — scripts_prefix_for_scope() sous --target : preuve par la sortie
# RÉELLE de merge_module_hooks() (settings.json d'un module à hooks, dev-orchestrator), jamais
# une reconstitution synthétique. Le placeholder {{VF_SCRIPTS}} doit résoudre vers le chemin
# ABSOLU de la cible réelle, jamais vers "$HOME"/.claude ni "$CLAUDE_PROJECT_DIR"/.claude — ET la
# forme produite, une fois `eval`-ée par un shell réel, résout physiquement vers <target>/scripts.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
CUSTOM_TARGET="$LAB/prefixtgt"
if prepare_module "$CACHE" "dev-orchestrator"; then
  (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" --target "$CUSTOM_TARGET" install dev-orchestrator >/dev/null 2>&1)
  SETTINGS="$CUSTOM_TARGET/settings.json"
  if [ -f "$SETTINGS" ]; then
    RESOLVED_TARGET="$(cd -P "$CUSTOM_TARGET" && pwd -P)"
    has_legacy=$("$GREP" -c '"\$HOME"/\.claude\|"\$CLAUDE_PROJECT_DIR"/\.claude' "$SETTINGS" 2>/dev/null || true)
    has_legacy="${has_legacy:-0}"
    # Présence du chemin ABSOLU réel (JSON échappe le guillemet séparant <cible> de /scripts en
    # "\"", donc ne PAS exiger la jointure exacte "<cible>/scripts" — le segment de chemin suffit
    # à prouver que la cible réelle apparaît ; l'absence des formes legacy ci-dessus garantit
    # qu'il ne s'agit pas d'une coïncidence).
    has_target=$("$GREP" -cF "$RESOLVED_TARGET" "$SETTINGS" 2>/dev/null || true)
    has_target="${has_target:-0}"
    if [ "$has_legacy" -eq 0 ] && [ "$has_target" -gt 0 ]; then
      # eval réel de la forme shell EXACTE produite en tête d'une entrée "command" de settings.json.
      EVAL_RESULT=$(eval "printf '%s' \"$RESOLVED_TARGET\"/scripts")
      if [ "$EVAL_RESULT" = "$RESOLVED_TARGET/scripts" ]; then
        ok "T33 (TGT-02, DISCRIMINANT) : settings.json sous --target contient le chemin absolu réel de la cible (0 forme \$HOME/\$CLAUDE_PROJECT_DIR), eval réel confirme <target>/scripts"
      else
        ko "T33 (TGT-02, DISCRIMINANT) : eval de la forme produite ÉCHOUÉ — attendu '$RESOLVED_TARGET/scripts', obtenu '$EVAL_RESULT'"
      fi
    else
      ko "T33 (TGT-02, DISCRIMINANT) : settings.json sous --target — formes legacy résiduelles=$has_legacy (attendu 0), forme cible=$has_target (attendu >0)"
    fi
  else
    skip "T33 : settings.json non produit (module sans hooks.json dans ce cache, ou merge-hooks absent)"
  fi
else
  skip "T33 : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T34 (TGT-04) — le marqueur $TARGET_ROOT/scripts/.vibeflow-target est posé sous --target,
# contient le chemin ABSOLU réel de la cible — [ -f ] + grep réels, jamais supposé.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
CUSTOM_TARGET="$LAB/markertgt"
if prepare_module "$CACHE" "dev-orchestrator"; then
  (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" --target "$CUSTOM_TARGET" install dev-orchestrator >/dev/null 2>&1)
  MARKER="$CUSTOM_TARGET/scripts/.vibeflow-target"
  if [ -f "$MARKER" ]; then
    RESOLVED_TARGET="$(cd -P "$CUSTOM_TARGET" && pwd -P)"
    MARKER_CONTENT="$(cat "$MARKER")"
    if [ "$MARKER_CONTENT" = "$RESOLVED_TARGET" ]; then
      ok "T34 (TGT-04) : \$TARGET_ROOT/scripts/.vibeflow-target posé, contient le chemin absolu réel de la cible ($MARKER_CONTENT)"
    else
      ko "T34 (TGT-04) : contenu du marqueur ('$MARKER_CONTENT') ≠ cible résolue ('$RESOLVED_TARGET')"
    fi
  else
    ko "T34 (TGT-04) : \$TARGET_ROOT/scripts/.vibeflow-target absent après install --target"
  fi
else
  skip "T34 : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T35 (D-38-H, sonde cross-module) — check-gsd-engine.sh (dev-orchestrator, INDÉPENDANT de
# vibeflow-update.sh) rend le MÊME code de sortie + la MÊME sortie stdout, exécuté depuis un cwd
# après une install --target custom et depuis un cwd après une install par défaut — preuve par
# exécution comparée que la sonde cross-module <S-moteur> reste résolue après ce changement de
# layout, jamais supposée (garde-fou explicite hérité, safe modification déclarée).
# ---------------------------------------------------------------------------
GSD_ENGINE_SCRIPT="$REPO/dev-orchestrator/scripts/check-gsd-engine.sh"
if [ -f "$GSD_ENGINE_SCRIPT" ]; then
  LAB_DEFAULT="$(mktemp -d)"
  LAB_TARGET="$(mktemp -d)"
  CACHE_D="$LAB_DEFAULT/cache"
  CACHE_T="$LAB_TARGET/cache"
  if prepare_module "$CACHE_D" "dev-orchestrator" && prepare_module "$CACHE_T" "dev-orchestrator"; then
    (cd "$LAB_DEFAULT" && VIBEFLOW_CACHE="$CACHE_D" bash "$INSTALLER" install dev-orchestrator >/dev/null 2>&1)
    (cd "$LAB_TARGET" && VIBEFLOW_CACHE="$CACHE_T" bash "$INSTALLER" --target "$LAB_TARGET/custom" install dev-orchestrator >/dev/null 2>&1)
    OUT_DEFAULT=$(cd "$LAB_DEFAULT" && bash "$GSD_ENGINE_SCRIPT" --quiet 2>/dev/null); RC_DEFAULT=$?
    OUT_TARGET=$(cd "$LAB_TARGET" && bash "$GSD_ENGINE_SCRIPT" --quiet 2>/dev/null); RC_TARGET=$?
    if [ "$RC_DEFAULT" = "$RC_TARGET" ] && [ "$OUT_DEFAULT" = "$OUT_TARGET" ]; then
      ok "T35 (D-38-H) : check-gsd-engine.sh --quiet rend le MÊME rc ($RC_DEFAULT) et la MÊME sortie, install par défaut vs install --target"
    else
      ko "T35 (D-38-H) : check-gsd-engine.sh diverge — défaut(rc=$RC_DEFAULT,out='$OUT_DEFAULT') vs --target(rc=$RC_TARGET,out='$OUT_TARGET')"
    fi
  else
    skip "T35 : dev-orchestrator non copiable dans le cache de test"
  fi
  rm -rf "$LAB_DEFAULT" "$LAB_TARGET"
else
  skip "T35 : check-gsd-engine.sh introuvable dans ce repo"
fi

# ---------------------------------------------------------------------------
# T36 (TGT-04, documentation) — la cascade documentaire vf-update/SKILL.md mentionne le marqueur
# .vibeflow-target, pas seulement le code.
# ---------------------------------------------------------------------------
SKILL_MD="$REPO/conductor/skills/vf-update/SKILL.md"
if [ -f "$SKILL_MD" ]; then
  occ=$("$GREP" -c '\.vibeflow-target' "$SKILL_MD" 2>/dev/null || true)
  occ="${occ:-0}"
  if [ "$occ" -ge 1 ]; then
    ok "T36 (TGT-04) : vf-update/SKILL.md documente le marqueur .vibeflow-target ($occ occurrence(s))"
  else
    ko "T36 (TGT-04) : vf-update/SKILL.md ne mentionne pas .vibeflow-target"
  fi
else
  skip "T36 : vf-update/SKILL.md introuvable"
fi

# ---------------------------------------------------------------------------
# T37 (ADPT-02/ADPT-03, 38-05) — wiring de l'adaptateur Codex dans install_module() : sur un
# runtime détecté `codex` (VF_RUNTIME=codex, override prioritaire de detect_agent_runtime — pas
# besoin du binaire `codex` réel dans le PATH), install d'un module à agent (content-bundle) fait
# apparaître la ligne `[codex-adapter]` verbatim sur stdout. HOME isolé (même garde que T24-T26,
# register-codex-agent.sh écrit sous $CODEX_HOME/agents/vibeflow/, défaut $HOME/.codex).
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
FAKE_HOME_CODEX="$LAB/home"
mkdir -p "$FAKE_HOME_CODEX"
if prepare_module "$CACHE" "content-bundle"; then
  OUT=$(cd "$LAB" && HOME="$FAKE_HOME_CODEX" VF_RUNTIME=codex VIBEFLOW_CACHE="$CACHE" \
    bash "$INSTALLER" install content-bundle 2>&1)
  miss=0
  echo "$OUT" | "$GREP" -q '^\[codex-adapter\] ' \
    || { ko "T37 (ADPT-02/03) : aucune ligne [codex-adapter] sur stdout de l'install (runtime codex détecté via VF_RUNTIME)"; miss=1; }
  [ -n "$(find "$FAKE_HOME_CODEX/.codex/agents/vibeflow" -name '*.toml' 2>/dev/null)" ] \
    || { ko "T37 (ADPT-02/03) : aucun .toml posé sous \$FAKE_HOME_CODEX/.codex/agents/vibeflow/"; miss=1; }
  [ "$miss" -eq 0 ] && ok "T37 (ADPT-02/03) : bannière [codex-adapter] verbatim + rôle .toml réellement posé (runtime codex détecté, content-bundle)"
else
  skip "T37 (ADPT-02/03) : content-bundle non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T38 (ADPT-02/03, non-régression) — le MÊME install, runtime détecté `claude`, N'APPELLE PAS
# register-codex-agent.sh : aucune ligne [codex-adapter], aucun $HOME/.codex créé.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
FAKE_HOME_CLAUDE="$LAB/home"
mkdir -p "$FAKE_HOME_CLAUDE"
if prepare_module "$CACHE" "content-bundle"; then
  OUT=$(cd "$LAB" && HOME="$FAKE_HOME_CLAUDE" VF_RUNTIME=claude VIBEFLOW_CACHE="$CACHE" \
    bash "$INSTALLER" install content-bundle 2>&1)
  miss=0
  echo "$OUT" | "$GREP" -q '^\[codex-adapter\] ' \
    && { ko "T38 (ADPT-02/03, non-régression) : ligne [codex-adapter] présente alors que le runtime détecté est claude"; miss=1; }
  [ -d "$FAKE_HOME_CLAUDE/.codex" ] \
    && { ko "T38 (ADPT-02/03, non-régression) : \$FAKE_HOME_CLAUDE/.codex créé alors que le runtime détecté est claude"; miss=1; }
  [ "$miss" -eq 0 ] && ok "T38 (ADPT-02/03, non-régression) : aucune ligne [codex-adapter], aucun \$HOME/.codex créé (runtime claude détecté)"
else
  skip "T38 (ADPT-02/03, non-régression) : content-bundle non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T39 (D-38-P, DISCRIMINANT) — --target refuse $HOME littéral ET résolu (T-38-09). Contre-épreuve
# dans le MÊME test : un sous-dossier du même $HOME reste accepté — preuve que le refus vient de
# la garde $HOME spécifiquement, pas d'un chemin déjà existant ou d'une garde générique (un
# fixture mort ressemblerait à un mutant tué sans cette contre-épreuve).
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
FAKE_HOME="$LAB/home"
mkdir -p "$FAKE_HOME"
if prepare_module "$CACHE" "dev-orchestrator"; then
  miss=0
  OUT=$(cd "$LAB" && HOME="$FAKE_HOME" VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" --target "$FAKE_HOME" install dev-orchestrator 2>&1)
  RC=$?
  if [ "$RC" -eq 0 ]; then
    ko "T39 (D-38-P, DISCRIMINANT) : --target \"\$HOME\" littéral ACCEPTÉ (rc=0) — devrait être refusé"
    miss=1
  elif ! echo "$OUT" | "$GREP" -qi 'HOME'; then
    ko "T39 (D-38-P, DISCRIMINANT) : --target \"\$HOME\" refusé (rc=$RC) mais message sans mention explicite de HOME — $OUT"
    miss=1
  fi
  [ -f "$FAKE_HOME/agents/dev-orchestrator.md" ] \
    && { ko "T39 (D-38-P, DISCRIMINANT) : payload posé directement dans \$HOME malgré le refus attendu"; miss=1; }
  # Contre-épreuve : $HOME/.claude (sous-dossier du même $HOME) reste accepté.
  (cd "$LAB" && HOME="$FAKE_HOME" VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" --target "$FAKE_HOME/.claude" install dev-orchestrator >/dev/null 2>&1)
  [ -f "$FAKE_HOME/.claude/agents/dev-orchestrator.md" ] \
    || { ko "T39 (D-38-P, DISCRIMINANT) : contre-épreuve — \$HOME/.claude aurait dû être accepté (refus limité à \$HOME exact)"; miss=1; }
  [ "$miss" -eq 0 ] && ok "T39 (D-38-P, DISCRIMINANT) : --target \"\$HOME\" refusé (message explicite), \$HOME/.claude accepté en contre-épreuve"
else
  skip "T39 : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T39b (D-38-P, mineur revue 38-04) — la garde $HOME a DEUX gardes distinctes (littérale l.~192,
# résolution physique l.~206-220). T39 ci-dessus n'exerce QUE la première (--target vaut $HOME
# EXACTEMENT comme chaîne). Ce test exerce la SECONDE : une forme qui ne matche PAS $HOME
# littéralement (segment ".." intercalé) mais RÉSOUT physiquement au même répertoire — aucun test
# dédié n'existait avant ce lot.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
FAKE_HOME="$LAB/home"
mkdir -p "$FAKE_HOME"
if prepare_module "$CACHE" "dev-orchestrator"; then
  miss=0
  OUT=$(cd "$LAB" && HOME="$FAKE_HOME" VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" --target "$FAKE_HOME/../home" install dev-orchestrator 2>&1)
  RC=$?
  if [ "$RC" -eq 0 ]; then
    ko "T39b (D-38-P, résolution physique) : --target \"\$FAKE_HOME/../home\" (résout physiquement à \$HOME, forme NON littérale) ACCEPTÉ (rc=0) — la 2e garde (résolution physique) ne tire pas"
    miss=1
  elif ! echo "$OUT" | "$GREP" -qi 'HOME'; then
    ko "T39b (D-38-P, résolution physique) : refusé (rc=$RC) mais message sans mention explicite de HOME — $OUT"
    miss=1
  fi
  [ -f "$FAKE_HOME/agents/dev-orchestrator.md" ] \
    && { ko "T39b (D-38-P, résolution physique) : payload posé directement dans \$HOME malgré le refus attendu"; miss=1; }
  [ "$miss" -eq 0 ] && ok "T39b (D-38-P, résolution physique) : --target résolvant physiquement à \$HOME (forme non littérale) refusé par la 2e garde"
else
  skip "T39b : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T39c (D-38-P, BLOQUANT 1 revue 38-04) — la garde $HOME résolue est CONTOURNABLE PAR LA CASSE sur
# une FS insensible à la casse qui préserve la casse (APFS macOS, défaut de fait) : `--target
# "$LAB/HOME"` avec `$HOME="$LAB/home"` désigne le MÊME inode mais produit une chaîne `pwd -P`
# différente, donc une comparaison textuelle seule ne suffit pas — vérifié par mesure directe
# (même device:inode, casse stockée ≠ casse demandée). Ce test ne s'exécute QUE si le FS courant
# est réellement insensible à la casse (sondé localement, jamais supposé) — la CI de ce dépôt
# tourne sous Linux/ext4 (sensible à la casse) : SKIP propre là-bas, la 2e garde générique reste
# couverte sur toute plateforme par T39b.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
FAKE_HOME="$LAB/home"
FAKE_HOME_UPPER="$LAB/HOME"
mkdir -p "$FAKE_HOME"
touch "$LAB/.ci-probe-a" 2>/dev/null
IS_CASE_INSENSITIVE_FS=0
[ -f "$LAB/.CI-PROBE-A" ] && IS_CASE_INSENSITIVE_FS=1
rm -f "$LAB/.ci-probe-a" "$LAB/.CI-PROBE-A" 2>/dev/null
if [ "$IS_CASE_INSENSITIVE_FS" = "1" ]; then
  CACHE="$LAB/cache"
  if prepare_module "$CACHE" "dev-orchestrator"; then
    miss=0
    OUT=$(cd "$LAB" && HOME="$FAKE_HOME" VIBEFLOW_CACHE="$CACHE" \
       bash "$INSTALLER" --target "$FAKE_HOME_UPPER" install dev-orchestrator 2>&1)
    RC=$?
    if [ "$RC" -eq 0 ]; then
      ko "T39c (D-38-P, BLOQUANT 1) : --target \"\$LAB/HOME\" (même inode que \$HOME=\$LAB/home sur FS insensible à la casse) ACCEPTÉ (rc=0) — la garde textuelle est contournée par la casse"
      miss=1
    fi
    { [ -f "$FAKE_HOME_UPPER/agents/dev-orchestrator.md" ] || [ -f "$FAKE_HOME/agents/dev-orchestrator.md" ]; } \
      && { ko "T39c (D-38-P, BLOQUANT 1) : payload posé dans \$HOME (via la casse alternative) malgré le refus attendu"; miss=1; }
    [ "$miss" -eq 0 ] && ok "T39c (D-38-P, BLOQUANT 1) : --target de casse différente mais MÊME inode que \$HOME refusé (FS insensible à la casse détecté et exercé)"
  else
    skip "T39c : dev-orchestrator non copiable dans le cache de test"
  fi
else
  skip "T39c (D-38-P, BLOQUANT 1) : FS sensible à la casse détecté (probablement Linux/CI) — garde non exerçable ici par construction, couverte sur toute plateforme par T39b"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T39d (BLOQUANT 1 persistant, revue 38-04 correction 3/3) — unité DIRECTE de vf_same_inode() via
# un HARDLINK, pas la casse. T39c ci-dessus ne s'exécute que sur une FS insensible à la casse
# (SKIP inconditionnel sous Linux/CI, cf. commentaire ci-dessus) — le défaut réel (`stat -f`
# GNU coreutils = alias de `--file-system`, deux arguments FILE au lieu d'une option + un
# argument, le 2e réussit et pollue la comparaison avec un blob contenant le nom du fichier) est
# donc STRUCTURELLEMENT INDÉTECTABLE par la suite telle qu'écrite avant ce test : le seul test qui
# exerce une collision d'inode ne tournait jamais là où le bug vit. Un hardlink donne le MÊME
# inode SUR TOUTE PLATEFORME sans dépendre de la sensibilité à la casse du FS — il tourne donc
# PARTOUT, y compris en CI Linux. Extrait vf_same_inode() du fichier RÉELLEMENT posé sur disque
# via `sed`+`eval` (même pattern que resolve_via_posed_caller plus haut) pour exercer
# l'implémentation COURANTE, jamais une copie qui pourrait diverger silencieusement.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
mkdir -p "$LAB/dir1"
echo "contenu" > "$LAB/dir1/realfile"
ln "$LAB/dir1/realfile" "$LAB/dir1/hardlinked_alias" 2>/dev/null
echo "autre contenu" > "$LAB/dir1/otherfile"
if [ -f "$LAB/dir1/hardlinked_alias" ]; then
  miss=0
  RESULT=$(bash -c '
    eval "$(sed -n "/^vf_same_inode()/,/^}/p" "$0")"
    if vf_same_inode "$1" "$2"; then echo "same=true"; else echo "same=false"; fi
    if vf_same_inode "$1" "$3"; then echo "different=true"; else echo "different=false"; fi
    if vf_same_inode "$1" "$1.nonexistent"; then echo "nonexistent=true"; else echo "nonexistent=false"; fi
  ' "$INSTALLER" "$LAB/dir1/realfile" "$LAB/dir1/hardlinked_alias" "$LAB/dir1/otherfile")
  echo "$RESULT" | "$GREP" -q '^same=true$' \
    || { ko "T39d (BLOQUANT 1 persistant) : vf_same_inode(realfile, hardlinked_alias) = false — le MÊME inode (hardlink, toute plateforme) n'est pas détecté — $RESULT"; miss=1; }
  echo "$RESULT" | "$GREP" -q '^different=false$' \
    || { ko "T39d (BLOQUANT 1 persistant) : contre-épreuve — vf_same_inode(realfile, otherfile) = true — deux fichiers DIFFÉRENTS classés même inode (garde non discriminante)"; miss=1; }
  echo "$RESULT" | "$GREP" -q '^nonexistent=false$' \
    || { ko "T39d (BLOQUANT 1 persistant) : vf_same_inode sur une cible INEXISTANTE ne rend pas false proprement (devrait échouer sans crash)"; miss=1; }
  [ "$miss" -eq 0 ] && ok "T39d (BLOQUANT 1 persistant, HARDLINK, toute plateforme y compris CI Linux) : vf_same_inode détecte le même inode, discrimine deux fichiers différents, gère la cible absente"
else
  skip "T39d : hardlink non créable sur ce FS (ln a échoué) — probablement un FS réseau/overlay restrictif"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T40 (D-38-P) — --target pointant hors du repo mais VIDE reste accepté (rc=0) : le danger n'est
# pas "hors repo", c'est $HOME peuplé — ne pas confondre les deux gardes.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
OUTSIDE_EMPTY="$(mktemp -d)/fresh-empty-target"
if prepare_module "$CACHE" "dev-orchestrator"; then
  OUT=$(cd "$LAB" && VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" --target "$OUTSIDE_EMPTY" install dev-orchestrator 2>&1)
  RC=$?
  if [ "$RC" -eq 0 ] && [ -f "$OUTSIDE_EMPTY/agents/dev-orchestrator.md" ]; then
    ok "T40 (D-38-P) : --target hors du repo mais vide -> accepté (rc=0), payload réellement posé"
  else
    ko "T40 (D-38-P) : --target hors du repo mais vide -> refusé ou payload manquant (rc=$RC) — $OUT"
  fi
else
  skip "T40 : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB" "$(dirname "$OUTSIDE_EMPTY")"

# ---------------------------------------------------------------------------
# T41 (D-38-P, corrigé revue 38-04 — majeur) — traversée `../../../../x` : PAS de refus de
# principe (contredirait --target /tmp/mon-lab), mais la cible résolue est affichée EN CLAIR sur
# STDERR (log() écrit sur stderr, cf. vibeflow-update.sh:32) — jamais une surprise silencieuse.
# Le PLAN (38-04-PLAN.md:227) et ce commentaire disaient « stdout » par erreur ; corrigés. Flux
# capturés SÉPARÉMENT (jamais `2>&1`, qui masquait l'écart — même défaut que la fixture idéalisée
# du gate FIDE-03 : un test vert qui ne démontre pas sa propre assertion) : la ligne doit être sur
# stderr ET absente de stdout.
# ---------------------------------------------------------------------------
BASE="$(mktemp -d)"
CACHE="$BASE/cache"
mkdir -p "$BASE/a/b/c/d"
if prepare_module "$CACHE" "dev-orchestrator"; then
  EXPECTED_RESOLVED="$(cd -P "$BASE" && pwd -P)/traversal-escaped"
  STDOUT_FILE="$(mktemp)"
  STDERR_FILE="$(mktemp)"
  (cd "$BASE/a/b/c/d" && VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" --target "../../../../traversal-escaped" install dev-orchestrator) \
     >"$STDOUT_FILE" 2>"$STDERR_FILE"
  RC=$?
  miss=0
  [ "$RC" -eq 0 ] || { ko "T41 (D-38-P) : traversée ../../../../x refusée (rc=$RC) — devrait être acceptée — stderr=$(cat "$STDERR_FILE")"; miss=1; }
  [ -f "$BASE/traversal-escaped/agents/dev-orchestrator.md" ] \
    || { ko "T41 (D-38-P) : traversée acceptée mais payload absent de la cible résolue"; miss=1; }
  "$GREP" -qF "$EXPECTED_RESOLVED" "$STDERR_FILE" \
    || { ko "T41 (D-38-P, majeur) : cible résolue absente de STDERR (attendu : $EXPECTED_RESOLVED) — stderr=$(cat "$STDERR_FILE")"; miss=1; }
  "$GREP" -qF "$EXPECTED_RESOLVED" "$STDOUT_FILE" \
    && { ko "T41 (D-38-P, majeur) : cible résolue trouvée sur STDOUT — log() doit écrire UNIQUEMENT sur stderr, fuite de flux"; miss=1; }
  [ "$miss" -eq 0 ] && ok "T41 (D-38-P) : traversée ../../../../x acceptée (rc=0) ET cible résolue affichée en clair sur stderr (jamais stdout, flux vérifiés séparément)"
  rm -f "$STDOUT_FILE" "$STDERR_FILE"
else
  skip "T41 : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$BASE"

# ---------------------------------------------------------------------------
# T42 (D-38-P, DISCRIMINANT) — cible --target pré-existante et NON VIDE refusée par défaut
# (message listant le contenu trouvé), acceptée seulement avec --target-nonempty-ok explicite.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
CUSTOM_TARGET="$LAB/nonempty-target"
mkdir -p "$CUSTOM_TARGET"
echo "contenu préexistant" > "$CUSTOM_TARGET/somefile.txt"
if prepare_module "$CACHE" "dev-orchestrator"; then
  miss=0
  OUT=$(cd "$LAB" && VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" --target "$CUSTOM_TARGET" install dev-orchestrator 2>&1)
  RC=$?
  if [ "$RC" -eq 0 ]; then
    ko "T42 (D-38-P, DISCRIMINANT) : cible non vide sans drapeau ACCEPTÉE (rc=0) — devrait être refusée"
    miss=1
  elif ! echo "$OUT" | "$GREP" -qi 'somefile.txt'; then
    ko "T42 (D-38-P, DISCRIMINANT) : refus sans drapeau (rc=$RC) mais message sans le contenu trouvé — $OUT"
    miss=1
  fi
  [ -f "$CUSTOM_TARGET/agents/dev-orchestrator.md" ] \
    && { ko "T42 (D-38-P, DISCRIMINANT) : payload posé malgré le refus attendu (sans drapeau)"; miss=1; }
  # Avec le drapeau explicite --target-nonempty-ok : accepté, le fichier préexistant survit.
  (cd "$LAB" && VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" --target "$CUSTOM_TARGET" --target-nonempty-ok install dev-orchestrator >/dev/null 2>&1)
  [ -f "$CUSTOM_TARGET/agents/dev-orchestrator.md" ] \
    || { ko "T42 (D-38-P, DISCRIMINANT) : --target-nonempty-ok fourni mais payload toujours absent"; miss=1; }
  [ -f "$CUSTOM_TARGET/somefile.txt" ] \
    || { ko "T42 (D-38-P, DISCRIMINANT) : fichier préexistant disparu après install --target-nonempty-ok"; miss=1; }
  [ "$miss" -eq 0 ] && ok "T42 (D-38-P, DISCRIMINANT) : cible non vide refusée par défaut (contenu listé), acceptée avec --target-nonempty-ok"
else
  skip "T42 : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T43 (D-38-P, révisé revue 38-04 ajout manager) — exception légitime SANS drapeau : DÉSORMAIS
# CONDITIONNÉE à un registre RÉEL (non vide, au moins un `mod=version`), plus une garde-fou vert
# à vide : un fichier .vibeflow-installed VIDE planté à la main ne doit PLUS ouvrir l'exception
# silencieusement (défaut mesuré en régime plein). Trois sous-cas, discriminants entre eux :
#   T43a — registre VIDE (fichier vide) -> refusé, comme n'importe quelle cible non vide sans
#          registre réel.
#   T43b — registre VALIDE (au moins une entrée mod=version) -> accepté ET la sortie NOMME
#          explicitement la voie « registre VibeFlow trouvé ».
#   T43c — registre INCONSISTENT (format écrit par _vf_rollback_mark_inconsistent) -> accepté
#          (voie de réparation légitime, pas un registre corrompu) ET la sortie porte une ligne
#          DÉDIÉE distincte du cas nominal T43b.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
CUSTOM_TARGET="$LAB/registered-target-empty"
mkdir -p "$CUSTOM_TARGET/scripts"
touch "$CUSTOM_TARGET/scripts/.vibeflow-installed"
if prepare_module "$CACHE" "dev-orchestrator"; then
  OUT=$(cd "$LAB" && VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" --target "$CUSTOM_TARGET" install dev-orchestrator 2>&1)
  RC=$?
  if [ "$RC" -ne 0 ] && [ ! -f "$CUSTOM_TARGET/agents/dev-orchestrator.md" ]; then
    ok "T43a (D-38-P, ajout manager) : registre .vibeflow-installed VIDE (planté à la main) -> refusé (rc=$RC), l'exception ne s'ouvre plus sur la seule existence du fichier"
  else
    ko "T43a (D-38-P, ajout manager) : registre .vibeflow-installed VIDE ACCEPTÉ (rc=$RC) — l'exception s'ouvre encore sur la seule existence du fichier, sans validation du contenu — $OUT"
  fi
else
  skip "T43a : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

LAB="$(mktemp -d)"
CACHE="$LAB/cache"
CUSTOM_TARGET="$LAB/registered-target-valid"
mkdir -p "$CUSTOM_TARGET/scripts"
echo "software-architecture=v1.0.0" > "$CUSTOM_TARGET/scripts/.vibeflow-installed"
if prepare_module "$CACHE" "dev-orchestrator"; then
  miss=0
  OUT=$(cd "$LAB" && VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" --target "$CUSTOM_TARGET" install dev-orchestrator 2>&1)
  RC=$?
  [ "$RC" -eq 0 ] && [ -f "$CUSTOM_TARGET/agents/dev-orchestrator.md" ] \
    || { ko "T43b (D-38-P, ajout manager) : registre VALIDE refusé (rc=$RC) — devrait être accepté sans drapeau — $OUT"; miss=1; }
  echo "$OUT" | "$GREP" -qi 'registre VibeFlow trouvé' \
    || { ko "T43b (D-38-P, ajout manager) : accepté mais la sortie ne NOMME PAS la voie empruntée (attendu une ligne « registre VibeFlow trouvé ») — $OUT"; miss=1; }
  [ "$miss" -eq 0 ] && ok "T43b (D-38-P, ajout manager) : registre VALIDE -> accepté ET voie empruntée journalisée"
else
  skip "T43b : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

LAB="$(mktemp -d)"
CACHE="$LAB/cache"
CUSTOM_TARGET="$LAB/registered-target-inconsistent"
mkdir -p "$CUSTOM_TARGET/scripts"
echo "software-architecture=INCONSISTENT:hooks:v2.0.0" > "$CUSTOM_TARGET/scripts/.vibeflow-installed"
if prepare_module "$CACHE" "dev-orchestrator"; then
  miss=0
  OUT=$(cd "$LAB" && VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" --target "$CUSTOM_TARGET" install dev-orchestrator 2>&1)
  RC=$?
  [ "$RC" -eq 0 ] && [ -f "$CUSTOM_TARGET/agents/dev-orchestrator.md" ] \
    || { ko "T43c (D-38-P, ajout manager) : registre INCONSISTENT refusé (rc=$RC) — devrait être accepté (voie de réparation légitime) — $OUT"; miss=1; }
  echo "$OUT" | "$GREP" -qi 'réparation' \
    || { ko "T43c (D-38-P, ajout manager) : accepté mais aucune ligne DÉDIÉE de réparation (distincte du cas nominal T43b) — $OUT"; miss=1; }
  echo "$OUT" | "$GREP" -qi 'registre VibeFlow trouvé' \
    && { ko "T43c (D-38-P, ajout manager) : le message NOMINAL (T43b) est apparu pour un registre INCONSISTENT — les deux voies doivent rester distinctes"; miss=1; }
  [ "$miss" -eq 0 ] && ok "T43c (D-38-P, ajout manager) : registre INCONSISTENT -> accepté (réparation légitime) ET ligne dédiée, distincte du cas nominal"
else
  skip "T43c : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T44 (BLOQUANT 2, revue 38-04, DISCRIMINANT) — la garde « cible non vide » s'exécutait AVANT
# `cmd="$1"` (dispatch), donc pour TOUS les verbes. `status` (lecture seule) et `sync` (no-op
# documenté) doivent PASSER sur une cible non vide SANS registre ET sans --target-nonempty-ok —
# aucun payload écrit, rien à protéger. `install`, lui, doit toujours REFUSER dans le MÊME
# scénario — témoin qui distingue un refus de garde d'une erreur en aval (piège documenté au
# mandat : c'est celui où la vérification précédente était tombée).
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
CUSTOM_TARGET="$LAB/nonempty-readonly-target"
mkdir -p "$CUSTOM_TARGET"
echo "contenu préexistant" > "$CUSTOM_TARGET/somefile.txt"
if prepare_module "$CACHE" "dev-orchestrator"; then
  miss=0
  OUT_STATUS=$(cd "$LAB" && VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" --target "$CUSTOM_TARGET" status 2>&1)
  RC_STATUS=$?
  [ "$RC_STATUS" -eq 0 ] \
    || { ko "T44 (BLOQUANT 2) : 'status' sur cible non vide REFUSÉ (rc=$RC_STATUS) — devrait passer, verbe en lecture seule — $OUT_STATUS"; miss=1; }
  OUT_SYNC=$(cd "$LAB" && VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" --target "$CUSTOM_TARGET" sync 2>&1)
  RC_SYNC=$?
  [ "$RC_SYNC" -eq 0 ] \
    || { ko "T44 (BLOQUANT 2) : 'sync' sur cible non vide REFUSÉ (rc=$RC_SYNC) — devrait passer, no-op documenté — $OUT_SYNC"; miss=1; }
  OUT_INSTALL=$(cd "$LAB" && VIBEFLOW_CACHE="$CACHE" bash "$INSTALLER" --target "$CUSTOM_TARGET" install dev-orchestrator 2>&1)
  RC_INSTALL=$?
  [ "$RC_INSTALL" -ne 0 ] \
    || { ko "T44 (BLOQUANT 2) : 'install' sur cible non vide (même scénario que status/sync ci-dessus) ACCEPTÉ (rc=0) — devrait rester refusé, seule la portée du verbe a changé"; miss=1; }
  [ -f "$CUSTOM_TARGET/agents/dev-orchestrator.md" ] \
    && { ko "T44 (BLOQUANT 2) : payload posé par 'install' malgré le refus attendu"; miss=1; }
  [ "$miss" -eq 0 ] && ok "T44 (BLOQUANT 2, DISCRIMINANT) : 'status'/'sync' passent sur cible non vide (lecture seule/no-op), 'install' reste refusé dans le MÊME scénario"
else
  skip "T44 : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T45 (ajout manager, revue 38-04) — visibilité de l'asymétrie --scope/--target : `--scope user`
# affiche désormais la cible résolue, même forme/flux (stderr) que `--target`. On ne teste PAS
# l'harmonisation du comportement (hors périmètre, tranché par le manager) — seulement que la
# ligne existe et porte la cible réelle.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
FAKE_HOME="$LAB/home"
mkdir -p "$FAKE_HOME"
if prepare_module "$CACHE" "dev-orchestrator"; then
  OUT=$(cd "$LAB" && HOME="$FAKE_HOME" VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" --scope user install dev-orchestrator 2>&1)
  echo "$OUT" | "$GREP" -qF "$FAKE_HOME/.claude" \
    && ok "T45 (ajout manager) : --scope user affiche la cible résolue ($FAKE_HOME/.claude), même visibilité que --target" \
    || ko "T45 (ajout manager) : --scope user n'affiche PAS la cible résolue — $OUT"
else
  skip "T45 : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T46 (BLOQUANT 2 persistant, revue 38-04 correction B-02) — vf_registry_state classait DU
# BINAIRE comme "valid" : `grep -qE '^[^=]+=.+$'` matche quasi systématiquement des octets
# aléatoires (n'importe quelle "ligne" binaire contenant un `=` 0x3D avec du contenu autour
# suffit) — mesuré 5/5 sur des essais /dev/urandom de 3000 octets AVANT ce durcissement, et
# rejoué end-to-end via le vrai installeur (exception de ré-install accordée sur un registre
# garbage, payload posé sans drapeau). EXACTEMENT le bypass que T43 venait fermer, déplacé de
# "fichier vide planté" à "fichier garbage planté". Discriminant DANS LE MÊME test (mutation
# memory) : le registre BINAIRE doit être refusé ET un registre RÉEL (`mod=version`) doit rester
# accepté dans le MÊME scénario — sinon on durcit trop et on casse le cas nominal T43b.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
GARBAGE_TARGET="$LAB/registered-target-garbage"
mkdir -p "$GARBAGE_TARGET/scripts"
head -c 3000 /dev/urandom > "$GARBAGE_TARGET/scripts/.vibeflow-installed"
REAL_TARGET="$LAB/registered-target-real"
mkdir -p "$REAL_TARGET/scripts"
echo "software-architecture=v1.0.0" > "$REAL_TARGET/scripts/.vibeflow-installed"
if prepare_module "$CACHE" "dev-orchestrator"; then
  miss=0
  OUT_GARBAGE=$(cd "$LAB" && VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" --target "$GARBAGE_TARGET" install dev-orchestrator 2>&1)
  RC_GARBAGE=$?
  { [ "$RC_GARBAGE" -eq 0 ] || [ -f "$GARBAGE_TARGET/agents/dev-orchestrator.md" ]; } \
    && { ko "T46 (BLOQUANT 2 persistant, B-02) : registre BINAIRE (3000 octets /dev/urandom) ACCEPTÉ (rc=$RC_GARBAGE) — la classification 'au moins une ligne matche' laisse encore passer du garbage — $OUT_GARBAGE"; miss=1; }
  OUT_REAL=$(cd "$LAB" && VIBEFLOW_CACHE="$CACHE" \
     bash "$INSTALLER" --target "$REAL_TARGET" install dev-orchestrator 2>&1)
  RC_REAL=$?
  { [ "$RC_REAL" -eq 0 ] && [ -f "$REAL_TARGET/agents/dev-orchestrator.md" ]; } \
    || { ko "T46 (BLOQUANT 2 persistant, B-02) : contre-épreuve — registre RÉEL (mod=version) refusé (rc=$RC_REAL) — le durcissement casse le cas nominal — $OUT_REAL"; miss=1; }
  [ "$miss" -eq 0 ] && ok "T46 (BLOQUANT 2 persistant, B-02, DISCRIMINANT) : registre BINAIRE refusé, registre RÉEL toujours accepté dans le MÊME scénario"
else
  skip "T46 : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T47 (MAJEUR, revue 38-04, M-01) — le `case "$_vf_registry_state" in valid|inconsistent|empty`
# est exhaustif AUJOURD'HUI par construction (seules valeurs rendues par vf_registry_state), mais
# rien ne le garantissait : une 4e valeur (ou une chaîne vide par bug) traversait AVANT ce lot sans
# `err` ni `log`, et le script CONTINUAIT — cible non vide acceptée sans preuve de registre
# (fail-open dans une garde de sécurité). Ce test PATCHE une copie de l'installeur RÉELLEMENT posé
# pour forcer vf_registry_state() à rendre une valeur inconnue (redéfinition de la fonction après
# sa définition d'origine — bash retient la DERNIÈRE définition rencontrée à l'exécution — le
# reste du fichier, y compris le `case`/`err` sous test, est inchangé) : preuve directe du filet
# `*)`  sans dépendre d'un état de registre qui n'existe pas encore en pratique.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
UNKNOWN_TARGET="$LAB/registered-target-unknown-state"
mkdir -p "$UNKNOWN_TARGET/scripts"
echo "software-architecture=v1.0.0" > "$UNKNOWN_TARGET/scripts/.vibeflow-installed"
PATCHED_INSTALLER="$LAB/patched-installer.sh"
cp "$INSTALLER" "$PATCHED_INSTALLER"
# Insère le override juste après la définition d'origine (avant tout point d'appel réel) : la
# DERNIÈRE définition rencontrée à l'exécution gagne, le `case` en aval voit la valeur bidon.
END_LINE=$("$GREP" -n '^vf_registry_state()' "$PATCHED_INSTALLER" | head -1 | cut -d: -f1)
END_LINE=$(awk -v start="$END_LINE" 'NR>=start && /^}/{print NR; exit}' "$PATCHED_INSTALLER")
{
  head -n "$END_LINE" "$PATCHED_INSTALLER"
  echo 'vf_registry_state() { echo "bogus-state-non-reconnu"; }'
  tail -n "+$((END_LINE + 1))" "$PATCHED_INSTALLER"
} > "$PATCHED_INSTALLER.tmp" && mv "$PATCHED_INSTALLER.tmp" "$PATCHED_INSTALLER"
if prepare_module "$CACHE" "dev-orchestrator"; then
  miss=0
  OUT=$(cd "$LAB" && VIBEFLOW_CACHE="$CACHE" \
     bash "$PATCHED_INSTALLER" --target "$UNKNOWN_TARGET" install dev-orchestrator 2>&1)
  RC=$?
  { [ "$RC" -eq 0 ] || [ -f "$UNKNOWN_TARGET/agents/dev-orchestrator.md" ]; } \
    && { ko "T47 (MAJEUR, M-01) : état de registre INCONNU ('bogus-state-non-reconnu') ACCEPTÉ (rc=$RC) — le case sans branche */ laisse traverser une valeur inattendue (fail-open) — $OUT"; miss=1; }
  echo "$OUT" | "$GREP" -qi 'non reconnu' \
    || { ko "T47 (MAJEUR, M-01) : refusé (rc=$RC) mais aucun message explicite 'non reconnu' — $OUT"; miss=1; }
  [ "$miss" -eq 0 ] && ok "T47 (MAJEUR, M-01) : état de registre INCONNU refusé par le filet */ (rc≠0), aucun payload posé"
else
  skip "T47 : dev-orchestrator non copiable dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T48 (MIGR-05, 38-06) — coexistence sans hooks déclarée AU MÊME endroit à l'install ET au
# `status` : gate check-artifact-fidelity.sh --coexistence-report résolu depuis le cache
# (conductor/scripts/), .planning/config.json de fixture avec un runtime coexistant.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
if prepare_module "$CACHE" "conductor" && prepare_module "$CACHE" "validator"; then
  mkdir -p "$LAB/.planning"
  cat > "$LAB/.planning/config.json" <<'EOF'
{"vf_runtimes": {"installed": ["claude", "codex"], "active": "codex"}}
EOF
  miss=0
  INSTALL_OUT=$(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" \
    bash "$INSTALLER" install validator 2>&1)
  echo "$INSTALL_OUT" | "$GREP" -qF '[fidelity-coexistence] codex : opère SANS gouvernance de hooks' \
    || { ko "T48 install : ligne [fidelity-coexistence] absente de la sortie d'install — $INSTALL_OUT"; miss=1; }

  STATUS_OUT=$(cd "$LAB" && VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" \
    bash "$INSTALLER" status 2>&1)
  echo "$STATUS_OUT" | "$GREP" -qF '[fidelity-coexistence] codex : opère SANS gouvernance de hooks' \
    || { ko "T48 status : ligne [fidelity-coexistence] absente de la sortie de status — $STATUS_OUT"; miss=1; }

  [ "$miss" -eq 0 ] && ok "T48 (MIGR-05) : coexistence sans hooks déclarée au même endroit à l'install ET au status"
else
  skip "T48 : conductor/validator non copiables dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T49 (CODEX-B4, 38-07) — resolve_posed_agent_artifact() rend TOUS les agents d'un module (root
# AGENT.md ET agents/*.md, cumulés), pas seulement le premier trouvé. Install de dev-orchestrator
# + design-orchestrator (root + agents/) + validator (root SEUL, témoin de non-régression
# mono-agent) sous runtime codex détecté (isolation HOME) — l'ensemble TRIÉ des noms `.toml`
# posés est identique (comm -3 vide) à l'ensemble TRIÉ des `name:` frontmatter des 10 fichiers
# source. Preuve par comparaison d'ENSEMBLE, jamais par comptage (D-38 prohibition).
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
FAKE_HOME_CODEX="$LAB/home"
mkdir -p "$FAKE_HOME_CODEX"
if prepare_module "$CACHE" "dev-orchestrator" && prepare_module "$CACHE" "design-orchestrator" && prepare_module "$CACHE" "validator"; then
  miss=0
  for mod in dev-orchestrator design-orchestrator validator; do
    (cd "$LAB" && HOME="$FAKE_HOME_CODEX" VF_RUNTIME=codex VIBEFLOW_CACHE="$CACHE" \
      bash "$INSTALLER" install "$mod" >/dev/null 2>&1)
  done
  SOURCE_NAMES="$LAB/source_names.txt"
  : > "$SOURCE_NAMES"
  for f in "$REPO/dev-orchestrator/AGENT.md" "$REPO/dev-orchestrator/agents/"*.md \
           "$REPO/design-orchestrator/AGENT.md" "$REPO/design-orchestrator/agents/"*.md \
           "$REPO/validator/AGENT.md"; do
    [ -f "$f" ] || continue
    _name="$(sed -n 's/^name:[[:space:]]*//p' "$f" | head -1 | tr -d '[:space:]')"
    printf '%s\n' "$_name" >> "$SOURCE_NAMES"
  done
  sort -o "$SOURCE_NAMES" "$SOURCE_NAMES"
  POSED_NAMES="$LAB/posed_names.txt"
  find "$FAKE_HOME_CODEX/.codex/agents/vibeflow" -name '*.toml' 2>/dev/null \
    | xargs -n1 basename 2>/dev/null | sed 's/\.toml$//' | sort > "$POSED_NAMES"
  DIFF="$(comm -3 "$SOURCE_NAMES" "$POSED_NAMES")"
  [ -z "$DIFF" ] \
    || { ko "T49 (CODEX-B4) : comm -3 non vide entre agents source (10) et rôles .toml posés — écart : $(printf '%s' "$DIFF" | tr '\n' ' ')"; miss=1; }
  "$GREP" -qx 'vibeflow-validator' "$POSED_NAMES" \
    || { ko "T49 (CODEX-B4, témoin mono-agent) : vibeflow-validator (module à agent unique) absent des rôles posés — le fix multi-agents aurait régressé le cas simple"; miss=1; }
  [ "$miss" -eq 0 ] && ok "T49 (CODEX-B4) : comm -3 vide entre les 10 agents source et les rôles .toml posés (team-kernel complet + module mono-agent non régressé)"
else
  skip "T49 : dev-orchestrator/design-orchestrator/validator non copiables dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T50 (CODEX-B5, 38-07) — uninstall_module() (et donc uninstall --all) retire réellement chaque
# rôle Codex posé, sans toucher aux résidus runtime légitimes de Codex. Install de
# dev-orchestrator + design-orchestrator (9 .toml attendus) sous runtime codex, seedage de
# résidus légitimes AVANT install, puis `uninstall --all` — preuve par comm sur ensembles de noms
# (jamais un compte), et contenu des résidus inchangé (comparaison de contenu).
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
FAKE_HOME_CODEX="$LAB/home"
mkdir -p "$FAKE_HOME_CODEX/.codex/sessions" "$FAKE_HOME_CODEX/.codex/cache" \
  "$FAKE_HOME_CODEX/.codex/log" "$FAKE_HOME_CODEX/.codex/tmp/arg0"
echo "residu-session" > "$FAKE_HOME_CODEX/.codex/sessions/probe.json"
echo "residu-cache" > "$FAKE_HOME_CODEX/.codex/cache/probe"
echo "residu-log" > "$FAKE_HOME_CODEX/.codex/log/probe.log"
echo "residu-tmp" > "$FAKE_HOME_CODEX/.codex/tmp/arg0/probe"
echo "residu-models" > "$FAKE_HOME_CODEX/.codex/models_cache.json"
echo "residu-sqlite" > "$FAKE_HOME_CODEX/.codex/memories_1.sqlite"
if prepare_module "$CACHE" "dev-orchestrator" && prepare_module "$CACHE" "design-orchestrator"; then
  miss=0
  for mod in dev-orchestrator design-orchestrator; do
    (cd "$LAB" && HOME="$FAKE_HOME_CODEX" VF_RUNTIME=codex VIBEFLOW_CACHE="$CACHE" \
      bash "$INSTALLER" install "$mod" >/dev/null 2>&1)
  done
  BEFORE_NAMES="$LAB/before_names.txt"
  find "$FAKE_HOME_CODEX/.codex/agents/vibeflow" -name '*.toml' 2>/dev/null \
    | xargs -n1 basename 2>/dev/null | sed 's/\.toml$//' | sort > "$BEFORE_NAMES"
  [ "$(wc -l < "$BEFORE_NAMES" | tr -d ' ')" = "9" ] \
    || { ko "T50 (CODEX-B5, précondition) : 9 rôles .toml attendus avant uninstall, trouvé $(wc -l < "$BEFORE_NAMES" | tr -d ' ') — $(cat "$BEFORE_NAMES" | tr '\n' ' ')"; miss=1; }

  (cd "$LAB" && HOME="$FAKE_HOME_CODEX" VF_RUNTIME=codex VIBEFLOW_CACHE="$CACHE" \
    bash "$INSTALLER" uninstall --all >/dev/null 2>&1)

  AFTER_NAMES="$LAB/after_names.txt"
  find "$FAKE_HOME_CODEX/.codex/agents/vibeflow" -name '*.toml' 2>/dev/null \
    | xargs -n1 basename 2>/dev/null | sed 's/\.toml$//' | sort > "$AFTER_NAMES"
  [ -s "$AFTER_NAMES" ] \
    && { ko "T50 (CODEX-B5) : rôles .toml survivants après uninstall --all — comm : $(comm -3 "$BEFORE_NAMES" "$AFTER_NAMES" | tr '\n' ' ')"; miss=1; }

  [ "$(cat "$FAKE_HOME_CODEX/.codex/sessions/probe.json" 2>/dev/null)" = "residu-session" ] \
    || { ko "T50 (CODEX-B5, résidu légitime) : sessions/probe.json altéré ou disparu après uninstall"; miss=1; }
  [ "$(cat "$FAKE_HOME_CODEX/.codex/cache/probe" 2>/dev/null)" = "residu-cache" ] \
    || { ko "T50 (CODEX-B5, résidu légitime) : cache/probe altéré ou disparu après uninstall"; miss=1; }
  [ "$(cat "$FAKE_HOME_CODEX/.codex/log/probe.log" 2>/dev/null)" = "residu-log" ] \
    || { ko "T50 (CODEX-B5, résidu légitime) : log/probe.log altéré ou disparu après uninstall"; miss=1; }
  [ "$(cat "$FAKE_HOME_CODEX/.codex/tmp/arg0/probe" 2>/dev/null)" = "residu-tmp" ] \
    || { ko "T50 (CODEX-B5, résidu légitime) : tmp/arg0/probe altéré ou disparu après uninstall"; miss=1; }
  [ "$(cat "$FAKE_HOME_CODEX/.codex/models_cache.json" 2>/dev/null)" = "residu-models" ] \
    || { ko "T50 (CODEX-B5, résidu légitime) : models_cache.json altéré ou disparu après uninstall"; miss=1; }
  [ "$(cat "$FAKE_HOME_CODEX/.codex/memories_1.sqlite" 2>/dev/null)" = "residu-sqlite" ] \
    || { ko "T50 (CODEX-B5, résidu légitime) : memories_1.sqlite altéré ou disparu après uninstall"; miss=1; }

  [ "$miss" -eq 0 ] && ok "T50 (CODEX-B5) : uninstall --all retire les 9 rôles .toml (comm vide), résidus runtime Codex légitimes intacts"
else
  skip "T50 : dev-orchestrator/design-orchestrator non copiables dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# T51 (CODEX-B6, 38-07) — la coexistence sans hooks se déclare depuis le chemin RÉEL
# d'install/status, SANS pré-semage manuel de .planning/config.json (contrairement à T48, qui
# pré-sème le registre). Install d'un module à agent sous runtime codex détecté sur un lab
# .planning/config.json minimal ({}) -> install ET status contiennent la ligne
# [fidelity-coexistence]. Témoin anti-parasite : même scénario sous runtime claude -> AUCUNE
# ligne coexistence, ni à l'install ni au status.
# ---------------------------------------------------------------------------
LAB="$(mktemp -d)"
CACHE="$LAB/cache"
FAKE_HOME_CODEX="$LAB/home"
mkdir -p "$FAKE_HOME_CODEX"
if prepare_module "$CACHE" "conductor" && prepare_module "$CACHE" "validator"; then
  mkdir -p "$LAB/.planning"
  echo '{}' > "$LAB/.planning/config.json"
  miss=0
  INSTALL_OUT=$(cd "$LAB" && HOME="$FAKE_HOME_CODEX" VF_SCOPE=project VF_RUNTIME=codex VIBEFLOW_CACHE="$CACHE" \
    bash "$INSTALLER" install validator 2>&1)
  echo "$INSTALL_OUT" | "$GREP" -qF '[fidelity-coexistence] codex : opère SANS gouvernance de hooks' \
    || { ko "T51 (CODEX-B6) install : ligne [fidelity-coexistence] absente sans pré-semage — $INSTALL_OUT"; miss=1; }
  STATUS_OUT=$(cd "$LAB" && HOME="$FAKE_HOME_CODEX" VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" \
    bash "$INSTALLER" status 2>&1)
  echo "$STATUS_OUT" | "$GREP" -qF '[fidelity-coexistence] codex : opère SANS gouvernance de hooks' \
    || { ko "T51 (CODEX-B6) status : ligne [fidelity-coexistence] absente sans pré-semage — $STATUS_OUT"; miss=1; }
  "$GREP" -qF '"codex"' "$LAB/.planning/config.json" \
    || { ko "T51 (CODEX-B6) : .planning/config.json ne contient pas \"codex\" après l'install — $(cat "$LAB/.planning/config.json")"; miss=1; }
  [ "$miss" -eq 0 ] && ok "T51 (CODEX-B6) : coexistence déclarée à l'install ET au status sans pré-semage manuel du registre"
else
  skip "T51 : conductor/validator non copiables dans le cache de test"
fi
rm -rf "$LAB"

LAB="$(mktemp -d)"
CACHE="$LAB/cache"
FAKE_HOME_CLAUDE="$LAB/home"
mkdir -p "$FAKE_HOME_CLAUDE"
if prepare_module "$CACHE" "conductor" && prepare_module "$CACHE" "validator"; then
  mkdir -p "$LAB/.planning"
  echo '{}' > "$LAB/.planning/config.json"
  miss=0
  INSTALL_OUT=$(cd "$LAB" && HOME="$FAKE_HOME_CLAUDE" VF_SCOPE=project VF_RUNTIME=claude VIBEFLOW_CACHE="$CACHE" \
    bash "$INSTALLER" install validator 2>&1)
  [ "$(echo "$INSTALL_OUT" | "$GREP" -c 'coexistence')" -eq 0 ] \
    || { ko "T51 (CODEX-B6, témoin anti-parasite) install : ligne coexistence présente sous runtime claude — $INSTALL_OUT"; miss=1; }
  STATUS_OUT=$(cd "$LAB" && HOME="$FAKE_HOME_CLAUDE" VF_SCOPE=project VIBEFLOW_CACHE="$CACHE" \
    bash "$INSTALLER" status 2>&1)
  [ "$(echo "$STATUS_OUT" | "$GREP" -c 'coexistence')" -eq 0 ] \
    || { ko "T51 (CODEX-B6, témoin anti-parasite) status : ligne coexistence présente sous runtime claude — $STATUS_OUT"; miss=1; }
  [ "$miss" -eq 0 ] && ok "T51 (CODEX-B6, témoin anti-parasite) : aucune ligne coexistence sous runtime claude seul, à l'install ET au status"
else
  skip "T51 (témoin anti-parasite) : conductor/validator non copiables dans le cache de test"
fi
rm -rf "$LAB"

# ---------------------------------------------------------------------------
# Garde-fou final : le vrai ~/.claude ET le vrai ~/.codex/agents/vibeflow sont inchangés
# (snapshot récursif avant=après).
# ---------------------------------------------------------------------------
HOME_AFTER=$(snapshot_home_claude)
if [ "$HOME_BEFORE" = "$HOME_AFTER" ]; then
  ok "Garde-fou : ~/.claude intact ($HOME_AFTER fichiers dans les zones engine avant=après)"
else
  ko "Garde-fou : ~/.claude POLLUÉ (avant=$HOME_BEFORE, après=$HOME_AFTER — zones agents/skills/scripts/rules/commands/settings)"
fi

HOME_CODEX_AFTER=$(snapshot_home_codex)
if [ "$HOME_CODEX_BEFORE" = "$HOME_CODEX_AFTER" ]; then
  ok "Garde-fou : ~/.codex/agents/vibeflow intact ($HOME_CODEX_AFTER fichiers avant=après)"
else
  ko "Garde-fou : ~/.codex/agents/vibeflow POLLUÉ (avant=$HOME_CODEX_BEFORE, après=$HOME_CODEX_AFTER)"
fi

# ---------------------------------------------------------------------------
echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ]
