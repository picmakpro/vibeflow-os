# Template : Registre des Learnings (Apprentissages)

> Fichier cible : `.claude/memory/LEARNINGS.md`
> Source : VibeFlow Core v4.1, Section 4 — Registre 3 (Learnings)
> Scalabilite : ADR-009 — Index + Archive + Rotation aux Jalons

---

## Instructions de gestion

### Index obligatoire
Le fichier commence toujours par un tableau index. L'agent lit l'index d'abord, puis charge le detail d'un learning specifique seulement si necessaire. **Ne jamais lire le fichier en entier sauf au checkpoint.**

### Promotion en rule
Quand un learning est suffisamment operationnel pour devenir une instruction permanente, le promouvoir en rule dans `.claude/rules/`. Remplir le champ `Encode dans:` et considerer l'archivage du learning.

### Archivage
Quand un learning est integre dans une rule OU n'est plus operationnellement pertinent (> 10 sprints), le deplacer dans `.claude/memory/archive/learnings-archive.md` et mettre a jour l'index.

### Rotation aux jalons
A chaque jalon majeur (fin MVP, V2, etc.) : trier les learnings — operationnels → promouvoir en rules, informatifs pertinents → garder, historiques → archiver.

### Lien avec les blockers
Un blocker resolu genere souvent un learning. Referencez le blocker dans le champ `Decouvert lors de` pour tracer la filiation.

---

## Index

| ID | Date | Categorie | Titre | Encode dans |
|----|------|-----------|-------|-------------|

---

## LRN-XXX : [Titre Memorable]

**Date** : [DATE]
**Categorie** : Performance | DX | Architecture | Process | Tool | Methodologie | Research | Terrain
**Decouvert lors de** : [Contexte / BLK-XXX si issu d'un blocker]
**Encode dans** : [.claude/rules/xxx.md] ou [Non encode]

### Contexte
[Situation initiale]

### Apprentissage
[Ce qu'on a appris]

### Avant / Apres
[Code ou process compare]

### Resultat
[Metriques d'amelioration si applicable]

### Application
[Rule ou c'est encode + description]
