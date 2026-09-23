# Phase 39: Workstreams — partition du planning et collaboration concurrente - Context

**Gathered:** 2026-09-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Le planning devient réellement **partitionnable en workstreams** — plusieurs sessions et
plusieurs humains travaillent en parallèle sur des feuilles de route disjointes — et toute
**divergence silencieuse** entre partitions (split-brain, phase orpheline, compteur faux) est
**détectée bruyamment** au lieu d'être subie. Chantier d'**adoption**, pas de re-décision :
l'adoption elle-même a été tranchée le 2026-08-04 (ADR-069, verbatim Samuel : « je préfère jeter
des IronLaw outdated que de sacrifier l'efficience »). Les gardes existent depuis la Phase 24
(`GSDA-13`→`GSDA-19`, closes) ; ce qui manque et que cette phase livre : (1) la preuve mesurée que
le mécanisme amont marche pour le modèle d'équipe VF, (2) le câblage `--ws` réellement exercé côté
VF, (3) le filet de détection de divergence — aujourd'hui absent à 100 %.

**Hors périmètre, explicitement** : la partition réelle de `vibeflow-os` (geste séparé, gaté
humain, postérieur à la clôture — voir `<deferred>`) ; tout dépôt tiers (Reviz/WillHosting,
Scroll-Off) ; toute révision de la condition dure d'ADR-069 ; le dépôt effectif de l'issue amont
(rédaction seulement).

</domain>

<decisions>
## Implementation Decisions

Cinq arbitrages humains ont été rendus par Samuel le 2026-09-09, sur mesures de première main
(`.planning/research/2026-09-09-phase-39-workstreams-mesures-de-cadrage.md`), après escalade du
manager de mission. Ils sont **verrouillés** — ne pas les rouvrir, ne pas les réinterpréter.

### Paradoxe d'auto-application — option A′
- **D-01:** La partition est prouvée sur un **clone jetable de `vibeflow-os`** (histoire réelle du
  dépôt), **hors de l'arbre de travail**. Les agents `vf-*` y tournent avec `--ws`, les gates y
  sont exercés. **L'arbre principal n'est JAMAIS partitionné pendant la phase** — la condition dure
  d'ADR-069 (« aucune partition tant qu'une phase est en vol ») n'est **pas révisée**, elle est
  respectée à la lettre. Aucun dépôt tiers n'est touché (option B écartée). — **Reversibility:**
  one-way — le clone jetable est détruit en fin de mission ; la preuve qu'il porte (mécanisme
  validé) ne se rejoue pas sans reconstruire un clone équivalent.
- **D-02:** La **partition réelle de `vibeflow-os`** est un **geste séparé, gaté humain,
  postérieur à la clôture de la Phase 39** — pas un livrable de cette phase. Elle doit être
  **inscrite avec un déclencheur de reprise daté** dans le plan/ROADMAP pour ne pas se reperdre
  comme s'est reperdue l'adoption entre le 2026-08-04 et le 2026-08-30.
- **D-03:** Nuance de preuve à ne jamais arrondir dans les livrables : un clone établit une preuve
  **de mécanisme**, pas d'usage concurrent réel sur le dépôt vivant. Tout SUMMARY/VERIFICATION doit
  le dire explicitement.

### `GSDA-19` — re-rédaction
- **D-04:** `GSDA-19` est **re-rédigée en BUG DE COMPORTEMENT**, sur le défaut mesuré
  (`init.progress --ws default` rend `project_exists: false` alors que `.planning/PROJECT.md`
  existe là où la migration officielle l'a laissé — recherche §5). L'angle « descripteur non
  descriptif » est **abandonné**. La phase **rédige** l'issue prête à poster ; elle ne la **poste
  pas** — geste humain. — **Reversibility:** reversible — un texte d'issue non posté n'engage rien.

### Compensation côté VF — minimale
- **D-05:** VF passe **`--ws` explicitement sur ses propres appels `gsd_run`** (agents `vf-*`).
  **Aucun workflow amont n'est réécrit** — une couche de réparation deviendrait dette morte à
  chaque correctif publié en face (précédent : trois correctifs `#4455`/`#4456`/`#4225` fermés les
  7-8 septembre 2026, non distribués avant 1.13.0 mais qui bougeront la couverture mécaniquement).
- **D-06:** Une **veille datée sur un ÉVÉNEMENT** — la publication de la prochaine version de
  `gsd-core` — remplace toute veille à seuil chiffré. Précédent explicite à ne pas reproduire :
  `WKTR-03` désarmée le 2026-09-07, seuil figé devenu faux positif permanent
  (`.claude/agent-memory/vf-coder/project_veille-gsd-core-eteinte.md`). **« Couverture amont
  figée » est FAUX comme propriété stable** — à consigner tel quel, jamais recopié comme un fait
  stable dans un futur document.

### Préfixe d'exigences
- **D-07:** Famille **`PART-xx`** (`PART-01…`), **pas `WSTR`**. Motif de lisibilité : voisinage
  visuel avec `WKTR` (worktree, vivant) et `WTCH`, dans une phase qui fait cohabiter workstream et
  worktree à répétition dans les mêmes phrases (critère 2, ADR-064). `WSTR` était techniquement
  libre (4 occurrences dépôt entier, toutes la proposition elle-même — recherche §10) ; ce n'est
  pas un conflit d'espace de noms, c'est un arbitrage de lisibilité pris avant que des identifiants
  soient gravés. Espace de noms dérivé au 2026-09-09 : **40 préfixes** dans `REQUIREMENTS.md`
  (194 identifiants), **41 familles réellement occupées** (`SIG-01`→`SIG-06`, Phase 17, vit hors
  des deux ledgers). `PART` vérifié libre par `comm`, jamais par `grep | sort -u`.

### Critère de succès 3 — exhaustivité, pas échantillon
- **D-08:** **TOUS** les agents dispatchés dans le run de preuve (sur le clone jetable) passent
  `--ws`, **sans exception** — jamais « au moins un par étage ». Motif : `GSDA-15` (le câblage) est
  **close** avec une observance **mesurée nulle** au 2026-09-09 (aucun lab n'est partitionné,
  aucun agent `vf-*` ne passe `--ws` en usage réel). L'énoncé de l'exigence doit être
  **insatisfaisable à vide** — un seul agent oublié = critère non atteint.

### Les deux faits mesurés qui doivent devenir des exigences gravées

- **D-09 — Le risque (b) d'ADR-069 a MIGRÉ, il n'a pas disparu.** `pr-branch.md` (gsd-core 1.13.0,
  `:250-270`) lève le silence au niveau **chemin** (`.planning/workstreams/<nom>/**` tombe dans le
  bloc `$OTHER`, préservé et signalé). Mais il **subsiste au niveau COMMIT** :
  `.planning/workstreams/<nom>/ROADMAP.md` ne matche pas `STRUCTURAL_RE`
  (ancré `^\.planning/ROADMAP\.md$`) — un commit qui ne touche **que** la feuille de route d'un
  workstream sort à `NON_PLANNING=0, STRUCTURAL=0`, classé « transient planning commit », **EXCLU
  DANS LES DEUX MODES** (`pr_strict` true ou false), invisible dans tout rapport (jamais dans le
  diff, seulement dans un compteur anonyme `Commits to exclude: {N}`). Vérifié par exécution réelle
  sur dépôt jetable partitionné le 2026-09-09 (recherche §7). **Décision à porter au plan, pas
  tranchée ici** : corriger côté VF (mitigation documentée, geste de vérification avant PR) ou
  déclarer coût assumé **daté** dans un amendement d'ADR-069 — les deux options restent ouvertes
  pour le planner/l'exécuteur, mais l'une des deux DOIT être choisie et écrite, jamais laissée
  implicite comme la version 2026-08-04 de ce même risque l'avait laissée.
- **D-10 — La collision ADR-064 est OUVERTE à l'intérieur d'une équipe, refermée entre sessions.**
  Mesuré (recherche §3) : tous les sous-agents héritent du `CLAUDE_CODE_SESSION_ID` de leur parent
  (`CLAUDE_CODE_CHILD_SESSION=1`) → un manager qui dispatche des workers sur des worktrees
  différents leur fait **tous partager un unique pointeur de workstream** ; dernier `set` gagnant.
  Le facteur discriminant est **la clé de session, pas le worktree**. C'est exactement le modèle
  d'exécution de VF (team-kernel) — le plan DOIT le traiter. Remède mesuré, sans patcher l'amont :
  **`--ws` explicite sur chaque appel** (déjà couvert par D-05/D-08) et/ou `GSD_SESSION_KEY`
  distinct par mandat (première clé de `WORKSTREAM_SESSION_ENV_KEYS`). Entre deux sessions Claude
  Code distinctes (deux worktrees, deux process), la collision est en revanche **refermée** —
  isolation parfaite mesurée (recherche §3, cas A/B).

### Filet de détection de divergence
- **D-11:** Spécifié sur la signature mesurée **S2 + S4 + S5** (recherche §8) :
  - **S2** — numéro de phase dupliqué dans un même workstream (signal primaire, robuste aux trois
    variantes de split-brain reproduites : orphan, rootonly, roadmap).
  - **S4** — cardinalité incohérente : `#dossiers de phase ≠ #entrées de ROADMAP du compartiment`,
    et/ou compteurs `progress:` de STATE.md < nombre de dossiers réels.
  - **S5** — fuite de niveau : une phase de workstream référencée dans le `ROADMAP.md` racine.
  - **S1/S3 explicitement écartés en l'état** (orphelin par numéro seul / fantôme par nom de
    dossier complet) : mesurés fragiles — faux négatif (doublon masque la clé) et faux positif 3/3
    (nom de dossier ne matche pas le libellé ROADMAP). S2+S4+S5 suffisent et sont robustes ; ne pas
    les réintroduire sans les normaliser d'abord (numéro + slug).
- **D-12:** Branché **post-merge**, jamais `SessionStart` — motif : la divergence se produit à la
  fusion, un check au démarrage de session la détecte trop tard ou pas du tout selon qui démarre
  une session en premier. Modèle de câblage à réutiliser : `scripts/hooks/pre-push` (git hook
  opt-in, `core.hooksPath scripts/hooks`, jamais armé par défaut, pas de vecteur de distribution
  automatique — précédent #38).
- **D-13:** **Mutation rouge prouvée obligatoire** — un gate qui ne sait que dire oui ne vaut rien
  (leçon Phase 24 : `check-workstream-pointer.sh` et `check-state-integrity.sh` rendent tous deux
  un vert trompeur sur un dépôt en split-brain mesuré, recherche §9). Le plan doit inclure la
  fixture de split-brain **exécutée** (pas décrite) et la preuve que le nouveau gate la détecte, en
  plus de rester silencieux sur le cas nominal non divergé.

### Claude's Discretion
- La forme exacte du script du filet (nom de fichier, module d'hébergement — `planning-core` déjà
  propriétaire de `workstream-policy.sh`, ou `conductor` déjà propriétaire de
  `check-state-integrity.sh`) est laissée à l'exécution/au planner, sous réserve de respecter D-11
  à D-13.
- Le choix concret entre « corriger `pr-branch` côté VF » et « déclarer coût assumé daté » (D-09)
  est un point de plan, pas une décision de cadrage — mais **doit** apparaître explicitement écrit
  dans le PLAN.md, jamais laissé en silence.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Recherche de cadrage (source factuelle unique de cette phase)
- `.planning/research/2026-09-09-phase-39-workstreams-mesures-de-cadrage.md` — dix mesures par
  exécution réelle, chaque affirmation porte son `fichier:ligne`. **Ne pas relancer ces mesures**,
  elles sont datées et méthodées.

### Décisions humaines verrouillées
- `.planning/STATE.md` § `### Decisions` — deux entrées du 2026-09-09 (« Phase 39, quatre
  arbitrages de cadrage » et « paradoxe d'auto-application : option A′ »). Verbatim faisant foi.

### Doctrine et gouvernance des workstreams
- `docs/ADR.md` § **ADR-069** — décision d'adoption du 2026-08-04, les quatre risques mesurés
  (a/b/c/d), la condition dure, la révision de l'Iron Law 2 (`plugin/conductor/AGENT.md`), le
  déclencheur de réexamen objectif (K2 > 50 %, regex `pr-branch` non ancrées, pointeur in-repo
  retenu par l'amont). **Tout amendement produit par cette phase est un amendement DATÉ de cette
  entrée, jamais une ADR neuve.**
- `plugin/dev-orchestrator/references/workstreams.md` — voix unique de module sur le sujet, 166
  lignes ; prescrit déjà le geste « vérifier quel chemin le workflow a effectivement lu ».
- `plugin/dev-orchestrator/references/mission-flow.md` — protocole d'équipe (team-kernel),
  pertinent pour D-10 (le manager dispatche des workers qui héritent tous du même
  `CLAUDE_CODE_SESSION_ID`).
- `plugin/conductor/AGENT.md` § Iron Law 2 (révisée par ADR-069) — « Router, jamais forker ».

### Ledger et espace de noms
- `.planning/REQUIREMENTS.md` — famille `GSDA-13`→`GSDA-19` (toutes closes, lignes 430-462) : ne
  pas les rouvrir, les reformuler si recouvrement (notamment `GSDA-15` vs l'observance nulle
  mesurée — piège identifié explicitement par le mandat). Table de traçabilité `GSDA-13..19 → Phase
  24` (lignes 797-803) à ne pas casser.
- `.planning/ROADMAP.md` § `### Phase 39` — Goal, Depends on, Success Criteria (6), la mesure de
  première main re-corrigée au cadrage. Source d'autorité du périmètre.

### Gardes existantes (état de départ, aucune ne couvre le filet de divergence)
- `plugin/conductor/scripts/check-workstream-pointer.sh` — ne couvre pas le split-brain (vert
  trompeur mesuré).
- `plugin/conductor/scripts/check-state-integrity.sh` — ne couvre pas, vert trompeur mesuré sur
  compteurs faux.
- `plugin/planning-core/scripts/workstream-policy.sh` — hors sujet, politique de nom uniquement.

### Modèle de câblage de hook réutilisable
- `scripts/hooks/pre-push` — git hook opt-in existant (discipline de release), modèle direct pour
  le hook `post-merge` du filet de divergence (D-12) : même mécanisme d'activation
  (`core.hooksPath`), même philosophie (bloque uniquement le cas visé, jamais armé par défaut sans
  geste explicite).

### Câblage `--ws` déjà en place côté VF (point de départ, pas à refaire)
- `plugin/dev-orchestrator/agents/vf-coder.md` § « Compartiment de planning — passer `--ws`, ne
  jamais présumer » — déclare déjà l'intention ; **la phase doit la rendre observée par exécution**
  (D-08), pas seulement déclarée en frontmatter.
- `plugin/dev-orchestrator/agents/vf-dev-manager.md:34` — même intention côté manager.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `workstream.create` (moteur, `workstream.cjs:46-94`) — migration clé en main vers un dépôt
  partitionné, rollback transactionnel. Rien à fabriquer côté VF pour la migration elle-même.
- `active-workstream-store.cjs` (445 l., `~/.claude/gsd-core/bin/lib/`) — les cinq niveaux de
  résolution du pointeur existent et sont mesurés fonctionnels (niveau 4 compris). Aucun besoin de
  patcher l'amont pour la résolution de pointeur.
- `scripts/hooks/pre-push` — squelette direct à décliner pour un hook `post-merge`.

### Established Patterns
- Toute mesure de couverture ou de comptage sur ce dépôt DOIT utiliser `awk`+`comm`, jamais
  `grep | sort -u` ni `diff` (outillage `rtk` proxifié, `diff` déjà mesuré menteur sur ce poste —
  cf. mémoire `project_diff-proxifie-utiliser-comm.md`). Tout chiffre gravé porte son corpus, son
  critère d'inclusion nommé et sa commande rejouable (précédent ADR-069 lui-même, section
  « Méthode, avant les chiffres »).
- Les hooks git opt-in de ce dépôt suivent tous le même contrat : jamais armés par défaut, activés
  par `git config core.hooksPath scripts/hooks`, ne bloquent que le cas précis visé (précédent #38 :
  ne jamais armer via un settings local).

### Integration Points
- `--ws` est un drapeau GLOBAL au point d'entrée unique `gsd-tools.cjs:4733-4738`, reprojeté en
  `GSD_WORKSTREAM`. Tout appel `gsd_run` de VF (agents `vf-*`) est un point d'intégration direct
  pour D-05/D-08.
- Le filet de divergence (D-11) doit lire `ROADMAP.md` + les dossiers de phase + `STATE.md` — objet
  neuf, aucun script existant ne le fait (recherche §9 : occurrences en commentaire seulement dans
  les trois gardes actuelles).

</code_context>

<specifics>
## Specific Ideas

- Le clone jetable de preuve (D-01) doit porter **l'histoire réelle du dépôt** (pas une fixture
  synthétique) — c'est ce qui distingue cette preuve d'une preuve de mécanisme sur fixture isolée
  comme celles déjà produites en recherche (§2, §7, §8).
- Le déclencheur de reprise pour la partition réelle de `vibeflow-os` (D-02) doit être **daté**,
  au même patron que les autres déclencheurs de ce dépôt (WKTR-03, le déclencheur objectif
  d'ADR-069 lui-même) — jamais une simple case à cocher sans condition de réveil explicite.

</specifics>

<deferred>
## Deferred Ideas

- **Partition réelle de `vibeflow-os`** — geste séparé, gaté humain, postérieur à la clôture de
  cette phase (D-02). Ne PAS l'exécuter dans cette phase, même en fin de plan. Inscrire son
  déclencheur de reprise daté dans le PLAN/ROADMAP.
- **Dépôt effectif de l'issue `GSDA-19` re-rédigée** sur `open-gsd/gsd-core` — rédaction seulement
  dans cette phase (D-04), le clic « poster » reste un geste de Samuel.
- **Révision de la condition dure d'ADR-069** — explicitement écartée, pas un sujet de cette phase
  ni d'une future sans nouvel arbitrage humain.
- **Toute manipulation sur un dépôt tiers** (Reviz/WillHosting, Scroll-Off) pour prouver le volet
  multi-humains — écartée (option B) ; si la preuve sur clone seul s'avère insuffisante pour ce
  volet, c'est un arbitrage distinct à remonter, jamais une compensation décidée en mission.

None — discussion stayed within phase scope pour le reste : les cinq arbitrages humains couvrent
l'intégralité des zones grises identifiées ; aucune zone grise résiduelle n'a nécessité de
nouvelle question (mandat de cadrage transmis avec les décisions déjà rendues par Samuel après
escalade du manager).

</deferred>

---

*Phase: 39-workstreams-partition-du-planning-et-collaboration-concurren*
*Context gathered: 2026-09-09*
