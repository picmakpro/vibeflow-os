# 72-BRANCHEMENTS-MERGE — recensement des branchements de la Phase 72 pour le merge (P72-D-18)

Établi à la planification (2026-11-05), sur la liste `files_modified` des plans 72-01 à 72-15, avant toute exécution. Il est **à re-dériver**
de `git diff --name-status <base>..<tête> -- plugin/` (statut M, relevé via `rtk proxy`) à la clôture de l'exécution, comme l'a fait
`../VFDO-71-terminal-integre-cockpit/71-BRANCHEMENTS-MERGE.md`. Principe (P72-D-18) : tout le code vit dans des fichiers neufs ; les points de
branchement dans des fichiers existants sont minimaux et listés ici. Base de planification : `aff9f260` ; main porte depuis la clôture de la 71
(`1e4d1ecd`, cockpit v1.3.3) : le manager rebase la branche avant l'exécution.

## 1. Fichiers existants touchés sous `plugin/cockpit/` (statut M attendu)

| # | Fichier existant | Plan | Changement prévu | Conflit possible |
|---|------------------|------|------------------|------------------|
| B1 | `skills/cockpit-moteur/terminal/vf-cockpit-pty.py` | 72-02 | marqueur `vibeflow:allow-large-file` en ligne 1 (dette tracée, 464 lignes) ; ligne de contrôle fd 3 `L <hex>`, réponse fd 2 `LANCE …` ; ajouts seulement | faible (la 71.5 ne le touche pas) |
| B2 | `scripts/vf-cockpit-terminal-session.mjs` | 72-02 | `sessions.lancer(ligne, onglet)` ; le parseur d'état accepte les lignes `LANCE …` ; ajouts seulement | faible |
| B3 | `scripts/vf-cockpit-equipe-carte.mjs` | 72-07 | paramètre optionnel `lancees` de `buildEquipeGraph` ; sortie octet pour octet identique quand il est absent | faible |
| B4 | `scripts/vf-cockpit-terminal-vue.mjs`, `scripts/vf-cockpit-terminal-client.mjs` | 72-08, puis 72-13 | bandeau de proposition (classes `vf-q-bandeau`/`vf-q-collage` réutilisées), sondage de `GET /proposition`, émission de la valeur fixe `proposition` vers P, mode retenu dans le stockage de l'origine Q ; 72-13 : case « continuer le chat » | **possible** avec la 71.5 si elle touche les classes du bandeau ; aucun style n'est ajouté ici |
| B5 | `scripts/vf-cockpit-server.mjs` | 72-09 | relevé réel (`rtk proxy git diff 1e4d1ecd..HEAD`, 7 hunks, 5 lignes ajoutées et 2 lignes modifiées, (5) et (7)) : (1) en-tête, ligne de commentaire des routes `GET /api/vf/lancer/cibles` · `POST /api/vf/lancer` ; (2) `import { creerLancer }` ; (3) `const lancer = creerLancer({ root, here, ptoken, log })` après `load()` ; (4) `lancer.sourceWho(() => live ? live.snapshot().who : null)` après `startLive` ; (5) branche non-GET de `route` : `lancer.reconnait(url)` puis `lancer.traiter(req, res, url)` avant le 405 ; (6) `if (lancer.get(req, res, url)) return true;` avant le 404 final ; (7) `pageEquipe` : `lancees: lancer.lancees()` dans les options de `buildEquipeGraph` | **possible** avec la 78 (routes et lecture Git) : hunks distincts, ne jamais écraser |
| B6 | `scripts/vf-cockpit-terminal.mjs` | 72-09 | `injection()` concatène `injectionLancer` ; renseigne le canal de lancement ; relais des messages IPC `cibles`, `proposition`, `lancee` | faible |
| B7 | `scripts/vf-cockpit-terminal-processus.mjs` | 72-10 | routes `GET /proposition`, `POST /lancer`, `POST /annuler` dans la table fermée, messages IPC ; `GET /proposition` passe par `controle(req, <url de /etat>)` dans `traiter` (commit 549d3bcc), et NON par la ligne `navigateur` de la 71, laissée intacte | faible |
| B8 | `scripts/vf-cockpit-terminal-tiroir.mjs`, `scripts/vf-cockpit-terminal-tiroir-style.mjs`, `scripts/tests/test-cockpit-terminal-tiroir.sh` | 72-14 | valeur fixe `proposition` ajoutée à `LISTE_MESSAGES`, ouverture du tiroir sans prise de focus ; assertions existantes inchangées, ajouts seulement | **certain** avec la 71.5 (style du tiroir) : relire la base `origin/main` avant d'éditer |
| B9 | `VERSION`, `module.json`, `CHANGELOG.md`, `README.md`, `skills/vf-cockpit/SKILL.md` | 72-15 | bump unique au-dessus de v1.3.3 (calculé à l'exécution), usage de « Lancer », limites (mode hérité, boîte « faire confiance », un seul terminal, travail non commité reporté à la 78) | **certain** avec la 78 et la 71.5 : ajouter, ne pas réécrire |
| B10 | `README.md`, `README.fr.md` (racine) | 72-15 | le seul nombre de la phrase « N suites » | **certain** : recompter après fusion, jamais additionner |

Non touchés : `skills/cockpit-moteur/assets/serve.mjs` (vendoré ; patchs tracés dans `VENDORED.txt` et `amont/patches/`), `scripts/vf-cockpit-build.mjs`
(le build copie `vf-cockpit-lancer*.mjs` par le motif `^vf-cockpit-.*\.mjs$`), `scripts/vf-cockpit-interface.json`, `scripts/tests/terminal-aux.mjs`,
`scripts/tests/test-cockpit-terminal-xss.sh`, `scripts/vf-cockpit-terminal-style.mjs`, tout `assets/ui/` (CSP de page identique sans `--terminal`).

## 2. Fichiers neufs (aucun conflit possible)

Modules `scripts/vf-cockpit-lancer-{gabarit,cibles,post,q,ui,suivi,canal}.mjs` et `scripts/vf-cockpit-lancer.mjs` ; suites `scripts/tests/test-cockpit-lancer-*.sh`
(onze) ; témoins `scripts/tests/temoins/lancer-*`, `temoins/fauxbin-claude/`, `scripts/tests/chrome-lancer.mjs`.

## 3. Couplages de lecture à contrôler au merge

- **78** : `vf-cockpit-server.mjs` (B5), en-tête du viewer et `00-vibeflow.js` ; le calcul « travail non commité » reste à la 78 (emplacement inactif ici, P72-D-07).
- **71.5** : `vf-cockpit-terminal-tiroir-style.mjs` (B8) et la palette ; le bandeau de la 72 n'utilise que des variables et classes existantes.
- **`window.VibeFlow.addPanelSection`** et l'en-tête `x-vf-cockpit-token` : noms de la sortie renommée (`vf-cockpit-rename.mjs`), à garder.
- **`VF.ptoken` et `jetonValide`** : les contrôles du POST de P les utilisent.

## 4. Procédure de fusion

1. Rebaser sur `origin/main` avant l'exécution des plans de la vague 3 qui touchent le tiroir (72-14) et avant le bump (72-15) : relire `VERSION`, tiroir, style sur la base.
2. `vf-cockpit-server.mjs` : fusionner les hunks de la 72 et de la 78, jamais l'un par l'autre.
3. README, CHANGELOG, VERSION, `module.json` : ajouter sans réécrire ; version recalculée (mineure suivante du plus haut de `origin/main` et de la branche) ; aligner d'un geste avec `check-version-sync.sh`.
4. README racine : nombre de suites recompté après fusion.
5. Rejouer après fusion : les suites `test-cockpit-lancer-*.sh`, les dix `test-cockpit-terminal-*.sh`, `test-cockpit-chaine-xss.sh`, `test-cockpit-serveur.sh`, `test-cockpit-securite.sh`, `test-cockpit-reseau.sh`, `test-cockpit-projet.sh`, `test-cockpit-equipe.sh`, `test-cockpit-vendor.sh`, `synchro.sh verifier`, `check-version-sync.sh`, les gates du job `gates` de `ci.yml`.
6. Précondition connue : `check-machine-paths` est rouge à la base sur `72-RESEARCH.md:238` (chemin de compte) ; à corriger avant la PR.

## 5. Ajouts du plan 72-16 (mode retenu d'une relance à l'autre ; P72-D-20)

Relevé réel sur `git diff --numstat 2b9e23b9..HEAD` (insertions / suppressions ; lignes avant -> après).

| # | Fichier existant | Plan | Changement | Lignes | Conflit attendu |
|---|------------------|------|------------|--------|-----------------|
| B7 (précision) | `scripts/vf-cockpit-terminal-processus.mjs` | 72-16 | un import, une création de mémoire (`// garde:mode-support`), `lireProposition` enrichie de `mode_retenu` pour l'état en-attente (`// garde:mode-servi`), un appel `ecrire` après le test de `w.ok` et avant `lq.confirmer` (`// garde:mode-ecrit`), une phrase d'en-tête ; la table `routes`, les trois lignes de contrôle de la 71 et le routeur IPC intacts | +5 / -1 ; 199 -> 203 | moyen : `lancer()` et `lireProposition` sont aussi touchés par les correctifs de revue |
| B4 (précision) | `scripts/vf-cockpit-terminal-client.mjs` | 72-16 | `CLE_MODE` retiré ; `modeRetenu()` (lecture du stockage) remplacée par `modeServi(p)` (valeur servie relue contre `MODES`, marqueurs `garde:mode-lecture` et `garde:mode-relu` conservés) ; `lire` passe le JSON brut à `modeServi` ; l'écriture `setItem` du 204 retirée | +8 / -9 ; 280 -> 279 (plafond LB.S3 : 280, jamais relevé) | faible |
| B11 | `scripts/tests/test-cockpit-lancer-bandeau.sh`, `scripts/tests/test-cockpit-lancer-processus.sh` | 72-16 | bandeau : LB.C4 (deux assertions), LB.E2 (dernière valeur), LB.E5, LB.E6 transposés, serveur factice qui sert `mode_retenu`, doublures du stockage qui observent toutes les opérations, deux sondes Chrome de plus sur M-MODE-NON-RELU et M-PARAM-URL ; processus : `mode_retenu` dans la liste exacte de clés de Q2 | bandeau +35 / -28 (838 -> 845) ; processus +1 / -1 | faible |
| B12 | `README.md` (module cockpit) | 72-16 | un paragraphe d'usage dans « Terminal intégré » : le mode retenu survit aux relances, fichier du lab non suivi, jamais lu par la page Projet | +2 / -0 | moyen : 72-15 réécrit la même section ; 72-15 passe APRÈS et ajoute sans réécrire |

Fichiers neufs de 72-16 : `scripts/vf-cockpit-lancer-mode.mjs` (57 lignes) et `scripts/tests/test-cockpit-lancer-mode.sh`. Hors `files_modified`, dits : `72-CONTRATS.md` §4 (clé `mode_retenu`).
Rappel au manager : 72-15 (bump de version, README, CHANGELOG) doit dépendre de 72-16.
