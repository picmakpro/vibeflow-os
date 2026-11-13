BASE=39300871800fbfa0aa74c19850577f836af96c2a

# 76-07 — trace rouge (régime allégé : test d'abord, vu ROUGE)

## Tâche 1 — C3.1 et C3.2 (aucun `ui/74-vf-trace-decisions.js` dans l'arbre : section « Décisions » absente)

Suite jouée : `bash plugin/cockpit/scripts/tests/test-cockpit-tracabilite-panneaux.sh` (serveur réel sur une copie du module, Chrome sans tête, lab fabriqué dans `$WORK`).
C0 vert (témoin : le serveur écoute et la route sert `ADR-001`).

```
  ❌ FAIL — C3.1a — section « Décisions » repliée par défaut, aucune requête vue=adr avant l'ouverture, une seule à l'ouverture
     attendu: [true|0|1]
     obtenu:  [absent : Cannot read properties of undefined (reading 'req')]
  ❌ FAIL — C3.1b — bilan « 2 ADR · 3 décisions · 1 registre de phase », compteur « 2 ADR », une ligne par ADR avec section (ADR-007 sans section n'en a pas)
     attendu: [2 ADR · 3 décisions · 1 registre de phase|2 ADR|ADR-001,ADR-002]
     obtenu:  [absent : Cannot read properties of undefined (reading 'bilan')]
  ❌ FAIL — C3.1c — Entrée sur ADR-001 : panneau d'ADR, titre « ADR-001 », id vf-trace-adr-ADR-001, data-trace adr:ADR-001, étiquette « ADR »
     attendu: [ADR-001|vf-trace-adr-ADR-001|adr:ADR-001|ADR]
     obtenu:  [absent : Cannot read properties of undefined (reading 'titre')]
  ❌ FAIL — C3.2 — témoin voisin : ADR-002 sans commit : « Aucun commit ne cite cet objet. Un message de commit qui nomme son identifiant le relierait. »
     attendu: [ADR-002|true|0]
     obtenu:  [absent : Cannot read properties of undefined (reading 'titre')]
  ❌ FAIL — C3.x — aucune section n'a échoué par erreur de harnais
     attendu: [{}]
     obtenu:  [{"d1":"clic : « #panel details[data-vf-trace-decisions] > summary » absent"}]
```

Rouge par l'assertion visée (la section n'existe pas), jamais par un plantage de Chrome. Vert après le code : 9 PASS / 0 FAIL (12 s).
Les mutants (M-NUE-PAGE, M-PLAFOND-30, …) sont levés : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).

## Tâche 2 — C3.3 à C3.9 (code de la tâche 1 seul : ni panneau de décision, ni registres)

Suite : `bash plugin/cockpit/scripts/tests/test-cockpit-tracabilite-panneaux.sh` (13 PASS, 14 FAIL avant le code). Rouges par l'assertion (attendu, obtenu), extraits :

```
  ❌ FAIL — C3.3a — Décisions, « Registres de phase » : un sous-repli « Phase 90, 3 décisions » fermé ; déplié : identifiant et début de définition de P90-D-01, P90-D-02 et D-04
     attendu: [1|true|Phase 90 3 décisions|P90-D-01,P90-D-02,D-04]
     obtenu:  [absent : Cannot read properties of null (reading 'n')]
  ❌ FAIL — C3.3b — panneau de P90-D-01 : étiquette « Décision », titre, titre de définition, sections « Phase », « ADR citées », « Commits qui la citent »
     attendu: [Décision|P90-D-01|vf-trace-decision-P90-D-01_ph-90|decision:P90-D-01:ph-90|DECISION-MARQUEUR-76 première définition (ADR-001, ADR-007)|Phase,ADR citées,Commits qui la citent]
     obtenu:  [absent : Cannot read properties of undefined (reading 'kind')]
  ❌ FAIL — C3.3c — « Phase » est un bouton qui sélectionne la phase ; ADR-001 en bouton ; ADR-007 (citée sans section) en texte non interactif « sans section dans docs/ADR.md », non focalisable
     attendu: [true|n:ph-90|ADR-001|[{"tag":"P","texte":"ADR-007 sans section dans docs/ADR.md","tab":null}]]
     obtenu:  [absent : Cannot read properties of undefined (reading 'phase')]
  ❌ FAIL — C3.3d — « Commits qui la citent » : sha, jour et sujet du commit qui nomme P90-D-01 ; pied « Lu dans <registre> »
     attendu: [7fb618a·11 nov. 2026·fix: applique P90-D-01|Lu dans .planning/workstreams/x/phases/90-registre/90-CONTEXT.md]
     obtenu:  [absent : Cannot read properties of undefined (reading 'commits')]
  ❌ FAIL — C3.4 — décision nue : titre « D-04, Phase 90 », phrase « Décision nue : … », aucune section ni ligne de commit ; témoin positif : un commit du lab cite « D-04 » et la préfixée porte sa ligne de commit
     attendu: [D-04, Phase 90|true|0|false|1|1]
     obtenu:  [absent : Cannot read properties of undefined (reading 'titre')|1]
  ❌ FAIL — C3.5a — 31 registres : 30 sous-replis fermés, du plus récent (Phase 80, 2 décisions) au plus ancien montré (Phase 51), puis « + 1 autre registre »
     attendu: [30|true|Phase 80 2 décisions|Phase 51 1 décision|+ 1 autre registre]
     obtenu:  [absent : Cannot read properties of null (reading 'n')]
  ❌ FAIL — C3.5b — un sous-repli ouvert montre ses décisions : identifiant mono et début de la ligne de définition
     attendu: [P80-D-01|décision de la phase 80, début de définition//P80-D-02|seconde décision de la phase quatre-vingts]
     obtenu:  [absent : Cannot read properties of undefined (reading 'join')]
  ❌ FAIL — C3.5c — « + 1 autre registre » ouvre la liste « Registres de phase » : le registre de la Phase 50
     attendu: [1|Phase 50 1 décision]
     obtenu:  [absent : Cannot read properties of undefined (reading 'n')]
  ❌ FAIL — C3.9a — sans docs/ADR.md : « Pas de docs/ADR.md dans ce dossier. … », les registres de phase restent montrés ; bilan « 0 ADR · 32 décisions · 31 registres de phase »
     attendu: [true|true|0 ADR · 32 décisions · 31 registres de phase]
     obtenu:  [absent : Cannot read properties of null (reading 'sansAdr')]
  ❌ FAIL — C3.9b — sans registre : « Aucune décision définie dans les registres de phase. Les lignes Pnn-D-nn d'un fichier CONTEXT de phase apparaissent ici. »
     attendu: [true]
     obtenu:  [false]
```

C3.6 (plafond de 30, liste paginée) et C3.7 (tiroir Git) étaient déjà verts : le plafond (`VT.liste30`) et la ligne de commit sont du code de la tâche 1 ; leurs témoins sont écrits ici et passent sans nouveau code. C3.8 rouge pour une raison de harnais (attente de fin de chargement, corrigée dans le harnais), vert ensuite.
Vert après le code : 27 PASS / 0 FAIL (46 s). Mutants M-NUE-PAGE et M-PLAFOND-30 levés : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).
