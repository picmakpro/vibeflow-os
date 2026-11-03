---
name: feedback-head-assignment-skip-quote-forms
description: resume() du cockpit-who (D3) saute les affectations de tête par fermeture de guillemet en suffixe ; formes qui fuient encore ($'..', $"..", (..), guillemet interne, \" interne) et garde interne non testée
metadata:
  type: feedback
---

Revue 67 revue-fb2 (dc9fe679, 2026-11-03) : `resume()` dans `plugin/cockpit/scripts/vf-cockpit-who.mjs`
ne détecte la quote qu'en TÊTE de valeur (`NOM=(["']?)`) et ferme au premier mot qui finit par ce guillemet.

**Why:** `FOO=$'pa ss' gh`, `FOO=$"pa ss" gh`, `FOO=(pa ss) gh`, `FOO=ab'cd ef'gh gh`, et `FOO="he said \"hi\" Secret99" gh`
(un `\"` en fin de mot ferme à tort) laissent le reste de la VALEUR devenir « programme + argument ». Hors limite acceptée
(qui ne vise que le 1er argument positionnel). Non gardé par les suites : la garde interne `$(`/backtick/`\` de la boucle
`while` est supprimable sans rouge (mutant vert 80/68).

**How to apply:** sur toute évolution de `resume()` ou d'un tokenizer shell maison, sonder ces formes et muter chaque
branche de la boucle de fermeture, pas seulement la première condition. Le repli sûr est « … » dès qu'une valeur contient
un guillemet hors position de tête, `(`, `)` ou `\`.
