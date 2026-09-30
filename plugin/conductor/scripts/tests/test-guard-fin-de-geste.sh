#!/usr/bin/env bash
# test-guard-fin-de-geste.sh — suite de guard-fin-de-geste.sh (SOBR-07, volet travail direct, QUAL-01,
# plan 41.3-04). Chaque cas construit SON dépôt jetable sous mktemp -d et SON dossier d'état
# (TMPDIR isolé) ; le script de budget est le VRAI check-method-budget.sh, sauf F10/F12 (substitué par
# VF_METHOD_BUDGET pour produire un jeton que --no-remote ne rend jamais). Trois issues QUAL-01 : PASS
# (silence, exit 0), FAIL (blocage exit 2 qui nomme ce qui reste) et imparsable BRUYANT (NON VÉRIFIABLE
# sur stderr, exit 0, jamais un vert muet). Quatre mutants, chacun asserté au rc EXACT sur le mutant ET
# sur l'original : « ✓ MUT-<n> TUE : rc_mutant=<x> attendu <x>, rc_original=<y> attendu <y> ».
# Comparaisons par cmp/comm, jamais diff. LIMITE DE FOND : la garde, sa suite et hooks.json vivent dans
# le dépôt qu'elles jugent.
set -uo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$HERE/guard-fin-de-geste.sh"
BUDGET="$HERE/check-method-budget.sh"
PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS + 1)); }
ko() { echo "  ✗ $1"; echo "    attendu   : $2"; echo "    obtenu    : $3"; FAIL=$((FAIL + 1)); }
okmut() { echo "  ✓ MUT-$1 TUE : rc_mutant=$2 attendu $3, rc_original=$4 attendu $5"; PASS=$((PASS + 1)); }
komut() { echo "  ✗ MUT-$1 NON TUE : $2"; echo "    attendu   : $3"; echo "    obtenu    : $4"; FAIL=$((FAIL + 1)); }

unset VF_FIN_DE_GESTE VF_METHOD_BUDGET VF_ARCHIVE_PROTECTED_WS
TMP="$(mktemp -d)"; MUTD="$(mktemp -d)"
trap 'rm -rf "$TMP" "$MUTD"' EXIT
STATE_DIR="$TMP/etat"; mkdir -p "$STATE_DIR"

G() { git -C "$1" -c user.name=CI -c user.email=ci@example.invalid -c commit.gpgsign=false "${@:2}"; }
mk_repo() {  # <nom> [clos] : dépôt partitionné (ws1, ws2), BACKLOG commité ; « clos » ajoute un sujet CLOS à ws1
  local d="$TMP/$1" w
  mkdir -p "$d" && G "$d" init -q -b main >/dev/null
  for w in ws1 ws2; do
    mkdir -p "$d/.planning/workstreams/$w"
    printf '# Backlog\n\n## Ouvert — DIFFÉRÉ (2026-01-01)\ntexte\n' > "$d/.planning/workstreams/$w/BACKLOG.md"
    [ "$w" = ws1 ] && [ -n "${2:-}" ] && printf '\n## Clos — CLOS (2026-01-02)\ntexte clos\n' >> "$d/.planning/workstreams/$w/BACKLOG.md"
    printf -- '---\nstatus: executing\n---\n\n# Project State\n\n## Current Position\nPhase: 1\n' > "$d/.planning/workstreams/$w/STATE.md"
  done
  G "$d" add -A >/dev/null; G "$d" commit -q -m "fixture: etat initial" >/dev/null
  printf '%s' "$d"
}
# branche_mergee <dépôt> <nom> : branche avec un commit à elle, mergée dans main (is_worked exige un commit propre).
branche_mergee() {
  G "$1" checkout -q -b "$2" >/dev/null 2>&1; G "$1" commit -q --allow-empty -m "travail $2" >/dev/null
  G "$1" checkout -q main >/dev/null 2>&1; G "$1" merge -q --no-ff "$2" -m "merge $2" >/dev/null
}
# hook <script> <dépôt> <stdin> [--snapshot] : O (stdout), E (stderr), R (rc) ; l'environnement d'appel est celui de l'appelant.
hook() {
  local s="$1" d="$2" in="$3"; shift 3
  O="$(cd "$d" && printf '%s' "$in" | GSD_WORKSTREAM="${HOOK_WS-ws1}" TMPDIR="$STATE_DIR" VF_METHOD_BUDGET="${VF_METHOD_BUDGET:-$BUDGET}" bash "$s" "$@" 2>"$TMP/stderr")"; R=$?
  E="$(cat "$TMP/stderr")"
}
J() { printf '{"session_id":"%s"}' "$1"; }
JA() { printf '{"session_id":"%s","stop_hook_active":true}' "$1"; }
has() { case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }
check() {  # <libellé> <rc attendu> <rc> <fragment attendu dans E ou ''> [<fragment interdit dans E>]
  local lib="$1" erc="$2" rc="$3" frag="$4" nofrag="${5:-}"
  if [ "$rc" -ne "$erc" ]; then ko "$lib" "rc=$erc" "rc=$rc ; stderr : $E"; return; fi
  if [ -n "$frag" ] && ! has "$E" "$frag"; then ko "$lib" "stderr contenant « $frag »" "$E"; return; fi
  if [ -n "$nofrag" ] && has "$E" "$nofrag"; then ko "$lib" "stderr sans « $nofrag »" "$E"; return; fi
  ok "$lib"
}
silence() {  # <libellé> : stdout ET stderr vides
  if [ -z "$O" ] && [ -z "$E" ]; then ok "$1"; else ko "$1" "stdout et stderr vides" "stdout=« $O » stderr=« $E »"; fi
}

echo "== test-guard-fin-de-geste : PASS / FAIL / BRUYANT =="

# F1 — rien de nouveau : silence, exit 0.
D="$(mk_repo f1)"; hook "$SCRIPT" "$D" "$(J f1)" --snapshot
check "F1 snapshot : exit 0" 0 "$R" ""; [ -z "$O" ] && ok "F1 snapshot : stdout STRICTEMENT vide (contrat §3)" || ko "F1 snapshot stdout" "vide" "$O"
hook "$SCRIPT" "$D" "$(J f1)"
check "F1 rien de nouveau : exit 0" 0 "$R" ""; silence "F1 … et silence total"

# F2 — branche mergée apparue pendant la session : blocage qui la nomme. F3 — le second Stop ne re-bloque pas.
D="$(mk_repo f2)"; hook "$SCRIPT" "$D" "$(J f2)" --snapshot; branche_mergee "$D" feat-x
hook "$SCRIPT" "$D" "$(J f2)"
check "F2 branche mergée apparue → exit 2, la nomme" 2 "$R" "RANGEABLE branche : feat-x"
has "$E" "Jamais une branche distante" && ok "F2 le blocage dit quoi ranger et interdit la branche distante" || ko "F2 texte" "consigne de rangement" "$E"
branche_mergee "$D" feat-y; hook "$SCRIPT" "$D" "$(J f2)"
check "F3 second Stop de la session → exit 0, ni archivage ni re-blocage" 0 "$R" ""; silence "F3 … silence"

# F4 — stop_hook_active : jamais de re-blocage d'une continuation.
D="$(mk_repo f4)"; hook "$SCRIPT" "$D" "$(J f4)" --snapshot; branche_mergee "$D" feat-x
hook "$SCRIPT" "$D" "$(JA f4)"; check "F4 stop_hook_active → exit 0" 0 "$R" ""; silence "F4 … silence"

# F5 — rangeable déjà là au snapshot : pas de blocage.
D="$(mk_repo f5)"; branche_mergee "$D" feat-ancienne; hook "$SCRIPT" "$D" "$(J f5)" --snapshot
hook "$SCRIPT" "$D" "$(J f5)"; check "F5 rangeable déjà au snapshot → exit 0" 0 "$R" ""; silence "F5 … silence"

# F6 — VF_FIN_DE_GESTE=warn : exit 0, dit sur stderr, RIEN déplacé.
D="$(mk_repo f6 clos)"; cp "$D/.planning/workstreams/ws1/BACKLOG.md" "$TMP/f6.avant"
export VF_FIN_DE_GESTE=warn
hook "$SCRIPT" "$D" "$(J f6)" --snapshot; branche_mergee "$D" feat-x; hook "$SCRIPT" "$D" "$(J f6)"
unset VF_FIN_DE_GESTE
check "F6 warn → exit 0 et le dit sur stderr" 0 "$R" "RANGEABLE branche : feat-x"
cmp -s "$D/.planning/workstreams/ws1/BACKLOG.md" "$TMP/f6.avant" && [ ! -e "$D/.planning/archives" ] && ok "F6 warn : rien déplacé (BACKLOG identique, aucune archive)" || ko "F6 rien déplacé" "BACKLOG identique, pas de .planning/archives" "modifié ou archive posée"
VF_FIN_DE_GESTE=off hook "$SCRIPT" "$D" "$(J f6)"; check "F6b off → exit 0, silence" 0 "$R" ""

# F7 — imparsable BRUYANT : jamais un vert muet.
D="$(mk_repo f7)"; hook "$SCRIPT" "$D" "pas du json"
check "F7 stdin illisible → exit 0, NON VÉRIFIABLE bruyant" 0 "$R" "NON VÉRIFIABLE"; [ -z "$O" ] && ok "F7 … stdout vide" || ko "F7 stdout" "vide" "$O"
hook "$SCRIPT" "$D" "$(J f7sans)"; check "F7b snapshot absent → exit 0, NON VÉRIFIABLE bruyant" 0 "$R" "snapshot de début de session absent"
VF_METHOD_BUDGET="$TMP/n-existe-pas.sh" hook "$SCRIPT" "$D" "$(J f7b)" --snapshot; check "F7c script de budget absent → NON VÉRIFIABLE bruyant" 0 "$R" "script de budget introuvable"

# F8 — sujet clos commité : le Stop archive SANS geste humain, le blocage nomme ARCHIVÉ, l'INDEX et la restauration.
D="$(mk_repo f8 clos)"; cp "$D/.planning/workstreams/ws1/BACKLOG.md" "$TMP/f8.avant"; H="$(G "$D" rev-parse HEAD)"
hook "$SCRIPT" "$D" "$(J f8)" --snapshot; hook "$SCRIPT" "$D" "$(J f8)"
check "F8 budget dépassé, source commitée → exit 2, ARCHIVÉ nommé" 2 "$R" "ARCHIVÉ : .planning/workstreams/ws1/BACKLOG.md"
has "$E" "INDEX.tsv" && has "$E" "git cat-file blob" && ok "F8 le blocage dit l'INDEX et la restauration" || ko "F8 texte" "INDEX.tsv et git cat-file blob" "$E"
REF="$(awk -F'\t' '$3 ~ /ws1\/BACKLOG.md$/ { print $5 }' "$D/.planning/archives/INDEX.tsv" | head -1)"
if [ -n "$REF" ] && G "$D" cat-file blob "$REF" > "$TMP/f8.restaure" 2>/dev/null && cmp -s "$TMP/f8.restaure" "$TMP/f8.avant"; then ok "F8 ligne INDEX écrite, git cat-file blob <ref> = la source d'avant (cmp -s)"; else ko "F8 restauration" "blob de l'INDEX = source d'avant" "ref=« $REF »"; fi
[ "$(G "$D" rev-parse HEAD)" = "$H" ] && [ -n "$(G "$D" status --porcelain)" ] && ok "F8 déplacement visible au git status, aucun commit" || ko "F8 sans commit" "HEAD inchangé, arbre sale" "HEAD=$(G "$D" rev-parse HEAD)"

# F9 — source sale : rien déplacé, blocage qui nomme ARCHIVAGE REFUSÉ.
D="$(mk_repo f9 clos)"; echo "ajout non commité" >> "$D/.planning/workstreams/ws1/BACKLOG.md"; cp "$D/.planning/workstreams/ws1/BACKLOG.md" "$TMP/f9.avant"
hook "$SCRIPT" "$D" "$(J f9)" --snapshot; hook "$SCRIPT" "$D" "$(J f9)"
check "F9 source sale → exit 2, ARCHIVAGE REFUSÉ nommé" 2 "$R" "ARCHIVAGE REFUSÉ"
cmp -s "$D/.planning/workstreams/ws1/BACKLOG.md" "$TMP/f9.avant" && [ ! -e "$D/.planning/archives" ] && ok "F9 rien déplacé" || ko "F9 rien déplacé" "BACKLOG identique, pas d'archive" "modifié"

# F10 — ligne À VALIDER nouvelle (script de budget substitué) : blocage ; --auto transmis en mode block, pas en warn.
STUB="$TMP/stub-budget.sh"
cat > "$STUB" <<'EOF'
#!/usr/bin/env bash
echo "$*" >> "$STUB_LOG"
case " $* " in
  *" --auto "*) [ -n "${STUB_AUTO:-}" ] && printf '%b\n' "$STUB_AUTO" ;;
  *) [ -n "${STUB_SNAP:-}" ] && printf '%b\n' "$STUB_SNAP" ;;
esac
exit 0
EOF
export STUB_LOG="$TMP/stub.log"; : > "$STUB_LOG"
D="$(mk_repo f10)"; export VF_METHOD_BUDGET="$STUB" STUB_AUTO='[budget] À VALIDER branche distante : origin/x (PR #1, samuel) — suppression = geste humain'
hook "$SCRIPT" "$D" "$(J f10)" --snapshot; hook "$SCRIPT" "$D" "$(J f10)"
check "F10 ligne À VALIDER nouvelle → exit 2, la nomme" 2 "$R" "À VALIDER branche distante : origin/x"
grep -q -- '--auto' "$STUB_LOG" && ok "F10 mode block : check-method-budget appelé avec --auto" || ko "F10 --auto" "--auto dans les arguments" "$(cat "$STUB_LOG")"
: > "$STUB_LOG"; D="$(mk_repo f10w)"; VF_FIN_DE_GESTE=warn hook "$SCRIPT" "$D" "$(J f10w)" --snapshot; STUB_SNAP="$STUB_AUTO" VF_FIN_DE_GESTE=warn hook "$SCRIPT" "$D" "$(J f10w)"
check "F10b warn → exit 0, dit sur stderr" 0 "$R" "À VALIDER branche distante"
grep -q -- '--auto' "$STUB_LOG" && ko "F10b warn sans --auto" "aucun --auto" "$(cat "$STUB_LOG")" || ok "F10b warn : jamais --auto (lecture seule)"
# F12 — DÉPASSÉ seul : cité, ne bloque pas.
D="$(mk_repo f12)"; export STUB_AUTO='[budget] STATE DÉPASSÉ : x fait 99 Ko (budget 8 Ko). Réécrire la position courante'
hook "$SCRIPT" "$D" "$(J f12)" --snapshot; hook "$SCRIPT" "$D" "$(J f12)"
check "F12 DÉPASSÉ seul → exit 0, cité sur stderr" 0 "$R" "STATE DÉPASSÉ"
unset VF_METHOD_BUDGET STUB_AUTO STUB_SNAP

# F11 — dépôt partitionné, aucun compartiment résolu : ARCHIVAGE NON TENTÉ, rien déplacé, exit 0.
D="$(mk_repo f11 clos)"; T0="$(cd "$D" && find . -path ./.git -prune -o -type f -print | LC_ALL=C sort | xargs cksum | cksum)"
HOOK_WS= hook "$SCRIPT" "$D" "$(J f11)" --snapshot; HOOK_WS= hook "$SCRIPT" "$D" "$(J f11)"
check "F11 aucun compartiment résolu → exit 0, ARCHIVAGE NON TENTÉ sur stderr" 0 "$R" "ARCHIVAGE NON TENTÉ"
T1="$(cd "$D" && find . -path ./.git -prune -o -type f -print | LC_ALL=C sort | xargs cksum | cksum)"
[ "$T0" = "$T1" ] && ok "F11 rien déplacé (arbre identique)" || ko "F11 rien déplacé" "$T0" "$T1"

echo "== test-guard-fin-de-geste : MUTANTS (MUT-1 à MUT-4) =="
make_mutant() {  # <nom> <ancienne ligne> <nouvelle ligne> ; 0 = opposable, 1 = identique, 2 = syntaxe invalide
  local out="$MUTD/$1.sh"
  MUT_OLD_ENV="$2" MUT_NEW_ENV="$3" awk '{ if ($0 == ENVIRON["MUT_OLD_ENV"]) print ENVIRON["MUT_NEW_ENV"]; else print }' "$SCRIPT" > "$out"
  cmp -s "$out" "$SCRIPT" && return 1
  bash -n "$out" 2>/dev/null || return 2
  return 0
}
mutant() {  # <n> <ancienne> <nouvelle> <scénario> <rc_original> <rc_mutant> ; le scénario rend le rc du dernier Stop
  local n="$1" old="$2" new="$3" sc="$4" eo="$5" em="$6" mr ro rm
  make_mutant "mut$n" "$old" "$new"; mr=$?
  if [ "$mr" -ne 0 ]; then komut "$n" "mutant opposable" "mutation appliquée et syntaxe valide" "statut make_mutant=$mr"; return; fi
  "$sc" "$SCRIPT" "mo$n"; ro=$?; "$sc" "$MUTD/mut$n.sh" "mm$n"; rm=$?
  if [ "$ro" -eq "$eo" ] && [ "$rm" -eq "$em" ]; then okmut "$n" "$rm" "$em" "$ro" "$eo"
  else komut "$n" "rc original=$eo, rc mutant=$em" "original=$eo mutant=$em" "original=$ro mutant=$rm"; fi
}
sc_f5() { local d; d="$(mk_repo "$2")"; branche_mergee "$d" feat-ancienne; hook "$1" "$d" "$(J "$2")" --snapshot; hook "$1" "$d" "$(J "$2")"; return "$R"; }
sc_f3() { local d; d="$(mk_repo "$2")"; hook "$1" "$d" "$(J "$2")" --snapshot; branche_mergee "$d" feat-x; hook "$1" "$d" "$(J "$2")"; branche_mergee "$d" feat-y; hook "$1" "$d" "$(J "$2")"; return "$R"; }
sc_f8() { local d; d="$(mk_repo "$2" clos)"; hook "$1" "$d" "$(J "$2")" --snapshot; hook "$1" "$d" "$(J "$2")"; return "$R"; }
sc_f10() {
  local d; d="$(mk_repo "$2")"
  VF_METHOD_BUDGET="$STUB" STUB_AUTO='[budget] À VALIDER branche distante : origin/x (PR #1, samuel) — suppression = geste humain' hook "$1" "$d" "$(J "$2")" --snapshot
  VF_METHOD_BUDGET="$STUB" STUB_AUTO='[budget] À VALIDER branche distante : origin/x (PR #1, samuel) — suppression = geste humain' hook "$1" "$d" "$(J "$2")"; return "$R"
}
# MUT-1 (F5) : le snapshot est ignoré, tout ce qui est rangeable est pris pour nouveau.
mutant 1 'NOUVEAU="$(LC_ALL=C comm -23 "$DIR/$KEY-$SID.now" "$SNAP" | grep -v '"'DÉPASSÉ'"')"' 'NOUVEAU="$(LC_ALL=C comm -23 "$DIR/$KEY-$SID.now" /dev/null | grep -v '"'DÉPASSÉ'"')"' sc_f5 0 2
# MUT-2 (F3) : le marqueur de session est ignoré, le Stop re-bloque.
mutant 2 '[ -f "$ACTED" ] && exit 0' ':' sc_f3 0 2
# MUT-3 (F8) : --auto remplacé par la lecture seule, plus rien n'est archivé.
mutant 3 '[ "$MODE" = "warn" ] || ARGS=(--auto "${ARGS[@]}")' ':' sc_f8 2 0
# MUT-4 (F10) : le jeton À VALIDER est retiré de la liste lue.
mutant 4 "TOKENS='RANGEABLE|ARCHIVABLE|ARCHIVÉ|ARCHIVAGE REFUSÉ|À VALIDER|DÉPASSÉ'" "TOKENS='RANGEABLE|ARCHIVABLE|ARCHIVÉ|ARCHIVAGE REFUSÉ|DÉPASSÉ'" sc_f10 2 0

echo
echo "Résultat : $PASS vert(s), $FAIL rouge(s)"
[ "$FAIL" -eq 0 ]
