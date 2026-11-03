# 71-11 — trace du rouge de la tenue du vendor xterm

- date : 2026-11-03
- commit de tests : `681f8318` (`test(71-11): témoins rouges de la tenue du vendor xterm …`)
- base : HEAD `03518b44` ; `assets/vendor/xterm/` absent, `VENDORED.txt` sans `P25` ni ligne `AJOUT` de l'assistant, `TAILLE assets/serve.mjs` à 610
- commande : `bash plugin/cockpit/scripts/tests/test-cockpit-vendor.sh > 71-11-t1.out 2>&1` — rc=1, `Résultats : 75 PASS / 11 FAIL`

## Témoins rouges (11)

### FAIL — V2 — six composants listés
- attendu : `[6]`
- obtenu : `[4]`

### FAIL — V6.1 — synchro.sh verifier rend 0
- attendu : `[0]`
- obtenu : `[1]`
- raison : fenêtre ouverte par 71-01 (F1) : `terminal/vf-cockpit-pty.py` non déclaré `AJOUT`

### FAIL — V9.1 — sha256 de xterm.js / xterm.css / addon-fit.js (3 rouges)
- attendu : `[14903579…a972]`, `[854a7c0f…93c6]`, `[ba3ea256…8527]`
- obtenu : `[absent]` (fichiers absents)

### FAIL — V9.2 — SHA256SUMS : ligne de xterm.js / xterm.css / addon-fit.js (3 rouges)
- attendu : les trois valeurs épinglées
- obtenu : `[absente]` (SHA256SUMS absent)

### FAIL — V9.3 — une ligne AJOUT terminal/vf-cockpit-pty.py
- attendu : `[1]`
- obtenu : `[0]`

### FAIL — V9.4 — la ligne PATCH assets/serve.mjs cite P25
- attendu : `[1]`
- obtenu : `[0]`

### FAIL — V9.4 — TAILLE assets/serve.mjs = lignes réelles
- attendu : `[614]`
- obtenu : `[610]`

## Témoins sautés / positifs
- M-SHA : sauté en le disant (« vendor xterm pas encore posé »), rejoué après le vendor ; le témoin positif de V9.4 (TAILLE décalée de 1 dans une copie) est vert dès la base.
- V1, V3, V4, V5, V7, V8 restent verts.
