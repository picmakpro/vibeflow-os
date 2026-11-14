// vf-cockpit-collecte-frise — l'étape de FRISE du fil de collecte (79-13, SOCL-17 ; P79-D-04, P79-D-12, A31, A35, A47). Synchrone, dans le fil,
//  aucun réseau.
// Exports : TRANCHE_OCTETS (8 Mio), TRANCHE_MS (150), FLUSH_MS (400), PAQUET_VOIES (200),
//   etapeFrise({ racine, home, memo, equipe, maintenant, horloge, octets, ms }) -> { messages, reste } : projette les voies de l'index gardées dans `memo`
//     (liste blanche, état officiel et rattachement joints, cibles lues par une tranche), puis rend les messages du fil (premier message complet, ensuite
//     seulement les voies changées et les identifiants retirés) ; aucun message quand rien n'a changé ;
//   tranche({ memo, maintenant, horloge, octets, ms }) -> { messages, reste } : poursuit la passe de fond d'une tranche ; un message au plus toutes
//   les FLUSH_MS
//     (horloge injectable), et à la fin de la passe.
// Message { complet?, majs, suite, retirees?, source?, tronque?, sig? } : les voies traversent par paquets de 200 au plus ; seul le dernier paquet
//  (suite faux)
// porte retirees, source, tronque et la signature de la projection ENTIÈRE. Les cibles restent en mémoire : ni l'index ni un fichier n'en portent.
import path from 'node:path';
import { enumerer } from './vf-cockpit-index.mjs';
import { lire as lireOfficiel } from './vf-cockpit-etat-officiel.mjs';
import { rattacherVoies } from './vf-cockpit-voies-rattachement.mjs';
import { arbresGit } from './vf-cockpit-arbres.mjs';
import { racinesDeComparaison, arbreDeNom } from './vf-cockpit-cible.mjs';
import { creerSuivi } from './vf-cockpit-cibles-suivi.mjs';
import { projeterVoie, sigFrise, VOIES_MAX } from './vf-cockpit-frise-voie.mjs';

export const TRANCHE_OCTETS = 8 << 20, TRANCHE_MS = 150, FLUSH_MS = 400, PAQUET_VOIES = 200;
const OFFICIELS = new Set(['actif', 'attend', 'au-repos', 'termine']);
const CIBLES_VIDES = Object.freeze({ etat: 'en-construction', tronque: false, ecritures: [], lectures: [] });
const cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

// les arbres prouvés du dépôt (arbresGit n'élargit la liste qu'aux worktrees dont le lien retour est vérifié) ; échec : l'arbre principal seul
function tableDes(racine) {
  let arbres = null;
  try { arbres = arbresGit(racine); } catch { arbres = null; }
  return racinesDeComparaison(racine, arbres);
}

function stamp(v, F, arbre, officiel, rat) {
  const c = v.curseur || {};
  return [c.taille, c.mtimeMs, v.fini, v.arrete, v.dispatchA, v.role, v.parent, v.depth, v.background, v.forme, arbre, officiel, JSON.stringify(rat),
    F.suivi.version(v.id)].join('|');
}

// rattache chaque voie à ses jointures et range les projections changées dans F.sale
function projeter(F) {
  const ids = new Set();
  for (const v of F.voies) {
    ids.add(v.id);
    const ent = arbreDeNom(F.arbres, v.arbre), arbre = ent ? ent.nom : null;
    const brut = v.kind === 'session' && F.carte ? F.carte.get(v.id) : null;
    const officiel = brut && OFFICIELS.has(brut.etat) ? brut.etat : null; // garde:frise-officiel
    const rat = F.rat.get(v.id) ?? null; // garde:frise-rattachement
    const s = stamp(v, F, arbre, officiel, rat), prev = F.courant.get(v.id);
    if (prev && prev.stamp === s) continue;
    const cibles = v.forme === 'inconnue' ? null : F.suivi.cibles(v.id) || CIBLES_VIDES;
    F.courant.set(v.id, { stamp: s, proj: projeterVoie(v, { arbre, etatOfficiel: officiel, rattachement: rat, cibles }) });
    F.sale.add(v.id);
  }
  for (const id of [...F.courant.keys()]) if (!ids.has(id)) { F.courant.delete(id); F.sale.delete(id); F.retirees.push(id); }
}

function sourceDe(F, idx) {
  const inc = F.voies.filter((v) => v.forme === 'inconnue').length;
  const etat = F.voies.length > 0 && inc === F.voies.length ? 'forme-inconnue' : inc > 0 ? 'partielle' : 'ok';
  const versionsVues = (idx.versionsVues || []).filter((x) => typeof x === 'string').slice(0, 8);
  return { etat, ccVerifie: typeof idx.ccVerifie === 'string' ? idx.ccVerifie : '', versionsVues };
}

function paquets(F, force) {
  const srcJ = JSON.stringify([F.source, F.tronque]), srcChange = srcJ !== F.srcJ;
  if (!force && !F.premier && F.sale.size === 0 && F.retirees.length === 0 && !srcChange) return [];
  const toutes = [...F.courant.values()].map((e) => e.proj).sort((a, b) => (a.debut ?? 0) - (b.debut ?? 0) || cmp(a.id, b.id));
  const majs = F.premier ? toutes : [...F.sale].map((id) => F.courant.get(id)).filter(Boolean).map((e) => e.proj);
  const sig = sigFrise({ source: F.source, tronque: F.tronque, voies: toutes }), n = Math.max(1, Math.ceil(majs.length / PAQUET_VOIES)), out = [];
  for (let i = 0; i < n; i++) {
    const m = { majs: majs.slice(i * PAQUET_VOIES, (i + 1) * PAQUET_VOIES), suite: i < n - 1 };
    if (i === 0 && F.premier) m.complet = true;
    if (i === n - 1) Object.assign(m, { retirees: F.retirees, source: F.source, tronque: F.tronque, sig });
    out.push(m);
  }
  F.premier = false; F.sale = new Set(); F.retirees = []; F.srcJ = srcJ;
  return out;
}

export function etapeFrise({ racine, home, memo, equipe, maintenant = Date.now(), horloge = Date.now, octets = TRANCHE_OCTETS, ms = TRANCHE_MS, limites }) {
  const idx = memo.index;
  if (!idx || !Array.isArray(idx.voies)) return { messages: [], reste: false };
  const F = (memo.frise ||= { suivi: creerSuivi({ limites }), courant: new Map(), sale: new Set(), retirees: [], premier: true, srcJ: null, flushA: 0 });
  F.voies = idx.voies.slice(0, VOIES_MAX); // garde:frise-instantane-borne
  F.tronque = idx.evinces > 0;
  F.arbres = tableDes(racine); F.carte = lireOfficiel(home); F.rat = rattacherVoies(F.voies, equipe && equipe.workers);
  F.fichiers = new Map(enumerer(path.join(home, '.claude', 'projects')).map((c) => [c.id, c.fichier]));
  F.suivi.oublier(new Set(F.voies.map((v) => v.id)));
  F.suivi.avancer({ voies: F.voies, fichiers: F.fichiers, arbres: F.arbres, maintenant, octets, ms, horloge });
  F.source = sourceDe(F, idx); projeter(F); F.flushA = horloge();
  return { messages: paquets(F, false), reste: F.suivi.reste() };
}

export function tranche({ memo, maintenant = Date.now(), horloge = Date.now, octets = TRANCHE_OCTETS, ms = TRANCHE_MS }) {
  const F = memo.frise;
  if (!F || !F.voies) return { messages: [], reste: false };
  F.suivi.avancer({ voies: F.voies, fichiers: F.fichiers, arbres: F.arbres, maintenant, octets, ms, horloge });
  projeter(F);
  const reste = F.suivi.reste();
  if (reste && horloge() - F.flushA < FLUSH_MS) return { messages: [], reste };
  F.flushA = horloge();
  return { messages: paquets(F, false), reste };
}
