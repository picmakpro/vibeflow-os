---
name: gate-repo-wide-en-acceptance-criteria
description: Un gate repo-wide exigé vert par un plan peut être rouge à cause d'un fichier hors de son `<files>` — déviation déclarée minimale, pas un HALT
metadata:
  type: feedback
---

Quand un plan met un **gate repo-wide** dans ses `<acceptance_criteria>` (`check-machine-paths.sh`
exit 0, un compteur de suites, un lint global…), ce gate peut être rouge pour une raison **hors du
`<files>` du plan**. Ce n'est ni un HALT ni un critère à sauter en silence : c'est une **déviation
encadrée** — correction *minimale* du fichier fautif, **commit séparé** explicitement étiqueté
déviation, consignée au SUMMARY.

**Why:** Phase 28 (2026-08-14). `28-02-PLAN.md` exigeait `check-machine-paths.sh` exit 0, alors que
son `<files>` ne déclarait que `check-capability-activation.sh`. Le rouge venait d'un chemin machine
absolu dans `28-RESEARCH.md:858`, posé par le commit de cadrage `ad03fc6`, **bien avant** la mission
— les deux juges de 28-01 l'avaient déjà signalé sans que personne ne puisse le corriger dans son
périmètre. Sans encadrement, le worker aurait soit halté sur un critère satisfaisable, soit élargi
son périmètre de lui-même.

**How to apply:** dans le mandat, borne la déviation à l'avance : « si la **seule** violation est
celle-là, corrige-la minimalement (forme portable, **aucune reformulation**, nombre de lignes du
fichier inchangé — d'autres docs le citent par ligne), commit séparé étiqueté déviation ; s'il y en
a d'autres ou si ce n'est pas trivialement sûr, HALT ». Vérifie que le fichier fautif est bien
antérieur à la mission (`git log` sur le fichier) avant d'autoriser quoi que ce soit.

**Piège auto-infligé observé :** en documentant la correction, le worker a recopié le chemin machine
**en littéral** dans `28-02-SUMMARY.md` et re-rougi le gate (2 occurrences). Exige la forme
documentaire neutre (`/Users/<user>/…`) dès le mandat quand le sujet du commit *est* un chemin machine.

Voir aussi [[verifier-contre-le-commit-de-base]], [[mandat-cumulatif-jamais-exclusif]].
