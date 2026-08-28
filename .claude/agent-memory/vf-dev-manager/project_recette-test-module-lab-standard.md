---
name: recette-test-module-lab-standard
description: Un test de module vibeflow-os n'est qualifié que joué en disposition « lab standard » — source + index vide laissent passer les régressions
metadata:
  type: project
---

`test-dev-orchestrator.sh` (et ses jumeaux par module) se joue dans **quatre dispositions**, et
seules les deux dernières qualifient réellement un changement :

1. source (le repo tel quel) · 2. source + index GSD vidé (simulation CI) · 3. lab installé avec
les seuls modules de l'étape · 4. **lab standard** — le module installé *à côté* des autres
(`conductor`, `planning-core`, `validator`…).

**Why:** en lab, l'installeur pose les `skills/`, `agents/` et `references/` de TOUS les modules
**à plat** dans `.claude/`. Or certains axes (T5 densité, T11 résidu Reviz) balaient ces dossiers
sans se borner au module testé : un fichier d'un module voisin peut rendre la suite rouge chez
l'utilisateur alors qu'elle est verte sur le repo. Constaté en Phase 12 (2026-07-25) : la recette
« source + index vide » du plan a laissé passer deux fois le même piège, seule la disposition
« lab standard » l'a révélé.

**How to apply:** quand une étape touche un script de test de module, ou les `skills/`/`agents/`/
`references/` d'un module, exiger dans la recette les 4 dispositions et lire le résultat de la 4ᵉ
avant de conclure. Un KO qui n'apparaît qu'en lab standard est un vrai KO utilisateur — vérifier
s'il est **préexistant** (donc hors périmètre, à remonter) ou **introduit** par l'étape (à
corriger). Voir aussi [[check-agents-vacuous-green]].
