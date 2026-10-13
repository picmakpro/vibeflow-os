# Mission 2026-10-13 — Phase 46.1 (gouvernance) : exécution de l'armement de G4 et G4′

**Manager :** `vf-dev-manager-p461-exec`
**Feu vert :** Willy, message en session principale, 2026-10-13 (« oui lance les exec sans attendre de
revu ») — exécution sans attendre la revue code owner de la pile ; aucun merge.
**Branche :** `gouvernance/phase-46.1-execution`, partie de `origin/gouvernance/phase-46.1-cadrage` @
`b73885c8` (PR #146), poussée avec suivi amont ; worktree `.claude/worktrees/gouvernance-46-1`.
**Compartiment :** `gouvernance` (`--ws gouvernance` à chaque commande GSD ; gsd-tools 1.14.0 du compte).
**Verrou :** acquis, génération `DRIVER.lock.gen.1791881933.48268`, 0 orphelin.
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
