# 70-10 — mesure de `test-cockpit-responsive.sh` (P70-D-18)

Poste chargé par les autres exécutants de la phase (load average 14 à 18 pendant toutes les mesures) : les durées absolues sont majorées,
le rapport avant / après est mesuré sur le même poste, une seule suite lancée à la fois, `date +%s` autour de la commande.
Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-responsive.sh` (sortie dans `$TMPDIR`). Base : 794c6dba plus les commits voisins du worktree.

## Avant

- Durée : 256 s (le plan annonçait 175 s : même suite, poste plus chargé).
- Résultat : 191 PASS / 0 FAIL, 191 libellés distincts.
- Lancements de Chrome : 14 par `mes` ou `chrome-responsive.mjs` direct (R1/R2 4, R3 2, R4.1 1, R4.2 1, R8 4, R9 2) et 23 par `chrome-cdp.mjs`
  (R5/R6 2, O2 4, O2b 10 plus 3 mutants, I2 2, R7 2) : 37 au total.
- Répartition des secondes (horodatage des lignes `===`) : R1 à R3 : 26 s ; R5/R6 : 9 s ; O2 : 12 s ; **O2b : 175 s** (dix mesures de 8 à 9 s, trois mutants de 29 s) ; I2 à R7 : 34 s.
  Le poste de coût n'était donc pas R1/R2 mais O2b, que le plan de regroupement d'origine ne visait pas.

## Plan de regroupement (révisé par la mesure)

1. O2b : la page attendait `pause(500)` par jeu de segments (3 jeux, deux évaluations par `stable`, deux onglets) et, dans les labs mutants sans agent actif, bouclait 5 s
   sur un badge « au travail » qui ne viendrait jamais. Remplacé par l'état de la page : géométrie identique sur deux images consécutives, et badge rempli (« travail » ou « Personne »).
2. Les mesures indépendantes partent en même temps, un Chrome par mesure (profil jetable distinct, port de débogage 0) : O2b (5 largeurs par lab), les trois mutants O2b, R1/R2/R3 (6), R8 (4), R9 (2).
   Les assertions se lisent ensuite dans l'ordre d'origine, donc mêmes libellés.
3. Aucune fusion entre un Chrome normal et `CHROME_NOPTR` ; aucune tolérance, largeur ni onglet modifiés ; `chrome-responsive.mjs` inchangé (il mesure déjà plusieurs largeurs par lancement).

## Après

- Durée : 74 s (étape intermédiaire, O2b seul rendu concurrent : 125 s).
- Résultat : 191 PASS / 0 FAIL, 191 libellés distincts.
- Lancements de Chrome : 37, inchangés — le gain vient de la concurrence et de la suppression des attentes, pas d'un retrait de mesure.
- Répartition : R1 à R3 : 10 s ; R5/R6 : 9 s ; O2 : 12 s ; O2b : 18 s ; I2 : 4 s ; R4 : 4 s ; R8 : 6 s ; R9 : 3 s ; R7 : 7 s.

## Rapport avant / après

| | avant | après |
|---|---|---|
| durée | 256 s | 74 s |
| libellés | 191 | 191 |
| lancements de Chrome | 37 | 37 |

## Égalité des libellés

`comm -3` entre l'ensemble trié des libellés `PASS` / `FAIL` de l'exécution d'avant et celui de l'exécution d'après : 0 ligne (et 0 pour l'étape intermédiaire à 125 s).
Les libellés sont extraits octet par octet (`LC_ALL=C`, motif `^  (✅ PASS|❌ FAIL) — `), 191 chacun, aucun doublon.

## Mutants

Rejoués dans l'exécution complète d'après, tous verts (donc la mesure rougit comme avant) : R4.1 (sans `01-vf-responsive.js`), R4.2 (borne de 316 px, bouton qui sort à 1 024 px),
R8.0 (Chrome sans pointeur : `pointer: none` confirmé, R8 sur 1 024, 1 280, 1 440 px), O2b.m1, O2b.m2, O2b.m3 ; R9 (texte élargi) passe sur ses deux onglets.
