# 68-FIX-MA — trace rouge puis vert (lot A)

Décisions : P68-D-34 (arbitrage Samuel, AskUserQuestion, session principale Claude Code, 2026-11-04 : « Rien sous le lab (Recommandé) ») et P68-D-35 (même canal, même date : « Tout selon les recos (Recommandé) »). Harnais : `claude plugin test plugin`.

## Rouge (code d'avant, 103 pass puis 13 fail sur les témoins neufs `tests/lot-a.test.tsx`)

| Témoin | Assertion | Attendu | Obtenu |
|---|---|---|---|
| MA-D34a | lanceurs lancés sous `/lab/` | `[]` | `["/lab/.claude/scripts/vf-cockpit.mjs"]` |
| MA-D34b | lanceur du compte, lien de realpath `/lab/vendu/…` : lancé ? | `false` | `true` |
| MA-D34c (positif) | lanceur lancé avec lab + compte plantés | `["/home/user/.claude/scripts/vf-cockpit.mjs"]` | `["/lab/.claude/scripts/vf-cockpit.mjs"]` |
| MA-D34e | bouton `elaguer` avec seul `<lab>/.claude/scripts/driver-lock.sh` | `undefined` | un bouton |
| MA-D34f | bouton `elaguer`, script du compte lien vers le lab | `undefined` | un bouton |
| MA-D34g (positif) | script lancé | `["/home/user/.claude/scripts/driver-lock.sh"]` | `["/lab/.claude/scripts/driver-lock.sh"]` |
| MA-R2a | `voir:c1` pour un agent `termine` dans who@2, `running` dans la liste | défini | `undefined` |
| MA-R3a / R3b / R3d | 150 terminés + 3 actifs : compteur « 150 terminés », terminés repliés | défini / non rendus | terminés rendus, pas de compteur |

MA-D34d (repli sans realpath) avait d'abord rougi pour une mauvaise raison (`on("fs.stat")` enregistré deux fois) : réécrit avec une option `sansReel`, il passe sur le code corrigé et rougit sous le mutant M1. MA-R2b et MA-R3c passaient déjà (négatifs gardés).

## Vert

`claude plugin test plugin` : 116 pass, 0 fail (103 d'avant + 13). `claude plugin validate --strict plugin` : passé. `test-cockpit-signal-mod.sh` : bash 40 ok / 0 ko, zsh 40 ok / 0 ko. `check-machine-paths.sh` : ✓ ; `awk '/\/(Users|home)\/…/'` sur les fichiers touchés : seuls les `/home/user` de fixture, déjà la convention des suites.

## Mutants tués

| Mutant | Tué par |
|---|---|
| M1 : lanceur du lab réintroduit en tête | A1, A1d, MA-D34a, b, c, d |
| M2 : realpath ignoré (`reel` rend le chemin) | MA-D34b, MA-D34f |
| M3b : repli driver-lock sous le lab, sans garde | MA-D34e, f, g, R6-K10b |
| M4 : gestes sur l'état who@2 | MA-R2a |
| M5 : aucun repli des terminés | Q2, R8-G5b, MA-R3a, b, d |
| M6 : `vivant` sans le statut fini de la liste | MA-R2b (assertion de repli ajoutée après un premier survivant) |
| M3 : stat en échec ⇒ chaîne vide (refuse tout) | A1c, FX-3b/3c, FX-6c/d, FX-4a0, R6-K10, R6-K10c |

Limite : le repli « sans realpath » de MA-D34d est équivalent au test par chemin ; il ne distingue pas d'un mutant qui n'irait que sur le chemin.

## Tests existants réécrits « par conception »

A1, A1d (actions.test), R6-K10b (vf-signal.test, même longueur : 299 lignes), FX-3b (citation-controles.test : le chemin à espace vient maintenant du compte, `lab-fix.ts` gagne l'option `home`), Q2 (equipe.test) et R8-G5b (graphite.test) : les terminés sont repliés, le témoin appuie sur `finis`.
