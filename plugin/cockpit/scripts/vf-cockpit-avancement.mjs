// vf-cockpit-avancement — avancement d'une phase, calculé en bibliothèque du socle (CKPT-13 à CKPT-17 ; P69-D-01 à P69-D-09).
// Exports : decompte, avancement (la tâche suivante ajoute ETATS, RESTE, libellés, rattachement des missions, reste).
// Module pur : ne lit que ce qu'on lui passe, aucune lecture réseau, aucun nom de lab codé en dur.

// Un plan est fait s'il a son *-PLAN.md ET son *-SUMMARY.md ; un SUMMARY sans PLAN est un correctif (P69-D-04).
// `fichiers` = noms de fichiers du dossier de phase. Rend { faits, total, correctifs }.
export function decompte(fichiers) {
  const plans = new Set(), sommes = new Set();
  for (const f of fichiers || []) {
    if (f.endsWith('-PLAN.md')) plans.add(f.slice(0, -'-PLAN.md'.length));
    else if (f.endsWith('-SUMMARY.md')) sommes.add(f.slice(0, -'-SUMMARY.md'.length));
  }
  let faits = 0, correctifs = 0;
  for (const p of plans) if (sommes.has(p)) faits++;
  for (const s of sommes) if (!plans.has(s)) correctifs++;
  return { faits, total: plans.size, correctifs };
}

// Objet versionné posé par readPlanning sur chaque phase (contrat figé en version 1 : ajouts de champs seulement).
export function avancement({ fichiers } = {}) {
  const { faits, total, correctifs } = decompte(fichiers);
  return { version: 1, plans: { faits, total }, correctifs };
}
