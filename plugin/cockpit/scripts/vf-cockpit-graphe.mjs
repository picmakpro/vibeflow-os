// vf-cockpit-graphe — les graphes des trois onglets, leur signature et leur validateur d'étiquette (79-15, SOCL-19 ; C5, A5, R1 à R6).
// Exports : ONGLETS (gelé), ongletValide(v), VOLATILS, signatureGraphe(g) (16 hexadécimaux, hors champs volatils), etagDe(sig), correspond(enTete, etag),
// avecMetaDeBase(g, base), projectionGarde(g),
// creerGraphes({ forcerGabarit, nomDe, code, gardeWho }) -> { recharger(html), maj({ projet, who }), courant(onglet), dues(), emises(onglet, sig) }.
// `courant(onglet)` rend `{ g, sig, brut(), page() }` (JSON brut et JSON échappé pour une page, mémoïsés), `{ interdit: true }` (Équipe fermée par la
// garde) ou null.
// Deux signatures par onglet : la COURANTE (avancée par `maj`, idempotente) et l'ÉMISE (ce que le flux a annoncé) ; `dues()` rend les onglets où
// elles diffèrent : l'instantané les vide
// après sa pose, une requête ne fait qu'avancer la courante, donc aucun événement ne se perd et aucune page ne sert une donnée plus vieille que l'instantané.
// La signature n'est pas triée par clé : les producteurs construisent leurs objets dans un ordre déterministe.
import crypto from 'node:crypto';
import { extraireGraphe, serialiser } from './vf-cockpit-embed.mjs';
import { buildEquipeGraph, missionsEnCours } from './vf-cockpit-equipe-carte.mjs';

export const ONGLETS = Object.freeze(['code', 'projet', 'equipe']);
const ENSEMBLE = new Set(ONGLETS);
export const ongletValide = (v) => typeof v === 'string' && ENSEMBLE.has(v); // garde:graphe-onglet — appartenance exacte, jamais une recherche dans un objet
export const VOLATILS = Object.freeze(['meta.generatedAt', 'meta.scanAt']);

const sans = (o, [k, ...reste]) => {
  if (!o || typeof o !== 'object' || !(k in o)) return o;
  if (!reste.length) { const { [k]: _retire, ...autres } = o; return autres; }
  return { ...o, [k]: sans(o[k], reste) };
};
// garde:graphe-couvre
const sansVolatils = (g) => VOLATILS.reduce((acc, c) => sans(acc, c.split('.')), g);
export const signatureGraphe = (g) => crypto.createHash('sha256').update(JSON.stringify(sansVolatils(g))).digest('hex').slice(0, 16); // garde:graphe-couvre
export const etagDe = (sig) => `"${sig}"`;

// If-None-Match : liste d'étiquettes séparées par des virgules, préfixe faible ignoré, `*` accepté, en-tête de plus de 2 048 caractères ignoré ;
// égalité d'étiquette ENTIÈRE
export function correspond(enTete, etag) {
  if (typeof enTete !== 'string' || !enTete || enTete.length > 2048) return false;
  return enTete.split(',').some((e) => { const x = e.trim(); return x === '*' || x.replace(/^W\//, '') === etag; }); // garde:graphe-inm-liste
}

export function avecMetaDeBase(g, base) { // copie, jamais de mutation : le graphe de l'instantané est gelé
  const meta = { ...g.meta };
  for (const k of ['root', 'vfLogos', 'vfGit']) if (base && base[k] !== undefined) meta[k] = base[k];
  return { ...g, meta };
}

// projection soumise à la garde d'émission : les CLÉS de `meta.vfTouch` sont des chemins du lab (jamais des noms de champ), ses valeurs restent comparées
export function projectionGarde(g) { // garde:graphe-garde
  const t = g && g.meta && g.meta.vfTouch;
  if (!t || typeof t !== 'object' || Array.isArray(t)) return g;
  return { ...g, meta: { ...g.meta, vfTouch: Object.values(t) } };
}

const fabrique = (g, sig, brut) => {
  let b = brut || null, p = null;
  return { g, sig, brut: () => (b ??= JSON.stringify(g)), page: () => (p ??= serialiser(g)) };
};

export function creerGraphes({ forcerGabarit = false, nomDe = () => 'Projet', code = () => null, gardeWho = () => true } = {}) {
  let base = null, gabarit = null; // méta de base et graphe de l'assemblage (gabarit de page)
  const courants = { code: null, projet: null, equipe: null }, emise = {};
  let mP = { src: undefined, gab: undefined, val: null }, mE = { who: undefined, p: undefined, val: null, fait: null }, mC = { src: undefined, val: null };
  const suivre = (o) => { // au démarrage les émises valent les courantes
    const c = courants[o];
    if (c && c.sig && emise[o] === undefined) emise[o] = c.sig;
  };

  function recharger(html) {
    try { gabarit = extraireGraphe(html); } catch { gabarit = null; }
    const m = (gabarit && gabarit.meta) || {};
    base = { root: m.root, vfLogos: m.vfLogos, vfGit: m.vfGit };
  }

  function maj({ projet = null, who = null } = {}) {
    const src = forcerGabarit ? null : projet; // le réglage d'essai garde au serveur la source du gabarit
    if (mP.src !== src || mP.gab !== gabarit) { // garde:graphe-page
      const g = src ? avecMetaDeBase(src, base) : gabarit;
      mP = { src, gab: gabarit, val: g ? fabrique(g, signatureGraphe(g)) : null };
    }
    courants.projet = mP.val;
    const p = mP.val && mP.val.g;
    // 73-08 (P73-D-03, P73-D-21) : l'enveloppe d'Équipe est une coquille sans cartes ; elle ne dépend plus ni de `who` ni des lancements
    // (la ligne de lancement vit sur le `who` du direct) :
    // construite une fois par génération de la source du gabarit, sa signature (donc l'ETag de la route) ne bouge plus à chaque poussée.
    // La garde d'émission, elle, suit chaque `who`.
    if (mE.who !== who || mE.p !== p) {
      let val = { interdit: true };
      if (gardeWho(who)) { // garde:graphe-equipe
        if (!mE.fait || mE.fait.p !== p) {
          const g = buildEquipeGraph(who, { nom: nomDe(p), racine: p?.meta?.root, logos: p?.meta?.vfLogos, git: p?.meta?.vfGit, missions: missionsEnCours(p) });
          mE = { ...mE, fait: { p, val: fabrique(g, signatureGraphe(g)) } };
        }
        val = mE.fait.val;
      }
      mE = { ...mE, who, p, val };
    }
    courants.equipe = mE.val;
    const c = code();
    if (mC.src !== c) { mC = { src: c, val: c ? fabrique(c.g, c.sig, c.brut) : null }; }
    courants.code = mC.val;
    for (const o of ONGLETS) suivre(o);
  }

  return {
    recharger, maj,
    courant: (o) => (ongletValide(o) ? courants[o] : null),
    dues: () => ONGLETS.filter((o) => courants[o] && courants[o].sig && emise[o] !== undefined && courants[o].sig !== emise[o]),
    emises: (o, sig) => { if (ongletValide(o)) emise[o] = sig; },
  };
}
