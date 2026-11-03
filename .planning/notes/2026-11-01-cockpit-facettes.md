# Cockpit floorplan — facettes tranchées avant la vraie phase

**Date** : 2026-11-01 · **Origine** : `/gsd-explore` après les spikes 002 à 006 (branche
`docs/etude-floorplan`) · **Entrée du cadrage** de la première phase du jalon `vibeflow-v2.0`.
Savoir technique : skill local `spike-findings-vibeflow-os` (cinq références) et
`.planning/spikes/WRAP-UP-SUMMARY.md`.

## Arbitrages (Samuel, AskUserQuestion session principale, 2026-11-01)

1. **Lignée** : le cockpit floorplan **remplace le module `vf-cockpit`** (page Mermaid, branche
   `feat/vf-cockpit-module`, jamais mergée) ; le mod **`vf-signal` reste** le panneau compact
   dans Claude Code. Les deux affichages partagent **un socle** : le collecteur « qui est au
   travail » (spike 004) et le graphe Projet (spike 002).
2. **Public** : **tous les labs**, module distribué et toggable, **onglet Projet au cœur**
   (marche partout où il y a un `.planning/` GSD). L'onglet Code est riche sur vibeflow-os
   (extracteur VibeFlow) et retombe sur le scan brut de floorplan ailleurs ; l'enrichir par stack
   est une suite, pas cette phase.
3. **Garde-fous par défaut** : **agent des questions actif** (les formes courantes restent
   locales et gratuites ; `claude -p` pour le raisonnement, modèle réglable) ; **dernière commande
   des sessions masquée** dans le panneau « Au travail » (qui et sur quelle tâche, jamais la
   commande), révélée sur demande, **jamais exportée**.
4. **Feuille de route** : **créer le jalon `vibeflow-v2.0`** avec le cockpit en tête : socle
   partagé puis cockpit floorplan ; `vf-signal` s'embarque ensuite sur le même socle.
   `equipe-produit-v1.0` (phases 63-66) reste ouvert, son sort se tranche à sa clôture. Le numéro
   36 reste réservé (dossier orphelin). La réponse initiale « go » a été reclarifiée par une
   seconde question avant d'être retenue.

## Choix de la session (défauts évidents, non arbitrés)

- **Un seul serveur** : le direct (`live.mjs`, spike 003) rejoint le serveur floorplan patché
  (P7, spike 005) ; plus de second port ni de CORS.
- **Ouverture** par un verbe du module, et un bouton « Ouvrir le cockpit » dans `vf-signal`.
- **Socle d'abord** dans l'ordre des plans : les deux affichages en dépendent.

## Préalables avant le cadrage

- Commiter le dossier du spike 002 (P6, P7, P8, `70-vf-live.js`, `80-vf-fr.js`, générateur,
  assemblage) : les spikes 003 à 006 en dépendent (todo `commiter-le-spike-002`).
- Correctif d'écriture atomique de `dag.sh` à faire valider (todo `dag-sh-ecriture-atomique`).
- Retrait du module `vf-cockpit` à la livraison (SEED-004).

## Limites connues à porter au cadrage

- Transcripts et `meta.json` des sous-agents : format interne de Claude Code, test de forme requis.
- `fs.watch` récursif prouvé sur macOS seulement (Linux, Windows à mesurer).
- Copie figée de floorplan : 8 patchs (P1-P8) à reporter à chaque synchro amont ; P1-P4, P6 et P8
  sont des crochets génériques, candidats à une PR amont. Licence MIT, ≈ 3,6 Mo dont ELK 1,5 Mo.
- Traduction du chrome : 97 des 258 chaînes au dictionnaire, il faut un test qui rougit sur
  l'anglais visible ; en-tête chargé sous ≈ 1 400 px.
- Réponses « en cours » à croiser avec le collecteur (zombies, ex. mission 18).
