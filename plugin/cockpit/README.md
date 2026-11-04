# cockpit — le cockpit web local du lab

> Une page locale, en lecture seule, qui dit où en est le lab : jalons, phases (à faire, en cours, à recetter, faites), plans,
> exigences, missions, et qui travaille en ce moment, en arbre. Ouverte par `/vf-cockpit`.

**Type** : skill + scripts + moteur vendorisé · **Version** : v1.2.0 · **Dépend de** : aucun module (lit le verrou de `conductor` s'il est posé)

## Ce que ça donne

Trois onglets sur une même page servie en local : **Projet** (la vie du lab, calculée depuis `.planning/`), **Équipe** (qui
travaille, en arbre) et **Code** (la carte du code). Lecture seule : le module n'écrit jamais dans `.planning/`.

## Ouvrir

```bash
node .claude/scripts/vf-cockpit.mjs [open|build|stop|status] [--lab <dossier>] [--no-open] [--port <p>] [--rebuild]
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
| 5 | serveur non démarré (journal : `.vibeflow/cockpit/.cache/serveur.log`) |

Le cockpit d'un lab écoute toujours sur le même port : un port préféré dérivé de l'empreinte de la racine du lab, dans la plage 4378 à 4477. Il ne dépend ni de l'ordre de lancement ni du nombre de labs ouverts. Si ce port est pris par un autre processus, le serveur prend le suivant (jusqu'à 20 essais), et ce choix est le même à chaque lancement tant que l'état des ports ne change pas. `--port <p>` garde la priorité.

## Les trois onglets

- **Projet** : jalons, phases, plans, exigences, missions ; badge « au travail » (sessions en direct), mise à jour en
  direct de la carte sans perdre le zoom. Chaque phase porte un état dérivé de ses plans : « à faire », « en cours »,
  « à recetter » (tous les plans faits, phase pas encore cochée au ROADMAP) ou « fait ». Les plans de correction sont comptés
  à part du total. Les missions sont rattachées à leur phase. Preuve : `test-cockpit-avancement.sh` (A1 à A12, A18).
- **Équipe** : l'arbre de l'équipe, session -> manager -> workers, avec ceux qui travaillent et ceux qui ont fini depuis
  moins de 24 h (les terminés sont repliés). Chaque agent renvoie vers son nœud de mission, ou dit pourquoi il n'est pas
  rattaché. Preuve : `test-cockpit-equipe.sh` (E19 à E23, EUI) et `test-cockpit-forme-claude.sh`.
- **Code** : carte des fichiers et des liens d'appel ; extracteur VibeFlow quand le lab porte des modules (`plugin/*/module.json`),
  architecture brute sinon. Aucun modèle n'est appelé pour l'assembler.

Les onglets sont resserrés pour que trois tiennent dans l'en-tête (`test-cockpit-responsive.sh`, R1 à R4) ; le retour aux
valeurs d'origine est repris en Phase 70 (P69-D-28).

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

- Le format interne de Claude Code (session « au travail ») est surveillé : s'il change, l'état passe à `forme-inconnue` au
  lieu de mentir.
- La surveillance récursive de fichiers est mesurée sur macOS et en CI Linux seulement ; Windows n'est pas mesuré.
- Fenêtre : mise en page mesurée de 1 024 à 2 560 px (`scripts/tests/test-cockpit-responsive.sh`) ; sous 1 024 px le gabarit étroit du moteur s'applique (mesuré à 800 et 390 px : en-tête sans superposition, barre de question entière).
- Serveur arrêté : la page cesse de sonder après 5 minutes et propose « Réessayer ».
