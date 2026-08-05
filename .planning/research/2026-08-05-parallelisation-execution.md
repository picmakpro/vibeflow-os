# Phase 27 — Parallélisation d'exécution : granulaire, simple, sans collision — Recherche

> **Numéro de phase** — `ROADMAP.md:60` porte, non commitée au moment où j'écris,
> `- [ ] Phase 27: Parallélisation d'exécution — granulaire, simple, sans collision d'écriture`,
> posée par une session concurrente qui a aussi clos la Phase 24 (PR #34, mergée pendant cette
> recherche). **La phase cadrée ici est donc la 27, pas la 25** — la 25 est « Budget d'instructions
> et étage d'alignement court », un sujet distinct. `[VERIFIED: git diff .planning/ROADMAP.md, mesuré]`

**Recherché :** 2026-08-05
**Domaine :** orchestration multi-agents, isolation d'écriture, partitionnement de périmètre
**Confiance globale :** HAUTE sur les mécanismes locaux (tout re-mesuré cette session) · MOYENNE sur les estimations de gain (méthode explicitée à chaque chiffre)

---

## Résumé exécutif

**Le verrou n'est pas là où la Phase 24 l'a laissé.** La Phase 24 a correctement établi que
`shouldFlattenDispatch()` aplatit le dispatch sous Claude Code parce que `backgroundDispatch: false`.
Cette lecture reste vraie — je l'ai re-vérifiée sur pièce. Mais elle a conclu, à tort, que le
parallélisme intra-étape était **perdu**. Il ne l'est pas : il est **désactivé par un drapeau
default-off**, et le chemin qui le restaure **ne passe pas par `shouldFlattenDispatch()` du tout**.

La capability `claude_orchestration` adopte l'outil **Workflow** de Claude Code (le moteur derrière
`/effort ultracode`). Son échelle de gates ne lit **jamais** `backgroundDispatch` — elle lit
`nested && background`, tous deux `true` sur ce poste. Le commentaire du code amont le dit
explicitement : *« the Workflow backend works precisely because a single tool-call orchestrates
internally, sidestepping the backgroundDispatch:false limitation »*
`[VERIFIED: ~/.claude/gsd-core/bin/lib/claude-orchestration.cjs:186-192]`.

**Sur les données réelles de la Phase 24**, j'ai fait tourner le partitionneur de l'amont sur les 12
plans réellement livrés : il compresse **12 exécutions sérielles en 4 étages parallèles**, soit un
facteur **3,00×**, avec **zéro collision de fichier** — le planificateur produit déjà des vagues
parfaitement disjointes. Le parallélisme est donc à la fois **sûr et gratuit** : rien ne le bloque
qu'une décision de configuration.

**Un seul gate bloque réellement ce poste**, et ce n'est pas une limite de capacité : c'est un
artefact de détection de version (`agent_sdk_version_unknown`), contournable par une variable
d'environnement.

**Recommandation principale :** poser `isolation: worktree` sur les workers (Option 1, une ligne par
agent, la machinerie l'accepte déjà) puis activer `claude_orchestration` avec le contournement de
version (Option 2). Ne pas construire d'orchestrateur maison — trois existent déjà en amont et
l'un d'eux est dans le binaire installé.

---

## A. État de l'art externe

### A.1 — Ce que Claude Code fournit nativement (le plus transposable, et de loin)

La doc officielle range **quatre** surfaces de parallélisme, plus deux outils de support
`[CITED: code.claude.com/docs/en/agents]` :

| Surface | Qui tient le plan | Échelle documentée | Isolation fichiers |
|---|---|---|---|
| **Subagents** | Claude, tour par tour | « a few delegated tasks per turn » | `isolation: worktree` en frontmatter |
| **Agent view** (`claude agents`) | l'humain | plusieurs sessions de fond | worktree **automatique** par session |
| **Agent teams** | un lead agent | « a handful of long-running peers » | **aucune** — « partition the work » |
| **Dynamic workflows** | **un script** | « dozens to hundreds of agents per run » | `isolation: "worktree"` par `agent()` |

**Limites dures de l'outil Workflow**, citées telles quelles
`[CITED: code.claude.com/docs/en/workflows §Behavior and limits]` :

- **16 agents concurrents maximum**, moins sur machine à peu de cœurs
- **1 000 agents au total par run**
- **aucune entrée utilisateur en cours de run** — « Only agent permission prompts can pause a run »
- aucun accès direct au shell ou au disque **depuis le script** — seuls les agents agissent
- requiert Claude Code **v2.1.154+** — ce poste est en **2.1.181** `[VERIFIED: npm ls -g, mesuré]`

**Primitives du script** `[CITED: code.claude.com/docs/en/workflows]` : `agent()`, `parallel()`,
`pipeline()`, `phase()`, un bloc `meta` littéral, `args` en global, et `resumeFromRunId`.

**Deux points de la doc directement pertinents au mot « granulaire » de Samuel :**

1. Sur la reprise : *« A workflow that fans work out across many small agents therefore preserves
   more progress than one long agent »* `[CITED: code.claude.com/docs/en/workflows §Resume after a
   pause]`. La granularité n'est pas un luxe — c'est ce qui rend une reprise peu coûteuse. La règle
   exacte est brutale : au redémarrage, le cache s'arrête au **premier agent non terminé**, et
   **tout agent démarré après lui rejoue**, même s'il avait fini.
2. `/batch` est une **skill livrée d'origine** qui découpe un gros changement en **5 à 30 subagents
   isolés en worktree, chacun ouvrant une PR** `[CITED: code.claude.com/docs/en/agents]`. C'est
   littéralement le patron demandé, déjà empaqueté. Présent dans le binaire installé
   `[VERIFIED: grep sdk-tools.d.ts, mesuré]`.

**Isolation worktree — les faits qui comptent** `[CITED: code.claude.com/docs/en/worktrees]` :

- `isolation: worktree` est un **champ de frontmatter de subagent**, pas une API à câbler
- pendant qu'un agent tourne, Claude pose un `git worktree lock` — le nettoyage concurrent ne peut
  pas le supprimer
- un worktree **partage le `.git`** du dépôt principal : `git commit` depuis un worktree fonctionne,
  y compris sous sandbox
- les worktrees de subagent branchent depuis la **branche par défaut** sauf si `worktree.baseRef`
  vaut `"head"` — **piège majeur ici** : un worker qui doit travailler sur le travail en cours a
  besoin de `baseRef: "head"`, sinon il part de `main` et perd le contexte de la mission
- les fichiers gitignorés (`.env`) ne sont **pas** copiés sans un `.worktreeinclude`

### A.2 — L'écosystème tiers (chiffres relevés à l'API GitHub le 2026-08-05)

`[VERIFIED: gh api, mesuré cette session]` — étoiles et dernier push réels, pas de mémoire :

| Dépôt | Étoiles | Dernier push | Archivé | Ce que c'est |
|---|---|---|---|---|
| `smtg-ai/claude-squad` | **8 237** | 2026-07-30 | non | TUI Go, un worktree isolé par agent, multi-CLI |
| `sipyourdrink-ltd/bernstein` | **786** | 2026-08-05 | non | orchestrateur Python, worktrees + vérif tests/lint |
| `cristicretu/diri` | 196 | 2026-08-05 | non | orchestration d'agents |
| `iishyfishyy/operator-oss` | 189 | 2026-08-01 | non | idem |
| `usemozzie/mozzie` | 48 | 2026-03-12 | **oui** | abandonné — ne pas s'en inspirer |

**Le patron convergent de tous ces projets est le même, et il est simple** : un worktree git par
agent, une branche par worktree, une vérification (tests/lint) avant merge. Aucun n'invente de
mécanisme de verrouillage fin — tous **partitionnent par répertoire de travail**.

### A.3 — Données de coût/bénéfice publiées

Le système de recherche multi-agents d'Anthropic (patron orchestrateur-worker, fan-out) rapporte
**+90,2 % de performance** sur des évals internes contre un système mono-agent, pour environ
**15× les tokens** d'une interaction de chat `[CITED: anthropic.com/engineering/multi-agent-research-system,
via recherche web]`. Un mode d'échec documenté et directement transposable : des agents qui
**spawnaient 50 subagents pour des requêtes triviales**. La proportionnalité n'est pas cosmétique.

### A.4 — Ce qui n'est PAS transposable ici

- **Agent teams** : expérimental, désactivé par défaut, et **n'isole pas** les coéquipiers en
  worktree — la doc dit explicitement de partitionner à la main. Régression par rapport à ADR-064.
- **Agent view / `claude agents`** : research preview, et pilotée par **l'humain**, pas par un
  manager agentique. Ne s'insère pas dans le team-kernel.
- **claude-squad / bernstein** : ce sont des **TUI externes** qui lancent des CLI. VibeFlow est un
  **plugin qui vit dans la session**. Les adopter voudrait dire sortir de Claude Code — contraire à
  la doctrine du lab. On en reprend le **patron** (un écrivain = un worktree, déjà ADR-064), pas le
  code.
- **Routines / cron** : exécution planifiée dans le cloud, pas du parallélisme local.

---

## B. GSD-workstream : est-ce le bon outil ? — **Non. Ta lecture est juste.**

**Verdict : la lecture de l'orchestrateur est confirmée, et de façon plus nette encore
qu'énoncée.** Les workstreams compartimentent le **planning**. Ils n'ont strictement **aucun**
point de contact avec l'exécution.

### B.1 — La preuve décisive

```
grep -c "workstream" ~/.claude/gsd-core/workflows/execute-phase.md  →  0
```

`[VERIFIED: mesuré cette session, gsd-core 1.9.1]`. **Zéro occurrence.** Le workflow qui dispatche
les agents d'exécution ne connaît pas le concept. Un workstream ne peut donc, par construction,
changer ni le nombre d'agents dispatchés, ni leur périmètre, ni leur isolation.

Ce que les workstreams font réellement : `resolveActiveWorkstream` tranche entre `--ws`,
`GSD_WORKSTREAM` et un pointeur de session, pour désigner **quel compartiment `.planning` est
actif** `[VERIFIED: plugin/dev-orchestrator/references/workstreams.md §2, relu cette session]`.
C'est un sélecteur de **feuille de route**, pas un ordonnanceur.

### B.2 — Re-dérivation des chiffres de couverture (ils ne tombent pas juste)

La consigne demandait de re-dériver plutôt que de recopier. **Les chiffres bougent selon
l'ensemble compté** — exactement le piège signalé.

Ma méthode, explicite : `find ~/.claude/gsd-core/workflows -name '*.md'` pour le dénominateur,
`grep -rl "workstream\|GSD_WORKSTREAM\|--ws "` pour le numérateur, gsd-core **1.9.1**, le
2026-08-05.

| Grandeur | Ma mesure | Ce que disait la Phase 24 |
|---|---|---|
| Workflows racine (`-maxdepth 1`) | **91** | 91 ✓ concordant |
| Workflows totaux (récursif) | **115** | non énoncé |
| Fichiers mentionnant workstream | **6** (5 racine + 1 imbriqué) | « 7/91 » |
| Workflows codant `.planning/` en dur | **73** (dont 70 racine) | « 45 » |

Les 6 : `new-milestone.md`, `settings.md`, `settings-advanced.md`, `settings-integrations.md`,
`transition.md`, `help/modes/full.md`. **Aucun n'est un workflow d'exécution** — ce sont des
workflows de réglage et de transition de jalon. Cela confirme B.1 par un second chemin.

L'écart sur « 45 » vs mes 73 est trop large pour être du bruit : les deux comptes portent sur des
ensembles différents (motif de grep, ou périmètre racine/récursif). **Je ne tranche pas lequel a
raison** — je signale que le chiffre « 45 » ne doit pas être recopié en Phase 27 sans être
re-dérivé avec sa méthode.

### B.3 — Alors quel est le bon mécanisme ?

Les workstreams restent utiles pour **ce pour quoi ils sont faits** : cloisonner deux feuilles de
route concurrentes. Ils sont même **complémentaires** de la parallélisation d'exécution — un
worktree qui exporte `GSD_WORKSTREAM` sait sur quelle feuille de route il travaille.

Mais le mécanisme de parallélisation d'exécution, c'est, dans l'ordre de simplicité :
**(1) `isolation: worktree` en frontmatter d'agent**, **(2) la capability `claude_orchestration`**,
**(3) le partitionnement mécanique par `files_modified`**. Section D.

> **À dire à Samuel sans détour :** « inspire-toi de GSD-workstream » est une bonne intuition qui
> pointe vers le mauvais objet. Ce qu'il a vu dans les workstreams — *cloisonner pour ne pas se
> marcher dessus* — est le bon principe. Mais l'objet qui l'applique à l'exécution s'appelle
> `isolation: worktree`, pas `workstream`.

---

## C. Les mécanismes disponibles ici, mesurés

### C.1 — L'échelle de gates de `claude_orchestration`, exécutée pour de vrai

J'ai appelé la fonction pure de l'amont directement, sans toucher au dépôt
`[VERIFIED: node -e sur claude-orchestration.cjs, mesuré cette session]` :

| Configuration | Backend | Raison |
|---|---|---|
| OFF — **état réel du dépôt** | `inline` | `capability_disabled` |
| ON, SDK inconnu — **état réel du poste** | `inline` | **`agent_sdk_version_unknown`** |
| ON, SDK 0.3.148 | `inline` | `agent_sdk_version_below_floor` |
| ON, SDK **0.3.149** (plancher pile) | **`workflow`** | `workflow_backend_active` |
| ON, SDK 0.4.0 | **`workflow`** | `workflow_backend_active` |
| ON, `execution_backend: inline` | `inline` | `backend_inline` |

Et via la vraie commande CLI, dans le dépôt :
`gsd-tools claude-orchestration resolve-wave-dispatch …` → `{"backend":"inline","reason":"capability_disabled"}`
`[VERIFIED: mesuré cette session]`.

**Il y a donc exactement deux verrous, et aucun n'est une limite de capacité :**

1. `claude_orchestration.enabled` absent de `.planning/config.json` — **un booléen à poser**
   `[VERIFIED: .planning/config.json relu cette session, la clé n'y est pas]`
2. Le SDK Agent n'est pas résolvable sur disque. J'ai reproduit la marche `node_modules` du routeur
   depuis le dépôt **et** depuis `~/.claude/gsd-core/bin/lib` : **`null` des deux côtés**
   `[VERIFIED: mesuré]`. Le SDK n'existe que dans des caches `npx` (`~/.npm/_npx/…`), que la marche
   ne visite pas. Claude Code 2.1.181 **embarque** son SDK dans un binaire (`claude`, 205 Mo) au
   lieu de l'exposer en paquet.

**Le contournement existe et est propre** : le routeur lit `GSD_AGENT_SDK_VERSION` **avant** de
tenter la résolution disque `[VERIFIED: claude-orchestration-command-router.cjs:157]`. Une variable
d'environnement suffit. `--agent-sdk-version` en drapeau explicite marche aussi.

> ⚠️ **Point d'honnêteté** : le gate 4 est un **proxy**, pas une détection. Le code le dit :
> `nested && background` est *« a proxy for Workflow-tool presence »*. Passer les gates prouve que
> l'amont **acceptera** d'émettre le script — **pas** que l'outil Workflow répondra. J'ai vérifié
> indépendamment que l'outil existe : `WorkflowInput` / `WorkflowOutput` sont déclarés dans
> `sdk-tools.d.ts` du binaire installé, avec `script`, `scriptPath`, `args`, `resumeFromRunId`
> `[VERIFIED: /opt/homebrew/lib/node_modules/@anthropic-ai/claude-code/sdk-tools.d.ts:2398-2428]`.
> **Reste à prouver en Phase 27 :** qu'un run réel aboutisse. C'est un spike, pas une hypothèse à
> écrire dans un plan.

### C.2 — Le script réellement émis

`emitWorkflowScript` fonctionne, testé sur un cas jouet à 3 plans dont 2 partagent un fichier
`[VERIFIED: mesuré]` :

```javascript
export const meta = { name: "gsd-execute-…", description: "GSD wave dispatch for …", phases: [...] }
phase("Wave wave-1")
// Stage 0
await parallel([
  () => agent("A", { agentType: "gsd-executor", isolation: "worktree" }),
  () => agent("B", { agentType: "gsd-executor", isolation: "worktree" }),
])
// Stage 1 (sequential — files_modified overlap)
await parallel([
  () => agent("C", { agentType: "gsd-executor", isolation: "worktree" }),
])
```

Le plan `C`, qui partage `a.md` avec `A`, a été **automatiquement relégué** à un étage séquentiel.
C'est le partitionnement granulaire demandé, **déjà écrit et fonctionnel en amont**.

### C.3 — LE gain, mesuré sur les données réelles de la Phase 24

**Méthode, à re-dériver au moment de la planification :** j'ai extrait le frontmatter des 12
`*PLAN.md` réels de `VFDO-24-*` (champs `wave` et `files_modified`), construit le manifeste de
vagues, puis appelé `emitWorkflowScript` de gsd-core 1.9.1 et lu `summary.stagesByWave`
`[VERIFIED: mesuré cette session sur .planning/phases/VFDO-24-*/*PLAN.md]`.

| Vague | Plans | Fichiers déclarés | Étages après partition | Paires en collision |
|---|---|---|---|---|
| 1 | 5 | 42 | **1** | **0** |
| 2 | 4 | 10 | **1** | **0** |
| 3 | 2 | 6 | **1** | **0** |
| 4 | 1 | 29 | 1 | 0 |
| **Total** | **12** | 87 | **4** | **0** |

**12 exécutions sérielles → 4 étages parallèles = facteur 3,00× de compression d'étages.**

Et le résultat le plus important : **zéro collision de fichier, sur les quatre vagues.** J'ai
vérifié l'intersection de tous les couples de plans intra-vague — toutes vides. **Le
planificateur produit déjà des vagues parfaitement disjointes.** Le parallélisme est sûr *dès
aujourd'hui* ; seule la décision de sérialisation du moteur l'empêche.

> **Ce que ce 3,00× est, et ce qu'il n'est pas.** C'est une compression du **nombre d'étages de
> dispatch**, mesurée. Ce **n'est pas** un gain d'horloge de 3× : le temps d'un étage parallèle est
> celui de son plan le plus long, pas la moyenne. Le gain d'horloge réel sera **inférieur à 3×**,
> d'autant plus que les plans d'une vague sont de durées inégales. Traiter 3,00× comme un
> **plafond mesuré**, pas comme une prévision.

### C.4 — Où sont les vraies collisions dans ce lab

| Ressource | Collision possible ? | Ce qui protège | État mesuré |
|---|---|---|---|
| **Fichiers source** | oui | worktree par écrivain (ADR-064) | ✅ mécanisme dispo, **0 agent ne le déclare** |
| **Index git** | non, en worktree | chaque worktree a son propre index ; le `.git` est partagé mais les commits sérialisent au niveau objet | ✅ sûr `[CITED: docs worktrees]` |
| **Verrou de driver** | par conception | `driver-lock.sh`, TTL **1800 s** | ⚠️ sérialise les **managers**, pas les workers — n'entrave pas ce chantier |
| **Frontière `ready` du DAG** | **oui** | rien | ❌ **voir C.5** |
| **`.planning/STATE.md`** (66,6 Ko) | oui | rien de mesuré | ⚠️ écrivain unique de fait ; à confirmer en Phase 27 |
| **`.claude/worktrees/`** | pollution du dépôt | `.gitignore` | ❌ **non couvert** — mesuré, à ajouter |
| **`.env` / fichiers ignorés** | absents en worktree | `.worktreeinclude` | ❌ **absent** — mesuré |

### C.5 — La plus petite unité parallélisable, et ce qui l'empêche

**Réponse courte : le plan (`*-PLAN.md`), et ce qui l'empêche est que rien ne calcule la
disjonction des périmètres.**

`dag.sh` **déclare** un `scope[]` par nœud (chemins/globs, D-13) et `dag.sh status` expose les
périmètres gelés. Mais il **ne calcule jamais** l'intersection. Test empirique — trois nœuds, `a` et
`b` déclarant le **même** `src/x.md` `[VERIFIED: mesuré cette session sur dag.sh]` :

```
dag.sh ready  →  {"ready": ["a", "b", "c"], "count": 3}
```

**`a` et `b` sortent tous deux `ready` alors qu'ils écrivent le même fichier.** La frontière `ready`
est une frontière de **dépendances**, pas de **périmètres**. La disjonction repose entièrement sur
le jugement du manager, porté par de la prose : *« ≥ 2 nœuds ready à périmètres disjoints → un seul
message »* `[VERIFIED: team-kernel.md §Règles d'instanciation, relu]`.

⚠️ **Piège de nommage à ne pas répéter** : `check-overlaps.sh` **ne fait pas** ce travail. Malgré
son nom, il inventorie les recouvrements de **routage entre briques tierces** (superpowers,
feature-dev), au titre d'ADR-057 `[VERIFIED: en-tête du script, relu]`. Aucun script du lab ne
calcule la disjonction de périmètres.

**C'est exactement la fonction que l'amont a déjà écrite** : `partitionStages()` fait ce calcul en
first-fit glouton sur `files_modified`, garantissant que deux plans partageant un fichier ne
cohabitent jamais dans un étage `[VERIFIED: claude-orchestration.cjs:216-250]`.

**Descendre plus bas que le plan (au niveau tâche) est déconseillé** : `parallelization.task_level`
est déjà `false` dans la config `[VERIFIED: .planning/config.json]`, et les tâches d'un même plan
partagent presque toujours des fichiers. Le plan est le bon grain.

---

## D. Trois options chiffrées

Toutes les estimations d'horloge sont **estimées et dites comme telles**. Seul le 3,00× de C.3 est
mesuré, et c'est un plafond d'étages, pas d'horloge.

### Option 1 — `isolation: worktree` sur les workers *(la plus simple ; recommandée en premier)*

**Le geste :** ajouter une ligne `isolation: worktree` au frontmatter des agents écrivains
(`vf-coder`, `vf-crafter`, éventuellement `gsd-executor`). Plus `.gitignore` et `.worktreeinclude`.

**Coût :** très faible. La machinerie **accepte déjà le champ** :
`check-agents.sh` liste `isolation` dans ses `KNOWN` et valide que *« seul worktree est admis »*
`[VERIFIED: check-agents.sh:158-160 et :530]`. **Aucun agent ne le déclare aujourd'hui** — 0 sur 25
`[VERIFIED: grep sur plugin/*/agents/*.md, mesuré]`. Le gate ne changera pas de comportement.

À faire en plus, mesuré manquant : ajouter `.claude/worktrees/` au `.gitignore` (**non couvert**),
créer un `.worktreeinclude` (**absent**), et arbitrer `worktree.baseRef` — le défaut `"fresh"`
branche depuis `main` et **ferait perdre le travail en cours d'une mission** ; il faut
vraisemblablement `"head"`.

**Gain :** ⚠️ **aucun gain de parallélisme en soi.** C'est une couche de **sécurité**, pas de
vitesse : elle rend sûr le fan-out inter-nœuds déjà pratiqué par `vf-dev-manager`, et supprime la
dépendance au jugement du manager sur la disjonction. *C'est le prérequis des options 2 et 3.*

**Ce que ça rend impossible :** deux workers ne peuvent plus se voir mutuellement en cours de
route ; un worker ne peut plus lire un fichier qu'un autre vient d'écrire sans passer par un merge.
Toute mission qui suppose un état partagé en cours de vague casse.

---

### Option 2 — Activer `claude_orchestration` *(le meilleur rapport gain/effort)*

**Le geste :** trois choses, dans cet ordre.

1. Un **spike** prouvant qu'un run Workflow réel aboutit (C.1 : les gates sont un proxy).
2. `GSD_AGENT_SDK_VERSION` posée à la version réelle du SDK embarqué — à **établir honnêtement**,
   pas à inventer. Sinon `--agent-sdk-version` en drapeau explicite.
3. `claude_orchestration.enabled: true` + `execution_backend: "auto"` dans `.planning/config.json`.

**Coût :** faible en code — **zéro ligne** de logique de parallélisation à écrire, tout existe en
amont. Le coût réel est de **vérification** : c'est une capability **BETA, default-off**, et le
repli est *fail-closed* (tout échec retombe sur `inline`, byte-identique à aujourd'hui). Le risque
d'adoption est donc structurellement borné.

**Gain estimé :** compression d'étages **mesurée à 3,00×** sur la Phase 24 (C.3). Gain d'horloge
**estimé entre 1,8× et 2,5×** — méthode de l'estimation : le plafond mesuré est 3,00×, dégradé par
l'inégalité des durées de plans au sein d'une vague (le plus long fixe l'étage) et par le surcoût
de création/merge des worktrees. **À re-mesurer sur la première phase réelle, pas à recopier.**

**Ce que ça rend impossible — et c'est le point dur :**

> **Aucune entrée utilisateur en cours de run.** La doc est catégorique : *« No mid-run user input
> — for sign-off between stages, run each stage as its own workflow »*
> `[CITED: code.claude.com/docs/en/workflows]`. **De plus, les subagents d'un workflow tournent
> toujours en `acceptEdits` : les éditions de fichier sont auto-approuvées**, quel que soit le mode
> de permission de la session.

C'est en **tension directe avec ADR-031 (« jamais de fix sans validation humaine »)** et avec la
halt-condition « escalade humaine impérative sur `ask-user` » du team-kernel. Le team-kernel a
déjà rencontré ce mur : un agent déclarant `AskUserQuestion` ne le recevait pas en dispatch
sous-agent, ce qui **a gelé une mission** `[VERIFIED: team-kernel.md §Écart déclaré ↔ runtime]`.
Le repli documenté — remonter le besoin humain dans le rapport typé — reste valable, mais **il doit
être re-prouvé sous Workflow**. C'est le vrai sujet de cadrage de la Phase 27, plus que la
technique.

Note de proportionnalité : la doc signale un avertissement « Large workflow » au-delà de 25 agents,
et un `workflowSizeGuideline` (small <5 / medium <15 / large <50) — **mais il requiert v2.1.219+**,
or ce poste est en **2.1.181**, donc défaut `unrestricted` `[VERIFIED: version mesurée ; seuils CITED]`.
Le garde-fou à 16 concurrents / 1 000 total, lui, s'applique.

---

### Option 3 — Un partitionneur de périmètres dans `dag.sh` *(la plus ambitieuse)*

**Le geste :** porter la logique de `partitionStages()` dans `dag.sh`, pour que `dag.sh ready`
retourne des **étages disjoints** au lieu d'une liste plate. Le manager reçoit alors un plan de
dispatch mécaniquement sûr, sans jugement.

**Coût :** moyen à élevé. C'est du code neuf dans un script du socle `conductor`, avec sa suite de
tests, sa doctrine, et une migration de tous les managers qui lisent `ready`. C'est aussi la seule
option qui **duplique** une logique existant en amont — précisément ce que la doctrine du lab
reproche (« notre couche ne duplique pas celle du moteur »).

**Gain :** ferme le trou mesuré en C.5 pour **tous les métiers** (dev, design, contenu, growth), pas
seulement le dev — l'option 2 ne couvre que le chemin `gsd-execute-phase`. Gain d'horloge **estimé
similaire à l'option 2** là où elles se recouvrent ; la valeur propre est la **correction**, pas la
vitesse.

**Ce que ça rend impossible :** un manager ne peut plus dispatcher deux nœuds à périmètres
recouvrants même quand il *sait* que c'est sûr (deux sections disjointes d'un même gros fichier).
Le partitionnement au fichier est plus grossier que le jugement humain.

**Recommandation :** **ne pas la faire en Phase 27.** La retenir comme option de repli si le spike
de l'option 2 échoue, ou comme extension une fois l'option 2 éprouvée. Samuel a demandé
**simple** — celle-ci ne l'est pas, et elle duplique de l'amont.

---

### Tableau de décision

| | Option 1 | Option 2 | Option 3 |
|---|---|---|---|
| Code neuf | ~0 (frontmatter + gitignore) | 0 (config) | script + tests + doctrine |
| Prérequis | — | Option 1 | Option 1 |
| Gain d'horloge | aucun (sécurité) | **est. 1,8–2,5×** | est. idem, plus large |
| Plafond mesuré | — | **3,00× d'étages** | 3,00× d'étages |
| Risque | faible | **BETA + mur ADR-031** | dette de duplication |
| Réversible | oui (retirer la ligne) | oui (fail-closed) | non (script du socle) |

**Chemin recommandé : 1 → spike de 2 → 2.** L'option 3 reste en réserve.

---

## Journal des hypothèses

| # | Affirmation | Section | Risque si faux |
|---|---|---|---|
| A1 | L'outil Workflow répond réellement sur ce poste | C.1 | Option 2 morte ; repli fail-closed sur inline, sans casse |
| A2 | La version du SDK embarqué peut être établie honnêtement | D/Opt.2 | il faut épingler une version arbitraire — malhonnête, à refuser |
| A3 | Gain d'horloge 1,8–2,5× | D/Opt.2 | le gain réel peut être bien plus faible si les plans d'une vague sont très inégaux |
| A4 | `STATE.md` a un écrivain unique de fait | C.4 | corruption d'état en écriture concurrente — **à mesurer en Phase 27** |
| A5 | Le repli « besoin humain dans le rapport typé » survit sous Workflow | D/Opt.2 | ADR-031 violé en silence — **c'est le risque n°1 de ce chantier** |

## Questions ouvertes

1. **Le mur ADR-031.** Un workflow ne peut pas demander l'avis de l'humain en cours de run et
   auto-approuve les éditions. Le contrat « un étage = un workflow, validation entre les étages »
   est le repli documenté par Anthropic — **est-il acceptable pour ce lab ?** C'est une question
   de doctrine, à trancher par Samuel, pas par la technique.
2. **`worktree.baseRef`.** `"fresh"` (défaut) branche depuis `main` et perdrait le travail en cours
   d'une mission. `"head"` semble requis — mais c'est un réglage **global** de settings, pas par
   agent. Interaction avec le verrou de driver à vérifier.
3. **Écart de comptage workstreams** (B.2) : « 45 » vs mes 73. Ne pas recopier l'un ou l'autre sans
   re-dériver avec sa méthode.
4. **Cohabitation worktrees × workstreams.** ADR-069 dit d'exporter `GSD_WORKSTREAM` par worktree.
   Un worktree créé **par le runtime** (isolation d'agent) hérite-t-il de cette variable ? Non
   mesuré cette session.

## Sources

**Primaires (HAUTE — mesurées sur pièce cette session)**
- `~/.claude/gsd-core/bin/lib/claude-orchestration.cjs` — échelle de gates, `partitionStages`, émetteur
- `~/.claude/gsd-core/bin/lib/claude-orchestration-command-router.cjs:105-160` — résolution de version SDK
- `~/.claude/gsd-core/bin/lib/host-integration.cjs:464-469` — `shouldFlattenDispatch`
- `~/.claude/gsd-core/workflows/` — 91 racine / 115 total, 0 mention workstream dans `execute-phase.md`
- `/opt/homebrew/lib/node_modules/@anthropic-ai/claude-code/sdk-tools.d.ts:443-445, 2398-2428` — `isolation`, `WorkflowInput`
- `plugin/conductor/scripts/{dag.sh,check-agents.sh,check-overlaps.sh,driver-lock.sh}` — testés en direct
- `.planning/phases/VFDO-24-*/*PLAN.md` — 12 plans, partition réelle
- `gh api` — étoiles/push réels au 2026-08-05

**Secondaires (MOYENNE — doc officielle)**
- code.claude.com/docs/en/{workflows,agents,worktrees}

**Tertiaires (BASSE — recherche web non recoupée)**
- anthropic.com/engineering/multi-agent-research-system (chiffres +90,2 % / 15× lus via résumé de recherche, **non vérifiés sur la source**)

## Métadonnées

**Confiance :** mécanismes locaux HAUTE (tout re-mesuré) · limites de l'outil Workflow MOYENNE
(doc officielle, non éprouvée sur ce poste) · estimations d'horloge BASSE (dites comme estimées)
**Date :** 2026-08-05 · **Valide jusqu'au :** ~2026-09-05, ou au prochain bump de gsd-core /
Claude Code — les deux bougent vite (gsd-core 1.9.1 publiée le 2026-07-31).
