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

## Vert (après le code)

`claude plugin test plugin` : 54 pass / 0 fail (sortie `68-07-test.out` du scratchpad). Q1, Q2, Q3, A1, A2, A3 lus par `verdict.sh ... succes` : tous `ok` ; A1 et Q1 lus `echec` sur la sortie d'avant le code : `ok` (rouge établi).
Passages intermédiaires : A1b rouge au premier vert (le plugin n'est pas testé par `fs.exists` : repli sans test d'existence, voir SUMMARY) ; A2 rouge (`cockpit : {url}` en JSX scinde le texte en deux enfants, corrigé en gabarit) ; A2d en boucle refusé par le harnais (un `lab()` par test).

## Mutants (chacun rougit sur l'assertion visée ; sorties `68-07-mut-*.out`)

| Mutant | Rouge |
|--------|-------|
| M1 gestes offerts à tout travailleur non terminé (plus de test d'appartenance à la liste de la session) | Q1, Q1b |
| M2 plus de filtre des terminés en compact | Q2 |
| M3 enfant écrit à la profondeur du parent | Q3 |
| M4 adresse prise par `https?://\S+` | A2b |
| M5 ordre des candidats : compte avant projet | A1d |
| M6 délai 15 000 ms au lieu de 60 000 | A1 |
| M7 code 2 retiré de la table | A2c |
| M8 `void ouvrir()` au rendu du bouton | A3 (et A1, A1b, A1c, A1d, A2) |
| M8-statique : `void ouvrir()` dans boutons.tsx / `ouvrirCockpit(` dans pane.tsx / `$.session.send` dans pane.tsx | M8.3 / M8.1 / M8.6 de `test-cockpit-signal-mod.sh` |

Un premier M3 (réécriture de la boucle des enfants) ne compilait pas : tous les tests rouges, mutant écarté et rejoué (`marche(c, depth)`).
