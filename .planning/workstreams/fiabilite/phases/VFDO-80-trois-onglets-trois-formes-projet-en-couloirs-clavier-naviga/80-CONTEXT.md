# Phase 80: Trois onglets, trois formes — Projet en couloirs, clavier, navigation - Context

**Gathered:** 2026-11-11
**Status:** Cadrée (2026-11-11) — frontière de questions vide ; cinq réouvertures tranchées par Samuel le 2026-11-11 (P80-D-52 à P80-D-56)

Cadrage par le manager de la mission Phase 80 (`vf-dev-manager`, worktree `.claude/worktrees/phase-80`, branche
`feat/phase-80-trois-formes`, base `origin/integration/cockpit-audit` `f763b556`, lot 0 de l'audit déjà fusionné). Jalon
`vibeflow-v2.0`, compartiment `fiabilite`. Cadrée en même temps que les Phases 79, 73, 74, 75, 76 et 77 (sept managers en
parallèle, demande de Samuel, session principale Claude Code, 2026-11-11). Mode autonome : chaque décision de détail est
« décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée », tranchée par un panel de
trois chercheurs sur faits établis par trois éclaireurs en lecture seule. Aucune de ces décisions ne vaut arbitrage de Samuel.

**Exigences :** FORM-01 à FORM-18. Préfixe réservé à la phase par le ROADMAP, vérifié libre (0 occurrence de `FORM-<n>`
sous `.planning/` et `plugin/` à `f763b556`).

<domain>
## Phase Boundary

L'onglet Projet se lit d'un regard à toute largeur : à la racine, les phases rangées en couloirs par état (À faire, En
cours, À recetter, Fait), le graphe de dépendances à la demande, une liste triable au téléphone. Chaque carte du canevas
(Code, et Projet quand le graphe est affiché) est atteignable au clavier et nommée pour un lecteur d'écran ; les
surcouches retiennent le focus et se ferment à Échap. On ne se perd plus sur la carte du code : minicarte, repères de
bord, zoom centré sur la sélection, palette de commandes, aide des raccourcis, cadrage de la sélection et de ses voisins.
Le tiroir Git tient à 1024 × 768. Une ligne d'état dit la branche entière, l'état du direct et l'heure de mise à jour.
Les jetons défaillants (contraste, tailles, chiffres) sont repris. Les onglets cessent de recharger la page entière
une fois la coquille de la Phase 79 livrée.

**Absorbe (part restante après le lot 0 seulement) :** AUDC-BL1, BL2, M1, M6, M12, X1, X2, X3, X5, X7 (onglets sans
rechargement ; les titres sont livrés), X8, F1, F3, F4, F5, F7 ; idées I23 à I27, I29, I30 ; et AUDC-M2, M5, M8 et la pastille de M10
(réouvertures tranchées par Samuel le 2026-11-11, P80-D-52 à P80-D-56).

**Déjà livré par le lot 0, hors plans :** AUDC-X4, X6, X7 (format de titre « <Onglet> · <nom> »), M7, M10 (vraie cause,
« Terminer »), M11 (tiroir du terminal rehaussé à min(480 px, 60 %) ; resté rehaussé après « Annuler » : en attente du
regard de Samuel, la Phase 80 n'y touche pas).

**Hors périmètre :** l'onglet Équipe (régie : Phase 73 ; frise et fiche d'agent : Phase 74) — la 80 ne le redessine pas ;
la couleur posée sur la carte Code (Phase 75 : la 80 la rend navigable, la 75 la colore) ; les preuves de traçabilité
(Phase 76, qui se branche sur Projet : contrats ci-dessous) ; la collecte, le flux, la coquille (Phase 79) ; toute
action sur une session (Phase 81, AUDC-Q3 « plus tard ») ; le plan B de AUDC-BL1 (PU-G-026 rouvert : sans objet tant
que les couloirs sont la direction) ; un mode focus qui recompose la mise en page (en réserve, après le worker de
mise en page de la 79) ; une vue liste de l'onglet Code (« Code reste une carte », DESIGNS § 1).

**Retraits (un ajout, un retrait — registre § 3, étude § 8.2) :**
1. Le canevas comme vue par défaut de l'onglet Projet (compensé par les couloirs).
2. Les vignettes Backlog, Graines et Releases (compensées par une liste).
3. Les trois copies de la formule de cadrage (`76-vf-git-entete.js`, `40-tour.js`, et la formule d'origine) ramenées à
   une seule (retrait de code né au cadrage).
4. Les trois listes « surcouche ouverte » recopiées (`02-vf-telephone.js`, `73-vf-tiroir-travail.js`,
   `77-vf-git-tiroir.js`) ramenées à une pile unique (retrait de code né au cadrage).
</domain>

## Faits établis au cadrage (éclaireurs, lecture du code à `f763b556`)

Le code a bougé depuis l'audit (écrit avant le lot 0) ; ces faits priment sur ses `fichier:ligne`.

- **Projet n'a aucun rendu propre** : `project.html` est la page du moteur forké avec le graphe Projet inséré
  (`vf-cockpit-build.mjs`). Des couloirs sont une vue nouvelle, pas une bascule existante.
- **Les quatre états existent** (`vf-cockpit-avancement.mjs`, codes `a-faire`, `en-cours`, `a-recetter`, `fait` ;
  projection `PROJECTION_ST` dans `vf-cockpit-project.mjs` ; glyphes et mots dans `ui/00-vibeflow.js`). Les comptes
  « 16/16 plans · 11/12 exigences » ne sont sérialisés qu'en texte dans `foot` (`piedExigences`).
- **Le contrat `cockpit-project@1` liste 4 statuts sans `recette`** alors que le graphe l'émet depuis la Phase 69
  (`vf-cockpit-interface.json`) ; aucun test ne le lit.
- **Le plancher de zoom 11/13 est voulu** (PU-G-026, `Math.max(kFit, 11/13)` dans `viewer.html`, Code seul) ; « Ajuster »
  ne peut pas tout montrer à taille lisible : l'aide passe par une minicarte, pas par un zoom plus petit.
- **Cartes du canevas** : `g.node` SVG + `foreignObject`, recréées à chaque `draw()`, sans rôle, nom ni `tabindex` ;
  Entrée plonge et Échap remonte déjà (écouteur global). Les positions sont dans `state.layout.children`, `freeArea()`
  est exportée.
- **Cause de AUDC-M6** : l'écouteur global sort quand la palette est ouverte et l'Échap de la palette n'écoute que son
  champ ; aucune pile, aucun piège à focus ; `inert` n'est posé que par le terminal ; le panneau fermé au bureau reste
  focalisable (`opacity:0`).
- **Garde de saisie incomplète** : les raccourcis ne sont neutralisés que dans un `INPUT` (Retour arrière remonte depuis
  une zone de texte ou un `<select>`, lu dans le code, non mesuré en navigateur).
- **Zoom `+`/`-`** centré sur le SVG entier ; facteurs 1,2/0,83 au clavier et 1,25/0,8 aux boutons (dérive à l'aller-retour).
- **Chaque onglet recharge la page entière** (liens vers trois pages) ; aucun pied de page ; la branche est coupée à
  220 px ; l'heure de mise à jour n'est affichée nulle part (`__vfLive.whoAt` existe en mémoire).
- **Tiroir Git** : 360 px fixes, toutes les rangées rendues d'un coup (jusqu'à ~1 000), worktrees ouverts par défaut,
  détail inséré sous la rangée.
- **Q12 n'énonce pas « ne pousse jamais la carte »** : sa réponse est « Un seul latéral sous 1280 px » puis « Non, lecture
  étroite » ; c'est **PU-G-204** qui écarte « le tiroir pousse la carte » (`plugin/cockpit/CHANGELOG.md` § Non publié). La
  borne tient ; sa source exacte est PU-G-204.
- **Plafonds** : extensions `ui/*.js` ≤ 300 lignes (`test-cockpit-vendor.sh`), `00-vibeflow.js` à 298 ; compteur
  « 213 suites » dans les deux README, contrôlé par `scripts/check-version-sync.sh` § 9 ; tout libellé neuf passe par le
  dictionnaire français.
- **M8** : la détection des services est déjà fondée sur le dépôt réel (patch P29 de `health.mjs`) ; le « supposé » de
  l'audit est à remesurer avant toute réécriture.
- **F3** ne vaut qu'au-delà de 1 279 px ; **F5** seulement en thème clair et dès 999 px ; **F1** compte deux `<select>`
  natifs, dont un dans la page du terminal (autre origine).

## Contrats consommés de la Phase 79

Source : `79-CONTEXT.md`, section « Contrats fournis » C0 à C6, branche `feat/phase-79-socle-cockpit`, commit
`3119d82a` (figés le 2026-11-11, amendement daté possible). Cités, jamais fusionnés.

- **C5 (coquille)** : les trois pages deviennent une coquille servie par le module, données par
  `GET /api/vf/graphe?onglet=code|projet|equipe` (formes inchangées, `ETag`) et par le magasin `window.VF_ETAT` (C4).
  Les onglets sans rechargement (FORM-16) se bâtissent dessus et seulement dessus.
- **C6-1 (appareil de patchs retiré en première vague de la 79)** : tout plan de la 80 qui modifie un fichier du moteur
  (`viewer.html`, `40-tour.js`, `05-theme.js`, autres fichiers `PATCH`) se place **après** cette vague : aucun diff à
  régénérer, et la fusion ne garde que la suppression. Les plans de la couche VF (fichiers `AJOUT`) n'en dépendent pas.
- **C6-2 (aide commune de lancement des suites)** : toute suite écrite par la 80 après la première vague de la 79
  l'utilise.
- **C0 (versions)** : ajouter un champ facultatif à un schéma ne change pas sa version — base de P80-D-06.
- **Amendement du 2026-11-11 de la 79** (`79-CONTEXT.md`, même branche, commit `2ae6607a`, A1 à A7), en réponse aux
  sept manques transmis par la 80 :
  - A1 : `/`, `/project.html` et `/equipe.html` restent servies par la même coquille ; le fragment est lu tel quel.
  - A2 : la 79 expose `VF_COQUILLE.chargerOnglet(nom)` (promesse résolue après le premier rendu) ; le routage,
    l'événement `vf:onglet`, le focus et l'historique sont à la 80 (P80-D-22).
  - A3 : l'iframe et l'amorce du terminal sont posées une fois par chargement de coquille ; usage unique et 60 s
    inchangés.
  - A4 : `render` est émis après la pose des positions par le worker ; `state.layout.children` et `freeArea()` gardés.
  - A5 : événement `graphe {seq, at, onglet, sig}` ; le lecteur relit `GET /api/vf/graphe?onglet=`. Le payload `patch`
    ne change pas et `vf-cockpit-live.mjs` reste à la 79 : les champs facultatifs du nœud phase (P80-D-06) arrivent par
    cette relecture ; la 80 ne modifie pas `vf-cockpit-live.mjs`.
  - A6 : aide commune des suites `plugin/cockpit/scripts/tests/socle-serveur.sh` (plan 79-02, première vague), à
    sourcer : `cockpit_lancer <lab> [opts]`, `cockpit_arreter`, `cockpit_get <chemin>`, `attendre <s> <cmd…>`.
  - A7 : le plan 79-01 retire `amont/` en première vague ; la 79 modifie `serve.mjs`, `graph-query.js`,
    `query-cli.mjs`, `scan.mjs`, `lib/common.mjs`, `lib/vf-git-sortant.mjs`, les modules `ui/70`, `75`, `78`, `79`,
    `80`, `viewer.html` à partir de sa vague 3, peut-être `40-tour.js` et `05-theme.js`. D'où P80-D-15 et P80-D-27.
  - Second amendement (commit `6f66d878`, A15 à A28) : A15, l'événement `lock` et le champ `lock` de `hello` portent
    `{ seq, at, verrous }` (forme de `signal.verrous`) — un lecteur neuf de la 80 (aucun n'est prévu) lirait cette forme,
    jamais l'ancienne ; A25, rien de l'état, de la frise, des verrous ni du plan de mission publié n'entre dans l'export
    autonome — les couloirs exportés se limitent aux données de `cockpit-project@1` ; A27, le graphe de Code est le
    `graph.json` sur disque, enrichi par des annotateurs inscrits dans `vf-cockpit-build.mjs` (point de partage avec la
    Phase 75) — la 80 n'ajoute aucun annotateur : sa navigation lit les cartes rendues, quelles que soient leurs
    annotations.
  - Règle commune A10/A11 : une route GET nouvelle s'inscrit dans la table des routes (une ligne, ordre alphabétique) et
    passe par la fonction unique de contrôle d'accès (plan 79-05). La 80 ne pose aucune route.

## Contrats fournis à la Phase 76

La Phase 76 se branche sur le panneau de l'onglet Projet par une route à elle (`GET /api/vf/tracabilite`), sans étendre
`cockpit-project@1`. Demande relayée par la session principale le 2026-11-11 ; réponses de la 80 :

- **P80-C76-1 — tenu tel quel.** `addPanelSection('item'|'overview', fn)` garde sa signature et son rappel `fn(cible)` à
  chaque rendu du panneau. Une carte de phase en couloirs (ou une ligne de la liste) ouvre le **même** panneau par
  `select(id)`, avec l'identifiant de nœud stable du graphe (`ph-<N>` ou `ph-<N>@<ws>`). Témoin dans le plan des couloirs :
  une section ajoutée par `addPanelSection('item')` apparaît après un clic sur une carte de couloir, avec la cible
  `ph-<N>`.
- **P80-C76-2 — tenu tel quel.** `setOverview` ne remplace que le corps de la vue d'ensemble ; les sections ajoutées par
  `addPanelSection('overview')` restent ajoutées après lui (ordre actuel du moteur, inchangé). La 80 ne modifie pas cette
  boucle ; témoin de non-régression dans le plan des couloirs.
- **P80-C76-3 — tenu sous une autre forme.** Ouverture programmatique : `select(id)` (panneau sur le nœud, sans changer
  de vue) et `reveal(id)` (va au nœud), déjà exportés et inchangés ; en mode couloirs, `reveal(id)` d'une phase
  sélectionne la carte de couloir au lieu de basculer sur le graphe. Le Retour commun est une **pile de sélections du
  panneau** posée par la 80 sur l'onglet Projet (`window.VF_PANNEAU.retour()` — l'objet `VibeFlow` du moteur est gelé (`Object.freeze`), d'où une globale à part, un bouton « Retour » dans l'en-tête du
  panneau, désactivé quand la pile est vide) ; la 76 y empile en appelant `select`.
- **P80-C76-5 — tenu, forme générique.** La pile accepte aussi une entrée qui n'est pas un nœud du graphe (exigence,
  ADR, décision, entrée de mémoire de la 76, panneau sur mesure ouvert par `showPanel`) :
  `window.VF_PANNEAU.empiler({ titre, rouvrir })`, où `titre` est une chaîne courte (rendue en texte, jamais en HTML) et
  `rouvrir` une fonction sans argument qui rouvre ce panneau. Une sélection de nœud s'empile d'elle-même (le panneau
  courant est empilé avant chaque `select` ou `showPanel` qui le remplace) ; une entrée générique s'empile par cet appel,
  juste avant d'ouvrir le panneau suivant. Le bouton « Retour » montre « Retour » suivi du titre de l'entrée du dessus
  (« Retour : Phase 72 », « Retour : REQ-12 »), tronqué au milieu, nom complet dans son nom accessible ; Retour dépile et
  appelle `rouvrir` (ou `select` pour un nœud) sans réempiler. La pile est bornée (32 entrées, la plus ancienne tombe),
  vidée au changement d'onglet et à la remontée à la racine ; une entrée dont `rouvrir` lève une erreur est retirée et le
  bouton passe à la suivante. Un seul Retour par panneau : la 76 n'a pas besoin d'un fil d'Ariane à côté. Décision
  déléguée par Samuel (message session principale, 2026-11-08), option recommandée, sur l'avis de la session principale.
- **P80-C76-6 — une seule porte pour les exigences et la couverture (demande de la 76, relayée par la session
  principale le 2026-11-11 ; retrait P76-D-25, plan 76-08).** Tout code de la 80 qui lit le nœud enfant « Exigences »
  d'une phase (`<ph>.req`), ses cartes d'exigence ou les liens « couvre » plan → exigence passe par **une seule
  fonction**, `lireExigences(phaseId)` de `assets/ui/41-vf-projet-phase.js` (exposée aux autres modules de Projet par
  une globale de la couche VF, l'objet du moteur étant gelé), qui rend les exigences de la phase (identifiant, texte,
  cochée ou non) et la couverture par plan (plan → exigences couvertes). Plan par plan :
  - **P80-D-05, liste à cocher (80-07)** : lue par `lireExigences` seulement (critère déjà écrit au plan) ;
  - **« N exigences couvertes » des rangées de plans (80-07)** : comptée depuis la couverture rendue par
    `lireExigences`, jamais par une lecture directe des liens ;
  - **P80-D-08, panneau d'un plan « Exigences couvertes » (80-11)** : la section est rendue par la couche VF
    (`41-vf-projet-panneau.js`) depuis `lireExigences` ; sur Projet, le moteur ne rend plus la liste générique des liens
    sortants « couvre » d'un plan (elle disparaîtrait au retrait) ;
  - **P80-D-04, graphe d'une phase** : le moteur dessine les nœuds et liens que porte le graphe ; la 80 n'y ajoute
    aucune lecture. Après le retrait de la 76, le graphe ne montre simplement plus ni exigences ni liens « couvre » :
    rien à rebrancher ;
  - aucune autre lecture : les champs `exigences {faits,total}` du nœud phase (80-03) sont calculés côté collecte par
    `piedExigences` depuis `REQUIREMENTS.md`, pas depuis le nœud (P80-C76-4).
  Critère vérifiable dans 80-07 et 80-11 : aucune occurrence de l'identifiant du nœud `.req` ni des liens de genre
  « couvre » dans les fichiers de la 80 hors du corps de `lireExigences`. La 80 s'exécute avant la 76 : elle lit encore le
  nœud à sa livraison ; la 76 n'a qu'à rebrancher cette fonction sur `meta.vf.trace.exigences`.
- **P80-C76-4 — tenu tel quel.** Le compte « x/y exigences » de la carte de phase est celui de `piedExigences` ; le champ
  structuré `exigences {faits, total}` ajouté par la 80 (P80-D-06) est calculé par la même fonction, une seule fois. La 76
  ne le recalcule pas et n'y touche pas.

## Contrats fournis aux autres phases

- **Pile de surcouches (Phases 73, 74)** : `window.VF_SURCOUCHES.ouvrir(el, { modale, ouvreur, fermer })` (globale à part : l'objet `VibeFlow` du moteur est gelé), `dessus()`,
  `ouverte()`. Toute surcouche nouvelle (fiche d'agent, lecteur plein cadre de la 74, régie de la 73) s'y enregistre au
  lieu de recopier une liste. Échap ferme le dessus de pile ; le terminal y est enregistré mais exclu d'Échap.
- **Clavier du canevas (Phase 75)** : les attributs (rôle, nom, `tabindex`) sont reposés à chaque `on('render')` ; la 75
  peut ajouter sa couche visuelle sans les écraser ; le nom accessible d'une carte est construit par une fonction unique
  que la 75 peut enrichir (mot d'activité) sans couleur seule.
- **Emplacement de preuve sur la carte de phase (Phase 76)** : un mot au plus sur la ligne d'état de la carte, lu depuis
  `avancement.reste` (`verification`, `recette`) ; le détail va dans le panneau.

<decisions>
## Implementation Decisions

Toutes « décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée », sauf mention.

### Projet en couloirs (AUDC-BL1, I23, X2, I25, X1)

- **P80-D-01 (où vit la vue).** Une vue DOM de la couche VF, en trois fichiers neufs `AJOUT` (modèle, rendu, vue, sur le
  découpage éprouvé du trio Git `77-*`), posée sur `project.html` à la place de la scène du moteur ; aucun patch du moteur
  pour les couloirs. Écartés : un mode de rendu dans `viewer.html` (patch lourd sur un fork de 2 579 lignes) ; des
  colonnes forcées dans la mise en page ELK (échelle de zoom au téléphone, contraire à DESIGNS § 6).
- **P80-D-02 (vue par défaut, retrait 1).** À la racine de Projet, les couloirs sont la vue par défaut à toute largeur ;
  le graphe reste accessible par une bascule (bouton et touche) et par le paramètre de requête `?vue=couloirs|liste|graphe`
  (gardé par `pushState`, que `setHash` n'efface pas). Les suites existantes qui supposent le canevas Projet passent
  `?vue=graphe` explicitement ; elles ne sont ni affaiblies ni supprimées. La 79 retouche toutes les suites (lancement
  par `socle-serveur.sh`, C6-2) : la 80 réduit ses retouches de suites existantes au minimum (de préférence l'aide
  commune qui construit l'adresse de `project.html`, sinon une ligne par suite) et les nomme dans la carte des fichiers.
- **P80-D-03 (forme des couloirs).** DESIGNS § 6 : en-tête de jalon (nom, « N phases faites sur M, K à recetter », barre
  d'avancement neutre et pourcentage strict) ; quatre colonnes À faire, En cours, À recetter, Fait, chacune avec son
  glyphe, son mot et son compte ; carte de phase = numéro en chasse fixe, titre, une ligne d'état (« 16 plans sur 16 ·
  11 exigences sur 12 », « pas de plan · non cadrée »). Un bloc par jalon actif, le jalon en cours d'abord ; jalons clos
  dans « Historique », replié. Ni fond teinté ni couleur d'alerte (Q9) ; grille fermée (P71.5-D-01) ; une colonne vide
  dit « aucune phase » en texte neutre.
- **P80-D-04 (profondeur).** Couloirs à la racine seulement. À l'intérieur d'une phase : le graphe du moteur (les liens
  « puis » et « couvre » y ont un sens) ou la liste (P80-D-05). Couloirs de plans écartés (trois états seulement, liens
  perdus). Le nœud « Exigences » (`<ph>.req`) et les liens « couvre » sont dessinés dans le graphe d'une phase tant que
  le graphe les porte ; aucun témoin de la 80 n'affirme leur présence dans le graphe (les suites de la 80 lisent les
  exigences et la couverture par `lireExigences`, P80-C76-6) : le retrait de la Phase 76 (P76-D-25, 76-08) ne rougit
  aucune suite de la 80. Précision du 2026-11-11, à la demande de la session principale.
- **P80-D-05 (liste et tableau, AUDC-I25).** Un seul modèle, deux mises en page : « tableau » = les couloirs (colonnes
  empilées ≤ 700 px) ; « liste » = rangées triables (numéro, état, plans, exigences ; dans une phase : plans par vague,
  exigences en liste à cocher, lecture seule). Touche `v` (bascule), bouton équivalent ; liste par défaut au téléphone.
  Choix mémorisé en `localStorage` par lab et par classe de largeur, jamais dans `.planning/`. Projet seulement (Code
  reste une carte).
- **P80-D-06 (données, contrat).** Champs facultatifs ajoutés au nœud phase de `vibeflow/cockpit-project@1` :
  `avancement` (objet `avancement@2` déjà calculé) et `exigences { faits, total }` (même calcul que `piedExigences`) ;
  `vague` structurée sur le nœud plan ; `statuts` du contrat corrigé avec `recette`. Pas de montée en `@2` (rien n'est
  retiré ni redéfini : règle C0 de la 79 et politique du README du module). `foot` et `st` gardent leur sens. Le
  rafraîchissement en direct de ces champs passe par l'événement `graphe` et la relecture de
  `GET /api/vf/graphe?onglet=projet` (A5 de la 79) ; avant la livraison de la 79, ils se rafraîchissent au rechargement
  (le plan le dit et son témoin ne prétend pas au direct). La 80 ne modifie pas `vf-cockpit-live.mjs`.
- **P80-D-07 (Backlog, Graines, Releases — retrait 2, AUDC-X2).** Une liste sous les couloirs, plus de vignettes ; le
  statut du backlog (« DIFFÉRÉ ») sort du pied de carte côté données, la pastille dit seule l'état.
- **P80-D-08 (vocabulaire du planning, AUDC-X1).** Trois causes, trois corrections : le dictionnaire (« Élément »,
  « module » sur Projet) ; dans le moteur, la ligne « module » écrite en dur remplacée par `meta.kindLabels` et la règle
  « document » (« Mentions ») neutralisée sur l'onglet Projet ; le panneau d'un plan dit statut, vague et exigences
  couvertes, et le texte d'une exigence n'est plus répété trois fois.
- **P80-D-09 (visite et direct).** La visite de Projet bascule en graphe avant de jouer (ses cibles sont des cartes) ; la
  bascule est déclenchée depuis la couche VF si la visite expose un point d'entrée, sinon la retouche de `40-tour.js`
  (fichier du moteur) part au lot moteur A ; la vue couloirs se redessine sur `on('render')` après un patch du direct.

### Clavier et surcouches (AUDC-BL2, M6, X3, I24) — première vague conseillée par l'audit

- **P80-D-10 (modèle clavier du canevas).** Tabulation itinérante : un seul arrêt pour le canevas, flèches entre cartes
  par **voisin spatial** (positions de `state.layout.children` ; ←/→ entre couches, ↑/↓ dans la colonne), Origine/Fin
  dans l'ordre de lecture, Entrée plonge, Échap remonte, le focus revient sur une carte après la plongée et la remontée.
  Rôles : `listbox` sur le canevas avec un nom (« Carte : <niveau>, N cartes »), `option` + `aria-selected` sur chaque
  carte, nom = titre + mot d'état + compte (« reliée à N »), arêtes masquées aux lecteurs d'écran. Au bureau la sélection
  suit le focus ; au téléphone non (la sélection y ouvre la feuille). Couche VF, fichier neuf, attributs reposés à chaque
  `on('render')` : aucun patch du moteur. Écartés : chaque carte tabulable (le parcours X4 n'atteindrait plus le champ de
  question) ; une liste cachée parallèle (seconde vérité, anneau invisible) ; voisin par les arêtes (carte sans lien
  inatteignable) ; `application`, `tree`, `grid` (APG).
- **P80-D-11 (pile de surcouches).** Une pile unique dans la couche VF, chargée tôt (fichier neuf trié avant les autres
  extensions) : `ouvrir`, `dessus`, `ouverte`. Modales (palette, export, santé, visite ouverte par le bouton, aide `?`) :
  piège à Tab, `inert` sur le reste, focus rendu à l'ouvreur ; les `inert` posés par la pile sont suivis à part pour ne
  jamais lever celui du terminal. Non modales (tiroirs Git et « Au travail », visite ouverte d'elle-même) : dans la pile
  pour l'ordre d'Échap, sans piège, sans prendre le focus (Q5). Terminal : enregistré, exclu d'Échap (le shell en a
  besoin). Échap écouté au niveau du document, en capture. Les trois listes recopiées passent par la pile (retrait 4).
  La part qui vit dans le moteur (panneau fermé `visibility:hidden` après sa transition, rôle `dialog` de la palette,
  résultats en `listbox` avec `aria-activedescendant`) va au plan moteur (P80-D-15).
- **P80-D-12 (zoom et garde, AUDC-X3).** Le centre du zoom est la carte sélectionnée si elle est visible, sinon le centre
  de la zone libre ; facteurs 1,25/0,8 partout (aller-retour exact). Garde de saisie unique : `INPUT`, `TEXTAREA`,
  `SELECT`, `contenteditable` ; une lettre seule est ignorée avec ⌘, Ctrl ou Alt. Patch du moteur (P80-D-15).
- **P80-D-13 (aide des raccourcis).** `?` ouvre une modale générée depuis un registre unique des raccourcis, filtré par
  onglet ; listée dans la palette.
- **P80-D-14 (palette, AUDC-I24).** Étendre la recherche du moteur (un seul champ, `/` et ⌘K/Ctrl+K déjà existants) par
  un point d'extension de sources et des résultats porteurs d'une action ; préfixe `>` pour les seules actions. Sources
  dans cette phase : les entités de la page courante (inchangé), les actions de vue (Ajuster, Monter, Détail, Git, Aide,
  bascule couloirs/liste/graphe) et le changement d'onglet. Les entités des autres onglets (phases depuis Code, agents)
  attendent la coquille de la 79. Aucune action ne déclenche un envoi (Q4) : « Demander » ne fait que remplir la barre.

### Navigation sur la carte du code (AUDC-M1, I26, I27, I29, X8)

- **P80-D-15 (lot moteur, séquentiel).** Tous les changements de `viewer.html` sont portés par deux plans successifs,
  un seul codeur à la fois sur ce fichier, placés **après la fusion de la Phase 79 entière** dans la branche d'intégration
  (C6-1 : plus aucun diff à régénérer ; A7 : la 79 modifie `viewer.html` à partir de sa vague 3, et peut-être `40-tour.js`
  et `05-theme.js`) : (A) zoom, garde de saisie,
  formule de cadrage unique exposée (`cadrage({ plancher })`) que `76-vf-git-entete.js` et `40-tour.js` appellent
  (retrait 3), part moteur de M6, part moteur de X1, lien de vue (P80-D-21) ; (B) palette et aide `?`.
- **P80-D-16 (minicarte et repères de bord).** Minicarte (vignette, cadre du champ, clic pour aller) dans le coin bas-droit
  de la scène, ≤ 144 × 96 px, à partir de 1 000 px et à la souris ; repères de bord « N cartes par là », cliquables, à
  toute largeur, seuls dispositifs sous 1 000 px et au tactile. La minicarte grise la part du champ cachée sous le tiroir
  Git ; `freeArea()` ne déduit pas le tiroir Git (le déduire recadrerait la carte, ce que PU-G-204 écarte). Le plancher
  11/13 reste (PU-G-026).
- **P80-D-17 (cadrer la sélection et ses voisins, AUDC-I27).** Dans cette phase : une action qui cadre la carte
  sélectionnée et ses voisins du niveau courant, plancher respecté, sans nouvelle mise en page. Le mode focus qui
  recompose un sous-graphe par ELK va en réserve (après le worker de mise en page de la 79) — consigné au rapport.
- **P80-D-18 (ligne d'état, AUDC-I29 et X8).** Pas de bande pleine largeur (conflit avec le tiroir du terminal posé au
  bord bas, P71-D-35, et la zone basse du téléphone) : une ligne d'état compacte jointe à la minicarte, coin bas-droit,
  à partir de 1 000 px : branche entière (ellipse au milieu, nom complet au survol), point du direct, « Mis à jour à
  HH:MM ». Sans `--terminal`, aucun segment du terminal (P71-D-02) ; « Terminer » reste dans la barre du tiroir. Au
  téléphone : zone basse dégagée (zoom, pastille et minicarte ne recouvrent pas la carte sélectionnée), cibles tactiles
  ≥ 44 px, onglets à hauteur de cible.

### Tiroir Git, jetons, onglets

- **P80-D-19 (tiroir Git, AUDC-M12).** Pagination « Afficher 100 de plus » (au plus ~110 rangées au départ) plutôt que
  virtualisation (tabulation itinérante et détail gardés) ; worktrees repliés avec leur compte dans le titre ; détail d'un
  commit dans un volet bas du tiroir (le mettre dans le panneau ouvrirait un second latéral, interdit sous 1 280 px) ;
  largeur réglable par une poignée `role=separator` utilisable aux flèches, bornée par la formule existante, mémorisée en
  `localStorage`, absente sous 1 000 px ; le tiroir reste posé par-dessus sans pousser la carte (PU-G-204).
- **P80-D-20 (jetons et finitions, X5, F1, F3, F4, F5).** Un lot unique, contraste mesuré dans les deux thèmes : texte
  ≥ 4,5:1, non-texte ≥ 3:1, glyphe « En cours » visé ≥ 3,5:1, texte des cartes estompées ≥ 4,5:1. Carte active en clair
  signalée par un contour ou le glyphe, jamais par un fond teinté (Q9). Chiffres tabulaires de la police de texte (F4).
  Pastilles du menu « ⋯ » aux mêmes teintes qu'au bureau (F5). Bouton de thème à 36 px au-delà de 1 279 px (F3), 44 px
  au tactile ; l'ouvreur Git à 44 px relève de P78-D-34 : vérifié dans `78-CONTEXT.md` avant d'y toucher, laissé tel
  quel si c'est un arbitrage. Composants à la charte pour les triangles de `<details>` et les deux `<select>` natifs
  (F1), y compris celui de la page du terminal. `DESIGN.md` mis à jour pour tout jeton changé.
- **P80-D-21 (lien de vue, sans la 79 — FORM-15).** Le fragment porte déjà `v=` et `s=` : il gagne le zoom (`z=k,x,y`) et
  l'état « tiroir Git ouvert » ; « Copier le lien de cette vue » dans la palette ; l'état des tiroirs survit au
  changement d'onglet par `sessionStorage` dès cette phase, même avec rechargement.
- **P80-D-22 (onglets sans rechargement, AUDC-I30, X7 reste, F7 — FORM-16).** Sur la coquille C5, le magasin C4 et
  `VF_COQUILLE.chargerOnglet(nom)` (A2) de la 79, uniquement : la 80 pose le routage (clic d'onglet et palette →
  `pushState` + `chargerOnglet`, `popstate` pour Précédent/Suivant), l'événement `vf:onglet`, le focus (posé sur le titre
  de la vue chargée, annoncé) et le titre d'onglet « <Onglet> · <nom> » (X7) ; tiroirs, zoom et terminal gardés. Plan à
  part, dépendance déclarée sur la fusion de la 79 entière. Témoin F7 : une chaîne écrite dans
  le terminal est toujours dans le tampon après un aller-retour d'onglet ; l'amorce à usage unique de 60 s (P71-D-27)
  n'est pas affaiblie.

### Méthode

- **P80-D-23 (vagues et fichiers partagés).** Vague 1 : la couche VF sans moteur (clavier du canevas, pile de surcouches,
  données de Projet) — fichiers disjoints. Vague 2 : couloirs et liste, minicarte et ligne d'état, tiroir Git — fichiers
  disjoints. Vagues 3, 4 et 5 : lot moteur A, puis B, puis jetons (seul plan sur `viewer.html` à chaque fois), après la
  fusion de la 79 ; le cadrage des voisins suit le lot A. Vague 6 : onglets sans rechargement (après la 79). Plan
  d'assemblage en dernier. Les vagues 1 et 2 ne dépendent pas de la 79 et peuvent s'exécuter avant elle.
- **P80-D-24 (compteur de suites et CHANGELOG).** Les témoins vont de préférence dans des suites neuves propres à chaque
  plan (fichiers disjoints entre plans d'une même vague) ; le compteur des deux README, la table de durées du partage CI
  et l'entrée « Non publié » du `CHANGELOG.md` du module ne sont écrits que par le plan d'assemblage, une fois, pour
  éviter des conflits de lignes voisines entre plans parallèles. Chaque plan consigne dans son SUMMARY la ligne de
  CHANGELOG qu'il demande.
- **P80-D-25 (preuves).** Chaque comportement ou correction porte un témoin qui rougit sur le code de la base et verdit
  après, avec la trace du rouge (assertion, attendu, obtenu) ; un mutant pour chaque garde ; mouvement réduit tenu (zéro
  animation active, X6) pour toute animation neuve, y compris écrite en JavaScript ; les sondes de `sondes/` mesurent,
  elles ne prouvent pas. Les suites existantes ne sont jamais affaiblies pour verdir.
- **P80-D-26 (lecture seule et bornes).** Aucune route nouvelle qui écrit ; aucune lecture réseau ; rien du terminal sans
  `--terminal` ; la dernière commande n'apparaît nulle part (P67-D-14) ; verbe et cible réduite seulement (P69-D-16) ;
  le double geste reste dû ; pas de quatrième onglet (P78-D-04) ; points de rupture inchangés (Q11).

- **P80-D-27 (fichiers que la 79 modifie aussi).** Pour ne pas croiser la 79 sur ses fichiers : les libellés neufs de la
  80 vont dans un dictionnaire à elle (un fichier `ui/` neuf chargé avec les deux dictionnaires existants, mécanisme à
  vérifier par le planificateur), pas dans `78-vf-fr-dict-a.js`, `79-vf-fr-dict-b.js` ni `80-vf-fr.js` ; la 80 ne modifie
  ni `70-vf-live.js`, ni `75-vf-modele.js`, ni `vf-cockpit-live.mjs`, ni `serve.mjs`. Ce qui ne peut pas l'éviter
  (`viewer.html`, `40-tour.js`, `05-theme.js`, F1 dans `75-vf-modele.js` si le sélecteur y vit) est porté par les plans
  placés après la fusion de la 79 (P80-D-15), et nommé dans la carte des fichiers du rapport. Toute suite écrite après la
  première vague de la 79 lance le serveur par `socle-serveur.sh` (A6) ; avant, par le moyen actuel.

### Points relevés par le craft (`80-UI-SPEC.md` § 8), tranchés au cadrage

- **P80-D-28 (barre d'avancement d'un jalon en cours).** `DESIGN.md` fait foi : la barre d'un élément en cours prend la
  teinte d'état prévue par `DESIGN.md` § 5, comme toute barre « en cours » (« barres neutres sauf en cours »,
  P71.5-D-12 et suivantes) ; neutre sinon. Les maquettes de l'audit (neutre partout) cèdent à la référence.
- **P80-D-29 (place du panneau dans la vue couloirs — révisée après la critique).** `DESIGN.md` § 5 fait foi : le
  panneau de détail se pose par-dessus sans pousser ni réserver de place. La mise en page des couloirs ne change pas à
  l'ouverture ou à la fermeture du panneau (pas de bascule de quatre colonnes vers une grille 2 × 2) ; la carte
  sélectionnée est amenée dans la partie visible si le panneau la couvre (défilement instantané). La réserve proposée au
  craft est écartée.
- **P80-D-30 (écarts des maquettes).** Valeurs hors grille des maquettes (10 px, 34 px) ramenées à la grille fermée ;
  cartes sur `--surface` (`DESIGN.md` § 5) ; ligne d'état présente sur toutes les cartes, « Fait » compris ; « Missions
  hors phase » rangées avec Backlog, Graines et Releases.

- **P80-D-31 (carte active en thème clair, AUDC-X5).** La ligne de `DESIGN.md` § 5 qui prescrit le gris pour la carte
  active claire, que l'audit mesure « lue comme désactivée », est modifiée par le lot jetons : contour ou glyphe d'état,
  jamais un fond teinté ; `--st-active` clair passe à une valeur ≥ 3,5:1 sur `--bg` sans toucher `--sev-medium` (pour ne
  pas faire tomber le texte des puces), et l'exception s'écrit dans `DESIGN.md`. Pas une réouverture : aucun registre ne
  porte un arbitrage de Samuel sur cette valeur ; `DESIGN.md` reste la référence et change avec sa justification mesurée.
- **P80-D-32 (raccourcis proposés par le craft).** une touche pour « cadrer la sélection et ses voisins » (P80-D-17, fixée par P80-D-45) ; Espace
  sélectionne au téléphone ; les repères de bord sont des boutons dans l'ordre de tabulation. L'aide `?` les liste.

### Amendement du 2026-11-11 après la recherche (`80-RESEARCH.md`)

Faits établis par la recherche qui corrigent la forme de décisions déjà prises ; aucune n'en change le fond.

- **P80-D-33 (globales à part).** L'objet `VibeFlow` (`window.Floorplan` du moteur) est gelé : les contrats publics de la
  80 sont `window.VF_SURCOUCHES` (pile, P80-D-11) et `window.VF_PANNEAU` (Retour, P80-C76-3). Signalé aux Phases 73, 74
  et 76 par la session principale.
- **P80-D-34 (pile et modale du moteur, précise P80-D-11).** La modale du moteur intercepte Échap avant la pile (écouteur
  en capture sur `window`) : la pile observe `#modal` et `#palette` (ouverture, fermeture) au lieu de les fermer elle-même,
  et ferme seule ce qui lui appartient. Le panneau fermé sort de la tabulation par une règle CSS de la couche VF, sur le
  modèle de celle du téléphone : ce point passe en vague 1, hors lot moteur.
- **P80-D-35 (« Élément », précise P80-D-08 et P80-D-27).** Le dictionnaire `80-vf-fr.js` réapplique « Élément » après
  fusion et une suite l'exige pour le Code : la correction de Projet passe par le moteur (libellé de type tiré de
  `meta.kindLabels`, lot A), sans toucher `80-vf-fr.js` ni la suite. Les libellés neufs de la couche VF sont écrits en
  français dans leur fichier (la couche VF est hors inventaire de traduction) ; s'il faut traduire une phrase du moteur,
  un dictionnaire neuf `79-vf-fr-dict-c.js` est chargé et fusionné sans toucher aux trois existants.
- **P80-D-36 (anneau de focus des cartes, précise P80-D-10).** L'anneau se dessine sur la `.card` ; la mesure de la sonde
  X4 existante est étendue à la `.card` dans le même plan, jamais affaiblie.
- **P80-D-37 (adresse de `project.html`, précise P80-D-02).** `?vue=graphe` se pose une fois dans `naviguer()` de
  `chrome-session.mjs`, avec une option de sortie pour les suites des couloirs ; les deux pilotes propres et la page
  `file://` relevés par la recherche sont traités un par un.
- **P80-D-38 (visite, précise P80-D-09).** `window.FloorplanTour` est exposé : la bascule en graphe avant la visite se fait
  depuis la couche VF (clic du bouton intercepté ; ouverture automatique détectée, le moteur restant rendu sous les
  couloirs), sans patch de `40-tour.js`.
- **P80-D-39 (mémoire par lab, précise P80-D-05 et P80-D-19).** Le stockage du moteur ne distingue pas les labs et
  l'origine change avec le port : les clés `localStorage` de la 80 portent le nom du lab.
- **P80-D-40 (aide de lancement).** `socle-serveur.sh` n'existe pas encore : les suites des vagues 1 et 2 lancent le
  serveur comme `test-cockpit-accessibilite.sh` ; celles écrites après la première vague de la 79 utilisent l'aide.
- **P80-D-41 (lignes `AJOUT`).** Chaque plan insère la ligne `AJOUT` de son fichier neuf à sa place alphabétique dans
  `VENDORED.txt` (lignes non voisines entre plans parallèles).

- **P80-D-42 (initialisation par onglet, A30 de la 79, commit `74501bb0`).** Tout module de page neuf de la 80 qui dépend
  de l'onglet s'initialise par `VF_COQUILLE.surOnglet(rappel)` quand la coquille existe (le rappel rend sa fonction de
  nettoyage), et par l'événement `ready` du moteur avant la livraison de la 79 ; jamais au seul chargement de la page. Le
  plan des onglets sans rechargement n'a donc pas à connaître la liste des extensions à réabonner : la 79 convertit les
  siennes (plan 79-16).
- **P80-D-43 (extrémité défilable des couloirs, précise P80-D-29).** Panneau ouvert, le rail des couloirs gagne une
  extrémité défilable de la largeur du panneau : l'étendue défilable s'allonge, aucun couloir ne bouge. Ce n'est pas une
  réserve (la mise en page est identique panneau ouvert ou fermé) ; elle permet d'amener la carte sélectionnée hors du
  panneau. Même règle au bord gauche pour le tiroir Git (extrémité défilable, `scroll-padding-inline-start`) :
  aucun couloir ne bouge, PU-G-204 tenu.

- **P80-D-44 (où se posent les champs de Projet, A31/A32 de la 79, commit `e04c43e7`).** Les champs facultatifs de
  P80-D-06 (`avancement`, `exigences {faits,total}` sur la phase, `vague` sur le plan) se posent dans la lecture du
  planning de la collecte (`plugin/cockpit/scripts/vf-cockpit-planning.mjs`, `readPlanning`) puis sont projetés sur le
  graphe (`vf-cockpit-project.mjs`) ; jamais par une lecture à part. `vf-cockpit-planning.mjs` est aussi modifié par la
  79 et par la 75 : collision nommée dans la carte des fichiers. **La 80 pose `vague`** sur le plan (son panneau et sa
  liste en ont besoin, et ses vagues 1 et 2 ne dépendent pas de la 79) ; la Phase 75 la lit et n'ajoute que
  `files_modified`. La 80 ne calcule rien côté serveur hors de cette lecture : `vf-cockpit-instantane.mjs` (A31) ne la
  concerne pas.

- **P80-D-45 (touche de « cadrer la sélection et ses voisins », remplace la touche de P80-D-32).** `C` (« Cadrer »),
  lue comme `c`, ignorée avec ⌘, Ctrl ou Alt (⌘C et Ctrl+C restent la copie), dans un champ de saisie et sur Équipe ;
  libre dans l'écouteur global du moteur et dans le registre. Maj+F écartée : `F` majuscule appelle déjà « Ajuster ».
- **P80-D-46 (deux lignes de `DESIGN.md` écrites par le lot jetons).** L'exemption de l'anneau de focus dans la règle
  « deux intentions d'élévation » (§ 9) et l'exception des rangées de 40 px du tiroir Git existant (§ 4), textes proposés
  dans `80-UI-SPEC-NAVIGATION.md`.

- **P80-D-47 (plonger depuis les couloirs).** Cohérence avec le canevas : au bureau, la sélection suit le focus dans les
  couloirs et la liste (le panneau montre la phase focalisée) et Entrée plonge dans la phase ; au téléphone, Entrée
  sélectionne (ouvre la feuille) et « Ouvrir la phase » est dans la feuille.

- **P80-D-48 (fusion de `VENDORED.txt` entre plans d'une même vague, précise P80-D-41 ; relevé par la vérification
  fraîche des plans).** Quand deux plans d'une même vague s'exécutent en parallèle et ajoutent chacun une ligne `AJOUT`,
  le conflit de fusion sur `VENDORED.txt` se résout par l'union des lignes, triées à leur place alphabétique, sans rien
  retirer ; c'est la seule résolution permise. Après la fusion de la 79, la forme du fichier est celle que la 79 laisse
  (C6-1) : les plans des vagues 4 et suivantes y inscrivent leurs fichiers neufs selon cette forme.
- **P80-D-49 (taille du plan « après avis de Samuel »).** Le plan 80-19 compte 13 fichiers parce qu'il porte cinq
  décisions indépendantes (S80-1 à S80-5) ; il n'est pas exécutable en l'état et sera redécoupé à la réponse de Samuel
  (une option écartée retire ses fichiers). Pas de découpage préalable : il figerait des réponses non rendues.

- **P80-D-50 (fermeture du dernier majeur de design, après trois tours de craft ; prime sur les UI-SPEC là où elles
  diffèrent).** Le juge frais du troisième tour rend 85 et 86/100 et un majeur ouvert sous 1 000 px. Le budget de trois
  tours étant atteint, le manager tranche et les specs reçoivent un erratum d'application, sans nouvelle conception :
  (a) sous 1 000 px, la zone basse `--vf-bas` compte aussi la hauteur de la feuille de détail quand elle est ouverte ;
  (b) les extrémités défilables et `scroll-padding-inline-*` ne valent qu'à partir de 1 000 px au pointeur fin (aucun
  défilement horizontal à 390 px) ; (c) la pastille Terminal entre dans la liste des éléments dégagés de la zone basse ;
  (d) un seul ordre de repli du focus orphelin, celui de la famille (`80-UI-SPEC.md` § 5) — ses instances (repères,
  tiroir Git) le citent sans le réécrire ; (e) au changement d'onglet, la règle de repli unique s'applique (élément
  sélectionné, sinon `h1`) ; (f) seuil de troncature 52 caractères partout, plus petite carte ≈ 226 px, mesure en
  graisse 600.
- **P80-D-51 (Entrée à toute largeur, révise P80-D-47).** Une seule règle de touches pour Projet, à toutes les largeurs
  et dans toutes les formes, comme sur le canevas : Entrée plonge, Espace sélectionne ; au toucher, un appui sélectionne
  (la feuille s'ouvre au téléphone) et « Ouvrir la phase » est dans la feuille. Au bureau, la sélection suit le focus
  dans les couloirs et la liste.

### Reprise du 2026-11-11 (arbitrages rendus, contrats de la 79 à la tête `317d34c7`)

- **P80-D-57 (redécoupage du plan « après avis »).** Le plan unique des réouvertures devient des plans exécutables, placés
  dans les vagues ordinaires après la fusion de la Phase 79 : titre de vue et en-tête (P80-D-52, P80-D-53, P80-D-56 :
  mêmes fichiers d'en-tête et `viewer.html`), Santé en français dans le collecteur (P80-D-54), ligne de l'aide et de la
  palette (P80-D-55, registre des raccourcis de 80-14). Plus aucun plan non autonome. Décision déléguée par Samuel
  (message session principale, 2026-11-08), option recommandée.
- **P80-D-58 (règles de la 79 à la tête `317d34c7`, amendements A34 à A44 ; même délégation).** Chaque plan de la 80 les
  tient : (a) un fichier de code du module fait **299 lignes au plus** (`check-file-size.sh`, A44) ; (b) aucune ligne de
  plus de **160 colonnes** dans un fichier neuf (cliquet de colonnes de 79-11, baseline 0 pour un fichier neuf) ; (c) le
  code du tiroir du terminal et du lancement vit sous `assets/ui/tiroir/` et la page du terminal sous
  `assets/ui/terminal/` (A43) : F1 vise `assets/ui/terminal/vue.js` (et sa feuille de style) et
  `assets/ui/tiroir/lancer.js`, plus `vf-cockpit-terminal-vue.mjs` ni `vf-cockpit-lancer-ui.mjs` ; (d) coquille et CSP
  (A40, A41) : aucun script en ligne ajouté à `viewer.html` ni à la coquille, les extensions neuves sont des fichiers du
  module servis sous `/_vf/`, et aucune suite ne lit un fichier de la sortie par service statique ; (e) le compteur de
  suites s'écrit au nombre réel compté par le gate, jamais en littéral recopié (A34) ; (f) Santé : la 79 garde les
  motifs `R` et `P` de `80-vf-fr.js` pour reconnaître les constats traduits à l'affichage (A43, A44) — P80-D-54 traduit
  à la source dans le collecteur sans retirer ces motifs ; (g) références exactes : aide de lancement `socle-serveur.sh`
  (79-02, retouchée par 79-11), coquille et `chargerOnglet` (79-16), `VF_ETAT` (79-17), worker de mise en page (79-18),
  porte du flux `window.VF_FLUX` (79-14).

### Claude's Discretion

Noms exacts des fichiers neufs (dans la plage `ui/` qui garantit l'ordre de chargement), découpage interne sous le
plafond de 300 lignes, libellés français exacts (dictionnaire), forme exacte des témoins, à condition de tenir les
décisions ci-dessus et l'UI-SPEC de la phase.
</decisions>

## À Samuel

Questions au format C76-Q1 (`76-CONTEXT.md`, Phase 76, P76-D-34). Les cinq ont été posées au cadrage sous les libellés
S80-1 à S80-5 et tranchées par Samuel le 2026-11-11 ; les décisions qui en découlent sont P80-D-52 à P80-D-56
(section « Arbitrages de Samuel » ci-dessous).

- **P80-Q-01 — Titre de vue flottant (S80-1, AUDC-M2, rouvre Q10).** Le bloc de titre, sans fond, se superpose aux
  cartes de Code et du graphe de Projet : faut-il lui donner une place à lui ?
  Options : (a) garder Q10 tel quel ; (b) une zone réservée au titre, 130 px au plus, flou et texte court gardés ; (c) le titre de vue monte dans l'en-tête (fil d'Ariane).
  Recommandation : (b) — le flou et le texte court restent, seule la superposition disparaît.
  Bloque : rien
  État : tranchée — arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 — option (b) — « Zone réservée (Recommandé) »
- **P80-Q-02 — En-tête illisible (S80-2, AUDC-M5, rouvre P70-D-22 et PU-G-001).** Neuf icônes sans libellé, trois
  icônes trompeuses, branche tronquée : comment rendre l'en-tête lisible ?
  Options : (a) garder ; (b) trois groupes libellés au-delà de 1 280 px, fil d'Ariane à chevron, trois icônes remplacées, badge et troncature inchangés ; (c) (b) plus le badge « au travail » libellé et la branche entière.
  Recommandation : (b) — ne rouvre que PU-G-001 en partie, P70-D-22 intact.
  Bloque : rien
  État : tranchée — arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 — option (b) — « Trois groupes libellés (Recommandé) »
- **P80-Q-03 — Santé en anglais (S80-3, AUDC-M8, rouvre P70-D-04 et P67-D-20).** Les constats du panneau Santé
  restent en anglais dans une interface française : faut-il les traduire ?
  Options : (a) garder les constats en anglais ; (b) traduire les gabarits des constats dans le collecteur, noms propres gardés ; (c) (b) et revoir l'introduction après remesure.
  Recommandation : (b) — l'introduction n'est pas retouchée sans nouvelle mesure.
  Bloque : rien
  État : tranchée — arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 — option (b) — « Traduire les constats (Recommandé) »
- **P80-Q-04 — Terminal absent sans explication (S80-4, reste de AUDC-M10, rouvre P71-D-02).** Sans `--terminal`,
  rien n'existe et rien ne l'explique : faut-il le dire, et où ?
  Options : (a) garder « rien sans l'option » ; (b) une ligne « Le terminal s'active avec --terminal » dans l'aide et la palette, sans pastille, port ni route ; (c) une pastille inerte expliquée.
  Recommandation : (b) — explique sans rien ajouter à l'écran ni au réseau.
  Bloque : rien
  État : tranchée — arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 — option (b) — « Une ligne dans l'aide (Recommandé) »
- **P80-Q-05 — Ouvreur Git à 44 px parmi des boutons à 36 (S80-5, AUDC-F3 en partie, rouvre P78-D-34).** L'en-tête
  doit-il retrouver une seule taille de bouton sans perdre la cible tactile ratifiée ?
  Options : (a) garder 44 px ; (b) dessin à 36 px, zone d'appui gardée à 44 px ; (c) 36 px partout au-delà de 999 px.
  Recommandation : (b) — la cible d'appui de P78-D-34 est gardée et l'en-tête retrouve une taille.
  Bloque : rien
  État : tranchée — arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 — option (b) — « 36 visibles, 44 d'appui (Recommandé) »

## Arbitrages de Samuel sur les réouvertures (P80-Q-01 à P80-Q-05, ex-S80-1 à S80-5)

Les cinq questions posées au cadrage ont été tranchées par Samuel : **arbitrage Samuel, AskUserQuestion session
principale, 2026-11-11**, relayé au manager par la session principale le même jour. Chaque réponse est recopiée mot pour
mot (libellé coché, puis l'option telle qu'elle lui a été présentée). Aucune option « révision du plan » n'a été retenue.
Chaque arbitrage d'origine n'est amendé que dans la mesure exacte de l'option retenue, pas au-delà.

- **P80-D-52 (P80-Q-01, ex-S80-1, AUDC-M2 — amende Q10).** Réponse : « Zone réservée (Recommandé) » — « Le titre garde son flou et
  son texte court, mais dans une zone à lui (130 px au plus, que la mise en page sait déjà déduire) : les cartes ne
  passent plus dessous. Votre réponse d'origine est gardée, seule la superposition disparaît. » Option (b) du cadrage.
  Q10 (« Flou gardé, texte court ») tient : seule la superposition du bloc de titre sur les cartes disparaît. Vaut pour
  Code et pour le graphe de Projet ; les couloirs et la liste ont déjà leur `h1` dans le flux.
- **P80-D-53 (P80-Q-02, ex-S80-2, AUDC-M5 — amende PU-G-001 en partie ; P70-D-22 intact).** Réponse : « Trois groupes libellés
  (Recommandé) » — « Au-delà de 1 280 px de large, les boutons sont rangés en trois groupes qui portent un libellé ; le
  fil d'Ariane prend un chevron ; les trois icônes trompeuses sont remplacées. Le badge « au travail » et la troncature
  de la branche ne changent pas : votre compromis n'est rouvert qu'en partie. » Option (b). Le badge « au travail »
  réduit à son point entre 701 et 1 639 px (P70-D-22) et la troncature de la branche (« Garder ce compromis »,
  PU-G-001) restent ; seuls le rangement en groupes libellés au-delà de 1 280 px, le chevron et les trois icônes
  (« Parcours », « Travail récent », sessions/agents) changent.
- **P80-D-54 (P80-Q-03, ex-S80-3, AUDC-M8 — amende P70-D-04 et, derrière lui, P67-D-20).** Réponse : « Traduire les constats
  (Recommandé) » — « Les gabarits des constats passent en français dans le collecteur ; les noms propres (outils,
  services) restent tels quels. L'introduction de l'onglet n'est pas retouchée sans nouvelle mesure. » Option (b).
  Les constats du panneau Santé ne restent plus en anglais (fin de P70-D-04 sur ce point) ; P67-D-20 (l'anglais reste une
  langue admise) tient pour le reste. L'introduction de Santé n'est pas retouchée dans cette phase.
- **P80-D-55 (P80-Q-04, ex-S80-4, AUDC-M10 reste — amende P71-D-02).** Réponse : « Une ligne dans l'aide (Recommandé) » — « Une ligne
  dans l'aide « ? » et dans la palette : « Le terminal s'active avec --terminal ». Aucune pastille, aucun port, aucune
  route : rien ne s'ajoute à l'écran ni au réseau. » Option (b). P71-D-02 (sans le drapeau : aucun port, aucune route,
  aucun tiroir) tient en entier ; seule une ligne de texte s'ajoute à l'aide `?` et à la palette.
- **P80-D-56 (P80-Q-05, ex-S80-5, AUDC-F3 en partie — amende P78-D-34).** Réponse : « 36 visibles, 44 d'appui (Recommandé) » — « Le
  bouton est dessiné à 36 px comme ses voisins, mais sa zone d'appui reste de 44 px : la cible tactile que vous aviez
  ratifiée est tenue, et l'en-tête retrouve une seule taille. » Option (b). Le seuil et la présence de l'icône de
  P78-D-34 (701 à 1 279 px) tiennent ; seul le dessin passe à 36 px, la zone d'appui restant de 44 px.

Le plan « après avis de Samuel » est redécoupé en plans exécutables (P80-D-49 accomplie). Signalé sans réouverture :
AUDC-M11 est tranché hors de cette phase (lot de correctifs à part) ; la source exacte de la borne « un tiroir latéral ne
pousse jamais la carte » est PU-G-204, pas Q12.

<canonical_refs>
## Canonical References

- `.planning/research/2026-11-10-audit-cockpit-etude.md` § 1, § 3, § 8.2, § 9
- `.planning/research/2026-11-10-audit-cockpit/REGISTRE.md` (lignes de la phase, § 3, § 4, § 5)
- `.planning/research/2026-11-10-audit-cockpit/DESIGNS.md` § 1, § 6, § 7, § 8, § 9
- `.planning/research/2026-11-10-audit-cockpit/A4-interface-parcours.md`
- `.planning/missions/2026-11-11-audit-cockpit-lot-0.md` (« Décisions », « Limites », « Fichiers par sous-lot »)
- `79-CONTEXT.md` § « Contrats fournis », branche `feat/phase-79-socle-cockpit`, commit `3119d82a`, et son
  « Amendement du 2026-11-11 » (A1 à A7, A10, A11), commit `2ae6607a`, second amendement (A15 à A28), commit `6f66d878`, A30 (`surOnglet`), commit `74501bb0`, et A31/A32, commit `e04c43e7`
- `DESIGN.md` (direction « Graphite »)
- `plugin/cockpit/CHANGELOG.md` § Non publié (Q4 à Q14 du 2026-11-06, PU-G-001, PU-G-026, PU-G-204)
- Registres d'arbitrage : `70-CONTEXT.md` (P70-D-04, P70-D-22), `71-CONTEXT.md` (P71-D-02, P71-D-27, P71-D-35),
  `71.5-CONTEXT.md` (P71.5-D-01), `78-CONTEXT.md` (P78-D-04, P78-D-34), `67-CONTEXT.md` (P67-D-14, P67-D-20),
  `69-CONTEXT.md` (P69-D-16, P69-D-19)
- `80-UI-SPEC.md` (couloirs, liste) et `80-UI-SPEC-NAVIGATION.md` (clavier, surcouches, minicarte, ligne d'état, palette,
  tiroir Git, jetons), produits au cadrage
</canonical_refs>
</content>
