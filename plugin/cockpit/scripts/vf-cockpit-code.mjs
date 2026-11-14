// vf-cockpit-code — onglet Code brut, sans modèle (67-03). Écrit <sortie>/architecture.json à partir du scan :
// un nœud par dossier de premier niveau portant du code, un nœud « Racine » pour les fichiers de premier niveau.
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

function architectureBrute({ lab, sortie }) {
  const scan = JSON.parse(fs.readFileSync(path.join(sortie, '.cache', 'scan.json'), 'utf8'));
  const code = scan.files.filter((f) => f.category === 'code').map((f) => f.path);
  const dossiers = new Map(); let racine = 0;
  for (const p of code) { const i = p.indexOf('/'); if (i < 0) racine++; else dossiers.set(p.slice(0, i), (dossiers.get(p.slice(0, i)) || 0) + 1); }
  const nodes = [...dossiers.keys()].sort().map((d) => ({ id: 'd-' + d.replace(/[^A-Za-z0-9_.-]+/g, '-'), label: d, kind: 'library', summary: `Dossier ${d} : ${dossiers.get(d)} ${dossiers.get(d) === 1 ? 'fichier' : 'fichiers'} de code.`, paths: [`${d}/**`] }));
  if (!code.length) nodes.push({ id: 'racine', label: 'Racine', kind: 'config', summary: 'Aucun fichier de code reconnu dans ce dossier : la carte du code est vide, la carte du projet reste complète.', paths: ['*'] }); // P1 : un lab sans code s'assemble
  else if (racine) nodes.push({ id: 'racine', label: 'Racine', kind: 'config', summary: `Fichiers de code à la racine : ${racine}.`, paths: ['*'] });
  const arch = { project: { name: path.basename(lab), summary: 'Carte du code construite sans modèle : un nœud par dossier de premier niveau.', entrypoints: [] }, audience: 'developers', include: ['code'], nodes, edges: [] };
  fs.writeFileSync(path.join(sortie, 'architecture.json'), JSON.stringify(arch, null, 2));
  return { extracteur: 'brut', noeuds: nodes.length };
}
