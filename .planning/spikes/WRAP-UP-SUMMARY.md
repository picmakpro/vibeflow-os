# Spike Wrap-Up Summary

**Date:** 2026-11-01
**Spikes processed:** 1
**Feature areas:** Cockpit Code + Projet
**Skill output:** `.claude/skills/spike-findings-vibeflow-os/` (arbre principal du dépôt, ignoré par git)

## Processed Spikes
| # | Name | Type | Verdict | Feature Area |
|---|------|------|---------|--------------|
| 002 | cockpit-code-projet | standard | VALIDATED | Cockpit Code + Projet |

Le spike 001 (`cockpit-live`) vit sur la branche `spike/cockpit-live` et n'est pas dans cet
arbre : il n'est pas emballé ici.

## Key Findings

- Le viewer de floorplan est générique (nœuds hiérarchiques, fichiers rattachés, liens typés,
  ordre des données respecté par ELK). Un onglet Projet s'y modélise au format
  `floorplan/graph@1` sans réécriture : 5 patchs de quelques lignes (P1-P5, `VENDORED.txt`) et une
  extension par `window.Floorplan`.
- Assemblage complet en 2,3 s, sans LLM, sur vibeflow-os : Code 528 fichiers et 1 244 liens
  (contre 7 pour floorplan seul) grâce à l'extracteur VibeFlow (dispatch `Agent(...)`, scripts
  sourcés ou appelés) ; Projet 11 jalons, 65 phases, 263 plans, 281 exigences, 25 DAG ; pont de
  458 fichiers reliés aux plans qui les ont touchés.
- Pièges de parsing de `.planning/` : `**Goal:**` (deux-points dans le gras), `$` multiligne,
  plages de jalons composées, `blocked` de `dag.sh` = en attente (pas bloqué), phases closes sans
  SUMMARY (la case cochée fait foi).
- Limites ouvertes pour la vraie phase : questions sur l'onglet Projet, statuts en direct
  (verrou, agents en vol), chrome et types en anglais, Recent work à tirer du diff réel, densité
  des liens plan → exigences, report des patchs à chaque synchro amont.
