#!/usr/bin/env bash
# test-check-no-live-250.sh — Contrôle négatif versionné de check-no-live-250.sh (Phase 40.1,
# BUDG-04). Chaque cas construit sa PROPRE fixture dans un dépôt git jetable (mktemp -d, jamais le
# dépôt réel — cf. patron test-check-instruction-budget.sh). Deux mutants opposables prouvent que
# la regex voit l'angle mort de `git grep -w` (MUT-W) et que l'exclusion agit réellement (MUT-X).
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

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# mk_repo <name> -> imprime le chemin ; crée un dépôt git vide jetable
mk_repo() {
  local d="$TMP/$1"
  mkdir -p "$d"
  (cd "$d" && git init -q) >/dev/null 2>&1 || true
  printf '%s' "$d"
}

# w <root> <path> <ligne...> — écrit un fichier ligne par ligne (jamais de heredoc), le stage.
w() {
  local root="$1" path="$2"; shift 2
  mkdir -p "$(dirname "$root/$path")"
  printf '%s\n' "$@" > "$root/$path"
  (cd "$root" && git add -- "$path") >/dev/null 2>&1 || true
}

# lines_out <file> — compte les lignes via awk (jamais wc -l sur un flux vide, cf. mémoire projet).
lines_out() { awk 'END{print NR}' "$1"; }

run_tool() {
  local root="$1"
  bash "$TARGET" "$root"
}

# =====================================================================================
# C0 — fichier sans 250 -> rc 0, 0 ligne
# =====================================================================================
R="$(mk_repo c0)"
w "$R" "a.md" "rien a signaler ici"
OUT="$TMP/c0.out"; RC=0; run_tool "$R" > "$OUT" || RC=$?
N=$(lines_out "$OUT")
if [ "$RC" -eq 0 ] && [ "$N" -eq 0 ]; then
  ok "C0 fichier sans 250 -> rc 0, 0 ligne"
else
  ko "C0 fichier sans 250 -> rc 0, 0 ligne" "rc=0 n=0" "rc=$RC n=$N"
fi

# =====================================================================================
# C1 — CLAUDE.md portant « agents <=250L » -> rc 1, 1 ligne CLAUDE.md: (angle mort de git grep -w)
# =====================================================================================
R="$(mk_repo c1)"
w "$R" "CLAUDE.md" "densite : agents <=250L, skills <=500L"
OUT="$TMP/c1.out"; RC=0; run_tool "$R" > "$OUT" || RC=$?
N=$(lines_out "$OUT")
FIRST=$(head -1 "$OUT")
case "$FIRST" in
  CLAUDE.md:*) F_OK=1 ;;
  *) F_OK=0 ;;
esac
if [ "$RC" -eq 1 ] && [ "$N" -eq 1 ] && [ "$F_OK" -eq 1 ]; then
  ok "C1 CLAUDE.md <=250L -> rc 1, 1 ligne CLAUDE.md: (angle mort git grep -w)"
else
  ko "C1 CLAUDE.md <=250L -> rc 1, 1 ligne CLAUDE.md: (angle mort git grep -w)" "rc=1 n=1 CLAUDE.md:*" "rc=$RC n=$N first=[$FIRST]"
fi
C1_REPO="$R"

# =====================================================================================
# C2 — plugin/x/scripts/g.sh portant VF_BUDGET_LINE_CAP=250 -> rc 1
# =====================================================================================
R="$(mk_repo c2)"
w "$R" "plugin/x/scripts/g.sh" "VF_BUDGET_LINE_CAP=250"
OUT="$TMP/c2.out"; RC=0; run_tool "$R" > "$OUT" || RC=$?
if [ "$RC" -eq 1 ]; then
  ok "C2 VF_BUDGET_LINE_CAP=250 -> rc 1"
else
  ko "C2 VF_BUDGET_LINE_CAP=250 -> rc 1" "rc=1" "rc=$RC"
fi

# =====================================================================================
# C3 — .planning/milestones/a.md portant « agents <= 250 lignes » -> rc 0 (exclusion d'archive)
# =====================================================================================
R="$(mk_repo c3)"
w "$R" ".planning/milestones/a.md" "agents <= 250 lignes"
OUT="$TMP/c3.out"; RC=0; run_tool "$R" > "$OUT" || RC=$?
if [ "$RC" -eq 0 ]; then
  ok "C3 .planning/milestones/a.md <=250 lignes -> rc 0 (exclusion d'archive)"
else
  ko "C3 .planning/milestones/a.md <=250 lignes -> rc 0 (exclusion d'archive)" "rc=0" "rc=$RC"
fi
C3_REPO="$R"

# =====================================================================================
# C4 — manual/.../the-machine-gates.md : ligne exclue + une AUTRE ligne -> rc 1, exactement 1 ligne
# (l'exclusion est ligne-à-ligne, jamais fichier entier)
# =====================================================================================
R="$(mk_repo c4)"
w "$R" "manual/en/07-under-the-hood/the-machine-gates.md" \
  "the charter recommending agents themselves stay under 250 lines is not the 300-line code threshold" \
  "agents under 250 lines is a separate live claim on another line"
OUT="$TMP/c4.out"; RC=0; run_tool "$R" > "$OUT" || RC=$?
N=$(lines_out "$OUT")
if [ "$RC" -eq 1 ] && [ "$N" -eq 1 ]; then
  ok "C4 the-machine-gates.md : ligne exclue + autre ligne -> rc 1, exactement 1 ligne (exclusion ligne-a-ligne)"
else
  ko "C4 the-machine-gates.md : ligne exclue + autre ligne -> rc 1, exactement 1 ligne (exclusion ligne-a-ligne)" "rc=1 n=1" "rc=$RC n=$N"
fi

# =====================================================================================
# C5 — répertoire non git -> rc 2
# =====================================================================================
R="$TMP/c5-nongit"
mkdir -p "$R"
OUT="$TMP/c5.out"; RC=0; run_tool "$R" > "$OUT" 2>&1 || RC=$?
if [ "$RC" -eq 2 ]; then
  ok "C5 repertoire non git -> rc 2"
else
  ko "C5 repertoire non git -> rc 2" "rc=2" "rc=$RC"
fi

# =====================================================================================
# C6 — faux positifs numériques (2500, 1250, v2.50) -> rc 0
# =====================================================================================
R="$(mk_repo c6)"
w "$R" "a.md" "valeurs : 2500, 1250, v2.50, aucune isolee"
OUT="$TMP/c6.out"; RC=0; run_tool "$R" > "$OUT" || RC=$?
if [ "$RC" -eq 0 ]; then
  ok "C6 faux positifs numeriques (2500, 1250, v2.50) -> rc 0"
else
  ko "C6 faux positifs numeriques (2500, 1250, v2.50) -> rc 0" "rc=0" "rc=$RC obtenu=[$(cat "$OUT")]"
fi

# =====================================================================================
# C7 — .planning/phases/VFDO-41-x/41-01-PLAN.md portant 250 -> rc 0 (ecart (a))
# =====================================================================================
R="$(mk_repo c7)"
w "$R" ".planning/phases/VFDO-41-x/41-01-PLAN.md" "plafond historique de 250 lignes cite ici"
OUT="$TMP/c7.out"; RC=0; run_tool "$R" > "$OUT" || RC=$?
if [ "$RC" -eq 0 ]; then
  ok "C7 .planning/phases/VFDO-41-x/41-01-PLAN.md portant 250 -> rc 0 (ecart (a))"
else
  ko "C7 .planning/phases/VFDO-41-x/41-01-PLAN.md portant 250 -> rc 0 (ecart (a))" "rc=0" "rc=$RC"
fi

# =====================================================================================
# C8 — .planning/seeds/SEED-001-equipe-produit-v1.md portant « > 250 lignes » -> rc 1 (ecart (b))
# =====================================================================================
R="$(mk_repo c8)"
w "$R" ".planning/seeds/SEED-001-equipe-produit-v1.md" "aucun nouvel agent > 250 lignes"
OUT="$TMP/c8.out"; RC=0; run_tool "$R" > "$OUT" || RC=$?
if [ "$RC" -eq 1 ]; then
  ok "C8 SEED-001-equipe-produit-v1.md > 250 lignes -> rc 1 (ecart (b), la regle est retiree)"
else
  ko "C8 SEED-001-equipe-produit-v1.md > 250 lignes -> rc 1 (ecart (b), la regle est retiree)" "rc=1" "rc=$RC"
fi

# =====================================================================================
# Mutants opposables — copie de l'outil, jamais l'original. Rejet si cmp -s identique ou si
# bash -n echoue sur le mutant.
# =====================================================================================

# MUT-W — remplace RE par une regex a frontieres de mot (semantique -w). Sur C1 (angle mort
# <=250L), le mutant doit devenir rc 0 alors que l'original est rc 1.
MUT_W="$TMP/mut-w.sh"
awk '{
  if ($0 ~ /^RE=/) print "RE=\x27(^|[^[:alnum:]_])250([^[:alnum:]_]|$)\x27";
  else print $0
}' "$TARGET" > "$MUT_W"
if cmp -s "$MUT_W" "$TARGET"; then
  ko "MUT-W mutant distinct de l'original" "fichiers differents" "cmp -s identique"
elif ! bash -n "$MUT_W" 2>/dev/null; then
  ko "MUT-W syntaxe valide (bash -n)" "bash -n reussit" "bash -n echoue"
else
  ORIG_RC=0; bash "$TARGET" "$C1_REPO" >/dev/null 2>&1 || ORIG_RC=$?
  MUT_RC=0; bash "$MUT_W" "$C1_REPO" >/dev/null 2>&1 || MUT_RC=$?
  if [ "$MUT_RC" -eq 0 ] && [ "$ORIG_RC" -eq 1 ]; then
    ok "MUT-W tue : mutant rc=0 vs original rc=1 sur la fixture <=250L (angle mort -w)"
  else
    ko "MUT-W tue : mutant rc=0 vs original rc=1 sur la fixture <=250L (angle mort -w)" "mutant=0 original=1" "mutant=$MUT_RC original=$ORIG_RC"
  fi
fi

# MUT-X — neutralise la condition d'exclusion ([[ $path == $glob ]] toujours fausse). Sur C3
# (exclusion d'archive), le mutant doit devenir rc 1 alors que l'original est rc 0.
MUT_X="$TMP/mut-x.sh"
awk '{
  if ($0 ~ /if \[\[ "\$path" == \$glob \]\]; then/) print "    if false; then";
  else print $0
}' "$TARGET" > "$MUT_X"
if cmp -s "$MUT_X" "$TARGET"; then
  ko "MUT-X mutant distinct de l'original" "fichiers differents" "cmp -s identique"
elif ! bash -n "$MUT_X" 2>/dev/null; then
  ko "MUT-X syntaxe valide (bash -n)" "bash -n reussit" "bash -n echoue"
else
  ORIG_RC=0; bash "$TARGET" "$C3_REPO" >/dev/null 2>&1 || ORIG_RC=$?
  MUT_RC=0; bash "$MUT_X" "$C3_REPO" >/dev/null 2>&1 || MUT_RC=$?
  if [ "$MUT_RC" -eq 1 ] && [ "$ORIG_RC" -eq 0 ]; then
    ok "MUT-X tue : mutant rc=1 vs original rc=0 sur la fixture d'archive (exclusion neutralisee)"
  else
    ko "MUT-X tue : mutant rc=1 vs original rc=0 sur la fixture d'archive (exclusion neutralisee)" "mutant=1 original=0" "mutant=$MUT_RC original=$ORIG_RC"
  fi
fi

echo "== resultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
