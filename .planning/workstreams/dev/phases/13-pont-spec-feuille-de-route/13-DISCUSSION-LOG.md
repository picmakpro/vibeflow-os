# Phase 13: Pont spec → feuille de route - Discussion Log (Assumptions Mode, plan 13-02)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `13-CONTEXT.md` — this log preserves the analysis.

**Date:** 2026-07-26
**Phase:** 13-pont-spec-feuille-de-route (portée : plan 13-02 uniquement — 13-01 déjà écrit,
en cours d'exécution en parallèle, non rouvert)
**Mode:** assumptions (non-interactif — délégué par `vf-dev-manager` à `vf-coder`, sans
`AskUserQuestion` disponible pour ce worker)
**Areas analyzed:** Emplacement de la doctrine (densité ADR-029), Contrat manifest/délégation,
Garde-fous BRDG-03, Next step, Axes de test machine, Release-meta du module

## Assumptions Presented

### Emplacement de la doctrine d'ingestion (densité ADR-029)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Nouveau fichier `references/ingestion-flow.md`, chargé on-demand ; `AGENT.md` reçoit seulement renvois + 1 ligne de table + 1 clause | Likely | `plugin/dev-orchestrator/references/{GSD-PIPELINE,mission-flow,autonomous-guardrails}.md` (pattern identique) ; `AGENT.md` à 152/250L |

### Contrat de construction du manifest depuis la sortie `grain<TAB>chemin`
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Manifest YAML `docs: [{path, type: SPEC}]` (grain spec uniquement) ; grain plan → `gsd-import --from` direct, pas de manifest | Confident (vérifié après recherche) | `$HOME/.claude/skills/gsd-ingest-docs/SKILL.md`, `$HOME/.claude/get-shit-done/workflows/ingest-docs.md:93-104`, `$HOME/.claude/skills/gsd-import/SKILL.md` |

### Emplacement des nouveaux axes de test
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| T16/T17 dans `test-dev-orchestrator.sh` (pas de fichier dédié — pas de script bash autonome produit par 13-02) | Likely | `test-dev-orchestrator.sh` T15 (mission-flow.md ↔ vf-dev-manager.md, même structure de vérification) ; contraste avec 13-01 (`test-discover-unintegrated-docs.sh`, script bash autonome avec fixtures) |

### Protocole de confirmation humaine (ADR-031) et bouclage next-step
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Gates BLOCKER/confirmation natifs à `gsd-ingest-docs`/`gsd-import` (pas réimplémentés) ; next step = clause ajoutée au mécanisme générique existant `AGENT.md:92-100` | Confident (gates, vérifiés) / Likely (formulation next-step) | `ingest-docs.md` steps `discover_docs`/`conflict_gate` ; `import.md` step `plan_conflict_detection` ; `AGENT.md:92-100` |

## Corrections Made

Aucune — mode `--auto`, toutes les assumptions Confident/Likely.

## Auto-Resolved

N/A — aucun item Unclear (recherche complémentaire menée avant présentation, cf. ci-dessous).

## External Research

- **Schéma exact du manifest `gsd-ingest-docs --manifest`** : l'agent d'analyse initial
  (`gsd-assumptions-analyzer`) avait classé ce point « Needs External Research » (le moteur n'est pas
  présent dans le repo `vibeflow-os`, seulement cité en doctrine). Résolu en lisant directement les
  skills **installés sur la machine** : `$HOME/.claude/skills/gsd-ingest-docs/SKILL.md`,
  `$HOME/.claude/skills/gsd-import/SKILL.md`, et leurs workflows
  (`$HOME/.claude/get-shit-done/workflows/{ingest-docs,import}.md`). Confirmé : manifest
  `docs: [{path, type, precedence?}]`, `type` ∈ `ADR|PRD|SPEC|DOC`, gates BLOCKER natifs côté moteur
  (aucune réimplémentation nécessaire côté `vibeflow-dev`).
