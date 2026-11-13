// vf-cockpit-trace-memoire — mémoire versionnée des agents lue en structure (76-03 ; TRAC-07, TRAC-08 ; P76-D-19 à D-23). Module PUR : aucun accès disque ni git.
// Exports : liensDe(txt), MOTIF_CHEMIN, entreesMemoire({ fichiers, index, head, historique, jours, fm }).
// Le texte des fichiers est lu ici pour en extraire liens et chemins, puis JETÉ : aucun objet rendu ne porte description, corps ou texte.
import { valeurImbriquee } from './vf-cockpit-frontmatter.mjs';

const RACINE = '.claude/agent-memory/';
export const MOTIF_CHEMIN = /(?<![\w./~@-])(?:[\w@.-]+\/)+[\w@-][\w@.-]*\.[A-Za-z0-9]{1,8}(?![\w/])/g;

// cibles `[[…]]` du texte
export function liensDe(txt) {
  const out = [];
  for (const m of String(txt ?? '').matchAll(/\[\[([^[\]\n]{1,128})\]\]/g)) {
    const cible = m[1].split(/[|#]/)[0].trim();
    if (cible) out.push(cible);
  }
  return out;
}

const decoupe = (chemin) => { const m = /^\.claude\/agent-memory\/([^/]+)\/([^/]+)$/.exec(chemin); return m ? { agent: m[1], fichier: m[2] } : null; };

export function entreesMemoire({ fichiers = [], index = new Map(), jours = new Map(), fm = () => ({}) } = {}) {
  const entrees = [];
  const textes = new Map();
  for (const f of fichiers) {
    const d = decoupe(f.chemin);
    if (!d || d.fichier === 'MEMORY.md') continue;
    const cle = `${d.agent}/${d.fichier}`;
    textes.set(cle, f.txt);
    entrees.push({ cle, chemin: `${RACINE}${cle}`, agent: d.agent, name: fm(f.txt).name || null, type: valeurImbriquee(f.txt, ['metadata', 'type']),
      jour: jours.get(`${RACINE}${cle}`) ?? null, sortants: [], entrants: [] });
  }
  const parNom = new Map();
  for (const e of entrees) if (e.name) parNom.set(e.name, [...(parNom.get(e.name) ?? []), e]);
  for (const e of entrees) {
    for (const cible of new Set(liensDe(textes.get(e.cle)))) {
      const c = parNom.get(cible) ?? [];
      const vers = c.length === 1 ? c[0] : null;
      e.sortants.push({ cible, etat: 'resolu', vers: vers ? vers.cle : undefined });
      if (vers && vers !== e && !vers.entrants.includes(e.cle)) vers.entrants.push(e.cle);
    }
  }
  return { agents: [], entrees, compteurs: { entrees: entrees.length } };
}
