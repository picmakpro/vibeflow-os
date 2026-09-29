#!/usr/bin/env bash
# test-check-method-budget.sh — Suite de check-method-budget.sh (budgets de méthode, v2.67.0).
#
#   S1/S2 — STATE sous et au-dessus du budget ; S3 — STATE de workstream compté aussi
#   S4 — budget surchargé par l'environnement ; S5 — pas de .planning : non applicable, rend 0
#   S6 — workstreams/ illisible : NON VÉRIFIABLE dit, rc 2 sous --strict (jamais un 0 de complaisance)
#   W1 — worktrees sous le budget ; W2 — dépassement ; W3 — RANGEABLE (branche intégrée)
#   W4 — worktree neuf (sans commit) jamais dit RANGEABLE ; W5 — ORPHELIN (dossier supprimé)
#   W6 — lab multi-dépôts : worktree frère compté UNE fois, pas comme un dépôt de plus
#   X1 — sans --strict un dépassement rend 0 ; X2 — avec --strict il rend 1 ; X3 — arguments
#        et budgets invalides rendent 64 ; X4 — lecture seule : rien n'est supprimé
#   B1/B2 — branche locale mergée et travaillée / neuve ; S1/S2 — stash sans propriétaire / message
#        illisible ; M1-M3 — mémoires hors git, hors index, sonde zz-probe-* ; R1-R6 — branches
#        distantes : owner, jamais celles d'autrui, gh absent / en échec / JSON invalide, --no-remote ;
#        X4 étendu — refs, stash et mémoires identiques avant/après ; M1-M3 (mutants) — QUAL-01
#   Q5 — anti-vert-à-vide
#
# Convention du dossier : set -uo pipefail sans -e, mktemp -d + trap EXIT, fixtures jetables.

set -uo pipefail
cd "$(dirname "$0")/../.."
CHECK="$(pwd)/scripts/check-method-budget.sh"

# Chemin réel (/var -> /private/var sous macOS), comme git le rend. Jamais `cd "$(mktemp -d)"` en
# une fois : si mktemp échoue, cd "" reste sur place et le trap effacerait le dossier courant.
TMP_RAW="$(mktemp -d)" || exit 1
[ -n "$TMP_RAW" ] && [ -d "$TMP_RAW" ] || exit 1
WORK_DIR="$(cd "$TMP_RAW" && pwd -P)" || exit 1
trap 'rm -rf "$WORK_DIR"' EXIT
unset VF_STATE_BUDGET_KB VF_WORKTREE_BUDGET

PASS=0; FAIL=0
assert()     { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): $3"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
refute()     { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     inattendu: $3"; echo "     obtenu:  $2"; FAIL=$((FAIL+1)); fi; }
assert_rc()  { if [ "$2" -eq "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (rc $2 ≠ $3)"; FAIL=$((FAIL+1)); fi; }

G() { git -c user.name=t -c user.email=t@t -c init.defaultBranch=main "$@" >/dev/null 2>&1; }
mk_repo() { # <dir> : dépôt avec un commit sur main
  mkdir -p "$1" && G -C "$1" init && echo a > "$1/a" && G -C "$1" add a && G -C "$1" commit -m init
}
fill() { # <fichier> <Ko>
  mkdir -p "$(dirname "$1")"; head -c $(( $2 * 1024 )) /dev/zero | tr '\0' 'x' > "$1"
}

echo "=== S — budget du fichier d'état ==="
LAB="$WORK_DIR/lab"; mk_repo "$LAB"
fill "$LAB/.planning/STATE.md" 4
OUT="$(bash "$CHECK" --root "$LAB")"; RC=$?
assert "S1 — STATE de 4 Ko dans le budget de 8" "$OUT" "STATE ok"
assert_rc "S1 — rend 0" "$RC" 0
fill "$LAB/.planning/STATE.md" 20
OUT="$(bash "$CHECK" --root "$LAB")"
assert "S2 — STATE de 20 Ko : dépassement signalé" "$OUT" "STATE DÉPASSÉ"
assert "S2 — le constat dit quoi faire" "$OUT" ".planning/archives/state/"
fill "$LAB/.planning/STATE.md" 2
fill "$LAB/.planning/workstreams/ws1/STATE.md" 12
OUT="$(bash "$CHECK" --root "$LAB")"
assert "S3 — STATE de workstream compté" "$OUT" "workstreams/ws1/STATE.md fait 12 Ko"
OUT="$(VF_STATE_BUDGET_KB=16 bash "$CHECK" --root "$LAB")"
refute "S4 — budget relevé à 16 Ko par l'environnement : plus de dépassement" "$OUT" "DÉPASSÉ"
mkdir -p "$LAB/.planning"; rm -rf "$LAB/.planning/workstreams"; echo x > "$LAB/.planning/workstreams"
OUT="$(bash "$CHECK" --root "$LAB" 2>/dev/null)"; RC=$?
assert "S6 — workstreams/ illisible (fichier) : non vérifiable, dit" "$OUT" "NON VÉRIFIABLE"
assert_rc "S6 — sans --strict : rend 0" "$RC" 0
bash "$CHECK" --root "$LAB" --strict >/dev/null 2>&1; assert_rc "S6 — avec --strict : rend 2, jamais 0" "$?" 2
rm -rf "$LAB/.planning"
OUT="$(bash "$CHECK" --root "$LAB")"; RC=$?
assert "S5 — pas de .planning : non applicable" "$OUT" "non applicable"
assert_rc "S5 — rend 0" "$RC" 0

echo ""
echo "=== W — budget des worktrees ==="
G -C "$LAB" worktree add "$LAB/.claude/worktrees/w1" -b w1
OUT="$(bash "$CHECK" --root "$LAB")"
assert "W1 — un worktree : dans le budget" "$OUT" "en a 1 actifs (budget 3)"
for n in 2 3 4; do G -C "$LAB" worktree add "$LAB/.claude/worktrees/w$n" -b "w$n"; done
OUT="$(bash "$CHECK" --root "$LAB")"
assert "W2 — quatre worktrees : dépassement" "$OUT" "worktrees DÉPASSÉ"
echo b > "$LAB/.claude/worktrees/w2/b"; G -C "$LAB/.claude/worktrees/w2" add b; G -C "$LAB/.claude/worktrees/w2" commit -m b
G -C "$LAB" merge --ff-only w2
echo c > "$LAB/.claude/worktrees/w3/c"; G -C "$LAB/.claude/worktrees/w3" add c; G -C "$LAB/.claude/worktrees/w3" commit -m c
OUT="$(bash "$CHECK" --root "$LAB")"
assert "W3 — branche w2 intégrée dans main : RANGEABLE" "$OUT" "RANGEABLE : $LAB/.claude/worktrees/w2 [w2]"
refute "W3 — branche w3 non intégrée : jamais RANGEABLE" "$OUT" "RANGEABLE : $LAB/.claude/worktrees/w3"
refute "W4 — worktree neuf sans commit : jamais RANGEABLE" "$OUT" "RANGEABLE : $LAB/.claude/worktrees/w4"
assert "W4 — worktree neuf signalé comme tel" "$OUT" "w4 [w4] neuf, aucun commit"
rm -rf "$LAB/.claude/worktrees/w1"
OUT="$(bash "$CHECK" --root "$LAB")"
assert "W5 — dossier supprimé : ORPHELIN" "$OUT" "ORPHELIN : $LAB/.claude/worktrees/w1"
assert "W5 — l'orphelin ne compte pas dans les actifs" "$OUT" "en a 3 actifs"
G -C "$LAB" worktree add "$LAB/.claude/worktrees/w5" -b w5  # de nouveau 4 actifs, pour la série X
[ -d "$LAB/.claude/worktrees/w2" ] && X4=present || X4=absent
assert "X4 — lecture seule : le worktree rangeable est toujours là" "$X4" "present"

MULTI="$WORK_DIR/multi"; mk_repo "$MULTI/front"; mk_repo "$MULTI/back"
G -C "$MULTI/front" worktree add "$MULTI/front-wt-a" -b a
G -C "$MULTI/front" worktree add "$MULTI/front-wt-b" -b b
OUT="$(bash "$CHECK" --root "$MULTI")"
N_FRONT=$(printf '%s\n' "$OUT" | grep -c 'worktrees ok : .*front')
assert_rc "W6 — lab multi-dépôts : le dépôt front compté une seule fois" "$N_FRONT" 1
assert "W6 — ses deux worktrees frères sont bien comptés" "$OUT" "front en a 2 actifs"
assert "W6 — le dépôt back est vu" "$OUT" "back en a 0 actifs"

echo ""
echo "=== X — codes de sortie ==="
bash "$CHECK" --root "$LAB" >/dev/null; assert_rc "X1 — dépassement sans --strict : 0" "$?" 0
bash "$CHECK" --root "$LAB" --strict >/dev/null; assert_rc "X2 — dépassement avec --strict : 1" "$?" 1
bash "$CHECK" --root "$MULTI" --strict >/dev/null; assert_rc "X2b — dans les budgets avec --strict : 0" "$?" 0
bash "$CHECK" --inconnu >/dev/null 2>&1; assert_rc "X3a — argument inconnu : 64" "$?" 64
VF_WORKTREE_BUDGET=abc bash "$CHECK" --root "$LAB" >/dev/null 2>&1; assert_rc "X3b — budget non numérique : 64" "$?" 64
bash "$CHECK" --root "$WORK_DIR/absent" >/dev/null 2>&1; assert_rc "X3c — racine introuvable : 64" "$?" 64
OUT="$(bash "$CHECK" --root "$LAB" --quiet)"
refute "X5 — --quiet tait les constats conformes" "$OUT" "actif : $LAB/.claude/worktrees/w3"
assert "X5 — --quiet garde les dépassements" "$OUT" "DÉPASSÉ"

echo ""
echo "=== B/S/M/R — rangement (SOBR-01) ==="
# gh factice : jamais un appel réseau. Comportement piloté par FAKE_GH_USER, FAKE_GH_PRS, FAKE_GH_RC ;
# chaque appel est journalisé dans FAKE_GH_LOG (témoin : --no-remote ne doit laisser aucune trace).
FAKEBIN="$WORK_DIR/fakebin"; mkdir -p "$FAKEBIN"
cat > "$FAKEBIN/gh" <<'GHSTUB'
#!/bin/sh
echo "$*" >> "${FAKE_GH_LOG:-/dev/null}"
case "$1 $2" in
  "api user") [ -n "${FAKE_GH_USER:-}" ] && { echo "$FAKE_GH_USER"; exit 0; }; exit 1 ;;
  "pr list") [ -n "${FAKE_GH_PRS:-}" ] && cat "$FAKE_GH_PRS"; exit "${FAKE_GH_RC:-0}" ;;
esac
exit 1
GHSTUB
chmod +x "$FAKEBIN/gh"
export FAKE_GH_LOG="$WORK_DIR/gh.log"
PRS="$WORK_DIR/prs.json"
printf '%s' '[{"headRefName":"feat-own","number":7,"author":{"login":"sam"}},{"headRefName":"feat-willy","number":8,"author":{"login":"picmakpro"}}]' > "$PRS"

RG="$WORK_DIR/rg"; mk_repo "$RG"
G -C "$RG" checkout -b done; echo d > "$RG/d"; G -C "$RG" add d; G -C "$RG" commit -m d
G -C "$RG" checkout main; G -C "$RG" merge --ff-only done
G -C "$RG" branch fresh
# stash : un sur main (propriétaire vivant), un sur une branche supprimée, un au message illisible
echo m > "$RG/a"; G -C "$RG" stash push -m "sur-main"
G -C "$RG" checkout -b tmp; echo t > "$RG/a"; G -C "$RG" stash push -m "sur-tmp"
G -C "$RG" checkout main; G -C "$RG" branch -D tmp
# mémoires : non suivie, suivie hors index, sonde ignorée
mkdir -p "$RG/.claude/agent-memory/ag" "$RG/.claude/agent-memory/zz-probe-x"
echo "- [x](ok.md)" > "$RG/.claude/agent-memory/ag/MEMORY.md"; echo ok > "$RG/.claude/agent-memory/ag/ok.md"
echo bar > "$RG/.claude/agent-memory/ag/bar.md"
echo "zz-probe-*/" > "$RG/.gitignore"; echo probe > "$RG/.claude/agent-memory/zz-probe-x/p.md"
G -C "$RG" add .gitignore .claude/agent-memory/ag/MEMORY.md .claude/agent-memory/ag/ok.md .claude/agent-memory/ag/bar.md
G -C "$RG" commit -m mem
echo nonsuivi > "$RG/.claude/agent-memory/ag/nouveau.md"
# branches distantes intégrées : une de sam, une de picmakpro
G -C "$RG" update-ref refs/remotes/origin/feat-own main
G -C "$RG" update-ref refs/remotes/origin/feat-willy main

rg_run() { VF_BUDGET_GH="$FAKEBIN/gh" bash "${CHECK_UNDER:-$CHECK}" --root "$RG" "$@" 2>&1; }
snap() { { G_() { git -C "$RG" "$@"; }; G_ for-each-ref; G_ stash list; find "$RG/.claude/agent-memory" -type f | sort | xargs cat | cksum; } 2>&1; }

SNAP0="$(snap)"
OUT="$(FAKE_GH_PRS="$PRS" rg_run --owner sam)"; RC=$?
assert "B1 — branche travaillée et mergée : RANGEABLE" "$OUT" "RANGEABLE branche : done déjà intégrée dans main"
refute "B2 — branche neuve (reflog à 1 entrée) : rien" "$OUT" "RANGEABLE branche : fresh"
assert "S1 — stash sur branche supprimée : RANGEABLE" "$OUT" "RANGEABLE stash : stash@{0}"
refute "S1 — le stash d'une branche vivante (main) n'est pas rangeable" "$OUT" "RANGEABLE stash : stash@{1}"
assert "M1 — mémoire non suivie : hors git" "$OUT" "RANGEABLE mémoire hors git : .claude/agent-memory/ag/nouveau.md"
assert "M2 — mémoire suivie absente de son MEMORY.md : hors index" "$OUT" "RANGEABLE mémoire hors index : .claude/agent-memory/ag/bar.md"
refute "M2 — mémoire présente dans son index : rien" "$OUT" "hors index : .claude/agent-memory/ag/ok.md"
refute "M3 — zz-probe-* jamais rangeable" "$OUT" "RANGEABLE mémoire hors git : .claude/agent-memory/zz-probe"
assert "M3 — zz-probe-* constatée" "$OUT" "zz-probe-*"
[ "$(cat "$RG/.claude/agent-memory/zz-probe-x/p.md")" = probe ] && M3=intacte || M3=touchee
assert "M3 — la sonde reste intacte" "$M3" "intacte"
assert "R1 — PR de l'owner : À VALIDER" "$OUT" "À VALIDER branche distante : origin/feat-own (PR #7, sam)"
refute "R2 — PR de picmakpro, owner autre : jamais candidate" "$OUT" "À VALIDER branche distante : origin/feat-willy"
assert "R2 — le propriétaire est imprimé" "$OUT" "propriétaires : sam"
FAKE_GH_PRS="$PRS" rg_run --owner sam --strict >/dev/null; assert_rc "X6 — RANGEABLE/À VALIDER comptent en dépassement sous --strict : 1 (ou 2 si un stash est illisible)" "$?" 1

echo z >> "$RG/a"; SC="$(git -C "$RG" stash create)"; G -C "$RG" stash store -m "sans-branche" "$SC"
OUT="$(FAKE_GH_PRS="$PRS" rg_run --owner sam)"
assert "S2 — message de stash sans branche lisible : NON VÉRIFIABLE" "$OUT" "NON VÉRIFIABLE stash"
FAKE_GH_PRS="$PRS" rg_run --owner sam --strict >/dev/null; assert_rc "S2 — sous --strict : 2" "$?" 2
G -C "$RG" stash drop "stash@{0}"; git -C "$RG" checkout -q -- a

: > "$FAKE_GH_LOG"
OUT="$(FAKE_GH_PRS="$PRS" FAKE_GH_USER=sam rg_run)"
assert "R1b — sans --owner : login résolu par gh api user" "$OUT" "À VALIDER branche distante : origin/feat-own"
OUT="$(VF_BUDGET_GH="$WORK_DIR/absent/gh" bash "$CHECK" --root "$RG" --owner sam 2>&1)"
assert "R3 — gh absent : NON VÉRIFIABLE" "$OUT" "NON VÉRIFIABLE branches distantes : gh introuvable"
VF_BUDGET_GH="$WORK_DIR/absent/gh" bash "$CHECK" --root "$RG" --owner sam --strict >/dev/null 2>&1; assert_rc "R3 — gh absent sous --strict : 2" "$?" 2
OUT="$(FAKE_GH_PRS="$PRS" FAKE_GH_RC=1 rg_run --owner sam)"
assert "R3b — gh pr list échoue : NON VÉRIFIABLE, jamais liste vide" "$OUT" "NON VÉRIFIABLE branches distantes : gh pr list a échoué"
printf '%s' 'ceci n est pas du json' > "$WORK_DIR/bad.json"
OUT="$(FAKE_GH_PRS="$WORK_DIR/bad.json" rg_run --owner sam)"
assert "R4 — JSON invalide : NON VÉRIFIABLE" "$OUT" "NON VÉRIFIABLE branches distantes : réponse de gh illisible"
OUT="$(FAKE_GH_PRS="$PRS" rg_run --owner sam --no-remote)"
[ -s "$FAKE_GH_LOG" ] && NC=appele || NC=jamais
: > "$FAKE_GH_LOG"
OUT2="$(FAKE_GH_PRS="$PRS" rg_run --owner sam)"; [ -s "$FAKE_GH_LOG" ] && WIT=appele || WIT=jamais
assert "R5 — témoin positif : sans --no-remote, gh est appelé" "$WIT" "appele"
: > "$FAKE_GH_LOG"
OUT="$(FAKE_GH_PRS="$PRS" rg_run --owner sam --no-remote)"; [ -s "$FAKE_GH_LOG" ] && NC=appele || NC=jamais
assert "R5 — --no-remote : gh jamais appelé" "$NC" "jamais"
refute "R5 — --no-remote : aucune branche distante candidate" "$OUT" "À VALIDER"
OUT="$(FAKE_GH_PRS="$PRS" rg_run --owner sam --quiet)"
refute "R6 — --quiet tait le constat de non-propriétaire" "$OUT" "hors propriétaire"
assert "R6 — --quiet garde le À VALIDER" "$OUT" "À VALIDER branche distante"

FAKE_GH_PRS="$PRS" rg_run --owner sam --quiet >/dev/null
assert "X4 — lecture seule étendue : refs, stash et mémoires identiques avant/après" "$(snap)" "$SNAP0"
NDEL="$(grep -v '^[[:space:]]*#' "$CHECK" | grep -cE 'branch +-[dD]|stash +(drop|clear|pop)|push .*--delete|(^|[^a-z-])rm +-' || true)"
assert_rc "X4 — aucun verbe de suppression dans le script" "$NDEL" 0

# --- Mutants (QUAL-01) : chacun doit rougir l'assertion qu'il vise, et elle seule -----------------
MUTD="$WORK_DIR/mut"; mkdir -p "$MUTD"; SCRIPT="$CHECK"
make_mutant() { # <nom> <ligne exacte> <remplacement> : imprime le chemin ; 0 opposable, 1 identique, 2 syntaxe
  local out="$MUTD/$1.sh"
  MUT_OLD_ENV="$2" MUT_NEW_ENV="$3" awk '{ if ($0 == ENVIRON["MUT_OLD_ENV"]) print ENVIRON["MUT_NEW_ENV"]; else print }' "$SCRIPT" > "$out"
  cmp -s "$out" "$SCRIPT" && { echo "$out"; return 1; }
  bash -n "$out" 2>/dev/null || { echo "$out"; return 2; }
  echo "$out"
}
kills() { # <nom> <sortie sous mutant> <sous-chaîne dont la présence rougit l'assertion visée> <attendu de l'assertion>
  if [[ "$2" == *"$3"* ]]; then
    echo "  ✅ PASS — mutant tué : $1"
    echo "     assertion rouge sous mutant — attendu: $4"
    echo "     obtenu: $(printf '%s\n' "$2" | grep -F -- "$3" | sed -n 1p)"; PASS=$((PASS+1))
  else
    echo "  ❌ FAIL — mutant SURVIVANT : $1"; echo "     attendu (sous-chaîne présente sous mutant): $3"; FAIL=$((FAIL+1))
  fi
}
M1="$(make_mutant m1 '      is_owner "$a" || n=1' '      true || n=1')"; RM=$?
assert_rc "M1 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$M1" FAKE_GH_PRS="$PRS" rg_run --owner sam)"
kills "M1 filtre propriétaire neutralisé : R2 rougit (une PR de picmakpro devient candidate)" "$OUT" "À VALIDER branche distante : origin/feat-willy" "R2 — aucune ligne À VALIDER pour origin/feat-willy"
M2="$(make_mutant m2 '  json=$(cd "$repo" && "$GH_BIN" pr list --state merged --limit 200 --json headRefName,number,author 2>/dev/null); rc=$?' '  json=$(cd "$repo" && "$GH_BIN" pr list --state merged --limit 200 --json headRefName,number,author 2>/dev/null) || json="[]"; rc=0')"; RM=$?
assert_rc "M2 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$M2" FAKE_GH_PRS="$PRS" FAKE_GH_RC=1 rg_run --owner sam)"
refute "M2 — sous mutant, R3b n'affiche plus NON VÉRIFIABLE (échec lu comme liste vide)" "$OUT" "gh pr list a échoué"
kills "M2 échec gh lu comme liste vide : R3b rougit (attendu NON VÉRIFIABLE, obtenu silence)" "$OUT" "origin/feat-own : aucune PR mergée connue" "R3b — NON VÉRIFIABLE branches distantes : gh pr list a échoué"
M3="$(make_mutant m3 '  [ "$(git -C "$1" reflog show --format=%H "refs/heads/$2" -- 2>/dev/null | grep -c .)" -gt 1 ]' '  true')"; RM=$?
assert_rc "M3 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$M3" FAKE_GH_PRS="$PRS" rg_run --owner sam --no-remote)"
kills "M3 règle reflog retirée : B2 rougit (la branche neuve devient rangeable)" "$OUT" "RANGEABLE branche : fresh" "B2 — aucune ligne RANGEABLE branche : fresh"

echo ""
echo "=== Q5 — anti-vert-à-vide ==="
TOTAL=$((PASS+FAIL))
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
if [ "$TOTAL" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
