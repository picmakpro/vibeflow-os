# 72-02 — trace du rouge (suite jouée sur la base, avant tout code)

Commandes : `bash plugin/cockpit/scripts/tests/test-cockpit-lancer-pty.sh pty` puis `… session` sur HEAD `b93fb088` (assistant et session de la Phase 71 intacts), shells `/bin/bash` 3.2.57 et `/bin/zsh` 5.9, `python3` 3.14.
Résultats : `pty` = `10 PASS / 34 FAIL`, `session` = `2 PASS / 13 FAIL`, `H0` vert dans les deux (aucun survivant de la suite). Le verdict `OK-ROUGE-ATTENDU` du plan est vérifié sur les deux sorties concaténées.
Le fixture de zsh a demandé une correction avant ce rouge : `ZDOTDIR` est posé dans l'environnement de ce poste (sur le dossier personnel de l'utilisateur), zsh lisait donc le `.zshrc` de l'utilisateur et non celui du `HOME` jetable ; la suite pose `ZDOTDIR` = `HOME` jetable (pilote et session). Sans cela L0.1 [zsh] était rouge pour une mauvaise raison.

## Rouges sur la base (assertion, attendu, obtenu)

- **L1.1** [bash et zsh] shell au repos
  - attendu `LANCE ok|`
  - obtenu `` (vide : l'assistant de la 71 ignore la ligne `L`, aucune ligne sur le descripteur 2)
- **L1.2** [bash et zsh] la ligne est à l'invite, le faux `claude` n'a pas tourné
  - attendu `vue absent`
  - obtenu `non absent` (l'UUID n'a jamais été tapé : la ligne n'est pas arrivée)
- **L1.3** [bash et zsh] retour chariot humain : argv exact
  - attendu `--session-id|<uuid>|-n|vf-phase-72-fiabilite|--permission-mode|acceptEdits|/vf-dev Cadre la Phase 72 du compartiment fiabilite`
  - obtenu `absent`
- **L2.1** [bash et zsh] lecteur brut au premier plan
  - attendu `LANCE premier-plan| 0 oui`
  - obtenu ` 0 oui` (le verdict `premier-plan` manque ; 0 octet reçu et lecteur vivant sont déjà vrais sur la base, d'où la conjonction exigée avec le verdict)
- **L3.1** [bash et zsh] `sleep` en mode canonique au premier plan
  - attendu `LANCE premier-plan oui`
  - obtenu ` oui` (verdict absent)
- **L4.1** [bash et zsh] le test se rejoue après la fin du programme
  - attendu `LANCE ok`
  - obtenu `` (vide)
- **L5.1** [bash et zsh] table hostile, 30 lignes
  - attendu `LANCE alphabet` trente fois puis `| absent absent`
  - obtenu ` | absent absent` (aucun verdict ; ni argv ni marqueur, ce qui est déjà vrai sur la base)
- **L5.2** [bash et zsh] table invalide, 12 lignes
  - attendu `LANCE invalide` douze fois puis `| absent absent`
  - obtenu ` | absent absent`
- **L5.3** [bash et zsh] 256 octets contre la classe évaluée par Node
  - attendu `egal 0 oui`
  - obtenu `different 0 oui`
- **L6.1** [bash et zsh] ligne de 390 caractères en deux écritures
  - attendu `LANCE ok|`
  - obtenu `` (vide)
- **L8.1** [bash et zsh] grammaire fermée du descripteur 2
  - attendu `LANCE ok|LANCE alphabet|LANCE invalide|FIN 0| 0`
  - obtenu `FIN 0| 0` (seule la ligne `FIN` existe)
- **L8.2** [bash et zsh] le shell qui imprime `LANCE ok`
  - attendu `oui LANCE ok|LANCE alphabet|LANCE invalide|FIN 0|`
  - obtenu `oui FIN 0|` (le témoin est vrai : le shell a bien imprimé `LANCE ok` sur le descripteur 1 ; aucune ligne forgée n'est passée sur le 2)
- **L9.1** shell sourd, 60 lignes de 390 caractères
  - attendu `oui 60 vivant code=0 sig=null`
  - obtenu `non(0) 0 vivant code=0 sig=null` (aucun `LANCE premier-plan`, zéro réponse ; l'assistant reste vivant et sort)
- **J1.1** à **J6.1** (onze assertions)
  - attendu par exemple `{"ok":false,"motif":"absente"}` (J1.1), `{"r":{"ok":true},"argv":"absent"}` (J2.1), `{"ok":false,"motif":"premier-plan"}` (J3.1)
  - obtenu `{"erreur":"S.lancer is not a function"}` : la méthode n'existe pas
- **M-PREMIER-PLAN, M-CTRLC-AVEUGLE, M-ALPHABET-PY, M-FIN-DE-LIGNE-PY, M-PREFIXE-PY, M-HEX-BORNE, M-ENTREE-AUTO, M-RESTE-TRONQUE, M-FILE-NON-BORNEE, M-JS-SANS-ATTENTE, M-FIFO**
  - attendu `effet`
  - obtenu `sans effet` : l'ancre du mutant est absente de l'assistant ou de la session de la base, attendu à ce stade (les onze mutants du plan sont consignés, onze lignes « mutant sans effet »)

## Verts sur la base, avec leur raison

- **L0.1** [bash et zsh] : témoin de fixture, l'invite `VFP> ` paraît et `command -v claude` rend le faux du `PATH`. C'est le témoin que la fixture démarre ; sa rougeur rendrait tous les « 0 octet » sans valeur.
- **L2.w** [bash et zsh] : témoin, un octet humain par le descripteur 0 arrive dans `lecteur.recu` (taille 1). Prouve que le lecteur reçoit des octets, donc que « 0 octet » de L2.1 est une mesure.
- **L3.w** [bash et zsh] : témoin, un Ctrl-C humain tue `dormir`. Prouve que le programme est mortel à Ctrl-C, donc que « vit encore » de L3.1 est une mesure.
- **L7.1** [bash et zsh] : `R 50 132` redimensionne déjà. L'assistant de la 71 applique les lignes `R` par `TIOCSWINSZ` ; la sonde garde le canal de taille quand la branche `L` s'ajoute (même écart que T11.2 et T13.3 de la 71).
- **J7.1** : `exit 3` dans le shell donne `etat().code` = 3. L'analyse de `FIN` existe déjà ; la sonde garde cette analyse quand la lecture de `LANCE` s'ajoute dans la même boucle. Écart avec le plan, qui annonçait J7 rouge sur la base (« méthode absente ») : le scénario de J7 ne dépend pas de la réussite de `lancer`, c'est une sonde de non-régression, pas une sonde du geste.
- **L0.0** : au moins un shell exercé. **H0** : aucun survivant.

## Mutants rouges de l'assistant

Suite `test-cockpit-lancer-pty.sh pty` sur l'assistant complété : `45 PASS / 0 FAIL`, rc=0, 69 s (L0 à L9 sous bash et zsh, dix assertions de mutants). Chaque mutant est une copie du moteur dont une ligne ancre, écrite mot pour mot par le plan, est remplacée par `sed -f` ; « mutant sans effet » (copie inchangée) serait un échec. Les valeurs ci-dessous sont l'obtenu sous le mutant, imprimé par la suite.

- **M-PREMIER-PLAN** (`    if not premier_plan_libre(maitre, pid):` -> `    if False:`) : tué par **L2.1**, obtenu `LANCE ok| 172 oui` (le lecteur brut reçoit 172 octets : Ctrl-C et la ligne), et par **L3.1**, obtenu `LANCE ok non` (le Ctrl-C tue `sleep`).
- **M-CTRLC-AVEUGLE** (ligne qui suit l'ancre précédente -> `        vers_shell += CTRL_C; return 'premier-plan'`) : tué par **L3.1**, obtenu `LANCE premier-plan non` : le verdict est le bon mais le programme est mort. C'est la preuve que la mesure est conjointe (verdict ET vivant). Il rougirait aussi L2.1 (Ctrl-C reçu par le lecteur) : la carte du plan ne le disait pas, la suite ne le rejoue que sur L3.
- **M-ALPHABET-PY** (`    if not ALPHABET_LIGNE.fullmatch(ligne):` -> `    if False:`) : tué par **L5.1**, obtenu 27 `LANCE ok` et 3 `invalide` sur 30 lignes hostiles (plus aucun refus pour l'alphabet), et `| 16 absent` : la dernière ligne tapée est exécutée par le retour chariot humain (le faux `claude` a écrit son argv, 16 octets).
- **M-FIN-DE-LIGNE-PY** (même ligne -> `    if not re.match(rb"^[A-Za-z0-9 ._:/'-]+$", ligne):`) : tué par **L5.1**, obtenu 29 `LANCE alphabet` et UN seul `LANCE invalide`, à la 26e ligne : le cas `claude --session-id 'a'` suivi d'un saut de ligne. Le `$` de Python passe la ligne devant le saut de ligne final, c'est le contrôle du préfixe (apostrophe finale) qui la refuse ensuite. Seule la ligne au saut de ligne final change : `\r` final et double saut de ligne restent `alphabet`. Écart avec le plan, qui écrit que ce cas « exécute la ligne tapée » : mesuré, il n'y a pas d'exécution (`| absent absent`), parce que le contrôle de l'apostrophe finale vient après ; la défense en profondeur tient, la sonde rougit par le verdict (`invalide` au lieu de `alphabet`).
- **M-PREFIXE-PY** (`    if not (ligne.startswith(PREFIXE_LIGNE) and ligne.endswith(b"'")):` -> `    if False:`) : tué par **L5.2**, obtenu `ok` pour trois des douze lignes (`Claude --session-id 'a'` à casse fausse, `claude --session-id 'a` sans apostrophe finale, la même avec une espace finale), `invalide` ailleurs (le préfixe faux plus court que le préfixe et `ls` sont encore refusés par le contrôle de longueur minimale, avant le test du préfixe), et `| 15 absent` (une ligne tapée a été exécutée par le retour chariot humain).
- **M-HEX-BORNE** (`    if len(hexa) > 2 * LIGNE_MAX:` -> `    if False:`) : tué par **L5.2**, obtenu `LANCE ok` pour la seule ligne de 401 octets (802 caractères hexadécimaux), onze autres `invalide`, et `| 393 absent` (la ligne tapée est exécutée par le retour chariot humain, argv de 393 octets).
- **M-ENTREE-AUTO** (`    vers_shell += CTRL_C + ligne` -> `    vers_shell += CTRL_C + ligne + bytes([13])`) : tué par **L1.2**, obtenu `vue 157` : le faux `claude` a déjà écrit son argv (157 octets) une seconde après l'envoi, sans geste humain.
- **M-RESTE-TRONQUE** (`    return tampon[-1024:]` -> `    return tampon[-256:]`) : tué par **L6.1**, obtenu `` (aucune réponse : le préfixe `L ` de la ligne fragmentée est perdu, la ligne est ignorée sans réponse).
- **M-FILE-NON-BORNEE** (`    if vers_shell:` -> `    if False:`) : tué par **L9.1**, obtenu `non(0) 60 vivant code=0 sig=null` : soixante réponses mais aucun `premier-plan` devant le shell sourd.

Verts finaux de l'assistant (le plan demande qu'aucune assertion ne soit affaiblie : aucune ne l'a été entre le rouge et le vert) : L0.1, L1.1 à L1.3, L2.1, L2.w, L3.1, L3.w, L4.1, L5.1 à L5.3, L6.1, L7.1, L8.1, L8.2 sous bash et sous zsh, L9.1 une fois ; H0.
