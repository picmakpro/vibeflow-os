# 47-SCOUTING — état des lieux du code livré avant cadrage de la Phase 47

> Mission `vf-dev-manager-p47-cadrage`, nœud `scouting-47`, 2026-10-12. Lecture du code seule : aucune suite lancée, aucun
> lab lu, aucun hook posé, aucun `git` qui écrit. Racine des chemins : le worktree `agent-a27d54e8a8701d01e` (branche
> `gouvernance/phase-47-cadrage`, HEAD `78808126`, tête de la Phase 46 exécutée). Abréviations : `PC` = `plugin/planning-core`,
> `HOOK` = `PC/scripts/planning-hook.sh` (3 558 l.), `REF` = `PC/references/modele-cycles.md` (1 553 l.),
> `SPEC` = `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md`, `P46` = le dossier de phase de la 46.
> Les relevés de la 46.1 sont lus en lecture seule : `46.1-SCOUTING.md` sur `origin/gouvernance/phase-46.1-cadrage`
> (`2840fa5f`) ; **`46.1-CONTEXT.md` (P461-D-01..15, ARMG-01..10) n'existe que sur la branche locale
> `gouvernance/phase-46.1-cadrage`, commit `8519c402`, non poussé** — cité `461-CTX`. Rien n'est tranché ici.

## S1. Hook central : modes, ordre des gates, armement, fail-closed, G2, canary, pré-filtre

**Lanceur et modes.** Une seule commande enregistrée sous six entrées (`PC/hooks/hooks.json:17-20` SessionStart sans matcher,
`:39-49` PreToolUse matcher `Write|Edit|NotebookEdit|Bash|Agent|Task|SubagentHandback` timeout 20, `:51-61` SubagentStop,
`:62-72` CwdChanged, `:73-83` FileChanged). Le cœur Python reçoit quatre arguments positionnels (`HOOK:86` : transport,
XDG_CACHE_HOME, HOME, `--classer|--juges`). Aiguillage par `hook_event_name` (`HOOK:11-21`, constantes `HOOK:120-125`,
`evenement_de` `HOOK:3441-3447` : absent = PreToolUse, inconnu = silence). Contrat par événement :
- PreToolUse : gates G1…G7, rôle, G3, G4, G4′(sur `SubagentHandback`) ; refus `permissionDecision: deny` code 0
  (`sortie_refus` `HOOK:1176-1181`, `hookEventName` codé en dur `HOOK:1178`) ; avis `additionalContext` (`HOOK:1184-1188`).
- SubagentStop : repli G4′ hors mode auto, `decision: block` code 0 (`HOOK:1200-1204`, `mode_subagent_stop` `HOOK:3316-3327`).
- SessionStart / CwdChanged / FileChanged : D1, ne refusent jamais (`MODES_EVENEMENT` `HOOK:3420-3425`, modes `HOOK:3377-3417`).

**Phases de `main` (`HOOK:3462-3551`).** Phase A (adhésion inconnue) : payload illisible → `exit 3` (`HOOK:3475-3477`) ;
`AdhesionIndeterminee` → 3 en PreToolUse, 0 ailleurs (`HOOK:3496-3497`) ; exception d'analyse → décision dans le doute
(PreToolUse seul, `HOOK:3498-3509`, `decider_dans_le_doute` `HOOK:385`) ; non adhérent → `exit 0` (`HOOK:3511`). Le code non nul
est tranché par la couche shell : fail-closed sous adhésion (en-tête `HOOK:27-37`). Phase B : PreToolUse évalue `evaluer_gates`
par forme de cible (`HOOK:3515-3525`) puis, si passage, `inscrire_intentions` (D1, `HOOK:3528`) ; erreur → deny (`HOOK:3543-3545`) ;
SubagentStop erreur → `erreur_subagent_stop` (block si armé, `HOOK:3428-3438`, `:3546-3547`) ; D1 erreur → silence (`HOOK:3549`).

**Ordre des gates.** `evaluer_gates` (`HOOK:2785-2805`) : (1) cohérence de la table (`armement_valide`, `HOOK:2790`) — sinon
refus de tout, Bash compris ; (2) G2 avertit (`HOOK:2794`, hors entonnoir) ; (3) `GATES_A_VERDICT` = G6, G5, G1, G7, ROLE, G3,
G4, G4P (`HOOK:2774`), chacun protégé (`evaluer_protege` `HOOK:2777-2782` : exception = Verdict d'erreur) ; (4) `decider`
(`HOOK:1456-1484`) : armé → refus sauf dérogation nominative (consommée seulement si la décision finale passe, `HOOK:1476-1484`) ;
observe → `observer` au journal d'observation (`HOOK:1321`), rien au modèle.

**Table d'armement.** Constantes une par ligne (`HOOK:133-140`) : G6, G5, G1, G7, ROLE, G3 `armed` ; G4 et G4P `observe` ;
`G2_MODE = "avertit"` (`HOOK:141`) ; `ORDRE_ETAPES = (("G6","G5"),("G1",),("G7",),("ROLE",),("G3","G4"),("G4P",))` (`HOOK:142`) ;
`TABLE_ARMEMENT` (`HOOK:143-144`). `armement_valide` (`HOOK:551-573`) : valeurs `observe|armed`, G6 = G5, G4 armé ⇒ G3 armé
(scission 5a/5b), une étape commencée exige la précédente armée en entier. Table de la référence : `REF:1129-1138`.

**Résolution du rôle.** `evaluer_role` (`HOOK:2610-2645`) : identité = `agent_id` ET `agent_type` non vides, sinon fil principal
(aucun verdict de rôle) ; `resoudre_agent` (`HOOK:2571`) lab → compte → plugin (P45-D-05b, liste `REF:1155`). Le hook ne lit
**jamais `session_id`** (0 occurrence dans `HOOK`, mesuré par `grep -c`) : tout ce qui est « mandat » passe aujourd'hui par
`agent_id`/`agent_type` (`HOOK:2625`, `:2740`).

**G6 (fichiers protégés).** `PROTEGES_G6` = `STATE.md`, `INDEX.md`, `cloture.log`, `.recalc-cache.json`, `derogations-gates.log`,
`surveillance.log`, `config.json` (adhésion seule) (`HOOK:1552-1557`) ; **enfant direct** de `.planning/` uniquement
(`fichier_protege` `HOOK:1590-1620`, test `a_la_racine` `HOOK:1596`) + scripts du hook sous `.claude/scripts/` (`HOOK:1623-1643`).
Outils `Write|Edit|NotebookEdit` seuls (`HOOK:1703`). Un fichier sous `.planning/baux/<…>/` ne serait **pas** couvert sans
extension de la règle de profondeur.

**G2 actuel vs G2′.** G2 (`evaluer_g2` `HOOK:1134-1166`) : avertissement jamais refus (`G2_MODE`), fail-open (exception avalée
`HOOK:1164`), hors `ORDRE_ETAPES` et hors `decider` ; il compare la cible (Write/Edit/NotebookEdit, ou jetons de chemin d'une
commande Bash `HOOK:1103-1131`) à l'**union** des `ecrit:` de **tous** les plans ouverts (`plans_ouverts` `HOOK:1065-1089`,
`_couvert` `HOOK:1092-1100`), hors `.planning/` et `.claude/` (`HOOK:1151`). G2′ (`SPEC:343`) : refus **à la clôture** de « ce qui a
bougé » hors de ce que **le bail** couvrait, sans amendement — par mandat, pas par union ; consomme le bail (`ROADMAP` gouvernance
l.305) ; aucune ligne de code ne le porte. « Amendement » n'est défini nulle part (SPEC §6 l.441-541 ne l'emploie pas).

**Canary et inventaire.** `PC/scripts/check-gates-alive.sh` : `EVENEMENTS_CABLES` (`:161`), `COMMANDE_REFERENCE` copie de la
commande (`:165`), `GATES` (`:195`), `COUVERTURE_MINIMALE` (`:198`), `CANARIS` 25 entrées dont D1-trace (décompte `awk`) (`:235-281`), `lire_armement` relit
chaque `ARMEMENT_<gate>` par regex (`:589-604`) ; un gate armé sans cas = signal. Inventaire du parc : `docs/HOOKS-CONTRAT-SORTIE.md:85`
(`assert n==37`), `scripts/tests/test-hook-exit-parc.sh`.

**Pré-filtre et coût.** `vf_pre` en tête de la commande (`hooks.json:19,45,56,67,78`) court-circuite hors adhésion sans script ni
python. `P46/46-COUT-PREFILTRE.md:38-47` : dans ce dépôt, commande complète 36-48 ms de médiane contre 102-144 ms sans pré-filtre ;
en lab adhérent (`:51-60`) le pré-filtre ajoute 5,5 à 29,1 ms (`:91-93`) ; FileChanged hors adhésion nul par construction (`:65-73`).
Un gate de plus **dans PreToolUse** ne change pas le coût hors adhésion ; un **nouvel événement** ajoute une entrée à mesurer.

**Points d'insertion probables (à trancher au cadrage).**
- (a) Jeton à l'écriture par outil : une fonction `evaluer_<bail>` ajoutée à `GATES_A_VERDICT` (`HOOK:2774`) avec sa constante
  `ARMEMENT_<X>` (`HOOK:133-140`), une étape 7 dans `ORDRE_ETAPES` (`HOOK:142`) et `armement_valide` (`HOOK:551-573`). Lecture du
  jeton présenté : seul `tool_input` le porte (patron `adhesion_conservee` `HOOK:1687-1695` et `_appliquer_edit` `HOOK:1646-1662`,
  qui reconstruisent le contenu d'un Write/Edit). « Dernier jeton vu sur ce chemin » : patron lecture+ajout sous `flock` de
  `consommer` (`HOOK:1412-1447`). Bash reste invisible (P45-D-10, `REF:1166-1167`) → côté écrivain obligatoire (§S3).
- (b) G2′ à la clôture : à côté de G3 sur l'écriture de `CLOTURE.md` (`evaluer_g3` `HOOK:1850-1880`, même
  `unite_de_fichier(...,"CLOTURE.md")` `HOOK:1801-1815`), ou de G4 sur `SUMMARY.md` (`HOOK:1914-1963`). Source de « ce qui a
  bougé » disponible : le journal de D1 (`lire_surveillance` `HOOK:2934`, `entrees_par_chemin` `HOOK:2961`) — dont la 46.1 change
  la réconciliation (§S4). Clôture par Bash invisible au hook → règle miroir au recalcul, zone des règles R1-R8 de
  `deriver_feuille` (`PC/scripts/recalc-planning.sh:1376-1456`).

## S2. Modèle : baux, classes de fichiers, identifiants, adhésion

**Ce que le modèle dit déjà des baux.** Arborescence : `baux/<phase>/gen-<n>/  (Phase 47)` (`REF:279`) ; `baux` est un
emplacement du modèle, jamais « Hors modèle », **non parcouru** par le recalcul (`REF:296-303` ; `NOMS_MODELE_RACINE_DOSSIERS`
`recalc-planning.sh:765`). INDEX : colonne « Bail en cours » (`REF:697-698`), **codée en dur `aucun`** (`recalc-planning.sh:2051`,
`:2058`). « Hors de cette phase » : G2′ et baux → 47, accroche à re-décider (`REF:1534`). La SPEC écrit `baux/<cycle>-<phase>/
gen-<n>/{meta, chemins}` (`SPEC:445-447`) mais `baux/<phase>/gen-<n>/` en §3 (`SPEC:205`) : **deux formes**. `<phase>` seul est
ambigu (un même nom de phase vit dans plusieurs cycles) ; `<cycle>-<phase>` l'est aussi, les noms d'unité contenant des tirets
(`^[0-9]{2,}-[\w.-]+$`, `HOOK:731`, `REF:290-291` : `01-a`+`02-b-03-c` = `01-a-02-b`+`03-c`) ; aucune forme ne vise le niveau plan
(`plans/<plan>/`, `unite_de_fichier` `HOOK:1801-1815`).

**Classes de fichiers.** SPEC §6.2 (`SPEC:505-511`) : append-only hors bail ; réécrit en place → bail au fichier près.
Arborescence annotée `REF:262-268` (générés, ajout seul). Relevé du code :

| Fichier | Écrivain | Classe réelle | Atomique / verrou |
|---|---|---|---|
| `STATE.md`, `INDEX.md`, `.recalc-cache.json` | recalcul | réécrit en place | `ecrire_si_different` temp + `os.replace` (`recalc-planning.sh:2107-2145`), **sans verrou** entre recalculs |
| `cloture.log` | recalcul | append-only | `O_APPEND` **sans flock** (`recalc-planning.sh:2010-2020`) ; dédoublonnage lu (`:2342`) puis ajout (`:2357`) hors verrou |
| `derogations-gates.log` | `deroger-gate.sh`, hook | append-only | flock (`deroger-gate.sh:338-339` ; `consommer` `HOOK:1412-1447`) |
| `surveillance.log` | hook, recalcul, pose | append-only | flock, trois copies (`HOOK:1272-1306`, `recalc-planning.sh:1965-1995`, `poser-verdict.sh:753-776`) |
| `VERDICT.md` | `poser-verdict.sh` | réécrit en place (⟲, `SPEC:202`) | temp + `os.replace` (`poser-verdict.sh:1008-1016`) sous flock du `PLAN.md` voisin (`:926-934`) |
| `config.json` | humain / outil | réécrit en place | aucun ; G6 ne garde que l'adhésion (`HOOK:1687-1726`) |
| `.planning/.gitignore` | hook | posé une fois | `O_EXCL` + `os.replace` (`HOOK:3335-3375`) |
| `PLAN/CADRAGE/CLOTURE/SUMMARY.md` | agents (outil ou Bash) | réécrits en place | aucun ; G1/G3/G4 jugent l'outil seulement |
| `.planning/missions/*.dag.json` | `dag.sh` | réécrit en place | **ni atomique ni verrou** (`plugin/conductor/scripts/dag.sh:117-121`) |
| état métier hors `.planning/` (`PIPELINE_STATE.json`…) | scripts, crons | réécrit en place | inconnu du moteur (seulement comme livrable `ecrit:`, G2 détection) |

À venir avec la 46.1 : un **fichier d'état du compteur G4′** sous `.planning/`, écrit atomiquement sous flock, protégé par G6,
connu du recalcul (`461-CTX` l.158-165, P461-D-04a) : un fichier « réécrit en place » de plus, écrit par le moteur.

**Le moteur écrit-il ?** Oui : `recalc-planning.sh` écrit `INDEX.md`, `STATE.md`, `.recalc-cache.json` (atomique fichier par
fichier) et ajoute à `cloture.log` (`appliquer_ecritures` `:2334-2390`), inscrit ses écritures à D1 (`inscrire_ecriture_moteur`
`:2320-2331`) ; deux recalculs concurrents ne se sérialisent pas (aucun `flock` hors journal de D1 dans ce fichier, relevé par grep).
Le temps : seule source fiable = `cloture.log` (`SPEC:584-594`) ; « battement frais » du bail (`SPEC:449-450`) n'a pas d'horloge définie.

**Identifiants.** Cycle, phase, plan : `NOM_UNITE` (`HOOK:731`) ; unité = 6 ou 8 composants `.planning/cycles/<c>/phases/<p>[/plans/<pl>]`
(`HOOK:1801-1815`, `REF:271-291`). Aucun identifiant de mandat ni de génération n'existe dans le modèle.

**Marqueur d'adhésion.** `.planning/config.json` avec `"planning_version": "cycles-v1"` exactement (`HOOK:106`, `verifier_adhesion`
`HOOK:521-547` ; recalcul `recalc-planning.sh:279-305`) ; motif de repli shell sur une ligne (`HOOK:107-111`).

## S3. Primitives de génération, fencing, verrou

**`plugin/conductor/scripts/driver-lock.sh` (838 l.).** Lien symbolique public → dossier de génération (`:8-20`). Génération
= `${LOCK_BASE}.gen.<epoch>.<pid>` (`new_generation` `:232-250`) : **pas un entier monotone** (seconde + pid, ordre par pid
arbitraire). Acquisition : `ln_atomic` (création de lien qui échoue si le nom existe, `:170-172`), publication après meta complet.
Reprise `takeover` (`:535-600`) : mutex nommé d'après la génération observée (`:554`), revalidation âge ET génération après mutex
(`:570-575`), bascule par `mv_link` = rename(2) (`:160-162`, `:581`), **l'ancienne génération est supprimée** (`:586`), trace au
journal append-only (`journal_event` `:322-333`). `reclaim`/`heartbeat` réécrivent le meta en place (`rewrite_meta` `:268`).
`recover` (`:726-761`) et `release` (`:698-719`) **suppriment le lien** (`drop_lock` `:292-296`) ; branche legacy
`rm -rf "$LOCK_DIR" && ln_atomic` (`:584`). Registre `register/close/orphans` JSONL append-only, frère du lock (`:336-440`).
Trailer `Fence: <generation>` : convention d'agent **jamais posée ni vérifiée par une machine**
(`plugin/conductor/references/team-kernel.md:288-303`, `plugin/dev-orchestrator/references/mission-flow.md:101-103`).
Preuves de concurrence existantes : `plugin/conductor/scripts/tests/test-driver-lock.sh` T11 (`:193`), T13 24×N (`:215-232`),
T32 (`:407-421`). **Réutilisable** : `ln_atomic`/`mv_link`, mutex par génération observée, relecture après acquisition (= SPEC
`:459-463`), journal frère, patron de test concurrent. **Non réutilisable tel quel** : identité de génération non entière, effacement
des générations (contraire de « un bail mort n'est jamais effacé : il est dépassé », `SPEC:449-450`), aucun « dernier jeton vu ».

**`dag.sh` — défaut exact.** `save()` (`dag.sh:117-121`) : `open(file, "w")` (troncature) + `json.dump`, ni temporaire+rename ni
verrou ; `load()` (`:111-115`) puis modification puis `save` aux sites `:348` (add), `:368` (mark), `:411` (reopen), init `:319`
(chargement unique `:323`). Effets : lost update silencieux entre deux écrivains, et lecteur concurrent qui peut lire un fichier
tronqué. Fiche BACKLOG : **`.planning/BACKLOG.md:169-191`** (la ROADMAP cite `:74`, ligne périmée depuis l'archivage SOBR-06 ;
`:74` est aujourd'hui une autre entrée). Piste notée : temp + `mv`, puis mutex `ln_atomic` si collisions mesurées, preuve par
« cas de concurrence réel rouge sous mutation » (`BACKLOG.md:183-186`). Suite existante : `plugin/conductor/scripts/tests/test-dag.sh`.
`dag.sh` vit dans `conductor`, pas dans `planning-core` : le corriger touche un autre module (VERSION, CHANGELOG propres).

**`check-method-budget.sh` (`plugin/conductor/scripts/`).** `archive_lock` = `mkdir .planning/.archive.lock` + pid (`:308-319`),
attente bornée, **aucune reprise automatique** (refus qui nomme le pid, `:337-344`), libération `rm -rf` (`:306`). Il a donc la
forme « mkdir + suppression » mais pas la récupération automatique qui casse (SPEC §6.1) ; sa reprise est manuelle. Patron
réutilisable : **instantané puis comparaison avant remplacement** (copie `:371`, `cmp -s` `:397`, refus sans perte), mais le
remplacement `cat new > src` (`:404`) n'est pas atomique.

**`planning-core/scripts`.** Aucun verrou `mkdir` (grep `mkdir .*lock|\.lock` vide). Verrous `fcntl.flock` (absents si `fcntl`
manque, `HOOK:99-103`) : `ouvrir_verrou` sur `PLAN.md` (`poser-verdict.sh:926-934`), journaux (ci-dessus). Écriture atomique :
`ecrire_si_different` (`recalc-planning.sh:2107-2145`), `ecrire_atomique` (`poser-verdict.sh:1008-1016`), `.gitignore`
(`HOOK:3362-3365`). **Jeton monotone déjà livré, à l'échelle d'un fichier** : `tentative` de `VERDICT.md`, contrôlée « 1 puis
ancienne + 1 » sous verrou (`controle_tentative` `poser-verdict.sh:943-948`) — mais le dernier jeton vit **dans le fichier
protégé lui-même**, donc forgeable : supprimer `VERDICT.md` ou baisser `tentative:` par Bash remet le compteur
(`poser-verdict.sh:56-60`, limite (g)). Leçon directe pour la 47 : « le dernier jeton vu » doit vivre hors du fichier gardé.

## S4. Zone partagée avec la 46.1 (exécutée avant la 47)

Fichiers que la 46.1 touchera (`461-CTX` l.314-325, décisions l.64-233) et fonctions concernées :
- `PC/hooks/hooks.json` : commande enregistrée changée sous les cinq événements (passage de `CLAUDE_PROJECT_DIR`, P461-D-03b,
  `461-CTX` l.140-143, l.348-350) → `COMMANDE_REFERENCE` (`check-gates-alive.sh:165`), `test-planning-hook-registered.sh`,
  `plugin/_internal/tests/test-planning-hook-installed.sh`.
- `HOOK` : `evaluer_g4` (exemption, `HOOK:1914`), `evaluer_g4p` (`HOOK:2727`) et une fonction propre de choix de définition
  (P461-D-02b), `mode_subagent_stop` (`HOOK:3316`) + compteur, `depart_evenement`/`main` (lab du cwd OU du projet, `HOOK:3450-3551`),
  arguments du cœur (`HOOK:86`), `reconcilier`/`decider_trace`/`_unites_non_closes` (N-5, A5 : `HOOK:2832`, `:2970`, `:3084`),
  `PROTEGES_G6` (nouveau fichier de compteur, `HOOK:1552-1557`), constantes `ARMEMENT_G4`/`ARMEMENT_G4P` (`HOOK:139-140`).
- `recalc-planning.sh` (fichier du compteur dans `NOMS_MODELE_RACINE_FICHIERS` `:766-781`), `rejeu-gates.sh`, `rejeu-reel.sh`,
  `check-gates-alive.sh` (cas de compteur), nouveau script de décision de relevé (P461-D-06), suites `test-cloture-gates.sh`,
  `fixtures/cloture-banc.txt`, `test-g4p-sortie-brute.sh`, `test-d1-surveillance.sh`, `test-rejeu-gates.sh`, `test-planning-gates.sh`
  (`TABLE_ATTENDUE` `:169`, `LIMITES_REFERENCE` `:5359`), `REF`, SPEC §5, `VERSION`/`module.json`/`CHANGELOG.md` → **v2.11.0**
  (P461-D-09), `.planning/BACKLOG.md`.

Collisions probables avec une 47 qui ajoute un gate et un contrôle de jeton :
1. **Bloc d'armement** `HOOK:133-144` + `armement_valide` `HOOK:551-573` : la 46.1 bascule G4 puis G4P ; la 47 ajoute une
   constante et une étape 7. Mêmes lignes, et la règle « une étape commencée exige la précédente armée » rend l'étape 7
   inarmable tant que G4P n'est pas armé — l'ordre réel de la 46.1 conditionne la 47.
2. **`GATES_A_VERDICT`** `HOOK:2774` (une ligne) et `evaluer_gates` `HOOK:2785-2805`.
3. **Commande enregistrée et arguments du cœur** : si la 47 transmet un jeton ou un identifiant de mandat par la couche shell
   (ou câble un nouvel événement), elle réécrit la même commande que P461-D-03b et les mêmes copies comparées.
4. **D1** : G2′ lirait le journal dont la 46.1 change la réconciliation (N-5, A5) ; `FICHIERS_RACINE_SURVEILLES`
   (`HOOK:2818`) est partagé.
5. **Listes une-ligne de R-REFERENCE** (`REF:1149-1155`) et `PROTEGES_G6` : la 46.1 y ajoute le compteur, la 47 y ajouterait
   le registre des jetons / les baux.
6. **Copies ast-identiques** (`inscrire_surveillance`, chaîne des empreintes, `REF:461-468`) : toute retouche suit dans trois
   fichiers.
7. **Versions** : la 47 part de v2.11.0 (46.1), pas de v2.10.0 (`PC/VERSION` à HEAD, `46.1-SCOUTING.md` §6).
8. **Fichier du compteur G4′** : premier fichier « réécrit en place » écrit par le moteur après la 46 ; à classer (hors bail
   comme les générés, ou client du jeton) au cadrage.

## S5. Infrastructure de preuve

Suites `PC/scripts/tests/` (lignes ; en-tête l.2-3 de chaque fichier) :

| Suite | l. | Couvre |
|---|---|---|
| `test-planning-gates.sh` | 5 751 | table d'armement (`TABLE_ATTENDUE` `:169`, `ORDRE_ATTENDU` `:170`, R-TABLE-01..04 `:3246-3267`), parseur croisé, G1/G2/G5/G6/G7/ROLE, mutants lot A (`TABLE-ORDRE` `:3904-3906`), R-REFERENCE et `LIMITES_REFERENCE` (`:5347-5656`) |
| `test-planning-hook-registered.sh` | 2 623 | commande enregistrée rejouée sous `/bin/sh -c` : R-CMD-01..08, R-EVT-01..08, R-DEPOT-INTACT, mutants MUT-EVT-* (`:7-37`) |
| `test-planning-prefilter.sh` | 1 486 | équivalence du pré-filtre hors adhésion + mutants |
| `test-cloture-gates.sh` (+ `fixtures/cloture-banc.txt`) | 2 409 | G3, G4 par la commande enregistrée, banc |
| `test-cloture-empreintes.sh` | 1 685 | livrable présent, empreintes, plafond de tentatives, copies ast-identiques (R-EMP-04) |
| `test-g4p-sortie-brute.sh` | 997 | G4′ (R-G4P-01..08) |
| `test-d1-surveillance.sh` | 1 700 | D1 : liste, journal, réconciliation |
| `test-juges-canary.sh` | 943 | canary de juge C-16 |
| `test-recalc-planning.sh` (+ `fixtures/recalc-planning-banc.txt`) | 5 211 | recalcul, états, cache |
| `test-rejeu-gates.sh` | 2 594 | `rejeu-gates.sh` / `rejeu-reel.sh`, R-REJEU-ETAPES (`:1267-1289`), duel `REJEU-ETAPE5` (`:2428`) |
| autres (`check-planning-state`, `detect-*`, `workstream-*`, `planning-hooks`, `planning-core`, `context-hardening`) | 72-479 | hooks et outils hérités, hors gates |

**Banc et rejeu.** `rejeu-gates.sh --etape=<1..6>` (`:18-21`) arme une copie du hook selon sa **propre copie** de `ORDRE_ETAPES`
(`rejeu-gates.sh:148`, `ETAPE_DE` `:149`, `armer_copie` `:386-393`) ; constructeurs G3/G4 dès 5, G4P dès 6 (`ETAPE_G3G4,
ETAPE_G4P = 5, 6`, `:164`) ; bornes d'usage `:1583`, `:1596` ; ligne `REJEU-ETAPE-<n>` `:1692-1693`, `COUVERTURE-REJEU`
(`couverture_g34` `:1326-1338`). `rejeu-reel.sh` (308 l.) : mêmes numéros, refus 64 hors 1..6 (`:214-215`), empreintes d'arbre.
**Numérotation** : étapes 1-6 utilisées ; « 5b » n'est **pas un numéro d'étape** — c'est un nouveau rejeu `--etape=5` sur G4
(`46.1-SCOUTING.md` §5.2 l.308-325) ; la 46.1 rejoue 5 puis 6. Une 47 qui ajoute un gate prend l'**étape 7**.
**Mutation d'armement** : mutants `TABLE-ORDRE`/`TABLE-ORDRE-REFUS` (`test-planning-gates.sh:3904-3906`), `CANG-ARMEMENT-SIGNAL`
(`:5288`), `REFERENCE-*` (`:5609-5611`), duel `REJEU-ETAPE5` (`test-rejeu-gates.sh:2428`).

**Ce qu'une 47 doit étendre (si gate PreToolUse, étape 7)** : constantes et `ORDRE_ETAPES` (`HOOK:133-142`) et sa copie
(`rejeu-gates.sh:148`, `:164`), bornes `--etape` (`rejeu-gates.sh:1583,1596`, `rejeu-reel.sh:214`), `TABLE_ATTENDUE`/`ORDRE_ATTENDU`
(`test-planning-gates.sh:169-170`) et le décompte de R-TABLE-02 (`:3262`), `GATES` + un cas `CANARIS` (`check-gates-alive.sh:195`,
`:235-281`), table et listes de la référence (`REF:1129-1155`), un banc à faux refus / faux accept mesurés dans les deux sens
(`SPEC:409-412`), et **un test de concurrence réel** — dans `PC`, un seul cas en tient lieu (deux poses simultanées de la
tentative 1, délai injecté, `test-planning-gates.sh:4568-4601`) ; patron à N écrivains : `test-driver-lock.sh` T13/T32.
Si un événement est ajouté : `EVENEMENTS_CONNUS` (`HOOK:125`), `EVENEMENTS_CABLES` (`check-gates-alive.sh:161`), R-CMD-01,
R-EVT-*, `assert n==37` (`docs/HOOKS-CONTRAT-SORTIE.md:85`), mesure de coût hors adhésion (patron `46-COUT-PREFILTRE.md`).
Côté écrivain : `test-recalc-planning.sh`, `test-cloture-empreintes.sh`, `plugin/conductor/scripts/tests/test-dag.sh`.

## S6. Espace de noms

Mesures (extraction `awk` des motifs `[A-Z][A-Z0-9]+-NN`, recoupée par `grep -o` + `sort -u`) :
- `.planning/workstreams/gouvernance/REQUIREMENTS.md` : **CLOT** (max 12, l.52-227), **FABR** (max 10, l.9-84), **GATE** (max 15,
  l.37-184), **MOTR** (max 18, l.19-159). Aucune exigence n'y vise encore la 47 (seule mention « bail » : `:130`, colonne « aucun » en 44).
- Branche 46.1 (`8519c402:…/REQUIREMENTS.md`) : **ARMG-01..10** en plus (l.64 sq.), réservé (P461-D-10).
- `.planning/workstreams/fiabilite/REQUIREMENTS.md` : 49 préfixes, dont `ABS ADPT AGTS ALTI ARMD BOOT BRDG BUDG CONS DOCF FIDE
  FIRST GSDA GSDC GSDM HEAD ICMD IDX INST ISSUE LEDG LOCK MANI MANIF MIGR PAEX PART PHIL PLUG PORT PROT QUAL RND ROLL ROUT RUNT
  SCOPE SIG SKIL SOBR TGT VERB VERIF VFDO VOC WKTR WSAW WSCH WTCH` (**LOCK** est pris : à éviter).
- **`BAIL` est libre** : `git grep -c -E '\b(BAIL|BAUX|JETN|LEAS|FENC)-[0-9]{2}\b'` sur HEAD, `8519c402` et `origin/main` →
  aucune sortie (code 1) ; recoupé sur disque (`grep -r -c` sur `.planning plugin docs scripts`) → 0 fichier, 0 occurrence.
  Préfixe de décision `P47-D-` : 0 occurrence (`.planning plugin docs`).

## S7. Limites nommées qui renvoient à la 47

- `REF:1534` : « G2′ et les baux (`.planning/baux/`) : Phase 47 ; le point d'accroche de G2′ est à re-décider (P46-D-19) ».
- `REF:279`, `REF:302-303`, `REF:697-698` : `baux/` réservé « (Phase 47) », non parcouru, bail en cours « aucun ».
- `P46/46-CONTEXT.md:40`, `:220-222`, `:375` : G2′ et baux → 47 ; P46-D-19 (note ROADMAP, `P46/46-NOTE-ROADMAP-47.md`).
- ROADMAP gouvernance l.305-308 : « Depends on » encore libellé « même `TaskCompleted` que G3/G4 » (l.305) **et** la note qui le
  dément (l.306) — le remplacement prêt de `46-NOTE-ROADMAP-47.md` (b) n'a pas été posé sur la l.305 ; `dag.sh` à embarquer (l.308).
- SPEC : la table garde G2′ sur `TaskCompleted` (`SPEC:343`), amendement « leur point d'accroche se re-décide au cadrage de la
  Phase 47 » (`SPEC:359`) ; `TaskCompleted` ne se déclenche pas sur un modèle récent sans activation (`P46/46-RECHERCHE-HOOKS.md:28`).
- `P46/46-VERIFICATION.md:95`, `:183` (F3) : les reports de la 46 n'avaient « aucune phase 47 à 50 » propriétaire — levé par
  l'insertion de la 46.1, pas par la 47.
- Limites sans lettre « Phase 47 » mais de la même classe : (ay) une `intention` explique un seul changement, une écriture Bash
  concurrente est masquée (`REF:1041`) ; (bn) forge d'une ligne du journal de D1 (`REF:1054`) ; (bo) cache du recalcul forgeable
  (`REF:1055`) ; (g) de la pose, compteur de tentative remis par Bash (`poser-verdict.sh:56-60`) ; (i) `$CLAUDE_PROJECT_DIR`
  choisit la copie du hook (`REF:999`) ; (an) course `lstat`/`readlink` (`REF:1030`). Aucune limite lettrée ne nomme le cron,
  le fan-out ni le jeton : ces trois cas ne vivent que dans `SPEC:471-485` et `SPEC:515-530`.

## Zones grises relevées (non tranchées par le code ni les sources)

1. **Où le jeton est présenté.** Le payload d'un `Write`/`Edit` ne porte aucun champ de mandat ; le hook ne lit pas `session_id`
   (parent en fan-out, `SPEC:479-482`) ; `agent_id` existe (`HOOK:2740`) mais change selon #89555 (`461-CTX` l.164-165).
   Jeton dans le contenu écrit (frontmatter), dans un fichier frère, dans l'argument d'un écrivain, ou dérivé d'`agent_id` : ouvert.
2. **Où vit « le dernier jeton vu sur ce chemin »** : hors du fichier gardé (leçon de la tentative, §S3) ; journal append-only
   sous flock (patron `consommer`) ou `baux/…/gen-<n>/` ; protection G6 en profondeur à étendre.
3. **Forme du chemin de bail** : `baux/<phase>` vs `baux/<cycle>-<phase>` (ambigus tous deux, §S2), niveau plan absent.
4. **« Battement frais »** sans horloge fiable (mtime exclu, `SPEC:580-594`) ; « plus haute génération fraîche » vs « monotone,
   jamais dépassée à rebours » (`SPEC:449-450` vs `:467-470`).
5. **« Amendement » du bail** : aucune définition (forme, auteur, trace).
6. **Accroche de G2′** : `CLOTURE.md` (avec G3), `SUMMARY.md` (avec G4), recalcul, ou plusieurs ; source de « ce qui a bougé »
   (journal D1, empreintes au bail, `ecrit:`).
7. **Périmètre des écrivains vérifiés** : recalcul, pose, dérogation, compteur 46.1, `dag.sh` (module `conductor`), scripts et
   crons métier du lab (que le moteur ne connaît pas). La ROADMAP exige « le jeton couvre `dag.sh`, ou la phase dit pourquoi non ».
8. **Labs non adhérents** : `dag.sh` sert aussi dans ce dépôt (dev, non adhérent) ; un correctif atomique ne dépend pas de l'adhésion,
   un contrôle de jeton oui.
9. **Windows** : `fcntl` absent → aucun verrou (`HOOK:99-103`) ; tout primitif de bail fondé sur flock y est muet.

```
{statut: passed,
 findings: [
  {id: F1, constat: "G2′ sans code : aucune fonction, constante ni cas de canary ; seul G2 (avertit, union des ecrit:) existe", chemin_ligne: "plugin/planning-core/scripts/planning-hook.sh:1134-1166, :2774", action: no-op},
  {id: F2, constat: "Deux formes du chemin de bail (baux/<phase> vs baux/<cycle>-<phase>), toutes deux ambiguës, niveau plan absent", chemin_ligne: "docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md:205, :445 ; plugin/planning-core/references/modele-cycles.md:279", action: ask-user},
  {id: F3, constat: "Le hook ne lit jamais session_id et aucun payload d'outil ne porte de jeton : le canal du jeton présenté est à décider", chemin_ligne: "plugin/planning-core/scripts/planning-hook.sh:2625, :2740", action: ask-user},
  {id: F4, constat: "driver-lock : génération = epoch.pid (non entière) et anciennes générations effacées ; Fence: jamais vérifié par machine", chemin_ligne: "plugin/conductor/scripts/driver-lock.sh:235, :586 ; plugin/conductor/references/team-kernel.md:288-303", action: no-op},
  {id: F5, constat: "dag.sh save() tronque puis écrit sans temp+rename ni verrou ; quatre sites load-modify-save", chemin_ligne: "plugin/conductor/scripts/dag.sh:117-121, :323, :348, :368, :411", action: no-op},
  {id: F6, constat: "La ROADMAP cite BACKLOG.md:74 pour dag.sh ; la fiche est à BACKLOG.md:169", chemin_ligne: ".planning/workstreams/gouvernance/ROADMAP.md:308 ; .planning/BACKLOG.md:169", action: no-op},
  {id: F7, constat: "Recalculs concurrents non sérialisés : cloture.log dédoublonné hors verrou et ajouté sans flock", chemin_ligne: "plugin/planning-core/scripts/recalc-planning.sh:2010-2020, :2342, :2357", action: no-op},
  {id: F8, constat: "Jeton monotone existant (tentative de VERDICT.md) stocké dans le fichier gardé, donc remis à zéro par Bash", chemin_ligne: "plugin/planning-core/scripts/poser-verdict.sh:943-948, :56-60", action: no-op},
  {id: F9, constat: "Collision 46.1/47 sur le bloc d'armement, GATES_A_VERDICT, la commande enregistrée, D1 et PROTEGES_G6 ; étape 7 inarmable avant G4P armé", chemin_ligne: "plugin/planning-core/scripts/planning-hook.sh:133-144, :551-573, :2774, :1552-1557", action: no-op},
  {id: F10, constat: "46.1-CONTEXT.md (P461-D-01..15, ARMG) n'existe que sur le commit local 8519c402, non poussé", chemin_ligne: "8519c402:.planning/workstreams/gouvernance/phases/VFDO-46.1-armement-de-g4-et-g4/46.1-CONTEXT.md", action: no-op},
  {id: F11, constat: "ROADMAP 47 « Depends on » garde la prémisse TaskCompleted démentie par sa propre note ; remplacement prêt non posé", chemin_ligne: ".planning/workstreams/gouvernance/ROADMAP.md:305-306 ; 46-NOTE-ROADMAP-47.md (b)", action: no-op},
  {id: F12, constat: "« Amendement » de bail et « battement frais » sans définition ni horloge", chemin_ligne: "docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md:343, :449-450, :580-594", action: ask-user},
  {id: F13, constat: "BAIL libre (HEAD, 8519c402, origin/main, disque) ; LOCK pris par fiabilite ; P47-D- libre", chemin_ligne: ".planning/workstreams/fiabilite/REQUIREMENTS.md ; .planning/workstreams/gouvernance/REQUIREMENTS.md", action: no-op}
 ],
 noeuds_debloques: ["cadrage-47"]}
```
