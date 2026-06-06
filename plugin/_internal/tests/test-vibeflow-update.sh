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

# Snapshot RÉCURSIF du vrai ~/.claude AVANT la suite (garde-fou anti-pollution).
HOME_BEFORE=$(find "$HOME/.claude" -type f 2>/dev/null | wc -l | tr -d ' ')

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
  # Rétro-compat references D7 (au moins les 3 references canoniques).
  for ref in GSD-PIPELINE.md gsd-skills-index.md vocabulary-map.md; do
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
CLOSURE="validator consolidator infrastructure-audit"
copy_ok=1
for m in $CLOSURE; do
  prepare_module "$CACHE" "$m" || { copy_ok=0; break; }
  [ -f "$CACHE/$m/module.json" ] || { copy_ok=0; break; }
done
if [ "$copy_ok" -eq 0 ]; then
  skip "T5 résolveur : module.json de validator/consolidator/infrastructure-audit non copiables"
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
  [ "$miss" -eq 0 ] \
    && ok "T5 résolveur : --with-deps validator installe la fermeture {validator, consolidator, infrastructure-audit} (résolveur RÉELLEMENT exercé)"
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
# Garde-fou final : le vrai ~/.claude est inchangé (snapshot récursif avant=après).
# ---------------------------------------------------------------------------
HOME_AFTER=$(find "$HOME/.claude" -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$HOME_BEFORE" = "$HOME_AFTER" ]; then
  ok "Garde-fou : ~/.claude intact ($HOME_AFTER fichiers récursifs avant=après)"
else
  ko "Garde-fou : ~/.claude POLLUÉ (avant=$HOME_BEFORE, après=$HOME_AFTER)"
fi

# ---------------------------------------------------------------------------
echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ]
