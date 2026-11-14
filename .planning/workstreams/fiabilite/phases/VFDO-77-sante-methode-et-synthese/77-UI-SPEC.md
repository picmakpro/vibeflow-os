---
phase: "77"
slug: "sante-methode-et-synthese"
status: approved
reviewed_at: 2026-11-11
shadcn_initialized: false
preset: none
created: "2026-11-11"
---

# Phase 77 — UI Design Contract

> Contrat visuel et d'interaction de la « Synthèse » du cockpit (onglet Projet) : dernière visite, burn-up du jalon, santé de la méthode, et le quatrième bloc (coût) réservé. Généré par gsd-ui-researcher, à vérifier par gsd-ui-checker.
> Il applique P77-D-01..18 (`77-CONTEXT.md`) sans en rouvrir aucune, dans les bornes de `DESIGN.md` (direction « Graphite ») et de `DESIGNS.md` § 8 et § 9. Tout point laissé ouvert est écrit « à trancher à l'exécution, borne X » (section « Points ouverts bornés »).
> Source de vérité des valeurs : le CSS du cockpit (`viewer.html`, `ui/00-vibeflow.js`). Si une valeur d'ici diverge, le CSS fait foi et ce fichier se corrige.

Convention de lecture des chaînes : les textes entre « » sont exacts. L'espace avant `:`, `;`, `%`, `h` (heure) et entre un nombre et son unité (Ko, jetons, lignes) est insécable (U+00A0), comme dans le reste du cockpit. Un témoin compare après normalisation de U+00A0 en espace simple, sans tenir compte de la casse de l'initiale.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (HTML, CSS et JS vanilla servis en local ; pas de shadcn, pas de Tailwind, pas de framework) |
| Preset | not applicable |
| Component library | none : classes du cockpit réutilisées (table « Classes du cockpit réutilisées ») |
| Icon library | pictos au trait en SVG inline du cockpit : `svg.i`, 16 × 16 px, `stroke: currentColor`, épaisseur 1,75, extrémités arrondies, sans remplissage (`DESIGN.md` § 7) |
| Font | Inter (`--sans`) et JetBrains Mono (`--mono`), embarquées à l'assemblage, aucun CDN |
| Thème | sombre d'abord ; thème clair complet ; chaque écran se vérifie dans les deux |

Classes du cockpit réutilisées (relevées dans `ui/00-vibeflow.js`, `ui/20-health.js` et `viewer.html`, 2026-11-11 ; liste non exhaustive, jamais une liste fermée) :

| Classe | Source | Usage dans la Synthèse |
|--------|--------|------------------------|
| `.sec`, `.sec h3`, `.sec h3 .c` | `viewer.html` | un bloc du panneau, son titre 12,5 px / 500 / `--text-3` |
| `.pt`, `.pd`, `.more`, `.list`, `.row`, `.rn`, `.rd`, `.rc`, `.actions` | `viewer.html` | titre 20 px, texte, « et N autres », ligne-résumé |
| `.btn`, `.btn.soft` | `viewer.html` | « Tout vu », « Fermer la synthèse », « Relire les jauges » |
| `.vst`, `.vst-done`, `.vst-active`, `.vst-recette`, `.vst-todo`, `.vst-blocked`, `.vst-tolere`, `.vst-ignore`, `.vst-info`, `.vst-abandonnee` | `ui/00-vibeflow.js` | glyphe + mot : seules les FORMES sont reprises ; la teinte est neutralisée (voir « Color ») |
| `.vf-bar` | `ui/00-vibeflow.js` | barre 6 px, piste `--raise-2`, remplissage `--text-3` |
| `.vf-link` | `ui/00-vibeflow.js`, `ui/70-vf-live.js` | ligne de phase cliquable (`data-vf-go`) |
| `details.vf-tech` | `ui/00-vibeflow.js` (onglet Projet) | repli « Liste datée » |

---

## Spacing Scale

Grille FERMÉE du cockpit (P71.5-D-01, `viewer.html` `:root`). Le fichier neuf n'écrit un espacement que par ces jetons, un jeton sémantique, un `calc()` de jetons, `0` ou `auto` :

| Token | Value | Usage dans la Synthèse |
|-------|-------|------------------------|
| `--sp-2` | 2px | écart entre deux lignes de liste (`.list` gap), padding vertical de `.vst`, filet entre barre et verdict |
| `--sp-4` | 4px | écart nom–barre d'une jauge, `.sec` bas, padding vertical d'un repli |
| `--sp-6` | 6px | marge sous `.pt`, écart glyphe–libellé, marge haute de la barre (`.vf-bar`) |
| `--sp-8` | 8px | padding vertical d'une ligne (`--inset-row`), marge sous un `h3`, écart de deux boutons |
| `--sp-12` | 12px | écart nom–valeur d'une jauge, marge haute du graphe, `--inset-box`, marge haute d'un groupe |
| `--sp-16` | 16px | marge haute d'un `h4` de groupe de jauges, `--edge` |
| `--sp-20` | 20px | `--inset-panel` : padding horizontal d'un `.sec` |
| `--sp-24` | 24px | `--gap-section` : entre deux blocs (déjà porté par `.sec`) |
| `--sp-32` | 32px | non utilisé par la Synthèse (reste dans la grille) |

Exceptions écrites, liste fermée :
- 2 et 6 ne sont pas des multiples de 4 : ce sont des demi-pas de la grille fermée du cockpit, repris tels quels, jamais des valeurs libres.
- Valeurs interdites : 10, 14, 18, 22 et toute valeur hors du tableau (marges négatives des jetons de la grille admises, comme `.list` : `calc(-1 * var(--sp-12))`).
- Filets et bordures : 1 px (`--hair`). Barre `.vf-bar` : 6 px (hérité). Traits de la courbe : 1,5 et 2 px (épaisseur de tracé SVG, pas un espacement).
- Hauteurs de contrôle héritées : `.btn` 36 px, `.actions .btn` 34 px, 44 px en tactile et jusqu'à 999 px (voir « Responsive »).
- Géométrie interne du SVG (viewBox 320 × 160) : unités du graphe, pas des pixels d'écran ; ni témoin d'espacement ni valeur CSS.
- Aucun `padding`/`margin`/`gap`/`top`/`left` en dur dans le fichier : les témoins W5 le vérifient sur le style calculé.

Gabarit du panneau (non écrit par ce fichier, jamais modifié) : `--panel-w` 360 px (redimensionnable, `panelWidth`), padding `.sec` 20 px, soit **320 px de contenu** à la largeur par défaut. Largeurs de conception : référence 320 px, minimum tenu 264 px (feuille du téléphone sur un écran de 360 px).

---

## Typography

Quatre tailles ; ce fichier ajoute deux graisses, 500 et 600 ; le corps de texte garde la graisse 400 héritée du cockpit. Toutes ces valeurs sont déjà celles du cockpit.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Titre de panneau (`h2.pt` « Synthèse ») | 20px | 600 | 1.3 (hérité de `.pt`) |
| Corps (`.pd`, phrases d'aide de l'en-tête de panneau) | 13.5px | 400 hérité, jamais redéclaré | 1.6 (hérité de `.pd`) |
| Notes et aides internes aux blocs (`p.pd` posé dans un `.sec.vf-sy`, classe `vf-sy-note`) | 12.5px | 400 hérité | 1.45 ; seule cette classe redéclare la taille, jamais `.pd` |
| Libellé et valeur (titre de bloc `h3`, nom de jauge, valeur, ligne de phase, tête « N sur M · P % » en 600) | 12.5px | 500 (600 pour la tête et le titre) | 1.4 |
| Micro (mot de verdict `.vst`, étiquettes d'axe, étiquettes directes, notes de pied, chemins en mono) | 11px | 500 | 16px (hérité de `.vst`) ; 1.45 ailleurs |

Règles :
- Graisses déclarées par le fichier neuf : **500 et 600 seulement**. Le 400 du corps est hérité, le 700 est interdit.
- Chiffres : `font-variant-numeric: tabular-nums` sur toute valeur, tête et date (comme `.stats b`).
- JetBrains Mono (11 px / 500, `--text-3`) pour les seuls identifiants : chemin relatif d'un fichier mesuré (`gouvernance/STATE.md`). Jamais pour un libellé.
- Aucun titre en capitales espacées (« kicker ») ; aucune taille hors du tableau (pas de 11,5, 12, 15, 17).
- Étiquettes SVG : `font: 500 11px var(--sans)`, `fill: var(--text-3)`.

---

## Color

Aucune couleur nouvelle, aucune variable nouvelle. Neutres de « Graphite » uniquement dans la Synthèse (P77-D-02) : le fichier neuf n'écrit aucune couleur littérale (ni `#`, ni `rgb(`, ni nom de couleur) ; seulement `var(--…)`, `currentColor`, `transparent` et `black` dans les masques SVG de glyphe.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60 %) | `--elev` (surface du panneau) sur `--bg` | fond du panneau et des blocs |
| Secondary (30 %) | `--raise-2` (piste de barre), `--hair` / `--hair-2` (filets), `rgba(var(--ink), .06)` (survol d'une ligne, fond d'un `.btn.soft`) | pistes, filets, survol, boutons |
| Accent (10 %) | aucun : `--accent` = `--on` (neutre). Emphase neutre `--text` | voir ci-dessous |
| Destructive | aucun | aucune action destructive (voir « Copywriting Contract ») |

Accent reserved for : rien. Le « 10 % » est tenu par l'emphase `--text`, réservée au nom d'une jauge, à sa valeur, à la tête « N sur M · P % » et au titre du panneau. La seule autre teinte est l'anneau de focus `--ring`.

Hiérarchie de texte : `--text` (nom, valeur, tête), `--text-2` (mot de verdict, phrase d'aide), `--text-3` (titre de bloc, chemin, note, étiquette de courbe, série « closes »), `--text-4` (série « périmètre » en tirets, « et N autres »).

Glyphes de verdict et d'état : un glyphe de FORME distincte plus un mot, jamais la couleur (`DESIGN.md` § 9). Les formes viennent des classes `.vst-*` existantes (masques SVG de `ui/00-vibeflow.js`) ; **leur teinte est neutralisée** dans le périmètre de la Synthèse par une seule règle `.vf-sy .vst { --c-st: var(--text-2); }` (spécificité supérieure aux règles `.vst-*`, qui posent `--st-*`, `--sev-medium`, `--sev-high`). Le mot reste en `--text-2`.

Barres :
- Jauge : toujours neutre (`.vf-bar`, remplissage `--text-3` sur piste `--raise-2`), jamais `.st-active` (une jauge n'est pas un élément « en cours »).
- Dépassement : remplissage plein à 100 % et **hachuré** (motif informatif, arrêts francs ; masque SVG, tuile 8 × 8, trait à 45° de 3 px, même technique `mask` + `encodeURIComponent` que les glyphes, jamais de `#` littéral, jamais de dégradé CSS).
- Burn-up : pas de barre ; la courbe la remplace.
- L'exception « barre d'un élément en cours prend `--warn-text` » du cockpit ne s'applique à aucune barre de la Synthèse.

Interdits (témoin W4) : fond teinté, pastille pleine, badge, liseré ou contour coloré, halo, ombre autre que celle du panneau, dégradé décoratif, texte coloré hors des quatre niveaux ci-dessus, tout élément de la Synthèse dont une couleur calculée n'est pas un neutre (canaux R, G, B égaux à ±2).

---

## Contrat de la Synthèse

### 1. Entrées du rendu (ce que la page reçoit ; formes exactes fixées par les plans)

| Besoin du rendu | Source (décision) | Si absent |
|-----------------|-------------------|-----------|
| Phases, états, jalons, `meta.vf.burnup` (`N`, `M`, `P` produit par `piedJalon`/`pct`, dates ISO de clôture et d'inscription, phases sans date) | `G.meta.vf` (P77-D-11, D-13, D-14) | bloc 2 « indisponible » ou « aucun jalon » |
| Jauges : par mesure, type, chemin relatif, valeur, budget, unité, mot de verdict en jeton fermé, cause d'indisponibilité en liste fermée, ligne de baseline si le gate en a une, instant de mesure | `GET /api/vf/methode` (P77-D-03, D-04, D-05) | bloc 3 « indisponible » |
| Rangées git et sommet mémorisé | `GET /api/vf/git` (P77-D-10) | ligne « Commits : non lus » |
| Travailleurs `termine` et `finAt`, agents qui attendent, nœuds échoués, entrées de blocage du STATE nettoyées | `who@2`, signal, route de lecture confinée (P77-D-10, A12 de la 79) | ligne omise ; jamais « 0 » |
| Identifiant de lab | `GET /api/vf/modeles` (P77-D-07) | repère de visite indisponible |
| Coût par voie (jetons, durées, rôle, rattachement) | `GET /api/vf/frise` (P77-D-15) | bloc 4 absent |

Règles transverses :
- Tout texte venu du STATE, de git ou d'une session s'écrit par `h()` (échappement) ou `textContent`, jamais en `innerHTML` brut.
- Le rendu n'affiche jamais un chemin absolu : un champ de chemin qui commence par `/` ou `~` n'est pas affiché et sa ligne dit « Format non reconnu ».
- Le rendu ne recalcule ni un pourcentage, ni un verdict, ni une mesure : il affiche ce que la source donne. Un jeton de verdict inconnu dit « Format non reconnu », jamais une valeur.
- Le rendu n'appelle jamais `/api/vf/doing` ni `/api/vf/transcript` ; il n'affiche, ne garde et n'exporte jamais la dernière commande d'un agent ni une sortie d'outil.
- Aucune écriture : un seul `GET` neuf (`/api/vf/methode`, à l'ouverture) ; ni `POST`, ni appel réseau sortant.

### 2. Bouton d'en-tête

| Élément | Contrat |
|---------|---------|
| Création | `Floorplan.addHeaderButton({ id: 'btn-synthese', label: 'Synthèse', svg, title, onClick })`, sur l'onglet Projet SEULEMENT et seulement quand le cockpit est servi (jeton de serveur présent). Absent sur Code, sur Équipe, sur une page exportée ou ouverte en fichier. |
| Libellé (`label`, `.bl`) | « Synthèse », constant. Aucun nombre dans le libellé (l'en-tête déborde déjà à la limite : P70-D-22). Le libellé ne s'affiche qu'à partir de 1 600 px ; en dessous le bouton est une icône seule (règle existante du cockpit). |
| Glyphe | escalier du burn-up, 24 × 24, tracé au trait comme `svg.i` : `<path d="M4 19h16M5 15h4v-4h4V8h4V5"/>` (valeur de départ ; seule la forme « escalier sur une ligne de base » est fixée, voir « Points ouverts bornés »). Pas un faux ami : ni pouls (Santé), ni roue (Récent), ni boussole (visite). |
| Position | juste après `#btn-health` dans `#hdr-ext` (`#btn-health.after(btn)`), donc à la place exacte du bouton Santé masqué sur Projet (DG-15). Si `#btn-health` est absent (réécriture de l'en-tête par la Phase 80), le bouton reste à la fin de `#hdr-ext` : l'API fait foi, jamais un sélecteur de position. |
| Compte et résumé | AUCUNE pastille, AUCUN badge (`.badge`), AUCUN nombre sur le bouton. Le résumé vit dans `title` et `aria-label` (même texte) et dans la ligne-résumé. Ainsi le menu « Plus d'actions » du téléphone, qui lit `.bl` puis `aria-label` puis `title`, dit « Synthèse ». |
| `title` / `aria-label` | quand la synthèse a du contenu : « Synthèse : {résumé} depuis votre dernière visite » ; sinon : « Synthèse du projet ». Il commence toujours par « Synthèse » (nom accessible contenant le libellé visible). Mis à jour à chaque recalcul, sans annonce. |
| `aria-controls` / `aria-expanded` | `aria-controls="panel"` ; `aria-expanded` = « true » tant que `#panel` contient la Synthèse (`#panel > .vf-sy`) et que `body` n'a pas `no-panel`, sinon « false ». Suivi par `MutationObserver` comme `ui/73-vf-tiroir-travail.js`. |
| Clic ou Entrée ou Espace | ouvre la Synthèse ; refaire le geste la ferme (retour au panneau d'ensemble de Projet, comme `closePanel` de la Santé du code). |
| Ouverture d'office | jamais, même à la première visite : une proposition ne prend jamais le focus ni le panneau (Q5). |
| Ligne-résumé (`overview`) | `Floorplan.addPanelSection('overview', () => ({ html, bind, top: true }))` : avec `top: true` le viewer la pose juste après la première section du panneau (titre, « Maintenant », compteurs), donc AVANT « Prochaines phases », visible à l'arrivée. Sans prise en charge de `top`, elle tombe en fin de panneau et le bouton reste l'entrée principale. |
| Anatomie de la ligne-résumé | un `.sec` : `h3` « Synthèse » ; un `<button type="button" class="row vf-rep" data-vf-sy-resume>` (focusable, contrairement à une ancre sans `href`) : `.rt` > `.rn` = résumé, `.rd` = « Burn-up du jalon et santé de la méthode », `.rc` = chevron `iconI('right')`. Pas de point `.dot`, pas de glyphe coloré. Reset de bouton : `background: none; border: 0; font: inherit; color: inherit; text-align: left; width: 100%`. La classe `vf-rep` laisse le résumé passer à la ligne. |
| Texte de la ligne-résumé | « Depuis votre dernière visite : 2 phases, 14 commits » ; catégories non nulles dans l'ordre phases, commits, sessions, blocages, séparées par « , » (voir « Copywriting Contract » pour chaque forme). Rien de neuf : « Rien de nouveau depuis votre dernière visite ». Sans repère : « Première visite sur ce poste ». Lab inconnu : « Repère de visite indisponible ». |
| Aucune jauge au chargement | ni le bouton ni la ligne-résumé ne portent un chiffre de santé : les gates ne tournent qu'à l'ouverture de la Synthèse (P77-D-04). |

### 3. Panneau : structure et ordre

La Synthèse occupe le panneau en place (`Floorplan.showPanel(html, bind)`), sur le patron de la Santé du code. Ce fichier n'écrit AUCUNE règle sur `#panel` : largeur, hauteur, position, fond, ombre, rayon et transitions restent ceux du viewer. Elle ne pousse jamais la carte (le panneau est `position: fixed`) ; elle ne crée ni tiroir, ni troisième tiroir, ni quatrième onglet. Le tiroir Git (à gauche) et la Synthèse (à droite) coexistent : la Synthèse n'est pas `.vf-whop`, donc elle ne déclenche pas l'exclusion Git / « Au travail » sous 1 280 px ; elle suit la règle du détail d'une carte (PU-G-203). Ouvrir « Au travail » remplace la Synthèse, et inversement : un seul contenu de panneau à la fois.

Structure (les blocs sont des `.sec` enfants directs de `#panel`, pour garder les règles `:first-child` / `:last-child` du viewer ; classe commune `vf-sy`) :

```
#panel
├─ .sec.vf-sy  (tête)      h2.pt « Synthèse » · p.pd · .actions [Fermer la synthèse]
├─ section.sec.vf-sy  [data-vf-sy-bloc="visite"]   h3 « Depuis votre dernière visite »
├─ section.sec.vf-sy  [data-vf-sy-bloc="burnup"]   h3 « Burn-up du jalon »
├─ section.sec.vf-sy  [data-vf-sy-bloc="methode"]  h3 « Santé de la méthode »
└─ section.sec.vf-sy  [data-vf-sy-bloc="cout"]     h3 « Coût par phase et par étage · dernières 24 h »   (réservé, voir 7)
```

- Ordre fixe, jamais réordonné par l'importance ni par la présence de changements : visite, burn-up, santé, (coût). Chaque `section` porte `aria-labelledby` vers son `h3` (`id="vf-sy-t-visite"`, `-burnup`, `-methode`, `-cout`).
- Un rafraîchissement de données ne rappelle JAMAIS `showPanel` : seul le contenu d'un conteneur de bloc est remplacé, de sorte que le focus et le défilement ne bougent pas (défaut déjà vécu, UIFN-12).
- Fermeture automatique quand une autre carte est sélectionnée : `SC.on('panel', …)` appelle `SC.closePanel()` si `[état sélectionné, conteneur]` a changé depuis l'ouverture (même règle que la Santé du code).
- Tête : `h2.pt` « Synthèse », `p.pd` « Ce qui a bougé, où en est le jalon, et si les règles de méthode tiennent. », puis `.actions` avec « Fermer la synthèse » (`.btn.soft`, icône `x`).

### 4. Bloc 1 : Depuis votre dernière visite

Anatomie, de haut en bas ; chaque catégorie n'est rendue que si elle est non nulle (sauf les réserves de 24 h, voir plus bas) :

| Zone | Contrat |
|------|---------|
| Ligne de base | `p.pd` 12,5 px, `--text-3` : « Depuis {quand}. » avec {quand} ∈ « aujourd'hui, 14 h 05 » · « hier, 18 h 42 » · « le 9 nov., 18 h 42 » (jour du mois, mois abrégé de la table fermée ci-dessous, « 1er » pour le premier du mois, année ajoutée seulement au-delà de 300 jours). |
| Phases | ligne de tête 12,5 / 500 « 2 phases ont avancé » ; puis au plus 5 lignes `a.vf-link[href="#r={id}"][data-vf-go={id}]` : `.vst` neutre de l'état PRÉSENT (formes `vst-done`, `vst-active`, `vst-recette`, `vst-todo`) + « Phase 73 · Gouvernance au cockpit » + en micro `--text-3` « avant : À faire » ou « nouvelle phase ». Au-delà de 5 : `.more` « et 3 autres ». Sans identifiant de carte, la ligne est un `span` (jamais un lien mort). |
| Commits | « 14 commits sont arrivés » ; « Plus de 500 commits sont arrivés » quand le sommet mémorisé sort de la fenêtre lue ; lien `.vf-link` « Voir dans Git » (clique l'ouvreur Git de l'en-tête, jamais une route : voir « Points ouverts bornés »). Pas de liste de commits, pas de sujet ni d'auteur. Git indisponible : « Commits : non lus, le dépôt git est indisponible. » (jamais « 0 commit »). |
| Sessions | « 3 sessions se sont terminées » ; avec la réserve des 24 h : « Au moins 3 sessions se sont terminées » suivi, sur la même ligne en micro, de « Seules les 24 dernières heures sont gardées. » ; lien `.vf-link[href="equipe.html"]` « Voir dans l'onglet Équipe ». Jamais de nom de session, de dernière commande ni de transcript. |
| Blocages nouveaux | tête « 1 nouveau blocage » ; une ligne par blocage (3 au plus puis `.more` « et 2 autres ») : `.vst` forme `vst-blocked` + mot « Bloqué » + texte nettoyé, coupé au mot à 140 caractères avec « … » (le texte complet en `title`). |
| Blocages levés | une ligne `.vst` forme `vst-done` + mot « Levé » (« Levés » au pluriel) + « 2 blocages » ; comptés seulement (leur texte n'est pas gardé). |
| Geste | bouton « Tout vu » (`.btn.soft`, dans `.actions` sous la liste), présent seulement quand au moins une ligne est affichée. |

Table fermée des mois : janv., févr., mars, avr., mai, juin, juil., août, sept., oct., nov., déc.

États du bloc :

| État | Rendu |
|------|-------|
| Première visite sur ce poste (aucune valeur, valeur corrompue, trop grosse ou de version inconnue : même rendu, sans exception) | `h3` puis « Première visite sur ce poste » (12,5 / 500 `--text`) et `p.pd` « Le cockpit garde le repère de cette visite dans ce navigateur, pour vous dire la prochaine fois ce qui a changé. » Aucun bouton « Tout vu ». |
| Rien de nouveau | `p.pd` « Rien de nouveau depuis {quand}. » Pas de bouton. |
| Quelque chose de neuf | ligne de base, catégories non nulles, « Tout vu ». |
| Visite de plus de 24 h et aucune session visible | la catégorie Sessions est rendue : « Aucune session terminée dans les 24 dernières heures. Seules les 24 dernières heures sont gardées. » (jamais un « 0 » sans cette réserve). |
| Lab inconnu (serveur muet, identifiant de lab non reçu) | « Repère de visite indisponible : le cockpit ne connaît pas l'identifiant de ce projet. » Rien n'est rangé, aucun repli par origine. |

Geste « Tout vu » :
- Effet : fait avancer le repère de base à maintenant ; le bloc passe à « Rien de nouveau depuis aujourd'hui, {heure}. » ; la ligne-résumé et le `title` du bouton suivent.
- Focus : le bouton disparaît ; le focus passe au `h3` du bloc (`tabindex="-1"`, `focus({ preventScroll: true })`), jamais perdu sur `body`.
- Annonce : zone vive polite « Synthèse remise à zéro. »
- Autres onglets du navigateur : ils reçoivent l'événement `storage` et mettent à jour, en silence, leur ligne-résumé, le `title` du bouton et le bloc 1 s'il est ouvert, sans déplacer le focus ni annoncer.
- Pas de confirmation : le geste n'efface que le repère de visite (bénin, répétable, son effet est dit sur le bouton par `title` : « Remettre la synthèse à zéro : seuls les changements à venir seront signalés »). Pas d'annulation, pas de bouton « Oublier » (un ajout, un retrait).

### 5. Bloc 2 : Burn-up du jalon

Tête et aide :
- Tête (`p`, 12,5 px / 600 `--text`, tabulaires ; une seule valeur retenue : 12,5 px, comme la table de typographie) : « 8 sur 16 · 50 % » (« {N} sur {M} · {P} % »), recopiée du champ `meta.vf.burnup` produit par la fonction du pied de jalon (`piedJalon`/`pct`, CKPT-16). Jamais recalculée côté page. Elle porte la même valeur que le pied de la carte de jalon (témoin W8).
- Aide (`p.pd` 12,5 px, `--text-3`) : « Phases closes du jalon {clé}, sans pondération par les plans. »

Courbe (SVG en ligne, desktop, panneau de 701 px et plus) :

| Élément | Contrat |
|---------|---------|
| Conteneur | `<svg class="vf-sy-courbe" viewBox="0 0 320 160" role="img" aria-label="…" focusable="false">`, `width: 100%; height: auto; display: block`, marge haute `--sp-12`. CSP : SVG en ligne dans le DOM, aucune image externe. |
| Zone de tracé | x de 28 à 236, y de 16 (haut, valeur M) à 128 (ligne de base, valeur 0). `x(t) = 28 + 208 · (t − t0) / (tN − t0)` ; `y(v) = 128 − 112 · v / M`. t0 = la plus ancienne date connue du jalon (inscription ou clôture) ; tN = aujourd'hui tant que le jalon n'est pas entièrement clos, sinon la dernière clôture ; au moins 1 jour d'écart. |
| Séries (deux, escalier) | `M x(t0) y(v0) H x(t1) V y(v1) H … H x(tN)`. **Clôtures** : trait plein 2 px `--text-3`, part de 0 à t0. **Périmètre** : tirets `4 4`, 1,5 px, `--text-4`, part du nombre de phases entrées à t0 ; les phases inscrites sans date y sont comptées dès t0. Le périmètre finit donc toujours à M. |
| Axes | une seule ligne de base (`--hair-2`, 1 px) ; pas de grille. Étiquettes 11 px / 500 `--text-3` : « 0 » et « {M} » à gauche (x = 20, ancrage fin), première date à gauche sous la base (ancrage début) et dernière date à droite (ancrage fin). Dates au format de la table des mois. |
| Étiquettes directes | à droite du tracé, x = 244, ancrage début : « périmètre 16 » à la hauteur de la fin de la série périmètre ; « closes 7 » à la hauteur de la fin de la série clôtures (nombre de marches placées). « closes » est toujours l'étiquette la plus basse : à moins de 14 unités de « périmètre », elle descend jusqu'à 14. Aucune légende, aucun nuancier. |
| Support non coloré | les deux séries se distinguent par le trait (plein / tirets), l'épaisseur et le gris, et par leur étiquette directe : jamais par une teinte. |
| `aria-label` | « Burn-up du jalon {clé} : {N} phases closes sur {M}, {P} %. Périmètre de {a} phases le {d1} à {M} phases le {d2} ; {k} phases closes datées entre le {d3} et le {d4}. » (singulier géré). |
| Animation | aucune : pas de tracé progressif, pas de transition (rien à couper en mouvement réduit). |

Équivalent texte (toujours présent) :
- Un `<ol class="vf-sy-liste">` : une ligne par date distincte où le périmètre ou les clôtures changent, `<time datetime="AAAA-MM-JJ">` : « 3 nov. · périmètre 11 · closes 1 : Phase 67 » (valeurs cumulées ; les phases closes ce jour-là nommées après « : », omises s'il n'y en a pas). Police 12,5 px / 500 `--text-2`.
- Sur desktop, la liste est dans un repli fermé `<details class="vf-tech"><summary>Liste datée</summary>…</details>` (clavier : Tab, Entrée ou Espace).
- Au téléphone (≤ 700 px) : la courbe n'est pas rendue du tout et la liste est affichée ouverte, sans repli. Le rendu choisit par `matchMedia('(max-width: 700px)')` et se refait au changement de largeur ; aucun double contenu lisible par un lecteur d'écran.

Notes sous le graphe (`p.pd` 12,5 px, `--text-3`, neutres, jamais d'estimation) :
- phase close sans date écrite : « Close, date non écrite : Phase 70. Elle compte dans le pourcentage, sans marche sur la courbe. » (pluriel : « Closes, date non écrite : Phases 70 et 71. Elles comptent dans le pourcentage, sans marche sur la courbe. ») ;
- phase inscrite sans date : « Inscrite sans date : Phase 79. Comptée dès l'ouverture du jalon, le 1er nov. » (pluriel accordé).
- Liste de phases : « Phase 70 » · « Phases 70 et 71 » · « Phases 70, 71 et 72 ».

États : aucun jalon en cours : « Aucun jalon en cours : pas de burn-up à tracer. » ; champ `meta.vf.burnup` absent : « Burn-up indisponible : le cockpit n'a pas reçu les dates du ROADMAP. » Dans les deux cas, ni courbe vide ni « 0 sur 0 ».

### 6. Bloc 3 : Santé de la méthode

Un seul `GET /api/vf/methode` à l'OUVERTURE de la Synthèse (jamais à l'arrivée sur la page, jamais en boucle). Les valeurs viennent du gate ; la page n'en recalcule aucune.

Anatomie d'une ligne de jauge (`<li class="vf-sy-jauge" data-vf-sy-jauge="{type}" data-verdict="{ok|surveiller|depasse|na|indispo|format}">`, dans un `<ul>` par groupe) :

```
Taille de STATE.md                          21 sur 8 Ko      ligne 1 : nom (12,5/500 --text) · valeur (12,5/500 --text-2, tabulaire, ne passe pas à la ligne)
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓   ligne 2 : barre .vf-bar 6 px, aria-hidden (hachurée si dépassé)
✕ Dépassé   gouvernance/STATE.md                  ligne 3 : .vst (glyphe + mot, 11/500) · chemin du plus gros en mono 11 px --text-3
```

- Grille : `display: grid; grid-template-columns: 1fr auto; column-gap: var(--sp-12); row-gap: var(--sp-4); padding: var(--sp-8) 0`. Barre et ligne 3 sur toute la largeur.
- Valeur : « {valeur} sur {budget} {unité} » (« 21 sur 8 Ko », « 39 sur 20 sujets », « 11 sur 3 worktrees actifs ») ; budget 0 : « {valeur}, budget 0 ». Largeur de barre = `min(100, valeur / budget)` en pourcentage ; budget 0 : 0 % si la valeur est 0, sinon 100 % hachuré.
- Un type à plusieurs mesures (STATE, ROADMAP, index MEMORY, agents, skills, worktrees par dépôt) = UNE jauge de synthèse (la mesure la plus proche ou au-delà de son budget, son chemin relatif en ligne 3) ; ses AUTRES mesures hors budget ou à surveiller suivent en sous-liste (`<ul>` de lignes plus compactes : chemin mono + « 21 sur 8 Ko » + `.vst`), 5 au plus, puis `.more` « et 4 autres ». Une mesure dans le budget n'est listée qu'une fois (dans la synthèse du type).
- Bloc `h3` suivi d'une ligne de bilan : « 11 jauges · 8 dans le budget · 3 dépassées » (catégories non nulles, accordées ; « à surveiller », « non applicables », « indisponibles », « format non reconnu »).

> Renvoi (planification, 2026-11-11) : les jetons de la première colonne sont ceux que le plan 77-01 FIXE en liste fermée dans la sortie TSV des gates (`OK`, `AVERTISSEMENT`, `DEPASSE`, `NON-VERIFIABLE`, `NON-APPLICABLE`) ; les jetons texte historiques cités ci-dessous (`OK+LIGNES-EN-HAUSSE`, `AVERTISSEMENT-ADR029`, `ARCHIVABLE`, `RANGEABLE`…) restent ceux de la sortie texte, inchangée, et se ramènent à ces cinq jetons côté gate. La version d'en-tête inconnue d'un TSV donne la jauge « Indisponible » (P77-D-05) ; « Format non reconnu » ne vaut que pour un jeton inconnu ou un champ de chemin rejeté.

Vocabulaire de verdict, FERMÉ (forme du glyphe reprise d'une classe `.vst-*` ; mot affiché ; teinte neutre) :

| Sens (jeton du gate, fixé par le plan 77-01) | Glyphe (classe) | Mot affiché | Barre |
|----------------------------------------------|-----------------|-------------|-------|
| dans le budget (OK, OK+LIGNES-EN-HAUSSE) | coche (`vst-done`) | Dans le budget | pleine proportion, neutre |
| avertissement d'agent, 251 à 300 lignes (AVERTISSEMENT-ADR029) | triangle « ! » (`vst-tolere`) | À surveiller | proportion, neutre |
| dépassé (DÉPASSÉ, DEPASSEMENT-*, AU-DESSUS-PLAFOND-*, ARCHIVABLE, RANGEABLE) | losange croisé (`vst-ignore`) | Dépassé | 100 %, hachurée |
| non applicable (NON-APPLICABLE ou code 2 du gate de densité hors dépôt de distribution) | anneau barré en diagonale (`vst-abandonnee`) | Non applicable dans ce lab | aucune |
| indisponible (gate absent, copie ancienne code 64, NON-VERIFIABLE, échéance dépassée) | anneau vide (`vst-todo`) | Indisponible | aucune |
| version d'en-tête ou jeton inconnu, champ de chemin absolu | anneau « i » (`vst-info`) | Format non reconnu | aucune |

- « Dépassé » se dit sans couleur par trois signes cumulés : le mot, le glyphe (losange croisé, forme unique dans le panneau), le motif hachuré de la barre ; la valeur « 21 sur 8 Ko » le chiffre.
- « Non applicable dans ce lab » et « Indisponible » n'affichent JAMAIS de valeur ni de « 0 » : pas de barre, pas de valeur, une ligne de raison en micro `--text-3` : non applicable, « Ce contrôle ne mesure que le dépôt de distribution de VibeFlow. » ; indisponible, selon la cause de la liste fermée de la route : « Le contrôle n'est pas installé. » · « Le contrôle installé est trop ancien. Mettez VibeFlow à jour : /vf-update. » · « Le contrôle n'a pas répondu à temps. » · par défaut « Mesure indisponible. » ; format non reconnu, « Le cockpit ne reconnaît pas la forme de cette mesure. »
- Socle de démarrage : ligne 3 ajoute, en micro `--text-3` : « Ligne de baseline : 2 610 jetons, mesure égale. » (ou « mesure au-dessus » / « mesure en dessous ») ; si le gate ne donne pas de baseline, la phrase est omise.

Groupes et ordre (l'ordre de P77-D-06, fixe ; jamais trié par gravité, pour que chaque jauge garde sa place) :

| Groupe (`h4`, 11 px / 500 `--text-3`, marge haute `--sp-16`) | Jauges, dans l'ordre | Unité, budget |
|---------------|----------------------|---------------|
| Planning | « Taille de STATE.md » (racine et compartiments) · « Paragraphe de prose de STATE.md » · « Sujets ouverts du BACKLOG » · « Longueur d'une entrée du BACKLOG » · « Sujets clos encore au BACKLOG » · « Taille de ROADMAP.md » (racine et compartiments) | Ko, 8 · lignes, 12 · sujets, 20 · lignes, 40 · sujets, 0 · Ko, 64 |
| Mémoire et chantiers | « Index de mémoire MEMORY.md » · « Worktrees actifs » | lignes, 200 · worktrees, 3 |
| Instructions des agents | « Agents : lignes du plus long » · « Skills : lignes du plus long » · « Socle de démarrage » | lignes, 300 (avertissement dès 251) · lignes, 500 · jetons, 2 000 |

Les budgets ci-dessus sont les défauts des gates ; le budget AFFICHÉ est toujours celui que le gate renvoie sur la ligne (variables `VF_*` comprises).

Chargement, fraîcheur, erreur :
- Pendant la lecture : le contenu du bloc est « Lecture des jauges en cours. » en `p.pd`, statique (aucun spinner, aucune animation), `aria-busy="true"` sur la `section`. Le reste du panneau reste utilisable.
- Pied de bloc (micro `--text-3`) : « Mesuré à 14 h 05 par les contrôles de la méthode. » (instant de la mesure, jamais l'heure d'affichage : le cache peut durer jusqu'à 5 min).
- Route muette ou en erreur : « Les jauges sont indisponibles : le serveur du cockpit n'a pas répondu. » + bouton « Relire les jauges » (`.btn.soft`, le focus reste dessus ; `aria-disabled` pendant l'appel, jamais `disabled`).
- Toutes les jauges « Indisponible » : une seule phrase « Aucune jauge n'a pu être lue. » + la raison commune + « Relire les jauges » ; pas douze lignes identiques.
- Le premier appel ne fige jamais le panneau : la route répond de façon asynchrone ; la page n'attend que son propre `fetch`.

### 7. Bloc 4 : coût par phase et par étage (RÉSERVÉ)

Emplacement, titre : quatrième `section` du panneau, `data-vf-sy-bloc="cout"`, `h3` « Coût par phase et par étage · dernières 24 h » (la fenêtre est dite dans le titre : AUDC-Q2). Il vient APRÈS le bloc 3 : sa présence ou son absence ne déplace donc aucun des trois autres.

Comportement quand il est absent : **rien n'est rendu** (aucun nœud DOM, aucun titre, aucun « à venir »). Motifs : un « à venir » est une promesse affichée en permanence tant que les Phases 74 et 79 n'ont pas livré, il ajoute un bloc de plus au panneau (« un ajout, un retrait »), il appelle la question du montant que le cockpit n'affichera jamais, et le panneau est déjà critiqué comme un mur de texte (`DESIGNS.md` § 8). « Absent » = la route `GET /api/vf/frise` répond 404, ou son schéma n'est pas `vibeflow/cockpit-frise@1`. Une route qui répond avec 400 (`bornes-invalides`, `champs-invalides`), 403, 503 (`emission-refusee`), 5xx ou une échéance dépassée donne le bloc avec « Coût indisponible : la frise n'a pas répondu. », jamais un bloc vide (un bloc qui existe ne disparaît pas sur une panne). Seuls 404 et un schéma autre que `vibeflow/cockpit-frise@1` rendent le bloc absent (P77-D-32).

Contrat de contenu quand il existe (revalidé le 2026-11-11 contre la Phase 79 à `c19c7461` et la Phase 74 à `33bb4aad` ; P77-D-28, P77-D-29, P77-D-32) :
- Aide `p.pd` : « Jetons et durée de travail. Jamais de montant. Les jetons couvrent la vie de chaque agent dans l'index des dernières 24 h, sans coupe à la seconde. » Aucun symbole ni mot de monnaie nulle part dans le bloc (témoin W17).
- Un `<table>` (en-têtes de colonne `<th scope="col">`, nom du tableau par `aria-labelledby` du `h3`) : colonnes « Phase » · « Jetons, hors cache » · « Cache lu et créé » · « Durée ». **Chiffre principal (P77-D-28)** : « Jetons, hors cache » = entrée + sortie ; le cache lu et le cache créé, qui comptent du texte relu et dominent les totaux, sont dans la colonne secondaire. Une ligne par phase du jalon ayant une activité, dans l'ordre numérique des phases, puis une ligne « Hors jalon » (voies rattachées à une phase connue hors du jalon en cours, P77-D-29), puis « Non rattaché » en dernier (voies sans clé `rattachement`, à `rattachement: null` ou dont la mission est introuvable, missions sans phase, voies hors mission) ; leurs jetons restent dans le total. Σ des lignes de phase + « Hors jalon » + « Non rattaché » = total. Chaque ligne se déplie (`<details>`) en une ligne par étage : « Manager », « Codeur », « Revue », « Audit », « Vérification », « Tête de session », « Autres », qui donne entrée, sortie, cache lu et cache créé.
- Formats : jetons « 1,2 M », « 340 k » ; durée « 3 h 10 », « 42 min ». Pas de barre.
- **Total coupé (BLOQUANT, P77-D-32).** Quand `tronque` est vrai, chaque total est un minorant : le mot « au moins » précède chaque total, et une phrase sous le tableau dit « Total partiel : au moins {jetons} jetons hors cache et {durée}, {N} voies omises. » (« 1 voie omise » au singulier) quand `voiesOmises` est un entier strictement positif, « … nombre de voies omises inconnu. » sinon, `voiesOmises` à 0 comprise (l'index a évincé des voies) ; jamais un total présenté comme complet, jamais un nombre inventé.
- **Les cinq états de `source.etat`** : `ok` avec des voies → le tableau ; `ok` sans voie → « Aucune activité dans les dernières 24 h. » (seul état qui le dit) ; `en-construction` → « L'index des sessions est en cours de construction : le coût apparaîtra à la fin de la lecture. » ; `partielle` → le tableau avec la phrase « Lecture partielle : certaines sessions n'ont pas été lues. » ; `forme-inconnue` → « Le cockpit ne reconnaît pas la forme des sessions de cette version de Claude Code. » ; `indisponible` → « Coût indisponible : la frise n'a pas répondu. ».

### 8. Retrait : la prose « Maintenant » (`lastDesc`)

- Ce qui disparaît : le paragraphe de prose recopié du STATE sous « Maintenant » (260 caractères coupés au mot, 12 px `--text-3`). Ce qui reste : « Maintenant · {jalon} », « Phase N — {nom} » avec sa pastille d'état, et l'avis « STATE.md semble périmé … » quand il s'applique. Le lecteur de `ui/00-vibeflow.js` tolère l'absence du champ (`V.lastDesc || ''`) : le fichier partagé n'est pas touché.
- Ce qui prend sa place : la ligne-résumé de la Synthèse (section 2), posée juste après le bloc « Maintenant » grâce à `top: true`, et le bouton. Rien n'est écrit à la place de la prose dans `.vf-now`.
- Repli (P77-D-12) : si la Phase 80 réécrit le panneau Projet avant l'exécution, la 77 retire le trio de compteurs `.vf-stats` à la place de la prose ; dans les deux cas aucune ligne de `ui/00-vibeflow.js` n'est éditée par la 77 (la ligne de lecture devenue morte est versée à la phase suivante qui y passe).
- À signaler à la recette humaine : ce qui est lu à l'ouverture de Projet change (A77-2).

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA (en-tête) | « Synthèse » |
| Primary CTA (dans le panneau) | « Tout vu » ; infobulle « Remettre la synthèse à zéro : seuls les changements à venir seront signalés » |
| Autres actions | « Fermer la synthèse » · « Relire les jauges » · liens « Voir dans Git », « Voir dans l'onglet Équipe » · repli « Liste datée » |
| Empty state heading (première visite) | « Première visite sur ce poste » |
| Empty state body (première visite) | « Le cockpit garde le repère de cette visite dans ce navigateur, pour vous dire la prochaine fois ce qui a changé. » |
| Empty state (rien de nouveau) | « Rien de nouveau depuis {quand}. » |
| Empty state (lab inconnu) | « Repère de visite indisponible : le cockpit ne connaît pas l'identifiant de ce projet. » |
| Empty state (aucun jalon) | « Aucun jalon en cours : pas de burn-up à tracer. » |
| Empty state (bloc 4 sans activité) | « Aucune activité dans les dernières 24 h. » |
| Error state (jauges, route) | « Les jauges sont indisponibles : le serveur du cockpit n'a pas répondu. » puis « Relire les jauges » |
| Error state (jauge) | « Indisponible » + raison de la liste fermée (« Le contrôle n'est pas installé. », « Le contrôle installé est trop ancien. Mettez VibeFlow à jour : /vf-update. », « Le contrôle n'a pas répondu à temps. », « Mesure indisponible. ») |
| Error state (burn-up) | « Burn-up indisponible : le cockpit n'a pas reçu les dates du ROADMAP. » |
| Error state (commits) | « Commits : non lus, le dépôt git est indisponible. » |
| Error state (coût) | « Coût indisponible : la frise n'a pas répondu. » |
| Destructive confirmation | aucune action destructive dans cette phase. « Tout vu » n'efface que le repère de visite de ce navigateur : pas de confirmation (bénin, répétable, effet dit par l'infobulle). L'oubli complet passe par l'effacement des données du site (dit dans la documentation du module, P77-D-09). |

Chaînes de la synthèse, par contexte (singulier / pluriel exacts) :

| Id | Copy |
|----|------|
| Titres | « Synthèse » · « Depuis votre dernière visite » · « Burn-up du jalon » · « Santé de la méthode » · « Coût par phase et par étage · dernières 24 h » |
| Intro du panneau | « Ce qui a bougé, où en est le jalon, et si les règles de méthode tiennent. » |
| Ligne de base | « Depuis aujourd'hui, 14 h 05. » · « Depuis hier, 18 h 42. » · « Depuis le 9 nov., 18 h 42. » |
| Phases | « 1 phase a avancé » · « 2 phases ont avancé » · « avant : À faire » · « nouvelle phase » |
| Commits | « 1 commit est arrivé » · « 14 commits sont arrivés » · « Plus de 500 commits sont arrivés » |
| Sessions | « 1 session s'est terminée » · « 3 sessions se sont terminées » · « Au moins 1 session s'est terminée » · « Au moins 3 sessions se sont terminées » · « Seules les 24 dernières heures sont gardées. » · « Aucune session terminée dans les 24 dernières heures. Seules les 24 dernières heures sont gardées. » |
| Blocages | « 1 nouveau blocage » · « 2 nouveaux blocages » · mot « Bloqué » · « 1 blocage levé » · « 2 blocages levés » · mot « Levé » / « Levés » · « et 2 autres » |
| Ligne-résumé | « Depuis votre dernière visite : 2 phases, 14 commits » · « … : plus de 500 commits, au moins 3 sessions, 1 nouveau blocage » · « … : 1 blocage levé » · « Rien de nouveau depuis votre dernière visite » · « Première visite sur ce poste » · « Repère de visite indisponible » · sous-ligne « Burn-up du jalon et santé de la méthode » |
| Burn-up | « {N} sur {M} · {P} % » · « Phases closes du jalon {clé}, sans pondération par les plans. » · « périmètre {M} » · « closes {n} » · « Liste datée » · « 3 nov. · périmètre 11 · closes 1 : Phase 67 » · notes des phases sans date (section 5) |
| Jauges | bilan « 11 jauges · 8 dans le budget · 3 dépassées » · groupes « Planning », « Mémoire et chantiers », « Instructions des agents » · mots « Dans le budget », « À surveiller », « Dépassé », « Non applicable dans ce lab », « Indisponible », « Format non reconnu » · « Lecture des jauges en cours. » · « Mesuré à 14 h 05 par les contrôles de la méthode. » · « Aucune jauge n'a pu être lue. » · « Ligne de baseline : 2 610 jetons, mesure égale. » |
| Annonces (zone vive) | « Synthèse remise à zéro. » · « Jauges lues : 8 dans le budget, 3 dépassées. » · « Jauges indisponibles. » |

Règles de langue : tout texte est écrit en français AU POINT D'ÉMISSION de `ui/74-…` (jamais par le dictionnaire `78-vf-fr-dict-*` / `80-vf-fr.js`) ; les noms de fichiers (STATE.md, BACKLOG, ROADMAP.md, MEMORY.md, worktrees) restent tels quels, comme dans le cockpit. Les mots de verdict prennent la majuscule initiale. Aucun montant, aucune monnaie.

---

## Interaction, clavier, focus

| Geste | Contrat |
|-------|---------|
| Tab (en-tête) | `#btn-synthese` est atteignable dans l'ordre du DOM, à la place de `#btn-health` ; anneau `--ring` 2 px décalé de 2 px (règle commune de `ui/03-vf-accessibilite.js`, pas de règle neuve). |
| Entrée / Espace sur le bouton | ouvre (ou ferme) la Synthèse ; `aria-expanded` suit. |
| Focus à l'ouverture | sur le `h2.pt` « Synthèse » (`tabindex="-1"`, `focus({ preventScroll: true })`), comme le tiroir « Au travail » ; l'anneau se voit au clavier (`:focus-visible`), pas à la souris. |
| Ordre de Tab dans le panneau | « Fermer la synthèse » · liens de phases · « Voir dans Git » · « Voir dans l'onglet Équipe » · « Tout vu » · repli « Liste datée » · « Relire les jauges » (si affiché) · replis du bloc 4. Aucune étape sur une jauge (non interactive) ni sur la courbe. |
| Échap, focus dans le panneau ou sur `#btn-synthese` | ferme la Synthèse (`closePanel`), `stopPropagation` + `preventDefault` pour que le canevas ne remonte pas, et rend le focus à `#btn-synthese`. Si une surcouche est ouverte (`#palette.open`, `#flowmenu.open`, `#legend.open`, `#ctxmenu:not([hidden])`, `[role="dialog"]:not([hidden])`, `[aria-modal="true"]`), elle prend l'Échap d'abord. |
| Clic sur une phase | `[data-vf-go]` : le cockpit révèle la carte ; la sélection change, donc la Synthèse se ferme (règle « une autre carte sélectionnée »). Un clic au milieu ou Ctrl-clic suit le `href="#r=…"` sans casser. |
| « Tout vu » | voir bloc 1 : le focus passe au `h3` du bloc. |
| « Relire les jauges » | rejoue le `GET`, `aria-disabled="true"` pendant l'appel (jamais `disabled`), le focus reste sur le bouton ; à l'arrivée des jauges, le focus n'est PAS déplacé. |
| Rafraîchissement | aucune donnée qui arrive (jauges, direct, `storage`) ne déplace le focus ni le défilement du panneau ; aucun `showPanel` de rafraîchissement. |
| Souris | survol d'une ligne cliquable : `.row:hover` et `.vf-link:hover` existants (fond neutre) ; jamais de survol sur une jauge. |
| Raccourcis | aucun raccourci neuf (`/`, `⌫` et `Échap` du cockpit restent seuls). |

## Accessibilité

- Rôles : `section` + `aria-labelledby` par bloc ; `h2` > `h3` > `h4` sans saut ; listes en `ul`/`ol` ; courbe `role="img"` avec `aria-label` complet (aucun enfant lu) ; dates en `<time datetime>` ; tableau du bloc 4 avec `th scope`. Pas de `role="dialog"` : le panneau est non modal, comme la Santé du code.
- Jauges : le sens est dans le TEXTE (nom, « 21 sur 8 Ko », mot de verdict). La barre est `aria-hidden="true"` ; pas de `role="meter"` (double lecture).
- Politique `aria-live` : UNE zone `<div class="sr" role="status" aria-live="polite" aria-atomic="true">` dans la tête du panneau (`.sr` = bloc masqué visuellement : `position: absolute; width/height: 1px; overflow: hidden; clip`). On n'y annonce que : jauges lues (une fois par ouverture, après l'arrivée), jauges indisponibles, « Synthèse remise à zéro. ». Jamais `assertive`. Rien n'est annoncé pour un rafraîchissement du direct, un événement `storage`, ni un changement de `title`. `aria-busy="true"` sur le bloc 3 pendant sa lecture.
- Contraste : textes sur `--surface`/`--elev` à 4,5:1 au moins (`--text` à `--text-4`, déjà mesurés par `DESIGN.md`) ; traits et glyphes à 3:1 (`--text-3` et `--text-4` contre `--surface` et `--bg`, deux thèmes) ; aucune teinte d'état.
- État sans couleur : tout verdict = glyphe de forme distincte + mot ; lisible en niveaux de gris et au daltonisme.
- Mouvement réduit : le fichier neuf ne déclare AUCUNE animation ni transition (pas de tracé progressif, pas de remplissage animé, pas de fondu). Les animations d'entrée du panneau (`panelIn`) sont déjà coupées par la règle `prefers-reduced-motion` de `ui/03-vf-accessibilite.js`. Témoin W14.
- CSP : aucun attribut `on*`, aucune URL `javascript:`, aucun `eval` ; les écouteurs sont posés par `addEventListener` ; les styles en ligne restent admis (`style-src 'unsafe-inline'`), les masques en `data:` aussi (`img-src 'self' data:`) ; `connect-src 'self'` suffit à l'unique `GET` neuf.

## Responsive

Points de rupture RÉELS du cockpit (inchangés, Q11) : ≤ 700 px téléphone ; ≤ 999 px tablette, ou tout écran tactile (`pointer: coarse`) ; ≤ 1 279 px en tactile ; 1 280 px et plus bureau. Côté en-tête, le libellé des boutons n'apparaît qu'à partir de 1 600 px (icône seule en dessous).

| Largeur | Comportement de la Synthèse |
|---------|------------------------------|
| ≥ 701 px | panneau flottant de droite, 360 px par défaut (redimensionnable), contenu de 320 px ; courbe SVG visible ; liste datée dans un repli fermé. Jamais de poussée de la carte. |
| ≤ 700 px | le panneau est la feuille du bas du viewer (`max-height: min(56vh, 480px)`, défilement interne) ; **la courbe n'est pas rendue, la liste datée est affichée ouverte** ; le bouton passe dans le menu « Plus d'actions » sous le nom « Synthèse ». Les grilles de jauge restent sur deux colonnes (nom + valeur), le nom passe à la ligne. |
| ≤ 999 px ou tactile | toute cible interactive de la Synthèse (`.btn`, `.vf-link`, `.row`, `summary`) fait au moins 44 px de haut (`min-height: 44px`) ; l'en-tête porte déjà 44 px. |
| 701 à 1 279 px | la Synthèse coexiste avec le tiroir Git (règle du détail d'une carte) ; elle ne ferme pas Git et n'est pas fermée par lui. |

---

## UI Considerations

Applicable state considerations resolved: 22 covered, 2 backstop, 0 unresolved

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | blocs 1 à 4 | ✅ covered | « Première visite sur ce poste », « Rien de nouveau depuis {quand}. », « Aucun jalon en cours… », « Aucune activité dans les dernières 24 h. » (Copywriting Contract) |
| loading | bloc 3 (jauges) | ✅ covered | « Lecture des jauges en cours. » statique, `aria-busy`, aucun spinner ni animation |
| loading | bloc 4 | ✅ covered | rien n'est rendu avant la réponse de la frise ; un bloc existant ne disparaît pas sur une panne |
| error | route des jauges | ✅ covered | « Les jauges sont indisponibles : le serveur du cockpit n'a pas répondu. » + « Relire les jauges » sans déplacer le focus |
| error | une jauge | ✅ covered | « Indisponible » + raison fermée, jamais « 0 » |
| error | git, burn-up, coût | ✅ covered | « Commits : non lus… », « Burn-up indisponible… », « Coût indisponible… » |
| populated | jauges, phases, burn-up | ✅ covered | exemples exacts (sections 4 à 6), gabarit à 320 px |
| partial | jauges | ✅ covered | une jauge « Indisponible » ou « Non applicable dans ce lab » à côté de jauges mesurées ; bilan qui compte chaque catégorie |
| partial | burn-up | ✅ covered | phase close sans date nommée sous le graphe, phase inscrite sans date dite, jamais estimée |
| overflow | listes de phases, de blocages, de mesures | ✅ covered | 5 phases, 3 blocages, 5 mesures au plus puis `.more` « et N autres » ; liste datée dans un repli |
| overflow | chemins relatifs | ✅ covered | coupure possible après chaque « / » (`<wbr>`), jamais au milieu d'un segment |
| zero-one-many | phases, commits, sessions, blocages | ✅ covered | singulier et pluriel exacts ; « au moins N » ; « plus de 500 » ; jamais « 0 » sans sa réserve de 24 h |
| long-text | texte d'un blocage | ✅ covered | coupé au mot à 140 caractères avec « … », texte complet en `title` |
| long-text | nom de phase, nom de jauge | ✅ covered | passent à la ligne ; la valeur ne passe jamais à la ligne |
| zero-one-many | jalon à une seule date | 🧪 backstop | domaine du tracé élargi à 1 jour minimum ; rendu à vérifier par un témoin visuel sur fixture à une date |
| long-text | libellé « Synthèse » à 1 600 px et plus | 🧪 backstop | l'en-tête déborde à la limite (P70-D-22) : témoin de non-débordement de l'en-tête à 1 280, 1 440, 1 600, 1 639 et 1 920 px |

---

## Stack, CSP, fichiers

- Pas de bibliothèque de composants : HTML, CSS et JS vanilla dans un fichier `ui/` neuf. Nom proposé : `ui/74-vf-synthese.js` ; le numéro est libre à l'exécution, à revérifier contre les fichiers posés par les autres phases (le calcul pur de la différence, sans DOM ni stockage, peut vivre dans un second fichier `ui/` ; nombre et noms fixés par le plan). Le fichier se charge APRÈS `20-health.js` (le bouton Santé existe) et `01-vf-responsive.js`, et AVANT `80-vf-fr.js`. Par prudence, un fichier `ui/` reste sous 300 lignes (plafond cité en tête de `ui/03-vf-accessibilite.js`).
- Ne parle au viewer que par `window.Floorplan` : `addHeaderButton`, `addPanelSection('overview', …)`, `showPanel`, `closePanel`, `on('panel')`, `reveal`, `iconI`, `h`, `store` non utilisé (la mémoire de visite passe par `localStorage` directement, sous sa clé par lab, P77-D-07).
- Jeton : `VF_ETAT.jeton()` / `VF_ETAT.lireJson()` quand la coquille de la 79 les expose (A13), sinon l'en-tête `x-floorplan-token` par le chemin en vigueur (comme `ui/75-vf-modele.js`).
- Stockage : seule la clé `vibeflow-cockpit:derniere-visite:<lab>` (jamais `vibeflow-cockpit:visite:<lab>`, prise par la visite guidée) ; objet `v: 1` de 8 Ko au plus, sur liste fermée (P77-D-08). Aucune écriture sur le disque du lab, aucune route d'écriture.
- Aucune couleur littérale dans le fichier (garde-fou des couleurs en dur : le marqueur `vf-couleur-ok` ne s'emploie que pour un masque, jamais pour afficher).
- L'inventaire des chaînes anglaises du cockpit (`vf-cockpit-fr-inventaire.mjs`) ne doit rien relever dans le fichier neuf ; sinon une exclusion écrite avec sa raison (`vf-cockpit-fr-exclusions.json`).
- Aucun chemin de machine, aucun identifiant de session, aucun montant dans le fichier ni dans ses chaînes.

### Fichiers partagés (coordination)

| Fichier | Rôle pour la 77 | Autres phases concernées | Règle |
|---------|-----------------|--------------------------|-------|
| `ui/74-vf-synthese.js` (+ calcul pur) | neuf : bouton, panneau, ligne-résumé, mémoire de visite | numéro libre à vérifier | après la première vague de la 79 : ni ligne `AJOUT` dans `VENDORED.txt`, ni diff amont ; avant : une ligne `AJOUT` par fichier neuf |
| `ui/00-vibeflow.js` | fournit `.vst-*`, `.vf-bar`, `.vf-link`, `.vf-now`, `.vf-stats` | 80 (panneau Projet, en-tête) | LECTURE SEULE pour la 77 (la ligne `V.lastDesc` morte est versée à la phase suivante qui l'édite) |
| `ui/20-health.js`, `ui/25-recent.js` | patron du bouton ; `#btn-health` sert d'ancre de position | 80 (AUDC-M8) | LECTURE SEULE |
| `ui/73-vf-tiroir-travail.js`, `ui/70-vf-live.js`, `ui/75-vf-modele.js`, `ui/76-vf-git-entete.js`, `ui/77-vf-git-*.js` | patrons (focus, Échap, clé par lab) ; `#vf-git-ouvreur` ; `#panel` partagé avec « Au travail » | 73, 74, 76 | LECTURE SEULE ; un seul contenu de panneau à la fois |
| `viewer.html` | `Floorplan`, `.sec`, `.row`, `#panel`, `#hdr-ext`, jetons `--sp-*` | — | LECTURE SEULE |
| `scripts/vf-cockpit-project.mjs` | champ facultatif `meta.vf.burnup` ; retrait de `lastDesc` | 75, 76, 80 (`meta.vf`) | ajout facultatif d'un champ : pas de changement de version (C0 de la 79) |
| `scripts/vf-cockpit-planning.mjs` | lecture des dates de la checklist (`ph.line`, `STATUS_SUFFIX`) | 79 | forme de `ph.line` inchangée |
| `scripts/vf-cockpit-server.mjs`, `scripts/vf-cockpit-paths.mjs`, `scripts/vf-cockpit-interface.json` | route `/api/vf/methode` (une ligne dans la table, ordre alphabétique des chemins), lanceur asynchrone borné, schémas | 75, 76, 79 | fonction exportée unique des contrôles C0 (A11) ; une ligne dans la table (A10) |
| `plugin/conductor/scripts/check-method-budget.sh`, `check-instruction-budget.sh` et leurs suites | option `--format=tsv` (plan sans fichier de la 79) | — | trailer `Gate-Touche:` ; sortie texte identique octet pour octet sans l'option |
| CHANGELOG du cockpit et du conducteur | entrée « Ajouté » / retrait | toutes | une entrée par module touché |

---

## Témoins (ce qu'un témoin visuel ou comportemental doit pouvoir faire rougir)

Chaque témoin est montré rouge sur mutation avant d'être cru (P77-D-18) ; chacun s'observe dans le DOM, sur une page Projet servie sur un lab fixture, dans les deux thèmes.

| Id | Observation DOM | Doit rougir quand |
|----|-----------------|-------------------|
| W1 | `nav.vf-tabs a` compte 3 sur chaque page ; aucun élément `role="tab"` neuf | un quatrième onglet apparaît |
| W2 | `#btn-synthese` existe une fois sur Projet, jamais sur Code, Équipe, page exportée ou sans serveur ; il suit `#btn-health` dans `#hdr-ext` ; `aria-controls="panel"`, `aria-expanded` bascule ; nom accessible commençant par « Synthèse » ; aucun enfant `.badge` ; ni chiffre ni point dans son texte visible | un badge, un compte ou une pastille est posé sur le bouton |
| W3 | largeur de `#panel` identique Synthèse ouverte et détail d'une carte ouvert ; rectangle et transformation de `#viewport` identiques avant et après ouverture ; aucune règle `#panel` écrite par le fichier neuf | le panneau change de largeur ou pousse la carte |
| W4 | pour tout élément sous `.vf-sy` : `background-color` ∈ {transparent, `--raise-2` (piste), `rgba(var(--ink), .06)` (survol, `.btn.soft`)} ; `box-shadow: none` ; bordures neutres ; chaque couleur calculée (`color`, `fill`, `stroke`, `border-*`, `.vst::before`) a R, G, B égaux à ±2 ; aucun `.badge`, `.dot` coloré ni liseré | un fond teinté, une couleur d'alerte ou un glyphe teinté apparaît |
| W5 | pour tout élément sous `.vf-sy` : `padding-*`, `margin-*`, `gap`, `row-gap`, `column-gap`, `top`, `left`, `right`, `bottom` calculés ∈ {0, 2, 4, 6, 8, 12, 16, 20, 24, 32} (et leurs négatifs), aucun 10, 14, 18, 22 | une valeur hors grille est écrite |
| W6 | `font-size` calculé ∈ {20, 13.5, 12.5, 11} px ; `font-weight` ∈ {400 hérité, 500, 600} ; première famille ∈ {Inter, JetBrains Mono} | une cinquième taille, un 700 ou une autre police |
| W7 | zéro élément dont la valeur calculée de `border-left-color`, `border-top-color` ou `outline-color` n'est pas neutre ; zéro `drop-shadow` ni `box-shadow` flou | un liseré ou un halo coloré |
| W8 | `svg.vf-sy-courbe[role="img"]` avec `aria-label` non vide contenant « sur » et « % » ; exactement deux `path` de série, l'un sans `stroke-dasharray` (`--text-3`), l'autre en tirets (`--text-4`) ; aucun `linearGradient`, aucun élément de légende à pastille ; deux étiquettes directes ; la tête « N sur M · P % » est égale au pied de la carte de jalon pour la même fixture ; à 700 px la courbe est absente et `ol.vf-sy-liste` visible, à 701 px la courbe est visible et la liste est dans un `details` fermé ; une fixture à phase close sans date porte la note « Close, date non écrite » et une marche de moins | une courbe colorée, une légende, une estimation de date ou un double contenu au téléphone |
| W9 | chaque `li[data-vf-sy-jauge]` porte un `.vst` dont le mot ∈ vocabulaire fermé et dont `::before` a un masque non `none` ; les verdicts non applicable, indisponible et format non reconnu n'ont ni `.vf-bar` ni valeur ni « 0 » (fixture de lab tiers sans corpus de densité : assertion sur le mot et sur l'absence de « 0 » ; fixture à copie de gate ancienne code 64 : « Indisponible ») ; un dépassement porte le mot, le glyphe et une barre hachurée | un 0 à la place d'un verdict ; un dépassement dit seulement par la couleur |
| W10 | `textContent` de `#panel` ne contient aucun préfixe de dossier personnel ni de dossier temporaire du poste (ni forme POSIX, ni forme à lettre de lecteur) ; aucun `code` de chemin ne commence par `/` ou `~` ; la fixture est posée sous un dossier au nom marqueur, absent de la page | un chemin du poste s'affiche |
| W11 | `localStorage` : seule la clé `vibeflow-cockpit:derniere-visite:<lab>` est écrite ; valeur JSON `v: 1`, ≤ 8 192 octets, uniquement les clés de la liste fermée ; aucune écriture de `vibeflow-cockpit:visite:*` ; `sessionStorage` inchangé ; aucune requête `POST` ; aucune requête hors `GET /api/vf/methode` neuve ; aucun appel à `/api/vf/doing` ni `/api/vf/transcript` ; aucune dernière commande dans la valeur gardée | une clé en plus, une donnée hors liste, un appel interdit |
| W12 | la fixture a un STATE dont `last_activity_desc` est une phrase reconnaissable : elle est absente du DOM de Projet, et `meta.vf` ne porte plus la clé `lastDesc` | la prose recopiée du STATE revient |
| W13 | à l'ouverture, `document.activeElement` est le `h2` de la Synthèse ; Échap : focus sur `#btn-synthese` et `#panel > .vf-sy` absent ; l'arrivée des jauges ne change pas `document.activeElement` ni `#panel.scrollTop` ; « Tout vu » : focus sur le `h3` du bloc 1 et zone vive « Synthèse remise à zéro. » ; un second onglet reçoit `storage` et met à jour sa ligne-résumé sans changer son focus | un focus perdu sur `body`, volé, ou un `showPanel` de rafraîchissement |
| W14 | sous `prefers-reduced-motion: reduce` : `animation-name: none` et `transition-duration: 0s` pour tout descendant de `.vf-sy` | une animation propre à la Synthèse |
| W15 | zéro attribut `on*` sous `.vf-sy` et sur `#btn-synthese` ; zéro évènement `securitypolicyviolation` ; zéro `innerHTML` d'un texte venu du STATE, de git ou d'une session non échappé (fixture au texte piégé : balise et attribut inertes) | un script ou une balise du STATE est interprété |
| W16 | en `pointer: coarse` ou ≤ 999 px, chaque `.btn`, `.vf-link`, `button.row`, `summary` de la Synthèse mesure au moins 44 px de haut ; aucun débordement horizontal du panneau à 264 px de contenu | une cible trop petite, un débordement |
| W17 | bloc 4 : route de frise en 404, aucun `[data-vf-sy-bloc="cout"]` dans le DOM et les ordonnées des blocs 1 à 3 sont identiques à la présence du bloc ; route présente, le bloc suit le bloc 3 ; le texte du bloc ne contient ni `€`, `$`, `£`, ni « euro », « dollar », « USD », « EUR », « coût estimé » ; une voie sans rattachement tombe sur la ligne « Non rattaché », jamais dans une phase | un « à venir », un montant, une phase devinée |
| W18 | la ligne-résumé `[data-vf-sy-resume]` est un `button` focusable, placé avant le `h3` « Prochaines phases » dans l'ordre du DOM quand le viewer prend en charge `top` ; elle ne contient aucune jauge, aucun badge | une ligne-résumé qui lance les gates ou qui n'est pas focusable |
| W19 | l'en-tête de Projet ne déborde pas à 1 280, 1 440, 1 600, 1 639 et 1 920 px (aucune ligne ajoutée à `header`) ; à ≤ 700 px le menu « Plus d'actions » liste « Synthèse » une fois | l'icône de trop fait déborder l'en-tête, ou une entrée en double |
| W20 | la Synthèse ne ferme ni n'ouvre le tiroir Git ; ouvrir « Au travail » remplace la Synthèse (un seul contenu de panneau) ; sélectionner une carte ferme la Synthèse | un conflit de panneau ou de tiroir |

## Points ouverts bornés (à trancher à l'exécution)

| Point | Borne |
|-------|-------|
| Forme finale du glyphe du bouton | reste un trait de 24 × 24, épaisseur 1,75, une seule figure « escalier sur ligne de base » ; jamais un pouls, une roue, une boussole ni un triangle de lecture |
| Lien « Voir dans Git » | clique `#vf-git-ouvreur` s'il existe, sans route ni événement neuf ; omis si l'ouvreur est absent ou si le clic n'ouvre pas le tiroir sous témoin ; jamais de repli |
| Nom de l'évènement du direct qui signale un `G.meta.vf` remplacé | relevé dans `ui/70-vf-live.js` à l'exécution ; faute d'évènement, le bloc 1 et le bloc 2 se recalculent à l'ouverture et sur `storage` seulement |
| `top: true` de la ligne-résumé | si la Phase 80 réécrit le panneau Projet et que le viewer n'honore plus `top`, la ligne tombe en fin de panneau ; le bouton reste l'entrée principale |
| Collision d'étiquettes de la courbe | la règle des 14 unités de la section 5 est une borne ; un ajustement d'ancrage est permis tant qu'aucune étiquette ne sort du viewBox ni ne recouvre une série |
| Tuile de hachures | tuile 8 × 8, trait à 45° de 3 px, `--text-3` sur `--raise-2` à 3:1 au moins dans les deux thèmes ; l'angle et le pas peuvent changer, pas la nature (motif, jamais dégradé) |
| Chiffre principal de « Jetons » (bloc 4) | voir section 7 : somme des quatre compteurs ou « entrée + sortie », libellé explicite |
| Durée du cache de la route des jauges | de 30 s à 5 min (P77-D-04) ; l'instant de mesure affiché est celui du gate |
| Numéro et nom du fichier `ui/` | libre à l'exécution, à revérifier ; tout fichier neuf passe le garde-fou de l'inventaire français et celui des couleurs en dur |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none (pas de shadcn dans ce projet) | not applicable |
| third-party | none | not applicable |

Aucun registre, aucune dépendance front nouvelle, aucune police ni image distante : rien à vetter.

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS
- [ ] Dimension 7 Inventory Provenance: PASS (`Tool: none` : section « Component Inventory » omise ; table des classes du cockpit réutilisées, relevées par lecture le 2026-11-11, jamais une liste fermée)

**Approval:** pending
