#!/usr/bin/env node
// etat-labo.mjs — aide de test-cockpit-etat.sh (79-12) : lab de démonstration, faux verrou à journal, lancement de l'émetteur de vf-signal.
//   lab <dossier>                                  dépôt git, planning à deux phases, un plan et son bilan, un commit
//   verrou <dossier> <lab>                         faux driver-lock.sh dans <dossier> ; chaque appel écrit « verbe PPID » dans <lab>/.vibeflow/journal-verrou ;
//                                                  l'instant de départ des âges est lu d'un fichier posé à côté du script (jamais d'une variable d'environnement)
//   emetteur <scripts> <lab> <faux> [coupe-ms]     lance l'émetteur du dossier <scripts> ; une ligne JSON { code, sortie, pid, ms, tue }
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync, spawn } from 'node:child_process';

const [, , mode, a1, a2, a3, a4] = process.argv;

if (mode === 'lab') {
  const L = a1;
  fs.mkdirSync(path.join(L, '.planning', 'phases', '01-x'), { recursive: true });
  fs.mkdirSync(path.join(L, '.vibeflow', 'cockpit'), { recursive: true });
  fs.writeFileSync(path.join(L, '.planning', 'ROADMAP.md'), '- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - deuxième jet\n');
  fs.writeFileSync(path.join(L, '.planning', 'REQUIREMENTS.md'), '- [x] **REQ-01**: premier\n- [ ] **REQ-02**: second\n');
  fs.writeFileSync(path.join(L, '.planning', 'phases', '01-x', '01-01-PLAN.md'), '<objective>socle</objective>\n');
  fs.writeFileSync(path.join(L, '.planning', 'phases', '01-x', '01-01-SUMMARY.md'), 'ok\n');
  const g = (...a) => execFileSync('git', ['-C', L, '-c', 'user.email=t@t', '-c', 'user.name=t', ...a], { stdio: 'ignore' });
  g('init', '-q'); g('add', '-A'); g('commit', '-q', '-m', 'init');
} else if (mode === 'verrou') {
  const D = a1, L = a2;
  fs.mkdirSync(D, { recursive: true });
  fs.mkdirSync(path.join(L, '.vibeflow'), { recursive: true });
  fs.writeFileSync(path.join(D, 'debut'), String(Math.floor(Date.now() / 1000)));
  fs.writeFileSync(path.join(D, 'driver-lock.sh'), `#!/usr/bin/env bash
D="$(cd "$(dirname "$0")" && pwd)"; T0="$(cat "$D/debut")"; N=$(( $(date +%s) - T0 ))
mkdir -p "${L}/.vibeflow"; echo "$1 $PPID" >> "${L}/.vibeflow/journal-verrou"
case "$1" in
  status) printf '{"locks":[{"present":true,"scope":"depot","ws":"","phase":"","stale":false,"age_seconds":%s,"ttl":1800,"progress_age_seconds":%s,"owner":"essai"}]}\\n' "$N" "$N" ;;
  orphans) echo '{"orphans":[]}' ;;
  registry) echo '{"present": false, "count": 0, "agents": []}' ;;
  *) echo '{}' ;;
esac
`, { mode: 0o755 });
} else if (mode === 'emetteur') {
  const [scripts, lab, faux, coupe] = [a1, a2, a3, Number(a4) || 0];
  const t0 = Date.now();
  const sonde = process.env.ETAT_SONDE; // préchargement facultatif (etat-sonde.mjs) : la suite compte les connexions de l'émetteur
  const enf = spawn(process.execPath, [...(sonde ? ['--import', sonde] : []), path.join(scripts, 'vf-cockpit-signal.mjs'), lab], {
    stdio: ['ignore', 'pipe', 'ignore'], env: { ...process.env, VF_COCKPIT_SCRIPTS_DIR: faux },
  });
  let sortie = '', tue = false;
  enf.stdout.on('data', (c) => { if (sortie.length < 8 << 20) sortie += c; });
  const minuteur = coupe ? setTimeout(() => { tue = true; enf.kill('SIGKILL'); }, coupe) : null;
  enf.on('close', (code) => { clearTimeout(minuteur); console.log(JSON.stringify({ code, sortie, pid: enf.pid, ms: Date.now() - t0, tue })); process.exit(0); });
}
