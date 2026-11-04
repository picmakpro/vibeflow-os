# cockpit — le cockpit web local du lab

> Une page locale, en lecture seule, qui dit où en est le lab : jalons, phases (à faire, en cours, à recetter, faites), plans,
> exigences, missions, et qui travaille en ce moment, en arbre. Ouverte par `/vf-cockpit`.

**Type** : skill + scripts + moteur vendorisé · **Version** : v1.1.3 · **Dépend de** : aucun module (lit le verrou de `conductor` s'il est posé)

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

## Sortie dans le lab

`<lab>/.vibeflow/cockpit/` avec son propre `.gitignore` (`*`). Aucun dossier amont, aucun `CLAUDE.local.md` dans le lab.

## Interface du socle pour `vf-signal`

Schémas lisibles dans `scripts/vf-cockpit-interface.json` (copié à l'identique dans la sortie) : `avancement@1` (clé posée par
`readPlanning` sur chaque phase : décompte de plans, correctifs, état dérivé, missions rattachées),
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
