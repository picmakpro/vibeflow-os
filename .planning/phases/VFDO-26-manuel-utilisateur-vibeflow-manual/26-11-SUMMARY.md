# 26-11 — SUMMARY (décision Samuel : alignement par le haut FR ← EN, paragraphes sans équivalent)

**Statut** : livré, gate au vert (`bash manual/.tools/check-manual.sh` exit 0, C0-C6 tous ✓).
Aucun commit produit sous `manual/` (hors git par construction, `.git/info/exclude` ligne 7).
Seul ce fichier est écrit sous `.planning/`, non commité par cet agent (précédent établi par
26-08-SUMMARY et 26-10-SUMMARY : les SUMMARY de vague restent untracked jusqu'à la clôture).
`.planning/ROADMAP.md` et `.planning/STATE.md` n'ont pas été touchés — la phase reste ouverte, le
plan `26-09` reste `autonomous: false`.

## Mandat

Une revue avait établi que des pages EN du manuel portaient 1-2 paragraphes (justifications méta,
rappels de limite) sans équivalent sémantique côté FR — jamais une inexactitude, juste moins de
contenu pour le lecteur FR. Décision de Samuel : **aligner par le haut**, porter ces paragraphes
vers le FR en français natif (pas une traduction mécanique), sans rien couper côté EN.

La revue citait des chemins EN qui n'existent plus depuis la vague 26-10 (renommage des slugs EN
en anglais idiomatique, H-1 levée). L'appariement réel s'est donc fait exclusivement via `id` +
`path_fr` + `path_en` lus dans `manual/toc.yml`, jamais par ressemblance de chemin.

## Méthode

Dispatch de **7 agents en parallèle, un par thème** (le découpage naturel du manuel), chacun
chargé de : lire les deux fichiers en entier (bandeaux `vf-manual:nav`/`vf-manual:lang` ignorés),
comparer **sémantiquement** paragraphe par paragraphe (pas par volume ni nombre de lignes), écrire
les paragraphes manquants en français natif en lisant d'abord toute la page FR pour en épouser la
voix, les insérer à leur place logique dans le raisonnement (jamais en bloc final), et s'arrêter
sans diviser si une page dépassait le seuil D-4 (300 lignes / 3 H2). Aucun agent n'a touché
`manual/en/**` ni `toc.yml` ni aucun fichier hors de ses pages FR assignées.

Consigne explicite donnée à chaque agent : ne pas faire confiance à l'estimation de concentration
par thème fournie en amont, produire son propre relevé, et signaler toute divergence.

## Répartition par thème — estimation vs relevé réel

| Thème | Estimation | Relevé réel | Écart |
|---|---|---|---|
| `01-get-started` | 2/7 | **4/7** | +2 |
| `02-concepts` | 3/7 | **5/7** | +2 |
| `03-modules` | 0/6 | **3/6** | +3 |
| `04-development-cycle` | 3/6 | **4/6** | +1 |
| `05-agent-team` | 5/6 | **6/6** | +1 |
| `06-reference` | 2/6 | **3/6** | +1 |
| `07-under-the-hood` | 6/6 | **6/6** | 0 |
| **Total** | **21/44** | **31/44** | **+10** |

**Nombre réel de pages avec écart : 31 sur 44** (l'estimation de 21 était basse de 10 pages,
surtout sur `03-modules` où l'estimation annonçait une concentration nulle et où 3 pages sur 6
portaient en réalité un écart réel). Aucun thème n'a un relevé inférieur à l'estimation.

## Détail par page

### `01-demarrer` / `01-get-started` (4/7 avec écart)

- **prerequis.md** — aucun écart, vérifié intégralement.
- **installation.md** — aucun écart, vérifié intégralement.
- **choisir-son-scope.md** — porté : phrase de clôture relativisant que les trois scopes ne sont
  pas hiérarchisés, le bon choix dépendant de la façon de travailler.
- **premiere-session.md** — porté : « il n'existe pas de question de débutant qui ferait perdre du
  temps à qui que ce soit ici » ; nouveau paragraphe de clôture invitant à aller essayer.
- **premier-lab.md** — aucun écart, vérifié intégralement.
- **mettre-a-jour-et-desinstaller.md** — porté : précision « tes labs seront exactement comme tu
  les as laissés » en fin de phrase sur la réinstallation.
- **depannage-installation.md** — porté : deux phrases sur l'idempotence des commandes (« rien
  n'est dupliqué ni corrompu en l'exécutant deux fois »).

### `02-concepts` (5/7 avec écart)

- **qu-est-ce-qu-un-lab.md** — aucun écart, vérifié intégralement.
- **modules-et-bundles.md** — porté : clause de clôture « le disque a toujours raison ; un chiffre
  recopié, tôt ou tard, ne l'a plus ».
- **agents-skills-commandes.md** — aucun écart, vérifié intégralement.
- **vibeflow-gsd-superpowers.md** — porté : paragraphe de réassurance (« aucune des deux briques ne
  disparaît... VibeFlow ajoute un raccourci, il n'en retire aucun ») ; phrase de synthèse finale
  (« deux moteurs éprouvés en dessous, une seule voix au-dessus »).
- **les-9-principes.md** — porté : distinction « édition du canon vs version livrée d'un module »
  et rappel historique sur les anciennes pages « sept principes ».
- **gates-et-validation-humaine.md** — porté : phrase sur le signalement d'un arrêt flou ; paragraphe
  de bouclage glossaire (halt condition, juge frais, gate machine, rapport typé).
- **glossaire.md** — porté : complément de la phrase Ctrl+F (« pour que tu n'aies jamais à deviner
  à partir du seul contexte ») ; paragraphe final entier justifiant le choix de seize termes. Les
  seize entrées de terme elles-mêmes étaient toutes déjà présentes et équivalentes — l'écart ne
  portait que sur les paragraphes de clôture.

### `03-modules` (3/6 avec écart — estimation infirmée, elle annonçait 0/6)

- **catalogue.md** — porté : renvoi manquant vers `choisir-ses-modules.md` en fin de section
  bundles ; phrase de clôture sur la primauté du dossier module sur la page.
- **socle-et-dependances.md** — aucun écart, vérifié intégralement.
- **choisir-ses-modules.md** — porté : précision sur le retrait de module (renvoi vers
  `activer-desactiver.md`, sauvegarde prise avant toute suppression).
- **bundles-metier.md** — aucun écart, vérifié intégralement.
- **activer-desactiver.md** — porté : précision sur le piège du redémarrage de session ; précision
  sur l'auto-audit du lab ; phrase de clôture sur le diagnostic « redémarrer, auditer, essayer,
  dans cet ordre ».
- **ou-vit-un-module.md** — aucun écart, vérifié intégralement (y compris l'anecdote README périmé).

### `04-cycle-de-dev` / `04-development-cycle` (4/6 avec écart)

- **le-cycle-en-bref.md** — aucun écart, vérifié intégralement.
- **cadrer-une-idee.md** — aucun écart, vérifié intégralement (correspondance quasi ligne à ligne).
- **planifier.md** — porté : clause finale « — et la seule aussi où changer d'avis ne coûte encore
  rien ».
- **executer.md** — porté : paragraphe sur les interruptions volontaires (« s'arrêter pour réfléchir
  ne coûte rien ») ; paragraphe garantissant que rien n'est perdu en pause (commits + plan sur disque).
- **livrer-et-relire.md** — porté : paragraphe sur le dimensionnement de la relecture à l'ampleur de
  l'impact plutôt qu'au nombre de lignes (exemple règle de tarification vs 300 lignes de tests).
- **mode-autonome.md** — porté : clause finale « — et pourquoi ça vaut le coup de la relire avant
  une longue nuit de travail délégué ».

### `05-equipe-agents` / `05-agent-team` (6/6 avec écart — confirmé, thème le plus dense après 07)

- **pourquoi-une-equipe.md** — porté : deux paragraphes de clôture (réassurance sur les limites du
  mécanisme ; énoncé du compromis du thème — moins de supervision par étape, en échange de lire où
  le mécanisme admet ses limites).
- **les-agents-livres.md** — porté : justification de l'absence de numéros de version à côté d'un
  agent (le comportement, c'est le fichier disque actuel, pas une entrée de changelog) ; extension
  de la phrase de transition vers la page suivante ; nouveau paragraphe final invitant à garder
  l'inventaire sous la main.
- **une-mission-longue.md** — porté : paragraphe de clôture — aucun des trois mécanismes ne demande
  quoi que ce soit au lecteur pendant qu'une mission tourne.
- **ce-qu-on-vous-demande.md** — porté : phrase ajoutée en clôture sur la raison de nommer les
  limites honnêtes du mécanisme (savoir où il peut dériver en silence, pour relire au bon moment).
- **branches-et-worktrees.md** — porté : paragraphe de clôture — les trois règles de la page coûtent
  une seule habitude (vérifier si un dépôt tient déjà son propre arbre avant de démarrer en parallèle).
- **equipes-specialisees.md** — porté : paragraphe de clôture — même lecture pour les quatre équipes
  (ce qu'elles peuvent faire est fixé par conception, la qualité dépend de ce qu'on a dit au lab).

### `06-reference` (3/6 avec écart)

- **commandes.md** — aucun écart, vérifié intégralement (y compris les exemples par commande).
- **skills.md** — aucun écart, vérifié intégralement (vingt entrées + section provenance).
- **agents.md** — porté : phrase sur le parcours de la colonne Famille de haut en bas pour repérer
  les agents invocables directement ; précision que ni Famille ni Modèle ne sont une promesse de
  comportement au-delà du choix de modèle.
- **couts-et-modeles.md** — porté : phrase autonome renvoyant vers `agents.md` pour le détail
  agent par agent ; clause sur `grep model:` comme commande qu'un mainteneur lancerait lui-même ;
  clause finale — le chiffrage du README n'est ni un fait acquis ni une promesse pour le lab du
  lecteur.
- **depannage.md** — aucun écart, vérifié intégralement (six pannes alignées phrase pour phrase).
- **ou-trouver-quoi.md** — porté : phrase de clôture finale sur ce qui referme le thème de référence
  et le parcours guidé du manuel.

### `07-sous-le-capot` / `07-under-the-hood` (6/6 avec écart — confirmé, thème le plus dense)

- **anatomie-d-un-lab-installe.md** — porté : rappel que rien n'est deviné à l'exécution, chaque
  artefact a une cible fixe documentée dans le mapping du script ; garantie que la page ne laisse
  jamais deviner ce qui est vrai aujourd'hui vs périmé (lue directement dans le code source).
- **l-engine-d-install.md** — porté : engagement que chaque affirmation de la page est vérifiée
  contre le code source actuel, pas contre la mémoire d'un comportement passé.
- **les-gates-machine.md** — porté : la page ne prétend jamais à l'exhaustivité, renvoie toujours
  au script en cas de doute, s'engage à ne jamais devenir un résumé périmé.
- **la-doctrine-et-ses-patterns.md** — porté : bloc de deux paragraphes — cette règle n'est pas une
  précaution de façade mais toute la conception de la page ; consigne « lis la carte puis le
  territoire » ; clôture « une carte, rien de plus ».
- **decisions-d-architecture.md** — porté : complément « avec le raisonnement que cette page a
  délibérément laissé de côté » ; paragraphe final sur le fait que ce raisonnement n'a jamais à être
  maintenu à deux endroits en même temps.
- **contribuer-et-aller-plus-loin.md** — porté : nuance « même si rien n'y est confidentiel » sur le
  bullet `docs/` ; phrase sur le canal de signalement qui permet de savoir si un problème est une
  limite connue ou un vrai bug ; paragraphe de clôture final (« sept thèmes, deux langues, un seul
  sommaire, et un dépôt qui reste lisible jusqu'au bout »).

## Écarts volontairement conservés

**Aucun.** Les 7 agents ont chacun rapporté explicitement qu'aucun paragraphe EN identifié comme
manquant n'a été volontairement laissé de côté : chaque paragraphe trouvé avait un sens transposable
en français et a été porté. Aucun n'expliquait un terme propre à l'anglais, aucun ne portait une
nuance strictement anglophone.

## Seuil D-4 (300 lignes / 3 H2)

Balayage indépendant post-édition sur les 44 pages FR (`wc -l` + `grep -c '^## '`) : **aucune page
ne dépasse le seuil**. La page FR la plus longue reste `06-reference/depannage.md` à 136 lignes
(inchangée, aucun écart trouvé sur cette page). Parmi les pages modifiées, le maximum atteint est
`05-equipe-agents/branches-et-worktrees.md` à 115 lignes. Aucune division de page n'a été
nécessaire — `manual/en/**` et `manual/toc.yml` n'ont donc pas été touchés, conformément au
périmètre.

## Sortie complète de `check-manual.sh` sur le manuel réel

```
$ bash manual/.tools/build-nav.sh
✓ build-nav: 44 page(s) × 2 langues, 7 thème(s) — arbre régénéré sous /Users/samuel/Documents/dev/vibeflow-os/manual

$ bash manual/.tools/check-manual.sh
✓ C0 verdict non vide — 44 page(s) sur disque, 44 dans toc.yml.
✓ C1 isomorphisme fr/en — chaque id de toc.yml a sa paire fr+en complète sur disque.
✓ C2 toc.yml <-> disque — bijection stricte vérifiée pour les deux langues.
✓ C3 liens relatifs — aucun lien mort détecté.
✓ C4 bandeau <-> toc — bandeaux à jour.
✓ C5 zéro version en dur — aucune occurrence hors bloc de code.
✓ C6 format de page — aucune page au-delà de la bascule ferme (300 lignes / 3 H2).

✓ check-manual: tous les contrôles passent.
```

## `git status --porcelain -- manual`

```
(vide)
```

Confirmé après les 7 vagues d'édition et après la régénération des bandeaux. `.git/info/exclude`
inchangé (ligne 7 : `manual/`). Branche `feat/phase-26-manuel-utilisateur` inchangée, aucun commit
créé sous `manual/`.

Note : `git status --porcelain` à la racine (sans filtre) montre deux fichiers modifiés hors
périmètre de cette vague — `.planning/ROADMAP.md` et `.planning/missions/dag-phase26.json` —
préexistants à cette session, non touchés par ce travail (aucun `Write`/`Edit` n'a ciblé ces
chemins).

## Ce qui n'a pas bougé

- `manual/en/**` et `manual/toc.yml` : aucune page n'a franchi le seuil D-4, donc aucune division
  n'a été nécessaire — ces chemins n'ont jamais été ouverts en écriture.
- `.planning/ROADMAP.md`, `.planning/STATE.md` : non touchés, cette vague ne clôt pas la phase.
- `README.md`, `README.fr.md`, `INSTALL.md`, `.gitignore`, `.github/**`, `scripts/**`,
  `plugin/**`, `docs/**`, `CHANGELOG.md`, `VERSION`, `.claude-plugin/**` : aucun de ces chemins
  interdits en écriture n'a été touché.

## Fichiers FR modifiés (31 sur 44)

```
manual/fr/01-demarrer/choisir-son-scope.md
manual/fr/01-demarrer/premiere-session.md
manual/fr/01-demarrer/mettre-a-jour-et-desinstaller.md
manual/fr/01-demarrer/depannage-installation.md
manual/fr/02-concepts/modules-et-bundles.md
manual/fr/02-concepts/vibeflow-gsd-superpowers.md
manual/fr/02-concepts/les-9-principes.md
manual/fr/02-concepts/gates-et-validation-humaine.md
manual/fr/02-concepts/glossaire.md
manual/fr/03-modules/catalogue.md
manual/fr/03-modules/choisir-ses-modules.md
manual/fr/03-modules/activer-desactiver.md
manual/fr/04-cycle-de-dev/planifier.md
manual/fr/04-cycle-de-dev/executer.md
manual/fr/04-cycle-de-dev/livrer-et-relire.md
manual/fr/04-cycle-de-dev/mode-autonome.md
manual/fr/05-equipe-agents/pourquoi-une-equipe.md
manual/fr/05-equipe-agents/les-agents-livres.md
manual/fr/05-equipe-agents/une-mission-longue.md
manual/fr/05-equipe-agents/ce-qu-on-vous-demande.md
manual/fr/05-equipe-agents/branches-et-worktrees.md
manual/fr/05-equipe-agents/equipes-specialisees.md
manual/fr/06-reference/agents.md
manual/fr/06-reference/couts-et-modeles.md
manual/fr/06-reference/ou-trouver-quoi.md
manual/fr/07-sous-le-capot/anatomie-d-un-lab-installe.md
manual/fr/07-sous-le-capot/l-engine-d-install.md
manual/fr/07-sous-le-capot/les-gates-machine.md
manual/fr/07-sous-le-capot/la-doctrine-et-ses-patterns.md
manual/fr/07-sous-le-capot/decisions-d-architecture.md
manual/fr/07-sous-le-capot/contribuer-et-aller-plus-loin.md
```
