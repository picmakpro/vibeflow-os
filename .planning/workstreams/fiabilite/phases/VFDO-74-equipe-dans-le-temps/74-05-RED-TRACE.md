# 74-05 : trace du rouge (base, aucune fiche)

Suite : `plugin/cockpit/scripts/tests/test-cockpit-fiche.sh` jouée sur la base (tête 0aa1bd7a plus les modules de la 74 déjà livrés), 42 s, exit 1.

| Section | Raison du rouge |
|---|---|
| P1, P2, P3 (cinq blocs), P4, P5 (quatre blocs), P6, P7, P8 (deux blocs), P9, P10, P11, P13, P14, P16, P17, P18 | `window.__vfFiche absent` : la page, le serveur, la régie, `who` et les routes remplacées sont montés (témoin positif : le serveur répond, la régie monte), seule la fiche manque |
| P15 | écouteurs Échap, `vf-agent:ouvrir` et abonnement `frise` à 0 au lieu de 1 ; puis `fiche posée` jamais atteinte |
| P12 | les trois modules `74-vf-fiche*.js` sont absents ou vides |

Constat sans le tester comme un retrait : la boîte de 320 px et « Lire le transcript » existent encore (retraits aux plans 74-08 et 74-10).
Le plan n'étant pas marqué audit, aucun mutant n'est joué (régime allégé de la session principale).
