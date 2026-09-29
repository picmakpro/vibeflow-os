---
name: libelle-de-cas-couple-au-verify-du-plan
description: Renommer un cas de test de ce dépôt peut casser la sonde `<verify>` du plan qui l'a créé — les plans cherchent les libellés à l'octet près ; vérifier exécuté vs non exécuté avant de renommer
metadata:
  type: project
---

Dans ce dépôt, les plans GSD posent des sondes `<automated>` qui cherchent les **libellés littéraux**
des cas de test qu'ils prescrivent (`for lab in ABSOLU-64 BASCULE-REL-ABS Q2-NOBASE; do … index($0, L)`),
précisément pour qu'un cas jamais écrit soit détectable. Conséquence : **un libellé de cas est une
interface**, pas un détail de rédaction. Le renommer casse silencieusement la sonde du plan.

**Why:** rencontré le 2026-09-23 en renommant `BASCULE-REL-ABS` → `OBS-REL-ABS` dans
`plugin/conductor/scripts/tests/test-check-state-integrity.sh` (un cas vert des deux côtés qui
portait un nom de témoin de bascule). Le plan `41.1-09-PLAN.md` cherchait encore l'ancien littéral.

**How to apply:** avant tout renommage d'un libellé de cas,
1. **balayer tous les fichiers suivis en `awk`**, pas seulement `git grep` — le mandat qui m'a
   dispatché avait lui-même raté trois trailers de la même branche sur une seule commande ;
2. trancher sur **exécuté vs non exécuté** : un plan avec son `-SUMMARY.md` posé est exécuté, sa
   sonde ne sera pas rejouée (vérifié : **aucun gate ni job CI de ce dépôt ne rejoue les blocs
   `<automated>` des plans**) → renommage possible. Un plan **sans** SUMMARY est en attente
   d'exécution : renommer le ferait rougir → **s'arrêter et remonter**, ne pas éditer le plan ;
3. quand on renomme malgré une sonde d'un plan déjà exécuté, **tracer la divergence dans le
   SUMMARY** de ce plan (l'artefact d'exécution est éditable, le plan ne l'est pas dans un mandat
   de correction ciblée) en nommant l'ancien et le nouveau libellé.

Corollaire de doctrine, tranché le 2026-09-23 : un cas **vert des deux côtés** ne se supprime pas et
ne se rend pas discriminant de force — *le coût n'est pas le cas inutile, c'est le crédit qu'on lui
accorde*. On garde sa mécanique et on **corrige son nom** pour qu'il ne se fasse pas compter comme
une garde. Voir [[preuve-incapable-de-rendre-rouge]] et [[mutation-test-discriminating-cases]].
