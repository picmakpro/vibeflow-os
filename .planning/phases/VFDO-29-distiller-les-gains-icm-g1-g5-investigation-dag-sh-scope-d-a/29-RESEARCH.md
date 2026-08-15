# Phase 29: Distiller les gains ICM (G1-G5) — investigation dag.sh --scope d'abord - Research

**Researched:** 2026-08-15
**Domain:** doctrine/tooling interne VibeFlow (bash + doctrine markdown, aucune stack applicative) — gate anti-drift, digest de mission, doctrine managers, scaffolding docs
**Confidence:** HIGH sur l'investigation `dag.sh --scope` (tout lu sur pièce cette session) · MEDIUM sur le placement recommandé de G2/G3 (zones de discrétion CONTEXT.md, raisonnées depuis les conventions du dépôt, pas verrouillées)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Périmètre (pré-cadrage 2026-08-15, AskUserQuestion)**
- **D-01:** G4 (lab-starters clonables à placeholders pour `vf-new-lab`) est **DÉCOUPÉ hors de la
  Phase 29** — phase dédiée à inscrire plus tard, à instruire conjointement avec les items backlog
  « agency-agents » et « Template d'agent installable » qu'il recoupe. La 29 livre G1/G2/G3/G5 +
  l'investigation `--scope`.
- **D-02:** Les gains secondaires du rapport (budgets tokens par couche, colonne `Section/Scope`
  dans les mandats, frame « compilateur », pipelines ICM purs pour labs non-dev) sont **HORS
  périmètre** — ils restent au backlog, aucun ne s'invite dans les livrables de la 29.
- **D-03:** **Zéro régression autorisée sur `dag.sh --scope`** : l'investigation (historique
  Phase 27/D-13, consommateurs — `partitionStages()`, frontière `ready --stage`, doctrine
  team-kernel.md:19 et mission-flow.md:106/244-247 —, suite `test-dag.sh`) précède et conditionne
  tout geste G1. Si un geste G1 exige de toucher `dag.sh`, la voie « doctrine seule / manager
  rédige » est la position de repli qui garantit la non-régression par construction.
  — **Reversibility:** one-way — une régression du scope casserait le dispatch parallèle des
  managers en production chez les utilisateurs du plugin ; c'est la raison d'être de la
  précondition, pas un simple ordre des tâches.

### Claude's Discretion (déléguées explicitement — « Rien » au menu de discussion)

- **G3** : choix des paires carte↔disque du v1 (folder maps des CLAUDE.md, `skills:` des
  frontmatters, compteurs STATE/ROADMAP…), emplacement du script (conductor hook vs phase
  validator), mode lint-only vs lint+update — en respectant ADR-031 (jamais de fix sans
  validation humaine) et le précédent `check-doc-drift.sh` (constater le FAIT, jamais juger le
  métier).
- **G1** : forme de l'anti-chargement (digest, templates d'agents, CLAUDE.md scaffoldés) et
  mécanisme du négatif du scope (calculé vs rédigé) — sous la contrainte D-03.
- **G2** : `scaffold-docs.sh` à la création seulement vs rattrapage `vf-calibrate` ;
  `_index.md` machine-généré vs rédigé.
- **G5** : emplacement de la règle Edit-Source (team-kernel.md vs mission-flow.md vs les deux
  + pattern méthodo) — en tenant compte de la charte de densité ADR-029.

### Deferred Ideas (OUT OF SCOPE)

- **G4 — lab-starters clonables à placeholders** (phase dédiée à inscrire) : à instruire avec les
  items backlog « agency-agents » et « Template d'agent installable » — trois entrées, un seul
  chantier probable.
- **Gains secondaires ICM** (budgets tokens par couche, `Section/Scope` dans les mandats, frame
  « compilateur », pipelines ICM purs pour labs non-dev simples) — au backlog, réévaluables après
  la 29.
</user_constraints>

<phase_requirements>
## Phase Requirements

**Aucun ID de requirement n'existe pour cette phase.** `ROADMAP.md` ne cite aucun préfixe pour la
Phase 29, et `REQUIREMENTS.md` ne porte aucune entrée qui la référence — vérifié par lecture
intégrale du fichier (781 lignes) cette session. C'est **conforme à la convention observée du
dépôt** sur les phases hors-milestone récentes : Phase 22 (`DOCF-*`), Phase 23 (`GSDC-*`),
Phase 24 (`GSDA-*`), Phase 27 (`PAEX-*`) et Phase 28 (`ARMD-*`) ont **toutes** vu leurs IDs
**créés au moment du plan**, jamais au cadrage ni à la recherche — le ROADMAP portait `TBD` pour
chacune jusqu'au plan `/gsd-plan-phase`. `[VERIFIED: .planning/REQUIREMENTS.md — lu en entier
cette session, offsets 1-781]`

**Recommandation de forme, non verrouillée** : un préfixe à 4 lettres cohérent avec la convention
(`DOCF`, `GSDC`, `GSDA`, `PAEX`, `ARMD` — tous dérivés du sujet de la phase, pas d'un acronyme
externe repris tel quel) — p. ex. `ICMG` (« ICM Gains ») ou `ICMD` (« ICM Distillation »). Utiliser
un préfixe qui référence « ICM » comme acronyme interne de traçabilité n'est **pas** une adoption
du label externe (le rapport de deep-search l'interdit explicitement, §6) — le précédent `GSDC`/
`GSDA` montre que le dépôt nomme déjà ses préfixes d'après l'objet externe qui a déclenché la
phase sans que cela constitue une adoption doctrinale. **`[ASSUMED]`** — c'est une suggestion de
forme pour le planner, pas une décision.

**Table Requirement → Support (à peupler par le planner une fois les IDs créés)** — cinq familles
de livrables identifiées par le domaine de phase, sourcées `29-CONTEXT.md` :

| Domaine | Description | Support recherche |
|---|---|---|
| Investigation `dag.sh --scope` | Précondition transverse : historique, consommateurs, couverture de test, verdict intouchable/extensible | §Investigation dag.sh --scope ci-dessous (livrable complet, HIGH confidence) |
| G3 — gate anti-drift carte↔disque | `check-map-drift.sh`, paires v1, emplacement, mode | §Architecture Patterns, §G3 — Anti-drift carte↔disque |
| G1 — anti-chargement déclaré | Tables Load/DO NOT Load + négatif du scope dans les digests | §Investigation dag.sh --scope (voie recommandée) + §G1 |
| G5 — Edit-Source Principle | Règle doctrinale chez les managers | §G5 — Edit-Source Principle, §Project Constraints (densité) |
| G2 — CONTEXT.md par compartiment + `_index.md` | `scaffold-docs.sh` / `vf-planning` | §G2 — Contrat-par-dossier |

</phase_requirements>

## Summary

Cette phase ne touche aucune stack applicative : c'est une phase de doctrine et d'outillage bash
interne au plugin VibeFlow. Le vrai risque n'est pas technologique, il est **architectural** :
`dag.sh --scope` est un socle lu en routine par les cinq managers du team-kernel, il porte déjà
une histoire de cinq passages du même motif de faille de confinement de chemin (ADR-070), et
l'Iron Law 2 révisée (ADR-069) interdit explicitement de réimplémenter localement la logique de
disjonction de périmètres qu'il câble en sous-processus vers l'amont `gsd-core`. L'investigation
demandée en précondition est donc traitée ici comme un **livrable à part entière**, pas un
préambule : elle reconstitue sur pièce (commits, lignes, tests) ce qui est intouchable, ce qui est
extensible, et conclut que **G1 peut se livrer sans toucher une seule ligne de `dag.sh`** — le
« négatif du périmètre » que G1 réclame pour les digests de mission est déjà 100 % dérivable des
champs que `dag.sh` émet aujourd'hui (`status --frozen`, le `scope[]` du nœud lui-même, déjà
threadé dans chaque digest de worker). Cela rend la clause de repli « voie doctrine, manager
rédige » de D-03 non seulement sûre mais **suffisante** — il n'y a pas besoin d'atteindre le repli
pour être en sécurité.

Pour G3 (l'anti-drift carte↔disque), le dépôt possède déjà deux précédents directement
transposables : `check-doc-drift.sh` (grammaire « FAIT, jamais métier », wrapper `git_safe()`
durci contre un dépôt cloné hostile) et `check-agents.sh` (grammaire d'exit 0/1/3, modes
`--hook`/`--strict`, garde-fou anti-« vert-à-vide » F13). Le point d'ancrage le plus cohérent
n'est ni un nouveau hook `SessionStart` ni un fichier isolé : c'est la **Phase 3 — dette
documentaire** de `vibeflow-validator` (grille des « 7 signaux de dette documentaire », déjà
conçue pour accueillir un signal de plus, comme `detect-planning-debt.sh` l'a fait pour un 8e).
Deux fichiers cruciaux à ce placement sont **déjà au plafond de densité ADR-029** (`vf-dev-
manager.md` et `validator/AGENT.md`, tous deux à 250/250 lignes, marge zéro) — toute addition
doctrinale de cette phase (G1, G3, G5) doit se déporter en `references/`, jamais s'ajouter inline
à ces deux fichiers sans retrait équivalent.

Pour G2, un risque de collision de vocabulaire est identifié et documenté : le mot « compartiment »
désigne **deux objets distincts et non liés** dans ce dépôt — `docs/<projet>/` posé par
`scaffold-docs.sh` (ADR-042, doc de module) et le compartiment `planning-core` à seuil d'autonomie
(`compartments.md`, `.planning/` par sous-projet). G2 vise le premier ; le confondre avec le second
casserait la doctrine `INDEX.md` déjà en place au niveau lab.

**Primary recommendation :** traiter l'investigation `--scope` comme le premier livrable écrit du
plan (elle conditionne tout le reste par D-03), livrer G1 en pur ajout doctrinal sans toucher
`dag.sh`, ancrer G3 en extension de la grille des 7 signaux du validator (script `references/`
séparé, jamais inline dans `AGENT.md`), et vérifier au fil de l'eau — pas en fin de phase — que
`vf-dev-manager.md` et `validator/AGENT.md` restent sous 250 lignes.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Investigation `dag.sh --scope` (précondition) | Documentaire (ce RESEARCH + doctrine team-kernel/mission-flow existante) | — | Aucun code à produire ici — c'est un livrable écrit, pas un artefact runtime |
| G1 — tables Load/DO NOT Load | Doctrine (templates d'agents `.md`, `CLAUDE.md` scaffoldés) | — | Texte statique, aucune dépendance runtime, aucun script |
| G1 — négatif du scope dans le digest | Doctrine manager (`mission-contracts.md` gabarit digest) | `dag.sh status --frozen` (source de donnée, déjà vivante) | Le manager compose la ligne à partir de champs déjà émis — zéro nouvelle surface machine |
| G3 — gate anti-drift carte↔disque | Script `references/`/scripts du module `validator` ou `conductor` (à trancher au plan) | Hook `SessionStart` du conductor (optionnel, si signal voulu au démarrage) | Suit le patron `check-doc-drift.sh`/`detect-planning-debt.sh` : script advisory, jamais un correctif auto |
| G5 — Edit-Source Principle | Doctrine `references/` (team-kernel.md ou mission-flow.md, jamais l'agent lui-même) | — | `vf-dev-manager.md` est au plafond ADR-029 (250/250) — aucune marge inline |
| G2 — CONTEXT.md par compartiment + `_index.md` | Script `scaffold-docs.sh` (conductor) | Skill `vf-planning` (planning-core, rattrapage `vf-calibrate`) | Prolonge un scaffolder déjà idempotent (89 L) plutôt qu'un nouveau mécanisme |
| `dag.sh --scope` lui-même | Socle `conductor` (team-kernel, lu par les 5 managers) | Amont `gsd-core` (`partitionStages()`, câblé en sous-processus) | Intouchable hors du cadre ADR-069 (router, jamais forker) |

## Project Constraints (from CLAUDE.md)

Extrait de `/Users/samuel/Documents/dev/vibeflow-os/CLAUDE.md`, directives applicables à cette
phase :

- **Densité (ADR-029)** : agents ≤ 250 lignes, skills ≤ 500 lignes, bootstrap SessionStart
  ≤ 2000 tokens. `[VERIFIED: plugin/dev-orchestrator/agents/vf-dev-manager.md — wc -l cette
  session]` rend **250** lignes exactement — plafond atteint, marge **zéro**. `[VERIFIED:
  plugin/validator/AGENT.md — wc -l cette session]` rend également **250** lignes exactement —
  même plafond, même marge zéro. Toute doctrine ajoutée par cette phase (G1, G5, et l'ancrage de
  G3 s'il touche l'un de ces deux fichiers) doit se déporter en `references/` chargé on-demand,
  jamais s'ajouter inline à l'un de ces deux fichiers sans retrait équivalent.
- **Jamais de fix sans validation humaine (ADR-031)** : contraint directement G3. Le mode
  lint-only doit être le comportement par défaut ; tout mode « update »/correctif automatique
  doit être opt-in explicite et gardé par une confirmation humaine (patron `DOCF-03`, Phase 22 :
  reformulation du nombre et de la liste des éléments affectés, attente d'un oui explicite,
  interdiction en mission d'équipe et en mode autonome).
- **Agents natifs machine-enforced (ADR-044)** : tout agent posé passe
  `plugin/conductor/scripts/check-agents.sh`. Aucun nouvel agent n'est attendu par cette phase
  (doctrine + un script), mais si un agent existant est modifié (peu probable), le gate s'applique
  sans exception.
- **Commits en français**, cohérents avec l'historique du dépôt — observé sur tous les commits lus
  cette session (`d549b2d`, `27abc07`).

## Standard Stack

Cette phase n'introduit **aucune nouvelle dépendance**. Elle prolonge des scripts bash + python3
déjà en production dans ce dépôt.

### Core (déjà présent, aucune installation requise)

| Outil | Usage dans cette phase | Pourquoi c'est déjà le standard du dépôt |
|---|---|---|
| `bash` + `python3` | Tout script de gate (`check-doc-drift.sh`, `dag.sh`, `check-agents.sh`) suit ce patron : wrapper bash pour le CLI, logique en python3 embarqué (dag.sh) ou pur bash+`git` (check-doc-drift.sh) | Aucune dépendance externe, portabilité macOS/Linux déjà prouvée (Phase 17 SC6) |
| `git` (via wrapper `git_safe()`) | Tout script G3 qui diffe la carte contre le disque doit shell-out vers `git` pour lire l'historique/les chemins trackés | `check-doc-drift.sh` est le précédent direct — durcissement déjà écrit, à copier verbatim |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Réimplémenter la comparaison de scope[] localement dans un nouveau script G1 | Lire `dag.sh status --frozen` (donnée déjà émise) | Interdit de toute façon par ADR-069 (Iron Law 2 révisée) — pas un choix, une contrainte |
| Un nouveau parseur AST de markdown pour G3 | Réutiliser les helpers de tokenisation frontmatter déjà écrits dans `check-agents.sh` (`bare_tokens()`, extraction de champ) | G3 vérifie des ensembles déclarés (skills:, folder maps) — même famille de problème que ce que `check-agents.sh` résout déjà pour `tools:`/`disallowedTools` |

**Installation :** aucune — cette phase ne touche à aucun `package.json`/`requirements.txt`/
gestionnaire de paquets.

## Package Legitimacy Audit

**N/A pour cette phase.** Aucun package externe (npm, PyPI, crates) n'est installé — tous les
outils utilisés (`bash`, `python3`, `git`) sont des dépendances système déjà exercées par la suite
de tests existante du dépôt (`test-dag.sh` sonde explicitement la présence/absence de `node`,
`python3`, `gsd-tools` dans ses cas T29/T31/T32). Aucun geste du protocole de légitimité de
paquets n'est requis.

## Architecture Patterns

### Diagramme — flux `--scope` (déjà en production, à ne pas régresser)

```
manager (vf-dev-manager)
   │
   │ 1. pose un nœud avec son périmètre déclaré
   ▼
dag.sh add --id=<n> --deps=<...> --scope=<globs>          [construction seule, P-02]
   │
   ▼
node.json { id, step, deps[], scope[], status }            (persisté sur disque, DAG de mission)
   │
   ├──► dag.sh status --file=<DAG>
   │       └─► frozen[] = { id, status, scope }             pour chaque nœud NON-done à scope non-vide
   │           (source vivante de la « table des fichiers gelés » — jamais recopiée en doc statique)
   │
   └──► dag.sh ready --file=<DAG>
           ├─► frontier_nodes = nœuds status=ready
           └─► compute_stages(frontier_nodes)
                   │  construit un manifeste { waves: [{ id: "ready-frontier", plans: [...] }] }
                   │  écrit dans un fichier temporaire (jamais argv, jamais de concat de chaînes)
                   ▼
               sous-processus : gsd-tools claude-orchestration emit-workflow --waves <tmp> --run-id dag-ready
                   │  (JAMAIS de réimplémentation locale de la comparaison scope[] — ADR-069)
                   ▼
               amont gsd-core : partitionStages() (claude-orchestration.cjs)
                   │
                   ▼
               stages[][]  — partition de la frontière ready en étages sans recouvrement de scope[]
                   │
                   ▼
   ready/count (inchangés) + stages (additif) ────► manager : dispatch d'un étage entier en 1 message
```

**Trois états du champ `stages`, jamais confondus** (contrat documenté, T29-T33) :
- **tableau d'étages** — calcul réussi ;
- **`[]`** — frontière `ready` vide, **aucun** sous-processus lancé (T30, court-circuit prouvé) ;
- **`null`** — dégradé : `node`/`gsd-tools` introuvable **ou** le sous-processus a échoué (T29,
  T31, T32) — le manager retombe alors sur son propre jugement, séquentiel en cas de doute
  (`team-kernel.md` : « Périmètres douteux → séquentiel »).

### Diagramme — flux G3 recommandé (à construire cette phase)

```
disque du lab (CLAUDE.md folder maps · frontmatters skills: · compteurs STATE/ROADMAP)
   │
   ▼
check-map-drift.sh  [advisory par défaut, ADR-031]
   │  grammaire FAIT-jamais-jugement (patron check-doc-drift.sh)
   │  exit 0 = signal émis · exit 3 = rien à signaler / hors-cible (F13, jamais vert-à-vide)
   │  exit 1 = réservé à un futur mode --strict, si jamais construit
   ▼
   ├──► SessionStart hook (conductor, optionnel) — signal compact, jamais bloquant
   └──► validator Phase 3 (dette documentaire) — 8e/9e signal de la grille existante
           │
           ▼
       rapport typé (reports/validator/*.md) — JAMAIS d'auto-fix (ADR-031)
           │
           ▼
       agent/utilisateur juge et déclenche un correctif manuel
```

### Recommended Project Structure (fichiers touchés, hypothèse de plan)

```
plugin/
├── conductor/
│   ├── scripts/
│   │   ├── check-map-drift.sh          # NOUVEAU (G3) — ou sous plugin/validator/scripts/, à trancher au plan
│   │   └── tests/test-check-map-drift.sh
│   └── references/team-kernel.md       # G5 (Edit-Source) si ancré ici — déporté, pas inline agent
├── dev-orchestrator/
│   ├── references/
│   │   ├── mission-contracts.md        # G1 — bullet "NE charge PAS" dans le gabarit digest
│   │   └── mission-flow.md             # G5 alternative d'ancrage — même contrainte de densité
├── validator/
│   └── AGENT.md                        # POINTEUR seulement vers G3 (déjà à 250/250 — zéro ligne ajoutable)
└── reference/content/methodology/patterns/
    └── 03-agents.md / 04-skills.md     # candidats G1 (tables Load/DO NOT Load dans les templates), à confirmer au plan
```

### Pattern — FAIT, jamais jugement (à répliquer pour G3)

**What :** un gate qui constate une divergence mesurable (compteur, ensemble déclaré vs ensemble
réel) sans jamais qualifier cette divergence de « faux » ou « périmé ».
**When to use :** tout script de drift (`check-doc-drift.sh` en est le seul précédent direct dans
ce dépôt).
**Example (source, cité verbatim) :**
```bash
# Source: plugin/dev-orchestrator/scripts/check-doc-drift.sh:4-7
# Rôle (ADR-055 §3) : répondre au FAIT, jamais au métier. Ce script ne dit JAMAIS que la doc est
# fausse ou périmée — seulement qu'elle N'A PAS BOUGÉ depuis N commits de code. C'est le jugement
# de l'agent (ou de l'utilisateur) de décider si cette absence de mouvement est un problème réel.
```

### Pattern — wrapper `git_safe()` (obligatoire pour tout G3 qui shell-out vers git)

**What :** toute invocation `git` passe par un wrapper unique qui neutralise `hooksPath`,
`fsmonitor` et les locks optionnels, plus trois variables d'environnement.
**When to use :** dès qu'un script lit l'historique/les chemins d'un dépôt qui pourrait être un
clone non maîtrisé (branche/PR hostile) — exactement le cas d'un lint lancé en `SessionStart`.
**Example (source, cité verbatim) :**
```bash
# Source: plugin/dev-orchestrator/scripts/check-doc-drift.sh:109-115
export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
export GIT_OPTIONAL_LOCKS=0

git_safe() { # <args...> — toute invocation git de ce script passe par ici, jamais un appel nu.
  git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"
}
```

### Pattern — grammaire d'exit code 0/1/3(/64), transverse à tout le dépôt

**What :** une convention unique tenue par `check-doc-drift.sh`, `check-agents.sh`,
`check-overlaps.sh`, `detect-planning-debt.sh` :

| Exit | Signification | Précédent |
|---|---|---|
| `0` | signal/verdict positif émis (ou hors-argument, `--help`) | `check-doc-drift.sh:149` (`[doc-drift]` émis) |
| `1` | non-conformité bloquante détectée (mode nu/`--strict`) | `check-agents.sh` (mode nu, non-conformités) |
| `3` | INDÉTERMINÉ — rien à constater, cible absente/vide, hors dépôt git (garde F13 anti-vert-à-vide, **jamais** un exit 0 déguisé) | `check-doc-drift.sh:153`, `check-agents.sh` (`--strict` sans cible) |
| `64` | argument invalide (convention BSD `EX_USAGE`) | `check-doc-drift.sh:60`, tous les gates du dépôt |

**When to use :** tout nouveau script de gate de cette phase (G3 en premier lieu) doit s'aligner
sur cette grammaire — un lecteur du dépôt (humain ou agent) la connaît déjà par les quatre
précédents.

### Anti-Patterns to Avoid

- **Réimplémenter la comparaison de `scope[]` localement** (dans `dag.sh` ou dans un script G1) —
  interdit par construction : `dag.sh:167-168` porte l'interdiction en commentaire de code
  (`[VERIFIED: plugin/conductor/scripts/dag.sh:167-168]` — « ne reimplemente AUCUNE comparaison
  de scope[] localement (ADR-069, Iron Law 2 revisee) ») et `test-dag.sh` T33 est un test de
  **non-régression par mutation** sur exactement ce type de réintroduction (candidat de résolution
  cwd-relatif).
- **Ajouter de la doctrine inline dans `vf-dev-manager.md` ou `validator/AGENT.md`** — les deux
  sont à 250/250 lignes, marge zéro (`[VERIFIED: wc -l cette session sur les deux fichiers]`).
  Toute ligne ajoutée à l'un des deux sans retrait équivalent fait échouer le gate de densité
  ADR-029 au merge.
- **G3 avec un mode « update » par défaut** — violerait ADR-031 directement ; le seul précédent du
  dépôt qui fait un pas dans cette direction (`DOCF-03`, Phase 22) le fait sous un garde-fou en
  trois temps explicite, jamais par défaut.

## Investigation `dag.sh --scope` — précondition transverse (livrable complet)

> Ce bloc répond intégralement à la demande explicite de Samuel : « je veux aussi investiguer
> l'histoire du DAG --scope car pas de régression autorisée ». Toutes les affirmations ci-dessous
> sont sourcées `fichier:ligne`, lues cette session, ou `commit` rejoué avec `git show`.

### 1. Reconstitution historique — deux phases, pas une

**Correction factuelle sur la citation du cadrage.** `29-CONTEXT.md` cite « l'historique Phase
27/D-13 » comme source du mécanisme `--scope`. C'est **imprécis** : les identifiants de décision
(`D-01`, `D-02`…) sont **scopés par fichier `*-CONTEXT.md`**, pas globalement uniques dans ce
dépôt. Le `D-13` qui a introduit `--scope` est celui de **`20-CONTEXT.md`** (Phase 20), pas celui
de `27-CONTEXT.md` — ce dernier porte un `D-13` sans rapport (« Tout chiffre gravé porte sa
méthode et se re-dérive au moment de l'écriture », `[VERIFIED: .planning/phases/VFDO-27-*/27-
CONTEXT.md:155-156]`). Un lecteur qui suivrait « Phase 27/D-13 » à la lettre atterrirait sur le
mauvais artefact. La reconstitution précise, par commit :

| Étape | Commit | Date | Ce qui existait avant/après |
|---|---|---|---|
| Avant tout scope | `60576e9` (extraction team-kernel) | antérieur à Phase 20 | `dag.sh` **ne porte aucune occurrence** du mot `scope` — `[VERIFIED: git show 60576e9:plugin/conductor/scripts/dag.sh \| grep -c scope → 0, exécuté cette session]` |
| **Phase 20, plan 20-02** | `d549b2d` | 2026-07-27 (msg : « Phase 20 — Fluidité du flux de dev... ») | Introduit `--scope` sur `dag.sh add` (D-13, `20-CONTEXT.md`), `review_regime=full` forcé sur `reopen` d'un nœud revue/join (D-14), et `status --frozen` (table des périmètres gelés, D-15 §2). **Déclaration et lecture tolérante seulement — aucun calcul de disjonction à ce stade.** `[VERIFIED: git show d549b2d:plugin/conductor/scripts/dag.sh \| grep -c scope → 11, exécuté cette session]` |
| **Phase 27** | `27abc07` (PR #35) | 2026-08-10 | Ajoute le champ `stages` sur `dag.sh ready` (câblage `partitionStages()` en sous-processus, ADR-069) **et** ferme une RCE réelle dans `resolve_gsd_tools_cmd()` (candidat cwd-relatif retiré, ADR-070). `[VERIFIED: git show 27abc07 --stat → dag.sh +110/-4, test-dag.sh +182, exécuté cette session]` |

**Ce que cette correction change pour le plan** : citer « Phase 27/D-13 » dans un artefact produit
par cette phase serait faux. La forme correcte est **« Phase 20 (déclaration du périmètre, D-13
de `20-CONTEXT.md`) puis Phase 27 (calcul de la disjonction via `stages`, plus fermeture RCE,
ADR-069/070) »**.

### 2. Consommateurs de `scope[]` — inventaire exhaustif

Tous les points de lecture/écriture de `scope[]` trouvés dans ce dépôt, avec leur nature exacte :

| Consommateur | Fichier:ligne | Nature | Citation |
|---|---|---|---|
| `dag.sh add` | `plugin/conductor/scripts/dag.sh:222-224` | **Écriture seule** — construction du nœud | `[VERIFIED]` « `node["scope"] = scope  # affectation directe unique : CONSTRUCTION du noeud, jamais une lecture (P-02)` » |
| `dag.sh ready` → `build_ready_manifest()` | `plugin/conductor/scripts/dag.sh:150-162` | **Lecture tolérante** — construit le manifeste envoyé au sous-processus amont | `[VERIFIED]` « `"files_modified": n.get("scope", []),` … « Lecture tolerante a l'absence (P-02) : jamais d'acces direct a `scope`. » |
| `dag.sh ready` → `compute_stages()` | `plugin/conductor/scripts/dag.sh:164-196` | **Câblage** — sous-processus `gsd-tools claude-orchestration emit-workflow`, **jamais** de comparaison locale | `[VERIFIED]` « ne reimplemente AUCUNE comparaison de scope[] localement (ADR-069, Iron Law 2 revisee) » (l.167-168) |
| `dag.sh status` → `frozen[]` | `plugin/conductor/scripts/dag.sh:285-306` | **Lecture tolérante**, dérive la table des « périmètres gelés » (tout nœud non-`done` à scope non-vide) | `[VERIFIED]` « Lecture tolerante a l'absence (P-02) : node.get("scope", []) jamais un acces direct. … C'est la source unique et vivante de la table des fichiers geles » |
| `team-kernel.md`, table « Plan de bataille » | `plugin/conductor/references/team-kernel.md:19` | **Doctrine** — documente la frontière `ready` comme liste dispatchable en parallèle quand les périmètres sont disjoints | `[VERIFIED]` « la frontière `ready` est une **liste à dispatcher en parallèle** quand les périmètres sont disjoints » |
| `mission-flow.md`, Pattern B §stages | `plugin/dev-orchestrator/references/mission-flow.md:92-126` | **Doctrine** — documente le contrat complet (`ready`/`count` inchangés, `stages` additif, la cascade de résolution, le repli `null`/`[]`) | `[VERIFIED]` « la garantie ne vaut que ce que vaut le `scope[]` déclaré à la pose du nœud (`dag.sh add --scope=...`) » (l.105-106) |
| `mission-flow.md`, Pattern E §Pose du nœud | `plugin/dev-orchestrator/references/mission-flow.md:244-249` | **Doctrine** — le périmètre est déclaré à la pose, ce qui rend calculable le critère (b) (fichier partagé avec une mission parallèle en vol) de la gradation de revue | `[VERIFIED]` « Le périmètre (`--scope`) est déclaré à la pose : c'est ce qui rend calculable le critère (b) de la §3 ci-dessous » |
| `mission-contracts.md`, gabarit digest | `plugin/dev-orchestrator/references/mission-contracts.md:59` | **Doctrine** — chaque mandat de worker embarque le périmètre déclaré du nœud | `[VERIFIED]` « - Périmètre de fichiers du nœud : <déclaré au dag add> » |
| `team-kernel.md`, règle « Dispatch parallèle par défaut » | `plugin/conductor/references/team-kernel.md:123-125` | **Doctrine** — le jugement manuel du manager que `stages` vient soulager | `[VERIFIED]` « ≥ 2 nœuds `ready` à périmètres disjoints → un seul message, plusieurs Task. Périmètres douteux → **séquentiel** » |
| `check-agents.sh` (`isolation:` frontmatter) | `plugin/conductor/scripts/check-agents.sh` (cité `:39,160,528-530` par `27-CONTEXT.md`) | **Objet distinct, à ne pas confondre** — `isolation: worktree` est une décision de dispatch séparée (issue #38), jamais dérivée de `scope[]` | `team-kernel.md:126-138` : « L'isolation est une décision de DISPATCH, jamais une propriété du worker » |
| `check-overlaps.sh` | `plugin/conductor/scripts/check-overlaps.sh:1-9` | **Objet distinct, piège de nommage documenté (D-08, Phase 27)** — routage de briques tierces (ADR-057), jamais disjonction de fichiers | En-tête du script : « Inventaire des recouvrements de déclenchement avec les briques TIERCES » |

### 3. Couverture de `test-dag.sh` sur le scope (501 lignes, T1-T33)

| Cas | Ce qu'il prouve |
|---|---|
| **T13** (`plugin/conductor/scripts/tests/test-dag.sh:167-181`) | `--scope` déclare et persiste le périmètre du nœud (2 entrées exactes, espaces rognés, entrée vide ignorée — même règle que `--deps`) |
| **T14, T22, T28** | Rétro-compatibilité : un DAG écrit par une version antérieure au champ `scope` (clé absente) ne fait jamais planter `ready`/`status`/`mark`/`reopen`/`tree` — lecture tolérante prouvée, pas seulement affirmée |
| **T20, T21** | `status --frozen` : un nœud non-`done` à scope non-vide apparaît ; un nœud `done` ou à scope vide est exclu ; la clé `frozen` est **toujours présente**, même vide — jamais absente |
| **T24, T27.3** | Déterminisme : deux appels consécutifs produisent une sortie identique octet pour octet |
| **T25** | Deux nœuds `ready` déclarant le **même** chemin dans `scope[]` sortent dans **deux étages distincts** |
| **T26** | Deux nœuds `ready` à scope **disjoint** sortent dans **le même** étage |
| **T27.1-2** | En présence de `stages`, `ready`/`count` gardent **exactement** leurs valeurs d'avant ce mécanisme — non-régression du contrat de sortie |
| **T29** | CLI amont totalement introuvable (PATH + `GSD_TOOLS` + `CLAUDE_CONFIG_DIR` + `HOME` neutralisés) → `stages: null`, jamais un crash |
| **T30** | Frontière `ready` vide → `stages: []` **sans lancer de sous-processus** (preuve du court-circuit, pas seulement d'un résultat différent) |
| **T31** | CLI résolue mais qui échoue (`returncode != 0`) → `stages: null`, **jamais `[]`** (cible précisément la ligne `if result.returncode != 0: return None`) |
| **T32** | `node` absent mais `gsd-tools` (.cjs) résolu → `stages: null` via l'absence de `node` spécifiquement |
| **T33** | **Non-régression de la RCE fermée (ADR-070)** : un `gsd-tools.cjs` tracké au CWD n'est jamais résolu ni exécuté, même avec `node` disponible — preuve par deux signaux indépendants (fichier marqueur absent, contenu JSON piégé absent) |

**Verdict de couverture** : le mécanisme de disjonction (`stages`), le repli dégradé (`null` vs
`[]`), la rétro-compatibilité, et la fermeture de la RCE sont **tous** couverts par mutation ou
par cas explicite. Il n'y a **aucun trou visible** dans `test-dag.sh` sur le périmètre `--scope` —
c'est la suite la plus exhaustive du dépôt sur un seul script (33 cas nommés).

### 4. Intouchable / extensible / voie recommandée pour G1

**INTOUCHABLE (ne jamais modifier)** :
- Le mécanisme de câblage `compute_stages()` lui-même — toute réimplémentation locale de la
  comparaison de `scope[]` est interdite par ADR-069 (Iron Law 2 révisée) et déjà gardée par T33.
- La cascade de résolution `resolve_gsd_tools_cmd()` — ne **jamais** réintroduire un candidat
  relatif au CWD ou à la racine du dépôt (`git rev-parse --show-toplevel`). C'est le 5e passage
  documenté du même motif de faille (ADR-070) ; un 6e serait une régression de sécurité connue,
  pas une découverte.
- La distinction sémantique `stages: null` (dégradé) vs `stages: []` (frontière vide) — toute la
  doctrine du manager en dépend (repli séquentiel sur `null`, pas sur `[]`).
- La forme de sortie `ready`/`count` — contrat byte-exact vérifié par T27.

**EXTENSIBLE SANS RISQUE** :
- Lire `dag.sh status --frozen` en pure consommation (aucune écriture) comme source de donnée
  pour n'importe quel script ou digest — c'est un champ déjà vivant, déjà testé (T20/T21), déjà
  déterministe (T24).
- Ajouter une **nouvelle** action/flag purement additive à `dag.sh` qui ne touche à aucune clé de
  sortie existante — le même patron de non-régression que `stages` lui-même (Phase 27 a prouvé que
  c'est faisable en gardant `ready`/`count` intacts).
- Étendre la doctrine textuelle de `team-kernel.md`/`mission-flow.md` — aucune surface de code.

**VOIE RECOMMANDÉE pour le « négatif du scope » de G1** : D-03 pose la voie « doctrine seule,
manager rédige » comme repli sûr **si** un geste G1 exige de toucher `dag.sh`. L'investigation
montre que **ce repli n'a même pas besoin d'être activé** : le nœud connaît déjà son propre
`scope[]` (threadé dans son digest via `mission-contracts.md:59`), et le manager a déjà accès à
`dag.sh status --frozen` (les périmètres gelés des **autres** nœuds en vol). Le « négatif » —
« ce que ce mandat ne doit PAS toucher » — se compose donc entièrement d'une opération de
lecture sur deux champs déjà émis : *(périmètre déclaré des autres nœuds actuellement gelés)
moins (périmètre déclaré de ce nœud)*. **Recommandation : livrer G1 en pur ajout doctrinal au
gabarit du digest (`mission-contracts.md`), zéro ligne de code touchée dans `dag.sh`.** Si un
futur besoin réclame un négatif *machine-vérifié* plutôt que composé par le manager, il devra
suivre la même discipline de câblage que `stages` (sous-processus vers l'amont, jamais une
réimplémentation) — mais ce n'est pas un prérequis pour livrer G1 dans cette phase.

**Conséquence pour le découpage du plan** : G1 se scinde proprement en deux livrables
indépendants et tous deux sans risque — (a) les tables statiques « Load / DO NOT Load » dans les
templates d'agents et `CLAUDE.md` scaffoldés (aucune dépendance à `--scope`), et (b) la ligne
« NE charge PAS » du digest de mission, dérivée en doctrine des champs `dag.sh` déjà émis (aucune
dépendance à un nouveau code `dag.sh`).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Disjonction/partition de périmètres de fichiers | Un comparateur de `scope[]` maison dans `dag.sh` ou un script G1 | `dag.sh status --frozen` (déjà émis) + `dag.sh ready .stages` (déjà câblé vers `partitionStages()`) | Interdit par ADR-069 (Iron Law 2 révisée) ; gardé par mutation (T33) |
| Détection de drift documentaire | Un parseur AST complet des `CLAUDE.md`/frontmatters | Étendre `check-doc-drift.sh` (grammaire FAIT) + réutiliser les helpers de tokenisation de `check-agents.sh` (`bare_tokens()`, extraction de champ frontmatter) | Ces deux scripts résolvent déjà 80 % du problème de bas niveau (parsing frontmatter, git durci) |
| Validation d'ensemble déclaré vs réel (skills:, folder maps) | Un nouveau linter de frontmatter | `check-agents.sh` valide déjà `skills:` (existence, Phase 13/GSDM) — G3 vérifie un axe **différent** (le folder map en prose vs le disque), pas le même axe que `check-agents.sh` — ne pas dupliquer ce qu'il couvre déjà |
| Confirmation humaine avant correctif | Une nouvelle mécanique de confirmation pour G3 | Le patron `DOCF-03` (Phase 22) : reformulation du nombre + liste affectée, attente d'un oui explicite, interdiction en mission/autonome | Déjà écrit, déjà éprouvé, ADR-031 conforme |

**Key insight** : ce dépôt a une politique explicite (ADR-069, Iron Law 2 révisée) contre la
réimplémentation de logique amont partiellement couverte — et une politique tout aussi explicite
(ADR-070) contre la réintroduction de vecteurs de résolution de chemin non ancrés. Les deux
s'appliquent directement à toute tentation de « faire plus simple » en écrivant une comparaison
de scope maison pour G1.

## Common Pitfalls

### Pitfall 1 — Citer « Phase 27/D-13 » comme source de `--scope`
**What goes wrong :** un lecteur qui suit cette citation littéralement dans `27-CONTEXT.md` trouve
un D-13 sans rapport avec le scope (« tout chiffre gravé porte sa méthode »).
**Why it happens :** les identifiants de décision sont scopés par fichier, pas globaux — deux
`*-CONTEXT.md` différents peuvent réutiliser le même numéro pour des sujets sans rapport.
**How to avoid :** citer « Phase 20 (D-13 de `20-CONTEXT.md`) » pour la déclaration du scope, et
« Phase 27 » (sans D-13) pour le calcul de `stages` et la fermeture RCE.
**Warning signs :** toute recherche future qui grep `D-13` dans plusieurs `*-CONTEXT.md` sans
préciser le fichier retombera dans le même piège.

### Pitfall 2 — G3 qui dérive vers le territoire des DAG de mission
**What goes wrong :** un script de drift carte↔disque qui, par extension naturelle, se met à
vérifier aussi la cohérence des `*.dag.json` de mission.
**Why it happens :** les deux problèmes (« la doc ment-elle ? » et « le DAG ment-il ? ») semblent
proches.
**How to avoid :** garder G3 strictement sur son domaine déclaré par CONTEXT.md — folder maps des
`CLAUDE.md`, `skills:` des frontmatters, compteurs STATE/ROADMAP. Les fichiers DAG de mission sont
hors de son périmètre ; les toucher romprait l'isolation du socle `--scope` que D-03 protège.

### Pitfall 3 — Addition doctrinale sur un fichier au plafond de densité
**What goes wrong :** un plan ajoute 5 lignes de doctrine G5 (Edit-Source) directement dans
`vf-dev-manager.md`, qui échoue ensuite au gate ADR-029 (250/250, zéro marge).
**Why it happens :** `vf-dev-manager.md` est l'endroit le plus intuitif pour une règle « le
manager doit… » — mais c'est précisément le fichier le plus saturé du dépôt.
**How to avoid :** déporter systématiquement en `references/` (team-kernel.md à 186/? lignes,
mission-flow.md à 415 lignes — tous deux sans plafond ADR-029 car ce sont des références chargées
on-demand, pas des agents). Vérifier `wc -l` avant/après sur `vf-dev-manager.md` **et**
`validator/AGENT.md` à chaque tâche du plan qui les touche, même indirectement.

### Pitfall 4 — G3 avec un mode « update » actif par défaut
**What goes wrong :** le script corrige silencieusement une carte périmée au lieu de se contenter
de la signaler, violant ADR-031.
**Why it happens :** le rapport ICM cite `/icm-sync` comme référence, dont l'amont a un mode
« lint/**update** » — copier cette forme sans l'adapter au garde-fou du dépôt introduit un
correctif automatique non gardé.
**How to avoid :** lint-only par défaut ; si un mode update est livré, le gater par le même
patron en trois temps que `DOCF-03`.

### Pitfall 5 — Confondre les deux « compartiments » du dépôt (G2)
**What goes wrong :** un plan G2 pose un `CONTEXT.md` par compartiment `planning-core` (seuil
d'autonomie, `compartments.md`) en pensant traiter le sujet ICM, alors que le rapport vise les
`docs/<projet>/` posés par `scaffold-docs.sh` (ADR-042).
**Why it happens :** le même mot « compartiment » désigne deux objets sans lien logique dans ce
dépôt — l'un est une unité de planning (`.planning/` conditionnel, seuil d'autonomie), l'autre une
unité de documentation de module (`docs/<projet>/INDEX.md`+`REFERENCE.md`).
**How to avoid :** le plan doit nommer explicitement lequel des deux objets il étend, et vérifier
qu'il ne réutilise pas le nom `INDEX.md` pour le pattern `_index.md` d'ICM (qui a une sémantique
différente — index de dossier de références > 10 fichiers — de l'`INDEX.md` de tableau de bord de
compartiments déjà posé par `planning-core`).

## Code Examples

### Le gabarit digest de mission à étendre pour G1 (source, cité verbatim)

```
# Source: plugin/dev-orchestrator/references/mission-contracts.md:56-63
DIGEST (cache — le disque fait foi)
- Mission : <objectif en 1 ligne> · Mode : <superviser|autonome>
- Étape courante : <n° + objectif + critères de succès>
- Périmètre de fichiers du nœud : <déclaré au dag add>
- Décisions actives : <2-5 lignes — panels tranchés, contraintes session>
- Verdicts amont utiles : <revue/audit/test pertinents pour ce mandat>
- Conventions cibles : <2-3 lignes du CLAUDE.md projet qui engagent ce mandat>
```
G1 y ajoute une ligne — p. ex. `- NE charge PAS : <dérivé de status --frozen minus le périmètre du
nœud>` — sans toucher au reste du gabarit ni à `dag.sh`.

### La sortie `dag.sh status --frozen` (source, forme exacte)

```json
{
  "file": "...", "total": 3, "counts": { "...": "..." },
  "ready": ["..."],
  "frozen": [
    { "id": "exec-2", "status": "running", "scope": ["src/b/**"] }
  ]
}
```
`[VERIFIED: plugin/conductor/scripts/dag.sh:285-306, et test-dag.sh T20/T21 vérifient exactement
cette forme — clé toujours présente, y compris `[]` quand rien n'est gelé]`.

### Grammaire d'exit code à reproduire pour `check-map-drift.sh`

```bash
# Patron à suivre — Source: plugin/dev-orchestrator/scripts/check-doc-drift.sh:56-60
# Exit codes:
#   0  = signal émis (divergence détectée)
#   3  = rien à signaler (hors cible, ou sous le seuil — jamais un vert déguisé sur cible absente)
#   64 = argument invalide
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Le manager arbitre lui-même si deux nœuds `ready` peuvent être dispatchés ensemble | `dag.sh status --frozen` dérive une table machine-vérifiable des périmètres gelés | Phase 20, `d549b2d`, 2026-07-27 | Le manager n'a plus à re-dériver à la main la table des fichiers gelés — source vivante, jamais une copie figée |
| Frontière `ready` dispatchée à plat, un jugement manuel par nœud | Champ `stages` : partition machine-calculée sans recouvrement de scope, câblée sur l'amont | Phase 27, `27abc07`, 2026-08-10 | Un manager peut dispatcher un étage entier en un seul message sans arbitrer lui-même les périmètres |
| Cascade de résolution `gsd-tools` incluait un candidat cwd-relatif | Candidat retiré entièrement (pas d'ancrage, pas de repli déguisé) | Phase 27, ADR-070, 2026-08-10 | Ferme le 5e passage documenté d'une RCE par confinement de chemin — précédent direct pour toute future résolution de binaire externe dans ce dépôt |

**Déprécié/périmé :** aucune forme antérieure de `dag.sh` n'est plus en usage — la version
actuelle (post-Phase 27) est la seule référence valide pour cette phase.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | La Phase 3 (« dette documentaire », grille des 7 signaux) de `vibeflow-validator/AGENT.md` est l'ancrage le plus cohérent pour G3, plutôt qu'un hook `SessionStart` isolé | Architecture Patterns, Summary | Faible — CONTEXT.md délègue déjà ce choix à la discrétion du planner ; si l'ancrage diffère, aucune régression fonctionnelle, seulement un rangement différent |
| A2 | Un préfixe d'ID de requirement du type `ICMG`/`ICMD` est une suggestion de forme cohérente avec la convention du dépôt, pas une décision | Phase Requirements | Nulle — le planner choisit librement au moment de créer les IDs, aucune dépendance technique |
| A3 | G2 vise le compartiment `docs/<projet>/` de `scaffold-docs.sh` (ADR-042), pas le compartiment `planning-core` à seuil d'autonomie | G2 — Pitfall 5, Architecture Patterns | Moyen si faux — un plan qui étendrait le mauvais mécanisme romprait la doctrine `INDEX.md` déjà posée au niveau lab (planning-core), sans le vouloir |

**Si cette table semble courte** : c'est volontaire — l'essentiel des affirmations de ce RESEARCH
sur `dag.sh --scope` sont `[VERIFIED]` (lues sur pièce, commit rejoué, ligne citée), pas
`[ASSUMED]`. Les seules zones d'hypothèse sont celles explicitement déléguées à la discrétion du
planner par `29-CONTEXT.md` (emplacement de G3, forme d'ID, cible exacte de G2).

## Open Questions (RESOLVED)

1. **G2 — quel « compartiment » exactement ?**
   RESOLVED : tranché par le plan 29-04, qui adopte la recommandation telle quelle — deux
   livrables séparés (contrainte ≤ 80 lignes sur `INDEX.md` + pattern `_index.md` nouveau).
   - What we know : le rapport ICM vise un `CONTEXT.md` de routing par unité de documentation ;
     `scaffold-docs.sh` pose déjà `docs/<projet>/INDEX.md` (routing pur, ≤ 80 lignes de fait vu sa
     taille actuelle) qui remplit presque ce rôle.
   - What's unclear : faut-il renommer `INDEX.md` en `CONTEXT.md`, ajouter un `CONTEXT.md`
     distinct à côté, ou considérer `INDEX.md` déjà conforme et se concentrer sur le pattern
     `_index.md` (scaling > 10 fichiers) qui, lui, n'existe nulle part encore ?
   - Recommendation : traiter les deux comme des livrables séparés — (a) vérifier/durcir que
     `docs/<projet>/INDEX.md` reste ≤ 80 lignes (contrainte, pas juste un fait actuel), (b) ajouter
     le pattern `_index.md` comme un mécanisme **nouveau**, cible `docs/reference/` (77 fichiers
     cités par le rapport ICM) et les gros `references/` de module.

2. **G3 — lint-only v1 suffit-il, ou faut-il déjà prévoir le mode update ?**
   RESOLVED : tranché par le plan 29-02 — lint-only livré, aucun mode correctif (ADR-031),
   bornes de non-couverture écrites en en-tête du script.
   - What we know : ADR-031 impose la validation humaine ; `DOCF-03` a déjà le patron du garde-fou
     en trois temps si un mode update est un jour voulu.
   - What's unclear : CONTEXT.md laisse le choix « lint-only vs lint+update » explicitement à la
     discrétion du planner.
   - Recommendation : livrer lint-only pour cette phase — le mode update ajouterait une surface
     de risque (ADR-031) sans qu'aucun besoin exprimé ne le réclame encore ; le rapport ICM lui-
     même note que la vérification de son propre système source (ICM) est 100 % humaine.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `git` | G3 (`check-map-drift.sh`), déjà requis par `check-doc-drift.sh`/`detect-planning-debt.sh` | ✓ (dépendance système déjà exercée par 4 scripts existants) | — | — |
| `python3` | `dag.sh` (déjà une dépendance dure, non nouvelle pour cette phase) | ✓ (exercé par `test-dag.sh` T29/T31/T32) | — | — |
| `node` + `gsd-tools` | `dag.sh ready .stages` uniquement — **hors du périmètre modifié par cette phase** | ✓/dégradé géré (repli `null` déjà prouvé) | — | Repli documenté et testé (`stages: null`, jamais un crash) |

**Missing dependencies with no fallback :** aucune — cette phase ne modifie aucune dépendance
d'environnement, elle documente et consomme des mécanismes déjà tolérants aux absences.

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | Bash artisanal (assertions maison `assert`/`assert_not`/`assert_exit`), un fichier `test-<script>.sh` par script, sous `plugin/<module>/scripts/tests/` — aucun framework externe (pas de pytest/jest/bats) |
| Config file | Aucun — chaque suite est un script autonome invoqué directement |
| Quick run command | `bash plugin/conductor/scripts/tests/test-dag.sh` (suite existante, 33 cas, ~1-2 s) — pour un nouveau `check-map-drift.sh` : `bash plugin/<module>/scripts/tests/test-check-map-drift.sh` |
| Full suite command | Rejouer chaque `test-*.sh` du dépôt sous `plugin/*/scripts/tests/` — le compte total (« N suites ») vit dans les deux README racine et **doit être re-dérivé, jamais recopié** (précédent : erreur de compte documentée trois fois dans `STATE.md`, ex. 39→41→42→45 selon les phases) |

### Phase Requirements → Test Map

Aucun ID `REQ-XX` n'existe encore (voir `<phase_requirements>`). Forme attendue une fois les IDs
créés au plan :

| Req ID (hypothèse) | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| G3-xx (map-drift) | Le script signale une divergence carte↔disque construite en fixture | unit/bash | `bash plugin/<module>/scripts/tests/test-check-map-drift.sh` | ❌ Wave 0 — à créer |
| G3-xx (vacuous green) | Cible absente/vide → exit 3, jamais exit 0 (F13) | unit/bash | même fichier, cas dédié | ❌ Wave 0 |
| G1-xx (digest négatif) | Aucun test comportemental — c'est un ajout de gabarit textuel, vérifiable par `grep`/lecture, pas par exécution | doc/manual | — | N/A (pas un artefact exécutable) |
| G5-xx (Edit-Source) | Aucun test comportemental — règle doctrinale, vérifiable par présence de texte + gate de densité | doc/manual + `wc -l` | `wc -l plugin/conductor/references/team-kernel.md` (ou l'endroit choisi) | N/A |
| Investigation --scope | Livrable écrit — vérifié par citation, pas par exécution | doc/manual | — | N/A (ce RESEARCH.md est la preuve) |

### Sampling Rate

- **Per task commit** : `bash plugin/conductor/scripts/tests/test-dag.sh` (non-régression du
  socle scope, **obligatoire** avant tout commit qui touche de près ou de loin `dag.sh` ou sa
  doctrine, même si cette phase ne prévoit pas de le modifier).
- **Per wave merge** : rejouer toute suite `test-*.sh` du/des module(s) touché(s) (`conductor`,
  `dev-orchestrator`, `validator` selon l'ancrage retenu pour G3).
- **Phase gate** : `bash plugin/conductor/scripts/check-agents.sh --strict` (si un agent est
  touché) + vérification `wc -l` sur `vf-dev-manager.md` et `validator/AGENT.md` avant
  `/gsd-verify-work`.

### Wave 0 Gaps

- [ ] `plugin/<module>/scripts/tests/test-check-map-drift.sh` — n'existe pas, à créer pour G3 (le
  script lui-même n'existe pas non plus).
- [ ] Aucun gap pour G1/G5 : ce sont des ajouts textuels sans surface exécutable, vérifiables par
  lecture + gate de densité existant.
- [ ] Aucun gap pour l'investigation `--scope` : c'est ce document.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | non | aucune surface d'auth dans cette phase |
| V3 Session Management | non | — |
| V4 Access Control | non | — |
| V5 Input Validation | **oui** | tout script G3 qui shell-out vers `git` doit copier verbatim le wrapper `git_safe()` (`check-doc-drift.sh:109-115`) — un dépôt cloné hostile ne doit jamais pouvoir exécuter de code via sa propre config `.git/config` lors d'un simple lint |
| V6 Cryptography | non | aucune primitive crypto touchée |

### Known Threat Patterns for ce dépôt (bash/python3/git tooling, plugin Claude Code)

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Résolution de binaire relative au CWD/à la racine du dépôt → exécution de code arbitraire (5 passages documentés dans ce dépôt, le dernier fermé par ADR-070) | Tampering / Elevation of Privilege | Cascade de résolution limitée à : variable d'environnement (chemin absolu) → `PATH` → répertoire fixe (`CLAUDE_CONFIG_DIR`/`~/.claude`) — **jamais** un candidat dérivé du CWD ou de `git rev-parse --show-toplevel`. Toute nouvelle résolution de binaire externe introduite par cette phase (aucune prévue) doit suivre ce patron et porter un test de mutation type T33. |
| Exécution de config git non maîtrisée pendant un lint en lecture seule | Tampering | Wrapper `git_safe()` (`-c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks` + `GIT_CONFIG_NOSYSTEM=1`/`GIT_TERMINAL_PROMPT=0`/`GIT_OPTIONAL_LOCKS=0`) — obligatoire pour tout script G3 qui lit l'historique git |
| Vert-à-vide (vacuous green) sur un ensemble de cibles absent/vide | Repudiation (fausse assurance de conformité) | Grammaire d'exit 0/1/3 : exit 3 = INDÉTERMINÉ sur cible absente/vide, jamais un exit 0 déguisé (patron F13, `check-agents.sh`/`detect-planning-debt.sh`) |
| Correctif automatique sans validation humaine | Elevation of Privilege (un agent écrit sans revue) | ADR-031 : G3 par défaut lint-only ; tout mode update opt-in gardé par confirmation explicite (patron `DOCF-03`) |

## Sources

### Primary (HIGH confidence — lu sur pièce cette session)

- `plugin/conductor/scripts/dag.sh` (359 lignes, lu intégralement)
- `plugin/conductor/scripts/tests/test-dag.sh` (501 lignes, lu intégralement)
- `plugin/conductor/references/team-kernel.md` (186 lignes, lu intégralement)
- `plugin/dev-orchestrator/references/mission-flow.md` (415 lignes, lu intégralement)
- `plugin/dev-orchestrator/references/mission-contracts.md` (337 lignes, lu intégralement)
- `plugin/dev-orchestrator/scripts/check-doc-drift.sh` (153 lignes, lu intégralement)
- `plugin/conductor/scripts/scaffold-docs.sh` (89 lignes, lu intégralement)
- `plugin/planning-core/references/compartments.md` (142 lignes, lu intégralement)
- `plugin/validator/AGENT.md` (extraits, phases 1-3 + délégations, lu sur pièce)
- `plugin/conductor/scripts/check-agents.sh` (extraits — en-tête, grammaire d'exit, en-tête de
  `check-overlaps.sh`)
- `docs/ADR.md` ADR-069 (l.1922-2172) et ADR-070 (l.2176-2201+), lues intégralement
- `.planning/phases/VFDO-27-*/27-CONTEXT.md` (lu intégralement)
- `.planning/phases/VFDO-29-*/29-CONTEXT.md` (lu intégralement, fourni en entrée)
- `.planning/REQUIREMENTS.md` (781 lignes, lu intégralement en deux passes)
- `.planning/STATE.md` (901 lignes, lu en deux passes)
- `git show`/`git log` sur les commits `60576e9`, `d549b2d`, `27abc07` (rejoués cette session)
- `reports/research/2026-08-15-icm-deep-search.md` (278 lignes, lu intégralement — source du
  périmètre G1-G5)

### Secondary (MEDIUM confidence)

- Aucune — cette recherche n'a mobilisé aucune source web ; le domaine est 100 % interne au dépôt
  et déjà entièrement documenté sur pièce.

### Tertiary (LOW confidence)

- Aucune.

## Metadata

**Confidence breakdown :**
- Investigation `dag.sh --scope` : HIGH — toutes les affirmations sont sourcées `fichier:ligne` ou
  `commit` rejoué cette session, avec citations verbatim.
- Standard stack / Package legitimacy : HIGH — aucune nouvelle dépendance, vérification directe.
- Placement de G2/G3/G5 : MEDIUM — raisonné depuis les conventions du dépôt (densité, grammaire
  d'exit, patron FAIT-jamais-jugement) mais explicitement laissé à la discrétion du planner par
  `29-CONTEXT.md` ; ne pas présenter ces recommandations comme verrouillées.
- Pitfalls : HIGH — tous sourcés depuis des fichiers lus cette session (dont l'erreur de citation
  D-13 elle-même, vérifiée par commande git).

**Research date :** 2026-08-15
**Valid until :** jusqu'à la prochaine modification de `dag.sh`/`team-kernel.md`/`mission-flow.md`
(fichiers socle à haute fréquence de changement — 2 phases l'ont déjà touché en un mois) ;
re-vérifier `wc -l` sur `vf-dev-manager.md` et `validator/AGENT.md` immédiatement avant le plan,
ces compteurs peuvent avoir bougé entre cette recherche et la planification.

## RESEARCH COMPLETE
