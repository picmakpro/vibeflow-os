base: 17dad7323a9f98b7970dea32b6eb0fa733298301

# 73-06 — trace du rouge (régime allégé)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-regie.sh RG0_ordre_titre RG11_lu RG12_titre`, sur la tête de départ, sans `90-vf-titre.js`. Chrome présent : les témoins navigateur ont tourné (aucun « NON VÉRIFIÉ »).
Verdict : 5 PASS / 13 FAIL, exit 1.

## Rouges (chacun avec sa ligne `❌ FAIL — <id> —`)

| id | obtenu | motif |
|----|--------|-------|
| RG0.13 | `90-vf-titre.js ×0` sur index.html et project.html | repère absent |
| RG12.1 | `false\|false\|false` | titres « Équipe · nom », « Projet · nom », « Code · nom » : aucun préfixe |
| RG12.2 (survie) | `0\|false` | rien à faire survivre |
| RG12.2 (onglets) | `true\|false\|true\|true` | pas de préfixe sur Projet ; comptes d'abonnés égaux (aucun compositeur) |
| RG12.3 | `false\|true\|true\|false\|true` | pas de « (1) vous attend » ; le titre reste « x map » à zéro |
| RG12.4 | `false\|true\|true\|0\|0` | l'icône ne change pas |
| RG12.6 | `00-vibeflow.js,76-vf-git-entete.js` | deux écrivains du titre hors compositeur |
| RG12.7 | `fichier absent` | compositeur absent |
| RG11.11 | `0\|false\|\|false\|1\|1\|false` | rien n'est écrit au clic, la ligne reste à relire |
| RG11.12 | `false\|true\|true\|true\|true` | aucune purge : tout est resté |
| RG11.15 | `-\|null\|\|true` | pas de bouton « Tout marquer comme relu » |
| M-TITRE-SANS-WHO, M-TITRE-NETTOIE | ancre absente | le mutant n'a rien à muter sans le fichier |

## Gardes vertes dès la base (`✅ PASS — <id> —`)

RG12.5 (focus inchangé), RG11.13 (stockage refusé : trois lignes à relire, aucune exception, pas de bouton), RG11.14 (aucune requête autre que GET ; aucun fichier du lab modifié).

## Remarques de banc

- Le harnais ne laisse passer ni les `who` du serveur ni son `reload` : le `hello` du serveur remplaçait la poussée, et la carte de l'ancien onglet Équipe recharge la page quand un agent du `who` manque à la carte (une fois par 15 s, clé de session `vf-equipe-rechargement`, tenue en repos par un horodatage futur).
- Un mutant par garde (régime allégé) : abonnement au `who` du compositeur, désabonnement du nettoyage par onglet.
