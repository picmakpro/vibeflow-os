---
name: sonde-inline-zsh-parse-le-case
description: Le shell du poste est zsh — un case inline dans un appel Bash meurt en parse error ; et le rejeu du job tests dépasse le timeout d'outil de 600 s
metadata:
  type: project
---

Deux pièges d'exécution de sondes sur ce poste, constatés le 2026-09-23 (Phase 41.1).

**1. Le shell est `zsh`.** Un `case … esac` écrit **inline** dans un appel de l'outil Bash est parsé
par zsh et meurt en `parse error`, même quand le corps est du Bash valide. Même famille que les
autres outils menteurs du poste, sauf que celui-ci échoue bruyamment.
**How to apply:** toute sonde qui contient un `case` (ou une construction dont la syntaxe diffère
entre zsh et bash) va dans un **fichier script** lancé par `bash fichier.sh`, jamais en une ligne.
Le mandat des workers doit le dire : sinon le worker perd un tour à diagnostiquer, et pire, peut
conclure « la sonde ne marche pas » au lieu de « mon shell n'est pas celui que je crois ».

**2. `replay-ci-jobs.sh --job tests` dépasse le timeout d'outil de 600 s** (85 suites sur ce dépôt).
Un worker qui le lance au premier plan le voit expirer.
**How to apply:** le lancer **détaché** et attendre sa **vraie** sortie. Ne jamais conclure un vert
sur un timeout — c'est un `0/N` déguisé, cf. [[project_timeout-absent-faux-zero]]. À écrire dans
chaque mandat d'exécution qui demande une non-régression complète.

**Corollaire d'ordonnancement, même phase** : `test-check-description-fidelity.sh` porte un
self-check `git diff --stat -- plugin` qui rougit (T10) si l'arbre est **sale** pendant le rejeu.
Donc : **commiter AVANT de rejouer**, sinon le worker diagnostique une régression qui n'existe pas.

**3. Flake connu de `--job tests` — une CLASSE, pas un cas** :
`plugin/conductor/scripts/tests/test-check-agents.sh` rougit par intermittence partout où elle fait
`OUT="$(…)"` puis `echo "$OUT" | grep -q …` — `grep -q` sort avant la fin de l'`echo`, SIGPIPE non
déterministe, `echo: write error: Broken pipe`. **Deux cas mesurés le 2026-09-23/24 (Phase 41.1),
indépendamment : T9 (l.227) et T29 (l.511).** Vert 3/3 en isolation et en passe suivante du job
complet, à chaque fois. Pré-existant.
Traiter tout rouge de cette suite comme un **membre présumé de la famille** : chercher le motif
`echo "$OUT" | grep -q` sur la ligne incriminée avant de suspecter sa propre modification.
**Trois instances mesurées en deux jours : T9 (l.227), T29 (l.511), T32.**

**4. `--job tests` n'est PAS un oracle fiable sur ce poste.** Mesuré le 2026-09-24 : deux rejeux
consécutifs rouges avec une suite **différente** à chaque fois (`test-check-agents.sh T32`, puis
`test-dev-orchestrator.sh T2b scope=local` — ce dernier étant un flake de **concurrence**, pas de
SIGPIPE), **les deux vertes en isolation** dans le même arbre. Un rejeu complet peut donc ne jamais
être vert en une passe, sans aucune régression réelle.
**How to apply:** l'oracle d'une PR est **la CI GitHub**, jamais un rejeu local séquentiel. Exiger
du worker qu'il (1) rejoue la suite incriminée **isolément**, (2) démontre le **découplage** — ses
fichiers modifiés ne sont pas lus par la suite rouge —, et seulement alors consigne un flake. Ne
jamais exiger « un rejeu complet vert » comme condition de clôture : c'est demander de la chance.
**How to apply:** un rouge isolé sur cette suite dans un rejeu complet n'est **pas** une régression
tant qu'il n'est pas reproduit **en isolation**. Le dire dans les mandats, sinon un worker
diagnostique sa propre modification pendant un tour entier. Ne pas le corriger au passage : il est
pré-existant et hors périmètre de la phase courante (règle
[[feedback_phase-cree-ferme-revele-consigne]]) — candidat BACKLOG.

Voir aussi [[project_grep-proxifie-tronque]], [[project_ls-proxifie-rend-vide]],
[[project_find-proxifie-tronque-par-intermittence]].
