#!/usr/bin/env bash
# Test de check-phase-validation.sh (Phase 60, ARCG-01, ARCG-02 ; QUAL-01) — autonome.
# Fixtures ÉCRITES À L'EXÉCUTION sous un dossier temporaire (P60-PL-20) : aucun dossier fixtures/ versionné,
# octets CRLF et BOM produits par printf. Le script se retrouve par ../check-phase-validation.sh, en source
# comme une fois copié à plat par l'engine (la suite se pose sous scripts/tests/).
# Cas CPV-TRACE-1..4 (du marqueur `proposed` au code 1, phase absente, ROADMAP absent, usage).
# Cas CPV-VALIDATED, CPV-INCONNU, CPV-MULTI, CPV-FENCE, CPV-FENCE-OUVERTE, CPV-TAG, CPV-DOUBLE, CPV-SECTIONS, CPV-DECIMAL,
# CPV-CRLF, CPV-BOM (grammaire et sections) ; CPV-WS, CPV-WS-SANS, CPV-WS-ABSENT, CPV-WS-NOM, CPV-WS-LIEN (compartiment
# nommé par --ws) ; CPV-POSTE (le gate ne lit pas le poste).
# Cas CPV-LIEN, CPV-FIFO, CPV-DOSSIER, CPV-GROS, CPV-ILLISIBLE (refus en 5 avant lecture), CPV-NOECHO, CPV-EXEC (sans
# évaluation de chaîne, arguments hostiles inertes), CPV-RO, CPV-CODES (ensemble observé = {0, 1, 3, 5, 64}, jamais 2).
# Cas CPV-FERME (fermeture de la section au titre suivant), CPV-NIVEAUX (niveaux de titre 2 à 4), CPV-FENCE-INDENTEE.
# Cas CPV-DETAILS-ACTIF (jalon actif lu, jalon livré ou neutre caché), CPV-BILAN-ILLISIBLE (champ BILAN lu par les consommateurs).
# Cas CPV-IDS, CPV-PREFIXE, CPV-ID-USAGE, CPV-DETAILS, CPV-FENCE-COMMONMARK, CPV-MARQUEUR-FORMES, CPV-CR-ISOLE, CPV-GSD-IDS (grammaire de --phase
# de gsd-core, jalons livrés <details>, barrières CommonMark, survivants MK et MI de la revue).
# Mutants CPV-MUT-1..46 (QUAL-01) : une ligne du script altérée, chacun différent de l'original (cmp -s), valide (bash -n),
# rouge pour la raison attendue (code attendu/obtenu imprimé), original revérifié vert.
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
  run --phase .5
  msg "--phase .5 (identifiant mal formé) attendu rc 64"; { [ "$RC" -eq 64 ] && [ -n "$ERR" ]; } || return 1
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
probe_ferme() {
  mklab fm '# Roadmap\n\n### Phase 2: Deuxieme\n**Goal:** deux\n\n### Phase 3: Troisieme\n**Goal:** trois\n**Validation:** proposed\n'; run --phase 2
  msg "le marqueur de la phase 3, APRÈS la section de la phase 2, ne doit pas lui être attribué : attendu rc 0 (phase 2)"
  [ "$RC" -eq 0 ] || return 1
  run --phase 3
  msg "témoin positif : le même marqueur appartient à la phase 3, attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  mklab fm2 '# Roadmap\n\n### Phase 2: Deuxieme\n**Goal:** deux\n\n## Autre section\n**Validation:** proposed\n'; run --phase 2
  msg "le marqueur d'une section de niveau inférieur (## Autre section) ne déborde pas sur la phase 2 : attendu rc 0"
  [ "$RC" -eq 0 ] || return 1
  mklab fm3 '# Roadmap\n\n### Phase 2: Deuxieme\n**Goal:** deux\n\n#### Detail\n**Validation:** proposed\n'; run --phase 2
  msg "témoin positif : un sous-titre plus profond appartient à la section, attendu rc 1"
  [ "$RC" -eq 1 ]
}
probe_niveaux() {
  mklab nv2 '# Roadmap\n\n## Phase 2: Deuxieme\n**Validation:** proposed\n'; run --phase 2
  msg "titre de niveau 2 reconnu, attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  mklab nv4 '# Roadmap\n\n#### Phase 2: Deuxieme\n**Validation:** proposed\n'; run --phase 2
  msg "titre de niveau 4 reconnu, attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  mklab nv5 '# Roadmap\n\n##### Phase 2: Deuxieme\n**Validation:** proposed\n'; run --phase 2
  msg "titre de niveau 5 non reconnu comme section, attendu rc 3 + phase introuvable"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE phase introuvable'; } || return 1
  mklab nv1 '# Phase 2: Deuxieme\n**Validation:** proposed\n'; run --phase 2
  msg "titre de niveau 1 non reconnu comme section, attendu rc 3 + phase introuvable"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE phase introuvable'; }
}
probe_fence_indentee() {
  mklab fi '# Roadmap\n\n### Phase 2: Deuxieme\n  ```\n**Validation:** proposed\n  ```\n'; run --phase 2
  msg "marqueur dans un bloc de code dont la barrière est indentée (espaces) attendu rc 0 (marqueur absent)"
  { [ "$RC" -eq 0 ] && has 'marqueur absent'; } || return 1
  mklab fi2 '# Roadmap\n\n### Phase 2: Deuxieme\n\t~~~\n**Validation:** proposed\n\t~~~\n'; run --phase 2
  msg "une tabulation (4 colonnes) devant ~~~ n'ouvre aucune barrière : le marqueur reste lu, attendu rc 1"
  [ "$RC" -eq 1 ] || return 1
  mklab fi3 '# Roadmap\n\n### Phase 2: Deuxieme\n    ```\n**Validation:** proposed\n    ```\n'; run --phase 2
  msg "quatre espaces devant trois accents graves n'ouvrent aucune barrière (code indenté) : attendu rc 1"
  [ "$RC" -eq 1 ] || return 1
  mklab fi4 '# Roadmap\n\n### Phase 2: Deuxieme\n   ```\n**Validation:** proposed\n   ```\n'; run --phase 2
  msg "témoin positif : trois espaces devant trois accents graves ouvrent une barrière, attendu rc 0 (marqueur absent)"
  { [ "$RC" -eq 0 ] && has 'marqueur absent'; }
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
case_ CPV-FERME probe_ferme
case_ CPV-NIVEAUX probe_niveaux
case_ CPV-FENCE-INDENTEE probe_fence_indentee

# === Grammaire de --phase alignée sur gsd-core : ids custom, suffixe lettre, préfixe projet (P60-D-02) ============
probe_ids() {
  mklab id1 '# Roadmap\n\n### Phase AUTH: Auth flow\n**Goal:** g\n**Validation:** proposed\n\n### Phase 12A: Suffixe\n**Goal:** g\n**Validation:** proposed\n\n### Phase 7.1A: Decimale\n**Goal:** g\n**Validation:** proposed\n'
  run --phase AUTH
  msg "id custom AUTH (phase add --id) attendu rc 1, la section est trouvée comme par gsd"; [ "$RC" -eq 1 ] || return 1
  run --phase auth
  msg "id custom en minuscules attendu rc 1 (casse indifférente comme gsd)"; [ "$RC" -eq 1 ] || return 1
  run --phase 12A
  msg "suffixe lettre 12A attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  run --phase 12a
  msg "suffixe lettre en minuscule attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  run --phase 12
  msg "12 ne désigne pas 12A, attendu rc 3 + phase introuvable"; { [ "$RC" -eq 3 ] && has 'INDETERMINE phase introuvable'; } || return 1
  run --phase 7.1A
  msg "segment décimal à suffixe lettre 7.1A attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  mklab id2 '# Roadmap\n\n### Phase AUTH: Auth flow\n**Goal:** g\n'
  run --phase AUTH
  msg "id custom sans marqueur attendu rc 0 + marqueur absent (le poste solo ne change pas)"; { [ "$RC" -eq 0 ] && has 'marqueur absent'; }
}
probe_prefixe() {
  mklab pf1 '# Roadmap\n\n### Phase CK-03: Prefixee\n**Goal:** g\n**Validation:** proposed\n'
  run --phase CK-03
  msg "préfixe projet CK-03 attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  run --phase CK-3
  msg "CK-3 = CK-03 (zéros de tête) attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  run --phase 3
  msg "le numéro nu 3 désigne CK-03 quand rien d'autre ne porte 3 (lecture tolérante de gsd) attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  run --phase 03
  msg "03 désigne CK-03 attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  mklab pf2 '# Roadmap\n\n### Phase 3: Nue\n**Goal:** g\n\n### Phase CK-03: Prefixee\n**Goal:** g\n**Validation:** proposed\n'
  run --phase 3
  msg "la forme exacte gagne : 3 désigne la phase nue (sans marqueur), attendu rc 0, jamais sections multiples"; [ "$RC" -eq 0 ] || return 1
  run --phase CK-03
  msg "CK-03 désigne la phase préfixée attendu rc 1"; [ "$RC" -eq 1 ]
}
probe_id_usage() {
  RUNDIR="$FX/t1"
  local bad
  for bad in .5 5. a..b 'a;b' 'a b' '-x' '_x' 'a/b' "$(printf 'x%.0s' $(seq 1 65))"; do
    run --phase "$bad"
    msg "--phase « ${bad:0:12} » attendu rc 64"; { [ "$RC" -eq 64 ] && [ -n "$ERR" ]; } || return 1
  done
  mklab id3 '# Roadmap\n\n### Phase 2: Deux\n**Goal:** g\n'
  run --phase "$(printf 'x%.0s' $(seq 1 64))"
  msg "un id de 64 caractères reste admis (rc 3 : introuvable)"; [ "$RC" -eq 3 ]
}
# === Jalons livrés : blocs <details> ignorés comme le fait gsd-core (stripShippedMilestones) =====================
probe_details() {
  local D1='# Roadmap\n\n<details>\n<summary>v1.0 shipped</summary>\n\n### Phase 1: Vieille\n**Goal:** a\n**Validation:** proposed\n\n### Phase 2: Vieille2\n**Goal:** b\n\n### Phase 5: Seule\n**Goal:** c\n**Validation:** proposed\n\n</details>\n\n## Milestone v2\n\n### Phase 1: Neuve\n**Goal:** a\n\n### Phase 2: Neuve2\n**Goal:** b\n**Validation:** proposed\n'
  mklab dt1 "$D1"
  run --phase 1
  msg "la phase 1 vivante, hors du bloc livré (qui porte une autre phase 1 proposée), attendu rc 0, jamais sections multiples"; [ "$RC" -eq 0 ] || return 1
  run --phase 2
  msg "la phase 2 vivante (proposée) attendu rc 1, le bloc livré ne la double pas"; [ "$RC" -eq 1 ] || return 1
  run --phase 5
  msg "phase 5 présente seulement dans le bloc livré attendu rc 3 + phase introuvable (gsd : found false)"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE phase introuvable'; } || return 1
  mklab dt2 '# Roadmap\n\n<details open>\n<summary>v2 actif</summary>\n\n### Phase 4: Active\n**Goal:** a\n**Validation:** proposed\n\n</details>\n'
  run --phase 4
  msg "<details open> marque le jalon ACTIF et reste visible (gsd) : attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  mklab dt3 '# Roadmap\n\n<DETAILS>\n### Phase 1: Vieille\n**Validation:** proposed\n</DETAILS>\n\n### Phase 1: Neuve\n**Goal:** a\n'
  run --phase 1
  msg "balises en majuscules : casse indifférente, attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  mklab dt4 '# Roadmap\n\n<details>\n### Phase 6: Visible\n**Goal:** a\n**Validation:** proposed\n<details></details>\n'
  run --phase 6
  msg "un <details> suivi d'un autre <details> avant sa fermeture n'ouvre aucun bloc (gsd) : la phase 6 reste visible, attendu rc 1"
  [ "$RC" -eq 1 ] || return 1
  mklab dt5 '# Roadmap\n\n<details>\n### Phase 6: Visible\n**Goal:** a\n**Validation:** proposed\n'
  run --phase 6
  msg "un <details> jamais fermé n'ouvre aucun bloc : la phase 6 reste visible, attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  mklab dt6 '# Roadmap\n\n### Phase 3: Titre<details>\ncache\n</details>\n**Goal:** a\n**Validation:** proposed\n'
  run --phase 3
  msg "le texte qui précède un <details> sur sa ligne reste visible (le titre), attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  mklab dt7 '# Roadmap\n\n### Phase 3: Titre\n**Goal:** a\n<details>\n**Validation:** proposed\n</details>\n'
  run --phase 3
  msg "un marqueur à l'intérieur d'un bloc <details> est caché comme le reste (gsd), attendu rc 0"; [ "$RC" -eq 0 ]
}
# === Jalon ACTIF en <details> : lu comme le sert gsd-core (surensemble), un jalon livré reste caché ===========
# gsd-core (`roadmap get-phase`) cherche d'abord dans la fenêtre du jalon courant, qui garde le bloc du jalon actif ;
# le gate lit tout bloc dont le <summary> porte un marqueur d'activité. Un summary livré ou neutre reste caché.
probe_details_actif() {
  local U='# Roadmap\n\n- 🚧 **v2.0 Next** - Phases 5-6 (in progress)\n\n<details><summary>%s</summary>\n\n### Phase 5: Active\n**Goal:** a\n**Validation:** proposed\n\n</details>\n'
  local d n=0
  for d in '🚧 v2.0 Next' '🔄 v2.0 Next' 'v2.0 Next in progress' 'v2.0 Next IN PROGRESS' 'v2.0 Next WIP' 'v2.0 Next ACTIVE'; do
    n=$((n+1)); mklab "da1-$n" "$U" "$d"
    run --phase 5
    msg "<summary> « $d » : jalon actif, bloc lu, la phase 5 proposée rend 1 (gsd la sert)"
    [ "$RC" -eq 1 ] || return 1
  done
  for d in '✅ v1.0 Old SHIPPED' 'v1.0 Old' 'Details'; do
    n=$((n+1)); mklab "da2-$n" "$U" "$d"
    run --phase 5
    msg "<summary> « $d » : ni actif ni lu, bloc caché, phase 5 introuvable, attendu rc 3"
    { [ "$RC" -eq 3 ] && has 'INDETERMINE phase introuvable'; } || return 1
  done
  mklab da3 '# Roadmap\n\n<details>\n<summary>🚧 v2.0 IN PROGRESS</summary>\n### Phase 5: Active\n**Goal:** a\n**Validation:** proposed</details>\n'
  run --phase 5
  msg "marqueur sur la ligne de fermeture d'un bloc actif : lu (texte avant </details>), attendu rc 1"; [ "$RC" -eq 1 ]
}
# === BILAN : marqueur présent mais illisible = champ machine que lisent les consommateurs (P60-D-04, P60-H-04) =====
probe_bilan_illisible() {
  local m n=0
  for m in 'proposé' 'proposée' 'proposed.'; do
    n=$((n+1)); mklab "bi1-$n" "$RM3" "**Validation:** $m"$'\n'
    run --phase 2
    msg "marqueur « $m » : rc 3 et BILAN marqueur=inconnu"
    { [ "$RC" -eq 3 ] && last | command grep -q 'BILAN phase=2 marqueur=inconnu code=3$'; } || return 1
  done
  mklab bi2 "$RM3" $'**Validation:** proposed\n**Validation:** validated\n'
  run --phase 2
  msg "deux lignes de marqueur : rc 3 et BILAN marqueur=multiple"
  { [ "$RC" -eq 3 ] && last | command grep -q 'BILAN phase=2 marqueur=multiple code=3$'; } || return 1
  mklab bi3 "$RM3" ""
  run --phase 9
  msg "phase introuvable : rc 3 et BILAN marqueur=- (les consommateurs continuent)"
  { [ "$RC" -eq 3 ] && last | command grep -q 'BILAN phase=9 marqueur=- code=3$'; } || return 1
  run --phase 2
  msg "marqueur absent : rc 0 et BILAN marqueur=absent (les consommateurs continuent)"
  { [ "$RC" -eq 0 ] && last | command grep -q 'BILAN phase=2 marqueur=absent code=0$'; }
}
# === Barrières de code CommonMark : ouverture, fermeture ===========================================================
probe_fence_commonmark() {
  mklab cm1 '# Roadmap\n\n### Phase 2: Deux\n``` `x` ```\n**Validation:** proposed\n'
  run --phase 2
  msg "une ligne « trois accents graves, espace, x entre accents graves » (accent grave dans l'info string) n'est pas une barrière : le marqueur reste lu, attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  mklab cm2 '# Roadmap\n\n### Phase 2: Deux\n````\n**Validation:** proposed\n```\n**Validation:** validated\n'
  run --phase 2
  msg "une barrière de 4 accents n'est pas fermée par 3 : bloc jamais fermé, attendu rc 3 + bloc de code non ferme"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE bloc de code non ferme'; } || return 1
  mklab cm3 '# Roadmap\n\n### Phase 2: Deux\n````\n**Validation:** proposed\n`````\n'
  run --phase 2
  msg "témoin positif : 4 accents fermés par 5 cachent le marqueur, attendu rc 0 + marqueur absent"; { [ "$RC" -eq 0 ] && has 'marqueur absent'; } || return 1
  mklab cm4 '# Roadmap\n\n### Phase 2: Deux\n```\n```js\n**Validation:** proposed\n```\n'
  run --phase 2
  msg "une ligne trois-accents-graves+js (info string) ne ferme pas la barrière : le marqueur reste caché, attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  mklab cm5 '# Roadmap\n\n### Phase 2: Deux\n~~~ a`b`\n**Validation:** proposed\n~~~\n'
  run --phase 2
  msg "une barrière tilde admet un accent grave dans son info string : marqueur caché, attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  mklab cm6 '# Roadmap\n\n### Phase 2: Deux\n~~~\n**Validation:** proposed\n```\n~~~\n'
  run --phase 2
  msg "une barrière tilde ne se ferme pas par des accents graves, mais par des tildes : marqueur caché, attendu rc 0"; [ "$RC" -eq 0 ]
}
# === Survivants de mutation de la revue (MK, MI) =====================================================================
probe_marqueur_formes() {
  mklab mf1 "$RM3" $'**Validation** : proposed\n'; run --phase 2
  msg "**Validation** : proposed (espace avant les deux-points, hors du gras) attendu rc 1, jamais « marqueur absent »"
  { [ "$RC" -eq 1 ] && has 'PHASE 2 proposee'; }
}
probe_cr_isole() {
  mklab cr1 '# Roadmap\n\n### Phase 2: Deux\n**Goal**: g\r**Validation:** proposed\n'; run --phase 2
  msg "un CR isolé est une fin de ligne : le marqueur qui le suit est une ligne, attendu rc 1"; [ "$RC" -eq 1 ]
}
case_ CPV-IDS probe_ids
case_ CPV-PREFIXE probe_prefixe
case_ CPV-ID-USAGE probe_id_usage
case_ CPV-DETAILS probe_details
case_ CPV-FENCE-COMMONMARK probe_fence_commonmark
case_ CPV-MARQUEUR-FORMES probe_marqueur_formes
case_ CPV-CR-ISOLE probe_cr_isole
case_ CPV-DETAILS-ACTIF probe_details_actif
case_ CPV-BILAN-ILLISIBLE probe_bilan_illisible

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

# === Entrées non fiables : refus bruyant AVANT lecture (T-60-02) ===================================
# mkrm <nom> : lab dont .planning existe, sans ROADMAP ; positionne RUNDIR.
mkrm() { RUNDIR="$FX/$1"; mkdir -p "$RUNDIR/.planning"; reg "$1"; reg "$1/.planning"; }
probe_lien() {
  mkrm lien; printf '### Phase 2: Deux\n**Validation:** proposed\n' > "$FX/lien-reel.md"; reg lien-reel.md
  ln -sf "$FX/lien-reel.md" "$RUNDIR/.planning/ROADMAP.md"; reg lien/.planning/ROADMAP.md
  run --phase 2
  msg "ROADMAP lien symbolique vers un fichier conforme attendu rc 5 + ILLISIBLE sur stdout et stderr"
  { [ "$RC" -eq 5 ] && has 'ILLISIBLE roadmap : lien symbolique' \
    && printf '%s' "$ERR" | command grep -qF 'ILLISIBLE roadmap : lien symbolique'; }
}
probe_fifo() {
  mkrm fifo; [ -p "$RUNDIR/.planning/ROADMAP.md" ] || mkfifo "$RUNDIR/.planning/ROADMAP.md"; reg fifo/.planning/ROADMAP.md
  run --phase 2
  msg "FIFO attendu rc 5 sans blocage (142 = lue)"; [ "$RC" -eq 5 ]
}
probe_dossier() {
  mkrm dossier; mkdir -p "$RUNDIR/.planning/ROADMAP.md"; reg dossier/.planning/ROADMAP.md
  run --phase 2
  msg "dossier attendu rc 5"; [ "$RC" -eq 5 ]
}
probe_gros() {
  mkrm gros
  dd if=/dev/zero bs=1048577 count=1 2>/dev/null | tr '\0' 'x' > "$RUNDIR/.planning/ROADMAP.md"; reg gros/.planning/ROADMAP.md
  run --phase 2
  msg "1048577 octets attendu rc 5"; [ "$RC" -eq 5 ] || return 1
  mkrm borne
  dd if=/dev/zero bs=1048576 count=1 2>/dev/null | tr '\0' 'x' > "$RUNDIR/.planning/ROADMAP.md"; reg borne/.planning/ROADMAP.md
  run --phase 2
  msg "1048576 octets (la borne incluse) attendu rc 3, pas 5"; [ "$RC" -eq 3 ]
}
probe_illisible() {
  mklab ill "$RM3" "$PROP"; chmod 000 "$RUNDIR/.planning/ROADMAP.md"; run --phase 2
  local r=$RC; chmod 600 "$RUNDIR/.planning/ROADMAP.md"; RC=$r
  msg "ROADMAP chmod 000 attendu rc 5 + « fichier illisible »"; { [ "$RC" -eq 5 ] && has "ILLISIBLE roadmap : fichier illisible"; }
}
case_ CPV-LIEN probe_lien
case_ CPV-FIFO probe_fifo
case_ CPV-DOSSIER probe_dossier
case_ CPV-GROS probe_gros
if [ "$(id -u)" -eq 0 ]; then skip "CPV-ILLISIBLE (suite jouée en root : chmod 000 n'interdit rien)"
else case_ CPV-ILLISIBLE probe_illisible; fi

# === Contenu du ROADMAP jamais réimprimé =============================================================
MARK="zzSECRETzz"
probe_noecho() {
  mklab ne '# Roadmap\n\n### Phase 2: %s titre\n**Goal:** %s\n**Validation:** proposed\n' "$MARK" "$MARK"; run --phase 2
  msg "attendu rc 1 sans $MARK sur stdout ni stderr"
  { [ "$RC" -eq 1 ] && ! has "$MARK" && ! printf '%s' "$ERR" | command grep -qF "$MARK"; } || return 1
  mklab ne2 "$RM3" "**Validation:** $MARK"$'\n'; run --phase 2
  msg "valeur inconnue attendu rc 3 sans $MARK sur stdout ni stderr"
  { [ "$RC" -eq 3 ] && ! has "$MARK" && ! printf '%s' "$ERR" | command grep -qF "$MARK"; }
}
case_ CPV-NOECHO probe_noecho

# === Forme exec : aucune évaluation de chaîne, arguments hostiles inertes ==============================
probe_exec() {
  local n; n="$(awk '!/^[[:space:]]*#/ && /(^|[^A-Za-z_])eval([^A-Za-z_]|$)/{n++} END{print n+0}' "$SCRIPT")"
  LASTMSG="le script appelle une évaluation dynamique de chaîne ($n ligne(s))"; [ "$n" = 0 ] || return 1
  mkpart ex
  run --phase 2 --ws "w a'b \$(touch pwned)"
  msg "nom de compartiment hostile attendu rc 64 sans exécution"; { [ "$RC" -eq 64 ] && [ ! -e "$RUNDIR/pwned" ]; } || return 1
  run --phase '1;touch pwned'
  msg "numéro de phase hostile attendu rc 64 sans exécution"; { [ "$RC" -eq 64 ] && [ ! -e "$RUNDIR/pwned" ]; }
}
case_ CPV-EXEC probe_exec

# === Lecture seule, couverture des codes ===========================================================
probe_ro() {
  LC_ALL=C sort -u "$TMP/fxlist" > "$TMP/fxl"; find "$FX" -mindepth 1 | LC_ALL=C sort > "$TMP/fxnow"
  LASTMSG="le dossier de fixtures a changé de contenu (fichier créé ou supprimé par le script)"
  cmp -s "$TMP/fxl" "$TMP/fxnow" || return 1
  local a b p
  while read -r a b p; do
    LASTMSG="fixture modifiée : $p"
    [ "$(cksum < "$p")" = "$a $b" ] || return 1
  done < "$TMP/fxsum"
  return 0
}
case_ CPV-RO probe_ro
probe_codes() {
  LC_ALL=C sort -u "$TMP/rcs" > "$TMP/obs"; printf '0\n1\n3\n5\n64\n' > "$TMP/exp-codes"
  local manq extra
  manq="$(comm -13 "$TMP/obs" "$TMP/exp-codes" | tr '\n' ' ')"; extra="$(comm -23 "$TMP/obs" "$TMP/exp-codes" | tr '\n' ' ')"
  LASTMSG="codes manquants [$manq] en trop [$extra]"; [ -z "$manq" ] && [ -z "$extra" ]
}
case_ CPV-CODES probe_codes

# === Preuve moteur GSD : le marqueur ne change rien pour les lecteurs du moteur (P60-D-03 a, P60-PL-19) ==========
# Fixtures générées sous $TMP/gsd (hors $FX : CPV-RO est déjà passé), moteur lancé avec --cwd sur ces seuls labs,
# jamais dans le dépôt (T-60-36). Aucun numéro de version du moteur écrit ici : seuls des champs sont comparés.
GSDJS="${HOME:-/nonexistent}/.claude/gsd-core/bin/gsd-tools.cjs"
GSD="$TMP/gsd"; mkdir -p "$GSD"
GRC=0
GSD_VALID='**Validation:** validated (dev, 2026-10-29)'

# gsd_roadmap <ligne de titre de la phase 2> <ligne de marqueur ou vide> : ROADMAP à trois phases, sur la forme que
# le moteur écrit (**Goal:**, **Requirements**, **Depends on:**, **Plans:**), cases de checklist comprises.
gsd_roadmap() {
  printf '# Roadmap\n\n## Milestone v1.0\n\n- [ ] Phase 1: Premiere\n- [ ] Phase 2: Deuxieme\n- [ ] Phase 3: Troisieme\n\n'
  printf '### Phase 1: Premiere\n**Goal:** un\n**Requirements**: TBD\n**Depends on:** Nothing\n**Plans:** 0 plans\n\n'
  printf '%s\n**Goal:** deux\n' "$1"
  if [ -n "$2" ]; then printf '%s\n' "$2"; fi
  printf '**Requirements**: TBD\n**Depends on:** Phase 1\n**Plans:** 0 plans\n\n'
  printf '### Phase 3: Troisieme\n**Goal:** trois\n**Requirements**: TBD\n**Depends on:** Phase 2\n**Plans:** 0 plans\n'
}
# gsd_mklab <nom> <compartiment ou -> <titre> <marqueur> : lab sous $GSD/<nom>, ROADMAP dans le dossier de planning
# du lab plat ou dans celui du compartiment.
gsd_mklab() {
  local d="$GSD/$1/.planning"
  if [ "$2" != - ]; then d="$d/workstreams/$2"; fi
  mkdir -p "$d"; gsd_roadmap "$3" "$4" > "$d/ROADMAP.md"
}
# gsd_do <lab> <compartiment ou -> <fichier de sortie> <arguments du moteur...> : commande du moteur sur le lab,
# sortie brute dans <fichier>, code dans GRC. Appel borné, cwd hors du dépôt.
gsd_do() {
  local lab="$1" ws="$2" out="$3"; shift 3
  if [ "$ws" = - ]; then
    (cd "$TMP" && perl -e 'alarm 30; exec @ARGV' node "$GSDJS" "$@" --cwd "$lab") > "$out" 2> "$out.err" < /dev/null
  else
    (cd "$TMP" && perl -e 'alarm 30; exec @ARGV' node "$GSDJS" "$@" --cwd "$lab" --ws "$ws") > "$out" 2> "$out.err" < /dev/null
  fi
  GRC=$?
}
# gsd_norm <drop> <lab> <fichier brut> : sortie normalisée (chemin du lab remplacé par un jeton fixe ; drop=1 retire
# la seule ligne "section":, seul champ qui porte le texte brut de la section).
gsd_norm() {
  LAB="$2" awk -v drop="$1" 'BEGIN { l = ENVIRON["LAB"] }
    { if (drop == "1" && $0 ~ /^[ \t]*"section":/) next
      while ((i = index($0, l)) > 0) $0 = substr($0, 1, i - 1) "<LAB>" substr($0, i + length(l))
      print }' "$3"
}
# gsd_same <drop> <compartiment ou -> <attendu> <labA> <labB> <arguments du moteur...> -> 0 identique, 1 différent,
# 2 référence inutilisable (moteur en erreur, sortie vide ou sans le jeton <attendu> : un « identique » ne vaudrait rien).
gsd_same() {
  local drop="$1" ws="$2" want="$3" a="$4" b="$5"; shift 5
  gsd_do "$a" "$ws" "$TMP/gsd.a" "$@"
  if [ "$GRC" -ne 0 ] || [ ! -s "$TMP/gsd.a" ] || ! command grep -qF -- "$want" "$TMP/gsd.a"; then
    LASTMSG="référence inutilisable (rc $GRC, jeton [$want] attendu) err[$(tr '\n' '|' < "$TMP/gsd.a.err" | cut -c1-200)]"; return 2
  fi
  gsd_do "$b" "$ws" "$TMP/gsd.b" "$@"
  if [ "$GRC" -ne 0 ]; then LASTMSG="le moteur rend rc $GRC sur le second lab"; return 1; fi
  gsd_norm "$drop" "$a" "$TMP/gsd.a" > "$TMP/gsd.na"; gsd_norm "$drop" "$b" "$TMP/gsd.b" > "$TMP/gsd.nb"
  if cmp -s "$TMP/gsd.na" "$TMP/gsd.nb"; then return 0; fi
  LASTMSG="sorties différentes"; return 1
}
# Attendu « différent » : un 0 (identique) est un comparateur aveugle, un 2 une référence inutilisable.
gsd_must_differ() {
  gsd_same "$@"; local r=$?
  if [ "$r" -eq 0 ]; then LASTMSG="comparateur aveugle : un témoin négatif est déclaré identique (${*:3:3})"; return 1; fi
  if [ "$r" -eq 2 ]; then return 1; fi
  return 0
}
# Attendu « identique ».
gsd_must_match() {
  gsd_same "$@"; local r=$?
  if [ "$r" -eq 0 ]; then return 0; fi
  LASTMSG="${LASTMSG} (${*:3:3})"; return 1
}

if [ -f "$GSDJS" ] && command -v node > /dev/null 2>&1; then
  gsd_mklab A - '### Phase 2: Deuxieme' ''
  gsd_mklab B - '### Phase 2: Deuxieme' '**Validation:** proposed'
  gsd_mklab C - '### Phase 2: Deuxieme' "$GSD_VALID"
  gsd_mklab N1 - '### Phase 2 [proposed]: Deuxieme' ''
  gsd_mklab N2 - '### Phase 2: Deuxieme (proposed)' ''
  PH2='"phase_name": "Deuxieme"'; CNT='"phase_count": 3'

  # Témoins négatifs d'abord, avant toute comparaison positive : le comparateur doit savoir rougir (T-60-35).
  probe_gsd_neg() {
    gsd_must_match 1 - "$PH2" "$GSD/A" "$GSD/A" roadmap get-phase 2 || { LASTMSG="témoin positif A = A non identique (comparateur toujours différent) — $LASTMSG"; return 1; }
    gsd_must_differ 1 - "$PH2" "$GSD/A" "$GSD/N1" roadmap get-phase 2 || return 1
    gsd_must_differ 1 - "$PH2" "$GSD/A" "$GSD/N2" roadmap get-phase 2 || return 1
    gsd_must_differ 0 - "$CNT" "$GSD/A" "$GSD/N2" roadmap analyze
  }
  case_ CPV-GSD-NEG probe_gsd_neg

  probe_gsd_get() {
    gsd_must_match 1 - "$PH2" "$GSD/A" "$GSD/B" roadmap get-phase 2 || return 1
    gsd_must_match 1 - "$PH2" "$GSD/A" "$GSD/C" roadmap get-phase 2 || return 1
    # Le champ retiré de la comparaison porte bien le marqueur : le retrait n'efface pas une différence réelle.
    gsd_do "$GSD/B" - "$TMP/gsd.sec" roadmap get-phase 2
    LASTMSG="la section de B ne porte pas la ligne de marqueur"; command grep -qF 'Validation:** proposed' "$TMP/gsd.sec"
  }
  case_ CPV-GSD-GET probe_gsd_get

  probe_gsd_analyze() {
    gsd_must_match 0 - "$CNT" "$GSD/A" "$GSD/B" roadmap analyze || return 1
    gsd_must_match 0 - "$CNT" "$GSD/A" "$GSD/C" roadmap analyze
  }
  case_ CPV-GSD-ANALYZE probe_gsd_analyze

  # Lab partitionné : mêmes comparaisons avec --ws w1 (compartiment de fixture, aucun nom réel).
  gsd_mklab Aw w1 '### Phase 2: Deuxieme' ''
  gsd_mklab Bw w1 '### Phase 2: Deuxieme' '**Validation:** proposed'
  gsd_mklab Cw w1 '### Phase 2: Deuxieme' "$GSD_VALID"
  gsd_mklab N1w w1 '### Phase 2 [proposed]: Deuxieme' ''
  probe_gsd_ws() {
    gsd_must_differ 1 w1 "$PH2" "$GSD/Aw" "$GSD/N1w" roadmap get-phase 2 || return 1
    gsd_must_match 1 w1 "$PH2" "$GSD/Aw" "$GSD/Bw" roadmap get-phase 2 || return 1
    gsd_must_match 1 w1 "$PH2" "$GSD/Aw" "$GSD/Cw" roadmap get-phase 2 || return 1
    gsd_must_match 0 w1 "$CNT" "$GSD/Aw" "$GSD/Bw" roadmap analyze || return 1
    gsd_must_match 0 w1 "$CNT" "$GSD/Aw" "$GSD/Cw" roadmap analyze
  }
  case_ CPV-GSD-WS probe_gsd_ws

  # Écritures du moteur (P60-D-03 a, P60-D-02) : le moteur réécrit le ROADMAP ; la case se coche, le marqueur survit.
  # gsd_no_marker <ROADMAP> : le ROADMAP privé de la seule ligne de marqueur, sur la sortie standard.
  gsd_no_marker() { awk '!/^\*\*Validation:\*\*/' "$1"; }
  # gsd_phase2_dir <lab> : dossier de la phase 2 prête à clore (un PLAN, un SUMMARY, une VERIFICATION passed).
  gsd_phase2_dir() {
    local p="$1/.planning/phases/02-deuxieme"; mkdir -p "$p"
    printf -- '---\nphase: 02\nplan: 01\n---\n# plan\n' > "$p/02-01-PLAN.md"
    printf -- '---\nphase: 02\nplan: 01\nstatus: complete\n---\n# summary\n' > "$p/02-01-SUMMARY.md"
    printf -- '---\nphase: 02\nstatus: passed\n---\n# verification\n' > "$p/02-VERIFICATION.md"
  }
  # gsd_gate <lab> <phase> -> RC : le gate rejoué sur le ROADMAP du lab que le moteur vient de réécrire.
  gsd_gate() { RUNDIR="$1"; run --phase "$2"; }

  gsd_mklab CA - '### Phase 2: Deuxieme' ''
  gsd_mklab CB - '### Phase 2: Deuxieme' '**Validation:** proposed'
  gsd_phase2_dir "$GSD/CA"; gsd_phase2_dir "$GSD/CB"
  probe_gsd_complete() {
    local l
    for l in CA CB; do
      gsd_do "$GSD/$l" - "$TMP/gsd.cmp.$l" phase complete 2
      LASTMSG="phase complete 2 sur $l rend rc $GRC err[$(tr '\n' '|' < "$TMP/gsd.cmp.$l.err" | cut -c1-200)]"; [ "$GRC" -eq 0 ] || return 1
      LASTMSG="la case de checklist n'est pas cochée dans $l"
      command grep -q '^- \[x\] Phase 2:' "$GSD/$l/.planning/ROADMAP.md" || return 1
    done
    gsd_no_marker "$GSD/CA/.planning/ROADMAP.md" > "$TMP/gsd.cmp.na"; gsd_no_marker "$GSD/CB/.planning/ROADMAP.md" > "$TMP/gsd.cmp.nb"
    LASTMSG="les deux ROADMAP réécrits diffèrent hors ligne de marqueur"; cmp -s "$TMP/gsd.cmp.na" "$TMP/gsd.cmp.nb" || return 1
    LASTMSG="la ligne de marqueur n'a pas survécu à phase complete dans CB"
    command grep -qxF '**Validation:** proposed' "$GSD/CB/.planning/ROADMAP.md" || return 1
    gsd_gate "$GSD/CB" 2
    msg "le gate sur le ROADMAP réécrit de CB attendu rc 1 (marqueur conservé)"; [ "$RC" -eq 1 ] || return 1
    gsd_gate "$GSD/CA" 2
    msg "le gate sur le ROADMAP réécrit de CA attendu rc 0 (aucun marqueur)"; [ "$RC" -eq 0 ]
  }
  case_ CPV-GSD-COMPLETE probe_gsd_complete

  gsd_mklab RA - '### Phase 2: Deuxieme' ''
  gsd_mklab RB - '### Phase 2: Deuxieme' '**Validation:** proposed'
  probe_gsd_renum() {
    local l
    for l in RA RB; do
      gsd_do "$GSD/$l" - "$TMP/gsd.ren.i.$l" phase insert 1 Intercalee
      LASTMSG="phase insert 1 sur $l rend rc $GRC err[$(tr '\n' '|' < "$TMP/gsd.ren.i.$l.err" | cut -c1-200)]"; [ "$GRC" -eq 0 ] || return 1
      gsd_do "$GSD/$l" - "$TMP/gsd.ren.r.$l" phase remove 1
      LASTMSG="phase remove 1 sur $l rend rc $GRC err[$(tr '\n' '|' < "$TMP/gsd.ren.r.$l.err" | cut -c1-200)]"; [ "$GRC" -eq 0 ] || return 1
    done
    # La phase 2 est devenue la phase 1 : le marqueur a suivi sa section, l'autre lab n'en a jamais eu.
    gsd_gate "$GSD/RB" 1
    msg "le gate sur la phase renumérotée de RB attendu rc 1 (le marqueur suit sa section)"; [ "$RC" -eq 1 ] || return 1
    gsd_gate "$GSD/RA" 1
    msg "le gate sur la phase renumérotée de RA attendu rc 0"; [ "$RC" -eq 0 ] || return 1
    gsd_must_match 1 - "$PH2" "$GSD/RA" "$GSD/RB" roadmap get-phase 1
  }
  case_ CPV-GSD-RENUM probe_gsd_renum

  # Grammaire de --phase : le gate trouve les phases que le moteur sert (P60-D-02, au poste solo rien ne change).
  # A : id custom posé par `phase add --id`. B : gabarit de jalons livrés (<details>) avec numérotation remise à 1.
  gsd_mklab AID - '### Phase 2: Deuxieme' ''
  gsd_mklab BDT - '### Phase 2: Deuxieme' ''
  {
    printf '# Roadmap\n\n<details>\n<summary>v1.0 shipped</summary>\n\n'
    printf '### Phase 1: Vieille\n**Goal:** a\n**Validation:** proposed\n\n### Phase 2: Vieille2\n**Goal:** b\n**Validation:** proposed\n\n</details>\n\n'
    printf '## Milestone v2.0\n\n### Phase 1: Neuve\n**Goal:** a\n\n### Phase 2: Neuve2\n**Goal:** b\n'
  } > "$GSD/BDT/.planning/ROADMAP.md"
  probe_gsd_ids() {
    gsd_do "$GSD/AID" - "$TMP/gsd.add" phase add "Auth flow" --id AUTH
    LASTMSG="phase add --id AUTH rend rc $GRC"; [ "$GRC" -eq 0 ] || return 1
    gsd_do "$GSD/AID" - "$TMP/gsd.gp" roadmap get-phase AUTH
    LASTMSG="le moteur ne trouve pas AUTH (référence inutilisable)"; command grep -q '"found": true' "$TMP/gsd.gp" || return 1
    gsd_gate "$GSD/AID" AUTH
    msg "le moteur trouve AUTH : le gate attendu rc 0 + marqueur absent, jamais 3 ni 64"; { [ "$RC" -eq 0 ] && has 'marqueur absent'; } || return 1
    gsd_do "$GSD/AID" - "$TMP/gsd.gn" roadmap get-phase NOPE
    LASTMSG="témoin : le moteur trouve NOPE"; command grep -q '"found": false' "$TMP/gsd.gn" || return 1
    gsd_gate "$GSD/AID" NOPE
    msg "témoin : le moteur ne trouve pas NOPE, le gate attendu rc 3"; [ "$RC" -eq 3 ] || return 1
    gsd_do "$GSD/BDT" - "$TMP/gsd.bg" roadmap get-phase 2
    LASTMSG="le moteur ne rend pas la phase active Neuve2 (référence inutilisable)"; command grep -q '"phase_name": "Neuve2"' "$TMP/gsd.bg" || return 1
    gsd_gate "$GSD/BDT" 2
    msg "gabarit de jalons livrés : le moteur sert la phase 2 active, le gate attendu rc 0, jamais 3 sections multiples"; [ "$RC" -eq 0 ] || return 1
    gsd_gate "$GSD/BDT" 1
    msg "gabarit de jalons livrés : phase 1 active sans marqueur, le gate attendu rc 0 (le marqueur du bloc livré est ignoré)"; [ "$RC" -eq 0 ]
  }
  case_ CPV-GSD-IDS probe_gsd_ids
else
  skip "CPV-GSD moteur GSD absent (node ou gsd-tools.cjs introuvable : la CI installe le moteur et tranche)"
fi

# === Mutants (QUAL-01) ===============================================================================
MUTDIR="$TMP/mut"; mkdir -p "$MUTDIR"
MUTBIN="$MUTDIR/check-phase-validation.sh"
# Les règles de compartiment se retrouvent à côté de la copie (à plat), comme chez l'utilisateur.
for _p in "$HERE/../workstream-policy.sh" "$HERE/../../../planning-core/scripts/workstream-policy.sh"; do
  if [ -f "$_p" ]; then cp "$_p" "$MUTDIR/workstream-policy.sh"; break; fi
done

# mutant <id> <ligne repère> <ancien> <nouveau> <sonde> <description> : dans UNE ligne du script (celle qui
# contient le repère), remplace la première occurrence littérale de <ancien> par <nouveau> (chaînes passées par
# l'environnement : aucune séquence d'échappement interprétée). La sonde doit échouer sur le mutant, réussir
# sur l'original ; code attendu/obtenu imprimé par msg.
mutant() {
  local id="$1" needle="$2" old="$3" new="$4" probe="$5" desc="$6"
  if ! declare -F "$probe" > /dev/null; then ko "$id sonde $probe NON DÉFINIE à cet endroit — $desc"; return; fi
  NEEDLE="$needle" OLD="$old" NEW="$new" awk 'BEGIN { n = ENVIRON["NEEDLE"]; o = ENVIRON["OLD"]; w = ENVIRON["NEW"] }
    { if (index($0, n)) { i = index($0, o); if (i) $0 = substr($0, 1, i - 1) w substr($0, i + length(o)) } print }' \
    "$SCRIPT" > "$MUTBIN"
  if cmp -s "$MUTBIN" "$SCRIPT"; then ko "$id mutant NON OPPOSABLE (copie identique à l'original) — $desc"; return; fi
  if ! bash -n "$MUTBIN" 2>/dev/null; then ko "$id mutant invalide (bash -n) — $desc"; return; fi
  local nl; nl="$(diff "$SCRIPT" "$MUTBIN" | command grep -c '^<')"
  if [ "$nl" != 1 ]; then ko "$id mutant mal ciblé ($nl lignes changées au lieu de 1) — $desc"; return; fi
  TARGET="$MUTBIN"; "$probe" < /dev/null; local mrc=$?; local mmsg="$LASTMSG"
  TARGET="$SCRIPT"; "$probe" < /dev/null; local orc=$?
  if [ "$mrc" -ne 0 ] && [ "$orc" -eq 0 ]; then
    ok "$id tue ($desc) — sur le mutant : $mmsg"
  elif [ "$mrc" -eq 0 ]; then
    ko "$id mutant SURVIVANT ($desc) — la sonde ${probe#probe_} reste verte sur le mutant"
  else
    ko "$id original rouge après mutation ($desc) — $LASTMSG"
  fi
  TARGET="$SCRIPT"
}

mutant CPV-MUT-1 'proposed) MARK=proposed' 'bump 1' ':' probe_trace2 \
  "FAIL : branche proposed -> 1 neutralisée"
mutant CPV-MUT-2 'if [ "$NSEC" -eq 0 ]; then indetermine' 'indetermine "phase introuvable"' 'MARK=absent' probe_trace3 \
  "INDÉTERMINÉ : phase introuvable rendue 0"
mutant CPV-MUT-3 '*) MARK=inconnu;' 'indetermine "valeur de marqueur inconnue"' ':' probe_inconnu \
  "INDÉTERMINÉ : valeur de marqueur inconnue rendue 0"
mutant CPV-MUT-4 'if [ -L "$f" ]; then illisible' '[ -L "$f" ]' 'false' probe_lien \
  "BRUYANT : refus du lien symbolique retiré"
mutant CPV-MUT-5 '"$size" -gt "$CPV_MAX_OCTETS"' '"$CPV_MAX_OCTETS"' '99999999999' probe_gros \
  "BRUYANT : borne de taille retirée"
mutant CPV-MUT-6 'if (c) { infence = 1; flen = c; return }' 'if (c)' 'if (0)' probe_fence \
  "PASS : bascule des blocs de code retirée"
mutant CPV-MUT-7 'if (match(r, /^[ \t]*\([^)]*\)/))' 'r = substr(r, RLENGTH + 1)' 'r = r' probe_tag \
  "FAIL : tag de titre entre parenthèses non toléré"
mutant CPV-MUT-8 'if (r !~ /^[ \t]*:/) return ""' 'r !~ /^[ \t]*:/' '0' probe_double \
  "FAIL : deux-points non exigé, un titre sans deux-points compte comme section"
mutant CPV-MUT-9 'then indetermine "lab partitionne sans --ws"' '[ -e "$PLAN/workstreams" ] || [ -L "$PLAN/workstreams" ]' 'false' probe_ws_sans \
  "INDÉTERMINÉ : contrôle « partitionné sans --ws » retiré"
mutant CPV-MUT-10 'elif [ "$NMARK" -gt 1 ]' '[ "$NMARK" -gt 1 ]' 'false' probe_multi \
  "INDÉTERMINÉ : marqueurs multiples rendus selon le premier"
mutant CPV-MUT-11 'if (insec[p] && lvl <= seclvl[p]) insec[p] = 0' 'insec[p] && lvl <= seclvl[p]' '0' probe_ferme \
  "FAIL : fermeture de la section de phase retirée, le marqueur d'une section voisine est attribué à la phase interrogée"
mutant CPV-MUT-12 'if (insec[p] && lvl <= seclvl[p]) insec[p] = 0' 'lvl <= seclvl[p]' 'lvl < seclvl[p]' probe_ferme \
  "FAIL : la section ne se ferme plus à un titre de MÊME niveau (borne <= devenue <)"
mutant CPV-MUT-13 'if (lvl < 2 || lvl > 4) return ""' 'lvl > 4' 'lvl > 5' probe_niveaux \
  "FAIL : un titre de niveau 5 compte comme section de phase"
mutant CPV-MUT-14 'if (lvl < 2 || lvl > 4) return ""' 'lvl < 2' 'lvl < 1' probe_niveaux \
  "FAIL : un titre de niveau 1 compte comme section de phase"
mutant CPV-MUT-15 'c = substr(s, i + 1, 1)' 'i + 1' '1' probe_fence_indentee \
  "FAIL : indentation tolérée devant une barrière de bloc de code retirée"

mutant CPV-MUT-16 'if (c == "`" && index(substr(s, i + n + 1), "`")) return 0' 'c == "`" &&' '0 &&' probe_fence_commonmark \
  "FAIL : un accent grave dans l'info string d'une barrière d'accents graves n'empêche plus l'ouverture"
mutant CPV-MUT-17 'if (n < flen) return 0' 'n < flen' '0' probe_fence_commonmark \
  "FAIL : une barrière de fermeture plus courte que l'ouvreur la ferme"
mutant CPV-MUT-18 'return (substr(s, i + n + 1) ~' '~ /^[ \t]*$/' '~ /^/' probe_fence_commonmark \
  "FAIL : une ligne de fermeture avec info string ferme la barrière"
mutant CPV-MUT-19 'if (i > 3) return 0' 'i > 3' 'i > 99' probe_fence_indentee \
  "FAIL : l'indentation de l'ouvreur n'est plus bornée à 3 espaces"
mutant CPV-MUT-20 'fch = c' 'fch = c' 'fch = "`"' probe_fence \
  "FAIL : une barrière tilde n'est plus fermée par des tildes"
mutant CPV-MUT-21 'u = toupper(s)' 'toupper(s)' 's' probe_ids \
  "FAIL : la casse des identifiants de phase devient significative"
mutant CPV-MUT-22 'sub(/^0+/, "", d); if (d == "") d = "0"' 'sub(/^0+/, "", d); ' '' probe_decimal \
  "FAIL : zéros de tête des segments numériques conservés"
mutant CPV-MUT-23 'if (!match(h, /^Phase[ \t]+[A-Za-z0-9]' '[A-Za-z0-9][A-Za-z0-9_-]*' '[0-9]' probe_ids \
  "FAIL : un titre à id custom (AUTH) n'est plus une section"
mutant CPV-MUT-24 'if (!match(h, /^Phase[ \t]+[A-Za-z0-9]' '(\.[A-Za-z0-9_-]+)*' '(\.[0-9]+)*' probe_ids \
  "FAIL : un segment décimal à suffixe lettre (7.1A) n'est plus une section"
mutant CPV-MUT-25 'p = (nsec[1] > 0) ? 1 : 2' '(nsec[1] > 0) ? 1 : 2' '2' probe_prefixe \
  "FAIL : la lecture tolérante au préfixe projet prime sur la lecture exacte (sections multiples)"
mutant CPV-MUT-26 'p = (nsec[1] > 0) ? 1 : 2' '(nsec[1] > 0) ? 1 : 2' '1' probe_prefixe \
  "FAIL : plus de lecture tolérante : le numéro nu 3 ne désigne plus CK-03"
mutant CPV-MUT-27 'if (match(u, /^[A-Z][A-Z0-9_]*-[0-9]/)) return' '(loose ? "" : substr(u, 1, RLENGTH - 1))' '(loose ? substr(u, 1, RLENGTH - 1) : substr(u, 1, RLENGTH - 1))' probe_prefixe \
  "FAIL : la lecture tolérante conserve le préfixe projet"
mutant CPV-MUT-28 '[ "${#PHASE}" -le 64 ]' '-le 64' '-le 9999' probe_id_usage \
  "FAIL : borne de longueur de l'identifiant retirée"
mutant CPV-MUT-29 'a = index(tw, "<details>")' '"<details>"' '"<detailz>"' probe_details \
  "FAIL : les blocs <details> des jalons livrés ne sont plus cachés"
mutant CPV-MUT-30 'w = rl; tw = tolower(rl)' 'tolower(rl)' 'rl' probe_details \
  "FAIL : la casse des balises <details> devient significative"
mutant CPV-MUT-31 'if (b && (!c || b < c)) {' '(!c || b < c)' '1' probe_details \
  "FAIL : un <details> suivi d'un autre <details> avant sa fermeture ouvre un bloc (la phase visible est cachée)"
mutant CPV-MUT-32 'for (k = 1; k <= pq_n; k++) proc(pq_not[k], pq_i[k])' 'proc(pq_not[k]' 'proc(""' probe_details \
  "FAIL : un <details> jamais fermé cache le reste du fichier"
mutant CPV-MUT-33 'a = index(tw, "<details>")' '"<details>"' '"<details"' probe_details \
  "FAIL : <details open> (jalon actif) est caché comme un jalon livré"
mutant CPV-MUT-34 'pq_blk[1] = vis substr(w, 1, a - 1)' 'substr(w, 1, a - 1)' '""' probe_details \
  "FAIL : le texte qui précède un <details> sur sa ligne est perdu"
mutant CPV-MUT-35 'if (match(line, /^[ \t]*\*\*Validation(:\*\*|\*\*[ \t]*:)/))' '\*\*[ \t]*:)' '\*\*:)' probe_marqueur_formes \
  "MK : la forme « **Validation** : proposed » n'est plus un marqueur (devient « absent »)"
mutant CPV-MUT-36 'OUT_TXT=$(sed' "| tr '\\r' '\\n' " '' probe_cr_isole \
  "MI : le CR isolé n'est plus une fin de ligne (le marqueur est lu en queue de la ligne précédente)"

mutant CPV-MUT-37 'return (index(s, "🚧") > 0' '(index(s, "🚧") > 0 || index(s, "🔄") > 0)' '0' probe_details_actif \
  "FAIL : un <summary> à 🚧 ou 🔄 n'est plus un jalon actif (gsd le sert, le gate le cache : fail-open)"
mutant CPV-MUT-38 'if (s ~ /in[ \t\n]+progress/) return 1' 'return 1' 'return 0' probe_details_actif \
  "FAIL : « in progress » n'est plus un marqueur d'activité"
mutant CPV-MUT-39 'if (match(s, /(^|[^a-z0-9_])(started|active|wip)' '(started|active|wip)' '(started|active)' probe_details_actif \
  "FAIL : WIP n'est plus un marqueur d'activité"
mutant CPV-MUT-40 'if (!inq && active_block(rl, w, b)) {' 'active_block(rl, w, b)' '1' probe_details_actif \
  "FAIL : tout bloc <details> devient visible, les jalons livrés ou neutres aussi (le gate refuse à tort)"
mutant CPV-MUT-41 'if (!inq && active_block(rl, w, b)) {' 'active_block(rl, w, b)' '0' probe_details_actif \
  "FAIL : le jalon actif en <details> est caché comme un jalon livré (rc 3, la boucle continue : le défaut du tour 2)"
mutant CPV-MUT-42 '        flush_pending()' 'flush_pending()' 'pend = 0' probe_details_actif \
  "FAIL : les lignes d'un bloc actif sont rendues vides (cachées malgré la décision de les lire)"
mutant CPV-MUT-43 '        vis = substr(rl, 1, length(rl) - length(w) + b - 1)' 'substr(rl, 1, length(rl) - length(w) + b - 1)' '""' probe_details_actif \
  "FAIL : le texte qui précède </details> sur la ligne de fermeture d'un bloc actif est perdu"
mutant CPV-MUT-45 '*) MARK=inconnu; indetermine' 'MARK=inconnu; ' '' probe_bilan_illisible \
  "FAIL : la ligne BILAN ne dit plus marqueur=inconnu (les consommateurs ne distinguent plus l'illisible du non constatable)"
mutant CPV-MUT-46 'elif [ "$NMARK" -gt 1 ]; then MARK=multiple;' 'MARK=multiple; ' '' probe_bilan_illisible \
  "FAIL : la ligne BILAN ne dit plus marqueur=multiple"

echo "== resultat : $PASS ok, $FAIL ko ($SKIPPED skip) =="
[ "$FAIL" -eq 0 ]
