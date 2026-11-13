// collecte-propriete — pilote des propriétés génératives de la collecte (79-09, tâche 3 ; sections C6 et C8 de test-cockpit-collecte.sh).
// Usage : node collecte-propriete.mjs <dossier-des-scripts> <mode> [--graine=N]      modes : rattachement | signature
//   Première ligne : `graine=N` (rejouable par --graine=N ou VF_SEED) ; dernière ligne : un JSON { resultats, couverture, ... } ; sortie 0 même quand une
//   propriété échoue (le verdict est dans le JSON : la suite lit, un module absent rougit sans planter le pilote).
// Le code testé est importé depuis le dossier passé : une copie mutée se joue sans changement. Chaque oracle est écrit ICI, indépendamment du module.
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { rng, graineDe } from './collecte-generateur.mjs';

const [, , scripts, mode] = process.argv;
const graine = graineDe(process.argv.slice(4), process.env);
console.log(`graine=${graine}`);
const imp = (f) => import(pathToFileURL(path.join(scripts, f)).href);
const sortir = (o) => { console.log(JSON.stringify(o)); process.exit(0); };
const r = rng(graine);

// ---- C6 : jointure du rattachement aux voies (A8, A14) ----
const CLASSES = ['propre', 'enfants-uniques', 'enfants-mixtes', 'aucun-enfant-rattache', 'enfants-partiellement-rattaches', 'session'];
const PLANS = ['.planning/missions/m1.dag.json', '.planning/missions/m2.dag.json', '.planning/workstreams/x/phases/p3/dag-p3.json', 'p'.repeat(250) + '.dag.json'];
const reduire = (p) => String(p).slice(0, 200); // oracle de la réduction à 200 caractères (aucun caractère de contrôle dans les plans générés)

function foret(force) {
  const voies = [{ id: 'sess-0', kind: 'session', parent: null, depth: null }], trav = []; let k = 0;
  const sous = (parent, depth) => { const id = `ag${++k}`; voies.push({ id, kind: 'subagent', parent, depth }); return id; };
  const att = (id, plan) => trav.push({ id, kind: 'subagent', rattachement: { etat: 'rattache', source: r.pick(['registre', 'mandat']), dag: plan, noeud: `n${r.n(5)}` } });
  const non = (id) => trav.push({ id, kind: 'subagent', rattachement: { etat: 'non-rattache', raison: r.pick(['sans-citation', 'inconnu', 'ambigu']) } });
  const classe = force ?? r.pick(CLASSES);
  const mgr = sous('sess-0', 1);
  if (classe === 'session') trav.push({ id: 'sess-0', kind: 'session', rattachement: { etat: 'rattache', source: 'mandat', dag: PLANS[0], noeud: 'n1' } }); // une voie de session reste null
  if (classe === 'propre') { att(mgr, r.pick(PLANS)); for (let i = 0; i < r.n(3); i++) att(sous(mgr, 2), r.pick(PLANS)); }
  else if (classe !== 'session') {
    non(mgr); const n = 1 + r.n(3), plans = [r.pick(PLANS)];
    if (classe === 'enfants-mixtes') plans.push(PLANS[(PLANS.indexOf(plans[0]) + 1) % PLANS.length]);
    for (let i = 0; i < Math.max(n, plans.length); i++) {
      const e = sous(mgr, 2);
      if (classe === 'aucun-enfant-rattache') non(e);
      else if (classe === 'enfants-partiellement-rattaches' && i === 0) non(e);
      else att(e, classe === 'enfants-mixtes' ? plans[i % plans.length] : plans[0]);
    }
    if (classe === 'enfants-partiellement-rattaches') att(sous(mgr, 2), plans[0]);
    if (r.bool(0.4)) att(sous(sous(mgr, 2), 3), r.pick(PLANS)); // un petit-enfant propre ne compte jamais pour le grand-parent
  }
  return { voies: r.bool(0.5) ? voies : voies.reverse(), trav, classe };
}

function oracle(voies, trav) {
  const w = new Map(trav.map((t) => [t.id, t])), propre = (id) => { const x = w.get(id)?.rattachement; return x && x.etat === 'rattache' && typeof x.dag === 'string' && x.dag ? x : null; };
  const sortie = new Map();
  for (const v of voies) {
    if (v.kind !== 'subagent') { sortie.set(v.id, null); continue; }
    const p = propre(v.id);
    if (p) { sortie.set(v.id, { dag: reduire(p.dag), noeud: p.noeud, source: p.source }); continue; }
    const plans = new Set(voies.filter((x) => x.kind === 'subagent' && x.parent === v.id && propre(x.id)).map((x) => reduire(propre(x.id).dag)));
    sortie.set(v.id, plans.size === 1 ? { dag: [...plans][0], noeud: null, source: 'enfants' } : null);
  }
  return sortie;
}

async function rattachement() {
  let M = null; try { M = await imp('vf-cockpit-voies-rattachement.mjs'); } catch (e) { sortir({ erreur: String(e.message).slice(0, 160), resultats: { total: 0, ecarts: Object.fromEntries(CLASSES.map((c) => [c, -1])) }, couverture: {} }); }
  const couverture = Object.fromEntries(CLASSES.map((c) => [c, 0])), ecarts = Object.fromEntries(CLASSES.map((c) => [c, 0])); let exemple = null;
  const TOURS = 300;
  for (let i = 0; i < TOURS; i++) {
    const { voies, trav, classe } = foret(i < CLASSES.length ? CLASSES[i] : undefined);
    const attendu = oracle(voies, trav);
    let obtenu; try { obtenu = M.rattacherVoies(voies, trav); } catch (e) { obtenu = null; }
    const c = classe; couverture[c]++;
    const egal = obtenu instanceof Map && voies.every((v) => JSON.stringify(obtenu.get(v.id) ?? null) === JSON.stringify(attendu.get(v.id)));
    if (!egal) { ecarts[c]++; exemple ||= { classe: c, graine, tour: i }; }
  }
  sortir({ resultats: { total: TOURS, ecarts }, couverture, exemple });
}

// ---- C8 : signature du who (A17) ----
const VOLATILS = ['at', 'ageS', 'dureeS', 'lastAt']; // oracle : la liste NOMMÉE des champs volatils, écrite ici

function whoFixture() {
  const w = (i) => ({ kind: 'subagent', id: `ag${i}`, tree: 'arbre principal', source: 'subagent-meta', role: 'vf-coder', task: `tache ${i}`, titre: `titre ${i}`, parent: 'sess-0', depth: 2, background: false,
    branch: 'main', treeBy: 'cwd', cwd: '/lab', ageS: 10 + i, lastAt: '2026-11-01T10:00:00Z', stale: false, orphan: false, children: 0, dag: 'm1.dag.json', etat: 'actif', dureeS: 30 + i,
    finAt: '2026-11-01T11:00:00Z', action: { verbe: 'lit', cible: 'x.md' }, rattachement: { etat: 'rattache', source: 'registre', dag: 'm1.dag.json', noeud: 'n1' }, enCours: true, finMotif: 'echec' });
  return { schema: 'vibeflow/cockpit-who@2', at: '2026-11-01T10:00:00Z', root: '/lab', trees: ['arbre principal'], fresh: 180, fenetre: 86400, busy: true, workers: [w(1), w(2)], sources: { sessions: { etat: 'lue', recentFiles: 2 } }, sortisSilence: 1 };
}
const clone = (o) => JSON.parse(JSON.stringify(o));
const change = (v) => (typeof v === 'string' ? v + '~' : typeof v === 'number' ? v + 1 : typeof v === 'boolean' ? !v : Array.isArray(v) ? [...v, 'x'] : v && typeof v === 'object' ? { ...v, zz: 1 } : 'nouveau');

async function signature() {
  let M = null; try { M = await imp('vf-cockpit-who-signature.mjs'); } catch (e) { sortir({ erreur: String(e.message).slice(0, 160), resultats: {} }); }
  const { whoSig, CHAMPS_VOLATILS } = M, base = whoFixture(), res = { liste: JSON.stringify([...CHAMPS_VOLATILS].sort()) === JSON.stringify([...VOLATILS].sort()), hors: [], dedans: [], ordre: true, ajoute: true, profondeur: true };
  const s0 = whoSig(base);
  const essai = (modif) => { const o = clone(base); modif(o); return whoSig(o) !== s0; };
  // chaque clé du premier niveau, puis chaque clé d'un travailleur : hors liste -> la signature change ; dans la liste -> elle ne change pas
  const cles = [];
  for (const k of Object.keys(base)) cles.push([k, (o) => { o[k] = change(o[k]); }]);
  for (const k of Object.keys(base.workers[0])) cles.push([`workers[0].${k}`, (o) => { o.workers[0][k] = change(o.workers[0][k]); }, k]);
  const cle = (k) => k.split('.').pop();
  for (const [nom, modif] of cles) { const volatile = VOLATILS.includes(cle(nom)), bouge = essai(modif); if (volatile === bouge) (volatile ? res.dedans : res.hors).push(nom); }
  res.nCles = cles.length; res.nTrav = Object.keys(base.workers[0]).length;
  // l'ordre des clés est sans effet
  const inverse = (o) => (Array.isArray(o) ? o.map(inverse) : o && typeof o === 'object' ? Object.fromEntries(Object.entries(o).reverse().map(([k, v]) => [k, inverse(v)])) : o);
  res.ordre = whoSig(inverse(base)) === s0;
  // un champ inconnu ajouté à un travailleur est couvert sans retouche du code ; un champ volatil de profondeur quelconque ne l'est pas
  res.ajoute = essai((o) => { o.workers[0][`champ${r.chaine(5)}`] = 'neuf'; });
  res.profondeur = !essai((o) => { o.workers[0].action.ageS = 9; o.workers[1].rattachement.at = 'x'; o.sources.sessions.at = 'y'; });
  sortir({ resultats: res, couverture: { cles: cles.length } });
}

if (mode === 'rattachement') await rattachement();
else if (mode === 'signature') await signature();
else sortir({ erreur: 'mode inconnu', resultats: {} });
