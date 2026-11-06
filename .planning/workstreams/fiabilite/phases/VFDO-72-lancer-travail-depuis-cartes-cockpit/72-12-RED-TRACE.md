# 72-12 — RED-TRACE : bout en bout du lancement avec un faux `claude`

Plan : 72-12 (Phase 72, compartiment fiabilite, vague 3). Mandat repris après le crash du 2026-11-05 ; exécution inline par vf-coder.
Code livré sous test : 72-08 (bandeau), 72-09 (côté P), 72-10 (côté Q), base `84501819` (HEAD au moment de la preuve verte).
Fichiers du plan : `test-cockpit-lancer-bout-en-bout.sh`, `temoins/fauxbin-claude/claude`, `chrome-lancer.mjs` (tous sous `plugin/cockpit/scripts/tests/`).

## Base mesurée (sur le code livré)

- `principal` de `ph-1` (phase 1 du compartiment `fiabilite`, un PLAN, aucun CONTEXT) : `executer`. Verbes de la carte : cinq.
- `arme_apres_ms` lu sur `GET /proposition` : 1000 (valeur de production, `VF_COCKPIT_LANCER_ARME_MS` non posée).
- `POST /api/vf/lancer` sur les cartes `ph-8` (`a$(touch pwn-ws)`) et `ph-9` (`a$(id)`) : 409 chacune (refus `bloque`), jamais 202 ; `GET /proposition` reste `aucune`.
- `GET /api/vf/lancer/cibles` : `lancee` est un objet `{ etat, verbe }` après lancement, `false` avant (forme riche de 72-09, pas le booléen du plan).
- Durée de la suite complète : environ 2 min 20 s (une attente d'armement de 1,3 s par lancement, cinq lancements sans navigateur plus le scénario Chromium).
- Chrome utilisé : Google Chrome 156.0.8078.80 (macOS). Apparition du bandeau après `POST /api/vf/lancer` : 508 ms puis 828 ms (deux rejeux) ; plafond du plan : 4 s.

## Rouges sur mutants (copies de la sortie ; la sonde rougit pour la bonne raison)

Les mutants sont asserts dans la suite (résultat fautif exact) ET rejoués contre TOUTE la variante sans navigateur (B0 à B9) pour montrer quelle sonde de bout en bout rougit.

### M-RETOUR-CHARIOT — `sessions.lancer(ligneQ, onglet)` devient `sessions.lancer(ligneQ + '\r', onglet)`

Ancre de 72-10 (`vf-cockpit-terminal-processus.mjs`), une occurrence. Variante B complète sous le mutant : 24 PASS / 18 FAIL. Rouges principaux :

- B2 — POST /lancer {id, mode:herite} après armement
  - attendu: [204]
  - obtenu : [400]
- B2 — la ligne herite exacte de GET /proposition est à l'invite
  - attendu: [TROUVE]
  - obtenu : [ABSENT]
- B2 — après l'Entrée du client : argv identique octet pour octet
  - attendu: [identique]
  - obtenu : [différent : obtenu [] attendu [--session-id|<uuid>|-n|vf-phase-1-fiabilite|/vf-dev Execute la Phase 1 du compartiment fiabilite|]]
- B3 (default, acceptEdits, plan) — chacun : attendu [202 204 identique], obtenu [202 400 différent : obtenu [] attendu [...]]
- Dans la suite : « M-RETOUR-CHARIOT — … » attendu [400 ABSENT sans-argv], PASS (le mutant est bien rouge).

### M-LISTE-PAGE — la carte cherchée dans la liste du disque est remplacée par une carte sans bloquant (ancre de 72-09, `vf-cockpit-lancer.mjs`)

Variante B complète sous le mutant : 38 PASS / 4 FAIL. Rouges :

- B6 — POST /api/vf/lancer pour ph-8 et ph-9 : 409 (bloque), jamais 202
  - attendu: [409 409]
  - obtenu : [202 202]
- B9 — POST /api/vf/lancer pour ph-1 sans claude : 409, GET /proposition aucune
  - attendu: [409 actif {"etat":"aucune"}]
  - obtenu : [202 actif {"etat":"aucune"}]
- B4 — avertissement `lancement-recent` : attendu [202 true 0], obtenu [202 false 0] (la carte factice du mutant n'a pas d'avertissement : conséquence, pas cause)
- B2 — racine du lab : artefact du harnais (la copie mutée vit sous `mut-liste/`, pas sous `lab/`) ; sans rapport avec le mutant.
- Observation utile : sous le mutant, `GET /proposition` de Q reste `aucune` (B6 « aucune proposition n'est arrivée à Q » vert) : Q ne confirme que les cibles de la liste fermée que P lui a envoyée, deuxième barrière indépendante de P (P72-D-10). Dans la suite : « M-LISTE-PAGE — … » attendu [202], PASS.

## Vert sur le code livré

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-bout-en-bout.sh`, HEAD `84501819` (arbre sans modification non commitée sur `vf-cockpit-lancer-ui.mjs`, `vf-cockpit-terminal-vue.mjs`, `vf-cockpit-terminal-client.mjs`) : exit 0, `Résultats : 54 PASS / 0 FAIL (0 non vérifiées sans navigateur)`. B0 à B9, CH0 à CH9, deux mutants, H0 (aucun serveur ni Chrome ne survit).

## Chromium

- Q est jouée dans un cadre de P (`iframe` sandbox de P71-D-25), comme `test-cockpit-terminal-xterm.sh`, pas en « premier niveau » : Q n'ouvre un shell que dans son cadre (écart avec PL-12.6, le code livré fait foi). Amorçage par `project.html#t=<64 hexadécimaux>`.
- Fenêtre de 1600 x 700 : la grille xterm est plus large que la ligne, aucune césure ne peut faire manquer l'UUID.
- CH3 : `aria-disabled` vrai et la cible du clic (`proposition-lancer`) relevés dans le MÊME `ev` ; un bouton déjà armé rend un échec nommé (« bouton déjà armé : le clic précoce ne prouve rien »).
- CH5 : le clic de confiance après armement écrit la ligne SANS Entrée (argv absent pendant 2 s) ; CH6 : la touche Entrée du clavier (`Input.dispatchKeyEvent`) lance le faux `claude`, argv identique octet pour octet (acceptEdits).
- CH7 : seconde proposition, le sélecteur vaut `acceptEdits` (dernier mode lancé avec succès) ; CH8 : « Annuler » retire le bandeau et `GET /proposition` du cadre rend `aucune`.
- Aucune assertion ne lit le media `pointer` (Chrome headless Linux : `pointer: none`).

## Écarts avec le plan (le code livré fait foi)

1. `lancee` : forme riche `{ etat, verbe }` ou `false` (72-09), pas `true` (B4 asserte l'objet).
2. Q jouée dans un cadre de P, pas en premier niveau (voir plus haut).
3. L'amorçage lu par la page doit faire 64 hexadécimaux : la suite en génère 32 octets (`randomBytes(32)`), faute de quoi le cadre n'est jamais monté (relevé et corrigé pendant l'exécution, sans rien affaiblir).
4. `POST /lancer` peut rendre 504 (délai de l'assistant) : hors contrat §4, non joué ici (le client le traite comme un refus).

## Défaut constaté

Aucun défaut du code livré. Aucune assertion n'a été affaiblie ni retirée. Observation hors périmètre (no-op) : au démarrage, `serve.mjs` sonde le vrai `claude` du PATH du serveur (`asking via Claude Code CLI … (~/.local/bin/claude)`) ; c'est la détection du moteur de questions du cockpit, antérieure à la Phase 72, jamais le shell du terminal : dans la suite le shell du terminal ne voit que le faux `claude` (B0 : `command -v claude` imprime le faux).

## Ce qui n'est pas vérifié ici

- Le vrai `claude` : recette par juges avec captures, hors plan (skill `/vf-dev` ouvert, boîte de confiance du dossier, transcript dans l'onglet Équipe).
- Le rattachement visible dans l'onglet Équipe : un faux `claude` n'écrit pas de transcript ; prouvé au niveau de la table par 72-07 et 72-09.
- Linux : l'exécution sous Linux se lit sur le job de CI de la PR ; le témoin des leurres (B0) lit `/proc/<pid>/environ` sous Linux et `ps eww` sous macOS (seul ce dernier est mesuré ici).
