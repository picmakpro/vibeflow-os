---
name: attestation-sur-sha-fige
description: Une attestation rouge→vert doit référencer un SHA figé et se mesurer APRÈS le commit — `git show HEAD:` se sabote au moment même du commit
metadata:
  type: feedback
---

Deux règles à imposer dans tout mandat qui demande une preuve « ce cas allait au rouge avant le
correctif » :

1. **L'attestation référence un SHA FIGÉ** (`git show <sha>:fichier`), jamais `HEAD`, `HEAD~n`, `@`
   ni un nom de branche. Une référence mutable compare le script **à lui-même** dès que le commit
   du correctif devient HEAD.
2. **Toute suite se rejoue APRÈS le commit**, jamais avant. Exiger la trace horodatée de ce dernier
   geste dans le rapport.

**Why:** Phase 29, `test-check-map-drift.sh` : le cas « Borne (a) sens 1 » attestait son rouge contre
`git show HEAD:…`. Le worker a rapporté **« 57/57 »** en toute bonne foi — il avait mesuré avant son
propre commit. Sur un checkout propre du commit livré, la suite sortait **56 ok / 1 ko, de façon
permanente**. Défaut invisible au worker par construction, trouvé par un juge externe. Deux autres
attestations du même fichier utilisaient déjà des SHA figés : le motif fautif était isolé, mais rien
ne l'empêchait de se répandre.

**How to apply:** Dès qu'un mandat demande une mutation attestée ou une preuve rouge→vert, écrire les
deux règles dans le mandat. Au retour, ne pas se contenter du compteur rapporté : demander (ou faire
vérifier par un juge) le compteur **rejoué après le dernier commit**. Et quand un défaut de ce type
est trouvé, exiger le **balayage du fichier entier** pour les autres références mutables — fermer la
classe, pas le cas. Voir [[liste-de-cas-ne-ferme-pas-une-classe]] et
[[mutation-qui-echoue-pour-la-mauvaise-raison]].

Corollaire observé la même mission : une entrée de CHANGELOG écrite au moment du bump décrit un
**état intermédiaire** si la phase continue après. Prévoir un rattrapage documentaire en fin de
mission plutôt qu'un re-bump — une version non publiée se corrige, elle ne se double pas.
