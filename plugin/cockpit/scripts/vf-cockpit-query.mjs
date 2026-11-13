// vf-cockpit-query (67-05, promu du spike 005 ; 79-06, SOCL-09, P79-D-09) : interroger le graphe Projet (project.html), comme query-cli.mjs
// le fait pour le graphe de code. L'agent de l'onglet Projet l'appelle PAR SON CHEMIN DANS LE MODULE (c'est l'un des deux seuls Bash que son
// confinement autorise) ; les résultats portent st et foot. Le cœur de requête est lu dans graph-query.js du moteur du module (jamais dans
// la sortie du lab, inscriptible par tout processus du lab) ; le lab est trouvé depuis le dossier courant et project.html est lu dans sa
// sortie, après contrôle que le chemin reste sous le lab.
//
// usage: node <module>/scripts/vf-cockpit-query.mjs overview
//        node <module>/scripts/vf-cockpit-query.mjs find "<mots>" [--limit 15]
//        node <module>/scripts/vf-cockpit-query.mjs show <id>
//        node <module>/scripts/vf-cockpit-query.mjs status <done|active|todo|blocked> [--in <id>] [--limit 30]
//        node <module>/scripts/vf-cockpit-query.mjs path <idA> <idB>
//        node <module>/scripts/vf-cockpit-query.mjs ask "<question>"      (voie locale seule, pour tester)
// Codes : 0 ok · 1 commande inconnue ou erreur (JSON { error }).
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { extraireGraphe } from './vf-cockpit-embed.mjs';
import { projectIndex, answerLocally } from './vf-cockpit-ask.mjs';
import { findLabRoot, engineDir, outputDir, confiner } from './vf-cockpit-paths.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
let G, q, I;
try {
  const lab = findLabRoot(process.cwd());
  if (!lab) throw new Error('aucun lab (dossier .planning) trouvé depuis le dossier courant');
  const moteur = engineDir(here).chemin;
  if (!moteur) throw new Error('moteur du module introuvable à côté du dossier de scripts');
  const page = confiner(lab, path.join(outputDir(lab), 'project.html'));
  G = extraireGraphe(fs.readFileSync(page, 'utf8'));
  // moteur de requête du graphe (graph-query.js du module), comme le serveur le charge
  const coreSrc = fs.readFileSync(path.join(moteur, 'assets', 'graph-query.js'), 'utf8');
  const { createGraphQuery } = new Function(`${coreSrc}; return { createGraphQuery };`)();
  q = createGraphQuery(G); I = projectIndex(G);
} catch (e) {
  console.log(JSON.stringify({ error: e.message }));
  process.exit(1);
}

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
