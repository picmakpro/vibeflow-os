// vf-cockpit-instantane — le dernier instantané de la collecte, lu en mémoire (79-09, A31, A47).
// Exports : instantane() -> objet profondément gelé { seq, at, git, projet, … } ou null avant la première pose ; surInstantane(rappel) -> désinscription ;
//           poser(instantane) -> l'objet posé, RÉSERVÉ au pilote de la collecte (le direct) : une route lit, elle ne pose jamais.
// Contenu : `seq` (entier, seul champ exigé), `at`, `git` ({ sig, at } ou null : la signature que le direct calcule déjà, A47), `projet` (graphe
// Projet) ; les phases suivantes y ajoutent leurs champs. Une lecture ne déclenche JAMAIS de collecte ni de lecture du lab : ce module n'importe
// rien de la collecte. Jamais exporté : le curseur de l'index, le payload brut du verrou, un champ que la garde d'émission refuse (la garde
// s'applique avant la pose).
let courant = null;
const rappels = new Set(), gelesProfond = new WeakSet();

// gel profond itératif (jamais récursif : un graphe profond ne fait pas déborder la pile) ; un objet déjà gelé en profondeur n'est pas reparcouru
function geler(racine) {
  const vus = new Set(), pile = [racine];
  while (pile.length) {
    const o = pile.pop();
    if (!o || typeof o !== 'object' || vus.has(o) || gelesProfond.has(o)) continue;
    vus.add(o);
    Object.freeze(o); // garde:instantane-gel
    for (const v of Object.values(o)) pile.push(v);
  }
  for (const o of vus) gelesProfond.add(o);
  return racine;
}

export const instantane = () => courant;

export function surInstantane(rappel) {
  if (typeof rappel !== 'function') throw new TypeError('surInstantane : un rappel est attendu');
  rappels.add(rappel);
  return () => { rappels.delete(rappel); };
}

export function poser(inst) {
  if (!inst || typeof inst !== 'object' || !Number.isInteger(inst.seq)) throw new TypeError('poser : un objet portant un seq entier est attendu');
  courant = geler(inst);
  for (const f of [...rappels]) { try { f(courant); } catch { /* un rappel qui lève n'arrête ni la pose ni les autres rappels */ } }
  return courant;
}
