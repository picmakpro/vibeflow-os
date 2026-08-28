#!/usr/bin/env bash
# test-check-artifact-fidelity.sh — Suite du gate de fidélité de conversion (Phase 38, FIDE-01).
#
# check-artifact-fidelity.sh :
#   T1 — content-clarity-judge.md (fixture copiée, isolée) --target codex → les 4 pertes réelles
#        (model/memory/disallowedTools/vf-internal) + 1 dégradation (tools) mesurées par
#        exécution réelle de la conversion gsd-core.
#   T2 — gsd-core absent (HOME/CLAUDE_CONFIG_DIR de sonde sans gsd-core) → exit 3, stdout vide.
#   T3 — --json produit un JSON valide (node -e JSON.parse).
#   T4 — cible inconnue (--target opencode) → exit 3, message "non mesuré".
#   T5 — --target codex sans binaire `codex` sur un PATH de sonde restreint →
#        multi_agent_v2=non mesurable, jamais une valeur par défaut.
#   T6 — --target codex avec un CODEX_HOME de sonde sans bloc [projects."…"] pour la racine
#        testée → trust_level=absent (non trusted), et la ligne [fidelity-recette] précède la
#        ligne [fidelity] dans le flux capturé.
#
# Convention : asserts numérotés, helpers ok()/ko()/skip(), exit 0 si tout passe (SKIP non
# bloquant), exit 1 si au moins un KO. Calqué sur le pattern de test-vibeflow-update.sh.
set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(cd "$TESTS_DIR/.." && pwd)"
GATE="$SCRIPTS_DIR/check-artifact-fidelity.sh"
REPO="$(cd "$SCRIPTS_DIR/../../.." && pwd)"
FIXTURE_SRC="$REPO/plugin/content-bundle/agents/content-clarity-judge.md"

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

echo "== test-check-artifact-fidelity (gate: $GATE) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Résout, comme le gate, le home gsd-core réellement présent sur ce poste — la suite ne
# recopie jamais son chemin en dur.
REAL_GSD_HOME=""
if [ -d "$REPO/.claude/gsd-core" ]; then
  REAL_GSD_HOME="$REPO/.claude/gsd-core"
elif [ -f "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core/VERSION" ]; then
  REAL_GSD_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core"
fi

if [ ! -f "$GATE" ]; then
  ko "T0 : gate introuvable à $GATE"
  echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
  exit 1
fi
if [ ! -x "$GATE" ]; then
  ko "T0 : gate non exécutable ($GATE)"
else
  ok "T0 : gate présent et exécutable"
fi

if [ -z "$REAL_GSD_HOME" ] || [ ! -f "$FIXTURE_SRC" ]; then
  skip "T1-T6 : gsd-core ou fixture introuvables sur ce poste (REAL_GSD_HOME='$REAL_GSD_HOME', fixture='$FIXTURE_SRC')"
  echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
  [ "$fail" -eq 0 ]
  exit $?
fi

# Fixture isolée : copie de content-clarity-judge.md dans le WORK (jamais l'artefact source
# du dépôt, pour rester en lecture seule sur le dépôt).
FIXTURE="$WORK/content-clarity-judge.md"
cp "$FIXTURE_SRC" "$FIXTURE"

# ---------------------------------------------------------------------------
# T1 — les 4 pertes réelles + 1 dégradation, mesurées (pas recopiées en dur avant exécution).
# ---------------------------------------------------------------------------
T1_OUT="$(cd "$REPO" && bash "$GATE" --target codex "$FIXTURE" 2>"$WORK/t1.err")"
T1_RC=$?

if [ "$T1_RC" -eq 0 ]; then
  ok "T1.rc : exit 0 (mesure exécutée)"
else
  ko "T1.rc : attendu exit 0, obtenu $T1_RC (stderr: $(cat "$WORK/t1.err"))"
fi

FIDELITY_LINE="$(printf '%s\n' "$T1_OUT" | grep '^\[fidelity\]')"
if [ -n "$FIDELITY_LINE" ]; then
  ok "T1.ligne : [fidelity] présente"
else
  ko "T1.ligne : [fidelity] absente de la sortie ($T1_OUT)"
fi

for champ in model disallowedTools vf-internal; do
  if printf '%s\n' "$FIDELITY_LINE" | grep -q "LOST={[^}]*\b${champ}\b"; then
    ok "T1.LOST : $champ dans LOST="
  else
    ko "T1.LOST : $champ absent de LOST= (ligne: $FIDELITY_LINE)"
  fi
done
if printf '%s\n' "$FIDELITY_LINE" | grep -q "LOST={[^}]*\bmemory\b"; then
  ok "T1.LOST : memory dans LOST="
else
  ko "T1.LOST : memory absent de LOST= (ligne: $FIDELITY_LINE)"
fi

if printf '%s\n' "$FIDELITY_LINE" | grep -q "DEGRADED={[^}]*\btools\b"; then
  ok "T1.DEGRADED : tools dans DEGRADED="
else
  ko "T1.DEGRADED : tools absent de DEGRADED= (ligne: $FIDELITY_LINE)"
fi

if printf '%s\n' "$FIDELITY_LINE" | grep -q "PRESERVED={[^}]*\bname\b" \
  && printf '%s\n' "$FIDELITY_LINE" | grep -q "PRESERVED={[^}]*\bdescription\b"; then
  ok "T1.PRESERVED : name et description préservés (model étant LOST, sur la MÊME exécution)"
else
  ko "T1.PRESERVED : name/description absents de PRESERVED= (ligne: $FIDELITY_LINE)"
fi

# ---------------------------------------------------------------------------
# T2 — gsd-core absent : exit 3, stdout vide.
# ---------------------------------------------------------------------------
SONDE_HOME="$WORK/sonde-no-gsd-core"
mkdir -p "$SONDE_HOME"
T2_OUT="$(HOME="$SONDE_HOME" CLAUDE_CONFIG_DIR="$SONDE_HOME/.claude" bash "$GATE" --target codex "$FIXTURE" 2>/dev/null)"
T2_RC=$?
if [ "$T2_RC" -eq 3 ]; then
  ok "T2.rc : gsd-core absent → exit 3"
else
  ko "T2.rc : attendu exit 3, obtenu $T2_RC"
fi
if [ -z "$T2_OUT" ]; then
  ok "T2.stdout : vide"
else
  ko "T2.stdout : non vide ('$T2_OUT')"
fi

# ---------------------------------------------------------------------------
# T3 — --json produit un JSON valide.
# ---------------------------------------------------------------------------
if (cd "$REPO" && bash "$GATE" --target codex --json "$FIXTURE" 2>"$WORK/t3.err" \
    | node -e "JSON.parse(require('fs').readFileSync(0,'utf8'))" >/dev/null 2>&1); then
  ok "T3 : --json parse (node JSON.parse)"
else
  ko "T3 : --json ne parse pas (stderr gate: $(cat "$WORK/t3.err" 2>/dev/null))"
fi

# ---------------------------------------------------------------------------
# T4 — cible inconnue → exit 3, stdout VIDE (contrat de l'en-tête, l. 22-28), message
# "non mesuré" sur stderr (jamais stdout : un consommateur de stdout ne doit rien voir).
# ---------------------------------------------------------------------------
T4_OUT="$(cd "$REPO" && bash "$GATE" --target opencode "$FIXTURE" 2>"$WORK/t4.err")"
T4_RC=$?
T4_ERR="$(cat "$WORK/t4.err" 2>/dev/null)"
if [ "$T4_RC" -eq 3 ]; then
  ok "T4.rc : cible inconnue → exit 3"
else
  ko "T4.rc : attendu exit 3, obtenu $T4_RC"
fi
if [ -z "$T4_OUT" ]; then
  ok "T4.stdout : vide (contrat de l'en-tête)"
else
  ko "T4.stdout : non vide ('$T4_OUT')"
fi
if printf '%s' "$T4_ERR" | grep -q "non mesuré"; then
  ok "T4.stderr : 'non mesuré' présent sur stderr"
else
  ko "T4.stderr : 'non mesuré' absent ('$T4_ERR')"
fi

# ---------------------------------------------------------------------------
# T5 — PATH de sonde sans `codex` → multi_agent_v2=non mesurable.
# ---------------------------------------------------------------------------
NODE_BIN="$(command -v node || true)"
if [ -z "$NODE_BIN" ]; then
  skip "T5 : node introuvable sur le PATH courant, impossible de construire un PATH de sonde"
else
  SONDE_BIN="$WORK/sonde-bin"
  mkdir -p "$SONDE_BIN"
  ln -sf "$NODE_BIN" "$SONDE_BIN/node"
  T5_OUT="$(cd "$REPO" && env -i PATH="$SONDE_BIN:/usr/bin:/bin" HOME="$HOME" \
    CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-}" bash "$GATE" --target codex "$FIXTURE" 2>"$WORK/t5.err")"
  T5_RC=$?
  if [ "$T5_RC" -eq 0 ] && printf '%s' "$T5_OUT" | grep -q "multi_agent_v2=non mesurable"; then
    ok "T5 : codex absent du PATH → multi_agent_v2=non mesurable (jamais une valeur par défaut)"
  else
    ko "T5 : attendu 'multi_agent_v2=non mesurable', obtenu rc=$T5_RC sortie='$T5_OUT' (stderr: $(cat "$WORK/t5.err" 2>/dev/null))"
  fi
fi

# ---------------------------------------------------------------------------
# T6 — CODEX_HOME de sonde sans bloc [projects."…"] → trust_level=absent (non trusted),
# et [fidelity-recette] précède [fidelity] dans le flux capturé.
# ---------------------------------------------------------------------------
SONDE_CODEX_HOME="$WORK/sonde-codex-home"
mkdir -p "$SONDE_CODEX_HOME"
{
  echo '[projects."/some/other/repo/never/matches"]'
  echo 'trust_level = "trusted"'
} > "$SONDE_CODEX_HOME/config.toml"

T6_OUT="$(cd "$REPO" && CODEX_HOME="$SONDE_CODEX_HOME" bash "$GATE" --target codex "$FIXTURE" 2>"$WORK/t6.err")"
T6_RC=$?
if [ "$T6_RC" -eq 0 ] && printf '%s' "$T6_OUT" | grep -q "trust_level=absent (non trusted)"; then
  ok "T6.trust_level : bloc [projects.…] non concordant → absent (non trusted)"
else
  ko "T6.trust_level : attendu 'trust_level=absent (non trusted)', obtenu rc=$T6_RC sortie='$T6_OUT' (stderr: $(cat "$WORK/t6.err" 2>/dev/null))"
fi

RECETTE_LINE_NO="$(printf '%s\n' "$T6_OUT" | grep -n '^\[fidelity-recette\]' | head -1 | cut -d: -f1)"
FIDELITY_LINE_NO="$(printf '%s\n' "$T6_OUT" | grep -n '^\[fidelity\]' | head -1 | cut -d: -f1)"
if [ -n "$RECETTE_LINE_NO" ] && [ -n "$FIDELITY_LINE_NO" ] && [ "$RECETTE_LINE_NO" -lt "$FIDELITY_LINE_NO" ]; then
  ok "T6.ordre : [fidelity-recette] précède [fidelity] dans le flux capturé"
else
  ko "T6.ordre : ordre inattendu (recette=$RECETTE_LINE_NO, fidelity=$FIDELITY_LINE_NO, sortie='$T6_OUT')"
fi

# ---------------------------------------------------------------------------
# T7 — count_markers() compte des OCCURRENCES, pas des lignes : une ligne portant DEUX
# marqueurs (deux `.claude/`) doit valoir 2, pas 1 (défaut : `grep -c` compterait la ligne
# une seule fois). Fonction extraite du gate lui-même (jamais recopiée à la main) et exécutée
# isolément — la sonde décisive est la ligne à deux occurrences.
# ---------------------------------------------------------------------------
COUNT_MARKERS_SRC="$(sed -n '/^count_markers() {/,/^}/p' "$GATE")"
if [ -z "$COUNT_MARKERS_SRC" ]; then
  ko "T7 : count_markers() introuvable dans $GATE (extraction vide)"
else
  T7_RESULT="$(bash -c "$COUNT_MARKERS_SRC"'
count_markers "Voir .claude/agents/foo.md et aussi .claude/skills/bar pour Task( details"')"
  if [ "$T7_RESULT" -eq 3 ]; then
    ok "T7 : ligne à 2x '.claude/' + 1x 'Task(' → 3 occurrences (pas 2 lignes)"
  else
    ko "T7 : attendu 3 occurrences sur la ligne à marqueurs multiples, obtenu '$T7_RESULT'"
  fi
fi

# ---------------------------------------------------------------------------
echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ]
