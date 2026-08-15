# Phase 28: Preuve que ce qui est armé dans le plugin est armé chez l'utilisateur - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-10
**Phase:** 28-preuve-que-ce-qui-est-arme-dans-le-plugin-est-arme-chez-l-utilisateur
**Areas discussed:** Recensement, Verdict, Emplacement, Portée, Angle mort, Cas de preuve

> **Note de méthode.** Le préalable posé à la création de la phase (« mise à jour de VibeFlow avant
> le cadrage, et ce qu'elle change doit être re-mesuré, jamais repris depuis l'entrée de roadmap »)
> a été honoré **avant** la première question : re-mesure de la version installée, du moteur GSD, de
> l'état des agents, de la localisation de `worktree.baseRef`, et de ce que l'engine pose réellement
> dans `settings.json`. Deux faits neufs en sont sortis — gsd-core est passé de 1.9.1 à **1.10.0**,
> et l'engine n'a **aucun véhicule** de distribution de settings hors `hooks`. Le second a
> directement changé les options présentées sur la question « Verdict ».
>
> Les six questions ont été posées en **deux appels groupés** (4 puis 2), conformément à la
> préférence de cadrage : groupées par zone, cochables, jamais en rendu texte.

---

## Recensement — qu'est-ce qu'un « armement » recensable ?

| Option | Description | Selected |
|--------|-------------|----------|
| Déclaré par l'artefact | L'agent/skill déclare sa précondition en frontmatter (patron `vf-mcp-consumer`). Le gate ne devine rien. Angle mort assumé : un armement non déclaré reste invisible. | ✓ |
| Liste close de clés connues | On fige `isolation:`, `mcp__*`, capability de `config.json`. Lisible et borné, mais chaque nouveau cas demande une édition. | |
| Registre armement↔précondition | Un fichier liste les couples. Très lisible, mais c'est le type d'artefact qui dérive dès qu'on oublie une ligne — l'oubli étant le mode d'échec de #38. | |
| Découverte par heuristique | Le gate scanne et infère. Zéro maintenance, aucune borne — le scénario « inerte ou insupportable » nommé par le ROADMAP. | |

**User's choice:** Déclaré par l'artefact.
**Notes:** L'angle mort a été signalé dans la description de l'option au moment du choix, puis
rouvert immédiatement après en question de second tour (voir « Angle mort ») parce qu'il reproduisait
exactement le mode d'échec de #38. La combinaison retenue au final est *déclaration + liste close*.

---

## Verdict — que fait le gate quand la précondition n'est posée par personne ?

| Option | Description | Selected |
|--------|-------------|----------|
| Bloque, et `ensure-*` vaut preuve | Refus par défaut, mais un `ensure-*.sh` runtime déclaré compte comme distribution valide. Réutilise les deux patrons déjà posés (#38 et `ensure-design-deps.sh`) sans ouvrir de véhicule de settings. | ✓ |
| Bloque, point | Comme le fix #38 : le gate refuse, l'auteur désarme. Le plus simple et le plus dur ; aucune porte pour armer légitimement une capacité à précondition externe. | |
| L'engine pose le réglage | Ouvrir un véhicule de distribution de settings au-delà de `hooks`. Résout à la racine, mais agrandit nettement la phase. | |
| Exige un `ensure-*` runtime | Toute précondition externe vérifiée chez l'utilisateur, jamais gatée en CI. Déplace la garantie du build vers le runtime. | |

**User's choice:** Bloque, et `ensure-*` vaut preuve.
**Notes:** L'option « l'engine pose le réglage » n'était pas un simple réglage de curseur : la
mesure faite avant la question a établi que `merge-hooks.sh` ne merge que la clé `hooks` et que
`vibeflow-update.sh` ne touche `settings.json` que par ce merger. La choisir aurait donc impliqué de
créer le véhicule **et** de faire écrire l'engine dans le settings de l'utilisateur. Elle est
consignée en idée différée, avec la condition qui la rendrait pertinente : une précondition qu'aucun
`ensure-*.sh` runtime ne peut vérifier.

---

## Emplacement — où vit le gate ?

| Option | Description | Selected |
|--------|-------------|----------|
| Étendre `check-capability-activation.sh` | Le précédent exact, un cran plus loin. Évite un sixième gate. Coût : le script est déjà à 443 lignes et très commenté. | ✓ |
| Extension + preuve en lab frais | Une seule implémentation, exécutée aussi par le job CI `lab-frais`. | |
| Job lab frais uniquement | Le job a déjà l'environnement d'un lab vierge installé, mais moins de lisibilité qu'un gate nommé. | |
| Nouveau gate dédié | Le plus lisible ; c'est le réflexe que la Phase 24 a chiffré comme coûteux (6 implémentations d'un même besoin en 3 langages). | |

**User's choice:** Étendre `check-capability-activation.sh`.
**Notes:** L'option « extension + preuve en lab frais » n'a pas été retenue comme choix, mais son
contenu a été conservé en **D-04** : le gate doit voir ce que l'install pose, pas seulement ce que le
repo contient — c'est la faille de fond de #38 (le repo avait le réglage en settings local, donc tous
ses gates rendaient vert). Les deux ne s'excluent pas : une implémentation (D-03), deux points
d'exécution (D-04). La question du seuil de `check-file-size.sh` si l'extension alourdit le script
est renvoyée au plan, avec l'interdiction explicite d'en faire un prétexte à créer un gate parallèle.

---

## Portée — gate seul ou traitement de l'existant ?

| Option | Description | Selected |
|--------|-------------|----------|
| Gate + un cas de preuve | Poser le gate, puis traiter UN cas réel pour prouver qu'il discrimine. Le reste en backlog. Phase bornée, preuve réelle. | ✓ |
| Gate + passage complet de l'existant | Solder tout ce que le gate remonte. Le plus complet ; taille inconnue tant que le gate n'a pas tourné. | |
| Gate seul | Tout finding en backlog. Le plus court — mais un gate jamais vu rouge sur un cas réel n'est pas prouvé. | |

**User's choice:** Gate + un cas de preuve.
**Notes:** Deux candidats de findings ont été identifiés pendant la mesure et partent en différé :
les outils `mcp__*` de `vf-reviewer` (seul agent concerné du corpus) et la chaîne design couverte par
`ensure-design-deps.sh`.

---

## Angle mort — le gate ne vérifie que le déclaré, or #38 est passé faute de déclaration

*Question de second tour, ouverte parce que le choix « déclaré par l'artefact » laissait intact le
mode d'échec exact de l'incident qui ouvre la phase.*

| Option | Description | Selected |
|--------|-------------|----------|
| Déclaration + liste close | Le gate vérifie le déclaré ET une petite liste close de clés déjà connues comme dangereuses. #38 aurait été vu par la seconde. Coût : deux mécanismes dans un seul gate. | ✓ |
| Déclaration obligatoire | Tout agent distribué DOIT porter un champ de préconditions, même vide. Rien d'implicite. Coût : ligne à ajouter sur 25+ agents, et `none` peut devenir un réflexe vide de sens. | |
| Angle mort assumé et écrit | Le gate ne couvre que le déclaré et l'écrit dans son en-tête (patron de `check-capability-activation.sh`). Honnête et simple ; ne ferme pas le mode d'échec de #38. | |

**User's choice:** Déclaration + liste close.
**Notes:** Le partage de rôles est explicite dans CONTEXT.md (D-01) : la déclaration porte
l'extensible, la liste close rattrape le connu. La liste close démarre à `isolation:` et aux outils
`mcp__*` ; son énumération complète est un calcul de planification, jamais une heuristique. L'option
« angle mort assumé » n'est pas perdue : son exigence rédactionnelle est reprise en **D-01b** — le
gate écrit ses propres bornes dans son en-tête, quelle que soit la couverture retenue.

---

## Cas de preuve — quel cas réel prouve que le gate discrimine ?

| Option | Description | Selected |
|--------|-------------|----------|
| Rejouer #38 en test | ROUGE si `isolation: worktree` revient sans précondition distribuée, VERT une fois désarmé. Discriminance vérifiée sur l'incident même — méthode déjà employée par le fix v2.50.1. | ✓ |
| La chaîne design (`ensure-*`) | `ensure-design-deps.sh` existe depuis le 2026-08-10 ; bon cas pour prouver que le verdict VERT fonctionne. | |
| Outils `mcp__*` de `vf-reviewer` | Solde la dette WINDOWS #4, mais la recette réelle est infaisable dans ce dépôt (aucun `.mcp.json`). | |
| Les deux premiers | Rouge par #38, vert par la chaîne design : couverture bidirectionnelle. Phase un peu plus large. | |

**User's choice:** Rejouer #38 en test.
**Notes:** Un point de vigilance a été inscrit en **D-06** plutôt que laissé implicite :
`check-agents.sh:528-549` interdit **déjà** toute valeur d'`isolation:` dans un agent distribué. Le
test de discriminance doit donc établir que le **nouveau** gate rend rouge de son propre chef, et pas
seulement que l'ancien le fait encore. Si les deux gardes se recouvrent intégralement, le plan doit
dire laquelle porte la règle et pourquoi l'autre subsiste. La chaîne design reste notée comme seconde
preuve à coût faible si le plan veut couvrir aussi le verdict vert.

---

## Claude's Discretion

- Mécanisme exact de liaison artefact ↔ `ensure-*.sh` (nommage, frontmatter ou registre) — seule
  contrainte : explicite et vérifiable par machine.
- Nom de la clé de frontmatter portant la précondition déclarée, et son ajout aux clés `KNOWN` de
  `check-agents.sh:160`.
- Contenu initial complet de la liste close (`isolation:` et `mcp__*` sont le plancher).
- Découpage éventuel de `check-capability-activation.sh` s'il franchit le seuil de
  `check-file-size.sh`.
- Forme du test de discriminance et son emplacement dans les suites.
- Articulation exacte avec `check-agents.sh` sur le cas `isolation:`.
- Découpage en plans, numérotation, nommage des artefacts produits.

## Deferred Ideas

- **Ré-armer `isolation: worktree`** — fermé tant qu'`open-gsd/gsd-core#3302` n'est pas levée. Le
  périmètre a été tenu explicitement pendant tout le cadrage : la phase porte le gate, jamais le
  ré-armement.
- **Distribuer `worktree.baseRef`** — corollaire du précédent, même verrou.
- **Ouvrir un véhicule de distribution de settings dans l'engine** (au-delà de `hooks`) — écarté par
  le choix de verdict. Redevient pertinent si une précondition ne peut pas être vérifiée par un
  `ensure-*.sh` runtime.
- **Findings du gate sur l'existant** — outils `mcp__*` de `vf-reviewer`, chaîne design.
- **WINDOWS #3 / #4** (`.planning/STATE.md` §Deferred) — même famille, mais #4 est déjà repris au
  périmètre de la Phase 21 et #3 est infaisable dans ce dépôt.
