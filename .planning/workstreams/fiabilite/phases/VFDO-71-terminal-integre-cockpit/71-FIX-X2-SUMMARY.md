# 71-FIX-X2 — serveur et lanceur : R3 (python3 disparu), R4 (lanceur sans python3), R5 (sonde)

Arbitrage de Samuel, AskUserQuestion, session principale Claude Code, 2026-11-04 : P71-D-36 « Tout, R5 après sonde (Recommandé) ».

## R3 — python3 disparu en cours de session (corrigé)

Cause : `vf-cockpit-terminal-processus.mjs` vérifiait python3 une seule fois, au démarrage du serveur du terminal. Après sa disparition, la relance d'un shell échouait (503) mais `/etat` rendait `absente` : le client y lisait « La session a été fermée » en boucle.
Correction : python3 est résolu à chaque lancement de shell (`/flux` sans session vivante). Une session déjà vivante n'en dépend pas (reprise dans la grâce, entrée, taille inchangées). `/etat` rend `indisponible` / `python3-absent` quand python3 manque ET qu'aucune session n'est vivante ET (un lancement vient d'être refusé OU la session est `absente`) ; juste après `exit`, avant toute relance, il rend encore `terminee` (code de sortie visible), puis `indisponible` à la relance. Une ligne de journal par absence (remise à zéro quand python3 revient).
Témoin : `test-cockpit-terminal-session.sh` R3.1 (session vivante, python3 retiré du PATH résolu, `exit`, relance : 503, `/etat` = `indisponible`, journal = 1), R3.2 (témoin positif), mutant M-PYTHON-FIGE (vérification figée au démarrage = tête d'avant) : le mutant rougit R3.1 (la relance ne dit plus `indisponible`), le code courant la verdit.

## R4 — lanceur, serveur déjà vivant, `--terminal` sans python3 (corrigé)

Cause : `o.terminal` retombait à `false` après le message « Le cockpit s'ouvre sans terminal », puis la branche « serveur vivant » rendait l'adresse sans rien ouvrir.
Correction : si le terminal était demandé et a été écarté (python3 absent, Windows), le lanceur ouvre le cockpit existant (adresse de P), sauf `--no-open`, comme au cas sans serveur (W3, code 0). Une relance ordinaire sans `--terminal` garde son comportement (adresse seule).
Témoin : `test-cockpit-terminal-lanceur.sh` L19b, deux variantes (serveur lancé sans puis avec terminal), ouvreur factice ; mutant M-R4-SANS-OUVERTURE. Rouge sur la tête d'avant (ouverture 0 au lieu de 1, 3 FAIL), vert après (104/0).

## R5 — « Terminal déjà ouvert » après fermeture d'un onglet propriétaire (SONDE : artefact du headless)

Sonde (hors dépôt, rejouable) : un client Node ouvre `/flux` comme onglet propriétaire A, puis détruit la connexion TCP (fin de connexion réelle) ; un onglet B sonde `/flux` toutes les 250 ms.
Mesures :
- grâce par défaut (30 000 ms) : 409 jusqu'à 30 079 ms, puis 200 à 30 079 ms ;
- grâce réglée à 3 000 ms : 409 jusqu'à 3 075 ms, puis 200.
Le serveur libère la place à la grâce près (30 s), jamais au-delà : le flux fermé est bien vu à l'instant de la fin de connexion. Les 75 s et plus du juge ne viennent donc pas du serveur : en headless la fermeture d'un onglet ne termine pas toujours le flux (connexion gardée), et la reprise suit la cadence de réessai du client. Verdict : artefact du headless. Aucun code modifié pour R5. Si le défaut se reproduisait sur un navigateur réel, la cause serait côté client (`vf-cockpit-terminal-client.mjs`, fichier de X1) : cadence de reconnexion de l'onglet B.

## Phrases de doc (pas de README ni CHANGELOG touchés ici)

- Terminal : « python3 est vérifié à chaque lancement de shell, y compris « Relancer le shell » : s'il a disparu en cours de session, le terminal le dit (« Python 3 introuvable ») au lieu de boucler sur « La session a été fermée ». Une session déjà ouverte n'est pas coupée. »
- Lanceur : « Avec `--terminal`, si le terminal ne peut pas s'ouvrir (Python 3 absent, Windows) et qu'un cockpit tourne déjà, le lanceur ouvre ce cockpit sans terminal et le dit. »
- Terminal : « Après la fermeture de l'onglet qui tient le terminal, un autre onglet obtient la session au bout de la grâce (30 s). »

## Suites et gates

Voir le retour du mandat (nombres rejoués après les commits) : `-session.sh`, `-lanceur.sh`, `-serveur.sh`, `-activation.sh`, check-machine-paths, check-file-size --all, check-python-isolation.
