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
  | `rattachement` | `{ dag, noeud, source: "registre" \| "mandat" }` \| null | nœud du plan de mission (AUDC-I37) |
  | `cibles` | `{ etat: "ok" \| "en-construction", ecritures: [{cible, n, dernierMs}] (≤ 200), lectures: [...] (≤ 200) }` | **en mémoire seulement**, reconstruites au démarrage par une passe en tâche de fond sur la fenêtre ; cible réduite (C0) |

- **Hors de la frise :** les commits (Git, routes `/api/vf/git*`), le fil daté d'un agent (route existante
  `/api/vf/transcript`, `cockpit-transcript@2`), le coût en monnaie et les limites de 5 h et de 7 jours (ligne d'état,
  Phase 74).
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
