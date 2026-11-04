---
phase: 70-finitions-ui-cockpit
plan: 08
status: complete
requirements: [UIFN-05]
commits: [e58a9e8a, b83df5c9]
---

# 70-08 — visite propre à l'onglet Projet (UIFN-05)

## Livré

- `vf-cockpit-project.mjs` : le champ `tour` est construit depuis le graphe — (1) le jalon en cours (« Phases faites : n sur N »), (2) la phase en cours (statut par `statutLisible`), (3) la mission en cours (sinon la première), (4) « au travail » (racine, `cible: '#vf-lock'`, nomme l'onglet Équipe, P70-D-13). Une étape dont la carte manque est omise ; sous deux étapes, `tour` est vide et le repli du moteur s'applique. Aucun texte ne parle de code.
- `test-cockpit-projet.sh` : section O6 (O6.1 à O6.4 et O6.6 à O6.8 en CLI, O6.5 dans Chrome sur `project.html` à 1 440 et 390 px, mesures O5.1 à O5.5 reprises). Trace : `70-08-RED-TRACE.md`.
- Nœud « au travail » : le point est toujours cité ; l'onglet Équipe est nommé sans test d'existence (il est posé en dur par `00-vibeflow.js`).

## Écart à signaler au manager

Au rechargement d'une page déjà vue dans le même profil Chrome, le centrage de la première étape (une carte) dérive de ~85 px à 390 px (`40-tour.js`, interdit à ce plan). Avant 70-08 aucune première étape n'était une carte hors racine, donc l'écart n'apparaissait pas. La suite mesure chaque largeur dans un Chrome neuf. À traiter dans un plan qui touche `40-tour.js` (candidat : 70-07 en correctif ou plan dédié).

## Vérifications

`test-cockpit-projet.sh` 86/0, `test-cockpit-chrome-fr.sh` 0 FAIL, `test-cockpit-questions.sh` 65/0, `test-cockpit-avancement.sh` 61/0. G-2 : aucun chemin surveillé touché.

estimate/actuals : le PLAN porte un `estimate`, mais aucun `actuals` n'est rendu par un moteur ; aucun nombre inventé.
