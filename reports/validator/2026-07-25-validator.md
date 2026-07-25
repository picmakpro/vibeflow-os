# Validator Report — 2026-07-25

> Cible : **repo de distribution** `vibeflow-os` @ `v2.31.1` (pas un lab qui installe le plugin).
> Périmètre adapté : agents/skills sous `plugin/*/agents|skills/`, doctrine sous `plugin/reference/`,
> planning sous `.planning/`.
> Iron Law respectée (ADR-031) : **ce rapport détecte et propose. Aucun fichier n'a été modifié.**

## Status global : WARN
## Score : 58 / 100

| Phase | Poids | Score | Commentaire |
|---|---:|---:|---|
| 1. Infrastructure | 20 | 14 | 1 test **rouge sur `main`**, whitelist périmée, aucun CI |
| 2. Densité + conformité agents | 20 | 19 | **Conformité ADR-029 totale** |
| 3. Dette documentaire | 25 | 8 | Doc utilisateur massivement fausse |
| 4. Architecture d'audit des process | 20 | 7 | **Le point noir** — gates au vert sans rien vérifier |
| 5. Gouvernance / cohérence release | 15 | 10 | Versions et tags impeccables, mais enforcement non câblé |

**Le constat central**, qui relie presque tous les findings :

> Ce repo **écrit et distribue** la meilleure doctrine d'enforcement que contienne l'écosystème
> (`plugin/audit-architecture/`, `AXIOMES-ENFORCEMENT.md`) — et **ne se l'applique pas à lui-même**.
> Zéro CI, `core.hooksPath` non configuré, `reports/validator/` vide avant aujourd'hui. Les gates
> existent, sont bien écrits, sont testés — et **rien ne les appelle**. Quand on les appelle à la
> main depuis la racine, la majorité rend un **vert non mérité**.

C'est l'Axiome 2 du repo qui se retourne contre lui
(`plugin/reference/content/methodology/AXIOMES-ENFORCEMENT.md:27-28`) : *« un filet décoratif
(présent mais non exécuté) est pire que pas de filet — il donne une fausse assurance. »*

**Pourquoi WARN et pas FAIL** : le repo lui-même reste cohérent — versions, tags, synchro bilingue et
CHANGELOG tous verts, aucun script cassé.
**Gate de release** : F3, F4 et P1-e sont **bloquants pour la prochaine release**.

---

## Phase 1 — Infrastructure

| Vérification | Résultat |
|---|---|
| `scripts/check-version-sync.sh` | ✓ `v2.31.1`, 17 modules, badges EN+FR alignés |
| `scripts/check-release-tag.sh` | ✓ `VERSION=v2.31.1 ↔ tag v2.31.1` |
| Syntaxe `bash -n` (tous les `.sh`) | ✓ 0 échec |
| Dépendances (`bash awk grep sed python3 jq git`) | ✓ toutes présentes |
| Discipline `jq` nu interdite (ADR-054) | ✓ wrapper `jqx` correct (`plugin/_internal/resolve-deps.sh:27`) |
| Hooks livrés | ✓ 14 scripts `{{VF_SCRIPTS}}/*.sh`, tous présents |
| Suites de tests | **30 pass / 1 fail** |

### Findings

- **P1-e (ERROR) — un test est rouge sur `main`.**
  `plugin/conductor/scripts/tests/test-vf-update.sh` → `== Résultat : 8 OK · 1 KO ==` (reproduit).
  Cause : fuite d'isolation — `plugin/conductor/scripts/update-banner.sh:16` appelle
  `check-legacy.sh`, qui scanne le **vrai `~/.claude` de la machine**, non stubé par le test. Le test
  est donc **vert ou rouge selon le poste**. Sans CI conteneurisée, personne ne le voit.
- **P1-a (WARNING) — whitelist runtime en retard de 5 versions.**
  `claude --version` = **2.1.220** ; `plugin/infrastructure-audit/scripts/known-versions.txt` s'arrête
  à **2.1.215**. Tout lab qui lance `audit-infra.sh` aujourd'hui reçoit un faux « version inconnue ».
  Un WARNING qui se déclenche pour tout le monde cesse d'être un signal.
- **P1-b (WARNING) — aucun CI.** Pas de `.github/`, pas de `Makefile`, pas de `package.json`. Les
  **31 suites de tests** n'ont **aucun runner agrégateur**. Le mot « test » n'apparaît pas une seule
  fois dans `CLAUDE.md`.
- **P1-c (WARNING) — le seul garde-fou machine n'est pas activé.**
  `git config --get core.hooksPath` → **vide** ; `.git/hooks/` ne contient que des `.sample`.
  `scripts/hooks/pre-push:5-6` l'assume : « Opt-in, non installé par défaut. »
- **P1-d (INFO)** — `plugin/_internal/tests/test-vibeflow-update.sh` n'est pas exécutable.

> Note de qualité : les tests sont **bien écrits** (pattern `ok()`/`ko()`, fixtures `mktemp -d` +
> `trap`, verdict final propagé en exit code). Le problème n'est pas leur facture, c'est qu'ils
> n'existent pour personne.

---

## Phase 2 — Densité + conformité agents

**Verdict : conformité ADR-029 pleine et entière.** La phase la plus saine du repo.

| Élément | Plafond | Pire cas réel | Statut |
|---|---:|---|---|
| Agents livrés | 250 L | **124 L** (`plugin/dev-orchestrator/agents/vf-dev-manager.md`) | ✓ marge 50 % |
| `SKILL.md` | 500 L | **485 L** (`plugin/skill-creator/skills/skill-creator/SKILL.md`) | ✓ |

Les 7 agents réellement livrés (`dev-orchestrator` ×4, `mobile-test-team` ×3) sont entre 37 et 124
lignes. Les seuils documentés dans
`.../templates/skills/agent-density-auditor/references/thresholds.md` correspondent exactement à la
charte (250 / 500 / 2000 tokens).

### Faux positifs écartés (à ne pas re-signaler)

Un glob naïf sur `*/agents/*.md` remonte 5 fichiers > 250 L. **Aucun n'est un agent** :

- `templates/agents/contracts-template.md` (685 L) — protocole de contrats.
- `templates/agents/_reference/lead-knowledge.md` (529 L) — se déclare ligne 4 « Ce document n'est
  **PAS** un agent ».
- `skill-creator/agents/{analyzer,grader,comparator}.md` (274/223/202 L) — sous-agents vendored
  d'Anthropic, invoqués par prompt explicite.
- Les `*.blueprint.md` — **spécifications à instancier** par `vf-new-lab`.

> **P2-a (MINEUR)** — ranger des documents de savoir et de protocole sous `agents/` garantit un faux
> positif à chaque audit de densité. Les déplacer sous `references/` supprimerait le bruit.

### Conformité recherche-doc avant debug (ADR-045)

`check-debug-research.sh` sort « aucune brique — rien a verifier », **exit 0**. Voir F13 — vert non
mérité, pas conformité.

---

## Phase 3 — Dette documentaire

Le repo est techniquement juste et **documentairement faux**. Un lecteur du README reçoit une image
périmée du produit.

*Signaux sains d'abord* : la synchro **README.md ↔ README.fr.md est parfaite** (233 L chacun, mêmes
tableaux aux mêmes lignes) — tous les défauts ci-dessous sont **partagés à l'identique**, donc à
corriger deux fois, jamais à réaligner l'un sur l'autre. Et la triade
`VERSION ↔ module.json ↔ CHANGELOG` est alignée **17/17** (par discipline humaine, pas par gate).

### 🔴 F1 (CRITIQUE) — le tableau des modules du README ment sur 13 versions sur 16

`README.md:81-96` / `README.fr.md:81-96` :

| Module | README | Réel |
|---|---|---|
| conductor | `1.8.2` | **v1.12.2** |
| dev-orchestrator | `1.3.0` | **v1.8.1** |
| consolidator | `1.0.0` | **v1.6.1** |
| reference | `2.3.1` | **v2.5.0** |
| software-architecture | `1.3.0` | **v1.5.1** |
| mobile-test-team | `1.0.1` | **v1.3.0** |
| infrastructure-audit | `1.0.0` | **v1.2.0** |
| validator | `1.1.0` | **v1.2.0** |
| design-orchestrator | `1.0.0` | **v1.1.0** |
| skill-creator | `1.0.0` | **v1.0.1** |
| business-pilot / content / growth | `1.0.0` | **v1.2.0 / v1.1.0 / v1.1.0** |

Le fichier se contredit : `README.md:198-199` annonce les *bons* numéros 117 lignes sous le tableau
qui affiche les anciens. **`kpi-analyst` (v1.0.1) est absent du tableau** alors que `:75` annonce
« 17 modules total » et que le badge `:13` dit `modules-17` — le tableau en compte 16.

### 🔴 F2 (CRITIQUE) — « 14 verbes » annoncés, 31 livrés

`README.md:82` : « Router agent `vibeflow-dev` + **14** `/vf-*` verbs ». Réel : **31**, et
`plugin/dev-orchestrator/module.json` le dit lui-même. Le produit est sous-vendu de plus de moitié.

### 🔴 F3 (CRITIQUE, release-bloquant) — l'agent `vibeflow-validator` déclare 3 skills inexistants

`plugin/validator/AGENT.md:6-12`, frontmatter `skills:` — vérifié un par un :

| Skill déclaré | Résolution |
|---|---|
| `consolidator` / `infrastructure-audit` / `audit-architecture` | ✓ |
| `agent-density-auditor` | ✗ **template only**, module doc-only, jamais posé comme skill exécutable |
| `dette-detector` | ✗ **aucun `SKILL.md` nulle part** — n'existe qu'en prose |
| `checkpoint` | ✗ **aucun `SKILL.md`** — seulement un `checkpoint-trigger-template.md` |

**Constaté en conditions réelles pendant cet audit** : les phases 2 et 3 ont dû être menées à la main
et déléguées à des agents génériques, précisément parce que ces trois skills sont introuvables. Le
défaut dégrade l'agent livré dans chaque lab.

Aggravants :
- `AGENT.md:73` propose `agent-density-auditor --mode=plan` : **le flag `--mode` n'existe nulle part**.
- **`/checkpoint` est documenté comme commande utilisateur dans 8+ fichiers** (`AGENT.md:3,25`,
  `plugin/validator/README.md:57`, `plugin/planning-core/SKILL.md:150,154`, …). Or `plugin/commands/`
  ne contient que `vf-audit`, `vf-calibrate`, `vf-new-lab`, `vf-planning`, `vf-update`, `vibeflow`.
  **`/checkpoint` n'existe pas.**

### 🔴 F4 (CRITIQUE, release-bloquant) — un skill distribué pointe un fichier inexistant

`plugin/skill-creator/skills/skill-creator/SKILL.md:364` : « Read the template from
`assets/eval_review.html` ». Il n'y a pas d'`assets/` ; le fichier est en
`references/eval_review.html`. Échec garanti à l'exécution.

### 🔴 F5 (CRITIQUE) — le README du module `reference` décrit une version qu'il n'est plus

Module à **v2.5.0**, mais `plugin/reference/README.md:6` annonce « Version : **v2.0.0** » :

| Affirmation | Réel |
|---|---|
| `:4` « 70 fichiers, 11 patterns, 4 skills » | **76 fichiers, 12 patterns, 5 skills** |
| `:21` « Core v4.1 (**8 principes**) » | `VIBEFLOW_CORE.md:3` = **v4.2**, `:64` = « les **9** principes », P9 défini `:162` |
| `:25-36` arbre s'arrêtant à `11-halt-conditions.md` | `12-cloisonnement-outils.md` existe, non listé |
| `content/VERSION.md:3` « v2.1, release 2026-05-28 » | c'est **le fichier que lit l'utilisateur** |

### 🟠 F6 (MAJEUR) — 30 ADR cités ~700 fois, définis nulle part

`docs/ADR.md` ne définit que **ADR-046 → ADR-055** ; son en-tête (`:5-7`) assume que ADR-001→045
« prédatent ce registre ». En pratique, les deux ADR **les plus cités du codebase n'ont aucune
définition canonique** :

- **ADR-031 → 169 occurrences**, **ADR-029 → 156**, ADR-045 → 70, ADR-044 → 58, ADR-030 → 44,
  ADR-043 → 39, ADR-032 → 29.
- `grep -rE '^#+ *(ADR-029|ADR-031|…)'` → **0 résultat**. Zéro définition, dans tout le dépôt.

**Collision de doctrine confirmée sur ADR-031**, qui porte deux sens incompatibles :

| Sens A — « vigilance support runtime » | Sens B — « jamais sans validation humaine » |
|---|---|
| `plugin/validator/AGENT.md:216` | `plugin/validator/AGENT.md:18` |
| `plugin/infrastructure-audit/SKILL.md:21` | `plugin/conductor/skills/vf-update/SKILL.md:46` |

`plugin/validator/AGENT.md` **utilise les deux sens à 200 lignes d'écart**. Collision similaire sur
ADR-019. C'est le socle normatif du produit : 325 citations reposent sur deux numéros non définis et
sémantiquement ambigus.

### 🟠 F7 (MAJEUR) — `.planning/` décrit un projet qui n'existe plus

- **`codebase/STRUCTURE.md`** (gelé au 2026-06-06) ne liste que **7 modules sur 17** — absents :
  `conductor` (le socle), `dev-orchestrator` (le module phare), `planning-core`, les 3 bundles. Il
  déclare 8 fichiers inexistants (`detect-cycles.sh`, `verify-boundaries.sh`, `archiving.md` — le vrai
  nom est `archivage.md`…).
- **`PROJECT.md`** figé au 2026-06-04 : projet encore intitulé « VibeFlow Dev Orchestrator »,
  **5 requirements sur 5 `- [ ]`**, **D1-D6 tous « Pending »**. `STATE.md:92` y renvoie pourtant.
- **`ROADMAP.md`** se contredit sur la Phase 9 : plans `[x]` vs « Not started (R&D) » vs
  `STATE.md:24` « SHIPPÉ v2.28.0 ».
- **`STATE.md`** : « Current focus: Phase 9 » vs « Phase: 13 » ; « plans completed: **0** » vs
  frontmatter « **13** ». Ne mentionne jamais v2.31.1.

### 🟡 Mineurs

- **F8** — les deux `skill-creator/SKILL.md` sont **byte-à-byte identiques** (485 L) mais versionnés
  séparément : ils divergeront au premier patch.
- **F9** — `patterns/README.md` : « 12 patterns » (`:3`) vs « ## Les 11 patterns » (`:18`).
- **F10** — `plugin/consolidator/README.md:26` : `../INSTALL.md` → résout vers `plugin/INSTALL.md`,
  inexistant.
- **F11** — `README.md:197-201` : historique croissant jusqu'à v2.28.0 puis décroissant.
- **F12** — la doc **installée** (`docs/reference/`, gitignorée) a dérivé : contient la version
  *fausse* de `05-regles.md` corrigée par `4a24aae`, et il manque la Phase 0 « recherche
  documentaire » (ADR-045). Preuve que la doc installée ne se rafraîchit pas.
- **F12 bis** — `README.md:145` « **Zero hooks**: the plugin registers nothing at session start » est
  **faux** (5 modules livrent un `hooks/hooks.json`). `README.md:146` « **Tests**: every script is
  covered » est **faux** : 6 scripts sans aucun test, dont **les deux gates de release**.

---

## Phase 4 — Architecture d'audit des process

### Ce qui tient — et ce que ça enseigne

Le clivage est net : **les process dont le garde-fou est un script ou un hook tiennent ; ceux dont le
garde-fou est une consigne d'agent tiennent moins.**

- **`mobile-test-team`** — la couche la plus solide du plugin. Cloisonnement **dans le frontmatter**,
  pas en prose (`vf-test-runner.md:23` « INTERDIT absolu : modifier le code app »). Refus réel avec
  arrêt (`vf-app-fixer.md:27` : « tu rapportes … et tu t'arrêtes sans rien committer »). Anti-boucle
  le plus complet (`maxAttemptsPerFlow`, HALT-2 > 3 cycles).
- **`consolidator`** — hooks `PreToolUse` DENY **sans** `|| true`, `--strict` exit 1. Auto-critique
  exemplaire (`SKILL.md:310` : « machine-enforced par le guard — **la prose seule ne suffisait pas** »).
- **`planning-core`** — le seul refus machine au moment du « done » (hook `Stop`), avec anti-boucle
  machine-enforced (`stop_hook_active` + marqueur `.blocked`, testé).
- **`kpi-analyst`** — le seul agent dont le prompt s'ouvre sur une Iron Law de refus incarnée
  (`AGENT.md:83` : « Je préfère ne rien afficher qu'afficher un faux chiffre »), et qui **retire la
  production de valeur au LLM** (extracteurs déterministes). Le meilleur enforcement est celui qui
  rend la triche impossible plutôt que détectable.
- **`vf-reviewer` / `vf-auditer`** — indépendance **techniquement forcée** par `tools:` sans
  `Write`/`Edit`. C'est la bonne façon de faire un auditeur indépendant.
- La chaîne dev a de vrais verdicts typés (`{statut: passed|gaps_found|human_needed|blocked}`) et un
  anti-boucle réel (`vf-coder.md:30` « 3 tours max »).

### 🔴 F13 (CRITIQUE) — la classe « vacuous green » : 7 gates rendent un vert sans avoir rien vérifié

Le trou le plus grave, et ce n'est pas 7 bugs mais **un seul bug de conception répété** : *une cible
absente ou vide est traitée comme une cible conforme.*

| # | Gate | Sortie observée | Cause |
|---|---|---|---|
| VG-1 | `check-agents.sh` (même `--strict`) | « aucun agent dans `.claude/agents` », **exit 0** | `:26` `AGENTS_DIR=".claude/agents"` figé ; `:221-226` glob vide → `sys.exit(0)` |
| VG-1 | `check-debug-research.sh` | « aucune brique », **exit 0** | idem `:33-34`, `:135-141` |
| VG-2 | `check-version-sync.sh` | **« ✓ sources synchronisées »** | `:45` compte les **fichiers** `module.json`, ne lit **jamais** `plugin/*/VERSION` ni les lignes du tableau README |
| VG-3 | `vibeflow-update.sh` | install **exit 0** après « gouvernance absente ! » | `:293-312` `return 0` après l'ERROR ; les 2 appelants ignorent le retour |
| VG-5 | `audit-infra.sh` | JSON à zéro, **exit 0** | `:22` `CLAUDE_DIR=.claude` absent → toutes les boucles sautées ; aucun `exit≠0` sur finding |
| VG-6 | `check-file-size.sh` (sans arg) | « Usage: … », **exit 0** | `:90` `exit 0` sur erreur d'usage |
| VG-7 | `probe-memory-guards.sh` | **silence** (= « tout va bien ») | ne vérifie que l'interpréteur Python, jamais le câblage des guards |

Trois conséquences directes, à retenir :

1. **`check-agents.sh` fonctionne parfaitement quand on le vise.** Pointé sur les vrais dossiers
   (`--agents-dir=plugin/dev-orchestrator/agents`), il rend « ✓ 4 agents conformes · 4 warnings ».
   Le flag existe (`:37`) mais **rien ne l'utilise**. Le problème n'est pas l'outil, c'est que
   personne ne le pointe au bon endroit.
2. **`CLAUDE.md:46-47`** affirme « **Agents natifs machine-enforced (ADR-044)** : tout agent posé
   passe `check-agents.sh` ». C'est **faux sur ce repo** : `guard-agent-write.sh:57` ne dénie que sous
   `.claude/agents`, or les agents produits vivent sous `plugin/*/agents/`. Le guard protège **les
   labs consommateurs**, jamais **le repo qui le produit**. Et c'est précisément ce gate qui aurait dû
   attraper **F3** : il *sait* détecter « skill déclaré introuvable », mais seulement en WARNING.
3. **VG-2 est une récidive documentée.** `check-version-sync.sh:5-7` cite l'incident qui l'a fait
   naître (« badge README 2.26.0/16 modules pour 17 réels »). Le même sinistre se rejoue un cran plus
   bas, sur les versions **par module**, et le gate écrit quand même « sources synchronisées » — une
   affirmation bien plus large que ce qu'il a vérifié.

Enfin, le seul déclencheur automatique de `check-agents.sh` est `SessionStart --hook`, or `--hook`
force `sys.exit(0)` (`:231-237`) **et** le câblage ajoute `|| true`. **Double neutralisation** : la
seule exécution automatique du gate agents ne peut, par construction, rien bloquer.

> **Correction de classe (à trancher une fois, pas sept)** : un **contrat de découverte** — tout gate
> déclare combien de cibles il attend et **refuse de rendre un verdict** s'il en trouve zéro :
> `exit 3 = INDÉTERMINÉ`, distinct de `exit 0 = CONFORME`. Un INDÉTERMINÉ n'est pas un vert : il ne
> satisfait aucun agent terminal.

### 🔴 F14 (CRITIQUE) — le repo n'est soumis à aucun de ses propres gates

`core.hooksPath` vide · `.github/` absent · `.claude/settings.json` absent · `reports/validator/`
vide avant aujourd'hui. `CLAUDE.md:32` prescrit « Vérifie : `bash scripts/check-release-tag.sh
--remote` » — instruction adressée à un humain, exécutée par personne.

Le garde-fou existe, il est correct, il **bloquerait** s'il était câblé — mais il est opt-in et non
activé. Cas d'école de `AXIOMES-ENFORCEMENT.md:9-10` : *« Une règle écrite dans un CLAUDE.md n'est pas
un garde-fou : c'est un vœu. »*

### 🟠 F15 (MAJEUR) — l'agent terminal ne refuse pas, et parfois n'existe pas

Doctrine : *« Le forçage réel = l'agent terminal qui REFUSE. »*

- **`vf-ship`** (`plugin/dev-orchestrator/skills/vf-ship/SKILL.md`) — le point de non-retour
  (PR / merge) — se termine par « Pré-requis : la **recette** (`vf-test`) doit être passée avant de
  livrer. » C'est **une phrase, pas un refus** : aucun artefact de verdict vérifié, aucune liste de
  verdicts requis, aucune instruction de refuser. C'est un **skill de 26 lignes**, pas un agent.
- **Le process de release (B1) n'a aucun agent terminal.** Le refus n'est incarné par personne.
- **`audit-infra.sh`** : son caractère bloquant n'est affirmé que dans un prompt
  (`plugin/validator/AGENT.md:49` « Bloquant : ERROR → arrêter »). Aucun exit code ne le porte.

### 🟠 F16 (MAJEUR) — trois règles de refus **orphelines de leur émetteur**

Le trou le plus subtil : la clause de refus est **correctement écrite** dans le prompt de l'agent
terminal — la forme exacte exigée par la doctrine — mais **le verdict qu'elle exige n'est produit par
personne**.

- `content-bundle/.../repurposer.blueprint.md:47-48` : « Vérifier les deux gates … Sinon, **refuser et
  renvoyer**. » Or **`human-validator` n'existe nulle part** (3 références, zéro définition), et le
  gate de clarté est décrété « une couche `audit-architecture`, **PAS un agent** »
  (`BUNDLE.md:96-97`) — en contradiction avec `plugin/audit-architecture/SKILL.md:114` (« un agent par
  couche qualitative »).
- `business-pilot-bundle/.../business-pilot-delivery.blueprint.md:94` : « **N'envoie aucun livrable
  sans gate vert** ». Or `quality-gate-client` est « à créer via skill-creator » — il n'existe pas ; et
  la rule path-scopée invoquée 4× est « à matérialiser à l'install » — **aucun `rules/`** dans le
  bundle.

> Une clause de refus orpheline est **plus dangereuse qu'aucune clause** : elle fait croire au filet.

### 🟠 F17 (MAJEUR) — le créateur s'auto-valide sur le fond dans les 3 bundles + design

`audit-architecture` est déclaré dans le `skills:` **du créateur** (`scriptwriter:20`,
`repurposer:20`, `copywriter-sequences:24`, `channel-strategist:26`, `campaign-analyst:24`) —
anti-pattern n°1. `channel-strategist.blueprint.md:106` : « Ne lance jamais une campagne sans gate
PASS » — mais c'est **le même agent** qui invoque le gate, lit le verdict et décide. **Auto-refus.**

Le design est le pire cas : `vibeflow-design` est créateur et unique évaluateur, et
`design-toolchain.md:54` pose que les outils d'audit peuvent tous être absents avec « dégradation
gracieuse » et **« ne JAMAIS bloquer »** — une couche d'audit désactivable par principe.

### 🟠 F18 (MAJEUR) — le commit précède systématiquement l'audit

`vf-coder.md:26-30` ordonne **3. Exécution** (« C'est lui qui fait les commits atomiques ») **puis
4. Revue**. Le point de non-retour est franchi **avant** la seule couche d'audit indépendante : le
verdict ne peut jamais *empêcher*, au mieux déclencher un fix ou un revert.

### 🟠 F19 (MAJEUR) — en mode autonome, l'escalade est explicitement neutralisée

`vf-dev-manager.md:82-86` : « `human_needed` → escalade (mode superviser : checkpoint ; **mode
autonome : consigner et continuer**) ». En autonomie, un verdict `human_needed` **ne bloque rien** :
il devient une ligne de journal. C'est la définition de l'avis, pas de l'audit.

### 🟡 Mineurs

- **F20** — **anti-boucle absent dans 5 process sur 11** (dev verbes, design, contenu, growth,
  business). Trois décrivent explicitement une boucle de reprise **sans la borner**. Le repo contient
  pourtant son propre gabarit chiffré (`examples-cross-domain.md:21` : « max 2 A/R → 3e FAIL =
  escalade »).
- **F21** — `skill-creator` : `comparator.md:41-53` porte **la seule vraie rubric scorée du repo**
  (6 critères ancrés 1-5, indépendance anti-biais « Stay blind »). Mais son verdict est **relatif**
  (`winner: A|B|TIE`, « pick the one that fails less badly ») — **aucun seuil plancher** — et il est
  déclaré **optionnel** (`SKILL.md:325-329`). Un dispositif d'audit optionnel n'est pas un gate.
  `grader.md` calcule un `pass_rate` (`:133`) **jamais comparé à un seuil**.
- **F22** — **aucun ID de verdict traçable**, alors que la doctrine du repo le prescrit
  (`audit-layer-primitive.md:65`). Les rapports typés ADR-053 sont un acquis réel mais ne sont ni
  identifiés, ni archivés, ni rejouables.
- **F23** — gates auto-désactivables : `check-release-tag.sh:49` (`if [ -f "$SYNC" ]`) — renommer
  `check-version-sync.sh` désactive **silencieusement** la moitié du gate de release ;
  `check-version-sync.sh:50-53` — le contrôle « N modules total » s'auto-désactive si la phrase est
  reformulée.

---

## Phase 5 — Recommandations

Par ratio effet/effort. **Rien n'a été appliqué** — chaque action attend ta validation.

### Bloquant avant la prochaine release

1. **F3** — Retirer `dette-detector` et `checkpoint` du frontmatter de `plugin/validator/AGENT.md`,
   ou créer les skills. Trancher le sort d'`agent-density-auditor`. Supprimer la mention `--mode=plan`.
2. **F3 bis** — Décider pour `/checkpoint` : créer `plugin/commands/checkpoint.md`, ou purger les 8+
   fichiers qui le documentent et rediriger vers `/vf-audit`.
3. **F4** — `SKILL.md:364` : `assets/eval_review.html` → `references/eval_review.html`.
4. **P1-e** — Réparer l'isolation de `test-vf-update.sh` (stuber `~/.claude`). Un test rouge sur
   `main` qui dépend du poste est pire qu'un test absent.

### Le geste à plus fort levier

5. **F14 + F13 + P1-b — un unique workflow CI**, qui ne demande **aucun gate nouveau**, seulement de
   brancher ceux qui existent :
   - boucle sur les 31 suites **avec assertion de découverte non vide** ;
   - `check-version-sync.sh` + `check-release-tag.sh --remote` ;
   - `check-agents.sh --strict --agents-dir=` sur chaque `plugin/*/agents/`.

   Corrige d'un coup F14, VG-1, P1-b, P1-c, et rend enfin vraie la promesse « machine-enforced » de
   `CLAUDE.md:46`.
6. **F1 + F2 + VG-2** — Régénérer le tableau des modules des deux README depuis les `VERSION` réelles
   (+ `kpi-analyst`, + « 31 verbes »), **et** élargir `check-version-sync.sh` à la triade par module
   *et aux lignes du tableau README*. Le correctif durable est le gate ; le reste est ponctuel.
7. **VG-3** — Propager l'échec de `merge_module_hooks` (trois lignes). Empêche un lab d'exister sans
   gouvernance tout en croyant l'avoir.
8. **F13 en doctrine** — Trancher le contrat `exit 3 = INDÉTERMINÉ ≠ exit 0 = CONFORME` pour tous les
   gates. Sans cela, chaque nouveau gate rejouera le motif.

### Dette structurante

9. **F16** — Livrer les émetteurs de verdict manquants (`clarity-auditor`, `human-validator`,
   `quality-gate-client`, la rule business) **ou** retirer les clauses de refus qui les invoquent.
10. **F6** — Rapatrier **ADR-029/030/031/032/043/044/045** dans `docs/ADR.md` et **désambiguïser
    ADR-031** (deux doctrines sous un numéro → en scinder une). 325 citations en dépendent.
11. **F18 + F19** — Arbitrer où vit le point de non-retour (commit vs push) et restaurer le caractère
    bloquant du `human_needed` en mode autonome.
12. **F15** — Inscrire le refus explicite dans `vf-ship` ; envisager un agent terminal de release.
13. **F17 + F20** — Séparer auditeur et créateur dans les bundles + design ; poser les compteurs
    d'anti-boucle (gabarit déjà disponible dans le repo).
14. **F7** — Régénérer `.planning/codebase/` (`/vf-map`) et remettre `PROJECT.md`/`STATE.md`/
    `ROADMAP.md` en phase avec v2.31.1.
15. **P1-a, F5, F8-F12, F21-F23, P2-a** — Whitelist runtime ; README `reference` ; dédup
    `skill-creator` ; seuils absolus du comparator ; gates auto-désactivables ; docs non-agents hors
    de `templates/agents/`.

---

## Prochaine session

Audit recommandé : **2026-08-24** (+30 j), ou immédiatement après la prochaine release de module.

**Contrôle de reproductibilité** : à état inchangé, ce score doit être identique. Toute variation sans
commit intermédiaire = bug d'auditeur.
