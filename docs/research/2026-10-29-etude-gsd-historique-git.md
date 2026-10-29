# Coût de la dérive et des pièges de GSD — mesure sur git, GitHub et CI

> Étude E0(b) de SEED-003, mesurée le 2026-10-29, en lecture seule. Dépôts : `vibeflow-os`
> (GitHub `picmakpro/vibeflow-os`) et Scroll-Off (trois dépôts `Scroll-Off/{backend,frontend,website}`
> + planning parent non versionné). Les transcripts Claude Code n'ont pas été lus (mesure parallèle).
> Moteur concerné : `@opengsd/gsd-core`, plage `^1`, dernière publiée 1.19.0 (2026-10-26).

## 1. Méthode

**Sources.** `git log --all` (3 302 commits, dont 2 318 sur `main`, 2026-05-24 → 2026-10-29) ;
`gh pr list --state all` (164 PR) ; `gh release list` (102 releases) ; `gh run list` (933 runs CI
conservés, 2026-07-25 → 2026-10-29, dont **209 en échec**) ; pour chaque run en échec, jobs et
étapes en échec via l'API, puis le journal du job filtré sur `##[error]` et `✗` (journaux expirés
pour 29 runs du 25 au 28 juillet, période de réparation initiale de la CI sans lien GSD) ;
`docs/ADR.md`, `.planning/` (BACKLOG, seeds, upstream) ; registre npm (`npm view … time`). Les
mémoires persistantes ont servi d'index d'épisodes ; chaque épisode retenu est recoupé par un SHA,
une PR, un run ou une release.

**Rattachement d'un run CI rouge à GSD.** Seulement quand le journal nomme la cause : `✗ T28-F`
(index de capabilities qui a dérivé du moteur installé), les cas `T2e-*` de l'auto-install Node,
la garde R1 de `check-dev-bootstrap` rendue muette par un `STATE.md` écrit par l'outillage amont,
`check-state-integrity` sur un frontmatter réécrit. Un run rouge sur la branche d'un épisode mais
pour une autre cause (ex. `check-machine-paths`) **n'est pas compté**.

**Estimation d'effort (heures).** Calendrier des commits de l'épisode (horodatage d'auteur,
dédupliqués). Borne basse : somme des intervalles < 1 h entre commits consécutifs, + 0,25 h par
grappe. Borne haute : intervalles < 2 h, + 0,5 h par grappe, + 0,5 h de diagnostic par épisode
ayant d'abord rougi la CI. **C'est une estimation de temps de session, pas de temps humain** : les
commits sont surtout produits par des agents, parfois en sessions concurrentes, et le temps de
diagnostic sans commit n'apparaît pas. Référence de comparaison, même méthode sur tout
l'historique : **401 h (basse) à 508 h (haute)**.

**Classes.** (a) dérive amont (nouvelle version publiée attrapée par `^1`, Node) ; (b) bug ou piège
du moteur ; (c) coût structurel de l'intégration ; (d) migration legacy → OpenGSD. Les classes
(c) et (d) ne sont pas de la dérive et sont présentées à part.

## 2. vibeflow-os — épisodes (a) dérive amont

| # | Épisode | Preuves | Dates | Commits | PR | Releases | CI rouges | Heures (bas–haut) |
|---|---|---|---|---|---|---|---|---|
| A1 | Alignement volontaire sur 1.9.0 (Phase 21 ; inclut le diagnostic `STATE.md` et ADR-063, et un correctif MCP propre à VibeFlow) | PR #22, `d89a60e` | 07-28 → 07-31 | 86 | 1 | v2.45.0 (minor) | 0 | 8,2–9,5 |
| A2 | 1.9.1 : vérification du couplage, en-tête d'index figé à 1.9.0 | PR #33 | 08-04 | 2 | 1 | **v2.47.1 (patch)** | 0 | 0,3–0,5 |
| A3 | 1.11.0 exige Node ≥ 24 ; sous Node 22, `^1` rétrograde en silence vers 1.10.0 → T28-F rouge en CI, vert en local ; CI repinnée, puis auto-install de Node | `a388c7d`, `d6f5f31` (dans PR #53), PR #54 ; runs 33086801639, 33086841585 (T28-F), 33172555669, 33172558794 (T2e-B/D, piège `NVM_DIR` du test) | 08-26 → 08-28 | 4 | 1 (+1 partagée) | **v2.58.0 (minor correctif)** | 4 | 0,9–2,2 |
| A4 | 1.12.0 : index de capabilities régénéré | `46794d6` (dans PR #56) ; runs 33392636258, 33392673933 | 08-31 | 1 | partagée | — | 2 | 0,2–1,0 |
| A5 | 1.13.0 : T28-F rouge sur une PR sans rapport (hotfix Windows) ; second index (skills) resté à 1.9.1, `gsd-quick-batch` non routé sans qu'aucun gate le dise | `8b42998`, `469ac8a`, `2ae55e8` (dans PR #59) ; runs 34138761997, 34138797889, 34139124261, 34139127350 | 09-07 | 3 | partagée | **v2.59.1 (patch, partagée avec WIN-PATHCONV II)** | 4 | 0,8–1,8 |
| A6 | 1.15.0 : **`main` rouge** et une PR de gouvernance rouge sans changement du dépôt | PR #112 (`430ada1`), `64c1589` ; runs 36348592098 (main), 36348611929, 36348613646 | 09-27 | 2 | 1 | — | 3 | 0,4–1,1 |
| **Σ (a)** | | | 07-28 → 09-27 | **98** (12 hors A1) | **4 dédiées + 3 partagées** | 1 phase + **3 correctives** (dont 1 partagée) | **13** | **10,8–16,1** (2,6–6,6 hors A1) |

Sur les 12 publications de gsd-core depuis 1.9.0, **4 ont rougi la CI de VibeFlow** sans
changement du dépôt (1.11.0 via Node, 1.12.0, 1.13.0, 1.15.0). 1.14.0 et 1.16.0 → 1.19.0 n'ont
produit aucun T28-F rouge mesurable.

## 3. vibeflow-os — épisodes (b) bugs et pièges du moteur

| # | Épisode | Preuves | Dates | Commits | PR | Releases | CI rouges | Heures (bas–haut) |
|---|---|---|---|---|---|---|---|---|
| B1 | Commandes `state.*` (`record-session`, `milestone-switch`, `planned-phase`, mises à jour d'état des quick) **réécrivent le frontmatter de `STATE.md`** : compteurs régressés, `current_phase` déplacé ou supprimé, scalaires aplatis. Restaurations à la main, récurrentes sur trois mois. (Le gate `check-state-integrity` et ADR-063, livrés en Phase 21, sont comptés dans A1.) | `ef8826c`, `63aca55`, `f9a0f45`, `342a815` (07-28), `37bbf16` (08-15), `7e504ad`, `5583d3e` (09-15, STATE posé à la main), `0ba7694`, `9a987f6` (09-17), `9f39891` (09-24) ; run 31900398143 (main) | 07-28 → 09-24 | 10 | 0 (direct ou dans d'autres PR) | — | 1 (main) | 2,8–6,6 |
| B2 | Ship-note prescrite par `ship.md` amont (`— PR #M`) hors liste blanche de la garde D-04 → R1 muette, **`main` rouge** | `c5798b3` ; runs 31374913468, 31374921005, 31375091613, 31375232177 | 08-10 | 1 | 0 | — | 4 (dont 2 main) | 0,2–1,0 |
| B3 | Isolation `worktree` : retour des commits du worker non implémenté amont (`open-gsd/gsd-core#3302`), puis fix amont mesuré inerte (fork sur `origin/HEAD`) → Phase 35 refuse le ré-armement | `512ecbd`, `23e8f56` (issue postée), `e6c8f8f` ; PR #53 hors commits Node | 08-10 → 08-27 | 14 | 1 | v2.57.1 (phase) | 0 | 2,1–3,1 (borne basse : commits de mesure du 08-23 absents de la branche) |
| B4 | Garde d'isolation fail-closed sur un lab dont la racine n'est pas un dépôt git (gsd-core 1.13.0) : blocages répétés côté Scroll-Off ; contournement `use_worktrees=false` posé par l'installeur | PR #61 (`20cb7cf`), issue amont #4734 | 09-14 | 5 | 1 | v2.60.0 (partagée, « + hotfix use_worktrees ») | 0 | 1,1–1,4 |
| B5 | Gate amont #4683 (« un ID de menace = une ligne de registre ») : planning de phase réécrit pour le satisfaire | `0fd8f19` | 10-10 | 1 | 0 | — | 0 | 0,2–0,5 |
| **Σ (b)** | | | 07-28 → 10-10 | **31** | **2 dédiées + 1 partagée** | 1 phase + 1 partagée | **5** | **6,4–12,6** |

Pièges constatés sans coût git mesurable (non mesuré) : `phase.add` propose un mauvais numéro et
reformate le ROADMAP (2026-09-09, appel annulé, aucun commit) ; une sonde `state record-session`
lancée pour vérifier l'existence d'une commande a muté l'état (2026-08-04, rattrapé par
`git checkout`).

## 4. vibeflow-os — coûts hors dérive, présentés à part

### (c) Coût structurel de l'intégration

| # | Chantier | Preuves | Dates | Commits | PR | Releases | CI rouges | Heures (bas–haut) |
|---|---|---|---|---|---|---|---|---|
| C1 | Couplage explicite au moteur (capabilities, flags, voie unique) — Phase 23 | PR #30 | 08-01 → 08-04 | 192 | 1 | v2.47.0 | 0 | 25,5–28,8 |
| C2 | Activation et mesure du moteur (capacités dormantes, gates workstream) — Phase 24 | PR #34 ; 6 runs rouges R1/`test-workstream-policy` (30958443734 … 30963492481) | 08-04 → 08-05 | 111 | 1 | v2.48.0 | 6 | 13,0–13,2 |
| C3 | Workstreams amont « à moitié câblés » (7/89 workflows conscients) : PR de partition refusée, filet de divergence (Phase 39), partition réelle, gates workstream-aware | PR #27 (fermée, 2 runs rouges), #62, #94, #97, #100 | 07-30 → 09-25 | 122 | 5 | v2.60.0, v2.65.0, v2.66.0 (part.) | 2 | 17,7–23,7 |
| C4 | `complete-milestone` fait `git rm REQUIREMENTS.md` : outil de restauration + gate de survie du ledger — Phase 18 | PR #51 | 08-17 → 08-23 | 42 | 1 | v2.57.0 | 0 | 7,9–10,0 |
| C5 | Veille de release amont WKTR-03, puis extinction (faux positif permanent) | `024dad5`, `6565d63`, `d23d3cf` | 08-15 → 09-07 | 3 | 0 | — | 0 | 0,5–1,0 |
| C6 | Détection d'un gsd-core périmé par `/vf-update` | PR #64 | 09-14 | 1 | 1 | v2.61.0 | 0 | 0,2–0,5 |
| **Σ (c)** | | | | **471** | **9** | 7 (dont 1 partielle) | **8** | **64,8–77,2** |

Liés mais non comptés (frontière floue) : frontière d'altitude planning-core/moteur (Phase 14,
v2.30.0), signaux de démarrage du moteur (Phase 17, v2.42.0), partition au démarrage d'un lab
(PR #130), verrou de driver par compartiment (PR #152), `gsd-run.sh` (PR #169), gate de fidélité de
conversion multi-runtime (Phase 38).

**Empreinte dans le code (état `5ca57af`).** 18 scripts dédiés ou majoritairement dédiés à
encadrer GSD : **6 978 lignes** (3 802 en excluant les trois scripts mixtes `ensure-deps.sh`,
`inject-mcp-tools.sh`, `check-capability-activation.sh` et le trio de survie du ledger) — soit
3,3 % à 6,1 % des 114 240 lignes de code de `plugin/` + `scripts/`. Suites de test associées :
**8 019 lignes** (hors `test-dev-orchestrator.sh`, qui porte T14/T28-F parmi d'autres cas).
Références générées ou doctrinales (index, `workstreams.md`, `GSD-PIPELINE.md`, `gsd-handoff.md`,
`intent-routing.md`…) : 1 341 lignes. ADR consacrés au moteur (055, 058, 061, 062, 063, 064, 068,
069) : 1 162 lignes sur 3 208. 10 occurrences de `gsd-core` dans `.github/workflows/ci.yml`.

### (d) Migration legacy → `@opengsd/gsd-core`

Déclencheur : dépôt amont archivé le 2026-06-26 après le départ de son créateur ; successeur
`open-gsd/gsd-core`.

| # | Étape | Preuves | Dates | Commits | Releases | Heures (bas–haut) |
|---|---|---|---|---|---|---|
| D1 | Étude de migration (Phase 10) | `1b8b8ff`, `e439c4f`, `e748915` | 07-26 | 3 | — | 1,6–1,8 |
| D2 | Bascule (Phase 11) + plafond `^1` | `aed79f6` → `783f2b4` | 07-26 | 27 | **v2.39.0** | 2,5–2,7 |
| D3 | Migration pilotée par `/vf-update` (Phase 19, ADR-058) | `377e96b` → `beb7365` | 07-28 | 23 | **v2.43.0** | 2,8–5,2 |
| **Σ (d)** | | | 07-26 → 07-28 | **53** | 2 | **6,9–9,7** |

Non mesuré : migration du poste (purge du legacy, hors git) ; détection legacy de v2.28.0 (PR #17,
mêlée à un autre chantier).

## 5. Scroll-Off

**Dans les trois dépôts git : zéro commit, zéro PR imputable à GSD.** Le planning n'est pas
versionné (`commit_docs: false`, parent non-git) ; aucun message de commit de `backend` (425
commits), `frontend` (1 498) ou `website` (16) ne traite du moteur, de l'état, des worktrees ou
des hooks. Les épisodes n'existent que dans le planning local et la mémoire d'agents :

| # | Classe | Épisode | Trace | Date | Coût |
|---|---|---|---|---|---|
| S1 | (b) | Garde d'isolation fail-closed sur racine non-git : 4 blocages dans une journée de session, contournement par sentinelle qui expire au bout de 10 min, puis `workflow.use_worktrees: false` | `.planning/config.json`, `.gsd/dispatch-isolation-sentinel.json` ; correctif côté VibeFlow (B4) | 2026-09-14 | non mesuré (transcripts hors périmètre) |
| S2 | (b) | `gsd-quick` en isolation worktree forke depuis `origin/HEAD`, pas depuis la branche locale (même cause que B3) | mémoire d'agent `vf-coder` | non daté | non mesuré, aucun incident chiffré |
| S3 | (c) | `gsd-plan-phase` sans granularité « lot » : contournement par plan écrit à la main en parallèle | mémoire d'agent `vf-coder` | non daté | non mesuré |
| S4 | (c), ambigu | Sections générées par GSD dans `CLAUDE.md` (~300 lignes) réécrites par le générateur, donc impossibles à alléger à la main ; `STATE.md` archivé à 195 Ko / 1 406 lignes lors d'un allègement de méthode | `.planning/ops/2026-09-28_plan-allegement.md` | 2026-09-28 | non mesuré |

Scroll-Off est sorti du périmètre VibeFlow le 2026-09-15 : la fenêtre d'observation est courte.

## 6. Totaux

| Périmètre | Commits | PR dédiées (+ partagées) | Releases correctives | CI rouges | Heures (bas–haut) |
|---|---|---|---|---|---|
| (a) dérive amont | 98 (12 hors A1) | 4 (+3) | 3 (dont 1 partagée) + v2.45.0 | 13 | 10,8–16,1 (2,6–6,6 hors A1) |
| (b) bugs et pièges | 31 | 2 (+1) | 0 (+ v2.57.1 de phase, v2.60.0 partagée) | 5 | 6,4–12,6 |
| **(a)+(b) vibeflow-os** | **129** (43 hors A1) | **6 (+4)** | **3** | **18** | **17,2–28,7** (9,0–19,2 hors A1) |
| (c) structurel | 471 | 9 | 7 | 8 | 64,8–77,2 |
| (d) migration | 53 | 0 | 2 | 0 | 6,9–9,7 |
| **Tout GSD vibeflow-os** | **653** | **15 (+4)** | — | **26** | **88,9–115,6** |
| Scroll-Off | 0 | 0 | 0 | non mesuré | non mesuré |

**Part de l'historique de vibeflow-os.**

- (a)+(b) : 3,9 % des commits (1,3 % hors A1), 3,7 % des PR (6,1 % avec les partagées),
  8,6 % des runs CI en échec (1,9 % de tous les runs), environ 4 à 6 % des heures estimées.
  `main` rougi par GSD : 4 runs (B2 ×2, B1, A6).
- Toutes classes : 19,8 % des commits, 9,1 % des PR dédiées, 12,4 % des runs en échec, environ
  22 % des heures estimées.

## 7. Contrefactuel : épinglage exact de gsd-core

Hypothèse : version exacte, montée volontaire par `/vf-update` (étape E2 de SEED-003).

**Évité par l'épinglage** — la dérive (a) hors A1 :

- les **13 runs CI rouges** de A3 à A6, dont le `main` rouge du 09-27 : aucune publication amont
  ne pourrait plus rougir une PR sans rapport, et le va-et-vient local/CI de T28-F disparaît ;
- la rétrogradation silencieuse sous Node 22 (A3) ;
- le caractère **non planifié** de v2.47.1, v2.58.0 et de la part GSD de v2.59.1.

Le travail lui-même ne disparaît pas : régénérer les deux index, router les briques nouvelles,
monter Node pour passer 1.11 restent dus, mais dans une PR de montée choisie et non sur une PR
sans rapport. Gain réel estimé : 2,6–6,6 h, 12 commits replacés, 13 rouges et 3 releases
d'urgence évités. Coût : la montée devient un geste à faire, et C6 (détection du périmé) reste
nécessaire sous une autre forme, contre la version épinglée.

**Non évité par l'épinglage** — il faudrait une correction du moteur ou une sortie de GSD :

- toute la classe (b) : réécriture de `STATE.md` par `state.*` (récurrente de 1.8 à 1.15 au
  moins), format de ship-note amont, isolation worktree (#3302 puis fork sur `origin/HEAD`), garde
  fail-closed sur racine non-git, gates amont. Au total 6,4–12,6 h, 31 commits, 5 rouges ;
- la classe (c) : couplage, workstreams à moitié câblés, `complete-milestone` qui supprime le
  ledger, environ 7 000 lignes de scripts et 8 000 lignes de tests. Une sortie ne la supprimerait
  pas entièrement : une partie (gates d'intégrité, partition) serait à réécrire contre un moteur
  maison ;
- A1, l'alignement volontaire : il est dû à chaque montée, épinglée ou non ;
- (d), la migration, est un coût passé et ponctuel, causé par l'abandon de l'amont : l'épinglage
  ne l'aurait que retardé.

**Lecture face à la règle de décision de SEED-003.** La dérive proprement dite est faible et
presque entièrement évitable par l'épinglage. Le coût qui tient au moteur lui-même ((b), environ
6 à 13 h) est du même ordre que la dérive. Le coût dominant est (c) : dix fois plus d'heures, mais
il a aussi acheté des capacités (workstreams, gates). Ce rapport chiffre ; le verdict appartient
à l'étude de synthèse.

## 8. Épisodes ambigus, non comptés

- PR #39 / **v2.50.1** (issue #38) : isolation worktree retirée de 13 agents. Cause première :
  VibeFlow a armé l'isolation sans distribuer sa précondition. Le trou amont (#3302) n'a fait
  qu'aggraver. 1 commit, 1 hotfix.
- Run 31893963868 (08-15) : R1 muette sur un `status:` de `STATE.md` hors liste blanche après un
  squash. On ne sait pas qui l'a écrit (outil ou agent). 1 run.
- « Hooks GSD introuvables dans les worktrees » (BACKLOG, 2026-09-28 → 09-30) : `0be13a9`,
  `4ee7667`, 2 commits documentaires.
- Phase 27 : spike `claude_orchestration` refusé faute de merge-back amont. Lié à B3, mais c'est
  une décision de conception.
- Les parties de A1 sans rapport avec GSD (injection MCP au scope global, contrat
  `estimate:`/`actuals:`) : laissées dans A1, ce qui le gonfle.

## 9. Limites

- **Heures** : ce sont des estimations de temps de session tirées des horodatages de commits.
  Elles sous-estiment le diagnostic qui ne laisse pas de commit et la recherche dans les
  transcripts. Elles surestiment là où des sessions concurrentes se chevauchent. Les épisodes à un
  seul commit sont planchers. Les transcripts sont mesurés ailleurs.
- **Commits** : `--all` contient des doublons de rebase. Les branches squash-mergées ne sont
  comptées que par l'API des PR. Certaines mesures de la Phase 35 ne sont pas sur la branche.
- **CI** : journaux expirés pour 29 runs (07-25 → 07-28). Ce sont les journaux de la réparation
  initiale de la CI, rouge sur 100 % de ses runs depuis sa pose, sans attribution GSD connue. Non
  mesurés. Seuls les runs dont le journal nomme la cause sont attribués.
- **Scroll-Off** : planning non versionné et transcripts hors périmètre. L'absence de commits ne
  prouve pas l'absence de coût : les blocages de S1 sont réels (4 dans une journée) mais leur durée
  n'est pas mesurée.
- **Frontières de classe** : (b) et (c) se recouvrent. B1 a produit un gate rangé en A1. C4 est
  né d'un piège. Les choix sont annoncés épisode par épisode, et les bornes changent de quelques
  heures selon le classement retenu, pas d'ordre de grandeur.
- Les mémoires persistantes ont servi d'index et non de preuve. Une affirmation de mémoire
  contredite par git l'aurait été au profit de git ; aucune contradiction majeure n'a été relevée.
