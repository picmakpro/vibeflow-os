# regie-rg-tiroir.sh — fragment du plan 73-10, SOURCÉ par test-cockpit-regie.sh (ne définit que des fonctions) : le tiroir « Au travail » hors d'Équipe (REGI-11 ; P73-D-14, P73-D-26).
#   RG11_tiroir : RG11.20a (forme A : page Équipe chargée comme page, G.meta.vfTab) et RG11.20b (forme B : coquille de la 79, Code puis Équipe par `surOnglet`) : sur Équipe le bouton
#                 « N au travail » mène à la section « Au travail » (focus sur son titre) et n'ouvre aucun tiroir ; sur Projet et Code il l'ouvre comme avant ·
#                 RG11.21 (le pli des terminés devient le lien « N à relire dans Équipe », compté avec l'état « lu ») · RG11.22 (navigateur : le lien mène au titre de « Terminé, à relire ») ·
#                 RG11.23 (70-vf-live.js : une ligne modifiée, aucune ajoutée ; garde dans la ligne du bouton, jamais dans un test d'onglet).
# Mutants (une garde, régime allégé) : M-TIROIR-EQUIPE (le bouton ouvre encore le tiroir sur Équipe), M-GARDE-ONGLET-FIGE (garde lue sur l'onglet connu comme page : verte en forme A, rouge en forme B).
# Les témoins observent le comportement (tiroir ouvert ou non, focus), jamais le texte de la ligne du bouton. Fixtures : noms et identifiants inventés.

[ -n "${RG_PAGE_COMMUN:-}" ] || { . "$TESTS_DIR/regie-page-commun.sh"; RG_PAGE_COMMUN=1; }
[ -n "${PG_SID:-}" ] || . "$TESTS_DIR/regie-rg-page.sh"
TI_FICH='"fichiers":["70-vf-live.js","71-vf-equipe-rendu.js","72-vf-equipe.js","72-vf-regie-modele.js","72-vf-regie-pied.js","72-vf-regie-rendu.js","72-vf-regie-source.js"],"source":"etat"'
TI_B="$TI_FICH"',"onglet":"code","coquille":{"onglet0":"code"}'
# (70-vf-live.js se charge avant 71 : le who est posé après le chargement, jamais au chargement)
# ti_clic <dossier ui> <membres> <étapes avant> : joue le clic sur le bouton du tiroir après les étapes ; rend « <ouvertures du tiroir>|<balise du focus>|<section du focus> »
ti_clic() {
  local f="$WORK/ti-$$-$RANDOM.sc.json" o
  printf '{"onglet":"equipe","source":"etat","who":null,"lock":null,%s,"etapes":[{"poser":{"who":%s}},%s{"nom":"a0","obs":{}},{"clic":"#vf-lock"},{"nom":"a1","obs":{}},{"nom":"f","obs":{"mode":"focus"}}]}' "$2" "$PG_WHO" "$3" > "$f"
  o="${f%.sc.json}.out.json"; node "$TESTS_DIR/vm-regie-page.mjs" "$1" "$f" > "$o" 2>&1
  G "$o" 'j.erreur ? "ERR:" + j.erreur : (j.out.a1.sc.filter((x) => x === "showPanel").length - j.out.a0.sc.filter((x) => x === "showPanel").length) + "|" + j.out.f.tag + "|" + (j.out.f.section || "-")' 2>/dev/null || echo "ERR:illisible"
}
# ti_pages <dossier ui> : les deux formes de la garde, en une ligne (sonde des mutants)
ti_pages() { printf 'A=%s B=%s' "$(ti_clic "$1" "$TI_FICH" '')" "$(ti_clic "$1" "$TI_B" '{"onglet":"equipe"},')"; }

rg_RG11_tiroir() {
  local a p c b0 b1 b2 o t="$WORK/ti-lignes.txt"
  # RG11.20a — forme A : la page Équipe est chargée comme page (G.meta.vfTab = equipe, pas de coquille)
  a="$(ti_clic "$UI" "$TI_FICH" '')"
  assert_eq "RG11.20a — forme A, sur Équipe : le bouton « N au travail » n'ouvre aucun tiroir et donne le focus au titre de « Au travail »" "$a" "0|H2|au-travail"
  p="$(ti_clic "$UI" "$TI_FICH"',"onglet":"project"' '')"; c="$(ti_clic "$UI" "$TI_FICH"',"onglet":"code"' '')"
  assert_eq "RG11.20a — forme A, témoin positif : sur Projet et sur Code le bouton ouvre le tiroir comme avant (une ouverture, focus non déplacé vers une section)" "${p%%|*}${c%%|*}" "11"
  # RG11.20b — forme B : page chargée sur Code avec la coquille, puis Équipe par surOnglet, puis retour sur Code
  b0="$(ti_clic "$UI" "$TI_B" '')"; b1="$(ti_clic "$UI" "$TI_B" '{"onglet":"equipe"},')"; b2="$(ti_clic "$UI" "$TI_B" '{"onglet":"equipe"},{"onglet":"code"},')"
  assert_eq "RG11.20b — forme B (coquille) : sur Code le tiroir s'ouvre ; après passage à Équipe par surOnglet il ne s'ouvre pas et le focus va au titre de « Au travail » ; au retour sur Code il s'ouvre de nouveau" "${b0%%|*}|$b1|${b2%%|*}" "1|0|H2|au-travail|1"
  rg_mutant TIROIR-EQUIPE "le bouton ouvre encore le tiroir sur Équipe (garde coupée)" "$UI" 70-vf-live.js "window.__vfRegie?.monte?.()" "false" ti_pages "A=0|H2|au-travail B=0|H2|au-travail"
  rg_mutant GARDE-ONGLET-FIGE "la garde lit l'onglet connu comme page au lieu de demander à la régie (vraie en forme A, fausse en forme B)" "$UI" 70-vf-live.js "window.__vfRegie?.monte?.()" "(G.meta.vfTab === 'equipe' && !window.VF_COQUILLE)" ti_pages "A=0|H2|au-travail B=0|H2|au-travail"
  # RG11.21 — le pli des terminés devient un lien compté avec « lu »
  local w='{"workers":[{"kind":"session","id":"s0000000-aaaa-bbbb-cccc-111111111111","etat":"actif","titre":"Atelier","tree":".","ageS":4}'
  local f1=',{"kind":"subagent","id":"f1f1f1f1f1f1","etat":"termine","parent":"s0000000-aaaa-bbbb-cccc-111111111111","role":"vf-reviewer","task":"Rapport un","ageS":300,"dureeS":40,"tree":"."}'
  local f2=',{"kind":"subagent","id":"f2f2f2f2f2f2","etat":"termine","parent":"s0000000-aaaa-bbbb-cccc-111111111111","role":"vf-reviewer","task":"Rapport deux","ageS":400,"dureeS":40,"tree":"."}'
  local f3=',{"kind":"subagent","id":"f3f3f3f3f3f3","etat":"termine","parent":"s0000000-aaaa-bbbb-cccc-111111111111","role":"vf-reviewer","task":"Rapport trois","ageS":500,"dureeS":40,"tree":"."}'
  local ex='(function(){ const h = j.final.panneauHtml || ""; const m = /<a class="[^"]*" href="([^"]*)">([^<]*à relire dans Équipe)<\/a>/.exec(h); return (m ? m[2] + "@" + m[1] : "aucun lien") + "|" + (h.includes("vf-termines") ? "pli" : "sans pli"); })()'
  local lus='"lus":["f2f2f2f2f2f2"]'
  o="$(pg_sc "$TI_FICH"',"onglet":"project","who":null,'"$lus" '[{"poser":{"who":'"$w$f1$f2$f3]}"'}},{"clic":"#vf-lock"}]')"
  pg_ok "RG11.21 — tiroir sur Projet, trois terminés dont un lu : le lien « 2 à relire dans Équipe » mène à equipe.html#vf-a-relire, plus aucun pli des terminés" "$o" "$ex" "2 à relire dans Équipe@equipe.html#vf-a-relire|sans pli"
  o="$(pg_sc "$TI_FICH"',"onglet":"project","who":null' '[{"poser":{"who":'"$w$f1$f2$f3]}"'}},{"clic":"#vf-lock"}]')"
  pg_ok "RG11.21 — aucun terminé lu : « 3 à relire dans Équipe »" "$o" "$ex" "3 à relire dans Équipe@equipe.html#vf-a-relire|sans pli"
  o="$(pg_sc "$TI_FICH"',"onglet":"project","who":null,"lus":["f1f1f1f1f1f1"]' '[{"poser":{"who":'"$w$f1]}"'}},{"clic":"#vf-lock"}]')"
  pg_ok "RG11.21 — tous lus : aucun lien (et aucun pli)" "$o" "$ex" "aucun lien|sans pli"
  # RG11.23 — 70-vf-live.js (P73-D-26) : la garde vit sur la seule ligne du bouton, aucune autre ligne ne parle de la régie, le fichier ne grandit pas (299 lignes au départ du plan, limite 300)
  assert_eq "RG11.23 — 70-vf-live.js : la ligne du bouton porte la garde et l'événement, aucune autre ligne ne les porte, ni lecture de l'onglet sur cette ligne, au plus 299 lignes" \
    "$(grep -n 'addHeaderButton' "$UI/70-vf-live.js" | awk -F: '$0 ~ /__vfRegie\?\.monte\?\.\(\)/ && $0 ~ /vf-regie:aller/ && $0 !~ /vfTab/ && $0 !~ /vf-tab-/ {n++} END{print n+0}')|$(grep -c -e 'vf-regie:aller' -e '__vfRegie' "$UI/70-vf-live.js")|$([ "$(awk 'END{print NR}' "$UI/70-vf-live.js")" -le 299 ] && echo ok || echo grand)" "1|1|ok"
  # RG11.24 — fin de phase : plus aucun producteur de data-vf-transcript ni de .vf-transcript dans ui/, donc plus de règle de feuille ni de sélecteur de focus qui les vise dans 70-vf-live.js
  assert_eq "RG11.24 — 70-vf-live.js ne cite plus ni data-vf-transcript, ni vfTranscript, ni .vf-transcript (règles de feuille et sélecteurs de focus morts retirés)" \
    "$(grep -c -e 'data-vf-transcript' -e 'vfTranscript' -e 'vf-transcript' "$UI/70-vf-live.js")" "0"
}

rg_RG11_tiroir_chrome() {
  rg_chrome || return 0
  local L="$WORK/lab-tiroir" out
  rg_lab "$L"; rg_serveur "$L"
  out="$(REAL_HOME="${REAL_HOME:-$HOME}" node "$TESTS_DIR/chrome-regie-tiroir.mjs" "$CHROME" "http://127.0.0.1:$RG_PORT/equipe.html" 2>&1)"
  rg_arreter; printf '%s\n' "$out" > "$WORK/ti-chrome.json"
  pg_ok "RG11.22 — dans un vrai navigateur, le lien « 3 à relire dans Équipe » du tiroir (Projet) ouvre Équipe avec le focus sur le titre de « Terminé, à relire »" "$WORK/ti-chrome.json" \
    'j.lien.texte + "|" + j.lien.plis + "|" + j.focus.tag + "|" + j.focus.section' "3 à relire dans Équipe|0|H2|a-relire"
}
