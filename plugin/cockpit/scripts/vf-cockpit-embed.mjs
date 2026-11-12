// vf-cockpit-embed — lecture et écriture de la zone de données d'une page du cockpit (P67-D-12).
// La page porte son graphe dans `<script>window.<GLOBALE> = {…};</script>` ; le nom de la globale est son nom VibeFlow : la page du
// moteur est renommée AVANT l'insertion des données (vf-cockpit-rename.mjs, renommerPageMoteur), jamais après.
// Exports : DATA_START, decouper(html, debut = DATA_START) -> { avant, donnees, apres }, extraireGraphe(html), insererGraphe(html, data).
// Chaque `<` du JSON devient `\u003c` (valide en JSON et en JS ; ferme `</script` ET `<!--`, qui ouvre l'état « double escaped » du parseur) ; U+2028 et U+2029 aussi, écrits en ASCII dans ce source.
export const DATA_START = '<script>window.VF_COCKPIT = ';
const DATA_END = ';</script>';

export function decouper(html, debut = DATA_START) {
  const a = html.indexOf(debut);
  if (a < 0) throw new Error('zone de données introuvable : marqueur de début absent');
  const b = html.indexOf(DATA_END, a);
  if (b < 0) throw new Error('zone de données introuvable : marqueur de fin absent');
  return { avant: html.slice(0, a + debut.length), donnees: html.slice(a + debut.length, b), apres: html.slice(b) };
}

export const extraireGraphe = (html) => JSON.parse(decouper(html).donnees);

export function insererGraphe(html, data) {
  const { avant, apres } = decouper(html);
  const json = JSON.stringify(data).replace(/</g, '\\u003c').replace(/\u2028/g, '\\u2028').replace(/\u2029/g, '\\u2029');
  return avant + json + apres;
}
