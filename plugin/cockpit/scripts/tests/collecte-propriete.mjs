// collecte-propriete — pilote des propriétés génératives de la collecte (79-09, tâches 3 et 4 ; sections C6, C8 et C9 de test-cockpit-collecte.sh).
// Usage : node collecte-propriete.mjs <dossier-des-scripts> <mode> [--graine=N]      modes : rattachement | signature | verrous
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

// ---- C9 : projection des verrous en liste blanche (A15) ----
const BLANCHE = ['ws', 'scope', 'phase', 'step', 'tenu', 'stale', 'ageS', 'ttl', 'progressAgeS', 'owner', 'childrenRunning', 'dag', 'leaseS', 'sansSession'];
const ID_DAG = /^[A-Za-z0-9._:-]{1,64}$/, ST_DAG = new Set(['blocked', 'ready', 'running', 'done', 'failed']), WS_OK = /^[A-Za-z0-9][A-Za-z0-9._-]*$/, PH_OK = /^[0-9]+(\.[0-9]+)*$/;
// noms des champs : A = sortie brute du script de verrou (`status --all`), B = entrée déjà normalisée que reçoit `projeterVerrous` (la liste blanche doit tenir seule)
const NOMS = { A: { age: 'age_seconds', lease: 'lease_seconds', enfants: 'children_running', sids: 'session_ids' }, B: { age: 'ageS', lease: 'leaseS', enfants: 'childrenRunning', sids: 'session_ids' } };
const noeuds = (n) => Array.from({ length: n }, (_, i) => ({ id: `n${i}`, deps: i ? [`n${i - 1}`] : [], status: 'running' }));
const CLASSES_V = {
  'chemin': (e, m) => { e.lock = `/srv/${m}/lab/.git/vf-driver/repo/DRIVER.lock`; e.location = `/srv/${m}/emplacement`; e.chemin = `/srv/${m}/x`; },
  'session-ids': (e, m, N) => { e[N.sids] = [`${m}a`, `${m}b`]; e.present = true; },
  'prototype': (e, m) => { Object.defineProperty(e, '__proto__', { value: { x: m }, enumerable: true, configurable: true, writable: true }); e.constructor = { prototype: m }; e.toString = m; },
  'objet-imbrique': (e, m) => { e.step = { a: { b: m } }; e.owner = [m, { c: m }]; },
  'tableau': (e, m) => { e.phase = [m]; e.scope = [m, { x: m }]; },
  'geante': (e, m) => { e.step = 'z'.repeat(4000) + m; e.owner = 'y'.repeat(4000) + m + 'o'; e.ws = 'x'.repeat(2000) + m + 'w'; },
  'controle': (e) => { e.step = 'a\u0000b\u0007c\u001bd\u007fe'; e.owner = 'o\u0000\u0001'; },
  'secret': (e, m) => { e.owner = `jeton ghp_${m}${'A1b2C3d4E5f6G7h8I9j0K1l2'}`; e.step = `ghp_${m}z${'A1b2C3d4E5f6G7h8I9j0K1l2'}`; },
  'nombre-hostile': (e, m, N) => { e[N.age] = m; e[N.lease] = [m]; e[N.enfants] = { v: m }; e.ttl = Infinity; e.stale = m; },
  'dag-id': (e, m) => { (e.dag = dagOk()).nodes = [{ id: `../${m}a`, deps: [], status: 'running' }, { id: 'a b', deps: [], status: 'ready' }, { id: 'x'.repeat(70) + m, deps: [`../${m}d`, 'y y'], status: 'done' }, ...noeuds(2)]; },
  'dag-statut': (e, m) => { (e.dag = dagOk()).nodes = [{ id: 'ok1', deps: [], status: m }, { id: 'ok2', deps: [], status: 7 }, ...noeuds(2)]; },
  'dag-noeuds': (e) => { (e.dag = dagOk()).nodes = noeuds(300); },
  'dag-deps': (e) => { (e.dag = dagOk()).nodes = [{ id: 'gros', deps: Array.from({ length: 60 }, (_, i) => `d${i}`), status: 'ready' }]; },
  'dag-ws-phase': (e, m) => { Object.assign(e.dag = dagOk(), { ws: `${m}/../x`, phase: `${m}.x`, at: m }); },
  'dag-forme': (e, m) => { e.dag = r.pick([m, [m], { nodes: { a: m } }, { nodes: m }, 42]); },
};
const NOMS_CLASSES = Object.keys(CLASSES_V), SANS_MARQUEUR = new Set(['controle', 'dag-noeuds', 'dag-deps']); // ces classes se prouvent par une borne, non par un marqueur
const dagOk = () => ({ ws: 'fiabilite', phase: '79', at: 1700000000 + r.n(1000), nodes: [{ id: 'n1', deps: [], status: 'running' }, { id: 'n2', deps: ['n1'], status: 'blocked' }] });
const entreeBrute = (i, B) => (B
  ? { ws: r.pick(['', 'fiabilite']), scope: r.pick(['depot', 'compartiment', 'phase']), phase: r.pick([null, '79']), tenu: true, stale: r.bool(0.2), ageS: r.n(500), ttl: 1800, progressAgeS: r.bool(0.8) ? r.n(300) : null,
    owner: `own${i}`, step: `step${r.n(9)}`, childrenRunning: r.n(3), leaseS: r.n(9000), dag: dagOk() }
  : { present: true, owner: `own${i}`, step: `step${r.n(9)}`, age_seconds: r.n(500), ttl: 1800, stale: r.bool(0.2), generation: 'g', session_ids: r.bool(0.5) ? [`s${r.n(5)}`] : [], lease_seconds: r.n(9000), guard_effective: true,
    progress_epoch: 1, progress_age_seconds: r.bool(0.8) ? r.n(300) : null, children_running: r.n(3), scope: r.pick(['depot', 'compartiment', 'phase']), ws: r.pick(['', 'fiabilite', 'x-1']), phase: r.pick(['', '79', '41.1']), dag: dagOk() });

// les violations de la projection, nommées par classe (un marqueur planté qui ressort, une borne dépassée, une clé hors liste)
function violations(proj, plantes) {
  const v = new Set(), txt = JSON.stringify(proj);
  for (const [m, c] of plantes) if (txt.includes(m)) v.add(c);
  for (const e of Array.isArray(proj?.liste) ? proj.liste : []) {
    if (Object.getOwnPropertyNames(e).some((k) => !BLANCHE.includes(k))) v.add('cle-hors-liste');
    for (const [k, n] of [['ws', 80], ['scope', 40], ['phase', 40], ['step', 80], ['owner', 80]]) if (typeof e[k] === 'string' && e[k].length > n) v.add('geante');
    for (const k of ['ws', 'scope', 'phase', 'step', 'owner']) if (typeof e[k] === 'string' && /[\u0000-\u001f\u007f]/.test(e[k])) v.add('controle');
    for (const k of ['stale', 'sansSession']) if (e[k] !== undefined && e[k] !== null && typeof e[k] !== 'boolean') v.add('nombre-hostile');
    for (const k of ['ageS', 'ttl', 'progressAgeS', 'childrenRunning', 'leaseS']) if (e[k] !== undefined && e[k] !== null && !(typeof e[k] === 'number' && Number.isFinite(e[k]))) v.add('nombre-hostile');
    const d = e.dag; if (d === undefined) continue;
    if (!d || typeof d !== 'object' || !Array.isArray(d.nodes)) { v.add('dag-forme'); continue; }
    if (d.nodes.length > 200) v.add('dag-noeuds');
    if (!(d.ws === '' || (typeof d.ws === 'string' && WS_OK.test(d.ws) && !d.ws.includes('..'))) || !(d.phase === '' || (typeof d.phase === 'string' && PH_OK.test(d.phase))) || !(d.at === null || Number.isInteger(d.at))) v.add('dag-ws-phase');
    for (const n of d.nodes) {
      if (typeof n.id !== 'string' || !ID_DAG.test(n.id)) v.add('dag-id');
      if (!ST_DAG.has(n.status)) v.add('dag-statut');
      if (!Array.isArray(n.deps) || n.deps.length > 32) v.add('dag-deps'); else if (n.deps.some((x) => typeof x !== 'string' || !ID_DAG.test(x))) v.add('dag-id');
    }
  }
  return v;
}

async function verrous() {
  let V = null, S = null;
  try { V = await imp('vf-cockpit-vie.mjs'); S = await imp('vf-cockpit-signal.mjs'); } catch (e) { sortir({ erreur: String(e.message).slice(0, 160), resultats: {} }); }
  if (typeof V.verrousDe !== 'function' || typeof S.projeterVerrous !== 'function') sortir({ erreur: 'verrousDe ou projeterVerrous absent', resultats: { ecarts: { absent: 1 } }, couverture: {} });
  const couverture = Object.fromEntries([...NOMS_CLASSES, 'extra-cle'].map((c) => [c, 0])), ecarts = {}, temoin = { plante: 0, vu: 0 }; let exemple = null;
  const TOURS = 400;
  for (let i = 0; i < TOURS * 2; i++) {
    const B = i >= TOURS, N = NOMS[B ? 'B' : 'A'], forcees = i % TOURS < NOMS_CLASSES.length ? [NOMS_CLASSES[i % TOURS]] : [];
    const entrees = [], plantes = new Map();
    for (let k = 0; k < 1 + r.n(3); k++) {
      const e = entreeBrute(k, B), classes = forcees.length && k === 0 ? forcees : r.bool(0.6) ? [r.pick(NOMS_CLASSES), ...(r.bool(0.4) ? [r.pick(NOMS_CLASSES)] : [])] : [];
      for (const c of classes) { const m = `MQ${c.replace(/-/g, '')}${r.chaine(6)}`; CLASSES_V[c](e, m, N); if (SANS_MARQUEUR.has(c)) couverture[c]++; else plantes.set(m, c); }
      if (B && r.bool(0.5)) { const m = `MQextracle${r.chaine(6)}`; Object.assign(e, { lock: `/srv/${m}/x`, present: true, location: m, session_ids: [m] }); plantes.set(m, 'extra-cle'); }
      entrees.push(e);
    }
    const sessions = new Set(['sess-a']);
    let proj;
    try {
      if (B) proj = S.projeterVerrous({ etat: 'lue', plat: false, liste: entrees });
      else {
        const brut = entrees.length === 1 && r.bool(0.4) ? entrees[0] : { present: true, scope: 'lab', location: `/srv/MQlocation${i}/x`, legacy_lock: false, children_running: 1, locks: [...entrees, { present: false, lock: '/x' }] };
        plantes.set(`MQlocation${i}`, 'chemin');
        proj = S.projeterVerrous(V.verrousDe(brut, { sessions: sessions }));
      }
    } catch (e) { proj = null; plantes.set('LEVE', 'leve'); }
    // témoin positif : chaque marqueur planté est bien dans l'entrée avant projection (la projection ne peut pas le « perdre » pour de bon sans qu'on sache que l'entrée le portait)
    const brutTxt = JSON.stringify(entrees);
    // un marqueur qu'une classe suivante a écrasé dans la même entrée n'est pas planté : il ne compte ni pour la couverture ni pour la preuve
    for (const [m, c] of [...plantes]) {
      if (m.startsWith('MQlocation') || m === 'LEVE') continue;
      temoin.plante++;
      if (brutTxt.includes(m)) { temoin.vu++; couverture[c]++; } else plantes.delete(m);
    }
    const v = proj ? violations(proj, plantes) : new Set(['leve']);
    for (const c of v) { ecarts[c] = (ecarts[c] || 0) + 1; exemple ||= { classe: c, graine, tour: i, pass: B ? 'B' : 'A' }; }
  }
  // C9.1b : formes de la sortie du script, C9.3 : sansSession, leaseS, childrenRunning, step
  const ve = V.verrousDe, un = (o) => ({ present: true, owner: 'o', step: 'etape', ttl: 1800, age_seconds: 1, lease_seconds: 3000, children_running: 4, scope: 'depot', ws: '', stale: false, ...o });
  const formes = [ve({ available: false }).etat, ve({ error: 'x' }).etat, (() => { const x = ve({ present: false }); return `${x.etat}${x.plat}${x.liste.length}`; })(), ve({ foo: 1 }).etat, ve(null).etat, ve({ locks: [un({}), { present: false }] }).liste.length].join();
  const sa = (ids, opts) => ve(un({ session_ids: ids }), opts).liste[0], sess = { sessions: new Set(['sessA']) };
  const c93 = { sansSession: [sa(['x'], sess).sansSession, sa(['sessA'], sess).sansSession, sa([], sess).sansSession, sa(['x', 'sessA'], sess).sansSession, 'sansSession' in sa(['x'], {})].join(), lease: sa([], sess).leaseS, enfants: sa([], sess).childrenRunning, step: sa([], sess).step };
  const p93 = S.projeterVerrous(ve(un({ session_ids: ['x'] }), sess)).liste[0]; c93.proj = [p93.sansSession, p93.leaseS, p93.childrenRunning, p93.step].join();
  sortir({ resultats: { total: TOURS * 2, ecarts, formes, c93, temoin }, couverture, exemple });
}

if (mode === 'verrous') await verrous();
else if (mode === 'rattachement') await rattachement();
else if (mode === 'signature') await signature();
else sortir({ erreur: 'mode inconnu', resultats: {} });
