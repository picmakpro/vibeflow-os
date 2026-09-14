# `vibeflow-head` — le head of minds du dev-orchestrator

> **Statut** : conception cadrée, **pas encore inscrite à la feuille de route** (le repo est piloté
> par GSD : l'inscription passe par `gsd-phase`, puis `gsd-discuss-phase` — cette note est l'entrée
> du cadrage, elle ne le remplace pas).
> **Arbitrages** : Samuel, AskUserQuestion session principale, **2026-09-15** (4 zones, voir §2).
> **Origine** : demande de renommer `vibeflow-dev` en head of minds — l'orchestrateur qui lance
> les managers, sait ce qui se parallélise, choisit le bon niveau d'équipe, tient le repo en
> ordre à la sortie des managers sans re-vérifier ce qu'ils ont déjà prouvé, et compte ce que
> ses équipes coûtent.

---

## 1. Diagnostic — ce que `vibeflow-dev` est, ce qui lui manque

`plugin/dev-orchestrator/AGENT.md` (205 lignes / 250 ADR-029) est un **routeur d'intention** :
une phrase → un geste outillé, proposition d'équipe sur signal mission, next step en clôture.

Trois manques pour le rôle de head :

| Manque | Aujourd'hui | Head |
|---|---|---|
| **Portefeuille** | réagit à une demande | lit la feuille de route, décide quoi lancer, dans quel ordre, avec quel niveau d'équipe |
| **Gouvernance de sortie** | relaie le rapport de mission | vérifie l'état du repo à la sortie de chaque manager, sur témoin machine |
| **Économie** | un seul chiffre, `SEUIL_EQUIPE = 3`, dans `vf-auto` seulement | table de proportionnalité graduée + décompte par mission + interdits de re-travail |

Ce que le head **ne duplique pas** (déjà dans le team-kernel, `conductor-references/team-kernel.md`) :
DAG et frontière `ready`, dispatch parallèle sur périmètres disjoints, verrou de driver, rapports
typés, digest de mission, halt conditions, hygiène doc en nœud unique. Sa valeur est **un cran
au-dessus** du manager : allouer, séquencer, contrôler la sortie, compter.

## 2. Décisions verrouillées (2026-09-15)

- **D-01 — Périmètre : head dev, dans `dev-orchestrator`.** `vibeflow-dev` est renommé en place.
  Il lance `vf-dev-manager`, `vf-design-manager` sur mission design pure, et les briques directes
  (`gsd-quick`, `gsd-debug`, `gsd-execute-phase`…). `vibeflow-design` reste un pair invocable.
  Aucun changement de socle (conductor). Un head cross-métier au-dessus des cinq équipes est
  **hors périmètre** ; la référence de gouvernance (§4) est écrite pour être déplaçable vers le
  conductor si cette extension est un jour décidée.
- **D-02 — Parallélisme inter-missions : sérialiser.** Un manager à la fois ; le parallélisme reste
  dans la frontière `ready` du manager. Zéro changement au kernel ni à ADR-053. La voie
  workstreams est **l'extension désignée**, pas la voie du jour — voir §6 pour ce qu'elle exigerait.
- **D-03 — Gate de sortie : témoin machine, rejouer seulement l'absent.** Script
  `check-mission-exit.sh` à codes de sortie ; un gate CI n'est rejoué que si le rapport ne porte
  pas sa preuve (commande + exit code + SHA). Jamais l'étage entier, jamais la revue.
- **D-04 — Nom : `vibeflow-head`.** Convention des front doors (`vibeflow-conductor`,
  `vibeflow-design`, `vibeflow-validator`). « Head of minds » vit dans la description.

Hypothèses non tranchées explicitement, assumées ici (à confirmer au discuss-phase) :

- **H-01** — en conversation le head **propose** l'équipe (comportement actuel, heuristique 7) ;
  sous `vf-auto` il la **lance d'office**. ADR-031 intact.
- **H-02** — inscription comme **nouvelle phase du milestone `fiabilite-v1.0`**, séquencée après
  la 34 et avant la 25, pour que le budget d'instructions (Phase 25) se calibre sur le head final.

## 3. Les quatre compétences du head

### 3.1 Allocation — la table de proportionnalité, dans un seul sens

Graduée du moins cher au plus cher. **On escalade, on ne redescend jamais en cours de geste.**

| Travail | Mind | Condition |
|---|---|---|
| un commit, pas d'impact archi | `gsd-quick` (`gsd-quick-batch` ≥ 2 items) | trivial |
| bug / crash | recherche doc (ADR-045) **puis** `gsd-debug` | le head porte la recherche, les workers cloisonnés n'ont pas le web |
| une étape unique déjà planifiée | `gsd-execute-phase` direct | N = 1, aucun signal de durée |
| N ≥ `SEUIL_EQUIPE` ou signal de durée ou étages combinés | `Task(vf-dev-manager)` | signaux canoniques : `mission-contracts.md` §Signaux |
| mission design pure (zéro feature) | `Task(vf-design-manager)` | binaire, jamais une dominante calculée (`vf-auto` §Pilote unique) |
| projet mobile, vérification réelle | `vf-test-orchestrator` | via le manager, ou direct sous `vf-auto` |
| configuration du lab | `vibeflow-conductor` | hors dev |
| conformité du lab | `/vf-audit` (validator) | chasse gardée, ADR-057 |

Cette table **existe déjà, éparpillée** entre `intent-routing.md` et `vf-auto`. Le head ne la
recopie pas : `intent-routing.md` reste la source de la correspondance intention → brique ; le
head y ajoute la **règle d'échelle** (sens unique, seuil, signaux) dans sa référence de gouvernance.

### 3.2 Séquencement — parallélisme au niveau mission

- Le manager parallélise des **nœuds** (fichiers disjoints). Le head parallélise des **missions**
  — et sur ce repo, aujourd'hui, il **sérialise** (D-02).
- Ce qu'il fait réellement de plus : lire `Depends on:` dans `ROADMAP.md`, ordonner les missions
  restantes, **détecter** les étapes indépendantes et les **déclarer** au manager dans le brief
  (`design: auto|force|off`, périmètres disjoints connus) pour que la frontière `ready` en profite
  (pipelining N/N+1 déjà doctriné).
- **Le fan-out n'est borné par aucun nombre.** Il est borné par la disjonction des périmètres et
  par les plafonds de budget (`autonomous-guardrails.md`). Voir §7 sur le Pitfall 12.

### 3.3 Gouvernance de sortie — vérifier le témoin, pas refaire le travail

**Principe** : un vert du manager est accepté s'il est accompagné d'une **preuve machine**. Le head
rejoue **uniquement** le gate dont la preuve manque. Il ne relit jamais un diff, ne redispatche
jamais un juge sur un diff déjà PASS sans nouveau commit.

**`check-mission-exit.sh`** (à créer, `plugin/dev-orchestrator/scripts/`, résolu via la cascade
`$S` de `mission-flow.md`) — contrôles, tous déterministes et bon marché :

| # | Contrôle | Source de vérité |
|---|---|---|
| E1 | verrou de driver relâché | `driver-lock.sh status` → `present:false` |
| E2 | arbre propre (hors `.planning/*.dag.json` et lock, gitignorés) | `git status --porcelain` — mesurer en `rtk proxy`, jamais via `\| wc -l` sous rtk |
| E3 | branche dédiée ≠ défaut, PR ouverte (ADR-059) | `git branch --show-current`, `gh pr view` (repli documenté si `gh` absent) |
| E4 | STATE/ROADMAP marqués pour les étapes de la mission | case cochée dans `ROADMAP.md`, `stopped_at` de `STATE.md` |
| E5 | rapport détaillé présent sur disque | chemin porté par le rapport compact (`.planning/missions/…`) |
| E6 | preuves des gates : chaque verdict du rapport porte commande + exit code + SHA | bloc typé du rapport ; absent → **ce gate-là** est rejoué, pas les autres |

Codes de sortie, alignés sur la convention du repo : `3` = sain (seul « vérifié, conforme »),
`0` = manque(s) nommé(s), `4` = indéterminé (rien vérifié), `64` = outillage illisible. Le script
naît avec ses tests **et sa mutation rouge prouvée** (QUAL-01, leçon « une preuve doit pouvoir
rendre rouge ») — un vérificateur incapable d'échouer ne compte pas.

Conduite du head sur les codes : `3` → enchaîne ; `0` → renvoie au manager en mandat de
**clôture ciblée** (jamais corrigé par le head, P3 : un orchestrateur ne produit pas) ; `4` →
traite la mission comme non prouvée, ne l'annonce pas verte ; `64` → `human_needed`.

### 3.4 Économie — trois règles, un décompte

1. **Ne jamais relire ce que le digest porte.** Le head lit le rapport compact et le disque
   pointé, jamais l'intégralité de `.planning/` après une mission.
2. **Ne jamais rejuger sans nouveau commit.** Un `revue-N` PASS sur SHA `x` vaut tant que HEAD de
   la branche est `x`.
3. **Relayer, jamais recalculer.** `estimate`/`actuals`, `verdicts`, décompte de budget : verbatim
   (contrat déjà en vigueur dans `mission-contracts.md`). Le head tient un **décompte par
   mission** : minds dispatchés, tours consommés, gates rejoués (E6) — trois lignes au rapport,
   pas une statistique.

Bornes dures inchangées : `autonomous-guardrails.md` (plafond temps/tokens, 3 essais, anti-triche).

## 4. Ce qui change dans le module — et ce qui ne change pas

**Change** :

| Objet | Geste |
|---|---|
| `plugin/dev-orchestrator/AGENT.md` | `name: vibeflow-head`, description « head of minds », section Persona réécrite, ajout d'une section courte « Gouvernance de sortie » qui **renvoie** à la référence (ADR-030, une seule voix) — l'agent reste ≤ 250 lignes, l'ajout net est compensé par le déplacement de la table de proportionnalité |
| `plugin/dev-orchestrator/references/head-governance.md` (nouveau) | règle d'échelle (§3.1), séquencement (§3.2), contrat de sortie (§3.3), économie (§3.4) — on-demand |
| `plugin/dev-orchestrator/scripts/check-mission-exit.sh` + `tests/test-check-mission-exit.sh` | le gate de sortie (§3.3), avec mutation rouge |
| `skills/vf-dev/SKILL.md` | incarne `vibeflow-head` |
| `skills/vf-auto/SKILL.md` | l'aiguillage cite la règle d'échelle de la référence au lieu de la dupliquer |
| `agents/vf-dev-manager.md` | « Dispatché par l'agent vibeflow-head » ; rapport compact enrichi des preuves E6 (commande + exit code + SHA par verdict) |
| `module.json`, `README.md`, `CHANGELOG.md`, `VERSION` | description, bump **minor** (nouvelle capacité) |
| `plugin/conductor/scripts/check-overlaps.sh` + son test | ligne `vibeflow-dev|gsd-next` → `vibeflow-head` |
| `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | cible d'incarnation `vibeflow-head` ; **nouveau test : aucun alias `vibeflow-dev` ne survit dans `plugin/`** (hors CHANGELOG) |
| Références citant `vibeflow-dev` | `GSD-PIPELINE.md`, `_index.md`, `docs-flow.md`, `ingestion-flow.md`, `intent-routing.md`, `mission-contracts.md`, `discover-unintegrated-docs.sh`, `design-orchestrator/AGENT.md`, `planning-core/SKILL.md`, `commands/vf-planning.md`, `software-architecture/rules/doc-research-before-debug.md` |
| Racine | `README.md`, `README.fr.md`, `docs/ADR.md` (mention), release taggée (règle non négociable du CLAUDE.md) |

**Ne change pas** : `team-kernel.md`, `driver-lock.sh`, `dag.sh`, `guard-driver-lock.sh`, ADR-053,
Pattern A (un seul manager), P3 (un orchestrateur ne produit pas), P12 (cloisonnement),
`SEUIL_EQUIPE`, la carte d'intention comme source unique de correspondance.

Surface mesurée le 2026-09-15 : **20 fichiers** dans `plugin/` citent `vibeflow-dev` hors
CHANGELOG, plus 2 README et 6 specs historiques sous `docs/superpowers/specs/` (celles-ci ne se
réécrivent pas : ce sont des archives datées).

## 5. Contraintes qui bornent la forme

- **ADR-029 / Phase 25** : 205 → ≤ 250 lignes ; les compétences vont dans la référence et le
  script, pas dans le prompt. Le budget d'instructions se calibrera sur le corpus post-head (H-02).
- **ADR-057** : une seule front door. Le head **remplace** `vibeflow-dev`, il ne s'y ajoute pas ;
  `gsd-next` reste non routé.
- **ADR-044** : `check-agents.sh --strict` passe (description + model + memory ; `vf-internal`
  non concerné, le head est une front door).
- **ADR-031** : le head ne corrige rien lui-même à la sortie d'un manager (mandat de clôture
  ciblée au manager, ou `human_needed`).
- **Zéro agent neuf** : renommage + extension. La Phase 34 (D-03) reste respectée par construction.
- **Traçabilité** : tout commit qui invoque un arbitrage nomme « arbitrage Samuel, AskUserQuestion
  session principale, 2026-09-15 ».

## 6. La voie workstreams — pourquoi elle n'est pas la voie du jour

Question posée au cadrage : « il me semblait qu'on avait mis en place des workstreams pour ça ? »
Réponse sur pièces (`39-CONTEXT.md`, ADR-069, `workstreams.md`, `driver-lock.sh`) :

- La Phase 39 a rendu le planning partitionnable pour que **plusieurs sessions et plusieurs
  humains** travaillent en parallèle sur des feuilles de route disjointes. La preuve est une
  preuve **de mécanisme sur clone jetable**, jamais d'usage concurrent réel (D-03 de la 39).
- **`vibeflow-os` n'est pas partitionné** : la partition réelle est un geste séparé, gaté humain,
  postérieur à la clôture de la 39 (D-02 de la 39), et la condition dure d'ADR-069 interdit toute
  partition tant qu'une phase est en vol.
- Le **verrou de driver est unique et relatif au checkout** (`.planning/DRIVER.lock`, gitignoré) :
  il ne connaît pas les compartiments. Deux managers dans deux worktrees auraient chacun leur
  lock **par accident**, sans que l'invariant « un seul manager » soit ni tenu ni consciemment
  levé. Dans une même session, tous les sous-agents partagent le pointeur de workstream (D-10 de
  la 39) — le remède `--ws` explicite + `GSD_SESSION_KEY` par mandat est câblé pour les workers,
  pas pour des managers.

Ce que la voie exigerait, le jour où un lab est réellement partitionné : (1) `driver-lock.sh`
compartiment-aware (lock nommé par workstream) avec amendement daté d'ADR-053 : l'invariant devient
« un manager **par compartiment** » ; (2) `guard-driver-lock.sh` aligné ; (3) le head passe `--ws`
et un `GSD_SESSION_KEY` distinct **par manager** ; (4) une preuve d'usage concurrent réel, pas sur
clone. C'est une phase à part entière, avec son déclencheur : **partition effective d'un lab**.
D'ici là, le head sérialise (D-02) — et le gain de parallélisme réel reste celui de la frontière
`ready` du manager, seul étage mesuré effectif (`team-kernel.md` §Étage de parallélisme).

## 7. Le Pitfall 12 et la phrase « plus de 2-3 agents d'un coup »

Question posée au cadrage : cette phrase est-elle vraie ? En pratique bien plus de 3 agents se
lancent et se gèrent très bien.

Lecture sur pièces (`.planning/research/PITFALLS.md` §Pitfall 12, `34-CONTEXT.md` D-03) : la
phrase est un **warning sign de catalogue**, pas de runtime. Son verbatim : « *Une PR ajoutant
plus de 2-3 agents d'un coup* ». Elle vise l'**ajout de fichiers d'agents au plugin** par import
en masse depuis `agency-agents` — le risque nommé est la couche de synonymes enterrée en v2.33.0
et l'explosion des gates ADR-029/044/`check-overlaps`. Elle ne dit **rien** du nombre d'agents
**dispatchés en parallèle** à l'exécution.

Sur le fan-out runtime, la doctrine du repo dit exactement l'inverse d'une limite : dispatch
parallèle **par défaut** dès que les périmètres sont disjoints (`team-kernel.md` §Règles
d'instanciation), mesuré à 92 % de recouvrement depuis un sous-agent, revue ∥ audit ∥ critique en
un seul message, chercheurs `gsd-*` par quatre. **Aucun plafond numérique n'existe** dans
`mission-flow.md` ni `team-kernel.md` (vérifié par grep le 2026-09-15). Les seules bornes sont la
disjonction des périmètres et les plafonds de budget.

**Verdict** : la phrase est **vraie pour ce qu'elle dit** (catalogue) et **ne contredit pas** la
pratique (runtime). Le risque réel est sa **lisibilité** : sortie de son contexte, dans D-03 de la
34, « plus de 2-3 agents d'un coup » se lit comme une limite d'orchestration. Recommandation, sans
rouvrir la décision verrouillée : le livrable AGTS-01 de la Phase 34 écrit la phrase **complète** —
« plus de 2-3 agents **ajoutés au catalogue** dans une PR » — et nomme explicitement que le fan-out
d'exécution n'est borné que par la disjonction des périmètres et le budget. La référence
`head-governance.md` porte la même phrase côté runtime (§3.2). C'est une précision de rédaction,
dans la marge « Claude's Discretion » de la 34, pas une révision de D-03.

## 8. Next step

Inscrire la phase (`gsd-phase` — attention, `phase.add` propose un mauvais numéro sur ce dépôt,
vérifier le prochain numéro libre à la main), puis `gsd-discuss-phase` avec cette note en entrée
pour confirmer H-01/H-02 et trancher ce qui reste (forme exacte du bloc de preuves E6 dans le
rapport compact ; repli de E3 sans `gh`).
