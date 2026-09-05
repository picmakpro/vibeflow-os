#!/usr/bin/env bash
# test-run-test-suites.sh — suite du collecteur `scripts/run-test-suites.sh`.
#
# Un gate qui prétend supprimer les verts à vide et ne se vérifie pas lui-même serait précisément
# le défaut qu'il traque. Chaque cas construit une arborescence de suites FACTICES et mesure le
# verdict réel du collecteur — jamais une lecture de son code.
#
# T1 parc sain -> exit 0, bilan sous contrat · T2 suite rouge -> exit 1 · T3 VERT À VIDE (rc=0,
# contrat à 0 cas) -> exit 1 BRUYANT, le cas que le code de sortie seul ne voit pas · T4 contrat
# ILLISIBLE -> exit 1, jamais un silence · T5 contrat incohérent (KO déclarés, rc=0) -> exit 1
# T6 suite HORS contrat verte -> tolérée (ratchet), comptée à part · T7 ratchet : plancher non
# atteint -> exit 1 · T8 découverte vide -> exit 1, jamais un verdict vide.
set -u
cd "$(dirname "$0")/../.."
COLLECTOR="$(pwd)/scripts/run-test-suites.sh"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0; fail=0
ok() { echo "  ✓ $1"; pass=$((pass+1)); }
ko() { echo "  ✗ $1"; fail=$((fail+1)); }

# Fabrique une suite factice. $1 = racine, $2 = nom, $3 = code de sortie, $4 = ligne de contrat
# (vide = suite hors contrat).
make_suite() {
  local root="$1" name="$2" rc="$3" contract="$4"
  mkdir -p "$root/tests"
  {
    echo '#!/usr/bin/env bash'
    echo "echo 'libellé humain de $name'"
    [ -n "$contract" ] && echo "echo '$contract'"
    echo "exit $rc"
  } > "$root/tests/test-$name.sh"
  chmod +x "$root/tests/test-$name.sh"
}

run_collector() {
  local root="$1" floor="${2:-0}"
  ( cd "$(dirname "$COLLECTOR")/.." \
    && VF_TEST_ROOTS="$root" VF_MIN_UNDER_CONTRACT="$floor" bash "$COLLECTOR" 2>&1 )
}

# ---------- T1 : parc sain ----------
R1="$WORK/r1"
make_suite "$R1" a 0 "RESULT: pass=3 fail=0 skip=0"
make_suite "$R1" b 0 "RESULT: pass=5 fail=0 skip=1"
OUT="$(run_collector "$R1" 2)"; RC=$?
if [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -qF "contrat : 2/2 suite(s) — 8 cas verts, 0 rouges, 1 ignorés"; then
  ok "T1 parc sain : exit 0 et bilan agrégé exact (8 verts, 1 ignoré)"
else
  ko "T1 parc sain (rc=$RC) — sortie : $(printf '%s' "$OUT" | tail -3)"
fi

# ---------- T2 : suite rouge ----------
R2="$WORK/r2"
make_suite "$R2" a 0 "RESULT: pass=3 fail=0 skip=0"
make_suite "$R2" b 1 "RESULT: pass=2 fail=1 skip=0"
OUT="$(run_collector "$R2" 2)"; RC=$?
if [ "$RC" -ne 0 ] && printf '%s' "$OUT" | grep -q "FAIL(rc=1)"; then
  ok "T2 suite rouge : exit non nul, échec nommé"
else
  ko "T2 suite rouge (rc=$RC)"
fi

# ---------- T3 : VERT À VIDE — le cas que le code de sortie seul ne voit pas ----------
R3="$WORK/r3"
make_suite "$R3" a 0 "RESULT: pass=0 fail=0 skip=0"
OUT="$(run_collector "$R3" 1)"; RC=$?
if [ "$RC" -ne 0 ] && printf '%s' "$OUT" | grep -q "VERT À VIDE"; then
  ok "T3 vert à vide : rc=0 de la suite MAIS verdict rouge et BRUYANT du collecteur"
else
  ko "T3 vert à vide non détecté (rc=$RC) — c'est le défaut n°1 du dépôt"
fi

# ---------- T4 : contrat illisible ----------
R4="$WORK/r4"
make_suite "$R4" a 0 "RESULT: pass=trois fail=0 skip=0"
OUT="$(run_collector "$R4" 0)"; RC=$?
if [ "$RC" -ne 0 ] && printf '%s' "$OUT" | grep -q "CONTRAT ILLISIBLE"; then
  ok "T4 contrat illisible : rouge et bruyant, jamais toléré en silence"
else
  ko "T4 contrat illisible non signalé (rc=$RC)"
fi

# ---------- T5 : contrat incohérent avec le code de sortie ----------
R5="$WORK/r5"
make_suite "$R5" a 0 "RESULT: pass=2 fail=3 skip=0"
OUT="$(run_collector "$R5" 1)"; RC=$?
if [ "$RC" -ne 0 ] && printf '%s' "$OUT" | grep -q "CONTRAT INCOHÉRENT"; then
  ok "T5 KO déclarés sur une sortie 0 : incohérence détectée (suite qui oublie de propager)"
else
  ko "T5 incohérence non détectée (rc=$RC)"
fi

# ---------- T6 : suite hors contrat — tolérée, le ratchet n'est pas un big bang ----------
R6="$WORK/r6"
make_suite "$R6" a 0 "RESULT: pass=3 fail=0 skip=0"
make_suite "$R6" b 0 ""
OUT="$(run_collector "$R6" 1)"; RC=$?
if [ "$RC" -eq 0 ] && printf '%s' "$OUT" | grep -qF "hors contrat" \
   && printf '%s' "$OUT" | grep -qF "contrat : 1/2"; then
  ok "T6 suite hors contrat : tolérée et comptée à part (1/2), jamais un échec"
else
  ko "T6 suite hors contrat mal traitée (rc=$RC)"
fi

# ---------- T7 : ratchet — le plancher ne descend jamais ----------
R7="$WORK/r7"
make_suite "$R7" a 0 "RESULT: pass=3 fail=0 skip=0"
make_suite "$R7" b 0 ""
OUT="$(run_collector "$R7" 2)"; RC=$?
if [ "$RC" -ne 0 ] && printf '%s' "$OUT" | grep -q "RÉGRESSION DU CONTRAT"; then
  ok "T7 ratchet : une suite qui cesse d'émettre fait rougir au lieu de disparaître des radars"
else
  ko "T7 ratchet inopérant (rc=$RC)"
fi

# ---------- T8 : découverte vide ----------
R8="$WORK/r8"; mkdir -p "$R8"
OUT="$(run_collector "$R8" 0)"; RC=$?
if [ "$RC" -ne 0 ] && printf '%s' "$OUT" | grep -q "aucune suite de tests découverte"; then
  ok "T8 découverte vide : refus de rendre un verdict, jamais un vert par absence"
else
  ko "T8 découverte vide acceptée (rc=$RC)"
fi

echo ""
echo "== résultat : $pass ok, $fail ko =="
printf 'RESULT: pass=%s fail=%s skip=%s\n' "${pass}" "${fail}" "0"
if [ "$((pass+fail))" -eq 0 ]; then
  echo "  ✗ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée"
  exit 1
fi
[ "$fail" -eq 0 ]
