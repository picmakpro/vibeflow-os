---
name: placement-lib-partagee-planning-core
description: Une brique partagée entre modules va dans planning-core, pas dans conductor — sa fermeture de dépendances est réduite à lui-même
metadata:
  type: project
---

Fermetures mesurées (`plugin/_internal/resolve-deps.sh`, 2026-08-04) :

- `planning-core` → **lui-même seul** (`"requires": []`)
- `conductor` → requiert planning-core, validator, skill-creator
- `dev-orchestrator` → requiert conductor, donc planning-core par transitivité

**Conséquence contre-intuitive :** `conductor` est le socle *de gouvernance*, mais ce n'est **pas**
le bon hôte pour du code partagé. Un fichier posé dans conductor et sourcé par planning-core casse
un lab qui installe planning-core seul — configuration parfaitement légale. L'inverse est sûr :
posé dans **planning-core**, il est disponible pour les trois sans **aucune** dépendance
inter-modules nouvelle.

**Why:** quatre gates de la Phase 24 (3 modules différents) portaient chacun leur copie d'une même
politique ; elles avaient divergé en un seul lot de travail parallèle. L'extraction demandait un
hôte, et le réflexe « conductor est le socle » aurait introduit une régression invisible.

**How to apply:** avant d'extraire une brique partagée, mesurer la fermeture de chaque consommateur
avec `resolve-deps.sh` — ne jamais déduire la direction de la dépendance du rôle apparent du module.
Résoudre le chemin dans les deux dispositions (voisin à plat en lab installé, `../../<mod>/scripts/`
dans le dépôt), cf. [[installeur-deux-familles-agents]]. Et prévoir le cas « brique introuvable » :
fail-closed pour un gate, fail-open **mais jamais muet** pour un hook SessionStart.
