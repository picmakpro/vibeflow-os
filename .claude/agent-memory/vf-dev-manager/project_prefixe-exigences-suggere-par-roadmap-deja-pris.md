---
name: prefixe-exigences-suggere-par-roadmap-deja-pris
description: Le ROADMAP suggère lui-même des préfixes d'exigences déjà pris par une famille vivante — PORT-xx proposé pour la Phase 38 collisionne avec PORT-01..05 de la Phase 30
metadata:
  type: project
---

Un préfixe d'ID d'exigence **suggéré par le ROADMAP n'est pas un préfixe libre**. Vérifier
l'espace de noms complet avant de graver une famille, même quand le document de cadrage la propose.

**Why:** mesuré Phase 38 (2026-08-28). La section Phase 38 du ROADMAP écrit noir sur blanc
« candidats : **PORT-xx** canal, MIGR-xx migration, FIDE-xx gate ». Or `PORT` est **déjà pris** par
la Phase 30 (« Portabilité Windows II », `PORT-01..05`), et `PORT-05` est un **gate CI vivant**
encore cité par les Phases 32 et 33 (12 occurrences dans `32-03-PLAN.md`). Écrire `PORT-01` pour la
Phase 38 aurait écrasé sémantiquement un ID actif, et le gate
`plugin/dev-orchestrator/scripts/check-requirements-survival.sh` (armé ici par le fichier-sentinelle
versionné `.planning/.requirements-survival-armed`) rend rouge sur un ID qui disparaît du ledger
sans issue tracée. Les deux autres suggestions (`MIGR`, `FIDE`) étaient bien libres — la moitié
d'une suggestion juste est le piège : elle donne confiance dans l'autre moitié.

**How to apply:** avant de nommer une famille d'exigences, dériver l'espace de noms occupé :
```
rtk proxy grep -ohE '\b[A-Z][A-Z0-9]{1,9}-[0-9]{2}\b' .planning/REQUIREMENTS.md \
  | awk -F- '{print $1}' | sort -u
```
36 préfixes occupés au 2026-08-28. Comparer les **ensembles**, jamais supposer depuis le ROADMAP
(mémoire [[ecart-de-chiffre-comparer-les-ensembles]]). Même famille de défaut que
[[artefacts-descriptifs-non-testes]] : un artefact descriptif (ici une suggestion de cadrage) que
rien ne vérifie dérive de la réalité qu'il prétend décrire.
