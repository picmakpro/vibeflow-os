#!/usr/bin/env node
// vf-cockpit-build — assemble le cockpit d'un lab GSD sous <lab>/.vibeflow/cockpit (67-03, P67-D-06).
// Sans modèle : scan, architecture mécanique (onglet Code brut), graphe Projet du socle, build du moteur
// vendorisé, épissure des deux pages, copie du code d'exécution. Aucun appel à `claude`.
// Exports : assembler({ lab, quiet, scriptsDir }), fichiersExecution(scriptsDir), OUTILS_ASSEMBLAGE.
// CLI : node vf-cockpit-build.mjs [<lab>] [--quiet]   Codes : 0 ok · 2 pas de .planning · 3 moteur absent · 4 échec d'une étape.
import fs from 'node:fs';
import path from 'node:path';
import { read as lireGarde } from './vf-cockpit-planning.mjs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { execFileSync } from 'node:child_process';
import { findLabRoot, engineDir, envGit, configFiltres, filtresDeclares, outputDir, resolveScriptsDir, verifierSortie } from './vf-cockpit-paths.mjs';
import { buildProjectGraph } from './vf-cockpit-project.mjs';
import { enteteGit } from './vf-cockpit-git-entete.mjs';
import { ecrireArchitecture } from './vf-cockpit-code.mjs';
import { insererGraphe } from './vf-cockpit-embed.mjs';
import { renommerHtml, renommerTexte, MARQUEUR_LICENCE } from './vf-cockpit-rename.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
// outils d'assemblage et de test : jamais recopiés dans la sortie (le motif général les y mettrait)
export const OUTILS_ASSEMBLAGE = [/^vf-cockpit-build\.mjs$/, /^vf-cockpit-rename\.mjs$/, /^vf-cockpit-code.*\.mjs$/, /^vf-cockpit-fr-.*\.mjs$/];
export const fichiersExecution = (scriptsDir) => fs.readdirSync(scriptsDir).filter((f) => /^vf-cockpit-.*\.mjs$/.test(f) && !OUTILS_ASSEMBLAGE.some((re) => re.test(f))).sort();

const GITIGNORE = '# Sortie générée par le cockpit VibeFlow : ignorée par git (ce fichier compris).\n*\n';
const fin = (code, msg) => { const e = new Error(msg); e.code = code; return e; };
const read = (f) => { try { return fs.readFileSync(f, 'utf8'); } catch { return ''; } };
const sentence = (s, n = 200) => { s = String(s || '').replace(/\s+/g, ' ').replace(/[`*]/g, '').trim(); const i = s.search(/[.!?](\s|$)/); s = i > 25 ? s.slice(0, i + 1) : s; return s.length > n ? s.slice(0, n - 1) + '…' : s; };
// la cause remonte (lignes d'erreur du moteur, jusqu'à 4), pas seulement sa dernière ligne ; timeout : un moteur bloqué ne gèle pas le lanceur
const run = (engine, script, lab, ...a) => {
  try { return execFileSync(process.execPath, [path.join(engine, 'scripts', script), lab, ...a], { encoding: 'utf8', maxBuffer: 256 << 20, stdio: ['ignore', 'pipe', 'pipe'], timeout: 600000, env: envGit(lab, { config: configFiltres(filtresDeclares(lab, lab)) }) }); }
  catch (e) {
    const lines = String(e.stderr || e.stdout || e.message).split('\n').map((l) => l.trim()).filter(Boolean);
    const cause = (lines.filter((l) => /^(✗|-|error|Error)/.test(l)).slice(0, 4).join(' · ') || lines.slice(-1)[0] || 'cause inconnue').slice(0, 400);
    throw fin(4, `échec de l'étape ${script} du moteur du cockpit. Cause : ${cause}`);
  }
};

export function assembler({ lab: labArg, quiet = false, scriptsDir: sd } = {}) {
  const t0 = Date.now();
  const lab = findLabRoot(labArg || process.cwd());
  if (!lab) throw fin(2, 'aucun dossier .planning trouvé : le cockpit se construit dans un lab GSD.');
  const scriptsDir = sd || resolveScriptsDir(HERE);
  const eng = engineDir(scriptsDir);
  if (eng.etat !== 'trouve') throw fin(3, 'moteur du cockpit introuvable : réinstaller le module cockpit.');
  const sortie = outputDir(lab);
  if (fs.existsSync(path.dirname(sortie))) verifierSortie(lab, path.dirname(sortie)); // M4 : aucun lien symbolique avant la moindre écriture
  fs.mkdirSync(sortie, { recursive: true });
  verifierSortie(lab, sortie);

  run(eng.chemin, 'scan.mjs', lab); // le moteur refuse un dossier de sortie non vide qui n'est pas encore une carte : .gitignore après
  const arch = ecrireArchitecture({ lab, sortie });
  const project = buildProjectGraph(lab);
  // travail récent : les deux dernières phases exécutées du jalon en cours (plans à SUMMARY)
  const phaseNodes = project.nodes.filter((n) => n.kind === 'phase');
  const recent = phaseNodes.filter((n) => project.files.some((f) => f.n === n.id && f.st === 'done' && f.touched?.length))
    .sort((a, b) => parseFloat(b.num) - parseFloat(a.num)).slice(0, 2);
  const scanFiles = new Set(JSON.parse(read(path.join(sortie, '.cache', 'scan.json'))).files.map((f) => f.path));
  fs.writeFileSync(path.join(sortie, 'recent-work.json'), JSON.stringify({ updatedAt: new Date().toISOString(), tasks: recent.map((ph) => {
    const items = new Map();
    for (const f of project.files.filter((x) => x.n === ph.id && x.touched)) for (const p of f.touched) if (scanFiles.has(p) && !p.startsWith('.planning/') && !items.has(p)) items.set(p, { ref: p, change: 'changed', note: `${f.name}` });
    return { title: ph.label.length > 160 ? ph.label.slice(0, 159).replace(/\s+\S*$/, '') + '…' : ph.label, // entier jusqu'à 160 caractères (le panneau et le sous-titre passent à la ligne), au-delà coupé à un espace avec « … »
      request: ph.summary, summary: ph.foot, items: [...items.values()].slice(0, 40) };
  }) }, null, 2));
  run(eng.chemin, 'build.mjs', lab, '--no-claude-md');
  fs.writeFileSync(path.join(sortie, '.gitignore'), GITIGNORE); // deux lignes : commentaire VibeFlow puis *

  // onglet Code : descriptions tirées du frontmatter ou de l'en-tête des scripts, et index inverse fichier -> plans
  const g = JSON.parse(read(path.join(sortie, 'graph.json')));
  let decrits = 0;
  for (const f of g.files) {
    const txt = lireGarde(path.join(lab, f.p)).slice(0, 6000);
    const fmBlock = /^---\n([\s\S]*?)\n---/.exec(txt)?.[1];
    let d = '';
    if (fmBlock) { d = /^description:\s*"?(.*?)"?\s*$/m.exec(fmBlock)?.[1] || ''; const nm = /^name:\s*(.*)$/m.exec(fmBlock)?.[1]; if (nm) f.name = nm.trim(); }
    else if (/\.(sh|bash)$/.test(f.p)) d = txt.split('\n').slice(txt.startsWith('#!') ? 1 : 0).filter((l, i, a) => /^#/.test(l) && a.slice(0, i).every((x) => /^#/.test(x))).map((l) => l.replace(/^#+\s?/, '')).join(' ');
    else if (f.p.endsWith('.md')) d = txt.replace(/^#.*$/gm, '').split(/\n\s*\n/).find((p) => p.trim().length > 30) || '';
    if (d) { f.d = sentence(d); f.auto = false; decrits++; }
  }
  const touch = Object.create(null); // un chemin `constructor` ou `__proto__` du lab n'est qu'une clé
  for (const f of project.files) for (const p of f.touched || []) (touch[p] ||= []).push({ ref: 'f:' + f.p, label: f.name.slice(0, 90), st: f.st });
  const logo = (n) => 'data:image/svg+xml;base64,' + fs.readFileSync(path.join(eng.chemin, 'assets', n)).toString('base64');
  const vfLogos = { clair: logo('vibeflow-logo-clair.svg'), sombre: logo('vibeflow-logo-sombre.svg') };
  g.meta.vfTab = 'code'; g.meta.vfTouch = touch; g.meta.vfCodeExtractor = arch.extracteur; g.meta.vfLogos = vfLogos; g.meta.vfGit = enteteGit(lab); // 78-04 : nom du dépôt, branche, worktree
  g.schema = 'vf-cockpit/graph@1'; // seul champ de données amont qui porte le nom du produit
  fs.writeFileSync(path.join(sortie, 'graph.json'), JSON.stringify(g));

  // les deux pages : même viewer, données différentes
  const html = read(path.join(sortie, 'index.html'));
  fs.writeFileSync(path.join(sortie, 'index.html'), insererGraphe(html, { ...g, meta: { ...g.meta, repos: [] } }).replace(/<title>[^<]*<\/title>/, '<title>VibeFlow · Code</title>'));
  project.meta.root = g.meta.root; project.meta.vfLogos = vfLogos; project.meta.vfGit = g.meta.vfGit;
  fs.writeFileSync(path.join(sortie, 'project.html'), insererGraphe(html, project).replace(/<title>[^<]*<\/title>/, '<title>VibeFlow · Projet</title>'));

  // code d'exécution du socle, licences, pointeur de dossier de scripts (jamais de modèle ni de dernière commande)
  for (const f of fichiersExecution(scriptsDir)) fs.copyFileSync(path.join(scriptsDir, f), path.join(sortie, f));
  for (const f of ['index.html', 'project.html']) { // marque blanche : la sortie seulement, jamais la copie amont ni les données du lab
    const p = path.join(sortie, f); const h = renommerHtml(read(p));
    const licence = `<!-- ${MARQUEUR_LICENCE} : logiciel tiers sous licence MIT, voir LICENSE et LICENCES-TIERCES.txt (floorplan) -->`;
    fs.writeFileSync(p, /^<!doctype[^\n]*\n/i.test(h) ? h.replace(/^(<!doctype[^\n]*\n)/i, `$1${licence}\n`) : `${licence}\n${h}`);
  }
  for (const f of ['serve.mjs', 'query.mjs', ...fichiersExecution(scriptsDir)]) { const p = path.join(sortie, f); fs.writeFileSync(p, renommerTexte(read(p))); }
  fs.copyFileSync(path.join(scriptsDir, 'vf-cockpit-interface.json'), path.join(sortie, 'vf-cockpit-interface.json'));
  for (const f of ['LICENSE', 'LICENCES-TIERCES.txt']) fs.copyFileSync(path.join(eng.chemin, f), path.join(sortie, f));
  fs.mkdirSync(path.join(sortie, '.cache'), { recursive: true });
  fs.writeFileSync(path.join(sortie, '.cache', 'vf-cockpit.json'), JSON.stringify({ scriptsDir, engineDir: eng.chemin, builtAt: new Date().toISOString() }, null, 2));

  const resume = `Cockpit assemblé : Code ${g.files.length} fichiers (${decrits} décrits sans modèle), Projet ${project.nodes.length} cartes · ${((Date.now() - t0) / 1000).toFixed(1)} s · ${sortie}`;
  if (!quiet) console.log(resume);
  return { lab, sortie, fichiersCode: g.files.length, cartesProjet: project.nodes.length, resume };
}

if (process.argv[1] && import.meta.url === pathToFileURL(fs.realpathSync(process.argv[1])).href) {
  const args = process.argv.slice(2);
  try { assembler({ lab: args.find((a) => !a.startsWith('--')), quiet: args.includes('--quiet') }); }
  catch (e) { console.error(e.message); process.exit(e.code || 4); }
}
