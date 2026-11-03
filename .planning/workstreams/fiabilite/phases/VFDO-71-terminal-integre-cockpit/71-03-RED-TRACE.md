# 71-03 — trace du rouge (suite jouée sur la base de 71-01, avant tout code)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-terminal-pty.sh` sur HEAD `ed13e6a8` (assistant et filtre de 71-01 intacts).
Résultat : `Résultats : 24 PASS / 8 FAIL`, rc=1, `H0` vert (aucun survivant de la suite). Commit des témoins : `9ee45e09`.

## Rouges sur la base (assertion, attendu, obtenu)

| Sonde | Attendu | Obtenu |
|-------|---------|--------|
| T10.1 absentes : CLAUDECODE, CLAUDE_CODE_FOO, CLAUDE_CODE_ENTRYPOINT, VF_COCKPIT_X | `0` | `3` (seul `VF_COCKPIT_X` est retiré par la tranche) |
| T10.8 serveur, passe 1 (TERM=vt100, COLORTERM absent) | `COLORTERM=truecolor TERM=xterm-256color` | `TERM=vt100` |
| T10.8 serveur, passe 2 (TERM=dumb, COLORTERM=24bit) | `COLORTERM=truecolor TERM=xterm-256color` | `COLORTERM=24bit TERM=dumb` |
| T10.5 `envShell` unitaire (clés restantes) | `AUTRE,CLAUDE_AUTRE,COURT,NODE_OPTIONS` | `AUTRE,CLAUDECODE,CLAUDE_AUTRE,CLAUDE_CODE_X,NODE_OPTIONS` |
| T10.8 `envShell` unitaire (4 entrées) | `xterm-256color\|truecolor` x4 | `vt100\|undefined dumb\|24bit undefined\|undefined undefined\|24bit` |
| T10.6 `choisirShell` | `relatif=oui sans-x=oui dossier=oui absent=oui valide=oui` | `relatif=oui sans-x=non:<pas-exec> dossier=non:<dossier> absent=oui valide=oui` |
| T12.4 cinq processus vivants, serveur tué par SIGKILL, aucun survivant après 5 s | `5 aucun` | `5 survivants` |
| M-SI-ABSENT | `effet` | `sans effet` (la constante `AJOUTS_TOUJOURS` n'existe pas encore : l'ancre du mutant manque, attendu sur la base) |

## Écart avec le plan : verts sur la base alors que le plan les annonçait rouges

- **T11.2** (`stty size` = `50 132` après `POST /taille`) et **T13.3** (`WINCH 50x132` après la taille) : verts sur la base. L'assistant posé par 71-01
  applique déjà les lignes `R <l> <c>` du descripteur 3 par `TIOCSWINSZ`. Ces sondes ne sont pas aveugles : le mutant **M-RESIZE** (lignes `R` ignorées)
  les fait rougir, obtenu `ABSENT ABSENT` pour `SZ1-50x132` puis `WINCH 50x132`. Le critère `fails_when` du plan (« T13.3 vert sur la base = sonde aveugle »)
  suppose à tort que la base ne redimensionne pas ; la preuve de sensibilité est le mutant.
- **T12.4** : rouge sur la base alors que le plan le voulait vert sur la base et rouge sur M-NOEOF. Défaut réel de la tranche : l'assistant n'envoie SIGHUP
  qu'au groupe du shell ; `bash -i` s'étant mis dans son propre groupe, ni lui ni ses travaux ne reçoivent le signal (A5 : le groupe de premier plan du terminal
  est celui qu'il faut atteindre, `os.tcgetpgrp`).

## Verts sur la base, rouges sur leur mutant (obtenu du mutant)

| Sonde | Mutant | Obtenu sur le mutant |
|-------|--------|----------------------|
| T10.2 (AUTRE, NODE_OPTIONS présentes) | M-ENVLARGE (liste blanche PATH, HOME, SHELL) | PATH `1`, AUTRE et NODE_OPTIONS `0` |
| T10.3 (`pwd -P` = lab, serveur lancé hors du lab) | M-CWD (`cwd: process.cwd()`) | `pwd -P` = dossier hors du lab |
| T10.4 (`-l`) | M-SANS-L (neuvième mutant, hors plan) | arguments du shell vides |
| T11.1 (`python3 -I <moteur>/terminal/vf-cockpit-pty.py`) | M-SANS-I | ligne de commande sans ` -I ` |
| T11.3 (0x03 interrompt le premier plan, shell vivant) | M-SIGINT / M-CTRLC | `non non` (shell tué) / `oui oui` (dormir survit) |
| T13.1, T13.2, T13.4, T13.5 | aucun mutant propre ; le témoin positif est le même flux (PRET, ESC[?1049h, 48;5;, 38;2;255;100;0m) | verts sur la base |
| T12.4 (rouge sur la base) | M-NOEOF (EOF du fd 0 ignoré) | `5 survivants` |
| T11.5 (`FIN 3` sur fd 2) | aucun | vert sur la base, gardé |
