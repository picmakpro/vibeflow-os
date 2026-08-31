---
name: liste-de-cas-ne-ferme-pas-une-classe
description: Quand un correctif remplace une comparaison tolérante par une comparaison stricte, exiger une preuve GÉNÉRATIVE (produit cartésien + idempotence), jamais une liste de cas énumérés
metadata:
  type: feedback
---

Quand un worker corrige une comparaison/normalisation en remplaçant une version **tolérante** par
une version **stricte**, ne jamais accepter une liste de cas énumérés comme preuve de couverture.
Exiger dans le mandat : (1) une seule fonction traitant la CLASSE, appliquée **symétriquement** aux
deux côtés de la comparaison, bouclée jusqu'au **point fixe** si les transformations peuvent
s'exposer l'une l'autre ; (2) une preuve **générative** — produit cartésien d'un alphabet de formes
× corps, avec la propriété `f(f(x)) == f(x)` ; (3) l'attestation du rouge du harnais génératif
contre le commit d'avant (« N combinaisons échouent avant, 0 après »).

**Why:** Phase 29, `normalize_path()` de `check-map-drift.sh` : **4 défauts consécutifs de la même
famille**, chacun trouvé par un juge externe et jamais par la suite du worker. Suffixe de basename
(faux négatif) → comparaison stricte (faux positif `./a.md`) → strip d'un niveau (faux positif
`.//a.md`) → deux passes indépendantes (faux positif `//./a.md`). À chaque tour, le correctif
fermait exactement le cas nommé dans le rapport et laissait survivre son voisin immédiat, parce que
la preuve était une **liste**. Le tour 4, en changeant de méthode (point fixe + 45 combinaisons
générées, 10 rouges avant / 0 après), a fermé la classe d'un coup. Le coût de la leçon : 4 tours de
correction et 4 passes de juge sur un seul nœud.

**How to apply:** Dès qu'un finding de revue porte sur une **forme d'écriture équivalente** (chemin,
identifiant, version, glob, URL), écrire l'anti-récidive directement dans le mandat de correction —
« énumère ce que la version tolérante acceptait par accident, puis prouve par génération ». Et si un
juge relève **deux fois** le même motif sur le même nœud, ne pas commander un troisième point-fix :
changer la méthode de preuve. Voir [[mutation-qui-echoue-pour-la-mauvaise-raison]] (le pendant :
une preuve qui passe pour la mauvaise raison) et [[re-deriver-les-listes-d-une-revue]].

Corollaire de budget : le plafond de 3 tours par nœud se dépasse **délibérément et consigné** quand
le correctif cesse d'être exploratoire (juge ayant donné le fix exact) ET que la méthode de preuve
change. Un 4e tour qui rejoue la même méthode est une halt condition, pas un tour de plus.
