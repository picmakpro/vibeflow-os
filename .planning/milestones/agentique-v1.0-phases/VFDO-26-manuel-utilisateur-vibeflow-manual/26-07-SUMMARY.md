# 26-07 — SUMMARY (vague 7 : thème `06-reference`, complet)

**Statut** : livré, gate au vert, aucun commit (D-14 respecté). Les 3 tâches du plan sont
terminées.

## Ce qui a été produit

12 fichiers de pages (6 pages × 2 langues) sous `manual/{fr,en}/06-reference/` :

`commandes.md` · `skills.md` · `agents.md` · `couts-et-modeles.md` · `depannage.md` ·
`ou-trouver-quoi.md`

Plus : `manual/toc.yml` (thème `06-reference` ouvert, 6 entrées `pages:`) et le parcours guidé
« je cherche une commande ou une panne » / « I'm looking for a command or a troubleshooting fix »
ajouté aux deux README de langue (`manual/fr/README.md`, `manual/en/README.md`).

Total du manuel après cette vague : **38 pages × 2 langues**, 6 thèmes ouverts (le septième,
`07-sous-le-capot`, reste hors périmètre de ce plan).

Répartition des tâches :
- **Task 1** — `commandes.md` et `skills.md`, FR+EN, écrites intégralement depuis les décomptes
  disque (D-11).
- **Task 2** — `agents.md` (table de recherche des 31 agents) et `couts-et-modeles.md` (M-11),
  FR+EN.
- **Task 3** — `depannage.md` (M-7, six pannes post-installation) et `ou-trouver-quoi.md`, FR+EN,
  plus le parcours guidé dans les deux README.

## Les trois décomptes établis depuis le disque (D-11)

Chaque décompte a été produit en énumérant le disque au moment de la rédaction (2026-08-01),
jamais recopié d'une documentation existante — conformément à l'invariant non négociable de ce
plan.

**Commandes — `plugin/commands/*.md`** : **6 fichiers**, aucun ailleurs dans le dépôt.
`/vibeflow`, `/vf-new-lab`, `/vf-planning`, `/vf-calibrate`, `/vf-audit`, `/vf-update`. Vérifié par
`ls plugin/commands/*.md`.

**Skills livrés — tous les `SKILL.md` hors `plugin/reference/content/**/templates/skills/`** :
**20 fichiers**, sur 15 modules. Vérifié par
`find plugin -iname 'SKILL.md' | grep -v reference/content`. Répartition : conductor (3 :
`vf-new-lab`, `vf-calibrate`, `vf-update`), dev-orchestrator (2 : `vf-dev`, `vf-auto`),
design-orchestrator (2 : `vf-design`, `vf-sketch`), skill-creator (2 : `skill-creator`,
`skill-creator-workflow`), et 11 modules à un seul skill (`installer`, `business-pilot-bundle`,
`content-bundle`, `growth-bundle`, `audit-architecture`, `consolidator`, `infrastructure-audit`,
`kpi-analyst`, `mobile-test`, `planning-core`, `software-architecture`). Les 4 modèles de skills
sous `plugin/reference/content/methodology/templates/skills/` (`agent-density-auditor`,
`safe-execute`, `debugger`, `metier-orchestration`) ont été **explicitement exclus** — ce sont des
gabarits pour fabriquer de nouveaux skills, pas des skills livrés.

**Agents — `plugin/*/agents/*.md` (un niveau) + `plugin/*/AGENT.md`** : **31 agents au total**
(25 + 6), confirmant le décompte déjà établi en 26-06. Répartition par modèle, recomptée
indépendamment pour `couts-et-modeles.md` : **10 en opus** (les 5 agents « visage » invocables —
`vibeflow-conductor`, `vibeflow-dev`, `vibeflow-design`, `vibeflow-validator`, `skill-creator` —
plus les 5 managers de mission), **21 en sonnet** (les 20 workers/juges, plus l'unique agent
« visage » qui n'est pas en opus : `vibeflow-kpi-analyst`). Exception notable relevée :
`vf-test-orchestrator` est un manager de mission mais tourne en **sonnet**, pas en opus — sa
boucle test→corrige→re-test reste un périmètre borné dès le départ, contrairement aux cinq autres
managers qui arbitrent un plan de bataille multi-métier ouvert. Vérifié par
`find plugin -path '*/agents/*.md'` et `find plugin -maxdepth 2 -name 'AGENT.md'`, croisé avec le
champ `model:` du frontmatter de chaque fichier.

## Écarts constatés avec le README du dépôt (constat, non corrigés — hors périmètre)

- Le README (tableau des modules) présente `/vf-design` et `/vf-sketch` comme des **commandes** —
  ce sont des skills, aucun des deux n'a de fichier sous `plugin/commands/`. `commandes.md` et
  `skills.md` corrigent cette confusion en creux, sans jamais nommer le README comme fautif dans
  le texte du manuel lui-même (seul ce SUMMARY le fait, à titre de constat).
- Le README liste « 6 commandes + 1 skill » comme points d'entrée livrés ; le disque en porte
  **6 commandes + 20 skills**. L'inventaire de phase (`26-INVENTAIRE-MATIERE.md`, §9.b et §9.c)
  avait déjà relevé cet écart mais l'avait chiffré à 18 skills en prose (le tableau détaillé du
  même document, recompté ligne à ligne, totalise en réalité 20 — c'est ce compte de 20, établi
  indépendamment par énumération directe du disque pour ce plan, qui fait foi ici, pas le chiffre
  en prose de l'inventaire).
- Aucun écart constaté côté agents : le décompte de 31 recoupe exactement celui déjà établi et
  documenté en 26-06.
- Le README chiffre l'efficience (« Efficiency, quantified ») sans jamais dire quel type de
  travail tourne sur quel modèle ni comment un utilisateur maîtrise sa dépense — c'est exactement
  le manque M-11 que `couts-et-modeles.md` comble. Le tableau du README est repris dans cette page
  avec sa source et sa date (2026-08-01), jamais recopié comme un fait acquis.

## Points de contenu notables

- **`commandes.md`** ouvre sur le fait que les commandes ne sont pas la porte d'entrée du produit
  (VibeFlow se pilote en langage naturel) et pose la frontière avec les skills, en nommant
  explicitement — sans accuser — l'erreur de classement du README.
- **`skills.md`** regroupe les 20 skills par module d'origine et met en avant, pour chacun, les
  formulations en langage naturel qui les déclenchent plutôt que leur nom technique — c'est la
  vraie porte d'entrée. Signale que `skill-creator-workflow` est un skill de support interne, pas
  un point d'entrée qu'un utilisateur invoque lui-même.
- **`agents.md`** est une table de recherche pure (une ligne par agent : module, famille,
  modèle, rôle), délibérément distincte de `05-equipe-agents/les-agents-livres.md` qui explique le
  fonctionnement en équipe — la première ne redit jamais l'explication de la seconde, elle y
  renvoie.
- **`couts-et-modeles.md`** (M-11) explique le partage de modèle par la nature du jugement demandé
  (ouvert pour les visages/managers, borné pour les workers/juges) plutôt que par un clivage
  « juge contre exécutant » qui ne correspond pas au disque (les juges de qualité tournent tous en
  sonnet). Nomme quatre leviers concrets de maîtrise de la dépense (périmètre de la demande,
  longueur de mission, mode autonome, modules installés) et trois surprises de coût (boucle de
  correction qui ne converge pas, audit large plutôt que ciblé, conversation fragmentée). Aucun
  tarif en euros ou dollars n'apparaît nulle part dans la page.
- **`depannage.md`** (M-7) traite les six pannes nommées par l'inventaire de phase, chacune sur le
  patron symptôme/cause/geste/vérification, et ouvre explicitement sur la frontière avec
  `01-demarrer/depannage-installation.md` pour ne jamais recouvrir cette page. Aucun geste proposé
  n'est destructeur sans dire ce qu'il détruit (le cas le plus sensible, `driver-lock.sh recover`,
  précise qu'il ne détruit que l'entrée du verrou, jamais un commit ou un fichier de la mission qui
  le tenait).
- **`ou-trouver-quoi.md`** ferme le thème avec une carte des ressources en tableau (version d'un
  module, ADR, doctrine méthodologique, changelog, scripts de gate, licence, CI, `toc.yml` du
  manuel lui-même) et dit explicitement pourquoi un utilisateur n'a normalement pas à ouvrir
  `docs/` ni `.planning/` — c'est la raison d'être du manuel, écrite noir sur blanc à l'endroit où
  le lecteur pourrait être tenté d'y aller. Termine par le canal de signalement (issue GitHub sur
  `picmakpro/vibeflow-os`, sans template préformaté à la date de rédaction).

## Dérivation depuis le disque

- Les frontmatter des 6 commandes (`description`, `argument-hint`) viennent d'une lecture directe
  de `plugin/commands/*.md`, pas d'une paraphrase du README.
- Les frontmatter des 20 skills (`name`, `description`) viennent d'une lecture directe de chaque
  `SKILL.md`.
- Les frontmatter des 31 agents (`model`, `memory`, `description`) viennent d'une lecture directe
  de `plugin/*/agents/*.md` et des 6 `AGENT.md`, croisés avec `check-agents.sh` pour les champs
  obligatoires.
- Le comportement du verrou de driver (`status`, `recover`, TTL par défaut de trente minutes,
  `VF_DRIVER_TTL`) vient de la lecture directe de `plugin/conductor/scripts/driver-lock.sh`.
- Le comportement du claim de branche (signal advisory, codes de sortie) vient de la lecture
  directe de `plugin/conductor/scripts/check-branch-claim.sh` et de
  `plugin/dev-orchestrator/references/mission-contracts.md` §Isolation de branche.
- Les cinq halte conditions universelles viennent de
  `plugin/reference/content/methodology/patterns/11-halt-conditions.md`.
- Le tableau « Efficiency, quantified » vient d'une lecture directe de `README.md` (racine du
  dépôt), section correspondante, datée du 2026-08-01.
- L'existence des deux licences distinctes (`LICENSE` racine, `plugin/reference/content/LICENSE.md`)
  et le léger décalage entre `docs/reference/` et `plugin/reference/content/` (3 fichiers diffèrent
  à la date de rédaction : `README-CLIENT.md`, `VERSION.md`, `methodology/patterns/README.md`)
  viennent d'une vérification directe (`diff -rq`), pas d'une reprise de l'inventaire de phase.

## Vérification

- Les 3 `<verify><automated>` du plan rejoués littéralement après chaque tâche, puis à nouveau
  après la dernière : **tous passent**. Un aléa d'exécution a été identifié et corrigé en cours de
  route : le shell d'exécution de cette session n'honore pas `set -e` à l'intérieur d'une boucle
  `for` (une commande de test qui échoue dans une boucle ne stoppe pas le script) — les premières
  passes de vérification ont donc affiché un « OK » trompeur alors que 6 des 8 pages du thème
  étaient encore sous le plancher de 100 lignes (D-04). Détecté par une inspection directe des
  comptes de lignes après coup, puis chaque page concernée (`commandes.md`, `agents.md`,
  `couts-et-modeles.md` — pas `skills.md`, déjà conforme) a été enrichie de contenu de référence
  substantiel (pas du remplissage) jusqu'à passer la barre des 100 lignes, et toutes les
  vérifications ont été rejouées avec des contrôles de code de sortie explicites (`if [ ... ]`)
  plutôt qu'un `set -e` implicite.
- `bash manual/.tools/check-manual.sh` → **exit 0**, C0 à C6 tous ✓, **zéro avertissement** (les 6
  pages qui portaient un avertissement de fourchette 100-200 lignes en sont sorties après
  l'enrichissement ci-dessus).
- `git status --porcelain -- manual` : **resté vide de bout en bout**, vérifié après chaque édition
  de fichier, après chaque exécution de `build-nav.sh`, et une dernière fois après la dernière
  tâche — `manual/` reste exclu via `.git/info/exclude:7`, inchangé du début à la fin.
- `git status --porcelain -- plugin docs README.md README.fr.md INSTALL.md scripts .github` :
  vide — aucune des sources lues (commandes, skills, agents, `driver-lock.sh`,
  `check-branch-claim.sh`, `11-halt-conditions.md`, `README.md`, `mission-contracts.md`) n'a été
  modifiée.
- `git status --porcelain` (racine, sans filtre) : un seul fichier untracked,
  `.planning/phases/VFDO-26-manuel-utilisateur-vibeflow-manual/26-06-SUMMARY.md` — préexistant à
  cette session (produit par la vague précédente, 26-06), non créé ni modifié ici, laissé en
  l'état. Aucun autre fichier suivi par git n'a bougé.
- `.git/info/exclude` non modifié (ligne 7 toujours `manual/`).
- Branche `feat/phase-26-manuel-utilisateur` inchangée du début à la fin, aucun commit créé.
