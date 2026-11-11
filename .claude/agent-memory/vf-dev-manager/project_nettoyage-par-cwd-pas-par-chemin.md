---
name: nettoyage-par-cwd-pas-par-chemin
description: Des suites lancées en chemin relatif depuis un clone échappent à pgrep -f sur le chemin ; tuer par répertoire courant (lsof -d cwd), marque non vide
metadata:
  type: project
---

2026-11-06, release v2.76.0 : après `pkill` des boucles de suites lancées dans des clones du scratchpad, `pgrep -f "<clone>/"` ne rendait plus rien. Pourtant des `bash plugin/cockpit/scripts/tests/…`, des `node` et des Chrome headless tournaient encore : ils avaient été lancés en chemin relatif après un `cd`. Ce qui les a trouvés : `lsof -d cwd -Fpn`, filtré par `index(n, "<scratch>/") == 1`. Il a fallu trois tours de `kill`, car les enfants respawnaient. Le poste faisait tourner au même moment les suites d'autres sessions, dans d'autres worktrees : un filtre sur le seul nom de suite les aurait tuées aussi. Sur ce poste, la charge des autres sessions monte jusqu'à 50-60. Sept shards locaux l'ont portée à 62, et les suites temporisées (Chrome, terminal) y rougissent par délai.

**Why:** un filtre de kill trop large tue le travail des autres (incident du 2026-11-02, [[nettoyeur-de-test-qui-tue-tout]]). Un filtre par chemin de commande, lui, laisse des orphelins.

**How to apply:** pour nettoyer, filtrer par répertoire courant sous MON scratchpad, avec une marque non vide vérifiée, et répéter jusqu'à zéro. Pour la non-régression complète, s'appuyer sur la CI ; en local, ne jouer que des rejeux ciblés, un à la fois, quand la charge est basse.
