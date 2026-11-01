// floorplan/vf-query.mjs (spike 005) : interroger le graphe Projet (project.html), comme query.mjs le
// fait pour le graphe de code. L'agent de l'onglet Projet l'appelle ; les résultats portent st et foot.
//
// usage: node floorplan/vf-query.mjs overview
//        node floorplan/vf-query.mjs find "<mots>" [--limit 15]
//        node floorplan/vf-query.mjs show <id>
//        node floorplan/vf-query.mjs status <done|active|todo|blocked> [--in <id>] [--limit 30]
//        node floorplan/vf-query.mjs path <idA> <idB>
//        node floorplan/vf-query.mjs ask "<question>"      (voie locale seule, pour tester)
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { extract, projectIndex, answerLocally } from './vf-ask.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const G = extract(fs.readFileSync(path.join(here, 'project.html'), 'utf8'));
// moteur de floorplan (query.mjs, partie avant la CLI), comme serve.mjs le charge
const coreSrc = fs.readFileSync(path.join(here, 'query.mjs'), 'utf8').split('// ---- cli ----')[0];
const { createGraphQuery } = new Function(`${coreSrc.replace(/^import .*$/gm, '')}; return { createGraphQuery };`)();
const q = createGraphQuery(G), I = projectIndex(G);

const argv = process.argv.slice(2);
const flag = (name) => { const i = argv.indexOf('--' + name); if (i < 0) return undefined; const v = argv[i + 1]; argv.splice(i, 2); return v; };
const limit = Number(flag('limit')) || 0, inside = flag('in');
const [cmd, ...rest] = argv;
// ajoute statut et pied à tout objet qui porte un id de carte, à n'importe quelle profondeur
const enrich = (v) => {
  if (Array.isArray(v)) return v.map(enrich);
  if (v && typeof v === 'object') {
    const o = Object.fromEntries(Object.entries(v).map(([k, x]) => [k, enrich(x)]));
    const x = typeof o.id === 'string' && I.get(o.id);
    if (x) { if (x.st) o.st = x.st; if (x.foot) o.foot = x.foot; }
    return o;
  }
  return v;
};
const brief = (x) => ({ id: I.ref(x), name: I.label(x), st: x.st, foot: x.foot, under: x.n || x.parent || null });
try {
  let out;
  if (cmd === 'overview') {
    const vf = G.meta.vf || {};
    out = { project: G.project, now: { milestone: vf.milestone, phase: vf.phase, phaseName: vf.phaseName, status: vf.status, lastActivity: vf.lastActivity }, milestones: vf.milestones, top: G.nodes.filter((n) => !n.parent).map(brief) };
  } else if (cmd === 'find') out = enrich(q.find(rest.join(' '), undefined, limit || 15));
  else if (cmd === 'show') {
    const x = I.get(q.normId ? q.normId(rest[0]) : rest[0]) || I.get(rest[0]);
    if (!x) throw new Error(`id inconnu : ${rest[0]}`);
    out = { ...brief(x), summary: x.summary || x.d || '', details: (x.details || '').slice(0, 1500),
      children: x.id ? [...(I.kids.get(x.id) || []), ...(I.files.get(x.id) || [])].slice(0, 60).map(brief) : [],
      touched: x.touched?.slice(0, 40), links: G.links.filter((l) => l.a === I.ref(x) || l.b === I.ref(x)).slice(0, 40).map((l) => ({ from: l.a, to: l.b, kind: G.meta.kindLabels?.[l.k] || l.k, label: l.label })) };
  } else if (cmd === 'status') {
    const pool = inside ? I.under(String(inside).replace(/^n:/, '')) : [...G.nodes, ...G.files];
    const xs = pool.filter((x) => x.st === rest[0]);
    out = { status: rest[0], in: inside || null, total: xs.length, items: xs.slice(0, limit || 30).map(brief) };
  } else if (cmd === 'path') out = enrich(q.path(rest[0], rest[1]));
  else if (cmd === 'ask') out = answerLocally(G, rest.join(' ')) || { local: null, note: "hors des formes connues : l'agent répondrait" };
  else { console.log('commandes : overview | find "<mots>" | show <id> | status <st> [--in <id>] | path <a> <b> | ask "<question>"'); process.exit(cmd ? 1 : 0); }
  console.log(JSON.stringify(out, null, 1));
} catch (e) {
  console.log(JSON.stringify({ error: e.message }));
  process.exit(1);
}
