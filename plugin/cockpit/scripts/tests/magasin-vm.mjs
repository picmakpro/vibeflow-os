// magasin-vm.mjs <70-vf-etat.js> <scénario> — le magasin d'état de la page hors navigateur (79-17, SOCL-21) : un contexte vm, un flux factice à la porte de
// ui/69-vf-flux.js (window.VF_FLUX : ecouter, surConnexion), un fetch factice contrôlable. Une ligne JSON rendue, ou { erreur }.
// Scénarios : api (A) · alimentation (F) · lectures (L) · json (J). Les erreurs levées dans le contexte ont un autre constructeur : on juge leur `name`.
import fs from 'node:fs';
import vm from 'node:vm';

const [, , fichier, scenario] = process.argv;
const SOURCE = fs.readFileSync(fichier, 'utf8');
const CLES = ['connexion', 'etat', 'frise', 'git', 'graphe', 'lock', 'planning', 'who'];
const tick = () => new Promise((r) => setImmediate(r));
const nom = (f) => { try { f(); return 'aucune'; } catch (e) { return e && e.name; } };
const rejets = [];
process.on('unhandledRejection', (e) => rejets.push(String(e && e.message)));

// un monde : flux factice, requêtes enregistrées, réponses contrôlées (file d'attente de promesses déclenchées à la main)
function monde({ flux = true, serveur = true, repond = null } = {}) {
  const abonnes = {}; const conns = []; const demandes = []; const journal = []; const attente = [];
  const FLUX = flux ? {
    ecouter(n, f) { (abonnes[n] ||= []).push(f); return () => { abonnes[n] = abonnes[n].filter((x) => x !== f); }; },
    surConnexion(f) { conns.push(f); return () => {}; },
  } : undefined;
  const reponse = (corps, { statut = 200, json = true } = {}) => ({ ok: statut >= 200 && statut < 300, status: statut,
    json: async () => { if (!json) throw new SyntaxError('JSON invalide'); return corps; } });
  const window = { VF_FLUX: FLUX, VF_COCKPIT_SERVER: serveur ? { token: 'jeton-synthetique-1' } : undefined,
    fetch: (u, o) => { demandes.push({ u, o }); if (repond) return Promise.resolve(repond(u, o, reponse)); return new Promise((ok, ko) => attente.push({ u, ok, ko, reponse })); } };
  const ctx = vm.createContext({ window, console: { error: (m) => journal.push(String(m)), log() {}, warn() {} }, Date });
  const charger = () => vm.runInContext(SOURCE, ctx, { timeout: 5000 });
  return { window, ctx, charger, demandes, journal, attente, reponse, conns,
    emettre: (n, c) => { for (const f of [...(abonnes[n] || [])]) f(c, { relaye: false, rejeu: false }); },
    connexion: (e) => { for (const f of [...conns]) f(e); }, nbAbonnes: (n) => (abonnes[n] || []).length };
}
const hello = (extra = {}) => ({ seq: 1, lock: { seq: 0, at: 5, verrous: { etat: 'absente', plat: false, liste: [] } }, who: { workers: [], sources: {} }, ...extra });
const ETAT = (seq = 1) => ({ schema: 'vibeflow/cockpit-state@1', seq, signal: {} });
const vides = (E) => CLES.every((c) => E.lire(c) === null);

async function api() {
  const R = {}; let m = monde(); m.charger(); const E = m.window.VF_ETAT;
  R.A1 = vides(E) && E.CLES.join() === CLES.join();
  R.A2 = ['__proto__', 'constructor', 'toString', '', 1, null].map((k) => nom(() => E.lire(k)) + '/' + nom(() => E.abonner(k, () => {})));
  R.A2b = vides(E);
  R.A3 = [nom(() => E.abonner('who', 'x')), nom(() => E.abonner('who', null)), nom(() => E.abonner('who'))];
  const ordre = []; E.abonner('git', () => ordre.push(1)); E.abonner('git', () => ordre.push(2)); E.abonner('git', () => ordre.push(3));
  m.emettre('git', { seq: 1, at: 1, sig: 'a' }); R.A4 = ordre.join();
  const appels = []; const off = E.abonner('graphe', () => appels.push('x')); m.emettre('graphe', { seq: 1, at: 1, onglet: 'code', sig: 'a' });
  off(); off(); m.emettre('graphe', { seq: 2, at: 1, onglet: 'code', sig: 'b' }); R.A5 = appels.length;
  const t = []; let offB; E.abonner('lock', () => { t.push('a'); offB(); }); offB = E.abonner('lock', () => t.push('b'));
  m.emettre('lock', { seq: 1, at: 1, verrous: {} }); R.A5b = t.join();
  const s = []; let ajoute = false; E.abonner('planning', () => { s.push('p'); if (!ajoute) { ajoute = true; E.abonner('planning', () => s.push('n')); } });
  m.emettre('structural', { seq: 1, at: 1 }); const apres1 = s.join(); m.emettre('structural', { seq: 2, at: 2 }); R.A6 = apres1 + '|' + s.join();
  const v = []; E.abonner('who', () => { throw new Error('rappel hostile'); }); E.abonner('who', (w) => v.push(w.workers.length));
  m.emettre('who', { seq: 1, at: 1, who: { workers: [1, 2], sources: {} } }); R.A7 = [v.join(), E.lire('who').workers.length, m.journal.length].join('|');
  const n0 = E.abonnes(); const off2 = E.abonner('connexion', () => {}); const n1 = E.abonnes();
  R.A8 = [Object.keys(n1).join() === CLES.join(), n1.connexion - n0.connexion, n1.git, n1.who].join();
  off2(); R.A8b = E.abonnes().connexion === n0.connexion;
  m.emettre('who', { seq: 2, at: 2, who: { workers: [], sources: {} } }); const avant = E.lire('who'); m.charger();
  R.A9 = [m.window.VF_ETAT === E, E.lire('who') === avant, m.nbAbonnes('who')].join();
  R.A10 = [Object.isFrozen(E), Object.isFrozen(E.CLES), (() => { try { E.lire = null; } catch { /* mode strict */ } return typeof E.lire; })()].join();
  m = monde({ flux: false, serveur: false }); m.charger(); const H = m.window.VF_ETAT; R.A11 = [vides(H), H.jeton(), nom(() => H.abonner('who', () => {}))].join();
  m = monde({ flux: false }); m.charger(); R.A11b = nom(() => m.window.VF_ETAT.lire('etat'));
  return R;
}

async function alimentation() {
  const R = {}; const m = monde({ repond: (u, o, rep) => rep(ETAT(3)) }); m.charger(); const E = m.window.VF_ETAT; const recu = {};
  for (const c of CLES) E.abonner(c, (v) => { (recu[c] ||= []).push(v); });
  m.connexion('ouvert'); m.emettre('hello', hello()); await tick();
  R.F1 = [E.lire('connexion'), E.lire('who') && 'who', E.lire('lock') && 'lock', (E.lire('etat') || {}).seq, m.demandes.some((d) => d.u === '/api/vf/state'), recu.connexion.length].join();
  const m2 = monde({ repond: (u, o, rep) => rep(ETAT()) }); m2.charger(); m2.emettre('hello', { seq: 1, lock: hello().lock });
  R.F2 = [m2.window.VF_ETAT.lire('who'), JSON.stringify(m2.window.VF_ETAT.lire('lock').verrous.etat)].join();
  const w = { workers: [{ kind: 'subagent', id: 'a', etat: 'actif', tree: '.' }], sources: {} }; m.emettre('who', { seq: 4, at: 4, who: w });
  R.F3 = JSON.stringify(E.lire('who')) === JSON.stringify(w);
  const l = { seq: 5, at: 5, verrous: { etat: 'lue', plat: false, liste: [] } }; m.emettre('lock', l); R.F4 = JSON.stringify(E.lire('lock')) === JSON.stringify(l);
  m.emettre('git', { seq: 6, at: 6, sig: 'abc' }); R.F5 = JSON.stringify(E.lire('git'));
  m.emettre('graphe', { seq: 7, at: 7, onglet: 'code', sig: 's1' }); m.emettre('graphe', { seq: 8, at: 8, onglet: 'projet', sig: 's2' });
  R.F6 = [recu.graphe.length, E.lire('graphe').onglet].join();
  m.emettre('structural', { seq: 9 }); const p = E.lire('planning'); R.F7 = [p.seq, typeof p.at, Object.keys(p).sort().join()].join();
  const trace = []; E.abonner('connexion', (c) => trace.push(c)); m.connexion('perdu'); m.connexion('perdu'); m.connexion('reprise'); m.connexion('ouvert');
  R.F8 = trace.join() + '|' + E.lire('connexion');
  const avant = CLES.map((c) => JSON.stringify(E.lire(c))).join('~'); const notifs = Object.values(recu).reduce((a, x) => a + x.length, 0);
  const mauvais = { who: [null, 'x', 5, [], {}, { who: null }, { who: [] }, { who: 'x' }], lock: [null, {}, { seq: 1 }, { verrous: 'x' }, { seq: -1, at: 1, verrous: {} }],
    git: [null, {}, { seq: 1 }, { seq: 1, sig: 5 }, { seq: 1e99, at: 1, sig: 'a' }, { seq: NaN, at: 1, sig: 'a' }],
    graphe: [null, {}, { seq: 1, at: 1, onglet: 5, sig: 'a' }, { seq: 1, at: 1, onglet: 'code' }], structural: [null, {}, { seq: 'x' }, { seq: -3 }, []] };
  let leve = 'aucune'; try { for (const [n, liste] of Object.entries(mauvais)) for (const c of liste) m.emettre(n, c); } catch (e) { leve = e.message; }
  R.F9 = [leve, avant === CLES.map((c) => JSON.stringify(E.lire(c))).join('~'), notifs === Object.values(recu).reduce((a, x) => a + x.length, 0)].join();
  const av2 = CLES.map((c) => JSON.stringify(E.lire(c))).join('~'); for (const n of ['vie', 'patch', 'reload']) m.emettre(n, { seq: 99, at: 1 });
  R.F10 = av2 === CLES.map((c) => JSON.stringify(E.lire(c))).join('~');
  return R;
}

async function lectures() {
  const R = {}; let seq = 0; let m = monde({ repond: (u, o, rep) => rep(ETAT(++seq)) }); m.charger(); let E = m.window.VF_ETAT;
  m.emettre('hello', hello()); await tick(); const n1 = (E.lire('etat') || {}).seq; m.emettre('etat', { seq: 2, at: 1, sig: 'a' }); await tick();
  R.L1 = [n1, E.lire('etat').seq, m.demandes.length, m.demandes.every((d) => d.u === '/api/vf/state')].join();
  const corps = [{ schema: 'autre', seq: 9 }, { schema: 'vibeflow/cockpit-state@1', seq: 'x' }, null, 5];
  let i = 0; m = monde({ repond: (u, o, rep) => (i++ === 0 ? rep(ETAT(5)) : i <= 5 ? rep(corps[i - 2]) : rep({}, { statut: 503 })) }); m.charger(); E = m.window.VF_ETAT;
  m.emettre('hello', hello()); await tick(); for (let k = 0; k < 5; k++) { m.emettre('etat', { seq: k, at: 1, sig: 'a' }); await tick(); }
  const n = m.demandes.length; await tick(); await tick(); R.L2 = [E.lire('etat').seq, n, m.demandes.length].join();
  m = monde(); m.charger(); E = m.window.VF_ETAT; m.emettre('hello', hello()); await tick();
  for (let k = 0; k < 10; k++) m.emettre('etat', { seq: k, at: 1, sig: 'a' });
  const pendant = m.demandes.length; m.attente[0].ok(m.attente[0].reponse(ETAT(100))); await tick(); await tick();
  const apres = m.demandes.length; m.attente[1].ok(m.attente[1].reponse(ETAT(200))); await tick(); await tick();
  R.L3 = [pendant, apres, m.demandes.length, E.lire('etat').seq].join();
  m = monde({ repond: (u, o, rep) => rep({ schema: 'vibeflow/cockpit-frise@1', seq: 1, u }) }); m.charger(); E = m.window.VF_ETAT;
  m.emettre('hello', hello()); await tick(); m.emettre('frise', { seq: 2, at: 1, sig: 'a' }); await tick();
  const sans = m.demandes.filter((d) => d.u.includes('frise')).length; const off = E.abonner('frise', () => {}); await tick(); const premiere = m.demandes.filter((d) => d.u.includes('frise')).length;
  m.emettre('frise', { seq: 3, at: 1, sig: 'b' }); await tick(); const relue = m.demandes.filter((d) => d.u.includes('frise')).length; off();
  m.emettre('frise', { seq: 4, at: 1, sig: 'c' }); await tick(); const perimee = m.demandes.filter((d) => d.u.includes('frise')).length;
  E.abonner('frise', () => {}); await tick(); R.L4 = [sans, premiere, relue, perimee, m.demandes.filter((d) => d.u.includes('frise')).length, E.lire('frise') && 'lue'].join();
  m = monde({ repond: (u, o, rep) => rep(u.includes('frise') ? { schema: 'vibeflow/cockpit-frise@1', seq: 1 } : ETAT(1)) }); m.charger(); E = m.window.VF_ETAT;
  E.abonner('frise', () => {}); m.emettre('hello', hello()); await tick(); const a = m.demandes.length; m.connexion('perdu'); m.connexion('reprise'); m.connexion('ouvert');
  m.emettre('hello', hello({ seq: 2 })); await tick(); R.L5 = [a, m.demandes.length, m.demandes.filter((d) => d.u.includes('frise')).length].join();
  m = monde({ repond: () => Promise.reject(new Error('réseau')) }); m.charger(); m.emettre('hello', hello()); await tick(); await tick(); await tick();
  R.L6 = [rejets.length, m.window.VF_ETAT.lire('etat')].join();
  return R;
}

async function json() {
  const R = {}; let m = monde({ repond: (u, o, rep) => rep({ ok: true }) }); m.charger(); let E = m.window.VF_ETAT; const lire = (c) => E.lireJson(c).then(() => 'ok', (e) => e.statut + ':' + e.message);
  R.J1 = [E.jeton()]; m.window.VF_COCKPIT_SERVER.token = 'jeton-synthetique-2'; R.J1.push(E.jeton()); R.J1 = R.J1.join();
  await lire('/api/vf/state'); const q = m.demandes[0]; R.J2 = [q.u, q.o.method || 'GET', q.o.headers['x-vf-cockpit-token'], q.o.cache, q.o.redirect, 'body' in q.o, Object.keys(q.o).sort().join()].join('|');
  const bonnes = ['/api/vf/state', '/api/vf/frise?depuis=1&jusqua=2', '/api/vf/frise?champs=cibles', '/api/vf/graphe?onglet=code', '/api/vf/git/entete', '/api/vf/doing?id=a-b_c',
    '/api/vf/transcript?id=a%3Ab', '/api/vf/modeles', '/api/vf/activite']; const av = m.demandes.length; const r3 = []; for (const c of bonnes) r3.push(await lire(c));
  R.J3 = r3.every((x) => x === 'ok') + ':' + (m.demandes.length - av);
  const hostiles = ['http://evil.example/api/vf/x', '//hote/x', '/api/export', 'api/vf/x', '/api/vf/../export', '/api/vf/%2e%2e/export', '/api/vf/x#f', '/api/vf/x\r\nX: y', '/api/vf/x\\y',
    '', 5, null, undefined, {}, '/api/vf/', '/api/vf', '/api/vf//x', '/api/vf/x y', '/api/vf/é', '/api/vf/x?a=1\n', '/' + 'a'.repeat(2049), '/api/vf/' + 'a'.repeat(2041)];
  const av4 = m.demandes.length; const r4 = []; for (const c of hostiles) r4.push(await lire(c)); R.J4 = [r4.filter((x) => x.startsWith('0:')).length, hostiles.length, m.demandes.length - av4].join();
  const statuts = []; for (const s of [403, 404, 500]) { const w = monde({ repond: (u, o, rep) => rep({ corps: 'SECRET-DU-CORPS' }, { statut: s }) }); w.charger(); try { await w.window.VF_ETAT.lireJson('/api/vf/x'); } catch (e) { statuts.push(e.statut + ':' + e.message.includes('SECRET')); } }
  R.J5 = statuts.join();
  const net = monde({ repond: () => Promise.reject(new Error('panne-reseau')) }); net.charger(); try { await net.window.VF_ETAT.lireJson('/api/vf/x'); } catch (e) { R.J6 = e.statut + ':' + e.message.includes('panne'); }
  const inv = monde({ repond: (u, o, rep) => rep(null, { json: false }) }); inv.charger(); try { await inv.window.VF_ETAT.lireJson('/api/vf/x'); } catch (e) { R.J7 = e.statut; }
  const sans = monde({ serveur: true, repond: (u, o, rep) => rep({}) }); sans.charger(); sans.window.VF_COCKPIT_SERVER.token = null; const avs = sans.demandes.length;
  try { await sans.window.VF_ETAT.lireJson('/api/vf/x'); R.J8 = 'accepte'; } catch (e) { R.J8 = e.statut + ':' + (sans.demandes.length - avs); }
  const jm = monde({ repond: (u, o, rep) => rep({ statutSecret: 'x' }, { statut: 500 }) }); jm.charger(); const Ej = jm.window.VF_ETAT; jm.emettre('hello', hello()); await tick(); await tick();
  const photo = JSON.stringify(CLES.map((c) => Ej.lire(c))) + jm.journal.join(); R.J9 = !photo.includes('jeton-synthetique');
  return R;
}

try {
  const f = { api, alimentation, lectures, json }[scenario]; if (!f) throw new Error('scénario inconnu : ' + scenario);
  console.log(JSON.stringify(await f()));
} catch (e) { console.log(JSON.stringify({ erreur: 'exécution : ' + String(e && e.message).slice(0, 200) })); }
