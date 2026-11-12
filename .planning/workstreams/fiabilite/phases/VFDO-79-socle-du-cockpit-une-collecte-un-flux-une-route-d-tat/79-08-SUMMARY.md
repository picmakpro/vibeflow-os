# 79-08 — SUMMARY : index incrémental des transcripts (SOCL-12)

Statut : exécuté. Commits : 42fb4ac6 (mesure de forme), 1528a2c9 (amendement daté), 500c16eb (témoins rouges I0-I2, I5, I8), 209c50aa (modules et contrat), 004c3914 (correctif trouvé par la propriété), d780aaa4 (propriété, couverture, mutants), 2ac7458d (fichier hostile, fuzz, balayage, F17), puis le commit du compteur de suites des README racine.

## Signatures exportées
- `vf-cockpit-jetons.mjs` : `jetonsVides`, `contexteDe`, `plierMessage`.
- `vf-cockpit-index-voie.mjs` : `BORNES`, `CONTRAT`, `lire`, `formeRequise`, `voieNeuve`, `inconnue`, `plierLigne`, `publique`, `enCours` (`depuisMs` est l'instant, en ms, de l'appel ouvert, non une durée : l'horloge n'entre pas dans un module pur).
- `vf-cockpit-index-cache.mjs` : `FICHIER_INDEX`, `SCHEMA_INDEX`, `indexVide`, `validerIndex`, `chargerIndex`, `ecrireIndex`.
- `vf-cockpit-index.mjs` : `FENETRE_S`, `enumerer`, `mettreAJour`, `construire`, `bilan`. Aucun module d'extraction ajouté (tous sous 150 lignes).
- Contrat : schéma `vibeflow/cockpit-index@1` (inséré après `cockpit-transcript@2`), bloc `claudeCode.index` (après `transcriptSousAgent`), `vueAgents.description` réécrit (AUDC-Q4), `verifieSur` 2.1.322 (`79-08-MESURE-FORME.md`). Le bloc `vibeflow/cockpit-project@1` est intact (contrôle machine rejoué : intact, zéro ligne `"statuts"` au diff).
- Traces : `79-08-RED-TRACE.md`. Graines jouées : 1, 2, 3 plus une graine fraîche imprimée par la suite (`VF_SEED` pour la rejouer). Couverture (graine 1) : chaque classe de coupe observée au moins 14 fois. Suite `test-cockpit-index.sh` : 109 assertions, environ 70 s ; `test-cockpit-forme-claude.sh` : 76.

## Écarts, amendements et décisions
- Amendement 1528a2c9 (décision déléguée par Samuel, message session principale, 2026-11-08, option recommandée ; prise par la session principale le 2026-11-11, dite à Samuel le même jour, révisable par lui) : critère de contiguïté resserré aux lignes `assistant` (mesure : 0 cas ; 13,7 % d'intercalations `user`). Ajouts : témoin I2.12 et mutant M-CLOS ; une alternance A, B, A passe la voie en forme inconnue (les 256 derniers identifiants clos sont gardés au curseur ; limite : une réapparition au-delà de 256 messages n'est pas vue).
- Déviations d'ordre : les tâches 1 et 2 ont leur code écrit d'un bloc (pas de rouge « règle manquante » sur un code minimal) ; la validation complète du fichier et le contrat étendu sont posés avec les modules (I6, P3, I7 sans rouge sur le code) ; leur capacité à rougir est tenue par les mutants et témoins (voir la trace).
- `candidats[].meta` est un accesseur paresseux (lecture du `meta.json` à la demande, pour les seules voies conservées).
- Bornes déclarées au contrat (`schemas["vibeflow/cockpit-index@1"].bornes`) ; ancêtres : une voie hors fenêtre n'est jamais créée seulement parce qu'elle est ancêtre (elle est gardée si elle existe déjà).
- La mesure de forme a montré `stop_reason` chaîne sur chaque ligne (la fixture du plan le mettait nul) : sans effet sur R7.
- Limites : les voies du lab sont jugées par `arbreDe` fourni par l'appelant (preuve `cockpit-git-worktrees@1` : plan 79-09) ; un transcript sans ligne datée n'est pas indexé (retenté à chaque tour) ; le fichier d'index n'est ni servi ni exporté (A25 : témoin d'export au plan 79-15).

## À documenter par 79-20
Les quatre modules, le schéma `cockpit-index@1`, le bloc `claudeCode.index`, la version revérifiée 2.1.322, le chapitre F17, la propriété d'incrémentalité (graine, `VF_SEED`) et les mutants ; aucune édition du CHANGELOG, du README, de VERSION ni de module.json du module cockpit dans ce plan.

## Correction après revue (rv1)
- Constat majeur (axe Spec, sécurité) : sans `arbreDe`, `mettreAJour` tenait tout transcript pour un transcript du lab. Correctif : `arbreDe` obligatoire, appel refusé (`TypeError`) sans lui ; amendement daté d'une ligne au plan (écart 12). Témoin rouge I2.8e (commit de test précédent le correctif), mutant M-ARBREDE (seul I2.8e rougit). Suite d'index 111 PASS, forme 76 PASS.
- Effet de bord corrigé : le générateur tire davantage de lignes géantes (une graine fraîche avait fait tomber la couverture de `ligne-geante` sous 8 : rouge de couverture, pas de l'index).
- Traçabilité : les décisions citées sans canal ni date dans les messages de commit de ce plan (P79-D-03, P79-D-13, P79-D-30 et les lignes « décision déléguée par Samuel … 2026-11-08, option recommandée » de certains commits) sont des décisions du cadrage de la phase ; elles ne sont pas de Samuel. L'historique n'est pas réécrit.
