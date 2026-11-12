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

Rouge préexistant connu, jugé seul : `test-cockpit-securite.sh`, `FB3.5` (« le cas génératif tient en moins de 10 s »), à la limite par construction : la sonde mesure une durée contre une borne de 10 s. Rejouée seule : 9 766 ms pour une borne de 10 s (marge de 2 %) ; sous charge (charge machine de 17 à 47) : au-delà de la borne ; rouge aussi sur un instantané de la tête d'avant les changements de cette session (91 PASS / 1 FAIL, même ligne). La borne ne monte pas, la sonde n'est pas affaiblie ; elle est comptée comme rouge préexistant connu. Aucune autre assertion préexistante n'a rougi dans les cinq suites.

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

## Tâche 3 (S2) — témoins de l'agent, rouges sur la base

Base : `4f9b3a6c` (branche de la phase, tâche 3 non commencée ; la suite des questions est écrite d'abord, la production n'a pas bougé). Suite jouée seule, serveur lancé comme aujourd'hui : 108 PASS / 22 FAIL. Les 22 rouges sont tous des témoins de cette tâche, plus Q11.2 (voir plus bas).

Écarts de forme, dits ici : (1) la suite porte déjà un paragraphe `Q12` (« ce qui reste » sans jalon courant) : le témoin « dossier du module refusé » du plan s'appelle donc `Q13` (Q13.1 à Q13.4). (2) Q9.1 à Q9.3 sont réécrits (le script de requête du Projet est lancé par son chemin dans le module) et non retirés ; Q9.6 est ajouté (graph.json lien vers un fichier hors du lab) en plus de Q9.4 et Q9.5 du plan. (3) `demarrer` fournit désormais `VF_COCKPIT_ENGINE_DIR` et `VF_COCKPIT_SCRIPTS_DIR` au serveur (le serveur de cette tâche tourne encore depuis la sortie et lit le dossier de scripts du module dans l'environnement) ; le reste du lancement est inchangé à cette étape.

| id | assertion (libellé court) | attendu | obtenu sur la base | rouge parce que |
|---|---|---|---|---|
| Q2.2 | l'argv du faux `claude` contient la combinaison de la mesure, `<module>` remplacé par le dossier du module calculé par la suite | `true` | `false` | la constante porte des règles relatives à la sortie |
| Q3.2 | même contrôle, onglet Code | `true` | `false` | idem |
| Q2.4 | tout `Bash(` de l'argv désigne l'un des deux scripts du module (forme exacte), aucune règle relative | `true` | `false` | règles `Bash(node .vibeflow/cockpit/...)` |
| Q2.7 | la consigne Projet nomme le script de requête du module, sans jeton ni chemin relatif | `true` | `false` | la consigne donne `node .vibeflow/cockpit/vf-cockpit-query.mjs` |
| Q3.4 | la consigne de l'onglet Code nomme `query-cli.mjs` du module, sans jeton ni chemin relatif | `true` | `false` | la consigne donne la forme amont relative |
| Q13.1, Q13.3 | dossier de module refusé (espace) ou absent : le faux `claude` n'est pas appelé | `0` | `1` | aucun refus : l'agent est lancé |
| Q13.2, Q13.4 | l'échec est en français et nomme le module | `oui` | (aucun événement d'échec) | aucun refus |
| Q9.1, Q9.2 | `vf-cockpit-query.mjs` lancé par son chemin dans le module, cwd = lab : `overview`, `status done` | `0true` | `1` | le script lit `project.html` et `query.mjs` à côté de lui et plante hors de la sortie |
| Q9.3 | commande inconnue : exit 1 ET la liste des commandes sur la sortie standard | `1 1` | `1 0` | exit 1 par plantage, pas par refus (la liste manque) |
| Q9.4 | `query-cli.mjs` du moteur du module : `overview` (clés `project`, `counts`) et `find` | `0true 1` | `1 0` | le script n'est pas autonome (cœur concaténé, `graph.json` lu à côté de lui) |
| Q9.5 | `graph.json` qui ressemble à du code : lu comme donnée (exit 1, clé `error`, aucun fichier PWNED) | `1 true 0` | `1  0` | plantage sans JSON d'erreur |
| Q9.6 | `graph.json` lien vers un fichier hors du lab : refusé, contenu jamais rendu | `1 true 0` | `1  0` | idem |
| Q11.5 | `argsAgent(dossier du module)` : aucun jeton, deux règles Bash au chemin attendu | `ok` | `regle:Bash(node .vibeflow/cockpit/query.mjs:*)\|Bash(node .vibeflow/cockpit/vf-cockpit-query.mjs:*)` | règles relatives, `dossierModule` ignoré |
| Q11.6 | un dossier admis puis dix refus (relatif, espace, parenthèses, virgule, égal, deux-points, étoile, jeton, vide, absent) | `admis` puis 10 `refus` | 11 `admis` | aucun refus de dossier |
| Q11.7.0 | ancres des mutants présentes une fois | `1\|1` | `0\|` | le code visé n'existe pas encore |
| Q11.7.1 | témoin : la copie non mutée passe Q11.5 | `ok` | `regle:…` | idem Q11.5 |
| Q11.7.2, Q11.7.3 | mutant « jeton non substitué » (verdict `jeton`), mutant « mauvais dossier » (verdict `regle:`), copie changée | `change jeton`, `change regle:` | `identique-ou-vide …` | ancre absente : rien à muter (un mutant doit pouvoir rougir pour la bonne raison, avant de prouver quoi que ce soit) |

Rouge préexistant, de cause nouvelle : `Q11.2` (constante contre mesure). Depuis le commit de la mesure du confinement (79), `mesure_de` choisit `79-MESURE-claude-p.md` (plus grand numéro de phase), dont la combinaison porte le gabarit `<module>` ; la constante de la base porte encore la forme de la phase 67. Attendu `identique`, obtenu `different` : il verdit avec la constante recopiée de la mesure (tâche 3, étape 3). Q11.1, Q11.3, Q11.4 sont verts sur la base (Q11.3 : la comparaison contre la liste amputée signale bien l'écart).

Témoins verts d'emblée de cette tâche (négatifs, ils ne peuvent rougir que par leurs mutants) : Q13 n'en a pas ; Q9.1 à Q9.3 sont rouges ; aucun vert à vide n'est ajouté.

## Tâche 3 (S2) — état final et point de reprise

Verts : `test-cockpit-questions.sh` seule, 133 PASS / 0 FAIL, OK-AGENT et OK-GABARIT joués ; mutants de la substitution (Q11.7.2, Q11.7.3) et de `query-cli.mjs` (Q9.7 graph.json évalué, Q9.8 confinement retiré) rougissent pour la bonne raison. Q9.4 s'attend finalement à `0true oui` (grep -c comptait des lignes). Rejeux séquentiels (une suite à la fois) : `demander-bornes` 36/0, `lancer-serveur` 82/0, `routes` 56/0 ; rouges attendus identiques à la base : `cycle-serveur` (AM4.7, 8a, 8b, 12a, 13, 14, 19, 20 et ancres M-VERSION-SYNC.0, M-LISTE-FIGEE.0, M-ESTNOTRE.0, M-MODULE.0, M-PREFIXE.0, M-ANCIENNE.0, M-STATUS.0), `marque-blanche` (AM4.17, AM4.18, M-NOM.0), `securite` (FB3.5 préexistant, AM4.1 à 4.4, M-TERM.0), `serveur` (AM4.5, AM4.6).
Non conclus, disque du poste plein (ENOSPC, indépendant de ce plan) : `assemblage` (AM4.15a/b et AM4.16 rouges par ENOSPC, AM4.15b était vert sur la base), `git-env` (135/0 mais une copie de mutant tronquée), `test-vibeflow-update-cockpit` (build en ENOSPC), `lancer-mode` (12 FAIL LM.Q3/Q6/Q9/Q10 et deux mutants sans effet : à rejouer seul avant de conclure), `transcript` (T24F4.1 sonde de durée 2398 ms pour 2000, charge de 70 à 140 : à rejouer seule). Non jouées : `git-e2e`, `chrome-fr`, `robustesse`.
Reprise : libérer le disque, rejouer SEULES `assemblage`, `git-env`, `test-vibeflow-update-cockpit`, `lancer-mode`, `transcript`, `git-e2e`, `chrome-fr`, `robustesse` ; juger `lancer-mode` par identifiant contre la base. Les 22 suites restantes qui nomment `serve.mjs` sans nommer un texte retiré (grep mécanique : aucun mutant ni ancre ne vise `floorplan/query.mjs`, `allowedTools`, les règles `.vibeflow/cockpit/…query.mjs`) n'ont pas été rejouées.

## Reliquat de S1 (ligne posée à la reprise de S2, 2026-11-12)

Commits `67f222bc` et `4f9b3a6c` : reliquat de la session S1, constaté non commité et repris tel quel par l'exécuteur de S2 (correctif `realUnder` avec `siEchec: true`, ancre REALUNDER.0, mutant REALUNDER.1, trace FB3.5). Mandat de reprise de S2 : manager, message du 2026-11-12 (8,2 Gio libres à 03 h 02).

## Tâches 4a et 4b (S2) — état final et point de reprise

Commits `(79-06)` : ef4da518 (noms écrits une fois, embed, rename), 893ae24b (serveur depuis le module, purge, version asynchrone, aide), 0ab30fdc (bascule minimale du lanceur), 5e0218ee (variable de module passée vide respectée), 862db8ce (suites 4b et mutants M-CONTRAT, M-CONTRAT-OUVERT, M-TERM, M-NOM, M-PURGE-LARGE, M-ORDRE), d20f2157 (cycle-serveur : M-VERSION-SYNC, M-LISTE-FIGEE ; equipe).

Partie I close : 893ae24b (OK-CODE-SERVEUR : AM4.1 à AM4.6, AM4.14 à AM4.19 verts, M-CONTRAT-OUVERT joué). Partie II : 0ab30fdc (AM4.7, AM4.9, AM4.10, AM4.11, AM4.20 verts). Statique : OK-STATIQUE-MODULE et OK-PLAFOND tenus (occurrences du nom amont 58 -> 0 ; `vf-cockpit.mjs` 292 lignes ; `vf-cockpit-module.mjs` 86).

Verts seuls : securite 100/0, assemblage 47/0, marque-blanche 36/0, serveur 76/0, lancer-post 95/0, confinement 66/0, questions 133/0, routes 56/0, demander-bornes 36/0, test d'installation (rc 0), equipe 215/0. cycle-serveur seul : 75 PASS / 9 FAIL, les neuf attendus de la tâche 5 (AM4.8a, AM4.8b, AM4.12a, AM4.13, M-ESTNOTRE.0, M-MODULE.0, M-PREFIXE.0, M-ANCIENNE.0, M-STATUS.0). Témoins AM4 verts : 1 à 7, 9 à 11, 12b, 14 à 20 ; mutants rouges pour la bonne raison : M-CONTRAT, M-CONTRAT-OUVERT (AM4.6 seul), M-TERM, M-NOM, M-PURGE-LARGE, M-ORDRE, M-VERSION-SYNC, M-LISTE-FIGEE (AM4.20 seul, AM4.7 vert).

Rejeu de la règle 9 (toutes les suites qui nomment un fichier d'où du code part : serve.mjs, terminal, build, lanceur, fr-inventaire, embed, query, rename, build du moteur ; 56 suites, une à la fois) : verts sans changement : accessibilite, amorce-navigateur, direct-coupe, flux-unique, fr-donnees, git, git-config-depot, git-details, git-env, git-tiroir, moteur-carte, path-enfants, projet-visite (2 sauts de police DejaVu, étrangers), reconnexion, reseau, responsive (un R15c.m-p3 rouge au premier jeu, vert 378/0 au rejeu seul : sonde de charge), terminal-fin, vendor, visite-retours, who. Rouges attendus, tâches 6a et 6b (mutants posés dans une copie de sortie qui n'est plus chargée, ou lecture du code dans la sortie) : chaine-xss (22), chrome-fr (F7), direct (D2.5, D2.6), git-e2e (3 mutants), lancer-bout-en-bout (2), lancer-chat (28), lancer-mode (53), lancer-processus (43), lancer-serveur (48), lancer-xss (47), onglet-code (22), robustesse (S1.1, S1.2, S1.2b), terminal-activation (6), terminal-client (30), terminal-lanceur (10), terminal-page (15), terminal-pty (9), terminal-serveur (22), terminal-session (17), terminal-tiroir (46), terminal-xss (5), terminal-xterm (25), transcript (T25.15). Suites rouges NON listées au plan (hors `files_modified` ; déclarées par l'amendement daté du 2026-11-12 du plan, constat de la porte 4c, et non par un amendement antérieur) : equipe (corrigée, verte), git-signature (M-POLL, M-LOG : `build_serve` lance désormais le serveur du module qui a assemblé ; verte 47/0 après correction), git-entete (H5.1b : rouge PRÉEXISTANT, identique sur un instantané de b8ed6c55 avant ces changements, 135 PASS / 1 FAIL ; signalé, non corrigé). Aucun mutant ni ancre ne vise `empreinteCode`, `selfHash`, `lireGraphe`, `renommerHtml` ou les écritures retirées du moteur (grep : 0 suite).

Écarts : voir l'amendement daté du plan (confinement sans aide, D4.2 par /api/health, A1 réduit aux données, AM4.18 compte l'injection, AM7.S11 et S12, variable vide respectée).

Reprise (S3) : tâche 4c (point d'arrêt), puis tâche 5 (AM4.8, AM4.12, AM4.13, `vf-cockpit-serveur-vivant.mjs`), 6a, 6b.

## Point d'arrêt S2 (tâche 4c)

Tête : `6464aeb5`. Mesures du 2026-11-12 sur un instantané de `6464aeb5` (`git archive 6464aeb5 | tar -x`, dossier neuf, sans `.git`), `TMPDIR` et `CLAUDE_CODE_TMPDIR` sur le dossier du nœud, 37 Gio libres avant chaque rejeu, aucun rejeu sous manque de place.

### (a) Commits `(79-06)` de S2

Base de S2 : `49640c69`. Relevés par `git log --grep='(79-06)' 49640c69..6464aeb5` : `67f222bc` et `4f9b3a6c` (reliquat de S1, repris tel quel), `f9feb0d3`, `a6171da9`, `d06b432a` (tâche 3), `0fb64c60` (trace), `ef4da518`, `893ae24b`, `0ab30fdc`, `5e0218ee`, `862db8ce`, `d20f2157`, `a71a36be`, `6464aeb5`. Les neuf du mandat sont tous présents ; les cinq autres sont la tâche 3 et le reliquat. Le code de production n'a pas changé après `5e0218ee` (les quatre suivants sont des tests ou de la trace).

### (b) Contrôles du plan, commandes littérales (extraites du plan, lignes 362, 364, 408, 410, 412, 448), jouées sur l'instantané

| contrôle | exit code mesuré | sortie utile |
|---|---|---|
| OK-AGENT | 0 | `OK-AGENT` (questions 133 PASS / 0 FAIL, 0 saut) |
| OK-GABARIT | 0 | `OK-GABARIT` |
| OK-CODE-SERVEUR et OK-CODE-LANCEUR (une seule commande) | 0 | `OK-CODE-SERVEUR` puis `OK-CODE-LANCEUR` |
| OK-STATIQUE-MODULE | 0 | `OK-STATIQUE-MODULE` |
| OK-PLAFOND | 0 | `check-file-size : seuils warn ≥ 250, block ≥ 300 ; ✓ OK (0 avertissement)` puis `OK-PLAFOND` |
| OK-SUITES-4B | 0 | `OK-SUITES-4B` (aucune suite en rouge ni en saut) |

Comptes mesurés (une suite à la fois) : securite 100/0, assemblage 47/0, marque-blanche 36/0, serveur 76/0, lancer-post 95/0, confinement 66/0, questions 133/0, routes 56/0, demander-bornes 36/0, test d'installation sortie 0. cycle-serveur : 75 PASS / 9 FAIL ; les neuf rouges mesurés sont AM4.8a, AM4.8b, AM4.12a, AM4.13, M-ESTNOTRE.0, M-MODULE.0, M-PREFIXE.0, M-ANCIENNE.0, M-STATUS.0 (exactement la liste de la tâche 5, aucun autre).

Autres contrôles `OK-*` du plan non rejoués par S2 : « rejoué par dossier4c sur 6464aeb5, tous à exit 0 (rapport du manager, 2026-11-12) ; non rejoué par S2 ».

### (c) Fichiers hors `files_modified`

`git log --format= --name-only --grep='(79-06)' 49640c69..6464aeb5`, comparé par `comm -13` au frontmatter (55 chemins ; 33 touchés) : trois chemins hors liste. `plugin/cockpit/scripts/tests/test-cockpit-equipe.sh` (d20f2157) et `plugin/cockpit/scripts/tests/test-cockpit-git-signature.sh` (a71a36be) : déclarés par l'amendement daté du 2026-11-12 du plan (constat de la porte 4c). `79-06-PLAN.md` : le plan lui-même, modifié par ses amendements datés (d06b432a, 67f222bc, a71a36be). Aucun fichier de production hors liste. (`git diff --name-only 49640c69 6464aeb5` montre en plus des fichiers de 79-05 et 79-07 présents sur la même branche, que S2 n'a pas écrits.)

### (d) Règle 9

Fichiers sources d'où du code est parti ou a été changé par S2 (16 fichiers de production touchés ; `vf-cockpit-module.mjs` est neuf, donc 15 sources) : `vf-cockpit-agent.mjs`, `vf-cockpit-ask.mjs`, `vf-cockpit-build.mjs`, `vf-cockpit-embed.mjs`, `vf-cockpit-fr-inventaire.mjs`, `vf-cockpit-lancer-post.mjs`, `vf-cockpit-query.mjs`, `vf-cockpit-rename.mjs`, `vf-cockpit-server.mjs`, `vf-cockpit-terminal.mjs`, `vf-cockpit.mjs`, `graph-query.js`, `query-cli.mjs`, `serve.mjs`, `build.mjs` du moteur. `grep -rlF <nom de base>` sur `plugin` et `scripts` (suites `test-*.sh` et aides) : 57 suites distinctes (le nom de base `build.mjs` est aussi contenu dans `vf-cockpit-build.mjs` : la liste est par excès). Verdict par suite :

- Mesurées par S2 au point d'arrêt, tête `6464aeb5` : les dix suites et le test d'installation du contrôle OK-SUITES-4B (comptes ci-dessus, lancer-post compris 95/0), plus cycle-serveur 75/9.
- Mesurées par S2 au rejeu interrompu (même instantané, une suite à la fois, 13 suites sur 46 avant l'arrêt demandé par le manager) : accessibilite 35/0 ; amorce-navigateur 52/0 ; direct-coupe 21/0 ; flux-unique 7/0 ; fr-donnees 31/0 ; git-config-depot 126/0 ; git-details 136/0 ; chaine-xss 12/22 (rouge attendu des tâches 6a/6b, comme la trace de S2) ; chrome-fr 96/1 (F7, attendu) ; direct 74/2 (D2.5, D2.6, attendus) ; git-e2e 32/3 (M-SIGNAL, M-ECOUTEUR, M-OUVREUR, attendus) ; git-entete 135/1 (H5.1b, rouge préexistant déjà consigné) ; equipe 211/4 : voir ci-dessous.
- equipe, rouge à l'instantané : EA2.11, EA2.16, EA3.5, EA3.9, tous libellés « témoin rouge : le code d'avant (<sha>) … ». Ils ont besoin de l'historique git (un instantané `git archive` n'en porte pas) ; la suite avait donné 215 PASS / 0 FAIL dans l'arbre (commit d20f2157). Cause non établie par un rejeu dans l'arbre ; le manager ou le dossier4c qui le rejoue dans l'arbre tranche. Ce n'est pas un verdict vert.
- Non rejouées par S2 (arrêt demandé) : les 33 autres suites de la liste. Leurs verdicts sont ceux de la trace de S2 (« Tâches 4a et 4b (S2) — état final ») et n'ont pas de mesure à l'instantané de la tête dans cette rubrique.
- Preuve mécanique qu'aucun mutant ni aucune ancre ne vise un texte absent du fichier source : le grep de la trace de S2 (`empreinteCode`, `selfHash`, `lireGraphe`, `renommerHtml`, écritures retirées du moteur : 0 suite) n'a pas été rejoué ici.

### (e) Identité à l'octet avec `ab8f3e64`

Zone `AUDC-B-03 bis` de `vf-cockpit.mjs` (de la ligne de commentaire `// AUDC-B-03 bis : secret d'ouverture` à la fin de `ouvrirQ`, 31 lignes) : `git show ab8f3e64:plugin/cockpit/scripts/vf-cockpit.mjs` contre le fichier de la tête, `cmp` sortie 0, 1 814 octets des deux côtés. Ligne `ouvertureLanceur` de `vf-cockpit-terminal.mjs` : `cmp` sortie 0, 200 octets des deux côtés. Écart au mandat : le total attendu de 1 905 octets n'est pas retrouvé (1 814 pour la zone, 2 014 avec la ligne) et aucun intervalle de lignes contigu de la zone ne donne 1 905 ; le chiffre vise peut-être une autre zone que celle que je retiens. L'identité à l'octet de celle-ci est établie, pas le nombre.

## Reprise après la porte 4c (2026-11-12, 07 h 41, heure lue dans le message de la session principale)

Reprise autorisée par la session principale, décision déléguée par Samuel (AskUserQuestion session principale, 2026-11-11, « Claude, sur preuves (Recommandé) »). Réponse rendue le 2026-11-12 à 07 h 41 : « reprendre S3 ». S3 (tâches 5, 6a, 6b) est confiée par le manager à un exécuteur neuf.

Contrôles cités par la session principale, recopiés tels qu'elle les rapporte :
- rubrique « Point d'arrêt S2 » lue ; 22 commits (79-06) depuis la base du segment ; fichiers hors files_modified : `79-06-PLAN.md`, `test-cockpit-equipe.sh` et `test-cockpit-git-signature.sh` (déclarés par l'amendement `4c48d523`) ;
- règle AUDC-B-03 et exception `ouvertureLanceur` de `serve.mjs` identiques à celles de `ab8f3e64` (même empreinte) ;
- rejeu indépendant sur un export de `24271323`, retiré depuis : securite 100 PASS / 0 FAIL, questions 133 / 0 ; AM4.1 à AM4.4 verts ;
- constat F1 lu à la source (`vf-cockpit.mjs`, repli sur le `serve.mjs` de la sortie) ;
- audit intermédiaire : aucun constat haut (relayé par le manager, non relu par la session principale dans le transcript de l'auditeur).

## S3, point 1 : mesure F4 (lot 3) close (2026-11-12, 07 h 47, heure lue dans le message de la session principale)

Mesure jouée par S3 (commit 85bdcad6, 11 appels haiku, un par forme) : dix compositions refusées sans effet de bord, témoin positif autorisé ; résultat dans `79-MESURE-claude-p.md`, section « Lot 3 ». Réponse de la session principale : le verdict « confinable » tient pour les compositions mesurées ; reprendre S3 par F1.

Contrôles de la session principale, recopiés tels qu'elle les rapporte : les onze relevés bruts recomptés depuis les flux ; pour les dix cas composés (point-virgule, commande hors liste en tête, tube, deux formes de substitution, redirection hors du lab et dans le lab, saut de ligne, esperluette, « ou ») : mode annoncé dontAsk, une tentative chacun avec la commande composée prévue, un refus dans le résultat final, aucun fichier créé dans le lab ni à côté, aucune ligne d'appel du script autorisé ; témoin : autorisé, aucun refus, une ligne d'appel ; aucun constat haut.

Reprise : point 2 du mandat S3 (F1 de `vf-cockpit.mjs`), puis F2, F3, réserve equipe en worktree détaché, 33 verdicts, FB3.5, tâche 5, 6a, 6b. Aucun code de S3 écrit à ce jour.

## S3 : point de reprise (contexte épuisé, 2026-11-12)

Fait : point 1 (mesure lot 3, 85bdcad6 + relecture cd319d20) ; point 2, F1 (commit d828f895 : témoins AM6.F1a-c dans `test-cockpit-assemblage.sh`, rouge sur le code d'avant : code 5 au lieu de 3, serveur lancé ; vert 50/0 après ; amendement daté au plan). Hors de ce commit, l'arbre n'a aucune modification de S3.
Reprise : point 3 (F2 : `serve.mjs` lancé directement et `VF_COCKPIT_SCRIPTS_DIR` / `VF_COCKPIT_ENGINE_DIR` ; F3 : `serve.mjs --stop` sans contrôle d'identité ; ne pas toucher la zone l.541-553 ni `ouvertureLanceur`), puis point 4 (réserve equipe en worktree détaché à la tête), point 5 (33 verdicts de la règle 9 sur ce worktree), point 6 (FB3.5, trois sous-points), puis tâche 5, 6a, 6b, SUMMARY. Exports de session : TMPDIR et CLAUDE_CODE_TMPDIR sous SP/x06s3/tmp (à purger à la fin du nœud). Rappel : `vf-cockpit.mjs` se lance par `open --lab <dossier> --no-open` (un argument nu rend 64).
