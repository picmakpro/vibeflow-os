---
name: nohup-ps-invisible-doublons-de-suite
description: un `nohup … &` lancé depuis Bash tourne bien même si ps/grep ne le montre pas ; le relancer crée des doublons qui écrasent le même log et bloquent le jeton de suites
metadata:
  type: project
---

En lot 6 (2026-11-06), deux lancements `nohup bash une-suite.sh … &` « sans effet visible » (ps vide, log absent) ont en fait tourné plus tard : 3 runs de `projet` se sont disputé `f-projet.log` (tronqué, entrelacé) et le jeton commun.

**Why:** le jeton de `une-suite.sh` met les runs en file ; un log partagé par plusieurs runs ressemble à une suite qui « rétrécit » ; `kill` d'un pid de suite peut être refusé par le classifieur.

**How to apply:** un seul lancement par suite, via Bash `run_in_background: true` (jamais `nohup &` puis relance) ; un log par lancement (suffixe) ; attendre la ligne `<suite> <rc>` finale, pas la taille du log ; `set -- $x` ne découpe pas dans ce shell (cf. [[project_shell-sans-word-splitting]]).
