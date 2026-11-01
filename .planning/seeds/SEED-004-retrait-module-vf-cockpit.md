---
id: SEED-004
status: dormant
planted: 2026-11-01
planted_during: equipe-produit-v1.0 (exploration cockpit, avant création du jalon vibeflow-v2.0)
trigger_when: "à la livraison (release) du cockpit floorplan dans le jalon vibeflow-v2.0"
scope: chore
source_spec: .planning/notes/2026-11-01-cockpit-facettes.md
---

# SEED-004 : Retrait du module `vf-cockpit` (page Mermaid)

Arbitrage Samuel, AskUserQuestion session principale, 2026-11-01 : le cockpit floorplan remplace
le module `vf-cockpit` v1.0 (branche `feat/vf-cockpit-module`, rapport de mission `12c6d19d`,
jamais mergé dans `main`).

À la livraison du cockpit floorplan :
- fermer la branche `feat/vf-cockpit-module` (et `origin/`) à la livraison de la Phase 67
  (arbitrage Samuel A3, AskUserQuestion session principale, 2026-11-01) — la graine reste dormante
  d'ici là ; fermer ne veut pas dire supprimer avant d'avoir relu ce qui mérite d'être repris :
  `DESIGN-SPEC.md`, le drawer, le markdown léger, le surlignage de diff, et la doctrine de
  réassurance du verrou périmé (`859f8be6`) ;
- vérifier qu'aucun catalogue, manuel ou compteur de README ne cite encore `vf-cockpit` comme
  module distribué (la branche les avait mis à jour : `b4aa578a`, `a2f1ea56`) ;
- doctrine : ne supprimer que les branches de Samuel (sobriété de méthode, Phase 41.3).
