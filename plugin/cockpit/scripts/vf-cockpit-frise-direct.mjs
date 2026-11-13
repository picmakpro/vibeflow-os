// vf-cockpit-frise-direct — côté boucle principale : fusion des paquets de frise du fil dans l'instantané (79-13, SOCL-17 ; A31, A47).
// Exports : recevoirFrise(message), brancherFluxFrise({ diffuser, seq }) -> { stop }, finDeTour().
// recevoirFrise : le premier paquet (`complet`) remplace la table des voies tenue ici, les suivants appliquent leurs différences ; la frise n'est
//  posée dans
// l'instantané (poserFrise, qui la gèle) qu'au paquet final de la séquence (`suite` faux) ; une séquence interrompue par un paquet `complet` est
//  abandonnée.
import { poserFrise, surInstantane } from './vf-cockpit-instantane.mjs';
import { creerSignaleur } from './vf-cockpit-flux-etat.mjs';

let table = new Map();
const SIG = /^[0-9a-f]{16}$/;

export function recevoirFrise(m) {
  if (!m || typeof m !== 'object') return;
  if (m.complet === true) table = new Map();
  for (const v of Array.isArray(m.majs) ? m.majs : []) if (v && typeof v.id === 'string') table.set(v.id, v);
  for (const id of Array.isArray(m.retirees) ? m.retirees : []) table.delete(id);
  if (m.suite === true || typeof m.sig !== 'string' || !SIG.test(m.sig) || !m.source || typeof m.source !== 'object') return;
  const voies = [...table.values()].sort((a, b) => (a.debut ?? 0) - (b.debut ?? 0) || (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
  poserFrise({ at: Date.now(), sig: m.sig, source: m.source, tronque: m.tronque === true, voies });
}

// événement `frise` { seq, at, sig } (C4, A21) : sans contenu, `seq` jamais avancé. L'abonnement à l'instantané NOTE la signature de la frise
//  posée ; seul
// finDeTour (appelée par le pilote à la fin d'une demande qui portait `tour`) la passe au signaleur de 79-12, qui n'émet qu'au changement de
//  signature depuis
// son dernier événement : au plus un événement par tour, les poses d'un même tour (paquets de la passe de fond compris) se fondant en un. Aucune
//  minuterie.
let branche = null, note = null;

export function brancherFluxFrise({ diffuser, seq }) {
  const signaleur = creerSignaleur({ diffuser, seq });
  const retirer = surInstantane((inst) => { note = inst && inst.frise ? inst.frise.sig : null; }); // garde:frise-pose
  branche = signaleur;
  return { stop() { retirer(); if (branche === signaleur) branche = null; note = null; } };
}

export function finDeTour() {
  if (branche && note) branche.signaler('frise', '', note); // garde:frise-tour
}
