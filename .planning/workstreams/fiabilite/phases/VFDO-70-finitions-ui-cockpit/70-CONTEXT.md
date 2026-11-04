# Phase 70: Finitions UI du cockpit - Context

**Gathered:** 2026-11-03
**Status:** exécutée, arbitrages reçus (P70-D-22 à P70-D-24, 2026-11-04). Historique : revalidée le 2026-11-04 contre `794c6dba` (Phase 69 mergée, cockpit `v1.1.1`) : 12 plans 70-01..12 en 6 vagues (3 plans ajoutés : 70-10, 70-11, 70-12 ; 70-02, 70-04, 70-05, 70-06, 70-08, 70-09 corrigés d'après le relevé d'un plan-checker frais) — non exécutée ; la revalidation P70-D-14 est traitée

**Exigences :** UIFN-01 à UIFN-14 (préfixe neuf, P70-D-12 ; UIFN-11 à UIFN-14 ajoutées le 2026-11-04, P70-D-21), inscrites dans `REQUIREMENTS.md` du compartiment
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
  à 390, 768 et 1 440 px, dans les deux thèmes. Puis une recette humaine pas à pas de 4 points était
  **proposée** à Samuel (en-tête mobile, tiroir, zoom, visite). **Amendé par P70-D-19 (2026-11-04) : la recette
  humaine de 4 points est remplacée par une recette par juges frais ; seuls les points de goût remontent à Samuel.**
  → UIFN-10.
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

- **P70-D-19 (méthode de recette : des juges, pas Samuel).** Arbitrage de méthode de Samuel, mot pour mot :
  « si c'est pour me demande ca ca sert a rien, lance des juge qui prenne des screenshot pour les tests, appele moi
  seulement si tu ne peux pas faire (gout, avis humain indispensable) » (session principale Claude Code, 2026-11-04 ;
  déjà consigné dans `phases/VFDO-69-suivi-travail-en-cours-cockpit/69-RECETTE-HUMAINE.md` § Tri, source vérifiable).
  Remplace la recette humaine de 4 points de P70-D-06 et le texte d'UIFN-10. Plan 70-09 : captures avant / après
  (390, 768, 1 440 px, deux thèmes ; les « avant » sont déjà prises par le manager sur `794c6dba`, hors dépôt,
  P70-D-17) puis recette par juges frais, chacun sur son propre Chromium headless piloté par la bibliothèque
  `playwright` (jamais le MCP partagé), deux thèmes, 390 / 1 024 / 1 440 px ; seuls les points de goût remontent à
  Samuel, groupés en un seul tri ; aucun correctif sans arbitrage (ADR-031). → UIFN-10.

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
  69 (`v1.1.0` à P69-D-26, puis `v1.1.1` à `794c6dba` : la cible est donc `v1.1.2`) : ce sont des finitions, sans nouvelle capacité (le choix de langue est exclu). La
  release racine reste un geste humain.


### Choix du manager (vf-dev-manager, 2026-11-04 — pas des arbitrages de Samuel)

Issus des captures « avant » mesurées sur `794c6dba` et du relevé du plan-checker ; aucune question posée à Samuel.
- **P70-D-20 (zoom de l'onglet Équipe, défaut D).** Sur l'onglet Équipe, qui n'a pas de barre de question, à TOUTE
  largeur ≥ 701 px, le zoom est la rangée en bas à gauche comme dans le viewer d'origine à 1 440 px. Mesuré : colonne à
  x=574, y=72 (42×114) à 1 024 px et x=308, y=108 (52×144) à 768 px, par-dessus les cartes. Les onglets Code et Projet
  gardent leur position actuelle (la barre de question occupe le bas). ≤ 700 px : P70-D-09 inchangé. → UIFN-14 (70-12).
- **P70-D-21 (périmètre ajouté, UIFN-11 à UIFN-14).** Relevés de la recette de la 69 sans plan, ajoutés sans arbitrage :
  UIFN-11 réglages visuels de l'onglet Équipe (70-02) ; UIFN-12 focus clavier du tiroir (70-11) ; UIFN-13 témoins des
  cinq mineurs de la 69 (70-11) ; UIFN-14 zoom, titre / première carte, fil d'Ariane et matrice responsive de l'onglet
  Équipe (70-12). Le point « écrit à <id d'agent> » (`vf-cockpit-transcript.mjs:12`) est exclu : il attend un
  arbitrage de goût de Samuel.
- **P70-D-22 (onglets à 13 px entre 701 et 1 279 px, question 1, bloquante).** Arbitrage de Samuel, mot pour mot :
  « Badge réduit à son point (Recommandé) » (AskUserQuestion, session principale Claude Code, 2026-11-04, réponses relayées par le manager vf-dev-manager). Conséquence : entre 701 et 1 279 px, le badge « au travail » se
  réduit à son point et les onglets restent à 13 px / 3 px ; cela amende P70-D-16 pour cette tranche (le recalcul de
  `70-04-RED-TRACE.md` montrait qu'à 1 024 px l'en-tête de Code ne tenait pas à 13 px avec le badge entier). R13.4
  est tranché par cette décision.
- **P70-D-23 (questions 2 à 13, tri de goût).** Arbitrage de Samuel, mot pour mot : « Tout selon les recos
  (Recommandé) » (AskUserQuestion, session principale Claude Code, 2026-11-04, réponses relayées par le manager vf-dev-manager), soit 2a 3b 4a 5a 6b 7b 8b 9b 10a 11b 12a 13a ; il demande aussi de corriger l'infobulle en
  « de ce projet ». Options retenues :
  - 2a : « écrit à <id d'agent> » devient le rôle, sinon « un agent ».
  - 3b : l'ajustement d'Équipe est plafonné à 0,75, cadré sur la première carte.
  - 4a : centrage borné de la visite conservé.
  - 5a : la visite éclaire une carte au lieu de la sélectionner (conservé).
  - 6b : le plafond de zoom ×1,6 sur téléphone est relevé.
  - 7b : l'étape « 2 services extérieurs » vise les cartes des services.
  - 8b : la pastille du « ⋯ » est un point.
  - 9b : « le bouton de visite (icône), en haut » remplace « Par où commencer en haut » ; l'infobulle « de ce code »
    de l'onglet Projet devient « de ce projet ».
  - 10a : « composant » et « prioritaire » conservés.
  - 11b : libellé du thème dans « ⋯ » : « Thème : Auto ».
  - 12a : le lien « Nœud », décalé de 10 px, est aligné.
  - 13a : le bouton « Par où commencer » est désactivé sur l'onglet Équipe.
- **P70-D-24 (R8 de la recette de la Phase 68, reporté).** Samuel a passé R8 de la 68 à la 70 (P68-D-35, sur la
  branche de la 68) : le panneau latéral web ne dit pas l'état de la mission, et un nœud en cours a le même point
  qu'un nœud fait. Décision du manager (vf-dev-manager, 2026-11-04, pas un arbitrage de Samuel) : inscrit au BACKLOG,
  pas traité en 70. Motif : l'état de la mission vient de la cascade de vie de la 68 (`vf-cockpit-vie.mjs`, P68-D-26
  et P68-D-33), absente de main et de la branche de la 70 ; le point des nœuds est rendu par `vf-cockpit-project.mjs`,
  que la branche de la 68 modifie aussi : le traiter ici ajouterait un conflit de merge.

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


## Re-mesures du 2026-11-04 (code `794c6dba`, Phase 69 mergée)

Les numéros de ligne ci-dessus datent de `7370d604` ; ceux-ci les remplacent (mesurés par `grep -n`). Les lignes de
`viewer.html` citées plus haut (1591, 1596, 620, 636-637) sont inchangées.
- `40-tour.js` : « One real path » à `:47` (et non `:74-75`) ; `autoSteps()` `:49` ; construction des étapes `:72-73`.
- `vf-cockpit-ask.mjs` : « Où on en est » `:105-108` (et non `:103-109`) ; `nexts` `:105` ; `vf.phase ?? '?'` sur la ligne `:107`.
- `00-vibeflow.js` : `--st-active: var(--sev-medium)` et `--st-blocked: var(--sev-high)` DÉJÀ posés `:24` ; `--text-1`
  n'existe plus ; restent `rgba(0,0,0,.18)` `:28` et `#000` ×4 `:57` (masque). Plus de `#f59e0b|#ef4444` dans `70-vf-live.js`
  (`#vf-lock` lit `var(--st-active)` `:22`). Les écarts M5.1 et M5.2 sont donc déjà soldés ; seule M5.3 est rouge.
- `01-vf-responsive.js` : `header .hl { min-width: 280px }` `:25` ; zoom en colonne en haut à droite de 1 000 à 1 279 px `:42` ;
  tranche 1 000-1 599 px à la souris `:35`.
- `vf-cockpit-equipe-carte.mjs` : détail joint par `'\n'` à la ligne `:35` (et non `:34`) ; `viewer.html:1625` découpe sur `\n\n+`.
- `72-vf-equipe.js` : clé de rechargement `:88`, `sessionStorage` `:75-82`, `b.disabled = true` `:122`, panneau `:109-116`.
  `70-vf-live.js` : redessin du tiroir `:72-82` (`SC.showPanel` `:78`), commande rendue en `textContent` `:86-89`, style `.vf-who button` `:34`, `.vf-link` `:38`.
  `vf-cockpit-who.mjs:82` : `WS_RE` et clause `..`.
- Identifiants de témoins : R9 existe déjà (`test-cockpit-responsive.sh:292-300`) et `Q12` aussi (`test-cockpit-questions.sh`) ; les
  neufs sont R13 à R20, Q15 à Q17, EK1 à EK7 et W19 (vérifiés absents par `grep`).
- Défauts mesurés sur les captures « avant » du manager : zoom de l'onglet Équipe au milieu du canevas (P70-D-20) ; titre qui
  recouvre la première carte de l'onglet Équipe, 22 752 px² à 390 px et ~17 400 px² à 768, 1 024 et 1 440 px ; fil d'Ariane rogné
  à 31 px (« V… ») à 1 024 px sur Projet et Équipe sans chevauchement de la recherche dans ce lab (le chevauchement de la
  recette 69 n'est donc pas reproduit partout : témoin sur la fixture qui le provoque, ou « non reproduit, témoin négatif »).
- Durée de `test-cockpit-responsive.sh` : 175 s, 11 lancements de Chrome (70-10, P70-D-18).

</facts>

<revalidation>
## Revalidation après le merge de la 69 (P70-D-14) — TRAITÉE le 2026-11-04

Relevé par le plan-checker frais (passe 2, `3edc7e51`, verdict passed, infos non bloquantes), TRAITÉ le 2026-11-04
contre `794c6dba` (nouveau relevé d'un plan-checker frais appliqué : voir « Re-mesures » et le tableau des vagues) :
- 70-09, bloc `<traces_sans_chemin_machine>` : nommait `70-09-CAPTURES.md` ; corrigé en `70-CAPTURES.md` et `70-RECETTE-JUGES.md`.
- `scripts/check-machine-paths.sh` ne balaie que les fichiers suivis : la relecture d'une RED-TRACE neuve se fait
  après `git add` et avant le commit, sinon elle est verte sans avoir lu le fichier.
- 70-04 tâche 2 : le critère « 12 px / 2 px = 0 occurrence » a retrouvé son sens sur `794c6dba` (`00-vibeflow.js:30` à 12 px / 2 px) : conservé.
- 70-09 : le bump vise `v1.1.2` au-dessus de la `v1.1.1` de `794c6dba` (la sonde OK-BUMP base + 1 reste juste).
- 70-09 ne versionne aucune capture PNG (P70-D-17, tranché le 2026-11-03).
- **P70-D-18 (durée de `test-cockpit-responsive.sh`).** Ajout au périmètre, arbitrage de Samuel, mot pour mot :
  « Accepter, l'alléger en 70 (Recommandé) » (AskUserQuestion, session principale Claude Code, 2026-11-03,
  relayée par la session principale). Après la 69, la suite dure 175 s pour une cible de 60 s. La 70 la ramène
  vers sa cible au moment où elle refait l'en-tête mobile (70-04, puis 70-05). Aucun témoin n'est retiré : le
  gain vient du regroupement des mesures et du nombre de lancements de Chrome. Durée avant et après consignée.
  → UIFN-01.

### Découpage en vagues (2026-11-04) — aucune collision de fichiers dans une même vague

Vérifié par script sur `files_modified` des 12 plans (hors fichiers de trace), sans collision ; chaque dépendance pointe vers une vague strictement antérieure.

| Vague | Plan | depends_on | Fichiers modifiés (résumé) | Régime |
|-------|------|------------|-----------------------------|--------|
| 1 | 70-01 | — | garde du français (`test-cockpit-chrome-fr.sh`, `chrome-fr-rendu.mjs`, inventaire, exclusions, `test-cockpit-onglet-code.sh`) | tests |
| 1 | 70-02 | — | `test-cockpit-marque-blanche.sh`, `00-vibeflow.js`, `70-vf-live.js`, `71-vf-equipe-rendu.js`, `vf-cockpit-equipe-carte.mjs` | M5 + quick |
| 1 | 70-10 | — | `test-cockpit-responsive.sh`, `chrome-responsive.mjs` (seul propriétaire en V1) | allègement |
| 1 | 70-11 | — | `chrome-equipe-clavier.mjs`, `test-cockpit-equipe.sh`, `test-cockpit-who.sh`, `72-vf-equipe.js` | témoins |
| 2 | 70-03 | 70-01 | dictionnaires `78`/`79`, `80-vf-fr.js`, `vf-cockpit-code.mjs`, exclusions | français |
| 2 | 70-04 | 70-02, 70-10 | `chrome-responsive.mjs`, `test-cockpit-responsive.sh`, `00-vibeflow.js`, `01-vf-responsive.js`, `02-vf-telephone.js`, `VENDORED.txt` | R13 à R16, en-tête |
| 3 | 70-05 | 70-04 | `02-vf-telephone.js`, `01-vf-responsive.js` (+ viewer et patch si inévitable) | zoom, tiroir, titre |
| 3 | 70-06 | 70-01, 70-03, 70-04 | `test-cockpit-questions.sh`, `vf-cockpit-project.mjs`, `vf-cockpit-ask.mjs`, `00-vibeflow.js` | Q15 à Q17 |
| 4 | 70-07 | 70-03, 70-05, 70-06 | `chrome-visite-etapes.mjs`, `test-cockpit-projet.sh`, `40-tour.js`, patch, `VENDORED.txt`, `79-vf-fr-dict-b.js` | visite |
| 4 | 70-12 | 70-05, 70-10, 70-11 | `chrome-responsive.mjs`, `test-cockpit-responsive.sh`, `00-vibeflow.js`, `01-vf-responsive.js`, `72-vf-equipe.js` (jamais `viewer.html` ni `VENDORED.txt`) | R17 à R20 |
| 5 | 70-08 | 70-06, 70-07 | `test-cockpit-projet.sh`, `vf-cockpit-project.mjs` | visite Projet |
| 6 | 70-09 | tous | `70-CAPTURES.md`, `70-RECETTE-JUGES.md`, version et documentation du module | juges |

Points de séquencement : 70-02 et 70-11 ne se partagent aucun fichier (la correction du focus ne touche pas `70-vf-live.js` ; si sa cause y est, 70-11 s'arrête et le manager séquence la retouche après 70-02). En vague 4, 70-07 et 70-12 ne partagent aucun fichier (`VENDORED.txt` est interdit à 70-12). La suite responsive est lancée au plus une fois par plan, en fin de plan ; deux fois pour 70-04 et 70-12, dont la tâche tracer doit prouver son rouge. Chaque exécuteur d'une même vague travaille dans son worktree (règle de parallélisme maximal de Samuel, mot pour mot : « la regle est de parallèliser le plus possible, pas de regle "1 seul manager" on lance autant d'agent et sous agent qu'on peut. Plusieur worktree peuvent etre necessaire », session principale Claude Code, 2026-11-03) ; les suites se rejouent à la jointure de la vague.

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
