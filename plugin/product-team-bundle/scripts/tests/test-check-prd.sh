#!/usr/bin/env bash
# Test de check-prd.sh (Phase 59, PRDT-03, PRDT-05, PRDT-09 ; QUAL-01) — autonome.
# Fixtures ÉCRITES À L'EXÉCUTION sous un dossier temporaire (P59-PL-07) : aucun dossier fixtures/ versionné,
# octets CRLF et BOM produits par printf. Le script se retrouve par ../check-prd.sh, en source comme une fois
# copié à plat par l'engine (la suite se pose sous scripts/tests/).
# Cas CPRD-TRACE-1..4 (exigence sans critère jusqu'au code 1, aucune exigence, usage).
# Cas CPRD-GABARIT, CPRD-COURT, CPRD-TBD, CPRD-TBD-MOT, CPRD-POINTS, CPRD-ANCRE, CPRD-FENCE, CPRD-CRLF, CPRD-BOM,
# CPRD-PRIO, CPRD-BRIEF-OK, CPRD-BRIEF-MANQUE, CPRD-BRIEF-VIDE, CPRD-BRIEF-FENCE, CPRD-BRIEF-NUM, CPRD-BRIEF-SEUL,
# CPRD-MIX, CPRD-NOECHO.
# Cas CPRD-ABSENT, CPRD-LIEN, CPRD-FIFO, CPRD-DOSSIER, CPRD-GROS, CPRD-ILLISIBLE, CPRD-MIX5, CPRD-EXEC (sans
# évaluation de chaîne, chemin hostile inerte), CPRD-RO, CPRD-CODES (ensemble observé = {0, 1, 3, 5, 64}, jamais 2).
# Cas revue-59 (F2, F3, F4) : CPRD-TODO, CPRD-REMPLISSAGE, CPRD-REMPLISSAGE-MOT, CPRD-LONGUEUR, CPRD-COMMENTAIRE,
# CPRD-FERME-BLANC, CPRD-SOUS-PUCE, CPRD-FENCE-OUVERTE, CPRD-CASE-INCONNUE, CPRD-BRIEF-REMPLISSAGE, CPRD-BRIEF-CRLF.
# Cas revue-59 (2e relecture) : CPRD-COM-OUVERT, CPRD-BRIEF-OUVERT, CPRD-BRIEF-MENTIONS, CPRD-BRIEF-LEGITIME, CPRD-CHAMP,
# CPRD-MARQUES, CPRD-CR, CPRD-COM-BLANC, CPRD-MOT-LEGITIME, CPRD-COCHEE, CPRD-HORS-SUJET, CPRD-5-SUR-1, CPRD-SOUS-PUCE-SUIVIE.
# Classes génératives tour 3 (4e relecture) : CPRD-GEN-ENVELOPPES-*, CPRD-GEN-CHAMP-VIDE/SUIVI, CPRD-GEN-PONCTUATION-*, CPRD-GEN-TITRES-* ;
# CPRD-IMBRICATION, CPRD-CODE-COMMENTAIRE, CPRD-CODE-MARQUEUR, CPRD-ILLISIBLE-000 (skip audible en root) ; mutants CPRD-MUT-117..159.
# Mutants CPRD-MUT-1..8 (QUAL-01), CPRD-MUT-9..26 (revue-59 F4 : un mutant par comportement documenté), CPRD-MUT-27..51 (2e relecture, hors 40 : un mutant par correctif) : une ligne du script altérée, chacun différent de l'original (cmp -s), valide
# (bash -n), rouge pour la raison attendue (code attendu/obtenu imprimé), original revérifié vert.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$HERE/.." && pwd)/check-prd.sh"
TARGET="$SCRIPT"

PASS=0; FAIL=0; SKIPPED=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }
skip() { echo "  ⊘ SKIP $1"; SKIPPED=$((SKIPPED+1)); }

TMP="$(mktemp -d)"
trap 'chmod -R u+rwx "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT
FX="$TMP/fx"; mkdir -p "$FX"
: > "$TMP/rcs"; : > "$TMP/fxlist"; : > "$TMP/fxsum"
mkdir "$TMP/cwd"; cd "$TMP/cwd" || exit 1   # cwd jetable : une évaluation de nom de fichier y laisserait une trace
MARK="zzSECRETzz"
LASTMSG=""; RC=0; OUT=""; ERR=""

# w <relatif> <format printf> [args] : écrit une fixture sous $FX et l'inscrit à l'empreinte de lecture seule.
reg() {
  echo "$FX/$1" >> "$TMP/fxlist"
  if [ -f "$FX/$1" ] && [ ! -L "$FX/$1" ]; then echo "$(cksum < "$FX/$1") $FX/$1" >> "$TMP/fxsum"; fi
}
w() { local rel="$1" fmt="$2"; shift 2; mkdir -p "$(dirname "$FX/$rel")"; printf -- "$fmt" "$@" > "$FX/$rel"
  case "$rel" in */*) reg "$(dirname "$rel")" ;; esac
  reg "$rel"
}

# run <arguments séparés> -> RC, OUT, ERR ; appel borné (une attente devient un échec du cas, rc 142).
run() {
  OUT="$(perl -e 'alarm 10; exec @ARGV' bash "$TARGET" "$@" 2>"$TMP/err")"; RC=$?
  ERR="$(cat "$TMP/err")"
  echo "$RC" >> "$TMP/rcs"
}
has() { command grep -qF -- "$1" <<<"$OUT"; }   # chaîne ici : jamais de tube (SIGPIPE + pipefail rendait un faux « absent » sur une sortie longue)
last() { printf '%s\n' "$OUT" | tail -1; }
# case_ <id> <sonde> : une sonde rend 0 quand le comportement attendu est observé.
case_() { if "$2"; then ok "$1"; else ko "$1 — $LASTMSG"; fi; }
msg() { LASTMSG="$1, obtenu rc $RC out[$(printf '%s' "$OUT" | tr '\n' '|' | cut -c1-200)] err[$(printf '%s' "$ERR" | tr '\n' '|' | cut -c1-200)]"; }

A1="- [ ] **PRD-01**: Afficher le tarif. Acceptation : le tarif s'affiche en moins de 2 secondes. Priorité : must"
A2="- [ ] **PRD-02**: Exporter la liste. Acceptation : un fichier CSV est téléchargé en moins de 5 secondes. Priorité : should"
B1="- [ ] **PRD-01**: Afficher le tarif\n  Acceptation : le tarif s'affiche en moins de 2 secondes\n  Priorité : must"
B2="- [ ] **PRD-02**: Exporter la liste\n  Acceptation : un fichier CSV est téléchargé en moins de 5 secondes\n  Priorité : could"
NOCRIT="- [ ] **PRD-02**: Exporter la liste\n  Priorité : should"

echo "== test-check-prd =="

# === Tracer : de l'exigence sans critère au code 1 ================================================
probe_trace1() {
  w okA.md '# Exigences\n\n%s\n%s\n' "$A1" "$A2"
  w okB.md "# Exigences\n\n$B1\n$B2\n"
  run --requirements "$FX/okA.md"
  msg "forme A attendu rc 0 + BILAN exigences=2 sans_critere=0"
  { [ "$RC" -eq 0 ] && last | command grep -q 'BILAN exigences=2 sans_critere=0 '; } || return 1
  run --requirements "$FX/okB.md"
  msg "forme B attendu rc 0 + BILAN exigences=2 sans_critere=0"
  [ "$RC" -eq 0 ] && last | command grep -q 'BILAN exigences=2 sans_critere=0 '
}
probe_trace2() {
  w trois.md "# Exigences\n\n%s\n$NOCRIT\n%s\n" "$A1" "$A2"
  run --requirements "$FX/trois.md"
  msg "attendu rc 1 + ELIMINATOIRE exigence PRD-02 seule"
  [ "$RC" -eq 1 ] && has 'ELIMINATOIRE exigence PRD-02' \
    && ! printf '%s\n' "$OUT" | command grep 'ELIMINATOIRE' | command grep -q 'PRD-01'
}
probe_trace3() {
  w prose.md '# Exigences\n\nUn titre et de la prose, sans aucune exigence.\n\n## Suite\n\nEncore du texte.\n'
  run --requirements "$FX/prose.md"
  msg "attendu rc 3 + INDETERMINE"
  [ "$RC" -eq 3 ] && has 'INDETERMINE exigences'
}
probe_trace4() {
  run; msg "sans argument attendu rc 64 + usage sur stderr"
  { [ "$RC" -eq 64 ] && [ -n "$ERR" ]; } || return 1
  run --requirements; msg "--requirements sans valeur attendu rc 64"
  [ "$RC" -eq 64 ] || return 1
  run --inconnu; msg "argument inconnu attendu rc 64"
  [ "$RC" -eq 64 ]
}
case_ CPRD-TRACE-1 probe_trace1
case_ CPRD-TRACE-2 probe_trace2
case_ CPRD-TRACE-3 probe_trace3
case_ CPRD-TRACE-4 probe_trace4

# === Gabarits non remplis, blocs de code, CRLF et BOM, priorités ==================================
CRIT="un fichier CSV est téléchargé en moins de 5 secondes"
req1() { # <nom> <ligne d'acceptation> : une exigence PRD-01 dont l'acceptation est donnée
  w "$1" "# Exigences\n\n- [ ] **PRD-01**: Exporter la liste\n  %s\n  Priorité : must\n" "$2"
}
probe_gabarit() { req1 gabarit.md "Acceptation : [critère mesurable : quoi, combien, en combien de temps]"; run --requirements "$FX/gabarit.md"
  msg "critère entre crochets attendu rc 1 + exigence nommée"; { [ "$RC" -eq 1 ] && has 'ELIMINATOIRE exigence PRD-01'; } || return 1
  req1 gabarit2.md "Acceptation : [décrire ici le critère attendu pour cette exigence]"; run --requirements "$FX/gabarit2.md"
  msg "consigne libre entre crochets (hors texte des gabarits livrés) attendu rc 1 : seul le filtre du crochet de tête la retient"; [ "$RC" -eq 1 ]; }
probe_court() { req1 court.md "Acceptation : ok vite"; run --requirements "$FX/court.md"
  msg "critère de moins de 10 caractères non blancs attendu rc 1"; [ "$RC" -eq 1 ]; }
probe_tbd() { req1 tbd.md "Acceptation : tbd avec le client avant la livraison"; run --requirements "$FX/tbd.md"
  msg "critère portant TBD attendu rc 1"; [ "$RC" -eq 1 ]; }
probe_ancre() {
  w ancre.md "# Exigences\n\n- [ ] **PRD-01**: Exporter\n  Critère d'acceptation : $CRIT\n  Priorité : must\n- [ ] **PRD-02**: Lister\n  Critère d’acceptation : $CRIT\n  Priorité : must\n"
  run --requirements "$FX/ancre.md"
  msg "ancres « Critère d'acceptation » (droite et typographique) attendu rc 0"; [ "$RC" -eq 0 ]; }
probe_fence() {
  w fence.md "# Exigences\n\nForme attendue :\n\n\`\`\`markdown\n- [ ] **PRD-99**: exemple sans critère\n\`\`\`\n\n%s\n" "$A1"
  run --requirements "$FX/fence.md"
  msg "exemple en bloc de code ignoré attendu rc 0"; { [ "$RC" -eq 0 ] && last | command grep -q 'BILAN exigences=1 '; } || return 1
  w fence-seul.md "# Exigences\n\nForme attendue :\n\n\`\`\`markdown\n- [ ] **PRD-99**: exemple sans critère\n\`\`\`\n"
  run --requirements "$FX/fence-seul.md"
  msg "seul l'exemple en bloc attendu rc 3"; [ "$RC" -eq 3 ]; }
probe_crlf() { w crlf.md '# Exigences\r\n\r\n%s\r\n%s\r\n' "$A1" "$A2"; run --requirements "$FX/crlf.md"
  msg "fichier CRLF attendu rc 0"; [ "$RC" -eq 0 ]; }
probe_bom() { w bom.md '\357\273\277# Exigences\n\n%s\n' "$A1"; run --requirements "$FX/bom.md"
  msg "BOM UTF-8 attendu rc 0"; [ "$RC" -eq 0 ]; }
probe_prio() {
  w prio.md "# Exigences\n\n- [ ] **PRD-01**: a\n  Acceptation : $CRIT\n- [ ] **PRD-02**: b\n  Acceptation : $CRIT\n  Priorité : urgent\n- [ ] **PRD-03**: c\n  Acceptation : $CRIT\n  Priorité : MUST\n"
  run --requirements "$FX/prio.md"
  msg "priorité absente / hors ensemble attendu rc 0 + AVERTISSEMENT PRD-01 et PRD-02, pas PRD-03"
  [ "$RC" -eq 0 ] && has 'AVERTISSEMENT exigence PRD-01' && has 'AVERTISSEMENT exigence PRD-02' \
    && ! has 'AVERTISSEMENT exigence PRD-03'; }
case_ CPRD-GABARIT probe_gabarit
case_ CPRD-COURT probe_court
probe_points() { req1 points.md "Acceptation : le tarif s'affiche vite et bien ..."; run --requirements "$FX/points.md"
  msg "trois points attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  req1 ellipse.md "Acceptation : le tarif s'affiche vite et bien …"; run --requirements "$FX/ellipse.md"
  msg "points de suspension attendu rc 1"; [ "$RC" -eq 1 ]; }
probe_tbd_mot() { req1 tbd-mot.md "Acceptation : l'autodocumentation complète est livrée en 3 jours"; run --requirements "$FX/tbd-mot.md"
  msg "todo à l'intérieur d'un mot (autodocumentation) attendu rc 0 : seuls les mots entiers TBD/TODO comptent"; [ "$RC" -eq 0 ]; }
case_ CPRD-TBD probe_tbd
case_ CPRD-POINTS probe_points
case_ CPRD-TBD-MOT probe_tbd_mot
case_ CPRD-ANCRE probe_ancre
case_ CPRD-FENCE probe_fence
case_ CPRD-CRLF probe_crlf
case_ CPRD-BOM probe_bom
case_ CPRD-PRIO probe_prio

# === Rubriques du BRIEF ===========================================================================
BR_PB="## Problème\nLes freelances perdent du temps.\n\n"
BR_US="## Utilisateurs\nFreelances en France.\n\n"
BR_VA="## Valeur\nGagner une heure par semaine.\n\n"
BR_CO="## Contraintes\nBudget limité.\n\n"
BR_HP="## Hors périmètre\nPas de paiement.\n"
probe_brief_ok() { w brief-ok.md "# Brief produit\n\n$BR_PB$BR_US$BR_VA$BR_CO$BR_HP"; run --brief "$FX/brief-ok.md"
  msg "BRIEF à cinq rubriques attendu rc 0"; [ "$RC" -eq 0 ]; }
probe_brief_manque() { w brief-manque.md "# Brief produit\n\n$BR_PB$BR_US$BR_CO$BR_HP"; run --brief "$FX/brief-manque.md"
  msg "BRIEF sans Valeur attendu rc 1 + valeur : absente"
  [ "$RC" -eq 1 ] && has 'ELIMINATOIRE rubrique BRIEF valeur : absente'; }
probe_brief_sans_hp() { w brief-sans-hp.md "# Brief produit\n\n$BR_PB$BR_US$BR_VA$BR_CO"; run --brief "$FX/brief-sans-hp.md"
  msg "BRIEF sans Hors périmètre attendu rc 1"; [ "$RC" -eq 1 ] && has 'hors_perimetre : absente'; }
probe_brief_vide() {
  w brief-vide.md "# Brief produit\n\n$BR_PB$BR_US$BR_VA## Contraintes\n[…]\n<!-- à remplir -->\n<!--\nencore\n-->\n\n$BR_HP"
  run --brief "$FX/brief-vide.md"
  msg "rubrique dont le corps est un gabarit ou un commentaire attendu rc 1 + contraintes : vide"
  [ "$RC" -eq 1 ] && has 'ELIMINATOIRE rubrique BRIEF contraintes : vide'; }
probe_brief_fence() {
  w brief-fence.md "# Brief produit\n\n$BR_PB$BR_US$BR_CO$BR_HP\nExemple :\n\n\`\`\`\n## Valeur\nune valeur d'exemple\n\`\`\`\n"
  run --brief "$FX/brief-fence.md"
  msg "titre dans un bloc de code ignoré attendu rc 1 + valeur : absente"
  [ "$RC" -eq 1 ] && has 'valeur : absente'; }
probe_brief_num() {
  w brief-num.md "# Brief\n\n## 1. Problème\nUn.\n## 2. Utilisateurs\nDeux.\n## 3. Valeur\nTrois.\n## 4. Contraintes\nQuatre.\n## 5. Hors périmètre\nCinq.\n"
  run --brief "$FX/brief-num.md"
  msg "titres numérotés attendu rc 0"; [ "$RC" -eq 0 ]; }
probe_brief_seul() { run --brief "$FX/brief-ok.md"
  msg "--brief seul sur BRIEF complet attendu rc 0"; [ "$RC" -eq 0 ] && last | command grep -q 'rubriques_manquantes=0 '; }
case_ CPRD-BRIEF-OK probe_brief_ok
case_ CPRD-BRIEF-MANQUE probe_brief_manque
case_ CPRD-BRIEF-VIDE probe_brief_vide
case_ CPRD-BRIEF-FENCE probe_brief_fence
case_ CPRD-BRIEF-NUM probe_brief_num
case_ CPRD-BRIEF-SEUL probe_brief_seul

# === revue-59 F2/F3/F4 : marqueurs de remplissage, longueur en caractères, commentaires, fences, cases ===
probe_todo() { req1 todo.md "Acceptation : todo avec le client avant la livraison"; run --requirements "$FX/todo.md"
  msg "critère portant TODO attendu rc 1"; [ "$RC" -eq 1 ]; }
probe_remplissage() {
  local v i=0
  while IFS= read -r v; do
    i=$((i+1)); req1 "rempl-$i.md" "Acceptation : $v"; run --requirements "$FX/rempl-$i.md"
    msg "critère de remplissage « $v » attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  done <<'EOF'
à définir
à préciser plus tard
a definir
À DÉFINIR avec le client avant la livraison
À Préciser avec le client plus tard
n/a pour l'instant sur ce point
à compléter avec le client
à venir dans une version ultérieure
TBA avec le client avant la livraison
EOF
  local nfd=$'a de\xcc\x81finir avec le client'   # « é » décomposé (e + accent combinant) : mêmes verdicts
  req1 rempl-nfd.md "Acceptation : $nfd"; run --requirements "$FX/rempl-nfd.md"
  msg "« à définir » en forme décomposée attendu rc 1"; [ "$RC" -eq 1 ]; }
probe_remplissage_mot() {
  local v i=0
  while IFS= read -r v; do
    i=$((i+1)); req1 "mot-$i.md" "Acceptation : $v"; run --requirements "$FX/mot-$i.md"
    msg "« $v » (marqueur au sein d'un mot) attendu rc 0 : seuls les mots entiers comptent"; [ "$RC" -eq 0 ] || return 1
  done <<'EOF'
le tarif de mesa definir en moins de 3 secondes
ça definiras toujours le résultat en 3 secondes
l'avenir du produit se mesure en 3 mois de suivi
EOF
}
probe_longueur() {
  req1 l9.md "Acceptation : ééééééééé"; run --requirements "$FX/l9.md"
  msg "9 caractères accentués (18 octets) attendu rc 1 : la longueur se mesure en caractères"; [ "$RC" -eq 1 ] || return 1
  req1 l9b.md "Acceptation : é é é é é é é é é"; run --requirements "$FX/l9b.md"
  msg "9 caractères non blancs séparés par des blancs attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  req1 l10.md "Acceptation : éééééééééé"; run --requirements "$FX/l10.md"
  msg "10 caractères accentués attendu rc 0 (borne incluse)"; [ "$RC" -eq 0 ]; }
probe_commentaire() {
  req1 com1.md "  <!-- Acceptation : $CRIT -->"; run --requirements "$FX/com1.md"
  msg "critère placé dans un commentaire HTML indenté attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  w com2.md "# Exigences\n\n- [ ] **PRD-01**: Exporter\n  <!--\n  Acceptation : %s\n  -->\n  Priorité : must\n" "$CRIT"
  run --requirements "$FX/com2.md"
  msg "critère dans un commentaire multi-ligne attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  w com3.md "# Exigences\n\n- [ ] **PRD-01**: Exporter\n  <!--\n  une note\n  -->\n  Acceptation : %s\n  Priorité : must\n" "$CRIT"
  run --requirements "$FX/com3.md"
  msg "commentaire multi-ligne au milieu d'une exigence attendu rc 0 (il ne ferme pas l'exigence)"
  { [ "$RC" -eq 0 ] && last | command grep -q 'BILAN exigences=1 sans_critere=0 '; } || return 1
  w com4.md "# Exigences\n\n<!-- - [ ] **PRD-09**: exemple commenté -->\n%s\n" "$A1"
  run --requirements "$FX/com4.md"
  msg "exigence en commentaire HTML non comptée, BILAN exigences=1"
  [ "$RC" -eq 0 ] && last | command grep -q 'BILAN exigences=1 '; }
probe_ferme_blanc() {
  w blanc.md "# Exigences\n\n- [ ] **PRD-01**: Exporter\n  \n  Acceptation : %s\n  Priorité : must\n" "$CRIT"
  run --requirements "$FX/blanc.md"
  msg "ligne indentée après une ligne faite de blancs attendu rc 1 (elle ferme l'exigence)"
  [ "$RC" -eq 1 ] && has 'ELIMINATOIRE exigence PRD-01'; }
probe_sous_puce() {
  w puce.md "# Exigences\n\n- [ ] **PRD-01**: Exporter\n  - Acceptation : %s\n  Priorité : must\n" "$CRIT"
  run --requirements "$FX/puce.md"
  msg "critère porté par une sous-puce attendu rc 1 (une puce ouvre un nouvel élément)"
  [ "$RC" -eq 1 ] && has 'ELIMINATOIRE exigence PRD-01'; }
probe_sous_puce_suivie() {
  w puce2.md "# Exigences\n\n- [ ] **PRD-01**: Exporter\n  - une sous-note\n  Acceptation : %s\n  Priorité : must\n" "$CRIT"
  run --requirements "$FX/puce2.md"
  msg "continuation placée après une sous-puce attendu rc 1 (la puce ferme l'exigence)"
  [ "$RC" -eq 1 ] && has 'ELIMINATOIRE exigence PRD-01'; }
probe_fence_ouverte() {
  w fo1.md "# Exigences\n\n%s\n\n\`\`\`markdown\n$NOCRIT\n" "$A1"
  run --requirements "$FX/fo1.md"
  msg "bloc de code non fermé avalant une exigence sans critère attendu rc 3 + INDETERMINE, jamais rc 0"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE exigences : bloc de code non ferme'; } || return 1
  w fo2.md "# Exigences\n\n$NOCRIT\n\n~~~\n%s\n" "$A1"
  run --requirements "$FX/fo2.md"
  msg "éliminatoire lu avant un bloc non fermé attendu rc 1 (1 l'emporte sur 3)"
  [ "$RC" -eq 1 ] && has 'INDETERMINE exigences : bloc de code non ferme'; }
probe_case_inconnue() {
  w ci.md "# Exigences\n\n%s\n- [ ] **PRD.02**: $MARK ID pointé\n- [x] **prd-03**: minuscules\n* [ ] **PRD-04**: puce étoile\n" "$A1"
  run --requirements "$FX/ci.md"
  msg "3 cases non reconnues attendu rc 3 (INDETERMINE, jamais un vert) + AVERTISSEMENT lignes 4 à 6 (stdout ET stderr) + non_reconnues=3, contenu jamais réimprimé"
  [ "$RC" -eq 3 ] && has 'INDETERMINE exigences : case a cocher non reconnue' || return 1
  has 'AVERTISSEMENT ligne 4 :' && has 'AVERTISSEMENT ligne 5 :' && has 'AVERTISSEMENT ligne 6 :' || return 1
  last | command grep -q 'BILAN exigences=1 .*non_reconnues=3 code=3' || return 1
  printf '%s' "$ERR" | command grep -qF 'AVERTISSEMENT ligne 5 :' || return 1
  ! has "$MARK" && ! printf '%s' "$ERR" | command grep -qF "$MARK"; }
probe_brief_remplissage() {
  w brief-rempl.md "# Brief produit\n\n$BR_PB$BR_US## Valeur\ntbd\n\n## Contraintes\ntodo : voir le client\n\n$BR_HP"
  run --brief "$FX/brief-rempl.md"
  msg "rubriques ne portant que TBD ou TODO attendu rc 1 + valeur : vide + contraintes : vide"
  [ "$RC" -eq 1 ] && has 'rubrique BRIEF valeur : vide' && has 'rubrique BRIEF contraintes : vide'; }
probe_brief_crlf() {
  w brief-crlf.md '# Brief\r\n\r\n## Problème\r\nUn.\r\n## Utilisateurs\r\nDeux.\r\n## Valeur\r\nTrois.\r\n## Contraintes\r\n\r\n## Hors périmètre\r\nCinq.\r\n'
  run --brief "$FX/brief-crlf.md"
  msg "BRIEF CRLF dont la rubrique Contraintes est vide attendu rc 1 + contraintes : vide"
  [ "$RC" -eq 1 ] && has 'rubrique BRIEF contraintes : vide'; }
case_ CPRD-TODO probe_todo
case_ CPRD-REMPLISSAGE probe_remplissage
case_ CPRD-REMPLISSAGE-MOT probe_remplissage_mot
case_ CPRD-LONGUEUR probe_longueur
case_ CPRD-COMMENTAIRE probe_commentaire
case_ CPRD-FERME-BLANC probe_ferme_blanc
case_ CPRD-SOUS-PUCE probe_sous_puce
case_ CPRD-SOUS-PUCE-SUIVIE probe_sous_puce_suivie
case_ CPRD-FENCE-OUVERTE probe_fence_ouverte
case_ CPRD-CASE-INCONNUE probe_case_inconnue
case_ CPRD-BRIEF-REMPLISSAGE probe_brief_remplissage
case_ CPRD-BRIEF-CRLF probe_brief_crlf

# === revue-59 (2e relecture) : délimiteurs ouverts, mentions déguisées, champ, CR, mots légitimes ===
BR4="$BR_PB$BR_US$BR_VA$BR_CO"
probe_com_ouvert() {
  w co1.md "# Exigences\n\n$B1\n<!-- note\n$NOCRIT\n"; run --requirements "$FX/co1.md"
  msg "commentaire HTML jamais fermé avalant une exigence sans critère attendu rc 3 + INDETERMINE commentaire, jamais rc 0"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE exigences : commentaire HTML non ferme'; } || return 1
  w co2.md "# Exigences\n\n$B1\n<!-- ferme --> texte <!-- ouvert\n$NOCRIT\n"; run --requirements "$FX/co2.md"
  msg "second commentaire de la ligne jamais fermé attendu rc 3"; [ "$RC" -eq 3 ] || return 1
  w co3.md "# Exigences\n\n$NOCRIT\n\n  <!-- note\n$B1\n"; run --requirements "$FX/co3.md"
  msg "éliminatoire lu avant un commentaire non fermé attendu rc 1 (1 l'emporte sur 3)"
  [ "$RC" -eq 1 ] && has 'INDETERMINE exigences : commentaire HTML non ferme'; }
probe_brief_ouvert() {
  w bo1.md "# Brief produit\n\n$BR4$BR_HP<!-- note\n"; run --brief "$FX/bo1.md"
  msg "BRIEF dont le dernier commentaire n'est jamais fermé attendu rc 3 + INDETERMINE brief"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE brief : commentaire HTML non ferme'; } || return 1
  w bo2.md "# Brief produit\n\n$BR4$BR_HP\n\`\`\`\nexemple\n"; run --brief "$FX/bo2.md"
  msg "BRIEF dont le dernier bloc de code n'est jamais fermé attendu rc 3 + INDETERMINE brief"
  [ "$RC" -eq 3 ] && has 'INDETERMINE brief : bloc de code non ferme'; }
probe_brief_mentions() {
  local v i=0
  while IFS= read -r v; do
    i=$((i+1)); w "bm-$i.md" "# Brief produit\n\n$BR4## Hors périmètre\n%s\n" "$v"; run --brief "$FX/bm-$i.md"
    msg "rubrique ne portant que la mention « $v » attendu rc 1 + hors_perimetre : vide"
    { [ "$RC" -eq 1 ] && has 'rubrique BRIEF hors_perimetre : vide'; } || return 1
  done <<'EOF'
À définir
<à compléter>
N/A
...
…
- [Qu est-ce qui est exclu ?]
> [Quel problème ?]
*[Qui ?]*
TBA
FIXME
`[ce qui est exclu]`
__________
* À préciser
EOF
  local nb=$'\xc2\xa0' zw=$'\xe2\x80\x8b' d
  for d in "$nb$nb$nb" "$zw$zw$zw" "$nb[ce qui est exclu]" "$zw[ce qui est exclu]"; do
    i=$((i+1)); w "bm-u$i.md" "# Brief produit\n\n$BR4## Hors périmètre\n%s\n" "$d"; run --brief "$FX/bm-u$i.md"
    msg "rubrique faite de blancs Unicode ou d'une mention précédée d'un blanc Unicode attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  done; }
probe_brief_legitime() {
  w bl.md "# Brief produit\n\n$BR_PB$BR_US$BR_VA## Contraintes\nla todo list affiche dix éléments\nle client à venir en magasin\n\n$BR_HP"
  run --brief "$FX/bl.md"
  msg "corps légitimes contenant les mots todo et « à venir » au fil d'une phrase attendu rc 0 (faux rouge m1)"; [ "$RC" -eq 0 ]; }
probe_champ() {
  req1 ch1.md "Le client franchit l etape d acceptation: il valide sa carte bancaire"; run --requirements "$FX/ch1.md"
  msg "mot « acceptation » au fil d'une phrase de continuation attendu rc 1 (ce n'est pas un champ)"; [ "$RC" -eq 1 ] || return 1
  w ch2.md "# Exigences\n\n- [ ] **PAY-01**: Le client franchit l etape d acceptation: il valide sa carte\n  Priorité : must\n"
  run --requirements "$FX/ch2.md"
  msg "mot « acceptation » au fil de la ligne d'exigence attendu rc 1 + PAY-01"; { [ "$RC" -eq 1 ] && has 'ELIMINATOIRE exigence PAY-01'; } || return 1
  req1 ch3.md "ACCEPTATION : $CRIT"; run --requirements "$FX/ch3.md"
  msg "champ en capitales attendu rc 0 (casse indifférente)"; [ "$RC" -eq 0 ] || return 1
  req1 ch4.md "Acceptation"$'\xc2\xa0'": $CRIT"; run --requirements "$FX/ch4.md"
  msg "espace insécable avant les deux-points attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  req1 ch5.md "**Acceptation** : $CRIT"; run --requirements "$FX/ch5.md"
  msg "champ en gras attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  req1 ch6.md "**Acceptation :** $CRIT"; run --requirements "$FX/ch6.md"
  msg "champ en gras, deux-points dans le gras attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  req1 ch8.md "Acceptation du tarif par le client en moins de dix secondes"; run --requirements "$FX/ch8.md"
  msg "ligne qui commence par le mot sans deux-points attendu rc 1 (ce n'est pas un champ)"; [ "$RC" -eq 1 ] || return 1
  w ch7.md "# Exigences\n\n%s\n" "$A1"; run --requirements "$FX/ch7.md"
  msg "champ en milieu de ligne d'exigence après une phrase attendu rc 0 (forme A)"; [ "$RC" -eq 0 ]; }
probe_marques() {
  local nb=$'\xc2\xa0' zw=$'\xe2\x80\x8b' v i=0 vals
  vals=('*[critere mesurable : quoi, combien]*' '`[critere mesurable : quoi]`' '"[critere mesurable : quoi]"' '`[…]`' '"[…]"'
    '__________' '> [critere mesurable : combien]' '_[critere mesurable : combien]_'
    "$nb$nb$nb$nb$nb$nb$nb$nb$nb$nb" "$zw$zw$zw$zw$zw$zw$zw$zw$zw$zw"
    "$nb[critere mesurable : combien]" "${zw}[critere mesurable : combien]" "a${nb}${nb}${nb}${nb}${nb}${nb}${nb}${nb}b" "a${zw}${zw}${zw}${zw}${zw}${zw}${zw}${zw}b")
  for v in "${vals[@]}"; do
    i=$((i+1)); req1 "mq-$i.md" "Acceptation : $v"; run --requirements "$FX/mq-$i.md"
    msg "critère déguisé en mention à remplir (forme n°$i) attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  done; }
probe_cr() {
  local m1="- [ ] **PRD-01**: a\r  Acceptation : $CRIT\r  Priorité : must\r" m2="- [ ] **PRD-02**: b\r  Priorité : should\r"
  w cr1.md "# Exigences\r\r$m1" ; run --requirements "$FX/cr1.md"
  msg "fichier à fins de ligne CR seules attendu rc 0 + exigences=1"; { [ "$RC" -eq 0 ] && last | command grep -q 'BILAN exigences=1 sans_critere=0 '; } || return 1
  w cr2.md "# Exigences\r\r$m1$m2"; run --requirements "$FX/cr2.md"
  msg "fichier CR seul dont la 2e exigence n'a pas de critère attendu rc 1 + PRD-02 (jamais tout fusionné en rc 0)"
  { [ "$RC" -eq 1 ] && has 'ELIMINATOIRE exigence PRD-02'; } || return 1
  local c1="- [ ] **PRD-01**: Afficher le tarif\r\n  Acceptation : le tarif s'affiche en moins de 2 secondes\r\n  Priorité : must\r\n"
  local c2="- [ ] **PRD-02**: Exporter la liste\r\n  Acceptation : un fichier CSV est téléchargé en moins de 5 secondes\r\n  Priorité : could\r\n"
  w cr3.md "# Exigences\r\n\r\n$c1$c2"; run --requirements "$FX/cr3.md"
  msg "fichier CRLF aux continuations attendu rc 0 + exigences=2 sans_critere=0"
  { [ "$RC" -eq 0 ] && last | command grep -q 'BILAN exigences=2 sans_critere=0 '; } || return 1
  w cr4.md "# Brief\r$BR_PB$BR_US$BR_VA$BR_CO$BR_HP"; run --brief "$FX/cr4.md"
  msg "BRIEF à fins de ligne CR seules attendu rc 0"; [ "$RC" -eq 0 ]; }
probe_com_blanc() {
  w cb.md "# Exigences\n\n- [ ] **PRD-01**: Exporter\n  <!--\n\n  une note\n  -->\n  Acceptation : %s\n  Priorité : must\n" "$CRIT"
  run --requirements "$FX/cb.md"
  msg "ligne blanche dans un commentaire multi-ligne attendu rc 0 (elle ne ferme pas l'exigence)"
  [ "$RC" -eq 0 ] && last | command grep -q 'BILAN exigences=1 sans_critere=0 '; }
probe_mot_legitime() {
  local v i=0
  while IFS= read -r v; do
    i=$((i+1)); req1 "ml-$i.md" "Acceptation : $v"; run --requirements "$FX/ml-$i.md"
    msg "critère légitime « $v » attendu rc 0 : un mot de remplissage au fil d'une phrase n'est pas du remplissage"; [ "$RC" -eq 0 ] || return 1
  done <<'EOF'
la todo list affiche dix éléments
le client à venir en magasin voit dix produits
EOF
  while IFS= read -r v; do
    i=$((i+1)); req1 "ml-$i.md" "Acceptation : $v"; run --requirements "$FX/ml-$i.md"
    msg "critère « $v » attendu rc 1 : le marqueur est isolé (début, fin ou ponctuation)"; [ "$RC" -eq 1 ] || return 1
  done <<'EOF'
le tarif affiché est à venir
le tarif s'affiche vite ; todo ; voir le client
le tarif de la prochaine version est à définir avec le client
EOF
}
probe_cochee() {
  w cx1.md "# Exigences\n\n- [x] **PRD-01**: Exporter\n  Priorité : must\n"; run --requirements "$FX/cx1.md"
  msg "exigence cochée [x] sans critère attendu rc 1 + PRD-01"; { [ "$RC" -eq 1 ] && has 'ELIMINATOIRE exigence PRD-01'; } || return 1
  w cx2.md "# Exigences\n\n- [X] **PRD-01**: Exporter\n  Acceptation : %s\n" "$CRIT"; run --requirements "$FX/cx2.md"
  msg "exigence cochée [X] avec critère attendu rc 0 + exigences=1"
  [ "$RC" -eq 0 ] && last | command grep -q 'BILAN exigences=1 sans_critere=0 '; }
probe_hors_sujet() {
  w hs.md "# Brief produit\n\n$BR4## Hors sujet\nPas de paiement.\n"; run --brief "$FX/hs.md"
  msg "rubrique « Hors sujet » attendu rc 1 + hors_perimetre : absente (seule « Hors périmètre » compte)"
  [ "$RC" -eq 1 ] && has 'hors_perimetre : absente'; }
probe_5_sur_1() {
  w b5.md "# Brief produit\n"; ln -sf "$FX/okA.md" "$FX/lien5.md"; reg lien5.md
  run --requirements "$FX/lien5.md" --brief "$FX/b5.md"
  msg "exigences en lien symbolique (5) puis BRIEF vide (1) attendu rc 5 (5 l'emporte sur 1)"; [ "$RC" -eq 5 ]; }
case_ CPRD-COM-OUVERT probe_com_ouvert
case_ CPRD-BRIEF-OUVERT probe_brief_ouvert
case_ CPRD-BRIEF-MENTIONS probe_brief_mentions
case_ CPRD-BRIEF-LEGITIME probe_brief_legitime
case_ CPRD-CHAMP probe_champ
case_ CPRD-MARQUES probe_marques
case_ CPRD-CR probe_cr
case_ CPRD-COM-BLANC probe_com_blanc
case_ CPRD-MOT-LEGITIME probe_mot_legitime
case_ CPRD-COCHEE probe_cochee
case_ CPRD-HORS-SUJET probe_hors_sujet
case_ CPRD-5-SUR-1 probe_5_sur_1

# === Combinaison des entrées, contenu jamais réimprimé =============================================
probe_mix() { run --requirements "$FX/trois.md" --brief "$FX/n-existe-pas.md"
  msg "éliminatoire + BRIEF absent attendu rc 1 (1 l'emporte sur 3)"; [ "$RC" -eq 1 ] && has 'INDETERMINE brief'; }
probe_noecho() {
  w secret.md "# Exigences\n\n- [ ] **PRD-01**: $MARK à ne jamais réimprimer\n  Priorité : must\n"
  w secret-brief.md "# Brief\n\n## Valeur\n[$MARK]\n"
  run --requirements "$FX/secret.md" --brief "$FX/secret-brief.md"
  msg "attendu rc 1 sans $MARK sur stdout ni stderr"
  [ "$RC" -eq 1 ] && ! has "$MARK" && ! printf '%s' "$ERR" | command grep -qF "$MARK"; }
case_ CPRD-MIX probe_mix
case_ CPRD-NOECHO probe_noecho

# === Entrées non fiables : refus bruyant AVANT lecture (T-59-03) ====================================
probe_absent() { run --requirements "$FX/n-existe-pas.md"
  msg "cible absente attendu rc 3 + INDETERMINE"; [ "$RC" -eq 3 ] && has 'INDETERMINE exigences'; }
probe_lien() {
  w okA.md '# Exigences\n\n%s\n%s\n' "$A1" "$A2"; ln -sf "$FX/okA.md" "$FX/lien.md"; reg lien.md
  run --requirements "$FX/lien.md"
  msg "lien symbolique vers un fichier conforme attendu rc 5 + ILLISIBLE lien symbolique sur stdout et stderr"
  [ "$RC" -eq 5 ] && has 'ILLISIBLE exigences : lien symbolique' \
    && printf '%s' "$ERR" | command grep -qF 'ILLISIBLE exigences : lien symbolique'; }
probe_fifo() { [ -p "$FX/fifo" ] || mkfifo "$FX/fifo"; reg fifo; run --requirements "$FX/fifo"
  msg "FIFO attendu rc 5 sans blocage (142 = lue)"; [ "$RC" -eq 5 ]; }
probe_dossier() { mkdir -p "$FX/dossier"; reg dossier; run --requirements "$FX/dossier"
  msg "dossier attendu rc 5"; [ "$RC" -eq 5 ]; }
probe_gros() {
  [ -f "$FX/gros.md" ] || { dd if=/dev/zero bs=1048577 count=1 2>/dev/null | tr '\0' 'x' > "$FX/gros.md"; reg gros.md; }
  run --requirements "$FX/gros.md"
  msg "1048577 octets attendu rc 5"; [ "$RC" -eq 5 ] || return 1
  [ -f "$FX/borne.md" ] || { dd if=/dev/zero bs=1048576 count=1 2>/dev/null | tr '\0' 'x' > "$FX/borne.md"; reg borne.md; }
  run --requirements "$FX/borne.md"
  msg "1048576 octets (la borne incluse) attendu rc 3, pas 5"; [ "$RC" -eq 3 ]; }
probe_illisible() { w ferme.md '# Exigences\n\n%s\n' "$A1"; chmod 000 "$FX/ferme.md"; run --requirements "$FX/ferme.md"
  local r=$RC; chmod 600 "$FX/ferme.md"; RC=$r
  msg "fichier illisible attendu rc 5"; [ "$RC" -eq 5 ]; }
case_ CPRD-ABSENT probe_absent
case_ CPRD-LIEN probe_lien
case_ CPRD-FIFO probe_fifo
case_ CPRD-DOSSIER probe_dossier
case_ CPRD-GROS probe_gros
if [ "$(id -u)" -eq 0 ]; then skip "CPRD-ILLISIBLE (suite jouée en root : chmod 000 n'interdit rien)"
else case_ CPRD-ILLISIBLE probe_illisible; fi
probe_mix5() { w brief-ok.md "# Brief produit\n\n$BR_PB$BR_US$BR_VA$BR_CO$BR_HP"; ln -sf "$FX/brief-ok.md" "$FX/lien-brief.md"; reg lien-brief.md
  run --requirements "$FX/okA.md" --brief "$FX/lien-brief.md"
  msg "exigences conformes + BRIEF en lien symbolique attendu rc 5 (5 l'emporte sur 0)"; [ "$RC" -eq 5 ]; }
case_ CPRD-MIX5 probe_mix5

# === Classes génératives (revue-59, tour 2) : un produit cartésien ferme une classe, une liste de cas non ======
# Chaque cellule est une assertion comptée (PASS), attribuée à son identifiant ; le compte total est imprimé en
# fin de suite. Les cellules d'un cas sont écrites en lots de 40 exigences (borne de 50 lignes par catégorie du
# script) ou de 5 rubriques de BRIEF : un lot = un appel, chaque cellule est lue par son identifiant.
GEN_FILL="le tarif s'affiche en 2 secondes"
GEN_VALID="un fichier CSV est téléchargé en moins de 5 secondes"
GEN_TOT=0; GEN_OK=0; CELLS_N=0
NBSP=$'\xc2\xa0'

# crit_cells <red|green> <tag> : stdin = cellules « reste de la ligne d'exigence@@ligne de continuation » (la
# continuation peut être vide). rouge attendu = « ELIMINATOIRE exigence GEN-nnn » ; vert = absent. -> CELLS_N, $TMP/genfail.
crit_cells() {
  local mode=$1 tag=$2 line total i=0 j cnt chunk=0 k f id present bad
  local -a H=() C=()
  CELLS_N=0; : > "$TMP/genfail"
  while IFS= read -r line; do H[${#H[@]}]="${line%%@@*}"; C[${#C[@]}]="${line#*@@}"; done
  total=${#H[@]}
  while [ "$i" -lt "$total" ]; do
    chunk=$((chunk+1)); cnt=0; j=$i; f="$FX/gen-$tag-$chunk.md"
    {
      printf '# Exigences\n\n'
      while [ "$j" -lt "$total" ] && [ "$cnt" -lt 40 ]; do
        printf -- '- [ ] **GEN-%03d**: %s\n' "$((cnt+1))" "${H[$j]}"
        if [ -n "${C[$j]}" ]; then printf '  %s\n' "${C[$j]}"; fi
        printf '  Priorité : must\n'
        j=$((j+1)); cnt=$((cnt+1))
      done
    } > "$f"
    reg "gen-$tag-$chunk.md"
    run --requirements "$f"
    bad=0; last | command grep -q "BILAN exigences=$cnt " || bad=1
    if [ "$bad" -eq 1 ]; then echo "lot $chunk : BILAN sans exigences=$cnt, obtenu rc $RC [$(last | cut -c1-120)]" >> "$TMP/genfail"; fi
    for k in $(seq 1 "$cnt"); do
      id="$(printf 'GEN-%03d' "$k")"; present=0
      has "ELIMINATOIRE exigence $id :" && present=1
      if [ "$mode" = red ] && [ "$present" -eq 0 ]; then
        echo "cellule [$(printf '%s' "${H[$((i+k-1))]}@@${C[$((i+k-1))]}" | cut -c1-140)] attendu rouge (éliminatoire), obtenu vert, rc $RC" >> "$TMP/genfail"
      elif [ "$mode" = green ] && [ "$present" -eq 1 ]; then
        echo "cellule [$(printf '%s' "${H[$((i+k-1))]}@@${C[$((i+k-1))]}" | cut -c1-140)] attendu vert (champ reconnu), obtenu éliminatoire, rc $RC" >> "$TMP/genfail"
      fi
    done
    CELLS_N=$((CELLS_N+cnt)); i=$j
  done
  msg_gen
  [ ! -s "$TMP/genfail" ]
}
# brief_cells <tag> : stdin = valeurs ; chacune est le SEUL corps d'une rubrique, qui doit sortir « vide » (par 5).
brief_cells() {
  local tag=$1 line i=0 g=0 k f
  local -a V=()
  local -a NM=(probleme utilisateurs valeur contraintes hors_perimetre)
  local -a HD=("Problème" "Utilisateurs" "Valeur" "Contraintes" "Hors périmètre")
  CELLS_N=0; : > "$TMP/genfail"
  while IFS= read -r line; do V[${#V[@]}]=$line; done
  while [ "$i" -lt "${#V[@]}" ]; do
    g=$((g+1)); f="$FX/genb-$tag-$g.md"
    {
      printf '# Brief produit\n\n'
      for k in 0 1 2 3 4; do
        printf '## %s\n' "${HD[$k]}"
        if [ $((i+k)) -lt "${#V[@]}" ]; then printf '%s\n\n' "${V[$((i+k))]}"; else printf 'Un corps légitime de la rubrique.\n\n'; fi
      done
    } > "$f"
    reg "genb-$tag-$g.md"
    run --brief "$f"
    for k in 0 1 2 3 4; do
      [ $((i+k)) -lt "${#V[@]}" ] || continue
      CELLS_N=$((CELLS_N+1))
      if [ "${BMODE:-red}" = green ]; then
        { has "ELIMINATOIRE rubrique BRIEF ${NM[$k]} :"; } \
          && echo "cellule BRIEF [$(printf '%s' "${V[$((i+k))]}" | cut -c1-140)] attendu vert (corps lu), obtenu rubrique vide, rc $RC" >> "$TMP/genfail"
      else
        has "ELIMINATOIRE rubrique BRIEF ${NM[$k]} : vide" \
          || echo "cellule BRIEF [$(printf '%s' "${V[$((i+k))]}" | cut -c1-140)] attendu rouge (rubrique vide), obtenu vert, rc $RC" >> "$TMP/genfail"
      fi
    done
    i=$((i+5))
  done
  msg_gen
  [ ! -s "$TMP/genfail" ]
}
# brief_grp <tag> : stdin = valeurs ; HUIT valeurs par rubrique (corps = ces huit lignes), toutes à lire comme vides. Une
# rubrique qui n'est pas « vide » trahit au moins une valeur lue comme un corps : chacune est alors rejouée seule, la
# trace nomme la cellule fautive.
brief_grp() {
  local tag=$1 line i=0 g=0 k j f idx cnt v
  local -a V=()
  local -a NM=(probleme utilisateurs valeur contraintes hors_perimetre)
  local -a HD=("Problème" "Utilisateurs" "Valeur" "Contraintes" "Hors périmètre")
  CELLS_N=0; : > "$TMP/genfail"
  while IFS= read -r line; do V[${#V[@]}]=$line; done
  while [ "$i" -lt "${#V[@]}" ]; do
    g=$((g+1)); f="$FX/genbg-$tag-$g.md"
    {
      printf '# Brief produit\n\n'
      for k in 0 1 2 3 4; do
        printf '## %s\n' "${HD[$k]}"; cnt=0
        for j in 0 1 2 3 4 5 6 7; do idx=$((i+k*8+j)); if [ "$idx" -lt "${#V[@]}" ]; then printf '%s\n' "${V[$idx]}"; cnt=$((cnt+1)); fi; done
        if [ "$cnt" -eq 0 ]; then printf 'Un corps légitime de la rubrique.\n'; fi
        printf '\n'
      done
    } > "$f"
    reg "genbg-$tag-$g.md"
    run --brief "$f"
    for k in 0 1 2 3 4; do
      cnt=0; for j in 0 1 2 3 4 5 6 7; do idx=$((i+k*8+j)); [ "$idx" -lt "${#V[@]}" ] && cnt=$((cnt+1)); done
      [ "$cnt" -gt 0 ] || continue
      CELLS_N=$((CELLS_N+cnt))
      has "ELIMINATOIRE rubrique BRIEF ${NM[$k]} : vide" && continue
      for j in 0 1 2 3 4 5 6 7; do idx=$((i+k*8+j)); [ "$idx" -lt "${#V[@]}" ] || continue
        v=${V[$idx]}; printf '# Brief produit\n\n## Problème\n%s\n\n## Utilisateurs\nLes clients.\n\n## Valeur\nMoins d appels.\n\n## Contraintes\nCoût borné.\n\n## Hors périmètre\nPas de paiement.\n' "$v" > "$FX/genbg-solo-$g-$idx.md"; reg "genbg-solo-$g-$idx.md"
        run --brief "$FX/genbg-solo-$g-$idx.md"
        has "ELIMINATOIRE rubrique BRIEF probleme : vide" || echo "cellule BRIEF [$(printf '%s' "$v" | cut -c1-140)] attendu rouge (rubrique vide), obtenu vert, rc $RC" >> "$TMP/genfail"
      done
    done
    i=$((i+40))
  done
  msg_gen
  [ ! -s "$TMP/genfail" ]
}
msg_gen() { if [ -s "$TMP/genfail" ]; then LASTMSG="$(head -1 "$TMP/genfail") ($(awk 'END{print NR}' "$TMP/genfail") cellule(s) en défaut)"; else LASTMSG=""; fi; }
# gen_case <id> <description> <crit-red|crit-green|brief> <producteur de cellules> : compte chaque cellule.
gen_case() {
  local id=$1 desc=$2 kind=$3 prod=$4 nfail=0 l
  case "$kind" in
    crit-red) crit_cells red "$id" < <("$prod") ;;
    crit-green) crit_cells green "$id" < <("$prod") ;;
    brief) brief_cells "$id" < <("$prod") ;;
    brief-grp) brief_grp "$id" < <("$prod") ;;
    brief-green) BMODE=green brief_cells "$id" < <("$prod") ;;
  esac
  [ -s "$TMP/genfail" ] && nfail="$(awk 'END{print NR}' "$TMP/genfail")"
  GEN_TOT=$((GEN_TOT+CELLS_N)); GEN_OK=$((GEN_OK+CELLS_N-nfail)); PASS=$((PASS+CELLS_N-nfail))
  if [ "$nfail" -eq 0 ]; then echo "  ✓ $id : $CELLS_N cellules conformes ($desc)"
  else while IFS= read -r l; do ko "$id — $l"; done < "$TMP/genfail"; fi
}

# Marques de tête (puces, numérotées, citation, emphase, code, guillemets, empilées) × mentions à remplir.
MARKS=('' '- ' '* ' '+ ' $'• ' $'· ' $'– ' $'— ' '1. ' '1) ' '12. ' '> ' '*' '_' '**' '`' '"' "'" $'« ' $'“' $'‘' $'„' $'‣ ' $'◦ ' $'▪ ' $'∙ ' $'● ' '~ ' '= ' '| ' '> - ' '- **' '1. *' $'• _' '> > ' '- - ')
MENT=('[décrire le critère mesurable]' '[Quel problème ?]' '<à compléter>' '<utilisateur cible>' '[…]' 'TBD' 'TBA' 'TODO' 'FIXME' 'N/A' 'n/a' 'À définir' 'à compléter' 'à préciser' 'à venir' 'à déterminer' 'à remplir' 'à renseigner' 'à confirmer' 'à décider' '...' $'…' $'［décrire ici］' $'＜à compléter＞' $'〈ici〉' $'⟨ici⟩')
cells_marks_crit() { local mk m; for mk in "${MARKS[@]}"; do for m in "${MENT[@]}"; do printf ' Cellule@@Acceptation : %s%s %s\n' "$mk" "$m" "$GEN_FILL"; done; done; }
cells_marks_brief() { local mk m; for mk in "${MARKS[@]}"; do for m in "${MENT[@]}"; do printf '%s%s\n' "$mk" "$m"; done; done; }
gen_case CPRD-GEN-MARQUES-CRITERE "${#MARKS[@]} marques de tête x ${#MENT[@]} mentions, critère d'acceptation" crit-red cells_marks_crit
gen_case CPRD-GEN-MARQUES-BRIEF "${#MARKS[@]} marques de tête x ${#MENT[@]} mentions, corps de rubrique du BRIEF" brief cells_marks_brief

# Champ « Acceptation » reconnu : séparateurs admis x casse x espace insécable (avant le mot, avant les deux-points).
SEPS=(':' '.' ';' ' |' '!' '?' ')' ',' $' \xe2\x80\x94' $' \xe2\x80\x93' ' -' ' (' '')
WORDS=('Acceptation' 'ACCEPTATION' 'acceptation')
cells_champ() {
  local s w sp1 sp2
  for s in "${SEPS[@]}"; do for w in "${WORDS[@]}"; do for sp1 in ' ' "$NBSP"; do for sp2 in '' ' ' "$NBSP"; do
    if [ -z "$s" ]; then printf ' Texte@@%s%s%s: %s\n' "$sp1" "$w" "$sp2" "$GEN_VALID"
    else printf ' Texte%s%s%s%s: %s@@\n' "$s" "$sp1" "$w" "$sp2" "$GEN_VALID"; fi
  done; done; done; done
  for s in "${SEPS[@]}"; do for w in "Critère d'acceptation" $'Critère d\xe2\x80\x99acceptation' "CRITÈRE D'ACCEPTATION" "Critere D'Acceptation"; do
    if [ -z "$s" ]; then printf ' Texte@@%s : %s\n' "$w" "$GEN_VALID"; else printf ' Texte%s %s : %s@@\n' "$s" "$w" "$GEN_VALID"; fi
  done; done
  for w in '**Acceptation** :' '**Acceptation :**' '_Acceptation_ :' '"Acceptation :"' $'« Acceptation : »'; do
    printf ' **Exporter la liste** %s %s@@\n' "$w" "$GEN_VALID"; printf ' Texte@@%s %s\n' "$w" "$GEN_VALID"
  done
}
gen_case CPRD-GEN-CHAMP "séparateurs x casse x insécable, plus « Critère d'acceptation » et champs en emphase" crit-green cells_champ

# Mot « acceptation » précédé d'un mot (ou d'une lettre, d'un chiffre, d'une apostrophe collée) : pas un champ.
PREWORDS=('l etape d ' "l'étape d'" $'l\xe2\x80\x99étape d\xe2\x80\x99' 'la phase de ' 'une ' 'notre ' 'x ' '2 ' 'été ' 'α ' 'и ' 'Version 2 ' '"la ' "la liste d'" 'Łódź ' $'cafe\xcc\x81 ')
cells_mot() {
  local p w sp2
  for p in "${PREWORDS[@]}"; do for w in 'acceptation' 'ACCEPTATION' 'Acceptation'; do for sp2 in '' ' ' "$NBSP"; do
    printf ' Le client franchit %s%s%s: %s@@\n' "$p" "$w" "$sp2" "$GEN_VALID"
    printf ' Titre@@Le client franchit %s%s%s: %s\n' "$p" "$w" "$sp2" "$GEN_VALID"
  done; done; done
  printf ' Le client valide la phase de critère d'"'"'acceptation : %s@@\n' "$GEN_VALID"
}
gen_case CPRD-GEN-MOT "mot précédé d'un mot, d'une lettre, d'un chiffre ou d'une apostrophe collée : non reconnu" crit-red cells_mot

# Caractères invisibles et blancs Unicode : ramenés à la forme nue avant le test de remplissage.
INVIS=($'\xe2\x80\x8b' $'\xe2\x80\x8c' $'\xe2\x80\x8d' $'\xe2\x80\x8e' $'\xe2\x80\x8f' $'\xe2\x81\xa0' $'\xef\xbb\xbf' $'\xc2\xad' $'\xe1\xa0\x8e')
BLANKS=("$NBSP" $'\xe2\x80\x80' $'\xe2\x80\x81' $'\xe2\x80\x82' $'\xe2\x80\x83' $'\xe2\x80\x84' $'\xe2\x80\x85' $'\xe2\x80\x86' $'\xe2\x80\x87' $'\xe2\x80\x88' $'\xe2\x80\x89' $'\xe2\x80\x8a' $'\xe2\x80\xa8' $'\xe2\x80\xa9' $'\xe2\x80\xaf' $'\xe2\x81\x9f' $'\xe3\x80\x80' $'\xe1\x9a\x80')
# cellules d'un caractère : <inv|blk> <caractère...>
chars_cells_crit() { local kind=$1 ch; shift
  for ch in "$@"; do
    printf ' Cellule@@Acceptation : %s[critère mesurable : quoi] %s\n' "$ch" "$GEN_FILL"
    printf ' Cellule@@Acceptation : - %s<critère mesurable> %s\n' "$ch" "$GEN_FILL"
    if [ "$kind" = inv ]; then printf ' Cellule@@Acceptation : T%sB%sD %s\n' "$ch" "$ch" "$GEN_FILL"
    else printf ' Cellule@@Acceptation : à%sdéfinir %s\n' "$ch" "$GEN_FILL"; printf ' Cellule@@Acceptation : %s%s%s%s%s%s%s%s%s%s\n' "$ch" "$ch" "$ch" "$ch" "$ch" "$ch" "$ch" "$ch" "$ch" "$ch"; fi
  done; }
chars_cells_brief() { local kind=$1 ch; shift
  for ch in "$@"; do
    printf '%s[décrire ici]\n' "$ch"; printf -- '- %s<à compléter>\n' "$ch"
    if [ "$kind" = inv ]; then printf 'T%sB%sD\n' "$ch" "$ch"; else printf 'à%sdéfinir\n' "$ch"; fi
  done; }
cells_inv_crit() { chars_cells_crit inv "${INVIS[@]}"; }
cells_blk_crit() { chars_cells_crit blk "${BLANKS[@]}"; }
cells_inv_brief() { chars_cells_brief inv "${INVIS[@]}"; }
cells_blk_brief() { chars_cells_brief blk "${BLANKS[@]}"; }
gen_case CPRD-GEN-INVISIBLES-CRITERE "${#INVIS[@]} caractères de largeur nulle, en tête et au milieu d'un marqueur" crit-red cells_inv_crit
gen_case CPRD-GEN-BLANCS-CRITERE "${#BLANKS[@]} blancs Unicode, en tête, entre deux mots, ou seuls" crit-red cells_blk_crit
gen_case CPRD-GEN-INVISIBLES-BRIEF "${#INVIS[@]} caractères de largeur nulle, corps de rubrique du BRIEF" brief cells_inv_brief
gen_case CPRD-GEN-BLANCS-BRIEF "${#BLANKS[@]} blancs Unicode, corps de rubrique du BRIEF" brief cells_blk_brief

# Marques combinantes : retirées du décompte (neuf lettres accentuées = neuf caractères, jamais dix-huit) ; dix restent vertes.
cells_comb_red() { local c; for c in $'\xcc\x81' $'\xcd\x81'; do printf ' Cellule@@Acceptation : a%sb%sc%sd%se%sf%sg%sh%si%s\n' "$c" "$c" "$c" "$c" "$c" "$c" "$c" "$c" "$c"; done; }
cells_comb_green() { local c; for c in $'\xcc\x81' $'\xcd\x81'; do printf ' Cellule@@Acceptation : a%sb%sc%sd%se%sf%sg%sh%si%sj%s\n' "$c" "$c" "$c" "$c" "$c" "$c" "$c" "$c" "$c" "$c"; done; }
gen_case CPRD-GEN-COMBINANTES-COURT "9 caractères portant des marques combinantes (U+0301, U+0341) : trop court" crit-red cells_comb_red
gen_case CPRD-GEN-COMBINANTES-DIX "10 caractères portant des marques combinantes : suffisant" crit-green cells_comb_green

# Repli des accents et des majuscules : chaque lettre accentuée d'un marqueur, minuscule et majuscule.
FOLDS=('à définir' 'À DÉFINIR' 'â définir' 'à définîr' 'à définïr' 'à compléter' 'à cômpléter' 'à préçiser' 'à décidèr' 'à décidêr' 'à décidër' 'à déterminer' 'À RENSEIGNER' 'à CONFIRMER')
cells_folds_crit() { local m; for m in "${FOLDS[@]}"; do printf ' Cellule@@Acceptation : %s %s\n' "$m" "$GEN_FILL"; done; }
cells_folds_brief() { local m; for m in "${FOLDS[@]}"; do printf '%s\n' "$m"; done; }
gen_case CPRD-GEN-REPLI-CRITERE "${#FOLDS[@]} variantes accentuées ou capitalisées des marqueurs" crit-red cells_folds_crit
gen_case CPRD-GEN-REPLI-BRIEF "${#FOLDS[@]} variantes accentuées ou capitalisées, BRIEF" brief cells_folds_brief

# BOM en tête de fichier : retiré avant la première ligne (exigence en 1re ligne ; rubrique en 1re ligne).
probe_bom_req() {
  printf '\xef\xbb\xbf- [ ] **PRD-01**: Exporter la liste\n  Acceptation : %s\n  Priorité : must\n' "$CRIT" > "$FX/bom-req.md"; reg bom-req.md
  run --requirements "$FX/bom-req.md"
  msg "BOM suivi d'une exigence en première ligne attendu rc 0 + exigences=1"
  [ "$RC" -eq 0 ] && last | command grep -q 'BILAN exigences=1 sans_critere=0 '; }
probe_bom_brief() {
  printf '\xef\xbb\xbf## Problème\nLe tarif est introuvable.\n\n## Utilisateurs\nLes clients.\n\n## Valeur\nMoins d appels.\n\n## Contraintes\nCoût borné.\n\n## Hors périmètre\nPas de paiement.\n' > "$FX/bom-brief.md"; reg bom-brief.md
  run --brief "$FX/bom-brief.md"
  msg "BOM suivi d'une rubrique en première ligne attendu rc 0 (rubrique Problème lue)"; [ "$RC" -eq 0 ]; }
case_ CPRD-BOM-EXIGENCE probe_bom_req
case_ CPRD-BOM-BRIEF probe_bom_brief
# Commentaires HTML : contenu jamais lu, reste de ligne conservé exactement.
probe_com_contenu() {
  w cc1.md "# Exigences\n\n- [ ] **PRD-01**: x\n  <!--\n    Acceptation : %s\n  -->\n  Priorité : must\n" "$CRIT"; run --requirements "$FX/cc1.md"
  msg "critère contenu dans un commentaire multi-ligne attendu rc 1 (un commentaire n'est pas un critère)"; [ "$RC" -eq 1 ] || return 1
  w cc2.md "# Exigences\n\n- [ ] **PRD-01**: x\n  <!-- note -->Acceptation : %s\n" "$CRIT"; run --requirements "$FX/cc2.md"
  msg "critère collé à la fin d'un commentaire sur la même ligne attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  w cc3.md "# Exigences\n\n- [ ] **PRD-01**: x\n  <!-- note\n  fin --> Acceptation : %s\n" "$CRIT"; run --requirements "$FX/cc3.md"
  msg "critère collé à la fin d'un commentaire multi-ligne attendu rc 0"; [ "$RC" -eq 0 ]; }
case_ CPRD-COM-CONTENU probe_com_contenu

# === Classes génératives (revue-59, tour 3) : la mise en forme en ligne, par construction ========================
# Un marqueur à remplir entouré de N'IMPORTE QUELLE emphase vaut le marqueur nu ; un champ vide reste vide quel que soit
# ce qui le suit sur la ligne ; un titre de rubrique se lit à la typographie près. Enveloppes : aucune, paire (`*x*`
# `_x_` `**x**` `__x__` code, guillemets droits, courbes, chevrons, `~~x~~`), tête seule, fin seule, imbriquées par
# deux. Positions : seule, en début, en fin, au milieu, mots séparés (chaque mot enveloppé à part).
EH=(); ET=()
addenv() { EH[${#EH[@]}]=$1; ET[${#ET[@]}]=$2; }
addenv '' ''
for p in '*' '_' '**' '__' '`' '"' "'" '~~'; do addenv "$p" "$p"; done
addenv $'«' $'»'; addenv $'« ' $' »'; addenv $'“' $'”'; addenv $'‘' $'’'
for p in '*' '_' '**' '__' '`' '"' $'«' '~' $'“' $'‘'; do addenv "$p" ''; done
for p in '*' '_' '**' '__' '`' '"' $'»' '~' $'”' $'’'; do addenv '' "$p"; done
addenv '_*' '*_'; addenv '*_' '_*'; addenv '**_' '_**'; addenv '_**' '**_'; addenv '"*' '*"'; addenv '*"' '"*'
addenv '`**' '**`'; addenv $'«_' $'_»'; addenv '**__' '__**'; addenv '"_' '_"'; addenv '_`' '`_'; addenv '~~*' '*~~'
addenv '_*' ''; addenv '*_' ''; addenv '' '_*'; addenv '' '*_'
STRONG=('TBD' 'TBA' 'FIXME' 'n/a' 'à définir' 'à préciser' 'à compléter' 'à déterminer' 'à remplir' 'à renseigner' 'à confirmer' 'à décider')
WEAK=('TODO' 'à venir')
LEGIT_S="le tarif s'affiche en 2 secondes"
NENV=${#EH[@]}
wrap() { printf '%s%s%s' "${EH[$1]}" "$2" "${ET[$1]}"; }
# envs_with <sous-chaîne> : indices des enveloppes qui portent cette chaîne (tête ou fin).
envs_with() { local e r=""; for ((e=0; e<NENV; e++)); do case "${EH[$e]}${ET[$e]}" in *"$1"*) r="$r $e" ;; esac; done; printf '%s' "$r"; }
ALLENV=""; for ((i=0; i<NENV; i++)); do ALLENV="$ALLENV $i"; done
# env_red [grand|petit] : valeurs qui doivent être lues comme à remplir (ENVSEL = indices ; défaut : tous).
env_red() { local size=${1:-grand} e m w a b x
  for e in ${ENVSEL:-$ALLENV}; do
    if [ "$size" = grand ]; then
      for m in "${STRONG[@]}"; do x="$(wrap "$e" "$m")"
        printf '%s\n' "$x" "$x $LEGIT_S" "$LEGIT_S $x" "le tarif $x s'affiche en 2 secondes"
        case "$m" in *' '*) a="${m%% *}"; b="${m#* }"; printf '%s\n' "$(wrap "$e" "$a") $(wrap "$e" "$b") $LEGIT_S" "le tarif $(wrap "$e" "$a") $(wrap "$e" "$b") s'affiche" ;; esac
      done
    else
      for m in 'TBD' 'à définir'; do x="$(wrap "$e" "$m")"
        printf '%s\n' "$x" "le tarif $x s'affiche en 2 secondes"
        case "$m" in *' '*) a="${m%% *}"; b="${m#* }"; printf '%s\n' "$(wrap "$e" "$a") $(wrap "$e" "$b") $LEGIT_S" ;; esac
      done
    fi
    for m in "${WEAK[@]}"; do x="$(wrap "$e" "$m")"
      if [ "$size" = grand ] || [ "$m" = TODO ]; then printf '%s\n' "$x" "$x $LEGIT_S" "$LEGIT_S $x"; fi
    done
  done; }
# env_green : phrases légitimes (jamais à remplir), enveloppées de toutes les façons.
env_green() { local e x
  for e in ${ENVSEL:-$ALLENV}; do
    printf '%s\n' "$(wrap "$e" "$LEGIT_S")" "$(wrap "$e" 'tarif') $LEGIT_S" "$LEGIT_S $(wrap "$e" 'export CSV')" "le $(wrap "$e" 'tarif') s'affiche en 2 secondes"
    printf '%s\n' "la $(wrap "$e" 'todo') list affiche dix éléments en 2 secondes" "le mois $(wrap "$e" 'à venir') affiche trois rapports en 2 secondes"
  done; }
to_crit() { local v; while IFS= read -r v; do printf ' Cellule@@Acceptation : %s\n' "$v"; done; }
cells_env_red_crit() { env_red grand | to_crit; }
cells_env_red_brief() { env_red grand; }
cells_env_green_crit() { env_green | to_crit; }
cells_env_green_brief() { env_green; }
gen_case CPRD-GEN-ENVELOPPES-CRITERE-ROUGE "$NENV enveloppes x 12 marqueurs forts, 2 faibles, 5 positions, critère d'acceptation" crit-red cells_env_red_crit
gen_case CPRD-GEN-ENVELOPPES-BRIEF-ROUGE "$NENV enveloppes x marqueurs x positions, corps de rubrique du BRIEF" brief-grp cells_env_red_brief
gen_case CPRD-GEN-ENVELOPPES-CRITERE-VERT "$NENV enveloppes x phrases légitimes (dont todo et à venir au fil d'une phrase), critère" crit-green cells_env_green_crit
gen_case CPRD-GEN-ENVELOPPES-BRIEF-VERT "$NENV enveloppes x phrases légitimes, corps de rubrique du BRIEF" brief-green cells_env_green_brief

# Champ vide suivi d'un autre champ sur la même ligne (ou en continuation) : la valeur s'arrête au champ suivant.
FSEPS=(' — ' ' ; ' '. ' ' | ' ', ' ' - ' ' (' ' « ')
FVALS=('' ' ' '  ' "$NBSP" ' ;' ' —' ' .' ' -' ' ,' ' !' ' ?' ' |' ' ()' ' **' ' __' ' ``' ' ""' $' «»' ' ***')
FNEXTS=('' ' Priorité : must' ' priorité: should' ' PRIORITÉ : could' ' **Priorité** : must' ' Priorite : must' ' — Priorité : must' '. Priorité : must' $' Priorite\xcc\x81 : must')
FNEXTS_SM=('' ' Priorité : must' ' PRIORITÉ : could' ' — Priorité : must' $' Priorite\xcc\x81 : must')
cells_field_red() { local s v n
  for s in "${FSEPS[@]}"; do for v in "${FVALS[@]}"; do for n in "${FNEXTS[@]}"; do
    printf ' Texte%sAcceptation :%s%s@@\n' "$s" "$v" "$n"; printf ' Texte@@Acceptation :%s%s\n' "$v" "$n"
  done; done; done
  for s in "${FSEPS[@]}"; do
    printf ' Texte%sAcceptation : Acceptation :@@\n' "$s"; printf " Texte%sAcceptation : Critère d'acceptation :@@\n" "$s"
  done; }
cells_field_green() { local s n
  for s in "${FSEPS[@]}"; do for n in "${FNEXTS[@]}"; do
    printf ' Texte%sAcceptation : %s%s@@\n' "$s" "$GEN_VALID" "$n"; printf ' Texte@@Acceptation : %s%s\n' "$GEN_VALID" "$n"
  done
    printf ' Texte%sAcceptation : le tarif de priorité : haute reste visible en 2 s@@\n' "$s"
  done; }
gen_case CPRD-GEN-CHAMP-VIDE "${#FSEPS[@]} séparateurs x ${#FVALS[@]} valeurs vides, blanches ou de ponctuation x ${#FNEXTS[@]} champs suivants, sur la ligne et en continuation" crit-red cells_field_red
gen_case CPRD-GEN-CHAMP-SUIVI "séparateurs x champs suivants avec un critère réel : verts, « de priorité : » au fil d'une phrase vert" crit-green cells_field_green

# Valeurs faites de ponctuation seule, ou dont le seul poids est une mise en forme, ou de ponctuation en tête et en fin.
PUNCT=('!!!' ';' '?' '()' '(())' '.' ',' ':' '[ ]' '{}' '|||')
cells_punct_brief() { printf '%s\n' "${PUNCT[@]}"; }
cells_punct_crit() { local v; for v in "${PUNCT[@]}" 'abcdefg !!!' 'abcdefg ???' 'abcdefg ;;;' 'abcdefg (((' '!!! abcdefg' '))) abcdefg' 'ok **********' 'ok __________' 'ok ~~~~~~~~~~' 'ok ``````````' 'ok """"""""""'; do printf ' Cellule@@Acceptation : %s\n' "$v"; done; }
gen_case CPRD-GEN-PONCTUATION-CRITERE "ponctuation seule ou en tête et en fin d'un texte trop court, mise en forme seule" crit-red cells_punct_crit
gen_case CPRD-GEN-PONCTUATION-BRIEF "ponctuation seule : une rubrique qui n'a que cela est vide" brief cells_punct_brief

# Titres de rubrique du BRIEF : variantes typographiques (trait d'union, espace, casse, accents, emphase, niveau) = la même rubrique.
TITRES_HP=('Hors-périmètre' 'Hors  périmètre' 'HORS PÉRIMÈTRE' 'hors perimetre' $'Hors\xe2\x80\x91périmètre' $'Hors\xe2\x80\x93périmètre' $'Hors\xe2\x80\x94périmètre' $'Hors\xe2\x88\x92périmètre' 'Hors_périmètre' '**Hors** périmètre' '_Hors périmètre_' '`Hors périmètre`' '~~Hors~~ périmètre' "Hors${NBSP}périmètre" 'Hors - périmètre' 'Hors périmètre :' 'Hors-Périmètre')
TITRES_AUTRES=('PROBLÈME' 'Probleme' 'Problématique' 'Utilisateurs cibles' 'UTILISATEUR' '**Valeur**' 'Valeur ajoutée' 'Contraintes techniques' 'CONTRAINTE')
# titre_brief <niveau> <rubrique 0-4> <titre> -> écrit $FX/titre.md (les quatre autres rubriques sont standard).
TITRE_N=0
titre_brief() { local lvl=$1 k=$2 t=$3 j; TITRE_N=$((TITRE_N+1))
  local -a HD=("Problème" "Utilisateurs" "Valeur" "Contraintes" "Hors périmètre")
  HD[$k]="$t"
  { printf '# Brief produit\n\n'; for j in 0 1 2 3 4; do printf '%s %s\nUn corps légitime de la rubrique.\n\n' "$lvl" "${HD[$j]}"; done; } > "$FX/titre-$TITRE_N.md"; reg "titre-$TITRE_N.md"; }
titres_probe() { local lvl=$1 k=$2 t; shift 2
  for t in "$@"; do
    titre_brief "$lvl" "$k" "$t"; run --brief "$FX/titre-$TITRE_N.md"
    msg "titre [$t] au niveau $lvl attendu rc 0 (même rubrique)"; [ "$RC" -eq 0 ] || return 1
  done; return 0; }
probe_titres_hp() { local l; for l in '#' '##' '###' '####'; do titres_probe "$l" 4 "${TITRES_HP[@]}" || return 1; done; }
probe_titres_autres() { local k; for k in 0 1 2 3; do
  case $k in 0) titres_probe '##' 0 'PROBLÈME' 'Probleme' 'Problématique' || return 1 ;; 1) titres_probe '##' 1 'Utilisateurs cibles' 'UTILISATEUR' || return 1 ;; 2) titres_probe '##' 2 '**Valeur**' 'Valeur ajoutée' || return 1 ;; 3) titres_probe '##' 3 'Contraintes techniques' 'CONTRAINTE' || return 1 ;; esac
  done; return 0; }
probe_titre_un() { titres_probe '##' 4 "$1"; }
probe_titre_tiret() { probe_titre_un 'Hors-périmètre'; }
probe_titre_souligne() { probe_titre_un 'Hors_périmètre'; }
probe_titre_etoile() { probe_titre_un '**Hors** périmètre'; }
probe_titre_code() { titres_probe '##' 4 'Hors `périmètre`' '`Hors` périmètre' '`Hors périmètre`'; }
probe_titre_tilde() { probe_titre_un '~~Hors~~ périmètre'; }
probe_titre_tiret_typo() { titres_probe '##' 4 $'Hors\xe2\x80\x91périmètre' $'Hors\xe2\x80\x93périmètre' $'Hors\xe2\x80\x94périmètre'; }
probe_titre_moins() { probe_titre_un $'Hors\xe2\x88\x92périmètre'; }
probe_titre_espaces() { probe_titre_un 'Hors  périmètre'; }
probe_titre_nbsp() { probe_titre_un "Hors${NBSP}périmètre"; }
probe_titre_casse() { probe_titre_un 'HORS PÉRIMÈTRE'; }
gen_titres() { local id=$1 desc=$2 probe=$3 n=$4
  if "$probe"; then GEN_TOT=$((GEN_TOT+n)); GEN_OK=$((GEN_OK+n)); PASS=$((PASS+n)); echo "  ✓ $id : $n cellules conformes ($desc)"
  else GEN_TOT=$((GEN_TOT+n)); ko "$id — $LASTMSG"; fi; }
gen_titres CPRD-GEN-TITRES-HORS-PERIMETRE "${#TITRES_HP[@]} graphies x 4 niveaux de titre" probe_titres_hp $(( ${#TITRES_HP[@]} * 4 ))
gen_titres CPRD-GEN-TITRES-AUTRES "variantes des quatre autres rubriques" probe_titres_autres 9

# Imbrication : le contenu sous un sous-titre plus profond appartient à la rubrique parente ; un titre de niveau égal
# ou inférieur la ferme.
probe_imbrication() {
  local d="# Brief\n\n## Problème\n%b\n## Utilisateurs\nLes clients.\n## Valeur\nMoins d appels.\n## Contraintes\nCoût borné.\n## Hors périmètre\nPas de paiement.\n"
  w imb1.md "$d" "### Contexte\nLe tarif est introuvable.\n### Enjeu\nPerte de temps."; run --brief "$FX/imb1.md"
  msg "corps uniquement sous des sous-titres ### attendu rc 0 (le contenu appartient à la rubrique parente)"; [ "$RC" -eq 0 ] || return 1
  w imb2.md "$d" "Le tarif est introuvable.\n#### Détail\nPerte de temps.\n##### Encore plus profond\nFin."; run --brief "$FX/imb2.md"
  msg "sous-titres #### et ##### attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  w imb3.md "$d" "### Contexte\n#### Détail\nLe tarif est introuvable."; run --brief "$FX/imb3.md"
  msg "corps uniquement sous ### puis #### attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  w imb4.md "$d" "# Autre titre\nLe tarif est introuvable."; run --brief "$FX/imb4.md"
  msg "un titre de niveau inférieur ferme la rubrique : attendu rc 1 + Problème vide"; { [ "$RC" -eq 1 ] && has "rubrique BRIEF probleme : vide"; } || return 1
  w imb5.md "$d" "## Autre titre\nLe tarif est introuvable."; run --brief "$FX/imb5.md"
  msg "un titre de même niveau ferme la rubrique : attendu rc 1 + Problème vide"; { [ "$RC" -eq 1 ] && has "rubrique BRIEF probleme : vide"; } || return 1
  w imb6.md "# Brief\n\n### Problème\nLe tarif.\n## Utilisateurs\nLes clients.\n#### Primaires\nLes abonnés.\n## Valeur\nMoins d appels.\n## Contraintes\nCoût borné.\n## Hors périmètre\nPas de paiement.\n"; run --brief "$FX/imb6.md"
  msg "rubrique ### suivie d'un ## : attendu rc 0"; [ "$RC" -eq 0 ]; }
case_ CPRD-IMBRICATION probe_imbrication

# Code en ligne : un `<!--` dans un span de code n'ouvre aucun commentaire ; une série d'accents graves non fermée reste littérale.
probe_code_commentaire() {
  local two='- [ ] **PRD-02**: Exporter la liste\n  Priorité : should\n'
  w cs1.md '# Exigences\n\n- [ ] **PRD-01**: Afficher\n  Acceptation : le bouton `<!--` ouvre un commentaire en HTML\n  Priorité : must\n'"$two"; run --requirements "$FX/cs1.md"
  msg "span de code contenant <!-- : PRD-02 attendu lu et éliminatoire (BILAN exigences=2, rc 1)"; { [ "$RC" -eq 1 ] && last | command grep -q 'BILAN exigences=2 sans_critere=1 '; } || return 1
  w cs2.md '# Exigences\n\n- [ ] **PRD-01**: Afficher\n  Acceptation : le bouton ``<!--`` ouvre un commentaire en HTML\n  Priorité : must\n'"$two"; run --requirements "$FX/cs2.md"
  msg "span à deux accents graves contenant <!-- : PRD-02 attendu lu (exigences=2)"; last | command grep -q 'BILAN exigences=2 sans_critere=1 ' || return 1
  w cs3.md '# Exigences\n\n- [ ] **PRD-01**: Afficher\n  Acceptation : le bouton ``a`<!--`` ouvre un commentaire en HTML\n  Priorité : must\n'"$two"; run --requirements "$FX/cs3.md"
  msg "span a deux accents graves enveloppant un accent grave et <!-- : PRD-02 attendu lu (exigences=2)"; last | command grep -q 'BILAN exigences=2 sans_critere=1 ' || return 1
  w cs4.md '# Exigences\n\n- [ ] **PRD-01**: Afficher\n  Acceptation : le bouton `<!-- ouvre un commentaire en HTML\n  Priorité : must\n'"$two"; run --requirements "$FX/cs4.md"
  msg "accent grave non fermé : le <!-- ouvre bien un commentaire, attendu INDETERMINE commentaire HTML non ferme"; has "INDETERMINE exigences : commentaire HTML non ferme" || return 1
  w cs5.md '# Exigences\n\n- [ ] **PRD-01**: Afficher\n  <!-- note `x --> Acceptation : le bouton est visible en 2 secondes\n  Priorité : must\n'; run --requirements "$FX/cs5.md"
  msg "commentaire réel contenant un accent grave isolé : retiré, critère de la fin de ligne lu (rc 0)"; [ "$RC" -eq 0 ] || return 1
  printf '## Problème\nLe bouton `<!--` ouvre.\n## Utilisateurs\nLes clients.\n## Valeur\nMoins d appels.\n## Contraintes\nCoût borné.\n## Hors périmètre\nPas de paiement.\n' > "$FX/cs6.md"; reg cs6.md; run --brief "$FX/cs6.md"
  msg "BRIEF : span de code contenant <!-- attendu rc 0 (rubriques suivantes lues)"; [ "$RC" -eq 0 ]; }
case_ CPRD-CODE-COMMENTAIRE probe_code_commentaire
# Le marqueur invisible posé dans un span ne doit jamais atteindre le décompte des caractères.
probe_code_marqueur() {
  crit_cells red mq < <(printf ' Cellule@@Acceptation : abcdefgh `<!--`\n'; printf ' Cellule@@Acceptation : abcdefgh `<!--` <!-- reste du commentaire\n'); }
case_ CPRD-CODE-MARQUEUR probe_code_marqueur

# Fichier à droits 000 : refus bruyant AVANT lecture, avec sa raison exacte (pas la raison du repli « taille »).
if [ "$(id -u)" -eq 0 ]; then
  skip "CPRD-ILLISIBLE-000 (exécuté en root : chmod 000 sans effet)"
else
  probe_illisible_000() {
    w ill.md '# Exigences\n\n%s\n' "$A1"; chmod 000 "$FX/ill.md"
    run --requirements "$FX/ill.md"
    msg "fichier chmod 000 attendu rc 5 + « fichier illisible »"; { [ "$RC" -eq 5 ] && has "ILLISIBLE exigences : fichier illisible"; }; local r=$?
    chmod 600 "$FX/ill.md"; return $r; }
  case_ CPRD-ILLISIBLE-000 probe_illisible_000
fi

# === Forme exec : aucune évaluation de chaîne, arguments séparés =====================================
probe_exec() {
  local n; n="$(awk '!/^[[:space:]]*#/ && /(^|[^A-Za-z_])eval([^A-Za-z_]|$)/{n++} END{print n+0}' "$SCRIPT")"
  LASTMSG="le script appelle une évaluation dynamique de chaîne ($n ligne(s))"; [ "$n" = 0 ] || return 1
  w "dossier avec espace/a b'c \$(touch pwned).md" '# Exigences\n\n%s\n' "$A1"
  run --requirements "$FX/dossier avec espace/a b'c \$(touch pwned).md"
  msg "chemin à espaces, apostrophe et substitution de commande attendu rc 0 sans exécution"
  [ "$RC" -eq 0 ] && [ ! -e "$TMP/cwd/pwned" ]; }
case_ CPRD-EXEC probe_exec

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
case_ CPRD-RO probe_ro
probe_codes() {
  LC_ALL=C sort -u "$TMP/rcs" > "$TMP/obs"; printf '0\n1\n3\n5\n64\n' > "$TMP/exp-codes"
  local manq extra
  manq="$(comm -13 "$TMP/obs" "$TMP/exp-codes" | tr '\n' ' ')"; extra="$(comm -23 "$TMP/obs" "$TMP/exp-codes" | tr '\n' ' ')"
  LASTMSG="codes manquants [$manq] en trop [$extra]"; [ -z "$manq" ] && [ -z "$extra" ]
}
case_ CPRD-CODES probe_codes

# === Mutants (QUAL-01) ===============================================================================
MUTDIR="$TMP/mut"; mkdir -p "$MUTDIR"
MUTBIN="$MUTDIR/check-prd.sh"

# mutant <id> <ligne repère> <ancien> <nouveau> <sonde> <description> : dans UNE ligne du script (celle qui
# contient le repère), remplace la première occurrence littérale de <ancien> par <nouveau> (chaînes passées par
# l'environnement : aucune séquence d'échappement interprétée ; MUT_NTH=n limite la mutation à la n-ième ligne qui
# porte le repère, pour deux lignes jumelles). La sonde doit échouer sur le mutant, réussir sur l'original.
mutant() {
  local id="$1" needle="$2" old="$3" new="$4" probe="$5" desc="$6"
  if ! declare -F "$probe" > /dev/null; then ko "$id sonde $probe NON DÉFINIE à cet endroit — $desc"; return; fi
  NEEDLE="$needle" OLD="$old" NEW="$new" NTH="${MUT_NTH:-0}" awk 'BEGIN { n = ENVIRON["NEEDLE"]; o = ENVIRON["OLD"]; w = ENVIRON["NEW"]; nth = ENVIRON["NTH"] + 0 }
    { if (index($0, n)) { seen++; if (nth == 0 || nth == seen) { i = index($0, o); if (i) $0 = substr($0, 1, i - 1) w substr($0, i + length(o)) } } print }' \
    "$SCRIPT" > "$MUTBIN"
  if cmp -s "$MUTBIN" "$SCRIPT"; then ko "$id mutant NON OPPOSABLE (copie identique à l'original) — $desc"; return; fi
  if ! bash -n "$MUTBIN" 2>/dev/null; then ko "$id mutant invalide (bash -n) — $desc"; return; fi
  local nl; nl="$(diff "$SCRIPT" "$MUTBIN" | command grep -c '^<')"
  if [ "$nl" != 1 ]; then ko "$id mutant mal ciblé ($nl lignes changées au lieu de 1) — $desc"; return; fi
  TARGET="$MUTBIN"; "$probe"; local mrc=$?; local mmsg="$LASTMSG"
  TARGET="$SCRIPT"; "$probe"; local orc=$?
  if [ "$mrc" -ne 0 ] && [ "$orc" -eq 0 ]; then
    ok "$id tué ($desc) — sur le mutant : $mmsg"
  elif [ "$mrc" -eq 0 ]; then
    ko "$id mutant SURVIVANT ($desc) — la sonde ${probe#probe_} reste verte sur le mutant"
  else
    ko "$id original rouge après mutation ($desc) — $LASTMSG"
  fi
  TARGET="$SCRIPT"
}

mutant CPRD-MUT-1 'if (!hascrit) {' '!hascrit' '0' probe_trace2 \
  "FAIL : branche « aucun critère » neutralisée"
mutant CPRD-MUT-2 'if (c == "[" || c == "<") return 1' 'c == "[" || c == "<"' '0' probe_gabarit \
  "FAIL : filtre de gabarit (crochet en tête) retiré"
mutant CPRD-MUT-3 'if [ "$NREQ" -eq 0 ]; then' '[ "$NREQ" -eq 0 ]' 'false' probe_trace3 \
  "INDÉTERMINÉ : zéro exigence rendu 0"
mutant CPRD-MUT-4 'if [ -L "$f" ]; then illisible' '[ -L "$f" ]' 'false' probe_lien \
  "BRUYANT : refus du lien symbolique retiré"
mutant CPRD-MUT-5 'n = split("probleme utilisateurs' ' hors_perimetre' '' probe_brief_sans_hp \
  "FAIL BRIEF : rubrique hors périmètre non exigée"
mutant CPRD-MUT-6 'close_block(); infence = 1' 'f3 == "```" || f3 == "~~~"' '0' probe_fence \
  "FAIL : bascule des blocs de code retirée"
mutant CPRD-MUT-7 '"$size" -gt "$PRD_MAX_OCTETS"' '"$PRD_MAX_OCTETS"' '99999999999' probe_gros \
  "BRUYANT : borne de taille retirée"
mutant CPRD-MUT-8 'low = tolower(s); off = 0' 'tolower(s)' 's' probe_champ \
  "PASS : champ du critère rendu sensible à la casse"

# --- revue-59 F4 : un mutant par comportement documenté (une ligne, un fragment retiré).
mutant CPRD-MUT-9 'n = split("todo|a venir"' 'todo|' '' probe_todo \
  "FAIL : TODO retiré de la liste des marqueurs de remplissage (exigence)"
mutant CPRD-MUT-10 'n = split("tbd|tba|fixme' 'tbd|' '' probe_tbd \
  "FAIL : TBD retiré de la liste des marqueurs de remplissage (exigence)"
mutant CPRD-MUT-11 'n = split("todo|a venir"' 'todo|' '' probe_brief_remplissage \
  "FAIL BRIEF : TODO retiré du filtre de remplissage"
mutant CPRD-MUT-12 'n = split("tbd|tba|fixme' 'tbd|' '' probe_brief_remplissage \
  "FAIL BRIEF : TBD retiré du filtre de remplissage"
mutant CPRD-MUT-13 'line ~ /^[ \t]*$/ || line ~ /^#/' 'line ~ /^[ \t]*$/ || ' '' probe_ferme_blanc \
  "FAIL : la ligne blanche ne ferme plus l'exigence"
mutant CPRD-MUT-14 'line ~ /^[ \t]*$/ || line ~ /^#/' ' || line ~ /^[ \t]*([-*+]|[0-9]+\.)[ \t]/' '' probe_sous_puce_suivie \
  "FAIL : la sous-puce ne ferme plus l'exigence"
mutant CPRD-MUT-15 'OUT_TXT=$(sed' 'sed "s/$CR\$//" "$1" | ' 'cat "$1" | ' probe_cr \
  "FAIL : retrait du CR final des fins de ligne CRLF retiré"
mutant CPRD-MUT-16 'n = split("tbd|tba|fixme' 'a preciser|' '' probe_remplissage \
  "FAIL : « à préciser » retiré de la liste des marqueurs"
mutant CPRD-MUT-17 'gsub(/é|É' 'gsub(/é|É|è|È|ê|Ê|ë|Ë/, "e", s)' 's = s' probe_remplissage \
  "FAIL : repli des accents (é, è, ê) retiré"
mutant CPRD-MUT-18 'gsub(/à|À' 'gsub(/à|À|â|Â/, "a", s)' 's = s' probe_remplissage \
  "FAIL : repli de « à » retiré"
mutant CPRD-MUT-19 'gsub(/\314[\200-\277]|\315[\200-\257]/, "", s)' 'gsub(/\314[\200-\277]|\315[\200-\257]/, "", s)' 's = s' probe_remplissage \
  "FAIL : marques combinantes non retirées (la repli porte aussi la forme décomposée)"
mutant CPRD-MUT-20 'gsub(/[\200-\277]/, "", s)' 'gsub(/[\200-\277]/, "", s)' 's = s' probe_longueur \
  "FAIL : la longueur se mesure de nouveau en octets"
mutant CPRD-MUT-21 'pre = line; line = strip_comments(line)' 'line = strip_comments(line)' 'line = line' probe_commentaire \
  "FAIL : commentaires HTML non retirés dans la passe exigences"
mutant CPRD-MUT-22 'if (line ~ /^[ \t]*$/ && (pre !~' '&& (pre !~ /^[ \t]*$/ || inc0)' '&& 0' probe_commentaire \
  "FAIL : un commentaire multi-ligne ferme l'exigence"
mutant CPRD-MUT-23 'if [ "$NFENCE" -ne 0 ]; then' '[ "$NFENCE" -ne 0 ]' 'false' probe_fence_ouverte \
  "INDÉTERMINÉ : bloc de code non fermé rendu 0"
mutant CPRD-MUT-24 'nunk++' 'nunk++' 'nxx++' probe_case_inconnue \
  "BILAN : cases non reconnues non comptées"
mutant CPRD-MUT-25 'if (nunk <= 50) printf' 'if (nunk <= 50)' 'if (0)' probe_case_inconnue \
  "AVERTISSEMENT : cases non reconnues non signalées"
mutant CPRD-MUT-26 "command grep -F 'AVERTISSEMENT ligne '" '>&2' '>/dev/null' probe_case_inconnue \
  "AVERTISSEMENT : copie sur stderr retirée"

# --- revue-59 (2e relecture) : un mutant par correctif, et les trois survivants de la relecture (F3 a, b, c).
mutant CPRD-MUT-27 'if [ "$NCOM" -ne 0 ]; then' '[ "$NCOM" -ne 0 ]' 'false' probe_com_ouvert \
  "INDÉTERMINÉ : commentaire HTML non fermé (exigences) rendu 0"
mutant CPRD-MUT-28 'if [ "$3" -ne 0 ]; then' '[ "$3" -ne 0 ]' 'false' probe_brief_ouvert \
  "INDÉTERMINÉ : bloc de code non fermé (BRIEF) rendu 0"
mutant CPRD-MUT-29 'if [ "$4" -ne 0 ]; then' '[ "$4" -ne 0 ]' 'false' probe_brief_ouvert \
  "INDÉTERMINÉ : commentaire HTML non fermé (BRIEF) rendu 0"
mutant CPRD-MUT-30 'if (isfill(t)) next' 'isfill(t)' 'substr(t, 1, 1) == "["' probe_brief_mentions \
  "FAIL BRIEF : détection de remplissage ramenée au seul crochet en tête (ancienne règle)"
mutant CPRD-MUT-31 'while (v != "" && match(v, /^([' '>+#~' '+#~' probe_brief_mentions \
  "FAIL BRIEF : citation « > » non retirée avant le test de remplissage"
mutant CPRD-MUT-32 'while (v != "" && match(v, /^([' '\t*_' '\t_' probe_marques \
  "FAIL : emphase « * » non retirée avant le test de remplissage"
mutant CPRD-MUT-33 'while (v != "" && match(v, /^([' '_`' '`' probe_marques \
  "FAIL : soulignés non retirés avant le test de remplissage"
mutant CPRD-MUT-34 'while (v != "" && match(v, /^([' '`"' '"' probe_marques \
  "FAIL : code en ligne non retiré avant le test de remplissage"
mutant CPRD-MUT-35 'while (v != "" && match(v, /^([' $'"\'>' $'\'>' probe_marques \
  "FAIL : guillemets droits non retirés avant le test de remplissage"
mutant CPRD-MUT-37 'n = split("tbd|tba|fixme' 'n/a|' '' probe_brief_mentions \
  "FAIL BRIEF : n/a retiré des marqueurs de remplissage"
mutant CPRD-MUT-38 'n = split("tbd|tba|fixme' 'fixme|' '' probe_brief_mentions \
  "FAIL BRIEF : FIXME retiré des marqueurs de remplissage"
mutant CPRD-MUT-39 'v = norm(v)' 'norm(v)' 'v' probe_brief_mentions \
  "FAIL : blancs Unicode et largeur nulle non normalisés avant le test de remplissage"
mutant CPRD-MUT-41 'if (wordbefore(pre)) return 0' 'wordbefore(pre)' '0' probe_champ \
  "PASS : champ d'acceptation de nouveau reconnu au fil d'une phrase (ancre retirée)"
mutant CPRD-MUT-42 'if (!match(rest, /^[ \t]*[*_]*[ \t]*:/)) return 0' '!match(rest, /^[ \t]*[*_]*[ \t]*:/)' '0' probe_champ \
  "PASS : deux-points du champ non exigés"
mutant CPRD-MUT-43 'low = tolower(s); off = 0' 's = norm(s);' 's = s;' probe_champ \
  "PASS : espace insécable avant les deux-points non toléré"
mutant CPRD-MUT-44 'if (match(pre, /crit[^ \t]*' '|\342\200\231)' ')' probe_ancre \
  "PASS : apostrophe typographique de « Critère d’acceptation » non reconnue"
mutant CPRD-MUT-45 'for (i = 1; i <= n; i++) if (isolated(t, W[i])) return 1' 'isolated(t, W[i])' 'hasword(t, W[i])' probe_mot_legitime \
  "PASS : todo / à venir de nouveau rouges au fil d'une phrase (faux rouge m1)"
mutant CPRD-MUT-46 'if (pre == "" || pre !~' 'pre == "" || pre !~ /[a-z0-9]$/ || ' '' probe_todo \
  "FAIL : marqueur faible en début de valeur plus reconnu"
mutant CPRD-MUT-47 'if (pre == "" || pre !~' ' || post == "" || post !~ /^[a-z0-9]/' '' probe_mot_legitime \
  "FAIL : marqueur faible en fin de valeur ou collé à une ponctuation plus reconnu"
mutant CPRD-MUT-48 'if (line ~ /^[ \t]*$/ && (pre !~' ' || inc0' '' probe_com_blanc \
  "FAIL : la ligne blanche d'un commentaire multi-ligne ferme l'exigence"
mutant CPRD-MUT-49 'if [ "$WORST" -ne 5 ]; then WORST=1; fi' 'if [ "$WORST" -ne 5 ]; then WORST=1; fi' 'WORST=1' probe_5_sur_1 \
  "ORDRE : 1 écrase 5 (priorité 5 > 1 perdue)"
mutant CPRD-MUT-50 'if (match(line, /^[ \t]*- \[[ xX]\] \*\*' '[ xX]' '[ ]' probe_cochee \
  "FAIL : exigence cochée [x] / [X] non reconnue"
mutant CPRD-MUT-51 'else if (index(lab, "hors p") == 1)' '"hors p"' '"hors"' probe_hors_sujet \
  "FAIL BRIEF : toute rubrique « Hors ... » prise pour Hors périmètre"

# --- Sondes des mutants (tour 2) : une sonde par normalisation de check-prd.sh, la trace nomme le cas fautif.
cells_onemark_crit() { local mk=$1 m; for m in "${MENT[@]}"; do printf ' Cellule@@Acceptation : %s%s %s\n' "$mk" "$m" "$GEN_FILL"; done; }
cells_onemark_brief() { local mk=$1 m; for m in "${MENT[@]}"; do printf '%s%s\n' "$mk" "$m"; done; }
mk_probe() { local mk
  for mk in "$@"; do
    crit_cells red mk < <(cells_onemark_crit "$mk") || { LASTMSG="marque [$mk] : $LASTMSG"; return 1; }
    brief_cells mk < <(cells_onemark_brief "$mk") || { LASTMSG="marque [$mk] : $LASTMSG"; return 1; }
  done; return 0; }
mk_probe_crit() { local mk
  for mk in "$@"; do crit_cells red mk < <(cells_onemark_crit "$mk") || { LASTMSG="marque [$mk] : $LASTMSG"; return 1; }; done; return 0; }
vals_crit() { local v; for v in "$@"; do printf ' Cellule@@Acceptation : %s %s\n' "$v" "$GEN_FILL"; done; }
vals_brief() { local v; for v in "$@"; do printf '%s\n' "$v"; done; }
vals_probe() { crit_cells red vp < <(vals_crit "$@") || return 1; brief_cells vp < <(vals_brief "$@"); }
chars_probe() { local kind=$1; shift
  crit_cells red cp < <(chars_cells_crit "$kind" "$@") || return 1; brief_cells cp < <(chars_cells_brief "$kind" "$@"); }
probe_mk_dash() { mk_probe '- ' '> - ' '- **'; }
probe_mk_plus() { mk_probe '+ '; }
probe_mk_tilde() { mk_probe '~ '; }
probe_mk_egal() { mk_probe '= '; }
probe_mk_barre() { mk_probe '| '; }
probe_mk_hash() { mk_probe_crit '# '; }
probe_mk_puce() { mk_probe $'\xe2\x80\xa2 ' $'\xe2\x80\xa2 _'; }
probe_mk_puce2() { mk_probe $'\xe2\x80\xa3 '; }
probe_mk_basdoubl() { mk_probe $'\xe2\x80\x9e'; }
probe_mk_demi() { mk_probe $'\xe2\x80\x93 '; }
probe_mk_cadr() { mk_probe $'\xe2\x80\x94 '; }
probe_mk_apos() { mk_probe $'\xe2\x80\x98'; }
probe_mk_guil() { mk_probe $'\xe2\x80\x9c'; }
probe_mk_point() { mk_probe $'\xc2\xb7 '; }
probe_mk_chev() { mk_probe $'\xc2\xab '; }
probe_mk_num1() { mk_probe '1. ' '12. ' '1. *'; }
probe_mk_num2() { mk_probe '1) '; }
probe_mk_rond() { mk_probe $'\xe2\x97\xa6 ' $'\xe2\x97\x8f '; }
probe_mk_carre() { mk_probe $'\xe2\x96\xaa '; }
probe_mk_oper() { mk_probe $'\xe2\x88\x99 '; }
probe_num_fin() { brief_cells nf < <(vals_brief '1.' '1)' '12.'); }
probe_pleine_chasse() { mk_probe ''; }
probe_inv_zw() { chars_probe inv $'\xe2\x80\x8b' $'\xe2\x80\x8c' $'\xe2\x80\x8d' $'\xe2\x80\x8e' $'\xe2\x80\x8f'; }
probe_inv_wj() { chars_probe inv $'\xe2\x81\xa0'; }
probe_inv_bom() { chars_probe inv $'\xef\xbb\xbf'; }
probe_inv_shy() { chars_probe inv $'\xc2\xad'; }
probe_inv_mvs() { chars_probe inv $'\xe1\xa0\x8e'; }
probe_blk_nbsp() { chars_probe blk "$NBSP"; }
probe_blk_fines() { chars_probe blk $'\xe2\x80\x80' $'\xe2\x80\x81' $'\xe2\x80\x82' $'\xe2\x80\x83' $'\xe2\x80\x84' $'\xe2\x80\x85' $'\xe2\x80\x86' $'\xe2\x80\x87' $'\xe2\x80\x88' $'\xe2\x80\x89' $'\xe2\x80\x8a'; }
probe_blk_sep() { chars_probe blk $'\xe2\x80\xa8' $'\xe2\x80\xa9'; }
probe_blk_nnbsp() { chars_probe blk $'\xe2\x80\xaf'; }
probe_blk_mmsp() { chars_probe blk $'\xe2\x81\x9f'; }
probe_blk_ideo() { chars_probe blk $'\xe3\x80\x80'; }
probe_blk_ogham() { chars_probe blk $'\xe1\x9a\x80'; }
probe_comb() { crit_cells red comb1 < <(cells_comb_red) || return 1; crit_cells green comb2 < <(cells_comb_green); }
probe_comb_espaces() { crit_cells red nsp < <(printf ' Cellule@@Acceptation : a b c d e f g h i\n'); }
probe_fold_i() { vals_probe 'à définîr' 'à définïr'; }
probe_fold_o() { vals_probe 'à cômpléter'; }
probe_fold_c() { vals_probe 'à préçiser'; }
probe_fold_a_up() { vals_probe 'À définir'; }
probe_fold_a_circ() { vals_probe 'â définir'; }
probe_fold_e_up() { vals_probe 'à DÉFINIR'; }
probe_fold_e_grave() { vals_probe 'à décidèr'; }
probe_fold_e_circ() { vals_probe 'à décidêr'; }
probe_fold_e_trema() { vals_probe 'à décidër'; }
probe_fold_tolower() { vals_probe 'TBD' 'FIXME' 'N/A' 'TODO'; }
probe_mot() { crit_cells red mot < <(cells_mot); }

# --- 3e relecture (tour 2) : un mutant par normalisation (lead, norm, nchars, fold, BOM, CR, strip_comments) et par
# classe de l'ancre « mot précédé d'un mot ». Le dernier argument de MUT_NTH ne sert qu'aux lignes jumelles (BOM).
LEADN='while (v != "" && match(v, /^(['
mutant CPRD-MUT-52 "$LEADN" '=|-]' '=|]' probe_mk_dash "FAIL : tiret de puce - non retiré en tête"
mutant CPRD-MUT-53 "$LEADN" '>+#~' '>#~' probe_mk_plus "FAIL : puce + non retirée en tête"
mutant CPRD-MUT-54 "$LEADN" '+#~=|' '+#=|' probe_mk_tilde "FAIL : marque ~ non retirée en tête"
mutant CPRD-MUT-55 "$LEADN" '~=|' '~|' probe_mk_egal "FAIL : marque = non retirée en tête"
mutant CPRD-MUT-56 "$LEADN" '=|-]' '=-]' probe_mk_barre "FAIL : marque | non retirée en tête"
mutant CPRD-MUT-57 "$LEADN" '>+#~' '>+~' probe_mk_hash "FAIL : marque # non retirée en tête"
mutant CPRD-MUT-58 "$LEADN" '\236\242\243' '\236\243' probe_mk_puce "FAIL : puce • non retirée en tête"
mutant CPRD-MUT-59 "$LEADN" '\236\242\243' '\236\242' probe_mk_puce2 "FAIL : puce ‣ non retirée en tête"
mutant CPRD-MUT-60 "$LEADN" '\234\236\242' '\234\242' probe_mk_basdoubl "FAIL : guillemet „ non retiré en tête"
mutant CPRD-MUT-61 "$LEADN" '[\223\224\230' '[\224\230' probe_mk_demi "FAIL : tiret demi-cadratin – non retiré en tête"
mutant CPRD-MUT-62 "$LEADN" '\223\224\230' '\223\230' probe_mk_cadr "FAIL : tiret cadratin — non retiré en tête"
mutant CPRD-MUT-63 "$LEADN" '\224\230\234' '\224\234' probe_mk_apos "FAIL : guillemet ‘ non retiré en tête"
mutant CPRD-MUT-64 "$LEADN" '\230\234\236' '\230\236' probe_mk_guil "FAIL : guillemet “ non retiré en tête"
mutant CPRD-MUT-65 "$LEADN" '\302[\253\267]' '\302[\253]' probe_mk_point "FAIL : point médian · non retiré en tête"
mutant CPRD-MUT-66 "$LEADN" '\302[\253\267]' '\302[\267]' probe_mk_chev "FAIL : guillemet « non retiré en tête"
mutant CPRD-MUT-67 "$LEADN" '[0-9]+[.)]' '[0-9]+[)]' probe_mk_num1 "FAIL : puce numérotée 1. non retirée en tête"
mutant CPRD-MUT-68 "$LEADN" '[0-9]+[.)]' '[0-9]+[.]' probe_mk_num2 "FAIL : puce numérotée 1) non retirée en tête"
mutant CPRD-MUT-69 "$LEADN" '([ \t]|$)' '([ \t])' probe_num_fin "FAIL : puce numérotée seule sur la ligne non retirée"
mutant CPRD-MUT-70 "$LEADN" '\342\227[\246\217]|' '' probe_mk_rond "FAIL : puces ◦ et ● non retirées en tête"
mutant CPRD-MUT-71 "$LEADN" '|\342\226\252' '' probe_mk_carre "FAIL : puce ▪ non retirée en tête"
mutant CPRD-MUT-72 "$LEADN" '|\342\210\231' '' probe_mk_oper "FAIL : puce ∙ non retirée en tête"
FULLN='if (v ~ /^(\357\274['
mutant CPRD-MUT-73 "$FULLN" '\357\274[\273\234]|' '' probe_pleine_chasse "FAIL : crochet et chevron pleine chasse ［ ＜ non reconnus"
mutant CPRD-MUT-74 "$FULLN" '|\343\200\210' '' probe_pleine_chasse "FAIL : chevron 〈 non reconnu"
mutant CPRD-MUT-75 "$FULLN" '|\342\237\250' '' probe_pleine_chasse "FAIL : chevron ⟨ non reconnu"
NORM1='\342\201\240|\357\273\277'
mutant CPRD-MUT-76 "$NORM1" '\342\200[\213-\217]|' '' probe_inv_zw "FAIL : largeur nulle U+200B..U+200F non retirée"
mutant CPRD-MUT-77 "$NORM1" '|\342\201\240' '' probe_inv_wj "FAIL : U+2060 non retiré"
mutant CPRD-MUT-78 "$NORM1" '|\357\273\277' '' probe_inv_bom "FAIL : U+FEFF non retiré hors tête de fichier"
mutant CPRD-MUT-79 "$NORM1" '|\302\255' '' probe_inv_shy "FAIL : U+00AD non retiré"
mutant CPRD-MUT-80 "$NORM1" '|\341\240\216' '' probe_inv_mvs "FAIL : U+180E non retiré"
NORM2='\302\240|\342\200[\200-\212]'
mutant CPRD-MUT-81 "$NORM2" '\302\240|' '' probe_blk_nbsp "FAIL : U+00A0 non ramenée à l espace"
mutant CPRD-MUT-82 "$NORM2" '\342\200[\200-\212]|' '' probe_blk_fines "FAIL : blancs U+2000..U+200A non ramenés à l espace"
mutant CPRD-MUT-83 "$NORM2" '|\342\200[\250\251]' '' probe_blk_sep "FAIL : U+2028 et U+2029 non ramenées à l espace"
mutant CPRD-MUT-84 "$NORM2" '|\342\200\257' '' probe_blk_nnbsp "FAIL : U+202F non ramenée à l espace"
mutant CPRD-MUT-85 "$NORM2" '|\342\201\237' '' probe_blk_mmsp "FAIL : U+205F non ramenée à l espace"
mutant CPRD-MUT-86 "$NORM2" '|\343\200\200' '' probe_blk_ideo "FAIL : U+3000 non ramenée à l espace"
mutant CPRD-MUT-87 "$NORM2" '|\341\232\200' '' probe_blk_ogham "FAIL : U+1680 non ramenée à l espace"
NCH='gsub(/\314[\200-\277]/, "", s); gsub('
mutant CPRD-MUT-88 "$NCH" 'gsub(/\314[\200-\277]/, "", s); ' '' probe_comb "FAIL : marques combinantes U+0300 non retirées du décompte"
mutant CPRD-MUT-89 "$NCH" '; gsub(/\315[\200-\257]/, "", s)' '' probe_comb "FAIL : marques combinantes U+0340 non retirées du décompte"
mutant CPRD-MUT-90 'gsub(/[ \t]/, "", s)' '[ \t]' '[\t]' probe_comb_espaces "FAIL : espaces comptés comme des caractères"
FOLDN='gsub(/î|Î|ï|Ï/'
mutant CPRD-MUT-91 "$FOLDN" 'gsub(/î|Î|ï|Ï/, "i", s); ' '' probe_fold_i "FAIL : î ï non repliés"
mutant CPRD-MUT-92 "$FOLDN" 'gsub(/ô|Ô/, "o", s); ' '' probe_fold_o "FAIL : ô non replié"
mutant CPRD-MUT-93 "$FOLDN" 'gsub(/ç|Ç/, "c", s)' '' probe_fold_c "FAIL : ç non replié"
mutant CPRD-MUT-94 'gsub(/à|À|â|Â/' 'à|À|' 'à|' probe_fold_a_up "FAIL : À majuscule non repliée"
mutant CPRD-MUT-95 'gsub(/à|À|â|Â/' '|â|Â' '' probe_fold_a_circ "FAIL : â non replié"
mutant CPRD-MUT-96 'gsub(/é|É|è' 'é|É|' 'é|' probe_fold_e_up "FAIL : É majuscule non repliée"
mutant CPRD-MUT-97 'gsub(/é|É|è' '|è|È' '' probe_fold_e_grave "FAIL : è non replié"
mutant CPRD-MUT-98 'gsub(/é|É|è' '|ê|Ê' '' probe_fold_e_circ "FAIL : ê non replié"
mutant CPRD-MUT-99 'gsub(/é|É|è' '|ë|Ë' '' probe_fold_e_trema "FAIL : ë non replié"
mutant CPRD-MUT-100 's = tolower(s)' 's = tolower(s)' 's = s' probe_fold_tolower "FAIL : minuscules non ramenées avant la comparaison"
mutant CPRD-MUT-101 'OUT_TXT=$(sed' " | tr '\\r' '\\n'" '' probe_cr "FAIL : CR seul non traité comme fin de ligne"
MUT_NTH=1 mutant CPRD-MUT-102 'substr(line, 1, 3) == bom' '== bom) line = substr(line, 4)' '== bom) line = line' probe_bom_req "FAIL : BOM non retiré en tête des exigences"
MUT_NTH=2 mutant CPRD-MUT-103 'substr(line, 1, 3) == bom' '== bom) line = substr(line, 4)' '== bom) line = line' probe_bom_brief "FAIL : BOM non retiré en tête du BRIEF"
mutant CPRD-MUT-104 'if (!b) return ""' 'if (!b) return ""' 'if (0) return ""' probe_com_contenu "FAIL : contenu d un commentaire multi-ligne lu comme du texte"
mutant CPRD-MUT-105 's = substr(s, b + 3); incom = 0' 'b + 3' 'b + 4' probe_com_contenu "FAIL : fin de commentaire multi-ligne mal découpée"
mutant CPRD-MUT-106 'substr(s, a + b + 6)' 'a + b + 6' 'a + b + 7' probe_com_contenu "FAIL : fin de commentaire sur une ligne mal découpée"
mutant CPRD-MUT-107 'if (!b) { incom = 1;' 'incom = 1' 'incom = 0' probe_com_ouvert "INDÉTERMINÉ : commentaire non fermé non signalé (état incom perdu)"
WORDN='return (p ~ /([A-Za-z0-9]|'
mutant CPRD-MUT-108 "$WORDN" '[A-Za-z0-9]' '[A-Za-z]' probe_mot "FAIL : chiffre avant le mot pris pour une ponctuation"
mutant CPRD-MUT-109 "$WORDN" '|\303[\200-\226\230-\266\270-\277]' '' probe_mot "FAIL : lettre Latin-1 avant le mot prise pour une ponctuation"
mutant CPRD-MUT-110 "$WORDN" '|[\304-\311][\200-\277]' '' probe_mot "FAIL : lettre Latin étendu avant le mot prise pour une ponctuation"
mutant CPRD-MUT-111 "$WORDN" '|[\316-\321][\200-\277]' '' probe_mot "FAIL : lettre grecque ou cyrillique avant le mot prise pour une ponctuation"
mutant CPRD-MUT-112 "$WORDN" '|(\314|\315)[\200-\277]' '' probe_mot "FAIL : marque combinante avant le mot prise pour une ponctuation"
mutant CPRD-MUT-113 "$WORDN" "('|\\342\\200\\231)?" '(\342\200\231)?' probe_mot "FAIL : apostrophe droite collée au mot précédent non reconnue"
mutant CPRD-MUT-114 "$WORDN" "('|\\342\\200\\231)?" "(')?" probe_mot "FAIL : apostrophe typographique collée au mot précédent non reconnue"
mutant CPRD-MUT-115 'sub(/[ \t]+$/, "", p)' '[ \t]+$' '[\t]+$' probe_mot "FAIL : blanc entre le mot précédent et acceptation non retiré"
mutant CPRD-MUT-116 'if (match(pre, /crit[^ \t]*' "d('|\\342\\200\\231)" '(\342\200\231)' probe_ancre "PASS : apostrophe droite de Critère d acceptation non reconnue"

# --- 4e relecture (tour 3) : un mutant par retrait de la normalisation en ligne, par règle de champ, par étape du
# masquage des spans de code et par règle de titre. Chaque sonde nomme la cellule fautive (cas, attendu, obtenu).
env_probe() { local rc=0 ch=$1; ENVSEL="$(envs_with "$ch")"
  crit_cells red e3r < <(env_red petit | to_crit) || rc=1
  if [ "$rc" -eq 0 ]; then brief_grp e3b < <(env_red petit) || rc=1; fi
  if [ "$rc" -eq 0 ]; then crit_cells green e3g < <(env_green | to_crit) || rc=1; fi
  if [ "$rc" -eq 0 ]; then BMODE=green brief_cells e3h < <(env_green); rc=$?; BMODE=red; fi
  ENVSEL=""; [ "$rc" -eq 0 ] || LASTMSG="enveloppe [$ch] : $LASTMSG"; return "$rc"; }
probe_env_etoile() { env_probe '*'; }
probe_env_souligne() { env_probe '_'; }
probe_env_code() { env_probe '`'; }
probe_env_guillemet() { env_probe '"'; }
probe_env_tilde() { env_probe '~'; }
probe_env_apostrophe() { env_probe "'"; }
probe_env_chevron() { env_probe $'«'; }
probe_env_courbe() { env_probe $'\xe2\x80\x9c'; }
vals_crit_only() { local v; for v in "$@"; do printf ' Cellule@@Acceptation : %s\n' "$v"; done; }
probe_trim_tete() { crit_cells red tt < <(vals_crit_only '!!! abcdefg' '))) abcdefg' ';;; abcdefg' '??? abcdefg'); }
probe_trim_fin() { crit_cells red tf < <(vals_crit_only 'abcdefg !!!' 'abcdefg ???' 'abcdefg ;;;' 'abcdefg((('); }
probe_pointfixe() { crit_cells red pf < <(vals_crit_only '**1.** abcdefghi' '> **2)** abcdefghi' '- **3.** abcdefghi'); }
probe_souligne_interne() { local v='le champ tbd_label est exporté en 2 secondes'
  crit_cells green si < <(vals_crit_only "$v") || return 1; BMODE=green brief_cells si < <(printf '%s\n' "$v"); local r=$?; BMODE=red; return $r; }
probe_collapse() { crit_cells red co < <(vals_crit '_à_ _définir_' '**à** **définir**' 'à  définir' $'à\t définir' 'à _définir_'); }
probe_ponct_brief() { brief_cells pb < <(printf '%s\n' "${PUNCT[@]}"); }
probe_nchars_plain() { crit_cells red np < <(vals_crit_only 'ok **********' 'ok __________' 'ok ~~~~~~~~~~' 'ok ``````````' 'ok """"""""""'); }
cells_field_small() { local v n
  for v in '' ' ;' ' —' ' .'; do for n in "${FNEXTS_SM[@]}"; do
    printf ' Texte — Acceptation :%s%s@@\n' "$v" "$n"; printf ' Texte@@Acceptation :%s%s\n' "$v" "$n"; done; done; }
probe_champ_suivant() { crit_cells red cs < <(cells_field_small); }
probe_champ_double() { crit_cells red cd < <(printf " Texte — Acceptation : Acceptation :@@\n Texte — Acceptation : Critère d'acceptation :@@\n Texte@@Acceptation : Acceptation :\n Texte — Acceptation : Acceptation : [x]@@\n Texte@@Acceptation : Acceptation : [x]\n"); }
probe_champ_phrase() { crit_cells green cp < <(printf ' Texte — Acceptation : le tarif de priorité : haute reste visible en 2 s@@\n Texte@@Acceptation : le tarif de priorité : haute reste visible en 2 s\n'); }
probe_ellipse_milieu() { vals_probe $'Le tarif … est affiché' $'l\'export … fonctionne' $'en … secondes'; }

mutant CPRD-MUT-36 'if (index(v, "...") || index(v, ell)) return 1' ' || index(v, ell)' '' probe_ellipse_milieu \
  "FAIL BRIEF : points de suspension typographiques non reconnus"
mutant CPRD-MUT-117 'gsub(/[*_`"~'"'"']|' '[*_`"~' '[_`"~' probe_env_etoile "FAIL : emphase * non retirée autour des mots (mise en forme en ligne)"
mutant CPRD-MUT-118 'gsub(/[*_`"~'"'"']|' '[*_`"~' '[*`"~' probe_env_souligne "FAIL : emphase _ non retirée autour des mots"
mutant CPRD-MUT-119 'gsub(/[*_`"~'"'"']|' '_`"~' '_"~' probe_env_code "FAIL : code en ligne non retiré autour des mots"
mutant CPRD-MUT-120 'gsub(/[*_`"~'"'"']|' '`"~' '`~' probe_env_guillemet "FAIL : guillemets droits non retirés autour des mots"
mutant CPRD-MUT-121 'gsub(/[*_`"~'"'"']|' '"~' '"' probe_env_tilde "FAIL : ~~ barré non retiré autour des mots"
mutant CPRD-MUT-122 'gsub(/[*_`"~'"'"']|' "~']" '~]' probe_env_apostrophe "FAIL : apostrophe droite en guise de guillemet non retirée"
mutant CPRD-MUT-123 'gsub(/[*_`"~'"'"']|' '|\302[\253\273]' '' probe_env_chevron "FAIL : chevrons « » non retirés autour des mots"
mutant CPRD-MUT-124 'gsub(/[*_`"~'"'"']|' '|\342\200[\230-\237]' '' probe_env_courbe "FAIL : guillemets courbes non retirés autour des mots"
mutant CPRD-MUT-125 'sub(/^([] ' '.,;:!?(){}[<>|=#+\/-]' '\t]' probe_trim_tete "FAIL : ponctuation de tête non retirée avant le décompte"
mutant CPRD-MUT-126 'sub(/([] ' '.,;:!?(){}[<>|=#+\/-]' '\t]' probe_trim_fin "FAIL : ponctuation de fin non retirée avant le décompte"
mutant CPRD-MUT-127 'for (k = 0; k < 8; k++)' 'k < 8' 'k < 1' probe_pointfixe "FAIL : normalisation à un seul passage (le retrait suivant n'est pas découvert)"
mutant CPRD-MUT-128 'v = protect_us(v)' 'protect_us(v)' 'v' probe_souligne_interne "PASS : _ interne d'un identifiant pris pour de l'emphase (faux rouge tbd_label)"
mutant CPRD-MUT-129 'gsub(/[ \t]+/, " ", v)' '[ \t]+' '[\t]+' probe_collapse "FAIL : blancs multiples entre deux mots d'un marqueur non repliés"
mutant CPRD-MUT-130 'if (p == "") return 1' 'p == ""' '0' probe_ponct_brief "FAIL BRIEF : ponctuation seule prise pour un corps"
mutant CPRD-MUT-131 'if (nchars(plain(v)) < 10) return 0' 'plain(v)' 'v' probe_nchars_plain "FAIL : décompte sur la valeur brute (mise en forme de fin comptée)"
mutant CPRD-MUT-132 'usable(fieldcut(substr(s, lend)))' 'fieldcut(substr(s, lend))' 'substr(s, lend)' probe_champ_suivant "FAIL : la valeur d'un champ ne s'arrête plus au champ suivant"
mutant CPRD-MUT-133 '/priorit(e|' '|\303[\210-\212\250-\252]' '' probe_champ_suivant "FAIL : Priorité accentuée non reconnue comme champ suivant"
mutant CPRD-MUT-134 '/priorit(e|' '|e\314[\200-\277]' '' probe_champ_suivant "FAIL : Priorité décomposée (e + U+0301) non reconnue comme champ suivant"
mutant CPRD-MUT-135 'if (acclabel(low, v, q)) { cut = lstart; break }' 'acclabel(low, v, q)' '0' probe_champ_double "FAIL : une seconde Acceptation ne borne plus la valeur de la première"
mutant CPRD-MUT-136 'if (!wordbefore(substr(low, 1, p - 1)))' '!wordbefore(substr(low, 1, p - 1))' '1' probe_champ_phrase "PASS : « de priorité : » au fil d'une phrase pris pour un champ"
mutant CPRD-MUT-139 'if (index(s, "`") && index(s, "<!--")) s = neutral(s)' 's = neutral(s)' 's = s' probe_code_commentaire "FAIL : un <!-- dans un span de code ouvre un commentaire"
mutant CPRD-MUT-140 'gsub(/<!--/, "<\004!--", P[i])' '"<\004!--"' '"<!--"' probe_code_commentaire "FAIL : le <!-- d'un span n'est pas neutralisé"
mutant CPRD-MUT-141 'NX[r] = (K[r] in LAST)' '(K[r] in LAST) ? LAST[K[r]] : 0' '(r < nr) ? r + 1 : 0' probe_code_commentaire "FAIL : une série d'accents graves se ferme sur n'importe quelle série"
mutant CPRD-MUT-142 'while (i + k < n && P[i + k] == "") k++' 'i + k < n &&' '0 &&' probe_code_commentaire "FAIL : les accents graves consécutifs ne forment plus une série"
mutant CPRD-MUT-143 'for (i = A[r] + K[r]; i <= A[c]; i++)' 'i <= A[c]' 'i < A[c]' probe_code_commentaire "FAIL : dernier morceau du span non neutralisé"
mutant CPRD-MUT-144 'for (i = A[r] + K[r]; i <= A[c]; i++)' 'A[r] + K[r];' 'A[r] + K[r] + 1;' probe_code_commentaire "FAIL : premier morceau du span non neutralisé"
mutant CPRD-MUT-145 'if (!b) { incom = 1; s = substr(s, 1, a - 1); gsub(' 'gsub(/\004/, "", s); return s' 'return s' probe_code_marqueur "FAIL : marqueur invisible conservé quand un commentaire s'ouvre sur la ligne"
mutant CPRD-MUT-146 '  gsub(/\004/, "", s)' 'gsub(/\004/, "", s)' 's = s' probe_code_marqueur "FAIL : marqueur invisible conservé en fin de ligne"
mutant CPRD-MUT-147 'gsub(/[*_`~-]|' '~-]' '~]' probe_titre_tiret "FAIL BRIEF : trait d'union d'un titre non lu comme espace"
mutant CPRD-MUT-148 'gsub(/[*_`~-]|' '[*_`' '[*`' probe_titre_souligne "FAIL BRIEF : souligné d'un titre non lu comme espace"
mutant CPRD-MUT-149 'gsub(/[*_`~-]|' '[*_' '[_' probe_titre_etoile "FAIL BRIEF : emphase * d'un titre non retirée"
mutant CPRD-MUT-150 'gsub(/[*_`~-]|' '_`~' '_~' probe_titre_code "FAIL BRIEF : code en ligne d'un titre non retiré"
mutant CPRD-MUT-151 'gsub(/[*_`~-]|' '`~-' '`-' probe_titre_tilde "FAIL BRIEF : ~~ d'un titre non retiré"
mutant CPRD-MUT-152 'gsub(/[*_`~-]|' '|\342\200[\220-\225]' '' probe_titre_tiret_typo "FAIL BRIEF : traits d'union typographiques d'un titre non lus comme espace"
mutant CPRD-MUT-153 'gsub(/[*_`~-]|' '|\342\210\222' '' probe_titre_moins "FAIL BRIEF : signe moins d'un titre non lu comme espace"
mutant CPRD-MUT-154 'gsub(/[ \t]+/, " ", lab)' '[ \t]+' '[\t]+' probe_titre_espaces "FAIL BRIEF : espaces multiples d'un titre non repliés"
mutant CPRD-MUT-155 'lab = fold(norm(' 'norm(substr(line, lvl + 1))' 'substr(line, lvl + 1)' probe_titre_nbsp "FAIL BRIEF : espace insécable d'un titre non normalisée"
mutant CPRD-MUT-156 'lab = fold(norm(' 'fold(norm(' '(norm(' probe_titre_casse "FAIL BRIEF : casse du titre non repliée"
mutant CPRD-MUT-157 'if (cur == "" || lvl <= curlvl) {' 'cur == "" || lvl <= curlvl' '1' probe_imbrication "FAIL BRIEF : un sous-titre plus profond ferme la rubrique parente"
mutant CPRD-MUT-158 'if (cur == "" || lvl <= curlvl) {' 'lvl <= curlvl' 'lvl < curlvl' probe_imbrication "FAIL BRIEF : un titre de même niveau ne ferme plus la rubrique"
if [ "$(id -u)" -ne 0 ]; then
  mutant CPRD-MUT-159 'if [ ! -r "$f" ]; then illisible' '[ ! -r "$f" ]' 'false' probe_illisible_000 "BRUYANT : refus du fichier illisible (droits 000) retiré, la raison exacte se perd"
else
  skip "CPRD-MUT-159 (exécuté en root : chmod 000 sans effet)"
fi

# === Correctifs du mandat du 2026-10-29 (arbitrage Samuel, AskUserQuestion session principale, 2026-10-29) ==========
# Case non reconnue = INDÉTERMINÉ (3), cédant devant 1 et 5 ; séparateurs avant le champ ; libellé répété ; gabarits
# livrés sans crochets ; puces numérotées en tête. Un mutant par comportement ajouté.
probe_unk_priorite() {
  w unk3.md '# Exigences\n\n%s\n* [ ] **PRD-02**: puce étoile\n' "$A1"
  run --requirements "$FX/unk3.md"
  msg "une seule case non reconnue (puce *) attendu rc 3 + INDETERMINE, jamais rc 0"
  { [ "$RC" -eq 3 ] && has 'INDETERMINE exigences : case a cocher non reconnue'; } || return 1
  w unk1.md "# Exigences\n\n%s\n$NOCRIT\n1. [ ] **PRD-04**: numérotée\n" "$A1"
  run --requirements "$FX/unk1.md"
  msg "case non reconnue + exigence sans critère attendu rc 1 (1 l'emporte sur 3)"; [ "$RC" -eq 1 ] || return 1
  ln -s "$FX/unk3.md" "$FX/unk-lien.md"
  run --requirements "$FX/unk3.md" --brief "$FX/unk-lien.md"
  msg "case non reconnue + BRIEF en lien symbolique attendu rc 5 (5 l'emporte sur 3)"; [ "$RC" -eq 5 ] || return 1
  w unk4.md '# Exigences\n\n%s\n* [ ] **PRD-02**:\n- [ ] **prd-05**: a\n1. [ ] **PRD-04**: b\n' "$A1"
  run --requirements "$FX/unk4.md"
  msg "les trois formes du mandat (puce *, ID en minuscules, numérotée) attendu rc 3 + non_reconnues=3"
  [ "$RC" -eq 3 ] && last | command grep -q 'non_reconnues=3 code=3'; }
sep_req() { w "$1" '# Exigences\n\n- [ ] **PRD-01**: Afficher le total. Priorité : must%sAcceptation : le total est affiché\n' "$2"; }
probe_separateurs() {
  local n=0 sp
  for sp in ', ' ' — ' ' – ' ' - ' ' (' ','; do
    n=$((n+1)); sep_req "sep$n.md" "$sp"; run --requirements "$FX/sep$n.md"
    msg "séparateur [$sp] avant « Acceptation : » attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  done
  return 0; }
probe_separateur_virgule() { sep_req sepv.md ', '; run --requirements "$FX/sepv.md"; msg "virgule avant le champ attendu rc 0"; [ "$RC" -eq 0 ]; }
probe_separateur_paren() { sep_req sepp.md ' ('; run --requirements "$FX/sepp.md"; msg "parenthèse avant le champ attendu rc 0"; [ "$RC" -eq 0 ]; }
probe_separateur_tiret() { sep_req sept.md ' - '; run --requirements "$FX/sept.md"; msg "tiret entouré d'espaces avant le champ attendu rc 0"; [ "$RC" -eq 0 ]; }
probe_separateur_cadratin() { sep_req sepc.md ' — '; run --requirements "$FX/sepc.md"; msg "tiret cadratin avant le champ attendu rc 0"; [ "$RC" -eq 0 ] || return 1
  sep_req sepd.md ' – '; run --requirements "$FX/sepd.md"; msg "tiret demi-cadratin avant le champ attendu rc 0"; [ "$RC" -eq 0 ]; }
probe_separateur_phrase() {
  w sf1.md '# Exigences\n\n- [ ] **PRD-01**: Il faut, acceptation :\n  Priorité : must\n'
  run --requirements "$FX/sf1.md"
  msg "« il faut, acceptation : » au fil d'une phrase, sans valeur, attendu rc 1 (jamais un faux vert)"; [ "$RC" -eq 1 ] || return 1
  w sf2.md '# Exigences\n\n- [ ] **PRD-01**: Il faut, acceptation : ok vite\n  Priorité : must\n'
  run --requirements "$FX/sf2.md"
  msg "« il faut, acceptation : ok vite » (valeur courte) attendu rc 1"; [ "$RC" -eq 1 ]; }
probe_tiret_colle() {
  w tc.md '# Exigences\n\n- [ ] **PRD-01**: Afficher le total pré-acceptation : le total est affiché\n  Priorité : must\n'
  run --requirements "$FX/tc.md"
  msg "tiret COLLÉ à un mot (pré-acceptation :) attendu rc 1 : mot composé, pas un champ"; [ "$RC" -eq 1 ]; }
probe_libelle_repete() {
  req1 lr1.md "Acceptation : Acceptation"; run --requirements "$FX/lr1.md"
  msg "valeur qui répète le libellé attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  req1 lr2.md "Acceptation : Critère d'acceptation"; run --requirements "$FX/lr2.md"
  msg "valeur « Critère d'acceptation » attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  req1 lr3.md "Acceptation : Critère d’acceptation"; run --requirements "$FX/lr3.md"
  msg "valeur « Critère d’acceptation » (apostrophe typographique) attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  req1 lr4.md "Critère d'acceptation : Critère d'acceptation"; run --requirements "$FX/lr4.md"
  msg "libellé long répété attendu rc 1"; [ "$RC" -eq 1 ] || return 1
  req1 lr5.md "Acceptation : Acceptation du tarif par le client en moins de 5 secondes"; run --requirements "$FX/lr5.md"
  msg "valeur légitime qui COMMENCE par le mot attendu rc 0"; [ "$RC" -eq 0 ]; }
probe_libelle_repete_nu() {
  req1 lr1.md "Acceptation : Acceptation"; run --requirements "$FX/lr1.md"
  msg "valeur « Acceptation » seule attendu rc 1"; [ "$RC" -eq 1 ]; }
probe_libelle_repete_long() {
  req1 lr2.md "Acceptation : Critère d'acceptation"; run --requirements "$FX/lr2.md"
  msg "valeur « Critère d'acceptation » seule attendu rc 1"; [ "$RC" -eq 1 ]; }
probe_puces_numerotees() {
  local v n=0
  for v in '1. [décrire le problème ici]' '12) <décrire le problème>' $'– [décrire le problème ici]' $'· [décrire le problème ici]' $'2. · – [décrire]'; do
    n=$((n+1))
    w "pn$n.md" "# Brief\n\n## Problème\n%s\n\n## Utilisateurs\nFreelances en France.\n\n$BR_VA$BR_CO$BR_HP" "$v"
    run --brief "$FX/pn$n.md"
    msg "rubrique ne portant que [$v] attendu rc 1 + problème : vide"
    { [ "$RC" -eq 1 ] && has 'rubrique BRIEF probleme : vide'; } || return 1
  done
  return 0; }
probe_puce_num_seule() { w pnn.md "# Brief\n\n## Problème\n1. [décrire le problème ici]\n\n## Utilisateurs\nFreelances en France.\n\n$BR_VA$BR_CO$BR_HP"
  run --brief "$FX/pnn.md"; msg "1. [décrire le problème ici] seul attendu rc 1"; [ "$RC" -eq 1 ] && has 'probleme : vide'; }
probe_puce_point_median() { w pnm.md "# Brief\n\n## Problème\n"$'\xc2\xb7'" [décrire le problème ici]\n\n## Utilisateurs\nFreelances en France.\n\n$BR_VA$BR_CO$BR_HP"
  run --brief "$FX/pnm.md"; msg "· [décrire le problème ici] seul attendu rc 1"; [ "$RC" -eq 1 ] && has 'probleme : vide'; }

# Gabarits LIVRÉS, crochets retirés (REQ : on garde la case `[ ]`, sinon plus aucune exigence ; BRIEF : tout).
TPL_REQ="$HERE/../../../planning-core/references/templates/product/REQUIREMENTS.template.md"
TPL_BRIEF="$HERE/../../references/BRIEF.template.md"
probe_tpl_req() {
  sed 's/\[\([^] ][^]]*\)\]/\1/g' "$TPL_REQ" > "$FX/tpl-req.md"
  run --requirements "$FX/tpl-req.md"
  msg "gabarit REQUIREMENTS sans crochets attendu rc 1 + PRD-01 et PRD-02 éliminatoires"
  [ "$RC" -eq 1 ] && has 'ELIMINATOIRE exigence PRD-01' && has 'ELIMINATOIRE exigence PRD-02'; }
probe_tpl_req_litteral() {
  sed 's/\[\([^]]*\)\]/\1/g' "$TPL_REQ" > "$FX/tpl-req2.md"
  run --requirements "$FX/tpl-req2.md"
  msg "gabarit REQUIREMENTS, sed littéral du mandat (la case est retirée aussi) attendu rc non nul (jamais 0)"
  [ "$RC" -ne 0 ]; }
probe_tpl_brief() {
  sed 's/\[\([^]]*\)\]/\1/g' "$TPL_BRIEF" > "$FX/tpl-brief.md"
  run --brief "$FX/tpl-brief.md"
  msg "gabarit BRIEF sans crochets attendu rc 1 + les cinq rubriques vides"
  [ "$RC" -eq 1 ] && has 'rubrique BRIEF probleme : vide' && has 'rubrique BRIEF utilisateurs : vide' \
    && has 'rubrique BRIEF valeur : vide' && has 'rubrique BRIEF contraintes : vide' && has 'rubrique BRIEF hors_perimetre : vide'; }
probe_tpl_req_brut() {
  run --requirements "$TPL_REQ"
  msg "gabarit REQUIREMENTS brut (crochets) attendu rc 1"; [ "$RC" -eq 1 ]; }

case_ CPRD-UNK-PRIORITE probe_unk_priorite
case_ CPRD-SEPARATEURS probe_separateurs
case_ CPRD-SEPARATEUR-PHRASE probe_separateur_phrase
case_ CPRD-TIRET-COLLE probe_tiret_colle
case_ CPRD-LIBELLE-REPETE probe_libelle_repete
case_ CPRD-PUCES-NUMEROTEES probe_puces_numerotees
if [ -f "$TPL_REQ" ] && [ -f "$TPL_BRIEF" ]; then
  case_ CPRD-GABARIT-SANS-CROCHETS-REQ probe_tpl_req
  case_ CPRD-GABARIT-SANS-CROCHETS-REQ-LITTERAL probe_tpl_req_litteral
  case_ CPRD-GABARIT-SANS-CROCHETS-BRIEF probe_tpl_brief
  case_ CPRD-GABARIT-BRUT-REQ probe_tpl_req_brut
else
  skip "CPRD-GABARIT-SANS-CROCHETS (gabarits livrés absents : suite posée à plat dans un lab)"
fi

mutant CPRD-MUT-160 'if [ "$NUNK" -gt 0 ]; then' '[ "$NUNK" -gt 0 ]' 'false' probe_unk_priorite \
  "INDÉTERMINÉ : case non reconnue rendue 0 (vert à vide)"
mutant CPRD-MUT-162 "$WORDN" '[A-Za-z0-9]' '[A-Za-z0-9,]' probe_separateur_virgule "FAIL : la virgule avant le champ est prise pour la fin d'un mot"
mutant CPRD-MUT-163 "$WORDN" '[A-Za-z0-9]' '[A-Za-z0-9(]' probe_separateur_paren "FAIL : la parenthèse avant le champ est prise pour la fin d'un mot"
mutant CPRD-MUT-164 "$WORDN" '[A-Za-z0-9]' '[A-Za-z0-9-]' probe_separateur_tiret "FAIL : le tiret entouré d'espaces avant le champ est pris pour la fin d'un mot"
mutant CPRD-MUT-165 "$WORDN" '|(\314|\315)[\200-\277])' '|(\314|\315)[\200-\277]|\342\200\224)' probe_separateur_cadratin "FAIL : le tiret cadratin avant le champ est pris pour la fin d'un mot"
mutant CPRD-MUT-166 "$WORDN" '|(\314|\315)[\200-\277])' '|(\314|\315)[\200-\277]|\342\200\223)' probe_separateur_cadratin "FAIL : le tiret demi-cadratin avant le champ est pris pour la fin d'un mot"
mutant CPRD-MUT-167 'if (nchars(plain(v)) < 10) return 0' '< 10' '< 0' probe_separateur_phrase "FAIL : seuil de longueur retiré, « il faut, acceptation : ok vite » devient un faux vert"
mutant CPRD-MUT-169 'if (pre ~ /([A-Za-z0-9]|[\200-\377])-$/) return 0' '/([A-Za-z0-9]|[\200-\377])-$/' '/ZZZZZ$/' probe_tiret_colle "FAIL : mot composé terminé par un tiret collé pris pour un champ"
mutant CPRD-MUT-170 'if (p == "acceptation" || p == "critere d acceptation") return 0' 'p == "acceptation" ||' '0 ||' probe_libelle_repete_nu "FAIL : valeur qui répète « Acceptation » acceptée"
mutant CPRD-MUT-171 'if (p == "acceptation" || p == "critere d acceptation") return 0' '|| p == "critere d acceptation"' '|| 0' probe_libelle_repete_long "FAIL : valeur « Critère d acceptation » acceptée"
mutant CPRD-MUT-172 "$LEADN" '|[0-9]+[.)]([ \t]|$)' '' probe_puce_num_seule "FAIL : puce numérotée non retirée en tête"
mutant CPRD-MUT-173 "$LEADN" '\302[\253\267]' '\302[\253]' probe_puce_point_median "FAIL : point médian · non retiré en tête"
if [ -f "$TPL_REQ" ] && [ -f "$TPL_BRIEF" ]; then
  mutant CPRD-MUT-174 'if (tmplword(t)) return 1' 'tmplword(t)' '0' probe_tpl_brief "FAIL BRIEF : texte des gabarits livrés, crochets retirés, accepté comme contenu"
  mutant CPRD-MUT-175 'if (tmplword(t)) return 1' 'tmplword(t)' '0' probe_tpl_req "FAIL : critère du gabarit livré, crochets retirés, accepté"
  mutant CPRD-MUT-176 'n = split("quel probleme rencontre-t-on' 'quel probleme rencontre-t-on' 'zzz1' probe_tpl_brief "FAIL BRIEF : consigne Problème du gabarit non reconnue"
  mutant CPRD-MUT-177 'n = split("quel probleme rencontre-t-on' 'qui utilisera ce produit' 'zzz2' probe_tpl_brief "FAIL BRIEF : consigne Utilisateurs du gabarit non reconnue"
  mutant CPRD-MUT-178 'n = split("quel probleme rencontre-t-on' 'qu est-ce qui change concretement' 'zzz3' probe_tpl_brief "FAIL BRIEF : consigne Valeur du gabarit non reconnue"
  mutant CPRD-MUT-179 'n = split("quel probleme rencontre-t-on' 'quelles limites s imposent' 'zzz4' probe_tpl_brief "FAIL BRIEF : consigne Contraintes du gabarit non reconnue"
  mutant CPRD-MUT-180 'n = split("quel probleme rencontre-t-on' 'qu est-ce qui est volontairement exclu' 'zzz5' probe_tpl_brief "FAIL BRIEF : consigne Hors périmètre du gabarit non reconnue"
  mutant CPRD-MUT-181 'n = split("quel probleme rencontre-t-on' 'quoi, combien, en combien de temps' 'zzz6' probe_tpl_req "FAIL : consigne du critère du gabarit non reconnue"
fi

echo "== cellules génératives : $GEN_TOT assertions comptées, $GEN_OK conformes (rouges ou verts attendus obtenus) =="
echo "== resultat : $PASS ok, $FAIL ko ($SKIPPED skip) =="
[ "$FAIL" -eq 0 ]
