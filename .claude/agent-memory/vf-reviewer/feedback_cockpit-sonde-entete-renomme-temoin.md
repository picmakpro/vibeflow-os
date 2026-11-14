---
name: cockpit-sonde-entete-renomme-temoin
description: Sondes HTTP sur le cockpit assemblé - l'en-tête de jeton est renommé à l'assemblage, une sonde au nom amont rend 403 partout (porte "fermée" à tort) ; toujours établir un 200 témoin d'abord
metadata:
  type: feedback
---

Dans le cockpit ASSEMBLÉ (`.vibeflow/cockpit/serve.mjs`), l'en-tête du jeton n'est pas `X-Floorplan-Token` mais `x-vf-cockpit-token` (renommerTexte). Une sonde avec l'ancien nom rend 403 sur TOUTES les routes, ce qui ressemble à « porte fermée » alors que c'est une sonde aveugle (revue SOBR-04 v2.76.0, volet A).

**Why:** premier jeu de 14 sondes entièrement 403, y compris les routes légitimes ; seul un 200 témoin (GET git/entete avec le bon en-tête) a révélé l'erreur. Même famille que [[negatif-aveugle-ne-prouve-rien]].

**How to apply:** avant de conclure qu'une route est fermée, lire `grep -n "x-.*token" serve.mjs` dans la sortie assemblée, puis jouer un 200 témoin. Le jeton de la page Projet (ptoken) se lit dans `/project.html` par `"token":"<32 hex>"`, pas par `FLOORPLAN_SERVER` (renommé aussi). Sous rtk, `curl` tronque : utiliser `rtk proxy curl`. Sous zsh, `pgrep -f <motif>` capte aussi le `zsh -c` de la commande en cours (un `kill -9 $(pgrep ... | head -1)` a visé mon propre shell) : capturer le PID par `lsof -t -iTCP:<port>` ou par le plus petit PID filtré sur le chemin du binaire.
