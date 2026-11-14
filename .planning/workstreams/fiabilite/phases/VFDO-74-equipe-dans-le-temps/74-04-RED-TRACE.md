# 74-04 : trace du rouge (base d4c0c655, aucun module ui/74-vf-frise.js ni -colonne, -pistes, -source, -style)

Commande : `VF_CDP_ECHEANCE_MS=8000 bash plugin/cockpit/scripts/tests/test-cockpit-frise-vue.sh` (185 s). Résultat : 3 réussis, 34 échecs.

| Section | Verdict | Raison |
|---|---|---|
| S0 | PASS | les scénarios passent `node --check` ; le serveur de la suite démarre (témoins positifs) |
| S1 | FAIL | aucun `[role=tablist]` dans `section#vf-equipe` (la régie n'en dessine qu'avec deux vues), `declarer` jamais appelé, position « Frise » absente |
| S2 à S12, S14 à S19 | FAIL | « section interrompue » : la position « Frise » n'existe pas dans la bascule de la régie (attente bornée dépassée) |
| S13 | FAIL | les cinq modules sont absents ou vides |
| mutants (12) | FAIL | motif absent : le fichier à muter n'existe pas dans la copie du module |

La ligne « S1 aucun fichier du lab modifié » est verte sur la base (rien n'écrit) : ce n'est pas une sonde de section.
