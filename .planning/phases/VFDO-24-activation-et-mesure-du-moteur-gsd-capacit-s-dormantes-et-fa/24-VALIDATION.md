---
phase: 24
slug: activation-et-mesure-du-moteur-gsd-capacit-s-dormantes-et-fa
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: false
nyquist_noncompliance_reason: >
  5 des 32 commandes `<automated>` des 12 plans ne rejouent PAS vertes sur `HEAD` (rc≠0),
  mesuré par extraction et ré-exécution le 2026-08-05. Au critère amont de
  `validate-phase.md:80-88` (COVERED = « test exists, targets behavior, **runs green** » ;
  PARTIAL = « test exists, **failing** or incomplete » ; « No gaps → set nyquist_compliant:
  true »), 5 vérifications sont donc PARTIAL et non COVERED — c'est un gap, donc `false`.
  Second motif, cumulatif : ce document est RENSEIGNÉ A POSTERIORI, après l'exécution des 12
  plans ; il n'a gouverné aucune décision d'échantillonnage pendant celle-ci.
  Nuance importante et mesurée, à ne pas surinterpréter : **les 5 rouges sont des défauts
  d'ASSERTION, pas des manques de livrable** — le contenu visé est présent dans l'arbre dans
  les 5 cas (détail en §Gaps d'échantillonnage). Aucune exigence `GSDA` n'est découverte
  non livrée par ce document.
wave_0_complete: true
created: 2026-08-05
validated: 2026-08-05
---

# Phase 24 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

> **RENSEIGNÉ A POSTERIORI, le 2026-08-05.** Ce document n'a jamais existé pendant l'exécution
> de la phase : les 12 plans ont été exécutés, revus, sécurisés et vérifiés sans qu'aucun
> contrat d'échantillonnage ne soit écrit ici. `24-VERIFICATION.md` l'a relevé comme gap
> (« La phase est validée au sens Nyquist, comme le lab l'exige de lui-même » → `failed`).
> Tous les chiffres ci-dessous sont **mesurés par exécution au moment du remplissage**, jamais
> reconstitués de mémoire ni recopiés d'un `SUMMARY.md`. Le frontmatter porte la conséquence :
> `status: validated` (les comportements SONT couverts, et la couverture est adossée à des
> commandes réelles) mais `nyquist_compliant: false` (5 de ces commandes ne rejouent pas
> vertes, et le contrat n'a pas gouverné l'exécution). Écrire `true` ici serait exactement le
> défaut que cette phase traque : une conformité affirmée que rien n'a mesurée.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash pur, zéro dépendance — helpers `ok()`/`ko()` maison (les livrables sont des scripts shell, de la doctrine markdown et du config JSON) |
| **Config file** | aucun — chaque `test-*.sh` est un exécutable autonome ; aucune Wave 0 nécessaire |
| **Quick run command** | `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` |
| **Full suite command** | `find plugin scripts -type f -path '*/tests/test-*.sh' \| sort` puis `bash` sur chaque — **forme exacte de la CI** (`.github/workflows/ci.yml:205-232`, étape « Découvrir et lancer toutes les suites », avec assertion de découverte non vide F13) |
| **Univers de suites** | **52** (`find plugin scripts -type f -path '*/tests/test-*.sh'`, compté en `awk 'END{print NR}'` — le glob à profondeur 1 n'en rend que 46, piège d'univers documenté en `24-VERIFICATION.md`) |
| **Estimated runtime** | **37 s** pour la suite la plus lente (`test-dev-orchestrator.sh`, 184 assertions) ; **61 s** cumulés pour les 10 suites touchées par la phase ; quelques minutes pour les 52 |

---

## Sampling Rate

*Contrat écrit a posteriori — il décrit la cadence que la phase A effectivement tenue (chaque tâche
des 12 plans porte une commande `<automated>`, cf. §Per-Task Verification Map), pas une cadence
souhaitée.*

- **After every task commit:** la commande `<automated>` de la tâche — **32 tâches, 32 commandes**,
  aucune tâche sans (mesuré, cf. carte ci-dessous).
- **After every plan wave:** la suite du module touché + `test-dev-orchestrator.sh`.
- **Before `/gsd-verify-work`:** les **52** suites du dépôt vertes + les **20** gates
  (`scripts/check-*.sh` = 3, `plugin/*/scripts/check-*.sh` = 17).
- **Max feedback latency:** **37 s** (mesurée, `test-dev-orchestrator.sh`). Les 9 autres suites de
  la phase sont entre **1 s et 6 s**.

---

## Per-Task Verification Map

Contractée **par tâche de plan**, univers = les 12 `24-NN-PLAN.md` du dossier de phase. Extraction
mécanique : chaque bloc `<automated>` a été extrait, dés-échappé (`&amp;` → `&`) et **ré-exécuté
depuis la racine du dépôt le 2026-08-05 sur `HEAD`**. La colonne « rejouée » porte le `rc` observé,
jamais une lecture.

| Plan | Tâches | Requirements | `<automated>` | Tâche sans verify | Rejouée sur HEAD |
|---|---|---|---|---|---|
| 24-01 | 3 | GSDA-20, 21, 22 | 3 | 0 | ✅ 3/3 rc=0 |
| 24-02 | 3 | GSDA-01, 04, 05, 06 | 3 | 0 | ❌ **0/3** — rc=1 ×3 |
| 24-03 | 2 | GSDA-02, 03 | 2 | 0 | ✅ 2/2 rc=0 |
| 24-04 | 3 | GSDA-13, 14 | 3 | 0 | ✅ 3/3 rc=0 |
| 24-05 | 3 | GSDA-16 | 3 | 0 | ✅ 3/3 rc=0 |
| 24-06 | 3 | GSDA-07, 08 | 3 | 0 | ✅ 3/3 rc=0 |
| 24-07 | 2 | GSDA-10, 11 | 2 | 0 | ⚠️ **1/2** — tâche 1 rc=1 |
| 24-08 | 2 | GSDA-15 | 2 | 0 | ✅ 2/2 rc=0 |
| 24-09 | 2 | GSDA-17 | 2 | 0 | ✅ 2/2 rc=0 |
| 24-10 | 3 | GSDA-12, 18, 19 | 3 | 0 | ⚠️ **2/3** — tâche 2 rc=1 |
| 24-11 | 3 | GSDA-09, 08, 15, 02 | 3 | 0 | ✅ 3/3 rc=0 |
| 24-12 | 3 | GSDA-09, 13, 14, 15, 16, 20, 21, 22 | 3 | 0 | ✅ 3/3 rc=0 |
| **Total** | **32** | **union = GSDA-01..22 (22/22)** | **32** | **0** | **27 verts / 5 rouges** |

**Continuité d'échantillonnage** : la plus longue série de tâches consécutives **sans** commande
automatisée est **0** — sur les 12 plans, dans l'ordre des tâches. Le critère « no 3 consecutive
tasks without automated verify » est donc satisfait **et mesurable a posteriori**, ce que la
Phase 23 ne pouvait pas faire (ses plans n'étaient pas instrumentés de la même façon). Aucune tâche
de type `checkpoint`, aucun `<human-check>` dans les 12 plans.

### Couverture par exigence

Univers = les **22** identifiants `GSDA-01..22` distincts de `.planning/REQUIREMENTS.md`.

| Exigence | Plan(s) porteur(s) | Commande automatisée qui la couvre | Statut |
|---|---|---|---|
| GSDA-01 | 24-02 | assertion `awk` sur ADR-066 (`docs/ADR.md`) + ligne d'index | ⚠️ PARTIAL — assertion rouge (G1) |
| GSDA-02 | 24-03, 24-11 | `jq -e '.agent_skills["gsd-planner"] \| length == 2'` + `test-dev-orchestrator.sh` | ✅ COVERED |
| GSDA-03 | 24-03 | assertion `awk` sur `GSD-PIPELINE.md` (`tdd_mode`, `onError: skip`) | ✅ COVERED |
| GSDA-04 | 24-02, 24-06 | `jq -e '… .workflow.windows_enforce …'` (24-06 T1, vert) ; ADR-066 (24-02, rouge) | ✅ COVERED par 24-06 |
| GSDA-05 | 24-02, 24-06 | `jq -e` sur `hooks.workflow_guard` (24-06 T1, vert) ; ADR-066 (24-02, rouge) | ✅ COVERED par 24-06 |
| GSDA-06 | 24-02 | assertion `awk` sur ADR-067 + ligne d'index | ⚠️ PARTIAL — assertion rouge (G2) |
| GSDA-07 | 24-06 | `jq -e '.intel.enabled == true'` | ✅ COVERED |
| GSDA-08 | 24-06, 24-11 | compteur `awk` des entrées « conditionnelle » + `check-capability-activation.sh` | ✅ COVERED |
| GSDA-09 | 24-11, 24-12 | `test-check-capability-activation.sh` (29 OK) + `check-version-sync.sh` | ✅ COVERED |
| GSDA-10 | 24-07 | assertion `awk` sur ADR-068 (`context_profile`, `dépréciée`) — tâche 2, verte | ✅ COVERED |
| GSDA-11 | 24-07 | mesure `awk` du seuil inline sur les `*-PLAN.md` — tâche 1 | ⚠️ PARTIAL — assertion rouge (G3) |
| GSDA-12 | 24-10 | extraction `awk` de l'Iron Law 2 dans `conductor/AGENT.md` — tâche 1, verte | ✅ COVERED |
| GSDA-13 | 24-04, 24-12 | `test-check-dev-bootstrap.sh` (35 ok) | ✅ COVERED |
| GSDA-14 | 24-04, 24-12 | `test-planning-context-hardening.sh` (38 passés) | ✅ COVERED |
| GSDA-15 | 24-08, 24-11, 24-12 | assertions `awk` sur `workstreams.md` + plafond ADR-029 | ✅ COVERED |
| GSDA-16 | 24-05, 24-12 | `test-check-workstream-pointer.sh` (24 ok) + assertion `jq` sur `hooks.json` | ✅ COVERED |
| GSDA-17 | 24-09 | `python3 -c "yaml.safe_load(…ci.yml…)"` + présence du job workstream | ✅ COVERED en forme — ⚠️ **jamais exécuté sur runner** (manual-only) |
| GSDA-18 | 24-10 | assertion `awk` sur ADR-069 — tâche 2 | ⚠️ PARTIAL — assertion rouge (G4/G5) |
| GSDA-19 | 24-10 | `test -f .planning/upstream/2026-08-04-workflows-aveugles-aux-workstreams.md` + assertions de contenu — tâche 3, verte | ✅ COVERED |
| GSDA-20 | 24-01, 24-12 | `test-check-agents.sh` (81 OK, T76 exige les 5 littéraux du descripteur) | ✅ COVERED |
| GSDA-21 | 24-01, 24-12 | compteur `awk` `^effort:` sur les 31 agents + `check-agents.sh --strict` ×6 | ✅ COVERED |
| GSDA-22 | 24-01, 24-12 | `test-check-agents.sh` + mutation « effort retiré » → rc=1 | ✅ COVERED |

**Bilan : 18 COVERED · 4 PARTIAL (GSDA-01, 06, 11, 18) · 0 MISSING.**
Aucune exigence n'est sans commande. Les 4 PARTIAL le sont par **défaut de l'assertion**, pas par
absence du livrable — les 5 défauts sont diagnostiqués clause par clause ci-dessous.

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky/partiel*

---

## Gaps d'échantillonnage — les 5 assertions qui ne rejouent pas vertes

Chaque rouge a été **décomposé clause par clause** pour distinguer « le livrable manque » de
« l'assertion est fausse ». Dans les 5 cas, c'est le second.

| # | Plan / tâche | Clause en échec | Diagnostic mesuré | Le livrable est-il là ? |
|---|---|---|---|---|
| **G1** | 24-02 T1 | `/strictement supérieure à 1\.9\.1/` sur `docs/ADR.md` | **Littéral coupé par un retour à la ligne** : `docs/ADR.md:1646-1647` porte « une version strictement\n supérieure à 1.9.1 ». Une assertion `awk` ligne-à-ligne ne peut pas la voir. Les 5 autres clauses (`h,a,b,c,e`) sont à 1, et l'index `\| ADR-066 \|` rend `n=1`. | ✅ oui — ADR-066 § Note de veille |
| **G2** | 24-02 T2 | `/69 ?%/` sur `docs/ADR.md` | **L'assertion pin un chiffre que l'ADR ne porte pas** : `docs/ADR.md:1677` écrit « **275 / 400 — 68 %** ». Les 4 autres clauses sont à 1, index `n=1`. Corollaire : c'est **le même chiffre** que le warning **W3** de `24-VERIFICATION.md` déclare non reproductible (re-dérivation → 305/400 = 76 %). L'assertion et l'ADR sont en désaccord, et l'ADR est en désaccord avec la mesure. | ✅ oui — ADR-067 existe et est indexée |
| **G3** | 24-02 T3 | `/strictement supérieure à 1\.9\.1/` sur `.planning/codebase/CONCERNS.md` | Même défaut que G1 : `CONCERNS.md:95-96` porte « strictement supérieure à\n 1.9.1 ». Les 3 autres clauses (`ADR-066`, `windows_enforce`, `workflow_guard`) sont à 1. | ✅ oui |
| **G4** | 24-07 T1 | `ENDFILE{…}` | **Extension `gawk` non portable** : l'`awk` de ce poste (BWK/BSD) ne connaît pas `ENDFILE`, la commande ne produit aucune ligne, et le garde-fou aval `NR>0` rougit. Défaut de l'assertion, indépendant du contenu mesuré. | ✅ oui — ADR-068 volet 2 porte la mesure |
| **G5** | 24-10 T2 | `awk '/^### Phase /{n++} END{exit !(n==26)}' .planning/ROADMAP.md` | **Piège d'univers dans l'assertion elle-même** : le ROADMAP mêle **deux profondeurs de titre** — `^### Phase ` = **13** et `^#### Phase ` = **13**, soit **26** au total. Le motif ne voit qu'une profondeur, compte 13, et échoue contre `n==26`. Les 8 clauses du volet ADR-069 sont **toutes à 1** et l'index rend `n=1` : le volet doctrinal est intact. | ✅ oui — ADR-069 complète |

**Aucun de ces 5 gaps n'ouvre un manque de livrable.** Ils ouvrent un manque de **fiabilité
d'échantillonnage** : quatre d'entre eux (G1, G3, G4, G5) auraient rougi le jour même de leur
écriture sur ce poste, ce qui signifie qu'ils n'ont pas pu servir de signal pendant l'exécution.
C'est précisément ce que le contrat Nyquist mesure — la qualité du signal, pas celle du livrable.

**Correction suggérée, non appliquée** (les `*-PLAN.md` sont des artefacts historiques d'une phase
exécutée : les réécrire a posteriori reviendrait à maquiller la trace) :

- G1 / G3 — pinner un littéral qui ne franchit pas de retour à la ligne (`supérieure à 1.9.1`), ou
  assertion multi-ligne (`awk 'BEGIN{RS=""}'` / normalisation des espaces avant match).
- G2 — trancher entre l'assertion (`69 %`) et l'ADR (`68 %`), tous deux non reproductibles selon
  W3 ; recaler sur la valeur que la commande rejouable rend (W3 demande déjà d'ajouter cette
  commande à ADR-067).
- G4 — remplacer `ENDFILE` par un pattern portable (`FILENAME != prev {…}` + bloc `END`).
- G5 — compter les deux profondeurs (`/^#{3,4} Phase /`) ou nommer explicitement l'univers visé.

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* Aucune installation de framework n'a été
nécessaire : les **10** suites touchées par la phase préexistaient ou ont été créées par les plans
eux-mêmes (24-05 pour `test-check-workstream-pointer.sh`, 24-11 pour
`test-check-capability-activation.sh`). Toutes vertes le 2026-08-05 :

| Suite | rc | Résultat | Durée |
|---|---|---|---|
| `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | 0 | **184 OK / 0 KO / 0 SKIP** | 37 s |
| `plugin/conductor/scripts/tests/test-check-agents.sh` | 0 | **81 OK / 0 KO** | 5 s |
| `plugin/conductor/scripts/tests/test-check-state-integrity.sh` | 0 | **40 ok / 0 ko** | 6 s |
| `plugin/conductor/scripts/tests/test-check-workstream-pointer.sh` | 0 | **24 ok / 0 ko** | 1 s |
| `plugin/conductor/scripts/tests/test-guard-agent-write.sh` | 0 | **14 OK / 0 KO** | 1 s |
| `plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh` | 0 | **29 OK / 0 KO** | 2 s |
| `plugin/dev-orchestrator/scripts/tests/test-check-dev-bootstrap.sh` | 0 | **35 ok / 0 ko** | 1 s |
| `plugin/planning-core/scripts/tests/test-planning-context-hardening.sh` | 0 | **38 passés / 0 échoués** | 1 s |
| `plugin/planning-core/scripts/tests/test-workstream-policy.sh` | 0 | **14 ok / 0 ko / 0 skip** | 5 s |
| `plugin/planning-core/scripts/tests/test-workstream-symlink-escape.sh` | 0 | **10 ok / 0 ko** | 2 s |

Univers de ce tableau : `git diff --name-only fbdb300..HEAD -- '**/tests/test-*.sh'` → **10**
fichiers. Aucun drapeau de mode veille (`--watch`, `entr`, `nodemon`) dans ces suites : **0**
occurrence.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|---|---|---|---|
| Le job CI `gates` / workstream est réellement **exercé sur un runner** | GSDA-17 | La branche `feat/phase-24-activation-moteur-gsd` **n'est pas poussée** (`git ls-remote --heads origin …` → 0 référence) ; `ci.yml:527-530` l'écrit lui-même. Aucune automatisation locale ne peut prouver un run distant. Warning **W5** de `24-VERIFICATION.md`. | Au premier push : vérifier sur le run que les 6 assertions workstream et `check-capability-activation.sh` sont exécutées **et** discriminantes. Les 6 ont été rejouées à la main sur fixture partitionnée (`24-VERIFICATION.md` §Gates rejoués). |
| Les deux skills du slot **PLANNER** sont posées dans le compte de la machine | GSDA-02 | La forme globale nue `global:<skill>` résout par système de fichiers vers le dossier de skills du compte ; un skill absent produit un `WARNING` sur stderr et est **silencieusement écarté** (`init.cjs:1765-1816`). Dépendance **machine-locale** : elle ne voyage pas avec le plugin. Warning **W4**. | Sur toute machine cible : `gsd-tools agent-skills gsd-planner` doit rendre le bloc `<agent_skills>` avec les **deux** entrées et **0 warning**. |
| Les six gestes de **release racine** (bump `VERSION`/`plugin.json`/`marketplace.json`, tag annoté, release GitHub) | hors `GSDA` — gouvernance | Gate humain non négociable (`CLAUDE.md` § Discipline de release, ADR-031). Le plan 24-12 garantit seulement que la branche **n'y touche pas** (`git diff main..HEAD` sur la triade → 0 ligne). | Après fusion, sous validation humaine explicite : bump, tag annoté, `gh release create`, puis `bash scripts/check-release-tag.sh --remote` → `✓`. |
| La recette humaine **XcodeBuildMCP** (fenêtre #3 du ledger) | GSDA-04 | Structurellement infermable sur ce dépôt : aucun `.mcp.json`, aucun projet iOS. Motif écrit, entrée passée `open` → `waived` et restant visible dans `/gsd-progress`. | Recette sur un lab iOS avec XcodeBuildMCP réellement connecté — hors périmètre de cette phase. |

---

## Validation Sign-Off

- [x] **All tasks have `<automated>` verify or Wave 0 dependencies** — **32 tâches sur 32**, aucune
      exception ; union des `requirements:` = **GSDA-01..22**, soit 22/22.
- [x] **Sampling continuity: no 3 consecutive tasks without automated verify** — plus longue série
      sans verify = **0**. Mesuré tâche par tâche sur les 12 plans, pas déduit d'un total.
- [x] **Wave 0 covers all MISSING references** — aucune référence manquante ; l'infrastructure
      préexistait, **0 MISSING** dans la couverture par exigence.
- [x] **No watch-mode flags** — 0 occurrence sur les 10 suites de la phase.
- [x] **Feedback latency < 60 s** — **37 s** mesurés au pire cas.
- [ ] **`nyquist_compliant: true` set in frontmatter** — **délibérément laissé à `false`.**
      Deux motifs cumulés, aucun fabriqué :
      **(a)** au critère amont (`validate-phase.md:80-88`), une vérification qui existe mais ne
      tourne pas verte est **PARTIAL**, donc un gap : **5 commandes sur 32** sont rouges sur `HEAD`
      (G1→G5), touchant **4 exigences** (GSDA-01, 06, 11, 18). « No gaps » n'est pas atteint.
      **(b)** ce contrat est écrit **après** l'exécution : il n'a pu gouverner aucune décision
      d'échantillonnage pendant celle-ci — même réserve que `23-VALIDATION.md`, et elle n'est pas
      rattrapable rétroactivement.

**Approval:** validated 2026-08-05 — *avec la réserve Nyquist ci-dessus. Aucun manque de livrable
n'est ouvert par ce document : les 5 gaps sont des défauts d'assertion, chacun diagnostiqué et
assorti d'une correction suggérée mais **non appliquée** (réécrire a posteriori le bloc `<verify>`
d'un plan déjà exécuté maquillerait la trace).*

---

_Renseigné : 2026-08-05_
_Méthode : extraction mécanique des 32 blocs `<automated>` des 12 `*-PLAN.md`, dés-échappement,
ré-exécution depuis la racine du dépôt, décomposition clause par clause des 5 rouges. Les 10 suites
et les durées sont chronométrées de première main. `grep`/`find` étant proxifiés et tronquants sur
ce poste, tous les comptes sont faits en `awk 'END{print NR}'` et croisés sur deux formes quand le
nombre est porteur._
