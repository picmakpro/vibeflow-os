# 72-BRANCHEMENTS-MERGE — recensement des branchements de la Phase 72 pour le merge (P72-D-18)

Établi à la planification (2026-11-05), sur la liste `files_modified` des plans 72-01 à 72-15, avant toute exécution. Il est **à re-dériver**
de `git diff --name-status <base>..<tête> -- plugin/` (statut M, relevé via `rtk proxy`) à la clôture de l'exécution, comme l'a fait
`../VFDO-71-terminal-integre-cockpit/71-BRANCHEMENTS-MERGE.md`. Principe (P72-D-18) : tout le code vit dans des fichiers neufs ; les points de
branchement dans des fichiers existants sont minimaux et listés ici. Base de planification : `aff9f260` ; main porte depuis la clôture de la 71
(`1e4d1ecd`, cockpit v1.3.3) : le manager rebase la branche avant l'exécution.

## 1. Fichiers existants touchés sous `plugin/` (statut M) — re-dérivé à la clôture

Relevé : `rtk proxy git diff --name-status origin/main HEAD -- plugin/` (HEAD `b05d3001`) : **15 fichiers de statut M**, tous sous `plugin/cockpit/`. Le détail des changements vient des plans ; les fichiers eux-mêmes sont ceux du relevé, pas ceux du plan.

| # | Fichier existant (statut M) | Plan | Changement | Conflit possible |
|---|------------------|------|------------|------------------|
| B1 | `skills/cockpit-moteur/terminal/vf-cockpit-pty.py` | 72-02 | marqueur `vibeflow:allow-large-file` en ligne 1 (dette tracée) ; ligne de contrôle fd 3 `L <hex>`, réponse fd 2 `LANCE …` ; ajouts seulement | faible (la 71.5 ne le touche pas) |
| B2 | `scripts/vf-cockpit-terminal-session.mjs` | 72-02 | `sessions.lancer(ligne, onglet)` ; le parseur d'état accepte les lignes `LANCE …` ; ajouts seulement | faible |
| B3 | `scripts/vf-cockpit-equipe-carte.mjs` | 72-07 | paramètre optionnel `lancees` de `buildEquipeGraph` ; sortie octet pour octet identique quand il est absent | faible |
| B4 | `scripts/vf-cockpit-terminal-vue.mjs`, `scripts/vf-cockpit-terminal-client.mjs` | 72-08, 72-13, 72-16, correctifs F1 et L2 | bandeau de proposition (classes `vf-q-bandeau`/`vf-q-collage` réutilisées), sondage de `GET /proposition`, émission de la valeur fixe `proposition` vers P, mode servi par Q (72-16), case « continuer le chat » (72-13) ; gardes `document.hasFocus()` (F1, L2) ; client à 279 lignes, plafond LB.S3 280 jamais relevé | **possible** avec la 71.5 : feuille `<style id="vf-lancer-style">` (voir §6), classes du bandeau |
| B5 | `scripts/vf-cockpit-server.mjs` | 72-09 | sept hunks (en-tête de routes, `import { creerLancer }`, `const lancer = creerLancer(…)` après `load()`, branchements `lancer.*` dans le routeur) ; ajouts presque exclusivement | **certain** avec la 78 : fusionner les hunks, jamais l'un par l'autre |
| B6 | `scripts/vf-cockpit-terminal.mjs` | 72-09 | `injection()` concatène `injectionLancer` ; renseigne le canal de lancement ; relais des messages IPC `cibles`, `proposition`, `lancee` | faible |
| B7 | `scripts/vf-cockpit-terminal-processus.mjs` | 72-10, 72-16 | routes `GET /proposition`, `POST /lancer`, `POST /annuler` dans la table fermée, messages IPC ; `GET /proposition` passe par `controle(req, <url de /etat>)` (commit `549d3bcc`), la ligne `navigateur` de la 71 reste intacte ; 72-16 : mémoire du mode, `mode_retenu` servi, écriture après `w.ok` | faible |
| B8 | `scripts/vf-cockpit-terminal-tiroir.mjs`, `scripts/tests/test-cockpit-terminal-tiroir.sh` | 72-14 | valeur fixe `proposition` ajoutée à `LISTE_MESSAGES`, ouverture du tiroir sans prise de focus ; assertions existantes inchangées, ajouts seulement. `vf-cockpit-terminal-tiroir-style.mjs` n'est PAS touché (le plan le prévoyait) | moyen avec la 71.5 : relire la base avant de fusionner |
| B9 | `VERSION`, `module.json`, `CHANGELOG.md`, `README.md`, `skills/vf-cockpit/SKILL.md` (tous sous `plugin/cockpit/`) | 72-15, 72-16 | bump unique au-dessus de v1.3.3, usage de « Lancer », limites (mode hérité, boîte « faire confiance », un seul terminal, travail non commité reporté à la 78) ; paragraphe du mode retenu | **certain** avec la 78 et la 71.5 : ajouter, ne pas réécrire |

Hors du relevé `plugin/` : `README.md` et `README.fr.md` (racine), le seul nombre de la phrase « N suites » — **certain** : recompter après fusion, jamais additionner (non couvert par le diff `-- plugin/`, à contrôler à part).

Non touchés (vérifié : absents du relevé) : `skills/cockpit-moteur/assets/serve.mjs` (vendoré), `scripts/vf-cockpit-build.mjs` (le build copie `vf-cockpit-lancer*.mjs` par le motif `^vf-cockpit-.*\.mjs$`), `scripts/vf-cockpit-interface.json`, `scripts/tests/terminal-aux.mjs`, `scripts/tests/test-cockpit-terminal-xss.sh`, `scripts/vf-cockpit-terminal-style.mjs`, `scripts/vf-cockpit-terminal-tiroir-style.mjs`, tout `assets/ui/`.

## 2. Fichiers neufs (statut A, aucun conflit possible) — re-dérivé à la clôture

**30 fichiers de statut A** sous `plugin/cockpit/` :

- modules `scripts/vf-cockpit-lancer.mjs` et `scripts/vf-cockpit-lancer-{canal,cibles,gabarit,mode,post,q,style,suivi,ui}.mjs` (dix) ;
- suites `scripts/tests/test-cockpit-lancer-{bandeau,bout-en-bout,chat,cibles,gabarit,mode,post,processus,pty,q,serveur,suivi,ui,xss}.sh` (quatorze) ;
- aide et témoins : `scripts/tests/chrome-lancer.mjs`, `scripts/tests/temoins/lancer-charge.js`, `scripts/tests/temoins/lancer-xss.mjs`, `scripts/tests/temoins/lancer-fauxbin/{claude,claude-ask}`, `scripts/tests/temoins/fauxbin-claude/claude` (six).

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

## 6. Points de fusion connus avec la 71.5 (relevé de clôture)

- **`<style id="vf-lancer-style">`** : feuille posée à l'exécution par `vf-cockpit-terminal-vue.mjs` (`poserStyleProposition`) pour le bandeau de proposition. À fondre dans `vf-cockpit-terminal-style.mjs` à la fusion de la 71.5, puis la constante et sa pose sont à retirer de la vue.
- **`var(--sp-8, 8px)` et repères voisins** de `vf-cockpit-lancer-style.mjs` (fichier neuf) : chaque `var(--sp-N, <px>)` porte un repli. Le repli est à retirer quand les jetons d'espacement de la 71.5 sont sur main.
- **Classe `vf-q-attention` (ambre)** : appartient à la 71.5 ; la 72 ne la touche pas (elle l'utilise seulement là où la 71 la posait, dans la vue). Ne pas la redéfinir côté 72 à la fusion.
- **Note sur §5** : les fichiers `test-cockpit-lancer-bandeau.sh` et `test-cockpit-lancer-processus.sh` (ligne B11) sont de statut A dans le relevé final (suites neuves de la 72), non des fichiers existants.
