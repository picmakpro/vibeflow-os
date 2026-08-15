# Phase 27 : Parallélisation d'exécution — granulaire, simple, sans collision — Recherche de planification

**Recherché :** 2026-08-05
**Domaine :** câblage d'une capability amont (`claude_orchestration`), isolation d'écriture
(`isolation: worktree`), fermeture d'un trou de disjonction de périmètres (`dag.sh`)
**Confiance globale :** HAUTE sur tout ce qui est vérifié sur pièce cette session (fichiers lus,
commandes exécutées, sorties observées) · BASSE sur un seul point non résolu par preuve sur pièce
(honnêteté de `GSD_AGENT_SDK_VERSION`, voir Livrable 4) — signalé comme tel, jamais présenté comme
un fait.

Cette recherche **prolonge** `.planning/research/2026-08-05-parallelisation-execution.md` (497 l.)
et la spec `docs/superpowers/specs/2026-08-05-parallelisation-execution-design.md` (225 l.). Elle ne
refait pas ce qu'elles ont déjà établi (échelle de gates, gain mesuré 3,00×, `isolation: worktree`
comme mécanisme réel) — elle répond aux six questions techniques que le cadrage (`27-CONTEXT.md`)
a explicitement laissées à la recherche.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01 — Chemin retenu : 1 → spike de 2 → 2.** L'option 1 (`isolation: worktree`) d'abord parce
  qu'elle ne fait rien gagner mais rend le reste sûr (prérequis de sécurité) ; le spike parce que
  l'option 2 (`claude_orchestration`) change le mode de dispatch de toute exécution.
- **D-02 — Décision A (mur ADR-031) : repli « un étage = un workflow ».** Un workflow n'accepte
  aucune entrée utilisateur en cours de run et ses sous-agents tournent toujours en `acceptEdits`.
  Le manager reste hors workflow. **Ce repli doit être re-prouvé sous Workflow pendant le spike du
  livrable 4, pas supposé.**
- **D-03 — Décision B (`worktree.baseRef`) : passer à `"head"`.** Le défaut `"fresh"` branche
  depuis `main` et ferait perdre le travail en cours. C'est un réglage **global** de settings
  (machine de Samuel, hors dépôt), assumé comme tel.
- **D-04** : remplacer, à `team-kernel.md:64-65`, « perdu » par « éteint par défaut ». Re-vérifié le
  2026-08-05 : les lignes 64-68 portent toujours exactement le texte cité.
- **D-05 — Portée `isolation: worktree` : tous les modules portant des agents.** Identification des
  agents écrivains = calcul mécanique (grep `tools:` pour `Write`/`Edit`/`MultiEdit`), pas une
  préférence. Re-vérifié : `check-agents.sh` valide déjà `isolation` (`:158-160`, `:528-530`),
  0 agent sur 25 le déclare.
- **D-06 — Deux manques matériels :** `.claude/worktrees/` absent du `.gitignore` racine,
  `.worktreeinclude` absent. Contenu exact à établir en recherche.
- **D-07 :** `dag.sh` déclare un `scope[]` mais ne calcule jamais la disjonction. Fermeture par
  **câblage** de `partitionStages()`/`emitWorkflowScript` (amont), **jamais réimplémentation**
  (ADR-069, Iron Law 2 révisée). Mécanisme précis = décision de recherche.
- **D-08 — Piège de nommage :** `check-overlaps.sh` traite du routage entre briques tierces
  (ADR-057), pas des périmètres d'écriture. Toute brique produite doit porter un nom distinct.
- **D-09 :** `claude_orchestration` absent de `.planning/config.json` (re-vérifié). Geste du spike =
  poser `enabled: true` + `execution_backend: "auto"`, établir honnêtement
  `GSD_AGENT_SDK_VERSION`, faire aboutir un run Workflow réel. Le gate n°4 n'est qu'un **proxy**.
- **D-10 :** La mesure du gain est un livrable — baseline avant, mesure après, méthode écrite. Le
  plafond 3,00× (Phase 24, compression d'étages) **n'est pas** un gain d'horloge.
- **D-11 — Simple avant complet.** Une solution qui demande de penser à trois choses avant chaque
  dispatch ne sera pas tenue.
- **D-12 — Zéro régression de sécurité de la Phase 24.** Toute primitive de chemin passe par
  `plugin/planning-core/scripts/workstream-policy.sh`, jamais une réimplémentation locale.
- **D-13 — Tout chiffre gravé porte sa méthode et se re-dérive au moment de l'écriture.**

### Claude's Discretion

- Le mécanisme exact de câblage `dag.sh` ↔ `partitionStages()` (sous-processus, format d'échange).
- Le contenu exact du `.worktreeinclude`.
- La liste exacte des agents recevant `isolation: worktree` (calcul mécanique).
- Le design précis du spike (livrable 4) et ses critères de passage/échec.
- Le corpus et la méthode exacts de mesure du gain (livrable 5).
- Découpage en plans, numérotation, nommage des fichiers et scripts produits.
- Cohabitation `isolation: worktree` × `GSD_WORKSTREAM` — à instruire par le chercheur de phase.

### Deferred Ideas (OUT OF SCOPE)

- **Option 3** (partitionneur dans `dag.sh`, réimplémentant `partitionStages`) — réserve si le spike
  de l'option 2 échoue. Pas cette phase.
- Remontée upstream des workflows aveugles aux workstreams — geste de contribution externe, pas du
  code de ce dépôt.
- Item `STATE.md:768-772` (Phase 19) — se résorbe par le livrable 2 ; à cocher en fin de Phase 27.
- La divergence de comptage `workstream`/`.planning/` en dur (7/91 vs 6, 45 vs 73) — **hors
  périmètre de cette phase**, ADR-069 fait foi.

</user_constraints>

<phase_requirements>
## Phase Requirements

Aucun REQ-ID n'est mappé à cette phase (`phase_req_ids` fourni à cette recherche = `null`). Le
ROADMAP §Phase 27 (l. 1833-1943) définit le périmètre par cinq livrables numérotés, pas par des
identifiants `REQUIREMENTS.md` — cohérent avec le patron déjà observé aux Phases 22/23/24, où les
préfixes (`DOCF-`, `GSDC-`, `GSDA-`) sont **créés au moment du plan**, pas hérités du cadrage. Le
planner devra probablement proposer un préfixe neuf (aucun des préfixes existants — `DOCF`, `GSDC`,
`GSDA` — ne couvre la parallélisation d'exécution) et le mapper aux 5 livrables ci-dessous.

</phase_requirements>

---

## Résumé pour le planner

Trois découvertes de cette session changent la forme des tâches à écrire, au-delà de ce que le
cadrage savait déjà :

1. **Le câblage du livrable 3 n'a pas besoin de code neuf dans `dag.sh` pour la logique de
   partition — elle existe déjà en CLI amont.** `gsd-tools claude-orchestration emit-workflow`
   (et `resolve-wave-dispatch`) exposent déjà `partitionStages()`/`emitWorkflowScript()` en
   sous-processus Node, **indépendamment de l'état d'activation de `claude_orchestration`** (voir
   Livrable 3, Q1). `dag.sh` doit shell-out vers cette commande, jamais réimplémenter le calcul.
2. **Les agents `Write` ne sont pas tous des ouvriers — cinq sont des managers**, dont le rôle
   documenté (`team-kernel.md` P3 : « un manager ne produit jamais ») entre en tension avec leur
   propre déclaration `Write`. Le calcul mécanique de D-05 doit être appliqué avec ce distinguo
   explicite (voir Livrable 2, Q3) — ce n'est plus un simple grep-and-apply sur 19 fichiers.
3. **`.claude/agent-memory/<agent>/*.md` est le contenu gitignoré le plus critique manquant à
   `.worktreeinclude`** — c'est la mémoire persistante inter-session de chaque agent
   (`memory: project`), pas un `.env`. Sans lui, un worker en worktree isolé perd tout son
   apprentissage accumulé à chaque dispatch (voir Livrable 2, Q2).

---

## Livrable 1 — Correction de la doctrine `team-kernel.md`

### Constat, re-vérifié sur pièce

`plugin/conductor/references/team-kernel.md:64-68` porte, **verbatim, à ce jour** :

```
**La conséquence doctrinale, en une ligne :** sur ce runtime, le parallélisme **intra-étape** (les
vagues de plans d'une même étape, côté moteur) est **perdu**, et le parallélisme **inter-nœuds**
porté par la frontière `ready` de `vf-dev-manager` est le **seul effectif**. Notre couche
d'orchestration ne duplique donc pas celle du moteur : **elle est la seule qui parallélise
réellement**.
```
`[VERIFIED: plugin/conductor/references/team-kernel.md:64-68]`

Cette même page (lignes 28-89) contient **déjà** la correction de prémisse la plus large : la
section « Marge de profondeur de dispatch » (l. 28-53) et « Étage de parallélisme réellement
effectif » (l. 55-89) — c'est cette dernière section qui porte le passage à corriger. Le reste de
la page (P12 « Cloisonnement par tools », « Écart déclaré ↔ runtime », etc.) n'a pas besoin d'édition
pour ce livrable.

### Tâche

Remplacer « perdu » par une formulation équivalente à « éteint par défaut, restaurable via
`claude_orchestration` (gate n°4, `nested && background`, jamais `backgroundDispatch`) » — reprendre
la formulation déjà validée par le cadrage (D-04) et par la spec de design §1.3-1.4. Ajouter un
renvoi vers la doctrine du livrable 3 si `dag.sh` gagne une nouvelle capacité de partition
(cohérence documentaire — voir Livrable 3).

### Fichiers touchés en écriture

- `plugin/conductor/references/team-kernel.md` (lignes 64-68 uniquement pour la correction stricte).

### Note de collision avec le Livrable 3

Si le planner choisit de documenter la nouvelle capacité de `dag.sh` (Livrable 3) **dans le même
fichier** `team-kernel.md` (la table `## Ce que le kernel fournit`, l. 14-27, est l'endroit naturel
pour documenter un nouveau comportement de `dag.sh`), **les Livrables 1 et 3 touchent alors le même
fichier en écriture** — pas une vraie collision de contenu (zones différentes : l. 64-68 vs table
l. 14-27), mais **pas une disjonction de fichiers non plus**. Deux options pour le planner : (a) un
seul plan porte les deux écritures sur `team-kernel.md` (Livrables 1 et 3 fusionnés côté doc), ou
(b) le Livrable 3 documente sa nouvelle capacité ailleurs (`mission-flow.md`, déjà le lieu de la
doctrine d'usage détaillée de `dag.sh`) et laisse `team-kernel.md` à la seule correction du
Livrable 1. **Recommandation : option (b)** — `mission-flow.md` est déjà le renvoi documenté pour
le détail d'usage (`team-kernel.md:140-143` : « doctrine détaillée côté dev … `mission-flow.md` »),
ce qui préserve la disjonction de fichiers entre plans.

---

## Livrable 2 — `isolation: worktree`

### Q3 — Liste exacte des agents recevant `isolation: worktree`

**Calcul mécanique exécuté cette session** — grep sur le frontmatter `tools:` de chaque agent
`plugin/*/agents/*.md`, recherche de `Write`, `Edit` ou `MultiEdit` :
`[VERIFIED: for f in plugin/*/agents/*.md; do grep -m1 "^tools:" "$f"; done — exécuté cette
session, sortie complète ci-dessous]`

**25 agents au total, 19 déclarent `Write`/`Edit`/`MultiEdit`, 0 déclare `isolation:` aujourd'hui**
(`grep -rl "^isolation:" plugin/*/agents/*.md` → vide, re-confirmé cette session).

Les 19 se répartissent en **deux catégories que le calcul mécanique seul ne distingue pas** :

**A — 13 workers non-managers (candidats directs, aucune raison identifiée de les exclure) :**

| Agent | Module | tools: (extrait) |
|---|---|---|
| `vf-coder` | dev-orchestrator | `Read, Write, Edit, Bash, ...` |
| `vf-crafter` | design-orchestrator | `Read, Write, Edit, Bash, ...` |
| `vf-business-commercial` | business-pilot-bundle | `Read, Write, Glob, Grep` |
| `vf-business-delivery` | business-pilot-bundle | `Read, Write, Glob, Grep` |
| `vf-business-finance` | business-pilot-bundle | `Read, Write, Glob, Grep` |
| `vf-content-repurposer` | content-bundle | `Read, Write, Glob, Grep` |
| `vf-content-strategist` | content-bundle | `Read, Write, Glob, Grep` |
| `vf-content-writer` | content-bundle | `Read, Write, Glob, Grep` |
| `campaign-analyst` | growth-bundle | `Read, Write, Glob, Grep` |
| `channel-strategist` | growth-bundle | `Read, Write, Glob, Grep` |
| `copywriter-sequences` | growth-bundle | `Read, Write, Glob, Grep` |
| `vf-app-fixer` | mobile-test-team | `Read, Edit, Write, Bash, ...` |
| `vf-test-runner` | mobile-test-team | `Read, Edit, Write, Bash, ...` |

**B — 6 managers/orchestrateurs, déclarant `Write` mais dont le rôle documenté est « ne produit
jamais » — cas à examiner, pas à appliquer mécaniquement :**

| Agent | Module | Écrit quoi, mesuré |
|---|---|---|
| `vf-business-manager` | business-pilot-bundle | mission/DAG (non audité ligne à ligne cette session) |
| `vf-content-manager` | content-bundle | idem |
| `vf-design-manager` | design-orchestrator | idem |
| `vf-dev-manager` | dev-orchestrator | **`.planning/STATE.md`** — seul agent du dépôt à écrire ce fichier `[VERIFIED: grep -rl "STATE\.md" plugin/dev-orchestrator/agents/vf-dev-manager.md → seul hit du dépôt sur les 19 candidats]` |
| `vf-growth-manager` | growth-bundle | mission/DAG |
| `vf-test-orchestrator` | mobile-test-team | mission/DAG (dispatche `vf-test-runner`, `vf-app-fixer` via `Agent(...)`) |

**Le cas nommément demandé par le cadrage existe, et c'est `vf-dev-manager`.** Il est le seul agent
sur les 19 à écrire `.planning/STATE.md` (constaté par grep, pas par lecture exhaustive de chaque
agent — la commande est reproductible). Deux faits convergent pour l'exclure du geste mécanique :

1. **Doctrine déjà écrite** : `team-kernel.md` « Règles d'instanciation » — « **Un manager ne
   produit jamais** (P3) : il lit, planifie (DAG), dispatche la frontière, synthétise. Toute
   production vit dans les workers. » `[VERIFIED: team-kernel.md:106-107]`. Son `Write` sert donc à
   des artefacts de pilotage (DAG.json sous `.planning/missions/`, `STATE.md` en fin de mission),
   pas à du code produit.
2. **Mécanisme d'isolation lui-même n'est documenté que pour un agent DISPATCHÉ** — la doc externe
   citée par la recherche source dit : « when Claude spawns a fork through the **Agent tool**, it
   can pass `isolation: "worktree"` » `[CITED: code.claude.com/docs/en/worktrees, via recherche
   source §A.1]`. Un manager qui est l'**incarnation d'entrée de la mission** (dispatché par
   `vibeflow-dev`/`/vf-auto`, pas nécessairement lui-même re-dispatché en sous-agent à chaque
   invocation) verrait potentiellement ce champ **inerte** dans son propre contexte d'exécution,
   tout en étant actif si un jour il est appelé comme sous-agent d'un autre orchestrateur. Ce point
   n'a **pas** été vérifié par exécution cette session (aucun harnais de test disponible pour
   observer le comportement de dispatch réel d'un manager) — **`[ASSUMED]`**, à traiter comme un
   point à trancher explicitement au plan, pas à supposer réglé par le grep seul.

**Recommandation au planner** : appliquer `isolation: worktree` mécaniquement aux 13 agents du
groupe A. Pour le groupe B (les 6 managers), écrire une tâche **distincte** qui statue
explicitement — soit (a) exclusion documentée avec renvoi à P3 + au risque de visibilité STATE.md,
soit (b) inclusion si le plan établit que la production réelle de `vf-dev-manager` reste bornée à
des artefacts qui tolèrent l'isolation (DAG.json committé avant lecture par un worker, `STATE.md`
écrit seulement en clôture après tout dispatch terminé). **Ne pas trancher ce point par défaut
silencieux** — c'est exactement le type de décision structurante que D-11 (simple avant complet)
voudrait voir explicite plutôt que déduite d'un grep.

### Q2 — Contenu exact du `.worktreeinclude`

**Énumération complète du gitignoré présent sur disque cette session** (`git status
--ignored=matching -s | grep '^!!'` — 6 entrées, exhaustif) `[VERIFIED: exécuté cette session]` :

| Chemin ignoré | Contenu | Nécessaire au runtime d'un worker ? |
|---|---|---|
| `.claude/` | `agent-memory/<agent>/*.md`, `memory/archive`, `logs/archive.log`, `.last-audit` | **OUI — critique**, voir ci-dessous |
| `docs/reference/` | doc générée (index GSD, non auditée en détail cette session) | non identifié comme lu par un worker au runtime — `[ASSUMED]`, à confirmer au plan |
| `plugin/conductor/scripts/dag.sh.bak` | résidu de backup | non |
| `plugin/design-orchestrator/agents/vf-design-manager.md.bak` | résidu de backup | non |
| `plugin/dev-orchestrator/agents/vf-dev-manager.md.bak` | résidu de backup | non |
| `plugin/dev-orchestrator/skills/vf-auto/SKILL.md.bak` | résidu de backup | non |

**Pas de `.env` de premier niveau** — confirmé (`find . -maxdepth 1 -iname ".env*"` → vide).

**La ligne critique est `.claude/agent-memory/`.** Chaque agent `Write` déclare `memory: project`
en frontmatter `[VERIFIED: grep -c "memory: project" plugin/*/agents/*.md — présent sur tous les
agents grepés, ex. plugin/dev-orchestrator/agents/vf-coder.md:7]` — c'est le mécanisme natif Claude
Code de mémoire persistante d'agent, matérialisé sous `.claude/agent-memory/<nom-agent>/*.md`
(observé cette session : `vf-coder/` contient 25 fichiers `project_*.md`/`feedback_*.md`
accumulés depuis juillet 2026). **Un worker dispatché dans un worktree fraîchement créé sans ce
dossier perdrait tout son apprentissage accumulé à chaque dispatch** — un régression fonctionnelle
directe, pas seulement cosmétique.

`docs/reference/` et les 4 fichiers `.bak` sont, sur les preuves disponibles cette session, des
candidats à **exclusion** du `.worktreeinclude` (pas de lecteur identifié au runtime pour les
`.bak` — ce sont des résidus d'édition ; `docs/reference/` mérite une vérification supplémentaire
au plan si un worker de doc s'avère le lire).

**Format attendu.** Aucune trace du format `.worktreeinclude` dans `gsd-core`
(`grep -rln worktreeinclude ~/.claude/gsd-core/` → aucun résultat) — **ce n'est pas un concept du
moteur GSD, c'est un mécanisme natif du harness Claude Code** `[CITED: recherche source §A.1, doc
code.claude.com/docs/en/worktrees : « les fichiers gitignorés (.env) ne sont pas copiés sans un
.worktreeinclude »]`. Le format précis (syntaxe de patterns, un chemin par ligne façon
`.gitignore` ?) n'est **documenté nulle part dans ce dépôt ni dans gsd-core** — recommandation :
traiter la syntaxe comme celle d'un `.gitignore` (patterns gitignore-style, un par ligne) par
analogie avec le nom du fichier et son rôle inverse (« inclure ce qui serait sinon exclu ») ; **à
vérifier empiriquement au premier plan qui pose le fichier**, avec un test discriminant (créer un
worktree, constater si `.claude/agent-memory/` y est présent). **`[ASSUMED]`** — pas de source
faisant autorité trouvée cette session sur la syntaxe exacte.

**Antécédent local à connaître : ADR-064 avait explicitement REFUSÉ de construire un
`.worktreeinclude`** (`.planning/quick/260801-17w-isolation-multi-session/PLAN.md:75-77` : « Pas de
`.worktreeinclude` ni de hooks `WorktreeCreate`/`WorktreeRemove` : ce sont des mécanismes du
harness Claude Code, pas du nôtre. **On prescrit l'usage de `isolation: worktree`, on ne
réimplémente pas ce que le harness fournit déjà.** »). **Ce n'est pas une contradiction avec le
Livrable 2 de cette phase** — la décision du 2026-08-01 refusait de **construire un mécanisme**
(hooks, tooling) autour du concept, pas de **poser le fichier de contenu** lui-même. La Phase 27 ne
fait que créer le fichier `.worktreeinclude` (une liste de chemins), ce que ce précédent
n'excluait pas. À noter au plan pour éviter toute relecture erronée comme un revirement.

### `.gitignore` racine — entrée manquante

`grep -n "worktree" .gitignore` → aucune ligne (re-confirmé). Ajouter une entrée
`.claude/worktrees/` — le nom exact du dossier que le harness matérialise pour les worktrees
d'agent n'est **pas confirmé sur pièce dans ce dépôt** (aucun worktree n'existe encore sur disque
puisque 0 agent ne déclare `isolation:` aujourd'hui) ; `.claude/worktrees/` est le chemin cité par
le ROADMAP (`:1907`) et la spec (`§4.1`) — **`[ASSUMED]` sur le nom exact**, à vérifier
empiriquement dès qu'un premier agent isolé tourne (le premier test du plan devrait constater le
chemin réel avant de figer l'entrée `.gitignore`, ou accepter de la corriger après coup si le
chemin observé diffère).

### `worktree.baseRef` — hors fichiers du dépôt

**Fait à noter pour l'analyse de disjonction (Requirement 4 du mandat)** : D-03 fixe
`worktree.baseRef: "head"`, mais c'est un **réglage global de `settings.json` de Claude Code**
(niveau machine, hors `.planning/config.json`, hors tout fichier versionné de ce dépôt) — la
recherche source le confirme (« c'est un réglage **global** de settings »). **Ce geste ne touche
aucun fichier du dépôt** : à documenter dans le plan comme une action de configuration machine
(recette humaine ou commande hors-git), pas comme une tâche avec un `files_modified` du dépôt.

### Fichiers touchés en écriture — Livrable 2

- `.gitignore` (racine) — une ligne ajoutée.
- `.worktreeinclude` (racine, nouveau fichier).
- 13 (ou 19, selon l'arbitrage du groupe B) fichiers `plugin/*/agents/*.md` — une ligne de
  frontmatter chacun, disjoints entre eux et disjoints des fichiers touchés par les Livrables 1/3/4/5.
- **Hors dépôt** : `worktree.baseRef` dans le `settings.json` machine de Samuel — pas un
  `files_modified` du plan.

---

## Livrable 3 — Fermeture du trou de `dag.sh`

### Q1 — Mécanisme exact de câblage

**Le trou, confirmé ligne à ligne cette session.** `dag.sh` déclare `scope[]` à la construction du
nœud (`plugin/conductor/scripts/dag.sh:124-126` : `scope = [s.strip() for s in scope_raw.split(",")
if s.strip()]` puis `node["scope"] = scope`), et l'expose en lecture seule dans `status`
(`dag.sh:196-200`, commentaire : « source unique et vivante de la table des fichiers gelés »). Mais
`ready` (`dag.sh:134-137`) ne fait **que** ceci :

```python
if action == "ready":
    frontier = [n["id"] for n in nodes if n["status"] == "ready"]
    emit({"ready": frontier, "count": len(frontier)})
    sys.exit(0)
```

`[VERIFIED: plugin/conductor/scripts/dag.sh:134-137, lu en entier cette session]` — **aucune
comparaison de `scope[]` entre nœuds n'a lieu.** `recompute()` (`dag.sh:80-86`) ne calcule que
`deps_done`, jamais une intersection de périmètres. Deux nœuds au statut `ready` déclarant le même
chemin dans `scope[]` sortent tous deux dans la frontière — exactement le constat de la recherche
source (§C.5), re-confirmé ici par lecture directe du code plutôt que par ré-exécution destructive
(hors périmètre de cette session de cadrage/recherche).

**Le câblage possible existe déjà en CLI amont, sans dépendre de l'activation de
`claude_orchestration`.** `~/.claude/gsd-core/bin/gsd-tools.cjs claude-orchestration` expose trois
sous-commandes `[VERIFIED: node ~/.claude/gsd-core/bin/gsd-tools.cjs claude-orchestration —
exécuté cette session, message d'usage complet]` :

```
gsd-tools claude-orchestration <detect-backend|emit-workflow|resolve-wave-dispatch> [...]
  detect-backend [--runtime <id>] [--agent-sdk-version <ver>] [--no-nested-dispatch]
  emit-workflow --waves <path> --run-id <id> [--phase-dir <dir>] [--budget <n>] [--executor-model <id>]
  resolve-wave-dispatch --waves <path> --run-id <id> [...]
```

**Fait décisif** : `cmdEmitWorkflow` (le gestionnaire de `emit-workflow`,
`claude-orchestration-command-router.cjs:222-247`) **appelle directement `emitWorkflowScript()` sans
jamais passer par `detectWorkflowBackend()`** `[VERIFIED: lu en entier — aucun appel à
detect-backend/gate ladder dans cmdEmitWorkflow]`. Autrement dit : **la partition en étages
disjoints (`summary.stagesByWave`, produite par `partitionStages()` en interne à
`emitWorkflowScript`, `claude-orchestration.cjs:477`) est disponible **que `claude_orchestration`
soit activé ou non**. Le Livrable 3 (fermer le trou de `dag.sh`) est donc **indépendant** du
Livrable 4 (activer `claude_orchestration`) — contrairement à ce que leur ordre dans le ROADMAP
pourrait suggérer, ils n'ont pas de dépendance dure entre eux côté machinerie (la dépendance
documentée dans le ROADMAP est une dépendance de **discipline** : livrer 1→2→3→4→5 dans cet ordre,
pas une dépendance technique de 3 sur 4).

**Mécanisme concret recommandé pour `dag.sh` :**

1. Construire, à partir de la frontière `ready` actuelle, un manifeste JSON temporaire au format
   attendu par `emit-workflow` — `{"waves": [{"id": "ready-frontier", "plans": [{"id": <node.id>,
   "brief": <node.step>, "files_modified": <node.scope>}, ...]}]}`. `dag.sh` a déjà les trois
   champs (`id`, `step`, `scope`) sur chaque nœud — aucune donnée nouvelle à collecter.
2. Invoquer `gsd-tools claude-orchestration emit-workflow --waves <tmp> --run-id dag-<id
   unique>` en sous-processus (le `python3` de `dag.sh` peut le faire via `subprocess.run`, ou un
   appel `node`/CLI direct depuis le bash englobant — les deux sont possibles, `dag.sh` est déjà un
   wrapper bash autour d'un heredoc `python3`).
3. Lire `summary.stagesByWave[0]` dans la réponse JSON — un tableau d'étages, chaque étage une
   liste d'`id` de nœuds garantis sans recouvrement de `scope[]`. **Ignorer le champ `script`**
   (le texte JS du Workflow n'a aucun usage pour `dag.sh` — c'est un sous-produit de la fonction
   partagée, pas une pollution à éviter activement, juste à ne pas consommer).
4. Émettre, en plus (ou à la place) de la frontière plate actuelle, une frontière **groupée par
   étage** — ex. `{"ready": [...], "count": N, "stages": [["a","b"], ["c"]]}` — pour que le manager
   sache combien de nœuds dispatcher **dans le même message**.

**Ce que cela coûte réellement, en dépendance.** Câbler ainsi introduit une dépendance **dure** de
`dag.sh` (socle `conductor`, lu par tous les managers du team-kernel) à la présence d'un binaire
`node` capable de résoudre `gsd-tools` sur le `PATH` ou via la cascade `$S` de résolution de
scripts. C'est une dépendance **nouvelle** — `dag.sh` aujourd'hui n'invoque que `python3`, jamais
`node`. Sur toute machine où le lab GSD est installé, `node`/`gsd-tools` sont déjà des prérequis
(le moteur GSD entier en dépend), donc le risque pratique est faible, mais **c'est la
« reversibility: costly si le câblage introduit une dépendance dure » que D-07 anticipait déjà** —
à écrire explicitement dans le plan, avec un repli si `gsd-tools` est introuvable (dégrader vers la
frontière plate actuelle, jamais un crash de `dag.sh ready`).

**Alternative plus légère, non retenue par cette recherche mais à mentionner au plan** : demander
en amont (`gsd-core`) l'exposition d'une commande dédiée `partition-scope` qui n'émettrait que
`summary` sans générer le script JS — réduirait le bruit de sortie mais **c'est une remontée
upstream**, hors périmètre d'exécution de cette phase (cf. §Deferred Ideas du cadrage : la
remontée amont est un geste externe, pas du code de ce dépôt).

### Contrat de sortie actuel de `dag.sh ready` — qui le consomme

`[VERIFIED: grep -rn "dag\.sh ready\|dag\.sh status" plugin/ — exécuté cette session, liste
exhaustive]` Consommateurs directs du contrat `{"ready": [...], "count": N}` :

| Fichier | Rôle |
|---|---|
| `plugin/dev-orchestrator/agents/vf-dev-manager.md:37,58,107` | manager dev — lit `ready`, dispatche « en un seul message » si ≥ 2 nœuds |
| `plugin/design-orchestrator/agents/vf-design-manager.md:57` | manager design — même patron |
| `plugin/content-bundle/agents/vf-content-manager.md:56` | manager content — même patron |
| `plugin/business-pilot-bundle/agents/vf-business-manager.md:77` | manager business — même patron |
| `plugin/growth-bundle/agents/vf-growth-manager.md:60` | manager growth — même patron |
| `plugin/dev-orchestrator/references/mission-flow.md:85,213,243` | doctrine de référence, exemple canonique |
| `plugin/conductor/scripts/check-mission-invariants.sh:130` | commentaire de gate — ne lit pas directement `ready`, mais documente que le périmètre gelé est dérivé de `dag.sh status` |

**Contrat actuel : `{"ready": [id, id, ...], "count": N}` — un tableau PLAT, aucune notion
d'étage.** Les 5 managers lisent ce tableau et **décident eux-mêmes**, en prose, si les périmètres
sont disjoints (« Périmètres douteux → séquentiel ou `isolation: worktree` », `team-kernel.md:109`)
— c'est précisément le jugement humain-simulé que le Livrable 3 doit remplacer par une garantie
machine.

**Rétro-compatibilité requise si le contrat change.** Si le planner choisit d'**ajouter** un champ
(`stages`) sans toucher `ready`/`count`, **les 5 managers actuels restent valides sans
modification** — c'est la voie la plus simple et la plus alignée avec D-11 (simple avant complet) :
aucun des 5 fichiers d'agents managers n'a besoin d'être touché par ce livrable, seul `dag.sh`
change. Si, à l'inverse, le planner choisit de **remplacer** `ready` par une structure groupée,
**les 5 managers + `mission-flow.md` doivent migrer dans le même plan** — sinon 4 des 5 métiers
(business, content, design, growth) perdent silencieusement le bénéfice du Livrable 3, puisqu'ils
liraient un champ qui n'existe plus sous son ancien nom. **Recommandation : additif, jamais
remplaçant** — champ `stages` nouveau, `ready`/`count` inchangés.

### Q1 — `workstream-policy.sh` : primitives déjà exposées

`[VERIFIED: plugin/planning-core/scripts/workstream-policy.sh, lu en entier cette session]` — ce
script expose :

- `vf_ws_name_valid <nom>` — validation du nom de workstream (alphabet, `..`, séparateurs).
- `vf_ws_trim <valeur>` — rognage des bords (parité `.trim()` amont).
- `vf_ws_resolve <planning_dir> [surcharge]` — résolution complète (surcharge > `VF_WORKSTREAM` >
  `GSD_WORKSTREAM` > pointeur partagé), positionne `VF_WS_NAME`/`VF_WS_SOURCE`/`VF_WS_REASON`.
- `vf_ws_path_nolink <chemin>` — test d'existence **sans suivre un lien symbolique**.
- `vf_ws_dir_resolve <planning_dir> <nom>` — résolution sûre du répertoire de compartiment.
- `vf_ws_file_in_ws <chemin>` — lecture sûre d'un fichier dans un compartiment (anti-symlink).

**Aucune de ces primitives ne concerne la disjonction de périmètres d'écriture** (elles portent
sur le NOM et le CHEMIN d'un workstream, pas sur des ensembles de fichiers modifiés par des plans).
**Le Livrable 3 n'a donc, sur les preuves de cette session, aucune primitive à réutiliser depuis ce
script** — D-12 (« toute primitive de chemin passe par `workstream-policy.sh` ») s'applique
seulement **si** le câblage du Livrable 3 en vient à construire des chemins sous
`.planning/workstreams/<nom>/...` (par exemple si la frontière `ready` doit un jour être calculée
par workstream) — ce qui n'est pas requis par le trou identifié ici (le trou porte sur des chemins
de fichiers de **code produit**, `scope[]`, pas sur des chemins de compartiment `.planning/`).
**À noter au plan comme non-applicable plutôt que silencieusement ignoré**, pour que la vérification
D-12 ne cherche pas un appel qui n'a pas lieu d'être.

### Q1 — Distinction avec `check-overlaps.sh` (D-08)

`[VERIFIED: plugin/conductor/scripts/check-overlaps.sh, en-tête lu cette session]` — confirmé :
« Inventaire des recouvrements de déclenchement avec les briques TIERCES (ADR-057) » — routage
entre briques VibeFlow/GSD et briques tierces (superpowers, feature-dev, natif Claude Code), pas
des périmètres d'écriture de fichiers. Codes de sortie : `0` advisory, `1` `--strict` sur
recouvrement non documenté, `3` indéterminé. **Aucun rapport avec le trou de `dag.sh`.**

**Nom recommandé pour la nouvelle brique** (si le planner opte pour un script séparé plutôt qu'une
extension de `dag.sh` lui-même) : quelque chose qui nomme explicitement « périmètre » et
« disjonction » — p.ex. `check-scope-disjunction.sh` ou `dag-partition.sh` — **jamais** un nom
contenant « overlap » seul (déjà pris par ADR-057) ni « scope » seul (déjà un champ existant de
`dag.sh`, source de confusion inverse). **Recommandation de cette recherche : ne pas créer de
script séparé** — étendre `dag.sh` lui-même avec un nouveau champ de sortie sur `ready` (voir
ci-dessus), ce qui évite le problème de nommage en évitant d'avoir à nommer une nouvelle brique.

### Fichiers touchés en écriture — Livrable 3

- `plugin/conductor/scripts/dag.sh` (nouvelle logique dans l'action `ready`, ou un nouveau champ).
- `plugin/conductor/scripts/tests/test-dag.sh` (extension — la suite existe déjà, 1 fichier).
- Optionnel, si le contrat devient remplaçant plutôt qu'additif : les 5 fichiers manager +
  `mission-flow.md` (à éviter, voir ci-dessus).
- **Collision documentaire potentielle avec le Livrable 1** sur `team-kernel.md` — voir note dans
  la section Livrable 1 ci-dessus (recommandation : documenter plutôt dans `mission-flow.md`).

---

## Livrable 4 — Instruire `claude_orchestration`

### L'échelle de gates complète, lue en entier cette session

`[VERIFIED: ~/.claude/gsd-core/bin/lib/claude-orchestration.cjs, fonction detectWorkflowBackend,
lue en entier]` — **7 gates, premier échec gagne, fail-closed à chaque étape** :

1. `claude_orchestration.enabled` doit être vrai (défaut : absent → faux).
2. `runtimeId === 'claude'` (seul runtime hébergeant l'outil Workflow).
3. `execution_backend !== 'inline'` (opt-out explicite court-circuite).
4. Le descripteur d'hôte doit porter `dispatch.nested === true && dispatch.background === true` —
   **jamais** `backgroundDispatch`. Le commentaire du code le dit explicitement (cité dans la
   recherche source, re-vérifié ici) : *« this is NOT the canonical `shouldFlattenDispatch` rule
   … the Workflow backend works precisely because a single tool-call orchestrates internally,
   sidestepping the `backgroundDispatch:false` limitation »*. **Ce gate n°4 est un proxy de
   présence de l'outil Workflow, pas une détection directe** — le code source le dit lui-même dans
   le commentaire de fonction (« a proxy for Workflow-tool presence »).
5. `agentSdkVersion` doit être un semver **valide** (sinon `agent_sdk_version_unknown`).
6. `agentSdkVersion >= floor` (défaut `0.3.149`, `WORKFLOW_TOOL_FLOOR_VERSION`).
7. `execution_backend` doit valoir `'auto'` ou `'workflow'` — les deux atteignent le backend
   `workflow` une fois tous les gates précédents passés.

**État réel de ce dépôt/poste, mesuré cette session** : gate 1 échoue déjà (`claude_orchestration`
absent de `.planning/config.json`, re-confirmé par lecture directe du fichier). Gate 5 échouerait
**aussi** en l'état — voir ci-dessous.

### Q4a — Établir honnêtement `GSD_AGENT_SDK_VERSION`

**Le mécanisme de résolution, lu en entier** (`claude-orchestration-command-router.cjs:150-158`) :
ordre `--agent-sdk-version` (flag explicite) > `process.env['GSD_AGENT_SDK_VERSION']` >
`resolveInstalledAgentSdkVersion(cwd)` (marche `node_modules` à la recherche de
`@anthropic-ai/claude-agent-sdk/package.json`, lecture directe du `version` du `package.json`
trouvé — jamais un `require()`).

**Fait central, établi cette session, qui rend le problème réel et non contournable par un
raccourci naïf** : `[VERIFIED: npm view @anthropic-ai/claude-code version → 2.1.222 (registre) ;
npm view @anthropic-ai/claude-agent-sdk version → 0.3.222 ; le binaire `claude` installé sur ce
poste rapporte 2.1.181 (`package.json` local) ]` — **les deux paquets ont des schémas de
versionnage totalement indépendants** (2.x pour le produit CLI, 0.3.x pour le SDK), et **aucune
correspondance numérique n'existe entre eux** — confirmé par recherche web
`[CITED: recherche web sur github.com/anthropics/claude-agent-sdk-typescript/releases + docs
Anthropic : « the SDK package version and the Claude Code CLI version are not directly tied to
each other — they are tracked independently »]`. **Il est donc structurellement impossible de
dériver `GSD_AGENT_SDK_VERSION` depuis `claude --version` par une formule** — quiconque le ferait
inventerait une valeur, exactement ce que D-09/hypothèse A2 du journal de recherche interdit.

**Chemin honnête recommandé pour le spike** : installer réellement `@anthropic-ai/claude-agent-sdk`
comme dépendance locale (`npm install --save-dev @anthropic-ai/claude-agent-sdk` à l'endroit d'où
`gsd-tools` sera invoqué, ou dans un répertoire que la marche `node_modules` de
`resolveInstalledAgentSdkVersion` traverse), pour que le mécanisme **natif déjà prévu par
l'amont** (lecture directe du `package.json` installé, sans variable d'environnement) s'applique
sans artifice. La version ainsi obtenue est **réelle** (un paquet réellement installé, une valeur
réellement lue) — pas inventée. **Ce qui reste non prouvé, et que seul le spike (pas la lecture de
code) peut établir** : que cette version installée **correspond fonctionnellement** au niveau de
l'outil Workflow réellement embarqué dans le binaire `claude` 2.1.181 de ce poste. Le gate 5/6 ne
vérifie qu'un plancher numérique arbitraire (`0.3.149`) — passer ce plancher avec une version
installée séparément (`0.3.222` au 2026-08-05, publiée hier) ne prouve PAS que le binaire répond ;
**c'est exactement pourquoi le gate 4 est qualifié de proxy et pourquoi le spike doit faire aboutir
un run réel**, pas seulement satisfaire la chaîne de gates. **`[ASSUMED — confiance BASSE]` : que
l'installation locale du paquet npm `@anthropic-ai/claude-agent-sdk` est le geste honnête attendu
par l'amont — c'est une inférence à partir du commentaire de code
(`resolveInstalledAgentSdkVersion` traite « the installed package's own package.json » comme
« authoritative »), pas une confirmation Anthropic. Alternative de repli si le spike juge cette
inférence insuffisante : documenter explicitement, dans la décision écrite du Livrable 4, que la
correspondance version-SDK ↔ binaire-CLI est **non garantie par Anthropic** et que le franchissement
du gate reste un **prérequis nécessaire mais non suffisant** — le run réel est la seule preuve qui
compte.**

### Q4b — Le plus petit run Workflow qui prouve le chemin

Limites dures de l'outil Workflow, déjà établies par la recherche source et non re-vérifiées cette
session (doc externe, MOYENNE confiance) : max 16 agents concurrents, 1000 agents/run, aucune
entrée utilisateur en cours de run, requiert Claude Code v2.1.154+ (ce poste : 2.1.181, au-dessus
du plancher — `[VERIFIED: npm view @anthropic-ai/claude-code local package.json]`).

**Design minimal recommandé pour le spike** — trois étapes séquentielles, chacune un critère
d'arrêt propre :

1. **Gate ladder seul** — poser `claude_orchestration.enabled: true`, `execution_backend: "auto"`,
   installer/pinner `GSD_AGENT_SDK_VERSION` (§Q4a), puis appeler
   `gsd-tools claude-orchestration detect-backend` (ou `resolve-wave-dispatch` sur un manifeste
   jouet à 2 plans sans recouvrement) et lire `backend`. **Ne rien exécuter encore.**
2. **Run réel trivial** — un manifeste à 2 plans, `files_modified` disjoints, chacun un `brief`
   ne demandant qu'une action anodine et vérifiable (ex. « crée un fichier `spike-a.txt` contenant
   la date »), avec `isolation: worktree` sur les deux (comportement par défaut de
   `emitWorkflowScript`, `use_worktree` non mis à `false`). Faire tourner le script émis via
   l'outil Workflow réel de la session (pas une simulation). **Critère** : les deux fichiers
   existent, chacun dans le commit produit par son propre worker, aucune collision, le run se
   termine sans intervention humaine.
3. **Sous-expérience Décision A** — un troisième manifeste, un seul plan, dont le `brief` demande
   explicitement à l'agent de poser une question à l'utilisateur (`AskUserQuestion`) avant de
   continuer. **Observer** : le run se termine-t-il en silence en ignorant la demande (fait déjà
   documenté ailleurs dans ce dépôt pour le dispatch sous-agent nu, `team-kernel.md:24`, « écart
   déclaré ↔ runtime ») ? bloque-t-il sans jamais rendre la main (mauvais signe — un run qui
   pendrait indéfiniment serait pire que l'inline actuel) ? ou l'outil documente-t-il une
   dégradation propre (« Only agent permission prompts can pause a run », doc externe déjà citée
   par la recherche source) ? **C'est la preuve empirique de la Décision A** — la doctrine « un
   étage = un workflow » n'est confirmée que si cette sous-expérience montre que l'absence
   d'entrée utilisateur en cours de run est **sans danger silencieux** (le besoin humain remonte
   dans le rapport typé de fin de run, jamais auto-répondu).

### Q4c — Critère de repli fail-closed

**Signal exact de repli déjà écrit dans le code amont, pas à inventer** : n'importe lequel des 7
gates échoue → `{available: false, backend: 'inline', reason: <raison nommée>}`. La liste fermée
des raisons observées : `capability_disabled`, `runtime_not_claude`, `backend_inline`,
`workflow_tool_unavailable`, `agent_sdk_version_unknown`, `agent_sdk_version_below_floor`. **Le
comportement inline actuel est le défaut avant toute intervention de cette phase** — donc le test
de non-régression du repli est trivial par construction : `claude_orchestration.enabled: false`
(ou absent) doit produire un comportement byte-identique à aujourd'hui, ce qui est déjà vrai
puisque c'est l'état actuel. Le spike doit néanmoins **re-tester ce repli après avoir manipulé la
config** (activer puis désactiver), pour s'assurer qu'aucun état résiduel ne subsiste — pas un
risque identifié sur preuve, mais une vérification bon marché à faire.

### Q4d — Critères de passage/échec écrits à l'avance

**PASS** — les trois conditions suivantes, toutes vérifiées :
1. Le gate ladder complet résout `backend: "workflow"` avec une valeur de SDK **installée
   réellement** (pas un flag inventé) sur ce poste.
2. Le run réel trivial (étape 2 ci-dessus) produit les mêmes artefacts que le chemin inline
   (commit, fichier, aucune erreur) — la parité avec l'inline path est ce que `emitWorkflowScript`
   promet dans ses commentaires (« composes the SAME gsd-executor agent … artifacts/commits »).
3. La sous-expérience Décision A confirme que l'absence d'entrée utilisateur en cours de run **ne
   produit pas de silence dangereux** — soit le run échoue explicitement, soit il remonte le
   besoin dans son rapport de fin de run, jamais un « faux terminé » qui aurait ignoré la demande.

**FAIL** — n'importe laquelle de ces conditions :
1. Le gate ladder ne résout jamais `workflow` même avec un SDK installé et la capability activée
   (blocage structurel du poste/runtime).
2. Le run réel diverge de l'inline path (artefacts différents, erreur non récupérée, worktree non
   nettoyé).
3. La sous-expérience Décision A révèle un silence dangereux (le run se termine `passed` alors que
   la question posée par l'agent n'a jamais été traitée nulle part, ni dans le rapport, ni ailleurs).

**Sur FAIL** : Livrable 4 se conclut par un **refus motivé et écrit** (patron des capacités
dormantes refusées en Phase 24 — GSDA-06, GSDA-08, GSDA-10), pas par un abandon silencieux. Sur
PASS partiel (gate ladder OK mais Décision A incertaine) : activer `execution_backend` reste
possible **seulement** si le plan documente le repli « un étage = un workflow » comme contrainte
opérationnelle du manager (jamais un workflow multi-étages sans point d'arbitrage humain entre
eux) — cohérent avec D-02.

### Fichiers touchés en écriture — Livrable 4

- `.planning/config.json` (`claude_orchestration.enabled`, `.execution_backend`).
- Un artefact de décision écrite (nouveau fichier, ex. `27-0X-DECISION-claude-orchestration.md`
  dans le dossier de phase, ou une entrée `docs/ADR.md` si le planner juge que ça mérite le
  registre — patron des ADR-066/067/068 pour les décisions d'activation de la Phase 24).
- Potentiellement `package.json`/`package-lock.json` racine si `@anthropic-ai/claude-agent-sdk` est
  installé en dépendance locale pour le spike (**à vérifier** : ce dépôt a-t-il déjà un
  `package.json` racine ? — non audité cette session, à faire au plan avant d'écrire cette tâche).

### Ordre de dépendance à respecter dans le plan

Le Livrable 5 (mesure) **doit établir sa baseline AVANT** que le Livrable 4 n'active
`claude_orchestration` — voir Livrable 5 ci-dessous pour la structuration en deux tâches
séquencées. **Ceci est une dépendance d'ORDRE D'EXÉCUTION, pas de fichiers** : les deux livrables
ne partagent quasiment aucun fichier en écriture (Livrable 5 écrit un document de méthode/mesure,
Livrable 4 écrit `.planning/config.json` et sa décision) — donc **compatibles avec un dispatch en
plans séparés**, à condition que le planencode explicitement l'ordre temporel (baseline avant
activation), pas seulement la disjonction de fichiers.

---

## Livrable 5 — Mesure du gain réel

### Q5 — Corpus et méthode recommandés

**Deux corpus possibles, avec justification pour trancher :**

| Corpus | Avantage | Inconvénient |
|---|---|---|
| **Reprise du corpus Phase 24** (12 plans déjà partitionnés, 4 étages, 0 collision — déjà mesuré en compression d'étages) | Aucune nouvelle exécution à orchestrer ; le partitionnement est déjà validé sans collision ; permet une mesure d'horloge **rétroactive** si les durées par plan ont été journalisées (`Per-Plan Metrics` existe dans `STATE.md`, mais incomplet — seulement 2 entrées Phase 19/20 dans le tableau lu cette session) | Les durées réelles par plan de la Phase 24 ne sont **pas** toutes mesurées dans `STATE.md` (table `Per-Plan Metrics` clairsemée) — la mesure rétroactive serait donc partielle, pas un vrai avant/après |
| **Exécution réelle en Phase 27** (les propres plans de cette phase, une fois écrits, dispatchés sous les deux modes) | Mesure fraîche, complète, sur le vrai comportement d'un manager en conditions réelles | Introduit une dépendance : il faut que la Phase 27 elle-même produise ≥ 2 plans à périmètres disjoints pour qu'il y ait quelque chose à paralléliser — sinon la mesure est vide de contenu |

**Recommandation de cette recherche : les deux, en séquence, pas l'un contre l'autre.**
1. **Baseline rétroactive qualitative** sur le corpus Phase 24 : documenter ce qui EST mesurable
   (le plafond 3,00× de compression d'étages, déjà acquis) et ce qui NE L'EST PAS (les durées
   d'horloge par plan, absentes de `STATE.md` pour la plupart des 12 plans) — **écrire cette
   limite explicitement**, ne pas la maquiller en mesure complète.
2. **Baseline d'horloge réelle et mesure après, sur les propres plans de la Phase 27** (≥ 2 plans à
   périmètres disjoints garantis par le Livrable 3) : chronométrer un dispatch en mode inline
   actuel (baseline), puis le même volume de travail sous `claude_orchestration` activé (mesure
   après), **au moins 2 répétitions** pour amortir la variance d'un run à l'autre (la recherche
   source ne donne aucune garantie de stabilité inter-run — sujet neuf, aucune donnée historique).

### Structuration en deux tâches séquencées sans ambiguïté

Le plan doit encoder l'ordre par une **dépendance de DAG explicite**, pas par une convention de
lecture. Deux tâches, l'une bloquant l'autre :

```
Tâche N   : "baseline horloge — dispatch inline actuel, ≥2 plans disjoints, chronométré"
Tâche N+1 : "mesure après — même volume sous claude_orchestration activé"  --deps=N
```

Si le plan utilise `dag.sh` lui-même pour modéliser ses propres tâches de Livrable 5 (cohérent avec
le patron déjà utilisé par toute la doctrine de mission de ce dépôt), la dépendance `--deps=` est
le mécanisme natif qui rend cet ordre non contournable — le nœud « mesure après » ne devient
`ready` qu'une fois « baseline » `done`. **C'est le patron le plus simple disponible (D-11)** :
aucun mécanisme neuf, juste l'usage normal de `dag.sh add --deps=`.

### Où écrire la méthode

**Recommandation : un fichier dédié dans le dossier de phase** (ex.
`27-0X-MESURE-GAIN.md`), pas une section noyée dans un `PLAN.md` — parce que (a) D-10 exige que la
méthode soit écrite et re-dérivable, ce qui mérite un artefact citable indépendamment du plan qui
l'a produit, (b) le patron déjà établi dans ce dépôt pour les mesures gravées est un document
séparé cité par ADR (cf. ADR-069 qui renvoie vers `24-COLLISIONS.md` pour sa méthode plutôt que de
la dupliquer inline).

### Fichiers touchés en écriture — Livrable 5

- Un nouveau fichier `27-0X-MESURE-GAIN.md` (ou équivalent) dans le dossier de phase.
- **Aucun fichier de code** — ce livrable ne modifie ni `dag.sh`, ni `.planning/config.json`
  au-delà de ce que le Livrable 4 y écrit déjà (Livrable 5 **lit** l'état activé par Livrable 4,
  ne le modifie pas une seconde fois).
- **Vraie disjonction avec le Livrable 4** confirmée : Livrable 4 écrit `.planning/config.json` +
  sa propre décision ; Livrable 5 écrit un document de méthode distinct. **Piège à signaler
  explicitement au planner (Requirement 4 du mandat)** : les deux livrables **mesurent/lisent le
  même objet** (l'état de `claude_orchestration`) sans écrire le même fichier — ce n'est **pas**
  une collision d'écriture, mais c'est une **dépendance d'ordre** qui doit être câblée en `--deps=`
  comme ci-dessus, jamais supposée tenue par la seule lecture du ROADMAP.

---

## Q6 — Cohabitation `isolation: worktree` × `GSD_WORKSTREAM`

**Question posée par le cadrage : un worktree créé par le runtime pour un agent `isolation:
worktree` hérite-t-il de `GSD_WORKSTREAM` du processus parent ?**

**Recherche effectuée cette session, résultat : question non tranchable par lecture de code —
`gsd-core` ne contient aucune logique de création de worktree** (c'est un mécanisme du binaire
`claude` fermé, pas du paquet npm `@opengsd/gsd-core`). `[VERIFIED: grep -rn "GSD_WORKSTREAM"
~/.claude/gsd-core/bin/lib/*.cjs → seules occurrences dans `active-workstream-store.cjs`, qui LIT
la variable pour résoudre un workstream, ne la CRÉE ni ne la PROPAGE à un sous-processus]`.

**Evidence indirecte trouvée, à degré de confiance MOYEN** `[CITED: recherche web —
github.com/anthropics/claude-code issue #36981, « Feature: Subagent environment variable isolation
for multi-identity workflows », lue via résumé de recherche cette session]` : cette issue
**demande** une fonctionnalité d'isolation des variables d'environnement par sous-agent, absente à
ce jour. **Le fait qu'une telle fonctionnalité soit demandée comme manquante implique, par
construction, que le comportement PAR DÉFAUT actuel est l'héritage** — sans quoi il n'y aurait rien
à isoler. Le texte de l'issue, tel que résumé, dit explicitement que les variables d'environnement
sont aujourd'hui héritées de la session parente et ne peuvent pas être scopées par agent.

**Conclusion de cette recherche, avec son degré de confiance explicite :** `GSD_WORKSTREAM`,
positionnée comme variable d'environnement du processus qui a lancé la session Claude Code (ou du
processus courant si positionnée en cours de session), est **vraisemblablement héritée** par tout
sous-agent dispatché — worktree isolé ou non, l'isolation `worktree` change le **répertoire de
travail** (`cwd`) des commandes `Bash` de l'agent, pas son **environnement**. Ces deux dimensions
sont orthogonales dans tout ce qui a été vérifié cette session (aucune source, amont ni externe, ne
documente que `isolation: worktree` filtre ou réinitialise l'environnement). **`[CITED — confiance
MOYENNE]`** : c'est une inférence à partir d'une issue GitHub tierce non officielle-doc, pas une
confirmation directe d'Anthropic ni un test exécuté sur ce poste (aucun agent ne déclare
`isolation:` aujourd'hui, donc aucun test empirique n'était possible cette session sans anticiper
le Livrable 2).

**Recommandation au planner** : traiter cette conclusion comme suffisamment fiable pour ÉCRIRE le
plan sans bloquer dessus (ADR-069 documente déjà `GSD_WORKSTREAM` comme « canal de premier rang »
qui « n'a jamais à toucher le fichier temporaire » si exporté — cohérent avec l'hypothèse
d'héritage), **mais ajouter un test empirique bon marché** dès que le premier agent avec
`isolation: worktree` tourne réellement (Livrable 2) : dispatcher ce premier agent avec
`GSD_WORKSTREAM` positionnée dans la session parente, lui faire imprimer `echo
"$GSD_WORKSTREAM"` depuis son worktree isolé, et confirmer sur pièce. **C'est un test à 1 ligne,
pas un chantier** — cohérent avec D-11.

---

## Package Legitimacy Audit

Cette phase n'introduit **aucune dépendance de production nouvelle** dans le code livré. Le seul
paquet potentiellement installé est **`@anthropic-ai/claude-agent-sdk`**, et seulement comme
artefact du **spike** du Livrable 4 (pour établir honnêtement `GSD_AGENT_SDK_VERSION`), pas comme
dépendance permanente du repo.

| Package | Registre | Âge / dernière publication | Downloads | Source repo | Verdict | Disposition |
|---|---|---|---|---|---|---|
| `@anthropic-ai/claude-agent-sdk` | npm | dernière version `0.3.222` publiée le 2026-08-04 (veille de cette recherche) `[VERIFIED: npm view … time]` | non mesuré cette session | `github.com/anthropics/claude-agent-sdk-typescript` (org officielle, même scope npm que `@anthropic-ai/claude-code` déjà installé et utilisé par tout ce dépôt) | OK — org officielle vérifiée, cadence de publication très active (quasi quotidienne sur juillet-août 2026), pas un paquet neuf/suspect | Approuvé, sous réserve du `checkpoint:human-verify` standard avant tout `npm install` en dépendance du repo (patron déjà en vigueur pour toute install de ce dépôt) |

**Packages retirés pour verdict [SLOP] :** aucun.
**Packages signalés suspects [SUS] :** aucun.

Le nom du paquet (`@anthropic-ai/claude-agent-sdk`) provient de la lecture directe du commentaire
de code amont (`claude-orchestration-command-router.cjs:20,105`) — **pas** d'une recherche web ni
de la mémoire d'entraînement — donc la provenance est `[VERIFIED: gsd-core, code source lu]` pour
le NOM, et `[VERIFIED: npm registry, interrogé cette session]` pour son existence/version réelle.
Les deux conditions de la règle de provenance de paquet sont réunies (source faisant autorité +
`npm view` exécuté cette session) — ce paquet peut porter le tag `[VERIFIED]` sans réserve, à la
différence de la plupart des autres paquets qu'une recherche découvrirait par websearch.

---

## Environment Availability

| Dépendance | Requise par | Disponible | Version | Fallback |
|---|---|---|---|---|
| `node` | `gsd-tools`, tout le moteur GSD, le câblage recommandé du Livrable 3 | ✓ | présent (utilisé toute cette session sans erreur) | — |
| `npm` | vérification de version des paquets, install éventuelle du SDK | ✓ | présent | — |
| `python3` | `dag.sh` (déjà une dépendance existante, non nouvelle) | ✓ | présent | — |
| `git` | worktrees (Livrable 2), tout le dépôt | ✓ | présent | — |
| `gh` (GitHub CLI) | mesures de l'écosystème (déjà utilisé par la recherche source, pas requis par cette phase) | ✓ | présent | — |
| `claude` (binaire CLI) | Livrable 4 (outil Workflow) | ✓ | 2.1.181 (local), au-dessus du plancher doc-cité v2.1.154+ | — |
| `@anthropic-ai/claude-agent-sdk` (paquet npm) | Livrable 4, établissement honnête de `GSD_AGENT_SDK_VERSION` | ✗ (non installé sur ce poste au moment de cette recherche) | — | à installer explicitement au spike — voir Q4a ; aucun fallback honnête autre que l'installation réelle |

**Manquants sans repli** : aucun — le seul manquant (`@anthropic-ai/claude-agent-sdk`) a une action
corrective directe (installation), pas une impasse.

---

## Runtime State Inventory

*(Section incluse par précaution — cette phase touche à de l'infrastructure d'exécution, mais ce
n'est pas une phase de rename/refactor/migration au sens strict du déclencheur. Les catégories sont
passées en revue pour être sûr qu'aucun état runtime caché n'est affecté.)*

| Catégorie | Constaté | Action requise |
|---|---|---|
| Données stockées | `.claude/agent-memory/<agent>/*.md` — mémoire persistante par agent, gitignorée, **non affectée en contenu** par cette phase (le Livrable 2 la rend seulement copiable en worktree via `.worktreeinclude`, il ne la modifie pas) | Aucune migration — geste de préservation, pas de transformation |
| Config de service en vol | `.planning/config.json` — modifié par Livrable 4 (`claude_orchestration.*`), déjà versionné, pas un service externe | Édition directe du fichier, pas de migration de données |
| État enregistré OS | Aucun mécanisme d'enregistrement OS identifié (pas de tâche planifiée, pas de service pm2/launchd/systemd trouvé dans ce dépôt lié à cette phase) | Aucune |
| Secrets/env vars | `worktree.baseRef` (Livrable 2, D-03) — un réglage `settings.json` **machine**, hors dépôt, pas un secret mais une config globale à modifier hors git ; `GSD_AGENT_SDK_VERSION` (Livrable 4) — variable d'environnement de session, pas un secret persistant | `worktree.baseRef` : édition manuelle du `settings.json` de Samuel, hors périmètre du plan de fichiers du dépôt ; `GSD_AGENT_SDK_VERSION` : positionnement au moment du spike, pas une valeur à committer |
| Artefacts de build/paquets installés | `@anthropic-ai/claude-agent-sdk`, si installé pour le spike — vérifier s'il doit être committé (`package.json`/lockfile) ou rester local/jetable au spike | À trancher au plan : si le paquet sert uniquement au spike (jetable), ne pas le committer ; s'il devient un prérequis permanent de `gsd-tools` côté ce dépôt, committer le lockfile |

---

## Validation Architecture

*(`nyquist_validation` est activé — `.planning/config.json` ne porte pas de clé qui le désactive,
donc cette section est incluse par défaut.)*

### Test Framework

| Propriété | Valeur |
|---|---|
| Framework | suites bash maison, patron `test-*.sh` (pas de framework tiers — jest/pytest absent de ce dépôt) |
| Config file | aucun fichier de config centralisé — chaque `test-*.sh` est autonome, exécuté directement |
| Quick run command | `bash plugin/conductor/scripts/tests/test-dag.sh` (Livrable 3) ; `bash plugin/conductor/scripts/tests/test-check-agents.sh` (Livrable 2) |
| Full suite command | non identifié de script de suite agrégée global cette session — patron observé ailleurs dans `STATE.md` : rejeu manuel de toutes les `test-*.sh` avant release |

### Phase Requirements → Test Map

| Livrable | Comportement | Type de test | Commande automatisée | Fichier existe ? |
|---|---|---|---|---|
| 1 | doctrine corrigée (texte) | non testable par machine — vérification par grep de non-régression du mot « perdu » | `grep -c "perdu" plugin/conductor/references/team-kernel.md` (doit décroître) | ✅ existant (fichier), test à écrire |
| 2 | `isolation: worktree` posé sur N agents, gate `check-agents.sh` valide | unitaire | `bash plugin/conductor/scripts/tests/test-check-agents.sh` | ✅ existant |
| 3 | `dag.sh` calcule la disjonction, frontière groupée par étages | unitaire | `bash plugin/conductor/scripts/tests/test-dag.sh` | ✅ existant — cas neufs à ajouter (nœuds à scope recouvrant) |
| 4 | gate ladder + run réel + décision A | unitaire (gate ladder) + manuel/spike (run réel) | `node ~/.claude/gsd-core/bin/gsd-tools.cjs claude-orchestration detect-backend` | ⚠️ pas de test dédié dans ce dépôt — à créer au Wave 0 |
| 5 | méthode de mesure écrite, baseline avant activation | manuel — le contenu est une mesure d'horloge, pas un test automatisable | — | ❌ Wave 0 : créer le document de méthode lui-même |

### Sampling Rate

- **Par commit de tâche** : rejeu de la suite bash directement concernée par le fichier touché
  (`test-dag.sh` pour Livrable 3, `test-check-agents.sh` pour Livrable 2).
- **Par fusion de vague** : rejeu de l'ensemble des suites `plugin/conductor/scripts/tests/*.sh`
  touchées par la phase.
- **Gate de phase** : suite complète verte avant `/gsd-verify-work`, plus la preuve d'exécution du
  spike (Livrable 4) documentée dans l'artefact de décision — pas seulement une lecture de code.

### Wave 0 Gaps

- [ ] Cas de test neufs dans `test-dag.sh` — deux nœuds `ready` avec `scope[]` recouvrant,
  vérifier qu'ils sortent dans des étages distincts après le câblage (Livrable 3).
- [ ] Un script/note de spike dédié pour le Livrable 4 (pas un test automatisé classique — un
  protocole reproductible avec ses 3 étapes, §Q4b).
- [ ] Le document de méthode de mesure lui-même (Livrable 5) — n'existe pas encore.

---

## Ce qui reste incertain / hypothèses

| # | Affirmation | Section | Confiance | Risque si faux |
|---|---|---|---|---|
| A1 | Le format exact (syntaxe) attendu par `.worktreeinclude` est celui d'un `.gitignore` (patterns, un par ligne) | Livrable 2, Q2 | BASSE — aucune source faisant autorité trouvée cette session | Le fichier posé ne produit pas l'effet attendu ; à vérifier empiriquement au premier plan qui le crée |
| A2 | Le nom exact du dossier matérialisé par le harness pour les worktrees d'agent est `.claude/worktrees/` | Livrable 2 | BASSE — cité par ROADMAP/spec, jamais observé sur disque dans ce dépôt (0 worktree existant) | L'entrée `.gitignore` ajoutée pourrait cibler le mauvais chemin ; premier test du plan doit confirmer |
| A3 | Installer `@anthropic-ai/claude-agent-sdk` en dépendance locale est le geste « honnête » attendu pour établir `GSD_AGENT_SDK_VERSION` | Livrable 4, Q4a | BASSE-MOYENNE — inférée du commentaire de code amont, pas confirmée par une doc Anthropic dédiée | Le gate 5/6 passerait sur une version qui ne reflète pas fidèlement le SDK embarqué dans le binaire `claude` — mais le run réel du spike (pas seulement le gate) reste la vraie preuve, donc le risque est borné |
| A4 | `GSD_WORKSTREAM` est hérité par un sous-agent en `isolation: worktree` (via héritage standard d'environnement de processus) | Q6 | MOYENNE — inférée d'une issue GitHub tierce, jamais testée sur ce poste (0 agent isolé aujourd'hui) | Un worker isolé ne résoudrait pas son workstream actif ; test empirique à 1 ligne recommandé dès le premier agent isolé |
| A5 | `docs/reference/` n'est lu par aucun worker au runtime, donc n'a pas besoin d'entrer dans `.worktreeinclude` | Livrable 2, Q2 | BASSE — absence de preuve positive (aucun grep de lecture trouvé), pas une preuve d'absence rigoureuse | Un worker de documentation pourrait le lire silencieusement en échouant en worktree isolé ; à vérifier au plan |
| A6 | Les 5 (ou 6, selon vf-test-orchestrator) managers qui déclarent `Write` sont candidats à l'EXCLUSION de `isolation: worktree` | Livrable 2, Q3 | MOYENNE — appuyée par la doctrine écrite (P3) et un fait mesuré (vf-dev-manager seul à écrire STATE.md), mais le comportement runtime du champ `isolation:` sur un agent incarné en entrée de mission (vs dispatché) n'a pas été testé cette session | Si l'exclusion est fausse, ces 5-6 agents restent exposés au risque de collision que le Livrable 2 devait fermer ; si l'inclusion est fausse, la visibilité inter-agents sur STATE.md/DAG.json pourrait casser silencieusement |

**Aucune de ces hypothèses ne porte sur une décision de vision** (toutes les décisions de vision
sont déjà tranchées, D-01 à D-13) — elles portent sur des **détails d'implémentation techniques**
que le plan doit soit vérifier empiriquement au premier plan concerné, soit encoder comme
vérification explicite plutôt que comme fait acquis.

---

## Sources

### Primaires (HAUTE — vérifiées sur pièce cette session)

- `plugin/conductor/scripts/dag.sh` — lu en entier, contrat `ready`/`status`/`add` confirmé.
- `plugin/conductor/references/team-kernel.md` — lu en entier, doctrine et table des briques.
- `plugin/planning-core/scripts/workstream-policy.sh` — lu en entier, primitives exposées.
- `plugin/conductor/scripts/check-overlaps.sh` — en-tête lu, objet confirmé distinct.
- `plugin/conductor/scripts/check-agents.sh` — grep ciblé sur `isolation` (lignes 39, 160, 528-530).
- `.gitignore` racine — lu en entier.
- `.planning/config.json` — lu en entier.
- `git status --ignored=matching -s` — exécuté cette session, 6 entrées exhaustives.
- `~/.claude/gsd-core/bin/lib/claude-orchestration.cjs` — lu en entier (echelle de gates,
  `partitionStages`, `emitWorkflowScript`).
- `~/.claude/gsd-core/bin/lib/claude-orchestration-command-router.cjs` — lu en entier (résolution
  SDK, sous-commandes CLI).
- `node ~/.claude/gsd-core/bin/gsd-tools.cjs claude-orchestration` — exécuté cette session, usage
  confirmé.
- `npm view @anthropic-ai/claude-code version` / `@anthropic-ai/claude-agent-sdk version` /
  `versions --json` / `time` — exécutés cette session.
- `plugin/*/agents/*.md` (25 fichiers) — frontmatter `tools:` grepé exhaustivement cette session.
- `.planning/quick/260801-17w-isolation-multi-session/PLAN.md` — lu en entier (antécédent ADR-064).
- `docs/ADR.md:1921-2100` (ADR-069) — lu en entier (workstreams, `GSD_WORKSTREAM`, risques mesurés).
- `.planning/STATE.md` (lignes 1-60, 750-568) — lu, item Phase 19 confirmé (`:768-772`).

### Secondaires (MOYENNE — citées, doc officielle ou recherche croisée)

- code.claude.com/docs/en/worktrees — via la recherche source (§A.1), non re-fetché cette session.
- GitHub issue anthropics/claude-code#36981 — lue via résumé de recherche web cette session
  (inférence sur l'héritage d'environnement par défaut).
- github.com/anthropics/claude-agent-sdk-typescript/releases — via résumé de recherche web
  (indépendance des schémas de version SDK/CLI).

### Tertiaires (BASSE — non recoupées, signalées comme telles dans le texte)

- Format exact du fichier `.worktreeinclude` — aucune source faisant autorité trouvée.
- Correspondance fonctionnelle entre version npm du SDK et outil Workflow embarqué dans le binaire
  `claude` — non documentée par Anthropic à la connaissance de cette recherche.

---

## Métadonnées

**Confiance globale :**
- Livrables 1, 2 (hors .worktreeinclude), 3 : HAUTE — tout vérifié sur pièce, mécanismes déjà
  écrits en amont, aucune zone grise résiduelle de vision.
- Livrable 4 : MOYENNE sur le mécanisme (gates lus en entier, CLI exécutée), BASSE sur
  l'établissement honnête de `GSD_AGENT_SDK_VERSION` (signalé explicitement, pas maquillé).
- Livrable 5 : HAUTE sur la méthode et la structuration (patron déjà établi dans ce dépôt), MOYENNE
  sur le choix de corpus (les deux options ont des limites documentées).
- Q6 : MOYENNE — inférence solide mais non testée empiriquement sur ce poste.

**Date de recherche :** 2026-08-05
**Valide jusqu'au :** ~2026-09-05, ou au prochain bump de `gsd-core`/Claude Code — les gates de
`claude_orchestration` (BETA, `#1143`) sont susceptibles d'évoluer vite ; `@anthropic-ai/claude-agent-sdk`
publie quasi quotidiennement (0.3.204 → 0.3.222 entre le 2026-07-08 et le 2026-08-04).
