# 75-04 — trace du rouge (régime allégé)

Base du rouge : `f9e6fabd` (Phases 79, 80 et 76-04 dans la branche), suite `plugin/cockpit/scripts/tests/test-cockpit-activite-planning.sh` posée seule, code de la tâche absent.

## Constat

- (a) `files_modified` est lu dans `vf-cockpit-project.mjs`, fonction `addPhase`, variable `touched` (`list(meta.files_modified)`, base l. 137), puis posé sur chaque carte de plan par `file({ … touched, vague })`. `list()` coupe la valeur d'une seule ligne : une liste en BLOC (`files_modified:` puis des lignes `  - x`, forme des vrais plans) était lue vide.
- (b) `instantane().projet` porte le champ : `etapePlanning` (`vf-cockpit-collecte-etapes.mjs`) rend `buildProjectGraph(racine)` tel quel, donc `projet.files[].touched` y survit sans lecture propre (A32).
- (c) La vague est posée par la Phase 80 : `readPlanning` rend `ph.plans[].vague` (`vf-cockpit-planning.mjs`, bloc « P80-D-44 »), la projection la lit (`vagues`, `vague: vagues.get(pf)`). Ce plan ne la touche pas.

## Rouge de la base (le test d'abord)

Suite rejouée sans arrêt au premier échec (copie locale de la suite, `exit` retiré) : 8 PASS, 6 FAIL.

| témoin | attendu | obtenu sur la base | bonne raison |
| --- | --- | --- | --- |
| T2 liste en bloc | `["bloc/a.mjs","bloc/b.mjs","bloc/c.mjs"]` | `[]` | `fm()` ne lit que la valeur de la ligne de la clé : la liste en bloc est perdue |
| T2b CRLF, liste en bloc | `["crlf/a.mjs","crlf/b.mjs"]` | `[]` | même cause |
| T3 5 000 chemins | `200\|4800` | `5000\|undefined` | aucune borne, aucun compteur |
| T3b chemin de 5 000 octets | `[["ok.mjs"],1]` | les deux chemins gardés (dont celui de 5 000 octets), `touchedIgnores` absent | aucune borne d'octets |
| T4 plan sans `files_modified` | 0 champ | 1 (`touched: []` posé à vide) | champ posé sur tout plan |
| T4b `files_modified: []` | 0 champ | 1 | même cause |

Verts sur la base, donc témoins de non-régression : T1, T1b, T1c (le champ ET la vague arrivent déjà à l'instantané), T2c, T2d (listes en ligne), T4c, T5, T5b (contrat inchangé).

Écart de la trace avec le plan : T1 n'est pas rouge sur la base (le champ n'est pas perdu entre `buildProjectGraph` et l'instantané) ; les rouges sont T2/T2b/T3/T3b/T4/T4b.

## Après le code

14 PASS, 0 FAIL (`BILAN : 14 PASS, 0 FAIL`).

## Changements de comportement assumés

- Borne : au plus 200 chemins par plan, 4 096 octets par chemin ; l'excédent est compté dans `touchedIgnores`. Les consommateurs de `touched` relus : `vf-cockpit-ask.mjs` (index inverse fichier → plans, `f.touched || []`) et `vf-cockpit-build.mjs` (`f.touched || []`, `x.touched`) tolèrent l'absence du champ et une liste plus courte ; un plan hors norme (> 200 chemins) n'y apparaît plus pour ses chemins au-delà du 200e.
- Les plans en liste en bloc, jusqu'ici lus vides, portent maintenant leurs chemins (le pied de carte « N fichiers » et la note « Fichiers touchés » apparaissent pour eux).
- Un plan sans `files_modified` (ou à liste vide) n'a plus `touched: []` : le champ est absent.
- Limite du lecteur de frontmatter partagé (`vf-cockpit-frontmatter.mjs`, P76-D-24) : un bloc de plus de 400 lignes n'est pas lu (rendu comme absent), sans compteur.
