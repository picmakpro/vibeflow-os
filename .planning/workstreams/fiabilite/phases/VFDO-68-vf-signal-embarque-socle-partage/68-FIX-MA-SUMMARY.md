# 68-FIX-MA — résumé (lot A)

**P68-D-34** (arbitrage Samuel, AskUserQuestion, session principale Claude Code, 2026-11-04). `hooks/actions.ts` : le lanceur « Ouvrir le cockpit » se cherche dans le compte puis dans le plugin ; le repli `driver-lock.sh` de l'élagage dans le plugin puis le compte (`resoudreDriverLock`). Le chemin du lab n'est plus jamais candidat. Un candidat du compte est refusé si son chemin ou son realpath tombe sous le lab ; le realpath vient de `$.fs.stat(chemin, { resolve: true }).realPath` (disponible dans l'API des mods), et à défaut la règle se rabat sur le chemin tel qu'écrit. Même règle que `driverLockScript`/`realUnder` (T-67-06) : les candidats « module » (racine du plugin) ne sont refusés que sous `<lab>/.vibeflow`. Le lanceur du plugin reste le repli inconditionnel, comme avant.

**P68-D-35 R2.** `hooks/views/equipe.tsx` : « voir » et « demander l'arrêt » vont à tout agent présent dans `$.agent.list()` dont le statut n'est pas `completed`/`failed`/`killed`, quel que soit l'état who@2.

**P68-D-35 R3.** Les terminés (who@2) qui ne sont pas vivants pour la session se replient derrière un bouton « N terminé(s) » (clé `finis`), placé après les actifs, orphelins compris ; il déplie. Le choix tient à une variable du module, la pane se redessine par `$.ui.invalidate('ui.render')` (la pane n'est pas du lot A). Le compact ne change pas.

Hors lot nommé, touchés au minimum (voir la trace) : `tests/vf-signal.test.tsx` (R6-K10b, 299 lignes), `tests/citation-controles.test.tsx` (FX-3b), `tests/graphite.test.tsx` (R8-G5b), `tests/lab-fix.ts` (option `home`).
