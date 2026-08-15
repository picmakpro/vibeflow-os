# Phase 26 Plan 03: Thème 02-concepts complet (FR+EN) Summary

**Statut : DONE.**

Livré : le thème `02-concepts` complet en français et en anglais — 7 pages × 2 langues (14
fichiers de contenu), `manual/toc.yml` enrichi (thème `02-concepts` ouvert, 7 entrées `pages:`
ajoutées, 14 entrées au total), et le parcours guidé « je veux comprendre avant d'agir » ajouté
aux deux README de langue. Aucun commit à aucun moment — `manual/` reste exclu de git de bout en
bout (D-14). Les trois manques prioritaires de CONTEXT.md ciblés par ce plan (**M-2** glossaire
produit, **M-3** définition de « lab », **M-5** VibeFlow ↔ GSD ↔ Superpowers) sont fermés.

## Fichiers livrés et nombre de lignes

| Fichier | Lignes |
|---|---:|
| `manual/fr/02-concepts/qu-est-ce-qu-un-lab.md` | 103 |
| `manual/en/02-concepts/qu-est-ce-qu-un-lab.md` | 100 |
| `manual/fr/02-concepts/modules-et-bundles.md` | 100 |
| `manual/en/02-concepts/modules-et-bundles.md` | 100 |
| `manual/fr/02-concepts/agents-skills-commandes.md` | 103 |
| `manual/en/02-concepts/agents-skills-commandes.md` | 101 |
| `manual/fr/02-concepts/vibeflow-gsd-superpowers.md` | 102 |
| `manual/en/02-concepts/vibeflow-gsd-superpowers.md` | 101 |
| `manual/fr/02-concepts/les-9-principes.md` | 101 |
| `manual/en/02-concepts/les-9-principes.md` | 100 |
| `manual/fr/02-concepts/gates-et-validation-humaine.md` | 100 |
| `manual/en/02-concepts/gates-et-validation-humaine.md` | 100 |
| `manual/fr/02-concepts/glossaire.md` | 100 |
| `manual/en/02-concepts/glossaire.md` | 103 |
| `manual/fr/README.md` (modifié — parcours « comprendre » ajouté) | 60 |
| `manual/en/README.md` (modifié — parcours « comprendre » ajouté) | 60 |
| `manual/toc.yml` (modifié — thème 02-concepts + 7 entrées) | 74 |

Les 14 pages de contenu sont toutes dans la fourchette **100-300 lignes** (D-04, plancher dur
respecté à la ligne près sur plusieurs d'entre elles après plusieurs itérations d'enrichissement) ;
aucune ne dépasse 3 titres H2 de même rang (vérifié individuellement : 3 pour
`agents-skills-commandes.md`, `gates-et-validation-humaine.md`, `modules-et-bundles.md`,
`qu-est-ce-qu-un-lab.md`, `vibeflow-gsd-superpowers.md` ; 2 pour `les-9-principes.md` — les neuf
principes eux-mêmes sont en H3 sous un unique H2 ; 0 pour `glossaire.md`, qui n'utilise que des
entrées en gras). `manual/toc.yml` porte exactement **7 entrées `- path: 02-concepts/`** (plancher
7, plafond dur 9 respecté avec large marge — le glossaire n'a pas eu besoin d'être scindé, il reste
sous 200 lignes) et **14 entrées `- path:`** au total (7 pour `01-demarrer`, 7 pour `02-concepts`).

## Verdict de `check-manual.sh`

Dernière exécution (sur `manual/` réel, sans argument), après la task 3 :

```
✓ C0 verdict non vide — 14 page(s) sur disque, 14 dans toc.yml.
✓ C1 isomorphisme fr/en — arbres identiques.
✓ C2 toc.yml <-> disque — bijection stricte vérifiée.
✓ C3 liens relatifs — aucun lien mort détecté.
✓ C4 bandeau <-> toc — bandeaux à jour.
✓ C5 zéro version en dur — aucune occurrence hors bloc de code.
✓ C6 format de page — aucune page au-delà de la bascule ferme (300 lignes / 3 H2).

✓ check-manual: tous les contrôles passent.
```

**Sortie : 0.** Zéro avertissement, zéro erreur au verdict final — toutes les pages du thème sont
tombées exactement dans la fourchette recommandée 100-200 lignes (D-04), pas seulement sous le
plafond dur de 300.

## Principe du canon signalé comme difficile à traduire en conséquence observable

**P9 — Modulariser pour la cognition** est, honnêtement, le plus indirect des neuf pour un
utilisateur final. Sa conséquence n'est pas un comportement que le lecteur déclenche ou observe
directement (contrairement à P1-Capitaliser qui se voit dans une mémoire consultable, ou P5-Vérifier
qui se voit dans des exit codes) : c'est un effet de second ordre sur la fiabilité du système
qui lui répond — des agents et des fichiers qui restent cohérents sur la durée plutôt que de
dériver, parce qu'aucune unité ne dépasse sa capacité cognitive utile. `les-9-principes.md` le dit
franchement dans les deux langues plutôt que d'inventer un bénéfice utilisateur immédiat : « Ce
principe est le plus indirect des neuf pour toi ». Aucun autre principe du canon n'a nécessité ce
traitement — les huit autres se traduisent chacun en un comportement que l'utilisateur peut
directement observer ou déclencher (voir la page pour le détail des huit).

## Confirmation git (D-14)

`git status --porcelain -- manual` a été rejoué après **chaque** tâche (task 1, task 2, task 3) et
à la toute fin de ce plan, et est sorti **vide** à chaque fois. Aucun `git add` ni `git commit`
n'a été exécuté sur un chemin sous `manual/` à aucun moment. `.git/info/exclude` n'a pas été
modifié. Aucune entrée `.gitignore` créée.

Les chemins gelés par le mandat de cette phase sont restés inchangés tout du long :

```
git status --porcelain -- plugin docs README.md README.fr.md INSTALL.md scripts .github
→ (vide)
```

En particulier, `plugin/reference/content/methodology/VIBEFLOW_PHILOSOPHY.md` et
`VIBEFLOW_EXPLAINED.md` — les deux fichiers qui portent encore les « sept principes » historiques,
nommément cités et jamais corrigés par ce plan — n'ont pas été touchés.

## Déroulé par tâche

**Task 1** — `qu-est-ce-qu-un-lab.md`, `modules-et-bundles.md`, `agents-skills-commandes.md`
(FR+EN) + ouverture du thème `02-concepts` dans `toc.yml`. Ferme **M-3** (définition matérielle et
non circulaire de « lab », avec deux exemples de nature différente : `vibeflow-os` lui-même comme
lab dev, le lab de Karim de `01-demarrer/premier-lab.md` comme lab non-dev — et un troisième
exemple, un lab de contenu avec équipe complète, pour couper court à l'ambiguïté « non-dev = solo
»). `modules-et-bundles.md` dérive le socle obligatoire des champs `mandatory`/`requires` réels de
`module.json` (vérifiés sur le disque : seul `conductor` porte `mandatory: true`, sa fermeture
transitive réelle est `planning-core`, `validator`, `skill-creator`, puis `consolidator`,
`infrastructure-audit`, `audit-architecture` via `validator`) — aucun tableau des 17 modules,
aucun numéro de version. `agents-skills-commandes.md` explique pourquoi certains agents n'ont
aucune commande d'incarnation (ADR-044, `vf-internal: true`), avec un exemple concret tiré du
disque (`vf-coder`, `quality-gate-client`) et une note honnête sur la limite réelle de ce
cloisonnement (heuristique robuste, pas une barrière technique absolue — Pattern 12).

**Task 2** — `vibeflow-gsd-superpowers.md`, `les-9-principes.md` (FR+EN). Ferme **M-5** (qui fait
quoi entre VibeFlow, GSD et Superpowers, ce que VibeFlow ajoute par-dessus, ce qui se passe sans
GSD, qui met à jour quoi — sourcé sur `INSTALL.md` §Dépendances externes, ADR-055, ADR-058, et le
comportement réel de `ensure-deps.sh`). `les-9-principes.md` documente **neuf** principes sourcés
de `VIBEFLOW_CORE.md` (P1-P9), aucun de la liste historique de sept, avec une section dédiée
expliquant pourquoi neuf et jamais sept (le canon lui-même qualifie les sept d'historiques, ligne
~308 et table de versions ~765). Vérification croisée : `git status` sur `plugin/` est resté vide
tout du long — `VIBEFLOW_PHILOSOPHY.md` et `VIBEFLOW_EXPLAINED.md` n'ont pas été modifiés. La
carte mermaid décorative de `vibeflow-gsd-superpowers.md` (4 nœuds, aucun lien, aucun emoji) est
immédiatement suivie de listes en prose qui portent l'information réelle (D-06).

**Task 3** — `gates-et-validation-humaine.md`, `glossaire.md` (FR+EN) + parcours « je veux
comprendre avant d'agir » dans les deux README. `gates-et-validation-humaine.md` énonce
explicitement l'engagement ADR-031 comme une promesse (« rien ne se corrige ni ne se supprime sans
toi »), sourcé sur les 3 axiomes d'`AXIOMES-ENFORCEMENT.md`, le pattern 11 (halt conditions, 5
codes) et le pattern 12 (cloisonnement juge/auteur), avec des exemples concrets déjà vus ailleurs
dans le manuel (migration GSD proposée jamais imposée, package tiers suspect bloqué en checkpoint
humain, lois de fer des bundles métier). `glossaire.md` définit les **16 termes** de M-2 (lab,
scope, module, bundle, socle, team-kernel, driver lock, DAG, digest de mission, halt condition,
juge frais, gate machine, rapport typé, worktree, anti-thrash, frontière ready), sourcés sur le
disque (`team-kernel.md`, `mission-flow.md`, `autonomous-guardrails.md`) plutôt qu'inventés, ouvre
par un renvoi explicite au lexique méthodologique existant pour ne pas le concurrencer, et ne lie
vers une page manuel que quand cette page existe déjà (aucun lien mort, contrôle C3 du gate passe).
Le glossaire n'a pas eu besoin d'être scindé (100-103 lignes, sous le seuil de 200 lignes du plan).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Dépassement du plafond de 3 titres H2 par page à la première écriture**
- **Found during:** Task 1, première vérification `check-manual.sh` (contrôle C6) sur
  `agents-skills-commandes.md` (5 H2) et `modules-et-bundles.md` (4 H2).
- **Issue:** Le premier jet de ces deux pages découpait le contenu logiquement en davantage de
  sections que le plafond dur D-04 ne l'autorise (`## ` compté, pas les H3).
- **Fix:** Restructuration en un H2 englobant + H3 pour les sous-sections (« Trois portes
  d'entrée : commande, skill, agent » avec 3 H3 dans `agents-skills-commandes.md` ; fusion d'une
  section « Ce que cette page ne fait pas » sous un H3 « Le scope, une notion indépendante » dans
  `modules-et-bundles.md`), sans perte de contenu.
- **Files modified:** `manual/{fr,en}/02-concepts/agents-skills-commandes.md`,
  `manual/{fr,en}/02-concepts/modules-et-bundles.md`
- **Commit:** aucun — fichiers sous `manual/`, hors git (D-14).

**2. [Rule 1 - Bug] Liens vers des pages pas encore écrites au moment de la première rédaction**
- **Found during:** Task 1 et Task 2, vérification `check-manual.sh` (contrôle C3) : les pages de
  task 1 renvoyaient en lien markdown vers `les-9-principes.md`, `gates-et-validation-humaine.md`
  et `vibeflow-gsd-superpowers.md`, pas encore écrites à ce stade (violation de l'invariant 2 —
  jamais de lien vers une page non écrite — hérité de 26-02).
- **Fix:** Remplacement des liens markdown par un renvoi en prose sans lien (« détaillé plus loin
  dans ce thème »), même pattern que celui déjà établi dans 26-02 pour `06-reference/depannage.md`.
- **Files modified:** `manual/{fr,en}/02-concepts/qu-est-ce-qu-un-lab.md`,
  `manual/{fr,en}/02-concepts/modules-et-bundles.md`,
  `manual/{fr,en}/02-concepts/agents-skills-commandes.md`
- **Commit:** aucun — fichiers sous `manual/`, hors git (D-14).

Aucune autre déviation. Les itérations successives d'enrichissement des pages (plusieurs cycles
d'ajout de paragraphes sur les 7 pages pour atteindre le plancher de 100 lignes de l'acceptance
criteria) n'étaient pas des déviations mais des itérations normales d'écriture pour respecter D-04
— chaque ajout porte une information réelle (exemple concret, nuance, mise en garde), jamais du
remplissage répétitif.

## Known Stubs

Aucun. Le glossaire ne lie que vers des pages déjà écrites ; les renvois en prose sans lien vers
des thèmes non encore écrits (`03-modules/catalogue.md`, `06-reference/`, `07-sous-le-capot`) sont
volontaires et documentés, conformes à l'invariant 2 du plan 26-02 — ce ne sont pas des stubs.

## Self-Check

- `manual/fr/02-concepts/{qu-est-ce-qu-un-lab,modules-et-bundles,agents-skills-commandes,vibeflow-gsd-superpowers,les-9-principes,gates-et-validation-humaine,glossaire}.md` : FOUND (7/7)
- `manual/en/02-concepts/{qu-est-ce-qu-un-lab,modules-et-bundles,agents-skills-commandes,vibeflow-gsd-superpowers,les-9-principes,gates-et-validation-humaine,glossaire}.md` : FOUND (7/7)
- `manual/toc.yml` contient le thème `02-concepts` et 7 entrées `pages:` sous ce thème : CONFIRMÉ
- `manual/fr/README.md` et `manual/en/README.md` portent le parcours « comprendre » : CONFIRMÉ
- `bash manual/.tools/check-manual.sh` sort en 0 : CONFIRMÉ
- `git status --porcelain -- manual` vide : CONFIRMÉ
- `git status --porcelain -- plugin docs README.md README.fr.md INSTALL.md scripts .github` vide : CONFIRMÉ

## Self-Check: PASSED
