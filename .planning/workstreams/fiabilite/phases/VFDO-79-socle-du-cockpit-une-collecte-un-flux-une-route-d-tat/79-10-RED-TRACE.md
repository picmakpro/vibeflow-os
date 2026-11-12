AVANT 954618bdff0f9eb09c21ef97070789b1e9d4f83b

# 79-10 — trace des rouges (plan 79-10, exécution inline)

Mesures faites sur le code de production présent à l'ouverture de la tâche 1 (aucun fichier de production modifié par cette tâche). Le relevé de rendu « avant » est versé dans 79-10-RENDU-AVANT.json (36 états : Code 13, Projet 3, constats de Santé 2, chacun en français et sous `?lang=en`).

## Relevés de base (une ligne par fait, forme `MOT nom valeur`)

```
LIGNES viewer.html 2579
LONGUES viewer.html 284
LIGNES serve.mjs 667
LONGUES serve.mjs 76
LIGNES 05-theme.js 75
LONGUES 05-theme.js 5
LIGNES 10-glossary.js 194
LONGUES 10-glossary.js 18
LIGNES 20-health.js 171
LONGUES 20-health.js 16
LIGNES 25-recent.js 91
LONGUES 25-recent.js 7
LIGNES 30-screens.js 141
LONGUES 30-screens.js 12
LIGNES 40-tour.js 271
LONGUES 40-tour.js 49
LIGNES 60-export.js 84
LONGUES 60-export.js 7
LIGNES 79-vf-fr-dict-b.js 129
LONGUES 79-vf-fr-dict-b.js 45
LIGNES 80-vf-fr.js 176
LONGUES 80-vf-fr.js 38
LIGNES build.mjs 479
LONGUES build.mjs 25
LIGNES vf-cockpit-fr-inventaire.mjs 192
LONGUES vf-cockpit-fr-inventaire.mjs 11
TLOCAUX viewer.html 25
TLOCAUX 10-glossary.js 5
TLOCAUX 25-recent.js 5
TLOCAUX 40-tour.js 4
OBSERVATEURS 80-vf-fr.js 2
EXCLUSIONS 143 (dont mode plan: 55)
ENTREES 78+79 463
INVENTAIRE F1 605
```

`TLOCAUX` : relevé approché par expression régulière (`const|let|var t`, `(t)`, `t =>`) ; la porte de la tâche 2 relève ses « ombres » avec sa propre règle, la trace la rapporte à la tâche 2 (`OMBRES-OUTIL`).

Écarts avec les faits écrits au plan (relevés sur 680364f1) : `LONGUES serve.mjs` 76 (plan 60), `LONGUES 80-vf-fr.js` 38 (plan 32), `LIGNES 80-vf-fr.js` 176 (plan 160) : le commit b16c57fc (restes de AUDC-H4) a ajouté `estDossier`, `dossier`, `DOSSIER`, une branche de `DONNEE` et deux exclusions de `SKIP` ; les bornes du plan sont donc les relevés ci-dessus, pas les nombres du plan.

## Rouges sur le code présent (suite test-cockpit-chrome-fr.sh : 106 PASS / 24 FAIL ; avant les témoins : 97 PASS / 0 FAIL)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-chrome-fr.sh` (sortie complète conservée hors dépôt). Seuls les identifiants F16, F17, F18.1, F19, F20.1, F20.2 et F21.3 échouent ; tout autre identifiant, y compris les 97 d'avant, reste vert.

| Identifiant | Attendu | Obtenu sur le code présent |
|---|---|---|
| F16.0 : inventaireSites est exportée par l'inventaire | `ok` | `absent` |
| F16.1 : clés de t relevées dans le rendu servi (au moins 200, jamais un vert à vide) (0 < 200) | `` | `` |
| F16.2 : toute clé de t, et tout texte du balisage statique, a une entrée de table ou une exclus… | `[]` | `calcul impossible : absent` |
| F16.3 témoin : un t('…') neuf sans entrée est nommé, lui seul | `["Chaîne neuve sans entrée"]` | `["calcul impossible"]` |
| F17.1 : aucun littéral anglais libre, aucune clé non littérale, aucun t local qui masque le tra… | `[]` | `calcul impossible : absent` |
| F17.2 témoin : un littéral anglais ajouté à une copie de la page est nommé, lui seul | `["Pending approval from the review board"]` | `["calcul impossible"]` |
| F17.3 témoin : un t(variable) ajouté à une copie est nommé « clé non littérale » | `["maVariableNeuve"]` | `["calcul impossible"]` |
| F17.4 témoin : un t local qui masque le traducteur (ombre) est nommé, lui seul | `["const t ="]` | `["calcul impossible"]` |
| F18.1 : les blocs vibeflow:fr (78, 79, 80) précèdent le script principal et ui/00-vibeflow.js d… | `3,true,true,false` | `3,false,false,false` |
| F19.1 : __vfFrT est une fonction | `function` | `undefined` |
| F19.2 : clé exacte (« Hello » : « Bonjour ») | `Bonjour` | `absent` |
| F19.3 : variables et formes (« {} call » : 1 appel, 3 appels) | `["1 appel","3 appels"]` | `absent` |
| F19.4 : élision et contraction de « de » devant la variable (d'Anthropic, du CLI) | `["Rien de saillant. C'est un contrôle automatique rapide, pas une revue complète d'Anthropic.","Rien de sailla…` | `absent` |
| F19.5 : @contexte (« Changed@pastille » : Récent) et repli sur la clé sans contexte (Touché) | `["Récent","Touché"]` | `absent` |
| F19.6 : t.pl et t.mot, singulier à 1 | `["1 appel","3 appels","ligne","lignes"]` | `absent` |
| F19.7 : t.k (« 1.3k » : « 1,3 k », espace insécable) | `1,3_k` | `absent` |
| F19.8 : t.type (« Library » : « Bibliothèque », une donnée inconnue : null) | `["Bibliothèque",null]` | `absent` |
| F19.9 : t.constat (forme rendue reconnue, phrase inconnue inchangée) | `["Readme et 7 autres","Une phrase que personne ne connaît"]` | `absent` |
| F19.10 : une clé absente de la table rend la clé, variables remplies | `Un x inconnu` | `absent` |
| F19.11 : sous ?lang=en, la clé remplie, aucune valeur de table lue, t.pl en anglais, t.mot, t.k… | `["Hello","3 call","Changed","3 calls","1 call","lines","1.3k","Readme and 7 more",null,"undefined","Un x incon…` | `absent` |
| F19.12 : sur la vraie table (« Fit to screen », File par onglet, une donnée, un constat reconnu… | `` | `attendu: [["Ajuster à l'écran","Fichier","Élément","Ma phrase de données",null,"src.js contient util.js"]] ⏎      obtenu:  [absent] ⏎ [F3] témoin du détecteur :…` |
| F20.1 : le code de 80-vf-fr.js (commentaires exclus) ne construit aucun observateur de mutation… | `0` | `2` |
| F20.2 : un « Health » posé dans le panneau (hors des anciens sélecteurs listés) reste « Health … | `Health` | `Santé` |
| F21.3 témoin : avec la ligne de garde « // garde:lang-en » neutralisée, les sondes anglaises li… | `Ajuster à l'écran (F)` | `mutation impossible : ancre absente` |

Raisons : F16.0 à F16.3 et F17.1 à F17.4 rougissent parce que `inventaireSites` n'existe pas encore (le test le dit : « calcul impossible », jamais une liste vide) ; F16.1 dit 0 clé relevée sur 200 attendues ; F18.1 : les trois blocs `// vibeflow:fr` sont posés après le script principal (`3,false,false,false`) ; F19.1 à F19.12 : `window.__vfFrT` n'existe pas (« absent ») ; F20.1 : 2 constructions d'observateur dans `80-vf-fr.js` ; F20.2 : le `span` « Health » du panneau est réécrit en « Santé » par l'observateur ; F21.3 : l'ancre `// garde:lang-en` n'existe pas encore, la copie ne peut pas être mutée (le rouge vient de l'ancre absente, pas d'un comportement).

Les verts de contrôle sont des témoins de non-régression, dits comme tels : F18.2 (un gabarit sans l'emplacement garde l'ancien ordre : vrai aujourd'hui, la capacité de rougir sera prouvée à la tâche 2 par la suppression du repli de `build.mjs` dans une copie), F20.3 (une copie portant un observateur générique est lue réécrite : la sonde sait voir la réécriture), F21.1 et F21.2 (sondes en français et sous `?lang=en` : vertes parce que `80-vf-fr.js` sort avant de rien poser sous `?lang=en` ; mutant F21.3 à la tâche 6), F23.1 à F23.4 (constats de Santé : l'observateur les traduit aujourd'hui).

## Mutant M-RETRAIT-SEUL (A43)

Commande : `VF_FR_F23_MUTANT=retrait bash plugin/cockpit/scripts/tests/test-cockpit-chrome-fr.sh` : la suite rejoue F23 sur une copie de la page de fixture où les deux constructions d'observateur du bloc 80 sont remplacées par un talon inerte ET où les deux écouteurs de rendu du moteur (`SC.on?.('panel', zones)`, `SC.on?.('render', zones)`) sont retirés.

Résultat : 26 FAIL au lieu de 24 ; les deux de plus sont :

- F23.1 : constat de Santé — le détail « X contains … » s'affiche « X contient … » (valeur du relevé avant) : attendu `src.js contient util.js`, obtenu `src.js contains util.js`
- F23.3 : constat de Santé — localisations coupées à trois, « +3 autres » (valeur du relevé avant) : attendu `src/a.js:3 ⏎ src/b.js ⏎ src/c.js:9 ⏎ +3 autres`, obtenu `src/a.js:3 ⏎ src/b.js ⏎ src/c.js:9 ⏎ +3 more`

MUTANT M-RETRAIT-SEUL F23.1,F23.3 sans observateur ni écouteur de rendu du moteur, le détail du constat reste « src.js contains util.js » et la localisation « +3 more » : retirer l'ancien mécanisme sans rien faire pour les constats change leur rendu (A43), c'est la raison du rouge.

Amendement 2026-11-12 (exécution, fait inattendu) : le plan prévoyait qu'ôter « l'observateur seul » fasse rougir F23. Mesuré : avec les seuls observateurs remplacés par un talon inerte, F23 reste VERT, parce que les deux écouteurs de rendu du moteur (`panel` et `render`) rappellent `fix` sur le panneau et le contexte à chaque ouverture de panneau. Le mutant M-RETRAIT-SEUL retire donc les observateurs ET ces écouteurs, c'est-à-dire tout ce qui applique `fix` au DOM après le chargement ; ce que la tâche 6 retire.

Amendement 2026-11-12 (exécution, hypothèse fausse du plan) : le plan et la mission placent le titre et la question du tableau « Montrer sur la carte » parmi les champs que l'observateur traduit aujourd'hui, à garder par `t.constat`. Mesuré sur le code présent : titre (`#panel .pt`) et question (`#panel .pd`) y sont des données du panneau (SKIP et DONNEE, lot 0 de l'audit, AUDC-H4) et ne sont JAMAIS réécrits : le tableau montre « Anyone could change data through util.js » et « src.js contains util.js ». A43 exige que le rendu des constats de Santé ne change pas : `t.constat` ne s'applique donc PAS aux deux champs passés à `showBoard` (F23.4 le fixe, valeurs du relevé avant). `t.constat` s'applique au titre, au détail et à la note de `issueHtml` seulement.

## Panneaux que le relevé n'atteint pas

Le lab de la suite ne permet pas d'atteindre : la visite guidée au-delà de sa première étape, l'écran des écrans détectés (`30-screens.js`), le travail récent (`25-recent.js`, aucune donnée de travail récent dans le lab), le glossaire sur une description riche, le tiroir de questions à l'agent, le détail d'un parcours en lecture. Ces extensions ne sont couvertes que par la porte statique (F16, F17) et par les sondes de leurs propres suites (moteur-carte, accessibilité, responsive, équipe).

## Écarts de rendu admis (lignes `ECART-ADMIS <page-mode>/<état> <texte exact>`)

Parité mesurée sur 36 états (Code 13, Projet 3, constats de Santé 2 ; français et `?lang=en`) entre le code d'avant (e553d3a5, relevé versé) et le code après le plan. Les 31 écarts ci-dessous sont les seuls, tous des corrections, aucune régression : de l'anglais que l'ancien mécanisme laissait à l'écran parce qu'il le jugeait donnée du lab (description du panneau, ligne de liste, texte de repli) est maintenant traduit là où il naît (« Contrôle automatique rapide des… », « Aucun problème trouvé », « 2 points à traiter », « , ou ouvrir cette carte dans l'application Claude. », « 1 mineur », « Rien d'urgent », le paragraphe d'introduction de la Santé), et le pluriel « 1 étapes » / « 1 steps » devient « 1 étape » / « 1 step » (`t.pl` : un pluriel construit à la main dans le viewer, `${n} steps`, disparaît). Aucun écart sur un constat de Santé produit à l'assemblage (titre, détail, localisations : F23).

ECART-ADMIS code-fr/accueil , or open this map in the Claude app.
ECART-ADMIS code-fr/accueil 1 minor
ECART-ADMIS code-fr/accueil Nothing urgent
ECART-ADMIS code-fr/accueil , ou ouvrir cette carte dans l'application Claude.
ECART-ADMIS code-fr/accueil 1 mineur
ECART-ADMIS code-fr/accueil Rien d'urgent
ECART-ADMIS code-fr/sante 1 mineur
ECART-ADMIS code-fr/sante We looked for keys left in the code or sent to the browser, data and parts of your app anyone on the internet can reach, leftover files and files too big to edit safely. It’s a quick check, not a security audit.
ECART-ADMIS code-fr/sante Nous avons cherché les clés laissées dans le code ou envoyées au navigateur, les données et les éléments de votre application accessibles à n'importe qui sur internet, les fichiers oubliés et les fichiers trop gros pour être modifiés sans risque. C'est un contrôle rapide, pas un audit de sécurité.
ECART-ADMIS projet-fr/accueil , open
ECART-ADMIS projet-fr/accueil , or open this map in the Claude app.
ECART-ADMIS projet-fr/accueil 1 étapes · Les phases du jalon en cours, dans l'ordre.
ECART-ADMIS projet-fr/accueil No problems found
ECART-ADMIS projet-fr/accueil Quick automatic check of
ECART-ADMIS projet-fr/accueil and leftover files
ECART-ADMIS projet-fr/accueil endpoints
ECART-ADMIS projet-fr/accueil , des points d'accès ouverts et des fichiers oubliés
ECART-ADMIS projet-fr/accueil , ou ouvrir cette carte dans l'application Claude.
ECART-ADMIS projet-fr/accueil 1 étape · Les phases du jalon en cours, dans l'ordre.
ECART-ADMIS projet-fr/accueil Aucun problème trouvé
ECART-ADMIS projet-fr/accueil Contrôle automatique rapide des
ECART-ADMIS projet-fr/sante We looked for keys left in the code or sent to the browser, data and parts of your app anyone on the internet can reach, leftover files and files too big to edit safely. It’s a quick check, not a security audit.
ECART-ADMIS projet-fr/sante Nous avons cherché les clés laissées dans le code ou envoyées au navigateur, les données et les éléments de votre application accessibles à n'importe qui sur internet, les fichiers oubliés et les fichiers trop gros pour être modifiés sans risque. C'est un contrôle rapide, pas un audit de sécurité.
ECART-ADMIS projet-en/accueil 1 steps · Les phases du jalon en cours, dans l'ordre.
ECART-ADMIS projet-en/accueil 1 step · Les phases du jalon en cours, dans l'ordre.
ECART-ADMIS sante-fr/constats , or open this map in the Claude app.
ECART-ADMIS sante-fr/constats 2 things need attention
ECART-ADMIS sante-fr/constats We looked for keys left in the code or sent to the browser, data and parts of your app anyone on the internet can reach, leftover files and files too big to edit safely. It’s a quick check, not a security audit.
ECART-ADMIS sante-fr/constats , ou ouvrir cette carte dans l'application Claude.
ECART-ADMIS sante-fr/constats 2 points à traiter
ECART-ADMIS sante-fr/constats Nous avons cherché les clés laissées dans le code ou envoyées au navigateur, les données et les éléments de votre application accessibles à n'importe qui sur internet, les fichiers oubliés et les fichiers trop gros pour être modifiés sans risque. C'est un contrôle rapide, pas un audit de sécurité.

## Les 19 motifs R : disposition finale (tous restent en service pour t.constat et __vfFrTraduire, A43)

MOTIF-R 1 sous-titre « Jalon … · phase … · statut » : sans émetteur dans le moteur (le statut est écrit en français à la source par le module projet)
MOTIF-R 2 « {} thing(s) » : 20-health.js, t.pl(total, 'thing') ; clé « {} thing » ajoutée
MOTIF-R 3 « Answer · {} card(s) » : viewer (en-tête de la vue), fragments « Answer » et « {} card » (t.pl) ; clé « {} card » ajoutée
MOTIF-R 4 « Ask anything about {}… » : viewer (champ de question, trois sites) ; clés « Ask anything about {}… » et du texte statique ajoutées
MOTIF-R 5 « {} map » : viewer, titre du document, t('{} map', nom), valeur « {} » ; clé ajoutée
MOTIF-R 6 « Searching the map for "{}" » : viewer (progression de l'outil) par t ; serve.mjs en français à la source ; clé ajoutée
MOTIF-R 7 « Searching code for "{}" » : serve.mjs en français à la source ; aucun émetteur dans la page
MOTIF-R 8 « Looking at {} » : viewer par t (clé ajoutée) ; serve.mjs en français à la source
MOTIF-R 9 « Reading {} » : serve.mjs en français à la source ; aucun émetteur dans la page
MOTIF-R 10 « Listing {} » : serve.mjs en français à la source ; aucun émetteur dans la page
MOTIF-R 11 « Running a command » : serve.mjs en français à la source ; aucun émetteur dans la page
MOTIF-R 12 « Tracing a dependency path » : viewer par t ; clé ajoutée
MOTIF-R 13 « … and N more » : viewer et 40-tour.js, « and {} more » et « and 1 more » ; clé « and 1 more » ajoutée
MOTIF-R 14 date d'en-tête d'export : viewer, toLocaleDateString(t.langue) dans t('Exported {}', date)
MOTIF-R 15 « (+{} more) » : serve.mjs (lignes de progression), écrit « (+N autres) » à la source ; aucun émetteur dans la page
MOTIF-R 16 « +{} more » : viewer, 20-health.js, t('+{} more', n)
MOTIF-R 17 « {} card(s) » et « {} file(s) » : viewer par plural (alias de t.pl) ; clés « {} card » et « {} file » (surcharge par onglet)
MOTIF-R 18 « {} file(s) » par onglet : surcharge Fichier/Élément lue aussi par les gabarits (« {} file », « files »)
MOTIF-R 19 « Theme: {}. Press for {}. » : 05-theme.js, t('Theme: {}. Press for {}.', …) ; clé ajoutée

## Entrées de table sans site d'émission (51, non supprimées)
SANS-SITE Less
SANS-SITE More
SANS-SITE Theme
SANS-SITE , because {}
SANS-SITE , matched from call sites to route definitions
SANS-SITE , opened in your project folder.
SANS-SITE , planned from {}
SANS-SITE A change is still being made.
SANS-SITE Backspace
SANS-SITE Enter
SANS-SITE Escape
SANS-SITE Everything behind
SANS-SITE The screen itself
SANS-SITE Failed to fetch
SANS-SITE Nothing stood out. This is a quick automatic check, not a full {} review.
SANS-SITE Nothing to undo.
SANS-SITE Pick one and choose
SANS-SITE Searching code
SANS-SITE The map’s server couldn’t export it. The details are in its output.
SANS-SITE This map is too old to export. Ask Claude or Codex to update the vf-cockpit first.
SANS-SITE This map’s server can’t find the VibeFlow scripts. Ask Claude Code or Codex to update the vf-cockpit once, then try again.
SANS-SITE Tracing a path {}
SANS-SITE Who may use it
SANS-SITE across {}
SANS-SITE at the top.{}
SANS-SITE for {}{}
SANS-SITE this part
SANS-SITE to start on it.
SANS-SITE worth fixing
SANS-SITE {} · step {} of {}
SANS-SITE {}Press Play to follow it through the code, one step at a time.
SANS-SITE {}Walk through {} steps
SANS-SITE {}{} with {}
SANS-SITE it explains the choice and updates the plan once you decide
SANS-SITE from
SANS-SITE {} of {}
SANS-SITE {} problems
SANS-SITE {} steps
SANS-SITE {} steps{}
SANS-SITE Unassigned
SANS-SITE Files no node claims. Add globs in architecture.json to place them.
SANS-SITE API client
SANS-SITE API key
SANS-SITE API keys
SANS-SITE HTTP methods
SANS-SITE MCP server
SANS-SITE ORM model
SANS-SITE ORM models
SANS-SITE Claude Code and GSD
SANS-SITE important
SANS-SITE minor
## Relevé sans chemin du poste (amendement)

Prise : `chrome-fr-etats.mjs` écarte les textes réduits à un fragment « dossier/ » et remplace master/main par BRANCHE avant l'écriture. Contrôle : `node 79-10-CONTROLE-CHEMINS.mjs 79-10-RENDU-AVANT.json` OK ; témoin rouge : relevé + « Users/ » donne ROUGE (code 1).
