---
phase: 72
plan: 11
status: complete
requirements: [LANC-04, LANC-05, LANC-07, LANC-09]
commits: [35d72e63]
---

# 72-11 — chaîne XSS prolongée jusqu'au lancement

Trace, mesures et écarts : `72-11-RED-TRACE.md`. Aucun fichier de production touché.

## Livrables

- `plugin/cockpit/scripts/tests/test-cockpit-lancer-xss.sh` (370 lignes) : manches LEG, C0l, C1l, C2l à C5l, DORIG (avec M-ORIGINE-LANCER), M-SANS-CONFIRM, M-ENTREE-AUTO, M-INTERPOLE, TIT ; mode simulé sans Chrome (partie HTTP rejouée, partie navigateur annoncée « NON vérifiée »). 57 PASS / 0 FAIL sous Chrome, zéro ligne « NON vérifiée ».
- `temoins/lancer-charge.js` (41 lignes), `temoins/lancer-xss.mjs` (52 lignes), `temoins/lancer-fauxbin/claude`.

## Ce qui est prouvé

- La charge de P compromise fait naître une proposition (202), jamais un lancement : argv absent, aucune ligne à l'invite, aucun marqueur, proposition toujours en attente, stockage de Q (clé du mode `vf.terminal.mode` comprise) illisible et inscriptible en SecurityError, cadre, messages et fenêtres sans effet.
- Le témoin qui aboutit existe : Q privée de ses contrôles, la même charge fait tourner le faux `claude` sans geste ; chaque contrôle laissé seul (Origin, secret, onglet, identifiant) casse la chaîne.
- Quatre mutants rougissent leur sonde : M-SANS-CONFIRM (ligne à l'invite sans POST), M-ENTREE-AUTO (argv sans Entrée), M-INTERPOLE (7 éléments d'argv, `bypassPermissions` présent), M-ORIGINE-LANCER (204 au lieu de 403). M-ESC et M-CSP rendent chacun, seuls, le témoin d'exécution rouge.
- Titres hostiles : 0 violation CSP, `window.__titre3` indéfini, avec la CSP puis sans elle ; la mesure sait compter (témoin).

## Écarts avec le plan

Sept, tous consignés dans la trace : armement lu à partir de la première lecture (constante `arme_apres_ms`) ; copie du lab entier par manche ; mutant M-ONGLET-SESSION ajouté ; LEG.2 sans `cible` ; 504 non rencontré ; un seul commit de code pour les deux tâches ; charge assemblée sans commentaire de fin de ligne.

## Défauts remontés

Aucun défaut de code applicatif.
