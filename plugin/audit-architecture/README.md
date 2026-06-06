# audit-architecture (module vibeflow-os)

> **Type** : single-skill + references
> **Version** : v1.0.0
> **ADR** : ADR-036 (Doctrine Audit Architecture — structures d'audit multi-couches universelles)

Méta-skill **concepteur d'architecture d'audit**. Pour N'IMPORTE QUEL process qui transforme
un brief en output (carrousel, script vidéo, dossier, feature de code, séquence de vente...),
il **dérive** la structure d'audit multi-couches adaptée, puis la **force**.

Pendant que `software-architecture` structure le CODE, `audit-architecture` structure les AUDITS.
Il opérationnalise le principe Core **P8 — Évaluer** *au niveau process* (pas seulement par sprint).

## Le primitif universel

```
COUCHE = (Dimension) × (Auditeur indépendant) × (Rubric) × (Verdict bloquant) × (Anti-boucle)
STRUCTURE D'AUDIT = chaîne séquencée de couches, dérivée du brief
```

Le forçage ne se limite pas au code déterministe : il existe le long d'un **spectre d'enforcement**
(script ↔ test ↔ checklist ↔ rubric LLM-judge), tous également bloquants via une **architecture de refus**.

## Contenu

| Fichier | Cible installation | Rôle |
|---------|--------------------|------|
| `SKILL.md` | `.claude/skills/audit-architecture/SKILL.md` | Doctrine + méthode 4 temps + spectre enforcement + matérialisation |
| `references/*.md` | `.claude/skills/audit-architecture/references/` | Primitif, méthode, spectre, design de rubric, exemples cross-domaines |

## Universel, pas déterministe

Le cœur du skill — **la décision de quelles couches** un process doit avoir — est du **raisonnement
LLM**, pas un script. C'est ce qui le rend universel (un bash ne saura jamais auditer la couche
visuelle d'un carrousel). Les seuls artefacts déterministes sont *générés par couche*, quand la
dimension est mesurable.

## Intégration vibeflow-validator

Injecté dans le champ `skills:` de l'agent `vibeflow-validator`. Ajoute un mode **scan de lab** :
énumérer les process → reconstituer leur structure d'audit actuelle → différer avec la cible →
reporter les trous. Conformément à ADR-031, le skill **conçoit et propose** ; la **matérialisation**
(générer les auditeurs + règles) est un acte humain-validé, séparé du scan.

## Installation

```bash
.claude/scripts/vibeflow-update.sh install audit-architecture
```

## Références

- ADR-036 — Doctrine Audit Architecture (Lab VibeFlow)
- Core P8 — Évaluer la qualité cognitive (registre EVALS)
- LRN-118 — enforcement > prose (un garde-fou non exécuté n'existe pas)
- Module frère : `software-architecture` (P9, structure du code)
- Preuve terrain : ContentFlow Lab (chaîne d'audit 5 couches CLA/HUM/VIS/REV)
