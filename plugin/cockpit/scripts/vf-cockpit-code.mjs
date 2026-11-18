// vf-cockpit-code — onglet Code brut, sans modèle (67-03). Écrit <sortie>/architecture.json à partir du scan :
// un nœud par dossier de premier niveau portant du code, un nœud « Racine » pour les fichiers de premier niveau ;
// un dépôt imbriqué (app/ ignoré par la racine, sous-module) a sa carte, ses dossiers et ses espaces de travail.
// Export : ecrireArchitecture({ lab, sortie }) -> { extracteur: 'vibeflow' | 'brut', noeuds }.
// 67-05 (P67-D-17) : un lab qui porte au moins un plugin/*/module.json reçoit l'extracteur VibeFlow (vf-cockpit-code-vf.mjs) ;
// tout autre lab, l'architecture brute ci-dessous. Aucun appel à un modèle dans les deux cas.
import fs from 'node:fs';
import path from 'node:path';
import { architectureVibeflow } from './vf-cockpit-code-vf.mjs';
import { lireConfine } from './vf-cockpit-planning.mjs';

const aDesModules = (lab) => { try { return fs.readdirSync(path.join(lab, 'plugin'), { withFileTypes: true }).some((e) => e.isDirectory() && fs.existsSync(path.join(lab, 'plugin', e.name, 'module.json'))); } catch { return false; } };

export function ecrireArchitecture({ lab, sortie }) {
  // AUDC-A-02 : les lectures du lab faites ici (module.json, VERSION, agents…) se font sous confinement à la racine réelle du lab, comme le reste de l'assemblage
  return lireConfine(lab, () => aDesModules(lab) ? architectureVibeflow({ lab, sortie }) : architectureBrute({ lab, sortie }));
}

// Dépôts imbriqués (discover() du moteur, scan.repos hors « . ») : une carte par dépôt, puis une par dossier de premier niveau du dépôt ;
// un dossier dont au moins deux sous-dossiers portent un manifeste (package.json, pyproject.toml…) est un conteneur d'espaces
// de travail (apps/, packages/) et reçoit une carte par espace. Tout se lit dans le scan, aucune lecture du lab.
const MANIFESTES = new Set(['package.json', 'pyproject.toml', 'go.mod', 'Cargo.toml', 'Package.swift', 'pubspec.yaml', 'composer.json', 'deno.json']);
const ident = (p) => p.replace(/[^A-Za-z0-9_.-]+/g, '-');
const nFichiers = (n) => `${n} ${n === 1 ? 'fichier' : 'fichiers'} de code`;
const carte = (id, parent, label, summary, cle) => ({ id, ...(parent ? { parent } : {}), label, kind: 'library', summary, paths: [`${cle}/**`] });
function cartesImbriquees(scan, code) {
  const tous = (scan.repos || []).map((r) => r.path).filter((p) => typeof p === 'string');
  // imbriqué = sous un autre dépôt du lab ; des dépôts côte à côte sous un dossier sans git gardent leur carte de dossier
  const sous = (p, x) => x !== p && (x === '.' || p.startsWith(x + '/'));
  const depots = tous.filter((p) => p !== '.' && tous.some((x) => sous(p, x)));
  depots.sort((a, b) => b.length - a.length); // le plus profond d'abord
  const depotDe = (p) => depots.find((d) => p.startsWith(d + '/')) || null;
  const manif = new Set(scan.files.filter((f) => MANIFESTES.has(path.posix.basename(f.path))).map((f) => path.posix.dirname(f.path)));
  const nodes = [], compte = new Map(), hors = [];
  const ajoute = (cle) => compte.set(cle, (compte.get(cle) || 0) + 1);
  for (const p of code) {
    const d = depotDe(p);
    if (!d) { hors.push(p); continue; }
    ajoute(d);
    const s = p.slice(d.length + 1).split('/');
    if (s.length < 2) continue;
    const conteneur = `${d}/${s[0]}`;
    ajoute(conteneur);
    if (s.length > 2 && manif.has(`${conteneur}/${s[1]}`)) ajoute(`${conteneur}/${s[1]}`);
  }
  const enfants = (c) => [...compte.keys()].filter((k) => path.posix.dirname(k) === c).sort();
  for (const d of [...depots].reverse().filter((x) => compte.has(x))) {
    const branche = scan.repos.find((x) => x.path === d)?.branch;
    const parent = depots.find((x) => d.startsWith(x + '/') && compte.has(x));
    const resume = `Dépôt ${d}${branche ? `, branche ${branche}` : ''} : ${nFichiers(compte.get(d))}.`;
    nodes.push(carte('r-' + ident(d), parent && 'r-' + ident(parent), d, resume, d));
    for (const c of enfants(d).filter((k) => depotDe(k + '/x') === d)) {
      nodes.push(carte('d-' + ident(c), 'r-' + ident(d), path.posix.basename(c), `Dossier ${c} : ${nFichiers(compte.get(c))}.`, c));
      const ws = enfants(c).filter((k) => manif.has(k));
      if (ws.length < 2) continue;
      const espace = (w) => carte('d-' + ident(w), 'd-' + ident(c), path.posix.basename(w), `Espace de travail ${w} : ${nFichiers(compte.get(w))}.`, w);
      nodes.push(...ws.map(espace));
    }
  }
  return { nodes, hors, depots };
}

const RESUME = 'Carte du code construite sans modèle : un nœud par dossier de premier niveau';
const IMBRIQUES = ', et pour chaque dépôt imbriqué ses dossiers et ses espaces de travail.';
function architectureBrute({ lab, sortie }) {
  const scan = JSON.parse(fs.readFileSync(path.join(sortie, '.cache', 'scan.json'), 'utf8'));
  const tout = scan.files.filter((f) => f.category === 'code').map((f) => f.path);
  const { nodes: imbriques, hors: code, depots } = cartesImbriquees(scan, tout);
  const dossiers = new Map(); let racine = 0;
  for (const p of code) { const i = p.indexOf('/'); if (i < 0) racine++; else dossiers.set(p.slice(0, i), (dossiers.get(p.slice(0, i)) || 0) + 1); }
  const dossierCarte = (d) => carte('d-' + ident(d), null, d, `Dossier ${d} : ${nFichiers(dossiers.get(d))}.`, d);
  const nodes = [...imbriques, ...[...dossiers.keys()].filter((d) => !depots.includes(d)).sort().map(dossierCarte)];
  if (!nodes.length && !racine) nodes.push({ id: 'racine', label: 'Racine', kind: 'config', summary: 'Aucun fichier de code reconnu dans ce dossier : la carte du code est vide, la carte du projet reste complète.', paths: ['*'] }); // P1 : un lab sans code s'assemble
  else if (racine) nodes.push({ id: 'racine', label: 'Racine', kind: 'config', summary: `Fichiers de code à la racine : ${racine}.`, paths: ['*'] });
  const project = { name: path.basename(lab), summary: RESUME + (depots.length ? IMBRIQUES : '.'), entrypoints: [] };
  const arch = { project, audience: 'developers', include: ['code'], nodes, edges: [] };
  fs.writeFileSync(path.join(sortie, 'architecture.json'), JSON.stringify(arch, null, 2));
  return { extracteur: 'brut', noeuds: nodes.length };
}
