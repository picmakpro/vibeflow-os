# 72-SECURITY — audit sécurité, Phase 72 (lancer du travail depuis les cartes du cockpit)

Trois lots d'audit, au fil de l'exécution : `84501819` (lot 1), `b5efcc40` (lot 2, équivalent rebasé `9b63d963`), `4fa5fe95` (lot 3, après rebase sur `origin/main` `57e7957f`) · 2026-11-05 et 2026-11-06 · auditeur : `vf-auditer`, recoupé avec `gsd-security-auditor` · statut au verdict du lot 3 : **SECURED** (aucune décision humaine nouvelle), trois findings bas encore **en correction** au moment de l'écriture (L1, I2, L2).

Ce fichier est écrit par le nœud docs du manager (hygiène documentaire de la phase). Il reprend les verdicts rendus par les auditeurs, leurs suites, les arbitrages humains avec leur canal et leur date, et les résiduels acceptés. Le registre complet des menaces de la phase (T-72-xx) vit dans les blocs `<threat_model>` des plans 72-01 à 72-16 ; les suites qui les prouvent et leurs mutants sont tracés dans les `72-NN-RED-TRACE.md`.

## Les trois lots d'audit

| Lot | SHA audité | Verdict | Findings |
|---|---|---|---|
| 1 | `84501819` | `human_needed` sur F6 seul ; aucune menace haute ou moyenne confirmée par sonde | F1 à F5 bas ou info, F6 à trancher |
| 2 | `b5efcc40` (rebasé : `9b63d963`) | `ESCALATE` sur F-1 | F-1 moyen conditionnel, F-2, F-3, F-4 |
| 3 | `4fa5fe95` | `SECURED`, recoupement `gsd-security-auditor` : mêmes conclusions | L1, I2, L2 bas ; L3 doc ; I3 info |

### Lot 1 — `84501819`

Revue : `passed`, 11 mineurs (ST-1 à ST-5, SP-1 à SP-6), fusionnés avec l'audit. Findings et suites :

| Id | Constat | Suite |
|---|---|---|
| F1 | une proposition déplace le focus clavier : fenêtre non focalisée, les frappes de la page Projet partent vers le shell (mesuré : trois octets à l'entrée du shell) | corrigé côté Q (`2cf478f4`) : un cadre sans focus ne le prend jamais ; témoins LB.F1 et LB.F2, mutants M-FOCUS-CLIENT et M-FOCUS-VUE rouges (`72-CORRECTIFS-B.md`) |
| F2 | « au repos » = le PID du shell au premier plan, sans détection d'invite | limite documentée au README du module, pas de détection d'invite (décision du manager, technique) |
| F3 | garde du propriétaire de `POST /annuler` et code `terminal-indisponible` sans témoin | témoins Q10b et E2b ajoutés, mutants M-ANNULER-PROPRIETAIRE, M-CODE-INDISPONIBLE, M-GARDE-ACTIF rouges (`72-CORRECTIFS-A.md`) |
| F4 | finding de gravité basse du rapport de l'auditeur | info, no-op : la revalidation indépendante côté Python (`vf-cockpit-pty.py`) ne tient que l'alphabet fermé, le préfixe et l'apostrophe finale ; `claude --session-id 'x' --dangerously-skip-permissions '/x'` y obtient `LANCE ok` ; la grammaire complète n'est tenue que par le gabarit JS ; pas d'écart d'autorité, Q a déjà `/entree` ; documenté en T-72-08 (commit `94bdb6e2`) |
| F5 | un `504` de `POST /lancer` peut être suivi d'une ligne tardive | documenté au contrat §4 (décision du manager) |
| F6 | portée réelle du mode « hérité du poste » | tranché par recherche documentaire (voir « Arbitrages et décisions » et « Limites mesurées de version ») ; texte `NOTE_HERITE` corrigé (`2cf478f4`, `90237961`), limite de version au README |

Autres suites du lot 1 : ST-1 (source unique de la récence et des règles de verdict, `bda27787`, `41f08dbe`), ST-3 (l'environnement ne peut que rallonger le délai d'armement, jamais l'abaisser sous 1 000 ms, `9dc27b50`, mutant M-ARME-ABAISSABLE), ST-4 (`LANCE ok` seulement pour une ligne réellement poussée, nouveau motif `ecriture` rendu en HTTP 410, `b6e2c21a`, `1f220a78`), ST-2 et ST-5 (parité des tables de motifs, texte vrai pour les quatre causes du 409), SP-1 (une proposition acceptée rend le cadre visible, sans focus). Documentaire : `94bdb6e2`.

### Lot 2 — `b5efcc40`

| Id | Constat | Suite |
|---|---|---|
| F-1 | moyen conditionnel : une charge dans la page Projet peut faire retenir l'identifiant d'une conversation qu'elle a écrite et proposer « continuer le chat » ; la confirmation humaine couvre la ligne, pas le contexte repris | arbitrage Samuel (P72-D-21), puis révisé (P72-D-22) : voir « Arbitrages » ; garde d'activation `2b9e23b9`, manche RES `0a1d90f8`, `86d6a4b9`, `45690d08` |
| F-2 | mode réel de « hérité » en reprise du chat | sonde réelle du 2026-11-06, voir ci-dessous |
| F-3 | M-LISTE-PAGE périmé dans la suite bout-en-bout après ST-1 (suite rouge) | corrigé `acb032e1` (le mutant retire les deux gardes d'appartenance) ; 54 PASS / 0 FAIL |
| F-4 | motif `ecriture` (HTTP 410) sans témoin | corrigé `acb032e1` ; ajouté au contrat §4 et §5 et à la docstring du PTY (`87552b91`) |

**Sonde réelle F-2 (2026-11-06, vraie version 2.1.318).** Une reprise `-r … --fork-session` sans `--permission-mode` prend le mode par défaut du poste (`auto` sur ce poste) et non le `dontAsk` du chat d'origine. `--permission-mode default` donne bien « manual mode on » avec invite, et `acceptEdits` écrit sans invite. La note corrigée du mode hérité est donc juste aussi pour la variante chat ; sur un poste dont le défaut est `auto`, « hérité » écrit sans invite (écrit au README).

La revue du lot 2 a ajouté S1 (majeur, déjà corrigé par `acb032e1`), S2 (docstring « poussée » plus forte que le code), P1 (motif `ecriture` absent du contrat) et S3 (motif d'identifiant lâche côté page, corrigé par `2b9e23b9`).

### Lot 3 — `4fa5fe95`

Verdict **SECURED**, aucune décision humaine nouvelle ; P72-D-20 tient (le dossier du fichier du mode est `dirname` de `serve.mjs`, posé une fois par le processus serveur, jamais par la page). Recoupement `gsd-security-auditor` : mêmes conclusions (il classe L1 en medium, l'auditeur en low : le lanceur refuse déjà les liens symboliques de la sortie et l'écriture exige déjà T-72-127).

| Id | Sévérité | Constat | Suite |
|---|---|---|---|
| L1 | bas | un lien symbolique sur `.cache` redirige l'écriture du fichier du mode | **clos** par `38eeeb3a` (`lstat` du dossier support avant écriture, lien refusé ; la course `lstat`/ouverture est consignée, non fermée) |
| I2 | info | un BOM en tête du fichier du mode est toléré | **clos** par `38eeeb3a` (BOM refusé à la lecture) |
| L2 | bas | trois `.focus()` de la vue de Q sans garde `hasFocus` (code de la Phase 71) | **clos** par `a5dc9180` (garde `document.hasFocus()` sur la carte et le bandeau ; témoins LB.F4 à LB.F8, mutants M-FOCUS-CARTE et M-FOCUS-BANDEAU rouges, `72-CORRECTIFS-D.md`) ; le collage n'est atteignable que par un geste dans le cadre, laissé tel quel |
| L3 | doc | limite à écrire au README | tenu par 72-15 |
| I3 | info | l'agent du chat (`/api/ask`, `Read(./**)`) lit le fichier du mode, non sensible | consigné au plan 72-16 (T-72-128), lecture seule |

Mesure du lot 3 : la fenêtre d'activation de la page Projet (environ 5 s) s'ouvre aussi sur un geste réel dans le cadre du terminal, pas seulement dans la page ; elle reste dans le résiduel P72-D-22 ci-dessous. Revue du lot 3 : `passed`, 5 mineurs ; S-1 (mutant `trim` survivant) et P-1 (UUID majuscule accepté par P et par Q) corrigés par `084e221d`, S-2 (note « hérité » dépendante de la version) traité par l'incise « Claude Code 2.1.257 et plus », S-3 (temporaires non balayés après SIGKILL) : sans suite, noté.

## Arbitrages et décisions humaines

Tous pris par Samuel via `AskUserQuestion`, session principale Claude Code, aux dates indiquées (texte intégral dans `72-CONTEXT.md`).

| Id | Date | Réponse | Objet |
|---|---|---|---|
| P72-D-01 (Q1) | 2026-11-05 | « Terminal au repos seulement (Recommandé) » | la ligne n'est écrite que si le premier plan du PTY est le shell |
| P72-D-02 (Q2) | 2026-11-05 | réponse libre : « choix + hérité don bypass » | modes proposés : `default`, `acceptEdits`, `plan` et « hérité du poste » ; la règle « jamais `bypassPermissions` depuis une carte » est levée |
| P72-D-02bis (Q2bis) | 2026-11-05 | « Le dernier mode choisi » | présélection du mode ; risque du détournement de clic exposé dans la question |
| P72-D-03 (Q3) | 2026-11-05 | « Option « continuer le chat » » | reprise du chat, livrée après la sonde A5 (verte, 2.1.318) |
| P72-D-04 (Q4) | 2026-11-05 | « Cartes phase et mission de Projet (Recommandé) » | cartes concernées |
| P72-D-05 (Q5) | 2026-11-05 | « Une action principale + menu (Recommandé) » | actions des cartes |
| P72-D-06 (Q6) | 2026-11-05 | « Bloquer l'impossible, avertir le reste (Recommandé) » | pré-vols |
| P72-D-07 (Q7) | 2026-11-05 | « La 78 le porte, la 72 le reprend (Recommandé) » | arbre sale reporté à la Phase 78 |
| P72-D-20 | 2026-11-06 | « Fichier du lab (Recommandé) » | le mode retenu vit dans un fichier du lab tenu par le processus du terminal (précise P72-D-02bis) |
| P72-D-21 | 2026-11-06 | « Geste humain exigé (Recommandé) » | garde d'activation utilisateur pour retenir l'identifiant du chat (F-1) ; remplacée sur le résiduel par P72-D-22 |
| P72-D-22 | 2026-11-06 | « Garder, risque écrit (Recommandé) » | la reprise forgée du chat est un résiduel accepté ; options B' et D écartées |

Décisions techniques du manager (non arbitrées par Samuel) citées par l'audit : P72-D-09 à P72-D-19 (page propose, terminal dispose ; liste fermée ; gabarit fermé ; double geste ; forme du prompt), recherche documentaire sur F6 (depuis la v2.1.257, `bypassPermissions` et `auto` d'un réglage de projet sont ignorés ; « hérité » ne peut valoir `bypassPermissions` que si le poste le configure).

Faute reconnue par le manager : la prémisse de P72-D-21 (« un script ne peut pas forger l'activation, donc la reprise forgée est fermée ») était fausse, car la route de la page accepte `chat:<uuid>` du corps. C'est ce qui a motivé la seconde question, tranchée par P72-D-22.

## Résiduels acceptés

> **Clic détourné (arbitrage Samuel, AskUserQuestion session principale, 2026-11-05, P72-D-02bis).** Un script qui s'exécute dans la page Projet peut rendre le cadre du terminal invisible ou trompeur et espérer un clic de l'humain sur « Lancer » ; avec le mode retenu (« le dernier mode choisi »), un mode puissant (`acceptEdits`, ou « hérité du poste » qui peut valoir « tout autoriser » si le poste le configure) est présélectionné. Depuis P72-D-20 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-06, « Fichier du lab (Recommandé) »), ce mode survit aux relances du cockpit au lieu d'être perdu à chaque démarrage : la durée du risque s'allonge, sa nature ne change pas. Parades dues et mesurées (LM.Q8, LB.E2, LEG.5/6, RES.3/4) : délai d'armement d'au moins 1 s lu côté serveur, clic de confiance dans le terminal, ligne exacte affichée, ligne écrite SANS retour chariot, Entrée tapée par l'humain. La valeur est l'une des quatre d'une liste fermée (`bypassPermissions` n'est jamais une valeur) ; le fichier est tenu par le seul processus du terminal, relu au démarrage contre cette liste, jamais lu ni écrit par la page Projet. Un tiers local qui peut écrire dans `<lab>/.vibeflow/cockpit/` peut forger la présélection (T-72-127) : il dispose déjà de pouvoirs supérieurs.
>
> **Reprise forgée du chat (arbitrage Samuel, AskUserQuestion session principale, 2026-11-06, P72-D-22, « Garder, risque écrit (Recommandé) »).** Un script qui s'exécute dans la page Projet peut envoyer lui-même à `POST /api/vf/lancer` un identifiant de conversation de forme valide, issu d'une conversation qu'il a écrite, avec le jeton de la page : la garde d'activation utilisateur (P72-D-21, `garde:activation`) ne ferme que le chemin par l'interface, et sa fenêtre (environ 5 s) s'ouvre aussi sur un geste réel dans le terminal, pas seulement dans la page. La barrière réelle est caractérisée par la manche RES de `test-cockpit-lancer-xss.sh` (jamais une protection) : la case « Continuer la conversation du chat » apparaît DÉCOCHÉE, la ligne affichée décochée ne porte ni `-r`, ni `--fork-session`, ni l'identifiant (il n'apparaît qu'une fois la case cochée), aucun octet n'atteint le shell et aucun argv n'est reçu tant qu'il n'y a ni clic ni Entrée dans Q. Surface voisine, hors phase : `POST /api/ask` (`.planning/BACKLOG.md`).
>
> **Limites mesurées de version de Claude Code.** Les mesures de la phase portent sur Claude Code 2.1.318 (forme du prompt, `--session-id`, `-r`, `--fork-session`, sonde de reprise du chat A5 verte le 2026-11-05) ; la note du mode hérité s'appuie sur la documentation officielle de cette version (`bypassPermissions` et `auto` d'un `.claude/settings.json` ou `settings.local.json` de projet ignorés depuis la v2.1.257), non remesurée par l'audit (aucun vrai `claude` lancé). Le plancher exact de compatibilité n'est pas mesuré (vf-signal : non chargée sous 2.1.181). Une version différente peut changer ces comportements sans que les suites rougissent : le faux binaire de test les suppose.

Sonde réelle F-2 (2026-11-06, vraie version 2.1.318) : une reprise `-r … --fork-session` sans `--permission-mode` prend le mode par défaut du poste (`auto` sur ce poste) et non le `dontAsk` du chat d'origine ; `--permission-mode default` donne « manual mode on » avec invite, `acceptEdits` écrit sans invite. Sur un poste dont le défaut est `auto`, « hérité » écrit donc sans invite.

Autres limites assumées, sans arbitrage nouveau : « au repos » = PID du shell au premier plan, pas de détection d'invite (F2) ; un `504` peut être suivi d'une ligne tardive (F5) ; `S-3` (temporaires non balayés après SIGKILL) ; la boîte « faire confiance à ce dossier » d'un lab jamais ouvert reste à l'utilisateur ; surface voisine hors phase, `POST /api/ask` pilotable par un script de la page Projet (`.planning/BACKLOG.md`).

## Limites de la mesure

Aucun vrai `claude` n'a été lancé par l'audit (faux binaire dans le PATH du shell des suites) ; macOS seulement pour les sondes d'audit (Linux jugé par la CI après la PR) ; Chrome seul pour les sondes navigateur ; la recette par juge (SHA `4fa5fe95`, étapes 1 à 6 passées) a joué le parcours avec les captures sous le dossier temporaire de la mission, hors dépôt.

## Statut des findings au moment de l'écriture

Fermés : F1, F3, F5, F6, F-1 (par P72-D-22), F-2, F-3, F-4, ST-1 à ST-5, SP-1, S1 à S3, P-1, S-1 (ces deux derniers par `084e221d`), L1 et I2 (par `38eeeb3a`), L2 (par `a5dc9180`). Info, no-op : F4 (documenté en T-72-08, `94bdb6e2`). Sans suite : S-3. Réglages visuels de la recette : `b05d3001`. Aucun finding ouvert.
