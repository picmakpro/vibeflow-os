---
gsd_state_version: 1.0
milestone: gsd-migration
milestone_name: Migration package GSD
current_phase: 26
current_phase_name: Manuel utilisateur VibeFlow (manual/) — cadrage capturé, mission d'équipe en cours (branche feat/phase-26-manuel-utilisateur)
status: in_progress
stopped_at: "Phase 26 — contexte capturé (26-CONTEXT.md, commit b9001b1), planification en cours. manual/ (bilingue FR+EN, hors git par amendement de mission — .git/info/exclude) reste le livrable réel, non versionné ; seuls les artefacts de suivi sous .planning/phases/VFDO-26-*/ sont committés. Reprendre par /gsd-plan-phase 26."
last_updated: "2026-08-01T00:00:00.000Z"
last_activity: 2026-08-01 (Phase 26 — cadrage capturé, plan en cours)

# ⚠ Phase 21 close par sa gouvernance (plan 21-05), même patron que 20-07/c01f813 : 5/5 plans
# livrés, vérification PASS PARTIEL 7/8 comblée (CI remise au vert — compteur de suites 44→45 —,
# dev-orchestrator bumpé v2.9.0, planning-core v2.5.3, ROADMAP §Phase 21 recalé, 4 warnings W1-W4
# traités : check-state-integrity.sh câblé au job gates de la CI, ADR-063 23→25 cas, team-kernel.md
# porte le recoupement #1995/#2608, inject-mcp-tools.sh nomme --force sur le rc=3 mode fichier
# unique). Release racine v2.45.0 préparée en commits locaux (triade + 2 historiques README +
# CHANGELOG racine) — AUCUN tag, AUCUN merge, AUCUN push : réservés à Samuel. Prochain geste
# humain : merger la PR, puis `git tag -a v2.45.0` et `gh release create`.
progress:
  total_phases: 26
  completed_phases: 21
  total_plans: 62
  completed_plans: 62
# ⚠ Compteurs curés À LA MAIN — PAS régénérés par `gsd-tools state` (ADR-063, cf.
# plugin/dev-orchestrator/references/mission-contracts.md §STATE.md : toute invocation force
# resync:true non désactivable et reproduirait la régression corrigée ici). Toute future mise à
# jour de ce bloc = édition manuelle, gardée par plugin/conductor/scripts/check-state-integrity.sh
# (compteurs non régressés au sein du même jalon `gsd-migration`).
# ⚠ Recalé le 2026-07-31 à la fusion de `main` dans la branche Phase 21 : la PR #23 (Phase 22)
# ayant été mergée AVANT la #22, ces compteurs cumulent les deux phases — +1 phase complète
# (22) et +3 plans livrés (22-01..03), et total_phases passe à 25 (phases 23/24/25 inscrites au
# ROADMAP par la Phase 22, hors périmètre, en attente d'arbitrage).
# ⚠ Recompté le 2026-08-01 depuis le disque ET la checklist du ROADMAP, une fois celle-ci posée
# (elle n'avait jamais existé : le moteur voyait 0 phase terminée). 21 phases complètes sur 25
# — les 4 restantes (18, 23, 24, 25) sont inscrites sans aucun plan. 62 PLAN.md sur disque, tous
# rattachés à une phase complète, d'où completed_plans = total_plans.
#
# Baseline héritée telle quelle (12/54/39), recalée le 2026-07-31 lors de la clôture 20-07 après une
# régression constatée (completed_phases 11→10, total_plans 53→49, completed_plans 37→29,
# current_phase resté à 19). Le plan 21-04 n'a PAS ré-audité l'exacte composition de ces 12
# phases — seul le delta depuis cette baseline était vérifié : total_plans et completed_plans
# +1/+1 (21-04 lui-même). Ce plan (21-05) ferme la Phase 21 par vérification goal-backward
# (21-VERIFICATION.md, PASS PARTIEL 7/8, comblé) : completed_phases +1 (12→13), total_plans et
# completed_plans +1/+1 (21-05 lui-même, PLAN+SUMMARY) — jamais un delta supposé, chaque
# incrément correspond à un artefact livré et vérifiable sur disque.
#
# Point ouvert, NON tranché par ce plan (remonté à Samuel, ADR-063 §Décision) : une lecture
# ROADMAP-trust stricte (« une phase shippée compte, qu'elle ait ou non un SUMMARY.md par plan » —
# le repli que `roadmap analyze` amont applique et que `buildStateFrontmatter` n'applique pas,
# Cause A) classerait significativement PLUS de phases complètes que 12 (`.planning/ROADMAP.md`
# marque les Phases 1-17, 19 et 20 « Complete »/shippées). Trancher entre backfiller les
# `SUMMARY.md` manquants (11/12/13/14) ou adopter durablement une lecture ROADMAP-trust locale
# reste une décision produit, pas une extraction mécanique — non faite ici par choix, pas par
# oubli.
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-26 — charte rouverte : 17 modules, D2/D6 renversées)

**Core value:** Dire « aide-moi à dev » déclenche le pipeline GSD complet sans jamais connaître GSD/Superpowers.
**Current focus:** Phase 19 **terminée, vérifiée et SHIPPÉE `v2.43.0`** (2026-07-28) — la migration
`get-shit-done-cc` → `@opengsd/gsd-core` livrée en v2.39.0 atteint enfin les **postes déjà équipés** :
`/vf-update` dit l'état du moteur avant tout stop et propose la bascule sous confirmation ADR-031.
Modules `dev-orchestrator` v2.7.0 + `conductor` v1.16.0. Verdict `19-VERIFICATION.md` : **PASS 6/7**.
Phase 17 **terminée, vérifiée et SHIPPÉE `v2.42.0`** (2026-07-28) — signaux de démarrage
du moteur de dev (`check-dev-bootstrap.sh`, `check-doc-drift.sh`, `discover-unintegrated-docs.sh --hook`,
hooks `SessionStart`), module `dev-orchestrator` v2.6.0. SC5 (advisory/lecture seule) et SC6
(portabilité macOS+Linux) prouvés par exécution, pas par lecture. Plus aucun milestone ouvert.
**Release `v2.42.0` publiée** le 2026-07-28 (tag annoté + release GitHub, `check-release-tag --remote`
✓, `check-version-sync` ✓ après synchro 39 → 41 suites dans les deux README).
Phase 18 **requalifiée en variante réduite** le 2026-07-28 (étude `STUDY.md`, verdict GO-RÉDUIT) —
non démarrée. Pré-requis bloquant : la RFC upstream `open-gsd/gsd-core` part **avant** toute
implémentation du gate.

**Dette backlog héritée — CLOSE le 2026-07-28** (commits `607844c`, `213ea1a`, hors release) :

- `known-versions.txt` jamais posé → cause racine corrigée côté engine. `copy_module_scripts()`
  pose désormais les fichiers de données `*.txt` (sans `chmod +x`) ; T9 borne le glob par le bas
  et par le haut, discriminance prouvée par mutation.

- `brick_routed()` grep naïf → fonction rendue **stricte** (la carte est la seule source, comme la
  spec du 2026-07-25 l'affirmait déjà). Mesure : sur 71 briques, **0** n'était couverte par un
  repli seul — les deux gardes étaient mortes ET rendaient T14 insensible. T14c les remplace par
  un filet qui échoue si une brique est citée par un SKILL.md sans l'être par la carte.
  Discriminance prouvée par mutation sur `gsd-quick`, le cas partagé qui produisait le faux vert.

Autre candidat restant : sortie d'expérimental de `mobile-test`(-team). Reliquat non traité :
templates-mémoire jamais posés à l'install (arbitrage engine, cf. §Decisions) — la correction
`*.txt` ci-dessus ne les couvre pas (ce sont des `.md` dans un sous-dossier).

## Current Position

Phase: 21 **complète** — Alignement du moteur GSD sur `@opengsd/gsd-core` 1.9.0. Rituel allégé
(arbitrage Samuel, `.planning/missions/2026-07-31-delta-gsd-core-1.9.0.md`) : pas de
`gsd-discuss-phase` séparé, périmètre exhaustif directement dérivé du digest de mission. 5 plans :
21-01 — défaut MCP actif corrigé (`inject-mcp-tools.sh` découvre le scope global MCP,
`~/.claude.json`, plus seulement `./.mcp.json`), WINDOWS #4 clos ; 21-02 — les trois contrats amont
(`estimate:`/`actuals:` relayés verbatim par `vf-coder`/`vf-dev-manager`, ADR-061 tranchant la
disjonction lanes de revue cross-AI amont / étage de revue de code ADR-060, hypothèse datée sur le
dispatch nommé dans `team-kernel.md`) ; 21-03 — purge de la dette de version figée 1.8.0 → 1.9.0
(6 fichiers, cas 8 de `test-check-gsd-engine.sh` déplacé avec le texte qu'il vérifie, preuve par
mutation) et ADR-062 (les 2 hooks 1.9.0 non câblés confrontés séparément à leur contrat
d'activation — absence correcte dans les deux cas, `merge-hooks.sh` non modifié) ; 21-04 —
`check-state-integrity.sh` (gate anti-régression du frontmatter de ce fichier, module `conductor`
v1.18.0) et ADR-063 (arbitrage de l'anomalie d'agrégation ci-dessous : dette d'artefact locale
doublée d'un vrai bug amont non scopé sur l'extraction `Phase`, cause de ce même correctif de
mise en forme du corps de ce fichier) ; 21-05 — clôture de gouvernance : CI remise au vert
(compteur de suites 44→45, `.planning/WINDOWS.md` recalé), `dev-orchestrator` bumpé v2.9.0,
`planning-core` v2.5.3, `.planning/ROADMAP.md` §Phase 21 recalé (5/5 plans, Requirements
tranchés), les 4 warnings de `21-VERIFICATION.md` traités (`check-state-integrity.sh` câblé au
job `gates` de la CI, ADR-063 25 cas, `team-kernel.md` porte le recoupement #1995/#2608,
`inject-mcp-tools.sh` nomme `--force` sur le rc=3 mode fichier unique), release racine v2.45.0
préparée en commits locaux (jamais taguée).
Status: Complète (5/5 plans exécutés, gates de sortie verts, release préparée non taguée).
Last activity: 2026-07-31 (plan 21-05, clôture de gouvernance).

**Anomalie d'agrégation instruite (ADR-063).** Le commentaire YAML du frontmatter ci-dessus daté du
2026-07-31 signalait une régression silencieuse de `completed_phases`/`total_plans`/
`completed_plans` et un `current_phase` resté figé après la clôture de la Phase 20. Diagnostic établi
sur pièce dans `@opengsd/gsd-core` 1.9.0 : Cause A (dette d'artefact locale — `buildStateFrontmatter`
n'a pas le repli ROADMAP que `roadmap analyze` a, les Phases 11/12/13/14 shippées sans `SUMMARY.md`
le révèlent) et Cause B (vrai bug amont — `stateExtractField(body, 'Phase')` prend le premier
`^Phase:` du corps entier sans scope, alors que la même fonction scope `Stopped At`/`Paused At` à
`## Session`). Remédiation : aucun patch du paquet tiers ; `check-state-integrity.sh` garde les deux
invariants (compteurs non régressés au sein d'un même jalon, une seule ligne `^Phase:` dans ce
fichier) ; convention d'archivage posée ici même (`**Phase archivée :**` au lieu de `Phase:` pour
toute section non courante) ; interdiction documentée d'invoquer `gsd-tools state` pour « réparer »
ce fichier (force `resync: true`, régénérerait la régression) ; signalement amont rédigé pour les
deux points de la Cause B, dépôt réservé à validation humaine. Le backfill des ~20 `SUMMARY.md`
manquants (Cause A) n'est **pas tranché** — remonté à Samuel avec son coût (ADR-063 §Décision).

---

**Phase archivée :** 19 **complète — vérifiée et shippée `v2.43.0`** (tag annoté + release GitHub, `check-release-tag --remote` ✓)
Migration du moteur GSD pilotée par `/vf-update`. Livrée en mission d'équipe le 2026-07-28, en
autonomie complète (DAG à 5 nœuds, `.planning/missions/dag-phase19.json` : n1 plan · n2 exécution ·
n3 gate portabilité · n4 audit sécurité/infra · n5 clôture, avec **un `reopen` unique** de n2 après
la vérification goal-backward). Cadrage préalable non refait (`19-CONTEXT.md`, 6 arbitrages tranchés
par Samuel en conversation). Livré : `check-gsd-engine.sh` (3 états `absent`/`legacy`/`gsd-core`,
exits 0/2/3, suite dédiée 15 cas), `ensure-deps.sh` (détecteur à 3 valeurs, fin du `skip` sur legacy,
chemin `--migrate-engine` chaîné sur la ré-injection MCP, message de nettoyage exact et atteignable),
`inject-mcp-tools.sh --verify`, `vf-update/SKILL.md` (diagnostic à deux volets, ligne de confirmation
moteur indépendante, §Garde-fous réécrit), **ADR-058**. Modules `dev-orchestrator` **v2.7.0** et
`conductor` **v1.16.0** (premier cas à deux modules bumpés dans la même phase).
Status: Shippée (v2.43.0).
Last activity: 2026-07-28 (clôture Phase 19 + release v2.43.0)

**Verdict `19-VERIFICATION.md` : PASS, 6/7 critères.** SC2 reste `PRESENT_BEHAVIOR_UNVERIFIED` — le
volet moteur du skill est présent et son contrat d'exit prouvé, mais c'est du **comportement d'agent**
non éprouvable par test. **Recette humaine en attente** : parcours `/vf-update` sur un poste legacy,
acceptation **puis** refus de la ligne moteur.

**Le défaut que trois étages ont laissé passer — à retenir.** Revue de code (PASS), gate de
portabilité (macOS + Ubuntu 24.04 + Debian 12, tout vert) et audit sécurité (6/6 angles PASS) ont
tous validé un garde-fou **inerte** : `patch_gsd_executor_mcp()` appelait `inject-mcp-tools.sh
--verify` **sans `--force`**, alors que l'injection juste au-dessus le passait (obligatoire —
`gsd-executor.md` ne porte pas `vf-mcp-consumer`). La cible était donc systématiquement écartée : le
verdict sortait **toujours en 3**, jamais 0 « conforme » ni 1 « serveur manquant », et un `ERROR`
bruyant tombait à chaque bootstrap sur tout lab sans `.mcp.json`. Seul le vérificateur goal-backward
l'a vu, **en mutant le bloc livré** : sa suppression complète laissait la suite à 73 OK / 0 KO.
Deux causes nommables : le compte rendu prouvait une **présence** (`grep -c 'verify' → 7`) et non un
comportement ; les tests exerçaient `--force --verify`, **une forme que la production n'émettait
jamais**. Corrigé (`94587c5`) avec contrat de relais F13 explicite (seul `rc=1` alarme, `rc=3` =
INDÉTERMINÉ informatif) et cas **T2m** qui exerce le chaînage réel — létal sur 3 mutations.

**Dette inscrite à `CONCERNS.md`** (commit `164ff35`) : la sonde cross-module `conductor` →
`dev-orchestrator` s'éteindrait **sans aucun signal** si l'engine cessait de matérialiser les scripts
de tous les modules à plat dans le même `.claude/scripts/`. Le silence sur script absent est voulu
(un lab content/growth ne doit rien voir), mais il rend le mode dégradé indiscernable du nominal —
même famille que le trou que cette phase vient de fermer. Risque auto-documenté en ADR-058.

**Release `v2.43.0` PUBLIÉE** le 2026-07-28 (commit `70c5720`, tag annoté poussé, release GitHub,
`check-release-tag.sh --remote` → ✓). Le compteur « N suites » des 2 README racine a été rattrapé
dans le même commit (41 → **42**), comme prévu : `check-version-sync.sh` est repassé ✓ avant le tag.
Gates rejoués avant release : **42 suites vertes**, `check-agents --strict` ✓ sur les 6 dossiers
d'agents, 17 triades par module ✓.

**Reste en attente — recette humaine de SC2** : le volet moteur du skill est présent et son contrat
d'exit prouvé, mais c'est du **comportement d'agent** non éprouvable par test. À recetter : parcours
`/vf-update` sur un poste legacy, **acceptation PUIS refus** de la ligne moteur.

---

**Phase archivée :** 17 **complète — vérifiée et shippée `v2.42.0`** (tag annoté + release GitHub)
<!-- Corrigé le 2026-07-28 : cette section affirmait encore « release racine en attente (VERSION
     intouchée : 2.41.0) » alors que v2.42.0 était publiée depuis le matin. Contradiction interne
     avec le §Current focus du même fichier, qui a fait conclure à tort à vf-dev-manager qu'il
     restait DEUX phases non shippées (17 et 19). Vérifié sur pièce avant la release v2.43.0 :
     `git show v2.42.0:plugin/dev-orchestrator/scripts/check-doc-drift.sh` répond — la Phase 17
     est bien dans le tag. Une section de phase datée ne doit jamais contredire le focus courant. -->
Signaux de démarrage du moteur de dev. Livrée en mission d'équipe (DAG à 5 nœuds : n1 cadrage+plan ·
n2 exécution · n3 gate portabilité · n4 audit advisory/read-only · un `reopen` unique après fusion des
deux juges · n5 clôture, `.planning/missions/dag-phase17.json`). Livré : `check-dev-bootstrap.sh`
(continuum à 4 états), `check-doc-drift.sh`, `discover-unintegrated-docs.sh --hook`,
`hooks/hooks.json`, section *Signaux de démarrage* dans `AGENT.md`, 2 nouvelles suites de tests.
Module `dev-orchestrator` **v2.6.0** (collision de version résolue : la Phase 16 concurrente avait
déjà pris v2.5.0, cible ajustée à v2.6.0 — commit `5a8b6a8`).
Status: Shippée (v2.42.0).
Last activity: 2026-07-28 (clôture Phase 17)

**SC5 (advisory / lecture seule) — CONFORME.** Prouvé par exécution, pas par lecture : lecture seule
OUI (seul `mktemp` de `discover-unintegrated-docs.sh:91-93`, apparié au `trap ... EXIT` ligne 94, borné
à `$TMPDIR`) · aucun `exit 1` OUI (seuls 0/3/64 ; `set -uo pipefail`, pas de `set -e`) · aucun blocage
de tour OUI (`hooks.json` = un seul groupe `SessionStart`, 3 commandes chacune suffixée `|| true`,
aucun `Stop`/`PreToolUse`). Robustesse : 5 fixtures de frontmatter hostiles (injection shell, octet de
contrôle 0x01, délimiteur tronqué, `$(whoami)`) → stdout VIDE et exit 3 dans les 5 cas ; `node_modules`
de 20 000 fichiers → 0.007s (élagage `-prune` confirmé) ; hors dépôt git sur chemin à espace/UTF-8 →
silence propre. Toutes les menaces `high` du threat model closes.

**SC6 (portabilité macOS ET Linux) — PROUVÉ.** Compteurs **identiques** sur trois environnements :
macOS bash 3.2.57, Debian 12 bash 5.2.15, Ubuntu 24.04 bash 5.2.21 (OS exact de
`runs-on: ubuntu-latest`) → `test-check-dev-bootstrap.sh` 23 ok/0 ko · `test-check-doc-drift.sh` 21
ok/0 ko · `test-discover-unintegrated-docs.sh` 22 ok/0 ko. Aucun test sauté silencieusement. Zéro
piège BSD/GNU trouvé. Aucun edit de `ci.yml` nécessaire.

**Comblement post-exécution** (commit `6e33b14`, après fusion des verdicts n3/n4) : cas 7 de
`test-discover-unintegrated-docs.sh` rendu discriminant (il était tautologique : vert avec ou sans le
filtre glob — prouvé par mutation, 21 ok/1 ko après retrait du filtre) ; boucle T21 de
`test-dev-orchestrator.sh` élargie à `discover-unintegrated-docs.sh`, seul des 3 scripts à utiliser
`mktemp`.

**Deux dettes inscrites à `CONCERNS.md`** (constatées pendant la mission, pas corrigées — hors
mandat de clôture) : le verrou de driver n'empêche techniquement rien (déclaratif, pas contraignant —
la Phase 16 a continué à commiter pendant que la Phase 17 tenait le verrou) ; le gate ADR-044 est un
faux vert dans son invocation nue prescrite par la spec (`check-agents.sh` sans argument sort exit 0
sans rien vérifier, `.claude/agents` étant absent de ce repo).

**Réservé à validation humaine** : release de clôture (bump `VERSION`/`plugin.json`/`marketplace.json`

+ historique des 2 README, tag annoté poussé, release GitHub, `check-release-tag.sh --remote` → ✓).

Pré-requis identifié : `scripts/check-version-sync.sh` est actuellement **rouge** — `README.md` et
`README.fr.md` annoncent « 39 suites » contre 41 réelles (les 2 suites ajoutées par cette phase), à
corriger avant tout bump.

---

**Phase archivée :** 16 **complète — shippée `v2.41.0`** (tag annoté + release GitHub, `check-release-tag --remote` ✓)
Cloisonnement complet des dispatches. Livrée en mission d'équipe le 2026-07-27, en autonomie complète
(cadrage rétroactif, aucun checkpoint humain). **4/4 Success Criteria tenus**, SC3 amendé (voir plus
bas). Suites rejouées à la main avant release : 58 check-agents · 51 dev · 12 design ·
`check-version-sync` ✓ · 6/6 modules `--strict` exit 0 · 6/6 en monde fermé (`--resolve-agents=strict`,
le job CI). Modules : `conductor` v1.15.0 · `dev-orchestrator` v2.5.0.
Status: Shippée.
Last activity: 2026-07-27 (mission d'équipe Phase 16 + release v2.41.0)

**Amendement SC3 — une allowlist `Agent(...)` n'est pas un sandbox runtime.** Découverte de la
mission, doc officielle citée verbatim dans l'en-tête de `check-agents.sh` : le runtime **ignore** la
liste de noms entre parenthèses dans la définition d'un sous-agent ; seule la présence de
`Agent`/`Task` dans `tools:` compte pour lui. L'allowlist n'est une vraie restriction runtime que
pour un agent incarné en thread principal (`claude --agent`). Elle reste donc un **contrat documenté,
enforcé par le lint et par lui seul** — ce qui vaut rétroactivement pour les allowlists des deux
managers posées en Phase 15. Le cloisonnement est réel, mais c'est un gate machine, pas un bac à sable.

**Deux dettes fermées** (retirées de `CONCERNS.md`) : accès `Agent` non scopé des 3 workers, et
`check-agents --strict` sans périmètre tiers (les 66 faux positifs du scope user, réglés par
`--third-party-prefix` et vérifiés empiriquement sur `~/.claude/agents`).

**Incident de concurrence à traiter — verrou de driver expiré en cours de mission.** Le TTL est de
30 min ; plusieurs workers ont tourné 10 à 22 min et les heartbeats du manager étaient placés *entre*
les frontières de dispatch, jamais pendant. Le lock a expiré, la session concurrente (Phase 17) l'a
récupéré, et le `release` final du manager Phase 16 a rendu `not-owner`. **Deux managers ont donc
tourné en parallèle** — sans dégât ici parce que les périmètres étaient disjoints, mais par chance,
pas par construction. L'invariant « un seul driver » n'est pas tenu face à des workers plus longs que
le TTL. À instruire (candidat phase ou correctif kernel : heartbeat pendant l'attente d'un worker,
ou TTL indexé sur la durée réelle des dispatches).

---

**Phase archivée :** 13 **complète — shippée `v2.37.0`** — milestone vf-routing CLOS
Plans: 13-01 ✅ (découverte outillée, BRDG-02) · 13-02 ✅ (câblage agent, BRDG-01/BRDG-03).
Vérification goal-backward **PASS** (`13-VERIFICATION.md`) : 4/4 critères dans le mandat, 3/3 BRDG,
22/22 must-haves, 0 blocker. Suites : 16 ok · 30 OK/0 KO · 10 OK · check-agents ✓ · check-version-sync ✓.
Module `dev-orchestrator` bumpé **v2.2.0** ; `VERSION` racine volontairement **intouchée** (v2.36.2).
Status: Milestone clos — release `v2.37.0` publiée et taggée le 2026-07-26.
Last activity: 2026-07-26 (mission d'équipe : exécution complète de la Phase 13)

**Phases 12 et 14 livrées et publiées sur `main`** :

- Phase 12 (Routage fin & verbes `/vf-*`) — 6/6 plans · release **`v2.31.0`**. Livrait 31 verbes et la
  rule de préséance ; **la façade `/vf-*` a été supprimée depuis en v2.33.0** (bascule agentique, spec
  `2026-07-25-suppression-facade-vf-design.md`) — subsistent la carte d'intention unique de
  `vibeflow-dev` et les skills `vf-auto` / `vf-dev`.

- Phase 14 (Frontière d'altitude `planning-core` / moteur GSD) — 7/7 plans · release **`v2.30.0`** ·
  **ADR-055** (renuméroté au merge : `ADR-054` était déjà pris par la portabilité Windows publiée en
  v2.29.0). 92 assertions vertes.

**Depuis la clôture des phases 12/14, 5 releases hors milestone** (v2.32.0 → v2.36.1) : enforcement CI,
bascule agentique, team-kernel transverse, 3 bundles métier matérialisés, recettes UAT, refonte README.
Versions modules au 2026-07-26 : dev-orchestrator v2.1.1 · design-orchestrator v1.2.1 ·
conductor v1.14.1 · planning-core v2.5.1 · consolidator v1.8.0.

Milestone `gsd-migration` (Phases 10-11) reste ouvert et **en attente** — chantier indépendant, non bloquant.
Milestone précédent memory-swarm-rnd **SHIPPÉ v2.28.0** (ADR-052 mémoire vivante + ADR-053 swarm).

Progress: [██████░░░░] 59%

## Performance Metrics

**Velocity:**

- Total plans completed: 26+ (13 mesurés phases 1-6 ci-dessous + 6 en Phase 12 + 7 en Phase 14 ;
  le compteur automatique n'a jamais été alimenté — reconstruit le 2026-07-26)

- Average duration: ~6 min/plan (sur les 13 plans mesurés)
- Total execution time: non mesuré au-delà de la Phase 6

**By Phase:** *(mesures disponibles uniquement — phases 7, 8, 9, 12 et 14 non instrumentées)*

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| Phase 01-dev-orchestrator P01 | 10min | 2 tasks | 6 files |
| Phase 01 P02 | 10 | 2 tasks | 1 files |
| Phase 01-dev-orchestrator P03 | 12 min | 2 tasks | 2 files |
| Phase 01 P04 | ~6 min | 2 tasks | 13 files |
| Phase 01-dev-orchestrator P05 | ~10min | 2 tasks | 4 files |
| Phase 02-manifeste-resolveur P01 | 5min | 2 tasks | 8 files |
| Phase 02-manifeste-resolveur P02 | ~5min | 2 tasks | 2 files |
| Phase 03-engine-scope-aware P01 | 3min | 3 tasks | 2 files |
| Phase 03 P02 | 6min | 2 tasks | 2 files |
| Phase 04 P01 | ~1 min | 2 tasks | 3 files |
| Phase 04 P02 | 5min | 2 tasks | 3 files |
| Phase 05 P01 | 2 | 3 tasks | 5 files |
| Phase 06 P01 | 1min | 2 tasks | 2 files |
| Phase VFDO-19 P01 | 15min | 3 tasks | 2 files |
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase VFDO-19 P02 | 90min | 3 tasks | 4 files |
| Phase 20 P07 | ~1h10 | 3 tasks | 26 files |

## Accumulated Context

### Roadmap Evolution

- 2026-08-01 : **Phase 26 ajoutée** — « Manuel utilisateur VibeFlow (manual/) ». Origine : demande
  de Samuel (réorganiser les specs et offrir une doc lisible aux arrivants sans les plonger dans
  les docs de gestion de projet). Un manuel « vitrine » sous `manual/` à la racine : arborescence
  thématique numérotée qui descend progressivement sous le capot, pages courtes chaînées
  prev/sommaire/next, index avec graphiques mermaid, bilingue FR + EN. `README`/`INSTALL`
  maigrissent et pointent dessus au lieu de dupliquer. Cible : lecteurs humains — ce dossier sera
  généralement ignoré par les agents de maintenance du repo.

- 2026-07-31 : **Phase 22 ajoutée** — « Hygiène documentaire — doctrine de sortie et captation
  d'intention ». Origine : demande de Samuel (« le dev-orchestrator n'a pas de workflow de mise à
  jour de doc avec les commandes GSD qui maintiennent la doc et les specs »). Gap établi **sur
  pièce** par lecture des workflows amont (`gsd-core/workflows/docs-update.md`, 1177 lignes, 17
  steps ; `ingest-docs.md` ; `map-codebase.md` ; `extract-learnings.md`) confrontés à l'état du
  module. **Le manque n'est pas d'outils mais de discernement** : les quatre familles
  documentaires que GSD outille séparément (doc **produit** → `gsd-docs-update` ; doc **d'entrée**
  → `gsd-ingest-docs`/`gsd-import` ; doc **du code** → `gsd-map-codebase` ; doc **de savoir** →
  `gsd-extract-learnings`/`gsd-graphify`) sont fondues en une ligne unique d'`intent-routing.md`.
  Quatre lacunes nommées : (1) aucune doctrine de sortie symétrique d'`ingestion-flow.md`, et les
  flags porteurs de sens de `gsd-docs-update` (`--verify-only` = auditer sans écrire, `--force` =
  régénérer) exposés nulle part ; (2) captation d'intention famélique — une seule ligne de
  formulations ; (3) `vf-dev-manager` sans table de moments déclencheurs et `vf-design-manager`
  sans aucun geste documentaire ; (4) le signal `[doc-drift]` (Phase 17) constate le fait mais
  personne n'est outillé pour le graduer. **Dépend du merge de la Phase 20** (fichiers partagés :
  `intent-routing.md`, `mission-contracts.md`, `vf-dev-manager.md`) ; **indépendante de la Phase
  21**, ordre libre.

- 2026-07-31 : **Phase 21 ajoutée** — « Alignement du moteur GSD sur gsd-core 1.9.0 ». Origine : la
  mise à jour du moteur de 1.8.0 vers 1.9.0 sur le poste de Samuel le 2026-07-31 (11:35). Delta
  établi **sur pièce** (`npm pack` des deux versions + diff intégral des tarballs + vérification de
  l'installation vivante), archivé en `.planning/missions/2026-07-31-delta-gsd-core-1.9.0.md`.
  **Vérifié avant ouverture : le dispatch tient** — aucun frontmatter d'agent modifié, 71 skills des
  deux côtés sans ajout ni suppression, `_runtime-launcher.snippet.sh` identique, 43 suites vertes,
  gates `check-gsd-engine.sh` / `detect-gsd-engine.sh` au vert. La phase est de l'**alignement**, pas
  du sauvetage, sauf sur un point : l'injection MCP ADR-051 est **structurellement inopérante** sur
  ce poste (`inject-mcp-tools.sh` dérive ses serveurs de `./.mcp.json`, or les serveurs sont en
  **scope global** dans `~/.claude.json` — `--verify` sort en `3 / INDÉTERMINÉ` au lieu de signaler
  le manque, et `gsd-executor` est aveugle à XcodeBuildMCP sur les labs iOS). Périmètre arbitré par
  Samuel : **une phase unique, exhaustive, rituel allégé** — injection MCP, contrat
  `estimate:`/`actuals:` (ADR-2629 amont), recouvrement avec les lanes de revue amont (ADR-2782) vs
  l'étage de revue livré en 20-06, `runtime-aware-dispatch` (#2508) et `executor-isolation-dispatch`,
  purge de la dette de version 1.8.0 (dont le **cas 8 de `test-check-gsd-engine.sh` qui asserte la
  chaîne littérale `1.8.0`**), et statut des hooks 1.9.0 non câblés. **Dépend du merge de la Phase
  20** — même règle que le diagnostic du 2026-07-29.

- 2026-07-28 : **Phase 20 ajoutée** — « Fluidité du flux de dev sans perte de qualité ». Origine :
  **second rapport de l'audit externe du 2026-07-28** (même lab `ExploreSomfy`, tranche iOS en 5
  lots dont 2 parallélisés par worktrees, ~90 commits, suite 177 → 331 tests), archivé en
  `.planning/missions/2026-07-28-audit-externe-fluidite.md`. **Les 4 constats ont été vérifiés sur
  pièce avant ouverture** — verdict : 3 confirmés dont 2 **plus solidement que le rapport ne
  l'affirme**, 1 **partiellement daté**.

  - **Changement 1 (ADR-051)** confirmé et aggravé : les `tools:` déclarés de `vf-reviewer`,
    `vf-auditer` et `vf-design-judge` gagnent tous **`Write, Edit` au runtime** (`memory: project`),
    et la description de `vf-design-judge` affirme une barrière « sans Write ni Edit » que le
    runtime ne pose pas. Le moindre privilège invoqué par ADR-051 n'existait déjà plus.

  - **Changement 2 (revue graduée par risque)** confirmé et verrouillé par un fait que le rapport ne
    citait pas : `vf-dev-manager.md:108` **interdit explicitement** au manager d'ajouter une revue
    (« Pas de double revue »). La revue est donc le seul étage à la fois obligatoire
    (`vf-coder.md:34`, en dur) **et hors de portée du manager**. Gradation existante indexée sur le
    volume (`SEUIL_EQUIPE = 3`), jamais sur le risque.

  - **Changement 3 (`MISSION-INVARIANTS.md`)** confirmé sur sa partie vérifiable (le gabarit
    `mission-contracts.md` existe et a été court-circuité ; `vf-dev-manager.md:29` lit déjà le
    `CLAUDE.md` du projet). L'absence des 3 invariants sur disque porte sur `ExploreSomfy` et n'est
    **pas vérifiable depuis ce repo** — statut plus faible que les autres constats.

  - **Changement 4 (`check-agents.sh`) — DATÉ à moitié** : l'option d'exclusion demandée **existe
    déjà** (`--third-party-prefix`, défaut `gsd-`, `check-agents.sh:84`), livrée en Phase 16 /
    v2.41.0 le 2026-07-27, **la veille du rapport**. Mesure du jour : **23 lignes, pas 68** — 21
    warnings tous sur des agents `vf-*`, 34 tiers `gsd-*` écartés, zéro finding `gsd-`. Reste vrai
    et non corrigé : `AGENTS_DIR=".claude/agents"` relatif au cwd (`:78`) + hook appelé sans
    `--agents-dir` ⇒ **le hook sort 0 ligne, le garde-fou ne regarde rien**. La correction, jugée
    impraticable le 28/07, est devenue praticable — et ferait remonter l'écart du changement 1.
  Découpage **arbitré par Samuel : une phase unique pour les 4 changements**, contre la
  recommandation de scinder en {1,4} conformité observable et {2,3} pilotage de mission. Réserve
  inscrite au ROADMAP : si l'exécution déborde, c'est par le changement 2 qu'il faudra scinder.

- 2026-07-28 : **Phase 19 ajoutée** — « Migration du moteur GSD pilotée par `/vf-update` ». Origine :
  **audit externe sur un second poste** (lab `ExploreSomfy`, scope user, rapport archivé en
  `.planning/missions/2026-07-28-audit-externe-migration-opengsd.md`), dont les 5 constats ont été
  **recoupés ligne à ligne dans ce repo** avant ouverture. Fait porteur : la migration
  `get-shit-done-cc` → `@opengsd/gsd-core` livrée en **v2.39.0** n'atteint **aucun poste déjà
  équipé** — plugin à 2.42.0, moteur toujours à 1.42.3 posé le 16/07, 12 jours après l'install et 2
  jours après la livraison de la migration. Trois causes vérifiées : `detect_gsd()` fait un `skip`
  sur le layout legacy (`ensure-deps.sh:119-120` + `:133`) ; aucun chemin d'update n'appelle
  `ensure_gsd()` (`vf-update/SKILL.md` §Garde-fous place le moteur hors périmètre) ;
  `log_legacy_cleanup_if_needed()` (`:184`) n'est joignable que par `/vf-init` et `/vf-calibrate`.
  Périmètre arbitré avec le mainteneur : **détecter + proposer sous confirmation ADR-031** (pas
  seulement dire), les 5 trous dans la même phase, **sans** hook `SessionStart` supplémentaire.
  Piège acté : **1.8.0 < 1.42.3 en semver** — le classement se fait sur le nom du paquet et le
  layout, jamais sur les numéros. Nuance portée au rapport : `check-plugin-update.sh` ne compare que
  les tags du plugin, aucun comparateur n'est en défaut aujourd'hui. **Indépendante de la Phase 18**
  (elle, bloquée par la RFC upstream) — donc exécutable immédiatement.
  Second rapport du même audit (fluidité du framework, 4 changements dont la révision d'ADR-051 et
  la gradation de la revue par risque) archivé en
  `.planning/missions/2026-07-28-audit-externe-fluidite.md` — **non instruit**, à arbitrer après.

- 2026-07-28 : **Phase 18 requalifiée en variante réduite** — « Survie du ledger d'exigences à la
  clôture de jalon ». Étude d'implémentation
  `.planning/phases/VFDO-18-survie-du-ledger-d-exigences-la-cl-ture-de-jalon/STUDY.md` (branche
  `phase-18-living-specs-study`, commit `0c2ecf7`) : verdict **GO-RÉDUIT**. Les 4 briques de
  l'inscription du 2026-07-27 (grammaire delta, ledger par capability, overlay `ship:post`, skill de
  spec-sync agent-driven) sont **écartées** — quatrième registre sans en retirer aucun (`ROUT-01` en
  3 copies) ; chemin agent-driven d'OpenSpec volé sans les 16 garde-fous du chemin `archive` ;
  ancrage `ship:post` réel en gsd-core 1.8.0 mais inopérant ici (`/gsd-ship` jamais emprunté,
  `onError: skip`, gate `bundleContentHash`). Le trou prouvé restant : `complete-milestone.md`
  supprime `.planning/REQUIREMENTS.md` **inconditionnellement** à chaque clôture. La RFC upstream
  `open-gsd/gsd-core` passe de bonus à **dépendance bloquante** (condition D3, échéance
  **2026-10-26**). Dossier de phase renommé en conséquence
  (`VFDO-18-capability-living-specs-conventions-openspec` →
  `VFDO-18-survie-du-ledger-d-exigences-la-cl-ture-de-jalon`, slug régénéré par
  `gsd-tools query generate-slug`). Les `*-SUMMARY.md` de la Phase 17 citent l'ancien chemin :
  laissés intacts, ce sont des constats datés.

- 2026-07-27 : **Phase 18** (Capability living-specs, conventions OpenSpec) ajoutée. Issue de
  l'étude « successeurs de GSD » du jour (mémoire `gsd-succession-landscape-2026-07`) : gap réel
  confirmé — GSD n'a aucun ledger de specs accumulées « ce que le système EST » ; verdict des audits
  code : ne PAS co-installer OpenSpec (collision de routage des skills, double état), voler la
  convention (grammaire delta + merge par bloc Requirement/Scenario) via une capability overlay
  `.gsd/capabilities/` sur `ship:post`, specs sous `.planning/specs/`. Piste amont : RFC/PR vers
  open-gsd/gsd-core une fois la capability éprouvée dans VibeFlow.

- 2026-07-27 : **Phase 17** (Signaux de démarrage du moteur de dev) ajoutée. Spec :
  `docs/superpowers/specs/2026-07-27-signaux-demarrage-dev-design.md`. Constat déclencheur :
  `dev-orchestrator` est le seul module structurant **sans hooks**, donc `discover-unintegrated-docs.sh`
  (livré Phase 13) n'est jamais appelé automatiquement et rien ne guide l'utilisateur après l'init.
  Incident du jour qui a élargi le périmètre : une demande de conception adressée au Claude principal
  est partie sur `superpowers:brainstorming` alors que ce repo tourne sous GSD avec une Phase 16
  inscrite — `planning-core` se retire quand GSD tient le projet (`--defer-to-gsd`), aucun module ne
  prend le relais, et le routage de `vibeflow-dev` n'existe que si son `AGENT.md` est lu (donc jamais
  avant invocation). D'où un 5e signal `[gsd-engine]` d'orientation. Indépendante de la Phase 16.

- 2026-07-27 : **Phase 15** (Collaboration inter-équipes dev ↔ design) ajoutée. Constat déclencheur :
  les deux équipes de mission s'ignorent totalement (seul pont = routage conversationnel
  `vibeflow-dev` → skill `vf-design`) ; les specs de `vf-crafter` ne sont jamais implémentées ; la
  description de `vf-design-manager` revendique un dispatch par `vf-auto` qui n'existe pas. Étude +
  7 tests empiriques (2026-07-27) : option A retenue — étages croisés sous UN manager, imbrication
  manager→manager interdite (Pattern A prouvé bloquant), DAG hétérogène déjà supporté par le kernel.

- 2026-07-26 : **Phase 13 redéfinie sans verbe-façade** — la phase était écrite autour de `/vf-ingest`
  et du cycle `vf-brainstorm → vf-ingest → vf-plan → vf-execute`, supprimés en v2.33.0. BRDG-01..03 et
  les critères de succès réécrits : ingestion portée par l'agent `vibeflow-dev`, découverte outillée
  (13-01). Plan 13-01 committé et réparé (corpus 8 → 9 documents, markup parasite purgé).

- 2026-07-25 : Milestone **gsd-migration** créé (VOC-02 promu). Phase 10 (Étude & faisabilité migration GSD)
  + Phase 11 (Intégration, GATE Phase 10) ajoutées à la feuille de route. Requirements GSDM-01..06.
- 2026-07-25 : Milestone **vf-routing** créé. Phase 12 (Routage fin & couverture complète des verbes `/vf-*`)
  + Phase 13 (Pont spec → feuille de route) ajoutées. Requirements VERB-01..05, BRDG-01..03.
  Devient le milestone actif ; `gsd-migration` reste ouvert en attente (chantiers indépendants).

- 2026-07-25 : **Phase 14** (Frontière d'altitude planning-core / moteur GSD) ajoutée au milestone vf-routing.
  Constat déclencheur : `vf-planning` et la chaîne GSD produisaient les mêmes fichiers dans le même dossier
  avec des frontmatters **incompatibles** (`planning_version` vs `gsd_state_version`) — deux moteurs de
  planning concurrents. Décision : ADR-055, frontière d'altitude (un projet = un seul moteur ; VibeFlow tient
  le lab et l'enforcement). Requirements ALTI-01..05, 6 plans sur 4 vagues, indépendante des Phases 12 et 13.

- 2026-07-25 : compteurs de `progress` corrigés — ils affichaient `total_plans: 0` alors que la Phase 12
  comptait déjà 6 plans dont 1 livré (12-01). Réel : 12 plans posés (6 en Phase 12, 6 en Phase 14), 1 livré.

### Decisions

Decisions are logged in PROJECT.md Key Decisions table (D1–D6).
Recent decisions affecting current work:

- **2026-08-02 — Le manuel utilisateur (Phase 26) vit sur disque, hors git, et sa disposition
  bilingue est un miroir de dossiers** (mission `.planning/missions/2026-08-01-phase-26-manuel-utilisateur.md`,
  13 décisions D-1..D-13 + point ouvert O-1). Contrainte de Samuel posée en cours de mission :
  **rien sous `manual/` n'est commité**, et **aucune entrée `.gitignore`** — ce fichier étant
  versionné, une entrée y laisserait une trace publique de l'existence du manuel ; l'exclusion
  passe par `.git/info/exclude`. Conséquences : le dégraissage de `README.md`/`README.fr.md`/
  `INSTALL.md` (D-7, D-8) est **gelé** — pointer vers un dossier absent du dépôt casserait les
  liens des visiteurs —, et l'outillage du manuel vit sous `manual/.tools/` plutôt que dans
  `scripts/` + `ci.yml` (D-13), où il aurait à la fois trahi l'existence du manuel et tourné **à
  vide** en CI. Disposition retenue : miroir `manual/fr/` + `manual/en/` (D-1), contre les suffixes
  `.fr.md` de la convention des deux README — **deux panels indépendants ont convergé** : le
  couplage langue↔chemin rend impossible la fuite silencieuse vers l'anglais qu'un `.fr` oublié
  produirait, et réduit la sonde de parité à un `diff` de deux `find`. **Livré : 8 vagues sur 9**
  (44 pages × 2 langues, gate `check-manual` exit 0). La vague 9 porte `autonomous: false` : la
  phase n'est **pas** marquée terminée, deux décisions attendent l'humain (parité de contenu FR/EN
  sur 21 pages, clôture + PR).

- **2026-07-31 — L'anti-triche P12 est garanti par un gate transverse, pas par les suites de
  module** (mission de clôture des reliquats Phase 20, WINDOWS #1). `team-kernel.md:23` affirmait
  que le cloisonnement `disallowedTools` était « vérifié par les suites de test de chaque module » :
  **faux sur pièce** — 0 occurrence de `disallowedTools` dans les suites propres de
  `design-orchestrator`, `business-pilot-bundle`, `content-bundle` et `growth-bundle`, et la seule
  du `dev-orchestrator` est une fixture de `test-inject-mcp-tools.sh`. Arbitrage : **corriger la
  phrase plutôt que dupliquer l'assertion dans 4 suites** — la garantie est transverse par
  construction (un seul gate `check-agents.sh --strict`, passé par la CI sur les 6 dossiers
  `plugin/*/agents` en découverte non vide + monde clos, doublé du hook `guard-agent-write.sh` à
  l'écriture, les deux testés par la suite conductor T69/T70). Quatre copies auraient divergé. La
  faute était de **nommer le mauvais mécanisme**, pas d'avoir un mécanisme manquant.
  **Corollaire non négociable** : la correction de doc seule aurait été un garde-fou inerte (motif
  exact du précédent Phase 19), donc elle est indissociable d'une **assertion sur l'arbre réel** —
  `test-check-agents.sh` T72 balaie `plugin/*/agents/*.md` (découverte dynamique, échec si vide) et
  exige `disallowedTools: Write, Edit` sur tout agent `memory:` + `tools:` sans Write/Edit. Jusque-là
  **aucune** suite du repo n'assertait quoi que ce soit sur les agents réellement posés — tout était
  fixture. Validé par mutation. Commit `8c5f0a5`.

- **2026-07-31 — Deux sessions ont écrit dans `.planning/` en parallèle ; le verrou de driver ne
  l'a pas empêché.** Pendant la mission de clôture des reliquats Phase 20 (verrou tenu par
  `mission-phase21` depuis 15:2xZ), une session tierce a rédigé la **Phase 22** dans `ROADMAP.md` et
  `STATE.md` à 15:37–15:38Z et créé `.planning/phases/VFDO-22-*/`. Confirmation opérationnelle que
  `driver-lock.sh` est **déclaratif, pas contraignant** : il coordonne des missions qui le
  consultent, il n'a aucun moyen d'arrêter un écrivain qui l'ignore. Traitement retenu : le brouillon
  Phase 22 est **préservé verbatim**, jamais réécrit ni annulé, et committé tel quel en signalant son
  origine hors mission. Ne jamais résoudre ce cas par un `stash` ou un `checkout --` décidé seul.

- **2026-07-28 — Un test qui n'exerce pas la commande réellement émise ne teste rien** (mission
  Phase 19, établi par mutation, pas par lecture). Le gap SC3 (`--verify` sans `--force`, garde-fou
  incapable de rendre un verdict en production) a franchi **trois étages de vérification** : revue de
  code PASS, gate de portabilité vert sur 3 OS, audit sécurité 6/6. Il n'a été vu qu'en **mutant le
  bloc livré** — sa suppression complète laissait la suite à 73 OK / 0 KO. Les deux signaux qui
  auraient dû alerter plus tôt sont désormais des sondes explicites : (a) un compte rendu qui prouve
  une **présence** (`grep -c 'verify' → 7`) au lieu d'un comportement ; (b) des cas de test qui
  invoquent une **forme de commande que le chaînage réel n'émet jamais** (`--force --verify` à la
  main, quand la production émettait `--verify` seul). C'est la troisième occurrence du motif
  « test tautologique derrière un décompte vert » sur ce repo (Phase 13 `discover-unintegrated-docs.sh`,
  Phase 17 cas 7, Phase 19 ici) — le contre-poison qui a marché à chaque fois est la **mutation du
  bloc livré**, jamais la relecture.

- **2026-07-28 — Arbitrage de mission (manager, autonomie) : le compteur « N suites » des README
  racine reste rouge à la clôture de phase.** Le gate de portabilité l'avait classé `auto-fix`
  majeur. Refusé : `check-version-sync.sh` est rouge sur ce seul contrôle (41 annoncé vs 42 réel) et
  le rattrapage **voyage avec le commit de release racine**, réservé à validation humaine — patron
  déjà appliqué aux Phases 13 et 17. Le corriger en mission aurait été s'accorder un morceau de la
  release explicitement sortie du périmètre. Les 17 triades par module sont ✓, dont les deux bumps
  de la phase. Corollaire de méthode : un juge frais ignore les déférés qu'on ne lui nomme pas — le
  mandat doit les lui dire, sinon il les remonte en faux positif.

- **2026-07-27 — Arbitrage humain (Samuel) : SC1 de la Phase 17 amendé, la spec fait foi.**
  `.planning/ROADMAP.md` §Phase 17 SC1 disait « les trois scripts sortent en 3 et **aucune ligne**
  n'est injectée […] le coût contexte d'un projet sain est nul ». La spec de référence
  (`docs/superpowers/specs/2026-07-27-signaux-demarrage-dev-design.md` §4.2 et §7) dit l'inverse :
  sur un projet sain, **une** ligne `[gsd-engine]` d'orientation est injectée (« 1 ligne, pas 0 »).
  SC1 tel qu'écrit contredisait aussi SC2 et SC2bis de la **même** entrée ROADMAP, qui exigent ce
  signal (le trou de routage du 2026-07-27 où une demande de conception est partie sur
  `superpowers:brainstorming` alors que le projet tournait sous GSD). Arbitrage retenu par Samuel :
  SC1 devient « les trois scripts sortent en 3 et la **seule** ligne injectée est le `[gsd-engine]`
  d'orientation ». SC2 et SC2bis restent inchangés. **Ceci est un arbitrage humain daté, pas une
  initiative d'agent** — appliqué par `vf-coder` (n1 du DAG de mission Phase 17) sur mandat exprès
  de `vf-dev-manager`, jamais tranché en autonomie.

- **2026-07-27 — Le cloisonnement `Agent(...)` n'est PAS linté par `check-agents.sh`** (mission Phase 15,
  établi empiriquement, pas déduit). Le cadrage de la phase et `team-kernel.md` affirmaient
  « anti-triche machine-enforced, linté par `check-agents.sh` ». Faux : ce script ne teste que la
  *présence* du champ `tools:` (`check-agents.sh:235-236`), jamais son contenu — le frontmatter est
  stocké comme chaîne opaque. Quatre agents fabriqués avec une allowlist de noms inventés, une
  parenthèse non fermée et des outils inexistants passent tous `--strict` en vert, exit 0. Décision :
  l'affirmation a été corrigée partout (`team-kernel.md`, `conductor/README.md`, `mission-cross-team.md`),
  et l'enforcement réel de D-07 passe par les suites de module (T18 dev, T8 design), seule vérification
  machine du contenu de `tools:` dans tout le repo. **Écrire le lint manquant dans `check-agents.sh`
  reste à arbitrer** — extension de périmètre sur un script de gate partagé, non exécutée en mission.
  Piège à connaître si on l'écrit un jour : `general-purpose` est un type natif sans fichier `.md`, et
  les agents `gsd-*` viennent de `@opengsd/gsd-core` — absents d'un lab sans GSD. Un lint exigeant
  `<agents-dir>/<nom>.md` rendrait rouges des allowlists correctes.

- **2026-07-27 — Un recensement de dispatches doit inclure les skills non forkées** (mission Phase 15,
  après deux omissions successives). Aucune skill de `~/.claude/skills/` ne déclare `context:` : aucune
  n'est donc forkée, et chacune exécute ses `Agent()` **dans le contexte de l'agent qui l'invoque**. Un
  manager qui appelle `gsd-ingest-docs`, `gsd-plan-phase`, `gsd-docs-update` ou `gsd-audit-milestone`
  dispatche donc lui-même `gsd-doc-classifier`, `gsd-doc-synthesizer`, `gsd-pattern-mapper`,
  `gsd-integration-checker`… qui doivent figurer dans SON allowlist. Le premier recensement de la
  mission a livré 7 noms, le second 14, un audit indépendant 18. Conséquence de méthode : sur ce type
  d'inventaire, la seconde dérivation doit être **indépendante** (interdiction de lire la première),
  sinon elle recopie l'angle mort au lieu de le corriger.

- **2026-07-27 — Portée réelle de l'interdiction d'imbrication manager→manager** (mission Phase 15).
  Les allowlists des deux managers ferment le chemin de dispatch **direct**. Le chemin **indirect**
  (`manager → worker → manager`) reste ouvert au niveau du dispatch : `vf-coder`, `vf-reviewer` et
  `vf-auditer` portent `Agent` nu. La garantie qu'un seul manager pilote une mission est portée par le
  **verrou de driver**, qui refuse la seconde acquisition quel que soit le chemin (T1 de l'étude,
  `test-driver-lock.sh` T2) — pas par les allowlists. Dette consignée dans `.planning/codebase/CONCERNS.md` ;
  scoper l'accès `Agent` de ces trois workers est une extension de périmètre non exécutée (ADR-031).

- **2026-07-26 — Résolution de `gsd-tools` par CASCADE, jamais par chemin en dur** (mission Phase 11,
  tranchée sur panel de recherche documentaire). Le dossier d'étude prescrivait
  `node "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core/bin/gsd-tools.cjs"`. Preuve contraire :
  l'installeur gsd-core 1.8.0 gère un scope `--local` qui dépose le payload sous
  `<projet>/.claude/gsd-core/`, or `ensure-deps.sh` dérive justement un `GSD_SCOPE_FLAG`
  `--global`/`--local` — le chemin en dur ratait donc DÉJÀ une population d'utilisateurs que notre
  propre engine sait créer. Forme retenue : l'ordre du snippet officiel amont
  (`_runtime-launcher.snippet.sh`), en variante Claude-only. Corollaires : `gsd-tools` sort exit 0
  même en erreur métier → tester le JSON (`.error`), jamais `$?` ; `VERSION` dérivé du chemin
  résolu ; ne jamais installer `@next` (dist-tag amont périmé : 1.7.0-rc.6 < latest 1.8.0).

- **2026-07-26 — Non-mixité GÉNÉRALE des groupes de hooks** (mission Phase 11, arbitrage manager).
  `merge-hooks.sh` ne fusionne plus jamais les hooks VibeFlow dans un groupe qu'il ne possède pas
  intégralement — y compris un groupe tiers, pas seulement gsd. L'option étroite (restreindre aux
  hooks gsd-managés) aurait affaibli un correctif déjà spécifié ; le risque prouvé (un outil voisin
  qui supprime des ENTRÉES ENTIÈRES) n'est pas propre à gsd-core, et l'invariant est symétrique (à
  la désinstallation, notre `remove` cesse de muter un groupe d'autrui). Conséquence assumée : T2 de
  `test-merge-hooks.sh` a été réécrit — son assertion `len(read_groups)==1` encodait l'ancien
  comportement ; la garantie qu'elle protégeait réellement (anti-prolifération de groupes) est
  conservée explicitement.

- **2026-07-26 — Citation canonique restaurée pour le jalon `vfdo-v1.0`** : la spec
  `2026-06-04-dev-orchestrator-design.md` n'était citée que dans `.planning/phases/01-*/**` (des sorties
  du moteur, pas un registre) — sa citation n'avait jamais été reportée dans le snapshot du jalon à
  l'archivage. C'est `discover-unintegrated-docs.sh` qui l'a mise au jour dès sa première passe sur le
  corpus réel. Confirme le motif déjà connu : **la citation migre puis disparaît à l'archivage**, ce qui
  justifie a posteriori les 6 registres de BRDG-02 plutôt que le seul `ROADMAP.md`.

- **2026-07-26 — Revue de code non négociable sur un fait outillé** : le script de découverte avait été
  livré sans revue (jugée disproportionnée par le worker) avec 12 tests verts. La revue commandée ensuite
  a trouvé **2 bloquants reproduits** (motif de citation non borné à gauche → faux négatif silencieux ;
  échappement ERE partiel → motif absorbant) que la suite ne pouvait pas voir, son cas de bornage étant
  tautologique. Enseignement : sur un artefact à **coût d'erreur asymétrique**, une suite verte ne vaut
  pas une revue — et un test de mutation dit la vérité qu'un décompte de cas cache.

- **2026-07-26 — Phase 13 sans verbe** (arbitrage Samuel) : pas de résurrection de la façade — le pont
  spec → feuille de route est un geste de l'agent `vibeflow-dev`, la découverte seule est outillée
  (ligne de coupe ADR-055 §3).

- **2026-07-25 — Programme d'audit croisé livré en 3 releases** (v2.32.0 → v2.34.0, rapports
  dans `reports/`) : (1) enforcement branché — CI, gates exit 3, scission ADR-031/ADR-056 ;
  (2) **bascule agentique** (arbitrage Samuel, spec
  `docs/superpowers/specs/2026-07-25-suppression-facade-vf-design.md`) — façade vf-* supprimée,
  dev-orchestrator v2.x, manager avec digest/next steps/hygiène doc, gouvernance proportionnée
  au profil ; (3) universalisation — team-kernel transverse (conductor), équipe design,
  content-bundle matérialisé `proposable:true`, pipelining N/N+1, lab express, ADR-057.
  Prolongé par **v2.35.0** : growth-bundle et business-pilot-bundle matérialisés à leur tour
  (quality-gate-client livré) — les 3 bundles métier sont réels, promesse multi-métier tenue.
  **v2.36.0** : recettes UAT réelles sur labs vierges (express ~11 min 30 ✓ ; protocole de
  mission exécutable par un agent tiers ✓) — 16 frictions corrigées, job CI « lab frais »
  (la baseline doit passer ses propres gates depuis un lab vierge).

- [Phase 1]: D4 — index 100% auto-généré, ordre pipeline documenté dans l'agent.
- [Phase 1]: D3 — install auto des deps, init projet sur confirmation seulement.
- [Phase ?]: Index GSD trié alphabétiquement pour diff déterministe + idempotence vérifiable (Plan 01-01)
- [Phase ?]: [Phase 1]: ensure-deps.sh utilise set -uo pipefail (sans -e) car les détections reposent sur des exit non-zéro normaux (Plan 01-02)
- [Phase ?]: [Phase 1]: Contrat de test VF_ENSURE_DRY_RUN=1 pour valider l'idempotence sans réseau (Plan 01-02)
- [Phase ?]: [Phase 1]: Modules AGENT — references sous .claude/agents/<mod>-references/ (D7), index régénéré à l'install via VF_INDEX_OUT (IDX-02) (Plan 01-05)
- [Phase ?]: [Phase 1]: Densité des .md mesurée par wc -l, jamais le contrôleur de taille générique qui ignore les .md (Plan 01-05)
- [Phase ?]: module.json: requires[] = prérequis module réels uniquement, ENGINE (vibeflow-update.sh) exclu
- [Phase ?]: Engine défaut LEGACY=project (rétro-compat ./.claude) ; skill /vibeflow-install passe toujours VF_SCOPE explicite (cohérence ID4)
- [Phase ?]: docs/<mod>/ doc-only laissé hors TARGET_ROOT (relatif au cwd projet)
- [Phase ?]: Plus de git clone/pull : source = cache local (require_cache) ; sync = no-op explicite
- [Phase ?]: ensure-deps scope-aware via VF_SCOPE (GSD --global/--local, Superpowers --scope), VF_ENSURE_FORCE dry-run only, defaut LEGACY user (ID4)
- [Phase ?]: Hook VibeFlow pointe directement le script bash; marqueur 1er lancement aligné sur registre engine scripts/.vibeflow-installed
- [Phase 06]: Garde-fou first-use placé avant la table de routage (point de décision router-vs-proposer)
- [Phase 06]: Séquence d'init non dupliquée : délégation au skill vf-init existant
- [Phase ?]: 19-02: capture de l'état legacy avant toute garde de ensure_gsd() (D-08.3), preuve directe par T2k
- [Phase ?]: 19-02: npm_pkg_installed_globally() est le seul appel npm réellement exécuté (lecture seule), --verify d'inject-mcp-tools.sh ne rejoue jamais --force
- [Phase ?]: 2026-07-31 — Phase 20 (20-07, clôture) : anti-triche « vérifié par les suites de test de chaque module » constaté FAUX pour design-orchestrator/business-pilot-bundle/content-bundle/growth-bundle (0 test de disallowedTools dans leur suite propre) — inscrit en différé nommé (WINDOWS.md), non corrigé (P-07).
- [Phase ?]: 2026-07-31 — Phase 20 (20-07) : compteurs du module obligatoire écrits à leur valeur réelle (14 scripts, 12 suites, pas 11) — un correctif de revue hors plan (test-guard-agent-write.sh, commit 447e75a) a créé une 2e suite entre le cadrage et l'exécution. Compteur repo-entier de suites réel = 44, pas 43 : consigné en reste-à-faire de release racine.

### Pending Todos

- **Release de clôture du milestone `vf-routing`** (bump `VERSION` racine + `plugin.json` +
  `marketplace.json` + historique des 2 README, puis tag annoté poussé, `check-release-tag.sh --remote`
  → ✓). Le module `dev-orchestrator` est déjà en v2.2.0 ; la racine est restée en v2.36.2.
  **Réservée à validation humaine — non faite en mission.**

- **Recette humaine de la Phase 19 (SC2)** : parcours `/vf-update` sur un poste réellement legacy —
  vérifier que la ligne « moteur GSD legacy 1.42.3 → `@opengsd/gsd-core` » apparaît **avant** tout
  stop sur « plugin à jour », puis l'**accepter** (migration + ré-injection MCP enchaînées) et, sur
  un second passage, la **refuser** (aucun effet de bord, aucune insistance). Seul critère de la
  phase non éprouvable par test — c'est du comportement d'agent.

- **Arbitrage à trancher (remonté par la mission Phase 19, non tranché seul)** : les vagues
  parallèles d'exécution partagent le même arbre de travail (pas d'`isolation: worktree`). Aucune
  collision constatée — les périmètres de fichiers étaient disjoints et déclarés — mais la garantie
  vient de la déclaration, pas de la construction. Même famille que l'incident de verrou de la
  Phase 16.

- **Arbitrage doctrinal (audit BRDG-03)** : la confirmation humaine ADR-031 avant ingestion est ancrée
  à `vibeflow-dev` seul. `vf-dev-manager` (chemin équipe, qui consulte `intent-routing.md` pour mapper
  un brief brut) n'a **aucune ligne nominative** sur l'ingestion, contrairement au patron déjà appliqué
  aux skills de clôture de milestone (« en respectant leurs confirmations internes »). Deux filets
  génériques couvrent probablement le cas, mais rien ne l'interdit noir sur blanc. Options : (a) no-op
  assumé, (b) ligne miroir dans `agents/vf-dev-manager.md` renvoyant à `ingestion-flow.md`.

- Combler le trou de couverture du **filtre glob** de `discover-unintegrated-docs.sh` : le mutant
  « filtre retiré » survit à la suite (16 ok quand même). Effet possible = faux négatif, jamais faux
  positif — donc pas de ré-ingestion silencieuse, priorité basse.

- ~~Divergence lexique P3-P8~~ **tranchée le 2026-07-26** (commit b835ffd) : le Core v4.2 est
  canonique, lexique réaligné, module reference v2.5.2 — part avec la prochaine release.

- *(milestone `gsd-migration`)* Mission Phase 11 dispatchée (vf-dev-manager) sur les 6 vagues de
  `10-APPROFONDISSEMENT.md` §5 — release finale réservée à validation humaine.

### Blockers/Concerns

- Migration package GSD `get-shit-done-cc` → `@opengsd/gsd-core` : milestone `gsd-migration` (VOC-02),
  ouvert et **en attente** — non bloquant pour vf-routing. Le go/no-go de la Phase 10 dépend de la
  maturité/parité du package cible sur npm — à vérifier en premier.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260801-17w | Isolation multi-session : un écrivain = un worktree (ADR-064) + gate advisory de revendication de branche | 2026-08-01 | `efa20c5` | [260801-17w-isolation-multi-session](./quick/260801-17w-isolation-multi-session/) |

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Recette humaine | **WINDOWS #3** — valider `test_sim` / `build_sim` / `clean` (clé `vf-mcp-tools`) contre un serveur **XcodeBuildMCP vivant** sur un lab iOS équipé. Reste `open` : **infaisable dans ce dépôt** (aucun `.mcp.json`, serveur non connecté) — toute preuve produite ici serait fabriquée. Se recette sur `RoastMyRoom` ou `FreelanceMoneyCalc`, pas sur `vibeflow-os`. | open | 2026-07-31 |
| Dette outillage | **WINDOWS #4** — `inject-mcp-tools.sh` ne valide pas qu'un nom de serveur cité dans un token `vf-mcp-tools`/`mcp__` **existe réellement**. **Repris au périmètre de la Phase 21, changement 1** : la phase rouvre déjà ce script pour lui donner la découverte des serveurs en scope global (`~/.claude.json`) — une fois la source des noms de serveurs connue du script, valider un nom cité devient possible, alors que c'était structurellement hors de portée tant que la seule source était `./.mcp.json`. | repris en Phase 21 | 2026-07-31 |

## Session Continuity

**Resume file:** None

Last session: 2026-07-31T10:26:41.586Z
Stopped at: Phase 20 complète (7/7 plans) — clôture de gouvernance (20-07) : ADR-051 révisée + ADR-060 posée, doctrine transverse alignée, 6 modules bumpés (conductor v1.17.0, dev-orchestrator v2.8.0, design-orchestrator v1.3.2, 3 bundles v2.0.3). Gates verts sauf le seul rouge attendu (compteur de suites racine, 44 réel pas 43). Release racine réservée à validation humaine post-fusion (4 éléments consignés + WINDOWS.md).
ubuntu:24.04) — 3 jobs verts au run 30257419335. Modules bumpés : conductor v1.14.5,
consolidator v1.8.1, dev-orchestrator v2.3.2. Leçon durable : tout bash développé sur macOS/BSD
doit être reproduit sous `docker run ubuntu:24.04` avant push (stat/-f, TMPDIR, outillage hôte).
Reprendre par : **release patch v2.39.1** (décision humaine — distribue les fixes aux labs, dont
le vol de lock ABA), et l'arbitrage engine sur les templates-memoire jamais posés à l'install.
