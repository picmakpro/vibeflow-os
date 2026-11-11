# Phase 76: Traçabilité au cockpit — exigences, décisions, mémoire - Context

**Gathered:** 2026-11-11
**Status:** Cadrée (2026-11-11), reprise le même jour : A-1 et A-2 tranchées par Samuel, format des questions en attente posé (P76-D-34 à P76-D-37) ; une question appliquée par délégation, contestable (P76-Q-03)

Cadrage porté par le manager de la mission Phase 76 (`vf-dev-manager`, worktree `.claude/worktrees/phase-76`, branche
`feat/phase-76-tracabilite`, base `integration/cockpit-audit` `f763b556`). Jalon `vibeflow-v2.0`, compartiment
`fiabilite`. Cadrée en parallèle des Phases 73, 74, 75, 77, 79 et 80 (vague de cadrage demandée par Samuel, session
principale Claude Code, 2026-11-11). Sources : bloc Phase 76 du ROADMAP ; idées 10, 11 et 14 de
`.planning/notes/2026-11-03-cockpit-idees-recherche.md` ; audit du 2026-11-10 (étude § 8.2, `REGISTRE.md`
AUDC-I33, `DESIGNS.md` § 1, § 7, § 9) ; rapport du lot 0 (`.planning/missions/2026-11-11-audit-cockpit-lot-0.md`) ;
contrats figés de la Phase 79 (`79-CONTEXT.md` § Contrats fournis, commit `3119d82a` de la branche
`feat/phase-79-socle-cockpit`, lus sans fusion).

**Exigences :** TRAC-01 à TRAC-13 (TRAC-13 ajoutée à la reprise : questions en attente). Préfixe neuf, vérifié libre le 2026-11-11 dans tous les ledgers
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

### Arbitrages de Samuel rendus à la reprise (2026-11-11)

Relayés mot pour mot par la session principale ; canal : arbitrage Samuel, AskUserQuestion session principale,
2026-11-11.

- **P76-D-32 (A-1, les trous ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-11).** Option retenue :
  « Marque neutre (Recommandé) » — « Une absence se dit par un glyphe et un mot, sans couleur. Seule une contradiction
  réellement lue (deux sources qui se contredisent) prend un octogone au trait corail. C'est ce que les plans prévoient
  déjà. » Confirme P76-D-04 et P76-D-15bis ; P76-Q-01 passe de « en attente » à « tranchée ».
- **P76-D-33 (A-2, graphe navigable ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-11).** Option
  retenue : « Panneaux reliés (Recommandé) » — « Dans l'onglet Projet, un clic sur un objet ouvre l'objet voisin
  (l'exigence ouvre son plan, sa décision, sa preuve), avec un seul bouton Retour. Ni canevas ni quatrième onglet. »
  Confirme P76-D-01 et P76-D-30 ; P76-Q-02 passe à « tranchée ».
- **P76-D-34 (questions en attente : poser le format maintenant ; arbitrage Samuel, AskUserQuestion session
  principale, 2026-11-11).** Option retenue : « Poser le format maintenant (Recommandé) », présentée mot pour mot :
  « Un format court pour une question en attente (identifiant, question, options, recommandation, ce qu'elle bloque),
  que les sept cadrages suivent déjà presque. La Phase 76 le lit, la régie de la 73 l'affiche dans « À vous ». Coût :
  un plan de plus dans la 76 et un dans la 73. Le manager de la 73 recommandait, lui, de reporter. » Née de la question
  S-3 de la Phase 73. Répartition fixée par la session principale : la 76 est propriétaire du format et de sa lecture
  (C76-Q1, C76-Q2, plan 76-09, TRAC-13) ; la 73 est propriétaire de l'affichage.
- **P76-D-35 (forme du format ; décision déléguée par Samuel (message session principale, 2026-11-08), option
  recommandée).** Le format reprend la forme que les sept sections « À Samuel » suivent déjà presque (puce, identifiant
  en gras, titre, options lettrées, recommandation) et la rend lisible par machine : identifiant préfixé selon la
  convention du dépôt (`P<n>-Q-<nn>`), champs sur des lignes étiquetées d'un ensemble fermé, état toujours écrit.
  Écartés : un bloc YAML ou JSON (illisible pour l'humain qui répond, rompt avec la forme des sept cadrages) ; un
  fichier de questions à part (une question vit à côté des décisions qu'elle conditionne).
- **P76-D-36 (lecture fermée par défaut ; décision déléguée par Samuel (message session principale, 2026-11-08), option
  recommandée).** Une entrée qui ne respecte pas la grammaire n'est jamais rendue « en attente » : elle est « mal
  formée », avec son défaut nommé. Une question n'est « tranchée » que par une ligne `État` canonique. Une incohérence
  lue (ligne `État : en attente` alors qu'une décision du même registre cite son identifiant avec « arbitrage
  Samuel ») rend l'état « à vérifier », jamais « en attente ».

- **P76-D-37 (état « appliquée » ; décision déléguée par Samuel (message session principale, 2026-11-08), option
  recommandée ; amendement du 2026-11-11 sur demande de la session principale).** Une question dont l'option
  recommandée a été appliquée sous délégation n'est ni « en attente » ni « tranchée » : elle prend l'état
  « appliquée », écrit dans la même section et lu par la même lecture, pour que la régie la montre à part, contestable,
  sans la mêler aux questions qui bloquent. Écarté : la sortir de la section (Samuel perdrait le moyen de la contester) ;
  la laisser « en attente » (la file « À vous » perdrait son sens).

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
  `select`, sans pile propre ni fil d'Ariane (P76-D-30) ; ancre par objet ; un commit s'ouvre dans le tiroir Git existant
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
  l'ouverture d'une section ou d'un panneau, calcul asynchrone, cache par empreinte (signature git de l'instantané, `instantane().git.sig` de la règle A47 de la Phase 79, à la place
  d'un `rev-parse` à chaque requête — amendé le 2026-11-11 sur la vérification fraîche des plans — + `seq` de
  l'instantané de la collecte pour tout ce qui vient de `.planning/` + date
  de modification de `docs/ADR.md` et de `.claude/agent-memory/` et de ses sous-dossiers d'agent ; amendé deux fois le
  2026-11-11 : `76-RESEARCH.md` a montré que l'empreinte d'origine omettait PLAN, SUMMARY, VERIFICATION et recette, puis
  le vérificateur frais a montré qu'un parcours de `.planning/` à chaque requête contredit A31 ; la collecte surveille
  déjà `.planning/`, son `seq` suffit), un seul calcul en vol,
  une seule entrée en cache. Ce qui vient du planning se lit dans l'instantané de la collecte et ne se relit jamais dans la route (P76-D-31, règles A31 et A32 de la 79). Panel
  « données » : option B retenue (A écartée : poids de page, collecte synchrone, conflit avec la 79 sur la boucle ;
  C écartée : deux sources pour le même compte). Paramètres `vue=jalon|phase|exigence|decision|adr|memoire|entree` et
  `cle=` validée par motif strict ; paramètre invalide : 400.
- **P76-D-31 (deux régimes de lecture, par source ; amendé le 2026-11-11 sur les règles A31 et A32 de la Phase 79,
  commit `e04c43e7` de `feat/phase-79-socle-cockpit`).** La route lit la collecte en mémoire par
  `vf-cockpit-instantane.mjs` (`instantane()`, `surInstantane(rappel)`, livrés par le plan 79-09), jamais par HTTP,
  sans jamais déclencher de collecte ; avant la première collecte (`null`), elle répond `collecte: en-cours` sans
  données de planning.

  | Source | Régime | Borne |
  |---|---|---|
  | Phases, plans (`requirements:`, `depends_on`), ledger (exigences, cases, table de traçabilité), état d'avancement et de recette | instantané `projet` (`cockpit-project@1`, déjà collecté) | celle de la collecte |
  | Maillons manquants à l'instantané : champs d'exigences des SUMMARY, `status:` et identifiants cités des VERIFICATION, identifiants cités des recettes, liste des fichiers de preuve, `must_haves` des PLAN, définitions des registres `*-CONTEXT.md` (identifiant, phase, titre coupé à 80 caractères, ADR citées) | **ajoutés par la 76 dans la lecture du planning de la collecte**, en champs facultatifs de `cockpit-project@1` (la version ne monte pas, A32) | celle de la collecte ; poids ajouté à la page Projet mesuré et écrit au plan |
  | `docs/ADR.md` | lecture propre de la route, point confiné (A12) | fichier ≤ 8 Mio (`MAX_LECTURE`), mis en cache |
  | Commits citants | lecture propre, `lancerGitAsync` | P76-D-10 : `--max-count=2000`, tampon 8 Mio, échéance de 10 s, `tronque` |
  | Mémoire des agents (fichiers suivis, liens, jour du dernier commit, chemins ayant existé) | lecture propre, point confiné + `lancerGitAsync` | au plus 2 000 fichiers lus, chacun ≤ 8 Mio, un passage git borné comme P76-D-10 ; au-delà, `tronque` |

  Les lectures propres ne se font jamais à chaque requête : cache par empreinte (P76-D-06), un seul calcul en vol,
  une seule entrée. Conséquence : la 76 touche la lecture du planning de la collecte (fichiers partagés avec la 79 et
  la 80), ce qui est écrit dans la carte des fichiers du rapport. Décision déléguée par Samuel (message session
  principale, 2026-11-08), option recommandée ; elle remplace la phrase d'origine de P76-D-06 « `cockpit-project@1`
  n'est pas étendu ».

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
- **P76-D-38 (l'exigence ouvre son plan, sa décision, sa preuve ; mise en œuvre de P76-D-33, décision déléguée par
  Samuel (message session principale, 2026-11-08), option recommandée).** La réponse de Samuel à A-2 promet que
  « l'exigence ouvre son plan, sa décision, sa preuve ». Plan : déjà lu (`requirements:`). Décision : arête lue,
  exigence → décisions préfixées (`P<n>-D-<nn>`, ADR) **citées dans la ligne de l'exigence au ledger** (les lignes des
  familles du jalon les citent : « (P78-D-01, P78-D-09) ») ; une décision nue n'y est pas reliée (ADR-075) ; aucune
  citation : « aucune décision citée », mot neutre. Preuve : chaque maillon de preuve lu (VERIFICATION, recette, trace
  rouge du plan) s'ouvre dans le panneau des preuves de la phase, positionné sur lui, avec son chemin copiable ; le
  contenu du fichier n'est pas rendu. Amende P76-D-17 (arête ajoutée) et P76-D-24 (preuve ouvrable).
- **P76-D-18 (extracteur partagé avec la Phase 73).** La 73 lit les mêmes registres pour sa file des arbitrages en
  attente (idée 9). Un seul extracteur de définitions, fonction pure dans un module dédié (nom proposé :
  `plugin/cockpit/scripts/vf-cockpit-registres.mjs`) : si la 73, exécutée avant, l'a livré, la 76 l'importe et
  l'étend par ajout ; sinon la 76 le crée sous ce nom. Écrit dans « À verser par la jointure » du rapport.

### Mémoire des agents

- **P76-D-19 (périmètre).** Seuls les fichiers suivis par git sous `.claude/agent-memory/` (`git ls-files`), lus par le
  point confiné. Jamais `.claude/agent-memory-local/`, jamais la mémoire hors dépôt. `.claude/` ignoré par git : état
  vide qui le dit, avec le nombre de fichiers non suivis, sans leurs noms.
- **P76-D-20 (champs montrés).** `name`, agent (le dossier), `metadata.type`, date du dernier commit (jour seul), nombre
  de liens entrants et sortants, le chemin du fichier de mémoire lui-même (relatif au dépôt, nécessaire au verdict « hors index » ; ajouté le 2026-11-11 sur la critique de l'UI-SPEC), et les chemins absents (relatifs au dépôt seulement). Jamais `description`, jamais le
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
- **Règle de page de la Phase 79** (amendement A30, commit `74501bb0` de `feat/phase-79-socle-cockpit`, C5) : toute
  extension qui dépend de l'onglet s'initialise par `VF_COQUILLE.surOnglet(rappel)`, jamais au seul chargement ; les
  sections de panneau et la lecture de `GET /api/vf/tracabilite` de la 76 s'installent quand l'onglet vaut Projet et
  le rappel rend leur nettoyage (écouteurs, minuteries, DOM posé). **À revalider** après exécution de la 79.
- **P76-D-30 (objets qui ne sont pas des nœuds).** Phase et plan sont des nœuds du graphe : ouverts par `select(id)`,
  ils s'empilent d'eux-mêmes. Exigence (après le retrait de P76-D-25), ADR, décision, entrée de mémoire : panneaux sur
  mesure par `SC.showPanel(html, bind)`, précédés d'un appel à `window.VF_PANNEAU.empiler({ titre, rouvrir })`
  (P80-C76-5, commit `1325f65a` de `feat/phase-80-trois-formes`) ; `titre` est une donnée du lab, rendue en texte,
  jamais en HTML. Un seul Retour par panneau, celui de la 80 : **la 76 n'a pas de fil d'Ariane**. La pile est vidée au
  changement d'onglet, ce qui se combine avec l'initialisation par `surOnglet`. Décision déléguée par Samuel (message
  session principale, 2026-11-08), option recommandée ; amendée le 2026-11-11 sur la réponse de la 80.
- **Reçu de la Phase 80 pour le retrait (P80-C76-6, commit `2985be64` de `feat/phase-80-trois-formes`, lu sans
  fusion).** Tout code de la 80 qui lit le nœud `<ph>.req`, ses cartes ou les liens « couvre » passe par une seule
  porte, `lireExigences(phaseId)` de `assets/ui/41-vf-projet-phase.js` (exigences et couverture par plan) : liste à
  cocher (P80-D-05) et compte « N exigences couvertes » (80-07), panneau d'un plan « Exigences couvertes » (P80-D-08,
  80-11) ; `exigences {faits,total}` vient de `piedExigences` côté collecte ; le graphe d'une phase (P80-D-04) n'est lu
  par aucun code de la 80. Conséquences pour la 76 : 76-04 pose `meta.vf.trace.exigences` avec ce que la porte rend
  (exigences, cochée, couverture par plan) ; 76-08 rebranche `lireExigences` sur ce champ, prouve par le témoin « porte
  substituée » de la 80 que liste, compte par plan et panneau rendent la même chose avant et après le retrait, adapte
  toute suite de la 80 qui affirmerait des liens « couvre » dans le graphe d'une phase (nom attendu de la session
  principale) et la porte dans ses `files_modified` ; la garde d'exécution reste (aucun retrait si une lecture hors de
  la porte subsiste, la 77 lit aussi Projet). Le graphe d'une phase perd ses liens « couvre » : voulu par P76-D-25.
- **Partagé avec la Phase 73** : l'extracteur de définitions des registres (P76-D-18).
- **Fourni à la Phase 77** : les compteurs de la mémoire par la route (P76-D-23).

### Contrats fournis (questions en attente, P76-D-34)

Posés le 2026-11-11 pour la Phase 73, qui affiche la liste dans « À vous ». La 76 est propriétaire de C76-Q1 et C76-Q2 ;
tout changement passe par un amendement daté ici.

**C76-Q1 — Écrire une question en attente.**

- **Où.** Dans le registre `*-CONTEXT.md` d'un dossier de phase non archivé (`phases/<préfixe>-<N>-<slug>/` d'un
  compartiment, ou de `.planning/phases/` ; les archives `*-phases/` ne sont pas lues : une question d'un jalon clos
  n'attend plus rien — amendé le 2026-11-11 sur la vérification fraîche des plans), dans la section dont le titre de niveau 2 commence
  exactement par « À Samuel » (ligne `## À Samuel`, suffixe libre après). Une seule section par fichier ; toute autre
  section, et tout autre fichier, n'est jamais lu comme une question.
- **Une entrée** est une puce de premier niveau dont la première ligne commence exactement par
  `- **P<n>-Q-<nn> — <titre>.**`, suivie de la question sur la même ligne et sur ses lignes de suite non étiquetées :
  - `<n>` est le numéro de la phase du registre, décimale comprise (`P71.5-Q-01`), et doit être celui du dossier ;
  - `<nn>` a au moins deux chiffres ;
  - le séparateur entre identifiant et titre est ` — ` (tiret cadratin) ; le titre finit par un point avant `**`.
- **Champs** : chacun sur une ligne de suite indentée de deux espaces, une seule fois, étiquettes d'un ensemble fermé ;
  l'ordre ci-dessous est conseillé, non contrôlé (amendé le 2026-11-11 : aucun défaut ne le nomme, un ordre différent
  n'est pas une question mal formée) :
  - `Options : (a) … ; (b) … .` — au moins deux options, lettres consécutives à partir de `a` ;
  - `Recommandation : (<lettre>) — <motif>.` — lettre prise parmi les options ; ou `Recommandation : aucune — <motif>.`
    quand aucune n'est recommandable (goût pur) ;
  - `Bloque : <liste>` — éléments séparés par `, ` : un plan `<NN>-<NN>` (ou `<NN.N>-<NN>`), une phase `Phase <N>`, ou
    le seul mot `rien` ;
  - `État : en attente` ; ou, une fois tranchée par Samuel,
    `État : tranchée — arbitrage Samuel, <canal>, <AAAA-MM-JJ> — option (<lettre>) — « <mot pour mot> »` ; ou, quand
    l'option recommandée a été appliquée sous délégation sans que Samuel ait répondu à cette question,
    `État : appliquée — décision déléguée par Samuel (<canal>, <AAAA-MM-JJ>), option (<lettre>) — P<n>-D-<nn>`, la
    lettre étant celle de `Recommandation` et `P<n>-D-<nn>` la décision du même registre qui l'applique.
- **Trois états, trois sens.** « en attente » : une réponse de Samuel est attendue et retient ce que dit `Bloque`.
  « appliquée » : rien n'est bloqué, le travail avance sur l'option recommandée, mais Samuel ne l'a pas tranchée et peut
  la contester. « tranchée » : Samuel a répondu, sur cette question. Une question appliquée que Samuel conteste ou
  confirme passe à « tranchée » ; si sa réponse diffère de l'option appliquée, la décision `P<n>-D-<nn>` est amendée.
- **Changement d'état.** On ne supprime ni ne déplace l'entrée : on remplace la seule ligne `État` par la nouvelle
  forme ; pour « tranchée », la forme porte (canal, date ISO, option, citation exacte entre guillemets français), et on écrit au
  registre la décision qui en découle (`P<n>-D-<nn>`), qui cite l'identifiant de la question.
- **Ce qui n'est pas une question** : toute ligne de la section qui n'est pas une entrée (prose, puce d'un autre format
  comme `- **S-1 — …**`, puce imbriquée). La lecture ne la rend jamais comme une question ; elle compte les puces de
  premier niveau d'un autre format (« non structurées »).

**C76-Q2 — Ce que la lecture du planning rend à la page.**

- **Où.** Champ facultatif `meta.vf.questions` de `vibeflow/cockpit-project@1`, posé dans la lecture du planning de la
  collecte (règle A32 de la Phase 79) ; la version ne monte pas. Absent si aucun registre lu n'a de section « À Samuel ».
- **Forme.**

  ```json
  {
    "liste": [
      {
        "id": "P76-Q-03",
        "phase": "ph-76",
        "ws": "fiabilite",
        "fichier": ".planning/workstreams/fiabilite/phases/VFDO-76-tracabilite-au-cockpit/76-CONTEXT.md",
        "ligne": 312,
        "titre": "≤ 80 caractères",
        "question": "≤ 240 caractères",
        "options": [{ "cle": "a", "texte": "≤ 160 caractères" }],
        "recommandation": "a",
        "bloque": [{ "type": "plan", "id": "76-04" }, { "type": "phase", "n": "81" }],
        "etat": "en-attente",
        "tranchee": null,
        "appliquee": null,
        "defauts": []
      }
    ],
    "bilan": { "enAttente": 1, "appliquees": 0, "tranchees": 0, "aVerifier": 0, "malFormees": 0, "nonStructurees": 0, "registresLus": 1 },
    "tronque": false
  }
  ```

- **Valeurs.** `etat` ∈ `en-attente`, `appliquee`, `tranchee`, `a-verifier`, `mal-formee`. `recommandation` est une lettre ou `null`
  (« aucune »). `bloque` vaut `[]` pour `rien`. `tranchee` vaut `null` sauf si `etat` = `tranchee`, et porte alors
  `{ canal, date, option, citation }` (citation ≤ 240 caractères). `appliquee` vaut `null` sauf si `etat` =
  `appliquee`, et porte alors `{ canal, date, option, decision }` (`decision` = `P<n>-D-<nn>`). `defauts` est fermé : `etat-absent`,
  `etat-invalide`, `options-invalides`, `recommandation-hors-options`, `bloque-invalide`, `champ-repete`,
  `champ-manquant`, `phase-incoherente` (le `<n>` de l'identifiant n'est pas celui du dossier), `identifiant-double`
  (même identifiant deux fois dans le planning lu : toutes ses occurrences sont « mal formée »), `citation-incoherente`
  (état « à vérifier », P76-D-36), `appliquee-hors-recommandation` (l'option appliquée n'est pas la
  recommandée : « mal formée »), `decision-introuvable` (la décision citée par « appliquée » n'est pas définie dans le
  registre : état « à vérifier »). Une entrée « mal formée » garde `id`, `phase`, `fichier`, `ligne` et `defauts`
  quand ils sont lisibles, rien d'autre ; une entrée « à vérifier » garde tous ses champs lus, plus `defauts` (amendé le
  2026-11-11).
- **Bornes.** Textes passés par le nettoyage de la 76 (aucun chemin absolu ni `~/`) et coupés aux longueurs ci-dessus ;
  la page les rend en texte, jamais en HTML. Au plus 200 entrées, triées par phase puis identifiant ; au-delà,
  `tronque: true`. Fichier absent ou illisible : rien, sans erreur. Section vide : `registresLus` compté, aucune entrée.
- **Ce que la 73 consomme** : dans « À vous », les seules entrées `etat` = `en-attente` ; à part, repliée, une liste
  (libellé choisi par la 73 : « Décisions prises pour vous, contestables (N) ») des entrées `etat` = `appliquee` (question, option appliquée, décision
  qui l'applique), jamais mêlée à « À vous » et jamais cachée ; le `bilan` pour dire ce qui n'est pas lu (« N questions
  écrites dans un autre format, non lues ») et ce qui est à vérifier. Elle n'affiche jamais une entrée `mal-formee` ou
  `a-verifier` comme une question qui attend une réponse. Tant que la lecture de la 76 n'existe pas (la 73 s'exécute
  avant), le champ est absent et la 73 le dit dans son emplacement ; le plan 76-09 le remplit.

### Claude's Discretion

Découpage exact en fichiers sous `plugin/cockpit/scripts/` (chaque fichier ≤ 300 lignes, gate V4), numéro des fichiers
`ui/`, format interne du cache, libellés exacts dans le cadre de l'UI-SPEC.
</decisions>

## À Samuel

Section écrite au format C76-Q1. A-1 et A-2 de la première version sont tranchées (P76-D-32, P76-D-33) ; elles
restent ici, réécrites au format, comme premiers cas réels pour la lecture.

- **P76-Q-01 — Les trous en rouge face à Q9.** Le but du 2026-11-03 dit « les trous en rouge », Q9 interdit toute
  couleur d'alerte : comment marquer un trou ?
  Options : (a) glyphe et mot neutres pour une absence, octogone au trait corail pour une contradiction lue ; (b) trait corail pour tout trou ; (c) tout neutre.
  Recommandation : (a) — seule lecture qui tient les deux textes.
  Bloque : 76-06, 76-07
  État : tranchée — arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 — option (a) — « Une absence se dit par un glyphe et un mot, sans couleur. Seule une contradiction réellement lue (deux sources qui se contredisent) prend un octogone au trait corail. C'est ce que les plans prévoient déjà. »
- **P76-Q-02 — Graphe navigable réalisé sans dessin.** Le but parle de « graphe navigable » et de « graphe de liens » :
  dessin ou panneaux reliés ?
  Options : (a) panneaux reliés, voisinage seul ; (b) en plus, un dessin de l'îlot de mémoire d'un agent ; (c) un canevas des décisions.
  Recommandation : (a) — tient la direction « trois onglets, trois formes ».
  Bloque : 76-06, 76-07
  État : tranchée — arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 — option (a) — « Dans l'onglet Projet, un clic sur un objet ouvre l'objet voisin (l'exigence ouvre son plan, sa décision, sa preuve), avec un seul bouton Retour. Ni canevas ni quatrième onglet. »
- **P76-Q-03 — Poids ajouté à la page Projet.** La règle A32 de la Phase 79 fait entrer les manques du planning
  (maillons, définitions de décisions, preuves, questions) dans `cockpit-project@1`, environ 0,4 Mo de JSON de plus
  selon le planificateur : garder ?
  Options : (a) garder et mesurer à l'exécution ; (b) une exception à A32 pour les définitions de décisions, lues par la route.
  Recommandation : (a) — mesure écrite dans la trace de 76-04, la règle commune reste entière.
  Bloque : rien
  État : appliquée — décision déléguée par Samuel (message session principale, 2026-11-08), option (a) — P76-D-31

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
