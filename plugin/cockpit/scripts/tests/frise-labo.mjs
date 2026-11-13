#!/usr/bin/env node
// frise-labo.mjs — aide de test-cockpit-frise.sh (79-13) : labs, transcripts valides, faux `claude`, frises forgées. Aucune donnée du poste : le jalon
// `@LAB@` d'une chaîne du spec est remplacé par le lab ; identifiants synthétiques. N'importe jamais le code testé (une fixture ne dépend pas de ce qu'elle sert).
//   lab <dossier>                              dépôt git, planning à deux phases, `src/a.js` et `src/b.js`, un commit
//   transcripts <home> <lab> <spec.json>       écrit sous <home>/.claude/projects/-lab/ des sessions de forme valide
//        spec : { sessions: [{ id, lignes: [{ age: secondes, outils: [{ name, input, ouvert }] }] }] } ; `age` : ancienneté de la ligne (jamais plus de 24 h)
//   claude-faux <dossier> <json>               pose (ou réécrit) un faux `claude agents --json` dans <dossier> qui imprime <json>
//   forge <sortie.json> <nombre> [variante]    liste de voies forgées, valides et cohérentes (segments croissants, durées = somme des segments)
//   arbres <dossier>                           dépôt réel et worktrees réels (voir l'en-tête de la section) ; imprime un JSON { lab, principal, wt… }
//   volumineux <home> <lab> <voies> <appels>   voies de plusieurs Mio, appels d'outil à entrées variées (écrites sous <home>)
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const [, , mode, a1, a2, a3, a4, a5] = process.argv;
const ISO = (ms) => new Date(ms).toISOString();
const GIT_ENV = { ...process.env, GIT_CONFIG_NOSYSTEM: '1', GIT_CONFIG_GLOBAL: '/dev/null' };
for (const k of ['GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_COMMON_DIR', 'GIT_OBJECT_DIRECTORY', 'GIT_NAMESPACE', 'GIT_CEILING_DIRECTORIES']) delete GIT_ENV[k];
const git = (dir, ...a) => execFileSync('git', ['-C', dir, '-c', 'user.email=t@t', '-c', 'user.name=t', ...a], { stdio: 'ignore', env: GIT_ENV });

function creerLab(L) {
  fs.mkdirSync(path.join(L, '.planning', 'phases', '01-x'), { recursive: true });
  fs.mkdirSync(path.join(L, '.vibeflow', 'cockpit'), { recursive: true });
  fs.mkdirSync(path.join(L, 'src'), { recursive: true });
  fs.writeFileSync(path.join(L, '.planning', 'ROADMAP.md'), '- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - deuxième jet\n');
  fs.writeFileSync(path.join(L, '.planning', 'REQUIREMENTS.md'), '- [x] **REQ-01**: premier\n- [ ] **REQ-02**: second\n');
  fs.writeFileSync(path.join(L, '.planning', 'phases', '01-x', '01-01-PLAN.md'), '<objective>socle</objective>\n');
  fs.writeFileSync(path.join(L, '.planning', 'phases', '01-x', '01-01-SUMMARY.md'), 'ok\n');
  fs.writeFileSync(path.join(L, 'src', 'a.js'), 'export const a = 1;\n');
  fs.writeFileSync(path.join(L, 'src', 'b.js'), 'export const b = 2;\n');
  fs.writeFileSync(path.join(L, '.gitignore'), '.vibeflow/\n');
  git(L, 'init', '-q'); git(L, 'add', '-A'); git(L, 'commit', '-q', '-m', 'init');
}

// une ligne `assistant` datée, de la forme que lit l'index (79-08) : identifiant de message, jetons, blocs
let SEQ = 0;
export function ligneAssistant({ lab, sid, t, outils = [], texte = 'MARQ-TEXTE' }) {
  const mid = `msg_${sid}_${++SEQ}`, blocs = [{ type: 'text', text: texte }];
  const ids = outils.map((o) => { const id = o.id || `toolu_${sid}_${++SEQ}`; blocs.push({ type: 'tool_use', id, name: o.name, input: o.input }); return id; });
  const a = { type: 'assistant', timestamp: ISO(t), cwd: lab, sessionId: sid, version: '2.1.322', gitBranch: 'main',
    message: { id: mid, model: 'claude-test-1', role: 'assistant', stop_reason: 'tool_use', usage: { input_tokens: 10, output_tokens: 5, cache_read_input_tokens: 0, cache_creation_input_tokens: 0 }, content: blocs } };
  const res = outils.filter((o) => !o.ouvert).map((o, i) => ({ type: 'user', timestamp: ISO(t + 500), cwd: lab, sessionId: sid, version: '2.1.322',
    message: { role: 'user', content: [{ type: 'tool_result', tool_use_id: ids[outils.indexOf(o)], content: 'MARQ-SORTIE' }] } }));
  return [a, ...res];
}
const jalon = (v, lab) => (typeof v === 'string' ? v.split('@LAB@').join(lab) : Array.isArray(v) ? v.map((x) => jalon(x, lab)) : v && typeof v === 'object' ? Object.fromEntries(Object.entries(v).map(([k, x]) => [k, jalon(x, lab)])) : v);

export function ecrireSessions(home, lab, spec, maintenant = Date.now()) {
  const d = path.join(home, '.claude', 'projects', '-lab'); fs.mkdirSync(d, { recursive: true });
  for (const s of jalon(spec, lab).sessions) {
    const L = [{ type: 'user', timestamp: ISO(maintenant - 86000e3), cwd: lab, sessionId: s.id, version: '2.1.322', origin: { kind: 'human' }, message: { role: 'user', content: 'MARQ-TEXTE' } }];
    for (const l of s.lignes) L.push(...ligneAssistant({ lab, sid: s.id, t: maintenant - l.age * 1000, outils: l.outils || [] }));
    fs.writeFileSync(path.join(d, `${s.id}.jsonl`), L.map((o) => JSON.stringify(o)).join('\n') + '\n');
  }
}
export const ajouterLignes = (home, lab, id, lignes, maintenant = Date.now()) => {
  const f = path.join(home, '.claude', 'projects', '-lab', `${id}.jsonl`);
  for (const l of jalon(lignes, lab)) fs.appendFileSync(f, ligneAssistant({ lab, sid: id, t: maintenant - (l.age || 0) * 1000, outils: l.outils || [] }).map((o) => JSON.stringify(o)).join('\n') + '\n');
};

// voie forgée (forme de `instantane().frise.voies`) : segments croissants, durées égales à la somme des segments (arrondie à la seconde)
const GENRE_DUREE = { travail: 'travailS', 'attend-humain': 'attenteHumainS', 'attend-agents': 'attenteAgentsS', repos: 'reposS', silence: 'silenceS' };
export function voieForgee(i, { t0 = Date.now() - 3600e3, etat = null, vivante = false, kind = 'session', cibles = true, enCours = null, fini = false } = {}) {
  const id = `v${String(i).padStart(5, '0')}`;
  const segments = [[t0, t0 + 600e3, 'travail'], [t0 + 600e3, t0 + 900e3, 'attend-humain'], [t0 + 900e3, t0 + 1200e3, 'repos']];
  const durees = { travailS: 0, attenteHumainS: 0, attenteAgentsS: 0, reposS: 0, silenceS: 0 };
  for (const [a, b, g] of segments) durees[GENRE_DUREE[g]] += (b - a) / 1000;
  return { id, kind, session: kind === 'session' ? id : 'v00000', parent: kind === 'session' ? null : 'v00000', depth: kind === 'session' ? null : 1, role: null, arbre: null, background: false,
    debut: t0, fin: t0 + 1200e3, dispatchA: null, fini, arrete: false, etatOfficiel: vivante ? 'actif' : etat, modeles: ['claude-test-1'],
    compteurs: { appels: 3, erreurs: 0, refus: 0, questions: 0, compactions: 0, tours: 2, reponsesApi: 3 }, jetons: { entree: 10, sortie: 5, cacheLu: 0, cacheCree: 0, contexteMax: 10, contexteDernier: 10 },
    durees, segments, evenements: [[t0 + 100e3, 'dispatch']], enCours, rattachement: null,
    cibles: cibles ? { etat: 'ok', tronque: false, ecritures: [{ arbre: null, cible: 'src/a.js', n: 1, dernierMs: t0 + 300e3 }], lectures: [] } : null };
}

if (mode === 'lab') creerLab(a1);
else if (mode === 'transcripts') ecrireSessions(a1, a2, JSON.parse(fs.readFileSync(a3, 'utf8')));
else if (mode === 'claude-faux') {
  fs.mkdirSync(a1, { recursive: true });
  fs.writeFileSync(path.join(a1, 'sortie.json'), a2);
  fs.writeFileSync(path.join(a1, 'claude'), '#!/bin/sh\ncat "$(dirname "$0")/sortie.json"\n', { mode: 0o755 });
} else if (mode === 'forge') {
  const n = Number(a2), v = a3 || '';
  const l = Array.from({ length: n }, (_, i) => voieForgee(i, { t0: Date.now() - 7200e3 + i * 1000, vivante: v === 'vivantes' && i < 5 }));
  fs.writeFileSync(a1, JSON.stringify(l));
}
