// vf-cockpit-blocages — blocages écrits dans le STATE du compartiment actif, lus en lecture seule, servis nettoyés et condensés
// (Phase 77, plan 77-02 ; P77-D-10, P77-D-20, SYNT-07).
// Module pur : aucun accès au système de fichiers, à l'environnement, à l'horloge ni au hasard ; seules dépendances `node:crypto`
// et `nettoie` (vf-cockpit-arbres.mjs). Le texte lu par `readPlanning` (point de lecture confiné) entre, une liste [{ h, t }] sort :
// `t` nettoyé (contrôles et bidi retirés, secrets masqués) et borné, `h` condensat de 12 caractères hexadécimaux du texte NORMALISÉ
// (calculé ici : la page n'a pas à dépendre de `crypto.subtle`). Aucune interprétation du texte.
// Exports : BORNES, PLACEHOLDERS, normaliser, condensat, lireBlocages.
import crypto from 'node:crypto';
import { nettoie } from './vf-cockpit-arbres.mjs';

export const BORNES = { entrees: 20, texte: 500 };
// puces vides du modèle de STATE (liste fermée), comparées après `normaliser` et retrait de la ponctuation finale
export const PLACEHOLDERS = ['none', 'none yet', 'aucun', 'aucune', 'néant', 'rien'];

// marques markdown (`**`, `__`, accents graves) retirées, blancs repliés, minuscules
export const normaliser = (texte) => String(texte ?? '').replace(/\*\*|__|`/g, '').replace(/\s+/g, ' ').trim().toLowerCase();
export const condensat = (texte) => crypto.createHash('sha256').update(normaliser(texte)).digest('hex').slice(0, 12);

const vide = (texte) => PLACEHOLDERS.includes(normaliser(texte).replace(/[.!\s]+$/, ''));

// puces de premier niveau de la section « ### Blockers/Concerns » (jusqu'au titre suivant de niveau 1 à 3) ; null si la section manque
export function lireBlocages(texteState) {
  const lignes = String(texteState ?? '').split('\n');
  const debut = lignes.findIndex((l) => /^###\s+Blockers\/Concerns\s*$/.test(l));
  if (debut < 0) return null;
  const puces = []; let courante = null;
  for (const l of lignes.slice(debut + 1)) {
    if (/^#{1,3}\s/.test(l)) break;
    const p = /^[-*]\s+(.*\S)\s*$/.exec(l);
    if (p) { courante = [p[1]]; puces.push(courante); }
    else if (courante && /^\s+\S/.test(l)) courante.push(l.trim());
    else courante = null;
  }
  return puces.map((m) => m.join(' ')).filter((t) => !vide(t)).slice(0, BORNES.entrees).map((t) => ({ h: condensat(t), t: nettoie(t, BORNES.texte) }));
}
