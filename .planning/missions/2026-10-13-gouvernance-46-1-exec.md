# Mission 2026-10-13 — Phase 46.1 (gouvernance) : exécution de l'armement de G4 et G4′

**Manager :** `vf-dev-manager-p461-exec`
**Feu vert :** Willy, message en session principale, 2026-10-13 (« oui lance les exec sans attendre de
revu ») — exécution sans attendre la revue code owner de la pile ; aucun merge.
**Branche :** `gouvernance/phase-46.1-execution`, partie de `origin/gouvernance/phase-46.1-cadrage` @
`b73885c8` (PR #146), poussée avec suivi amont ; worktree `.claude/worktrees/gouvernance-46-1`.
**Compartiment :** `gouvernance` (`--ws gouvernance` à chaque commande GSD ; gsd-tools 1.14.0 du compte).
**Verrou :** acquis, génération `DRIVER.lock.gen.1791881933.48268`, 0 orphelin ; relâché en fin de
session (attente humaine).
**Issue (session du 2026-10-13 → 2026-10-14) :** `human_needed` — DAG exécuté jusqu'au checkpoint 5b
(plan 46.1-04, Tâche 2) ; `exec-04` (Tâches 2-3) et toute la suite attendent Willy (Q-5b-A, Q-5b-B).
**Issue (reprise du 2026-10-14) :** `human_needed` — rejeu 5b non joué (repos non nul : VS Code
relance des hôtes d'extensions sous `~/BusinessFlow-Lab`) ; CKPT-5b-bis relayé, sans réponse après
~1 h d'attente au premier plan ; verrou relâché.
**Invariants :** `check-mission-invariants.sh` → 3 (SAIN).
**Flags d'enchaînement :** `workflow.auto_advance` et `workflow._auto_chain_active` à `false`, vérifiés
par lecture de `.planning/config.json` (`gsd_run` non résolu sur ce poste).
**Budget :** snapshot de la mission p461-cadrage (close, génération `…1791803429.58344`) remplacé par
un snapshot neuf sous la génération de cette mission (`check-mission-exit.sh --budget-snapshot`).
**design :** off.

## Plan de bataille (DAG `2026-10-13-gouvernance-46-1-exec.dag.json`)

Un plan par vague, dans l'ordre du cadrage (presque tous touchent `planning-hook.sh` : aucun
parallélisme d'exécution) :

```
exec-14 → exec-17 → exec-01 → exec-02 → exec-03 → exec-18
  → revue-5b ∥ audit-5b ∥ nonreg-5b (jalon 1 de P461-D-16)
  → exec-04 [CHECKPOINT : rejeu réel 5b, repos des labs] → exec-05 [CHECKPOINT : armement G4]
  → exec-06 → exec-15 → exec-07 → exec-08 → exec-09 → exec-16 → exec-10
  → revue-6 ∥ audit-6 ∥ nonreg-6 (jalon 2)
  → exec-11 [CHECKPOINT : rejeu réel 6, repos des labs] → exec-12 [CHECKPOINT : armement G4′, P461-D-17]
  → exec-13 (clôture, planning-core v2.11.0 sans release)
  → revue-final ∥ audit-final ∥ verif-461 ∥ nonreg-final (jalon 3) → docs → pr (empilée sur #146)
```

- **Étages :** build par `vf-coder` (`gsd-execute-phase 46.1 --ws gouvernance`, un plan par mandat) ;
  revue et audit en jointure aux deux jalons qui précèdent un armement (coût d'erreur asymétrique :
  un gate armé à faux refus bloque des labs réels), puis en fin de phase ; vérification de phase en fin.
- **Non-régression (P461-D-16) :** base mesurée au plan 14 ; par plan, l'exécuteur rejoue les suites
  nommées ; la découverte complète est un geste du manager aux trois jalons ; la CI Linux fait
  autorité ; tout rouge imputé par rejeu sur le commit parent (charge machine ~6).
- **Checkpoints humains :** remontés à la session principale par `SendMessage(main)`, persistés ici ;
  jamais tranchés par la mission ; nœud gelé sans réponse, le reste avance s'il est indépendant.
- **Risques :** durée (18 plans séquentiels, base ~2-3 h) ; exécuteurs forcés en worktree d'agent
  (rapatriement en fast-forward à chaque plan) ; rouges de durée sous charge ; NFC/ext4 (CI Linux
  seule juge) ; repos des labs.

## Déroulé

1. **exec-14** (vf-coder, `gsd-execute-phase 46.1 --wave 1`, exécuteur en worktree d'agent,
   rapatrié par fast-forward `60468efd..483fb472`, SHA gardés : `BASE-MESURE commit=c702f772` doit
   rester ancêtre). Outil `46.1-CONTROLES.sh` (autotest 87/87 rapporté par l'exécuteur), base
   `46.1-BASE.txt` : `BASE-BILAN suites=109 vertes=101 rouges=8 zero-ok=0 s=14497`, charge 16 → 50
   (pics observés par le manager jusqu'à ~250, processus d'AUTRES sessions : `bfs` sur `/`, suites
   node, etc. — rien de cette mission). `BORNE_MESURE_BASE` (14 400 s) dépassée de 97 s : `sonder` a
   rendu 3, rien tué, la mesure a abouti seule.

   **Décisions du manager (renversables) sur les trois `ask-user` de l'exécuteur :**
   - *Base gardée, non remesurée* : la charge vient d'autres sessions et ne baissera pas sur
     commande ; une base lente rend les plafonds (3 × base) plus larges, jamais plus étroits — risque
     accepté : un ralentissement réel reste masqué jusqu'à 3 × une durée déjà gonflée ; le verdict
     d'une suite reste son code de sortie, pas sa durée.
   - *Dépassement de borne* : consigné, sans effet sur un verdict (exception déclarée du plan).
   - *Huit rouges locaux à la base, dont `test-planning-hook-registered.sh` (suite à gate)* : la CI
     Linux est **verte** sur le même code (`b73885c8`, run 38373075869) ; ces rouges sont classés
     **environnement local** (charge, macOS, worktree), pas défauts du code. Aucune escalade à Willy
     (P461-D-16 : escalade seulement si une suite rouge garde un gate, et la CI la dit verte) ; la
     CI Linux fait autorité pour cette suite, à rejouer en CI après les plans 08 et 10.
2. **exec-17** (rapatrié en fast-forward `f5075506..1d1c9e8a`) : modes `imputer`, `garder-g4`,
   `armement`, `etat-reference`, `jalon`, `empreinte` ; outil figé (`46.1-CONTROLES.sha256`, gel
   `6f77f178` ; empreinte rejouée par le manager après rapatriement : `EMPREINTE ok`, rc 0). Autotest
   193/193 rapporté par l'exécuteur ; rejeu indépendant du manager lancé. **Mineur du plan-check
   fermé** : `garder-g4-mal-forme` scindé en `garder-g4-canal-vide`, `garder-g4-date-forme` et
   `garder-g4-date-invalide` (`2026-13-45`), chacun rouge pour sa seule raison, trois mutants tués
   chacun par son seul cas. `46.1-17-PLAN.md:310` cite encore l'ancien nom : plan exécuté, non
   réécrit (le SUMMARY fait foi).
   **Décision du manager (renversable) :** un rouge qui n'est QUE `duree-plafond` (suite à code 0,
   plafond 3 × base dépassé sous charge — constaté une fois sur `reel-temoin-role`, 99 s pour 81 s,
   charge 15 → 72) est classé **instable (charge)**, consigné et remonté, non bloquant ; tout rouge
   de code de sortie reste imputé par `imputer`.
   Rejeu indépendant du manager : `AUTOTEST-BILAN cas=193 declares=193 echecs=0` (outil `1d1c9e8a`).
3. **exec-01** (rapatrié en fast-forward `32a23042..28fe140f`) : exemption étroite de G4 dans le
   hook, banc G4 à familles de réécriture (`COUVERTURE G4 doit-refuser=51 doit-passer=30 silence=31`,
   `COMPTE G4 faux-refus=0 faux-accept=0` sur copie armée), 8 mutants tués pour leur famille,
   référence, limite (bp), spec §5. CI Linux verte sur `fbd05a04`. Écarts au texte du plan
   acceptés par le manager : phrase « reste permis tant que le verdict tient » remise sur une ligne
   (grep d'acceptation), phrase d'état 5b ajustée, `MUT-G4-R6-REECRITURE` retire la clause
   `len(constats) == 0` (le `if False:` du plan laissait un `SyntaxError`). L'exécuteur n'a pas pu
   rejouer ses deux suites par l'outil (défaut ci-dessous) : rejeu de repli par sections, vert.
4. **fix-outil-01** (quick `261013-owa`, vf-coder inline, deux passes) — défaut CRÉÉ par la phase :
   - `suite|toutes|imputer --detache` inutilisables pour une suite de base ≥ 480 s (la copie
     détachée ré-appliquait `detache-requis` : `DETACHE-FIN rc=64`) ; l'autotest ne l'avait jamais vu
     (base de 4 s dans son cas). Corrigé dans les trois modes (`54936dc9`), trois cas neufs rouges
     sur l'outil d'avant, verts après ; preuve de bout en bout sur les deux suites longues du plan 01
     par l'outil : `test-cloture-gates.sh rc=0 duree=102`, `test-planning-gates.sh rc=0 duree=352`.
   - **Décision du manager (renversable) — regel tracé** : le gel à commit unique (plan 17) n'avait
     aucune voie pour une correction légitime, chaque plan suivant aurait commencé rouge
     (`gel-rouvert`). Un regel est désormais valide s'il ne touche que `.sha256` et porte un trailer
     `Regel-Outil: <id quick> — <raison>` (forme vérifiée, jamais la véracité) ; il est imprimé
     (`EMPREINTE-REGEL …`) avant `EMPREINTE ok … regels=<n>` à la première commande de chaque plan ;
     un regel sans trailer reste `gel-rouvert`. Cinq cas d'autotest neufs, mutants tués (`b284c367`).
     Le premier commit de regel du worker (`e1b5fc94`, sans trailer, jamais poussé) a été retiré de
     l'historique local par le manager (sauvegarde `vf-backup/p461-fix-outil-avant-reecriture`) ;
     regel tracé `f108ef1b`. Rejoué par le manager : `EMPREINTE ok … regels=1`, rc 0.
   - **Défaut du plan 01 fermé** : la phrase de la limite (bp) « qu'un G4 armé aurait refusées » se
     lisait comme un état armé de G4 (`etat-reference` : `ETAT-ECART k4 ligne=1056`) ; reformulée
     (`1b5cba0e`), `etat-reference` rejoué par le manager : `ecarts=0`. La même phrase subsiste dans
     la spec (`docs/superpowers/specs/…`), que `etat-reference` ne lit pas : non touchée.
   - Autotest final rapporté : `cas=201 declares=201 echecs=0` ; rejoué par le manager sur
     `297f978c` : `AUTOTEST-BILAN cas=201 declares=201 echecs=0`.
5. **exec-02** (rapatrié en fast-forward `223e073b..0b2cb951`) : D1 N-5 et A5 (`29e49058`,
   `f3a78f95`), limites (ar), (ax), (bk), recensement READDIR (`66ad38b8`). Suites par l'outil :
   `test-d1-surveillance.sh rc=0`, `test-planning-gates.sh` rouge au premier rejeu (imputé
   `imputable` : fonction neuve `chemin_du_disque` absente du recensement des énumérations,
   `MUT-RECENSEMENT-READDIR` non tué), corrigé dans le plan, vert au rejeu final (`rc=0 duree=353`).
   Faux signaux sur lab sain : `MESURE-FAUX-SIGNAUX-A5 mkdir-copie=3 git=5 outil=0 moteur=0`.
   **Décisions du manager :** (a) l'`imputable` corrigé dans le plan avant livraison n'est pas
   escaladé (état livré vert ; aucune suite d'un gate armé n'est rouge) ; (b) unité posée d'emblée
   close (SUMMARY présent) toujours aveugle : accepté, écrit dans (ar)/(bk) ; (c) deux faux signaux
   mesurés mais **non nommés** en limite — `git checkout` qui retire une unité référencée (N-5,
   `suppression-git=3`) et contournements A5 d'un lab dont le journal ne porte que des lignes
   `moteur` — : P461-D-05a exige de les nommer ; reportés au lot de correction d'avant armement
   (`fix-5b`), sans changement de comportement.
6. **exec-03** (rapatrié en fast-forward `78574909..f517c934`) : `verifier-releve.sh` (21 règles
   marquées, 21 mutants de règle + 2 globaux tués), suite neuve `test-verifier-releve.sh` (95 OK ·
   0 KO, rejouée par le manager après rapatriement : identique), README (110 suites). Limite (bu)
   levée côté script ; `COMMIT-REJOUE` non confronté au dépôt (l'ascendance relève du mode
   `armement` de l'outil, plan 17).
7. **exec-18** (rapatrié en fast-forward `9edefba0..9c34175e`) : chaîne réelle sur lab synthétique
   (`RELEVE-CHAINE … coherence=ok` ×3), fixtures des relevés réels de la 46 (étape 5 refusée
   `faux-refus=349`, étape 6 `faux-refus=343` + `commit-absent` : le script refuse bien les relevés
   qui ne sont pas armables), couverture 21/21/21, `BASE-AJOUT … test-verifier-releve.sh s=11 plan=18`
   inscrite par l'outil. Base de 11 s : plafond 3 × base étroit sous charge (règle `duree-plafond`
   seul = instable s'applique).
8. **revue-5b ∥ audit-5b ∥ nonreg-5b** (diff `b73885c8..00d43cd2`, régime plein) :
   - revue (vf-reviewer) : **PASS**, 7 mineurs (garde `d1-n5-forme` sans mutant ; faux signal A5
     sur référence sortie de la fenêtre de 4 Mio ; exemption qui teste VERDICT/CLOTURE sous le nom
     NFC ; `int()` > 4300 chiffres ; `chemin-machine` en sous-chaîne ; `EMPREINTE-DIVERGENTE` non
     lue ; plancher auto-déclaré) ;
   - audit (vf-auditer) : **OPEN_THREATS**, aucun HIGH — F-1 MEDIUM (ligne géante du journal :
     SessionStart muet, rc 73, régression du diff), F-2 MEDIUM (relevé réel retouché rendu
     armable), F-3 MEDIUM conditionnel (= revue n°3, fail-open sur FS sensible à la normalisation),
     F-4 LOW (= revue n°4) ; 17 menaces des plans vérifiées (3 ouvertes ou partielles : F-1, F-2) ;
   - jalon 1 lancé en parallèle puis **arrêté par le manager** (87/110 suites, 6 rouges tous
     `rouge-sur-base=oui`) : le lot de correction touche `planning-hook.sh`, le jalon aurait été
     périmé (`jalon-perime`) ; il sera rejoué sur le code corrigé.
   **Décisions du manager (renversables)** : lot unique `fix-5b` (quick, vf-coder) qui ferme
   H1 (forme validée avant toute E/S, F-1), H2 (I/O sur le nom du disque, F-3), H3 (mutant de
   `d1-n5-forme`), H4 (faux signal de fenêtre mesuré et nommé), H5 (faux signaux et course
   nommés), V1-V3, et V4 = F-2 (a) ligne qui contient un jeton sans le commencer = malformée,
   (b) `REJEU-ETAPE` recoupé avec les `COMPTE` de l'émetteur, (c) plancher auto-déclaré nommé en
   limite, un `--lab` par lab réel exigé au prédicat des plans 05 et 11. L'auditeur avait mis F-2
   en `ask-user` (« le contrat de grammaire change ») : tranché par le manager, car (a) et (b)
   appliquent la règle de P461-D-06 (« toute ligne malformée rougit ») sans en créer.
9. **fix-5b** (quick `261013-t18`, planificateur + exécuteur inline, 12 commits `2ff2fa90..071c517b`
   + docs `0cc5ad6a`) : H1-H5 et V1-V4 fermés, chacun avec un cas rouge avant / vert après et son
   mutant (`MUT-D1-N5-FORME-CLE`, `MUT-D1-N5-FORME`, `MUT-G4-REECRITURE-DISQUE`, `MUT-D1-FENETRE`,
   `MUT-RELEVE-ENTIER-BORNE`, `MUT-RELEVE-MACHINE-SOUS-CHAINE`, `MUT-RELEVE-REJEU-DIVERGENT`,
   `MUT-RELEVE-JETON-DEPLACE`, …). Sonde d'attaque F-1 : `rc=73` avant, `rc=0 dt=1.1s` après (130 000
   puis 520 000 composants). V4 (b) suit la règle réelle de l'émetteur (faux-refus et
   refus-conforme-modèle égaux à la somme des `COMPTE`, faux-accept ≥). Limite neuve (bx) (plancher
   auto-déclaré). Suites par l'outil : `test-d1-surveillance rc=0`, `test-cloture-gates rc=0`,
   `test-planning-gates rc=0 duree=1488`, `test-verifier-releve rc=0` + `SUITE-ECART duree-plafond
   86 > 33` (instable : la suite a grossi de 55 % et la base de 11 s est gelée ; règle du manager) ;
   rejouée par le manager : 156 OK · 0 KO. `etat-reference` `ecarts=0`, `EMPREINTE ok … regels=1`.
   **Décisions du manager sur les `ask-user` du lot :**
   - coût de N-5 sur ~19 000 clés conformes forgées (SessionStart > 8 s, muet) : **accepté comme
     limite nommée** dans (bn) (forge du journal par `Bash`, même classe que (bn)) ; D1 n'est jamais
     armé ;
   - les plans 04, 05, 11, 12 prescrivent de citer dans le relevé des lignes à jeton et le nom du
     relevé, que la règle V4 (a) rougit (`jeton-deplace`) : **plans à corriger avant exécution**,
     après un plan-check des plans restants contre le code livré (les plans 06 et 07 réservent aussi
     (bv)/(bw), à insérer avant (bx)) ;
   - `46.1-CONTROLES.sh releve` refuse encore `/home/` en sous-chaîne : **pas de regel** ; s'il
     rougit sur un relevé réel, la correction se fera alors ;
   - base gelée de `test-verifier-releve.sh` (11 s) : **non rebasée**, `duree-plafond` seul =
     instable.
10. **plancheck-restants → fix-plans-restants** (re-validation des plans écrits avant les faits) :
    deux `gsd-plan-checker` frais contre le code livré : **ISSUES** — angle A (04, 05, 11, 12, 13) :
    5 bloquants, 3 majeurs (relevés prescrits qui rougissent `jeton-deplace`, banc G4 du plan 05
    lancé au premier plan alors que sa base est 1512 s, lettres de limites) ; angle B (06, 15, 07,
    08, 09, 16, 10) : 3 bloquants (`test-planning-hook-registered.sh` refusé par l'outil car rouge
    à la base, suites longues non détachées, collision de la lettre (bx) au plan 10), 15 PASSED.
    Correction du texte des plans par vf-coder (12 commits `c0c976e5..1eda37f2`, une coupure API
    « session limit » reprise par réveil, rien perdu), plan-check de contrôle : A, C, D, E, G, H
    tenues, F avait créé des dossiers de détache dupliqués (scratchpad PARTAGÉ entre agents) ;
    correction n°2 (11 commits jusqu'à `66fe1fa9`) : dossier neuf, unique, absolu
    `p461-<plan>-t<tâche>-<objet>` à chaque lancement ; attente du rejeu réel 6 sur la fin du
    processus. Doublons de `--detache=` relus par le manager : aucun (hors gabarits de prose).
    **Décisions du manager :** `test-planning-hook-registered.sh` → verdict = CI Linux lue par le
    manager avant le plan suivant (07, 08, 09, 16, 10) ; lettres (bv) 06, (bw) 07, (by)/(bz) 10 ;
    le jalon 1 n'est exigé qu'avant le checkpoint d'armement du plan 05 (P461-D-16 tel qu'écrit au
    plan 04) : exec-04 part pendant que le jalon tourne (exec-04 ne touche ni `planning-hook.sh`
    ni `hooks.json`, le jalon ne périme pas).
11. **exec-04, Tâche 1** (rapatriée en fast-forward `9801ff84..8379e1af`, trois `Gate-Touche:`) :
    constructeur G4 de `rejeu-gates.sh` à réécritures, `MUT-REJEU-G4-REECRITURE` tué, (bu) levée ;
    `test-rejeu-gates.sh rc=0` (101 OK), `RELEVE-CHAINE … coherence=ok` ×3, `etat-reference`
    `ecarts=0` ; constantes inchangées (G3 armé, G4 et G4′ en observation).
    **Checkpoint de la Tâche 2 atteint — en attente de Willy** (voir § Checkpoints en attente).
12. **nonreg-5b — jalon 1** (geste du manager, P461-D-16) : `46.1-CONTROLES.sh toutes --contre-base`
    détaché, lancé sur `9cbdf16e` (après fix-5b) : `TOUTES-BILAN suites=110 vertes=103 rouges=7
    zero-ok=0 s=4752` ; les 7 rouges sont tous `rouge-sur-base=oui` (préexistants, verts en CI
    Linux) ; `test-planning-hook-registered.sh`, rouge à la base sous charge, est **vert** ici
    (rouge de base = instable de charge). Pendant le rejeu, le dépôt a reçu des commits de plans
    (texte) et, à 00:49:33, le fast-forward de 46.1-04 Tâche 1 (`rejeu-gates.sh` et sa suite) : seul
    la dernière minute du rejeu (suites `plugin/skill-creator`, `scripts/tests`) a tourné sur ces
    fichiers ; les suites de `planning-core` ont tourné sur le code de `9cbdf16e`, et l'exécuteur de
    04 a rejoué `test-rejeu-gates.sh` sur le code neuf (`rc=0`). `planning-hook.sh` et `hooks.json`
    inchangés depuis `9cbdf16e`. Consigné dans `46.1-JALONS.txt` ; `46.1-CONTROLES.sh jalon 1` →
    `JALON-VERIF 1 ok`.

## Checkpoints en attente (relayés à la session principale)

### CKPT-5b — plan 46.1-04, Tâche 2 (`checkpoint:decision`, `gate="blocking-human"`), posé le 2026-10-14

Repos mesuré par l'exécuteur (`lsof -n -F pn`, filtre éprouvé sur entrée synthétique, `LC_ALL=C`) :
`~/jarvis-keystone` **0 processus** ; `~/BusinessFlow-Lab` **30 processus** dont le répertoire
courant est dans le lab, aucun fichier ouvert (node 16, zsh 3, uv 3, python3.11 3, Code Helper
(Plugin) 2, binaires Claude Code `2.1.296` ×2 et `2.1.292` ×1 — sessions Claude ouvertes dans le
lab). Rien arrêté, aucun lab lu.

- **Q-5b-A — rejeu réel 5b** (options du plan, verbatim) : `rejeu-5b-oui` — « Rejeu réel 5b en
  lecture seule, labs au repos : une lecture, plus au plus une seconde lecture uniquement sur
  divergence d'empreinte d'arbre ; aucun attendu ajouté par l'exécuteur » ; `rejeu-5b-non`
  (défaut) — « Repli sûr : aucun rejeu réel ». Sans réponse explicite : `rejeu-5b-non`.
- **Q-5b-B — repos de `~/BusinessFlow-Lab`** (le rejeu n'est joué que si 0 processus) : (a) Willy
  ferme lui-même les sessions ouvertes dans ce lab, la mission re-mesure le repos ; (b) Willy
  autorise la mission à arrêter ces processus pour CE rejeu seulement ; (c) aucun arrêt : repli,
  pas de rejeu 5b, donc pas d'armement de G4 dans cette exécution (P461-D-17 le fera trancher en
  fin de phase).
- **Recommandation du manager :** `rejeu-5b-oui` + (a) — ce sont des sessions de travail de Willy
  (dont des `claude` actifs) : les fermer lui-même évite de perdre un travail en cours ; (b) reste
  possible s'il le préfère.

### Réponses de Willy au CKPT-5b (relayées par la session principale, 2026-10-14)

Willy, AskUserQuestion session principale, 2026-10-14, mot pour mot :
- Q-5b-A : « rejeu-5b-oui (Recommandé) ».
- Q-5b-B : « (b) La mission arrête » — libellé de l'option présentée : « Tu autorises la mission à
  arrêter ces processus, pour CE rejeu seulement. Une session Claude active peut y perdre son
  travail en cours. »

Cadre transmis avec les réponses (coordinateur, session principale, 2026-10-14) : arrêt borné à CE
rejeu 5b et aux seuls processus dont le répertoire courant ou un fichier ouvert est sous
`~/BusinessFlow-Lab` ; SIGTERM d'abord, fin propre attendue, SIGKILL seulement sur les restants et
tracé ; jamais un processus hors de ce lab, jamais `~/jarvis-keystone` ; ne vaut pas pour le rejeu 6
ni aucun autre ; liste exacte (PID, commande, répertoire courant) inscrite ici AVANT l'arrêt ;
repos re-mesuré juste avant et après le rejeu ; sessions arrêtées non relancées (Willy les
rouvrira) ; rejeu en lecture seule sur copies, empreintes sha256 avant/après, seconde lecture
seulement sur divergence d'empreinte d'arbre, aucun attendu ajouté ; checkpoint d'armement de G4
(plan 05) remonté à la session principale avant tout armement.

Reprise : verrou ré-acquis (génération `DRIVER.lock.gen.1791969153.15231`, 0 orphelin),
invariants 3 (SAIN), snapshot de budget reposé sous cette génération.

### Processus arrêtés au CKPT-5b

Cadre : autorisation de Willy (AskUserQuestion session principale, 2026-10-14, Q-5b-B « (b) La mission arrête »), valable pour CE rejeu 5b seulement et pour les seuls processus dont le répertoire courant ou un fichier ouvert est sous `~/BusinessFlow-Lab`. Liste mesurée le 2026-10-14 (UTC 09:15:20) par `lsof -n -F pcfn` (LC_ALL=C), AVANT tout signal. Aucun ancêtre du processus de la mission n'y figure ; `~/jarvis-keystone` : 0 processus.

| Rang | PID | Commande | Répertoire courant | Fichiers ouverts sous le lab |
|------|-----|----------|--------------------|------------------------------|
| 1 | 28786 | Code Helper (Plugin) | `~/BusinessFlow-Lab` | 0 |
| 2 | 41066 | zsh | `~/BusinessFlow-Lab` | 0 |
| 3 | 41508 | 2.1.292 | `~/BusinessFlow-Lab` | 0 |
| 4 | 42249 | node | `~/BusinessFlow-Lab` | 0 |
| 5 | 42266 | node | `~/BusinessFlow-Lab` | 0 |
| 6 | 42515 | uv | `~/BusinessFlow-Lab` | 0 |
| 7 | 42553 | node | `~/BusinessFlow-Lab` | 0 |
| 8 | 43007 | node | `~/BusinessFlow-Lab` | 0 |
| 9 | 43011 | python3.11 | `~/BusinessFlow-Lab` | 0 |
| 10 | 56239 | zsh | `~/BusinessFlow-Lab` | 0 |
| 11 | 57041 | 2.1.296 | `~/BusinessFlow-Lab` | 0 |
| 12 | 57864 | node | `~/BusinessFlow-Lab` | 0 |
| 13 | 57872 | node | `~/BusinessFlow-Lab` | 0 |
| 14 | 58086 | node | `~/BusinessFlow-Lab` | 0 |
| 15 | 58129 | node | `~/BusinessFlow-Lab` | 0 |
| 16 | 58148 | node | `~/BusinessFlow-Lab` | 0 |
| 17 | 58245 | node | `~/BusinessFlow-Lab` | 0 |
| 18 | 58257 | uv | `~/BusinessFlow-Lab` | 0 |
| 19 | 58354 | python3.11 | `~/BusinessFlow-Lab` | 0 |
| 20 | 85454 | zsh | `~/BusinessFlow-Lab` | 0 |
| 21 | 86082 | 2.1.296 | `~/BusinessFlow-Lab` | 0 |
| 22 | 86940 | node | `~/BusinessFlow-Lab` | 0 |
| 23 | 86957 | node | `~/BusinessFlow-Lab` | 0 |
| 24 | 87208 | node | `~/BusinessFlow-Lab` | 0 |
| 25 | 87233 | node | `~/BusinessFlow-Lab` | 0 |
| 26 | 87255 | node | `~/BusinessFlow-Lab` | 0 |
| 27 | 87357 | uv | `~/BusinessFlow-Lab` | 0 |
| 28 | 87396 | node | `~/BusinessFlow-Lab` | 0 |
| 29 | 87406 | python3.11 | `~/BusinessFlow-Lab` | 0 |
| 30 | 97423 | Code Helper (Plugin) | `~/BusinessFlow-Lab` | 0 |

Total : 30 processus. Plan d'arrêt : SIGTERM à ces PID exactement, sondage borné (~30 s), SIGKILL seulement sur ceux qui restent, tracé ci-dessous. Aucune session arrêtée n'est relancée.

#### Signaux envoyés (première vague)

Chaque PID de la liste ci-dessus a été revalidé (même répertoire courant sous le lab) juste avant le signal.

- SIGTERM envoyé à 28 PID de la liste. Deux autres n'ont pas reçu de signal : le PID 58148 (`node`) était déjà sorti à la revalidation, le PID 58354 (`python3.11`) est sorti entre la revalidation et le signal (`kill` en échec, processus absent).
- Fin propre au SIGTERM dans le sondage de 30 s : 25 des 28 processus signalés.
- Restants à 30 s : 3 shells interactifs `zsh` (PID 41066, 56239, 85454), qui ignorent SIGTERM. SIGKILL envoyé à ces trois PID, et à eux seuls.
- Mesure de repos juste après : 0 processus sous `~/jarvis-keystone` ; 2 NOUVEAUX processus `Code Helper (Plugin)` sous `~/BusinessFlow-Lab` (PID 20255 et 20380, répertoire courant `~/BusinessFlow-Lab`, aucun fichier ouvert), absents de la liste d'origine : relancés par l'éditeur après l'arrêt des premiers. Même lab, même rejeu, même catégorie que la liste d'origine : ils sont consignés ici AVANT tout signal, puis traités de la même façon (SIGTERM, puis SIGKILL sur un éventuel restant).

#### Signaux envoyés (deuxième vague : les deux processus relancés)

- SIGTERM aux PID 20255 et 20380 (`Code Helper (Plugin)`), fin propre au premier sondage (2 s), aucun SIGKILL.
- Mesure de repos juste après : 2 NOUVEAUX `Code Helper (Plugin)` sous `~/BusinessFlow-Lab` (PID 23854 et 23857, répertoire courant `~/BusinessFlow-Lab`, aucun fichier ouvert), de nouveau absents de la liste. Leur processus parent n'est pas dans le lab : c'est Visual Studio Code, qui relance ses hôtes d'extensions tant que le dossier du lab est ouvert dans une fenêtre. Fermer cette fenêtre ou cette application sort de l'autorisation (processus hors du lab) : la mission n'y touche pas.
- Dernière tentative avant repli : SIGTERM à ces deux PID puis mesure immédiate (troisième vague, tracée ci-dessous). Si le repos n'est pas nul à la mesure qui précède le rejeu, la branche REPLI du plan s'applique (motif `repos-non-nul`) et rien n'est lu.

#### Signaux envoyés (troisième vague) et arrêt de la tentative

- SIGTERM aux PID 23854 et 23857 (`Code Helper (Plugin)`, listés et commités avant le signal), fin propre au premier sondage (2 s), aucun SIGKILL.
- Mesure immédiate : 2 NOUVEAUX `Code Helper (Plugin)` sous `~/BusinessFlow-Lab` (PID 24759 et 24763), relancés par Visual Studio Code (processus parent hors du lab). Ces deux-là n'ont reçu AUCUN signal : la mission s'arrête là. Les arrêter plus loin ne ferait que les voir relancés, et viser le processus parent sort de l'autorisation (processus hors du lab).
- Bilan des signaux de l'ensemble : SIGTERM 32 PID (28 + 2 + 2) ; fin propre 29 ; SIGKILL 3 (les `zsh` 41066, 56239, 85454) ; 2 PID sortis d'eux-mêmes avant signal (58148, 58354). Le rejeu 5b n'est pas joué (branche de repli, motif `repos-non-nul`) ; aucun lab n'a été lu ; aucune session arrêtée n'est relancée (Willy rouvrira les siennes).

### Issue de la reprise du CKPT-5b (exec-04 Tâche 3, 2026-10-14) — rejeu 5b NON JOUÉ

Liste des processus visés commitée avant chaque vague (`ada80476`, `55c4b602`, `26b0332d`,
`63224122`). Vague 1 : SIGTERM à 28 PID, 25 fins propres, SIGKILL sur 3 `zsh` interactifs (41066,
56239, 85454) ; 2 PID sortis seuls avant le signal. Vagues 2 et 3 : VS Code (processus parent HORS
du lab) relançait aussitôt deux hôtes d'extensions `Code Helper (Plugin)` dont le répertoire
courant est sous `~/BusinessFlow-Lab` (20255, 20380 ; 23854, 23857, arrêtés par SIGTERM). Après la
vague 3, deux nouveaux hôtes (24759, 24763, parent VS Code) : **non signalés** (le parent est hors de
l'autorisation) ; ils restent en vie (constaté par le manager). Repos juste avant le rejeu :
`~/BusinessFlow-Lab` 2, `~/jarvis-keystone` 0 → branche REPLI du plan, `REJEU-NON-JOUE repos-non-nul`
(`c0898545`), aucune lecture des labs, aucune empreinte, aucune constante touchée. Sessions
arrêtées non relancées. `test-planning-gates.sh rc=0`, `releve` → `RELEVE-COHERENCE ok`,
`invariants` `ecarts=0`. SUMMARY `8db1e15d`.

**CKPT-5b-bis (posé le 2026-10-14) — en attente de Willy** : (a) Willy ferme la fenêtre VS Code
qui tient `~/BusinessFlow-Lab` ouvert (et tout autre outil qui y relance des processus), puis la
mission rejoue la Tâche 3 du plan 04 sous ses réponses du 2026-10-14 (à confirmer : vaut-elle pour
cette nouvelle tentative du même rejeu 5b ?) ; (b) Willy autorise l'arrêt de la fenêtre VS Code
elle-même (processus hors du lab : autorisation plus large) ; (c) en rester au repli : le plan 05 ne
présentera que « ne pas armer » G4, la phase continue vers G4′, P461-D-17 tranchera en fin de phase.
Recommandation du manager : (a).

## État à la remise (2026-10-14)

- **Plans livrés :** 14, 17, 01, 02, 03, 18 (6/18) + 46.1-04 Tâche 1. Lots quick : `261013-owa`
  (outil de contrôle), `261013-t18` (fix-5b). Plans 04-13 et 16 re-validés et corrigés.
- **Gates :** G3 armé (Phase 46) ; **G4 et G4′ en observation** — rien n'a été armé.
- **Juges :** revue-5b PASS (7 mineurs) ; audit-5b OPEN_THREATS sans HIGH (3 MEDIUM, 1 LOW) → tous
  fermés par fix-5b ; plan-checks : ISSUES → corrigés → contrôle (2 points) → corrigés.
- **Non-régression :** base 109 suites (8 rouges locaux, verts en CI) ; jalon 1 : 110 suites, 103
  vertes, 7 rouges préexistants, 0 imputable (`JALON-VERIF 1 ok`). CI Linux verte sur chaque push,
  dernier `7ff70821`.
- **Branche :** `gouvernance/phase-46.1-execution`, poussée. Aucune PR encore (nœud `pr` en fin de
  DAG). Aucun merge, tag ni release.

## Reprise (pour la relance)

1. Réponses de Willy à Q-5b-A et Q-5b-B (verbatim, canal + date).
2. Si (a) ou (b) : re-mesure du repos ; nouveau `vf-coder` sur `exec-04` avec le champ `reprise`
   (`plan_id 46.1-04`, `checkpoint` Tâche 2, `gate blocking-human`, `attendu` = options du plan,
   `reponse_humaine` verbatim, `taches_faites` = Tâche 1 `8379e1af`) → Tâche 3 (rejeu ou repli),
   puis `exec-05` (checkpoint d'armement de G4 : jalon 1 déjà consigné, `JALON-VERIF 1 ok`).
3. Puis 06, 15, 07, 08, 09, 16, 10, revue-6 ∥ audit-6 ∥ jalon 2, 11, 12 (checkpoints), 13, étage
   final, docs, PR empilée sur #146.

## Décompte (mandats émis par le manager, blocs typés reçus)

Dispatches : 15 — vf-coder 10 (exec-14, exec-17, exec-01, fix-outil-01, exec-02, exec-03,
exec-18, fix-5b, fix-plans-restants, exec-04), vf-reviewer 1, vf-auditer 1, gsd-plan-checker 3 ;
reprises par `SendMessage` : 3 (fix-outil-01 passe 2, fix-plans-restants réveil après coupure API
et correction n°2). Tours de revue : 1 (revue-5b) ; tours d'audit : 1 ; tours de plan-check : 2.
`subagent_tokens` des blocs typés : exec-14 680 873 ; exec-17 494 297 ; exec-01 317 259 ;
exec-02 328 678 ; exec-03 344 433 ; exec-18 244 807 ; audit-5b 201 081 ; fix-5b 1 019 259
(planificateur 495 508 + exécuteur 523 751) ; exec-04 200 754 ; fix-outil-01, revue-5b,
fix-plans-restants : 0 déclaré. Usage rapporté par le harnais pour les mandats sans compte : fix-outil
143 504 + 178 897, revue 304 882, plan-checks 190 015 + 116 815 + 213 904, fix-plans 251 314 + 290 713.

## Preuves E6

Relayées verbatim des blocs typés `vf-coder`, par sprint :

```json
{
 "preuves": [
  {"verdict": "recette", "preuve": "amont", "sprint": "exec-14"},
  {"verdict": "autotest", "preuve": "amont-agent", "detail": "AUTOTEST-BILAN cas=87 declares=87 echecs=0, rapporté par le gsd-executor, non rejoué par moi", "sprint": "exec-14"},
  {"verdict": "recette", "preuve": "amont", "sprint": "exec-17"},
  {"verdict": "recette", "preuve": "amont", "sprint": "exec-01"},
  {"verdict": "recette", "preuve": "amont", "sprint": "fix-outil-01 (passe 1)"},
  {"verdict": "autotest-apres", "commande": "bash .planning/workstreams/gouvernance/phases/VFDO-46.1-armement-de-g4-et-g4/46.1-CONTROLES.sh --autotest", "exit_code": 1, "sha": "54936dc9", "sprint": "fix-outil-01 (passe 1)"},
  {"verdict": "autotest-mutant-avant-fix", "commande": "CONTROLES-mutant-avant-fix.sh --autotest --sans-reel (scratchpad)", "exit_code": 1, "sha": "54936dc9", "sprint": "fix-outil-01 (passe 1)"},
  {"verdict": "e2e-suite-detachee", "commande": "46.1-CONTROLES.sh suite … test-cloture-gates.sh --duree-max=base --detache=… puis sonder", "exit_code": 0, "sha": "54936dc9", "sprint": "fix-outil-01 (passe 1)"},
  {"verdict": "empreinte", "commande": "46.1-CONTROLES.sh empreinte", "exit_code": 1, "sha": "e1b5fc94", "sprint": "fix-outil-01 (passe 1)"},
  {"verdict": "recette", "preuve": "amont", "sprint": "fix-outil-01 (passe 2)"},
  {"verdict": "autotest-final", "commande": "bash …/46.1-CONTROLES.sh --autotest", "exit_code": 0, "sha": "1b5cba0e", "sprint": "fix-outil-01 (passe 2)"},
  {"verdict": "empreinte", "commande": "bash …/46.1-CONTROLES.sh empreinte", "exit_code": 0, "sha": "f108ef1b", "sprint": "fix-outil-01 (passe 2)"},
  {"verdict": "suite-detachee-gates", "commande": "46.1-CONTROLES.sh suite … test-planning-gates.sh --duree-max=base --detache=… puis sonder", "exit_code": 0, "sha": "f108ef1b", "sprint": "fix-outil-01 (passe 2)"},
  {"verdict": "recette", "preuve": "amont", "sprint": "exec-02"},
  {"verdict": "suite:test-d1-surveillance.sh", "commande": "46.1-CONTROLES.sh suite plugin/planning-core/scripts/tests/test-d1-surveillance.sh (exiges de la tâche 2) --montre", "exit_code": 0, "sha": "f3a78f95", "sprint": "exec-02"},
  {"verdict": "suite:test-planning-gates.sh", "commande": "46.1-CONTROLES.sh suite plugin/planning-core/scripts/tests/test-planning-gates.sh --detache", "exit_code": 0, "sha": "66ad38b8", "sprint": "exec-02"},
  {"verdict": "recette", "preuve": "amont", "sprint": "exec-03"},
  {"verdict": "recette", "preuve": "amont", "sprint": "exec-18"},
  {"verdict": "recette", "preuve": "amont", "sprint": "fix-5b"},
  {"verdict": "recette", "preuve": "amont", "sprint": "exec-04 (Tâche 1)"},
  {"verdict": "banc G4 (cité de 46.1-01-SUMMARY.md)", "preuve": "amont", "detail": "COMPTE G4 faux-refus=0 faux-accept=0 ; COUVERTURE G4 doit-refuser=51 doit-passer=30 silence=31", "sprint": "exec-04 (Tâche 1)"},
  {"verdict": "MUT-REJEU-G4-REECRITURE", "preuve": "amont", "detail": "tué : original « COMPTE G4 faux-accept=0 », mutant « COMPTE G4 faux-accept=1 » sur l'unité à verdict périmé", "sprint": "exec-04 (Tâche 1)"},
  {"verdict": "constantes ARMEMENT_*", "preuve": "amont", "detail": "inchangées : ARMEMENT_G3 armed, ARMEMENT_G4 observe, ARMEMENT_G4P observe", "sprint": "exec-04 (Tâche 1)"},
  {"verdict": "critères d'acceptation Tâche 1 (exécuteur)", "preuve": "amont", "detail": "limite (bu) : 0 ligne ; entrée (\"bu\",) : 0 ; verifier-releve.sh --etape= : 1 ; check-machine-paths.sh vert, 2003 fichiers", "sprint": "exec-04 (Tâche 1)"}
 ]
}
```

Verdicts des hooks moteur relayés : `{"code_review":"absent","nyquist":"absent","secure":"absent"}` pour
chaque sprint (aucun hook vu). `estimate`/`actuals` : absents (aucun plan ne porte `estimate:`).

## Next step

Relayer CKPT-5b-bis à Willy ; sur (a) ou (b), nouveau `vf-coder` sur `exec-04` (Tâche 3 rejouée,
relevé de repli remplacé par le relevé du rejeu) ; sur (c), `exec-05` au checkpoint « ne pas armer ».
Puis checkpoint d'armement de G4 (plan 05) remonté à la session principale avant tout armement.
