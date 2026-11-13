#!/usr/bin/env bash
# test-cockpit-activite-git.sh — calcul git de la lentille « activité » (Phase 75, plan 75-01 ; ACTV-04, 05, 06, 10)
#   G1 parseur du journal (alignement, coupes, noms hostiles, commit vide, renommage) · G2 fenêtre, merge, plafond
#   G3 renommages · G4 points chauds (rang, paliers) · G5 clone superficiel
# Dépôts fabriqués par la suite dans mktemp (identité et dates fixées), jamais de dépôt distant, aucun serveur.
# Forme de sortie : `PASS — <id> : <texte>`, `❌ FAIL — <id> : <texte>`, ligne finale `BILAN : <n> PASS, <m> FAIL` ; exit non nul au premier FAIL.
# Les modules sont importés en `node` (aucun serveur, aucun processus laissé derrière).

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t.test GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t.test
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/vf-activite-git.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/sonde.mjs" <<'FIN_SONDE'
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

const [, , SCRIPTS, WORK] = process.argv;
let pass = 0, fail = 0;
const bilan = () => console.log(`BILAN : ${pass} PASS, ${fail} FAIL`);
const eq = (id, texte, obtenu, attendu) => {
  const o = JSON.stringify(obtenu), a = JSON.stringify(attendu);
  if (o === a) { pass++; console.log(`PASS — ${id} : ${texte}`); return; }
  fail++; console.log(`❌ FAIL — ${id} : ${texte}\n   attendu: ${a}\n   obtenu:  ${o}`); bilan(); process.exit(1);
};
const charger = async (f) => {
  try { return await import(path.join(SCRIPTS, f)); }
  catch (e) { fail++; console.log(`❌ FAIL — G0 : import de ${f}\n   attendu: module chargé\n   obtenu:  ${e.code || e.message}`); bilan(); process.exit(1); }
};

// ---- outils de fixture (git réel) ----
const ENV = { GIT_CONFIG_NOSYSTEM: '1', GIT_CONFIG_GLOBAL: '/dev/null' };
const G = (cwd, ...args) => execFileSync('git', args, { cwd, env: { ...process.env, ...ENV }, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
const GD = (cwd, t, ...args) => execFileSync('git', args, { cwd, env: { ...process.env, ...ENV, GIT_AUTHOR_DATE: t, GIT_COMMITTER_DATE: t }, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
const NOW = Math.floor(Date.now() / 1000);
let SEQ = 0;
const dateDe = (jours) => `${NOW - Math.round(jours * 86400) + (++SEQ)} +0000`; // strictement croissant à jours égaux
const C = (cwd, msg, jours, { ecrit = {}, mv = [] } = {}) => {
  for (const [p, c] of Object.entries(ecrit)) { fs.mkdirSync(path.dirname(path.join(cwd, p)), { recursive: true }); fs.writeFileSync(path.join(cwd, p), c); }
  for (const [a, b] of mv) G(cwd, 'mv', '--', a, b);
  G(cwd, 'add', '-A');
  GD(cwd, dateDe(jours), 'commit', '-q', '--allow-empty', '-m', msg);
  return G(cwd, 'rev-parse', 'HEAD').trim();
};
const touch = (cwd, msg, jours, ...chemins) => C(cwd, msg, jours, { ecrit: Object.fromEntries(chemins.map((p) => [p, `${++SEQ}\n`])) });
const init = (nom) => { const d = path.join(WORK, nom); fs.mkdirSync(d, { recursive: true }); G(d, 'init', '-q', '-b', 'main', '.'); return d; };

const L = await charger('vf-cockpit-activite-log.mjs');
const A = await charger('vf-cockpit-activite-git.mjs');
const H40 = 'a'.repeat(40);

// ---- fixture principale : fenêtre, vide, noms hostiles, renommage, recréation, merge ----
const NOM_NL = 'n\nl', NOM_U = 'u v', NOM_TAB = 't\tab';
const r1 = init('r1');
const sha = {};
sha.vieux = touch(r1, 'c100', 100, 'vieux.txt');
sha.h91 = touch(r1, 'c91', 91, 'h91.txt');
sha.h89 = touch(r1, 'c89', 89, 'h89.txt');
sha.vide = C(r1, 'vide', 88);
sha.noms = C(r1, 'noms', 86, { ecrit: { [NOM_NL]: '1\n', [NOM_U]: '2\n', [NOM_TAB]: '3\n' } });
touch(r1, 'anc1', 80, 'ancien.txt'); touch(r1, 'anc2', 79, 'ancien.txt');
sha.ren = C(r1, 'ren', 70, { mv: [['ancien.txt', 'nouveau.txt']] });
touch(r1, 'nv', 60, 'nouveau.txt');
touch(r1, 'rc1', 50, 'recree.txt'); C(r1, 'rc2', 45, { mv: [['recree.txt', 'recree2.txt']] }); touch(r1, 'rc3', 40, 'recree.txt'); touch(r1, 'rc4', 35, 'recree.txt');
G(r1, 'checkout', '-q', '-b', 'feat'); touch(r1, 'f1', 31, 'merge.txt'); G(r1, 'checkout', '-q', 'main');
GD(r1, dateDe(30), 'merge', '-q', '--no-ff', 'feat', '-m', 'merge feat');
const TOUS = ['vieux.txt', 'h91.txt', 'h89.txt', NOM_NL, NOM_U, NOM_TAB, 'ancien.txt', 'nouveau.txt', 'recree.txt', 'recree2.txt', 'merge.txt'];
const loc1 = new Map(TOUS.map((p) => [p, 1]));
const nbSansMerge = Number(G(r1, 'rev-list', '--count', '--no-merges', '--since=90.days', 'HEAD'));
const nbAvecMerge = Number(G(r1, 'rev-list', '--count', '--since=90.days', 'HEAD'));
eq('G0', 'G0.1 contrôle de la fixture : le merge existe dans la fenêtre (un commit de plus avec merges)', nbAvecMerge - nbSansMerge, 1);

// ---- G1 : le parseur sur une sortie réelle, puis les cas qui doivent échouer ----
const ARGS_LOG = ['log', '--no-merges', '-M', '-l400', '--name-status', '-z', '--format=%x00%H%x00%ct', '--since=90.days', '-n', '5000', 'HEAD', '--'];
const sortie = G(r1, ...ARGS_LOG);
const lu = L.lireLog(sortie);
eq('G1', 'G1.1 sortie réelle : ok:true et un commit par commit hors merge de la fenêtre', [lu.ok, lu.commits?.length], [true, nbSansMerge]);
const parH = (h) => lu.commits.find((c) => c.h === h);
eq('G1', 'G1.2 commit vide : présent, sans entrée', parH(sha.vide)?.entrees, []);
eq('G1', 'G1.3 renommage R100 : deux chemins, ancien puis nouveau', parH(sha.ren)?.entrees, [{ st: 'R', chemins: ['ancien.txt', 'nouveau.txt'] }]);
eq('G1', 'G1.4 retour ligne, U+2028 et tabulation dans un nom : chemins bruts, intacts', parH(sha.noms)?.entrees.map((e) => e.chemins[0]).sort(), [NOM_NL, NOM_U, NOM_TAB].sort());
eq('G1', 'G1.5 sortie vide : ok:true, aucun commit', L.lireLog(''), { ok: true, commits: [] });
const enTete = `\x00${H40}\x00100\x00`;
const ko = (s) => L.lireLog(s).ok;
eq('G1', 'G1.6 sortie non terminée par NUL : ok:false avec une raison', [ko(sortie.slice(0, -1)), typeof L.lireLog(sortie.slice(0, -1)).raison], [false, 'string']);
eq('G1', 'G1.7 entête sans sha valide : ok:false', ko(`\x00zz\x00100\x00\nA\x00f\x00`), false);
eq('G1', 'G1.8 date non entière : ok:false', ko(`\x00${H40}\x00cent\x00\nA\x00f\x00`), false);
eq('G1', 'G1.9 statut inconnu : ok:false', ko(`${enTete}\nQ\x00f\x00`), false);
eq('G1', 'G1.10 renommage coupé après le premier chemin : ok:false', ko(`${enTete}\nR100\x00a\x00`), false);
eq('G1', 'G1.11 entrée de texte qui ne commence pas par un entête : ok:false ; non-chaîne : ok:false', [ko('texte\x00'), ko(undefined)], [false, false]);
eq('G1', 'G1.12 forme minimale valide : une entrée A et une entrée M', L.lireLog(`${enTete}\nA\x00f\x00M\x00g\x00`), { ok: true, commits: [{ h: H40, at: 100, entrees: [{ st: 'A', chemins: ['f'] }, { st: 'M', chemins: ['g'] }] }] });

// ---- G2 : fenêtre, merge, plafond ----
const g1 = await A.calculerGit(r1, { loc: loc1 });
const chemins1 = new Map((g1.chauds || []).map((t) => [t[0], t]));
eq('G2', 'G2.1 état ok, fenêtre de 90 jours et plafond de 5 000 déclarés', [g1.etat, g1.fenetre?.jours, g1.fenetre?.plafond, A.FENETRE], ['ok', 90, 5000, { jours: 90, plafond: 5000 }]);
eq('G2', 'G2.2 un commit à 91 jours est exclu, un commit à 89 jours est compté', [chemins1.has('h91.txt'), chemins1.has('vieux.txt'), chemins1.has('h89.txt')], [false, false, true]);
eq('G2', 'G2.3 un merge n\'est jamais compté : autant de commits que `rev-list --no-merges`', g1.fenetre?.commits, nbSansMerge);
eq('G2', 'G2.4 plafond non atteint sur la fixture', g1.fenetre?.plafondAtteint, false);
const g1p = await A.calculerGit(r1, { loc: loc1, plafond: 5 });
eq('G2', 'G2.5 plafond injectable : 5 commits lus, plafondAtteint true', [g1p.fenetre?.commits, g1p.fenetre?.plafondAtteint], [5, true]);
const rg = init('rgros');
{
  const NB = 5001, t0 = NOW - 5 * 86400, morceaux = [];
  for (let i = 0; i < NB; i++) morceaux.push(`commit refs/heads/main\nmark :${i + 1}\ncommitter t <t@t.test> ${t0 + i} +0000\ndata 2\nc\n${i ? `from :${i}\n` : ''}M 644 inline f.txt\ndata ${String(i).length + 1}\n${i}\n\n`);
  execFileSync('git', ['fast-import', '--quiet'], { cwd: rg, input: morceaux.join(''), env: { ...process.env, ...ENV } });
}
eq('G2', 'G2.6 contrôle de la fixture : 5 001 commits dans la fenêtre', Number(G(rg, 'rev-list', '--count', 'HEAD').trim()), 5001);
const gg = await A.calculerGit(rg, { loc: new Map([['f.txt', 1]]) });
eq('G2', 'G2.7 5 001 commits réels : exactement 5 000 lus, plafondAtteint true', [gg.etat, gg.fenetre?.commits, gg.fenetre?.plafondAtteint], ['ok', 5000, true]);

// ---- G3 : renommages ----
const c3 = (p) => chemins1.get(p)?.[1];
eq('G3', 'G3.1 les commits qui citent l\'ancien chemin comptent pour le chemin actuel (création, modification, renommage, modification = 4)', [c3('nouveau.txt'), chemins1.has('ancien.txt')], [4, false]);
eq('G3', 'G3.2 un chemin recréé après un renommage reste distinct (2 commits avant le renommage, 2 après)', [c3('recree.txt'), c3('recree2.txt')], [2, 2]);
eq('G3', 'G3.3 noms hostiles : comptés une fois chacun, chemins bruts', [c3(NOM_NL), c3(NOM_U), c3(NOM_TAB)], [1, 1, 1]);

// ---- G4 : points chauds, rang et paliers ----
const cm = (...chemins) => ({ h: H40, at: 1, chemins });
const serie = (n) => { const cs = []; for (let i = 1; i <= n; i++) for (let j = 0; j < i; j++) cs.push(cm(`f${String(i).padStart(2, '0')}`)); return cs; };
const loc1de = (n) => new Map(Array.from({ length: n }, (_, i) => [`f${String(i + 1).padStart(2, '0')}`, 1]));
const p15 = A.pointsChauds(serie(15), loc1de(15));
eq('G4', 'G4.1 15 fichiers aux scores 1 à 15 : rang décroissant, trois paliers de 5', [p15.chauds[0], p15.chauds[14], [3, 2, 1].map((p) => p15.chauds.filter((t) => t[4] === p).length), p15.paliers], [['f15', 15, 1, 1, 3], ['f01', 1, 1, 15, 1], [5, 5, 5], 3]);
const pSous = A.pointsChauds(serie(11), loc1de(11));
eq('G4', 'G4.2 sous 12 fichiers à score non nul : un seul palier', [pSous.paliers, new Set(pSous.chauds.map((t) => t[4])).size], [1, 1]);
eq('G4', 'G4.3 le seuil est injectable : paliersMin 3 rend trois paliers sur 11 fichiers', A.pointsChauds(serie(11), loc1de(11), { paliersMin: 3 }).paliers, 3);
const egal = A.pointsChauds(Array.from({ length: 12 }, (_, i) => [cm(`e${String(i).padStart(2, '0')}`), cm(`e${String(i).padStart(2, '0')}`)]).flat(), new Map(Array.from({ length: 12 }, (_, i) => [`e${String(i).padStart(2, '0')}`, 1])));
eq('G4', 'G4.4 douze scores égaux : un seul palier pour tous, rang par chemin', [new Set(egal.chauds.map((t) => t[4])).size, egal.chauds.map((t) => t[0]).join()], [1, Array.from({ length: 12 }, (_, i) => `e${String(i).padStart(2, '0')}`).join()]);
const prod = A.pointsChauds([cm('a'), cm('a'), ...Array.from({ length: 10 }, () => cm('b')), cm('sans-loc'), cm('loc-zero')], new Map([['a', 100], ['b', 5], ['loc-zero', 0], ['jamais-modifie', 9]]));
eq('G4', 'G4.5 score = commits x loc ; un fichier sans loc, à loc nulle ou sans modification n\'est pas rendu', prod.chauds.map((t) => [t[0], t[1], t[2], t[3]]), [['a', 2, 100, 1], ['b', 10, 5, 2]]);
eq('G4', 'G4.6 bout en bout : le rang tient compte du renommage (nouveau.txt, 4 commits, en tête) et pas de fichier hors fenêtre', [g1.chauds[0][0], g1.chauds.every((t) => t.length === 5)], ['nouveau.txt', true]);

// ---- G5 : clone superficiel ----
const rl = init('rlin');
for (const [msg, j] of [['l1', 100], ['l2', 95], ['l3', 85], ['l4', 80], ['l5', 20], ['l6', 10]]) touch(rl, msg, j, 'f.txt');
const clone = (nom, prof) => { const d = path.join(WORK, nom); G(WORK, 'clone', '-q', '--depth', String(prof), `file://${rl}`, d); return d; };
const part = async (d) => (await A.calculerGit(d, { loc: new Map([['f.txt', 1]]) })).fenetre?.partiel;
const sup3 = clone('sup3', 3), sup5 = clone('sup5', 5);
eq('G5', 'G5.1 contrôle : les deux clones sont superficiels', [G(sup3, 'rev-parse', '--is-shallow-repository').trim(), G(sup5, 'rev-parse', '--is-shallow-repository').trim()], ['true', 'true']);
eq('G5', 'G5.2 limite superficielle plus récente que le début de la fenêtre (80 j) : historique partiel', await part(sup3), true);
eq('G5', 'G5.3 limite plus ancienne que le début de la fenêtre (95 j) : pas partiel', await part(sup5), false);
eq('G5', 'G5.4 dépôt complet : pas partiel', await part(rl), false);

// ---- G6 : couplage aux bornes (unitaire, commits synthétiques) ----
const co = (...chemins) => ({ h: H40, at: 1, chemins });
const rep = (n, ...chemins) => Array.from({ length: n }, () => co(...chemins));
const seul = (n, p) => rep(n, p);
const paire = (a, b, communes, soloA, soloB) => [...rep(communes, a, b), ...seul(soloA, a), ...seul(soloB, b)];
const cp = (commits, options) => A.couplage(commits, options);
eq('G6', 'G6.1 défauts exportés : 5 communes, 5 révisions, degré 30, 30 fichiers, 5 voisins', A.SEUILS_COUPLAGE, { minCommunes: 5, minRevs: 5, minDegre: 30, maxFichiers: 30, voisins: 5 });
eq('G6', 'G6.2 quatre révisions communes : exclu ; cinq : gardé', [cp(paire('a', 'b', 4, 0, 0)), cp(paire('a', 'b', 5, 0, 0))], [[], [['a', 'b', 5, 100]]]);
eq('G6', 'G6.3 degré 29 % : exclu ; 30 % : gardé (communes et révisions identiques par ailleurs)', [cp(paire('a', 'b', 29, 71, 71)), cp(paire('a', 'b', 30, 70, 70))], [[], [['a', 'b', 30, 30]]]);
const bloc = (n, nb) => Array.from({ length: nb }, () => co(...Array.from({ length: n }, (_, i) => `g${String(i).padStart(2, '0')}`)));
eq('G6', 'G6.4 commit de 30 fichiers : compté ; de 31 fichiers : écarté', [cp(bloc(30, 5)).length > 0, cp(bloc(31, 5))], [true, []]);
eq('G6', 'G6.5 un fichier de la liste de bruit ne forme aucune paire ; le même schéma sur un fichier ordinaire en forme une', [cp(paire('a.js', 'CHANGELOG.md', 5, 0, 0)), cp(paire('a.js', 'sous/dossier/package-lock.json', 5, 0, 0)), cp(paire('a.js', 'b.js', 5, 0, 0)).length], [[], [], 1]);
const hub = cp(Array.from({ length: 5 }, () => co('h', 'x1', 'x2', 'x3', 'x4', 'x5', 'x6', 'x7', 'x8')));
const occ = new Map(); for (const t of hub) for (const p of t.slice(0, 2)) occ.set(p, (occ.get(p) || 0) + 1);
eq('G6', 'G6.6 au plus 5 voisins par fichier (neuf fichiers co-modifiés, 36 paires possibles) ; le centre en garde exactement 5', [Math.max(...occ.values()), occ.get('h')], [5, 5]);
eq('G6', 'G6.7 tri par degré décroissant puis par chemin', cp([...paire('r', 's', 6, 4, 4), ...paire('t', 'u', 5, 7, 7), ...paire('p', 'q', 5, 0, 0)]), [['p', 'q', 5, 100], ['r', 's', 6, 60], ['t', 'u', 5, 42]]);
eq('G6', 'G6.8 liste de bruit exportée : dix noms, dont CHANGELOG.md, VERSION et un fichier de verrou', [A.BRUIT.length, ['CHANGELOG.md', 'VERSION', 'package-lock.json'].every((n) => A.BRUIT.includes(n))], [10, true]);
const deux = paire('a', 'b', 4, 1, 1); // 4 communes, 5 révisions chacun
eq('G6b', 'G6b.1 les deux contrôles sont indépendants : minRevs 6 exclut (communes 4 >= 3, révisions 5 < 6)', cp(deux, { minRevs: 6, minCommunes: 3 }), []);
eq('G6b', 'G6b.2 minRevs 5 et minCommunes 3 : gardé ; défauts : exclu par les communes seules', [cp(deux, { minRevs: 5, minCommunes: 3 }), cp(deux)], [[['a', 'b', 4, 80]], []]);

// ---- G7 à G9 : espion d'argv (`binaire`), cache par clé, incrémental, dégradations ----
const GITREEL = execFileSync('/bin/sh', ['-c', 'command -v git'], { encoding: 'utf8' }).trim();
const JOURNAL = path.join(WORK, 'espion.log');
fs.writeFileSync(JOURNAL, '');
const script = (nom, corps) => { const f = path.join(WORK, nom); fs.writeFileSync(f, `#!/bin/sh\n${corps}\n`, { mode: 0o755 }); return f; };
const ESPION = script('espion-git', `printf '%s\\t' "$@" >> '${JOURNAL}'\nprintf '\\n' >> '${JOURNAL}'\nexec '${GITREEL}' "$@"`);
const ECHEC_LOG = script('echec-log-git', `for a in "$@"; do [ "$a" = log ] && exit 3; done\nexec '${GITREEL}' "$@"`);
const ORDURE_LOG = script('ordure-log-git', `for a in "$@"; do [ "$a" = log ] && { printf 'abc'; exit 0; }; done\nexec '${GITREEL}' "$@"`);
const argvs = () => fs.readFileSync(JOURNAL, 'utf8').split('\n').filter(Boolean).map((l) => l.split('\t').filter((x, i, t) => i < t.length - 1 || x !== ''));
const HIST = [];
const vider = () => { HIST.push(...argvs()); fs.writeFileSync(JOURNAL, ''); };
const appels = (sous) => argvs().filter((a) => a.includes(sous));
const aire = (o) => JSON.stringify({ f: o.fenetre, c: o.chauds, k: o.couplage, p: o.paliers });

const ri = init('rinc');
let ti = 60;
const lot = (msg, ...chemins) => touch(ri, msg, (ti -= 2), ...chemins);
for (let i = 0; i < 6; i++) lot(`i${i}`, 'a.txt', 'b.txt');
lot('seul', 'c.txt');
const locI = new Map([['a.txt', 3], ['b.txt', 2], ['c.txt', 1], ['a2.txt', 3], ['d.txt', 1]]);
vider();
const s1 = await A.calculerGit(ri, { loc: locI, binaire: ESPION });
eq('G7', 'G7.1 premier calcul : exactement un `log`, et une clé sha256 recalculée à partir de `for-each-ref` et de `worktree list`', [appels('log').length, /^[0-9a-f]{64}$/.test(s1.cle), appels('for-each-ref').length, appels('worktree').length], [1, true, 1, 1]);
eq('G7', 'G7.2 le couplage de la fixture est non vide (le témoin d\'égalité ci-dessous ne compare pas du vide)', [s1.etat, s1.couplage.length, s1.chauds.length], ['ok', 1, 3]);
vider();
const s2 = await A.calculerGit(ri, { loc: locI, binaire: ESPION, etatPrecedent: s1 });
eq('G7', 'G7.3 HEAD et refs inchangés : zéro `log` relancé, résultat identique, la clé est pourtant relue (un `for-each-ref` et un `worktree list`)', [appels('log').length, appels('for-each-ref').length, appels('worktree').length, aire(s2) === aire(s1)], [0, 1, 1, true]);
const s2b = await A.calculerGit(ri, { loc: new Map([['a.txt', 30], ['b.txt', 2]]), binaire: ESPION, etatPrecedent: s1 });
eq('G7', 'G7.4 clé inchangée mais `loc` du scan différent : les points chauds suivent, sans nouveau `log`', [appels('log').length, s2b.chauds[0].slice(0, 3)], [0, ['a.txt', 6, 30]]);
G(ri, 'branch', 'autre');
vider();
const s3 = await A.calculerGit(ri, { loc: locI, binaire: ESPION, etatPrecedent: s2 });
eq('G7', 'G7.5 une ref de plus (HEAD inchangé) : la clé change, le résultat reste identique, toujours aucun `log` (rien de neuf à lire)', [s3.cle !== s2.cle, appels('log').length, aire(s3) === aire(s2)], [true, 0, true]);

// G8 : incrémental quand l'ancien HEAD est un ancêtre, relecture complète sinon
const ancienHead = G(ri, 'rev-parse', 'HEAD').trim();
lot('apres1', 'a.txt', 'b.txt'); C(ri, 'renomme', (ti -= 2), { mv: [['a.txt', 'a2.txt']] }); lot('apres2', 'a2.txt', 'b.txt', 'd.txt');
const nouvelHead = G(ri, 'rev-parse', 'HEAD').trim();
vider();
const s4 = await A.calculerGit(ri, { loc: locI, binaire: ESPION, etatPrecedent: s3 });
const logs4 = appels('log');
eq('G8', 'G8.1 ancien HEAD ancêtre : un seul `log`, limité à ancien..HEAD', [logs4.length, logs4[0]?.includes(`${ancienHead}..${nouvelHead}`)], [1, true]);
const complet4 = await A.calculerGit(ri, { loc: locI });
eq('G8', 'G8.2 les agrégats de l\'incrémental sont identiques à ceux d\'une relecture complète (renommage compris)', aire(s4) === aire(complet4), true);
eq('G8', 'G8.3 le témoin d\'égalité n\'est pas vide : l\'alias du renommage agit sur les anciens commits', [s4.chauds.find((t) => t[0] === 'a2.txt')?.[1], s4.chauds.some((t) => t[0] === 'a.txt'), s4.couplage.length > 0], [9, false, true]);
G(ri, 'reset', '-q', '--hard', 'HEAD~2'); lot('divergent', 'd.txt');
vider();
const s5 = await A.calculerGit(ri, { loc: locI, binaire: ESPION, etatPrecedent: s4 });
const logs5 = appels('log');
eq('G8', 'G8.4 ancien HEAD non ancêtre (réécriture) : relecture complète, aucun `..` dans le `log`', [logs5.length, logs5[0]?.some((x) => x.includes('..'))], [1, false]);
eq('G8', 'G8.5 la relecture complète rend les agrégats d\'un calcul neuf', aire(s5) === aire(await A.calculerGit(ri, { loc: locI })), true);

// G9 : aucun argv interdit, dégradations sans champ partiel
const tous = [...HIST, ...argvs()];
const interdit = (x) => ['status', 'diff', 'fetch', 'pull', 'push', '--follow'].includes(x);
eq('G9', 'G9.1 aucun argv journalisé ne contient status, diff, fetch ni --follow (journal non vide)', [tous.length > 8, tous.filter((a) => a.some(interdit)).length], [true, 0]);
eq('G9', 'G9.2 erreur de `log` (sortie 3) : indisponible, sans champ partiel', await A.calculerGit(ri, { loc: locI, binaire: ECHEC_LOG }), { etat: 'indisponible' });
eq('G9', 'G9.3 sortie de `log` désalignée : indisponible, sans champ partiel', await A.calculerGit(ri, { loc: locI, binaire: ORDURE_LOG }), { etat: 'indisponible' });
eq('G9', 'G9.4 échéance dépassée : indisponible, sans champ partiel', await A.calculerGit(ri, { loc: locI, fin: Date.now() - 1 }), { etat: 'indisponible' });
eq('G9', 'G9.5 sortie tronquée (maxBuffer de 600 octets sur un journal plus long) : indisponible, sans champ partiel', await A.calculerGit(r1, { loc: loc1, maxBuffer: 600 }), { etat: 'indisponible' });
const horsDepot = path.join(WORK, 'horsdepot'); fs.mkdirSync(horsDepot);
eq('G9', 'G9.6 hors dépôt, dossier absent, git introuvable : absent', [(await A.calculerGit(horsDepot, { loc: locI })).etat, (await A.calculerGit(path.join(WORK, 'inexistant'), { loc: locI })).etat, (await A.calculerGit(ri, { loc: locI, binaire: path.join(WORK, 'pas-de-git') })).etat], ['absent', 'absent', 'absent']);
const vide = init('rvide');
eq('G9', 'G9.7 dépôt sans commit : vide, aucune ligne rendue', await A.calculerGit(vide, { loc: locI }).then((o) => [o.etat, o.chauds, o.couplage]), ['vide', [], []]);

// FIN_G6_G9
bilan();
FIN_SONDE

node "$WORK/sonde.mjs" "$SCRIPTS" "$WORK"
