---
name: rejeu-ci-gates-bash-e
description: Rejouer le job CI gates en bash -e (pas -eo pipefail) et extraire le tableau d'un gate en rtk proxy — deux faux rouges vécus sur 25-04
metadata:
  type: feedback
---

Rejouer les étapes `run:` du job `gates` de ci.yml avec `bash --noprofile --norc -e` : ci.yml ne
déclare aucun `shell:`, le runner n'active donc PAS pipefail. Un harnais `-eo pipefail` rend l'étape
check-instruction-budget rouge à tort.

Toute extraction de données depuis la sortie d'un gate (baselines, compteurs) passe par
`rtk proxy bash -c '...'` : le filtre rtk injecte des numéros de ligne dans grep.

**Why:** 2026-09-16, plan 25-04 — baseline corrompue par rtk (gate armé rc=2, 31 orphelines) puis
faux rouge du rejeu en pipefail ; les deux détectés avant commit.

**How to apply:** avant tout « vert » déclaré sur ce dépôt ; voir aussi [[liste-de-gates-jamais-la-reference]].
