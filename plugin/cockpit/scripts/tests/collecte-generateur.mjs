// collecte-generateur — générateur à graine et fabriques de valeurs hostiles des propriétés de la collecte (79-09, tâche 3). Sans dépendance.
// Exports : rng(graine) -> { n(max), pick(liste), bool(p), chaine(n) } (mulberry32, déterministe), graineDe(argv, env) -> entier (--graine=N, puis VF_SEED, sinon l'horloge),
//           hostiles(rng) -> { classe -> valeur } (valeurs de toute forme qu'un script de verrou ou un fichier du lab pourrait rendre).
// Rien ici n'importe le code testé : une fixture ne dépend pas de ce qu'elle sert à prouver.
export function rng(graine) {
  let a = graine >>> 0;
  const suiv = () => { a = (a + 0x6d2b79f5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
  return {
    n: (max) => Math.floor(suiv() * max),
    pick(l) { return l[Math.floor(suiv() * l.length)]; },
    bool: (p = 0.5) => suiv() < p,
    chaine(n) { const A = 'abcdefghijklmnopqrstuvwxyz0123456789'; let s = ''; for (let i = 0; i < n; i++) s += A[Math.floor(suiv() * A.length)]; return s; },
  };
}

export function graineDe(argv, env = {}) {
  const a = argv.find((x) => x.startsWith('--graine='));
  const v = a ? Number(a.slice(9)) : Number(env.VF_SEED);
  return Number.isInteger(v) && v >= 0 ? v : (Date.now() % 2147483647);
}

// une valeur de chaque classe hostile : le marqueur (unique par classe) sert à prouver qu'il ne ressort pas
export function hostiles(r) {
  const m = (k) => `MQ${k}${r.chaine(6)}`;
  return {
    'chemin': `/Users/${m('chemin')}/lab/.git/vf-driver/repo`,
    'prototype': { __proto__: null, constructor: m('proto'), toString: m('proto') },
    'objet-imbrique': { a: { b: { c: m('imbrique') } } },
    'tableau': [m('tableau'), { x: m('tableau') }],
    'geante': m('geante') + 'z'.repeat(5000),
    'controle': `${m('controle')}\u0000\u0007‮​`,
    'nombre-hostile': Number.NaN,
    'identifiant-hors-forme': `../${m('identifiant')} x`,
  };
}
