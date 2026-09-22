---
name: collision-planning-gouvernance
description: Le travail gouvernance local et origin/main réorganisent .planning/ de deux façons incompatibles — tout alignement bute sur cet arbitrage avant les conflits de texte
metadata:
  type: project
---

**La branche de travail gouvernance et `origin/main` ont réorganisé `.planning/` de deux façons
concurrentes.** Côté gouvernance, la partition en workstreams déplace `.planning/phases/` vers
`.planning/workstreams/{dev,gouvernance}/phases/`. Côté `origin/main`, les mêmes phases ont été
archivées vers `.planning/milestones/agentique-v1.0-phases/`, et **`origin/main` n'a jamais adopté
la partition** — le mécanisme workstream a bien été durci côté dev (Phase 39 mergée,
`check-divergence.sh`, famille PART) mais le `.planning/` distant est resté plat.

**Why:** constaté le 2026-09-22 en alignant `main` (820 commits de retard, v2.43.1 → v2.63.2).
Une simulation `git merge-tree` annonce 135 conflits, dont **116 rename/rename** qui viennent tous
de cet arbitrage. Les 9 conflits de contenu réels sont banals : les deux README, plus
`VERSION`/`module.json` de `conductor` et `infrastructure-audit`.

**How to apply:** ne jamais présenter l'alignement de la branche gouvernance comme une opération
mécanique. La question à trancher d'abord est *« la partition en workstreams survit-elle ? »* — pas
*« merge ou rebase ? »*. La section « workstreams » de `CLAUDE.md` est une doctrine posée par la
polarité gouvernance en local ; elle n'existe pas dans le `CLAUDE.md` de `origin/main`. Tant que
l'arbitrage n'est pas fait, fast-forwarder `main` seul et laisser la branche de travail intacte.

**Corollaire — la Phase 1 gouvernance est probablement caduque.** Son `STATE.md` dit lui-même
« prête à exécuter APRÈS merge PR #27 + remise à niveau », or la Phase 38 (portabilité
multi-runtime) a depuis été mergée dans `main` : `plugin/_internal/lib/vf-portable.sh`, ses tests,
`test-windows-crlf.sh`, et un `.planning/WINDOWS.md` à 4 fixés / 1 waivé / 0 ouvert sur 5. Avant
de relancer cette phase, confronter le contrat figé dans `docs/CONTRAT-PORTABILITE.md` à
l'implémentation réellement livrée.

Voir [[verifier-fraicheur-avant-audit]] et [[collaboration-sam]].
