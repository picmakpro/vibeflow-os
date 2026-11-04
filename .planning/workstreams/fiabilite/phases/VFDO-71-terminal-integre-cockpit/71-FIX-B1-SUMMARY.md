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

## Correction documentaire (après B2 et B3, HEAD `502b354b`)

Les phrases F3, F4, P71-D-26, P71-D-28 du README et du CHANGELOG étaient écrites avant B2 et B3 ; elles sont réalignées sur le code livré
(`plugin/cockpit/`, chemins relatifs à ce dossier). Vérifications :

| Phrase | Preuve |
|---|---|
| Bandeau « Annuler / Coller », focus sur « Annuler » | `scripts/vf-cockpit-terminal-vue.mjs:76-77` |
| Échap annule ; un nouveau collage abandonne l'ancien | `scripts/vf-cockpit-terminal-client.mjs:97` ; `:81` (`abandonner()` en tête de `soumettre`) |
| Tab puis Entrée : boutons natifs, aucune touche de confirmation directe | `scripts/vf-cockpit-terminal-vue.mjs:76` (deux `bouton`) ; `71-FIX-B3-SUMMARY.md:17` ; `scripts/vf-cockpit-terminal-client.mjs:97` (seule touche écoutée : Échap) |
| Une ligne simple passe, retour à la ligne ou contrôle (dont ESC, Tab) confirmé | `scripts/vf-cockpit-terminal-client.mjs:77,83` (`SUR`, `term.paste`) |
| Glisser-déposer couvert | `scripts/vf-cockpit-terminal-client.mjs:91-96` (`dragover`, `drop`, `beforeinput`) |
| Popup ou ouverture seule : « Terminal indisponible » | `scripts/vf-cockpit-terminal-client.mjs:16,47` ; `scripts/vf-cockpit-terminal-vue.mjs:20` |
| Attente de la police, 2,5 s au plus | `scripts/vf-cockpit-terminal-client.mjs:13,52-55` |
| Pastille tactile à 44 px | `scripts/vf-cockpit-terminal-tiroir-style.mjs:47` |
| Arrêt de la session : SIGHUP, grâce 3 s, SIGKILL des membres relevés ; `setsid` et double fork survivent | `skills/cockpit-moteur/terminal/vf-cockpit-pty.py:15-19,34,195-221` |
| Relevé par `/proc` puis `ps` en chemin absolu ; repli sur les groupes | `vf-cockpit-pty.py:114-122,130-152` ; `71-FIX-B2-SUMMARY.md:12,32` |
| Marge de fermeture 6 s | `scripts/vf-cockpit-terminal-session.mjs:22` |
| `python3` en chemin absolu, éléments relatifs ou vides écartés ; un élément absolu du lab reste consulté | `scripts/vf-cockpit-terminal-session.mjs:28-35,73` ; `71-FIX-B2-SUMMARY.md:30` |
| Contre-pression 429 (256 Kio), octets gardés, réessai à 100 ms | `scripts/vf-cockpit-terminal-session.mjs:21,120` ; `scripts/vf-cockpit-terminal-client.mjs:109` |
| 503 pendant la fermeture, puis « Reconnexion… » | `scripts/vf-cockpit-terminal-session.mjs:105` ; `scripts/vf-cockpit-terminal-client.mjs:141,174` ; `scripts/vf-cockpit-terminal-vue.mjs:23` |
| B1-1 : PID étranger vivant, code 5 sur `open` et `stop`, message | `scripts/vf-cockpit.mjs:53-54,69,173,189` |
| Marche à suivre (`ps -o command=`, suppression de `server.json`) | `scripts/vf-cockpit.mjs:43,69` |

Retiré du README : « un travail d'arrière-plan d'un shell qui ne relaie pas SIGHUP (`dash`) peut survivre » (A5) : l'arrêt vise désormais la session, plus le relais de SIGHUP ; `vf-cockpit-pty.py:195-221`.
