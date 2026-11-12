// collecte-labo — fixtures de la suite test-cockpit-collecte.sh (79-09) : lab git neutre avec planning, faux verrou, session fraîche dans un
// HOME jetable.
// Exports : creerLab(dir), ecrireFauxVerrou(dir), ecrireSession(home, lab, id), ecrireLourd(home, lab, opts), ecrireGeant(home, lab, id, octets),
//           ecrireAncienne(home, lab, id), ecrireVoie(home, cwd, id, seed).
// CLI : node collecte-labo.mjs lab <dir> | verrou <dir> | session <home> <lab> <id> | lourd <home> <lab> | geant <home> <lab> <id> [octets]
//       | ancienne <home> <lab> <id>
// Modes de la tâche 2 : `lourd` (16 sessions de 3 sous-agents, environ 50 Mio, dates récentes), `geant` (une session dont une ligne dépasse la
// borne de lecture de l'index ; écrite au test, jamais commitée), `ancienne` (session datée de 25 h, appel d'outil non résolu, fichier récent).
// Les transcripts viennent du générateur à graine de 79-08 (importé, jamais dupliqué) dont les dates sont décalées vers le présent.
// Le faux verrou consigne le verbe appelé dans VF_FAUX_JOURNAL, dort VF_FAUX_DELAI secondes pour `status` seulement et rend les formes
// minimales de `status`, `orphans` et `registry` (79-03). Rien ici n'importe le code testé : une fixture ne dépend pas de ce qu'elle sert
// à prouver.
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { gen } from './index-generateur.mjs';

const git = (lab, ...a) => execFileSync('git', ['-C', lab, '-c', 'user.email=t@t', '-c', 'user.name=t', ...a], { stdio: 'ignore' });

export function creerLab(dir) {
  fs.mkdirSync(path.join(dir, '.planning', 'phases', '01-x'), { recursive: true });
  fs.mkdirSync(path.join(dir, '.vibeflow', 'cockpit'), { recursive: true });
  fs.writeFileSync(path.join(dir, '.planning', 'ROADMAP.md'), '- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - deuxième jet\n');
  fs.writeFileSync(path.join(dir, '.planning', 'REQUIREMENTS.md'), '- [x] **REQ-01**: premier\n- [ ] **REQ-02**: second\n');
  fs.writeFileSync(path.join(dir, '.planning', 'phases', '01-x', '01-01-PLAN.md'), '<objective>socle</objective>\n');
  fs.writeFileSync(path.join(dir, '.planning', 'phases', '01-x', '01-01-SUMMARY.md'), 'ok\n');
  git(dir, 'init', '-q'); git(dir, 'add', '-A'); git(dir, 'commit', '-q', '-m', 'init');
}

export function ecrireFauxVerrou(dir) {
  fs.mkdirSync(dir, { recursive: true });
  const f = path.join(dir, 'driver-lock.sh');
  fs.writeFileSync(f, [
    '#!/usr/bin/env bash',
    '[ -z "${VF_FAUX_JOURNAL:-}" ] || echo "$1" >> "$VF_FAUX_JOURNAL"',
    'case "$1" in',
    '  status) [ -z "${VF_FAUX_DELAI:-}" ] || sleep "$VF_FAUX_DELAI"; echo \'{"locks":[]}\' ;;',
    '  orphans) echo \'{"orphans":[]}\' ;;',
    '  registry) echo \'{"present": false, "count": 0, "agents": []}\' ;;',
    '  *) echo \'{}\' ;;',
    'esac', ''].join('\n'));
  fs.chmodSync(f, 0o755);
}

export function ecrireSession(home, lab, id) {
  const d = path.join(home, '.claude', 'projects', '-lab');
  fs.mkdirSync(d, { recursive: true });
  const base = { cwd: lab, sessionId: id, gitBranch: 'main', version: '2.1.316' };
  fs.writeFileSync(path.join(d, `${id}.jsonl`), [
    { type: 'user', timestamp: '2026-11-01T10:00:00Z', message: { content: 'salut' }, ...base },
    { type: 'assistant', timestamp: '2026-11-01T10:00:05Z', ...base,
      message: { content: [{ type: 'tool_use', name: 'Bash', input: { description: 'x', command: 'ls' } }] } },
  ].map((o) => JSON.stringify(o)).join('\n') + '\n');
}

const ISO = /"timestamp":"([^"]+)"/g;
// texte du transcript d'une voie, dates décalées pour que la dernière tombe à `finA` (ms) ; `remplissage` lignes de 8 Kio datées de la seconde suivante
function texte(seed, lab, id, finA, { remplissage = 0, abandonne = false } = {}) {
  let t = gen(seed, { lab, id, abandonne }).buf.toString('utf8');
  const max = Math.max(...[...t.matchAll(ISO)].map((m) => Date.parse(m[1])));
  const d = finA - max - remplissage * 1000;
  t = t.replace(ISO, (_, x) => `"timestamp":"${new Date(Date.parse(x) + d).toISOString()}"`);
  for (let k = 1; k <= remplissage; k++) {
    t += JSON.stringify({ type: 'user', timestamp: new Date(max + d + k * 1000).toISOString(), cwd: lab, sessionId: id, version: '2.1.322', message: { role: 'user', content: 'x'.repeat(8000) } }) + '\n';
  }
  return t;
}
const projets = (home) => { const d = path.join(home, '.claude', 'projects', '-lab'); fs.mkdirSync(d, { recursive: true }); return d; };
const metaSous = (n) => ({ agentType: 'vf-coder', description: 'tache', spawnDepth: 1, toolUseId: `toolu_lourd_${n}`, requestShape: 'foreground' });

export function ecrireLourd(home, lab, { sessions = 16, sous = 3, remplissage = 95 } = {}) {
  const d = projets(home), fin = Date.now() - 3600e3; let n = 0;
  for (let s = 0; s < sessions; s++) {
    const sid = `lourde${String(s).padStart(2, '0')}-aaaa-bbbb-cccc-dddddddddddd`;
    fs.writeFileSync(path.join(d, `${sid}.jsonl`), texte(1000 + s, lab, sid, fin, { remplissage }));
    const sub = path.join(d, sid, 'subagents'); fs.mkdirSync(sub, { recursive: true });
    for (let a = 0; a < sous; a++, n++) {
      const aid = `ag${String(s).padStart(2, '0')}${a}${'0'.repeat(10)}`;
      fs.writeFileSync(path.join(sub, `agent-${aid}.jsonl`), texte(5000 + n, lab, aid, fin, { remplissage }));
      fs.writeFileSync(path.join(sub, `agent-${aid}.meta.json`), JSON.stringify(metaSous(n)));
    }
  }
}

// une session saine, puis une session dont UNE ligne dépasse la borne de lecture de l'index (octets + 1 Mio : 33 Mio avec la borne livrée)
export function ecrireGeant(home, lab, id, octets = 33554432 + (1 << 20)) {
  const d = projets(home), fin = Date.now() - 600e3;
  fs.writeFileSync(path.join(d, `sain-${id}.jsonl`), texte(78, lab, `sain-${id}`, fin)); // une voie saine à côté : « les autres voies sont indexées »
  fs.writeFileSync(path.join(d, `${id}.jsonl`), texte(77, lab, id, fin));
  fs.appendFileSync(path.join(d, `${id}.jsonl`), JSON.stringify({ type: 'user', timestamp: new Date(fin + 1000).toISOString(), cwd: lab, sessionId: id, message: { role: 'user', content: 'y'.repeat(octets) } }) + '\n');
}

// une session saine et récente dont le `cwd` est `cwd` (les arbres de la preuve d'appartenance, C4.8)
export function ecrireVoie(home, cwd, id, seed = 9) { fs.writeFileSync(path.join(projets(home), `${id}.jsonl`), texte(seed, cwd, id, Date.now() - 600e3)); }

export function ecrireAncienne(home, lab, id) {
  const d = projets(home);
  fs.writeFileSync(path.join(d, `${id}.jsonl`), texte(31, lab, id, Date.now() - 25 * 3600e3, { abandonne: true })); // mtime = maintenant, lignes de 25 h, dernier appel ouvert
}

if (process.argv[1] && fs.realpathSync(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const [, , verbe, a, b, c] = process.argv;
  if (verbe === 'lab') creerLab(a);
  else if (verbe === 'verrou') ecrireFauxVerrou(a);
  else if (verbe === 'session') ecrireSession(a, b, c);
  else if (verbe === 'lourd') ecrireLourd(a, b);
  else if (verbe === 'geant') ecrireGeant(a, b, c, process.argv[6] ? Number(process.argv[6]) : undefined);
  else if (verbe === 'ancienne') ecrireAncienne(a, b, c);
  else { console.error('collecte-labo : lab <dir> | verrou <dir> | session <home> <lab> <id> | lourd <home> <lab> | geant <home> <lab> <id> [octets] | ancienne <home> <lab> <id>'); process.exit(64); }
}
