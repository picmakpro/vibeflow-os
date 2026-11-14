# 74-06 : SUMMARY (curseur de relecture, encart « À cet instant », fichiers à t, « Voir sur la carte »)

rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)

## Livré
- `ui/74-vf-frise-curseur.js` (repère `role=slider` « Curseur de la frise », trait plein, pose au clavier, au pointeur, au toucher ; Échap en capture sur le document), `-encart.js` (voies,
  nœuds portés, fichiers, bouton), `-fichiers.js` (lecture sous plafond), `-carte.js` (`voirSurLaCarte`, `finirRelecture`). `tests/test-cockpit-frise-curseur.sh` (C1 à C12, C6b, C8f, C8c).
  Trace du rouge : `74-06-RED-TRACE.md`. Chaque module s'inscrit par `surOnglet` avec sa `cle` (nom de fichier avec extension) ; aucun marqué `vf-coquille: persistant`.
- Chemin pris pour ouvrir Code : `VF_ONGLETS.aller('code')` (80-10), repli `VF_COQUILLE.chargerOnglet('code')` (C8c). Pose : `VF_MARQUES.poser('relecture', rangées, { exclusif: true })`, rangées
  `['f:<chemin>', null, 'relecture', 'relu', titre]` pour les fichiers de l'arbre principal seulement ; canal absent : `VF_MARQUES_EN_ATTENTE` ; reprises (10 x 100 ms) si le canal n'est pas encore ouvert.
- `finirRelecture` : `VF_MARQUES.retirer('relecture')`, appelée au retrait du curseur (Échap, Fin, → au bord, sortie de fenêtre) et au nettoyage du curseur au départ de l'onglet.
- Forme réelle d'`arbre` : celle des `cibles.ecritures` de la route de frise (`arbre` nul ou nom de worktree, jamais analysée) ; dans le fil réduit : suffixe `<chemin> (worktree <nom>)` lu par `fichiersA` de 74-01 (déjà posé).

## Écarts
- Écart : décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée ; prise par la session principale le 2026-11-13 ; amende l'arrangement de P74-D-47 (le rebranchement de "Voir sur la carte" passe de 75-07 à 74-06).
  Conséquences : aucun `showBoard`, aucun C8b, aucun repli `sessionStorage` (la clé de repli tombe avec le mécanisme provisoire), C8 lit `VF_MARQUES.active()` et `lire('f:<chemin>')` sur le canal réel.
- Précondition 79 (P74-D-56 / OK-PRECONDITION-79) remplacée par les prérequis réels, non jouée.
- Pas de lecture `GET /api/vf/frise?champs=cibles` : la route livrée l'ignore et les voies lues par 74-04 portent déjà `cibles` (`fichiersA` s'en sert) ; une lecture de plus n'apporterait rien.
- `__vfFrise.voirSurLaCarte` et `finirRelecture` sont posées dans le rappel d'arrivée de `surOnglet`, pas au chargement : `74-vf-frise.js` se charge après les modules `74-vf-frise-*` (le « - » précède le « . ») et réassigne l'objet.
- Les fichiers d'un worktree figurent dans la liste et dans l'appel `voirSurLaCarte` mais ne marquent aucune carte (le canal ne connaît que les ids `f:<chemin>` du lab).
- Fichiers « Début » : le curseur posé à `depuis` sort de la fenêtre dès la prochaine relecture directe (comportement voulu de la sortie par la gauche).
- Mutants : plan non marqué audit, aucun mutant joué (rituel levé). `{ cle }` : pas de sonde sur « inscription rejouée remplace la précédente » (contrat de la coquille, 79).
- Sondes vertes sur la base (voir la trace) : quatre, sans valeur de témoin, gardées pour leur sens une fois les modules posés.
- Pas de contrôle visuel par capture : seules les sondes mesurées de la suite (tailles 44 x 44, trait plein, couleur du repère de survol).

## Contrat consommé par d'autres phases
- Phase 75 : le point d'appel est désormais DANS 74-06 ; la 75 ne rebranche plus rien (75-07 n'a plus de ligne à remplacer dans `74-vf-frise-carte.js`). Les fichiers sont posés dans la couche exclusive `relecture`.
- 74-09 : lignes `AJOUT` de `VENDORED.txt` et inscription au partage de `ci-shard-suites.sh` pour les quatre modules et `test-cockpit-frise-curseur.sh` (posées à part par la session principale).

## Suites jouées (tête commitée `9161b39f`, une fois chacune)
| Suite | Verdict | Secondes |
|---|---|---|
| test-cockpit-frise-curseur.sh | 70 réussis, 0 échec | 61 |
| test-cockpit-frise-vue.sh | 102 réussis, 0 échec | 150 |

Tailles : quatre modules de 59 à 179 lignes, aucune ligne de plus de 160 caractères, `css-jetons.mjs` nul sur les quatre.
