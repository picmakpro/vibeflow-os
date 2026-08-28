---
name: resolution-scripts-sur-le-repo-source
description: Sur vibeflow-os, résoudre $S vers plugin/conductor/scripts — pas vers ~/.claude/scripts, qui héberge une version plus ancienne des mêmes scripts
metadata:
  type: project
---

Sur ce repo (`vibeflow-os` = repo **source** du plugin), la résolution du dossier de scripts `$S`
doit pointer vers `plugin/conductor/scripts/`. Il n'existe pas de `./.claude/scripts` ici, et
l'ordre de résolution par défaut ferait tomber sur `$HOME/.claude/scripts`, qui contient une
version **antérieure** des mêmes scripts (constaté 2026-07-27 : `driver-lock.sh` 6.7K en scope
user contre 7.8K dans le repo).

**Why:** la doctrine dit « le lab courant PRIME sur le scope user » précisément pour éviter de
diverger silencieusement de la version du lab. Sur le repo qui *produit* les scripts, la version
de référence est celle du repo — piloter une mission avec la copie installée du user reviendrait
à tester une version qui n'est pas celle qu'on modifie.

**How to apply:** au démarrage de toute mission sur `vibeflow-os`, utiliser
`plugin/conductor/scripts/{driver-lock,dag}.sh` en chemin absolu. Vérifier au passage que les
deux versions n'ont pas divergé au point de changer un contrat de sortie (JSON du lock, format
du DAG) — si oui, c'est un signal que le scope user est périmé et mérite un `/vf-update`.

Voir aussi [[check-agents-vacuous-green]] pour un autre piège de gate sur ce repo.
