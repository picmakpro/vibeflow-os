# Phase 18: Survie du ledger d'exigences à la clôture de jalon - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-17
**Phase:** 18-survie-du-ledger-d-exigences-la-cl-ture-de-jalon
**Areas discussed:** Forme du roll-over, Qui exécute le geste, Armement du gate, Table statut → destin

---

## Vérifications conduites AVANT le cadrage

Deux conditions du STUDY §8 étaient vérifiables par commande. Elles ont été jouées avant de poser
la moindre question, parce que l'une d'elles pouvait supprimer la phase.

| Condition | Commande | Résultat |
|---|---|---|
| **D1** — gsd-core cesse de supprimer le ledger → variante caduque | `grep -n "git rm .planning/REQUIREMENTS.md" ~/.claude/gsd-core/workflows/complete-milestone.md` | **2 occurrences** (l. 433, 501) en gsd-core 1.10.0 → **non satisfaite**, la phase garde sa raison d'être |
| **D3** — RFC refusée ou sans réponse au 2026-10-26 | `gh issue view 3556 --repo open-gsd/gsd-core` | **OPEN**, créée le 2026-08-15, réponse d'un collaborateur amont le 2026-08-15 avec prototype chiffré → **non satisfaite**, 70 jours de marge |

**Fait décisif découvert à cette occasion :** le prototype amont attaché à la RFC teste 4 variantes
sur 5 checks de conflit. Le **keep-file** — la variante que le STUDY §7.2 décrit — sort à **4/5
conflits**. Seul le **roll-forward** sort à **0/5**. Le STUDY est donc périmé sur son point central,
et la ROADMAP (LEDG-01, « `carried-from:` ») avait déjà intégré la correction sans que le STUDY
soit amendé. C'est ce qui a ouvert la première zone de discussion.

---

## Forme du roll-over

### Q1 — Aligner LEDG-01 sur le roll-forward et amender le STUDY ?

| Option | Description | Selected |
|--------|-------------|----------|
| Oui, roll-forward + amender le STUDY | Adopte la seule variante à 0/5 ; le STUDY reçoit un encadré daté périmant son §7.2 | ✓ |
| Oui, mais sans toucher au STUDY | Même design, STUDY laissé comme document d'époque | |
| Non, keep-file assumé | Garde « le fichier reste », en assumant les 4 conflits mesurés | |

**Notes :** l'argument retenu est la compatibilité amont — notre design devient celui que la RFC
propose, donc un GO upstream donne le geste gratuitement. L'amendement du STUDY est motivé par le
précédent immédiat : le recalage de `STATE.md` du même jour a montré ce que coûte un document
périmé qu'un agent lit en premier.

### Q2 — Que deviennent les exigences déjà livrées ?

| Option | Description | Selected |
|--------|-------------|----------|
| Section « Garanties » séparée | Livrées hors de la table de traçabilité, dans un H2 dédié | ✓ |
| Strict — les livrées partent | Conformité maximale au prototype amont, coût le plus bas | |
| Tout reste, statut final en ligne | Pratique manuelle actuelle du repo — c'est le keep-file à 4/5 | |

**Notes :** le roll-forward strict ne comble le trou du §7.1 qu'à moitié — le fichier vivant
devient une liste de restes à faire, et « que garantit le système ? » exige encore de fouiller les
archives. La réserve posée avec l'option (« vérifier que le readiness count ne compte pas cette
section ») a été **levée dans la foulée** : `milestone.cjs:70` scope l'écriture au heading
`## Traceability`, `audit-milestone.md:68,153` scope la détection d'orphelins à la table de
traçabilité. Un H2 distinct échappe aux deux. Le readiness count lui-même n'a pas été localisé —
reporté à la recherche de phase.

### Q3 — Rôle de l'archive `milestones/v[X.Y]-REQUIREMENTS.md`

| Option | Description | Selected |
|--------|-------------|----------|
| Instantané verbatim intégral | Le fichier entier au moment de la clôture, comme aujourd'hui | ✓ |
| Archive réduite aux livrées | Pas de doublon archive/ledger | |

**Notes :** le CLI archive déjà verbatim avec en-tête SHIPPED → zéro code. L'option réduite aurait
exigé de modifier le comportement d'archivage de gsd-core, donc une dépendance à la RFC bien
au-delà du simple `git rm`.

---

## Qui exécute le geste

### Q1 — Que livre-t-on maintenant, sans attendre le go/no-go de la RFC ?

| Option | Description | Selected |
|--------|-------------|----------|
| Rattrapage outillé après clôture | S'exécute après le `git rm`, reconstitue depuis l'archive | ✓ |
| Doctrine + gate seuls, on attend | Coût minimal — mais gate en conflit récurrent avec le moteur | |
| Doctrine seule, pas de gate | Repli prévu par D3 — ne comble rien | |
| Commande VF enveloppant la clôture | Plus intégré — crée une porte d'entrée concurrente du natif | |

**Notes :** l'option retenue est la seule qui livre la valeur sans dépendre d'un tiers **et** sans
combattre le moteur — elle s'exécute après lui. L'option « commande enveloppante » a été écartée
comme une couche de synonymes, le motif exact de la suppression de la façade `vf-*` à l'audit
2026-07. Contrainte de qualification portée au CONTEXT : le rattrapage est un **post-traitement**,
jamais une réimplémentation de `complete-milestone` (Iron Law 2).

### Q2 — Point d'ancrage

| Option | Description | Selected |
|--------|-------------|----------|
| Hook SessionStart détecte et propose | Même moule que check-dev-bootstrap, forme exec Phase 30 | ✓ |
| Verbe explicite à jouer à la clôture | Simple, mais repose sur la mémoire de l'opérateur | |
| Les deux — verbe + détection | Couvre l'oubli, surface plus large à tester | |

**Notes :** `ship:post` était écarté d'avance par le STUDY §5 (`/gsd-ship` n'est pas le chemin de
release réel de ce repo, condition A1 non satisfaite). Le choix fait émerger une propriété
d'architecture exploitable au plan : gate et rattrapage partagent la même détection.

### Q3 — Plan si la RFC est refusée au 2026-10-26 (condition D3)

| Option | Description | Selected |
|--------|-------------|----------|
| Le rattrapage devient permanent | Aucun ré-arbitrage — le geste n'a jamais eu besoin de la RFC | ✓ |
| Ré-arbitrage intégral comme prévu | Applique la conclusion du STUDY à la lettre | |
| À trancher à l'échéance | Ne préjuge pas, inscrit la date en veille | |

**Notes :** ce choix **désamorce le risque porteur du §7.2**. Le STUDY prévoyait un ré-arbitrage
parce qu'il supposait un gate seul, qui sans levier upstream planterait un piquet contre le moteur.
Le rattrapage, lui, suit le moteur — un refus amont le rend définitif au lieu de transitoire.

---

## Armement du gate

### Q1 — Sévérité

| Option | Description | Selected |
|--------|-------------|----------|
| Ratchet — avertit d'abord | Précédent `workflow.windows_enforce`, même moule que BUDG-02 | ✓ |
| Rouge d'emblée | Critère binaire, rendu satisfiable jour 1 par le rattrapage | |
| Avertissement définitif | Zéro friction — mais LEDG-02 exige qu'il rende ROUGE | |

**Notes :** l'argument décisif est concret et non théorique — tout lab ayant clos un jalon **avant**
cette mise à jour serait rouge dès le premier `SessionStart`, sur du legacy que l'utilisateur n'a
pas causé.

### Q2 — Dogfooding

| Option | Description | Selected |
|--------|-------------|----------|
| Oui, armer ce repo | Gate vert immédiatement ici, coût nul, répond à la condition C1 | ✓ |
| Non, labs seulement | Cohérent avec le précédent Phase 32 (driver-lock) | |

**Notes :** écart assumé avec la Phase 32, où `vibeflow-os` a été laissé non armé — là le risque
était réel, ici il est nul. Rappel porté au CONTEXT : régression #38, un armement posé dans le
settings local du repo ne voyage pas.

### Q3 — Périmètre

| Option | Description | Selected |
|--------|-------------|----------|
| Absence seule ; traces = issue BRUYANTE | Le gate est lecteur d'absence, jamais juge de contenu | ✓ |
| Absence + validation des traces | Plus de garanties — mais le §7.2 refuse le juge de contenu | |

**Notes :** verrouillé d'avance par la ROADMAP. Une trace malformée tombe dans la 3ᵉ issue de
QUAL-01 (imparsable → BRUYANT), jamais dans FAIL.

---

## Table statut → destin

### Q1 — Correspondance

| Option | Description | Selected |
|--------|-------------|----------|
| Trois destins | Livrées → Garanties + archive ; non livrées → voyagent ; caduques → archive seule | ✓ |
| Binaire livré / non livré | Plus simple — mais les caduques atterrissent en Garanties | |
| Quatre destins — conditionnelles à part | Plus fidèle — 4ᵉ cas à spécifier et tester | |

**Notes :** le cas qui tranche existe déjà dans le ledger — `VERB-02`, « caduc depuis v2.33.0
(façade supprimée) ». En Garanties il ferait mentir la section ; en report il ferait croire qu'il
reste à faire.

### Q2 — Forme de la trace

| Option | Description | Selected |
|--------|-------------|----------|
| `carried-from: v[X.Y]` — la forme de la RFC | Syntaxe littérale validée par le prototype amont | ✓ |
| Forme maison plus riche | Jalon d'origine, date, motif — mais diverge de l'amont | |

**Notes :** classée `one-way` au CONTEXT. Si la RFC passe, gsd-core produira exactement cette forme
et le rattrapage devient un no-op propre ; toute divergence, même cosmétique, condamne à une
migration de tous les ledgers en circulation.

### Q3 — Statuts en prose libre

| Option | Description | Selected |
|--------|-------------|----------|
| Préserver verbatim + ajouter la trace | Zéro perte, zéro jugement machine | ✓ |
| Normaliser vers un vocabulaire fermé | Parsable — mais §4 montre qu'aucun consommateur n'existe | |

**Notes :** inventaire réel du ledger conduit pendant le cadrage — 48 `Complete`, 9 `Pending`, plus
des annotations riches (« Pending — conditionnelle (gsd-core > 1.10.0 releasé ET installé) »,
« Livré v2.31.0 (17/18 verbes) — caduc depuis v2.33.0 »). Cohérent avec le gate lecteur, jamais juge.

---

## Claude's Discretion

- Découpage en plans et vagues.
- Nom et emplacement de la primitive de détection partagée entre gate et rattrapage.
- Forme du marqueur de ratchet — à aligner sur `workflow.windows_enforce` après lecture de son
  implémentation réelle.
- Libellé exact de la section `## Garanties`.

## Deferred Ideas

- **Indexation par capability** — conditionnée à E1 et E2 du STUDY §8. Ne pas la revendiquer ici.
- **Parsabilité machine des exigences** — aucun consommateur (STUDY §4).
- **Archive réduite aux seules livrées** — exigerait de modifier l'archivage de gsd-core.
- **Normalisation des statuts** — redeviendrait pertinente si la parsabilité trouve un consommateur.
- **Bug d'idempotence cross-matcher de `merge-hooks.sh`** — dette BACKLOG depuis la Phase 32.

## Correction apportée au chiffrage du STUDY

Mesure refaite sur l'analogue exact pendant le scout :

| | STUDY §7.3 (2026-07-28) | Mesuré le 2026-08-17 |
|---|---|---|
| `check-doc-drift.sh` | 153 l. | **167 l.** |
| `tests/test-check-doc-drift.sh` | 232 l. | **278 l.** |
| Ratio test/script | 1,5× | **1,66×** |

Conséquence : un gate de 100-150 l. demande **~170-250 l.** de tests, pas 150-230.
