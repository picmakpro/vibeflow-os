# 68-FIX-MOD — trace des témoins rouges et verts (correction ciblée du mod vf-signal)

Poste : Claude Code 2.1.318, `claude plugin test plugin`, tête de départ `69060360`. Sorties brutes dans le scratchpad (`fix-mod-*.out`).
Identifiants de témoins préfixés `FX-` (verdict.sh refuse un doublon). Un témoin rouge est joué sur le code NON corrigé.

## ST-1 — sans `cockpit=`, le mod travaille quand même (majeur)

Fichier : `plugin/cockpit/signal/tests/session-sans-registre.test.tsx`. Un lab sans ligne `cockpit=` joue un tour complet
(`session.start`, `turn.start`, `tool.call` Bash `driver-lock.sh`, `agent.spawn`, `turn.complete`, `command.run brief`) et espionne
`process.run`, `clock.every`, `ui.invalidate`, `state.set`, `agent.list`, `session.usage`. Le témoin positif FX-1d (registre
`cockpit=`) prouve que les espions voient bien le travail du mod.

ROUGE (tête non corrigée, `fix-mod-st1-rouge.out`) :

| témoin | assertion | attendu | obtenu |
| --- | --- | --- | --- |
| FX-1a | process.run lancés | `[]` | 2 × `node …/cockpit/scripts/vf-cockpit-signal.mjs /lab` |
| FX-1b | argv contenant `vf-cockpit-signal.mjs` (vrai nom) | `[]` | 2 lancements |
| FX-1e | minuteries posées | 0 | 1 |
| FX-1f | `ui.invalidate` | 0 | 1 |
| FX-1g | `state.set` | 0 | 13 |
| FX-1h | `[agent.list, session.usage]` | `[0, 0]` | `[2, 1]` |
| FX-1c | `/vf-signal brief` | `{ text: 'engine' }` | vert (le gating de `command.run` existe déjà ; sa mutation est jouée plus bas) |

VERT (`fix-mod-st1-vert.out`, 71 pass / 0 fail) : `register.tsx` porte `if (!actif) return next(e)` en tête de `turn.start`,
`turn.complete`, `agent.spawn`, `skill.prompt`, `tool.call` et `classic.PreToolUse` (les autres hooks l'avaient déjà).

Mutants tués (un gate retiré à la fois, suite rejouée) :

| mutant | témoins rouges |
| --- | --- |
| gate de `command.run` retiré | FX-1a, FX-1g, FX-1h, FX-1b, FX-1c |
| gate de `tool.call` retiré | FX-1a, FX-1g, FX-1b |
| gate de `turn.start` retiré | FX-1e, FX-1f, FX-1g |
| gate de `agent.spawn` retiré | FX-1g, FX-1h |

## ST-3, ST-4, ST-5, ST-6 — témoins rouges (tête avec le correctif ST-1, sortie `fix-mod-st346-rouge.out` : 76 pass / 19 fail, dont 0 hors FX-)

Fichiers : `tests/lab-fix.ts` (faux lab pilotable : émetteur, bash, lanceur, toasts, copies), `tests/socle-fix.test.tsx` (ST-5, ST-6a/b),
`tests/citation-controles.test.tsx` (ST-3, ST-4, ST-6c/d).

| témoin | assertion | attendu | obtenu (tête non corrigée) |
| --- | --- | --- | --- |
| FX-5a0..FX-5a6 | signal sans `verrous.liste`, `jalons`, `layout`, `equipe`, `n` numérique, `avancement.plans`, `arbres[].label` : texte « sortie de l'émetteur illisible » | texte trouvé | `$.ui.mount: no implementation for ui.render` (le rendu lève) pour a0..a3 ; texte absent pour a4..a6 |
| FX-5b | émetteur rejeté `EACCES` : `/émetteur non lancé \(EACCES/` et pas `/délai dépassé/` | trouvé / absent | texte absent (la pane dit « délai dépassé ») |
| FX-5c | lanceur rejeté `EACCES` : idem `lanceur non lancé` | idem | idem |
| FX-6a | lanceur rejeté `timed out after 60000 ms` : « lanceur sans réponse (délai dépassé) » | trouvé | vert (garde contre le sur-correctif : tout rejet dit « non lancé ») |
| FX-6b | lecture réussie, puis `exit 1` : plus de « phase 68 », « émetteur en échec (code 1) » dit ; puis relecture réussie : tout revient | idem | vert : la propriété réelle du code est « l'échec remet `signal` à `null` et pose l'erreur » (refresh.ts) ; le mutant est joué plus bas |
| FX-6c | toast `recover · exit 3 · <120 x>` (sortie de 200 bornée) ; `recover · exit 0 · verrou élagué` | toasts contenant | vert (le contenu n'était asserté nulle part ; mutants plus bas) |
| FX-6d | script qui ne démarre pas : « recover : driver-lock.sh ne démarre pas » | idem | vert (idem) |
| FX-3b | chemin `/lab dir/...` et `ws` = `a b';touch /tmp/pwn;`id`$(id) #` : la commande copiée se découpe (découpeur POSIX du témoin, FX-3a prouve qu'il sait rougir) en `bash`, script, `takeover`, `--owner=ID`, `--ws=<ws>` | découpe exacte | `Error: guillemet simple non fermé : bash /lab dir/.../driver-lock.sh takeover --owner=<id> --ws=a b';touch /tmp/pwn;...` |
| FX-3c | sans caractère spécial, la commande reste `bash <script> takeover --owner=<id> --ws=fiabilite` (aucun guillemet inutile) | motif | vert (garde contre le sur-correctif) |
| FX-4a0 | toast d'élagage portant `ESC[31m`, `ESC]0;`, BEL, C1, un saut de ligne : aucun contrôle, aucune ligne forgée | pas de `[\x00-\x1f\x7f-\x9f]` | `recover · exit 0 · rouge\u001b[31m fin\u001b]0;titre\u0007 c1\u009b31m bel\u0007- faux verrou : intrus` |
| FX-4a1..a4 | brief : `agent.description`, raison de refus, `projet`, `owner` du verrou | idem | contrôles et ligne `- faux verrou` forgée dans le Markdown |
| FX-4a5 | bandeau : `owner` du verrou périmé | idem | contrôles dans le texte |
| FX-4a6, FX-4a7 | pane : `owner` du verrou (`cut`, sans `oneLine`), nom de phase (`oneLine` identité sur les contrôles) | pane dessinée | `$.ui.mount: vibeflow drew nothing … a text child holds a control character (an escape sequence)` : l'engine refuse la pane entière |
