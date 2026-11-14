# 75-10 — trace de rouge

Base de comparaison : `bba9aecde` (parent du premier commit de la route d'activité, après les Phases 79, 80 et 74) ; tête mesurée : `4e299397` plus les changements du plan.
Les chemins sont relatifs au dépôt.

## Témoins mesurés

- `test-cockpit-coquille.sh`, C6.1 : vert sur l'archive de `3a80d45e` (114 PASS, 0 FAIL), rouge sur la tête `4e299397` (113 PASS, 1 FAIL ; attendu [aucune], obtenu [ids]).
  Détail relevé : après un changement d'onglet vers Code, `lens-d-chauds` et `lens-d-couplage` manquent par rapport au chargement à froid. Ce sont les descriptions des lignes DÉSACTIVÉES tant que la route lit git (état `en-lecture`) ;
  le chargement à froid est pris sur un serveur jeune, la suite d'onglets plus tard, une fois git lu. La cause est le temps, pas un défaut de démontage. Correctif : C6.1 reprend ses chargements à froid une fois la route lue (`activite_prete`) ; C6.1 vert ensuite.
- Compteur de suites : `check-version-sync.sh` rouge avant retouche (`'245 suites' ≠ réel=247`, README.md et README.fr.md), vert après (247, relevé par la commande du gate).
- Volet « activité » : C0a (témoin, trois maillons retirés) ABOUTIT ; C1a (code livré) : rien n'aboutit ; C2a, C3a, C4a : chaque maillon casse la chaîne seul ; Q1.2 : le mutant « innerHTML dans la marque » est vu rouge. Mise au point : le témoin a d'abord été rouge pour de mauvaises raisons (CSP : fenêtre `alert` bloquante, charge de 170 caractères coupée à 120 par la cible), corrigées.
- `test-cockpit-activite-sans-git.sh` : 17 PASS, 0 FAIL, 2 MUTANT-ROUGE.

## Non mesuré

- Le rouge « route absente (attendu 200, obtenu 404) » sur `bba9aecde` n'a pas été rejoué : l'archive de la base est prête, le temps manquait. Le témoin positif de la suite est l'assertion X3 « GET /api/vf/activite répond 200 ».
- Nombre d'assertions de `test-cockpit-chaine-xss.sh` : 33 avant, 49 après (16 du volet activité ; rejouée verte en 133 s) ; aucune assertion existante modifiée.
