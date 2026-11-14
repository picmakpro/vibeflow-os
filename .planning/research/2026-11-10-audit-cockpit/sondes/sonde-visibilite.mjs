// Sonde : que rend le collecteur REEL (collectWho) pour une session et un sous-agent muets depuis N secondes ?
// HOME factice dans le scratchpad (aucune ecriture dans le depot ni dans ~/.claude). Temoin positif : N = 60 s (doit etre visible).
import fs from 'node:fs';
import path from 'node:path';
const [, , depot, scratch] = process.argv;
const { collectWho } = await import(path.join(depot, 'plugin/cockpit/scripts/vf-cockpit-who.mjs'));
const { buildEquipeGraph } = await import(path.join(depot, 'plugin/cockpit/scripts/vf-cockpit-equipe-carte.mjs'));
const SID = '11111111-1111-4111-8111-111111111111', MGR = 'a00000000000000001', WRK = 'a00000000000000002', FIN = 'a00000000000000003';
const ligne = (o) => JSON.stringify(o) + '\n';
const base = (extra) => ({ cwd: depot, sessionId: SID, version: '2.1.322', gitBranch: 'release/v2.77.0', userType: 'external', ...extra });
function monter(nom, { ageSession, ageMgr, ageWrk, mgrFini = false, avecFini = false }) {
  const home = path.join(scratch, 'home-' + nom); fs.rmSync(home, { recursive: true, force: true });
  const dir = path.join(home, '.claude', 'projects', '-sonde'); const sub = path.join(dir, SID, 'subagents'); fs.mkdirSync(sub, { recursive: true });
  const now = Date.now(); const iso = (s) => new Date(now - s * 1000).toISOString();
  const poser = (f, lignes, age) => { fs.writeFileSync(f, lignes.join('')); const t = new Date(now - age * 1000); fs.utimesSync(f, t, t); };
  poser(path.join(dir, SID + '.jsonl'), [
    ligne(base({ type: 'user', timestamp: iso(ageSession + 100), message: { role: 'user', content: 'x' }, uuid: 'u1', parentUuid: null })),
    ligne(base({ type: 'assistant', timestamp: iso(ageSession), uuid: 'u2', parentUuid: 'u1', message: { role: 'assistant', id: 'm1', model: 'm', stop_reason: 'tool_use', content: [{ type: 'tool_use', id: 't1', name: 'Agent', input: { subagent_type: 'vf-dev-manager' } }] } })),
  ], ageSession);
  const agent = (id, role, parent, depth, age, fini, outil) => {
    fs.writeFileSync(path.join(sub, `agent-${id}.meta.json`), JSON.stringify({ agentType: role, description: 'tache ' + role, spawnDepth: depth, toolUseId: 't' + id, requestShape: 'background', ...(parent ? { parentAgentId: parent } : {}), ...(fini ? { finished: true } : {}) }));
    poser(path.join(sub, `agent-${id}.jsonl`), [
      ligne(base({ type: 'user', isSidechain: true, agentId: id, timestamp: iso(age + 600), message: { role: 'user', content: 'mandat' }, uuid: 'a1', parentUuid: null })),
      ligne(base({ type: 'assistant', isSidechain: true, agentId: id, timestamp: iso(age), uuid: 'a2', parentUuid: 'a1', message: { role: 'assistant', id: 'm' + id, model: 'm', stop_reason: fini ? 'end_turn' : 'tool_use', content: fini ? [{ type: 'text', text: 'fin' }] : [{ type: 'tool_use', id: 'tb' + id, name: outil, input: outil === 'Bash' ? { command: 'npm test' } : { subagent_type: 'vf-coder' } }] } })),
    ], age);
  };
  agent(MGR, 'vf-dev-manager', null, 1, ageMgr, mgrFini, 'Agent');
  agent(WRK, 'vf-coder', MGR, 2, ageWrk, false, 'Bash');
  if (avecFini) agent(FIN, 'vf-reviewer', MGR, 2, 3600, true, 'Bash');
  return home;
}
const voir = (nom, cfg) => {
  const home = monter(nom, cfg);
  const w = collectWho(depot, { home });
  const ag = w.workers.filter((x) => x.kind === 'session' || x.kind === 'subagent').map((x) => `${x.kind === 'session' ? 'session' : x.role}:${x.etat}(${x.ageS}s)`);
  const g = buildEquipeGraph(w, {});
  const carte = g.nodes.find((n) => n.id === 'ag-' + WRK);
  console.log(`${nom.padEnd(34)} busy=${String(w.busy).padEnd(5)} agents=[${ag.join(', ') || 'aucun'}]${carte ? `  carte du worker: parent=${carte.parent} st=${carte.st}` : ''}  resume="${g.project.summary}"`);
};
console.log('cas                                resultat du collecteur reel');
voir('temoin-tout-frais-60s', { ageSession: 60, ageMgr: 60, ageWrk: 60 });
voir('worker-en-commande-longue-10min', { ageSession: 600, ageMgr: 600, ageWrk: 600 });
voir('idem-avec-un-frere-termine', { ageSession: 600, ageMgr: 600, ageWrk: 600, avecFini: true });
voir('worker-frais-manager-muet', { ageSession: 600, ageMgr: 600, ageWrk: 30 });
voir('worker-frais-manager-TERMINE', { ageSession: 600, ageMgr: 600, ageWrk: 30, mgrFini: true });
voir('session-au-repos-5min-sans-agent', { ageSession: 300, ageMgr: 90000, ageWrk: 90000 });
