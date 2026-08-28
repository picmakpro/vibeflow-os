---
name: shell-sans-word-splitting
description: Sur ce poste, `set -- $var` ne découpe pas — une boucle de vérification qui passe deux tags en un seul mot compare des fichiers vides et `cmp -s` répond « identique »
metadata:
  type: project
---

Le shell de ce poste est **zsh** : `$var` non quoté **ne subit pas de word-splitting**. Un
`for a in "TAG_A TAG_B" …; do set -- $a` laisse donc `$1="TAG_A TAG_B"` et `$2` **vide**, au lieu
des deux tags attendus.

**Why:** rencontré le 2026-08-04 en prouvant que quatre intervalles d'ADR restaient intacts. La
fonction d'extraction recevait un tag de début composite et un tag de fin vide, n'a jamais matché,
et a écrit **quatre fichiers de 0 octet des deux côtés**. `cmp -s` sur deux fichiers vides répond
**identique** : les quatre lignes de sortie disaient « IDENTIQUE bit-à-bit » alors que rien
n'avait été comparé. Le symptôme est trompeur au second degré — l'`echo "$1 : …"` affichait
`TAG_A TAG_B : 0 l. avant / 0 l. après`, que j'ai d'abord lu comme deux colonnes correctes. Ce qui
m'a sauvé, c'est l'`ls` du scratchpad : les fichiers s'appelaient `b.TAG_A TAG_B.txt`.

**How to apply:** dans toute boucle de vérification,
1. **jamais** de word-splitting implicite — écrire chaque cas en clair, ou passer les arguments un
   par un à une fonction ;
2. **toujours** un garde `[ "$n" -eq 0 ] && echo "VERT À VIDE"` avant le `cmp`/`comm` : deux
   ensembles vides sont toujours égaux, et c'est le mode d'échec par défaut d'un extracteur cassé ;
3. tester l'extracteur **seul** sur un cas connu avant de le mettre en boucle — l'appel manuel
   rendait 90 lignes là où la boucle en rendait 0, et c'est ce qui a localisé la panne en un coup.

Même famille que [[check-agents-file-egal-vert-a-vide]] et [[lab-skills-plat-partage]] : la cible
de mesure est vide, pas la propriété fausse. Voir aussi [[diff-proxifie-utiliser-comm]] pour
l'outillage de comparaison d'ensembles sur ce poste.
