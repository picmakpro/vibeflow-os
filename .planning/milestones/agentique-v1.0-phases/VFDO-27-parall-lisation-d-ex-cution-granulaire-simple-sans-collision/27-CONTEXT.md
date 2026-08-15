# Phase 27: Parallélisation d'exécution — granulaire, simple, sans collision d'écriture - Context

**Gathered:** 2026-08-05
**Status:** Ready for planning

> **Cadrage produit par un worker interne (`vf-coder`) sans outil de question.** Contrairement à la
> Phase 24, cette phase arrive avec un **pré-cadrage déjà très détaillé** (ROADMAP §Phase 27, la spec
> de design 225 lignes, la recherche 497 lignes) et **deux décisions déjà tranchées par Samuel** (A et
> B ci-dessous), injectées par le digest de mission. Chaque décision de ce fichier porte sa source
> (fichier + ligne). **Aucune zone grise restante n'a nécessité d'arbitrage humain** — voir
> `<escalations>` en fin de fichier pour la vérification explicite de ce constat, question par
> question.

<domain>
## Phase Boundary

Cette phase prend un **gain de vitesse déjà disponible et non pris** (le partitionneur amont produit
déjà des vagues d'exécution parfaitement disjointes sur le corpus réel de la Phase 24) et le rend
**sûr par construction**, tout en corrigeant une doctrine livrée qui affirme à tort ce gain « perdu ».
Elle ferme dans les deux sens l'écart entre ce qui dort (le dispatch parallèle réel, la capability
`claude_orchestration`) et ce qui n'est tenu que par le jugement humain (la disjonction de périmètres
entre nœuds de DAG). [ROADMAP.md:1843-1848]

**Cinq livrables, dans cet ordre de dépendance** [spec §6, ROADMAP.md:1926-1939] :
1. Corriger la doctrine fausse de `team-kernel.md:64-65` (« perdu » → « éteint par défaut »).
2. Poser `isolation: worktree` là où c'est juste, avec les deux manques matériels comblés.
3. Fermer le trou de `dag.sh` — en câblant la disjonction amont (`partitionStages`), jamais en la
   réimplémentant.
4. Instruire `claude_orchestration` : spike, puis décision écrite (activation ou refus motivé).
5. Mesurer le gain réel : baseline d'horloge avant, mesure après, méthode écrite.

**Hors périmètre, explicitement** :
- Option 3 (porter le partitionneur dans `dag.sh`) — proscrite maintenant par l'Iron Law 2 révisée
  (ADR-069) : dupliquerait l'amont. Reste en réserve si le spike de l'option 2 échoue.
  [ROADMAP.md:1909, spec §4.3/§D]
- La divergence de comptage `workstream` (6 vs 7/91) et `.planning/` en dur (45 vs 73) — en cours de
  re-dérivation par un nœud parallèle de cette même mission. **ADR-069 fait foi jusque-là ; ce cadrage
  ne cite aucun des deux nombres.** [digest de mission ; ROADMAP.md:1898-1901 ; spec §7]
- Toute nouvelle capacité au-delà des cinq livrables (scope creep) — appartiendrait à une phase
  distincte.

</domain>

<decisions>
## Implementation Decisions

### Décisions déjà tranchées par Samuel — injectées par le digest, ne se rediscutent pas

- **D-01 — Chemin retenu : 1 → spike de 2 → 2.** L'option 1 (`isolation: worktree`) d'abord parce
  qu'elle ne fait rien gagner mais rend le reste sûr (prérequis de sécurité) ; le spike parce que
  l'option 2 (`claude_orchestration`) change le mode de dispatch de toute exécution — pas un réglage
  qu'on bascule sans l'avoir vu tourner. — **Reversibility:** reversible — frontmatter et clé de
  config, retirables sans migration. [ROADMAP.md:1903-1912 ; spec §4.3, §D « Tableau de décision »]

- **D-02 — Décision A (mur ADR-031) : repli « un étage = un workflow ».** Un workflow n'accepte
  aucune entrée utilisateur en cours de run et ses sous-agents tournent toujours en `acceptEdits`. Le
  manager reste hors workflow ; la main humaine est gardée aux jointures entre étages. **Ce repli doit
  être re-prouvé sous Workflow pendant le spike du livrable 4, pas supposé.** — **Reversibility:**
  costly — si le spike invalide le repli, il faut retrouver un autre point d'arbitrage humain en cours
  d'exécution, potentiellement architectural. [digest de mission — décision A ; ROADMAP.md:1914-1920 ;
  spec §5.1]

- **D-03 — Décision B (`worktree.baseRef`) : passer à `"head"`.** Le défaut `"fresh"` branche depuis
  `main` et ferait perdre le travail en cours d'une mission — inacceptable. C'est un réglage
  **global** de settings, assumé comme tel. — **Reversibility:** reversible — un flip de clé revient
  au défaut sans migration, mais l'effet est global (toutes missions), pas scopé à cette phase.
  [digest de mission — décision B ; ROADMAP.md:1922-1924 ; spec §5.2, §4.1]

### Livrable 1 — Correction de la doctrine `team-kernel.md`

- **D-04 :** Remplacer, à `plugin/conductor/references/team-kernel.md:64-65`, l'affirmation « le
  parallélisme intra-étape … est **perdu** » par la formulation exacte « **éteint par défaut** » (ou
  équivalent conservant le sens : désactivé par un drapeau default-off, restaurable). Le chemin réel
  qui restaure ce parallélisme ne passe pas par `shouldFlattenDispatch()` mais par le gate n°4 de
  `claude_orchestration` (`nested && background`, jamais `backgroundDispatch`). — **Reversibility:**
  reversible. **Re-vérifié sur disque le 2026-08-05, ce jour** : les lignes 64-68 de
  `team-kernel.md` portent toujours exactement le texte cité par le ROADMAP et la spec ; rien n'a
  bougé depuis leur rédaction. [ROADMAP.md:1850-1863 ; spec §1 ; team-kernel.md:64-68, lu directement]

### Livrable 2 — `isolation: worktree`

- **D-05 — Portée : tous les modules portant des agents, pas seulement `dev-orchestrator`.** La spec
  le dit explicitement en en-tête (« Modules visés … tous les modules portant des agents (frontmatter
  `isolation:`) »). L'identification précise des agents **écrivains** (candidats à `isolation:
  worktree`) se fait par un critère mécanique — grep sur le champ `tools:` du frontmatter pour
  `Write`/`Edit`/`MultiEdit` — **à la planification, pas ici** : c'est un calcul, pas une préférence.
  **Re-vérifié ce jour** : `check-agents.sh` valide déjà `isolation` dans ses clés `KNOWN` et n'admet
  que `worktree` (`plugin/conductor/scripts/check-agents.sh:160,528-530`) ; **0 agent sur 25** le
  déclare (`grep -rl "^isolation:" plugin/*/agents/*.md` → vide). — **Reversibility:** reversible —
  retirer une ligne de frontmatter par agent. [spec §0 point 4, §4.1 ; ROADMAP.md:1907 ; vérifié sur
  disque ce jour : `check-agents.sh:39,160,528-530`]

- **D-06 — Deux manques matériels à combler, mesurés ce jour sur ce dépôt :** `.claude/worktrees/`
  **absent** du `.gitignore` racine (`grep -n "worktree" .gitignore` → aucune ligne) et aucun
  `.worktreeinclude` **présent** à la racine. Le contenu exact du `.worktreeinclude` (quels fichiers
  gitignorés doivent malgré tout être copiés dans un worktree d'agent) est à établir en recherche —
  ce dépôt n'a pas de `.env` de premier niveau détecté à ce cadrage, mais la liste complète des
  fichiers gitignorés pertinents (secrets, config locale) reste à énumérer au plan. —
  **Reversibility:** reversible. [ROADMAP.md:1907 ; spec §4.1 ; vérifié sur disque ce jour]

### Livrable 3 — Fermeture du trou de `dag.sh`

- **D-07 :** `dag.sh` déclare un `scope[]` par nœud mais ne calcule jamais la disjonction —
  `dag.sh ready` rend `ready` pour deux nœuds qui déclarent le même fichier (testé et confirmé par la
  recherche, non re-testé destructivement ce jour car hors périmètre de cadrage). La fermeture doit
  **câbler** la fonction déjà écrite en amont (`partitionStages()` / `emitWorkflowScript`,
  `~/.claude/gsd-core/bin/lib/claude-orchestration.cjs`), **jamais la réimplémenter localement** —
  c'est exactement ce que l'Iron Law 2 révisée (ADR-069) proscrit : « une capacité amont partiellement
  couverte se câble en écrivant ses limites, elle ne se réimplémente pas ». Le mécanisme précis de
  câblage (appel du binaire `gsd-tools`/le module amont en sous-processus depuis `dag.sh`, format
  d'échange) est une décision de recherche/plan, pas de cadrage. — **Reversibility:** costly si le
  câblage introduit une dépendance dure de `dag.sh` (socle `conductor`, lu par tous les managers) à un
  binaire externe — à documenter au plan si c'est le cas. [ROADMAP.md:1881-1889, 1909 ; spec §3, §3.3,
  §6.3 ; team-kernel-adjacent : ADR-069]

- **D-08 — Piège de nommage à ne pas répéter :** `check-overlaps.sh` ne fait pas ce travail — il
  traite du routage entre briques tierces (ADR-057), pas des périmètres d'écriture. Toute brique
  produite par cette phase pour la disjonction de périmètres doit porter un nom qui dit son objet, pas
  un nom qui prête à confusion avec `check-overlaps.sh`. — **Reversibility:** reversible (choix de
  nommage). [ROADMAP.md:1888-1889 ; spec §3.2]

### Livrable 4 — Instruire `claude_orchestration`

- **D-09 :** **Re-vérifié sur disque ce jour** : `claude_orchestration` est totalement **absent** de
  `.planning/config.json` — ni la clé `enabled`, ni `execution_backend` n'y figurent (`cat
  .planning/config.json` relu en entier ce jour ; les blocs présents sont `mode`, `granularity`,
  `workflow`, `planning`, `parallelization` (`enabled: true, plan_level: true, task_level: false,
  max_concurrent_agents: 3`), `hooks`, `intel`, `agent_skills`). Le geste du spike est donc : poser
  `claude_orchestration.enabled: true` + `execution_backend: "auto"`, établir honnêtement
  `GSD_AGENT_SDK_VERSION` (ou `--agent-sdk-version`) — **jamais une valeur inventée**, c'est un risque
  nommé par la recherche (hypothèse A2 du journal) — et faire aboutir un run Workflow réel. Le gate
  n°4 n'est qu'un **proxy** de présence de l'outil Workflow, pas une preuve qu'il répond — la preuve
  est le spike lui-même. — **Reversibility:** reversible — capability BETA, repli fail-closed intégral
  vers `inline` sur tout échec, byte-identique au comportement actuel. [ROADMAP.md:1908 ; spec §4.2,
  §C.1 ; recherche §C.1, §D/Opt.2, journal des hypothèses A1/A2 ; `.planning/config.json` relu ce jour]

### Livrable 5 — Mesure du gain

- **D-10 :** La mesure du gain est un **livrable**, pas une promesse : baseline d'horloge **avant**
  activation, mesure **après**, méthode écrite dans l'artefact produit. Le plafond de 3,00×
  (compression d'étages sur les 12 plans réels de la Phase 24) **n'est pas** un gain d'horloge — la
  distinction doit être tenue dans tout artefact produit par cette phase, jamais recopiée comme un
  gain mesuré. Le corpus exact de la mesure (une exécution réelle en Phase 27, ou reprise du corpus
  Phase 24) est une décision de recherche/plan. — **Reversibility:** reversible. [ROADMAP.md:1876-1879,
  1938-1939 ; spec §2, §6.5]

### Contraintes non négociables — portent sur les cinq livrables, ne se rediscutent pas

- **D-11 — Simple avant complet.** Une solution qui demande de penser à trois choses avant chaque
  dispatch ne sera pas tenue, donc ne comptera pas. [ROADMAP.md:1928-1929 ; digest de mission]
- **D-12 — Zéro régression de sécurité de la Phase 24.** Toute primitive de chemin passe par les
  primitives partagées de `plugin/planning-core/scripts/workstream-policy.sh` (localisé et confirmé ce
  jour), jamais par une réimplémentation locale — le motif d'échappement par lien symbolique en était
  à son 4ᵉ passage. [ROADMAP.md:1932-1934 ; digest de mission]
- **D-13 — Tout chiffre gravé porte sa méthode et se re-dérive au moment de l'écriture.**
  [ROADMAP.md:1935-1937]

### Claude's Discretion

- Le mécanisme exact de câblage `dag.sh` ↔ `partitionStages()` (sous-processus, format d'échange) —
  D-07.
- Le contenu exact du `.worktreeinclude` (liste des fichiers gitignorés à préserver) — D-06.
- La liste exacte des agents recevant `isolation: worktree` (grep mécanique sur `tools:`) — D-05.
- Le design précis du spike (livrable 4) et ses critères de passage/échec.
- Le corpus et la méthode exacts de mesure du gain (livrable 5).
- Découpage en plans, numérotation, nommage des fichiers et scripts produits.
- Cohabitation `isolation: worktree` × `GSD_WORKSTREAM` (un worktree créé par le runtime hérite-t-il
  de la variable ?) — question technique non mesurée par la recherche (« non mesuré cette session »,
  recherche §Questions ouvertes #4) ; à instruire par le chercheur de phase, pas par arbitrage humain.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Cadrage amont de cette phase (à lire en premier)
- `.planning/ROADMAP.md` §« Phase 27 » (l. 1833-1943) — le périmètre détaillé, déjà quasi-cadré.
- `docs/superpowers/specs/2026-08-05-parallelisation-execution-design.md` (225 l.) — la spec de
  design complète, chemin retenu, les 5 livrables.
- `.planning/research/2026-08-05-parallelisation-execution.md` (497 l.) — la recherche source,
  mécanismes mesurés sur pièce, options chiffrées, journal des hypothèses, questions ouvertes.
- `plugin/conductor/references/team-kernel.md:55-70` — la doctrine fausse à corriger (livrable 1).

### Antécédents et registre
- ADR-064 — un écrivain = un worktree (amendée en Phase 24).
- ADR-069 — Iron Law 2 révisée (router, jamais forker) ; adoption des workstreams — **fait foi sur les
  chiffres de couverture tant que la re-dérivation parallèle n'a pas conclu**.
- ADR-031 — jamais de fix sans validation humaine (le mur du livrable 4, décision A).
- `.planning/STATE.md:768-772` — item en attente de la Phase 19 : « les vagues parallèles d'exécution
  partagent le même arbre de travail (pas d'`isolation: worktree`) … la garantie vient de la
  déclaration, pas de la construction » — **même sujet que le livrable 2 de cette phase**, à traiter
  comme contexte convergent, pas comme un todo formellement folded (aucune correspondance automatique
  trouvée par `gsd-tools query todo.match-phase 27`, re-testé ce jour → 0 match, absence de mécanisme
  `.planning/todos/` structuré dans ce dépôt).

### Moteur (source de vérité machine, gsd-core 1.9.1 au moment de la recherche)
- `~/.claude/gsd-core/bin/lib/claude-orchestration.cjs` — échelle de gates, `partitionStages`,
  `emitWorkflowScript`.
- `~/.claude/gsd-core/bin/lib/claude-orchestration-command-router.cjs:157` — résolution
  `GSD_AGENT_SDK_VERSION`.
- `~/.claude/gsd-core/bin/lib/host-integration.cjs:464-469` — `shouldFlattenDispatch` (reste vrai,
  mais n'est plus le bon chemin à citer pour le parallélisme intra-étape).
- `/opt/homebrew/lib/node_modules/@anthropic-ai/claude-code/sdk-tools.d.ts:2398-2428` — `WorkflowInput`
  / `WorkflowOutput` déclarés dans le binaire installé.

### Gates et scripts de ce dépôt
- `plugin/conductor/scripts/check-agents.sh:39,158-160,528-530` — validation `isolation: worktree`,
  déjà en place, 0 agent ne le déclare (re-vérifié ce jour).
- `plugin/conductor/scripts/check-overlaps.sh` — piège de nommage (D-08), ne pas confondre avec la
  disjonction de périmètres.
- `plugin/planning-core/scripts/workstream-policy.sh` — primitives de chemin partagées, obligatoires
  pour toute primitive touchant `.planning/` (D-12).
- `.planning/config.json` — état re-lu en entier ce jour ; `claude_orchestration` absent, à poser au
  livrable 4 (D-09) ; `.gitignore` racine sans entrée `worktree` (D-06).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `partitionStages()` / `emitWorkflowScript()` (amont, `claude-orchestration.cjs`) — testés sur le
  corpus réel de la Phase 24 (12 plans → 4 étages, 0 collision) et sur un cas jouet à 3 plans dans la
  recherche. C'est la fonction à câbler pour le livrable 3, pas à réécrire.
- Le barème de gates `check-agents.sh` valide déjà `isolation` — le livrable 2 n'a rien à ajouter côté
  machine de validation, seulement des lignes de frontmatter et deux fichiers matériels.
- `workstream-policy.sh` — primitives de chemin déjà partagées, à réutiliser pour toute manipulation
  de chemin introduite par le livrable 3 (D-12).

### Established Patterns
- **ADR-069, Iron Law 2 révisée** : router une capacité amont partiellement couverte en écrivant ses
  limites, jamais la réimplémenter. S'applique directement au livrable 3 (D-07) et exclut l'option 3
  du périmètre de cette phase.
- **Repli fail-closed intégral** déjà pratiqué par les capabilities dormantes de la Phase 24
  (ex. `broken-windows`, `hooks.community`) — le même patron s'applique à `claude_orchestration`
  (D-09) : tout échec de gate retombe sur `inline`, identique à l'octet près au comportement actuel.

### Integration Points
- `.planning/config.json` — point d'intégration principal du livrable 4 (`claude_orchestration.*`).
- `.gitignore` racine + `.worktreeinclude` (à créer) — point d'intégration du livrable 2.
- `plugin/conductor/scripts/dag.sh` — point d'intégration du livrable 3, socle `conductor`, lu par
  tous les managers du team-kernel (dev, design) : tout changement de contrat de sortie (`ready`) doit
  rester rétro-compatible ou migrer tous les lecteurs.
- `plugin/conductor/references/team-kernel.md:64-68` — point d'intégration du livrable 1.

</code_context>

<specifics>
## Specific Ideas

- Origine de la demande : Samuel, le 2026-08-05, à la clôture de la Phase 24 — « parallélisation
  complète, simple et granulaire. Le but est de gagner du temps d'exécution sans que les agents se
  marchent dessus. » [ROADMAP.md:1835-1838]
- La recherche a **renversé la prémisse** de cette demande : ce que Samuel a vu dans les workstreams
  (« cloisonner pour ne pas se marcher dessus ») est le bon principe, mais l'objet qui l'applique à
  l'exécution s'appelle `isolation: worktree`, pas `workstream` — les workstreams compartimentent le
  planning, jamais l'exécution (`grep -c "workstream" execute-phase.md` → 0, mesuré par la recherche).
  [recherche §B, spec §0 point « quatrième fait »]

</specifics>

<deferred>
## Deferred Ideas

- **Option 3** (partitionneur dans `dag.sh`) — retenue en réserve si le spike de l'option 2 échoue, ou
  comme extension une fois l'option 2 éprouvée. Pas cette phase. [ROADMAP.md:1909 ; spec §4.3]
- **Remontée upstream** des workflows aveugles aux workstreams et des profils de contexte sans
  consommateur — geste de contribution externe déjà noté en Phase 24, pas du code de ce dépôt.
- **Item STATE.md:768-772** (Phase 19) — se résorbe par le livrable 2 de cette phase ; à cocher/clore
  dans `STATE.md` en fin de Phase 27, pas à re-instruire.

### Reviewed Todos (not folded)
Aucun todo structuré trouvé par `gsd-tools query todo.match-phase 27` (0 match, mécanisme
`.planning/todos/` absent de ce dépôt). L'item connexe de `STATE.md:768-772` est traité comme contexte
convergent en `<canonical_refs>`, pas comme un todo formellement plié.

</deferred>

<escalations>
## Vérification explicite — aucune escalade nécessaire

Le mandat de ce cadrage impose de vérifier, question par question, si une zone grise résiste aux
sources disponibles avant de conclure à l'absence d'escalade. Revue des candidats identifiés :

1. **Mur ADR-031 (repli « un étage = un workflow »)** — DÉJÀ TRANCHÉ (décision A du digest). Reste à
   *re-prouver* pendant le spike (livrable 4), ce qui est une action d'exécution, pas une question
   ouverte de cadrage.
2. **`worktree.baseRef`** — DÉJÀ TRANCHÉ (décision B du digest) : `"head"`.
3. **Divergence de comptage `workstream`/`.planning/` en dur** — hors périmètre de ce cadrage, en
   cours de re-dérivation par un nœud parallèle de la même mission ; ADR-069 fait foi jusque-là.
4. **Portée de `isolation: worktree` (quels modules)** — DÉJÀ TRANCHÉE par la spec elle-même (« tous
   les modules portant des agents »), la liste précise d'agents est un calcul mécanique (D-05), pas
   une préférence.
5. **Cohabitation `isolation: worktree` × `GSD_WORKSTREAM`** — question technique non mesurée par la
   recherche, mais c'est une question de fait pour le chercheur de phase (`gsd-phase-researcher`), pas
   une question de vision pour Samuel — elle ne change pas la direction du livrable, seulement son
   détail d'implémentation.

**Conclusion : zéro décision remontée en arbitrage humain pour ce cadrage.** Tout ce que le ROADMAP,
la spec et la recherche du 2026-08-05 laissaient ouvert relève soit d'une décision déjà tranchée par
Samuel (A, B), soit d'un calcul mécanique de planification, soit d'une question de recherche technique
sans impact sur la vision du livrable.

</escalations>

---

*Phase: 27-Parallélisation d'exécution — granulaire, simple, sans collision d'écriture*
*Context gathered: 2026-08-05*
