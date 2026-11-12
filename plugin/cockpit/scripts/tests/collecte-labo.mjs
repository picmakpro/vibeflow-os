// collecte-labo — fixtures de la suite test-cockpit-collecte.sh (79-09) : lab git neutre avec planning, faux verrou, session fraîche dans un
// HOME jetable.
// Exports : creerLab(dir), ecrireFauxVerrou(dir), ecrireSession(home, lab, id).
// CLI : node collecte-labo.mjs lab <dir> | verrou <dir> | session <home> <lab> <id>
// Le faux verrou consigne le verbe appelé dans VF_FAUX_JOURNAL, dort VF_FAUX_DELAI secondes pour `status` seulement et rend les formes
// minimales de `status`, `orphans` et `registry` (79-03). Rien ici n'importe le code testé : une fixture ne dépend pas de ce qu'elle sert
// à prouver.
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

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

if (process.argv[1] && fs.realpathSync(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const [, , verbe, a, b, c] = process.argv;
  if (verbe === 'lab') creerLab(a);
  else if (verbe === 'verrou') ecrireFauxVerrou(a);
  else if (verbe === 'session') ecrireSession(a, b, c);
  else { console.error('collecte-labo : lab <dir> | verrou <dir> | session <home> <lab> <id>'); process.exit(64); }
}
