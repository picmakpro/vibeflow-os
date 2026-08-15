# Phase 22: Hygiène documentaire — doctrine de sortie et captation d'intention - Discussion Log

> **Trace d'audit seulement.** Ne pas utiliser comme entrée d'un agent de planification, de
> recherche ou d'exécution. Les décisions vivent dans `22-CONTEXT.md` — ce journal préserve les
> alternatives écartées et pourquoi.

**Date:** 2026-07-31
**Phase:** 22-Hygiène documentaire — doctrine de sortie et captation d'intention
**Zones discutées:** Où vit la doctrine · Autonomie du geste doc · Moments déclencheurs ·
Désambiguïsation + design · Gate machine

---

## Sélection des zones

Quatre zones proposées, **les quatre retenues** par Samuel. Une cinquième (gate machine) a été
posée en fin de parcours car elle relève d'une convention du repo plutôt que d'une préférence.

---

## Où vit la doctrine

### Question 1 — Où héberger la doctrine documentaire ?

| Option | Description | Retenue |
|---|---|---|
| dev-orchestrator | `references/docs-flow.md`, symétrique d'`ingestion-flow.md`, même chemin d'install D7. Le design y renvoie, comme pour `mission-cross-team.md`. Coût : dépendance douce design → dev | ✓ |
| team-kernel (conductor) | Transverse à tous les métiers, comme `dag.sh`/`driver-lock.sh` depuis v2.34.0. Coût : hébergerait une doctrine parlant d'outils `gsd-*` absents du module hôte | |
| Éclatée par métier | Une doctrine dev, une doctrine design. Coût : deux sources de vérité sur le même geste — ce qu'ADR-057 interdit | |

**Choix :** dev-orchestrator.
**Notes :** le précédent `mission-cross-team.md` (hébergé côté dev, référencé côté design) rend le
renvoi naturel et déjà éprouvé.

### Question 2 — Que doit couvrir ce fichier ?

| Option | Description | Retenue |
|---|---|---|
| Les 4 familles | Produit + code + savoir traités en propre, **renvoi** vers `ingestion-flow.md` pour l'entrée, jamais duplication | ✓ |
| Sortie produit seulement | Uniquement `gsd-docs-update` et ses flags. Coût : le discernement « la doc » (README) vs « la carto » (`.planning/codebase/`) reste nulle part — la confusion n°1 identifiée | |

**Choix :** les 4 familles.

---

## Autonomie du geste doc

Fait posé avant la question : `gsd-docs-update` écrit jusqu'à 9 fichiers, scanne les secrets, puis
**commite** (`commit_docs: true`). `--verify-only` n'écrit rien. `--force` écrase le manuscrit sans
prompt.

### Question 1 — Régime de confirmation pour un déclenchement depuis un agent

| Option | Description | Retenue |
|---|---|---|
| Gradation par risque | `--verify-only` libre (read-only), génération sous confirmation explicite. Même axe que la revue graduée de la Phase 20 : on gradue sur le risque réel, pas sur le volume | ✓ |
| Tout gaté (aligné ingestion) | Aucun appel sans confirmation, même `--verify-only`. Coût : on gate un geste qui ne peut rien casser, et l'agent perd le moyen de constater avant de proposer | |
| Libre (gates internes) | On se fie aux `AskUserQuestion` du moteur. Coût : ces gates tombent quand le skill est invoqué depuis un sous-agent sans `AskUserQuestion` au runtime — défaut D-09 déjà constaté en Phase 20 | |

**Choix :** gradation par risque.

### Question 2 — Mode autonome (`vf-auto`, « la nuit »)

| Option | Description | Retenue |
|---|---|---|
| Constater et consigner | `--verify-only`, constat au rapport, génération proposée en next step. Rien n'est écrit sans humain | ✓ |
| Générer, c'est le but de l'autonomie | Une mission autonome qui laisse la doc périmée n'a pas fini. Coût : écrase potentiellement du travail manuscrit pendant la nuit | |
| Rien du tout | Aucun geste doc en autonome. Coût : le mode où la doc dérive le plus vite est celui où on ne regarde jamais | |

**Choix :** constater et consigner.

### Question 3 — Le flag `--force`

| Option | Description | Retenue |
|---|---|---|
| Interdit aux agents *(recommandé par Claude)* | Ligne rouge : jamais depuis un agent, réservé à un appel humain direct. Il détruit du travail humain sans le montrer d'abord | |
| Autorisé sur intention explicite | « refais toute la doc » → l'agent le passe. Coût : la formulation déclencheuse devient un point d'erreur d'interprétation, sur un geste destructif | ✓ |

**Choix :** autorisé sur intention explicite — **contre la recommandation**.
**Notes :** décision assumée de Samuel. La contrepartie négociée est le garde-fou de la question 4,
qui borne le déclencheur au lieu de le laisser à l'interprétation. Ce débat est **clos** : ni la
planification ni l'exécution ne doivent le rouvrir.

### Question 4 — Garde-fou autour de `--force`

| Option | Description | Retenue |
|---|---|---|
| Reformuler + confirmer, jamais en mission | L'agent liste ce qui sera écrasé (dérivé d'`existing_docs`), attend un oui, puis appelle. Interdit en mission d'équipe et en autonome | ✓ |
| Confirmation simple | Un « tu confirmes ? » sans lister les fichiers | |
| La formulation suffit | Aucun filet | |

**Choix :** reformuler + confirmer, jamais en mission.

---

## Moments déclencheurs

### Question 1 — Grain du geste doc dans une mission d'équipe (DAG)

| Option | Description | Retenue |
|---|---|---|
| Un nœud agrégé en fin de mission | `deps` = tous les `exec-N`. Le coût (9 agents + waves) est payé une fois, sur l'état final | ✓ |
| Un nœud par étape, conditionnel | `docs-N deps=exec-N` sur déclencheur factuel. Plus réactif, gros coût cumulé, re-documente les mêmes fichiers | |
| Jamais en mission | Proposé au next step seulement. Le moins cher. Coût : redevient une intention à capter, pas un geste garanti | |

**Choix :** un nœud agrégé en fin de mission.
**Notes :** l'argument décisif retenu est qu'un nœud par étape documenterait des états
intermédiaires déjà périmés à l'étape suivante.

### Question 2 — Déclencheurs de la pose du nœud (multi-sélection)

| Option | Description | Retenue |
|---|---|---|
| Surface publique touchée | Le diff modifie API/CLI/config/schéma — ce que décrivent README, API.md, CONFIGURATION.md | ✓ |
| Signal `[doc-drift]` actif | `check-doc-drift.sh` sort en exit 0 au démarrage. Fait déjà produit, coût nul | ✓ |
| Fin de milestone | La clôture enchaîne déjà audit → clôture → nettoyage | ✓ |
| Nouveau module / nouvelle capacité | Un point d'entrée apparaît, sans aucune doc par construction | ✓ |

**Choix :** les quatre.

---

## Désambiguïsation + design

### Question 1 — « Mets à jour la doc » vise 4 familles. Comment router ?

| Option | Description | Retenue |
|---|---|---|
| Juger sur le contexte, demander si creux | Le geste qui vient de se fermer donne la famille ; question courte seulement sur formulation creuse. Heuristique 5 déjà en vigueur | ✓ |
| Toujours demander | Zéro erreur de routage. Coût : friction sur chaque demande, y compris les non ambiguës | |
| Défaut sur la doc produit | Simple. Coût : « la doc du repo est à jour ? » sur un projet non cartographié partirait sur le README | |

**Choix :** juger sur le contexte, demander si creux.

### Question 2 — Geste documentaire pour `vf-design-manager`

| Option | Description | Retenue |
|---|---|---|
| Même doctrine, mêmes déclencheurs | Même nœud agrégé en fin de mission design ; `DESIGN.md` reste son gate propre ; il a déjà l'outil `Skill` | ✓ |
| Signaler seulement | Consigne au rapport, geste laissé au dev. Coût : personne ne ramène le signal, il meurt dans un rapport | |
| Rien, `DESIGN.md` suffit | Coût : la lacune 3 reste entière | |

**Choix :** même doctrine, mêmes déclencheurs.

### Question 3 — `check-doc-drift.sh` doit-il évoluer ?

| Option | Description | Retenue |
|---|---|---|
| Inchangé, la doctrine gradue | Le script constate le FAIT, la doctrine dit quoi en faire. ADR-055 §3, zéro code nouveau | ✓ |
| L'enrichir pour nommer les docs périmées | Signal plus actionnable. Coût : jugement déguisé en fait, et doublerait le périmètre | |

**Choix :** inchangé.

---

## Gate machine

### Question — Quelle garantie machine pour cette doctrine ?

| Option | Description | Retenue |
|---|---|---|
| Étendre le test existant | `test-dev-orchestrator.sh` gagne : existence + référencement de `docs-flow.md`, traitement des 4 familles, ligne rouge `--force` | ✓ |
| Aucun gate nouveau | Prose relue humainement. Coût : rien n'empêche un futur agent de perdre le renvoi — c'est ce qui a laissé la lacune actuelle s'installer | |
| Gate + vérification de non-duplication | En plus : assertion que `docs-flow.md` ne redéfinit rien d'`ingestion-flow.md`. Plus strict, plus coûteux | |

**Choix :** étendre le test existant.
**Notes :** l'extension, plutôt qu'une suite nouvelle, évite de devoir rattraper le compteur
« N suites » des deux README racine gaté par `check-version-sync.sh`.

---

## Zones grises supplémentaires

Proposées à Samuel en fin de parcours. Réponse : *« rien de plus si tu n'as pas d'autres zones
grises, enchaîne »*. Aucune zone additionnelle ouverte.

---

## Discrétion de Claude

- Structure interne de `docs-flow.md` (ordre des sections, forme des tables), sous contrainte
  ADR-029 et symétrie avec `ingestion-flow.md`.
- Liste exacte des formulations captées, à condition que `--verify-only` et `--force` aient chacune
  la leur.
- Forme exacte des assertions du test.
- Découpage en plans.

## Idées différées

- **Enrichir `check-doc-drift.sh` pour nommer les docs périmées** — écarté en zone 4 (jugement
  déguisé en fait, périmètre doublé). À reconsidérer si le signal binaire s'avère trop grossier.
- **Assertion de non-duplication `docs-flow.md` ↔ `ingestion-flow.md`** — proposée en zone 5, non
  retenue au profit de l'extension simple.
