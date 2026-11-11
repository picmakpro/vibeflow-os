# Phase 76: Traçabilité au cockpit — exigences, décisions, mémoire - Context

**Gathered:** 2026-11-11
**Status:** Cadrée (2026-11-11) — frontière de questions vide ; deux confirmations non bloquantes « À Samuel »

Cadrage porté par le manager de la mission Phase 76 (`vf-dev-manager`, worktree `.claude/worktrees/phase-76`, branche
`feat/phase-76-tracabilite`, base `integration/cockpit-audit` `f763b556`). Jalon `vibeflow-v2.0`, compartiment
`fiabilite`. Cadrée en parallèle des Phases 73, 74, 75, 77, 79 et 80 (vague de cadrage demandée par Samuel, session
principale Claude Code, 2026-11-11). Sources : bloc Phase 76 du ROADMAP ; idées 10, 11 et 14 de
`.planning/notes/2026-11-03-cockpit-idees-recherche.md` ; audit du 2026-11-10 (étude § 8.2, `REGISTRE.md`
AUDC-I33, `DESIGNS.md` § 1, § 7, § 9) ; rapport du lot 0 (`.planning/missions/2026-11-11-audit-cockpit-lot-0.md`) ;
contrats figés de la Phase 79 (`79-CONTEXT.md` § Contrats fournis, commit `3119d82a` de la branche
`feat/phase-79-socle-cockpit`, lus sans fusion).

**Exigences :** TRAC-01 à TRAC-12. Préfixe neuf, vérifié libre le 2026-11-11 dans tous les ledgers
(`.planning/workstreams/*/REQUIREMENTS.md`, `.planning/milestones/*REQUIREMENTS*.md`) et dans tout le dépôt (aucun
`TRAC-<n>` ; `TRACE-…` est un identifiant de preuve de la Phase 41, sans rapport).

<domain>
## Phase Boundary

L'onglet Projet du cockpit montre, en lecture seule, trois chaînes que le lab écrit déjà mais que personne ne relie :

1. **Exigences** : pour chaque exigence d'une phase, son plan, son SUMMARY, sa VERIFICATION et sa recette, chaque maillon
   lu dans un champ ou une citation, les trous visibles ; au niveau du jalon, une ligne par phase avec ses trous.
2. **Décisions** : les ADR de `docs/ADR.md`, les décisions définies dans les registres de phase (`*-CONTEXT.md`), et les
   commits qui les citent ; on va de l'une à l'autre par liens.
3. **Mémoire des agents** : les entrées versionnées de `.claude/agent-memory/`, leurs liens `[[…]]`, les liens cassés,
   les entrées hors index, sans lien entrant, ou qui citent un chemin du dépôt disparu.

S'y ajoute AUDC-I33 : les preuves de vérification déjà écrites (VERIFICATION, recette, traces rouges, critères des
plans) attachées à la phase et à ses plans, en liens vers leurs fichiers.

**Hors périmètre :** toute écriture (le cockpit ne coche, ne corrige ni ne crée rien) ; un graphe dessiné sur canevas ;
un quatrième onglet ; les registres hors phase (`PU-G-…`, `AUDC-…`, `DEC-…` de `.claude/memory/DECISIONS.md` des labs
non-dev) ; le contenu des mémoires (corps, description) ; la mémoire hors dépôt ; toute lecture réseau ; la file des
arbitrages en attente (Phase 73) ; les jauges de santé de la méthode (Phase 77) ; la forme en couloirs de Projet
(Phase 80).
</domain>

<decisions>
## Implementation Decisions

Toutes les décisions ci-dessous : **décision déléguée par Samuel (message session principale, 2026-11-08), option
recommandée**, sauf mention. Chacune a été contrôlée contre `DESIGNS.md` § 9 et les registres d'origine. Faits établis
par trois éclaireurs en lecture seule et trois panels (`gsd-advisor-researcher`) le 2026-11-11 ; chiffres mesurés sur ce
dépôt.

### Arbitrages en vigueur qui bornent la phase (rappel, non rouverts)

- Pas de quatrième onglet (P78-D-04). Trois onglets, trois formes ; le canevas reste à Code (`DESIGNS.md` § 1, direction
  retenue par Samuel le 2026-11-11).
- Ni couleur d'alerte ni fond teinté : glyphe et mot ; les teintes Graphite (vert, jaune, corail) ne sont portées que par
  un glyphe ou un trait (Q9, P71.5-D-12, D-19, D-21, D-27, D-28). Grille d'espacements fermée (P71.5-D-01). Points de
  rupture inchangés (Q11). Un tiroir latéral ne pousse jamais la carte (Q12 ; P71-D-35 pour le terminal).
- Lien jamais deviné (P69-D-15) ; aucun pourcentage pondéré ni étape cochée à la main (P69-D-01) ; statut jamais tiré du
  STATE (P69-D-08).
- Aucune lecture réseau (P67-D-02, P78-D-05) ; lecture seule sur `.planning/` ; sortie sous `.vibeflow/cockpit/`
  (P67-D-06).
- Transcript sans sortie d'outil, jamais exporté (P69-D-19) ; verbe et cible réduite, jamais un argument (P69-D-16) ;
  dernière commande jamais dans le flux, un fichier ou l'export (P67-D-14).
- Titre jamais généré (PU-G-162) : aucun résumé rédigé par un modèle d'une ADR, d'une décision ou d'une mémoire.
- Rien sans l'option `--terminal` (P71-D-02) ; le double geste reste dû (la phase n'ajoute aucune action).

### Forme et emplacement

- **P76-D-01 (forme : voisinage en panneaux reliés, pas de canevas).** « Graphe navigable » et « graphe de liens » se
  réalisent par des panneaux reliés : chaque objet (phase, exigence, ADR, décision, commit, entrée de mémoire) a un
  panneau qui liste ses voisins lus, et chaque voisin s'ouvre d'un geste. Aucun dessin de nœuds et d'arêtes. Motifs :
  volumes mesurés (≈ 1 900 arêtes commit → décision, voisinages de plus de 30 commits, 268 entrées de mémoire), piège
  « graphes illisibles au-delà de quelques dizaines de nœuds » (étude § 6), canevas hors clavier (AUDC-BL2). Panel
  « forme » : option D retenue (sections de panneau + agrégats + navigation de proche en proche avec historique) ;
  canevas (C) écarté, sous-vue plein cadre (B) écartée pour collision certaine avec la bascule de vue que refait la 80.
- **P76-D-02 (emplacement).** Par l'API de page existante seulement : `SC.addPanelSection('item', …)` pour la section
  « Traçabilité » du panneau d'une phase ; `SC.addPanelSection('overview', …)` pour trois sections repliées de la vue
  d'ensemble de Projet (« Jalon », « Décisions », « Mémoire des agents ») ; `SC.showPanel(html, bind)` pour le panneau
  d'une exigence, d'une ADR, d'une décision ou d'une entrée de mémoire. Jamais `setOverview` (il remplace). Aucune
  modification de `viewer.html` dans la phase ; nouveaux fichiers de page `ui/7x-vf-trace*.js` (numéro libre sous 78,
  fixé au plan).
- **P76-D-03 (navigation).** Ouverture d'un objet par `select(id)` (panneau sans changer de vue) et `reveal(id)` de la
  page, déjà exportés ; Retour par la pile de sélections commune que la Phase 80 pose sur Projet
  (`window.VF_PANNEAU.retour()` et bouton « Retour » de l'en-tête du panneau, P80-C76-3) : la 76 y empile en appelant
  `select`, sans pile propre ; fil d'Ariane et ancre par objet ; un commit s'ouvre dans le tiroir Git existant
  (Phase 78, détail sans diff) ; une phase s'ouvre dans son panneau Projet (identifiant stable `ph-<N>` ou
  `ph-<N>@<ws>`). Clavier : tout lien est un élément focalisable natif, Échap ferme, ordre de tabulation dans le
  panneau. Amendé le 2026-11-11 sur la réponse de la Phase 80 (pile locale abandonnée ; nom corrigé par la 80 le même jour : l'objet global du moteur est gelé, P80-D-33 à P80-D-41). Une surcouche éventuelle passe par la pile commune `window.VF_SURCOUCHES` de la 80 (`ouvrir`, `dessus`, `ouverte`).
- **P76-D-04 (trous : glyphe et mot).** Une ligne d'exigence porte une bande de quatre glyphes (plan, SUMMARY,
  VERIFICATION, recette) et un seul mot pour le premier trou (« manque : VERIFICATION »). Absence simple : glyphe
  neutre et mot neutre (même registre que « N exigences non cochées », PU-G-097). Contradiction lue (case cochée au
  ledger sans SUMMARY, statut de traçabilité « Complete » sans plan, lien `[[…]]` cassé, mémoire hors index) : glyphe
  à trait corail et mot. Jamais de fond teinté, jamais de texte coloré. Le mot « rouge » du but est lu comme « marqué
  et visible » dans les teintes Graphite : confirmation demandée à Samuel (A-1), non bloquante.
- **P76-D-05 (échelle).** Les listes longues s'agrègent d'abord (une ligne par phase du jalon, une par ADR puis un
  repli par registre de phase, une par agent pour la mémoire) ; dans un panneau, au plus 30 voisins d'une même sorte,
  puis « + N autres » qui ouvre la liste complète paginée.

### Données : chemin, schéma, sécurité

- **P76-D-06 (route à la demande).** Les données arrivent par une route propre, `GET /api/vf/tracabilite`, appelée à
  l'ouverture d'une section ou d'un panneau, calcul asynchrone, cache par empreinte (sha de HEAD + dates de
  modification de `docs/ADR.md`, des `*-CONTEXT.md`, du ledger et de `.claude/agent-memory/`), un seul calcul en vol,
  une seule entrée en cache. `vibeflow/cockpit-project@1` n'est **pas** étendu ; `project.html` ne grossit pas. Panel
  « données » : option B retenue (A écartée : poids de page, collecte synchrone, conflit avec la 79 sur la boucle ;
  C écartée : deux sources pour le même compte). Paramètres `vue=jalon|phase|exigence|decision|adr|memoire|entree` et
  `cle=` validée par motif strict ; paramètre invalide : 400.
- **P76-D-07 (schéma).** `vibeflow/cockpit-trace@1` déclaré dans `plugin/cockpit/scripts/vf-cockpit-interface.json`
  avec ses `requis`, `optionnels`, `etats` et `interdits` (les cinq clés de C0 plus `description`, `corps`, `texte`),
  ligne au README § Interface et à la table des routes ; tout champ de réponse déclaré (motif de
  `test-cockpit-who.sh`). Champ `bornes.tronque` : une réponse bornée ne se présente jamais comme complète.
- **P76-D-08 (règles C0 de la Phase 79).** La route suit C0 tel que figé : hôte exact, `Origin`, jeton en en-tête
  `x-vf-cockpit-token` en temps constant, GET seul (405 sinon), JSON `Cache-Control: no-store`, garde `porteInterdit`
  appliquée à la réponse, 503 `{ "erreur": "emission-refusee" }` si elle se déclenche ou si le contrat est illisible.
- **P76-D-09 (lecture confinée).** Toute lecture du lab passe par le point de passage unique d'AUDC-A-02 (aujourd'hui
  `lireConfine`/`read`/`lister` de `vf-cockpit-planning.mjs` ; son successeur si la Phase 79 le renomme en fermant la
  classe restante d'A-02). La route s'enveloppe elle-même dans le confinement. Git par le seul point durci
  (`lancerGitAsync` de `vf-cockpit-paths.mjs`), jamais `--all`, référence résolue en sha, `--end-of-options` et `--`.
- **P76-D-10 (commits citants).** Un passage `git log <sha de HEAD> -E --grep=<ADR et décisions préfixées>
  --max-count=2000` ; le corps du message sert seulement à extraire les identifiants et n'est jamais servi (on sert
  sha court, date au jour, sujet). Coût mesuré : 0,08 s pour 3 619 commits, 1 014 citants. Pas de fenêtre en jours :
  une décision ancienne garde ses commits. Borne atteinte, délai dépassé ou sortie tronquée : `bornes.tronque: true`.
- **P76-D-11 (rien dans l'export ni hors du lab).** L'export n'emporte aucune donnée de la phase (il n'emporte
  aujourd'hui que l'onglet Code ; la Phase 79 garde une page autonome : la vue de traçabilité n'y entre pas, témoin
  dédié). Aucun chemin absolu ni `~/` dans une réponse : un chemin servi est relatif au lab ; tout texte venu des
  fichiers est rendu en `textContent`.
- **P76-D-12 (dégradation).** Lab sans `docs/ADR.md`, sans compartiment, sans `.claude/agent-memory/`, sans git, ou
  dont le ledger range sa traçabilité en « Étape N » (gabarit `planning-core`) : la section dit l'absence en une ligne
  neutre, rien ne casse ailleurs (témoin par cas). Le motif « Étape N » est lu comme « Phase N » s'il désigne un
  dossier de phase existant ; sinon la section le dit.

### Exigences → plan → SUMMARY → VERIFICATION → recette

- **P76-D-13 (rattachement).** Une exigence appartient à une phase par la table `## Traceability` du ledger (motif
  existant `reTraceabilite`) ou, à défaut, par le `requirements:` d'un PLAN du dossier de phase. Mesuré sur les
  Phases 67 à 78 : 93 exigences, 92 rattachées par champ.
- **P76-D-14 (maillons lus).** Plan : `requirements:` du frontmatter du PLAN. SUMMARY : `requirements:` ou
  `requirements-completed:` du SUMMARY apparié à ce plan (deux noms observés, les deux lus ; SUMMARY sans frontmatter :
  « non lisible », pas « manque »). VERIFICATION : fichier `*-VERIFICATION.md` de la phase, `status:` du frontmatter,
  et l'identifiant cité dans sa table de couverture (« niveau exigence ») ; sinon le fichier seul (« niveau phase »).
  Recette : fichier de recette de la phase (`*-RECETTE-*.md`), état lu sur la ligne `**Statut :` (règle déjà codée par
  `reste()` de `vf-cockpit-avancement.mjs`, réutilisée, jamais réécrite) ; identifiant cité dans le fichier = niveau
  exigence. `*-VALIDATION.md` (Nyquist) n'est pas une recette. Chaque maillon dit son niveau (exigence ou phase).
- **P76-D-15 (contradictions du ledger).** Sont montrées, jamais corrigées : case cochée sans SUMMARY lu, case non
  cochée avec SUMMARY lu, ligne de traçabilité sans exigence, exigence sans ligne de traçabilité. Mesuré : 24 cas
  case/statut et 50 exigences sans ligne dans le ledger `fiabilite`.

### Décisions

- **P76-D-15bis (où vit le corail, amendé le 2026-11-11 sur la critique de l'UI-SPEC).** Le trait corail est réservé
  aux contradictions de la liste fermée de P76-D-04 (case cochée sans SUMMARY lu, statut « Complete » sans plan lu, lien
  `[[…]]` cassé, mémoire hors index, chemin cité absent). « Exigence sans ligne de traçabilité » (rattachée par un PLAN)
  et « ligne de traçabilité sans exigence » sont dites en mot neutre, sans corail : mesuré, la première touche 50
  exigences du ledger `fiabilite`, ce qui ferait du corail la norme. « Ligne sans exigence » vit dans la vue d'ensemble
  « Jalon » (pas de ligne d'exigence où la poser) ; « exigence sans ligne » est une mention de la ligne d'exigence,
  hors des quatre maillons. Un mot de ligne ne masque jamais le premier trou de la bande.

- **P76-D-16 (corpus).** ADR : sections `## ADR-NNN` de `docs/ADR.md` (32 ici ; une ADR citée sans section reste un
  identifiant cité, sans panneau) ; décisions : lignes de définition des registres `*-CONTEXT.md` des dossiers de phase
  (`- **Pnn-D-nn` et formes voisines mesurées). Une décision nue (`D-nn`) d'un registre est qualifiée par la phase de son
  registre pour l'affichage (« D-04, Phase 41 ») mais aucun commit ne lui est relié par une citation nue (ambiguë sans
  phase, ADR-075). Hors corpus, différé : `PU-G-…`, `AUDC-…`, `DEC-…`.
- **P76-D-17 (arêtes).** Décision → commits qui la citent (P76-D-10) ; ADR → décisions et commits qui la citent ;
  décision → ADR qu'elle cite dans sa ligne de définition ; décision → sa phase. Toutes lues dans un texte, jamais
  inférées.
- **P76-D-18 (extracteur partagé avec la Phase 73).** La 73 lit les mêmes registres pour sa file des arbitrages en
  attente (idée 9). Un seul extracteur de définitions, fonction pure dans un module dédié (nom proposé :
  `plugin/cockpit/scripts/vf-cockpit-registres.mjs`) : si la 73, exécutée avant, l'a livré, la 76 l'importe et
  l'étend par ajout ; sinon la 76 le crée sous ce nom. Écrit dans « À verser par la jointure » du rapport.

### Mémoire des agents

- **P76-D-19 (périmètre).** Seuls les fichiers suivis par git sous `.claude/agent-memory/` (`git ls-files`), lus par le
  point confiné. Jamais `.claude/agent-memory-local/`, jamais la mémoire hors dépôt. `.claude/` ignoré par git : état
  vide qui le dit, avec le nombre de fichiers non suivis, sans leurs noms.
- **P76-D-20 (champs montrés).** `name`, agent (le dossier), `metadata.type`, date du dernier commit (jour seul), nombre
  de liens entrants et sortants, et les chemins absents (relatifs au dépôt seulement). Jamais `description`, jamais le
  corps, jamais un chemin `~/` ou absolu. Panel « mémoire » : rien de masqué par liste de cas (une liste de cas ne ferme
  pas une classe) ; seule la structure entre dans la page.
- **P76-D-21 (liens).** Extraction après retrait des blocs de code et des passages entre accents graves, et de toute
  classe POSIX `[[:…:]]` (7 faux positifs mesurés). Résolution par `name:` d'abord, puis par nom de fichier, ce second
  cas étant un état propre (« résolu par nom de fichier », compté) ; le reste est « cassé ». Mesuré : 399 liens, 33
  cassés réels sur 22 cibles, 61 résolus seulement par nom de fichier.
- **P76-D-22 (pas de « périmée » devinée).** Trois états mesurables, distincts : « hors index » (absente de son
  `MEMORY.md`, correspondance exacte du nom de fichier) — contradiction ; « sans lien entrant » (les liens d'index ne
  comptent pas) — filtre neutre, 143 sur 268 ; « cite un chemin absent » (chemin relatif au dépôt, absent de HEAD et
  présent dans l'historique git lu, borne du P76-D-10) — contradiction. La date est une information, jamais un verdict.
- **P76-D-23 (doublon avec `check-method-budget.sh`).** Règle réimplémentée en fonction pure côté cockpit (le module ne
  dépend d'aucun autre), sans lire la sortie du script. Le script juge « hors index » par sous-chaîne (`grep -qF`) ; la
  76 juge par égalité exacte et le constat part au BACKLOG par la jointure. La Phase 77 lit les compteurs de la route
  si elle veut une jauge, sans recalcul.

### Preuves de vérification (AUDC-I33)

- **P76-D-24 (preuves attachées).** Sous la ligne dépliée d'une phase ou d'un plan : les fichiers de preuve existants
  de la phase (`*-VERIFICATION.md` et son `status:`, recette et son statut, `*-RED-TRACE.md` du plan, `*-SECURITY.md`,
  `*-VALIDATION.md` Nyquist), en liens vers leurs chemins relatifs, et les critères `must_haves` du frontmatter du PLAN
  quand ils existent (comptés et listés en texte). Jamais un contenu de transcript, jamais une capture hors dépôt,
  jamais une preuve déduite.

### Retrait, design, preuves, ordre

- **P76-D-25 (un ajout, un retrait).** Retrait : le nœud enfant « Exigences » de chaque phase du graphe Projet et ses
  cartes d'exigence (`vf-cockpit-project.mjs`, nœud `<id>.req` et ses cartes), que la section « Traçabilité » rend
  redondants. Les liens « couvre » plan → exigence quittent le canevas avec eux. Le compte « x/y exigences » du pied
  (`piedExigences`) reste, la Phase 80 le réutilise sur ses cartes. Recoupement avec AUDC-I25 (Phase 80, bascule liste
  où « les exigences se lisent comme une liste à cocher ») : écrit dans « À verser par la jointure ».
- **P76-D-26 (étage design).** UI neuve (sections et panneaux) : contrat `76-UI-SPEC.md` avant les plans, critiqué par
  `vf-design-judge` contre `DESIGN.md` (seuil 70/100) ; à l'exécution, `craft` par `vf-crafter` avant le code d'UI et
  `critique` en parallèle de la revue.
- **P76-D-27 (preuves).** Chaque exigence porte un témoin qui rougit sur le code actuel et verdit après ; mutants sur
  les gardes (confinement, `porteInterdit`, motif de `cle`, borne `tronque`, exclusion des champs de mémoire, export) ;
  lab jetable fabriqué dans la suite (ledger, dossiers de phase, ADR, registres, commits citants, mémoire avec liens
  cassés et hors index). Rendu par une suite Chrome sans tête à port éphémère, à l'exécution seulement. Les sondes de
  `sondes/` mesurent, elles ne prouvent pas.
- **P76-D-28 (ordre et revalidation).** Les plans s'exécutent après la première vague de la Phase 79 (AUDC-V5 : 79,
  puis 73, 74, 75, 76) : aucun diff amont régénéré (`plugin/cockpit/amont/` retiré par la 79, C6), suites lancées par
  l'aide commune de la 79. Avant exécution, les plans repassent devant un vérificateur frais contre la base qui porte la
  79 et la 80 (fichiers partagés : `vf-cockpit-server.mjs`, `vf-cockpit-project.mjs`, `vf-cockpit-planning.mjs`,
  `vf-cockpit-interface.json`, `ui/`).
- **P76-D-29 (version).** Ligne au `CHANGELOG.md` du module § Non publié ; aucun bump ni release dans la phase.

### Contrats entre phases

- **Reçus de la Phase 79** (amendement du 2026-11-11, commit `2ae6607a` de `feat/phase-79-socle-cockpit`,
  `79-CONTEXT.md` § Amendement, A10 à A13, lu sans fusion) : A10, table des routes GET en ordre alphabétique livrée par
  le plan 79-05 en première vague, la route de la 76 s'y ajoute par **une ligne à sa place alphabétique** (voisines :
  `/api/vf/activite` de la 75, `/api/vf/methode` de la 77) ; A11, une fonction exportée unique porte les contrôles C0,
  `porteInterdit`, `no-store` et le 503 : la 76 l'**appelle**, ne la recopie pas ; A12, la lecture confinée reste l'API
  unique et couvre toute la racine réelle, dossiers cachés compris ; A13, côté page, `VF_ETAT.jeton()` et
  `VF_ETAT.lireJson(chemin)` sont les seuls lecteurs du jeton, `structural` reste émis et la clé `planning`
  `{seq, at}` de `VF_ETAT` signale un changement de `.planning/` : la 76 relance l'appel ouvert sur cette clé.
  Plans bâtis sur ces contrats ; tant que la 79 n'est pas exécutée, le chemin réel des fonctions est **à revalider**.
- **Reçus de la Phase 80** (commit `f10ba2c7` de `feat/phase-80-trois-formes`, `80-CONTEXT.md` § Contrats fournis à
  la Phase 76, lu sans fusion) : P80-C76-1, `addPanelSection('item'|'overview', fn)` garde sa signature et son rappel
  `fn(cible)` à chaque rendu, une carte de couloir ou une ligne de liste ouvre le même panneau par `select(id)`,
  identifiant de phase `ph-<N>` ou `ph-<N>@<ws>` ; P80-C76-2, `setOverview` ne remplace que le corps, les sections
  `addPanelSection('overview')` restent posées après lui ; P80-C76-3, pas de `SC.openNode` : `select(id)` et
  `reveal(id)`, Retour par la pile commune `window.VF_PANNEAU.retour()` ; P80-C76-4, « x/y exigences » reste
  `piedExigences`, et le champ facultatif `exigences {faits,total}` que la 80 ajoute au nœud de phase sort du même
  calcul, la 76 ne le recalcule pas. **Séquence** : le lot moteur et les onglets sans rechargement de la 80 passent
  après la fusion de la 79 entière ; les plans de la 76 qui se branchent sur le panneau dépendent donc de la **80
  exécutée**, pas seulement de la première vague de la 79 (dépendance déclarée dans les plans, **à revalider** à
  l'exécution).
- **Partagé avec la Phase 73** : l'extracteur de définitions des registres (P76-D-18).
- **Fourni à la Phase 77** : les compteurs de la mémoire par la route (P76-D-23).

### Claude's Discretion

Découpage exact en fichiers sous `plugin/cockpit/scripts/` (chaque fichier ≤ 300 lignes, gate V4), numéro des fichiers
`ui/`, format interne du cache, libellés exacts dans le cadre de l'UI-SPEC.
</decisions>

## À Samuel

Questions qui ne bloquent rien : l'arbitrage en vigueur tient et les plans sont bâtis dessus.

- **A-1 — « Les trous en rouge » (but du 2026-11-03) face à Q9 (2026-11-06, ni couleur d'alerte).** En vigueur : Q9.
  Options : (a) glyphe neutre et mot pour une absence, trait corail sur le glyphe pour une contradiction lue
  (P76-D-04) ; (b) trait corail pour tout trou ; (c) tout neutre. Recommandation : (a), seule lecture qui tient les
  deux textes ; elle garde le corail pour ce qui demande une action.
- **A-2 — « Graphe navigable » et « graphe de liens » (but du 2026-11-03) réalisés sans dessin.** En vigueur : la
  direction « trois onglets, trois formes » retenue le 2026-11-11. Options : (a) panneaux reliés, voisinage seul
  (P76-D-01) ; (b) en plus, un dessin de l'îlot de mémoire d'un agent (moins de 30 nœuds) ; (c) un canevas des
  décisions. Recommandation : (a) ; (b) peut venir plus tard sans rien défaire.

<canonical_refs>
## Canonical References

- `.planning/workstreams/fiabilite/ROADMAP.md` § Phase 76 (but du 2026-11-03)
- `.planning/notes/2026-11-03-cockpit-idees-recherche.md` (idées 10, 11, 14 ; complément du 2026-11-11)
- `.planning/research/2026-11-10-audit-cockpit-etude.md` § 6, § 8.2 ; `.planning/research/2026-11-10-audit-cockpit/REGISTRE.md` (AUDC-I33, § 3) ;
  `DESIGNS.md` § 1, § 2 (vocabulaire des états), § 7, § 9
- `.planning/missions/2026-11-11-audit-cockpit-lot-0.md` (Décisions, Limites, Fichiers par sous-lot)
- `79-CONTEXT.md` § Contrats fournis (C0, C5, C6), branche `feat/phase-79-socle-cockpit`, commit `3119d82a`
- `DESIGN.md` (direction « Graphite »)
- `docs/ADR.md` § ADR-075 (préfixage des identifiants de décision)
- `plugin/cockpit/scripts/vf-cockpit-planning.mjs` (`lireConfine`, `read`, `lister`, `readPlanning`),
  `vf-cockpit-project.mjs` (`buildProjectGraph`, `piedExigences`, nœud `<id>.req`), `vf-cockpit-avancement.mjs`
  (`reste`, `decompte`), `vf-cockpit-formats.mjs` (`reExigences`, `reTraceabilite`), `vf-cockpit-paths.mjs`
  (`lancerGitAsync`), `vf-cockpit-server.mjs` (`porteInterdit`), `vf-cockpit-interface.json`
- `plugin/cockpit/skills/cockpit-moteur/assets/viewer.html` (API `SC` : `addPanelSection`, `showPanel`) et `ui/00-vibeflow.js`
- `plugin/conductor/scripts/check-method-budget.sh` (`rangement_memoires`)
</canonical_refs>

<deferred>
## Deferred Ideas

- Registres hors phase (`PU-G-…`, `AUDC-…`, `DEC-…` des labs non-dev) dans le corpus des décisions.
- Un dessin de l'îlot de mémoire d'un agent (A-2 b).
- Une vue plein cadre de la traçabilité du jalon, si la Phase 80 ouvre un emplacement de vue enregistrable.
- Une écriture quelconque (cocher une exigence, réparer un lien) : contraire à la lecture seule.
</deferred>
