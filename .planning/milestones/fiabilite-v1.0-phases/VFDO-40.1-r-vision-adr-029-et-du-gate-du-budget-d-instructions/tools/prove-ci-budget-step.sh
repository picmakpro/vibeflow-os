#!/usr/bin/env bash
# prove-ci-budget-step.sh — Phase 40.1 (plan 03, T-40.1-08). Joue des mutants du gate
# check-instruction-budget.sh CONTRE l'étape CI check-instruction-budget extraite de ci.yml par
# replay-ci-jobs.sh (jamais une copie de l'étape) : chaque mutant doit faire échouer l'étape
# (rc 1) sur SA bascule précise (une note `<k>/7` ciblée), jamais une autre. Une étape verte par
# construction (O-1) ne serait jamais détectée sans cette contre-épreuve.
#
# La cible n'est PAS le dépôt réel : c'est une copie de l'arbre SUIVI courant (git ls-files -z +
# tar), pour que les mutations et modifications non committées de cette même phase soient
# incluses sans jamais toucher le dépôt de travail.
#
# Codes de sortie : 0 = T0 vert ET les six mutants rouges sur leur bascule exacte ; 1 = au moins
# une assertion en échec ; 2 = usage/environnement (pas un dépôt git, gate ou outil de rejeu
# introuvables).
set -u
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$ROOT" ]; then
  echo "ERREUR: pas un depot git" >&2
  exit 2
fi

HERE="$(cd "$(dirname "$0")" && pwd)"
REPLAY="$HERE/replay-ci-jobs.sh"
if [ ! -f "$REPLAY" ]; then
  echo "ERREUR: outil de rejeu introuvable: $REPLAY" >&2
  exit 2
fi

GATE_REL="plugin/conductor/scripts/check-instruction-budget.sh"
if [ ! -f "$ROOT/$GATE_REL" ]; then
  echo "ERREUR: gate introuvable: $ROOT/$GATE_REL" >&2
  exit 2
fi

PASS=0; FAIL=0
ok() { echo "  ok $1"; PASS=$((PASS+1)); }
# ko <assertion> <attendu> <obtenu> — trace a trois champs distincts, jamais un ko muet.
ko() {
  echo "  ko $1"
  echo "    assertion : $1"
  echo "    attendu   : $2"
  echo "    obtenu    : $3"
  FAIL=$((FAIL+1))
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- Copie de l'arbre SUIVI courant, modifications non committees incluses ------------------------
TARBALL="$WORK/.tree.tar"
if ! (cd "$ROOT" && git ls-files -z | tar --null -T - -cf "$TARBALL") 2>/dev/null; then
  echo "ERREUR: copie de l'arbre suivi (git ls-files -z + tar) a echoue" >&2
  exit 2
fi
COPY="$WORK/copie"
mkdir -p "$COPY"
if ! tar -x -C "$COPY" -f "$TARBALL" 2>/dev/null; then
  echo "ERREUR: extraction de la copie a echoue" >&2
  exit 2
fi

GATE="$COPY/$GATE_REL"
if [ ! -f "$GATE" ]; then
  echo "ERREUR: gate absent de la copie: $GATE" >&2
  exit 2
fi
ORIG="$WORK/.gate-orig.sh"
cp "$GATE" "$ORIG"

run_step() { # -> imprime le chemin du journal ; le code de rc de l'étape est retourné
  local out="$WORK/step-out-$$_$RANDOM.log"
  bash "$REPLAY" --root "$COPY" --job gates --step check-instruction-budget > "$out" 2>&1
  local rc=$?
  printf '%s\n' "$out"
  return "$rc"
}

restore_gate() { cp "$ORIG" "$GATE"; }

# --- T0 : etape extraite, gate intact -> rc 0 ------------------------------------------------------
restore_gate
t0_out="$(run_step)"; t0_rc=$?
if [ "$t0_rc" -eq 0 ]; then
  ok "T0 — etape extraite, gate intact -> rc 0"
else
  ko "T0 — etape extraite, gate intact -> rc 0" "rc=0" "rc=$t0_rc (journal : $t0_out)"
fi

# apply_mutant <old> <new> -> ecrit le mutant dans $GATE ; rc 1 si non opposable (cmp identique ou
# bash -n en echec), rc 0 sinon.
apply_mutant() {
  local old="$1" new="$2" mut="$WORK/.mut.sh"
  awk -v old="$old" -v new="$new" '{ if ($0 == old) { print new } else { print } }' "$ORIG" > "$mut"
  if cmp -s "$mut" "$ORIG"; then
    return 1
  fi
  if ! bash -n "$mut" 2>/dev/null; then
    return 1
  fi
  cp "$mut" "$GATE"
  return 0
}

# check_mutant <nom> <old> <new> <note-attendue>
check_mutant() {
  local nom="$1" old="$2" new="$3" note="$4"
  restore_gate
  if ! apply_mutant "$old" "$new"; then
    ko "$nom — mutation opposable (cmp differente, bash -n OK)" "mutation appliquee et valide" "mutant identique a l'original OU syntaxe invalide — NON OPPOSABLE"
    restore_gate
    return
  fi
  local out rc
  out="$(run_step)"; rc=$?
  local has_note=0
  case "$(cat "$out" 2>/dev/null)" in
    *"$note"*) has_note=1 ;;
  esac
  if [ "$rc" -eq 1 ] && [ "$has_note" -eq 1 ]; then
    ok "$nom — etape rouge (rc=1) sur sa bascule exacte ($note)"
  else
    ko "$nom — etape rouge (rc=1) sur sa bascule exacte ($note)" "rc=1, note contenant \"$note\"" "rc=$rc, note presente=$has_note (journal : $out)"
  fi
  restore_gate
}

check_mutant "MUT-2 (comparaison LIGNES re-introduite comme bloquante)" \
  '    [ "$lines" -gt "$bl_lines" ] && verdict="${verdict}+LIGNES-EN-HAUSSE"' \
  '    [ "$lines" -gt "$bl_lines" ] && verdict="DEPASSEMENT-LIGNES"' \
  "2/7"

check_mutant "MUT-1 (comparaison INSTRUCTIONS neutralisee)" \
  '    [ "$instr" -gt "$bl_instr" ] && instr_over=1' \
  '    [ "0" -eq "1" ] && instr_over=1' \
  "3/7"

check_mutant "MUT-5 (avertissement de zone rendu bloquant)" \
  '    verdict="${verdict}+AVERTISSEMENT-ADR029"' \
  '    verdict="DEPASSEMENT-AVERTISSEMENT"' \
  "4/7"

check_mutant "MUT-6 (plafond decale d'un cran, -gt -> -ge)" \
  '  if [ "$lines" -gt "$VF_BUDGET_LINE_CAP" ]; then' \
  '  if [ "$lines" -ge "$VF_BUDGET_LINE_CAP" ]; then' \
  "4/7"

check_mutant "MUT-AV (avertissement de zone efface)" \
  '    verdict="${verdict}+AVERTISSEMENT-ADR029"' \
  '    verdict="${verdict}"' \
  "4/7"

check_mutant "MUT-CAP (plafond desactive, 300 -> 100000)" \
  'VF_BUDGET_LINE_CAP=300' \
  'VF_BUDGET_LINE_CAP=100000' \
  "5/7"

restore_gate

echo "== resultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
