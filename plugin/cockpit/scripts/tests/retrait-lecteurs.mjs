// retrait-lecteurs.mjs (76-08, P76-D-39) : l'INVENTAIRE des lecteurs du nœud « Exigences » et la lecture de la porte unique des exigences.
// Jamais une porte de décision : l'inventaire imprime, il ne juge rien ; la preuve du retrait est le comportement de la porte (--porte, --porte-brut).
//   --inventaire <racine>      une ligne `OCCURRENCE <fichier>:<ligne>:<extrait>` par occurrence d'un jeton, puis `TROUVEES=<n>` ; sort 0, aucune exclusion
//   --porte <racine-du-lab>    sortie canonique de window.VF_EXIGENCES.lireExigences pour chaque phase du lab, `cible` ramenée à null
//   --porte-brut <racine>      la même sortie SANS normalisation (la `cible` brute)
//   --lab-reference <dossier>  écrit le lab de référence (deux compartiments, une exigence d'archive, plans qui couvrent)
//   --temoins <racine>         plante les formes dans une copie jetable et sort non nul si l'inventaire n'en voit pas une
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import vm from 'node:vm';
import { pathToFileURL, fileURLToPath } from 'node:url';

const ICI = path.dirname(fileURLToPath(import.meta.url));
const MODULE = path.resolve(ICI, '../..');
const PORTE = path.join(MODULE, 'skills/cockpit-moteur/assets/ui/41-vf-projet-phase.js');
const JETONS = ['.req', 'req/', 'couvre', 'entrant:data', 'sortant:data', 'feuille:exigences', 'liste:exigences', "kind: 'exigences'", "kind === 'exigences'"];

// jetons par SOUS-CHAÎNE insensible à la casse ; scripts/*.mjs, assets/ui/*.js et assets/viewer.html, hors tests/
function fichiersLus(racine) {
  const m = path.join(racine, 'plugin/cockpit'), sortie = [];
  const dans = (d, re) => {
    if (fs.existsSync(d)) for (const f of fs.readdirSync(d).sort()) if (re.test(f) && fs.statSync(path.join(d, f)).isFile()) sortie.push(path.join(d, f));
  };
  const A = 'skills/cockpit-moteur/assets';
  dans(path.join(m, 'scripts'), /\.mjs$/); dans(path.join(m, A, 'ui'), /\.js$/); dans(path.join(m, A), /^viewer\.html$/);
  return sortie;
}
function inventaire(racine) {
  const lignes = []; let n = 0;
  for (const f of fichiersLus(racine)) fs.readFileSync(f, 'utf8').split('\n').forEach((l, i) => {
    const bas = l.toLowerCase();
    for (const j of JETONS) if (bas.includes(j)) { n++; lignes.push(`OCCURRENCE ${path.relative(racine, f)}:${i + 1}:[${j}] ${l.trim().slice(0, 110)}`); }
  });
  return { lignes, n };
}

// la porte : le fichier de la 80 chargé dans un contexte vm, avec le graphe réel du lab ; aucun DOM, aucune initialisation (state sans `layout`, `on` muet)
async function lirePorte(racine) {
  const { buildProjectGraph } = await import(pathToFileURL(path.join(MODULE, 'scripts/vf-cockpit-project.mjs')).href);
  const G = buildProjectGraph(racine), fenetre = {};
  fenetre.window = fenetre; fenetre.Floorplan = { graph: G, state: {}, h: String, on() {} }; fenetre.__vfFrT = (x) => x;
  vm.runInNewContext(fs.readFileSync(PORTE, 'utf8'), fenetre, { filename: '41-vf-projet-phase.js' });
  if (!fenetre.VF_EXIGENCES || typeof fenetre.VF_EXIGENCES.lireExigences !== 'function') return null;
  const sortie = {};
  for (const n of G.nodes.filter((x) => x.kind === 'phase')) sortie[n.id] = JSON.parse(JSON.stringify(fenetre.VF_EXIGENCES.lireExigences(n.id)));
  return sortie;
}
const normaliser = (s) => { for (const p of Object.values(s)) {
  for (const e of p.exigences) e.cible = null;
  for (const l of Object.values(p.couverture)) for (const e of l) e.cible = null;
} return s; };

function ecrire(f, t) { fs.mkdirSync(path.dirname(f), { recursive: true }); fs.writeFileSync(f, t); }
const plan = (n, ids, but) => `---\nphase: x\nplan: "${n}"\nwave: 1\nrequirements: [${ids.join(', ')}]\n---\n\n<objective>${but}</objective>\n`;
function labReference(d) {
  const B = path.join(d, '.planning/workstreams');
  const lignes = (ws, rows) => rows.map(([i, ph, st]) => `| ${i} | Phase ${ph} | ${st} |`).join('\n');
  const LONG = 'Exigence au libellé long. '.repeat(14).trim();
  ecrire(`${B}/un/ROADMAP.md`, '- [ ] **Phase 1: Socle** - a\n- [ ] **Phase 2: Suite** - b\n\n### Phase 1: Socle\n**Goal**: le socle\n\n'
    + '### Phase 2: Suite\n**Goal**: la suite\n');
  ecrire(`${B}/un/REQUIREMENTS.md`, `- [x] **UN-01**: première exigence\n- [ ] **UN-02**: ${LONG}\n- [x] **UN-03**: troisième\n\n`
    + `${lignes('un', [['UN-01', 1, 'Complete'], ['UN-02', 1, 'Pending'], ['UN-03', 2, 'Complete']])}\n`);
  ecrire(`${B}/un/phases/01-socle/01-01-PLAN.md`, plan('01', ['UN-01', 'UN-02'], 'Premier plan'));
  ecrire(`${B}/un/phases/01-socle/01-02-PLAN.md`, plan('02', ['UN-01'], 'Second plan'));
  ecrire(`${B}/un/phases/02-suite/02-01-PLAN.md`, plan('01', ['UN-03', 'OLD-09'], 'Plan de la suite'));
  ecrire(`${B}/deux/ROADMAP.md`, '- [ ] **Phase 1: Autre** - c\n\n### Phase 1: Autre\n**Goal**: autre\n');
  ecrire(`${B}/deux/REQUIREMENTS.md`, `- [ ] **DEUX-01**: exigence de l'autre compartiment\n\n${lignes('deux', [['DEUX-01', 1, 'Pending']])}\n`);
  ecrire(`${B}/deux/phases/01-autre/01-01-PLAN.md`, plan('01', ['DEUX-01'], 'Plan de l\'autre compartiment'));
  ecrire(path.join(d, '.planning/milestones/v0-REQUIREMENTS.md'), `- [x] **OLD-09**: exigence d'archive\n\n${lignes('*', [['OLD-09', 2, 'Complete']])}\n`);
}

// témoins : l'inventaire voit les formes plantées (une copie jetable d'un lab minimal, jamais le dépôt)
function temoins() {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), 'retrait-temoins-')), m = path.join(d, 'plugin/cockpit');
  const forme = { 'scripts/a.mjs': "const x = 'ph-1.req';\n", 'scripts/b.mjs': 'const re = /\\.req$/;\n', 'scripts/c.mjs': "const y = id + '.req';\n",
    'scripts/d.mjs': "if (n.kind === 'exigences') f();\n", 'skills/cockpit-moteur/assets/viewer.html': "<script>kindLabels['sortant:data']</script>\n",
    'skills/cockpit-moteur/assets/ui/e.js': "const z = { kind: 'exigences' };\n" };
  for (const [f, t] of Object.entries(forme)) ecrire(path.join(m, f), t);
  const vues = new Set(inventaire(d).lignes.map((l) => l.split(':')[0].replace('OCCURRENCE ', '')));
  fs.rmSync(d, { recursive: true, force: true });
  const manque = Object.keys(forme).filter((f) => !vues.has(path.join('plugin/cockpit', f)));
  manque.forEach((f) => console.log(`TEMOIN-NON-VU ${f}`));
  return manque.length === 0;
}

const [, , mode, racine] = process.argv;
if (mode === '--inventaire') { const r = inventaire(path.resolve(racine)); r.lignes.forEach((l) => console.log(l)); console.log(`TROUVEES=${r.n}`); }
else if (mode === '--porte' || mode === '--porte-brut') {
  let s = null; try { s = await lirePorte(path.resolve(racine)); } catch { s = null; }
  process.stdout.write(s ? `${JSON.stringify(mode === '--porte' ? normaliser(s) : s, null, 2)}\n` : '{"erreur":"porte-absente"}\n');
} else if (mode === '--lab-reference') labReference(path.resolve(racine));
else if (mode === '--temoins') process.exit(temoins() ? 0 : 1);
else { console.error('usage : retrait-lecteurs.mjs --inventaire|--porte|--porte-brut|--lab-reference|--temoins <racine>'); process.exit(64); }
