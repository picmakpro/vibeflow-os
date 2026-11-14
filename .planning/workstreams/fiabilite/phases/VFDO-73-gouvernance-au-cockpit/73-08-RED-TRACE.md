base: 852e638e9b76985e987acfe534a9d4a199784fab

# 73-08 — trace du rouge (régime allégé)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-regie.sh RG3_retrait RG14_retrait`, sur la tête de départ (canevas d'Équipe encore en place). Pas de Chrome nécessaire : les sections sont jouées en vm et en module.
Verdict : 4 PASS / 6 FAIL, exit 1.

## Rouges (chacun avec sa ligne `❌ FAIL — <id> —`)

| id | obtenu | motif |
|----|--------|-------|
| RG3.1 | `nodes` = 3, cartes présentes | l'enveloppe porte encore une carte par agent |
| RG3.3 | `2\|1\|true\|au-travail:…` (rechargements, rendus du moteur) | `72-vf-equipe.js` recharge la page et rappelle le moteur à chaque poussée et toutes les 30 s |
| RG3.5 | `constructions=11` | le mémo dépend du `who` et des lancements |
| RG3.6 | `2\|2` | clé `vf-equipe-rechargement` écrite, rechargements |
| M-GARDE-MEMO | ancre absente | la garde mémoïsée n'existe pas encore |
| RG14.30 | `5\|0,0,0,0` | `72-vf-equipe.js` construit encore les boutons de commande et de transcript (5 occurrences) |

## Gardes vertes dès la base (`✅ PASS — <id> —`)

RG3.2 (enveloppe valide contre le bloc `cockpit-equipe@1`), RG3.4 (le moteur ne porte aucune trace de la régie ni de la ligne de lancement), RG3.7 (garde d'émission : sain, interdit, sain), RG14.3 (A2 : aucun champ `health`, la règle de feuille d'Équipe est en place, aucun titre Santé dans `section#vf-equipe`).

## Re-pointages des témoins du canevas (P73-D-04) : ancien support, rouge observé, nouveau support

Rouge observé : les assertions d'origine rejouées sur le code retiré (enveloppe sans cartes, `72-vf-equipe.js` réduit). Liste vue rouge : E23.4, EUI2.8 à EUI2.14, EUI2.18c, EUI2.23, EUI2.24, EUI2.25, EK1.0, EK1, EK1.1, EK2.1, EK3.1, EK5.1 (le reste du `test-cockpit-equipe.sh` n'avait pas été joué jusqu'au bout : l'arrêt est volontaire, la suite a été re-pointée en bloc, puis rejouée en entier).

| id | ancien support | nouveau support (même propriété) |
|----|----------------|----------------------------------|
| E23.4 | cartes de l'enveloppe servie | enveloppe sans carte, meta conservée |
| EUI2.8, 2.23 | panneau d'item de `72-vf-equipe.js` | ligne de la régie, `vm-regie-page.mjs`, entrées piégées en texte |
| EUI2.9, 2.24 | mutants « pied brut » et « nœud brut » sur 72 | mêmes mutants sur `72-vf-regie-rendu.js` (copie) |
| EUI2.10, 2.12, 2.25 | rechargement de page sur changement d'ensemble | 0 rechargement, 0 rendu du moteur, ligne ajoutée ou déplacée de section |
| EUI2.11, 2.13, 2.26 | mutants de signature et de borne de 72 | mutants de clé de ligne du modèle (clé sans agent, clé volatile, clé sans section) |
| EUI2.14 à 2.16 | arrivée sur une carte (`SC.reveal`) | arrivée par `__vfRegie.arriver` : ancrage de la ligne, une fois ; mutant sans ancrage |
| EUI2.18c | effectifs `meta.vf.compte` | sous-titre de la régie (2 agents, 1 à relire) |
| EA1.5, EA1.6 | descriptions des cartes (`buildEquipeGraph`) | ligne 2 et mot d'état des lignes du modèle (`vm-regie.mjs`) |
| EK1.0, EK1, EK1.1 | « Lire le transcript » du panneau | « Lire le rapport » d'une ligne terminée (fixture : un agent terminé en plus) |
| EK1.2, EK1.3 | mutants de 72 (Entrée non arrêtée, bouton désactivé) | mutants de `ouvrirRepli` de `72-vf-regie-source.js` |
| EK2.1, EK2.2, EK3.1, EK3.2, EK6 | clé `vf-equipe-ouvert` | aucune clé `vf-equipe-*` ; mutants : le lecteur de repli en écrit une |
| EK5.1, EK5.2 | commande du panneau d'item | commande du tiroir « Au travail » (Projet) |
| EK8.0, EK8, EK8.2 | focus rendu au bouton du panneau après un `who` | focus resté sur « Lire le rapport » (mise à jour en place) ; mutant : lignes réinsérées à chaque rendu |
| EKR2 | transcript reposé dans le panneau (`reposer-chrome.mjs`) | lecteur de repli de la régie reposé (action `lecteur-puis-who`) |
| EK10, EK10.2 | pastille dans la carte | mot d'état dans sa ligne ; mutant de feuille (mot décalé) |
| EK13, EK13.0, EK13.2, EK13.3 | échelle et cadrage du canevas | aucune ligne ne déborde, l'en-tête de la régie ne recouvre pas sa première section ; mutants de feuille |
| EK14, EK14.2 | titre qui grandit, cadrage | même mesure sur l'en-tête de la régie ; mutant de hauteur fixe |
| EK18, EK18.1, EK18.2 | `#context h1` | `#vf-equipe-entete h1` : arrêt de Tab ni fermé, ni ouvert, ni refermé ; mutants : tabindex, lien |
| K13.1 à K13.3 | grille de cartes à 390 px | colonne de lignes de la régie à 390 px, aucune ne déborde |
| L3 | `lancees: lancer.lancees()` passé à la page Équipe | `lancees: () => lancer.lancees()` passé à `startLive` |
| L3b (neuf) | — | le `who` du direct porte `lancee` sur la session lancée, jamais sur un sous-agent |

## Remarques de banc

- `RG3.4` n'est pas la ligne V6.1 que le plan cite : elle n'existe pas dans `test-cockpit-vendor.sh`. Le témoin lit `viewer.html` et `20-health.js` (aucune trace de la régie ni de la ligne de lancement) ; l'octet est de plus prouvé par `git diff` vide sur ces deux fichiers (SUMMARY).
- Un seul mutant neuf (M-GARDE-MEMO) : la garde d'émission mémoïsée (régime allégé).
