---
name: attente-au-premier-plan
description: En sous-agent, un tour qui finit en attente d'une tâche de fond déclenche une remise forcée ; un worker qui lance ses suites en arrière-plan s'endort sans réveil
metadata:
  type: project
---

Un manager dispatché comme sous-agent qui termine son tour pour attendre un worker ou un rejeu
détaché reçoit `[handback-send-enforce]` : il doit rendre la main, trois fois de suite le
2026-10-01 (Phase 45, armement). Un worker qui lance ses suites avec `run_in_background` s'endort
aussi : le harnais dit « may resume », mais il n'a repris qu'au réveil par SendMessage.

**Why:** chaque remise forcée a coûté une relance complète par le head (verrou à reprendre,
état à reconstater), alors que le travail avançait.

**How to apply:**
- Attendre AU PREMIER PLAN, par un script Python du scratchpad qui sonde l'état (commit attendu
  dans `git log`, fichier `.done` présent, plus aucun processus de suite actif) puis rend la main
  avant 600 s. Les messages des workers arrivent entre deux appels d'outil. Le `sleep` de Bash est
  bloqué ; `time.sleep` de Python passe.
- Dans tout mandat de worker, exiger les suites au premier plan : un appel Bash par suite, avec
  timeout 600000. Interdire `run_in_background`, `nohup` et `&`.
- Seule la non-régression complète du manager (plus de 600 s) reste en nohup détaché. Elle
  s'attend par sondage du fichier `.done`. Voir [[rejeu-long-detache-nohup]].
