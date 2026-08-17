# CHANGELOG — content-bundle

## [v2.0.7] — 2026-08-17 (Phase 32, doctrine du verrou resynchronisée)

**Patch** (doctrine d'agent corrigée pour rester exacte, aucune nouvelle capacité).

- `vf-content-manager.md` : la doctrine du verrou s'arrêtait à `acquired:false → ne dispatche
  pas, remonte à l'humain` sans jamais nommer de marche à suivre sur un lock périmé. Ajout d'une
  distinction courte : `reason: held` (remontée inchangée) vs `reason: stale-requires-takeover`
  (exécuter `takeover --owner=<id> --step=<mission>` plutôt que de remonter). Renvoi à
  `conductor-references/team-kernel.md` pour la doctrine complète et la convention `Fence:`
  (LOCK-05).

## [v2.0.6] — 2026-08-10 (correctif #38 — `isolation: worktree` retiré du frontmatter)

**Retrait d'`isolation: worktree` du frontmatter des 3 agents du bundle.** Livrée en v2.49.0
(Phase 27), la ligne rendait ces workers inutilisable dès qu'un manager mandatait une branche autre
que la branche par défaut : le worktree du harness fork depuis la **branche par défaut**, jamais
depuis le HEAD courant — le worker atterrissait sur une branche technique **sans aucun fichier du
mandat**, se déclarait bloqué sans produire, et le manager se rabattait silencieusement sur un
agent générique dépourvu de sa doctrine et de ses allowlists.

La précondition qui corrige le fork — `worktree.baseRef: "head"` — vit dans le settings du poste
et **n'est posée nulle part par l'engine** : elle avait été posée dans le settings local du repo
de développement, et les agents ont été distribués sans elle. Même corrigée, elle ne suffirait
pas : rien ne ramène les commits du worker vers la branche de mission (`open-gsd/gsd-core#3302`).

L'isolation redevient ce que la doctrine du kernel dit déjà qu'elle est — une **décision de
dispatch du manager**, jamais une propriété du worker. Désormais machine-enforced :
`check-agents.sh` refuse `isolation:` dans un agent distribué.

Référence : issue #38.

## [v2.0.5] — 2026-08-10 (armement worktree du groupe A)

### Modifié
- **3 agents armés `isolation: worktree`** (Phase 27, groupe A) : `vf-content-repurposer`,
  `vf-content-strategist`, `vf-content-writer` — écritures isolées par worktree, mémoire d'agent
  embarquée via `.worktreeinclude`. Précondition de sûreté : `worktree.baseRef: "head"`.

## [v2.0.4] — 2026-08-04 (`effort:` par rôle sur les 5 agents, Phase 24)

### Modifié
- **Les 5 agents du bundle déclarent `effort:`** — `vf-content-manager` **high** et
  `content-clarity-judge` **high** (pilotage et jugement) ; `vf-content-strategist`,
  `vf-content-writer` et `vf-content-repurposer` **medium** (exécution). Barème par rôle repris des
  agents-templates de `plugin/reference/`, qui ont été **lus, jamais modifiés**.
- Motif : `check-agents.sh` **exige** désormais le champ (conductor v1.20.0) au lieu de le valider
  seulement quand il est présent — un agent sans `effort:` échoue le gate.

## [v2.0.3] — 2026-07-31 (barrière d'écriture réelle de `content-clarity-judge`, Phase 20)

### Corrigé
- **`content-clarity-judge` porte `disallowedTools: Write, Edit`** : la barrière d'écriture était
  une simple absence dans `tools:`, rouverte silencieusement au runtime par `memory: project`.
  Elle devient une contrainte posée par le frontmatter — le juge ne peut plus écrire son fichier
  de mémoire (il continue de le lire), cohérent avec l'exigence de regard frais.
- **`vf-content-manager` cite le mécanisme réel** (au lieu du seul adjectif « read-only ») pour
  justifier le dispatch parallèle de son juge.

Référence : `plugin/conductor/references/team-kernel.md` §Cloisonnement par tools,
`.planning/phases/VFDO-20-fluidit-du-flux-de-dev-sans-perte-de-qualit/`.

## [v2.0.2] — 2026-07-26

### Modifié
- `README.md` monté au standard de doc framework : tagline, en-tête `Type · Version · Dépend de`
  (l'en-tête **Version** est désormais déclaré — couvert par le gate `check-version-sync.sh`),
  sections Quoi / Installation / Démarrer / Usage / Référence / Limites.

## [v2.0.1] — 2026-07-26

### Corrigé
- `requires` += `conductor` (team-kernel, dépendance non déclarée).

## [v2.0.0] — 2026-07-25 — Matérialisation : de doc-only à module installable (team-kernel)

Bascule majeure : le bundle n'est plus un plan de fabrication (`doc-only`, `proposable: false`)
mais un **module installable** — la première équipe métier non-dev complète sur le team-kernel
(preuve d'universalité du framework, audit 2026-07-25).

### Ajouté
- **`agents/vf-content-manager.md`** (opus, memory: project) — manager de mission content sur le
  kernel : brief en langage naturel, lecture de `LIGNE-EDITORIALE`/`CALENDRIER`/registres,
  plan de bataille en DAG (5 nœuds par pièce : cadrage → rédaction → clarté → humain →
  déclinaison) + verrou de driver (`$S`), dispatch **parallèle** des pièces indépendantes
  (périmètres disjoints par construction), digest ≤30L par mandat, contrôle de flux sur
  rapports typés, halt conditions (5 codes P11). Définition du « vert » content : gate de
  clarté auto-contrôlé + score du juge ≥ 80/100 sans éliminatoire + **validation humaine
  explicite AVANT toute distribution** (ADR-031 — nœud `humain(p)` en `human_needed`, jamais
  auto-validé, aucun mode ne le contourne).
- **3 workers sonnet cloisonnés** (Pattern 12 : `vf-internal`, tools sans Task/Agent/Skill,
  périmètre d'écriture strict par étage) issus des blueprints, qui restent dans `content/`
  comme trace de conception :
  - `vf-content-strategist` (← strategist.blueprint) — fiche de cadrage : un angle unique
    justifié contre AUDIENCE/LIGNE, structure hook▸contexte▸mécanisme▸implication▸CTA,
    format confirmé. Écrit uniquement `pieces/<slug>/cadrage.md` + registres.
  - `vf-content-writer` (← scriptwriter.blueprint) — 3 hooks + livrable complet, aucune
    affirmation chiffrée non sourcée, auto-contrôle 4 critères. Écrit uniquement
    `pieces/<slug>/piece.md` + registres.
  - `vf-content-repurposer` (← repurposer.blueprint) — déclinaisons multi-plateformes d'une
    pièce VERTE uniquement (refus sinon), un CTA par variante, tient `editorial/CALENDRIER.md`.
    Ne publie jamais — la publication effective est remise à l'humain.
- **`agents/content-clarity-judge.md`** (sonnet, read-only : tools `Read, Glob, Grep`, sans
  Write/Edit) — le gate de clarté des blueprints matérialisé en **juge frais** : rubric /100
  explicite (chiffres sourcés 25 — éliminatoire —, jargon 15, take-away 15, ton 15, CTA unique
  10, fidélité au cadrage 10, gabarit 10), seuil 80, verdict typé avec findings cités.
- **`skills/vf-content/SKILL.md`** — point d'entrée du métier (« écris un post », « décline cet
  article », « prépare le calendrier », « lance la prod en autonomie ») : aiguillage geste
  simple (chaîne courte orchestrée depuis le skill) vs mission (`SEUIL_EQUIPE_CONTENT = 3`
  pièces ou signal de durée → `vf-content-manager`), garde first-use si `editorial/` absent.
- **`scripts/tests/test-content-bundle.sh`** — suite machine (12 tests) : agents présents +
  frontmatter, densité ADR-029, `check-agents.sh --strict` vert, juge sans Write/Edit,
  cloisonnement Pattern 12, manager sans périmètre de production, DIGEST + rapports typés,
  validation humaine non contournable (manager + repurposer + skill), aiguillage du skill,
  cohérence module.json/VERSION, encart de matérialisation, rubric du juge.

### Modifié
- `module.json` : type `doc-only` → `agents + skill + scripts` ; **`proposable: true`** (le
  module est réellement fini et vert — plus un WIP caché).
- `content/BUNDLE.md` : encart de matérialisation en tête — le document reste la trace de
  conception ; le réel vit dans `agents/` et `skills/`.
- `README.md` : réécrit pour refléter le module réel (équipe, chaîne, tests).

### Décisions de design
- Le « human-validator » des blueprints n'est **pas un agent** : c'est l'étape de validation
  humaine, orchestrée par le manager (statut `human_needed`) — conforme à la doctrine
  « la publication est TOUJOURS human-gated » (ADR-031).
- Le gate de clarté, couche d'audit dans les blueprints, devient un **juge read-only du
  kernel** (P8 : évaluation scorée par juge frais, machine-cloisonnée par les tools) — même
  esprit, forme kernel.
- Convention de production : une pièce = un dossier `pieces/<AAAA-MM-JJ>-<slug>/`
  (`cadrage.md` / `piece.md` / `variantes.md`), périmètres d'écriture disjoints par étage
  ET par pièce → dispatch parallèle sûr par construction.

## [v1.1.1] — 2026-07-25

### Corrigé
- Le gate `human-validator` est explicitement marqué « à fabriquer au ficelage du lab » (skill-creator + Gate C) au lieu d'être invoqué comme existant (F16).

## [v1.1.0] — 2026-07-16 (ADR-048 — orchestrateur métier)

### Modifié
- Doctrine d'orchestration réconciliée : un **orchestrateur métier** (`chef-editorial`, skill
  `metier-orchestration`) est posé d'office (≥2 spécialistes) ; le `conductor` redevient strictement méta.

## [v1.0.1] — 2026-07-05 (ADR-044)

### Corrigé
- BUNDLE.md : l'énumération d'instanciation inclut `description` (le frontmatter cible des
  blueprints l'avait, mais la consigne de recopie l'omettait — les agents sortaient muets).

## [v1.0.0] — 2026-06-11

### Création du bundle métier content (ContentFlow)

Premier bundle métier **doc-only** du plugin vibeflow-os. Il ne s'installe pas comme un agent
exécutable : il porte des **blueprints** que `vf-new-lab` (module `conductor`) lit et instancie en
agents natifs ≤250L dans le lab cible.

- **Manifeste** `content/BUNDLE.md` : métier (content / chaîne brief→livrable→distribution), profil
  de rigueur planning (**standard**), extension de domaine (**editorial/**), vocabulaire métier
  (campagne / pièce / angle / pilier / cadence), les 3 agents, modules recommandés et le flux
  d'instanciation lu par `vf-new-lab`.
- **3 blueprints d'agents** (`content/agents/`) prêts à instancier façon `business-agent`, chacun
  conçu pour s'instancier **≤250L** (savoir déporté en skills injectés via frontmatter `skills:`,
  jamais inliné — charte densité ADR-029) :
  - `strategist.blueprint.md` (sonnet) — stratège éditorial, cadre chaque pièce avant production.
  - `scriptwriter.blueprint.md` (sonnet) — rédacteur/idéateur, produit hooks + livrable.
  - `repurposer.blueprint.md` (sonnet) — repurposing/distribution multi-plateformes.
- **Spec d'extension** `content/domain/extension-spec.md` : structure exacte de `editorial/`
  (LIGNE-EDITORIALE / CALENDRIER / AUDIENCE / FORMATS / PILIERS) à scaffolder.
- **Registres** `content/registres.md` : les 5 registres canon (DECISIONS / LEARNINGS / BLOCKERS /
  JOURNAL / EVALS), convention d'IDs, ce que chaque agent capitalise, et le pont planning↔mémoire.

### Châssis doctrinal embarqué

- Principes Core **P1/P3/P4/P5/P7/P8/P9** référencés (jamais redupliqués — source : module
  `reference`, `VIBEFLOW_CORE.md`).
- Filet d'audit obligatoire câblé : agent `vibeflow-validator` (module `validator`) + skill
  `audit-architecture` (P8, verdict bloquant sur le générateur brief→output).
- Orchestration **déléguée** au module `conductor` (`vibeflow-conductor`) : le bundle ne re-code
  aucun orchestrateur ; les agents métier n'orchestrent pas.
- Décision de design tracée : **condensation 6 rôles → 3 agents** + le **gate de clarté** matérialisé
  comme couche `audit-architecture` (pas un agent) — à inscrire en DECISIONS du lab (cf. BUNDLE.md).

### Dépendances

`planning-core`, `consolidator`, `audit-architecture`, `validator`. Orchestration via `conductor`
(transitive — `vf-new-lab` est le point d'entrée).
