# 26-10 — SUMMARY (décision Samuel : slugs anglais idiomatiques sous `manual/en/`)

**Statut** : livré, gate au vert (`bash manual/.tools/check-manual.sh` exit 0, C0-C6 tous ✓).
Aucun commit produit sous `manual/` (hors git par construction). Seul ce fichier est écrit sous
`.planning/`, non commité par cet agent (le commit relève de la vague 9 de clôture, cf. précédent
établi par 26-08-SUMMARY : les SUMMARY de vague restent untracked jusqu'à la clôture).

## Mandat

H-1 (« les slugs de fichiers sont identiques en FR et EN ») a été levée par décision explicite de
Samuel le 2026-08-02 : sous `manual/en/`, dossiers ET fichiers portent désormais des slugs
anglais **idiomatiques** (traduction, pas translittération). L'outillage qui dépendait de cette
hypothèse (`toc.yml`, `build-nav.sh`, `check-manual.sh`) devait suivre. `manual/fr/**` ne bouge
pas, à l'exception du bloc de langue régénéré (seul lien qui traverse les deux arbres).

## Table de correspondance — 7 dossiers de thème

| id (toc.yml) | `dir_fr` | `dir_en` (nouveau) |
|---|---|---|
| `get-started` | `01-demarrer` | `01-get-started` |
| `concepts` | `02-concepts` | `02-concepts` (déjà anglais) |
| `modules` | `03-modules` | `03-modules` (déjà anglais) |
| `development-cycle` | `04-cycle-de-dev` | `04-development-cycle` |
| `agent-team` | `05-equipe-agents` | `05-agent-team` |
| `reference` | `06-reference` | `06-reference` (déjà anglais) |
| `under-the-hood` | `07-sous-le-capot` | `07-under-the-hood` |

## Table de correspondance — échantillon représentatif de pages (8 sur 44)

| id | `path_fr` | `path_en` (nouveau) |
|---|---|---|
| `prerequisites` | `01-demarrer/prerequis.md` | `01-get-started/prerequisites.md` |
| `installation` | `01-demarrer/installation.md` | `01-get-started/installation.md` (slug inchangé, dossier renommé) |
| `what-is-a-lab` | `02-concepts/qu-est-ce-qu-un-lab.md` | `02-concepts/what-is-a-lab.md` |
| `catalog` | `03-modules/catalogue.md` | `03-modules/catalog.md` |
| `planning` | `04-cycle-de-dev/planifier.md` | `04-development-cycle/planning.md` |
| `a-long-mission` | `05-equipe-agents/une-mission-longue.md` | `05-agent-team/a-long-mission.md` |
| `skills` | `06-reference/skills.md` | `06-reference/skills.md` (identique, coïncidence — traité comme toute autre entrée) |
| `anatomy-of-an-installed-lab` | `07-sous-le-capot/anatomie-d-un-lab-installe.md` | `07-under-the-hood/anatomy-of-an-installed-lab.md` |

Les 44 entrées complètes (7 thèmes + 44 pages) sont dans `manual/toc.yml`, chacune avec son `id`
logique stable. 42 des 44 pages ont changé de `path_en` ; 2 sont restées identiques par
coïncidence (`06-reference/agents.md`, `06-reference/skills.md` — dossier et slug déjà anglais des
deux côtés).

## `toc.yml` — nouvelle forme

Toujours du YAML restreint parsable en bash pur (2 espaces, une clé par ligne, aucune ancre,
aucune valeur multi-ligne — contrainte de conception préservée). Chaque entrée `themes:` porte
désormais `id`, `dir_fr`, `dir_en`, `fr`, `en` ; chaque entrée `pages:` porte `id`, `path_fr`,
`path_en`, `fr`, `en`. L'`id` est l'identifiant logique stable qui matérialise l'appariement — ce
n'est plus le chemin qui le porte implicitement. L'en-tête du fichier documente explicitement que
H-1 est levée et pourquoi (paragraphe dédié, daté).

## `manual/.tools/build-nav.sh` — ce qui a changé

- `parse_pages`/`parse_themes` extraient maintenant `id`, `path_fr`/`path_en` (ou `dir_fr`/`dir_en`),
  `fr`, `en` — 5 champs au lieu de 3.
- La validation pré-écriture vérifie `fr/$path_fr` ET `en/$path_en` par entrée (au lieu d'un
  chemin unique testé dans les deux racines).
- Le bloc de langue (`lang_block`) reçoit désormais, pour une page EN, le `path_fr` réel de son id
  comme cible miroir (`../../fr/$path_fr`), et pour une page FR, le `path_en` réel
  (`../../en/$path_en`) — plus de substitution de segment.
- Prev/next (`nav_block`) sont calculés **par langue** : les liens EN utilisent la suite des
  `PAGE_EN_PATH`, les liens FR la suite des `PAGE_FR_PATH`. Avant la levée de H-1 les deux étaient
  la même suite ; ce n'est plus vrai en général (ça l'est encore par construction pour l'ordre de
  lecture, qui reste identique des deux côtés — seul le nommage change).
- `build_sommaire($lang)` construit les liens du README avec le `dir`/`path` de la langue
  demandée, plus jamais un chemin partagé.
- Les 4 correctifs de la revue précédente (bloc `END` de `parse_themes`, trim/dé-quotage,
  `ltrim_blank`/`rtrim_blank`) sont préservés tels quels — aucune régression : revérifiés par
  l'idempotence (voir plus bas) qui aurait échoué si l'un d'eux avait sauté.

## `manual/.tools/check-manual.sh` — ce qui a changé

- **C1 (isomorphisme)** ne diffe plus les deux arbres de fichiers bruts (`find manual/fr` vs
  `find manual/en`, structurellement différents par construction désormais). Il itère les entrées
  `pages:` de `toc.yml` et vérifie, par `id`, que `fr/$path_fr` ET `en/$path_en` existent tous les
  deux. Un id dont un seul côté existe = échec.
- **C2 (bijection toc↔disque)** est désormais vérifiée **par langue** : tout `.md` de niveau page
  trouvé sur `manual/fr` doit avoir une entrée `path_fr:` dans `toc.yml`, et réciproquement (idem
  côté `en` avec `path_en:`). Avant, une seule liste de chemins partagée suffisait ; maintenant il
  y a deux bijections indépendantes.
- Le comptage `TOC_PAGE_COUNT` (contrôle C0) est passé de `grep -c '.*path:'` à
  `grep -c '.*path_fr:'` — `path:` n'existe plus, et `id:` seul aurait compté aussi les 7 thèmes,
  faussant le total à 51 au lieu de 44.
- C3, C4, C5, C6 sont inchangés dans leur logique (agnostiques du nommage des fichiers) ; C4 a été
  revérifié vert (voir plus bas) car il rejoue `build-nav.sh`, donc valide indirectement le nouveau
  code de celui-ci.

## Preuves de mutation — la démonstration exigée

**Exécutées sur des copies jetables sous `/private/tmp/.../scratchpad/`, jamais sur `manual/`
réel.** Deux mutations discriminantes, chacune restaurée avant de passer à la suivante,
revérifiées vertes après restauration.

### Mutation A — casse un appariement `toc.yml` (prouve C1 **et** C2)

Commande : remplacement de `path_en: 03-modules/catalog.md` par
`path_en: 03-modules/catalog-DOES-NOT-EXIST.md` dans une copie de `toc.yml`.

Sortie observée (extrait) :
```
    id 'catalog' : manual/fr/03-modules/catalogue.md existe mais manual/en/03-modules/catalog-DOES-NOT-EXIST.md est absent
✗ C1 isomorphisme fr/en — au moins un id sans sa paire complète (voir détail ci-dessus).
    toc.yml (id 'catalog') référence path_en '03-modules/catalog-DOES-NOT-EXIST.md' mais le fichier est absent
    manual/en/03-modules/catalog.md existe sur disque mais n'est référencé par aucune entrée 'path_en:' de toc.yml
✗ C2 toc.yml <-> disque — désaccord (voir détail ci-dessus).
✗ C4 bandeau <-> toc — build-nav.sh a échoué sur une copie de l'arbre (toc.yml référence probablement un fichier absent).
✗ check-manual: au moins un contrôle a échoué.
```
Restauration du `toc.yml` original → C0-C6 repassent tous ✓.

### Mutation B — page EN orpheline (prouve C2 **seul**, discrimine C1/C2)

Commande : `echo "# Orphan" > manual/en/06-reference/orphan-page.md` (copie jetable), sans toucher
`toc.yml`.

Sortie observée (extrait) :
```
✓ C1 isomorphisme fr/en — chaque id de toc.yml a sa paire fr+en complète sur disque.
    manual/en/06-reference/orphan-page.md existe sur disque mais n'est référencé par aucune entrée 'path_en:' de toc.yml
✗ C2 toc.yml <-> disque — désaccord (voir détail ci-dessus).
✗ check-manual: au moins un contrôle a échoué.
```
C1 reste vert pendant que C2 rougit : preuve que les deux contrôles sont réellement indépendants
(pas de « vert par construction »). Suppression du fichier orphelin → C0-C6 repassent tous ✓.

Après les deux mutations et leurs restaurations, `check-manual.sh` rejoué sur le **manuel réel**
(`/Users/samuel/Documents/dev/vibeflow-os/manual`, jamais touché par ces expériences) reste vert
— confirmé explicitement ci-dessous.

## Sortie complète de `check-manual.sh` sur le manuel réel

```
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

## Idempotence de `build-nav.sh`

Checksum SHA-256 de la concaténation triée de tous les `.md` sous `manual/`, avant et après une
deuxième exécution de `bash manual/.tools/build-nav.sh` sur le manuel réel :

```
checksum1: 0ec264d247db07948457393eeba4a1bd683933186d2a8ae545afe63cf5f2d896
checksum2: 0ec264d247db07948457393eeba4a1bd683933186d2a8ae545afe63cf5f2d896
```

Identiques — deux passes consécutives laissent l'arbre strictement inchangé.

## Confirmation : `manual/fr/**` n'a changé que sur le bloc de langue

Hash SHA-256 de chacun des 45 fichiers `manual/fr/**/*.md` calculé avant et après le renommage
EN + régénération des bandeaux. 42 pages ont un hash différent (le bloc `vf-manual:lang` pointe
vers le nouveau `path_en`) ; 3 fichiers ont un hash **identique** avant/après :
`06-reference/agents.md`, `06-reference/skills.md` (leur `path_en` n'a pas changé — dossier et
slug déjà anglais des deux côtés) et `fr/README.md` (son lien de langue vers `en/README.md` ne
dépend jamais d'un slug de page). C'est la preuve empirique directe que le seul texte modifié dans
un fichier FR touché est la ligne à l'intérieur du bloc `<!-- vf-manual:lang -->` — jamais le
corps de page ni le bandeau `<!-- vf-manual:nav -->` (celui-ci est calculé uniquement à partir des
`path_fr` voisins, qui n'ont pas bougé). Exemple concret (`manual/fr/01-demarrer/installation.md`,
un fichier touché) :

```
# Installation

<!-- vf-manual:lang -->
**Français** · [English](../../en/01-get-started/installation.md)
<!-- /vf-manual:lang -->
```

Seul le segment `01-get-started` (ex-`01-demarrer`) a changé dans cette ligne.

## `git status --porcelain -- manual`

```
(vide)
```

Confirmé après le renommage, après chaque régénération de `build-nav.sh`, et après les mutations
(qui n'ont jamais touché le manuel réel, uniquement des copies sous `/private/tmp/...`).
`git status --porcelain` à la racine, sans filtre, est également vide — rien d'autre que ce fichier
`26-10-SUMMARY.md` n'a été écrit par cette vague. `.git/info/exclude` inchangé (ligne 7 :
`manual/`). Branche `feat/phase-26-manuel-utilisateur` inchangée, aucun commit créé.

## Ce qui n'a pas bougé

- `manual/fr/**` : contenu de page strictement inchangé (voir preuve ci-dessus).
- `.planning/ROADMAP.md`, `.planning/STATE.md` : non touchés — cette vague ne clôt pas la phase.
  Le plan `26-09` reste `autonomous: false` : la décision de parité de contenu FR/EN attend
  toujours Samuel.
- `README.md`, `README.fr.md`, `INSTALL.md`, `.gitignore`, `.github/**`, `scripts/**`,
  `plugin/**`, `docs/**`, `CHANGELOG.md`, `VERSION`, `.claude-plugin/**` : aucun de ces chemins
  interdits en écriture n'a été touché.
