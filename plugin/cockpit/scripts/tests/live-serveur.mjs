// live-serveur.mjs <vf-cockpit-live.mjs> [cas] — le diff de statuts de vf-cockpit-live.mjs, sans serveur HTTP ni Chrome (collecteur factice, seam `collecteur`).
// Cas (défaut : tout) :
//   sum        un résumé (summary) qui change seul, sans statut ni pied, part dans un patch
//   identique  un graphe relu au contenu identique (objets neufs) n'émet RIEN (ni patch vide, ni meta.vf comparé par référence)
//   snapshot   après un événement, snapshot().seq (le seq du hello suivant) égale le seq du dernier événement émis
// Sortie : une ligne JSON { cas: { ok, detail } }, code 0 si tous les cas demandés passent, 1 sinon, 2 si l'aide ne s'exécute pas.
import fs from 'node:fs'; import os from 'node:os'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , mod, cas = 'tout'] = process.argv;
if (!fs.existsSync(mod)) { console.log(JSON.stringify({ erreur: 'module absent : ' + mod })); process.exit(2); }
const { startLive } = await import(pathToFileURL(mod).href);
const lab = fs.mkdtempSync(path.join(process.env.TMPDIR || os.tmpdir(), 'live-serveur-'));
const graphe = (sum, st = 'todo', vf = { phases: 1 }) => ({ meta: { vf: { ...vf } }, nodes: [{ id: 'ph-1', st, foot: '1/2 plans', summary: sum }], files: [{ p: 'a.md', st: 'done', foot: '' }] });
const monter = () => {
  let cb = null; const evs = [];
  const collecteur = () => ({ demander() {}, surResultat(f) { cb = f; }, etat: () => ({ etat: 'ok' }), pret: async () => true, arreter() {} });
  const live = startLive({ root: lab, sortie: path.join(lab, '.vibeflow', 'cockpit'), onEvent: (n, d) => evs.push({ n, d }), mode: 'poll', garde: () => true, collecteur });
  const planning = (g) => cb({ type: 'planning', graphe: g, motifs: ['planning:x'] });
  return { live, evs, planning };
};
const R = {};
try {
  if (cas === 'tout' || cas === 'sum') {
    const { live, evs, planning } = monter(); planning(graphe('But A')); planning(graphe('But B'));
    const p = evs.filter((e) => e.n === 'patch'); const ref = p.flatMap((e) => e.d.patch).find((x) => x.ref === 'n:ph-1');
    R.sum = { ok: p.length === 1 && !!ref && ref.sum === 'But B', detail: { evenements: evs.map((e) => e.n), sum: ref ? ref.sum : null } }; live.stop();
  }
  if (cas === 'tout' || cas === 'identique') {
    const { live, evs, planning } = monter(); planning(graphe('But A')); planning(graphe('But A')); planning(graphe('But A'));
    R.identique = { ok: evs.length === 0, detail: { evenements: evs.map((e) => e.n + ':' + JSON.stringify(e.d.patch || []) + (e.d.vf ? ':vf' : '')) } }; live.stop();
  }
  if (cas === 'tout' || cas === 'snapshot') {
    const { live, evs, planning } = monter(); planning(graphe('But A')); planning(graphe('But A', 'done'));
    const dernier = evs.at(-1); const s = live.snapshot().seq;
    R.snapshot = { ok: !!dernier && typeof dernier.d.seq === 'number' && s === dernier.d.seq && s > 0, detail: { dernierSeq: dernier ? dernier.d.seq : null, snapshotSeq: s } }; live.stop();
  }
} catch (e) { console.log(JSON.stringify({ erreur: 'exécution : ' + String(e && e.message).slice(0, 200) })); fs.rmSync(lab, { recursive: true, force: true }); process.exit(2); }
fs.rmSync(lab, { recursive: true, force: true });
console.log(JSON.stringify(R));
process.exit(Object.values(R).length && Object.values(R).every((c) => c.ok) ? 0 : 1);
