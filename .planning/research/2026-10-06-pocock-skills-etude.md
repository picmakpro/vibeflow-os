# Étude — ce que vf-dev peut emprunter au pack de Matt Pocock (2026-10-06)

**Source étudiée** : `mattpocock/skills` (« Skills For Real Engineers », MIT, plugin
`mattpocock-skills` v1.3.1, commit `6fd9479` du 2026-10-06), cloné et lu le 2026-10-06 :
`README.md`, `SCOPE.md`, `CLAUDE.md`, `.out-of-scope/*.md`, les README de buckets et les
`SKILL.md` de `grilling`, `grill-with-docs`, `ask-matt` (+ `PHASE-BOUNDARIES.md`), `to-spec`,
`to-tickets`, `implement`, `implement-spec`, `wayfinder`, `code-review`, `retro`, `handoff`,
`chief-of-staff`, `loop-me`.
**Demande** : Willy, relayée par Samuel en session principale le 2026-10-06 — « regarder le plugin
de Matt Pocock pour améliorer vf-dev ». Aucune veille antérieure dans le dépôt, la mémoire, les
issues ni les branches (vérifié le même jour). Seule trace : une **copie périmée du pack**
(mai 2026, noms d'avant les renommages `to-prd`→`to-spec`, `to-issues`→`to-tickets`,
`diagnose`→`diagnosing-bugs`) dans `~/.agents/skills` de Samuel, posée par skills.sh — jamais une
dépendance VibeFlow, à ne pas prendre pour une étude.

## 1. Ce qu'est le pack, mesuré

| Dimension | Pocock (1.3.1) | VibeFlow (v2.68.0) |
|---|---|---|
| Skills | 38 dossiers : 20 `engineering/`, 7 `productivity/` (les 27 « promus », seuls livrés par le plugin), 4 `misc/` gelés, 7 `in-progress/` hors plugin | 14 skills VF + superpowers (15) + 72 de gsd-core |
| Volume | 2 676 lignes au total, skill médian ≈ 70 lignes, le plus long 170 (`pr`) | plafond 500 / skill (ADR-029) |
| Agents / hooks / commandes | **0 / 0 / 0** — rien que des skills | 25 agents sous `plugin/*/agents/` (gatés par `check-agents.sh`), hooks sur 6 modules, 0 façade |
| État | aucun : tout passe par le tracker d'issues (GitHub, GitLab ou `.scratch/<feature>/issues/`) et deux fichiers (`GLOSSARY.md`, ADR) | `.planning/` (GSD) + registres + DAG + driver-lock |
| Invocation | deux classes machine-déclarées : **user-invoked** (`disable-model-invocation: true`, orchestre) et **model-invoked** (discipline réutilisable) ; un user-invoked n'appelle jamais un autre user-invoked | Pattern 12 (`vf-internal: true`), profondeur 1/2/3 (`team-kernel.md`) |
| Routage | `ask-matt` : un router en prose — flow principal idée → ship, deux bretelles, « vocabulaire en dessous » | `intent-routing.md` (table) + échelle dans `head-governance.md` |
| Gouvernance du catalogue | `SCOPE.md` : une issue ne reste ouverte que sur **défaillance observée** + conformité philosophie ; **zéro nouveau skill accepté** (« si ça se compose depuis l'existant, pas de skill ») ; `.out-of-scope/` = un fichier par refus motivé | SOBR-01..08 (un ajout = un retrait), ADR comme registre des refus |
| Multi-runtime | Claude Code (plugin officiel), Codex et autres via skills.sh ; `agents/openai.yaml` par skill | Claude Code, Codex, Kimi prouvés (Phase 38) |

**Philosophie, en une ligne du README** : « GSD, BMAD et Spec-Kit *possèdent* le process et vous
retirent le contrôle ; ces skills sont petits, adaptables, composables. » C'est l'**inverse
exact** de la doctrine VibeFlow (GSD-first, mémoire `doctrine-gsd-first`). Le pack ne se prend
donc **jamais en bloc** : on emprunte des disciplines transcrites, pas un pipeline concurrent.

## 2. Table — skill Pocock → équivalent chez nous → verdict

| Pocock | Chez nous | Verdict |
|---|---|---|
| `grilling` (primitif : arbre de décision, **frontière par tours**, recommandation par question, « les faits sont au agent, les décisions à l'humain ») | `gsd-discuss-phase` (zones grises, mode advisor), `superpowers:brainstorming` | **à emprunter** — la discipline, pas le skill (§3-a) |
| `grill-with-docs` = `grilling` + `domain-modeling` (`GLOSSARY.md` + ADR tenus **pendant** le cadrage) | aucun mécanisme : `docs/_transverse/` prévoit un glossaire de lab (`scaffold-docs.sh`), rien ne le remplit ; le lexique VF est celui de la méthode, pas du domaine du lab | **à emprunter** (§3-b) |
| `ask-matt` + `PHASE-BOUNDARIES.md` (arbre à 5 options à la frontière de phase : continue / clear / handoff / subagent / compact) | `intent-routing.md` pour le routage ; **rien** sur la frontière de contexte côté head | **à emprunter** la frontière (§3-c) ; le router est un doublon |
| `to-spec` (synthèse sans interview, user stories, **seams de test**, hors-périmètre) | `gsd-spec-phase`, `gsd-plan-phase` | doublon ; retenir l'idée « choisir les seams de test **avant** la spec » comme question de cadrage |
| `to-tickets` (tranches verticales traceuses, arêtes bloquantes, **expand–contract** pour un refactor large) | `gsd-plan-phase` (vagues), DAG team-kernel | doublon ; expand–contract = motif de plan, déjà exprimable |
| `implement` / `implement-spec` (frontière de tickets, worktree par implémenteur, merger, review finale) | `gsd-execute-phase`, `vf-dev-manager` + `vf-coder`, worktrees (WKTR) | doublon — notre DAG fait déjà plus (lock, rapports typés, halt) |
| `wayfinder` (carte de **tickets de décision** sur le tracker, brouillard de guerre, un ticket par session) | `gsd-explore`, `gsd-discuss-phase` multi-sessions, ROADMAP | doublon partiel ; l'idée « décisions, pas livrables » est déjà celle du cadrage GSD |
| `code-review` (**deux axes** Standards / Spec en sous-agents parallèles, **jamais re-rankés**, baseline de 12 smells Fowler) | `vf-reviewer` → `gsd-code-reviewer` (agrège, déduplique, classe par sévérité) | **à emprunter** la séparation des axes (§3-d) |
| `retro` (améliorer l'**environnement** de l'agent, pas le code ; « mécanique → check déterministe, jugement → standard ») | `gsd-extract-learnings`, `consolidator` (LEARNINGS, `detect-promotions.sh`), gates G-1..G-3 | **à emprunter** la grille de tri (§3-e) — recoupe l'emprunt ECC-3 |
| `pr` (corps de PR : plus petit visuel, preuve avant/après, **porte à sens unique / double sens + rayon d'explosion**) | `gsd-ship`, `gsd-pr-branch` | **à emprunter** le « merge-danger call » (§3-f) |
| `tdd`, `diagnosing-bugs` | `superpowers:test-driven-development`, `systematic-debugging`, `gsd-debug` (ADR-045) | doublon |
| `prototype`, `research`, `handoff`, `triage` | `gsd-spike` / `gsd-sketch`, `gsd-phase-researcher`, `gsd-pause-work`, `gsd-inbox` | doublon |
| `codebase-design`, `improve-codebase-architecture` | `software-architecture`, `improve-codebase-architecture` (déjà dans `~/.agents/skills`, hors VF) | hors vf-dev — vocabulaire « module profond » utile à `vf-coder`, pas prioritaire |
| `wizard` (script bash interactif pour les gestes que seul l'humain peut faire : secrets, dashboards tiers) | rien | **hors vf-dev** — à garder en tête pour `conductor`/installeur (pose des rulesets, secrets CI) |
| `to-questionnaire`, `wait-what`, `teach`, `writing-for-agents`, `writing-*` | — | hors périmètre |
| `chief-of-staff`, `loop-me`, `claude-handoff` (beta, hors plugin) | `vibeflow-head`, `vf-auto` | lire §3-c : la « double piste tactique / stratégique » est la seule idée à retenir |
| `setup-matt-pocock-skills` (tracker d'issues, labels de triage, emplacement des docs) | `vibeflow-install`, `vf-new-lab`, config GSD | doublon |

## 3. Les six emprunts retenus (ordre de valeur / coût)

- **a. La frontière de questions comme discipline de cadrage** (`grilling`). Trois règles
  transposables telles quelles dans le cadrage du head et des panels du manager : (1) ne poser
  que les questions dont les prérequis sont réglés — un **tour** = toute la frontière, numérotée ;
  (2) **une recommandation par question**, toujours ; (3) **un fait ne se demande jamais à
  l'humain** — un sous-agent va le chercher, et seules les questions en aval attendent. Fin de
  session = frontière vide, rien d'assumé en silence. **Divergence assumée** : Pocock refuse le
  tool natif (`.out-of-scope/native-question-tool.md`, « les pickers poussent au QCM pré-mâché »)
  et refuse tout plafond de questions ; Samuel a tranché l'inverse (mémoire
  `preference-discuss-batch` : AskUserQuestion groupé par zone, jamais le rendu texte). On garde
  la discipline de la frontière et le rendu AskUserQuestion. → `head-governance.md` et le mandat
  de cadrage de `vf-dev-manager` (panels `gsd-discuss-phase` advisor).
- **b. Glossaire de domaine du lab, tenu pendant le cadrage** (`grill-with-docs`,
  `domain-modeling`). L'argument est **token-économique** : un langage partagé (« la cascade de
  matérialisation ») remplace vingt mots par un, nomme les variables et fichiers de façon
  cohérente, et réduit le thinking. Le slot existe (`docs/_transverse/`, `scaffold-docs.sh`),
  aucun geste ne l'alimente. → chaque cadrage (discuss) challenge les termes flous et met à jour
  le glossaire du lab ; `docs-flow.md` en fait une cinquième famille ou l'adosse à la famille
  **savoir**. Les ADR du lab restent ce qu'ils sont (`ingestion-flow.md` les ingère déjà).
- **c. L'arbre de la frontière de phase** (`PHASE-BOUNDARIES.md`). Le head n'a **aucune
  doctrine** sur « que faire du contexte à la fin d'un geste ». L'arbre ordonné — continuer
  (gratuit, à exclure d'abord) → clear (si rien ne sert à la suite) → handoff (seulement
  harness / dossier / collègue / fork) → sous-agent (si AFK-able) → compact **en dernier**, avec
  instruction — est la face **jugement** de l'emprunt ECC-1 (snapshot PreCompact, face machine).
  Avec, venu de `chief-of-staff`, la **double piste** : à chaque sortie de manager, le head se
  demande aussi « qu'est-ce qui, dans l'environnement, aurait rendu la prochaine mission moins
  chère ? » → `head-governance.md` (compétence 3, contrôle de sortie).
- **d. Revue à deux axes jamais fusionnés** (`code-review`). Standards (conventions du dépôt +
  baseline de smells, toujours un jugement) et Spec (manquant / non demandé / implémenté faux,
  avec la ligne de spec citée) en **sous-agents séparés**, rapportés côte à côte : « un seul
  gagnant entre axes » est précisément le re-ranking que la séparation empêche. `vf-reviewer`
  (lu le 2026-10-06) ne porte **que** l'axe Standards — bugs, régressions, sécurité, qualité,
  conventions du projet ; la fidélité au plan d'étape n'est vérifiée que plus loin, par
  `gsd-verifier`. → deux dispatches de `gsd-code-reviewer` avec briefs distincts (Standards /
  Spec contre le PLAN de l'étape), agrégation par axe, jamais un verdict unique.
- **e. La grille de tri d'une rétro** (`retro`). Une erreur **mécanique** (motif syntaxique, API
  bannie, emplacement de fichier) devient un check déterministe (lint, hook, job CI) — jamais une
  règle de prose ; seul le **jugement** (cohérence inter-fichiers) mérite un standard ; un dépôt
  sans garde-fou est **en soi** un finding ; les instructions sans effet (« no-ops ») se chassent.
  C'est déjà notre doctrine des gates, jamais écrite comme grille de promotion des LEARNINGS.
  → `gsd-extract-learnings` / `consolidator` (`detect-promotions.sh`), en composant avec ECC-3.
- **f. Le « merge-danger call » dans le corps de PR** (`pr`) : porte à **sens unique** ou
  **double sens**, plus le **rayon d'explosion**. Cinq lignes dans le gabarit de `gsd-ship` ; sur
  ce dépôt, c'est exactement ce qu'une relecture adverse SOBR-04 veut lire en premier.

Aucun de ces emprunts n'installe `mattpocock-skills` : un seul catalogue tiers (superpowers),
décision du 2026-08-28 (mémoire `agent-skills-ecarte-superpowers-reste`). Le `tdd` et le
`diagnosing-bugs` de Pocock ne remplacent pas ceux de superpowers.

## 4. Ce qui est explicitement écarté, et pourquoi

- **Le flow idée → ship** (`to-spec` → `to-tickets` → `implement(-spec)`, `wayfinder`) — c'est
  un second pipeline de planning, posé **contre** GSD par construction (README). Doctrine
  GSD-first, ADR-057 (une seule voix) ; la façade de synonymes supprimée en v2.33.0 ne revient pas.
- **Le tracker d'issues comme état** — `.planning/` est notre état, le DAG et les rapports typés
  notre frontière ; dupliquer l'un dans GitHub Issues est la dérive que `check-overlaps.sh` chasse.
- **Le refus du tool de question natif** et **l'absence de plafond** — tranchés à l'inverse par
  Samuel (ci-dessus). On ne rouvre pas.
- **« Les gardes contre la récursion de sous-agents appartiennent au harness, pas aux skills »**
  (`.out-of-scope/subagent-recursion.md`) — on a mesuré le contraire : profondeur 3 ne voit plus
  Agent et l'allowlist n'est pas appliquée (mémoire `profondeur-de-spawn-limite-2`). Pattern 12
  et la marge de profondeur du team-kernel restent **dans** nos agents.
- **`ask-matt`** — un router en prose sur 27 skills ; `vibeflow-head` + `intent-routing.md` le
  sont déjà, et machine-vérifiés (test d'exhaustivité contre l'index).
- **Les buckets `misc/` et `in-progress/`** — gelés ou beta, hors plugin chez lui aussi.

## 5. Ce qu'on retient de sa gouvernance de catalogue (pas un emprunt, un miroir)

`SCOPE.md` + `.out-of-scope/` sont la version Pocock de SOBR-01..08 : **défaillance observée
obligatoire** (une hypothèse « ce serait mieux si » ne tient pas une issue), **zéro nouveau skill**
(composer, sinon rien), **un fichier par refus** relu avant toute proposition, `misc/` gelé avec
toutes ses issues fermées. Un dépôt à 274k étoiles tient 27 skills ; la pression inverse (le
volume ECC, 292 skills) est celle qu'on a écartée le 2026-09-25. Rien à copier, c'est une
confirmation de la Phase 41.3.

## 6. Collisions et séquencement

| Emprunt | Modules touchés | Voisinage | Nature |
|---|---|---|---|
| a, c | `dev-orchestrator` (`head-governance.md`, `vf-dev-manager.md`) | Phases 45-50 de Willy (hook central par rôle, gates) : hors `dev-orchestrator` | faible |
| b | `conductor` (`scaffold-docs.sh`, `docs-flow.md`), cadrage | Phase 48 (pont mémoire) | **moyenne** — même terrain documentaire, à sérialiser après 48 |
| d | `dev-orchestrator` (`vf-reviewer.md`) | — | aucune |
| e | `consolidator` (`detect-promotions.sh`) | ECC-3 (Phase 53), Phase 48 | **moyenne** — à fondre dans la Phase 53, pas une phase à part |
| f | `gsd-ship` est amont (gsd-core) : gabarit côté `mission-contracts.md` ou note de ship | — | faible |

**Recommandation de séquencement** : pas de jalon dédié. Deux gestes :

1. **a + c + d + f** = doctrine du head et du reviewer, **une phase `dev-orchestrator`** dans le
   compartiment `fiabilite`, minor (comportement installé qui change), après la clôture de
   `fiabilite-v1.0` et avant ou à côté de la 51 (indépendante).
2. **b + e** se fondent dans le jalon `ecc-inspiration-v1.0` : b dans la phase documentaire la
   plus proche (ou une 52bis), e dans la **Phase 53** (apprentissage adossé à l'observation).

Points de sérialisation inchangés : `VERSION` et le tag (une release à la fois), numérotation des
ADR (à la suite du dernier posé), `BACKLOG.md` et `docs/ADR.md` (un seul écrivain par PR).
