# Registre des Blockers — Fixture Test

---

## Index

| ID | Date | Titre | Statut |
|----|------|-------|--------|
| BLK-001 | 2026-01-01 | Blocker résolu fixture | RÉSOLU 2026-01-15 |
| BLK-002 | 2026-01-02 | Blocker actif fixture | ACTIF |

---

## BLK-001 — Blocker résolu fixture

**Date ouverture** : 2026-01-01
**Statut** : RÉSOLU 2026-01-15
**Sévérité** : Moyenne

### Description

Test : ce BLK est RÉSOLU et a plus de 90 jours → candidat archivage si threshold respecté.

### Cause Racine

N/A — fixture.

### Solution

Test archive.sh.

---

## BLK-002 — Blocker actif fixture

**Date ouverture** : 2026-01-02
**Statut** : ACTIF
**Sévérité** : Haute

### Description

Ce BLK est ACTIF → ne doit JAMAIS être archivé même si vieux.

### Cause Racine

N/A — fixture.

### Solution

Test négatif : archive.sh ne doit pas le marquer archivable.
