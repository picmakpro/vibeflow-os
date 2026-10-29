#!/usr/bin/env bash
# test-audit-infra.sh — Suite de audit-infra.sh (fiabilisation INF-01/02/04/05).
#
# T1 — INF-01 : --quick pose le stamp .last-audit
# T2 — INF-01 : --quick --if-older-than=14d avec stamp frais → skip (aucun JSON injecté)
# T3 — INF-04 : --if-older-than=2w (malformé) → pas de "integer expression" sur stderr,
#               gate ignoré silencieusement et audit exécuté (fail-open)
# T4 — INF-02 : settings.json avec script manquant + event inconnu → errors_count/warnings_count
#               alimentés + détections formatées dans le JSON, aucune fuite brute ERR|/WARN|
# T5 — INF-05 : version listée → known ; plus récente que la dernière validée → known + note ;
#               ancienne non listée → false
# T6 — INF-05 : la whitelist couvre bien 2.1.215
# T7-T9 — VG-5 : --strict (exit 3 sans cible, exit 1 sur ERROR, exit 0 sur lab propre)
# T10 — contrat de flux sous --hook (HOOKS-CONTRAT-SORTIE.md §3)
# T11 — #153 §3 : forme "$CLAUDE_PROJECT_DIR"/x.sh ; T12 — #153 §6.7 : CR retirés du JSON (Windows)
# T13 — #153 §6.4 : événements connus (SubagentStop, FileChanged)
# T14 — #153 §6.3 : --no-tests / VF_SKIP_TESTS=1 ; T15 — --strict + suites sautées → exit 3
# T16 — #153 : --strict + saut SANS suite découverte (pas de tests/, tests/ vide de test-*.sh) → verdict normal

set -uo pipefail

# Herméticité : un VF_SKIP_TESTS hérité de l'appelant (README, Git Bash) fausserait les cas qui
# attendent des suites exécutées ; les cas qui le veulent le posent eux-mêmes (env VF_SKIP_TESTS=1).
unset VF_SKIP_TESTS

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$TESTS_DIR/.." && pwd)/audit-infra.sh"
SRC_KNOWN="$(cd "$TESTS_DIR/.." && pwd)/known-versions.txt"
# Exécuter le script avec le bash qui exécute la suite (/bin/bash → validation 3.2 réelle).
BASH_BIN="${BASH:-bash}"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-audit-infra (script: $SCRIPT) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Lab propre (T1-T3, T5) + lab avec settings cassé (T4). Le script se lance depuis le
# lab (CLAUDE_DIR par défaut .claude, chemins de hooks relatifs au lab).
LAB="$WORK/lab"
LAB_ERR="$WORK/lab-err"
mkdir -p "$LAB/.claude/scripts" "$LAB_ERR/.claude/scripts"
cp "$SRC_KNOWN" "$LAB/.claude/scripts/known-versions.txt"

# Faux binaire claude (version pilotée par FAKE_CLAUDE_VERSION) pour l'axe runtime.
mkdir -p "$WORK/bin"
cat > "$WORK/bin/claude" <<'SH'
#!/bin/sh
echo "${FAKE_CLAUDE_VERSION:-2.1.215} (Claude Code)"
SH
chmod +x "$WORK/bin/claude"

run_in() { # run_in <labdir> [env VAR=x ...] -- args...
  local lab="$1"; shift
  (cd "$lab" && "$@")
}

# T1 — --quick pose le stamp
run_in "$LAB" "$BASH_BIN" "$SCRIPT" --quick >/dev/null 2>&1
if [ -f "$LAB/.claude/.last-audit" ]; then
  ok "T1 INF-01 : --quick pose le stamp .claude/.last-audit"
else
  ko "T1 stamp absent après --quick"
fi

# T2 — gate d'âge : stamp frais → skip, rien sur stdout
OUT="$(run_in "$LAB" "$BASH_BIN" "$SCRIPT" --quick --if-older-than=14d 2>"$WORK/t2.err")"
if [ -z "$OUT" ] && grep -q "skip" "$WORK/t2.err"; then
  ok "T2 INF-01 : stamp frais → skip (aucune injection stdout au SessionStart)"
else
  ko "T2 skip attendu (out='$OUT', err=$(cat "$WORK/t2.err" 2>/dev/null))"
fi

# T3 — valeur malformée (2w) : silencieux sur l'erreur, audit exécuté quand même
rm -f "$LAB/.claude/.last-audit" "$LAB/.claude/INFRASTRUCTURE_SNAPSHOT.md"
OUT="$(run_in "$LAB" "$BASH_BIN" "$SCRIPT" --quick --if-older-than=2w 2>"$WORK/t3.err")"
if grep -q "integer expression" "$WORK/t3.err"; then
  ko "T3 INF-04 : 'integer expression expected' fuit encore sur stderr"
elif echo "$OUT" | grep -q '"axis": "runtime"'; then
  ok "T3 INF-04 : --if-older-than=2w → gate ignoré proprement, audit exécuté"
else
  ko "T3 audit attendu malgré la valeur malformée (out='$OUT')"
fi

# T4 — comptage + formatage des détections hooks
cat > "$LAB_ERR/.claude/settings.json" <<'JSON'
{
  "hooks": {
    "SessionStart": [
      { "matcher": "startup", "hooks": [ { "type": "command", "command": "bash .claude/scripts/fantome.sh --quick" } ] }
    ],
    "EventInconnu": [
      { "hooks": [ { "type": "command", "command": "echo ok" } ] }
    ]
  }
}
JSON
OUT="$(run_in "$LAB_ERR" "$BASH_BIN" "$SCRIPT" --axis=hooks 2>/dev/null)"
T4_OK=1
echo "$OUT" | grep -q '"errors_count": 1' || { T4_OK=0; ko "T4 INF-02 : errors_count devrait valoir 1 (script manquant), sortie : $OUT"; }
echo "$OUT" | grep -q '"warnings_count": 1' || { T4_OK=0; ko "T4 INF-02 : warnings_count devrait valoir 1 (event inconnu)"; }
echo "$OUT" | grep -q 'script_missing' || { T4_OK=0; ko "T4 INF-02 : la détection script_missing devrait figurer dans le JSON"; }
if echo "$OUT" | grep -Eq '^(ERR|WARN)\|'; then
  T4_OK=0; ko "T4 INF-02 : des lignes brutes ERR|/WARN| fuient encore sur stdout"
fi
[ "$T4_OK" -eq 1 ] && ok "T4 INF-02 : détections comptées + formatées dans le JSON, pas de fuite brute"

# T5 — axe runtime : version listée / plus récente / ancienne inconnue
OUT="$(run_in "$LAB" env PATH="$WORK/bin:$PATH" FAKE_CLAUDE_VERSION=2.1.215 "$BASH_BIN" "$SCRIPT" --axis=runtime 2>/dev/null)"
if echo "$OUT" | grep -q '"version_known": true' && echo "$OUT" | grep -q '"version_note": ""'; then
  ok "T5a INF-05 : version listée (2.1.215) → known, sans note"
else
  ko "T5a known attendu pour 2.1.215, sortie : $OUT"
fi
OUT="$(run_in "$LAB" env PATH="$WORK/bin:$PATH" FAKE_CLAUDE_VERSION=2.1.999 "$BASH_BIN" "$SCRIPT" --axis=runtime 2>/dev/null)"
if echo "$OUT" | grep -q '"version_known": true' && echo "$OUT" | grep -q 'supposee compatible'; then
  ok "T5b INF-05 : version plus récente que la dernière validée → known + note explicite"
else
  ko "T5b known+note attendus pour 2.1.999, sortie : $OUT"
fi
OUT="$(run_in "$LAB" env PATH="$WORK/bin:$PATH" FAKE_CLAUDE_VERSION=1.0.0 "$BASH_BIN" "$SCRIPT" --axis=runtime 2>/dev/null)"
if echo "$OUT" | grep -q '"version_known": false'; then
  ok "T5c INF-05 : version ancienne non listée → false (pas de faux positif)"
else
  ko "T5c false attendu pour 1.0.0, sortie : $OUT"
fi

# T6 — la whitelist couvre le runtime récent
if grep -q '^2\.1\.215$' "$SRC_KNOWN"; then
  ok "T6 INF-05 : known-versions.txt couvre 2.1.215"
else
  ko "T6 whitelist toujours périmée (2.1.215 absent)"
fi

# T6b — #166/#153 : la version installée (2.1.312) est LISTÉE, pas seulement « supposée compatible »
# (version_note vide : la liste ne retarde plus de 97 versions sur le poste de référence).
OUT="$(run_in "$LAB" env PATH="$WORK/bin:$PATH" FAKE_CLAUDE_VERSION=2.1.312 "$BASH_BIN" "$SCRIPT" --axis=runtime 2>/dev/null)"
if echo "$OUT" | grep -q '"version_known": true' && echo "$OUT" | grep -q '"version_note": ""'; then
  ok "T6b #153 : 2.1.312 listée → known, version_note vide"
else
  ko "T6b 2.1.312 : known=true et version_note vide attendus, sortie : $OUT"
fi
for v in 2.1.296 2.1.300 2.1.301 2.1.311 2.1.312; do
  grep -qx "$v" "$SRC_KNOWN" && ok "T6c #153 : known-versions.txt couvre $v" || ko "T6c $v absent de known-versions.txt"
done

# T7 — VG-5 (F13) : --strict sans .claude → exit 3 (INDÉTERMINÉ, plus de JSON à zéro en vert)
EMPTY="$WORK/no-lab"; mkdir -p "$EMPTY"
run_in "$EMPTY" "$BASH_BIN" "$SCRIPT" --strict --quick >/dev/null 2>&1
rc=$?
[ "$rc" -eq 3 ] && ok "T7 VG-5 : --strict + .claude absent → exit 3 INDÉTERMINÉ" || ko "T7 --strict sans cible devrait sortir 3, obtenu rc=$rc"

# T8 — VG-5 : --strict avec finding ERROR (script de hook manquant) → exit 1
run_in "$LAB_ERR" "$BASH_BIN" "$SCRIPT" --strict --axis=hooks >/dev/null 2>&1
rc=$?
[ "$rc" -eq 1 ] && ok "T8 VG-5 : --strict + ERROR hooks → exit 1 (le finding porte enfin un exit code)" || ko "T8 --strict avec ERROR devrait sortir 1, obtenu rc=$rc"

# T9 — VG-5 : --strict sur lab propre → exit 0 ; défaut (sans --strict) sur lab cassé → exit 0 (compat)
run_in "$LAB" "$BASH_BIN" "$SCRIPT" --strict --axis=hooks >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && ok "T9a VG-5 : --strict sur lab propre → exit 0" || ko "T9a lab propre devrait sortir 0 en strict, obtenu rc=$rc"
run_in "$LAB_ERR" "$BASH_BIN" "$SCRIPT" --axis=hooks >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && ok "T9b VG-5 : défaut (advisory) inchangé → exit 0 même avec ERROR" || ko "T9b advisory devrait rester 0, obtenu rc=$rc"

# T10 — CONTRAT DE FLUX sous --hook (HOOKS-CONTRAT-SORTIE.md §3 et §3 bis).
# Régression d'origine : chaque axe émet SON objet JSON, donc --quick en émettait DEUX collés.
# `jq` acceptait (il lit un flux), le harness non — d'où « looks like a JSON object but is not
# valid JSON » au SessionStart. On valide donc en parseur de DOCUMENT (json.loads), pas en jq.
# verdict_stdout : rend "VIDE", "VALIDE" ou "INVALIDE" pour un stdout de hook donné.
verdict_stdout() {
  python3 -c '
import json, sys
raw = sys.stdin.read()
if raw.strip() == "":
    print("VIDE")
elif not raw.lstrip().startswith("{"):
    print("NON-JSON")
else:
    try:
        json.loads(raw)
        print("VALIDE")
    except ValueError:
        print("INVALIDE")
' 2>/dev/null
}

# T10a — findings présents (lab cassé) → UN SEUL objet JSON, valide au parseur strict.
OUT="$(run_in "$LAB_ERR" "$BASH_BIN" "$SCRIPT" --quick --hook 2>/dev/null)"
V="$(printf '%s' "$OUT" | verdict_stdout)"
if [ "$V" = "VALIDE" ] && printf '%s' "$OUT" | grep -q '"systemMessage"'; then
  ok "T10a §3bis : --quick --hook avec findings → UN document JSON valide (systemMessage)"
else
  ko "T10a stdout de hook non valide en parseur strict (verdict=$V), sortie : $OUT"
fi

# T10b — lab propre et version connue → stdout STRICTEMENT vide (silence du chemin nominal).
OUT="$(run_in "$LAB" env PATH="$WORK/bin:$PATH" FAKE_CLAUDE_VERSION=2.1.215 "$BASH_BIN" "$SCRIPT" --quick --hook 2>/dev/null)"
V="$(printf '%s' "$OUT" | verdict_stdout)"
[ "$V" = "VIDE" ] && ok "T10b §3 : lab propre → stdout strictement vide sous --hook" \
  || ko "T10b le chemin nominal doit être muet (verdict=$V), sortie : $OUT"

# T10c — INF-05 : sans known-versions.txt, version_known=false ne signifie PAS drift (rien pour
# comparer). Le bandeau doit se taire, sinon il crie une alerte non actionnable à chaque audit.
NOREF="$WORK/lab-noref"; mkdir -p "$NOREF/.claude/scripts"
OUT="$(run_in "$NOREF" env PATH="$WORK/bin:$PATH" FAKE_CLAUDE_VERSION=9.9.9 "$BASH_BIN" "$SCRIPT" --axis=runtime --hook 2>/dev/null)"
V="$(printf '%s' "$OUT" | verdict_stdout)"
[ "$V" = "VIDE" ] && ok "T10c INF-05 : référentiel absent → silence (pas d'alerte non actionnable)" \
  || ko "T10c sans référentiel le hook doit se taire (verdict=$V), sortie : $OUT"

# T10d — non-régression CLI : SANS --hook, la sortie par axe reste le flux d'objets historique
# que consomment les scripts et cette suite. Le correctif ne doit vivre que sous --hook.
N="$(run_in "$LAB_ERR" "$BASH_BIN" "$SCRIPT" --quick 2>/dev/null | grep -c '^{')"
[ "$N" -eq 2 ] && ok "T10d non-régression : sans --hook, --quick rend toujours 2 objets (runtime+hooks)" \
  || ko "T10d la sortie CLI a changé : $N objet(s) au lieu de 2"

# T11 — #153 §3 : `bash "$CLAUDE_PROJECT_DIR"/.claude/scripts/x.sh` (forme à guillemets, celle
# qui survit aux espaces d'un chemin Windows) : le jeton garde ses guillemets, le chemin n'était
# jamais résolu → faux script_missing. Le script existe ici : zéro détection attendue.
LAB_Q="$WORK/lab-quote"; mkdir -p "$LAB_Q/.claude/scripts"
printf '#!/bin/sh\nexit 0\n' > "$LAB_Q/.claude/scripts/present.sh"; chmod +x "$LAB_Q/.claude/scripts/present.sh"
cat > "$LAB_Q/.claude/settings.json" <<'JSON'
{ "hooks": { "SessionStart": [ { "hooks": [
  { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/scripts/present.sh" },
  { "type": "command", "command": "bash '$CLAUDE_PROJECT_DIR'/.claude/scripts/present.sh --x" } ] } ] } }
JSON
OUT="$(run_in "$LAB_Q" "$BASH_BIN" "$SCRIPT" --axis=hooks 2>/dev/null)"
if echo "$OUT" | grep -q 'script_missing'; then
  ko "T11 #153 §3 : faux script_missing sur la forme à guillemets, sortie : $OUT"
elif echo "$OUT" | grep -q '"errors_count": 0'; then
  ok "T11 #153 §3 : jetons \"\$CLAUDE_PROJECT_DIR\"/… (guillemets doubles et simples) résolus, 0 erreur"
else
  ko "T11 errors_count: 0 attendu, sortie : $OUT"
fi

# T12 — #153 §6.7 : sous Windows, print() termine chaque ligne par CRLF ; $(…) ne retire que la
# fin de la DERNIÈRE ligne, donc les lignes intermédiaires de py_out gardaient un \r → JSON
# invalide dès 2 détections. Simulé par un faux python3 qui réécrit en CRLF la sortie du
# programme lu sur stdin (l'invocation `python3 - …` de py_out), et seulement elle.
CRLF_BIN="$WORK/bin-crlf"; mkdir -p "$CRLF_BIN"
REAL_PY="$(command -v python3)"
cat > "$CRLF_BIN/python3" <<SH
#!/bin/sh
for a in "\$@"; do
  if [ "\$a" = "-" ]; then
    "$REAL_PY" "\$@" | awk '{ printf "%s\r\n", \$0 }'
    exit 0
  fi
done
exec "$REAL_PY" "\$@"
SH
chmod +x "$CRLF_BIN/python3"
LAB_CR="$WORK/lab-crlf"; mkdir -p "$LAB_CR/.claude/scripts"
cat > "$LAB_CR/.claude/settings.json" <<'JSON'
{ "hooks": { "SessionStart": [ { "hooks": [
  { "type": "command", "command": "bash .claude/scripts/fantome-un.sh" },
  { "type": "command", "command": "bash .claude/scripts/fantome-deux.sh" },
  { "type": "command", "command": "bash .claude/scripts/fantome-trois.sh" } ] } ] } }
JSON
OUT="$(run_in "$LAB_CR" env PATH="$CRLF_BIN:$PATH" "$BASH_BIN" "$SCRIPT" --axis=hooks 2>/dev/null)"
V="$(printf '%s' "$OUT" | verdict_stdout)"
if [ "$V" = "VALIDE" ] && printf '%s' "$OUT" | grep -q '"errors_count": 3'; then
  ok "T12 #153 §6.7 : sortie Python en CRLF, 3 détections → JSON valide, errors_count 3"
else
  ko "T12 JSON attendu VALIDE avec errors_count 3 (verdict=$V), sortie : $(printf '%s' "$OUT" | cat -v | head -12)"
fi

# T13 — #153 §6.4 : SubagentStop et FileChanged sont des événements documentés de Claude Code ;
# ni l'axe hooks (event_unknown) ni la liste de l'axe runtime ne doivent les ignorer.
LAB_EV="$WORK/lab-events"; mkdir -p "$LAB_EV/.claude/scripts"
cat > "$LAB_EV/.claude/settings.json" <<'JSON'
{ "hooks": {
  "SubagentStop": [ { "hooks": [ { "type": "command", "command": "echo ok" } ] } ],
  "FileChanged":  [ { "hooks": [ { "type": "command", "command": "echo ok" } ] } ] } }
JSON
OUT="$(run_in "$LAB_EV" "$BASH_BIN" "$SCRIPT" --axis=hooks 2>/dev/null)"
RT="$(run_in "$LAB_EV" "$BASH_BIN" "$SCRIPT" --axis=runtime 2>/dev/null)"
if echo "$OUT" | grep -q '"warnings_count": 0' && echo "$RT" | grep -q '"SubagentStop"' && echo "$RT" | grep -q '"FileChanged"'; then
  ok "T13 #153 §6.4 : SubagentStop/FileChanged connus (axe hooks 0 WARN, axe runtime les liste)"
else
  ko "T13 warnings_count: 0 + 2 événements runtime attendus, hooks : $OUT · runtime : $RT"
fi

# T14 — #153 §6.3 : --no-tests / VF_SKIP_TESTS=1 saute la boucle des suites de l'axe scripts
# (plusieurs heures sous Git Bash). Sans l'option : suites exécutées, "tests_skipped": false.
LAB_T="$WORK/lab-tests"; mkdir -p "$LAB_T/.claude/scripts/tests"
printf '#!/bin/sh\ntouch "%s/ran-marker"\nexit 0\n' "$WORK" > "$LAB_T/.claude/scripts/tests/test-sonde.sh"
chmod +x "$LAB_T/.claude/scripts/tests/test-sonde.sh"
rm -f "$WORK/ran-marker"
OUT="$(run_in "$LAB_T" "$BASH_BIN" "$SCRIPT" --axis=scripts 2>/dev/null)"
if [ -f "$WORK/ran-marker" ] && echo "$OUT" | grep -q '"tests_skipped": false' && echo "$OUT" | grep -q '"tests_pass": 1'; then
  ok "T14a #153 §6.3 : sans option, la suite tourne, tests_skipped=false, tests_pass=1"
else
  ko "T14a suite exécutée + tests_skipped=false + tests_pass=1 attendus (marker=$([ -f "$WORK/ran-marker" ] && echo oui || echo non)), sortie : $OUT"
fi
for variant in "--no-tests" "VF_SKIP_TESTS=1"; do
  rm -f "$WORK/ran-marker"
  if [ "$variant" = "--no-tests" ]; then
    OUT="$(run_in "$LAB_T" "$BASH_BIN" "$SCRIPT" --axis=scripts --no-tests 2>/dev/null)"
  else
    OUT="$(run_in "$LAB_T" env VF_SKIP_TESTS=1 "$BASH_BIN" "$SCRIPT" --axis=scripts 2>/dev/null)"
  fi
  V="$(printf '%s' "$OUT" | verdict_stdout)"
  if [ ! -f "$WORK/ran-marker" ] && [ "$V" = "VALIDE" ] && echo "$OUT" | grep -q '"tests_skipped": true' \
     && echo "$OUT" | grep -q '"tests_pass": 0' && echo "$OUT" | grep -q '"tests_fail": 0'; then
    ok "T14b #153 §6.3 : $variant → suite non exécutée, tests_skipped=true, JSON valide"
  else
    ko "T14b $variant : aucune suite, tests_skipped=true, JSON valide attendus (verdict=$V), sortie : $OUT"
  fi
done
run_in "$LAB_T" "$BASH_BIN" "$SCRIPT" --snapshot --no-tests >/dev/null 2>&1
if grep -q '^\*\*Tests\*\* : non exécutés' "$LAB_T/.claude/INFRASTRUCTURE_SNAPSHOT.md" 2>/dev/null; then
  ok "T14c #153 §6.3 : --snapshot --no-tests → ligne **Tests** : non exécutés"
else
  ko "T14c ligne '**Tests** : non exécutés' attendue dans le snapshot"
fi
run_in "$LAB_T" "$BASH_BIN" "$SCRIPT" --snapshot >/dev/null 2>&1
if grep -q '^\*\*Tests\*\* : exécutés' "$LAB_T/.claude/INFRASTRUCTURE_SNAPSHOT.md" 2>/dev/null; then
  ok "T14d #153 §6.3 : --snapshot sans option → ligne **Tests** : exécutés"
else
  ko "T14d ligne '**Tests** : exécutés' attendue dans le snapshot"
fi

# T15 — #153 §6.3, revue adverse : --strict + suites sautées = vert PAR ABSENCE → exit 3 INDÉTERMINÉ
# (arbitrage Samuel, AskUserQuestion session principale, 2026-10-22). rc ET champ JSON asserés.
for variant in "--no-tests" "VF_SKIP_TESTS=1"; do
  if [ "$variant" = "--no-tests" ]; then
    OUT="$(run_in "$LAB_T" "$BASH_BIN" "$SCRIPT" --strict --axis=scripts --no-tests 2>/dev/null)"; rc=$?
  else
    OUT="$(run_in "$LAB_T" env VF_SKIP_TESTS=1 "$BASH_BIN" "$SCRIPT" --strict --axis=scripts 2>/dev/null)"; rc=$?
  fi
  if [ "$rc" -eq 3 ] && echo "$OUT" | grep -q '"strict_indeterminate": true'; then
    ok "T15a #153 §6.3 : --strict + $variant → exit 3 INDÉTERMINÉ, strict_indeterminate=true"
  else
    ko "T15a --strict + $variant : rc=3 et strict_indeterminate=true attendus, obtenu rc=$rc, sortie : $OUT"
  fi
done
# Mode complet : même verdict (l'axe scripts est évalué).
run_in "$LAB_T" "$BASH_BIN" "$SCRIPT" --strict --no-tests >/dev/null 2>&1; rc=$?
[ "$rc" -eq 3 ] && ok "T15b #153 §6.3 : --strict --no-tests (mode complet) → exit 3" || ko "T15b mode complet : rc=3 attendu, obtenu rc=$rc"
# Non-régression : --strict SANS saut garde son comportement (suite exécutée, vert = 0, champ false).
OUT="$(run_in "$LAB_T" "$BASH_BIN" "$SCRIPT" --strict --axis=scripts 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ] && echo "$OUT" | grep -q '"strict_indeterminate": false' && echo "$OUT" | grep -q '"tests_pass": 1'; then
  ok "T15c non-régression : --strict sans saut → suite exécutée, exit 0, strict_indeterminate=false"
else
  ko "T15c --strict sans saut : rc=0, tests_pass=1, strict_indeterminate=false attendus, rc=$rc, sortie : $OUT"
fi
# Sans --strict, le saut reste advisory (exit 0, champ false : pas de gate, pas d'indéterminé).
OUT="$(run_in "$LAB_T" "$BASH_BIN" "$SCRIPT" --axis=scripts --no-tests 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ] && echo "$OUT" | grep -q '"strict_indeterminate": false'; then
  ok "T15d --no-tests sans --strict → exit 0 advisory, strict_indeterminate=false"
else
  ko "T15d --no-tests sans --strict : rc=0 + strict_indeterminate=false attendus, rc=$rc, sortie : $OUT"
fi
# Priorité : une suite en échec EXÉCUTÉE reste exit 1 ; un script à syntaxe cassée avec saut → exit 1 (rouge établi > indéterminé).
LAB_BAD="$WORK/lab-bad"; mkdir -p "$LAB_BAD/.claude/scripts/tests"
printf '#!/bin/sh\nexit 1\n' > "$LAB_BAD/.claude/scripts/tests/test-rouge.sh"; chmod +x "$LAB_BAD/.claude/scripts/tests/test-rouge.sh"
run_in "$LAB_BAD" "$BASH_BIN" "$SCRIPT" --strict --axis=scripts >/dev/null 2>&1; rc=$?
[ "$rc" -eq 1 ] && ok "T15e --strict + suite rouge exécutée → exit 1 (inchangé)" || ko "T15e suite rouge : rc=1 attendu, obtenu rc=$rc"
printf '#!/bin/sh\nif then\n' > "$LAB_BAD/.claude/scripts/casse.sh"
run_in "$LAB_BAD" "$BASH_BIN" "$SCRIPT" --strict --axis=scripts --no-tests >/dev/null 2>&1; rc=$?
[ "$rc" -eq 1 ] && ok "T15f --strict --no-tests + syntaxe cassée → exit 1 (finding établi prioritaire sur l'indéterminé)" || ko "T15f syntaxe cassée + saut : rc=1 attendu, obtenu rc=$rc"
# Axes qui n'évaluent pas l'axe scripts : inchangés (documenté en tête de audit-infra.sh).
run_in "$LAB_T" "$BASH_BIN" "$SCRIPT" --strict --quick --no-tests >/dev/null 2>&1; rc1=$?
run_in "$LAB_T" "$BASH_BIN" "$SCRIPT" --strict --axis=hooks --no-tests >/dev/null 2>&1; rc2=$?
[ "$rc1" -eq 0 ] && [ "$rc2" -eq 0 ] && ok "T15g --strict --no-tests sur --quick / --axis=hooks (axe scripts non évalué) → exit 0 inchangé" || ko "T15g rc attendus 0/0, obtenus quick=$rc1 hooks=$rc2"
# Même arbitrage (F2) via l'ENVIRONNEMENT : VF_SKIP_TESTS=1 hérité + --strict sur un mode qui n'exécute pas les suites → rc=0.
run_in "$LAB_T" env VF_SKIP_TESTS=1 "$BASH_BIN" "$SCRIPT" --strict --quick >/dev/null 2>&1; rcq=$?
run_in "$LAB_T" env VF_SKIP_TESTS=1 "$BASH_BIN" "$SCRIPT" --strict --axis=hooks >/dev/null 2>&1; rch=$?
run_in "$LAB_T" env VF_SKIP_TESTS=1 "$BASH_BIN" "$SCRIPT" --strict --axis=runtime >/dev/null 2>&1; rcr=$?
[ "$rcq" -eq 0 ] && [ "$rch" -eq 0 ] && [ "$rcr" -eq 0 ] && ok "T15g' VF_SKIP_TESTS=1 hérité + --strict sur --quick / --axis=hooks / --axis=runtime → exit 0" || ko "T15g' VF_SKIP_TESTS hérité : rc attendus 0/0/0, obtenus quick=$rcq hooks=$rch runtime=$rcr"

# T16 — #153 (précision de l'arbitrage du 2026-10-22, délégation explicite, session principale, 2026-10-23) :
# sans suite découverte, rien n'est sauté → pas d'indéterminé ; les cas T15 (suites présentes) restent exit 3.
# SCRIPT_UNDER_TEST permet de rejouer ces cas contre une autre version du script (preuve du rouge sur la base).
LAB_NOTESTS="$WORK/lab-notests"; mkdir -p "$LAB_NOTESTS/.claude/scripts"
LAB_EMPTY="$WORK/lab-emptytests"; mkdir -p "$LAB_EMPTY/.claude/scripts/tests"
printf 'lisez-moi\n' > "$LAB_EMPTY/.claude/scripts/tests/README.txt"
mkdir -p "$LAB_EMPTY/.claude/scripts/tests/test-dossier.sh"   # dossier nommé test-*.sh : pas une suite (fichier régulier requis)
for lab in "$LAB_NOTESTS" "$LAB_EMPTY"; do
  for variant in "--no-tests" "VF_SKIP_TESTS=1"; do
    if [ "$variant" = "--no-tests" ]; then
      OUT="$(run_in "$lab" "$BASH_BIN" "${SCRIPT_UNDER_TEST:-$SCRIPT}" --strict --axis=scripts --no-tests 2>/dev/null)"; rc=$?
    else
      OUT="$(run_in "$lab" env VF_SKIP_TESTS=1 "$BASH_BIN" "${SCRIPT_UNDER_TEST:-$SCRIPT}" --strict --axis=scripts 2>/dev/null)"; rc=$?
    fi
    if [ "$rc" -eq 0 ] && echo "$OUT" | grep -q '"strict_indeterminate": false' \
       && echo "$OUT" | grep -q '"strict_indeterminate_reason": "no_suites"' && echo "$OUT" | grep -q '"suites_found": 0'; then
      ok "T16a #153 : $(basename "$lab") + --strict + $variant → exit 0, strict_indeterminate=false, raison no_suites"
    else
      ko "T16a $(basename "$lab") + --strict + $variant : rc=0, strict_indeterminate=false, raison no_suites, suites_found=0 attendus, obtenu rc=$rc, sortie : $OUT"
    fi
  done
done
# Mode complet sans suite : même verdict (hors findings d'autres axes, lab propre).
run_in "$LAB_NOTESTS" "$BASH_BIN" "${SCRIPT_UNDER_TEST:-$SCRIPT}" --strict --axis=scripts --no-tests >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "T16b #153 : sans suite, --strict --no-tests → exit 0" || ko "T16b sans suite : rc=0 attendu, obtenu rc=$rc"
# Un finding bloquant reste exit 1 même sans suite (rouge établi).
LAB_NOTESTS_BAD="$WORK/lab-notests-bad"; mkdir -p "$LAB_NOTESTS_BAD/.claude/scripts"
printf '#!/bin/sh\nif then\n' > "$LAB_NOTESTS_BAD/.claude/scripts/casse.sh"
run_in "$LAB_NOTESTS_BAD" "$BASH_BIN" "${SCRIPT_UNDER_TEST:-$SCRIPT}" --strict --axis=scripts --no-tests >/dev/null 2>&1; rc=$?
[ "$rc" -eq 1 ] && ok "T16c #153 : sans suite + syntaxe cassée → exit 1 (finding bloquant)" || ko "T16c sans suite + syntaxe cassée : rc=1 attendu, obtenu rc=$rc"
# Suites présentes + sautées : raison tests_skipped et compte (garde la lettre de T15a, n'affaiblit rien).
OUT="$(run_in "$LAB_T" "$BASH_BIN" "${SCRIPT_UNDER_TEST:-$SCRIPT}" --strict --axis=scripts --no-tests 2>/dev/null)"; rc=$?
if [ "$rc" -eq 3 ] && echo "$OUT" | grep -q '"strict_indeterminate_reason": "tests_skipped"' && echo "$OUT" | grep -q '"suites_found": 1'; then
  ok "T16d #153 : suites présentes + sautées → exit 3, raison tests_skipped, suites_found=1"
else
  ko "T16d suites présentes + sautées : rc=3, raison tests_skipped, suites_found=1 attendus, obtenu rc=$rc, sortie : $OUT"
fi
# Hors --strict la raison est null.
OUT="$(run_in "$LAB_NOTESTS" "$BASH_BIN" "${SCRIPT_UNDER_TEST:-$SCRIPT}" --axis=scripts --no-tests 2>/dev/null)"
echo "$OUT" | grep -q '"strict_indeterminate_reason": null' && ok "T16e #153 : hors --strict → raison null" || ko "T16e hors --strict : raison null attendue, sortie : $OUT"

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
