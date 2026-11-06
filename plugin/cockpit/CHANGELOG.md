# Changelog — cockpit

## v1.4.0 — 2026-11-06 — non publié

Parseurs tolérants du planning et diagnostic des lignes non comprises (constat du lab portfolio, 2026-11-05 : « **Depends on :** Phase 02 (…) » ne donnait aucun lien dans le graphe Projet). Arbitrage : Samuel, AskUserQuestion en session principale, 2026-11-05 — hotfix et chantier de fond traités ensemble, release minor.

### Corrigé — dépendances (hotfix)
- `**Depends on :**` (espace, U+00A0 ou U+202F avant « : »), deux-points dans le gras ou dehors, gras ou non, puce « - », casse, `Dépend de` / `Dépendance(s)` / `Dependency` / `Dependencies` / `Depends` : lus. Les coupures existantes (« · », champ gras suivant, « La Phase 68 en dépend ») sont intactes. Valeur portée par les puces qui suivent : lue.

### Ajouté — normalisation partagée (`vf-cockpit-formats.mjs`, module pur)
- Une grammaire commune à la lecture (`vf-cockpit-planning.mjs`) et au diagnostic (`vf-cockpit-drift.mjs`) : titres de phase (`##`, `###`, `####`, `Phase N:`, `Phase N :`, `Phase N —`, 01 = 1, décimales, gras autour du titre), cases `[ ]` `[x]` `[X]` avec puces `-` `*` `+`, `Goal` / `Objectif` / `Objective`, exigences `**REQ-01**:` `**REQ-01:**` `REQ-01:`, statut STATE normalisé (« In Progress » → `in_progress`), `current_phase` entre guillemets ou « Phase 2 », CRLF et BOM.
- La case « - [x] Phase 3 - Trois » ou « **Phase 2 — Deux** » (tiret au lieu des deux-points) est lue, état coché compris (arbitrage Samuel, AskUserQuestion session principale, 2026-11-06).
- **Limite assumée** : la tolérance des titres est large (`##` à `####`, tiret) ; un intertitre de prose « ### Phase N — … » est donc lu comme une phase (arbitrage Samuel, AskUserQuestion session principale, 2026-11-06).
- Coût linéaire : 100 000 espaces dans une ligne ne coûtent plus des secondes (lecture et diagnostic). Les puces qui suivent un « Depends on » vide se lisent avec ou sans ligne vide ; une dépendance répétée ne donne qu'un lien. STATE.md en CRLF/BOM est lu comme en LF (jalons-absents).

### Ajouté — diagnostic « lignes non comprises »
- Règle `ligne-non-comprise` (niveau « ignoré », une par ligne, jamais de correctif proposé ; « Depends on Phase 3 » sans deux-points est signalée, jamais lue ; un mot-clé collé à un trait d'union comme « goal-backward » n'est pas un champ) dans `vf-cockpit-drift.mjs` : une ligne qui ressemble à un champ lu (titre de phase, Goal, Depends on, case d'exigence, `current_phase`) sans qu'aucun lecteur la reconnaisse. Prose libre, tables, plans et blocs de code ne sont jamais signalés.
- Sortie du build : « N ligne(s) non comprise(s) du planning : fichier:ligne … », au premier assemblage et à chaque `build --rebuild`. Panneau « Lignes du planning non comprises » dans l'interface (20 premières lignes, fichier:ligne sans coupure et extrait). Le cockpit n'écrit toujours rien dans `.planning/`.
- Suites : `test-cockpit-projet.sh` P8 (matrice générée de 980 variantes, deux mutants), `test-cockpit-assemblage.sh` A6.

## v1.3.3 — 2026-11-05 — non publié

Réglage visuel (demande de Samuel, session principale, 2026-11-05) : tiroir fermé, la pastille « Terminal » se place sous les boutons de zoom (− ▢ +), au plus bas à gauche, et les boutons de zoom remontent au-dessus d'elle ; plus de chevauchement. Tiroir ouvert, rien ne change. Vaut pour les pages Projet et Code.
- **Placement** : `vf-cockpit-terminal-tiroir.mjs` ne remonte plus la pastille ; si elle recouvre `#zoom`, c'est `#zoom` qui reçoit un `bottom` en ligne juste au-dessus d'elle (retiré à l'ouverture du tiroir, à chaque recalcul). La puce « Terminal indisponible » garde l'ancienne règle.
- **Suite** : `test-cockpit-terminal-tiroir.sh` (T21.1) exige désormais, quand la pastille et le zoom se partagent la même colonne, la pastille sous le zoom, en plus du non-chevauchement ; le mutant `M-PASTILLE-SUR-ZOOM` vise la nouvelle ligne.

## v1.3.2 — 2026-11-05 — non publié

Correctif hors phase (jalon vibeflow-v2.0, compartiment fiabilité) : le terminal intégré fonctionne sous Safari. Arbitrages : arbitrage Samuel, AskUserQuestion session principale, 2026-11-05 (SAF-1 « connexion dans le cadre », SAF-2 « les deux preuves »).

### Corrigé — « Session expirée » sous Safari (SAF-1)
- **Cause** : Safari découpe le `localStorage` d'un cadre par origine de premier niveau, port compris (Chrome et Firefox par site, port ignoré). Le terminal échangeait l'amorçage au premier niveau et y rangeait le secret ; le cadre du terminal sous la page Projet (autre port) lisait un stockage vide.
- **L'échange se fait dans le cadre** : la page de redirection du lanceur mène à `http://127.0.0.1:<port>/project.html#t=<amorçage>`. La page Projet lit le fragment avant tout autre traitement, l'efface, n'en retient que le format exact (64 chiffres hexadécimaux), monte le cadre du terminal au chargement (tiroir fermé) avec l'amorçage dans le fragment de son adresse (jamais dans un attribut `src`). Le cadre efface son fragment, fait `POST /amorce`, range le secret dans son stockage et se recharge sans fragment ; il ne navigue plus vers la page Projet. Le shell ne démarre qu'à l'ouverture du tiroir (le cadre attend une taille non nulle).
- **Renforcé** : une adresse du terminal ouverte seule avec un amorçage n'échange plus rien (« Terminal indisponible »). Propriétés inchangées : pas de cookie, secret jamais dans une adresse ni lisible par la page Projet, usage unique, 60 s, `Origin` exacte.
- **Limites écrites au README** : le script de la page Projet voit passer l'amorçage (jamais le secret) moins de 60 s ; sous Safari le stockage du cadre est effacé à la fermeture du navigateur (relancer `/vf-cockpit --terminal`).
- **Suites** : `test-cockpit-terminal-lanceur.sh` (L6, L12b, L12c, L15, M-OUVRE-Q), `-client.sh` (T6.1, T6.1b, T6.1c, T6.3, T6.9, mutants M-STOCKAGE, M-PREMIER-NIVEAU, M-SANS-AMORCE), `-tiroir.sh` et `-xterm.sh` (amorçage par la page Projet) jouent le nouveau contrat.

## v1.3.1 — 2026-11-05 — non publié

Correctif hors phase (jalon vibeflow-v2.0, compartiment fiabilité) : le terminal intégré ne laisse plus de survivants quand son assistant PTY plante.

### Corrigé — survivants après le plantage de l'assistant PTY
- **Un gardien ramasse la session** : si l'assistant `vf-cockpit-pty.py` meurt sans passer par `arreter()` (SIGKILL, SIGSEGV, exception Python non rattrapée), les travaux qui ignorent le SIGHUP du noyau (`nohup … & disown`, `(trap '' HUP; exec sleep) &`) restaient rattachés à `ppid=1`. Un petit processus gardien, forké avant le pseudo-terminal (il ne détient jamais le maître), sorti de la session par `setsid`, détecte la fin du tube sans le mot `OK` de l'arrêt propre, puis rejoue SIGHUP, la grâce de 3 s et le SIGKILL répété sur les membres de la session (getsid relu avant chaque envoi). Il sort dès que la session est vide. Limites écrites dans l'en-tête du module : un gardien tué lui-même laisse les survivants, un processus sorti de la session par `setsid` y échappe.
- **Suite `test-cockpit-terminal-pty-plantage.sh`** : T12.8a (SIGKILL) et T12.8b (exception injectée dans une copie) au vert, témoins T12.8c sains, deux mutants (`M-GARDIEN-ABSENT`, `M-GARDIEN-SANS-SID`) qui rougissent T12.8a avec les survivants `nohup` et `trap`. Aucun changement de comportement hors de ce ramassage.

## v1.3.0 — 2026-11-04 — non publié

Phase 71 : terminal intégré. Décisions : arbitrages Samuel, AskUserQuestion session principale Claude Code, 2026-11-03,
pour P71-D-01 à P71-D-08 et P71-D-23 ; décisions du manager (vf-dev-manager, 2026-11-03) pour P71-D-09 à P71-D-22 et P71-D-24
(O1 à O11 tranchées par P71-D-20 et P71-D-21 ; P71-D-22, d'abord provisoire, est devenue définitive par P71-D-23). Les gestes de
release racine (version, tag, release GitHub) restent humains. Numéro de version recalculé à la fusion avec les Phases 68 et 70 (P71-PL-12) : mineure suivante de la v1.2.1 de main.

### Corrigé — recette par juges, lots W1 à W4, et rebase sur H-1
Arbitrages de Samuel, AskUserQuestion session principale Claude Code, 2026-11-04 : P71-D-33 (« Terminal dans son processus (Recommandé) »), P71-D-34 (« Corriger E2 à E5 (Recommandé) »), P71-D-35 (« G1 tiroir et cadrage, G2 arrêt immédiat, G3 défilement discret »).
- **Le serveur du terminal tourne dans son propre processus** (E1, P71-D-33) : un travail synchrone du serveur (le calcul de qui travaille sur le lab) gelait les frappes ; Q est désormais un enfant (`child_process.fork`, `vf-cockpit-terminal-processus.mjs`), l'interface exportée par `vf-cockpit-terminal.mjs` et le patch `P26` de `serve.mjs` sont inchangés. Si le serveur du cockpit meurt, même par SIGKILL, l'enfant, l'assistant et le shell s'arrêtent avec lui.
- **Arrêt volontaire dit, Python 3 absent dit** (G2, E4, P71-D-34 et D-35) : `GET /etat` rend `{"etat":"arret"}` pendant environ 2,5 s après un arrêt volontaire et `{"etat":"indisponible","raison":"python3-absent"}` sans `python3` (autres routes 503, une ligne dans `serveur.log`). La page affiche « Serveur arrêté » aussitôt, ou une carte « Terminal indisponible » avec la marche à suivre, sans boucle de reconnexion ; une coupure inattendue garde la reconnexion pendant 30 s.
- **Lanceur** (E4, E5) : sans `python3`, `--terminal` le dit et le cockpit s'ouvre sans terminal (code 0) ; il attend le serveur jusqu'à 30 s (au lieu de 10) et dit « démarrage lent » après 5 s ; le code 5 ne vient qu'au-delà.
- **Tiroir** (E2, G1) : la pastille ne recouvre plus les boutons de zoom ; tiroir ouvert, la carte s'arrête au-dessus du tiroir (« Ajuster » et le cadrage en tiennent compte, ouvrir, fermer ou régler le tiroir recadre la carte), la barre de question se range, la visite guidée se ferme.
- **Page du terminal** (E3, G3) : le nombre de lignes de la grille se calcule sur la hauteur utile du cadre, la dernière ligne ne déborde plus ; la barre de défilement n'apparaît qu'au survol ou pendant un défilement.
- **Rebase sur H-1 (v1.1.2)** : le `PATH` assaini de `vf-cockpit-env.mjs` remplace les variantes N2 de `vf-cockpit-build.mjs`, `-live.mjs`, `-planning.mjs` et `-who.mjs` ; `gitCommonDir` tient N2 et H-1 ensemble. Le shell du terminal garde le `PATH` d'origine du lanceur, transporté par `VF_COCKPIT_PATH_ORIGINE` (limite : un serveur lancé hors du lanceur donne au shell le `PATH` assaini). Le patch du terminal est renuméroté `P26` (le `P25` est celui de H-1). Le moteur d'assemblage reçoit le repli `/usr/bin:/bin:/usr/sbin:/sbin` (et non plus `/usr/bin:/bin`) quand plus rien n'est sûr. Ceci remplace les phrases du tour D qui disaient H-1 renvoyée à un mandat séparé.

### Corrigé — tour de correction E de la Phase 71 (N9, N10)
- **Collage d'une ligne invisible ou de contrôle d'affichage confirmé** (N9 ; P71-D-30, arbitrage Samuel, AskUserQuestion session principale
  Claude Code, 2026-11-04 : « Corriger avant la PR (Recommandé) ») : xterm réordonnait visuellement le texte bidi, `echo hello<U+202E>; touch m; `
  s'affichait à l'envers et Entrée exécutait `touch m`. Une ligne portant un caractère de la classe Cf (bidi, zéro largeur), un caractère Tag ou
  un contrôle C0/C1 ouvre désormais le bandeau « Annuler / Coller », par la même définition que le marquage ⟨U+XXXX⟩ de l'aperçu.
- **Collage confirmé : ce qui est confirmé est visible** (N10 ; même arbitrage) : les suites d'au moins trois lignes vides ou blanches sont
  repliées à l'affichage (⟨N lignes vides⟩), un avertissement dit quand l'aperçu dépasse sa zone ; le texte envoyé reste l'original (sha256).

### Corrigé — tour de correction D de la Phase 71 (N8, N11, documentation)
- **Un `PATH` assaini vide n'est plus transmis au moteur d'assemblage** (N8, régression de N2 ; P71-D-29, arbitrage Samuel, AskUserQuestion, session
  principale Claude Code, 2026-11-04 : « le lanceur n'exécute jamais un binaire du lab ») : sans `PATH` ou avec un `PATH` entièrement relatif
  (`env -i`, `PATH=.`), Node posait `PATH=''` et libuv le lisait comme le dossier courant, donc le `git` du lab était exécuté (6 fois pendant
  `build`). Le moteur reçoit désormais `/usr/bin:/bin` (sous Windows, la clé est omise).
- **File d'entrée du terminal** (N11) : un morceau vide est retiré sans envoi ; il bouclait en POST vides (plus de 20 000 en 300 ms).
- **Sans `ps`, le refus d'arrêt est dit une seule fois** (au lieu d'une centaine pendant l'attente du terminal).
- **Documentation** : le README dit que le lanceur n'exécute jamais un binaire par son nom mais que le serveur vendorisé et le moteur ne sont pas assainis (H-1,
  mandat séparé) ; le docstring de l'assistant PTY dit la vraie garantie de `killpg` après le réapage du chef.

### Corrigé — dernier tour de mineurs de la Phase 71 (lot C)
- **Chaque branche d'arrêt de l'assistant tue la session** (M1) : sortie du shell, SIGTERM et fin du descripteur 0 portent chacune une
  assertion avec un `nohup` ; un relevé de processus qui ne contient pas l'assistant (`/proc` vide) vaut « impossible » et déclenche le
  repli sur les groupes (M2) ; un zombie n'est plus un membre vivant (M3) ; le PID du chef de session n'est plus signalé une fois le chef
  réapé (N4).
- **Fermeture bornée** (M3, N5) : au-delà de la borne de fermeture, le serveur escalade en SIGKILL sur l'assistant et rend la place ; le
  README dit la vraie borne (8 s au pire, la grâce de 3 s en pratique).
- **Saisie découpée** (M4, N6c) : jamais de corps de plus de 64 Kio sur l'entrée, une grosse saisie part en tranches dans l'ordre ; un 413
  réduit la tranche puis, à un octet, s'écrit dans le terminal, jamais silencieux.
- **Ouverture du terminal annoncée** (M6, N6b) : l'erreur asynchrone de l'ouvreur est rattrapée ; si l'amorçage n'est pas échangé dans les
  15 s, le lanceur le dit avec la page à ouvrir à la main ; limite Linux écrite au README (P71-D-27 inchangée).
- **Aucune trace au lanceur** (N6a) : un lien symbolique planté sur le chemin de sortie, serveur réutilisé, sort en code 4 avec un message.

### Corrigé — audit de sécurité de la Phase 71 (lot B1 : lanceur et amorçage)
- **Le lanceur n'ouvre plus une adresse lue dans le lab** (F1, majeur ; P71-D-25, validation de Samuel, AskUserQuestion, session
  principale Claude Code, 2026-11-04) : seuls des ports entiers sont lus dans `server.json`, l'adresse est reconstruite en
  `http://127.0.0.1:<port>`, et seulement si le processus est le serveur de la sortie ; un `server.json` planté ne remet rien à l'ouvreur.
- **L'amorçage n'est plus dans l'argv de l'ouvreur** (F6 ; P71-D-27, validation de Samuel, même canal, 2026-11-04) : page de redirection
  0600 en création exclusive, dont seul le chemin est remis à l'ouvreur, supprimée à l'échange et balayée à 60 s ; l'amorçage expire
  60 s après sa création, côté serveur. Limite résiduelle : lisible d'un processus du même compte pendant 60 s au plus.
- **Documentation alignée** (README) : Q n'a aucun écouteur `message` propre, le vendor xterm en garde un interne (F5, P71-D-15
  reformulée) ; réponses de format fixe d'xterm réinjectées (F8).
- **Limite signalée (B1-1)** : un `server.json` planté qui désigne un processus vivant étranger fait sortir `open` et `stop` en code 5
  tant qu'il n'est pas supprimé ; marche à suivre au README.

### Corrigé — audit de sécurité de la Phase 71 (lots B2 et B3)
- **Arrêt de toute la session du terminal** (S1 ; P71-D-28, validation de Samuel, AskUserQuestion, session principale Claude Code,
  2026-11-04) : SIGHUP puis SIGKILL à chaque membre de la session relevé à l'arrêt ; `nohup`, `disown` et `&` sont tués ; un
  processus sorti par `setsid` (ou double fork + `setsid`) survit ; repli sur les groupes si ni `/proc` ni `ps` ne sont lisibles.
- **`python3` résolu en chemin absolu** (F3 ; P71-D-25) : seuls les éléments absolus du `PATH` sont consultés, un `python3` du lab
  n'est jamais exécuté ; un élément absolu du `PATH` situé dans le lab reste consulté (limite). Le `PATH` du shell est inchangé.
- **Le lanceur n'exécute jamais un binaire du lab** (N2 ; P71-D-29, validation de Samuel, AskUserQuestion, session principale Claude Code,
  2026-11-04) : lancé depuis la racine du lab, sous un `PATH` à élément relatif ou vide (`.`, `:` en tête ou en queue, `bin`), il exécutait un
  `open`, `xdg-open`, `ps` ou `git` posé dans le lab. `open`, `xdg-open`, `ps`, `git` et `bash` sont maintenant résolus en chemin absolu dans
  les seuls éléments absolus du `PATH` ; le moteur d'assemblage reçoit un `PATH` assaini ; le serveur n'ouvre plus le navigateur lui-même
  (le lanceur le fait, y compris sans `--terminal`). Binaire introuvable : échec dit en clair, jamais un repli sur le dossier courant. Le
  `PATH` du shell du terminal est inchangé (P71-D-03).
- **Collage confirmé** (F2 ; P71-D-26, même canal, même date) : un collage ou un dépôt à retour à la ligne ou caractère de contrôle
  n'atteint le shell qu'après « Coller » dans un bandeau « Annuler / Coller » ; Échap annule, Tab puis Entrée valide, aucune touche de
  confirmation directe exprès ; une ligne simple passe.
- **Collage confirmé : aperçu intégral** (correction N1 ; P71-D-29, arbitrage Samuel, AskUserQuestion session principale Claude Code,
  2026-11-04) : le bandeau montrait 200 caractères coupés par une ellipse alors que « Coller » envoyait tout. Il montre désormais le texte
  intégral (zone défilante, texte seulement, décompte de lignes et de caractères), les caractères invisibles ou de contrôle d'affichage en
  marqueur ⟨U+XXXX⟩ ; le texte envoyé reste l'original ; une coupure d'affichage (au-delà de 20 000 caractères) est dite et levable.
- **Terminal limité à son cadre** (F4 ; P71-D-25) : un popup ou une ouverture seule de la page du terminal affiche « Terminal
  indisponible » (ni secret lu, ni flux, ni shell).
- **Police attendue au premier chargement** (2,5 s au plus) avant de mesurer la grille ; pastille du tiroir à 44 px sur écran tactile.

### Ajouté — Terminal intégré (Phase 71)
- **`--terminal`** — le lanceur ouvre un shell de votre compte dans un tiroir en bas des pages Projet et Code, dans la même
  fenêtre : `$SHELL -l` dans la racine du lab, `claude` y tourne avec son `CLAUDE.md` et ses skills (P71-D-01, D-03, D-04, D-06,
  D-08). Désactivé par défaut : sans le drapeau, aucun port, aucune route, aucun tiroir, politique de contenu de la v1.0.x
  (P71-D-02).
- **Second serveur d'une autre origine** (`127.0.0.1`, port éphémère) rendu dans un cadre ; sortie par `fetch` en flux, entrées
  par `POST`, pas de WebSocket (P71-D-09) ; `Host`, `Origin` et secret contrôlés sur chaque requête (P71-D-10, P71-D-24).
- **Amorçage à usage unique** (fichier 0600 effacé à l'échange, fragment d'adresse effacé), secret de session dans le stockage de
  la page du terminal, jamais de cookie (P71-D-11 à D-13).
- **Assistant PTY en Python standard** lancé isolé (`python3 -I`), redimensionnement, Ctrl-C ; une session, grâce de 30 s,
  tampon de reprise de 256 Kio en mémoire ; `TERM=xterm-256color` et `COLORTERM=truecolor` posés toujours (P71-D-05, D-06,
  D-23). Windows : indisponible (P71-D-07).
- **xterm.js 6.0.0 et addon-fit 0.11.0 vendorisés** (MIT, sha256, licences), aucun addon presse-papiers, séquences OSC 52,
  OSC 8, DCS et DECRQSS neutralisées (P71-D-16) ; canal de la page du terminal vers la page Projet limité à une liste fermée de
  valeurs fixes (P71-D-18) ; thème par paramètre d'adresse (P71-D-19).
- **Patch amont `P26` de `serve.mjs`** (`vibeflow P26`, diff dans `amont/patches/`), `AJOUT` des fichiers xterm et de l'assistant
  dans `VENDORED.txt`.
- **Suites** : `test-cockpit-terminal-activation.sh`, `-serveur.sh`, `-pty.sh`, `-session.sh`, `-page.sh`, `-client.sh`,
  `-tiroir.sh`, `-xterm.sh`, `-xss.sh`, `-lanceur.sh` (dix suites) ; `test-cockpit-chaine-xss.sh` et `test-cockpit-vendor.sh`
  étendues.

### Limites connues
- Voir la section « Limites connues » du README : limite de fond (votre compte, dépôt potentiellement hostile, extensions de
  navigateur), processus détachés, reprise du plein écran, déni de service du cadre par la page Projet, Windows, Safari et Firefox
  non mesurés.

## v1.2.2 — 2026-11-04

Phase 70 : finitions de l'interface. Décisions : P70-D-01 à P70-D-07 et P70-D-16, arbitrages Samuel, AskUserQuestion session principale,
2026-11-03 ; P70-D-09, P70-D-10, P70-D-13, P70-D-20 et P70-D-21, choix du manager (pas des arbitrages de Samuel) ; P70-D-19, arbitrage de
méthode de Samuel, session principale Claude Code, 2026-11-04 (recette jouée par des juges qui prennent des captures). Pas de release racine.

### Corrigé
- **Français** : plus d'anglais résiduel ni de coquille dans le chrome (« clic droit », « Dans … », « Mis à jour il y a … », « d'equipe-… », « 1 fichier de code »),
  fil d'Ariane sans doublon, durées et textes de la visite jamais coupés.
- **« Où en est-on ? »** sans `STATE.md` : réponse construite des seuls champs présents, plus de statut brut (`ready_to_execute`) affiché.
- **Couleurs de statut** du thème clair : suivent le thème, contrastes d'au moins 4,5:1 (mesurés de 6,07 à 7,01:1 en clair).
- **Visite** : texte entier, « Passer » à chaque étape, centrage de la première étape stable au rechargement, grandes cartes cadrées, contour de l'étape sur un élément du chrome.
- **Onglet Équipe** : badge d'état dans sa carte, « non rattaché » sur une ligne, boutons au style du tiroir (sans toucher aux boutons du viewer), champs en paragraphes,
  lien « Nœud » distinct, titre sans recouvrement de la première carte, focus clavier gardé sur « Lire le transcript » et « Voir la dernière commande » après redessin.

### Modifié
- **Téléphone** : en-tête sur une rangée avec menu « ⋯ », zoom en pile verticale à gauche, tiroir à poignée, croix et titre cliquable, onglets à 13 px / 3 px (390 px).
- **Visite de l'onglet Projet** : propre au projet (jalon, phase, mission, « au travail »), sans mention de code.
- **Zoom de l'onglet Équipe** : en bas à gauche dès 701 px (P70-D-20).

### Limites
- Onglets à 12 px / 2 px à 1 024 et 1 440 px (R13.4 rouge, six lignes) : arbitrage de Samuel en attente.
- Carte Session « en attente » avec badge « En cours » (défaut de la Phase 69, au BACKLOG).
- Tri de goût (12 questions) en attente de Samuel : `70-RECETTE-JUGES.md`.

## v1.2.1 — 2026-11-04

Correctif : l'onglet Projet voit les phases en cours dans des worktrees (N5 de la recette de la Phase 68). Arbitrage Samuel,
AskUserQuestion session principale Claude Code, 2026-11-04 : « Correctif juste après la 68 (Recommandé) ». Pas de release racine.

### Corrigé
- **Phases menées dans un worktree** : la carte Projet (et la vue macro du jalon, et les phases de `signal@1`) lisait le ROADMAP et les dossiers de phase
  de l'arbre courant seulement ; une phase en exécution dans `.claude/worktrees/phase-70` s'affichait « À faire · pas de plan ». Elle prend désormais l'avancement
  du worktree (état, décompte de plans, reste) et la carte le dit : « dans worktree phase-70 ». Nouveau module `vf-cockpit-ailleurs.mjs`.
- **Règle de priorité** : l'état le plus avancé gagne (à faire < en cours < à recetter) ; un état clos sur l'arbre courant reste clos ; une clôture lue
  seulement dans un worktree vaut « à recetter » ; à égalité l'arbre courant garde la main.
- **Rien sous le lab** (P68-D-34) : les fichiers d'un worktree sont lus, jamais exécutés, et chaque lecture est confinée à la racine réelle de son arbre
  (`lireConfine`) : un lien symbolique sortant n'est pas suivi. Git passe par `arbresGit` (préfixe sûr, environnement assaini).
- Suite `test-cockpit-ailleurs.sh` (témoin rouge avant, vert après ; priorités ; lien symbolique sortant, prouvé par mutation).

## v1.2.0 — 2026-11-04

Phase 68 (vf-signal embarqué, socle partagé). Module monté seul ; le bump racine est reporté à la release groupée (P68-D-31 :
arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-04, « Module seul, racine groupée (Recommandé) »).
Publiée dans VibeFlow vX.Y.Z (mention à compléter par le geste de release groupée). Autres décisions : P68-D-08 et P68-D-21
(arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-03).

### Ajouté
- **Mod vf-signal embarqué** : pane terminal affichée par Claude Code, gatée (elle ne s'affiche que si `cockpit=` est posé), bouton
  « Ouvrir le cockpit ».
- **Émetteur `signal@1`** : état du travail publié pour la pane (mission vivante, retard sur la base, worktrees).
- **Socle partagé** : calcul de la vie d'une mission (`mission.vie`), lecture des arbres git (`arbresGit`) et émetteur, communs au cockpit et au mod.
- **Cascade de vie (P68-D-33)** : verrou de phase, puis verrou du compartiment, puis verrou de dépôt (et l'ancien `.planning/DRIVER.lock`) ;
  un verrou présent, même périmé, arrête la cascade (P68-D-27, P68-D-36), et la mission est `abandonnee` s'il est périmé ou si aucun
  verrou n'existe ; une source illisible donne `inconnu`.
- **Lanceur et repli de l'élagage (P68-D-34)** : le mod n'exécute aucun fichier du compte ou du plugin dont le chemin ou le realpath
  tombe sous le lab (la racine du plugin n'est refusée que sous `<lab>/.vibeflow`) ; lanceur pris dans le compte (`~/.claude/scripts`)
  puis dans le plugin, `driver-lock.sh` de l'élagage pris dans le plugin puis dans le compte. Un fichier existant dont le realpath est
  inconnu est refusé, et les lancements partent hors du lab avec un PATH assaini (P68-D-37).

### Modifié
- **`avancement@1` devient `avancement@2`** : états de mission `abandonnee` et `inconnu` et champ `mission.vie` (vocabulaire de mission
  fermé élargi) ; `who` lit les arbres par `arbresGit`.
- Corrections issues de la recette de la Phase 68 (revues du socle, du mod et du web).
- **Tiroir « Au travail »** : l'âge d'un verrou se retrouve par correspondance exacte sur la portée et le compartiment, plus par sous-chaîne
  (deux compartiments dont l'un est préfixe de l'autre, `fiabilite` et `fiabilite-2`, gardent chacun leur âge).
- **README de la pane** : règle de rafraîchissement (P68-D-41 : arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-04),
  coût remesuré, version vérifiée de Claude Code (2.1.318 ; non chargée sous 2.1.181, plancher exact non mesuré) et cockpit installé sans `conductor` (« état inconnu »).
- **Environnement des lancements du mod (P68-D-40, P68-D-42)** : le mod vide `VF_COCKPIT_SCRIPTS_DIR`, `NODE_OPTIONS`, `BASH_ENV` et `ENV`
  dans l'environnement de ses lancements (émetteur, lanceur du cockpit, élagage), pour que rien sous le lab ne s'exécute par leur biais.
- **Cadence (P68-D-41)** : pane fermée, le bandeau peut afficher un état vieux d'une minute ou plus ; une horloge qui recule compte comme une minute échue
  (FND-3), et le minuteur de 10 s est annulé avant d'être reposé (FND-4).

### Retiré
- Lecture maison du planning par le mod (remplacée par le socle partagé).
- Couleurs « Signal » du mod.
- Bloc backlog de la vue macro.

## v1.1.2 — 2026-11-04

Correctif de sécurité H-1 (héritée de la Phase 67, présente dès v2.75.0), sur arbitrage de Samuel (AskUserQuestion, session
principale Claude Code, 2026-11-04 : « Mandat séparé maintenant (Recommandé) »). Pas de release racine.

### Corrigé
- **Outils du lab exécutés par le serveur** : le serveur et ses modules appellent des outils par leur nom (`which`, `claude`, `git`, `bash`,
  puis `awk`, `tr`, `ps` par `driver-lock.sh`). Avec un `PATH` contenant `.`, un élément relatif ou vide (que libuv lit comme le dossier
  courant), ou un dossier du lab, un programme piégé posé dans le lab s'exécutait à leur place.
- Un seul utilitaire, `vf-cockpit-env.mjs` (`assainirPath`, `envEnfant`) : retire du `PATH` tout élément vide, relatif ou situé sous le lab
  (lien symbolique résolu), avec le repli `/usr/bin:/bin:/usr/sbin:/sbin` si plus rien ne reste. Il s'applique à l'environnement de chaque enfant
  (`git`, `bash`, `ps`, moteur de construction, serveur détaché du lanceur) et, par le patch P25 de `serve.mjs`, au processus du serveur
  lui-même (donc à `which`, `claude --version`, l'agent et l'ouverture du navigateur). Le `PATH` du shell de l'utilisateur n'est jamais modifié.

### Ajouté
- `test-cockpit-path-enfants.sh` : l'utilitaire (U), les fonctions du module (F), le serveur (S) et le lanceur (L) lancés depuis un lab dont les
  outils sont piégés, avec `PATH=.:…`, un `PATH` relatif, vide et absolu sous le lab. Rouge avant le correctif (outils du lab exécutés), vert après.

## v1.1.1 — 2026-11-04

Correctifs de la recette de la Phase 69, sur arbitrage de Samuel (AskUserQuestion, session principale Claude Code,
2026-11-04 : « « Dépend de » faux, Verrou « Driver libre », Contraste « En cours », Pied caché, ligne anglaise »). Pas de release racine.

### Corrigé
- **« Dépend de »** : la valeur de `Depends on` perd ses parenthèses, ses identifiants `Pnn-D-nn` et tout ce qui suit la première phrase ;
  une phase dépendante (« La Phase 68 en dépend ») ou le 10 de `P69-D-10` ne sont plus lus comme des dépendances.
- **Verrou « Driver libre »** : le script du conductor voisin (`…/plugin/conductor/scripts`) passe avant la copie de `~/.claude/scripts`,
  qui peut dater d'avant les verrous par phase ; la copie installée ne sert plus que de repli.
- **Contraste des statuts** : `--st-active` et `--st-blocked` suivent le thème (`--sev-medium`, `--sev-high`) au lieu de `#f59e0b` et `#ef4444` en dur ;
  le texte des pastilles est teinté vers `--text` (au moins 4,5:1 dans les deux thèmes) ; `--text-1`, qui n'existait pas, devient `--text`.
- **Pied des cartes de phase** : lisible au zoom d'ouverture d'un jalon (pied agrandi, description masquée à ce niveau).
- **Export de l'onglet Code** : « Ce qui vient de changer, et pourquoi. » remplace la ligne anglaise.

## v1.1.0 — 2026-11-03

Phase 69 : suivi du travail en cours. Décision du bump : arbitrage Samuel, AskUserQuestion session principale,
2026-11-03 (P69-D-26, « Bump v1.1.0 »). Les gestes de release racine (version, tag, release GitHub) restent humains.

### Ajouté
- **État d'avancement dérivé des phases** (CKPT-13 à CKPT-18) — « à faire », « en cours », « à recetter », « fait », calculé
  depuis les plans et leurs SUMMARY ; plans de correction comptés à part ; missions rattachées à leur phase ; contrat `avancement@1`.
- **Équipe en arbre avec historique de 24 h** (CKPT-19, CKPT-20, CKPT-27, CKPT-28) — session -> manager -> workers, terminés
  repliés ; forme des sous-agents de Claude Code mesurée (2.1.317) et stricte (`forme-inconnue` plutôt qu'un mensonge) ;
  contrat `vibeflow/cockpit-who@2` (remplace `@1`) et `vibeflow/cockpit-equipe@1`.
- **Onglet « Équipe »** (CKPT-23) — troisième onglet, page `/equipe.html` servie en mémoire, mise à jour en place.
- **Dernière action lisible et lien vers le nœud de mission** (CKPT-21, CKPT-22) — table fermée de verbes (libellés provisoires) ;
  un agent non rattaché dit pourquoi.
- **Transcript à la demande** (CKPT-24 à CKPT-26) — réduit au mandat, aux messages et à la liste des outils, masque des
  secrets au mieux, route `GET /api/vf/transcript` authentifiée, jamais dans le flux, les fichiers, le journal ni l'export,
  garde d'émission lue du contrat et fermée par défaut ; contrat `vibeflow/cockpit-transcript@1`.

### Modifié
- Forme Claude Code étendue et mesurée (fenêtre de 24 h, aucune lecture hors fenêtre).
- Onglets resserrés pour tenir à trois dans l'en-tête (borne `.hl` 264 -> 280 px) ; retour aux valeurs d'origine en Phase 70 (P69-D-28).

### Limites
- Masque des secrets au mieux sur la prose des mandats et des messages ; jeton lisible par tout processus local : risque accepté
  (P69-D-27, arbitrage Samuel, AskUserQuestion session principale, 2026-11-03).

## v1.0.2 — 2026-11-03 — non publié

### Ajouté
- **Verrous de phase dans « qui est au travail »** : `vf-cockpit-who.mjs` affiche `compartiment <sujet> phase <N>` et lit le
  registre des agents de chaque phase tenue (`orphans --ws --phase`). Règle de Samuel, session principale, 2026-11-03.

## v1.0.1 — 2026-11-03

Publiée dans VibeFlow v2.75.1.

### Corrigé
- **ROADMAP écrit à la française lu par l'onglet Projet** — `Phase N : nom` (espace avant les deux-points, insécable
  comprise) était ignoré : le lab Scroll-Off n'affichait aucune phase de son jalon en cours (constaté le 2026-11-03).
  La ligne `**Depends on**: rien · **Parallélisable avec**: Phase 4` ne crée plus de dépendance à la Phase 4 ;
  `## Jalons` vaut `## Milestones`, `**Objectif**` vaut `**Goal**`, `**Dépend de**` vaut `**Depends on**`.

### Ajouté
- **Détection de dérive de format avant la lecture** (`scripts/vf-cockpit-drift.mjs`) — quatre règles
  (`phases-illisibles` bloquant, `phase-deux-points` et `depends-on` tolérés, `jalons-absents` et
  `phase-courante-absente` en info). Le panneau d'ensemble de l'onglet Projet les affiche dans une section « Format de
  la planification » (`meta.vf.drift`). `--diff` propose un correctif au format unifié vers le gabarit GSD, jamais
  écrit sur disque : on le relit puis on l'applique avec `git apply` (ADR-031). Suite `test-cockpit-projet.sh` (P6.1 à P6.14, dont les mineurs F1 à F5 de la relecture adverse SOBR-04).

## v1.0.0 — 2026-11-01

Première version du module (publiée dans VibeFlow v2.75.0). Décisions : arbitrages Samuel,
AskUserQuestion session principale, 2026-11-01.

### Ajouté
- **Socle partagé à interface versionnée** (P67-D-12) — collecteur « au travail », lecture de la planification, verrou et
  chemins du lab ; schémas `vibeflow/cockpit-*@1` consignés dans `scripts/vf-cockpit-interface.json`, destinés à `vf-signal`.
- **Moteur d'affichage vendorisé et rejouable** (P67-D-07, P67-D-11) — copie du moteur floorplan v0.6.0 @ 92d6854 (MIT)
  sous `skills/cockpit-moteur/`, patchs listés dans `VENDORED.txt`, procédure de synchro hors réseau (`amont/SYNCHRO.md`).
- **Marque blanche par renommage de la sortie** (P67-D-03, P67-D-04) — aucune mention du produit amont dans ce que voit
  l'utilisateur ; logo et favicon VibeFlow.
- **Cloud retiré, aucun appel sortant hors l'agent** (P67-D-02) — la fonction Cloud du moteur est retirée, le test réseau
  enregistre 0 connexion sortante.
- **Serveur unique avec direct et repli** (P67-D-13, P67-D-16) — flux d'événements, surveillance récursive de `.planning/`
  avec repli par scrutation, anti-rebond et hystérésis.
- **Dernière commande masquée** (P67-D-14) — jamais diffusée ; révélée à la demande dans la page.
- **Questions locales et agent confiné, modèle réglable** (P67-D-08, P67-D-15) — réponses calculées sur place pour les
  formes courantes, sinon `claude -p` confiné (mesure `67-MESURE-claude-p.md`) ; `sonnet` par défaut, liste fermée,
  `VF_COCKPIT_MODEL` et sélecteur de la page.
- **Onglet Code conditionnel** (P67-D-17) — extracteur VibeFlow sur un lab à modules, architecture brute ailleurs.
- **Verbe `/vf-cockpit`** (P67-D-05) — skill de classe utilisateur (`open`, `build`, `stop`, `status`), pour tous les
  postes (P67-D-01) ; aucun fichier sous `plugin/commands/`.
- **Sortie sous `.vibeflow/cockpit/`** (P67-D-06) — ignorée par git, ce dossier compris.
- **Chrome en français, test d'inventaire qui rougit** (CKPT-09, P67-D-03, P67-D-18) — dictionnaire (deux fichiers `assets/ui/78` et `79`), gabarits à variables, motifs et fonction pure `window.__vfFrTraduire` (`80-vf-fr.js`) ; inventaire déterministe des chaînes anglaises du rendu servi (`vf-cockpit-fr-inventaire.mjs`) comparé au dictionnaire, aux gabarits, aux motifs et aux exclusions justifiées (`vf-cockpit-fr-exclusions.json`) ; statuts de STATE affichés en français ; direction artistique du moteur conservée.

### Interface ajustable et corrections de la recette (correction B de la Phase 67, avant toute publication)
- **Fenêtre ajustable de 1 024 à 2 560 px** (CKPT-12, P67-D-21 ; demande de Samuel, message session principale, 2026-11-01) — en-tête en ligne souple
  (`assets/ui/01-vf-responsive.js`) : nom de projet tronqué avec une ellipse, recherche gardée à 200 px, boutons d'action en icône seule sous 1 600 px,
  barre de question sur une ligne, zoom au-dessus de la barre jusqu'à 1 279 px ; la règle de grille de `80-vf-fr.js` qui écrasait la recherche est retirée.
  Suite `test-cockpit-responsive.sh` (boîtes mesurées dans Chrome headless, redimensionnement à chaud, témoin rouge intégré).
- **Logo VibeFlow lisible** (il était inversé par le viewer : un tiret orange) ; titre d'onglet « <nom> — Code » ; export nommé « …-carte.html » (P20).
- **Lab sans `STATE.md`** : plus de « ? » ni de parenthèses vides dans le sous-titre et le panneau d'ensemble.
- **« Au travail »** : badge compact (le détail du verrou est dans l'infobulle et le panneau) ; les nœuds `running` de `.planning/missions/*.dag.json` sont lus ;
  la dernière commande d'une session très active est retrouvée (remontée jusqu'au dernier appel Bash, fenêtres jusqu'à 8 Mio : un gros résultat
  d'outil en dernière ligne rendait « Indisponible » et pouvait cacher la session) ; journal minimal authentifié `GET /api/vf/journal`.
- **Reconnexion à recul** (E-6, P21) : serveur arrêté, la page sonde une fois par seconde pendant 30 s, puis toutes les 5 s, puis s'arrête avec un message
  et « Réessayer » (un seul sondage pour les deux flux, au lieu de deux requêtes par seconde sans fin). Suite `test-cockpit-reconnexion.sh`.
- **Direct** : le résumé d'une carte de mission suit le statut de ses nœuds ; « Thinking… » traduit avant la peinture.

### Corrigé (recette humaine du 2026-11-02, avant toute publication)
- **En-tête à 1 024 px** (R8, R9) — la mise en page souris est conditionnée à `not (pointer: coarse)` au lieu de `(pointer: fine)` : Chrome headless sous Linux n'annonce aucun pointeur, la règle souris ne s'appliquait donc pas et l'en-tête restait dans la grille du viewer ; tests R8 et R9 ajoutés. Source : recette humaine du 2026-11-02.
- **« Voir la dernière commande »** (D3) — montre la dernière commande Bash de la session, plus le dernier message de l'assistant, et au plus le programme et son premier argument (« git push … »), programme seul si ce premier argument commence par `-`, contient `=` ou un caractère hors liste blanche (`redis-cli -a …`, `env DB_PASS=…`, `export KEY=…`, chaîne de requête `?key=…`, mot cité) ; liste blanche (lettres ASCII, chiffres, `_ . / : @ % + , ~ -`) à la place de la lecture des guillemets : une affectation de tête n'est sautée que si elle vaut `NOM=<mot simple ou vide>` ; un mot de tête qui n'est pas une telle affectation est le programme, et rend « … » s'il n'est pas simple ; la découpe en mots se fait sur espace, tabulation et retour à la ligne seulement (`\r`, `\f`, `\v` restent dans le mot, donc non simple) (vérifié sur 6 000 commandes générées, graine fixe). Limite acceptée : un secret passé en premier argument positionnel simple reste visible (`ls Secret99`, et surtout une URL ou un hôte en premier argument dont le jeton est dans le chemin ou dans l'userinfo (seul `schéma://utilisateur:mot-de-passe@` est masqué) ; ex. `curl https://api.telegram.org/bot<id>:<jeton>/getMe`, `curl https://<jeton>@hôte`, `curl user:pass@hôte`). Les masques `mysql -p` et `sshpass -p` sont conservés pour task/cwd/role (décision de Samuel, « N'afficher que le programme », AskUserQuestion session principale, 2026-11-02). Source : recette humaine du 2026-11-02.
- **Tiroir « Au travail »** (D2) — marge et hauteur ajustées. Source : recette humaine du 2026-11-02.
- **« Où en est-on ? » après une réponse de l'agent** (V1) — les formes courantes répondent sur place même une fois l'agent intervenu : la voie locale ne dépend plus de l'absence de session. Effet de bord arbitré : une relance qui dépend du fil et contient un mot de la voie locale reçoit la réponse locale (arbitrage Samuel, option A, AskUserQuestion session principale, 2026-11-02). Source : recette humaine du 2026-11-02.
- **Parcours « Trajectoire »** (D1) — à la dernière étape, le chevron « suivant » est inactif et il ne reste qu'une croix. Source : recette humaine du 2026-11-02.
- **Vue d'ensemble** (I2) — léger flou et fond translucide derrière le titre et le sous-titre. Source : recette humaine du 2026-11-02.
- **Mise à jour en direct** (I3) — la carte ne rejoue plus son animation d'apparition ; seules les cartes basculées clignotent. Source : recette humaine du 2026-11-02.
- **Types de carte en français** — « Library » et ses pairs sont traduits dans le chrome de l'onglet Code. Source : recette humaine du 2026-11-02.
- **Onglet Code, dossiers de `plugin/` sans `module.json`** — ils ont désormais leur nœud (kind infra, outillage) au lieu de tomber dans « non assigné » ; règle générique, sans liste de noms. Source : recette humaine du 2026-11-02 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-02).

### Corrigé (recette 3, 2026-11-03, avant toute publication ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-03)
- **« Voir la dernière commande » derrière un `cd`** (O1) — `cd <chemin> && git status` affichait « … » seul (ou « cd … ») alors que c'est la forme la plus fréquente : un `cd` simple (un seul mot simple, `&&` ou `;` en mot séparé ou collé à la fin du chemin) s'efface et la règle s'applique une fois à la commande qui suit (« git status ») ; le chemin du `cd` ne sort jamais, tout autre `cd` (chemin cité, `||`, option, second `cd`) rend « … ».
- **Port stable par lab, visite sans cookie** (O4, arbitrage Samuel, « C : port stable par lab (Recommandé) », AskUserQuestion session principale, 2026-11-03) — le cockpit d'un lab prend un port préféré dérivé de la racine réelle du lab (sha1, 100 valeurs à partir de 4378), le même à chaque lancement quel que soit l'ordre ; repli port+1 (20 essais) de `serve.mjs` en cas de collision. La marque « vue » de la visite « Par où commencer » reste en localStorage par lab (`vibeflow-cockpit:visite:<lab>`), l'origine étant désormais stable ; plus de cookie. Nouveau module `vf-cockpit-port.mjs`, variable de test `VF_COCKPIT_PORT_BASE`. Suites `test-cockpit-serveur.sh` (PS.*) et `test-cockpit-projet.sh` (O4).
- **Vue d'ensemble, matériau à la iOS** (I2, retour de Samuel, saisie texte, session principale, 2026-11-03 : « le flou sous le titre est trop dense, il faut aussi qu'il ai un radius fort en haut faible en bas, il doit etre comparable au blur iOS ») — `#context` : `blur(24px) saturate(1.8)` (la recette de `.glass`), fond à 30 % d'opacité (55 % avant), coins 22 px en haut et 6 px en bas, filet de lumière ; les deux thèmes. Source : `assets/ui/00-vibeflow.js`. **Reprise (avis de Samuel, Wispr Flow, session principale, 2026-11-03 : « pas de bordure, un flou dégradé qui part du haut gauche et descend, comme le header, en mode iOS 26 »)** : plus de carte, ni bordure, ni rayon, ni ombre ; `#context::before` porte un flou progressif (`blur(22px) saturate(1.6)`, fond `--bg-rgb` à 28 %) masqué par un dégradé radial ancré en haut à gauche (`mask-image` et `-webkit-mask-image`), plein derrière le début du titre, estompé vers le bas et la droite. **Seconde reprise (avis de Samuel, Wispr Flow, session principale, 2026-11-03 : « il y a un gap où il n'y a pas de flou entre le texte vue d'ensemble et le header […] allonger un petit peu le flou pour qu'il aille jusqu'au header »)** : la couche monte jusqu'au haut de l'en-tête, derrière lui (inset haut relatif à `--hh`, jamais une valeur calée sur une largeur), car le dégradé de l'en-tête s'estompe sur sa hauteur et laissait voir la carte nette entre les deux ; le masque (deux couches) garde l'aspect d'avant autour du titre.
- **Fil d'Ariane jamais rogné à tort** (O2, budget revu après la revue de la recette 3) — un segment de moins de 12 caractères (11 au plus) n'est jamais rogné ; la troncature commence par le milieu (segments longs, plancher de 64 px), puis le premier et le dernier ; si le fil déborde encore, les segments du milieu se replient derrière « … » (infobulle : leurs noms). Dès 1 280 px la colonne gauche prend sa largeur naturelle et la recherche cède la première (jamais sous 200 px), puis le nom du projet : plus aucun `min-width` dérivé de la largeur du fil, donc plus de bouton d'en-tête hors de la fenêtre à 1 280-1 320 px (revue F1/F2). Source : `assets/ui/01-vf-responsive.js`.
- **Italique rendu dans les réponses de l'agent** (O3) — `*…*` et `_…_` deviennent `<em>` après l'échappement, hors des spans de code ; bornes de mot : ni `a * b * c`, ni `snake_case_var`, ni `**/*.js`, ni `2*3*4`, ni liste à puces. Patch P23 de `viewer.html`.
- **Chevrons de la Trajectoire nommés** (O6) — « Étape précédente » / « Étape suivante » (aria-label et infobulle ; dictionnaire `78-vf-fr-dict-a.js`). Patch P23.

### Sécurité et robustesse (correction A de la Phase 67, avant toute publication)
- **Chaîne lab piégé -> XSS -> jeton -> exécution de code rompue à trois endroits** — échappement de tout champ du graphe (patch P16), Content-Security-Policy
  par empreintes avec `connect-src 'self'` et en-têtes `nosniff`/`DENY` (P17), « modifier le plan » durci : seuls `plan.mjs` et `build.mjs` du moteur du module
  s'exécutent, jamais un script désigné par un `.cache/` du lab (P15). Suite `test-cockpit-chaine-xss.sh` (navigateur headless, mutants).
- **Aucun script du lab exécuté** — plus de `driver-lock.sh` pris sous le lab, arrêt du serveur par signal sur un PID vérifié, aucune écriture ni lecture à travers un lien symbolique.
- **`claude -p` confiné aussi côté réglages** — `--setting-sources ""` (ni hooks du lab ou de l'utilisateur, ni règle `allow`) et `--strict-mcp-config`, mesurés.
- **Robustesse** — une question courante ne fait plus tomber le serveur, la page rechargée est à jour après un patch, verrou tenu visible en lab plat,
  lab sans code assemblé, masque des secrets étendu, corps JSON non objet refusé, `<!--` neutralisé, timeouts partout.

### Corrigé (relecture adverse SOBR-04 de v2.75.0, avant la publication ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-03, « Corriger maintenant »)
- **`--port` borné à 1024..65515** (65515 = 65535 − 20 essais de repli de serve.mjs : au-delà, le repli sortait de la plage, erreur avalée, serveur orphelin) (F1) — `--port 99999` lançait un serveur qui ne pouvait pas écouter, survivait sans `server.json` et échappait à `stop` ; le lanceur refuse maintenant tout port hors bornes (code 64) avant de lancer quoi que ce soit. Test `PS.12` de `test-cockpit-serveur.sh`.
- **Mode de question hors liste** (F2, patch P14) — `constructor`, `__proto__`, `toString` ou `hasOwnProperty` en `mode` lançaient l'agent avec `--json-schema undefined` ; seuls les modes propres de la table comptent, le reste retombe sur `ask`. Test `Q4b` de `test-cockpit-questions.sh`.
- **Ceinture `doing` éprouvée** (F3) — le refus d'émettre un objet portant une clé `doing` (flux et hello, à toute profondeur) n'était tué par aucune suite ; test `DO` de `test-cockpit-serveur.sh` (le serveur réel, le collecteur seul remplacé par un double).
