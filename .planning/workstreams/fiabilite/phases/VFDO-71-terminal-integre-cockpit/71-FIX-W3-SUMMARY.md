# 71-FIX-W3 — E4 (python3 côté lanceur) et E5 (attente du serveur 30 s)

Arbitrage Samuel, AskUserQuestion session principale, 2026-11-04 : P71-D-34 « Corriger E2 à E5 (Recommandé) ». Commit : 7a2295c1.

## E4
Avec `--terminal`, `vf-cockpit.mjs` résout `python3` par `resoudreBinaire` (éléments absolus du PATH, même règle que `resoudrePython3` du serveur) avant tout amorçage. Introuvable : message « Terminal indisponible : python3 introuvable… » avec la marche à suivre, `o.terminal` retombe à faux, le cockpit s'ouvre sans terminal, sortie 0. Choix : le cockpit reste utile sans terminal, et le message n'est pas muet.

## E5
Borne de démarrage 30 s (`VF_COCKPIT_DEMARRAGE_MS`, réglage de test, 1 à 120 s). « démarrage lent… » dit une fois après 5 s. Serveur vivant sans état : on attend jusqu'à la borne ; serveur sorti sans état : échec immédiat (rc 5).

## Preuves
- L20 (serveur factice écrivant son état à 15 s) : rc 0 ; M-BORNE-10 (borne à 10 s = comportement de HEAD) : rc 5.
- L19 : PATH sans python3 ; M-SANS-PYTHON3 (vérification neutralisée = HEAD) rougit.
- Suites : `-lanceur.sh` 94/0, `-activation.sh` 40/0 ; gates check-machine-paths, check-file-size --all, check-python-isolation verts.
- L18 reçoit un `pybin` (python3 sans ps) : il testait l'absence de ps, pas celle de python3.

## Phrases de doc
- README : « Sans python3 dans le PATH, `--terminal` le dit (« Terminal indisponible : python3 introuvable ») et le cockpit s'ouvre sans terminal. »
- README/CHANGELOG : « Le lanceur attend le serveur jusqu'à 30 s (au lieu de 10) et signale un démarrage lent après 5 s ; code 5 seulement au-delà. »
