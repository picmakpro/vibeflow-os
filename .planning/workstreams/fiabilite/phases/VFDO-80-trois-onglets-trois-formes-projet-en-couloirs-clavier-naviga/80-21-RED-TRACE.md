# 80-21 — trace du rouge (P80-D-25, régime allégé)

Suite `test-cockpit-echec-onglet.sh` jouée sur la tête `bfd5f5359` (80-10 et 80-14 faits, rien de 80-21), un vrai Chrome :
`2 PASS / 15 FAIL`. Le seul vert est le démarrage du serveur (EC0) et l'hygiène (H0).

| Cas | Rouge observé | Cause attendue |
|-----|---------------|----------------|
| EC1.1, EC1.2, EC1.2b, EC1.3, EC1.4, EC3.1, EC3.1b | section `ec1` du pilote en erreur | `VF_ONGLETS.echec` n'existe pas (la lecture d'état du pilote lève) |
| EC2.2 | `Cannot read properties of undefined (reading 'un')` | `00-vf-onglets-echec.js` absent |
| EC2.1, EC2.1b (projet, code, equipe) | sections `ec21-*` en erreur | `VF_ONGLETS.echec` absent ; aucune boîte `#vf-onglets-echec` (le repli de la coquille seul s'afficherait) |
| EC9 | `ec1, ec14, ec22, ec21-projet, ec21-code, ec21-equipe` | les mêmes sections |

Taille de `00-vf-onglets.js` avant le plan : 140 lignes.
Mutants : levés (régime allégé, ce plan n'est pas une garde) ; M-PREVENT-OMIS, M-ECHEC-SILENCE, M-PERSISTANT-ECHEC, M-PALETTE-FIXE et
M-RANGEE-FIXE ne sont pas joués.
