AVANT 1f4197ced9bd5c4dbe49747c3f53bd9a7363974f

# 79-07 — trace des rouges (plan 79-07, exécution inline)

Mesures faites sur le code de production présent (aucun fichier de production modifié par la tâche 1). Graine par défaut de G16 : 4217, 300 arbres à dossier git simple + 150 à dossier git et commun distincts.

## Tâche 1 — rouges sur le code présent (suite test-cockpit-git-config-depot.sh : 47 PASS / 20 FAIL)

Couverture G16.0 (verte) : 450 arbres, 1402 liens ; forme dedans / noyau dehors ou non résolu 105, forme dehors / noyau dedans 16, non résolus 55, entièrement dedans 86, realpath JS différent du natif 150. Témoin rouge G16.2 (vert) : le modèle de la règle lexicale trouve des contre-preuves. Témoin d'oracle G16.3 (vert) : zéro désaccord entre le realpath natif et l'inode atteint par le noyau.

| Identifiant | Attendu | Obtenu sur le code présent |
|---|---|---|
| G16.1 (graine=4217) | `ok` (aucune contre-preuve) | contre-preuve arbre 51, disposition simple : liens `.git/d/a/l0 -> l0` (boucle), `.git/l1 -> <lab/.git/d/a>` ; attendu sortant=true, obtenu false (la forme écrite reste dans le dossier git) |
| G17.1 | `function` | `undefined` (cheminPhysique n'existe pas) |
| G17.2, G17.3, G17.4 | `ok` | tous les cas en échec : fonction absente |
| G18.2 | `true,true,true,true,true` | `false,false,false,false,false` : un lien pendant de forme quelconque dont la cible écrite reste dans le dossier git est permis |
| G18.3 | `true` | `false` : gitdir d'un gitfile à maillon divergent jugé dedans |
| G18.4 | `true` | `false` : inclusion à maillon divergent jugée dedans |
| A8, A9, A10 | `0` occurrence du marqueur | `4` chacun : le contenu lié (configuration du dossier git, fichier de .cache, fichier ignoré) sort dans les pages |
| A12 | `0` | `4` : le lien à maillon divergent est admis, le fichier extérieur est lu |
| A13 | `ok=oui ext=0` | `ok=oui ext=1` : le DAG extérieur alimente l'équipe |
| A14 | `refuse:4\|refuse:4` | `passe\|passe` : verifierSortie et confiner admettent une sortie liée hors du lab |
| B5.1 | `refuse` | `verifie` : gitfile de worktree forgé accepté |
| D6.1 | marqueurs `absentabsentabsentabsent`, aucun refus à tort | `poséabsentabsentposé` : `log -p -1 --textconv` lance le textconv (TC) et le filtre (FL) |
| D6.2 | les sept clés de pilotes vides | `false` : seuls les filtres des sous-commandes filtrantes sont vidés, jamais pour rev-parse |
| D6.3 | aucun GIT_* hérité, GIT_CONFIG_COUNT posé, `.git` | hérités : GIT_AUTHOR_*, GIT_COMMITTER_*, GIT_CONFIG_GLOBAL, GIT_CONFIG_NOSYSTEM, GIT_DIR, GIT_INDEX_FILE, GIT_WORK_TREE ; GIT_CONFIG_COUNT absent ; rev-parse rend le dépôt leurre |
| D6.4 | tout refusé, liste = 14 noms, MG et ALIAS absents, dépôt inchangé | `refus=false liste=illisible marques=poséposé depot=modifié` |
| D6.5 | `1\|false\|true\|2` | `0\|false\|false\|0` : aucune lecture mémorisée (aucune lecture du tout pour rev-parse) |

Témoins verts : G16.0, G16.2, G16.3, G18.1, G18.5, A11, A14b, B5.2, D6.0 (git brut exécute textconv, commande de diff, les deux emplois à argument tardif, pilote de fusion, alias).

Observations d'exécution (aucun amendement) :
- Le plan prévoit que `diff HEAD~1 --ext-diff` lance la commande de diff sur le code présent (D6.1). Mesuré par lancerGit : le marqueur CMD n'est PAS posé (le durcissement `diff.external` inerte est prioritaire en pratique) ; D6.1 est rouge par `log -p -1 --textconv` (TC et FL posés). Sans effet sur la suite : l'attendu après la tâche 5 reste « aucun marqueur ».
- Le plan cite deux fois « chemin non absolu » parmi les refus du mode plusProcheParent (tâche 1, comportement G17.3) alors que la section Interface exportée dit qu'un chemin relatif est pris au dossier courant par concaténation. Suivi : la section Interface (G17.4 teste `.` = dossier courant natif) ; le mode plusProcheParent ne refuse donc pas un chemin relatif.
- Générateur G16 : en plus des formes du plan (marche, traversée de lien, absolu dans le dossier git 8 %, extérieur 4 %, absent 2 %), 3 % de liens bouclés (cible = son propre nom) : sans eux la couverture « non résolus >= 20 » n'était tenue que par hasard sur certaines graines (mesuré : 18 sur la graine par défaut sans boucles).

## Tâche 2 — extraction du module de lancement (aucun changement de comportement)

Les rouges de la tâche 1 sont inchangés après l'extraction (mêmes 20 identifiants, aucun nouveau). `vf-cockpit-paths.mjs` descend de 296 à 157 lignes (166 après la tâche 3), `vf-cockpit-git-lanceur.mjs` en compte 152, `child_process` n'est plus importé par paths.mjs, `execFile(cmd` n'apparaît qu'une fois, dans le module neuf. Suites jouées seules après l'extraction : test-cockpit-git-env.sh, -vendor.sh, -confinement.sh, -signal.sh, -path-enfants.sh, -avancement.sh, -assemblage.sh vertes.
Mesure de contrôle : test-cockpit-securite.sh (FB3.5, délai de 10 s du cas génératif) et test-cockpit-git-details.sh (X6.2, ordre de service sous charge) rougissent aussi sur un instantané du commit des témoins (avant toute modification de production), sous une charge machine de 25 à 40 : rouges de charge, rejoués seuls, non imputables au plan (X6.2 est revenue verte aux rejeux suivants).

## Tâche 3 — état vert et mutants

Suite test-cockpit-git-config-depot.sh après la tâche 3 : seuls A8, A9, A10, A12 (tâche 4) et D6.1 à D6.5 (tâche 5) échouent ; G16.0 à G16.3, G17.1 à G17.4, G18.1 à G18.5, A11, A13, A14, A14b, B5.1, B5.2, D6.0 sont verts. Générateur : 450 arbres, 1402 liens, 1,7 à 4 s hors charge (12 s mesurés sous charge 30). Graine rejouée : `VF_G16_GRAINE=424242` vert (G16.0 et G16.1), graine par défaut 4217.

| Mutant (une ancre, copie du module) | Assertion rougie | Attendu | Obtenu (graine 4217) |
|---|---|---|---|
| M-LEXICAL (la règle de jugement d'un lien redevient lexicale) | G16.1 | 0 désaccord | 19 contre-preuves ; première : arbre 51, liens `.git/d/a/l0 -> l0`, `.git/l1 -> <lab/.git/d/a>`, attendu sortant, obtenu non sortant |
| M-JS (realpath JS à la place du natif) | G16.1 | 0 désaccord | 3 contre-preuves ; première : arbre 211, liens `.git/b/a/d/l0 -> ..`, `.git/b/p0 -> a/d`, `.git/b/a/q0 -> ../p0/../../..`, attendu non sortant, obtenu sortant (le realpath JS replie `..`) |
| M-JS | G17.2 | 0 échec | 178 échecs sur 1402 liens |
| M-JS | A13 / A14 / B5.1 | `ok=oui ext=0` / `refuse:4\|refuse:4` / `refuse` | `ok=oui ext=1` / `passe\|passe` / `verifie` |
| M-REPLI (un échec rend le chemin écrit) | G16.1 | 0 désaccord | 16 contre-preuves ; première : arbre 51 (le lien bouclé n'est plus sortant) |
| M-REPLI | G17.2 | 0 échec | 1402 échecs : un lien non résolu rend sa forme écrite |
| M-VERROU (toute cible sans barre oblique tolérée sous le verrou) | G18.2 | `true,true,true,true,true` | `true,true,true,true,false` (le lien DRIVER.lock de cible d'une autre forme est toléré) |

Chaque mutant garde ses témoins positifs verts (dépôt ordinaire lu, oracles concordants, sortie ordinaire A14b, vrai worktree B5.2, forme exacte du verrou).

Amendement daté (voir le plan, commit séparé) : les ancres de mutation de `worktreeVerifie` employées par X7 de test-cockpit-git-details.sh (M-RETOUR, M-PERE, M-PRINCIPAL) manquaient à la liste du plan ; premier jet de la tâche 3 : 8 échecs X7 de test-cockpit-git-details.sh (ancres absentes, mutants sans effet) ; corrigé en gardant `reelOuNull` (alias de `cheminPhysique`) et les lignes d'ancre à l'identique.
