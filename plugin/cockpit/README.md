# cockpit — le cockpit web local du lab

> Une page locale, en lecture seule (sauf le terminal intégré, si on le demande), qui dit où en est le lab : jalons, phases (à faire, en cours, à recetter, faites), plans,
> exigences, missions, et qui travaille en ce moment, en arbre. Ouverte par `/vf-cockpit`.

**Type** : skill + scripts + moteur vendorisé · **Version** : v1.3.4 · **Dépend de** : aucun module (lit le verrou de `conductor` s'il est posé)

## Ce que ça donne

Trois onglets sur une même page servie en local : **Projet** (la vie du lab, calculée depuis `.planning/`), **Équipe** (qui
travaille, en arbre) et **Code** (la carte du code). Lecture seule : le module n'écrit jamais dans `.planning/`. Exception à « en lecture seule » : quand il est lancé avec `--terminal`, le cockpit ouvre aussi un **shell de votre compte** dans un tiroir en bas des pages Projet et Code (voir « Terminal intégré »). Ce shell écrit où vous le décidez ; le cockpit lui-même reste sans écriture dans `.planning/`.

## Ouvrir

```bash
node .claude/scripts/vf-cockpit.mjs [open|build|stop|status] [--lab <dossier>] [--no-open] [--port <p>] [--rebuild] [--terminal]
```

Le verbe `/vf-cockpit` lance ce script (poses `project` et `local`) ou `$HOME/.claude/scripts/vf-cockpit.mjs` (pose `user`).
`open` (défaut) assemble la sortie si besoin, démarre le serveur et imprime
`Cockpit : <adresse>/ (Code) · <adresse>/project.html (Projet)` (l'onglet Équipe est à `<adresse>/equipe.html`) ; un serveur vivant du même lab est réutilisé sauf
`--rebuild`. `build` assemble sans serveur, `stop` arrête, `status` dit l'adresse et le PID.

| Code | Sens |
|------|------|
| 0 | succès |
| 2 | lab sans `.planning/` |
| 3 | moteur absent (réinstaller le module) |
| 4 | assemblage en échec |
| 5 | serveur non démarré (journal : `.vibeflow/cockpit/.cache/serveur.log`), ou `server.json` désignant un processus qui n'est pas le serveur de ce cockpit (voir « Limites connues », B1-1) |

Le cockpit d'un lab écoute toujours sur le même port : un port préféré dérivé de l'empreinte de la racine du lab, dans la plage 4378 à 4477. Il ne dépend ni de l'ordre de lancement ni du nombre de labs ouverts. Si ce port est pris par un autre processus, le serveur prend le suivant (jusqu'à 20 essais), et ce choix est le même à chaque lancement tant que l'état des ports ne change pas. `--port <p>` garde la priorité.

### Terminal intégré (`--terminal`)

Sans `--terminal`, rien de ce qui suit n'existe : aucun second écouteur, aucune route, aucun tiroir, la politique de contenu de la page est celle de la v1.0.x. Avec `--terminal` (macOS et Linux, `python3` requis), le lanceur ouvre le cockpit dans le même onglet et la page Projet porte une pastille « Terminal » en bas à gauche ; un clic ou **Ctrl+Maj+Espace** ouvre un tiroir qui s'étend au bas des pages Projet et Code (hauteur réglable à la souris et au clavier, mémorisée). Le shell est `$SHELL -l`, lancé dans la racine du lab (on y `cd` librement), avec l'environnement du serveur sauf `CLAUDECODE`, `CLAUDE_CODE_*`, `VF_COCKPIT_*` et les valeurs de jeton du cockpit, et avec le `PATH` **d'origine** du lanceur (P71-D-03) : le serveur et ses enfants tournent avec un `PATH` assaini (voir « Binaires du système »), le lanceur transmet l'original dans `VF_COCKPIT_PATH_ORIGINE`, que le filtre du shell restitue en `PATH` puis retire. Limite : un serveur lancé hors du lanceur (par exemple directement par `node serve.mjs`) ne reçoit pas cette variable, et le shell hérite alors du `PATH` assaini ; `TERM=xterm-256color` et `COLORTERM=truecolor` sont posés toujours (P71-D-23). `claude` y tourne normalement, avec le `CLAUDE.md` du dépôt et ses skills ; les commandes VibeFlow aussi. Il n'y a qu'une session par serveur (une seconde est refusée) ; elle survit 30 s à un rechargement de la page, avec un tampon de reprise de 256 Kio gardé en mémoire seulement ; passé le délai, ou à l'arrêt du serveur, toute la session du terminal reçoit SIGHUP puis, après 3 s de grâce, SIGKILL : les travaux lancés avec `&`, `nohup` ou `disown` sont arrêtés avec le shell (P71-D-28). Le serveur du terminal (Q) tourne dans un processus enfant dédié du serveur du cockpit (P71-D-33) : un travail synchrone du serveur (par exemple le calcul de qui travaille sur le lab) ne retarde plus ni les frappes ni la sortie du terminal. Si le serveur du cockpit meurt, même brutalement, l'enfant, l'assistant et le shell s'arrêtent avec lui. À l'arrêt volontaire du cockpit, la page affiche « Serveur arrêté » tout de suite : le serveur du terminal répond encore `arret` à `GET /etat` pendant environ 2,5 s avant de sortir ; une coupure inattendue garde la reconnexion pendant 30 s (P71-D-35). Au premier chargement, le terminal attend que sa police soit prête (2,5 s au plus) avant de mesurer sa grille : le terminal peut apparaître une fraction de seconde plus tard, jamais décalé. Le nombre de lignes de la grille se calcule sur la hauteur utile du cadre, marges internes déduites : la dernière ligne ne déborde jamais. La barre de défilement du terminal n'apparaît qu'au survol ou pendant un défilement (molette, Maj+PageUp/PageDown). Avec `--terminal`, la pastille Terminal se place sous les boutons de zoom quand le tiroir est fermé (les boutons remontent au-dessus d'elle) ; tiroir ouvert, la carte s'arrête au-dessus du tiroir (« Ajuster » et le cadrage initial en tiennent compte ; ouvrir, fermer ou régler le tiroir recadre la carte, donc un zoom fait à la main est perdu à ce moment), la barre de question se range et la visite guidée se ferme. Un terminal ouvert empêche l'arrêt du serveur sur inactivité. Relancer `open --terminal` sur un cockpit déjà vivant sans terminal le redémarre avec le drapeau ; sur un cockpit déjà vivant avec terminal, il rend un nouvel amorçage au même serveur. Le lanceur attend le serveur jusqu'à 30 s et signale « démarrage lent » une fois après 5 s ; le code 5 ne vient qu'au-delà, ou si le serveur sort sans avoir écrit son état. Sans `python3` dans le `PATH`, `--terminal` le dit (« Terminal indisponible : python3 introuvable… ») et le cockpit s'ouvre sans terminal, code 0 ; si c'est le serveur qui le constate, « python3 introuvable : le terminal est indisponible. » est écrit une fois dans `serveur.log`, `GET /etat` rend `indisponible` (les autres routes 503) et la page affiche « Terminal indisponible : Python 3 est introuvable sur ce poste » avec la marche à suivre, sans boucle de reconnexion (P71-D-34). Windows : « Terminal indisponible sous Windows. » (aucun second serveur).

## Les trois onglets

- **Projet** : jalons, phases, plans, exigences, missions ; badge « au travail » (sessions en direct), mise à jour en
  direct de la carte sans perdre le zoom. Chaque phase porte un état dérivé de ses plans : « à faire », « en cours »,
  « à recetter » (tous les plans faits, phase pas encore cochée au ROADMAP) ou « fait ». Les plans de correction sont comptés
  à part du total. Les missions sont rattachées à leur phase. Preuve : `test-cockpit-avancement.sh` (A1 à A12, A18).
  **Phases menées dans un worktree** (même dépôt git) : la carte affiche l'avancement du worktree (état, décompte de plans, reste) avec la mention
  « dans worktree <nom> ». Règle de priorité : l'état le plus avancé gagne (à faire < en cours < à recetter) ; un état clos
  sur l'arbre courant reste clos, jamais rouvert par un worktree ; une clôture lue seulement dans un worktree vaut « à recetter »
  (rien n'est clos avant d'être fusionné) ; à égalité l'arbre courant garde la main. Les fichiers du worktree sont lus, jamais exécutés,
  et chaque lecture reste dans la racine réelle de son arbre (un lien symbolique sortant n'est pas suivi). La pane `vf-signal` applique la même
  règle à ses phases (`signal@1`, champ `avancement.ailleurs`). Preuve : `test-cockpit-ailleurs.sh`.
- **Équipe** : l'arbre de l'équipe, session -> manager -> workers, avec ceux qui travaillent et ceux qui ont fini depuis
  moins de 24 h (les terminés sont repliés). Chaque agent renvoie vers son nœud de mission, ou dit pourquoi il n'est pas
  rattaché. Preuve : `test-cockpit-equipe.sh` (E19 à E23, EUI) et `test-cockpit-forme-claude.sh`.
- **Code** : carte des fichiers et des liens d'appel ; extracteur VibeFlow quand le lab porte des modules (`plugin/*/module.json`),
  architecture brute sinon. Aucun modèle n'est appelé pour l'assembler.

Les onglets sont resserrés pour que trois tiennent dans l'en-tête (`test-cockpit-responsive.sh`, R1 à R4). Depuis la Phase 70,
ils reviennent aux valeurs de `DESIGN.md` (13 px, piste de 3 px) en largeur téléphone (R13.4 à 390 px) ; à 1 024 et 1 440 px ils restent
à 12 px / 2 px (écart connu : R13.4 y est rouge, arbitrage de Samuel en attente).

## Téléphone et visite

- **Téléphone (≤ 700 px)** : l'en-tête tient sur une rangée, les actions rares passent dans un menu « ⋯ » ; le zoom est une pile
  verticale à gauche, au-dessus de la barre de question ; un tap sur une carte ou sur le titre ouvre le tiroir, qu'une poignée, une croix,
  Échap ou un tap dans le vide referment. Preuve : `test-cockpit-responsive.sh` (R13 à R16 ; R17 à R20 pour l'onglet Équipe, dont le zoom
  passe en bas à gauche dès 701 px).
- **Visite « Par où commencer »** : sur Code comme sur Projet (jalon, phase, mission et « au travail » sur Projet), chaque étape vise un
  élément, le texte est entier, « Passer » est toujours là, la visite éclaire une carte sans la sélectionner. Preuve : `test-cockpit-projet.sh`
  (O5 pour Code, O6 pour Projet).

## Équipe au travail

Chaque agent actif affiche sa **dernière action**, en une phrase lisible (« lit … », « modifie … », « lance une commande »,
« lance un agent ») ; les libellés sont provisoires. Cliquer un agent ouvre son panneau : état, durée, dernière action,
nœud de mission, puis **« Lire le transcript »**. Le transcript est lu **à la demande** seulement : il est réduit à son
mandat, à ses messages et à la liste des outils employés (aucun résultat d'outil), rendu en texte brut, et rien n'en est
gardé une fois le panneau fermé. Preuve : `test-cockpit-transcript.sh` (T24 à T26, dont T26.7 sous Chrome).

## Questions et modèle

Les formes courantes de l'onglet Projet (« Où en est-on ? », « phase N ») sont répondues sur place, même au milieu d'une conversation avec l'agent (effet de bord arbitré : une relance qui dépend du fil et contient un mot de ces formes reçoit la réponse locale). Les autres passent par
`claude -p`, confiné : mode `dontAsk`, outils `Read,Grep,Glob,Bash`, Bash limité aux deux scripts de requête, lecture bornée à
`./**`, aucun réglage chargé (`--setting-sources ""` : ni hooks du lab, ni règle `allow` de l'utilisateur) et aucun serveur MCP
hors configuration explicite. Modèle : sélecteur de la page > variable `VF_COCKPIT_MODEL` > `sonnet`, parmi une liste fermée ; une valeur
hors liste est refusée. Mesures : `67-MESURE-claude-p.md` (dossier de la phase 67).

## Interface en français

Tout le chrome est traduit en page, sans toucher au viewer : le dictionnaire (`skills/cockpit-moteur/assets/ui/78-vf-fr-dict-a.js`
et `79-…`, phrases exactes, clés à `{}` pour les gabarits), les motifs et la fonction pure `window.__vfFrTraduire` (`80-vf-fr.js`).
`scripts/vf-cockpit-fr-inventaire.mjs` recalcule, de façon déterministe, les chaînes d'interface anglaises du **rendu servi** ;
`scripts/tests/test-cockpit-chrome-fr.sh` rougit sur toute chaîne ni traduite ni exclue. Les exclusions
(`scripts/vf-cockpit-fr-exclusions.json`, une raison par entrée) ne couvrent que ce qui n'est jamais affiché (invites envoyées
à l'agent, mode plan que l'assemblage ne produit jamais) ou s'écrit pareil en français ; une exclusion devenue sans objet fait
rougir le test. **À rejouer à chaque synchro amont** (`amont/SYNCHRO.md`) : relancer l'inventaire, traduire ou exclure le reste.
Les types de carte de l'onglet Code (« Library » et pairs) sont traduits aussi. `?lang=en` désactive la traduction. Limite connue : les textes de l'onglet Code produits à l'assemblage par le moteur
(messages du panneau Santé, notes de couverture) sont des données, pas du chrome : ils restent en anglais.

## Confidentialité et réseau

Écoute sur `127.0.0.1` seulement, contrôle du `Host`, jeton propre au serveur, segments cachés refusés. La dernière commande Bash
d'une session n'est jamais diffusée ni exportée ; elle se révèle à la demande, dans la ligne cliquée, réduite au programme et à son
premier argument au plus (« git push … ») ; liste blanche, sans lecture des guillemets : un mot n'est affiché que s'il ne contient que lettres ASCII, chiffres et `_ . / : @ % + , ~ -` (programme seul si le premier argument n'est pas de cette forme, commence par « - » ou contient « = » ; « … » si le programme ne l'est pas, ou si une affectation de tête n'est pas `NOM=<mot simple ou vide>`) ; un `cd <mot simple> &&` ou `;` de tête s'efface et la règle s'applique une fois à la commande qui suit, le chemin du `cd` n'est jamais affiché (« … » pour tout autre `cd`) ; limite acceptée : un secret passé en premier argument positionnel simple reste visible (`ls Secret99`, et surtout une URL ou un hôte en premier argument dont le jeton est dans le chemin ou dans l'userinfo (seul `schéma://utilisateur:mot-de-passe@` est masqué) ; ex. `curl https://api.telegram.org/bot<id>:<jeton>/getMe`, `curl https://<jeton>@hôte`, `curl user:pass@hôte`). Décision
de Samuel, AskUserQuestion session principale, 2026-11-02 ; les règles « = » et « - » prolongent cette décision. Le transcript d'un agent ne sort que par une requête authentifiée par le jeton (`GET /api/vf/transcript`), jamais dans le
flux en direct, les fichiers générés, le journal ni l'export ; la garde d'émission lit sa liste d'interdits du contrat et
refuse tout objet si le contrat est illisible (fermée par défaut) (`test-cockpit-transcript.sh` T25, `test-cockpit-serveur.sh` F4,
`test-cockpit-reseau.sh` R1.4). Aucun appel sortant, hors
l'agent qui répond aux questions. Le lab observé n'est jamais une source de code : aucun de ses scripts n'est exécuté (le mode
« modifier le plan » n'exécute que le moteur du module), aucun lien symbolique de la sortie n'est suivi, et la page porte une
Content-Security-Policy (scripts en ligne par empreintes, `connect-src 'self'`). Hypothèse assumée : une machine à un seul utilisateur
(le jeton est servi à tout processus local, `.cache/server.json` est en 0600).

**Avec `--terminal`**, ce qui circule et ce qui ne circule pas :

- Un **second serveur** écoute sur `127.0.0.1` seulement, sur un port éphémère : une autre origine que la page Projet, rendue dans un cadre du tiroir. La page Projet ajoute `frame-src` (cette origine exacte) à sa politique de contenu, et seulement avec le drapeau ; la page du terminal a sa propre politique stricte (scripts par empreintes, `connect-src 'self'`, `frame-ancestors` = les origines de la page Projet). Chaque requête au second serveur est contrôlée : `Host`, `Origin` exacte (les `GET` de même origine qui n'envoient pas `Origin` sont admis sous `Sec-Fetch-Site: same-origin` et secret valide, P71-D-24) et secret en en-tête, comparé en temps constant ; aucun shell n'est lancé avant ce contrôle. Pas de WebSocket : la sortie arrive par un flux `fetch`, l'entrée et le redimensionnement par `POST`.
- Le **jeton d'amorçage** est à usage unique : le lanceur l'écrit dans `.vibeflow/cockpit/.cache/terminal-amorce` (mode 0600, création exclusive, aucun lien suivi), l'écrit aussi dans le fragment d'une page de redirection locale (`.cache/terminal-ouvrir.html`, mode 0600, même création exclusive) dont le navigateur reçoit **le chemin**, jamais l'amorçage : il n'est dans l'argument d'aucun processus. Cette page mène à la **page Projet** (`http://127.0.0.1:<port>/project.html#t=<amorçage>`), jamais au serveur du terminal (SAF-1 ; arbitrage Samuel, AskUserQuestion session principale, 2026-11-05). La page Projet lit le fragment avant tout autre traitement, l'efface de l'adresse (`history.replaceState`), n'en retient que le format exact (64 chiffres hexadécimaux) et monte aussitôt le cadre du terminal, tiroir fermé, en lui passant l'amorçage dans le **fragment** de l'adresse du cadre (cadre navigué par programme : l'attribut `src` n'est jamais posé, l'amorçage ne figure dans aucun nœud de la page). **L'échange se fait dans le cadre** : il efface son fragment, fait lui-même `POST /amorce` (le serveur exige toujours l'`Origin` exacte du terminal, la page Projet ne peut pas l'échanger), range le secret dans son propre stockage, puis se recharge sans fragment. Le shell ne démarre qu'à l'ouverture du tiroir (le cadre attend d'avoir une taille). Une adresse du terminal ouverte seule avec un amorçage n'échange rien : « Terminal indisponible ». Le fichier d'amorçage est effacé à l'échange, la page de redirection aussi, et le serveur balaie cette page 60 s après sa création si personne ne l'a lue ; l'amorçage **expire 60 s après sa création**, côté serveur (un échange plus tardif est refusé, relancer `--terminal` en pose un neuf). Le lanceur n'ouvre jamais une adresse lue dans le lab : `server.json` n'en livre que des **ports** (entiers de 1 à 65535), l'adresse est reconstruite en `http://127.0.0.1:<port>`, et seulement si le processus de `server.json` est le serveur de cette sortie. Le jeton n'est jamais servi par HTTP, ni écrit dans `serveur.log`, `server.json`, le flux d'événements ou l'export. Le **secret de session** qui lui succède ne vit que dans le stockage de la page du terminal : jamais de cookie, jamais dans une adresse, inaccessible depuis la page Projet. Safari est pris en charge (SAF-1) : il découpe le stockage d'un cadre par origine de premier niveau, port compris, de sorte qu'un secret posé par le terminal ouvert seul n'aurait pas été lisible dans son cadre sous la page Projet (« Session expirée ») ; l'échange dans le cadre met secret et lecture dans la même partition.
- Rien du terminal (frappes, sortie, tampon de reprise) n'est écrit sur disque ni dans le journal, le flux d'événements ou l'export ; le tampon est vidé à la fin de la session. Le tiroir n'est injecté qu'à la volée, avec le drapeau : il n'est jamais dans la page écrite sur disque ni dans l'export.
- La page du terminal peut envoyer à la page Projet des messages de valeur fixe tirés d'une liste fermée (sortie du focus clavier, état de la session, terminal joignable), avec l'origine cible exacte ; jamais un octet du shell, un jeton ou un secret. Le sens inverse est fermé : **Q n'a aucun écouteur `message` propre** ; le vendor xterm.js en garde un interne (planificateur `vscodeScheduleAsyncWork`), sans contrôle d'origine mais sans donnée ni commande, et n'est pas patché (P71-D-15 reformulée, F5).
- Le terminal ne se connecte que dans son cadre de la page Projet : une fenêtre ouverte par la page Projet vers Q (popup) ou l'adresse du terminal ouverte seule affiche « Terminal indisponible », sans lire de secret, sans flux et sans lancer de shell (F4). L'assistant se lance par un `python3` résolu en chemin absolu dans un `PATH` filtré : les éléments relatifs ou vides du `PATH` sont écartés, un `python3` du lab trouvé par le répertoire courant n'est jamais exécuté ; le `PATH` du shell n'est pas filtré, c'est le `PATH` d'origine du lanceur (F3, P71-D-03 ; sauf serveur lancé hors du lanceur, voir « Terminal intégré »). Limite : un élément **absolu** du `PATH` qui se trouve dans le lab reste consulté (c'est votre `PATH`).
- Un **collage** (ou un texte glissé-déposé dans le terminal) qui contient un retour à la ligne ou un caractère de contrôle (dont Échap et Tab) n'atteint pas le shell tout de suite : un bandeau « Annuler / Coller » affiche le texte **intégral** dans une zone défilante (atteignable au clavier), avec son nombre de lignes et de caractères, et le focus est sur « Annuler ». Les caractères invisibles ou de contrôle d'affichage (dont U+202E et U+200B) y sont rendus visibles, par exemple ⟨U+202E⟩, sans être retirés : ce qui part après « Coller » est le texte collé tel quel. Au-delà de 20 000 caractères l'affichage est coupé, la coupure est dite (« N caractères non affichés ») et « Tout afficher » montre le reste. **Échap** annule, ainsi qu'un nouveau collage ; pour valider, **Tab** puis **Entrée** (ou Espace) sur « Coller », ou un clic. Il n'y a volontairement aucune touche de confirmation directe : Entrée ne valide jamais un collage par réflexe. Une ligne simple, sans retour à la ligne ni caractère de contrôle, passe sans confirmation (P71-D-26) ; une seule ligne qui porte un caractère invisible ou de contrôle d'affichage (U+202E, U+200B, caractères Tag…) demande, elle aussi, confirmation. Les suites d'au moins trois lignes vides sont repliées à l'affichage (⟨N lignes vides⟩, le texte envoyé reste l'original), et un avertissement dit quand le texte dépasse la zone visible (P71-D-30).
- **Saisie rapide et fermeture** : si le shell lit moins vite que vous ne tapez, le serveur refuse l'excédent (429, au-delà de 256 Kio en attente) ; la page garde alors vos octets et les renvoie 100 ms plus tard, sans rien perdre. Une grosse saisie (un collage de plus de 64 Kio) part en tranches de 64 Kio au plus, dans l'ordre : un corps plus grand serait refusé (413) ; si le serveur refuse tout de même, la page découpe plus petit, et à un seul octet refusé elle écrit un message dans le terminal au lieu de perdre la saisie en silence. Pendant qu'une session précédente se ferme, une nouvelle attache reçoit un 503 bref et la page affiche « Reconnexion… » avant de se rattacher : en pratique la fermeture dure la grâce de 3 s au plus (un zombie n'est pas un processus vivant) ; au pire, un assistant qui ne meurt pas reçoit SIGTERM 6 s après l'échéance de la grâce, SIGKILL 1 s plus tard, et la place est rendue 1 s après, soit 8 s au plus.
- Les **réponses de format fixe** d'xterm (DA1, DA2, DSR, CPR, DECRQM, couleurs OSC) sont réinjectées dans l'entrée du shell comme sur tout terminal ; aucun octet choisi par la sortie du shell ne l'est autrement (F8, TERM-10).
- **Binaires du système** : le lanceur est exécuté depuis la racine du lab, donc il ne lance jamais un binaire par son nom. `open`, `xdg-open`, `ps`, `git`, `bash` et `python3` sont cherchés dans les seuls éléments absolus du `PATH` (`.`, un élément vide ou relatif sont ignorés) et lancés par leur chemin absolu ; introuvable, le lanceur le dit et ne se replie jamais sur le dossier courant. Un élément absolu du `PATH` situé dans le lab reste consulté : c'est votre choix. Le `PATH` du shell du terminal est celui d'origine du lanceur, non assaini (P71-D-03).
  **Serveur et moteur (H-1, sur `main`)** : le serveur vendorisé, ses enfants et le moteur d'assemblage tournent avec un `PATH` assaini par `scripts/vf-cockpit-env.mjs` (`assainirPath`, `envEnfant`) : les éléments vides, relatifs ou situés sous le lab (lien symbolique résolu) sont retirés, avec le repli `/usr/bin:/bin:/usr/sbin:/sbin` si rien ne reste (un `PATH` vide serait lu comme le dossier courant) ; le patch amont `P25` de `serve.mjs` l'applique au processus du serveur lui-même (donc à `which`, `claude`, l'agent). Le processus du serveur du terminal (Q) est lancé avec ce même environnement assaini ; seul le shell reçoit le `PATH` d'origine, par `VF_COCKPIT_PATH_ORIGINE` (voir « Terminal intégré »).
- Le shell garde son historique comme tout terminal : c'est celui de votre compte.

## Sortie dans le lab

`<lab>/.vibeflow/cockpit/` avec son propre `.gitignore` (`*`). Aucun dossier amont, aucun `CLAUDE.local.md` dans le lab.

## Pane terminal vf-signal

Le même module a une seconde surface : une pane dans la session Claude Code, `/vf-signal`. Elle dit en un coup d'œil où en est la boucle
et ce que fait l'équipe, sans quitter le terminal. Elle observe et affiche ; ce sont les hooks VibeFlow qui décident. Elle n'écrit
jamais dans le planning et n'ouvre aucun réseau (pas de `git fetch` : l'âge du dernier fetch se lit à la date de `FETCH_HEAD`).

### Ce que montre la pane

- **L'en-tête** : l'espace de travail, le jalon de la phase active de l'arbre courant, puis un badge de retard (« en retard de N commits
  sur main, dernier fetch il y a X », avec `origin/main` local en plus s'il diffère), **une ligne par worktree** (branche, phase active
  de cet arbre et son avancement) et la mission courante avec son état. Sans phase active ou sans jalon qui la contienne, rien n'est
  affiché : jamais un repli sur `STATE.md`. Les couleurs ne servent qu'au statut (jeton `st-done`, `st-active`, `st-todo`, `st-blocked`,
  direction « Graphite » de `DESIGN.md`) ; le thème, sombre ou clair, est lu une fois au démarrage de la session.
- **Le fil** de la boucle : `cadrer`, `planifier`, `exécuter`, `vérifier`, `clore`, déduit des agents et des skills que la session lance.
- **Trois vues**, par onglet ou par les touches `1`, `2`, `3` quand la pane a le clavier :
  - `mission` : les verrous de driver, le plan de bataille de la mission de la phase active dessiné par vagues d'exécution, le nœud
    courant, les refus des gardes. Une mission dont les nœuds n'ont jamais été refermés n'est plus présentée comme en cours.
  - `équipe` : l'arbre des agents de **toutes les sessions et de tous les worktrees** (`who@2`, fenêtre de 24 h, comme l'onglet Équipe de la
    page web) ; les agents terminés sont repliés derrière un bouton « N terminé(s) ». « voir » (sa transcription) et « demander l'arrêt »
    (un message, pas un kill) ne sont offerts qu'aux agents **vivants de la session courante**, jamais aux agents d'une autre session ni
    aux orphelins du registre.
  - `macro` : le projet, le jalon de la phase active et ses phases (clé du jalon et titre court), la phase active et ses plans, les autres
    jalons. Le bloc backlog de l'ancien mod n'existe plus.
- **Toi** : la prochaine action humaine et ses boutons : élaguer un verrou périmé (`e`), copier la commande `takeover` (`t`), compacter
  (`c`), **Ouvrir le cockpit** (`o`), rafraîchir (`r`). Puis le contexte (remplissage, coût, fenêtres de rate limit).
- **Le bandeau** au-dessus du prompt, seulement quand une action t'attend (un garde a refusé un appel, un verrou est périmé, un nœud attend
  un arbitrage, le contexte dépasse 85 %, un outil est appelé trois fois à l'identique), avec « voir » et « masquer ».
- **Deux formes** : dockée (plein écran, au moins 110 colonnes) elle montre tout ; posée au-dessus du prompt (inline) ou sous 48 colonnes,
  elle se fait compacte : une ligne d'en-tête, la vue, « toi ».

Commandes : `/vf-signal` ouvre la pane ou la ramène au premier plan, `/vf-signal mission|équipe|macro` ouvre sur cette vue,
`/vf-signal brief` rend l'état complet en Markdown dans la transcription (et dit la cause quand le socle n'a pas répondu).

### Quand la pane apparaît (gating)

Elle ne s'affiche que si le module `cockpit` est installé : le mod lit le registre `scripts/.vibeflow-installed` du scope projet
(`<racine>/.claude/scripts/`) puis du scope user (`~/.claude/scripts/`) et cherche la ligne `cockpit=`. Sans elle, le mod n'enregistre ni pane, ni
bandeau, ni commande `/vf-signal`, et ses hooks laissent passer. Un registre planté dans le lab observé ne fait au pire que
déclencher cet affichage : le mod n'exécute rien qui s'y trouve.

### D'où viennent les données

Une seule source : l'émetteur du socle, `node <plugin>/cockpit/scripts/vf-cockpit-signal.mjs <racine de session>`, qui publie une ligne
de JSON au schéma `vibeflow/cockpit-signal@1` (phases avec leur `avancement@2`, jalons, missions et leur état de vie, verrous, worktrees et
retard, équipe `who@2`). Le mod ne relit pas le planning lui-même. Un appel est borné à 15 secondes et un seul tourne à la fois.

**Règle de rafraîchissement (P68-D-41, arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-04, « Rafraîchir si pane ouverte (Recommandé) »).**
Garantie du mod : le rafraîchissement est continu seulement quand la pane est ouverte et la session interactive. Pane fermée, il n'a lieu qu'après un tour
terminé et au plus une fois par minute. Le mod n'attend jamais l'émetteur au démarrage de la session.
Conséquence à connaître : pane fermée, le bandeau peut afficher un état vieux d'une minute ou plus (P68-D-41). Une horloge qui recule compte comme une minute échue.
**Environnement des lancements (P68-D-40, P68-D-42).** Le mod vide `VF_COCKPIT_SCRIPTS_DIR`, `NODE_OPTIONS`, `BASH_ENV` et `ENV` dans l'environnement
de ses lancements (émetteur, lanceur du cockpit, élagage), même quand ton shell les pointe vers le lab : rien sous le lab ne doit s'exécuter par leur biais.

**Coût mesuré** (relecture adverse de la Phase 68, `68-RELECTURE-ADVERSE.md` § S3, 2026-11-04, sonde rejouée trois fois sur ce dépôt) : environ 1,8 à 2,1 s par appel,
8 arbres git, environ 120 Ko de sortie (120 757 octets), environ 2 s de CPU par appel, sortie 0. La durée varie avec le nombre de worktrees ; elle n'est pas garantie ailleurs.
Ce chiffre remplace l'ancienne mesure du SUMMARY de 68-03 (3 s, 14 worktrees, 108 338 octets), périmée.

**`node` doit être dans le PATH** de Claude Code. Sans lui, la pane dit « node introuvable dans le PATH » et n'affiche aucune donnée
(plutôt que des données à moitié lues) ; il n'existe pas de réglage de chemin de `node`. Une sortie tronquée, illisible, d'un autre schéma
ou incomplète est dite de la même façon, avec sa cause.

**Mission vivante.** Une mission n'est « en cours » que si le verrou de driver qui la couvre est tenu et non périmé, ou si son progrès est plus récent que
le TTL (1 800 s). Le socle cherche le verrou dans l'ordre : **phase, puis compartiment, puis dépôt** (l'ancien `.planning/DRIVER.lock` compte
comme un verrou de dépôt). Un verrou **présent**, même périmé, arrête la cascade : un verrou de phase ou de compartiment périmé n'est jamais contourné par un verrou plus large tenu, et la mission est alors « abandonnée, nœuds non refermés » (grisée, avec le bouton d'élagage humain) ; elle l'est aussi quand aucun verrou n'existe à aucun cran (P68-D-27, P68-D-36). Si la
source des verrous est illisible, l'état est « inconnu », jamais « en cours » ni « abandonnée ». Cette règle vit dans le socle : la carte Projet
de la page web la partage. La date de modification d'un DAG n'est jamais regardée.

### Ouvrir le cockpit

Le bouton lance `node <lanceur> open --lab <racine>` et affiche l'adresse rendue (port stable par lab, voir plus haut) ; c'est un geste humain,
aucun agent ne l'appuie. Le lanceur est cherché dans le compte (`~/.claude/scripts/vf-cockpit.mjs`), puis dans le plugin ; `driver-lock.sh` (élagage) est cherché dans le plugin,
puis dans le compte. Deux garanties du mod : **il n'exécute jamais un fichier du compte ou du plugin dont le chemin ou le chemin réel tombe sous le lab** (la racine du plugin
n'est refusée que sous `<lab>/.vibeflow`), **et un fichier existant dont le chemin réel ne peut pas être établi est refusé** ; **ses lancements partent hors du lab, avec un PATH assaini**.
Un échec de lanceur est dit en clair (code de sortie de la table de « Ouvrir »).

**Cockpit installé sans `conductor`.** `cockpit/module.json` ne requiert aucun module. Sans `driver-lock.sh` trouvable (ni dans le plugin, ni dans le compte, ni dans un scope
accepté), la source des verrous est illisible : une mission dont un nœud est en cours s'affiche « état inconnu », et non « en cours » (P68-D-23).

### Gestes réservés aux humains

Élaguer un verrou périmé (`driver-lock.sh recover`), demander l'arrêt d'un agent, compacter, copier une commande, ouvrir le cockpit :
chacun est borné, derrière un bouton, jamais lancé par le mod seul.

### Chargement, version et CI

Le mod est déclaré au niveau du plugin (`plugin/.claude-plugin/plugin.json`, clés `hooks` et `types`), sa source est sous `signal/`. Il est lu depuis le cache du
plugin, jamais copié chez l'utilisateur. Ses clés d'état portent le nom du plugin (`vibeflow.*`). L'API des mods de Claude Code est en accès anticipé. Pane vf-signal vérifiée sous Claude Code 2.1.318 ; non chargée sous 2.1.181 (plancher exact non mesuré) (P68-D-41, arbitrage Samuel, AskUserQuestion session principale Claude Code, 2026-11-04, « L'écrire sans mesurer (Recommandé) »). La CI joue `claude plugin validate --strict plugin` et `claude plugin test plugin`
(`@anthropic-ai/claude-code` épinglé en `2.1.318`, job `gates`) ; sous `claude plugin test`, `process.run` n'atteint jamais la machine, donc la chaîne réelle
`node` + émetteur se prouve par `test-cockpit-signal.sh` et par un passage `claude -p --plugin-dir plugin "/vf-signal brief"` à la recette.

### Retirer l'ancien mod (geste humain)

Si tu avais le mod `vf-signal` posé à la main (`~/.claude/mods/vf-signal`, marketplace local `vf-mods`), il reste actif à côté du mod embarqué : **deux panes**.
Le mod embarqué le détecte et te le dit (une alerte au démarrage et une ligne dans la pane) ; **il ne le retire jamais** (arbitrage de Samuel, AskUserQuestion
session principale, 2026-11-03). À faire toi-même, après avoir vérifié que la pane embarquée te convient :

1. `claude plugin list` : repérer `vf-signal@vf-mods` et son scope (`user` pour une pose dans le compte).
2. `claude plugin uninstall vf-signal@vf-mods` (`--scope project` ou `local` si ce n'est pas le scope `user`) ; la commande exacte se relit avec `claude plugin --help` et
   `claude plugin uninstall --help` sur ta version.
3. Si `vf-mods` ne porte plus aucun autre mod : `claude plugin marketplace list` puis `claude plugin marketplace remove vf-mods`.
4. Supprimer le dossier source `~/.claude/mods/vf-signal` (une fois le plugin désinstallé), puis relancer la session.

## Inventaire du module

`scripts/` (le socle : lecture du planning, `vf-cockpit-vie.mjs`, `vf-cockpit-arbres.mjs`, l'émetteur `vf-cockpit-signal.mjs`, le lanceur), `signal/` (le mod : `hooks/`,
`tests/`, `types/`, jouée par `claude plugin test`) et `skills/` (le moteur d'affichage). Suites neuves de la Phase 68 : `test-cockpit-vie.sh` (règle de mission
vivante), `test-cockpit-retard.sh` (retard et worktrees), `test-cockpit-signal.sh` (l'émetteur) et `test-cockpit-signal-mod.sh` (déclaration, import et
gardes statiques du mod).

## Interface du socle pour `vf-signal`

Schémas lisibles dans `scripts/vf-cockpit-interface.json` (copié à l'identique dans la sortie) : `avancement@2` (clé posée par
`readPlanning` sur chaque phase : décompte de plans, correctifs, état dérivé, mission rattachée ; **monté de `@1` à `@2`** pour dire l'état de vie d'une mission :
`abandonnee`, `inconnu` et le champ `vie`), `vibeflow/cockpit-signal@1` (ce que la pane lit : phases, jalons, missions, verrous, worktrees et retard, équipe),
`vibeflow/cockpit-who@2` (arbre des agents : parent, état, action, rattachement, fenêtre de 24 h ; remplace `@1`),
`vibeflow/cockpit-transcript@1` (transcript réduit) et `vibeflow/cockpit-equipe@1`. Les autres schémas restent à `@1`.

## Code tiers

Le moteur d'affichage est **floorplan v0.6.0 @ 92d6854** (`haydenschmitty/floorplan`, licence MIT), copié sous
`skills/cockpit-moteur/`. Le copyright d'origine est dans `LICENSE`, les composants tiers dans `LICENCES-TIERCES.txt`,
chaque patch, ajout et retrait dans `VENDORED.txt`. Vérifier : `bash plugin/cockpit/amont/synchro.sh verifier` ; resynchroniser :
`plugin/cockpit/amont/SYNCHRO.md`.

## Limites connues

- **Transcript** (risque accepté, P69-D-27 : arbitrage Samuel, AskUserQuestion session principale, 2026-11-03) : le masque des
  secrets est fait au mieux sur la prose des mandats et des messages ; un secret écrit en clair dans une phrase peut donc
  s'afficher dans le transcript lu. Le jeton qui autorise la lecture est lisible par tout processus local (hypothèse d'une
  machine à un seul utilisateur).
- CI, merge et PR ne sont jamais lus (aucun appel réseau) : l'état « à recetter » vient des seuls fichiers de `.planning/`.
- Les libellés de la « dernière action » sont provisoires (table fermée de verbes, à valider).
- **Limite de fond du terminal.** Le terminal, c'est votre compte, dans un dépôt potentiellement hostile : un prompt git, `direnv`, des hooks peuvent exécuter du code du dépôt dès l'ouverture. Une extension de navigateur ayant accès à `http://127.0.0.1/*` lit et pilote toute page locale. Le serveur ne peut fermer ni l'un ni l'autre.
- **Windows** : le terminal est indisponible (le reste du cockpit n'est pas mesuré sous Windows non plus).
- P71-D-15 : la page Projet peut renvoyer le cadre du terminal vers `about:blank` et le vider ; ce déni de service du cadre est accepté (le flux est alors coupé : la session suit la règle des 30 s, recharger la page dans ce délai la reprend, au-delà elle est fermée).
- O5 : après un rechargement, une application plein écran (`claude`, un éditeur) peut s'afficher fausse jusqu'à son prochain redessin ; l'historique rejoué est borné à 256 Kio, ce qui est perdu à la bascule de thème aussi (le cadre est rechargé).
- F4 : tiroir fermé, puis page rechargée après plus de 30 s : la session est fermée, car le cadre qui la tenait n'existe plus ; fermer le tiroir sans recharger ne coûte rien.
- A4 (remplace l'ancienne limite « amorçage dans les arguments de l'ouvreur », F6, P71-D-27) : l'amorçage n'est plus dans aucun argument ; il reste lisible 60 s au plus dans la page de redirection 0600 et le fichier d'amorçage 0600 (propriétaire seul), donc d'un processus du MÊME compte (hypothèse mono-utilisateur, comme M7). Sous Linux, `xdg-open` reçoit un chemin de fichier local ; cette voie n'a pas été exécutée sur un poste Linux (forme lue, ouvreur factice testé). Limite Linux : la page est ouverte par l'association de fichiers du poste, qui n'est pas maîtrisée ici : Firefox installé en snap ne lit pas les dossiers cachés (`.vibeflow/`), et un `.html` associé à un éditeur s'ouvre en texte. Le lanceur ne peut pas le savoir de l'ouvreur (il rend toujours succès) : il attend l'échange de l'amorçage, 15 s au plus, et s'il n'a pas eu lieu (ou si l'ouvreur ne se lance pas, `xdg-open` absent), il écrit « le terminal ne s'est pas ouvert » avec le chemin de la page à ouvrir à la main dans un navigateur dans la minute qui suit ; sinon relancer la commande après avoir réglé l'ouvreur pour les `.html`. Un échec du lanceur ne sort jamais avec une trace : message en une ligne et code documenté (4 pour un lien symbolique planté dans la sortie).
- A5 (P71-D-28) : à l'arrêt, tout processus encore dans la session du terminal est tué (SIGHUP, 3 s de grâce, SIGKILL), travaux `&`, `nohup` et `disown` compris. Un processus sorti de la session par `setsid`, ou par un double fork suivi de `setsid`, survit (limite écrite). Si ni `/proc` ni `ps` ne sont lisibles, l'assistant se replie sur les groupes de processus relevés au départ : plus de garantie pour `nohup`. Un relevé qui ne contient pas l'assistant lui-même (`/proc` vide d'un bac à sable) vaut « impossible » : même repli. Un zombie (état Z, lu dans `/proc/<pid>/stat` sous Linux, par `ps` ailleurs) n'est pas un membre vivant : sous Linux sans init il ne consomme pas la grâce. Avec des survivants `nohup`, l'arrêt prend la grâce de 3 s en entier.
- B1-1 : un `server.json` qui désigne un processus vivant qui n'est pas le serveur de ce cockpit (fichier planté dans le lab, ou PID réutilisé) empêche `open` et `stop` de partir, avec le code 5 et le message « PID <n> non reconnu comme le serveur de ce cockpit », tant que le fichier n'est pas supprimé : rien n'est tué ni ouvert. Marche à suivre : vérifier le processus (`ps -p <n> -o command=`) ; si ce n'est pas un `serve.mjs` de `.vibeflow/cockpit/`, supprimer `<lab>/.vibeflow/cockpit/.cache/server.json` puis relancer `open`. Si c'est bien un vieux serveur du cockpit, l'arrêter (`kill <n>`) avant de supprimer le fichier.
- A6 : « dupliquer l'onglet » peut copier l'identifiant d'onglet de la session : l'onglet dupliqué reprend alors la session au lieu d'être refusé.
- O6 : la page Projet ouverte par `localhost` (au lieu de `127.0.0.1`) désactive le tiroir, avec un message : le stockage y est cloisonné autrement ; utiliser `127.0.0.1`.
- O8 : les liens du terminal (OSC 8) ne s'ouvrent que sur clic, dans un nouvel onglet en `noopener` ; le cadre est en `sandbox="allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox"`, sans `allow-top-navigation` ni `allow`.
- F6 : la sortie du terminal n'est pas exposée au lecteur d'écran (terminal DOM sans mode lecteur), et le texte atténué du terminal reste sous 4,5:1 par nature.
- A7 : seul Chrome est mesuré par les suites ; Safari (stockage du cadre, SAF-1) a été éprouvé à la main par un harnais d'événements réels, Firefox relève de la recette humaine (raccourci Ctrl+Maj+Espace, stockage du cadre). Les suites Chrome ne reproduisent pas la partition de Safari (Chrome ignore le port : P et Q, même site, partagent leur stockage) ; elles gardent le contrat qui la rend sans objet (échange dans le cadre, jamais au premier niveau).
- SAF-1 : la page Projet voit passer l'amorçage (pas le secret) moins de 60 s : son script peut le consommer (déni de service : relancer `/vf-cockpit --terminal`) mais pas l'échanger, faute de l'`Origin` du terminal. Sous Safari, le stockage du cadre est effacé à la fermeture du navigateur : relancer `/vf-cockpit --terminal` après un redémarrage de Safari.
- Marge basse de la page Projet : la page Projet est la même vue que la carte, sans conteneur défilant ; tiroir ouvert, la carte s'arrête au-dessus du tiroir (P71-D-35) et la barre de question est rangée. Le tiroir agrandi (« plein ») ne réserve rien : il recouvre la carte, comme voulu. Mesuré sur de petits labs (2 nœuds Code, 8 Projet).
- Le format interne de Claude Code (session « au travail ») est surveillé : s'il change, l'état passe à `forme-inconnue` au
  lieu de mentir.
- La surveillance récursive de fichiers est mesurée sur macOS et en CI Linux seulement ; Windows n'est pas mesuré.
- Fenêtre : mise en page mesurée de 1 024 à 2 560 px (`scripts/tests/test-cockpit-responsive.sh`) ; sous 1 024 px le gabarit étroit du moteur s'applique (mesuré à 800 et 390 px : en-tête sans superposition, barre de question entière).
- Serveur arrêté : la page cesse de sonder après 5 minutes et propose « Réessayer ».
