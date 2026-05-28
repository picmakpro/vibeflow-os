# Catalogue d'anti-patterns + signaux + remède

> Référence du skill `software-architecture`. Chaque anti-pattern = signal mesurable + remède.

## God File / God Class
- **Signal** : fichier > 300L ; classe avec > 10 méthodes publiques + > 5 dépendances ;
  formule de priorité = **taille × churn (fréquence de modification) × couplage**.
- **Effet IA** : l'IA charge tout, perd l'intention, casse une zone en en modifiant une autre.
- **Remède** : extraire chaque responsabilité dans son fichier (hook, service, contrôleur,
  validateur). Écrire les tests des fonctions extraites AVANT de les retirer du god file.

## Couplage circulaire (import cycles)
- **Signal** : `madge --circular` / `dependency-cruiser` détecte un cycle.
- **Effet IA** : modification en cascade imprévisible ; ordre de chargement fragile.
- **Remède** : un cycle = une tâche de refactor. Inverser une dépendance (DIP) ou extraire
  l'élément partagé dans une couche plus basse.

## Mixing Concerns (couches mélangées)
- **Signal** : logique métier + accès DB + rendu UI dans la même unité.
- **Remède** : séparer en couches domaine / application / infrastructure (voir `solid-soc.md`).

## Feature Envy
- **Signal** : une fonction manipule surtout les données d'un AUTRE module.
- **Remède** : déplacer le comportement là où vivent les données.

## Frontières non enforced
- **Signal** : n'importe quel module peut importer n'importe quel autre ; règles « écrites » seulement.
- **Remède** : déclarer explicitement les dépendances autorisées (eslint-plugin-boundaries),
  passer de `warn` à `error`. **Une règle non machine-enforced n'est pas une règle.**

## Filet de tests décoratif
- **Signal** : la commande de test crashe / 0 test exécuté / coverage non câblé ; pourtant
  « on a des tests ». Versions runtime désalignées (ex : Node vs framework de test).
- **Effet IA** : aucune détection de régression → les casses se propagent silencieusement.
- **Remède** : **réparer le filet AVANT toute autre chose**. Un test rouge non lu = absence de filet.

## Gate fantôme
- **Signal** : garde-fou décrit dans CLAUDE.md / README mais jamais exécuté (pas de hook, pas de CI).
- **Remède** : convertir en check machine (hook, lint error, CI bloquante, exit code).

## Spec floue → rework
- **Signal** : « on verra en faisant » ; pic de régressions corrélé à l'absence de spec écrite.
- **Remède** : Explore → Plan (spec écrite 100-200L) → Validate → Execute en session fraîche.

## Anti-pattern de session (context rot)
- **Signal** : session > 60-90 min, contexte accumulé, l'IA dérive.
- **Remède** : tâches atomiques 30-60 min, état externalisé dans des fichiers, reset entre tâches,
  commits atomiques par étape.
