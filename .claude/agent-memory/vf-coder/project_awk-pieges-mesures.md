---
name: awk-pieges-mesures
description: Deux pièges awk payés sur ce poste — RS="\0" ne découpe pas (compteur faux d'un facteur 800) et `&` dans un remplacement gsub réinjecte le texte matché
metadata:
  type: project
---

Deux défauts **mesurés** en écrivant `scripts/check-machine-paths.sh` (2026-08-05), tous deux
silencieux : ils rendent un résultat plausible au lieu d'échouer.

**1. `awk -v RS="\0"` ne découpe pas sur NUL côté macOS.** Compter les entrées d'une liste
`git ls-files -z` avec `awk 'BEGIN{RS="\0"} END{print NR}'` a rendu **1** là où l'univers en compte
**868** — tout le fichier lu comme un seul enregistrement. Le compteur servait de garde
anti-vert-à-vide : faux d'un facteur 800, il ne gardait plus rien tout en ayant l'air de garder.
Forme qui marche : `tr '\0' '\n' < liste | awk 'END{print NR}'`.

**2. Dans le remplacement de `sub`/`gsub`, `&` désigne le texte matché.** Remplacer
`"cd <chemin> &&"` par `"cd \"$(...)\" &&"` a produit `cd "$(...)" cd <chemin> &&cd <chemin> &&` :
les deux `&` du remplacement ont réinjecté la commande entière, deux fois. Aucun message d'erreur.
Il faut écrire `\\&\\&`. Vérifier tout remplacement contenant `&` **avant** de l'appliquer en masse,
et relire le diff — pas seulement le code de retour.

**How to apply** : ces deux formes passent les tests de fumée et ne rougissent qu'à la relecture du
résultat. Après toute substitution `awk` en masse, relire au moins une ligne touchée
(`awk 'FNR==N{print}'`), jamais se contenter du « REECRIT ».

Voisines : [[project-bash32-heredoc-substitution]], [[project-shell-sans-word-splitting]],
[[project-diff-proxifie-utiliser-comm]].
