# 74-01 — SUMMARY : calculs et modèle de la frise

## Livré
- `ui/74-vf-frise-calculs.js` (185 lignes) : `window.__vfFriseCalculs` = etatA, noeudsPortes, etages, agreger, delta, voiesAutour, fichiersA, commitsParBranche, couverture, fmtJetons, fmtDuree, fmtHeure, fmtNombre. Chargé en premier.
- `ui/74-vf-frise-modele.js` (243 lignes) : `window.__vfFriseModele` = SCHEMA, CHAMPS_LUS, FENETRES, SEUIL_REPLI, SILENCE_MS, lire, omises, arbre, replier, projection, coalescer, courbe, voiesTronquees + les calculs.
- `tests/test-cockpit-frise-modele.sh` (F0 à F15, FMT) et `tests/frise-fabrique.mjs` (fixtures `cockpit-frise@1`, missions, fil, git, en mémoire, sans horloge ni hasard).
- Trace du rouge : `74-01-RED-TRACE.md`.

## Contrat exporté consommé par une autre phase (agrégat de coût, plan 77-07)
- `agreger(voies, par, { missions, phases, fenetreLibelle, tronque })`, `par` dans `'agent'|'mission'|'etage'`, `voies` = voies normalisées par `lire`.
- Retour : `{ lignes, horsMission, total, inconnus, incomplet, fenetreDurees, fenetreJetons }` ; ligne `{ cle, libelle, travailS, attenteHumainS, entree, sortie, cacheLu, cacheCree, enfants? , phases? }` ; `horsMission` et `total` : mêmes six colonnes.
- Précision : `total` = somme de TOUTES les voies ; `horsMission` = sous-total des voies sans `rattachement.dag`. En `'mission'` : Σ lignes + horsMission = total ; en `'agent'` et `'etage'` les lignes couvrent toutes les voies (Σ lignes = total, horsMission en sous-total informatif).

## Écarts
- Écart : précondition « P74-D-56 / OK-PRECONDITION-79 » non jouée, remplacée par les prérequis réels plan par plan (consigne du mandat) ; le calcul tourne sur fixtures.
- Écart levé à la reprise (après 79-13) : F10 (b) est écrite et verte (CHAMPS_LUS contre le bloc `vibeflow/cockpit-frise@1` de `vf-cockpit-interface.json` et la liste blanche de `vf-cockpit-frise-voie.mjs`) ; plus aucun `⊘`. À rendre bloquante au plan 74-09 : elle l'est déjà (rouge si le bloc manque).
- Écart : confrontation à la route livrée. `at` est une chaîne ISO (fixture et `lire` corrigés : `frise.at` en millisecondes) ; la route fusionne la queue `attend-humain` au dernier segment quand il l'est déjà (sonde F7 ajoutée, `etatA` inchangé) et ne la pose que pour un agent `attend`. Les autres champs concordent (durees, jetons, rattachement, cibles.tronque, voiesOmises, `arbre`/`cibles` nuls, segments et évènements en tableaux). Dépend encore de 79-22 : rien (le modèle ne lit jamais le fil).
- Écart : la suite ne lance aucun serveur, donc pas d'hygiène de processus (`hygiene.sh`) ; elle tourne sous `TZ=Europe/Paris` (F6b) et se rejoue sur un dossier vide (F0, contrôle positif).
- Écart : les commandes `<automated>` des tâches n'ont pas été rejouées sous bash et zsh sur sorties factices (régime allégé) ; remplacées par le contrôle positif F0 de la suite.
- Écart : forme de la voie normalisée par `lire` : `segments[] = { debut, fin, genre }`, `evenements[] = { t, genre }` (la route écrit des tableaux).
- Écart : `fmtHeure(ms, { secondes, phrase })` : l'option `phrase` rend « 14 h 32 » (espace insécable devant `h`) ; `fmtDuree` met l'espace insécable devant `h`, pas entre `h` et les minutes (« 2 h 05 »).
- Écart : `replier` replie les managers du plus peuplé au moins peuplé et s'arrête dès que le nombre de voies visibles est au plus égal au seuil (tout ou rien par manager).
- Écart : `fichiersA` : seule une entrée regroupée (`n > 1`) couvre jusqu'à l'élément suivant du fil ; une entrée simple est un instant. Une cible de fil « chemin (worktree nom) » devient `{ arbre: nom, cible: chemin }`.

## Rituels levés
- rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale) — pas de mutants M-* (plan non marqué audit), pas de relecteur, pas de triple passe.

## Suites jouées (tête commitée de la reprise, après 79-13)
| Suite | Verdict | Secondes |
|---|---|---|
| `test-cockpit-frise-modele.sh` | exit 0, 146 PASS, 0 FAIL, aucun `⊘` | < 1 |
| `check-file-size.sh` (deux modules et la fabrique) | exit 0, aucun avertissement | < 1 |

Tailles : aucun fichier au-delà de 299 lignes, aucune ligne au-delà de 160 colonnes ; aucun symbole monétaire, aucun accès réseau, aucune lecture de la consommation brute (F10 a).
