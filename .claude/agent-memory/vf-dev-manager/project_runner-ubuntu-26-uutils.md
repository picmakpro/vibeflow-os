---
name: runner-ubuntu-26-uutils
description: Le runner ubuntu-latest passe à Ubuntu 26 (coreutils uutils, -h = --help) depuis le 2026-10-19 ; toute copie gelée ou tout script qui fait `ln -sh`/`mv -nh` en premier y casse en silence
metadata:
  type: project
---
Depuis le 2026-10-19 (annotation GitHub du run 40800958831), `ubuntu-latest` bascule vers Ubuntu 26, qui embarque les coreutils uutils. Sous uutils, `-h` vaut `--help` : l'aide part sur stdout, le code de retour est 0 et rien n'est fait. Un `ln -sh … || ln -sn …` ne déclenche donc jamais son repli.

**Why:** PR #168, 2026-10-29. La correction de driver-lock.sh était verte sous macOS. Mais les comparaisons A/B des suites -ws exécutent une COPIE GELÉE de l'ancien script : WS-AB, GW-AB et toute la cascade de mutants ont rougi en CI (34 et 28 échecs). Correctif : un shim `gnu_shim_setup` dans les deux suites, posé seulement quand le binaire de l'OS ne fait pas réellement `-sh`/`-nh`.

**How to apply:** tout faux binaire ou toute copie gelée de test doit être jugé sous les trois sémantiques (BSD, GNU, uutils). Pour reproduire en local, utiliser un faux uutils en tête de PATH. Une branche qui ne contient pas cd7c66c3 voit son verrou de driver ne jamais se poser sous ce runner.
