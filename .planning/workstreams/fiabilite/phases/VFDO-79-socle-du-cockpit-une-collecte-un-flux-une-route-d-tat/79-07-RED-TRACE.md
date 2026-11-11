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

## Point d'arrêt après la tâche 3

`AVANT` : voir la première ligne de cette trace. Commits `(79-07)` de la session, dans l'ordre : `6c6a8479` (témoins rouges), `0180f45c` (extraction du lanceur), `199d725b` (règle physique), `d99b396a` (ancres de worktreeVerifie), `b17f5510` (amendement daté du plan), `d4db658e` (mutants de la règle physique) ; le commit de cette rubrique suit.

Suites vertes, jouées seules : test-cockpit-git-env.sh, -vendor.sh, -confinement.sh, -git-details.sh, -avancement.sh, -terminal-serveur.sh, -signal.sh, -path-enfants.sh, -assemblage.sh. Contrôles de la tâche 3 : OK-REGLE-PHYSIQUE (aucun échec hors A8, A9, A10, A12, D6.1 à D6.5 ; 19 identifiants de la règle verts ; 17 assertions de mutants vertes ; copies du module identiques ; aucun appel du realpath JS ni de la résolution lexicale dans le module partagé ; module de 150 lignes), OK-GRAINE-REJOUABLE (graine 424242), OK-NON-REGRESSION-SOCLE.
Rouge de charge, hors plan : test-cockpit-securite.sh FB3.5 (délai de 10 s du cas génératif), rouge aussi sur un instantané antérieur au plan.

Ensemble exact des rouges attendus dans test-cockpit-git-config-depot.sh : A8, A9, A10, A12 (tâche 4, scan.mjs) et D6.1, D6.2, D6.3, D6.4, D6.5 (tâche 5, pilotes nommés) ; tout le reste est vert.
Mutants M-LEXICAL, M-JS, M-REPLI et M-VERROU : causes, attendus, obtenus et graine (4217) dans la section « Tâche 3 » ci-dessus.
Amendement du plan : les ancres de mutation de worktreeVerifie (X7), voir le plan, commit `b17f5510`.
Interface de 79-13 : `cheminPhysique(chemin, { plusProcheParent = false } = {})` existe, exportée de vf-cockpit-git-sortant.mjs, copie octet pour octet dans le moteur, figée par G17.

État : porte non levée. Un constat de l'audit de sécurité intermédiaire (obligatoire, amendement de la porte) est à obtenir avant la tâche 4 ; la reprise est une décision de la session principale. L'arbre est partiellement rouge par construction (A8, A9, A10, A12, D6.1 à D6.5) : ne pas fusionner ici.

## Reprise après le point d'arrêt de la tâche 3

Reprise autorisée par la session principale, décision déléguée par Samuel (AskUserQuestion session principale, 2026-11-11, « Claude, sur preuves (Recommandé) »). Levée le 2026-11-12 à 00 h 11, réponse « reprendre tâche 4 ».

Contrôles de la session principale, recopiés :
- trace lue (rubrique du point d'arrêt) ; AVANT 1f4197ce est un ancêtre de la tête ; 7 commits (79-07) ;
- fichiers touchés hors files_modified : 79-07-PLAN.md seul (amendement daté b17f5510) ;
- rapport de l'auditeur lu dans son propre transcript : passed, aucun constat haut ;
- rejeu indépendant sur une copie détachée à bca33d4b, retirée depuis : git-config-depot 75 PASS / 9 FAIL, exactement A8, A9, A10, A12, D6.1 à D6.5 ; 19 identifiants de la règle, 17 assertions de mutants ; copies du module identiques ; 0 realpathSync(, 0 path.resolve(, 1 export de cheminPhysique ; git-sortant 150 lignes, paths 166 ; graine 424242 conforme ; git-env 134 / 0 ; git-details 136 / 0 ; confinement 66 / 0. Avancement et terminal-serveur non rejouées par elle (le rejeu de l'exécuteur fait foi).

## Tâche 4 — le scan juge un lien comme sa cible (D-M15)

`scan.mjs` : `rootReal` et la résolution d'un lien passent par `cheminPhysique` ; un lien n'est lu que si sa cible physique est sous la racine réelle du lab et est un fichier retenu par la marche (liste git ou marche : ni dossier git, ni sortie du cockpit et son `.cache`, ni fichier ignoré). Plus aucun `realpathSync(` dans le fichier (2 avant).

Suite test-cockpit-git-config-depot.sh après la tâche 4 : 85 PASS / 5 FAIL, les cinq étant D6.1 à D6.5 (tâche 5). A8, A9, A10, A11, A12 verts. Suites rejouées seules, vertes : assemblage 49/0, git-env 134/0, securite 92/0, vendor 87/0, confinement 66/0.

| Mutant du moteur (copie de scan.mjs, assemblage depuis l'arbre muté sur une copie du lab des liens) | Effet | Attendu | Obtenu |
|---|---|---|---|
| M-MEMBRE (le lien n'est plus jugé que sur « sa cible est dans le lab ») | A8, A9, A10 rougissent ; A12 reste verte | `cfg=4 cac=4 ign=4 ext=0` | `cfg=4 cac=4 ign=4 ext=0` (marqueurs présents dans les pages : le contenu lié sort) |
| M-JS-SCAN (la résolution du lien redevient le realpath JS, qui replie `..`) | A12 rougit ; A8, A9, A10 restent verts | `cfg=0 cac=0 ign=0 ext=4` | `cfg=0 cac=0 ign=0 ext=4` (le fichier extérieur sort) |

Chacun garde A11 vert (fichier normal, lien interne vers un fichier listé, leurre intérieur décrits). Le « 4 » est le nombre d'occurrences du marqueur dans les quatre pages.

Correction de la suite (sans effet sur un verdict de production) : la ligne de D6.4 portait `.sorlk_t()` au lieu de `.sort()` (renommage de variable fautif des tâches 1 à 3) ; corrigée dans le commit des mutants.

## Tâche 5 — pilotes nommés vidés pour tout lancement, liste fermée, enfants shell sous envGit

`vf-cockpit-git-durci.mjs` exporte `SOUS_COMMANDES_AUTORISEES` (14 noms) et `PILOTES_NOMMES` ; le lanceur lit une fois les pilotes (une commande `config --name-only --get-regexp`), vide toutes les unités (`filter.<nom>` : quatre clés ; `diff.<nom>.textconv`, `diff.<nom>.command`, `merge.<nom>.driver` : une clé) pour toute sous-commande, refuse hors liste fermée, mémorise la lecture `PILOTES_TTL_MS` (2000 ms, jamais pour une liste illisible), lance les enfants non git sous `envGit(lab)`. `SOUS_COMMANDES_FILTRANTES` n'existe plus dans `plugin/cockpit` ; `envEnfant(lab)` : 0 occurrence dans le lanceur.

test-cockpit-git-config-depot.sh : 103 PASS / 0 FAIL (D6.1 à D6.5 verts, D7.0 témoin non muté conforme).

| Mutant (copie du lanceur, une ancre) | D6.1, D6.2, D6.3, D6.4, D6.5 | Lecture |
|---|---|---|
| M-PORTEE (vidage limité à status, diff, ls-files, stash) | r, r, v, v, r | D6.2 rouge comme prévu ; D6.1 (log -p) et D6.5 (lecture après la fenêtre) rougissent aussi |
| M-FILTRES-SEULS (seuls les filtres sont lus) | r, r, v, v, r | D6.1 et D6.2 rouges comme prévu ; D6.5 rouge aussi (pilote de diff tardif non vidé) |
| M-LISTE (plus de refus hors liste) | v, v, v, r, v | D6.4 seul |
| M-BASH (enfants non git sous envEnfant seul) | v, v, r, v, v | D6.3 seul |
| M-MEMO (mémo sans expiration) | v, v, v, v, r | D6.5 seul |
| M-OPTIONS (OPTIONS_LECTURE retirées seules) | v, v, v, v, v | VERT, redondance voulue : le vidage ferme seul (deux protections indépendantes) |

Écart au plan, mesuré (amendement daté du 2026-11-12 dans le plan) : M-OPTIONS était rouge sur D6.1 avec la sonde d'origine : sans options de lecture, `log -p`, `show` et `diff` sortent en code 128 (pilotes vidés) avec une sortie vide, lue à tort comme un refus de shBorne. La sonde ne compte plus un refus de shBorne que si lancerGit a réussi sur la même ligne.

Suites de l'environnement durci, rejouées seules : test-cockpit-git-env.sh 135 / 0 (E9.5b et E9.6a récrites au sens neuf : toute sous-commande refusée au-delà de la borne ou si la liste est illisible ; E9.6b témoin positif ; M-LECTURE devient le mutant double options retirées ET vidage retiré, chacune retirée seule laisse E2.4 et E5.2 verts), test-cockpit-git-signature.sh 45 / 0 (R2.2c : la sous-commande `config` de la lecture des pilotes est admise).

### Les douze suites qui nomment vf-cockpit-paths.mjs, après reciblage (chacune jouée seule)

Liste relevée par `rtk proxy grep -l 'vf-cockpit-paths.mjs'` sur les suites du module : assemblage 49/0, avancement 69/0, confinement 66/0, git-config-depot 103/0, git-env 135/0, git 118/0, lancer-cibles 51/0, path-enfants 37/0, securite 92/0, signal 76/0, terminal-lanceur 111/0, vendor 87/0. En plus : git-details 136/0, who 157/0, git-signature 45/0.

Preuve mécanique qu'aucun mutant ni aucune ancre ne vise dans paths.mjs un texte qui n'y est plus : `grep -nE '(paths|git-sortant)(\.mjs)?'` filtré sur les lignes de mutation (mutant, mutsub, sed -i, FROM=, muter) de ces suites ne rend que (a) test-cockpit-avancement.sh l.484 (ancre de `st.isFile() && st.size <= 4096 …`, présente 1 fois dans paths.mjs), (b) des mutants de git-sortant.mjs (git-config-depot, git-details), dont le texte n'a pas été déplacé ; les mutants gitnomnu et whonomnu de test-cockpit-terminal-lanceur.sh visaient `timeout: Math.floor(reste), env, maxBuffer })` (0 occurrence dans paths.mjs, 1 dans le lanceur) : reciblés sur le lanceur, ils rougissent de nouveau (assertions « gitnomnu — le mutant (nom nu) exécute le leurre « git » du lab » et « whonomnu — … », passées sous la forme « rouge détecté »). Les assertions `.0` d'existence d'ancre de chaque suite, toutes vertes, couvrent le reste.
