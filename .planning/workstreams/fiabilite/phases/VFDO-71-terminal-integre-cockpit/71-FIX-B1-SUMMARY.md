# 71-FIX-B1 — correction ciblée de sécurité, lot B1 (lanceur et amorçage)

Phase 71, terminal intégré. Correctifs validés par Samuel au titre d'ADR-031 : P71-D-25 (F1) et P71-D-27 (F6), validation de Samuel
(AskUserQuestion, session principale Claude Code, 2026-11-04). Base : `c00d534a`. Périmètre tenu : `vf-cockpit.mjs`,
`vf-cockpit-terminal-amorce.mjs`, `vf-cockpit-terminal.mjs` (balayage de la page), suites `-lanceur.sh` et `-serveur.sh`, README et CHANGELOG
du module. Aucun fichier des lots B2 et B3 touché.

## F1 (majeur) — le lanceur n'ouvre jamais une adresse lue dans le lab

Cause : `serveurVivant` ne vérifiait que `vivant(pid)` (un PID 1 est « vivant », `EPERM`) et le lanceur remettait `terminal.url` du fichier
d'état tel quel à l'ouvreur. Correctif : `serveurVivant` ne lit que des ports (`^[0-9]{1,5}$`, 1..65535 ; `terminal.url` n'est retenue que
si elle a exactement la forme `http://127.0.0.1:<port>`) et reconstruit toute adresse ; l'ouverture de Q exige en plus `estNotre` (le processus
de `server.json` est le `serve.mjs` de cette sortie). Un état invalide rend « pas de serveur ».

- Témoin rouge sur `c00d534a` (lab planté, ouvreur factice, copie de l'arbre au commit) : `rc=0`, argv de l'ouvreur =
  `file:///System/Applications/Calculator.app/#t=<64 hex>`. Même scénario sur le correctif : `rc=5`, argv vide, état planté intact.
- Suite `-lanceur.sh` sur `c00d534a` : L12a, L12b et les cinq L12c rouges (22 rouges au total, tous des assertions nouvelles).
- Vert : `-lanceur.sh` 61 PASS / 0 FAIL.
- Mutants (rougissent) : M-F1-PID (`estNotre` remplacé par `true`, L12a), M-F1-VALID (port non validé, adresse du lab reprise, L12b).
- Cas planté couverts : PID étranger + `file:///…` ; PID étranger + `http://127.0.0.1:1235` ; serveur à nous + `file:///…`,
  `http://127.0.0.1:80@evil.example`, `:99999`, `:1235/x`, `http://evil.example:1235`, `:0x10`.

## F6 (P71-D-27) — l'amorçage n'est plus dans l'argv, il expire en 60 s

- Le lanceur écrit `.cache/terminal-ouvrir.html` (0600, suppression préalable puis création exclusive, aucun lien suivi) : une redirection
  `meta refresh` vers `http://127.0.0.1:<Q>/#t=<amorçage>` ; l'ouvreur ne reçoit que ce chemin. Échec d'écriture : amorçage effacé, rien
  n'est ouvert (jamais de repli vers une adresse en argv).
- Le serveur du terminal retire la page dès l'échange réussi de l'amorçage, la balaie (tous les 2 s, minuterie `unref`) 60 s après sa création
  si elle n'est jamais lue, et la retire à l'arrêt.
- `consommerAmorce` refuse un amorçage de plus de 60 s (`mtime` du fichier, horloge injectable `{ maintenant }`) ; un fichier daté du futur
  est refusé aussi. Les témoins reculent la date du fichier (`utimes`), jamais un vrai `sleep 60`.
- Témoin rouge : course de `p9.mjs` de l'auditeur (copie avec le lanceur de `c00d534a`) : amorçage lu dans `ps` après 926 ms, échange
  200, marqueur créé par le shell du compte. Sur le correctif : « amorçage jamais vu dans ps » (fenêtre de 12 s, `rc` du lanceur 0).
- Suite `-serveur.sh` sur `c00d534a` : T4.9 (61 s, 1 h), T4.10 (page retirée à l'échange), T4.11 (balayage) rouges. Vert : 208 PASS / 0 FAIL.
- Mutants : M-EXPIRE (`age <= DUREE_AMORCE_MS` → `true`), M-RETIRE (page non retirée à l'échange), M-BALAI (balayage neutralisé),
  M-ARGV (adresse avec amorçage en argv), M-PAGE-MODE (0666 sous umask 022), M-PAGE-LIEN (sans suppression préalable, sans `wx`, sans la
  garde `verifierSortie`) : tous rouges.
- Page jamais en 0644 : L6/L13 mesurent 600 ; la page n'existe plus après l'échange (L13) et après 60 s (L13, T4.11).
- Linux : `xdg-open <fichier local>` est le même appel qu'`open <fichier>` côté lanceur (chemin seul en argv) ; non exécuté sur un poste
  Linux, l'ouvreur factice `xdg-open` des suites en vérifie la forme. Écrit au README (A4).

## Documentation

README et CHANGELOG du module : F5 (Q sans écouteur `message` propre, écouteur interne du vendor, P71-D-15 reformulée), F6 et sa limite
résiduelle (lisible d'un processus du même compte 60 s au plus), F8 (réponses de format fixe réinjectées), P71-D-28 (`nohup` et `disown`
tués, `setsid` limite), P71-D-26 (confirmation des collages multi-lignes), F3 et F4 (une phrase chacun, d'après P71-D-25). Les phrases F3,
F4, P71-D-26 et P71-D-28 décrivent le comportement validé que livrent les lots B2 et B3 : elles ne sont pas vérifiées par B1.

## Suites rejouées

`-lanceur.sh` 61/0 · `-serveur.sh` 208/0 · `-activation.sh` 40/0 · `check-machine-paths.sh` ✓ · `check-file-size.sh --all` ✓ ·
`check-python-isolation.sh` ✓.

## Point à décider

Un `server.json` planté qui désigne un PID vivant étranger continue de faire sortir `open` en code 5 (« PID non reconnu », garde L11 de la
67, M3) : rien n'est signalé, rien n'est ouvert, mais le lanceur ne démarre pas tant que le fichier n'est pas supprimé. Je ne l'ai pas
changé (comportement testé de longue date) ; l'ignorer et démarrer un serveur neuf serait possible, au prix de L11, L11b et M-LEURRE-TERMINAL.
