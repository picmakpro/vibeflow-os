# Phase 9: Spike transposition jcode (mémoire + swarm) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-20
**Phase:** 9-Spike transposition jcode (mémoire + swarm)
**Areas discussed:** Lab témoin, Périmètre, Champs, Barre go/no-go

---

## Lab témoin

| Option | Description | Selected |
|--------|-------------|----------|
| Ce repo (vibeflow-os) | Mémoire de session de ce repo. Peu d'entrées, boucle courte, zéro risque prod. | ✓ |
| Un lab réel connecté | WillHosting/Reviz, LinkedinBot… mesure plus réaliste mais projet vivant à isoler. | |
| Lab témoin jetable dédié | Lab factice ~15-20 entrées synthétiques. Contrôle total, entrées moins authentiques. | |

**User's choice:** Ce repo (vibeflow-os)
**Notes:** Compensation prévue si le signal est trop faible : ajouter quelques entrées synthétiques calibrées.

---

## Périmètre

| Option | Description | Selected |
|--------|-------------|----------|
| Mémoire seule (swarm différé) | Phase 9 = spike mémoire pur ; swarm = second spike conditionné. | |
| Mémoire + cadrage swarm léger | Spike mémoire + mini-cadrage écrit (non implémenté) du lock de driver. | ✓ |

**User's choice:** Mémoire + cadrage swarm léger
**Notes:** Le cadrage swarm est écrit, non implémenté — l'invariant « swarm non implémenté » de la phase tient.

---

## Champs

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal — 3 gestes | trust + confidence + superseded_by + décroissance par catégorie. | ✓ |
| Complet — 5 champs | Ajoute reinforced[] + status/arêtes typées. Plus lourd, risque de biaiser vers « trop cher ». | |

**User's choice:** Minimal — 3 gestes
**Notes:** reinforced[] et arêtes typées restent candidats pour l'ADR si le spike est concluant.

---

## Barre go/no-go

| Option | Description | Selected |
|--------|-------------|----------|
| Round-trip auto sans édition humaine | Passe consolidator lit/recalcule/réécrit sans intervention + supersession archivée. Critère binaire. | ✓ |
| Jugement qualitatif de valeur | Évaluation subjective du gain de rappel. Plus riche mais non binaire. | |

**User's choice:** Round-trip auto sans édition humaine
**Notes:** Critère binaire retenu pour éviter une décision floue ; la valeur qualitative reste un bonus documenté.

---

## Claude's Discretion

- Mapping catégories jcode (`Fact/Preference/Entity/Correction`) → types VibeFlow (`user/feedback/project/reference`) : à proposer au research/plan.
- Forme précise des clés YAML du frontmatter enrichi, sous seuils de densité ADR-029.

## Deferred Ideas

- Implémentation du volet swarm (lock de driver + DAG) → propre phase, conditionnée aux collisions observées (ADR-048/049).
- Champs mémoire étendus (reinforced[], arêtes Contradicts/DerivedFrom, clusters).
- Pipeline mémoire par-tour, embeddings/RRF/sidecar → rejetés (pas de runtime intra-session Claude Code).
