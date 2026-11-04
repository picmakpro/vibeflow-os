# 68-FIX-FIN-WEB — trace rouge puis vert (dernière passe web et doc)

Décisions : P68-D-41 (arbitrage Samuel, AskUserQuestion, session principale Claude Code, 2026-11-04 : AD-1 « Rafraîchir si pane ouverte (Recommandé) », AD-2 « L'écrire sans mesurer (Recommandé) »). Constats de `68-RELECTURE-ADVERSE.md` : M-3, M-4, M-5, M-6, AD-1, AD-2.

## Rouge (avant correctif)

| Point | Témoin | Résultat avant |
|---|---|---|
| M-3 | `test-cockpit-chrome-fr.sh` F10c (Chromium propre, `chrome-verrou-prefixe.mjs` : verrous `fiabilite` 40 s puis `fiabilite-2` 600 s, même propriétaire) | `FAIL`, obtenu `[true,false]` : la ligne `fiabilite-2` prend l'âge de `fiabilite` |
| AD-2 | `grep -c "aucune version minimale" plugin/cockpit/README.md` | 1 |
| AD-2 | `grep -c "vérifiée sous Claude Code 2.1.318" 68-RELECTURE-ADVERSE.md` | 0 |
| M-4 | `grep -c "3 s sur ce dépôt (14 worktrees)" plugin/cockpit/README.md` | 1 |
| AD-1 | `grep -c "toutes les 10 secondes" plugin/cockpit/README.md` | 1 |
| M-6 | `grep -ci "sans .conductor." plugin/cockpit/README.md` | 0 |
| M-5 | `grep -c "et les trois points de procédure" 68-11-PLAN.md` (le premier grep tenté, sur « avec leur canal … plus aucun », ne discriminait pas : il vise aussi D-22 à D-25, légitimes) | 1 (les trois points de procédure rejoignent la liste des arbitrages à canal AskUserQuestion) |
| notes | `grep -c "\[AD-1\]\|\[AD-2\]" 68-RELECTURE-ADVERSE.md` | 2 (phrases conditionnelles non reprises sur l'arbitrage) |

## Correctif

`70-vf-live.js` `ageDe` : la valeur `tree` du verrou se reconstruit comme `vf-cockpit-who.mjs` (`compartiment <ws>[ phase <N>]`, sinon la portée) et se compare par égalité ; repli sur le seul verrou du propriétaire, sinon sur l'`ageS` du `who`. README, CHANGELOG, notes de release et libellé du plan corrigés.

## Vert

| Point | Témoin | Résultat après |
|---|---|---|
| M-3 | F10c | PASS (`test-cockpit-chrome-fr.sh` : 31 PASS / 0 FAIL) |
| AD-2 | `grep -c "aucune version minimale"` README ; `grep -c "vérifiée sous Claude Code 2.1.318"` README et notes | 0 ; 1 ; 1 |
| M-4, AD-1 | `grep -c "3 s sur ce dépôt (14 worktrees)\|toutes les 10 secondes"` README | 0 |
| M-6 | `grep -ci "sans .conductor."` README | 1 |
| M-5 | `grep -c "et les trois points de procédure"` 68-11-PLAN.md | 0 |
| notes | `grep -c "\[AD-1\]\|\[AD-2\]"` | 0 |
