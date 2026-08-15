# Phase 24: Activation et mesure du moteur GSD — capacités dormantes et faits de runtime - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-04
**Phase:** 24-activation-et-mesure-du-moteur-gsd-capacit-s-dormantes-et-fa
**Areas discussed:** doctrine vers les agents du moteur (A2/A3) · gates machine (A1/A5) · routes
inertes (A7/A8 + une troisième) · réglages ré-implémentés (A4/A6) · workstreams (A9) · faits de
runtime par rôle (M1/M3)

---

## ⚠ Nature de ce cadrage — aucune discussion n'a eu lieu

Ce cadrage a été produit par **`vf-coder`**, un worker interne du team-kernel, qui **n'a pas
`AskUserQuestion` dans ses `tools:`** — par conception : un worker interne ne parle jamais à
l'utilisateur. Les six zones grises ont donc été **instruites et documentées**, jamais posées ni
tranchées.

**Aucune option n'est cochée dans les tables ci-dessous.** Elles enregistrent les alternatives
telles qu'elles seront présentées à Samuel par `vf-dev-manager`, dans un unique passage cochable.
Les recommandations et leurs justifications vivent dans `24-ARBITRAGES.md` ; ce log ne conserve que
les options et ce qui a été écarté chemin faisant.

---

## Méthode de re-constat des faits (2026-08-04)

Les faits du ROADMAP §Phase 24 dataient du **2026-07-31** et avaient été établis contre
`@opengsd/gsd-core@1.9.0`. Le cadrage les a **tous re-testés contre le disque**. Aucun n'a été
recopié.

**Précautions d'outillage appliquées** (elles ont changé des résultats, ce n'est pas décoratif) :

- `grep` est proxifié sur cette machine et **tronque silencieusement** ses sorties. Tout comptage et
  toute liste exhaustive ont été extraits en `awk` et comparés en `comm -23`/`-13`. C'est ce qui a
  permis de mesurer 7/91 workflows workstream-aware là où le ROADMAP annonçait 16/91.
- `wc -l <fichier` a rendu **`0`** sur `test-dev-orchestrator.sh` (5727 lignes réelles) — tout
  comptage de lignes est passé par `awk 'END{print NR}'`.
- Le payload de `gsd-core` a été résolu par sondage des **deux** dispositions possibles : l'installé
  (`~/.claude/gsd-core/bin/lib/`, segment simple) et le tarball npm (double segment
  `gsd-core/gsd-core/bin/lib`). Conclure « absent » depuis une seule des deux aurait été faux.
- **Aucune commande `gsd-tools state …` n'a été invoquée** (ADR-063 : `record-session` réécrit
  `.planning/STATE.md` avec `resync:true` non désactivable et fait régresser les compteurs). Le
  `write_context` du workflow amont a été suivi ; son étape `update_state` a été **délibérément
  sautée** et remontée au manager.

**Bilan : 8 faits périmés sur 23 re-testés, en 4 jours.** Trois d'entre eux inversent la conclusion
de leur item (F-20, F-25, F-33) et trois faits entièrement nouveaux ont été découverts (F-13, F-30,
F-07).

---

## Zone 1 — Comment notre doctrine de dev atteint les agents du moteur (A2, A3)

| Option | Description | Selected |
|--------|-------------|----------|
| A | Slot `PLANNER` seul, sans `tdd_mode` — canal unique prouvé | |
| B | Slots `PLANNER` et `EXECUTOR`, allowlist `vf-coder` rouverte, sans `tdd_mode` | |
| C | Slot `PLANNER` plus `tdd_mode` activé — planification et typage des tâches | |
| D | Rien : acter le refus des deux canaux, doctrine par digest | |

**User's choice:** — *en attente d'arbitrage*
**Notes:** Deux découvertes ont reformé la zone en cours d'instruction. (1) Le slot `EXECUTOR` n'est
injecté que dans le prompt de dispatch d'`execute-phase.md` ; or `gsd-executor` et `gsd-planner` ont
été retirés de l'allowlist de `vf-coder` en **Phase 23**, et le repli documenté est l'inline
séquentiel — **sans injection**. Le levier « le plus fort de tout l'audit » est donc, côté exécuteur,
un candidat au vert-à-vide. (2) `references/tdd.md` (330 l.) est déjà injecté **sans condition** dans
le prompt de l'exécuteur : `tdd_mode` n'apporte pas la doctrine TDD, seulement un tag `type: tdd` et
un gate **non bloquant**. L'hypothèse initiale « `tdd_mode` câblerait notre doctrine TDD au moteur »
a été **écartée sur pièce**.

---

## Zone 2 — Ce que la machine bloque, et ce qu'elle se contente de signaler (A1, A5)

| Option | Description | Selected |
|--------|-------------|----------|
| A | Rien de bloquant — les trois restent en signalement | |
| B | `windows_enforce` activé seul, après avoir soldé ou dérogé la fenêtre #3 | |
| C | `windows_enforce` plus `workflow_guard`, `community` refusé pour incompatibilité de style | |
| D | Les trois activés, et notre style de commit réaligné sur amont | |

**User's choice:** — *en attente d'arbitrage*
**Notes:** Le ROADMAP affirmait « un gate existe » pour les commits conventionnels : **vérifié faux**
— aucun des 6 `plugin/*/hooks/hooks.json` n'en déclare, `scripts/hooks/pre-push` est le gate de tag.
La mesure de compatibilité a été faite avant de formuler les options : sur 109 commits locaux, **23
échouent sur le type** (six types maison absents de la liste amont) et **69 % dépassent 72
caractères**. Côté A1, `open_count` est passé de 2 à **1**, et la fenêtre restante (#3, recette
XcodeBuildMCP) est **structurellement infermable dans ce dépôt** — ce qui transforme « activer le
gate » en « activer le gate **après** avoir dérogé », un ordre que le ROADMAP ne mentionnait pas.

---

## Zone 3 — Les routes qui mènent à un geste inerte (A7, A8, + une troisième)

| Option | Description | Selected |
|--------|-------------|----------|
| A | Activer `intel`, refuser `graphify` et `profile-pipeline`, gate d'activation ajouté | |
| B | Refuser les trois, marquer les entrées conditionnelles, gate d'activation ajouté | |
| C | Activer les trois capabilities et laisser la doc telle quelle | |
| D | Retirer les entrées de doc et de routage, sans gate | |

**User's choice:** — *en attente d'arbitrage*
**Notes:** Le ROADMAP décrivait **deux** routes inertes. Le cadrage en a trouvé une **troisième**, et
la plus gênante : notre propre `docs-flow.md:43-44` publie `--query` comme l'un des deux modes
normaux de `gsd-map-codebase`, alors que le skill exige `intel.enabled: true` (`SKILL.md:29`) —
c'est **notre documentation** qui promet le geste mort. Corollaire : A7 n'est pas « jamais instruit »
comme l'écrit le ROADMAP, il est **déjà promis**. Le trou de test est par ailleurs plus large que
décrit : `test-dev-orchestrator.sh` ne nomme ni `graphify` ni `gsd-profile-user` dans aucun de ses
150 cas, et `gsd-capabilities-index.md` (livré en Phase 23) ne les mentionne pas non plus.

---

## Zone 4 — Les réglages du moteur que nous ré-implémentons en doctrine (A4, A6)

| Option | Description | Selected |
|--------|-------------|----------|
| A | Refuser les profils, garder le seuil inline par défaut 2 | |
| B | Refuser les profils, mettre le seuil à 0 — délégation toujours | |
| C | Refuser les profils, monter le seuil à 3 — économie maximale | |
| D | Adopter `context: dev` et garder le seuil par défaut | |

**User's choice:** — *en attente d'arbitrage*
**Notes:** La prémisse du ROADMAP — « nous ré-implémentons en doctrine ce que le moteur porte en
config » — s'est **inversée** à la vérification : la recherche exhaustive sur `~/.claude/gsd-core`,
`~/.claude/agents` et `~/.claude/skills` ne rend que **3 occurrences, toutes auto-déclaratives** (la
ligne 3 de chacun des trois profils). **Aucun consommateur n'existe** : le moteur *déclare* la clé,
il ne la *porte* pas. La question « adopter ou acter » est donc devenue « acter, et dire si le refus
est définitif ou daté » — ce dernier point exige de savoir si la clé est abandonnée ou pas encore
câblée en amont, ce qui n'est pas lisible depuis le disque (remonté en `action: research`). Côté A6,
le seuil a été chiffré contre nos plans réels avec la regex exacte du moteur avant de formuler les
options : 4 plans sur 28 sous le seuil, mode à 3 tâches.

---

## Zone 5 — Chantiers parallèles : les workstreams (A9)

| Option | Description | Selected |
|--------|-------------|----------|
| A | Refuser, acter ADR-064 comme réponse unique aux chantiers parallèles | |
| B | Borner à un usage restreint, en listant les workflows interdits | |
| C | Adopter et payer la mise à niveau de toute notre couche | |
| D | Refuser maintenant, remonter les 42 workflows aveugles en amont | |

**User's choice:** — *en attente d'arbitrage*
**Notes:** Deux faits ont bougé de façon décisive. (1) La **PR #27 est CLOSE** depuis le
2026-08-03 — jamais mergée, restée en `CHANGES_REQUESTED` : plus personne ne porte la proposition, et
le statu quo de fait est déjà le refus. (2) La couverture amont re-mesurée est de **7/91 = 7,7 %**,
pas 18 % — la divergence tient à la méthode de comptage (`awk` + `comm` contre `grep` tronqué), et
elle **durcit** la conclusion au lieu de l'adoucir. Les trois constats d'outillage aveugle du bac à
sable tiennent **par lecture du code** (chemins en dur à `check-dev-bootstrap.sh:111` et
`check-state-integrity.sh:53`, regex ancrées à `pr-branch.md:235-236` — lignes glissées depuis la
1.9.0). Le **symptôme** rouge n'a pas été re-mesuré : les deux gates sont verts aujourd'hui, et les
faire rougir exigerait de partitionner `.planning/` — **écarté comme hors périmètre du nœud**, pas
comme non pertinent.

---

## Zone 6 — Les faits de runtime par rôle, écrits nulle part (M1, M3)

| Option | Description | Selected |
|--------|-------------|----------|
| A | Écrire la marge de profondeur, et `effort:` par rôle sur tous | |
| B | Écrire la marge de profondeur seulement, `effort` laissé au défaut | |
| C | `effort:` par rôle seulement, la marge reste non écrite | |
| D | Ni l'un ni l'autre — statu quo documenté nulle part | |

**User's choice:** — *en attente d'arbitrage*
**Notes:** La sonde M3 a été **re-lancée** au lieu d'être recopiée, et sous deux formes. La sonde
littérale du ROADMAP (`plugin/*/agents/*.md`, 25 agents livrés) confirme **0 déclaration** ; la sonde
élargie (`plugin/**/agents/*.md`, 49 fichiers) trouve **3 agents-templates qui portent déjà
`effort: medium|high`** sous `plugin/reference/content/methodology/templates/agents/`. Le barème par
rôle n'est donc **pas à inventer** — il existe dans nos templates et n'a jamais été appliqué aux
agents livrés. Cela déplace M3 d'une décision de doctrine vers une décision de propagation, et rend
l'option D plus coûteuse à défendre qu'elle ne le paraissait.

---

## Claude's Discretion

Points laissés au plan, jamais remontés à Samuel : noms de fichiers et de clés · forme et emplacement
des cas de test · rédaction exacte des lignes de doctrine · découpage en plans et leur ordre ·
numérotation des ADR · choix entre étendre un fichier de référence existant et en créer un (sous
ADR-057) · formulation de la raison de dérogation `windows waive` · libellés des entrées
conditionnelles de routage.

## Deferred Ideas

- **Recaler le ROADMAP §Phase 24** (8 faits périmés en 4 jours) — gouvernance de fin de phase, au
  dernier plan de la 24, comme l'ont été les §Phase 20 et §Phase 21.
- **Remontées upstream** à `@opengsd/gsd-core` : les 42 workflows aveugles aux workstreams et les
  3 profils de contexte sans consommateur. Gestes de contribution externe — ils se planifient, ils ne
  se livrent pas dans ce dépôt.
- **Fenêtre WINDOWS #3** (recette XcodeBuildMCP sur lab iOS équipé) — non fermable ici ; sa
  résolution appartient à un lab iOS.
- **Path-scope de `production-code-architecture`** (`src|app|lib|features`, aucun n'existe dans ce
  dépôt — la règle y est dormante) — défaut du module `software-architecture`, hors des 11 items,
  à porter au backlog.
- **Phase 25** (budget d'instructions, étage d'alignement court) — frontière explicite du ROADMAP,
  jamais franchie pendant ce cadrage.
