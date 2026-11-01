---
spike: 006
idea: cockpit-code-projet
name: types-et-chrome-fr
type: comparison
validates: "Given le cockpit floorplan (onglets Code et Projet), when on donne aux cartes Projet des types dédiés (jalon, phase, exigences, mission…) et qu'on traduit le chrome du viewer, then les cartes portent leur pictogramme, leur couleur et leur libellé en français, l'interface ne montre plus d'anglais visible, sans réécrire le viewer ni ralentir le rendu"
verdict: VALIDATED
related: [002-cockpit-code-projet, 005-questions-onglet-projet]
tags: [cockpit, floorplan, i18n, types, ui]
---

# Spike 006 : types dédiés et interface en français

## Ce qu'on valide

Limites laissées par le spike 002 :
- les cartes Projet empruntent des types pensés pour du code (`service`, `feature`, `data`…),
  avec leurs pictogrammes et leurs libellés (« Service ») ;
- tout le chrome du viewer est en anglais. Le spike 005 l'a rendu encore plus visible : tableau
  de réponse, progression de l'agent.

Given le cockpit, when on donne des types dédiés et qu'on traduit, then plus d'anglais visible et
des types lisibles, sans réécrire le viewer (exigence de l'idée) ni le ralentir.

## Recherche : comment le viewer nomme et dessine un type

- Le type d'une carte (`node.kind`) choisit trois choses :
  - le pictogramme : `icon(k)` lit `P[k]` et retombe sur `P.file` ;
  - la couleur : `var(--n-<kind>)` ;
  - le libellé : le nom du type lui-même, mis en capitale (« Phase ») dans le panneau et
    l'en-tête de contexte.

  **Un type nommé en français s'affiche donc en français sans rien traduire.** Seul `P` est
  enfermé dans le script.
- Le seul type qui change le comportement est `external` : une carte de ce type ne s'ouvre pas.
  Aucun type Projet ne l'utilise plus.
- Les extensions `assets/ui/*.js` s'exécutent avant le premier rendu (rendu après
  `fontsReady`).
- Le viewer et ses extensions contiennent **258 chaînes d'interface anglaises** (inventaire par
  regex sur les littéraux). Aucun mécanisme d'i18n : `lang="en"`, chaînes en dur dans le code et
  les gabarits.

| Approche | Pour | Contre | Statut |
|---|---|---|---|
| A. Patcher chaque chaîne du viewer | traduction exacte | plus de 150 sites dans 175 Ko de copie figée, à reporter à chaque synchro amont | écartée |
| B. Remplacement au build sur le source | aucun code en page | touche du JS par motif textuel, fragile, mêmes reports | écartée |
| **C. Traduction en page** : dictionnaire de phrases exactes + motifs, `MutationObserver` | viewer intact, une extension | un passage par frame de mutation | **retenue** |
| Types : renommer les types et fournir leurs pictogrammes | libellé gratuit, une ligne de patch (P8) | — | **retenue** |

## Lancer

```bash
node .planning/spikes/002-cockpit-code-projet/build-cockpit.mjs <root>
node <root>/floorplan/serve.mjs --no-open
# http://127.0.0.1:4378/project.html (français) · ?lang=en pour comparer · / pour l'onglet Code
```

## Ce qui a été construit

- `vf-types.mjs` : un pictogramme (SVG 24×24 au trait du viewer) et une couleur claire et sombre
  pour huit types (`historique`, `jalon`, `phase`, `exigences`, `mission`, `backlog`, `graine`,
  `release`). Le générateur (`vf-project-graph.mjs`) les nomme et pose `meta.kindIcons` et
  `meta.kindColors`.
- **Patch P8** (`viewer.html`, une ligne, consigné dans `VENDORED.txt`) :
  `Object.assign(P, G.meta?.kindIcons || {})`.
- `80-vf-fr.js` (96 l., copie archivée ici ; l'original vit dans
  `002/.../assets/ui/`, injecté au build) :
  - environ 120 phrases exactes et 15 motifs, dont la progression de l'agent (« Cherche « x »
    dans la carte », « Examine », « Lit ») et « Réponse · N cartes » ;
  - appliqués aux nœuds de texte et aux attributs (`placeholder`, `title`, `aria-label`), au
    chargement puis à chaque mutation, regroupés par frame (`requestAnimationFrame`) ;
  - n'agit pas dans `code`, `pre`, `.mono` ni les chemins ;
  - libellés distincts selon l'onglet (« Élément » sur Projet, « Fichier » sur Code) ;
  - `lang="fr"`, titre de page suivi par observateur ;
  - couleurs des types ;
  - grille d'en-tête élargie (voir la trace de l'investigation) ;
  - `?lang=en` désactive l'extension, sonde `window.__vfFr = { nodes, attrs, passes, ms }`.

## Ce qu'on observe (2026-11-01, Playwright Chromium, dépôt réel)

Anglais visible (nœuds de texte et attributs qui égalent une chaîne de l'inventaire, ou un motif) :

| État | `?lang=en` | français |
|---|---|---|
| Projet, racine | 24 | 0 après ajout des 3 restes |
| Projet, phase 61 | 24 | 3, puis 0 |
| Projet, tableau de réponse | 28 | 2, puis 0 |
| Code, racine | n/a | 11, puis **0** |

- **Coût** : 1 à 2 ms cumulées sur l'onglet Projet (67 à 102 passages), 2 ms sur l'onglet Code
  (299 passages au chargement). **0 traduction et 1 passage sur 3 s au repos.**
- **Motifs** : `Searching the map for "phase 62"` → `Cherche « phase 62 » dans la carte` ;
  `Answer · 1 card` → `Réponse · 1 carte`. Une phrase de données qui contient « Answer » reste
  intacte (témoin négatif).
- **Types** : jalons en ambre avec un drapeau, panneau « Phase » avec son pictogramme violet,
  « Exigences », « Mission », « Graine » et « Release » distincts.
  Captures : `captures/1-racine-fr.png` et `captures/2-jalon-types.png`.
- **Non-régression** : la sonde du spike 005 repasse (exit 0) après la reconstruction.

## Trace de l'investigation

1. **L'en-tête casse** : les libellés français sont plus longs (« Par où commencer »,
   « Exporter », « Parcours »). Avec la grille `1fr auto 1fr`, la colonne de droite déborde et la
   recherche glisse **sur l'onglet « Projet »** (recherche à x = 304 contre 391 en anglais, onglet
   jusqu'à 320). → `auto minmax(0, 1fr) auto` au-dessus du gabarit mobile. La recherche se
   rétrécit (302 px à 1 440 px de large, 142 px à 1 280 px) et ne chevauche plus rien.
2. **Boucle infinie sur l'onglet Code** : 10 146 traductions d'attributs, puis 9 000 en 3 s au
   repos. Un `title=""` vide donnait `''`, valeur fausse mais pas `null`. L'attribut était donc
   réécrit, ce qui déclenchait une mutation et un nouveau passage, à chaque frame.
   L'onglet Projet n'a pas d'attribut vide, il ne la montrait pas : seul le second onglet l'a
   révélée. → `x ? tr(x) : null`, puis vérifié à 0 au repos.
3. **Navigation par hash** : changer `location.hash` après le chargement ne change pas la vue.
   Les mesures se font donc par chargement direct de chaque vue.
4. **Inventaire contre dictionnaire** : le dictionnaire couvre 97 des 258 chaînes de
   l'inventaire, mais **toutes celles vues** dans les états mesurés. Le reste vit dans des
   panneaux non visités : visite guidée, santé, glossaire, export, mode blueprint, messages
   d'erreur rares.

## Résultats

**VALIDATED** : les types dédiés tiennent avec une ligne de patch (P8), et leur libellé français
est gratuit. Le chrome passe en français par une extension de 96 lignes, sans toucher au
viewer, pour 1 à 2 ms et rien au repos.

Limites et suites :
- **Couverture partielle par construction** : une chaîne absente du dictionnaire reste en
  anglais, sans erreur. Il faut un test qui parcourt les états (dont visite guidée, export,
  parcours, erreurs) et rougit sur toute chaîne de l'inventaire visible. À chaque synchro amont,
  régénérer l'inventaire et comparer.
- **Un frame d'anglais** : la traduction suit la mutation dans la frame suivante. Pas visible à
  l'œil dans les captures, mais un rendu lent pourrait la montrer.
- **En-tête chargé** : à 1 280 px la recherche n'a plus que 142 px. Il faudra des libellés
  courts ou des boutons en icône seule sous environ 1 400 px.
- **Les « éléments »** (plans, exigences, étapes) gardent le type `file` du viewer : un seul
  libellé « Élément ». Des types de fichier distincts demanderaient un patch de `info()`.
- **Données en anglais** : « closed » (statut de STATE.md) et les ids bruts dans la progression
  de l'agent (« Examine n:ph-61 ») ne sont pas du chrome. À traiter au générateur et dans
  `describeTool` (P7).
- **Prompt de l'agent** : il reste à lui donner les noms de types français s'il doit les citer
  (`vf-ask.mjs` ne les cite pas encore).
