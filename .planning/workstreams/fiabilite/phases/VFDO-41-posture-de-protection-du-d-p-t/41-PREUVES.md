# Phase 41 — registre des mesures

Chaque ligne `CLE: valeur` est une mesure consignée au moment où elle est faite. Une valeur non
mesurée s'écrit `non_prouvee` ou `indetermine`, jamais supposée. Les sorties humaines sont
recopiées verbatim dans des lignes `…-MSG:`. Aucun chemin absolu de machine.

## 41-01 — préalables externes

CONTEXTES-CHECKS: sha=5238cba66c0d878a9ff4eb1c32757c21c64b454d n=4 app=15368 egal_ci=oui

## 41-14 — base de la garde de trace

BASE-TRACE-ARBITRAGE: f1d658957f7fe9c446b341bc447c19d6a0a0ed3a
Motif : les commits de cadrage et de planification antérieurs à cette valeur précèdent la garde G-1 et ne sont pas réécrits — seule la plage `<sha>..HEAD` sera jugée par le contrôle de trace du plan 41-15.

## 41-15 — outillage de preuve du périmètre sans admin

RECENSEMENT-FERMETURE: rc=0 fichiers=20 hits=0 allowlist_entrees=3 allowlist_appliquees=3
RECENSEMENT-CONTROLES: R0=0,R1=1,R2=1,R3=1,R4=0,R5=0,R6=0,R7=2,R8=64,R9=1,R10=0,R11=0 mutants_tues=3
TRACE-ARBITRAGE: rc=0 commits=17 citants=2 base=f1d6589
TRACE-CONTROLES: C0=0,C1=1,C2=1,C3=0,C4=1,C5=0,C6=0,C7=3,C8=2,C9=64,C10=0,C11=0,C12=2,C13=2 mutants_tues=6
OUTILS-PERIMETRE: distribues=non etapes_ci=0 decouverts_par_le_job_tests=non
LIMITE-DE-FOND: exiges=7 porteurs=4 manquants=aucun
BORNE-TRACE: sha=f1d6589 source=41-PREUVES.md commits_juges=17 commits_hors_borne=1255
Note : le compte de mutants de check-trace-arbitrage.sh est passé de 4 à 6 (mesuré) au tour
précédent de ce plan, resserrement du détecteur à une liste fermée de marqueurs d'invocation.
Les valeurs `commits=`/`citants=`/`commits_juges=` ci-dessus sont mesurées juste avant l'écriture
de cette section ; toute mesure ultérieure du même contrôle inclura, en plus, le commit qui
introduit cette section elle-même — propriété déjà présente pour `BASE-TRACE-ARBITRAGE` et non
un défaut de cette mesure.

## 41-19 — clôture du périmètre sans admin

REJEU-GATES: rc=0 etapes=13 ecarts=0
REJEU-TESTS: rc=0 suites=82 echecs=0
G1-REEL: rc=0 verdict=CONFORME
G2-REEL: rc=0 chemins_surface=7 marqueurs_conformes=18
G3-FIXTURE: bascules=4 ecarts=0
RECENSEMENT-FINAL: rc=0 fichiers=27 hits=0 allowlist_entrees=3
TRACE-FINALE: rc=0 commits=35 citants=6
SUMMARY-PRESENTS: 41-14,41-15,41-16,41-17,41-18 manquants=aucun — le sixième (41-19) est écrit à
la clôture de ce plan ; les SUMMARY des plans 41-01 à 41-13 ne sont PAS attendus, ces plans
étant différés faute d'accès admin et non exécutés (§ Prémisse renversée, 41-CONTEXT.md)
AUCUN-BUMP: fichiers_plugin_touches=0 version_racine=v2.63.2 modules_bumpes=0

Note sur RECENSEMENT-FINAL (hits=0, mesuré) : `tools/check-aucune-fermeture.sh` rend, sur l'état
final, `perimetre: fichiers=27`, `allowlist: entrees=3 appliquees=3`, `limite: exiges=10
porteurs=10 manquants=aucun`, rc=0 — zéro ligne de co-occurrence candidate (format `chemin:ligne:
contenu`), donc zéro hit réel. Le bloc `<automated>` de la Task 1 de ce plan compte `h` par
exclusion des seules lignes `^perimetre: ` et `^allowlist: `, sans exclure `^limite: ` — à la
différence du bloc analogue du plan 41-15 (`!/^perimetre: |^allowlist: |^limite: /`, ligne 208) qui
exclut les trois. Rejoué tel quel, ce bloc rend donc `h=1` (la ligne `limite: …` comptée à tort,
aucune ligne `chemin:ligne:contenu` ne s'y trouve) — écart mécanique entre le texte du plan 41-19 et
le comportement du script `check-aucune-fermeture.sh` tel qu'il existe depuis 41-15 (la sonde de
limite de fond, avertissement 7, est antérieure à ce plan). Le script n'a pas été modifié (interdit
par la discipline de ce plan) ; ce constat n'affaiblit aucune garde — la valeur `hits=0` ci-dessus
est celle du recensement réel (aucune co-occurrence non dispensée), pas une valeur choisie pour
faire passer la clôture. Remonté au manager comme finding mécanique, pas comme une régression.

Périmètre non rejoué, nommé (plan §Task 1) : job `tests` — étapes `Dépendances (bash, jq,
python3)`, `actions/setup-node` (action, nom vide en sortie de l'outil de rejeu), `Installer le
moteur GSD (@opengsd/gsd-core@^1)`, `Canari de forme du moteur GSD (lecture de texte —
check-gsd-config.sh)` (SAUTEE — installation/infra du runner, 5 sautee(s) au bilan, 1 seule étape
« Découvrir et lancer toutes les suites » rejouée) ; jobs `lab-frais` et `lab-frais-arme` (non
sélectionnés par `--job tests`/`--job gates`) ; étape `check-release-tag` (conditionnelle `main`,
SAUTEE) ; étape de mesure réelle de G-3, `check-push-sans-pr (G-3, PROT-05 — mesure réelle sur un
push vers main)` (conditionnelle `main`, SAUTEE — son étape de fixture sans condition, elle, est
rejouée et verte, `G3-FIXTURE` ci-dessus). Job `gates` : 1 étape action sautée en tête (checkout,
nom vide en sortie de l'outil), 3 sautee(s) au bilan.

CRITERE-1-ROADMAP: inatteignable_sans_admin raison=exige un ruleset actif sur main ; rulesets du
depot lus a vide, permissions admin false
CRITERE-2-ROADMAP: inatteignable_sans_admin raison=exige le refus reel d'un merge, donc une regle
cote serveur
CRITERE-3-ROADMAP: inatteignable_sans_admin raison=exige le rejeu du flux de release SOUS la
regle ; la regle n'existe pas
PROT-01-STATUT: non_coche hors_d_atteinte declencheur=acces admin accorde ou transfert du depot
ROADMAP-NON-TOUCHE: oui
STATE-NON-TOUCHE: oui
RELEASE: aucune version=v2.63.2 inchangee tag=aucun release_github=aucune modules_bumpes=0
LIMITE-DE-FOND: exiges=10 porteurs=10 manquants=aucun

Note sur ROADMAP-NON-TOUCHE / STATE-NON-TOUCHE : aucun plan de cette phase ne modifie
`.planning/ROADMAP.md` ni `.planning/STATE.md` ; leur mise à jour (réécriture des critères de
succès sur le périmètre arbitré) est prise en charge par le manager (décision du 2026-09-17),
nommée ici comme reliquat tracé, jamais comme un oubli.

## 41-01 — reprise du volet admin (2026-09-23)

IDENTITE-REPRISE: login=picmakpro id=203482067 admin=true source=gh_api_user
ACTEURS-CONTOURNEMENT: samuel-neveugall=151974738 picmakpro=203482067 collaborateurs=2 source=collaborators
PR29-FERMEE: state=CLOSED closedAt=2026-09-23T10:48:32Z
RULESETS-AVANT: n=0
PR-EN-VOL-REPRISE: numeros=#87,#88 detail=#87:main:de46daa3,#88:main:ed95ac5a
CONTEXTES-CHECKS-REPRISE: sha=6a7b15b3c74a1f45f4f1ad380a35d97d62cf1514 n=4 app=15368 ci_inclus_dans_api=oui egal_2026-09-17=oui check_release_tag_contexte=non

## 41-04 — PR de la phase

PR-PHASE: #90 merge=e70b22b71b5271c596ed5ff9cd053b498feefc8e tete=f5db5145f239c5c38bbe7abcd74a15981bead3c3 checks_tete=8/8 codeowners_errors=0 rulesets_au_merge=0 fusionne_par=samuel-neveugall fusionne_le=2026-09-23T14:41:20Z

Note : décision de merge de Willy (AskUserQuestion session principale, 2026-09-23 — « Je merge
depuis la session »), mais au moment de la commande `gh pr merge 90 --merge`, GitHub a répondu
« already merged » : la PR #90 avait déjà été mergée par `samuel-neveugall` (id 151974738) à
2026-09-23T14:41:20Z, commit de merge `e70b22b71b5271c596ed5ff9cd053b498feefc8e`, état `MERGED`
(témoin `gh pr view 90 --json state,mergeCommit,mergedBy`). Entre l'ouverture de la PR et son
merge, `samuel-neveugall` a poussé un commit de fusion supplémentaire sur la branche A
(`f5db514`, « Merge origin/main dans feat/phase-41-volet-admin (débogage PR #90) ») rattrapant
7 commits arrivés sur `main` entre-temps (PR #91) ; c'est ce sha de tête qui a été mergé. Fait
consigné tel quel : Willy n'a pas mergé cette PR.

## 41-05 — pose

RETOUR-ARRIERE-ECRIT: admin=picmakpro gh_api_-X_PUT_repos/picmakpro/vibeflow-os/rulesets/<id>_-f_enforcement=disabled temoin=rules/branches/main_vide

Retour arrière, écrit AVANT toute pose : si un ruleset posé ne se comporte pas comme arbitré, ou
bloque un merge à tort, l'admin (`picmakpro`) le repasse en `disabled` pour chacun des deux ids
posés — `gh api -X PUT repos/picmakpro/vibeflow-os/rulesets/<id> -f enforcement=disabled` — et
vérifie que `gh api repos/picmakpro/vibeflow-os/rules/branches/main` rend `[]` (plus aucune règle
effective sur la branche `main`). Exercé seulement sur décision humaine (Task 4 de ce plan, si
`M2-VERDICT: ECART` ou `POSE-ECHEC:`), jamais de la propre initiative de l'exécutant.

MAIN-VERTE-AVANT-POSE: sha=c78b238725ea24b181668efb1a5c4501569b6694 tests=success lab_frais=success lab_frais_arme=success gates=success gates_echec=aucun

PR-EN-VOL-AVANT: numeros=#93 detail=#93:base=main:etat=CLEAN:revue=aucune:codeowners=oui

Note sur `PR-EN-VOL-AVANT:` : une seule PR ouverte vers `main` au moment de la relecture (2026-09-23,
après le merge de la PR de la phase #90 et de la PR #91) — `#93` (`feat/garde-affirmation-non-mesuree`
→ `main`), ouverte par `samuel-neveugall` à `2026-09-23T14:55:10Z`, titre « feat(scripts): garde G-4 —
affirmation non mesurée de protection serveur ». Fichiers touchés :
`.github/workflows/ci.yml`, `.planning/server-rulesets-measurement.json`, `README.fr.md`,
`README.md`, `scripts/check-affirmation-non-mesuree.sh`, `scripts/measure-server-rulesets.sh`,
`scripts/tests/test-check-affirmation-non-mesuree.sh`. `.github/workflows/ci.yml` tombe sous le
motif `/.github/` de `.github/CODEOWNERS` (`origin/main`) → `codeowners=oui` : ouverte par
`samuel-neveugall`, pas par `picmakpro`, cette PR n'est pas bloquée par le cas « auteur = seul code
owner » ; elle passera par la revue `@picmakpro` normale une fois la règle posée, pas par un
contournement. `mergeStateStatus=CLEAN`, `reviewDecision` vide (aucune revue exigée tant qu'aucun
ruleset n'est actif).

POSE-DECISION: option=poser decideur=Willy canal=AskUserQuestion-session-principale date=2026-09-23 fenetre_preuves_annoncee=non

Pose effectuée par l'exécutant (jeton admin `picmakpro` de la session), exactement deux appels
d'écriture, dans l'ordre imposé, chacun depuis `origin/main` (sha
`a9620659c24103a103a5ca35c882faedb255b2c4`, tête au moment de la pose — postérieure aux mesures
de `MAIN-VERTE-AVANT-POSE:` et `PR-EN-VOL-AVANT:` : 27 commits supplémentaires atterris sur `main`
entre-temps, dont un rattrapage de release `v2.65.0` et le merge de la PR `#93` elle-même ;
`.github/rulesets/main.json`, `.github/rulesets/tags-v.json` et `.github/CODEOWNERS` inchangés sur
cette plage — `git diff c78b238..origin/main -- .github/rulesets/main.json
.github/rulesets/tags-v.json .github/CODEOWNERS` vide, source toujours celle relue conforme à la
Task 1) : `git show origin/main:.github/rulesets/main.json | gh api -X POST
repos/picmakpro/vibeflow-os/rulesets --input -` puis la même commande avec
`.github/rulesets/tags-v.json`. Aucun `POSE-ECHEC:` — les deux appels ont réussi au premier essai.

POSE-BRANCHE: id=23892920 enforcement=active pose_par=picmakpro source=origin/main:a9620659c24103a103a5ca35c882faedb255b2c4
POSE-TAGS: id=23892922 enforcement=active pose_par=picmakpro source=origin/main:a9620659c24103a103a5ca35c882faedb255b2c4

POSE-BYPASS-RELU: branche=User:151974738:always,User:203482067:always tags=User:151974738:always,User:203482067:always lu_par=picmakpro

POSE-MSG: branche={"_links":{"html":{"href":"https://github.com/picmakpro/vibeflow-os/rules/23892920"},"self":{"href":"https://api.github.com/repos/picmakpro/vibeflow-os/rulesets/23892920"}},"bypass_actors":[{"actor_id":151974738,"actor_type":"User","bypass_mode":"always"},{"actor_id":203482067,"actor_type":"User","bypass_mode":"always"}],"conditions":{"ref_name":{"exclude":[],"include":["refs/heads/main"]}},"created_at":"2026-09-23T19:56:30.490+02:00","current_user_can_bypass":"always","enforcement":"active","id":23892920,"name":"main — PR obligatoire, 4 checks requis, revue code owner (Phase 41)","node_id":"RRS_lACqUmVwb3NpdG9yec5KZh8BzgFsk7g","rules":[{"type":"deletion"},{"type":"non_fast_forward"},{"parameters":{"allowed_merge_methods":["merge","squash","rebase"],"dismiss_stale_reviews_on_push":false,"require_code_owner_review":true,"require_extra_approval_for_unattributed_changes":true,"require_last_push_approval":false,"required_approving_review_count":0,"required_review_thread_resolution":false,"required_reviewers":[]},"type":"pull_request"},{"parameters":{"do_not_enforce_on_create":false,"required_status_checks":[{"context":"Gates de qualité (mode strict)","integration_id":15368},{"context":"Lab frais (install baseline + Gate C — leçon UAT 2026-07-25, F2)","integration_id":15368},{"context":"Lab frais arme (as-installed testing — le gate installe, sur un univers non vide, #38)","integration_id":15368},{"context":"Suites de tests (découverte non vide)","integration_id":15368}],"strict_required_status_checks_policy":true},"type":"required_status_checks"}],"source":"picmakpro/vibeflow-os","source_type":"Repository","target":"branch","updated_at":"2026-09-23T19:56:30.592+02:00"} tags={"_links":{"html":{"href":"https://github.com/picmakpro/vibeflow-os/rules/23892922"},"self":{"href":"https://api.github.com/repos/picmakpro/vibeflow-os/rulesets/23892922"}},"bypass_actors":[{"actor_id":151974738,"actor_type":"User","bypass_mode":"always"},{"actor_id":203482067,"actor_type":"User","bypass_mode":"always"}],"conditions":{"ref_name":{"exclude":[],"include":["refs/tags/v*"]}},"created_at":"2026-09-23T19:56:35.140+02:00","current_user_can_bypass":"always","enforcement":"active","id":23892922,"name":"tags v* — réécriture et suppression tracées, création libre (Phase 41)","node_id":"RRS_lACqUmVwb3NpdG9yec5KZh8BzgFsk7o","rules":[{"type":"deletion"},{"type":"non_fast_forward"},{"type":"update"}],"source":"picmakpro/vibeflow-os","source_type":"Repository","target":"tag","updated_at":"2026-09-23T19:56:35.201+02:00"}

POSE-CONFORME: branche=oui tags=oui contextes_egaux_source=oui rules_branches_main=oui

M2: picmakpro_branche=always picmakpro_tags=always relue_picmakpro=oui samuel_branche=non_mesure samuel_tags=non_mesure bypass_users_relus=oui

M2-VERDICT: CONFORME — les deux entrées `bypass_actors` relues sur chacun des deux rulesets sont
exactement les deux `User` de `ACTEURS-CONTOURNEMENT:` (151974738, 203482067) en mode `always` ;
`current_user_can_bypass` de `picmakpro` relu à `always` sur les deux ; `POSE-CONFORME:` à `oui`
partout ; aucun `POSE-ECHEC:`.

ACCES-RULE-SUITES: picmakpro=ok samuel-neveugall=non_mesure

Note sur `ACCES-RULE-SUITES:` : `gh api "repos/picmakpro/vibeflow-os/rulesets/rule-suites?time_period=hour"`
rend `[]` (liste vide, aucun contournement mesuré dans l'heure — attendu, aucune PR n'a encore été
mergée en contournant depuis la pose) ; l'appel lui-même réussit (rc=0) sous le jeton admin
`picmakpro`, donc `ok`. `samuel-neveugall` reste `non_mesure` : aucun jeton de Samuel sur ce poste.

PR-EN-VOL-APRES: numeros=#93,#96,#98 detail=#93:etat=MERGED:revue=aucune:fusionnee_par=samuel-neveugall,#96:etat=BEHIND:revue=aucune:fusionnee_par=aucun,#98:etat=CLEAN:revue=aucune:fusionnee_par=aucun

Note sur `PR-EN-VOL-APRES:` : la PR `#93` (seule PR de `PR-EN-VOL-AVANT:`) a été mergée par
`samuel-neveugall` (commit `e23bbe3`) AVANT la pose des rulesets — relecture faite quelques minutes
après la pose, état `MERGED`, `mergeStateStatus` API `UNKNOWN` (relu deux fois : valeur stable,
attendue pour une PR déjà fermée — GitHub ne calcule plus la mergeabilité d'une PR non ouverte) ;
`reviewDecision` vide → `revue=aucune`. Rien n'a été fait sur cette PR par la phase. Deux PR
ouvertes vers `main` sont apparues depuis la mesure `PR-EN-VOL-AVANT:` (ouvertes avant la pose,
toujours ouvertes après) : `#96` (`docs/backlog-partition-au-demarrage`, `mergeStateStatus=BEHIND`
après relecture — un premier `UNKNOWN` relu) et `#98`
(`chore/phases-41-1-41-2-inscription`, `mergeStateStatus=CLEAN`) ; ni l'une ni l'autre commentée,
mise à jour, fermée ou mergée par cette phase — état relevé en lecture seule uniquement.

REJEU-GATES-41-05: rc=0 etapes=14 sautees=3 en_echec=0
REJEU-TESTS-41-05: rc=1 suites=84 echecs=2 echecs_preexistants_ledger=WINDOWS#6,WINDOWS#7

Note sur le rejeu `tests` après la pose : `bash …/replay-ci-jobs.sh --job tests` rend 84 suites,
2 échecs — `plugin/_internal/runtime-adapter/tests/test-register-codex-agent-path-traversal.sh`
(cas `T4 [majuscules]`, macOS filesystem insensible à la casse) et
`plugin/conductor/scripts/tests/test-check-description-fidelity.sh` (36 KO, module Python PyYAML
introuvable pour `python3` sur ce poste). Les DEUX sont déjà consignés `open` dans
`.planning/WINDOWS.md` (id 6 et 7, phase 41, plan 41-01) — rouges préexistants, hors périmètre de
ce plan (JSON/pose de rulesets), reproduits à l'identique sur une extraction d'`origin/main`
indépendante de tout travail de ce plan ; ni neutralisés ni fixés sans validation humaine
(ADR-031). Confirmation indépendante que ce ne sont pas des régressions de la pose : les 4 checks
CI réels de la tête d'`origin/main` (`a9620659…`, source de la pose) sont `success`, y compris
« Suites de tests (découverte non vide) » — l'écart est un artefact d'environnement local
(sensibilité à la casse du système de fichiers, dépendance Python absente), pas un état réel du
dépôt. `gates` rejoué sans écart (14 étapes, 3 sautées par construction — conditionnelles à
`main`/push —, 0 en échec).

## 41-06 — revue code owner

PR-EN-VOL-41-06: numeros=#96,#98,#99,#100 date=2026-09-24T07:27:37Z note=fenetre-sans-merge-convenue-avec-Samuel-relayee-par-Willy-session-principale-2026-09-24

Note sur `PR-EN-VOL-41-06:` : `PR-EN-VOL-APRES:` (41-05) reste telle quelle, non réécrite — c'est une
mesure historique d'après la pose. Cette ligne est une mesure nouvelle et distincte, prise le
2026-09-24 avant la Task 1 de ce plan : `#93` est sortie de l'inventaire (mergée, déjà fermée) et
deux PR sont apparues depuis (`#99` gouvernance/remarques-revue-sam, `#100`
feat/phase-41-1-gates-workstream-aware), toutes deux ouvertes vers `main`. Aucune des quatre PR de
cette liste (`#96`, `#98`, `#99`, `#100`) n'est mergée ni touchée par cette phase pendant la fenêtre
sans merge convenue avec Samuel, relayée par Willy, session principale, 2026-09-24 — la mesure de
Phase 41 reste valide tant que la fenêtre tient.

MAIN-AVANT-PREUVES: a9620659c24103a103a5ca35c882faedb255b2c4

PR-P-COMMITS: p1=dc05507ce215df774d81b3ff64a1c0288e225f4b p2=20fdad050eaaff2d987c20b00a05dfc75d3655b0 base=a9620659c24103a103a5ca35c882faedb255b2c4

PR-CO-COMMITS: baseline=ce9f30e0f5ee5b08f57209836b7ef677095c4b86 sentinelle=863215be527e781d9c69139cf9ca52284a2b053e base=a9620659c24103a103a5ca35c882faedb255b2c4

### Task 2 — gestes humains de Willy (`picmakpro`), 2026-09-24

Publié tel que collé au checkpoint : `preuve/41-contournement`=dc05507ce215df774d81b3ff64a1c0288e225f4b,
`preuve/41-codeowner-baseline`=ce9f30e0f5ee5b08f57209836b7ef677095c4b86,
`preuve/41-codeowner-sentinelle`=863215be527e781d9c69139cf9ca52284a2b053e. PR ouvertes : PR-P=#101,
PR-BASELINE=#102, PR-SENTINELLE=#103. `gh pr checks 101 --watch` : rc=0, tous verts. Étape 4 :
`mergeStateStatus=CLEAN` (jamais `BLOCKED`) et `reviewDecision=""` sur les trois PR, lues par
`picmakpro`. Conformément à l'instruction de la Task 2 (« SEULEMENT si 4 rend `mergeStateStatus` =
`BLOCKED` »), `gh pr merge` n'a pas été tenté — l'état n'était pas `BLOCKED`. Témoin étape 6 :
`gh pr view 101 --json state` → `OPEN`. Aucune PR fermée.

### Task 3 — relecture API et consignation, 2026-09-24

PR-P: #101 branche=preuve/41-contournement auteur=picmakpro
PR-BASELINE: #102 branche=preuve/41-codeowner-baseline auteur=picmakpro
PR-SENTINELLE: #103 branche=preuve/41-codeowner-sentinelle auteur=picmakpro

CO-I: tete=dc05507ce215df774d81b3ff64a1c0288e225f4b checks_verts_deux_evenements=4/4 behind_by=0 review=vide etat=CLEAN merge_sans_contournement=non_tente provenance=indeterminee gh_version=2.83.2 etat_pr_apres=OPEN

CO-I-MSG: non_tente — mergeStateStatus lu CLEAN (jamais BLOCKED) à l'étape 4 de la Task 2, donc gh pr merge n'a pas été exécuté conformément à l'instruction, aucune sortie à coller.

CO-I-GH-MSG: gh version 2.83.2 (2025-12-10)

CO-BASELINE: auteur=picmakpro review=vide relue=oui
CO-SENTINELLE: auteur=picmakpro review=vide relue=oui

CO-VERDICT: ECART

Note sur l'écart mesuré (Task 3, 2026-09-24) : les trois PR de preuve (#101, #102, #103), toutes
ouvertes par `picmakpro`, sont lues `mergeStateStatus=CLEAN` et `reviewDecision=""` (vide, ni
`REVIEW_REQUIRED` ni `BLOCKED`) — vérifié deux fois, par le collage de la Task 2 et par une lecture
indépendante de l'agent (`gh pr view --json mergeStateStatus,reviewDecision`, ce document même,
2026-09-24), toutes deux sous le jeton `picmakpro`. Pourtant les 4 checks CI de PR-P sont verts sur
les deux événements (`checks_verts_deux_evenements=4/4`, mesuré `repos/.../commits/<tete>/check-runs`
filtré `app.id=15368` et `conclusion=success`, groupé par nom de job), `behind_by=0` (mesuré
`compare/main...<tete>`), et le ruleset de branche exige bien `require_code_owner_review: true` avec
`required_approving_review_count: 0` (`POSE-MSG:`, 41-05) sur les trois chemins visés (`.github/`,
la baseline, la sentinelle — les trois sous `.github/CODEOWNERS`). La seule variable qui distingue
cet état d'un `BLOCKED` est `current_user_can_bypass=always` de `picmakpro`, relu à nouveau ici sur
le ruleset `23892920` (`bypass_actors` inchangés : `User:151974738:always`, `User:203482067:always`
— cf. `ACTEURS-CONTOURNEMENT:`, 41-01 reprise, et `POSE-BYPASS-RELU:`, 41-05).

L'hypothèse relayée dans `<user_response>` — `mergeStateStatus` et `reviewDecision` sont calculés
pour le compte qui lit, et un compte en contournement `always` voit la PR déjà mergeable — n'est
PAS recopiée ici comme un fait établi ; elle est la seule explication compatible avec l'ensemble des
mesures ci-dessus (CI verte, à jour, ruleset actif et code-owner exigé sur les trois chemins, mais
`CLEAN`/vide plutôt que `BLOCKED`/`REVIEW_REQUIRED`), mais elle reste **non prouvée au sens strict** :
aucun compte hors liste de contournement (`samuel-neveugall` et `picmakpro` sont les deux seuls
collaborateurs, et les deux sont en `always` — `ACTEURS-CONTOURNEMENT:`) n'a pu relire ces trois PR
pendant que la session dispose d'un jeton pour trancher entre « revue non exigée sur ce chemin » et
« revue exigée mais invisible pour un compte en contournement toujours actif ». C'est exactement le
témoin discriminant que T-41-62 et l'option « REJOUER AVEC DES PR OUVERTES PAR SAMUEL » de la Task 4
visent à produire.

`merge_sans_contournement=non_tente` (ni `refuse` ni `merge`) : conforme à l'instruction de la Task 2,
qui interdisait la tentative hors `BLOCKED` — la première tentative de merge sans contournement de la
phase n'a donc PAS eu lieu ici ; l'ordre de sûreté de T-41-23 (jamais sur la PR rouge, seulement sur
un support inoffensif, et seulement sur `BLOCKED`) reste respecté, rien n'a menacé d'atterrir sur
`main`. `provenance=indeterminee` : aucune sortie de `gh pr merge` à classer, donc ni `serveur` ni
`client_gh`.

`CO-VERDICT: ECART` — recalculé par les blocs `<automated>` de la Task 3 (`etat != BLOCKED`,
`review != REVIEW_REQUIRED` sur les trois PR) ; consigné tel quel, sans correction (ADR-031, règle du
plan : « un écart de valeur n'est jamais corrigé »). Ce constat ne clôt ni PROT-04 ni le critère 2 du
ROADMAP : il documente que la preuve prévue par ce plan (refus observable par tentative de merge sans
contournement) n'est pas observable depuis le seul compte actuellement disponible pour la tenter,
`picmakpro`, parce que ce compte est lui-même en contournement `always`. Arrêt sur la Task 4
(checkpoint de décision), comme prévu par le plan sur `CO-VERDICT: ECART`.

### Task 4 — décision humaine, 2026-09-24

CO-DECISION: option=accepter-et-documenter decideur=Willy canal=AskUserQuestion-session-principale date=2026-09-24

Écart accepté et documenté tel que mesuré, sans l'adoucir : les deux seuls collaborateurs du dépôt
(`samuel-neveugall`, `picmakpro`) ont le contournement `always` (D-02bis) ; `mergeStateStatus` et
`reviewDecision` sont calculés pour le compte lecteur ; aucun acteur réel du dépôt n'observe donc le
refus par défaut ni la revue code owner exigée — la règle est posée et effective
(`rules/branches/main`), mais elle ne s'impose qu'à un acteur hors liste, ce que le plan 41-09
mesurera avec une clé de déploiement temporaire pour le push direct. Le critère 2 du ROADMAP n'est
pas tenu tel que formulé ; consigné tel quel, sans correction. Suite prescrite par le plan : fermer
PR-BASELINE (#102) et PR-SENTINELLE (#103), et supprimer leurs branches, au pas 0 de la Task 2 du
plan 41-07 (pas ici) ; PR-P (#101) reste ouverte pour le temps (ii) du plan 41-08.

**Correction de l'explication, 2026-09-24** (arbitrage Willy, AskUserQuestion session principale,
2026-09-24) : la mesure `CO-VERDICT: ECART` reste valide. En revanche, l'explication ci-dessus, selon
laquelle le contournement `always` empêche tout acteur réel d'observer le refus, est **contredite**.
Lecture seule du même jour, par `picmakpro` : la #100, ouverte par `samuel-neveugall` et qui touche
`.github/workflows/ci.yml`, est vue `BLOCKED` avec une revue demandée à `picmakpro`, alors que la
#101, la #102 et la #103, ouvertes par `picmakpro`, sont vues `CLEAN`. La variable qui départage les
deux cas est l'auteur, lui-même seul code owner, et non le contournement. C'est une lecture des
mesures, pas une règle GitHub vérifiée. Ce constat est consigné comme simple observation, sans
valeur de preuve du critère 2. La ligne `CO-DECISION` ci-dessus n'est pas modifiée.

## 41-07 — M-1 par lecture, PR rouge jamais mergée (D-02ter)

### Task 1 — précondition et construction, 2026-09-24 (arrêt avant consignation des commits)

PRECONDITION-41-07: identite=picmakpro CO-VERDICT=ECART CO-DECISION=accepter-et-documenter tenue=oui origin_main=a9620659c24103a103a5ca35c882faedb255b2c4 prs_ouvertes_hors_inventaire=#101,#102,#103

PR-R-PREMISSE: ecart etape=check-version-sync job=gates suites_readme=85 suites_avec_preuve=86 rejeu_gates_seule_suite=rc1_1_en_echec rejeu_gates_readme_aligne=rc0_0_en_echec g2_trailer_gate_touche=requis source=rejeu_local_clone_jetable

Note sur `PR-R-PREMISSE:` (mesuré le 2026-09-24, avant tout geste chez GitHub) : le plan suppose
qu'un commit qui n'ajoute QUE `scripts/tests/test-preuve-41-m1.sh` laisse les trois autres jobs
verts sur les deux événements (C0 témoin vert, `autres_jobs_verts=6/6`). C'est faux. Le gate
`scripts/check-version-sync.sh` (point 9, job `gates`, contexte requis « Gates de qualité (mode
strict) ») compare le compte « N suites » cité par `README.md` et `README.fr.md` au nombre de
fichiers `*/tests/test-*.sh` sous `plugin` et `scripts` : 85 cités, 86 avec la suite de preuve. Le
job `gates`, rejoué localement (outil `replay-ci-jobs.sh --job gates`) sur un clone jetable dont la
tête est le B construit selon le plan, rend `15 rejouee(s), 3 sautee(s), 1 en echec` — l'étape
`check-version-sync` en échec avec `README.md : '85 suites' ≠ réel=86`. Toute suite découverte par
l'étape `find plugin scripts -type f -path '*/tests/test-*.sh'` est aussi comptée par ce gate :
aucun emplacement ne la fait lancer par le job de tests sans la faire compter. Joué tel quel, C0
porterait donc un check requis en échec, l'agrégat de C0 ne vaudrait pas `SUCCESS`, et le verdict
serait `INDETERMINE` par construction. Second constat, déjà traité sans écart au contrat : la
suite de preuve tombe dans la surface de G-2 (`scripts/tests/test-*.sh`) ; chaque commit C0, A, B
porte donc le trailer `Gate-Touche: scripts/tests/test-preuve-41-m1.sh — …` (G-2 rejoué sur B :
`DECLARE`, rc=0). Variante mesurée verte : C0 aligne en plus « 86 suites » dans les deux README
(une ligne chacun), A et B ne touchent que la suite ; `gates` rejoué sur cette tête B :
`15 rejouee(s), 3 sautee(s), 0 en echec`. Elle contredit le critère `autres_fichiers=0` du plan
(deux fichiers existants modifiés dans C0, aucun gate) : non retenue sans décision humaine.
Comportement local de la suite de preuve, identique dans les deux variantes : `c0_push=0 c0_pr=0
a_push=0 a_pr=1 b_push=1 b_pr=0`. Aucun push, aucune PR ouverte ou fermée, `PR-R-COMMITS:` non
consigné en attente de la décision.

PR-R-DECISION: option=REPLANIFIER decideur=Willy canal=AskUserQuestion-session-principale date=2026-09-24

Le plan 41-07 est renvoyé au planificateur pour intégrer la contrainte `check-version-sync` à la
source (arbitrage Willy, AskUserQuestion session principale, 2026-09-24). Les commits construits
localement (les deux variantes) ne sont pas publiés.

### Task 1 — reprise après REPLANIFIER, 2026-09-24

PRECONDITION-41-07-REPRISE: identite=picmakpro CO-VERDICT=ECART CO-DECISION=accepter-et-documenter PR-R-DECISION=REPLANIFIER origin_main=a9620659c24103a103a5ca35c882faedb255b2c4 prs_ouvertes_hors_inventaire=#101,#102,#103

PR-R-COMMITS: c0=755650c0dd34dbc399247da80cf7391c74cf7ae1 a=a3bf40f4a254e0bc72b441408be5ff486d164401 b=3b493061251f952bad57f7cb2a61a7f7aab8e85b base=a9620659c24103a103a5ca35c882faedb255b2c4 readme_suites=85->86 reprise=oui

MAIN-AVANT-PR-R: a9620659c24103a103a5ca35c882faedb255b2c4

PR-R-REJEU-LOCAL: c0_gates=0/0 b_gates=0/0 b_g2=0:DECLARE c0_suites=86 c0_echecs_ledger=2 c0_echecs_hors_ledger=0 preuve_c0=PASS source=clone_jetable non_rejoue=etapes_uses,etapes_if_main,commit_de_merge_pull_request,dodo_420s

Note sur la reprise (2026-09-24) : `origin/main` relue à `a9620659…`, inchangée ; les trois objets
du premier passage existent, chaînés sur elle, sans aucune ref locale : repris tels quels
(`reprise=oui`). `gates` rejoué sur C0 et sur B : `15 rejouee(s), 3 sautee(s), 0 en echec` chacun ;
G-2 sur B : `DECLARE`, rc 0. `tests` rejoué sur C0 (`GITHUB_EVENT_NAME=pull_request`,
`PREUVE41_DODO=0`) : 86 suites, rc 1 dû aux deux seuls échecs
`plugin/_internal/runtime-adapter/tests/test-register-codex-agent-path-traversal.sh` et
`plugin/conductor/scripts/tests/test-check-description-fidelity.sh`, entrées `open` #6 et #7 du
ledger `.planning/WINDOWS.md` (rouges d'environnement de ce poste, absents de la CI) ; suite de
preuve `PASS`. Non couverts par ce rejeu : les jobs `lab-frais` et `lab-frais-arme` (hors de portée
de l'outil ; invariance tenue par construction, `plugin=0`, et relue sur la CI réelle à la Task 3) ;
et, dans le job `tests`, le contrôle du nombre d'étapes en échec que les blocs de 41-08 à 41-13 ont
reçu n'existe pas dans ceux de 41-07 (trou inactif ici : une seule étape rejouée).
