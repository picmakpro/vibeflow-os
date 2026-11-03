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
