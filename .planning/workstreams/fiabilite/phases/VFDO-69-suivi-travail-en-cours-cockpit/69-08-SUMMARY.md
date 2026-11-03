---
phase: 69-suivi-travail-en-cours-cockpit
plan: 08
requirements: [CKPT-19, CKPT-20, CKPT-21, CKPT-22, CKPT-23, CKPT-26]
commits: [9061cde2, cdef292c]
---

# 69-08 — rendu de l'équipe dans l'interface

## Livré
- `71-vf-equipe-rendu.js` (neuf, ligne `AJOUT` de `VENDORED.txt`) : `window.__vfEquipeRendu = { arbre, agentsDuNoeud, transcript, pied, duree }`. Arbre session -> manager -> workers, terminés repliés dans `details.vf-termines` fermé, liens agent -> nœud et « non rattaché (raison) », pied d'action en texte brut, transcript par `createElement` + `textContent`.
- `70-vf-live.js` : le tiroir « Au travail » rend l'arbre à la place de la liste plate (retrait de `age`, remplacé par `duree`) ; lignes verrou, nœud de DAG et registre sous « Verrous et nœuds » ; N et badge = agents `actif` non périmés ; section « Agents sur ce nœud » dans l'onglet Projet ; classes `vf-arbre-enfants`, `vf-termines`, `vf-pied`, `vf-transcript`.
- `72-vf-equipe.js` : pied sur les cartes, panneau d'agent (état, durée, dernière action, nœud, « Voir la dernière commande », « Lire le transcript »), requête `/api/vf/transcript` avec `x-floorplan-token`, réponse jamais conservée (le DOM du transcript lu passe d'un panneau à l'autre au redessin), `hashchange` pour les liens internes à la page.

## Témoins
EUI.1 à 7, E23.7, T26.1 à 4 verts ; T26.7 jouée dans Chrome et verte (la route de 69-07 était présente). W16 jouée dans Chrome (non sautée), verte.

## Écarts au plan
- Le conteneur `.vf-transcript` n'est pas posé caché dans le panneau : T26.7 l'attend absent avant le clic (`if (!document.querySelector('.vf-transcript'))` clique alors le bouton). Il est créé au clic, après son bouton.
- Libellés : la sonde E23.7 juge anglais « Session », « Mandat », « en attente », « {} min » dans un fichier neuf (liste `CONNU` du test limitée à 70 et 00). Les mots sont écrits en minuscules et mis en capitale à l'affichage (`cap`), l'unité de durée assemblée sans gabarit. Plus propre : déclarer ces littéraux dans `CONNU` pour 71 (suite hors périmètre).
- En-tête du jeton : `x-floorplan-token` (celui que le serveur lit), pas `x-vf-cockpit-token`.

estimate: tokens 90000 / actuals non mesuré.

## Correction de revue

Mandat de correction ciblée (revue de l'onglet Équipe sur 945613b6, F1 à F6 ; F7 renvoyé par P69-D-28).

- **F1** (`72-vf-equipe.js`) : `dansCarte()` exclut les cartes-blocs `<carte>~termines`, qui ne sont pas des agents. Rouge avant : un agent actif et un terminé donnaient 1 rechargement au premier `vf-who` (attendu 0). Témoins : EUI2.10 (0 rechargement, 1 rendu), EUI2.12 (borne : 1, 1, 2 rechargements autour de l'échéance de 15 s). Mutants : EUI2.11 (bloc compté) et EUI2.13 (`PAUSE_MS = 0`).
- **F2** (`72-vf-equipe.js`, pas de patch du viewer vendu) : l'arrivée sur `#r=n:<carte>` est traitée après le premier rendu qui aboutit (`arrivee()`, une fois par page), ce qui couvre le cas où `ready` n'est jamais émis ; si `ready` a eu lieu, `00-vibeflow.js` l'a traitée et 72 ne la rejoue pas. Témoins : EUI2.14, EUI2.15 (vm, ordre forcé), T26.8 (Chrome, `state.selected`). Mutant : EUI2.16. Limite : en Chrome l'ordre de livraison du flux n'est pas pilotable, T26.8 ne rougit pas sur un 72 sans `arrivee()` (00 traite l'arrivée quand `ready` a lieu) ; la preuve de l'ordre défavorable est EUI2.14/16.
- **F3** (`test-cockpit-transcript.sh`) : T24F1.* ne couvrait que le message coupé et le mandat. Ajouts : T24F3.0 à T24F3.4 (message, cible d'outil, nom d'outil ; trois mutants) et T25.9b (la route, agent `xsec`, 3 masques).
- **F4, F5b** (`71-vf-equipe-rendu.js`) : témoins EUI2.1 à EUI2.9 (id, rôle, branche, cible, raison, tâche piégés dans l'arbre, le pied, la liste d'un nœud et le panneau de 72 ; un agent non rattaché n'a jamais de lien). `versNoeud()` est désormais unique (arbre et panneau). Mutants : EUI2.2 à EUI2.7, EUI2.9.
- **F5a** (`70-vf-live.js`) : EUI2.17 (un actif, un terminé, un en attente : « 1 au travail », « Au travail (1) »), mutant EUI2.18.
- **F6** : les libellés sont écrits tels qu'affichés ; les huit littéraux français de 71 que la sonde prend pour de l'anglais sont déclarés dans `CONNU` (rien d'autre) ; EUI2.19 prouve que la sonde voit encore un libellé anglais ajouté à 71.
- Note de harnais : sous Chrome le viewer est exposé en `window.VibeFlow` (le `Floorplan` des sources est renommé à l'assemblage).
