# 80-14 : trace du rouge (P80-D-25)

Base : l'arbre à la tête avant ce plan (`git archive HEAD` du module, rejeu par `PA_SCRIPTS`), suite et pilote de ce plan.
Résultat sur la base : 6 PASS / 19 FAIL. Toutes les sections du pilote (`pa1`, `pa2`, `pa3`) échouent : la palette n'a ni action, ni onglet, ni rôle ARIA.

Rouges attendus (tous constatés) :
- PA1.1 : « >git » ne rend aucune rangée (`j.pa1.lignes` vide) ; PA1.2 : la boîte n'a ni `role=dialog`, ni combobox, ni listbox.
- PA2.1, PA2.1b : le champ vide ne montre que les entités (« src »), aucune des huit actions ni onglet ; PA2.2, PA2.2b : pas de pastille « Actions », pas de « Basculer ».
- PA2.3 (copie du lien), PA2.4 (question), PA2.5 (onglets), PA2.6 (focus) : aucune action n'existe, la section n'a rien mesuré.
- PA2.8 : « terminal » ne rend aucune rangée ; PA2.8t : même constat avec `--terminal`.
- PA3.1, PA3.1b, PA3.2 : ni « Phases » ni « Agents » ; PA3.3 : pas d'état vide en deux lignes ni de région d'annonce ; PA3.4 : aucune rangée d'action à mesurer ; PA3.5 : les deux fichiers sont absents (404).

Verts à vide sur la base, déclarés (ils n'ont pas de témoin rouge) : PA2.7 (aucun mot anglais : le texte est vide), PA2.8b (la ligne du terminal n'est pas
parmi les huit usuelles : il n'y a aucune usuelle), PA0, PA0t, PA9t, H0. PA2.8b et PA2.7 prennent leur sens une fois PA2.1 et PA2.8 verts.

## Correction ciblée de revue (M3, M4, mineurs)

Rouge de M3 (PA4.1) sur la tête d'avant la correction (module `git archive` de 77d2d8a74, section `pa4` seule) : `ajouter({ id, onglets, libelle, action, palette: true })` sans `touche`
est refusé sans message (`ajoutees` = [false, false], `erreurs` = 0) ; `{ …, visible: true }` est accepté, puis `sourceActions` lève et tout le groupe Actions disparaît.
Après correction : `ajoutees` = [true, true], 3 `console.error` (visible ignoré, libellé manquant, onglets invalides), actions natives présentes, retrait effectif, `autre` = 0 après deux allers-retours (PA4.2).

M4 (PA4.3), mutant à la main sur une copie du module : `h()` retiré de `it.libelle` et `it.detail` dans `rowSource` de `viewer.html` : la section rend `img` = 3 (trois balises `<img>` dans `#results`), `texte` = 0 :
PA4.3 rougit (attendu `img` = 0, `texte` >= 3). Sans mutant : `img` = 0, `texte` = 3, `window.__p` indéfini. Le fichier du dépôt n'est pas touché (copie sous le dossier de travail).
