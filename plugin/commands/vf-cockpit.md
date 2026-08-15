---
description: Lance le cockpit web local en lecture seule sur le .planning/ du lab courant.
argument-hint: "[optionnel : port / chemin .planning/]"
---

Invoque le skill **`vf-cockpit`** : $ARGUMENTS

Le skill décrit la commande exacte de lancement, la résolution du `.planning/` visé, les
prérequis réels, les états vides gérés et le dépannage. Rappel de son Iron Law : le cockpit ne
modifie jamais rien — c'est un miroir en lecture seule du `.planning/`, servi uniquement sur
`127.0.0.1`.

Si le module `vf-cockpit` n'est pas installé dans ce lab, lance d'abord `vibeflow-install` (ou
indique `/vibeflow-install`) pour l'installer.
