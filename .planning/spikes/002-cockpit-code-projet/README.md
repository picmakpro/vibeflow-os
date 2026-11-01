---
spike: 002
idea: cockpit-code-projet
name: cockpit-code-projet
type: standard
validates: "Given le viewer de floorplan vendorisé et le .planning/ de vibeflow-os, when on génère sans LLM un onglet Code et un onglet Projet sur le même moteur, then on navigue jalon → phase → plan → fichiers de code et retour, avec statuts, dépendances et DA d'origine"
verdict: VALIDATED
related: [001-cockpit-live]
tags: [cockpit, floorplan, visualisation, planning, elk]
---

# Spike 002 : cockpit Code + Projet sur la base de floorplan

## Ce qu'on valide

Given la copie figée du viewer de floorplan (v0.6.0, MIT) et le `.planning/` réel de ce dépôt,
when on génère sans LLM deux pages sur le même moteur (Code et Projet),
then on navigue de la racine du projet jusqu'aux plans, et d'un plan aux fichiers de code qu'il
touche, et retour. Les statuts, les dépendances et la DA de floorplan sont conservés.

## Recherche

Étude préalable : `docs/research/2026-11-01-etude-floorplan-cockpit.md`. Approches comparées :

| Approche | Pour | Contre | Statut |
|---|---|---|---|
| Réécrire un viewer à la DA de floorplan | maîtrise totale | des semaines, on refait ELK, le zoom, le panneau, le mobile | écartée |
| **Réutiliser le viewer tel quel, avec un graphe Projet au format `floorplan/graph@1`** | le moteur, la DA, la recherche, les flows, l'export, le mobile viennent gratuitement | le modèle est pensé pour du code (libellés, statistiques) | **retenue** |
| Faire de `.planning/` une « carte de code » (scan de fichiers markdown) | zéro patch | aucun statut, aucune dépendance, des cartes vides de sens | écartée |

Constat clé : le viewer est générique. Il ne connaît que des nœuds hiérarchiques, des « fichiers »
rattachés à un nœud, et des liens typés. ELK respecte l'ordre des données
(`considerModelOrder`). Un jalon, une phase, un plan ou une exigence s'y modélisent sans forcer.

## Lancer

```bash
node .planning/spikes/002-cockpit-code-projet/build-cockpit.mjs .   # 2,3 s, aucun LLM
node floorplan/serve.mjs                                             # http://127.0.0.1:4378
```

`/` affiche l'onglet Code, `/project.html` l'onglet Projet. Le dossier `floorplan/` s'ignore
lui-même dans git.

## Ce qui a été construit (463 lignes à nous + 5 patchs)

- `vf-project-graph.mjs` (195 l.) : lit ROADMAP, STATE et REQUIREMENTS des compartiments et des
  archives, les dossiers de phase (PLAN, SUMMARY, frontmatter `wave`, `depends_on`,
  `requirements`, `files_modified`), les DAG de mission, BACKLOG, les graines et les tags git.
  Il produit un graphe `floorplan/graph@1`.
  - Hiérarchie : Historique → jalons → phases → plans + Exigences + Mission (DAG).
  - À la racine : le jalon en cours, ses voisins, le jalon de Willy, les missions hors phase, le
    backlog, les graines et les releases.
- `vf-code-arch.mjs` (104 l.) : l'`architecture.json` de l'onglet Code (un nœud par module, ses
  dossiers types en enfants) **et l'extracteur VibeFlow** qui manque à floorplan : dispatch entre
  agents (`Agent(...)` du frontmatter), scripts sourcés ou appelés depuis un script, un agent, un
  skill ou une référence.
- `build-cockpit.mjs` (65 l.) : enchaîne scan → architecture → graphe Projet → `recent-work.json`
  (les 2 dernières phases exécutées) → build floorplan. Il décrit ensuite les fichiers sans LLM
  (frontmatter `description`, en-tête des scripts) et écrit les deux pages par épissure des
  données dans le même `index.html`.
- `floorplan/assets/ui/00-vibeflow.js` (99 l.) : les onglets, les pastilles de statut, le panneau
  d'ensemble Projet (« Maintenant », prochaines phases, barres de progression par jalon) et le pont
  entre onglets dans les deux sens.
- Patchs sur la copie figée (`floorplan/VENDORED.txt`) :
  - P1 : libellés des liens ;
  - P2 : pied de carte et pastille de statut ;
  - P3 : classe de statut ;
  - P4 : `setOverview` ;
  - P5 : `no-store` sur les fichiers servis.

## Ce qu'on observe (2026-11-01, vibeflow-os)

| | Mesure |
|---|---|
| Assemblage complet | **2,3 s**, 0 token |
| Onglet Code | 528 fichiers (agents, skills, scripts, références) ; **1 244 liens contre 7** pour floorplan seul ; **497 décrits sans LLM** |
| Onglet Projet | 11 jalons, 65 phases, 263 plans, 281 exigences rattachées à leur phase, 25 DAG, 1 460 liens (dépendances de phases et de plans, couverture des exigences, enchaînement des jalons, étapes de mission) |
| Pont | 458 fichiers de code reliés aux plans ou aux nœuds de mission qui les ont touchés |
| Statuts | 913 faits, 85 à faire, 2 en cours, 3 bloqués (les 3 nœuds `failed` de la mission 414) |
| Recent work | 44 cartes de code surlignées « Changed », rattachées aux Phases 61 et 62 et à leur objectif |

Captures (`captures/`) :
- 1 : racine du projet ;
- 2 : jalon en cours en DAG de phases (57 → 58 → 59 → 60 → 61 → 62, avec 63 branchée sur 59 et 60) ;
- 3 : une phase et ses 8 plans en vagues ;
- 4 : un plan, ses fichiers touchés et ses exigences couvertes ;
- 5 : un script dans l'onglet Code, avec « Changed · Phase 61 », « Used by 5 » et « Touché par » ;
- 0 : floorplan seul sur malt-keyword.

## Trace de l'investigation

1. **Premier rendu de la racine** : 15 cartes en une seule chaîne, illisibles au zoom.
   → Les jalons clos sont regroupés sous « Historique ». La racine passe à 8 cartes.
2. **Aucun lien de dépendance entre phases** : la ROADMAP écrit `**Goal:**` et
   `**Depends on:**` (deux-points dans le gras), alors que la regex attendait `**Goal**:`.
   → Corrigé. 75 liens de dépendance apparaissent, et le jalon se lit comme un DAG ordonné.
3. **Jalons mal bornés** (equipe-produit à 0 phase, fiabilite à 6) : un `$` en mode multiligne
   coupait la description à la première ligne, et « Phases 30-35, 37-41.4 + Phases 18 et 25 » déjouait
   la regex de plages.
   → Corrigé. Les 11 jalons collent à la ROADMAP (Phase 36 « RÉSERVÉ » volontairement hors jalon).
4. **`project.html` servi depuis le cache** après chaque rebuild : le serveur de floorplan
   n'envoie `no-store` que sur `/`. → Patch P5.
5. **24 « Bloqué » trompeurs** : dans `dag.sh`, `blocked` veut dire « en attente de ses
   dépendances ». → Il devient « À faire ». Seul `failed` reste « Bloqué ».
6. **Plans des Phases 11 à 14 « À faire »** alors que la phase est cochée (closes avant le suivi
   GSD, sans SUMMARY). → La case cochée de la phase fait foi, comme pour `roadmap.cjs`.
7. **Piège d'outillage** : l'outil d'écriture convertit les échappements `\u2028`/`\u2029` en
   caractères invisibles réels, ce qui casse la regex. → Remplacés par leur forme échappée. À
   retenir pour tout code qui inline du JSON dans du HTML.

## Résultats

**VALIDATED** : le viewer de floorplan porte un onglet Projet sans réécriture. Il suffit de
5 patchs de quelques lignes et d'une extension par l'API `window.Floorplan`. La DA, le zoom,
la recherche, les flows (« Trajectoire du jalon »), le mode sombre, l'export et la barre de
questions de l'onglet Code viennent sans travail.

Limites constatées, à traiter dans la vraie phase :
- **Pas de questions sur l'onglet Projet** : `serve.mjs` ne répond que sur le graphe de code
  (barre masquée). Il faut un second jeu d'instructions sur `project-graph.json` pour demander
  « où en est la 64 ? ».
- **Pas de direct** : ni verrou de driver, ni agents en vol. Les statuts viennent du disque à
  l'instant du build. La suite : `driver-lock.sh status --all` + `running` des DAG en statut
  « en cours », rebuild sur surveillance de `.planning/` (le serveur recharge déjà les onglets
  quand `index.html` change). C'est le terrain de vf-signal.
- **Chrome en anglais et types de code** : « File », « Service », « Depends on », « Used by ».
  Il faut des types dédiés (jalon, phase, plan, exigence, mission) et la traduction de la chrome.
- **Pastilles « Changed »** de la phase 62 aussi sur `.planning/` (filtrées) : ce Recent work est
  une approximation, à remplacer par le diff réel de la branche de phase.
- **Densité des liens** plan → Exigences sur les grosses phases : il faudrait regrouper par
  famille.
- **Copie figée** : 5 patchs à reporter à chaque synchro amont. P1 à P4 sont de bons candidats
  à une PR amont (crochets génériques).

## Reconstruire la copie figée

La copie de floorplan (v0.6.0 @ 92d6854, MIT) n'est pas commitée : `floorplan/` est ignoré.
Elle se reconstruit depuis l'amont, les patchs P1-P8 et nos extensions (preuve : `diff -r` = 0 contre la copie figée d'origine).

```bash
cd .planning/spikes/002-cockpit-code-projet
git clone https://github.com/haydenschmitty/floorplan /tmp/fp-up && git -C /tmp/fp-up checkout 92d6854
cp -R /tmp/fp-up/skills/floorplan floorplan && cp /tmp/fp-up/LICENSE floorplan/LICENSE
(cd floorplan && for p in ../patches/*.diff; do patch -p1 < "$p"; done)
cp extensions/*.js floorplan/assets/ui/ && cp VENDORED.txt floorplan/
```
