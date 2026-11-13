# 74-01 — trace du rouge (suite écrite avant les modules)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-frise-modele.sh` (modules `ui/74-vf-frise-calculs.js` et `ui/74-vf-frise-modele.js` absents).
Résultat : exit 1, `=== 1 PASS, 21 FAIL ===`. Le seul PASS est le contrôle positif F0 (sur un dossier vide, chaque section rougit : « une sonde reste verte sans module : aucune »).

| Section | Verdict | Raison du rouge |
|---|---|---|
| F0 | FAIL | modules chargés : module absent ou illisible (`74-vf-frise-calculs.js`) |
| F1 | FAIL | exception : `window.__vfFriseModele` absent, `lire` introuvable |
| F2 | FAIL | exception : `commitsParBranche` introuvable |
| F3 | FAIL | exception : `arbre` introuvable |
| F3b | FAIL | exception : `arbre` introuvable (cycle de `parent`, plafond de 500) |
| F4 | FAIL | exception : `FENETRES` introuvable |
| F5 | FAIL | exception : `arbre` / `replier` introuvables |
| F6 | FAIL | exception : `projection` introuvable |
| F6b | FAIL | exception : `projection` introuvable (graduations, TZ=Europe/Paris) |
| F7 | FAIL | exception : `lire` / `etatA` introuvables |
| F8 | FAIL | exception : `noeudsPortes` introuvable |
| F9 | FAIL | exception : `agreger` / `etages` introuvables |
| F10 | FAIL | les deux modules ne sont pas présents (a), `CHAMPS_LUS` introuvable ; (b) annoncée « NON vérifiée » |
| F11 | FAIL | exception : `courbe` introuvable |
| F12 | FAIL | exception : `commitsParBranche` / `couverture` introuvables |
| F13 | FAIL | exception : `delta` / `voiesAutour` introuvables |
| F14 | FAIL | exception : `fichiersA` introuvable |
| F15 | FAIL | exception : fichiers des modules absents (lecture impossible) |
| FMT | FAIL | exception : `fmtJetons` introuvable |

Aucun mutant (régime allégé : plan non marqué audit). Rituel levé : voir `74-01-SUMMARY.md`.
