---
name: awk-pieges-mesures
description: Trois pièges de commande de mesure payés sur ce poste — RS="\0" ne découpe pas (compteur faux d'un facteur 800), `&` dans un remplacement gsub réinjecte le texte matché, et `xargs -0 LC_ALL=C awk` cherche un exécutable nommé LC_ALL=C
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

**3. `xargs -0 LC_ALL=C awk '…'` ne lance pas awk.** `xargs` exécute son premier argument comme un
programme : il cherche un exécutable nommé `LC_ALL=C`, rend `xargs: LC_ALL=C: No such file or
directory` sur stderr, et **rien sur stdout**. Mesuré le 2026-09-24 en rédigeant la commande de
re-mesure du recensement du plan 41.1-05 (la forme venait du plan lui-même) : l'univers sortait
VIDE, et le `comm` de comparaison disait tranquillement « rien ne manque » — un faux vert parfait.
Forme qui marche : `export LC_ALL=C` avant le pipeline (ou `xargs -0 env LC_ALL=C awk`). Le même
piège vaut pour tout `xargs VAR=val cmd`.

**How to apply** : ces trois formes passent les tests de fumée et ne rougissent qu'à la relecture du
résultat. Après toute substitution `awk` en masse, relire au moins une ligne touchée
(`awk 'FNR==N{print}'`), jamais se contenter du « REECRIT ».

Voisines : [[project-bash32-heredoc-substitution]], [[project-shell-sans-word-splitting]],
[[project-diff-proxifie-utiliser-comm]].
