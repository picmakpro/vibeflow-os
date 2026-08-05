# Phase 24 — Inventaire des collisions « GSD-first »

**Établi le :** 2026-08-04 · **Par :** `vf-coder` (mandat plan seul)
**Origine :** doctrine posée par Samuel **après** l'arbitrage des 6 zones —
« *je veux coller au max à ce que fait GSD, je préfère jeter des IronLaw outdated que de sacrifier
l'efficience* ».

> ## ⛔ STATUT DE CE DOCUMENT
>
> **Chaque entrée est une PROPOSITION, sauf deux.** Les **deux révisions doctrinales** que Samuel a
> explicitement autorisées dans le verdict de la zone 5 ont été **APPLIQUÉES le 2026-08-04** et sont
> actées par **ADR-069** :
>
> - **C-1** — Iron Law 2 révisée dans `plugin/conductor/AGENT.md` (item 2, formulation antérieure
>   conservée en trace sous le bloc des lois), appliquée par le plan `24-10`, tâche 1 ;
> - **C-6** — **amendement d'ADR-064** (`GSD_WORKSTREAM` écrit comme **canal nominal**), porté par
>   **ADR-069 § « L'amendement d'ADR-064 — `GSD_WORKSTREAM` est le canal nominal »**. Statut mis à
>   jour le **2026-08-04** par un mandat de correction ciblée : le mandat de `24-10` bornait ce
>   document au statut de C-1, ce qui avait laissé C-6 en « PROPOSÉE » alors que l'amendement était
>   déjà gravé.
>
> Les collisions C-2 à C-5 attendent un **arbitrage humain**. Elles n'ont **rien changé** aux
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
| **C-1** | Iron Law 2 — `plugin/conductor/AGENT.md:115` | Adoption des workstreams | conformité interne | **RÉVISÉE — ✅ APPLIQUÉE le 2026-08-04** (ADR-069) |
| **C-2** | Phase 23 — allowlist de `vf-coder` | Slot `AGENT_SKILLS_EXECUTOR` | conformité interne | **MAINTENIR** — mais la mesure invalide le gain |
| **C-3** | `CLAUDE.md` — vocabulaire de commit | `hooks.community` (capability native) | conformité interne | **MAINTENIR**, motif requalifié |
| **C-4** | ADR-057 « une capacité, une seule voix » | `graphify`, `profile-pipeline` (natives) | **fait mesuré** | **MAINTENIR** — hors doctrine, tracé pour relisibilité |
| **C-5** | Pattern C — contrat typé par rôle | `context_profile` (natif) | **fait mesuré** | **MAINTENIR** — collision apparente seulement |
| **C-6** | ADR-064 « un écrivain = un worktree » | Pointeur de session des workstreams | **fait mesuré** | **AMENDÉE — ✅ APPLIQUÉE le 2026-08-04** (ADR-069) |

---

## C-1 — Iron Law 2 contre l'adoption des workstreams

**Loi.** `plugin/conductor/AGENT.md:115` — « **Router, jamais réimplémenter.** » (formulation
antérieure ; la ligne porte aujourd'hui la formulation révisée, cf. Statut plus bas).
(Les 4 Iron Laws occupent les lignes **114-117** ; c'est la 2ᵉ, donc la **115**. Ancres re-vérifiées
le 2026-08-04 : les précédentes — `:114` pour la loi, `113-116` pour le bloc — étaient décalées d'une
ligne et pointaient sur l'**Iron Law 1**.)

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

**Statut : ✅ RÉVISION APPLIQUÉE le 2026-08-04** par `24-10`, tâche 1 (autorisation : verdict zone 5,
point 1 — « soit on la révise, soit on écrit pourquoi elle ne s'applique pas — ne pas la contourner
en silence »). **Première des DEUX entrées appliquées de cet inventaire** — l'autre est **C-6**
(amendement d'ADR-064), appliquée le même jour. Toutes les autres restent des PROPOSITIONS.
*(Correction du 2026-08-04, nœud 24-13 : ce paragraphe portait « seule entrée … et la seule
appliquée », en contradiction directe avec l'encadré d'ouverture « sauf deux » et avec le statut de
C-6 plus bas. C'était le compte de C-1 seul, écrit avant que C-6 ne soit appliquée.)*

**Ce qui a été écrit.** L'item 2 du bloc `## Iron Laws` de `plugin/conductor/AGENT.md` devient
« **Router, jamais forker — une capacité amont partiellement couverte se câble en écrivant ses
limites, elle ne se réimplémente pas** (ADR-069) ». Le bornage proposé ci-dessus est tenu : le fork
d'une capacité amont reste interdit, seule l'**adaptation d'un gate local** est autorisée, et elle
l'est **sous condition écrite** — les limites de la capacité doivent être consignées, ce que fait
ADR-069 § « Les quatre risques mesurés ». La formulation antérieure est **conservée en trace** sous
le bloc des lois, avec sa date de révision et le renvoi à ce document. Items 1, 3, 4 et le bloc
`## Garde-fous` prouvés bit-à-bit inchangés.

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

**Fait nouveau mesuré le 2026-08-04 (`24-RESEARCH.md` R-2b/R-2c) — la collision est RÉELLE, et elle
se COMPOSE par le canal nominal.** L'inventaire de risques de l'arbitrage était **incomplet** :

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
la non-composabilité tombe. C'est la voie **la moins coûteuse**, et elle **n'existait pas** dans
l'inventaire de risques de l'arbitrage.

*(Vocabulaire rectifié le 2026-08-04, nœud 24-13.* Ce paragraphe et le précédent qualifiaient
`GSD_WORKSTREAM` de « **contournement** » et de « **voie de mitigation** » — contre leur propre
conclusion, reprise telle quelle par ADR-069 : c'est le **canal NOMINAL**, niveau 2 de la résolution
amont, et non un détour autour d'un défaut. La nuance n'est pas cosmétique : un contournement se
tolère et se retire au premier refactoring, un canal nominal se **borne** et se **teste** — c'est
d'ailleurs ce qui a fait découvrir qu'il n'avait, lui, aucune borne de longueur.*)

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

**Statut : ✅ AMENDEMENT APPLIQUÉ le 2026-08-04** — 2ᵉ des deux révisions doctrinales autorisées par
le verdict de la zone 5, et **seule autre entrée appliquée** avec C-1. ADR-064 **reste en vigueur,
principe intact** : l'amendement ne le contredit pas, il en précise la mécanique de composition.

**Ce qui a été écrit.** `docs/ADR.md` § **ADR-069 → « L'amendement d'ADR-064 — `GSD_WORKSTREAM` est
le canal nominal »** grave la proposition ci-dessus : sur un arbre partitionné, l'isolation « un
écrivain = un worktree » se compose avec les workstreams **via l'export de `GSD_WORKSTREAM` par
worktree**, jamais via le pointeur de session. `GSD_WORKSTREAM` y est qualifié de **canal nominal**
(niveau 2 de la résolution amont), et non de contournement. L'en-tête d'ADR-069 porte ADR-064 comme
voisine « **amendée par cette entrée** », et ADR-064 porte le renvoi retour vers ADR-069.

---

## M-1 — Mesure datée de la couverture amont des workstreams

**Mesurée le 2026-08-04**, à inscrire telle quelle dans ADR-069 (plan 24-10). Elle remplace tout
chiffre de couverture cité sans sa méthode.

### Corpus (exact, vérifiable)

`$HOME/.claude/gsd-core/workflows/*.md`, **profondeur 1 uniquement** — `@opengsd/gsd-core` **1.9.1**.
**91 fichiers.** Le qualificatif « racine » porte : en récursif le même dossier en compte 115. Le
compte 91 a été confirmé par **six** méthodes indépendantes (`find|awk`, `find -exec`, glob shell,
`ls`, `find`>fichier, `find|sort`>fichier) après qu'une invocation a rendu **4** en silence — un
compteur d'atteinte (`91 fichiers réellement ouverts`) est donc inclus dans la commande.

### Le critère d'inclusion, nommé — c'est lui, et lui seul, qui explique l'écart 7 vs 5

Un workflow est dit **conscient** selon l'une de ces trois définitions, qui ne sont pas
interchangeables. Aucune des mesures antérieures ne nommait la sienne :

| # | Critère d'inclusion | Conscients | Taux | En dur | Aveugles |
|---|---|---|---|---|---|
| **K1** | le mot `workstream` (insensible à la casse) **seul** | **5** | 5,5 % | 45 | **43** |
| **K2** | le mot `workstream` **ou** l'option `--ws` — *« résout le scope »* | **7** | **7,7 %** | 45 | **42** |
| **K3** | K2 **ou** la variable `GSD_WS` — *toute forme de surface* | **16** | 17,6 % | 45 | **35** |

### Ce que la re-dérivation établit

- **Les deux chiffres en litige sont reproductibles.** L'arbitrage citait 7/91 (45 en dur, 42
  aveugles) : c'est **exactement K2**, retrouvé au fichier près. La re-mesure indépendante citait
  5/91 (45 en dur, 43 aveugles) : c'est **exactement K1**. Aucune n'était fausse ; aucune ne nommait
  son critère. Il n'y a donc **pas** de mesure à corriger, mais un critère à écrire.
- **K1 sous-compte par faux négatifs.** Les 2 workflows que K2 ajoute — `verify-work.md` et
  `plan-review-convergence.md` — traitent bien `--ws` (`verify-work.md:42-43` le parse dans `GSD_WS`)
  **sans jamais écrire le mot** « workstream ». Un critère purement lexical les rate.
- **K3 contient un faux positif isolé et nommé** : `reapply-patches.md:220` ne cite `${GSD_WS}` que
  comme *exemple de dérive de variable* dans une doc de rapprochement de patchs. Il n'est
  workstream-aware en rien. K3 vaut donc **16 bruts / 15 réels**.
- **K3 sépare deux natures que K2 confond.** Sur ses 16, **7 résolvent** le scope et **9 ne font que
  propager** `${GSD_WS}` dans une commande suggérée (`ship.md` : 1 seule ligne ; `progress.md` : 29).
  Propager n'est pas résoudre — mais ce n'est pas non plus être aveugle.

### La correction qui compte pour ADR-069

La fiche **F-34 déclare « PÉRIMÉ — la couverture est BIEN PIRE que 18 % »**. **Cette conclusion ne
survit pas à la re-dérivation.** Le taux ~18 % du ROADMAP est **retrouvé** par K3 (17,6 %). L'écart
18 % → 7,7 % n'est donc **pas** une régression amont ni une découverte d'un état pire : c'est un
**changement de critère non déclaré**. Écrire « bien pire que 18 % » dans une ADR serait graver un
artefact de méthode comme un fait sur le produit.

**À graver : 7/91 = 7,7 % (critère K2), 45 en dur dont 42 aveugles, mesuré le 2026-08-04 sur
gsd-core 1.9.1.** K2 est retenu parce que c'est le critère qui répond à la question de l'ADR — *ce
workflow sait-il résoudre un scope de workstream ?* — et non *le mot apparaît-il ?* (K1) ni *la
variable transite-t-elle ?* (K3). Les trois chiffres restent publiés ci-dessus : c'est le tableau,
pas le seul nombre retenu, qui rend la mesure rejouable.

### Commande reproductible (à recopier dans ADR-069)

`awk` et `comm` uniquement — **jamais** `grep` piped, qui tronque en silence sur ce poste.

```bash
W="$HOME/.claude/gsd-core/workflows"; T1=$(mktemp); H=$(mktemp); seen=0
for f in "$W"/*.md; do
  [ -f "$f" ] || continue; seen=$((seen+1))
  awk -v F="$f" 'tolower($0) ~ /workstream/ || /--ws([^a-zA-Z0-9-]|$)/ { print F; exit }' "$f" >> "$T1"
  awk -v F="$f" '/\.planning\/(ROADMAP\.md|STATE\.md|phases)/           { print F; exit }' "$f" >> "$H"
done
sort -u "$T1" -o "$T1"; sort -u "$H" -o "$H"
echo "atteinte=$seen (doit valoir 91)"
echo "K2 conscients=$(awk 'END{print NR+0}' "$T1")  en dur=$(awk 'END{print NR+0}' "$H")  aveugles=$(comm -13 "$T1" "$H" | awk 'END{print NR+0}')"
```

Attendu au 2026-08-04, gsd-core 1.9.1 : `atteinte=91`, `K2 conscients=7  en dur=45  aveugles=42`.

**Règle générale, applicable au-delà de cette fiche** : tout chiffre gravé dans un ADR ou un README
porte sa méthode et se re-dérive au moment de l'écriture. Un chiffre sans critère nommé n'est pas
faux — il est **indécidable**, et deux lecteurs de bonne foi en tireront deux conclusions opposées,
ce qui est exactement ce qui s'est produit ici.

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

- **Aucune application au-delà des deux révisions autorisées.** Seules **C-1** (Iron Law 2, portée
  par `24-10`) et **C-6** (amendement d'ADR-064, portée par ADR-069) sont appliquées ; C-2 à C-5
  restent des propositions sans effet.
- **Aucune révision d'ADR-031** ni de la **release racine gatée** — la doctrine GSD-first ne les lève
  pas (contrainte explicite du mandat).
- **Aucun verdict modifié.** Les 12 plans exécutent les 6 verdicts **tels qu'arbitrés le 2026-08-04**.
- **Aucune phase ajoutée** au ROADMAP (« PAS DE PHASE 27 »).

## Références

`24-ARBITRAGES.md` (verdicts) · `24-RESEARCH.md` (R-1, R-2) · `24-CONTEXT.md` (F-01→F-38) ·
`.planning/REQUIREMENTS.md` § Hors-milestone Phase 24 (GSDA-01→22) ·
`plugin/conductor/AGENT.md:114-117` (les 4 Iron Laws ; ancre re-vérifiée le 2026-08-04) ·
`docs/ADR.md` (ADR-057, ADR-064, ADR-069, ADR-031) ·
`.planning/missions/2026-07-31-mesure-m2-dispatch-parallele.md` ·
`.planning/missions/2026-08-04-phase-24-activation-moteur-gsd.md`
