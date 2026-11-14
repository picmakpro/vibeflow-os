// donnees.mjs — les données de route que les mesures poussent à la page (forme de GET /api/vf/activite, 75-05) pour les fichiers du lab de mk-lab.sh.
const p2 = (i) => String(i).padStart(2, '0');
export const A = (i) => `src/a/m${p2(i)}.js`;
export const B = (i) => `src/b/n${p2(i)}.js`;
export const PREVUE = 'src/a/neuf.mjs';
export const HOSTILE = '<img src=x onerror=window.__xss=1>"\'</script>  __proto__';
const palier = (i) => (i >= 10 ? 3 : i >= 5 ? 2 : 1);
export const donnees = (o = {}) => ({
  schema: 'vibeflow/cockpit-activite@1', at: '2026-11-14T00:00:00.000Z', etat: 'ok', calcul: 'pret',
  git: { etat: 'ok', fenetre: { jours: 90, commits: 70, plafond: 5000, plafondAtteint: false, partiel: false },
    chauds: Array.from({ length: 14 }, (_, k) => [A(14 - k), 14 - k, (14 - k) + 9, k + 1, palier(14 - k)]),
    couplage: [[A(1), A(2), 6, 100], [A(1), A(3), 5, 78], [A(2), A(3), 5, 55]], paliers: 3, tronque: false },
  branches: { etat: 'ok', tetes: 2, plafond: 12, plafondAtteint: false },
  gardes: { etat: 'ok', gardes: [...Array.from({ length: 14 }, (_, k) => [A(k + 1), k < 2 ? 2 : 0, 0]), ['scripts/check-lab.sh', 0, 1]], estGarde: ['scripts/check-lab.sh'], prevusIgnores: 1, tronque: false },
  empreinte: { etat: 'ok', incomplet: false, limite: ['ecritures-par-commande-non-vues'], horsCarte: 1, horsLab: 2, coupees: 0, rejetes: 0, ignorees: 0, voiesTronquees: false,
    marques: [[A(1), 'en-cours', ['vf-coder · nœud 75-08']], [A(2), 'modifie', ['vf-coder · nœud 75-08', 'vf-reviewer · non rattaché', 'vf-auditer · non rattaché']],
      [A(3), 'lu', ['vf-coder · nœud 80-01']], [A(4), 'fini', ['vf-coder · nœud 80-01']]] },
  collisions: [[A(5), 'agents', ['vf-coder · phase-75', 'vf-coder · phase-76'], null], [A(5), 'branches', ['feat/a', 'feat/b'], null], [A(6), 'arbres', ['phase-75', 'phase-76'], null],
    [PREVUE, 'plans', ['75-02', '75-04'], 3]],
  radar: { incomplet: false, raisons: [], total: 3, tronque: false, sansVague: 0, plansTronques: false, limites: ['plans-comparaison-textuelle'] }, ...o,
});
// un état dérivé : seul le champ donné change
export const avec = (champ, valeur, o = {}) => { const d = donnees(o); d[champ] = typeof valeur === 'function' ? valeur(d[champ]) : valeur; return d; };
