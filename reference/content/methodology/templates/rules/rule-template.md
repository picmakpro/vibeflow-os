# Template : Rule Contextuelle

> Fichier cible : `.claude/rules/[domaine].md`
> Source : VibeFlow Core v4.1, Section 5 (Rules contextuelles)

```markdown
---
paths:
  - "[glob pattern 1]"
  - "[glob pattern 2]"
---

# Regles [NOM_DOMAINE]

## ADR Applicables
- **ADR-XXX** : [Titre] — [Impact sur ce domaine]

## Patterns Obligatoires
[Patterns specifiques a ce domaine]

## Pieges Connus (Extrait BLOCKERS)
- **BLK-XXX** : [Resume] — [Comment l'eviter ici]

## Dependances
[Packages, versions, pre-requis]

## Tests Specifiques
[Commandes de test pour ce domaine]
```

## Notes

- **Tier 1** (global.md) : Present des le bootstrap, regles universelles
- **Tier 2** (emergent) : Genere quand un pattern se repete 3+ fois dans les checkpoints
- **Tier 3** (par domaine) : Pour projets matures (10+ features, Sprint 5+)
