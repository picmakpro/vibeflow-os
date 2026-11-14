// vf-cockpit-frontmatter — lecteur borné de blocs imbriqués du frontmatter (P76-D-24, T-76-01). Jamais d'évaluation YAML.
// Exports : valeurImbriquee, listeImbriquee. Ne lit que le premier bloc `---` (au plus 400 lignes), indentation stricte de deux espaces par niveau,
// éléments de liste « - » au niveau suivant la clé ; normalisation par `texte` de vf-cockpit-formats.mjs. Aucune RegExp construite depuis une valeur lue.
import { texte } from './vf-cockpit-formats.mjs';

const MAX_LIGNES = 400;
const CLE = /^( *)([\w-]+):[ \t]*(.*)$/;
const ELEMENT = /^( *)- +(.*)$/;
const indentDe = (l) => /^ */.exec(l)[0].length;
const sansGuillemets = (v) => String(v).trim().replace(/^["']|["']$/g, '').trim();

// lignes du premier bloc `---` ; null si le fichier ne l'ouvre pas ou si le bloc n'est pas fermé dans les 400 lignes
function bloc(txt) {
  const l = texte(txt).split('\n', MAX_LIGNES + 2);
  if (l[0] !== '---') return null;
  const fin = l.indexOf('---', 1);
  return fin > 0 && fin <= MAX_LIGNES ? l.slice(1, fin) : null;
}

// descend le chemin : une clé par niveau, à l'indentation 2 × niveau, dans le bloc de la clé précédente ; rend { debut, fin, valeur } du dernier
// niveau ou null
function descendre(lignes, chemin) {
  let debut = 0, fin = lignes.length, valeur = '';
  for (let d = 0; d < chemin.length; d++) {
    const ind = 2 * d; let ligne = -1;
    for (let i = debut; i < fin; i++) {
      if (!lignes[i].trim()) continue;
      const k = indentDe(lignes[i]);
      if (k < ind) break;
      if (k === ind) { const m = CLE.exec(lignes[i]); if (m && m[2] === chemin[d]) { ligne = i; valeur = m[3]; break; } }
    }
    if (ligne < 0) return null;
    debut = ligne + 1; let f = debut;
    while (f < fin && (!lignes[f].trim() || indentDe(lignes[f]) > ind)) f++;
    fin = f;
  }
  return { debut, fin, valeur };
}

// valeur scalaire d'une clé imbriquée (guillemets retirés) ; null si le bloc, le chemin ou la valeur manque
export function valeurImbriquee(txt, chemin) {
  const l = bloc(txt); if (!l) return null;
  const r = descendre(l, chemin);
  return r && r.valeur.trim() !== '' ? sansGuillemets(r.valeur) : null;
}

// éléments d'une liste imbriquée (« - x » au niveau qui suit la clé, ou « [a, b] » sur la ligne de la clé), guillemets retirés, au plus `max` ; [] si absente
export function listeImbriquee(txt, chemin, { max = 64 } = {}) {
  const l = bloc(txt); if (!l) return [];
  const r = descendre(l, chemin); if (!r) return [];
  if (r.valeur.trim().startsWith('[')) return r.valeur.trim().replace(/^\[|\]$/g, '').split(',').map(sansGuillemets).filter(Boolean).slice(0, max);
  const out = [], ind = 2 * chemin.length;
  for (let i = r.debut; i < r.fin && out.length < max; i++) {
    const m = ELEMENT.exec(l[i]);
    if (m && m[1].length === ind) { const v = sansGuillemets(m[2]); if (v) out.push(v); }
  }
  return out;
}
