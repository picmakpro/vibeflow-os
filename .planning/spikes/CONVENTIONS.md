# Conventions des spikes

- **Stack** : Node ≥ 18, zéro dépendance, modules ESM `.mjs`. Lecture seule sur le dépôt observé ;
  les sorties vont dans un dossier qui s'ignore lui-même (`floorplan/`).
- **Code tiers** : copie figée dans le dossier du spike, avec sa licence et un `VENDORED.txt` qui
  donne la version, le commit et chaque patch (marqué `vibeflow Pn` dans le source).
- **JSON inliné dans du HTML** : échapper `</script`, U+2028 et U+2029. Écrire ces échappements
  sous forme ASCII, car certains outils d'écriture les convertissent en caractères réels.
- **Preuve visuelle** : captures dans `captures/` du spike, prises dans un vrai navigateur sur le
  dépôt réel, jamais sur un jeu de démonstration.
- **Direct** (spikes 001, 003) : serveur Node sans dépendance, SSE + `fs.watch` récursif, anti-rebond
  de 300 ms, plus un filet de scrutation de 5 s (un dossier qui naît après le démarrage n'est pas
  surveillé, et un âge avance sans écriture). Journal forensique servi sur un endpoint (`/log`).
- **Sondes sur bac à sable** (spikes 003, 004) : toute mutation de `.planning/` ou d'un verrou se
  fait sur une copie git dans le scratchpad, jamais sur le dépôt ; la sonde refuse le chemin réel.
- **Lire du JSON servi** : `fetch` Node direct, jamais `curl` à travers rtk (sortie corrompue).
- **Témoin positif d'abord** (spikes 001, 004) : avant de conclure « personne / rien », produire un
  cas qui doit être vu (session, sous-agent en arrière-plan lancé exprès, verrou pris) et vérifier
  qu'il l'est.
- **Extension du viewer** (spikes 002, 003) : un fichier par fonction dans `assets/ui/NN-vf-*.js`,
  injecté au build, qui ne parle au viewer que par `window.Floorplan` (et les patchs `vibeflow Pn`).
  Chaque extension expose une sonde `window.__vf*` lue par Playwright pour prouver sans capture.
- **Écriture d'un fichier lu en concurrence** (spikes 003, 004) : `.tmp` puis `rename`, jamais
  `open(file, "w")` direct ; côté lecteur, un retrait n'est cru qu'après une seconde lecture.
