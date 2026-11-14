// etat-leve.mjs — préchargement de test (node --import) : Object.fromEntries lève quand `assainir` de l'émetteur lui passe la valeur marqueur du leurre (79-12, E9.19).
// Seul l'appel dont la pile nomme `assainir` lève : la projection (`garder`) et la collecte locale de repli ne sont pas touchées. Sans cette levée, aucune
// forme d'entrée n'atteint `assainir` sans avoir franchi `borne` : le `try` de la CLI n'aurait pas de témoin.
const MARQUEUR = 'MARQUEUR-LEURRE-79-12';
const origine = Object.fromEntries;
Object.fromEntries = function (entrees) {
  if (Array.isArray(entrees) && entrees.some((e) => e && e[1] === MARQUEUR) && /\bassainir\b/.test(new Error().stack || '')) throw new Error('levée par la sonde');
  return origine.call(this, entrees);
};
