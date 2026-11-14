# regie-rg-retrait.sh — fragment du plan 73-08, SOURCÉ par test-cockpit-regie.sh (ne définit que des fonctions) : le canevas d'Équipe retiré (REGI-03, REGI-14, REGI-16 ;
#   P73-D-03, P73-D-04, P73-D-17, P73-D-18).
#   RG3_retrait  : enveloppe cockpit-equipe@1 sans cartes (RG3.1, RG3.2), aucun rechargement de page et une ligne par clé (RG3.3), moteur non touché (RG3.4),
#                  enveloppe construite une seule fois (RG3.5), aucune clé vf-equipe-* en stockage (RG3.6), garde d'émission de la page Équipe (RG3.7, un mutant)
#   RG14_retrait : santé ni calculée ni montrée (RG14.3, garde de non-régression : verte dès la base), aucun bouton de commande ni de transcript sur Équipe (RG14.30)
# L'enveloppe est lue dans l'objet que sert la route GET /api/vf/graphe?onglet=equipe (vf-cockpit-graphe.mjs, 79-15) : la construction vit là depuis la coquille de la 79.
# Mutant : un seul, sur la garde d'émission mémoïsée (régime allégé : pas de mutant hors garde). Fixtures : noms et identifiants inventés.

[ -n "${RG_PAGE_COMMUN:-}" ] || { . "$TESTS_DIR/regie-page-commun.sh"; RG_PAGE_COMMUN=1; }
RT_FICH='"fichiers":["71-vf-equipe-rendu.js","72-vf-equipe.js","72-vf-regie-modele.js","72-vf-regie-pied.js","72-vf-regie-rendu.js","72-vf-regie-source.js"]'
RT_PARENT='s0000000-aaaa-bbbb-cccc-111111111111'
RT_C1='{"kind":"subagent","id":"c1c1c1c1c1c1","etat":"actif","parent":"'"$RT_PARENT"'","role":"vf-coder","task":"Neuf un","ageS":2,"dureeS":10,"tree":"."}'
RT_C2='{"kind":"subagent","id":"c2c2c2c2c2c2","etat":"actif","parent":"'"$RT_PARENT"'","role":"vf-coder","task":"Neuf deux","ageS":1,"dureeS":5,"tree":"."}'

rt_aux() {
  cat > "$AUX/enveloppe.mjs" <<'JS'
// enveloppe.mjs <scripts> <mode> : l'enveloppe de l'onglet Équipe telle que la route la sert (creerGraphes de <scripts>). Modes : forme · json · memo · garde
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const [, , scripts, mode] = process.argv;
const { creerGraphes } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-graphe.mjs')).href);
const S = 's0000000-aaaa-bbbb-cccc-111111111111';
const trois = (n = 0) => ({ workers: [
  { kind: 'session', id: S, etat: 'actif', titre: 'Atelier', tree: '.', ageS: 5 + n },
  { kind: 'subagent', id: 'a1b2c3d4e5f6', etat: n % 2 ? 'termine' : 'actif', parent: S, role: 'vf-coder', task: 'Écrire', tree: '.' },
  { kind: 'subagent', id: 'b9b9b9b9b9b9', etat: 'actif', parent: S, role: 'vf-reviewer', tree: '.' }], sources: { sessions: { etat: 'lue' } }, fenetre: 86400 });
const neuf = () => { const G = creerGraphes({ nomDe: () => 'lab', gardeWho: (w) => !JSON.stringify(w || {}).includes('"doing"') }); G.recharger(''); return G; };
const dormir = (ms) => new Promise((r) => setTimeout(r, ms));
const G = neuf();
if (mode === 'forme' || mode === 'json') {
  G.maj({ who: trois(0), lancees: new Map() });
  const g = G.courant('equipe').g, t = JSON.stringify(g);
  if (mode === 'json') console.log(t);
  else console.log(JSON.stringify({ schema: g.schema, nodes: g.nodes.length, vfTab: g.meta.vfTab, compte: g.meta.vf.compte, missions: Array.isArray(g.meta.vf.missions), kinds: Object.keys(g.meta.kindLabels).length, health: t.includes('health'), carte: t.includes('se-') || t.includes('ag-') }));
} else if (mode === 'memo') {
  G.maj({ who: trois(0), lancees: new Map() });
  const vus = new Set([G.courant('equipe').g]), sig0 = G.courant('equipe').sig;
  for (let i = 1; i <= 10; i++) { await dormir(3); G.maj({ who: trois(i), lancees: new Map([['x' + i, { phase: '1', ws: null, verbe: 'executer' }]]) }); vus.add(G.courant('equipe').g); }
  console.log(`constructions=${vus.size} signature-stable=${G.courant('equipe').sig === sig0}`);
} else if (mode === 'garde') {
  G.maj({ who: trois(0) });
  const a = G.courant('equipe').interdit === true ? 'interdit' : 'ok';
  const mauvais = trois(1); mauvais.workers[0].doing = 'x';
  G.maj({ who: mauvais });
  const b = G.courant('equipe').interdit === true ? 'interdit' : 'ok';
  G.maj({ who: trois(2) });
  const c = G.courant('equipe').interdit === true ? 'interdit' : 'ok';
  console.log([a, b, c].join('|'));
}
JS
}

rg_RG3_retrait() {
  local o L g c sonde_garde
  rt_aux
  # RG3.1 — l'enveloppe sans cartes : schéma gardé, meta conservée (P73-D-03)
  o="$(node "$AUX/enveloppe.mjs" "$SCRIPTS" forme 2>&1)"
  echo "$o" > "$WORK/rt-forme.json"
  assert_eq "RG3.1 — enveloppe d'un lab à trois agents : schéma cockpit-equipe@1, nodes vide, meta (vfTab, vf.compte, vf.missions, kindLabels) conservée, aucune carte" "$(G "$WORK/rt-forme.json" 'j.erreur||(j.schema+"|"+j.nodes+"|"+j.vfTab+"|"+JSON.stringify(j.compte)+"|"+j.missions+"|"+j.kinds+"|"+j.carte)' 2>/dev/null || echo illisible)" \
    'vibeflow/cockpit-equipe@1|0|equipe|{"actif":3,"enAttente":0,"auRepos":0,"attend":0,"termine":0}|true|6|false'
  # RG3.2 — valide contre le bloc du contrat (requis, meta.requis, interdits), même propriété qu'E23.5
  node "$AUX/enveloppe.mjs" "$SCRIPTS" json > "$WORK/rt-env.json" 2>&1
  cat > "$AUX/rt-valide.mjs" <<'JS'
// rt-valide.mjs <interface.json> <sortie.json> : « OK » ou la liste des écarts au bloc vibeflow/cockpit-equipe@1
import fs from 'node:fs';
const id = 'vibeflow/cockpit-equipe@1', spec = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')).schemas?.[id];
if (!spec) { console.log('KO bloc absent'); process.exit(0); }
let out; try { out = JSON.parse(fs.readFileSync(process.argv[3], 'utf8')); } catch { console.log('KO sortie illisible'); process.exit(0); }
const e = [], type = (v) => (Array.isArray(v) ? 'array' : v === null ? 'null' : typeof v);
for (const [k, t] of Object.entries(spec.requis || {})) { if (!(k in out)) e.push('absent:' + k); else if (t !== 'any' && type(out[k]) !== t) e.push('type:' + k); }
if (out.schema !== id) e.push('schema');
for (const k of spec.meta?.requis || []) if (!(k in (out.meta || {}))) e.push('meta:' + k);
const deep = (o) => { if (o && typeof o === 'object') for (const [k, v] of Object.entries(o)) { if ((spec.interdits || []).includes(k)) e.push('interdit:' + k); deep(v); } };
deep(out);
console.log(e.length ? 'KO ' + e.join(',') : 'OK');
JS
  assert_eq "RG3.2 — l'enveloppe sans cartes est valide contre le bloc vibeflow/cockpit-equipe@1 de vf-cockpit-interface.json (requis, meta.requis, interdits)" "$(node "$AUX/rt-valide.mjs" "$SCRIPTS/vf-cockpit-interface.json" "$WORK/rt-env.json")" "OK"
  # RG3.3 — 72 réduit et régie : trois poussées qui changent l'ensemble des agents
  local w2 w3 w4 btn="$PG_BTN_A"
  w2="${PG_WHO%]\}},$RT_C1]}"; w3="${PG_WHO%]\}},$RT_C1,$RT_C2]}"; w4="${PG_WHO%]\}},$RT_C1]}"
  o="$(pg_sc "$RT_FICH" '[{"focus":"'"$btn"'"},{"poser":{"who":'"$w2"'}},{"poser":{"who":'"$w3"'}},{"poser":{"who":'"$w4"'}},{"avancer":30000},{"nom":"f","obs":{"mode":"focus"}},{"nom":"cles","obs":{"mode":"attr","sel":"li[data-vf-cle]","attr":"data-vf-cle"}},{"nom":"e","obs":{}}]')"
  pg_ok "RG3.3 — trois poussées qui changent l'ensemble des agents (+1, +1, −1) puis 30 s : 0 rechargement, 0 rendu du moteur, une seule li par clé, focus resté sur la ligne" "$o" \
    '(j.final.rechargements || 0) + "|" + j.out.e.sc.filter((x) => x === "rerender").length + "|" + (new Set(j.out.cles).size === j.out.cles.length) + "|" + j.out.f.cle' "0|0|true|au-travail:$PG_A"
  # RG3.4 — le moteur n'est pas touché : viewer.html et 20-health.js ne connaissent ni la régie ni le retrait
  assert_eq "RG3.4 — viewer.html et ui/20-health.js ne portent aucune trace de la régie ni de la ligne de lancement (moteur retrouvé tel quel)" "$(cat "$UI/../viewer.html" "$UI/20-health.js" | grep -c -e '__vfRegie' -e 'vf-equipe' -e 'lancees')" "0"
  # RG3.5 — dix poussées de who : l'enveloppe n'est construite qu'une fois (la signature, donc l'ETag de la route, ne bouge plus)
  assert_eq "RG3.5 — dix poussées de who (et dix tables de lancement) : une seule construction de l'enveloppe, signature stable" "$(node "$AUX/enveloppe.mjs" "$SCRIPTS" memo 2>&1)" "constructions=1 signature-stable=true"
  # RG3.6 — après un parcours (arrivée sur un agent, changement d'ensemble, rechargement de la page), aucune clé vf-equipe-* écrite
  o="$(pg_sc "$RT_FICH" '[{"appel":"__vfRegie.arriver","args":["n:ag-'"$PG_A"'"]},{"poser":{"who":'"$w2"'}},{"poser":{"who":'"$w3"'}},{"reexecuter":true},{"poser":{"who":'"$w4"'}},{"avancer":30000},{"nom":"e","obs":{}}]')"
  pg_ok "RG3.6 — après un parcours, aucune clé vf-equipe-* dans le stockage de session et aucun rechargement" "$o" \
    'j.final.stockage.filter((k) => k.startsWith("vf-equipe-")).length + "|" + (j.final.rechargements || 0)' "0|0"
  # RG3.7 — la garde d'émission de la page Équipe : un who qui porte une clé interdite ferme l'onglet, même quand l'enveloppe est mémoïsée ; un mutant sur la garde
  assert_eq "RG3.7 — garde d'émission : who sain, puis who portant une clé interdite (enveloppe fermée), puis who sain (rouverte)" "$(node "$AUX/enveloppe.mjs" "$SCRIPTS" garde 2>&1)" "ok|interdit|ok"
  sonde_garde() { node "$AUX/enveloppe.mjs" "$1" garde 2>&1; }
  rg_mutant GARDE-MEMO "la garde n'est plus rejouée quand le gabarit n'a pas changé (enveloppe mémoïsée servie telle quelle)" "$SCRIPTS" vf-cockpit-graphe.mjs \
    "if (gardeWho(who)) { // garde:graphe-equipe" "if (mE.fait || gardeWho(who)) { // garde:graphe-equipe" sonde_garde "ok|interdit|ok"
}

rg_RG14_retrait() {
  local o w2
  rt_aux
  # RG14.3 — garde de non-régression (A2) : verte dès la base ; la santé contrôle le code, elle n'est ni calculée ni montrée sur Équipe
  node "$AUX/enveloppe.mjs" "$SCRIPTS" forme > "$WORK/rt-forme14.json" 2>&1
  o="$(pg_sc '' '[{"nom":"h2","obs":{"mode":"textes","sel":"#vf-equipe h2"}},{"nom":"sante","obs":{"mode":"compte","sel":"#vf-equipe [data-hc-open]"}}]')"
  assert_eq "RG14.3 — santé : aucun champ health dans l'enveloppe, la règle de feuille d'Équipe (00-vibeflow.js) masque #btn-health, aucun titre ni lien Santé dans section#vf-equipe" \
    "$(G "$WORK/rt-forme14.json" 'j.health')|$(grep -c "TAB === 'equipe') style.textContent += '#btn-health" "$UI/00-vibeflow.js")|$(pg_g "$o" 'j.out.h2.filter((s) => /Sant/.test(s)).length + "|" + j.out.sante')" "false|1|0|0"
  # RG14.30 — aucun contrôle de la page Équipe ne porte plus de commande ni de transcript à la demande
  w2="${PG_WHO%]\}},$RT_C1]}"
  o="$(pg_sc "$RT_FICH" '[{"appel":"__vfRegie.arriver","args":["n:ag-'"$PG_A"'"]},{"poser":{"who":'"$w2"'}},{"nom":"a","obs":{"mode":"compte","sel":"#vf-equipe [data-vf-doing]"}},{"nom":"b","obs":{"mode":"compte","sel":"#vf-equipe [data-vf-transcript]"}},{"nom":"c","obs":{"mode":"compte","sel":"#panel [data-vf-doing]"}},{"nom":"d","obs":{"mode":"compte","sel":"#panel [data-vf-transcript]"}}]')"
  assert_eq "RG14.30 — aucun élément de la page Équipe (régie, panneau) ne porte data-vf-doing ni data-vf-transcript, et 72-vf-equipe.js n'en construit plus" \
    "$(grep -c -e 'data-vf-doing' -e 'data-vf-transcript' "$UI/72-vf-equipe.js")|$(pg_g "$o" '[j.out.a, j.out.b, j.out.c, j.out.d].join(",")')" "0|0,0,0,0"
}
