// vf-cockpit-code — onglet Code brut, sans modèle (67-03). Écrit <sortie>/architecture.json à partir du scan :
// un nœud par dossier de premier niveau portant du code, un nœud « Racine » pour les fichiers de premier niveau.
// Export : ecrireArchitecture({ lab, sortie }) -> { extracteur: 'brut', noeuds }.
// Point d'extension : un extracteur plus riche (plan 67-05) remplace ce module en rendant un autre `extracteur`.
import fs from 'node:fs';
import path from 'node:path';

export function ecrireArchitecture({ lab, sortie }) {
  const scan = JSON.parse(fs.readFileSync(path.join(sortie, '.cache', 'scan.json'), 'utf8'));
  const code = scan.files.filter((f) => f.category === 'code').map((f) => f.path);
  const dossiers = new Map(); let racine = 0;
  for (const p of code) { const i = p.indexOf('/'); if (i < 0) racine++; else dossiers.set(p.slice(0, i), (dossiers.get(p.slice(0, i)) || 0) + 1); }
  const nodes = [...dossiers.keys()].sort().map((d) => ({ id: 'd-' + d.replace(/[^A-Za-z0-9_.-]+/g, '-'), label: d, kind: 'library', summary: `Dossier ${d} : ${dossiers.get(d)} fichiers de code.`, paths: [`${d}/**`] }));
  if (racine) nodes.push({ id: 'racine', label: 'Racine', kind: 'config', summary: `Fichiers de code à la racine : ${racine}.`, paths: ['*'] });
  const arch = { project: { name: path.basename(lab), summary: 'Carte du code construite sans modèle : un nœud par dossier de premier niveau.', entrypoints: [] }, audience: 'developers', include: ['code'], nodes, edges: [] };
  fs.writeFileSync(path.join(sortie, 'architecture.json'), JSON.stringify(arch, null, 2));
  return { extracteur: 'brut', noeuds: nodes.length };
}
