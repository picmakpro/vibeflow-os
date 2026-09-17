---
name: rejeu-long-detache-nohup
description: Un Bash run_in_background du manager meurt quand son tour se termine — lancer la découverte complète en nohup détaché avec un fichier témoin, puis attendre en avant-plan
metadata:
  type: project
---
La découverte complète des suites (79 suites, ~7 min sur ce poste) lancée en `run_in_background` par le manager a été tuée à la fin de son tour : log tronqué à « debut Découvrir… », aucune erreur. Relancée, elle a tourné deux fois en même temps dans le même worktree et fabriqué un faux rouge (T10 de `test-check-description-fidelity.sh`, garde d'arbre propre).

**Why:** mesuré Phase 40.1, 2026-09-16. Deux rejeux concurrents dans un seul worktree rendent un rouge sur une suite qui exige un arbre propre.

**How to apply:** écrire le rejeu dans un script du scratchpad qui finit par `echo done > <témoin>`, le lancer en `nohup bash script >out 2>&1 </dev/null & disown`, puis attendre en avant-plan avec une boucle `perl -e 'select(undef,undef,undef,5)'` jusqu'au témoin (timeout 600000). Un témoin distinct par rejeu, jamais deux rejeux dans le même worktree. Voir [[non-regression-complete-est-un-geste-de-manager]].
