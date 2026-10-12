---
name: project-phase57-verrou-compartiment-audit
description: Audit sécu Phase 57 (verrou de driver par compartiment, HEAD cc17e5f1, 2026-10-11) : SECURED, 3 résiduels hors registre (casse de .planning, cwd sous-dossier, globals git)
metadata:
  type: project
---

Phase 57 audit (45 menaces T-57-01..44 + SC) : SECURED, 4 suites rejouées vertes (492/180/30/54) et mutants
personnels qui mordent (excepthook, casefold, fsmonitor). Résiduels non bloquants : F-1 `.PLANNING` en casse
différente passe le préfiltre C4 du guard Write/Edit sur APFS ; F-2 `--ws` sans effet depuis un sous-dossier du lab
(acquire réussit, `.planning/DRIVER.lock` parasite, guard plat) ; F-3 `git --no-pager commit` non reconnu.

**Why:** le guard est déclaré anti-accident (CONCERNS.md, Phase 32), donc ces trous restent medium/low ; mais F-2 est
un vrai silence de l'exclusion mutuelle.

**How to apply:** si la Phase 57 est ré-auditée après correctifs, rejouer F-1/F-2 d'abord (payload Write `.PLANNING/...`
et `acquire --ws` depuis `plugin/sub/` dans un dépôt jetable) ; le gate E1 résout `~/.claude/scripts/driver-lock.sh`
ancien (sans --ws) -> INDETERMINE, c'est le comportement voulu (T-57-23), pas un bug. Voir [[feedback-execute-dont-trust-green]].
