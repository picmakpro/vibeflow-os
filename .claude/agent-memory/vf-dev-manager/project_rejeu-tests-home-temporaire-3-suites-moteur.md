---
name: rejeu-tests-home-temporaire-3-suites-moteur
description: rejouer le job CI tests sous HOME temporaire fait échouer 3 suites sur « moteur gsd-core introuvable » ; c'est un artefact du rejeu, à rejouer avec le moteur réel avant de conclure
metadata:
  type: project
---

Mesuré le 2026-10-29, lot B, tête d4d96859 : `replay-ci-jobs.sh --job tests` sous `HOME=$(mktemp -d)` (avec PYTHONUSERBASE conservé) donne 112 suites, dont 4 échecs dans 3 suites :
- `test-check-planning-not-inflight.sh`,
- `test-split-planning.sh`,
- `test-check-gsd-config.sh` (cas 20 et 26).

Le motif est le même partout : « moteur gsd-core introuvable ». Le rejeu saute l'étape « Installer le moteur GSD » de la CI. Rejouées avec le HOME réel, les trois suites sont vertes (37/0, 69/0, 38/0).

**Why:** ces suites refusent volontairement de se dégrader en skip. Sans le moteur, elles rendent KO, et ce KO ressemble à une régression.

**How to apply:** avant d'attribuer un rouge du rejeu `tests` à la branche, grep `introuvable` dans le journal de l'étape, puis rejouer les suites désignées avec le moteur réel. Deux autres pièges à connaître :
- le `ps` proxifié par rtk peut rendre vide sur un process vivant : utiliser `rtk proxy ps -p <pid>` / `pgrep -P` ;
- le journal de l'étape n'est écrit qu'en fin d'étape, compter environ 50 min pour ce job.

Voir aussi [[ci-tests-shallow-pyyaml-user-site]] et [[rejeu-long-detache-nohup]].
