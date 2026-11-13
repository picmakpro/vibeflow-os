BASE=5b5efe73920ca8878af04c5775fac4c6906c0fa9

# 76-06 — trace rouge (régime allégé : test d'abord, vu ROUGE)

## Tâche 1 — C1.0 à C1.2 (code de page absent : aucun `ui/74-vf-trace*.js` dans l'arbre)

Suite jouée : `bash plugin/cockpit/scripts/tests/test-cockpit-tracabilite-page.sh` (serveur réel sur une copie du module, Chrome sans tête). C0 vert (témoin : serveur et première collecte).

```
  ❌ FAIL — C1.0 — fichier neuf servi : /_vf/…/74-vf-trace.js répond 200, première ligne « // VibeFlow ( »
     attendu: [200|// VibeFlow (]
     obtenu:  [non demandé]
  ❌ FAIL — C1.0b — un 74-vf-trace-intrus.js planté après le démarrage répond 404 (liste fermée au démarrage)
     attendu: [404]
     obtenu:  [non demandé]
  ❌ FAIL — C1.1 — select(n:ph-2) : #vf-trace-phase, h3 « Traçabilité », ligne REQ-01 (un button) au mot « manque : VERIFICATION »
     attendu: [true|Traçabilité|BUTTON:REQ-01:manque : VERIFICATION]
     obtenu:  [false|null|]
  ❌ FAIL — C1.1b — la requête vue au réseau est GET /api/vf/tracabilite?vue=phase&cle=ph-2
     attendu: [true]
     obtenu:  [false]
  ❌ FAIL — C1.2 — témoin positif voisin : select(n:ph-3), REQ-02 à chaîne complète, mot « chaîne complète »
     attendu: [true|chaîne complète]
     obtenu:  [false|]
  ✅ PASS — C1.x — aucune section n'a échoué par erreur de harnais
```

Rouge par l'assertion visée (« obtenu : absent »), jamais par un plantage de Chrome. Les mutants (M-MOT-VERIF et suivants) sont levés : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).

## Tâche 2 — C1.3 à C1.12 (code de la tâche 1 seul : section réduite aux lignes et au mot, ni feuille, ni légende, ni bilan, ni preuves, ni Jalon)

Suite : `bash plugin/cockpit/scripts/tests/test-cockpit-tracabilite-page.sh` (10 PASS, 21 FAIL). Rouges par l'assertion (attendu, obtenu), extraits :

```
  ❌ FAIL — C1.3 — bande : quatre glyphes de 16 x 16 px, aria-hidden ; octogone à la place du SUMMARY (REQ-16) et du plan (REQ-17), mots dits
     attendu: [4|16x16,16x16,16x16,16x16|true|0100|1000|contradiction : cochée, sans SUMMARY|contradiction : Complete, sans plan]
     obtenu:  [4|0x16,0x16,0x16,0x16|true|0100|1000|contradiction : cochée, sans SUMMARY|contradiction : Complete, sans plan]
  ❌ FAIL — C1.3b — le corail ne vit que dans l'octogone : seul le glyphe SUMMARY de REQ-16 le résout, aucun texte, fond ni bordure ne l'a
     attendu: [0100|0]
     obtenu:  [0000|0]
  ❌ FAIL — C1.4 — bilan de la phase 1 : catégories exclusives (somme 7), identique aux nombres de la route, compteur « 7 exigences »
     attendu: [2,3,1,1,7|Par exigence : 2 en contradiction · 3 avec un manque · 1 non lisible · 1 complète|7 exigences]
     obtenu:  [2,3,1,1,7||7 exigences]
  ❌ FAIL — C1.4b — légende visible sans survol : quatre glyphes neutres (aucun corail), colonnes nommées
     attendu: [true|true|4|0]
     obtenu:  [false|false|0|-1]
  ❌ FAIL — C1.5a — au bureau : cinq lignes, contradictions puis manques, puis « + 2 autres exigences »
     attendu: [REQ-16,REQ-17,REQ-13,REQ-14,REQ-15|+ 2 autres exigences]
     obtenu:  [REQ-16,REQ-17,REQ-13,REQ-14,REQ-15,REQ-12,REQ-11|null]
  ❌ FAIL — C1.5b — à 390 px : trois lignes puis « + 4 autres exigences »
     attendu: [REQ-16,REQ-17,REQ-13|+ 4 autres exigences]
     obtenu:  [REQ-16,REQ-17,REQ-13,REQ-14,REQ-15,REQ-12,REQ-11|null]
  ❌ FAIL — C1.7 — entrée haute : un bouton placé avant la section, nom « Traçabilité, 7 exigences, 6 incomplètes dont 2 en contradiction. Aller à la section. »
     attendu: [BUTTON|true|Traçabilité 7 exigences, 6 incomplètes dont 2 en contradiction Aller à la section.]
     obtenu:  [absent : Cannot read properties of null (reading 'tag')]
  ❌ FAIL — C1.8a — preuves attachées au bureau : fermé par défaut, ouvert 6 lignes, « Phase · VERIFICATION » et « statut : passed », « + 1 autre fichier de preuve », six chemins
     attendu: [true|6|Phase · VERIFICATION statut : passed .planning|+ 1 autre fichier de preuve|6]
     obtenu:  [absent : Cannot read properties of undefined (reading 'ferme')]
  ❌ FAIL — C1.9a — section Jalon : repliée par défaut, aucune requête vue=jalon avant l'ouverture, une seule à l'ouverture
     attendu: [true|0|1]
     obtenu:  [null|0|undefined]
  ❌ FAIL — C1.10b — route refusée : boîte « La traçabilité est indisponible », cause, « Réessayer » de 12,5 px et 32 px ; il relit
     attendu: [La traçabilité est indisponible La lecture du dépôt a échoué ou dépassé le délai. Réessayer|12.5px|32|true|true]
     obtenu:  [La traçabilité est indisponibleLa lecture du dépôt a échoué ou dépassé le délai.Réessayer|13px|36|true|true]
  ❌ FAIL — C1.10c — phase sans exigence : la phrase dit sa cause et ce qui la lèverait
     attendu: [Aucune exigence rattachée à cette phase. Une ligne du tableau de traçabilité du registre des exigences, ou le champ « requirements » d'un plan, la rattache.]
     obtenu:  []
  ❌ FAIL — C1.11 — quatre tailles de texte seulement sous .vf-trace, aucune couleur ni espacement en dur, aucune variable inventée, aucun tiret cadratin, aucune violation de CSP
     attendu: [true|true|0|0|0|false|0]
     obtenu:  [absent : Cannot read properties of undefined (reading 'tailles')]
  ❌ FAIL — C1.12a — bureau : section ≤ 792 px (repli fermé) et ≤ 1 148 px (ouvert), aucun défilement horizontal, carte non poussée
     attendu: [true|true|true|true]
     obtenu:  [absent : Cannot read properties of undefined (reading 'ferme')]
```

Verts dès la tâche 1 (comportement déjà livré) : C1.0 à C1.2, C1.6a, C1.6b, C1.10a. Mutants M-PLAFOND, M-RECOMPTE, M-CORAIL, M-EXCLUSION : levés (régime allégé, consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).

## Tâche 3 — C2.1 à C2.10 (code de la tâche 2 seul : ni panneau d'exigence, ni liste, ni pile, ni Échap)

Suite : 34 PASS, 20 FAIL (C1.x tous verts). Rouges par l'assertion (attendu, obtenu), extraits :

```
  ❌ FAIL — C2.1a — clic sur REQ-16 : panneau d'exigence, titre REQ-16, Chaîne sans section « Contradictions », SUMMARY en contradiction dite sur sa ligne
     attendu: [true|REQ-16|Chaîne,Décisions citées,Preuves,Rattachement|true]
     obtenu:  [absent : Cannot read properties of null (reading 'titre')]
  ❌ FAIL — C2.2a — « + 26 autres exigences » ouvre « Exigences de la Phase 5 » : 30 lignes, « 1 à 30 sur 31 exigences », Précédentes désactivé ; Suivantes : 1 ligne, focus sur le titre
     attendu: [30|1 à 30 sur 31 exigences|true|1|31 à 31 sur 31 exigences|true]
     obtenu:  [absent : Cannot read properties of undefined (reading 'n')]
  ❌ FAIL — C2.3a — Entrée sur une ligne : focus sur le titre du panneau ; un clic souris laisse le focus où il est
     attendu: [true|vf-trace-exigence-REQ-16|true]
     obtenu:  [false||true]
  ❌ FAIL — C2.9a — REQ-11 : sections dans l'ordre, une ligne par décision définie et par ADR avec son titre, « D-04 » absent (la route le rend en decisionsNues, la ligne du registre le contient), aucun glyphe
     attendu: [Chaîne,Décisions citées,Preuves,Rattachement|P90-D-01,ADR-001|true|true|false|1|true|0]
     obtenu:  [absent : Cannot read properties of undefined (reading 'pan')]
  ❌ FAIL — C2.9d — un clic sur une preuve ouvre « Preuves de la Phase 1 » positionné sur elle (aria-current, chemin relatif copiable) ; le contenu du fichier n'est ni dans le DOM ni dans les réponses (témoin : il est dans le fichier du lab)
     attendu: [[".planning/workstreams/x/phases/01-socle/01-VERIFICATION.md"]|false|false|true]
     obtenu:  [absent : Cannot read properties of undefined (reading 'cur')]
  ❌ FAIL — C2.5 — section Jalon ouverte : un SUMMARY modifié dans le lab remplace le contenu, la section reste ouverte, le défilement est gardé ; refermée : aucune requête vue=jalon
     attendu: [true|true|true|0]
     obtenu:  [false|true|true|0]
  ❌ FAIL — C2.7 — exigence retirée du registre puis relue : « Cet objet n'existe plus dans le dépôt. Le bouton Retour de l'en-tête rouvre la vue précédente. »
     attendu: [true]
     obtenu:  [false]
```

Obtenu typique : `clic : « #vf-trace-phase .vf-trace-ligne[data-trace="exigence:REQ-11"] » absent` / panneau absent (`pan: null`), Retour « indisponible » (aucun panneau empilé). Mutants M-INNERHTML, M-PREUVE-CORPS, M-NUE-EXIG, M-EMPILER, M-EMPILER-NOEUD, M-EXPORT, M-REF-GARDEE, M-CLE-CRUE : levés (régime allégé, consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).
