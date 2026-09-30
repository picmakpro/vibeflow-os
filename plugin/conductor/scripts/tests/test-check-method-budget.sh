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
#        R11-R15 — PR de fork homonyme, liste des PR tronquée, dépôt de gh ≠ origin, origin sans URL, aucun
#        remote origin ; RL — branches locales par défaut / longue durée ; RF — base hors liste longue durée
#   X7 — refs, stash et mémoires identiques avant/après
#   RO — LECTURE SEULE PROUVÉE DYNAMIQUEMENT. Tout `git` et tout `gh` de la suite passent par une enveloppe
#        posée en tête du PATH qui journalise chaque argv et REFUSE (rc 97, jamais exécuté) toute
#        sous-commande ou option qu'elle ne sait pas lire seule ; RO1 : zéro refus sur toutes les fixtures
#        rejouées (+ RO2 témoin : chaque verbe attendu a bel et bien été vu passer) ; RO3 : arbre complet de
#        chaque fixture octet pour octet identique avant/après ; RO4 : une écriture injectée dans le script
#        sous une trentaine de formes qui PASSENT par le PATH (options entre -C et le verbe, symbolic-ref
#        nu, sh -c, eval, awk system(), perl, python, gh -XDELETE...) est refusée ; RO5 : les formes qui ne
#        passent PAS par le PATH (chemin absolu de git, redirection, sed w, awk print >, python open) sont
#        invisibles de l'enveloppe et ne sont attrapées que par RO3.
#        HORS DE PORTÉE, dit ici et nulle part contredit : une écriture hors des arbres de fixtures
#        (HOME, /tmp, réseau : jamais injectée avec un gh réel), un chemin du script que les fixtures
#        n'exécutent pas, une option `-c` qui lancerait un programme. X8 (liste blanche statique) n'est
#        gardé que comme FILET : il attrape les formes courantes, il ne prouve rien seul.
#   K1-K15 — budgets étendus (BACKLOG ouvert, index MEMORY.md, ROADMAP), plafonds de prose (STATE, entrée de BACKLOG),
#        ARCHIVAGE (--archive, --auto) : tracé (INDEX.tsv), relisible, jamais de commit, source commitée seule, portée
#        bornée au(x) compartiment(s) nommé(s) ou de la session, compartiment protégé intact, retour arrière par le blob
#   X9 — une seule région exemptée du filet statique d'écriture (la région vf-archive-writer du script)
#   MU1-MU24 — mutants (QUAL-01) : chacun rougit l'assertion qu'il vise, pour la bonne raison
#   MU25-MU29 — mutants de l'archivage : filtre de clos, refus de source sale, filtre --ws, session de --auto, protection
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
# REAL_GIT : le git réel, résolu AVANT de poser l'enveloppe en tête du PATH. La suite appelle git par la
# fonction `git` ci-dessous (jamais l'enveloppe) ; le script sous test, lui, appelle le git du PATH.
REAL_GIT="$(command -v git)"; export REAL_GIT
git() { "$REAL_GIT" "$@"; }
G() { git -c user.name=t -c user.email=t@t -c init.defaultBranch=main "$@" >/dev/null 2>&1; }
mk_repo() { # <dir> : dépôt avec un commit sur main
  mkdir -p "$1" && G -C "$1" init && echo a > "$1/a" && G -C "$1" add a && G -C "$1" commit -m init
}
fill() { # <fichier> <Ko>
  mkdir -p "$(dirname "$1")"; head -c $(( $2 * 1024 )) /dev/zero | tr '\0' 'x' > "$1"
}

# Enveloppes de lecture seule (voir RO). Créées avant tout appel du script ; le journal est global.
WRAPBIN="$WORK_DIR/wrapbin"; mkdir -p "$WRAPBIN"
RO_LOG="$WORK_DIR/ro.log"; : > "$RO_LOG"; export RO_LOG
cat > "$WRAPBIN/git" <<'GITWRAP'
#!/bin/bash
LOG="${RO_LOG:-/dev/null}"
argv="git"; for a in "$@"; do argv="$argv [$a]"; done
viol() { echo "VIOLATION $argv ($1)" >> "$LOG"; echo "git-ro : refusé ($1) : $argv" >&2; exit 97; }
args=("$@"); n=$#; i=0; sub=""
while [ "$i" -lt "$n" ]; do
  a="${args[$i]}"
  case "$a" in
    -C|--git-dir|--work-tree|--namespace) i=$((i+2)) ;;
    -c) kv="${args[$((i+1))]:-}"; key="$(printf '%s' "${kv%%=*}" | tr 'A-Z' 'a-z')"
        case "$key" in alias.*|core.pager|core.editor|core.fsmonitor|core.sshcommand|core.hookspath|core.askpass|core.gitproxy|credential.*|protocol.*|filter.*|*.helper|*.command|*.textconv) viol "option -c $key" ;; esac
        i=$((i+2)) ;;
    --git-dir=*|--work-tree=*|--namespace=*|--no-pager|-P|--bare|--no-replace-objects|--literal-pathspecs|--no-optional-locks) i=$((i+1)) ;;
    -*) viol "option globale inconnue $a" ;;
    *) sub="$a"; i=$((i+1)); break ;;
  esac
done
rest=("${args[@]:$i}")
symref_check() { local r np=0; for r in "${rest[@]}"; do case "$r" in -d|--delete|-m*|--) viol "symbolic-ref en écriture $r" ;; -q|--quiet|--short|--no-recurse|--recurse) ;; -*) viol "symbolic-ref option $r" ;; *) np=$((np+1)) ;; esac; done; [ "$np" -eq 1 ] || viol "symbolic-ref à $np argument(s)"; }
case "$sub" in
  rev-parse|for-each-ref|merge-base|ls-files) ;;
  symbolic-ref) symref_check ;;
  reflog) case "${rest[0]:-}" in show|exists) ;; *) viol "reflog ${rest[0]:-}" ;; esac ;;
  stash) case "${rest[0]:-}" in list|show) ;; *) viol "stash ${rest[0]:-}" ;; esac ;;
  worktree) [ "${rest[0]:-}" = list ] || viol "worktree ${rest[0]:-}" ;;
  config) case "${rest[0]:-}" in --get|--get-all|--get-regexp|--list|-l) ;; *) viol "config ${rest[0]:-}" ;; esac
          for r in "${rest[@]}"; do case "$r" in --unset*|--add|--replace-all|--edit|-e|--rename-section|--remove-section|--file=*|-f) viol "config option $r" ;; esac; done ;;
  *) viol "sous-commande $sub non autorisée" ;;
esac
echo "OK $argv" >> "$LOG"
exec "$REAL_GIT" "$@"
GITWRAP
cat > "$WRAPBIN/gh" <<'GHWRAP'
#!/bin/bash
LOG="${RO_LOG:-/dev/null}"
argv="gh"; for a in "$@"; do argv="$argv [$a]"; done
viol() { echo "VIOLATION $argv ($1)" >> "$LOG"; echo "gh-ro : refusé ($1) : $argv" >&2; exit 97; }
skip=0; pos=()
for a in "$@"; do
  if [ "$skip" -eq 1 ]; then skip=0; continue; fi
  case "$a" in
    -X*|--method|--method=*|-f*|-F*|--field|--field=*|--raw-field|--raw-field=*|--input|--input=*|-H*|--header*|--hostname*) viol "option d'écriture ou de forme $a" ;;
    --state|-s|--limit|-L|--json|--jq|-q|--repo|-R) skip=1 ;;
    --state=*|--limit=*|--json=*|--jq=*|--repo=*) ;;
    -*) viol "option inconnue $a" ;;
    *) pos+=("$a") ;;
  esac
done
case "${pos[0]:-} ${pos[1]:-}" in "api user"|"pr list"|"repo view") ;; *) viol "sous-commande ${pos[0]:-} ${pos[1]:-}" ;; esac
[ "${#pos[@]}" -eq 2 ] || viol "arguments en trop"
echo "OK $argv" >> "$LOG"
exec "$RO_GH_REAL" "$@"
GHWRAP
chmod +x "$WRAPBIN/git" "$WRAPBIN/gh"
export PATH="$WRAPBIN:$PATH"

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
  "repo view") echo "${FAKE_GH_REPO-o/r}"; exit "${FAKE_GH_REPO_RC:-0}" ;;
esac
exit 1
GHSTUB
chmod +x "$FAKEBIN/gh"
RO_GH_REAL="$FAKEBIN/gh"; export RO_GH_REAL
export FAKE_GH_LOG="$WORK_DIR/gh.log"
PRS="$WORK_DIR/prs.json"
printf '%s' '[{"headRefName":"feat-own","number":7,"author":{"login":"sam"},"baseRefName":"main","isCrossRepository":false},{"headRefName":"feat-willy","number":8,"author":{"login":"picmakpro"},"baseRefName":"main","isCrossRepository":false},{"headRefName":"fix-typo","number":21,"author":{"login":"sam"},"baseRefName":"main","isCrossRepository":false},{"headRefName":"develop","number":30,"author":{"login":"sam"},"baseRefName":"main","isCrossRepository":false},{"headRefName":"integration","number":40,"author":{"login":"sam"},"baseRefName":"main","isCrossRepository":false},{"headRefName":"feat-z","number":41,"author":{"login":"sam"},"baseRefName":"integration","isCrossRepository":false},{"headRefName":"foo","number":50,"author":{"login":"sam"},"baseRefName":"main","isCrossRepository":false},{"headRefName":"feat-forked","number":60,"author":{"login":"sam"},"baseRefName":"main","isCrossRepository":true}]' > "$PRS"
NPRS="$(jq length "$PRS")"
set_origin() { G -C "$1" config remote.origin.url "${2:-https://github.com/o/r.git}"; }

RG="$WORK_DIR/rg"; mk_repo "$RG"; set_origin "$RG"
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
# une branche origin/ de Willy dont une PR de sam, depuis un FORK, porte le même nom ; une sans aucune PR
G -C "$RG" update-ref refs/remotes/origin/feat-forked main
G -C "$RG" update-ref refs/remotes/origin/feat-nopr main

rg_run() { VF_BUDGET_GH="$WRAPBIN/gh" bash "${CHECK_UNDER:-$CHECK}" --root "$RG" "$@" 2>&1; }
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

# RB — base de référence introuvable / orpheline : NON VÉRIFIABLE bruyant, jamais un 0 de complaisance
run_at() { VF_BUDGET_GH="$WRAPBIN/gh" bash "${CHECK_UNDER:-$CHECK}" --root "$1" "${@:2}" 2>&1; }
RT="$WORK_DIR/rt"; mkdir -p "$RT"; G -C "$RT" init -b trunk; echo a > "$RT/a"; G -C "$RT" add a; G -C "$RT" commit -m init
G -C "$RT" checkout -b old; echo o > "$RT/o"; G -C "$RT" add o; G -C "$RT" commit -m o; G -C "$RT" checkout trunk; G -C "$RT" merge --ff-only old
OUT="$(FAKE_GH_PRS="$PRS" run_at "$RT" --owner sam)"; RC=$?
assert "RB1 — base introuvable (défaut trunk, ni main/master, ni origin/HEAD) : NON VÉRIFIABLE dit" "$OUT" "NON VÉRIFIABLE rangement : branche de référence introuvable"
refute "RB1 — jamais la fausse sortie « aucune intégrée »" "$OUT" "aucune"
assert_rc "RB1 — sans --strict : rend 0" "$RC" 0
FAKE_GH_PRS="$PRS" run_at "$RT" --owner sam --strict >/dev/null; assert_rc "RB2 — base introuvable sous --strict : 2, jamais 0" "$?" 2
RD="$WORK_DIR/rd"; mk_repo "$RD"; set_origin "$RD"; G -C "$RD" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/gone
OUT="$(FAKE_GH_PRS="$PRS" run_at "$RD" --owner sam)"
assert "RB3 — origin/HEAD vers un ref absent : NON VÉRIFIABLE dit" "$OUT" "ne désigne aucun commit"
FAKE_GH_PRS="$PRS" run_at "$RD" --owner sam --strict >/dev/null; assert_rc "RB3 — origin/HEAD orphelin sous --strict : 2" "$?" 2

# R10 — gh rend une sortie vide avec rc 0 : NON VÉRIFIABLE, jamais une liste vide
OUT="$(FAKE_GH_PRS= rg_run --owner sam)"
assert "R10 — gh muet (rc 0, aucune sortie) : NON VÉRIFIABLE dit" "$OUT" "n'a rien rendu"
refute "R10 — jamais lu comme liste vide" "$OUT" "aucune PR mergée connue"
FAKE_GH_PRS= rg_run --owner sam --strict >/dev/null; assert_rc "R10 — gh muet sous --strict : 2" "$?" 2

# RV — À VALIDER est ici la SEULE source de dépassement (aucune branche, stash, mémoire ni worktree rangeable)
RV="$WORK_DIR/rv"; mk_repo "$RV"; set_origin "$RV" "git@github.com:O/r.git"; G -C "$RV" update-ref refs/remotes/origin/feat-own main
OUT="$(FAKE_GH_PRS="$PRS" run_at "$RV" --owner sam --strict)"; RC=$?
assert "RV — la seule ligne de constat est un À VALIDER" "$OUT" "À VALIDER branche distante : origin/feat-own"
refute "RV — aucune autre source de dépassement" "$OUT" "RANGEABLE"
assert_rc "RV — sous --strict, un À VALIDER seul rend 1" "$RC" 1

# RH — origin/HEAD et origin/<base> jamais candidates (un dépôt cloné les porte toujours)
RH="$WORK_DIR/rh"; mk_repo "$RH"; set_origin "$RH"; G -C "$RH" update-ref refs/remotes/origin/main main
G -C "$RH" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main; G -C "$RH" update-ref refs/remotes/origin/feat-own main
OUT="$(FAKE_GH_PRS="$PRS" run_at "$RH" --owner sam)"
assert "RH — témoin positif : gh est consulté, feat-own candidate" "$OUT" "À VALIDER branche distante : origin/feat-own"
refute "RH — origin/HEAD jamais examinée" "$OUT" "branche distante origin/HEAD"
refute "RH — origin/<base> jamais examinée" "$OUT" "branche distante origin/main"

# R11 — une PR de sam depuis un FORK dont la tête porte le nom d'une branche origin/ de Willy : jamais candidate
OUT="$(FAKE_GH_PRS="$PRS" rg_run --owner sam)"
refute "R11 — PR de fork homonyme (origin/feat-forked) : jamais candidate" "$OUT" "À VALIDER branche distante : origin/feat-forked"
assert "R11 — le constat dit pourquoi" "$OUT" "origin/feat-forked : seule une PR de fork porte ce nom"
assert "R11 — témoin : une PR de la même auteure DANS origin reste candidate" "$OUT" "À VALIDER branche distante : origin/feat-own"
assert "R11b — sans PR du tout : aucune PR mergée connue" "$OUT" "origin/feat-nopr : aucune PR mergée connue"

# R12 — liste des PR mergées possiblement tronquée (nombre rendu = limite) : NON VÉRIFIABLE sur les branches sans PR connue
OUT="$(VF_BUDGET_PR_LIMIT="$NPRS" FAKE_GH_PRS="$PRS" rg_run --owner sam)"
assert "R12 — limite atteinte : la branche sans PR connue est NON VÉRIFIABLE" "$OUT" "NON VÉRIFIABLE branche distante : origin/feat-nopr"
assert "R12 — le constat nomme la limite" "$OUT" "limite $NPRS atteinte"
refute "R12 — jamais « aucune PR mergée connue » silencieux" "$OUT" "origin/feat-nopr : aucune PR mergée connue"
assert "R12 — une branche dont la PR est connue reste classée" "$OUT" "À VALIDER branche distante : origin/feat-own"
VF_BUDGET_PR_LIMIT="$NPRS" FAKE_GH_PRS="$PRS" rg_run --owner sam --strict >/dev/null; assert_rc "R12 — sous --strict : 2" "$?" 2
OUT="$(VF_BUDGET_PR_LIMIT=$((NPRS+1)) FAKE_GH_PRS="$PRS" rg_run --owner sam)"
refute "R12b — témoin : sous la limite, aucun NON VÉRIFIABLE de troncature" "$OUT" "limite"
assert "R12b — témoin : le constat ordinaire revient" "$OUT" "origin/feat-nopr : aucune PR mergée connue"
VF_BUDGET_PR_LIMIT=abc FAKE_GH_PRS="$PRS" rg_run --owner sam >/dev/null; assert_rc "R12c — limite non numérique : 64" "$?" 64

# R13 — le dépôt que gh interroge n'est pas celui de remote.origin.url
OUT="$(FAKE_GH_REPO=x/y FAKE_GH_PRS="$PRS" rg_run --owner sam)"
assert "R13 — gh interroge x/y, origin pointe o/r : NON VÉRIFIABLE" "$OUT" "gh interroge x/y mais remote.origin.url désigne o/r"
refute "R13 — aucune branche candidate sur des PR d'un autre dépôt" "$OUT" "À VALIDER"
FAKE_GH_REPO=x/y FAKE_GH_PRS="$PRS" rg_run --owner sam --strict >/dev/null; assert_rc "R13 — sous --strict : 2" "$?" 2
OUT="$(FAKE_GH_REPO=O/R FAKE_GH_PRS="$PRS" rg_run --owner sam)"
assert "R13b — témoin : même dépôt à la casse près : classé" "$OUT" "À VALIDER branche distante : origin/feat-own"
OUT="$(FAKE_GH_REPO_RC=1 FAKE_GH_PRS="$PRS" rg_run --owner sam)"
assert "R13c — gh repo view échoue : NON VÉRIFIABLE" "$OUT" "gh repo view a échoué"
OUT="$(FAKE_GH_REPO= FAKE_GH_PRS="$PRS" rg_run --owner sam)"
assert "R13d — gh repo view muet : NON VÉRIFIABLE" "$OUT" "gh repo view a échoué ou n'a rien rendu"
# R14 — des refs origin/ mais aucune URL de remote : le dépôt des PR n'est pas comparable
RU="$WORK_DIR/ru"; mk_repo "$RU"; G -C "$RU" update-ref refs/remotes/origin/feat-own main
OUT="$(FAKE_GH_PRS="$PRS" run_at "$RU" --owner sam)"
assert "R14 — origin sans URL : NON VÉRIFIABLE" "$OUT" "remote.origin.url absent ou illisible"
refute "R14 — jamais candidate sur un dépôt non comparé" "$OUT" "À VALIDER"
FAKE_GH_PRS="$PRS" run_at "$RU" --owner sam --strict >/dev/null; assert_rc "R14 — sous --strict : 2" "$?" 2

# R15 — aucun remote origin mais des refs distantes d'un autre remote : dit, jamais « aucune candidate »
RN="$WORK_DIR/rn"; mk_repo "$RN"; G -C "$RN" update-ref refs/remotes/picmakpro/feat-x main
OUT="$(FAKE_GH_PRS="$PRS" run_at "$RN" --owner sam --strict --quiet)"; RC=$?
assert "R15 — aucun remote origin, refs d'un autre remote : NON VÉRIFIABLE dit, même sous --quiet" "$OUT" "aucun remote origin, branches distantes non examinées"
assert "R15 — il nomme le remote rencontré" "$OUT" "picmakpro"
refute "R15 — jamais le trompeur « aucune candidate »" "$OUT" "aucune candidate"
assert_rc "R15 — sous --strict --quiet : 2, jamais un 0 muet" "$RC" 2
OUT="$(FAKE_GH_PRS="$PRS" run_at "$LAB" --owner sam)"
assert "R15b — témoin : aucune ref distante du tout, c'est dit tel quel" "$OUT" "aucune ref distante"
refute "R15b — et ce n'est pas un NON VÉRIFIABLE" "$OUT" "aucun remote origin"

# RL — la protection par défaut / longue durée vaut aussi pour les branches LOCALES
RL="$WORK_DIR/rl"; mk_repo "$RL"
for b in develop release/1.0 stable done2; do
  G -C "$RL" checkout -b "$b"; echo "$b" > "$RL/f"; G -C "$RL" add f; G -C "$RL" commit -m "$b"
  G -C "$RL" checkout main; G -C "$RL" merge --ff-only "$b"
done
OUT="$(run_at "$RL" --no-remote)"
assert "RL1 — témoin : une branche ordinaire travaillée et intégrée (done2) est RANGEABLE" "$OUT" "RANGEABLE branche : done2 déjà intégrée"
refute "RL1 — develop local intégré : jamais RANGEABLE" "$OUT" "RANGEABLE branche : develop"
refute "RL1 — release/1.0 local intégré : jamais RANGEABLE" "$OUT" "RANGEABLE branche : release/1.0"
refute "RL1 — stable local intégré : jamais RANGEABLE" "$OUT" "RANGEABLE branche : stable"
assert "RL1 — le constat dit pourquoi" "$OUT" "branche develop : par défaut ou longue durée"

# RF — la base de référence est HORS liste longue durée (origin/foo) : origin/foo n'est jamais candidate, et cela
# se MESURE (une PR de sam de tête foo existe ; sans l'exclusion elle la rendrait À VALIDER)
RF="$WORK_DIR/rf"; mk_repo "$RF"; set_origin "$RF"
G -C "$RF" update-ref refs/remotes/origin/foo main; G -C "$RF" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/foo
G -C "$RF" update-ref refs/remotes/origin/feat-own main
OUT="$(FAKE_GH_PRS="$PRS" run_at "$RF" --owner sam)"
assert "RF1 — témoin : base origin/foo, gh consulté, feat-own candidate" "$OUT" "À VALIDER branche distante : origin/feat-own"
refute "RF1 — la base elle-même (origin/foo, PR de tête foo par sam) : jamais candidate" "$OUT" "À VALIDER branche distante : origin/foo"

# LAB : une branche déjà listée comme worktree n'est pas redite comme branche
OUT="$(run_at "$LAB" --no-remote)"
assert "B3 — témoin : le worktree w2 est RANGEABLE" "$OUT" "RANGEABLE : $LAB/.claude/worktrees/w2 [w2]"
refute "B3 — sa branche w2 n'est pas redite en doublon" "$OUT" "RANGEABLE branche : w2"

echo ""
echo "=== K — budgets étendus, plafonds de prose, archivage (SOBR-06, SOBR-08) ==="
unset VF_BACKLOG_OPEN_BUDGET VF_MEMORY_INDEX_BUDGET_LINES VF_ROADMAP_BUDGET_KB VF_STATE_NOTE_MAX_LINES VF_BACKLOG_ENTRY_MAX_LINES VF_ARCHIVE_PROTECTED_WS VF_ARCHIVE_DATE GSD_WORKSTREAM
KD=2026-01-02
NVIOL_K0="$(grep -c '^VIOLATION' "$RO_LOG")"
krun() { VF_ARCHIVE_DATE="$KD" bash "${CHECK_UNDER:-$CHECK}" --root "$@" 2>&1; }   # krun <racine> <options...>
kcommit() { G -C "$1" add -A; G -C "$1" commit -m "${2:-plan}"; }
ktree() { ( cd "$1" && { find . -path ./.git -prune -o -type f -print | LC_ALL=C sort | while IFS= read -r f; do cksum "$f"; done; } ); }
bk_file() { # <fichier> <ouverts> <clos> : un BACKLOG de sujets à deux lignes
  local f="$1" i; mkdir -p "$(dirname "$f")"
  { echo "# Backlog"; echo
    for i in $(seq 1 "$2"); do echo "## Ouvert $i — DIFFÉRÉ (2026-01-01)"; echo "texte $i"; done
    for i in $(seq 1 "$3"); do echo "## Clos $i — CLOS (2026-01-02)"; echo "texte $i"; done; } > "$f"
}
state_file() { # <fichier> : STATE à frontmatter, trois sections gardées, deux sections d'historique (> 1 Ko)
  local f="$1" i; mkdir -p "$(dirname "$f")"
  { printf -- '---\ngsd_state_version: 1.0\nstatus: executing\n---\n\n# Project State\n\n## Project Reference\nref-corps\n\n## Current Position\nPhase: 41\npos-corps\n\n## Historique\n'
    for i in $(seq 1 40); do echo "hist-ligne-$i xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"; done
    printf '\n### Sous-titre\nsous-corps\n\n## Session Continuity\nsession-corps\n'; } > "$f"
}
mk_part() { # <dir> : racine + ws1 + ws2 + gouvernance, chacun avec un BACKLOG (ouvert + clos) et un STATE > 1 Ko ; commité
  local d="$1" w; mk_repo "$d"
  for w in ws1 ws2 gouvernance; do
    bk_file "$d/.planning/workstreams/$w/BACKLOG.md" 1 1; state_file "$d/.planning/workstreams/$w/STATE.md"
  done
  bk_file "$d/.planning/BACKLOG.md" 1 1; kcommit "$d"
}

# K1 — BACKLOG ouvert : les clos ne comptent pas
KB="$WORK_DIR/kb"; mk_repo "$KB"; bk_file "$KB/.planning/BACKLOG.md" 21 0; kcommit "$KB"
OUT="$(krun "$KB" --no-remote)"
assert "K1 — 21 sujets ouverts : DÉPASSÉ" "$OUT" "BACKLOG DÉPASSÉ : $KB/.planning/BACKLOG.md compte 21 sujets ouverts (budget 20)"
refute "K1 — aucune ligne de budget ne porte RANGEABLE" "$OUT" "RANGEABLE"
bk_file "$KB/.planning/BACKLOG.md" 20 5; kcommit "$KB"
OUT="$(krun "$KB" --no-remote)"
assert "K1 — 20 ouverts + 5 clos : dans le budget (les clos ne comptent pas)" "$OUT" "BACKLOG ok : $KB/.planning/BACKLOG.md compte 20 sujets ouverts"
refute "K1 — pas de DÉPASSÉ" "$OUT" "BACKLOG DÉPASSÉ"
assert "K1 — les 5 clos sont dits ARCHIVABLES" "$OUT" "ARCHIVABLE : $KB/.planning/BACKLOG.md porte 5 sujet(s) clos"
# K2 — index de mémoire
KM="$WORK_DIR/km"; mk_repo "$KM"; mkdir -p "$KM/.claude/agent-memory/ag"
seq 1 201 | sed 's/^/- entrée /' > "$KM/.claude/agent-memory/ag/MEMORY.md"; kcommit "$KM"
OUT="$(krun "$KM" --no-remote)"
assert "K2 — MEMORY.md à 201 lignes : DÉPASSÉ" "$OUT" "MEMORY DÉPASSÉ : $KM/.claude/agent-memory/ag/MEMORY.md fait 201 lignes (budget 200"
seq 1 200 | sed 's/^/- entrée /' > "$KM/.claude/agent-memory/ag/MEMORY.md"
OUT="$(krun "$KM" --no-remote)"
assert "K2 — 200 lignes : ok" "$OUT" "MEMORY ok : $KM/.claude/agent-memory/ag/MEMORY.md fait 200 lignes"
refute "K2 — 200 lignes : pas de DÉPASSÉ" "$OUT" "MEMORY DÉPASSÉ"
# K3 — ROADMAP de compartiment
KR="$WORK_DIR/kr"; mk_repo "$KR"; fill "$KR/.planning/workstreams/ws1/ROADMAP.md" 70
OUT="$(krun "$KR" --no-remote)"
assert "K3 — ROADMAP de compartiment de 70 Ko : DÉPASSÉ" "$OUT" "ROADMAP DÉPASSÉ : $KR/.planning/workstreams/ws1/ROADMAP.md fait 70 Ko (budget 64 Ko)"
refute "K3 — aucune ligne de budget ne porte RANGEABLE" "$OUT" "RANGEABLE"
fill "$KR/.planning/workstreams/ws1/ROADMAP.md" 10
OUT="$(krun "$KR" --no-remote)"; refute "K3 — 10 Ko : pas de DÉPASSÉ" "$OUT" "ROADMAP DÉPASSÉ"
# K4 — plafonds de prose
K4="$WORK_DIR/k4"; mk_repo "$K4"; mkdir -p "$K4/.planning"
{ printf -- '---\n'; for i in $(seq 1 15); do echo "cle$i: v"; done; printf -- '---\n\n# Etat\n\n'; for i in $(seq 1 13); do echo "ligne de prose $i"; done
  printf '\nsuite\n\n'; for i in $(seq 1 15); do echo "- puce $i"; done; } > "$K4/.planning/STATE.md"
{ echo "# Backlog"; echo; echo "## Long — DIFFÉRÉ"; for i in $(seq 1 40); do echo "l$i"; done; echo; echo "## Juste — DIFFÉRÉ"; for i in $(seq 1 39); do echo "l$i"; done; } > "$K4/.planning/BACKLOG.md"
kcommit "$K4"; OUT="$(krun "$K4" --no-remote)"
assert "K4 — paragraphe de STATE de 13 lignes : PROSE DÉPASSÉE (fichier:ligne)" "$OUT" "PROSE DÉPASSÉE : $K4/.planning/STATE.md:21 (paragraphe de 13 lignes, plafond 12)"
refute "K4 — frontmatter de 15 lignes et liste de 15 puces : jamais un paragraphe" "$OUT" "STATE.md:2 "
assert "K4 — entrée de BACKLOG de 41 lignes : PROSE DÉPASSÉE" "$OUT" "PROSE DÉPASSÉE : $K4/.planning/BACKLOG.md:3 (entrée « Long — DIFFÉRÉ » de 41 lignes, plafond 40)"
refute "K4 — entrée de 40 lignes : pas de dépassement" "$OUT" "Juste"
OUT="$(VF_STATE_NOTE_MAX_LINES=13 VF_BACKLOG_ENTRY_MAX_LINES=41 krun "$K4" --no-remote)"; refute "K4 — plafonds surchargés : plus de PROSE DÉPASSÉE" "$OUT" "PROSE DÉPASSÉE"
# K5 — --archive backlog : déplacé, tracé, relisible, rien d'autre
K5="$WORK_DIR/k5"; mk_repo "$K5"; bk_file "$K5/.planning/BACKLOG.md" 3 2; kcommit "$K5"
cp "$K5/.planning/BACKLOG.md" "$WORK_DIR/k5.before"; H5="$(git -C "$K5" rev-parse HEAD)"
OUT="$(krun "$K5" --no-remote --archive backlog)"; RC=$?
assert_rc "K5 — rc 0" "$RC" 0
assert "K5 — ARCHIVÉ nomme source, archive et blob" "$OUT" "ARCHIVÉ : .planning/BACKLOG.md → .planning/archives/backlog/racine-BACKLOG-$KD.md (2 unité(s)"
SRC5="$(cat "$K5/.planning/BACKLOG.md")"
refute "K5 — le sujet clos n'est plus au BACKLOG (hors ligne de pointeur)" "$(printf '%s\n' "$SRC5" | awk 'index($0, "<!-- vf-archive: ") != 1')" "## Clos 1"
assert "K5 — les sujets ouverts restent" "$SRC5" "## Ouvert 3 — DIFFÉRÉ"
assert "K5 — un pointeur à la place" "$SRC5" "<!-- vf-archive: .planning/archives/backlog/racine-BACKLOG-$KD.md"
A5="$K5/.planning/archives/backlog/racine-BACKLOG-$KD.md"
assert "K5 — l'archive commence par le sujet déplacé : aucun en-tête ajouté" "$(head -n 1 "$A5")" "## Clos 1 — CLOS"
refute "K5 — un sujet ouvert n'est jamais déplacé" "$(cat "$A5")" "## Ouvert"
assert_rc "K5 — l'archive fait exactement 4 lignes : aucune ligne ajoutée" "$(awk 'END { print NR }' "$A5")" 4
IDX5="$(sed -n 2p "$K5/.planning/archives/INDEX.tsv")"
assert "K5 — INDEX : en-tête à la ligne 1" "$(sed -n 1p "$K5/.planning/archives/INDEX.tsv")" "date	type	source	archive	ref	motif"
assert "K5 — INDEX : date, type, source, archive" "$IDX5" "$KD	backlog	.planning/BACKLOG.md	.planning/archives/backlog/racine-BACKLOG-$KD.md	"
REF5="$(printf '%s' "$IDX5" | cut -f5)"
assert_rc "K5 — HEAD inchangé : l'outil ne commite jamais" "$([ "$(git -C "$K5" rev-parse HEAD)" = "$H5" ] && echo 0 || echo 1)" 0
assert "K5 — le déplacement se voit au git status" "$(git -C "$K5" status --porcelain)" " M .planning/BACKLOG.md"
{ awk 'index($0, "<!-- vf-archive: ") != 1' "$K5/.planning/BACKLOG.md"; cat "$A5"; } | LC_ALL=C sort > "$WORK_DIR/k5.n"; git -C "$K5" cat-file blob "$REF5" | LC_ALL=C sort > "$WORK_DIR/k5.o"
assert_rc "K5 — lignes triées du blob = source sans pointeurs + archive (cmp -s)" "$(cmp -s "$WORK_DIR/k5.o" "$WORK_DIR/k5.n"; echo $?)" 0
# K11 (chemin --archive) — retour arrière
git -C "$K5" cat-file blob "$REF5" > "$WORK_DIR/k5.restored"
assert_rc "K11 — --archive : le blob de l'INDEX restitue la source d'avant (cmp -s)" "$(cmp -s "$WORK_DIR/k5.restored" "$WORK_DIR/k5.before"; echo $?)" 0
# K6 — ROADMAP : blocs <details> déplacés au-delà du budget, rien en deçà
mk_roadmap() { { echo "# Roadmap"; echo; echo "<details>"; echo "<summary>✅ jalon A -- SHIPPED</summary>"; echo; for i in $(seq 1 50); do echo "phase A ligne $i xxxxxxxxxxxxxxxxxxxx"; done; echo; echo "</details>"; echo; echo "## Phases en cours"; echo "courant"; } > "$1/.planning/ROADMAP.md"; }
K6="$WORK_DIR/k6"; mk_repo "$K6"; mkdir -p "$K6/.planning"; mk_roadmap "$K6"; kcommit "$K6"; T6="$(ktree "$K6" | cksum)"
OUT="$(krun "$K6" --no-remote --archive roadmap)"
assert_rc "K6 — en deçà du budget : rien déplacé (arbre identique)" "$([ "$(ktree "$K6" | cksum)" = "$T6" ] && echo 0 || echo 1)" 0
refute "K6 — en deçà : pas d'ARCHIVÉ" "$OUT" "ARCHIVÉ"
OUT="$(VF_ROADMAP_BUDGET_KB=1 krun "$K6" --no-remote --archive roadmap)"
assert "K6 — au-delà : ARCHIVÉ" "$OUT" "ARCHIVÉ : .planning/ROADMAP.md → .planning/archives/roadmap/racine-ROADMAP-$KD.md (1 unité(s)"
SRC6="$(cat "$K6/.planning/ROADMAP.md")"
refute "K6 — le bloc <details> a quitté le ROADMAP" "$SRC6" "<details>"
assert "K6 — le pointeur porte le résumé du jalon (-- assaini)" "$SRC6" "— ✅ jalon A - SHIPPED -->"
assert "K6 — le reste du ROADMAP est intact" "$SRC6" "## Phases en cours"
assert "K6 — l'archive commence par <details> : aucun en-tête" "$(head -n 1 "$K6/.planning/archives/roadmap/racine-ROADMAP-$KD.md")" "<details>"
K6b="$WORK_DIR/k6b"; mk_repo "$K6b"; mkdir -p "$K6b/.planning"; printf '# R\n<details>\n<summary>x</summary>\nnon refermé\n%s\n' "$(head -c 2000 /dev/zero | tr '\0' 'x')" > "$K6b/.planning/ROADMAP.md"; kcommit "$K6b"; T6B="$(ktree "$K6b" | cksum)"
OUT="$(VF_ROADMAP_BUDGET_KB=1 krun "$K6b" --no-remote --archive roadmap)"
assert_rc "K6 — bloc <details> jamais refermé : rien déplacé (arbre identique)" "$([ "$(ktree "$K6b" | cksum)" = "$T6B" ] && echo 0 || echo 1)" 0
# K7 — STATE : frontmatter, titres et ligne ^Phase: gardés
K7="$WORK_DIR/k7"; mk_repo "$K7"; state_file "$K7/.planning/workstreams/ws1/STATE.md"; kcommit "$K7"
OUT="$(VF_STATE_BUDGET_KB=1 krun "$K7" --no-remote --archive state --ws ws1)"
S7="$(cat "$K7/.planning/workstreams/ws1/STATE.md")"
assert "K7 — ARCHIVÉ" "$OUT" "ARCHIVÉ : .planning/workstreams/ws1/STATE.md → .planning/archives/state/ws1-STATE-$KD.md"
assert_rc "K7 — le frontmatter est gardé (ligne 1 = ---, status: executing)" "$([ "$(sed -n 1p "$K7/.planning/workstreams/ws1/STATE.md")" = "---" ] && printf '%s' "$S7" | grep -q '^status: executing$'; echo $?)" 0
for t in "## Project Reference" "## Current Position" "## Historique" "### Sous-titre" "## Session Continuity"; do assert "K7 — titre gardé : $t" "$S7" "$t"; done
assert_rc "K7 — une seule ligne ^Phase:" "$(printf '%s\n' "$S7" | grep -c '^Phase:')" 1
for t in ref-corps pos-corps session-corps; do assert "K7 — corps de section gardée : $t" "$S7" "$t"; done
refute "K7 — l'historique a quitté le STATE" "$S7" "hist-ligne-1 "
refute "K7 — le corps du sous-titre aussi" "$S7" "sous-corps"
assert "K7 — l'historique est dans l'archive" "$(cat "$K7/.planning/archives/state/ws1-STATE-$KD.md")" "hist-ligne-40"
# K8 — source non commitée : rc 2, rien écrit (trois formes)
for form in modifiee indexee nonsuivie; do
  D="$WORK_DIR/k8$form"; mk_repo "$D"; bk_file "$D/.planning/BACKLOG.md" 1 1
  case "$form" in
    nonsuivie) ;;
    *) kcommit "$D"; echo "ajout non commité" >> "$D/.planning/BACKLOG.md"; [ "$form" = indexee ] && G -C "$D" add .planning/BACKLOG.md ;;
  esac
  cp "$D/.planning/BACKLOG.md" "$WORK_DIR/k8.$form.before"
  OUT="$(krun "$D" --no-remote --archive backlog)"; RC=$?
  assert_rc "K8 — source $form : rc 2" "$RC" 2
  assert "K8 — source $form : refus dit" "$OUT" "ARCHIVAGE REFUSÉ : .planning/BACKLOG.md"
  assert_rc "K8 — source $form : rien écrit (ni archive, ni INDEX, source identique)" "$([ ! -e "$D/.planning/archives" ] && cmp -s "$D/.planning/BACKLOG.md" "$WORK_DIR/k8.$form.before"; echo $?)" 0
done
# K9 — fichier illisible : NON VÉRIFIABLE, jamais un 0 de complaisance sous --strict
K9="$WORK_DIR/k9"; mk_repo "$K9"; mkdir -p "$K9/.planning/BACKLOG.md"
OUT="$(krun "$K9" --no-remote)"; RC=$?
assert "K9 — BACKLOG.md illisible : NON VÉRIFIABLE dit" "$OUT" "BACKLOG NON VÉRIFIABLE : $K9/.planning/BACKLOG.md"
assert_rc "K9 — sans --strict : rc 0" "$RC" 0
krun "$K9" --no-remote --strict >/dev/null; assert_rc "K9 — sous --strict : rc 2" "$?" 2
# K10 — seul le compartiment nommé est archivé ; arguments de portée
KP="$WORK_DIR/kp"; mk_part "$KP"; T2="$(ktree "$KP/.planning/workstreams/ws2" | cksum)"; TG="$(ktree "$KP/.planning/workstreams/gouvernance" | cksum)"
OUT="$(VF_STATE_BUDGET_KB=1 krun "$KP" --no-remote --archive state,backlog --ws ws1)"; RC=$?
assert "K10 — le compartiment nommé est archivé (backlog)" "$OUT" "ARCHIVÉ : .planning/workstreams/ws1/BACKLOG.md"
assert "K10 — le compartiment nommé est archivé (state)" "$OUT" "ARCHIVÉ : .planning/workstreams/ws1/STATE.md"
assert "K10 — la racine est toujours incluse" "$OUT" "ARCHIVÉ : .planning/BACKLOG.md"
assert_rc "K10 — ws2, au-delà du budget mais non nommé : intact (cksum avant/après)" "$([ "$(ktree "$KP/.planning/workstreams/ws2" | cksum)" = "$T2" ] && echo 0 || echo 1)" 0
assert_rc "K10 — gouvernance : intact" "$([ "$(ktree "$KP/.planning/workstreams/gouvernance" | cksum)" = "$TG" ] && echo 0 || echo 1)" 0
assert "K10 — ws2 : constat seul (DÉPASSÉ)" "$OUT" "STATE DÉPASSÉ : $KP/.planning/workstreams/ws2/STATE.md"
assert "K10 — ws2 : constat seul (ARCHIVABLE)" "$OUT" "ARCHIVABLE : $KP/.planning/workstreams/ws2/BACKLOG.md"
krun "$KP" --archive >/dev/null; assert_rc "K10 — --archive sans liste de types (dernier argument) : rc 64" "$?" 64
krun "$KP" --archive --no-remote >/dev/null; assert_rc "K10 — --archive suivi d'une option : rc 64" "$?" 64
krun "$KP" --archive foo >/dev/null; assert_rc "K10 — type inconnu : rc 64" "$?" 64
OUT="$(krun "$KP" --archive backlog --ws gouvernance)"; RC=$?
assert_rc "K10 — --ws sur un compartiment protégé : rc 64" "$RC" 64
assert "K10 — le refus dit pourquoi" "$OUT" "compartiment protégé"
krun "$KP" --archive backlog --ws nope >/dev/null; assert_rc "K10 — compartiment introuvable : rc 64" "$?" 64
krun "$KP" --auto --archive backlog >/dev/null; assert_rc "K10 — --auto et --archive s'excluent : rc 64" "$?" 64
krun "$KP" --ws ws1 >/dev/null; assert_rc "K10 — --ws seul : rc 64" "$?" 64
assert_rc "K10 — aucun des refus n'a écrit : gouvernance intact" "$([ "$(ktree "$KP/.planning/workstreams/gouvernance" | cksum)" = "$TG" ] && echo 0 || echo 1)" 0
# K12 — --auto : la session décide, l'outil exécute, même exécution rend l'état d'après
KA="$WORK_DIR/ka"; mk_part "$KA"; T2="$(ktree "$KA/.planning/workstreams/ws2" | cksum)"; TG="$(ktree "$KA/.planning/workstreams/gouvernance" | cksum)"
cp "$KA/.planning/workstreams/ws1/BACKLOG.md" "$WORK_DIR/ka.backlog.before"; cp "$KA/.planning/workstreams/ws1/STATE.md" "$WORK_DIR/ka.state.before"; HA="$(git -C "$KA" rev-parse HEAD)"
OUT="$(VF_STATE_BUDGET_KB=1 GSD_WORKSTREAM=ws1 krun "$KA" --no-remote --auto)"; RC=$?
assert_rc "K12 — rc 0" "$RC" 0
assert "K12 — SANS --archive : le BACKLOG de la session est archivé" "$OUT" "ARCHIVÉ : .planning/workstreams/ws1/BACKLOG.md"
assert "K12 — le STATE de la session, au-delà du budget, aussi" "$OUT" "ARCHIVÉ : .planning/workstreams/ws1/STATE.md"
assert_rc "K12 — ws2 intact" "$([ "$(ktree "$KA/.planning/workstreams/ws2" | cksum)" = "$T2" ] && echo 0 || echo 1)" 0
assert_rc "K12 — gouvernance intact" "$([ "$(ktree "$KA/.planning/workstreams/gouvernance" | cksum)" = "$TG" ] && echo 0 || echo 1)" 0
refute "K12 — la même exécution rend l'état d'après : plus d'ARCHIVABLE pour ws1" "$OUT" "ARCHIVABLE : $KA/.planning/workstreams/ws1"
assert "K12 — ... et ws2 reste constaté ARCHIVABLE" "$OUT" "ARCHIVABLE : $KA/.planning/workstreams/ws2/BACKLOG.md"
assert_rc "K12 — HEAD inchangé (jamais de commit)" "$([ "$(git -C "$KA" rev-parse HEAD)" = "$HA" ] && echo 0 || echo 1)" 0
# K11 (chemin --auto) — ligne INDEX puis blob = source d'avant, pour chacune des deux sources archivées
while IFS="$(printf '\t')" read -r _d _ty _src _arch _ref _mo; do
  [ "$_d" = date ] && continue
  case "$_src" in *ws1/BACKLOG.md) B="$WORK_DIR/ka.backlog.before" ;; *ws1/STATE.md) B="$WORK_DIR/ka.state.before" ;; *) continue ;; esac
  git -C "$KA" cat-file blob "$_ref" > "$WORK_DIR/ka.restored"
  assert_rc "K11 — --auto : INDEX $_src → blob = source d'avant (cmp -s)" "$(cmp -s "$WORK_DIR/ka.restored" "$B"; echo $?)" 0
done < "$KA/.planning/archives/INDEX.tsv"
assert_rc "K11 — --auto : deux lignes INDEX (backlog, state) pour ws1" "$(grep -c 'ws1/' "$KA/.planning/archives/INDEX.tsv")" 2
# K12b — dépôt partitionné sans compartiment résolu : rien déplacé
KU="$WORK_DIR/ku"; mk_part "$KU"; TU="$(ktree "$KU" | cksum)"
OUT="$(VF_STATE_BUDGET_KB=1 krun "$KU" --no-remote --auto)"
assert "K12b — partitionné, aucun compartiment résolu : ARCHIVAGE NON TENTÉ" "$OUT" "ARCHIVAGE NON TENTÉ : compartiment de session non résolu"
assert_rc "K12b — rien déplacé, racine comprise (arbre identique)" "$([ "$(ktree "$KU" | cksum)" = "$TU" ] && echo 0 || echo 1)" 0
OUT="$(VF_STATE_BUDGET_KB=1 krun "$KU" --no-remote --auto --ws ws2)"
assert "K12b — témoin : --ws nomme le compartiment, l'archivage a lieu" "$OUT" "ARCHIVÉ : .planning/workstreams/ws2/BACKLOG.md"
# K12c — dépôt non partitionné : la racine est la session
KN="$WORK_DIR/kn"; mk_repo "$KN"; bk_file "$KN/.planning/BACKLOG.md" 1 2; kcommit "$KN"
OUT="$(krun "$KN" --no-remote --auto)"
assert "K12c — non partitionné, sans GSD_WORKSTREAM : la racine est archivée" "$OUT" "ARCHIVÉ : .planning/BACKLOG.md"
# K13 — compartiment protégé : rien déplacé, racine comprise
KG="$WORK_DIR/kg"; mk_part "$KG"; TK="$(ktree "$KG" | cksum)"
OUT="$(VF_STATE_BUDGET_KB=1 GSD_WORKSTREAM=gouvernance krun "$KG" --no-remote --auto)"; RC=$?
assert "K13 — compartiment protégé de la session : ARCHIVAGE REFUSÉ" "$OUT" "ARCHIVAGE REFUSÉ : compartiment protégé gouvernance"
assert_rc "K13 — rien déplacé, racine comprise (arbre identique)" "$([ "$(ktree "$KG" | cksum)" = "$TK" ] && echo 0 || echo 1)" 0
assert_rc "K13 — rc 0 (refus d'un --auto : jamais 2)" "$RC" 0
OUT="$(VF_ARCHIVE_PROTECTED_WS=ws1,x VF_STATE_BUDGET_KB=1 GSD_WORKSTREAM=ws1 krun "$KG" --no-remote --auto)"
assert "K13 — la liste protégée est surchargeable" "$OUT" "ARCHIVAGE REFUSÉ : compartiment protégé ws1"
# K14 — --auto, source sale : rien déplacé, dit, ARCHIVABLE maintenu
KS="$WORK_DIR/ks"; mk_part "$KS"; echo "ajout non commité" >> "$KS/.planning/workstreams/ws1/BACKLOG.md"; cp "$KS/.planning/workstreams/ws1/BACKLOG.md" "$WORK_DIR/ks.before"
OUT="$(GSD_WORKSTREAM=ws1 krun "$KS" --no-remote --auto)"; RC=$?
assert "K14 — source sale : ARCHIVAGE REFUSÉ non commitée" "$OUT" "ARCHIVAGE REFUSÉ : .planning/workstreams/ws1/BACKLOG.md modifiée dans l'arbre de travail, non commitée, rien déplacé"
assert_rc "K14 — rien écrit pour cette source" "$(cmp -s "$KS/.planning/workstreams/ws1/BACKLOG.md" "$WORK_DIR/ks.before"; echo $?)" 0
assert "K14 — ARCHIVABLE maintenu" "$OUT" "ARCHIVABLE : $KS/.planning/workstreams/ws1/BACKLOG.md"
assert_rc "K14 — rc 0 sans --strict" "$RC" 0
GSD_WORKSTREAM=ws1 krun "$KS" --no-remote --auto --strict >/dev/null; assert_rc "K14 — sous --strict : rc 1, jamais 2" "$?" 1
# K15 — lecture seule de git/gh maintenue sous --archive/--auto (l'enveloppe n'a rien refusé) et verbes vus
assert_rc "K15 — zéro refus de l'enveloppe git/gh sur toute la section K" "$(( $(grep -c '^VIOLATION' "$RO_LOG") - NVIOL_K0 ))" 0
assert "K15 — témoin : l'archivage a bien appelé ls-files --error-unmatch via l'enveloppe" "$(grep -c '^OK git .*\[ls-files\] \[--error-unmatch\]' "$RO_LOG" | sed 's/^0$/jamais/; s/^[1-9][0-9]*$/vu/')" "vu"

echo ""
echo "=== RO — lecture seule prouvée DYNAMIQUEMENT ==="
tree_snap() { # <dir...> : noms, liens et octets de chaque arbre, dans un ordre stable
  local d f
  for d in "$@"; do
    ( cd "$d" && { find . | LC_ALL=C sort; find . -type f | LC_ALL=C sort | while IFS= read -r f; do cksum "$f"; done; } )
  done
}
FIXTURES=("$LAB" "$MULTI" "$RG" "$RT" "$RD" "$RV" "$RH" "$RF" "$RL" "$RN" "$RU")
replay_all() { # rejoue TOUTES les fixtures, sous toutes les options et sous chaque comportement de gh
  local repo mode
  for repo in "${FIXTURES[@]}"; do
    for mode in "" "--strict" "--quiet" "--no-remote" "--owner sam" "--strict --quiet --owner sam"; do
      FAKE_GH_PRS="$PRS" FAKE_GH_USER=sam VF_BUDGET_GH="$WRAPBIN/gh" bash "$CHECK" --root "$repo" $mode >/dev/null 2>&1
    done
  done
  for repo in "$RG" "$RV"; do
    FAKE_GH_PRS="$PRS" FAKE_GH_RC=1 VF_BUDGET_GH="$WRAPBIN/gh" bash "$CHECK" --root "$repo" --owner sam >/dev/null 2>&1
    FAKE_GH_PRS= VF_BUDGET_GH="$WRAPBIN/gh" bash "$CHECK" --root "$repo" --owner sam >/dev/null 2>&1
    FAKE_GH_PRS="$WORK_DIR/bad.json" VF_BUDGET_GH="$WRAPBIN/gh" bash "$CHECK" --root "$repo" --owner sam >/dev/null 2>&1
    FAKE_GH_REPO=x/y FAKE_GH_PRS="$PRS" VF_BUDGET_GH="$WRAPBIN/gh" bash "$CHECK" --root "$repo" --owner sam >/dev/null 2>&1
    FAKE_GH_REPO_RC=1 FAKE_GH_PRS="$PRS" VF_BUDGET_GH="$WRAPBIN/gh" bash "$CHECK" --root "$repo" --owner sam >/dev/null 2>&1
    VF_BUDGET_PR_LIMIT="$NPRS" FAKE_GH_PRS="$PRS" VF_BUDGET_GH="$WRAPBIN/gh" bash "$CHECK" --root "$repo" --owner sam --strict >/dev/null 2>&1
  done
}
T0="$(tree_snap "${FIXTURES[@]}" | cksum)"
NLOG0="$(grep -c . "$RO_LOG")"
replay_all
T1="$(tree_snap "${FIXTURES[@]}" | cksum)"
assert "RO3 — arbre complet des ${#FIXTURES[@]} fixtures identique avant/après toutes les exécutions rejouées (cksum)" "$T1" "$T0"
NVIOL="$(grep -c '^VIOLATION' "$RO_LOG")"
assert_rc "RO1 — zéro refus de l'enveloppe sur TOUS les appels git/gh de la suite (suite entière + rejeu)" "$NVIOL" 0
[ "$NVIOL" -eq 0 ] || grep '^VIOLATION' "$RO_LOG" | sed -n 1,5p
NOK="$(grep -c '^OK ' "$RO_LOG")"
[ "$NOK" -gt "$NLOG0" ] && GREW=oui || GREW=non
assert "RO2 — le rejeu a bien produit des appels journalisés (l'enveloppe est en ligne, pas un vert à vide)" "$GREW" "oui"
for verb in rev-parse symbolic-ref for-each-ref merge-base ls-files stash worktree reflog config; do
  N="$(grep -c "^OK git .*\[$verb\]" "$RO_LOG")"
  [ "$N" -ge 1 ] && SEEN=oui || SEEN=non
  assert "RO2 — verbe git « $verb » vu passer au moins une fois ($N)" "$SEEN" "oui"
done
for verb in "api\] \[user" "pr\] \[list" "repo\] \[view"; do
  N="$(grep -c "^OK gh .*\[$verb\]" "$RO_LOG")"
  [ "$N" -ge 1 ] && SEEN=oui || SEEN=non
  assert "RO2 — appel gh « $(printf '%s' "$verb" | tr -d '\\[]') » vu passer au moins une fois ($N)" "$SEEN" "oui"
done

# RO4/RO5 — une écriture injectée dans une COPIE du script (juste après `set -uo pipefail`, donc exécutée) doit être
# attrapée. A : passe par le PATH, l'enveloppe la refuse et la fixture reste intacte. B : ne passe pas par le PATH
# (chemin absolu, redirection, sed w, awk print >, python open) : l'enveloppe ne la voit pas, seule la comparaison de
# l'arbre la révèle. Aucun gh réel n'est jamais injecté en chemin absolu (ce serait un appel réseau).
INJ_ROOT="$WORK_DIR/inj"; export REPO
inject_run() { # <dossier d'enveloppes> <forme> : INJ_VIOL = nb de refus, INJ_CHANGED = 1 si l'arbre de la fixture a bougé
  local wd="$1" form="$2" scr="$INJ_ROOT/inj.sh" logf="$INJ_ROOT/run.log" before after
  rm -rf "$INJ_ROOT"; mkdir -p "$INJ_ROOT"; : > "$logf"
  REPO="$INJ_ROOT/repo"; mk_repo "$REPO"; G -C "$REPO" branch x
  G -C "$REPO" worktree add "$INJ_ROOT/wt" -b y; rm -rf "$INJ_ROOT/wt"
  FORM="$form" awk '{ print } /^set -uo pipefail$/ && !d { print ENVIRON["FORM"]; d = 1 }' "$CHECK" > "$scr"
  before="$(tree_snap "$REPO" | cksum)"
  RO_LOG="$logf" PATH="$wd:$PATH" VF_BUDGET_GH="$wd/gh" FAKE_GH_PRS="$PRS" bash "$scr" --root "$REPO" --no-remote --owner sam >/dev/null 2>&1
  after="$(tree_snap "$REPO" | cksum)"
  INJ_VIOL="$(grep -c '^VIOLATION' "$logf")"; [ "$before" = "$after" ] && INJ_CHANGED=0 || INJ_CHANGED=1
}
INJFORMS="$WORK_DIR/injforms.txt"
cat > "$INJFORMS" <<'INJEOF'
A|git -C "$REPO" worktree prune
A|git -C "$REPO" symbolic-ref -d refs/remotes/origin/HEAD
A|git -C "$REPO" symbolic-ref HEAD refs/heads/x
A|git -C "$REPO" -c a.b=c branch -D x
A|git -C "$REPO" --no-pager branch -D x
A|git -C "$REPO" -C "$REPO" branch -D x
A|git --git-dir="$REPO/.git" branch -D x
A|git --git-dir "$REPO/.git" update-ref -d refs/heads/x
A|git -C "$REPO" reflog expire --all
A|git -C "$REPO" push origin :x
A|git -C "$REPO" stash drop
A|git -C "$REPO" config remote.origin.url x
A|"git" -C "$REPO" branch -D x
A|G=git; $G -C "$REPO" branch -D x
A|echo "# pas un commentaire"; git -C "$REPO" branch -D x
A|sh -c 'git -C "$REPO" branch -D x'
A|eval 'git -C "$REPO" branch -D x'
A|awk 'BEGIN { system("git -C \"" ENVIRON["REPO"] "\" branch -D x") }'
A|perl -e 'system("git", "-C", $ENV{REPO}, "branch", "-D", "x")'
A|python3 -c 'import os, subprocess; subprocess.call(["git", "-C", os.environ["REPO"], "branch", "-D", "x"])'
A|gh api -X DELETE repos/o/r/git/refs/heads/x
A|gh api -XDELETE user
A|gh api user -fa=b
A|gh api repos/o/r/git/refs/heads/x --method DELETE
A|gh api user --jq .login >/dev/null; gh api -X DELETE repos/o/r/git/refs/heads/x
A|"${VF_BUDGET_GH:-gh}" api -X DELETE repos/o/r/git/refs/heads/x
A|gh pr merge 1
A|gh pr close 1
B|"$REAL_GIT" -C "$REPO" branch -D x
B|rm "$REPO/a"
B|echo x > "$REPO/fichier"
B|printf 'x\n' | sed -n "w $REPO/fuite"
B|awk 'BEGIN { print "x" > (ENVIRON["REPO"] "/fuite") }'
B|python3 -c 'import os; open(os.environ["REPO"] + "/fuite", "w").write("x")'
INJEOF
NA=0; NB=0
while IFS= read -r line; do
  [ -n "$line" ] || continue
  kind="${line%%|*}"; form="${line#*|}"
  inject_run "$WRAPBIN" "$form"
  if [ "$kind" = A ]; then
    NA=$((NA+1))
    if [ "$INJ_VIOL" -ge 1 ] && [ "$INJ_CHANGED" -eq 0 ]; then echo "  ✅ PASS — RO4 écriture injectée via le PATH refusée, fixture intacte : $form"; PASS=$((PASS+1))
    else echo "  ❌ FAIL — RO4 écriture injectée via le PATH NON refusée (refus $INJ_VIOL, fixture modifiée $INJ_CHANGED) : $form"; FAIL=$((FAIL+1)); fi
  else
    NB=$((NB+1))
    if [ "$INJ_VIOL" -eq 0 ] && [ "$INJ_CHANGED" -eq 1 ]; then echo "  ✅ PASS — RO5 écriture hors PATH invisible de l'enveloppe, révélée par la comparaison de l'arbre : $form"; PASS=$((PASS+1))
    else echo "  ❌ FAIL — RO5 forme hors PATH : attendu refus 0 et arbre modifié 1, obtenu refus $INJ_VIOL, arbre $INJ_CHANGED : $form"; FAIL=$((FAIL+1)); fi
  fi
done < "$INJFORMS"
assert "RO4 — bilan : $NA formes via le PATH et $NB formes hors PATH rejouées" "$NA/$NB" "/"
[ "$NA" -ge 25 ] && [ "$NB" -ge 5 ] && NBIL=suffisant || NBIL=insuffisant
assert "RO4 — le nombre de formes injectées n'a pas fondu" "$NBIL" "suffisant"

# X8 — FILET statique, requalifié. Une analyse statique d'un script bash ne ferme pas une classe par une liste
# de cas : ce filet lit le texte (git -C + verbe, gh, commandes qui écrivent, redirections) et attrape les
# formes COURANTES ; il laisse passer, entre autres, `symbolic-ref -d`, des options entre -C et le verbe,
# `/usr/bin/git`, `G=git; $G`, `gh -XDELETE`, un `#` dans une chaîne, sh -c / eval / awk system() / perl / python.
# Il n'AFFIRME donc PAS la lecture seule : la preuve est RO1-RO5 ci-dessus, mesurée sur des exécutions.
ro_violations() { # <script> : un écart par ligne ; rien = conforme
  local f="$1" code
  # Écartés avant lecture : lignes de commentaire, commentaires de fin de ligne (« # texte »), et le texte des
  # messages `flag "…"` / `say "…"` SANS substitution `$(…)` ni backtick (un message n'exécute rien ; un
  # message qui substitue reste lu). Une commande collée après un message (`flag "x"; rm y`) reste lue.
  code="$(grep -v '^[[:space:]]*#' "$f" | sed -E 's/(dossier absent, git worktree prune)//' \
    | sed -E 's/(flag|say) +"([^"$`]|\$[A-Za-z_{0-9])*"/\1 ""/g' | sed -E 's/[[:space:]]+#[[:space:]].*$//')"
  # La région `vf-archive-writer` (une seule, voir X9) est le SEUL endroit exempté des filets d'ÉCRITURE ; ses verbes
  # git et gh restent lus (liste blanche) par les mêmes filets que le reste du script.
  codew="$(awk '/^# >>> vf-archive-writer$/ { skip = 1; next } /^# <<< vf-archive-writer$/ { skip = 0; next } !skip' "$f" | grep -v '^[[:space:]]*#' | sed -E 's/(dossier absent, git worktree prune)//' \
    | sed -E 's/(flag|say) +"([^"$`]|\$[A-Za-z_{0-9])*"/\1 ""/g' | sed -E 's/[[:space:]]+#[[:space:]].*$//')"
  printf '%s\n' "$code" | grep -oE '(^|[^A-Za-z0-9_/-])git +-[^C ][^ ]*' | sed 's/^/option git hors -C : /'
  printf '%s\n' "$code" | grep -oE '(^|[^A-Za-z0-9_/-])git +(-C +("[^"]*"|[^ ]+) +)?[a-z][a-z-]*( +[a-z][a-z-]*)?' \
    | sed -E 's/^[^g]*git +//; s/^-C +("[^"]*"|[^ ]+) +//' \
    | grep -vxE 'rev-parse|symbolic-ref|for-each-ref|merge-base|ls-files|reflog show|stash list|worktree list|config' \
    | sed 's/^/sous-commande git hors liste blanche : /'
  printf '%s\n' "$code" | grep -oE '"\$GH_BIN".{0,14}' \
    | grep -vE '^"\$GH_BIN" (api user|pr list|repo view)( |$)' | grep -vE '^"\$GH_BIN"( *>|\)|$| *\|\|)' \
    | sed 's/^/appel gh hors liste blanche : /'
  printf '%s\n' "$code" | grep -E 'GH_BIN.*(^| )(-X|--method|-f|-F|--field|--raw-field|--input)( |=|$)' | sed 's/^/gh en écriture : /'
  printf '%s\n' "$code" | grep -E '(^|[;&|(]|\$\(|[^A-Za-z0-9_](then|else|do))[[:space:]]*gh +' | sed 's/^/gh nu : /'
  printf '%s\n' "$codew" | grep -oE '(^|[;&|(]|\$\(|[^A-Za-z0-9_](then|else|do))[[:space:]]*(rm|mv|unlink|rmdir|shred|truncate|xargs|tee|dd|cp|ln|touch|mkdir)( |$)' | sed 's/^/commande qui écrit : /'
  printf '%s\n' "$codew" | grep -E 'find .*(-delete|-exec)|sed +-[a-z]*i' | sed 's|^|find/sed en écriture : |'
  printf '%s\n' "$codew" | grep -oE '>>? *[^ &>)]+' | grep -v '/dev/null' | sed 's/^/redirection vers un fichier : /'
}
NRO="$(ro_violations "$CHECK" | grep -c .)"
assert_rc "X8 — filet statique : le script réel ne contient aucune forme courante d'écriture (ne prouve pas la lecture seule)" "$NRO" 0
INJ="$WORK_DIR/inj.sh"; NINJ=0; NRED=0
while IFS= read -r form; do
  [ -n "$form" ] || continue
  { cat "$CHECK"; printf '%s\n' "$form"; } > "$INJ"
  n="$(ro_violations "$INJ" | grep -c .)"; NINJ=$((NINJ+1))
  if [ "$n" -ge 1 ]; then NRED=$((NRED+1)); echo "  ✅ PASS — X8 filet statique, forme courante injectée rougie : $form  ($(ro_violations "$INJ" | sed -n 1p))"; PASS=$((PASS+1))
  else echo "  ❌ FAIL — X8 filet statique, forme courante NON détectée : $form"; FAIL=$((FAIL+1)); fi
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
assert_rc "X8 — filet statique : les formes courantes listées sont toutes attrapées (les autres ne le sont pas forcément : voir RO4/RO5)" "$NRED" "$NINJ"
# X9 — l'exemption de la région d'écriture est UNIQUE et bornée : une paire de marqueurs, ouverture avant fermeture.
NB9="$(grep -c '^# >>> vf-archive-writer$' "$CHECK")"; NE9="$(grep -c '^# <<< vf-archive-writer$' "$CHECK")"
assert_rc "X9 — une seule ouverture de région exemptée du filet d'écriture" "$NB9" 1
assert_rc "X9 — une seule fermeture" "$NE9" 1
assert_rc "X9 — l'ouverture précède la fermeture" "$([ "$(grep -n '^# >>> vf-archive-writer$' "$CHECK" | cut -d: -f1)" -lt "$(grep -n '^# <<< vf-archive-writer$' "$CHECK" | cut -d: -f1)" ]; echo $?)" 0


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
OLD2="$(line_of '  json=$(cd "$repo" && "$GH_BIN" pr list')"
MU2="$(make_mutant m2 "$OLD2" "${OLD2/; rc=\$?/ || json=\"[]\"; rc=0}")"; RM=$?
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
MU5="$(mut mu5 '    main|master|develop' '    ZZZ) return 0 ;;')"; RM=$?
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
SCRIPT="$MU9"; MU10="$(mut mu10 '  [ "$rc" -eq 0 ] || { UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : git for-each-ref --merged' '  :')"; RM10=$?; SCRIPT="$CHECK"
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
OUT="$(CHECK_UNDER="$MU16" FAKE_GH_PRS="$PRS" run_at "$RF" --owner sam)"
kills "MU16 exclusion de origin/<base> retirée : RF1 rougit (base hors liste longue durée : la PR de tête foo la rend candidate)" "$OUT" "À VALIDER branche distante : origin/foo" "RF1 — la base elle-même : jamais candidate"
MU17="$(mut mu17 '         && git -C "$repo" merge-base --is-ancestor "refs/heads/$own"' '         && true; then')"; RM=$?
assert_rc "MU17 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU17" FAKE_GH_PRS="$PRS" rg_run --owner sam)"
kills "MU17 test d'intégration du stash neutralisé : ST5 rougit (le stash de live devient rangeable)" "$OUT" "« On live: sur-live »" "ST5 — aucune ligne RANGEABLE pour le stash de live"
MU18="$(mut mu18 '    elif [ -n "$base" ] && is_worked "$repo" "$own"' '    elif [ -n "$base" ] \')"; RM=$?
assert_rc "MU18 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU18" FAKE_GH_PRS="$PRS" rg_run --owner sam)"
kills "MU18 is_worked retiré du test de stash : ST4 rougit (le stash de fresh devient rangeable)" "$OUT" "« On fresh: sur-fresh »" "ST4 — aucune ligne RANGEABLE pour le stash de fresh"

MU19="$(mut mu19 '      if [ -z "$origin_url" ]; then' '      if false; then')"; RM=$?
assert_rc "MU19 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU19" FAKE_GH_PRS="$PRS" run_at "$RN" --owner sam --strict --quiet)"; RC19=$?
kills_absent "MU19 absence de remote origin non signalée : R15 rougit (attendu NON VÉRIFIABLE, obtenu silence)" "$OUT" "aucun remote origin, branches distantes non examinées" "R15 — NON VÉRIFIABLE aucun remote origin"
kills "MU19 — R15 rougit aussi sous --strict --quiet : le mutant rend 0 au lieu de 2 (0 muet)" "rc=$RC19" "rc=0" "R15 — rc 2"
MU20="$(mut mu20 '    is_longlived "$b" && { say "branche $b' '    :')"; RM=$?
assert_rc "MU20 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU20" run_at "$RL" --no-remote)"
kills "MU20 protection longue durée retirée des branches locales : RL1 rougit (develop local devient RANGEABLE)" "$OUT" "RANGEABLE branche : develop" "RL1 — develop local jamais RANGEABLE"
MU21="$(mut mu21 '  trunc=0; [ "$nprs" -ge "$PR_LIMIT" ] && trunc=1' '  trunc=0')"; RM=$?
assert_rc "MU21 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU21" VF_BUDGET_PR_LIMIT="$NPRS" FAKE_GH_PRS="$PRS" rg_run --owner sam)"
kills_absent "MU21 troncature non détectée : R12 rougit (attendu NON VÉRIFIABLE origin/feat-nopr)" "$OUT" "NON VÉRIFIABLE branche distante : origin/feat-nopr" "R12 — NON VÉRIFIABLE branche distante : origin/feat-nopr"
kills "MU21 — R12 rougit aussi : « aucune PR mergée connue » redevient silencieux" "$OUT" "origin/feat-nopr : aucune PR mergée connue" "R12 — jamais « aucune PR mergée connue » sous limite atteinte"
OLD22="$(line_of '    auths=$(printf')"; PAT22=' && $5 == "false"'
MU22="$(make_mutant mu22 "$OLD22" "${OLD22/"$PAT22"/}")"; RM=$?
assert_rc "MU22 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU22" FAKE_GH_PRS="$PRS" rg_run --owner sam)"
kills "MU22 rapprochement par nom de tête seul : R11 rougit (la PR de fork rend origin/feat-forked candidate)" "$OUT" "À VALIDER branche distante : origin/feat-forked" "R11 — aucune ligne À VALIDER pour origin/feat-forked"
MU23="$(mut mu23 '  if [ "$(printf '"'"'%s'"'"' "$have"' '  if false; then')"; RM=$?
assert_rc "MU23 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU23" FAKE_GH_REPO=x/y FAKE_GH_PRS="$PRS" rg_run --owner sam)"
kills "MU23 comparaison gh/origin neutralisée : R13 rougit (des PR d'un autre dépôt rendent origin/feat-own candidate)" "$OUT" "À VALIDER branche distante : origin/feat-own" "R13 — aucune branche candidate sur des PR d'un autre dépôt"
MU24="$(mut mu24 '  case "$want" in */*) ;; *) UNVERIFIABLE=1; flag "NON VÉRIFIABLE branches distantes : remote.origin.url' '  :')"; RM=$?
assert_rc "MU24 opposable" "$RM" 0
OUT="$(CHECK_UNDER="$MU24" FAKE_GH_PRS="$PRS" run_at "$RU" --owner sam)"
kills_absent "MU24 URL d'origin absente non signalée en propre : R14 rougit (le libellé propre disparaît)" "$OUT" "remote.origin.url absent ou illisible" "R14 — remote.origin.url absent ou illisible"
assert "MU24 — la comparaison gh/origin tient seule : toujours NON VÉRIFIABLE, jamais À VALIDER" "$OUT" "gh interroge o/r mais remote.origin.url désigne"

# MU25-MU29 — mutants de l'archivage (K) : chacun rougit le cas K qu'il vise, pour la bonne raison
# Un mutant vit dans $MUTD : la politique de compartiments (sourcée depuis le dossier du script) doit y être voisine.
cp "$(pwd)/../planning-core/scripts/workstream-policy.sh" "$MUTD/workstream-policy.sh"
K_OLD_CLOS='  return (w == "CLOS" || w == "RÉSORBÉ" || w == "TRANCHÉ" || w == "ADOPTÉ" || w == "ADOPTÉE")'
MU25="$(make_mutant mu25 "$K_OLD_CLOS" '  return 0')"; RM=$?
assert_rc "MU25 opposable" "$RM" 0
KX="$WORK_DIR/kx5"; mk_repo "$KX"; bk_file "$KX/.planning/BACKLOG.md" 3 2; kcommit "$KX"
OUT="$(CHECK_UNDER="$MU25" krun "$KX" --no-remote --archive backlog)"
kills_absent "MU25 filtre de clos retiré : K5 rougit (attendu ARCHIVÉ, obtenu rien)" "$OUT" "ARCHIVÉ : .planning/BACKLOG.md" "K5 — ARCHIVÉ nomme source, archive et blob"
assert_rc "MU25 — K5 rougit aussi : le sujet clos reste au BACKLOG" "$(grep -c '^## Clos' "$KX/.planning/BACKLOG.md")" 2
K_OLD_SALE='  if why=$(src_unclean "$rel"); then archive_refuse "$rel $why, rien déplacé"; return 0; fi'
MU26="$(make_mutant mu26 "$K_OLD_SALE" '  :')"; RM=$?
assert_rc "MU26 opposable" "$RM" 0
KX="$WORK_DIR/kx8"; mk_repo "$KX"; bk_file "$KX/.planning/BACKLOG.md" 1 1; kcommit "$KX"; echo "ajout non commité" >> "$KX/.planning/BACKLOG.md"
OUT="$(CHECK_UNDER="$MU26" krun "$KX" --no-remote --archive backlog)"; RC26=$?
kills "MU26 refus de source sale retiré : K8 rougit (la source non commitée est archivée)" "$OUT" "ARCHIVÉ : .planning/BACKLOG.md" "K8 — ARCHIVAGE REFUSÉ, rien déplacé"
kills "MU26 — K8 rougit aussi : rc 0 au lieu de 2" "rc=$RC26" "rc=0" "K8 — rc 2"
K_OLD_TGT='  targets="racine|$ROOT/.planning"'
MU27="$(make_mutant mu27 "$K_OLD_TGT" '  targets="racine|$ROOT/.planning
$(printf "%s\n" "$WS_DIRS" | awk "NF { n = \$0; sub(/.*\\//, \"\", n); print n \"|\" \$0 }")"')"; RM=$?
assert_rc "MU27 opposable" "$RM" 0
KX="$WORK_DIR/kx10"; mk_part "$KX"
OUT="$(CHECK_UNDER="$MU27" krun "$KX" --no-remote --archive backlog --ws ws1)"
kills "MU27 filtre --ws retiré : K10 rougit (ws2, non nommé, est archivé)" "$OUT" "ARCHIVÉ : .planning/workstreams/ws2/BACKLOG.md" "K10 — ws2 intact, constat seul"
K_OLD_SES='    names="${GSD_WORKSTREAM:-}"'
MU28="$(make_mutant mu28 "$K_OLD_SES" '    names="$(printf "%s\n" "$WS_DIRS" | awk "NF && !/gouvernance/ { n = \$0; sub(/.*\\//, \"\", n); print n }")"')"; RM=$?
assert_rc "MU28 opposable" "$RM" 0
KX="$WORK_DIR/kx12"; mk_part "$KX"
OUT="$(GSD_WORKSTREAM=ws1 CHECK_UNDER="$MU28" krun "$KX" --no-remote --auto)"
kills "MU28 résolution de session retirée : K12 rougit (ws2 est archivé avec la session ws1)" "$OUT" "ARCHIVÉ : .planning/workstreams/ws2/BACKLOG.md" "K12 — ws2 intact"
K_OLD_PROT='    case ",$PROTECTED_WS," in'
MU29="$(make_mutant mu29 "$K_OLD_PROT" '    case ",zz," in')"; RM=$?
assert_rc "MU29 opposable" "$RM" 0
KX="$WORK_DIR/kx13"; mk_part "$KX"
OUT="$(GSD_WORKSTREAM=gouvernance CHECK_UNDER="$MU29" krun "$KX" --no-remote --auto)"
kills "MU29 protection du compartiment retirée : K13 rougit (gouvernance est archivé)" "$OUT" "ARCHIVÉ : .planning/workstreams/gouvernance/BACKLOG.md" "K13 — ARCHIVAGE REFUSÉ, rien déplacé"

# MW — mutants de l'ENVELOPPE : une enveloppe affaiblie laisse passer une écriture, RO4 le voit rougir
WMUT="$WORK_DIR/wmut"
mk_wmut() { # <nom> <fichier git|gh> <sed> : dossier d'enveloppes dont un seul fichier est affaibli
  local d="$WMUT/$1"; rm -rf "$d"; mkdir -p "$d"; cp "$WRAPBIN/git" "$WRAPBIN/gh" "$d/"
  sed -E "$3" "$WRAPBIN/$2" > "$d/$2"; chmod +x "$d/git" "$d/gh"
  cmp -s "$d/$2" "$WRAPBIN/$2" && { echo "$d"; return 1; }; echo "$d"
}
MW1="$(mk_wmut w1 git 's/^  symbolic-ref\) symref_check ;;/  symbolic-ref) : ;;/')"; RM=$?
assert_rc "MW1 opposable" "$RM" 0
inject_run "$MW1" 'git -C "$REPO" symbolic-ref HEAD refs/heads/x'
kills "MW1 enveloppe : symbolic-ref accepté nu : RO4 rougit (attendu refus, obtenu aucun refus)" "viol=$INJ_VIOL changed=$INJ_CHANGED" "viol=0 changed=1" "RO4 — git symbolic-ref HEAD refs/heads/x refusé"
MW2="$(mk_wmut w2 git 's/^  \*\) viol "sous-commande .*$/  *) ;;/')"; RM=$?
assert_rc "MW2 opposable" "$RM" 0
inject_run "$MW2" 'git -C "$REPO" -c a.b=c branch -D x'
kills "MW2 enveloppe : verbe inconnu accepté (liste noire au lieu de liste blanche) : RO4 rougit" "viol=$INJ_VIOL changed=$INJ_CHANGED" "viol=0 changed=1" "RO4 — git -c a.b=c branch -D x refusé"
MW3="$(mk_wmut w3 gh 's/viol "option d.écriture ou de forme [$]a"/:/')"; RM=$?
assert_rc "MW3 opposable" "$RM" 0
inject_run "$MW3" 'gh api -XDELETE user'
kills "MW3 enveloppe gh : -X collé accepté : RO4 rougit" "viol=$INJ_VIOL changed=$INJ_CHANGED" "viol=0 changed=0" "RO4 — gh api -XDELETE user refusé"
inject_run "$WRAPBIN" 'git -C "$REPO" symbolic-ref HEAD refs/heads/x'
assert "MW — témoin : la même forme est bien refusée par l'enveloppe intacte" "viol=$INJ_VIOL changed=$INJ_CHANGED" "viol=1 changed=0"

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
