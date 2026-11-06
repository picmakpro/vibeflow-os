# 78-09 — traces rouge / vert (GITC-11, P78-D-15, P78-D-23)

Commande commune : `bash plugin/cockpit/scripts/tests/test-cockpit-git-signature.sh`

## Tâche 1 — témoin rouge du signal Git (avant tout code de production)

Tête : sans `vf-cockpit-git-signature.mjs`, `vf-cockpit-live.mjs` inchangé.

| Assertion | Attendu | Obtenu (rouge) |
|---|---|---|
| R1.0 témoin : serveur, jeton, git emballé | oui | oui (PASS) |
| R1.0b témoin : le client reçoit le `hello` | 1 | 1 (PASS) |
| R1.1 11 s sans changement : 0 événement git | 0 | 0 (PASS, non vacuité garantie par R1.0b) |
| R1.2a un commit : au moins un événement git | oui | non (FAIL) |
| R1.2b charge `at,seq,sig` + sig de 16 hexadécimaux | at,seq,sig\|true | null (FAIL) |
| R1.2c événement en moins de 8 s | oui | non (FAIL) |

Résultat : 4 PASS / 3 FAIL. Rouge sur R1.2, comme annoncé par le plan.
Défaut trouvé au premier jeu : R1.2c passait à vide (aucun événement : latence négative < 8000). Garde ajoutée (événement présent ET latence >= 0).

## Tâche 1 — vert

`vf-cockpit-git-signature.mjs` (neuf, 28 lignes) + accroche dans le filet de `vf-cockpit-live.mjs` : 7 PASS / 0 FAIL (R1.0, R1.0b, R1.1, R1.2a, R1.2b, R1.2c, H0).
`grep setInterval` et `grep 'log'|'status'|'diff'` sur le module : aucune ligne.

## Tâche 2 — rouge avant l'écouteur de la page (reprise après crash)

`70-vf-live.js` non touché ; sections R2 à R4 et mutants ajoutés à la suite. Premier jeu (écouteur posé, suite écrite) : 23 PASS / 4 FAIL, tous défauts de TEST, corrigés :
- R2.2a et R2.2c : l'argv journalisé commence par `--no-optional-locks -c core.fsmonitor=false` ; extracteur `sous_cmds` qui écarte les options globales.
- R3.1 (page `/`) : `server.json` lu à moitié écrit, port 0 (ECONNREFUSED 127.0.0.1:80) ; `build_serve` relit jusqu'à un port et un jeton valides.

## Tâche 2 — vert : 27 PASS / 0 FAIL / 0 SAUTÉ

Mutants (copie du module par `mkmod`, mutation d'UNE occurrence, la suite refuse un motif absent ou multiple) :

| Mutant | Mutation | Sonde rougie | Preuve |
|---|---|---|---|
| M-POLL | `if (gs && gs !== gitSig) {` -> `if (gs) {` | R1.1 | hello reçu (témoin) puis événements git > 0 sans changement |
| M-LOG | `for-each-ref` -> `log -1 --all --format=%H` | R2.2b | journal d'argv non vide (témoin) puis `log` vu > 0 |
| M-RELAIS | `addEventListener('git'` -> `'git-retire'` | R3.1 | `atteint=false`, `signaux=0`, alors que la page réelle reçoit le signal sur la même procédure |

Non-régression : `test-cockpit-reconnexion.sh`, `-vie.sh`, `-who.sh`, `-reseau.sh` : rc 0.

## Correction revue serveur (2026-11-06, mandat mgr78-reprise) — R2 (S3) coût de la signature

Défauts : (a) R2.3 mesurait `$REAL_HOME/Documents/dev/vibeflow-os`, un chemin de poste ; (b) plafond dur de 50 ms sur trois git (48 à 55 ms mesurés sous charge par la revue). Rouge AVANT : la suite d'avant (copie `78-revue-srv-signature-avant.sh`) rejouée avec un `HOME` sans dépôt, `SIGNAL_SANS_NAVIGATEUR=1` (log `78-revue-srv-r2-rouge.log`) : `coût mesuré … ce dépôt NULL 0.01 ms`, R2.3 attendu `oui` obtenu `nul`. Le rouge vient du chemin codé en dur.
Après : la mesure vise le dépôt de la suite (`git rev-parse --show-toplevel` depuis le dossier du script) ; hors dépôt R2.3b est SAUTÉE et comptée (`${SKIP}`), jamais un PASS ; le plafond est de 250 ms sur la médiane de 7 appels (R2.3a fixture, R2.3b dépôt de la suite). Vert APRÈS : voir SUMMARY (suite complète, Chrome inclus).
Mutants : M-LOG existant (un `log -1 --all` dans la signature) rougit toujours, par l'argv journalisé (R2.2b), le temps d'un `log` n'étant pas discriminant (un git comme un autre). Nouveau M-SIG-LENTE (400 ms d'attente avant l'échéance du tick) : la mesure dépasse le plafond, R2.3a rougit pour son coût ; la fixture saine reste sous le plafond.
Aussi : `R5.6` attend `lireGit` (désormais asynchrone, P78-D-41).
