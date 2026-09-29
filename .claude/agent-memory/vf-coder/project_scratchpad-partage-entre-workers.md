---
name: scratchpad-partage-entre-workers
description: Le scratchpad de session est partagé par tous les workers d'une même mission — un fichier de sortie homonyme d'un worker précédent se lit comme le sien
metadata:
  type: project
---

Le répertoire scratchpad (`/private/tmp/claude-501/<projet>/<session>/scratchpad`) est **partagé
par tous les workers d'une même mission**, pas privé au worker courant. Vécu le 2026-09-24 (plan
41.1-08) : `cat $S/tests.rc` a rendu un bilan COMPLET (`87 suite(s), 0 échec(s)`, `rc=0`) alors que
mon propre rejeu tournait encore — pgrep le montrait vivant. Le fichier venait d'un worker
antérieur du même nom. Le listing du dossier portait 234 entrées, dont `tests2.rc`, `tests3.rc`,
`replay-tests.out`, `gates.rc` — tous d'autres lots.

**Why:** j'ai d'abord soupçonné `rtk` de mentir (cache de sortie), ce qui m'a coûté plusieurs
tours ; la cause était banale et le risque bien pire — conclure un vert sur le rejeu de quelqu'un
d'autre, exactement la faute que `ne-jamais-affirmer-un-resultat-de-sous-agent-non-recu` interdit.

**How to apply:** nommer tout artefact de sortie avec un préfixe propre au lot (`l08-tests.rc`),
OU `rm -f` la cible AVANT de lancer, OU vérifier que le processus est terminé avant de lire. Ne
jamais lire un `*.rc`/`*.log` sans avoir la preuve qu'il est le sien : tester `pgrep` sur le
producteur, et se méfier de tout contenu plus riche que l'avancement observé. Voir aussi
[[diff-proxifie-utiliser-comm]] pour la famille « l'outil ne dit pas ce qu'on croit ».
