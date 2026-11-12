// contrôle : aucun segment de chemin du poste dans le relevé (fragment « dossier/ » ou segment long du HOME / de l'arbre de travail)
import fs from 'node:fs'; import os from 'node:os'; import { execFileSync } from 'node:child_process';
const f = process.argv[2], j = JSON.parse(fs.readFileSync(f, 'utf8')); const txt = [];
(function m(x) { if (typeof x === 'string') txt.push(x); else if (x && typeof x === 'object') Object.values(x).forEach(m); })(j);
const top = execFileSync('git', ['rev-parse', '--show-toplevel'], { encoding: 'utf8' }).trim();
const segs = [...new Set([...os.homedir().split('/'), ...top.split('/')])].filter((s) => s.length >= 6 && !/^(Documents|worktrees|plugin|cockpit)$/.test(s) || /^(Users|samuel)$/.test(s));
const mal = txt.filter((t) => /^[-\w.]+\/$/.test(t) || segs.some((s) => t.includes(s)));
console.log(mal.length ? 'ROUGE ' + JSON.stringify(mal.slice(0, 5)) : 'OK'); process.exit(mal.length ? 1 : 0);
