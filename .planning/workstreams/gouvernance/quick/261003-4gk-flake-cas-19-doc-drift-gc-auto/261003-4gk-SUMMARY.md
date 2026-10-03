---
quick_id: 261003-4gk
status: complete
---

# Résumé — quick 261003-4gk

- Correction : `mk_git_root` coupe la maintenance git automatique (gc.auto=0, maintenance.auto=false,
  gc.autoDetach=false) via `git_must`. Cas 19 intact, empreinte toujours `find` sur tout `$D` y compris `.git`.
- Reproduction : sur le code d'origine, écrivain détaché simulé (`git gc` lancé avant l'empreinte) : cas 19
  rouge 20/20 ; suite corrigée : cas 19 rouge 0/20. Le déclencheur réel (git 2.55 CI) n'a pas pu être
  reproduit en local (git 2.52) : la preuve du mécanisme repose sur les listes de fichiers des journaux CI.
- Mutant (outil qui écrit `.git/zz-mutant`) : tué par le cas 19 après correction.
- Suite : 21 ok, 0 ko ; check-machine-paths vert.
- Méthode : planification et exécution faites en ligne par vf-coder (une ligne de config), sans
  sous-agents planner/executor.
