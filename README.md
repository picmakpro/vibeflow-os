# vibeflow-os

> **Modules VibeFlow distribués aux labs** — repo central versionné pour réplication méthodologique.
> Public (source-available, licence propriétaire). Maintenu par [@picmakpro](https://github.com/picmakpro).

---

## Quoi

Ce repo héberge les **modules réutilisables** de la méthodologie VibeFlow, distribués via un script `vibeflow-update.sh` installé dans chaque lab branché.

## Modules

| Module | Version | Type | Description |
|--------|---------|------|-------------|
| [`consolidator/`](./consolidator/) | v1.0.0 | single-skill + scripts | Consolidation mémoire 4 piliers (Indexation / Archivage / Fusion / Promotion) — ADR-032 |
| [`infrastructure-audit/`](./infrastructure-audit/) | v1.0.0 | single-skill + scripts | Audit automatique infrastructure (hooks, scripts, drift Anthropic) — détecte régressions après update Claude Code |
| [`validator/`](./validator/) | v1.1.0 | agent-only | Agent `vibeflow-validator` (garant alignement technique méthodo ↔ labs) — 5 phases dont audit architecture des process |
| [`skill-creator/`](./skill-creator/) | v1.0.0 | agent + 2 skills | Pattern "agent minimal + 2 skills composables" (Anthropic + workflow) — LRN-101 |
| [`reference/`](./reference/) | v2.1.1 | doc-only | Documentation méthodologique complète (VIBEFLOW_CORE **v4.2 — 9 principes, +P9** + pointeur P8↔audit-architecture + 11 patterns + 33 templates + 1 exemple) |
| [`software-architecture/`](./software-architecture/) | v1.0.0 | single-skill + rules + scripts | Doctrine Architecture Logicielle AI-Safe (SOLID/SoC, anti-god-files ≤300L, gates machine-enforced, playbook restructuration brownfield) — ADR-035 |
| [`audit-architecture/`](./audit-architecture/) | v1.0.0 | single-skill + references | Concepteur d'**architecture d'audit** : dérive depuis un brief la structure d'audit multi-couches d'un process et la force (universel : contenu / dossier / code / vente). Spécialise P8 — ADR-036 |
| [`dev-orchestrator/`](./dev-orchestrator/) | v1.1.0 | agent + skills + scripts | Orchestrateur de développement (VFDO) : agent routeur `vibeflow-dev` + 13 verbes `/vf-*` + index GSD auto-généré. Route le **langage naturel** vers les skills GSD/Superpowers (cadrage → livraison) sans exposer la plomberie — références D7 sous `.claude/agents/dev-orchestrator-references/` |

## Types de modules supportés (depuis v2.0.0)

| Type | Structure module | Cible installation |
|------|------------------|---------------------|
| **single-skill** | `<mod>/SKILL.md` + optionnel `references/`, `scripts/` | `.claude/skills/<mod>/` + `.claude/scripts/` |
| **multi-skills** | `<mod>/skills/<name>/SKILL.md` (multiple) | `.claude/skills/<name>/` (chaque skill séparément) |
| **agent-only** | `<mod>/AGENT.md` | `.claude/agents/<mod>.md` |
| **doc-only** | `<mod>/content/` | `docs/<mod>/` |
| **rules** | `<mod>/rules/*.md` | `.claude/rules/` (rules path-scopées auto-chargées) |

Les types sont composables (ex: `skill-creator` = agent + multi-skills ; `software-architecture` = skill + rules + scripts).

Chaque module a obligatoirement : `VERSION` (semver), `CHANGELOG.md`, `README.md`.

---

## Installation

VibeFlow s'installe comme **plugin Claude Code**, en deux commandes :

```bash
claude plugin marketplace add picmakpro/vibeflow-os
claude plugin install vibeflow
```

Aucun clone, aucun script à lancer, aucune édition de `settings.json`.

### Auto-lancement (1er lancement)

À la **session suivante** (charger un plugin = restart de Claude Code), le hook `SessionStart`
détecte le 1er lancement — le marqueur `scripts/.vibeflow-installed` est absent — et **ouvre
automatiquement** l'UX `/vibeflow-install` :

- **Toggle scope** (single-select) : compte (`user`) / projet (`project`) / projet sans commit (`local`).
- **Toggle modules** (multi-select) : la liste sort du catalogue (chaque module + sa description).
- **Dépendances auto-résolues** : la fermeture transitive des `requires` est calculée et récapitulée
  avant toute install.

Une fois VibeFlow installé, ce message ne réapparaît plus.

### Re-configurer / ajouter un module

`/vibeflow-install` reste invocable à la main à tout moment pour changer de scope, ajouter ou
retirer un module (les dépendances sont re-résolues automatiquement).

### Mise à jour

```bash
claude plugin update vibeflow
```

Voir [INSTALL.md](./INSTALL.md) pour les détails (désinstallation, troubleshooting).

---

## Convention versioning

- **Semver** : `vMAJOR.MINOR.PATCH`
- **MAJOR** : breaking change (convention frontmatter, format registre, structure module)
- **MINOR** : nouveau module ou nouvelle capacité majeure
- **PATCH** : bugfix scripts ou amélioration doc

Chaque module a sa propre version. Le repo global est tagué à la version du dernier changement majeur.

### Historique versions repo

| Version | Date | Changement |
|---------|------|------------|
| v1.0.0 | 2026-05-23 | Initial release : consolidator |
| v1.1.0 | 2026-05-24 | + infrastructure-audit |
| v1.2.0 | 2026-05-24 | + validator (agent-only) |
| v1.2.1 | 2026-05-24 | Fix vibeflow-update.sh handle AGENT.md |
| **v2.0.0** | 2026-05-24 | **+ skill-creator (multi-skills), + reference (doc-only), nouveau type module supporté** |
| **v2.1.0** | 2026-05-28 | **+ software-architecture (skill+rules+scripts), + type distribuable `rules/` dans l'installer, Core v4.2 (ajout P9), reference v2.1.0** |
| **v2.2.0** | 2026-06-03 | **+ audit-architecture (méta-skill concepteur de structures d'audit multi-couches), validator v1.1.0 (Phase 4 scan des process) — ADR-036** |
| **v2.3.0** | 2026-06-04 | **+ dev-orchestrator (agent routeur VibeFlow → GSD + Superpowers, 13 verbes `/vf-*`, index auto) — milestone vfdo-v1.0** |
| **v2.4.0** | 2026-06-05 | **Installation en 2 commandes : plugin Claude Code + skill `/vibeflow-install` à toggles (scope user/project/local), auto-lancement, manifeste de dépendances — milestone install-ux-v1.0** |

---

## Sécurité

- Repo public **source-available** : code et historique visibles, licence propriétaire « All rights reserved » (aucun droit de réutilisation accordé)
- Scripts shell + Python uniquement (auditables ligne par ligne)
- Pas de dépendances tierces non vérifiées
- Tests automatisés pour chaque script (`scripts/tests/test-*.sh`)
- skill-creator (Anthropic) sous licence MIT, contenu Anthropic original conservé

---

## Gouvernance

- ADR doit accompagner toute modification structurante (côté Lab VibeFlow)
- Modifications testées dans le Lab VibeFlow (cobaye) avant release
- Tag GitHub Release = changelog officiel
- Cycle de release rapide (multiple releases par session quand justifié)

---

## Références

- [VibeFlow Lab](https://github.com/picmakpro/vibeflow-lab) (privé) — Lab principal
- ADR-029 : Charte de densité agents
- ADR-031 : Garde-fou support runtime
- ADR-032 : Système de Consolidation Mémoire 4 piliers
- ADR-033 : Création repo vibeflow-os (Session 047)
- ADR-035 : Doctrine Architecture Logicielle AI-Safe — module software-architecture + P9 Core (Session 049)
- ADR-036 : Doctrine Audit Architecture — module audit-architecture + validator Phase 4 (Session 050)
- LRN-101 : Pattern "agent minimal + 2 skills composables"
- LRN-106 : Audit avant fix
- LRN-107 : Repo central versionné > zip ad-hoc
