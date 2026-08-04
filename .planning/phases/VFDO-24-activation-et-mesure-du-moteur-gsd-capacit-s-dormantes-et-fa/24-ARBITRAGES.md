# Phase 24 — Fiche d'arbitrage

**Établie le :** 2026-08-04, contre `@opengsd/gsd-core@1.9.1` et le dépôt en `v2.47.1`
**Pour :** Samuel — **6 questions fermées, un seul passage**
**Par :** `vf-coder` (cadrage seul — aucune de ces décisions n'a été tranchée par l'agent)

> **Mode d'emploi.** Les 11 items de la Phase 24 (M1, M2, M3 + A1→A9) sont regroupés en **6 zones**.
> M2 est déjà mesuré et arbitré le 2026-07-31 — il n'apparaît pas ici. Chaque zone tient en **une
> question fermée** ; les options sont **mutuellement exclusives**. Les faits ont tous été
> **re-vérifiés sur disque le 2026-08-04** : le détail et les preuves sont dans `24-CONTEXT.md`
> (fiches `F-01` à `F-38`). **8 faits du ROADMAP sur 23 ont péri en 4 jours** — les valeurs
> ci-dessous priment sur celles du ROADMAP.

---

## Zone 1 — Comment notre doctrine de dev atteint les agents du moteur

**Items couverts :** A2 (`agent_skills`) · A3 (`workflow.tdd_mode`)

### État de fait re-vérifié

| Fait | Statut | Valeur au 2026-08-04 |
|---|---|---|
| `buildAgentSkillsBlock`, 17 slots, forme `global:<plugin>:<skill>` | **CONFIRMÉ** | `init.cjs:1731-1815` |
| Workflows consommateurs | **PÉRIMÉ** | **30**, pas 19 — le canal a grossi en 1.9.1 |
| `agent_skills` dans notre config | **CONFIRMÉ** | `{}` — vide |
| Le digest de mission transmet la doctrine de dev | **CONFIRMÉ FAUX** | Il borne les conventions à 2-3 lignes du `CLAUDE.md` (`mission-contracts.md:62`), plafond ≤ 30 lignes (`:51`). Notre `CLAUDE.md` ne contient ni SOLID, ni DRY, ni KISS, ni YAGNI, ni Clean Archi, ni TDD. |
| Le slot `EXECUTOR` est atteignable depuis `vf-coder` | **NON — fait nouveau, décisif** | L'injection ne vit que dans le prompt de dispatch d'`execute-phase.md:86,715`. `gsd-executor` et `gsd-planner` ont été **retirés de l'allowlist de `vf-coder`** en Phase 23 (vérifié de première main). Le repli est l'inline séquentiel (`execute-phase.md:28-31`) — **sans injection**. |
| Le slot `PLANNER` est atteignable | **OUI** | `plan-phase.md:74`, injections `:769` et `:1247`. |
| Recouvrement existant | **PARTIEL** | `gsd-planner` reçoit déjà `codebase/CONVENTIONS.md` + `ARCHITECTURE.md` (`gsd-planner.md:635-653`) — densité, portabilité, commits, mais **pas** SOLID/DRY/KISS/YAGNI. |
| `tdd_mode` ajoute la doctrine TDD à l'exécuteur | **CONFIRMÉ FAUX** | `references/tdd.md` (330 l.) est déjà injecté **sans condition** (`execute-phase.md:693`). `tdd_mode` n'ajoute que le tag `type: tdd` au planner + un gate `execute:post` **non bloquant** (`onError: skip`). |
| Éligibilité TDD amont vs locale | **DIVERGENTE** | Amont : par type de tâche (business logic → `tdd` ; glue/config/CRUD → `execute`). Local : par **critère mesurable** (`principles.md:61-63`). Sur ce dépôt (bash + markdown), **aucune des 7 catégories amont ne correspond** — l'heuristique classerait presque tout en `execute`. |

### ❓ Question — Comment la doctrine de dev atteint-elle les agents du moteur ?

| | Option | Coût réel | Conséquence |
|---|---|---|---|
| **A** | **Slot PLANNER seul, sans `tdd_mode` — canal unique prouvé** | 1 clé de config + 1 cas de test | La doctrine atteint l'agent qui **écrit le plan**. L'exécuteur reste au régime actuel. |
| **B** | **Slots PLANNER et EXECUTOR, allowlist `vf-coder` rouverte, sans `tdd_mode`** | 1 clé + réouverture d'une allowlist **fermée en Phase 23** + cas de test | Portée maximale, mais **rouvre une décision de la phase précédente** et remet `gsd-executor` en dispatch direct. |
| **C** | **Slot PLANNER plus `tdd_mode` activé — planification et typage des tâches** | Option A + 1 clé | Ajoute un typage `type: tdd` que l'heuristique amont ne posera quasi jamais sur ce dépôt. |
| **D** | **Rien : acter le refus des deux canaux, doctrine par digest** | 1 ligne de doctrine + 1 ADR | Écrit **pourquoi** le canal reste vide. Zéro changement de comportement. |

### Recommandation — **A**

Le canal `agent_skills` est **le plus fort levier qualité de tout l'audit**, mais seulement là où il
est prouvé : `gsd-planner` est l'agent qui décide de la découpe et des tâches, et c'est le seul des
deux dont l'injection est atteignable aujourd'hui sans défaire une décision de la Phase 23. L'option
B paie une réouverture d'allowlist pour un canal dont F-13 montre qu'il pourrait tomber en
vert-à-vide sur notre chemin réel — mauvais rapport risque/gain. L'option C ajoute un toggle dont
F-18 établit que l'essentiel (la doctrine TDD elle-même) est **déjà injecté sans lui**, et dont
l'heuristique est calibrée pour des dépôts applicatifs, pas pour du bash et du markdown.

**Si A est retenue, devient impossible :** prétendre que la doctrine atteint le code — elle
atteindra le **plan**, pas l'exécution. Il faudra l'écrire tel quel et ne plus présenter A2 comme
résolu côté exécuteur.

---

## Zone 2 — Ce que la machine bloque, et ce qu'elle se contente de signaler

**Items couverts :** A1 (`workflow.windows_enforce`) · A5 (`hooks.community`, `hooks.workflow_guard`)

### État de fait re-vérifié

| Fait | Statut | Valeur au 2026-08-04 |
|---|---|---|
| `.planning/WINDOWS.md` → `open_count` | **PÉRIMÉ** | **`1`**, pas 2 (`fixed: 4`, `total: 5`) |
| Nature de la fenêtre encore ouverte | **fait nouveau, décisif** | **#3** — recette humaine XcodeBuildMCP sur lab iOS équipé. **Non fermable dans ce dépôt** (aucun `.mcp.json`, aucun projet iOS). |
| Le gate `ship:pre` correspond au ledger | **CONFIRMÉ** | `artifact-frontmatter-equals`, `WINDOWS.md`, `open_count`, `equals: 0`, `blocking: true`, `onError: halt`, `when: workflow.windows_enforce` (défaut `false`, issue #1950) |
| Les deux hooks A5 sont « installés et inertes » | **PÉRIMÉ — nuance** | Ils sont **posés** en `PreToolUse` dans `~/.claude/settings.json`, et s'**auto-gatent** sur le config (`gsd-validate-commit.sh:12-17`, `gsd-workflow-guard.js:70-79`). **Les activer = une clé, aucune édition de `settings.json`.** |
| « Le lab impose des commits conventionnels — un gate existe » | **CONFIRMÉ FAUX** | **Aucun gate de message de commit dans ce dépôt.** Les 6 `plugin/*/hooks/hooks.json` n'en déclarent aucun ; `scripts/hooks/pre-push` est le gate de tag. C'est une **consigne** du `CLAUDE.md`. |
| Compatibilité de notre style avec le hook amont | **fait nouveau, décisif** | Sur **109 commits locaux** : **23 échouent sur le type** (`release:`, `planning:`, `doctrine:`, `bump(…)`, `spec(…)`, `plan(…)` — six types que nous employons, absents de la liste amont) et **76/109 = 69 % dépassent 72 caractères**. |

### ❓ Question — Que bloque la machine, et que se contente-t-elle de signaler ?

| | Option | Coût réel | Conséquence |
|---|---|---|---|
| **A** | **Rien de bloquant — les trois restent en signalement** | 1 ligne de doctrine + 1 ADR | Cohérent avec ADR-031 et avec les hooks *advisory* du module. Zéro friction. |
| **B** | **`windows_enforce` activé seul, après avoir soldé ou dérogé #3** | 1 clé + une dérogation tracée (`windows waive 3 "<raison>"`) | Le ship bloque sur toute fenêtre ouverte. **Exige de traiter #3 d'abord** — sinon `/gsd-ship` est mort. |
| **C** | **`windows_enforce` plus `workflow_guard`, `community` refusé pour incompatibilité de style** | 2 clés + dérogation #3 + 1 ADR sur le refus | Enforcement là où il ne coûte rien, refus documenté là où il coûterait 69 % de l'historique. |
| **D** | **Les trois activés, et notre style de commit réaligné sur amont** | 2 clés + réécriture de la convention de commit du `CLAUDE.md` + 6 types abandonnés | Conformité maximale, au prix de notre vocabulaire de commit et de sujets ≤ 72 car. |

### Recommandation — **C**

`windows_enforce` est « le plus actionnable de la phase » — mais **seulement après** avoir traité la
fenêtre #3, qui est structurellement infermable ici : l'activer sans elle, c'est se donner un
`/gsd-ship` définitivement bloqué. La dérogation existe pour ça (`gsd-tools windows waive`, raison
obligatoire) et laisse une trace honnête. `workflow_guard` est gratuit et ne touche pas au style.
`community` est le seul des trois dont la mesure dit **non** sans ambiguïté : nos six types de
commit maison (`release:`, `planning:`, `doctrine:`, `bump`, `spec`, `plan`) ne sont pas dans la
liste amont, et la contrainte des 72 caractères casse 69 % de nos sujets — un gate qu'on doit
contourner tous les jours est un gate qu'on finit par désarmer. Le refuser **et écrire pourquoi**
vaut mieux que l'activer et le subir.

**Si C est retenue, devient impossible :** invoquer plus tard « le lab impose des commits
conventionnels » comme une garantie machine — ce sera explicitement une consigne humaine, et
`24-CONTEXT.md` F-25 le dit déjà.

---

## Zone 3 — Les trois routes qui mènent à un geste inerte

**Items couverts :** A7 (`intel`) · A8 (`graphify`, `profile-pipeline`) — **plus une troisième route
non vue par le ROADMAP**

### État de fait re-vérifié

| Fait | Statut | Valeur au 2026-08-04 |
|---|---|---|
| `intel.enabled` / `graphify.enabled` / `profile-pipeline.enabled` | **CONFIRMÉ** | Toutes `false` par défaut, **absentes** de notre config. `.planning/intel/` n'existe pas. |
| Routes mortes dans `intent-routing.md` | **CONFIRMÉ** | `:104` → `gsd-graphify` · `:147` → `gsd-profile-user` |
| **Troisième route morte** | **fait nouveau** | Notre `docs-flow.md:43-44` publie `--query` (`term`/`status`/`diff`/`refresh`) comme l'un des **deux modes normaux** de `gsd-map-codebase`. Or `gsd-map-codebase/SKILL.md:29` : « **Requires intel to be enabled (`intel.enabled: true`)** ». **Notre propre doc promet un geste inerte.** |
| « Le test vérifie que le skill est routé » | **PÉRIMÉ — à la baisse** | `test-dev-orchestrator.sh` (5727 l., 150 cas) **ne nomme ni `graphify` ni `gsd-profile-user`**. Et `gsd-capabilities-index.md` (111 l., Phase 23) **ne mentionne aucune des deux**, alors qu'il liste `intel`, `tdd`, `broken-windows`. Le gate T14 (`:1289-1321`) compte les briques routées sans jamais interroger leur activation. |
| Frontière `codebase/` ↔ `intel/` | **CONFIRMÉE, nette** | `codebase/` = 7 markdown de **jugement humain daté** (Tech Debt, Scaling Limits, Architectural Constraints), **lecteurs prescrits nommément** (`vf-dev-manager.md:32`, `vf-auditer.md:3,23`, `check-dev-bootstrap.sh:27`, `gsd-planner.md:635-653`). `intel/` = 5 **JSON machine** + `API-SURFACE.md`, horodatés/hashés, **temporel interdit** (`gsd-intel-updater.md:39`), **un seul** consommateur auto, marqué « HINT ONLY … MAY BE INCOMPLETE ». |

### ❓ Question — Que fait-on des trois routes qui mènent à un geste inerte ?

| | Option | Coût réel | Conséquence |
|---|---|---|---|
| **A** | **Activer `intel`, refuser `graphify` et `profile-pipeline`, gate d'activation ajouté** | 1 clé + 2 entrées marquées conditionnelles + extension du test T14 | `--query` tient sa promesse ; les deux autres sont honnêtement marquées ; le trou se referme pour l'avenir. |
| **B** | **Refuser les trois, marquer les entrées conditionnelles, gate d'activation ajouté** | 3 entrées marquées + extension T14 + 1 ADR | Zéro nouveau comportement. Mais `docs-flow.md` doit **retirer** `--query` de ses deux modes normaux. |
| **C** | **Activer les trois capabilities et laisser la doc telle quelle** | 3 clés | Trois nouveaux artefacts (`intel/`, graphe, profil) sans lecteur prescrit, et le trou de test reste ouvert. |
| **D** | **Retirer les entrées de doc et de routage, sans gate** | 3 suppressions | Le symptôme disparaît, la cause non : le prochain skill ajouté rouvre exactement le même trou. |

### Recommandation — **A**

La frontière `codebase/` ↔ `intel/` n'est pas floue, elle est **déjà tracée par les formats** :
jugement humain daté d'un côté, fait dérivé rafraîchissable de l'autre. Ils ne se recouvrent pas, et
la question « que ferait `intel` que `codebase/` ne fait pas » a une réponse concrète — le mode
`--query` que **nous documentons déjà comme normal**. Refuser `intel` (option B) obligerait à
retirer de `docs-flow.md` une capacité qu'on a choisi d'y publier ; l'activer coûte une clé.
`graphify` et `profile-pipeline`, eux, n'ont **aucun consommateur prescrit** dans le module et n'ont
même pas atteint l'index de la Phase 23 — les activer (option C) créerait de l'artefact sans
lecteur. L'option D traite le symptôme et laisse la cause : **le point commun des trois routes est
qu'aucun gate ne relie une entrée de doc à l'activation de sa capability** — c'est ce gate qui est le
vrai livrable de la zone, et il est le même dans les options A et B.

**Si A est retenue, devient impossible :** garder `graphify` et `profile-pipeline` hors de
`gsd-capabilities-index.md` — l'index généré (D-07, Phase 23) devra les porter avec leur état, sinon
le gate d'activation n'a rien à lire.

---

## Zone 4 — Les réglages du moteur que nous ré-implémentons en doctrine

**Items couverts :** A4 (profils de contexte) · A6 (`workflow.inline_plan_threshold`)

### État de fait re-vérifié

| Fait | Statut | Valeur au 2026-08-04 |
|---|---|---|
| « Le moteur porte en config ce que nous ré-implémentons en doctrine » (A4) | **PÉRIMÉ — le fait s'inverse** | Les 3 profils existent, la clé `context` est validée (`config.cjs:690-692`) et documentée (`planning-config.md:241`) — mais la recherche exhaustive sur tout `~/.claude/gsd-core`, `~/.claude/agents` et `~/.claude/skills` ne rend que **3 hits, tous auto-déclaratifs**. **Aucun consommateur n'existe.** Le moteur ne le *porte* pas, il le *déclare*. |
| Forme incompatible avec Pattern C | **CONFIRMÉ** | Profil = **scalaire global** (une valeur pour tout le projet) ; Pattern C = **contrat par rôle** (4 rôles, schéma JSON — `mission-flow.md:136-152`). Comparer à `agent_skills`, qui est bien une map par agent. |
| Verbosité | **CONFIRMÉ, contradiction directe** | `dev.md:21` « Low » ✔ compatible ; `research.md:20-23` « **High** … Include background context even if the developer likely knows it » ✘ frontalement contraire à `mission-flow.md:139-142` (« la prose libre est du volume mort »). Sévérités divergentes aussi : `blocking/important/nit` vs `bloquant/majeur/mineur`. |
| `inline_plan_threshold` | **CONFIRMÉ** | Défaut **2**, plage `0`–`10` (`planning-config.md:41,276`), appliqué `execute-plan.md:94,100` (« ~14K token subagent spawn overhead »). |
| Portée réelle sur nos plans | **MESURÉ** | Sur les 32 `*-PLAN.md` des phases 20-26, regex exacte du moteur : **≤ 2 tâches → 4 plans sur 28 exécutables (14 %)** ; **mode à 3 tâches (20 plans)** — juste au-dessus du seuil. (4 plans à « 0 tâche » sont des rétro-plans de Phase 21 sans balise `<task>` : artefact de format, pas petitesse.) |
| Le seuil contredit-il la délégation systématique ? | **NON** | La doctrine vise l'**acteur** (`AGENT.md:165-166,172`) ; le seuil est lu **dans** la brique, après qu'elle a été atteinte (`GSD-PIPELINE.md:188-199`). |

### ❓ Question — Réglages du moteur : adopte-t-on, ou acte-t-on notre doctrine ?

| | Option | Coût réel | Conséquence |
|---|---|---|---|
| **A** | **Refuser les profils, garder le seuil inline par défaut 2** | 1 ADR sur le refus | Statu quo assumé et écrit. 14 % des plans continuent de s'exécuter inline. |
| **B** | **Refuser les profils, mettre le seuil à 0 — délégation toujours** | 1 ADR + 1 clé | Aucun plan n'échappe au sous-agent : isolation de contexte homogène, au prix de ~14 K tokens sur 4 plans sur 28. |
| **C** | **Refuser les profils, monter le seuil à 3 — économie maximale** | 1 ADR + 1 clé | Le mode de nos plans (20 sur 28) bascule inline : économie forte, mais l'isolation de contexte disparaît sur la majorité des plans. |
| **D** | **Adopter `context: dev` et garder le seuil par défaut** | 1 clé + 1 ligne de doctrine | Pose une clé **qu'aucun code ne lit** aujourd'hui. |

### Recommandation — **A**

Sur A4, le fait s'est inversé pendant le cadrage et il tranche la question tout seul : on ne peut pas
« adopter ce que le moteur porte en config » quand **rien ne lit la clé**. L'option D poserait un
réglage décoratif — et si le canal s'implémentait un jour en amont, `research.md` (« Verbosity High,
include background context ») entrerait en collision frontale avec Pattern C. Le bon livrable est
d'**écrire que notre contrat typé est plus strict, per-rôle, et pourquoi** — c'est exactement ce que
le ROADMAP proposait en alternative.

Sur A6, le seuil ne contredit rien (F-23) et la mesure montre un levier **étroit** : 4 plans sur 28.
Le monter à 3 (option C) ferait basculer le mode de nos plans vers l'inline — gain de tokens réel,
mais on perd l'isolation de contexte sur 71 % des plans pour économiser sur des plans qui ne sont pas
notre coût dominant. Le mettre à 0 (option B) achète une homogénéité qui n'a pas de problème constaté
à résoudre. **Ne pas toucher un réglage dont on vient de mesurer qu'il mord peu** est ici le choix
informé, pas le choix paresseux — et la mesure elle-même est le livrable.

**Si A est retenue, devient impossible :** présenter A6 comme un « levier de coût inconnu » — il est
désormais chiffré, et tout retour dessus devra citer la mesure, pas la rouvrir.

---

## Zone 5 — Chantiers parallèles : les workstreams

**Item couvert :** A9

### État de fait re-vérifié

| Fait | Statut | Valeur au 2026-08-04 |
|---|---|---|
| PR #27 | **PÉRIMÉ — fait le plus important du re-constat** | **CLOSE** depuis le **2026-08-03T06:56:32Z** (`isDraft: true`, `reviewDecision: CHANGES_REQUESTED`, `mergedAt: null`). Jamais mergée, plus ouverte. **Le statu quo de fait est aujourd'hui le refus.** |
| Couverture amont | **PÉRIMÉ — bien pire que 18 %** | Re-mesure `awk`+`comm` sur les **91 workflows racine** (compte confirmé) : **7 connaissent** les workstreams, **45 codent en dur** `.planning/ROADMAP.md`/`STATE.md`/`phases`, dont **42 sans aucune conscience** (`execute-phase`, `execute-plan`, `plan-phase`, `discuss-phase`, `next`, `ship`, `pr-branch`, `quick`, `progress`, `complete-milestone`…). **Couverture réelle : 7/91 = 7,7 %.** |
| Notre outillage est aveugle | **CONFIRMÉ par lecture ; symptôme NON re-mesuré** | `check-dev-bootstrap.sh:111` (`"$PLANNING_DIR/ROADMAP.md"` en dur) ; `check-state-integrity.sh:53` (`FILE_REL=".planning/STATE.md"` en dur, 6 sorties `exit 2`). **Les deux gates sont VERTS aujourd'hui** dans l'arbre non partitionné. Reproduire le rouge exigerait de partitionner `.planning/` — **hors périmètre de ce nœud**. |
| `/gsd-pr-branch` s'inverse | **CONFIRMÉ** | Regex ancrées à `^\.planning/(STATE\|ROADMAP\|MILESTONES\|PROJECT\|REQUIREMENTS)\.md` — **`pr-branch.md:235-236`** (et non `:232-234` : les lignes ont glissé en 1.9.1). `.planning/workstreams/dev/STATE.md` ne matche plus `STRUCTURAL` → **transient → EXCLUDED**, les commits de feuille de route disparaissent des branches de PR. |
| Le pointeur ne vit pas où on croit | **CONFIRMÉ** | `os.tmpdir()/gsd-workstream-sessions/<sha1(realpath du .planning) tronqué 16>/<clé>` (`active-workstream-store.cjs:98-108`) — effacé au reboot, **indexé sur le chemin absolu, donc distinct par worktree et jamais hérité**. |
| Notre couche | **CONFIRMÉ** | Exactement **3 fichiers** de tout `plugin/` mentionnent « workstream », **tous des tables de routage**. Aucun agent `vf-*` ne sait passer `--ws`. `vf-dev-manager.md` lit les chemins racine en dur — **5 occurrences**, pas 7. |
| Recouvrement | **CONFIRMÉ** | Avec **ADR-064** (« un écrivain = un worktree », quick `260801-17w`), pas avec le moteur. Le pointeur étant indexé sur le chemin du `.planning`, **chaque worktree ouvre sans workstream résolu**. Et M2 a établi que le parallélisme **inter-nœuds** est le seul effectif sur ce runtime — **le seul étage qui marche est celui que la partition fragilise le plus.** |

### ❓ Question — Workstreams : adopter, refuser ou borner ?

| | Option | Coût réel | Conséquence |
|---|---|---|---|
| **A** | **Refuser, acter ADR-064 comme réponse unique aux chantiers parallèles** | 1 ADR + 1 ligne dans les 3 tables de routage | Une seule réponse au problème, physique et déjà en place. Les chantiers parallèles passent par des jalons distincts dans une ROADMAP partagée. |
| **B** | **Borner à un usage restreint, en listant les workflows interdits** | Lister et maintenir **42 workflows interdits** contre une cible amont mouvante | Usage possible mais sous contrainte que personne ne peut vérifier à l'exécution. |
| **C** | **Adopter et payer la mise à niveau de toute notre couche** | `check-dev-bootstrap.sh` + `check-state-integrity.sh` + `planning-context.sh` workstream-aware, `--ws` câblé dans les agents `vf-*`, gate sur le pointeur, CI étendue | Le lab tourne contre une chaîne d'outils couverte à 7,7 % — le cas que l'**Iron Law 2** interdit (`conductor/AGENT.md:114`). |
| **D** | **Refuser maintenant, remonter les 42 workflows aveugles en amont** | Option A + une remontée sourcée à `@opengsd/gsd-core` | Même posture que la voie 2 de M2 (déjà retenue) : bénéfice collectif, et rouvre la question quand la couverture aura monté. |

### Recommandation — **D**

Trois faits convergent et rendent l'adoption indéfendable aujourd'hui : la couverture amont mesurée
est de **7,7 %**, pas 18 % ; la **PR #27 est close** — plus personne ne porte la proposition ; et
**ADR-064 traite déjà le même problème** par l'isolation physique, tranché il y a trois jours. S'y
ajoute l'argument le plus lourd : le pointeur étant indexé sur le chemin absolu du `.planning`,
workstreams et worktrees **ne se composent pas** — et M2 a établi que le parallélisme inter-nœuds
porté par `vf-dev-manager` est le **seul effectif** sur ce runtime. On fragiliserait le seul étage
qui fonctionne. L'option B demande de maintenir à la main une liste de 42 exclusions contre une
cible qui bouge à chaque version amont : c'est un gate qu'on ne peut pas tenir.

**D plutôt que A** parce que le refus sec laisse le problème entier chez l'amont sans rien lui
rendre, alors que nous avons une mesure reproductible (7/91, méthode `awk`+`comm`) qui vaut d'être
remontée — exactement le patron déjà retenu pour M2 voie 2 et pour la RFC de la Phase 18.

**Si D est retenue, devient impossible :** relancer une partition de `.planning/` dans ce dépôt sans
rouvrir l'ADR — et la condition commune à toutes les options reste vraie de toute façon : **aucune
partition tant qu'une phase est en vol** (`git merge-tree` sort **exit 0** sur une divergence
post-partition : Git ne signale rien).

---

## Zone 6 — Les faits de runtime par rôle, écrits nulle part

**Items couverts :** M1 (profondeur de dispatch) · M3 (`effort:`)

### État de fait re-vérifié

| Fait | Statut | Valeur au 2026-08-04 |
|---|---|---|
| Descripteur de dispatch en 1.9.1 | **CONFIRMÉ, inchangé** | `{ nested: true, maxDepth: 5, subagentToolkit: "full", background: true, backgroundDispatch: false, isolation: "harness-worktree" }` |
| Consommation réelle | **CONFIRMÉ** | `vf-dev-manager → vf-coder → agent gsd-*` = **3 niveaux sur 5**, **deux de marge**. Écrit **nulle part** dans le module : ni la limite, ni la marge, ni ce qu'elle autorise (un worker pourrait légitimement dispatcher un sous-worker). |
| `effort:` sur les agents livrés | **CONFIRMÉ** | **0 sur 25** (`plugin/*/agents/*.md`). |
| **Mais** | **fait nouveau, change la nature du travail** | La sonde élargie (49 fichiers) trouve **3 agents-templates qui en portent déjà un** : `business-agent-template.md` (`medium`), `clarity-feature-template.md` (`high`), `orchestrator-template.md` (`high`). **Le barème par rôle existe déjà dans nos propres templates** — les modules ne l'ont jamais appliqué. Ce n'est pas une doctrine à inventer, c'est une doctrine à **propager**. |
| Support machine | **CONFIRMÉ** | Harness : `agentFrontmatterExtensions: ["effort"]`. Notre gate valide déjà : `check-agents.sh:514-516`, `low\|medium\|high\|xhigh\|max`. Les skills GSD l'emploient (`effort: max` sur `gsd-plan-phase`). |

### ❓ Question — Faits de runtime par rôle : que grave-t-on dans les agents ?

| | Option | Coût réel | Conséquence |
|---|---|---|---|
| **A** | **Écrire la marge de profondeur, et `effort:` par rôle sur tous** | 1 ligne de doctrine + 25 frontmatters + cas de test d'exhaustivité | Pilotage et jugement en haut, exécution mécanique en bas. Le barème des templates devient la règle. |
| **B** | **Écrire la marge de profondeur seulement, `effort` laissé au défaut** | 1 ligne de doctrine | Clôt la question du nesting. Managers et juges continuent à l'effort par défaut. |
| **C** | **`effort:` par rôle seulement, la marge reste non écrite** | 25 frontmatters + cas de test | Gain de qualité/coût par rôle, mais la limite de profondeur reste un savoir tacite. |
| **D** | **Ni l'un ni l'autre — statu quo documenté nulle part** | 0 | Les deux faits restent tacites, comme aujourd'hui. |

### Recommandation — **A**

Les deux items sont du même genre — un fait de runtime que le moteur expose, que notre gate valide
déjà, et que zéro fichier du module énonce — et ils se livrent au même endroit, pour un coût presque
entièrement partagé. M1 « clôt la question du nesting posée à l'ouverture de l'audit » : ne pas
l'écrire, c'est garantir qu'elle se repose. M3 n'est plus un choix de barème depuis que le cadrage a
trouvé les 3 templates qui en portent déjà un — il ne reste qu'à **propager un barème existant** aux
25 agents livrés, avec le gate qui le tient. Le ROADMAP le dit bien : **à trancher par rôle**
(pilotage et jugement haut, exécution mécanique bas), **jamais uniformément**.

**Si A est retenue, devient impossible :** ajouter un agent sans déclarer son `effort:` — il faudra
étendre `check-agents.sh` de « valide si présent » à « exige », et ce durcissement est lui-même une
décision que le plan devra porter jusqu'au bout (25 agents, aucun laissé de côté).

---

## Ce qui n'est PAS remonté ici (tranché par le plan seul)

Noms de fichiers et de clés · forme et emplacement des cas de test · rédaction exacte des lignes de
doctrine · découpage en plans et leur ordre · numérotation des ADR · choix entre étendre un fichier
de référence existant et en créer un (sous ADR-057, « une capacité, une seule voix ») · formulation
de la raison de dérogation `windows waive` · libellés des entrées conditionnelles de routage.

## Points qui ne se referment pas sans accès web

- **État de la PR #27** — lu via `gh` (CLOSE au 2026-08-03). La **raison** de la fermeture (retrait
  par l'auteur ? décision de Samuel ?) n'est pas lisible depuis les métadonnées et pèse sur la
  formulation de l'ADR de la zone 5.
- **Issues amont #853, #1950, #2608** — citées par le ROADMAP et par les descriptions de capability.
  Leur état courant conditionne la voie 2 de M2 (déjà retenue) et la remontée de la zone 5 option D.
- **Doc amont `@opengsd/gsd-core`** sur le canal `context:` — savoir s'il s'agit d'une clé
  **abandonnée** ou **pas encore câblée** change le libellé de l'ADR de la zone 4 (refus définitif vs
  refus daté).
