---
phase: VFDO-28-preuve-que-ce-qui-est-arm-dans-le-plugin-est-arm-chez-l-util
plan: 01
verified: 2026-08-12T00:00:00Z
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
scope: "plan 28-01 SEUL — 28-02 / 28-03 (ARMD-05, 08, 09, 10, D-04) hors perimetre de cette verification"
method: "goal-backward, execution reelle ; fixtures INDEPENDANTES du verificateur + mutation testing de la suite livree"
warnings:
  - id: W1
    severity: warning
    what: "scripts/check-machine-paths.sh sort 1 sur l'arbre — c'est un gate CI (.github/workflows/ci.yml:359). Violation unique : .planning/phases/VFDO-28-.../28-RESEARCH.md:858 (« /Users/samuel »)." # vf-allow-machine-path — le littéral EST le sujet : ce rapport cite la violation constatée
    attributable_to_28_01: false
    evidence: "Le fichier fautif n'est PAS dans le diff 3c0f24b..HEAD (4 fichiers seulement) ; dernier commit le touchant = ad03fc6 (2026-08-10), anterieur aux 3 commits du plan. Declare honnetement dans 28-01-SUMMARY.md:174."
    action: "Decision humaine : corriger avant PR (le gate CI rougira sur cette branche) ou porter en tache de 28-02. Non imputable au plan 01."
  - id: W2
    severity: warning
    what: "L'en-tete de inject-mcp-tools.sh affirme que la regle 4 lit son verdict « comme preuve de la precondition worktree-baseref / mcp-servers ». Ce script ne fournit QUE mcp-servers (# vf-provides: mcp-servers) ; il ne prouve jamais worktree-baseref."
    attributable_to_28_01: true
    evidence: "plugin/dev-orchestrator/scripts/inject-mcp-tools.sh, bloc ajoute par be9e2eb — la phrase conflate les deux ids de la table OKID."
    action: "Corriger la phrase (retirer « worktree-baseref / ») — le premier porteur reel du marqueur ne doit pas decrire faux ce qu'il prouve."
infos:
  - id: I1
    what: "Le parseur de frontmatter ouvre a la PREMIERE ligne valant `---` OU QU'ELLE SOIT, pas a la ligne 1. Un .md sans frontmatter portant une regle horizontale `---` suivie d'une ligne `cle: valeur` est lu comme un frontmatter."
    demonstrated: true
    evidence: "Fixture verificateur sans frontmatter (--- en ligne 5, `isolation: worktree` en ligne 7) -> ECART regle 4, exit 1."
    exposure: "0 / 51 artefacts distribues sont sans frontmatter en ligne 1 aujourd'hui — risque LATENT, jamais actif."
    direction: "Faux POSITIF uniquement (ROUGE indu), jamais un faux vert : ne peut pas manquer le but."
  - id: I2
    what: "Les assertions de la suite testent `*\"ECART regle 4\"*`, motif qui matche aussi « ECART regle 4bis » (sous-chaine)."
    exploitable: false
    evidence: "Dans MUT-R2 et MUT-R3 aucune 4bis ne peut naitre (agentB porte un vf-requires legal). Les regles 2/2bis/3 emettent « ECART regle 2/2bis/3 » — la garde contre « un exit 1 venu d'une autre regle » tient."
  - id: I3
    what: "L'action (5) du plan demandait de comparer les ids par `occ()` a frontiere ; l'implementation compare par egalite stricte (`REQ_VAL[f] != reqid`)."
    direction: "PLUS strict que demande (un `vf-requires: a, b` multi-valeur rougirait), jamais plus permissif. Deviation mineure non declaree au SUMMARY."
  - id: I4
    what: "`vf-requires` n'est PAS dans les cles KNOWN de plugin/conductor/scripts/check-agents.sh:158."
    impact: "Sans effet en 28-01 (aucun artefact distribue ne porte encore vf-requires). Mordra en 28-02, quand des artefacts reels le porteront."
---

# Phase 28 / Plan 01 — Rapport de verification

**But du plan :** qu'un artefact distribue arme d'une capacite dont la precondition n'est posee par
personne fasse ROUGIR le gate, et que le desarmement (ou la preuve de la precondition) le fasse
VERDIR — les deux sens etablis sur l'incident #38 rejoue en fixture.

**Verdict goal-backward : GOAL ACHIEVED.**

Les six verites du bloc `must_haves` sont etablies **par execution**, dont cinq sur des fixtures
construites par le verificateur (independantes de la suite livree), et la discriminance de la suite
livree est elle-meme etablie par **deux mutations du gate** attestees par `cmp`.

## Suites executees — comptes REELS

| Suite | Commande | Sortie observee | Exit |
|---|---|---|---|
| Gate | `bash plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh` | `== bilan : 41 cas — 41 OK / 0 KO ==` | 0 |
| Porteur | `bash plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` | `Bilan : 26 OK, 0 KO` | 0 |
| Module | `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | `== resultat : 184 OK / 0 KO / 0 SKIP ==` | 0 |
| Gate voisin | `bash plugin/conductor/scripts/check-agents.sh` | — | 0 |
| Chemins machine | `bash scripts/check-machine-paths.sh` | 1 violation, **pre-existante** (W1) | **1** |

Les 41 cas annonces par le SUMMARY sont donc **reels**, pas declaratifs.

## Verites observables — chacune avec sa commande et sa sortie

### Verite 1 — armement sans precondition ⇒ 1, message nommant artefact + armement + fichier:ligne — VERIFIEE

Fixture **du verificateur** (`veriflab.md`, `isolation: worktree`, sans `vf-requires`) :

```
[check-capability-activation] ECART regle 4 : artefact « .../veriflab.md » arme « isolation »
sans precondition declaree (vf-requires: absent) — exige « worktree-baseref » — .../veriflab.md:4
EXIT=1
```

Ligne reelle de l'armement dans le fichier, controlee separement : `veriflab.md:4`. **Le numero de
ligne est exact**, pas un placeholder.

### Verite 2 — desarmement (mutation attestee par `cmp`) ⇒ 0 — VERIFIEE

```
mutation attestee par cmp
EXIT_desarme=0
```

Mutation : retrait de `isolation:` et `vf-requires:`. `cmp -s` confirme que le fichier a change
(mutant opposable).

### Verite 3 — `vf-requires` leve par `# vf-provides` ⇒ 0, sans execution de script — VERIFIEE

Le script porteur de la fixture contenait un **canari d'execution** (`touch "$CANARI_PATH"` +
`echo "JE ME SUIS EXECUTE"`) :

```
EXIT=0
canari toujours absent — jointure STATIQUE
```

Le canari n'a jamais ete cree : **aucun script du corpus n'est execute**. Confirme statiquement —
aucun `system()`, `eval`, `source` ni `.` dans le gate.

**D-02b (liaison explicite par identifiant, jamais inferee d'une proximite de nom) — falsifiee et
tenue.** Un porteur declarant `# vf-provides: worktree-baseref-BIS` — id qui **contient** le bon —
ne leve rien :

```
ECART regle 4 : ... vf-requires « worktree-baseref » legal, mais aucun # vf-provides:
worktree-baseref dans le corpus de scripts balaye
EXIT_id_voisin=1
```

### Verite 4 — les quatre planchers anti-vert-a-vide ⇒ 2, jamais 0 — VERIFIEE (4/4)

Controle prealable : le gate **non mute**, dans les memes conditions, sort **0**.

| Plancher | Comment exerce | Message | Exit |
|---|---|---|---|
| Univers d'artefacts vide | `VF_CAPACT_ARMED=""` | `aucun artefact lisible dans le corpus darmement (0 fichier(s) annonce(s)) — la regle 4 serait INERTE` | 2 |
| Corpus sans `# vf-provides:` | script muet | `aucun marqueur # vf-provides: ... — la moitie preuve de la regle 4 serait INERTE` | 2 |
| Table des armements vide | **mutation sur copie** du gate (`cmp`-attestee) | `table des armements surveilles vide — la regle 4 serait INERTE` | 2 |
| Table des ids legaux vide | **mutation sur copie** du gate (`cmp`-attestee) | `table des ids de precondition legaux vide — la regle 4 et la regle 4bis seraient INERTES` | 2 |
| (bonus) chemin annonce illisible | chemin inexistant | `artefact d'armement illisible (...) — activation NON VERIFIABLE` | 2 |

Les deux planchers de **table** sont structurellement inatteignables depuis l'exterieur (les tables
`ARM`/`OKID` sont litterales et non surchargeables — T-28-01-05, doctrine tenue). Ils ont donc ete
exerces par mutation d'une **copie hors-depot** du gate : ce sont bien des gardes vivantes, pas du
code mort declaratif. La suite livree, elle, ne couvre que les deux premiers (R5/R6).

### Verite 5 — le message du cas ROUGE porte le numero de regle 4, et le test l'asserte — VERIFIEE

Falsification decisive. Mutation du gate (copie structurelle complete) : la regle 4 **rougit
toujours** (`exit 1`) mais son message est renumerote `ECART regle 9`. La suite livree **echoue** :

```
✗ MUT-R2 ... — rc=1 regle4=0 nomme=1 ...
✗ MUT-R3 ... — rc=1 regle4=0 id=1 ...
== bilan : 40 cas — 38 OK / 2 KO ==
```

`rc=1` mais `regle4=0` ⇒ l'assertion porte bien sur le **message**, jamais sur le seul code de
sortie. Un `exit 1` venu d'une autre regle ne peut pas passer pour la preuve.

**Seconde mutation (la suite est-elle decorative ?)** : boucle de la regle 4 neutralisee
(`for (i = 1; i <= 0; i++)`), `cmp`-attestee ⇒ `40 cas — 38 OK / 2 KO`, MUT-R2 et MUT-R3 tombent.
La suite est **reellement discriminante**.

### Verite 6 — l'arbre reel reste vert — VERIFIEE

```
$ bash plugin/dev-orchestrator/scripts/check-capability-activation.sh
[check-capability-activation] conforme — univers balaye : 23 toggle(s) ... 334 ligne(s).
EXIT_ARBRE_REEL=0
```

## Artefacts (`must_haves.artifacts`)

| Artefact | `contains` attendu | Existe | Substantiel | Cable | Statut |
|---|---|---|---|---|---|
| `check-capability-activation.sh` | `ECART regle 4` | oui (657 l., +220) | regle 4 + 4bis + 4 planchers + ARM/OKID | invoque nu en CI (`ci.yml:342`) + 3 appelants | ✓ VERIFIE |
| `inject-mcp-tools.sh` | `# vf-provides: mcp-servers` | oui (549 l., +8) | en-tete seule ; **0 ligne de logique** modifiee (diff verifie) | lu par le corpus PROVIDERS du gate | ✓ VERIFIE (voir W2) |
| `test-check-capability-activation.sh` | `vf-requires` | oui (943 l., +313) | 12 cas neufs, 7 `cmp -s`, 7 `ECART regle 4` | 41/41 verts, discriminance prouvee par mutation | ✓ VERIFIE |

Comptes mesures : `ECART regle 4` x3 dans le gate, `# vf-provides: mcp-servers` x1 (exactement)
dans le porteur, `VF_CAPACT_ARMED` x4 / `VF_CAPACT_PROVIDERS` x3.

## Key links (`must_haves.key_links`)

| De | Vers | Via | Statut |
|---|---|---|---|
| gate | frontmatter des artefacts distribues | `VF_CAPACT_ARMED` + argv + 3e discriminant `FILENAME in ISARM` | ✓ CABLE — 51 artefacts au defaut, R9 prouve que `nLines` du corpus n'est pas pollue |
| gate | en-tete des scripts distribues | `VF_CAPACT_PROVIDERS` + `FILENAME in ISPRV`, lecture texte du bloc de tete | ✓ CABLE — canari prouve l'absence d'execution |
| suite | gate | `mktemp -d`, mutation `cmp -s`, assertion sur `ECART regle 4` | ✓ CABLE — prouve par double mutation |

## Criteres d'acceptation du plan — tous executes

| Critere | Resultat |
|---|---|
| suite du gate → 0, 0 KO | 41 OK / 0 KO, exit 0 |
| gate sur l'arbre reel → 0 | exit 0 |
| `awk '/ECART regle 4 /...'` | 3 occurrences, rc=0 |
| `awk '/^# vf-provides: mcp-servers$/...'` (== 1) | 1 occurrence, rc=0 |
| `awk '/VF_CAPACT_ARMED/ /VF_CAPACT_PROVIDERS/...'` | 4 / 3, rc=0 |
| `ECART regle 4bis` present | 1, rc=0 |
| `regle 4 serait INERTE` present | 3, rc=0 |
| suite du porteur → 0 | 26 OK / 0 KO |
| 52 suites, inchange | 52, rc=0 |
| aucun artefact distribue n'arme `isolation:` | rc=0 sur les 51 — et le gate vert sur l'arbre le **reprouve** a toute profondeur d'indentation |
| `test-dev-orchestrator.sh` → 0 | 184 OK / 0 KO |
| `check-machine-paths.sh` → 0 | **1** — pre-existant, non imputable (W1) |

## Exigences

| ID | Statut | Preuve |
|---|---|---|
| ARMD-01 | ✓ SATISFAITE | jointure par identifiant prouvee (falsification `-BIS`) ; regle 4bis + contre-epreuve D-01 |
| ARMD-02 | ✓ SATISFAITE | `ARM`/`OKID` litterales dans l'awk, non surchargeables ; planchers de table exerces par mutation |
| ARMD-03 | ✓ SATISFAITE | verite 1, `fichier:ligne` exact |
| ARMD-04 | ✓ SATISFAITE | verite 3, canari d'execution absent |
| ARMD-06 | ✓ SATISFAITE | 4 planchers + garde de lisibilite, tous exerces |
| ARMD-07 | ✓ SATISFAITE | MUT-R4 (#38 rejoue) + mutations `cmp`-attestees, discriminance bidirectionnelle |

ARMD-05, 08, 09, 10 : **hors perimetre** (plans 28-02 / 28-03), non comptes.

## Deviations declarees par le SUMMARY — controlees

| # | Declaration | Verdict du verificateur |
|---|---|---|
| 1 | Apostrophes francaises cassant l'awk | REELLE et benigne. `bash -n` propre sur les 3 fichiers. Aucune assertion touchee. |
| 2 | `unbound variable` bash 3.2 sur tableau vide sous `set -u` | REELLE. Idiome `"${ARR[@]+"${ARR[@]}"}"` present aux 4 points d'expansion. **Ne masque rien** : le plancher « univers vide » sort bien en 2, verifie. |
| 3 | Fixture du cas 14 « completee » | **N'a PAS neutralise le cas.** Les assertions du cas 14 sont **inchangees** (`rc_lab -eq 0` ET `2 fichier(s) de corpus`), et la contre-epreuve 14b (config du voisin ⇒ rc=1) est intacte. L'ajout est un `dummy-agent.md` **non arme** et un `dummy-provider.sh` portant un id **jamais requis** dans cette fixture : il reconstitue l'univers sans introduire ni lever d'ecart de regle 4. Le cas continue de tester ce qu'il testait (racine = le lab, jamais le parent). |

Aucune des trois deviations ne contourne une assertion.

## Anti-patterns

Aucun marqueur `TBD` / `FIXME` / `XXX` / `TODO` / `HACK` / `PLACEHOLDER` dans les trois fichiers
modifies. Aucun `eval`, `system()`, `source` dans le gate (T-28-01-03 tenu).

---

*Verifie le 2026-08-12 — verification goal-backward par execution, non commitee.*
