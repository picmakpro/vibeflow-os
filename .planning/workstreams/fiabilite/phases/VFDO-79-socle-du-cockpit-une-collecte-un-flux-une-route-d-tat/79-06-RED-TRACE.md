SEUIL-COCKPIT-LANCER=43

# 79-06 — trace des rouges sur la base, des mutants et des points d'arrêt

Plan 79-06, session S1 (tâche 1 : témoins rouges ; tâche 2 : porte de la mesure du confinement de `claude -p`). Aucun fichier de production n'a changé : l'aide `socle-serveur.sh`, cinq suites, cette trace et (tâche 2) la mesure.

La ligne 1 est le seuil lu par la tâche 6b : nombre de suites qui appellent `cockpit_lancer` après 79-02, mesuré par `rtk proxy grep -l 'cockpit_lancer' plugin/cockpit/scripts/tests/test-*.sh | awk 'END{print NR}'` (43 ; 79-05 ajoute une suite qui n'appelle pas l'aide).

## Tâche 1 — témoins AM4 rouges sur la base

Base de l'arbre d'exécution : branche de la phase, 79-01, 79-02, 79-05 faits, base d'intégration fusionnée. Les rouges sont des lignes `❌ FAIL — AM4.…` des cinq suites rejouées avec le code de production inchangé (serveur lancé depuis la copie de code de la sortie).

Commande jouée pour chaque suite : `bash plugin/cockpit/scripts/tests/test-cockpit-<nom>.sh` (une suite à la fois, sortie conservée hors dépôt). Décompte : 18 témoins AM4 rouges (securite 4, cycle-serveur 8, assemblage 2, marque-blanche 2, serveur 2), seuil exigé : 16.

| id | suite | assertion (libellé court) | attendu | obtenu sur la base | rouge parce que |
|---|---|---|---|---|---|
| AM4.1 | securite | `vf-cockpit-server.mjs` planté dans la sortie ne s'exécute jamais (témoin absent ET serveur vivant) | `absent vivant` | `présent vivant` | le serveur importe le module de la sortie : le marqueur s'exécute |
| AM4.2 | securite | cœur de requête planté dans `<sortie>/query.mjs` jamais évalué | `absent vivant` | `présent vivant` | `serve.mjs` lit `<sortie>/query.mjs` et l'évalue par `new Function` au démarrage |
| AM4.3 | securite | processus de terminal planté dans la sortie jamais lancé par `fork` (`--terminal`) | `absent vivant` | `présent vivant` | le terminal fork le fichier pris à côté de `here` (la sortie) : quatrième voie d'exécution de la sortie |
| AM4.4 | securite | témoin positif : même marqueur dans une copie du module s'exécute et le serveur de la copie démarre | `0 présent` | `1 absent` | le `serve.mjs` du module ignore `--sortie=`, cherche ses modules à côté de lui (`vf-cockpit-env.mjs absent`) et sort en échec : « le serveur du module ne démarre pas sur une sortie » |
| AM4.5 | serveur | contrat de la sortie vidé : ignoré, la garde lit celui du module, le flux émet son `hello` | `vivant hello=1` | `vivant hello=0` | le serveur lit le contrat de la sortie ; la liste vide ferme tout |
| AM4.6 | serveur | copie du module sans son contrat : serveur vivant, aucun `hello`, `/equipe.html` sans donnée | `vivant hello=0 equipe=0` | `mort hello=0 equipe=0` | rouge pour une autre raison que le contrat, comme le plan le dit : le serveur du module ne démarre pas sur une sortie (même cause que AM4.4) ; il verdit à la tâche 4a et c'est alors le contrat illisible qui ferme le flux |
| AM4.7 | cycle-serveur | un octet changé dans un module autre que `serve.mjs` d'une copie du module : le second `open` relance, journal « code du serveur changé » | `relancé journal=1` | `réutilisé journal=0` | seul `serve.mjs` de la sortie est haché par le lanceur |
| AM4.8a | cycle-serveur | serveur vivant sans `server.json` : `status` le dit vivant (PID) et le fichier reste absent | `vivant=1 fichier=absent` | `vivant=0 fichier=absent` | `status` ne lit que `server.json` : il dit « arrêté » |
| AM4.8b | cycle-serveur | serveur vivant sans `server.json` : `stop` l'arrête | `arrêté` | `vivant` | `stop` ne connaît le PID que par `server.json` (le serveur est arrêté ensuite par `cockpit_arreter`) |
| AM4.12a | cycle-serveur | module sous `.vibeflow/`, sous la sortie, ou par lien symbolique : refus code 3, rien lancé | `3/0` trois fois | `0/1` trois fois | aucun refus de module sur la base : le serveur démarre |
| AM4.13 | cycle-serveur | lab dont le chemin contient ` --sortie=` : refus code 5, rien lancé | `5/0` | `0/1` | aucun refus d'ambiguïté sur la base |
| AM4.14 | cycle-serveur | `claude --version` bloqué : lancement 0, `/api/status` 200, `/api/health` version `null` avant libération, version après | `lancement=0 status=200 avant=null après=apparue` | `lancement=4 status=000 avant=illisible après=absente` | la lecture est synchrone (`execFileSync`, borne 15 s) : `server.json` est absent à la borne de l'aide (6 s) |
| AM4.19 | cycle-serveur | serveur lancé sur une copie du module dont un octet a changé : `cockpit_module_charge` de la copie 0, du dépôt 1 | `lancement=0 copie=0 dépôt=1` | `lancement=1 copie=1 dépôt=1` | mode module inopérant sur la base : le serveur du module meurt (voir AM4.4) |
| AM4.20 | cycle-serveur | module neuf `vf-cockpit-*.mjs` ajouté à une copie puis modifié d'un octet : `open` relance ; sans modification, réutilise | `réutilisé-sans-changement relancé-après-octet journal=1` | `réutilisé-sans-changement réutilisé-malgré-octet journal=0` | la moitié « témoin positif » est verte ; la moitié « relance » rougit : l'empreinte ne couvre pas le code du module |
| AM4.15a | assemblage | sortie d'une version précédente : aucun fichier de code ni de contrat après assemblage | `0\|` (rien) | `0\|query.mjs serve.mjs vf-cockpit-…` | l'assemblage recopie le code d'exécution (63 modules) plus `serve.mjs`, `query.mjs` et le contrat |
| AM4.16 | assemblage | sortie fraîche : aucun `*.mjs` ni contrat (liste des fichiers de la sortie non vide : témoin d'exposition) | `liste-non-vide code=[]` | `liste-non-vide code=[… 66 fichiers]` | même cause ; 66 fichiers de code : 63 (`fichiersExecution`) + `serve.mjs` + `query.mjs` + le contrat |
| AM4.17 | marque-blanche | occurrences du nom amont dans les six sources (liste calculée, `compterOccurrences`) | `0` | `58` | détail : `serve.mjs`=30, `graph-query.js`=19, `query-cli.mjs`=6, `vf-cockpit-embed.mjs`=1, `vf-cockpit-lancer-post.mjs`=1, `vf-cockpit-server.mjs`=1 ; la liste jugée compte 66 fichiers (63 + 3 du moteur) |
| AM4.18 | marque-blanche | bout en bout, serveur du module : la page fournit `VF_COCKPIT_SERVER`, en-tête renommé 200, ancien 403 | `page=1 neuf=200 ancien=403` | `page=0 neuf=000 ancien=000` | le serveur du module ne démarre pas sur une sortie (même cause que AM4.4) |

Témoins verts d'emblée (négatifs et positifs : leurs mutants rougiront à la tâche 5, un témoin vert ne prouve rien tant que son mutant n'a pas rougi) :

| id | suite | pourquoi vert sur la base | pourquoi il ne peut pas rougir avant la tâche 5 |
|---|---|---|---|
| AM4.9 | cycle-serveur | leurre (réponses d'un serveur du cockpit, PID d'un autre processus) : sur la base `status` ne lit que `server.json` (absent) et `stop` ne trouve aucun PID : rien n'est sur-reconnu ; le leurre est bien en écoute (`/api/status` rend le PID attendu, vérifié dans le libellé) | il garde la détection de sur-reconnaître : seul un `status` qui scrute les ports (tâche 5) peut le faire rougir ; son mutant « reconnaissance toujours vraie » est joué à la tâche 5 |
| AM4.10 | cycle-serveur | identité par sortie : le chemin d'un lab n'est pas contenu dans la ligne de commande de l'autre (`…/lab/.vibeflow/cockpit/serve.mjs` contre `…/lab bis/…`) | seuls les mutants « chemin du module seul » et « préfixe sans fin de ligne » (tâche 5, nouvelle identité) peuvent rougir |
| AM4.11 | cycle-serveur | la forme `includes(<sortie>/serve.mjs)` de `estNotre` est celle de la base | le mutant « forme ancienne retirée » est joué à la tâche 5 |
| AM4.12b | cycle-serveur | module sous `.claude/` du lab : aucun refus sur la base, le serveur démarre | témoin positif de la garde : il rougirait si la garde refusait trop (tâche 5) |
| AM4.15b | assemblage | données conservées : `custom-flows.json` identique, `LICENSE` et `graph.json` présents (la base ne purge rien) | il rougit avec le mutant M-PURGE-LARGE (purge de tout le dossier), tâche 4a |
| AM4.17a, AM4.17b | marque-blanche | liste calculée non vide (66 fichiers) ; le compteur voit une chaîne jetable | témoins d'exposition, sans mutant |
| AM4.19b | cycle-serveur | la copie du module est complète, sans lien, et muter `assets/ui/` dans la copie laisse le fichier du dépôt identique (`cmp`) | c'est l'amendement du contrat de `cockpit_module_copie` : il ne dépend d'aucun code de production |

Ancres de mutants (`.0`) écrites à cette tâche (jouées avec le code aux tâches 4a et 5). Elles vérifient qu'un texte précis existe dans le fichier que le mutant éditera. Verte dès cette tâche : `M-CONTRAT-OUVERT.0` (la constante `porteInterdit` existe déjà) et `M-CONTRAT.0` (le contrat est déjà lu à côté du fichier du serveur par `import.meta.url`). Rouges attendues, parce que le code visé n'existe pas encore : `M-TERM.0`, `M-NOM.0`, `M-VERSION-SYNC.0`, `M-LISTE-FIGEE.0`, `M-PURGE-LARGE.0`, `M-ORDRE.0`, `M-ESTNOTRE.0`, `M-MODULE.0`, `M-PREFIXE.0`, `M-ANCIENNE.0`, `M-STATUS.0`. Contrat d'ancres que les tâches 4a et 5 doivent honorer (un nom exporté, ou un marqueur de commentaire `// m:<nom>` posé sur la ligne que le mutant édite) :

| ancre | fichier | texte exact attendu (une fois) |
|---|---|---|
| M-TERM.0 | `vf-cockpit-terminal.mjs` | `path.dirname(fileURLToPath(import.meta.url)), 'vf-cockpit-terminal-processus.mjs'` |
| M-NOM.0 | `vf-cockpit-lancer-post.mjs` | `ENTETE_JETON = 'x-vf-cockpit-token'` |
| M-VERSION-SYNC.0 | `serve.mjs` du moteur | `execFile(cli.cmd, [...cli.args, '--version']` |
| M-LISTE-FIGEE.0 | `vf-cockpit-module.mjs` | `export function fichiersCodeEvalue` |
| M-PURGE-LARGE.0 | `vf-cockpit-build.mjs` | `const CODE_ANCIEN =` |
| M-ORDRE.0 | `vf-cockpit-rename.mjs` | `export function renommerPageMoteur` |
| M-ESTNOTRE.0 | `vf-cockpit-serveur-vivant.mjs` | `export function estNotre` |
| M-MODULE.0, M-PREFIXE.0, M-ANCIENNE.0 | `vf-cockpit-serveur-vivant.mjs` | `// m:module`, `// m:prefixe`, `// m:ancienne` |
| M-STATUS.0 | `vf-cockpit-serveur-vivant.mjs` | `export function detecterServeur` |

Rouge préexistant, hors AM4 et hors ancres : `test-cockpit-securite.sh`, `FB3.5` (« le cas génératif tient en moins de 10 s »), sonde de durée qui rougit sous charge : constaté rouge dans la suite complète, identique sur un instantané de la tête d'avant les changements de cette session (91 PASS / 1 FAIL, même ligne), la machine étant chargée par les autres plans de la phase (charge de 17 à 47) ; la même mesure rejouée seule rend 9 766 ms (borne 10 000 ms : marge de 2 %). Défaut de la sonde, signalé et non corrigé (ADR-031) : il rougit le décompte « aucune assertion préexistante rouge » de la vérification de la tâche 1 tant que la charge dure. Aucune autre assertion préexistante n'a rougi dans les cinq suites.

## Baselines statiques (tâche 4a)

Mesurées sur l'arbre d'exécution avant tout changement de production :

| contrôle | base |
|---|---|
| occurrences du nom amont, par fichier (`serve.mjs`, `graph-query.js`, `query-cli.mjs`, `embed`, `lancer-post`, `server`) | 30, 19, 6, 1, 1, 1 (58) |
| moteur `build.mjs` : écriture de `query.mjs` dans la sortie, de `serve.mjs` dans la sortie | 1, 1 |
| `vf-cockpit-build.mjs` : copie du code d'exécution dans la sortie (`copyFileSync(path.join(scriptsDir, f)`) | 1 |
| `serve.mjs` : imports dynamiques depuis `here` (`new URL('./vf-cockpit`) | 3 |
| `serve.mjs` : lecture synchrone de la version (`execFileSync(cli.cmd`) | 1 |
| `vf-cockpit-terminal.mjs` : `fork` d'un fichier de `here` | 1 |
| `vf-cockpit.mjs` : lignes de l'ancienne empreinte (`empreinteCode`) | 3 |
| `vf-cockpit.mjs` : `--sortie=` | 0 |
| `vf-cockpit-agent.mjs` : règle Bash relative à la sortie (`Bash(node .vibeflow`) | 1 |
| fichiers de code dans une sortie assemblée | 66 |

Occurrences de `sleep` par suite (baseline du critère « aucune pause fixe ajoutée », avant et après la tâche) : securite 0 et 0, cycle-serveur 9 et 9, assemblage 1 et 1, marque-blanche 1 et 1, serveur 3 et 3. Le faux `claude` de AM4.14 attend un fichier de libération par une boucle d'horloge en node, jamais par un `sleep`.

## Aide `socle-serveur.sh` — contrat posé à cette tâche

`COCKPIT_MODULE` (racine d'un module, facultatif ; absente : ancien comportement, aucune variable ajoutée) ; `--sortie=<chemin réel>` placé en dernier argument ; `VF_COCKPIT_SCRIPTS_DIR` et `VF_COCKPIT_ENGINE_DIR` posés sur la racine, sauf valeur passée par la suite (elle gagne : l'ordre des `NOM=valeur` suit) ; code 5 de `cockpit_lancer` quand le serveur lancé ne publie pas l'empreinte de la racine visée. `cockpit_module_copie [destination]` (amendement de revalidation : copie complète, sans lien, jamais le moteur lié ; imprime seul la racine ; n'exporte rien), `cockpit_module_muter`, `cockpit_module_charge`, `cockpit_vivant`, `cockpit_exporter`. Hypothèses que la tâche 3 et la tâche 4a doivent tenir : `vf-cockpit-module.mjs` exporte `empreinteModule({ dossierScripts, dossierMoteur })` (12 caractères hexadécimaux, `null` si un fichier est illisible) et `server.json` publie la clé `hash` ; `/api/status` publie `hash` (12 caractères hexadécimaux : contrôle de vie). La copie du module comprend `scripts/` (sans `tests/`) et `skills/` ; le module de signal et les fichiers documentaires n'y sont pas.

Contrôles de l'aide (`OK-AIDE`) : marqueurs `am7:` présents (5), aucun `trap`, `kill` ou `set -` hors commentaire (0), aucun chemin du poste (0).

## Point d'arrêt S1 (tâche 2)

Commits `(79-06)` de la session : 81168f4f (aide), 10604d3f (témoins et trace), e1a1238c (mesure). Aucun fichier de production touché ; fichiers touchés : l'aide, cinq suites, cette trace, `79-MESURE-claude-p.md` (tous dans `files_modified`).

Mesure : 46 appels réels (Claude Code 2.1.322, haiku), verdict CONFINABLE, combinaison retenue de 13 éléments avec le gabarit `<module>` dans les deux règles Bash. Chemin nominal et lien tiennent (règle et commande doivent porter le même chemin textuel) ; dossier avec espace non admis par `argsAgent` (la forme guillemetée tient : décision de produit, non prise) ; alphabet admis : lettres, chiffres, `.` `-` `_` `/` `~` `@` `+` ; `(` et `)` échouent. Sortie brute conservée hors dépôt (dossier du banc du nœud x06, fichiers `RESULTATS.md`, `RESULTATS-2.md`, `sortie-brute/`).

État attendu des rouges à la reprise (S2) : les 18 témoins AM4 rouges de la tâche 1 le restent jusqu'aux tâches 4a et 5 ; FB3.5 est une sonde de durée préexistante, instable sous charge.

Constat bas 1 de l'audit de 79-07 (`realUnder` en polarité inverse sans `siEchec: true`, `vf-cockpit-terminal.mjs`, fonction `ordinaire`) : non traité en S1 (fichier de production, tâche 4a). Analyse préalable : `lstat(f).isFile()` précède `realUnder`, qui résout le même fichier : aucun cas déterministe ne fait réussir l'un et échouer l'autre (seule une course), donc aucun témoin d'effet constructible ; l'amendement daté dira cela, posera le correctif d'une ligne et une ancre structurelle avec son mutant.

## Reprise après la porte de la tâche 2

Réponse de la session principale, rendue le 2026-11-12 à 01 h 58 (heure lue), par message de la session principale : « confinable : combinaison retenue écrite dans 79-MESURE-claude-p.md (limites : dossier de module avec espace non admis, refus fermé ; alphabet admis lettres, chiffres, . - _ / ~ @ + ; règle et commande au même chemin textuel ; une seule version de Claude Code, 2.1.322, sur macOS, un appel par cas) ». La mesure était autorisée d'avance par Samuel (AskUserQuestion session principale, 2026-11-11, « Oui, d'avance (Recommandé) ») ; Samuel n'a pas relu la mesure.

Contrôles de la session principale avant sa réponse : le document relu en entier ; les 46 relevés bruts recomptés depuis les flux (outils tentés, refus du résultat final, mode annoncé à l'initialisation), tous concordants avec le tableau ; effets de bord revérifiés dans cinq bacs à sable (B1, B3 et B1 en V4b sans fichier créé ; B1 en V4w avec fichier créé, le banc sait voir un non-refus ; B2a avec une ligne d'appel) ; OK-MESURE rejoué vert ; les commits de S1 ne touchent aucun fichier de production.

Bornes pour S2 : (1) l'alphabet de la tâche 3 suit le document de mesure ; (2) la variante « dossier avec espace admis par la forme guillemetée » n'est pas faite dans ce plan : décision de produit portée à Samuel par la session principale ; refus fermé, dit en clair à l'utilisateur.
