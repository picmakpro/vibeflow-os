#!/usr/bin/env bash
# Test de check-phase-validation.sh (Phase 60, ARCG-01, ARCG-02 ; QUAL-01) — autonome.
# Fixtures ÉCRITES À L'EXÉCUTION sous un dossier temporaire (P60-PL-20) : aucun dossier fixtures/ versionné,
# octets CRLF et BOM produits par printf. Le script se retrouve par ../check-phase-validation.sh, en source
# comme une fois copié à plat par l'engine (la suite se pose sous scripts/tests/).
# Cas CPV-TRACE-1..4 (du marqueur `proposed` au code 1, phase absente, ROADMAP absent, usage).
# Cas CPV-VALIDATED, CPV-INCONNU, CPV-MULTI, CPV-FENCE, CPV-FENCE-OUVERTE, CPV-TAG, CPV-DOUBLE, CPV-SECTIONS, CPV-DECIMAL,
# CPV-CRLF, CPV-BOM (grammaire et sections) ; CPV-WS, CPV-WS-SANS, CPV-WS-ABSENT, CPV-WS-NOM, CPV-WS-LIEN (compartiment
# nommé par --ws) ; CPV-POSTE (le gate ne lit pas le poste).
# Les cas CPV-GSD-* (preuve que le marqueur ne change rien pour le moteur GSD) s'ajoutent en 60-03.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$HERE/.." && pwd)/check-phase-validation.sh"
TARGET="$SCRIPT"

PASS=0; FAIL=0; SKIPPED=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }
skip() { echo "  ⊘ SKIP $1"; SKIPPED=$((SKIPPED+1)); }

TMP="$(mktemp -d)"
trap 'chmod -R u+rwx "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT
FX="$TMP/fx"; mkdir -p "$FX"
: > "$TMP/rcs"; : > "$TMP/fxlist"; : > "$TMP/fxsum"
mkdir "$TMP/cwd"; cd "$TMP/cwd" || exit 1
RUNDIR="$TMP/cwd"
LASTMSG=""; RC=0; OUT=""; ERR=""

# reg <relatif> : inscrit une fixture à l'empreinte de lecture seule (contenu des fichiers réguliers).
reg() {
  echo "$FX/$1" >> "$TMP/fxlist"
  if [ -f "$FX/$1" ] && [ ! -L "$FX/$1" ]; then echo "$(cksum < "$FX/$1") $FX/$1" >> "$TMP/fxsum"; fi
}
# mklab <nom> <format printf> [args] : lab plat sous $FX/<nom>, ROADMAP du dossier de planning ; positionne RUNDIR.
mklab() {
  local n="$1" fmt="$2"; shift 2; RUNDIR="$FX/$n"
  mkdir -p "$RUNDIR/.planning"; printf -- "$fmt" "$@" > "$RUNDIR/.planning/ROADMAP.md"
  reg "$n"; reg "$n/.planning"; reg "$n/.planning/ROADMAP.md"
}
# run <arguments séparés> -> RC, OUT, ERR ; appel borné (une attente devient un échec du cas, rc 142), cwd = RUNDIR.
run() {
  OUT="$(cd "$RUNDIR" && perl -e 'alarm 10; exec @ARGV' bash "$TARGET" "$@" 2>"$TMP/err")"; RC=$?
  ERR="$(cat "$TMP/err")"
  echo "$RC" >> "$TMP/rcs"
}
has() { command grep -qF -- "$1" <<<"$OUT"; }   # chaîne ici : jamais de tube (SIGPIPE + pipefail)
last() { printf '%s\n' "$OUT" | tail -1; }
case_() { if "$2"; then ok "$1"; else ko "$1 — $LASTMSG"; fi; }
msg() { LASTMSG="$1, obtenu rc $RC out[$(printf '%s' "$OUT" | tr '\n' '|' | cut -c1-200)] err[$(printf '%s' "$ERR" | tr '\n' '|' | cut -c1-200)]"; }

# ROADMAP de trois phases ; %s = lignes insérées sous le Goal de la phase 2.
RM3='# Roadmap\n\n## Milestone v1.0\n\n### Phase 1: Premiere\n**Goal:** un\n\n### Phase 2: Deuxieme\n**Goal:** deux\n%s\n### Phase 3: Troisieme\n**Goal:** trois\n'
PROP=$'**Validation:** proposed\n'

echo "== test-check-phase-validation =="

# === Tracer : du marqueur proposed au code 1 =====================================================
probe_trace1() {
  mklab t1 "$RM3" ""
  run --phase 2
  msg "aucun marqueur attendu rc 0 + PHASE 2 validee (marqueur absent)"
  { [ "$RC" -eq 0 ] && has 'PHASE 2 validee (marqueur absent)' \
    && last | command grep -q 'BILAN phase=2 marqueur=absent code=0$'; }
}
probe_trace2() {
  mklab t2 "$RM3" "$PROP"
  run --phase 2
  msg "marqueur proposed en phase 2 attendu rc 1 + PHASE 2 proposee"
  { [ "$RC" -eq 1 ] && has 'PHASE 2 proposee' && last | command grep -q 'BILAN phase=2 marqueur=proposed code=1$'; } || return 1
  run --phase 3
  msg "le marqueur de la phase 2 ne déborde pas sur la phase 3, attendu rc 0"
  [ "$RC" -eq 0 ]
}
probe_trace3() {
  mklab t3 "$RM3" ""
  run --phase 9
  msg "phase 9 absente attendu rc 3 + INDETERMINE phase introuvable"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE phase introuvable'; } || return 1
  RUNDIR="$FX/t3b"; mkdir -p "$RUNDIR/.planning"; reg t3b; reg t3b/.planning
  run --phase 2
  msg "ROADMAP absent attendu rc 3 + INDETERMINE roadmap absent"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE roadmap absent'; }
}
probe_trace4() {
  RUNDIR="$FX/t1"
  run
  msg "aucun argument attendu rc 64 + message sur stderr"; { [ "$RC" -eq 64 ] && [ -n "$ERR" ]; } || return 1
  run --phase
  msg "--phase sans valeur attendu rc 64"; { [ "$RC" -eq 64 ] && [ -n "$ERR" ]; } || return 1
  run --phase abc
  msg "--phase abc attendu rc 64"; { [ "$RC" -eq 64 ] && [ -n "$ERR" ]; } || return 1
  run --phase 2 --inconnu
  msg "argument inconnu attendu rc 64"; { [ "$RC" -eq 64 ] && [ -n "$ERR" ]; }
}
case_ CPV-TRACE-1 probe_trace1
case_ CPV-TRACE-2 probe_trace2
case_ CPV-TRACE-3 probe_trace3
case_ CPV-TRACE-4 probe_trace4

# === Grammaire du marqueur, sections, blocs de code (P60-PL-01) ===================================
probe_validated() {
  mklab v1 "$RM3" $'**Validation:** validated (dev, 2026-10-29)\n'; run --phase 2
  msg "validated (poste, date) attendu rc 0 + PHASE 2 validee"
  { [ "$RC" -eq 0 ] && has 'PHASE 2 validee' && ! has 'marqueur absent' && last | command grep -q 'marqueur=validated code=0$'; } || return 1
  mklab v2 "$RM3" $'**Validation**: proposed\n'; run --phase 2
  msg "variante deux-points hors du gras attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  mklab v3 "$RM3" $'**Validation:** PROPOSED\n'; run --phase 2
  msg "casse indifférente attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  mklab v4 "$RM3" $'**Validation:** validated\n'; run --phase 2
  msg "validated nu attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  mklab v5 "$RM3" $'**Validation:** validated sans parenthese\n'; run --phase 2
  msg "validated suivi d'un texte hors parenthèses attendu rc 3 (jamais un vert permissif)"; [ "$RC" -eq 3 ]
}
probe_inconnu() {
  mklab i1 "$RM3" $'**Validation:** propose\n'; run --phase 2
  msg "valeur propose attendu rc 3 + valeur de marqueur inconnue"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE valeur de marqueur inconnue' && last | command grep -q 'marqueur=inconnu code=3$'; } || return 1
  mklab i2 "$RM3" $'**Validation:**\n'; run --phase 2
  msg "valeur vide attendu rc 3"; [ "$RC" -eq 3 ]
}
probe_multi() {
  mklab m1 "$RM3" $'**Validation:** proposed\n**Validation:** validated\n'; run --phase 2
  msg "deux lignes de marqueur attendu rc 3 + marqueurs multiples"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE marqueurs multiples' && last | command grep -q 'marqueur=multiple code=3$'; }
}
probe_fence() {
  mklab f1 "$RM3" $'```\n**Validation:** proposed\n```\n'; run --phase 2
  msg "marqueur dans un bloc de code attendu rc 0 (marqueur absent)"; { [ "$RC" -eq 0 ] && has 'marqueur absent'; } || return 1
  mklab f2 "$RM3" $'~~~\n**Validation:** proposed\n~~~\n'; run --phase 2
  msg "marqueur dans un bloc tilde attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  mklab f3 "$RM3" $'<!-- **Validation:** proposed -->\n'; run --phase 2
  msg "marqueur dans un commentaire HTML d'une ligne attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  mklab f4 "$RM3" $'<!--\n**Validation:** proposed\n-->\n'; run --phase 2
  msg "marqueur dans un commentaire HTML multi-ligne attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  mklab f5 "$RM3" $'`<!--` est un exemple\n**Validation:** proposed\n'; run --phase 2
  msg "ouvreur de commentaire dans un span de code attendu sans effet (rc 1 lu)"; [ "$RC" -eq 1 ]
}
probe_fence_ouverte() {
  mklab fo '# Roadmap\n\n```\nexemple jamais ferme\n\n### Phase 2: Deuxieme\n**Validation:** proposed\n'; run --phase 2
  msg "bloc de code jamais fermé attendu rc 3 + bloc de code non ferme"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE bloc de code non ferme'; } || return 1
  mklab fc '# Roadmap\n\n### Phase 2: Deuxieme\n**Validation:** validated\n<!-- jamais ferme\n'; run --phase 2
  msg "commentaire jamais fermé attendu rc 3 + commentaire HTML non ferme"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE commentaire HTML non ferme'; }
}
probe_tag() {
  mklab tg '# Roadmap\n\n### Phase 2 (x): Deuxieme\n**Validation:** proposed\n'; run --phase 2
  msg "titre à tag entre parenthèses attendu rc 1"; [ "$RC" -eq 1 ]
}
probe_double() {
  mklab d1 '# Roadmap\n\n## Phase 2 — note\n\n### Phase 2: Deuxieme\n**Validation:** proposed\n'; run --phase 2
  msg "titre sans deux-points avant la vraie section attendu rc 1 (une seule section)"; [ "$RC" -eq 1 ]
}
probe_sections() {
  mklab s1 '# Roadmap\n\n### Phase 2: Une\n**Validation:** proposed\n\n### Phase 2: Deux\n'; run --phase 2
  msg "deux sections pour la phase 2 attendu rc 3 + sections multiples"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE sections multiples'; }
}
probe_decimal() {
  mklab dc '# Roadmap\n\n### Phase 01.1: Inseree\n**Validation:** proposed\n\n### Phase 2: Deux\n'; run --phase 1.1
  msg "--phase 1.1 désigne Phase 01.1 attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  run --phase 1
  msg "--phase 1 ne désigne pas 01.1 attendu rc 3"; [ "$RC" -eq 3 ] || return 1
  run --phase 02
  msg "--phase 02 désigne la phase 2, sans marqueur attendu rc 0"; [ "$RC" -eq 0 ]
}
probe_crlf() {
  mklab cr "${RM3//\\n/\\r\\n}" $'**Validation:** proposed\r\n'; run --phase 2
  msg "ROADMAP en CRLF attendu rc 1"; [ "$RC" -eq 1 ]
}
probe_bom() {
  mklab bm '\357\273\277### Phase 2: Deuxieme\n**Validation:** proposed\n'; run --phase 2
  msg "BOM de tête sur le titre de la section attendu rc 1"; [ "$RC" -eq 1 ]
}
case_ CPV-VALIDATED probe_validated
case_ CPV-INCONNU probe_inconnu
case_ CPV-MULTI probe_multi
case_ CPV-FENCE probe_fence
case_ CPV-FENCE-OUVERTE probe_fence_ouverte
case_ CPV-TAG probe_tag
case_ CPV-DOUBLE probe_double
case_ CPV-SECTIONS probe_sections
case_ CPV-DECIMAL probe_decimal
case_ CPV-CRLF probe_crlf
case_ CPV-BOM probe_bom

# === Compartiment nommé par --ws, jamais déduit (P60-PL-02, DLWS-04) ===============================
# mkws <lab> <compartiment> <format printf> [args] : lab partitionné, ROADMAP du compartiment ; positionne RUNDIR.
mkws() {
  local n="$1" ws="$2" fmt="$3"; shift 3; RUNDIR="$FX/$n"
  mkdir -p "$RUNDIR/.planning/workstreams/$ws"; printf -- "$fmt" "$@" > "$RUNDIR/.planning/workstreams/$ws/ROADMAP.md"
  reg "$n"; reg "$n/.planning"; reg "$n/.planning/workstreams"; reg "$n/.planning/workstreams/$ws"
  reg "$n/.planning/workstreams/$ws/ROADMAP.md"
}
mkpart() { mkws "$1" w1 "$RM3" "$PROP"; mkws "$1" w2 "$RM3" ""; printf -- "$RM3" "" > "$RUNDIR/.planning/ROADMAP.md"; reg "$1/.planning/ROADMAP.md"; }
probe_ws() {
  mkpart p1
  run --phase 2 --ws w1
  msg "--ws w1 (proposed) attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  run --phase 2 --ws w2
  msg "--ws w2 (sans marqueur) attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  run --ws=w1 --phase=2
  msg "forme --x=valeur attendu rc 1"; [ "$RC" -eq 1 ]
}
probe_ws_sans() {
  mkpart p2
  printf 'w1\n' > "$RUNDIR/.planning/active-workstream"; reg p2/.planning/active-workstream
  export GSD_WORKSTREAM=w1 VF_WORKSTREAM=w1
  run --phase 2; local r=$RC o=$OUT e=$ERR
  unset GSD_WORKSTREAM VF_WORKSTREAM
  RC=$r; OUT=$o; ERR=$e
  msg "lab partitionné sans --ws (pointeur et variables armés sur w1) attendu rc 3 + lab partitionne sans --ws"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE lab partitionne sans --ws'; }
}
probe_ws_absent() {
  mkpart p3; run --phase 2 --ws w9
  msg "--ws w9 attendu rc 3 + compartiment absent"; { [ "$RC" -eq 3 ] && has 'INDETERMINE compartiment absent'; } || return 1
  mklab p3b "$RM3" ""; run --phase 2 --ws w1
  msg "--ws sur un lab plat attendu rc 3 + compartiment absent"; { [ "$RC" -eq 3 ] && has 'INDETERMINE compartiment absent'; }
}
probe_ws_nom() {
  mkpart p4; run --phase 2 --ws '../x'
  msg "--ws ../x attendu rc 64"; { [ "$RC" -eq 64 ] && [ -n "$ERR" ]; }
}
probe_ws_lien() {
  mkpart p5; ln -s w1 "$RUNDIR/.planning/workstreams/w3"; reg p5/.planning/workstreams/w3
  run --phase 2 --ws w3
  msg "compartiment en lien symbolique attendu rc 5 + ILLISIBLE sur stdout et stderr"
  { [ "$RC" -eq 5 ] && has 'ILLISIBLE compartiment : compartiment-lien-symbolique' \
    && printf '%s' "$ERR" | command grep -qF 'ILLISIBLE compartiment : compartiment-lien-symbolique'; }
}
probe_poste() {
  mklab po "$RM3" "$PROP"
  local r
  for r in solo product dev; do
    export VF_ROLE=$r; run --phase 2; local rc=$RC; unset VF_ROLE
    RC=$rc; msg "VF_ROLE=$r attendu rc 1 (le gate ne lit pas le poste)"; [ "$RC" -eq 1 ] || return 1
  done
}
case_ CPV-WS probe_ws
case_ CPV-WS-SANS probe_ws_sans
case_ CPV-WS-ABSENT probe_ws_absent
case_ CPV-WS-NOM probe_ws_nom
case_ CPV-WS-LIEN probe_ws_lien
case_ CPV-POSTE probe_poste

echo "== resultat : $PASS ok, $FAIL ko ($SKIPPED skip) =="
[ "$FAIL" -eq 0 ]
