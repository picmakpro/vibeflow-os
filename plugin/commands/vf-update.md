---
description: Met à jour VibeFlow — le plugin (cache marketplace) puis tous les modules installés — vers la dernière version publiée, avec changelog et confirmation.
argument-hint: "[--check | --modules-only]"
---

Invoque le skill **`vf-update`** : $ARGUMENTS

Le skill compare la version installée au dernier tag publié, affiche ce qui a changé, puis — sous
confirmation — met à jour **les deux couches** : le plugin (`claude plugin update vibeflow`, couche
marketplace) puis les modules installés (engine `update --all`, re-matérialisation dans `.claude/`).
Termine par un rappel de redémarrage de Claude Code.

- `--check` : affiche seulement l'écart de version et le changelog, sans rien mettre à jour.
- `--modules-only` : ne met à jour que les modules déjà installés (n'exécute pas `claude plugin update`).

Si le module `conductor` n'est pas installé, lance d'abord `/vibeflow-install`.
