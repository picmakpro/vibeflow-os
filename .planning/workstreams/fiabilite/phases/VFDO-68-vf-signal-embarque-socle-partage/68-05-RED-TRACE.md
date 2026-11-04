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
