---
quick_id: 261001-urj
slug: fix-audit-final-securite-phase-45
date: 2026-10-01
mode: validate
workstream: gouvernance
---

# Quick 261001-urj — correction ciblée de l'audit de sécurité final, Phase 45

Mandat du manager vf-dev-manager (mission vf-dev-manager-p45-exec, nœud fix-audit-final). Findings F-01 à F-08 de l'audit demandé par Willy en session principale le 2026-10-01.

## Tâches

1. F-01 (haute) : borner la couche shell de repli de `hooks.json` (et la copie de référence du canary) à 4096 caractères par valeur ; au-delà, décider sur le cwd (GATE-03 tenu). Cas rouge puis vert R-BORNE-01 et mutants.
2. F-03 (moyenne) : désarmer le minuteur après la décision du cœur (émission et sortie) ; l'échéance de 8 s reste intacte avant l'émission. R-DEFS-06 et mutants.
3. F-02 (moyenne) : G6 exige que le nouveau `config.json` satisfasse aussi le motif du repli, constante partagée `MOTIF_ADHESION_REPLI` comparée au grep de `hooks.json`. R-ADH-REPLI et mutants. Mesure en lecture seule des `config.json` réels.
4. F-04 à F-08 : limites (aa) à (ae), (z) réécrite, limite T-45-61 dans la section G7, formulation de `--tentative`, entrée v2.9.0 du CHANGELOG (sans bump).
5. Rejouer les suites au premier plan, le contrôle de marqueur, la zéro-régression dev, puis le rejeu réel post-audit (lecture seule) et sa section dans `45-REJEU-FINAL.md`.

## Contraintes

Aucun cas ni mutant supprimé ou affaibli (Q-ARM, Willy, AskUserQuestion session principale, 2026-09-30). `ARMEMENT_*`, `TABLE_ATTENDUE`, `VERSION`, `module.json`, `STATE.md`, `ROADMAP.md` intacts.
