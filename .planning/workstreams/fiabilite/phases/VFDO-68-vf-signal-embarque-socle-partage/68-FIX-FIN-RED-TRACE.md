# 68-FIX-FIN — trace rouge puis vert (mod vf-signal, dernière passe de la Phase 68)

Décisions : P68-D-40 (variable vidée), P68-D-41 (arbitrage Samuel « Rafraîchir si pane ouverte (Recommandé) », AskUserQuestion, session
principale Claude Code, 2026-11-04). Témoins : `plugin/cockpit/signal/tests/fin-cadence.test.tsx` (FIN-1*) et `fin-correctifs.test.tsx` (FIN-2..FIN-6).
Rejouer : `claude plugin test plugin` (base avant la passe : 153 pass / 0 fail).

## Ce que l'API des mods permet de savoir (types de la référence `plugin-authoring`, build 2.1.317)

- Session interactive : `session.start` porte `isInteractive` (« true under the REPL, false for a `-p` run or the SDK »). Sûr.
- Pane ouverte : `$.ui.panes()` rend les panes du mod avec `isPlaced` (dessinée maintenant). Lue à la demande. L'API ne NOTIFIE PAS
  l'ouverture par la personne (`ui.open` ne dit rien d'une ouverture faite par la touche) : la règle « pane ouverte » est donc SONDÉE par le
  minuteur de 10 s (qui ne lance l'émetteur que si la pane est posée) et relue à chaque tour. Règle la plus proche de l'arbitrage, sans minuteur qui lance un processus pane fermée.

## Rouge (avant correctif)

| témoin | attendu | obtenu |
| --- | --- | --- |
| FIN-1a | `session.start` rend la main émetteur retenu | attend l'émetteur (course perdue) |
| FIN-1b | 1 lancement pour start + 3 tours, pane fermée | 4 |
| FIN-1b2 | 2 (une minute plus tard, un tour relance) | 5 (rouge pour la mauvaise raison, vert après) |
| FIN-1c2 | pane fermée : minuteur sans lancement | lance l'émetteur |
| FIN-1d | non interactif : aucun lancement par minuteur | lance l'émetteur |
| FIN-2a, FIN-2b | `init.env.VF_COCKPIT_SCRIPTS_DIR === ''` (émetteur, lanceur) | `undefined` |
| FIN-3a, FIN-3b | aucun U+202A–202E / U+2066–2069 au brief (description d'agent, raison de refus, projet) | présents |
| FIN-4a | `/vf-signal` : « vf-signal : erreur — … » | le hook levait, « no implementation for command.run » |
| FIN-5 | « actif · dépôt · 46 s » | « actif · depot · 46 s » |
| FIN-6a | « - 7 j : 35 % », « - 5 h : 12 % » | `seven_day`, `five_hour` bruts |
| FIN-6c | « 1 outil » / « 2 outils » | « 1 outils » |

Témoins déjà verts, gardés comme contrôles positifs : FIN-1b3 (pane ouverte, chaque tour rafraîchit), FIN-1c (pane ouverte, le minuteur tourne),
FIN-1e (gestes explicites : `/vf-signal` et `brief` rafraîchissent aussitôt, même dans la minute), FIN-6b (fenêtre inconnue gardée telle quelle).

## Correctifs

- `hooks/cadence.ts` (nouveau) : `paneOuverte`, `emetteurAuto`, `pulsation`, `apresBash`, `noter`. Une seule horloge de lancement automatique (démarrage compris) :
  pane fermée, au plus un lancement par minute ; pane ouverte et session interactive, aucun plafond. Les gestes explicites ne passent pas par là.
- `register.tsx` : `session.start` lance l'émetteur en arrière-plan (jamais attendu), la liste des agents et le coût restent attendus (aucun processus) ;
  minuteur de 10 s posé en session interactive seulement ; `turn.complete` et `/clear` passent par `emetteurAuto` ; le lancement lié aux appels Bash (verrou, commit…) exige la pane ouverte ;
  `command.run{vf-signal}` porte un `.catch` qui répond « vf-signal : erreur — <cause bornée à 120 caractères, sans contrôle> ».
- `env-sain.ts` : `VF_COCKPIT_SCRIPTS_DIR: ''` dans l'`init.env` de tout lancement (émetteur, lanceur du cockpit, élagage : tous passent par `envSain`).
- `ds.ts` : `sansControle` retire aussi les marques bidi (comme `nettoie` du socle) ; `libelleFenetre`, `nOutils`, `libellePortee` partagés pane / brief / vue Équipe.
- `derive.ts` (brief) : « 7 j », « 5 h », « outil(s) » ; `views/equipe.tsx` : « dépôt », « outil(s) » ; `pane.tsx` : `libelleFenetre`.
- Suites existantes : `tests/apres-demarrage.ts` (120 ms) — `session.start` ne attend plus l'émetteur, un test qui monte la pane aussitôt laisse finir le rafraîchissement d'arrière-plan.

## Vert et mutants (suite complète rejouée, fichier restauré par copie après chacun)

Vert : 173 pass / 0 fail (153 avant + 20 témoins FIN-*).

| mutant | témoins rouges |
| --- | --- |
| `session.start` attend l'émetteur | FIN-1a |
| limite d'une minute retirée | FIN-1b, FIN-1b2 |
| le minuteur ignore l'état de la pane | FIN-1b2, FIN-1c2 |
| minuteur posé en non interactif | FIN-1d2 (la période de 10 s est espionnée ; FIN-1d seul ne le voyait pas : survivant, d'où FIN-1d2/1d3) |
| pane ouverte soumise à la limite d'une minute | FIN-1b3 |
| `VF_COCKPIT_SCRIPTS_DIR` non vidée | FIN-2a, FIN-2b |
| bidi retirés de `sansControle` | FIN-3a, FIN-3b |
| `.catch` de `command.run` retiré | FIN-4a |
| « depot » non traduit | FIN-5 |
| clé brute au brief | FIN-6a, FIN-6d |
| « n outils » sans accord | FIN-6c |

## Hors preuve (dit)

- Pane ouverte par la personne sans commande : le rafraîchissement suivant est celui du minuteur de 10 s (ou du tour), pas un rafraîchissement à l'ouverture ; l'API ne signale pas cette ouverture.
- `FIN-4a` : le moteur de test réécrit la cause (« no implementation for ui.open ») ; le témoin vérifie la forme « erreur — <cause> », pas le texte de la panne injectée.
