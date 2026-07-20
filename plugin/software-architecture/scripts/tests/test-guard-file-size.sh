#!/usr/bin/env bash
# test-guard-file-size.sh — Suite du guard PreToolUse(Edit|Write) Iron Law 300L (ADR-043).
#
# Le guard juge le RÉSULTAT de l'opération (contenu entrant / estimation), pas le seul
# état passé du disque. Payloads réalistes : Edit porte old_string/new_string, Write
# porte content — comme le runtime.
#
# T1  — Edit qui agrandit un fichier >= 300L sans marqueur → DENY (comportement conservé)
# T2  — fichier >= 300L AVEC marqueur disque, édition qui agrandit → allow (dette tracée)
# T3  — petit fichier, édition qui agrandit sous le seuil → allow
# T4  — fichier non-code (.md) long → allow
# T5  — Write initial PETIT sur chemin inexistant → allow
# T6  — stdin invalide → allow silencieux (fail-open)
# T7  — ARC-01a : Write d'un refactor conforme (150L) sur un chemin 400L → allow (remédiation)
# T8  — ARC-01b : Edit qui AJOUTE le marqueur sur un fichier 400L → allow
# T9  — ARC-01c : Edit qui rétrécit un fichier 400L (new <= old) → allow (voie de découpe)
# T10 — ARC-02a : Edit qui fait passer 299L au-dessus du seuil → deny
# T11 — ARC-02b : Write NEUF de 2000L → deny
# T12 — ARC-02c : replace_all qui fait exploser le compte → deny ; occurrence absente → allow
# T13 — ARC-03 : fichier illisible (chmod 000) → allow (fail-open, jamais deny sur erreur interne)
# T14 — ARC-05 : Write de 300 lignes SANS newline finale → deny (compte exact, pas wc -l)

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
GUARD="$(cd "$TESTS_DIR/.." && pwd)/guard-file-size.sh"
# Exécuter le guard avec le bash qui exécute la suite (/bin/bash → validation 3.2 réelle).
BASH_BIN="${BASH:-bash}"

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "== test-guard-file-size (guard: $GUARD) =="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

for i in $(seq 1 350); do echo "const x$i = $i;"; done > "$WORK/big.ts"
{ echo "// vibeflow:allow-large-file — dette tracée"; for i in $(seq 1 350); do echo "const x$i = $i;"; done; } > "$WORK/big-optout.ts"
for i in $(seq 1 50); do echo "const x$i = $i;"; done > "$WORK/small.ts"
for i in $(seq 1 400); do echo "ligne $i"; done > "$WORK/doc.md"
for i in $(seq 1 400); do echo "const y$i = $i;"; done > "$WORK/huge.ts"
for i in $(seq 1 299); do echo "const z$i = $i;"; done > "$WORK/edge299.ts"
# 250L dont 10 occurrences identiques (cas replace_all)
{ for i in $(seq 1 240); do echo "const w$i = $i;"; done; for i in $(seq 1 10); do echo "REPEAT_ME();"; done; } > "$WORK/dup.ts"

run_guard() { printf '%s' "$1" | "$BASH_BIN" "$GUARD" 2>/dev/null; }

# Payloads construits par python (échappement JSON fiable pour les chaînes multilignes).
mk_edit() { # file old new [all]
  python3 -c '
import json, sys
ti = {"file_path": sys.argv[1], "old_string": sys.argv[2], "new_string": sys.argv[3]}
if len(sys.argv) > 4 and sys.argv[4] == "all":
    ti["replace_all"] = True
print(json.dumps({"tool_name": "Edit", "tool_input": ti}))' "$@"
}
mk_write() { # file content
  python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]}}))' "$1" "$2"
}

GROW3="ligne a
ligne b
ligne c"

# T1 — Edit qui agrandit un fichier >= seuil sans marqueur → deny
OUT="$(run_guard "$(mk_edit "$WORK/big.ts" "const x1 = 1;" "$GROW3")")"
if echo "$OUT" | grep -q '"permissionDecision": *"deny"' && echo "$OUT" | grep -q "allow-large-file"; then
  ok "T1 Edit qui agrandit un fichier >= 300L sans marqueur → deny avec échappatoire expliquée"
else
  ko "T1 deny attendu, obtenu : ${OUT:-<vide>}"
fi

# T2 — marqueur sur le disque → allow même en agrandissant
OUT="$(run_guard "$(mk_edit "$WORK/big-optout.ts" "const x1 = 1;" "$GROW3")")"
[ -z "$OUT" ] && ok "T2 marqueur vibeflow:allow-large-file sur disque → allow (dette tolérée)" || ko "T2 allow attendu, obtenu : $OUT"

# T3 — petit fichier, croissance sous le seuil → allow
OUT="$(run_guard "$(mk_edit "$WORK/small.ts" "const x1 = 1;" "$GROW3")")"
[ -z "$OUT" ] && ok "T3 fichier court qui reste sous le seuil → allow" || ko "T3 allow attendu, obtenu : $OUT"

# T4 — non-code → allow
OUT="$(run_guard "$(mk_edit "$WORK/doc.md" "ligne 1" "$GROW3")")"
[ -z "$OUT" ] && ok "T4 fichier non-code → allow" || ko "T4 allow attendu, obtenu : $OUT"

# T5 — Write initial petit sur chemin inexistant → allow
OUT="$(run_guard "$(mk_write "$WORK/nexiste-pas.ts" "const a = 1;")")"
[ -z "$OUT" ] && ok "T5 Write initial petit (fichier inexistant) → allow" || ko "T5 allow attendu, obtenu : $OUT"

# T6 — stdin invalide → allow silencieux
OUT="$(echo 'pas du json' | "$BASH_BIN" "$GUARD" 2>/dev/null)"; RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "T6 stdin invalide → allow silencieux (fail-open)"
else
  ko "T6 fail-open (rc=$RC, out=$OUT)"
fi

# T7 — ARC-01a : Write d'un refactor conforme sur un chemin obèse → allow
REFACTOR="$(for i in $(seq 1 150); do echo "const r$i = $i;"; done)"
OUT="$(run_guard "$(mk_write "$WORK/huge.ts" "$REFACTOR")")"
[ -z "$OUT" ] && ok "T7 ARC-01a Write refactor 150L sur chemin 400L → allow (remédiation possible)" || ko "T7 allow attendu, obtenu : $OUT"

# T8 — ARC-01b : Edit qui pose le marqueur sur un fichier obèse → allow
OUT="$(run_guard "$(mk_edit "$WORK/huge.ts" "const y1 = 1;" "// vibeflow:allow-large-file — dette tracée
const y1 = 1;")")"
[ -z "$OUT" ] && ok "T8 ARC-01b Edit qui ajoute le marqueur → allow (pas de deny-loop)" || ko "T8 allow attendu, obtenu : $OUT"

# T9 — ARC-01c : Edit qui rétrécit un fichier obèse → allow
OUT="$(run_guard "$(mk_edit "$WORK/huge.ts" "const y1 = 1;
const y2 = 2;
const y3 = 3;" "extraireModule();")")"
[ -z "$OUT" ] && ok "T9 ARC-01c Edit qui rétrécit (new <= old) → allow (voie de découpe)" || ko "T9 allow attendu, obtenu : $OUT"

# T10 — ARC-02a : 299L + édition qui franchit le seuil → deny
BIGNEW="$(for i in $(seq 1 50); do echo "injecte$i();"; done)"
OUT="$(run_guard "$(mk_edit "$WORK/edge299.ts" "const z1 = 1;" "$BIGNEW")")"
if echo "$OUT" | grep -q '"permissionDecision": *"deny"'; then
  ok "T10 ARC-02a Edit qui fait franchir le seuil (299 → ~348) → deny"
else
  ko "T10 deny attendu, obtenu : ${OUT:-<vide>}"
fi

# T11 — ARC-02b : Write neuf massif → deny
HUGE_CONTENT="$(for i in $(seq 1 2000); do echo "const h$i = $i;"; done)"
OUT="$(run_guard "$(mk_write "$WORK/nouveau-massif.ts" "$HUGE_CONTENT")")"
if echo "$OUT" | grep -q '"permissionDecision": *"deny"'; then
  ok "T11 ARC-02b Write neuf de 2000L → deny"
else
  ko "T11 deny attendu, obtenu : ${OUT:-<vide>}"
fi

# T12 — ARC-02c : replace_all multiplicateur → deny ; occurrence absente → allow
OUT="$(run_guard "$(mk_edit "$WORK/dup.ts" "REPEAT_ME();" "$(printf 'a();\nb();\nc();\nd();\ne();\nf();\ng();\nh();\ni();\nj();')" all)")"
if echo "$OUT" | grep -q '"permissionDecision": *"deny"'; then
  ok "T12a ARC-02c replace_all x10 qui fait exploser le compte (250 → ~340) → deny"
else
  ko "T12a deny attendu, obtenu : ${OUT:-<vide>}"
fi
OUT="$(run_guard "$(mk_edit "$WORK/dup.ts" "ABSENT_DU_FICHIER();" "$BIGNEW" all)")"
[ -z "$OUT" ] && ok "T12b replace_all sans occurrence → allow (Edit échouera de lui-même)" || ko "T12b allow attendu, obtenu : $OUT"

# T13 — ARC-03 : fichier illisible → allow (fail-open), jamais deny sur erreur interne
for i in $(seq 1 20); do echo "const u$i = $i;"; done > "$WORK/verrouille.ts"
chmod 000 "$WORK/verrouille.ts"
OUT="$(run_guard "$(mk_edit "$WORK/verrouille.ts" "const u1 = 1;" "$GROW3")")"; RC=$?
chmod 644 "$WORK/verrouille.ts"
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  ok "T13 ARC-03 fichier illisible (chmod 000) → allow silencieux (fail-open)"
else
  ko "T13 fail-open attendu (rc=$RC), obtenu : $OUT"
fi

# T14 — ARC-05 : contenu de 300 lignes SANS newline finale → deny (300 >= 300)
CONTENT300="$(for i in $(seq 1 300); do echo "l$i"; done)"   # $( ) retire le \n final
OUT="$(run_guard "$(mk_write "$WORK/exact300.ts" "$CONTENT300")")"
if echo "$OUT" | grep -q '"permissionDecision": *"deny"'; then
  ok "T14 ARC-05 Write 300 lignes sans newline finale → deny (plus d'off-by-one wc -l)"
else
  ko "T14 deny attendu, obtenu : ${OUT:-<vide>}"
fi

echo ""
echo "== Résultat : $pass OK · $fail KO =="
[ "$fail" -eq 0 ]
