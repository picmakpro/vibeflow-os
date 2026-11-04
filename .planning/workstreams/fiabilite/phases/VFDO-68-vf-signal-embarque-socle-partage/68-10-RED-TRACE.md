# 68-10 — Trace du rouge de la doc (VFSG-12), tâche 1 partie 1

Base : `d4f3bbb5` (branche `feat/phase-68-doc`), avant toute ligne de doc. Claude Code 2.1.318. Sorties brutes dans le scratchpad de session (`d2.out`, `d4a.out`, `d4b.out`).

## Témoins joués avant l'écriture

| Id | Commande | Attendu avant la doc | Obtenu |
|----|----------|----------------------|--------|
| D1a | `grep -c 'Pane terminal' plugin/cockpit/README.md` | 0 (rouge) | 0 |
| D1b | `grep -c 'cockpit=' plugin/cockpit/README.md` | 0 (rouge) | 0 |
| D1c | `grep -c 'signal@1' plugin/cockpit/README.md` | 0 (rouge) | 0 |
| D2 | `bash scripts/check-version-sync.sh` (contrôle positif) | exit 0, compte des suites juste (153) | exit 0 ; `README.md suites 153`, `README.fr.md suites 153`, `sources synchronisées (v2.75.1, 19 modules)` |
| D3a | `grep -c 'vf-signal' README.md` | 0 (rouge) | 0 |
| D3b | `grep -c 'vf-signal' README.fr.md` | 0 (rouge) | 0 |
| D4a | `bash scripts/tests/test-check-machine-paths.sh` (le gate sait rougir) | exit 0 | exit 0 ; `bilan : 19 OK / 0 KO` |
| D4b | `bash scripts/check-machine-paths.sh` | exit 0 | exit 0 ; `2496 fichier(s) suivi(s) balayé(s), aucun chemin absolu de machine` |

Lecture : D1 et D3 sont rouges (la doc manque), D2 est le contrôle positif (le compte des suites est juste avant la doc et doit le rester : la doc ne touche ni la mention « N suites », ni les badges, ni l'historique), D4 prouve que le gate de chemins sait rougir et qu'il est vert sur l'arbre.
Ces trois rouges et ces deux verts sont les attendus du plan ; aucun n'a été un faux départ.
