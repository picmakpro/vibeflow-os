# Phase 70: Finitions UI du cockpit - Context

**Gathered:** 2026-11-03
**Status:** Planifiée (2026-11-03, 9 plans 70-01..09 en 6 vagues, plan-checker frais passed sur `3edc7e51`) — non exécutée ; exécution après le merge de la 69 et la revalidation P70-D-14

**Exigences :** UIFN-01 à UIFN-10 (préfixe neuf, P70-D-12), inscrites dans `REQUIREMENTS.md` du compartiment
et dans la ligne `Requirements` de la Phase 70 du ROADMAP.

Cadrage documentaire (aucun code), par vf-dev-manager, sur la branche `feat/phase-70-finitions-ui` partie de
`7370d604` (planification de la 69, sans code). Jalon `vibeflow-v2.0`, compartiment `fiabilite`.
**Exécution après le merge de la Phase 69** : la 70 touche les mêmes fichiers du cockpit que la 69
(`00-vibeflow.js`, `70-vf-live.js`, nouvel onglet « Équipe » `72-vf-equipe.js`).

<domain>
## Phase Boundary

Le cockpit tient en largeur mobile avec une information hiérarchisée, sa visite guidée est plus claire, et
le chrome ne montre plus d'anglais résiduel ni de coquilles (Goal du ROADMAP).

**Hors périmètre :** toute modification du calcul d'avancement et du jalon (Phase 69, CKPT-13..28) ; le
terminal intégré (Phase 71) ; lancer du travail depuis les cartes (Phase 72) ; vf-signal (Phase 68) ;
tout appel réseau sortant (P67-D-02) ; la release racine (geste humain).

</domain>

<decisions>
## Implementation Decisions

### Arbitrages de Samuel

Réponse unique de Samuel aux six questions de cadrage, mot pour mot : « Tout accepter (Recommandé) »
(AskUserQuestion, session principale Claude Code, 2026-11-03, relayée par la session principale).

- **P70-D-01 (en-tête mobile, D4 et I6 ; Q1-A).** À ≤ 700 px, l'en-tête tient sur **une seule rangée** :
  logo, onglets, recherche, le point « au travail » et un bouton « ⋯ ». Ce bouton ouvre un menu où chaque
  action porte un libellé : thème, Santé, Travail récent, Écrans, Visite, Exporter, Parcours, Types de
  liens. Les pastilles de compte (Santé, Travail récent) sont reportées sur le « ⋯ ». → UIFN-01.
- **P70-D-02 (visite guidée, I1 ; Q2-B).** Deux volets. D'abord les correctifs des constats : chaque étape
  cible un élément et la carte se centre dessus ; le texte s'affiche entier ; « Passer » reste visible à
  chaque étape ; les libellés sont cohérents (le texte nomme le bouton tel qu'il s'affiche) ; aucun
  anglais ; un repère « n sur N ». Ensuite, une **visite propre à l'onglet Projet** (jalon, phase en cours,
  missions, au travail) au lieu du repli « La base de code ». → UIFN-04, UIFN-05.
- **P70-D-03 (langue FR/EN ; Q3-A).** Hors de la 70. L'entrée du BACKLOG « Choix de la langue de l'interface
  du cockpit » reste ouverte. La 70 ne nettoie que l'anglais résiduel en mode français ; `?lang=en` n'est pas
  touché.
- **P70-D-04 (anglais résiduel ; Q4-A).** Toute l'interface, y compris le chrome du moteur vendorisé et les
  textes assemblés par VibeFlow : liste O5, pluriels construits à l'exécution, « Calls », « ⌫ up », les
  compteurs Santé, l'élision « de » + voyelle, « Claude Code and GSD », « Contrôle De Santé », les statuts
  bruts. Le garde du français est durci pour voir ces formes. Les **constats** du panneau Santé (données du
  moteur) restent en anglais (P67-D-20). → UIFN-06, UIFN-07.
- **P70-D-05 (« Où en est-on ? » sans STATE, BACKLOG F5 ; Q5-A).** Ajouté à la 70. La réponse locale omet les
  champs absents ou dit qu'il n'y a pas de `STATE.md`, et un test le couvre. → UIFN-08.
- **P70-D-06 (recette ; Q6-A).** En fin d'exécution, l'agent compare des captures Playwright avant et après,
  à 390, 768 et 1 440 px, dans les deux thèmes. Puis une recette humaine pas à pas de 4 points est
  **proposée** à Samuel (en-tête mobile, tiroir, zoom, visite), sans lui être imposée. → UIFN-10.
- **P70-D-07 (écarts DESIGN.md).** Arbitrage antérieur de Samuel, mot pour mot : « Les règles dans DESIGN.md,
  la correction en 70 (Recommandé) » (AskUserQuestion, session principale, 2026-11-03).
  - `--st-active` vaut `var(--sev-medium)` et `--st-blocked` vaut `var(--sev-high)`.
  - `--text-1` est remplacé par `--text`.
  - Aucune couleur en dur dans les fichiers `ui/*vf*` et `00-vibeflow.js`, hors les exceptions justifiées
    (masque).
  
  → UIFN-09.
- **P70-D-08 (régime d'exécution).** Arbitrage de Samuel, mot pour mot : « Méthode allégée selon le risque »
  (AskUserQuestion, session principale, 2026-11-03). Il s'agit de finitions visuelles, donc ni revue ni audit
  séparés à l'exécution. Un seul codeur. Des tests seulement là où un comportement change. Recherche et plans
  courts.

- **P70-D-16 (onglets resserrés par la 69, retour à DESIGN.md).** Ajout au périmètre, arbitrage de Samuel, mot
  pour mot : « Garder en 69, corriger en 70 (Recommandé) » (AskUserQuestion, session principale Claude Code,
  2026-11-03, relayée par la session principale).
  - Ce que la 69 a fait : pour faire tenir le 3e onglet « Équipe » (plan 69-05) à 1 024 et 390 px, elle a
    resserré `.vf-tabs` dans `ui/00-vibeflow.js` (police 12 px au lieu de 13, padding de piste 2 px au lieu
    de 3, onglet 5 × 6 px). Elle a aussi élargi la borne `.hl` de 264 à 280 px dans `ui/01-vf-responsive.js`,
    et le témoin R4.2 de `test-cockpit-responsive.sh` est passé de 300 à 316 px (commit `1efcc691` sur
    `feat/phase-69-suivi-travail`).
  - Ce que fait la 70 : elle revient aux valeurs de `DESIGN.md` (onglets à 13 px, piste à 3 px de padding,
    §3 et §5) en même temps que la refonte de l'en-tête (P70-D-01), avec les trois onglets. L'en-tête doit
    tenir à 390 px (rangée unique) et à 1 024 px. La borne `.hl` et le témoin R4.2 sont recalculés depuis
    la nouvelle mise en page, jamais simplement élargis. → UIFN-01, UIFN-09.

- **P70-D-17 (captures hors dépôt).** Arbitrage de Samuel, mot pour mot : « Non, hors dépôt (Recommandé) »
  (AskUserQuestion, session principale Claude Code, 2026-11-03, relayée par la session principale). Les captures
  avant/après de 70-09 ne sont pas versionnées : elles restent dans le dossier temporaire de la session
  d'exécution. Le rapport de recette (`70-CAPTURES.md`) les nomme et décrit ce que chacune montre. → UIFN-10.

### Choix du manager (vf-dev-manager, 2026-11-03 — pas des arbitrages de Samuel)

Annoncés à Samuel dans le message de cadrage, sans question ; il ne les a pas contredits, mais n'a pas non
plus été interrogé dessus.
- **P70-D-09 (zoom, I4).** Reprend la demande de Samuel (`67-RECETTE-HUMAINE.md` § 3, point 7). À ≤ 700 px, les
  trois boutons de zoom passent en pile verticale, même dessin, à gauche, au-dessus de la barre de question.
  La tablette (701-999 px et tactile) reste telle quelle. Les trois boutons reçoivent un `aria-label`
  français à toutes les largeurs. → UIFN-02.
- **P70-D-10 (tiroir sur téléphone, I5).** À ≤ 700 px, le bouton « Détail » (`#btn-panel`) disparaît. Le
  tiroir s'ouvre au tap d'une carte ou du titre de la vue d'ensemble, selon le contexte. Il reçoit une
  poignée et une croix visibles, avec un nom accessible, et la fermeture au tap dans le vide et à Échap est
  conservée. → UIFN-03.
- **P70-D-11 (jalon affiché).** « Trajectoire de equipe-produit-v1.0 » est présentée comme le jalon en cours
  alors que le sous-titre dit `vibeflow-v2.0`. Le constat relève de la Phase 69 (CKPT-16, jalon) et lui est
  signalé, sans être traité en 70. Seule l'élision (« de » + voyelle) est traitée ici (P70-D-04).
- **P70-D-12 (identifiants d'exigences).** Les exigences prennent un préfixe neuf, `UIFN-01` à `UIFN-10`, libre
  au 2026-11-03 (aucune occurrence dans les REQUIREMENTS du dépôt). Motif : les Phases 68 et 71 sont cadrées
  en parallèle et pourraient prendre CKPT-29 et la suite.
- **P70-D-13 (onglet « Équipe » de la 69).** L'en-tête mobile compte avec les trois onglets (Code, Projet,
  Équipe) que la 69 livre (P69-D-17). La visite Projet peut nommer l'équipe si l'onglet existe au moment de
  l'exécution.
- **P70-D-14 (revalidation après le merge de la 69).** Les plans sont écrits sur `7370d604`, avant le code de
  la 69. Avant toute exécution, après le merge de la 69, un plan-checker les revalide contre le code réel
  (numéros de ligne, `00-vibeflow.js`, `70-vf-live.js`, `72-vf-equipe.js`, version du module). Aucune exécution
  sur un plan non revalidé.
- **P70-D-15 (version du module).** Bump **patch** du module `cockpit`, au-dessus de la version laissée par la
  69 (`v1.1.0`, P69-D-26) : ce sont des finitions, sans nouvelle capacité (le choix de langue est exclu). La
  release racine reste un geste humain.

</decisions>

<facts>
## Constats mesurés (2026-11-03, code `7370d604`, inventaire et captures Playwright)

Captures : `scratchpad/captures-70/` de la session du manager (non versionnées). `A/` =
`plugin/cockpit/skills/cockpit-moteur/assets/`.

### En largeur mobile (≤ 700 px)
- Points de rupture : 700/701 (téléphone, `A/viewer.html:2231`), 999/1000, 1279/1280 en tactile, 1599/1600
  à la souris (`A/ui/01-vf-responsive.js:35`). Sous 1 600 px, les boutons de l'en-tête sont en icônes seules.
- En-tête de l'onglet Code à 390 px : 3 rangées (~148 px). Rangée 1 : logo, onglets Code|Projet, zoom
  − / ajuster / + (déplacé dans l'en-tête par `placeZoom`, `A/viewer.html:2276-2278`), recherche (44 px, icône).
  Rangée 2 (`#hdr-ext`, `A/viewer.html:518`) : thème, Santé, Travail récent, Écrans, Par où commencer,
  Exporter, Au travail (réduit à un point, libellé masqué). Rangée 3 : Parcours, Types de liens, Détail
  (`#btn-panel`). Onglet Projet : 2 rangées (sans Santé, Récent, Écrans).
- La carte est rendue minuscule ; ce qui attire l'œil d'abord, ce sont le titre et les pastilles rouge et verte.
- Boutons de zoom : `title` sans `aria-label` (`A/viewer.html:561-565`). Pendant un parcours, sur Projet,
  « Remonter d'un niveau » passe sous la pilule de zoom.
- Tiroir (sheet) : `#panel` en feuille du bas (`A/viewer.html:534-538`), ouvert au tap d'une carte (:1415) ou
  par `#btn-panel` (:2279), fermé par tap dans le vide ou Échap ; ni poignée ni croix visibles ; il masque la
  barre de question ; le nœud sélectionné n'est pas mis en évidence.
- Test : `test-cockpit-responsive.sh` R3 (:82-85) ne vérifie à 800 et 390 px que l'absence de superposition
  de l'en-tête et de défilement horizontal.

### Visite guidée (`A/ui/40-tour.js`)
- Étapes : `G.tour` (≥ 2 entrées) ou `autoSteps()` (:49-70), plus « One real path » (:74-75), 9 au plus.
  Onglet Projet : `tour: []` (`plugin/cockpit/scripts/vf-cockpit-project.mjs:129`) → repli automatique, d'où
  « La base de code » et « En coulisse » sur Projet, et « Un vrai chemin » dont la note dit « dans le code ».
- Constats : l'étape 1 ne cible rien ; la carte n'est ni zoomée ni centrée sur la cible (onglet Code) ; texte
  coupé (« …reçoit les esca… ») ; « Passer » disparaît dès l'étape 2 ; « Appuyez sur Lecture » alors que le
  bouton dit « La lire » (`dict-a:194, 206`) ; « at the top » reste en anglais (gabarit sous 16 caractères,
  `80-vf-fr.js:15,39`) ; « Stripe and Postgres » garde « and » (`listOf`, :39).
- Démarrage seul au premier chargement ; mémoire `vibeflow-cockpit:visite:<lab>` (`75-vf-modele.js:30-50`).
- Test : `test-cockpit-projet.sh` O4 (:197-245) garde la persistance, pas le contenu.

### Anglais résiduel et coquilles (O5 et balayage)
- « Calls · N » : `A/viewer.html:1613` + `KIND_*` `call: 'Calls'` (:636-637), absent du dictionnaire.
- « ⌫ up » : `A/viewer.html:1596`, « up · » absent du dictionnaire (`dict-a:157,168` couvre « fit · », « search · »).
- « 1 important · 1 worth fixing · 1 minor » : `A/ui/20-health.js:16-18,98,148`.
- « …still use generated names. Run the skill again… » : `A/viewer.html:1591` ; l'entrée existe
  (`dict-a:184`) mais le gabarit plus court « {} and {} » (`dict-a:177`) passe d'abord (ordre du dictionnaire,
  `80-vf-fr.js:19,39`), puis le glossaire coupe le nœud texte (`10-glossary.js:76`).
- « viennent de le CLI Claude Code » : `A/viewer.html:1933` + `cli: 'the Claude Code CLI'` (:620), gabarit
  `dict-a:47`, variable `dict-a:170` — pas de contraction « de le » → « du ».
- « 1 fichiers de code » : `plugin/cockpit/scripts/vf-cockpit-code.mjs:21`, sans accord.
- Autres : « N modules », « N endpoints » (`A/viewer.html:925,928,1178,1692`), « N calls » (:1655,1669,1694),
  « Show N changes » (:2088), « 1 step » (:1847), « N places in here » (`20-health.js:160`), « Uses
  connection » → « Utilise liens » (`dict-a:227`), « Resolve on the map » (`80-vf-fr.js:28`), « Claude Code and
  GSD », « Contrôle De Santé », statuts bruts « ready_to_execute », « PASSED », « Trajectoire de equipe-… »
  (élision), titre coupé en plein mot à 768 et 1 440 px.
- Le garde `test-cockpit-chrome-fr.sh` (F1-F8, `vf-cockpit-fr-inventaire.mjs`, 142 exclusions) ne voit pas
  ces formes : « Calls » passe pour un chemin SVG (`inventaire:92`), « minor »/« important » pour des
  identifiants (:93), « up » a moins de 3 lettres (:84), les pluriels se construisent à l'exécution.

### Langue de l'interface
- `?lang=en` (`A/ui/80-vf-fr.js:67`) coupe aussi les couleurs de types de l'onglet Projet ; traduction à sens
  unique (retour à l'anglais = rechargement). Ajouts VibeFlow (`00-vibeflow.js`, `70-vf-live.js`,
  `75-vf-modele.js`) et données (`vf-cockpit-project.mjs`, `vf-cockpit-code.mjs`, `vf-cockpit-ask.mjs`) écrits
  en français en dur. Aucun test n'utilise `lang=en`.

### Écarts DESIGN.md (direction « Graphite », PR #196)
- `A/ui/00-vibeflow.js:24` : `--st-active: #f59e0b; --st-blocked: #ef4444`, identiques dans les deux thèmes ;
  doivent valoir `var(--sev-medium)` et `var(--sev-high)` (DESIGN.md §2).
- `--text-1` (inexistante) utilisée à `00-vibeflow.js:27,28` (repli `inherit`) → `--text`.
- Autres couleurs en dur : `00-vibeflow.js:28` `rgba(0,0,0,.18)`, `:54` `#000` ×4 (masque), replis
  `70-vf-live.js:22-23` `#f59e0b`/`#ef4444`.

### « Où en est-on ? » sans STATE (BACKLOG F5)
- `plugin/cockpit/scripts/vf-cockpit-ask.mjs:103-109` : `vf.phase ?? '?'`, `vf.status || ''`,
  `vf.lastActivity || '?'` (:107), `nexts = []` sans `curMs` (:105) → « Dernière phase : ? · , le ?. » et une
  liste « À finir » vide. Aucun test de la voie locale sur un lab sans STATE.

</facts>

<revalidation>
## À reprendre à la revalidation après le merge de la 69 (P70-D-14)

Relevé par le plan-checker frais (passe 2, `3edc7e51`, verdict passed, infos non bloquantes) :
- 70-09, bloc `<traces_sans_chemin_machine>` : il nomme `70-09-CAPTURES.md` ; l'artefact s'appelle `70-CAPTURES.md`
  (et `70-RECETTE-HUMAINE.md`) partout ailleurs dans le plan.
- `scripts/check-machine-paths.sh` ne balaie que les fichiers suivis : la relecture d'une RED-TRACE neuve se fait
  après `git add` et avant le commit, sinon elle est verte sans avoir lu le fichier.
- 70-04 tâche 2 : le critère « 12 px / 2 px = 0 occurrence » est déjà à 0 avant la 69 ; il n'a de sens que sur le
  code de la 69 (mesuré 1/1 sur `feat/phase-69-suivi-travail`).
- 70-09 : le bump attend `v1.1.1` au-dessus de la `v1.1.0` de la 69 ; sur la branche actuelle, le module est encore en
  `v1.0.0` et la sonde rougit par construction.
- 70-09 ne versionne plus aucune capture PNG (P70-D-17, tranché le 2026-11-03).
- **P70-D-18 (durée de `test-cockpit-responsive.sh`).** Ajout au périmètre, arbitrage de Samuel, mot pour mot :
  « Accepter, l'alléger en 70 (Recommandé) » (AskUserQuestion, session principale Claude Code, 2026-11-03,
  relayée par la session principale). Après la 69, la suite dure 175 s pour une cible de 60 s. La 70 la ramène
  vers sa cible au moment où elle refait l'en-tête mobile (70-04, puis 70-05). Aucun témoin n'est retiré : le
  gain vient du regroupement des mesures et du nombre de lancements de Chrome. Durée avant et après consignée.
  → UIFN-01.

</revalidation>

<canonical_refs>
## Canonical References

- `.planning/workstreams/fiabilite/phases/VFDO-67-cockpit-floorplan-socle-partage/67-RECETTE-HUMAINE.md`
  § 3 (points 1 et 7 : D4, I1, I4, I5, I6), § 6 (O5).
- `.planning/BACKLOG.md` § « Cockpit en largeur mobile et clarté de la visite guidée », § « Cockpit : anglais
  résiduel et coquilles du chrome », § « Choix de la langue de l'interface du cockpit », § « Où en est-on ? sur
  un lab sans STATE ».
- `DESIGN.md` (direction « Graphite », branche `docs/design-md`, PR #196) — §2 statuts, §4 points de rupture,
  §9 règles strictes.
- `.planning/workstreams/fiabilite/phases/VFDO-67-cockpit-floorplan-socle-partage/67-CONTEXT.md` — P67-D-02
  (aucun appel sortant), P67-D-20 (anglais de Santé accepté).
- `.planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-CONTEXT.md` — P69-D-17
  (onglet « Équipe »), P69-D-25 (« à recetter » en couleur « en cours »).

</canonical_refs>
