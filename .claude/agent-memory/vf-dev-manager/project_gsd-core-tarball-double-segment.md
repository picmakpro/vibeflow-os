---
name: gsd-core-tarball-double-segment
description: Le tarball npm @opengsd/gsd-core range son payload sous un DOUBLE segment gsd-core/gsd-core/bin/lib — tout code qui résout node_modules/@opengsd/gsd-core/bin/lib est mort
metadata:
  type: project
---

Le paquet npm `@opengsd/gsd-core` range son payload sous **`node_modules/@opengsd/gsd-core/gsd-core/bin/lib`** — double segment, en **minuscules** (nom de scope + dossier de payload). Un `bin/lib` existe bien au cran supérieur mais ne contient qu'**un** fichier (`ui-safety-gate.cjs`), contre ~172 dans le vrai dossier — et **pas** `config.cjs`.

Mesuré le 2026-08-03 sur les deux installs présents (**1.8.0 et 1.9.0**) : le layout est **identique**. Ce n'est donc pas une régression de version — c'est la forme du tarball.

Le layout posé sous `$HOME/.claude/gsd-core/` n'a **pas** ce double segment. Seul le chemin npm l'a.

**Why:** `check-gsd-config.sh:270` résout `<root>/node_modules/@opengsd/gsd-core/bin/lib` et n'a donc **jamais** résolu, pour personne, sur aucune version — du code mort qui donnait une fausse impression de couverture (arbitrage O-12 de la Phase 23). Le premier relevé avait écrit `GSD-CORE` en majuscules et attribué le défaut à la seule version 1.9.1 : deux erreurs, corrigées par re-mesure indépendante.

**How to apply:** avant d'écrire ou de réviser toute cascade de résolution du moteur GSD, vérifier le chemin **segment par segment** contre un install réel (`find <pkg> -maxdepth 3 -name bin`), jamais contre l'intuition du nom de paquet. Et se méfier symétriquement de l'inverse : la cascade `$S` du plugin, elle, n'omet aucun segment — `marketplace.json` déclare `"source": "./plugin"`, donc le préfixe `plugin/` du dépôt n'est **pas** dans le chemin installé et `CLAUDE_PLUGIN_ROOT` pointe un dossier de version à plat. Ne pas propager le défaut npm par analogie. Voir [[resolution-scripts-sur-le-repo-source]] et [[artefacts-descriptifs-non-testes]].
