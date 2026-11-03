# Phase 71: Terminal intégré au cockpit - Context

**Gathered:** 2026-11-03
**Status:** Cadrée (2026-11-03) — non planifiée

Cadrage par le manager de la mission Phase 71 (`vf-dev-manager`, worktree `.claude/worktrees/phase-71`, branche
`feat/phase-71-terminal`, base `7370d604`). Jalon `vibeflow-v2.0`, compartiment `fiabilite`. Sources : `69-CONTEXT.md`
P69-D-19 (vision de Samuel, citée au bloc Phase 72 du ROADMAP), P69-D-20 (« Terminal intégré dans la page »), P69-D-21 ;
`67-SECURITY.md` (B2, M5, M7) ; `DESIGN.md` direction « Graphite » (PR #196, branche `docs/design-md`, pas encore mergée).

**Exigences :** TERM-01 à TERM-12. Préfixe propre à la phase : les Phases 68, 69 et 70 partent toutes de CKPT-28 en
parallèle, un CKPT-29+ entrerait en collision au merge (espace de noms vérifié libre sur `origin/main` et les trois branches
le 2026-11-03).

<domain>
## Phase Boundary

Le cockpit ouvre, quand on le lance avec `--terminal`, un vrai terminal dans un tiroir en bas des pages Projet et Code
(comme le panneau de VS Code), dans la même fenêtre. Le shell de l'utilisateur démarre à la racine du lab, de sorte que
`claude` y tourne normalement, avec le `CLAUDE.md` du projet et ses skills. Dessous, un second serveur local invisible,
d'une autre origine, isole le shell des données du lab affichées par le cockpit.

**Hors périmètre :** lancer du travail depuis les cartes (Phase 72), plusieurs sessions ou onglets de terminal, Windows,
tout changement du modèle de sécurité de la page Projet elle-même (la CSP de `v2.75.0` reste, seul `frame-src` s'ajoute).
</domain>

<decisions>
## Implementation Decisions

### Arbitrages de Samuel (AskUserQuestion, session principale Claude Code, 2026-11-03, relayés mot pour mot au manager)

- **P71-D-01 (isolation, Q1).** Premier tour, réponse libre : « Peu importe ce que je veux, c'est que ça soit dans la même
  page, c'est-à-dire que on puisse un peu comme dans VS code et fermer mais si c'est plus simple. […] il faut en tout cas que
  ça soit cool à utiliser donc qu'on puisse avoir un terminal dans ou au moins une session Claude code en fait qui est accès à
  tous les skills, qui soit qui est comme Racine, le projet avec le Claude. MD, etc. vraiment je veux que ça soit comme un
  terminal. Après dans l'idéal dans la même fenêtre, il faut pas qu'il y ait deux fenêtres jongler entre deux fenêtres parce
  que sinon bah faut juste ouvrir un terminal ça reviendrait à la même chose quoi tu vois ». Clarification : « Oui : même
  fenêtre, isolation invisible (Recommandé) ». Retenu : origine distincte (second serveur sur 127.0.0.1, autre port), rendue
  dans un cadre du tiroir. Exigences d'usage : une seule fenêtre, l'aspect d'un vrai terminal, `claude` utilisable à la
  racine avec ses skills et son `CLAUDE.md`.
- **P71-D-02 (activation, Q2).** « Désactivé, `--terminal` l'ouvre (Recommandé) ». Sans le drapeau : aucun port, aucune
  route, aucun tiroir.
- **P71-D-03 (shell, Q3).** Premier tour : « Ton shell, tout l'environnement ». Clarification : « Tout l'environnement, sauf
  ces variables (Recommandé) ». Retenu : `$SHELL -l`, avec tout l'environnement du serveur, MOINS `CLAUDECODE`,
  `CLAUDE_CODE_*` hérités, `VF_COCKPIT_*` et toute valeur de jeton du cockpit. Ce n'est PAS une liste blanche.
  `NODE_OPTIONS` n'a pas été évoqué : il passe (voir P71-D-14).
- **P71-D-04 (dossier, Q4).** « Racine du lab, puis libre (Recommandé) ». `cwd` = `realpath(lab)` au démarrage, `cd` libre.
- **P71-D-05 (sessions, Q5).** « Une, qui survit au rechargement (Recommandé) ». Une session par serveur, refus explicite
  au-delà ; survie au rechargement avec délai de grâce de 30 s et tampon de reprise de 256 Ko en mémoire seulement ;
  ensuite SIGHUP au groupe de processus ; tout est tué à l'arrêt du serveur.
- **P71-D-06 (PTY, Q6).** Premier tour, réponse libre : « Bonne question il faut que ça puisse agir comme un Shell comme pour
  le terminal ou powershell classique, l'impératif est que claudecode et VibeFlow doivent fonctionner normalement sur unix ».
  Clarification : « Oui, l'assistant Python (Recommandé) ». Retenu : assistant Python stdlib (`pty.fork`, redimensionnement
  par `ioctl TIOCSWINSZ` sur un canal de contrôle), le module garde `requires: []`. **Critère d'acceptation qui en découle** :
  `claude` (interface plein écran, couleurs, redimensionnement, Ctrl-C) et les commandes VibeFlow fonctionnent normalement
  dans le terminal sous macOS et Linux — en test ET en recette (TERM-09).
- **P71-D-07 (Windows, Q7).** « Hors périmètre de la 71 (Recommandé) ». Le terminal y est indisponible, message clair, aucun
  second serveur.
- **P71-D-08 (emplacement, Q7).** « Tiroir en bas de Projet et Code (Recommandé) ». Coût accepté : une directive `frame-src`
  dans la CSP de page de `serve.mjs`, ajoutée seulement quand le terminal est actif.

### Décisions techniques du manager (2026-11-03, sur mesures ; à vérifier par l'audit, ADR-031)

Appuis : panel de recherche (deux chercheurs, PTY/transport et modèle de menace) et spike Chrome headless 156 (dossier
scratchpad de la mission, rejouable ; résultats repris ci-dessous).

- **P71-D-09 (transport).** Pas de WebSocket : sortie par `fetch()` en flux (ReadableStream, octets bruts), entrées et
  redimensionnement par POST, sur le second serveur. Motif : l'événement `upgrade` de Node court-circuite les contrôles Host,
  Origin et jeton (classe de CVE-2023-26114, code-server) ; le jeton reste en en-tête, jamais dans une URL. Mesuré dans le
  cadre : médiane < 1 ms en boucle locale, 0 perte sur 50 POST, flux tenu 5,9 s.
- **P71-D-10 (contrôles du second serveur).** Sur CHAQUE requête : `Host` exactement `127.0.0.1:Q` ou `localhost:Q` ;
  `Origin` exactement l'origine du terminal (une Origin d'un autre port, même `127.0.0.1:P`, est refusée ; une requête sans
  Origin n'est admise que pour les GET de la page et des ressources statiques, jamais pour le flux ni les POST) ; jeton en
  en-tête comparé en temps constant. Aucun shell lancé avant l'authentification. Corps borné. Motif : le spike a montré qu'un
  POST `no-cors` de la page Projet atteint Q (seul le contrôle serveur l'arrête, F3).
- **P71-D-11 (jetons).** Un jeton d'amorçage à usage unique, généré par le lanceur et jamais servi par HTTP (ni P ni Q), ni
  écrit dans `serveur.log`, le flux SSE, l'export ou `server.json` en clair ; s'il transite par le disque : 0600 et effacé à
  la consommation. Échangé contre un secret de session propre au serveur Q (renouvelé à chaque démarrage du serveur).
- **P71-D-12 (amorçage dans la même fenêtre).** `--terminal` ouvre d'abord `http://127.0.0.1:Q/#t=<amorçage>` dans l'onglet ;
  la page Q consomme le jeton, efface le fragment (`history.replaceState`), range le secret de session, puis remplace
  l'adresse par la page Projet (`location.replace`). La page Projet ne voit jamais ni le jeton ni le secret.
- **P71-D-13 (rangement du secret).** Jamais de cookie : le spike (F1) mesure que les cookies ne sont pas cloisonnés par port,
  un cookie de Q est envoyé à P et lisible par `document.cookie` de P. Secret dans le `localStorage` de l'origine Q : partagé
  entre Q en premier niveau et Q encadré dans P (même site, pas de cloisonnement, mesuré F2), inaccessible depuis P
  (`SecurityError`, mesuré). Il ne vaut que pendant la vie du serveur.
- **P71-D-14 (`NODE_OPTIONS`).** Hors arbitrage de Samuel, il passe au shell comme le reste de l'environnement. Exception : si
  le lanceur ou le serveur du cockpit le posent eux-mêmes, on retire la valeur posée par le cockpit, jamais celle de
  l'utilisateur. Toute autre envie de le retirer remonte à Samuel.
- **P71-D-15 (frontière P → Q).** Q ignore tout `postMessage` et ne prend aucune configuration sensible dans son URL hors
  amorçage. P peut toujours renvoyer le cadre vers `about:blank` : déni de service accepté, écrit dans le README.
- **P71-D-16 (xterm.js).** `@xterm/xterm` 6.0.0 et `@xterm/addon-fit` 0.11.0, MIT, vendorisés (UMD) avec sha256 et
  licence ; `xterm.css` injecté dans un `<style>` (la CSP n'admet pas `'self'` pour les styles) ; scripts en `<script>` sans
  attribut (la regex d'empreintes de `pageCsp` ne voit que cette forme). Aucun addon presse-papiers (OSC 52). Les liens ne
  s'ouvrent que sur clic, en `noopener`.
- **P71-D-17 (fichiers neufs, branchement minimal).** La 69 modifie le cockpit en parallèle (`serve.mjs`,
  `vf-cockpit-server.mjs`, `VERSION`, `CHANGELOG.md`, `README.md`, `module.json`, suites `securite`/`serveur`/`reseau`).
  Tout le code de la 71 vit dans des fichiers neufs : serveur du terminal, assistant PTY, page du terminal, tiroir
  (`assets/ui/9x-vf-terminal.js`, chargé automatiquement par ordre de nom), suites `test-cockpit-terminal-*.sh`. Les points de
  branchement dans des fichiers existants sont listés et minimaux (drapeau du lanceur, démarrage du second serveur, port
  exposé à la page sous jeton, `frame-src` dans `pageCsp` + son patch amont, docs du module). Ils sont recensés pour le merge.

- **P71-D-18 (canal sortant Q → P, sur F1 de `71-UI-SPEC.md`).** Q peut envoyer à P des messages `postMessage` de valeur
  FIXE, tirés d'une liste fermée (sortie du focus clavier, état de la session pour la barre, Q joignable), avec `targetOrigin`
  exactement l'origine de P ; jamais un octet du shell, jamais un jeton ni un secret. P n'accepte que les messages dont
  `event.origin` est exactement l'origine de Q ET `event.source` le cadre, et dont la valeur est dans la liste. Le sens
  entrant P → Q reste fermé (P71-D-15). Motif : sans ce canal, un utilisateur au clavier reste piégé dans le terminal.
  À vérifier par l'audit (sonde : message hors liste ou d'une autre source ignoré ; aucune donnée du shell dans un message).
- **P71-D-19 (thème, sur F2 de `71-UI-SPEC.md`).** Le thème passe au cadre par un paramètre d'URL non sensible ; une bascule
  recharge le cadre, qui rejoue le tampon de reprise (256 Ko). Accepté : le sens P → Q reste fermé.

### Contraintes héritées (Phase 67, `v2.75.0`)

- Le lab observé n'est jamais une source de code : aucun script du lab exécuté par le serveur (le shell, lui, est l'usage
  voulu : il exécute ce que l'utilisateur tape).
- Les secrets ne sortent jamais vers le flux SSE, les fichiers générés, `serveur.log` ou l'export.
- `.cache/server.json` en 0600, hypothèse mono-utilisateur assumée (M7), désormais écrite pour le terminal aussi.

### Limite de fond (à écrire dans le README)

Le terminal, c'est votre compte, dans un dépôt potentiellement hostile : un prompt git, `direnv`, des hooks peuvent exécuter
du code du dépôt dès l'ouverture. Une extension de navigateur ayant accès à `http://127.0.0.1/*` lit et pilote toute page
locale. Le serveur ne peut fermer ni l'un ni l'autre.
</decisions>

<requirements>
## Exigences (TERM-01..12)

Chacune porte un témoin rouge joué avant le code (sur un mutant ou sur la base), puis vert sur le code livré.

- **TERM-01** Activation : sans `--terminal`, aucun second écouteur, aucune route ni tiroir terminal, la CSP de page est
  octet pour octet celle de `v2.75.0` ; avec, un second serveur sur `127.0.0.1` seulement, port distinct (P71-D-02).
- **TERM-02** Contrôles du second serveur : Host, Origin et jeton sur chaque requête, aucun shell avant authentification
  (P71-D-10). Témoins : Origin tierce, Origin `127.0.0.1:P`, Host de rebinding, sans jeton, mauvais jeton, jeton d'amorçage
  rejoué → refus et 0 PTY lancé.
- **TERM-03** Jetons jamais servis ni journalisés : 0 occurrence dans toute réponse HTTP de P et de Q, le SSE, `serveur.log`,
  l'export, `.vibeflow/cockpit/` (P71-D-11).
- **TERM-04** Amorçage dans la même fenêtre : fragment effacé, historique sans jeton, secret jamais en cookie, inaccessible
  depuis P (P71-D-12, P71-D-13).
- **TERM-05** Tiroir dans les pages Projet et Code, en cadre d'origine Q ; CSP de P = celle de `v2.75.0` + `frame-src`
  exact ; CSP de Q stricte (scripts par empreintes, `connect-src 'self'`, `frame-ancestors` = origines de P) ; 0 violation
  au fonctionnement normal (P71-D-08, P71-D-16).
- **TERM-06** Shell : `$SHELL -l`, `cwd` = `realpath(lab)`, environnement complet moins `CLAUDECODE`, `CLAUDE_CODE_*`,
  `VF_COCKPIT_*` et toute valeur de jeton (P71-D-03, P71-D-04, P71-D-14).
- **TERM-07** PTY : assistant Python stdlib, lancé isolé (`-I`), redimensionnement, Ctrl-C (SIGINT au groupe de premier
  plan), macOS et Linux ; sous Windows, message « indisponible » et aucun second serveur (P71-D-06, P71-D-07).
- **TERM-08** Session : une seule, la deuxième est refusée ; survie au rechargement (30 s de grâce, tampon de 256 Ko en
  mémoire) ; SIGHUP au groupe après la grâce ; aucun processus survivant à l'arrêt du serveur ; le terminal ouvert empêche
  l'arrêt sur inactivité (P71-D-05).
- **TERM-09** Usage réel : un programme plein écran (alternate screen, couleurs 256/truecolor, SIGWINCH, SIGINT) se comporte
  normalement dans le terminal (test automatisé avec un programme témoin) ; `claude` démarre à la racine du lab et y voit son
  `CLAUDE.md` et ses skills, et une commande VibeFlow tourne (recette humaine, macOS ; Linux par la CI pour la partie
  automatisée) (P71-D-01, P71-D-06).
- **TERM-10** xterm.js vendorisé avec sha256 et licence ; aucun addon presse-papiers ; séquences OSC 52, OSC 8, DCS, CSI 21t,
  DECRQSS dans la sortie : presse-papiers inchangé, aucun octet réinjecté dans l'entrée du PTY (P71-D-16).
- **TERM-11** Aucune frappe ni sortie du terminal sur disque ni dans les flux du cockpit (journal, SSE, export) ; le tampon
  de reprise est vidé à la fin de la session.
- **TERM-12** Non-régression et chaîne XSS : toutes les suites du cockpit restent vertes ; la chaîne de
  `test-cockpit-chaine-xss.sh` étendue — une charge exécutée dans P qui tente `window.open` vers Q, `postMessage`, `fetch`/POST
  vers Q avec le jeton de page, la lecture du stockage de Q — ne crée aucun fichier marqueur par le shell.
</requirements>

<canonical_refs>
## Canonical References

- `.planning/workstreams/fiabilite/phases/VFDO-67-cockpit-floorplan-socle-partage/67-SECURITY.md` — modèle de menace du cockpit, témoins F1.
- `.planning/workstreams/fiabilite/phases/VFDO-69-suivi-travail-en-cours-cockpit/69-CONTEXT.md` § P69-D-19..21.
- `plugin/cockpit/skills/cockpit-moteur/assets/serve.mjs` l.480-600 (Host, Origin, jeton, `pageCsp`, `listen`).
- `plugin/cockpit/scripts/vf-cockpit-server.mjs` (`attach`), `plugin/cockpit/scripts/vf-cockpit.mjs` (lanceur).
- `plugin/cockpit/scripts/tests/chrome-session.mjs`, `test-cockpit-chaine-xss.sh` (harnais CDP).
- `plugin/cockpit/amont/SYNCHRO.md` (tout changement de `serve.mjs` = un patch amont).
- `DESIGN.md` (`git show origin/docs/design-md:DESIGN.md`), direction « Graphite » : variables CSS du thème, sombre d'abord.
- Prototype PTY mesuré : scratchpad de la mission, `py/ptyhelper2.py`, `spike-iframe/bridge.py` (hors dépôt, à recopier, jamais à référencer).
</canonical_refs>
