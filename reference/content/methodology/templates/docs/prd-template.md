# Product Requirements Document — [NOM_PROJET]

> Fichier cible : `docs/PRD.md`
> Le PRD definit le QUOI et le POURQUOI — produit, utilisateurs, exigences.
> La technique (stack, schema, conventions) est dans `docs/REFERENCE.md`.

## 1. Vision Produit

### Probleme
[Quel probleme ce produit resout]

### Solution
[Comment ce produit resout le probleme]

### Utilisateurs Cibles
[Qui utilise ce produit — personas, segments]

## 2. User Stories

### Epic 1 : [Nom]

#### US-001 : [Titre]
**En tant que** [role]
**Je veux** [action]
**Afin de** [benefice]

**Criteres d'acceptation** :
- [ ] [Critere 1]
- [ ] [Critere 2]

**Priorite** : Must Have | Should Have | Could Have | Won't Have

### Epic 2 : [Nom]
...

## 3. Exigences Non-Fonctionnelles

| Exigence | Seuil | Mesure |
|----------|-------|--------|
| Performance (LCP) | < 2.5s | Lighthouse |
| Disponibilite | 99.9% | Monitoring |
| Securite | OWASP Top 10 | Audit |

## 4. Contraintes

- [Contrainte 1]
- [Contrainte 2]

## 5. Hors Perimetre (Explicite)

- [Ce qui n'est PAS dans le scope]

## 6. Roadmap

| Sprint | Objectif | User Stories |
|--------|----------|-------------|
| Sprint 1 | MVP | US-001, US-002 |

---

> **Relation avec les autres docs** :
> - `docs/REFERENCE.md` = Comment c'est construit (stack, schema, conventions). Pointe ici pour les US.
> - `docs/SPEC-[feature].md` = Plan d'execution d'une feature. Pointe ici pour les requirements.
