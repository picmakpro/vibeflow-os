# Phase 24 — Inventaire des collisions « GSD-first »

**Établi le :** 2026-08-04 · **Par :** `vf-coder` (mandat plan seul)
**Origine :** doctrine posée par Samuel **après** l'arbitrage des 6 zones —
« *je veux coller au max à ce que fait GSD, je préfère jeter des IronLaw outdated que de sacrifier
l'efficience* ».

> ## ⛔ STATUT DE CE DOCUMENT
>
> **Chaque entrée est une PROPOSITION. Aucune n'est appliquée.** La seule exception est la
> **collision C-1** (Iron Law 2), dont Samuel a **déjà explicitement autorisé la révision effective**
> dans le verdict de la zone 5 — elle est portée en tâche du plan `24-10`.
>
> Les collisions C-2 à C-6 attendent un **arbitrage humain**. Elles n'ont **rien changé** aux
> verdicts en vigueur : les 12 plans de la phase exécutent les verdicts **tels qu'arbitrés le
> 2026-08-04**, pas les propositions ci-dessous.
>
> **ADR-031 (jamais de fix sans validation humaine) et la release racine gatée restent en vigueur —
> la doctrine GSD-first ne les lève pas.**

## Règle de lecture

La doctrine GSD-first déclasse un motif de décision précis : **« c'est conforme à une décision
interne »**. Elle ne déclasse **pas** les motifs factuels (« il n'y a pas de consommateur »,
« la mesure dit non », « le canal n'existe pas »). Une collision n'est donc inventoriée ici que si le
refus repose, **en tout ou partie**, sur de la conformité interne plutôt que sur un fait mesuré.

| # | Loi / ADR | Usage GSD contrarié | Fondé sur | Proposition |
|---|---|---|---|---|
| **C-1** | Iron Law 2 — `plugin/conductor/AGENT.md:114` | Adoption des workstreams | conformité interne | **RÉVISER** — ✅ autorisé par Samuel |
| **C-2** | Phase 23 — allowlist de `vf-coder` | Slot `AGENT_SKILLS_EXECUTOR` | conformité interne | **MAINTENIR** — mais la mesure invalide le gain |
| **C-3** | `CLAUDE.md` — vocabulaire de commit | `hooks.community` (capability native) | conformité interne | **MAINTENIR**, motif requalifié |
| **C-4** | ADR-057 « une capacité, une seule voix » | `graphify`, `profile-pipeline` (natives) | **fait mesuré** | **MAINTENIR** — hors doctrine, tracé pour relisibilité |
| **C-5** | Pattern C — contrat typé par rôle | `context_profile` (natif) | **fait mesuré** | **MAINTENIR** — collision apparente seulement |
| **C-6** | ADR-064 « un écrivain = un worktree » | Pointeur de session des workstreams | **fait mesuré** | **AMENDER** — voie de composition trouvée |

---

## C-1 — Iron Law 2 contre l'adoption des workstreams

**Loi.** `plugin/conductor/AGENT.md:114` — « **Router, jamais réimplémenter.** »
(Les 4 Iron Laws occupent les lignes 113-116 ; c'est la 2ᵉ.)

**Usage GSD contrarié.** L'adoption des workstreams (verdict zone 5, option C) oblige le lab à
**réimplémenter** la résolution du workstream actif dans sa propre couche : trois gates bash
(`check-dev-bootstrap.sh:111`, `check-state-integrity.sh:53`,
`plugin/planning-core/scripts/planning-context.sh`) doivent apprendre à résoudre
`.planning/workstreams/<ws>/` au lieu de lire `.planning/ROADMAP.md` et `.planning/STATE.md` en dur —
c'est-à-dire re-coder localement une logique que `active-workstream-store.cjs` porte déjà en amont.
La lettre de la loi l'interdit.

**Coût de chaque branche.**

| Branche | Coût |
|---|---|
| **Maintenir la loi telle quelle** | L'adoption devient indéfendable *par construction* — le verdict zone 5 est inapplicable. Le lab reste à ADR-064 seul, et les 22 exigences perdent 8 de leurs membres (GSDA-12 → GSDA-19). |
| **Réviser la loi** | Il faut border la révision pour qu'elle n'autorise pas *n'importe quelle* réimplémentation : sans bornage, la loi cesse de protéger contre le fork des skills GSD (« Out of Scope » de `REQUIREMENTS.md`). Coût rédactionnel, pas d'exécution. |

**Proposition — RÉVISER, avec bornage.** La loi visait le **fork d'une capacité** (réécrire ce que
le moteur fait) ; elle n'a jamais visé l'**adaptation d'un gate local à une capacité amont**. La
révision doit préserver le premier interdit tout en autorisant le second. Formulation à arbitrer dans
`24-10` — la trace de la formulation antérieure est conservée.

**Statut : ✅ RÉVISION AUTORISÉE PAR SAMUEL** (verdict zone 5, point 1 : « soit on la révise, soit on
écrit pourquoi elle ne s'applique pas — ne pas la contourner en silence »). Portée par `24-10`,
tâche 1. **Seule entrée de cet inventaire dont la révision effective est déjà validée.**

---

## C-2 — L'allowlist fermée en Phase 23 contre le slot `AGENT_SKILLS_EXECUTOR`

> **Collision nommée par Samuel lui-même** dans le mandat : « le slot `EXECUTOR` a été écarté
> **principalement pour ne pas rouvrir l'allowlist fermée en Phase 23**. C'est exactement le
> raisonnement “conformité à une décision interne” que la doctrine GSD-first déclasse. »

**Décision interne concernée.** Phase 23 — retrait de `gsd-executor` et `gsd-planner` de l'allowlist
`tools:` de `vf-coder`.

**Usage GSD contrarié.** `buildAgentSkillsBlock` (`init.cjs:1731-1815`) expose **17 slots** dont
`AGENT_SKILLS_EXECUTOR`, consommés par **30 workflows** en 1.9.1. Le verdict zone 1 (option A) ne
peuple que `AGENT_SKILLS_PLANNER` : la doctrine de dev du lab atteint le **plan**, jamais
l'**exécution**.

**Instruction demandée par le mandat — que coûterait vraiment la réouverture, et le canal est-il
atteignable ?**

Réponse, en deux temps :

1. **Le coût de la réouverture est modéré** : rajouter `gsd-executor` à la ligne `tools:` de
   `vf-coder.md`, plus l'assertion de suite correspondante. Ce n'est pas un chantier.
2. **Mais le canal est un vert à vide sur notre chemin réel.** C'est le point décisif, et il est
   **factuel, pas doctrinal** : l'injection du slot `EXECUTOR` **ne vit que dans le prompt de
   dispatch** d'`execute-phase.md:86,715`. Notre chemin d'exécution ne passe pas par ce dispatch —
   il tombe sur le **repli inline séquentiel** (`execute-phase.md:28-31`), **qui n'injecte rien**.
   Rouvrir l'allowlist rendrait le dispatch *possible*, mais ne garantit pas qu'il soit *emprunté* :
   on paierait la réouverture pour un canal dont rien ne prouve qu'il se remplit.

**Coût de chaque branche.**

| Branche | Coût |
|---|---|
| **Maintenir (verdict A)** | La doctrine n'atteint jamais l'exécuteur. Assumé et **écrit tel quel** (`GSDA-02`). |
| **Rouvrir (option B)** | Faible coût d'écriture ; **gain non prouvé** ; il faudrait d'abord établir par mesure que le dispatch d'`execute-phase.md:86,715` est réellement emprunté depuis `vf-coder`. |

**Proposition — MAINTENIR le verdict A**, mais pour un **motif requalifié** : ce n'est plus « on ne
rouvre pas une décision de la Phase 23 » (motif de conformité interne, que la doctrine déclasse) —
c'est « **le canal n'est pas prouvé atteignable sur notre chemin d'exécution réel** » (motif
factuel, que la doctrine ne déclasse pas). Le verdict ne change pas ; **sa justification, si**.

**Ouverture proposée à Samuel :** faire de la mesure « le dispatch d'`execute-phase.md:86,715`
est-il emprunté depuis `vf-coder` ? » un **déclencheur de réexamen objectif** — si la mesure dit oui,
C-2 se rouvre sur un gain démontré, et la réouverture d'allowlist devient un coût qui achète quelque
chose. **Non planifié dans cette phase.**

**Statut : PROPOSÉE — le verdict A reste en vigueur. Aucune application.**

---

## C-3 — Le vocabulaire de commit du lab contre `hooks.community`

**Décision interne concernée.** `CLAUDE.md` — « **Commits** : messages en français, cohérents avec
l'historique du repo », et les six types maison qui en découlent.

**Usage GSD contrarié.** `hooks.community` est une **capability native** du moteur (Conventional
Commits bloquants). Le hook est **déjà posé** en `PreToolUse` dans `~/.claude/settings.json` et
s'auto-gate sur le config (`gsd-validate-commit.sh:12-17`) : **l'activer coûte une clé**, aucune
édition de `settings.json`.

**Mesure (verdict zone 2, `GSDA-06`).** Sur **109 commits locaux** :
- **23 échouent sur le type** — six types maison absents de la liste amont : `release:`, `planning:`,
  `doctrine:`, `bump(…)`, `spec(…)`, `plan(…)` ;
- **76/109 = 69 %** des sujets dépassent **72 caractères**.

*(Note de traçabilité : le commit des plans de cette phase, `b0680f4`, porte `planning(24):` — l'un
des six types maison. La collision n'est pas théorique, elle se manifeste dans la phase qui
l'inventorie.)*

**Coût de chaque branche.**

| Branche | Coût |
|---|---|
| **Maintenir le refus (verdict C)** | La conformité aux Conventional Commits reste une **consigne humaine**, jamais une garantie machine — et il faut l'écrire, car **aucun gate machine de message de commit n'existe** dans ce dépôt (les 6 `plugin/*/hooks/hooks.json` n'en déclarent aucun ; `scripts/hooks/pre-push` est le gate de tag). |
| **Réaligner le style (option D, la branche GSD-first)** | Abandon des 6 types maison + réécriture de la convention du `CLAUDE.md` + discipline des sujets ≤ 72 car. Coût **récurrent et quotidien**, sur 69 % des messages. |

**Proposition — MAINTENIR le refus, motif requalifié.** L'argument le plus solide n'est pas « on
tient à notre vocabulaire » (conformité interne, déclassée) mais un **fait de conception de
garde-fou** : *un gate qu'on doit contourner tous les jours est un gate qu'on finit par désarmer* —
et un gate désarmé est pire qu'un gate absent, parce qu'il ment sur la garantie qu'il offre. C'est le
même raisonnement qui a fait retenir la dérogation tracée plutôt que le contournement en zone 2.

**Réserve honnête à porter devant Samuel :** l'option D reste la branche *littéralement* GSD-first, et
elle n'a **pas** été chiffrée en coût d'adaptation (combien de temps pour que 6 types disparaissent
des habitudes ?). Le refus est défendable ; il n'est pas démontré optimal.

**Statut : PROPOSÉE — le verdict C reste en vigueur (refus par ADR, porté par `24-02`).**

---

## C-4 — `graphify` et `profile-pipeline` : deux capabilities natives refusées

**Usage GSD contrarié.** Deux capabilities **natives** du moteur, refusées (verdict zone 3, option A),
leurs entrées de routage (`intent-routing.md:104` → `gsd-graphify`, `:147` → `gsd-profile-user`)
marquées **conditionnelles**.

**Instruction — le motif est-il de la conformité interne ?** **Non.** Le motif retenu est
**factuel** : *aucun consommateur prescrit dans le module*, et ni l'une ni l'autre n'a atteint
`gsd-capabilities-index.md` (111 l., Phase 23), qui liste pourtant `intel`, `tdd` et
`broken-windows`. Les activer créerait **de l'artefact sans lecteur** — un coût sans contrepartie,
que la doctrine GSD-first ne demande pas de payer (elle privilégie l'usage **réel**, pas
l'exhaustivité des capacités posées).

**Pourquoi cette entrée figure quand même ici.** Le mandat le demande explicitement : « la collision
mérite d'être tracée pour que le refus soit relisible ». Refuser une capability native est un geste
qui doit pouvoir se relire dans six mois **avec son motif**, sinon il se re-débat.

**Proposition — MAINTENIR**, et **rendre le refus lisible par la machine** : c'est précisément ce que
fait `GSDA-08` (les deux capabilities portées dans `gsd-capabilities-index.md` **avec leur état**) et
`GSDA-09` (le gate d'activation doc ↔ capability). Sans cet index, le refus serait invisible et le
trou se rouvrirait au prochain skill ajouté.

**Statut : TRACÉE, hors doctrine — le verdict A reste en vigueur, sans réserve.**

---

## C-5 — Pattern C (contrat typé par rôle) contre `context_profile`

**Décision interne concernée.** Pattern C — contrat typé **par rôle**, 4 rôles, schéma JSON
(`mission-flow.md:136-152`).

**Usage GSD contrarié — en apparence.** Le moteur documente 3 profils de contexte ; le lab les refuse
(verdict zone 4, option A).

**Pourquoi la collision est apparente et non réelle.** Deux faits mesurés la dissolvent :
1. **Il n'y a rien à adopter.** La clé porteuse de la sémantique est **`context_profile`**, avec
   **6 occurrences amont, toutes dans `docs/`**. **Aucun consommateur n'existe.** Le moteur ne
   *porte* pas ce réglage, il le *déclare*. On ne peut pas « coller à l'usage réel de GSD » quand
   l'usage réel est **nul**.
2. **La forme est incompatible** : profil = **scalaire global** (une valeur pour tout le projet) ;
   Pattern C = **contrat par rôle**. Ce n'est pas une préférence, c'est une différence d'arité.
   *(Contraste utile : `agent_skills`, lui, **est** une map par agent — et il est adopté, zone 1.)*
3. Si le canal s'implémentait un jour, `research.md:20-23` (« Verbosity **High** … Include background
   context even if the developer likely knows it ») entrerait en **collision frontale** avec
   `mission-flow.md:139-142` (« la prose libre est du volume mort »).

**Proposition — MAINTENIR**, avec la **rédaction imposée** par le verdict et **aucun écart** :
la clé est **`context_profile`** (jamais `context:`) ; l'état est « **documentée, livrée, jamais
câblée, abandonnée de fait depuis avril 2026** » ; le mot « **dépréciée** » **n'apparaît nulle part**
(l'amont ne l'a jamais dit — l'ADR serait factuellement faux) ; le déclencheur de réexamen est
**objectif, pas une date** : rouvrir **ssi** `context_profile` apparaît **hors de `docs/`** dans une
release amont, **ou** qu'une issue amont le mentionne.

**Statut : TRACÉE, collision apparente — le verdict A reste en vigueur, sans réserve.**

---

## C-6 — ADR-064 contre le pointeur de session des workstreams

**Décision interne concernée.** **ADR-064** — « un écrivain = un worktree » (quick `260801-17w`,
tranché le 2026-08-01).

**Usage GSD contrarié.** L'adoption des workstreams (verdict zone 5) suppose un pointeur de
workstream actif. L'arbitrage l'a inventorié en **risque (c)** : le pointeur vit dans
`os.tmpdir()/gsd-workstream-sessions/<sha1(realpath(.planning)) tronqué 16>/<clé>` — **effacé au
reboot, indexé sur le chemin absolu, donc distinct par worktree et jamais hérité** — et conclut à la
**non-composabilité** avec ADR-064.

**Fait nouveau mesuré le 2026-08-04 (`24-RESEARCH.md` R-2b/R-2c) — la collision est RÉELLE mais
CONTOURNABLE.** L'inventaire de risques de l'arbitrage était **incomplet** :

1. La résolution du workstream actif a **trois niveaux court-circuitants**
   (`resolveActiveWorkstream`, `active-workstream-store.cjs:252-277`) :
   **`--ws` (CLI) > `GSD_WORKSTREAM` (env) > pointeur de session**.
   Le pointeur n'est atteint qu'**en dernier recours**.
2. Il existe **deux** adaptateurs de pointeur, pas un (`pickActiveWorkstreamAdapter:170-185`) : le
   **session-scoped** (`tmpdir`) **et** un **shared** (`:110-127`) qui écrit
   **`<cwd>/.planning/active-workstream`**, dans le dépôt — donc naturellement par worktree.
3. **Mais** `getWorkstreamSessionKey()` (`:78-86`) balaie 9 clés d'environnement, dont
   **`CLAUDE_CODE_SSE_PORT`** — **mesurée PRÉSENTE dans ce runtime**. Sous Claude Code, c'est donc
   bien l'adaptateur **`tmpdir`** qui est retenu : **le risque (c) est CONFIRMÉ pour notre runtime**,
   il n'est pas générique.

**Conséquence.** `GSD_WORKSTREAM` est un **canal de premier rang, indépendant du pointeur**. Un
worktree qui l'exporte résout son workstream **sans jamais toucher au fichier de `os.tmpdir()`** —
la non-composabilité tombe. C'est la voie de mitigation **la moins coûteuse**, et elle **n'existait
pas** dans l'inventaire de risques de l'arbitrage.

**Proposition — AMENDER ADR-064**, sans le contredire : ajouter que, sur un arbre partitionné en
workstreams, l'isolation « un écrivain = un worktree » se **compose** avec les workstreams via
l'export de `GSD_WORKSTREAM` par worktree, et **jamais** via le pointeur de session (qui, sous Claude
Code, est indexé sur un chemin absolu et n'est pas hérité). Le principe d'ADR-064 est **préservé** ;
seule sa **mécanique de composition** est précisée.

**Ce que les plans en font déjà** (sans attendre l'arbitrage, parce que cela relève de l'exécution du
verdict d'adoption, pas d'une révision de loi) : `GSDA-15` câble `--ws` dans les agents `vf-*`,
`GSDA-16` pose un gate qui **échoue bruyamment** au lieu de laisser une session ouvrir sans
workstream résolu — la défaillance visée est mesurée : `getActiveWorkstream` (`:186-201`)
**auto-nettoie en silence** (nom invalide **ou** `.planning/workstreams/<nom>/` inexistant →
`adapter.clear()` puis `null`).

**Statut : PROPOSÉE (amendement d'ADR-064) — non appliquée. ADR-064 reste en vigueur tel quel.**

---

## Tension hors-collision — la parallélisation

**Le mandat la signale comme pouvant diverger, et elle diverge.**

M2 (mesure du 2026-07-31) a établi deux faits :
- **GSD aplatit ses dispatches** ;
- le parallélisme **inter-nœuds**, porté par `vf-dev-manager`, est le **seul effectif** sur ce runtime.

« Coller au max à GSD » et « ne pas sacrifier l'efficience » **pointent ici dans des directions
opposées** : le seul étage de parallélisme qui fonctionne est **le nôtre**, pas celui du moteur — et
c'est aussi **celui que la partition en workstreams fragilise le plus**.

**Ce n'est pas une collision avec une loi** (aucun ADR ni Iron Law n'est contrarié), donc pas d'entrée
`C-N`. C'est une **tension de doctrine**, et le mandat est explicite : « si tu vois une tension,
inventorie-la, **ne la tranche pas** ».

**Élément de décision que le plan apporte quand même :** le découpage en **12 plans sur 4 vagues avec
périmètres de fichiers disjoints** (0 collision de fichier vérifiée dans chacune des 4 vagues) est
précisément ce qui alimente le parallélisme inter-nœuds de `vf-dev-manager`. La phase **exerce** donc
l'étage qui marche, sans rien préjuger de l'arbitrage.

**Statut : TENSION SIGNALÉE — non tranchée, portée au prochain checkpoint humain.**

---

## Ce que cet inventaire ne contient pas

- **Aucune application.** Une seule révision est autorisée (C-1) et elle est portée par `24-10`.
- **Aucune révision d'ADR-031** ni de la **release racine gatée** — la doctrine GSD-first ne les lève
  pas (contrainte explicite du mandat).
- **Aucun verdict modifié.** Les 12 plans exécutent les 6 verdicts **tels qu'arbitrés le 2026-08-04**.
- **Aucune phase ajoutée** au ROADMAP (« PAS DE PHASE 27 »).

## Références

`24-ARBITRAGES.md` (verdicts) · `24-RESEARCH.md` (R-1, R-2) · `24-CONTEXT.md` (F-01→F-38) ·
`.planning/REQUIREMENTS.md` § Hors-milestone Phase 24 (GSDA-01→22) ·
`plugin/conductor/AGENT.md:113-116` · `docs/ADR.md` (ADR-057, ADR-064, ADR-031) ·
`.planning/missions/2026-07-31-mesure-m2-dispatch-parallele.md` ·
`.planning/missions/2026-08-04-phase-24-activation-moteur-gsd.md`
