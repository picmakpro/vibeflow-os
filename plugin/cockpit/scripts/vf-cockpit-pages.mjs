// vf-cockpit-pages — les empreintes des scripts en ligne d'un document du cockpit (79-15, SOCL-19 ; 79-16, SOCL-20).
// 79-16 : la coquille statique (vf-cockpit-coquille.mjs) remplace les pages en trois parties de 79-15 (les trois fonctions de préparation, d'assemblage
// et de mémoïsation de page sont retirées : plus aucun appelant, écart 79-16-d) ; l'export autonome garde « coquille + données incluses »
// dans sa propre fonction.
// Export : hachesDePage(texte) -> liste ordonnée dédoublonnée d'empreintes `'sha256-…'` (entre apostrophes) des scripts en ligne SANS attribut, dans l'ordre
// du document ; les scripts à `src` et les blocs de données (`type="application/json"`) n'en ont pas.
import crypto from 'node:crypto';

const empreinte = (texte) => `'sha256-${crypto.createHash('sha256').update(texte).digest('base64')}'`;
const dedoublonner = (l) => [...new Set(l)];
const scripts = (texte) => [...String(texte).matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => empreinte(m[1]));

export const hachesDePage = (texte) => dedoublonner(scripts(texte));
