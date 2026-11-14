# Mission Phase 75 — exécution jusqu'au bout, régime allégé (2026-11-13 → 2026-11-14)

Manager `vf-dev-manager-p75`, mode autonome, verrou `--ws=fiabilite --phase=75`. Demande de Samuel (session principale,
2026-11-11) ; régime allégé et parallélisme (consignes de Samuel, message session principale, 2026-11-13 et 2026-11-03).
Départ `d487f372`. PR #245 (75-01 à 75-06, fusionnée en `82aab6cc`) ; PR à ouvrir vers integration/cockpit-audit (75-07 à 75-10).

## Livré
| Plan | Objet | Dernier commit |
|---|---|---|
| 75-01 | Calcul git : points chauds, couplage, collisions de branches (`--relative`, correctif de revue) | d33f2438 |
| 75-02 | Lentille Gardes (règle de citation de la CI ; calcul qui cède la main, correctif d'audit haut) | 6db40736 |
| 75-03 | Chemins, empreinte, collisions (audit : A46 fermé, coût linéaire, mutants déterministes) | 56500820 |
| 75-04 | `files_modified` lu en bloc, borné à 200 (`touchedIgnores`) | e69faab6 |
| 75-05 | Route `GET /api/vf/activite`, `cockpit-activite@1` (audit : bornes en octets, D10.7) | 9f854a14 |
| 75-06 | Cartes « prévues » (`st:'prevu'`), retirées de l'export | a3de3a34 |
| 75-07 | Canal `VF_MARQUES` (livré à la 74 en 1974b994), pied réservé, glyphes, XSS | 95f9b75a |
| 75-08 | Sélecteur, menu, panneau, radar | 26bf0a3c |
| 75-09a/b/c | Retrait de « Travail récent » (assemblage, page, dictionnaires) | 4e299397 |
| 75-10 | Non-régression, `test-cockpit-activite-sans-git.sh`, DESIGN.md (P75-D-32), CHANGELOG | ceaf82fc |
| fin | Correctifs de revue et de juge design, C6.1 | 60290acb |

## Écarts
- 75-07 tâche 4 (« Voir sur la carte ») passée à 74-06 : décision déléguée par Samuel (message session principale,
  2026-11-08), option recommandée, prise par la session principale le 2026-11-13. File tardive : `VF_MARQUES_EN_ATTENTE`.
- P75-Q-06 : arbitrage Samuel (message session principale, 2026-11-14), option (a) — P75-D-32.
- Audit et mutants de garde réservés à 75-03 et 75-05 (accord de la session principale) ; XSS avec mutant partout.
- Fusionnés par sha, à la demande de la session principale : 76-04, 79-13, 79-15, 79-16, 79-17/22/18 ; cueillettes de la 79.

## Rouges de CI et causes
- #245 run 43494419728 : mutant K8 lu vert après alarme sur runner lent (75-03, compté) ; D10.7 `binaire` passé en
  production (75-05, faux git par le PATH) ; T7.2b et S3 venus de 79-15.
- #245 run 43511744943 : questions Q11.7, accessibilite (course « ready »), robustesse W, git-entete, marque blanche,
  R3.4 — tous venus de 79-16, corrigés par cueillette de commits de la 79.
- Local : collecte (C0.2, C4.4a, C12.4b) intermittents sous charge (17 Chrome) ; règle du jeton Chrome adoptée.

## Mineurs versés au BACKLOG
Revue 1 (6), revue 2 (3), audit 75-03 (no-op), juge design (2), limites de l'API figée de VF_MARQUES, noms des suites
gardiennes non servis, écarts de géométrie face à la spec (au goût de la recette).

## Ce qu'une autre phase doit savoir
- 74 : API `VF_MARQUES` figée ; rangées `[id, palier, glyphe, mot, infobulle]` ; `relecture` = glyphe neutre, mot « relu ».
- 80 : pied réservé sur l'onglet Code (`const reserve =`) ; `#btn-recent`, `ui/25-recent.js`, `recentWork` n'existent plus.
- 73 : route `/api/vf/ailleurs` extraite dans `vf-cockpit-route-ailleurs.mjs` (plafond F.1).

## Preuves E6
```json
{"preuves":[
{"verdict": "gate:test-cockpit-vendor", "commande": "bash plugin/cockpit/scripts/tests/test-cockpit-vendor.sh", "exit_code": 0, "sha": "60290acbbe1ba44d2c34bbfbdcb44d8084ba44cd"},
{"verdict": "gate:check-machine-paths", "commande": "bash scripts/check-machine-paths.sh", "exit_code": 0, "sha": "60290acbbe1ba44d2c34bbfbdcb44d8084ba44cd"},
{"verdict": "gate:check-version-sync", "commande": "bash scripts/check-version-sync.sh", "exit_code": 0, "sha": "60290acbbe1ba44d2c34bbfbdcb44d8084ba44cd"},
{"verdict": "gate:mission-invariants", "commande": "bash plugin/conductor/scripts/check-mission-invariants.sh", "exit_code": 3, "sha": "d487f3721c4328f19364cdca1241dc184db76208"}
]}
```
