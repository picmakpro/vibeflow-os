// query-cli.mjs : look things up in the graph.json of the lab you run it from (79-06, SOCL-09, P79-D-09). A standalone script of the
// cockpit module: the Claude Code CLI calls it, by its path in the module, when you ask questions from the map. It loads the graph
// query core from graph-query.js next to it (never from the lab's output folder, which any process of the lab can write) and reads
// graph.json from <current folder>/.vibeflow/cockpit as DATA (JSON.parse, never evaluated), after checking that its real path stays
// under the current folder (the lab root: the server runs the agent there).
//
// usage: node <module>/skills/cockpit-moteur/assets/query-cli.mjs overview
//        node <module>/skills/cockpit-moteur/assets/query-cli.mjs find "<words>" [--kind module|file|endpoint|symbol] [--limit 15]
//        node <module>/skills/cockpit-moteur/assets/query-cli.mjs show <id>
//        node <module>/skills/cockpit-moteur/assets/query-cli.mjs path <fromId> <toId>
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const argv = process.argv.slice(2);
const flag = (name) => { const i = argv.indexOf('--' + name); if (i < 0) return undefined; const v = argv[i + 1]; argv.splice(i, 2); return v; };
const kind = flag('kind'), limit = flag('limit');
const [cmd, ...rest] = argv;
try {
  if (!['overview', 'find', 'show', 'path'].includes(cmd)) { console.log('commands: overview | find "<words>" [--kind module|file|endpoint|symbol] | show <id> | path <fromId> <toId>'); process.exit(cmd ? 1 : 0); }
  const lab = fs.realpathSync(process.cwd());
  const file = fs.realpathSync(path.join(lab, '.vibeflow', 'cockpit', 'graph.json'));
  if (!file.startsWith(lab + path.sep)) throw new Error('graph.json is outside the lab: refused');
  const G = JSON.parse(fs.readFileSync(file, 'utf8'));
  const core = fs.readFileSync(path.join(here, 'graph-query.js'), 'utf8');
  const { createGraphQuery: creer } = new Function(`${core}; return { createGraphQuery };`)();
  const q = creer(G);
  let out;
  if (cmd === 'overview') out = q.overview();
  else if (cmd === 'find') out = q.find(rest.join(' '), kind, limit);
  else if (cmd === 'show') out = q.show(rest[0]);
  else out = q.path(rest[0], rest[1]);
  console.log(JSON.stringify(out, null, 1));
} catch (e) {
  console.log(JSON.stringify({ error: e.message }));
  process.exit(1);
}
