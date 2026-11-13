// etat-live-double.mjs — direct factice de test-cockpit-etat.sh (79-12) : le harnais l'écrit dans la COPIE du module à la place de vf-cockpit-live.mjs.
// Même interface que startLive. L'état vit dans globalThis.__ETAT_DOUBLE, que le harnais lit et fixe : `collecte`, `seq`, `absent` (le direct ne démarre
// pas), `appels` (chaque appel compté : etat, reveil, pret) et `emettre(nom, data)` (un événement par le rappel `onEvent` du serveur).
const D = (globalThis.__ETAT_DOUBLE ||= {
  collecte: { etat: 'ok', derniereA: '2026-01-01T00:00:00.000Z', dureeMs: 5, mode: 'watch', clients: 0 }, seq: 0, absent: false, emettre: null, appels: { etat: 0, reveil: 0, pret: 0 },
});
export function startLive({ onEvent, nbClients = () => 0 }) {
  if (D.absent) throw new Error('direct absent');
  D.emettre = (nom, data) => onEvent(nom, data);
  return {
    etat: () => { D.appels.etat++; return { mode: D.collecte.mode, seq: D.seq, derniereMaj: null, collecte: { ...D.collecte, clients: nbClients() } }; },
    snapshot: () => ({ seq: D.seq, lock: { seq: 0, at: 1, verrous: { etat: 'absente', plat: false, liste: [] } }, who: { workers: [], sources: {} } }),
    reveil: () => { D.appels.reveil++; },
    pret: () => { D.appels.pret++; return Promise.resolve(true); },
    stop: () => {},
  };
}
