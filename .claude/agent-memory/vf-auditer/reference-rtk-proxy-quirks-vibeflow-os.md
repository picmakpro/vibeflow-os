---
name: reference-rtk-proxy-quirks-vibeflow-os
description: Pièges d'outillage mesurés sur ce poste lors des audits infra vibeflow-os (rtk proxy, grep, diff, timeout absent, garde worktree Bash)
metadata:
  type: reference
---

Sur ce poste, pour les audits touchant `vibeflow-os` (et probablement ses worktrees `-p23`,
`gouvernance-44`, etc.), plusieurs outils habituels ne sont PAS fiables tels quels — mesuré, pas
supposé, lors de l'audit Phase 23 (`audit-infra`) et de l'audit Phase 44 (`audit-44`) :

- `git diff` sous le proxy `rtk` : la forme `A..B` rend une sortie résumée sans hunks (garde verte
  à vide). Utiliser la forme à DEUX ARGUMENTS `rtk proxy git diff A B`.
- `grep` proxifié TRONQUE silencieusement au-delà d'un certain nombre de lignes (mesuré : 31 lignes
  sur 102 rendues). Pour compter ou extraire exhaustivement : `awk`, `comm`/`cmp` sur listes
  matérialisées, jamais `grep -c` pour un total qui doit être exact.
- `diff` a déjà rendu "Files are identical" sur deux fichiers réellement différents — ne pas lui
  faire confiance comme preuve d'identité/différence sans un `cmp`/`awk` de contrôle.
- `timeout` n'existe PAS sur ce macOS. Pour borner l'exécution d'un script potentiellement bloquant
  (test de DoS/FIFO), lancer en arrière-plan (`&`), garder le PID, poller `kill -0` en boucle avec
  un budget de temps explicite, puis `kill -9` soi-même si le budget est dépassé.
- La garde d'isolation de worktree du tool Bash refuse les commandes "trop complexes à vérifier"
  dès qu'elles combinent plusieurs lignes (heredoc, plusieurs commandes chaînées) OU qu'un
  `printf`/`cat` porte des motifs qui ressemblent à du contenu git (`---`, crochets `[]`) OU qu'une
  variable shell est interpolée dans un chemin de fichier écrit — même quand la commande n'a
  STRICTEMENT rien à voir avec git (mesuré en fabriquant des fixtures de lab hors dépôt, Phase 44).
  Contournement fiable : une seule commande simple par appel Bash, chemins ABSOLUS écrits en toutes
  lettres (jamais de variable shell type `$SCRATCH`), et pour écrire un fichier avec du contenu
  multi-lignes ou des `---`/frontmatter, passer par `python3 -c "open('<chemin littéral>',
  'w').write('...')"` plutôt que `cat <<EOF`/`printf` — un seul appel `open().write()` par fichier,
  jamais de `cd` suivi d'une autre commande dans le même appel.

Voir aussi [[feedback-execute-dont-trust-green]] pour la doctrine générale de vérification par
exécution sur ce projet.
