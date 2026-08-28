---
name: ls-proxifie-rend-vide
description: `ls` proxifié rend un dossier peuplé comme VIDE, sans erreur — troisième commande prise en défaut après grep et diff ; passer par rtk proxy ou find
metadata:
  type: project
---

`ls -1 <dir>` proxifié peut rendre une sortie **vide** sur un dossier réellement peuplé, sans
erreur ni code de retour non nul. Constaté le 2026-08-17 sur
`.planning/phases/` : `ls` rendait vide, alors que `git status` listait un dossier untracked
dessous. `rtk proxy ls -1` et `find -maxdepth 1 -type d` rendaient les **7** dossiers réels.

**Why:** j'ai failli conclure que le dossier de la Phase 33 n'existait pas et que le chemin donné
par le coordinateur était faux — c'est-à-dire contredire un fait vrai sur la foi d'un outil qui
ment. Un « dossier vide » se lit exactement comme un « dossier absent ».

**How to apply:** troisième commande prise en défaut après [[grep-proxifie-tronque]] et
[[diff-proxifie-faux-identique]] — traiter désormais **toute sortie vide ou courte** d'un
utilitaire de listing/recherche comme non concluante, jamais comme une preuve d'absence. Avant de
conclure « ça n'existe pas », re-dériver par un second chemin (`rtk proxy …`, `find`, `git
ls-files`). Le motif général : dans cet environnement, l'absence n'est jamais prouvée par une
seule commande proxifiée.
