---
name: mutation-test-regression-claims
description: Avant de valider un test qui prétend garder une régression spécifique (whitelist, renommage), le muter mentalement/réellement pour vérifier qu'il échoue quand la régression est réintroduite
metadata:
  type: feedback
---

Quand une PR/diff ajoute un nouveau cas de test dont le nom/commentaire affirme protéger contre une
régression précise (ex. « preuve que le renommage de la whitelist a bien pris effet »), ne pas se
fier au commentaire ni au fait qu'il passe au vert dans l'état actuel. Revert temporairement la
correction qu'il est censé garder (ex. retirer l'entrée de whitelist visée) et relancer la suite :
si le nouveau test passe quand même, il est tautologique — il reproduit sa propre hypothèse au lieu
de vérifier le mécanisme réel.

**Why:** trouvé en Phase 11 plan 11-02 (migration `gsd-sdk` → `gsd-tools`, module dev-orchestrator) :
le cas `T4c` de `test-dev-orchestrator.sh` prétendait prouver que le renommage de la whitelist T4
(case `gsd-tools) : ;;`) avait pris effet. En pratique T4c a son propre `[ "$t" = "gsd-tools" ] &&
continue` codé en dur, indépendant de la case statement de T4 — retirer l'entrée whitelist de T4
fait échouer T4 (attendu) mais **T4c reste vert**. Le test redondant ne garde rien de plus que T4
lui-même et peut donner un faux sentiment de couverture double.

**How to apply:** en revue de tests, repérer les tests dont le setup contient un bypass/skip
hardcodé sur exactement le cas qu'ils prétendent vérifier (`[ "$x" = "$valeur_cible" ] && continue`
suivi d'une assertion sur le reste) — c'est le signal. Confirmer par mutation réelle (édition
temporaire + relance + restauration via `git diff --stat` pour prouver l'absence de résidu) plutôt
que par lecture seule. Voir [[recette-lab-standard]] pour la famille de pièges voisine (tests qui
n'auditent pas ce qu'ils prétendent).
