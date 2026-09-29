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
#   B1/B2 — branche locale mergée et travaillée / neuve ; ST1-ST5 — stash : branche supprimée, message
#        illisible, branche travaillée et intégrée (rangeable), branche neuve, branche vivante non
#        intégrée (jamais rangeables) ; M1-M3 — mémoires hors git, hors index, sonde zz-probe-* ;
#        R1-R6 — branches distantes : owner, jamais celles d'autrui, gh absent / en échec / JSON invalide,
#        --no-remote ; R7-R9 — jamais un fork, jamais une branche par défaut ou longue durée ;
#        R10 — gh muet (sortie vide, rc 0) ; RB1-RB3 — base de référence introuvable / orpheline :
#        NON VÉRIFIABLE, jamais un 0 de complaisance ; RV — À VALIDER seule source de dépassement ;
#        RH — origin/HEAD et origin/<base> jamais candidates
#   X7 — refs, stash et mémoires identiques avant/après ; X8 — preuve de lecture seule par liste blanche
#        (git, gh, commandes, redirections) et sept formes de suppression injectées qui la rougissent
#   MU1-MU18 — mutants (QUAL-01) : chacun rougit l'assertion qu'il vise, pour la bonne raison
#   L1 — étiquettes : aucun identifiant de cas réutilisé d'une section à l'autre
#   Q5 — anti-vert-à-vide
#
# Convention du dossier : set -uo pipefail sans -e, mktemp -d + trap EXIT, fixtures jetables.

set -uo pipefail
cd "$(dirname "$0")/../.."
CHECK="$(pwd)/scripts/check-method-budget.sh"
SELF="$(pwd)/scripts/tests/$(basename "$0")"

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

assert_line() { # <label> <sortie> <fragment de la ligne visée> <sous-chaîne attendue sur cette ligne>
  local l; l="$(printf '%s\n' "$2" | grep -F -- "$3")"; assert "$1" "$l" "$4"
}
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
printf '%s' '[{"headRefName":"feat-own","number":7,"author":{"login":"sam"},"baseRefName":"main"},{"headRefName":"feat-willy","number":8,"author":{"login":"picmakpro"},"baseRefName":"main"},{"headRefName":"fix-typo","number":21,"author":{"login":"sam"},"baseRefName":"main"},{"headRefName":"develop","number":30,"author":{"login":"sam"},"baseRefName":"main"},{"headRefName":"integration","number":40,"author":{"login":"sam"},"baseRefName":"main"},{"headRefName":"feat-z","number":41,"author":{"login":"sam"},"baseRefName":"integration"}]' > "$PRS"

RG="$WORK_DIR/rg"; mk_repo "$RG"
G -C "$RG" checkout -b done; echo d > "$RG/d"; G -C "$RG" add d; G -C "$RG" commit -m d
G -C "$RG" checkout main; G -C "$RG" merge --ff-only done
G -C "$RG" branch fresh
# stash : un sur main (propriétaire vivant), un sur une branche supprimée, un au message illisible
echo m > "$RG/a"; G -C "$RG" stash push -m "sur-main"
G -C "$RG" checkout -b tmp; echo t > "$RG/a"; G -C "$RG" stash push -m "sur-tmp"
G -C "$RG" checkout main; G -C "$RG" branch -D tmp
# stash sur une branche VIVANTE : travaillée et intégrée (done), neuve (fresh), travaillée non intégrée (live)
G -C "$RG" checkout done; echo x > "$RG/d"; G -C "$RG" stash push -m "sur-done"
G -C "$RG" checkout fresh; echo x > "$RG/d"; G -C "$RG" stash push -m "sur-fresh"
G -C "$RG" checkout -b live main; echo l > "$RG/l"; G -C "$RG" add l; G -C "$RG" commit -m l
echo y > "$RG/l"; G -C "$RG" stash push -m "sur-live"
G -C "$RG" checkout main
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
# jamais candidates : la ref d'un fork homonyme d'une PR de sam, une branche par défaut/longue durée
# (develop, sans PR sauf develop -> main), une branche base d'une PR mergée (integration)
G -C "$RG" update-ref refs/remotes/picmakpro/fix-typo main
G -C "$RG" update-ref refs/remotes/origin/develop main
G -C "$RG" update-ref refs/remotes/origin/integration main

rg_run() { VF_BUDGET_GH="$FAKEBIN/gh" bash "${CHECK_UNDER:-$CHECK}" --root "$RG" "$@" 2>&1; }
snap() { { G_() { git -C "$RG" "$@"; }; G_ for-each-ref; G_ stash list; find "$RG/.claude/agent-memory" -type f | sort | xargs cat | cksum; } 2>&1; }

SNAP0="$(snap)"
OUT="$(FAKE_GH_PRS="$PRS" rg_run --owner sam)"; RC=$?
assert "B1 — branche travaillée et mergée : RANGEABLE" "$OUT" "RANGEABLE branche : done déjà intégrée dans main"
refute "B2 — branche neuve (reflog à 1 entrée) : rien" "$OUT" "RANGEABLE branche : fresh"
assert_line "ST1 — stash sur branche supprimée : RANGEABLE" "$OUT" "« On tmp: sur-tmp »" "RANGEABLE stash"
refute "ST1b — le stash d'une branche vivante (main) n'est pas rangeable" "$OUT" "« On main: sur-main »"
assert_line "ST3 — stash sur une branche travaillée ET intégrée (done) : RANGEABLE" "$OUT" "« On done: sur-done »" "RANGEABLE stash"
refute "ST4 — stash sur une branche NEUVE (fresh, tête ancêtre de main) : jamais rangeable" "$OUT" "« On fresh: sur-fresh »"
refute "ST5 — stash sur une branche vivante NON intégrée (live) : jamais rangeable" "$OUT" "« On live: sur-live »"
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
refute "R7 — ref d'un fork (picmakpro/fix-typo) homonyme d'une PR de sam : jamais candidate" "$OUT" "À VALIDER branche distante : picmakpro/fix-typo"
assert "R7 — le constat dit pourquoi" "$OUT" "picmakpro/fix-typo : hors du remote origin"
refute "R8 — origin/develop (PR develop -> main de sam) : branche longue durée, jamais candidate" "$OUT" "À VALIDER branche distante : origin/develop"
assert "R8 — le constat dit pourquoi" "$OUT" "origin/develop : par défaut ou longue durée"
refute "R9 — origin/integration, base d'une PR mergée : jamais candidate" "$OUT" "À VALIDER branche distante : origin/integration"
assert "R9 — le constat dit pourquoi" "$OUT" "origin/integration : base d'une PR mergée"
FAKE_GH_PRS="$PRS" rg_run --owner sam --strict >/dev/null; assert_rc "X6 — RANGEABLE/À VALIDER comptent en dépassement sous --strict : 1 (ou 2 si un stash est illisible)" "$?" 1

echo z >> "$RG/a"; SC="$(git -C "$RG" stash create)"; G -C "$RG" stash store -m "sans-branche" "$SC"
OUT="$(FAKE_GH_PRS="$PRS" rg_run --owner sam)"
assert "ST2 — message de stash sans branche lisible : NON VÉRIFIABLE" "$OUT" "NON VÉRIFIABLE stash"
FAKE_GH_PRS="$PRS" rg_run --owner sam --strict >/dev/null; assert_rc "ST2 — sous --strict : 2" "$?" 2
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
assert "X7 — lecture seule étendue : refs, stash et mémoires identiques avant/après" "$(snap)" "$SNAP0"
M4_OUT="$(FAKE_GH_PRS="$PRS" rg_run --owner sam)"
refute "M4 — MEMORY.md n'est jamais 'hors index' de lui-même" "$M4_OUT" "hors index : .claude/agent-memory/ag/MEMORY.md"

# X8 — preuve de lecture seule par LISTE BLANCHE (et non liste noire de verbes) : git (option -C seule,
# sous-commandes lues), gh (api user, pr list, jamais -X/--method), aucune commande qui écrit ou supprime,
# aucune redirection vers autre chose que /dev/null ou un descripteur. Une forme de suppression jamais
# vue (git worktree prune, update-ref -d, reflog expire, push origin :x, gh api -X DELETE, rm) sort de la liste.
ro_violations() { # <script> : un écart par ligne ; rien = conforme
  local f="$1" code
  # Écartés avant lecture : lignes de commentaire, commentaires de fin de ligne (« # texte »), et le texte des
  # messages `flag "…"` / `say "…"` SANS substitution `$(…)` ni backtick (un message n'exécute rien ; un
  # message qui substitue reste lu). Une commande collée après un message (`flag "x"; rm y`) reste lue.
  code="$(grep -v '^[[:space:]]*#' "$f" | sed -E 's/(dossier absent, git worktree prune)//' \
    | sed -E 's/(flag|say) +"([^"$`]|\$[A-Za-z_{0-9])*"/\1 ""/g' | sed -E 's/[[:space:]]+#[[:space:]].*$//')"
  printf '%s\n' "$code" | grep -oE '(^|[^A-Za-z0-9_/-])git +-[^C ][^ ]*' | sed 's/^/option git hors -C : /'
  printf '%s\n' "$code" | grep -oE '(^|[^A-Za-z0-9_/-])git +(-C +("[^"]*"|[^ ]+) +)?[a-z][a-z-]*( +[a-z][a-z-]*)?' \
    | sed -E 's/^[^g]*git +//; s/^-C +("[^"]*"|[^ ]+) +//' \
    | grep -vxE 'rev-parse|symbolic-ref|for-each-ref|merge-base|ls-files|reflog show|stash list|worktree list' \
    | sed 's/^/sous-commande git hors liste blanche : /'
  printf '%s\n' "$code" | grep -oE '"\$GH_BIN".{0,14}' \
    | grep -vE '^"\$GH_BIN" (api user|pr list)( |$)' | grep -vE '^"\$GH_BIN"( *>|\)|$| *\|\|)' \
    | sed 's/^/appel gh hors liste blanche : /'
  printf '%s\n' "$code" | grep -E 'GH_BIN.*(^| )(-X|--method|-f|-F|--field|--raw-field|--input)( |=|$)' | sed 's/^/gh en écriture : /'
  printf '%s\n' "$code" | grep -E '(^|[;&|(]|\$\(|[^A-Za-z0-9_](then|else|do))[[:space:]]*gh +' | sed 's/^/gh nu : /'
  printf '%s\n' "$code" | grep -oE '(^|[;&|(]|\$\(|[^A-Za-z0-9_](then|else|do))[[:space:]]*(rm|mv|unlink|rmdir|shred|truncate|xargs|tee|dd|cp|ln|touch|mkdir)( |$)' | sed 's/^/commande qui écrit : /'
  printf '%s\n' "$code" | grep -E 'find .*(-delete|-exec)|sed +-[a-z]*i' | sed 's|^|find/sed en écriture : |'
  printf '%s\n' "$code" | grep -oE '>>? *[^ &>)]+' | grep -v '/dev/null' | sed 's/^/redirection vers un fichier : /'
}
NRO="$(ro_violations "$CHECK" | grep -c .)"
assert_rc "X8 — le script réel ne viole aucune règle de lecture seule (liste blanche)" "$NRO" 0
INJ="$WORK_DIR/inj.sh"; NINJ=0; NRED=0
while IFS= read -r form; do
  [ -n "$form" ] || continue
  { cat "$CHECK"; printf '%s\n' "$form"; } > "$INJ"
  n="$(ro_violations "$INJ" | grep -c .)"; NINJ=$((NINJ+1))
  if [ "$n" -ge 1 ]; then NRED=$((NRED+1)); echo "  ✅ PASS — X8 forme injectée rougie : $form  ($(ro_violations "$INJ" | sed -n 1p))"; PASS=$((PASS+1))
  else echo "  ❌ FAIL — X8 forme injectée NON détectée : $form"; FAIL=$((FAIL+1)); fi
done <<'INJEOF'
git -C "$repo" worktree prune
git worktree prune
git -C "$repo" update-ref -d refs/heads/x
git -C "$repo" branch --delete x
git -C "$repo" reflog expire --all
git -C "$repo" push origin :x
git -c core.x=1 branch -d x
"$GH_BIN" api -X DELETE repos/o/r/git/refs/heads/x
gh api -X DELETE repos/o/r/git/refs/heads/x
rm "$f"
if true; then rm x; fi
echo x > "$repo/fichier"
INJEOF
assert_rc "X8 — toutes les formes injectées ont été rejouées et rougies" "$NRED" "$NINJ"

# RB — base de référence introuvable / orpheline : NON VÉRIFIABLE bruyant, jamais un 0 de complaisance
run_at() { VF_BUDGET_GH="$FAKEBIN/gh" bash "${CHECK_UNDER:-$CHECK}" --root "$1" "${@:2}" 2>&1; }
RT="$WORK_DIR/rt"; mkdir -p "$RT"; G -C "$RT" init -b trunk; echo a > "$RT/a"; G -C "$RT" add a; G -C "$RT" commit -m init
G -C "$RT" checkout -b old; echo o > "$RT/o"; G -C "$RT" add o; G -C "$RT" commit -m o; G -C "$RT" checkout trunk; G -C "$RT" merge --ff-only old
OUT="$(FAKE_GH_PRS="$PRS" run_at "$RT" --owner sam)"; RC=$?
assert "RB1 — base introuvable (défaut trunk, ni main/master, ni origin/HEAD) : NON VÉRIFIABLE dit" "$OUT" "NON VÉRIFIABLE rangement : branche de référence introuvable"
refute "RB1 — jamais la fausse sortie « aucune intégrée »" "$OUT" "aucune"
assert_rc "RB1 — sans --strict : rend 0" "$RC" 0
FAKE_GH_PRS="$PRS" run_at "$RT" --owner sam --strict >/dev/null; assert_rc "RB2 — base introuvable sous --strict : 2, jamais 0" "$?" 2
RD="$WORK_DIR/rd"; mk_repo "$RD"; G -C "$RD" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/gone
OUT="$(FAKE_GH_PRS="$PRS" run_at "$RD" --owner sam)"
assert "RB3 — origin/HEAD vers un ref absent : NON VÉRIFIABLE dit" "$OUT" "ne désigne aucun commit"
FAKE_GH_PRS="$PRS" run_at "$RD" --owner sam --strict >/dev/null; assert_rc "RB3 — origin/HEAD orphelin sous --strict : 2" "$?" 2

# R10 — gh rend une sortie vide avec rc 0 : NON VÉRIFIABLE, jamais une liste vide
OUT="$(FAKE_GH_PRS= rg_run --owner sam)"
assert "R10 — gh muet (rc 0, aucune sortie) : NON VÉRIFIABLE dit" "$OUT" "n'a rien rendu"
refute "R10 — jamais lu comme liste vide" "$OUT" "aucune PR mergée connue"
FAKE_GH_PRS= rg_run --owner sam --strict >/dev/null; assert_rc "R10 — gh muet sous --strict : 2" "$?" 2

# RV — À VALIDER est ici la SEULE source de dépassement (aucune branche, stash, mémoire ni worktree rangeable)
RV="$WORK_DIR/rv"; mk_repo "$RV"; G -C "$RV" update-ref refs/remotes/origin/feat-own main
OUT="$(FAKE_GH_PRS="$PRS" run_at "$RV" --owner sam --strict)"; RC=$?
assert "RV — la seule ligne de constat est un À VALIDER" "$OUT" "À VALIDER branche distante : origin/feat-own"
refute "RV — aucune autre source de dépassement" "$OUT" "RANGEABLE"
assert_rc "RV — sous --strict, un À VALIDER seul rend 1" "$RC" 1

# RH — origin/HEAD et origin/<base> jamais candidates (un dépôt cloné les porte toujours)
RH="$WORK_DIR/rh"; mk_repo "$RH"; G -C "$RH" update-ref refs/remotes/origin/main main
G -C "$RH" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main; G -C "$RH" update-ref refs/remotes/origin/feat-own main
OUT="$(FAKE_GH_PRS="$PRS" run_at "$RH" --owner sam)"
assert "RH — témoin positif : gh est consulté, feat-own candidate" "$OUT" "À VALIDER branche distante : origin/feat-own"
refute "RH — origin/HEAD jamais examinée" "$OUT" "branche distante origin/HEAD"
refute "RH — origin/<base> jamais examinée" "$OUT" "branche distante origin/main"

# LAB : une branche déjà listée comme worktree n'est pas redite comme branche
OUT="$(run_at "$LAB" --no-remote)"
assert "B3 — témoin : le worktree w2 est RANGEABLE" "$OUT" "RANGEABLE : $LAB/.claude/worktrees/w2 [w2]"
refute "B3 — sa branche w2 n'est pas redite en doublon" "$OUT" "RANGEABLE branche : w2"

echo ""
echo "=== MU — mutants (QUAL-01) ==="
# Chacun doit rougir l'assertion qu'il vise, et elle seule -----------------
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

kills_absent() { # <nom> <sortie sous mutant> <sous-chaîne qui DEVRAIT figurer> <attendu de l'assertion>
  if [[ "$2" != *"$3"* ]]; then
    echo "  ✅ PASS — mutant tué : $1"
    echo "     assertion rouge sous mutant — attendu: $4"
    echo "     obtenu: (absent) $(printf '%s\n' "$2" | sed -n 1p)"; PASS=$((PASS+1))
  else
    echo "  ❌ FAIL — mutant SURVIVANT : $1"; echo "     la sous-chaîne attendue figure encore : $3"; FAIL=$((FAIL+1))
  fi
}
line_of() { # <préfixe de ligne> : imprime la ligne UNIQUE du script qui commence ainsi (sinon échec bruyant)
  local l n; l="$(P="$1" awk 'index($0, ENVIRON["P"]) == 1' "$SCRIPT")"; n="$(printf '%s\n' "$l" | grep -c .)"
  [ "$n" -eq 1 ] || { echo "line_of : $n lignes pour « $1 »" >&2; return 1; }
  printf '%s' "$l"
}
mut() { # <nom> <préfixe> <remplacement> : mutant sur la ligne unique ; même codes que make_mutant (3 = ligne introuvable)
  local old; old="$(line_of "$2")" || { echo "$MUTD/$1.sh"; return 3; }
  make_mutant "$1" "$old" "$3"
}
MU1="$(make_mutant m1 '      is_owner "$a" || n=1' '      true || n=1')"; RM=$?
assert_rc "MU1 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU1" FAKE_GH_PRS="$PRS" rg_run --owner sam)"
kills "MU1 filtre propriétaire neutralisé : R2 rougit (une PR de picmakpro devient candidate)" "$OUT" "À VALIDER branche distante : origin/feat-willy" "R2 — aucune ligne À VALIDER pour origin/feat-willy"
MU2="$(make_mutant m2 '  json=$(cd "$repo" && "$GH_BIN" pr list --state merged --limit 200 --json headRefName,number,author,baseRefName 2>/dev/null); rc=$?' '  json=$(cd "$repo" && "$GH_BIN" pr list --state merged --limit 200 --json headRefName,number,author,baseRefName 2>/dev/null) || json="[]"; rc=0')"; RM=$?
assert_rc "MU2 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU2" FAKE_GH_PRS="$PRS" FAKE_GH_RC=1 rg_run --owner sam)"
refute "MU2 — sous mutant, R3b n'affiche plus NON VÉRIFIABLE (échec lu comme liste vide)" "$OUT" "gh pr list a échoué"
kills "MU2 échec gh lu comme liste vide : R3b rougit (attendu NON VÉRIFIABLE, obtenu silence)" "$OUT" "origin/feat-own : aucune PR mergée connue" "R3b — NON VÉRIFIABLE branches distantes : gh pr list a échoué"
MU3="$(make_mutant m3 '  [ "$(git -C "$1" reflog show --format=%H "refs/heads/$2" -- 2>/dev/null | grep -c .)" -gt 1 ]' '  true')"; RM=$?
assert_rc "MU3 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU3" FAKE_GH_PRS="$PRS" rg_run --owner sam --no-remote)"
kills "MU3 règle reflog retirée : B2 rougit (la branche neuve devient rangeable)" "$OUT" "RANGEABLE branche : fresh" "B2 — aucune ligne RANGEABLE branche : fresh"

MU4="$(mut mu4 '    case "$short" in origin/*) name=' '    case "$short" in *) name="${short#*/}" ;; esac')"; RM=$?
assert_rc "MU4 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU4" FAKE_GH_PRS="$PRS" rg_run --owner sam)"
kills "MU4 rapprochement sans le remote : R7 rougit (la ref du fork devient candidate)" "$OUT" "À VALIDER branche distante : picmakpro/fix-typo" "R7 — aucune ligne À VALIDER pour picmakpro/fix-typo"
MU5="$(mut mu5 '      main|master|develop' '      ZZZ) continue ;;')"; RM=$?
assert_rc "MU5 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU5" FAKE_GH_PRS="$PRS" rg_run --owner sam)"
kills "MU5 branches longue durée retirées : R8 rougit" "$OUT" "À VALIDER branche distante : origin/develop" "R8 — aucune ligne À VALIDER pour origin/develop"
MU6="$(mut mu6 '    if printf '"'"'%s\n'"'"' "$tsv" | NAME="$name" awk -F' '    if false; then')"; RM=$?
assert_rc "MU6 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU6" FAKE_GH_PRS="$PRS" rg_run --owner sam)"
kills "MU6 base-d'une-PR retirée : R9 rougit" "$OUT" "À VALIDER branche distante : origin/integration" "R9 — aucune ligne À VALIDER pour origin/integration"
MU7="$(mut mu7 '  if [ -z "$base" ]; then UNVERIFIABLE=1' '  if [ -z "$base" ]; then :')"; RM=$?
assert_rc "MU7 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU7" FAKE_GH_PRS="$PRS" run_at "$RT" --owner sam --strict)"; RC7=$?
kills_absent "MU7 base introuvable non signalée : RB1 rougit" "$OUT" "NON VÉRIFIABLE rangement : branche de référence introuvable" "RB1 — NON VÉRIFIABLE rangement : branche de référence introuvable"
kills "MU7 — RB2 rougit aussi : sous --strict le mutant rend 0 au lieu de 2" "rc=$RC7" "rc=0" "RB2 — rc 2"
MU8="$(mut mu8 '  elif ! git -C "$repo" rev-parse -q --verify "$base^{commit}"' '  elif false; then :')"; RM=$?
assert_rc "MU8 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU8" FAKE_GH_PRS="$PRS" run_at "$RD" --owner sam)"
kills_absent "MU8 origin/HEAD orphelin non validé en amont : RB3 rougit (le libellé propre disparaît)" "$OUT" "ne désigne aucun commit" "RB3 — ne désigne aucun commit"
assert "MU8 — la couche de repli (rc de for-each-ref) tient seule : toujours NON VÉRIFIABLE" "$OUT" "NON VÉRIFIABLE branches locales : git for-each-ref"
SCRIPT="$MU8"
MU9="$(mut mu9 '  [ "$rc" -eq 0 ] || { UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches locales' '  :')"; RM=$?
SCRIPT="$MU9"
SCRIPT="$MU9"; MU10="$(mut mu10 '  [ "$rc" -eq 0 ] || { UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes' '  :')"; RM10=$?; SCRIPT="$CHECK"
assert_rc "MU9 opposable (sur MU8)" "$RM" 0
assert_rc "MU10 opposable (sur MU9)" "$RM10" 0
OUT="$(CHECK_UNDER="$MU9" FAKE_GH_PRS="$PRS" run_at "$RD" --owner sam)"
kills_absent "MU9 rc de for-each-ref (branches locales) retiré : le repli local disparaît" "$OUT" "NON VÉRIFIABLE branches locales" "RB3 — repli local"
assert "MU9 — le repli distant tient encore" "$OUT" "NON VÉRIFIABLE branches distantes : git for-each-ref"
OUT="$(CHECK_UNDER="$MU10" FAKE_GH_PRS="$PRS" run_at "$RD" --owner sam --strict)"; RC10=$?
kills_absent "MU10 rc de for-each-ref (branches distantes) retiré aussi : plus aucun constat" "$OUT" "NON VÉRIFIABLE" "RB3 — NON VÉRIFIABLE"
kills "MU10 — RB3 rougit : sous --strict le mutant rend 0 au lieu de 2 (0 de complaisance)" "rc=$RC10" "rc=0" "RB3 — rc 2"
MU11="$(mut mu11 '  case "$json" in *[![:space:]]*) ;;' '  case "$json" in *) ;; esac')"; RM=$?
assert_rc "MU11 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU11" FAKE_GH_PRS= rg_run --owner sam)"
kills_absent "MU11 sortie vide de gh lue comme liste vide : R10 rougit" "$OUT" "n'a rien rendu" "R10 — NON VÉRIFIABLE : gh pr list n'a rien rendu"
OLD12="$(line_of '      OVER=1; flag "À VALIDER branche distante')"
MU12="$(make_mutant mu12 "$OLD12" "${OLD12/OVER=1; /}")"; RM=$?
assert_rc "MU12 opposable" "$RM" 0
CHECK_UNDER="$MU12" FAKE_GH_PRS="$PRS" run_at "$RV" --owner sam --strict >/dev/null; RC12=$?
kills "MU12 À VALIDER ne compte plus en dépassement : RV rougit (rc 0 au lieu de 1, seule source)" "rc=$RC12" "rc=0" "RV — rc 1"
MU13="$(mut mu13 '"*) continue ;; esac' '"*) : ;; esac')"; RM=$?
assert_rc "MU13 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU13" run_at "$LAB" --no-remote)"
kills "MU13 branche déjà en worktree non écartée : B3 rougit (doublon)" "$OUT" "RANGEABLE branche : w2" "B3 — pas de RANGEABLE branche : w2"
MU14="$(mut mu14 '    [ "${f##*/}" = MEMORY.md ] && continue' '    :')"; RM=$?
assert_rc "MU14 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU14" FAKE_GH_PRS="$PRS" rg_run --owner sam)"
kills "MU14 exclusion de MEMORY.md retirée : M4 rougit" "$OUT" "hors index : .claude/agent-memory/ag/MEMORY.md" "M4 — aucune ligne hors index pour MEMORY.md"
MU15="$(mut mu15 '      HEAD) continue ;;' '      HEAD) : ;;')"; RM=$?
assert_rc "MU15 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU15" FAKE_GH_PRS="$PRS" run_at "$RH" --owner sam)"
kills "MU15 exclusion de origin/HEAD retirée : RH rougit" "$OUT" "branche distante origin/HEAD" "RH — origin/HEAD jamais examinée"
MU16="$(mut mu16 '      "$bshort") continue ;;' '      "$bshort") : ;;')"; RM=$?
assert_rc "MU16 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU16" FAKE_GH_PRS="$PRS" run_at "$RH" --owner sam)"
kills "MU16 exclusion de origin/<base> retirée : RH rougit" "$OUT" "branche distante origin/main" "RH — origin/<base> jamais examinée"
MU17="$(mut mu17 '         && git -C "$repo" merge-base --is-ancestor "refs/heads/$own"' '         && true; then')"; RM=$?
assert_rc "MU17 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU17" FAKE_GH_PRS="$PRS" rg_run --owner sam)"
kills "MU17 test d'intégration du stash neutralisé : ST5 rougit (le stash de live devient rangeable)" "$OUT" "« On live: sur-live »" "ST5 — aucune ligne RANGEABLE pour le stash de live"
MU18="$(mut mu18 '    elif [ -n "$base" ] && is_worked "$repo" "$own"' '    elif [ -n "$base" ] \')"; RM=$?
assert_rc "MU18 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU18" FAKE_GH_PRS="$PRS" rg_run --owner sam)"
kills "MU18 is_worked retiré du test de stash : ST4 rougit (le stash de fresh devient rangeable)" "$OUT" "« On fresh: sur-fresh »" "ST4 — aucune ligne RANGEABLE pour le stash de fresh"

echo ""
echo "=== L1 — étiquettes : un identifiant de cas ne migre pas d'une section à l'autre ==="
DUP="$(awk '/^echo "=== /{ sec++ } match($0, /(assert|assert_rc|assert_line|refute|kills|kills_absent) +"[A-Za-z0-9]+/) { t = substr($0, RSTART, RLENGTH); sub(/^[a-z_]+ +"/, "", t); if (!(t in first)) first[t] = sec; else if (first[t] != sec) print t }' "$SELF" | sort -u | tr '\n' ' ')"
assert_rc "L1 — aucun identifiant de cas réutilisé dans deux sections (obtenu : ${DUP:-aucun})" "$(printf '%s' "$DUP" | grep -c .)" 0

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
