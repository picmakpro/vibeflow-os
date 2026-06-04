# feature-dev-gates (module vibeflow-os)

> **Type** : rules-only (path-scopée, composable)
> **Version** : v1.0.0
> **ADR** : ADR-037 (Adoption Nyquist Layer + Decision Coverage Gate — import GSD)

Deux **gates de développement de feature**, machine-enforced via une rule **path-scopée**.
Importés du framework GSD, alignés sur le principe **enforcement > prose** (LRN-118).

- **Gate Nyquist** : chaque critère d'acceptation doit avoir une **commande de vérification automatisée** (pass/fail) AVANT le code → empêche la complétion hallucinée.
- **Gate Decision Coverage** : chaque décision (ADR/DEC-XXX) doit être portée par une tâche/contrat → empêche la dérive décision↔code.

## Pourquoi une rule path-scopée

C'est le **déclencheur fiable** : la rule se charge automatiquement dès qu'on touche du code applicatif (`src/**`, `app/**`, `lib/**`, `features/**`), indépendamment des triggers manuels (souvent jamais invoqués) et de l'activation on-demand d'un skill de clarification (conditionnelle). Le filet déterministe que les autres véhicules ne garantissent pas.

## Contenu

| Fichier | Cible installation | Rôle |
|---------|--------------------|------|
| `rules/feature-dev-gates.md` | `.claude/rules/` | Rule path-scopée portant les 2 gates |

## Articulation (côté projet cible)

- Complément naturel du skill `clarity-feature` (qui *matérialise* la spec : critères + commandes de vérif + table de couverture des décisions).
- Complément des triggers `plan-sprint` / `implement-feature` (gates pour l'usage explicite).
- Les commandes de vérif Nyquist sont exécutées par `tdd` + `verification-before-completion`.

## Installation

```bash
bash _internal/vibeflow-update.sh add feature-dev-gates
```
