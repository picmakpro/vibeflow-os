---
name: requirements-supprime-a-la-cloture
description: gsd-core supprime .planning/REQUIREMENTS.md à chaque clôture de jalon — aucun lab conforme n'a de ledger d'exigences durable, et celui de vibeflow-os est une déviation manuelle
metadata:
  type: project
---

`gsd-complete-milestone` fait un `git rm` de `.planning/REQUIREMENTS.md` à chaque clôture de
jalon — **inconditionnellement** : pas de flag, pas de gate (`~/.claude/gsd-core/workflows/complete-milestone.md`
l. 441-533 et 781-791). `new-milestone.md:475` le régénère ensuite **de zéro**. Établi et
contre-vérifié le 2026-07-28 (étude Phase 18, gsd-core 1.8.0).

Conséquence non évidente : **aucun lab conforme à GSD ne possède de ledger d'exigences durable.**
Le `.planning/REQUIREMENTS.md` à 6 jalons de `vibeflow-os` est une **déviation manuelle non
reproductible** — il a survécu parce que personne n'a lancé la clôture standard, pas parce que le
moteur le préserve. Corollaire : `ROUT-01` existe déjà en 3 copies (`REQUIREMENTS.md` + les deux
archives `milestones/*-REQUIREMENTS.md`), supersets emboîtés aux 9 premières lignes identiques et
sans en-tête d'archive — trois candidats indiscernables à la vérité, pas trois strates historiques.

**Why:** toute proposition de « mémoire de ce que le système EST » (specs vivantes, ledger,
registre d'exigences) bute sur ce fait. Il tranche dans les deux sens : le besoin est **réel au
niveau framework** (rien ne survit), mais **déjà servi artisanalement sur ce repo** (d'où le risque
de double état si on ajoute un registre sans nommer celui qu'on remplace).

**How to apply:** (a) ne jamais supposer qu'un document `.planning/` accumulé survivra à un
`/gsd-complete-milestone` — vérifier dans `complete-milestone.md` avant de bâtir dessus ;
(b) toute mission qui propose un nouveau registre d'état doit **nommer le fichier qu'elle
remplace**, sinon elle crée mécaniquement un état de plus ; (c) le seul geste à valeur nette
identifié est de faire *survivre* `REQUIREMENTS.md`, ce qui exige une RFC upstream chez
`open-gsd/gsd-core` — dépendance critique hors contrôle, pas un bonus. Voir
[[citation-lifecycle-planning]] (l'archivage efface aussi les citations du ROADMAP) et
[[artefacts-descriptifs-non-testes]].

Piège de vocabulaire associé : « capability » est **déjà pris** sur ce repo avec un autre sens
(`plugin/conductor/skills/vf-new-lab/references/capability-manifest.md:11` — « une capacité = un
skill à créer », IDs `CAP-01…`), dans un repo qui a ADR-057 et `check-overlaps.sh` pour interdire
exactement ça.
