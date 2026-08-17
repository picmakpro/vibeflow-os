# Phase 18: Survie du ledger d'exigences à la clôture de jalon - Context

**Gathered:** 2026-08-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Faire **survivre les exigences à la clôture de jalon**. Un fichier qui existe déjà
(`.planning/REQUIREMENTS.md`), **aucun nouveau registre, aucune nouvelle grammaire, aucun overlay**.

Le trou comblé (STUDY §7.1) : `gsd-complete-milestone` exécute `git rm .planning/REQUIREMENTS.md`
**inconditionnellement**, et `new-milestone` régénère de zéro au jalon suivant — aucun lab GSD
conforme n'a de réponse durable à « qu'est-ce que ce système garantit aujourd'hui ? ».

**Hors périmètre, explicitement** — l'indexation par capability (STUDY §7.3, « bénéfice non
capté ») et la parsabilité machine des exigences (§4 : aucun consommateur). Ne pas les revendiquer.

</domain>

<decisions>
## Implementation Decisions

### A. Forme du roll-over

- **D-18-01 :** LEDG-01 est aligné sur le **roll-forward**, pas sur le keep-file. Les exigences
  non livrées voyagent au jalon suivant avec une trace de report ; l'archive garde son rôle
  d'instantané. — **Reversibility:** costly — le format de trace se propage dans le ledger de
  chaque lab dès la première clôture outillée ; en changer ensuite demande une migration de tous
  les `REQUIREMENTS.md` en circulation.

  *Motif, et il est décisif :* le STUDY §7.2 décrit la variante comme « le fichier **reste** »
  (keep-file). Le prototype attaché à la RFC amont mesure cette forme à **4 conflits sur 5**
  (readiness count pollué, findings orphelins fantômes dans `audit-milestone`, intention
  milestone-scoped brisée, chevauchement d'IDs non marqué avec l'archive) et ne sort **que** le
  roll-forward à **0/5**. Le §7.2 du STUDY est donc **périmé sur son point central**.

- **D-18-02 :** Le `STUDY.md` reçoit un **encadré d'amendement daté** en tête de son §7.2 qui
  périme la formulation keep-file et renvoie ici. Sans ça, un futur agent qui lit le STUDY en
  premier repart sur la variante à 4 conflits — exactement le faux départ que le recalage de
  `STATE.md` du 2026-08-17 vient de corriger ailleurs.

- **D-18-03 :** Les exigences **livrées restent dans le fichier vivant**, mais **hors de la table
  de traçabilité** — dans une section dédiée (`## Garanties`, H2 propre) portant leur statut final.
  — **Reversibility:** reversible — section additive, sa suppression ne casse aucun consommateur.

  *C'est ce qui capte la motivation d'origine du §7.1.* Le roll-forward strict (livrées → archive
  seule) laisse un fichier vivant qui n'est qu'une liste de restes à faire : « que garantit le
  système aujourd'hui ? » exigerait encore de fouiller la pile d'archives, et le trou ne serait
  comblé qu'à moitié.

  **Réserve levée pendant le cadrage** — vérifié sur gsd-core 1.10.0 : les deux consommateurs
  cités comme conflits par le prototype amont sont scopés à la **table de traçabilité**, pas au
  fichier entier.
  - `~/.claude/gsd-core/bin/lib/milestone.cjs:70` — `updateTraceabilityCell()` borne l'écriture au
    heading `## Traceability` (ou `## Traceability Status`) jusqu'au prochain H1/H2.
  - `~/.claude/gsd-core/workflows/audit-milestone.md:68,153` — la détection d'orphelins parse
    « REQUIREMENTS.md **traceability table** ».

  Une section `## Garanties` en H2 distinct échappe donc aux deux. **Reste à confirmer par la
  recherche de phase** : le *readiness count* mentionné par le prototype amont (compte-t-il la
  table seule ou le fichier ?) — non localisé pendant le cadrage.

- **D-18-04 :** L'archive `milestones/v[X.Y]-REQUIREMENTS.md` reste un **instantané verbatim
  intégral** — le fichier entier au moment de la clôture, livrées comprises. Le CLI archive déjà
  verbatim avec en-tête SHIPPED : **zéro code à écrire**, la doctrine dit simplement que c'est un
  instantané, pas un déménagement.

### B. Qui exécute le geste

- **D-18-05 :** VibeFlow livre un **rattrapage outillé qui s'exécute APRÈS la clôture** et
  reconstitue le ledger en roll-forward depuis l'archive. — **Reversibility:** costly — le geste
  devient le chemin par lequel les labs conservent leur ledger ; le retirer après adoption
  laisserait les labs sans reprise au jalon suivant.

  *Motif :* `complete-milestone.md` vit dans `~/.claude/gsd-core/`, hors du contrôle de VibeFlow, et
  la RFC #3556 n'a pas de go/no-go formel. Le rattrapage est le seul choix qui livre la valeur
  **maintenant** sans dépendre d'un tiers, et il **ne combat pas le moteur** — il s'exécute après
  lui, il ne le bloque pas.

  **Contrainte de qualification, non négociable (Iron Law 2, `plugin/conductor/AGENT.md:114`
  « Router, jamais réimplémenter ») :** le rattrapage est un **post-traitement**. Il ne
  réimplémente ni `complete-milestone`, ni l'archivage, ni la génération. Tout plan qui le ferait
  dériver vers une copie du workflow amont est hors périmètre.

- **D-18-06 :** Point d'ancrage = **hook `SessionStart`** qui détecte l'état (MILESTONES.md déclare
  un jalon clos ET REQUIREMENTS.md absent) et **propose** la reconstitution **sous validation
  humaine (ADR-031)** — jamais en silence. Même moule que `check-dev-bootstrap.sh` et
  `check-doc-drift.sh`, **forme exec** héritée de la Phase 30.

  Conséquence d'architecture à exploiter au plan : le gate et le rattrapage **partagent la même
  détection**. Une seule primitive de détection, deux consommateurs.

  *`ship:post` est écarté* — STUDY §5 : `/gsd-ship` n'est pas le chemin de release réel de ce repo
  (condition A1 non satisfaite).

- **D-18-07 :** **Plan D3** — si la RFC est refusée ou sans réponse au **2026-10-26**, le
  rattrapage **devient permanent** au lieu de transitoire. Aucun ré-arbitrage à conduire.

  *C'est ce qui désamorce le risque porteur du §7.2* : le STUDY prévoyait un ré-arbitrage intégral
  parce qu'il supposait un gate seul, qui sans levier upstream planterait un piquet contre le
  moteur. Le rattrapage n'a jamais eu besoin de la RFC pour fonctionner. Si la RFC passe, il
  devient un no-op propre et se retire.

### C. Armement du gate

- **D-18-08 :** `check-requirements-survival.sh` est en **ratchet** — il avertit d'abord, bloque au
  merge qui livre la remédiation, et n'est jamais rouge des semaines. Précédent :
  `workflow.windows_enforce` (spec Windows II §7) ; même moule que le BUDG-02 prévu en Phase 25.

  *Raison concrète, pas théorique :* tout lab ayant clos un jalon **avant** cette mise à jour a un
  `MILESTONES.md` avec jalon clos et un `REQUIREMENTS.md` absent → rouge dès le premier
  `SessionStart`, sur du legacy que l'utilisateur n'a pas causé. Le ratchet laisse le rattrapage
  reconstituer depuis l'archive, puis bloque.

- **D-18-09 :** **Ce repo (`vibeflow-os`) est armé** avec son propre gate. Il a un
  `REQUIREMENTS.md` vivant et des jalons clos dans `MILESTONES.md` : le gate y est vert
  immédiatement, l'armement ne coûte rien et prouve le geste sur pièce. Répond aussi à la
  condition **C1** du STUDY (« ce repo prouve qu'il consomme son propre outillage »).

  *Écart assumé avec le précédent de la Phase 32*, où `vibeflow-os` a été laissé volontairement non
  armé pour le driver-lock : là le risque était réel, ici il est nul.

  **Rappel de régression (#38, v2.49.0 → v2.50.1) :** un réglage d'armement posé dans le settings
  local du repo **ne voyage pas**. L'armement doit être porté par une précondition distribuée.

- **D-18-10 :** Périmètre du gate = **détection d'absence uniquement**. Une trace `carried-from:`
  malformée tombe dans la **3ᵉ issue de QUAL-01** (imparsable → **BRUYANT**), **jamais dans FAIL** :
  un ledger illisible n'est ni un vert ni un rouge, il est signalé. Le gate est **lecteur
  d'absence, jamais juge de contenu**.

  *Motif verrouillé par la ROADMAP :* le volet « ou n'a pas bougé » est exactement l'heuristique que
  `check-doc-drift.sh` se refuse en en-tête et que la Phase 17 a neutralisée. L'absence, elle, est
  binaire et falsifiable.

### D. Table statut → destin

- **D-18-11 :** **Trois destins.** — **Reversibility:** costly — la table décide de ce qui survit à
  chaque clôture ; une erreur de classement fait disparaître une exigence du vivant.

  | Statut au ledger | Destin |
  |---|---|
  | Livrée — `Complete`, « Livré vX.Y.Z » | section `## Garanties` du fichier vivant **+** archive |
  | Non livrée — `Pending` sous toutes ses formes | **voyage** avec `carried-from:` |
  | Caduque / abandonnée — « caduc depuis vX.Y.Z » | **archive seule**, sort du vivant |

  *Le point qui décide :* une exigence caduque **ne garantit plus rien**. La laisser en `Garanties`
  ferait mentir la section ; la faire voyager ferait croire qu'elle reste à faire. Le cas est déjà
  présent dans le ledger : `VERB-02`, « caduc depuis v2.33.0 (façade supprimée) ».

- **D-18-12 :** Forme de la trace = **`carried-from: v[X.Y]`**, littéralement la syntaxe validée
  par le prototype amont. — **Reversibility:** one-way — la trace est écrite dans le ledger de
  chaque lab à chaque clôture ; changer la syntaxe après diffusion demande une migration de tous
  les ledgers existants **et** casse la compatibilité avec un éventuel gsd-core aligné.

  *Enjeu concret :* si la RFC passe, gsd-core produira **exactement** cette forme et notre
  rattrapage devient un no-op propre. Toute divergence, même cosmétique, nous condamne à une
  migration.

- **D-18-13 :** Le roll-forward **préserve les statuts verbatim** et se contente d'accoler
  `carried-from:`. **Aucune normalisation** vers un vocabulaire fermé.

  *Motif :* le ledger porte 48 `Complete`, 9 `Pending` et des annotations riches en prose
  (« Pending — conditionnelle (gsd-core > 1.10.0 releasé ET installé) », « Livré v2.31.0 (17/18
  verbes) — caduc depuis v2.33.0 »). Zéro perte, zéro jugement machine sur une prose que seul un
  humain sait interpréter — cohérent avec D-18-10. Et la parsabilité machine n'a **aucun
  consommateur** (STUDY §4).

### E. Doctrine

- **D-18-14 :** Une ligne de doctrine dans `plugin/dev-orchestrator/AGENT.md` : les archives
  `milestones/*-REQUIREMENTS.md` sont des **instantanés** ; `.planning/REQUIREMENTS.md` est la
  **seule source vivante**. C'est le critère 3 de la ROADMAP.

### Claude's Discretion

- Le découpage en plans et les vagues.
- Le nom exact et l'emplacement de la primitive de détection partagée entre gate et rattrapage.
- La forme du marqueur de ratchet (fichier, config, variable d'environnement) — à aligner sur le
  précédent `workflow.windows_enforce` après lecture de son implémentation réelle.
- Le libellé exact de la section `## Garanties` (le nom est à confirmer contre l'usage existant du
  ledger).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Étude et cadrage de la phase
- `.planning/phases/VFDO-18-survie-du-ledger-d-exigences-la-cl-ture-de-jalon/STUDY.md` — étude de
  faisabilité (verdict **GO-RÉDUIT** du 2026-07-28). **§7.2 est périmé** sur la forme du roll-over
  (voir D-18-01/02) ; §7.1 (le trou), §7.3 (chiffrage) et §8 (conditions d'invalidation) restent
  valides.
- `.planning/ROADMAP.md` §Phase 18 — goal, 5 critères de succès, transverse QUAL-01, et la
  dépendance à la RFC (« la RFC conditionne le GO du gate, pas le code »).
- `.planning/REQUIREMENTS.md` — LEDG-01, LEDG-02 (portées ici), LEDG-03 (RFC, portée par la
  Phase 30). Statuts réels du ledger à respecter (D-18-13).

### Amont — la RFC et ce qu'elle a produit
- https://github.com/open-gsd/gsd-core/issues/3556 — RFC LEDG-03, ouverte le 2026-08-15, **OPEN**
  au 2026-08-17. **Deadline de ré-arbitrage : 2026-10-26** (condition D3 du STUDY §8). Porte le
  prototype amont (4 variantes × 5 checks) qui valide le roll-forward à 0/5 et classe le keep-file
  à 4/5 — **source de D-18-01**.

### Moteur GSD — ce que le geste doit contourner ou suivre
- `~/.claude/gsd-core/workflows/complete-milestone.md:433,501` — `git rm .planning/REQUIREMENTS.md`,
  toujours **inconditionnel** en gsd-core **1.10.0** (vérifié 2026-08-17 : condition D1 du STUDY
  **non satisfaite**, la phase garde sa raison d'être).
- `~/.claude/gsd-core/workflows/new-milestone.md:475` — régénération de zéro au jalon suivant.
- `~/.claude/gsd-core/bin/lib/milestone.cjs:70` — `updateTraceabilityCell()`, scope `## Traceability`
  jusqu'au prochain H1/H2 — **preuve de l'innocuité de la section `## Garanties`** (D-18-03).
- `~/.claude/gsd-core/workflows/audit-milestone.md:68,153` — détection d'orphelins scopée à la
  table de traçabilité — **seconde preuve** (D-18-03).

### Analogues à imiter dans ce repo
- `plugin/dev-orchestrator/scripts/check-doc-drift.sh` — **167 lignes**, le moule exact du gate.
  Son en-tête (l. 4-6) porte le refus explicite de l'heuristique « n'a pas bougé » — motif de
  D-18-10.
- `plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh` — **278 lignes**.
- `plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh` + `plugin/dev-orchestrator/hooks/hooks.json`
  — moule du hook `SessionStart` en forme exec (D-18-06).

### Doctrine
- `plugin/conductor/AGENT.md:114` — Iron Law 2, « Router, jamais réimplémenter » — contrainte de
  qualification de D-18-05.
- `plugin/dev-orchestrator/AGENT.md` — cible de la ligne de doctrine (D-18-14).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `check-doc-drift.sh` (167 l.) : moule du gate — structure, en-tête, conventions de sortie. Son
  refus documenté de l'heuristique « n'a pas bougé » est directement réutilisable comme motif.
- `check-dev-bootstrap.sh` + `hooks/hooks.json` : moule du hook `SessionStart` en forme exec.
  **Rappel du hotfix v2.53.1** — la forme exec signifie **zéro expansion shell**, et les deux
  scopes (user / project) doivent être testés.
- Le CLI gsd-core archive déjà `REQUIREMENTS.md` **verbatim** avec en-tête SHIPPED : D-18-04 ne
  demande aucun code.

### Established Patterns
- **Ratchet** : `workflow.windows_enforce` (spec Windows II §7) est le précédent à lire avant de
  choisir la forme du marqueur (D-18-08).
- **QUAL-01** : tout gate du module naît avec ses issues explicites et sa **mutation rouge
  prouvée**. Amendé en Phase 32 (D-32-QUAL) à **quatre** issues — PASS / DENY / imparsable →
  fail-open silencieux / indisponible → fail-open **BRUYANT**. Vérifier au plan laquelle des deux
  formes (3 ou 4 issues) s'applique ici.
- **Convention de test du module** : ratio mesuré sur l'analogue exact = **278 / 167 ≈ 1,66×**.
  Le STUDY §7.3 chiffrait 232/153 ≈ 1,5× — **chiffres datés**. Un gate de 100-150 l. demande donc
  **~170-250 l.** de tests, pas 150-230.

### Integration Points
- `hooks/hooks.json` du module `dev-orchestrator` — entrée `SessionStart`. **Dette connue à ne pas
  rouvrir ici** : `merge-hooks.sh` porte un bug d'idempotence cross-matcher, contourné en Phase 32
  (déviation D-32-05) par une entrée unique. Le plan doit composer avec, pas le corriger.
- `.planning/MILESTONES.md` et `.planning/REQUIREMENTS.md` — les deux entrées de la détection.
- Bump du module `dev-orchestrator` (VERSION + CHANGELOG + README) à la clôture.

</code_context>

<specifics>
## Specific Ideas

- **Le gate et le rattrapage partagent la même détection** (« jalon clos déclaré ET ledger
  absent »). Une primitive, deux consommateurs — à exploiter au plan plutôt qu'à dupliquer.
- **Compatibilité amont comme objectif de conception**, pas comme bonus : le design retenu est
  celui que la RFC propose à gsd-core. Un GO upstream doit nous donner le geste **gratuitement**,
  et le rattrapage doit alors se retirer sans migration (D-18-12).
- La section `## Garanties` doit être un **H2 propre**, distinct de `## Traceability` — c'est
  précisément ce qui la met hors de portée des deux consommateurs amont.

</specifics>

<deferred>
## Deferred Ideas

- **Indexation par capability** — la part du besoin que le GO-RÉDUIT laisse ouverte (STUDY §7.3).
  Un `REQUIREMENTS.md` qui survit reste **indexé par jalon** : il livre une pile chronologique, pas
  la réponse directe à « que garantit le routage aujourd'hui ? ». Reste conditionnée à **E1**
  (résolution de la collision de vocabulaire « capability ») et **E2** (le besoin devient
  mesurable : ≥ 3 emplacements à réconcilier, plus de 2 fois). **Ne pas la revendiquer ici.**
- **Parsabilité machine des exigences** — aucun consommateur aujourd'hui (STUDY §4). Hors périmètre.
- **Archive réduite aux seules livrées** — écartée : exigerait de modifier le comportement
  d'archivage de gsd-core, donc une dépendance à la RFC bien au-delà du simple `git rm`.
- **Normalisation des statuts vers un vocabulaire fermé** — écartée par D-18-13, mais redeviendrait
  pertinente le jour où la parsabilité machine trouve un consommateur.
- **Correction du bug d'idempotence cross-matcher de `merge-hooks.sh`** — dette portée au BACKLOG
  depuis la Phase 32. Hors périmètre de cette phase.

</deferred>

---

*Phase: 18-Survie du ledger d'exigences à la clôture de jalon*
*Context gathered: 2026-08-17*
