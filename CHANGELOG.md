# Changelog — vibeflow-os

Historique des versions du **repo** (canon unique — les deux README n'affichent que les 3
dernières entrées et pointent ici). Chaque module a par ailleurs son propre `CHANGELOG.md`
sous `plugin/<module>/`. Rappel : toute release = un tag git annoté `vX.Y.Z`
(`scripts/check-release-tag.sh`).

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
