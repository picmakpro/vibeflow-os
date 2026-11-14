---
phase: 80
plan: "18"
requirements: [FORM-17, FORM-18]
status: executed
---

# 80-18 — assemblage : compteur des README, table du partage CI, CHANGELOG, non-régression

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)

## Livré
- README.md et README.fr.md : compteur 244 -> 257, valeur lue dans la sortie rouge de `check-version-sync.sh` § 9 (`réel=257`, trace dans
  `80-18-RED-TRACE.md`), recoupée par `scripts/ci-shard-suites.sh --all` (257). Gate rejoué : `✓ README.md suites 257`, `✓ README.fr.md suites 257`, exit 0.
- `scripts/ci-shard-suites.sh` : treize suites neuves ajoutées à `durees()` (aide 54, cadrer 33, echec-onglet 27, entete 66, finitions 43, jetons 20,
  lien-vue 39, neutre 37, onglets 54, palette 68, projet-vocabulaire 33, sante-fr 25, zoom-garde 41 secondes), mesures locales macOS du 2026-11-14,
  commentaire daté ; les huit suites du premier segment de la phase y avaient déjà leur ligne ; le glob `540 …/test-cockpit-projet-*.sh` reste en dernier.
  Relevé : `git log --grep='(80-' d487f372..HEAD --diff-filter=A` donne ces treize `test-cockpit-*.sh` ; les autres suites sans ligne de la table
  (coquille, frise, graphe, magasin, mise-en-page, regie, tracabilite-*) viennent des Phases 73, 76 et 79 : non touchées (DEFAUT 7 s).
  `test-ci-shard-suites.sh` 22/0, partition `0 14` rendue.
- `plugin/cockpit/CHANGELOG.md` : sections « Ajouté / Modifié / Retiré / Méthode / Décisions — Phase 80 » posées après « Limites — Phase 79 », dans la section
  `v1.5.0 — non publié` laissée par 79-20 ; aucune ligne existante déplacée ni retirée (0 ligne `-` au diff). Lignes reprises des SUMMARY 80-01 à 80-21
  et neutre, plus la ligne A51 du rapport du nœud. P80-D-01 à P80-D-60 citées une à une ; P80-D-52 à P80-D-56 portent « arbitrage Samuel, AskUserQuestion
  session principale, 2026-11-11 » et le libellé coché ; les autres « décision déléguée par Samuel (message session principale, 2026-11-08), option
  recommandée » ; aucune autre ligne ne cite l'arbitrage du 2026-11-11. Retraits 1 à 4 nommés. Aucun bump : VERSION racine et `plugin/cockpit/VERSION` (v1.5.0) inchangées.

## Écarts
- Écart : précondition du plan (19 plans) corrigée : `depends_on` en compte 20 (80-01 à 80-17, 80-19, 80-20, 80-21), tous faits et tous avec SUMMARY ; deux nœuds
  sans PLAN.md ont aussi livré (passe A51, trace `80-a51-RED-TRACE.md` ; attribut neutre du terminal, `80-neutre-SUMMARY.md`) : leurs lignes sont au CHANGELOG.
- Écart : la table du partage CI du plan (9 lots, durées du run 43408047589) a changé (14 lots, PR #241) : lue à la source dans l'arbre ; 80-04 et 80-05
  y avaient mis des lignes de segment (a) ; seules les treize suites sans ligne ont été ajoutées.
- Écart : le CHANGELOG n'a plus de section `## Non publié` mais `## v1.5.0 — non publié` avec des sous-sections « — Phase 79 » : la Phase 80 suit cette forme
  (sous-sections « — Phase 80 ») au lieu de `### Phase 80 — Trois onglets, trois formes` sous `## Non publié`.
- Écart : l'OK-PERIMETRE complet, les gates rejoués depuis `ci.yml` et les mutants par plan ne sont pas rejoués (régime allégé : le reste, c'est la CI).
- Écart (P80-D-59) : trois fichiers `ui/` portent `vf-coquille: persistant` en tête, pas deux : `00-vf-onglets-echec.js` (80-21, vue d'échec) s'ajoute à
  `00-vf-surcouches.js` et `00-vf-onglets.js` ; `69-vf-flux.js` le porte aussi, mais c'est la 79 (80-16 n'y a replié qu'un commentaire de plus de 160 colonnes).
  À signaler au manager : la règle écrite au plan nommait deux fichiers.
- Écart (P80-D-60) : un commit de la 80 touche `69-vf-flux.js` (08858bb4c, 80-16) : un commentaire replié sur deux lignes, aucun changement de `ROUTES`,
  `ANNOTATEURS` ni de la liste `EVENEMENTS` ; `vf-cockpit-routes.mjs` et `vf-cockpit-build.mjs` : aucun commit de la 80 (le seul commit de la plage est 07d6627f3, 79-22).

## Suites jouées (une fois, sur la tête commitée)
| Suite | Verdict | Secondes |
|---|---|---|
| check-version-sync.sh | exit 0 (suites 257) | — |
| test-cockpit-vendor.sh | 286 PASS / 0 FAIL | 96 |
| test-ci-shard-suites.sh | 22 PASS / 0 FAIL | 3 |
| treize suites neuves (mesure des durées) | rc 0, aucune ligne FAIL ni SAUTÉE | 25 à 68 chacune |

## Carte des suites touchées (existantes modifiées par les commits `(80-`)
Dérivée de `git log --grep='(80-' --diff-filter=M d487f372..HEAD` : `chrome-session.mjs` (naviguer), `chrome-pointeur.mjs`, `chrome-surcouches.mjs`,
`chrome-couloirs-clavier.mjs`, `cockpit-sante/sonde.mjs` (regex ramenées au français, 80-19), `test-cockpit-chrome-fr.sh` (F5.2, F23), `test-cockpit-sante.sh` (S2.3 à S2.5),
`test-cockpit-coquille.sh` (4 lignes, 80-21, Gate-Touche), `test-cockpit-git-tiroir.sh` (D2.1, D7, D8.1, D9.1, 80-06), `test-cockpit-git-entete.sh` (H4.1, 80-20),
`test-cockpit-git-pagination.sh`, `test-cockpit-panneau-retour.sh`, `test-cockpit-projet-liste.sh`, `test-cockpit-couloirs.sh`, `test-cockpit-coin.sh`,
`test-cockpit-surcouches.sh`, `test-cockpit-finitions.sh` (FI2.3, M-OUVREUR), `colonnes-baseline.txt` (baisses seules, 00-vibeflow.js 91 -> 89, aucune hausse).
Justifications : chaque SUMMARY 80-NN ; aucune assertion retirée ni relâchée (80-19 : 34 lignes `assert_eq`/`assert_ne` avant et après).

## Carte des fichiers partagés (P80-D-27)
`viewer.html`, `vf-cockpit-planning.mjs`, `vf-cockpit-project.mjs`, `vf-cockpit-interface.json` (80-03), `40-tour.js`, `05-theme.js`, `76-vf-git-entete.js`, `scripts/lib/health.mjs`
(80-19), `VENDORED.txt` (lignes `AJOUT` à leur place alphabétique), `colonnes-baseline.txt`, suites existantes ci-dessus : toutes modifiées par la 80 sur la tête `cda263753`,
c'est-à-dire APRÈS la fusion de la 79 (point de fusion 85cbb1c5, 79-17 à 79-22) ; le côté commit par commit n'est pas relevé (régime allégé).

## P80-D-26 / P80-C76-6 / P80-D-59
- Aucune route ajoutée par la 80 ; aucune URL absolue `http` ajoutée dans les `ui/` de la phase ; aucun `fetch(` ajouté.
- `.req'` et `'couvre'` : deux lignes seulement, `41-vf-projet-phase.js` l.18 et l.24, corps de `lireExigences`.
- `cle:` : au plus une inscription par fichier `ui/`, égale à son nom (23 fichiers) ; l'autre occurrence trouvée (`h23`) est `hourCycle`, sans rapport.

## Clôture de FORM-18
Cinq points livrés (80-14 : ligne du terminal ; 80-19 : Santé en français ; 80-20 : titre de vue, trois groupes, ouvreur 36/44), suites vertes aux SUMMARY de leur plan
(`test-cockpit-sante-fr.sh`, `test-cockpit-entete.sh` 35/0 et 65 s, FI2.3, H4.1) ; `test-cockpit-entete`, `-sante-fr`, `-finitions` rejouées ici (rc 0).

## Mutants par plan
Non rejoués ici (régime allégé) ; les comptes sont dans les SUMMARY et traces `80-NN-RED-TRACE.md`.

## Ligne de CHANGELOG demandée par 80-18
Posée au CHANGELOG du module (sections « — Phase 80 »).
