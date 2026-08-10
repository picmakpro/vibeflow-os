# Phase 28: Preuve que ce qui est armé dans le plugin est armé chez l'utilisateur - Context

**Gathered:** 2026-08-10
**Status:** Ready for planning

> **Préalable levé.** L'entrée de roadmap a été écrite avant la mise à jour de VibeFlow, avec la
> consigne explicite de re-mesurer au cadrage plutôt que de reprendre ses faits. Tous les faits
> ci-dessous ont été **re-mesurés sur disque le 2026-08-10**, après mise à jour. Ce qui a bougé est
> nommé en `<code_context>` § « État re-mesuré ».

<domain>
## Phase Boundary

Cette phase pose **le maillon qui manquait à #38** : relier un **armement** livré par le plugin à la
**distribution de la précondition** qui le rend sûr. Aujourd'hui rien ne relie les deux — l'armement
voyage avec le plugin, la précondition reste dans le poste de développement, et les cinq gates
rendent vert. [ROADMAP.md:2012-2015]

Le motif est celui de `check-capability-activation.sh` (Phase 24) **d'un cran plus loin** : ce gate
relie une entrée de doc à l'activation de sa capability ; celui-ci relie un armement à la
distribution de sa précondition. [ROADMAP.md:2051-2058]

**Livrable, en une phrase :** un gate qui rend **rouge** quand un artefact distribué est armé d'une
capacité dont la précondition n'est posée par personne chez l'utilisateur — et dont la
**discriminance est prouvée sur l'incident #38 lui-même**.

**Hors périmètre, verrouillé et non rediscutable :**
- **Ré-armer `isolation: worktree`.** Question distincte, et cette phase ne l'ouvre pas : le retour
  des commits d'un worker isolé n'est implémenté nulle part en amont (`open-gsd/gsd-core#3302`).
  Tant que ce point n'est pas levé, ré-armer serait refaire #38 avec une précondition de plus.
  [ROADMAP.md:2067-2071]
- **Distribuer `worktree.baseRef`** — corollaire du précédent, même verrou.
- **Ouvrir un véhicule de distribution de settings au-delà de `hooks`** — écarté par D-02 ; voir
  `<deferred>`.
- Solder l'ensemble des findings que le gate remontera sur l'existant — écarté par D-05.

</domain>

<decisions>
## Implementation Decisions

### Recensement — qu'est-ce qu'un « armement » ?

- **D-01 — Déclaration par l'artefact, doublée d'une liste close.** Le gate vérifie **deux**
  ensembles, jamais un seul :
  1. **Le déclaré** — l'artefact (agent, skill) nomme lui-même sa précondition externe en
     frontmatter. Le patron existe déjà et est éprouvé : `vf-mcp-consumer` / `vf-mcp-tools` +
     `inject-mcp-tools.sh`. Le gate ne devine rien ; il vérifie que ce qui est déclaré est distribué.
  2. **La liste close** — un petit ensemble de clés **déjà connues comme dangereuses**, vérifié en
     plus du déclaré, que l'artefact ait déclaré ou non. Point de départ : le champ `isolation:` du
     frontmatter et les outils `mcp__*`. La liste s'élargit ligne par ligne quand un cas nouveau se
     présente — jamais par heuristique.

  **Raison d'être de la seconde moitié, et elle est la leçon de #38 :** la déclaration seule aurait
  laissé passer #38 à l'identique, puisque le mode d'échec exact était que *personne n'a déclaré*.
  La déclaration porte l'extensible, la liste close rattrape le connu. — **Reversibility:** costly —
  une clé de frontmatter déclarée par des artefacts distribués devient un contrat public de
  frontmatter, à retirer de tous les modules porteurs si on la renonce ; `check-agents.sh` devra
  l'admettre dans ses clés `KNOWN` (`plugin/conductor/scripts/check-agents.sh:160`).
  [ROADMAP.md:2062-2064 ; arbitrage humain du 2026-08-10]

- **D-01b — Le gate écrit ses propres bornes.** Ce que la liste close couvre, ce qu'elle ne couvre
  pas, et pourquoi la déclaration reste faillible : à écrire dans l'en-tête du gate, sur le patron
  déjà pratiqué par `check-capability-activation.sh` (qui déclare explicitement ne pas juger la
  prose). Un gate qui laisse croire qu'il couvre plus que son périmètre réel est le mode d'échec
  qu'il existe pour fermer. — **Reversibility:** reversible.

### Verdict — que fait le gate quand la précondition n'est posée par personne ?

- **D-02 — Il bloque, et un `ensure-*.sh` déclaré vaut preuve de distribution.** Deux verdicts, pas
  un :
  - **Rouge** par défaut : armement sans précondition distribuée ⇒ exit non nul, message nommant
    l'artefact, l'armement, la précondition manquante **et** fichier:ligne (patron de message déjà
    imposé par `check-capability-activation.sh`).
  - **Vert** si un `ensure-*.sh` runtime déclaré vérifie la précondition **chez l'utilisateur au
    moment de l'usage**. Le patron existe et tourne : `ensure-deps.sh` (GSD + Superpowers),
    `ensure-design-deps.sh` (présence **et** activation des 4 plugins de la chaîne design, posé le
    2026-08-10, quick `260810-fh3`).

  **Ce que ce choix évite explicitement :** ouvrir un véhicule de distribution de settings dans
  l'engine. Mesuré ce jour, `merge-hooks.sh` ne merge dans `settings.json` que la clé `hooks` — il
  n'existe **aucun** véhicule pour un autre réglage. Exiger que l'engine pose la précondition aurait
  demandé de créer ce véhicule, donc de faire écrire l'engine dans le settings de l'utilisateur :
  hors du périmètre voulu pour cette phase. — **Reversibility:** reversible — le verdict est une
  règle du gate, pas un contrat distribué. [arbitrage humain du 2026-08-10 ; mesuré ce jour :
  `plugin/_internal/merge-hooks.sh`, `plugin/_internal/vibeflow-update.sh:276-330`]

- **D-02b — Le mécanisme de liaison artefact ↔ `ensure-*.sh` relève du plan, pas du cadrage.**
  Convention de nommage, champ de frontmatter nommant le script, ou registre : c'est un calcul
  d'implémentation. Seule contrainte de cadrage : la liaison doit être **explicite et vérifiable
  par machine**, jamais inférée d'une proximité de nom. — **Reversibility:** reversible.

### Emplacement — où vit le gate ?

- **D-03 — Extension de `plugin/dev-orchestrator/scripts/check-capability-activation.sh`, pas un
  sixième gate.** Le ROADMAP le demande nommément (« regarder d'abord si ce gate s'étend plutôt que
  d'en créer un sixième ») et la Phase 24 a chiffré le coût du réflexe inverse : 6 implémentations
  d'un même besoin en 3 langages, et un script neuf dans aucun roster. Le script est déjà à
  **443 lignes** et très commenté : si l'extension le fait franchir le seuil de
  `check-file-size.sh`, le découpage est une décision de plan — jamais un prétexte à créer un gate
  parallèle. — **Reversibility:** costly — le script est câblé dans les rosters de gates et la CI ;
  le scinder après coup impose de migrer tous ses appelants. [ROADMAP.md:2051-2058 ; mesuré ce jour :
  443 lignes]

- **D-04 — Le gate doit voir ce que l'install pose, pas seulement ce que le repo contient.** C'est
  la faille de fond de #38 : le repo avait le réglage dans son settings local, donc tous les gates
  du repo rendaient vert. Le job CI `lab-frais` (`.github/workflows/ci.yml:620`) est le **seul**
  endroit qui installe la fermeture transitive de `conductor` dans un lab vierge — il vérifie
  aujourd'hui que l'install *tient* (Gate C), jamais qu'elle est *cohérente avec ce qu'elle
  promet*. Une seule implémentation (D-03), exécutée **aussi** depuis `lab-frais`. — **Reversibility:**
  reversible — ajout d'une étape au job.

### Portée — gate seul ou traitement de l'existant ?

- **D-05 — Le gate, plus UN cas de preuve. Le reste part en backlog.** Un gate qu'on n'a jamais vu
  rendre rouge sur un cas réel n'est pas prouvé.

- **D-06 — Le cas de preuve est #38 lui-même, rejoué.** Remettre `isolation: worktree` sur un agent
  distribué sans précondition distribuée ⇒ le gate rend **ROUGE** ; désarmer (ou prouver la
  précondition) ⇒ **VERT**. Discriminance vérifiée dans les deux sens, sur l'incident même qui ouvre
  la phase — c'est déjà la méthode employée par le fix v2.50.1 (« Discriminance vérifiée (ligne
  remise → exit 1) », commit `bc825e6`).

  **Attention au recouvrement, à instruire au plan :** `check-agents.sh:528-549` interdit **déjà**
  toute valeur d'`isolation:` dans un agent distribué. Le test de discriminance doit donc établir
  que **le nouveau gate** rend rouge de son propre chef, et pas seulement que l'ancien le fait
  encore. Si les deux gardes se recouvrent intégralement, le plan doit dire laquelle porte la règle
  et pourquoi l'autre subsiste — jamais laisser deux gardes muettes l'une sur l'autre.
  — **Reversibility:** reversible. [arbitrage humain du 2026-08-10 ; `bc825e6`]

### Claude's Discretion

- Le mécanisme exact de liaison artefact ↔ `ensure-*.sh` (D-02b) : nommage, frontmatter ou registre.
- Le nom exact de la clé de frontmatter portant la précondition déclarée (D-01), et son ajout aux
  clés `KNOWN` de `check-agents.sh:160`.
- Le contenu initial exact de la liste close (D-01, point 2) — `isolation:` et `mcp__*` sont le
  plancher, l'énumération complète est un calcul de planification.
- Le découpage éventuel de `check-capability-activation.sh` si l'extension franchit le seuil de
  `check-file-size.sh` (D-03).
- La forme du test de discriminance et son emplacement dans les suites (D-06).
- L'articulation exacte avec `check-agents.sh` sur le cas `isolation:` (D-06, § recouvrement).
- Découpage en plans, numérotation, nommage des artefacts produits.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Cadrage amont de cette phase (à lire en premier)
- `.planning/ROADMAP.md` §« Phase 28 » (l. 2005-2076, fin du fichier) — le diagnostic complet, le tableau des gardes
  passées, les trois questions ouvertes. **Écrit avant la mise à jour de VibeFlow** : ses faits
  moteur sont à re-mesurer, pas à reprendre.
- `.planning/phases/VFDO-27-parall-lisation-d-ex-cution-granulaire-simple-sans-collision/27-CONTEXT.md`
  — le cadrage qui a produit l'armement, en particulier D-03 (`worktree.baseRef: "head"`, décision B)
  et D-05 (portée de l'isolation). C'est le fichier où la précondition a été identifiée **et** où la
  question « qui l'écrit chez l'utilisateur ? » n'a jamais été posée.
- `.planning/research/2026-08-05-parallelisation-execution.md:92-94` — la précondition, écrite mot
  pour mot, dix mois avant l'incident. **Produite sur gsd-core 1.9.1** ; le poste est en 1.10.0.

### L'incident et son correctif
- Commit `bc825e6` — `fix(#38): isolation worktree retirée des 13 agents + garde-fou machine (#39)`.
  Le message porte le diagnostic causal complet et la méthode de discriminance à reprendre.
- `plugin/conductor/scripts/check-agents.sh:528-549` — l'interdiction posée en v2.50.1, motif et
  condition de levée écrits sur place. **Recouvrement à instruire** (D-06).
- `plugin/conductor/scripts/check-agents.sh:39,160` — clés `KNOWN` du frontmatter ; toute nouvelle
  clé de précondition déclarée (D-01) doit y être admise, sinon `--strict` la refusera.

### Le gate à étendre, et son précédent
- `plugin/dev-orchestrator/scripts/check-capability-activation.sh` (443 l.) — **le fichier à
  étendre** (D-03). Son en-tête (l. 1-80) est le patron rédactionnel à suivre : périmètre borné et
  déclaré, règles numérotées, plancher anti-vert-à-vide (règle 1), discriminance bidirectionnelle
  (règle 3), comparaison de noms par frontière et jamais par sous-chaîne nue.
- `.github/workflows/ci.yml:620-652 (fin du fichier)` — job `lab-frais` (install baseline + Gate C), point
  d'intégration de D-04.

### Le patron « ensure-* » qui vaut preuve (D-02)
- `plugin/design-orchestrator/scripts/ensure-design-deps.sh` — présence **et** activation des 4
  plugins de la chaîne design ; posé le 2026-08-10 (quick `260810-fh3`, commit `e9b3650`). Le plus
  récent et le plus proche du besoin.
- `plugin/dev-orchestrator/scripts/ensure-deps.sh` — GSD + Superpowers, auto-install non-interactif.
- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` + clés `vf-mcp-consumer` / `vf-mcp-tools` —
  le précédent de **précondition externe déclarée par l'artefact** (D-01, point 1).

### Ce que l'engine pose, et ce qu'il ne pose pas (fonde D-02)
- `plugin/_internal/merge-hooks.sh` — ne merge que la clé `hooks` de `settings.json`.
- `plugin/_internal/vibeflow-update.sh:276-330` — le seul point où l'engine touche
  `settings.json`, via le merger de hooks. **Aucun autre réglage n'est distribué.**

### Registre
- ADR-044 — agents natifs machine-enforced (`check-agents.sh` : description + model + memory).
- ADR-054 — Bash portable (Windows ok, pas de `jq` / `grep -P` / `sed -i` obligatoires). Contraint
  toute extension du gate.
- ADR-031 — jamais de fix sans validation humaine.
- `.planning/STATE.md` §Deferred — **WINDOWS #4** : `inject-mcp-tools.sh` ne valide pas qu'un nom de
  serveur cité existe réellement. Même famille que cette phase, **non folded** (voir `<deferred>`).

</canonical_refs>

<code_context>
## Existing Code Insights

### État re-mesuré le 2026-08-10 (après mise à jour de VibeFlow)

| Fait | Valeur mesurée | Conséquence |
|---|---|---|
| VibeFlow racine / installé | `v2.50.1` / `v2.50.1` | préalable de la phase levé, les deux sont alignés |
| Moteur `@opengsd/gsd-core` | **1.10.0** (`~/.claude/gsd-core/VERSION`) | la recherche Phase 27 tournait sur **1.9.1** — tout fait moteur qu'elle cite est à re-mesurer par le chercheur, jamais à recopier |
| Agents déclarant `isolation:` | **0** (`grep -rl "^isolation:" plugin/*/agents/*.md` → vide) | l'armement de #38 est bien retiré ; le cas de preuve devra le **rejouer**, pas l'observer |
| `worktree.baseRef` | **seule clé** de `.claude/settings.local.json` de ce repo | la précondition est toujours strictement locale au poste |
| `baseRef` dans `plugin/_internal/` | **0 occurrence** (uniquement des mentions en CHANGELOG) | rien n'a changé côté distribution depuis le hotfix |
| Véhicule de distribution de settings | **inexistant** hors `hooks` | fonde D-02 : le gate bloque, il ne peut pas demander à l'engine de poser le réglage |

### Reusable Assets
- **`check-capability-activation.sh`** — le précédent structurel exact, à étendre et non à copier.
  Fournit déjà : lecture d'un index généré, lecture de `.planning/config.json`, lecture à trois états
  (actif / inactif / **indéterminé** — un gate ne se replie pas sur un verdict qu'il ne peut pas
  tenir), plancher anti-vert-à-vide, messages `fichier:ligne`, discriminance bidirectionnelle. Toutes
  ces primitives sont réutilisables telles quelles pour armement ↔ distribution.
- **`ensure-deps.sh` / `ensure-design-deps.sh`** — la moitié « vert » du verdict (D-02) : deux
  implémentations vivantes du contrat « la précondition est vérifiée chez l'utilisateur ».
- **`inject-mcp-tools.sh` + `vf-mcp-consumer`** — la moitié « déclaration » (D-01, point 1) : un
  artefact qui nomme sa dépendance externe, et un script qui la traite.
- **Job `lab-frais`** — l'environnement d'un lab vierge réellement installé existe déjà en CI ; D-04
  y branche une étape, il n'y a pas d'infrastructure à créer.

### Established Patterns
- **Un besoin = une implémentation** (leçon chiffrée de la Phase 24 : 6 implémentations d'un même
  besoin en 3 langages). Fonde D-03.
- **Un gate déclare ses bornes dans son en-tête** (`check-capability-activation.sh` déclare ne pas
  juger la prose). Fonde D-01b.
- **Discriminance prouvée dans les deux sens**, jamais supposée (règle 3 du gate de la Phase 24 ;
  méthode du fix `bc825e6`). Fonde D-06.
- **Repli fail-closed** : `awk` plutôt que `grep` piped dans les gates de ce dépôt (le `grep`
  proxifié du poste tronque silencieusement — 31 lignes rendues sur 102 mesurées, constat inscrit
  dans l'en-tête du gate). À respecter par toute extension.

### Integration Points
- `plugin/dev-orchestrator/scripts/check-capability-activation.sh` — point d'intégration principal.
- `.github/workflows/ci.yml:620-652 (fin du fichier)` — job `lab-frais`, second point d'intégration (D-04).
- `plugin/conductor/scripts/check-agents.sh:160` — clés `KNOWN` : toute clé de précondition déclarée
  doit y être admise sous peine d'échec en `--strict`.
- Les suites de tests du module `dev-orchestrator` (`plugin/dev-orchestrator/scripts/tests/`) — le
  test de discriminance de D-06 y atterrit.

</code_context>

<specifics>
## Specific Ideas

- **Origine de la phase** : Samuel, le 2026-08-10, dans la foulée du hotfix #38 — *« corrige le trou
  structurel »*. [ROADMAP.md:2008-2009]
- **La phrase qui définit le trou**, et qui doit rester la boussole du plan : *« Le maillon manquant
  n'était pas la connaissance. La précondition était identifiée, écrite, arbitrée et posée. Ce qui
  n'a jamais été posé, c'est la question suivante : **qui écrit ce réglage chez l'utilisateur ?** »*
  [ROADMAP.md:2034-2036]
- **Le piège nommé par le ROADMAP lui-même** : *« un gate qui [devine la frontière] sera soit inerte
  soit insupportable »* [ROADMAP.md:2064]. D-01 y répond en refusant l'heuristique dans les deux
  ensembles — le déclaré est explicite, la liste close est énumérée à la main.

</specifics>

<deferred>
## Deferred Ideas

- **Ré-armer `isolation: worktree`** — fermé tant qu'`open-gsd/gsd-core#3302` n'est pas levée. Ne
  pas rouvrir depuis cette phase, même si le gate rend vert : un gate vert prouve que la précondition
  est distribuée, jamais que le worker sait rendre son travail.
- **Ouvrir un véhicule de distribution de settings dans l'engine** (au-delà de `hooks`) — écarté par
  D-02. Redevient pertinent le jour où une précondition ne peut *pas* être vérifiée par un
  `ensure-*.sh` runtime. Phase distincte : l'engine écrirait dans le settings de l'utilisateur.
- **Solder les findings du gate sur l'existant** — écarté par D-05. Deux candidats déjà identifiés :
  les outils `mcp__*` de `plugin/dev-orchestrator/agents/vf-reviewer.md` (seul agent concerné), et la
  chaîne design couverte par `ensure-design-deps.sh` (bon candidat pour prouver le verdict **vert**,
  si le plan veut une seconde preuve à coût faible).
- **WINDOWS #4** (`.planning/STATE.md` §Deferred) — `inject-mcp-tools.sh` ne valide pas qu'un serveur
  MCP cité existe réellement. Même famille (armement sans précondition vérifiée), mais l'item est
  déjà *repris au périmètre de la Phase 21* ; ne pas le re-instruire ici.
- **Recette humaine `mcp__*`** (WINDOWS #3) — infaisable dans ce dépôt (aucun `.mcp.json`, serveur
  non connecté) ; toute preuve produite ici serait fabriquée. Se recette sur un lab iOS équipé.

### Reviewed Todos (not folded)
`gsd-tools query todo.match-phase 28` → **0 match** (mécanisme `.planning/todos/` absent de ce
dépôt). Les items connexes de `.planning/STATE.md` §Deferred (WINDOWS #3 et #4) sont traités
ci-dessus comme contexte convergent, pas comme des todos formellement pliés.

</deferred>

---

*Phase: 28-Preuve que ce qui est armé dans le plugin est armé chez l'utilisateur*
*Context gathered: 2026-08-10*
