# Milestones — VibeFlow Dev Orchestrator (VFDO)

## 🚧 vf-routing — Routage fin & verbes VibeFlow (créé 2026-07-25)

**Statut :** ACTIF — 2 phases sur 3 livrées (12 ✅ `v2.31.0`, 14 ✅ `v2.30.0`) · **Spec :** `docs/superpowers/specs/2026-07-25-routage-fin-verbes-vf-design.md`

**Périmètre :** 3 phases · requirements VERB-01..05, BRDG-01..03, ALTI-01..05.

**But :** Deux trous constatés sur le module `dev-orchestrator` v1.7.0. **(1)** La table de routage de
l'agent mappe l'intention directement sur la cible GSD au lieu du verbe `/vf-*` correspondant — deux
sources de vérité par intention, et rien ne garantit qu'un verbe VibeFlow gagne l'arbitrage face aux 70
skills `gsd-*` chargés en parallèle. **(2)** 14 verbes couvrent 12 cibles : ~50 skills GSD n'ont aucune
porte d'entrée. La Phase 12 pose trois niveaux de routage (descriptions déclencheuses, rule de préséance
globale, doctrine exhaustive on-demand) et 19 verbes. La Phase 13 ferme le seul maillon non outillé du
cycle : `/vf-ingest`, qui transforme une spec en étapes de la feuille de route via les moteurs GSD
existants. La **Phase 14**, ajoutée en cours de milestone, traite un troisième trou découvert au passage :
`vf-planning` et la chaîne de développement produisaient les mêmes fichiers dans le même dossier avec des
frontmatters incompatibles — deux moteurs de planning concurrents (ADR-055, frontière d'altitude).

**Livré**

- **Phase 12** — release `v2.31.0`. 31 verbes dans `dev-orchestrator` (14 → 31), 2 dans
  `design-orchestrator`. Trois niveaux de routage : descriptions déclencheuses à contre-exemples croisés,
  rule globale de préséance (40 L), doctrine `intent-routing.md` couvrant 65/65 skills. `AGENT.md` ne cite
  plus aucune cible interne. Tests 25 OK / 0 KO / 1 SKIP.
  *Écart tracé* : le verbe prévu `vf-audit` s'appelle **`vf-gaps`** (collision avec la commande d'audit de
  conformité du lab). `VERB-02` reste **partiel** : 17/18 verbes, `vf-ingest` soldé en Phase 13.
- **Phase 14** — release `v2.30.0`, **ADR-055**. Un projet de code a un seul moteur de planning ;
  `planning-core` garde l'altitude lab, la mémoire et le socle des labs non-dev. planning-core v2.4.0.

**Prochaine action :** `/gsd:discuss-phase 13` puis `plan-phase` (pont `/vf-ingest`).

## 🚧 gsd-migration — Migration package GSD (créé 2026-07-25)

**Statut :** EN COURS — non planifié · **Requirement source :** VOC-02

**Périmètre :** 2 phases · requirements GSDM-01..06.

**But :** Basculer la dépendance GSD `get-shit-done-cc` → `@opengsd/gsd-core` sans casser l'auto-install,
l'index factuel ni le routage. On sépare **l'étude** (Phase 10 : surface d'impact, maturité du package
cible, note go/no-go) de **l'intégration** (Phase 11 : bascule outillée + non-régression isolée + release
taggée). **Phase 11 conditionnée au GO de la Phase 10** — un no-go documenté archive le chantier sans
toucher le code.

**Prochaine action :** `/gsd:discuss-phase 10` puis `plan-phase`.

## ✅ dev-doctrine — Doctrine dev & consolidation (2026-07-07)

**Tag git :** `v2.20.0` · **PR** #9 (mergée) · **Statut :** SHIPPED
**Spec :** `docs/superpowers/specs/2026-07-07-dev-doctrine-consolidation-design.md`

**Périmètre :** 2 phases · 6 plans · 12 requirements (PHIL-01..08, CONS-01..04) — **tous complétés**.

**Livré :** `software-architecture` v1.1.0 → **v1.3.0** (SOLID déjà là + DRY/KISS/YAGNI, Clean Archi/Clean
Code nommés, carte TDD, gates Nyquist+Decision Coverage absorbés). Module `feature-dev-gates`
**supprimé** + `cleanup_retired_modules` engine (convergence, test T7). `audit-architecture` **v1.0.1**
(Instance C dé-dupliquée, description legacy corrigée). `reference/AXIOMES-ENFORCEMENT.md` (source
unique des 3 axiomes). Invariant `dev-orchestrator` intact.

**Origine :** audit du parc de modules vs `dev-orchestrator` (`scratchpad/AUDIT-modules-vs-dev-orchestrator.md`) — constat : `dev-orchestrator` est un pur routeur sans doctrine ; les philosophies de dev (DRY absent, Clean Archi/Clean Code non nommés, TDD sans carte) et les doublons se concentrent dans le cluster qualité.

- **Phase 7 — Philosophies de dev** : enrichir `software-architecture` (DRY/KISS/YAGNI, nommer Clean Architecture + Clean Code, carte TDD → skill canonique, câblage Tier 2 honnête).
- **Phase 8 — Consolidation** : fusionner/déprécier `feature-dev-gates`, dé-dupliquer `audit-architecture`, factoriser les 3 axiomes. Invariant : `dev-orchestrator` reste un pur routeur.

---

## ✅ install-ux-v1.0 — Installation plugin + UX à toggles (2026-06-05)

**Tag git :** `install-ux-v1.0` · **Release repo** `v2.4.0` · **PR** #2 (mergée)

**Périmètre :** 5 phases (2-6) · 9 plans · 39 commits atomiques

### Livré
- **Plugin Claude Code** — `.claude-plugin/plugin.json` + `marketplace.json` : installation en **2 commandes** (`marketplace add picmakpro/vibeflow-os` + `install vibeflow`), **validé zéro-auth** sur repo public.
- **Auto-lancement** — hook `SessionStart` (`installer/hooks/`) qui ouvre l'UX `/vibeflow-install` au 1er lancement (marqueur `scripts/.vibeflow-installed`), silencieux ensuite.
- **Skill `/vibeflow-install`** — UX à toggles (scope user/project/local → modules), récap des dépendances auto-résolues, install scopée. Délègue à l'engine (zéro réimplémentation).
- **Engine scope-aware** — `vibeflow-update.sh` (`--scope`, `TARGET_ROOT`, clone git supprimé, `.gitignore` local) + `ensure-deps.sh` scopé (GSD `--global`/`--local`, Superpowers `--scope`). Rétro-compat préservée.
- **Manifeste & résolveur** — `module.json` ×8 + `resolve-deps.sh` (fermeture transitive des dépendances).
- **dev-orchestrator first-use** — garde-fou dans `AGENT.md` : détecte `.planning/` absent → propose l'init via `vf-init`.

### Requirements (17/17 complétés)
MANIF-01..02 · SCOPE-01..04 · INST-01..05 · PLUG-01..04 · FIRST-01..02

### Décisions clés
- Plugin embarque tout (modules = données bundlées, `${CLAUDE_PLUGIN_ROOT}` = cache) — pas de double-chargement.
- Un seul scope (user/project/local) appliqué à tout ; le skill passe toujours `VF_SCOPE` explicite (cohérence ID4).
- Repo rendu **public source-available** (LICENSE propriétaire conservée — flip fait par le mainteneur, droits admin).

### Process GSD (dogfooding)
brainstorm → spec → new-milestone → 5× (plan → **plan-check** → exécution → vérif). Le plan-check a attrapé de **vrais blockers** aux phases 3 / 4 / 5 (faux-négatif dry-run, marqueur cassé, hook cassé en contexte plugin) — tous corrigés avant exécution.

### Vérification runtime
Repo public confirmé · `marketplace add` + `install vibeflow` **zéro-auth OK** (puis env de dev nettoyé) · tests isolés (vrai `~/.claude` jamais touché) · scan secrets CLEAN.

## ✅ vfdo-v1.0 — Module dev-orchestrator (2026-06-04)

**Tag git :** `vfdo-v1.0` · **Embarqué dans la release repo** `v2.3.0`

**Périmètre :** 1 phase · 5 plans · ~10 tasks + 1 incrément (`vf-map`) · 18 commits atomiques

### Livré
- **Agent routeur `vibeflow-dev`** (`AGENT.md`, 125L) — routage langage naturel → bon skill GSD/Superpowers, 14 cibles distinctes, ne nomme jamais « GSD », reframe en vocabulaire VibeFlow.
- **Index factuel auto-généré** — `build-gsd-index.sh` → `gsd-skills-index.md` (65-66 skills GSD réels, zéro hallucination, régénéré à l'install via `VF_INDEX_OUT`).
- **13 verbes `/vf-*`** — thin delegators construits via `writing-skills` (dont `vf-init` bootstrap, `vf-map` cartographie, `vf-auto` autonome), + `vocabulary-map.md`.
- **Bootstrap auto-install** — `ensure-deps.sh` : GSD + Superpowers non-interactif, idempotent, fallback manuel ; `gsd-new-project` jamais lancé seul (BOOT-04).
- **Intégration installeur (D7)** — `vibeflow-update.sh` copie les references d'un module agent sous `.claude/agents/<mod>-references/` + hook post-install régénérant l'index.
- **Tests** — `test-dev-orchestrator.sh` (4 axes + densité `wc -l`), portable source ↔ lab installé. 7/7 repo, 6/6+1 SKIP lab.

### Requirements (14/14 complétés)
ROUT-01..04 · IDX-01..02 · ABS-01..02 · BOOT-01..04 · VERIF-01..02

### Process GSD (dogfooding)
brainstorm → spec → init → plan (5) → **plan-check ❌ 3 blockers** → révision → **plan-check ✅** → execute (4 waves) → **verify goal-backward** → fix → incrément `vf-map` (v1.1.0) → runtime test (lab) → clôture.

### Vérification runtime
Routage NL confirmé en session par l'utilisateur · install lab end-to-end OK · bootstrap idempotent OK.

### Reporté (v2)
- VOC-01 : traduction exhaustive des artefacts GSD.
- VOC-02 : migration package `get-shit-done-cc` → `@opengsd/gsd-core`.
