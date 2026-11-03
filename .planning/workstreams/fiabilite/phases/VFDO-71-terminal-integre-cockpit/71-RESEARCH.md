# Phase 71 : Terminal intégré au cockpit - Recherche

**Recherché :** 2026-11-03
**Domaine :** serveur local Node (second écouteur, origine distincte), PTY Python stdlib, xterm.js 6 vendorisé, CSP/frame, audit de menaces
**Confiance :** HAUTE sur le branchement, les contrôles serveur, le PTY et les pièges xterm (relus ou rejoués cette session) ; MOYENNE sur la tenue du stockage Q dans un cadre `sandbox`, sur Firefox/Safari et sur la reprise d'un plein écran après rechargement (non mesurés).

Toutes les références de fichiers sont relatives au dépôt. Les mesures du prototype PTY, du spike de cadre iframe et des tarballs xterm viennent du « prototype de la mission (hors dépôt) » : elles se lisent ici, elles ne se citent pas par chemin.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Recopiées mot pour mot de `71-CONTEXT.md` (§ Implementation Decisions, état du 2026-11-03 20h01, avec P71-D-18 et P71-D-19).

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

Contraintes héritées (Phase 67, `v2.75.0`) : le lab observé n'est jamais une source de code (le shell, lui, est l'usage voulu) ;
les secrets ne sortent jamais vers le flux SSE, les fichiers générés, `serveur.log` ou l'export ; `.cache/server.json` en 0600,
hypothèse mono-utilisateur assumée (M7), désormais écrite pour le terminal aussi.

### Claude's Discretion

`71-CONTEXT.md` ne porte pas de section « Claude's Discretion ». Sont donc laissés à la recherche et au plan, sans toucher aux
décisions ci-dessus : le découpage des fichiers neufs, le mécanisme exact du jeton d'amorçage sur disque (D-11 autorise le disque
en 0600), le processus du second serveur (même processus ou séparé), l'emplacement du vendor xterm, la forme des suites de test.

### Deferred Ideas (OUT OF SCOPE)

Hors périmètre (`71-CONTEXT.md`, § Phase Boundary) : lancer du travail depuis les cartes (Phase 72), plusieurs sessions ou onglets
de terminal, Windows, tout changement du modèle de sécurité de la page Projet elle-même (la CSP de `v2.75.0` reste, seul
`frame-src` s'ajoute).

Limite de fond à écrire dans le README (`71-CONTEXT.md`) : « Le terminal, c'est votre compte, dans un dépôt potentiellement
hostile : un prompt git, `direnv`, des hooks peuvent exécuter du code du dépôt dès l'ouverture. Une extension de navigateur ayant
accès à `http://127.0.0.1/*` lit et pilote toute page locale. Le serveur ne peut fermer ni l'un ni l'autre. »
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Support de la recherche |
|----|-------------|-------------------------|
| TERM-01 | Activation seulement avec `--terminal`, CSP de P inchangée sans le drapeau | §2 (branchements), question ouverte O1 (conflit entre D-17 et « octet pour octet »), sonde T7 |
| TERM-02 | Host, Origin, jeton sur chaque requête de Q, aucun shell avant authentification | §4 patron « contrôles de Q », sondes T1 à T3, mutants M-ORIGIN, M-HOST, M-JETON |
| TERM-03 | Jetons jamais servis ni journalisés | §4 jeton d'amorçage sur disque (O3), sonde T5 |
| TERM-04 | Amorçage dans la même fenêtre, fragment effacé, secret hors cookie | §4 amorçage, mesures F1/F2 du spike, sonde T6 |
| TERM-05 | Tiroir en cadre d'origine Q, CSP de P + `frame-src`, CSP de Q stricte, 0 violation | §3 pageCsp, CSP de Q (style-src `'unsafe-inline'` imposé par xterm), F3 police, `sandbox`, sondes T8, T9 |
| TERM-06 | `$SHELL -l`, cwd, environnement filtré | §4 filtrage d'environnement, sonde T10 |
| TERM-07 | PTY Python stdlib, `-I`, resize, Ctrl-C, Windows | §4 assistant PTY (mesuré), sonde T11 |
| TERM-08 | Session unique, grâce 30 s, tampon 256 Ko, SIGHUP, aucun orphelin, anti-inactivité | §4 cycle de vie, O4, O5, sonde T12 |
| TERM-09 | Usage réel plein écran, `claude` à la racine | §5 programme témoin (rejoué), sonde T13, recette humaine |
| TERM-10 | xterm vendorisé (sha256, licence), séquences hostiles sans réinjection | §1 stack, §6 pièges xterm (DECRQSS réinjecté, vérifié dans la source), sonde T14 |
| TERM-11 | Aucune frappe ni sortie sur disque ni dans les flux | sonde T15 |
| TERM-12 | Non-régression et chaîne XSS | sondes T16, T17 (canal Q vers P), T18 (parité F7), suites existantes |
</phase_requirements>

## Résumé

Le plan se décompose en trois blocs de code neuf (serveur Q et session, assistant PTY, tiroir côté P), un vendor (xterm 6.0.0 et addon-fit 0.11.0) et un petit nombre de branchements dans `serve.mjs`, le lanceur, le patch amont et les docs. Tout le contrôle d'accès de Q se rejoue à chaque requête (Host, Origin, jeton) ; le transport est un `fetch()` en flux plus des POST, ce qui évite l'événement `upgrade`. Le PTY est un fichier Python lancé `python3 -I`, qui se termine seul quand le serveur disparaît (EOF du tube d'entrée), ce qui règle le cas du serveur tué par SIGKILL.

Trois points exigent une décision du manager avant le plan, parce qu'ils sont en tension avec des textes verrouillés : (O1) `assets/ui/9x-vf-terminal.js` chargé par ordre de nom (D-17) modifie la liste des empreintes de script de la CSP même sans `--terminal`, donc TERM-01 « octet pour octet » est faux tel quel ; (O2) le jeton d'amorçage et le cas d'un cockpit déjà lancé ; (O4) comment distinguer « le cadre se recharge » de « un deuxième onglet » pour la règle « une seule session ». D'autres zones grises neuves sont listées en §7.

Trois constats cadrent la CSP et la sécurité : (1) xterm 6 en moteur DOM crée des éléments `<style>` avec `textContent`, donc la CSP de Q doit porter `style-src 'unsafe-inline'` (« stricte » ne peut pas vouloir dire sans cela) ; (2) xterm répond de lui-même à DECRQSS par `triggerDataEvent`, c'est-à-dire des octets qui repartent vers l'entrée du PTY, ce que TERM-10 interdit : il faut un gestionnaire DCS de remplacement ; (3) les réponses DA/DSR/OSC 10-11 sont légitimes et nécessaires à `claude`, donc la sonde T14 a besoin d'un témoin positif.

**Recommandation principale :** un module de serveur Q dans le même processus que `serve.mjs`, chargé seulement avec `--terminal`, tous les crochets dans `serve.mjs` (jamais dans `vf-cockpit-server.mjs`, que la 69 modifie plus largement), le tiroir injecté à la volée quand le terminal est actif (option B de O1), et une écriture de test par exigence avec mutant nommé, programme témoin Python pour TERM-09 et un témoin positif pour chaque sonde négative.

## Contraintes du projet (CLAUDE.md)

Sources : `CLAUDE.md` du dépôt et `CLAUDE.md` global.

- Commits en français, cohérents avec l'historique ; un commit qui invoque une décision humaine nomme le canal et la date. Identifiants de décision préfixés (`P71-D-NN`, `TERM-NN`).
- Toute version est un tag annoté ; une release n'a lieu que pour une évolution fonctionnelle, et le geste est humain et gaté (mémoire « Ship toujours gaté humain »). Les tâches du plan ne bumpent ni `VERSION` racine, ni `plugin/.claude-plugin/plugin.json`, ni `.claude-plugin/marketplace.json`, ni les README racine (la 69 y touche aussi). Le bump du module `cockpit` et l'entrée de `CHANGELOG.md` suivent le geste de release.
- Jamais de fix sans validation humaine (ADR-031) : les constats de sécurité sont des menaces à arbitrer.
- Densité : ADR-029 pour agents/skills ; pour le code, `check-file-size` avertit à 250 lignes et bloque à 300 (hors marqueur `vibeflow:allow-large-file`). Cible : tout fichier neuf du plan sous 250 lignes.
- Gates : `check-gate-touche` (voir §8), `check-machine-paths`, `check-python-isolation`, `check-version-sync`.
- Le dépôt est piloté par GSD ; un geste de dépôt court prend le verrou (`driver-lock.sh`) ; vérifier le verrou avant tout checkout dans l'arbre principal. Ce travail reste dans le worktree de la phase.
- `rtk` proxifie grep, ls, find, diff et git et peut mentir : mesurer en `rtk proxy` quand le résultat compte (sortie vide comptée 1 ligne par `wc -l`).
- Global : pas de `timeout`/`gtimeout` sur le poste, pas de kill par motif (mémoire du crash du 2026-11-02 : `hygiene.sh` filtre par marque non vide).

## Cartographie de responsabilité d'architecture

| Capacité | Tier principal | Tier secondaire | Raison |
|----------|----------------|-----------------|--------|
| Rendu du terminal (xterm, thème, ajustement) | Navigateur, origine Q | | Code JS vendorisé, page servie par Q |
| Tiroir, poignée, raccourci, mémorisation de hauteur | Navigateur, origine P | | Chrome de l'application ; ne touche jamais le flux |
| Authentification (Host, Origin, jeton, secret) | Serveur Q | Lanceur (génère l'amorçage) | Contrôle sur chaque requête, avant tout shell |
| Secret de session | Navigateur, `localStorage` de Q | Serveur Q (valeur de référence) | Inaccessible depuis P (cloisonnement par origine) |
| PTY, shell, groupes de processus | Assistant Python | Serveur Q (cycle de vie) | `pty.fork`, `ioctl`, signaux : bibliothèque standard seule |
| Tampon de reprise (256 Ko) | Serveur Q, mémoire | | TERM-11 : jamais sur disque |
| `frame-src` de P, `/api/vf/terminal` | Serveur P (`serve.mjs`) | | Seul endroit où la CSP de page est produite |
| Tuer tout à l'arrêt | Serveur Q (`exit`) | Assistant Python (EOF du tube) | Deux filets : arrêt propre et SIGKILL du serveur |

## Stack standard

### Cœur

| Bibliothèque | Version | Rôle | Pourquoi |
|--------------|---------|------|----------|
| `@xterm/xterm` | 6.0.0 | émulation et rendu du terminal (moteur DOM) | verrouillé par P71-D-16 |
| `@xterm/addon-fit` | 0.11.0 | ajustement colonnes/lignes | verrouillé par P71-D-16 |
| Python 3 stdlib (`pty`, `os`, `fcntl`, `termios`, `select`, `signal`) | 3.9 à 3.14 | assistant PTY | verrouillé par P71-D-06 ; `requires: []` conservé |
| Node `http`, `crypto.timingSafeEqual`, `child_process` | Node 24 en CI | second serveur, comparaison en temps constant, lancement | aucune dépendance npm |

Aucun addon presse-papiers, web-links, WebGL ni serialize (D-16). Rien à installer dans le dépôt : les fichiers xterm sont copiés des tarballs et épinglés par sha256.

**Valeurs relevées cette session** (`[VERIFIED: tarballs téléchargés par la mission, shasum rejoués]`, sha1 des tarballs identiques à `npm view dist.shasum`) :

| Fichier | Taille | sha256 |
|---------|--------|--------|
| tarball `@xterm/xterm` 6.0.0 | | `908e66e04af6c8dc6b00dd3b54de088e2e81e5ed866284fd6c2fb3c2d1c7a3f6` (sha1 `93637b0f2ee3a70718b5746a27c9c506af16745b`) |
| tarball `@xterm/addon-fit` 0.11.0 | | `26003b4517a132b64e4ff228fd88a5fda3fff5e606c76093f6dcff772e9ecec0` (sha1 `ba4778b69fcc9044a060c2176bbe077657d7b37e`) |
| `lib/xterm.js` (UMD) | 488 663 o, 1 ligne | `14903579ff54664cd72f8e8699e6961a6272c21863ec1c3b118cdc8af5d4a972` |
| `css/xterm.css` | 7 112 o | `854a7c0fb70e8b1a083c16797ab827299fb18744f5ad34f227b48337e33293c6` |
| `lib/addon-fit.js` (UMD) | 1 521 o | `ba3ea256ce0620a0992a197d6c9baea64823fc93d8da07a9e366ca9943c18527` |
| `LICENSE` xterm | | `b569f629d00f2626a8100df2a1798210535621e42164dfd426a6fe5aac7b0ccd` |
| `LICENSE` addon-fit | | `e256f01188af527e4d06d21d06fbf785ae9c50d4b328bf03cbe0ba7f0aa4228f` |

Le fichier UMD est `lib/xterm.js` (pas `dist/`). Il se termine par `//# sourceMappingURL=xterm.js.map` : le garder octet pour octet (le sha256 vaut alors celui de l'amont) ; la requête de la carte ne part que si les outils de développement sont ouverts et reçoit un 404 de Q, sans effet.

Contenu relevé dans les fichiers (rejoué avec `rtk proxy grep` cette session) : 0 occurrence de `fetch(`, `XMLHttpRequest`, `WebSocket`, `sendBeacon`, `eval(`, `new Function` dans `xterm.js` ; 0 occurrence des motifs V5 de `test-cockpit-vendor.sh` (`run.app`, `waitlist`, `auth status`, `cloud-card`, `50-cloud`, `claudeEmail`) dans les trois fichiers ; URL littérales : `http://www.w3.org/1999/xhtml`, `http://www.w3.org/2000/svg`, `https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts` (dans `xterm.js`), `http://bellard.org/jslinux/` et `https://github.com/chjj/term.js` (commentaires de `xterm.css`). Ces cinq URL devront figurer dans une liste blanche motivée si la sonde « URL des pages » (R2) est rejouée sur la page Q.

**Alternatives écartées (décidées par le contexte) :** WebSocket (D-09), addon presse-papiers (D-16), module PTY Node natif (D-06, ajouterait une dépendance et casserait `requires: []`).

### Audit de légitimité des paquets

| Paquet | Registre | Âge | Téléchargements | Dépôt source | Verdict | Disposition |
|--------|----------|-----|-----------------|--------------|---------|-------------|
| `@xterm/xterm` | npm | publié 2025-12-22 | 9,07 M/semaine | github.com/xtermjs/xterm.js | OK | Approuvé |
| `@xterm/addon-fit` | npm | publié 2025-12-22 | 7,76 M/semaine | github.com/xtermjs/xterm.js | OK | Approuvé |

`[VERIFIED: gsd-tools query package-legitimacy check --ecosystem npm @xterm/xterm @xterm/addon-fit]` : deux verdicts OK, `postinstall` nul. Les noms viennent d'une décision de Samuel (D-16), pas d'une recherche web. `npm view` : latest 6.0.0, licence MIT ; une bêta 6.1.0-beta existe (non retenue). Aucun paquet retiré, aucun suspect. Les paquets ne sont pas installés dans le dépôt (copie de fichiers vendorisés), donc aucun `npm install`.

## Architecture

### Schéma du flux

```
 lanceur vf-cockpit.mjs --terminal
   |  génère amorçage B (jamais en HTTP) ; l'écrit en 0600 (O3) ; lance serve.mjs --terminal --no-open
   v
 serve.mjs (P, 127.0.0.1:P) ---- chargement (dynamique) ----> module terminal (Q, 127.0.0.1:Q)
   | pages Code/Projet avec CSP + frame-src Q                    | GET / (page Q), GET /vendor (xterm)
   | GET /api/vf/terminal (sous jeton P) -> { origine Q }         | GET /flux (octets bruts, jeton en en-tête)
   |                                                              | POST /entree, POST /taille (jeton en en-tête)
   v                                                              v
 navigateur, un onglet                                  session unique ---- tube stdin/stdout, fd 3 de contrôle ----> python3 -I vf-cockpit-pty.py
   1. ouvre Q/#t=B (top)  -> Q échange B contre le secret S, range S (localStorage de Q), efface le fragment,
                              location.replace(P)                                                  |
   2. P affiche la page + tiroir -> iframe Q (sandbox, theme=)                                       v
   3. Q lit S -> fetch /flux (en-tête) ; xterm.onData -> POST /entree        pty.fork -> $SHELL -l (cwd = realpath(lab), env filtré)
   4. Q -> P : postMessage(valeur fixe, origine P) ; P filtre origin + source + liste                |
   Arrêt : EOF du tube (serveur mort ou fermé) -> SIGHUP au groupe, SIGKILL après 3 s, exit            v
```

### Structure recommandée des fichiers neufs

```
plugin/cockpit/
├── scripts/
│   ├── vf-cockpit-terminal.mjs          # écouteur Q, contrôles Host/Origin/jeton, routes (< 250 l.)
│   ├── vf-cockpit-terminal-session.mjs  # session unique, lancement du PTY, tampon 256 Ko, grâce, nettoyage
│   ├── vf-cockpit-terminal-page.mjs     # page Q : HTML, CSP et empreintes, thème, variables Graphite, police
│   ├── vf-cockpit-terminal-amorce.mjs   # jeton d'amorçage, secret de session, comparaison en temps constant
│   ├── vf-cockpit-terminal-env.mjs      # filtrage de l'environnement (pur, testable seul)
│   ├── vf-cockpit-terminal-tiroir.mjs   # (option B de O1) JS et CSS du tiroir, servis à la volée
│   ├── vf-cockpit-pty.py                # assistant PTY (non copié dans la sortie : lu dans le dossier de scripts du module)
│   └── tests/ test-cockpit-terminal-*.sh + terminal-aux.mjs + temoins/{plein-ecran.py,hostile.py,recepteur.py}
└── skills/cockpit-moteur/assets/vendor/xterm/   # xterm.js, addon-fit.js, xterm.css, 2 licences, SHA256SUMS
```

Règle de nommage : `fichiersExecution` recopie dans la sortie tout `vf-cockpit-*.mjs` sauf `build`, `rename`, `code*` et `fr-*` (`plugin/cockpit/scripts/vf-cockpit-build.mjs:19-20`). Les cinq fichiers `vf-cockpit-terminal*.mjs` sont donc recopiés à côté de `serve.mjs` sans rien changer. Le fichier `.py` ne l'est pas : l'assistant se lit dans `VF_COCKPIT_SCRIPTS_DIR` (posé par le lanceur, `resolveScriptsDir`), jamais dans un dossier du lab (leçon M3 de `67-SECURITY.md`). Les suites qui lancent `serve.mjs` directement doivent poser `VF_COCKPIT_SCRIPTS_DIR` et `VF_COCKPIT_ENGINE_DIR`, comme `test-cockpit-chaine-xss.sh` le fait déjà.

Le vendor xterm va sous `assets/vendor/` pour deux raisons mesurées : `check-python-isolation.sh` exclut explicitement `*/assets/vendor/*.js` (JS minifié à lignes géantes), et c'est la convention d'elkjs et des polices. Les fichiers sont lus depuis `VF_COCKPIT_ENGINE_DIR/assets/vendor/xterm/` (chemin posé par le lanceur), vérifiés contre leur sha256 au démarrage de Q ; une altération fait refuser le démarrage du terminal avec un message en français (mutant M-VENDOR, sonde T14).

### Patron 1 : contrôles de Q sur chaque requête

Reprendre la forme de `serve.mjs` (voir §3) en la durcissant selon D-10 : un seul point d'entrée qui rend un refus avant tout routage.

```js
// Forme à suivre (adaptée de serve.mjs:505-511 ; durcie par P71-D-10)
const HOTES = [`127.0.0.1:${port}`, `localhost:${port}`];
const ORIGINE = `http://127.0.0.1:${port}`;           // l'origine du terminal, rien d'autre
function controle(req) {
  if (!HOTES.includes(String(req.headers.host || '').toLowerCase())) return 403;     // rebinding
  const o = req.headers.origin;
  const lectureStatique = req.method === 'GET' && !/^\/(flux|entree|taille)/.test(url.pathname);
  if (o === undefined) { if (!lectureStatique) return 403; }                          // sans Origin : GET de page seulement
  else if (o !== ORIGINE) return 403;                                                  // Origin de P comprise
  if (!lectureStatique && !egalTempsConstant(req.headers['x-vf-terminal'], secret)) return 401;
  return 0;
}
// aucune réponse ne porte Access-Control-* ; OPTIONS -> 403 (le spike : aucun préflight accepté)
```

Détails à ne pas manquer : une page Q servie via `localhost:Q` aurait pour Origin `http://localhost:Q` ; D-10 admet les deux Host mais « l'origine du terminal » est une seule valeur : trancher dans le plan (recommandé : `127.0.0.1` seulement pour l'Origin, Host `localhost` admis seulement pour les GET statiques). `crypto.timingSafeEqual` exige deux tampons de même longueur : comparer d'abord les longueurs (ou condenser par sha256) pour ne pas lever d'exception, et traiter une exception comme un refus.

### Patron 2 : assistant PTY (mesuré)

Le prototype de la mission prouve les trois comportements demandés par TERM-07, rejoués ici sous Python 3.14.6 et sous le `python3` système de macOS (3.9.6) : `ioctl(TIOCSWINSZ)` sur le maître envoie SIGWINCH au groupe de premier plan (la trappe `stty size` affiche la nouvelle taille), l'octet `0x03` écrit sur le maître interrompt le processus au premier plan (statut « signalé, signal 2 »), et la lecture du maître lève `OSError` quand l'enfant sort. L'assistant du plan reprend le pont minimal du spike (stdin vers maître, maître vers stdout, mort sur EOF ou SIGTERM) et ajoute :

- un **canal de contrôle** sur le descripteur 3 (lignes `R <lignes> <colonnes>`) lu dans la même boucle `select`, appliqué par `ioctl` ;
- l'**enfant** : `os.chdir(cwd)` puis `os.execvp(shell, [shell, '-l'])` avec l'environnement déjà filtré par Node (l'assistant n'invente aucune variable) ;
- l'**arrêt** (EOF du tube d'entrée, SIGTERM, ou ordre `X` du contrôle) : `os.killpg(pid_shell, SIGHUP)`, fermeture du maître (le noyau envoie SIGHUP au groupe de premier plan), attente bornée de 3 s, puis `SIGKILL` du groupe, `waitpid`, `os._exit(0)` ;
- le code de sortie du shell rendu sur le descripteur 2 (ligne `FIN <code|signal>`), pour la carte « Le shell s'est terminé (code N) » de l'UI-SPEC ;
- **compatibilité Python 3.9** : pas de `match`, pas d'unions de types évaluées à l'exécution (`/usr/bin/python3` de macOS est un 3.9.6, relevé ici).

Le shell est session leader (`pty.fork` appelle `setsid`) : `killpg(pid_shell)` atteint donc son groupe, et les travaux d'un shell interactif sont relayés par le shell lui-même (bash et zsh envoient SIGHUP à leurs travaux). Limite à écrire au README : un processus détaché volontairement (`nohup`, `setsid`) survit, comme dans tout terminal. `[ASSUMED]` : le comportement de bash/zsh sur SIGHUP aux travaux d'arrière-plan est celui des manuels ; la sonde T12 le mesure (travail d'arrière-plan avec marque).

Lancement côté Node : `spawn('python3', ['-I', assistant, ...], { stdio: ['pipe', 'pipe', 'pipe', 'pipe'], env })`. Pas de `detached` : l'assistant doit mourir avec le serveur. Contre-pression : si `res.write()` renvoie `false`, suspendre la lecture de `stdout` jusqu'à `drain`, sinon un `cat` géant gonfle la mémoire.

### Patron 3 : reprise après rechargement

Le tampon est une file d'octets bornée à 256 Ko en mémoire. Au rattachement du flux : envoyer le tampon puis le direct. Deux pièges, voir §6 : le tampon coupé peut commencer au milieu d'une séquence d'échappement (ou d'un caractère UTF-8) ; et pour une application plein écran en cours (`claude`), la queue de 256 Ko n'est pas garantie de contenir l'entrée en écran alterné.

### Anti-modèles à éviter

- Mettre le jeton ou le secret dans une URL, un cookie, `data-*`, une variable globale de la page Q ou un corps de réponse : le spike montre le cookie envoyé à P et lisible par `document.cookie`.
- Écouter `upgrade` ou ouvrir un WebSocket : il court-circuite Host, Origin et jeton (D-09).
- Ajouter une variable d'environnement portant l'amorçage à un processus qui lance des enfants (`claude -p` hérite de `process.env` via `cliEnv`, `serve.mjs:161-165`) : l'amorçage ne doit pas vivre dans l'environnement du serveur (O3).
- Journaliser la moindre octet d'entrée ou de sortie, même tronqué, même en erreur (TERM-11) ; les messages d'erreur du module nomment des états, jamais des données.
- Lancer le shell à la connexion du flux avant d'avoir validé le secret ; ou sur un GET de la page.

## À ne pas réinventer

| Problème | Ne pas construire | Utiliser | Pourquoi |
|----------|-------------------|----------|----------|
| Émulation de terminal | un analyseur VT maison | xterm.js 6 | séquences, Unicode, sélection, défilement |
| Ajustement à la taille | calcul de cellules à la main | `addon-fit` (attendre `document.fonts.ready`) | mesure de cellule du moteur DOM |
| PTY | `script`, `expect`, `forkpty` en C, `node-pty` | `pty.fork` de la bibliothèque standard | zéro dépendance ; `requires: []` |
| Comparaison de secrets | `===` | `crypto.timingSafeEqual` sur condensés | temps constant (D-10) |
| Jeton aléatoire | `Math.random` | `crypto.randomBytes(32)` (comme `serve.mjs:88`, `randomBytes(16)`) | CSPRNG |
| Calcul des empreintes de CSP | autre regex | la forme de `pageCsp` : `<script>` sans attribut, hash du contenu en base64 | la regex de `pageCsp` ne voit que cette forme (D-16) |
| Hygiène de processus des suites | `pkill -f`, `awk` sur `ps` | `tests/hygiene.sh` (`vf_hyg_init/stop/assert`) | marque non vide, plafond, témoin positif (incident du 2026-11-02) |
| Pilotage du navigateur | Playwright, puppeteer | `chrome-session.mjs` (CDP par WebSocket de Node) | aucune dépendance, déjà gaté CI |

**Idée clé :** chaque brique de ce domaine a une version « presque juste » qui échoue sur un cas limite que l'audit ira chercher (préflight, `upgrade`, octet coupé, groupe de processus). Les rares choses à écrire à la main sont les contrôles d'accès de Q et la plomberie de session.

## 2. Cartographie des fichiers

### 2.1 Fichiers neufs (tous sous `plugin/cockpit/`)

| Fichier | Rôle | Remarque |
|---------|------|----------|
| `scripts/vf-cockpit-terminal.mjs` | écouteur Q, routes, contrôles | export unique `demarrerTerminal({ here, root, portP, log })`, aucun effet de bord à l'import |
| `scripts/vf-cockpit-terminal-session.mjs` | session, PTY, tampon, grâce, arrêt | un seul objet de session ; lance l'assistant seulement après authentification |
| `scripts/vf-cockpit-terminal-page.mjs` | page Q, CSP de Q, thème, variables Graphite | inline xterm.js, addon-fit, script de page (3 `<script>` sans attribut), `<style>` pour `xterm.css` |
| `scripts/vf-cockpit-terminal-amorce.mjs` | amorçage, secret, échange | voir O3 |
| `scripts/vf-cockpit-terminal-env.mjs` | filtre d'environnement | pur, testé sans réseau |
| `scripts/vf-cockpit-terminal-tiroir.mjs` | JS et CSS du tiroir (option B) | si option A : fichier `assets/ui/90-vf-terminal.js` à la place |
| `scripts/vf-cockpit-pty.py` | assistant PTY | lu dans le dossier de scripts du module, non copié |
| `skills/cockpit-moteur/assets/vendor/xterm/*` | 3 fichiers + 2 licences + `SHA256SUMS` | 6 lignes `AJOUT` dans `VENDORED.txt` |
| `scripts/tests/test-cockpit-terminal-{activation,serveur,pty,session,xterm,navigateur,xss}.sh` | une suite par famille de §3 | découvertes automatiquement par la CI (`find plugin scripts -path '*/tests/test-*.sh'`, `scripts/ci-shard-suites.sh`) |
| `scripts/tests/terminal-aux.mjs`, `scripts/tests/temoins/*.py` | aides et programmes témoins | ne s'appellent pas `test-*.sh` : non découverts comme suites |

Chargement du tiroir (question demandée) : `build.mjs` inline chaque `assets/ui/*.js` dans l'ordre alphabétique (`plugin/cockpit/skills/cockpit-moteur/scripts/build.mjs:448`, `[VERIFIED]`, citation : `fs.readdirSync(uiDir).filter((n) => n.endsWith('.js')).sort().map((n) => \`<script>/* ui/${n} */\n…\``). Un fichier `90-vf-terminal.js` passerait donc après `80-vf-fr.js` sans toucher une liste ni un assemblage (aucune liste ne recense ces fichiers côté build), mais il exige : une ligne `AJOUT assets/ui/90-vf-terminal.js` dans `VENDORED.txt` (sinon `synchro.sh verifier` rougit : il retire les `AJOUT` listés puis compare au manifeste amont), un en-tête qui commence par `// VibeFlow (71-NN) :` (le motif `MARQUEURS_FR` de `vf-cockpit-fr-inventaire.mjs:113` saute alors tout le bloc, sinon un mot isolé comme « Terminal » est compté comme chaîne anglaise non traduite par la suite `chrome-fr`), et moins de 300 lignes (V4 de `test-cockpit-vendor.sh`). Les noms `71-` et `72-` sont pris par la 69 (`assets/ui/72-vf-equipe.js` existe sur sa branche et `71-vf-equipe-rendu.js` est dans ses plans) ; `90` est libre. Les phases 70 et 72 n'ont aucun fichier à ce jour.

### 2.2 Points de branchement dans des fichiers existants

Les numéros de ligne sont ceux du worktree de la phase (base `7370d604`) ; ils bougent si la 69 est mergée avant.

| # | Fichier | Endroit | Changement minimal | Ce que la 69 touche déjà ou prévoit | Risque de conflit |
|---|---------|---------|--------------------|-------------------------------------|-------------------|
| B1 | `scripts/vf-cockpit.mjs` | `lireArgs` l.22-37, `AIDE` l.14-19, `demarrer` l.69-88, `main` l.114-122 | accepter `--terminal` (champ `o.terminal`) ; sous le drapeau : engendrer l'amorçage, passer `--terminal --no-open` à `serve.mjs`, ouvrir l'URL de Q lui-même ; décider du cas « serveur déjà vivant » (O2) | rien (non touché sur la branche 69) | faible |
| B2 | `skills/cockpit-moteur/assets/serve.mjs` | `pageCsp` l.489-496 | ajouter `; frame-src <origine Q>` seulement si le terminal est actif | la 69 ajoute 1 ligne l.568 (`/equipe.html`), pas ici | faible (hunks distincts) |
| B3 | `serve.mjs` | `inject` l.171 / `load` l.183 (option B de O1) | ajouter à `inject` le tiroir quand le terminal est actif | la 69 passe `inject` à `pageEquipe` (dans `vf-cockpit-server.mjs`) | faible |
| B4 | `serve.mjs` | garde d'inactivité l.217 | `&& !TERM?.occupe()` | rien | faible |
| B5 | `serve.mjs` | routage l.508-512 (avant `VF.route`) | `GET /api/vf/terminal` sous jeton, renvoie l'origine de Q (jamais de secret) ; absent sans drapeau | rien | faible |
| B6 | `serve.mjs` | `server.on('listening')` l.592-610 | démarrer Q une fois le port de P connu ; compléter `server.json` (0600) avec les infos non secrètes de Q | rien | faible |
| B7 | `amont/patches/assets__serve.mjs.diff` + `VENDORED.txt` (ligne `PATCH assets/serve.mjs …`, `TAILLE assets/serve.mjs`, 6 `AJOUT`) | | régénérer le diff : `bash plugin/cockpit/amont/synchro.sh regenerer-patch assets/serve.mjs` puis `verifier` | la 69 modifie la même ligne `PATCH assets/serve.mjs` (ajoute `P24`) et `TAILLE` (610 vers 611) et régénère le diff | **certain** : fusion à la main (liste `…,P24,P25`, TAILLE recalculée, diff régénéré APRÈS la fusion) |
| B8 | `README.md`, `CHANGELOG.md`, `module.json` (description « Lecture seule… »), `VERSION` | sections « Ouvrir », « Confidentialité et réseau », « Limites connues » ; entrée de version au geste de release | la 69 modifie les quatre | **certain** sur le texte ; ajouter, ne pas réécrire |
| B9 | `scripts/tests/test-cockpit-vendor.sh` | V2 « quatre composants listés » (assertion `n = 4`) | le passer à 6 (xterm et addon-fit ajoutés à `LICENCES-TIERCES.txt`) | non touchée | faible |
| B10 | `skills/cockpit-moteur/LICENCES-TIERCES.txt` | deux lignes `<nom> (MIT) — <chemin de la licence>` | format lu par V2 : la licence doit exister sous `skills/cockpit-moteur/` | non touché | faible |

`vf-cockpit-server.mjs` et `vf-cockpit-build.mjs` ne sont PAS touchés par le plan recommandé. Raison : la 69 y a déjà modifié les imports (l.16-22), `load` (l.28-35) et l'objet retourné (`pageEquipe`, l.109-114) ; tout crochet là-dedans produirait un conflit textuel. Les crochets B2 à B6 tiennent dans `serve.mjs` (qui a un patch amont, une liste `P`, et où la 69 ne change qu'une ligne). Si le planificateur préfère passer par `attach()`, c'est faisable mais il faut alors fusionner l'objet retourné à la main.

Suites que la 69 modifie et que la 71 ne doit pas toucher : `test-cockpit-securite.sh`, `test-cockpit-reseau.sh`, `test-cockpit-serveur.sh`, `test-cockpit-projet.sh`, `test-cockpit-robustesse.sh`, `test-cockpit-who.sh`. Toute vérification de la 71 sur ces sujets va dans les suites neuves `test-cockpit-terminal-*.sh`.

### 2.3 Effets de bord à connaître

- `exportMap` lit `index.html` : sous l'option A de O1, le script du tiroir est présent dans l'export (inerte). Sous l'option B, il n'y est jamais.
- `R2` de `test-cockpit-reseau.sh` extrait toute URL `https?://[^ "'<>)\\]*` des pages : le script du tiroir ne doit contenir aucun littéral `http://` (construire l'origine de Q à partir de la réponse de `/api/vf/terminal`, ou par concaténation `'//127.0.0.1:' + port`), sinon cette suite existante rougit (`[VERIFIED: test-cockpit-reseau.sh:129-134, motif du grep -oE]`).
- `R3.3` (un seul port dans `server.json` hors drapeau) reste vert si la clé de Q s'appelle `terminal` et non `portTerminal`/`terminalPort` (le test filtre `/port/i`, et ne tourne que sans le drapeau).
- La suite `chrome-fr` inventorie les chaînes anglaises des pages servies et du source de `serve.mjs` : les messages ajoutés à `serve.mjs` doivent être en français.
- Le renommage de marque blanche (`vf-cockpit-rename.mjs`) s'applique aux fichiers de la sortie : ne jamais écrire le nom amont dans les fichiers du terminal (le test de marque blanche le chercherait).

## 3. État des défenses existantes à reproduire ou à ne pas casser

`[VERIFIED: plugin/cockpit/skills/cockpit-moteur/assets/serve.mjs:487-497, 505-511]` (relu cette session, citations littérales) :

- `const BASE_CSP = "default-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'";`
- `pageCsp` : `` `default-src 'none'; script-src ${[...new Set(hashes)].join(' ')}; style-src 'unsafe-inline'; img-src 'self' data:; font-src data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'; object-src 'none'` ``, avec `hashes` issus de `String(html).matchAll(/<script>([\s\S]*?)<\/script>/g)`.
- Contrôle Host : ``if (![`127.0.0.1:${port}`, `localhost:${port}`].includes(String(req.headers.host || '').toLowerCase())) { res.writeHead(403); return res.end('unknown host'); }``
- Contrôle Origin de P : ``const sameOrigin = !req.headers.origin || req.headers.origin === `http://${req.headers.host}`;`` (P admet donc les requêtes sans Origin ; Q ne doit PAS reprendre cette tolérance pour le flux et les POST, D-10).
- Toutes les réponses : `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `BASE_CSP` (l.499). **Conséquence pour Q** : `X-Frame-Options: DENY` empêche d'encadrer Q ; Q ne doit PAS poser cet en-tête (`frame-ancestors` le remplace) — oubli classique qui donne un cadre vide (le spike l'a mesuré sans cet en-tête).
- Écoute : `server.listen(port, '127.0.0.1')` (l.591), repli `port++` jusqu'à `wantPort + 20` (l.587) : le port de P n'est connu qu'à l'événement `listening`, donc `frame-ancestors` de Q et l'origine de P attendue dans les messages se calculent après cet événement.
- `.cache/server.json` est écrit en 0600 puis `chmod` (l.596-597) ; le lanceur ne le lit que pour `pid` et `url` (`vf-cockpit.mjs:39-42`).

## 4. Zones de conception à détailler dans le plan

### 4.1 Environnement du shell (TERM-06)

Fonction pure `envShell(env)` qui retire exactement : `CLAUDECODE`, tout `CLAUDE_CODE_*` (le motif de `serve.mjs:162` est plus étroit : `^CLAUDE_?CODE_(SESSION|ENTRYPOINT|CHILD|MESSAGING|HOST|SDK)|^CLAUDECODE$` ; D-03 dit « `CLAUDE_CODE_*` hérités » donc le motif large `^CLAUDE_CODE_`), `VF_COCKPIT_*`, et toute valeur de jeton du cockpit (comparer les valeurs, pas seulement les noms : tester avec une variable `AUTRE=<valeur du jeton>`). Pas de liste blanche. `NODE_OPTIONS` passe, sauf une valeur posée par le cockpit lui-même (D-14) : `grep` du lanceur et de `serve.mjs` pour `NODE_OPTIONS` ne trouve aucune pose à ce jour (`rtk proxy grep` à rejouer au plan ; si le plan en ajoute une, retirer ce que le cockpit pose). Ajouter `TERM=xterm-256color` et `COLORTERM=truecolor` seulement s'ils sont absents (sans eux `claude` n'affiche ni 256 couleurs ni truecolor) : c'est un ajout hors D-03 que le plan doit signaler comme choix (question O7).

Choix du shell : `$SHELL` s'il est absolu et exécutable, sinon l'entrée du compte, sinon `/bin/sh`. `[ASSUMED]` : `SHELL` peut manquer dans un environnement de service (lanceur détaché, runner CI) ; le repli évite un terminal qui ne démarre pas.

### 4.2 Amorçage et secret (TERM-03, TERM-04)

Flux de D-12. Choix de mécanisme laissés à la recherche (O3) : recommandation, un fichier `.cache/terminal-amorce` écrit par le lanceur (suppression préalable, création `wx`, mode 0600, jamais suivi si lien symbolique), lu puis supprimé par Q lors de l'échange ; le jeton ne vit alors ni dans l'environnement du serveur (hérité par `claude -p`), ni dans `server.json`, ni dans un argument de `serve.mjs` (visible par `ps`). Il passe par l'argument de la commande d'ouverture du navigateur (`open`/`xdg-open`) une fraction de seconde : même hypothèse mono-utilisateur que M7, à écrire au README. `[ASSUMED]` : un autre utilisateur de la machine peut lire l'argument d'un processus par `ps` ; non mesuré.

Q échange le jeton contre un secret de session de 32 octets aléatoires produit au démarrage de Q, le renvoie dans le corps de la réponse de l'échange (jamais en cookie, jamais dans un en-tête `Set-Cookie`), la page le range dans son `localStorage`, efface le fragment (`history.replaceState`) puis `location.replace` vers P. Le jeton d'amorçage est à usage unique : la seconde présentation est refusée sans lancer de shell.

Le secret circule ensuite en en-tête (`X-VF-Terminal` ou nom équivalent) sur le flux et les POST. Le flux `fetch()` l'envoie en en-tête, pas dans l'URL (D-09). Le mutant M-URL (secret en paramètre d'URL) doit rougir T5.

### 4.3 Cycle de vie de la session (TERM-08)

États : absente, vivante attachée, vivante détachée (grâce), terminée. Règles à écrire telles quelles :
- une seule session par serveur ; une seconde demande de création est refusée (statut distinct, ex. 409) sans lancer de processus ;
- détachement = fermeture du flux : démarrer la minuterie de 30 s ; au rattachement avant l'échéance, annuler et rejouer le tampon ; à l'échéance, `X` à l'assistant ;
- le tampon est vidé à la fin de la session (TERM-11) ;
- arrêt du serveur : handler `process.on('exit')` qui tue l'assistant, plus le filet de l'EOF du tube (couvre SIGKILL) ;
- `occupe()` vrai tant qu'une session existe (B4). Remarque : tant que l'onglet est ouvert, son flux `/api/events` fait déjà compter `tabs.size`, donc B4 ne sert que pendant la grâce ou quand l'onglet est fermé ; l'exigence est quand même écrite, la sonde T12 la prouve avec `--idle-exit` réduit.

### 4.4 Cadre, `sandbox` et canal Q vers P (D-18, UI-SPEC)

L'UI-SPEC pose `sandbox="allow-scripts allow-same-origin"` sur le cadre. **Non mesuré par le spike** (le spike encadrait sans `sandbox`) : il faut une sonde qui prouve que, sous ce `sandbox`, `localStorage` de Q est lisible, que `fetch` vers l'origine de Q marche et que `postMessage` vers P arrive avec `event.origin` = origine de Q (T9, T17). `[ASSUMED]` jusqu'à cette sonde. Sans `allow-popups`, `window.open` est bloqué : les liens cliquables du terminal ne s'ouvriront pas ; l'UI-SPEC prévoit `allow-popups allow-popups-to-escape-sandbox` « si la politique l'exige » (O8).

Canal Q vers P (liste fermée de l'UI-SPEC §13 : `ready`, `etat:connecte`, `etat:reconnexion`, `etat:termine`, `etat:refuse`, `etat:expire`, `etat:arrete`, `toggle`) :
- côté Q : `parent.postMessage(valeur, ORIGINE_P)` avec `ORIGINE_P` posée par la configuration de la page (calculée par le serveur à partir du port de P) ; jamais `'*'` ; valeur issue d'une table de constantes, jamais d'une donnée du shell ;
- côté P : un seul écouteur `message` qui vérifie, dans cet ordre, `e.origin === origineQ`, `e.source === cadre.contentWindow`, `typeof e.data === 'string'` et `LISTE.has(e.data)`, sinon `return` sans trace ni exception ;
- Q n'écoute aucun message (D-15 inchangé) ;
- si P est chargé via `localhost:P`, `ORIGINE_P` (en `127.0.0.1`) ne correspond pas : le navigateur ne livre pas le message, et le stockage de Q dans le cadre est partitionné (mesuré par le spike, `p3_temoin_cross_site` : `localStorage` nul et cookies vides dans un cadre encadré depuis `localhost`). Voir O6.

### 4.5 CSP de Q

À poser par la page Q (sans `X-Frame-Options`) :
`default-src 'none'; script-src <empreintes des 3 scripts>; style-src 'unsafe-inline'; connect-src 'self'; font-src data:; img-src data:; frame-ancestors <origines de P>; base-uri 'none'; form-action 'none'; object-src 'none'`.

- `style-src 'unsafe-inline'` est imposé : `[VERIFIED: src/browser/renderer/dom/DomRenderer.ts:138,158 et :149,:280 du tarball @xterm/xterm 6.0.0]` crée deux éléments `<style>` avec `textContent` (`this._dimensionsStyleElement = this._document.createElement('style');` l.138, `this._themeStyleElement = this._document.createElement('style');` l.158), et `Viewport.ts:79-83` un troisième. Aucun nonce n'est supporté (0 occurrence de `nonce`/`CspNonce` dans `src/`, relevé par `rtk proxy grep`). « Stricte » veut donc dire : pas de `unsafe-eval`, pas de script externe, `connect-src 'self'`, `frame-ancestors` exact.
- `font-src data:` (F3 de l'UI-SPEC) : pour JetBrains Mono embarquée en data URI dans la page Q ; les woff2 du cockpit sont sous `assets/vendor/fonts/` (4 fichiers, `test-cockpit-vendor.sh` V8.1). Sans cela la pile retombe sur `ui-monospace`, valable mais différent d'aspect.
- `frame-ancestors` : exactement `http://127.0.0.1:P` (et `http://localhost:P` seulement si O6 le décide).
- Pas de `img-src 'self'`.

### 4.6 CSP de P avec le drapeau

Chaîne actuelle du §3 plus `; frame-src http://127.0.0.1:Q` (origine exacte). Mémoïsation : `pageCsp` met en cache par contenu de page ; l'ajout ne dépend que de l'état du processus, donc stable. Sans le drapeau, la fonction doit produire la chaîne de v2.75.0 sans aucun octet de plus (T7/T8).

## 5. Programme plein écran témoin (TERM-09)

Écrit et rejoué cette session en Python stdlib (sous Python 3.14.6 et sous `/usr/bin/python3` 3.9.6) derrière un `pty.fork` : sortie observée `ESC[?1049h` (écran alterné), `TEMOIN-PLEIN-ECRAN-DEBUT`, une barre `ESC[48;5;<n>m` (256 couleurs), `ESC[38;2;255;100;0mTRUECOLOR` (truecolor), `TAILLE 24x80`, `PRET` ; après `TIOCSWINSZ 50x132` : `WINCH 50x132` ; après l'octet `0x03` : `ESC[?1049l` puis `SIGINT-RECU`, sortie de code 0.

```python
# plein-ecran.py : témoin de TERM-09 (écran alterné, 256 couleurs, truecolor, SIGWINCH, SIGINT)
import os, signal, sys, time
def w(s):
    sys.stdout.write(s); sys.stdout.flush()
def taille():
    c, l = os.get_terminal_size(sys.stdout.fileno())   # pas shutil : il lit COLUMNS/LINES d'abord
    return f"{l}x{c}"
w("\x1b[?1049h\x1b[2J\x1b[H")
w("TEMOIN-PLEIN-ECRAN-DEBUT\r\n")
w("".join(f"\x1b[48;5;{n}m \x1b[0m" for n in range(16, 232, 6)) + "\r\n")
w("\x1b[38;2;255;100;0mTRUECOLOR\x1b[0m\r\n")
w(f"TAILLE {taille()}\r\n")
def winch(*_): w(f"WINCH {taille()}\r\n")
def intr(*_): w("\x1b[?1049l"); w("SIGINT-RECU\r\n"); os._exit(0)
signal.signal(signal.SIGWINCH, winch); signal.signal(signal.SIGINT, intr)
w("PRET\r\n")
while True: time.sleep(0.05)
```

Observations de mesure à garder : le noyau double les fins de ligne (`\r\r\n`, ONLCR) ; l'écho `^C` précède la sortie du gestionnaire : les assertions cherchent des sous-chaînes, pas des lignes entières.

Deux niveaux d'automatisation (le second est le plus fort) :

1. **Flux direct, sans navigateur** (suite `test-cockpit-terminal-pty.sh`) : le test joue le rôle du navigateur avec un client Node (`fetch` flux, POST d'entrée et de taille, avec secret et en-têtes valides). Le shell de la session est un petit script de test (`SHELL=<tmp>/shell-test`, `exec /bin/sh -l`) dont la ligne de commande porte la marque de la suite, pour que `hygiene.sh` voie les survivants. Séquence : envoyer `python3 -I <tmp>/plein-ecran.py\n`, attendre `PRET`, vérifier `ESC[?1049h`, `48;5;`, `38;2;255;100;0m` ; POST de taille 50x132, attendre `WINCH 50x132` ; POST de l'octet `0x03`, attendre `SIGINT-RECU` puis le retour de l'invite du shell. Aucune contrainte de navigateur : tourne à l'identique sous macOS et sous Linux CI.
2. **Navigateur (CDP)** (suite `test-cockpit-terminal-navigateur.sh`) : après l'amorçage dans l'onglet (`naviguer` vers `Q/#t=<amorçage>` jusqu'à l'arrivée sur P), `naviguer` vers l'URL de Q seule, en premier niveau : le secret est déjà dans le `localStorage` de Q, la page fonctionne en terminal et son DOM est lisible par `ev` sans changer `chrome-session.mjs`. Saisir via `Input.insertText`/`dispatchKeyEvent`, attendre `attendre("document.querySelector('.xterm-rows').textContent.includes('PRET')")`, puis relever la grille. Le DOM xterm ne dit pas l'écran alterné : le test s'appuie sur le texte `TEMOIN-PLEIN-ECRAN-DEBUT` puis son absence après `SIGINT-RECU` (retour à l'écran normal). Le cadre dans P (T9, T17) se teste séparément, depuis P, sans lire le DOM de Q (inaccessible, c'est la propriété à prouver).

Contraintes Linux CI : Chrome headless Linux n'expose aucun pointeur (`pointer: none`, énoncé du mandat, `[ASSUMED]` non rejoué) ; les gestes souris du tiroir (poignée) doivent donc passer par `Input.dispatchMouseEvent` et ne pas dépendre d'une requête média `hover`/`pointer: fine` ; le clavier (`dispatchKeyEvent`) est indépendant. La CI a `google-chrome` et Node 24 (`.github/workflows/ci.yml`, job `tests-shard`) ; sans Chrome, les suites existantes retombent en « simulation fidèle » : les suites neuves doivent soit faire de même pour la partie navigateur, soit annoncer le saut en toutes lettres (jamais un vert à vide : `ÉCHEC ANTI-VERT-À-VIDE` si zéro assertion). `claude` lui-même n'est pas lancé en CI : la partie « `claude` démarre à la racine, voit `CLAUDE.md` et ses skills, une commande VibeFlow tourne » de TERM-09 est une recette humaine macOS (énoncé de l'exigence).

## 6. Pièges courants

### Piège 1 : DECRQSS réinjecte des octets dans l'entrée du PTY
**Ce qui se passe :** xterm répond lui-même à `DCS $ q … ST`. `[VERIFIED: src/common/InputHandler.ts:381 du tarball 6.0.0]` : `this._parser.registerDcsHandler({ intermediates: '$', final: 'q' }, new DcsHandler((data, params) => this.requestStatusString(data, params)));` ; la fonction appelle `this._coreService.triggerDataEvent(\`${C0.ESC}${s}${C0.ESC}\\\`)` (réponses `ESC P 1 $ r … ESC \`), c'est-à-dire un `onData` indiscernable d'une frappe.
**Pourquoi c'est un problème :** TERM-10 : « aucun octet réinjecté dans l'entrée du PTY ».
**Remède :** enregistrer un gestionnaire DCS de remplacement avant le premier flux, `term.parser.registerDcsHandler({ intermediates: '$', final: 'q' }, () => true)` (l'API existe : `typings/xterm.d.ts:1835`, `registerDcsHandler(id, callback)`) ; un gestionnaire enregistré après les natifs passe en premier, retourner `true` arrête la chaîne. `[ASSUMED]` pour l'ordre de priorité : la sonde T14 le prouve par un mutant sans le gestionnaire.
**Signal d'alerte :** le récepteur de la sonde T14 reçoit `1b50` (ESC P).

### Piège 2 : CSI 21 t n'est inoffensif que si `windowOptions` reste vide
`[VERIFIED: src/common/InputHandler.ts:92 et :262]` : `case 21: return !!opts.getWinTitle;` et `this._parser.registerCsiHandler({ final: 't' }, params => this.windowOptions(params));`. La valeur par défaut est vide (aucune option) ; l'UI-SPEC pose en plus tout à `false`. Le mutant M-WINOPT met `getWinTitle: true` et doit faire rougir T14 (le titre revient en entrée du PTY : injection de commande classique).

### Piège 3 : OSC 52 n'a pas de gestionnaire sans addon, OSC 8 a un `confirm()`
`[VERIFIED: src/common/InputHandler.ts:319-323]` : l'OSC 52 n'apparaît que dans une liste de commentaires (« 52 - Manipulate Selection Data. »), aucun `registerOscHandler(52` n'existe. OSC 8 est géré (`:304`) et son activation par défaut appelle `confirm(...)` puis `window.open()` (`src/browser/OscLinkProvider.ts:115`). D-16 impose clic seulement et `noopener` : fournir `linkHandler: { activate, allowNonHttpProtocols: false }` avec ouverture par `window.open(url, '_blank', 'noopener')` ; sous `sandbox` sans `allow-popups` l'appel est bloqué (O8). Les OSC 10/11/12 (`:306-310`), DA (`:245-246`), DSR (`:256-257`) répondent aussi par `onData` : c'est légitime et utilisé par `claude`, donc à laisser passer, et c'est le témoin positif de T14.

### Piège 4 : le moteur DOM écrit des `<style>` (CSP) et dessine mal les traits
Voir §4.5 (CSP). L'UI-SPEC pose `lineHeight: 1` pour que `│ ─ ┌` ne se coupent pas (moteur DOM, 6.0 n'a plus de moteur canvas) ; à valider en recette sur `claude`. Mesurer la cellule seulement après `document.fonts.ready`.

### Piège 5 : tampon de reprise coupé et applications plein écran
Un tampon de 256 Ko tronqué par la tête peut commencer au milieu d'une séquence ESC ou d'un caractère UTF-8, et ne contient plus l'entrée en écran alterné d'une application lancée il y a longtemps. Après rattachement, l'écran peut être faux jusqu'au prochain redessin de l'application. Pistes (à mesurer, `[ASSUMED]`) : rogner le tampon jusqu'au premier octet de début de caractère, puis forcer un redessin par deux `TIOCSWINSZ` successifs (taille moins une ligne puis taille réelle, deux SIGWINCH) après le rejeu. Zone grise neuve, voir O5.

### Piège 6 : `X-Frame-Options: DENY` et `frame-ancestors`
Voir §3 : Q ne pose pas `X-Frame-Options`. Témoin du spike : `frame-ancestors 'none'` bloque le cadre (violation relevée) ; `frame-src` absent de P le bloque aussi (`p1_sans_frame_src`).

### Piège 7 : `localhost` contre `127.0.0.1`
Mesuré par le spike : depuis `127.0.0.1:P` le stockage de Q encadré est partagé avec Q en premier niveau (même site) ; depuis `localhost:P` il est vide (cloisonné, `p3_temoin_cross_site`). P accepte les deux hôtes (`serve.mjs:505`), donc un utilisateur qui ouvre `localhost:P` obtient un tiroir « Session expirée » trompeur. Le tiroir doit détecter `location.hostname !== '127.0.0.1'` et le dire (O6).

### Piège 8 : l'hygiène des suites ne voit pas le shell
`hygiene.sh` retrouve les survivants par la marque de la suite dans leur ligne de commande, et ne traite comme orphelin qu'un arbre dont le sommet, sous pid 1, porte la marque. Un shell lancé par `$SHELL -l` s'appelle `-zsh`, `-bash` : sans marque. Les suites neuves doivent donc (a) poser `SHELL` sur un script de test situé dans leur dossier temporaire (ligne de commande `/bin/sh <tmp>/…/shell-test -l`, donc marquée), (b) lancer leurs programmes témoins par `python3 -I <tmp>/…/x.py`, (c) ne jamais compter sur `vf_hyg_assert` seul pour TERM-08 : une assertion dédiée lit les PID relevés (assistant, shell, travail d'arrière-plan) et sonde leur disparition par `kill -0` avec attente bornée.

### Piège 9 : `\r\r\n`, `^C`, et autres artefacts d'un PTY réel
Voir §5. Un test qui compare des lignes exactes sera faux sur un PTY.

### Piège 10 : commandes de vérification sous zsh, bash 3.2, uutils
Voir §8.

## 7. Questions ouvertes réelles

Aucune ne tranche un arbitrage P71-D-01 à D-19. Chacune est un choix neuf, avec options.

- **O1 (bloquante, conflit de textes).** D-17 : le tiroir est `assets/ui/9x-vf-terminal.js` « chargé automatiquement ». TERM-01 : sans `--terminal`, « la CSP de page est octet pour octet celle de v2.75.0 ». Or `build.mjs` inline ce fichier dans les deux pages, `pageCsp` calcule `script-src` à partir de TOUS les `<script>` de la page servie (`serve.mjs:491`) : un script de plus ajoute une empreinte sha256, la CSP diffère donc même sans le drapeau (`[VERIFIED]` par lecture des deux fichiers ; non rejoué en exécution). Options : (A) garder D-17 et redéfinir le témoin de TERM-01 en « mêmes directives, une empreinte de plus » (modifie le texte verrouillé de TERM-01) ; (B) servir le tiroir à la volée seulement avec le drapeau (ajout à `inject`, B3 de §2.2) : TERM-01 vrai à la lettre, « aucun nœud, aucun écouteur » de l'UI-SPEC §5 vrai a fortiori, export sans tiroir, mais le fichier n'est plus sous `assets/ui/` (modifie le texte de D-17) ; (C) fichier sous `assets/ui/` mais exclu de l'inline par une branche dans `build.mjs` (rejeté : patch de plus sur un fichier du moteur). **Recommandation : B.** À trancher par le manager avant le plan (arbitrage Samuel si c'est un texte de décision verrouillée).
- **O2.** `--terminal` sur un cockpit déjà vivant : (a) le relancer comme `--rebuild` (arrêt par signal vérifié puis démarrage avec le drapeau) ; (b) refuser avec un message ; (c) si le serveur vivant a déjà un terminal, rouvrir seulement P. Recommandé : (a) quand le serveur vivant n'a pas de terminal, (c) sinon ; dans le cas (c), un autre navigateur n'a pas de secret : le lanceur écrit un nouvel amorçage (O3) et ouvre Q avec celui-ci.
- **O3.** Transport du jeton d'amorçage du lanceur à Q : (a) fichier 0600 supprimé puis recréé `wx` par le lanceur, lu puis supprimé par Q à l'échange ; (b) variable d'environnement du serveur (héritée par `claude -p`, visible dans l'environnement du processus : mauvaise). **Recommandé : (a).** Garde supplémentaire : le dossier `.cache` de la sortie est dans le lab ; tout fichier préexistant est supprimé avant écriture.
- **O4.** « Une seule session » contre « le cadre se recharge » : un second onglet et un rechargement présentent le même secret. Discriminant mesuré par le spike : `sessionStorage` est partagé par le premier niveau et le cadre du MÊME onglet (`p3_ecrit_top`, `p3_iframe_meme_onglet` : `SS-st`) et absent d'un nouvel onglet (`p3_iframe_nouvel_onglet` : `ss: null`). Proposition : un identifiant d'onglet aléatoire généré par Q à l'amorçage dans `sessionStorage`, envoyé avec le flux ; même identifiant = remplace le flux précédent ; autre identifiant = « Terminal déjà ouvert ». Limite : « dupliquer l'onglet » copie `sessionStorage` dans Chrome (`[ASSUMED]`, non mesuré). Alternative : refuser tout second flux tant que le premier n'est pas fermé, avec une attente de quelques secondes avant de conclure au refus.
- **O5.** Fidélité de la reprise d'une application plein écran (Piège 5) : rognage sur frontière de caractère et double SIGWINCH, ou assumer et l'écrire au README.
- **O6.** Page P ouverte via `localhost:P` : (a) le tiroir se désactive avec un message (« Ouvrez le cockpit à l'adresse 127.0.0.1… ») ; (b) Q est aussi appelée par `localhost` (origine, `frame-src` et `frame-ancestors` doublés, stockage séparé donc amorçage séparé). Recommandé : (a). Navigateur par défaut : `open` ouvre le navigateur par défaut, qui peut être Safari ou Firefox ; le partage de stockage et le comportement du cadre ont été mesurés dans Chrome seulement (`[ASSUMED]` ailleurs).
- **O7.** Variables d'environnement ajoutées au shell (`TERM`, `COLORTERM`) : hors D-03 ; sans elles, `claude` perd ses couleurs. Faut-il les ajouter seulement si absentes ? Question à poser à Samuel si le manager n'ose pas le décider.
- **O8.** `sandbox` du cadre : `allow-scripts allow-same-origin` (UI-SPEC) rend les liens OSC 8 et ceux détectés non ouvrables ; ajouter `allow-popups allow-popups-to-escape-sandbox` pour qu'un clic ouvre un onglet `noopener`. Mesurer avant de choisir.
- **O9.** Processus de Q : même processus que `serve.mjs` (recommandé : un seul cycle de vie, `exit` et inactivité partagés) ou processus séparé (isolation mémoire de Q contre P, mais le jeton de P et celui de Q n'ont de toute façon aucun lien). L'isolation visée par D-01 est celle de l'origine du navigateur, que les deux options donnent.
- **O10.** Où ranger la clé d'état du tiroir (D-19 + UI-SPEC §8) : `localStorage` de P, clés `vf.terminal.h` et `vf.terminal.open` ; ce ne sont pas des secrets. À confirmer que la suite de non-régression « aucun cookie / localStorage seul » (`PS`, `O4` de `test-cockpit-serveur.sh` et `test-cockpit-projet.sh`) n'interdit pas ces clés (lecture à faire par le plan).
- **O11.** Le test XSS de TERM-12 : étendre `test-cockpit-chaine-xss.sh` (texte de l'exigence) ou créer `test-cockpit-terminal-xss.sh` qui reprend le lab piégé. Recommandé : la suite neuve, plus un renvoi dans l'en-tête de la suite existante (fichier de 18 Ko dont la manche prend des mutants par `sed`).

## 8. Catalogue de sondes d'audit T1 à T18

**Reconstitution.** La liste d'origine des « sondes d'audit T1-T16 du panel » n'est pas disponible sur disque. Cette table est reconstruite à partir des témoins énumérés dans `71-CONTEXT.md` (TERM-02 à TERM-12), regroupés en 16 sondes (T1 à T16), puis complétée de deux sondes ajoutées après coup à la demande du manager (T17 pour P71-D-18, T18 pour la parité F7 de l'UI-SPEC). La numérotation n'est PAS celle du panel.

Convention : « Base » = état avant tout code de la phase (`--terminal` est inconnu du lanceur, qui sort en 64 « argument inconnu », `vf-cockpit.mjs:32` ; aucun port de terminal). « Mutant » = copie jetable de la sortie ou des fichiers du module, modifiée par `sed` avec vérification que la copie a changé (« mutant sans effet » est une erreur, comme dans `test-cockpit-chaine-xss.sh`). Toute sonde négative est accompagnée de son témoin positif (une requête valide qui aboutit), faute de quoi un refus aveugle passerait pour un succès.

| T | Menace | Exigence | Sonde exécutable | Base (rouge) | Après le code (vert) | Mutant qui la fait rougir |
|---|--------|----------|------------------|--------------|----------------------|---------------------------|
| T1 | Site tiers ou page P qui atteint Q (CSRF, `no-cors`) | TERM-02 | `req.mjs` (Node `http`) : GET/POST `/flux`, `/entree`, `/taille` avec Host valide, secret valide, `Origin: http://evil.example`, puis `Origin: http://127.0.0.1:<P>` ; compter les PID de l'assistant | rouge : le serveur n'existe pas | 403 pour les deux, 0 PTY lancé ; témoin : `Origin` de Q + secret = 200/204 | M-ORIGIN (la comparaison d'Origin retirée) : `Origin` de P passe, T1 rouge `attendu 403 obtenu 204` |
| T2 | DNS rebinding | TERM-02 | mêmes requêtes avec `Host: evil.example:<Q>`, puis `Host: 127.0.0.1:<P>` | rouge idem | 403, 0 PTY ; témoin `Host: localhost:<Q>` admis pour un GET statique | M-HOST (liste d'hôtes élargie) |
| T3 | Accès sans secret, mauvais secret, sans Origin sur flux et POST | TERM-02 | requête sans en-tête de secret, secret d'une autre longueur, secret faux de même longueur ; flux et POST sans `Origin` | rouge idem | 401/403 partout, 0 PTY ; GET de page sans `Origin` = 200 | M-JETON (comparaison `===` ou secret optionnel) ; M-SANSORIGIN (POST sans Origin admis) |
| T4 | Jeton d'amorçage rejoué ou servi | TERM-02, TERM-03 | échanger l'amorçage deux fois ; le chercher dans la réponse de `GET /` de P et de Q | rouge idem | 2e échange refusé, 0 occurrence dans les corps ; fichier d'amorçage supprimé après le 1er échange, 0600 avant | M-REJEU (amorçage non consommé) ; M-SERVI (jeton écrit dans la page Q) |
| T5 | Fuite des secrets | TERM-03 | après un parcours complet (amorçage, flux, entrées), `grep` de l'amorçage et du secret dans : corps de toutes les réponses de P et de Q, 3 s de SSE (`/api/vf/events`), `.cache/serveur.log`, export (`/api/export`), tout `.vibeflow/cockpit/**`, `server.json`, `ps` du serveur (arguments), en-têtes de réponse ; `rtk proxy grep -r` | rouge idem | 0 occurrence partout ; témoin positif : le secret figure bien dans l'en-tête de la requête (compté côté client) | M-LOG (secret écrit dans `serveur.log`) ; M-URL (secret en paramètre d'URL du flux : visible dans les journaux d'accès/URL) |
| T6 | Amorçage hors fenêtre, fragment, historique, cookie, lecture depuis P | TERM-04 | CDP : `naviguer` vers `Q/#t=<amorçage>`, attendre l'arrivée sur P ; lire `history`/`location` (pas de fragment), `document.cookie` de P et de Q (vides), `Set-Cookie` dans toute réponse (0), `localStorage` de Q lu depuis P via le cadre (`SecurityError`) | rouge idem | fragment absent de l'URL et de l'historique, 0 cookie, `SecurityError` ; secret présent dans le stockage de Q en premier niveau | M-COOKIE (secret posé en cookie) ; M-FRAGMENT (`replaceState` retiré) ; M-STOCKAGE (secret posé dans `localStorage` de P) |
| T7 | Activation silencieuse | TERM-01 | sans le drapeau : `lsof`/test de connexion sur ports, route `/api/vf/terminal` (404), CSP de `/` et `/project.html` comparée à celle d'un module de base (`git archive` de la base) ; avec le drapeau : exactement un écouteur de plus, sur `127.0.0.1` | rouge : sans objet côté Q (le drapeau est inconnu) ; la comparaison de CSP est verte | CSP identique octet pour octet à la base (sous réserve de O1), 0 écouteur et 0 route de plus | M-ACTIF (terminal démarré sans drapeau) ; M-ECOUTE0 (écoute sur 0.0.0.0 : le test d'adresse d'écoute rougit) |
| T8 | CSP de P avec drapeau | TERM-05 | CSP de `/` et `/project.html` avec drapeau = CSP de base + `; frame-src http://127.0.0.1:<Q>` exact (comparaison de chaînes) ; page chargée en Chrome : cadre affiché, 0 violation | rouge idem | égalité stricte + 0 violation | M-FRAMESRC (`frame-src *` ou absent : cadre bloqué) ; M-CSPP (une directive de base modifiée) |
| T9 | CSP et cadre de Q | TERM-05 | en-têtes de `GET /` de Q : `frame-ancestors` exact, `connect-src 'self'`, `script-src` par empreintes (recalculées indépendamment), `style-src 'unsafe-inline'`, aucun `X-Frame-Options`, aucun `unsafe-eval` ; Chrome : cadre sous `sandbox="allow-scripts allow-same-origin"` : `localStorage` de Q lisible dans le cadre, `fetch` du flux, 0 violation ; `frame-ancestors 'none'` en témoin rouge | rouge idem | tous les contrôles verts | M-ANCETRES (`frame-ancestors *`) ; M-XFO (`X-Frame-Options: DENY` posé : cadre vide) ; M-EMPREINTE (script modifié après calcul : bloqué) |
| T10 | Shell mal configuré, environnement trop large | TERM-06 | session de test dont le shell écrit `env`, `pwd`, `echo $0` dans un fichier du dossier de test ; environnement du serveur avec `CLAUDECODE`, `CLAUDE_CODE_FOO`, `VF_COCKPIT_X`, une variable portant la valeur du secret, `NODE_OPTIONS=--no-warnings`, `AUTRE=ok` | rouge idem | absentes : les quatre premières ; présentes : `NODE_OPTIONS`, `AUTRE` ; `pwd` = `realpath(lab)` (tester avec un lab accessible par lien symbolique) ; `$0` = `-<shell>` (login) | M-ENVLARGE (liste blanche à la place de la liste noire) ; M-CWD (`cwd` = `process.cwd()` du serveur) |
| T11 | PTY incorrect | TERM-07 | voir T13 pour le plein écran ; ici : `ps` de l'assistant = `python3 -I …` (argument `-I`), `TIOCSWINSZ` observé par `stty size`, Ctrl-C tue le travail au premier plan et pas le shell, simulation Windows (`process.platform` surchargé) : message et 0 écouteur | rouge idem | `-I` présent ; `stty size` = taille envoyée ; shell vivant après `0x03` ; message en français | M-SANS-I (lancement sans `-I`) ; M-SIGINT (Ctrl-C tue le groupe du shell) ; M-WIN (écouteur ouvert sous Windows) |
| T12 | Sessions, orphelins | TERM-08 | (1) 2e création refusée, 0 PTY de plus ; (2) fermer le flux, rouvrir à 5 s : tampon rejoué, même PID de shell ; (3) fermer et attendre 30 s + marge : SIGHUP, shell et travail d'arrière-plan marqué morts ; (4) SIGTERM puis SIGKILL du serveur : assistant, shell, travail d'arrière-plan morts (attente bornée, `kill -0`) ; (5) `--idle-exit` réduit : le serveur survit tant qu'une session existe | rouge idem | tous vrais ; témoin : une session sans fermeture de flux survit 35 s | M-GRACE0 (grâce nulle) ; M-NOEOF (assistant qui ignore l'EOF : survivant après SIGKILL du serveur) ; M-IDLE (`occupe()` toujours faux) |
| T13 | Usage réel d'un programme plein écran | TERM-09 | §5 : programme témoin (écran alterné, 256 couleurs, truecolor, SIGWINCH, SIGINT) par le flux direct, puis par le DOM de Q en premier niveau | rouge idem | marqueurs `?1049h`, `48;5;`, `38;2;255;100;0m`, `WINCH 50x132`, `SIGINT-RECU`, retour de l'invite | M-RESIZE (le POST de taille ne fait rien : pas de `WINCH`) ; M-CTRLC (octet 0x03 filtré : pas de `SIGINT-RECU`) |
| T14 | Séquences hostiles et vendor | TERM-10 | `hostile.py` imprime OSC 52 (écriture), OSC 8, DCS, CSI 21t, DECRQSS puis `ESC[c` (DA1, témoin positif) puis lit son entrée brute pendant 1,5 s et l'écrit en hexadécimal ; Chrome : `navigator.clipboard` espionné via `Page.addScriptToEvaluateOnNewDocument` ; `sha256sum` des trois fichiers vendor contre `SHA256SUMS` et contre §1 ; aucune mention de `ClipboardAddon` dans la page Q | rouge idem | entrée du PTY = réponse à DA1 seulement ; 0 appel au presse-papiers ; sha256 égaux ; démarrage refusé si un octet du vendor change | M-DCS (gestionnaire DECRQSS non remplacé : `1b50…` arrive) ; M-WINOPT (`getWinTitle: true`) ; M-CLIP (gestionnaire OSC 52 appelant `writeText`) ; M-VENDOR (un octet de `xterm.js` modifié) |
| T15 | Frappes et sorties sur disque ou dans les flux | TERM-11 | après une session où l'on tape et affiche des marqueurs uniques (`MARQUEUR-FRAPPE-<n>`, `MARQUEUR-SORTIE-<n>`) : `rtk proxy grep -r` dans le lab entier (sortie incluse), `serveur.log`, SSE (3 s), export, dossier temporaire du serveur ; fin de session : tampon vidé (mesure de la taille mémoire du tampon via un second attachement : rejeu vide) | rouge idem | 0 occurrence ; rejeu vide après fin | M-JOURNAL (octets écrits dans `serveur.log`) ; M-TAMPON (tampon non vidé à la fin) |
| T16 | Chaîne XSS P vers Q | TERM-12 | lab piégé de `test-cockpit-chaine-xss.sh` dont la charge tente : `window.open(Q)`, `postMessage` vers le cadre, `fetch`/POST vers Q avec `FLOORPLAN_SERVER`/`VF_COCKPIT_SERVER.token` de P, lecture du stockage du cadre ; marqueurs : fichier créé par le shell (`touch` dans une session ouverte) ; témoin C0 (CSP et garde retirées) | rouge idem | 0 fichier marqueur, 0 PTY lancé par la charge ; toutes les suites existantes vertes | M-CSP-TERM (CSP de P neutralisée) ; M-ORIGINE-TERM (Q accepte l'Origin de P) : le marqueur est créé |
| T17 | Canal Q vers P (D-18) | TERM-05, TERM-12 | voir ci-dessous | rouge : écouteur absent | liste fermée respectée | M-MSG-ORIGINE, M-MSG-SOURCE, M-MSG-LISTE, M-MSG-DONNEE |
| T18 | Dérive des variables recopiées (F7) | TERM-05 | voir ci-dessous | rouge sur mutant | parité vraie | M-PARITE |

### T17 : canal Q vers P (P71-D-18)

Sonde exécutée dans Chrome sur P avec le tiroir ouvert, écouteur de P observé par un compteur posé via `Runtime.evaluate` et via l'appel d'un point d'entrée de test fourni par le module uniquement s'il est déjà public (sinon observer l'effet visible : état de la barre, tiroir fermé). Cas, chacun avec son témoin :
1. **Témoin positif.** Q (vrai cadre) envoie `etat:connecte` : la barre passe à « Connecté » ; Q envoie `toggle` : le tiroir se ferme et le focus revient à l'ouvreur.
2. **Origine tierce ignorée.** Page tierce (second serveur Node jetable sur un autre port, qui encadre ou ouvre P) envoie `toggle` : aucun effet. Variante : depuis P elle-même, `postMessage('toggle', location.origin)` (charge XSS) : `event.origin` = origine de P, ignoré.
3. **Source tierce ignorée même avec la bonne origine.** Message émis par une fenêtre autre que le cadre (une seconde fenêtre ouverte sur Q en premier niveau, dont `event.origin` est celle de Q mais `event.source` n'est pas `cadre.contentWindow`) : aucun effet.
4. **Valeur hors liste.** Cadre légitime envoie `fermer-tout`, un objet, un tableau, une chaîne de 10 000 caractères : aucun effet, aucune exception non rattrapée (journal de la console vide).
5. **Aucune donnée du shell.** Le shell affiche un marqueur unique, le test récupère tous les messages reçus par P (écouteur espion `Page.addScriptToEvaluateOnNewDocument`) et vérifie qu'ils sont tous membres de la liste fermée et qu'aucun ne contient le marqueur, le secret ou l'amorçage.
6. **`targetOrigin` exact.** Du côté de Q, `postMessage` n'est jamais appelé avec `'*'` (inspection de la page servie : 0 occurrence de `postMessage(` avec `'*'`) ; sous `localhost:P` le message n'est pas livré (comportement attendu, O6).
7. **Sens entrant fermé.** Un `postMessage` de P vers le cadre ne change rien dans Q (D-15) : Q n'a aucun écouteur `message` (0 occurrence de `addEventListener('message'` dans la page Q servie).

Mutants (chacun doit rougir le cas correspondant, trace attendue `attendu : toggle ignoré, obtenu : tiroir fermé`) : M-MSG-ORIGINE (le test de `event.origin` retiré), M-MSG-SOURCE (le test de `event.source` retiré), M-MSG-LISTE (le test d'appartenance retiré), M-MSG-DONNEE (Q joint une partie de la sortie du shell au message).

Impact sur TERM-05 : la barre d'état de P et la détection « injoignable » (aucun `ready` après 8 s) deviennent des comportements vérifiés ; l'attribut `sandbox` entre dans les assertions de T9. Impact sur TERM-12 : la chaîne XSS gagne un maillon (la charge peut émettre des messages vers P) ; T16 doit prouver qu'un message forgé par la charge, avec `event.origin` = origine de P, n'a aucun effet de sécurité (au pire elle ferme le tiroir, ce qu'elle peut déjà faire par le DOM), et qu'aucune donnée du shell ni secret ne passe jamais dans un message.

### T18 : parité des variables CSS Q contre `viewer.html` (F7)

Contrôle à ajouter à une suite NEUVE (pas à `test-cockpit-responsive.sh`, que la 69 ne touche pas mais qui est lourde) : extraire de `plugin/cockpit/skills/cockpit-moteur/assets/viewer.html` les déclarations des 25 variables listées par l'UI-SPEC §3.3 sous `:root` (sombre) et `:root[data-theme="light"]` (clair), et celles de la feuille de la page Q servie ; comparer variable par variable, valeur normalisée (espaces et casse). Les deux sources doivent contenir les 25 noms dans chaque thème (sinon rouge « variable absente », jamais « parité vraie » sur ensemble vide : `ÉCHEC ANTI-VERT-À-VIDE`).

- **Témoin positif :** sur le code livré, 25 sur 25 dans chaque thème, parité vraie.
- **Rouge sur mutant (M-PARITE, quatre variantes à jouer) :** (a) une valeur de la page Q modifiée (`--surface` de `#191919` à `#191918`) ; (b) une variable retirée de Q ; (c) une valeur de `viewer.html` modifiée dans la copie (l'amont dérive) ; (d) thème clair seul modifié. Trace : `variable --surface (sombre) : viewer.html=#191919, Q=#191918`.
- Vérifier d'abord que les 25 noms existent bien dans `viewer.html` (l'UI-SPEC cite `:root` l.33 et `:root[data-theme="light"]` l.66 ; à relire au plan : DESIGN.md PR #196 n'est pas mergé, `viewer.html` fait foi).
- Le thème de Q vient de `?theme=dark|light`, toute autre valeur donne `dark` (D-19) : ajouter les cas `theme=<script>`, `theme=` vide, `theme=LIGHT` (rouge si la page reflète la valeur ; témoin : `light` pose `data-theme="light"`). Mutant M-THEME (la valeur est insérée telle quelle dans la page).

## 9. Témoin rouge par exigence

Principe : le témoin est écrit AVANT le code, joué sur la base (ou sur le mutant nommé quand la base ne peut pas le rendre discriminant), puis vert sur le code. Format des traces (comme les suites du cockpit) : `❌ FAIL — <assertion>` suivi de `attendu: [..]` et `obtenu:  [..]`.

| Exigence | Assertion qui rougit | Rouge sur la base | Rouge sur mutant | Vert |
|----------|----------------------|-------------------|------------------|------|
| TERM-01 | `T7.1 aucune route /api/vf/terminal sans le drapeau` ; `T7.2 CSP de / identique à celle de v2.75.0` ; `T7.3 un seul écouteur sans le drapeau` | `vf-cockpit.mjs open --terminal` sort en 64 « argument inconnu : --terminal » (le test d'activation échoue sur « exit 0 attendu ») | M-ACTIF : `T7.3 attendu [1] obtenu [2]` | route 404, CSP égale, 1 écouteur ; avec le drapeau 2 écouteurs, tous sur 127.0.0.1 |
| TERM-02 | `T1.2 Origin 127.0.0.1:<P> : statut` ; `T2.1 Host de rebinding : statut` ; `T3.1 sans secret : statut` ; `T4.2 amorçage rejoué : statut` ; `T*.pty 0 PTY lancé` | pas de serveur : « connexion refusée » | M-ORIGIN : `T1.2 attendu [403] obtenu [204]` | 403/401 partout, 0 PTY, témoins positifs 200/204 |
| TERM-03 | `T5.1 amorçage et secret : 0 occurrence dans N emplacements` | sans objet | M-LOG : `T5.* attendu [0] obtenu [1] (.cache/serveur.log)` | 0 occurrence ; 0600 sur le fichier d'amorçage avant consommation |
| TERM-04 | `T6.1 fragment absent` ; `T6.2 document.cookie vide` ; `T6.3 stockage de Q illisible depuis P` | idem | M-COOKIE : `T6.2 attendu [] obtenu [vfterm=…]` | URL propre, 0 cookie, `SecurityError` |
| TERM-05 | `T8.1 CSP de P avec drapeau = base + frame-src exact` ; `T9.* directives de Q` ; `T9.5 0 violation` | idem | M-FRAMESRC : `T8.1 attendu [..frame-src http://127.0.0.1:<Q>] obtenu [..]` ; M-XFO : `T9.* cadre vide` | égalités exactes |
| TERM-06 | `T10.1 variables retirées` ; `T10.2 variables conservées` ; `T10.3 pwd = realpath(lab)` | idem | M-ENVLARGE : `T10.2 attendu [NODE_OPTIONS=…] obtenu []` | présence/absence correctes |
| TERM-07 | `T11.1 ligne de commande de l'assistant contient -I` ; `T11.2 taille` ; `T11.3 shell vivant après Ctrl-C` ; `T11.4 Windows : 0 écouteur` | idem | M-SANS-I, M-SIGINT, M-WIN | verts |
| TERM-08 | `T12.1`..`T12.5` | idem | M-GRACE0 : `T12.2 attendu [même PID] obtenu [nouvelle session]` ; M-NOEOF : `T12.4 survivants : 3` | verts avec attente bornée, aucun survivant |
| TERM-09 | `T13.1`..`T13.5` marqueurs | idem | M-RESIZE : `T13.3 attendu [WINCH 50x132] obtenu [(absent)]` | marqueurs présents ; recette humaine pour `claude` |
| TERM-10 | `T14.1 entrée du PTY = DA1 seulement` ; `T14.2 presse-papiers : 0 appel` ; `T14.3 sha256 du vendor` | idem | M-DCS : `T14.1 attendu [DA1] obtenu [DA1 + 1b50…]` | verts |
| TERM-11 | `T15.1 0 occurrence des marqueurs hors flux de session` ; `T15.2 rejeu vide après fin` | idem | M-JOURNAL, M-TAMPON | verts |
| TERM-12 | `T16.1 aucun marqueur créé par le shell` ; `T16.2 suites existantes vertes` ; `T17.*` ; `T18.*` | idem | M-CSP-TERM, M-ORIGINE-TERM ; M-MSG-* ; M-PARITE | 0 marqueur, suites existantes vertes |

Remarque sur « rouge sur la base » : comme le code de la phase n'existe pas sur la base, ce rouge-là prouve seulement que la suite détecte l'absence. La capacité à rougir sur un défaut précis est portée par les mutants ; c'est le sens de la leçon « une preuve doit pouvoir rendre rouge » (mémoire du dépôt) et celui du témoin positif de chaque sonde négative.

## 10. Exemples de code vérifiés

### Remplacement du gestionnaire DECRQSS et des options sûres (côté Q)

```js
// Source : API publique, typings/xterm.d.ts:1835 (registerDcsHandler) du tarball @xterm/xterm 6.0.0 ;
// comportement natif : src/common/InputHandler.ts:381 (DECRQSS répond via onData).
const term = new Terminal({
  windowOptions: {},                        // aucun CSI t : pas de CSI 21t, pas de manipulation de fenêtre
  macOptionIsMeta: false,                   // UI-SPEC : { [ ] | \ ~ @ au clavier français macOS
  linkHandler: { allowNonHttpProtocols: false, activate: (e, url) => ouvrirSurClic(e, url) }  // jamais confirm() ni ouverture implicite
});
term.parser.registerDcsHandler({ intermediates: '$', final: 'q' }, () => true);   // DECRQSS avalé : rien ne repart en entrée
// OSC 52 : aucun addon presse-papiers n'est chargé, aucun gestionnaire n'existe (InputHandler.ts:319-323)
```

### Lancement de l'assistant (côté Node)

```js
// Forme à suivre ; les fichiers du lab ne sont jamais la source de l'assistant (leçon M3 de 67-SECURITY.md)
const pty = spawn('python3', ['-I', path.join(scriptsDir, 'vf-cockpit-pty.py'), String(rows), String(cols)], {
  cwd: realLab, env: envShell(process.env), stdio: ['pipe', 'pipe', 'pipe', 'pipe']   // 0 entrée, 1 sortie, 2 état, 3 contrôle
});
// pas de detached : l'assistant meurt avec le serveur (EOF de stdin) ; le contrôle : pty.stdio[3].write(`R ${rows} ${cols}\n`)
```

### Contrôle de parité des variables (T18, squelette)

```js
// lit les déclarations "--nom: valeur;" sous un sélecteur donné ; refuse l'ensemble vide
const decl = (css, sel) => Object.fromEntries([...(new RegExp(sel.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\s*{([^}]*)}').exec(css)?.[1] || '').matchAll(/(--[\w-]+)\s*:\s*([^;]+);/g)].map((m) => [m[1], m[2].trim().toLowerCase()]));
```

## 11. État de l'art

| Ancienne approche | Approche retenue | Pourquoi |
|-------------------|------------------|----------|
| WebSocket pour un terminal web | `fetch()` en flux et POST | l'événement `upgrade` de Node court-circuite Host/Origin/jeton (D-09) |
| Moteur canvas ou WebGL de xterm | moteur DOM natif de xterm 6.0 (le canvas a été retiré) | rien à vendoriser de plus ; mais `<style>` dynamiques (CSP) et `lineHeight: 1` pour les traits |
| Cookie de session pour le terminal | secret en `localStorage` de l'origine Q | les cookies ne sont pas cloisonnés par port (D-13, mesuré) |
| `node-pty` | `pty.fork` Python | pas de compilation native, pas de dépendance |

## 12. Journal des hypothèses

| # | Affirmation | Section | Risque si fausse |
|---|-------------|---------|------------------|
| A1 | Sous `sandbox="allow-scripts allow-same-origin"`, le `localStorage` de Q, le `fetch` vers Q et le `postMessage` vers P fonctionnent comme dans le spike sans `sandbox` | §4.4, T9, T17 | le tiroir ne s'authentifie pas ; revoir le `sandbox` (O8) |
| A2 | Un gestionnaire DCS enregistré par l'API publique passe avant le natif et avale DECRQSS | Piège 1 | TERM-10 non tenu ; filtrer `onData` en plus |
| A3 | Chrome headless Linux n'a aucun pointeur (`pointer: none`) | §5 | gestes souris des tests à revoir |
| A4 | Un autre utilisateur de la machine lit les arguments d'un processus par `ps` | §4.2 | contrainte mono-utilisateur (M7) déjà assumée |
| A5 | bash et zsh envoient SIGHUP à leurs travaux d'arrière-plan à la fermeture | §4 patron 2 | survivants de T12 ; ajouter un balayage par session |
| A6 | « Dupliquer l'onglet » copie `sessionStorage` dans Chrome | O4 | un onglet dupliqué pourrait voler la session |
| A7 | Le comportement du cadre et du stockage est identique sous Safari et Firefox | O6 | tiroir cassé selon le navigateur par défaut |
| A8 | `SHELL` peut manquer dans un environnement de service | §4.1 | terminal qui ne démarre pas sans repli |
| A9 | Rogner le tampon sur frontière de caractère et forcer un double SIGWINCH redessine une application plein écran après rattachement | Piège 5 | reprise visuellement fausse |
| A10 | Les messages Q vers P ne passent pas si P est chargé via `localhost:P` | §4.4 | message silencieusement perdu ; état de la barre faux |

## 13. Environnement et vérifications (`<verify>`)

### Disponibilité

| Dépendance | Requis par | Disponible | Version | Repli |
|------------|-----------|------------|---------|-------|
| Node | serveur, suites | oui | 26.5.0 (poste) ; 24 en CI | |
| `python3` | assistant PTY | oui | 3.14.6 dans le PATH ; `/usr/bin/python3` = 3.9.6 (macOS) | assistant compatible 3.9 ; Windows : indisponible (D-07) |
| Chrome | suites navigateur | oui | 156 (poste), `google-chrome` sur le runner | simulation fidèle ou saut annoncé |
| `claude` | recette TERM-09 | oui | 2.1.317 (poste) | recette humaine seulement |
| `timeout`, `gtimeout` | | absents | | boucles bornées en shell, échéances dans les clients Node (`VF_CDP_ECHEANCE_MS`) |
| `$SHELL` | shell du terminal | `zsh` (poste) | | repli `/bin/sh` |

### Contraintes à respecter dans chaque `<verify>`

- **CI Ubuntu 26.04 = coreutils uutils** : `ln -sh` et `mv -h` y affichent l'aide (mémoire « CI sous Ubuntu 26 ») ; n'utiliser ni l'un ni l'autre, ni options spécifiques BSD/GNU de `sed -i` (employer `sed -i.bak` comme les suites existantes), ni `stat -f`/`stat -c`.
- **zsh ET bash** : `for c in $var` ne découpe pas sous zsh (mettre les listes dans un tableau ou une boucle `while read`) ; pas de `mapfile` (bash 3.2 de macOS) ; shebang `#!/usr/bin/env bash`, `set -uo pipefail`.
- **Pas de `timeout`** : attentes bornées par boucle (`for _ in $(seq 1 100)`) ou par échéance du client Node.
- **Tuer par PID enregistré, jamais par motif** : `vf_hyg_stop <pid>` ; jamais `pkill -f`, jamais `awk` sur `ps` hors `hygiene.sh`.
- **Pas de `| tail`/`| head` sur un test qui peut bloquer** (le tube masque l'échéance et laisse des survivants) ; rediriger vers un fichier et lire le fichier.
- **rtk** : `rtk proxy grep`, `rtk proxy ls`, `rtk proxy git` quand un compte compte (`wc -l` donne 1 sur sortie vide).
- **Assistant Python lancé `python3 -I`**, et tout programme témoin aussi. Aucun `python3 -c` ni `python3 -` inline dans un script livré hors `*/tests/*` (`scripts/check-python-isolation.sh` : les scripts livrés doivent isoler ; les `.py` eux-mêmes ne sont pas balayés ; les suites `*/tests/*` ne le sont pas non plus, `[VERIFIED: en-tête de scripts/check-python-isolation.sh]`).
- **Aucun chemin absolu de machine** dans un fichier versionné (`scripts/check-machine-paths.sh`, `/Users/<compte>/…`, `/home/<compte>/…`) : la présente recherche, les plans, les suites, les messages du module. Utiliser des chemins relatifs, `$WORK`, `$SCRIPTS`, ou `<lab>`.
- **Gates à rejouer en fin de phase** : `bash scripts/check-version-sync.sh` (la phase ne bumpe rien : doit rester vert), `bash scripts/check-machine-paths.sh`, `bash scripts/check-python-isolation.sh`, `bash plugin/software-architecture/scripts/check-file-size.sh <fichiers neufs>` (`--all` ne balaie que `src app lib features`, donc ne voit pas `plugin/` : l'invoquer sur les fichiers neufs explicitement ; `[VERIFIED: check-file-size.sh, SCAN_DIRS=(src app lib features)]`), `bash plugin/cockpit/amont/synchro.sh verifier` (doit dire « amont retrouvé à l'octet » après l'ajout des `AJOUT` et du diff régénéré), `bash plugin/cockpit/scripts/tests/test-cockpit-vendor.sh`, `bash plugin/_internal/tests/test-vibeflow-update-cockpit.sh`.
- **`check-gate-touche`** : surface réelle relue cette session (`scripts/check-gate-touche.sh:216-226`, citation) : `plugin/conductor/scripts/check-*.sh`, `scripts/check-*.sh`, `plugin/conductor/scripts/tests/test-*.sh`, `scripts/tests/test-*.sh`, `.github/workflows/ci.yml`, `scripts/hooks/*`, `plugin/conductor/scripts/tests/fixtures/*`, `scripts/tests/fixtures/*`. Les suites `plugin/cockpit/scripts/tests/test-cockpit-*.sh` n'en font PAS partie : aucun trailer `Gate-Touche:` n'est requis tant que le plan ne touche ni `scripts/check-*.sh`, ni `.github/workflows/ci.yml`, ni `scripts/tests/`. Sans surface touchée la garde rend rc 3 (« vert à vide interdit ») et c'est son comportement normal. Si le plan ajoute une étape à `ci.yml`, le trailer devient obligatoire, avec la forme `Gate-Touche: .github/workflows/ci.yml — <raison de 10 caractères non blancs au moins>`.
- **`check-ajout-retrait`** surveille `plugin/<module>/scripts/{check,guard}-*.sh`, `rules/*.md`, `SKILL.md`, ADR et CLAUDE.md : la phase n'ajoute rien de ce genre (les suites s'appellent `test-*.sh`), donc aucun trailer `Ajout-Retrait:`.
- **Hygiène** : chaque suite source `tests/hygiene.sh` après la définition de `WORK`, appelle `vf_hyg_init`, `vf_hyg_stop`, `vf_hyg_assert`, finit par le bilan « anti-vert-à-vide ».
- **CI** : les nouvelles suites sont découvertes et réparties automatiquement sur les 7 shards (`scripts/ci-shard-suites.sh`) ; pas besoin de les déclarer, mais chacune doit tenir en quelques dizaines de secondes (la grâce de 30 s se teste avec une grâce réduite par une variable d'environnement de test, par exemple `VF_COCKPIT_TERM_GRACE_MS`, documentée dans le module comme réglage de test et ignorée hors valeur entière valide).

## 14. Architecture de validation (Nyquist)

### Cadre de test

| Propriété | Valeur |
|-----------|--------|
| Cadre | suites bash du module (`assert_eq` / `assert_has`, bilan anti-vert-à-vide), clients Node sans dépendance, Chrome headless par `chrome-session.mjs` (CDP) |
| Fichier de configuration | aucun ; découverte par `find plugin scripts -path '*/tests/test-*.sh'` |
| Commande rapide | `bash plugin/cockpit/scripts/tests/test-cockpit-terminal-serveur.sh` (contrôles de Q, sans navigateur ni PTY) |
| Commande complète | `for f in plugin/cockpit/scripts/tests/test-cockpit-*.sh; do bash "$f" > "$TMPDIR/$(basename "$f").out" 2>&1; echo "$? $f"; done` (14 suites existantes + les suites neuves ; à adapter en tableau si zsh) |

### Carte exigence vers test

| Exigence | Comportement | Type | Commande automatisée | Existe |
|----------|--------------|------|----------------------|--------|
| TERM-01 | activation, CSP identique | intégration | `bash plugin/cockpit/scripts/tests/test-cockpit-terminal-activation.sh` | à créer (Wave 0) |
| TERM-02 | Host, Origin, secret, 0 PTY | intégration | `bash …/test-cockpit-terminal-serveur.sh` | à créer |
| TERM-03 | aucune fuite | intégration | `bash …/test-cockpit-terminal-serveur.sh` (famille T4, T5) | à créer |
| TERM-04 | amorçage, fragment, cookie | navigateur | `bash …/test-cockpit-terminal-navigateur.sh` | à créer |
| TERM-05 | CSP de P et de Q, cadre, `sandbox`, parité | navigateur | `bash …/test-cockpit-terminal-navigateur.sh` | à créer |
| TERM-06 | environnement, cwd | intégration | `bash …/test-cockpit-terminal-pty.sh` | à créer |
| TERM-07 | PTY, `-I`, resize, Ctrl-C, Windows | intégration | `bash …/test-cockpit-terminal-pty.sh` | à créer |
| TERM-08 | session, grâce, orphelins | intégration | `bash …/test-cockpit-terminal-session.sh` | à créer |
| TERM-09 | plein écran témoin ; `claude` | intégration + recette | `bash …/test-cockpit-terminal-pty.sh` ; recette humaine macOS | à créer |
| TERM-10 | séquences hostiles, vendor | navigateur + fichiers | `bash …/test-cockpit-terminal-xterm.sh` | à créer |
| TERM-11 | rien sur disque ni dans les flux | intégration | `bash …/test-cockpit-terminal-session.sh` (famille T15) | à créer |
| TERM-12 | chaîne XSS, non-régression | navigateur + toutes les suites | `bash …/test-cockpit-terminal-xss.sh` ; les 14 suites existantes | à créer / existantes |

### Cadence d'échantillonnage

- Par commit de tâche : la suite de la famille touchée (rapide).
- Par vague : toutes les suites `test-cockpit-terminal-*` plus `test-cockpit-securite.sh`, `test-cockpit-reseau.sh`, `test-cockpit-serveur.sh`, `test-cockpit-vendor.sh`, `test-cockpit-assemblage.sh`, `test-cockpit-chrome-fr.sh`.
- Avant `/gsd-verify-work` : toutes les suites du module, les gates de §13, `synchro.sh verifier`, puis la recette humaine de TERM-09 sur macOS (et le contrôle visuel de l'UI-SPEC §15).

### Lacunes de la Wave 0

- [ ] `terminal-aux.mjs` (client HTTP de test, flux, lecture de `server.json`) et `temoins/{plein-ecran.py, hostile.py, recepteur.py}`
- [ ] les sept suites `test-cockpit-terminal-*.sh`
- [ ] vendor xterm (copie, `SHA256SUMS`, `AJOUT`, licences) et mise à jour de V2 dans `test-cockpit-vendor.sh`
- [ ] une extension prudente de `chrome-session.mjs` seulement si un besoin réel apparaît (le plan recommandé n'en a pas : voir §5, niveau 2)

## 15. Domaine de sécurité

### Catégories ASVS applicables

| Catégorie | S'applique | Contrôle standard |
|-----------|-----------|-------------------|
| V2 Authentification | oui | amorçage à usage unique échangé contre un secret de session, comparaison en temps constant |
| V3 Gestion de session | oui | secret renouvelé à chaque démarrage, stockage hors cookie, session unique |
| V4 Contrôle d'accès | oui | Host, Origin et secret sur chaque requête ; aucun shell avant authentification |
| V5 Validation des entrées | oui | corps bornés, taille (lignes et colonnes) validée comme entiers bornés, `theme` en liste fermée, messages en liste fermée |
| V6 Cryptographie | oui | `crypto.randomBytes`, `timingSafeEqual` ; rien d'écrit à la main |
| V7 Journalisation | oui | rien de la session dans les journaux (TERM-11) |
| V14 Configuration | oui | CSP de P et de Q, `frame-ancestors`, `sandbox`, `nosniff` |

### Menaces connues pour cette pile

| Motif | STRIDE | Mitigation standard |
|-------|--------|---------------------|
| POST `no-cors` de P vers Q | Tampering | contrôle de l'Origin et du secret côté Q (mesuré F3 du spike) |
| DNS rebinding | Spoofing | liste d'hôtes exacte |
| Détournement de WebSocket (CVE-2023-26114, code-server) | Elevation | pas de WebSocket (D-09) |
| Réponses de terminal injectées dans l'entrée (DECRQSS, CSI 21t, OSC) | Tampering | gestionnaire DCS de remplacement, `windowOptions` vide, pas d'addon presse-papiers |
| Fuite de secret par cookie, URL, journal | Information disclosure | stockage `localStorage` de Q, en-tête, jamais journalisé |
| Charge exécutée dans P (XSS stockée) qui pilote Q | Elevation | origine distincte, secret inaccessible depuis P, contrôles de Q, canal Q vers P à liste fermée |
| Processus survivants après arrêt | Denial of service / Elevation | EOF du tube, SIGHUP puis SIGKILL du groupe |
| Fichier d'amorçage préplacé ou lien symbolique par un lab hostile | Spoofing | suppression avant écriture, création `wx` en 0600 |
| Extension de navigateur sur `127.0.0.1` | Information disclosure | hors de portée du serveur, écrit au README (limite de fond du contexte) |

## 16. Sources

### Primaires (confiance haute, lues ou rejouées cette session)

- `71-CONTEXT.md` (état du 2026-11-03 20h01) et `71-UI-SPEC.md` (F1 à F8, §3.3, §13) : décisions et spécifications.
- `plugin/cockpit/skills/cockpit-moteur/assets/serve.mjs` l.1-225, 480-611 ; `plugin/cockpit/scripts/vf-cockpit.mjs`, `vf-cockpit-server.mjs`, `vf-cockpit-build.mjs`, `vf-cockpit-paths.mjs`, `vf-cockpit-rename.mjs`, `vf-cockpit-fr-inventaire.mjs` (en-tête et `MARQUEURS_FR`).
- `plugin/cockpit/amont/SYNCHRO.md`, `amont/synchro.sh`, `skills/cockpit-moteur/VENDORED.txt`, `LICENCES-TIERCES.txt`.
- Suites : `tests/chrome-session.mjs`, `chrome-cdp.mjs`, `hygiene.sh`, `test-cockpit-chaine-xss.sh`, `test-cockpit-vendor.sh`, `test-cockpit-reseau.sh`, `test-cockpit-securite.sh` (en-tête et familles), `test-cockpit-assemblage.sh`, `test-cockpit-chrome-fr.sh`.
- Gates : `scripts/check-gate-touche.sh`, `check-python-isolation.sh` (en-tête), `check-machine-paths.sh` (en-tête), `check-version-sync.sh`, `scripts/ci-shard-suites.sh`, `plugin/software-architecture/scripts/check-file-size.sh`, `plugin/conductor/scripts/check-ajout-retrait.sh` (en-tête), `.github/workflows/ci.yml` (jobs).
- `67-SECURITY.md` : modèle de menace, corrections et témoins de la Phase 67.
- Branche `feat/phase-69-suivi-travail` (lecture seule, `git diff 7370d604..`) : fichiers touchés par la 69, diff de `serve.mjs`, `vf-cockpit-server.mjs`, `VENDORED.txt`, suites reseau et securite ; plans de la 69 (`files_modified`).
- Tarballs `@xterm/xterm` 6.0.0 et `@xterm/addon-fit` 0.11.0 du prototype de la mission : `src/common/InputHandler.ts`, `src/browser/renderer/dom/DomRenderer.ts`, `src/browser/Viewport.ts`, `src/browser/OscLinkProvider.ts`, `typings/xterm.d.ts`, sha256 recalculés.
- Prototype PTY de la mission (hors dépôt), rejoué sous Python 3.14.6 et 3.9.6 ; spike de cadre iframe (résultats `out1.json` : cadre, `frame-src`, `frame-ancestors`, cookies, `localStorage`, `sessionStorage`, transport, `no-cors`) ; programme témoin de §5 écrit et rejoué.
- `gsd-tools query package-legitimacy check` et `npm view` : verdicts OK pour les deux paquets xterm.

### Secondaires et tertiaires

Aucune recherche web n'a été nécessaire : les décisions externes (CVE-2023-26114, comportement de `confirm` dans OscLinkProvider) viennent des textes verrouillés ou du code lu. La classe de CVE de code-server est citée par D-09, non rejouée.

## Métadonnées

**Répartition de la confiance :**
- Pile standard : haute (versions, sha256, légitimité et contenu vérifiés).
- Architecture : haute pour les branchements et les contrôles ; moyenne pour `sandbox` (A1) et la reprise (A9).
- Pièges : haute pour DECRQSS, CSI 21t, `<style>`, X-Frame-Options, localhost ; moyenne pour la reprise du plein écran.

**Date de recherche :** 2026-11-03
**Valable jusqu'à :** 2026-11-17 (la 69 va être mergée et déplacera les numéros de ligne de §2.2 et le conflit B7 ; xterm 6.1 est en bêta)

## RESEARCH COMPLETE
