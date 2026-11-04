# 68-05 — Trace du rouge (VFSG-11, VFSG-05, VFSG-06 ; P68-D-14)

Claude Code 2.1.318. Arbre : worktree `phase-68-w05`. Témoins de la tâche 1 commités en `b512d0a9`, joués AVANT tout code.
Commande : `claude plugin test plugin` (sortie : scratchpad `68-05-t1-rouge.out`), rc=1 : 8 pass (les 8 tests déjà là), 9 fail (les 9 neufs).

## Rouge avant le code — assertion, attendu, obtenu

| Témoin | Assertion | Attendu | Obtenu (cause) |
|--------|-----------|---------|----------------|
| K1 | `lab.emetteur().length` | > 0 | 0 (aucun `process.run` ne lance `node` : le mod n'appelle pas l'émetteur) |
| K2 | `find Text /node introuvable dans le PATH/` | defined | undefined (phrase absente) |
| K3 | `find Text /sortie de l'émetteur tronquée/` | defined | undefined |
| K4 | `find Text /sortie de l'émetteur illisible/` | defined | undefined |
| K5 | `find Text /schéma inattendu : …@9/` | defined | undefined |
| K6 | `find Text /phase 68 Embarquer le mod \(en cours\)/` | defined | undefined (la pane lit encore STATE.md) |
| K9 | `find Text /émetteur en échec \(code 1\)/` | defined | undefined |
| K13 | `find Text /émetteur sans réponse \(délai dépassé\)/` | defined | undefined |
| K14 | `lab.emetteur().length - avant` | 1 | 0 (aucun appel de l'émetteur, donc pas de garde à prouver) |

Cause commune, la bonne : la fonctionnalité n'existe pas. Aucun rouge dû à un fichier qui ne charge pas : un premier jeu avec
`await import('../hooks/socle')` (K14) a produit `the file did not load` (import dynamique refusé par le chargeur de mods) ;
ce rouge-là est écarté, K14 a été réécrit par la pression de `rafraichir`.

## Témoin que le motif d'échec n'est pas à vide (`verdict.sh`)

Sur cette sortie, pour chaque K1 K2 K3 K4 K5 K6 K9 K13 K14 : `verdict.sh <sortie> Kn echec` rend **0**, `verdict.sh <sortie> Kn succes` rend **1**
(bash ; K1 rejoué sous zsh : echec = 0).

## Annexe — rouge rejoué avec les tests corrigés (commits `test(68-05)` suivants)

Le premier jeu (`b512d0a9`) avait deux défauts de harnais, trouvés en écrivant le code : un gestionnaire `process.run` qui lève
donne « no implementation for process.run » (le rejet se simule par `{ deny }`), et l'événement porte `{ argv, init: { cwd, timeoutMs } }`
(pas `e.cwd`) ; `$.plugin.root` n'existe pas sur le `$` du test (K1 déduit la racine du plugin du script : `argv[1] === <cwd>/cockpit/scripts/vf-cockpit-signal.mjs`).
Pour que le rouge reste celui des tests tels que livrés, ils ont été rejoués sur l'arbre d'avant le code :
`git archive 4c9caa26 plugin` dans le scratchpad, tests corrigés par-dessus, `claude plugin test plugin` : **8 pass, 9 fail** (K1 K2 K3 K4 K5 K6 K9 K13 K14),
`verdict.sh … echec` = 0 pour les neuf. La retouche de `vf-signal.test.tsx` est verte avant le code comme après.

## Annexe tâche 2 — rouge de l'en-tête complet (témoins commités avant le code)

Arbre : `git rev-parse` du commit des témoins = tête `test(68-05): témoins du retard…`, avant `en-tete.tsx` complet. `claude plugin test plugin`
(sortie scratchpad `68-05-t2-rouge.out`) : **18 pass, 7 fail**. Rouges pour la bonne raison (l'assertion de la ligne neuve rend `Received: undefined` ; le reste de l'en-tête de la tâche 1 est vert) :

| Témoin | Assertion | Attendu | Obtenu |
|--------|-----------|---------|--------|
| K7 | `find Text /en retard de 3 commits sur main, dernier fetch il y a 2 h/` | defined | undefined |
| K8 | `find Text /mission MISSION-68 · abandonnée, nœuds non refermés/` | defined | undefined |
| K10 | `find Text /phase 68 Embarquer le mod \(en cours\) · retard 3/` (placement inline) | defined | undefined |
| K11 | `find Text /mission MISSION-70 · état inconnu/` | defined | undefined |
| K15 | `find Text /en retard de 1 commit sur main, … · origin\/main local : en retard de 2/` | defined | undefined |
| K16 | `find Text /en retard de 3 commits sur main, aucun fetch connu/` | defined | undefined |

`verdict.sh … echec` rend 0 pour K7 K8 K10 K11 K15 K16. K17 (arbre à jour : aucune ligne `en retard`, phase toujours là) est verte avant le code : c'est un garde, non un témoin de comportement neuf ;
sa preuve est le mutant « la ligne de retard s'écrit toujours » (annexe mutants). Un `the file ran to its end` en échec accompagne les rouges : conséquence des panes non démontées après une assertion tombée, il disparaît au vert.
Ajouts au plan (ids K10 à K17 hors liste K1-K9 du plan, K5, K13, K14 aussi) : compact, mission inconnue (P68-D-23), singulier/origine, absence de fetch, arbre à jour, schéma, délai, appel unique.

## Vert, puis mutants (copies jetables du dossier `plugin/` dans le scratchpad, une mutation chacune)

Vert après le code : `claude plugin test plugin` **24 pass, 0 fail** (3 rejeux consécutifs, rc=0) ; `claude plugin validate --strict plugin` rc=0 ;
`verdict.sh … succes` = 0 pour K1 K2 K3 K4 K6 K7 K8 K9 sous bash ET sous zsh.
Un `the file ran to its end` (rejet non traité de l'environnement 18) est apparu avec les tests de la tâche 2 : bisecté en retirant un test à la fois, le coupable est K14
(le rafraîchissement lancé par `void refresh()` survivait au démontage) ; K14 attend maintenant 250 ms la fin du vol (commit `test(68-05)` dédié).

| Mutant (copie jetable) | Tests qui rougissent | Assertion visée |
|---|---|---|
| `cwd: pluginRoot` -> `cwd: root` | K1 | `a.cwd` différent de `/lab` |
| `trace.includes('ENOENT')` -> `false` | K2 | « node introuvable dans le PATH » |
| garde `if (enVol) return enVol` neutralisée | K14 | un seul processus pour deux rafraîchissements |
| contrôle `o.schema !== SCHEMA` neutralisé | K5 | « schéma inattendu : … » |
| contrôle de troncature retiré | K3 | « sortie de l'émetteur tronquée » |
| pluriel figé à `commits` | K15 | « en retard de 1 commit » |
| ligne de retard écrite même à 0 (`r.main !== null`) | K17 | aucune ligne `en retard` |
| `fetchAgeS === null` neutralisé | K16 | « aucun fetch connu » |
| mission prise de la 1re phase qui en a une, pas de l'arbre courant | K11 | « mission MISSION-70 · état inconnu » |
| segment origin neutralisé | K15 | « origin/main local : en retard de 2 » |
| arbre courant = `arbres[0]` | K7 K8 K10 K11 K15 K16 | phase active de l'arbre courant |
