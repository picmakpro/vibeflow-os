# consolidator — Consolidation Mémoire 4 Piliers

> Skill VibeFlow qui maintient les registres mémoire structurés (DECISIONS / LEARNINGS / BLOCKERS / EVALS / JOURNAL) scalables et propres au fil des sessions.

**Version** : v1.8.0
**Référence** : ADR-032 du Lab VibeFlow
**Iron Law** : *"La lecture d'un registre = lecture de l'index uniquement par défaut."*

---

## Quoi

Les registres mémoire VibeFlow grossissent en mode append-only (`/session-close` ADR-019). Sans consolidation, ils deviennent illisibles. Ce skill orchestre 4 mécanismes :

| Pilier | Problème adressé | Mécanisme |
|--------|------------------|-----------|
| 1. Indexation | Lecture index sans `#Ligne` = parcours body inutile | Convention header strict + script `reindex.sh` |
| 2. Archivage | Entrées obsolètes s'accumulent | Script `archive.sh` (3 critères AND) + hook SessionEnd async |
| 3. Fusion | Collisions IDs + doublons sémantiques | Skill `/consolidate --pillar=fusion` (LLM-based) |
| 4. Promotion | Learnings restent passifs (pas de comportement) | Skill `/consolidate --pillar=promote` (semi-auto + validation humaine) |

---

## Installation

Voir [INSTALL.md du repo racine](../INSTALL.md).

```bash
.claude/scripts/vibeflow-update.sh install consolidator
```

---

## Usage

### Audit (read-only)

```bash
.claude/scripts/reindex.sh --register=LEARNINGS --audit
# → JSON avec index_count, body_count, orphans
```

### Reindex apply (préserve Date + Resume + orphelins)

```bash
.claude/scripts/reindex.sh --register=DECISIONS --apply
# Backup auto. Idempotent.
```

### Archive auto (hook SessionEnd) ou manuel

```bash
.claude/scripts/archive.sh --dry-run --threshold-days=90
.claude/scripts/archive.sh --apply
```

### Détecter doublons

```bash
.claude/scripts/detect-duplicates.sh
# → candidats fusion (collisions + titres similaires)
```

### Détecter promotions

```bash
.claude/scripts/detect-promotions.sh
# → candidats learning → rule
```

### Skill complet via Claude Code

```
/consolidator
```

Le skill `consolidator` (chargé via le système de skills Claude Code) orchestre les 4 piliers de manière interactive.

---

## Tests

```bash
.claude/scripts/tests/test-consolidator.sh
# → 14 tests, doit passer 100%
```

---

## Structure

```
consolidator/
├── SKILL.md                          # Skill principal (449 lignes)
├── VERSION                            # v1.0.0
├── CHANGELOG.md                      # Historique
├── README.md                         # Ce fichier
├── references/
│   ├── indexation.md                 # Pilier 1
│   ├── archivage.md                  # Pilier 2
│   ├── fusion.md                     # Pilier 3
│   └── promotion.md                  # Pilier 4
└── scripts/
    ├── reindex.sh                    # Pilier 1
    ├── archive.sh                    # Pilier 2
    ├── detect-duplicates.sh          # Pilier 3
    ├── detect-promotions.sh          # Pilier 4
    └── tests/
        ├── test-consolidator.sh      # Suite 14 tests
        └── fixtures/
            ├── LEARNINGS-mini.md
            └── BLOCKERS-mini.md
```

---

## Compatibilité

- macOS (testé Darwin 25.4.0)
- Linux (compatible — utilise BSD/GNU utilities communes)
- bash 4+, python3 3.8+
- Claude Code v2+ (utilise hooks lifecycle + skills natifs)

---

## Limites v1.0.0

Voir `CHANGELOG.md` section "Limites connues".

---

## Support

Issues : tracker du repo `picmakpro/vibeflow-os`.
