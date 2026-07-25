---
description: Met en place ou tient à jour le socle de planning d'un lab non-dev, et l'altitude lab (index des projets, compartiments, pont mémoire) sur tous les labs.
argument-hint: "[optionnel : mets en place le planning / fais l'index de mes projets / qu'est-ce qui traîne sans plan]"
---

Invoque le skill **`vf-planning`** : $ARGUMENTS

Le skill commence **toujours** par déterminer qui tient le planning de ce lab (étape 0), puis :

- **lab non-dev** (contenu, vente, growth, design, dossier, recherche) → il pose ou maintient le
  tronc `.planning/` adapté au métier (`PROJECT`, `STATE` ★ clé de voûte, `ROADMAP`, etc.) — jamais
  une forme dev imposée ;
- **lab dev** → il n'écrit **pas** le planning du projet : il tient l'altitude lab — index des
  projets et typage des compartiments si le lab en a plusieurs, pont mémoire, dette — et redirige
  vers le bon verbe.

Pour un projet de code : démarrage → `/vf-init`, état et avancement → `/vf-progress`, cadrage d'une
étape → `/vf-plan`, comprendre l'existant → `/vf-map`.

Si le module `planning-core` n'est pas installé, lance d'abord `vibeflow-install`.
