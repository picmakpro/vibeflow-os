# 68-03 — SUMMARY : émetteur `signal@1` du socle (VFSG-03, VFSG-11 ; P68-D-02, P68-D-14, P68-D-15)

Trace du rouge : `68-03-RED-TRACE.md` (10 PASS / 33 FAIL avant le code, cause : émetteur et schéma absents).

## Commits (branche `feat/phase-68-w03`, base `89a6b649`)

| Empreinte | Objet |
|-----------|-------|
| `7ce542e2` | test(68-03) : suite `test-cockpit-signal.sh`, rouge |
| `d0cd9d80` | docs(68-03) : trace du rouge |
| `a6c8a276` | feat(68-03) : `vf-cockpit-signal.mjs`, phases, avancement@2, jalons, missions (tracer) |
| `d42b9f20` | feat(68-03) : arbres, retard, verrous, équipe `who@2` ; schéma `vibeflow/cockpit-signal@1` au contrat |
| `32400bfc` | test(68-03) : S8 vert (correction d'une attente de S8.1) |

Ordre tests, trace, code tenu (OK-ORDRE sous zsh et bash). Artefacts posés d'office : aucun hors `68-03-RED-TRACE.md` et ce fichier.

## CLI de l'émetteur (pour 68-05)

`node <dossier-du-module>/cockpit/scripts/vf-cockpit-signal.mjs <racine-du-lab>` : exactement UN argument, une racine existante ; JSON sur une ligne (stdout), exit 0.
Exit 2 (usage sur stderr, stdout vide) : aucun argument, plus d'un argument, argument commençant par `-` (donc `--plugin-root`, `--json`…), racine absente. Pas de `--plugin-root` (P68-D-28).
Le verrou se résout seul : `VF_COCKPIT_SCRIPTS_DIR` s'il est posé, sinon le dossier du fichier ; conductor voisin `…/plugin/conductor/scripts/` quand le fichier est sous `…/cockpit/scripts` ; copie de HOME en repli. Ne poser `VF_COCKPIT_SCRIPTS_DIR` que sur les appels qui calculent.
Export : `collectSignal(root, { home, now, scriptsDir })` ; `SCHEMA`.

## Écarts au plan

1. **S6.3b ajouté** : S6.3 (« script planté jamais exécuté ») est vert avant le code par construction (aucun script lancé) ; S6.3b (verrous `absente` avec HOME = le lab planté) est rouge avant le code et interdit le vert à vide. S6.0 : témoin positif (le script planté laisse son fichier témoin quand on le lance). Le lab piégé est un lab distinct (`lab-trap`), pour ne pas toucher aux autres sections.
2. **S4 scindée** : S4.1 = avancement, S4.2 = état de mission (le plan les cumulait sous S4.1). S8 a deux mutants : M1 (état de mission recalculé depuis les nœuds : S3.2 et S4.2 rougissent) et M2 (avancement recalculé, `version: 3` : S4.1 rougit), chacun avec contrôle d'ancre unique (S8.0) et exigence que le rouge soit un écart de contenu, pas une panne.
3. **Attente de S8.1 corrigée** après le premier vert (espace final de trop dans la sous-chaîne attendue, `cut -c1-22`) : le rouge de la trace reste vrai (aucune copie à muter avant le code).
4. **Contrat** : `validate.mjs` de la suite refuse aussi toute clé hors `requis` + `optionnels` dans les sous-objets (phase, jalon, mission, noeud, verrou, arbre, retard) ; le contrat porte ces sous-schémas.
5. Les phases d'archive sont exclues (fixture `milestones/v0-ROADMAP.md`, S3.1) ; `phaseActive` d'un arbre reçoit les phases hors archive de CE arbre (planning relu par arbre, l'arbre courant réutilise la lecture de `root`).
6. `mission.ws` = `ws` du DAG, repli sur `wsDeclare` puis `null` (lab plat : `null`) ; `phases[].ws` et `jalons[].ws` valent `null` en lab plat.

## Mesure sur ce dépôt

`node plugin/cockpit/scripts/vf-cockpit-signal.mjs "$PWD"` : 3 s (14 worktrees, schéma attendu présent), 108 338 octets, exit 0.

## Suites rejouées (sorties `68-03-*.out` du scratchpad, deux à la fois)

`test-cockpit-signal.sh` 43/0 ; `-vie.sh` 30/0 ; `-retard.sh` 38/0 ; `-who.sh` 87/0 ; `-avancement.sh` 61/0 ; `-reseau.sh` 15/0 ; `-assemblage.sh` 40/0 ; `-marque-blanche.sh` 22/0 ; `-vendor.sh` 77/0 — toutes exit 0.
`bash scripts/check-gate-touche.sh` : RIEN-A-JUGER ; `bash scripts/check-machine-paths.sh` : vert (2458 fichiers). `vf-cockpit-signal.mjs` : 65 lignes (plafond du plan 300).

## Estimation / actuels

`estimate` du plan : 90 000 jetons, 3 tâches, confiance basse. Pas de `actuals:` : exécution en ligne, sans `gsd-executor`.
