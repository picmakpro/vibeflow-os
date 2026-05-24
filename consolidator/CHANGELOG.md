# CHANGELOG — consolidator

## [v1.0.0] — 2026-05-24

### Initial release

**Pilier 1 — Indexation**
- Convention `index header` avec colonne `#Ligne` strict
- Iron Law : "Lecture d'un registre = lecture de l'index uniquement par défaut"
- Script `reindex.sh` (modes `--audit`, `--dry-run`, `--apply`)
- Mode `--apply` préserve Date + Resume + orphelins (LRN-106 régression résolue Session 047)

**Pilier 2 — Archivage**
- Script `archive.sh` avec 3 critères AND (statut RESOLU/OBSOLETE/SUPERSEDED + age > 90j + 0 ref récente)
- Support accents français (`RÉSOLU`, `Différée`, `Dépréciée`...)
- Support champ `**Date ouverture** :` en plus de `**Date** :`
- Hook `SessionEnd` async pour archivage non-bloquant
- Allowlist `.claude/scripts/archive.allowlist` pour protéger entrées fondatrices
- Lock file 5min TTL pour race conditions sessions parallèles

**Pilier 3 — Fusion**
- Script `detect-duplicates.sh` (collisions IDs + similarité titres Jaccard)
- Skill manuel `/consolidate --pillar=fusion` (LLM-based, pas embeddings ML)
- Pattern inspiré Anthropic Auto Dream + grandamenium/dream-skill

**Pilier 4 — Promotion**
- Script `detect-promotions.sh` (operational keywords + frequency clusters)
- Skill manuel `/consolidate --pillar=promote` semi-auto
- Iron Law : aucun write dans `.claude/rules/*.md` sans validation humaine (ADR-031)

**Suite de tests**
- `scripts/tests/test-consolidator.sh` — 14 tests, 100% pass
- Fixtures synthétiques `LEARNINGS-mini.md` + `BLOCKERS-mini.md`
- Tests de régression LRN-106 inclus (préservation orphelins)

**Documentation**
- `SKILL.md` (449 lignes, charte ADR-029 ≤500L)
- 4 références : indexation / archivage / fusion / promotion

### Validé en production
- Lab VibeFlow (cobaye) — Session 047 — 5 registres processés (ADR 32/31/1, LEARNINGS 106/74/32, BLOCKERS 5/5/0, EVALS vide, ITERATION_LOG 45)
- 3 collisions LRN-090/091 fusionnées
- BLK-005 dette pré-existante documentée

### Références
- ADR-032 (parent) — Système Consolidation Mémoire 4 piliers
- ADR-009 — Architecture mémoire tiered (parent historique)
- ADR-029 — Charte densité agents
- ADR-031 — Garde-fou support runtime
- LRN-105 — 4 piliers complémentaires
- LRN-106 — Audit avant fix (méta-learning Session 047)

### Limites connues v1.0.0
- ITERATION_LOG format Session (sans index) non géré (acceptable, format spécial)
- Compteurs JSON peuvent afficher "0\n0" cosmétiquement quand fichier vide (non bloquant)
- BLK-005 : 32 LRN orphelins (index sans body) préservés mais à compléter ultérieurement
