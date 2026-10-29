---
name: ci-cancelled-36min-runner-uutils
description: Job « Suites de tests » annulé vers 36 min puis « Complete job » bloqué ~45 min (oct. 2026) — la cause réparée était le runner Ubuntu 26 à coreutils uutils (lot A, #168), pas la charge des mutants
metadata:
  type: project
---

Fin octobre 2026, le pas « Découvrir et lancer toutes les suites » passait `cancelled` à ~36-37 min sur
main et sur toutes les branches, puis « Complete job » restait bloqué ~45 min avant l'échec. J'ai
attribué ça à `test-guard-driver-lock-ws.sh` (55 matrices de mutants en arrière-plan sans borne) et
ouvert #171 (borne `GW_MUT_PAR`). Entre-temps une autre session a mergé #168 (driver-lock sous uutils,
`ln -sn` seul, `mv -nT`) et le job est repassé vert en 55-57 min SANS la borne : l'hypothèse « charge »
n'était pas démontrée. Les logs d'un run annulé par `force-cancel` ne sont jamais récupérables
(BlobNotFound) ; un `cancel` simple attend la fin du blocage.

**Why:** j'ai bâti un correctif sur une corrélation (suite active au moment de l'annulation) sans
témoin, pendant que la vraie cause (changement d'image runner) se corrigeait ailleurs.

**How to apply:** un `cancelled` à heure fixe sur GitHub Actions → regarder d'abord l'image du runner
et les PR des autres sessions (`gh pr list`, leurs runs) avant de toucher une suite ; ne merger un
correctif d'infra que s'il a un témoin (run rouge sans, vert avec). Voir [[lire-la-ci-de-la-branche-des-la-reprise]].
