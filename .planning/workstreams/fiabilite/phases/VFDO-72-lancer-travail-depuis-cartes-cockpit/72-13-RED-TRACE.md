# 72-13 — trace

## Porte A5 (tâche 0, P72-D-03) — la session du chat, reprise en interactif, retrouve-t-elle ses outils et ses réglages ?

**Sonde A5 : VERTE — 2026-11-05, claude 2.1.318 (Claude Code)**

Voie : **fidèle** (serveur du cockpit réel sur le lab jetable, `POST /api/ask`). Aucun repli.
Essai retenu : essai 2, 2026-11-05T21:22:47+0100, aléa `F40BB723`. HEAD de l'arbre au moment de la sonde : `68a809d9`.
Pilote : `sonde_a5.py` (Python, toutes les attentes bornées en Python ; ni `timeout` ni `gtimeout`).
Artefacts (hors dépôt) : `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/5237320c-23bb-4599-a818-cdbd167e39c2/scratchpad/sonde72/a5/`
(`run2.out` et `journal.txt` journal complet, `s3-sse.txt` flux SSE du chat, `s4-pty-brut.bin` et `s4-pty.txt` sortie du PTY brute et sans ANSI, `releves.json`).

### Étapes et commandes

- **S1 Environnement.** `os.environ` filtré comme `envShell` (retirés : `CLAUDECODE` et tout `CLAUDE_CODE_*`, `VF_COCKPIT_*` ; `TERM=xterm-256color`, `COLORTERM=truecolor`).
  Clés retirées mesurées : `CLAUDECODE`, `CLAUDE_CODE_BRIDGE_SESSION_ID`, `CLAUDE_CODE_CHILD_SESSION`, `CLAUDE_CODE_ENTRYPOINT`, `CLAUDE_CODE_EXECPATH`,
  `CLAUDE_CODE_MESSAGING_SOCKET`, `CLAUDE_CODE_MESSAGING_TOKEN`, `CLAUDE_CODE_SESSION_ATTENDED`, `CLAUDE_CODE_SESSION_ID`, `CLAUDE_CODE_SSE_PORT`. HOME réel conservé.
- **S2 Lab jetable.** `mktemp -d "$TMPDIR/sonde72-a5.XXXXXX"` → `LAB=/var/folders/9t/…/T/sonde72-a5.yoFKlE` (non résolu),
  `LABR=/private/var/folders/9t/…/T/sonde72-a5.yoFKlE` ; `git -C "$LAB" init -q` ; `.planning/PROJECT.md` minimal ;
  `$LAB/CLAUDE.md` : « Si on te demande le mot du lab, reponds exactement MOT-LAB-A5-F40BB723 ».
- **S3 Session du chat.** `node plugin/cockpit/scripts/vf-cockpit.mjs open --no-open --lab "$LAB" --port 4907` (rc 0, serveur PID 14494, port 4907),
  jeton lu dans `$LAB/.vibeflow/cockpit/.cache/server.json`, puis `POST http://127.0.0.1:4907/api/ask`, corps
  `{"question":"Retiens ce fait : le mot de passe de la sonde est SESAME-A5-F40BB723. Réponds seulement OK.","mode":"ask"}`.
  En-tête de jeton : **`x-vf-cockpit-token`**. Dans la sortie assemblée, l'en-tête s'appelle ainsi, et non `x-floorplan-token` comme dans `assets/serve.mjs` du moteur.
  Le premier essai avec `x-floorplan-token` a rendu `403` (mesuré sur `/api/status` et `/api/ask`). Jeton principal, et non le jeton de la page Projet : `body.project` est faux, `answerLocally` n'est pas consulté.
  Évènements SSE obtenus : `start`, `progress` « Write » (refusé : l'agent du chat est confiné), `progress` « StructuredOutput »,
  `answer` = `{"title":"OK","answer":"OK","items":[],"session":"7c7d7412-0a15-4407-939b-eacb01a8e345"}` en 6,6 s.
  **Forme réelle de l'évènement que l'observateur lira : `event: answer`, champ `session` de `data`, qui passe `/^[0-9a-f-]{36}$/i` (oui).**
  Transcript du chat : `~/.claude/projects/-private-var-folders-9t-1m3f81vn3bd677kc1tzbg2zm0000gn-T-sonde72-a5-yoFKlE/7c7d7412-….jsonl`.
  Il est rangé sous le slug du chemin **résolu**, alors que le serveur a été lancé avec `--lab` non résolu.
- **S4 Reprise.** La ligne vient de `composerLigne({ phase: '72', ws: 'fiabilite', verbe: 'cadrer', mode: 'acceptEdits', session: <uuid4>, chat: <S3> })` (gabarit 72-01), `ok: true` :
  `claude --session-id 'a7eb8b0b-0eef-4bd5-ad04-012abb2af4cb' -r '7c7d7412-0a15-4407-939b-eacb01a8e345' --fork-session -n 'vf-phase-72-fiabilite' --permission-mode 'acceptEdits' '/vf-dev Cadre la Phase 72 du compartiment fiabilite'`.
  Seul le dernier argument est remplacé, par « Réponds en une ligne : mot=<le mot de passe de la sonde> ; lab=<le mot du lab>. Puis crée avec l'outil Write le fichier PREUVE-OUTIL-A5.txt contenant OK. ».
  Jouée dans un PTY (`pty.fork`, 160×50), `cwd = $LABR`, argv obtenu par `shlex.split` de la ligne du gabarit puis `execvpe` (voir Limites).
  La boîte de confiance est apparue à 1,9 s. Réponse envoyée : flèche bas puis Entrée. Fichier présent et marqueur vu à 18,1 s.
  Arrêt à 22,3 s : `SIGTERM` puis `SIGKILL` du groupe de l'enfant (PGID 50328, distinct de celui du pilote).

### Relevés (S5)

| Relevé | Obtenu | Preuve |
|--------|--------|--------|
| R-HISTORIQUE | oui | la sortie du PTY contient `⏺mot=SESAME-A5-F40BB723;lab=MOT-LAB-A5-F40BB723` (espaces écrasés par le rendu) |
| R-REGLAGE | oui | même ligne : `MOT-LAB-A5-F40BB723`, la valeur que seul le `CLAUDE.md` du lab porte |
| R-OUTIL | oui | `$LABR/PREUVE-OUTIL-A5.txt` existe et vaut `OK\n` ; PTY : `⏺Write(PREUVE-OUTIL-A5.txt)` / `Wrote 1 line to PREUVE-OUTIL-A5.txt`, sans refus. Write fonctionne alors que le chat d'origine l'avait refusé (`progress` « Write », confinement `dontAsk` + `--tools Read,Grep,Glob,Bash`) |
| R-SUIVI | oui | `~/.claude/projects/-private-var-folders-9t-1m3f81vn3bd677kc1tzbg2zm0000gn-T-sonde72-a5-yoFKlE/a7eb8b0b-0eef-4bd5-ad04-012abb2af4cb.jsonl` existe : 88 lignes, contient les deux marqueurs, ses entrées ne portent que `sessionId = a7eb8b0b-…` (le fork honore `--session-id` avec `-r`) |
| R-COPIE | oui | transcript du chat : 85 299 octets, sha256 `db075b9b…c055`, avant comme après. La mesure « avant » a été prise après 8 s de stabilité (voir Essai 1) |

Aucun relevé supposé : les cinq viennent de l'essai 2, d'après les fichiers et la sortie listés plus haut.

### Essai 1 (écarté, sortie du PTY perdue)

L'essai 1 date du 2026-11-05T21:17:12+0100 (aléa `9A9BB67B`). Le pilote est resté bloqué dans `os.waitpid` après S4. Un échantillon `sample` du processus le montre dans `__wait4`. Il n'a donc écrit ni la sortie du PTY ni le nettoyage. Le nettoyage (serveur, lab, deux transcripts) a été fait à la main, puis le pilote bloqué a été tué par `kill -9`.
R-HISTORIQUE et R-REGLAGE n'ont donc pas de preuve de sortie pour cet essai. Le transcript du fork (copie `essai1-fork.jsonl`) montre pourtant :
- le Write réussi, puis la ligne `mot=SESAME-A5-9A9BB67B ; lab=MOT-LAB-A5-9A9BB67B` ;
- un faux positif de R-COPIE évité. Le transcript du chat a grandi de 831 octets après l'évènement `answer`. Ces entrées `last-prompt` et `cost-state` sont écrites par le processus `claude -p` du chat à sa sortie (`lastPrompt` = la question du chat), et non par le fork.
Correctif de l'essai 2 : la taille « avant » se mesure après stabilité du fichier.
Pilote durci ensuite : sortie écrite au fil de l'eau, signaux journalisés, arrêt de l'enfant sans `waitpid` bloquant.

### Nettoyage (S7)

- `vf-cockpit.mjs stop --lab "$LAB"` : « Cockpit arrêté. », PID 14494 mort. `$LAB` supprimé.
- Seuls les deux transcripts de chaque essai ont été supprimés sous `~/.claude/projects/` (`7c7d7412-….jsonl`, `a7eb8b0b-….jsonl` ; essai 1 : `a90b51c5-….jsonl`, `10de3951-….jsonl`).
- Aucun processus de la sonde vivant au retour.

### Limites

- La sonde vaut pour `claude 2.1.318` ; une montée de version la périme (limite à écrire au README par 72-15).
- La ligne a été jouée en `execvpe` de l'argv issu de `shlex.split`, et non tapée dans un shell : le prompt de sonde contient une apostrophe, hors de l'alphabet fermé. L'argv est identique à celui que le shell produirait avec la ligne livrée.
- Effets de bord laissés, conformément à la règle « ne supprimer que les transcripts ». Le fork reprend la mémoire automatique de l'utilisateur et a écrit `memory/MEMORY.md` et `memory/sonde-password.md` sous le dossier de projet du slug `…sonde72-a5-yoFKlE` (PTY : « Wrote 2 memories »). Les deux dossiers de slug (`…-XsrjJF`, `…-yoFKlE`) restent, et l'acceptation de confiance des deux dossiers jetables reste inscrite dans `~/.claude.json`.
- C'est une confirmation supplémentaire de R-REGLAGE : la session reprise charge la configuration complète de l'utilisateur (mémoire automatique, hooks Stop visibles dans le PTY : « running Stophoks… 0/4 », texte brut du rendu).
- Les hooks utilisateur ont tourné dans la session reprise. Le lab jetable n'avait pas VibeFlow installé : le skill `/vf-dev` n'a pas été exercé, et la sonde ne le visait pas.

## Rouge (tâche 1) — suite `test-cockpit-lancer-chat.sh` jouée sur la base, sans le code du plan

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-chat.sh` — HEAD `2c73b795` (arbre : suite seule ajoutée, aucun fichier de code touché). Résultat : 17 PASS / 18 FAIL, rc 1.
Sortie : `/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/13e1f1c3-f616-4fb2-9ff3-f349e3c3e010/scratchpad/r72-13/rouge3.out`.

- **TC.1** — attendu `ok`, obtenu `ABSENT : extraireSessionChat` (l'export n'existe pas).
- **TC.2** — attendu `ok`, obtenu `ABSENT : installerObservateurChat`.
- **TC.3** — attendu `ok`, obtenu `ABSENT : corpsProposition`.
- **TC.4** — attendu `true/true/true/true`, obtenu `///` (aucune constante `CHAT_LIVRE` ni dans le script de P ni dans la vue de Q) ; `corps` attendu `cible,verbe,chat`, obtenu vide.
- **TC.6** — attendu `true|checkbox|false|Continuer la conversation du chat|true|1`, obtenu `false|||||` (aucune case) ; les trois mesures suivantes (lignes, rappel, hostile) tombent sur `erreur: élément introuvable` (la case manque). Témoin vert : « sans chat : aucune case » (`0|0|0|0`).
- **TC.7** — attendu `[{"type":"checkbox",…},{…}]`, obtenu `[null,null]` ; erreurs nommées `e1` et `e2` : `attente de « case dans le bandeau de Q » dépassée (20000 ms)`. Les deux `POST /api/vf/lancer` rendent 202 (témoin positif : l'infrastructure, le tiroir, le terminal connecté et la proposition arrivent bien jusqu'à Q).
- **Mutants** — les six annoncent « mutant sans effet (cible absente ou inchangée) » sur la base, sauf `M-CHAT-NON-VALIDE-P` et `M-CHAT-NON-VALIDE-Q` (voir « Écarts »).

### Sonde boîte noire de « Interface exigée de Q » (TC.5, sans lire le code de Q)

Les trois points de l'interface sont DÉJÀ tenus par le code livré (72-05 amendé, 72-10), aucun arrêt `human_needed` :
1. `chat` forgé (`x;touch M`, `$(touch M)`, 37 caractères, vide, nombre, tableau, 35 caractères + point-virgule, `null`) : 8 propositions sur 8 ignorées (`GET /proposition` = `aucune`), `POST /lancer` → 404, 0 octet capturé, aucun fichier `M`.
2. `chat` valide : `GET /proposition` porte `chat: true` et `lignes_chat` (quatre modes), égales à `composerLigne` du gabarit 72-01 pour la session relevée, `lignes` sans `-r` (verdict `ok`).
3. `POST /lancer { id, mode, chat }` : `true` → 204 et capture = `lignes_chat[mode]` ; `false` ou absent → 204 et capture = `lignes[mode]` ; chat chaîne ou nombre, champ `ligne` → 400, 0 octet ; avant armement 425.

### Écarts constatés (code livré contre le plan écrit)

- **Octet `\x03` en tête** : la capture du shell témoin vaut `\x03` + ligne (contrat §4 de 72-02 : Ctrl-C puis la ligne, sans `\r`), et non la ligne seule ; la suite l'attend ainsi.
- **TC.5 et la route de P sont verts sur la base** : le plan les croyait rouges, parce que 72-05 et 72-10 portaient seulement la variante « reprise seule ». Le code livré porte déjà les deux jeux de lignes. Ils restent dans la suite comme gardes de non-régression et comme preuve boîte noire.
- **`M-CHAT-NON-VALIDE-Q` ne peut pas rougir TC.5b** : retirer le test d'UUID de Q laisse le gabarit (`composerLigne`, `validerLigne`) refuser l'identifiant forgé. Défense en profondeur sur au moins trois couches (forme de Q, motif du gabarit, alphabet et grammaire). La suite l'asserte comme « absorbé » (propositions forgées toujours ignorées, 0 octet) au lieu d'un rouge fabriqué.
- **Majuscules** : le motif `/^[0-9a-f-]{36}$/i` du plan, repris par P et Q, accepte un UUID en majuscules que le motif du gabarit (minuscules seules) refuse : la proposition est alors ignorée en silence. Fail-closed, sans conséquence (les identifiants de `claude` sont en minuscules).
- **Shell témoin** : il écrit `VFP> ` avant `stty raw -echo` ; sans octet initial, le flux de Q n'ouvre pas ses en-têtes et la page n'émet jamais `etat:connecte` (premier essai du TC.7 : `tiroir ouvert et terminal connecté dépassée`).
