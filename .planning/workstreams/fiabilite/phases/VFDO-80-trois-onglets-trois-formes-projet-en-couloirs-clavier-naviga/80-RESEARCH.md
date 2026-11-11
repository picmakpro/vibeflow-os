# Phase 80 : Trois onglets, trois formes — Recherche

**Recherché le :** 2026-11-11 (arbre `.claude/worktrees/phase-80`, base `f763b556` ; branche 79 lue à `6f66d878`, lecture seule)
**Domaine :** couche VF du cockpit (extensions `ui/*.js` d'un moteur forké), accessibilité clavier d'un canevas SVG, harnais Chrome CDP
**Confiance :** HAUTE pour le code lu ; MOYENNE pour les comportements navigateur non mesurés (Safari, `inert` sur iframe)

## Summary

Les éclaireurs ont établi l'essentiel ; cette recherche ne vérifie que ce dont le plan a besoin. Trois faits changent la
forme des plans : (1) l'API du moteur est **gelée** (`window.Floorplan = Object.freeze({…})`, `viewer.html:2519`) : la couche
VF ne peut pas y accrocher `surcouches` ni `panneau` ; (2) `80-vf-fr.js` réapplique **après** la fusion du dictionnaire ses
surcharges propres à Projet (`File: 'Élément'`, l.28) : un dictionnaire neuf ne peut pas retirer « Élément », et
`test-cockpit-chrome-fr.sh` F6.6/F6.7 l'exigent aujourd'hui ; (3) les fichiers de la couche VF écrivent **déjà en français**
(marqueur `// VibeFlow (`, exclu de l'inventaire anglais) : le dictionnaire de la 80 ne sert qu'aux phrases anglaises que les
lots moteur A et B ajouteraient à `viewer.html`.

Aucune aide commune ne construit l'adresse de `project.html` ; le seul point de passage commun des suites navigateur est
`naviguer()` de `chrome-session.mjs`. La branche de la 79 ne porte encore que des documents (trois commits `docs(79)`) :
`socle-serveur.sh` n'existe pas ; toute suite écrite maintenant lance le serveur comme `test-cockpit-accessibilite.sh`.

**Recommandation principale :** vagues 1-2 entièrement dans des fichiers `ui/` neufs (déclarés `AJOUT`, chacun inséré à sa
place alphabétique dans `VENDORED.txt`), API publique de la 80 sous des globales `window.VF_*` (pas sous `VibeFlow.*`),
retrait d'« Élément » par le moteur (lot A, libellé de type) plutôt que par le dictionnaire, `?vue=graphe` posé une fois
dans `naviguer()`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
Recopiées par référence (le fichier fait foi, 383 lignes) : `80-CONTEXT.md` § `<decisions>` — **P80-D-01 à P80-D-27**, toutes
« décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée » ; contrats **P80-C76-1 à 4**
(Phase 76) ; contrats fournis aux Phases 73, 74, 75 (pile de surcouches, clavier du canevas, emplacement de preuve) ; contrats
consommés de la 79 **C0, C5, C6-1, C6-2, A1 à A7, A10, A11, A15, A25, A27**. Points qui bornent cette recherche :
- P80-D-15 : tout `viewer.html` / `40-tour.js` / `05-theme.js` **après la fusion de la 79 entière**, un seul codeur à la fois.
- P80-D-23 : vagues 1-2 couche VF sans moteur, indépendantes de la 79 ; 3-5 moteur ; 6 onglets ; assemblage en dernier.
- P80-D-24 : compteur des README, table de durées, `CHANGELOG.md` écrits **par le seul plan d'assemblage**.
- P80-D-25 : témoin rouge sur la base puis vert, trace (assertion, attendu, obtenu), un mutant par garde, suites jamais affaiblies.
- P80-D-27 : la 80 ne modifie ni `78-vf-fr-dict-a.js`, `79-vf-fr-dict-b.js`, `80-vf-fr.js`, `70-vf-live.js`, `75-vf-modele.js`,
  `vf-cockpit-live.mjs`, `serve.mjs`.

### Claude's Discretion
« Noms exacts des fichiers neufs (dans la plage `ui/` qui garantit l'ordre de chargement), découpage interne sous le plafond de
300 lignes, libellés français exacts (dictionnaire), forme exacte des témoins, à condition de tenir les décisions ci-dessus et
l'UI-SPEC de la phase. »

### Deferred Ideas (OUT OF SCOPE)
Onglet Équipe (73, 74) ; couleur de la carte Code (75) ; preuves de traçabilité (76) ; collecte, flux, coquille (79) ; actions
sur une session (81) ; plan B d'AUDC-BL1 ; mode focus recomposé ; vue liste de Code. FORM-18 (S80-1 à S80-4) non exécutable.
</user_constraints>

## Project Constraints (from CLAUDE.md)

- Commits en français ; un arbitrage cité nomme canal et date ; identifiants de décision préfixés (`P80-D-NN`).
- Jamais de fix sans validation humaine (ADR-031) ; ne jamais supprimer un artefact pour verdir.
- Densité : fichiers d'agents/skills hors sujet ici ; plafond **300 lignes** par extension `ui/*.js` (gate `test-cockpit-vendor.sh`).
- Tout commit qui touche un gate, sa suite, `ci.yml`, un hook ou une fixture surveillée porte un trailer `Gate-Touche:` (G-2).
- Toute interface suit `DESIGN.md` (« Graphite »). Pas de release pour une PR de planning seule (ADR-073).
- Rejouer les commandes du job CI `gates` de `.github/workflows/ci.yml`, jamais une liste de rapport ; `rtk proxy` pour mesurer.

<phase_requirements>
## Phase Requirements

| ID | Description (abrégée) | Ce que la recherche apporte |
|----|----|----|
| FORM-01 | Canevas au clavier, `listbox`/`option` | Points d'accroche `on('render')`/`on('panel')`, `state.chipEls`, ordre microtâche ; conflit X4 (Pièges 1, 4) |
| FORM-02 | Pile de surcouches | API gelée → globale `VF_SURCOUCHES` ; ordre des Échap en capture ; panneau fermé en CSS VF (Pièges 2, 3) |
| FORM-03 | Zoom, garde de saisie, aide `?` | `zoomBy`/`setT` non exportés (patch lot A) ; garde globale `viewer.html:2448` |
| FORM-04 | Palette étendue | `index` et `runSearch` internes (`viewer.html:1839-1881`) → lot B ; rôles posables depuis la couche VF |
| FORM-05 | Couloirs par défaut | Pas d'aide d'adresse commune ; `naviguer()` point unique ; `?vue=` préservé par `setHash` |
| FORM-06 | Champs facultatifs du nœud phase | `piedExigences` et `statuts` cités verbatim |
| FORM-07, 08 | Liste Backlog/Graines/Releases ; vocabulaire | « Élément » réappliqué par `80-vf-fr.js:28` ; F6.6/F6.7 |
| FORM-09 | Liste/tableau mémorisé par lab | `store` non scopé par lab (`viewer.html:689`) |
| FORM-10, 11, 12 | Minicarte, cadrage, ligne d'état | `freeArea`, `state.layout`, `state.t` lisibles ; pas d'événement de transformation |
| FORM-13 | Tiroir Git | Fichiers `77-*` couche VF, aucune dépendance moteur |
| FORM-14 | Jetons | Outil de contraste existant (`test-cockpit-git-entete.sh:409-411`) ; P78-D-34 = arbitrage |
| FORM-15 | Lien de vue | `setHash` reconstruit le fragment (v, s seuls) → lot A |
| FORM-16 | Onglets sans rechargement | Plancher de `fit()` lié à `location.pathname` ; extensions qui lisent l'onglet une fois |
| FORM-17 | Non-régression | Carte des suites touchées, compteur § 9, partage CI |
</phase_requirements>

## Architectural Responsibility Map

| Capacité | Tier principal | Secondaire | Raison |
|---|---|---|---|
| Couloirs, liste, carte de phase | Navigateur (couche VF `ui/`) | Socle Node (`vf-cockpit-project.mjs`, champs facultatifs) | Vue DOM nouvelle (P80-D-01) ; données déjà calculées côté socle |
| Clavier du canevas, pile, minicarte, ligne d'état | Navigateur (couche VF) | — | Lit `state.*` du moteur, ne le modifie pas |
| Zoom centré, garde de saisie, palette, lien de vue, libellé de type | Navigateur (moteur `viewer.html`, lots A/B) | — | Fonctions internes non exportées |
| Contrat `cockpit-project@1` | Socle Node (`vf-cockpit-interface.json`) | — | Ajout de champs seul (C0) |
| Routage d'onglet | Navigateur (couche VF) | Coquille 79 (`VF_COQUILLE`) | A2 : la 79 recharge le moteur, la 80 route |

## Standard Stack

Aucune bibliothèque nouvelle. Tout repose sur l'existant, vérifié dans l'arbre :

| Élément | Où | Usage par la 80 |
|---|---|---|
| Extensions `ui/*.js` inlinées, tri lexicographique | `skills/cockpit-moteur/scripts/build.mjs:448` `readdirSync(uiDir).filter((n) => n.endsWith('.js')).sort()` [VERIFIED: build.mjs:448] | fichiers neufs, ordre par le nom |
| Harnais Chrome sans dépendance | `scripts/tests/chrome-session.mjs` (117 l.), `chrome-cdp.mjs`, `chrome-parcours-tab.mjs` [VERIFIED: lus] | toutes les suites navigateur |
| Hygiène des processus | `scripts/tests/hygiene.sh` (`vf_hyg_init`, `vf_hyg_assert`, `vf_hyg_fin`) [VERIFIED: test-cockpit-accessibilite.sh:19-20,105] | obligatoire dans une suite qui lance serveur ou Chrome |
| Saut sans navigateur | `scripts/tests/chrome-saut.sh` `vf_chrome_saut` [VERIFIED: test-cockpit-accessibilite.sh:16] | « SUITE SAUTÉE », jamais un vert à vide |

**Installation :** aucune.

## Package Legitimacy Audit

Aucun paquet externe installé par la phase. **Retirés :** aucun. **Suspects :** aucun.

## Architecture Patterns

### Diagramme (données et événements)

```
.planning/ du lab ──► vf-cockpit-planning.mjs ──► vf-cockpit-project.mjs ──(cockpit-project@1 + champs facultatifs P80-D-06)──►
   project.html (aujourd'hui) / GET /api/vf/graphe?onglet=projet (après la 79)
        │
        ▼
 viewer.html (moteur gelé) ── render() ──► draw() ──► queueMicrotask(emit 'render') ──► couche VF :
        │                                                   ├─ clavier canevas : rôles, tabindex, nom (Code, Projet ?vue=graphe)
        │                                                   ├─ couloirs / liste (Projet racine, ?vue=couloirs|liste) ── clic ──► VibeFlow.select(ph-N)
        │                                                   └─ minicarte, repères de bord, ligne d'état (lit state.layout, state.t, freeArea())
        ├─ renderPanel() ──► emit 'panel' {selected} ──► aria-selected, pile « Retour » (VF_PANNEAU)
        └─ keydown window (bulle) ◄── pile de surcouches (VF_SURCOUCHES) : Échap, piège à Tab, inert
```

### Structure recommandée des fichiers neufs (`assets/ui/`, ordre = ordre de chargement)

```
00-vf-surcouches.js     # pile (avant 00-vibeflow.js : « 00-vf » < « 00-vi ») — P80-D-11
04-vf-clavier-canevas.js# listbox/option, voisin spatial — P80-D-10
4x-vf-projet-modele.js  # modèle couloirs/liste (pur)   ┐ découpage du trio 77-* (P80-D-01)
4x-vf-projet-rendu.js   # rendu pur, chaînes par h()    │ placés APRÈS 40-tour.js pour lire window.VibeFlowTour
4x-vf-projet-vue.js     # bascule ?vue=, touche v       ┘
6x-vf-minicarte.js      # minicarte + repères + ligne d'état (≤ 300 l., sinon deux fichiers)
79-vf-fr-dict-c.js      # SEULEMENT si les lots A/B ajoutent des phrases anglaises au moteur (voir Piège 6)
```
Plages à éviter : `70`-`80` (fichiers de la 79), `73`, `77` (modifiés par la 80 pour la pile, mais existants).
[ASSUMED : noms exacts — discrétion du planificateur]

### Pattern 1 : s'accrocher au rendu sans patch
**Quoi :** `render()` pose `state.layout`, émet `render` en **microtâche** puis appelle `draw()`, `applySelection()` et
`opts.after()` dans la même continuation (`viewer.html:1140-1148`) : les écouteurs `on('render')` voient les cartes dessinées
**et** passent après le `after` de `reveal()` (qui pose `role=button` + `tabindex=-1`, `viewer.html:1503`) ; la 80 peut donc
reposer `role=option` sans être écrasée. Une simple sélection (même niveau) ne rend pas : elle passe par `renderPanel()` qui
émet `panel` `{ selected, container }` (`viewer.html:1685`). `aria-selected` se synchronise sur `panel`, pas sur `render`.
[VERIFIED: viewer.html:1126-1149, 1465-1474, 1685]

```js
// Source : viewer.html:2519-2565 (API), 1186-1200 (cartes)
const SC = window.VibeFlow;                      // servi sous ce nom (rename /Floorplan/g → VibeFlow)
SC.on('render', ({ container }) => poserRoles(container));   // cartes recréées à chaque draw()
SC.on('panel', ({ selected }) => synchroniserSelection(selected));
// carte ↔ id : SC.state.chipEls (Map id → g.node) ; positions : SC.state.layout.children [{id,x,y,width,height}]
```

### Pattern 2 : publier une API de la 80 hors de l'objet gelé
`window.Floorplan = Object.freeze({ … })` (`viewer.html:2519`) : `VibeFlow.surcouches = …` échoue (silencieusement hors mode
strict, `TypeError` en mode strict). La couche VF publie déjà ses objets en globales : `window.__vfLive` (`70-vf-live.js:14`),
`window.__vfModele` (`75-vf-modele.js:11`), `window.__vfFrTraduire` (`80-vf-fr.js:82`) ; la 79 nomme les siens `VF_ETAT`,
`VF_COQUILLE`. **Recommandation :** `window.VF_SURCOUCHES = { ouvrir, dessus, ouverte }` et `window.VF_PANNEAU = { retour }`,
contrats 73/74/76 réécrits avec ces noms (amendement daté de `80-CONTEXT.md`). L'objet `state` n'est gelé qu'en surface :
`SC.state.t` reste inscriptible (usage existant `72-vf-equipe.js:84-86`). [VERIFIED: viewer.html:2519 ; grep des globales]

### Pattern 3 : modèle de tabulation itinérante déjà écrit
Rangées du graphe Git : `role=option`, `aria-selected`, un seul `tabindex=0` (`77-vf-git-vue-detail.js:53-62`, création
`77-vf-git-rendu.js:106`) [CITED: scout-canevas § 2]. Le reprendre pour les cartes : `g.node` porte `tabindex` (0 pour la
carte courante, −1 pour les autres), l'`svg#svg` porte `role=listbox` + `aria-label`. Voisin spatial calculé sur
`state.layout.children` (centres), cartes connecteurs `x:` comprises (Entrée sur `x:` = `reveal(connEntity)`, géré par `open()`).

### Anti-patterns
- **Recopier une liste « surcouche ouverte » de plus** : il y en a trois (`77-vf-git-tiroir.js:182`, `73-vf-tiroir-travail.js:28`,
  `02-vf-telephone.js:223`) ; la pile les remplace (retrait 4).
- **Écrire `#viewport` sans `applyTransform`** pour le zoom centré : saute les paliers `lod-*` et le redessin des colonnes
  (`viewer.html:1343-1350`) ; `72-vf-equipe.js` le fait par nécessité, la 80 passe par le patch du lot A.
- **Garder un focus sur une carte détruite** : `draw()` vide `#viewport` (`vp.innerHTML = ''`, `viewer.html:1152`) ; sans
  reprise sur `render`, le focus retombe sur `body`.

## Don't Hand-Roll

| Problème | Ne pas écrire | Utiliser | Raison |
|---|---|---|---|
| Attente d'un état navigateur | `pause(n)` puis lecture | `s.attendre`, `stabiliser`, `attendreValeur`, `positionPosee` (`chrome-session.mjs:10-26`) | règle « mesurer une fois posé » ; CI Linux plus lente |
| Parcours de Tab | boucle maison | `parcoursTab(s, touche, detail, nom)` (`chrome-parcours-tab.mjs:4`) | départ explicite, détection du cycle |
| Vraies touches | `dispatchEvent(new KeyboardEvent)` | `Input.dispatchKeyEvent` (`touche()`, `chrome-accessibilite.mjs:46`) | Tab et focus réels |
| Contraste | formule ad hoc | `lum(rgb(...))` de `test-cockpit-git-entete.sh:409-411` | même calcul que H7.6 |
| Jetons CSS | contrôle manuel | `scripts/tests/css-jetons.mjs` | couleur littérale, espacement hors grille, rayon |
| Fermer la palette | ré-implémenter | `document.getElementById('pal-x').click()` (`viewer.html:1891` → `closePalette(true)`) | rend le focus à l'origine |
| Mouvement réduit | `matchMedia` par fichier | règle `!important` de `03-vf-accessibilite.js:13-16`, entrée `vf-<nom>-entree` | X6 compte `getAnimations()` |

## Common Pitfalls

### Piège 1 : l'anneau sur `.card` fait rougir X4 (Code)
**Ce qui casse :** l'UI-SPEC pose `g.node:focus { outline: none }` et dessine l'anneau sur `.card`. La sonde X4
(`chrome-accessibilite.mjs:59-63`) lit le contour **calculé de `document.activeElement`** (ou de son `form`) : l'arrêt du canevas
sur Code sera « sans anneau » (X4.1) et cassera « un seul style » (X4.2, X4.2b).
**Éviter :** étendre `ANNEAU` (si l'actif est un `g.node`, mesurer sa `.card`) dans le plan du clavier, comme renforcement
nommé (pas un affaiblissement), avec un témoin rouge (carte sans anneau visible). Témoin positif : X4.3 inchangé.

### Piège 2 : Échap en capture « au niveau du document » arrive après le moteur
**Ce qui casse :** la fenêtre modale du moteur écoute Échap sur `window` en capture avec `stopImmediatePropagation`
(`viewer.html:2478`) ; `30-screens.js:114-117` et `40-tour.js:249-254` aussi (sur `window`, capture). La phase de capture va
`window` → `document` : un écouteur de pile sur `document` ne voit jamais ces Échap.
**Éviter :** la pile **observe** l'état des surcouches du moteur (classe `open` de `#modal` et `#palette` par
`MutationObserver`) au lieu de les fermer elle-même ; elle n'est maîtresse que des surcouches de la couche VF. Écouteur de pile
sur `window` en capture, enregistré au chargement de `00-vf-surcouches.js` (après ceux du moteur, avant ceux des autres `ui/`).

### Piège 3 : `inert` ne se lève pas sous un ancêtre inerte
**Ce qui casse :** un élément sous un ancêtre `inert` ne peut pas s'en extraire (seul un `<dialog>` ouvert par `showModal()`
y échappe) [CITED: developer.mozilla.org/…/Global_attributes/inert]. Le terminal pose `inert` **sur sa propre région fermée**
(`vf-cockpit-terminal-tiroir.mjs:160,170`).
**Éviter :** poser `inert` sur les **frères** de la surcouche au niveau de `body` (`header`, `main#stage`, `#panel`, tiroirs),
jamais sur un ancêtre d'elle ; mémoriser la liste exacte des nœuds inertés par la pile et ne lever que ceux-là (la région du
terminal fermée garde le sien). Effet d'un `inert` sur le document d'une iframe : non vérifié [ASSUMED] — témoin Chrome.

### Piège 4 : la sélection suit le focus au bureau, pas au téléphone — et Entrée lit `state.selected`
L'Entrée globale ouvre `state.selected` (`viewer.html:2462`), pas la carte focalisée. Au téléphone (sélection découplée,
P80-D-10), la carte focalisée doit gérer Entrée elle-même (`stopPropagation`). Les flèches ←/→ du moteur pilotent un parcours
(`state.flow`, `viewer.html:2463-2464`) et la visite en capture (`40-tour.js:251-252`) : le clavier du canevas cède quand
`SC.state.flow` est vrai ou `VibeFlowTour.active()`. Échap remonte déjà si `svg.contains(ev.target)` (`viewer.html:2456`).
L'APG dit la sélection-suit-le-focus « optionnelle », « can severely degrade accessibility in others » [CITED: w3.org/WAI/ARIA/apg/patterns/listbox].

### Piège 5 : Équipe et ses comptes de Tab
FORM-01 vise Code et le graphe de Projet ; l'UI-SPEC dit qu'Équipe n'a plus de canevas (73). Toute pose de `tabindex` sur
`vfTab === 'equipe'` décale EK18 (`test-cockpit-equipe.sh`, `chrome-equipe-clavier.mjs`). Garde explicite sur `G.meta.vfTab`.

### Piège 6 : le dictionnaire ne peut pas retirer « Élément » sur Projet
`80-vf-fr.js:12` copie `window.__vfFrDict` puis, l.28, `Object.assign(T, projet() ? { File: 'Élément', file: 'élément',
Files: 'Éléments', 'Files involved': 'Éléments concernés', … } : …)` : les surcharges propres à Projet **gagnent** sur toute
entrée d'un dictionnaire neuf. `test-cockpit-chrome-fr.sh:138` exige `« File » → Élément sur l'onglet Projet` (F6.6) et l.140
`["éléments","fichiers"]` (F6.7). [VERIFIED: 80-vf-fr.js:12,28 ; test-cockpit-chrome-fr.sh:138-140]
**Éviter :** que le moteur n'émette plus « File »/« Files » sur Projet (en-tête de panneau d'une feuille et titre de liste
écrits depuis `meta.kindLabels`, lot A) : F6.6 reste vrai (la fonction pure traduit toujours), mais le mot n'est plus affiché.

### Piège 7 : `setHash` efface tout ce qui n'est pas `v` et `s`
`setHash` reconstruit le fragment avec un `URLSearchParams` neuf (`v`, `s`) et `pushState` (`viewer.html:1448-1455`) ;
`readHash` ignore le reste. Un `z=` ou un état « Git ouvert » posé par la couche VF est effacé à la sélection suivante.
La requête est préservée (`location.pathname + location.search` quand le fragment est vide) : `?vue=` survit (P80-D-02 juste).
`pushState` ne déclenche ni `hashchange` ni `popstate` : un `#r=` posé par la palette doit appeler le traitement directement
(`00-vibeflow.js:280-298` écoute `ready` et `hashchange`).

### Piège 8 : préférences « par lab » dans `store`
`store` préfixe `floorplan:` + clé, sans lab (`viewer.html:689`) ; l'origine change avec le port. Clé = nom du lab (forme de
`40-tour.js:9`, `'tour-seen:' + (G.project?.name || G.meta?.rootName || 'map')`) + classe de largeur.

### Piège 9 : l'onglet est lu une seule fois au chargement
`fit()` choisit le plancher 11/13 sur `location.pathname` (`viewer.html:1371`) ; `80-vf-fr.js:28` et `70-vf-live.js:15`
(`const TAB = G.meta.vfTab === 'project' ? …`) figent l'onglet au chargement. Avec `chargerOnglet` dans le même document
(FORM-16), le `pushState` du chemin doit précéder l'appel, et la réinitialisation des extensions est à demander à la 79.

### Piège 10 : la vue des couloirs ne doit pas masquer le moteur au point de casser la visite
La visite calcule ses étapes sur les cartes rendues. Si les couloirs **recouvrent** la scène (le moteur continue de rendre
dessous), la bascule en graphe est un simple démasquage, et la visite automatique reste jouable (voir Q5).

## Réponses aux questions prioritaires

**Q1 — Chargement et dictionnaires.** Tri lexicographique de tous les `ui/*.js`, inlinés avec l'en-tête `/* ui/<nom> */`
(`build.mjs:448`). Un fichier neuf doit être déclaré `AJOUT assets/ui/<nom>.js` : `synchro.sh verifier` retire les `AJOUT`
puis compare l'arbre à l'empreinte amont (`synchro.sh:98-110`, l.103) — un fichier non déclaré la fait échouer (V6.1). Plafond
300 lignes appliqué aux seuls `AJOUT` `.js/.mjs` (`test-cockpit-vendor.sh:53`). Fusion du dictionnaire :
`window.__vfFrDict = Object.assign(window.__vfFrDict || {}, {` (`78-vf-fr-dict-a.js:5`, `79-vf-fr-dict-b.js:3`), copie unique
par `80-vf-fr.js:12`. **Un `79-vf-fr-dict-c.js` (première ligne `// vibeflow:fr`) est chargé et fusionné sans toucher aux trois
fichiers** (« 79-vf-fr-dict-c » trie entre « …-b » et « 80-vf-fr ») ; le test le lit (regex `// vibeflow:fr`,
`test-cockpit-chrome-fr.sh:39`) mais F5.2 ne contrôle le nom amont que dans 78 et 79 (l.131) : l'étendre au fichier neuf.
Limites : (a) il ne peut pas surcharger les clés de `80-vf-fr.js:28` ; (b) la 79 modifie le mécanisme (A7 : 78, 79, 80 ;
AUDC-H4 « traduction au point d'émission ») — à revérifier après sa fusion ; (c) les fichiers VF (`// VibeFlow (`) sont exclus
de l'inventaire anglais (`vf-cockpit-fr-inventaire.mjs:124`) et écrivent en français : aucune entrée de dictionnaire pour eux.
Insertion des `AJOUT` : à leur place alphabétique entre `VENDORED.txt:25` et `:42` (plans parallèles = lignes distinctes).

**Q2 — Harnais.** Une suite = `test-cockpit-<nom>.sh` (découverte par `find plugin scripts -path '*/tests/test-*.sh'`,
`ci-shard-suites.sh --all`) + un pilote `chrome-<nom>.mjs` qui appelle `executer(chrome, async (s) => {…})` et rend une ligne
JSON (`chrome-session.mjs:111-117`). Gabarit à recopier : `test-cockpit-accessibilite.sh` — Chrome détecté (l.15), saut
(l.16), `HOME` jetable et `REAL_HOME` (l.17-18), hygiène (l.19-20), `mklab` (l.44-56), serveur lancé par
`node "$O/serve.mjs" --no-open --port "$(libre)"` avec `VF_COCKPIT_ENGINE_DIR`/`VF_COCKPIT_SCRIPTS_DIR` (l.62), port lu
dans `.cache/server.json` (l.64-65), lecture JSON par `ev.mjs` (l.23-27), garde anti-vert-à-vide (l.107). Pilote :
`charger` (`?lang=en` ; Échap pour la visite automatique), `PRET`/`VUE_POSEE` (`chrome-accessibilite.mjs:7-8,14-20`),
`Emulation.setFocusEmulationEnabled` (l.21). Après la vague 1 de la 79 : sourcer `socle-serveur.sh` (`cockpit_lancer`,
`cockpit_get`, `attendre`) — **absent à `6f66d878`** (la branche ne porte que des commits `docs(79)`). Déclaration : le
compteur « 213 suites » (`README.md:65`, `README.fr.md`) est comparé à la découverte réelle (`check-version-sync.sh:131-139`,
213 mesurées) — écrit par l'assemblage seul ; `ci-suites-perimetre.sh` sélectionne par module (rien à déclarer) ; la table de
`ci-shard-suites.sh` est facultative (défaut 7 s). Trace du rouge : écrire la suite d'abord, la jouer sur le code de la base
dans l'arbre du plan, coller la sortie `❌ FAIL … attendu/obtenu` dans un `80-NN-RED-TRACE.md` (forme de `78-04-RED-TRACE.md`).

**Q3 — Adresse de `project.html`.** **Aucune aide commune.** ~50 fichiers citent `project.html` ; la plupart lisent le fichier
ou le servent par HTTP (indifférents à la vue). Chargent la page dans Chrome et supposent le canevas : `chrome-accessibilite.mjs`
(l.49, 57), `chrome-moteur-carte.mjs` (122, 134, 179), `chrome-equipe-clavier.mjs` (271), `chrome-mission.mjs`,
`chrome-panneau-etroit.mjs`, `chrome-statut.mjs` (`file://`, `test-cockpit-chrome-fr.sh:276`), `chrome-fr-rendu.mjs`
(`:258`), `chrome-visite*.mjs`, `test-cockpit-responsive.sh` (130, 137, 158, 223, 304, 446, 458, 476, 539), `test-cockpit-
projet-visite.sh`, `test-cockpit-git-entete.sh:361`, `test-cockpit-lancer-ui.sh:167`, `test-cockpit-lancer-bandeau.sh`
(381, 912, 938, 964), `chrome-lancer.mjs`, `chrome-fin.mjs`, `test-cockpit-lancer-chat.sh:406-407`, `test-cockpit-chaine-xss.sh`
(138, 233 ; pilote propre), `temoins/lancer-xss.mjs` (pilote propre). Point unique : `naviguer(url)` de
`chrome-session.mjs:62-69`, par lequel passent `executer`/`chrome-cdp.mjs`. **Recommandation :** une ligne qui ajoute
`vue=graphe` à toute adresse `/project.html` sans `vue=` (préserver `#…`), avec une option de sortie (`naviguer(url, { brut:
true })`) pour la suite des couloirs ; puis vérifier une à une les suites à pilote propre (`chaine-xss`, `lancer-xss`) et la
page `file://` de `chrome-statut.mjs` (`?vue=` sur `file://` : vérifier). La liste exacte va dans la carte des fichiers.

**Q4 — Points d'extension.** Exportés (`viewer.html:2519-2565`) : `go`, `reveal`, `select`, `open`, `up`, `fit`, `freeArea`,
`render`, `rerender`, `refreshPanel`, `closeMenus`, `addHeaderButton`, `addPanelSection`, `showPanel`, `closePanel`, `modal`,
`toast`, `copy`, `store`, `on`, `setOverview`, `state`, `graph`, `nodes`, `files`, `children`, `parentOf`, `exists`,
`shownName`, `info`, `h`, `icon`, `plural`. Événements : `render` (1141), `panel` (1685), `technical` (2474), `ready` (2574).
**Faisables sans patch** : rôles et nom des cartes ; pile (en observant `#modal`/`#palette`) ; piège à Tab et `inert` ;
rôles `dialog`/`listbox`/`aria-activedescendant` de la palette (élément statique `#palette .box` et `#results`, réécrit à chaque
`runSearch` : `MutationObserver`) ; **panneau fermé non tabulable en CSS VF** (le moteur le fait déjà au téléphone :
`body.no-panel #panel { … visibility: hidden; transition: …, visibility 0s linear .45s; }`, `viewer.html:582`) ; minicarte,
repères, ligne d'état (lecture ; transformation observée sur l'attribut `style` de `#viewport`, aucun événement). **Exigent un
patch** : zoom centré et facteurs (`zoomBy` 1377, touches 2465-2466, boutons 1443-1444) ; garde de saisie (2448) ; formule de
cadrage exposée ; sources et actions de la palette (`index` 1839, `runSearch` internes) ; `setHash`/`readHash` (1448-1462) ;
ligne « module » (≈1788) et règle « document » (≈1792) ; libellé de type « File » sur Projet.

**Q5 — Visite.** `window.FloorplanTour = { start, end, active, diag }` (`40-tour.js:270`), servi `window.VibeFlowTour` ;
`02-vf-telephone.js:223` le lit déjà. Le bouton appelle la fonction interne (`40-tour.js:245`), l'ouverture automatique part
de `maybeAuto` (l.260-267 : seulement si `!SEEN`, fragment vide, `container === 'root'`, après 700 ms). Depuis la couche VF :
clic du bouton intercepté sur `document` en capture (`stopPropagation`, bascule en graphe, puis `VibeFlowTour.start()`) ;
ouverture automatique seulement **détectée** (`VibeFlowTour.active()` ou carte de visite visible → bascule). Faisable sans
patch de `40-tour.js` si la scène du moteur reste rendue sous les couloirs (Piège 10). `?vue=graphe` ne bloque pas
`maybeAuto` (il ne lit que le fragment) : les suites de visite gardent leur comportement.

**Q6 — Sources.** APG listbox : `listbox` nommé, `option` + `aria-selected`, Origine/Fin « strongly recommended » au-delà de
cinq options, `aria-activedescendant` « an alternative to moving DOM focus » [CITED: w3.org/WAI/ARIA/apg/patterns/listbox].
`inert` : tout le sous-arbre, non focalisable, retiré de l'arbre d'accessibilité, aucune échappatoire hors `showModal()`
[CITED: MDN inert ; html.spec.whatwg.org § inert]. Focus d'un `g` SVG à `tabindex` dans Safari et rendu d'`outline` sur un
`g` : [ASSUMED] — d'où l'anneau sur `.card`. Le focus ne va jamais **dans** le `foreignObject` (les cartes n'ont pas
d'élément interactif) : le piège Safari du focus dans `foreignObject` ne s'applique pas.

**Q8 — P78-D-34.** **Arbitrage de Samuel** : « **P78-D-34 ratifiée.** « Valider le seuil (Recommandé) » (arbitrage Samuel,
AskUserQuestion session principale, 2026-11-06) : seconde ligne masquée sous 1280 px, icône 44 px de 701 à 1279 px, pas de
retour en arrière. » [VERIFIED: 78-CONTEXT.md:160-161]. P78-D-39 l'a confirmé (« Options écartées : … revenir sur P78-D-34 »,
l.175-176). FORM-14 laisse l'ouvreur Git à 44 px.

## Code Examples

```js
// Données (FORM-06) — même calcul que piedExigences (vf-cockpit-project.mjs:48-53) :
//   const ouvertes = reqs.filter((r) => !r.done).length; … `${reqs.length - ouvertes}/${reqs.length} exigences`
const exigences = phReqs.length ? { faits: phReqs.length - phReqs.filter((r) => !r.done).length, total: phReqs.length } : undefined;
// contrat : vf-cockpit-interface.json:46  "statuts": ["done", "active", "todo", "blocked"]  → ajouter "recette"
// projection : vf-cockpit-project.mjs:22  PROJECTION_ST = { fait: 'done', 'a-recetter': 'recette', 'en-cours': 'active', 'a-faire': 'todo' }
```

```js
// Mouvement réduit dans un témoin (chrome-accessibilite.mjs:73, 81)
const ANIMS = "document.getAnimations().filter((a) => a.playState === 'running' || a.playState === 'pending').length";
await s.send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });
```

## State of the Art

| Ancien | Actuel | Quand | Effet |
|---|---|---|---|
| Diff de patch régénéré (`synchro.sh regenerer-patch`) | Fork assumé, `amont/` retiré | vague 1 de la 79 (C6-1, A7) | les lots moteur A/B/jetons n'écrivent aucun diff |
| `node "$O/serve.mjs"` dans chaque suite | `socle-serveur.sh` sourcé | plan 79-02 (A6) | suites écrites après : `cockpit_lancer` |
| Une page par onglet | Coquille + `GET /api/vf/graphe` | C5 | FORM-16 seulement après la 79 |

## Assumptions Log

| # | Hypothèse | Section | Risque si faux |
|---|---|---|---|
| A1 | Safari focalise un `g` SVG à `tabindex` et n'y dessine pas d'`outline` arrondi | Q6, Piège 1 | anneau invisible sur Safari ; témoin Chrome seul |
| A2 | `inert` sur un ancêtre d'iframe rend l'iframe inopérante dans Chrome | Piège 3 | terminal utilisable sous une modale |
| A3 | Noms de fichiers `00-vf-…`, `04-…`, `4x-…`, `6x-…` | Structure | ordre de chargement à revoir |
| A4 | Le mécanisme `__vfFrDict` survit à la 79 (H4) | Q1 | dictionnaire de la 80 à déplacer |
| A5 | `?vue=` sur une adresse `file://` est lu par la page | Q3 | `chrome-statut.mjs` à traiter à part |

## Open Questions

1. **Noms des contrats publics (`VibeFlow.surcouches`, `VibeFlow.panneau`) devenus impossibles.** Connu : objet gelé.
   Recommandation : `window.VF_SURCOUCHES`, `window.VF_PANNEAU`, amendement daté de `80-CONTEXT.md` et message aux 73, 74, 76.
2. **Réinitialisation des extensions par `chargerOnglet`** (Piège 9) : à poser à la 79 avant le plan FORM-16.
3. **« Mentions » / « module »** : patch lot A (règle « document » ≈`viewer.html:1792`, ligne ≈1788 ; numéros de l'éclaireur,
   non relus ici).

## Environment Availability

| Dépendance | Requise par | Dispo | Version | Repli |
|---|---|---|---|---|
| Node | suites, socle | ✓ | v26.5.0 | — |
| Google Chrome | suites navigateur | ✓ | 157.0.8103.51 | saut audible (`chrome-saut.sh`) |
| Safari | A1 (mesure manuelle) | ✓ (app) | — | juge humain |
| jq, git | suites | ✓ | — | — |

## Validation Architecture

### Test Framework
| Propriété | Valeur |
|---|---|
| Framework | suites bash `assert_eq` + pilotes Node CDP (`chrome-session.mjs`) |
| Config | aucune ; découverte `find plugin scripts -path '*/tests/test-*.sh'` |
| Commande rapide | `bash plugin/cockpit/scripts/tests/test-cockpit-<suite-du-plan>.sh` (depuis la racine de l'arbre) |
| Suite complète | `bash scripts/ci-suites-perimetre.sh --liste <base> HEAD \| while read -r s; do bash "$s" \|\| echo "FAIL $s"; done` puis les commandes du job `gates` de `ci.yml` (dont `bash scripts/check-version-sync.sh`) |

### Phase Requirements → Test Map
Chaque ligne : témoin rouge sur la base (trace collée) → vert ; suite neuve par plan (P80-D-24).

| Req | Témoin rouge → vert | Type | Commande |
|---|---|---|---|
| FORM-01 | Code : Tab depuis le départ → nombre d'arrêts dans `#svg` = 0 sur la base, 1 après ; flèche → `activeElement` change d'id ; `role=listbox` nommé, `option` + `aria-selected` ; arêtes `aria-hidden` ; Entrée/Échap rendent le focus à une carte ; mutant : voisin par ordre DOM | navigateur | `test-cockpit-clavier-canevas.sh` |
| FORM-02 | palette ouverte + Tab + Échap → fermée (rouge base) ; export + 15 Tab → focus dans `#modal` ; panneau fermé au bureau → 0 tabulable ; `inert` du terminal intact après fermeture ; mutant : pile qui lève tous les `inert` | navigateur | `test-cockpit-surcouches.sh` |
| FORM-03 | `+` puis `-` → `state.t` identique (rouge : 1,2×0,83) ; centre = carte sélectionnée ; `f` dans un `TEXTAREA`/`contenteditable` → rien ; `?` ouvre l'aide listée depuis le registre | navigateur | `test-cockpit-zoom-garde.sh` (après la 79) |
| FORM-04 | `>` + « Git » → action présente ; choix → tiroir ouvert, aucune requête `POST` ; « Copier le lien » | navigateur | `test-cockpit-palette.sh` (après la 79) |
| FORM-05 | `project.html` sans paramètre → 4 `[role=group]`, 0 canevas (rouge base : canevas) ; `?vue=graphe` → canevas ; P80-C76-1 (section `addPanelSection('item')` après clic, cible `ph-<N>`), C76-2 (ordre), C76-3 (`reveal` en couloirs) | navigateur | `test-cockpit-couloirs.sh` |
| FORM-06 | `avancement`, `exigences {faits,total}`, `vague` présents ; `statuts` contient `recette` ; `foot`/`st` inchangés (témoin : `test-cockpit-projet-graphe.sh` vert) | données | `test-cockpit-projet-champs.sh` |
| FORM-07 | 0 carte `file` Backlog dans la vue ; liste rendue ; « DIFFÉRÉ » absent du pied | données + navigateur | `test-cockpit-couloirs.sh` |
| FORM-08 | texte visible de Projet sans « Élément », « module », « Mentions » ; panneau d'un plan : statut, vague, exigences ; texte d'exigence ≤ 1 fois ; « Retour » désactivé à pile vide | navigateur | `test-cockpit-projet-vocabulaire.sh` (part moteur après la 79) |
| FORM-09 | `v` bascule ; tri par colonne ; défaut liste à 390 px ; clé `localStorage` porte le lab | navigateur | `test-cockpit-couloirs.sh` |
| FORM-10 | minicarte présente ≥ 1 000 px souris, absente au tactile ; « N cartes par là » = compte hors champ ; `freeArea().w` identique tiroir Git ouvert/fermé ; `k ≥ 11/13` sur Code ; une seule formule (grep : 0 copie dans `76-*`, `40-tour.js`) | navigateur + grep | `test-cockpit-minicarte.sh` |
| FORM-11 | action « cadrer » → sélection et voisins dans `freeArea`, `k ≥ plancher`, `state.layout` inchangé | navigateur | `test-cockpit-minicarte.sh` (après lot A) |
| FORM-12 | ligne d'état : branche entière dans `title`, point du direct, « Mis à jour à HH:MM » ; sans `--terminal` 0 nœud `vf-term` ; à 390 px cibles ≥ 44 px | navigateur | `test-cockpit-ligne-etat.sh` |
| FORM-13 | ≤ 110 rangées au départ (rouge : ~1 000) ; worktrees repliés ; détail dans le volet bas à 1024×768 ; poignée flèches bornée et mémorisée ; `freeArea` et `state.t` inchangés à l'ouverture | navigateur | `test-cockpit-git-tiroir.sh` (sections ajoutées) ou suite neuve |
| FORM-14 | ratios mesurés (deux thèmes) ≥ seuils ; `font-variant-numeric: tabular-nums` ; teintes « ⋯ » = bureau ; `DESIGN.md` à jour ; ouvreur Git = 44 px (P78-D-34) | navigateur | `test-cockpit-jetons.sh` (après la 79) |
| FORM-15 | fragment `v,s,z,git` rejoué → même vue ; état des tiroirs gardé après changement d'onglet | navigateur | `test-cockpit-lien-vue.sh` (après lot A) |
| FORM-16 | clic d'onglet → aucun `Page.loadEventFired` ; Précédent/Suivant ; focus sur le titre ; titre « <Onglet> · <nom> » ; chaîne du terminal toujours dans le tampon ; amorce non réutilisable | navigateur | `test-cockpit-onglets.sh` (après la 79) |
| FORM-17 | toutes les suites du périmètre vertes macOS + Linux ; `test-cockpit-vendor.sh` V4 ; `check-version-sync.sh` § 9 | gates | commandes du job `gates` |

### Sampling Rate
- **Par tâche :** la suite du plan + `test-cockpit-vendor.sh`.
- **Par vague :** périmètre `ci-suites-perimetre.sh` du diff de la vague.
- **Gate de phase :** périmètre complet + job `gates`, macOS local et CI Linux.

### Wave 0 Gaps
- [ ] Extension de `ANNEAU` (X4) au `.card` d'un `g.node` focalisé — avant le plan FORM-01 (Piège 1).
- [ ] Ligne `vue=graphe` dans `naviguer()` + option de sortie — avant le plan des couloirs (Q3).
- [ ] F5.2 étendu au dictionnaire neuf, s'il est créé (Q1).

## Security Domain

| Catégorie ASVS | S'applique | Contrôle |
|---|---|---|
| V4 Contrôle d'accès | non (aucune route, P80-D-26) | — |
| V5 Validation / encodage | oui | rendu des couloirs depuis les données du lab par `SC.h()` / `textContent`, jamais d'HTML brut (suites `chaine-xss`, `lancer-xss`) |
| V8 Données | oui | préférences en `localStorage`/`sessionStorage` seulement, jamais dans `.planning/` ; aucune dernière commande (P67-D-14) |
| V14 Configuration | oui | aucune requête réseau neuve ; CSP de la page inchangée |

| Menace | STRIDE | Mitigation |
|---|---|---|
| Titre de phase piégé (`<img onerror>`) dans une carte de couloir | Tampering | échappement par `h()` ; témoin dans la suite des couloirs (forme de `test-cockpit-chaine-xss.sh`) |
| Lien de vue forgé (`#v=`, `z=` hors bornes) | Tampering | `readHash` valide `v`/`s` ; bornes de `z` (`clamp` 0,08-2,5) dans le patch |
| Action de palette qui envoie | Elevation | aucune action ne soumet (Q4) ; témoin : 0 `POST` |

## Sources

### Primaires (HAUTE)
- Code lu à `f763b556` : `viewer.html` (346, 582, 689, 1126-1155, 1343-1384, 1448-1530, 1839-1891, 2447-2498, 2515-2576),
  `build.mjs:430-449`, `78-vf-fr-dict-a.js:1-12`, `79-vf-fr-dict-b.js:1-3`, `80-vf-fr.js:1-60`, `40-tour.js:225-271`,
  `39-vf-tour-placement.js:1-30`, `72-vf-equipe.js:66-92`, `76-vf-git-entete.js:70-90`, `VENDORED.txt`, `synchro.sh:40-110`,
  `test-cockpit-vendor.sh:40-90`, `test-cockpit-chrome-fr.sh:1-140`, `test-cockpit-accessibilite.sh`, `chrome-accessibilite.mjs`,
  `chrome-session.mjs`, `chrome-parcours-tab.mjs`, `chrome-cdp.mjs`, `check-version-sync.sh:125-139`, `ci-shard-suites.sh:1-60`,
  `ci-suites-perimetre.sh:1-40`, `vf-cockpit-interface.json:40-50`, `vf-cockpit-project.mjs:20-24,46-54,120-126`,
  `78-CONTEXT.md:150-179`, `79-CONTEXT.md` (`origin/feat/phase-79-socle-cockpit` @ `6f66d878`, l.205-330).
### Secondaires (MOYENNE)
- https://www.w3.org/WAI/ARIA/apg/patterns/listbox/ ; https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/inert ;
  https://html.spec.whatwg.org/multipage/interaction.html#inert-subtrees
### Tertiaires
- Rapports d'éclaireurs `scout-projet.md`, `scout-canevas.md`, `scout-chrome.md` (non relus ligne à ligne ici).

## Metadata

**Confiance :** pile HAUTE (code lu) ; architecture HAUTE ; pièges navigateur MOYENNE (A1, A2 non mesurés).
**Date :** 2026-11-11. **Valide jusqu'à :** la fusion de la 79 (mécanismes de dictionnaire, lancement des suites, `amont/`).
