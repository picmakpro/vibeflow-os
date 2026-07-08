<div align="center">

# VibeFlow OS

[English](./README.md) · **Français**

**Transforme Claude Code en orchestrateur de développement piloté au langage naturel.**

Dis _« aide-moi à dev cette feature »_ — et tout le pipeline se déclenche : cadrage → plan → exécution → tests → livraison. Sans jamais taper une commande technique ni savoir ce qui tourne en coulisse.

[![Version](https://img.shields.io/badge/version-2.21.0-2563eb)](./VERSION)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-d97757)](https://docs.claude.com/en/docs/claude-code)
[![Modules](https://img.shields.io/badge/modules-16-16a34a)](#-modules)
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

**Mise à jour :** `claude plugin update vibeflow@vibeflow-os` (ou simplement `/vf-update` une fois installé) · **Détails / troubleshooting :** [INSTALL.md](./INSTALL.md)

---

## 📦 Modules

16 modules au total. Chacun a sa propre version, son `CHANGELOG.md` et son `README.md`.

> **À l'installation (depuis v2.13.0)** : `conductor` est le **socle obligatoire** posé d'office (avec son filet : planning-core, validator, consolidator, infrastructure-audit) — pas un choix. Ensuite, **un seul choix** : *lab de développement* (`dev-orchestrator`) ou *nouveau lab métier sur mesure* via `/vf-new-lab`. Les **3 bundles métier** (business-pilot / content / growth) sont **WIP et non proposés à l'install** (`proposable:false`) ; ils seront reproposés une fois finalisés. Les autres modules restent disponibles en à-la-carte avancé (« ajoute &lt;module&gt; »). Les modules **mobile-test** et **mobile-test-team** sont des add-ons à-la-carte avancés pour les projets mobiles.

| Module | Ver. | Type | Ce qu'il fait |
|--------|:----:|------|---------------|
| **[conductor](./plugin/conductor/)** | `1.8.2` | agent + skills + scripts + references | 🧭 La porte d'entrée. Agent méta `vibeflow-conductor` (gardien) : crée/configure un lab dans **n'importe quel métier** (`vf-new-lab`, bundle-aware), installe/vérifie/met à jour, migre sur évolution de doctrine (`vf-calibrate`), reçoit les escalades de cohérence. Pas appelé en continu — config/audit/migration. |
| **[dev-orchestrator](./plugin/dev-orchestrator/)** | `1.3.0` | agent + skills + scripts | ⭐ Le cœur dev. Agent routeur `vibeflow-dev` + 14 verbes `/vf-*` (dont le panel de décision `vf-decide`) + routage des phases de design vers `/vf-design` + index GSD auto-généré + doctrine des garde-fous de boucle autonome. Route le **langage naturel** vers les skills GSD/Superpowers (cadrage → livraison), sans exposer la plomberie. Installe `design-orchestrator` d'office. |
| **[design-orchestrator](./plugin/design-orchestrator/)** | `1.0.0` | agent + skills | 🎨 Le compagnon design. Agent routeur `vibeflow-design` + verbe `/vf-design` : route le **langage naturel** design (définir la DA, refonte UI, critique/audit, craft ciblé) vers le bon workflow. **Générique multi-stack** (web / mobile / desktop) — produit des specs + tokens, pas du code framework-locké. Chaîne d'outils design (référentiel UX, direction créative, atelier de craft) pilotée en coulisse avec dégradation gracieuse. Installé d'office avec `dev-orchestrator`. |
| **[mobile-test](./plugin/mobile-test/)** | `1.0.0` | skill + script + config | 📱 Test réel d'app mobile (simulateur iOS / émulateur Android) : détection de cible, build-si-absent, régression Maestro, rapport horodaté + artefacts, diagnostic visuel des échecs via `mobile-mcp`. Piloté par config, sans constante projet. **Expérimental** jusqu'au premier vrai run vert. |
| **[mobile-test-team](./plugin/mobile-test-team/)** | `1.0.1` | agents + rules | 🤖 Boucle autonome test→fix mobile : `vf-test-orchestrator` + workers cloisonnés par outils (`vf-test-runner` / `vf-app-fixer`, Pattern 12), pour que le mode autonome atteigne « l'app marche vraiment », pas juste des tests unitaires verts. Une règle path-scopée déclenche la doctrine de vérification réelle pendant le code. Requiert `mobile-test`. **Expérimental**. |
| **[software-architecture](./plugin/software-architecture/)** | `1.3.0` | skill + rules + scripts | Doctrine d'architecture logicielle AI-Safe + **foyer des philosophies de dev** : SOLID, DRY, KISS, YAGNI, Clean Architecture, Clean Code, carte TDD ; anti-god-files (≤300 L), gates *machine-enforced* (**Nyquist + Decision Coverage** absorbés), playbook brownfield. |
| **[audit-architecture](./plugin/audit-architecture/)** | `1.0.1` | skill + references | Concepteur d'**architecture d'audit** : dérive depuis un brief la structure d'audit multi-couches d'un process (contenu / dossier / code / vente). |
| **[infrastructure-audit](./plugin/infrastructure-audit/)** | `1.0.0` | skill + scripts | Audit automatique de l'infra Claude Code (hooks, scripts, drift Anthropic) — détecte les régressions après une mise à jour. |
| **[validator](./plugin/validator/)** | `1.1.0` | agent-only | Agent `vibeflow-validator` : garant de l'alignement technique méthodo ↔ projets, en 5 phases (dont audit d'architecture des process). |
| **[consolidator](./plugin/consolidator/)** | `1.0.0` | skill + scripts | Consolidation de la mémoire structurée sur 4 piliers : indexation / archivage / fusion / promotion. |
| **[skill-creator](./plugin/skill-creator/)** | `1.0.0` | agent + skills | Pattern « agent minimal + 2 skills composables » pour créer de nouveaux skills (base Anthropic + workflow). |
| **[reference](./plugin/reference/)** | `2.3.1` | doc-only | Documentation méthodologique complète : VibeFlow Core (9 principes) + 12 patterns (dont le cloisonnement par outils) + 33 templates + 1 exemple de bout en bout. |
| **[planning-core](./plugin/planning-core/)** | `1.1.0` | skill + references + scripts | Socle de planning & documentation universel : pose le tronc commun `.planning/` (PROJECT/STATE/ROADMAP/REQUIREMENTS/MILESTONES/phases), **adapté à la logique métier de chaque lab** — jamais imposé. Couche avant/présent, complémentaire des registres mémoire. Garde-fou de fraîcheur + détection métier + exemple non-dev. |
| 📦 **[business-pilot-bundle](./plugin/business-pilot-bundle/)** | `1.0.0` | doc-only (bundle) | Bundle métier : châssis prêt pour piloter un business (3 blueprints commercial/delivery/finance + extension `business/` + registres canon). Instancié par `vf-new-lab`. |
| 📦 **[content-bundle](./plugin/content-bundle/)** | `1.0.0` | doc-only (bundle) | Bundle métier : chaîne éditoriale brief→livrable→distribution (3 blueprints strategist/scriptwriter/repurposer + extension `editorial/` + gate clarté bloquant). Instancié par `vf-new-lab`. |
| 📦 **[growth-bundle](./plugin/growth-bundle/)** | `1.0.0` | doc-only (bundle) | Bundle métier : growth/acquisition **organisé par canal** (3 blueprints channel-strategist/copywriter/analyst + extension `growth/channels/` + garde-fous RGPD). Instancié par `vf-new-lab`. |

---

## ⌨️ Commandes

Slash commands natives livrées par le plugin (disponibles dès qu'il est activé — `commands/` auto-découvert) :

| Commande | Rôle |
|----------|------|
| `/vibeflow [demande]` | Porte d'entrée — délègue à l'agent **vibeflow-conductor** (créer/configurer/vérifier/mettre à jour/migrer le lab). |
| `/vf-new-lab [métier]` | Créer un lab dans n'importe quel métier (instancie un bundle métier si présent). |
| `/vf-planning` | Poser ou rafraîchir le socle `.planning/` ; répond à « où en est-on ? ». |
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
| `v2.6.0` | 2026-06-11 | planning-core v1.1.0 : garde-fou de fraîcheur (`check-planning-state.sh`) + détection métier + bootstrap opt-in + exemple non-dev travaillé |
| `v2.7.0` | 2026-06-11 | + conductor (orchestrateur méta/gardien) : bootstrap de lab universel (tout métier), propagation update + migration, protocole d'escalade sous-agents |
| `v2.8.0` | 2026-06-11 | + 3 bundles métier (business-pilot / content / growth-par-canal) + conductor v1.1.0 (`vf-new-lab` bundle-aware, fix pointeur cassé) |
| `v2.9.0` | 2026-06-11 | + slash commands natives (`/vibeflow`, `/vf-new-lab`, `/vf-planning`, `/vf-calibrate`, `/vf-audit`) — points d'entrée explicites des agents/skills méthodo |
| `v2.10.0` | 2026-06-17 | + kpi-analyst (KPIs métier : déduits, déterministes, sourcés) |
| `v2.11.0` | 2026-06-23 | planning-core v2.0.0 : topologie à compartiments + harmonisation branche main |
| `v2.12.0` | 2026-06-24 | vf-new-lab v1.3.0 : Lab Factory, clarification-first |
| `v2.13.0` | 2026-06-29 | Init : externalisation doc contextuelle + commandes d'incarnation native (ADR-042) |
| `v2.14.0` | 2026-07-04 | Gouvernance scripturale : hooks auto-câblés + canon DECISIONS + guards registres (ADR-043) |
| `v2.15.0` | 2026-07-05 | Guard Bash registres : fermeture du contournement shell (BLK-006) |
| `v2.15.1` | 2026-07-05 | Guard Read : fenêtre bornée par VALEUR, pas par présence (BLK-007) |
| `v2.16.0` | 2026-07-05 | Agents natifs machine-enforced + doctrine de chargement contexte (ADR-044) |
| `v2.17.0` | 2026-07-07 | + mobile-test + mobile-test-team (boucle autonome test→fix mobile), dev-orchestrator v1.2.0 (vf-decide + garde-fous autonomes), reference v2.3.0 (Pattern 12), support engine multi-agents |
| `v2.18.0` | 2026-07-07 | Discipline de release (convention `vf-internal` : les workers internes n'ont plus de commande d'incarnation ; conductor v1.7.0) + règle de tagging & guard du repo (`scripts/check-release-tag.sh`, règle path-scopée) |
| `v2.19.0` | 2026-07-07 | Commande `/vf-update` + bandeau de mise à jour au démarrage : update deux couches en un geste (cache marketplace du plugin + modules installés), dernière version détectée via les tags GitHub (conductor v1.8.0) |
| `v2.19.1` | 2026-07-07 | Correctif : `vf-update` + docs utilisent l'identifiant complet `vibeflow@vibeflow-os` pour `claude plugin update` (le nom nu peut échouer « Plugin not found » sur un cache de catalogue périmé), avec note de dépannage (conductor v1.8.1) |
| `v2.19.2` | 2026-07-07 | Correctif : `/vf-update` fait désormais respecter le socle obligatoire — un module `mandatory` publié après la config d'un lab (ex. `conductor` sur un lab antérieur à v2.13.0) était ignoré à vie, ses scripts & hooks (le bandeau de mise à jour SessionStart) jamais câblés ; `update` re-synchronise aussi la gouvernance des modules à jour (idempotent) (conductor v1.8.2) |
| `v2.20.0` | 2026-07-07 | Milestone doctrine dev : `software-architecture` **v1.3.0** = foyer des philosophies de dev (DRY/KISS/YAGNI ajoutés, Clean Architecture/Clean Code nommés, carte TDD, **gates Nyquist + Decision Coverage absorbés**) ; module `feature-dev-gates` **supprimé** + nettoyage moteur des modules retirés (rule orpheline nettoyée à `update --all`, test T7) ; `audit-architecture` **v1.0.1** (Instance C dé-dupliquée, description legacy corrigée) ; `reference` source unique des 3 axiomes d'enforcement |
| `v2.21.0` | 2026-07-08 | + **design-orchestrator** v1.0.0 : agent routeur `vibeflow-design` + verbe `/vf-design` (langage naturel design → workflow), **générique multi-stack** (web/mobile/desktop), chaîne d'outils design pilotée en coulisse avec dégradation gracieuse ; `dev-orchestrator` **v1.3.0** route les phases de design vers `/vf-design` et installe `design-orchestrator` d'office (`requires`) |

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
