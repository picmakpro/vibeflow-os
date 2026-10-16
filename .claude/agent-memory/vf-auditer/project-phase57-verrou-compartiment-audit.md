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

## Second passage (2026-10-12, corrections R-4..R-7, F-3, C3, HEAD 8b957f62..c580b45e) : passed, 6 lows

F-1/F-2 rejoues OK (.PLANNING, cwd sous-dossier, not-at-lab-root). R-4/R-6 fermes (mutant c rejoue : 12 KO attendus). Lows restants :
R-5 partiel (`cd <hors lab> && GIT_DIR=<lab>/.git GIT_WORK_TREE=<lab> git commit` ALLOW et embarque alpha, car
git_target/bash_targets_outside_lab ignorent le prefixe ; `export GIT_INDEX_FILE=..; git commit` ALLOW) ; F-3 famille
(`--git-dir X` en deux jetons, `--config-env=`, `env -u X`, `nice -n`, `exec -a`, `bash -c` : ALLOW, identiques a la base) ;
R-7 epingle editable avec la fixture (suite couverte par G-2 declaratif, tests/fixtures/ non couvert) ; CONCERNS.md Phase 57
perime ; WS-ALL-5 insere au milieu du groupe WS-ALL-3 (3.8-3.10 tournent desormais sur le lab all5) ; takeover sans sonde legacy.

**How to apply:** si un 3e passage a lieu, rejouer d'abord les formes `cd`+`GIT_DIR=` et `export` ; les suites se rejouent
avec `GW_GUARD=<abs>` (chemin ABSOLU, un relatif donne 135 faux KO) et `DLWS_MODE=matrice`.
