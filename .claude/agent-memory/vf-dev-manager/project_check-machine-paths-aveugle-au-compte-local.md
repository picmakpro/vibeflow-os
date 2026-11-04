---
name: check-machine-paths-aveugle-au-compte-local
description: check-machine-paths vert en local, rouge en CI sur /Users/<compte local> — une trace citée verbatim depuis le scratchpad passe tous les rejeux locaux puis casse la PR
metadata:
  type: project
---

En Phase 71 (2026-11-04), `71-01-RED-TRACE.md` citait une sortie verbatim contenant `/Users/samuel/.local/bin/claude`.
`bash scripts/check-machine-paths.sh` a été vert à CHAQUE rejeu local pendant deux jours (job `gates` rejoué 4 fois par
replay-ci-jobs.sh), puis le job `gates` de la PR #203 a rougi en 10 s sur cette ligne (« segment de compte samuel »).
Le gate local ne voit pas le compte qui le lance ; le runner, si.

**Why:** les traces de rouge, résumés de correcteurs et rapports d'auditeurs recopient des sorties brutes pleines de
chemins du poste ; le seul témoin local de ce gate est aveugle à exactement ce cas.

**How to apply:** avant d'ouvrir une PR, faire un `grep -rn "/Users/$(whoami)\|/private/tmp\|/private/var"` sur
le diff de la branche (pas seulement le gate), et dans chaque mandat qui écrit une trace verbatim exiger `~` ou
`/Users/<user>`. Voir [[rapport-de-mission-passe-les-gates]] et [[liste-de-gates-jamais-la-reference]].
