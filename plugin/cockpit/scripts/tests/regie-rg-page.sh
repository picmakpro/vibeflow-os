# regie-rg-page.sh — fragment du plan 73-05, SOURCÉ par test-cockpit-regie.sh (ne définit que des fonctions) : la page Équipe (régie) jouée en vm (vm-regie-page.mjs),
#   RG0_ordre_page (ordre de chargement, sortie assemblée) · RG1_page (conteneur, ancre de section, vue au retour de `vf:onglet`) · RG2_page (source unique)
#   RG9_page (mise à jour en place, durées) · RG11_page (lecteur de repli) · RG14_page (un seul style de bouton, nom unique, aucun HTML construit)
#   RG15_page (accroches de la Phase 74 : bascule, attributs, ancres, annulation, Échap, ré-exécution) · RG16_page (recherche).
# Mutants : aucun dans ce fragment (régime allégé) ; ceux des gardes de non-fuite du verrou viendront avec les sections navigateur.
# Fixtures : noms et identifiants inventés. Les formes simulées de VF_ETAT, VF_COQUILLE et VF_SURCOUCHES sont dans vm-regie-page.mjs (à aligner sur le code livré).
# Contrat du DOM attendu de la régie (écrit ici AVANT le code) : section#vf-equipe[role=main] > #vf-equipe-entete (h1, .vf-rg-sous, bascule role=tablist) puis .vf-vue[data-vf-vue] ;
#   section.vf-rg-sec[data-vf-section] > h2 (tabindex -1) ; li.vf-rg-lig[data-vf-cle][data-vf-agent][data-vf-noeud][data-vf-etat] ; .vf-rg-nom (le nom, une fois) ; button[aria-expanded] (le nom, déplie) ;
#   .vf-rg-plus (détail en flux) ; .vf-rg-dur ; .vf-rg-act button.btn (actions) ; .vf-rg-note (messages) ; recherche : input#search du moteur.

[ -n "${RG_PAGE_COMMUN:-}" ] || { . "$TESTS_DIR/regie-page-commun.sh"; RG_PAGE_COMMUN=1; }
PG_SID='s0000000-aaaa-bbbb-cccc-111111111111'; PG_A='a1b2c3d4e5f6'; PG_F='f0f0f0f0f0f0'; PG_B='b9b9b9b9b9b9'
PG_WHO='{"workers":[
 {"kind":"session","id":"s0000000-aaaa-bbbb-cccc-111111111111","etat":"attend","titre":"Atelier alpha","tree":".","branch":"feat/x","ageS":120,"dureeS":900,"retient":{"n":3,"portee":"noeuds"},"rattachement":{"etat":"rattache","dag":"D1","noeud":"N1"}},
 {"kind":"subagent","id":"a1b2c3d4e5f6","etat":"actif","parent":"s0000000-aaaa-bbbb-cccc-111111111111","role":"vf-dev-manager","ageS":3,"dureeS":60,"tree":".","rattachement":{"etat":"rattache","dag":"D1","noeud":"N2"}},
 {"kind":"subagent","id":"f0f0f0f0f0f0","etat":"termine","parent":"s0000000-aaaa-bbbb-cccc-111111111111","role":"vf-reviewer","task":"Relire le plan","ageS":600,"dureeS":90,"tree":"."},
 {"kind":"subagent","id":"b9b9b9b9b9b9","etat":"actif","parent":"s0000000-aaaa-bbbb-cccc-111111111111","role":"vf-coder","task":"Écrire le rendu","ageS":5,"dureeS":30,"tree":"."}]}'
PG_LOCK='[{"ws":"fiab","scope":"phase","phase":"73","step":"exec-73","owner":"vf-dev-manager-p73","present":true,"age_seconds":30,"lease_seconds":120}]'
PG_BTN_A='li[data-vf-cle=\"au-travail:a1b2c3d4e5f6\"] button.vf-rg-tog'
PG_BTN_RAPPORT='li[data-vf-cle=\"a-relire:f0f0f0f0f0f0\"] .vf-rg-act button'

# pg_sc <membres JSON en plus, ou vide> <étapes JSON> : écrit un scénario (les clés répétées l'emportent) et rend le chemin de sa sortie après exécution
pg_sc() { local f="$WORK/pg-$$-$RANDOM.sc.json" o; o="${f%.sc.json}.out.json"
  printf '{"onglet":"equipe","source":"live","who":%s,"lock":null%s,"etapes":%s}' "$PG_WHO" "${1:+,$1}" "$2" > "$f"
  node "$TESTS_DIR/vm-regie-page.mjs" "$UI" "$f" > "$o" 2>&1; printf '%s' "$o"; }
# pg_g <sortie> <expression sur j> : la valeur, ou « ERR:… » quand le harnais n'a rien pu jouer (fichier absent, exception)
pg_g() { local r; r="$(G "$1" 'j.erreur ? "ERR:" + j.erreur : (function(){ try { return ('"$2"'); } catch (e) { return "ERR:" + e.message; } })()' 2>/dev/null)"; printf '%s' "${r:-ERR:sortie vide}"; }
pg_ok() { assert_eq "$1" "$(pg_g "$2" "$3")" "$4"; }

rg_RG0_ordre_page() {
  cat > "$AUX/ordre-page.mjs" <<'JS'
// ordre-page.mjs <html> : « ok » si modèle, rendu et source de la régie existent une fois chacun, dans cet ordre, tous après 72-vf-equipe.js et avant tout /* ui/74- */ ; « faux:… » sinon
import fs from 'node:fs';
let t; try { t = fs.readFileSync(process.argv[2], 'utf8'); } catch { console.log('illisible'); process.exit(0); }
const m = (n) => `/* ui/${n} */`, n = (s) => t.split(s).length - 1, at = (s) => t.indexOf(s);
const noms = ['72-vf-regie-modele.js', '72-vf-regie-rendu.js', '72-vf-regie-source.js'], pb = [];
for (const x of noms) if (n(m(x)) !== 1) pb.push(`${x} ×${n(m(x))}`);
if (!(at(m(noms[0])) < at(m(noms[1])) && at(m(noms[1])) < at(m(noms[2])))) pb.push('ordre');
if (!(at(m('72-vf-equipe.js')) >= 0 && at(m(noms[0])) > at(m('72-vf-equipe.js')))) pb.push('pas après 72-vf-equipe.js');
const k = t.indexOf('/* ui/74-'); if (k >= 0 && !(k > at(m(noms[2])))) pb.push('pas avant 74-');
console.log(pb.length ? 'faux:' + pb.join(',') : 'ok');
JS
  local L="$WORK/ordp-lab" r="" f; mkdir -p "$L/src" "$L/.planning"; printf 'x\n' > "$L/src/u.js"; printf '## Phases\n\n- [ ] **Phase 1: Socle** - jet\n' > "$L/.planning/ROADMAP.md"
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/ordp-build.out" 2>&1
  for f in index.html project.html; do r="$r$f=$(node "$AUX/ordre-page.mjs" "$L/.vibeflow/cockpit/$f" 2>&1) "; done
  assert_eq "RG0.11 — modèle, rendu et source de la régie : une fois chacun, dans cet ordre, après 72-vf-equipe.js et avant 74-" "$r" "index.html=ok project.html=ok "
}

rg_RG1_page() {
  local o t="À vous|Au travail|Terminé, à relire|Au repos"
  o="$(pg_sc '' '[{"nom":"cadre","obs":{"mode":"compte","sel":"section#vf-equipe[role=\"main\"]"}},{"nom":"entete","obs":{"mode":"compte","sel":"#vf-equipe-entete h1"}},{"nom":"sous","obs":{"mode":"compte","sel":"#vf-equipe-entete .vf-rg-sous"}},{"nom":"h2","obs":{"mode":"textes","sel":"#vf-equipe h2"}},{"nom":"ser","obs":{"mode":"ser","sel":"#vf-equipe"}}]')"
  pg_ok "RG1.10 — section#vf-equipe[role=main] avec #vf-equipe-entete (h1, sous-titre) puis quatre h2 dans l'ordre ; corps vf-regie-montee" "$o" \
    'j.out.cadre + "|" + j.out.entete + "|" + j.out.sous + "|" + j.out.h2.map((s, i) => s.startsWith(["À vous","Au travail","Terminé, à relire","Au repos"][i])).join(",") + "|" + (j.out.ser.indexOf("vf-equipe-entete") < j.out.ser.indexOf("<h2")) + "|" + j.final.corps.includes("vf-regie-montee")' "1|1|1|true,true,true,true|true|true"
  o="$(pg_sc '"onglet":"code"' '[]')"; local p; p="$(pg_sc '"onglet":"project"' '[{"nom":"x","obs":{"mode":"compte","sel":"#vf-equipe"}}]')"
  pg_ok "RG1.10 — sur Code et sur Projet, rien n'est injecté (ni conteneur, ni classe du corps)" "$o" 'j.final.corps.includes("vf-regie-montee") + "|" + (j.final.monte === true)' "false|false"
  pg_ok "RG1.10 — sur Projet : aucun #vf-equipe" "$p" 'j.out.x' "0"
  o="$(pg_sc '' '[{"evenement":"vf-regie:aller","detail":{"section":"au-travail"}},{"nom":"f","obs":{"mode":"focus"}},{"nom":"ti","obs":{"mode":"attr","sel":"section[data-vf-section=\"au-travail\"] h2","attr":"tabindex"}},{"evenement":"vf-regie:aller","detail":{"section":"inconnue"},"nom":"x"}]')"
  pg_ok "RG1.11 — vf-regie:aller { section: 'au-travail' } : focus sur le titre (tabindex -1) ; section inconnue : aucune exception" "$o" 'j.out.f.tag + "|" + j.out.f.section + "|" + j.out.ti.join(",") + "|" + (j.out.x.erreur || "sans erreur")' "H2|au-travail|-1|sans erreur"
  o="$(pg_sc '"hash":"#vf-a-relire"' '[{"nom":"f0","obs":{"mode":"focus"}},{"focus":"#search"},{"poser":{"who":'"$PG_WHO"'}},{"nom":"f1","obs":{"mode":"focus"}}]')"
  pg_ok "RG1.11 — fragment #vf-a-relire au montage : focus sur le titre de « Terminé, à relire », une seule fois (une poussée suivante ne le reprend pas)" "$o" 'j.out.f0.tag + "|" + j.out.f0.section + "|" + j.out.f1.tag' "H2|a-relire|INPUT"
  # vue au retour de vf:onglet (80-10 non livré : le repli décrit au plan, l'événement de document vf:onglet émis après pushState)
  o="$(pg_sc '"coquille":{"onglet0":"code"},"onglets":true,"hash":"#vf-au-repos"' '[{"onglet":"equipe"},{"nom":"f1","obs":{"mode":"focus"}},{"vfOnglet":"equipe","hash":"#vf-a-relire"},{"nom":"f2","obs":{"mode":"focus"}},{"focus":"#search"},{"vfOnglet":"equipe"},{"nom":"f3","obs":{"mode":"focus"}}]')"
  pg_ok "RG1.12 — arrivée par onglet : au rappel de surOnglet le fragment est encore celui de l'onglet précédent (aucune action) ; à vf:onglet il est lu UNE fois ; un second vf:onglet identique ne refait rien" "$o" \
    '(j.out.f1.section || "aucune") + "|" + j.out.f2.section + "|" + j.out.f3.tag' "aucune|a-relire|INPUT"
}

rg_RG2_page() {
  local e l s1 s2
  e="$(pg_sc '"source":"etat","lock":'"$PG_LOCK" '[{"nom":"ser","obs":{"mode":"ser","sel":"#vf-equipe"}}]')"
  l="$(pg_sc '"source":"live","lock":'"$PG_LOCK" '[{"nom":"ser","obs":{"mode":"ser","sel":"#vf-equipe"}}]')"
  s1="$(pg_g "$e" 'j.out.ser')"; s2="$(pg_g "$l" 'j.out.ser')"
  assert_eq "RG2.1 — même (who, lock) donné par VF_ETAT ou par vf-who + __vfLive : sous-arbres section#vf-equipe identiques, non vides, avec la ligne de mission du verrou" \
    "$([ "$s1" = "$s2" ] && echo egal || echo different)|$([ "${#s1}" -gt 500 ] && echo plein || echo vide)|$([[ "$s1" == *"verrou"* ]] && echo mission || echo sans-mission)" "egal|plein|mission"
}

# RG2.2 (correction 73-09, H6.2) : les missions du titre viennent de meta.vf.missions de l'enveloppe de l'onglet, jamais d'un tableau vide écrit en dur dans la source
rg_RG2_missions() {
  local rel o m fx="$WORK/pg-missions-$$.js" defaut='71-vf-equipe-rendu.js 72-vf-regie-modele.js 72-vf-regie-pied.js 72-vf-regie-rendu.js 72-vf-regie-source.js' liste="" f
  rel="$(node -e 'console.log(require("path").relative(process.argv[1], process.argv[2]))' "$UI" "$fx")"
  for m in '[]' '["x"]' '["x","y"]'; do
    printf 'window.Floorplan.graph.meta.vf.missions = %s;\n' "$m" > "$fx"
    liste="\"$rel\""; for f in $defaut; do liste="$liste,\"$f\""; done
    o="$(pg_sc '"who":{"workers":[]},"fichiers":['"$liste"']' '[{"nom":"h","obs":{"mode":"textes","sel":"#vf-equipe-entete h1"}}]')"
    pg_ok "RG2.2 — meta.vf.missions = $m : le titre de la régie dit les missions de l'enveloppe" "$o" 'j.out.h.join("|")' \
      "$([ "$m" = '[]' ] && echo 'Aucune mission en cours' || { [ "$m" = '["x"]' ] && echo 'Mission : x' || echo '2 missions en cours'; })"
  done
}

rg_RG9_page() {
  local x='x0000000-0000-0000-0000-000000000009' w1 w2 w3 o
  w1='{"workers":[{"kind":"session","id":"'"$x"'","etat":"actif","titre":"Atelier X","tree":".","ageS":10,"dureeS":40}]}'
  w2='{"workers":[{"kind":"session","id":"'"$x"'","etat":"attend","titre":"Atelier X","tree":".","ageS":20,"dureeS":100,"retient":{"n":2,"portee":"noeuds"}}]}'
  w3='{"workers":[{"kind":"session","id":"'"$x"'","etat":"au-repos","titre":"Atelier X","tree":".","ageS":30,"dureeS":100}]}'
  local btn='li[data-vf-cle=\"au-travail:'"$x"'\"] button.vf-rg-tog'
  o="$(pg_sc '"who":'"$w1" '[{"marquer":"li[data-vf-cle=\"au-travail:'"$x"'\"]"},{"focus":"'"$btn"'"},{"poser":{"who":'"$w2"'}},{"nom":"f2","obs":{"mode":"focus"}},{"nom":"m2","obs":{"mode":"marques","sel":"li[data-vf-cle=\"au-travail:'"$x"'\"]"}},{"nom":"cles2","obs":{"mode":"attr","sel":"li[data-vf-cle]","attr":"data-vf-cle"}},{"poser":{"who":'"$w3"'}},{"nom":"f3","obs":{"mode":"focus"}}]')"
  pg_ok "RG9.20 — une ligne passe d'« Au travail » à « À vous » : même noeud (mise à jour en place), une seule li par clé, focus resté sur la ligne de l'arbre, jamais sur sa jumelle ; aucun rechargement" "$o" \
    'j.out.f2.cle + "|" + j.out.m2 + "|" + (new Set(j.out.cles2).size === j.out.cles2.length) + "|" + j.out.cles2.length + "|" + (j.final.rechargements || 0)' "au-travail:$x|1|true|2|0"
  pg_ok "RG9.20 — la ligne retirée de l'arbre : le focus va au titre de sa section, pas à une autre ligne" "$o" 'j.out.f3.tag + "|" + j.out.f3.section' "H2|au-travail"
  o="$(pg_sc '"who":'"$w1" '[{"nom":"a","obs":{"mode":"textes","sel":".vf-rg-dur"}},{"avancer":30000},{"nom":"b","obs":{"mode":"textes","sel":".vf-rg-dur"}}]')"
  pg_ok "RG9.21 — 30 s sans poussée : les durées avancent" "$o" '(j.out.a.length > 0) + "|" + (j.out.a.join() !== j.out.b.join())' "true|true"
  o="$(pg_sc '"who":{"workers":[{"kind":"subagent","id":"f0f0f0f0f0f0","etat":"termine","role":"vf-reviewer","task":"Relire","ageS":600,"dureeS":90,"tree":"."}]}' '[{"raz":true},{"avancer":30000},{"nom":"e","obs":{}}]')"
  pg_ok "RG9.21 — 30 s sans poussée, texte identique : aucune écriture du DOM" "$o" 'j.out.e.ecritures + "|" + (j.out.e.minuteries >= 1)' "0|true"
}

# RG9.22 : un rendu qui suit un événement du magasin (who, lock, connexion) ou la minuterie ne touche ni la sélection du moteur ni le focus : aucun appel au moteur
# (rerender, showPanel, closePanel…), la sélection posée avant reste posée. Sans horloge : l'événement est rejoué puis le rendu attendu par un cycle de promesses.
rg_RG9_selection() {
  local src o ev='{"poser":{"who":'"$PG_WHO"',"lock":'"$PG_LOCK"'}}'
  for src in etat live; do
    o="$(pg_sc '"source":"'"$src"'"' '[{"selectionner":"n:ag-'"$PG_A"'"},{"focus":"'"$PG_BTN_A"'"},{"nom":"av","obs":{"mode":"focus"}},'"$ev"','"$ev"',{"conn":"perdu"},{"conn":"ouvert"},{"avancer":30000},{"nom":"ap","obs":{"mode":"focus"}},{"nom":"e","obs":{}}]')"
    pg_ok "RG9.22 — source $src : événements du magasin et minuterie, puis rendu : aucun appel au moteur, sélection et focus intacts" "$o" \
      'j.out.e.sc.length + "|" + j.out.e.selection + "|" + (j.out.ap.cle === j.out.av.cle && j.out.ap.tag === "BUTTON")' "0|n:ag-$PG_A|true"
  done
}

rg_RG11_page() {
  local o="$WORK/_" a b c
  b="$(pg_sc '' '[{"annuler":["rapport"]},{"clic":"'"$PG_BTN_RAPPORT"'"},{"nom":"e","obs":{}}]')"
  pg_ok "RG11.10 — annulé : aucune requête, aucun panneau, aucun vf-agent:lu" "$b" 'j.out.e.evts.map((x) => x.type).join(",") + "|" + j.out.e.fetchs.length + "|" + (j.out.e.panneau === "")' "vf-agent:ouvrir|0|true"
  pg_ok "RG15.7 — la régie n'émet vf-agent:lu que quand SON lecteur s'ouvre (jamais sur un ouvrir annulé)" "$b" 'j.out.e.evts.filter((x) => x.type === "vf-agent:lu").length' "0"
}

rg_RG14_page() {
  local o
  o="$(pg_sc '' '[{"nom":"cl","obs":{"mode":"classes","sel":".vf-rg-act button"}},{"nom":"nom","obs":{"mode":"trouve","sel":"li[data-vf-cle=\"au-travail:b9b9b9b9b9b9\"]","contient":"Écrire le rendu"}},{"nom":"dis","obs":{"mode":"compte","sel":"#vf-equipe [disabled]"}},{"nom":"btns","obs":{"mode":"textes","sel":"#vf-equipe button"}}]')"
  pg_ok "RG14.10 — chaque bouton d'action n'a que la classe de style .btn (et il y en a au moins un)" "$o" '(j.out.cl.length > 0) + "|" + j.out.cl.every((c) => c === "btn")' "true|true"
  pg_ok "RG14.10 — le nom d'une ligne s'écrit dans un seul élément (ni title, ni aria-label, ni bouton) ; jamais l'attribut disabled" "$o" 'j.out.nom.textes + "|" + j.out.nom.attrs + "|" + j.out.dis' "1|0|0"
  pg_ok "RG14.10 — « Tout marquer comme relu » absent tant que __vfRegieLu n'existe pas" "$o" 'j.out.btns.some((t) => t.includes("Tout marquer"))' "false"
  pg_ok "RG14.11 — aucun HTML construit : ni innerHTML ni insertAdjacentHTML dans toute la page (clic sur le rapport et le nom compris)" \
    "$(pg_sc '' '[{"clic":"'"$PG_BTN_RAPPORT"'"},{"clic":"'"$PG_BTN_A"'"},{"nom":"e","obs":{}}]')" 'j.out.e.violations.length + "|" + (j.out.e.fiche.tag !== undefined)' "0|true"
}

rg_RG15_page() {
  local o a v='{"declarerVue":{"id":"frise","libelle":"Frise"}}' cle='"sessionStorage":{"vibeflow-cockpit:equipe-vue":"frise"}'
  a='[{"nom":"ts","obs":{"mode":"compte","sel":"#vf-equipe-entete [role=\"tablist\"]"}}]'
  pg_ok "RG15.1 — avec la seule vue regie : aucune bascule" "$(pg_sc '' "$a")" 'j.out.ts' "0"
  o="$(pg_sc '' '['"$v"',{"nom":"ts","obs":{"mode":"compte","sel":"#vf-equipe-entete [role=\"tablist\"]"}},{"nom":"lib","obs":{"mode":"attr","sel":"#vf-equipe-entete [role=\"tablist\"]","attr":"aria-label"}},{"nom":"tabs","obs":{"mode":"textes","sel":"[role=\"tab\"]"}},{"clic":"[role=\"tab\"]","indice":1},{"nom":"v1","obs":{"mode":"compte","sel":".vf-vue[data-vf-vue=\"frise\"]"}},{"nom":"e1","obs":{}},{"clic":"[role=\"tab\"]","indice":0},{"nom":"e2","obs":{}},{"appel":"sessionStorage.getItem","args":["vibeflow-cockpit:equipe-vue"],"nom":"cle"}]')"
  pg_ok "RG15.1 et RG15.8 — dès deux vues : tablist « Vue de l'équipe » à deux onglets (Régie, Frise) ; monter une fois au choix, demonter au retour ; position gardée par l'id de la vue" "$o" \
    'j.out.ts + "|" + j.out.lib.join() + "|" + j.out.tabs.join() + "|" + j.out.v1 + "|" + j.out.e1.vues.join() + "|" + j.out.e2.vues.join() + "|" + j.out.cle' "1|Vue de l'équipe|Régie,Frise|1|monter:frise|monter:frise,demonter:frise|regie"
  o="$(pg_sc "$cle" '['"$v"',{"nom":"sel","obs":{"mode":"attr","sel":"[role=\"tab\"]","attr":"aria-selected"}}]')"
  pg_ok "RG15.8 — la clé sessionStorage restaure la vue (Frise sélectionnée)" "$o" 'j.out.sel.join()' "false,true"
  o="$(pg_sc '"sessionStorage":{"vibeflow-cockpit:equipe-vue":"zzz"}' '['"$v"',{"nom":"sel","obs":{"mode":"attr","sel":"[role=\"tab\"]","attr":"aria-selected"}}]')"
  pg_ok "RG15.8 — valeur inconnue ou absente : « Régie »" "$o" 'j.out.sel.join()' "true,false"
  o="$(pg_sc '' '[{"nom":"ag","obs":{"mode":"sansAttr","sel":"li[data-vf-cle]","attr":"data-vf-agent"}},{"nom":"no","obs":{"mode":"sansAttr","sel":"li[data-vf-cle]","attr":"data-vf-noeud"}},{"nom":"et","obs":{"mode":"sansAttr","sel":"li[data-vf-cle]","attr":"data-vf-etat"}},{"nom":"vn","obs":{"mode":"attr","sel":"li[data-vf-cle=\"au-travail:a1b2c3d4e5f6\"]","attr":"data-vf-noeud"}},{"nom":"ve","obs":{"mode":"attr","sel":"li[data-vf-cle=\"au-travail:a1b2c3d4e5f6\"]","attr":"data-vf-etat"}},{"nom":"va","obs":{"mode":"attr","sel":"li[data-vf-cle=\"au-travail:a1b2c3d4e5f6\"]","attr":"data-vf-agent"}}]')"
  pg_ok "RG15.2 — data-vf-agent, data-vf-noeud et data-vf-etat sur chaque ligne ; valeurs d'une ligne rattachée" "$o" 'j.out.ag + "|" + j.out.no + "|" + j.out.et + "|" + j.out.va + "|" + j.out.vn + "|" + j.out.ve' "0|0|0|$PG_A|N2|actif"
  o="$(pg_sc '' '[{"annuler":[]},{"clic":"li[data-vf-cle=\"au-travail:'"$PG_SID"'\"] button.vf-rg-tog"},{"nom":"e","obs":{}},{"nom":"ex","obs":{"mode":"attr","sel":"li[data-vf-cle=\"au-travail:'"$PG_SID"'\"] button.vf-rg-tog","attr":"aria-expanded"}},{"nom":"det","obs":{"mode":"textes","sel":"li[data-vf-cle=\"au-travail:'"$PG_SID"'\"] .vf-rg-plus"}},{"nom":"lien","obs":{"mode":"attr","sel":"li[data-vf-cle=\"au-travail:'"$PG_SID"'\"] .vf-rg-plus a","attr":"href"}},{"touche":"Escape","sur":"li[data-vf-cle=\"au-travail:'"$PG_SID"'\"] button.vf-rg-tog","nom":"esc"},{"nom":"ex2","obs":{"mode":"attr","sel":"li[data-vf-cle=\"au-travail:'"$PG_SID"'\"] button.vf-rg-tog","attr":"aria-expanded"}},{"nom":"f","obs":{"mode":"focus"}}]')"
  pg_ok "RG15.3 — le nom, non annulé : vf-agent:ouvrir (nom) puis détail en flux (identifiant court, branche, arbre, lien Nœud) avec aria-expanded ; Échap replie et rend le focus au bouton" "$o" \
    'j.out.e.evts[0].declencheur + "|" + j.out.ex.join() + "|" + ["s0000000","feat/x","main","Nœud"].map((s) => j.out.det.join(" ").includes(s)).join() + "|" + j.out.lien.join().includes("project.html#r=") + "|" + j.out.ex2.join() + "|" + j.out.f.tag + ":" + j.out.f.cle' \
    "nom|true|true,true,true,true|true|false|BUTTON:au-travail:$PG_SID"
  local ar='{"appel":"__vfRegie.arriver","args":["n:se-'"$PG_SID"'"],"nom":"r1"}'
  o="$(pg_sc '' '[{"raz":true},'"$ar"',{"nom":"f1","obs":{"mode":"focus"}},{"nom":"d1","obs":{}},{"raz":true},{"appel":"__vfRegie.arriver","args":["n:se-inconnu"],"nom":"r2"},{"nom":"d2","obs":{}},{"nom":"f2","obs":{"mode":"focus"}},{"raz":true},{"appel":"__vfRegie.arriver","args":["n:ag-'"$PG_A"'"],"nom":"r3"},{"nom":"f3","obs":{"mode":"focus"}}]')"
  pg_ok "RG15.4 — #r=n:se-<id> avec la ligne dans « À vous » et dans l'arbre : défilement et focus sur celle d'« À vous », une fois ; n:ag-<id> : la ligne de l'arbre" "$o" \
    'j.out.r1 + "|" + j.out.f1.cle + "|" + j.out.d1.defilements.join() + "|" + j.out.f3.cle' "true|a-vous:$PG_SID|a-vous:$PG_SID|au-travail:$PG_A"
  pg_ok "RG15.4 — ancre inconnue : ni exception, ni défilement, focus inchangé" "$o" '(j.out.r2 && j.out.r2.erreur ? "erreur" : "sans erreur") + "|" + j.out.d2.defilements.length + "|" + (j.out.f2.cle === j.out.f1.cle)' "sans erreur|0|true"
  assert_eq "RG15.4 — la ligne d'arrivée de 00-vibeflow.js délègue à __vfRegie.arriver sur Équipe seulement, sans ligne ajoutée (≤ 298 lignes)" \
    "$(grep -c "TAB === 'equipe'.*__vfRegie\|__vfRegie.*TAB === 'equipe'" "$UI/00-vibeflow.js")|$(awk 'END{print (NR <= 298) ? "ok" : "trop"}' "$UI/00-vibeflow.js")" "1|ok"
  rg15_annule
  rg15_cycle
  rg15_echap
}

rg15_annule() {
  local av='li[data-vf-cle=\"a-vous:'"$PG_SID"'\"] button.vf-rg-tog'
  local o ouv='li[data-vf-cle=\"au-travail:'"$PG_SID"'\"] button.vf-rg-tog' ar='{"appel":"__vfRegie.arriver","args":["n:se-'"$PG_SID"'"]}'
  o="$(pg_sc '' '[{"annuler":["nom","ancre","rapport"]},{"focus":"#search"},{"clic":"'"$ouv"'"},{"clic":"'"$PG_BTN_RAPPORT"'"},'"$ar"',{"nom":"e","obs":{}},{"nom":"ex","obs":{"mode":"attr","sel":"'"$ouv"'","attr":"aria-expanded"}},{"nom":"det","obs":{"mode":"compte","sel":".vf-rg-plus"}},{"nom":"f","obs":{"mode":"focus"}}]')"
  pg_ok "RG15.6 — vf-agent:ouvrir annulé (nom, rapport, ancre) : détail dans son état (replié), aucun lecteur, aucune requête, aucun vf-agent:lu, aucun défilement" "$o" \
    'j.out.e.evts.map((x) => x.type + ":" + x.declencheur).join() + "|" + j.out.ex.join() + "|" + j.out.det + "|" + j.out.e.fetchs.length + "|" + j.out.e.panneau.length + "|" + j.out.e.defilements.length' \
    "vf-agent:ouvrir:nom,vf-agent:ouvrir:rapport,vf-agent:ouvrir:ancre|false|0|0|0|0"
  o="$(pg_sc '' '[{"annuler":[]},'"$ar"',{"nom":"ex","obs":{"mode":"attr","sel":"'"$av"'","attr":"aria-expanded"}},{"nom":"e","obs":{}}]')"
  pg_ok "RG15.6 — non annulés : « ancre » déplie la ligne (défile et prend le focus)" "$o" 'j.out.ex.join() + "|" + j.out.e.evts.map((x) => x.declencheur).join()' "true|ancre"
}

rg15_cycle() {
  local o e='"source":"etat","coquille":{"onglet0":"code"},"surcouches":"pile"' v='{"declarerVue":{"id":"frise","libelle":"Frise"}}'
  o="$(pg_sc "$e" '[{"nom":"base","obs":{}},{"onglet":"equipe"},{"nom":"mon","obs":{}},{"onglet":"code"},{"nom":"fin","obs":{}},{"nom":"ex","obs":{"mode":"existe","sel":"#vf-equipe"}}]')"
  pg_ok "RG15.5 — rappel({onglet:'equipe'}) monte (conteneur, écouteurs vf-who/…/keydown/input, minuterie de 30 s, monte() vrai) ; la fonction rendue ramène écouteurs et minuteries au compte de départ, retire conteneur et classe" "$o" \
    '(j.out.base.monte === false) + "|" + (j.out.mon.monte === true) + "|" + (j.out.mon.minuteries - j.out.base.minuteries) + "|" + (j.out.mon.types.keydown > (j.out.base.types.keydown || 0)) + "|" + (j.out.mon.types.input > (j.out.base.types.input || 0)) + "|" + (j.out.mon.corps.includes("vf-regie-montee")) + "|" + (j.out.fin.ecouteurs === j.out.base.ecouteurs) + "|" + (j.out.fin.minuteries === j.out.base.minuteries) + "|" + (j.out.fin.monte === false) + "|" + j.out.ex + "|" + j.out.fin.corps.includes("vf-regie-montee")' \
    "true|true|1|true|true|true|true|true|true|false|false"
  o="$(pg_sc '"source":"live","coquille":{"onglet0":"code"}' '[{"nom":"base","obs":{}},{"onglet":"equipe"},{"nom":"mon","obs":{}}]')"
  pg_ok "RG15.5 — source vf-who : l'écouteur de vf-who et celui de vf-regie:aller sont posés au montage seulement" "$o" '(j.out.mon.types["vf-who"] > (j.out.base.types["vf-who"] || 0)) + "|" + (j.out.mon.types["vf-regie:aller"] > (j.out.base.types["vf-regie:aller"] || 0))' "true|true"
  pg_ok "RG15.5 — sans VF_COQUILLE : montage au chargement d'Équipe seulement" "$(pg_sc '"onglet":"code"' '[{"nom":"x","obs":{"mode":"compte","sel":"#vf-equipe"}}]')" 'j.out.x' "0"
  pg_ok "RG15.5 — sans VF_COQUILLE, onglet Équipe : monté au chargement" "$(pg_sc '' '[{"nom":"x","obs":{"mode":"compte","sel":"#vf-equipe"}}]')" 'j.out.x' "1"
  o="$(pg_sc "$e"',"sessionStorage":{"vibeflow-cockpit:equipe-vue":"frise"}' '[{"onglet":"equipe"},'"$v"',{"nom":"k0","obs":{}},{"onglet":"code"},{"onglet":"equipe"},{"nom":"k1","obs":{}},{"marquer":"#vf-equipe"},{"reexecuter":true},'"$v"',{"nom":"k2","obs":{}},{"nom":"n","obs":{"mode":"compte","sel":"#vf-equipe"}},{"nom":"m","obs":{"mode":"marques","sel":"#vf-equipe"}},{"nom":"sel","obs":{"mode":"attr","sel":"[role=\"tab\"]","attr":"aria-selected"}}]')"
  pg_ok "RG15.10 — départ puis retour, puis ré-exécution du fichier : un seul conteneur (nouveau), mêmes comptes d'écouteurs, un abonnement VF_ETAT par clé, une seule inscription de surOnglet à la clé du fichier, bascule restaurée depuis sessionStorage" "$o" \
    '(j.out.k1.types.keydown === j.out.k0.types.keydown) + "|" + (j.out.k2.types.keydown === j.out.k0.types.keydown) + "|" + (j.out.k2.ecouteurs === j.out.k0.ecouteurs) + "|" + (JSON.stringify(j.out.k2.abonnes) === JSON.stringify(j.out.k0.abonnes)) + "|" + Object.values(j.out.k2.abonnes).every((n) => n === 1) + "|" + j.out.k2.inscriptions.join() + "|" + j.out.n + "|" + j.out.m + "|" + j.out.sel.join() + "|" + (j.out.k2.minuteries === j.out.k0.minuteries)' \
    "true|true|true|true|true|72-vf-regie-source.js|1|0|false,true|true"
  assert_eq "RG15.10 — aucun des trois fichiers 72-vf-regie-*.js ne porte « vf-coquille: persistant » dans ses huit premières lignes (leur état est lié à un onglet)" \
    "$(for f in source rendu pied; do if [ -f "$UI/72-vf-regie-$f.js" ]; then head -8 "$UI/72-vf-regie-$f.js" | grep -c 'vf-coquille: persistant'; else echo absent; fi; done | tr '\n' ' ')" "0 0 0 "
}

rg15_echap() {
  local o d='li[data-vf-cle=\"au-travail:'"$PG_A"'\"] button.vf-rg-tog'
  local pre='{"clic":"'"$d"'"}' mana='{"saisie":"#search","valeur":"mana"}'
  local ex='{"nom":"EXN","obs":{"mode":"attr","sel":"'"$d"'","attr":"aria-expanded"}}'
  # (réel) surcouche factice ouverte (le lecteur de repli est retiré, 73-C2), pile simulée en capture sur window : la régie ne voit jamais l'appui
  o="$(pg_sc '"surcouches":"pile"' '['"$pre"',{"surcoucheFactice":true},'"$mana"',{"nom":"av","obs":{}},{"touche":"Escape","sur":"#search","nom":"p1"},{"nom":"ap","obs":{}},'"${ex/EXN/ex1}"',{"touche":"Escape","sur":"'"$d"'","nom":"p2"},'"${ex/EXN/ex2}"',{"nom":"f2","obs":{"mode":"focus"}},{"touche":"Escape","sur":"#search","nom":"p3"},{"nom":"r3","obs":{}},{"nom":"s3","obs":{"mode":"ser","sel":"#vf-equipe"}},{"touche":"Escape","sur":"#search","nom":"p4"},{"nom":"s4","obs":{"mode":"ser","sel":"#vf-equipe"}}]')"
  pg_ok "RG15.9 (réel) — lecteur ouvert : la pile le ferme (preventDefault) et l'appui n'atteint JAMAIS la régie ; détail et recherche inchangés" "$o" \
    'j.out.p1.prevenu + "|" + (j.out.ap.appels.keydown === j.out.av.appels.keydown) + "|" + j.out.ap.surcouches.some((x) => x.op === "fermee-par-pile") + "|" + j.out.ex1.join() + "|" + j.out.ap.recherche' "true|true|true|true|mana"
  pg_ok "RG15.9 — le lecteur fermé, trois appuis intacts : cran 2 (détail replié, focus au bouton du nom), cran 3 (recherche vidée), cran 4 (rien : DOM identique, defaultPrevented faux)" "$o" \
    'j.out.ex2.join() + "|" + j.out.f2.tag + ":" + j.out.f2.cle + "|" + j.out.r3.recherche + "|" + (j.out.s3 === j.out.s4) + "|" + j.out.p4.prevenu' "false|BUTTON:au-travail:$PG_A||true|false"
  # (forcé) appui déjà prévenu envoyé directement, ouverte() faux
  o="$(pg_sc '"surcouches":"pile"' '['"$pre"','"$mana"',{"nom":"s1","obs":{"mode":"ser","sel":"#vf-equipe"}},{"touche":"Escape","sur":"'"$d"'","prevenu":true,"nom":"p"},{"nom":"s2","obs":{"mode":"ser","sel":"#vf-equipe"}},'"${ex/EXN/ex}"',{"nom":"e","obs":{}}]')"
  pg_ok "RG15.9 (forcé) — appui avec defaultPrevented déjà vrai et ouverte() faux : la régie ne fait rien (DOM identique), sans lire ouverte()" "$o" '(j.out.s1 === j.out.s2) + "|" + j.out.ex.join() + "|" + j.out.e.recherche + "|" + j.out.e.ouverteLue' "true|true|mana|0"
  # (intact avec surcouche) terminal simulé, ouverte() vrai, l'appui arrive intact ; et sans VF_SURCOUCHES
  local sc='['"$pre"','"$mana"',{"touche":"Escape","sur":"'"$d"'"},'"${ex/EXN/ex2}"',{"touche":"Escape","sur":"#search"},{"nom":"r3","obs":{}},{"touche":"Escape","sur":"#search","nom":"p4"},{"nom":"e","obs":{}}]'
  o="$(pg_sc '"surcouches":"terminal"' "$sc")"
  pg_ok "RG15.9 (intact avec surcouche) — terminal ouvert, ouverte() vrai : la régie applique ses crans, sans lire ouverte() ; ni VF_SURCOUCHES.ouvrir ni VF_PANNEAU au montage" "$o" \
    'j.out.ex2.join() + "|" + j.out.r3.recherche + "|" + j.out.p4.prevenu + "|" + j.out.e.ouverteLue + "|" + j.out.e.panneauLu + "|" + j.out.e.surcouches.filter((x) => x.op === "ouvrir").length' "false||false|0|0|0"
  o="$(pg_sc '' "$sc")"
  pg_ok "RG15.9 — sans VF_SURCOUCHES (repli sans pile) : aucune exception et les crans 2 à 4 tiennent" "$o" 'j.out.ex2.join() + "|" + j.out.r3.recherche + "|" + j.out.p4.prevenu' "false||false"
}

rg_RG16_page() {
  local o rows='li[data-vf-cle] .vf-rg-nom'
  o="$(pg_sc '' '[{"nom":"tous","obs":{"mode":"visibles","sel":"'"$rows"'"}},{"saisie":"#search","valeur":"mana"},{"nom":"m","obs":{"mode":"visibles","sel":"'"$rows"'"}},{"nom":"sm","obs":{"mode":"visiblesAttr","sel":"section.vf-rg-sec","attr":"data-vf-section"}},{"touche":"Enter","sur":"#search"},{"nom":"f","obs":{"mode":"focus"}},{"saisie":"#search","valeur":"zzzz"},{"nom":"z","obs":{"mode":"visibles","sel":"'"$rows"'"}},{"nom":"nt","obs":{"mode":"visibles","sel":".vf-rg-note"}},{"saisie":"#search","valeur":""},{"nom":"v","obs":{"mode":"visibles","sel":"'"$rows"'"}},{"nom":"sv","obs":{"mode":"visiblesAttr","sel":"section.vf-rg-sec","attr":"data-vf-section"}}]')"
  pg_ok "RG16.1 — « mana » : seules les lignes dont le nom ou le rôle visible contient « mana » restent (la ligne du vf-dev-manager, pas les autres) ; sections sans ligne masquées" "$o" \
    'j.out.m.includes("vf-dev-manager") + "|" + j.out.m.includes("Écrire le rendu") + "|" + j.out.m.includes("Relire le plan") + "|" + j.out.sm.includes("au-travail") + "|" + j.out.sm.includes("a-relire") + "|" + j.out.sm.includes("au-repos")' "true|false|false|true|false|false"
  pg_ok "RG16.1 — Entrée dans la recherche : le focus va à la première ligne retenue" "$o" 'j.out.f.cle' "au-travail:$PG_A"
  pg_ok "RG16.1 — aucune correspondance : « Aucun agent ne correspond » avec sa résolution ; champ vidé : tout revient et les quatre sections" "$o" \
    'j.out.z.length + "|" + j.out.nt.some((t) => t.includes("Aucun agent ne correspond") && t.length > 40) + "|" + (j.out.v.length === j.out.tous.length) + "|" + j.out.sv.length' "0|true|true|4"
}

rg_RG0_ordre_pied() {
  cat > "$AUX/ordre-pied.mjs" <<'JS'
// ordre-pied.mjs <html> : « ok » si le repère du pied existe une fois et vient avant celui de la source (la source monte le pied) ; « faux:… » sinon
import fs from 'node:fs';
let t; try { t = fs.readFileSync(process.argv[2], 'utf8'); } catch { console.log('illisible'); process.exit(0); }
const m = (n) => `/* ui/${n} */`, n = (s) => t.split(s).length - 1, p = t.indexOf(m('72-vf-regie-pied.js')), s = t.indexOf(m('72-vf-regie-source.js'));
console.log(n(m('72-vf-regie-pied.js')) === 1 && p >= 0 && s > p ? 'ok' : `faux:pied ×${n(m('72-vf-regie-pied.js'))}`);
JS
  local L="$WORK/ordq-lab" r="" f; mkdir -p "$L/src" "$L/.planning"; printf 'x\n' > "$L/src/u.js"; printf '## Phases\n\n- [ ] **Phase 1: Socle** - jet\n' > "$L/.planning/ROADMAP.md"
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/ordq-build.out" 2>&1
  for f in index.html project.html; do r="$r$f=$(node "$AUX/ordre-pied.mjs" "$L/.vibeflow/cockpit/$f" 2>&1) "; done
  assert_eq "RG0.12 — le pied de la régie existe une fois et se charge avant sa source" "$r" "index.html=ok project.html=ok "
}

rg_RG1_etats() {
  local o ev='{"workers":[{"kind":"session","id":"s0000000-aaaa-bbbb-cccc-111111111111","etat":"actif","titre":"Atelier alpha","tree":".","ageS":10,"dureeS":40}]}'
  local note='{"nom":"NN","obs":{"mode":"visibles","sel":".vf-rg-note"}}' busy='{"nom":"BB","obs":{"mode":"attr","sel":"#vf-equipe","attr":"aria-busy"}}'
  o="$(pg_sc '"who":null' '['"${busy/BB/b0}"','"${note/NN/n0}"',{"avancer":160},'"${busy/BB/b1}"','"${note/NN/n1}"',{"poser":{"who":'"$ev"'}},'"${busy/BB/b2}"','"${note/NN/n2}"']')"
  pg_ok "RG1.12 (états) — avant le premier who : aria-busy tout de suite, « Lecture de l'équipe » au-delà de 150 ms seulement ; au premier who, ni l'un ni l'autre" "$o" \
    'j.out.b0.join() + "|" + j.out.n0.length + "|" + j.out.b1.join() + "|" + j.out.n1.join() + "|" + j.out.b2.join() + "|" + j.out.n2.length' "true|0|true|Lecture de l'équipe||0"
  o="$(pg_sc '"who":{"workers":[]}' '[{"nom":"n","obs":{"mode":"textes","sel":".vf-rg-note p"}},{"nom":"h2","obs":{"mode":"compte","sel":"#vf-equipe h2"}}]')"
  pg_ok "RG1.12 (états) — aucun agent : la boîte dit ses deux phrases, les quatre titres sont gardés" "$o" 'j.out.n.join(" | ") + "|" + j.out.h2' \
    "Aucun agent dans les dernières 24 h. | Les sessions de ce dépôt apparaîtront ici dès qu'elles écrivent.|4"
  o="$(pg_sc '"serveur":false' '[{"nom":"n","obs":{"mode":"visibles","sel":".vf-rg-note p"}},{"nom":"h2","obs":{"mode":"visibles","sel":"#vf-equipe h2"}}]')"
  pg_ok "RG1.12 (états) — page sans FLOORPLAN_SERVER : seulement la boîte « Le direct n'est pas branché. » avec sa résolution, aucune section" "$o" 'j.out.n.join(" | ") + "|" + j.out.h2.length' \
    "Le direct n'est pas branché. | Ouvrez le cockpit depuis le projet pour voir l'équipe.|0"
  local err lue; err="$(printf '%s' "$ev" | sed 's/^{"workers"/{"sources":{"sessions":{"etat":"erreur"}},"workers"/')"; lue="$(printf '%s' "$ev" | sed 's/^{"workers"/{"sources":{"sessions":{"etat":"lue"}},"workers"/')"
  o="$(pg_sc '"who":'"$err" '[{"nom":"a","obs":{"mode":"visibles","sel":".vf-rg-source"}},{"poser":{"who":'"$lue"'}},{"nom":"b","obs":{"mode":"visibles","sel":".vf-rg-source"}}]')"
  pg_ok "RG1.12 (états) — source illisible : pied « Source illisible : Sessions et sous-agents », qui disparaît à la poussée suivante où la source est lue" "$o" \
    'j.out.a.map((t) => t.replace(/ /g, " ")).join() + "|" + j.out.b.length' "Source illisible : Sessions et sous-agents|0"
  local dur='{"nom":"DD","obs":{"mode":"textes","sel":".vf-rg-dur"}}' dc='{"nom":"CC","obs":{"mode":"compte","sel":".vf-rg-direct"}}'
  o="$(pg_sc '"source":"etat","who":'"$ev" '[{"conn":"perdu"},{"avancer":10000},'"${dc/CC/c10}"',{"avancer":6000},'"${dc/CC/c16}"','"${dur/DD/d16}"',{"avancer":30000},'"${dur/DD/d46}"',{"nom":"txt","obs":{"mode":"textes","sel":".vf-rg-direct"}},{"conn":"ouvert"},'"${dc/CC/cfin}"']')"
  pg_ok "RG1.12 (états) — direct coupé : rien avant 15 s ; à 16 s la ligne « Direct coupé : durées figées, données d'il y a … » ; les durées ne bougent plus ; la reconnexion la retire" "$o" \
    'j.out.c10 + "|" + j.out.c16 + "|" + (j.out.d16.join() === j.out.d46.join()) + "|" + j.out.txt.join().replace(/ /g, " ").startsWith("Direct coupé : durées figées, données d\u0027il y a") + "|" + j.out.cfin' "0|1|true|true|0"
}

# ---------- sections navigateur (CDP) : sans Chrome hors CI elles disent « NON VÉRIFIÉ » et ne comptent aucun PASS ----------
rg_RG1_chrome() {
  rg_chrome || return 0
  rg_page montage "$WORK/pg-montage.json"
  pg_ok "RG1.20 — sur Équipe : #stage non affiché, section#vf-equipe seule région principale visible, quatre titres" "$WORK/pg-montage.json" \
    'j.stage + "|" + j.mains.join() + "|" + j.h2.length' "none|vf-equipe|4"
  pg_ok "RG1.20 — aucun défilement horizontal à 375, 700, 768, 1 000 et 1 440 px (mesuré une fois posé)" "$WORK/pg-montage.json" \
    '[375, 700, 768, 1000, 1440].map((w) => j.defil[w]).join()' "0,0,0,0,0"
}

rg_RG6_chrome() {
  rg_chrome || return 0
  rg_page fuite-verrou "$WORK/pg-fuite.json"
  pg_ok "RG6.20 — témoin positif : la ligne de mission « verrou : … » s'affiche pour un événement lock à forme projetée (le négatif ne prouve rien sans lui)" "$WORK/pg-fuite.json" \
    '/verrou/i.test(j.positif) + "|" + j.jeton + "|" + j.exportStatut' "true|true|200"
  pg_ok "RG6.20 — avec identifiant de session, chemin, emplacement et durée de bail sentinelles : aucune dans le HTML, localStorage, sessionStorage ni l'export" "$WORK/pg-fuite.json" \
    'j.html.length + "|" + j.local.length + "|" + j.session.length + "|" + j.export.length' "0|0|0|0"
  # M-VERROU-PAGE-BRUT : la page pose l'objet lock BRUT dans un attribut de la régie (copie jetable du module, jamais le dépôt) : la garde de non-fuite doit rougir
  local v
  if cockpit_module_muter_page verrou-brut 's|ui.rendre(m, { sections: !sansDirect });|&racine.setAttribute("data-vf-lock", JSON.stringify(A.lock()));|' 2> "$WORK/mut-verrou.err"; then
    rg_page fuite-verrou "$WORK/pg-fuite-mut.json"
    v="$(pg_g "$WORK/pg-fuite-mut.json" 'j.html.length + "|" + j.local.length + "|" + j.session.length + "|" + j.export.length')"
    assert_eq "M-VERROU-PAGE-BRUT — l'objet lock brut dans un attribut de la page : la non-fuite rougit (mutant tué)" "$([ "$v" != "0|0|0|0" ] && [[ "$v" != ERR:* ]] && echo tue || echo "survivant:$v")" "tue"
  else assert_eq "M-VERROU-PAGE-BRUT — ancre présente dans les sources de page" "$(cat "$WORK/mut-verrou.err")" "muté"; fi
  unset COCKPIT_MODULE
}
