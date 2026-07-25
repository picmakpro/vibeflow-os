<div align="center">

# VibeFlow OS

[English](./README.md) · **Français**

**Transforme Claude Code en orchestrateur de dev & design piloté au langage naturel.**

Dis _« aide-moi à dev cette feature »_ — et tout le pipeline se déclenche : cadrage → plan → exécution → tests → livraison. Sans jamais taper une commande technique ni savoir ce qui tourne en coulisse. Les autres métiers ont leur lab sur mesure via la Lab Factory (`vf-new-lab`).

[![Version](https://img.shields.io/badge/version-2.35.0-2563eb)](./VERSION)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-d97757)](https://docs.claude.com/en/docs/claude-code)
[![Modules](https://img.shields.io/badge/modules-17-16a34a)](#-modules)
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

Aujourd'hui VibeFlow orchestre le **dev et le design** via un **modèle agentique** : l'agent `vibeflow-dev` détecte l'intention et invoque directement la chaîne GSD, avec une équipe de mission pour les runs longs. Les autres métiers se fabriquent en **labs sur mesure** via la Lab Factory (`vf-new-lab` + `skill-creator`) ; les **bundles content, growth et business-pilot sont disponibles** (équipes complètes sur le team-kernel). Au-delà de l'orchestration, VibeFlow embarque des modules de **gouvernance** : audit d'architecture logicielle, audit d'infrastructure, consolidation de mémoire, validation d'alignement méthodologique — chacun activable à la carte.

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

**Mise à jour :** `claude plugin update vibeflow@vibeflow-os` (ou simplement `/vf-update` une fois installé) · **Détails / troubleshooting :** [INSTALL.md](./INSTALL.md)

---

## 📦 Modules

17 modules au total. Chacun a sa propre version, son `CHANGELOG.md` et son `README.md`.

> **À l'installation (depuis v2.13.0)** : `conductor` est le **socle obligatoire** posé d'office (avec son filet : planning-core, validator, consolidator, infrastructure-audit) — pas un choix. Ensuite, **un seul choix** : *lab de développement* (`dev-orchestrator`) ou *nouveau lab métier sur mesure* via `/vf-new-lab`. Les **3 bundles métier** (business-pilot / content / growth) sont **WIP et non proposés à l'install** (`proposable:false`) ; ils seront reproposés une fois finalisés. Les autres modules restent disponibles en à-la-carte avancé (« ajoute &lt;module&gt; »). Les modules **mobile-test** et **mobile-test-team** sont des add-ons à-la-carte avancés pour les projets mobiles.

| Module | Ver. | Type | Ce qu'il fait |
|--------|:----:|------|---------------|
| **[conductor](./plugin/conductor/)** | `1.14.0` | agent + skills + scripts + references | 🧭 La porte d'entrée. Agent méta `vibeflow-conductor` (gardien) : crée/configure un lab dans **n'importe quel métier** (`vf-new-lab`, bundle-aware), installe/vérifie/met à jour, migre sur évolution de doctrine (`vf-calibrate`), reçoit les escalades de cohérence. Pas appelé en continu — config/audit/migration. |
| **[dev-orchestrator](./plugin/dev-orchestrator/)** | `2.1.0` | agent + skills + scripts | ⭐ Le cœur dev, **modèle agentique** (v2, breaking) : l'agent `vibeflow-dev` détecte l'intention et invoque **directement** les briques GSD (carte d'intention unique, on-demand), propose les next steps, garde le first-use. Équipe de mission `vf-dev-manager` (DAG + lock de driver + rapports typés + digest de mission) avec workers sonnet `vf-coder`/`vf-reviewer`/`vf-auditer`, dispatch parallèle revue ∥ audit, garde-fous de boucle autonome. Deux skills survivants : `vf-auto` (porte d'autonomie) et `vf-dev` (incarner l'agent). Installe `design-orchestrator` d'office. |
| **[design-orchestrator](./plugin/design-orchestrator/)** | `1.2.0` | agent + skills | 🎨 Le compagnon design. Agent routeur `vibeflow-design` + verbes `/vf-design` (point d'entrée design) et `/vf-sketch` (maquette jetable) : route le **langage naturel** design (définir la DA, refonte UI, critique/audit, craft ciblé) vers le bon workflow. **Générique multi-stack** (web / mobile / desktop) — produit des specs + tokens, pas du code framework-locké. Chaîne d'outils design (référentiel UX, direction créative, atelier de craft) pilotée en coulisse avec dégradation gracieuse. Installé d'office avec `dev-orchestrator`. |
| **[mobile-test](./plugin/mobile-test/)** | `1.0.1` | skill + script + config | 📱 Test réel d'app mobile (simulateur iOS / émulateur Android) : détection de cible, build-si-absent, régression Maestro, rapport horodaté + artefacts, diagnostic visuel des échecs via `mobile-mcp`. Piloté par config, sans constante projet. **Expérimental** jusqu'au premier vrai run vert. |
| **[mobile-test-team](./plugin/mobile-test-team/)** | `1.4.0` | agents + rules | 🤖 Boucle autonome test→fix mobile : `vf-test-orchestrator` + workers cloisonnés par outils (`vf-test-runner` / `vf-app-fixer`, Pattern 12), pour que le mode autonome atteigne « l'app marche vraiment », pas juste des tests unitaires verts. Une règle path-scopée déclenche la doctrine de vérification réelle pendant le code. Requiert `mobile-test`. **Expérimental**. |
| **[software-architecture](./plugin/software-architecture/)** | `1.5.2` | skill + rules + scripts | Doctrine d'architecture logicielle AI-Safe + **foyer des philosophies de dev** : SOLID, DRY, KISS, YAGNI, Clean Architecture, Clean Code, carte TDD ; anti-god-files (≤300 L), gates *machine-enforced* (**Nyquist + Decision Coverage** absorbés), playbook brownfield. |
| **[audit-architecture](./plugin/audit-architecture/)** | `1.0.1` | skill + references | Concepteur d'**architecture d'audit** : dérive depuis un brief la structure d'audit multi-couches d'un process (contenu / dossier / code / vente). |
| **[infrastructure-audit](./plugin/infrastructure-audit/)** | `1.2.1` | skill + scripts | Audit automatique de l'infra Claude Code (hooks, scripts, drift Anthropic) — détecte les régressions après une mise à jour. |
| **[validator](./plugin/validator/)** | `1.3.0` | agent-only | Agent `vibeflow-validator` : garant de l'alignement technique méthodo ↔ projets, en 5 phases (dont audit d'architecture des process). |
| **[consolidator](./plugin/consolidator/)** | `1.7.0` | skill + scripts | Consolidation de la mémoire structurée sur 4 piliers (indexation / archivage / fusion / promotion) + pilier mémoire vivante (couche `knowledge/` fichier-par-entrée, décroissance par demi-vie de catégorie, supersession non destructive) + registres fork-config. |
| **[skill-creator](./plugin/skill-creator/)** | `1.0.2` | agent + skills | Pattern « agent minimal + 2 skills composables » pour créer de nouveaux skills (base Anthropic + workflow). |
| **[reference](./plugin/reference/)** | `2.5.1` | doc-only | Documentation méthodologique complète : VibeFlow Core (9 principes) + 12 patterns (dont le cloisonnement par outils) + 33 templates + 1 exemple de bout en bout. |
| **[planning-core](./plugin/planning-core/)** | `2.5.0` | skill + references + scripts | Socle de planning & documentation du lab : pose le tronc commun `.planning/` d'un lab **non-dev** (PROJECT/STATE/ROADMAP/REQUIREMENTS/MILESTONES/phases), adapté à son métier — jamais imposé — et tient l'**altitude lab** partout : index des projets, compartiments typés, détection de dette, pont mémoire, fraîcheur machine-enforced. Sur un projet de code, le planning du projet appartient au moteur de développement : ce module redirige au lieu de produire un format concurrent (ADR-055). |
| **[kpi-analyst](./plugin/kpi-analyst/)** | `1.0.2` | agent + skill + scripts + references | 📈 Déduit les **vrais KPIs métier** d'un lab : schéma stable validé une fois + valeurs extraites de façon déterministe, publiées dans le registre `KPIS.md` pour le dashboard du Hub. Jamais de chiffre inventé. |
| 📦 **[business-pilot-bundle](./plugin/business-pilot-bundle/)** | `2.0.0` | agents + skill + scripts | Bundle métier, **équipe complète sur le team-kernel** : `vf-business-manager` + workers commercial/delivery/finance + juge `quality-gate-client` (périmètre vendu et montants sourcés éliminatoires, seuil 80). Double Iron Law : aucun envoi client sans validation humaine, aucun chiffre financier inventé. Skill d'entrée `vf-business`. |
| 📦 **[content-bundle](./plugin/content-bundle/)** | `2.0.0` | agents + skill + scripts | Bundle métier, **équipe complète sur le team-kernel** : `vf-content-manager` + workers strategist/writer/repurposer + `content-clarity-judge` (chiffres sourcés éliminatoires, seuil 80). Publication toujours human-gated. Skill d'entrée `vf-content`. |
| 📦 **[growth-bundle](./plugin/growth-bundle/)** | `2.0.0` | agents + skill + scripts | Bundle métier, **équipe complète sur le team-kernel** : `vf-growth-manager` + workers channel-strategist/copywriter/analyst + `growth-quality-judge` (claims sourcés et consentement/anti-spam éliminatoires). Tout envoi réel (email, dépense pub, outreach) human-gated ; métriques sourcées ou `low`. Skill d'entrée `vf-growth`. |

---

## ⌨️ Commandes

Slash commands natives livrées par le plugin (disponibles dès qu'il est activé — `commands/` auto-découvert) :

| Commande | Rôle |
|----------|------|
| `/vibeflow [demande]` | Porte d'entrée — délègue à l'agent **vibeflow-conductor** (créer/configurer/vérifier/mettre à jour/migrer le lab). |
| `/vf-new-lab [métier]` | Créer un lab dans n'importe quel métier (instancie un bundle métier si présent). |
| `/vf-planning` | Poser ou rafraîchir le socle `.planning/` d'un lab non-dev, et l'altitude lab partout (index des projets, compartiments, pont mémoire). Sur un projet de code, redirige vers le verbe de développement. |
| `/vf-calibrate` | Détecter le drift framework et migrer le lab (validation humaine). |
| `/vf-audit` | Audit de conformité complet via l'agent **vibeflow-validator**. |
| `/vibeflow-install` | Installer/activer des modules (skill installeur scope-aware). |
| `/vf-update` | Mettre à jour VibeFlow — plugin (cache marketplace) + modules installés — vers la dernière version publiée, avec changelog et confirmation. Un bandeau au démarrage signale une nouvelle version dès qu'il en existe une. |

> Les agents (`vibeflow-conductor`, `vibeflow-validator`) ne se tapent pas directement — ces commandes sont leurs points d'entrée explicites. Une commande renvoie vers `/vibeflow-install` si le module sous-jacent n'est pas encore installé.

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

- **Source-available** : code et historique publics, licence propriétaire — réutilisation privée accordée aux élèves de la formation, voir [LICENSE](./LICENSE).
- **Scripts shell + Python, plus l'outil standard `jq`** (lecture des manifestes JSON) — auditables ligne par ligne. Prérequis système listés dans [INSTALL.md](./INSTALL.md) (notes Windows/Git Bash incluses).
- **Idempotent** : chaque script d'install est ré-exécutable sans casser l'installation, avec backup automatique avant écrasement.
- **Zéro hook** : le plugin n'enregistre rien au démarrage de session. Tout part de ton invocation manuelle.
- **Tests** : chaque script est couvert (`scripts/tests/test-*.sh`).

---

## 🧭 Versioning & gouvernance

**Semver** par module (`vMAJOR.MINOR.PATCH`) — MAJOR = breaking change, MINOR = nouveau module/capacité, PATCH = bugfix ou doc. Le repo global est tagué à la version du dernier changement majeur. Chaque release GitHub = changelog officiel.

Historique complet : **[CHANGELOG.md](./CHANGELOG.md)** — le README ne garde que les 3 dernières entrées.

| Version | Date | Changement |
|---------|------|------------|
| `v2.31.1` | 2026-07-25 | Alignement des fichiers de version : les fichiers `VERSION` de `software-architecture` (v1.5.1) et `kpi-analyst` (v1.0.1) rattrapent leurs changelogs de la v2.29.0 — le registre de versions dit désormais la vérité. |
| `v2.31.0` | 2026-07-25 | Routage fin des intentions : trois niveaux de routage (descriptions déclencheuses, rule globale de préséance des verbes, doctrine de routage on-demand). 19 verbes `/vf-*` neufs — dev-orchestrator passe de 14 à 31, design-orchestrator gagne `/vf-sketch` (dev-orchestrator v1.8.1, design-orchestrator v1.1.0, conductor v1.12.2). |
| `v2.30.0` | 2026-07-25 | Frontière d'altitude entre le planning VibeFlow et le moteur de planning de développement (ADR-055) : `vf-planning` tient l'altitude lab et redirige le planning d'un projet de code vers le verbe de développement (planning-core v2.4.0). |

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

Source-available sous licence propriétaire — voir [LICENSE](./LICENSE). Le code et l'historique sont publics ; les élèves de la formation disposent d'un droit de réutilisation privée (adapter des éléments de modules dans leurs dépôts privés) ; redistribution et revente restent interdites.

> Le module `skill-creator` réutilise du contenu Anthropic original sous licence MIT.
