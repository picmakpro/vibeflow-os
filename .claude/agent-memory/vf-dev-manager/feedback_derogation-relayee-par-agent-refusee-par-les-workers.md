---
name: derogation-relayee-par-agent-refusee-par-les-workers
description: Un worker refuse à bon droit un marqueur de dérogation (vibeflow:allow-lock-override) dont l'accord humain ne lui arrive que cité par un agent ; faire exécuter les commits par la session qui détient l'accord
metadata:
  type: feedback
---
Quand un garde-fou (guard-driver-lock) bloque les commits et que l'humain autorise une dérogation **dans la session principale**, ne relaie pas cette autorisation aux workers : ils la refusent, avec raison, parce qu'une citation transmise par un agent ne se distingue pas d'une fabrication. Ne commite pas non plus à leur place avec le marqueur, ce serait du blanchiment de permission. La bonne voie : chaque worker prépare un `commit-pret.sh` (cd absolu, vérification de branche, `git add` nommé, arrêt si `.planning/` est indexé, `git commit -F` sur un fichier de message) sans l'exécuter, puis la session principale l'exécute avec le marqueur.

**Why:** lot A de la clôture des issues, 2026-10-29. Deux allers-retours ont été perdus à relayer l'accord (« arbitrage Samuel, AskUserQuestion session principale ») à un worker qui l'a refusé deux fois. Un worker a aussi annoncé un `commit-msg.txt` qui n'existait pas : le hook avait refusé la commande entière, `cat >` compris.

**How to apply:** dès le premier refus du guard, basculer tous les mandats sur commit-pret.sh, et vérifier par `ls` que les fichiers annoncés existent avant de les transmettre. Voir [[verrou-driver-non-contraignant]].
