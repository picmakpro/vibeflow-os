# 74-06 : trace du rouge (suite écrite avant les modules, base `ded6c343`)

`bash plugin/cockpit/scripts/tests/test-cockpit-frise-curseur.sh` sur la base, sans aucun des quatre modules (321 s) :

- C10 (forme du code) : rouge, « module absent ou vide » pour les quatre.
- C1 : rouge (aucun `[role=slider]`, ← ne pose rien, Début, Échap, lecture Événements, calage sur silence).
- C2 : rouge (aucun trait de survol, clic et glisser sans effet, la colonne de gauche ouvre bien la fiche mais le test compte aussi le curseur nul).
- C3 : rouge (aucun trait de curseur), section interrompue ensuite.
- C4, C6, C6b, C7, C8, C8c, C9, C11 : rouge, section interrompue faute de repère ou d'encart (`.vf-encart-*` absent).
- C5 : rouge sur les cinq lignes de nœuds et la note « déduit des voies ».
- C8f : rouge (finirRelecture jamais appelée).
- C12 : rouge (aucun repère, aucun écouteur, aucune inscription `surOnglet` des quatre fichiers).

Sondes vertes à vide sur la base, notées pour ne pas les compter comme témoin : « → sans curseur ne change rien », « Fin revient à maintenant »,
« sans `noeuds` : aucune ligne de bilan », « chargement : aucune lecture de VF_MARQUES » (absence de module = absence de lecture), « la fixture a un repère de silence ».
Elles gardent un sens une fois les modules posés (le témoin d'une pose précède chacune dans la même section).
