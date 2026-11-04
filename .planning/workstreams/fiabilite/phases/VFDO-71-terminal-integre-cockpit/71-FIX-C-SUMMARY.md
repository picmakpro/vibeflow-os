# 71-FIX-C — dernier tour de mineurs hors sécurité (correction ciblée)

Branche `feat/phase-71-terminal`, partie de `cee17a76`. Périmètre tenu : N1 (aperçu du bandeau de collage) et N2 (résolution par PATH de
`open`, `xdg-open`, `ps`) ne sont pas touchés ; `ps` reste lancé par `execFileSync('ps')` dans `estNotre`, `open` et `xdg-open` par leur
nom dans `ouvrir()`. Aucun `gsd-tools state.*`, ni STATE, ROADMAP, CONTEXT, REQUIREMENTS.

## Méthode des témoins rouges

Chaque constat a un mutant nommé, installé dans la suite (donc rejoué à chaque exécution) : le mutant est une copie du moteur ou de la
sortie dont la ligne corrigée est retirée, et son assertion attend la valeur rouge. Un mutant « sans effet » est un FAIL de la suite.
Le mutant reproduit le comportement du HEAD d'avant correctif sur le point en cause.

| Constat | Mutant (témoin rouge) | Valeur rouge observée | Assertion verte |
|---|---|---|---|
| M1 branche « shell sorti » | `M-SORTIE-SANS-KILL` (retire `sigkill_session(pid, gs)` de `main()`) | `avant=2 survivants=2 fin=code=0 sig=null` | T12.6a `avant=2 survivants=0` |
| M1 SIGTERM, fin du fd 0 | `M-ARRET-SANS-KILL` (retire les deux `sigkill_session` de `arreter()`) | `survivants=2` pour `term` et pour `eof` | T12.6b, T12.6c |
| M2 relevé vide | `M-RELEVE-VIDE` (`if moi in r` -> `if True`) | `membres=[] vivants=False` | T12.7a `membres=None vivants=True` |
| M3 zombie | `M-ZOMBIE` (retire le filtre `not e.startswith('Z')`) | `Z=True S=True` | T12.7d `Z=False S=True`, T12.7b zombie réel `etat=Z zombie=False` |
| M3 lecture de l'état | `M-ETAT-PROC` (état lu un caractère trop tôt) | `Z=  absent=None` | T12.7e `Z=Z absent=None` |
| N4 chef réapé | `M-CHEF-REAPE` (`if CHEF_REAPE and p == sid` -> `if False`) | `avant=True apres=True` | T12.7c `avant=True apres=False` |
| M3 / N5 escalade | `M-SANS-SIGKILL` (retire `kill('SIGKILL')` de la garde du serveur) | l'assistant factice qui ignore SIGTERM survit | N5.1 `ancien=mort nouvelle=autre assistant` |
| M4 / N6c tranches | `M-TRANCHE` (`tranche = 1 << 30`) | `max>65536=true n413>=1=true` | M4.1 `max<=65536 n413=0 tranches>=3 cksum=ok` |
| M4 / N6c 413 | `M-413` (retire la branche 413) | `cksum=perdu` (saisie perdue sans signal) | M4.2 `cksum=ok n413>=1 accepte<=4096` |
| M6 / N6b erreur de l'ouvreur | `M-OUVREUR-ERREUR` (retire `enfant.on('error', dire)`) | code ≠ 0 et trace `node:internal` | L14 `0 trace=0 ENOENT=1 page=1 dit=1` |
| M6 / N6b amorçage non échangé | `M-SANS-ANNONCE` (message neutralisé) | succès muet, 0 occurrence du message | L15 `0 dit=1 navigateur=1 page=1 snap=1` |
| M6 / N6b témoin positif | `M-TOUJOURS-ANNONCE` (annonce même après échange) | message présent avec un ouvreur conforme | L15 témoin `0 dit=0 rapide=oui echange=200` |
| N6a lien planté | `M-SANS-RATTRAPAGE` (`main();` nu) | `1 trace=oui` (code 1 et trace de pile) | L4 `4 0 1` |
| M5 mode | `git ls-files -s` avant : `100644` | `100644` | `100755` après `git update-index --chmod=+x` |

## Ce qui a changé

- `vf-cockpit-pty.py` : `releve()` rend `{pid: état}` (`/proc/<pid>/stat`, sinon `ps -A -o pid=,stat=` en chemin absolu) et vaut `None` si le
  relevé ne contient pas `os.getpid()` ; les états Z sont écartés de `membres()` ; `CHEF_REAPE` empêche de signaler `p == sid` après
  réapage du chef (`vise()`).
- `vf-cockpit-terminal-session.mjs` : après `FERMETURE_MAX_MS` (6 s) SIGTERM, 1 s plus tard SIGKILL sur l'assistant, 1 s plus tard la place est
  rendue (au plus 8 s après l'échéance de la grâce) ; réglage de test `VF_COCKPIT_TERM_FERMETURE_MS` (100 à 30 000, comme la grâce).
- `vf-cockpit-terminal-client.mjs` : file d'entrée consommée par tranches de 64 Kio au plus (`extraire`) ; 429 rejoue la même tranche ;
  413 réduit la tranche puis, à un octet, écrit un message dans le terminal (aucun fichier de vue touché).
- `vf-cockpit.mjs` : l'erreur asynchrone du `spawn` de l'ouvreur est rattrapée ; `attendreOuverture` attend l'échange de l'amorçage
  (`OUVERTURE_MS` 15 s, réglage de test `VF_COCKPIT_OUVERTURE_MS`) et sinon le dit avec la page à ouvrir à la main ; `main().catch` : message
  en une ligne et code documenté (4 pour le lien symbolique), jamais de trace. P71-D-27 inchangé (page 0600, jeton hors argv, 60 s).
- README et CHANGELOG : vraie borne de fermeture, saisie en tranches, limite Linux (Firefox snap, `.html` associé à un éditeur), zombie.

## Notes

- Sous macOS `getsid(2)` échoue sur un zombie, sous Linux il réussit : le mutant `M-ZOMBIE` est donc rejoué sur un relevé qui déclare Z un
  processus vivant (T12.7d), seul moyen de le rougir sur les deux plateformes ; le zombie réel (T12.7b) vérifie la lecture de l'état.
- Le chemin `/proc` n'a pas été exécuté sous Linux sur ce poste (macOS) : il est couvert par `etat-proc` (faux `/proc`) et le repli `ps`
  par l'exécution réelle ; à confirmer par la CI Linux.
- Le test unitaire de l'assistant désactive l'écriture de bytecode : un `__pycache__` à côté de `vf-cockpit-pty.py` rougirait
  `synchro.sh verifier` (écart constaté puis corrigé en cours de lot).
- L'amorçage consommé est la seule preuve d'ouverture : si l'amorçage est échangé par un autre moyen que l'ouvreur dans les 15 s, le lanceur
  ne peut pas le distinguer (sans conséquence : le terminal est ouvert).

## Suites

Rejouées une à une après les commits de code : activation, client (57/0), lanceur (69/0), page, serveur, session (40/0), tiroir, xss, xterm,
toutes rc 0. `test-cockpit-terminal-pty.sh` : un premier rejeu rc 1 (63 assertions, 1 FAIL : mon attendu du mutant `M-ETAT-PROC` oubliait
l'espace lue, corrigé au commit suivant), puis trois rejeux rc 0 (63 PASS / 0 FAIL). Gates : `synchro.sh verifier` (amont retrouvé à l'octet),
`check-machine-paths.sh`, `check-file-size.sh --all` (0 avertissement), `check-python-isolation.sh` : verts.
