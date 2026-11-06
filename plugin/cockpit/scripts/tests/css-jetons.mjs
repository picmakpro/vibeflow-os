// css-jetons.mjs — garde de la feuille d'un fichier ui du cockpit (78-04, P78-D-12), aide de test partagée (78-06, 78-10, 78-11).
// Usage : node css-jetons.mjs <fichier…>. Lit le texte de chaque fichier ; rend 1 et nomme chaque valeur fautive, 0 sinon.
//   couleur     : littéral #rgb / #rrggbb en valeur de propriété, ou rgb( rgba( hsl( hsla( dont l'argument ne commence pas par var(
//   espacement  : toute valeur en px de padding, margin ou gap (signe compris) hors {2, 4, 6, 8, 12, 16, 20, 24, 32}
//   rayon       : toute valeur de border-radius hors {999px, 8px} ou var(--r-…)
// Aucune dépendance. Sortie : une ligne `fichier:ligne : <règle> <valeur>` par écart.
import fs from 'node:fs';

// grille d'espacement figée par la Phase 71.5 (arbitrages Samuel, AskUserQuestion session principale, 2026-11-05) : 2-4-6-8-12-16-20-24-32 ; 10 et 14 n'en font plus partie (R5, revue serveur 2026-11-06)
const ESPACEMENTS = new Set([2, 4, 6, 8, 12, 16, 20, 24, 32]);
const RAYONS = new Set(['999px', '8px']);
const lignes = (txt, idx) => txt.slice(0, idx).split('\n').length;

export function ecarts(txt) {
  const out = [];
  const ajoute = (idx, regle, valeur) => out.push({ ligne: lignes(txt, idx), regle, valeur });
  // couleurs : littéral hexadécimal dans une valeur de propriété (jamais un sélecteur #id)
  for (const m of txt.matchAll(/:\s*[^;{}\n]*?(#[0-9a-fA-F]{3,8})(?![\w-])/g)) ajoute(m.index, 'couleur', m[1]);
  for (const m of txt.matchAll(/\b((?:rgb|rgba|hsl|hsla)\()\s*(?!var\()/g)) ajoute(m.index, 'couleur', m[1]);
  // espacements : padding, margin, gap (et leurs variantes -top, -left…)
  for (const m of txt.matchAll(/(?<![\w-])((?:padding|margin)(?:-[a-z]+)?|gap|row-gap|column-gap)\s*:\s*([^;}\n]+)/g)) {
    for (const t of m[2].matchAll(/(-?\d+(?:\.\d+)?)px\b/g)) if (!ESPACEMENTS.has(Math.abs(Number(t[1])))) ajoute(m.index, m[1], t[0]);
  }
  // rayons
  for (const m of txt.matchAll(/(?<![\w-])border-radius\s*:\s*([^;}\n]+)/g)) {
    for (const v of m[1].trim().split(/\s+/)) if (!RAYONS.has(v) && !/^var\(--r-[\w-]+\)$/.test(v)) ajoute(m.index, 'border-radius', v);
  }
  return out;
}

if (process.argv[1] && import.meta.url === new URL(`file://${fs.realpathSync(process.argv[1])}`).href) {
  const fichiers = process.argv.slice(2);
  if (!fichiers.length) { console.error('usage : node css-jetons.mjs <fichier…>'); process.exit(2); }
  let n = 0;
  for (const f of fichiers) for (const e of ecarts(fs.readFileSync(f, 'utf8'))) { console.log(`${f}:${e.ligne} : ${e.regle} ${e.valeur}`); n++; }
  process.exit(n ? 1 : 0);
}
