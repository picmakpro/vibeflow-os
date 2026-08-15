# Phase 26 — Inventaire de la matière source du manuel utilisateur

> **Nature de ce document** : cartographie de l'existant, **pas** de rédaction. Rien n'est inventé,
> rien n'est réécrit — on relève ce qui est sur le disque au 2026-08-01 (`VERSION` = `v2.46.0`),
> sa nature, ses doublons, et ce qui manque.
>
> **Légende « nature »** : `vitrine` (pitch, valeur, pourquoi) · `procédure` (pas-à-pas) ·
> `concept` (modèle mental, philosophie) · `référence` (tableaux, listes exhaustives, options) ·
> `interne` (gouvernance du repo, release, contribution).
>
> **Légende « destination »** : `manuel` · `README` (reste au README) · `interne` (reste interne) ·
> `supprimer` (dupliqué, à retirer de la source secondaire).

**Total inventorié : 96 sections / unités documentaires** réparties sur 8 sources.

---

## 1. `README.md` (EN, 290 lignes)

| # | Section | ~L | Nature | Doublon | Destination |
|---|---------|---:|--------|---------|-------------|
| 1.1 | Hero (titre, tagline, pitch spec-driven, badges, nav) | 1-22 | vitrine | D-1 (README.fr) | README |
| 1.2 | `## The problem` (context rot / improvisation / burned tokens) | 24-34 | vitrine + concept | D-1 | README (résumé) + **manuel** (version développée) |
| 1.3 | `## 🔁 The dev cycle — spec-driven` + mermaid + 3 puces | 37-58 | concept | D-1 | **manuel** (thème « Le cycle de dev ») ; README garde le mermaid |
| 1.4 | `## 🤖 Long missions — the team` + mermaid + contrôle de flux | 62-83 | concept | D-1 | **manuel** (thème « Missions longues ») |
| 1.5 | `### Efficiency, quantified` (tableau 5 leviers) | 84-93 | référence | D-1 | **manuel** |
| 1.6 | `## 🧪 Beyond dev — a lab for any domain` + mermaid + 4 puces | 96-126 | vitrine + concept | D-1 | **manuel** (thème « Labs non-dev ») |
| 1.7 | `## 🧠 Memory that holds` (4 puces registres/mémoire) | 130-141 | concept | D-1 | **manuel** |
| 1.8 | `## 🏗 Architecture` + mermaid socle/orchestrateurs/gouvernance | 144-169 | concept + référence | D-1 | **manuel** (thème « Sous le capot ») |
| 1.9 | `## 🚀 Install` (2 commandes + `/vibeflow-install` + lien INSTALL) | 173-184 | procédure | **D-2 (INSTALL.md)**, D-1 | README (3 lignes) → pointe **manuel** |
| 1.10 | `## 📦 Modules` — chapeau (17 modules, socle obligatoire, choix) | 188-198 | référence | D-1 | **manuel** |
| 1.11 | `<details>` **tableau des 17 modules** (Module / Ver. / Type / What) | 200-223 | référence | **D-6 (READMEs de modules)**, D-1 | **manuel** (page « Catalogue des modules ») |
| 1.12 | « Shipped entry points » (commandes + skill installer) | 225-228 | référence | **D-8 (disque)** | **manuel** (page « Commandes ») |
| 1.13 | `## 🔒 Trust` (5 puces source-available / auditable / CI / hooks) | 232-243 | vitrine | D-1 | README |
| 1.14 | `## 🧭 Versioning` + **tableau de 9 releases** (v2.46 → v2.40) | 247-262 | interne | **D-4 (CHANGELOG.md)**, D-1 | **supprimer** (garder 3 lignes max + lien CHANGELOG) |
| 1.15 | `<details>` « Methodology references (ADR / LRN) » + lien vibeflow-lab | 263-277 | interne | D-7 (docs/ADR.md) | interne |
| 1.16 | `## 👤 Authors` | 281-284 | vitrine | D-1 | README |
| 1.17 | `## 📄 License` | 286-290 | référence | D-1 + `LICENSE` + `plugin/reference/content/LICENSE.md` | README |

**Constat de fraîcheur (bloquant pour le manuel)** : le tableau des modules (1.11) est **périmé sur
13 des 17 versions** (voir §7). Toute page de manuel qui recopie ce tableau héritera de la dette.

---

## 2. `README.fr.md` (FR, 296 lignes)

Structure **strictement isomorphe** à `README.md` : mêmes 17 unités, même ordre, mêmes ancres,
mêmes mermaid, mêmes badges (`version-2.46.0`, `modules-17`), même tableau de 9 releases.
Les 6 lignes d'écart sont du **retour à la ligne**, pas du contenu.

| # | Section FR | ~L | Correspond à |
|---|-----------|---:|--------------|
| 2.1 | Hero | 1-22 | 1.1 |
| 2.2 | `## Le problème` | 24-34 | 1.2 |
| 2.3 | `## 🔁 Le cycle dev — spec-driven` | 37-58 | 1.3 |
| 2.4 | `## 🤖 Missions longues — l'équipe` | 62-83 | 1.4 |
| 2.5 | `### L'efficience, chiffrée` | 85-94 | 1.5 |
| 2.6 | `## 🧪 Au-delà du dev — un lab pour chaque métier` | 97-130 | 1.6 |
| 2.7 | `## 🧠 La mémoire qui tient` | 134-145 | 1.7 |
| 2.8 | `## 🏗 Architecture` | 149-174 | 1.8 |
| 2.9 | `## 🚀 Installation` | 178-189 | 1.9 |
| 2.10 | `## 📦 Modules` (chapeau) | 193-203 | 1.10 |
| 2.11 | `<details>` tableau 17 modules | 205-228 | 1.11 |
| 2.12 | « Points d'entrée livrés » | 230-233 | 1.12 |
| 2.13 | `## 🔒 Confiance` | 237-248 | 1.13 |
| 2.14 | `## 🧭 Versioning` + 9 releases | 252-266 | 1.14 |
| 2.15 | `<details>` Références méthodologiques | 268-282 | 1.15 |
| 2.16 | `## 👤 Auteurs` | 286-289 | 1.16 |
| 2.17 | `## 📄 Licence` | 291-296 | 1.17 |

---

## 3. `INSTALL.md` (FR uniquement, 192 lignes)

| # | Section | ~L | Nature | Doublon | Destination |
|---|---------|---:|--------|---------|-------------|
| 3.1 | `## Pré-requis` (bash/jq/python3, cas **Windows** + Git Bash + CRLF ADR-054) | 7-19 | procédure | — | **manuel** (page « Prérequis ») — matière unique, à préserver telle quelle |
| 3.2 | `## Installation (2 commandes)` | 23-35 | procédure | **D-2** (README 1.9/2.9) | **manuel**, source unique |
| 3.3 | `## Configuration (lancement manuel)` — les 4 étapes de l'UX à toggles | 39-60 | procédure | partiel D-2 + `plugin/installer/SKILL.md` | **manuel** |
| 3.4 | Encadré « le lancement est toujours manuel » (+ historique du hook retiré) | 57-60 | procédure + interne | D-9 (Troubleshooting 3.9) | **manuel** (fusionner avec 3.9) |
| 3.5 | `### Re-configurer / ajouter un module` | 62-66 | procédure | — | **manuel** |
| 3.6 | `## Mises à jour` (`/vf-update`, `claude plugin update`, piège du nom nu) | 70-85 | procédure | partiel D-2 (README 1.9) + `conductor/skills/vf-update` | **manuel** |
| 3.7 | `## Désinstallation` (tableau 2 couches + ordre + engine `uninstall`) | 89-132 | procédure | — | **manuel** — matière unique |
| 3.8 | `### Dépendances externes (GSD / Superpowers)` | 134-144 | procédure + concept | — | **manuel** — seul endroit du repo qui nomme la relation VibeFlow ↔ GSD ↔ Superpowers |
| 3.9 | `## Sécurité` (4 puces : scripts auditables, idempotence, backup, zéro hook) | 148-155 | vitrine | **D-3** (README 1.13 « Trust ») | **supprimer** d'INSTALL, garder au README + 1 page manuel |
| 3.10 | `## Troubleshooting` — 4 entrées (`claude plugin` introuvable · UX ne s'ouvre pas · marketplace absent · réinstaller) | 159-192 | procédure | D-9 avec 3.4 | **manuel** (page « Dépannage install ») |

---

## 4. `CLAUDE.md` (racine, 56 lignes) — FR

| # | Section | ~L | Nature | Doublon | Destination |
|---|---------|---:|--------|---------|-------------|
| 4.1 | `## Ce qu'est ce repo` | 7-13 | interne | — | interne |
| 4.2 | `## Règle non négociable — Discipline de release : toute version = un tag` (4 étapes + garde-fou `check-release-tag.sh` + numérotation) | 15-48 | interne | partiel D-5 (README 1.14 « Versioning ») | interne — **jamais** au manuel |
| 4.3 | `## Conventions transverses` (densité ADR-029, ADR-031, ADR-044, commits FR) | 50-56 | interne | D-7 (docs/ADR.md « ADR héritées ») | interne |

**Verdict** : `CLAUDE.md` est intégralement de la gouvernance du repo de distribution. **Zéro
matière pour le manuel** — sauf, indirectement, la définition de ce qu'est un module (4.1).

---

## 5. `plugin/reference/` — la doc méthodologique (module doc-only, v2.5.2, FR)

`plugin/reference/README.md` (135 L) est la doc **du module**, pas la méthodologie elle-même.
Le contenu canonique vit dans `plugin/reference/content/` : **77 fichiers, 9 831 lignes**.

### 5.a Le README du module

| # | Section | ~L | Nature | Destination |
|---|---------|---:|--------|-------------|
| 5.1 | `## Quoi` + arborescence commentée de `content/` | 11-48 | référence | **manuel** (carte de la doctrine) |
| 5.2 | `## Installation` (copie `content/` → `docs/reference/` du lab) | 52-62 | procédure | **manuel** |
| 5.3 | `## Usage` (lecture méthodo, onboarding équipe, templates, exemple) | 66-92 | procédure | **manuel** |
| 5.4 | `## Historique des versions` | 93-108 | interne | interne |
| 5.5 | `## Pour les modules vibeflow-os` | 109-122 | interne | interne |
| 5.6 | `## Limites` / `## Liens` | 123-135 | référence | README module |

### 5.b Les documents fondateurs (`content/methodology/`)

| # | Fichier | L | Nature | Doublon | Destination |
|---|---------|--:|--------|---------|-------------|
| 5.7 | `VIBEFLOW_CORE.md` — « le système d'exploitation universel », **9 principes P1-P9**, architecture en 5 composants, 5 registres, dimensionnement par maturité | 783 | concept + référence | **D-10** | **manuel** (source doctrinale, à *citer* pas à recopier) |
| 5.8 | `VIBEFLOW_PHILOSOPHY.md` — « Pourquoi VibeFlow existe », **« Les 7 Principes »**, architecture universelle, transposition en 5 étapes, « ce que VibeFlow n'est PAS » | 282 | concept | **D-10 (périmé : 7 principes vs 9)** | **manuel** (thème « Philosophie ») après arbitrage 7↔9 |
| 5.9 | `VIBEFLOW_EXPLAINED.md` — vulgarisation en 30 s / 5 min / 15 min, analogie du CEO, **« Les 7 principes »**, FAQ 8 questions, « les preuves », « Nouveautés v4.1 » | 350 | concept + vitrine | **D-10 (périmé)** | **manuel** — c'est la matière la plus proche d'un manuel qui existe déjà |
| 5.10 | `AXIOMES-ENFORCEMENT.md` — 3 axiomes (enforcement > prose, filet de tests, preuve avant done) + « qui applique quoi » | 46 | concept | — | **manuel** (thème « Pourquoi des gates ») |

### 5.c Les 12 patterns (`content/methodology/patterns/`, 1 668 L au total)

| # | Fichier | L | Nature | Destination |
|---|---------|--:|--------|-------------|
| 5.11 | `README.md` (index des patterns) | 46 | référence | **manuel** (carte) |
| 5.12 | `01-constitution.md` | 93 | concept | **manuel** (profondeur 3) |
| 5.13 | `02-registres.md` | 187 | concept | **manuel** (profondeur 3) |
| 5.14 | `03-agents.md` | 179 | concept | **manuel** (profondeur 3) |
| 5.15 | `04-skills.md` | 160 | concept | **manuel** (profondeur 3) |
| 5.16 | `05-regles.md` | 139 | concept | **manuel** (profondeur 3) |
| 5.17 | `06-capitalisation.md` | 204 | concept | **manuel** (profondeur 3) |
| 5.18 | `07-transposition.md` | 133 | concept | **manuel** (profondeur 3) |
| 5.19 | `08-evaluer.md` | 180 | concept | **manuel** (profondeur 3) |
| 5.20 | `09-meta-procedures.md` | 132 | concept | **manuel** (profondeur 3) |
| 5.21 | `10-plan-review-adversarial.md` | 167 | concept | **manuel** (profondeur 3) |
| 5.22 | `11-halt-conditions.md` | 157 | concept | **manuel** — directement utile à l'utilisateur (« pourquoi l'agent s'est arrêté ») |
| 5.23 | `12-cloisonnement-outils.md` | 120 | concept | **manuel** — explique « le juge n'est jamais l'auteur » |

### 5.d Vocabulaire, templates, exemple

| # | Unité | L | Nature | Destination |
|---|-------|--:|--------|-------------|
| 5.24 | `vocabulary/lexique.md` | 118 | référence | **manuel** — mais **c'est un lexique de la *méthodologie*, pas du produit** (voir M-2) |
| 5.25 | `vocabulary/dire-ne-pas-dire.md` | 107 | référence | **manuel** |
| 5.26 | `vocabulary/forks-mapping.md` | 91 | référence | interne |
| 5.27 | `templates/` — 42 fichiers (9 agents + `_reference`, 5 docs, 7 memory, 5 triggers, 1 rule, 5 skills) | ~3 400 | référence | **manuel** (annexe « Templates », liste seulement) |
| 5.28 | `examples/PetitsCoursFlow/` — exemple fictif complet (Sophie K., prof de musique) : README, CLAUDE.md, 2 agents, 5 registres, 1 rule | ~600 | concept + procédure | **manuel** — le seul « bout en bout » existant, matière de tuto |
| 5.29 | `content/README-CLIENT.md` (présentation utilisateur final) | 145 | vitrine | **manuel** — préfigure le manuel |
| 5.30 | `content/VERSION.md` (changelog de la doc méthodo) | 88 | interne | interne |
| 5.31 | `content/LICENSE.md` (licence d'usage personnel) | 80 | référence | doublon partiel de `LICENSE` racine → **README** |

---

## 6. `docs/reference/methodology/` — **copie quasi intégrale de `plugin/reference/content/`**

`diff -rq docs/reference plugin/reference/content` → **77 fichiers, 2 seuls diffèrent réellement** :

| Fichier | État de `docs/reference/` | État de `plugin/reference/content/` |
|---------|---------------------------|--------------------------------------|
| `README-CLIENT.md` | **v2.0** (mai 2026) — « 8 principes », « 11 patterns », « 33 templates » | **v2.5.1** — « 9 principes », « 12 patterns », « 42 fichiers » |
| `VERSION.md` | **v2.1** (2026-05-28) | **v2.5.1** (2026-07-25) |
| `methodology/patterns/README.md` | identiques (diff vide) | identiques |
| Les 74 autres | **identiques octet pour octet** | — |

**C'est le doublon le plus massif du repo : 9 820 lignes dupliquées, dont 2 fichiers périmés
de deux versions mineures.** Voir **D-11**. Aucune section propre à `docs/reference/` n'existe —
rien à inventorier au-delà de ce constat.

---

## 7. `docs/ADR.md` (1 511 lignes) — ADR portant une notion **utilisateur**

Le registre contient **19 ADR détaillées (046 → 064)** + un index de **10 ADR héritées** (029-045)
avec définition canonique. On ne retient ici que celles dont un lecteur humain a besoin.

| # | ADR | Notion utilisateur portée | Destination |
|---|-----|---------------------------|-------------|
| 7.1 | **ADR-029** | Densité : agents ≤ 250 L, skills ≤ 500, bootstrap ≤ 2 000 tokens — *« pourquoi les agents sont courts »* | **manuel** (Sous le capot) |
| 7.2 | **ADR-031** | **Jamais de fix / suppression sans validation humaine** — *l'engagement central envers l'utilisateur* | **manuel** (page dédiée, très haut dans le manuel) |
| 7.3 | **ADR-032** | Consolidation mémoire 4 piliers — *« comment le lab n'oublie pas »* | **manuel** (Mémoire) |
| 7.4 | **ADR-035** | Doctrine architecture AI-Safe (SOLID/SoC, gates de taille) | **manuel** (Sous le capot) |
| 7.5 | **ADR-044** | Agents natifs machine-enforced + `vf-internal` — *« pourquoi certains agents n'ont pas de commande »* | **manuel** (Équipe d'agents) |
| 7.6 | **ADR-045** | **Recherche doc avant debug** — comportement visible pour l'utilisateur | **manuel** (Cycle de dev) |
| 7.7 | **ADR-051** | Allowlist MCP dérivée du lab — explique pourquoi l'install touche aux agents GSD | **manuel** (Ce que l'install écrit) |
| 7.8 | **ADR-053** | Swarm : lock de driver + DAG + rapports typés — *le mécanisme des missions longues* | **manuel** (Missions longues) |
| 7.9 | **ADR-054** | **Portabilité Windows** (CRLF, préflight) — condition d'usage réelle | **manuel** (Prérequis) |
| 7.10 | **ADR-055** | Frontière planning-core ↔ moteur GSD : *un projet = un seul moteur* | **manuel** (VibeFlow & GSD) |
| 7.11 | **ADR-057** | Frontières avec les briques tierces | **manuel** (VibeFlow & l'écosystème) |
| 7.12 | **ADR-058** | Le moteur GSD entre dans le périmètre de `/vf-update` | **manuel** (Mise à jour) |
| 7.13 | **ADR-059** | **Une mission d'équipe travaille sur sa propre branche + PR laissée ouverte** — impact direct sur le workflow git de l'utilisateur | **manuel** (Missions longues) |
| 7.14 | **ADR-060** | La revue est un étage de premier rang piloté par le manager | **manuel** (Cycle de dev) |
| 7.15 | **ADR-064** | **Un écrivain = un worktree** — impose une pratique à l'utilisateur multi-session | **manuel** (Missions longues / Dépannage) |

**Restent internes** (décisions de mécanique interne, aucune notion utilisateur) : ADR-046, 047,
048, 049, 050, 052, 056, 061, 062, 063.

---

## 8. `plugin/` — les 17 modules (états **disque**, `VERSION` + `module.json`)

| # | Module | `VERSION` disque | Ver. annoncée README | README | Ce qu'il apporte à l'utilisateur (1 ligne) |
|---|--------|:----------------:|:--------------------:|-------:|---------------------------------------------|
| 8.1 | `conductor` | **1.19.0** | ~~1.14.1~~ | 136 L | La porte d'entrée : crée/configure/vérifie/met à jour un lab, héberge le team-kernel et les gates. |
| 8.2 | `dev-orchestrator` | **2.10.0** | ~~2.1.1~~ | 305 L | Le cœur dev : l'agent `vibeflow-dev` comprend le langage naturel et lance le cycle, plus l'équipe de mission. |
| 8.3 | `design-orchestrator` | **1.4.0** | ~~1.2.1~~ | 139 L | Le compagnon design : « rends ça plus beau » → direction artistique, craft, critique scorée /100. |
| 8.4 | `mobile-test` | **1.0.2** | ~~1.0.1~~ | 130 L | Teste vraiment une app mobile sur simulateur/émulateur (Maestro), avec rapport et captures. |
| 8.5 | `mobile-test-team` | **1.4.1** | ~~1.4.0~~ | 137 L | Boucle autonome test → corrige → re-test jusqu'à ce que l'app marche vraiment. |
| 8.6 | `software-architecture` | 1.5.2 | 1.5.2 ✓ | **47 L** | La doctrine de code (SOLID/DRY/KISS, anti-god-files ≤ 300 L) appliquée par des gates machine. |
| 8.7 | `audit-architecture` | **1.0.2** | ~~1.0.1~~ | 122 L | Dérive d'un brief la structure d'audit multi-couches d'un process (contenu, dossier, code, vente). |
| 8.8 | `infrastructure-audit` | **1.2.2** | ~~1.2.1~~ | 146 L | Détecte les régressions d'infra Claude Code après une mise à jour (hooks, scripts, drift). |
| 8.9 | `validator` | 1.3.1 | 1.3.1 ✓ | 156 L | Vérifie en 5 audits que le lab reste aligné sur la méthodologie ; propose, ne corrige jamais seul. |
| 8.10 | `consolidator` | **1.8.1** | ~~1.8.0~~ | 154 L | Entretient la mémoire du lab : indexation, archivage, fusion, promotion learning → règle. |
| 8.11 | `skill-creator` | **1.0.3** | ~~1.0.2~~ | 140 L | Fabrique de nouvelles capacités (skills) pour le lab, avec boucle d'évaluation. |
| 8.12 | `reference` | **2.5.2** | ~~2.5.1~~ | 135 L | La bibliothèque méthodologique complète, posée en `docs/reference/` du lab. |
| 8.13 | `planning-core` | **2.5.3** | ~~2.5.1~~ | **94 L** | Le socle de planning des labs **non-dev** + l'altitude lab (index de projets, dette). |
| 8.14 | `kpi-analyst` | **1.0.3** | ~~1.0.2~~ | 135 L | Déduit les vrais KPIs métier du lab et les tient dans `KPIS.md` — jamais un chiffre inventé. |
| 8.15 | `business-pilot-bundle` | **2.0.3** | ~~2.0.1~~ | 135 L | Équipe business complète (commercial/delivery/finance + gate qualité client). |
| 8.16 | `content-bundle` | **2.0.3** | ~~2.0.1~~ | 123 L | Équipe contenu complète (stratège/rédacteur/repurposer + juge de clarté). |
| 8.17 | `growth-bundle` | **2.0.3** | ~~2.0.1~~ | 135 L | Équipe growth complète (canaux/copy/analyse + juge qualité, anti-spam éliminatoire). |

**Constat 1 — dette de version** : **13 modules sur 17** portent au README une version périmée
(barrées ci-dessus). Le manuel ne doit **pas** recopier de numéros de version : il doit renvoyer
au module.

**Constat 2 — la promesse « même structure partout » est fausse** (README 1.10 / 2.10 affirme
« ce qu'il fait, installation, démarrer, usage, référence exhaustive, limites ») :

| Structure de README | Modules |
|---------------------|---------|
| **Canonique** (`Quoi` · `Installation` · `Démarrer` · `Usage` · `Référence` · `Limites`) | audit-architecture, business-pilot-bundle, content-bundle, design-orchestrator, growth-bundle, infrastructure-audit, kpi-analyst, mobile-test, mobile-test-team, skill-creator — **10/17** |
| **Partielle** (pas de `Démarrer`) | consolidator, reference, validator, dev-orchestrator — 4/17 |
| **Hors-norme** (aucune section commune) | `conductor` (agent/team-kernel/skills/hooks/scripts/contenu/limites), `planning-core` (problème/idée/tronc commun/profils…), `software-architecture` (contenu/activation/installation/deux usages) — **3/17**, dont les **deux modules les plus structurants** |

---

## 9. Commandes et skills réellement exposés (établi depuis le disque)

### 9.a Commandes — `plugin/commands/` (6 fichiers, aucune ailleurs)

| # | Commande | L | Description (frontmatter) | Destination |
|---|----------|--:|---------------------------|-------------|
| 9.1 | `/vibeflow` | 21 | Point d'entrée — configurer / vérifier / mettre à jour / migrer via `vibeflow-conductor`. | **manuel** |
| 9.2 | `/vf-new-lab` | 17 | Crée/initialise un lab dans n'importe quel métier. | **manuel** |
| 9.3 | `/vf-planning` | 21 | Socle de planning d'un lab non-dev + altitude lab. | **manuel** |
| 9.4 | `/vf-calibrate` | 13 | Recalibre/migre le lab après évolution de doctrine, sous validation humaine. | **manuel** |
| 9.5 | `/vf-audit` | 16 | Audit de conformité complet du lab via `vibeflow-validator`. | **manuel** |
| 9.6 | `/vf-update` | 16 | Met à jour plugin + modules installés, avec changelog et confirmation. | **manuel** |

### 9.b Skills livrés (hors `plugin/reference/content/…/templates/skills/`, qui sont des **modèles**)

| # | Skill | Module | Destination |
|---|-------|--------|-------------|
| 9.7 | `vibeflow-install` | `plugin/installer/` | **manuel** — c'est *le* point d'entrée de l'install |
| 9.8 | `vf-new-lab` | conductor | **manuel** |
| 9.9 | `vf-calibrate` | conductor | **manuel** |
| 9.10 | `vf-update` | conductor | **manuel** |
| 9.11 | `vf-dev` | dev-orchestrator | **manuel** |
| 9.12 | `vf-auto` | dev-orchestrator | **manuel** |
| 9.13 | `vf-design` | design-orchestrator | **manuel** |
| 9.14 | `vf-sketch` | design-orchestrator | **manuel** |
| 9.15 | `vf-business` | business-pilot-bundle | **manuel** |
| 9.16 | `vf-content` | content-bundle | **manuel** |
| 9.17 | `vf-growth` | growth-bundle | **manuel** |
| 9.18 | `audit-architecture`, `consolidator`, `infrastructure-audit`, `kpi-analyst`, `mobile-test`, `planning-core`, `software-architecture` (skills mono-fichier à la racine du module) | 7 modules | **manuel** (référence) |
| 9.19 | `skill-creator`, `skill-creator-workflow` | skill-creator | **manuel** (référence) |

### 9.c Écarts disque ↔ README (à ne pas propager dans le manuel)

- Le README (1.12 / 2.12) présente **`/vf-design` et `/vf-sketch` comme des commandes** dans le
  tableau des modules (ligne `design-orchestrator`) : ce sont des **skills**, pas des fichiers de
  `plugin/commands/`.
- Le README liste **6 commandes + 1 skill** ; le disque porte **6 commandes + 18 skills livrés**.
  La liste « points d'entrée livrés » est donc **incomplète**, pas fausse.

### 9.d Agents livrés (22 hors templates et blueprints) — matière du thème « Équipe d'agents »

| Famille | Agents |
|---------|--------|
| Agents « visage » (`AGENT.md`) | `vibeflow-conductor`, `vibeflow-dev`, `vibeflow-design`, `vibeflow-validator`, `kpi-analyst`, `skill-creator` |
| Équipe dev | `vf-dev-manager`, `vf-coder`, `vf-reviewer`, `vf-auditer` |
| Équipe design | `vf-design-manager`, `vf-crafter`, `vf-design-judge` |
| Équipe mobile | `vf-test-orchestrator`, `vf-test-runner`, `vf-app-fixer` |
| Bundle business | `vf-business-manager`, `vf-business-commercial`, `vf-business-delivery`, `vf-business-finance`, `quality-gate-client` |
| Bundle content | `vf-content-manager`, `vf-content-strategist`, `vf-content-writer`, `vf-content-repurposer`, `content-clarity-judge` |
| Bundle growth | `vf-growth-manager`, `channel-strategist`, `copywriter-sequences`, `campaign-analyst`, `growth-quality-judge` |

---

## 10. Table des doublons (le cœur du rapport)

Classés par **coût** (volume dupliqué × risque de divergence).

| ID | Paire de sources | Volume | Divergence constatée | Traitement proposé |
|----|------------------|-------:|----------------------|--------------------|
| **D-11** | `docs/reference/` **↔** `plugin/reference/content/` | **9 820 L / 77 fichiers** | 74 fichiers identiques ; `README-CLIENT.md` et `VERSION.md` **périmés de v2.0/v2.1 → v2.5.1** dans `docs/` | **Le plus coûteux.** Une seule source canonique (`plugin/reference/content/`) ; `docs/reference/` devient un artefact d'install ou disparaît du versionnement. Le manuel ne référence **que** la source canonique. |
| **D-1** | `README.md` **↔** `README.fr.md` | **586 L** (2 × ~293) | Aucune divergence de fond détectée ; les 6 L d'écart sont du wrapping | Structurel et **assumé** (bilinguisme). Mais le coût double à chaque ajout → **maigrir les deux d'abord**, puis dupliquer moins. |
| **D-4** | Tableau « Versioning » des 2 README **↔** `CHANGELOG.md` (57,7 Ko) | **~2 × 9 entrées de 20-40 lignes = ~180 L de prose dense, en double langue** | Le README annonce « garde les 3 dernières » et en porte **9** | **Supprimer** 6 entrées sur 9 dans les deux README ; le manuel ne porte **aucun** changelog, il pointe `CHANGELOG.md`. |
| **D-2** | README §Install (1.9 / 2.9) **↔** `INSTALL.md` §Installation + §Configuration | ~35 L × 3 emplacements | Les 2 commandes `claude plugin …` sont écrites **3 fois** (EN, FR, INSTALL) ; la mention `/vf-update` **4 fois** | **Manuel = source unique** de la procédure. README garde 3 lignes + lien. `INSTALL.md` maigrit ou devient une redirection. |
| **D-10** | `VIBEFLOW_CORE.md` **↔** `VIBEFLOW_PHILOSOPHY.md` **↔** `VIBEFLOW_EXPLAINED.md` | **1 415 L** | **Contradiction active** : CORE dit « **9 principes** universels (P1-P9) », PHILOSOPHY dit « **Les 7 Principes** », EXPLAINED dit « **Les 7 principes** » — deux versions de retard non propagées | Arbitrage requis **avant** rédaction du manuel. Le manuel choisit une profondeur unique et cite CORE comme référence. |
| **D-6** | README §Modules (tableau 17 lignes) **↔** les 17 `plugin/*/README.md` (§Quoi) **↔** les 17 `module.json` (`description`) | 3 copies de 17 descriptions | **13/17 versions périmées** au README ; descriptions rédigées 3 fois de 3 façons | Le manuel dérive la liste du disque (`module.json`) et **ne recopie aucune version**. |
| **D-3** | `INSTALL.md` §Sécurité **↔** README §Trust / §Confiance | ~20 L × 3 | Formulations divergentes de la même promesse « zéro hook au niveau plugin » | Une page manuel « Ce que VibeFlow n'exécute pas » ; retirer d'`INSTALL.md`. |
| **D-9** | `INSTALL.md` §3.4 (encadré « lancement manuel ») **↔** §3.10 Troubleshooting « L'UX d'install ne s'ouvre pas » | ~15 L | Le même fait dit deux fois dans le même fichier, à 110 lignes d'écart | Fusionner dans le manuel. |
| **D-5** | `CLAUDE.md` §Discipline de release **↔** README §Versioning | ~15 L | Le README expose au public une règle de gouvernance interne | Rester interne ; ne **jamais** entrer au manuel. |
| **D-7** | README `<details>` « Références méthodologiques » **↔** `docs/ADR.md` §« ADR héritées » | ~10 L | Le README liste 6 ADR + 2 LRN ; le registre en définit 10 | Le manuel cite les ADR **utilisateur** (§7) et pointe le registre. |
| **D-8** | README « points d'entrée livrés » **↔** disque (`plugin/commands/`, skills) | — | **Incomplet** : 1 skill listé, 18 livrés ; 2 skills présentés comme commandes | Le manuel établit la liste **depuis le disque**. |
| **D-12** | `LICENSE` racine **↔** `plugin/reference/content/LICENSE.md` **↔** README §License ×2 | ~180 L | Deux textes de licence distincts coexistent (usage personnel vs source-available) | Hors périmètre manuel — à signaler. |

---

## 11. Table des manques (aucune matière n'existe — à écrire de zéro)

Classés par importance pour un nouvel arrivant humain.

| ID | Manque | Pourquoi c'est bloquant | Matière existante |
|----|--------|-------------------------|-------------------|
| **M-1** | **« Et maintenant ? » — le premier quart d'heure après l'install** | `INSTALL.md` s'arrête à « modules posés au scope choisi ». Le README montre des mermaid mais aucun pas-à-pas. **Aucun fichier du repo ne décrit une première session réelle.** Les sections « Démarrer (5 min) » sont **par module** et absentes de 7 modules sur 17 — dont `conductor`, la porte d'entrée. | **Zéro** — à écrire intégralement |
| **M-2** | **Glossaire du produit** (≠ lexique de la méthodologie) | Le README emploie sans jamais les définir : *lab*, *scope*, *module*, *bundle*, *socle*, *team-kernel*, *driver lock*, *DAG*, *digest de mission*, *halt condition*, *juge frais*, *gate machine*, *rapport typé*, *worktree*, *anti-thrash*, *frontière ready*. `vocabulary/lexique.md` (118 L) couvre le vocabulaire **méthodologique** (agents, registres, constitution), pas celui-ci. | Partielle (lexique méthodo) — ~80 % à écrire |
| **M-3** | **Qu'est-ce qu'un « lab », concrètement ?** | Mot central du produit (« il fabrique des labs », « ton lab », « lab frais », « altitude lab ») — **jamais défini nulle part**. Un dossier ? un projet git ? un scope Claude Code ? | **Zéro** |
| **M-4** | **Anatomie d'un lab installé — ce que l'install écrit sur ton disque** | La seule trace est le **tableau de désinstallation** d'`INSTALL.md` (§3.7), qui liste `.claude/skills/`, `.claude/agents/`, `.claude/scripts/`, `.claude/rules/`, `docs/` — à l'envers, comme une procédure de retrait. Rien sur `.vibeflow-installed`, `.planning/`, les hooks posés, l'injection MCP (ADR-051). | Fragmentaire (tableau inversé) |
| **M-5** | **VibeFlow ↔ GSD (`@opengsd/gsd-core`) ↔ Superpowers — qui fait quoi** | Le cycle de dev **repose entièrement** sur GSD ; le lecteur n'a que la §« Dépendances externes » d'`INSTALL.md` (11 L, orientée désinstallation) et 3 ADR (055/057/058) internes. Rien ne dit ce que VibeFlow ajoute, ni ce qui se passe sans GSD. | Fragmentaire (11 L + 3 ADR) |
| **M-6** | **Choisir : quel scope, quels modules** | `INSTALL.md` nomme les 3 scopes en une ligne chacun sans arbitrage. Aucun guide « solo dev / équipe / lab contenu → installe X ». Les 3 bundles métier n'ont pas de critère de choix. | **Zéro** |
| **M-7** | **Dépannage au-delà de l'install** | Les 4 entrées de troubleshooting sont **toutes** des problèmes d'installation. Rien pour : l'agent ne s'est pas déclenché · une mission est bloquée · une halt condition a gelé un nœud · le driver lock est coincé · le claim de branche refuse (ADR-064) · une PR de mission est restée ouverte (ADR-059). | **Zéro** |
| **M-8** | **Cycle de vie d'une mission vu par l'humain** | ADR-053/059/060/064 décrivent la mécanique **côté agents**. Rien ne dit à l'utilisateur : quand il sera sollicité, comment interrompre (`gsd-pause-work`), comment reprendre, où atterrissent les artefacts, ce qu'il doit relire avant de merger. | Fragmentaire (ADR internes) |
| **M-9** | **Un parcours non-dev complet et réel** | `/vf-new-lab` est vendu « lab opérationnel en ≤ 15 minutes, 3 questions » — **aucune transcription, aucun exemple d'échange** dans le repo. `PetitsCoursFlow` est un exemple de *lab fini*, pas de *création de lab*. | Partielle (PetitsCoursFlow, statique) |
| **M-10** | **Tout le contenu profond est FR-only** | Le lecteur EN dispose de 290 lignes ; les ~10 000 lignes de doctrine, les 17 READMEs de modules, `INSTALL.md`, `CHANGELOG.md` et `docs/ADR.md` sont exclusivement en français. Le manuel bilingue **crée** cette matière EN — elle n'existe pas. | **Zéro côté EN** |
| **M-11** | **Combien ça coûte / quel modèle est utilisé quand** | Le README chiffre l'efficience (§1.5) mais rien n'explique à l'utilisateur ce qui tourne en opus vs sonnet, ni comment il maîtrise sa dépense. | Fragmentaire (tableau README) |
| **M-12** | **Prérequis Windows testés vs non testés** | `INSTALL.md` §3.1 est solide sur Windows, mais rien ne dit ce qui est **vérifié** (la CI tourne macOS + Debian + Ubuntu selon le CHANGELOG v2.42.0) et ce qui ne l'est pas. | Fragmentaire |

---

## 12. Parité FR/EN — constat (aucune correction appliquée)

### 12.a Au niveau des deux README : parité **structurelle intégrale**

- **17 unités de contenu de chaque côté**, dans le **même ordre**, avec les **mêmes ancres**.
- **Aucune section présente d'un côté et absente de l'autre.**
- Mêmes badges (`version-2.46.0`, `Claude Code-plugin`, `modules-17`, `license-source--available`).
- Mêmes 4 diagrammes mermaid, avec libellés de nœuds traduits mais topologie identique.
- Mêmes 9 entrées de tableau de versioning (v2.46.0 → v2.40.0), traduites intégralement.
- Mêmes **13 versions de modules périmées** — la dette est **synchronisée** dans les deux langues.
- Écart de 6 lignes (290 vs 296) = retour à la ligne du français, pas du contenu.

### 12.b Divergences de fond relevées

Aucune divergence sémantique. Trois écarts **lexicaux** seulement, tous cohérents :

| EN | FR | Verdict |
|----|----|---------|
| « Stack-agnostic » | « Générique multi-stack » | équivalent |
| « Métier bundle » (mot français conservé en EN) | « Bundle métier » | équivalent |
| « the README keeps the last 3 entries » | « le README garde les 3 dernières » | **les deux mentent identiquement** (9 entrées présentes) |

### 12.c La vraie asymétrie : la parité s'arrête au README

| Ressource | EN | FR |
|-----------|:--:|:--:|
| README | ✅ 290 L | ✅ 296 L |
| `INSTALL.md` | ❌ | ✅ 192 L |
| `CHANGELOG.md` | ❌ | ✅ 57,7 Ko |
| `docs/ADR.md` | ❌ | ✅ 1 511 L |
| `plugin/reference/content/` (doctrine, patterns, templates) | ❌ | ✅ 9 831 L |
| Les 17 `plugin/*/README.md` | ❌ | ✅ ~2 200 L |
| `CLAUDE.md` | ❌ | ✅ 56 L |

**Un lecteur anglophone qui clique n'importe quel lien du README tombe sur du français.**
Le manuel bilingue devra donc **produire** la matière EN de profondeur 2 et 3, pas la traduire —
elle n'existe pas.

---

## 13. Ce que la matière impose comme thèmes de manuel

Constat transversal : la matière du repo est **très riche en `concept` et `référence`**
(≈ 11 500 lignes de doctrine et de tableaux), **pauvre en `procédure` utilisateur**
(≈ 200 lignes, toutes concentrées sur l'installation et la désinstallation), et **vide en
parcours guidé** (0 ligne). Le manuel doit donc majoritairement **écrire de la procédure et du
parcours**, et **réordonner** le concept déjà écrit — pas le réécrire.

Trois thèmes s'imposent au vu de cette distribution :

1. **« Démarrer »** — le trou le plus béant (M-1, M-3, M-4, M-6) coïncide avec le doublon le plus
   fréquent (D-2, install racontée 3 fois). C'est le seul thème où **supprimer un doublon et
   combler un manque sont le même geste**.
2. **« Comprendre »** — modèle mental et vocabulaire (M-2, M-3, M-5). La doctrine existe en
   abondance mais à l'altitude du concepteur (`VIBEFLOW_CORE.md`, 783 L, 9 principes) ; il manque
   la marche du bas. À traiter **après** l'arbitrage 7↔9 principes (D-10).
3. **« Opérer au quotidien »** — le cycle de dev, les missions longues, l'autonomie, quand
   intervenir, quoi faire quand ça bloque (M-7, M-8, M-11). Matière disponible mais **dispersée
   dans 15 ADR** écrites pour les agents, jamais pour l'humain.

Quatre thèmes secondaires suivent naturellement : **« Labs non-dev »** (M-9), **« Catalogue »**
(modules/commandes/skills, §8-9, dérivé du disque), **« Sous le capot »** (patterns 5.11-5.23,
architecture 1.8), **« Dépannage »** (3.10 + M-7).

---

## 14. Points de vigilance pour la phase de rédaction

1. **Ne recopier aucun numéro de version** dans le manuel : 13/17 sont déjà périmés au README, la
   dette se propagerait mécaniquement.
2. **Arbitrer 7 vs 9 principes** (D-10) avant d'écrire la page philosophie.
3. **Trancher le sort de `docs/reference/`** (D-11) avant de poser des liens : 9 820 lignes
   dupliquées, dont 2 fichiers en retard de deux versions mineures.
4. **Dériver commandes et skills du disque**, jamais du README (D-8) : la liste publiée est
   incomplète et classe 2 skills en commandes.
5. **Ne pas importer `CLAUDE.md`** : discipline de release et conventions de commit sont de la
   gouvernance du repo de distribution, sans objet pour un utilisateur (§4).
6. **Le bilinguisme n'est pas une traduction** : côté EN, la profondeur 2-3 n'existe pas (§12.c).
