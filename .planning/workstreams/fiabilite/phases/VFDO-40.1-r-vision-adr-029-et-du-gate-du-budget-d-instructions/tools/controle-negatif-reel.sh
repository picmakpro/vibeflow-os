#!/usr/bin/env bash
# controle-negatif-reel.sh — Contrôle négatif de check-no-live-250.sh JOUÉ SUR UN CLONE du dépôt
# réel (Phase 40.1, BUDG-04). Joué à la CLÔTURE (plan 40.1-14), pas à cette étape. Portage des cas
# N1-N4 du contrôle manuel du manager (copie jetable, 2026-09-16), sans chemin machine : chaque cas
# altère le clone, relève rc + nombre de lignes + première ligne de sortie, restaure, puis vérifie
# le retour à rc 0. Précondition : le dépôt d'origine est propre (git status --porcelain vide) —
# sinon R0 imprimerait les lignes déjà présentes et l'outil ne pourrait pas prouver l'ajout.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HERE/check-no-live-250.sh"

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
# ko <assertion> <attendu> <obtenu> — trace à trois champs distincts, jamais un « KO » muet.
ko() {
  echo "  ✗ $1"
  echo "    assertion : $1"
  echo "    attendu   : $2"
  echo "    obtenu    : $3"
  FAIL=$((FAIL+1))
}

REPO_ROOT="$(git rev-parse --show-toplevel)"
CLONE_PARENT="$(mktemp -d)"
CLONE="$CLONE_PARENT/clone"
trap 'rm -rf "$CLONE_PARENT"' EXIT

git clone -q "$REPO_ROOT" "$CLONE" || {
  echo "ERREUR: clone impossible" >&2
  exit 2
}

lines_out() { awk 'END{print NR}' "$1"; }

run_clone() {
  bash "$TARGET" "$CLONE"
}

OUT="$CLONE_PARENT/r0.out"
RC=0; run_clone > "$OUT" || RC=$?
N=$(lines_out "$OUT")
if [ "$RC" -eq 0 ] && [ "$N" -eq 0 ]; then
  ok "R0 clone propre -> rc 0, 0 ligne (precondition)"
else
  echo "$(cat "$OUT")"
  ko "R0 clone propre -> rc 0, 0 ligne (precondition)" "rc=0 n=0" "rc=$RC n=$N"
  echo "== resultat : $PASS ok, $((FAIL+3)) ko (arret precoce, precondition R0 non satisfaite) =="
  exit 1
fi

# R1 — ligne « - **Densité** : agents ≤250L (réintroduit) » ajoutée à CLAUDE.md -> rc 1, 1 ligne
# CLAUDE.md:, puis restauration -> rc 0.
printf '%s\n' '- **Densité** : agents ≤250L (réintroduit)' >> "$CLONE/CLAUDE.md"
OUT="$CLONE_PARENT/r1.out"
RC=0; run_clone > "$OUT" || RC=$?
N=$(lines_out "$OUT")
FIRST=$(head -1 "$OUT")
case "$FIRST" in CLAUDE.md:*) F_OK=1 ;; *) F_OK=0 ;; esac
if [ "$RC" -eq 1 ] && [ "$N" -eq 1 ] && [ "$F_OK" -eq 1 ]; then
  ok "R1 CLAUDE.md reintroduit -> rc 1, 1 ligne CLAUDE.md:"
else
  ko "R1 CLAUDE.md reintroduit -> rc 1, 1 ligne CLAUDE.md:" "rc=1 n=1 CLAUDE.md:*" "rc=$RC n=$N first=[$FIRST]"
fi
(cd "$CLONE" && git checkout -- CLAUDE.md) >/dev/null 2>&1 || true
RC=0; run_clone > /dev/null || RC=$?
if [ "$RC" -eq 0 ]; then
  ok "R1 restauration CLAUDE.md -> rc 0"
else
  ko "R1 restauration CLAUDE.md -> rc 0" "rc=0" "rc=$RC"
fi

# R2 — VF_BUDGET_LINE_CAP=300 réécrit en 250 par awk dans le gate du clone -> rc 1, 1 ligne
# plugin/conductor/scripts/check-instruction-budget.sh:, puis restauration -> rc 0.
GATE="$CLONE/plugin/conductor/scripts/check-instruction-budget.sh"
if [ -f "$GATE" ]; then
  TMPGATE="$CLONE_PARENT/gate.tmp"
  awk '{ gsub(/VF_BUDGET_LINE_CAP=300/, "VF_BUDGET_LINE_CAP=250"); print }' "$GATE" > "$TMPGATE"
  mv "$TMPGATE" "$GATE"
  OUT="$CLONE_PARENT/r2.out"
  RC=0; run_clone > "$OUT" || RC=$?
  N=$(lines_out "$OUT")
  FIRST=$(head -1 "$OUT")
  case "$FIRST" in plugin/conductor/scripts/check-instruction-budget.sh:*) F_OK=1 ;; *) F_OK=0 ;; esac
  if [ "$RC" -eq 1 ] && [ "$N" -eq 1 ] && [ "$F_OK" -eq 1 ]; then
    ok "R2 gate reecrit en 250 -> rc 1, 1 ligne plugin/conductor/scripts/check-instruction-budget.sh:"
  else
    ko "R2 gate reecrit en 250 -> rc 1, 1 ligne plugin/conductor/scripts/check-instruction-budget.sh:" "rc=1 n=1 gate:*" "rc=$RC n=$N first=[$FIRST]"
  fi
  (cd "$CLONE" && git checkout -- plugin/conductor/scripts/check-instruction-budget.sh) >/dev/null 2>&1 || true
  RC=0; run_clone > /dev/null || RC=$?
  if [ "$RC" -eq 0 ]; then
    ok "R2 restauration gate -> rc 0"
  else
    ko "R2 restauration gate -> rc 0" "rc=0" "rc=$RC"
  fi
else
  ko "R2 gate present dans le clone" "fichier present" "absent : $GATE"
fi

# R3 — .planning/milestones/zz-temoin.md portant « agents <= 250 lignes », git add -> rc 0.
mkdir -p "$CLONE/.planning/milestones"
printf '%s\n' 'agents <= 250 lignes' > "$CLONE/.planning/milestones/zz-temoin.md"
(cd "$CLONE" && git add -- .planning/milestones/zz-temoin.md) >/dev/null 2>&1 || true
RC=0; run_clone > /dev/null || RC=$?
if [ "$RC" -eq 0 ]; then
  ok "R3 nouveau fichier d'archive avec 250 -> rc 0"
else
  ko "R3 nouveau fichier d'archive avec 250 -> rc 0" "rc=0" "rc=$RC"
fi
(cd "$CLONE" && git reset -q -- .planning/milestones/zz-temoin.md) >/dev/null 2>&1 || true
rm -f "$CLONE/.planning/milestones/zz-temoin.md"

# R4 — ligne « The charter keeps agents under 250 lines. » ajoutée à
# manual/en/07-under-the-hood/the-machine-gates.md -> rc 1, 1 ligne.
GATES_MANUAL="$CLONE/manual/en/07-under-the-hood/the-machine-gates.md"
if [ -f "$GATES_MANUAL" ]; then
  printf '%s\n' 'The charter keeps agents under 250 lines.' >> "$GATES_MANUAL"
  OUT="$CLONE_PARENT/r4.out"
  RC=0; run_clone > "$OUT" || RC=$?
  N=$(lines_out "$OUT")
  if [ "$RC" -eq 1 ] && [ "$N" -eq 1 ]; then
    ok "R4 ligne ajoutee au manuel des gates -> rc 1, 1 ligne"
  else
    ko "R4 ligne ajoutee au manuel des gates -> rc 1, 1 ligne" "rc=1 n=1" "rc=$RC n=$N"
  fi
  (cd "$CLONE" && git checkout -- manual/en/07-under-the-hood/the-machine-gates.md) >/dev/null 2>&1 || true
else
  ko "R4 manuel des gates present dans le clone" "fichier present" "absent : $GATES_MANUAL"
fi

echo "== resultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
