---
phase: 67-cockpit-floorplan-socle-partage
plan: 07
status: complete-avec-reserve
requirements: [CKPT-09]
commits: [e3e86895, bae638a6]
actuals:
  tasks: 2
---

# 67-07 SUMMARY — chrome en français

Exécution inline. Tâches 1 (tracer) et 2 (couverture) dans un seul commit de code (e3e86895) : l'inventaire, le dictionnaire et la suite se réglaient ensemble sur le rendu réel. Commit de documentation et de recette : bae638a6.

**Statut : recette humaine NON faite** — préparée dans `67-RECETTE-HUMAINE.md` (commandes pour l'arbre réel, un lab jetable et un lab quelconque ; tableau de réponses vide). Aucun point n'est coché ni inféré ; la réponse de Samuel, avec son canal et sa date, reste à consigner.

## Mesures (rendu servi d'un lab neutre assemblé)
- Inventaire : **563 chaînes** (repère du spike 006 : 258 ; le périmètre est plus large : extensions, glossaire, gabarits HTML, messages de `serve.mjs`).
- Dictionnaire : **399 entrées** (dont **66 gabarits** à `{}`), **16 motifs**, **142 exclusions** : 14 identiques dans les deux langues, 14 noms de produit ou de technologie, 4 noms d'outils de l'agent, 55 du mode plan (blueprint) inatteignable (F7 : aucun graphe servi ne porte `meta.blueprint`), 6 textes envoyés à l'agent, 30 alias de repérage du glossaire, 10 classes CSS ou commandes, 8 formes collées à une icône, 1 nom de commande. Chaque exclusion a sa raison dans `vf-cockpit-fr-exclusions.json` ; F4 vérifie qu'elle a un objet.
- `test-cockpit-chrome-fr.sh` : `Résultats : 24 PASS / 0 FAIL` (141 lignes). `synchro.sh verifier` 0 (les fichiers 78, 79, 80 et 00 sont des AJOUTS : aucun patch du viewer).
- Contrôle visuel (playwright, Chromium, arbre réel, 1 440 px) : onglet **Projet** sans aucun anglais après ouverture de Santé, « Par où commencer », Exporter, Parcours, filtres, recherche et panneau, et clic sur six cartes ; seules des données du lab (noms, résumés) restent anglaises. Onglet **Code** : idem pour le chrome, sauf la réserve ci-dessous.

## Mutants (sortie rouge)
### entrée du dictionnaire retirée (`"Copy endpoint"` de 78)
```
  ❌ FAIL — F2 : non traduits = vide (563 chaînes, 142 exclusions)
     obtenu:  [["Copy endpoint"]]
```
### nom amont dans une valeur du dictionnaire source (79)
```
  ❌ FAIL — F5.2 : sources 78 et 79 du dictionnaire sans le nom amont (insensible à la casse)
     obtenu:  [1]
```
(le rendu est renommé à l'assemblage : la valeur fautive y deviendrait « vf-cockpit », donc F5.2 cherche dans les SOURCES.)
### garde « chaîne vide → rien » retirée de `__vfFrTraduire`
Resté **vert** : le reste de la fonction (`T['']`, motifs, segments) rend déjà `null` sur une chaîne vide ; la garde est redondante et F6.4 est un témoin de comportement, pas un test discriminant par mutation. Le mutant utile de la boucle du spike 006 (clé `''` dans le dictionnaire) est couvert par F5 (valeur = clé).
Témoins internes de la suite : F3 (chaîne anglaise inventée ajoutée au rendu, listée), F2 témoin (ligne retirée d'une copie, nommée), F4 témoin (exclusion inventée et exclusion sans raison, signalées), F5 témoin (4 problèmes), F6.8 (un gabarit court n'abîme pas une donnée).

## Écarts au plan
- Schéma des exclusions inchangé (`{ texte, raison }`, version 1) ; les chaînes composées à l'exécution (pluriels) sont traitées par une règle de la fonction pure (« files » → singulier du dictionnaire + « s »), pas par l'inventaire statique, qui ne les voit pas : trouvées au contrôle visuel, pas par F2.
- Mécanismes ajoutés à `80-vf-fr.js` (hors dictionnaire) : clés à `{}` (gabarits ; texte fixe < 16 caractères appliqué seulement si une variable est un nombre ou se traduit elle-même, sinon « Top of the world » serait abîmé), valeur « singulier|pluriel », traduction des variables capturées, segments ` · ` et `: `, et traduction du panneau et du contexte **avant** le glossaire (écouteurs `panel`/`render` synchrones) : sans cela le glossaire morcelait le texte anglais avant traduction.
- Statuts de STATE : `closed` → `clos` (le plan écrit « close », lu comme l'adjectif français), `complete`/`completed` → `terminée`, etc. ; valeur inconnue affichée telle quelle.
- L'inventaire écarte : la zone de données du lab, les blocs `// vibeflow:fr` et `// VibeFlow (` (déjà en français), le bloc des requêtes sur le graphe (descriptions d'outils pour l'agent), la bibliothèque de mise en page vendorisée, toute ligne de journal console.
- Limite des heuristiques de `estAnglais` (écrites en tête du module) : un identifiant d'un seul mot en minuscules hors nœud de texte HTML n'est jamais inventorié.

## Réserve ouverte (décision à prendre)
Sur l'onglet **Code**, le panneau « Santé » et la note de couverture affichent des textes **anglais produits à l'assemblage** par `scripts/lib/health.mjs` et `build.mjs` (titres et détails d'alertes : « 2 files are very large », « Files no node claims… », explications Supabase/Firebase/Stripe…). Ce sont des données du graphe, hors du périmètre du plan (viewer, extensions, messages du serveur) : le test ne les voit pas. Les traduire demande de dictionnariser une centaine de gabarits composés (`health.mjs`, 1 146 lignes) ou de masquer le panneau sur l'onglet Code. **À trancher par Samuel avant de déclarer CKPT-09 tenu au sens « zéro anglais visible »** ; l'onglet Projet n'est pas concerné.

STATE.md identique à la baseline.
