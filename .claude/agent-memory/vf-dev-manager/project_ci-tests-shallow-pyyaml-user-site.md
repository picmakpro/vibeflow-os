---
name: ci-tests-shallow-pyyaml-user-site
description: Le job `tests` de ci.yml clone en shallow (objets historiques absents) ; sous HOME temporaire, PyYAML du site utilisateur disparaît
metadata:
  type: project
---

1. Le job `tests` de `.github/workflows/ci.yml` fait `actions/checkout@v4` SANS `fetch-depth` (seul `gates` a
   `fetch-depth: 0`). Toute suite qui lit un objet git historique (`git show <sha>:…`) y passe en SKIP : c'était le cas
   de WS-AB-INTEGRITE / GW-AB-INTEGRITE jusqu'au 2026-10-12 (corrigé par empreinte épinglée, R-7).
2. Sur ce poste, PyYAML vit dans le site utilisateur (`python3 -m site --user-base`). Un rejeu sous `HOME=$(mktemp -d)`
   rend `test-check-description-fidelity.sh` rouge 30/30 (exit 3) : faux rouge d'environnement. Garder
   `PYTHONUSERBASE=<user-base>` dans le rejeu.

**Why:** un SKIP en CI se lit comme un vert ; un rouge d'environnement se lit comme une régression.

**How to apply:** exiger d'une preuve « au bit près » qu'elle ne dépende pas de l'historique ; préfixer tout rejeu
sous HOME temporaire de `PYTHONUSERBASE`. Lié : [[lire-la-ci-de-la-branche-des-la-reprise]].
