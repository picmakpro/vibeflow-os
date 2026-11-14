// VibeFlow (79-18, SOCL-22) : le fil de calcul de la mise en page du canevas. Un script classique de worker, servi par le module sous /_vf/.
// Il importe le seul paquet de mise en page du module (chemin relatif, même dossier servi) et répond au protocole fermé de la page :
//   requête { id: entier >= 0, graphe: objet }  ->  réponse { id, resultat } ou { id, erreur } (texte de 200 caractères au plus).
// Tout autre message est ignoré. Ni réseau, ni évaluation dynamique, ni autre import : la politique de contenu de sa réponse le garantit.
// L'échec de l'import n'est pas capturé : l'évènement d'erreur du worker est le signal du repli en ligne côté page.
// Le paquet, chargé dans un worker (aucun `document`), pose lui-même son calcul sur `self.onmessage` au moment où `new ELK()` le requiert,
// puis échoue faute de fil à fabriquer : l'échec attendu est ignoré, l'effet voulu est vérifié.
// Ce calcul parle le protocole interne du paquet ; il est enveloppé ici.
importScripts('vendor/elk.bundled.js');
try { new self.ELK(); } catch (e) { /* attendu : seul l'effet compte */ }
const calcul = self.onmessage;
if (typeof calcul !== 'function') throw new Error('mise en page : le calcul du paquet est introuvable');
const poste = self.postMessage.bind(self);
self.postMessage = (r) => { // les réponses internes du paquet, traduites dans le protocole de la page
  if (!r || !Number.isInteger(r.id) || r.id < 0) return;
  if (r.error) poste({ id: r.id, erreur: String((r.error && r.error.message) || r.error).slice(0, 200) });
  else poste({ id: r.id, resultat: r.data });
};
const ALGOS = ['layered', 'stress', 'mrtree', 'radial', 'force', 'disco', 'sporeOverlap', 'sporeCompaction', 'rectpacking'];
calcul({ data: { id: -1, cmd: 'register', algorithms: ALGOS } });
self.onmessage = (e) => {
  const m = e.data;
  if (!m || typeof m !== 'object' || !Number.isInteger(m.id) || m.id < 0) return;
  if (!m.graphe || typeof m.graphe !== 'object' || Array.isArray(m.graphe)) return;
  calcul({ data: { id: m.id, cmd: 'layout', graph: m.graphe, layoutOptions: {}, options: {} } }); // garde:mep-calcul
};
