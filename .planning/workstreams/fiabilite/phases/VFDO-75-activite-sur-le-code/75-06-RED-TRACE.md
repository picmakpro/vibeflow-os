# 75-06 — trace du rouge (régime allégé : pas de mutants)

Base du rouge : `d3ffa525` (75-01 à 75-05, 79-13, 79-15 et 79-21 livrés), suite `plugin/cockpit/scripts/tests/test-cockpit-activite-prevues.sh` posée seule, code de la tâche absent.
Aucun chemin du poste : `<tmp>` pour le dossier temporaire de la suite, `.` pour la racine du dépôt.

## Constat de la base (étape 0)

- Forme d'annotateur livrée par 79-05 : `annotateur(g, ctx)`, synchrone, `ctx = { lab, sortie, project, arch, eng }` (`arch` = `{ extracteur, noeuds }`, PAS le contenu d'`architecture.json` : l'annotateur le relit dans `<sortie>/architecture.json`, écrit par `ecrireArchitecture` juste avant). `project` et le dossier de sortie y figurent : l'hypothèse A4 tient, le plan n'est pas « à revalider ».
- `plugin/cockpit/amont/` est absent (aucun diff de patch). La règle de rattachement est inline dans `skills/cockpit-moteur/scripts/build.mjs` (profondeur, spécificité, `exclude` hérité) ; `graph.json` ne porte pas `exclude`.
- `compileGlob(glob)` à un paramètre, objet `{ glob, specificity, test }`, dans `lib/common.mjs` (79-21 livré).

## Rouge de la base (le test d'abord) — suite complète rejouée sans arrêt au premier échec : 7 PASS, 20 FAIL

Témoins de la tâche 1 (V1 à V4) :

| témoin | attendu | obtenu sur la base | bonne raison |
| --- | --- | --- | --- |
| V1 | `["src/ZMARQ-prevu.mjs","src/nouveau.mjs"]` | `[]` | l'assemblage réel tourne et le graphe ne porte aucune carte prévue : le fichier absent d'un plan non fait est écarté, rien ne le réinjecte |
| V1b | l'élément `{p, n:'d-src', r:'.', l:'prevu', loc:0, name, d:'Créé par le plan 01-01', st:'prevu', prevuPar:['01-01']}` | `illisible` (aucun élément) | même cause |
| V1c | `true,0` (`meta.vfPrevuAt` ISO, `meta.prevusIgnores` 0) | `false,` | `meta` n'a ni l'un ni l'autre |
| V3, V3b, V3c, V3d | équivalence moteur / règle extraite sur 9 fichiers ; répartition `{"a":1,"b":1,"unassigned":4,"wk":2,"zz":1}` ; nœuds des cartes prévues | `absent` | `lib/common.mjs` n'exporte ni `regleDeNoeuds` ni `rattacher`, le module des cartes prévues n'existe pas |
| V4 | `identiques\|2` (stats identiques ET deux cartes prévues dans le graphe complet) | `identiques\|0` | les stats sont identiques (rien n'est injecté), mais le graphe complet ne porte aucune carte : le témoin positif échoue pour la bonne raison |

Verts sur la base, donc témoins de non-régression : V2, V2b (plan fait, fichier du scan, doc présent, fichier ignoré par git mais présent : aucune carte ; le fichier réel reste une carte du moteur), V4b (`scan.json` ne contient aucun prévu, contient un fichier réel).

Preuve que le rouge « module absent » de V3 est le bon : l'état intermédiaire « règle extraite dans `common.mjs`, moteur et annotateur qui l'appellent » rend V3 vert sur 9 fichiers à zéro divergence ; la fixture est discriminante (V3b : l'exclusion héritée envoie `a/b/c/z.js`, `a/b/c/d/deep.js`, `a/t/q.js` et `loose.js` en « non assignés », et `w/k.js`, `w/k2.js` à égalité de spécificité vont au premier déclaré). L'annotateur qui ignorerait l'`exclude` hérité rendrait `c` pour `a/b/c/neuf.js` au lieu de `unassigned` (V3c) : mutant non exécuté (régime allégé), la fixture le tient.

## Rouge de `test-cockpit-routes.sh` après l'ajout de la ligne (A54), AVANT la mise à jour de la liste

Une ligne `['prevues', prevues.annoterPrevues]` ajoutée à `ANNOTATEURS` ; suite rejouée sans arrêt au premier échec : 53 PASS, 3 FAIL.

| témoin | attendu | obtenu | cause |
| --- | --- | --- | --- |
| AN.1 | `descriptions,git,logos,onglet,schema,touche` | `descriptions,git,logos,onglet,prevues,schema,touche` | la liste écrite à la main ne connaît pas le nom neuf (le rouge voulu par A54) |
| AN.4 | `4\|1\|ok dégénéré` | `4\|4\|ok dégénéré` | `meta.vfPrevuAt` change à chaque assemblage : le canon de la suite ne le tenait pas pour volatile |
| M-ANNOT-DEP | `0\|naturel-egal\|inverse-different\|vf-cockpit/graph@1\|floorplan/graph@1` | `0\|\|inverse-different\|illisible\|illisible` | la suite copie les `vf-cockpit-*.mjs` seuls dans un dossier : l'import statique du moteur (`../skills/…`) échouait dans la copie |

Correctifs : `vfPrevuAt` ajouté aux clés volatiles du canon d'`an.mjs` (liste `VOL`), `prevues` ajouté à la liste d'AN.1 entre `onglet` et `schema` ; le module charge le moteur par un import dynamique de tête (`await import(…).catch(() => null)`) et ne dit son absence qu'au moment de rattacher une carte, jamais par un rattachement deviné.

## Après le code (tâche 1)

`test-cockpit-activite-prevues.sh` : 12 PASS, 0 FAIL (`BILAN : 12 PASS, 0 FAIL`). `test-cockpit-routes.sh` : 56 PASS, 0 FAIL. `test-cockpit-onglet-code.sh` : 32 PASS, 0 FAIL. `test-cockpit-assemblage.sh` : 55 PASS. `test-cockpit-moteur-carte.sh` : 73 PASS.
