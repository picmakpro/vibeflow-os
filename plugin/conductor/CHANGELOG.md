# Changelog — conductor

## v1.3.0 — 2026-06-24

`vf-new-lab` évolue en **Lab Factory clarification-first** (pipeline 7 phases). L'init ne pose plus un
squelette : elle clarifie en profondeur (gate machine-enforced), dérive un manifeste de capacités, et
**fabrique** les skills + auditeurs. Rétrocompatible (toujours invocable « crée un lab »), profondeur
adaptative au profil.

### Ajouté
- **Clarification-first** : Phase Triage (greenfield/brownfield + profil adaptatif) → Scan brownfield
  (explorer) → élicitation section par section avec **menu numéroté** (pattern BMAD) → **Gate A**
  (`[À CLARIFIER]` bloquant sur `LAB_BRIEF.md`). Refs `elicitation-methods.md` + `completeness-gate.md`.
- **T2 — Manifeste de capacités** : dérive les capacités (savoir/compétence/procédure), **Gate B**
  (justification obligatoire), proportionnalité au profil. Ref `capability-manifest.md` +
  `scripts/proportion-capabilities.sh` (tests 9/9).
- **T3 — Fan-out skill-creator** : fabrication parallèle (N × skill-creator, un par capacité P0) +
  anti-slop (gate capacité + eval par skill + critique de complétude). Ref `skill-fanout.md`.
- **T4 — Ficelage auditeurs** : un auditeur par procédure générative via `audit-architecture` (verdict
  bloquant). Ref `procedure-audit-wiring.md`.
- **T5 — Assemblage** : agents câblés sur les skills fabriqués, planning v2 compartiments, 5 registres
  (dont EVALS), garde-fous, stamp. Récap adaptatif (pédagogique en mode découverte).

## v1.2.0 — 2026-06-23

Câblage de la **topologie à compartiments** (planning-core v2.0.0) dans l'init, l'update et le pipeline.

### Ajouté / Modifié
- `vf-new-lab` : étape de dérivation « topologie du lab » (mono-objectif vs compartiments) + typage
  `deliverable`/`continuous`/infra + seuil d'autonomie ; scaffolding *steering lab + INDEX + plan par
  compartiment qualifié*. Garde-fou « jamais un `.planning/` par compartiment systématique ».
- `vf-calibrate` : cas **planning v2** (breaking-doctrine) routé vers la recette de migration sans perte.
- `references/migration-playbook.md` : recette **§2bis migration planning v2 sans perte de données**
  (détection de dette → typage → récupération de l'existant en `_archive/` → désengorgement mémoire → INDEX).
- `references/conductor-pipeline.md` : étape compartiments + garde-fou transverse.

## v1.1.0 — 2026-06-11

`vf-new-lab` rendu **bundle-aware** + correction d'un pointeur cassé.

### Corrigé
- Pointeur cassé : `vf-new-lab` référençait `references/bootstrap-method.md` (introuvable au runtime
  car le skill et les references s'installent à des emplacements distincts) → pointe désormais vers
  `.claude/agents/conductor-references/bootstrap-method.md` (emplacement réel d'install).

### Ajouté
- Mode bundle métier : si un bundle est installé (`docs/<metier>-bundle/`), `vf-new-lab` lit son
  `content/BUNDLE.md` et **instancie** les blueprints `content/agents/*.blueprint.md` au lieu de
  dériver de zéro — le châssis conforme est déjà porté par le bundle. Compatible business-pilot /
  content / growth.

## v1.0.0 — 2026-06-11

Release initiale. Agent méta orchestrateur central + gardien du framework, distribué dans chaque lab.
Comble 4 trous identifiés à l'audit du plugin (cf. README).

### Ajouté
- **Agent `vibeflow-conductor`** (AGENT.md, ≤250L) — porte d'entrée méta pour configurer/vérifier/
  mettre à jour/migrer un lab. Route et délègue (installeur, validator, planning-core, consolidator).
  4 rôles : configurateur / vérificateur / calibreur / gardien. N'est pas appelé en continu.
- **C2 — `vf-new-lab`** : bootstrap de lab **universel** (non-dev en première classe). Cadrage 5
  questions (ce que l'utilisateur sait déjà) → dérivation → scaffolding adapté au métier. Exemple
  « acquisition » de bout en bout. Ne présume jamais dev.
- **C3 — `vf-calibrate`** + `scripts/framework-version.sh` : propagation d'update façon GSD.
  Détection de drift framework ↔ lab (current/recorded/stamp/drift, sémver portable), migration sous
  validation humaine, surfaçage SessionStart **opt-in**. + tests (8/8 PASS).
- **C4 — `references/contracts.md`** : protocole d'escalade sous-agents → conductor (gardien central).
- Références on-demand : `conductor-pipeline.md`, `migration-playbook.md`, `bootstrap-method.md`.

### Notes
- `type: agent + skills + scripts + references`. `requires: [planning-core, validator]`.
- Respecte ADR-031 (détecter/proposer, jamais corriger/migrer sans validation humaine), ADR-029
  (densité), ADR-030 (skills natifs, déléguer sans réimplémenter).
- Ne fait JAMAIS le travail métier — il configure et garde le lab.
