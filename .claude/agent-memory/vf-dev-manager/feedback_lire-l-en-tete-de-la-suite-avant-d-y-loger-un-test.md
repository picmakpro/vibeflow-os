---
name: lire-l-en-tete-de-la-suite-avant-d-y-loger-un-test
description: un brief peut désigner une suite GELÉE comme lieu du test rouge ; lire l'en-tête de la suite (et de sa variante) avant de prescrire où vit la preuve
metadata:
  type: feedback
---

Avant de dire à un worker dans quelle suite écrire le test rouge, lire l'en-tête de cette suite et celui de sa variante. Le brief n'en tient pas lieu.

Cas du lot E (2026-10-29, PR #180) : le brief demandait le test dans `test-guard-driver-lock.sh`. Or l'en-tête de `test-guard-driver-lock-ws.sh` fixe P57-D-03 : la suite plate est le témoin GELÉ du lab plat, et toute preuve du chemin partitionné vit dans `-ws`, avec un mutant GW-M-* par comportement neuf (QUAL-01). Le défaut était sur le chemin partitionné. J'ai redirigé le test vers `-ws` et documenté l'écart dans la PR.

**Why:** suivre le brief à la lettre aurait modifié un témoin de non-régression gelé. Il aurait aussi privé le nouveau comportement de son mutant.

**How to apply:** pour chaque suite nommée dans un brief, lire ses 20 premières lignes. Si sa doctrine contredit le brief, la doctrine du fichier l'emporte : écrire l'écart et son motif dans le mandat, puis dans la PR. Prévoir aussi le coût réel : la suite `-ws` complète dure environ 20 min, dont environ 13 min de mutants. Voir [[non-regression-sur-la-decouverte-complete]].
