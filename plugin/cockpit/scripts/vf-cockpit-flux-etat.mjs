// vf-cockpit-flux-etat — deux événements du flux sans contenu : `vie` (battement nommé) et `etat` (changement de l'état) (79-12, C4, D-M2, A31).
// `vie` { seq, at } toutes les 15 s, par la diffusion du serveur (donc par la garde d'émission), hors journal ; remplace le commentaire de battement
// invisible au JavaScript. `etat` { seq, at, sig } au seul changement de la signature du `signal` (vf-cockpit-state.mjs : privée de ses champs volatils),
// le premier signal non nul compris. Ni l'un ni l'autre n'avance `seq` : la page recharge l'onglet Projet quand le `seq` d'un `hello` de reconnexion diffère
// du dernier `seq` qu'elle suit ; un lecteur qui reçoit `etat` relit GET /api/vf/state. `at` en millisecondes.
// Exports : VIE_MS, creerSignaleur({ diffuser, seq }) -> { signaler(nom, cle, sig, extra) }, brancherFluxEtat({ diffuser, seq, nbClients, vieMs }) -> { stop }.
// Règle d'ajout d'un événement sans contenu : un `signaler(nom, cle, sig)` à l'endroit où sa signature change, aucune minuterie, aucun `seq` avancé.
import { surInstantane } from './vf-cockpit-instantane.mjs';
import { sigState } from './vf-cockpit-state.mjs';

export const VIE_MS = 15000;

export function creerSignaleur({ diffuser, seq }) {
  const dernieres = new Map();
  return {
    signaler(nom, cle, sig, extra = {}) {
      if (typeof sig !== 'string' || !sig) return false; // jamais pour une signature nulle
      const k = `${nom}\0${cle ?? ''}`;
      if (dernieres.get(k) === sig) return false;
      dernieres.set(k, sig);
      diffuser(nom, { seq: seq(), at: Date.now(), ...extra, sig }); // garde:etat-seq
      return true;
    },
  };
}

export function brancherFluxEtat({ diffuser, seq, nbClients, vieMs = VIE_MS }) {
  const signaleur = creerSignaleur({ diffuser, seq });
  const minuterie = setInterval(() => { if (nbClients() > 0) diffuser('vie', { seq: seq(), at: Date.now() }); }, vieMs); // garde:vie-battement
  minuterie.unref?.();
  const retirer = surInstantane((inst) => { signaleur.signaler('etat', '', sigState(inst && inst.signal)); });
  return { stop() { clearInterval(minuterie); retirer(); } };
}
