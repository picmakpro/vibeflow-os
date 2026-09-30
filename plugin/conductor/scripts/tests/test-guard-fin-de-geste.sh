#!/usr/bin/env bash
# test-guard-fin-de-geste.sh — suite de guard-fin-de-geste.sh (SOBR-07, volet travail direct, QUAL-01,
# plan 41.3-04, correction B). Chaque cas construit SON dépôt jetable sous mktemp -d et SON dossier d'état
# (TMPDIR isolé) ; le script de budget est le VRAI check-method-budget.sh, sauf F12/F13 (substitué par
# VF_METHOD_BUDGET pour produire un constat). Issues QUAL-01 : PASS (silence, exit 0), FAIL (blocage exit 2
# qui nomme ce qui reste), imparsable BRUYANT (NON VÉRIFIABLE dans `systemMessage`, exit 0). Le stdout d'un
# exit 0 non vide est vérifié comme UN SEUL document JSON par un parseur de DOCUMENT (json.loads), jamais
# `jq` (qui accepte un flux de documents). Sept mutants, chacun asserté au rc EXACT sur le mutant ET sur
# l'original : « ✓ MUT-<n> TUE : rc_mutant=<x> attendu <x>, rc_original=<y> attendu <y> ».
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
  O="$(cd "$d" && printf '%s' "$in" | GSD_WORKSTREAM="${HOOK_WS-ws1}" TMPDIR="${HOOK_TMP:-$STATE_DIR}" PATH="${HOOK_PATH:-$PATH}" VF_METHOD_BUDGET="${VF_METHOD_BUDGET:-$BUDGET}" bash "$s" "$@" 2>"$TMP/stderr")"; R=$?
  E="$(cat "$TMP/stderr")"
}
J() { printf '{"session_id":"%s"}' "$1"; }
JA() { printf '{"session_id":"%s","stop_hook_active":true}' "$1"; }
has() { case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }
# doc_unique : O est UN SEUL document JSON (parseur de DOCUMENT, json.loads) dont l'unique clé est systemMessage.
doc_unique() { printf '%s' "$O" | python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); assert list(d.keys())==["systemMessage"] and isinstance(d["systemMessage"],str)' 2>/dev/null; }
vm() { VM="$(printf '%s' "$O" | python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["systemMessage"])' 2>/dev/null)"; }
check() {  # <libellé> <rc attendu> <rc> <fragment attendu dans E ou ''> [<fragment interdit dans E>]
  local lib="$1" erc="$2" rc="$3" frag="$4" nofrag="${5:-}"
  if [ "$rc" -ne "$erc" ]; then ko "$lib" "rc=$erc" "rc=$rc ; stderr : $E"; return; fi
  if [ -n "$frag" ] && ! has "$E" "$frag"; then ko "$lib" "stderr contenant « $frag »" "$E"; return; fi
  if [ -n "$nofrag" ] && has "$E" "$nofrag"; then ko "$lib" "stderr sans « $nofrag »" "$E"; return; fi
  ok "$lib"
}
visible() {  # <libellé> <fragment attendu dans systemMessage> [<fragment interdit>] : exit 0, UN document JSON, stderr vide
  local lib="$1" frag="$2" nofrag="${3:-}"
  if [ "$R" -ne 0 ]; then ko "$lib" "rc=0" "rc=$R ; stderr : $E"; return; fi
  if ! doc_unique; then ko "$lib" "stdout = UN document JSON {systemMessage}" "stdout=« $O »"; return; fi
  vm
  if [ -n "$frag" ] && ! has "$VM" "$frag"; then ko "$lib" "systemMessage contenant « $frag »" "$VM"; return; fi
  if [ -n "$nofrag" ] && has "$VM" "$nofrag"; then ko "$lib" "systemMessage sans « $nofrag »" "$VM"; return; fi
  if [ -n "$E" ]; then ko "$lib" "stderr vide (le canal est systemMessage)" "$E"; return; fi
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

# F2 — branche mergée apparue pendant la session : blocage qui la nomme et dit quoi ranger.
D="$(mk_repo f2)"; hook "$SCRIPT" "$D" "$(J f2)" --snapshot; branche_mergee "$D" feat-x
hook "$SCRIPT" "$D" "$(J f2)"
check "F2 branche mergée apparue → exit 2, la nomme, blocage 1/3" 2 "$R" "RANGEABLE branche : feat-x"
has "$E" "blocage 1/3" && has "$E" "Jamais une branche distante" && has "$E" "pas de ta main" && ok "F2 le blocage dit quoi ranger, interdit la branche distante et l'objet d'autrui" || ko "F2 texte" "blocage 1/3, branche distante, pas de ta main" "$E"

# F3 (M1, arbitrage AskUserQuestion 2026-09-30 option a) — bloque / bloque / bloque / sort VISIBLE, puis se tait.
D="$(mk_repo f3)"; hook "$SCRIPT" "$D" "$(J f3)" --snapshot; branche_mergee "$D" feat-x
hook "$SCRIPT" "$D" "$(J f3)"; check "F3 arrêt 1 → exit 2 (blocage 1/3)" 2 "$R" "blocage 1/3"
hook "$SCRIPT" "$D" "$(J f3)"; check "F3 arrêt 2 sans progrès → exit 2 (blocage 2/3)" 2 "$R" "blocage 2/3"
hook "$SCRIPT" "$D" "$(J f3)"; check "F3 arrêt 3 sans progrès → exit 2 (blocage 3/3)" 2 "$R" "blocage 3/3"
hook "$SCRIPT" "$D" "$(J f3)"; visible "F3 arrêt 4 : coupe-circuit, exit 0, VISIBLE (systemMessage), nomme ce qui reste" "Coupe-circuit"
has "$VM" "feat-x" && ok "F3 … le message nomme le reste" || ko "F3 reste nommé" "feat-x dans systemMessage" "$VM"
hook "$SCRIPT" "$D" "$(J f3)"; silence "F3 arrêt 5 : déjà dit une fois, silence"

# F3b — un PROGRÈS (l'ensemble attribué diminue) remet le compteur à zéro.
D="$(mk_repo f3b)"; hook "$SCRIPT" "$D" "$(J f3b)" --snapshot; branche_mergee "$D" feat-x; branche_mergee "$D" feat-y
hook "$SCRIPT" "$D" "$(J f3b)"; hook "$SCRIPT" "$D" "$(J f3b)"
G "$D" branch -d feat-x >/dev/null 2>&1
hook "$SCRIPT" "$D" "$(J f3b)"; check "F3b progrès (2 → 1 objet) : le compteur repart, blocage 1/3" 2 "$R" "blocage 1/3"
hook "$SCRIPT" "$D" "$(J f3b)"; hook "$SCRIPT" "$D" "$(J f3b)"; check "F3b … jusqu'à 3/3 sans progrès" 2 "$R" "blocage 3/3"
hook "$SCRIPT" "$D" "$(J f3b)"; visible "F3b … puis le coupe-circuit, visible" "Coupe-circuit"

# F3c — rangement fait : sort vert, silence, état effacé (un nouveau rangement repart à 1/3).
D="$(mk_repo f3c)"; hook "$SCRIPT" "$D" "$(J f3c)" --snapshot; branche_mergee "$D" feat-x
hook "$SCRIPT" "$D" "$(J f3c)"; hook "$SCRIPT" "$D" "$(J f3c)"
G "$D" branch -d feat-x >/dev/null 2>&1
hook "$SCRIPT" "$D" "$(J f3c)"; check "F3c rangement fait → exit 0" 0 "$R" ""; silence "F3c … silence total"
branche_mergee "$D" feat-z; hook "$SCRIPT" "$D" "$(J f3c)"; check "F3c nouveau rangement après un vert → repart à 1/3" 2 "$R" "blocage 1/3"

# F4 — stop_hook_active ne rend PLUS la garde muette (il la coupait dès le 2e arrêt) : la boucle est bornée par le compteur.
D="$(mk_repo f4)"; hook "$SCRIPT" "$D" "$(J f4)" --snapshot; branche_mergee "$D" feat-x
hook "$SCRIPT" "$D" "$(JA f4)"; check "F4 stop_hook_active + rangement attribué → exit 2 quand même (borné par le compteur)" 2 "$R" "RANGEABLE branche : feat-x"

# F5 (M3) — rangeable déjà là au snapshot : jamais imputé à la session. F5b : seul le NOUVEAU est nommé.
D="$(mk_repo f5)"; branche_mergee "$D" feat-ancienne; hook "$SCRIPT" "$D" "$(J f5)" --snapshot
hook "$SCRIPT" "$D" "$(J f5)"; check "F5 rangeable déjà au snapshot → exit 0" 0 "$R" ""; silence "F5 … silence"
branche_mergee "$D" feat-neuve; hook "$SCRIPT" "$D" "$(J f5)"
check "F5b préexistant + nouveau → exit 2, seul le nouveau est nommé" 2 "$R" "RANGEABLE branche : feat-neuve" "feat-ancienne"

# F6 — VF_FIN_DE_GESTE=warn : exit 0, dit à l'utilisateur, RIEN déplacé.
D="$(mk_repo f6 clos)"; cp "$D/.planning/workstreams/ws1/BACKLOG.md" "$TMP/f6.avant"
export VF_FIN_DE_GESTE=warn
hook "$SCRIPT" "$D" "$(J f6)" --snapshot; branche_mergee "$D" feat-x; hook "$SCRIPT" "$D" "$(J f6)"
unset VF_FIN_DE_GESTE
visible "F6 warn → exit 0, systemMessage qui nomme le rangement" "RANGEABLE branche : feat-x"
cmp -s "$D/.planning/workstreams/ws1/BACKLOG.md" "$TMP/f6.avant" && [ ! -e "$D/.planning/archives" ] && ok "F6 warn : rien déplacé (BACKLOG identique, aucune archive)" || ko "F6 rien déplacé" "BACKLOG identique, pas de .planning/archives" "modifié ou archive posée"
VF_FIN_DE_GESTE=off hook "$SCRIPT" "$D" "$(J f6)"; check "F6b off → exit 0" 0 "$R" ""; silence "F6b … silence"

# F7 — imparsable BRUYANT (M5) : NON VÉRIFIABLE dans systemMessage, jamais un vert muet, jamais sur stderr seul.
D="$(mk_repo f7)"; hook "$SCRIPT" "$D" "pas du json"
visible "F7 stdin illisible → exit 0, NON VÉRIFIABLE visible" "NON VÉRIFIABLE"
hook "$SCRIPT" "$D" "$(J f7sans)"; visible "F7b snapshot absent → NON VÉRIFIABLE visible" "snapshot de début de session absent"
VF_METHOD_BUDGET="$TMP/n-existe-pas.sh" hook "$SCRIPT" "$D" "$(J f7b)" --snapshot; visible "F7c script de budget absent → NON VÉRIFIABLE visible" "script de budget introuvable"

# F8 (M3) — sujet clos PRÉEXISTANT : le Stop l'archive SANS geste humain, le DIT à l'utilisateur, ne bloque PAS.
D="$(mk_repo f8 clos)"; cp "$D/.planning/workstreams/ws1/BACKLOG.md" "$TMP/f8.avant"; H="$(G "$D" rev-parse HEAD)"
hook "$SCRIPT" "$D" "$(J f8)" --snapshot; hook "$SCRIPT" "$D" "$(J f8)"
visible "F8 sujet clos préexistant archivé → exit 0 (pas de blocage), ARCHIVÉ dit" "ARCHIVÉ : .planning/workstreams/ws1/BACKLOG.md"
has "$VM" "INDEX.tsv" && has "$VM" "git cat-file blob" && ok "F8 le message dit l'INDEX et la restauration" || ko "F8 texte" "INDEX.tsv et git cat-file blob" "$VM"
REF="$(awk -F'\t' '$3 ~ /ws1\/BACKLOG.md$/ { print $5 }' "$D/.planning/archives/INDEX.tsv" | head -1)"
if [ -n "$REF" ] && G "$D" cat-file blob "$REF" > "$TMP/f8.restaure" 2>/dev/null && cmp -s "$TMP/f8.restaure" "$TMP/f8.avant"; then ok "F8 ligne INDEX écrite, git cat-file blob <ref> = la source d'avant (cmp -s)"; else ko "F8 restauration" "blob de l'INDEX = source d'avant" "ref=« $REF »"; fi
[ "$(G "$D" rev-parse HEAD)" = "$H" ] && [ -n "$(G "$D" status --porcelain)" ] && ok "F8 déplacement visible au git status, aucun commit" || ko "F8 sans commit" "HEAD inchangé, arbre sale" "HEAD=$(G "$D" rev-parse HEAD)"
hook "$SCRIPT" "$D" "$(J f8)"; check "F8b second arrêt → exit 0, ne re-bloque pas" 0 "$R" ""

# F9 (M2) — source sale : ARCHIVAGE REFUSÉ non actionnable → exit 0, DIT à l'utilisateur, rien déplacé ; pas de répétition.
D="$(mk_repo f9 clos)"; echo "ajout non commité" >> "$D/.planning/workstreams/ws1/BACKLOG.md"; cp "$D/.planning/workstreams/ws1/BACKLOG.md" "$TMP/f9.avant"
hook "$SCRIPT" "$D" "$(J f9)" --snapshot; hook "$SCRIPT" "$D" "$(J f9)"
visible "F9 source sale → exit 0 (ne bloque plus), ARCHIVAGE REFUSÉ dit" "ARCHIVAGE REFUSÉ"
cmp -s "$D/.planning/workstreams/ws1/BACKLOG.md" "$TMP/f9.avant" && [ ! -e "$D/.planning/archives" ] && ok "F9 rien déplacé" || ko "F9 rien déplacé" "BACKLOG identique, pas d'archive" "modifié"
hook "$SCRIPT" "$D" "$(J f9)"; silence "F9b même constat à l'arrêt suivant : pas de répétition"

# F10 — stubs : plusieurs constats d'un coup → UN SEUL document JSON ; DÉPASSÉ résumé en UNE ligne.
STUB="$TMP/stub-budget.sh"
cat > "$STUB" <<'STUBEOF'
#!/usr/bin/env bash
echo "$*" >> "$STUB_LOG"
case " $* " in
  *" --auto "*) [ -n "${STUB_AUTO:-}" ] && printf '%b\n' "$STUB_AUTO" ;;
  *) [ -n "${STUB_SNAP:-}" ] && printf '%b\n' "$STUB_SNAP" ;;
esac
exit 0
STUBEOF
export STUB_LOG="$TMP/stub.log"; : > "$STUB_LOG"
D="$(mk_repo f10)"
export VF_METHOD_BUDGET="$STUB" STUB_AUTO='[budget] STATE DÉPASSÉ : a fait 99 Ko (budget 8 Ko)\n[budget] STATE DÉPASSÉ : b fait 98 Ko (budget 8 Ko)\n[budget] STATE DÉPASSÉ : c fait 97 Ko (budget 8 Ko)\n[budget] ARCHIVAGE NON TENTÉ : dépôt partitionné, aucun compartiment résolu\n[budget] ARCHIVÉ : x.md -> archives/x.md\n[budget] ARCHIVAGE REFUSÉ : y.md modifiée, non commitée'
hook "$SCRIPT" "$D" "$(J f10)" --snapshot; hook "$SCRIPT" "$D" "$(J f10)"
visible "F10 constats multiples → exit 0, UN document JSON valide (json.loads)" "ARCHIVAGE NON TENTÉ"
has "$VM" "ARCHIVÉ : x.md" && has "$VM" "ARCHIVAGE REFUSÉ : y.md" && ok "F10 … ARCHIVÉ et REFUSÉ y sont" || ko "F10 contenu" "ARCHIVÉ et REFUSÉ" "$VM"
[ "$(printf '%s\n' "$VM" | grep -c 'budget dépassé')" -eq 1 ] && has "$VM" "3 ligne(s)" && ok "F10 DÉPASSÉ résumé en UNE ligne (3 constats → 1 ligne)" || ko "F10 DÉPASSÉ" "une ligne « budget dépassé … 3 ligne(s) »" "$VM"
grep -q -- '--auto' "$STUB_LOG" && ok "F10 mode block : check-method-budget appelé avec --auto" || ko "F10 --auto" "--auto dans les arguments" "$(cat "$STUB_LOG")"
unset VF_METHOD_BUDGET STUB_AUTO STUB_SNAP
: > "$STUB_LOG"; D="$(mk_repo f10w)"
export VF_METHOD_BUDGET="$STUB"; VF_FIN_DE_GESTE=warn hook "$SCRIPT" "$D" "$(J f10w)" --snapshot; VF_FIN_DE_GESTE=warn hook "$SCRIPT" "$D" "$(J f10w)"
grep -q -- '--auto' "$STUB_LOG" && ko "F10b warn sans --auto" "aucun --auto" "$(cat "$STUB_LOG")" || ok "F10b warn : jamais --auto (lecture seule)"
unset VF_METHOD_BUDGET

# F11 (M4 côté garde) — dépôt partitionné, aucun compartiment résolu : ARCHIVAGE NON TENTÉ DIT, rien déplacé, exit 0.
D="$(mk_repo f11 clos)"; T0="$(cd "$D" && find . -path ./.git -prune -o -type f -print | LC_ALL=C sort | xargs cksum | cksum)"
HOOK_WS= hook "$SCRIPT" "$D" "$(J f11)" --snapshot; HOOK_WS= hook "$SCRIPT" "$D" "$(J f11)"
visible "F11 aucun compartiment résolu → exit 0, ARCHIVAGE NON TENTÉ visible" "ARCHIVAGE NON TENTÉ"
T1="$(cd "$D" && find . -path ./.git -prune -o -type f -print | LC_ALL=C sort | xargs cksum | cksum)"
[ "$T0" = "$T1" ] && ok "F11 rien déplacé (arbre identique)" || ko "F11 rien déplacé" "$T0" "$T1"

# --- Correction 41.3 (tour 2) : M1 identité des stash, M2 écritures d'état, M3 archivage dit, m4 -------------------
UIDN="$(id -u)"
stash_sur_branche_supprimee() {  # <dépôt> <branche> <message> : un stash dont la branche d'origine n'existe plus (RANGEABLE)
  G "$1" checkout -q -b "$2" >/dev/null 2>&1; printf 'x\n' >> "$1/.planning/workstreams/ws1/STATE.md"
  G "$1" stash push -q -m "$3" >/dev/null 2>&1; G "$1" checkout -q main >/dev/null 2>&1; G "$1" branch -q -D "$2" >/dev/null 2>&1
}
# F12 (M1) — un stash PRÉEXISTANT reste non imputé quand un nouveau stash décale sa position (stash@{0} → stash@{1}).
D="$(mk_repo f12)"; stash_sur_branche_supprimee "$D" tmp-a "ancien-A"; SHA_A="$(G "$D" stash list --format=%H | head -1)"; SHA_A="${SHA_A:0:12}"
hook "$SCRIPT" "$D" "$(J f12)" --snapshot
stash_sur_branche_supprimee "$D" tmp-b "nouveau-B"; SHA_B="$(G "$D" stash list --format=%H | head -1)"; SHA_B="${SHA_B:0:12}"
hook "$SCRIPT" "$D" "$(J f12)"
check "F12 nouveau stash → exit 2, désigné par son SHA" 2 "$R" "RANGEABLE stash : $SHA_B" "$SHA_A"
has "$E" "position actuelle : stash@{0}" && ok "F12 … la position ACTUELLE est dite à celui qui doit agir" || ko "F12 position" "position actuelle : stash@{0}" "$E"
has "$E" "ancien-A" && ko "F12 préexistant jamais imputé" "« ancien-A » absent" "$E" || ok "F12 le stash préexistant, décalé en stash@{1}, n'est PAS imputé"

# F13 (M2) — compteur non persistable : dit, relâché, JAMAIS de blocage sans borne (huit arrêts).
D="$(mk_repo f13)"; hook "$SCRIPT" "$D" "$(J f13)" --snapshot; branche_mergee "$D" feat-x
SNAPF="$(ls "$STATE_DIR/vibeflow-fin-de-geste-$UIDN/"*-f13.snap)"; mkdir "${SNAPF%.snap}.blk"
NB2=0; for i in 1 2 3 4 5 6 7 8; do hook "$SCRIPT" "$D" "$(J f13)"; [ "$R" -eq 2 ] && NB2=$((NB2 + 1)); done
[ "$NB2" -eq 0 ] && ok "F13 compteur non persistable : zéro blocage sur huit arrêts (jamais non borné)" || ko "F13 bornage" "0 exit 2 sur 8" "$NB2 exit 2"
visible "F13 … et dit, avec ce qui reste" "non persistable"
has "$VM" "feat-x" && ok "F13 … le message nomme le reste" || ko "F13 reste nommé" "feat-x" "$VM"

# F14 (M2) — snapshot non écrivable (ici : son chemin est occupé par un dossier ; le script remet lui-même ses droits 700) : dit, jamais un vert muet.
snap_bloque() { # <dépôt> <sid> <dossier TMPDIR> : occupe le chemin du snapshot de cette session par un dossier
  local k; k="$(printf '%s' "$(git -C "$1" rev-parse --show-toplevel)" | cksum | awk '{print $1}')"
  mkdir -p "$3/vibeflow-fin-de-geste-$UIDN" && mkdir "$3/vibeflow-fin-de-geste-$UIDN/${k}-$2.snap"
}
D="$(mk_repo f14)"; HT="$TMP/ro-tmp"; snap_bloque "$D" f14 "$HT"; HOOK_TMP="$HT" hook "$SCRIPT" "$D" "$(J f14)" --snapshot
visible "F14 snapshot non écrivable → exit 0, DIT (jamais un vert muet)" "snapshot de début de session non écrit"

# F15 (M3) — le même arrêt archive ET bloque : l'avis d'archivage, invisible dans un exit 2, est dit au premier exit 0.
D="$(mk_repo f15 clos)"; hook "$SCRIPT" "$D" "$(J f15)" --snapshot; branche_mergee "$D" feat-x
hook "$SCRIPT" "$D" "$(J f15)"; check "F15 arrêt 1 : archive ET bloque → exit 2" 2 "$R" "RANGEABLE branche : feat-x"
G "$D" branch -q -d feat-x >/dev/null 2>&1
hook "$SCRIPT" "$D" "$(J f15)"
visible "F15 arrêt 2 (rangé) : exit 0, l'archivage fait par l'arrêt précédent est DIT à l'utilisateur" "Archivé sans geste humain"
has "$VM" "INDEX.tsv" && ok "F15 … avec l'INDEX et la restauration" || ko "F15 texte" "INDEX.tsv" "$VM"
hook "$SCRIPT" "$D" "$(J f15)"; silence "F15 arrêt 3 : dit une fois, silence"

# F16 (m4) — plus bas atteint : l'alternance −1 / +1 n'est pas un progrès net, le coupe-circuit est atteint.
D="$(mk_repo f16)"; hook "$SCRIPT" "$D" "$(J f16)" --snapshot; branche_mergee "$D" feat-x; branche_mergee "$D" feat-y
hook "$SCRIPT" "$D" "$(J f16)"; check "F16 arrêt 1 (2 objets) → blocage 1/3" 2 "$R" "blocage 1/3"
G "$D" branch -q -d feat-x >/dev/null 2>&1
hook "$SCRIPT" "$D" "$(J f16)"; check "F16 arrêt 2 (1 objet, plus bas) : progrès → blocage 1/3" 2 "$R" "blocage 1/3"
branche_mergee "$D" feat-z
hook "$SCRIPT" "$D" "$(J f16)"; check "F16 arrêt 3 (+1) → blocage 2/3" 2 "$R" "blocage 2/3"
G "$D" branch -q -d feat-z >/dev/null 2>&1
hook "$SCRIPT" "$D" "$(J f16)"; check "F16 arrêt 4 (−1, pas sous le plus bas) → blocage 3/3" 2 "$R" "blocage 3/3"
branche_mergee "$D" feat-w
hook "$SCRIPT" "$D" "$(J f16)"; visible "F16 arrêt 5 : coupe-circuit atteint malgré l'alternance" "Coupe-circuit"

# F17 (m4) — sans jq ni python3 à son PATH, le message visible reste UN document JSON valide ; guillemets, backslash, tabulation,
# contrôle et accents décodés à l'identique (le parseur est celui de la suite, pas celui du hook).
MINBIN="$TMP/minbin"; mkdir -p "$MINBIN"
for f in /usr/bin/* /bin/* /usr/sbin/*; do n="${f##*/}"; case "$n" in jq|python|python3|python3.*|pythonw|pip*) continue ;; esac; [ -e "$MINBIN/$n" ] || ln -s "$f" "$MINBIN/$n" 2>/dev/null; done
GITBIN="$(command -v git)"; [ -e "$MINBIN/git" ] || ln -s "$GITBIN" "$MINBIN/git"
[ -z "$(PATH="$MINBIN" command -v jq)$(PATH="$MINBIN" command -v python3)" ] && ok "F17 témoin : ni jq ni python3 sur le PATH réduit" || ko "F17 PATH réduit" "ni jq ni python3" "$(PATH="$MINBIN" command -v jq python3)"
D="$(mk_repo f17)"
export VF_METHOD_BUDGET="$STUB" STUB_AUTO='[budget] ARCHIVAGE REFUSÉ : y"q\\z\tw\0001v é « ok » modifiée'
HOOK_PATH="$MINBIN" hook "$SCRIPT" "$D" "$(J f17)" --snapshot; HOOK_PATH="$MINBIN" hook "$SCRIPT" "$D" "$(J f17)"
unset VF_METHOD_BUDGET STUB_AUTO
visible "F17 PATH réduit : exit 0, UN document JSON valide" "ARCHIVAGE REFUSÉ"
WANT="$(printf 'y"q\\z\tw\001v é « ok » modifiée')"
has "$VM" "$WANT" && ok "F17 … guillemet, backslash, tabulation, contrôle \\u0001 et accents décodés à l'identique" || ko "F17 fidélité" "$WANT" "$VM"

# F18 (m4) — dossier d'état propre à l'utilisateur, droits 700 ; un lien à sa place est refusé, dit, et rien n'y est écrit.
D="$(mk_repo f18)"; hook "$SCRIPT" "$D" "$(J f18)" --snapshot
PERM="$(ls -ld "$STATE_DIR/vibeflow-fin-de-geste-$UIDN" | cut -c1-10)"
[ "$PERM" = "drwx------" ] && ok "F18 dossier d'état vibeflow-fin-de-geste-<uid>, droits 700" || ko "F18 droits" "drwx------" "$PERM"
[ ! -e "$STATE_DIR/vibeflow-fin-de-geste" ] && ok "F18 l'ancien nom partagé entre comptes n'est plus utilisé" || ko "F18 nom partagé" "absent" "présent"
HT="$TMP/lnk-tmp"; EVIL="$TMP/evil"; mkdir -p "$HT" "$EVIL"; ln -s "$EVIL" "$HT/vibeflow-fin-de-geste-$UIDN"
D="$(mk_repo f18b)"; HOOK_TMP="$HT" hook "$SCRIPT" "$D" "$(J f18b)" --snapshot
visible "F18 dossier d'état = un lien : refusé, exit 0, DIT" "dossier d'état inutilisable"
[ -z "$(ls "$EVIL")" ] && ok "F18 … rien n'est écrit à travers le lien" || ko "F18 lien" "dossier cible vide" "$(ls "$EVIL")"

echo "== test-guard-fin-de-geste : MUTANTS (MUT-1 à MUT-15) =="
make_mutant() {  # <nom> <ancienne ligne> <nouvelle ligne> ; 0 = opposable, 1 = identique, 2 = syntaxe invalide
  local out="$MUTD/$1.sh"
  MUT_OLD_ENV="$2" MUT_NEW_ENV="$3" awk '{ if ($0 == ENVIRON["MUT_OLD_ENV"]) print ENVIRON["MUT_NEW_ENV"]; else print }' "$SCRIPT" > "$out"
  cmp -s "$out" "$SCRIPT" && return 1
  bash -n "$out" 2>/dev/null || return 2
  return 0
}
mutant() {  # <n> <ancienne> <nouvelle> <scénario> <rc_original> <rc_mutant> ; le scénario rend le rc qui discrimine
  local n="$1" old="$2" new="$3" sc="$4" eo="$5" em="$6" mr ro rm
  make_mutant "mut$n" "$old" "$new"; mr=$?
  if [ "$mr" -ne 0 ]; then komut "$n" "mutant opposable" "mutation appliquée et syntaxe valide" "statut make_mutant=$mr"; return; fi
  "$sc" "$SCRIPT" "mo$n"; ro=$?; "$sc" "$MUTD/mut$n.sh" "mm$n"; rm=$?
  if [ "$ro" -eq "$eo" ] && [ "$rm" -eq "$em" ]; then okmut "$n" "$rm" "$em" "$ro" "$eo"
  else komut "$n" "rc original=$eo, rc mutant=$em" "original=$eo mutant=$em" "original=$ro mutant=$rm"; fi
}
sc_f5() { local d; d="$(mk_repo "$2")"; branche_mergee "$d" feat-ancienne; hook "$1" "$d" "$(J "$2")" --snapshot; hook "$1" "$d" "$(J "$2")"; return "$R"; }
sc_f3() { local d i; d="$(mk_repo "$2")"; hook "$1" "$d" "$(J "$2")" --snapshot; branche_mergee "$d" feat-x; for i in 1 2 3 4; do hook "$1" "$d" "$(J "$2")"; done; return "$R"; }
sc_f3b() { local d; d="$(mk_repo "$2")"; hook "$1" "$d" "$(J "$2")" --snapshot; branche_mergee "$d" feat-x; branche_mergee "$d" feat-y
  hook "$1" "$d" "$(J "$2")"; hook "$1" "$d" "$(J "$2")"; G "$d" branch -d feat-x >/dev/null 2>&1
  hook "$1" "$d" "$(J "$2")"; hook "$1" "$d" "$(J "$2")"; return "$R"; }
sc_f4() { local d; d="$(mk_repo "$2")"; hook "$1" "$d" "$(J "$2")" --snapshot; branche_mergee "$d" feat-x; hook "$1" "$d" "$(JA "$2")"; return "$R"; }
sc_f8() { local d; d="$(mk_repo "$2" clos)"; hook "$1" "$d" "$(J "$2")" --snapshot; hook "$1" "$d" "$(J "$2")"; return "$R"; }
sc_f8x() { local d; d="$(mk_repo "$2" clos)"; hook "$1" "$d" "$(J "$2")" --snapshot; hook "$1" "$d" "$(J "$2")"; [ -e "$d/.planning/archives/INDEX.tsv" ]; }
sc_f9() { local d; d="$(mk_repo "$2" clos)"; echo "x" >> "$d/.planning/workstreams/ws1/BACKLOG.md"; hook "$1" "$d" "$(J "$2")" --snapshot; hook "$1" "$d" "$(J "$2")"; return "$R"; }
sc_vis() { local d; d="$(mk_repo "$2" clos)"; hook "$1" "$d" "$(J "$2")" --snapshot; hook "$1" "$d" "$(J "$2")"; [ -n "$O" ]; }
# MUT-1 (F5) : le snapshot est ignoré, tout ce qui est rangeable est pris pour nouveau.
mutant 1 'NOUVEAU="$(LC_ALL=C comm -23 "$NOW" "$SNAP")"               # apparu depuis le snapshot de CETTE session' 'NOUVEAU="$(LC_ALL=C comm -23 "$NOW" /dev/null)"' sc_f5 0 2
# MUT-2 (F3) : le coupe-circuit est retiré, la garde bloque sans fin.
mutant 2 'if [ "$P_COUNT" -ge "$MAX_BLOCS" ]; then' 'if false; then' sc_f3 0 2
# MUT-3 (F8) : --auto remplacé par la lecture seule, plus rien n'est archivé (la seule trace : l'INDEX).
mutant 3 '[ "$MODE" = "warn" ] || ARGS=(--auto "${ARGS[@]}")' ':' sc_f8x 0 1
# MUT-4 (F9, M2) : ARCHIVAGE REFUSÉ redevient bloquant.
mutant 4 'BLOQUANT="$(printf '"'"'%s\n'"'"' "$NOUVEAU" | grep '"'"'^RANGEABLE'"'"' | annoter || true)"' 'BLOQUANT="$(printf '"'"'%s\n'"'"' "$NOUVEAU" | grep -E '"'"'^(RANGEABLE|ARCHIVAGE REFUSÉ)'"'"' | annoter || true)"' sc_f9 0 2
# MUT-5 (F3b) : un progrès ne remet plus le compteur à zéro.
mutant 5 'if [ "$TAILLE" -lt "$P_LOW" ]; then P_LOW="$TAILLE"; P_COUNT=0; P_LACHE=0; fi' ':' sc_f3b 2 0
# MUT-6 (F4) : stop_hook_active redevient une sortie muette immédiate.
mutant 6 'MODE="${VF_FIN_DE_GESTE:-block}"' 'MODE="${VF_FIN_DE_GESTE:-block}"; case "$INPUT" in *stop_hook_active*true*) exit 0 ;; esac' sc_f4 2 0
# MUT-7 (F8, M3) : un archivage de sujet préexistant redevient bloquant.
mutant 7 'BLOQUANT="$(printf '"'"'%s\n'"'"' "$NOUVEAU" | grep '"'"'^RANGEABLE'"'"' | annoter || true)"' 'BLOQUANT="$(printf '"'"'%s\n'"'"' "$NOUVEAU" | grep -E '"'"'^(RANGEABLE|ARCHIVÉ)'"'"' | annoter || true)"' sc_f8 0 2
# MUT-8 (M5) : le canal visible redevient stderr à exit 0 (invisible pour l'utilisateur) ; le témoin est stdout.
mutant 8 'sortie_ok() { emit; exit 0; }' 'sortie_ok() { [ -n "$VIS" ] && echo "$VIS" >&2; exit 0; }' sc_vis 0 1

mutp() {  # <n> <préfixe de la ligne UNIQUE du script> <remplacement> <scénario> <rc original> <rc mutant> : mutant sur une ligne désignée par son début
  local old; old="$(P="$2" awk 'index($0, ENVIRON["P"]) == 1' "$SCRIPT")"
  [ "$(printf '%s\n' "$old" | grep -c .)" -eq 1 ] || { komut "$1" "une seule ligne pour « $2 »" "mutant opposable" "$(printf '%s\n' "$old" | grep -c .) ligne(s)"; return; }
  mutant "$1" "$old" "$3" "$4" "$5" "$6"
}
sc_blkdir() { local d sf; d="$(mk_repo "$2")"; hook "$1" "$d" "$(J "$2")" --snapshot; branche_mergee "$d" feat-x
  sf="$(ls "$STATE_DIR/vibeflow-fin-de-geste-$UIDN/"*-"$2".snap)"; mkdir "${sf%.snap}.blk"; hook "$1" "$d" "$(J "$2")"; return "$R"; }
sc_rosnap() { local d ht="$TMP/ro-$2"; d="$(mk_repo "$2")"; snap_bloque "$d" "$2" "$ht"; HOOK_TMP="$ht" hook "$1" "$d" "$(J "$2")" --snapshot; [ -n "$O" ]; }
sc_pend() { local d; d="$(mk_repo "$2" clos)"; hook "$1" "$d" "$(J "$2")" --snapshot; branche_mergee "$d" feat-x; hook "$1" "$d" "$(J "$2")"
  G "$d" branch -q -d feat-x >/dev/null 2>&1; hook "$1" "$d" "$(J "$2")"; has "$O" "Archivé sans geste humain"; }
sc_low() { local d; d="$(mk_repo "$2")"; hook "$1" "$d" "$(J "$2")" --snapshot; branche_mergee "$d" feat-x; branche_mergee "$d" feat-y
  hook "$1" "$d" "$(J "$2")"; G "$d" branch -q -d feat-x >/dev/null 2>&1; hook "$1" "$d" "$(J "$2")"; branche_mergee "$d" feat-z
  hook "$1" "$d" "$(J "$2")"; G "$d" branch -q -d feat-z >/dev/null 2>&1; hook "$1" "$d" "$(J "$2")"; branche_mergee "$d" feat-w
  hook "$1" "$d" "$(J "$2")"; return "$R"; }
sc_json() { local d; d="$(mk_repo "$2")"
  export VF_METHOD_BUDGET="$STUB" STUB_AUTO='[budget] ARCHIVAGE REFUSÉ : y"q\\z\tw modifiée'
  HOOK_PATH="$MINBIN" hook "$1" "$d" "$(J "$2")" --snapshot; HOOK_PATH="$MINBIN" hook "$1" "$d" "$(J "$2")"; unset VF_METHOD_BUDGET STUB_AUTO
  doc_unique; }
sc_lnk() { local d ev="$TMP/ev-$2" ht="$TMP/lt-$2"; mkdir -p "$ev" "$ht"; ln -s "$ev" "$ht/vibeflow-fin-de-geste-$UIDN"
  d="$(mk_repo "$2")"; HOOK_TMP="$ht" hook "$1" "$d" "$(J "$2")" --snapshot; [ -z "$(ls "$ev")" ]; }
# MUT-9 (F13, M2) : l'échec d'écriture du compteur n'est plus fatal à la garde — elle bloque sans borne (exit 2).
mutp 9 'wr "$BLK" "$P_COUNT $P_LOW 0" ||' 'wr "$BLK" "$P_COUNT $P_LOW 0" || true' sc_blkdir 0 2
# MUT-10 (F14, M2) : le snapshot non écrit n'est plus dit — vert muet (le témoin est stdout).
mutp 10 '  wr "$SNAP" "$(printf' '  wr "$SNAP" "$(printf '"'"'%s\n'"'"' "$OUT" | jetons)" || true' sc_rosnap 0 1
# MUT-11 (F15, M3) : l'avis d'archivage n'est plus gardé pour le prochain exit 0 — l'utilisateur ne l'apprend jamais.
mutp 11 'if [ -n "$ARCHIVE_MSG" ]; then' 'if false; then' sc_pend 0 1
# MUT-12 (F16, m4) : la référence du progrès redevient le DERNIER arrêt — l'alternance −1/+1 n'atteint jamais le coupe-circuit.
mutp 12 'if [ "$TAILLE" -lt "$P_LOW" ]; then P_LOW=' 'if [ "$TAILLE" -lt "$P_LOW" ]; then P_COUNT=0; P_LACHE=0; fi; P_LOW="$TAILLE"' sc_low 0 2
# MUT-13 (F17, m4) : l'encodeur awk n'échappe plus les guillemets — JSON invalide (le témoin est le parseur de la suite).
mutp 13 '      if (c == "\\") o =' '      if (c == "\\") o = "\\\\"; else if (c in ctl) o = ctl[c]; else o = c' sc_json 0 1
# MUT-14 (F18, m4) : un lien à la place du dossier d'état n'est plus refusé — l'état s'écrit à travers lui.
mutp 14 '  [ -d "$DIR" ] && [ ! -L "$DIR" ]' '  [ -d "$DIR" ] || return 1' sc_lnk 0 1

# MUT-15 (F12, M1) : le jeton de stash porte de nouveau sa POSITION — un stash préexistant, décalé, est imputé à la session.
MUTBUD="$MUTD/budget-m1.sh"; cp "$HERE/../../planning-core/scripts/workstream-policy.sh" "$MUTD/workstream-policy.sh"
sed 's/flag "RANGEABLE stash : \$sha « \$msg »"/flag "RANGEABLE stash : $gd $sha « $msg »"/' "$BUDGET" > "$MUTBUD"
if cmp -s "$MUTBUD" "$BUDGET" || ! bash -n "$MUTBUD" 2>/dev/null; then komut 15 "mutant opposable" "mutation appliquée et syntaxe valide" "budget inchangé ou invalide"
else
  sc_m1() { local d; d="$(mk_repo "$2")"; stash_sur_branche_supprimee "$d" tmp-a "ancien-A"; hook "$SCRIPT" "$d" "$(J "$2")" --snapshot
    stash_sur_branche_supprimee "$d" tmp-b "nouveau-B"; hook "$SCRIPT" "$d" "$(J "$2")"; has "$E" "ancien-A"; }
  sc_m1 "" mo15; RO=$?; VF_METHOD_BUDGET="$MUTBUD" sc_m1 "" mm15; RM=$?
  if [ "$RO" -eq 1 ] && [ "$RM" -eq 0 ]; then okmut 15 "$RM" 0 "$RO" 1; else komut 15 "original : préexistant non imputé (1), mutant : imputé (0)" "original=1 mutant=0" "original=$RO mutant=$RM"; fi
fi

echo
echo "Résultat : $PASS vert(s), $FAIL rouge(s)"
[ "$FAIL" -eq 0 ]
