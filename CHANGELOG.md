# Changelog — vibeflow-os

Historique des versions du **repo** (canon unique — les deux README n'affichent que les 3
dernières entrées et pointent ici). Chaque module a par ailleurs son propre `CHANGELOG.md`
sous `plugin/<module>/`. Rappel : toute release = un tag git annoté `vX.Y.Z`
(`scripts/check-release-tag.sh`).

## [v2.43.0] — 2026-07-28

**Le moteur GSD entre dans le périmètre de `/vf-update`** (Phase 19, livrée en mission d'équipe —
**ADR-058**). Modules `dev-orchestrator` **v2.7.0** et `conductor` **v1.16.0** (premier cas de deux
modules bumpés dans la même phase).

**Le trou fermé.** La migration `get-shit-done-cc` → `@opengsd/gsd-core` livrée en v2.39.0
n'atteignait **aucun poste déjà équipé** — seulement les installations neuves. Constaté sur un poste
tiers le 2026-07-28 : plugin à jour en **2.42.0**, cache rafraîchi le matin même, et moteur toujours
à **1.42.3** posé **12 jours** plus tôt, soit 2 jours après la livraison de la migration. Le poste
portait le *code* de la migration sans en porter l'*effet*, et rien dans l'interface ne le disait.
Le message final « Modules à jour sur disque » était **exact et trompeur à la fois**.

**Trois causes enchaînées, toutes fermées.** `detect_gsd()` renvoyait vrai sur le layout legacy via
un `||` écrit pour la tolérance dual-layout (Phase 10) et en faisait un `skip` : il devient un état
à **trois valeurs** — `absent` / `legacy` / `gsd-core` — où « legacy » est **actionnable**, pas
sauté. Aucun chemin de mise à jour n'appelait `ensure_gsd()` : le nouveau gate
`check-gsd-engine.sh` (contrat F13, exits 0/2/3, 15 cas de test) est sondé par `/vf-update`. Et
`log_legacy_cleanup_if_needed()` n'était joignable que par `/vf-init` et `/vf-calibrate` — un
garde-fou correct sur un chemin que le régime nominal n'emprunte jamais.

**La détection passe AVANT le stop « VibeFlow est à jour ».** Sans ce point, la correction n'aurait
rien corrigé : sur le poste constaté, le plugin était déjà à jour, donc `/vf-update` s'arrêtait à
l'étape 1 avant toute détection du moteur. L'étape 1 devient un **diagnostic à deux volets** —
version du plugin **et** état du moteur — et le message ne peut plus sortir seul quand le moteur est
legacy.

**Le piège de version, écrit noir sur blanc.** Le fork **repart de zéro** : `get-shit-done-cc` est
figé à 1.42.3 (déprécié sur npm) pendant que `@opengsd/gsd-core` vit à 1.8.0. Donc
**1.8.0 < 1.42.3 en semver**, et la doctrine « ne jamais downgrader » interdirait précisément le
geste à faire. La migration se décide sur le **nom du paquet et le layout du dossier**, jamais sur
la comparaison des numéros — un test fixe ce couple exact. Le plafond `@^1` reste inchangé, et le
repli legacy de la cascade à 4 niveaux est préservé pour les postes non migrés : c'est le **skip**
qui est corrigé, pas le repli.

**ADR-031 tenu de bout en bout.** Détecter et **proposer**, jamais installer sans accord : la
migration est une ligne de plus dans la confirmation existante, refusable sans effet de bord. Le
nettoyage legacy reste **affiché, jamais exécuté** — mais devient atteignable et **exact** :
`npm uninstall -g` n'est plus proposé que si le paquet est réellement installé en global (constaté
faux sur le poste audité — install `npx`, jamais globale, donc deux lignes sur trois étaient des
no-op), l'arborescence vide laissée debout par l'installeur est incluse, et l'état legacy est
**capturé avant l'install** — l'installeur amont supprimant lui-même le `VERSION` legacy, le message
ne pouvait sinon plus jamais sortir après coup.

**La ré-injection MCP devient une étape, pas une conséquence heureuse.** L'installeur `gsd-core`
réécrit `agents/gsd-executor.md`, classe l'injection ADR-051 en « local patch » et efface
`mcp__XcodeBuildMCP__*` du `tools:`. Sur un lab dont le `CLAUDE.md` interdit `xcodebuild` en shell,
l'exécutant ne peut alors plus builder du tout — ou le fait par le chemin interdit.
`ensure-deps.sh --migrate-engine` enchaîne donc sur `inject-mcp-tools.sh --force`, et le nouveau
mode `--verify` compare le `tools:` final aux serveurs déclarés dans le `.mcp.json` du lab.

**Le défaut que trois étages ont laissé passer — à retenir.** `--verify` a d'abord été livré
**inerte** : appelé sans `--force`, il écartait sa propre cible (`gsd-executor.md` ne porte pas le
flag `vf-mcp-consumer`) et sortait **toujours en 3** — jamais « conforme », jamais « serveur
manquant » — tout en crachant un `ERROR` à chaque bootstrap sur les labs sans `.mcp.json`. Revue de
code PASS, portabilité verte sur trois OS, audit sécurité 6/6 : aucun ne l'a vu. Seule la **mutation
du bloc livré** l'a révélé — sa suppression complète laissait la suite à 73 OK / 0 KO. Deux causes
nommables et réutilisables comme sondes : un compte rendu qui prouve une **présence**
(`grep -c 'verify' → 7`) au lieu d'un comportement, et des tests qui exercent une forme de commande
que la production n'émet jamais. Corrigé avec un contrat de relais explicite (seul `rc=1` alarme,
`rc=3` reste INDÉTERMINÉ informatif) et un cas de test qui exerce le chaînage réel.

**Reste ouvert, inscrit à `CONCERNS.md`** : la sonde cross-module `conductor` → `dev-orchestrator`
s'éteindrait **sans aucun signal** si l'engine cessait de matérialiser les scripts de tous les
modules à plat dans le même `.claude/scripts/`. Le silence sur script absent est voulu — un lab
content ou growth ne doit rien voir du moteur GSD — mais il rend le mode dégradé indiscernable du
nominal, même famille que le trou que cette version ferme.

## [Non versionné] — 2026-07-26

**Correctif `_internal/merge-hooks.sh`** (vague 11-04, Phase 11 — intégration migration GSD).
Le matching des scripts référencés dans un hook merge est désormais ancré aux frontières de
chemin réelles (fin du bug de sous-chaîne : un hook référençant `archive.sh` aurait pu, à tort,
matcher et donc détruire une entrée tierce `gsd-archive.sh`). Fin également de la réutilisation
de groupes mixtes lors du merge de hooks — un groupe qui mélange des scripts de provenances
différentes n'est plus recyclé, un nouveau groupe est créé à la place. Entrée non taggée : ne
déclenche pas de release, sera absorbée par le prochain bump de `VERSION` racine.

## [v2.42.0] — 2026-07-28

**Signaux de démarrage du moteur de dev** (Phase 17, livrée en mission d'équipe). `dev-orchestrator`
était le seul module structurant **sans aucun hook** — conséquence directe :
`discover-unintegrated-docs.sh`, livré en Phase 13 avec un contrat propre et testé, n'était jamais
appelé automatiquement. Le module reçoit son premier fragment `hooks/hooks.json`, câblé par l'engine
sans le modifier (`merge_module_hooks` gérait déjà le cas). Trois scripts constatent des **FAITS** au
`SessionStart` et injectent des lignes courtes et **auto-portantes** — chacune porte son propre geste,
sur le modèle de `[planning-debt]`. Module `dev-orchestrator` **v2.6.0**.

**`check-dev-bootstrap.sh` — le continuum de démarrage en un seul script.** Silence si ni code ni
`.planning/` ; signal `onboard` si du code sans `.planning/` ; signal `bootstrap` listant les items
manquants (`config.json`, `codebase/`, ROADMAP sans phase) ; signal d'orientation `gsd-engine` si
complet. Les signaux sont **prouvés mutuellement exclusifs par test**, pas par construction.

**Le signal `gsd-engine` ferme un trou de routage constaté sur ce dépôt le 2026-07-27** : une demande
de conception adressée au Claude principal est partie sur du brainstorming générique alors que le
projet tournait sous GSD avec une phase inscrite. Cause structurelle — `planning-core` se retire
quand GSD tient le projet (`--defer-to-gsd`) et aucun module ne prenait le relais ; le routage de
`vibeflow-dev` n'existe que si son `AGENT.md` est lu, donc seulement une fois l'agent invoqué. Le
signal lit le frontmatter réel de `STATE.md` (milestone, phase, statut) et **retombe en silence s'il
est illisible** — jamais d'état inventé. Arbitrage humain assumé : un projet sain coûte **1 ligne,
pas 0**, le critère d'acceptation initial ayant été amendé en ce sens (il contredisait la spec et les
deux critères voisins de la même feuille de route).

**Les deux autres signaux.** `discover-unintegrated-docs.sh --hook` agrège le compte en une ligne de
façon **additive**, sans toucher au contrat historique (`grain<TAB>chemin`, exits 0/3/64) consommé
par `ingestion-flow.md` ; `--hook` avec `--quiet` sort en 64. `check-doc-drift.sh` signale au-delà
d'un seuil de commits de code sans mise à jour de doc (défaut 20, réglable) et reste silencieux hors
dépôt git ou sans commit de doc.

**Contrat advisory vérifié par exécution.** Les trois scripts sont en lecture seule : aucune
écriture, aucun `exit 1`, aucun blocage de tour — la confirmation humaine reste devant chaque geste
proposé (ADR-031). Vérifié sur 5 frontmatter hostiles (injection shell, octet `0x01`, délimiteur
tronqué) qui rendent tous stdout vide et exit 3, et sur un `node_modules` de 20 000 fichiers traversé
en 0,007 s.

**Portabilité prouvée par exécution, pas déclarée.** Compteurs **identiques** sur macOS bash 3.2.57,
Debian 12 bash 5.2.15 et Ubuntu 24.04 — l'OS exact du runner. L'égalité des compteurs est le vrai
résultat : elle exclut le **test sauté silencieusement**, qui était le mode de panne dangereux (la
régression CI du 2026-07-27 avait coûté 6 fixes de portabilité). Aucun edit de `ci.yml` nécessaire,
les suites tombent dans son `find`. Suites du dépôt : 39 → **41**.

**Deux faux verts débusqués dans les tests** — aucun dans le code livré. Le cas 7 de
`test-discover-unintegrated-docs.sh` était **tautologique** : sa fixture ne citait que le glob, jamais
le basename, donc il passait avec ou sans le filtre qu'il prétendait verrouiller — prouvé par
mutation, et re-prouvé discriminant après correctif. Et la boucle T21, filet censé garantir les
invariants du contrat advisory, **omettait `discover-unintegrated-docs.sh`**, le seul des trois à
utiliser `mktemp` ; le comblement a lui-même révélé un défaut latent du helper
`t21_strip_awk_block`, aveugle à `awk -v x=… '`.

**Deux dettes inscrites au `CONCERNS.md`, non corrigées (hors périmètre).** Le **verrou de driver est
déclaratif, pas contraignant** (HIGH) : aucune garde en écriture ne refuse un commit à une session
sans verrou — constaté le 2026-07-27, deux missions ont commité en parallèle avec des horodatages
entrelacés, ce qui a produit une collision de numérotation de version. Le **gate ADR-044 est un faux
vert dans son invocation nue** (MEDIUM) : `check-agents.sh` sans argument sort `exit 0` sans rien
linter (`.claude/agents` absent du dépôt), et `AGENT.md` étant à la racine du module, il échappe
aussi à la boucle CI sur `plugin/*/agents` — seul `--file` prouve quelque chose.

## [v2.41.0] — 2026-07-27

**Cloisonnement complet des dispatches d'agents** (Phase 16, livrée en autonomie complète). Ferme
les deux trous escaladés par la mission de la Phase 15. `check-agents.sh` **lint désormais le
contenu** du champ `tools:` — syntaxe des allowlists (parenthèse fermée, séparateurs, charset) et
existence de chaque nom, sur `tools:` comme `disallowedTools:` : jusqu'ici, des noms d'agents
inventés, une parenthèse non fermée ou des outils inexistants passaient tous `--strict` en vert. La
suite `test-check-agents` passe de 38 à **58 axes**.

**Résolution graduée du piège natifs/externes.** La sévérité est indexée sur ce qui est vérifiable
indépendamment du périmètre installé : syntaxe → erreur dure (ne dépend d'aucun scope) ; nom d'outil
hors du set fermé documenté → warning, erreur en `--strict` ; **nom d'agent non résolu → warning même
en `--strict`**, erreur seulement sous le mode opt-in `--resolve-agents=strict`, réservé à la CI —
seul endroit où l'univers complet des agents du repo est connu. Mesure à l'appui : 22 entrées non
résolvables sur la baseline, dont **aucune n'est un bug** (types natifs comme `general-purpose`,
agents `gsd-*` de `@opengsd/gsd-core`, agents d'autres modules non installés). La doc officielle ne
fige pas la liste des types natifs : en faire une erreur serait parier sur une liste mouvante, pari
que le dépôt a déjà payé au prix de 66 faux positifs. L'option « manifeste externe » a été écartée
sur preuve de code (`copy_module_scripts()` ne globbe que `*.sh|*.mjs|*.js` — un fichier de données
ne serait jamais posé chez l'utilisateur) : tout est inline. Bonus, `--third-party-prefix` **ferme la
dette connexe** des 66 faux positifs du scope user.

**Allowlists posées sur les 3 workers dev** — `vf-coder` (22 noms), `vf-reviewer`
(`gsd-code-reviewer`), `vf-auditer` (`gsd-security-auditor`) — après **double recensement
indépendant en parallèle**, la seconde dérivation interdite de lire les rapports de mission, les
allowlists existantes et `CONCERNS.md`. Accord total sur deux workers ; écart de 5 noms sur
`vf-coder` (21 vs 18), union retenue au titre du coût d'erreur asymétrique. Fait discriminant :
`vf-coder` a le tool `Skill`, donc une expansion transitive que les deux autres n'ont pas.

**Correction de portée doctrinale — une allowlist n'est pas un sandbox runtime.** La doc officielle,
désormais citée verbatim dans l'en-tête du script, est explicite : dans la définition d'un
sous-agent, le runtime **ignore** la liste de noms entre parenthèses ; seule la présence de
`Agent`/`Task` dans `tools:` compte. Une allowlist `Agent(x, y)` est donc un **contrat documenté,
enforcé par ce lint et par lui seul** — elle ne redevient une restriction runtime que pour un agent
incarné en thread principal (`claude --agent`). Vaut rétroactivement pour les allowlists des deux
managers posées en v2.40.0.

**Ce que les juges ont rattrapé**, sur des classes disjointes : T19/T19e étaient **tautologiques**
(grep sur toute la ligne `tools:` — un nom retiré de l'allowlist mais replacé en `Bash(...)` laissait
la suite verte à 50/0 alors que le dispatch était perdu), deux faux-bloquants du lint neuf (champ
quoté ; ligne vide en liste bloc faisant perdre silencieusement les entrées suivantes), et
`--resolve-agents=<valeur inconnue>` qui **dégradait le gate en silence** — une typo YAML aurait
désactivé le monde fermé sans un mot.

40 suites vertes, 6/6 modules `--strict` exit 0, 6/6 en monde fermé. Deux entrées retirées de
`CONCERNS.md`. Modules : conductor v1.15.0, dev-orchestrator v2.5.0.

## [v2.40.0] — 2026-07-27

**Collaboration inter-équipes dev ↔ design : étages croisés sous un seul manager** (Phase 15,
option A validée par 7 tests empiriques). Les deux équipes de mission cessent d'être étanches sans
jamais s'imbriquer : un seul verrou de driver, un seul DAG, un seul rapport de mission. En mission
dev, `vf-dev-manager` insère des nœuds `craft:<écran>` (`vf-crafter`) avant l'exécution et
`critique:<écran>` (`vf-design-judge`) en parallèle de la revue code — décision de jugement au plan
de bataille, seuil design bloquant au même régime que l'équipe design, étage sauté et signalé si la
DA manque (next step DA-INIT, jamais de DA inventée). En mission design, `vf-design-manager` gagne
un étage d'implémentation opt-in (`livrable: specs|specs+implementation`) où `vf-coder` incarne les
specs du crafter, avec double juge en parallèle (re-critique DA **et** revue de diff) et budgets
anti-thrash séparés 3 + 3 par écran. Le brief de mission gagne les champs `design: auto|force|off`
et `livrable:` ; le digest croisé embarque la DA vers les workers design et les conventions code
vers les workers dev (≤ 30 lignes, le disque fait foi). `vf-auto` aiguille enfin les missions
entièrement design vers `vf-design-manager` (règle simple : design pur → design, tout le reste →
dev). Cloisonnement **structurel** : allowlists `Agent(...)` sur les deux managers (18 noms côté
dev, 6 côté design) — un manager ne peut pas dispatcher l'autre. Deux corrections de vérité en
cours de route : `check-agents.sh` ne lint **pas** le contenu du champ `tools:` (l'enforcement réel
passe par les tests de suite, prouvés rouges par mutation), et le recensement initial de l'allowlist
dev omettait 4 agents dispatchés via les skills du manager (fin de milestone, ingestion de cadrage,
re-validation de plan) — trouvés par audit indépendant. Nouvelle référence
`conductor/references/mission-cross-team.md` (Pattern D). Kernel intact : aucune modification de
`dag.sh` ni `driver-lock.sh`. Suites : 43 dev-orchestrator, 12 design-orchestrator, 36 dag,
26 driver-lock — 0 KO. Modules : dev-orchestrator v2.4.0, design-orchestrator v1.3.0,
conductor v1.14.6. Escaladé et non livré volontairement : le lint réel dans `check-agents.sh` et le
scoping `Agent` des workers (`vf-coder`/`vf-reviewer`/`vf-auditer`) — le chemin indirect
manager→worker→manager reste ouvert au dispatch, l'invariant tenant par le verrou de driver.

## [v2.39.0] — 2026-07-26

**Migration du moteur GSD : `get-shit-done-cc` → `@opengsd/gsd-core@^1`** (clôture du milestone
`gsd-migration`, VOC-02). L'original est déprécié et abandonné ; VibeFlow bascule sur le
successeur communautaire — à parité fonctionnelle prouvée sur install réelle sandbox — avec un
**plafond semver `^1`** (fraîcheur sans pin figé, saut de majeure = décision humaine, arbitrage
post-audit). Livré en mission d'équipe (6 vagues, 26 commits) : `ensure-deps.sh` migré (piège
`command -v gsd-sdk` neutralisé, layout dual `gsd-core`/legacy, étapes destructives affichées
jamais exécutées — ADR-031 prouvé par sentinelle), références SDK → **`gsd-tools`** (le paquet
`@opengsd/gsd-sdk` est lui-même déprécié ; parité des 3 requêtes prouvée), routage **`gsd-onboard`**
pour le brownfield (BOOT-04 conservé), canal « une seule voix » (`gsd-next` et `gsd-mempalace-*`
délibérément non routés, frontières machine dans `check-overlaps`), durcissement `merge-hooks.sh`
(matching ancré + fin de co-location, prouvé rouge→vert) + nouvelle suite `test-gsd-cohabitation`
sur le settings.json réel de l'installeur, `model_profile: balanced` explicite (doctrine
« planner=opus, workers=sonnet » machine-enforced côté moteur). 39 suites vertes, dry-run 3 scopes,
vérification goal-backward PASS, audit sécurité sans bloquant. Modules : dev-orchestrator v2.3.1,
planning-core v2.5.2, conductor v1.14.2. Dossier d'étude complet dans
`.planning/phases/10-etude-migration-gsd/`.

## [v2.38.0] — 2026-07-26

**Documentation niveau framework, module par module.** Le README de chaque module devient sa
documentation canonique — même structure partout : tagline, Type/Version/Dépendances, Quoi,
**Installation** (prérequis réels, ordre d'install explicite), **Démarrer** (premier usage
guidé en 5 min), **Usage**, **Référence** exhaustive vérifiée sur disque, **Limites**. 10
modules montés au standard (design-orchestrator, kpi-analyst, mobile-test, mobile-test-team,
skill-creator, audit-architecture, infrastructure-audit et les 3 bundles métier — qui
déclarent désormais leur en-tête Version, gaté 17/17). Pas de dossier de doc parallèle : une
seule source, zéro nouvelle surface de drift. Vitrine racine (FR+EN) : nouvelle section
« Au-delà du dev — un lab pour chaque métier » (pipeline `/vf-new-lab` en mermaid, design en
équipe avec juge frais /100, bundles métier, kpi-analyst) + hub de doc vers les README de
modules. Embarque aussi : lexique P3-P8 réaligné sur le Core v4.2 canonique (reference
v2.5.2, arbitrage 2026-07-26). Découverte tracée en Limites d'infrastructure-audit :
`known-versions.txt` n'est jamais posé par l'engine (fail-open, pose manuelle).

## [v2.37.0] — 2026-07-26

**Clôture du milestone `vf-routing` — le pont spec → feuille de route est livré** (Phase 13,
exécutée en mission d'équipe). Une spec ou un plan écrit devient des étapes de la feuille de
route **sans quitter le modèle agentique** : le fait est outillé par
`discover-unintegrated-docs.sh` (quels cadrages ne sont pas encore intégrés — 6 registres de
citation, détection du grain spec/plan, 16 cas de test, revue à coût d'erreur asymétrique :
2 bloquants trouvés et corrigés), et l'agent `vibeflow-dev` porte la doctrine
`references/ingestion-flow.md` (typage en prose, manifest YAML construit par l'agent,
délégation `gsd-ingest-docs --mode merge` / `gsd-import`, gate BLOCKER jamais contourné,
cap 50 signalé). **Aucun verbe-façade recréé** — la phase, écrite avant la bascule agentique
autour d'un `/vf-ingest`, a été redéfinie sans verbe. La confirmation humaine ADR-031 précède
tout appel d'ingestion, ancrée **nominativement** dans `vibeflow-dev` ET `vf-dev-manager`
(échappatoire trouvée par l'audit BRDG-03, fermée en v2.2.1 du module). `dev-orchestrator`
v2.2.1. Premier usage réel de l'outil : une citation canonique perdue à l'archivage du jalon
`vfdo-v1.0` retrouvée et restaurée. Les 3 phases du milestone (12, 13, 14) sont complètes.

## [v2.36.2] — 2026-07-26

**Remédiation de l'audit « périmé »** (planning + docs, 5 commits). Côté distribution :
README de modules réalignés sur l'état réel — `validator` (5 audits, dépendance
`audit-architecture` rétablie, chemin d'install corrigé, skills fantômes purgés, densité vraie
249/250 L), `conductor` (team-kernel enfin documenté : `dag.sh`, `driver-lock.sh`, rapports
typés ; skill `vf-update`, hooks, 13 scripts, dépendance `skill-creator`/ADR-047), `reference`
(12 patterns / 5 skills / 42 templates / Core v4.2 à 9 principes, contenu distribué inclus :
`VERSION.md`, `README-CLIENT.md`, `lexique.md` gagne P9), `consolidator` (5 piliers, arbre
complet, `/consolidate` → `/consolidator`, ADR-031 → ADR-056), `planning-core`,
`software-architecture`, `dev-orchestrator` (`gsd-sketch` → `vf-sketch`, kernel consommé depuis
`conductor`). Registre ADR : ADR-053 relocalisé (kernel → conductor, v2.34.0), ADR-052 remet
`plugin/reference/` en source, ADR-035 gagne sa définition canonique. Les 14 en-têtes
`**Version**` des README de modules réalignés et **gatés** : `check-version-sync.sh` gagne les
contrôles 8 (en-tête Version ↔ VERSION du module) et 9 (compte de suites ↔ découverte CI), et
son grep « N modules » mort depuis la v2.36.1 échoue désormais bruyamment au lieu d'être sauté
en silence. Divers : marqueur de conflit git purgé de `conductor/CHANGELOG.md`,
`/vibeflow-install` présenté comme skill dans les 2 README. Côté planning (non distribué) :
Phase 13 redéfinie **sans verbe** (ingestion portée par l'agent), socle `.planning/` remis à
l'heure, cartographie codebase régénérée, PROJECT.md rouvert.

## [v2.36.1] — 2026-07-26

**Refonte vitrine des README** (FR+EN), inspirée d'ECC (spécificité, tables) et GSD (accroche
par le problème) : dev-first, 3 diagrammes mermaid (cycle spec-driven, équipe de mission avec
rapports typés et nœud gelé, architecture kernel/orchestrateurs/gouvernance), efficience
chiffrée et mémoire en avant, tableau des 17 modules replié en `<details>`. Corrections :
note « bundles WIP » périmée, Hub kpi-analyst adouci, handle GitHub de Samuel. Gate :
`check-version-sync` invariant n°7 — l'historique README en tête doit être la VERSION
courante (c'est lui qui a exigé cette entrée).

## [v2.36.0] — 2026-07-26

**Recettes réelles (UAT) sur labs vierges + corrections** — deux labs sandbox installés par le
vrai engine et joués par des agents neufs (rapport : `reports/uat/2026-07-25-uat-express-et-dev.md`) :

- **Verdicts** : le mode express tient son contrat (~11 min 30 < 15 min, fabrication réelle
  d'un skill avec 2 évals PASS en tâche de fond, Gate C 3/3) ; le protocole de mission
  (lock → DAG → pipelining N/N+1 → rapports typés → reopen → release) est **exécutable par un
  agent qui ne l'a pas écrit**, scripts du kernel conformes à 100 % (mission pomodoro réelle,
  7 commits, app fonctionnelle démontrée).
- **16 frictions corrigées**, dont 3 bloquantes : un lab frais échouait son propre
  `check-agents --strict` (skills plugin déclarés, résolution par nom de dossier — corrigée
  par frontmatter `name:`) ; templates de registres absents de la baseline (embarqués dans
  consolidator v1.8.0) ; cascade `$S` qui préférait le scope user au lab courant. Doctrine
  `human_needed` en autonome tranchée : **geler le nœud porteur**, jamais « continuer ».
- **Dépendance team-kernel déclarée** : `requires: conductor` sur les 5 modules consommateurs
  (fermeture resolve-deps incomplète depuis l'extraction v2.34.0).
- **CI : job « lab frais »** — installe la baseline dans un lab vierge et exige qu'elle passe
  ses propres gates sans intervention (la CI testait le repo, pas l'expérience installée).
- 9 modules bumpés (conductor v1.14.1, consolidator v1.8.0, validator v1.3.1,
  dev-orchestrator v2.1.1, planning-core v2.5.1, design-orchestrator v1.2.1, bundles ×3 v2.0.1).

## [v2.35.0] — 2026-07-25

**La promesse multi-métier est tenue : les 3 bundles métier sont des modules réels** (fin du
doc-only), chacun avec une équipe complète sur le team-kernel, un juge read-only à rubric /100
avec critères éliminatoires, des Iron Laws machine-testées et une suite de tests dédiée :

- **growth-bundle v2.0.0 (`proposable: true`)** : `vf-growth-manager` (DAG stratégie →
  production → gate → humain → analyse par campagne) + channel-strategist / copywriter-sequences /
  campaign-analyst + `growth-quality-judge` (claims sourcés ET consentement/anti-spam
  éliminatoires). Tout envoi réel human-gated ; l'analyste refuse toute campagne sans preuve
  de lancement humain ; métriques sourcées ou `low` (Iron Law kpi-analyst). 12 tests.
- **business-pilot-bundle v2.0.0 (`proposable: true`)** : `vf-business-manager` (DAG
  commercial → delivery → gate → humain → finance par dossier client) + commercial / delivery /
  finance + **`quality-gate-client`** — le gate « à fabriquer » du finding F16 enfin livré
  (périmètre vendu et montants sourcés éliminatoires, seuil 80). Double Iron Law : aucun envoi
  client sans validation humaine, aucun chiffre financier inventé. 14 tests.
- Le catalogue d'install propose désormais les **3 bundles** ; messaging racine et tableaux
  README alignés sur le réel (équipes, versions, types).

## [v2.34.0] — 2026-07-25

**Vague 3 de l'audit croisé — universalisation** (clôt le programme d'audit du 2026-07-25) :

- **Team-kernel (conductor v1.14.0)** : `dag.sh` + `driver-lock.sh` extraits en socle
  transverse, `team-kernel.md` pose le contrat universel (invariants du kernel — lock, DAG,
  rapports typés, HALT, digest, cloisonnement — vs paramètres du métier : spécialistes,
  définition du « vert », gates). Le dev-orchestrator devient l'implémentation de référence.
- **Équipe design (design-orchestrator v1.2.0)** : première instanciation non-dev —
  `vf-design-manager` + `vf-crafter` + `vf-design-judge` (juge frais, rubric /100 : DA /40 +
  copy/hiérarchie/couleur/typo/spacing/accessibilité, seuil 70, 3 tours max).
- **Bundle content matérialisé (content-bundle v2.0.0, `proposable: true`)** : de doc-only à
  module installable — manager + strategist/writer/repurposer + juge de clarté (chiffres
  sourcés éliminatoires, seuil 80), publication toujours human-gated, 12 tests. Preuve
  d'universalité : le catalogue d'install le propose désormais.
- **Pipelining N/N+1 (dev-orchestrator v2.1.0)** : discuss/plan/execute modélisés par étape
  dans le DAG, cadrage+plan de N+1 pendant l'exécution de N, plan provisoire re-validé.
- **Lab express (conductor)** : opérationnel en ≤ 15 min — 3 questions, dérivations `[DÉRIVÉ]`
  assumées, Gate C intact (test anti-régression), fabrication en tâche de fond, dette
  d'express affichée. Scope d'install pré-sélectionné (installer).
- **ADR-057 — frontières outillées avec les briques tierces** : `check-overlaps.sh` (advisory,
  7 paires, doctrine F13), abandon du « sole authorized channel », frontières descriptives
  (debug, revues, skill-creator, mobile, brainstorm).

## [v2.33.0] — 2026-07-25

**Vague 2 de l'audit croisé — bascule agentique** (arbitrage Samuel, spec
`docs/superpowers/specs/2026-07-25-suppression-facade-vf-design.md`) :

- **dev-orchestrator v2.0.0 (breaking)** : les 29 verbes-façades `/vf-*` disparaissent — GSD
  redevient l'interface directe du quotidien. L'agent `vibeflow-dev` détecte l'intention et
  invoque les briques directement (carte d'intention **unique**, fin de la table ×4, de la rule
  de préséance et du reframe de vocabulaire). Survivent `vf-auto` (porte d'autonomie) et
  `vf-dev` (incarner l'agent). Tests refondus (26 OK), README et pipeline réécrits.
- **Manager agentique** : brief en langage naturel mappé par le manager, **digest de mission**
  ≤ 30 lignes par mandat (amortit ~100-200k tokens de relecture par étape), hygiène
  documentaire déclenchée aux bons moments (drift → nœud `gsd-docs-update`), next step ferme
  en fin de mission, rapports de workers réduits au bloc typé (détail sur disque).
- **ADR-045 en 1 saut (mobile-test-team v1.4.0)** : `vf-test-orchestrator` porte lui-même la
  recherche documentaire (WebSearch/context7) — fin de l'escalade à 3 étages.
- **Gouvernance proportionnée au profil** (planning-core v2.5.0, validator v1.3.0,
  consolidator v1.7.0, conductor v1.13.0) : Stop-hook `warn` en profil léger (lu dans
  `.planning/config.json`, machine-enforced, 4 tests), validator Phase 4 opt-in avec score
  renormalisé, EVALS créé à la première éval réelle en léger, cadences réalistes pour un solo.
- Références externes alignées (conductor, design-orchestrator, planning-core, commands) ;
  messaging racine basculé « modèle agentique ».

## [v2.32.0] — 2026-07-25

**Vague 1 de l'audit croisé du 2026-07-25** (5 audits parallèles, rapports dans `reports/`) —
le framework s'applique enfin sa propre doctrine d'enforcement :

- **CI GitHub Actions** : 31 suites de tests + `check-agents --strict` + gates de release,
  branchés sur push/PR. Fin du « vert non mérité » : 7 gates sortaient exit 0 sur cible
  absente → doctrine exit 3 = indéterminé (`--strict`/`--allow-empty`), engine d'install qui
  avorte si le merge des hooks de gouvernance échoue. Test rouge et test flaky corrigés
  (isolation HOME/cwd).
- **Équipe de mission optimisée** : workers et juges en sonnet (fin du tout-opus), dispatch
  **parallèle** de la frontière DAG et des juges (revue ∥ audit), fin de la double revue,
  cadrage non-interactif explicite de `vf-coder` (plus de checkpoint interactif mort).
- **Chasse aux fantômes** : les 3 skills inexistants du frontmatter validator (F3), la commande
  `/checkpoint` citée dans 13 fichiers (→ `/vf-audit`), les gates `human-validator` /
  `quality-gate-client` des bundles marqués « à fabriquer » (F16), le chemin `assets/` cassé du
  template skill-creator (F4, dédupliqué → pointeur).
- **ADR assainies** : définitions canoniques des 9 ADR héritées les plus citées ;
  **scission ADR-031/ADR-056** (validation humaine vs vigilance runtime — un même identifiant
  portait deux doctrines).
- **Versions honnêtes** : 13 versions fausses du tableau README corrigées, « 14 verbes » → 31,
  kpi-analyst ajouté, historique dédupliqué vers ce CHANGELOG, `scripts/bump.sh` (générateur
  idempotent), globs mobile discriminants (fin des faux positifs Next.js), messaging
  « dev + design + Lab Factory ». 14 modules patch-bumpés.

## [v2.31.1] — 2026-07-25

**Alignement des fichiers de version** : `software-architecture` et `kpi-analyst` ont livré leurs
correctifs de portabilité Windows en v2.29.0 (CHANGELOG et `module.json` bumpés tous les deux)
mais leurs fichiers `VERSION` étaient restés en arrière — or c'est `VERSION` que lit l'engine,
donc le registre annonçait un numéro périmé. Aucun utilisateur n'a été privé du correctif (les
changements sont dans `scripts/`, que le resync de gouvernance recopie), mais le registre de
versions dit désormais la vérité (software-architecture v1.5.1, kpi-analyst v1.0.1).

## [v2.31.0] — 2026-07-25

**Routage fin des intentions** : trois niveaux de routage (descriptions déclencheuses à
contre-exemples croisés, rule globale de préséance des verbes, doctrine exhaustive chargée
on-demand couvrant les 65 skills du moteur). 19 verbes `/vf-*` neufs — dev-orchestrator passe de
14 à 31, design-orchestrator gagne `/vf-sketch`. La table de l'agent ne cite plus aucune cible
interne : elle route vers un verbe, le verbe connaît sa cible. Aussi : purge des mentions d'un
projet tiers dans tout le dépôt, axes de test T5/T11 bornés à leur module, sémantique de
chargement des rules corrigée, gabarit de description sur les trois verbes du conductor
(dev-orchestrator v1.8.1, design-orchestrator v1.1.0, conductor v1.12.2).

## [v2.30.0] — 2026-07-25

Frontière d'altitude entre le planning VibeFlow et le moteur de planning de développement
(ADR-055) : planning-core **v2.4.0** — `vf-planning` ne pose plus le tronc d'un projet de code
(frontmatters `STATE.md` incompatibles, double injection `SessionStart`, concurrence au
matching), il tient l'altitude lab et redirige vers le bon verbe ; nouveau
`detect-gsd-engine.sh` (fait seul, 4 exits priorisés, marqueur borné au frontmatter), doctrine
`references/gsd-handoff.md`, flag opt-in `--defer-to-gsd` sur deux hooks (défaut inchangé),
guard Stop bloquant conservé en exception motivée ; `vf-new-lab` + routage conductor + 3 README
réalignés.

## [v2.29.0] — 2026-07-23

**Portabilité Windows (ADR-054)** : wrapper `jqx` normalisant le CRLF dans tout l'engine (le jq
Windows natif cassait l'install : `planning-core\r`, corruption silencieuse du catalogue),
préflight d'install (jq + sonde d'EXÉCUTION python3 vs stub Store + bash dans le PATH) avec
commandes par OS, `.gitattributes eol=lf`, chemins de scripts pleinement qualifiés, résolution
python dans `merge-hooks.sh` **et dans les hooks de garde runtime** (le stub Store passe
`command -v python3` : gardes inertes en silence), préfiltres mémoire compatibles antislashs
(les chemins Windows n'atteignaient jamais le python qui savait les traiter), signal
SessionStart quand les gardes sont inactives, gate de synchro des versions, droit de
réutilisation privée pour les élèves (licence) — causes racines remontées par deux rapports
terrain rejouables d'élèves sous Windows (conductor v1.12.1, consolidator v1.6.1,
software-architecture v1.5.1, planning-core v2.3.1, kpi-analyst v1.0.1).

## [v2.28.0] — 2026-07-22

R&D mémoire-swarm shippée (ADR-052/053) : consolidator **v1.6.0** pilier mémoire vivante (couche
`knowledge/` fichier-par-entrée, décroissance par demi-vie de catégorie + supersession non
destructive, `decay-pass.sh`) ; dev-orchestrator **v1.7.0** contrôle de flux swarm (lock de
driver unique + DAG ready/blocked avec rendu `tree` + rapports de worker typés, résolution de
scripts scope-robuste) ; conductor **v1.12.0** détection legacy scope-aware + nudge
SessionStart ; mobile-test-team **v1.3.0** rapports typés ; fix engine uninstall (skills
imbriqués + tests).

## [v2.27.1] — 2026-07-20

Gate agents fiabilisé (2e vague audit hooks conductor : parseur YAML, anti-trappe fail-closed,
portée lab, filet debug-research) (conductor v1.11.3).

## [v2.27.0] — 2026-07-20

Guard planning par attribution de session (ADR-050 amendée) + durcissement global des hooks du
harnais (29 findings corrigés, 282 checks verts) (planning-core, software-architecture,
conductor).

## [v2.26.0] — 2026-07-19

Allowlist MCP des agents exécutants dérivée du lab (ADR-051) : les sous-agents voient enfin les
serveurs MCP du projet (XcodeBuildMCP, mobile-mcp, DB métier…) via le flag `vf-mcp-consumer` +
injection idempotente à l'install depuis `.mcp.json` ; `gsd-executor` patché après l'install GSD
(dev-orchestrator v1.6.0, mobile-test-team v1.2.0, conductor v1.11.1).

## [v2.25.0] — 2026-07-16

Orchestrateur métier systématique + durcissement gouvernance (ADR-048/049/050) : `vf-new-lab`
pose un orchestrateur métier dès ≥2 agents métier + skill de boucle de mission ; backups mémoire
isolés avec rotation intégrée ; hooks planning (lecture index-first au start, mise à jour
bloquante au end) (conductor v1.11.0).

## [v2.24.0] — 2026-07-11

skill-creator ajouté à la baseline d'install du conductor (ADR-047) : le canal unique de
création de skills est désormais posé d'office via la fermeture transitive du conductor —
corrige le fan-out de `vf-new-lab` vers un sous-agent jamais installé (conductor v1.10.0).

## [v2.23.0] — 2026-07-09

Équipe manager de mission (ADR-046) : vf-dev-manager + workers spécialisés (arborescence à
contexte minimal), détection de mission par le router, bascule taille de vf-auto
(dev-orchestrator v1.5.0).

## [v2.22.0] — 2026-07-08

**Recherche-doc avant debug (ADR-045)** : phase de recherche documentaire obligatoire (context7
+ issues GitHub / release notes) **avant** tout debug empirique intensif, dès qu'un bug touche
une lib/framework/natif/version d'OS-SDK ou qu'un correctif a déjà échoué. Nouvelle règle
canonique path-scopée `doc-research-before-debug` (`software-architecture` **v1.4.0**),
**référencée** (non dupliquée) par `vf-debug` (pré-étape) + le routage `vibeflow-dev` + 6ᵉ
garde-fou autonome avec `maxResearchRoundsPerFlow` (`dev-orchestrator` **v1.4.0**), la boucle de
test mobile (gate `vf-test-orchestrator` + remontée `doc-research-required` de `vf-app-fixer`,
`mobile-test-team` **v1.1.0**), et la Phase 0 du template `debugger` (`reference` **v2.4.0**) ;
nouveau contrôle machine `check-debug-research.sh` branché en Phase 2 du validator (`conductor`
**v1.9.0**, `validator` **v1.2.0**).

## [v2.21.0] — 2026-07-08

+ **design-orchestrator** v1.0.0 : agent routeur `vibeflow-design` + verbe `/vf-design` (langage
naturel design → workflow), **générique multi-stack** (web/mobile/desktop), chaîne d'outils
design pilotée en coulisse avec dégradation gracieuse ; `dev-orchestrator` **v1.3.0** route les
phases de design vers `/vf-design` et installe `design-orchestrator` d'office (`requires`).

## [v2.20.0] — 2026-07-07

Milestone doctrine dev : `software-architecture` **v1.3.0** = foyer des philosophies de dev
(DRY/KISS/YAGNI ajoutés, Clean Architecture/Clean Code nommés, carte TDD, **gates Nyquist +
Decision Coverage absorbés**) ; module `feature-dev-gates` **supprimé** + nettoyage moteur des
modules retirés (rule orpheline nettoyée à `update --all`, test T7) ; `audit-architecture`
**v1.0.1** (Instance C dé-dupliquée, description legacy corrigée) ; `reference` source unique
des 3 axiomes d'enforcement.

## [v2.19.2] — 2026-07-07

Correctif : `/vf-update` fait désormais respecter le socle obligatoire — un module `mandatory`
publié après la config d'un lab (ex. `conductor` sur un lab antérieur à v2.13.0) était ignoré à
vie, ses scripts & hooks (le bandeau de mise à jour SessionStart) jamais câblés ; `update`
re-synchronise aussi la gouvernance des modules à jour (idempotent) (conductor v1.8.2).

## [v2.19.1] — 2026-07-07

Correctif : `vf-update` + docs utilisent l'identifiant complet `vibeflow@vibeflow-os` pour
`claude plugin update` (le nom nu peut échouer « Plugin not found » sur un cache de catalogue
périmé), avec note de dépannage (conductor v1.8.1).

## [v2.19.0] — 2026-07-07

Commande `/vf-update` + bandeau de mise à jour au démarrage : update deux couches en un geste
(cache marketplace du plugin + modules installés), dernière version détectée via les tags GitHub
(conductor v1.8.0).

## [v2.18.0] — 2026-07-07

Discipline de release (convention `vf-internal` : les workers internes n'ont plus de commande
d'incarnation ; conductor v1.7.0) + règle de tagging & guard du repo
(`scripts/check-release-tag.sh`, règle path-scopée).

## [v2.17.0] — 2026-07-07

+ mobile-test + mobile-test-team (boucle autonome test→fix mobile), dev-orchestrator v1.2.0
(vf-decide + garde-fous autonomes), reference v2.3.0 (Pattern 12), support engine multi-agents.

## [v2.16.0] — 2026-07-05

Agents natifs machine-enforced + doctrine de chargement contexte (ADR-044).

## [v2.15.1] — 2026-07-05

Guard Read : fenêtre bornée par VALEUR, pas par présence (BLK-007).

## [v2.15.0] — 2026-07-05

Guard Bash registres : fermeture du contournement shell (BLK-006).

## [v2.14.0] — 2026-07-04

Gouvernance scripturale : hooks auto-câblés + canon DECISIONS + guards registres (ADR-043).

## [v2.13.0] — 2026-06-29

Init : externalisation doc contextuelle + commandes d'incarnation native (ADR-042).

## [v2.12.0] — 2026-06-24

vf-new-lab v1.3.0 : Lab Factory, clarification-first.

## [v2.11.0] — 2026-06-23

planning-core v2.0.0 : topologie à compartiments + harmonisation branche main.

## [v2.10.0] — 2026-06-17

+ kpi-analyst (KPIs métier : déduits, déterministes, sourcés).

## [v2.9.0] — 2026-06-11

+ slash commands natives (`/vibeflow`, `/vf-new-lab`, `/vf-planning`, `/vf-calibrate`,
`/vf-audit`) — points d'entrée explicites des agents/skills méthodo.

## [v2.8.0] — 2026-06-11

+ 3 bundles métier (business-pilot / content / growth-par-canal) + conductor v1.1.0
(`vf-new-lab` bundle-aware, fix pointeur cassé).

## [v2.7.0] — 2026-06-11

+ conductor (orchestrateur méta/gardien) : bootstrap de lab universel (tout métier), propagation
update + migration, protocole d'escalade sous-agents.

## [v2.6.0] — 2026-06-11

planning-core v1.1.0 : garde-fou de fraîcheur (`check-planning-state.sh`) + détection métier +
bootstrap opt-in + exemple non-dev travaillé.

## [v2.5.0] — 2026-06-10

+ planning-core (socle `.planning/` universel, adaptatif par métier, 3 profils de rigueur) —
ADR-038.

## [v2.4.2] — 2026-06-06

Commande engine `uninstall --all` + flux de désinstallation dans `/vibeflow-install` + doc
désinstallation 2 couches.

## [v2.4.1] — 2026-06-06

`/vibeflow-install` 100 % manuel, distribuable isolé sous `plugin/`, clean reliquats.

## [v2.4.0] — 2026-06-05

Installation en 2 commandes : plugin Claude Code + `/vibeflow-install` à toggles.

## [v2.3.0] — 2026-06-04

+ dev-orchestrator (routeur NL → GSD + Superpowers, 13 verbes `/vf-*`).

## [v2.2.0] — 2026-06-03

+ audit-architecture, validator v1.1.0 (Phase 4 scan des process).

## [v2.1.0] — 2026-05-28

+ software-architecture, type `rules/` dans l'installer, Core v4.2 (P9).

## [v2.0.0] — 2026-05-24

+ skill-creator (multi-skills), + reference (doc-only), nouveau type de module.

## [v1.2.1] — 2026-05-24

Fix `vibeflow-update.sh` (handle `AGENT.md`).

## [v1.2.0] — 2026-05-24

+ validator (agent-only).

## [v1.1.0] — 2026-05-24

+ infrastructure-audit.

## [v1.0.0] — 2026-05-23

Release initiale : consolidator.
