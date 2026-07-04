# CHANGELOG — consolidator

## [v1.2.0] — 2026-07-04 (ADR-043 — gouvernance scripturale)

### Ajouté
- `guard-read-registres.sh` — hook PreToolUse(Read) : DENY toute lecture d'un registre canonique
  sans offset/limit au-delà de 150 lignes. L'Iron Law index-first est machine-enforced.
- `check-registres.sh` — lint format (## Index + #Ligne, cohérence index↔body, doublons).
  Modes `--strict` (gate init vf-new-lab Gate C) / `--hook` (SessionStart informatif).
- `post-edit-reindex.sh` — hook PostToolUse(Edit|Write) : reindex --apply automatique du registre
  édité + rotation des backups (3 max). L'index ne dérive plus.
- `hooks/hooks.json` — les 4 hooks (guard-read, post-edit-reindex, check-registres, archive
  SessionEnd) sont MERGÉS AUTOMATIQUEMENT dans `.claude/settings.json` à l'install (merge-hooks.sh).

### Modifié
- `reindex.sh` — bootstrap : crée le bloc `## Index` s'il est absent (registre v1/sortie d'init),
  avec 2e passe pour recaler les #Ligne. Avant, --apply était silencieusement sans effet.
- `detect-duplicates.sh` — couvre désormais DECISIONS.md (gap).
- Canon DECISIONS.md/DEC-XXX dans SKILL/README/références ; spec index alignée sur reindex.sh
  (5 colonnes, sans Tags) ; note obsolète « PreToolUse(Read) pas supporté » corrigée (le deny EST
  supporté — vérifié doc Claude Code 2.1.201).

### Tests
- `test-guard-read-registres.sh` (8), `test-check-registres.sh` (8) + non-régression 14/14.

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

## v1.1.0 — 2026-06-04

- reindex.sh : support BDR (registre fork BusinessFlow) dans les mappings par defaut + mecanisme de fork-config optionnel (`registers.conf.sh` sourced, surcharges `register_file_custom`/`id_pattern_custom`) — remontee BLK-005 point 4 du BFL.
- archive.sh : BDR.md ajoute a la liste des registres scannes.
- infrastructure-audit : whitelist Claude Code 2.1.162.
