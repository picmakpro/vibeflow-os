# Template : Registre des Décisions

> Fichier cible : `.claude/memory/DECISIONS.md`
> Source : VibeFlow Core — Registre 1 (DECISIONS)
> Scalabilite : ADR-009 — Index + Archive + Rotation aux Jalons

---

## Instructions de gestion

### Index obligatoire (format canonique v2)
Le fichier commence toujours par le tableau index ci-dessous. L'agent lit l'index d'abord, puis charge le detail d'une decision specifique avec `offset`/`limit` (colonne `#Ligne`) seulement si necessaire pour la tache en cours. **Ne jamais lire le fichier en entier — lire l'index puis cibler la decision voulue avec offset/limit.**

Regles de l'index :
- `#Ligne` = numero de ligne du header `## DEC-XXX :` dans le corps du fichier
- `Resume` ≤ 80 caracteres
- Tri par date decroissante (la plus recente en haut)

### Archivage
Quand une decision est depreciee ou supersedee, la deplacer dans `.claude/memory/archive/decisions-archive.md` et mettre a jour l'index (Resume → `Archivee → voir archive`).

### Rotation aux jalons
A chaque jalon majeur (fin MVP, V2, etc.) : passer en revue toutes les decisions, archiver celles qui ne sont plus operationnellement pertinentes, conserver celles encore actives.

---

## Index

| ID | Date | Titre | #Ligne | Resume |
|----|------|-------|--------|--------|
| DEC-000 | [DATE] | [Etat initial du projet] | [N] | [Resume ≤ 80 caracteres] |

---

## DEC-XXX : [Titre]

**Date** : [DATE]
**Statut** : Proposee | En discussion | Validee | Rejetee | Deprecee | Supersedee par DEC-YYY
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
>  quels criteres ont pese, quelles decisions/Blockers/Learnings consultes]

### Decision
[Option choisie et resume du pourquoi]

### Consequences
**Positives** :
**Negatives** :

### Code Impacte
- [Fichiers/modules concernes]

### Rules Associees
- [.claude/rules/ impactees]
