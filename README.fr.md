<div align="center">

# VibeFlow OS

[English](./README.md) · **Français**

**Transforme Claude Code en orchestrateur de développement piloté au langage naturel.**

Dis _« aide-moi à dev cette feature »_ — et tout le pipeline se déclenche : cadrage → plan → exécution → tests → livraison. Sans jamais taper une commande technique ni savoir ce qui tourne en coulisse.

[![Version](https://img.shields.io/badge/version-2.5.0-2563eb)](./VERSION)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-d97757)](https://docs.claude.com/en/docs/claude-code)
[![Modules](https://img.shields.io/badge/modules-9-16a34a)](#-modules)
[![License](https://img.shields.io/badge/license-source--available-64748b)](./LICENSE)

[Installation](#-installation) · [Modules](#-modules) · [Comment ça marche](#-comment-ça-marche) · [Auteur](#-auteur)

</div>

---

## ✨ C'est quoi

**VibeFlow OS** est le repo de distribution de **VibeFlow** — une méthodologie de développement assisté par IA, packagée en **plugin Claude Code** à modules activables.

Tu n'apprends pas une nouvelle CLI. Tu parles normalement. Un **agent routeur** comprend ton intention et l'envoie vers le bon outil (GSD, Superpowers, audits…) en reformulant tout dans un vocabulaire VibeFlow cohérent. La plomberie reste invisible.

```text
Toi  ›  aide-moi à ajouter l'auth Google
        VibeFlow déroule : cadrage → feuille de route → sprint → tests
        ↳ aucun /gsd-*, aucun /sp-* à connaître

Toi  ›  on est où ?
        VibeFlow : rapport de sprint + prochaine étape

Toi  ›  débugge ce crash
        VibeFlow : débogage systématique, état persistant entre les resets
```

Au-delà de l'orchestration dev, VibeFlow embarque des modules de **gouvernance** : audit d'architecture logicielle, audit d'infrastructure, consolidation de mémoire, validation d'alignement méthodologique — chacun activable à la carte.

---

## 🚀 Installation

VibeFlow s'installe comme **plugin Claude Code**, en deux commandes — aucun clone, aucun script, aucune édition de `settings.json` :

```bash
claude plugin marketplace add picmakpro/vibeflow-os
claude plugin install vibeflow
```

Puis, **dans Claude Code**, lance l'UX de configuration quand tu veux :

```
/vibeflow-install
```

L'UX déroule :

| Étape | Ce qui se passe |
|-------|-----------------|
| **Scope** | Choisis où installer : compte (`user`), projet (`project`), ou projet sans commit (`local`). |
| **Modules** | Sélectionne les modules à activer — la liste sort du catalogue, chacun avec sa description. |
| **Dépendances** | La fermeture transitive des `requires` est calculée et récapitulée **avant** toute install. |

> Le lancement est **100 % manuel** : VibeFlow ne s'ouvre jamais tout seul au démarrage de session. Tape `/vibeflow-install` pour installer ou re-configurer (changer de scope, ajouter/retirer un module — les dépendances sont re-résolues à chaque passage).

**Mise à jour :** `claude plugin update vibeflow` · **Détails / troubleshooting :** [INSTALL.md](./INSTALL.md)

---

## 📦 Modules

9 modules activables indépendamment. Chacun a sa propre version, son `CHANGELOG.md` et son `README.md`.

| Module | Ver. | Type | Ce qu'il fait |
|--------|:----:|------|---------------|
| **[dev-orchestrator](./plugin/dev-orchestrator/)** | `1.1.0` | agent + skills + scripts | ⭐ Le cœur. Agent routeur `vibeflow-dev` + 13 verbes `/vf-*` + index GSD auto-généré. Route le **langage naturel** vers les skills GSD/Superpowers (cadrage → livraison), sans exposer la plomberie. |
| **[software-architecture](./plugin/software-architecture/)** | `1.0.0` | skill + rules + scripts | Doctrine d'architecture logicielle AI-Safe : SOLID/SoC, anti-god-files (≤300 L), gates *machine-enforced*, playbook de restructuration brownfield. |
| **[audit-architecture](./plugin/audit-architecture/)** | `1.0.0` | skill + references | Concepteur d'**architecture d'audit** : dérive depuis un brief la structure d'audit multi-couches d'un process (contenu / dossier / code / vente). |
| **[infrastructure-audit](./plugin/infrastructure-audit/)** | `1.0.0` | skill + scripts | Audit automatique de l'infra Claude Code (hooks, scripts, drift Anthropic) — détecte les régressions après une mise à jour. |
| **[validator](./plugin/validator/)** | `1.1.0` | agent-only | Agent `vibeflow-validator` : garant de l'alignement technique méthodo ↔ projets, en 5 phases (dont audit d'architecture des process). |
| **[consolidator](./plugin/consolidator/)** | `1.0.0` | skill + scripts | Consolidation de la mémoire structurée sur 4 piliers : indexation / archivage / fusion / promotion. |
| **[skill-creator](./plugin/skill-creator/)** | `1.0.0` | agent + skills | Pattern « agent minimal + 2 skills composables » pour créer de nouveaux skills (base Anthropic + workflow). |
| **[reference](./plugin/reference/)** | `2.1.1` | doc-only | Documentation méthodologique complète : VibeFlow Core (9 principes) + 11 patterns + 33 templates + 1 exemple de bout en bout. |
| **[planning-core](./plugin/planning-core/)** | `1.0.0` | skill + references | Socle de planning & documentation universel : pose le tronc commun `.planning/` (PROJECT/STATE/ROADMAP/REQUIREMENTS/MILESTONES/phases), **adapté à la logique métier de chaque lab** — jamais imposé. La couche avant/présent, complémentaire des registres mémoire. |

---

## 🛠 Comment ça marche

### Une UX, plusieurs scopes

L'installeur pose chaque module à l'endroit attendu par Claude Code selon son type :

| Type de module | Structure | Cible d'installation |
|----------------|-----------|----------------------|
| **single-skill** | `<mod>/SKILL.md` (+ `references/`, `scripts/`) | `.claude/skills/<mod>/` |
| **multi-skills** | `<mod>/skills/<name>/SKILL.md` | `.claude/skills/<name>/` (chacun) |
| **agent-only** | `<mod>/AGENT.md` | `.claude/agents/<mod>.md` |
| **doc-only** | `<mod>/content/` | `docs/<mod>/` |
| **rules** | `<mod>/rules/*.md` | `.claude/rules/` (path-scopées, auto-chargées) |

Les types sont **composables** : `dev-orchestrator` = agent + skills + scripts ; `software-architecture` = skill + rules + scripts.

### Anti-hallucination par design

Le routage repose sur un **index factuel auto-généré** depuis le frontmatter des skills présents sur disque — jamais écrit à la main. L'agent ne peut pas inventer un nom de commande qui n'existe pas.

---

## 🔒 Sécurité

- **Source-available** : code et historique publics, licence propriétaire (« All rights reserved », aucun droit de réutilisation accordé).
- **Scripts shell + Python uniquement** — auditables ligne par ligne, aucune dépendance tierce non vérifiée.
- **Idempotent** : chaque script d'install est ré-exécutable sans casser l'installation, avec backup automatique avant écrasement.
- **Zéro hook** : le plugin n'enregistre rien au démarrage de session. Tout part de ton invocation manuelle.
- **Tests** : chaque script est couvert (`scripts/tests/test-*.sh`).

---

## 🧭 Versioning & gouvernance

**Semver** par module (`vMAJOR.MINOR.PATCH`) — MAJOR = breaking change, MINOR = nouveau module/capacité, PATCH = bugfix ou doc. Le repo global est tagué à la version du dernier changement majeur. Chaque release GitHub = changelog officiel.

<details>
<summary><strong>Historique des versions du repo</strong></summary>

| Version | Date | Changement |
|---------|------|------------|
| `v1.0.0` | 2026-05-23 | Initial release : consolidator |
| `v1.1.0` | 2026-05-24 | + infrastructure-audit |
| `v1.2.0` | 2026-05-24 | + validator (agent-only) |
| `v1.2.1` | 2026-05-24 | Fix `vibeflow-update.sh` (handle `AGENT.md`) |
| `v2.0.0` | 2026-05-24 | + skill-creator (multi-skills), + reference (doc-only), nouveau type de module |
| `v2.1.0` | 2026-05-28 | + software-architecture, type `rules/` dans l'installer, Core v4.2 (P9) |
| `v2.2.0` | 2026-06-03 | + audit-architecture, validator v1.1.0 (Phase 4 scan des process) |
| `v2.3.0` | 2026-06-04 | + dev-orchestrator (routeur NL → GSD + Superpowers, 13 verbes `/vf-*`) |
| `v2.4.0` | 2026-06-05 | Installation en 2 commandes : plugin Claude Code + `/vibeflow-install` à toggles |
| `v2.4.1` | 2026-06-06 | `/vibeflow-install` 100 % manuel, distribuable isolé sous `plugin/`, clean reliquats |
| `v2.4.2` | 2026-06-06 | Commande engine `uninstall --all` + flux de désinstallation dans `/vibeflow-install` + doc désinstallation 2 couches |
| `v2.5.0` | 2026-06-10 | + planning-core (socle `.planning/` universel, adaptatif par métier, 3 profils de rigueur) — ADR-038 |

</details>

<details>
<summary><strong>Références méthodologiques (ADR / LRN)</strong></summary>

- **ADR-032** — Système de consolidation mémoire 4 piliers
- **ADR-033** — Création du repo vibeflow-os
- **ADR-035** — Doctrine architecture logicielle AI-Safe (module software-architecture + P9 Core)
- **ADR-036** — Doctrine audit architecture (module audit-architecture + validator Phase 4)
- **LRN-101** — Pattern « agent minimal + 2 skills composables »
- **LRN-106** — Audit avant fix
- **LRN-107** — Repo central versionné > zip ad-hoc

Lab principal (privé) : [vibeflow-lab](https://github.com/picmakpro/vibeflow-lab) — les modifications structurantes y sont testées avant release.

</details>

---

## 👤 Auteurs

- **[@picmakpro](https://github.com/picmakpro)** — créateur et mainteneur de la méthodologie VibeFlow et de la plupart des modules (gouvernance, audits, `skill-creator`, `consolidator`, `reference`…). Propriétaire du repo.
- **Samuel Neveu — [@Samuel-Learnity](https://github.com/Samuel-Learnity)** — partie workflow de développement : le module `dev-orchestrator` et l'expérience langage naturel → pipeline.

---

## 📄 Licence

Source-available sous licence propriétaire — voir [LICENSE](./LICENSE). Le code et l'historique sont publics, mais aucun droit de réutilisation, de modification ou de distribution n'est accordé.

> Le module `skill-creator` réutilise du contenu Anthropic original sous licence MIT.
