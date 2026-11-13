# 73-01 — SUMMARY : socle de la suite unique et module de gouvernance

Exigences : REGI-04, REGI-05, REGI-07, REGI-10, REGI-16. Trace du rouge et valeurs saines des sondes mutées : `73-01-RED-TRACE.md`.

## Livré

- `plugin/cockpit/scripts/vf-cockpit-gouvernance.mjs` (162 lignes, aucune ligne au-delà de 160 colonnes, lecture seule).
- `plugin/cockpit/scripts/tests/test-cockpit-regie.sh` (lanceur), `regie-commun.sh` (préambule sourcé), `regie-rg-gouvernance.sh` (fragment : RG0, RG4, RG5, RG7, RG10 et dix mutants).

### Contrat du lanceur (consommé par 73-02 et 73-03)

- `bash plugin/cockpit/scripts/tests/test-cockpit-regie.sh [SECTION…]` ; section = fonction `rg_<NOM>` d'un fragment `regie-rg-*.sh`, `<NOM>` = `RG<n>_<couche>` ; l'argument `A` retient `A` et `A_*` (RG1 ne retient pas RG10_x) ; section inconnue : `❌ FAIL — section inconnue : A` ; sans argument : toutes, ordre trié ; dossier des fragments : `VF_REGIE_FRAGMENTS` (autotest RG0 seulement). Un fragment ne fait que définir des fonctions. Un nouveau fragment est ramassé tout seul (aucune liste à éditer).
- Bilan `Résultats : N PASS / M FAIL`, sortie 1 si M > 0 ou si N = 0.
- `regie-commun.sh` fournit : `SCRIPTS`, `TESTS_DIR`, `UI`, `WORK` (trap), `AUX`, `HOME` jetable, `PASS`/`FAIL`, `assert_eq|assert_has|assert_not|assert_ok` (`assert_eq "<id> — <libellé>" <obtenu> <attendu>`), `G`, `rg_node`, `rg_mut <nom> <dossier> <fichier> <ancre> <remplacement>`, `rg_copie`, et en plus `rg_mutant <NOM> <libellé> <dossier> <fichier> <ancre> <remplacement> <sonde> <valeur saine>` (assertion `M-<NOM>`, mutant tué si la sonde sur la copie diffère de la valeur saine). `gv <dossier de scripts> <corps JS> [args…]` (importe le module de gouvernance) est défini dans le fragment 73-01, pas dans le commun.

### Exports du module (consommés par 73-03)

`aval(noeuds, depart)`, `restants(noeuds)`, `detention(idSession, verrous)` (verrous = objet brut `{ locks }`, liste de verrous, ou verrou unique ; champ `session_ids` tableau), `missionDe({ ws, phase }, { dags, phases })` (phases = `Map` de `readPlanning`), `retientDe({ rattachement: { dag (nom, fichier ou objet), noeud }, detention }, { dags, phases })` → `{ n, portee }` ou null, `enteteStatut(texte)`, `phasesHumaines({ phases, lire, fichiers })`, `fenetreStall({ env, texteScript })`, `scriptGarde({ scriptsDir, labRoot, home })`, `attendAgents(fichier)`.

## Écarts

- Écart : `phasesHumaines` reçoit en plus `fichiers(cle)` (noms du dossier de la phase), le plan ne nommait que `lire(cle, fichier)` ; les objets de phase de `readPlanning` ne portent pas la liste de leurs fichiers.
- Écart : seize lignes du module dépassaient le plafond de 160 colonnes (V4c.9a, fichier neuf à plus de 0 interdit) et imposaient un recoupage du module ; fait au commit `chore(73-01)`, comportement inchangé.
- Écart : la tâche 3 vise « `test-cockpit-vendor.sh` vert » ; V4 « check-file-size.sh sur tout le code du module » reste rouge pour une cause de la base : `plugin/cockpit/scripts/tests/chrome-coin.mjs` fait 300 lignes à faed809d (seuil de blocage). Hors périmètre de ce plan, non touché.

## Suites jouées (une fois, sur la tête commitée)

- `test-cockpit-regie.sh` (toutes sections) : vert, 35 PASS / 0 FAIL, dont les dix mutants tués.
- `test-cockpit-vendor.sh` : 251 PASS / 1 FAIL (V4, `chrome-coin.mjs` à 300 lignes, base) ; V4c.9a vert après recoupage.
- `check-file-size.sh` sur le module : ✓ ; `check-machine-paths.sh` : ✓ (aucun chemin de machine).
- `check-version-sync.sh` : seule ligne en échec, la ligne « suites » des deux README (`226 suites` écrit, 227 réelles, recompte au plan 73-10) ; toutes les autres lignes ✓.

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)
