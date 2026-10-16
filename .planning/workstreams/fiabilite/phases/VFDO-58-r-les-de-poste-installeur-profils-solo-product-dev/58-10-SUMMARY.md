---
phase: 58-r-les-de-poste-installeur-profils-solo-product-dev
plan: 10
status: complete
requirements: [RLPO-12]
---

# 58-10 — versions des quatre modules, sans release

Arbitrages : P58-D-01..14, arbitrage Samuel, AskUserQuestion session principale, 2026-10-16.

| Module | Avant | Après | Niveau |
|---|---|---|---|
| conductor | v1.49.0 | v1.50.0 | minor |
| dev-orchestrator | v2.28.0 | v2.28.1 | patch |
| mobile-test | v1.0.3 | v1.0.4 | patch |
| mobile-test-team | v1.4.6 | v1.4.7 | patch |

- VERSION, `.version` de `module.json`, en-tête `**Version**` du README et entrée datée 2026-10-16 du CHANGELOG, « non publiée »,
  pour chacun ; clé `roles` de 58-01 conservée (`dev-orchestrator mobile-test mobile-test-team`).
- `scripts/check-version-sync.sh` : points 6 (triade, 17 modules) et 8 (en-têtes README) verts, filtre mécanique = 2. Seul écart restant :
  compte de suites des README racine (`102 suites` ≠ réel 108), réaligné par le plan 58-11.
- Aucune release : `VERSION` racine, `plugin/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` et
  `plugin/planning-core/module.json` inchangés depuis la merge-base ; aucun tag.
