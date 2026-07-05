# BUNDLE — ContentFlow (métier *content*)

> **Manifeste de bundle métier.** Document lu par `vf-new-lab` (module `conductor`) pour instancier un
> lab de **création de contenu** complet et gouverné — chaîne **brief → livrable → distribution** —
> sans aucune hypothèse dev, avec son filet d'audit.
>
> Ce fichier est la **source de vérité** du bundle : il déclare le métier, le profil de rigueur, le
> nom de l'extension de domaine, le vocabulaire natif, les 3 agents, les modules recommandés, et le
> **flux d'instanciation** exact que `vf-new-lab` doit dérouler.

---

## 1. Métier

**Content / création de contenu (ContentFlow)** — production récurrente de contenu éditorial :
newsletters, posts LinkedIn, threads, scripts vidéo courts, carrousels. Le lab matérialise la
**chaîne éditoriale** complète :

```
BRIEF ──▶ [strategist] cadre l'angle ──▶ [scriptwriter] produit le livrable
       ──▶ [GATE CLARTÉ : audit-architecture] ──▶ [validation humaine]
       ──▶ [repurposer] décline & distribue multi-plateformes
```

Le métier produit des **pièces** rattachées à des **campagnes**, alignées sur des **piliers**
éditoriaux, tenues à une **cadence**, et chacune portée par un **angle** unique.

## 2. Profil de rigueur planning

**Profil : `standard`** (cf. `planning-core` → `PROFILES.md`).

Justification : le travail est réellement découpé en étapes (campagnes), avec des exigences à tracer
(ligne, cadence, CTA) et des livrables à suivre — mais sans l'enjeu architecture/code qui justifierait
le profil *complet*. Mapping métier→profil de `planning-core` : *contenu/éditorial → standard*.

Artefacts `.planning/` posés (profil standard) : `STATE.md` (clé de voûte), `PROJECT.md`,
`ROADMAP.md`, `REQUIREMENTS.md`, `MILESTONES.md`, `config.json`, arbo `phases/NN/` (PLAN + SUMMARY),
et l'extension de domaine `editorial/`.

## 3. Extension de domaine

**Nom : `editorial/`** (à la place de `codebase/` — le métier n'est PAS le code).

Structure exacte à scaffolder : voir `domain/extension-spec.md`. Résumé : `LIGNE-EDITORIALE.md`,
`CALENDRIER.md`, `AUDIENCE.md`, `FORMATS.md`, `PILIERS.md`.

## 4. Vocabulaire métier (natif — P7 Transposer, pas copier)

Le lab parle le métier, jamais le jargon dev. Les agents et les artefacts emploient ces termes :

| Terme | Sens dans le lab |
|---|---|
| **campagne** | regroupement de pièces autour d'un objectif éditorial daté (≈ « jalon/étape ») |
| **pièce** | une unité de contenu livrable (post, newsletter, thread, script, carrousel) |
| **angle** | la prise de vue unique d'une pièce — ce qui la rend pertinente pour l'audience |
| **pilier** | un thème porteur récurrent de la ligne éditoriale, qui structure la production |
| **cadence** | le rythme de publication tenu (ex. 1 newsletter + 3 posts / semaine) |

> Conformément à **P7**, ce vocabulaire remplace tout terme importé : « campagne » et non « sprint »,
> « pièce » et non « commit ». `vf-new-lab` doit instancier les agents et artefacts dans ce langage.

## 5. Les 3 agents métier

Tous **`model: sonnet`**, `memory: project`, conçus pour s'instancier **≤250L** (charte **ADR-029** :
savoir déporté en skills via frontmatter `skills:`, jamais inliné). Blueprints complets dans
`agents/`.

| Agent | Rôle (1 ligne) | Modèle | Blueprint |
|---|---|---|---|
| **strategist** | Stratège éditorial : arbitre l'angle, garde la ligne, cadre chaque pièce AVANT production. | sonnet | `agents/strategist.blueprint.md` |
| **scriptwriter** | Rédacteur/idéateur : produit 3 hooks puis rédige le livrable complet selon l'angle validé. | sonnet | `agents/scriptwriter.blueprint.md` |
| **repurposer** | Repurposing/distribution : décline une pièce validée en variantes multi-plateformes. | sonnet | `agents/repurposer.blueprint.md` |

Aucun de ces agents n'orchestre (P3) et aucun ne code, jamais. L'orchestration est **déléguée au
module `conductor`** (`vibeflow-conductor`). Les agents escaladent au conductor hors de leur scope.

## 6. Modules recommandés

| Module | Rôle dans ce lab |
|---|---|
| `planning-core` | socle `.planning/` (profil standard + extension `editorial/`) |
| `consolidator` | consolidation mémoire 4 piliers ; promotion `PROJECT.D-NN` → DECISIONS |
| `audit-architecture` | **gate de clarté** bloquant sur le générateur brief→output (P8) |
| `validator` | agent `vibeflow-validator` — filet de cohérence/conformité (5 phases) |
| `conductor` | orchestration + `vf-new-lab` (point d'entrée d'instanciation) |
| `reference` | source canonique des principes Core + registres (si présent) |

**Pas de `dev-orchestrator`** : le métier n'est pas le code.

## 7. Spécificités métier à matérialiser (NON négociables)

- **Gate de clarté BLOQUANT** *avant* la validation humaine — c'est une **couche
  `audit-architecture`**, **PAS un agent**. Critères de verdict (tous requis) :
  1. **Aucun chiffre non sourcé** (toute donnée chiffrée → source primaire citée).
  2. **Aucun jargon non expliqué** à sa 1re occurrence.
  3. **Take-away actionnable** présent (le lecteur sait quoi faire/penser).
  4. **Ton non-alarmiste** (pas de peur ni de superlatif gratuit).
  → Verdict `BLOQUANT` : une pièce qui échoue ne passe pas à l'étape humaine. (Voir `registres.md`
  pour la capitalisation des verdicts en EVALS.)
- **Étape `human-validator` NON négociable** *avant publication* : aucune pièce n'est distribuée sans
  validation humaine explicite. Le `repurposer` ne déclenche aucune distribution sensible en autonomie.
- **Sourcing gouverné** : seules les sources **tier-1 autorisées** (listées dans
  `editorial/LIGNE-EDITORIALE.md`) sont citables ; toute citation chiffrée renvoie à sa **source
  primaire** ; les sources interdites sont bannies.
- **Décision de design à tracer en DECISIONS du lab** : ce bundle **condense 6 rôles éditoriaux en
  3 agents**, et matérialise le **gate de clarté comme couche audit (pas comme agent)**. `vf-new-lab`
  doit inscrire cette décision en `DECISIONS` (1 entrée, ID `DEC-001` ou suivant) à l'instanciation.

## 8. Châssis Core référencé (jamais redupliqué)

Source canonique : module `reference` (`VIBEFLOW_CORE.md`). Le lab applique :

- **P1 Capitaliser** — chaque agent alimente DECISIONS/LEARNINGS/BLOCKERS/EVALS (cf. `registres.md`).
- **P3 Orchestrer** — l'orchestrateur (`conductor`) ne produit jamais ; les agents métier
  n'orchestrent pas.
- **P4 Clarifier avant d'exécuter** — `strategist` cadre l'angle AVANT toute production ;
  `scriptwriter` retourne au gate clarté.
- **P5 Vérifier en boucle** — gate de clarté + validation humaine ; rien ne passe sans vérification.
- **P7 Transposer pas copier** — vocabulaire métier natif (§4), zéro forme dev.
- **P8 Évaluer** — `audit-architecture` matérialise le gate de clarté (verdict bloquant) ; verdicts en
  EVALS.
- **P9 Modulariser** — chaque agent ≤250L, une responsabilité par agent, savoir en skills injectés.

---

## 9. FLUX D'INSTANCIATION (lu et exécuté par `vf-new-lab`)

> `vf-new-lab` lit ce manifeste et déroule la séquence ci-dessous. Chaque étape **délègue** à un
> module ; le bundle n'exécute rien lui-même (doc-only).

### Étape 0 — Confirmer le métier
Le métier *content* est déclaré ici (§1). `vf-new-lab` confirme en une ligne (pas de re-cadrage si
l'utilisateur a déjà dit « lab de contenu »).

### Étape 1 — Poser la constitution du lab
Écrire `CLAUDE.md` du lab (WHY/WHAT/HOW) en vocabulaire métier (§4) : studio éditorial, chaîne
brief→livrable→distribution, ligne éditoriale tenue, sourcing gouverné.

### Étape 2 — Installer les modules
Déléguer à l'installeur la sélection §6 : `planning-core` + `consolidator` + `audit-architecture` +
`validator` (+ `conductor` déjà présent comme point d'entrée). **Jamais `dev-orchestrator`.**

### Étape 3 — Poser le socle planning
Déléguer à `planning-core` (`vf-planning`) :
- profil **standard** (§2) ;
- artefacts `.planning/` dont **`STATE.md` = clé de voûte obligatoire** + `PROJECT.md` + `ROADMAP.md`
  + `REQUIREMENTS.md` + `MILESTONES.md` + `config.json` ;
- **extension `editorial/`** scaffoldée selon `domain/extension-spec.md` (§3).
ROADMAP exprimée en **campagnes**, REQUIREMENTS en exigences éditoriales (ton, cadence, CTA, sourcing).

### Étape 4 — Poser les 5 registres mémoire
Selon `registres.md` : `DECISIONS.md`, `LEARNINGS.md`, `BLOCKERS.md`, `JOURNAL.md`, `EVALS.md`
(depuis `reference` si installé). Chacun **commence par un index tableau**.

### Étape 5 — Instancier les 3 agents (≤250L chacun)
Pour chaque blueprint de `agents/` :
1. Lire le frontmatter cible (name, description, model, memory:project, skills:[...]) — les recopier TOUS (gate `check-agents.sh`, ADR-044).
2. Créer l'agent natif dans `.claude/agents/<name>.md` du lab, **≤250L** (passer
   `agent-density-auditor` en gate si disponible).
3. Si un skill déclaré n'existe pas encore, le **créer via `skill-creator`** (ne PAS inliner le savoir
   dans l'agent — ADR-029). Les skills déclarés par les blueprints sont à créer, pas fournis ici.

### Étape 6 — Câbler le filet d'audit (« pas de lab sans filet »)
- Câbler l'agent **`vibeflow-validator`** (module `validator`).
- Câbler le skill **`audit-architecture`** comme **gate de clarté bloquant** sur le générateur
  brief→output (entre `scriptwriter` et la validation humaine), avec les 4 critères du §7.

### Étape 7 — Tracer la décision de design du bundle
Inscrire en `DECISIONS` la condensation **6 rôles → 3 agents** + le **gate clarté = couche
audit (pas un agent)** (cf. §7). Une seule entrée, pointeur depuis `PROJECT.md` (D-NN → DEC-NNN).

### Étape 8 — Stamper la version framework
Lancer `framework-version.sh stamp` (module `conductor`) dans le lab pour permettre la détection
d'update ultérieure.

### Étape 9 — Récapituler
Montrer l'arbo posée, les 3 agents créés, l'extension `editorial/`, le filet câblé, et **la première
action métier** en vocabulaire du lab (ex. « cadre l'angle de ta première pièce avec le strategist »).

---

## 10. Pont planning ↔ mémoire (propriétaire unique)

Voir `registres.md` et `planning-core/bridge-memory.md`. Règle d'or : **une info ne vit qu'à un seul
endroit**. Décisions courantes en `PROJECT.md` (`D-NN`) → **promues** en `DECISIONS` (`DEC-NNN`) si
structurantes ; `STATE.md` → `JOURNAL` à la clôture de session ; jamais de doublon.
