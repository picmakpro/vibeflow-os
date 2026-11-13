---
phase: 73
plan: "02"
requirements: [REGI-13]
---

# 73-02 — SUMMARY : « ailleurs() » et `GET /api/vf/ailleurs`

Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale).

## Livré

- `ailleurs(home, { racines, now, homeDir })` en fin de `vf-cockpit-etat-officiel.mjs` : `[{ lab, n }]` trié par `n` décroissant puis `lab`, ou `null`
  (aucune lecture officielle de moins de 60 s, liste illisible, entrée « vous attend » sans `cwd` chaîne, racines inconnues). Jamais `0` faute de lecture.
  Les dossiers des sessions en attente vivent dans la mémoire privée du cache (`c.attendent`), jamais exportée ; une seule ligne existante change (le rappel d'`execFile` qui appelle `clos`).
- Règle A7 retenue : dossier personnel, un de ses ancêtres, ou chemin de moins de deux segments (après retrait du suffixe `/.claude/worktrees/<n>`) → « un autre dossier » ;
  sinon dernier segment passé par `nettoie` (contrôles et sens d'écriture retirés), borné à 40. « Sous une racine » se juge par segment entier, sur chemins réels
  (ancêtre existant le plus proche résolu pour un dossier disparu).
- Route `GET /api/vf/ailleurs` : une ligne de `ROUTES` (première, ordre alphabétique), réponse gardée commune (hôte, origine, jeton, GET seul, no-store, garde d'émission),
  corps `{ schema: 'vibeflow/cockpit-ailleurs@1', ailleurs }`. Racines du lab (`arbresGit`, lien retour vérifié) relues au plus une fois par `REPIT_MS`.
- Suite : `regie-rg-ailleurs.sh` (RG13_officiel, RG13_route), 21 assertions ; trace : `73-02-RED-TRACE.md`.
- Mutants vus rouges puis retirés (copies jetables, jamais le dépôt) : M-AILLEURS-CWD, -TITRE, -SOUS-ARBRE, -HOME, -GIT ; M-ROUTE-PAR-REQUETE ; M-ROUTE-SANS-JETON (portail de serve.mjs ET contrôle de l'accès gardé).

## Écarts

- Écart : la collecte lit `claude agents --json` dans un fil (worker) ; le cache de `vf-cockpit-etat-officiel.mjs` du processus serveur reste vide, donc la route lance elle-même `demander` (une lecture au plus par `REPIT_MS`, jamais une par requête) ; null jusqu'à la première lecture.
- Écart : la suite `test-cockpit-routes.sh` a deux lignes en dur de plus à tenir que la seule liste de RK.1 (compteur de couverture de RK.7 : 7 → 8) et le libellé de RK.1 ; trois lignes modifiées, aucune déplacée.
- Écart : `socle-serveur.sh` (79-02) existe : le fragment lance le serveur par `cockpit_lancer`, mutants de serveur par `cockpit_module_muter`. `regie-commun.sh` n'est pas modifié ; la section `RG13_route` repose le trap EXIT de la suite (`vf_hyg_fin` puis suppression de `$WORK`) pour arrêter ses serveurs.
- Écart : la mémoire privée de `ailleurs()` n'est pas vidée explicitement à l'échec de lecture : `clos(null)` met la carte à `null`, que `ailleurs()` teste d'abord (une liste périmée n'est jamais lisible).

## Suites jouées (une fois, tête commitée) et verdict

| Suite | Verdict |
|---|---|
| `test-cockpit-regie.sh RG13` | vert, 21 PASS / 0 FAIL |
| `test-cockpit-routes.sh` | 54 PASS / 2 FAIL : R1.8 et RC.1 (clé `lecturesPlanning` ajoutée à `/api/vf/etat` par le travail concurrent du plan 73-03 dans `vf-cockpit-live.mjs`, non commité au moment de la mesure) ; RK.1 et RK.7 PASS ; vert à 56/0 avant ce changement concurrent |
| `test-cockpit-securite.sh` | vert, 103 PASS / 0 FAIL |
| `test-cockpit-equipe-etats.sh` | vert, 86 / 0 |
| `test-cockpit-serveur.sh` | vert, 98 PASS / 0 FAIL |
| `test-cockpit-vendor.sh` | 250 PASS / 2 FAIL : V4 (connu, `chrome-coin.mjs` à 300 lignes) et V4c.9a (hausse de `vf-cockpit-gouvernance-lecture.mjs`, fichier d'un autre plan ; `etat-officiel` et `server` égaux à leur baseline) |
| `check-file-size.sh` (deux modules) | vert |
| `scripts/check-machine-paths.sh` | vert |
| `scripts/check-version-sync.sh` | seul écart : lignes « suites » (226 ≠ 227, plan 73-10) |

Gate-Touche : aucun chemin des six classes touché. `colonnes-baseline.txt` inchangée.

## Pour les autres phases

- Contrat consommé par 73-07 : réponse `{ schema, ailleurs }`, `ailleurs` est une liste ou `null` (le client ne doit pas lire `null` comme 0).
- `ROUTES` compte désormais 8 routes ; toute phase qui en ajoute une met à jour `ATTENDU` et le compteur de RK.7 dans `test-cockpit-routes.sh`.
- 73-03 : la clé `lecturesPlanning` de `/api/vf/etat` fait rougir R1.8 et RC.1 de `test-cockpit-routes.sh` tant que leurs attendus ne la citent pas.

## Correctifs d'audit

- Constat 2 (clés en trop) : la liste d'interdits d'ailleurs@1 n'était lue par aucun code, la route appliquait celle de who@2. Correctif : à l'émission, une entrée sort seulement si elle a exactement les clés `lab` et `n`. Témoin : RG13.15, vu rouge sur la tête d'avant ; mutant EXTRA-GARDE vu rouge puis retiré. Commit f5b9ff46.
- Constat 3 (git synchrone dans le gestionnaire) : nouvelle `arbresGitAsync` (`lancerGitAsync`, comme P78-D-41), lecture lancée en tâche de fond, au plus une à la fois et une par `REPIT_MS` ; contrat inchangé (`{ schema, ailleurs }`, `null` avant la première lecture). Témoin : RG13.16 (faux git qui dort 3 s, requête d'état servie en moins de 1,5 s), vu rouge sur la tête d'avant ; mutant LENT-SYNC vu rouge puis retiré. Commit 49db6e0f.
- Écart : l'ancre du mutant ROUTE-PAR-REQUETE suit la ligne déplacée du serveur.

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)
