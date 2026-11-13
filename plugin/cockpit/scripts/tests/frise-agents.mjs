#!/usr/bin/env node
// frise-agents.mjs — harnais des sections F7 de test-cockpit-frise.sh (79-22, SOCL-27) : routes d'agent lues dans la table de la collecte.
// Aucune donnée du poste : identifiants synthétiques, jalon de lab passé en argument. N'importe le code testé que par le dossier de scripts reçu.
//   fixture <home> <lab> <Mio>              session, sous-agents (rôle connu, supprimable, hors fenêtre, marqué, volumineux), second projet au nom marqué
//   instrumenter <racine-module> <fichier>  copie instrumentée : `collecteAgents` ajoute `requete` (pile avec revealDoing/revealTranscript/reveler) ou `tour`
//                                           au fichier compteur ; `reduireTranscript` lève, sur l'agent `err1`, une erreur dont le message porte chemin et marqueur
//   rafale <port> <jeton> <id> <n> <groupe> <pauseMs>   n requêtes de transcript par groupes, une ligne JSON { codes, ms }
//   duree <scripts> <lab> <home> <id>       durée (ms) d'une lecture de l'ancien chemin sur la boucle
//   tours <scripts> <lab> <home> <faux> <n>   n tours de la collecte en processus (F7.7)
//   egal | borne | file | erreur <scripts> …  scénarios en processus (F7.2, F7.2b, F7.6, F7.9) : une ligne JSON
// Le même fichier sert de fil d'essai (F7.6) : lancé comme fil, il répond, retient, se tait ou meurt selon `<sortie>/scenario`.
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import { isMainThread, parentPort, workerData } from 'node:worker_threads';
import { pathToFileURL } from 'node:url';

export const M_MANDAT = 'MARQ-MANDAT-79-22', M_DOING = 'MARQ-DOING-79-22', M_CHEMIN = 'MARQ-CHEMIN-79-22', M_ERREUR = 'MARQ-ERREUR-79-22';
const iso = (ms) => new Date(ms).toISOString();
const imp = (scripts, f) => import(pathToFileURL(path.join(scripts, f)).href);
const ligne = (o) => JSON.stringify(o) + '\n';

// ---------- fil d'essai (F7.6) ----------
if (!isMainThread) {
  const lire = () => { try { return fs.readFileSync(path.join(workerData.sortie, 'scenario'), 'utf8').trim(); } catch { return 'repond'; } };
  const tenus = [], repondre = (m) => parentPort.postMessage({ type: 'lecture', id: m.id, corps: { schema: 'essai', id: m.lecture.id } });
  setInterval(() => { if (lire() === 'repond') while (tenus.length) repondre(tenus.shift()); }, 20);
  parentPort.on('message', (m) => {
    if (m.lecture) { const s = lire(); if (s === 'mourir') process.exit(1); if (s === 'repond') repondre(m); else if (s === 'retient') tenus.push(m); return; }
    parentPort.postMessage({ type: 'fini', id: m.id });
  });
}

// ---------- fixture ----------
function agent(sous, aid, { lab, sid, role = 'vf-coder', texte, mandat, ageS = 5, octets = 0, extra = '' }) {
  fs.mkdirSync(sous, { recursive: true });
  const t = Date.now() - ageS * 1000, base = { cwd: lab, sessionId: sid };
  const L = [ligne({ isSidechain: true, agentId: aid, type: 'user', ...base, timestamp: iso(t - 60e3), message: { role: 'user', content: mandat || `mandat ${aid}` } })];
  L.push(ligne({ type: 'assistant', ...base, timestamp: iso(t - 30e3), message: { role: 'assistant', content: [{ type: 'text', text: texte || `fait ${aid}` }, { type: 'tool_use', id: `toolu_${aid}`, name: 'Bash', input: { command: `echo ${aid}${extra}` } }] } }));
  let corps = L.join('');
  if (octets) { const plein = ligne({ type: 'assistant', ...base, timestamp: iso(t - 20e3), message: { role: 'assistant', content: [{ type: 'text', text: 'x'.repeat(900) }] } }); corps += plein.repeat(Math.ceil(octets / plein.length)); }
  corps += ligne({ type: 'assistant', ...base, timestamp: iso(t), message: { role: 'assistant', content: [{ type: 'tool_use', id: `toolu_${aid}b`, name: 'Bash', input: { command: `echo fin-${aid}` } }] } });
  const f = path.join(sous, `agent-${aid}.jsonl`);
  fs.writeFileSync(f, corps); fs.utimesSync(f, new Date(t), new Date(t));
  fs.writeFileSync(path.join(sous, `agent-${aid}.meta.json`), JSON.stringify({ agentType: role, description: 'tâche', spawnDepth: 1, toolUseId: 'toolu_x', requestShape: 'background' }));
}
function session(proj, sid, lab, commande) {
  fs.mkdirSync(proj, { recursive: true });
  const base = { cwd: lab, sessionId: sid, version: '2.1.322', gitBranch: 'main' }, t = Date.now();
  fs.writeFileSync(path.join(proj, `${sid}.jsonl`), ligne({ type: 'user', ...base, timestamp: iso(t - 90e3), message: { role: 'user', content: 'salut' } })
    + ligne({ type: 'assistant', ...base, timestamp: iso(t - 5e3), message: { role: 'assistant', content: [{ type: 'tool_use', id: 'toolu_s', name: 'Bash', input: { command: commande } }] } }));
}
function fixture(home, lab, mio) {
  const P = path.join(home, '.claude', 'projects'), A = path.join(P, '-lab'), B = path.join(P, `-lab-${M_CHEMIN}`);
  const S1 = 'sess-ag-0001', S2 = 'sess-ch-0001';
  session(A, S1, lab, `echo ${M_DOING}`);
  const sous = path.join(A, S1, 'subagents');
  agent(sous, 'role1', { lab, sid: S1, mandat: `${M_MANDAT} faire une chose`, role: 'vf-coder' });
  agent(sous, 'gone1', { lab, sid: S1 });
  agent(sous, 'out1', { lab, sid: S1 });
  agent(sous, 'err1', { lab, sid: S1 });
  agent(sous, 'big1', { lab, sid: S1, octets: Number(mio) * (1 << 20) });
  session(B, S2, lab, 'echo second');
  agent(path.join(B, S2, 'subagents'), 'chem1', { lab, sid: S2 });
}

// ---------- copie instrumentée ----------
function une(texte, ancre, nom) { const n = texte.split(ancre).length - 1; if (n !== 1) { console.error(`ancre ${nom} : ${n} occurrence(s)`); process.exit(2); } }
function instrumenter(racine, compteur) {
  const C = JSON.stringify(compteur), S = path.join(racine, 'scripts');
  const eq = path.join(S, 'vf-cockpit-equipe.mjs'), tr = path.join(S, 'vf-cockpit-transcript.mjs');
  let a = fs.readFileSync(eq, 'utf8'); const ancreA = 'export function collecteAgents(ctx) {';
  une(a, ancreA, 'collecteAgents'); une(a, "import fs from 'node:fs';", 'import fs');
  a = a.replace("import fs from 'node:fs';", "import fs from 'node:fs';\nimport { appendFileSync as __ajout } from 'node:fs';")
    .replace(ancreA, ancreA + `\n  { const p = new Error().stack || ''; __ajout(${C}, (/revealDoing|revealTranscript|reveler/.test(p) ? 'requete' : 'tour') + '\\n'); }`);
  fs.writeFileSync(eq, a);
  let b = fs.readFileSync(tr, 'utf8'); const ancreB = 'export function reduireTranscript(fichier, { root, roles, kind } = {}) {';
  une(b, ancreB, 'reduireTranscript'); une(b, "import fs from 'node:fs';", 'import fs (transcript)');
  b = b.replace("import fs from 'node:fs';", "import fs from 'node:fs';\nimport { appendFileSync as __ajout } from 'node:fs';")
    .replace(ancreB, ancreB + `\n  if (String(fichier).includes('/agent-err1.jsonl')) { __ajout(${C}, 'levee\\n'); throw new Error('${M_ERREUR} ' + fichier); }`);
  fs.writeFileSync(tr, b);
}

// ---------- scénarios en processus ----------
const entree = (o) => JSON.stringify(o);
async function egal(scripts, lab, home, faux) {
  const T = await imp(scripts, 'vf-cockpit-agents-table.mjs'), W = await imp(scripts, 'vf-cockpit-who.mjs'), K = await imp(scripts, 'vf-cockpit-collecte.mjs');
  const sortie = fs.mkdtempSync(path.join(lab, '.vibeflow', 'cockpit', 'ag-')), opts = { home, scriptsDir: faux };
  const c = K.creerCollecte({ racine: lab, sortie, scriptsDir: faux, home });
  const ids = ['sess-ag-0001', 'role1', 'gone1', 'inconnu-xyz'], r = { avant: {}, egal: {}, sorti: {} };
  for (const id of ids) r.avant[id] = entree(await T.lireAgent('transcript', id)) === entree({ schema: 'vibeflow/cockpit-transcript@2', id, erreur: 'inconnu' });
  c.demander({ tour: true }); r.tour1 = await c.pret(60000);
  const sous = path.join(home, '.claude/projects/-lab/sess-ag-0001/subagents'), gone = path.join(sous, 'agent-gone1.jsonl'), sortant = path.join(sous, 'agent-out1.jsonl');
  const gardeGone = fs.readFileSync(gone), mt = fs.statSync(gone).mtime; // la fixture est rendue telle quelle à la fin (les scénarios suivants la relisent)
  fs.rmSync(gone);
  for (const id of ids) {
    const nouveau = { t: await T.lireAgent('transcript', id), d: await T.lireAgent('doing', id) };
    const ancien = { t: W.revealTranscript(lab, id, opts), d: W.revealDoing(lab, id, opts) };
    r.egal[id] = [entree(nouveau.t) === entree(ancien.t), entree(nouveau.d) === entree(ancien.d), nouveau.t.erreur || 'corps', nouveau.d.erreur || nouveau.d.doing];
  }
  r.mandat = (await T.lireAgent('transcript', 'role1')).mandat;
  const vieux = new Date(Date.now() - 25 * 3600e3), f = sortant, mtOut = fs.statSync(f).mtime;
  r.presentAvant = (await T.lireAgent('transcript', 'out1')).erreur === undefined;
  fs.utimesSync(f, vieux, vieux); c.demander({ tour: true }); await c.pret(60000);
  r.sorti = (await T.lireAgent('transcript', 'out1')).erreur;
  c.arreter(); fs.writeFileSync(gone, gardeGone); fs.utimesSync(gone, mt, mt); fs.utimesSync(f, mtOut, mtOut); console.log(JSON.stringify(r));
}
async function borne(scripts) {
  const T = await imp(scripts, 'vf-cockpit-agents-table.mjs'), t = T.creerTable({ max: T.TABLE_MAX }), r = { max: T.TABLE_MAX, retenus: [], inconnus: {} };
  for (const n of [1999, 2000, 2001, 2500]) {
    t.remplacer(Array.from({ length: n }, (_, i) => ({ kind: i % 2 ? 'subagent' : 'session', id: `t${i}`, _tr: `/x/t${i}.jsonl` })), new Map());
    let k = 0; for (let i = 0; i < n; i++) if (t.chercher(`t${i}`)) k++;
    r.retenus.push(k); r.inconnus[n] = [t.chercher(`t${n - 1}`) === null, t.chercher('t2000') === null];
  }
  console.log(JSON.stringify(r));
}
const attendre = (ms) => new Promise((res) => setTimeout(res, ms));
async function file(scripts, lab, sortie) {
  const T = await imp(scripts, 'vf-cockpit-agents-table.mjs'), K = await imp(scripts, 'vf-cockpit-collecte.mjs');
  const scen = (s) => fs.writeFileSync(path.join(sortie, 'scenario'), s), r = {};
  scen('retient');
  const c = K.creerCollecte({ racine: lab, sortie, scriptsDir: sortie, home: sortie, entree: new URL(import.meta.url) });
  const fauxT = () => { const fns = []; return { fns, h: { setTimeout: (f) => { fns.push(f); return fns.length; }, clearTimeout: () => {} } }; };
  const fige = fauxT(), etat = [], corps = [];
  for (let i = 0; i < 40; i++) T.lireAgent('transcript', `a${i}`, { horloge: fige.h }).then((b) => { etat.push(i); corps[i] = b; });
  await attendre(400);
  r.tot40 = etat.length; r.tot40Inconnus = etat.every((i) => corps[i].erreur === 'inconnu');
  scen('repond'); await attendre(600);
  r.tot40Apres = etat.length; r.bons = corps.filter((b) => b && b.schema === 'essai').length;
  scen('muet'); const muet = fauxT(), sm = [];
  for (let i = 0; i < 3; i++) T.lireAgent('transcript', `m${i}`, { horloge: muet.h }).then((b) => sm.push(b));
  await attendre(100); r.muetsAvant = sm.length; muet.fns.forEach((f) => f()); await attendre(100);
  r.muetsApres = sm.length; r.muetsInconnus = sm.every((b) => b.erreur === 'inconnu');
  scen('repond'); const nb = [];
  for (let i = 0; i < 17; i++) T.lireAgent('transcript', `n${i}`, { horloge: fige.h }).then((b) => nb.push(b));
  await attendre(600); r.nouveaux = nb.filter((b) => b.schema === 'essai').length; r.nouveauxInconnus = nb.filter((b) => b.erreur === 'inconnu').length;
  scen('mourir'); const mort = [];
  for (let i = 0; i < 2; i++) T.lireAgent('transcript', `d${i}`, { horloge: fige.h }).then((b) => mort.push(b));
  await attendre(1500); r.morts = mort.length; r.mortsInconnus = mort.every((b) => b.erreur === 'inconnu');
  scen('repond'); c.demander({ tour: true }); await c.pret(8000);
  const b = await T.lireAgent('transcript', 'apres', { horloge: fige.h }); r.apresRelance = b.schema === 'essai';
  c.arreter(); console.log(JSON.stringify(r));
}
async function erreur(scripts, lab) {
  const T = await imp(scripts, 'vf-cockpit-agents-table.mjs'), forge = `x\0${M_ERREUR}`, r = {};
  const t = T.creerTable({ max: 10 }); t.remplacer([{ kind: 'subagent', id: 'forge1', _tr: forge }, { kind: 'session', id: 'forge2', _tr: forge }], new Map());
  const vide = T.creerTable({ max: 10 });
  for (const q of ['transcript', 'doing']) {
    const b = T.lireDansLeFil({ quoi: q, id: 'forge1', table: t, racine: lab }), s = JSON.stringify(b);
    r[q] = [s === JSON.stringify(T.lireDansLeFil({ quoi: q, id: 'forge1', table: vide, racine: lab })), s.includes(M_ERREUR), s.includes(lab), Object.keys(b).sort().join(',')];
  }
  try { fs.statSync(forge); r.leve = 'non'; } catch (e) { r.leve = String(e.message).includes(M_ERREUR) ? 'oui' : 'sans-marqueur'; }
  console.log(JSON.stringify(r));
}
function rafale(port, jeton, id, n, groupe, pause) {
  const codes = [], t0 = Date.now();
  const un = () => new Promise((res) => http.get({ host: '127.0.0.1', port: Number(port), path: `/api/vf/transcript?id=${id}`, headers: { Host: `127.0.0.1:${port}`, 'x-vf-cockpit-token': jeton } },
    (r) => { r.resume(); r.on('end', () => { codes.push(r.statusCode); res(); }); }).on('error', () => { codes.push(0); res(); }));
  (async () => { for (let i = 0; i < Number(n); i += Number(groupe)) { await Promise.all(Array.from({ length: Math.min(Number(groupe), Number(n) - i) }, un)); await attendre(Number(pause)); } console.log(JSON.stringify({ codes, ms: Date.now() - t0 })); })();
}

if (isMainThread && process.argv[1] && import.meta.url === pathToFileURL(fs.realpathSync(process.argv[1])).href) {
  const [, , mode, a, b, c, d, e, f] = process.argv;
  if (mode === 'fixture') fixture(a, b, c);
  else if (mode === 'instrumenter') instrumenter(a, b);
  else if (mode === 'rafale') rafale(a, b, c, d, e, f);
  else if (mode === 'duree') { const W = await imp(a, 'vf-cockpit-who.mjs'), t0 = Date.now(); W.revealTranscript(b, d, { home: c }); console.log(Date.now() - t0); }
  else if (mode === 'tours') { const E = await imp(a, 'vf-cockpit-collecte-etapes.mjs'), memo = E.creerMemoire(); for (let i = 0; i < Number(e); i++) E.etapeTour({ racine: b, sortie: fs.mkdtempSync(path.join(b, '.vibeflow', 'cockpit', 'tr-')), scriptsDir: d, home: c, memo, sansIndex: true }); }
  else if (mode === 'egal') await egal(a, b, c, d);
  else if (mode === 'borne') await borne(a);
  else if (mode === 'file') await file(a, b, c);
  else if (mode === 'erreur') await erreur(a, b);
}
