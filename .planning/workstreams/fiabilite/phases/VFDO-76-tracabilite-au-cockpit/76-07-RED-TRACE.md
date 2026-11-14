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

## Tâche 3 — C4.1 à C4.10 (code des tâches 1 et 2 seul : aucun `ui/74-vf-trace-memoire.js`)

Suite : `bash plugin/cockpit/scripts/tests/test-cockpit-tracabilite-panneaux.sh` (29 PASS, 25 FAIL avant le code). Rouges par l'assertion (attendu, obtenu), extraits :

```
  ❌ FAIL — C4.1a — section « Mémoire des agents » repliée par défaut, aucune requête vue=memoire avant l'ouverture, une seule à l'ouverture
     attendu: [true|0|1]
     obtenu:  [absent : Cannot read properties of undefined (reading 'req')]
  ❌ FAIL — C4.1b — bilan en six emplacements, zéros écrits ; compteur « 3 agents »
     attendu: [4 entrées · 3 agents · 1 entrée hors index · 1 lien cassé · 1 chemin cité absent · 2 entrées sans lien entrant|3 agents]
     obtenu:  [absent : Cannot read properties of undefined (reading 'bilan')]
  ❌ FAIL — C4.1d — une ligne par agent : nom, nombre d'entrées, ligne 2 (octogone, contradictions non nulles), ligne 3 (mentions neutres) ou « aucun écart » ; aucun octogone en ligne 3
     attendu: [vf-coder|3 entrées|1 entrée hors index · 1 lien cassé · 1 chemin cité absent|2 entrées sans lien entrant · 1 lien résolu par nom de fichier|1|0//vf-reviewer|1 entrée||aucun écart|0|0//vide|0 entrée||aucun écart|0|0]
     obtenu:  [absent : Cannot read properties of undefined (reading 'agents')]
  ❌ FAIL — C4.2a — liste « Entrées de vf-coder » : nom mono, type, ligne « modifiée le … », contradictions derrière un octogone puis « sans lien entrant » sans glyphe
     attendu: [Entrées de vf-coder|entree-a-MEMOIRE-MARQUEUR-76|project|modifiée le 8 nov. 2026 · 0 lien entrant · 3 liens sortants|1 lien cassé · sans lien entrant|1|1 lien cassé//entree-b|feedback|modifiée le 8 nov. 2026 · 0 lien entrant · 0 lien sortant|1 chemin cité absent · sans lien entrant|1|
     obtenu:  [absent : Cannot read properties of undefined (reading 'titre')]
  ❌ FAIL — C4.2b — agent sans entrée : « Aucune entrée suivie pour cet agent. Un fichier de mémoire suivi par git sous son dossier apparaît ici. »
     attendu: [true|Entrées de vide]
     obtenu:  [absent : Cannot read properties of undefined (reading 'texte')]
  ❌ FAIL — C4.3a — entrée entree-a : titre mono, ancre, rappel, fiche, état « sans lien entrant » sans octogone (le lien cassé n'est pas répété), pied « Lu dans … »
     attendu: [Mémoire|entree-a-MEMOIRE-MARQUEUR-76|vf-trace-entree-vf-coder_a_md|entree:vf-coder/a.md|Seule la structure est lue : ni description ni contenu.|Agent=vf-coder,Type=project,Dernier commit=8 nov. 2026,Liens sortants=3 liens,Liens entrants=0 lien|Fiche,État,Liens sortants|sans lien entra
     obtenu:  [absent : Cannot read properties of undefined (reading 'kind')]
  ❌ FAIL — C4.3b — liens sortants : résolu par nom de fichier (bouton, carré à deux barres), lien cassé (texte non interactif, octogone), résolu (bouton)
     attendu: [BUTTON|c|résolu par nom de fichier|resolu//DIV|inconnu|lien cassé|contradiction//BUTTON|revue-1|résolu|]
     obtenu:  [absent : Cannot read properties of undefined (reading 'sortants')]
  ❌ FAIL — C4.3c — entrée hors index : état « hors index » avec octogone ; liens entrants en boutons, sans lien d'index
     attendu: [hors index+octogone|Fiche,État,Liens entrants|BUTTON|vf-coder/a.md]
     obtenu:  [absent : Cannot read properties of undefined (reading 'etat')]
  ❌ FAIL — C4.3d — chemin cité absent : ligne non interactive avec octogone, « absent de HEAD, présent dans l'historique lu »
     attendu: [DIV|docs/vieux.md absent de HEAD, présent dans l'historique lu|1|Fiche,État,Chemins cités et absents de HEAD|sans lien entrant]
     obtenu:  [absent : Cannot read properties of undefined (reading 'absents')]
  ❌ FAIL — C4.3e — entrée saine : « Dans l'index, avec au moins un lien entrant. »
     attendu: [Dans l'index, avec au moins un lien entrant.|0|revue-1|Liens entrants=1 lien]
     obtenu:  [absent : Cannot read properties of undefined (reading 'etat')]
  ❌ FAIL — C4.6c — entrée, puis entrée cible par un lien résolu : le Retour nomme l'entrée quittée ; Échap rappelle le Retour commun (l'entrée, le Retour nomme la liste)
     attendu: [true|entree-a-MEMOIRE-MARQUEUR-76|true]
     obtenu:  [absent : Cannot read properties of undefined (reading 'label')]
  ❌ FAIL — C4.6d — exigence, décision citée (P76-D-38) : le Retour nomme REQ-01, puis la phase 90 ; ordre phase 90, REQ-01, décision, aucune vue répétée
     attendu: [P90-D-01|true|REQ-01|true|n:ph-90|true]
     obtenu:  [absent : Cannot read properties of undefined (reading 'titre')]
  ❌ FAIL — C4.7a — témoin positif d'abord : éléments .vf-trace posés et visibles ; aucun canevas ni svg dans .vf-trace
     attendu: [true|true|0]
     obtenu:  [absent : Cannot read properties of undefined (reading 'posees')]
  ❌ FAIL — C4.7b — ordre des sections Jalon, Décisions, Mémoire après le corps ; une section ouverte reste ouverte après un nouveau rendu du panneau
     attendu: [vfTraceJalon,vfTraceDecisions,vfTraceMemoire|true|true,true,true|vfTraceJalon,vfTraceDecisions,vfTraceMemoire|true,true,true]
     obtenu:  [absent : Cannot read properties of undefined (reading 'ordre')]
  ❌ FAIL — C4.8a — témoin positif : les marqueurs d'ADR, de décision et de mémoire sont visibles dans les sections et les panneaux
     attendu: [true|true|true|true]
     obtenu:  [absent : Cannot read properties of undefined (reading 'includes')]
  ❌ FAIL — C4.5a — sans .claude/agent-memory/ : « Pas de .claude/agent-memory/ dans ce dossier. Les fichiers de mémoire suivis par git apparaîtraient ici. », aucun bilan
     attendu: [Pas de .claude/agent-memory/ dans ce dossier. Les fichiers de mémoire suivis par git apparaîtraient ici.|true]
     obtenu:  [absent : Cannot read properties of undefined (reading 'texte')]
  ❌ FAIL — C4.5b — .claude/ ignoré par git : « .claude/ n'est pas suivi par git : 3 fichiers non suivis, aucune entrée à lire. … » ; aucun des trois noms dans le DOM ; témoin positif : ils existent
     attendu: [.claude/ n'est pas suivi par git : 3 fichiers non suivis, aucune entrée à lire. Suivre .claude/agent-memory/ dans git les rend lisibles.|false|3]
     obtenu:  [absent : Cannot read properties of undefined (reading 'texte')|3]
  ❌ FAIL — C4.5c — sans git : « Git n'est pas disponible : la mémoire des agents n'est pas lue. Un dépôt git la rend lisible. » et, dans le panneau d'ADR, « Git n'est pas disponible : les commits qui citent cet objet ne sont pas lus. … »
     attendu: [Git n'est pas disponible : la mémoire des agents n'est pas lue. Un dépôt git la rend lisible.|true]
     obtenu:  [absent : Cannot read properties of undefined (reading 'texte')]
```

Déjà verts avant le code, et pourquoi : C4.6a et C4.6b (chaînes de Retour du Jalon et de Décisions, ADR, décision, phase : code des tâches précédentes et de 76-06), C4.4 et C4.8b
(négatifs : aucune donnée de mémoire n'existe encore côté page ; leurs témoins positifs sont C4.1 à C4.3 et C4.8a, rouges ici). Deux assertions du harnais corrigées après coup,
avant le vert : C4.4 (le témoin positif comptait avec `grep -rc`, qui préfixe le chemin) et C4.8b (le code de la 76, présent dans l'export, contient les chaînes `data-vf-trace-` :
le contrôle porte sur les trois marqueurs seulement).
Vert après le code : 54 PASS / 0 FAIL (68 s). Mutants M-ETAT-REPETE, M-CORAIL-NEUTRE, M-EXPORT-DM, M-PILE-DECISIONS, M-EXCLUSION, M-CLE-CRUE, M-REF-GARDEE levés : régime allégé
(consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).
