# Milestone agentique-v1.0 : Durcissement du moteur d'équipes agentique

**Status:** ✅ SHIPPED 2026-08-15
**Phases:** 15 → 29 (13 phases livrées ; **18 et 25 reportées** au prochain milestone)
**Total Plans:** 76 plans complétés (SUMMARY.md) sur le périmètre
**Releases:** `v2.40.0` → `v2.52.0` · **CI main verte** sur `f50b226` à la clôture

## Overview

Chantier post-migration GSD : durcir le moteur d'équipes agentique de VibeFlow, de la
collaboration inter-équipes (15) aux gains ICM (29). Ce milestone **absorbe `gsd-alignement`**
(ouvert le 2026-08-01 pour légitimer les phases 23-25 inscrites hors mandat) et rattache les
phases orphelines 15-22 et 29 qui avaient tourné sous le label périmé `gsd-migration` (clos le
2026-07-26 — la dérive de label est restée trois semaines dans `STATE.md`).

**Livré, en fil conducteur :** collaboration dev ↔ design (15), cloisonnement des dispatches (16),
signaux de démarrage (17), migration du moteur pilotée par `/vf-update` (19, ADR-058), fluidité
sans perte de qualité (20), alignement gsd-core 1.9.0 (21, ADR-061/062/063), hygiène documentaire
(22), couplage explicite au moteur GSD (23), activation et mesure des capacités dormantes (24),
manuel utilisateur (26), parallélisation d'exécution (27 — spike `claude_orchestration` refusé par
écrit), gate armement ↔ précondition distribuée avec *as-installed testing* (28 — réponse
structurelle à la régression #38), distillation des gains ICM (29).

**Reporté au prochain milestone :** Phase 18 (survie du ledger d'exigences à la clôture de jalon —
ironiquement, la dérive qu'elle doit fermer a été constatée pendant cette clôture même) et
Phase 25 (budget d'instructions et étage d'alignement court). Jamais cadrées ni planifiées.

**Audit allégé de clôture (2026-08-15) :** familles d'exigences ARMD (10), ICMD (12) et DOCF (7)
vérifiées livrées sur preuves (SUMMARYs + artefacts sur disque + releases taggées) et cochées dans
le ledger ; 29 tags `v2.30.x` → `v2.52.0` présents ; `check-release-tag --remote` ✓ ; verrou
`open-gsd/gsd-core#3302` (ré-armement `isolation: worktree`) toujours fermé à la clôture.

## Phases

### Phase 15: Collaboration inter-équipes dev ↔ design

**Goal**: Faire collaborer les deux équipes de mission (dev-orchestrator, design-orchestrator) **par
étages croisés sous un seul manager** — option A de l'étude du 2026-07-27 : un seul verrou de driver,
un seul DAG, un seul rapport. `vf-dev-manager` gagne un étage design (nœuds `craft:<écran>` via
`vf-crafter` avant l'exécution d'une étape à dominante UI, `critique:<écran>` via `vf-design-judge`
en parallèle de la revue code) ; `vf-design-manager` gagne un étage implémentation (`vf-coder` pour
incarner les specs+tokens du crafter — comble le trou « specs jamais implémentées »). L'imbrication
manager→manager reste INTERDITE (Pattern A, prouvée bloquante par test) ; le kernel `dag.sh` accepte
déjà les DAG hétérogènes et le reopen cross-métier (7/7 tests empiriques verts). Inclut le fix de
l'aiguillage `vf-auto` (dominante design → `Task(vf-design-manager)`) pour honorer la description
déjà publiée de `vf-design-manager`.
**Requirements**: TBD (à dériver au cadrage)
**Depends on:** Phase 14
**Success Criteria** (what must be TRUE):

  1. `vf-dev-manager` sait insérer les étages design (craft avant exec, critique en parallèle de la
     revue) sur une étape à dominante UI, avec workers `vf-crafter`/`vf-design-judge` — sans jamais
     dispatcher `vf-design-manager` (pas d'imbrication de managers, Pattern A intact).

  2. `vf-design-manager` sait dispatcher `vf-coder` pour implémenter les specs du crafter, avec le
     même contrat typé — le « vert » design reste la critique scorée ≥ seuil.

  3. `vf-auto` route une mission longue à dominante design vers `Task(vf-design-manager)` (aiguillage
     documenté, cohérent avec la description publiée de l'agent).

  4. Le cloisonnement machine-enforced tient : `check-agents.sh` passe, les juges restent sans
     Write/Edit effectif, les workers internes restent `vf-internal: true`.

  5. Tests : les suites des deux modules couvrent le scénario croisé (DAG mixte, reopen cross-métier,
     interdiction d'imbrication) et restent vertes ; release bumpée + tag annoté poussé
     (`check-release-tag.sh --remote` → ✓).
**Plans:** livrée en mission d'équipe (DAG de mission, 2026-07-27) — pas de PLAN.md par plan

Plans:

- [x] Contrats et doctrine croisée — `mission-contracts.md` (champs de brief `design:`/`livrable:`, digest croisé), nouvelle référence `mission-cross-team.md`, « Pattern D » de renvoi, table `team-kernel.md`
- [x] Étages croisés sur les deux managers — étage design dans `vf-dev-manager`, étage implémentation dans `vf-design-manager`, allowlists `Agent(...)` (18 et 6 noms)
- [x] Aiguillage et descriptions — `vf-auto` D-11, dispatch élargi des 4 workers, signaux de mission des deux `AGENT.md`
- [x] Tests croisés — T18/T18b (dev), T8/T8b + T4 durci (design), T12 (DAG hétérogène cross-métier), chacun prouvé discriminant par mutation
- [x] Portée réelle du cloisonnement — garantie attribuée au verrou de driver, dette `Agent` non scopé des workers consignée dans CONCERNS.md
- [x] Bumps par module — conductor v1.14.6, design-orchestrator v1.3.0, dev-orchestrator v2.4.0
- [x] **Release racine + tag annoté + release GitHub** — `v2.40.0` validée humainement et publiée le 2026-07-27 (`check-release-tag.sh --remote` → ✓)

### Phase 16: Cloisonnement complet des dispatches d'agents

**Goal**: Fermer les deux trous escaladés par la mission de la Phase 15, tous deux sur le même
sujet : le cloisonnement des dispatches est aujourd'hui **documenté et testé par module**, mais pas
**garanti par le gate partagé**, et il ne couvre que le chemin direct manager→manager. (1) Écrire le
lint réel des allowlists `Agent(...)` dans `check-agents.sh` — le script ne lit actuellement jamais
le contenu du champ `tools:`, si bien que des noms d'agents inventés, une parenthèse non fermée ou
des outils inexistants passent `--strict` en vert. (2) Scoper l'accès `Agent` de `vf-coder`,
`vf-reviewer` et `vf-auditer`, qui laissent ouvert le chemin indirect manager→worker→manager.
**Requirements**: TBD (à dériver au cadrage)
**Depends on:** Phase 15
**Success Criteria** (what must be TRUE):

  1. `check-agents.sh` valide le **contenu** des allowlists `Agent(...)` : syntaxe (parenthèse
     fermée, séparateurs) et existence de chaque nom — sans rendre rouges des allowlists correctes
     qui référencent des types natifs sans fichier `.md` (`general-purpose`) ou des agents externes
     fournis par `@opengsd/gsd-core` (`gsd-*`). Ce piège est la raison pour laquelle le lint n'a pas
     été écrit en Phase 15.

  2. Les allowlists de `vf-coder`, `vf-reviewer` et `vf-auditer` sont posées après le **même
     recensement exhaustif** que celui de la Phase 15 — dispatches directs **et** agents dispatchés
     par les skills que ces workers invoquent (l'angle mort qui avait produit 4 omissions).

  3. Le chemin indirect manager→worker→manager est structurellement fermé ; la dette correspondante
     sort de `CONCERNS.md`.

  4. Les tests de suite existants (T18/T18b, T8/T8b) restent verts et le nouveau lint est prouvé
     discriminant par mutation ; les 39 suites du repo passent.
**Plans:** livrée en mission d'équipe (2026-07-27) — cadrage rétroactif, pas de PLAN.md par plan

**Amendement au SC3 (découverte de la mission, actée)** : le runtime Claude Code **ignore** la liste
de noms entre parenthèses dans la définition d'un sous-agent — la doc officielle est explicite, et
elle est désormais citée verbatim dans l'en-tête de `check-agents.sh`. Une allowlist `Agent(x, y)`
n'est donc **pas** un bac à sable runtime pour un agent posé sous `.claude/agents/` : c'est un
**contrat documenté, enforcé par le lint et par lui seul**. Elle ne redevient une vraie restriction
runtime que pour un agent incarné en thread principal (`claude --agent`). Le SC3 est tenu au sens
« contrat + gate machine », pas au sens « sandbox runtime ». Cette honnêteté doctrinale vaut
rétroactivement pour les allowlists des deux managers posées en Phase 15.

Plans:

- [x] Lint des allowlists dans `check-agents.sh` — syntaxe et existence des noms, sur `tools:` comme `disallowedTools:` ; suite `test-check-agents` portée de 38 à 58 axes
- [x] Résolution graduée du piège natifs/externes — sévérité indexée sur ce qui est vérifiable indépendamment du périmètre installé : syntaxe → erreur dure, outils → erreur en `--strict`, **nom d'agent non résolu → warning même en `--strict`**, erreur seulement sous `--resolve-agents=strict` (mode opt-in réservé à la CI, seul endroit où l'univers des agents est connu)
- [x] Fermeture de la dette connexe `CONCERNS.md:52-59` — `--third-party-prefix` règle les 66 faux positifs du scope user
- [x] Allowlists des 3 workers après double recensement indépendant — `vf-coder` (22 noms), `vf-reviewer` (1), `vf-auditer` (1) ; écart de 5 noms entre les deux dérivations sur `vf-coder`, union retenue (coût d'erreur asymétrique)
- [x] Correctifs remontés par les juges — T19/T19e étaient **tautologiques** (grep sur toute la ligne `tools:` : un nom retiré de l'allowlist mais replacé en `Bash(...)` laissait la suite verte), 2 faux-bloquants du lint neuf, et `--resolve-agents=<valeur inconnue>` qui dégradait le gate en silence
- [x] Sortie de dette — entrées « accès `Agent` non scopé » et « `check-agents --strict` sans périmètre tiers » retirées de `CONCERNS.md` (la seconde vérifiée empiriquement sur `~/.claude/agents`)
- [x] Bumps par module — `conductor` v1.15.0, `dev-orchestrator` v2.5.0
- [x] Release racine `v2.41.0` — taggée et publiée le 2026-07-27

### Phase 17: Signaux de démarrage du moteur de dev

Spec : `docs/superpowers/specs/2026-07-27-signaux-demarrage-dev-design.md`.

**Goal**: Rendre implicites les gestes de démarrage et d'hygiène documentaire (`gsd-onboard`,
`gsd-config`, `gsd-map-codebase`, `gsd-ingest-docs`, `gsd-docs-update`), qui ne se déclenchent
aujourd'hui que si le modèle y pense. `dev-orchestrator` est le seul module structurant **sans
aucun hook** — conséquence directe : `discover-unintegrated-docs.sh`, livré en Phase 13 avec un
contrat propre et testé, n'est jamais appelé automatiquement, et rien ne guide l'utilisateur
au-delà de l'init d'un projet. Poser au module un fragment `hooks/hooks.json` sur le modèle de
`planning-core` : trois scripts constatent des FAITS au `SessionStart` et injectent des signaux
courts et **auto-portants** (chaque ligne porte son propre geste, comme `[planning-debt]`).
**Depends on**: — (indépendante de la Phase 16 ; s'appuie sur l'acquis des Phases 13 et 14)
**Requirements**: SIG-01 (continuum `check-dev-bootstrap.sh` — 4 états mutuellement exclusifs, un
seul script) · SIG-02 (`discover-unintegrated-docs.sh --hook`, non-régression du contrat historique
`grain<TAB>chemin` + exits 0/3/64) · SIG-03 (`check-doc-drift.sh` — heuristique commits, seuil
réglable, silence hors dépôt git) · SIG-04 (contrat advisory/lecture seule des 3 scripts — aucune
écriture, aucun exit 1, aucun blocage de tour) · SIG-05 (gate ADR-044 réellement falsifiable sur
`AGENT.md` racine de module via `check-agents.sh --file`, fermé par test embarqué plutôt que
documenté) · SIG-06 (portabilité macOS/Linux prouvée par conteneur avant push, non cochée sur un
run macOS seul)
**Success Criteria** (what must be TRUE):

  1. Sur un repo sain et complètement cadré, les trois scripts sortent en 3 et la **seule** ligne
     injectée est le `[gsd-engine]` d'orientation. *(Amendé le 2026-07-27 — arbitrage humain de
     Samuel, cf. `.planning/STATE.md` §Decisions : le libellé original « aucune ligne n'est
     injectée » contredisait la spec §4.2/§7 et se contredisait lui-même avec SC2/SC2bis
     ci-dessous, qui exigent le signal `[gsd-engine]`. La spec fait foi.)*

  2. `check-dev-bootstrap.sh` couvre le continuum de démarrage en un seul script : silence si ni
     code ni `.planning/`, signal `onboard` si code sans `.planning/`, signal `bootstrap` listant
     les items manquants (`config.json`, `codebase/`, ROADMAP sans phase) sinon, signal
     d'orientation `gsd-engine` si complet. Les trois signaux sont prouvés mutuellement exclusifs
     par test.
  2bis. Le signal `gsd-engine` ferme le trou de routage constaté le 2026-07-27 sur ce repo : une
     demande de conception adressée au Claude principal est partie sur `superpowers:brainstorming`
     alors que le projet tournait sous GSD avec une Phase 16 inscrite. Cause structurelle —
     `planning-core` se retire quand GSD tient le projet (`--defer-to-gsd`) et aucun module ne
     prend le relais ; le routage de `vibeflow-dev` n'existe que si son `AGENT.md` est lu, donc
     seulement une fois l'agent invoqué. Le signal lit le frontmatter réel de `STATE.md`
     (milestone, phase, statut) et retombe en silence s'il est illisible — jamais d'état inventé.

  3. `discover-unintegrated-docs.sh --hook` agrège le compte en une ligne **sans toucher** au
     contrat historique (`grain<TAB>chemin`, exits 0/3/64) consommé par `ingestion-flow.md` ;
     `--hook` avec `--quiet` sort en 64.

  4. `check-doc-drift.sh` signale au-delà d'un seuil de commits de code sans mise à jour de doc
     (défaut 20, réglable), et reste silencieux hors dépôt git ou sans commit de doc.

  5. Les trois scripts sont en **lecture seule** et **advisory** : aucune écriture, aucun exit 1,
     aucun blocage de tour — la confirmation humaine reste devant chaque geste proposé (ADR-031,
     garde-fous BRDG-03 pour l'ingestion).

  6. Les hooks sont câblés par l'engine sans le modifier (`merge_module_hooks` gère déjà le
     fragment), `check-agents.sh` passe après modification d'`AGENT.md`, et les tests des trois
     scripts passent sous `bash` macOS **et** Linux (portabilité CI — régression du 2026-07-27).
**Plans:** 3 plans (3 vagues) — ✅ complétés. Livré : `check-dev-bootstrap.sh`, `check-doc-drift.sh`,
`discover-unintegrated-docs.sh --hook`, `hooks/hooks.json`, section *Signaux de démarrage* dans
`AGENT.md`, 2 nouvelles suites de tests. Module `dev-orchestrator` **v2.6.0** (collision de version
avec la Phase 16 concurrente, qui avait déjà pris v2.5.0 — cible ajustée v2.5.0 → v2.6.0, commit
`5a8b6a8`).

**SC5 (advisory / lecture seule) — CONFORME**, prouvé par exécution : seul `mktemp` du module
(`discover-unintegrated-docs.sh:91-93`) apparié à un `trap ... EXIT`, borné à `$TMPDIR` ; aucun
`exit 1` (seuls 0/3/64, `set -uo pipefail` sans `set -e`) ; aucun blocage de tour (`hooks.json` =
un seul groupe `SessionStart`, chaque commande suffixée `|| true`) ; 5 fixtures de frontmatter
hostiles (injection shell, octet de contrôle 0x01, délimiteur tronqué, `$(whoami)`) → stdout vide et
exit 3 dans les 5 cas ; `node_modules` 20 000 fichiers → 0.007s (élagage `-prune` confirmé).

**SC6 (portabilité macOS ET Linux) — PROUVÉ** : compteurs identiques sur macOS bash 3.2.57, Debian 12
bash 5.2.15, Ubuntu 24.04 bash 5.2.21 (OS exact de `runs-on: ubuntu-latest`) — `test-check-dev-bootstrap.sh`
23 ok/0 ko · `test-check-doc-drift.sh` 21 ok/0 ko · `test-discover-unintegrated-docs.sh` 22 ok/0 ko.
Aucun test sauté silencieusement, aucun edit de `ci.yml` nécessaire.

**Comblement post-exécution** (commit `6e33b14`, après fusion des verdicts gate portabilité + audit
advisory) : cas 7 de `test-discover-unintegrated-docs.sh` rendu discriminant (tautologique — vert
avec ou sans le filtre glob, prouvé par mutation) ; boucle T21 de `test-dev-orchestrator.sh` élargie
à `discover-unintegrated-docs.sh`, seul des 3 scripts à utiliser `mktemp`.

**Reste-à-faire assumé** : la **release racine + tag** est hors du mandat de la mission — réservée à
validation humaine. Pré-requis identifié : `scripts/check-version-sync.sh` est rouge (README/README.fr
annoncent « 39 suites » contre 41 réelles). Deux dettes constatées et inscrites à `CONCERNS.md` (non
corrigées, hors mandat de clôture) : le verrou de driver est déclaratif et non contraignant ; le gate
ADR-044 est un faux vert dans son invocation nue prescrite par la spec.

Plans:
**Wave 1**

- [x] 17-01-PLAN.md — Tranche traçante : `check-dev-bootstrap.sh` (continuum à 4 états) + fragment `hooks/hooks.json`, prouvé de bout en bout sur ce dépôt (vague 1)

**Wave 2**

- [x] 17-02-PLAN.md — Expansion : `check-doc-drift.sh` (seuil réglable, silence hors git) + `discover-unintegrated-docs.sh --hook` strictement additif (vague 2)

**Wave 3**

- [x] 17-03-PLAN.md — Doctrine `AGENT.md`, gates T20/T21 falsifiables (ADR-044, SC5), preuve de portabilité Linux en conteneur, module `v2.6.0` (vague 3)

### Phase 19: Migration du moteur GSD pilotée par /vf-update

> **Origine — audit externe vérifié sur pièce le 2026-07-28**, mené sur un second poste (lab
> `ExploreSomfy`, scope user) : `.planning/missions/2026-07-28-audit-externe-migration-opengsd.md`.
> Les cinq constats ont été **recoupés ligne à ligne** dans ce repo avant ouverture de la phase.

**Goal**: Faire que la migration `get-shit-done-cc` → `@opengsd/gsd-core` livrée en **v2.39.0**
atteigne les **postes déjà équipés**, et pas seulement les installations neuves. Fait porteur : sur
un poste à jour côté plugin (**2.42.0**, cache rafraîchi), le moteur était toujours
`~/.claude/get-shit-done/VERSION` = **1.42.3** posé le 16/07 — **12 jours après l'install initiale et
2 jours après la livraison de la migration**. Le poste portait le *code* de la migration sans en
porter l'*effet*, et rien dans l'interface ne le disait. Trois causes enchaînées, toutes vérifiées
dans ce repo : (a) `ensure-deps.sh:119-120` — `detect_gsd()` renvoie vrai sur le VERSION file legacy
via un `||` écrit pour la tolérance dual-layout (D-01/D3, Phase 10), et `:133` en fait un `skip`,
donc **même appelé, le script sauterait la migration** ; (b) aucun chemin de mise à jour n'appelle
`ensure_gsd()` — `vf-update/SKILL.md` §Garde-fous place explicitement le moteur **hors périmètre**
(« la chaîne d'outils interne a sa propre mise à jour »), frontière que cette phase révise puisque
la version du moteur est décidée par VibeFlow (`@^1`, `ensure-deps.sh:166`) ; (c)
`log_legacy_cleanup_if_needed()` (`:184`) n'est appelé que depuis `ensure_gsd()`, donc joignable
uniquement par `/vf-init` et `/vf-calibrate` — **un garde-fou correct sur un chemin que le régime
nominal n'emprunte jamais**, exactement le motif déjà rencontré ailleurs.

**Piège de version à écrire noir sur blanc** : le fork **repart de zéro** —
`get-shit-done-cc 1.42.3` (déprécié, figé) contre `@opengsd/gsd-core 1.8.0` (vivant). **1.8.0 <
1.42.3 en semver.** La doctrine « ne jamais downgrader » du skill `vf-update`, saine partout
ailleurs, interdirait précisément le geste à faire. La migration se décide donc sur le **nom du
paquet et le layout du dossier**, jamais sur la comparaison des numéros. Nuance portée au rapport
d'origine : `check-plugin-update.sh` ne compare que les **tags GitHub du plugin VibeFlow**, jamais un
numéro de moteur — il n'y a donc **aucun comparateur en défaut aujourd'hui**, le piège concerne le
détecteur qui reste à écrire.

**Effet de bord à couvrir dans le même geste** : l'installeur amont `gsd-core` réécrit
`agents/gsd-executor.md` et classe l'injection ADR-051 en « local patch » — `mcp__XcodeBuildMCP__*`
**disparaît du `tools:`**. `ensure-deps.sh:248` (`patch_gsd_executor_mcp`, `--force`, idempotent) sait
la restaurer, mais `_internal/vibeflow-update.sh:268` n'injecte que dans les agents flaggés
`vf-mcp-consumer` — flag que `gsd-executor` **ne porte pas** (fichier hors plugin, `:268` de
`ensure-deps.sh`). Deux chemins, une seule couverture : toute migration automatique du moteur doit
**enchaîner** sur la ré-injection, sinon l'exécutant perd silencieusement son accès MCP.

**Requirements**: TBD (à dériver au cadrage)
**Depends on:** aucune — **indépendante de la Phase 18**, dont le GO est suspendu à une RFC upstream
`open-gsd/gsd-core`. La Phase 19 ne touche ni au ledger d'exigences ni à `gsd-complete-milestone`.
**Success Criteria** (what must be TRUE):

  1. `detect_gsd()` renvoie un **état à trois valeurs** — `absent` / `legacy` / `gsd-core` — et
     « legacy » est **actionnable**, plus jamais un `skip`. La décision se prend sur le layout et le
     nom du paquet ; **aucune comparaison de numéros** n'entre dans le classement.

  2. `/vf-update` **dit l'état du moteur** dans le même récapitulatif que le plugin et les modules,
     et propose la migration comme **une ligne de plus dans la confirmation `AskUserQuestion`
     existante** (ADR-031). Refus accepté sans effet de bord ; **aucune migration silencieuse**.

  3. Toute installation ou réinstallation du moteur **enchaîne** sur `inject-mcp-tools.sh --force`
     pour `gsd-executor`, avec **vérification après coup** : si le `tools:` final ne contient pas les
     serveurs déclarés dans le `.mcp.json` du lab, c'est dit fort.

  4. Le message de nettoyage legacy est **atteignable** en régime nominal et **exact** : `npm
     uninstall -g` n'est proposé que si le paquet est réellement installé en global (constaté faux
     sur le poste audité : install `npx`, jamais globale), et le retrait de l'arborescence vide
     laissée debout par l'installeur est inclus.

  5. **Tests de non-régression** : le couple exact `1.42.3 → 1.8.0` est classé « à migrer » ; et un
     test de cohabitation couvre le **scénario réel** — poste legacy déjà installé + plugin à jour →
     migration **détectée**. La suite `test-gsd-cohabitation.sh` livrée en v2.39.0 ne teste que le
     merger `settings.json`, sinon le trou aurait été vu.

  6. **Repli legacy préservé** : la cascade à 4 niveaux de `detect-gsd-engine.sh` /
     `build-gsd-index.sh` continue de fonctionner pour les postes non encore migrés — c'est le
     **skip** qu'on corrige, pas le repli. Plafond `@^1` **inchangé**.

  7. Gouvernance tenue : `check-agents.sh` vert, densité ADR-029, portabilité macOS + Linux prouvée
     par exécution, module bumpé, release racine + tag annoté poussé, `check-release-tag.sh
     --remote` ✓.

**Hors périmètre, décidé** : aucun **hook `SessionStart` supplémentaire** sur l'état du moteur. Le
signal passe par `/vf-update`, pas par une ligne de plus au démarrage de chaque session.

**Doctrine à réviser** : la frontière de périmètre de `vf-update/SKILL.md` §Garde-fous (« la chaîne
d'outils interne a sa propre mise à jour — hors périmètre ») devient fausse et doit être réécrite —
ADR à créer, c'est un **changement de doctrine**, pas un correctif de configuration.

**Plans:** 3/3 plans executed

Plans:

- [x] 19-01-PLAN.md — Gate `check-gsd-engine.sh` : détection à 3 états (layout/nom de paquet, jamais les numéros), contrat de sortie 0/2/3, suite dédiée + preuve Linux (vague 1)
- [x] 19-02-PLAN.md — `ensure-deps.sh` : détecteur à 3 valeurs, fin du skip sur legacy, chemin `--migrate-engine` chaîné sur la ré-injection MCP, message de nettoyage exact ; `inject-mcp-tools.sh --verify` (vague 1)
- [x] 19-03-PLAN.md — `vf-update/SKILL.md` : diagnostic à deux volets et ligne de confirmation moteur ; ADR-058 ; release-meta `dev-orchestrator` v2.7.0 + `conductor` v1.16.0 (vague 2, dépend de 19-01 et 19-02)

### Phase 20: Fluidité du flux de dev sans perte de qualité

> **Origine — second rapport de l'audit externe du 2026-07-28** (même lab `ExploreSomfy`, tranche de
> dev iOS en 5 lots dont 2 parallélisés par worktrees, ~90 commits, suite passée de 177 à 331
> tests) : `.planning/missions/2026-07-28-audit-externe-fluidite.md`. **Les 4 constats ont été
> vérifiés sur pièce le 2026-07-28** avant ouverture — 3 confirmés (dont 2 plus solidement que le
> rapport ne l'affirme), 1 **partiellement daté**. Découpage arbitré par Samuel : **une phase
> unique** pour les 4 changements, contre la recommandation de scinder le changement 2.

**Goal**: Rendre le flux de dev **plus rapide et plus fluide sans perdre en qualité**, par quatre
changements indépendants dont deux touchent la doctrine. Deux garde-fous non négociables encadrent
toute la phase, tirés des chiffres de l'audit :

- **Ne jamais réduire le nombre de tests.** Mesuré : sur 90 s de `test_sim`, les tests pèsent ~1 s,
  tout le reste est compilation et installation. Levier nul.

- **Ne jamais alléger la revue sur le chemin critique produit** — 5 bloquants y ont été trouvés en
  une journée, dont un qui cassait le geste le plus fréquent de la démo.

- **Aucun allègement ne s'applique jamais à un diff de comblement.** Sur cette tranche, **9 fois,
  puis 5, puis 4 défauts sont nés des correctifs de revue eux-mêmes**. Une re-revue reste pleine,
  quelle que soit la nature du lot d'origine.

**Changement 1 — `mcp__XcodeBuildMCP__*` à `vf-reviewer`, et révision d'ADR-051.**
`docs/ADR.md` §ADR-051 porte la prémisse contestée mot pour mot : « les agents de planif/revue/audit
(`vf-dev-manager`, `vf-reviewer`, `vf-auditer`) restent inchangés (moindre privilège — **ils ne
compilent jamais**) ». Elle confond **produire** un verdict de compilation et **en vérifier** un :
un relecteur n'a pas besoin de compiler pour livrer, il en a besoin pour ne pas *croire* un message
de commit (constaté : « la revue de phase a dû croire un message de commit »). `vf-reviewer` a déjà
`Bash`, l'outil le plus large — il ne lui manque pas l'outil dangereux, il lui manque l'outil
sanctionné, alors que le `CLAUDE.md` du lab interdit `xcodebuild` en shell.
**Fait vérifié dans ce repo, plus grave que le rapport ne le dit** — le moindre privilège invoqué
n'existe déjà plus, `memory: project` rouvrant `Write`/`Edit` au runtime :

| Agent | `tools:` déclaré sur disque | `tools:` au runtime |
|---|---|---|
| `vf-reviewer` | `Read, Bash, Glob, Grep, Agent(gsd-code-reviewer)` | + **`Write, Edit`** |
| `vf-auditer` | `Read, Bash, Glob, Grep, Agent(gsd-security-auditor)` | + **`Write, Edit`** |
| `vf-design-judge` | `Read, Bash, Glob, Grep` | + **`Write, Edit`** |

Le cas de `vf-design-judge` dépasse le constat d'origine : sa **description** affirme « Ne corrige
JAMAIS rien — **sans Write ni Edit** » — une barrière que le runtime ne pose pas, et cette phrase
est lue par les agents qui le dispatchent. Le « je juge, je ne corrige pas » est une consigne de
prompt, pas une barrière.
**À instruire AVANT de livrer, par le test et non par la supposition** : ADR-051 établit que
`mcp__*` est refusé en allowlist et que seule la forme par-serveur `mcp__<serveur>__*` est admise —
il ne dit **rien** du nom d'outil exact. Si une allowlist fine (`test_sim` / `build_sim` seulement)
passe dans le `tools:` d'un subagent, elle est préférable au wildcard. **Coût à assumer et à
écrire** : un relecteur qui peut lancer les tests va les lancer — +90 s par revue et un slot de
simulateur consommé.

**Changement 2 — sortir la revue de `vf-coder` et la graduer par RISQUE.**
Défaut de **placement**, pas de doctrine. `vf-dev-manager.md:93-94` sait déjà graduer (« une étape UI
saute l'audit sécurité ; une étape sécurité le garde ») et l'audit est conditionnel (`:103`). La
revue, elle, est **en dur à l'étape 4 du cycle interne de `vf-coder`** (`vf-coder.md:34`, sans
condition). **Fait vérifié qui verrouille le diagnostic** : `vf-dev-manager.md:108` interdit
explicitement au manager d'en ajouter une — « **Pas de double revue** : si le rapport typé de
`vf-coder` est `passed` avec verdict revue PASS, ne re-dispatche pas de revue de code ». La revue est
donc le seul étage à la fois **obligatoire et hors de portée du manager**.
La seule gradation existante est indexée sur le **volume** : `SEUIL_EQUIPE = 3`
(`mission-contracts.md:105`) compte des étapes restantes. Mauvais axe — trois lignes sur un chemin
BLE partagé sont minuscules et à très haut risque ; 400 lignes de Domain pur prouvées par mutation
sont grosses et à bas risque.
**Rendement observé par nature de lot** (aucun rattrapable par les tests, sauf la dernière ligne) :

| Nature du lot | Bloquants trouvés |
|---|---|
| Adaptateur matériel (non injectable, non testable) | 3 |
| Contrôleur partagé entre features | 3 |
| **Jointures entre lots parallèles** | **4 bloquants + 9 majeurs** — « aucun relecteur cadré sur un seul lot ne les aurait vus » |
| Geste utilisateur / géométrie de vue | 3 (trouvés par géométrie et capture d'écran) |
| **Domain pur avec tests de mutation** | **0** — terrain le mieux couvert |
| Documentation / catalogue de chaînes | 0 bug, mais 2 faits faux bloquants pour la mission suivante |

**Changement 3 — `.planning/MISSION-INVARIANTS.md`.**
Le constat incrimine son auteur, et les deux faits qui le fondent sont vérifiés :
`mission-contracts.md` dit bien « le brief ne porte QUE ce qui n'est pas sur disque, il ne paraphrase
jamais `ROADMAP.md`/`STATE.md`/`PROJECT.md` », et `vf-dev-manager.md:29` lit déjà le `CLAUDE.md` du
projet avec préséance. Recopier les conventions à la main dans chaque brief duplique donc ce que la
machine lira de toute façon — et c'est cette recopie qui a produit une contradiction interne à
corriger en cours de mission. **Le gabarit n'a pas manqué : il a été court-circuité.**
Mais **trois invariants ne vivent nulle part sur disque** et aucun agent ne peut les deviner : le
**seuil de tests courant** (mouvant : 177 → 331 en une journée) ; la **table des fichiers gelés** par
mission en vol ; les **motifs de risque récurrents** du projet (« la neuvième occurrence du motif de
la phase » — donc connu, mais écrit nulle part). Le fichier reste court, relu par le manager au même
titre que `STATE.md` ; le brief garde ses champs minimaux.
**Coût à écrire noir sur blanc : s'il ment, il est pire que rien** — précédent réel d'un `CLAUDE.md`
affirmant encore « deux trous interdisent toute installation device » alors que la mission suivante
devait recetter sur device. **Prévoir comment il est tenu à jour, ou ne pas le créer.** Sa table des
fichiers gelés alimente directement le critère (b) du changement 2.

**Changement 4 — scope des hooks de conformité. ⚠ CONSTAT PARTIELLEMENT DATÉ.**
**La moitié demandée est déjà livrée** : l'option d'exclusion existe et `gsd-` est son **défaut** —
`check-agents.sh` §Usage (`--third-party-prefix=PFX`, répétable) et `:84`
(`THIRD_PARTY_PREFIXES="gsd-"`), livrés en **Phase 16 / v2.41.0 le 2026-07-27**, soit la veille du
rapport. **Mesuré le 2026-07-28** sur `~/.claude/agents` avec la version du repo (identique à celle
installée) : **23 lignes, pas 68** — 21 warnings **tous sur des agents `vf-*`**, 34 agents tiers
`gsd-*` écartés proprement, **zéro finding `gsd-`**. Le motif du refus du 28/07 (« 68 lignes dont 66
de bruit ») ne tient plus. La phase ne doit donc **pas** créer un `--exclude=GLOB` redondant.
**Ce qui reste vrai et non corrigé** : `check-agents.sh:78` fixe `AGENTS_DIR=".claude/agents"`
**relatif au cwd**, le hook `SessionStart` de `conductor/hooks/hooks.json` appelle
`check-agents.sh --hook` **sans `--agents-dir`**, et un lab en scope user n'a aucun agent dans son
projet. **Vérifié : le hook tel qu'il tourne sort 0 ligne** — le garde-fou de conformité ne regarde
rien. Même diagnostic pour `check-debug-research.sh --hook`. Les deux sont en plus masqués par
`|| true`.
**La conséquence s'inverse** : corriger le scope produirait aujourd'hui **21 warnings de signal
réel** sur les agents que VibeFlow gouverne — dont, précisément, l'écart `tools:` déclaré/runtime du
changement 1. Impraticable le 28/07, praticable maintenant.

**Requirements**: SC1, SC2, SC3, SC4, SC5, SC6, SC7 (les 7 critères de succès ci-dessous servent
d'IDs de traçabilité — aucun ID formel `REQ-` n'existe pour cette phase dans `REQUIREMENTS.md`,
même convention que les Phases 15 à 19 ; numérotation reprise telle quelle par `20-RESEARCH.md`,
`20-VALIDATION.md` et le champ `requirements` de chaque `20-NN-PLAN.md`).
**Depends on:** aucune — indépendante des Phases 18 (bloquée par RFC upstream) et 19 (livrée).
**Success Criteria** (what must be TRUE):

  1. **ADR-051 est révisé** sur ce seul point, avec l'argument explicite « un relecteur ne PRODUIT
     pas de verdict de compilation, il en VÉRIFIE un », et `vf-reviewer` obtient l'accès MCP — **à
     lui seul**, ni `vf-auditer` ni `vf-dev-manager`. La granularité (allowlist fine vs wildcard
     par serveur) est tranchée **par un test réel**, pas par lecture de doc.

  2. **L'écart `tools:` déclaré / runtime est traité, pas seulement constaté** : la description de
     `vf-design-judge` cesse d'affirmer une barrière `Write`/`Edit` que le runtime ne pose pas, et
     le repo dit quelque part que `memory:` rouvre ces outils.

  3. **La revue est un étage de premier rang piloté par le manager**, au même titre que l'audit et
     le test — sans quoi la gradation n'a nulle part où s'appliquer. La règle « pas de double
     revue » (`vf-dev-manager.md:108`) est réécrite en conséquence, pas contournée.

  4. **Les critères de déclenchement sont objectifs, jamais des seuils au jugé** : revue renforcée
     non négociable si le diff touche (a) un adaptateur d'infra non couvert par les tests, (b) un
     fichier partagé avec une mission parallèle en vol, (c) du code que la mutation ne couvre pas,
     (d) un geste utilisateur ou une géométrie de vue. **Revue de jointure obligatoire, en nœud
     séparé**, dès que deux lots parallèles fusionnent — meilleur rendement de toute la tranche,
     étage qui n'existe aujourd'hui que parce qu'il a été créé à la main. Revue allégée réservée au
     Domain pur à mutation verte, à la documentation et aux catalogues sans ajout de clé.
     **En cas de doute, revue pleine** — le classement du lot est un point de décision, donc un
     point d'erreur : le défaut par défaut doit être le sûr.

  5. **`MISSION-INVARIANTS.md` porte les 3 invariants + la contrainte d'outillage du moment**, le
     brief reste à ses champs minimaux, et **son mécanisme de mise à jour est spécifié** — faute de
     quoi le fichier n'est pas créé (critère falsifiable : un invariant périmé doit être détectable).

  6. **Le scope des deux hooks est corrigé** (`check-agents.sh --hook`,
     `check-debug-research.sh --hook`) et le garde-fou devient **silencieux en régime nominal et
     utile sur les dérives** — **sans** créer d'option d'exclusion redondante avec
     `--third-party-prefix`, déjà livrée et déjà réglée sur `gsd-`.

  7. Gouvernance tenue : `check-agents.sh` vert, densité ADR-029, portabilité macOS + Linux prouvée
     par exécution, modules bumpés, release racine + tag annoté, `check-release-tag.sh --remote` ✓.

**Livrable attendu du cadrage** : pour chaque changement — ce qui bouge fichier par fichier, le
gain, **le coût et le risque**, sa réversibilité, et l'ADR à créer ou réviser. **Distinguer
nettement une correction de configuration (changement 4) d'un changement de doctrine (1, 2, 3).**

**Déjà appliqué le 2026-07-28 côté lab, à ne pas refaire** : profils de session XcodeBuildMCP
désactivés (`XCODEBUILDMCP_DISABLE_SESSION_DEFAULTS=true`) — le serveur n'a qu'**un seul
`SessionStore` global** partagé par la fenêtre principale et tous les sous-agents, et `build_sim` /
`test_sim` n'exposaient **aucun paramètre de projet** dans ce mode ; constaté : une exécution
complète partie sur le code d'un autre worktree. **Conséquence à propager : chaque appel de build
doit porter son `projectPath`, son `scheme` et son `simulatorId`/`deviceId`.** Purge du cache
`test-products` (12 Go → 1,3 Go) également faite.

**Piège d'outillage à inscrire dans la doctrine de gate** : un `build_sim` **en cache** (zéro tâche
`SwiftCompile`) annonce « 0 warning » **sans rien compiler**. Un verdict de warnings non précédé
d'un `clean` est structurellement invérifiable.

**Réserve de cadrage, inscrite pour mémoire** : le découpage recommandé était {1,4} (conformité des
agents observable — le 4 est ce qui rend le 1 visible) et {2,3} (pilotage de mission) en deux
phases. Samuel a tranché pour une phase unique. Le changement 2 vaut à lui seul plus que les trois
autres réunis — si l'exécution déborde, c'est par là qu'il faudra scinder.

**Plans:** 7/7 plans executed

Plans:

- [x] 20-01-PLAN.md — Changement 5 : périmètre explicite des 2 hooks de conformité, avertissements conditionnels en mode hook, charset de token MCP, clé `vf-mcp-tools` connue du gate ; chemin par défaut enfin testé (vague 1)
- [x] 20-02-PLAN.md — `dag.sh` : `--scope` sur `add`, `review_regime` forcé à `full` par `reopen`, périmètres gelés exposés par `status` (vague 1)
- [x] 20-03-PLAN.md — Changement 1 : mode d'injection MCP nommé dans `inject-mcp-tools.sh`, `vf-reviewer` déclare son allowlist et son protocole d'appel (vague 2, dépend de 20-01)
- [x] 20-04-PLAN.md — Critère 2, sens ouverture : `disallowedTools: Write, Edit` sur les 4 juges, `vf-design-judge` cesse d'affirmer une barrière que le runtime ne pose pas (vague 1)
- [x] 20-05-PLAN.md — Changement 3 : `.planning/MISSION-INVARIANTS.md` réduit aux éléments falsifiables + `check-mission-invariants.sh` et sa suite (vague 2, dépend de 20-02, checkpoint humain D-16)
- [x] 20-06-PLAN.md — Changement 2 : la revue devient un étage de premier rang piloté par le manager, graduée par risque, revue de jointure sur topologie (vague 3, dépend de 20-02/20-03/20-05, checkpoint humain D-11)
- [x] 20-07-PLAN.md — Gouvernance : ADR-051 révisée + ADR-060, doctrine `team-kernel`/README alignée, 6 modules bumpés, gates de sortie (vague 4, dépend de tous)

### Phase 21: Alignement du moteur GSD sur gsd-core 1.9.0

> **Origine** — mise à jour du moteur de 1.8.0 vers 1.9.0 sur le poste de Samuel le 2026-07-31
> (11:35). Delta établi **sur pièce** par `npm pack` des deux versions et diff intégral des
> tarballs, plus vérification de l'installation vivante :
> `.planning/missions/2026-07-31-delta-gsd-core-1.9.0.md`. Découpage arbitré par Samuel le
> 2026-07-31 : **une phase unique**, périmètre exhaustif, **rituel allégé**.

**Goal**: Faire coller VibeFlow à `@opengsd/gsd-core` 1.9.0 — réparer le seul défaut actif,
adopter les contrats amont qui créent une perte silencieuse, instruire les recouvrements
d'architecture, et purger la dette de version — puis **publier une release racine** (tag annoté +
release GitHub, discipline `CLAUDE.md`).

**Le point de départ n'est pas une panne.** Vérifié avant ouverture : aucun frontmatter d'agent ne
change entre 1.8.0 et 1.9.0 (les 10 agents modifiés ne bougent que dans le corps — `description:`,
`tools:` et `model:` identiques), 71 skills des deux côtés sans ajout ni suppression,
`_runtime-launcher.snippet.sh` identique, les 43 suites vertes, aucun hook déclaré manquant, gates
`check-gsd-engine.sh` et `detect-gsd-engine.sh` au vert. **Le dispatch tient.** Cette phase est de
l'alignement, pas du sauvetage — à l'exception du changement 1.

**Changement 1 — l'injection MCP (ADR-051) est structurellement inopérante sur ce poste.**
Seul défaut qui dégrade réellement le fonctionnement. L'update a réécrit
`~/.claude/agents/gsd-executor.md` (mtime identique à celui de `gsd-core/VERSION`) et effacé
`mcp__XcodeBuildMCP__*` de son `tools:` — comportement connu, documenté au README v2.43.0
(l'installeur amont classe l'injection en « local patch »). Mais la remédiation prévue **ne peut
pas s'appliquer** : `inject-mcp-tools.sh` dérive les serveurs de `./.mcp.json` (défaut de
`--mcp-json`), or **aucun lab de `~/Documents/dev` n'a de `.mcp.json`** — `XcodeBuildMCP` est
déclaré en **scope global** dans `~/.claude.json`. `--verify` sort donc en `3 / INDÉTERMINÉ` au lieu
de signaler le manque, et `ensure-deps.sh --migrate-engine` ne rattrape rien. Conséquence : sur un
projet iOS, `gsd-executor` dispatché par `vf-coder` est **aveugle à XcodeBuildMCP** (un sous-agent
n'hérite pas des serveurs MCP de la session), alors que le `CLAUDE.md` de RoastMyRoom interdit
`xcodebuild` brut. La cause n'est pas la 1.9.0 — c'est une **lacune de scope dans notre propre
script**, que chaque update du moteur révèle à nouveau.

**Changement 2 — câbler le contrat `estimate:` / `actuals:` (ADR-2629 amont, #2632).**
`gsd-planner` émet désormais un bloc `estimate:` (`tokens`, `raw_tokens`, `tasks`, `confidence`
— cette dernière **dérivée du nombre d'échantillons, jamais auto-évaluée**) dans le frontmatter du
`PLAN.md` ; `gsd-executor` doit écrire `actuals:` (`tokens`, `tasks`, `commits`) dans le `SUMMARY`
quand le plan portait un `estimate`. Deux exigences amont à respecter : **même échelle** des deux
côtés (`chars/4` sur le diff réalisé, **pas** un compteur du harness — sinon on mesure les méthodes
de mesure), et **aucun arrondi flatteur**. `dev-orchestrator/references/mission-contracts.md`
définit les contrats de sortie typés de `vf-coder` et des workers et **ignore ces deux champs** :
les missions pilotées par `vf-dev-manager` traversent la chaîne sans jamais alimenter la boucle de
calibration. Rien n'échoue — la donnée n'existe simplement pas. **Perte silencieuse**, d'où sa
place dans le périmètre.

**Changement 3 — instruire le recouvrement avec les lanes de revue amont (ADR-2782 Phase 1,
#2794, clôt #2690).** `review-lane-descriptor.cjs` déclare **en données** le contrat des reviewers
cross-AI, jusqu'ici éclaté sur trois surfaces (roster, ~640 lignes de bash par CLI dans
`workflows/review.md`, en-têtes codés en dur dans `write_reviews`). Le module **déclare, il
n'exécute pas** — `invoke_reviewers` garde ses jambes manuelles jusqu'à la Phase 5b amont (#2799) ;
l'apport est `checkReviewerLaneParity`. À trancher **explicitement plutôt que par omission** : le
recouvrement avec l'**étage de revue de premier rang** livré en 20-06 (`vf-reviewer` →
`gsd-code-reviewer`). Ce sont a priori deux objets distincts — revue **cross-AI de plans** en amont,
revue de **diff de code** chez nous — mais l'arbitrage doit être écrit.

**Changement 4 — instruire `runtime-aware-dispatch` (#2505 Phase 4 / #2508) et
`executor-isolation-dispatch`.** L'amont distingue les runtimes à **dispatch nommé**
(`hostIntegration.dispatch.namedDispatch: true` — Claude Code, OpenCode, Cursor, Cline) des
runtimes **built-in-only** (kimi-code : `coder`, `explore`, `plan`), où un nom de rôle GSD est
inconnu et doit tomber sur le built-in le plus proche. Nos managers dispatchent des agents nommés
**en dur** ; `.gsd-runtime` vaut `claude` ici, donc aucun effet immédiat — mais l'hypothèse « le
dispatch nommé marche toujours » est désormais fausse en général et **n'est écrite nulle part chez
nous**. À recouper aussi : `gsd-executor` accepte maintenant `agent-<id>` **ou**
`worktree-agent-<id>` (#1995), et remonte un nouveau cas d'échec `staging_failed` /
`staging_timeout` à ne pas retenter (#2608) — à confronter à `gsd-worktree-path-guard`.

**Changement 5 — purger la dette de version figée sur 1.8.0.** `gsd-skills-index.md` est
**auto-généré** et porte « depuis @opengsd/gsd-core@1.8.0 », daté 2026-07-26 → regénérer via
`build-gsd-index.sh` ; `mission-contracts.md` cite « gsd-core 1.8.0 » (:148) et « tag stable =
1.8.0 » (:172) ; `check-gsd-engine.sh` (:25) et `detect-gsd-engine.sh` (:30) citent 1.8.0.
⚠️ **Piège à préserver, pas à corriger** : `test-check-gsd-engine.sh` **cas 8 asserte la présence
littérale de la chaîne `1.8.0`** dans l'en-tête — le test doit bouger avec le texte. Et la leçon
elle-même reste vraie : le fork repart de zéro, donc **1.9.0 < 1.42.3 en semver** — la migration se
décide sur le **nom du paquet et le layout**, jamais sur la comparaison des numéros.

**Changement 6 — statuer sur les hooks 1.9.0 non câblés.** `gsd-ensure-canonical-path.js` et
`gsd-update-banner.js` sont posés par 1.9.0 et absents de `settings.json` (les `gsd-cursor-*` /
`gsd-windsurf-*` sont normalement dormants hors de leur runtime, `gsd-check-update-worker.js` est
un interne appelé par son parent). Rien n'est cassé, mais une fonctionnalité amont est peut-être
inactive faute de câblage. Décider si `merge-hooks.sh` doit en tenir compte — ou acter que c'est un
sujet `gsd-core`, hors périmètre VibeFlow.

**Requirements**: Changements 1 à 6 + le point hérité (anomalie d'agrégation `STATE.md`) servent
d'IDs de traçabilité — aucun ID formel `REQ-` n'existe pour cette phase dans `REQUIREMENTS.md`
(le ledger s'arrête à ALTI-05 / Phase 14, vérifié sur pièce), même convention que les Phases 15 à
20 ; numérotation reprise telle quelle par le champ `requirements-completed` de chaque
`21-0N-PLAN.md`/`SUMMARY.md`.
**Depends on:** Phase 20 — **merge requis avant exécution**. Même règle que le diagnostic du
2026-07-29 : les phases qui touchent le couplage au moteur attendent que la 20 soit mergée pour
éviter les conflits sur les fichiers partagés.
**Plans:** 5/5 plans executed

Plans:

- [x] 21-01-PLAN.md — Changement 1 : `inject-mcp-tools.sh` découvre les serveurs MCP en union de deux scopes (`./.mcp.json` projet ∪ `~/.claude.json` global), corrige le défaut actif ADR-051 (vague 1)
- [x] 21-02-PLAN.md — Changements 2, 3, 4 : contrat `estimate:`/`actuals:` relayé verbatim, ADR-061 (recouvrement lanes de revue amont vs étage 20-06), hypothèse datée du dispatch nommé + recoupement #1995/#2608 (vague 1)
- [x] 21-03-PLAN.md — Changements 5, 6 : purge de la dette de version 1.8.0 → 1.9.0, ADR-062 (hooks 1.9.0 non câblés, absence correcte dans les deux cas) (vague 2)
- [x] 21-04-PLAN.md — Point hérité : `check-state-integrity.sh` (gate anti-régression du frontmatter de `STATE.md`, module `conductor` v1.18.0) et ADR-063 (arbitrage de l'anomalie d'agrégation) (vague 2)
- [x] 21-05-PLAN.md — Gouvernance : CI remise au vert (compteur de suites), 2 modules bumpés (`dev-orchestrator` v2.10.0 — v2.9.0 étant déjà prise en amont, `planning-core` v2.5.3), ROADMAP recalé, 4 warnings traités, `STATE.md` recalé, release racine v2.45.0 préparée (vague 3, dépend de tous)

### Phase 22: Hygiène documentaire — doctrine de sortie et captation d'intention

> **Origine** — demande de Samuel le 2026-07-31 : « le dev-orchestrator n'a pas de workflow de
> mise à jour de doc avec les commandes GSD qui maintiennent la doc et les specs ». Gap établi
> **sur pièce** par lecture des workflows amont (`gsd-core/workflows/docs-update.md` 1177 lignes,
> `ingest-docs.md`, `map-codebase.md`, `extract-learnings.md`) confrontés à l'état du module.

**Goal**: Donner au moteur de dev une **doctrine documentaire de sortie** — symétrique de la
doctrine d'entrée déjà écrite (`ingestion-flow.md`) — et la **captation d'intention en langage
naturel** qui la déclenche, de sorte que (a) `vf-dev-manager` et `vf-design-manager` sachent
QUAND poser un nœud de doc et LEQUEL, et (b) l'utilisateur obtienne le bon geste sans jamais
nommer une commande, exactement comme « on en est où ? » tombe aujourd'hui sur `gsd-progress`.

**Le point de départ n'est pas un manque d'outils — c'est un manque de discernement.**
Les quatre familles documentaires que GSD maintient sont **outillées séparément amont** et
**fondues en une seule ligne** chez nous (`intent-routing.md` : « mets à jour la doc / génère le
README / la doc est périmée » → `gsd-docs-update`) :

| Famille | Brique | Ce qui est réellement maintenu |
|---|---|---|
| doc **produit** | `gsd-docs-update` | 6 docs toujours-on (README, ARCHITECTURE, GETTING-STARTED, DEVELOPMENT, TESTING, CONFIGURATION) + 3 conditionnelles (API si routes, CONTRIBUTING si OSS, DEPLOYMENT si config de déploiement), **plus** une *review queue* des docs écrites à la main vérifiées contre le code, **plus** une détection de trous. CHANGELOG **jamais** régénéré. |
| doc **d'entrée** | `gsd-ingest-docs`, `gsd-import` | specs/ADR/PRD → `.planning/`. Doctrine déjà écrite (`ingestion-flow.md`). |
| doc **du code** | `gsd-map-codebase` | `.planning/codebase/` (STACK, ARCHITECTURE, CONVENTIONS, CONCERNS…), modes `--fast` / `--query refresh`. |
| doc **de savoir** | `gsd-extract-learnings`, `gsd-graphify` | LEARNINGS.md de phase, graphe de connaissance. |

**Lacune 1 — aucune doctrine de sortie.** L'entrée a ses 94 lignes de garde-fous ; la sortie n'a
qu'une ligne de table. Un agent à qui l'on dit « mets à jour la doc » ne sait pas s'il s'agit du
README, de `.planning/codebase/`, ou de `STATE`. Les **flags porteurs de sens** de
`gsd-docs-update` ne sont exposés nulle part : `--verify-only` (auditer sans écrire — la doc
est-elle encore juste ?) et `--force` (régénérer, écrase le manuscrit) répondent à **deux
intentions distinctes** aujourd'hui indiscernables.

**Lacune 2 — captation d'intention famélique.** Une seule ligne de formulations pour un geste que
l'utilisateur exprime de vingt façons : « la doc est fausse », « ça correspond plus au code »,
« documente ce module », « il manque la doc d'API », « vérifie que la doc dit encore vrai »,
« on a changé l'archi », « qu'est-ce qu'on a appris ». Aucune ne tombe de façon fiable.

**Lacune 3 — managers sans moments déclencheurs.** `vf-dev-manager` porte 3 puces d'hygiène et
une seule mention outillée (« drift doc détecté → ajoute un nœud `gsd-docs-update` ») ; il
n'existe aucune table « à ce moment du cycle → cette brique, à cette condition ».
`vf-design-manager` n'a **aucun** geste documentaire : son gate `DESIGN.md` ne parle jamais à la
doc produit, alors qu'une refonte d'écran périme ARCHITECTURE/README aussi sûrement qu'un refactor.

**Lacune 4 — le signal existe, le destinataire n'est pas outillé.** Le hook `[doc-drift]`
(`check-doc-drift.sh`, Phase 17) constate déjà le FAIT — N commits de code sans commit de doc —
et propose `gsd-docs-update`. Personne n'est équipé pour transformer ce constat en geste gradué
(vérifier ? régénérer une doc ? toutes ?).

**Requirements**: DOCF-01, DOCF-02, DOCF-03, DOCF-04, DOCF-05, DOCF-06, DOCF-07
*(IDs créés au plan du 2026-07-31 — aucun préfixe existant du ledger ne couvrait ce périmètre ;
définis dans `.planning/REQUIREMENTS.md` §Hors-milestone — Phase 22.)*
**Depends on:** Phase 20 — **merge requis avant exécution**. Périmètre à fichiers partagés avec
la 20 (`intent-routing.md`, `mission-contracts.md`, `vf-dev-manager.md`). **Indépendante de la
Phase 21** (alignement gsd-core 1.9.0) : aucun fichier commun, l'ordre d'exécution est libre.
**Plans:** 1/3 plans executed
partagé par les plans 01 et 02 — pas de parallélisme possible). Découpage tracer-first : le plan
01 prouve la chaîne complète sur UNE intention avant d'écrire les trois autres familles.

Plans:

- [x] 22-01-PLAN.md — doctrine de sortie `docs-flow.md` (4 familles, 3 régimes, garde-fous) +
  captation d'intention dans `intent-routing.md` + câblage `AGENT.md` au chemin d'install D7 +
  bloc de garde T22. *Tracer : la doctrine existe, est référencée, s'installe réellement et est
  gardée — prouvé sur une seule intention avant toute expansion.* (DOCF-01→04, DOCF-06)

- [ ] 22-02-PLAN.md — les deux managers dotés du nœud `docs` agrégé et des 4 déclencheurs, par
  renvoi vers la doctrine (aucune copie) + bloc de garde T23 + checkpoint humain sur la
  formulation de `--force` (D-05/D-06). (DOCF-05, DOCF-06)

- [ ] 22-03-PLAN.md — bump **minor** des 2 modules touchés (`dev-orchestrator` v2.9.0,
  `design-orchestrator` v1.4.0), triades + CHANGELOG, `check-version-sync.sh` ✓. Release racine
  **hors périmètre**, réservée à validation humaine. (DOCF-07)

### Phase 23: Couplage explicite au moteur GSD — capabilities, flags et voie unique

> **Origine** — analyse du 2026-07-31, déclenchée par l'observation d'un `gsd-pattern-mapper`
> spawné en session **inline** (hors `vf-dev-manager`) et la question de Samuel : « dev-manager a-t-il
> accès à cet outil, et sait-il utiliser GSD avec le bon workflow, au bon moment, quand c'est
> réellement utile ? ». Gap établi **sur pièce** contre `@opengsd/gsd-core@1.9.0` **installé**
> (`~/.claude/gsd-core/VERSION` = 1.9.0, pas le 1.8.0 de l'index versionné) : lecture de
> `workflows/plan-phase.md`, `workflows/execute-phase.md`, `bin/lib/config.cjs`,
> `bin/lib/capability-registry.cjs`, et **sortie réelle** de
> `gsd-tools.cjs loop render-hooks` sur 6 points de hook.

**Goal**: Rendre le couplage du moteur de dev à GSD **explicite et arbitré** — (a) une **voie
unique** d'invocation des briques de cycle, (b) une **doctrine de flags** par sous-phase, (c) une
**table des capabilities/hooks** qui dit qui couvre quoi, (d) un **contrat de checkpoint aligné**
sur celui du moteur (type × `gate`, continuation) et (e) des **budgets de boucle additionnés** —
de sorte que la chaîne d'équipe cesse de superposer des étages que GSD lance déjà, de laisser
accessible sans garde-fou une voie qui en désactive la moitié, et de pouvoir trancher seule un
checkpoint que le moteur a refusé de trancher.

**Ordre de traitement imposé** : la **Lacune 6 (sûreté) passe en premier** — c'est la seule dont la
conséquence est un mauvais comportement silencieux, les autres coûtant du volume ou de la
cohérence. Elle est aussi le prérequis de la Lacune 3 : la doctrine de flags ne peut pas être
écrite sans savoir ce qu'un `--auto` auto-approuve.

**Le point de départ n'est pas une panne.** La chaîne tourne, les agents ont les accès, aucune
suite n'échoue. Le défaut est un **couplage implicite** : le module raisonne comme si GSD était une
liste de skills à appeler, alors que GSD 1.9 est un **moteur à capabilities** qui insère ses étages
lui-même.

**Constat 0 — l'accès n'est pas le sujet.** `gsd-pattern-mapper` est déclaré dans les allowlists
`Agent(...)` de `vf-dev-manager.md:4` **et** `vf-coder.md:4` ; et `team-kernel.md:23` acte que cette
allowlist est **un contrat documenté, pas un cloisonnement runtime** pour un agent dispatché en
sous-agent. Le pattern-mapper de la capture n'a d'ailleurs été choisi par **aucun** agent :
`plan-phase.md:651` — « Pattern mapper activation is owned by the `pattern-mapper` capability's
`plan:pre` step hook ». La bonne question n'est donc pas « y a-t-il accès », c'est « qui décide,
et le module le sait-il ».

**Constat 1 — le mécanisme de capabilities est invisible pour le module.**
`grep -r "capabilit\|render-hooks\|plan:pre\|verify:post"` sur `plugin/dev-orchestrator/` →
**zéro occurrence**. `gsd-pattern-mapper`, `gsd-verifier` et `gsd-nyquist-auditor` n'apparaissent
**que** dans les lignes `tools:`, jamais dans une doctrine d'usage. Hooks réellement actifs
(mesurés, pas déduits) :

| Point | Capability → brique | Toggle (défaut **true**, `config.cjs:243-273`) |
|---|---|---|
| `plan:pre` | `gsd-phase-researcher`, **`gsd-pattern-mapper`**, `ui-phase`, `ai-integration-phase` | `research`, `pattern_mapper`, `ui_phase` |
| `plan:post` | gap-analysis | `post_planning_gaps` |
| `execute:post` | skill **`code-review`** | `code_review` |
| `verify:post` | **`validate-phase`** (nyquist), **`secure-phase`**, **`ui-review`** | `nyquist_validation`, `security_enforcement`, `ui_review` |

`execute-phase.md` rend **à lui seul** `execute:post` (:1210) **et** `verify:post` (:1152) — un
seul appel de skill déclenche donc revue de code, validation nyquist et audit sécurité.

**Lacune 1 — doublons d'étage non arbitrés.** `vf-dev-manager.md:114-129` pose `revue-N`
**systématiquement** (Pattern E, `mission-flow.md:176-206`) et `vf-auditer` conditionnellement,
par-dessus les hooks `code-review` et `secure-phase` que GSD a déjà lancés. Deux revues du même
diff, deux budgets, deux `reopen` possibles. Ce n'est pas nécessairement faux — la **revue de
jointure** a un rendement prouvé (`mission-flow.md:238` : 4 bloquants + 9 majeurs sur la tranche
Phase 20) — mais l'arbitrage n'est écrit nulle part. À trancher **explicitement plutôt que par
omission**, et **une seule fois** : recouper avec le changement 3 de la Phase 21 (recouvrement avec
les lanes de revue cross-AI amont), qui instruit le même genre de frontière.

**Lacune 2 — une voie dégradée accessible sans garde-fou.** `vf-coder.md:31-32` offre
« ou dispatche l'agent `gsd-planner` » / « ou dispatche `gsd-executor` » **à égalité** avec
l'invocation du skill. Or l'agent nu fait sauter research, pattern-mapper, plan-checker,
gap-analysis, drift gate, waves, verifier, code-review, nyquist et secure-phase — **sans que rien
ne le signale** au rapport typé. C'est le trou le plus grave : un worker peut rendre `passed` en
ayant désactivé la moitié du moteur.

**Lacune 3 — aucune doctrine de flags.** Un seul flag GSD dans tout le module (`--auto` sur
`gsd-discuss-phase`, `vf-coder.md:27`). Deux faits mesurés qui rendent le silence coûteux :

- `plan-phase.md:333` **prompte** sur la recherche si ni `--research` ni `--skip-research` ni
  `--auto` — et `vf-coder` **n'a pas `AskUserQuestion`** (blocage ou auto-réponse silencieuse) ;

- `plan-phase.md:1557-1577` : `--auto` **persiste** `workflow._auto_chain_active` puis enchaîne
  seul `gsd-execute-phase --auto` et la phase suivante. Un `--auto` par réflexe **exécuterait hors
  frontière DAG**, contre le pipelining N/N+1 (`mission-flow.md:98-132`).

Le réglage juste est donc **étroit** (`--research`/`--skip-research` explicite, `--text` si besoin,
**jamais** `--auto` sur plan/execute) et il n'est écrit nulle part.
**Frontière avec la Phase 22** : la 22 porte les flags de la famille **documentaire**
(`--verify-only` / `--force` de `gsd-docs-update`) ; celle-ci porte ceux du **cycle**
discuss/plan/execute. Une seule surface de doctrine, pas deux — la première exécutée fixe la forme.

**Lacune 4 — briques routées mais jamais mobilisées en mission.** Présentes dans
`intent-routing.md` (couverture 100 % vérifiée machine) et absentes du cycle d'équipe :
`gsd-spec-phase`, `gsd-add-tests`, `gsd-extract-learnings` (l'hygiène du manager ne cite que
`gsd-docs-update`), `gsd-debug` — `vf-dev-manager` n'a même pas `gsd-debugger` en allowlist, donc
après la recherche doc d'ADR-045 il n'a **rien** —, `gsd-undo` sur échec, `gsd-forensics` après
blocage, et `gsd-ship`/`gsd-pr-branch` : le manager ouvre la PR à la main (ADR-059) alors que
`GSD-PIPELINE.md:19` place `gsd-ship` dans le cycle canonique — **tension non tranchée**.

**Lacune 5 — le `config.json` du lab n'est pas aligné sur le moteur.** `gsd-tools` avertit à chaque
appel : « unknown config key(s) in .planning/config.json: `gates`, `safety` — these will be
ignored » (deux blocs entiers **inertes**, dont `confirm_plan`) ; et `pattern_mapper`,
`code_review`, `ui_review` sont **absentes** → au défaut `true` sans que personne ne l'ait décidé.
Le lab pilote donc ses étages par omission.

**Lacune 6 — la taxonomie de checkpoint GSD est ignorée (SÛRETÉ, priorité de la phase).**
GSD 1.9 porte un contrat de checkpoint **à deux couches** (type × `gate`) que le module ne
connaît pas : `grep -rn "checkpoint"` sur `plugin/dev-orchestrator/` → 4 occurrences, **toutes** au
sens du mode superviser VibeFlow, **aucune** au sens GSD. `references/checkpoints.md` décrit
pourtant exactement notre configuration comme le mode de défaillance à éviter : « *An orchestrator
that dispatches on checkpoint **type** alone would auto-approve the very checkpoint the executor
just refused to auto-approve, nullifying that refusal one layer up.* » Trois faits :

- **(a) `gate="blocking-human"` n'est jamais honoré.** `gsd-executor.md:330-332` : en auto-mode
  l'exécuteur auto-approuve `human-verify` et auto-sélectionne `decision` — **sauf**
  `gate="blocking-human"` (et sauf les checkpoints de légitimité de paquet), qu'il **refuse** de
  trancher et escalade exprès via `checkpoint_return_format`. `vf-dev-manager.md:157` pilote sur son
  `statut` maison (`passed|gaps_found|human_needed|blocked`) : **aucun mapping** n'existe entre le
  gate amont et `human_needed`, donc un manager en mode autonome peut « continuer » sur le seul
  checkpoint que le moteur a explicitement refusé d'auto-approuver. Même chose pour les
  **préconditions non satisfaites** (`gsd-executor.md:150`), « NEVER auto-approved, even under
  `AUTO_CFG=true` ».

- **(b) l'auto-mode auto-tranche les décisions.** Règle 5 de `checkpoints.md` : dès que
  `workflow._auto_chain_active` **ou** `workflow.auto_advance` est vrai, `human-verify`
  auto-approuve et `decision` **auto-sélectionne la première option**. Aucun agent du module ne lit
  ni ne remet ce flag à zéro — alors que `plan-phase.md:1560` sait l'écrire (cf. Lacune 3). Le
  couplage des deux lacunes est le vrai danger : un `--auto` mal placé ne fait pas que dérouler,
  il **tranche des décisions à notre place**.

- **(c) un worker interrompu par checkpoint ne reprend pas.** `execute-plan.md:321` :
  « *You will NOT be resumed* » — l'orchestrateur doit spawner une **continuation** portant l'état
  des tâches déjà faites, sur un contrat en 4 blocs (Completed Tasks / Current Task / Checkpoint
  Details / Awaiting). Le bloc typé ADR-053 ne porte **aucun** de ces champs, et `dag.sh reopen` ne
  modélise pas un plan **partiellement** exécuté : au reopen, `vf-coder` repart de l'étape, pas de
  la tâche. Risque : travail refait, ou commits orphelins d'un premier passage.

**Lacune 7 — les budgets de boucle se superposent en silence.** `workflow.node_repair` est **ON par
défaut** (budget 2) : sur échec de vérification, GSD tente seul RETRY / DECOMPOSE / PRUNE avant
d'escalader (`execute-plan.md:330-345`). Les « 3 tours max » de la boucle de revue
(`mission-flow.md` §Pattern E) et celle de comblement s'empilent donc **par-dessus** deux
réparations déjà consommées à l'intérieur de chaque tour — budget réel ≈ 3 × (1+2), jamais écrit,
jamais consigné au rapport. Un blocage « après 3 tours » a en réalité coûté jusqu'à neuf tentatives.

**Requirements**: GSDC-01, GSDC-02, GSDC-03, GSDC-04, GSDC-05, GSDC-06, GSDC-07, GSDC-08, GSDC-09,
GSDC-10 *(créés au plan du 2026-08-01, préfixe `GSDC` — cf. `.planning/REQUIREMENTS.md`)*
**Depends on:** Phase 20 — **merge requis avant exécution** (périmètre à fichiers partagés :
`vf-coder.md`, `vf-dev-manager.md`, `mission-contracts.md`, `intent-routing.md`).
**Recoupements à instruire, pas des dépendances d'ordre** : Phase 21 (changement 3 — arbitrage des
étages de revue) et Phase 22 (doctrine de flags documentaires). L'ordre est libre ; l'arbitrage
écrit par la première exécutée **fait autorité**, la suivante s'y réfère sans le dupliquer.
**Plans:** 8/8 plans executed
quasi-séquentielle ; seuls 23-01 et 23-02 sont parallélisables en vague 1)

Plans:

- [x] 23-01-PLAN.md — **Zone 1, SÛRETÉ, priorité imposée** : champ `gate` et mapping unique vers
  `human_needed` de bout en bout, reset de `workflow._auto_chain_active` au démarrage de mission,
  minimum de reprise, halt de nœud, réponse humaine portée par le manager. Blocs T24/T25/T26,
  discriminance prouvée par mutation. (GSDC-01, GSDC-02)

- [x] 23-02-PLAN.md — **Zone 5, parallèle de 23-01** : `check-gsd-config.sh` (advisory, exit 0/3/64,
  clés connues lues depuis `gsd-core`) + suite dédiée + câblage `SessionStart` ; blocs `gates` et
  `safety` supprimés du `config.json` du lab et 5 toggles écrits à une valeur décidée. (GSDC-07)

- [x] 23-03-PLAN.md — **Zone 2** : `GSD-PIPELINE.md` §9 doctrine de flags de cycle en **allowlist
  stricte** (clause de fermeture par défaut, gradation `--research` factuelle, renvoi croisé vers
  `docs-flow.md`), ligne `gsd-ship` du cycle canonique corrigée. Bloc T27. (GSDC-03)

- [x] 23-04-PLAN.md — **Zone 2** : générateur `build-gsd-capabilities-index.sh` →
  `references/gsd-capabilities-index.md` sur les **12** points de hook (liste découverte depuis le
  registre amont), renvoi depuis la doctrine, régénération à l'install. Bloc T28. (GSDC-04)

- [x] 23-05-PLAN.md — **Zone 3, le trou le plus grave** : voie dégradée supprimée du corps de
  prompt de `vf-coder`, `gsd-planner`/`gsd-executor` retirés des lignes `tools:` des **deux**
  agents (arbitrage du Finding 1), doctrine de voie unique et continuation par voie skill. Bloc
  T29. (GSDC-05)

- [x] 23-06-PLAN.md — **Zone 4** : verdicts de hooks au bloc typé (`pass|fail|absent`), ADR-061
  étendue d'un **troisième objet revu** sur les mêmes 3 axes (hook vs `revue-N`, hook vs
  `vf-auditer` avec le delta `CONCERNS.md`). Bloc T30. (GSDC-06)

- [x] 23-07-PLAN.md — **Zones 6 et 7** : budget de tours **partagé par étape**, halt `blocked` +
  décompte complet avec l'invisibilité `node_repair` nommée, table des moments déclencheurs des 4
  briques dormantes, mandat de debug par le skill. Blocs T31/T32. (GSDC-08, GSDC-09)

- [x] 23-08-PLAN.md — **Clôture** : bump **minor** du module (v2.10.0 → v2.11.0), triade +
  CHANGELOG, compteur de suites des 2 README racine 46 → 47, `check-version-sync.sh` ✓, ledger
  d'exigences, rejeu des 11 gates de sortie. Release racine **hors périmètre**, réservée à
  validation humaine. (GSDC-10)

### Phase 24: Activation et mesure du moteur GSD — capacités dormantes et faits de runtime

> **Origine** — second temps de l'audit du 2026-07-31 (le premier a produit la Phase 23), sur
> demande de Samuel d'aller au bout des gaps VibeFlow ↔ GSD. Établi **sur pièce** contre
> `@opengsd/gsd-core@1.9.0` installé : inventaire des **44 capabilities** et des **12 points de
> hook** (`bin/lib/capability-registry.cjs`, exports `capabilities` / `byLoopPoint` /
> `capabilityClusters`), du **descripteur d'hôte `claude`**, de `bin/lib/init.cjs`
> (`buildAgentSkillsBlock`), de `bin/lib/host-integration.cjs` (`shouldFlattenDispatch`) et des
> hooks réellement posés dans `~/.claude/settings.json`.

**Goal**: Cesser de payer l'installation d'un moteur sans en prendre les bénéfices — **activer**
les capacités GSD déjà installées mais dormantes, **mesurer** les faits de runtime que VibeFlow
présume, et **fermer** les routes qui mènent à un geste inerte. La Phase 23 rend le couplage
explicite ; celle-ci rend le moteur **effectivement employé**.

**Le point de départ n'est ni une panne ni un couplage flou — c'est de la valeur laissée sur la
table.** Chaque item ci-dessous est une brique du moteur **présente sur le disque**, dont le
toggle est à `false` ou dont le canal est vide, et que VibeFlow soit ignore, soit ré-implémente à
la main.

**Ordre imposé — le lot MESURE d'abord.** Le constat M2 portait sur le cœur du gain de la Phase 20 :
il devait être connu **avant** d'activer quoi que ce soit d'autre. **M2 est mesuré et rendu**
(2026-07-31, verdict ci-dessous : les acquis tiennent, le gap se déplace) ; M1 et M3 restent des
constats de lecture à instruire au plan. Aucun lot d'activation ne démarre avant que les trois
soient traités.

#### Lot MESURE — trois faits présumés (M2 mesuré le 2026-07-31, M1 et M3 à instruire)

Le descripteur officiel du runtime `claude` dans GSD 1.9 (capability `claude`, clé
`hostIntegration.dispatch`) dit :

```
{ namedDispatch: true, nested: true, maxDepth: 5,
  background: true, backgroundDispatch: false,
  subagentToolkit: "full", isolation: "harness-worktree" }
```

**M1 — la profondeur de dispatch disponible est 5, VibeFlow en consomme 3.** `nested: true`,
`maxDepth: 5`, `subagentToolkit: "full"` : la chaîne `vf-dev-manager → vf-coder → agent gsd-*`
tient, avec **deux niveaux de marge**. Ce fait **clôt** la question du nesting posée à l'ouverture
de l'audit et n'est écrit nulle part dans le module — ni la limite, ni la marge, ni ce qu'elle
autorise (un worker pourrait légitimement dispatcher un sous-worker).

**M2 — ✅ MESURÉ le 2026-07-31 : le moteur s'auto-bride, le runtime sait paralléliser.**
Preuve complète et protocole : `.planning/missions/2026-07-31-mesure-m2-dispatch-parallele.md`.
`shouldFlattenDispatch()` (`bin/lib/host-integration.cjs:464`) renvoie `true` dès que
`background && backgroundDispatch` n'est pas vrai — donc **true pour Claude Code** : GSD
**aplatit** ses dispatches, et la capability `claude-orchestration` (1.9.0, **default-off**, BETA)
existe pour « *restoring the wave parallelism the #853 backgrounded-agent nesting limitation forces
inline on Claude Code* ». Deux acquis VibeFlow reposaient sur la capacité inverse — le **fan-out de
la frontière `ready`** (`vf-dev-manager.md:90-96`) et la **recherche doc en tâche de fond**
(`vf-dev-manager.md:180-184`, ADR-045). **Mesure par sondes horodatées (busy-loop 20 s, PID
distincts, 12 cœurs)** :

| Configuration | Recouvrement | Verdict |
|---|---|---|
| Contrôle — fenêtre principale → 2 agents en un message | 18 259 / 20 000 ms (**91 %**) | parallèle |
| **Sous-agent** → 2 agents en un message (le cas `vf-dev-manager`) | 18 460 / 20 000 ms (**92 %**) | **parallèle** |
| **Sous-agent** → 1 enfant en tâche de fond, puis travail propre | parent démarré 1018 ms **avant** l'enfant, fini 18 s avant lui | **non bloquant** |

**Les deux acquis tiennent** — statistiquement indiscernables du contrôle. `backgroundDispatch:
false` est **fail-closed par conception, pas descriptif** de la capacité réelle du runtime. **Le gap
se déplace donc, il ne disparaît pas** : `gsd-execute-phase` sérialise ses vagues **par décision du
moteur** alors que le runtime sait les paralléliser → le parallélisme **intra-étape** (vagues de
plans d'une même phase) est perdu, et seul subsiste le parallélisme **inter-nœuds** porté par
`vf-dev-manager`. Conséquence doctrinale à écrire : sur ce runtime, notre couche d'orchestration ne
duplique pas celle de GSD, **elle est la seule qui parallélise réellement**.

**Voies retenues (arbitrées par Samuel le 2026-07-31), deux sur trois :**

1. **Acter et documenter** — écrire en doctrine que sur ce runtime le parallélisme **inter-nœuds**
   porté par `vf-dev-manager` est le seul effectif, et que le parallélisme **intra-étape** des vagues
   GSD est perdu par décision du moteur. Gratuit, immédiat, et consolide l'architecture existante au
   lieu de la remettre en cause.

2. **Signaler le descripteur en amont** — remonter à `@opengsd/gsd-core`, **mesure horodatée à
   l'appui**, que `backgroundDispatch: false` est *fail-closed* mais non descriptif du runtime
   Claude Code. Bénéfice collectif : débloquerait le parallélisme intra-étape pour tous les labs.

3. ~~Activer `claude_orchestration.enabled`~~ — **ÉCARTÉ pour l'instant** : placer un backend
   **BETA** sur le chemin critique d'exécution n'est pas justifié quand notre propre parallélisme
   fonctionne (mesuré). À reconsidérer seulement si le parallélisme intra-étape devient un besoin
   démontré, ou si la voie 2 échoue.

Reste non mesuré : la profondeur 2 → 3 (`vf-coder → gsd-executor`), couverte en **déclaration** par
M1 (`maxDepth: 5`), pas par l'expérience.

**M3 — `effort:` est supporté, validé, et déclaré par aucun agent.** Le harness l'expose
(`agentFrontmatterExtensions: ["effort"]`), notre propre gate le **valide déjà**
(`check-agents.sh:514`, `low|medium|high|xhigh|max`), les skills GSD l'emploient (`effort: max` sur
`gsd-plan-phase`) — et `grep -rln "^effort:" plugin/*/agents/*.md` → **aucun résultat**. Managers,
juges et workers tournent tous à l'effort par défaut. À trancher par rôle (pilotage et jugement
haut, exécution mécanique bas), pas uniformément.

#### Lot ACTIVATION — capacités installées, dormantes

**A1 — broken-windows : le ledger est au bon format, le gate est éteint.** `.planning/WINDOWS.md`
porte `open_count: 2` — **exactement** le frontmatter que le gate `ship:pre` évalue
(`predicate: artifact-frontmatter-equals`, `artifact: WINDOWS.md`, `field: open_count`,
`equals: 0`). Mais `workflow.windows_enforce` est **absent** du `config.json` → défaut **`false`**,
et la description amont est sans ambiguïté : « *When false (default), windows are still tracked
(the executor and verifier still populate WINDOWS.md) but ship does not block — teams can adopt
tracking before enforcement* » (#1950). Nous sommes exactement dans cet état intermédiaire : le
tracking tourne, l'enforcement non — sauf que nous tenons le ledger **à la main** (commits
`chore(20): WINDOWS #2 résolu`) sans savoir que le moteur l'alimente et saurait bloquer le ship.
**Le plus actionnable de la phase** : une clé de config et une décision.

**A2 — `agent_skills` : le canal officiel de transmission de doctrine est vide.**
`buildAgentSkillsBlock` (`bin/lib/init.cjs:1731`) injecte des skills dans le prompt des agents
GSD via **17 slots** (`AGENT_SKILLS_PLANNER`, `EXECUTOR`, `REVIEWER`, `VERIFIER`, `AUDITOR`,
`DEBUGGER`, `MAPPER`, `CHECKER`, `ANALYZER`, `ADVISOR`, `ROADMAPPER`, `SYNTHESIZER`, `FIXER`,
`RESEARCHER`, `UI*`), consommés par **19 workflows**, et accepte les skills de **plugin
namespacés** (`global:<plugin>:<skill>`). Le `config.json` du lab : `agent_skills: {}`. Conséquence
structurante : la doctrine de dev du lab (Phases 7-8 — SOLID/DRY/KISS/YAGNI/Clean Archi/TDD)
**n'atteint jamais** `gsd-planner` ni `gsd-executor`, c'est-à-dire les agents qui écrivent
réellement le plan et le code. Le « digest de mission » (`mission-contracts.md`) ne va qu'aux
workers `vf-*` et s'arrête à la frontière du moteur. C'est le gap avec le plus fort levier
qualité de tout l'audit.

**A3 — `workflow.tdd_mode = false` alors que la doctrine TDD est écrite.** `plan-phase.md:80` :
quand la capability `tdd` est active, le planner applique `type: tdd` aux tâches éligibles via
`references/tdd.md`, et un hook `execute:post` porte un review-checkpoint TDD. Le lab a une
doctrine TDD (Phase 7) et un skill `tdd` — et le toggle qui la câblerait au moteur est à `false`.

**A4 — les profils de contexte (`contexts/dev|review|research.md`) ne sont pas employés.** Chargés
par la clé `context:` du `config.json` (**absente**), ils fixent style de sortie, focus et
**verbosité** par mode. Or `mission-flow.md` §Pattern C légifère précisément là-dessus (« la prose
libre est du volume mort ») : nous ré-implémentons en doctrine ce que le moteur porte en config.
À arbitrer : adopter, ou acter que notre contrat typé est plus strict et pourquoi.

**A5 — deux hooks machine opt-in, non branchés.** `hooks.workflow_guard` (garde d'enchaînement de
workflow, `gsd-workflow-guard.js:70-79`) et `hooks.community` (Conventional Commits bloquants,
`gsd-validate-commit.sh`) sont **installés et inertes**. Le lab impose déjà des commits
conventionnels en français **par consigne** — un gate existe.

**A6 — `workflow.inline_plan_threshold` (défaut 2) est un levier de coût inconnu.** Un plan de
≤ 2 tâches s'exécute **inline** au lieu de spawner un sous-agent : « *avoids ~14K token subagent
spawn overhead and preserves prompt cache* » (`execute-plan.md:100`). À confronter à la doctrine
de délégation systématique du module.

**A7 — `intel` (`intel.enabled: false`, agent `gsd-intel-updater`, cible `.planning/intel/`).**
Jamais instruit, alors que `.planning/codebase/` (via `gsd-map-codebase`) est pleinement employé et
lu par `vf-dev-manager` au démarrage. Frontière à écrire : que ferait `intel` que `codebase/` ne
fait pas — ou acter le refus.

**A8 — la carte de routage envoie sur des gestes inertes.** `intent-routing.md` route « le graphe
de connaissance » → `gsd-graphify` et « profile ma façon de bosser » → `gsd-profile-user`, or
`graphify.enabled` et `profile-pipeline.enabled` valent **`false`**. Le test d'exhaustivité du
module (`test-dev-orchestrator.sh`) vérifie que **le skill est routé**, jamais que **la capability
est active** : une couverture verte peut donc masquer un geste mort. Deux issues : activer, ou
marquer l'entrée comme conditionnelle — et dans les deux cas, **étendre le test à l'activation**
(sinon le même trou se rouvre au prochain skill ajouté).

**A9 — les workstreams : chantiers parallèles en `.planning/`, capacité native à 18 % de
couverture.** Entré au lot le **2026-08-02**, à la suite de la **PR #27** (partition de `.planning`
en workstreams dev/gouvernance, proposée par Willy, **revue en `CHANGES_REQUESTED`**). Le besoin est
réel et démontré : `ROADMAP.md` et `STATE.md` sont **mono-position** et ne savent pas décrire deux
chantiers simultanés — chaque avancée de l'un réécrit la position de l'autre.

GSD porte la réponse nativement (`.planning/workstreams/<nom>/`, flag `--ws`, `bin/lib/workstream.cjs`,
`gsd-tools workstream list` → `"mode": "workstream"`). **Mais la capacité est à moitié câblée en
amont** : sur les **91 workflows** de gsd-core **1.9.1**, **16 bruts / 15 réels** la connaissent au
critère le plus large (`K3` : le mot `workstream`, l'option `--ws` ou la variable `GSD_WS` — un faux
positif nommé, `reapply-patches.md:220`, qui ne cite `${GSD_WS}` que comme exemple de dérive), et
**45 codent en dur** `.planning/ROADMAP.md` / `STATE.md` / `phases/` (`add-phase`, `verify-phase`,
`next`, `pr-branch`, `execute-plan`, `extract-learnings`, `complete-milestone`…). Couverture :
**17,6 % bruts / 16,5 % réels** au critère K3, **7,7 %** au critère K2 (« le workflow sait-il
résoudre un scope »). Adopter en l'état, c'est faire tourner le lab contre sa propre chaîne
d'outils — le cas que visait l'**Iron Law 2**.

> **Faits corrigés le 2026-08-04 (nœud 24-13), les seuls de ce paragraphe.** Trois périmés y
> figuraient et sont rectifiés ci-dessus : le **« 37 en dur »**, jamais réconcilié avec la mesure
> finale (**45**) ; la version du moteur (**1.9.0 → 1.9.1**) ; et le **~18 %** laissé sans critère,
> désormais nommé (K3) et daté. L'**Iron Law 2** figurait ici dans sa formulation **pré-révision**
> avec une ancre périmée (`conductor/AGENT.md:114`, qui est aujourd'hui l'**Iron Law 1**) : elle a
> été révisée par **ADR-069** en « *Router, jamais forker — une capacité amont partiellement
> couverte se câble en écrivant ses limites, elle ne se réimplémente pas* », et se lit désormais en
> `plugin/conductor/AGENT.md:115` avec sa trace de révision juste en dessous. Le reste de ce bloc
> n'est PAS recalé : il appartient au nœud de documentation de fin de mission.

Faits établis en bac à sable sur la PR #27 (worktree `c0908fd`, gsd-core 1.9.0), qui bornent
l'arbitrage :

- **Notre propre outillage est aveugle.** `check-dev-bootstrap.sh:28` cherche `.planning/ROADMAP.md`
  à la racine → le `SessionStart` repasse de `[gsd-engine] phase 26 en cours` à `[bootstrap] feuille
  de route absente`. `check-state-integrity.sh` (câblé `ci.yml:117` en Phase 21) sort **exit 2**.
  `vf-dev-manager.md` lit les chemins racine en dur (7 occurrences) ; sur tout `plugin/`, **3
  fichiers** mentionnent « workstream », tous des tables de routage.

- **`/gsd-pr-branch` s'inverse.** Ses regex sont ancrées (`pr-branch.md:232-234`) :
  `.planning/workstreams/dev/STATE.md` ne matche plus `STRUCTURAL` → reclassé **transient →
  EXCLUDED**. Les commits de feuille de route disparaissent silencieusement des branches de PR.

- **Le pointeur de workstream ne vit pas où on croit.** Dès qu'une clé de session résout, ce n'est
  pas `.planning/active-workstream` mais
  `os.tmpdir()/gsd-workstream-sessions/<sha1(chemin absolu du .planning)>/<clé>`
  (`active-workstream-store.cjs:95-111`) : effacé au reboot, **et indexé sur le chemin absolu, donc
  distinct par worktree, jamais hérité**. Sur cette machine `CLAUDE_SESSION_ID` n'est pas défini —
  la clé effective est `CLAUDE_CODE_SSE_PORT`, un port recyclable par l'OS.

- **Migration à conflit nul, donc à divergence invisible.** `git merge-tree` d'une branche de travail
  post-partition → **exit 0** avec le dossier de phase en cours **orphelin à la racine** pendant que
  le `STATE.md` du workstream le déclare courant. Git ne signale rien.

**Le recouvrement à instruire est avec ADR-064, pas avec le moteur.** Le quick `260801-17w`
(2026-08-01) a déjà tranché la concurrence multi-session par l'**isolation physique** — « un
écrivain = un worktree », `check-branch-claim.sh` au `SessionStart`, claim de branche élargi —
d'après `shanraisshan/claude-code-best-practice`. Les workstreams sont une **seconde réponse au même
problème, conventionnelle** celle-là, et les deux se composent mal : le pointeur étant indexé sur le
chemin du `.planning`, **chaque worktree ouvre sans workstream résolu**, et aucun agent `vf-*` ne
sait passer `--ws`. Or M2 (lot MESURE) a établi que le parallélisme **inter-nœuds** de
`vf-dev-manager` est le **seul effectif** sur ce runtime : le seul étage de parallélisme qui
fonctionne est aussi celui que la partition fragilise le plus.

**À trancher au plan — la question est ouverte, l'adoption n'est pas acquise :** (a) **adopter** les
workstreams et payer la mise à niveau de notre couche (`check-dev-bootstrap.sh`,
`check-state-integrity.sh`, `planning-context.sh` workstream-aware, `--ws` câblé dans les agents
`vf-*`, gate sur le pointeur, CI étendue) ; (b) **refuser** et traiter les chantiers parallèles par
jalons distincts dans une ROADMAP partagée, l'isolation restant physique par ADR-064 ; (c) **borner**
— workstreams réservés à un usage où les 42 workflows aveugles (critère K2) ne sont jamais sollicités, ce qui
demande de dire lesquels. Dans les cas (a) et (c), la **remontée upstream** des workflows aveugles
est le préalable, au même titre que la RFC de la Phase 18 et la voie 2 de M2. Condition commune aux
trois : **aucune partition tant qu'une phase est en vol** (cf. divergence invisible ci-dessus).

> ### ⚠️ Lettrage — deux jeux de lettres ont coexisté sur A9, un seul fait foi
>
> Les lettres `(a) (b) (c)` ci-dessus sont celles du **cadrage de ce ROADMAP**. L'arbitrage
> `24-ARBITRAGES.md` § Zone 5 en a posé **d'autres**, à quatre branches, et c'est **le lettrage de
> l'arbitrage qui est normatif** — c'est lui que citent `ADR-069` et toute décision postérieure.
> Les lettres du ROADMAP sont conservées pour la trace, **elles ne sont plus une référence
> citable**.
>
> | ROADMAP (historique, non citable) | Arbitrage § Zone 5 / ADR-069 (**normatif**) |
> |---|---|
> | **(a)** adopter | **C** — adopter et payer la mise à niveau de notre couche |
> | **(b)** refuser | **A** — refuser sec · **D** — refuser + remontée amont (l'arbitrage a scindé le refus en deux) |
> | **(c)** borner | **B** — borner à un usage restreint, sous liste de workflows interdits |
>
> **Pourquoi cet encadré existe.** La confusion a effectivement eu lieu : la ligne de décision du
> tableau de clôture a été écrite « voie (c) bornée » en pensant à l'**option C de l'arbitrage**
> (= adopter), glosée avec la lettre `(c)` du ROADMAP (= borner) — soit l'exact contraire de la
> décision de Samuel. Corrigé le 2026-08-05. **Ne jamais désigner une voie A9 par une lettre nue :
> nommer le jeu (« option C de l'arbitrage ») et le geste (« adoption »).**

> **Chiffre recalé le 2026-08-04.** Ce paragraphe et le précédent citaient « **37** workflows
> aveugles ». Ce nombre n'a jamais été réconcilié avec une mesure : les aveugles sont **42** au
> critère **K2** (43 au K1, 35 au K3), sur **45** qui codent des chemins en dur. Le critère fait
> partie du chiffre — voir le tableau de clôture en fin de section, et ADR-069 pour la commande.

#### État à la clôture — ce que la phase a effectivement tranché (2026-08-04)

> **Comment lire tout ce qui précède.** Les lots MESURE et ACTIVATION ci-dessus décrivent l'état
> **au cadrage** (2026-07-31 / 2026-08-02). Ils sont conservés tels quels : ils portent le
> raisonnement qui a produit les plans, et les réécrire effacerait la trace de ce qui était su
> quand la phase a été ouverte. Le tableau ci-dessous dit ce qu'ils sont **devenus**, mesuré sur
> l'arbre le 2026-08-04 au soir. **En cas de contradiction, c'est ce tableau qui fait foi.**

| Constat du cadrage | État mesuré à la clôture | Où |
|---|---|---|
| **M1** — profondeur 5 disponible, 3 consommée, écrite nulle part | **écrite** dans les agents | 24-01 |
| **M2** — ✅ mesuré le 2026-07-31 | **voie 1 livrée** — acté en doctrine (`team-kernel.md:55-89`) ; **voie 2 non livrée** — `backgroundDispatch` compte 24 occurrences sur 872 fichiers suivis, **0 dans `.planning/upstream/`** (1 seul fichier, sans rapport avec M2) : aucune remontée amont du descripteur n'a été rédigée ni déposée | 24-01, 24-10 |
| **M3** — « `effort:` déclaré par **aucun** agent » | **PÉRIMÉ** — **31 agents sur 31** le déclarent (25 en `agents/<nom>.md` **+ 6 en `AGENT.md`** de module : le second balayage est celui que le cadrage oubliait) | 24-01 |
| **A1** — `workflow.windows_enforce` absent → défaut `false` | **PÉRIMÉ** — présent et à **`true`** (dégel, ADR-066) | 24-02 |
| **A2** — `agent_skills: {}` | **PÉRIMÉ** — slot **PLANNER ouvert** (2 skills) ; `gsd-executor` délibérément non câblé | 24-03 |
| **A3** — `tdd_mode` à `false` | **inchangé, par décision écrite** — clé non posée | 24-03 |
| **A4** — profils de contexte non employés | **refusés**, par décision écrite | 24-07, ADR-068 |
| **A5** — deux hooks opt-in inertes | `hooks.workflow_guard` **à `true`** ; `hooks.community` **refusé** | 24-02 |
| **A6** — `inline_plan_threshold`, levier inconnu | **chiffré**, laissé au défaut | 24-07 |
| **A7** — `intel` jamais instruit | **PÉRIMÉ** — `intel.enabled: true` | 24-06 |
| **A8** — routes vers des gestes inertes, test aveugle à l'activation | `graphify` et `profile-pipeline` **refusés**, entrées de doc **marquées conditionnelles**, et le trou **fermé par un gate** (`check-capability-activation.sh`) câblé au job `gates` de la CI | 24-06, 24-11 |
| **A9** — workstreams : « notre propre outillage est aveugle » | **PÉRIMÉ sur les deux volets.** Outillage : les quatre gates sont workstream-aware et exercés en CI sur un arbre réellement partitionné. **Adoption : ACQUISE** depuis `ADR-069` (2026-08-04) — voir la décision ci-dessous | 24-04, 24-05, 24-08, 24-09 |

**La décision A9, écrite : ADOPTION — *option C de l'arbitrage* (`24-ARBITRAGES.md` § Zone 5), soit
la *voie (a) du lettrage historique de ce ROADMAP* — avec ses quatre limites datées et la condition
dure « aucune partition tant qu'une phase est en vol ».** L'usage restreint sous liste d'exclusions
(option **B** de l'arbitrage = voie `(c)` du ROADMAP) est **explicitement rejeté** par ADR-069, tout
comme le refus (options **A** et **D**). Cf. l'encadré « Lettrage » plus haut dans cette section.
`ADR-069` acte la révision de l'**Iron Law 2** (« *Router, jamais forker — une capacité amont
partiellement couverte se câble en écrivant ses limites, elle ne se réimplémente pas* ») et grave
la couverture **avec son critère et sa commande rejouable**, parce qu'un nombre sans critère est
précisément ce qui avait produit trois chiffres inconciliables. **Re-dérivé le 2026-08-04 au soir
par la commande d'ADR-069 elle-même**, identique au fichier près :

| Critère | Ce qu'il demande | Workflows | Couverture | En dur | Aveugles |
|---|---|---|---|---|---|
| K1 | le mot `workstream` seul | 5 | 5,5 % | 45 | 43 |
| **K2** | **`workstream` ou `--ws` — *résout un scope*** | **7** | **7,7 %** | **45** | **42** |
| K3 | K2 ou `GSD_WS` — toute forme de surface | 16 bruts / 15 réels | 17,6 % / 16,5 % | 45 | 35 |

Univers : **91 workflows** de `@opengsd/gsd-core` **1.9.1**, compteur d'**atteinte** inclus dans la
commande (`atteinte=91`) — une invocation antérieure avait rendu **4** en silence. Le **« 37 en
dur »** qui figurait dans ce document n'a jamais été réconcilié : la mesure est **45**, et les
**42** aveugles sont ceux du critère **K2**.

**Requirements**: GSDA-01 → GSDA-22 (créés au plan du 2026-08-04 — préfixe `GSDA`, « GSD
Activation », distinct du `GSDC` de la Phase 23 ; détail et mapping aux plans dans
`.planning/REQUIREMENTS.md`)
**Depends on:** Phase 23 — dépendance **doctrinale**, pas de fichiers : la 23 écrit la table des
capabilities et la voie unique ; la 24 décide quoi activer dedans. Activer avant de savoir qui
couvre quoi reviendrait à empiler des étages sur un couplage encore implicite. Le **lot MESURE**
est en revanche exécutable **sans attendre** la 23 (lecture et instrumentation seules, aucun
fichier de doctrine touché) — et M2 gagne à être connu tôt.
**Plans:** 12/12 plans executed

Plans:

- [x] 24-01-PLAN.md — **Lot MESURE, M1 + M3** : profondeur de dispatch et parallélisme gravés dans
  les agents ; `effort:` propagé sur **31 agents sur 31** (barème par rôle) et exigé par
  `check-agents.sh`. `GSDA-20/21/22`.

- [x] 24-02-PLAN.md — **Zone 2** : `workflow.windows_enforce` et `hooks.workflow_guard` **activés**
  (dégel, **ADR-066** — un prérequis de version insatisfiable ne gate pas) ; `hooks.community`
  **refusé**. `GSDA-01/04/05/06`.

- [x] 24-03-PLAN.md — **Zone 1** : slot `agent_skills` **PLANNER** ouvert (la doctrine du lab
  atteint enfin `gsd-planner`) ; `tdd_mode` non posé, par décision écrite. `GSDA-02/03`.

- [x] 24-04-PLAN.md — **Zone 4** : trois gates rendus **workstream-aware**, sur une politique de
  nom **partagée** et conforme au moteur amont. `GSDA-13/14`.

- [x] 24-05-PLAN.md — **Zone 4** : `check-workstream-pointer.sh` — l'auto-nettoyage silencieux du
  moteur rendu **audible**, câblé au `SessionStart`. `GSDA-16`.

- [x] 24-06-PLAN.md — **Zone 3** : `intel` **activé** (la promesse publiée par notre doc devient
  tenue) ; `graphify` et `profile-pipeline` **refusés**, et les refus **indexés**. `GSDA-07/08`.

- [x] 24-07-PLAN.md — **Zones A4/A6** : profils de contexte **refusés** (**ADR-068**), seuil inline
  **chiffré** et laissé au défaut. `GSDA-10/11`.

- [x] 24-08-PLAN.md — **Zone 4** : les agents `vf-*` savent enfin dire au moteur **sur quel scope**
  ils travaillent. `GSDA-15`.

- [x] 24-09-PLAN.md — **Zone 4, CI** : les gates workstream exercés sur un arbre **réellement
  partitionné**, fixture prouvée **discriminante**, + non-régression sur la racine. `GSDA-17`.

- [x] 24-10-PLAN.md — **Zone 5** : **ADR-069** — Iron Law 2 révisée (« router, jamais forker »),
  couverture workstreams gravée **avec son critère et sa commande**, remontée amont déposée.
  `GSDA-12/18/19`.

- [x] 24-11-PLAN.md — **Zone 3, la cause** : `check-capability-activation.sh` — une entrée de doc
  ne peut plus promettre un geste inerte ; câblé au job `gates` de la CI. `GSDA-09/08/15/02`.

- [x] 24-12-PLAN.md — **Clôture** : **10 modules** bumpés (dont 2 mono-agents que le plan avait
  sous-recensés), compteur de suites des deux README recalé, `check-version-sync.sh` vert, et la
  **frontière de release non franchie** — 0 ligne d'écart depuis `main`.

> **Ce que cette checklist ne dit pas.** Douze plans exécutés ne valent pas phase close : le gate
> de sécurité reste **bloquant** (`24-SECURITY.md`, `threats_open: 1`) sur `T-24-02-01`, qui
> demande une **décision humaine** de re-disposition et non du code. Aucun tag, aucune release :
> la release racine est un geste humain gaté (`CLAUDE.md` § Discipline de release).

### Phase 26: Manuel utilisateur VibeFlow (manual/)

**Goal:** Créer un manuel utilisateur « vitrine » sous `manual/` à la racine — destiné aux humains
qui arrivent sur le repo, distinct des docs de gestion de projet (`docs/`, `.planning/`) et
volontairement hors du contexte des agents qui maintiennent VibeFlow. Arborescence thématique à
préfixes numériques (get started/install, philosophie, cycle de dev, équipe d'agents, sous le
capot…) qui descend progressivement dans la profondeur : pages courtes (un sujet = un fichier, on
divise plutôt qu'allonger), chaînées par navigation `← Précédent · ↑ Sommaire · Suivant →`, index
`manual/README.md` avec carte du manuel (graphiques mermaid) et tutos. Bilingue FR + EN (comme les
deux README). `README.md`/`README.fr.md` et `INSTALL.md` maigrissent et pointent vers le manuel au
lieu de dupliquer — le manuel devient la version guidée et pédagogique.

> **Amendement de mission (2026-08-01)** — `manual/` **reste local, hors git** (`.git/info/exclude`,
> aucune entrée `.gitignore`). Aucun fichier du manuel n'entre dans un commit. Le volet « les README
> maigrissent et pointent vers le manuel » est **SUSPENDU, pas abandonné** : pointer vers un dossier
> absent du dépôt casserait les liens des visiteurs. `README.md`, `README.fr.md`, `INSTALL.md`,
> `scripts/` et `.github/` sortent du périmètre d'écriture ; l'outillage vit sous `manual/.tools/`
> et n'entre pas en CI. Seuls `.planning/**` sont committés.
> Cadrage complet : `.planning/missions/2026-08-01-phase-26-manuel-utilisateur.md` (D-1 à D-13) et
> `.planning/phases/VFDO-26-manuel-utilisateur-vibeflow-manual/26-CONTEXT.md` (D-01 à D-14).

**Requirements**: aucun ID formel — `REQUIREMENTS.md` ne porte aucun `REQ-` pour cette phase (le
ledger s'arrête à ALTI-05 / Phase 14), même convention que les Phases 15 à 21. La traçabilité est
assurée par les **décisions D-01 à D-14** de `26-CONTEXT.md` et les **manques M-1 à M-12** de
`26-INVENTAIRE-MATIERE.md`, repris par le champ `must_haves` de chaque `26-0N-PLAN.md`.
**Depends on:** Phase 25
**Plans:** 9/9 plans executed

Plans:

- [x] 26-01-PLAN.md — Infrastructure : `toc.yml` (D-03), `manual/.tools/build-nav.sh` (nav générée), `manual/.tools/check-manual.sh` (gate à 7 contrôles, refus du verdict vide, D-13), `manual/README.md` bilingue (vague 1)
- [x] 26-02-PLAN.md — Priorité du mandat 1/2 : les deux README de langue (carte mermaid décorative + navigation réelle, D-06) et le thème `01-demarrer` complet FR+EN, 7 pages — comble M-1, M-6 (scope), M-12 (vague 2)
- [x] 26-03-PLAN.md — Priorité du mandat 2/2 : thème `02-concepts` complet FR+EN, 7 pages — comble M-2 (glossaire produit), M-3 (« lab » enfin défini), M-5 (VibeFlow ↔ GSD ↔ Superpowers) ; documente 9 principes sourcés du canon (D-09) (vague 3)
- [x] 26-04-PLAN.md — Thème `03-modules` FR+EN, 6 pages : catalogue et choix de modules **dérivés du disque**, zéro version en dur (D-11) — comble M-6 (modules) (vague 4)
- [x] 26-05-PLAN.md — Thème `04-cycle-de-dev` FR+EN, 6 pages : cadrer → planifier → exécuter → livrer, écrit du point de vue de l'humain (vague 5)
- [x] 26-06-PLAN.md — Thème `05-equipe-agents` FR+EN, 6 pages : missions longues, ce qu'on vous demande (M-8), branches et worktrees (ADR-059, ADR-064) (vague 6)
- [x] 26-07-PLAN.md — Thème `06-reference` FR+EN, 6 pages : commandes/skills/agents énumérés depuis le disque (D-11) — comble M-7 (dépannage après install) et M-11 (coût et modèles) (vague 7)
- [x] 26-08-PLAN.md — Thème `07-sous-le-capot` FR+EN, 6 pages : anatomie d'un lab installé (M-4), engine d'install, gates, 15 ADR à valeur utilisateur, pont vers `docs/` (vague 8)
- [x] 26-09-PLAN.md — Clôture : ROADMAP et STATE recalés sur le réel livré, **checkpoint humain bloquant** puis unique commit de la phase, par chemins explicites (D-14, one-way) (vague 9)

**Découpe différable.** Les vagues 4 à 8 (un thème chacune, bilingue) peuvent être différées sans
casser le manuel ni son gate : `toc.yml` ne référence à tout instant que des pages réellement
écrites dans les deux langues, donc un arrêt entre deux vagues laisse un manuel plus court et
cohérent, `check-manual.sh` au vert. La priorité du mandat est tenue dès la vague 3.

### Phase 27: Parallélisation d'exécution — granulaire, simple, sans collision d'écriture

> **Origine** — demande directe de Samuel le 2026-08-05, à la clôture de la Phase 24 : « parallélisation
> complète, simple et granulaire. Le but est de gagner du temps d'exécution sans que les agents se
> marchent dessus. » La recherche de cadrage (2026-08-05, scratchpad `parallel-research.md`) a
> **renversé la prémisse** sur laquelle la demande reposait — voir ci-dessous.

> **Spec** : `docs/superpowers/specs/2026-08-05-parallelisation-execution-design.md`
> **Recherche** : `.planning/research/2026-08-05-parallelisation-execution.md`

**Goal**: Prendre un gain de vitesse **déjà disponible et non pris**, et le rendre **sûr par
construction**. La Phase 24 avait conclu que le parallélisme intra-étape était *perdu* ; la
re-vérification montre qu'il est seulement **désactivé par défaut**. Dans le même temps, la
disjonction des périmètres — la seule chose qui empêche deux agents de s'écraser — est aujourd'hui
**déclarée mais jamais calculée**. La phase doit donc fermer l'écart dans les deux sens : activer ce
qui dort, et outiller ce qui n'est tenu que par le jugement.

#### La correction de prémisse — le parallélisme intra-étape n'est pas perdu, il est éteint

`plugin/conductor/references/team-kernel.md:64-65` affirme que le parallélisme intra-étape est
« **perdu** ». **C'est faux, et la doctrine livrée doit être corrigée.** Ce qui est vrai :
`shouldFlattenDispatch()` rend bien `true` sous Claude Code (re-vérifié le 2026-08-05) — mais le
chemin qui restaure le parallélisme **ne passe pas par cette fonction**. La capability
`claude_orchestration` s'appuie sur l'outil **Workflow**, et son gate n° 4 lit `nested && background`
(tous deux `true` ici), **jamais `backgroundDispatch`**. Le commentaire amont le dit mot pour mot :
*« sidestepping the backgroundDispatch:false limitation »* (`claude-orchestration.cjs:186-192`).

Le seul verrou réel est le **gate n° 5** : `agent_sdk_version_unknown`. Claude Code embarque son SDK
dans un binaire au lieu de l'exposer en paquet npm, donc le routeur ne trouve aucune version sur
disque. La variable `GSD_AGENT_SDK_VERSION` est le contournement documenté en amont
(`claude-orchestration-command-router.cjs:157`).

#### Le chiffre qui devrait décider la phase

Le partitionneur amont (`partitionStages`) a été appliqué aux **12 plans réels de la Phase 24** :

| Vague | Plans | Étages après partition | Paires en collision de fichier |
|---|---|---|---|
| 1 | 5 | 1 | **0** |
| 2 | 4 | 1 | **0** |
| 3 | 2 | 1 | **0** |
| 4 | 1 | 1 | 0 |

**12 exécutions sérielles → 4 étages, soit un plafond de 3,00×** — et **zéro collision de fichier sur
les quatre vagues**. Le planificateur produit déjà des vagues parfaitement disjointes : le
parallélisme est **sûr et gratuit aujourd'hui**. C'est un **plafond d'étages mesuré, pas un gain
d'horloge** — la distinction est à tenir dans toute la phase.

#### Le trou de granularité, mesuré

`dag.sh` déclare un champ `scope[]` par nœud mais **ne calcule jamais** la disjonction. Testé :
trois nœuds dont **deux déclarent le même fichier** → `ready: ["a","b","c"]`. **Les deux écrivains du
même fichier sortent en parallèle.** La sécurité du parallélisme inter-nœuds ne repose donc sur
aucune machine — seulement sur le jugement du manager, à chaque dispatch.

Piège de nommage à ne pas répéter : `check-overlaps.sh`, malgré son nom, traite du **routage entre
briques tierces** (ADR-057), pas des périmètres d'écriture.

#### Les workstreams ne sont pas l'outil — c'est mesuré

Samuel demandait de s'en inspirer. `grep -c "workstream" execute-phase.md` → **0** : le workflow qui
dispatche les agents **ne connaît pas le concept**. Les workstreams compartimentent le **planning**
(feuille de route, état), jamais l'**exécution**. Le mécanisme qui répond au besoin s'appelle
`isolation: worktree`.

> **Comptages re-dérivés, méthode incluse.** La divergence relevée le 2026-08-05 est close ; les
> deux chiffres d'ADR-069 tiennent, chacun sur son ensemble nommé.
>
> - `workstream` : **7/91 tient** (critère K2, `~/.claude/gsd-core/workflows/*.md` profondeur 1,
>   non récursif). Le 6 obtenu par la recherche du 2026-08-05 venait d'un motif récursif K1
>   différent (`--ws ` espace littéral, qui ne matchait aucun fichier) — les deux mesures étaient
>   justes sur des ensembles différents, pas contradictoires.
> - `.planning/` en dur : **45 tient** (motif étroit `.planning/(ROADMAP.md|STATE.md|phases)`, les 3
>   seuls artefacts que la partition déplace, écrit à
>   `plugin/dev-orchestrator/references/workstreams.md:101`). Réconciliation avec le 73 : **73 = 70 + 3**
>   — 70 fichiers `workflows/*.md` à la racine (profondeur 1) plus 3 fichiers imbriqués sous
>   `help/modes/`, atteints uniquement par le parcours récursif. Sur ces 70, le motif large (toute
>   mention de `.planning/` en récursif) ajoute **25** chemins racine que le motif étroit ne compte
>   pas : **70 − 45 = 25**, et **45 ⊂ 70** (vérifié par `comm -23` vide). Corpus :
>   `$HOME/.claude/gsd-core/workflows/`, moteur **gsd-core 1.9.1** — profondeur 1 = 91 fichiers, en
>   récursif = 115 (mêmes bornes que le critère K2 ci-dessus) ; mesure non épinglable à un commit de
>   ce dépôt, voir la limite actée juste en dessous.
> - ADR-069 n'a besoin d'aucune correction — ses deux chiffres se re-dérivent au fichier près.
> - **Limite à écrire, pas taire** : le corpus (`~/.claude/gsd-core/`) vit hors dépôt, la mesure
>   n'est **pas épinglable à un commit** de ce dépôt — la seule ancre valide est
>   `~/.claude/gsd-core/VERSION = 1.9.1`. Toute citation future de ces deux chiffres doit porter
>   profondeur + motif + version du moteur, pas juste le nombre.

#### Les trois options, et le chemin

| | Option | Coût | Gain | Nature |
|---|---|---|---|---|
| **1** | **`isolation: worktree` en frontmatter d'agent** | frontmatters + `.gitignore` (`.claude/worktrees/` non couvert) + `.worktreeinclude` (absent) | **aucun gain de vitesse** | **prérequis de sécurité** — `check-agents.sh` liste déjà `isolation` dans ses `KNOWN` et n'admet que `worktree`, mais **0 agent sur 25** le déclare |
| **2** | **Activer `claude_orchestration`** | **zéro ligne de logique**, repli fail-closed intégral | **1,8–2,5× d'horloge estimé** (dit comme estimé) | active une capacité amont déjà écrite |
| **3** | **Porter le partitionneur dans `dag.sh`** | réimplémentation locale | — | **à ne pas faire maintenant** : duplique l'amont, exactement ce que l'Iron Law 2 révisée (ADR-069) proscrit |

**Chemin proposé : 1 → spike de 2 → 2.** L'option 1 d'abord parce qu'elle ne fait rien gagner mais
rend le reste sûr ; le spike parce que l'option 2 change le mode de dispatch de toute exécution.

#### Les deux points qui appellent un arbitrage humain, pas une décision technique

**A — Le mur ADR-031.** Un workflow **n'accepte aucune entrée utilisateur en cours de run**, et ses
sous-agents tournent **toujours en `acceptEdits`** — éditions auto-approuvées quel que soit le mode
de session. Or ADR-031 (« jamais de fix sans validation humaine ») est un socle du lab, et le
team-kernel a déjà vu une mission gelée par un `AskUserQuestion` indisponible en dispatch sous-agent.
Le repli documenté (« un étage = un workflow ») existe mais doit être **re-prouvé sous Workflow**.

**B — `worktree.baseRef`.** Le défaut `"fresh"` branche depuis `main` et **ferait perdre le travail en
cours** d'une mission. `"head"` semble requis — mais c'est un réglage **global**, donc un choix qui
engage au-delà de cette phase.

#### Contraintes non négociables

- **Simple avant complet.** Samuel l'a posé en premier. Une solution qui demande de penser à trois
  choses avant chaque dispatch ne sera pas tenue, donc ne comptera pas.

- **Corriger la doctrine fausse** de `team-kernel.md:64-65` fait partie du périmètre — une doctrine
  livrée qui affirme « perdu » là où c'est « éteint » induit chaque lecteur en erreur.

- **Aucune régression de sécurité de la Phase 24** — le motif d'échappement par lien symbolique en
  était à son quatrième passage ; toute primitive de chemin passe par les primitives partagées de
  `workstream-policy.sh`, jamais par une réimplémentation locale.

- **Tout chiffre gravé porte sa méthode et se re-dérive au moment de l'écriture** — la Phase 24 a
  produit quatre décomptes justes portant sur le mauvais ensemble, et la divergence 45 → 73
  ci-dessus en est la cinquième occurrence.

- **La mesure du gain est un livrable, pas une promesse** : baseline d'horloge avant, mesure après,
  méthode écrite. Un plafond d'étages n'est pas un gain d'horloge.

**Requirements**: PAEX-01 → PAEX-11 (préfixe `PAEX` — « PArallélisation d'EXécution » — **proposé au
plan du 2026-08-05** ; aucun préfixe existant `DOCF`/`GSDC`/`GSDA` ne couvre la parallélisation
d'exécution. À inscrire au ledger `REQUIREMENTS.md` par le manager de mission, comme aux Phases
22/23/24 où les préfixes ont été créés au plan.)

**Plans**: 6 plans en 4 vagues
**Wave 1**

- [x] 27-01-PLAN.md — **TRACER** : `dag.sh ready` calcule la disjonction de périmètres en câblant `partitionStages()` amont (jamais réimplémentée, ADR-069), champ `stages` additif, repli prouvé par test, doctrine et limites dans `mission-flow.md` — livrable 3 (vague 1)
- [x] 27-02-PLAN.md — Doctrine corrigée : `team-kernel.md` dit « éteint par défaut » et nomme le chemin qui rallume ; le callout de comptages divergents du ROADMAP laisse place au résultat re-dérivé — livrables 1 + lift ROADMAP (vague 1)
- [x] 27-03-PLAN.md — `isolation: worktree` sur les 13 écrivains non-managers, `.worktreeinclude` posé, statut `.gitignore` tranché sur pièce, portée écrite (groupe B, `worktree.baseRef`, 4 hypothèses + sondes) — livrable 2 (vague 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 27-04-PLAN.md — Baseline d'horloge capturée **avant** toute activation, corpus étalon versionné et prouvé parallélisable, méthode écrite — livrable 5, moitié « avant » (vague 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 27-05-PLAN.md — Spike `claude_orchestration` : SDK établi par installation réelle, échelle de 7 gates, run Workflow réel, sous-expérience Décision A, décision écrite (activation ou refus motivé) — livrable 4, **checkpoint bloquant** (vague 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 27-06-PLAN.md — Mesure après activation sur le même corpus étalon, écart et limites écrits — ou non-mesurabilité motivée avec déclencheur de reprise — livrable 5, moitié « après », **checkpoint bloquant** (vague 4)

**Ordre non négociable, câblé deux fois.** La baseline (`27-04`) précède l'activation (`27-05`) par
`depends_on` **et** par une précondition vérifiée à l'exécution sur l'absence de la clé de capability :
une baseline prise après activation est détruite sans rattrapage.

---

### Phase 28: Preuve que ce qui est armé dans le plugin est armé chez l'utilisateur

> **Origine** — régression **#38**, livrée en v2.49.0, corrigée en v2.50.1 le 2026-08-10. Ouverte
> par Samuel dans la foulée du hotfix : *« corrige le trou structurel »*. La phase est **créée avec
> le diagnostic, sans cadrage ni plan** — une mise à jour de VibeFlow est prévue avant de la
> travailler, et ce qu'elle changera doit être re-mesuré au cadrage, jamais présumé ici.

**Goal**: Qu'une capacité **armée** dans le plugin ne puisse pas être livrée quand le réglage qui
la rend sûre n'est **posé par personne** chez l'utilisateur. Aujourd'hui rien ne relie les deux :
l'armement voyage avec le plugin, la précondition reste dans le poste de développement, et tous les
gates rendent vert.

**Requirements**: ARMD-01, ARMD-02, ARMD-03, ARMD-04, ARMD-05, ARMD-06, ARMD-07, ARMD-08, ARMD-09, ARMD-10
**Depends on:** Phase 27
**Plans:** 3 plans

#### Le fait qui ouvre la phase

La Phase 27 a armé `isolation: worktree` sur 13 agents. Sa **propre recherche** avait identifié la
précondition, mot pour mot : *« besoin de `baseRef: "head"`, sinon il part de `main` et perd le
contexte de la mission »* (`.planning/research/2026-08-05-parallelisation-execution.md:92-94`). Le
réglage a été posé — dans `.claude/settings.local.json` **de ce repo**, sous checkpoint humain,
avant l'armement, dans le bon ordre.

Puis les agents ont été distribués. Pas le réglage : **zéro occurrence de `baseRef`** dans
`vibeflow-update.sh`, `merge-hooks.sh` et l'installeur. Chez l'utilisateur, les 13 workers partaient
sur un worktree forké depuis la branche par défaut, sans les fichiers de leur mandat, et le manager
se rabattait en silence sur un agent générique.

**Le maillon manquant n'était pas la connaissance.** La précondition était identifiée, écrite,
arbitrée et posée. Ce qui n'a jamais été posé, c'est la question suivante : **qui écrit ce réglage
chez l'utilisateur ?**

#### Pourquoi rien ne l'a vu

| Garde en place | Ce qu'elle a vérifié | Pourquoi elle est passée |
|---|---|---|
| 52 suites + CI Linux | le comportement **dans ce repo** | le repo a le réglage dans son settings local |
| `check-agents.sh` | la **forme** de `isolation:` (« seul `worktree` est admis ») | il ne pouvait pas savoir si la valeur était légitime — corrigé en v2.50.1 |
| Checkpoint humain avant armement | que la précondition soit **posée** | jamais qu'elle soit **distribuée** |
| Job CI « lab frais » | que la baseline passe **ses propres gates** dans un lab vierge | il ne compare aucun armement à sa précondition |

Le job « lab frais » est l'endroit le plus proche du besoin — il installe déjà dans un lab vierge.
Il vérifie que l'install **tient**, jamais que ce qu'elle pose est **cohérent avec ce qu'elle a
promis**.

#### Le précédent à reprendre, pas à réinventer

`check-capability-activation.sh` (Phase 24) relie **une entrée de doc à l'activation de sa
capability** — né exactement du même motif : trois routes documentées qui ne faisaient rien parce
que la capacité était éteinte. La phase 28 est ce motif **d'un cran plus loin** : relier un
**armement** à la **distribution** de sa précondition. Regarder d'abord si ce gate s'étend plutôt
que d'en créer un sixième — la Phase 24 a documenté le coût de ce réflexe (6 implémentations d'un
même besoin en 3 langages, et un script neuf dans aucun roster).

#### Questions ouvertes, à trancher au cadrage — pas ici

- **Qu'est-ce qu'un « armement » recensable ?** `isolation:` est le cas connu. Un hook, un flag de
  capability, une clé de settings lue par un script posé, un `permissionMode` — la frontière n'est
  pas établie, et un gate qui la devine sera soit inerte soit insupportable.

- **Le lab frais doit-il porter le gate, ou faut-il un gate séparé ?** Le premier a l'environnement,
  le second a la lisibilité. Non tranché.

- **Faut-il distribuer `worktree.baseRef` et ré-armer ?** Question distincte, et **elle n'est pas
  ouverte par cette phase** : le retour des commits d'un worker isolé reste non implémenté en amont
  (`open-gsd/gsd-core#3302`). Tant que ce point n'est pas levé, ré-armer serait refaire #38 avec une
  précondition de plus. Cette phase porte le **gate**, pas le ré-armement.

Plans:
**Wave 1**

- [x] 28-01-PLAN.md — Tranche traçante : la règle 4 de bout en bout sur `isolation:` seul (registre-vocabulaire, 3ᵉ discriminant `FILENAME`, planchers anti-vert-à-vide, premier porteur réel de `# vf-provides:`, cas de preuve #38 rejoué rouge/vert). Vague 1.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 28-02-PLAN.md — Expansion : seconde ligne de la liste close (armements MCP), 5 déclarations `vf-requires: mcp-servers` sur les artefacts réellement armés, admission de la clé dans les `KNOWN` de `check-agents.sh`, opposabilité machine des porteurs de preuve, et les 5 bornes déclarées de l'en-tête du gate. Vague 2.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 28-03-PLAN.md — *As-installed testing* : le gate exercé tel qu'installé dans un lab vierge, sur un univers d'armement non vide (checkpoint humain — la forme dépasse le cadrage D-04), puis clôture des deux triades de module. Vague 3.

### Phase 29: Distiller les gains ICM (G1-G5) — investigation dag.sh --scope d'abord

**Goal:** Distiller dans VibeFlow les 5 mécanismes retenus par la deep-search ICM
(`reports/research/2026-08-15-icm-deep-search.md`, §5), sans jamais adopter le label ni le modèle
mono-agent : G3 gate anti-drift carte↔disque (`check-map-drift.sh` — diffe ce que déclarent
CLAUDE.md/frontmatters/compteurs contre le disque réel), G1 anti-chargement déclaré (tables
« Load / DO NOT Load » dans les templates + le négatif du périmètre `--scope` dans les digests de
mission), G5 Edit-Source Principle dans la doctrine des managers (correction récurrente = amender
la source, jamais redispatcher le même fix), G2 CONTEXT.md ≤ 80 lignes par compartiment +
`_index.md` des dossiers de références > 10 fichiers, G4 lab-starters clonables à placeholders
pour `vf-new-lab` (à cadrer — candidat au découpage en phase propre, recoupe les items backlog
`agency-agents` et « Template d'agent installable »). **Précondition transverse : investigation de
l'historique et des consommateurs de `dag.sh --scope` (git log, tests, lecteurs du champ) AVANT
tout geste G1 — zéro régression autorisée sur le mécanisme de scope, qui porte le dispatch
parallèle des périmètres disjoints du team-kernel.**
**Requirements**: ICMD-01, ICMD-02, ICMD-03, ICMD-04, ICMD-05, ICMD-06, ICMD-07, ICMD-08, ICMD-09, ICMD-10, ICMD-11, ICMD-12
**Depends on:** Phase 28
**Plans:** 5 plans

Plans:
**Wave 1**

- [x] 29-01-PLAN.md — Socle : baseline `test-dag.sh` verte constatée par exécution, rapport durable d'investigation `--scope` (historique en deux phases par commit, inventaire des consommateurs, couverture T13-T33, verdict intouchable/extensible, voie G1 avec clause de halte), et création des 12 exigences `ICMD-01..12` au ledger. Vague 1.

**Wave 2** *(blocked on Wave 1 completion — périmètres disjoints, dispatchables en parallèle)*

- [x] 29-02-PLAN.md — **G3** : `check-map-drift.sh` (lint seul, deux paires carte↔disque bidirectionnelles, grammaire d'exit 0/1/3/64, wrapper git durci, plancher anti-vert-à-vide, bornes déclarées en en-tête) + sa suite née avec lui, mutations attestées à l'octet. Vague 2.
- [x] 29-03-PLAN.md — **G1 + G5** : bullet « NE charge PAS » dans le gabarit de digest (composée de champs déjà émis, zéro ligne dans `dag.sh`), table Charge / NE charge PAS dans la doctrine des agents (+ miroir `docs/`), et règle d'édition-à-la-source dans la doctrine du kernel. Vague 2.
- [x] 29-04-PLAN.md — **G2** : contrat de routage `CONTEXT.md` ≤ 80 lignes par compartiment de documentation posé par `scaffold-docs.sh`, pattern `_index.md` (> 10 fichiers) avec sa première application réelle, et première suite de tests du scaffolder. Vague 2.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 29-05-PLAN.md — Clôture : câblage du gate comme 9e signal de la grille de dette documentaire à coût de densité nul, 4 triades de module bumpées, compteurs « N suites » re-dérivés, puis **checkpoint humain bloquant** (findings réels du gate présentés, jamais corrigés — ADR-031). `autonomous: false`. Vague 3.

---
