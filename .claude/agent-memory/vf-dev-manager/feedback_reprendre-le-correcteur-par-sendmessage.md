---
name: reprendre-le-correcteur-par-sendmessage
description: Un vf-coder terminé se reprend par SendMessage avec tout son contexte — moins cher qu'un redispatch pour une 3e passe de correction ; et chaque passe de correction doit repasser devant un checker frais
metadata:
  type: feedback
---

Un worker dont la tâche est **terminée** se reprend par `SendMessage(to: <agentId>)` : le runtime le relance
avec son transcript (« Resuming agent »). Mesuré Phase 69 (2026-11-03) : 3e passe de correction des plans
en ~1,5 min et 7 appels d'outil, contre ~5 à 9 min pour un vf-coder neuf. Nuance la note de
[[base-de-diff-derivee-du-parent]] : un worker *en cours* n'est pas rattrapable, un worker *fini* l'est.

**Why:** la passe n°2 (fermer 3 warnings) a créé un blocker — commande de mutation posée dans la mauvaise
tâche et sur le mauvais fichier, échec garanti. Le correcteur qui l'avait écrite avait le contexte pour la
réparer en 16 lignes ; un checker frais, scopé au seul diff, l'a validée en ~70k jetons.

**How to apply:** boucle correction → checker frais scopé au diff (`git diff <avant>..<après>`), jamais
« passed » sur la déclaration du correcteur ; correction suivante par SendMessage au même correcteur ;
`driver-lock.sh register` à nouveau avant la reprise, `close` au retour. Voir
[[revalider-les-plans-ecrits-avant-les-faits]].
