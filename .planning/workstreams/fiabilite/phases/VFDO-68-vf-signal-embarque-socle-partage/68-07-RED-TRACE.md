# 68-07 — Trace du rouge (VFSG-04, VFSG-10 ; P68-D-03, P68-D-17, P68-D-19)

Claude Code 2.1.318. Commande : `claude plugin test plugin`, avant tout code (branche `feat/phase-68-w07`, partie de `523921fe`).
Résultat : 35 pass / 16 fail (les 35 sont les tests de 68-04 à 68-06 et E1..E4b, inchangés ; les 16 fail sont les témoins neufs sauf A3).

## Équipe (`tests/equipe.test.tsx`)

| Test | Assertion | Attendu | Obtenu (avant le code) |
|------|-----------|---------|------------------------|
| Q1 | `find Text /plan autre-session/` (agent `x9`, sous-agent d'une autre session, rôle `vf-coder`) | défini | `undefined` : la vue lit `$.agent.list()`, `x9` n'y est pas |
| Q1b | `find Text /audit perdu/` (orphelin du registre, `orphan: true`) | défini | `undefined` |
| Q1c | `find Text /plan 68-07/` avec `equipe.workers` vide et `c1` dans `$.agent.list()` | `undefined` | le Text `↳ vf-coder · plan 68-07` : l'arbre vient encore de `$.agent.list` |
| Q2 | `find Text /revue finie/` en dock (agent `termine`) | défini | `undefined` |
| Q3 | `find Text /↳ .* vf-coder/` (enfant `c1` de `m1`, `$.agent.list` vide) | défini | `undefined` |

La première version de Q3 passait par accident (la liste de la session portait aussi `c1`) : le témoin a été réécrit sans `$.agent.list` pour rougir pour la bonne raison.

## Bouton « Ouvrir le cockpit » (`tests/actions.test.tsx`)

| Test | Assertion | Attendu | Obtenu (avant le code) |
|------|-----------|---------|------------------------|
| A1, A1b, A1c, A1d, A2, A2b, A2c, A2d, A2e, A2f | `press({ key: 'ouvrir-cockpit' })` | bouton dessiné | `HooksError: press: no Button of vibeflow keyed "ouvrir-cockpit" is drawn in this Pane` |
| A3 | session entière sans appui : `sp.emetteur.length > 0` et `sp.lanceur.length === 0` | vert | vert (garde : aucun lanceur aujourd'hui ; le témoin positif prouve que l'espion n'est pas muet) |

A3 a d'abord échoué pour une panne de harnais (pas de `on('ui.render')` pour le bandeau, et l'onglet courant n'a pas de bouton à presser), corrigée avant la trace.
