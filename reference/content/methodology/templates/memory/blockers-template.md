# Template : Registre des Blockers (Obstacles & Resolutions)

> Fichier cible : `.claude/memory/BLOCKERS.md`
> Source : VibeFlow Core v4.1, Section 4 — Registre 2 (Blockers)
> Scalabilite : ADR-009 — Index + Archive + Rotation aux Jalons

---

## Instructions de gestion

### Index obligatoire
Le fichier commence toujours par un tableau index. L'agent lit l'index d'abord pour verifier si un blocker similaire a deja ete rencontre.

### Lien learning
Chaque blocker resolu DOIT generer un learning associe (champ `Learning associe`). C'est la filiation qui permet d'archiver le blocker sans perdre la connaissance.

### Archivage
Les blockers resolus depuis > 5 sprints sont candidats a l'archivage dans `.claude/memory/archive/blockers-archive.md`. Le learning associe reste en L2 tant qu'il est pertinent.

### Rotation aux jalons
A chaque jalon majeur : archiver tous les blockers resolus (leur connaissance vit dans les learnings).

---

## Index

| ID | Date | Sprint | Titre | Statut | Learning |
|----|------|--------|-------|--------|----------|

---

## BLK-XXX : [Titre Court]

**Date** : [DATE]
**Sprint** : [Sprint X]
**Statut** : Actif | En cours | Resolu | Contourne
**Temps Perdu** : [Xh]
**Severite** : Critique | Haute | Moyenne | Basse
**Source** : [Agent qui a trouve/resolu | Escalation sub-agent]
**Learning associe** : [LRN-XXX] ou [A creer]

### Symptome
[Message d'erreur ou comportement observe]

### Contexte
[Qu'est-ce qu'on faisait quand c'est arrive]

### Hypotheses Eliminees (Extended Thinking)
> 1. ~~[Hypothese]~~ — Elimine car [raison]
> 2. **[Hypothese confirmee]** — [raison]

### Cause Racine
[Pourquoi ca s'est produit]

### Solution Appliquee
[Code ou configuration qui a resolu]

### Prevention Future
[Rule ajoutee, pattern documente]

### Fichiers Impactes
[Liste des fichiers modifies]
