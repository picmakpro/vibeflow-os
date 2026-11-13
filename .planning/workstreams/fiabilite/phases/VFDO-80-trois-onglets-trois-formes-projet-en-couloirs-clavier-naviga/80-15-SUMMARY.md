# 80-15 — aide des raccourcis ouverte par `?` (SUMMARY)

## Livré
- `ui/60-vf-aide.js` : modale « Raccourcis clavier » de la pile `VF_SURCOUCHES`, rangées générées depuis `VF_RACCOURCIS.entrees(onglet)`,
  filtrée par onglet, `window.VF_AIDE = { ouvrir, fermer, ouverte }` (celui que la palette de 80-14 appelle déjà). Ligne `AJOUT` de `VENDORED.txt`.
- `test-cockpit-aide.sh` + `chrome-aide.mjs` : AI1.1 à AI1.5, AI1.4t (--terminal), AI2.1 à AI2.7 ; 18 PASS / 0 FAIL ; trace rouge : `80-15-RED-TRACE.md` (3 PASS / 15 FAIL sur la base).

## Écarts
- Écart : le libellé de la rangée de V est celui du registre (« Basculer couloirs, liste, graphe »), non « Changer de vue » du plan (libellé du registre = seule source).
- Écart : classe racine `vf-aide-modale`, car `.vf-aide` existe déjà dans 00-vibeflow.js (indice du panneau) ; une première version la doublait.
- Écart : l'unicité de l'écouteur se prouve par le nombre d'écouteurs `keydown` du document (CDP DOMDebugger) à onglet égal avant/après deux allers-retours : la portée (79-16) rend les propriétés de `window` posées par la page à chaque onglet, donc une instrumentation de `addEventListener` ne survit pas.
- Écart : AI1.4 « au texte du registre » ; aucun mutant (régime allégé) : M-REGISTRE, M-SAISIE, M-PIEGE, M-SANS-CLE non joués.
- `07-vf-raccourcis.js` non touché ; rien à remonter sur le registre.

## Suites
palette 25/0, surcouches 48/0, chrome-fr 141/0, vendor 252/0, aide 18/0 (une fois chacune, sur la tête commitée). Rouges connus non réparés : T21.7 terminal-tiroir, 17 rouges git-entete, JT1.4.

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)

## CHANGELOG (80-18)
- cockpit : `?` ouvre l'aide des raccourcis, générée depuis le registre unique et filtrée par onglet ; elle est aussi dans la palette (« Afficher les raccourcis »).
