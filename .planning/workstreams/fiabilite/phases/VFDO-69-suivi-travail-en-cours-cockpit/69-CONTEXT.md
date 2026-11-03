# Phase 69: Suivi du travail en cours dans le cockpit - Context

**Gathered:** 2026-11-03
**Updated:** 2026-11-03 (mise à jour du cadrage : équipe au travail, P69-D-12..24 ; Phases 71 et 72 inscrites)
**Status:** Cadrée — non planifiée

Inscription et cadrage documentaires (aucun code). Entrée unique :
`.planning/notes/2026-11-03-cockpit-progression-en-cours.md` (note de conception, copiée telle quelle).
Décision source : option A de cette note, **arbitrage Samuel, AskUserQuestion session principale,
2026-11-03**, « à implémenter dans la phase qui suit la 67 ». Création de la phase demandée par Samuel
en session principale, 2026-11-03. Numéro 69 posé à la main (le moteur propose un mauvais numéro sur ce
dépôt). Jalon `vibeflow-v2.0`, compartiment `fiabilite`.

**Exigences :** CKPT-13 à CKPT-18 (avancement des phases) et CKPT-19 à CKPT-28 (équipe au travail, posées à la mise à
jour du cadrage), suite de la famille de la Phase 67, libres le 2026-11-03, inscrites dans
`REQUIREMENTS.md` du compartiment et dans la ligne `Requirements` de la Phase 69 du ROADMAP.

<domain>
## Phase Boundary

La carte Projet du cockpit (`plugin/cockpit/scripts/vf-cockpit-project.mjs`) affiche aujourd'hui, pour le
jalon `vibeflow-v2.0`, « 0/2 phases · 0 % · à faire », et pour la Phase 67 « à faire · 11/7 plans · 0/12
exigences », alors que ses 7 plans sont exécutés et la PR #187 ouverte. La phase calcule dans la lib de
lecture (`readPlanning`, `vf-cockpit-planning.mjs`, futur socle de `vf-signal`, Phase 68) un état
d'avancement dérivé de traces locales, et retire la seule règle fausse.

Depuis la mise à jour du 2026-11-03 (P69-D-12), la phase couvre aussi **l'équipe au travail** : le tiroir « Au
travail » montre l'arbre session → manager → workers (aujourd'hui aplati en liste par `vf-cockpit-who.mjs`,
lignes 82-107), chaque agent relié au nœud de mission qu'il exécute, sa dernière action lisible, un onglet
« Équipe » et le transcript réduit d'un agent, lu à la demande.

**Hors périmètre :** option B ; toute lecture réseau ; release (geste humain) ; le terminal intégré (Phase 71) ;
lancer du travail depuis le cockpit (Phase 72).

</domain>

<decisions>
## Implementation Decisions

Registre de la phase : identifiants préfixés `P69-D-NN` (convention CLAUDE.md, ADR-075).

### Constat — causes mesurées dans le code (note § 1, branche `feat/v2-cockpit`)

- **C1** Phase 67 « à faire » : `phaseStatus` (`vf-cockpit-project.mjs:36`) ne connaît que 3 cas — case de
  ROADMAP cochée → fait ; `ph.n === curPhase` (`current_phase` du STATE) → en cours ; sinon → à faire.
  Le STATE pointe sur la 62 : plans et mission ne sont jamais lus pour le statut.
- **C2** « 11/7 plans » : `sums` (`:63`) compte tous les `*-SUMMARY.md`, dont les 4 `67-FIX-{A..D}-SUMMARY.md`
  (correctifs de mission, sans PLAN) : 7 + 4 = 11. Ce ne sont pas des nœuds de DAG.
- **C3** Jalon à 0 % : le pied (`:56`) ne compte que les phases à case cochée ; le statut du jalon (`:47`)
  vient de l'icône (`📋` → à faire) ou d'une phase close.
- **C4** Mission non rattachée : rattachement seulement si le DAG s'appelle `MISSION-<n>` (`:90`) ; celui de
  la 67, `2026-11-01-v2-cockpit.dag.json`, tombe dans « Missions hors phase ».
- **C5** Exigences 0/12 : cochées à la clôture de la phase seulement — voulu, seule vérité d'exigence. Rien
  à changer.

### Arbitrage de Samuel (AskUserQuestion session principale, 2026-11-03)

- **P69-D-01 (option A retenue, B écartée).** Statut de phase dérivé dans la lib de lecture, objet versionné,
  rien d'autre. Coût estimé : une vingtaine de lignes, affichage existant réutilisé, 4 cas de test.

### Règles de l'option A (note § 2)

- **P69-D-02 (objet `avancement`).** `readPlanning` expose par phase
  `{ "version": 1, "etat": …, "plans": {"faits","total"}, "correctifs": N, "mission": {"nom","etat"}, "reste": […] }`
  (CKPT-13). Il sera consommé par `vf-signal` (Phase 68).
- **P69-D-03 (quatre états, chacun avec sa preuve locale).** `a-faire` : aucun SUMMARY de plan ;
  `en-cours` : au moins un plan fait, ou mission rattachée avec un nœud `running` ; `a-recetter` : tous les
  plans faits, phase non cochée ; `fait` : case de ROADMAP cochée (CKPT-13). « À recetter » se déduit de
  « tous les plans faits et phase non close », jamais de « PR ouverte ».
- **P69-D-04 (décompte des plans, C2).** Un plan est fait s'il a un `*-PLAN.md` **et** son
  `*-SUMMARY.md`. Les SUMMARY sans PLAN forment une ligne à part, « 4 correctifs » (CKPT-14).
- **P69-D-05 (rattachement des missions, C4).** Dans l'ordre : (1) champ `phase` du DAG s'il existe,
  (2) nom `MISSION-<n>`, (3) DAG situé dans le dossier de la phase. Le cas de la 67 se règle par (1) : une
  ligne `"phase": "67"` dans son DAG (CKPT-15). Poser cette ligne dans le DAG de la 67 est un geste de
  mission, hors de cette phase documentaire.
- **P69-D-06 (jalon et pied).** Le jalon est `en-cours` dès qu'une de ses phases est `en-cours` ou
  `a-recetter`, quel que soit le STATE. Pied : « 0 clos · 1 à recetter · 1 à faire · 0 % ». Le pourcentage
  reste strict (phases closes seulement), jamais pondéré (CKPT-16).
- **P69-D-07 (`reste`, traces locales seulement).** Recette humaine : un `*-RECETTE-HUMAINE.md` dont le
  statut n'est pas « FAITE » ; vérification : pas de `*-VERIFICATION.md` ; clôture : case de ROADMAP non
  cochée. CI, merge et release ne sont **pas** affichés ; au mieux la release se lira depuis un tag local,
  « à voir plus tard » (CKPT-17).
- **P69-D-08 (retrait, un ajout = un retrait).** On supprime la règle `ph.n === curPhase` : le STATE ne
  pilote plus le statut d'une phase sur la carte, c'est la seule source qui ment ici (CKPT-18).

### Limite de fond

- **P69-D-09 (aucune lecture réseau).** Le cockpit ne fait aucun appel réseau (recette 67, point 5 ;
  P67-D-02). L'état d'une PR, de la CI ou d'un merge n'est donc **pas lisible** : « PR ouverte » ne peut
  venir que d'une trace locale, et la carte ne prétend jamais savoir ce qu'elle ne peut pas lire.

### Quatre témoins rouges (fixtures de lab, un par règle, joués avant le code)

| # | Fixture | Attendu | Aujourd'hui (rouge) |
|---|---|---|---|
| a | 7 PLAN, 7 SUMMARY et 4 SUMMARY de correctif | `7/7 plans · 4 correctifs` | 11/7 |
| b | STATE sur une autre phase, plans faits | `a-recetter` | à faire |
| c | DAG avec `phase: 67` | rattaché à la 67 | hors phase |
| d | Jalon `📋` avec une phase `a-recetter` | jalon `en-cours` | à faire |

Un témoin « décompte faussé par un nœud DAG » serait vert dès aujourd'hui et ne prouverait rien : le bon
témoin du décompte est un SUMMARY sans PLAN (note § 3 bis). Le retrait de la règle STATE (CKPT-18) se prouve
par le témoin (b) plus un test qui rougit si `curPhase` redevient une source de statut.

### Points écartés (option B, note § 3)

- Pourcentage de jalon pondéré : précision fausse (un plan n'est pas une unité constante ; 7/7 plans ne
  valent pas « 95 % » d'une phase qui attend sa recette).
- État d'exigence intermédiaire « livré, non vérifié » (`- [~]`) : second vocabulaire hors GSD, ignoré de
  `check-requirements-survival` et du moteur — la couche de synonymes à éviter.
- Liste d'étapes déclarée en frontmatter (`etapes:`) et cochée à la main : vert déclaré, non lu.
- B pourra revenir pièce par pièce si un besoin réel apparaît après la Phase 68.

### Arbitrages ultérieurs de Samuel (AskUserQuestion session principale, 2026-11-03)

- **P69-D-10 (ordre 69 avant 68).** Réponse de Samuel, mot pour mot : « 69 avant 68 (Recommandé) ». La
  Phase 68 dépend de la 69 : « Depends on » de la 68 mis à jour dans le ROADMAP ; la 68 consomme `avancement`.
- **P69-D-11 (refonte mobile hors 69).** Réponse de Samuel : « Phase à part (Recommandé) ». La refonte mobile,
  I1 et O5 relèvent de la Phase 70 « Finitions UI du cockpit » (inscrite 2026-11-03) ; les déclencheurs des
  deux entrées BACKLOG du cockpit y renvoient. La 69 n'a aucune exigence sur ce sujet.

### Mise à jour du cadrage — équipe au travail (arbitrages Samuel, AskUserQuestion session principale, 2026-11-03)

Réponses de Samuel consignées mot pour mot ; canal et date : AskUserQuestion, session principale, 2026-11-03.

- **P69-D-12 (découpage).** Réponses : « 69 = avancement + équipe, terminal en 71 (Recommandé) », puis « Oui, 69 / 71 /
  72 (Recommandé) ». La 69 couvre l'avancement des phases (option A, P69-D-01..09, inchangée) **et** l'équipe au
  travail. La Phase 71 porte le terminal intégré ; la Phase 72, lancer du travail depuis les cartes.
- **P69-D-13 (ordre du jalon).** Réponse : « 69 → 68 → 70 → 71 → 72 (Recommandé) ». Prolonge P69-D-10 ; la 72 dépend
  de la 71.
- **Affichage de l'équipe.** Réponse, les quatre retenus : « Arbre dans le tiroir, Lien vers les nœuds de DAG, Fil
  d'Ariane d'activité, Vue dédiée plein écran ».
  - **P69-D-14 (arbre).** Arbre session → manager → workers dans le tiroir « Au travail », avec type, description, état
    et durée (CKPT-19). Retrait associé (un ajout = un retrait) : la liste plate des sous-agents du tiroir.
  - **P69-D-15 (lien vers les nœuds de DAG).** Chaque agent rattaché au nœud de mission qu'il exécute, cliquable dans
    les deux sens (CKPT-21). Sources, dans l'ordre : registre de `driver-lock.sh` (`--node`), puis nom de nœud cité dans
    le mandat (premier message du transcript, souvent « Nœud `revue-p3` ») et présent dans un DAG connu ; jamais deviné.
  - **P69-D-16 (fil d'Ariane).** Pour chaque agent actif, sa dernière action lisible (« lit X », « lance les tests »),
    sans le détail des commandes (CKPT-22).
  - **P69-D-17 (vue dédiée).** Un troisième onglet « Équipe », en carte comme Code et Projet (CKPT-23).
- **P69-D-18 (historique).** Réponse : « Actifs + terminés récents (collapsable) ». Les agents en cours, plus ceux finis
  dans les dernières 24 h, grisés et repliables (CKPT-20).
- **P69-D-19 (transcripts).** Réponse, mot pour mot : « Message et action, sans les sorties. Je veux aussi anticiper à
  l'intégration prochaine terminale et de pouvoir travailler directement dans le cockpit, c'est-à-dire que on a déjà
  un chat qui est prévu enfin qui est actuellement dans l'application, ils permet de poser des questions mais pas
  forcément de lancer du travail, il faudrait qu'on puisse aussi lancer du travail éventuellement donc ça sera l'idée
  d'avoir une session Claude code qui tourne dans le code une session de terminale dans l'idéal, et ça permettrait de
  lancer par exemple depuis les cartes ou depuis le cockpit du travail soit en cliquant sur les cartes de phase ou de
  mission ou peu importe. Bien sûr, il faudrait qu'on anticipe les manque, les dépendances manquantes donc ça
  empêcherait l'exécution, il faudrait qu'on anticipe aussi et les impossibilité voilà qu'on qu'on fasse pas de but en
  blanc donc ça potentiellement le chat qui permet de poser des questions permet déjà d'avoir le contexte et puis
  ensuite on pourrait éventuellement lancer du travail depuis le cockpit donc c'est-à-dire avec la méthode Vilo avec le
  Fail système qui vit qui vit littéralement sur le PC et donc il peut travailler sur les work qui peut faire des
  poches qui peut écrire dans des fichiers qui s'ouvre avec déjà le contexte, projets, les skis etc. cetera »
  - Ce que la 69 en retient : le mandat, les messages de l'agent et la liste de ses outils (une commande réduite comme
    « Voir la dernière commande », règle F-B de `v2.75.0`). Jamais les sorties d'outils ni le contenu des fichiers lus.
    Local, à la demande, jamais exporté (CKPT-24, CKPT-25).
  - Le reste, lancer du travail, est la vision des Phases 71 et 72 (lecture de la transcription vocale : « Vilo » =
    VibeFlow, « Fail système » = file system, « work » = worktrees, « poches » = PR, « skis » = skills).
- **P69-D-20 (terminal, hors 69).** Réponse : « Terminal intégré dans la page » (xterm.js et une PTY native). C'est la
  Phase 71, avec un audit de sécurité complet : elle change le modèle de menace du cockpit (un shell complet derrière
  le serveur local).
- **P69-D-21 (lancer du travail, hors 69).** La Phase 72 porte la vision de P69-D-19 : lancer du travail depuis les
  cartes de phase ou de mission, en anticipant les dépendances manquantes et les impossibilités, avec le contexte du
  chat. Dépend de la 71.

### Faits mesurés (session principale, 2026-11-03)

- **P69-D-22 (format Claude Code non documenté, test de forme étendu).** Pour chaque sous-agent, Claude Code écrit
  `~/.claude/projects/<slug>/<session>/subagents/agent-<id>.meta.json` (`agentType`, `description`, `parentAgentId`,
  `spawnDepth`, `finished`, `toolUseId`, `requestShape`) et `agent-<id>.jsonl` (transcript, avec `isSidechain` et
  `agentId` ; son premier message est le mandat). Mesure sur une session réelle : 39 sous-agents, dont 37 avec un
  `parentAgentId`. `vf-cockpit-who.mjs` lit déjà ces fichiers (lignes 82-107) mais les aplatit en liste. Ce format
  n'est pas documenté : le test de forme de CKPT-01 couvre chaque champ nouvellement lu et rougit si l'un disparaît
  (CKPT-27).

### Contraintes de doctrine du cockpit (équipe au travail)

- **P69-D-23.** Calcul dans la bibliothèque du socle (`readPlanning`, `who`), sous un JSON versionné ; aucune requête
  réseau ; un ajout = un retrait (SOBR) ; aucune couche de synonymes ; XSS et CSP inchangés ; transcripts jamais
  exportés ni présents dans le flux SSE sans requête authentifiée (CKPT-25, CKPT-26, CKPT-28).
- **P69-D-24 (un témoin rouge par règle).** Chaque exigence CKPT-19..28 porte son témoin rouge, joué avant le code.
  Un helper de test qui tue des processus passe la marque par `awk -v`, refuse une marque vide, plafonne le nombre de
  processus tués, garde un leurre vivant et ne fait jamais de `pkill -f` par motif.

### Point ouvert

- **Ligne `phase` du DAG de la 67** : à poser côté mission 67 (Samuel la traite, même date).

</decisions>

<canonical_refs>
## Canonical References

- `.planning/notes/2026-11-03-cockpit-progression-en-cours.md` — constat, causes C1-C5, options A et B.
- `plugin/cockpit/scripts/vf-cockpit-project.mjs` (`phaseStatus`, `sums`, pied de jalon, rattachement des
  missions) et `plugin/cockpit/scripts/vf-cockpit-planning.mjs` (`readPlanning`).
- `.planning/workstreams/fiabilite/phases/VFDO-67-cockpit-floorplan-socle-partage/67-CONTEXT.md` — P67-D-02
  (aucun appel sortant), P67-D-12 (socle JSON versionné).
- Phase 68 (ROADMAP) — consommatrice de `readPlanning`.
- `plugin/cockpit/scripts/vf-cockpit-who.mjs` (collecteur « au travail », lignes 82-107) et
  `plugin/cockpit/scripts/vf-cockpit-interface.json` (contrat versionné et clés Claude Code vérifiées).
- Phases 71 et 72 (ROADMAP) — terminal intégré, lancer du travail depuis les cartes.

</canonical_refs>
