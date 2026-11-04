# 68-FIX-FND — trace rouge puis vert (cadence et environnement du mod vf-signal)

Décisions : P68-D-41 (arbitrage Samuel, AskUserQuestion, session principale Claude Code, 2026-11-04, « Rafraîchir si pane ouverte (Recommandé) »),
P68-D-40 (variable vidée), P68-D-42 (décision du manager, applique « Rien sous le lab »). Base avant la passe : 173 pass / 0 fail.
Témoins : `plugin/cockpit/signal/tests/fin-cadence.test.tsx` (FND-1a..1c, FND-3, FND-4) et `fin-correctifs.test.tsx` (FND-2a, FND-2b).
Rejouer : `claude plugin test plugin`.

## Rouge

| point | témoin | obtenu avant correctif |
| --- | --- | --- |
| FND-3 | FND-3 (horloge à 500 000 après un lancement à 1 000 000, un tour) | 1 lancement au lieu de 2 : la différence négative bloquait |
| P68-D-42 | FND-2a, FND-2b | `NODE_OPTIONS`, `BASH_ENV`, `ENV` valent le chemin du lab (l'hôte les pointe vers `/lab`) au lieu de `''` |
| FND-1, FND-4 | tests ajoutés verts sur le code actuel ; leur rouge est le mutant tué (ci-dessous) | — |

## Mutants (suite complète rejouée sur copie, fichier restauré par `cp` après chacun)

| mutant | témoins rouges (hors FND-3, rouge avant correctif) |
| --- | --- |
| C12 : `dernierLancement = now` retiré d'`emetteurAuto` | FND-1a, FND-1b |
| C4 : `/clear` appelle `refreshSignalAuto` sans limite | FND-1b |
| C6 : `apresBash` sans la condition « pane ouverte » | FND-1c |
| FND-4 : `refreshTimer?.cancel(); refreshTimer = null` retirés | FND-4 |
| P68-D-42 : une seule des trois variables retirée de `envSain` (trois mutants) | FND-2a, FND-2b à chaque fois |

## Vert

180 pass / 0 fail (173 + FND-1a, 1b, 1c, 2a, 2b, 3, 4). Correctifs : `hooks/cadence.ts` (`now - dernierLancement >= 0 &&` : négatif = échu),
`hooks/env-sain.ts` (`NODE_OPTIONS`, `BASH_ENV`, `ENV` à `''`), README (section de la pane) et CHANGELOG v1.2.0 (FND-5).

## Hors preuve (dit)

- Le lancement d'élagage passe lui aussi par `envSain` ; aucun témoin ne capture son `init.env` (les deux autres lancements sont couverts, le mutant sur `envSain` les tue).
