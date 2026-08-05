---
phase: 24
slug: activation-et-mesure-du-moteur-gsd-capacit-s-dormantes-et-fa
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: false
nyquist_noncompliance_reason: >
  Trois motifs cumulés, tous mesurés, aucun fabriqué.
  (a) **La CI est ROUGE sur la branche poussée.** Les 4 runs de
  `feat/phase-24-activation-moteur-gsd` concluent `failure`, dont les 2 derniers sur la tête
  poussée `7e3c39c` : 2 étapes en échec, `test-workstream-policy.sh` (cas A5d) et le job
  « Gates workstream-aware sur un arbre RÉELLEMENT partitionné » (assertion R1). Les deux
  passent en local sur macOS — c'est une **divergence de plateforme**, pas un flake, et elle
  touche `GSDA-13`, `GSDA-16` et `GSDA-17`.
  (b) 5 des 32 commandes `<automated>` des 12 plans ne rejouent PAS vertes sur `HEAD`
  (rc≠0), ré-extraites et ré-exécutées le 2026-08-05. Au critère amont de
  `validate-phase.md:80-88` (COVERED = « test exists, targets behavior, **runs green** » ;
  PARTIAL = « test exists, **failing** or incomplete »), 5 vérifications sont PARTIAL.
  (c) Ce document est RENSEIGNÉ A POSTERIORI, après l'exécution des 12 plans ; il n'a
  gouverné aucune décision d'échantillonnage pendant celle-ci.
  Nuance mesurée, à ne pas surinterpréter : les 5 rouges du motif (b) sont des défauts
  d'ASSERTION, pas des manques de livrable. Le motif (a), lui, est un **défaut de
  comportement réel** sur la plateforme de référence — c'est le plus grave des trois.
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
>
> **Discipline de chiffres.** Cette phase a produit quatre décomptes justes portant sur le
> mauvais ensemble (25 agents annoncés / 31 réels · 47 suites / 52 · 8 modules / 10 · 1 gate
> troué / 4). En conséquence : **aucun nombre de ce document n'est recopié d'un amont.** Chacun
> a été re-dérivé par exécution au moment de l'écriture, et **porte la commande qui le
> reproduit**. Deux corrections d'univers en sont sorties, signalées en place (§Wave 0).
>
> Le frontmatter porte la conséquence : `status: validated` (les comportements SONT couverts et
> adossés à des commandes réelles) mais `nyquist_compliant: false`. Écrire `true` ici serait
> exactement le défaut que cette phase traque : une conformité affirmée que rien n'a mesurée.

---

## Test Infrastructure

| Property | Value | Commande de re-dérivation |
|----------|-------|---------------------------|
| **Framework** | bash pur, zéro dépendance — helpers `ok()`/`ko()` maison (les livrables sont des scripts shell, de la doctrine markdown et du config JSON) | — |
| **Config file** | aucun — chaque `test-*.sh` est un exécutable autonome ; aucune Wave 0 nécessaire | — |
| **Quick run command** | `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | — |
| **Full suite command** | `find plugin scripts -type f -path '*/tests/test-*.sh' \| sort` puis `bash` sur chaque — **forme exacte de la CI** (`.github/workflows/ci.yml:208`) | — |
| **Univers de suites** | **52** — le glob à profondeur 1 n'en rend que 46, piège d'univers documenté en `24-VERIFICATION.md` | `find plugin scripts -type f -path '*/tests/test-*.sh' \| awk 'END{print NR}'` → `52` |
| **Univers d'agents** | **31** = `plugin/*/agents/*.md` (**25**) ∪ `plugin/*/AGENT.md` (**6**). Les deux familles sont posées dans `.claude/agents/` par l'installeur ; ne compter que la première est le piège d'univers qui a produit le « 25 » du ledger | `printf '%s\n' plugin/*/agents/*.md plugin/*/AGENT.md \| awk 'END{print NR}'` → `31` |
| **Gates** | **20** = `scripts/check-*.sh` (**3**) + `plugin/*/scripts/check-*.sh` (**17**) | `ls scripts/check-*.sh plugin/*/scripts/check-*.sh \| awk 'END{print NR}'` → `20` |
| **Estimated runtime** | **24 s** pour la suite la plus lente (`test-dev-orchestrator.sh`, 184 assertions) ; **110 s** pour les 52 suites du dépôt, mesuré bout en bout | boucle chronométrée sur la découverte CI |

---

## Sampling Rate

*Contrat écrit a posteriori — il décrit la cadence que la phase A effectivement tenue (chaque tâche
des 12 plans porte une commande `<automated>`), pas une cadence souhaitée.*

- **After every task commit:** la commande `<automated>` de la tâche — **32 tâches, 32 commandes**,
  aucune tâche sans (mesuré, cf. carte ci-dessous).
- **After every plan wave:** la suite du module touché + `test-dev-orchestrator.sh`.
- **Before `/gsd-verify-work`:** les **52** suites du dépôt vertes + les **20** gates.
  ⚠️ **Cette ligne n'est vraie que sur macOS.** Sur le runner Linux de la CI, la même découverte
  rend **52 suites, 1 échec** (§Gaps de plateforme). Un contrat d'échantillonnage qui n'est vert
  que sur le poste de l'auteur n'échantillonne pas la plateforme de référence.
- **Max feedback latency:** **24 s** (mesurée le 2026-08-05, `test-dev-orchestrator.sh`). Les 10
  autres suites de la phase sont entre **1 s et 6 s**.

---

## Per-Task Verification Map

Contractée **par tâche de plan**, univers = les 12 `24-NN-PLAN.md` du dossier de phase. Extraction
mécanique **re-faite pour ce document** : les 32 blocs `<automated>` ont été ré-extraits, dés-échappés
(`html.unescape`) et **ré-exécutés depuis la racine du dépôt le 2026-08-05 sur `HEAD` (`479eee9`)**.
La colonne « rejouée » porte le `rc` observé, jamais une lecture.

| Plan | Tâches | Requirements | `<automated>` | Tâche sans verify | Rejouée sur HEAD |
|---|---|---|---|---|---|
| 24-01 | 3 | GSDA-20, 21, 22 | 3 | 0 | ✅ 3/3 rc=0 |
| 24-02 | 3 | GSDA-01, 04, 05, 06 | 3 | 0 | ❌ **0/3** — rc=1 ×3 |
| 24-03 | 2 | GSDA-02, 03 | 2 | 0 | ✅ 2/2 rc=0 |
| 24-04 | 3 | GSDA-13, 14 | 3 | 0 | ✅ 3/3 rc=0 |
| 24-05 | 3 | GSDA-16 | 3 | 0 | ✅ 3/3 rc=0 |
| 24-06 | 3 | GSDA-07, 08 | 3 | 0 | ✅ 3/3 rc=0 |
| 24-07 | 2 | GSDA-10, 11 | 2 | 0 | ⚠️ **1/2** |
| 24-08 | 2 | GSDA-15 | 2 | 0 | ✅ 2/2 rc=0 |
| 24-09 | 2 | GSDA-17 | 2 | 0 | ✅ 2/2 rc=0 |
| 24-10 | 3 | GSDA-12, 18, 19 | 3 | 0 | ⚠️ **2/3** |
| 24-11 | 3 | GSDA-09, 08, 15, 02 | 3 | 0 | ✅ 3/3 rc=0 |
| 24-12 | 3 | GSDA-09, 13, 14, 15, 16, 20, 21, 22 | 3 | 0 | ✅ 3/3 rc=0 |
| **Total** | **32** | **union = GSDA-01..22 (22/22)** | **32** | **0** | **27 verts / 5 rouges** |

Re-dérivation du total : extraction `re.finditer(r"<automated>(.*?)</automated>")` sur les 12
`24-*-PLAN.md` → **32** blocs ; `subprocess.run(["bash","-c",cmd])` sur chacun → **27** rc=0.

**Continuité d'échantillonnage** : la plus longue série de tâches consécutives **sans** commande
automatisée est **0**. Le critère « no 3 consecutive tasks without automated verify » est donc
satisfait **et mesurable a posteriori**, ce que la Phase 23 ne pouvait pas faire. Aucune tâche de
type `checkpoint`, aucun `<human-check>` dans les 12 plans.

### Couverture par exigence

Univers = les **22** identifiants `GSDA-01..22` distincts de `.planning/REQUIREMENTS.md`
(`awk '/^- \[[ x]\] \*\*GSDA-/{n++} END{print n}'` → `22`, dont **22 cochées `[x]`**, `0` restante).

| Exigence | Plan(s) porteur(s) | Commande automatisée qui la couvre | Statut |
|---|---|---|---|
| GSDA-01 | 24-02 | assertion `awk` sur ADR-066 (`docs/ADR.md`) + ligne d'index | ⚠️ PARTIAL — assertion rouge (G1) |
| GSDA-02 | 24-03, 24-11 | `jq -e '.agent_skills["gsd-planner"] \| length == 2'` + `test-dev-orchestrator.sh` | ✅ COVERED |
| GSDA-03 | 24-03 | assertion `awk` sur `GSD-PIPELINE.md` (`tdd_mode`, `onError: skip`) | ✅ COVERED |
| GSDA-04 | 24-02, 24-06 | `jq -e '… .workflow.windows_enforce …'` (24-06 T1, vert) | ✅ COVERED par 24-06 |
| GSDA-05 | 24-02, 24-06 | `jq -e` sur `hooks.workflow_guard` (24-06 T1, vert) | ✅ COVERED par 24-06 |
| GSDA-06 | 24-02 | assertion `awk` sur ADR-067 + ligne d'index | ⚠️ PARTIAL — assertion rouge (G2) |
| GSDA-07 | 24-06 | `jq -e '.intel.enabled == true'` | ✅ COVERED |
| GSDA-08 | 24-06, 24-11 | compteur `awk` des entrées « conditionnelle » + `check-capability-activation.sh` | ✅ COVERED |
| GSDA-09 | 24-11, 24-12 | `test-check-capability-activation.sh` (**29 OK / 0 KO**) + `check-version-sync.sh` | ✅ COVERED |
| GSDA-10 | 24-07 | assertion `awk` sur ADR-068 (`context_profile`) — tâche 2, verte | ✅ COVERED |
| GSDA-11 | 24-07 | mesure `awk` du seuil inline sur les `*-PLAN.md` — tâche 1 | ⚠️ PARTIAL — assertion rouge (G4) |
| GSDA-12 | 24-10 | extraction `awk` de l'Iron Law 2 dans `conductor/AGENT.md` — tâche 1, verte | ✅ COVERED |
| GSDA-13 | 24-04, 24-12 | `test-check-dev-bootstrap.sh` (**35 ok / 0 ko**) | ⚠️ **PARTIAL — vert en local, ROUGE en CI** (CI-2) |
| GSDA-14 | 24-04, 24-12 | `test-planning-context-hardening.sh` (**38 passés / 0 échoués**) | ✅ COVERED |
| GSDA-15 | 24-08, 24-11, 24-12 | assertions `awk` sur `workstreams.md` + plafond ADR-029 | ✅ COVERED |
| GSDA-16 | 24-05, 24-12 | `test-check-workstream-pointer.sh` (**24 ok / 0 ko**) + `test-workstream-policy.sh` | ⚠️ **PARTIAL — vert en local, ROUGE en CI** (CI-1) |
| GSDA-17 | 24-09 | `python3 -c "yaml.safe_load(…ci.yml…)"` + présence du job workstream | ❌ **RED — le job a tourné et il ÉCHOUE** (CI-2) |
| GSDA-18 | 24-10 | assertion `awk` sur ADR-069 — tâche 2 | ⚠️ PARTIAL — assertion rouge (G5) |
| GSDA-19 | 24-10 | `test -f .planning/upstream/2026-08-04-workflows-aveugles-aux-workstreams.md` + contenu | ✅ COVERED |
| GSDA-20 | 24-01, 24-12 | `test-check-agents.sh` (**81 OK / 0 KO**, T76 exige les 5 littéraux du descripteur) | ✅ COVERED |
| GSDA-21 | 24-01, 24-12 | compteur `^effort:` sur les **31** agents + `check-agents.sh --strict` ×(6+11) | ✅ COVERED |
| GSDA-22 | 24-01, 24-12 | `test-check-agents.sh` + mutation « effort retiré » → rc=1 | ✅ COVERED |

**Bilan : 15 COVERED · 6 PARTIAL (GSDA-01, 06, 11, 13, 16, 18) · 1 RED (GSDA-17) · 0 MISSING** —
somme re-vérifiée à 22, égale à l'univers.
Aucune exigence n'est sans commande, et **aucune n'est découverte non livrée**. Mais trois
(`GSDA-13`, `GSDA-16`, `GSDA-17`) sont adossées à des commandes qui **ne sont vertes que sur macOS**.

Re-dérivation de `GSDA-21`/`GSDA-22` (l'univers historiquement faux) :
`grep -l '^effort:' $(printf '%s\n' plugin/*/agents/*.md plugin/*/AGENT.md) | awk 'END{print NR}'`
→ **31 sur 31**, et le gate rejoué dans les deux formes de la CI
(`--agents-dir` sur les 6 dossiers, `--file` sur les 6 `AGENT.md`) → **0 échec**.

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky/partiel*

---

## Gaps de plateforme — la CI est rouge, et ce n'est pas un flake

**C'est le gap qui bloque, et il ne figurait dans aucun document amont** : `24-VERIFICATION.md`
écrivait (warning W5) que la branche « n'est pas poussée » et que le job workstream n'avait
« jamais tourné sur un runner réel ». **Ce n'est plus vrai.** La branche est poussée et la CI a
tourné — elle échoue.

```
gh run list --branch feat/phase-24-activation-moteur-gsd --json databaseId,headSha,conclusion
→ 4 runs, 4 × "failure"  (2026-08-04T22:59Z sur 795b984 · 2026-08-05T00:19Z sur 7e3c39c)
```

`7e3c39c` est la tête **poussée** ; `HEAD` local (`479eee9`) n'ajoute que deux commits `docs(24)`
— **aucun correctif** : les deux échecs ci-dessous sont l'état de la branche.

| # | Étape CI en échec | Fait mesuré sur le runner | Même mesure en local (macOS) |
|---|---|---|---|
| **CI-1** | *Suites de tests (découverte non vide)* → `FAIL(rc=1) plugin/planning-core/scripts/tests/test-workstream-policy.sh` | Cas **A5d** (borne d'octets du canal nominal, ADR-064 amendée) : `long: rc=0 raison= nom=[] / court: rc=0 nom=[aaaa]`. Un `GSD_WORKSTREAM` de **200 000 octets** n'est **pas refusé pour sa taille** — la garde `[ "${#raw}" -gt "$VF_WS_VALUE_MAX_BYTES" ]` (`workstream-policy.sh:286-290`) ne se déclenche pas, la valeur arrive vide. Bilan de l'étape : **52 suites, 1 échec**. | `bash plugin/planning-core/scripts/tests/test-workstream-policy.sh` → **rc=0, 14 ok / 0 ko / 0 skip**. La garde se déclenche. |
| **CI-2** | *Gates workstream-aware sur un arbre RÉELLEMENT partitionné* → assertion **R1** | « check-dev-bootstrap racine : la sortie **CHANGE** selon `GSD_WORKSTREAM` sur un arbre NON partitionné — la résolution de workstream a fui hors de son domaine ». C'est exactement le contrat de **non-régression** que `GSDA-13` promet. | `a=$(check-dev-bootstrap.sh); b=$(GSD_WORKSTREAM=dev check-dev-bootstrap.sh)` → `rc 3/3`, **169 / 169 octets, sorties identiques** → invariance tenue. |

**Pourquoi c'est un gap Nyquist et pas un simple bug** : les 52 suites vertes en local ont servi de
signal pendant toute l'exécution de la phase. Ce signal était **aveugle à la plateforme de
référence**. C'est la répétition exacte de l'incident de portabilité macOS→Linux de juillet 2026
(6 correctifs, CI réparée le 2026-07-27) : un échantillonnage qui ne couvre pas la cible ne mesure
rien de ce qui compte.

**Ces deux échecs sont hors du pouvoir de ce document** : les corriger demande de toucher
`workstream-policy.sh` et/ou `check-dev-bootstrap.sh` — de l'implémentation, sous validation
humaine (ADR-031). Ils sont **escaladés**, pas contournés, et ils sont la raison n°1 du `false`.

---

## Gaps d'échantillonnage — les 5 assertions de plan qui ne rejouent pas vertes

Chaque rouge a été **décomposé clause par clause** pour distinguer « le livrable manque » de
« l'assertion est fausse ». Dans les 5 cas, c'est le second — vérifié de première main.

| # | Plan / tâche | Clause en échec | Diagnostic mesuré | Le livrable est-il là ? |
|---|---|---|---|---|
| **G1** | 24-02 T1 | `/strictement supérieure à 1\.9\.1/` sur `docs/ADR.md` | **Littéral coupé par un retour à la ligne** : `docs/ADR.md:1646` ferme sur « … une version strictement », la suite est ligne 1647. Une assertion `awk` ligne-à-ligne ne peut pas la voir. Les 5 autres clauses sont à 1, l'index `\| ADR-066 \|` rend `n=1`. | ✅ oui — ADR-066 § Note de veille |
| **G2** | 24-02 T2 | `/69 ?%/` sur `docs/ADR.md` | **L'assertion pin un chiffre que l'ADR ne porte pas** : `docs/ADR.md:1677` écrit « **275 / 400 — 68 %** ». Corollaire : c'est le chiffre que le warning **W3** de `24-VERIFICATION.md` déclare non reproductible (re-dérivation → 76 %). L'assertion contredit l'ADR, et l'ADR contredit la mesure — trois valeurs pour un seul fait. | ✅ oui — ADR-067 existe et est indexée |
| **G3** | 24-02 T3 | `/strictement supérieure à 1\.9\.1/` sur `CONCERNS.md` | Même défaut que G1, même littéral, autre fichier. Les 3 autres clauses (`ADR-066`, `windows_enforce`, `workflow_guard`) sont à 1. | ✅ oui |
| **G4** | 24-07 T1 | `ENDFILE{…}` | **Extension `gawk` non portable** : l'`awk` de ce poste (BWK/BSD) ne connaît pas `ENDFILE`, la commande ne produit aucune ligne, et le garde-fou aval `NR>0` rougit. Défaut de l'assertion, indépendant du contenu. Miroir exact de CI-1/CI-2 : **une assertion verte ici serait rouge là-bas, et réciproquement.** | ✅ oui — ADR-068 volet 2 porte la mesure |
| **G5** | 24-10 T2 | `awk '/^### Phase /{n++} END{exit !(n==26)}'` | **Piège d'univers dans l'assertion elle-même** : re-dérivé → `^### Phase ` = **13**, `^#### Phase ` = **13**, total **26**. Le motif ne voit qu'une profondeur, compte 13, échoue contre `n==26`. Les 8 clauses du volet ADR-069 sont **toutes à 1**. C'est le cinquième piège d'univers de la phase. | ✅ oui — ADR-069 complète |

**Correction suggérée, non appliquée** (les `*-PLAN.md` sont des artefacts historiques d'une phase
exécutée : les réécrire a posteriori maquillerait la trace) :

- G1 / G3 — pinner un littéral qui ne franchit pas de retour à la ligne, ou assertion multi-ligne.
- G2 — trancher entre l'assertion (`69 %`), l'ADR (`68 %`) et la re-dérivation (`76 %`) ; W3 demande
  déjà d'inscrire dans ADR-067 la commande qui rend le chiffre.
- G4 — remplacer `ENDFILE` par `FILENAME != prev {…}` + bloc `END` (portable BSD **et** gawk).
- G5 — compter les deux profondeurs (`/^#{3,4} Phase /`) ou nommer explicitement l'univers visé.

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* Aucune installation de framework : les
suites préexistaient ou ont été créées par les plans (24-05 pour `test-check-workstream-pointer.sh`,
24-11 pour `test-check-capability-activation.sh`).

**Correction d'univers n°1** : la phase touche **11** suites, non 10. Le compte de 10 omet
`scripts/tests/test-check-machine-paths.sh`, hors de `plugin/`.
Commande : `git diff --name-only fbdb300..HEAD -- '*/tests/test-*.sh' | awk '/tests\/test-/{n++} END{print n}'` → **11**.

Toutes vertes en local le 2026-08-05 (`rc` et durées chronométrés de première main) :

| Suite | rc | Résultat | Durée |
|---|---|---|---|
| `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | 0 | **184 OK / 0 KO / 0 SKIP** | 24 s |
| `plugin/conductor/scripts/tests/test-check-agents.sh` | 0 | **81 OK / 0 KO** | 3 s |
| `plugin/conductor/scripts/tests/test-check-state-integrity.sh` | 0 | **40 ok / 0 ko** | 5 s |
| `plugin/conductor/scripts/tests/test-check-workstream-pointer.sh` | 0 | **24 ok / 0 ko** | 1 s |
| `plugin/conductor/scripts/tests/test-guard-agent-write.sh` | 0 | **14 OK / 0 KO** | 1 s |
| `plugin/dev-orchestrator/scripts/tests/test-check-capability-activation.sh` | 0 | **29 OK / 0 KO** | 1 s |
| `plugin/dev-orchestrator/scripts/tests/test-check-dev-bootstrap.sh` | 0 | **35 ok / 0 ko** | 1 s |
| `plugin/planning-core/scripts/tests/test-planning-context-hardening.sh` | 0 | **38 passés / 0 échoués** | 1 s |
| `plugin/planning-core/scripts/tests/test-workstream-policy.sh` | 0 | **14 ok / 0 ko / 0 skip** | 4 s | 
| `plugin/planning-core/scripts/tests/test-workstream-symlink-escape.sh` | 0 | **10 ok / 0 ko** | 1 s |
| `scripts/tests/test-check-machine-paths.sh` | 0 | **19 OK / 0 KO** | 1 s |

⚠️ **Deux lignes de ce tableau sont fausses sur le runner Linux** (`test-workstream-policy.sh`,
et `test-check-dev-bootstrap.sh` via l'assertion R1 du job de gates) — voir §Gaps de plateforme.

**Dépôt entier, en local** : `52 suites, 0 échec, 110 s` (boucle sur la découverte exacte de la CI).
**Dépôt entier, sur le runner** : `52 suites, 1 échec`.

Aucun drapeau de mode veille (`--watch`, `entr`, `nodemon`) : **0** occurrence sur les 11 suites.

**Correction d'univers n°2** : `10` modules ont leur `VERSION` bumpée sur la branche
(`git diff --name-only fbdb300..HEAD -- 'plugin/*/VERSION' | awk 'END{print NR}'` → **10**), sur
**17** modules portant un `module.json`. La triade racine (`VERSION`, `plugin.json`,
`marketplace.json`) est **intacte** — frontière de release non franchie, conforme au gate humain.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|---|---|---|---|
| Les deux skills du slot **PLANNER** sont posées dans le compte de la machine | GSDA-02 | La forme globale nue `global:<skill>` résout par système de fichiers vers le dossier de skills du compte ; un skill absent produit un `WARNING` sur stderr et est **silencieusement écarté**. Dépendance **machine-locale** : elle ne voyage pas avec le plugin. Warning **W4**. | Sur toute machine cible : `gsd-tools agent-skills gsd-planner` doit rendre le bloc `<agent_skills>` avec les **deux** entrées et **0 warning**. |
| Les six gestes de **release racine** | hors `GSDA` — gouvernance | Gate humain non négociable (`CLAUDE.md` § Discipline de release, ADR-031). Le plan 24-12 garantit seulement que la branche **n'y touche pas**. | Après fusion, sous validation humaine explicite : bump, tag annoté, `gh release create`, puis `bash scripts/check-release-tag.sh --remote` → `✓`. |
| La recette humaine **XcodeBuildMCP** (fenêtre #3 du ledger) | GSDA-04 | Structurellement infermable sur ce dépôt : aucun `.mcp.json`, aucun projet iOS. Entrée passée `open` → `waived` (`WINDOWS.md`, `waived_count: 1`) et restant visible dans `/gsd-progress`. | Recette sur un lab iOS avec XcodeBuildMCP réellement connecté — hors périmètre de cette phase. |

> **Une ligne a été RETIRÉE de ce tableau** : « le job CI workstream est réellement exercé sur un
> runner ». Elle n'est plus manuelle — le job **a** tourné, et il **échoue**. Le laisser en
> « manual-only » aurait transformé un échec mesuré en attente polie. Il est désormais compté comme
> gap bloquant (CI-2).

---

## Gaps ouverts hors périmètre de ce document

Relevés en re-dérivant, escaladés sans être corrigés (implémentation = ADR-031) :

1. **Zéro marge sur le gate de démarrage.** Le gap n°1 de `24-VERIFICATION.md` (frontmatter de
   `.planning/STATE.md` au-delà de la garde de 60 lignes, signal rendu muet) **est refermé** :
   `awk 'NR>1 && /^---[[:space:]]*$/{print NR; exit}' .planning/STATE.md` → **60**, et
   `check-dev-bootstrap.sh` reparle (`rc=3` + orientation `gsd-engine`, 169 octets). Mais la garde
   est `NR > 60 { exit }` (`:215`) : le délimiteur ferme **exactement** sur la dernière ligne lue.
   **Une seule ligne ajoutée au frontmatter re-muselle le signal**, et
   `grep -n '60' plugin/dev-orchestrator/scripts/tests/test-check-dev-bootstrap.sh` → **0
   correspondance** : aucune assertion ne garde la longueur du `STATE.md` réel. La dette a été
   payée sans qu'on pose le tripwire qui l'empêche de revenir.
2. **M2, voie 2, toujours absente.** La voie 1 est livrée depuis la vérification
   (`team-kernel.md:64-65` porte désormais la conséquence doctrinale intra-étape / inter-nœuds).
   La voie 2 non : `grep -rl backgroundDispatch .planning/upstream/` → **aucun fichier**, le seul
   artefact du dossier reste celui des 42 workflows aveugles (GSDA-19). M2 n'est porté par aucune
   des 22 exigences — il ne peut donc pas faire baisser la couverture `GSDA`, mais il reste un
   livrable du lot MESURE affirmé et non produit.

---

## Validation Sign-Off

- [x] **All tasks have `<automated>` verify or Wave 0 dependencies** — **32 tâches sur 32**, aucune
      exception ; union des `requirements:` = **GSDA-01..22**, soit 22/22.
- [x] **Sampling continuity: no 3 consecutive tasks without automated verify** — plus longue série
      sans verify = **0**. Mesuré tâche par tâche sur les 12 plans, pas déduit d'un total.
- [x] **Wave 0 covers all MISSING references** — aucune référence manquante, **0 MISSING**.
- [x] **No watch-mode flags** — 0 occurrence sur les 11 suites de la phase.
- [x] **Feedback latency < 60 s** — **24 s** mesurés au pire cas, sur ce poste.
- [ ] **Les commandes d'échantillonnage sont vertes sur la plateforme de référence** — **NON.**
      **2 étapes CI en échec** sur la tête poussée, touchant 3 exigences. C'est le gap bloquant.
- [ ] **`nyquist_compliant: true` set in frontmatter** — **délibérément laissé à `false`.**
      Trois motifs cumulés, aucun fabriqué :
      **(a)** la CI est rouge (CI-1, CI-2) — l'échantillonnage n'a jamais couvert la plateforme de
      référence, et il y a un **défaut de comportement réel** derrière, pas un artefact de test ;
      **(b)** **5 commandes sur 32** sont rouges sur `HEAD` (G1→G5), touchant 4 exigences ; au
      critère amont, « No gaps » n'est pas atteint ;
      **(c)** ce contrat est écrit **après** l'exécution — il n'a pu gouverner aucune décision
      d'échantillonnage pendant celle-ci, et cette réserve n'est pas rattrapable rétroactivement.

**Approval:** validated 2026-08-05 — *avec les réserves ci-dessus.* Aucune exigence `GSDA` n'est
découverte **non livrée**. Mais **la phase ne peut pas être shippée en l'état** : `/gsd-ship`
suppose une CI verte, et elle ne l'est pas. Les 5 gaps d'assertion (G1→G5) sont documentaires et
n'empêchent rien ; les 2 gaps de plateforme (CI-1, CI-2) sont bloquants et demandent un correctif
d'implémentation sous validation humaine.

---

_Renseigné : 2026-08-05, sur `HEAD` = `479eee9`._
_Méthode : ré-extraction mécanique des 32 blocs `<automated>` des 12 `*-PLAN.md` (`re.finditer` +
`html.unescape`), ré-exécution depuis la racine, décomposition clause par clause des 5 rouges ; les
11 suites de la phase et les 52 du dépôt chronométrées de première main ; les 4 runs CI lus via
`gh run view --log-failed`, jamais supposés. `grep`/`find` étant proxifiés et tronquants sur ce
poste, tous les comptes sont faits en `awk 'END{print NR}'` et croisés sur deux formes quand le
nombre est porteur — c'est ainsi que les deux corrections d'univers (11 suites, non 10) ont été
trouvées._
