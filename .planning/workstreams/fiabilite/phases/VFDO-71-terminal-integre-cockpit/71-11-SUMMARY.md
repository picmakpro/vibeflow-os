---
phase: 71
plan: 11
requirements: [TERM-10]
status: passed
---

# 71-11 — vendor xterm et tenue du moteur : résumé

Trace du rouge : `71-11-RED-TRACE.md`.

## Commits
- `681f8318` test(71-11) : V2 à six composants, section V9 (V9.1 à V9.4, M-SHA)
- `c115e207` docs(71-11) : trace du rouge
- `e52f1320` chore(71-11) : vendor xterm 6.0.0 + addon-fit 0.11.0, `SHA256SUMS`, `VENDORED.txt`, `LICENCES-TIERCES.txt`

## Ce qui est posé
- `npm pack --ignore-scripts` dans un dossier neuf, jamais d'installation. Intégrité des deux tarballs recalculée (sha512 base64) et égale à `dist.integrity` du registre ; sha256 des tarballs égaux aux valeurs de 71-RESEARCH ; aucun `postinstall`.
- Les cinq fichiers (3 + 2 licences) copiés octet pour octet, `SHA256SUMS` égal aux cinq valeurs épinglées.
- `VENDORED.txt` : six `AJOUT assets/vendor/xterm/…` (dont `SHA256SUMS`), `AJOUT terminal/vf-cockpit-pty.py`, `P25` et sa description, `TAILLE assets/serve.mjs` = 614 (610 avant).
- `synchro.sh verifier` : « amont v0.6.0 @ 92d6854 retrouvé à l'octet (48 fichiers) ». Fenêtres F1 de 71-01 (assistant non déclaré, V6.1) refermées.

## Preuves
- Rouge : 11 FAIL (V2 4 au lieu de 6, V6.1, V9.1 x3, V9.2 x3, V9.3, V9.4 x2). Vert : `test-cockpit-vendor.sh` 96 PASS / 0 FAIL, dont M-SHA (octet changé vu) ; `test-cockpit-marque-blanche.sh` rc 0.
- `check-machine-paths.sh`, `check-file-size.sh --all`, `check-python-isolation.sh` : rc 0.

## Limites et points pour la suite
- F2 de 71-01 : `synchro.sh regenerer-patch` sans clone échoue si `serve.mjs` a changé ; le diff P25 est celui régénéré par 71-01, non retouché.
- Le vendor n'a pas le marqueur `allow-large-file` (octet pour octet) : `check-file-size.sh` et V4 le laissent passer (xterm.js tient sur 1 ligne).
- Le vendor est encore sans lecteur : 71-05 le vérifie au démarrage.

## Branchements à recenser pour le merge
| # | Fichier | Changement | Conflit avec la 69 |
|---|---------|-----------|--------------------|
| B7b | `skills/cockpit-moteur/VENDORED.txt` | six `AJOUT` xterm, `AJOUT terminal/vf-cockpit-pty.py`, `P25` + description, `TAILLE serve.mjs` 614 | **certain** : la 69 ajoute `P24` et passe TAILLE à 611 ; fusion à la main (`…,P24,P25`), TAILLE recomptée et diff régénéré APRÈS la fusion de `serve.mjs` |
| B9 | `scripts/tests/test-cockpit-vendor.sh` | V2 à six, section V9 | faible |
| B10 | `skills/cockpit-moteur/LICENCES-TIERCES.txt` | deux lignes | faible |
