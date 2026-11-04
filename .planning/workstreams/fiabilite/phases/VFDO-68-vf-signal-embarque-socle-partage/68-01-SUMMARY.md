# 68-01 — SUMMARY : règle de mission vivante dans le socle, `avancement@2` (VFSG-06)

Trace du rouge : `68-01-RED-TRACE.md` (rouge avant le code, annexes V5 corrigé, témoin P68-D-29, témoins P-VIE).

## Commits (branche `feat/phase-68-w01`, base `0586746f`)

| Empreinte | Objet |
|-----------|-------|
| `7ad90e3f` | docs(68-01) : correction du plan, dossier de scripts explicite en plus du `HOME` (P68-D-29 ; F-01, F-02) |
| `23cb1612` | test(68-01) : suite `test-cockpit-vie.sh`, rouge (5 PASS / 25 FAIL) |
| `e042e25f` | docs(68-01) : trace du rouge |
| `34bf26f3` | feat(68-01) : `vf-cockpit-vie.mjs`, `etatMission(nodes, vie)`, `readPlanning(root, layout, opts)` ; suite verte 30/30 |
| `cfe5414d` | feat(68-01) : contrat `avancement@2` ; A2.5, A2.6, A7.1 réécrites par conception |
| `937c900a` | test(68-01) : témoin rouge de la carte Projet (P-VIE.1 à P-VIE.4, 57 PASS / 4 FAIL) |
| `5c9b290a` | feat(68-01) : carte Projet, pied et détails en libellés, `test-cockpit-who.sh` épinglé |

Artefacts posés d'office : aucun hors `68-01-RED-TRACE.md` et ce fichier.

## Assertions réécrites par conception (contrat 2)

- A2.5 : version 2 (le contrat monte de 1 à 2).
- A2.6 : `mission` porte `nom`, `etat` et `vie` (`"vie":null` pour une mission sans nœud `running`).
- A7.1 : le bloc du contrat égale `ETATS_MISSION` (six états) et sa clé `vie` ; la version attendue passe à 2. A7.2 reste rouge sur la copie mutée.

## Écarts au plan et décisions d'exécution

1. **`vie` absent quand l'appelant ne lit pas les verrous** : `choisir` rend `vie: m.vie` (non forcé à `null`). Sinon A11.5 et A11.6 (assertions hors périmètre du plan) changeaient. `readPlanning` pose toujours `null` ou un objet.
2. **Lecture paresseuse des verrous** : `readPlanning` ne lance `driver-lock.sh status --all` que si un DAG porte un nœud `running` ; les autres DAG ont `vie` = `null` et leur état ne dépend pas de `vie`. Une session de cockpit sans mission en cours ne paie aucun shell-out. Risque connu : le serveur vivant relit le verrou à chaque reconstruction du graphe tant qu'une mission est `running` (borné à 10 s par appel).
3. **V7.1 scindé en V7.1 (script jamais exécuté, vert avant et après le code) et V7.2 (mission `inconnu`)** : le plan annonçait V7.1 vert avant le code. V0.4 (lab partitionné) et V5.3 (témoin P68-D-29 : le conductor voisin est trouvé quand aucun dossier n'est passé) ajoutés.
4. **Accesseur de V5.1/V5.2** corrigé après le premier vert (`?? "absent"` confondait `null` et champ absent) ; rouge rejoué sur `e042e25f` par `git archive`, consigné en annexe de la trace.
5. **Épinglage du dossier de scripts par suite (F-01, F-02)** :
   - `test-cockpit-vie.sh` : `scriptsDir` par cas ; `HOME` jetable.
   - `test-cockpit-avancement.sh` : `HOME` jetable + `VF_COCKPIT_SCRIPTS_DIR` vers un faux verrou tenu (processus en ligne seulement).
   - `test-cockpit-projet.sh` : `HOME` jetable ; le dossier n'est posé QUE sur les appels `Q` (en processus), jamais en export global : le vrai lanceur de la section O4 fait de `VF_COCKPIT_SCRIPTS_DIR` le dossier de scripts du module (un export global a fait échouer O4.0 à O4.7, « page prête dépassée »).
   - `test-cockpit-who.sh` : `Q project` épinglé (`HOME` + dossier explicite), seul appel en processus de la suite.
   - **`test-cockpit-direct.sh`, `-equipe.sh`, `-responsive.sh` : aucune modification.** Leurs fixtures à nœud `running` ne passent que par des serveurs construits qui tournent depuis le dossier de sortie du lab (`.vibeflow/cockpit`, hors disposition `…/cockpit/scripts` : le conductor voisin ne s'y cherche pas) sous un `HOME` jetable déjà exporté (`direct`, `responsive` : `HOME` jetable en tête ; `equipe` : `HOME="$HS"`/`"$H23"` sur chaque serveur ; `responsive` : dossier hôte nommé autrement que `scripts`). Y ajouter un dossier de scripts explicite aurait changé le dossier de scripts du serveur (`revealDoing`) sans rien épingler de plus. Conséquence : la vérification `grep` par suite du bloc `<automated>` ajouté par l'étape 0 rend `SANS-DOSSIER direct` (les cinq autres suites contiennent `VF_COCKPIT_SCRIPTS_DIR` ou `scriptsDir`) ; c'est une constatation, pas une dérive.
   - Témoin négatif consigné (sortie en `$scratchpad/neg-av.out`) : `test-cockpit-avancement.sh` jouée SANS son `export VF_COCKPIT_SCRIPTS_DIR` rougit (54 PASS / 7 FAIL : A2.3, A4.3, A9.1, A9.3 à A9.5, A11.4 — le vrai conductor est trouvé, la mission `running` devient `abandonnee`). Témoin positif de la suite neuve : V5.3.
6. **Faux verrou legacy de `test-cockpit-responsive.sh`** (`scope: "repo"`, `ws: ""`) : sous la règle neuve, sa mission `running` se lit `abandonnee` (aucune entrée `depot`) ; aucune assertion de la suite ne porte sur l'état de mission, verte 191/0. À rouvrir si une phase ultérieure assert l'état de cette mission.

## Preuves de non-régression

- `test-cockpit-vie.sh` 30/30 ; `-avancement.sh` 61/61 ; `-projet.sh` 61/61 ; `-who.sh` 87/87 (après épinglage).
- Toutes les `test-cockpit-*.sh` sauf `retard` (68-02) et `signal*` (68-03/04), soit 22 suites, rejouées sous un `HOME` vide puis sous un `HOME` portant un faux `driver-lock.sh` (`present: false`) : 22 verdicts `0 0`, égaux. Mesure faite avant l'épinglage de `who` ; `who` rejouée ensuite seule (87/0). `test-cockpit-vie.sh` : mutants V8, V9.3, V9.5, V9.7, V9.9, V10.3 verts (assertion visée rouge sur la copie).
- `bash scripts/check-gate-touche.sh` : RIEN-A-JUGER (aucun chemin de surface surveillée touché) ; `bash scripts/check-machine-paths.sh` : vert (2426 fichiers). Étape 9 de `check-version-sync.sh` (compte des suites) rouge par construction jusqu'à 68-09 (P68-PL-07), non rejouée.
- `vf-cockpit-paths.mjs` non modifié (`git diff --name-only 794c6dba..HEAD -- plugin/cockpit/scripts/vf-cockpit-paths.mjs` vide) ; `grep -c mtime vf-cockpit-vie.mjs` = 0 ; longueurs : vie 64, avancement 100, planning 166, project 153 lignes.

## Estimation / actuels

`estimate` du plan : 105 000 jetons, 3 tâches, confiance basse. Pas de `actuals:` : exécution en ligne, sans `gsd-executor` ni mesure d'exécuteur.
