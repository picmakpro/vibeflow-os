# Phase 72: Lancer du travail depuis les cartes du cockpit - Context

**Gathered:** 2026-11-05
**Status:** Cadrée (2026-11-05) — non planifiée

Cadrage par le manager de la mission Phase 72 (`vf-dev-manager`, worktree `.claude/worktrees/phase-72`, branche
`feat/phase-72-lancer-depuis-cartes`, base `aff9f260`). Jalon `vibeflow-v2.0`, compartiment `fiabilite`. Sources :
`69-CONTEXT.md` P69-D-19 et P69-D-21 (vision de Samuel, citée au bloc Phase 72 du ROADMAP) ; `71-CONTEXT.md`
(P71-D-01 à P71-D-37, TERM-01 à TERM-12) ; `72-RESEARCH.md` (commit `c13b078b`) ; panel de sécurité sur le canal
carte → terminal (manager, 2026-11-05, options A à E, recommandation reprise en P72-D-09).

**Exigences :** LANC-01 à LANC-12. Préfixe propre à la phase, vérifié libre sur `origin/main` et sur toutes les
branches locales et distantes le 2026-11-05.

<domain>
## Phase Boundary

Quand le cockpit tourne avec `--terminal`, les cartes de phase et de mission de l'onglet Projet portent une action
« Lancer ». Un clic n'exécute rien : il PROPOSE. La proposition passe par le serveur du cockpit jusqu'au terminal du
tiroir, qui affiche la cible, la commande exacte, les pré-vols (ce qui bloque, ce qui mérite un avertissement) et le
choix du mode de permission. La commande n'est écrite dans le shell qu'après un geste de l'utilisateur DANS le
terminal, et seulement si le shell est au repos. La session lancée est un `claude` interactif à la racine du lab, avec
son `CLAUDE.md`, ses skills et VibeFlow ; elle est suivie par son identifiant de session jusqu'à l'onglet Équipe. En
option, elle reprend la conversation du chat du cockpit.

**Hors périmètre :** un bouton global dans l'en-tête (l'en-tête appartient à la Phase 78) ; « Reprendre » sur les cartes
de l'onglet Équipe ; le calcul du travail non commité (porté par la Phase 78, repris par la 72 plus tard, P72-D-07) ;
plusieurs sessions de terminal ; un lancement en arrière-plan sans terminal ; Windows ; toute modification des jetons
d'espacement, paddings et valeurs de palette (Phase 71.5) ; toute route qui agit sur Git (la Phase 78 est en lecture
seule).
</domain>

<decisions>
## Implementation Decisions

### Arbitrages de Samuel (AskUserQuestion, session principale Claude Code, 2026-11-05, relayés mot pour mot au manager)

- **P72-D-01 (Q1, où tourne la session ; arbitrage Samuel, AskUserQuestion, session principale Claude Code, 2026-11-05).**
  « Terminal au repos seulement (Recommandé) ». La ligne n'est écrite que si le premier plan du PTY est le shell
  (`tcgetpgrp(maître) == pid du shell`). Un programme au premier plan (`claude`, un build, `vim`) : refus avec un message
  clair, 0 octet écrit.
- **P72-D-02 (Q2, mode de permission ; arbitrage Samuel, AskUserQuestion, session principale Claude Code, 2026-11-05).**
  Réponse libre, mot pour mot : « choix + hérité don bypass ». Lecture confirmée par le manager : le bandeau propose
  `default`, `acceptEdits`, `plan` ET « hérité du poste » (aucun drapeau `--permission-mode`, donc le `defaultMode` de
  l'utilisateur, qui peut valoir `bypassPermissions`). La règle « bypassPermissions jamais depuis une carte » du panel
  est levée par cette réponse.
- **P72-D-02bis (Q2bis, présélection du mode ; arbitrage Samuel, AskUserQuestion, session principale Claude Code,
  2026-11-05).** Mot pour mot : « Le dernier mode choisi ». Le mode est retenu dans le terminal ; au premier lancement,
  c'est `default`. Samuel a tranché en connaissant le risque du détournement de clic, que la question lui exposait
  (mode hérité présélectionné = agent sans demande de permission sur une cible de la liste). Les parades de P72-D-14
  (délai d'armement, Entrée au clavier) restent dues dans tous les cas. La mémorisation vit dans le stockage de
  l'origine Q seulement (comme le secret, P71-D-13) : jamais lisible ni écrivable par la page P, ni transmise par l'IPC,
  ni dans un cookie ; valeur relue contre la liste fermée (valeur inconnue = `default`). Point d'audit obligatoire.
  *Précisé par P72-D-20 (support de la mémorisation : un fichier du lab tenu par le processus de Q, non plus le stockage du navigateur).*
- **P72-D-03 (Q3, contexte du chat ; arbitrage Samuel, AskUserQuestion, session principale Claude Code, 2026-11-05).**
  « Option « continuer le chat » ». Le bandeau offre, quand une conversation du chat existe, de la poursuivre dans la
  session lancée (`claude -r <id> --fork-session`). Livrée SEULEMENT après une sonde qui prouve qu'une session du chat
  reprise en interactif retrouve ses outils et ses réglages complets (hypothèse A5 de `72-RESEARCH.md`) ; sonde rouge =
  option non livrée et remontée à Samuel, jamais livrée dégradée.
- **P72-D-04 (Q4, cartes ; arbitrage Samuel, AskUserQuestion, session principale Claude Code, 2026-11-05).** « Cartes
  phase et mission de Projet (Recommandé) ».
- **P72-D-05 (Q5, actions ; arbitrage Samuel, AskUserQuestion, session principale Claude Code, 2026-11-05).** « Une
  action principale + menu (Recommandé) ». L'action principale suit l'état de la phase (Cadrer → Planifier → Exécuter →
  Vérifier) ; les autres verbes de la liste fermée sont dans un petit menu.
- **P72-D-06 (Q6, pré-vols ; arbitrage Samuel, AskUserQuestion, session principale Claude Code, 2026-11-05).** « Bloquer
  l'impossible, avertir le reste (Recommandé) ». Bloquants : phase finie, terminal absent ou arrêté, premier plan occupé,
  `claude` introuvable, phase ou compartiment hors motif, `python3` absent. Avertissements : dépendance non close
  (heuristique de prose), mission vivante sur la phase (verrou de driver), phase plus avancée dans un autre worktree,
  lancement récent de la même cible.
- **P72-D-07 (Q7, arbre sale ; arbitrage Samuel, AskUserQuestion, session principale Claude Code, 2026-11-05).** « La 78 le
  porte, la 72 le reprend (Recommandé) ». Précision de la session principale : le cadrage de la 78 (réponse E1 de Samuel)
  lui donne tout l'affichage Git, travail non commité compris. La 72 ne calcule pas l'arbre sale ; elle prévoit l'emplacement
  d'un avertissement « travail non commité » alimenté plus tard par la donnée de la 78.

### Décisions d'ordonnancement (session principale, 2026-11-05 — pas des arbitrages de Samuel)

- **P72-D-08 (R1 à R3).** R1 : cadrer et planifier maintenant ; exécuter ce qui touche `vf-cockpit-terminal-tiroir.mjs`
  après le merge de `chore/cloture-71-inversion-terminal`, puis rebaser ; ce qui n'y touche pas peut partir avant.
  R2 : la 78 est en lecture seule (décision D1 de Samuel sur la 78) ; le mécanisme des routes POST du serveur P est à la
  72 seule. R3 : aucune valeur de style en dur, seulement les variables CSS existantes ; la 71.5 refait la palette.

### Décisions techniques du manager (vf-dev-manager, 2026-11-05, sur mesures ; à vérifier par l'audit, ADR-031)

- **P72-D-09 (« la page propose, le terminal dispose » ; amende P71-D-15).** La page P peut être pilotée par une charge
  injectée via les données du lab (toute route de P est appelable avec le jeton de page, `serve.mjs:508-514`). Donc un
  clic sur une carte ne fait que PROPOSER un couple `{verbe, cible}` ; aucun texte libre. P71-D-15 devient : « P peut
  proposer une cible de la liste fermée par le serveur, jamais exécuter ; Q n'a toujours aucun écouteur `message`
  propre et ne lit toujours aucun paramètre d'URL hors thème ».
- **P72-D-10 (canal : IPC serveur, pas l'URL du cadre ni `postMessage`).** Chemin : P → `POST` sur le serveur P → IPC
  parent → enfant Q (qui existe, `vf-cockpit-terminal-processus.mjs:4-5`) → proposition en attente exposée par Q dans
  `GET /etat` ou un `GET /proposition` → bandeau dans Q. Écartés : le paramètre d'URL (recharge le cadre et rejoue le
  tampon, classe du défaut R1 de P71-D-36) et le `postMessage` (rouvre un écouteur dans Q, T-71-34). Une seule
  proposition en attente à la fois ; une nouvelle remplace l'ancienne ; elle expire (durée fixée au plan) et est consommée
  à l'usage ou à l'annulation.
- **P72-D-11 (mécanisme POST de P, fichier neuf).** Le serveur P refuse aujourd'hui tout ce qui n'est pas GET
  (`vf-cockpit-server.mjs:70`). La 72 pose un mécanisme POST unique dans un fichier neuf : `Host` exact, `Origin` exacte de
  P obligatoire, jeton de page comparé en temps constant, `Content-Type: application/json`, corps borné, schéma fermé,
  table de routes POST explicite (une seule route à ce stade). Branchement minimal recensé. Témoin rouge sur mutant
  pour chaque contrôle.
- **P72-D-12 (liste fermée, dérivée du disque par le serveur).** Le serveur P calcule les cibles lançables à partir de
  SES lectures (graphe Projet, avancement v2, verrous par `driver-lock.sh status --all` du module, worktrees) et les
  transmet à Q par l'IPC. Q valide la proposition contre cette liste ; malformée ou absente : aucun bandeau, 0 octet au
  PTY. Jamais de liste venue de la page.
- **P72-D-13 (gabarit fermé, aucun texte du lab dans le shell).** La ligne est un gabarit constant dont les seules
  variables sont : numéro de phase `^\d+(?:\.\d+)?$`, compartiment à motif fermé (hors motif = refus, jamais un nom
  « nettoyé »), verbe d'une liste fermée, mode de permission d'une liste fermée, UUID de session généré par le serveur,
  identifiant de session du chat validé UUID. Jamais le titre, le Goal, un nom de mission ou de nœud. Chaque argument
  entre guillemets simples ; la ligne entière revalidée par un alphabet fermé dans le serveur ET dans l'assistant Python
  avant écriture. Le contexte riche, s'il en faut, passe par fichier (`--append-system-prompt-file`, 0600, création
  exclusive, effacé), jamais par la ligne.
- **P72-D-14 (double geste dans Q, parade au détournement de clic).** Le bouton « Lancer » du bandeau n'est armé qu'après
  un court délai d'affichage (valeur au plan). Il écrit la ligne au shell SANS retour chariot : l'utilisateur la voit à
  l'invite et appuie lui-même sur Entrée. Une ligne en attente à l'invite est vidée seulement si le premier plan est le
  shell.
- **P72-D-15 (forme du prompt, PROVISOIRE jusqu'à la sonde de vague 0 — tranchée par P72-D-19).** Intention en français, construite par le
  gabarit (par exemple « Cadre la Phase 72 du compartiment fiabilite »), passée au head par la forme que la sonde prouve
  (`'/vf-dev <intention>'` en prompt initial, ou `--agent`, ou intention nue). Jamais une commande `gsd-*` dans le
  prompt (doctrine du head). Lancement à la racine du lab ; VibeFlow crée son propre worktree selon sa doctrine.
- **P72-D-19 (forme du prompt, DÉFINITIVE ; décision du manager, vf-dev-manager, 2026-11-05, sur la sonde de vague 0).**
  Mesures (Claude Code 2.1.318, projet témoin, PTY) : un skill passé en prompt initial interactif se déclenche
  (`claude --permission-mode acceptEdits '/temoin72'`, marqueur en 7,9 s) et reçoit ses arguments par `$ARGUMENTS`
  (`'/temoin72 phase 72 cadrer'`) ; `--agent <nom>` incarne aussi un agent ; `--session-id <uuid4>` écrit
  `~/.claude/projects/<slug>/<uuid>.jsonl` SEULEMENT si `CLAUDE_CODE_CHILD_SESSION` est absent de l'environnement ;
  `--append-system-prompt-file` est accepté en interactif (absent de `--help`, cité seulement sous `--bare`) ; une chaîne
  passée par variable entre guillemets doubles n'est pas développée. Retenu : `claude --session-id '<uuid>' -n '<nom>'
  [--permission-mode '<mode>'] '/vf-dev <intention>'`, le nom exact du skill tel qu'exposé par l'installation (nu ou
  préfixé du plugin) étant une constante du gabarit, vérifiée par une suite. Obligations qui en découlent : l'environnement
  du shell est déjà privé de `CLAUDE_CODE_*` (P71-D-03) — un témoin le vérifie, sans quoi le suivi P72-D-16 est muet ;
  la boîte « faire confiance à ce dossier » d'un lab jamais ouvert apparaît dans le terminal et reste à l'utilisateur
  (écrit au README). Artefacts de la sonde : scratchpad de la mission, `sonde72/` (hors dépôt).
- **P72-D-16 (suivi).** `--session-id <uuid>` et `-n` construit des seuls identifiants ; la carte montre « lancée » et
  se rattache à la session de l'onglet Équipe (`vf-cockpit-who.mjs`, P69-D-22) ; un second lancement de la même cible
  dans la fenêtre de récence est averti (P72-D-06).
- **P72-D-17 (sans `--terminal`, rien ne change).** L'interface de lancement est servie à la volée seulement avec le
  drapeau, comme le tiroir (P71-D-20) : sans lui, CSP de page octet pour octet identique, aucun bouton, aucune route
  POST, aucun script ajouté. Pas de repli « copier la commande » (motif ClickFix relevé par le panel).
- **P72-D-18 (fichiers neufs, branchement minimal).** Tout le code vit dans des fichiers neufs (`vf-cockpit-lancer*.mjs`,
  suites `test-cockpit-lancer-*.sh`) ; les points de branchement dans des fichiers existants sont listés et minimaux
  (serveur P : route POST ; tiroir : ouvrir et afficher l'état ; processus/client/vue de Q : proposition et bandeau ;
  assistant PTY : premier plan et revalidation). Recensés dans `72-BRANCHEMENTS-MERGE.md`.
- **P72-D-20 (support du mode retenu ; arbitrage Samuel, AskUserQuestion, session principale Claude Code, 2026-11-06 ; précise
  P72-D-02bis).** Mot pour mot : « Fichier du lab (Recommandé) ». Option présentée : le processus du terminal garde le dernier
  mode dans un petit fichier du lab, non suivi par git ; il ne le sert qu'à l'origine du terminal, jamais à la page Projet ; il
  revalide la valeur contre la liste fermée (`default` si elle est inconnue) ; le mode survit aux relances du cockpit. Coût
  accepté : un petit plan de plus, avec témoins et audit (plan 72-16). Motif : Q écoute sur un port tiré au hasard
  (`q.listen(0, …)`, `vf-cockpit-terminal-processus.mjs`), donc le stockage du navigateur de l'origine Q est perdu à chaque
  démarrage du cockpit, et P72-D-02bis (« le dernier mode choisi ») n'était pas tenu d'une relance à l'autre. La règle de
  P72-D-02bis « jamais lisible ni écrivable par la page P » reste entière.
  *Amendé par AUDC-B-05 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 : « Le ranger hors du projet (Recommandé) ») : le support est le dossier d'état du poste, projet par projet, et non plus un fichier du lab ; une archive reçue ne peut plus apporter de présélection. Le reste de P72-D-20 et de P72-D-02bis tient (9b58a6c6).*
- **P72-D-21 (reprise du chat : geste humain exigé ; arbitrage Samuel, AskUserQuestion, session principale Claude Code, 2026-11-06 ; précise
  P72-D-03, constat d'audit F-1).** Mot pour mot : « Geste humain exigé (Recommandé) ». L'identifiant de conversation n'est retenu que si la
  question au chat a été envoyée par un vrai geste humain dans la page (activation utilisateur du navigateur), avec un témoin XSS qui tente la
  reprise forgée et doit échouer, puis ré-audit. L'option reste dans la phase. Mise en oeuvre : `navigator.userActivation.isActive` lu au
  moment de l'appel à la fonction de requête (garde `garde:activation`), échec fermé si l'API est absente. Résiduel accepté en clair par Samuel :
  un script peut encore attendre le prochain geste réel de l'humain pour glisser sa question (pendant la fenêtre d'activation, mesurée par
  la suite XSS, manche ACT). Trace : `72-CORRECTIFS-D.md`.
  Renvoi : remplacée sur le résiduel par P72-D-22.
- **P72-D-22 (reprise du chat : résiduel du POST direct accepté ; arbitrage Samuel, AskUserQuestion, session principale Claude Code,
  2026-11-06 ; remplace P72-D-21 comme arbitrage sur le résiduel).** Mot pour mot : « Garder, risque écrit (Recommandé) ». Constat qui a motivé
  la nouvelle question : la garde d'activation de P72-D-21 ne ferme que le chemin par l'interface. Un script qui s'exécute dans la page Projet
  peut lui-même envoyer à `POST /api/vf/lancer` un identifiant `chat` de forme valide, issu d'une conversation qu'il a écrite ; la seule
  barrière réelle est le clic et l'Entrée dans le terminal. Décision : « continuer le chat » reste tel quel. Le README et l'audit disent
  qu'un script qui s'exécute dans la page Projet peut proposer la reprise d'une conversation qu'il a écrite, que la case est décochée par
  défaut, que l'identifiant est affiché dans la ligne quand la case est cochée (mesure RES.2/RES.2b), et que rien ne part sans le clic et l'Entrée dans le terminal. La fenêtre d'activation de la page Projet (garde `garde:activation`, environ 5 s) s'ouvre aussi sur un geste réel dans le cadre du terminal, pas seulement dans la page (mesuré par l'audit du lot 3, 2026-11-06). Le correctif 2b9e23b9 (activation
  utilisateur) reste, au titre de l'honnêteté du chemin normal, non de la protection contre un script de la page. Options écartées : B'
  (date et première question affichées dans le terminal) et D (reporter). Témoin de caractérisation, à ne jamais lire comme une protection :
  manche RES de `test-cockpit-lancer-xss.sh`. Surface voisine, hors phase : `.planning/BACKLOG.md`, entrée sur `POST /api/ask`.

### Contraintes héritées (Phases 67 et 71)

- Le serveur n'exécute aucun script du lab ; `driver-lock.sh` est résolu dans le module, jamais sous le lab.
- Aucun secret ni jeton vers le SSE, `serveur.log`, l'export ou une réponse HTTP (TERM-03).
- Toutes les protections de la 71 restent : contrôles de Q (P71-D-10, P71-D-24), canal Q → P à liste fermée
  (P71-D-18), bandeau de collage, une seule session.
</decisions>

<requirements>
## Exigences (LANC-01..12)

Chacune porte un témoin rouge joué avant le code (sur un mutant ou sur la base), puis vert sur le code livré.

- **LANC-01** Cartes : avec `--terminal`, les cartes de phase et de mission de l'onglet Projet portent une action
  principale selon l'état et un menu des autres verbes de la liste fermée (P72-D-04, P72-D-05).
- **LANC-02** Sans `--terminal` : CSP de page identique octet pour octet, aucun bouton, aucune route POST (P72-D-17,
  TERM-01).
- **LANC-03** Route POST de P : Host, Origin exacte, jeton en temps constant, `Content-Type`, corps borné, schéma
  fermé ; témoins : Origin tierce, Origin absente, Origin de Q, mauvais jeton, corps trop long, champ inconnu → refus et
  0 proposition (P72-D-11).
- **LANC-04** Liste fermée : une cible malformée (`72;touch M`, `$(touch M)`) ou bien formée mais absente de la liste du
  serveur → aucun bandeau, 0 octet au PTY, aucun marqueur (P72-D-12).
- **LANC-05** Gabarit : avec un lab de test dont le titre de phase vaut `"; touch M #` et `<img src=x onerror=…>`, la
  ligne écrite est exactement le gabarit, dans l'alphabet fermé ; titre affiché par `textContent` ; 0 violation CSP,
  0 marqueur ; mutant qui interpole le titre → rouge (P72-D-13).
- **LANC-06** Premier plan : programme témoin au premier plan, confirmation → 0 octet reçu par le programme et message
  clair ; mutant sans contrôle → rouge (P72-D-01).
- **LANC-07** Double geste : aucune écriture sans clic dans Q ; clic avant le délai d'armement ignoré ; ligne écrite
  sans `\r` ; la charge XSS de `test-cockpit-terminal-xss.sh` (proposition, `iframe.click()`, `postMessage`, popup)
  ne crée aucun marqueur (P72-D-14, TERM-12).
- **LANC-08** Pré-vols : chaque bloquant de P72-D-06 empêche le lancement avec son motif ; chaque avertissement
  s'affiche sans bloquer ; emplacement « travail non commité » prévu, inactif (P72-D-06, P72-D-07).
- **LANC-09** Mode de permission : le bandeau propose `default`, `acceptEdits`, `plan` et « hérité » ; « hérité » =
  aucun drapeau ; présélection = dernier mode choisi, retenu dans le stockage de l'origine Q, `default` au premier
  lancement ou si la valeur retenue est hors liste ; témoins : P ne peut ni lire ni écrire ce choix (`SecurityError`
  mesuré), une valeur forgée dans le stockage de Q retombe sur `default` (P72-D-02, P72-D-02bis).
- **LANC-10** Suivi : `--session-id` généré, la carte montre « lancée » et rattache la session de l'onglet Équipe ;
  proposition consommée une seule fois (un rechargement ou une bascule de thème ne la fait pas revenir) (P72-D-16,
  P72-D-10).
- **LANC-11** Continuer le chat : option offerte seulement si une conversation existe et si la sonde de P72-D-03 est
  verte ; identifiant validé UUID (P72-D-03).
- **LANC-12** Usage réel et non-régression : de bout en bout dans Chromium avec un faux `claude` dans le PATH (suites),
  puis avec le vrai `claude` (recette par juges, captures) ; toutes les suites du cockpit vertes sous macOS et Linux.
</requirements>

<canonical_refs>
## Canonical References

- `72-RESEARCH.md` (ce dossier) — carte du code, chemins:lignes, pré-vols disponibles, CLI vérifiée, zones grises.
- `.planning/workstreams/fiabilite/phases/VFDO-71-terminal-integre-cockpit/71-CONTEXT.md`, `71-SECURITY.md`,
  `71-BRANCHEMENTS-MERGE.md` (modèle du recensement).
- `plugin/cockpit/scripts/vf-cockpit-terminal-processus.mjs` (IPC), `vf-cockpit-terminal-client.mjs`,
  `vf-cockpit-terminal-vue.mjs` (bandeau de collage, modèle du bandeau), `vf-cockpit-terminal-tiroir.mjs`,
  `plugin/cockpit/skills/cockpit-moteur/terminal/vf-cockpit-pty.py` (`groupes()`, `tcgetpgrp`).
- `plugin/cockpit/scripts/vf-cockpit-server.mjs` (l.70, refus non-GET), `vf-cockpit-project.mjs`,
  `vf-cockpit-avancement.mjs`, `vf-cockpit-vie.mjs`, `vf-cockpit-who.mjs`.
- `plugin/cockpit/skills/cockpit-moteur/assets/serve.mjs` l.480-600 et `plugin/cockpit/amont/SYNCHRO.md`.
- `plugin/dev-orchestrator/skills/vf-dev/SKILL.md` (entrée du head).
- `DESIGN.md`, direction « Graphite » : variables CSS existantes seulement.
</canonical_refs>
</content>
</invoke>
