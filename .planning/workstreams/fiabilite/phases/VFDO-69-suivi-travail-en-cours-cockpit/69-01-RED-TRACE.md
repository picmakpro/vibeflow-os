# 69-01 — trace du rouge de l'avancement avant le code (P69-D-24)

- Date : 2026-11-03
- Empreinte du commit de la suite (commit A, suite seule) : `4fce7e42` (`4fce7e429c9a0b06ac04222533f46860b507466d`), base `7370d604`
- Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-avancement.sh > sortie 2>&1` (rc=1 ; 10 PASS / 25 FAIL)
- Code rejoué : aucun module d'avancement, `vf-cockpit-project.mjs` et `vf-cockpit-planning.mjs` inchangés (HEAD = base + commit A)

Chaque témoin rouge est précédé de son contrôle positif vert (A0). Chaque rouge ci-dessous a la bonne raison :
le champ existant montre l'ancien comportement (`11/7 plans`, `todo`, `missions`, `0/2 phases`, `active`) ou l'objet
`avancement` est absent (`absent`, `undefined`, `module absent`), jamais une erreur de fixture.

## Contrôles positifs verts (avant le code)

- A0.1 — fixture (a) : 7 PLAN et 11 SUMMARY dont 4 FIX
- A0.2 — le graphe se construit
- A0.3 — le DAG de la fixture est lu
- A0.4 — le STATE de la fixture pointe la phase 9
- A3.2 — règle 2 (contrôle positif) : MISSION-2 rattaché à ph-2
- A3.5 — « phase: 99 » inconnue : hors phase, jamais corrigé
- A6.1 — témoin positif : la sonde enregistre un fetch et une connexion délibérés
- A6.2 — buildProjectGraph : sonde chargée, 0 appel enregistré
- A18.2 — contrôle de mutant : la copie compare au numéro courant et son graphe se construit
- A18.3 — la copie mutée rend ph-2 active : l'assertion A18.1 la voit

## Témoins rouges (libellé, attendu, obtenu — recopiés de la sortie)

### A1.1 — le pied de ph-1 lit « 7/7 plans · 4 correctifs »

- attendu: [7/7 plans · 4 correctifs]
- obtenu:  [11/7 plans]

### A1.2 — le pied de ph-1 ne lit pas « 11/7 » (a trouvé [11/7])

- obtenu:  [11/7 plans]

### A1.3 — avancement.plans et correctifs de la phase 1

- attendu: [{"faits":7,"total":7}|4]
- obtenu:  [absent]

### A2.1 — phase 1 (7/7 plans, STATE sur la phase 9) : a-recetter

- attendu: [a-recetter]
- obtenu:  [absent]

### A2.2 — carte ph-1 : statut projeté et pied « à recetter »

- attendu: [active|true]
- obtenu:  [todo|false]

### A2.3 — lab L4 : états des phases 1 à 5

- attendu: [fait,en-cours,en-cours,a-recetter,a-recetter]
- obtenu:  [,,,,]

### A2.4 — phase 2 du lab L (aucun plan) : a-faire

- attendu: [a-faire]
- obtenu:  [absent]

### A2.5 — clés exactes de l'objet et version 1

- attendu: [correctifs,etat,mission,plans,reste,version|1]
- obtenu:  [|undefined]

### A2.6 — mission de la phase 1 : nom et état ; de la phase 2 : null

- attendu: [{"nom":"2026-11-01-v-cockpit","etat":"done"}|null]
- obtenu:  [undefined|undefined]

### A3.1 — règle 1 : DAG « phase: 1 » rattaché à ph-1

- attendu: [ph-1]
- obtenu:  [missions]

### A3.3 — règle 3 : DAG du dossier de la phase 3 rattaché à ph-3

- attendu: [ph-3]
- obtenu:  [absent]

### A3.4 — ordre : MISSION-4 portant « phase: 1 » va à ph-1

- attendu: [ph-1]
- obtenu:  [ph-4]

### A4.1 — jalon 📋 avec une phase à recetter : active

- attendu: [active]
- obtenu:  [todo]

### A4.2 — pied du jalon v-test

- attendu: [0 clos · 1 à recetter · 1 à faire · 0 %]
- obtenu:  [0/2 phases · 0 %]

### A4.3 — lab L4 : pied strict, 1 clos sur 5 = 20 %

- attendu: [1 clos · 2 en cours · 2 à recetter · 0 à faire · 20 %]
- obtenu:  [1/5 phases · 20 %]

### A5.1 — reste de la phase 1 du lab L4

- attendu: [[]]
- obtenu:  [undefined]

### A5.2 — reste de la phase 2 du lab L4

- attendu: [["verification","cloture"]]
- obtenu:  [undefined]

### A5.3 — reste de la phase 3 du lab L4

- attendu: [["verification","cloture"]]
- obtenu:  [undefined]

### A5.4 — reste de la phase 4 du lab L4

- attendu: [["recette","verification","cloture"]]
- obtenu:  [undefined]

### A5.5 — reste de la phase 5 du lab L4

- attendu: [["cloture"]]
- obtenu:  [undefined]

### A18.1 — lab L5 : le STATE pointe la phase 2, aucun plan n'y est fait : ph-2 reste todo

- attendu: [todo]
- obtenu:  [active]

### A18.0 — le source réel ne compare plus une phase au numéro courant

- attendu: [0]
- obtenu:  [1]

### A7.1 — le bloc avancement du contrat égale ETATS et RESTE, version 1

- attendu: [ok]
- obtenu:  [module absent]

### A7.2 — copie mutée du contrat (un état retiré) : la dérive est vue

- attendu: [dérive]
- obtenu:  [module absent]

### A8.1 — lab partitionné, pointeur sur beta : la phase 1 d'alpha est a-recetter

- attendu: [a-recetter]
- obtenu:  [absent]

