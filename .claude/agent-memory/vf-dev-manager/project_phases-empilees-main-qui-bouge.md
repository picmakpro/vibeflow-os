---
name: phases-empilees-main-qui-bouge
description: Empiler 59→60→61 pendant qu'une autre session merge ses lots sur main — chaque merge impose un rebase en chaîne et un CI de ~55 min (règle « branche à jour »)
metadata:
  type: project
---

Le 2026-10-29, trois lots d'une autre session (#168, #169, #170) ont été mergés sur main pendant que
59, 60 et 61 étaient empilées. Le ruleset exige une branche à jour : chaque merge a rendu la PR BEHIND
ou CONFLICTING, puis a demandé un rebase de toute la pile et un nouveau job « Suites de tests »
(55-57 min). Conflits récurrents : VERSION/CHANGELOG/README des modules bumpés des deux côtés
(garder la version la plus haute, empiler les entrées), compte de suites des README racine (recompter
par `find plugin scripts -path '*/tests/test-*.sh'`, `check-version-sync` tranche), tableau de
traçabilité et sections de `REQUIREMENTS.md` du compartiment (union : lignes des deux côtés, un seul
pied de page). Un résolveur Python d'union pour REQUIREMENTS a tenu sur 6 conflits.

**Why:** le coût réel d'une pile n'est pas le rebase mais le CI rejoué à chaque fusion d'autrui.

**How to apply:** rebaser la pile une seule fois juste avant de demander la CI qui servira au merge ;
noter dans le CHANGELOG racine de la release les modules des lots mergés sans release (ils partent
avec elle). Voir [[sessions-concurrentes-sur-le-repo]].
