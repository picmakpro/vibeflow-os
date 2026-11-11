# Phase 79: Socle du cockpit — une collecte, un flux, une route d'état - Context

**Cadrée le :** 2026-11-11, par le manager de la phase (mission de cadrage et de planification, compartiment
`fiabilite`, jalon `vibeflow-v2.0`), sur la base `integration/cockpit-audit` (release v2.77.0 alignée + lot 0 de
l'audit). Les faits cités viennent de quatre relevés en lecture seule du code présent (lot 0 inclus) ; les numéros
de ligne de l'audit ont bougé depuis le 2026-11-10, ceux d'ici sont ceux de la base.

**Entrées :** `.planning/research/2026-11-10-audit-cockpit-etude.md` § 8.2 ; `REGISTRE.md` du même dossier (lignes
absorbées ci-dessous) ; `DESIGNS.md` § 2, § 4, § 9 ; annexes A1, A2, A3, A6 ; rapport du lot 0
`.planning/missions/2026-11-11-audit-cockpit-lot-0.md`.

<domain>
## Phase Boundary

Le serveur du cockpit collecte sans bloquer et sert un état unique : un index incrémental des transcripts, une route
d'état en JSON lue par la page et par `vf-signal`, un seul flux d'événements partagé entre les onglets, des données
sorties de la page, et un serveur lancé depuis le module plutôt que depuis une copie dans le lab.

**Absorbe (part restante après le lot 0 seulement) :** AUDC-A-03, AM4 (première vague, constat de sécurité) ; la
classe restante d'AUDC-A-02 (chemin jugé sur sa forme écrite alors que git le résout physiquement) avec D-M15 et les
limites d'AUDC-A-04 ; H3 reste (empreinte de relance) et D-M13 ; D5 et I37 (registre du verrou, nœud dans le mandat) ;
D9 ; H1 reste (flux partagé entre onglets) et D-M2 (coupure muette) ; H2 reste (collecte asynchrone) ; H4 reste
(traduction au point d'émission) ; H5 (fork assumé, AUDC-Q5) ; AM1, AM2, AM3 avec M7 reste, AM5, AM6, AM7 reste ;
AB1 ; idées I18, I19, I20, I22, I31, I32, I37.

**Hors périmètre :** la régie et l'onglet Équipe (Phase 73) ; la frise, la fiche d'agent, le coût affiché (Phase 74) ;
le radar et l'empreinte en direct (Phase 75) ; la synthèse (Phase 77) ; les onglets sans rechargement (Phase 80,
AUDC-I30, sur la coquille fournie ici) ; toute action sur une session (Phase 81, AUDC-Q3 « plus tard »).

</domain>

## Contrats fournis

Section figée le 2026-11-11 avant la recherche détaillée et les plans, pour les Phases 73, 74, 75, 77 et 80. Elle dit
ce que la Phase 79 livre et ce que ses consommateurs peuvent tenir pour acquis. Un plan de la 79 qui s'en écarte doit
le dire ici, en amendement daté, avant d'être exécuté.

### C0. Règles communes à tous les contrats

- **Accès.** Toute route `/api/vf/*` reste derrière les contrôles présents de `serve.mjs` : hôte exact
  `127.0.0.1:<port>` ou `localhost:<port>` (sinon 403) ; `Origin` absente ou égale à `http://<hôte>` (sinon 403) ;
  jeton de la page Code ou de la page Projet en en-tête **`x-vf-cockpit-token`** (forme servie ; le paramètre `?token=`
  n'est admis que sur `/api/vf/events`), comparé en temps constant (sinon 403). Méthode autre que GET : 405. Chemin
  inconnu : 404. Aucun en-tête CORS. Réponses JSON en `Cache-Control: no-store`.
- **Client hors navigateur** (`vf-signal`, un futur client) : jeton lu dans `.vibeflow/cockpit/.cache/server.json`
  (mode 0600, jamais servi), `Host` explicite, pas d'`Origin`. Aucun appel réseau sortant : la boucle locale seule.
- **Garde d'émission.** Toute réponse des routes de ce contrat et tout événement du flux passent la garde
  `porteInterdit` : refus, à toute profondeur, des clés **`doing`, `mandat`, `messages`, `outils`, `fil`** (liste du
  contrat de forme, cinq clés depuis AUDC-D8). Garde déclenchée ou liste illisible : rien n'est émis (fermé par
  défaut) ; une route répond 503 `{ "erreur": "emission-refusee" }`. Les routes à la demande existantes
  `/api/vf/doing` et `/api/vf/transcript` gardent leur régime propre (P67-D-14, P69-D-19), inchangé.
- **Bornes de contenu** (inchangées, P67-D-14, P69-D-16, P69-D-19, P69-D-23) : jamais une dernière commande, un
  argument de commande, un texte de message, une entrée d'outil autre que la cible réduite, une sortie d'outil ; une
  cible est un chemin **relatif au lab** ou le libellé « un fichier hors du lab », jamais un chemin absolu.
- **Versions.** Chaque schéma est déclaré dans `plugin/cockpit/scripts/vf-cockpit-interface.json`. Ajouter un champ
  facultatif ne change pas la version ; retirer, renommer ou changer le type d'un champ la monte d'un cran (`@N+1`).
  Un lecteur ignore les champs qu'il ne connaît pas et vérifie `schema` avant de lire. Les schémas existants
  (`cockpit-signal@1`, `cockpit-who@2`, `cockpit-project@1`, `cockpit-equipe@1`, `cockpit-transcript@2`,
  `cockpit-doing@1`, `cockpit-git*@1`, `avancement@2`) **ne changent pas de forme** dans la Phase 79.
- **Temps.** `at` et les instants de premier niveau en ISO 8601 ; les instants des segments et des événements de la
  frise en millisecondes depuis l'époque Unix (forme compacte).

### C1. Index incrémental des transcripts — `vibeflow/cockpit-index@1` (privé au serveur)

- **Nature.** Fichier de données du lab, jamais servi tel quel, jamais exporté, jamais importé ni évalué. Sa projection
  publique est la route de frise (C3). AUDC-Q2 (Samuel, 2026-11-11) : index sur disque, **borné à heures, durées,
  jetons et verbes**, fenêtre de 24 h.
- **Emplacement.** `.vibeflow/cockpit/.cache/index-transcripts.json`, écrit par le seul serveur du lab (celui qui tient
  le verrou du lanceur), par fichier temporaire puis renommage, mode 0600.
- **Non fiable à la lecture** (classe AUDC-B-05 : un fichier du cache peut être arrivé avec une archive du lab).
  Schéma, version et bornes vérifiés à chaque chargement ; une voie dont le transcript n'existe plus, dont la taille
  réelle est inférieure au décalage ou dont l'empreinte de tête diffère est relue depuis zéro ; un fichier invalide est
  écarté et reconstruit. Identifiants filtrés par le motif d'identifiant du socle. Rendu en texte côté page (jamais en
  HTML).
- **Fenêtre.** Une voie par transcript (session ou sous-agent) dont la dernière ligne date de moins de 24 h, ou encore
  vivante (état officiel vivant ou appel ouvert). Purge à chaque écriture. Aucune rétention au-delà.
- **Forme.**
  - en-tête : `schema`, `ccVerifie` (version de Claude Code du contrat de forme), `versionsVues` (≤ 8 chaînes),
    `genereA` (ISO), `fenetreS` (= 86400) ;
  - `voies[]` : les champs de la voie publique (C3, sans `etatOfficiel` ni `cibles`) + un `curseur` interne jamais
    servi : `octets` (fin de la dernière ligne complète lue), `taille`, `mtimeMs`, `tete` (empreinte de la première
    ligne), `dernierMsgId` et son `usage` (un message réparti sur plusieurs lignes n'est jamais compté deux fois),
    `ouverts` (appels d'outil non appariés : identifiant → verbe et instant, ≤ 64).
- **Lecture incrémentale.** Seuls les octets ajoutés depuis le curseur sont lus, hors de la boucle d'événements ; un
  fichier raccourci ou dont la tête a changé est relu depuis zéro.
- **Jamais dans l'index :** les cinq clés interdites, un texte, une description de tâche, un titre, une entrée d'outil,
  une sortie d'outil, **une cible** (les cibles restent en mémoire : C3 `cibles`, et « À Samuel » S-1).

### C2. Route d'état — `GET /api/vf/state` → `vibeflow/cockpit-state@1`

- Une seule collecte, dans le serveur, sert la page, `vf-signal` et tout client futur (AUDC-I19, AM1).
- **Corps (200) :**

  ```json
  {
    "schema": "vibeflow/cockpit-state@1",
    "at": "<ISO>",
    "seq": 0,
    "collecte": { "etat": "ok|en-cours|partielle|indisponible", "derniereA": "<ISO>|null",
                  "dureeMs": 0, "mode": "watch|poll|absent", "clients": 0 },
    "signal": { "schema": "vibeflow/cockpit-signal@1", "...": "forme inchangée" }
  }
  ```

  `seq` est le compteur du flux (C4) ; `signal` est un objet `vibeflow/cockpit-signal@1` **de forme inchangée** (phases,
  jalons, missions, verrous normalisés, arbres, `equipe` au format `vibeflow/cockpit-who@2` avec l'état officiel) ;
  `signal` vaut `null` tant que la première collecte n'est pas faite (`collecte.etat: "en-cours"`).
- **Erreurs :** 403 (contrôles C0), 405, 503 `{ "erreur": "emission-refusee" }` (garde). Jamais de collecte déclenchée
  par la requête : la route lit le dernier instantané.
- **`vf-signal`.** Lit cette route quand un serveur du lab est vivant (`server.json` présent, processus reconnu) et
  valide `signal.schema` comme aujourd'hui. Sans serveur, il garde son émetteur actuel à sa cadence actuelle
  (P68-D-41) : la collecte refaite toutes les 10 s disparaît quand le serveur tourne (retrait de la phase).
- **Payload `lock` du flux** : laissé tel quel (sortie brute, non versionnée) pour compatibilité ; un nouveau lecteur
  lit les verrous dans `signal.verrous`.

### C3. Route de frise — `GET /api/vf/frise` → `vibeflow/cockpit-frise@1`

- **Paramètres** (facultatifs, entiers en ms) : `depuis` (défaut maintenant − 24 h ; ramené à maintenant − 24 h s'il
  est plus ancien), `jusqua` (défaut maintenant ; ramené à maintenant s'il est futur). Paramètre non entier, ou
  `depuis ≥ jusqua` : 400 `{ "erreur": "bornes-invalides" }`. Aucune fenêtre au-delà de 24 h (P69-D-18, AUDC-Q2).
- **Corps (200) :** `{ schema, at, depuis, jusqua, fenetreS: 86400, source, tronque, voies[] }` ; `source` =
  `{ etat: "ok|en-construction|partielle|forme-inconnue|indisponible", ccVerifie, versionsVues }` ; `tronque` vrai si
  une borne de taille a coupé quelque chose.
- **Voie :**

  | Champ | Type | Sens |
  |---|---|---|
  | `id` | chaîne | `sessionId` pour une session, identifiant d'agent pour un sous-agent |
  | `kind` | `session` \| `subagent` | |
  | `session` | chaîne | session racine |
  | `parent` | chaîne \| null | agent ou session qui l'a lancé |
  | `depth` | entier \| null | profondeur de lancement (`spawnDepth`) |
  | `role` | chaîne ≤ 64 \| null | type d'agent (`agentType`) |
  | `arbre` | chaîne \| null | libellé relatif du worktree, jamais un chemin absolu |
  | `background` | booléen | lancé en arrière-plan |
  | `debut`, `fin` | ms | première et dernière ligne datée |
  | `dispatchA` | ms \| null | instant de l'appel parent apparié |
  | `fini`, `arrete` | booléens | fin déclarée, arrêt par l'humain |
  | `etatOfficiel` | `actif` \| `attend` \| `au-repos` \| `termine` \| null | état présent de `claude agents --json` (AUDC-Q4), jamais persisté |
  | `modeles` | chaînes (≤ 4) | modèles vus |
  | `compteurs` | objet | `appels`, `erreurs`, `refus`, `questions`, `compactions`, `tours`, `reponsesApi` |
  | `jetons` | objet | `entree`, `sortie`, `cacheLu`, `cacheCree`, `contexteMax`, `contexteDernier` (dédoublonnés par message) |
  | `durees` | objet | `travailS`, `attenteHumainS`, `attenteAgentsS`, `reposS`, `silenceS` (somme des segments) |
  | `segments` | `[debutMs, finMs, genre][]` (≤ 500) | `genre` ∈ `travail`, `attend-agents`, `attend-humain`, `repos`, `silence` ; coupés à `[depuis, jusqua]` |
  | `evenements` | `[tMs, genre][]` (≤ 500) | `genre` ∈ `compaction`, `erreur`, `humain`, `rapport`, `dispatch` |
  | `enCours` | `{ verbe, depuisMs }` \| null | verbe de la table fermée du socle, jamais l'entrée de l'outil |
  | `rattachement` | `{ dag, noeud, source: "registre" \| "mandat" \| "enfants" }` \| null | nœud du plan de mission (AUDC-I37) ; `noeud` null si `source: "enfants"` (amendement A14) |
  | `cibles` | `{ etat: "ok" \| "en-construction", ecritures: [{cible, n, dernierMs}] (≤ 200), lectures: [...] (≤ 200) }` | **en mémoire seulement**, reconstruites au démarrage par une passe en tâche de fond sur la fenêtre ; cible réduite (C0) |

- **Hors de la frise :** les commits (Git, routes `/api/vf/git*`), le fil daté d'un agent (route existante
  `/api/vf/transcript`, `cockpit-transcript@2`), le coût en monnaie et les limites de 5 h et de 7 jours (hors de
  cette vague, voir l'amendement).
- **Erreurs :** 400, 403, 405, 503 `emission-refusee`. Index en cours de construction : 200 avec
  `source.etat: "en-construction"` et les voies déjà connues.

### C4. Flux d'événements partagé — `/api/vf/events`

- **Un flux par navigateur et par lab**, plus un par page : un onglet élu tient l'unique `EventSource` et relaie les
  événements aux autres onglets de la même origine ; à sa fermeture, un autre onglet reprend le flux sans
  rechargement. Navigateur sans les primitives nécessaires : repli sur un flux par page (comportement du lot 0).
- **Événements, payloads inchangés :** `hello` `{seq, lock, who}`, `patch`, `structural`, `who` (`cockpit-who@2`),
  `lock` (brut), `git` `{seq, at, sig}`, `reload` `{}`.
- **Événements ajoutés :**
  - `frise` `{ seq, at, sig }` : signature de 16 caractères de l'index, émise au seul changement, sans contenu ; le
    lecteur relit `GET /api/vf/frise` ;
  - `etat` `{ seq, at, sig }` : signature de l'instantané d'état, émise au seul changement ; le lecteur relit
    `GET /api/vf/state` ;
  - `vie` `{ seq, at }` : battement nommé toutes les 15 s (remplace le commentaire `: ka`, invisible au JavaScript) ;
    côté page, au-delà de 45 s sans aucun événement, le flux est déclaré perdu et suit la reprise existante (AUDC-D-M2).
- **Reprise :** pas d'identifiant SSE ; la resynchronisation passe par `seq` (comme aujourd'hui) et, pour un lecteur
  d'état, par une relecture de `GET /api/vf/state`.
- **API côté page** (ce que 73, 74, 75 et 80 consomment) : un magasin `window.VF_ETAT` alimenté par le flux,
  `VF_ETAT.lire(cle)` et `VF_ETAT.abonner(cle, rappel)` → fonction de désabonnement ; clés `etat` (dernier
  `cockpit-state@1`), `who`, `frise` (dernier `cockpit-frise@1` lu à la demande), `git`, `connexion`
  (`ouvert|perdu|reprise`). Les événements de document existants (`vf-who`, `vf-git:signal`) restent émis pendant la
  Phase 79 et s'éteignent quand plus aucun lecteur ne les écoute.

### C5. Coquille statique et données en JSON (ce que la Phase 80 reçoit)

- Les pages Code, Projet et Équipe deviennent **une même coquille** servie depuis le module, mise en cache par le
  navigateur (`ETag`), sans données incluses ; leurs données arrivent par :
  - `GET /api/vf/graphe?onglet=code|projet|equipe` → respectivement `vf-cockpit/graph@1` (format du moteur, hors
    contrat), `vibeflow/cockpit-project@1`, `vibeflow/cockpit-equipe@1` (formes inchangées) ; `ETag` = signature,
    `If-None-Match` → 304 ; `onglet` inconnu → 400 `{ "erreur": "onglet-invalide" }` ;
  - le magasin `VF_ETAT` (C4).
- Le serveur ne réécrit plus `project.html` sur disque à chaque changement ; l'export garde une page autonome (coquille
  + données incluses, mise en page sans worker).
- La mise en page du canevas tourne dans un worker servi par le module (AUDC-AM3, M7).
- **Pour la Phase 80 :** les onglets sans rechargement (AUDC-I30) se bâtissent sur cette coquille et ce magasin ; la 79
  ne change ni l'ordre ni la forme des onglets.

### C6. Ce que la Phase 79 retire ou change sous les pieds d'une autre phase

- **Appareil de patchs du moteur retiré en première vague** (AUDC-H5, fork assumé, AUDC-Q5) : `plugin/cockpit/amont/`
  disparaît, `VENDORED.txt` ne garde que l'origine, la sentinelle du moteur et l'inventaire du plafond. Une phase qui
  modifie un fichier du moteur après cette vague ne régénère plus de diff ; avant, elle en régénère un, et la fusion
  avec la 79 se résout en gardant la suppression.
- **Code évalué depuis le module** (AUDC-AM4, A-03) : les suites ne lancent plus `<sortie>/serve.mjs` mais le
  `serve.mjs` du module avec la sortie en argument ; une aide commune de lancement est fournie (AUDC-AM7).
- **Contrat de forme** `vf-cockpit-interface.json` : bloc nouveau pour l'index (`message.id`, `message.model`,
  `message.usage`, `stop_reason`, blocs d'appel et de résultat d'outil limités à leurs identifiants et au drapeau
  d'erreur, `compact_boundary`, `turn_duration`), description de `vueAgents` réécrite selon AUDC-Q4, `verifieSur`
  revérifié. La Phase 74 n'a donc pas à étendre le contrat pour lire les jetons.

### Amendement du 2026-11-11 (retours des Phases 74, 76, 77 et 80, relayés par la session principale)

Décisions déléguées par Samuel (message session principale, 2026-11-08), option recommandée. Elles complètent C0 à C6
sans en retirer rien.

- **A1 (80) — adresses des onglets.** `/`, `/project.html` et `/equipe.html` restent servies, toutes trois par la même
  coquille ; le fragment (`#r=…`, `#v=…&s=…`) est lu tel quel par le moteur, inchangé.
- **A2 (80) — changement d'onglet sans rechargement.** La coquille est à la 79 : elle expose
  `VF_COQUILLE.chargerOnglet(nom)` (`nom` ∈ `code`, `projet`, `equipe`), qui lit `GET /api/vf/graphe?onglet=<nom>` et
  réinitialise le moteur avec ce graphe dans le même document, et rend une promesse résolue après le premier rendu.
  Le routage (adresse, événement `vf:onglet`, focus, historique) est à la Phase 80, qui l'appelle.
- **A3 (80) — terminal.** L'iframe et l'amorce du terminal (sous `--terminal`) sont posées une fois par chargement de la
  coquille, jamais par onglet ; l'amorce reste à usage unique et garde son délai de 60 s.
- **A4 (80) — mise en page en worker.** L'API globale du moteur (`window.Floorplan` dans le source, servie sous
  `window.VibeFlow`) garde l'événement `render`, émis après la pose des positions calculées par le worker ;
  `state.layout.children` (x, y, w, h) et `freeArea()` restent exposés avec la même forme.
- **A5 (80) — champs ajoutés au graphe Projet en direct.** Le payload `patch` reste `st`, `foot`, `sum`. Événement
  ajouté au flux C4 : `graphe` `{ seq, at, onglet, sig }`, émis quand la signature complète du graphe d'un onglet
  change ; le lecteur relit `GET /api/vf/graphe?onglet=<onglet>`. Les champs facultatifs que la 80 ajoute au nœud de
  phase de `cockpit-project@1` arrivent ainsi sans qu'elle touche à `vf-cockpit-live.mjs`, qui reste à la 79.
- **A6 (80) — aide commune des suites.** Fichier `plugin/cockpit/scripts/tests/socle-serveur.sh`, à sourcer, livré
  par le plan 79-02 (première vague). Fonctions : `cockpit_lancer <lab> [options du serveur…]` (lance le serveur,
  attend qu'il écoute, exporte `VF_PORT`, `VF_JETON`, `VF_PID`, `VF_SORTIE`) ; `cockpit_arreter` ; `cockpit_get
  <chemin>` (GET avec l'hôte et le jeton, corps sur la sortie, code HTTP dans `VF_CODE`) ; `attendre <délai en s>
  <commande…>` (attente active bornée, à la place d'une pause fixe). La signature ne change pas quand le plan 79-06
  lance le serveur depuis le module.
- **A7 (80) — ordre.** Le plan **79-01** retire `plugin/cockpit/amont/` en première vague. Fichiers du moteur que la
  79 modifie : `assets/serve.mjs`, `assets/graph-query.js`, `assets/query-cli.mjs`, `scripts/scan.mjs`,
  `scripts/lib/common.mjs`, `scripts/lib/vf-git-sortant.mjs`, `assets/viewer.html`, et sous `assets/ui/` au moins
  `70-vf-live.js`, `75-vf-modele.js`, `78-vf-fr-dict-a.js`, `79-vf-fr-dict-b.js`, `80-vf-fr.js`. `viewer.html` n'est
  touché par la 79 qu'à partir de sa troisième vague (coquille, worker, traduction). La liste finale, fichiers d'ui
  traduits ou débarrassés d'observateurs compris (dont peut-être `40-tour.js` et `05-theme.js`), est celle des
  `files_modified` des plans ; elle sera renvoyée à la session principale avec leur SHA.
- **A8 (74) — jointure nœud, mission, phase.** `rattachement.dag` d'une voie vaut exactement
  `signal.missions[].fichier` : même source (le fichier du plan de mission) et même réduction (texte nettoyé, 200
  caractères au plus).
- **A9 (74) — commits.** `cockpit-git@1` n'est pas modifié par la 79. Fait relevé : `rangees[].at` est l'heure
  d'auteur en **secondes** Unix (`%at`), à multiplier par 1000 pour la frise ; la marche est bornée à 500 commits
  (`BORNES.base`), donc les 24 h ne sont couvertes que si elles tiennent dans cette borne : à mesurer par la 74.
- **A10 (76, 77, et toute phase) — règle de C0 : une route neuve, une ligne.** La 79 livre en première vague (plan
  **79-05**) une table des routes de `vf-cockpit-server.mjs` : une route GET `/api/vf/*` s'ajoute par une entrée
  d'une ligne (chemin, lecteur), sans retoucher la répartition. Deux phases qui ajoutent chacune une route ajoutent
  chacune une ligne ; l'ordre des lignes est alphabétique par chemin pour que deux insertions ne tombent pas au même
  endroit.
- **A11 (76, 77, et toute phase) — règle de C0 : réponse gardée commune.** Le même plan exporte une fonction unique
  qui applique à une réponse JSON les contrôles de C0, la garde `porteInterdit`, `Cache-Control: no-store` et le 503
  `emission-refusee` ; une route neuve l'appelle et ne recopie aucun contrôle.
- **A12 (76) — lecture du lab.** Le point de lecture confiné de `vf-cockpit-planning.mjs` (ou son successeur nommé
  par le plan qui traite la classe restante d'AUDC-A-02) reste l'API unique de lecture d'un fichier du lab ; il lit
  tout chemin sous la racine réelle du lab, dossiers cachés compris (`.planning/`, `.claude/agent-memory/`, `docs/`).
  La 79 change la façon de juger un chemin (résolution physique), pas ce qu'il couvre.
- **A13 (76) — jeton et planning côté page.** La coquille expose `VF_ETAT.jeton()` et `VF_ETAT.lireJson(chemin)`
  (GET avec `x-vf-cockpit-token`) : aucun script de page ne lit le jeton autrement. L'événement `structural` reste
  émis à chaque changement de `.planning/`, et la clé `planning` de `VF_ETAT` (`{ seq, at }`) change avec lui.
- **A14 (77) — voie du manager.** `rattachement` peut valoir `{ dag, noeud: null, source: "enfants" }` : une voie sans
  nœud propre dont tous les enfants rattachés pointent le même plan de mission reçoit ce plan ; enfants sur plusieurs
  plans ou aucun enfant rattaché → `null`. Le coût de l'étage manager se somme ainsi par mission et par phase.
- **A15 (73) — verrous dans le flux : projection côté serveur.** Le payload brut de `driver-lock.sh` quitte le flux.
  L'événement `lock` et le champ `lock` de `hello` portent désormais `{ seq, at, verrous }`, où `verrous` a la forme
  de `signal.verrous` (C2) ; chaque entrée de `verrous.liste` est une **liste blanche** construite champ par champ,
  plus aucune recopie de l'entrée brute : `ws`, `scope`, `phase`, `step` (≤ 80), `tenu`, `stale`, `ageS`, `ttl`,
  `progressAgeS`, `owner` (≤ 80), `childrenRunning`, `dag` (A16). Aucun chemin, aucun emplacement de verrou, aucune
  liste d'identifiants de session. `signal.verrous` passe par la même projection (les champs requis du contrat sont
  gardés ; `step`, `childrenRunning`, `dag` sont des facultatifs ajoutés). Les lecteurs de la page sont mis à jour
  dans le même plan. Ni verrous ni payload `lock` n'entrent dans l'export (règle C0-export ci-dessous).
- **A16 (73) — plan de mission publié.** La 79 le prend, côté `plugin/conductor`, dans le plan **79-03** : un manager
  qui tient un verrou publie le résumé de son plan de mission à côté du verrou (dossier du verrou, sous le dossier git
  commun, jamais dans l'arbre de travail), par `driver-lock.sh` ; le résumé ne porte que les identifiants de nœuds,
  leurs dépendances et leur statut, avec le compartiment et la phase du verrou ; `status --all` le rend dans un champ
  `dag` de l'entrée, que la projection A15 transmet. Le texte libre d'un nœud n'est jamais publié. La doctrine
  (plan **79-04**) dit au manager de publier son plan à l'initialisation et à chaque marque.
- **A17 (73) — `cockpit-who@2`.** Les champs facultatifs que la 73 ajoute sont permis (C0). La signature du `who`
  (`vf-cockpit-live.mjs`) est calculée sur l'objet entier moins une liste nommée de champs volatils (l'âge
  aujourd'hui) : tout champ ajouté est couvert sans retouche ; un champ volatil ajouté s'inscrit dans cette liste.
  Fusion : dans `vf-cockpit-interface.json`, la 79 ajoute des blocs de schémas neufs et ne modifie pas le bloc
  `cockpit-who@2` hors des deux facultatifs de A20 ; dans `vf-cockpit-who.mjs`, la 79 n'intervient qu'aux plans de
  l'environnement git (deuxième vague) et de la collecte (troisième vague). Ordre libre : la jointure résout.
- **A18 (73) — `vf-cockpit-etat-officiel.mjs`.** La 79 n'y touche que dans le plan de la collecte (troisième vague),
  pour A20 ; la fonction exportée de la 73 (AUDC-I10) s'ajoute en fin de fichier, sans recouvrement attendu.
- **A19 (73) — `cockpit-equipe@1`.** Noté : forme stable, la route `graphe?onglet=equipe` la sert telle quelle.
- **A20 (73) — silence et échec.** Deux facultatifs ajoutés à `cockpit-who@2` par le plan de la collecte :
  `sortisSilence` (entier, au premier niveau : agents non finis sortis de la collecte pour un silence au-delà de
  1 800 s, sur la fenêtre de 24 h) et `finMotif` (`echec` \| `arret` \| null, par travailleur, lu de l'état officiel :
  `failed` → `echec`, `stopped` → `arret`). L'état reste `termine` ; seul le motif s'ajoute, derrière le contrat de
  forme (`vueAgents`).
- **A21 (75) — fraîcheur des cibles.** La signature portée par l'événement `frise` est calculée sur la projection
  publique entière, `cibles` comprises : un changement de cible change la signature.
- **A22 (75) — référentiel des cibles.** Chaque entrée de `cibles` porte `cible` relative à la **racine réelle de
  l'arbre de la voie** quand cet arbre est sous le lab (worktrees sous le lab compris), à côté du libellé `arbre` de
  la voie. Un arbre hors du lab reste « un fichier hors du lab » (borne CKPT-22 en vigueur ; question S-3).
- **A23 (75) — chemin réel.** Une cible est calculée sur la résolution physique complète (lien symbolique résolu ;
  fichier supprimé : résolution du plus proche parent existant puis le reste du nom) ; échec de résolution → « un
  fichier hors du lab ». Même fonction que la classe restante d'AUDC-A-02, une seule règle.
- **A24 (75) — outils comptés.** `lectures` : `Read` seul. `ecritures` : `Write`, `Edit`, `MultiEdit`,
  `NotebookEdit`. `Grep`, `Glob`, `Bash` ne produisent aucune cible.
- **A25 (75) — règle de C0, export.** L'index, la route d'état, la route de frise, les `cibles`, les verrous et le
  plan de mission publié n'entrent **jamais** dans l'export autonome (P67-D-14, P69-D-19). Témoin : un lab dont
  l'index, les cibles et un verrou portent un marqueur unique ; l'export ne contient le marqueur nulle part ; le même
  marqueur placé dans une donnée exportée légitime apparaît (témoin positif).
- **A26 (75) — route neuve.** `/api/vf/activite` s'ajoute par une ligne de la table (A10) et la réponse gardée (A11).
- **A27 (75) — graphe de l'onglet Code.** `GET /api/vf/graphe?onglet=code` sert le `graph.json` construit sur disque
  par l'assemblage (annoté par `vf-cockpit-build.mjs`), relu quand il change ; il n'est pas recalculé par requête. Une
  phase ajoute des nœuds ou des attributs au graphe Code par un **annotateur** inscrit d'une ligne dans une table de
  `vf-cockpit-build.mjs` (même règle que A10, livrée par le plan 79-05) ; il tourne à chaque assemblage. Un
  changement de `.planning/` seul ne reconstruit pas le graphe Code : un besoin de fraîcheur plus courte se dit à la
  79 par amendement.
- **A28 (75, facultatif retenu) — `?champs=cibles`.** `GET /api/vf/frise?champs=cibles` rend chaque voie réduite à
  `id`, `arbre` et `cibles` ; `champs` inconnu → 400 `{ "erreur": "champs-invalides" }`.
- **Note C3.** Le coût en monnaie et les limites de 5 h et de 7 jours sont hors de cette vague (P74-D-20, P74-D-24).

## À Samuel

Questions qui ne bloquent rien : l'arbitrage en vigueur tient et le plan est bâti dessus.

- **S-1 — Persister les cibles réduites dans l'index ?** AUDC-Q2 borne l'index à « heures, durées, jetons et
  verbes ». Le radar de la Phase 75 a besoin des cibles d'écriture (chemin relatif au lab). En vigueur : cibles en
  mémoire seulement, reconstruites au démarrage par une passe de fond sur 24 h (le radar est incomplet pendant
  quelques secondes après un démarrage). Options : (a) garder ainsi ; (b) persister la cible réduite, même classe que
  « verbe et cible réduite » (P69-D-16). Recommandation : (a), le coût est faible et rien n'est rouvert.
- **S-2 — Coût par phase au-delà de 24 h (Phase 77) ?** En vigueur : la fenêtre de 24 h vaut pour l'index ; le coût par
  phase et par étage se calcule sur ces 24 h. Options : (a) garder ainsi ; (b) un agrégat persisté par phase, étage et
  modèle (jetons et durées, sans heure par agent) au-delà de 24 h. Recommandation : (a) pour cette vague, (b) à
  instruire avec la Phase 77 si le coût sur 24 h ne répond pas à la question.
- **S-3 — Une écriture dans un worktree hors du dossier du lab est-elle « hors du lab » ?** CKPT-22 dit « jamais un
  chemin hors du lab ». En vigueur : oui, elle devient « un fichier hors du lab » ; le radar de la Phase 75 ne voit pas
  ces worktrees. Options : (a) garder ainsi ; (b) un worktree du même dépôt compte comme le lab, la cible restant
  relative à sa racine (aucun chemin absolu). Recommandation : (b), aucun chemin du poste ne sort et le radar devient
  complet ; à confirmer par Samuel, l'arbitrage en vigueur tient d'ici là.

<decisions>
## Implementation Decisions

Toutes « décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée », sauf mention.
Aucune ne vaut arbitrage de Samuel.

- **P79-D-01 (contrats).** Les sections C0 à C6 sont figées ; un écart se consigne ici en amendement daté.
- **P79-D-02 (route d'état).** Enveloppe `cockpit-state@1` autour d'un `cockpit-signal@1` inchangé : la Phase 73 et
  `vf-signal` gardent leurs lecteurs.
- **P79-D-03 (index).** C1 : cache du lab, non fiable à la lecture, un seul écrivain, 24 h, sans cible.
- **P79-D-04 (cibles).** En mémoire seulement (arbitrage AUDC-Q2 en vigueur) ; question S-1.
- **P79-D-05 (coût).** Sur la fenêtre de 24 h (arbitrage AUDC-Q2 en vigueur) ; question S-2.

</decisions>

<canonical_refs>
## Canonical References

- `.planning/research/2026-11-10-audit-cockpit-etude.md` § 3, § 7, § 8.2, § 9
- `.planning/research/2026-11-10-audit-cockpit/REGISTRE.md` (lignes absorbées, § 3, § 5.1, constats nés du lot 0)
- `.planning/research/2026-11-10-audit-cockpit/DESIGNS.md` § 2, § 4, § 9 ; annexes `A1`, `A2`, `A3`, `A6`
- `.planning/missions/2026-11-11-audit-cockpit-lot-0.md` (Décisions, Limites, Fichiers par sous-lot)
- `.planning/workstreams/fiabilite/phases/VFDO-67-cockpit-floorplan-socle-partage/67-CONTEXT.md` (P67-D-02, D-06, D-14)
- `.planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-CONTEXT.md` (P69-D-16, D-18, D-19, D-22, D-23, D-27)
- `plugin/cockpit/scripts/vf-cockpit-interface.json`, `plugin/cockpit/README.md` § « Interface du socle pour `vf-signal` »

</canonical_refs>
