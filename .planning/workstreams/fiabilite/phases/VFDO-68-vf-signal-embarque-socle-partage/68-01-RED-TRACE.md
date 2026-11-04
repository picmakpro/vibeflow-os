# 68-01 — trace du rouge de la mission vivante avant le code (VFSG-06)

- Date : 2026-11-04
- Empreinte du commit de la suite (commit A, suite seule) : `23cb1612` (`23cb16120b0eb0dfb5f2168abea435952e385e76`), base `7ad90e3f`
- Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-vie.sh > sortie 2>&1` (rc=1 ; 5 PASS / 25 FAIL)
- Code rejoué : aucun `vf-cockpit-vie.mjs`, `vf-cockpit-avancement.mjs` et `vf-cockpit-planning.mjs` inchangés (HEAD = base + commit A)

Chaque témoin rouge est précédé de ses contrôles positifs verts (V0, V7.1). Chaque rouge a la bonne raison : le champ existant montre l'ancien
comportement (`running` pour V1.2, `en-cours` pour V6.1) ou le champ est absent (`absent`, `undefined`) parce que le module `vf-cockpit-vie.mjs` n'existe pas ;
jamais une erreur de fixture (V0.1 à V0.4 vérifient les faux verrous, les DAG et les clés de phase). Les copies mutées (V8, V9.3, V9.5, V9.7, V9.9, V10.3)
rougissent par « ancre absente » : la copie ne peut pas exister avant le module qu'elle mute ; elles rougiront sur l'assertion visée une fois le module écrit.
V5.1, V5.2 et V7.2 attendent `inconnu` (P68-D-23) ; V1 et V9 attendent `abandonnee` ; V5.3 est le témoin de P68-D-29 (sans dossier de scripts explicite,
le conductor voisin du dépôt est trouvé).
Le témoin VFSG-06 obtient `running` sur l'avancement de la phase (V1.2, ancien comportement) et un champ `etat` de DAG absent (V1.1) : la mission n'est pas encore jugée.

## Contrôles positifs verts (avant le code)

- V0.1 — fixtures lisibles (faux verrous exécutables et JSON, DAG running lisibles)
- V0.2 — le dossier de scripts explicite vide ne contient aucun driver-lock.sh
- V0.3 — readPlanning rend le DAG de MISSION-1 (lab plat) et deux phases
- V0.4 — lab partitionné : deux DAG et les phases w|1 et w|2
- V7.1 — script planté dans le lab jamais exécuté

## Témoins rouges (libellé, attendu, obtenu — recopiés de la sortie)

### V1.1 — DAG à nœud running sans verrou : abandonnee

- attendu: [abandonnee]
- obtenu:  [absent]

### V1.2 — avancement.mission.etat de la phase 1 : abandonnee

- attendu: [abandonnee]
- obtenu:  [running]

### V2.1 — verrou tenu (lab plat, objet unique), stale false : running

- attendu: [running]
- obtenu:  [absent]

### V3.1 — verrou périmé mais progrès de 60 s sous un ttl de 1800 : running

- attendu: [running]
- obtenu:  [absent]

### V4.1 — verrou périmé, progress_age_seconds null : abandonnee

- attendu: [abandonnee]
- obtenu:  [absent]

### V5.1 — source des verrous introuvable : vie null, état inconnu

- attendu: [null|inconnu]
- obtenu:  [absent|absent]

### V5.2 — JSON illisible : vie null, état inconnu

- attendu: [null|inconnu]
- obtenu:  [absent|absent]

### V5.3 — témoin P68-D-29 : sans dossier de scripts explicite, le conductor voisin du dépôt est trouvé (vie non null)

- attendu: [true]
- obtenu:  [false]

### V6.1 — phase 1 (mission abandonnée, aucun plan fait) : a-faire

- attendu: [a-faire]
- obtenu:  [en-cours]

### V7.2 — la source plantée n'est pas lue : mission inconnu

- attendu: [inconnu]
- obtenu:  [absent]

### V8.1 — copie mutée (âge pris de la date du DAG) détectée : le DAG récent rend la mission running sans verrou

- attendu: [muté|running]
- obtenu:  [ancre absente|absent]

### V9.1 — deux DAG, phases différentes : seul celui sans verrou de phase est abandonnee

- attendu: [MISSION-1:running,MISSION-2:abandonnee]
- obtenu:  [MISSION-1:absent,MISSION-2:absent]

### V9.2 — verrou posé sur l'autre phase : verdicts inversés

- attendu: [MISSION-1:abandonnee,MISSION-2:running]
- obtenu:  [MISSION-1:absent,MISSION-2:absent]

### V9.3 — copie mutée (verrou du compartiment) détectée : les deux DAG se disent vivants

- attendu: [muté|MISSION-1:running,MISSION-2:running]
- obtenu:  [ancre absente|MISSION-1:absent,MISSION-2:absent]

### V9.4 — phase 069 (chaîne) et 69 : même phase

- attendu: [MISSION-69:running]
- obtenu:  [MISSION-69:absent]

### V9.4b — phase en nombre dans le JSON du verrou : écartée

- attendu: [MISSION-69:abandonnee]
- obtenu:  [MISSION-69:absent]

### V9.5 — copie mutée (normPhase identité) détectée : 069 ne désigne plus 69

- attendu: [muté|MISSION-69:abandonnee]
- obtenu:  [ancre absente|MISSION-69:absent]

### V9.6 — 069 périmée (listée en premier) et 69 tenue : vivante

- attendu: [MISSION-69:running]
- obtenu:  [MISSION-69:absent]

### V9.7 — copie mutée (première entrée seule) détectée

- attendu: [muté|MISSION-69:abandonnee]
- obtenu:  [ancre absente|MISSION-69:absent]

### V9.8 — verrou de phase périmé et compartiment tenu : abandonnee (MISSION-1)

- attendu: [abandonnee]
- obtenu:  [absent]

### V9.9 — copie mutée (repli compartiment prioritaire) détectée

- attendu: [muté|running]
- obtenu:  [ancre absente|absent]

### V10.1 — compartiment seul tenu : running

- attendu: [running]
- obtenu:  [absent]

### V10.2 — compartiment périmé sans progrès : abandonnee

- attendu: [abandonnee]
- obtenu:  [absent]

### V10.3 — copie mutée (sans repli) détectée

- attendu: [muté|abandonnee]
- obtenu:  [ancre absente|absent]

### V10.4 — entrée de compartiment absente à côté : V9.1 inchangé

- attendu: [MISSION-1:running,MISSION-2:abandonnee]
- obtenu:  [MISSION-1:absent,MISSION-2:absent]

## Annexe — correction d'accesseur de V5.1 et V5.2, rouge rejoué sur la tête d'avant le code

Après le premier vert, V5.1 et V5.2 lisaient `vie` par un accesseur en `?? "absent"` qui confondait `null` et champ absent : un `null` obtenu s'affichait
`absent`. Les deux assertions lisent désormais `JSON.stringify(vie)|etat` (attendu `null|inconnu`, inchangé). Le rouge a été rejoué sur `e042e25f`
(extrait par `git archive`, suite corrigée posée dedans) : 5 PASS / 25 FAIL, V5.1 et V5.2 obtiennent `[undefined|undefined]` (la lecture des verrous n'existe pas encore).
Le tableau d'obtenus ci-dessus (`absent|absent`) est celui du premier jeu d'accesseurs ; la raison du rouge est la même.

## Annexe — témoin de P68-D-29 (dossier de scripts explicite)

Même lab plat à nœud `running`, `HOME` vide, `readPlanning` rejoué sur le code livré :

- avec un dossier de scripts explicite vide (`scriptsDir`) : `[["inconnu",null]]` (V5.1 vert)
- sans ce dossier (défaut = `plugin/cockpit/scripts` réel, conductor voisin du dépôt) : `[["abandonnee",{"tenu":false,"stale":null,"progressAgeS":null,"ttl":null}]]` — le vrai `driver-lock.sh` du dépôt est trouvé, V5.1 rougirait

Épingler `HOME` ne suffit donc pas ; V5.3 de `test-cockpit-vie.sh` garde ce fait (le conductor voisin est trouvé quand aucun dossier n'est passé).

## Annexe — témoins rouges de la carte Projet (tâche 3, P-VIE)

- Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-projet.sh > sortie 2>&1` (rc=1 ; 57 PASS / 4 FAIL) sur le code de la tâche 2 (`vf-cockpit-project.mjs` inchangé).
- Contrôle positif vert : P-VIE.0 (verrou tenu : la carte `dag-MISSION-1` et son plan désigné restent `active`).
- Le dossier de scripts explicite est posé sur les seuls appels en processus de `Q` : le vrai lanceur de la section O4 en fait le dossier de scripts du module
  (`vf-cockpit.mjs`, `VF_COCKPIT_SCRIPTS_DIR`), un export global l'a fait échouer (O4.0 à O4.7, « page prête dépassée »), corrigé avant ce rouge.

### P-VIE.1 — sans verrou : la carte dag-MISSION-1 est todo et son pied dit « abandonnée, nœuds non refermés »

- attendu: [todo|true]
- obtenu:  [active|false]

### P-VIE.2 — un plan désigné par un nœud running d'une mission abandonnée reste todo

- attendu: [todo]
- obtenu:  [active]

### P-VIE.3 — les détails de la phase disent « Mission : MISSION-1 (abandonnée, nœuds non refermés) »

- attendu: [true]
- obtenu:  [false]

### P-VIE.4 — verrous illisibles (aucun script) : la carte est todo et son pied dit « état inconnu »

- attendu: [todo|true]
- obtenu:  [active|false]
