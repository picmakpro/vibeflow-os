# 75-10 — SUMMARY : non-régression et documentation de la phase (ACTV-12)

Rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale). Mutants tenus : ceux de la chaîne XSS (garde) et les deux de la suite sans git.
Le point de contrôle humain est levé : P75-Q-06 tranchée, P75-D-32 (voir 75-CONTEXT.md).

## Livré

- `test-cockpit-chaine-xss.sh` : volet « activité » (C0a à C4a, Q1.2), 49 PASS (33 avant), 0 FAIL, 133 s. Fichier, branche (worktree), plan prévu : vraie route d'un lab piégé ; rôle et description d'agent hostiles : tuples ajoutés à la route par l'amorce de la page.
- `test-cockpit-activite-sans-git.sh` (+ `chrome-activite-sans-git.mjs`) : 18 PASS, 2 MUTANT-ROUGE, 130 s.
- `DESIGN.md` : neuf amendements ; CHANGELOG du module (« Non publié », sans bump), README du module ; compteur des README recompté par le gate (245 -> 247) ; table des durées de `ci-shard-suites.sh` (carte 118 s, lentilles 182 s, sans-git 130 s ; `test-cockpit-activite-carte.sh` et `-lentilles.sh` n'y étaient pas).
- Grep d'inventaire du retrait : zéro ligne.

## Écarts

- Écart : un agent réel du lab piégé n'est « vivant » qu'avec un état officiel de `claude agents --json` que l'essai n'a pas obtenu (le faux claude n'a pas été pris) ; le rôle et la description hostiles passent donc par une route amorcée dans la page. La route réelle porte la branche, le fichier prévu et les collisions.
- Écart : le nom accessible de la carte est vérifié sur son début (`<img`), non sur la charge entière.
- Écart : un lab hors dépôt rend `gardes.etat = indisponible` (la ligne Gardes est désactivée) : la suite sans git l'écrit tel quel. À trancher : la spec dit Gardes « présente », elle l'est.
- Écart avec la spec livrée dans `DESIGN.md` : barres des paliers écartées de 2, tige du confluent à 13,5, contour pointillé de la carte prévue en `outline` (pas en bordure compensée), glyphe inconnu en carré creux ; le goût reste à la recette de Samuel.
- Écart : C6.1 de `test-cockpit-coquille.sh` reste ROUGE sur la tête : vert avant 75-07 (`3a80d45e`, 114 PASS), rouge après (attendu [aucune], obtenu [ids] : `lens-d-chauds` et `lens-d-couplage` manquent après le changement d'onglet). Cause : ce sont les descriptions des lignes DÉSACTIVÉES tant que la route lit git ; le chargement à froid est pris sur un serveur jeune, la suite d'onglets une fois git lu : le document dépend de l'âge du serveur, pas d'un défaut de démontage de `ui/75-vf-*`. Un correctif de la suite (chargements à froid de C6.1 repris une fois la route lue) fait passer C6.1 mais rougit M-ECOUTEURS et M-HEAD (`balises,…`, y compris joués seuls) : retiré, suite rendue à son état d'avant (commit de retour). À reprendre avec la Phase 79 (propriétaire de ces mutants).
- Écart : le rouge « route absente » sur la base `bba9aecde` n'a pas été rejoué (voir la trace).

## Suites jouées

Têtes commitées : `test-cockpit-chaine-xss.sh` vert (49 PASS, 133 s) ; `test-cockpit-activite-sans-git.sh` vert (18 PASS, 2 MUTANT-ROUGE, 130 s) ; `test-cockpit-vendor.sh` vert (253 PASS, 70 s) ; `check-version-sync.sh` vert (247) ; `check-machine-paths.sh` vert ; cliquet de colonnes OK ; `scripts/tests/test-ci-shard-suites.sh` vert (22) ; `test-cockpit-coquille.sh` : C6.1 rouge (voir plus haut), M-ECOUTEURS et M-HEAD verts à l'état d'avant.

## Findings pour le manager

- Release : relecture adverse SOBR-04 du diff `plugin/` avant tout tag de la release qui portera la phase.
- `ci-shard-suites.sh` : inscrit ici avec `Gate-Touche`.
