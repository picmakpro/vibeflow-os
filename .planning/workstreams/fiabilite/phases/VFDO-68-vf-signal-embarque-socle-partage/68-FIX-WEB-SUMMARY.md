# 68-FIX-WEB — résumé

Correction ciblée de l'UI web du cockpit, écarts de recette R5, R7, R12 (P68-D-35, arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-04). R8 reporté en Phase 70.

- R5 : la pastille d'une mission abandonnée dit « Abandonnée », gris neutre (`--st-todo`), `00-vibeflow.js`.
- R7 : le pied de carte passe à la ligne, la pastille reste dans la carte, `00-vibeflow.js`.
- R12 : portée « dépôt » dans l'infobulle du badge, `70-vf-live.js` ; `test-cockpit-responsive.sh` R7.5.2 réaligné.
- Témoins : section R-M de `test-cockpit-responsive.sh`, aide `chrome-mission.mjs`. Détails et limites : `68-FIX-WEB-RED-TRACE.md`.
- Suites rejouées : responsive 198/0, vendor 77/0. Non-régression Chrome complète laissée au manager.
