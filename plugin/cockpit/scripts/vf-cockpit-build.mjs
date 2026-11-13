#!/usr/bin/env node
// vf-cockpit-build — assemble le cockpit d'un lab GSD sous <lab>/.vibeflow/cockpit (67-03, P67-D-06).
// Sans modèle : scan, architecture mécanique (onglet Code brut), graphe Projet du socle, build du moteur
// vendorisé, épissure des deux pages. La sortie ne porte que des données : le code s'exécute depuis le module. Aucun appel à `claude`.
// Exports : assembler({ lab, quiet, scriptsDir, annotateurs }), fichiersExecution(scriptsDir), OUTILS_ASSEMBLAGE, ANNOTATEURS, appliquerAnnotateurs.
// Annotateurs du graphe Code (A27) : une ligne `[nom, fonction]` par annotateur, à sa place alphabétique ;
// il tourne à chaque assemblage et modifie `g` en mémoire seulement.
// CLI : node vf-cockpit-build.mjs [<lab>] [--quiet]   Codes : 0 ok · 2 pas de .planning · 3 moteur absent · 4 échec d'une étape.
import fs from 'node:fs';
import path from 'node:path';
import { read as lireGarde, lireConfine, clipMot } from './vf-cockpit-planning.mjs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { execFileSync } from 'node:child_process';
import { findLabRoot, engineDir, envGit, configFiltres, filtresEtat, MAX_FILTRES, outputDir, verifierSortie } from './vf-cockpit-paths.mjs';
import { signatureDuLab, lireSignature, ecrireSignature } from './vf-cockpit-code-cache.mjs';
import { OUTILS_ASSEMBLAGE, fichiersExecution } from './vf-cockpit-module.mjs';
import { buildProjectGraph } from './vf-cockpit-project.mjs';
import { enteteGit } from './vf-cockpit-git-entete.mjs';
import { ecrireArchitecture } from './vf-cockpit-code.mjs';
import { insererGraphe } from './vf-cockpit-embed.mjs';
import { ecrireProjet } from './vf-cockpit-graphe-fichier.mjs';
import { renommerPageMoteur, MARQUEUR_LICENCE } from './vf-cockpit-rename.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
export { OUTILS_ASSEMBLAGE, fichiersExecution }; // déplacés dans vf-cockpit-module.mjs (79-06) : ré-exportés pour leurs importeurs
// la sortie ne porte plus que des données : l'assemblage purge ce que les versions précédentes y ont laissé (code et contrat), jamais autre chose
const CODE_ANCIEN = [/\.mjs$/, /^vf-cockpit-interface\.json$/];
function purgerCodeAncien(sortie) {
  for (const f of fs.readdirSync(sortie)) {
    if (!CODE_ANCIEN.some((re) => re.test(f))) continue;
    const p = path.join(sortie, f);
    try { if (!fs.lstatSync(p).isDirectory()) fs.rmSync(p, { force: true }); } catch {} // le lien lui-même, jamais sa cible
  }
}

const GITIGNORE = '# Sortie générée par le cockpit VibeFlow : ignorée par git (ce fichier compris).\n*\n';
const fin = (code, msg) => { const e = new Error(msg); e.code = code; return e; };
const read = (f) => { try { return fs.readFileSync(f, 'utf8'); } catch { return ''; } };
// PU-G-067 : le résumé d'un fichier est une phrase, jamais du balisage. Markdown : le « > » des citations est retiré, les commentaires et balises HTML connues
// (<picture>, <img>, <p>…) aussi — liste fermée de balises, pour qu'un « <lab> » ou un « <chemin> » de la prose reste intact.
const BALISES_HTML = 'a|abbr|b|br|center|code|details|div|em|h[1-6]|hr|i|img|kbd|li|ol|p|picture|source|span|strong|sub|summary|sup|svg|table|tbody|td|th|thead|tr|ul';
export const nettoyerMarkdown = (s) => String(s || '').replace(/<!--[\s\S]*?-->/g, ' ').replace(new RegExp(`</?(?:${BALISES_HTML})(?:\\s[^>]*)?/?>`, 'gi'), ' ').replace(/^[ \t]*(?:>[ \t]?)+/gm, '');
// PU-G-068 : un résumé dont le texte source a perdu ses accents (mots français qui en portent toujours, sans aucun caractère accentué) reste tel quel —
// on ne réécrit pas le fichier source — mais se dit « extrait brut ». Liste fermée de mots, jamais une règle de langue.
const MOTS_SANS_ACCENT = /\b(etapes?|deja|apres|verifie[rsz]?|verifiables?|generer|necessaires?|creer|executer|systemes?|systematique|resultats?|donnees|ecrire|ecrit|prefere|empeche\w*|regles?|ecarts?|defauts?|deploiement|problemes?|derniere|entrees?|memoire|developpe\w*|evenements?|evite[rsz]?|definit|apres)\b/i; // sans mot qui existe aussi en anglais (reference, complete, different, detect…)
export const extraitBrut = (d) => (d && !/[^\x00-\x7f]/.test(d) && MOTS_SANS_ACCENT.test(d) ? `${d} (extrait brut)` : d);
export const sentence = (s, n = 200) => { s = String(s || '').replace(/\s+/g, ' ').replace(/[`*]/g, '').trim(); const i = s.search(/[.!?](\s|$)/); return clipMot(i > 25 ? s.slice(0, i + 1) : s, n); }; // PU-G-147 : coupe au mot entier, comme la version du planning
// R6 : environnement du moteur. Liste des filtres lue et bornée : filtres vidés, marqueur VF_COCKPIT_GIT_DURCI posé (le moteur lit git). Liste illisible ou au-delà de MAX_FILTRES : le marqueur n'est PAS posé, git() du
// moteur reste fermé (patch P27 de common.mjs : carte sans fichiers suivis ni head) ; `ferme` dit pourquoi. Même règle fail-closed que lancerGit : un filtre inconnu n'est pas un filtre absent.
export function etatMoteur(lab) {
  const f = filtresEtat(lab, lab);
  if (!f.refus) return { env: envGit(lab, { config: configFiltres(f.noms) }), ferme: null };
  const env = envGit(lab); delete env.VF_COCKPIT_GIT_DURCI;
  return { env, ferme: f.fiable ? `plus de ${MAX_FILTRES} filtres déclarés par le dépôt` : 'liste des filtres déclarés par le dépôt illisible' };
}
// la cause remonte (lignes d'erreur du moteur, jusqu'à 4), pas seulement sa dernière ligne ; timeout : un moteur bloqué ne gèle pas le lanceur
const run = (engine, script, lab, ...a) => {
  try { return execFileSync(process.execPath, [path.join(engine, 'scripts', script), lab, ...a], { encoding: 'utf8', maxBuffer: 256 << 20, stdio: ['ignore', 'pipe', 'pipe'], timeout: 600000, env: etatMoteur(lab).env }); }
  catch (e) {
    const lines = String(e.stderr || e.stdout || e.message).split('\n').map((l) => l.trim()).filter(Boolean);
    const cause = (lines.filter((l) => /^(✗|-|error|Error)/.test(l)).slice(0, 4).join(' · ') || lines.slice(-1)[0] || 'cause inconnue').slice(0, 400);
    throw fin(4, `échec de l'étape ${script} du moteur du cockpit. Cause : ${cause}`);
  }
};

// ---- annotateurs du graphe Code (A27) : `annotateur(g, ctx)` modifie `g` en mémoire, synchrone, indépendant des autres ----
// ctx = { lab, sortie, project, arch, eng }
function annoterDescriptions(g, { lab }) { // descriptions tirées du frontmatter ou de l'en-tête des scripts ; rend le nombre de fichiers décrits
  let decrits = 0;
  for (const f of g.files) {
    const txt = lireConfine(lab, () => lireGarde(path.join(lab, f.p))).slice(0, 6000); // AUDC-A-02 : défense en profondeur assumée — le scan écarte déjà un lien sortant, donc aucun cas de suite ne dépend de ce seul confinement ; il garde l'assemblage sûr si la liste du scan change
    const fmBlock = /^---\n([\s\S]*?)\n---/.exec(txt)?.[1];
    let d = '';
    if (fmBlock) { d = /^description:\s*"?(.*?)"?\s*$/m.exec(fmBlock)?.[1] || ''; const nm = /^name:\s*(.*)$/m.exec(fmBlock)?.[1]; if (nm) f.name = nm.trim(); }
    else if (/\.(sh|bash)$/.test(f.p)) d = txt.split('\n').slice(txt.startsWith('#!') ? 1 : 0).filter((l, i, a) => /^#/.test(l) && a.slice(0, i).every((x) => /^#/.test(x))).map((l) => l.replace(/^#+\s?/, '')).join(' ');
    else if (f.p.endsWith('.md')) d = nettoyerMarkdown(txt.replace(/^#.*$/gm, '')).split(/\n\s*\n/).map((p) => p.replace(/\s+/g, ' ').trim()).find((p) => p.length > 30) || '';
    if (d) { f.d = extraitBrut(sentence(d)); f.auto = false; decrits++; }
  }
  return decrits;
}
const annoterGit = (g, { lab }) => { g.meta.vfGit = enteteGit(lab); }; // 78-04 : nom du dépôt, branche, worktree
function annoterLogos(g, { eng }) {
  const logo = (n) => 'data:image/svg+xml;base64,' + fs.readFileSync(path.join(eng.chemin, 'assets', n)).toString('base64');
  g.meta.vfLogos = { clair: logo('vibeflow-logo-clair.svg'), sombre: logo('vibeflow-logo-sombre.svg') };
}
const annoterOnglet = (g, { arch }) => { g.meta.vfTab = 'code'; g.meta.vfCodeExtractor = arch.extracteur; };
const annoterSchema = (g) => { g.schema = 'vf-cockpit/graph@1'; }; // garde:annot-schema — seul champ de données amont qui porte le nom du produit
function annoterTouche(g, { project }) { // index inverse fichier -> plans
  const touch = Object.create(null); // un chemin `constructor` ou `__proto__` du lab n'est qu'une clé
  for (const f of project.files) for (const p of f.touched || []) (touch[p] ||= []).push({ ref: 'f:' + f.p, label: f.name.slice(0, 90), st: f.st });
  g.meta.vfTouch = touch;
}
// la table (une ligne par annotateur, ordre alphabétique par nom : l'ordre d'exécution ne doit rien changer au résultat)
export const ANNOTATEURS = [
  ['descriptions', annoterDescriptions],
  ['git', annoterGit],
  ['logos', annoterLogos],
  ['onglet', annoterOnglet],
  ['schema', annoterSchema],
  ['touche', annoterTouche],
];
function validerAnnotateurs(table) {
  const vus = new Set();
  if (!Array.isArray(table)) throw fin(4, 'table des annotateurs invalide : un tableau est attendu');
  for (const l of table) {
    const [nom, f] = Array.isArray(l) ? l : [];
    const ok = typeof nom === 'string' && nom && typeof f === 'function' && !vus.has(nom);
    if (!ok) throw fin(4, `table des annotateurs invalide (${String(nom).slice(0, 60)})`);
    vus.add(nom);
  }
}
export function appliquerAnnotateurs(g, ctx, table = ANNOTATEURS) {
  validerAnnotateurs(table);
  const retours = {};
  for (const [nom, f] of table) {
    let r;
    try { r = f(g, ctx); } catch (e) { throw fin(4, `échec de l'annotateur ${nom} du graphe Code. Cause : ${String(e && e.message).slice(0, 200)}`); }
    if (r && typeof r.then === 'function') {
      r.catch(() => {});
      throw fin(4, `échec de l'annotateur ${nom} du graphe Code. Cause : annotateur asynchrone refusé`);
    }
    retours[nom] = r;
  }
  return retours;
}

export function assembler({ lab: labArg, quiet = false, scriptsDir: sd, annotateurs = ANNOTATEURS } = {}) {
  const t0 = Date.now();
  validerAnnotateurs(annotateurs); // avant toute écriture
  const lab = findLabRoot(labArg || process.cwd());
  if (!lab) throw fin(2, 'aucun dossier .planning trouvé : le cockpit se construit dans un lab GSD.');
  const scriptsDir = sd || HERE; // AUDC-B-06 : le dossier de scripts de l'assembleur est son propre emplacement, jamais une VF_COCKPIT_SCRIPTS_DIR héritée
  const eng = engineDir(scriptsDir);
  if (eng.etat !== 'trouve') throw fin(3, 'moteur du cockpit introuvable : réinstaller le module cockpit.');
  const sortie = outputDir(lab);
  if (fs.existsSync(path.dirname(sortie))) verifierSortie(lab, path.dirname(sortie)); // M4 : aucun lien symbolique avant la moindre écriture
  fs.mkdirSync(sortie, { recursive: true });
  verifierSortie(lab, sortie);
  purgerCodeAncien(sortie); // avant toute écriture : la sortie n'est jamais source de code (P79-D-26)

  const ferme = etatMoteur(lab).ferme; // R6 : dit dans le résumé quand git du moteur reste fermé
  // AB1 : un lab inchangé (fichiers, index git, environnement git et code du moteur) ne relance pas le scan ;
  // la signature est posée APRÈS un scan réussi, effacée avant
  const sigLab = signatureDuLab({ lab, moteur: eng.chemin, etatGit: JSON.stringify([ferme, filtresEtat(lab, lab).noms]) });
  if (!(sigLab && sigLab === lireSignature(sortie) && fs.existsSync(path.join(sortie, '.cache', 'scan.json')))) {
    fs.rmSync(path.join(sortie, '.cache', 'scan-signature.json'), { force: true });
    run(eng.chemin, 'scan.mjs', lab); // le moteur refuse un dossier de sortie non vide qui n'est pas encore une carte : .gitignore après
    if (sigLab) ecrireSignature(lab, sortie, sigLab);
  }
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

  // onglet Code : les annotateurs de la table (descriptions, index inverse fichier -> plans, logos, entête Git…) puis le schéma
  const g = JSON.parse(read(path.join(sortie, 'graph.json')));
  const decrits = appliquerAnnotateurs(g, { lab, sortie, project, arch, eng }, annotateurs).descriptions || 0;
  fs.writeFileSync(path.join(sortie, 'graph.json'), JSON.stringify(g));

  // les deux pages : même viewer, données différentes
  const html = renommerPageMoteur(read(path.join(sortie, 'index.html'))); // A48 : la page du moteur est renommée AVANT l'insertion des données
  fs.writeFileSync(path.join(sortie, 'index.html'), insererGraphe(html, { ...g, meta: { ...g.meta, repos: [] } }).replace(/<title>[^<]*<\/title>/, '<title>VibeFlow · Code</title>'));
  project.meta.root = g.meta.root; project.meta.vfLogos = g.meta.vfLogos; project.meta.vfGit = g.meta.vfGit;
  fs.writeFileSync(path.join(sortie, 'project.html'), insererGraphe(html, project).replace(/<title>[^<]*<\/title>/, '<title>VibeFlow · Projet</title>'));
  // A29 : l'outil de requête de l'agent « Demander » le lit sans serveur
  if (!ecrireProjet(lab, sortie, project)) throw fin(4, 'projet.json non écrit : la sortie du cockpit le refuse.');

  // bannière de licence (marque blanche : déjà faite sur la page du moteur, jamais sur les données du lab)
  for (const f of ['index.html', 'project.html']) {
    const p = path.join(sortie, f); const h = read(p);
    const licence = `<!-- ${MARQUEUR_LICENCE} : logiciel tiers sous licence MIT, voir LICENSE et LICENCES-TIERCES.txt (floorplan) -->`;
    fs.writeFileSync(p, /^<!doctype[^\n]*\n/i.test(h) ? h.replace(/^(<!doctype[^\n]*\n)/i, `$1${licence}\n`) : `${licence}\n${h}`);
  }
  for (const f of ['LICENSE', 'LICENCES-TIERCES.txt']) fs.copyFileSync(path.join(eng.chemin, f), path.join(sortie, f));
  fs.mkdirSync(path.join(sortie, '.cache'), { recursive: true });
  fs.writeFileSync(path.join(sortie, '.cache', 'vf-cockpit.json'), JSON.stringify({ scriptsDir, engineDir: eng.chemin, builtAt: new Date().toISOString() }, null, 2));

  const resume = `Cockpit assemblé : Code ${g.files.length} fichiers (${decrits} décrits sans modèle), Projet ${project.nodes.length} cartes · ${((Date.now() - t0) / 1000).toFixed(1)} s · ${sortie}${ferme ? ` · git du moteur fermé (${ferme}) : carte sans fichiers suivis ni head` : ''}`;
  if (!quiet) console.log(resume);
  const nc = project.meta.vf.drift; // diagnostic : ce que les lecteurs n'ont pas compris (sinon un graphe vide et muet)
  const diagnostic = nc.nonComprisesN ? `${nc.nonComprisesN} ligne(s) non comprise(s) du planning : ${nc.nonComprises.map((x) => `${x.fichier}:${x.ligne}`).join(' ')}${nc.nonComprisesN > nc.nonComprises.length ? ` … (+${nc.nonComprisesN - nc.nonComprises.length})` : ''}` : '';
  if (diagnostic && !quiet) console.log(diagnostic);
  return { lab, sortie, fichiersCode: g.files.length, cartesProjet: project.nodes.length, gitFerme: ferme, resume, diagnostic };
}

if (process.argv[1] && import.meta.url === pathToFileURL(fs.realpathSync(process.argv[1])).href) {
  const args = process.argv.slice(2);
  try { assembler({ lab: args.find((a) => !a.startsWith('--')), quiet: args.includes('--quiet') }); }
  catch (e) { console.error(e.message); process.exit(e.code || 4); }
}
