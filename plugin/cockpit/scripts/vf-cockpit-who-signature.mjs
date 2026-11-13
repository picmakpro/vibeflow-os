// vf-cockpit-who-signature — la signature de la liste « qui » (79-09, A17, P79-D-12). Pur, aucune lecture disque.
// Exports : whoSig(who) -> chaîne (JSON à clés triées de l'objet ENTIER moins les champs volatils, à toute profondeur),
//           CHAMPS_VOLATILS (la liste nommée de ces champs).
// Un champ ajouté au `who` est couvert sans retouche ; un champ qui varie sans que l'équipe ait changé (un âge, une durée, un horodatage de lecture)
// s'inscrit dans la liste, jamais dans une énumération de champs : la liste est la seule chose à tenir à jour.
export const CHAMPS_VOLATILS = Object.freeze(['at', 'ageS', 'dureeS', 'lastAt']); // garde:who-volatils

const ordonne = (v) => {
  if (Array.isArray(v)) return v.map(ordonne);
  if (!v || typeof v !== 'object') return v;
  return Object.fromEntries(Object.keys(v).filter((k) => !CHAMPS_VOLATILS.includes(k)).sort().map((k) => [k, ordonne(v[k])]));
};

export const whoSig = (who) => JSON.stringify(ordonne(who ?? {}));
