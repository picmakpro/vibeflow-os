# 26-08 — SUMMARY (vague 8 : thème `07-sous-le-capot`, manuel COMPLET)

**Statut** : livré, gate au vert, aucun commit (D-14 respecté). Les 3 tâches du plan sont terminées.
Cette vague ferme le manuel : les 7 thèmes de D-05 sont désormais ouverts dans les deux langues.

## Ce qui a été produit

12 fichiers de pages (6 pages × 2 langues) sous `manual/{fr,en}/07-sous-le-capot/` :

`anatomie-d-un-lab-installe.md` · `l-engine-d-install.md` · `les-gates-machine.md` ·
`la-doctrine-et-ses-patterns.md` · `decisions-d-architecture.md` · `contribuer-et-aller-plus-loin.md`

Plus : `manual/toc.yml` (thème `07-sous-le-capot` ouvert, 6 entrées `pages:` — **le sommaire est
maintenant complet, les 7 thèmes de D-05 y figurent dans l'ordre**) et le parcours guidé
« je veux voir la mécanique » / « I want to see the mechanics » ajouté aux deux README de langue
(`manual/fr/README.md`, `manual/en/README.md`), pointant vers `anatomie-d-un-lab-installe.md`.

Répartition des tâches :
- **Task 1** — `anatomie-d-un-lab-installe.md` (M-4, comblé) et `l-engine-d-install.md`, FR+EN,
  écrites depuis une lecture directe de `plugin/_internal/vibeflow-update.sh`, jamais depuis le
  tableau de désinstallation périmé d'`INSTALL.md`.
- **Task 2** — `les-gates-machine.md` (inventaire des gates réellement câblés, avec le principe du
  fail-open et l'honnêteté sur ce qui n'est pas encore machine-enforced par défaut) et
  `la-doctrine-et-ses-patterns.md` (carte de la bibliothèque méthodologique, jamais un résumé),
  FR+EN.
- **Task 3** — `decisions-d-architecture.md` (les 15 ADR à valeur utilisateur, regroupées par ce
  qu'elles changent pour l'utilisateur) et `contribuer-et-aller-plus-loin.md` (sortie du manuel),
  FR+EN, plus la clôture du sommaire dans `toc.yml` et le parcours guidé dans les deux README.

## Décompte final du manuel (COMPLET)

**44 pages × 2 langues = 88 fichiers**, 7 thèmes ouverts des deux côtés :

| Thème | Pages FR | Pages EN |
|---|---:|---:|
| `01-demarrer` | 7 | 7 |
| `02-concepts` | 7 | 7 |
| `03-modules` | 6 | 6 |
| `04-cycle-de-dev` | 6 | 6 |
| `05-equipe-agents` | 6 | 6 |
| `06-reference` | 6 | 6 |
| `07-sous-le-capot` | 6 | 6 |
| **Total** | **44** | **44** |

Vérifié par `find manual/fr -mindepth 2 -maxdepth 2 -name '*.md' | wc -l` et l'équivalent `manual/en`
— comptage direct du disque, pas repris d'un décompte antérieur.

## Discipline D-11 sur `decisions-d-architecture.md`

Les 15 ADR listées à l'inventaire §7 (029, 031, 032, 035, 044, 045, 051, 053, 054, 055, 057, 058,
059, 060, 064) ont chacune été vérifiées sur pièce dans `docs/ADR.md` avant d'en écrire la ligne —
aucune n'a été recopiée : chaque décision est résumée en une à deux lignes, avec un renvoi explicite
au registre complet (`docs/ADR.md`, lien relatif vérifié résolvant). Aucune des ADR déclarées
internes (046-050, 052, 056, 061-063) n'apparaît. Regroupement retenu, par ce que chaque décision
change concrètement pour l'utilisateur plutôt que par numéro : « Ce qui te protège » (031, 051, 054,
032), « Ce qui contraint le code et le travail de l'agent » (029, 035, 044, 045), « Ce qui régit une
mission d'équipe et l'écosystème » (053, 059, 060, 064, 055, 057, 058).

## Deux interdictions explicites du plan — respectées

1. **La gouvernance de release et les conventions de commit du `CLAUDE.md` racine du dépôt
   n'entrent jamais dans le manuel.** Vérifié par grep négatif sur les 12 pages de cette vague
   (`release discipline`, `commit convention`, `git tag`) : aucune occurrence. Le thème
   `07-sous-le-capot` documente l'engine d'installation, les gates et la doctrine — jamais la
   discipline de publication du dépôt de distribution.
2. **`la-doctrine-et-ses-patterns.md` référence uniquement `plugin/reference/content/` comme
   source canonique.** Vérifié par grep négatif (`docs/reference/`) sur les deux fichiers de
   langue : zéro occurrence dans les deux. La page mentionne le mécanisme général de copie d'un
   module doc-only vers le projet cible (déjà décrit à la page précédente du thème) sans jamais
   nommer le chemin `docs/reference/` de la copie dupliquée connue, hors périmètre.

## Points de contenu notables

- **`anatomie-d-un-lab-installe.md`** inventorie chaque artefact posé par l'installation (registre,
  skills, agents, références, config, règles, scripts, doc-only, commande d'incarnation) directement
  depuis `vibeflow-update.sh`, et couvre explicitement l'injection MCP dérivée du lab (ADR-051),
  absente jusqu'ici de toute documentation utilisateur — c'est le cœur de M-4, écrit à l'endroit
  (ce qui est posé et pourquoi) plutôt qu'à l'envers (une procédure de retrait). Renvoie par lien
  résolvant vers `01-demarrer/mettre-a-jour-et-desinstaller.md` sans le redire.
- **`l-engine-d-install.md`** formule la promesse « ce que VibeFlow n'exécute pas » à un seul endroit
  du manuel : aucun comportement automatique de démarrage de session n'existe avant que l'utilisateur
  n'ait lui-même installé le module qui le porte — nuance importante face à la formulation
  actuellement périmée d'`INSTALL.md` (« le plugin n'enregistre aucun hook »), alors que six modules
  du dépôt câblent effectivement des hooks à l'install (vérifié par lecture directe des
  `hooks/hooks.json` de `conductor`, `consolidator`, `dev-orchestrator`, `infrastructure-audit`,
  `planning-core`, `software-architecture`). La page reste fidèle au mécanisme réel plutôt qu'à la
  doc existante déjà signalée en dette par l'inventaire de phase.
- **`les-gates-machine.md`** inventorie les gates réellement câblés (conformité des agents, Iron Law
  300L, garde-fou de planning, revendication de branche, registres mémoire, fraîcheur de doctrine,
  audit d'infrastructure, recherche documentaire avant debug) avec le principe du fail-open
  (un gate cassé n'échoue jamais côté blocage). Signale explicitement que la charte des 250 lignes
  par agent (ADR-029) n'est **pas** vérifiée par un gate posé par défaut — seulement par un gabarit
  optionnel de la bibliothèque méthodologique — pour ne jamais surpromettre une garantie absente.
- **`la-doctrine-et-ses-patterns.md`** cartographie les trois strates de `plugin/reference/content/`
  (textes fondateurs, douze patterns, vocabulaire/gabarits/exemple) et pointe les deux patterns les
  plus utiles à un utilisateur (conditions d'arrêt, cloisonnement par outils) sans jamais résumer les
  dix mille lignes de la doctrine elle-même — cite et route, ne recopie pas.
- **`decisions-d-architecture.md`** ouvre en expliquant ce qu'est une ADR pour un lecteur qui n'a
  probablement jamais croisé le sigle, avant de dérouler les quinze décisions groupées par thème
  utilisateur.
- **`contribuer-et-aller-plus-loin.md`** ferme le manuel : distingue les deux publics du dépôt
  (le manuel/README pour l'utilisateur, `docs/`/`.planning/` pour les agents et contributeurs du
  dépôt), dit à qui s'adressent ces deux dossiers, donne le canal de signalement (issue GitHub, sans
  template préformaté), pointe vers `LICENSE` pour ce que source-available permet sans le résumer
  davantage, et relaie la promesse de confiance du `README` en pointant vers sa formulation déjà
  incarnée dans ce thème plutôt qu'en la recopiant mot pour mot.

## Aléa d'exécution et discipline de vérification

Conformément à la consigne de cette vague, chaque `<verify><automated>` a été rejoué avec des
contrôles de code de sortie explicites (`if [ ... ]; then echo FAIL; fi` plutôt qu'un `set -e`
implicite dans une boucle `for`) — l'aléa signalé par la vague précédente (26-07 : un `set -e` non
honoré à l'intérieur d'une boucle `for` du shell d'exécution, masquant des pages sous 100 lignes) a
donc été évité dès la première passe de cette vague, pas seulement corrigé après coup. Chaque page a
été mesurée en lignes brutes **avant** l'exécution de `build-nav.sh` (qui ajoute lui-même ~9 lignes
de bandeau lang/nav), conformément à l'ordre exact des `<verify>` du plan — plusieurs pages ont dû
être enrichies de contenu substantiel (jamais du remplissage : exemples concrets, nuances honnêtes,
paragraphes de clôture) pour dépasser la barre des 100 lignes en comptage brut, avant même l'ajout
du bandeau.

## Vérification

- Les 3 `<verify><automated>` du plan rejoués littéralement après chaque tâche, avec des `if`
  explicites sur chaque assertion (fichier présent, 100 ≤ lignes ≤ 300, ≤ 3 H2, liens requis
  présents, absence de `docs/reference/`, entrées `toc.yml`) : **tous passent**, à chaque tâche.
- `bash manual/.tools/build-nav.sh` : rejoué après chaque tâche, **exit 0** à chaque fois, arbre
  régénéré sans erreur (40 → 42 → 44 pages × 2 langues au fil des 3 tâches).
- `bash manual/.tools/check-manual.sh` sur le **manuel complet** (44 pages × 2 langues, 7 thèmes) :
  **exit 0**, C0 à C6 tous ✓, zéro avertissement de fourchette 100-200 lignes en fin de vague.
- `git status --porcelain -- manual` : **resté vide de bout en bout**, vérifié après chaque écriture
  de fichier, après chaque exécution de `build-nav.sh`, et une dernière fois après la Task 3 —
  `manual/` reste exclu via `.git/info/exclude:7` (`manual/`), ligne inchangée du début à la fin.
- `git status --porcelain -- plugin docs README.md README.fr.md INSTALL.md scripts .github` : vide
  — aucune des sources lues (`vibeflow-update.sh`, `INSTALL.md`, `docs/ADR.md`, les `hooks/hooks.json`
  de six modules, `check-agents.sh`, `guard-file-size.sh`, `AXIOMES-ENFORCEMENT.md`, l'index des
  patterns, `plugin/reference/README.md`) n'a été modifiée.
- `git status --porcelain -- .claude-plugin` : vide.
- `git status --porcelain` (racine, sans filtre) : deux fichiers untracked préexistants,
  `.planning/phases/VFDO-26-manuel-utilisateur-vibeflow-manual/26-06-SUMMARY.md` et
  `26-07-SUMMARY.md`, produits par les vagues précédentes, non créés ni modifiés ici, laissés en
  l'état. Aucun autre fichier suivi par git n'a bougé.
- `.git/info/exclude` non modifié (ligne 7 toujours `manual/`).
- Branche `feat/phase-26-manuel-utilisateur` inchangée du début à la fin, aucun commit créé.

## État de la vague 9 (hors périmètre de cette exécution)

Une vague 9 de clôture existe dans le plan de la phase mais **n'a pas été exécutée ici** — elle
appartient à un autre agent, conformément aux instructions explicites reçues pour cette mission.
