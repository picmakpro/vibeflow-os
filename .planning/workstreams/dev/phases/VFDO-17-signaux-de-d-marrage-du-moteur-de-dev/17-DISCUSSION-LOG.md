# Phase 17: Signaux de démarrage du moteur de dev - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `17-CONTEXT.md` — this log preserves the analysis.

**Date:** 2026-07-27
**Phase:** VFDO-17-signaux-de-d-marrage-du-moteur-de-dev (les 2 plans de la phase, pas de découpage
préexistant)
**Mode:** assumptions (non-interactif — délégué par `vf-dev-manager` (n1 du DAG de mission) à
`vf-coder`, sans `AskUserQuestion` disponible pour ce worker — même protocole que Phase 13)
**Areas analyzed:** Continuum `check-dev-bootstrap.sh`, extension `--hook` de
`discover-unintegrated-docs.sh`, heuristique `check-doc-drift.sh`, gabarit `hooks/hooks.json`,
doctrine agent, gate ADR-044 (faux vert), preuve de portabilité Linux, contrat de test
sortie/exit, release-meta module.

## Assumptions Presented

### Continuum de `check-dev-bootstrap.sh` (4 états mutuellement exclusifs)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Détection code source par `find -prune` réutilisant le motif `PRUNE_VENDOR` de `detect-planning-debt.sh`, étendu à `docs/`/`.planning/`/`.claude/` | Confident (vérifié) | `plugin/planning-core/scripts/detect-planning-debt.sh:54`, spec §3.1 |
| État 3 lit le frontmatter YAML de `STATE.md` (milestone/current_phase/status), silence si illisible | Confident (spec explicite) | spec §3.1 « L'exit reste 3… retombe en silence » |
| État 3 est le SEUL cas où exit 3 s'accompagne d'une sortie non vide (piège de test) | Confident (fait vérifié par n1, mandat) | mandat n1 « piège de test à couvrir explicitement » |

### `discover-unintegrated-docs.sh --hook`
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Flag additif pur, contrat historique (`grain<TAB>chemin`, exits 0/3/64) inchangé sans le flag | Confident (spec explicite + script lu intégralement) | spec §3.2, `scripts/discover-unintegrated-docs.sh` (142L) |
| `--hook` + `--quiet` ensemble → exit 64 | Confident (spec explicite, critère 5) | spec §3.2, §7 critère 5 |

### `check-doc-drift.sh`
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Comptage de commits depuis le dernier commit touchant `docs/**` ou `README*` **racine seulement** (pas les README de module) | Likely (inférence du libellé spec « à la racine ») | spec §3.3 — formulation explicite « ou un README* à la racine » |
| Seuil 20 par défaut, réglable `--threshold`, silence hors dépôt git ou sans commit doc | Confident (spec explicite) | spec §3.3, tableau des exits |

### Gate ADR-044 (critère 6 de la spec)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Invocation nue de `check-agents.sh` est un faux vert sur ce repo (`.claude/agents` absent) ; l'invocation correcte est `--file plugin/dev-orchestrator/AGENT.md` | Confident (vérifié empiriquement par n1 avant ce cadrage) | mandat n1 : exit 0, 3 warnings baseline, `ci.yml:66-104` ne couvre que `plugin/*/agents` |
| Fermer le trou en ajoutant un test embarqué (T20) plutôt que de seulement documenter l'invocation | Likely (choix de conception, cohérent avec l'esprit ADR-044 « machine-enforced ») | découverte générique CI (`ci.yml:32`) ramasse tout fichier `tests/test-*.sh` |

### Preuve de portabilité Linux
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Aucune édition de `ci.yml` nécessaire, la découverte est déjà générique | Confident (vérifié par n1) | `ci.yml:32`, `runs-on: ubuntu-latest` |
| Preuve locale par conteneur Docker AVANT push, en réutilisant les idiomes déjà portables du repo | Confident (Docker disponible localement, mandat n1) | mandat n1 §Faits vérifiés point 2 |
| Le livrable de recherche du nœud n0 (parallèle) doit être consulté par l'exécution s'il existe, sans bloquer l'écriture de CE plan | Likely (dépendance DAG n2 ← n0, n1) | `.planning/missions/dag-phase17.json` |

## Corrections Made

Aucune — mode assumptions non-interactif, aucun humain disponible pour corriger ; toutes les
assumptions sont Confident ou Likely avec une évidence directe (spec, code lu, ou fait déjà
vérifié par le manager n1 avant délégation). Aucune n'atteint le seuil `human_needed`.

## Auto-Resolved

- **Emplacement de la doctrine agent** : la spec §5 tranche explicitement (table 4 lignes dans
  `AGENT.md`, pas de fichier `references/*.md` séparé) — pas d'ambiguïté à lever, à la différence
  de la Phase 13 où le choix (fichier séparé vs inline) n'était pas donné par la spec.
- **Portée du champ ROADMAP « Requirements »** : laissé `TBD` sur les 2 phases précédentes (15, 16)
  sans jamais être résolu formellement en `REQUIREMENTS.md` — mais le mandat n1 demande
  explicitement sa résolution ici. Résolu en dérivant des IDs inline dans le champ ROADMAP
  (périmètre d'écriture n1 n'incluant pas `REQUIREMENTS.md`), cohérent avec le fait que ce fichier
  n'a de toute façon pas été mis à jour pour les phases hors-milestone récentes (v2.32→v2.36.1).

## External Research

Aucune recherche externe nécessaire : la spec (291 lignes) et le code existant du module couvrent
la totalité des décisions d'implémentation. Seule la portabilité macOS↔Linux fine (au-delà des
idiomes déjà présents dans le repo) reste déléguée à la recherche parallèle du nœud n0 du DAG de
mission — non dupliquée ici.
