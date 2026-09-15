---
name: find-proxifie-tronque-par-intermittence
description: Le proxy shell tronque aussi `find` (21 résultats sur 78), mais PAS à chaque invocation — deux appels identiques peuvent rendre 78 et 21 ; la troncature est intermittente, donc indétectable par simple relecture
metadata:
  type: project
---

`find` rejoint `grep`, `ls`, `wc -l` et `diff` dans la liste des commandes que le proxy `rtk` de ce
poste rend fausses. Constaté en Phase 25 (vague 2, 2026-09-15) par un `vf-reviewer` : `find plugin
scripts -type f -path '*/tests/test-*.sh'` a rendu **21** suites non préfixé, **78** préfixé `rtk
proxy`.

**Le fait qui compte est l'intermittence.** Dans la même mission, à quelques minutes d'écart, j'ai
rejoué les deux formes côte à côte : `sans proxy : 78` / `avec proxy : 78`. La même commande, sur le
même arbre, avait tronqué chez un agent et pas chez moi. On ne peut donc pas conclure « chez moi ça
passe, donc la mesure est bonne » — un compte juste une fois ne prouve rien sur le compte d'à côté.

**Why:** les autres troncatures de ce poste ([[grep-proxifie-tronque]], [[ls-proxifie-rend-vide]])
se reproduisaient à l'identique, ce qui rendait possible de les détecter en comparant deux formes.
Celle-ci ne se reproduit pas : un `0/N` ou un compte bas peut être un artefact qui disparaît au
rejeu, et le rejeu « réussi » sert alors de fausse innocence.

**How to apply:** toute mesure de cardinalité qui décide quelque chose (nombre de suites découvertes
par la CI, nombre de fichiers d'un corpus, « aucun consommateur hors diff ») se prend **préfixée
`rtk proxy` ET recoupée par un second moyen** (`awk` sur la sortie d'un `find`, `git ls-files`,
comptage par le script sous test lui-même). Exiger le recoupement dans le mandat, pas l'espérer :
un worker qui rend un seul chiffre sans dire comment il l'a obtenu rend un chiffre invérifiable.
Voir aussi [[ecart-de-chiffre-comparer-les-ensembles]] — quand deux comptes divergent, comparer les
ENSEMBLES par `comm`, jamais arbitrer entre les deux nombres.
