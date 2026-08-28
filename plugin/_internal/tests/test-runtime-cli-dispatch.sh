#!/usr/bin/env bash
# test-runtime-cli-dispatch.sh — Suite dédiée de plugin/_internal/runtime-cli-dispatch.sh
# (RUNT-01/RUNT-02, plan 38-02).
#
# Couvre :
#   T1 — VF_RUNTIME=claude + faux binaire claude en fixture PATH → la commande construite/
#        exécutée contient EXACTEMENT `plugin install foo@bar --scope user` (capturée par
#        exécution réelle, jamais recopiée en dur).
#   T2 — VF_RUNTIME=codex + faux binaire codex → commande équivalente construite pour
#        `codex plugin install ...` (même forme d'arguments).
#   T3 — VF_RUNTIME=opencode, AUCUN binaire réel requis → message d'étape manuelle sur stderr,
#        exit 0, AUCUNE tentative d'exécution d'un binaire absent.
#   T4 — aucun VF_RUNTIME, PATH de sonde vide → détection rend « absent », même comportement
#        que T3 (dégradation déclarée, pas un crash).
#   T5..T7 — précondition Codex (RUNT-01 étendu, tâche 3) : multi_agent_v2 posé si inactif,
#        idempotent si déjà actif, trust_level jamais auto-écrit (config.toml byte-identique).
#
# Convention : asserts numérotés, helpers ok()/ko()/skip(), isolation mktemp -d + trap, exit 0
# si tout passe (SKIP non bloquant), exit 1 si au moins un KO.

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
INTERNAL_DIR="$(cd "$TESTS_DIR/.." && pwd)"
DISPATCH="$INTERNAL_DIR/runtime-cli-dispatch.sh"

pass=0; fail=0; skipped=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
skip() { echo "  ⊘ SKIP $1"; skipped=$((skipped+1)); }

echo "== test-runtime-cli-dispatch (dispatch: $DISPATCH) =="

[ -x "$DISPATCH" ] && ok "runtime-cli-dispatch.sh est exécutable" \
  || { ko "runtime-cli-dispatch.sh introuvable ou non exécutable"; echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="; exit 1; }

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

# ---------------------------------------------------------------------------
# T1 — VF_RUNTIME=claude, faux binaire claude qui journalise ses arguments.
# ---------------------------------------------------------------------------
FIX1="$WORKDIR/fix1"
mkdir -p "$FIX1"
LOG1="$WORKDIR/log1.txt"
cat > "$FIX1/claude" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$LOG1"
exit 0
EOF
chmod +x "$FIX1/claude"
: > "$LOG1"
OUT1=$(PATH="$FIX1:$PATH" VF_RUNTIME=claude bash "$DISPATCH" install foo@bar --scope user 2>&1)
EXIT1=$?
if [ "$EXIT1" -eq 0 ] && grep -qF 'plugin install foo@bar --scope user' "$LOG1"; then
  ok "T1 : VF_RUNTIME=claude → 'plugin install foo@bar --scope user' exécuté réellement (journal grep)"
else
  ko "T1 : commande claude non conforme (exit=$EXIT1, journal='$(cat "$LOG1" 2>/dev/null)', out='$OUT1')"
fi

# ---------------------------------------------------------------------------
# T2 — VF_RUNTIME=codex, faux binaire codex, MÊME forme d'arguments.
# ---------------------------------------------------------------------------
FIX2="$WORKDIR/fix2"
mkdir -p "$FIX2"
LOG2="$WORKDIR/log2.txt"
cat > "$FIX2/codex" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$LOG2"
exit 0
EOF
chmod +x "$FIX2/codex"
: > "$LOG2"
OUT2=$(PATH="$FIX2:$PATH" VF_RUNTIME=codex bash "$DISPATCH" install foo@bar --scope user 2>&1)
EXIT2=$?
if [ "$EXIT2" -eq 0 ] && grep -qF 'plugin install foo@bar --scope user' "$LOG2"; then
  ok "T2 : VF_RUNTIME=codex → 'plugin install foo@bar --scope user' exécuté réellement sur codex (journal grep)"
else
  ko "T2 : commande codex non conforme (exit=$EXIT2, journal='$(cat "$LOG2" 2>/dev/null)', out='$OUT2')"
fi

# enable, sur les deux runtimes — non-régression de la grammaire pour le 2e verbe actionnable.
: > "$LOG1"
PATH="$FIX1:$PATH" VF_RUNTIME=claude bash "$DISPATCH" enable foo@bar --scope user >/dev/null 2>&1
grep -qF 'plugin enable foo@bar --scope user' "$LOG1" \
  && ok "T2b : verbe 'enable' routé identiquement sur claude" \
  || ko "T2b : verbe 'enable' non routé sur claude (journal='$(cat "$LOG1" 2>/dev/null)')"

: > "$LOG2"
PATH="$FIX2:$PATH" VF_RUNTIME=codex bash "$DISPATCH" enable foo@bar --scope user >/dev/null 2>&1
grep -qF 'plugin enable foo@bar --scope user' "$LOG2" \
  && ok "T2c : verbe 'enable' routé identiquement sur codex" \
  || ko "T2c : verbe 'enable' non routé sur codex (journal='$(cat "$LOG2" 2>/dev/null)')"

# ---------------------------------------------------------------------------
# T3 — VF_RUNTIME=opencode, AUCUN binaire réel requis (PATH de sonde vide).
# ---------------------------------------------------------------------------
EMPTY_PATH_DIR="$WORKDIR/empty-path"
mkdir -p "$EMPTY_PATH_DIR"
OUT3=$(PATH="$EMPTY_PATH_DIR" VF_RUNTIME=opencode /bin/bash "$DISPATCH" install foo@bar --scope user 2>&1)
EXIT3=$?
if [ "$EXIT3" -eq 0 ] && printf '%s' "$OUT3" | grep -qi 'étape manuelle'; then
  ok "T3 : VF_RUNTIME=opencode, PATH vide → exit 0 + message d'étape manuelle, aucun binaire invoqué"
else
  ko "T3 : dégradation opencode non conforme (exit=$EXIT3, out='$OUT3')"
fi

# ---------------------------------------------------------------------------
# T4 — aucun VF_RUNTIME, PATH de sonde vide → détection rend « absent ».
# ---------------------------------------------------------------------------
DETECT4=$(env -u VF_RUNTIME PATH="$EMPTY_PATH_DIR" /bin/bash "$DISPATCH" detect 2>&1)
EXIT4D=$?
[ "$EXIT4D" -eq 0 ] && [ -z "$DETECT4" ] \
  && ok "T4a : détection sans VF_RUNTIME + PATH vide → chaîne vide (« absent »)" \
  || ko "T4a : détection non conforme (exit=$EXIT4D, sortie='$DETECT4')"

OUT4=$(env -u VF_RUNTIME PATH="$EMPTY_PATH_DIR" /bin/bash "$DISPATCH" install foo@bar --scope user 2>&1)
EXIT4=$?
if [ "$EXIT4" -eq 0 ] && printf '%s' "$OUT4" | grep -qi 'étape manuelle'; then
  ok "T4b : runtime absent → même dégradation déclarée que T3 (exit 0, message)"
else
  ko "T4b : dégradation runtime-absent non conforme (exit=$EXIT4, out='$OUT4')"
fi

# ---------------------------------------------------------------------------
# T5 — précondition Codex : multi_agent_v2 inactif → 'features enable multi_agent_v2' appelé.
# ---------------------------------------------------------------------------
FIX5="$WORKDIR/fix5"
mkdir -p "$FIX5"
LOG5="$WORKDIR/log5.txt"
cat > "$FIX5/codex" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$LOG5"
if [ "\$1" = "features" ] && [ "\$2" = "list" ]; then
  echo "multi_agent_v2                           stable             false"
  exit 0
fi
exit 0
EOF
chmod +x "$FIX5/codex"
CODEX_HOME5="$WORKDIR/codex-home-5"
mkdir -p "$CODEX_HOME5"
: > "$LOG5"
PATH="$FIX5:$PATH" VF_RUNTIME=codex CODEX_HOME="$CODEX_HOME5" bash "$DISPATCH" ensure-codex-preconditions >/dev/null 2>&1
grep -qF 'features enable multi_agent_v2' "$LOG5" \
  && ok "T5 : multi_agent_v2 inactif → 'codex features enable multi_agent_v2' appelé (journal grep)" \
  || ko "T5 : activation manquante (journal='$(cat "$LOG5" 2>/dev/null)')"

# ---------------------------------------------------------------------------
# T6 — précondition Codex : multi_agent_v2 déjà actif → AUCUN appel 'enable' (idempotent).
# ---------------------------------------------------------------------------
FIX6="$WORKDIR/fix6"
mkdir -p "$FIX6"
LOG6="$WORKDIR/log6.txt"
cat > "$FIX6/codex" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$LOG6"
if [ "\$1" = "features" ] && [ "\$2" = "list" ]; then
  echo "multi_agent_v2                           stable             true"
  exit 0
fi
exit 0
EOF
chmod +x "$FIX6/codex"
CODEX_HOME6="$WORKDIR/codex-home-6"
mkdir -p "$CODEX_HOME6"
: > "$LOG6"
PATH="$FIX6:$PATH" VF_RUNTIME=codex CODEX_HOME="$CODEX_HOME6" bash "$DISPATCH" ensure-codex-preconditions >/dev/null 2>&1
if grep -qF 'features enable' "$LOG6"; then
  ko "T6 : idempotence violée — 'enable' appelé alors que multi_agent_v2 était déjà actif (journal='$(cat "$LOG6")')"
else
  ok "T6 : multi_agent_v2 déjà actif → aucun appel 'enable' (idempotent)"
fi

# ---------------------------------------------------------------------------
# T7 — précondition Codex : trust_level absent → config.toml JAMAIS écrit (sha256 identique).
# ---------------------------------------------------------------------------
FIX7="$WORKDIR/fix7"
mkdir -p "$FIX7"
cat > "$FIX7/codex" <<EOF
#!/usr/bin/env bash
if [ "\$1" = "features" ] && [ "\$2" = "list" ]; then
  echo "multi_agent_v2                           stable             true"
  exit 0
fi
exit 0
EOF
chmod +x "$FIX7/codex"
CODEX_HOME7="$WORKDIR/codex-home-7"
mkdir -p "$CODEX_HOME7"
echo "# aucun bloc [projects...] pour ce dépôt" > "$CODEX_HOME7/config.toml"
SUM_BEFORE=$(command shasum -a 256 "$CODEX_HOME7/config.toml" 2>/dev/null | awk '{print $1}')
OUT7=$(PATH="$FIX7:$PATH" VF_RUNTIME=codex CODEX_HOME="$CODEX_HOME7" bash "$DISPATCH" ensure-codex-preconditions 2>&1)
SUM_AFTER=$(command shasum -a 256 "$CODEX_HOME7/config.toml" 2>/dev/null | awk '{print $1}')
if [ "$SUM_BEFORE" = "$SUM_AFTER" ] && printf '%s' "$OUT7" | grep -qi 'trust_level non confirmé'; then
  ok "T7 : trust_level absent → config.toml byte-identique (sha256 avant=après) + message de déclaration"
else
  ko "T7 : écriture suspectée ou message absent (before=$SUM_BEFORE after=$SUM_AFTER out='$OUT7')"
fi

# ---------------------------------------------------------------------------
echo "== résultat : $pass OK / $fail KO / $skipped SKIP =="
[ "$fail" -eq 0 ]
