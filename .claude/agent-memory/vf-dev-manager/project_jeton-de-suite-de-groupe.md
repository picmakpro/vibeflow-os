---
name: jeton-de-suite-de-groupe
description: Quand plusieurs managers tournent en parallèle sur ce poste, une baseline complète par codeur est impossible ; un jeton mkdir commun « une suite à la fois » par groupe a tenu toute une mission
metadata:
  type: project
---

Sous 4 managers simultanés (2026-11-06, retours du panel cockpit, charge 150 sur 12 cœurs, 81 suites,
14 Chrome, swap plein), la baseline de 15 suites du premier codeur n'a pas fini en 20 min, et 3
exemplaires de la même baseline tournaient en parallèle dans le même worktree. Remède posé par le
manager : un script `une-suite.sh <worktree> <suite> <log>` qui prend un jeton `mkdir` commun au groupe
(reprise si le PID porteur est mort), écrit `<suite> <rc>` en dernière ligne, lancé en `nohup … &` et
sondé par `python3 time.sleep` ; plus de baseline complète, chaque codeur ne rejoue que les suites qui
mesurent ses fichiers, et le pré-existant se vérifie dans un worktree parent FIGÉ au commit de départ.

**Why:** la règle « une seule suite à la fois » de la session principale n'est tenable que si elle est
outillée ; sans jeton, chaque codeur lance sa batterie et les rouges de chronométrage se multiplient.

**How to apply:** dès que la session principale signale d'autres groupes actifs, poser le jeton AVANT le
premier dispatch, le donner par chemin absolu dans les règles communes, et garder un worktree parent
intact comme ancre « pré-existant ». Durée observée : `projet` 16 à 30 min, les suites terminal/lancer
3 à 10 min chacune. Voir [[non-regression-complete-est-un-geste-de-manager]], [[scratchpad-partage-vert-emprunte]].
