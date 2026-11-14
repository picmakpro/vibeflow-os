---
name: jeton-de-suites-et-attentes-orphelines
description: Sous charge, un jeton mkdir « une suite à la fois » par groupe tient ; les boucles until…sleep des workers survivent à leur fin et gèlent sous zsh
metadata:
  type: project
---

Mission « retours panel, Code et moteur » (2026-11-06/07) : quatre managers dans la même session ont saturé le poste (81 suites, 49 cockpits, swap plein) ; la session principale a imposé UNE suite à la fois par groupe. Un jeton `mkdir` partagé (`une-suite.sh <worktree> <suite> <sortie>`, PID dans le verrou, nettoyage du verrou mort) a tenu toute la nuit sans collision.

Deux défauts venaient des workers, pas du jeton :
- un worker a écrit `for p in "$T suite"…; set -- $p` : sa commande Bash tourne sous zsh, qui ne découpe pas les mots → le jeton sort en usage, le fichier de rc reste vide, et son `until [ $(wc -l) -ge 6 ]; do sleep 10; done` a tourné 47 min jusqu'à mon réveil ;
- les boucles `until … sleep` d'un worker fini restent vivantes des heures (5 shells orphelins de M1, 7 h 30 après son rapport), sans enfant, parent = le processus claude.

**Why:** le scratchpad et le poste sont partagés entre groupes ; un orphelin ou une boucle bloquée ne se voient que par `ps`.
**How to apply:** dans chaque mandat, exiger un appel du jeton par suite avec les trois arguments en clair, en arrière-plan, fin attendue par la notification, jamais de boucle `until` ; namespacer le scratchpad du groupe dès le départ (`scratchpad/<groupe>/`) ; en fin de mission, `pgrep -fl <chemins du groupe>` et tuer par PID les shells sans enfant. Voir [[transcript-fige-ne-prouve-pas-worker-mort]], [[verify-des-plans-sous-zsh]].
