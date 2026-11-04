# 68-06 — Trace du rouge du retrait (VFSG-03, VFSG-06 ; P68-D-13, P68-D-17, P68-D-24, P68-D-30)

Claude Code 2.1.318. Arbre : worktree `phase-68-w06`. Témoins commités en `24e71a83`, joués AVANT tout code.
Commandes : `claude plugin test plugin` (scratchpad `68-06-t1-rouge.out`) : **23 pass, 10 fail**, rc=1 ; `bash` et `zsh test-cockpit-signal-mod.sh`
(`68-06-t1-m7-rouge.out`, `-zsh.out`) : 22 ok / 3 ko, rc=1, identiques sous les deux shells.

Identifiants : `R6-K5`, `R6-K10`, `R6-K11` portent le préfixe `R6-` parce que `K5`, `K10` et `K11` existent déjà dans `socle.test.tsx` (68-05) et que
`verdict.sh` compare le titre par son début (deux tests de même identifiant donneraient exit 2). Écart au plan, voir le SUMMARY.

## Rouge avant le code — assertion, attendu, obtenu

| Témoin | Assertion | Attendu | Obtenu (cause) |
|--------|-----------|---------|----------------|
| R6-K5 | `lus.filter(p => p.includes('/.planning'))` sur toute la session (démarrage, trois vues, bandeau, `/vf-signal brief`) | `[]` | `/lab/.planning/active-workstream` ×N, `/lab/.planning/workstreams/fiabilite/STATE.md`… (`disk.ts` lit le STATE) |
| R6-K10 | argv de `recover` | `['bash', '<racine du plugin>/conductor/scripts/driver-lock.sh', 'recover', '--ws=fiabilite']` | `['bash', '/lab/.claude/scripts/driver-lock.sh', 'recover', '--ws=fiabilite']` (le script du scope projet passe avant celui du plugin) |
| R6-K10b | bouton `elaguer` (plugin amputé, script du projet seul) | bouton dessiné, `/lab/.claude/scripts/driver-lock.sh` | `press: no Button … keyed "elaguer"` : le verrou périmé vient de `signal.verrous.liste`, que l'ancien code ne lit pas |
| R6-K10c | idem, script du compte seul | `/home/user/.claude/scripts/driver-lock.sh` | même cause (b et c sont rouges par la source du verrou, pas par l'ordre : voir « Gardes » plus bas) |
| R6-K11 | `find Text /exécution/` (vue mission, pane inline) | defined | undefined (nœuds lus du disque, vides sous la fixture) |
| R6-K11b | `find Text /état inconnu/` (mission MISSION-70) | defined | undefined |
| R6-J1 | `find Text /jalon Jalon d essai/` | defined | undefined (l'en-tête ne dit plus le jalon depuis 68-05) |
| M7.2 | `disk.ts` absent | absent | present |
| M7.3 | littéral `.planning` hors commentaire dans les hooks | aucun fichier | `disk.ts,` |
| M7.4 | `current_phase` hors commentaire dans les hooks | aucun fichier | `disk.ts,` |

Trois tests d'origine réalignés (rouges avant le code, même cause : ils lisaient le disque) :
`la pane montre la phase, la mission par vagues et le verrou périmé` (`find /exécution/` undefined), `le bandeau porte la prochaine action humaine`
(`find /verrou périmé de mgr68/` undefined : le bandeau lisait le verrou du disque), `la vue équipe…` (`find /Jalon d essai/` undefined : la macro lisait le ROADMAP).

## Verdicts lus par `verdict.sh` sur cette sortie

`verdict.sh <sortie> Rn echec` rend **0** et `… succes` rend **1** pour R6-K5, R6-K10, R6-K10b, R6-K10c, R6-K11, R6-K11b, R6-J1 (bash ; succes sous zsh = 1 aussi).

## Gardes (verts avant le code, par construction)

- R6-J2 (phase 70 hors de tout jalon, leurre STATE servi) et R6-J3 (arbre courant sans phase active) : verts avant le code, car l'en-tête n'affiche aucun jalon.
  Ce sont des gardes contre un repli (sur le STATE, sur le premier jalon) : leur preuve est un mutant, joué après le code (annexe de la fin de mandat).
- M7.5 (`agent.list` seulement dans `refresh.ts`) : déjà vrai, garde. M7.0 et M7.1 sont des contrôles positifs de la suite (l'extracteur sait trouver un littéral, le balayage ne voit pas un dossier vide).
- R6-K10b et R6-K10c rougissent aujourd'hui par la source du verrou, pas par l'ordre des candidats ; l'ordre est prouvé par un mutant après le code (échange de deux candidats).

## Harnais (trouvé en écrivant les témoins)

`labSignal` (fixture 68-05) ne laisse pas d'espion : le moteur de test refuse un second `on('fs.exists')` (`registered twice`) ; la fixture n'est pas dans le périmètre du plan,
`vf-signal.test.tsx` porte donc son propre `lab()` (mêmes réponses que `labSignal`, plus l'enregistrement des lectures `fs.*` et des appels `bash`, et un leurre d'ancien disque : STATE.md, `status --all`).
`ui.toast` demande un gestionnaire (`on('ui.toast')`), sinon « dropped ».

## Vert, puis mutants (annexe, après le code)

Vert (scratchpad `68-06-tests2.out`) : `claude plugin test plugin` **35 pass, 0 fail**, rc=0 ; `claude plugin validate --strict plugin` rc=0 ;
`test-cockpit-signal-mod.sh` 25 ok / 0 ko sous bash ET sous zsh ; `check-machine-paths.sh` rc=0 ;
`verdict.sh … succes` = 0 pour R6-K5 R6-K10 R6-K10b R6-K10c R6-K11 R6-K11b R6-J1 R6-J2 R6-J3 sous bash ET sous zsh.
Le rouge → vert de chaque témoin : R6-K11 et R6-K11b au commit `f9922469` (vérifié `OK-T1`, K5 encore rouge à ce commit), R6-K5/K10/K10b/K10c et les trois tests d'origine à `1a059b78`
(32 pass / 1 fail : R6-J1 seul), R6-J1 à `58e89b59`, M7 à `fd4b3834`.

Témoins ajoutés après le code (comportement neuf de `attention`, verts au premier jeu, prouvés par mutant) : R6-A1, R6-A2.

Mutants (copies jetables de `plugin/` dans le scratchpad, une mutation chacune, `claude plugin test` dans la copie) :

| Mutant | Rouge obtenu | Attendu |
|--------|--------------|---------|
| `actions.ts` : projet avant plugin | R6-K10 | R6-K10 |
| `actions.ts` : candidat du compte retiré | R6-K10c | R6-K10c |
| `actions.ts` : candidat du projet retiré | R6-K10b | R6-K10b |
| `derive.ts` : `jalonCourant` retombe sur `jalons[0]` si aucun jalon ne contient la phase | R6-J2 | R6-J2 |
| `derive.ts` : idem sans phase active | R6-J3 | R6-J3 |
| `derive.ts` : nœuds d'une mission abandonnée dictent l'action | R6-A2 | R6-A2 |
| `derive.ts` : détection du nœud en échec coupée | R6-A1 | R6-A1 |
| `refresh.ts` : un `fs.exists` sous `/lab/.planning/` ajouté | R6-K5 | R6-K5 |
| `derive.ts` : `missionCourante` rend null | R6-K11, R6-K11b, R6-A1 | R6-K11, R6-K11b, R6-A1 |
| `en-tete.tsx` : jalon jamais affiché | R6-J1 | R6-J1 |
| `derive.ts` : `verrouPerime` cherche `stale === false` | R6-K10, K10b, K10c, A1, A2 | R6-K10, K10b (K10c, A1, A2 en plus : le verrou périmé ne sort plus) |

Mutants de M7 (copies, `test-cockpit-signal-mod.sh` sous bash ET zsh) : littéral `/.planning/` dans `ds.ts` -> M7.3 ; `current_phase` -> M7.4 ; un `disk.ts` recréé -> M7.2 ; `$.agent.list()` dans `derive.ts` -> M7.5.
Chaque mutant a eu son ancre unique vérifiée avant application (`assert count == 1`).
