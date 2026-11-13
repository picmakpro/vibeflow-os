---
phase: 79
plan: "01"
requirements: [SOCL-01]
---

# 79-01 — Fork assumé : retrait de `plugin/cockpit/amont/` — SUMMARY

## Résultat

`plugin/cockpit/amont/` n'existe plus (22 fichiers). `VENDORED.txt` ne porte plus que l'origine, la sentinelle du moteur et l'inventaire du plafond (32 `AJOUT` triés, 8 `TAILLE` sans nombre). La suite vendor perd V6, V7, V9.4 et gagne V10 ; la suite des questions ne peut plus sauter Q11 en silence (Q11.0a, Q11.0b) ; E8.4 ne lit plus VENDORED.txt (M-TRACE). DESIGN.md et le commentaire de l'inventaire sont alignés. Aucun fichier du moteur modifié hors VENDORED.txt.

## Commits (branche feat/phase-79-socle-cockpit)

| Tâche | SHA | Heure (date) |
|---|---|---|
| 1 — témoins V10 et Q11.0, rouge constaté | 1828dc64 | 22:41:56 |
| 2 — retrait de l'appareil, VENDORED.txt réduit, suites réécrites (SHA de retrait, à renvoyer à la session principale, A7) | 8cb2a0fe | 22:43:43 |
| 3 — DESIGN.md, commentaire de l'inventaire, trace finale, SUMMARY | voir `git log` (dernier commit du plan) | |

Fenêtre rouge (01-m1) entre 22:41:56 et 22:43:43 : V10.1, V10.2, V10.5 (vendor) et Q11.0b (questions).

## Preuves

Vendor 87 PASS / 0 FAIL ; git-env 134 / 0 ; questions 116 / 0 ; test-vibeflow-update-cockpit.sh, check-version-sync.sh, check-machine-paths.sh : 0. Trace des rouges : `79-01-RED-TRACE.md`.

## À reprendre par 79-20 (P79-D-27 : aucun document du module touché ici)

- README l.191 (« à rejouer à chaque synchro amont ») ; README § Code tiers : décrire l'origine v0.6.0 @ 92d6854, la licence MIT, le fork assumé ; retirer les deux commandes de vérification et de resynchronisation.
- CHANGELOG : une entrée « Non publié » (appareil retiré) ; entrées historiques intactes.
- `module.json` : champ `type` → « moteur vendorisé ».

## Laissé à leurs plans

- Commentaire de `test-cockpit-terminal-pty.sh` qui cite l'outil retiré (hors périmètre, signalé).
- Commentaire de `ui/00-vibeflow.js` l.5 qui cite les patchs (fichier chaud, à reprendre avec le code navigateur par 79-10 ou 79-11).

## Contrats pour les autres phases

- 79-06 : la suite des questions lit la mesure au plus grand numéro de phase (`mesure_de`) : sa `79-MESURE-claude-p.md` sera lue sans autre geste ; 79-06 migrera les suites questions et git-env vers l'aide commune.
- Phase 80 et plans suivants : `VENDORED.txt` = une ligne `AJOUT <chemin>` par fichier, tri C octet par octet, insérée à sa place alphabétique, jamais en fin de fichier (V10.5). En cas de conflit sur `amont/`, garder la suppression.
