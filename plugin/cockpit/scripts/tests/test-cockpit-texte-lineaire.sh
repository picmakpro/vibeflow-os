#!/usr/bin/env bash
# test-cockpit-texte-lineaire.sh — les lecteurs du cockpit qui traitent un texte venu du lab restent en temps LINÉAIRE (classe : coût quadratique
# sur un texte du lab, dans la boucle du serveur ou dans le fil de lecture). Node seul, aucun Chrome.
# Une seule sonde générative : pour chaque lecteur et chaque forme d'entrée hostile (longues suites de « . », « ! », blancs, « [ », « check- »,
# fins de ligne \r, \n, U+2028, U+2029, classe de motif non fermée…), le temps de l'appel est mesuré à la taille N puis 2N. Le verdict est un RAPPORT
# t(2N)/t(N) (médiane de plusieurs mesures, durée d'un appel sur une entrée minuscule retranchée), jamais une durée absolue : linéaire ≈ 2,
# quadratique ≈ 4, seuil 3. N double jusqu'à ce que le temps net dépasse 40 ms ; sous ce seuil jusqu'à la borne de taille, la forme est
# linéaire sans discussion (un coût quadratique y coûterait des minutes). Un rapport au-delà du seuil se remesure une fois (le plus bas compte).
# Lecteurs : gatesDeCi, globLineaire (activite-gardes) · lireBlocages · lireOptions · propre (project) · detailCommit (git-details) ·
# architectureVibeflow (code-vf) · findIssues (moteur, health.mjs). Dépôts et labs fabriqués dans mktemp. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t.test GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t.test
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
MOD="${VF_TEXTE_MODULES:-$SCRIPTS}" # dossier des modules lus (surchargé seulement pour tracer le rouge sur une copie)
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"
trap 'rm -rf "$WORK"' EXIT
export HOME="$WORK/home"; mkdir -p "$HOME"

cat > "$WORK/sonde.mjs" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { execFileSync } from 'node:child_process';

const [, , MOD, WORK] = process.argv;
const imp = (f) => import(pathToFileURL(path.join(MOD, f)).href);
const { gatesDeCi, globLineaire } = await imp('vf-cockpit-activite-gardes.mjs');
const { lireBlocages } = await imp('vf-cockpit-blocages.mjs');
const { lireOptions } = await imp('vf-cockpit-questions-champs.mjs');
const { propre } = await imp('vf-cockpit-project.mjs');
const { detailCommit } = await imp('vf-cockpit-git-details.mjs');
const { architectureVibeflow } = await imp('vf-cockpit-code-vf.mjs');
const { findIssues } = await import(pathToFileURL(path.join(MOD, '..', 'skills', 'cockpit-moteur', 'scripts', 'lib', 'health.mjs')).href);

const SEUIL_MS = 40, SEUIL_RAPPORT = 3, BORNE = 1 << 21; // 2N reste sous la borne de lecture d'un fichier du lab (8 Mio)
const med = (a) => a.slice().sort((x, y) => x - y)[a.length >> 1];
const chrono = async (appel, arg) => { const a = process.hrtime.bigint(); await appel(arg); return Number(process.hrtime.bigint() - a) / 1e6; };
async function mediane(appel, arg, reps) { const t = []; for (let i = 0; i < reps; i++) t.push(await chrono(appel, arg)); return med(t); }

// cas : { prep(n) -> argument (peut être asynchrone), appel(argument), borne?, seuil? } (seuil : temps net minimal, plus haut quand l'appel porte un bruit fixe, un processus git par exemple)
async function mesure(cas) {
  const borne = cas.borne || BORNE, seuil = cas.seuil || SEUIL_MS;
  const base = await mediane(cas.appel, await cas.prep(1024), 5);
  const net = async (n, reps) => Math.max(await mediane(cas.appel, await cas.prep(n), reps) - base, 0.01);
  let n = 4096, s = await net(n, 5);
  while (s < seuil && n < borne) { n *= 2; s = await net(n, 5); }
  if (s < seuil) return { ok: true, texte: `sous ${seuil} ms jusqu'à N=${n} (net ${s.toFixed(0)} ms)` };
  const r = (await net(2 * n, 5)) / s;
  return { ok: r <= SEUIL_RAPPORT, rapport: r, texte: `t(2N)/t(N)=${r.toFixed(2)} (N=${n}, net ${s.toFixed(0)} ms)` };
}
let pass = 0, fail = 0;
async function juge(famille, forme, cas) {
  let r = await mesure(cas);
  if (!r.ok) { const r2 = await mesure(cas); if (r2.ok || r2.rapport < r.rapport) r = r2; }
  if (r.ok) { pass++; console.log(`  ✅ PASS — ${famille} / ${forme} : ${r.texte}`); }
  else { fail++; console.log(`  ❌ FAIL — ${famille} / ${forme} : ${r.texte}`); console.log(`     attendu: rapport <= ${SEUIL_RAPPORT} (linéaire ≈ 2)`); console.log(`     obtenu:  ${r.rapport.toFixed(2)}`); }
}
const rep = (m, n) => m.repeat(Math.max(1, Math.ceil(n / m.length)));
let seq = 0; const dossier = (nom) => { const d = path.join(WORK, `${nom}-${++seq}`); fs.mkdirSync(d, { recursive: true }); return d; };

// --- 1. gatesDeCi : jetons « check- » de .github/workflows/ci.yml ---
const lab = dossier('ci'); fs.mkdirSync(path.join(lab, '.github/workflows'), { recursive: true });
for (const [forme, f] of [['check- répété', (n) => rep('check-', n)], ['check-/ répété', (n) => rep('check-/', n)], ['.sh/check- répété', (n) => rep('.sh/check-', n)],
  ['check-x.sh répété sans blanc', (n) => rep('check-x.sh/', n)], ['check- puis points', (n) => 'check-' + '.'.repeat(n)], ['check- séparés par U+2028', (n) => rep('check- ', n)]]) {
  await juge('gatesDeCi', forme, { prep: (n) => fs.writeFileSync(path.join(lab, '.github/workflows/ci.yml'), 'run: ' + f(n) + '\n'), appel: () => gatesDeCi(lab, new Set()) });
}

// --- 2. globLineaire : motif écrit dans une suite contre un chemin (motif ET chemin croissent) ---
for (const [forme, p, s] of [['classe non fermée', (n) => 'plugin/*[' + 'a'.repeat(n), (n) => 'plugin/' + 'a'.repeat(n)],
  ['classe négative non fermée', (n) => '*[!' + 'a'.repeat(n), (n) => 'b'.repeat(n)], ['classe non fermée sous \\', (n) => '*[\\' + 'a'.repeat(n), (n) => 'a'.repeat(n)],
  ['étoiles et littéraux', (n) => rep('*a', n) + 'b', (n) => 'a'.repeat(n)]]) {
  await juge('globLineaire', forme, { prep: (n) => [p(n), s(n)], appel: ([mo, ch]) => { globLineaire(mo, ch); globLineaire(mo + '/*', ch); } });
}

// --- 3. lireBlocages : puces de « ### Blockers/Concerns » du STATE ---
const ST = (corps) => `# State\n\n### Blockers/Concerns\n- ${corps}\n\n### Autre\n`;
for (const [forme, f] of [['points', (n) => '.'.repeat(n) + 'x'], ['points d\'exclamation', (n) => '!'.repeat(n) + 'x'], ['points et point d\'exclamation', (n) => rep('.!', n) + 'x'],
  ['blancs', (n) => 'a' + ' '.repeat(n) + 'x'], ['fin de ligne U+2028', (n) => 'a' + ' '.repeat(n) + 'x'], ['fin de ligne U+2029', (n) => 'a' + ' '.repeat(n) + 'x'],
  ['retours chariot', (n) => 'a' + '\r'.repeat(n) + 'x'], ['mot vide puis points', (n) => 'rien' + '.'.repeat(n) + 'x']]) {
  await juge('lireBlocages', forme, { prep: (n) => ST(f(n)), appel: lireBlocages });
}
await juge('lireBlocages', 'puces et continuations nombreuses', { prep: (n) => ST(rep('a\n  b\n- c', n)), appel: lireBlocages });
await juge('lireBlocages', 'titre à blancs', { prep: (n) => '### ' + ' '.repeat(n) + 'x', appel: lireBlocages });

// --- 4. lireOptions : champ « Options : (a) … ; (b) … » d'une question en attente ---
for (const [forme, f] of [['blancs dans une option', (n) => '(a) a' + ' '.repeat(n) + 'b'], ['tabulations dans une option', (n) => '(a) a' + '\t'.repeat(n) + 'b'],
  ['blancs seuls', (n) => ' '.repeat(n) + 'x'], ['point puis blancs', (n) => 'a.' + ' '.repeat(n) + 'x'], ['blancs puis point', (n) => 'a' + ' '.repeat(n) + '.'],
  ['points-virgules', (n) => rep(';', n)], ['points-virgules et blancs', (n) => rep(' ; ', n) + 'x'], ['séparateurs sans option', (n) => rep('(a) a ;', n)]]) {
  await juge('lireOptions', forme, { prep: f, appel: lireOptions });
}

// --- 5. propre : texte d'un jalon ou d'une phase du ROADMAP (markdown nettoyé à la source) ---
for (const [forme, f] of [['crochets ouvrants', (n) => '['.repeat(n)], ['liens sans fin', (n) => rep('[a](', n)], ['texte de lien sans fermeture', (n) => '[' + 'a'.repeat(n)],
  ['crochets et retours à la ligne', (n) => rep('[a\n', n)], ['blancs avant un caractère', (n) => 'x' + ' '.repeat(n) + 'x'], ['tabulations avant un caractère', (n) => 'x' + '\t'.repeat(n) + 'x'],
  ['blancs et retours', (n) => rep(' \t', n) + 'x'], ['commentaire jamais fermé', (n) => rep('<!--', n)], ['gras et accents graves', (n) => rep('**`', n)]]) {
  await juge('propre', forme, { prep: f, appel: propre });
}

// --- 6. detailCommit : message d'un commit du lab (git log %B), version asynchrone ---
const repo = dossier('depot');
const git = (...a) => execFileSync('git', a, { cwd: repo, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
git('init', '-q'); const arbre = git('mktree');
for (const [forme, f] of [['blancs dans le message', (n) => 'a' + ' '.repeat(n) + 'x'], ['retours à la ligne', (n) => 'a' + '\n'.repeat(n) + 'x'], ['fin de ligne U+2028', (n) => 'a' + ' '.repeat(n) + 'x']]) {
  await juge('detailCommit', forme, { borne: 1 << 20, seuil: 300, prep: (n) => { const m = path.join(WORK, 'message.txt'); fs.writeFileSync(m, f(n)); return git('commit-tree', arbre, '-F', m); }, appel: (sha) => detailCommit(repo, sha) });
}

// --- 7. architectureVibeflow : mentions « *.sh » et lignes `source` dans les scripts et références du lab ---
const labC = dossier('code'), sortie = dossier('sortie');
fs.mkdirSync(path.join(labC, 'scripts'), { recursive: true }); fs.mkdirSync(path.join(sortie, '.cache'), { recursive: true });
fs.writeFileSync(path.join(labC, 'scripts', 'a.sh'), 'echo a\n');
fs.writeFileSync(path.join(sortie, '.cache', 'scan.json'), JSON.stringify({ files: ['scripts/a.sh', 'scripts/b.sh'].map((p) => ({ path: p, category: 'code' })) }));
for (const [forme, f] of [['mot et points', (n) => rep('a.', n)], ['points', (n) => '.'.repeat(n)], ['lignes vides', (n) => '\n'.repeat(n)], ['lignes à blancs', (n) => rep(' \n', n)],
  ['blancs en tête de ligne', (n) => '\n' + ' '.repeat(n) + 'x'], ['tirets', (n) => '-'.repeat(n)], ['U+2028', (n) => rep(' ', n)]]) {
  await juge('architectureVibeflow', forme, { borne: 1 << 20, prep: (n) => fs.writeFileSync(path.join(labC, 'scripts', 'b.sh'), 'a.sh\n' + f(n) + '\n'), appel: () => architectureVibeflow({ lab: labC, sortie }) });
}

// --- 8. findIssues (moteur, health.mjs) : motifs à `^` sous le drapeau m appliqués au source d'un fichier du lab ---
for (const [forme, lang, f] of [['lignes vides', 'javascript', (n) => '\n'.repeat(n) + 'x'], ['lignes vides en python', 'python', (n) => '\n'.repeat(n) + 'x'], ['lignes à blancs', 'javascript', (n) => rep(' \n', n) + 'x'],
  ['lignes vides après un import', 'python', (n) => 'import os\n' + '\n'.repeat(n)], ['retours chariot', 'javascript', (n) => '\r'.repeat(n) + 'x']]) {
  await juge('findIssues', forme, { borne: 1 << 20, prep: (n) => f(n), appel: (src) => findIssues(src, { category: 'code', lang, path: 'x.' + (lang === 'python' ? 'py' : 'js') }) });
}

console.log(`RESULTAT ${pass} ${fail}`);
JS

OUT="$WORK/sortie.txt"
node "$WORK/sonde.mjs" "$MOD" "$WORK" > "$OUT" 2>&1; RC=$?
grep -v '^RESULTAT' "$OUT"
LIGNE="$(grep '^RESULTAT' "$OUT" | tail -1)"
if [ -z "$LIGNE" ]; then echo "  ❌ FAIL — la sonde n'a pas rendu de bilan (exit $RC)"; PASS=0; FAIL=1
else PASS="$(echo "$LIGNE" | cut -d' ' -f2)"; FAIL="$(echo "$LIGNE" | cut -d' ' -f3)"; fi
echo ""
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
