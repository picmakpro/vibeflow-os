# Template : Registre des Decisions d'Architecture (ADR)

> Fichier cible : `.claude/memory/ADR.md`
> Source : VibeFlow Core v4.1, Section 4 — Registre 1 (ADR)
> Scalabilite : ADR-009 — Index + Archive + Rotation aux Jalons

---

## Instructions de gestion

### Index obligatoire
Le fichier commence toujours par un tableau index. L'agent lit l'index d'abord, puis charge le detail d'une ADR specifique seulement si necessaire pour la tache en cours. **Ne jamais lire le fichier en entier sauf au checkpoint.**

### Archivage
Quand une ADR est depreciee ou supersedee, la deplacer dans `.claude/memory/archive/adr-archive.md` et mettre a jour l'index (statut → `Archivee → voir archive`).

### Rotation aux jalons
A chaque jalon majeur (fin MVP, V2, etc.) : passer en revue toutes les ADR, archiver celles qui ne sont plus operationnellement pertinentes, conserver celles encore actives.

---

## Index

| ID | Date | Titre | Statut |
|----|------|-------|--------|
| ADR-000 | [DATE] | [Etat initial du projet] | Validee |

---

## ADR-XXX : [Titre]

**Date** : [DATE]
**Statut** : Proposee | En discussion | Validee | Rejetee | Deprecee | Supersedee par ADR-YYY
**Decideur** : Lead Agent (valide par [Nom])
**Contexte** : [Sprint/Phase]
**Thinking Level** : think | think hard | ultrathink

### Probleme
[Description du probleme a resoudre]

### Options Considerees
| Option | Avantages | Inconvenients |
|--------|-----------|---------------|

### Raisonnement (Capture depuis Extended Thinking)
> [Chaine logique complete : pourquoi les options sont eliminees,
>  quels criteres ont pese, quelles ADR/Blockers/Learnings consultes]

### Decision
[Option choisie et resume du pourquoi]

### Consequences
**Positives** :
**Negatives** :

### Code Impacte
- [Fichiers/modules concernes]

### Rules Associees
- [.claude/rules/ impactees]
