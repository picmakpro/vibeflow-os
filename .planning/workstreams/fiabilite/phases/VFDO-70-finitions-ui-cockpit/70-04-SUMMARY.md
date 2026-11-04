# 70-04 — résumé

UIFN-01 (en-tête mobile) et UIFN-09 (onglets) livrés. Commits : `79c5bb1d` (témoins R13 à R16 rouges), `3316a8da` (mesures du recalcul), `03317053` (partie ≤ 700 px), puis la suite de l'arbitrage 1 024 px (voir `git log`).

- **≤ 700 px (P70-D-01)** : en-tête sur une rangée (logo, onglets, recherche, point « au travail », « ⋯ »), menu à libellés, pastille du « ⋯ » réduite à un point (Q8), thème abrégé à son état (Q11), zoom hors de l'en-tête (au-dessus de la barre de question et de la visite), Détail masqué. Hauteur d'en-tête à 390 px : 148 px sur Code et 100 px sur Projet et Équipe avant (3 et 2 rangées) ; une rangée après.
- **Onglets (P70-D-16)** : 13 px, piste 3 px, padding 13 px au-dessus de 700 px (8 px à ≤ 700 px) ; règle de resserrement de 69-05 retirée.
- **Borne (P70-D-22)** : `header .hl` 280 -> 342 px, calculée (84 + 4 + 14 + 200 + 4 + 36), mesurée à 1 024 px jusqu'à 380 px ; R4.2 mutant à 400 px. Badge « au travail » réduit à son point de 701 à 1 599 px (écart : l'arbitrage disait 701-1 279 ; nécessaire à 1 440 px pour O2b.6).
- Tests : R13 à R16 (+ lab « trait » pour R16), `test-cockpit-responsive.sh` 261 PASS / 0 FAIL, vendor et marque blanche verts.
- Reste (70-05, fait en parallèle) : poignée et croix du tiroir, nom accessible du zoom, titre coupé.
- Limite : R3 à 390 px sur Projet a rougi par intermittence sous charge (visite d'office) ; traité côté zoom, à surveiller.
