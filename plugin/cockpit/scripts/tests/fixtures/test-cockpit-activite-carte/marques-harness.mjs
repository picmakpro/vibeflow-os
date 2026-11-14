// Fait tourner ui/75-vf-marques.js dans un faux navigateur minimal (vm) et rend, une ligne « clé=valeur » par observation.
// usage : node marques-harness.mjs <module.js>   (stdout : D1.api=… ; un module illisible rend D1.api=ABSENT et rien d'autre)
import fs from 'node:fs';
import vm from 'node:vm';

const fichier = process.argv[2];
const sortie = [];
const dire = (k, v) => sortie.push(`${k}=${typeof v === 'string' ? v : JSON.stringify(v)}`);
let code;
try { code = fs.readFileSync(fichier, 'utf8'); } catch { dire('D1.api', 'ABSENT'); console.log(sortie.join('\n')); process.exit(0); }

// l'arbre du moteur : chain(id) = [id, parent, …, 'root'] (la forme de Floorplan.chain)
const PARENT = { 'f:a': 'n:x', 'f:b': 'n:x', 'f:c': 'n:y', 'f:d': 'n:y', 'f:e': 'n:na', 'n:x': 'n:top', 'n:y': 'n:top', 'n:na': 'root', 'n:top': 'root' };
const chain = (id) => { const o = [id]; for (let p = PARENT[id]; p; p = PARENT[p]) o.push(p); if (id !== 'root' && o[o.length - 1] !== 'root') o.push('root'); return o; };

function moteurFaux() {
  const ecouteurs = [], compte = { render: 0, rerender: 0 };
  const VibeFlow = Object.freeze({ chain, on: (ev, fn) => { if (ev === 'render') ecouteurs.push(fn); }, render: () => { compte.render++; },
    rerender: () => { compte.rerender++; } });
  return { VibeFlow, ecouteurs, compte, emettre: () => ecouteurs.slice().forEach((f) => f()) };
}

// la coquille : même règle de `cle` (une inscription de même cle REMPLACE la précédente, son nettoyage est appelé d'abord) et mêmes moments d'appel que vf-coquille.js
function coquilleFausse(rejouer) {
  const K = { inscriptions: [], affiche: null, enDemarrage: false };
  const nettoyer = (i) => { const f = i.nettoyage; i.nettoyage = null; if (f) f(); };
  const appeler = (i) => { const r = i.rappel({ onglet: K.affiche }); i.nettoyage = typeof r === 'function' ? r : null; };
  K.surOnglet = (rappel, o) => {
    const cle = o && Object.hasOwn(o, 'cle') ? o.cle : undefined;
    const r = cle === undefined ? null : K.inscriptions.find((i) => i.cle === cle);
    if (r) { r.actif = false; nettoyer(r); K.inscriptions.splice(K.inscriptions.indexOf(r), 1); }
    const ins = { rappel, cle, nettoyage: null, actif: true, demarrage: K.enDemarrage };
    K.inscriptions.push(ins);
    if (K.affiche !== null && !K.enDemarrage) appeler(ins);
    return () => { ins.actif = false; nettoyer(ins); };
  };
  K.arriver = (nom) => {
    for (const i of [...K.inscriptions].reverse()) nettoyer(i);
    for (const i of K.inscriptions.splice(0)) if (!i.demarrage) K.inscriptions.push(i);
    K.enDemarrage = true; rejouer(); K.enDemarrage = false;
    K.affiche = nom;
    for (const i of [...K.inscriptions]) appeler(i);
  };
  K.rejeu = () => rejouer();
  return K;
}

function monde({ avecMoteur = true, avecCoquille = false, file } = {}) {
  const M = avecMoteur ? moteurFaux() : null;
  const win = { console };
  if (M) win.VibeFlow = M.VibeFlow;
  if (file) win.VF_MARQUES_EN_ATTENTE = file;
  const ctx = vm.createContext({ window: win, console, document: {} });
  const charger = () => vm.runInContext(code, ctx, { filename: 'marques.js' });
  const K = avecCoquille ? coquilleFausse(charger) : null;
  if (K) win.VF_COQUILLE = Object.freeze({ surOnglet: K.surOnglet });
  return { win, M, K, charger };
}
const noms = (ms) => ms.map((m) => m.couche).join('+');
const tab = (ids, p) => ids.map((id) => [id, p, 'g', `m-${id}`, `i-${id}`]);

// ---- D1 : le canal existe, l'objet gelé du moteur n'est jamais étendu, aucune relance du placement ----
{
  const w = monde(); const avant = Object.keys(w.win.VibeFlow).join(',');
  w.charger();
  const V = w.win.VF_MARQUES;
  dire('D1.api', V ? ['poser', 'retirer', 'active', 'lire'].map((n) => `${n}:${typeof V[n]}`).join(' ') : 'ABSENT');
  if (V) {
    V.poser('x', tab(['f:a'], 'bas')); V.retirer('x'); V.poser('y', tab(['f:b'], 'haut'), { exclusif: false });
    dire('D1.moteur-gele', Object.isFrozen(w.win.VibeFlow));
    dire('D1.moteur-cles', Object.keys(w.win.VibeFlow).join(',') === avant);
    dire('D1.canal-gele', Object.isFrozen(V));
    dire('D1.relances', `${w.M.compte.render}+${w.M.compte.rerender}`);
  }
}
if (!sortie.some((l) => l.startsWith('D1.relances='))) { console.log(sortie.join('\n')); process.exit(0); }

// ---- D2 : couches exclusives, pile ----
{
  const w = monde(); w.charger(); const V = w.win.VF_MARQUES;
  V.poser('a', tab(['f:a'], 'bas')); V.poser('b', tab(['f:b'], 'haut'));
  dire('D2.b-seule', `${V.active()}|${V.lire('f:a').length}|${noms(V.lire('f:b'))}`);
  dire('D2.retrait-de-b', `${V.retirer('b')}|${V.active()}|${noms(V.lire('f:a'))}|${V.lire('f:b').length}`);
  V.poser('b', tab(['f:b'], 'haut')); V.poser('a', tab(['f:a'], 'moyen'));
  dire('D2.repose-passe-dessus', `${V.active()}|${V.lire('f:b').length}|${V.lire('f:a')[0].palier}`);
  dire('D2.retrait-inconnu', `${V.retirer('zz')}|${V.retirer('a')}|${V.retirer('b')}|${V.active()}`);
  dire('D2.refus', [V.poser('', []), V.poser('x', 'pas une table'), V.poser(null, [])].join(','));
}

// ---- D2b : couche non exclusive visible en même temps que l'exclusive ----
{
  const w = monde(); w.charger(); const V = w.win.VF_MARQUES;
  V.poser('a', tab(['f:a'], 'bas')); V.poser('col', [['f:a', 'agents', 'confluent', 'écrit par 2 agents', '']], { exclusif: false });
  dire('D2b.ensemble', noms(V.lire('f:a')));
  V.poser('b', tab(['f:b'], 'haut'));
  dire('D2b.exclusive-masque-l-autre-exclusive-pas-la-non-exclusive', `${noms(V.lire('f:a'))}|${noms(V.lire('f:b'))}|${V.active()}`);
  V.retirer('b'); dire('D2b.apres-retrait', noms(V.lire('f:a')));
  V.retirer('a'); dire('D2b.exclusive-retiree-ne-touche-pas-l-autre', `${noms(V.lire('f:a'))}|${V.active()}`);
}

// ---- D5 : agrégat aux ancêtres : palier maximal et compte, jamais une somme ----
{
  const w = monde(); w.charger(); const V = w.win.VF_MARQUES;
  V.poser('chauds', [...tab(['f:a', 'f:b', 'f:e'], 'haut'), ...tab(['f:c'], 'moyen'), ...tab(['f:d'], 'bas')]);
  const m = (id) => { const l = V.lire(id); return l.length === 1 ? `${l[0].palier}|${l[0].compte}|${l[0].mot}|${l[0].agrege}` : `lignes:${l.length}`; };
  dire('D5.noeud-x', m('n:x')); dire('D5.noeud-y', m('n:y')); dire('D5.noeud-haut', m('n:top')); dire('D5.non-assignes', m('n:na'));
  dire('D5.carte-propre', `${V.lire('f:a')[0].agrege}|${V.lire('root').length}`);
  V.poser('bas', [...tab(['f:c', 'f:d'], 'bas')]);
  dire('D5.tous-bas', m('n:y'));
  V.poser('col', [['f:a', 'agents', 'c', 'x', ''], ['f:a', 'branches', 'c', 'x', ''], ['f:c', 'arbres', 'c', 'x', '']], { exclusif: false });
  const col = V.lire('n:top').filter((x) => x.couche === 'col');
  dire('D5.collisions-en-fichiers', `${col.length}|${col[0].compte}|${col[0].mot}|${col[0].palier}`);
  dire('D5.un-fichier', (() => { V.poser('un', tab(['f:a'], 'haut'), { exclusif: false }); return V.lire('n:x').filter((x) => x.couche === 'un')[0].mot; })());
  const sans = monde({ avecMoteur: false }); sans.charger();
  dire('D5.sans-moteur', `${sans.win.VF_MARQUES.poser('c', tab(['f:a'], 'haut'))}|${sans.win.VF_MARQUES.lire('n:x').length}|${sans.win.VF_MARQUES.lire('f:a').length}`);
}

// ---- D5b : données hostiles : identifiants et textes littéraux, aucune pollution ----
{
  const w = monde(); w.charger(); const V = w.win.VF_MARQUES;
  V.poser('h', [['__proto__', 'bas', 'g', '<img onerror=x> ', '"\'</script>'], ['constructor', 'bas', 'g', 'm', 'i'], [7, 'bas'], null, ['', 'bas']]);
  dire('D5b.hostiles', `${V.lire('__proto__')[0].mot === '<img onerror=x> '}|${V.lire('constructor').length}|${V.table().length}|${({}).bas}|${typeof ({}).mot}`);
  dire('D5b.long', V.poser('l', [['f:a', 'bas', 'g', 'x'.repeat(5000), 'y'.repeat(5000)]]) && `${V.lire('f:a')[0].mot.length}|${V.lire('f:a')[0].infobulle.length}`);
}

// ---- D18 : inscription par cle, nettoyage, aucun doublement ----
{
  const w = monde({ avecCoquille: true }); w.charger(); const K = w.K;
  const cles = () => K.inscriptions.filter((i) => i.cle === '75-vf-marques.js').length;
  const suite = [];
  for (const o of ['code', 'projet', 'code', 'projet', 'code']) {
    K.arriver(o);
    const V = w.win.VF_MARQUES; const posee = V.poser('a', tab(['f:a'], 'bas')); V.poser('col', tab(['f:a'], 'agents'), { exclusif: false });
    suite.push(`${o}:${cles()}:${posee}:${V.lire('f:a').length}:${w.M.ecouteurs.length}`);
  }
  dire('D18.arrivees', suite.join(' '));
  const avant = `${cles()}|${K.inscriptions.length}|${w.M.ecouteurs.length}`;
  K.rejeu(); K.rejeu();
  const V = w.win.VF_MARQUES; V.poser('a', tab(['f:a'], 'bas'));
  dire('D18.rejeu', `${avant}->${cles()}|${K.inscriptions.length}|${w.M.ecouteurs.length}|${V.lire('f:a').length}`);
  K.arriver('projet'); dire('D18.projet-vide', `${w.win.VF_MARQUES.lire('f:a').length}|${w.win.VF_MARQUES.active()}`);
}

// ---- D19 : le point d'entrée du dessin, tolérant ; réapplication à `render`, muet une fois fermé ----
{
  const w = monde({ avecCoquille: true }); w.charger(); w.K.arriver('code'); const V = w.win.VF_MARQUES; let n = 0, vu = '';
  V.brancherDessin(({ table }) => { n++; vu = table.map(([id, ms]) => `${id}:${ms.length}`).join(','); });
  const a0 = n; V.poser('a', tab(['f:a'], 'bas')); const a1 = n; w.M.emettre(); const a2 = n;
  dire('D19.dessin', `${a1 - a0}|${a2 - a1}|${vu}`);
  w.K.arriver('projet'); const a3 = n; w.M.emettre(); dire('D19.ferme', `${n - a3}`);
  const sans = monde({ avecMoteur: false }); sans.charger(); const S = sans.win.VF_MARQUES;
  dire('D19.sans-moteur', `${S.poser('a', tab(['f:a'], 'bas'))}|${typeof S.brancherDessin(() => {})}|${S.brancherDessin(42)()}`);
}

// ---- D20 : la file de résolution tardive : une pose déposée avant le canal, appliquée une fois et une seule ----
{
  const file = [{ couche: 'relecture', entrees: tab(['f:a'], 'bas'), exclusif: true }, null, 'x', { couche: '__proto__', entrees: 3 }];
  const w = monde({ file }); w.charger(); const V = w.win.VF_MARQUES;
  dire('D20.appliquee', `${V.active()}|${V.lire('f:a').length}|${V.table().length}|${file.length}`);
  w.charger(); dire('D20.rejeu', `${w.win.VF_MARQUES.lire('f:a').length}|${file.length}`);
  const f2 = [{ couche: 'a', entrees: tab(['f:a'], 'bas') }, { couche: 'col', entrees: tab(['f:a'], 'agents'), exclusif: false }, { couche: 'b', entrees: tab(['f:b'], 'bas') }];
  const w2 = monde({ file: f2 }); w2.charger(); const V2 = w2.win.VF_MARQUES;
  dire('D20.ordre', `${V2.active()}|${noms(V2.lire('f:a'))}|${noms(V2.lire('f:b'))}`);
  const w3 = monde(); w3.charger(); dire('D20.sans-file', `${w3.win.VF_MARQUES.active()}|${w3.win.VF_MARQUES_EN_ATTENTE}`);
}
console.log(sortie.join('\n'));
