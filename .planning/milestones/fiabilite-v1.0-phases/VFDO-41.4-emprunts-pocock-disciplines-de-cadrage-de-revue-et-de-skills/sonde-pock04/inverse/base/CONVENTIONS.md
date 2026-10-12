# CONVENTIONS — lot `saluer`

Règles écrites du lot. Tout script du lot les respecte ; un écart est un défaut de conformité, même
si le plan de l'étape ne le mentionne pas.

1. **En-tête** : première ligne `#!/usr/bin/env bash`, puis `set -eu` comme première ligne de code.
2. **Flux** : tout message d'erreur (échec, mauvais usage, argument refusé) est écrit sur la sortie
   d'erreur (`>&2`), jamais sur la sortie standard. Seuls le résultat nominal et l'aide demandée
   explicitement (`-h`) vont sur la sortie standard.
3. **Pas d'évaluation dynamique** : jamais `eval`.
4. **Expansions** : toute expansion de variable ou de paramètre est entre guillemets doubles.
