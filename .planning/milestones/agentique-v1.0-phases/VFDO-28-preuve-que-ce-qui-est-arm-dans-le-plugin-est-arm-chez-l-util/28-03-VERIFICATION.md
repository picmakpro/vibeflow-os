---
phase: VFDO-28-preuve-que-ce-qui-est-arm-dans-le-plugin-est-arm-chez-l-util
plan: 03
verified: 2026-08-15T00:00:00Z
status: human_needed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
method: "goal-backward, execution reelle dans un worktree isole ; reproduction integrale du job CI + 6 tests de falsification (F1-F8) sur copies de lab, jamais sur l'arbre reel"
scope: "diff bd37f1e..HEAD (4 commits) ; ARMD-06 + ARMD-08 + D-04 seulement — 28-01/28-02 hors portee"
checkpoint_D04: "second-job-9-modules (repondu par l'humain hors session) — cas nominal, bloc <branching> inactif"

warnings:
  - id: W1
    severity: warning
    what: "Mapping ARMD inverse dans le frontmatter `coverage` du SUMMARY : D1 (job CI as-installed) est etiquete ARMD-06, D2 (triades de version) est etiquete ARMD-08. Or ARMD-08 EST l'exigence as-installed (REQUIREMENTS.md:605-609) et n'a aucun rapport avec les triades de version."
    attributable_to_28_03: true
    evidence: "28-03-SUMMARY.md:52 (`requirement: \"ARMD-06\"` sur D1) et :61 (`requirement: \"ARMD-08\"` sur D2) ; .planning/REQUIREMENTS.md:605-609."
    impact: "Tracabilite seulement. La substance des DEUX exigences est livree : le job porte son propre plancher anti-vert-a-vide (ARMD-06) ET s'execute tel qu'installe sur univers non vide (ARMD-08). Aucun manque fonctionnel."
    action: "Corriger le mapping dans le SUMMARY (D1 -> ARMD-06 + ARMD-08 ; retirer ARMD-08 de D2). Non bloquant."
  - id: W2
    severity: info
    what: "Le nom du job est tronque par le parseur YAML : `name: Lab frais arme (... univers non vide, #38)` est un scalaire nu, donc ` #38)` est lu comme un COMMENTAIRE YAML. Le nom affiche dans l'UI GitHub sera « Lab frais arme (as-installed testing — le gate installe, sur un univers non vide, »."
    attributable_to_28_03: true
    evidence: ".github/workflows/ci.yml:664 ; `yaml.safe_load` rend le nom tronque a la virgule."
    impact: "Cosmetique — le libelle du job dans l'UI. Aucun effet sur l'execution, aucun effet sur les assertions."
    action: "Quoter le nom (`name: \"...#38)\"`) au prochain passage. Non bloquant."

human_verification:
  - test: "Pousser `feat/phase-28-03-as-installed` et lire le run GitHub Actions : les 4 jobs (`tests`, `gates`, `lab-frais`, `lab-frais-arme`) doivent etre verts."
    expected: "4/4 jobs verts ; le job `lab-frais-arme` affiche « fermeture armee : ... dev-orchestrator ... », « gate installe (rc=0) », « artefacts armes installes : 2 »."
    why_human: "La branche n'a JAMAIS ete poussee (`git branch -r --list '*phase-28-03*'` -> vide). Le plan exige un run CI vert constate (<verification>:438 et <success_criteria>:454). Le push est hors mandat d'execution ET hors mandat de verification. Un run sur ubuntu-latest ne peut pas etre simule."

deferred: []
---

# Phase 28 — Plan 03 : Verification (as-installed testing + cloture des triades)

**Goal du plan** : faire tourner le gate **la ou l'install le pose**, sur un univers d'armement qui
n'est pas vide — et clore les deux triades de module.

**Verdict goal-backward : GOAL ACHIEVED**, avec **un critere de preuve ouvert** (run CI reel) qui
est structurellement hors du mandat d'execution.

---

## Methode

Le job `lab-frais-arme` a ete **extrait du YAML** (`yaml.safe_load` -> 5 scripts `run`) puis
**execute verbatim** en local, etape par etape, avec `GITHUB_WORKSPACE` et `GITHUB_ENV` simules.
Puis **6 tests de falsification** sur des **copies** du lab installe. Aucune mutation de l'arbre
source, aucun commit, aucun push.

Shell local : **bash 3.2.57 (macOS)** — plus conservateur que le bash 5 d'`ubuntu-latest`.

---

## Observable Truths (`must_haves.truths` du plan)

| # | Truth | Statut | Preuve executee |
|---|---|---|---|
| 1 | La CI exerce le gate tel qu'installe dans un lab vierge, sur un univers d'armement NON VIDE contenant au moins deux artefacts reellement armes | ✓ VERIFIED | Reproduction integrale des 5 etapes : `mktemp -d` + `git init` -> install de 9 modules -> `.planning/config.json` -> gate `rc=0` -> `artefacts armes installes : 2`. Les 2 armes mesures : `vf-coder.md` (`vf-mcp-consumer: true`) et `vf-reviewer.md` (`vf-mcp-tools: XcodeBuildMCP:...`), tous deux porteurs de `vf-requires: mcp-servers` — exactement l'etat annonce par le commentaire du job. |
| 2 | Le gate invoque dans le lab est celui pose par l'install (`.claude/scripts/`), jamais celui de l'arbre source | ✓ VERIFIED | `awk '/\.claude\/scripts\/check-capability-activation\.sh/{n++} END{exit !(n>=1)}'` -> **n=1, rc=0** (unique occurrence, ligne 724). Le rapport du gate cite le chemin **installe** : `.claude/agents/dev-orchestrator-references/gsd-capabilities-index.md` — pas `plugin/dev-orchestrator/references/...` comme sur l'arbre source. Aucune invocation depuis `$GITHUB_WORKSPACE` dans le job. Aucune surcharge `VF_CAPACT_*`. |
| 3 | Si l'univers d'armement du lab devient vide, le job echoue en exit 2 plutot que de rendre vert | ✓ VERIFIED | **F8** (corpus d'armement vraiment vide : `agents/*.md` + `skills/*/SKILL.md` supprimes de la copie) -> `aucun artefact lisible dans le corpus darmement (0 fichier(s) annonce(s)) — activation NON VERIFIABLE`, **gate rc=2**, etape rc=1. **F6** (corpus non vide mais ZERO artefact arme) -> le gate rend 0, et c'est le **plancher du job** qui mord : `univers d'armement du lab installe < 2 (0)`, rc=1. Le double plancher de T-28-03-01 est mesure **dans les deux sens**. |
| 4 | Gate C conserve ses trois assertions mot pour mot et sa tolerance rc ∈ {0,3} ; son lab et sa fermeture sont en outre inchanges | ✓ VERIFIED | Extraction du bloc `lab-frais` avant/apres (`bd37f1e` vs `HEAD`) : les **33 lignes sont byte-identiques**, `diff` ne rend que des **additions apres la fin du job**. Diff global sur `ci.yml` : `97 insertions(+), 0 deletions(-)`, hunk unique `@@ -650,3 +650,100 @@`. Fermeture `conductor` re-derivee du disque : **7 modules**, inchangee. Les 3 assertions verifiees en place : `check-agents.sh --strict` (:645), `check-registres.sh --strict --allow-empty` avec `rc ∈ {0,3}` (:649-650), `grep -q "guard" .claude/settings.json` (:652). |
| 5 | Les deux modules touches portent leur triade VERSION / module.json / CHANGELOG coherente | ✓ VERIFIED | `bash scripts/check-version-sync.sh` -> **rc=0**, 15 lignes vertes dont `triade par module : 17 modules VERSION ↔ module.json alignes` et `en-tete Version des README de modules : 17 declares, tous alignes`. Valeurs mesurees : `dev-orchestrator` v2.15.0 (VERSION = module.json = README), `conductor` v1.23.0 (idem). |

**Score : 5/5 verites verifiees** (0 override, 0 present-behavior-unverified).

---

## Tests de falsification — le vert a vide est-il ferme ?

Le mode d'echec central de ce plan est le **vert a vide**. Chaque mecanisme a ete casse
deliberement sur une **copie** du lab, pour verifier que le job **tombe**.

| # | Mutation | Attendu | Mesure | Statut |
|---|---|---|---|---|
| F1 | Fermeture resolue sans `dev-orchestrator` (fermeture `conductor` injectee) | assertion etape 2 declenche | `-> assertion DECLENCHE (le job sortirait 1)` | ✓ MORD |
| F2 | `vf-reviewer.md` desarme -> 1 seul artefact arme | plancher `< 2` declenche | `artefacts armes installes : 1` + `::error::univers d'armement du lab installe < 2 (1)`, **rc=1** | ✓ MORD |
| F3 | `.planning/config.json` retire du lab | gate exit 2, etape rouge | `configuration du lab illisible — activation NON VERIFIABLE`, `gate installe (rc=2)`, **etape rc=1** | ✓ MORD |
| F4 | `# vf-provides: mcp-servers` retire de `inject-mcp-tools.sh` **installe** | gate non nul | `aucun marqueur # vf-provides: dans le corpus de scripts balaye (48 fichier(s))`, `rc=2`, **etape rc=1** | ✓ MORD |
| F5 | `vf-requires: mcp-servers` retire de `vf-coder.md` **installe** | regle 4 ROUGE, nommant l'artefact | `ECART regle 4 : artefact « .claude/agents/vf-coder.md » arme « vf-mcp-consumer » sans precondition declaree — .claude/agents/vf-coder.md:9`, `rc=1`, **etape rc=1** | ✓ MORD |
| F6 | Les 2 artefacts desarmes -> 0 arme, corpus non vide | job rouge | gate `rc=0` (corpus non vide, legitime) **mais** plancher du job : `< 2 (0)`, **rc=1** | ✓ MORD (par le plancher du job) |
| F8 | Corpus d'armement **vraiment** vide (0 fichier annonce) | gate exit 2 | `aucun artefact lisible dans le corpus darmement (0 fichier(s))`, `rc=2`, **etape rc=1** | ✓ MORD |

**F5 est la preuve centrale** : la regle 4 rougit **tel qu'installe**, dans la disposition a plat du
lab, en nommant l'artefact par un chemin **relatif** (`.claude/agents/vf-coder.md:9`) — ce qui
valide aussi T-28-03-04 (aucun chemin absolu de runner ne fuit dans le verdict).

### Chasse aux avaleurs de code de sortie

Aucun trouve. Balayage du bloc neuf (lignes 654-fin) :

- `|| true` : **0**
- `continue-on-error` : **0** (ni au niveau job, ni au niveau etape — confirme par `yaml.safe_load`)
- `set +e` : **0**
- Un seul `||` : `bash .claude/scripts/check-capability-activation.sh || rc=$?`, immediatement suivi
  de `[ "$rc" -eq 0 ]` sous `set -eu` — mecanisme mesure comme mordant en F3/F4/F5.
- Le seul pipe qui pourrait avaler : `awk ... 2>/dev/null | sort -u | awk 'END{print NR+0}'` —
  **fail-closed** (echec -> compte vide -> `0` -> `< 2` -> exit 1), mesure en F2/F6.

---

## Acceptance criteria — Tache 1 (option `second-job-9-modules`)

| Critere | Commande | Sortie | Statut |
|---|---|---|---|
| `lab-frais-arme` present, n==1 | `awk '/^  lab-frais-arme:/{n++} END{exit !(n==1)}' .github/workflows/ci.yml` | `n=1`, **rc=0** | ✓ |
| Script **installe** invoque, n>=1 | `awk '/\.claude\/scripts\/check-capability-activation\.sh/{n++} END{exit !(n>=1)}'` | `n=1`, **rc=0** | ✓ |
| Job `lab-frais` inchange | extraction du bloc avant/apres + `diff` | `33a34,43` (additions seules), 0 suppression, 0 modification | ✓ |
| YAML valide | `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"` | `yaml ok, jobs: ['tests','gates','lab-frais','lab-frais-arme']`, **rc=0** | ✓ |
| Assertion `< 2` artefacts armes | ci.yml:745-749 + execution F2/F6 | `::error::univers d'armement du lab installe < 2` -> rc=1 | ✓ |
| Commentaire « exit 2 = exit 1 » | ci.yml:726-727 | *« Un exit 2 (NON VERIFIABLE) echoue le job au meme titre qu'un exit 1 — un gate qui ne peut pas se prononcer n'est pas un gate vert. »* | ✓ |
| Aucun chemin absolu de machine | `bash scripts/check-machine-paths.sh` | `✓ 947 fichier(s) suivi(s) balaye(s), aucun chemin absolu de machine`, **rc=0** | ✓ |

**7/7.**

### Fermeture installee — re-derivee du disque

`bash plugin/_internal/resolve-deps.sh dev-orchestrator` -> **9 modules**, contenant
`dev-orchestrator` :

```
audit-architecture · conductor · consolidator · design-orchestrator · dev-orchestrator
infrastructure-audit · planning-core · skill-creator · validator
```

Install reelle du job : **9/9 modules poses**, `dev-orchestrator v2.15.0` et `conductor v1.23.0`
inclus. `.claude/scripts/check-capability-activation.sh` **present** (42.5 K) dans le lab.

Contre-mesure : `resolve-deps.sh conductor` -> **7 modules**, **sans** `dev-orchestrator` — la
premisse du SIGNALEMENT du plan est confirmee ce jour.

---

## Acceptance criteria — Tache 2 (cibles re-pointees par decision humaine)

Le plan visait `v2.14.0` / `v1.22.0` / racine `v2.50.1`. Ces valeurs sont **perimees** : elles
etaient deja posees sur `main` (travail Phase 29, v2.51.0). Le bump repart des valeurs reelles —
**decision humaine actee**, pas une deviation.

| Critere (re-pointe) | Commande | Sortie | Statut |
|---|---|---|---|
| `check-version-sync` | `bash scripts/check-version-sync.sh` | **rc=0**, 15 assertions vertes | ✓ |
| `dev-orchestrator` VERSION | `cat plugin/dev-orchestrator/VERSION` | `v2.15.0` | ✓ |
| `dev-orchestrator` module.json | `awk '/v2.15.0/{n++} END{exit !(n==1)}'` | `n=1`, **rc=0** | ✓ |
| `conductor` VERSION | `cat plugin/conductor/VERSION` | `v1.23.0` | ✓ |
| `conductor` module.json | `awk '/v1.23.0/{n++} END{exit !(n==1)}'` | `n=1`, **rc=0** | ✓ |
| CHANGELOG `dev-orchestrator` | `awk '/v2.15.0/{n++} END{exit !(n>=1)}'` | `n=1`, **rc=0** | ✓ |
| CHANGELOG `conductor` | `awk '/v1.23.0/{n++} END{exit !(n>=1)}'` | `n=1`, **rc=0** | ✓ |
| `VERSION` racine intacte | `cat VERSION` + `git diff --name-only bd37f1e..HEAD` | `v2.51.0` ; ni `VERSION`, ni `plugin.json`, ni `marketplace.json` dans le diff | ✓ |
| Les 2 entrees nomment #38 et « qui l'ecrit chez l'utilisateur » | `awk '/#38/'` + lecture | `dev-orchestrator` : 5 occurrences de `#38` + *« la question ... n'etait pas "la precondition existe-t-elle ?" mais "qui l'ecrit chez l'utilisateur ?" »* ; `conductor` : 6 occurrences + la meme question | ✓ |

**9/9.**

### Les journaux decrivent-ils la Phase 28 (et non la Phase 29) ?

Verifie sur pieces. `dev-orchestrator v2.15.0` couvre : regle 4, regle 4bis, jointure statique
`vf-requires` ↔ `# vf-provides`, 5 declarations `vf-requires: mcp-servers`, 4 planchers
anti-vert-a-vide, 5 bornes en en-tete, job `lab-frais-arme`. `conductor v1.23.0` couvre :
admission de `vf-requires` dans `KNOWN`, la precision mesuree (`warnings.append` nu, jamais
bloquant), la hierarchie avec la garde dure `isolation: worktree`. **Aucun contenu Phase 29.** Les
entrees `v2.14.0` / `v1.22.0` juste en dessous sont bien les entrees Phase 29 preexistantes,
intouchees.

**Ancres citees, re-verifiees du disque** : `check-agents.sh:621-623` (`for k in fm: if k not in
KNOWN: warnings.append(...)`) — exacte ; `.planning/ROADMAP.md:2047-2049` (*« il verifie que
l'install tient, jamais que ce qu'elle pose est coherent avec ce qu'elle a promis »*) — exacte ;
les 5 `vf-requires: mcp-servers` sur disque — exactement 5 (`vf-coder`, `vf-reviewer`,
`vf-app-fixer`, `vf-test-orchestrator`, `vf-test-runner`).

---

## Les deux deviations declarees masquent-elles un contournement ?

**Non.** Verifie ligne a ligne.

**Deviation 1 — README de module hors `files_modified`.** `check-version-sync.sh` compare aussi
l'en-tete `**Version**` des README de module a la `VERSION` canonique. Diff mesure :
**exactement 1 ligne changee par README**, uniquement le numero (`v1.22.0` -> `v1.23.0`,
`v2.14.0` -> `v2.15.0`). Aucune reformulation, aucun assouplissement d'assertion. C'est le
correctif **minimal** qui fait passer le critere de verification **deja prescrit par le plan**.

**Deviation 2 — 2 chemins absolus de machine (commit `ab73039`).** Diff mesure :
`2 files changed, 2 insertions(+), 2 deletions(-)` — **1 ligne par fichier**, nombre de lignes
inchange, aucune reformulation. Formes utilisees : `/Users/<user>` (forme documentaire) dans
`28-01-VERIFICATION.md`, chemin relatif `CLAUDE.md` dans `29-RESEARCH.md`. **Aucune assertion du
gate n'a ete touchee** — `scripts/check-machine-paths.sh` est inchange, seules les donnees fautives
l'ont ete. Le commit est bien separe et etiquete.

---

## Suites et gates (comptes reels, pas ceux du SUMMARY)

| Commande | Sortie reelle | rc |
|---|---|---|
| `bash plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh` | `== bilan : 60 cas — 60 OK / 0 KO ==` (comptage independant : **60 ✓ / 0 ✗**) | **0** |
| `bash plugin/dev-orchestrator/scripts/check-capability-activation.sh` | `conforme — univers balaye : 23 toggle(s) ... 334 ligne(s).` | **0** |
| `bash scripts/check-version-sync.sh` | 15 assertions vertes | **0** |
| `bash scripts/check-machine-paths.sh` | `✓ 947 fichier(s) suivi(s) balaye(s)` (le SUMMARY disait 946 — l'ecart est le SUMMARY lui-meme, ajoute depuis) | **0** |

---

## Anti-patterns

Balayage `TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER` sur les 5 fichiers de code/doc modifies :
**aucun marqueur imputable a 28-03**. Seul hit : `plugin/conductor/CHANGELOG.md:646`
(`DEC-XXX`, jeton de convention de nommage dans une entree historique, **hors du diff** de ce plan).

---

## Le critere « run CI vert constate » — NON SATISFAIT

Le plan l'exige deux fois : `<verification>:438` (*« pousser la branche de travail et lire le run
— tous les jobs verts ... C'est la seule preuve recevable que le gate tourne tel qu'installe ; la
lire dans le SUMMARY, jamais la deduire »*) et `<success_criteria>:454`.

**Mesure :** `git branch -r --list '*phase-28-03*'` -> **vide**. La branche n'a jamais ete poussee.
**Aucun run GitHub Actions n'existe.** Le SUMMARY le declare honnetement (section « Issues
Encountered ») et l'etiquette `human_judgment: true` sur D1 — la declaration est exacte, pas
minimisee.

**Ce que la reproduction locale achete malgre tout** (a porter au credit, sans le confondre avec la
preuve exigee) :

- Les 5 etapes du YAML executees **verbatim**, sur bash 3.2 — **plus** conservateur qu'ubuntu.
- Les 6 tests de falsification, tous mordants.
- `check-capability-activation.sh` tourne **deja** sur `ubuntu-latest` dans le job `gates`
  (`ci.yml:342`) — la compatibilite awk/ubuntu du gate est donc **deja prouvee en production**. Le
  risque residuel du job neuf se limite a la cascade de resolution en disposition installee (exercee
  ici) et a la propagation `$GITHUB_ENV` (patron identique a `lab-frais`, vert en production).

**Risque residuel : faible mais non nul.** Ce n'est pas une preuve equivalente, et ce rapport ne la
presente pas comme telle.

---

## Requirements Coverage

| Exigence | Description | Statut | Preuve |
|---|---|---|---|
| **ARMD-06** | Chaque regle neuve porte son plancher anti-vert-a-vide -> exit 2, jamais un repli vert | ✓ SATISFAITE | F8 (gate exit 2 sur corpus vide), F4 (corpus de preuve vide -> exit 2) + le plancher propre du job (F2/F6) |
| **ARMD-08** | Le gate s'execute **tel qu'installe** sur un univers **non vide**, plancher anti-vert-a-vide, cas `.planning/config.json` absent regle, vert de Gate C non trouble | ✓ SATISFAITE | Job `lab-frais-arme` reproduit de bout en bout (gate rc=0, 2 armes) ; F3 regle le cas config absent (exit 2) ; Gate C byte-identique |

**Note (W1)** : le SUMMARY etiquette ces deux exigences a l'envers dans son `coverage`. La substance
est livree ; seule la tracabilite est fausse.

---

## Verdict

**GOAL ACHIEVED.** Le gate tourne la ou l'install le pose, sur un univers d'armement de 2 artefacts
reellement armes, et il **mord** — prouve par 6 falsifications, pas par lecture. Gate C est intact
au byte pres. Les deux triades sont coherentes et leurs journaux decrivent le travail reel de la
Phase 28.

**Statut : `human_needed`** — un seul critere reste ouvert et il ne peut pas etre ferme par un
verificateur : lire le run CI reel apres push.

---

*Verifie : 2026-08-15 · Verificateur : gsd-verifier (worktree isole, read-only)*
