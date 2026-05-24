# Registre des Learnings — Fixture Test

> Fixture synthétique pour test-consolidator.sh

---

## Index

| ID | Date | Categorie | Titre |
|----|------|-----------|-------|
| LRN-001 | 2026-01-01 | Architecture | Premier learning fixture |
| LRN-002 | 2026-01-02 | Process | Deuxième learning fixture |
| LRN-003 | 2026-01-03 | Tooling | Troisième learning (orphelin — pas de body) |
| LRN-004 | 2026-01-04 | Architecture | Quatrième learning fixture |

---

## LRN-001 : Premier learning fixture

**Date** : 2026-01-01
**Categorie** : Architecture
**Encode dans** : Non encode

### Situation

Premier scénario de test pour valider le parsing date + résumé.

### Apprentissage

Le script reindex.sh doit extraire cette première phrase comme résumé.

---

## LRN-002 : Deuxième learning fixture

**Date** : 2026-01-02
**Categorie** : Process
**Encode dans** : Non encode

### Situation

Deuxième scénario. Mot-clé operational ici : il faut toujours valider les corrections.

### Apprentissage

Test du detect-promotions sur learning operational.

---

## LRN-004 : Quatrième learning fixture

**Date** : 2026-01-04
**Categorie** : Architecture
**Encode dans** : Non encode

### Situation

Quatrième scénario. Note : LRN-003 est volontairement absent du body (orphelin).

### Apprentissage

Test fusion : ce learning et LRN-001 sont sur même catégorie Architecture.

---

## LRN-001 : Collision test (doublon)

**Date** : 2026-01-05
**Categorie** : Architecture

### Situation

Cette section a un ID en doublon avec LRN-001 ci-dessus. detect-duplicates.sh doit le signaler.

### Apprentissage

Test pilier 3 : détection collisions.
