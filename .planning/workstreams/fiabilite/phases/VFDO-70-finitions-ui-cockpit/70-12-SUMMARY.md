---
phase: 70-finitions-ui-cockpit
plan: 12
requirements: [UIFN-14]
commits: [c555f584, c8f1d90d]
---

# 70-12 SUMMARY — onglet Équipe : zoom, titre, matrice responsive (UIFN-14)

Témoins R17 à R20 joués rouges sur le code d'avant (7 FAIL propres au plan), puis verts après le correctif ; trace dans `70-12-RED-TRACE.md`.

- **Zoom (défaut D, P70-D-20 : choix du manager, vf-dev-manager, 2026-11-04, pas un arbitrage de Samuel)** : dès 701 px l'onglet Équipe remet le zoom en rangée en bas à gauche (x=16, 16 px au-dessus du bas). Avant : colonne à x=308, y=108 (52x144) à 768 px et x=574, y=72 (42x114) à 1 024 px, par-dessus les cartes (une carte recouverte à 768 px). Code et Projet inchangés (R17.2).
- **Titre (défaut E)** : cause relevée par sonde, le premier rendu du viewer (celui qui appelle `fit()`) est annulé par le `rerender()` de `72-vf-equipe.js` ; la scène gardait sa transformation d'origine. `fit(false)` est appelé une fois à l'arrivée. Aire titre / première carte : 22 752 (390 px), 17 408 (768 px), 26 100 (1 024 et 1 440 px) px², puis 0 partout.
- **Fil d'Ariane / recherche (R18)** : non reproduit, témoin négatif. À 1 024 px, lab au nom long, Équipe et Projet : fil en x=265 (31 px), recherche en x=308, recouvrement 0. Aucun correctif.
- **Page Équipe dans la matrice (R20)** : 390, 768, 1 024 et 1 440 px, aucune superposition, aucun défilement horizontal (vert dès le départ, gardé).
- R19.2 (titre après ouverture d'une session) vert dès le départ : l'ouverture passe par `render()` qui cadre. Gardé.
- Suites : responsive 255 PASS / 6 FAIL (les six R13.4 de 70-04, arbitrage en attente), équipe 134/0, marque blanche 30/0, vendor 78/0.
- Écart au plan : `SC.fit?.(false)` (et non `SC.fit(false)`) pour que le harnais hors navigateur de `test-cockpit-equipe.sh` reste vert sans éditer cette suite.
