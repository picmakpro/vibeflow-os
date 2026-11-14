import fs from 'node:fs'; import path from 'node:path';
const [, , home, lab, sid] = process.argv; const now = Date.now();
const dir = path.join(home, '.claude', 'projects', '-lab'); const sub = path.join(dir, sid, 'subagents'); fs.mkdirSync(sub, { recursive: true });
const iso = (ms) => new Date(ms).toISOString(); const base = (o) => ({ cwd: lab, sessionId: sid, gitBranch: 'main', version: '2.1.317', ...o });
const put = (f, lignes) => fs.writeFileSync(f, lignes.map((l) => JSON.stringify(l)).join('\n') + '\n');
put(path.join(dir, sid + '.jsonl'), [base({ type: 'user', timestamp: iso(now - 600000), message: { content: 'salut' } }), base({ type: 'assistant', timestamp: iso(now - 5000), message: { content: [{ type: 'tool_use', name: 'Bash', input: { command: 'echo bonjour' } }] } })]);
const agents = [{ id: 'mgr1', d: 1, role: 'vf-dev-manager' }]; for (let i = 1; i <= 9; i++) agents.push({ id: 'act' + i, d: 2, parent: 'mgr1', role: 'vf-coder' });
for (const a of agents) {
  const meta = { agentType: a.role, isBuiltIn: false, launchedWithDefaults: false, description: 'tâche synthétique ' + a.id, toolUseId: 'toolu_' + a.id, spawnDepth: a.d, requestShape: 'background', requestNonInteractive: true };
  if (a.d >= 2) meta.parentAgentId = a.parent;
  fs.writeFileSync(path.join(sub, `agent-${a.id}.meta.json`), JSON.stringify(meta));
  put(path.join(sub, `agent-${a.id}.jsonl`), [base({ type: 'user', isSidechain: true, agentId: a.id, parentUuid: null, timestamp: iso(now - 300000), message: { role: 'user', content: 'mandat de ' + a.id } }), base({ type: 'assistant', isSidechain: true, agentId: a.id, timestamp: iso(now - 4000), message: { role: 'assistant', content: [{ type: 'tool_use', id: 'toolu_x' + a.id, name: 'Read', input: { file_path: lab + '/README.md' } }] } })]);
}
