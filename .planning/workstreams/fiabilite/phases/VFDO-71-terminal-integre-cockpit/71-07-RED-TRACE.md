# 71-07 — trace du rouge du tiroir

## Contrôle d'entrée

- date : 2026-11-03 ; base : HEAD `fcfa4520`
- ligne de décision (`71-CONTEXT.md` l.113), mot pour mot : « **P71-D-20 (O1 → option B ; décision du manager, vf-dev-manager, 2026-11-03).** Le tiroir est servi à la volée, SEULEMENT avec `--terminal`, depuis `scripts/vf-cockpit-terminal-tiroir*.mjs`, et non par un `assets/ui/9x-vf-terminal.js` inliné. »
- option retenue : **B** (le plan continue tel qu'écrit ; aucun fichier sous `assets/ui/`)
- ligne de `71-06-SUMMARY.md` qui rapporte T9.7 : « Rouge puis vert : T6.1, T6.1b, T6.2, T6.3, T6.4, T6.6, T6.7, T9.5, T9.7, T14.S1-S4, T17.Q1-Q4 … » (suite client : 35 PASS / 0 FAIL)
- mesure O8 retenue (71-06-SUMMARY) : `MESURE-O8 minimal=bloque popups=ouvert opener=nul` ; décision du manager : cinq jetons `allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox`, aucun autre
- porte rejouée avec sortie non nulle sur échec (remarque du plan-checker) : le script de vérification se termine par `process.exit(1)` sur `ENTREE-NON-TENUE`
