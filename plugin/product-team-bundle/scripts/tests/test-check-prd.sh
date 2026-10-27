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
# Mutants CPRD-MUT-1..8 (QUAL-01), puis CPRD-MUT-9..26 (revue-59 F4 : un mutant par comportement documenté) : une ligne du script altérée, chacun différent de l'original (cmp -s), valide
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
has() { printf '%s\n' "$OUT" | command grep -qF -- "$1"; }
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
  msg "critère entre crochets attendu rc 1 + exigence nommée"; [ "$RC" -eq 1 ] && has 'ELIMINATOIRE exigence PRD-01'; }
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
  msg "3 cases non reconnues attendu rc 0 + AVERTISSEMENT lignes 4 à 6 (stdout ET stderr) + non_reconnues=3, contenu jamais réimprimé"
  [ "$RC" -eq 0 ] || return 1
  has 'AVERTISSEMENT ligne 4 :' && has 'AVERTISSEMENT ligne 5 :' && has 'AVERTISSEMENT ligne 6 :' || return 1
  last | command grep -q 'BILAN exigences=1 .*non_reconnues=3 ' || return 1
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
case_ CPRD-FENCE-OUVERTE probe_fence_ouverte
case_ CPRD-CASE-INCONNUE probe_case_inconnue
case_ CPRD-BRIEF-REMPLISSAGE probe_brief_remplissage
case_ CPRD-BRIEF-CRLF probe_brief_crlf

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
# l'environnement : aucune séquence d'échappement interprétée). La sonde doit échouer sur le mutant, réussir sur l'original.
mutant() {
  local id="$1" needle="$2" old="$3" new="$4" probe="$5" desc="$6"
  NEEDLE="$needle" OLD="$old" NEW="$new" awk 'BEGIN { n = ENVIRON["NEEDLE"]; o = ENVIRON["OLD"]; w = ENVIRON["NEW"] }
    { if (index($0, n)) { i = index($0, o); if (i) $0 = substr($0, 1, i - 1) w substr($0, i + length(o)) } print }' \
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
mutant CPRD-MUT-2 'if (c == "[" || c == "<") return 0' 'c == "[" || c == "<"' '0' probe_gabarit \
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
mutant CPRD-MUT-8 'if (match(s, /[Aa]cceptation' '[Aa]cceptation' 'Acceptation' probe_ancre \
  "PASS : ancre du critère rendue sensible à la casse"

# --- revue-59 F4 : un mutant par comportement documenté (une ligne, un fragment retiré).
mutant CPRD-MUT-9 'n = split("tbd|todo|tba' 'todo|' '' probe_todo \
  "FAIL : TODO retiré de la liste des marqueurs de remplissage (exigence)"
mutant CPRD-MUT-10 'n = split("tbd|todo|tba' 'tbd|' '' probe_tbd \
  "FAIL : TBD retiré de la liste des marqueurs de remplissage (exigence)"
mutant CPRD-MUT-11 'hasword(tolower(t), "tbd")' ' || hasword(tolower(t), "todo")' '' probe_brief_remplissage \
  "FAIL BRIEF : TODO retiré du filtre de remplissage"
mutant CPRD-MUT-12 'hasword(tolower(t), "tbd")' 'hasword(tolower(t), "tbd") || ' '' probe_brief_remplissage \
  "FAIL BRIEF : TBD retiré du filtre de remplissage"
mutant CPRD-MUT-13 'line ~ /^[ \t]*$/ || line ~ /^#/' 'line ~ /^[ \t]*$/ || ' '' probe_ferme_blanc \
  "FAIL : la ligne blanche ne ferme plus l'exigence"
mutant CPRD-MUT-14 'line ~ /^[ \t]*$/ || line ~ /^#/' ' || line ~ /^[ \t]*([-*+]|[0-9]+\.)[ \t]/' '' probe_sous_puce \
  "FAIL : la sous-puce ne ferme plus l'exigence"
mutant CPRD-MUT-15 "OUT_TXT=\$(tr -d" "tr -d '\\r' < \"\$1\"" "cat < \"\$1\"" probe_brief_crlf \
  "FAIL BRIEF : retrait des CR retiré (fichier CRLF)"
mutant CPRD-MUT-16 'n = split("tbd|todo|tba' 'a preciser|' '' probe_remplissage \
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
mutant CPRD-MUT-22 'if (line ~ /^[ \t]*$/ && pre !~' ') next' ') pre = pre' probe_commentaire \
  "FAIL : un commentaire multi-ligne ferme l'exigence"
mutant CPRD-MUT-23 'if [ "$NFENCE" -ne 0 ]; then' '[ "$NFENCE" -ne 0 ]' 'false' probe_fence_ouverte \
  "INDÉTERMINÉ : bloc de code non fermé rendu 0"
mutant CPRD-MUT-24 'nunk++' 'nunk++' 'nxx++' probe_case_inconnue \
  "BILAN : cases non reconnues non comptées"
mutant CPRD-MUT-25 'if (nunk <= 50) printf' 'if (nunk <= 50)' 'if (0)' probe_case_inconnue \
  "AVERTISSEMENT : cases non reconnues non signalées"
mutant CPRD-MUT-26 "command grep -F 'AVERTISSEMENT ligne '" '>&2' '>/dev/null' probe_case_inconnue \
  "AVERTISSEMENT : copie sur stderr retirée"

echo "== resultat : $PASS ok, $FAIL ko ($SKIPPED skip) =="
[ "$FAIL" -eq 0 ]
