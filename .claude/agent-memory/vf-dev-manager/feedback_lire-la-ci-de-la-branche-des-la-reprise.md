---
name: lire-la-ci-de-la-branche-des-la-reprise
description: une branche déjà poussée peut être rouge en CI Linux alors que toutes les suites sont vertes sur macOS ; lire `gh run list --branch` au démarrage, pas au moment de la PR
metadata:
  type: feedback
---

Au démarrage d'une reprise (ou dès le premier push), lire la CI de la branche :
`gh run list --branch <branche>` puis `--log-failed` du dernier run rouge.

**Why:** Phase 44 (2026-09-28) — la branche avait été poussée une fois (`ca185e4`) et sa CI était
rouge (`test-recalc-planning.sh` R14 : `stat -f "%Lp" … || stat -c "%a"` concatène un bloc
système de fichiers sous GNU). Cinq lots, quatre tours de juges et trois gsd-verifier ont tous dit
« vert » sur macOS ; le défaut n'est apparu qu'au moment de la PR. Aucun juge ne rejoue sous Linux.

**How to apply:** à la reprise, relever la CI de la branche avant tout dispatch et l'injecter dans le
premier mandat si elle est rouge. Dans tout mandat qui ajoute des tests shell, exiger que la
sémantique ne dépende pas de GNU vs BSD (`stat`, `sed -i`, `readlink -f`, `date`), de préférence via
`$PYBIN`. Rejeu local du job `tests` : toujours sous `HOME=$(mktemp -d)` — un rejeu lancé avec le
vrai HOME a dû être interrompu et audité après coup. Voir aussi [[rejeu-ci-avec-le-mauvais-shell]].
