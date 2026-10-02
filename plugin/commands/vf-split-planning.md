---
description: "Sépare le planning du lab en sujets parallèles, sous validation humaine."
argument-hint: "[optionnel : nom du nouveau sujet]"
---

Invoque le skill **`vf-split-planning`** (choix du planning : unique ou sujets parallèles) : $ARGUMENTS

Le skill vérifie par machine qu'aucune phase n'est en cours, pose une seule question en langage
d'usage (défaut : un seul planning), puis sépare le planning par le geste outillé sous validation
humaine et propose la suite.

Si le module `conductor` n'est pas installé, lance d'abord `vibeflow-install`.
