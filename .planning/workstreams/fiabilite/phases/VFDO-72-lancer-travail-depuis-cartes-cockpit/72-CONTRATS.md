# 72-CONTRATS — contrats inter-plans de la Phase 72 (pris à la planification, 2026-11-05)

Document de coordination des plans `72-01` à `72-15`. Il fige les interfaces entre plans écrits en parallèle ; il ne remplace ni
`72-CONTEXT.md` (décisions P72-D-01 à P72-D-19, qui priment) ni `72-RESEARCH.md`. Un plan qui doit s'en écarter le dit dans son
objectif et remonte le point au manager.

## 1. Découpage, vagues, propriété des fichiers

Règle : deux plans d'une même vague n'ont aucun fichier commun dans `files_modified`. Les chemins sont sous `plugin/cockpit/`
(`S` = `scripts/`, `T` = `scripts/tests/`, `PTY` = `skills/cockpit-moteur/terminal/vf-cockpit-pty.py`).

| Plan | Vague | Objet | Fichiers possédés (neufs sauf mention) | Exigences |
|------|-------|-------|-----------------------------------------|-----------|
| 72-01 | 1 | Gabarit de commande, alphabet fermé, motifs, forme du prompt | `S/vf-cockpit-lancer-gabarit.mjs`, `T/test-cockpit-lancer-gabarit.sh` | LANC-05, LANC-09 (liste des modes) |
| 72-02 | 1 | Assistant PTY : premier plan, revalidation de la ligne, écriture sans `\r` | `PTY` (existant), `S/vf-cockpit-terminal-session.mjs` (existant), `T/test-cockpit-lancer-pty.sh` | LANC-06, LANC-07 (sans `\r`) |
| 72-03 | 1 | Cibles lançables et pré-vols (module pur, lecteurs injectés) | `S/vf-cockpit-lancer-cibles.mjs`, `T/test-cockpit-lancer-cibles.sh` | LANC-04 (liste), LANC-08 |
| 72-04 | 1 | Mécanisme POST de P (table de routes, contrôles) | `S/vf-cockpit-lancer-post.mjs`, `T/test-cockpit-lancer-post.sh` | LANC-03 |
| 72-05 | 1 | État de Q : liste fermée, proposition unique, expiration, armement, consommation (module pur, composeur injecté) | `S/vf-cockpit-lancer-q.mjs`, `T/test-cockpit-lancer-q.sh` | LANC-04, LANC-07, LANC-10 (consommée une fois) |
| 72-06 | 1 | Interface des cartes (script servi à la volée), sur page factice | `S/vf-cockpit-lancer-ui.mjs`, `T/test-cockpit-lancer-ui.sh` | LANC-01, LANC-02 (côté script) |
| 72-07 | 1 | Registre de suivi des lancements et rattachement Équipe | `S/vf-cockpit-lancer-suivi.mjs`, `S/vf-cockpit-equipe-carte.mjs` (existant, paramètre optionnel), `T/test-cockpit-lancer-suivi.sh` | LANC-10 |
| 72-08 | 1 | Bandeau de proposition dans la page Q (vue, client, mode retenu dans le stockage de l'origine Q) | `S/vf-cockpit-terminal-vue.mjs` (existant), `S/vf-cockpit-terminal-client.mjs` (existant), `T/test-cockpit-lancer-bandeau.sh` | LANC-07, LANC-09 |
| 72-09 | 2 | Assemblage côté P : canal, orchestration, branchement dans `vf-cockpit-server.mjs` et `vf-cockpit-terminal.mjs` | `S/vf-cockpit-lancer.mjs`, `S/vf-cockpit-lancer-canal.mjs`, `S/vf-cockpit-server.mjs` (existant), `S/vf-cockpit-terminal.mjs` (existant), `T/test-cockpit-lancer-serveur.sh` | LANC-01..04, LANC-08, LANC-10, LANC-02 |
| 72-10 | 2 | Assemblage côté Q : routes et messages IPC dans le processus de Q | `S/vf-cockpit-terminal-processus.mjs` (existant), `T/test-cockpit-lancer-processus.sh` | LANC-04..07, LANC-09, LANC-10 |
| 72-11 | 3 | Chaîne XSS étendue jusqu'au lancement (suite neuve) | `T/test-cockpit-lancer-xss.sh` (+ témoins neufs `T/temoins/lancer-*`) | LANC-07, LANC-04, LANC-05 |
| 72-12 | 3 | Bout en bout avec faux `claude` dans Chromium et variante sans navigateur | `T/test-cockpit-lancer-bout-en-bout.sh`, `T/temoins/fauxbin-claude/`, `T/chrome-lancer.mjs` | LANC-05, LANC-10, LANC-12 |
| 72-13 | 3 | « Continuer le chat » : sonde A5 puis option (porte de décision en tête) | `S/vf-cockpit-lancer-ui.mjs`, `S/vf-cockpit-terminal-vue.mjs`, `S/vf-cockpit-terminal-client.mjs` (tous existants à ce stade), `T/test-cockpit-lancer-chat.sh` | LANC-11 |
| 72-14 | 3 | Tiroir : ouvrir et signaler une proposition en attente (la clôture de la 71 est mergée, 1e4d1ecd, cockpit v1.3.3 : plus de contrainte de dernière vague, la disjonction décide ; dépend de 72-08 qui émet la valeur fixe `proposition` Q → P) | `S/vf-cockpit-terminal-tiroir.mjs`, `S/vf-cockpit-terminal-tiroir-style.mjs`, `T/test-cockpit-terminal-tiroir.sh` | LANC-01, LANC-07 |
| 72-15 | 4 | Docs et bump unique (au-dessus de v1.3.3) | `VERSION`, `module.json`, `CHANGELOG.md`, `README.md`, `skills/vf-cockpit/SKILL.md`, README racine (compte de suites) | LANC-12 |

Chaque plan crée aussi son `72-NN-RED-TRACE.md` (preuve du rouge, modèle `71-NN-RED-TRACE.md`) : il figure dans ses `files_modified`.
`72-BRANCHEMENTS-MERGE.md` est tenu par le planificateur (pas par un plan d'exécution).

Les fichiers `S/vf-cockpit-lancer*.mjs` sont copiés dans le lab par le build (motif `^vf-cockpit-.*\.mjs$`, `vf-cockpit-build.mjs:22`) :
aucun enregistrement n'est à faire. `serve.mjs` (vendoré, patchs tracés dans `VENDORED.txt` et `amont/patches/`) n'est PAS modifié : le
canal passe par `vf-cockpit-lancer-canal.mjs` (registre de module que `preparerTerminal` renseigne et que `vf-cockpit-lancer.mjs` lit).
Si un plan découvre que `serve.mjs` doit changer, il s'arrête et remonte (patch P-numéroté, `amont/SYNCHRO.md`, hors de ce découpage).

## 2. Alphabet et forme de la ligne (P72-D-13, P72-D-19)

- Alphabet fermé unique, littéral normatif repris À L'IDENTIQUE par le gabarit (JS) et l'assistant (Python) :
  `^[A-Za-z0-9 ._:/'-]+$` (aucun `$`, accent grave, `;`, `&`, `|`, `<`, `>`, `(`, `)`, `\`, `!`, `"`, `*`, `?`, `#`, `~`, retour chariot).
  Longueur maximale 400. La ligne commence par `claude --session-id '` et se termine par une apostrophe.
- Forme : `claude --session-id '<uuid4>' -n '<nom>' [--permission-mode '<mode>'] '/vf-dev <intention>'`. Le nom exact du skill (`vf-dev` nu, ou
  préfixé du plugin) est UNE constante du gabarit, vérifiée par une suite (P72-D-19). Variante chat (72-13 seulement) : le gabarit sait
  composer `-r '<uuid>' --fork-session`, jamais offerte par le bandeau avant 72-13.
- Variables : phase `^\d+(?:\.\d+)?$` ; compartiment `^[a-z0-9][a-z0-9-]{0,39}$` (hors motif = refus, jamais « nettoyé ») ; verbe de la liste
  fermée `cadrer, planifier, executer, verifier, reprendre` ; mode de la liste fermée `default, acceptEdits, plan, herite` (`herite` = aucun
  drapeau `--permission-mode`, P72-D-02) ; UUID v4 de session généré par Q ; UUID du chat validé. Jamais un titre, un Goal, un nom de mission
  ou de nœud. Une carte de mission hors phase n'est PAS lançable (bloquant `mission-hors-phase`) ; une carte de mission rattachée se
  résout en `(phase, compartiment, verbe reprendre)`.
- Intentions en ASCII sans accent, une par verbe, constantes du gabarit (par exemple `Cadre la Phase 72 du compartiment fiabilite`).
  Jamais une commande `gsd-*` dans une intention.
- Nom de session `-n` : `vf-phase-<phase avec . remplacé par ->-<compartiment>` (alphabet respecté).

## 3. Canal P → Q (IPC de `fork`, P72-D-10, P72-D-12)

- parent → enfant : `{ t:'cibles', cibles:[{ id, verbe, verbes:[…], phase, ws, kind }] }` (liste fermée recalculée par P, envoyée avant toute
  proposition et à chaque changement) ; `{ t:'proposition', cible, verbe, chat? , bloquants:[codes], avertissements:[codes] }`.
  Q ignore (0 octet, aucun bandeau) toute proposition dont le couple `(cible, verbe)` n'est pas dans la dernière liste reçue.
- enfant → parent : `{ t:'lancee', cible, verbe, session, at }` (la ligne a été écrite au shell) ; les messages existants sont inchangés.
- Une seule proposition en attente ; une nouvelle remplace l'ancienne ; elle expire (`EXPIRE_MS`, valeur au plan 72-05) ; elle est consommée
  à l'usage, à l'annulation ou à l'expiration, jamais rejouée par un rechargement ou une bascule de thème.
- Aucun texte du lab ne traverse le canal : seulement `cible` (identifiant de carte), `verbe`, `phase`, `ws`, codes de pré-vol, `chat` (UUID).

## 4. Routes

P (72-04 pose le mécanisme, 72-09 branche) :
- `GET  /api/vf/lancer/cibles` → `{ actif:true, terminal:'actif'|'arrete'|'indisponible', claude:bool, cibles:[{ id, kind, principal, verbes, bloquants, avertissements, lancee }] }` ; `lancee` = `{ etat, verbe }` ou `false` (§9).
- `POST /api/vf/lancer` corps `{ cible, verbe, chat? }`, schéma fermé (champ inconnu = refus), `Content-Type: application/json`, corps ≤ 512 octets,
  `Host` exact `127.0.0.1:P` ou `localhost:P`, `Origin` OBLIGATOIRE et égale à `http://<Host>`, jeton de page en temps constant. Réponse `202 { propose:true }`
  ou refus à code fermé ; jamais une ligne de commande dans une réponse. Sans `--terminal` : aucune de ces routes n'existe (réponse 404 identique
  à l'actuelle pour toute route `/api/vf/` inconnue), aucun script injecté, CSP de page inchangée.
Q (72-10 branche ; table fermée existante étendue) :
- `GET /proposition` (mêmes contrôles que `GET /etat`) → `{ etat:'aucune' }` ou `{ etat:'en-attente', id, verbe, intention, phase, ws, lignes:{ default, acceptEdits, plan, herite },
  bloquants, avertissements, arme_apres_ms, expire_ms, mode_retenu }`. Les textes viennent des constantes du gabarit. `mode_retenu` (72-16 ; P72-D-20) : un mot de la liste fermée `default, acceptEdits, plan, herite`, présent SEULEMENT dans la réponse `en-attente` (jamais dans `{ etat:'aucune' }`), lu au démarrage de Q dans `<sortie>/.cache/terminal-mode` (`default` si le fichier est absent, vide, forgé ou illisible) ; le client le relit contre la liste fermée.
- `POST /lancer` corps `{ id, mode }` (Origin Q exacte, secret, onglet) → `204`, `409` premier plan occupé, `425` pas encore armé (armement refusé AUSSI côté
  serveur), `404` proposition inconnue ou consommée, `410` pas de session OU écriture au PTY échouée (motif `ecriture`, `STATUT_LANCER.ecriture` ; la proposition est restituée, `lq.rendre`), `400`, `504` délai de l'assistant PTY (`STATUT_LANCER.delai`, `vf-cockpit-terminal-processus.mjs:29`, `lancer()` l.70-82 ; `LANCER_DELAI_MS = 2000`, `vf-cockpit-terminal-session.mjs:25`). Le client de Q traite le 504 comme un refus (`vf-cockpit-terminal-client.mjs:84`, repli `'refus'`). Limite connue : une réponse tardive de l'assistant peut encore écrire la ligne à l'invite après le 504, sans retour chariot ; la proposition revient `en-attente`, un second clic réécrit Ctrl-C puis la ligne. Aucune exécution sans Entrée humaine. Le client n'envoie JAMAIS le texte de la ligne : Q retrouve la ligne précomposée.
- `POST /annuler` corps `{ id }`.

## 5. Protocole de l'assistant PTY (72-02)

- fd 3 (contrôle), nouvelle ligne : `L <hex>\n` (`<hex>` = octets de la ligne, 2 à 800 caractères hexadécimaux pairs). L'assistant décode, REVALIDE l'alphabet,
  la longueur et le préfixe, puis SI `tcgetpgrp(maître) == pid du shell` : écrit `\x03` SEUL, puis, quand le shell a réagi (sortie vue puis 30 ms de calme, ou 0,3 s sans sortie) et que `tcgetpgrp(maître) == pid` est ENCORE vrai, écrit la ligne, SANS `\r`, dans une écriture distincte (Ctrl-C et ligne dans la même écriture : bash sous Linux perd le premier octet de la ligne, cf. 72-CI-LINUX.md) ; sinon n'écrit RIEN. La réponse `LANCE …` d'une demande acceptée ne part qu'avec la ligne (`ok`, `premier-plan` ou `ecriture`). **TOUTE entrée humaine (fd 0) reçue entre l'arrivée de `L` et l'écriture de la ligne l'annule** (la ligne n'est pas écrite (le Ctrl-C l'a déjà été), `LANCE premier-plan`) ; en défense en profondeur, une entrée encore en file d'écriture ou un programme déjà au premier plan l'annulent aussi ; les demandes arrivées pendant l'attente reçoivent leur réponse ensuite, dans l'ordre.
- fd 2 (état), nouvelle ligne : `LANCE ok` · `LANCE premier-plan` · `LANCE alphabet` · `LANCE invalide` · `LANCE ecriture` (l'écriture au PTY a échoué ; `lancer_ligne` de `vf-cockpit-pty.py`, regex du parseur dans `vf-cockpit-terminal-session.mjs`). Le parseur de session accepte ces lignes en plus de `FIN`/`SIG`.
- `sessions.lancer(ligne, onglet)` → `Promise<{ ok:true } | { ok:false, motif:'premier-plan'|'alphabet'|'invalide'|'absente'|'delai'|'ecriture' }>` (`ecriture` : HTTP 410, la proposition est restituée) (délai 2 s).
- Mutants imposés à 72-02 : M-PREMIER-PLAN (test sauté), M-CTRLC-AVEUGLE (`\x03` sans test), M-ALPHABET-PY (pas de revalidation), M-ENTREE-AUTO (`\r` ajouté).

## 6. Mode de permission (P72-D-02, P72-D-02bis)

Le mode retenu vit UNIQUEMENT dans le stockage de l'origine Q (page Q, clé fixe), relu contre la liste fermée (valeur inconnue = `default`, premier lancement
= `default`). Il n'est ni transmis par l'IPC, ni dans un cookie, ni écrit par le serveur, ni lisible par la page P (`SecurityError` mesuré dans une suite).
Le bandeau envoie `{ id, mode }` ; Q valide `mode` contre la liste.

## 7. Règles de forme communes à tous les plans

- Tâches : témoin ROUGE joué avant le code (mutant ou base) puis vert ; mutants nommés ; jamais une assertion affaiblie ; chaque `<automated>` suivi d'un `<fails_when>`.
- Commandes de vérification rejouables sous zsh ET bash (pas de `==== ` nu, pas de substitution propre à un seul shell).
- Suites neuves `test-cockpit-lancer-*.sh` ; harnais Chrome existant (`chrome-session.mjs`) ; faux `claude` dans le PATH d'origine du shell ; ports libres ≥ 4600, jamais 4456.
- Tout commit qui touche une suite, une fixture surveillée ou un gate porte `Gate-Touche: <chemin> — <raison>` (CLAUDE.md du dépôt).
- Aucune valeur de style en dur : variables CSS existantes seulement ; classes `vf-q-bandeau` / `vf-q-collage` réutilisées (P72-D-08).
- Fichiers de code ≤ 300 lignes (`check-file-size.sh`), sauf dette existante tracée (`vf-cockpit-pty.py` dépasse déjà : vérifier le marqueur `vibeflow:allow-large-file`).
- Section menace STRIDE pour tout plan qui touche une frontière (LANC-03 à LANC-07, P72-D-02bis).
- Les suites existantes du cockpit restent vertes ; un plan qui modifie un fichier existant rejoue les suites qui le couvrent.

## 8. Amendement du 2026-11-05 (message du manager)

La clôture de la 71 est mergée sur main (`1e4d1ecd`, cockpit v1.3.3). 72-14 passe en vague 3 (`depends_on: ["72-08"]`), 72-15 en vague 4. Le bump se calcule au-dessus de v1.3.3. 72-08 (client Q) émet, à l'arrivée d'une proposition, la valeur FIXE `proposition` vers P (`window.parent.postMessage`, origine de P exacte) ; 72-14 l'ajoute à `LISTE_MESSAGES` sans rien changer au filtre `accepteMessage`. Lire le tiroir sur `git show origin/main:plugin/cockpit/scripts/vf-cockpit-terminal-tiroir.mjs`.

## 9. Amendement additif de planification (2026-11-05)

Ajoutés par 72-05, 72-09, 72-10 et exigés par 72-13 : `GET /proposition` rend aussi `chat` (booléen) et `lignes_chat` ; `POST /lancer` accepte `chat` booléen strict
facultatif ; `chat` (UUID) est validé côté P (72-09) et côté Q (72-05) et relayé de bout en bout, inerte tant que 72-13 n'offre pas la case. Sans conversation,
`GET /proposition` garde exactement les clés du §4 (`mode_retenu` compris). `lancee` a la forme riche `{ etat, verbe }` ou `false` dans la réponse de P (livrée par 72-09, `vf-cockpit-lancer.mjs:6` et `:96`, lue par la carte de 72-06) ; l'état du suivi (72-07) sert l'avertissement de récence
et le rattachement Équipe. Un refus de `POST /api/vf/lancer` porte la clé `refus` (corps `{ refus: <code fermé> }`, `vf-cockpit-lancer.mjs:7`, `vf-cockpit-lancer-post.mjs:81`). `sessions.lancer` peut aussi répondre `delai` (HTTP 504 côté Q). Sans `--terminal`, `POST /api/vf/lancer` répond comme `POST /api/vf/inconnu` (405 actuel) et
`GET` inconnu 404 : identité à prouver, jamais un statut écrit en dur. Règle de dépôt : aucun `vf-cockpit-*.mjs` ne contient `fiabilite` ni `gouvernance` (`test-cockpit-projet.sh`, P4.8).
