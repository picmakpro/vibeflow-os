---
phase: 13-pont-spec-feuille-de-route
verified: 2026-07-26T01:35:26Z
status: human_needed
score: 4/4 critères de succès dans le mandat vérifiés (SC5 hors mandat) · 3/3 BRDG · 22/22 must-haves de plan
overrides_applied: 0
re_verification:
  previous_status: null
  previous_score: null
  gaps_closed: []
  gaps_remaining: []
  regressions: []
gaps: []
deferred:
  - truth: "Critère de succès 5 — Release livrée : CHANGELOG/README des modules à jour, bump racine + tag annoté poussé (check-release-tag.sh --remote → ✓)"
    addressed_in: "Post-phase — validation humaine explicite (hors mandat de la mission, 13-02-PLAN.md § « Release hors périmètre »)"
    evidence: "13-02-PLAN.md l.254-257 : « la VERSION racine, plugin.json, marketplace.json et le tag git restent explicitement intouchés — le critère de succès 5 du ROADMAP est un reste-à-faire post-plan réservé à validation humaine ». État prêt-à-release vérifié : module v2.2.0 cohérent, racine intouchée à v2.36.2, check-version-sync ✓, check-release-tag ✓."
human_verification:
  - test: "Décider et exécuter la release racine : bump VERSION/plugin.json/marketplace.json + historique des 2 README, puis tag annoté poussé, puis `bash scripts/check-release-tag.sh --remote`"
    expected: "✓ — la capacité d'ingestion v2.2.0 de dev-orchestrator devient installable par référence"
    why_human: "Décision de release explicitement réservée à validation humaine par le plan 13-02 ; hors mandat de cette vérification"
  - test: "Smoke test agentique réel : dans un lab avec une spec orpheline sous docs/superpowers/specs/, demander à vibeflow-dev « intègre cette spec à la feuille de route »"
    expected: "L'agent appelle discover-unintegrated-docs.sh, annonce N documents + grains + moteur ciblé, ATTEND la confirmation, puis invoque gsd-ingest-docs --mode merge --manifest <tmp hors .planning/>"
    why_human: "Les 4 garde-fous BRDG-03 sont doctrinaux (prose chargée on-demand). Aucun grep ne prouve que l'agent les respecte à l'exécution — seul un essai réel le montre."
  - test: "Décider du sort du lock de driver résiduel `.planning/DRIVER.lock/` (owner=mission-phase13, step=planification, acquis 2026-07-26T02:41:20) et de `.planning/missions/dag-phase13.json`"
    expected: "Lock relâché (sinon la prochaine mission d'équipe peut être bloquée), et décision prise : versionner ou .gitignore"
    why_human: "Un lock détenu peut être légitime si la mission phase 13 est encore considérée en cours ; le relâcher est une décision d'orchestration, pas de vérification"
---

# Phase 13 : Pont spec → feuille de route — Rapport de vérification

**Goal ROADMAP** : « Outiller le passage d'un cadrage écrit aux étapes de la feuille de route — une spec
devient des étapes + des exigences, un plan devient le plan d'une étape — en déléguant aux moteurs GSD
existants et sans contourner leurs garde-fous. »

**Vérifié** : 2026-07-26T01:35:26Z
**Statut** : `human_needed` (aucun gap bloquant ; 3 items réservés à décision humaine)
**Re-vérification** : Non — vérification initiale
**Base du diff** : `e5127b9` (v2.36.2) → `HEAD` (`7a39cf4`), 9 commits, 16 fichiers, +998/-10

> Note de méthode : aucun `13-01-SUMMARY.md` ni `13-02-SUMMARY.md` n'existe. Cette vérification n'a donc
> **aucun récit à croire** — chaque verdict ci-dessous est adossé à une commande exécutée pendant la
> vérification et à sa sortie réelle. Quatre **tests de mutation** ont été menés sur le script livré pour
> écarter l'hypothèse de tests tautologiques.

---

## 1. Critères de succès du ROADMAP

| # | Critère | Statut | Commande / preuve |
|---|---------|--------|-------------------|
| 1 | Deux grains traités : spec → `gsd-ingest-docs --mode merge`, plan → `gsd-import --from`, sans parseur maison | **ACHIEVED** | `ingestion-flow.md:56-65` (§ Délégation) + contrat moteur corroboré : `~/.claude/get-shit-done/workflows/ingest-docs.md:6,29` (`--mode new\|merge`), `import.md:5,27` (`--from`). Aucun parseur de manifest dans le module : `grep -cE 'jq \|python3\|...' discover-unintegrated-docs.sh` → `0`, le script ne lit aucun manifest. |
| 2 | Découverte **outillée** (6 registres, détection du grain), manifest construit par l'agent | **ACHIEVED** | `bash test-discover-unintegrated-docs.sh` → **`16 ok, 0 ko`**, exit 0. Corpus réel : exit **3**, stdout **0 octet**. § « Construction du manifest » de `ingestion-flow.md:35-54` : l'agent écrit le manifest via `mktemp` hors `.planning/`. |
| 3 | Gate BLOCKER jamais contourné · confirmation ADR-031 · `--mode merge` par défaut · cap 50 signalé | **ACHIEVED** (doctrinal) | `ingestion-flow.md:67-86` — 4 garde-fous nommés textuellement. Corroborés côté moteur : `ingest-docs.md:213` (`conflict_gate`), `:219` (`BLOCKERS > 0`), `:333` (jamais d'écriture PROJECT/REQUIREMENTS/ROADMAP/STATE), `:126` (cap dur de 50). Rappel dans `AGENT.md:127-129`. T16 vert. |
| 4 | Fin de cadrage → l'agent propose l'ingestion comme next step, sans ressusciter de verbe | **ACHIEVED** | `git diff` sur `AGENT.md` @@ -97,7 +98,8 : clause insérée **dans la liste existante** « Next steps & hygiène documentaire », aucune nouvelle section. T17 vert. `grep -rn "vf-ingest" plugin/` → 2 occurrences, **aucune** n'est un verbe (cf. §5). |
| 5 | Release livrée : bump racine + tag annoté poussé | **HORS MANDAT — reste-à-faire assumé** | Voir §4 « État prêt-à-release ». Non compté comme échec (13-02-PLAN.md l.254-257). |

**Score dans le mandat : 4/4.**

---

## 2. Exigences BRDG

| Exigence | Statut | Preuve |
|----------|--------|--------|
| **BRDG-01** — spec via `gsd-ingest-docs --mode merge`, plan via `gsd-import --from`, sans réimplémenter ni contourner | **ACHIEVED** | Doctrine `ingestion-flow.md` § Délégation (l.56-65) + § Interdits (l.88-94, « ces logiques appartiennent à `gsd-ingest-docs`/`gsd-import`, point »). Les deux moteurs existent réellement : `ls ~/.claude/skills/gsd-ingest-docs ~/.claude/skills/gsd-import` → présents ; routés dans `gsd-skills-index.md:29,31`. Schéma `type: SPEC` validé contre `ingest-docs.md:93-104` (`type` ∈ ADR\|PRD\|SPEC\|DOC). |
| **BRDG-02** — découverte outillée sur 6 registres + grain, manifest jamais écrit à la main | **ACHIEVED (bout en bout)** | Script : 142 L, `100755` en index git, `set -uo pipefail` (l.42), aucun `^set -e`. 16/16 tests. **Atteignabilité prouvée par install e2e réelle** (§3). Chaîne : `AGENT.md:157` → `.claude/agents/dev-orchestrator-references/ingestion-flow.md` → `ingestion-flow.md:16-18` → `.claude/scripts/discover-unintegrated-docs.sh`. Les deux chemins résolvent dans un lab installé (vérifié, pas déduit). |
| **BRDG-03** — 4 garde-fous préservés + ingestion proposée en fin de cadrage | **ACHIEVED (doctrinal)** | `ingestion-flow.md:67-86` + `AGENT.md:127-129` + clause next-step `AGENT.md:98-99`. T16 vérifie la présence textuelle des 4. Réserve : l'application à l'exécution relève du comportement agentique — non grep-able, routée en vérification humaine. |

**Score : 3/3.** Aucune exigence orpheline : `REQUIREMENTS.md` mappe BRDG-01/02/03 sur la Phase 13 ; 13-01 déclare `[BRDG-02]`, 13-02 déclare `[BRDG-01, BRDG-03]` — couverture complète.

---

## 3. Must-haves des plans (22 vérités, une commande chacune)

### Plan 13-01 (12 vérités)

| # | Vérité | Statut | Commande → sortie |
|---|--------|--------|-------------------|
| 1 | Script existe, exécutable, `set -uo pipefail` sans `set -e` | ✓ VERIFIED | `git ls-files -s` → `100755 …`, `test -x` → OUI ; `grep -c 'set -uo pipefail'` → 1 (l.42) ; `grep -c '^set -e'` → **0** |
| 2 | Sortie déterministe `grain<TAB>chemin`, triée | ✓ VERIFIED | Fixture 1 doc → `od -c` : `s p e c \t d o c s / …` — **tabulation réelle**, pas un espace. `LC_ALL=C sort` l.141 |
| 3 | 3 exits 0/3/64 | ✓ VERIFIED | `--nope` → **64** · `--path` **sans valeur** → **64** (durcissement l.51-54) · `--path $(mktemp -d)` → **3** · corpus réel → **3** · fixture 1 doc → **0** |
| 4 | 6 registres couverts | ✓ VERIFIED | l.91-92 énumère les 6 ; cas 1-5 de la suite les exercent **isolément** (un registre à la fois) |
| 5 | `.planning/phases/**` jamais balayé | ✓ VERIFIED | Fixture montée à la main : citation **uniquement** dans `.planning/phases/13-x/13-01-PLAN.md` → `rc=0 out=[spec<TAB>docs/superpowers/specs/2026-01-99-omega-design.md]` — le doc reste non intégré ✓ |
| 6 | Citation sur BASENAME `.md` inclus, **bornée**, jamais sur le stem ni par préfixe | ✓ VERIFIED | l.113 `pat = "[^0-9A-Za-z._-]" esc "[^0-9A-Za-z._-]"` (bornage **bilatéral**) + padding l.116. **Prouvé par mutation** (voir encadré ci-dessous) |
| 7 | Ligne de registre contenant un glob ignorée | ✓ VERIFIED | l.115 `index($0,"/*") > 0 { next }` ; cas 7 vert. *Nuance : branche redondante — voir Finding I-01* |
| 8 | Racines surchargeables par env | ✓ VERIFIED | `VF_INGEST_SOURCES_DIR=… VF_INGEST_PLANNING_DIR=… VF_INGEST_ADR_FILE=…` sur fixture hors repo → `rc=0` puis, après citation dans le registre surchargé, `rc=3`. La surcharge est **honorée dans les deux sens** |
| 9 | Portabilité ADR-054 | ✓ VERIFIED | `grep -cE 'jq \|python3\|grep -P\|sed -i\|mapfile\|realpath\|-printf'` → **0** |
| 10 | Les cas de test passent, 2 suites existantes vertes | ✓ VERIFIED **(sur-livré)** | **`16 ok, 0 ko`** (plan en demandait 12 — 4 cas de durcissement ajoutés après revue). `test-dev-orchestrator.sh` → `30 OK / 0 KO / 0 SKIP`. `test-inject-mcp-tools.sh` → `10 OK, 0 KO` |
| 11 | Corpus réel (9 documents) : aucun faux positif | ✓ VERIFIED | `ls docs/superpowers/{specs,plans}/*.md \| wc -l` → **9** (7 specs + 2 plans). Script → **exit 3**, `wc -c` stdout → **0** |
| 12 | Fixture d'auto-sabotage par glob | ✓ VERIFIED | Cas 7 vert (`out` = le doc, donc **non** marqué cité) |

> ### Tests de mutation — les cas de durcissement sont-ils tautologiques ?
>
> Copie du script mutée dans un bac à sable, suite relancée telle quelle contre le mutant :
>
> | Mutant | Mutation appliquée | Résultat suite | Verdict |
> |---|---|---|---|
> | **A** | Borne **gauche** retirée (`pat = esc "[^…]"`) | `15 ok, 1 ko` — **✗ cas 13** | Cas 13 (`redesign.md` ne cite pas `design.md`) est **load-bearing** |
> | **B** | Borne **droite** retirée (`pat = "[^…]" esc`) | `15 ok, 1 ko` — **✗ cas 14** | Cas 14 (`alpha.mdx` ne cite pas `alpha.md`) est **load-bearing** |
> | **C** | Échappement ERE neutralisé (`if (0)`) | `15 ok, 1 ko` — **✗ cas 15** | Cas 15 (basename `notes[draft.md`) est **load-bearing** |
> | **D** | Filtre glob retiré (`index($0,"/*")` supprimé) | `16 ok, 0 ko` — **survit** | Branche **non couverte** — cf. I-01 |
>
> Conclusion : le bornage bilatéral et l'échappement ERE annoncés après revue sont **réellement testés**,
> pas décorés. Trois mutants sur quatre sont tués par un cas dédié.

### Plan 13-02 (10 vérités)

| # | Vérité | Statut | Commande → sortie |
|---|--------|--------|-------------------|
| 1 | Doctrine : appel du script + 3 exits interprétés | ✓ VERIFIED | `ingestion-flow.md:16-33` — script nommé dans le **corps**, exits 0/3/64 explicités un par un avec leur sens |
| 2 | Doctrine : manifest YAML `docs:[{path,type: SPEC}]` en tmp hors `.planning/` via `mktemp`, puis `gsd-ingest-docs --mode merge --manifest` | ✓ VERIFIED | `ingestion-flow.md:44-54` (schéma verbatim + `mktemp` + interdiction `.planning/`) et l.58-59 |
| 3 | Doctrine : `gsd-import --from <chemin>` pour le grain plan, sans manifest | ✓ VERIFIED | `ingestion-flow.md:60-61` |
| 4 | 4 garde-fous BRDG-03 écrits noir sur blanc | ✓ VERIFIED | `ingestion-flow.md:69-86` — BLOCKER / ADR-031 / `--mode merge` / cap 50, un item chacun |
| 5 | Next step en fin de cadrage, **sans nouvelle section** | ✓ VERIFIED | `git diff` @@ -97,7 +98,8 : la clause est insérée dans la liste existante ; diff total AGENT.md = **+7 −1** ligne, aucune section créée |
| 6 | AGENT.md ≤ 250 lignes (ADR-029) | ✓ VERIFIED | `wc -l plugin/dev-orchestrator/AGENT.md` → **158** (marge 92) ; T3/T5 le re-mesurent |
| 7 | `intent-routing.md` renvoie vers `ingestion-flow.md` | ✓ VERIFIED | l.53 enrichie **en place** (`+1 −1`, pas de ligne dupliquée) |
| 8 | Aucun verbe-façade `/vf-ingest` ni `/vf-*` introduit | ✓ VERIFIED | Voir §5 |
| 9 | T16/T17 ajoutés et verts, sans régression T1..T15 | ✓ VERIFIED | `test-dev-orchestrator.sh` → **`30 OK / 0 KO / 0 SKIP`**, T16 ✓ et T17 ✓ (lignes 604-639) |
| 10 | Module bumpé v2.2.0 cohérent, racine intouchée | ✓ VERIFIED | Voir §4 |

---

## 4. État prêt-à-release (SC5 hors mandat)

| Contrôle | Commande | Sortie |
|---|---|---|
| Module `VERSION` | `cat plugin/dev-orchestrator/VERSION` | `v2.2.0` |
| Module `module.json` | `grep '"version"'` | `"version": "v2.2.0"` |
| Module `README.md` | `grep '^\*\*Version\*\*'` | `**Version** : v2.2.0` (l.10) |
| Module `CHANGELOG.md` | `head -12` | `## [v2.2.0] — 2026-07-26` en tête, section `### Ajouté` décrivant le câblage BRDG-01/03 |
| Racine **intouchée** | `git diff --stat e5127b9..HEAD -- VERSION plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json` | **vide** — `VERSION` racine reste `v2.36.2` |
| Cohérence globale | `bash scripts/check-version-sync.sh` | **15 ✓, exit 0** — dont « triade par module : 17 modules VERSION ↔ module.json alignés », « suites 38 » |
| Tag de la version courante | `bash scripts/check-release-tag.sh` | `✓ VERSION=v2.36.2 ↔ tag v2.36.2`, exit 0 |
| Compte de suites CI | `find plugin scripts -path '*/tests/test-*.sh' \| wc -l` | **38** — README racine FR+EN synchronisés 37 → 38 (commit `7f17c03`) ; `ci.yml:32` découvre les suites **dynamiquement**, la nouvelle suite est donc prise sans édition |
| Non-régression globale | boucle sur les 38 suites | **0 suite en échec / 38** |

**Verdict : le repo est dans un état prêt-à-release propre.** Le bump racine + tag reste entier et
n'a été ni amorcé ni pollué.

---

## 5. Garde-fou anti-façade (`/vf-*` supprimée en v2.33.0)

```
grep -rn "vf-ingest" plugin/
→ plugin/dev-orchestrator/CHANGELOG.md:135
→ plugin/dev-orchestrator/references/ingestion-flow.md:90
```

| Fichier | Compte | Nature | Verdict |
|---|---|---|---|
| `AGENT.md` | **0** | — | ✓ |
| `references/intent-routing.md` | **0** | — | ✓ |
| `references/ingestion-flow.md` | **1** | « **Aucun** verbe-façade `/vf-ingest` n'existe ni ne doit être introduit — la façade a été **supprimée** en v2.33.0 » (§ Interdits, l.90) | ✓ **négation licite** — `grep -E "vf-ingest" … \| grep -qE "supprimée\|aucun"` → exit 0 |
| `CHANGELOG.md:135` | 1 | Entrée historique **v2.0.0** (« son verbe n'est pas encore écrit ») | ✓ **préexistante** — `git show e5127b9:…CHANGELOG.md \| grep -c` → 1. Le diff de la mission n'ajoute **aucune** occurrence hors les 5 lignes de doctrine/plan, toutes en négation |
| Lab installé (e2e) | 1 | Seule la négation de `ingestion-flow.md` | ✓ |
| Nouveaux `commands/` ou `skills/` | **0** | `git diff --name-only e5127b9..HEAD \| grep -E "commands/\|skills/"` → aucune | ✓ |

Aucun verbe-façade réintroduit. Aucune commande d'incarnation créée.

---

## 6. Install end-to-end (atteignabilité réelle de BRDG-02)

Install jouée dans un lab temporaire vierge (`VIBEFLOW_CACHE` pointé sur une copie du module) :

```
install rc=0
.claude/scripts/discover-unintegrated-docs.sh      → présent, exécutable (test -x → OUI)
  → bash …/discover-unintegrated-docs.sh --path $LAB  → rc=3 (lab vide, comportement nominal)
.claude/agents/dev-orchestrator.md                  → présent
.claude/agents/dev-orchestrator-references/ingestion-flow.md → présent
```

Les deux chemins que la doctrine annonce (`ingestion-flow.md:16-18` pour le script,
`AGENT.md:157` pour la doctrine) **résolvent réellement** dans un lab installé — corroboré par
`vibeflow-update.sh:75-76` (`TARGET_ROOT=.claude`), `:342-343` (scripts → `TARGET_ROOT/scripts`),
`:514-516` (references → `TARGET_ROOT/agents/<mod>-references`).

C'est le point qui distingue « le script existe » de « l'agent peut l'atteindre ». **Il est atteignable.**

---

## 7. Suites de tests — chiffres réels

| Suite | Commande | Résultat | Attendu | Verdict |
|---|---|---|---|---|
| Découverte (BRDG-02) | `bash plugin/dev-orchestrator/scripts/tests/test-discover-unintegrated-docs.sh` | **`== résultat : 16 ok, 0 ko ==`**, exit 0 | 16/0 | ✓ |
| Module dev-orchestrator | `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | **`== résultat : 30 OK / 0 KO / 0 SKIP ==`**, exit 0, T16 ✓ T17 ✓ | 30/0/0 | ✓ |
| Injection MCP | `bash plugin/dev-orchestrator/scripts/tests/test-inject-mcp-tools.sh` | **`Bilan : 10 OK, 0 KO`**, exit 0 | 10/0 | ✓ |
| ADR-044 (agents) | `bash plugin/conductor/scripts/check-agents.sh --file plugin/dev-orchestrator/AGENT.md` | **`✓ agents conformes` · 3 warning(s)**, exit 0 | vert | ✓ |
| ADR-044 (équipe) | `… --strict --agents-dir=plugin/dev-orchestrator/agents` | **`✓ agents conformes` · 4 warning(s)**, exit 0 | vert | ✓ |
| Synchro versions | `bash scripts/check-version-sync.sh` | **15 ✓, exit 0** | vert | ✓ |
| Non-régression repo | boucle sur les 38 suites | **0 échec / 38** | — | ✓ |

*Note : `bash plugin/conductor/scripts/check-agents.sh` sans argument sort `aucun agent dans
.claude/agents — rien a verifier` (exit 0) : ce repo est le repo de **distribution**, il n'a pas de
`.claude/agents/`. Le contrôle utile a donc été rejoué en `--file` sur `AGENT.md` (le fichier modifié)
et en `--agents-dir` sur les 4 agents d'équipe. Les warnings sont préexistants et non bloquants
(`skills:` absent, `name` ≠ nom de fichier — normal, `AGENT.md` est renommé `dev-orchestrator.md` à
l'install).*

---

## 8. Anti-patterns

| Contrôle | Résultat |
|---|---|
| `TBD` / `FIXME` / `XXX` dans les 16 fichiers du diff | **0** |
| `TODO` / `HACK` / `PLACEHOLDER` | **0** |
| Fichier stub / doctrine creuse | Aucun — `ingestion-flow.md` = 94 L de prose dense, chaque affirmation corroborée contre le moteur réel (§1, §2) |
| Chemin annoncé mais non résolvable | Aucun — les 2 chemins de la doctrine vérifiés par install e2e (§6) |

---

## 9. Findings

| Sévérité | Réf | Action | Description |
|---|---|---|---|
| ⚠️ WARNING | **W-01** | Exécuter le nœud `hygiene-13` | **Hygiène doc non faite.** `STATE.md` (`stopped_at` : « plan 13-01 … à exécuter ; 13-02 à planifier », `completed_plans: 13`, `percent: 67`), `ROADMAP.md:265` (« 13-01 … à exécuter · 13-02 … à planifier »), `REQUIREMENTS.md:168-177` (BRDG-01/02/03 toujours `- [ ]`) et le tableau de statut l.281-283 (« Not started » / « In progress ») décrivent tous un état **antérieur** au travail livré. Non bloquant : le DAG place `hygiene-13` en aval de `verify-13`, il est **séquencé, pas oublié**. |
| ⚠️ WARNING | **W-02** | Produire `13-01-SUMMARY.md` et `13-02-SUMMARY.md` | Aucun SUMMARY pour les deux plans exécutés. La phase n'est pas formellement close côté GSD, et le prochain lecteur n'aura aucune trace narrative des écarts (ex. 12 cas de test planifiés → 16 livrés). |
| ⚠️ WARNING | **W-03** | Relâcher ou assumer le lock | `.planning/DRIVER.lock/` détenu (`owner=mission-phase13`, `step=planification`, acquis `2026-07-26T02:41:20`) — non versionné et **non couvert par `.gitignore`**. Un lock résiduel peut bloquer la prochaine mission d'équipe. |
| ℹ️ INFO | **I-01** | Optionnel | Le filtre glob (`index($0,"/*") > 0 { next }`, l.115) **survit à sa suppression** : le mutant D passe `16 ok, 0 ko`. Le cas 7 est en réalité satisfait par le bornage seul. C'est cohérent avec l'intention déclarée du plan (« défense en profondeur… la ligne est déjà inerte »), mais la branche n'est **pas couverte** : un 17ᵉ cas devrait exercer une ligne où le glob est le **seul** rempart. |
| ℹ️ INFO | **I-02** | Optionnel | `.planning/missions/dag-phase13.json` non versionné ni ignoré. Il porte `review-13-01: "failed"` jamais repassé à `done`/`superseded` après `fix-13-01: "done"` — un lecteur futur croira la revue toujours en échec. |
| ℹ️ INFO | **I-03** | Optionnel | `CHANGELOG.md:135` (entrée v2.0.0) annonce encore `/vf-ingest` comme « à l'étape suivante, son verbe n'est pas encore écrit ». Historique, donc immuable par convention — mais désormais contredit par v2.33.0. Une note d'obsolescence dans l'entrée v2.2.0 lèverait l'ambiguïté. |
| ℹ️ INFO | **I-04** | Optionnel | Quand `VF_INGEST_SOURCES_DIR` pointe **hors** de `--path`, le chemin émis est absolu (le `case "$rel" in "$ROOT"/*` de l.128-130 ne s'applique pas). Sans effet en production (mécanisme réservé aux fixtures), mais le contrat « chemin relatif à la racine scannée » n'est pas tenu dans ce cas. |

**Aucun BLOCKER.**

---

## 10. Nœuds débloqués

- **`hygiene-13`** (DAG `dag-phase13.json`, statut `blocked`, deps `[audit-13, verify-13]`) : le volet
  `verify-13` est **rendu** par ce rapport. Le nœud devient exécutable dès qu'`audit-13` est rendu.
- **Reste-à-faire release (SC5)** : le socle est propre et complet (module v2.2.0 cohérent, racine
  intacte, 38/38 suites vertes, `check-version-sync` ✓). La release racine + tag annoté est **débloquée
  techniquement** et n'attend plus qu'un arbitrage humain.
- **Milestone `vf-routing`** : Phase 13 était la dernière phase non livrée (12 et 14 déjà complètes et
  taguées). Une fois W-01/W-02 traités, le jalon est en position de clôture.

---

## 11. Recommandation

**Oui — la Phase 13 peut être déclarée complète hors release**, sous réserve de fermer trois items de
tenue de registre (W-01, W-02, W-03) qui ne touchent pas la capacité livrée.

Ce que la vérification a réellement établi, au-delà de « les fichiers existent » :

1. Le **fait outillé tient ses promesses** : le durcissement post-revue (bornage bilatéral, échappement
   ERE, exit 64 sur `--path` sans valeur) est **prouvé par mutation** — 3 mutants sur 4 tués par un cas
   dédié. Les cas 13/14/15 ne sont pas décoratifs.
2. **BRDG-02 est satisfait de bout en bout**, pas seulement « le script existe » : l'install e2e dans un
   lab vierge montre que les deux chemins annoncés par la doctrine résolvent, que le script y est
   exécutable et fonctionnel, et que la chaîne `AGENT.md → ingestion-flow.md → .claude/scripts/` est
   réellement parcourable par l'agent.
3. **La doctrine n'est pas de la fiction** : chacune de ses affirmations sur les moteurs (`--mode merge`,
   `--manifest` avec `type: SPEC`, cap dur de 50, `conflict_gate` qui n'écrit jamais
   PROJECT/REQUIREMENTS/ROADMAP/STATE si `BLOCKERS > 0`) a été confrontée au workflow réel des skills GSD
   installés et s'y vérifie ligne à ligne.
4. **Aucune façade réintroduite** : zéro `/vf-ingest` dans `AGENT.md` et `intent-routing.md`, une unique
   occurrence en négation dans les « Interdits », zéro nouveau `commands/`/`skills/`.

La limite honnête de cette vérification : les 4 garde-fous BRDG-03 sont **doctrinaux**. Leur présence
textuelle est prouvée, leur respect à l'exécution ne l'est pas et ne peut pas l'être par grep — d'où le
smoke test agentique inscrit en vérification humaine. C'est une propriété du design agentique choisi, pas
un défaut de cette livraison.

---

_Vérifié : 2026-07-26T01:35:26Z_
_Vérificateur : Claude (gsd-verifier), analyse goal-backward, stance adverse — aucun SUMMARY à disposition, tous les verdicts adossés à commande_
