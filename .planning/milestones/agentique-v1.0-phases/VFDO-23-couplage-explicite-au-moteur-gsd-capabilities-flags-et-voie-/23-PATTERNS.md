# Phase 23 : Couplage explicite au moteur GSD — Pattern Map

**Mapped:** 2026-08-01
**Fichiers analysés :** 9 surfaces (+ .planning/config.json, docs/ADR.md)
**Analogs trouvés :** 9 / 9

## Classification des fichiers

| Fichier neuf/modifié | Rôle | Flux de données | Analogue le plus proche | Qualité du match |
|---|---|---|---|---|
| `plugin/dev-orchestrator/references/GSD-PIPELINE.md` | référence doctrinale (markdown, chargée on-demand) | transform (doctrine → table de décision lue par les agents) | lui-même (édition en place, sections existantes §1/§6/§8) | exact — extension d'un fichier déjà dans le patron cible |
| `plugin/dev-orchestrator/scripts/build-gsd-capabilities-index.sh` (NOUVEAU) | générateur idempotent | batch (lecture CLI amont → écriture markdown) | `plugin/dev-orchestrator/scripts/build-gsd-index.sh` | exact — même rôle, même flux (générateur → fichier `references/*-index.md`) |
| `plugin/dev-orchestrator/references/gsd-capabilities-index.md` (NOUVEAU, généré) | sortie générée, jamais éditée | — (artefact, pas de logique) | `plugin/dev-orchestrator/references/gsd-skills-index.md` | exact |
| `plugin/dev-orchestrator/scripts/check-gsd-config.sh` (NOUVEAU) | gate advisory (config) | request-response (lit un fichier, répond exit code + signal texte) | `plugin/dev-orchestrator/scripts/check-doc-drift.sh` | exact — même contrat exit 0/3/64, même patron `--hook`/`--quiet` |
| `.planning/config.json` (nettoyage) | config (donnée de projet) | CRUD (suppression de clés, pas d'ajout de structure) | lui-même — édition directe, pas de générateur | exact (fichier de données, pas de code) |
| `plugin/dev-orchestrator/references/mission-contracts.md` | référence doctrinale (contrats typés) | transform (ajout de champs optionnels au contrat JSON documenté) | lui-même — patron déjà écrit §Contrat `estimate:`/`actuals:` (lignes 133-168) pour l'ajout de champs optionnels frères | exact — même geste (ajouter un champ optionnel documenté, jamais recalculé) |
| `plugin/dev-orchestrator/references/mission-flow.md` | référence doctrinale (patterns de pilotage) | event-driven (budgets de boucle, halt conditionnel) | lui-même — Pattern E déjà écrit (§budget 3 tours, §garde-fou machine `dag.sh reopen`) | exact — extension du même Pattern E |
| `plugin/dev-orchestrator/agents/vf-coder.md` | agent (worker interne, prompt markdown + frontmatter `tools:`) | request-response (reçoit un mandat, rend un bloc typé) | lui-même — édition en place (§Le cycle, ligne `tools:`) | exact |
| `plugin/dev-orchestrator/agents/vf-dev-manager.md` | agent (manager, prompt markdown + frontmatter `tools:`) | request-response + event-driven (contrôle de flux sur bloc typé) | lui-même — édition en place (§Contrôle de flux, §Hygiène documentaire, ligne `tools:`) | exact |
| `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` | test (suite bash, assertions maison) | batch (grep discriminant + assertions mutation) | lui-même — blocs T4c / T14b / T14c déjà écrits (discriminance par mutation, fixture injectée) | exact — patron à reproduire pour D-02/D-11 |
| `docs/ADR.md` (extension ADR-061) | doctrine (registre d'ADR) | transform (ajout d'une section « Objet revu #3 » à une ADR existante) | lui-même — ADR-061 déjà écrite avec le critère 3 axes (lignes 1098-1165) | exact |

## Pattern Assignments

### `plugin/dev-orchestrator/scripts/build-gsd-capabilities-index.sh` (générateur, batch)

**Analogue :** `plugin/dev-orchestrator/scripts/build-gsd-index.sh` (138 lignes, patron complet à imiter)

**En-tête + variables surchargeables** (lignes 1-30) :
```bash
#!/usr/bin/env bash
# build-gsd-index.sh — Générateur d'index factuel des skills GSD installés (dev-orchestrator)
#
# Iron Law (D4 — anti-hallucination) : aucun nom de skill n'est écrit en dur.
# L'index est exclusivement extrait du frontmatter des SKILL.md présents sur disque.
#
# Usage:
#   ./build-gsd-index.sh                      # écrit l'index dans references/ (défaut dev)
#   VF_INDEX_OUT=/chemin/index.md ./build-gsd-index.sh   # écrit à un chemin arbitraire
#   VF_GSD_SKILLS_DIR=/tmp/fixtures ./build-gsd-index.sh # source surchargeable (tests)
set -euo pipefail
SKILLS_DIR="${VF_GSD_SKILLS_DIR:-$HOME/.claude/skills}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${VF_INDEX_OUT:-$SCRIPT_DIR/../references/gsd-skills-index.md}"
GSD_CORE_PACKAGE="${VF_GSD_CORE_PACKAGE:-@opengsd/gsd-core@1.9.0}"
```
Pour D-07, remplacer la source (SKILL.md sur disque) par la sortie CLI :
`node $HOME/.claude/gsd-core/bin/gsd-tools.cjs loop render-hooks <point> --raw` sur les 12 points
(`discuss:pre`, `discuss:post`, `plan:pre`, `plan:post`, `execute:pre`, `execute:wave:pre`,
`execute:wave:post`, `execute:post`, `verify:pre`, `verify:post`, `ship:pre`, `ship:post`). Variable
`VF_GSD_TOOLS` (patron `VF_GSD_SKILLS_DIR`) pour surcharger le chemin en test.

**Écriture idempotente, en-tête « NE PAS ÉDITER »** (lignes 111-138) :
```bash
mkdir -p "$(dirname "$OUT")"
generated_at="$(date -Iseconds 2>/dev/null || date "+%Y-%m-%dT%H:%M:%S%z")"
{
  echo "# GSD Skills Index (auto-généré — NE PAS ÉDITER)"
  echo "> Généré le $generated_at par build-gsd-index.sh depuis $GSD_CORE_PACKAGE"
  echo ""
  # ... table markdown ...
} > "$OUT"
log "Index généré : $OUT ($skill_count skill(s) gsd-*)"
```

**Sécurité (V5 Input Validation, ASVS)** : ne jamais recopier `fragment.inline` verbatim (prose
volumineuse destinée à un LLM, pas du markdown sûr) — extraire seulement les métadonnées
structurées (`capId`, `kind`, `when`, `onError`) depuis le JSON `render-hooks --raw`, jamais un
`eval`/shell-out non wrappé sur ce contenu.

---

### `plugin/dev-orchestrator/scripts/check-gsd-config.sh` (gate advisory, request-response)

**Analogue :** `plugin/dev-orchestrator/scripts/check-doc-drift.sh` (153 lignes, patron complet à imiter)

**Contrat exit codes + doctrine ADR-055 §3 en tête de fichier** (lignes 1-60, en-tête entier à
reproduire pour le nouveau script — même densité de commentaire, même justification du FAIT vs
JUGEMENT) :
```bash
# Exit codes:
#   0  = signal [doc-drift] émis (seuil atteint ou dépassé)
#   3  = rien à signaler (hors dépôt git, aucun commit de doc, ou compte < seuil)
#   64 = argument inconnu, --path sans valeur, --threshold sans valeur ou invalide, ou --hook +
#        --quiet ensemble
```
Pour `check-gsd-config.sh` (D-17/D-20) : 0 = au moins un signal (clé inconnue OU toggle décidé
laissé au défaut implicite), 3 = config alignée, 64 = argument invalide (ex. `--path` sans valeur).

**Parsing d'arguments + validation stricte avant toute logique** (lignes 69-102) :
```bash
while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      if [ "$#" -lt 2 ]; then
        echo "[check-doc-drift] --path nécessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    ...
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-doc-drift] argument inconnu : $1" >&2; exit 64 ;;
  esac
done
```

**Fonction `say()` (mode --quiet) et signal final** (lignes 104, 144-153) :
```bash
say() { [ "$QUIET" -eq 1 ] || echo "[check-doc-drift] $*" >&2; }
...
if [ "$COUNT" -ge "$THRESHOLD" ]; then
  say "seuil atteint : ..."
  printf '%s\n' "[doc-drift] ${COUNT} commits de code depuis la dernière mise à jour de la doc."
  printf '%s\n' "            → propose gsd-docs-update."
  exit 0
fi
say "..."
exit 3
```
Pour `check-gsd-config.sh` : signal `[gsd-config]` sur le même modèle (`printf` sur stdout, jamais
sur stderr — le hook `SessionStart` capture stdout comme signal utilisateur).

**Lecture des clés connues DEPUIS gsd-core, jamais en dur** (principe D-17, analogue vérifié dans
`bin/lib/config.cjs:243-273` — lire ce fichier programmatiquement, ex. `node -e "console.log(Object.keys(require('.../config.cjs').CONFIG_DEFAULTS.workflow))"`, plutôt que copier la liste de clés dans le script bash).

**Durcissement git si le script shell-out vers git** (lignes 106-121, `git_safe()` wrapper) — à
reprendre **seulement si** `check-gsd-config.sh` invoque git (ex. pour localiser `.planning/config.json` via `git rev-parse --show-toplevel`) :
```bash
export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0
export GIT_OPTIONAL_LOCKS=0
git_safe() { git -C "$ROOT" -c core.fsmonitor= -c core.hooksPath=/dev/null --no-optional-locks "$@"; }
```

**Câblage `SessionStart`** — analogue exact dans `plugin/dev-orchestrator/hooks/hooks.json` :
```json
{ "type": "command", "command": "bash {{VF_SCRIPTS}}/check-doc-drift.sh --hook || true" }
```
Ajouter une entrée identique pour `check-gsd-config.sh --hook || true` dans le même tableau
`SessionStart[0].hooks`.

---

### `.planning/config.json` (D-18/D-19 — suppression + toggles explicites)

**État actuel exact** (à modifier) :
```json
"gates": {
  "confirm_project": true, "confirm_phases": true, "confirm_roadmap": true,
  "confirm_breakdown": true, "confirm_plan": true, "execute_next_plan": true,
  "issues_review": true, "confirm_transition": true
},
"safety": { "always_confirm_destructive": true, "always_confirm_external_services": true }
```
→ **les deux blocs `gates` et `safety` sont supprimés** (D-18). Le bloc `workflow` gagne les 5
toggles décidés (D-19), absents aujourd'hui :
```json
"workflow": {
  ...,
  "code_review": true,
  "pattern_mapper": true,
  "node_repair": true,
  "node_repair_budget": 2
  // ui_review : NE PAS écrire — absent des défauts amont, résolu par la capability elle-même (D-19 note)
}
```

---

### `plugin/dev-orchestrator/references/mission-contracts.md` (D-01/D-03/D-15/D-28)

**Analogue interne exact — patron des champs optionnels frères** (lignes 154-168, déjà écrit pour
`estimate:`/`actuals:`, à reproduire pour `gate`/verdicts de hooks/décompte de budget) :
```
**Propagation retenue** — le disque reste la source de vérité, mais le bloc typé de `vf-coder`
gagne deux champs **optionnels**, frères de `statut`/`findings`/`noeuds_debloques` :

"estimate": { "tokens": …, "raw_tokens": …, "tasks": …, "confidence": "low|med|high" },
"actuals":  { "tokens": …, "tasks": …, "commits": … }

Présents **uniquement** quand le `PLAN.md`/`SUMMARY.md` du mandat les portait — absents sinon
(aucune valeur inventée, même conditionnalité que l'amont). `vf-coder` les **recopie verbatim**...
```
Réutiliser mot pour mot cette structure pour :
- `"gate": "blocking-human" | …` (D-01) — présent dès qu'un checkpoint est survenu ;
- minimum de reprise D-03 : `plan_id`, type de checkpoint, `gate`, `Awaiting` (PAS les 4 blocs complets) ;
- `"verdicts": { "code_review": "pass|fail|absent", "nyquist": "...", "secure": "..." }` (D-15) ;
- décompte de budget D-28 (tours d'équipe consommés + mention explicite « réparations node_repair amont : invisible, cf. D-26 »).

**Section existante à étendre en place** (lignes 170-177, déjà le patron de renvoi vers une ADR au
lieu de dupliquer la doctrine) :
```
## Étage revue — deux objets disjoints (ADR-060 / ADR-061)
...
Arbitrage complet, avec le critère écrit : `docs/ADR.md` ADR-061.
```
Même geste pour D-13/D-14 (hooks GSD vs `revue-N`/`vf-auditer`) : un pointeur bref vers l'extension
d'ADR-061, jamais une reformulation.

**Contrainte de densité** : `mission-contracts.md` est déjà le plus gros fichier du module (16.1K)
— privilégier le renvoi vers `GSD-PIPELINE.md` plutôt que la copie (cf. RESEARCH §Contrainte
dimensionnante).

---

### `plugin/dev-orchestrator/references/mission-flow.md` (D-23/D-24/D-27/D-28)

**Analogue interne exact — table de moments déclencheurs, gabarit `déclencheur | constat`** —
tirée de `docs-flow.md` (Phase 22), à reproduire à l'identique pour les 4 briques dormantes de D-23
(source réelle : `plugin/dev-orchestrator/references/docs-flow.md:69-75`) :
```
| Déclencheur | Constat |
|---|---|
| **surface publique touchée** | le diff modifie une API, une CLI, une config ou un schéma... |
| **`[doc-drift]` actif** | `check-doc-drift.sh` sort en **exit 0** au démarrage de session... |
| **fin de milestone** | la clôture enchaîne déjà `gsd-audit-milestone` → ... |
| **nouveau module / nouvelle capacité** | un répertoire de module ou un point d'entrée apparaît... |

Aucun déclencheur qui ne tombe est un **état normal**, pas un manque.
```
Même forme pour `gsd-extract-learnings` / `gsd-add-tests` / `gsd-spec-phase` / `gsd-undo`/`gsd-forensics` (D-23), chaque ligne un FAIT constatable (verdict nyquist PARTIEL, absence de SPEC.md, etc.).

**Pattern E existant — budget de tours et garde-fou machine** (lignes 168-246, déjà écrit,
patron exact pour D-27/D-28 — un budget partagé par étape au lieu d'un budget par plan) :
```
Budget **3 tours** ; au-delà, escalade humaine (jamais de raffinage infini) — cette boucle
s'articule sur la MÊME table de pilotage déterministe que le reste du contrôle de flux...
```
```
### 5. Garde-fou de comblement

**Aucun allègement ne s'applique jamais à un diff de comblement...** Garant MACHINE, pas une
consigne : `dag.sh reopen` écrit lui-même `review_regime=full` sur tout nœud `revue-*`/`join-*`
rouvert...
```
D-27 (budget partagé revue+comblement, par étape) et D-28 (`blocked` + décompte complet) s'écrivent
en extension directe de cette section — même vocabulaire « garde-fou machine, pas une consigne ».

---

### `plugin/dev-orchestrator/agents/vf-coder.md` (74 lignes — édition en place)

**Ligne `tools:` actuelle, à purger (D-12)** :
```
tools: Read, Write, Edit, Bash, Glob, Grep, Skill, Agent(vf-reviewer, general-purpose,
gsd-assumptions-analyzer, gsd-phase-researcher, gsd-pattern-mapper, gsd-planner, gsd-plan-checker,
gsd-executor, gsd-codebase-mapper, gsd-verifier, gsd-code-reviewer, gsd-code-fixer, gsd-debugger,
gsd-integration-checker, gsd-nyquist-auditor, gsd-ui-researcher, gsd-ui-checker, gsd-ui-auditor,
gsd-framework-selector, gsd-ai-researcher, gsd-domain-researcher, gsd-eval-planner)
```
→ retirer `gsd-planner` et `gsd-executor` de la liste (D-12), rien d'autre (audit complet différé).

**§Le cycle, points 2 et 3 — voie dégradée à supprimer (D-09)** (lignes 31-33) :
```
2. **Plan** : invoque `gsd-plan-phase` (ou dispatche l'agent `gsd-planner` via l'outil Agent).
3. **Exécution** : invoque `gsd-execute-phase` (ou dispatche `gsd-executor` via l'outil Agent).
   C'est lui qui fait les commits atomiques — dernier appel de ton cycle. ...
```
→ retirer la parenthèse « ou dispatche… » sur les deux lignes. Une seule voie : le skill.

**§Cadrage, gradation `--research` à ajouter (D-05)** (ligne 27, à étendre) :
```
1. **Cadrage** : invoque le skill `gsd-discuss-phase` en mode **non-interactif** (`--auto` /
   mode assumptions). ...
```
→ préciser le critère factuel de gradation `--research`/`--skip-research` (D-05), avec renvoi vers
`GSD-PIPELINE.md` pour la doctrine complète plutôt qu'une reformulation (densité ADR-029, ce fichier
est déjà à 74/75 lignes).

**§Retour — bloc typé existant, à étendre pour porter `gate`** (lignes 65-74, patron exact du champ
optionnel frère, déjà appliqué à `estimate:`/`actuals:` — même geste pour `gate`) :
```
**Termine par le bloc typé** (contrat ADR-053, cf. `dev-orchestrator-references/mission-flow.md`) :
`{ "statut": "passed|gaps_found|human_needed|blocked", "findings": [...], "noeuds_debloques": [...] }`.
```

**D-04bis — vf-coder ne répond jamais aux attentes humaines** : le fichier n'a pas `AskUserQuestion`
dans `tools:` (confirmé) — aucune ligne à retirer, mais **ajouter une phrase explicite** disant que
`safe_resume_gate`/checkpoint interrompu → `human_needed` + attendu, jamais une réponse de `vf-coder`
lui-même (cohérent avec §Cadrage ligne 28-30, déjà ce patron pour le cadrage : « une question de
cadrage… → statut `human_needed` remonté au manager, JAMAIS auto-répondue en silence »).

---

### `plugin/dev-orchestrator/agents/vf-dev-manager.md` (236 lignes — proche du plafond ADR-029/250, édition en place)

**Ligne `tools:` — Finding 1 du RESEARCH, à trancher explicitement au plan** :
```
tools: Read, Write, Bash, Glob, Grep, Skill, AskUserQuestion, Agent(vf-coder, vf-reviewer,
vf-auditer, vf-test-orchestrator, gsd-advisor-researcher, general-purpose, gsd-phase-researcher,
gsd-plan-checker, gsd-planner, gsd-pattern-mapper, gsd-doc-verifier, gsd-doc-writer,
gsd-doc-classifier, gsd-doc-synthesizer, gsd-roadmapper, gsd-integration-checker, vf-crafter,
vf-design-judge)
```
`gsd-planner` y figure aussi (contrairement à `vf-coder`, D-12 ne le nomme pas explicitement pour ce
fichier) — le planner doit choisir : retirer (lecture littérale de D-09) ou consigner pourquoi il
reste (lecture bornée à D-12+Deferred).

**§Contrôle de flux — statut à étendre pour le mapping `gate` (D-01/D-04)** (lignes 152-167,
patron déjà écrit, `human_needed` déjà géré comme un cas de gel de nœud en mode autonome) :
```
- **Verdict d'étape (rapport typé, ADR-053)** : le `statut` du rapport de worker — recoupé au
  `*-VERIFICATION.md` — pilote le flux de façon déterministe : `passed` → `dag.sh mark done` +
  frontière suivante · `human_needed` (ou tout finding `action: ask-user`) → **escalade** (mode
  superviser : checkpoint ; mode autonome : **GELER le nœud porteur** — le laisser
  `blocked`/`failed`, consigner l'escalade au rapport, et ne poursuivre QUE les nœuds
  indépendants ; jamais « continuer » sur un finding qui défie l'intention/la sécurité)...
```
→ D-01 s'y greffe : ajouter la règle unique de mapping (`gate="blocking-human"` OU précondition non
satisfaite ⇒ `human_needed`) juste avant cette ligne. D-04 confirme déjà le comportement décrit
(« GELER le nœud porteur ») — pas de réécriture de fond, juste nommer explicitement le `gate` comme
déclencheur.

**§Entrée — filet de repli AskUserQuestion déjà écrit (D-04bis, à réutiliser tel quel)** (lignes
21-26) :
```
Si le périmètre reste inexploitable après mapping, demande-le (AskUserQuestion) AVANT de
dispatcher quoi que ce soit. **Filet de repli (D-09, sens fermeture)** : `AskUserQuestion` figure
dans ton `tools:`, mais quand tu es dispatché **en sous-agent**... le runtime peut ne pas te la
fournir malgré sa présence déclarée... Si l'appel échoue pour cette raison, remonte `human_needed`
dans ton rapport typé plutôt que d'insister ou d'auto-répondre en silence.
```
→ D-04bis réutilise directement ce patron pour le cas « réponse aux checkpoints/`safe_resume_gate`
amont » : même filet de repli, même formulation.

**§Hygiène documentaire — table de 4 déclencheurs déjà présente (lignes 210-213), gabarit pour
D-24** :
```
- **Quatre déclencheurs** : surface publique touchée · `[doc-drift]` actif · fin de milestone ·
  nouveau module ou nouvelle capacité. Le nœud est posé dès qu'**au moins un** tombe...
  Constats et conditions exactes : `dev-orchestrator-references/docs-flow.md` §Déclencheurs et
  §Garde-fous — ne pas les reformuler ici.
```
→ Pour D-22/D-23, réutiliser le même schéma : « le manager ne debug pas — redispatche `vf-coder` en
mandat debug » (une phrase, renvoi vers `GSD-PIPELINE.md` §7 pour `gsd-debug`), et un renvoi vers la
nouvelle table de moments déclencheurs de `mission-flow.md` plutôt qu'une recopie.

**Contrainte de densité (RESEARCH)** : 217/250 lignes avant Phase 22, 6 changements prévus ici —
remplacer plutôt qu'ajouter, chaque section neuve doit d'abord chercher si une section existante
peut être étendue en une ligne de renvoi (patron déjà appliqué 3 fois ci-dessus).

---

### `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (1726 lignes — extension, jamais nouvelle suite)

**Analogue exact — discriminance par mutation, fixture injectée (T14b, lignes 1188-1204)** :
```bash
# T14b (DISCRIMINANT) — l'exemption INTENTIONALLY_UNROUTED est bornée aux 3 noms exacts,
# pas un passe-droit générique. Fixture d'index injectée : gsd-next (exempté, canal 4) +
# gsd-inconnu-xyz (ni exempté ni routé — doit être signalé manquant).
fixture_indexed="gsd-next gsd-inconnu-xyz"
fixture_missing=""
for s in $fixture_indexed; do
  is_intentionally_unrouted "$s" && continue
  brick_routed "$s" || fixture_missing="$fixture_missing $s"
done
if echo "$fixture_missing" | "$GREP" -q 'gsd-inconnu-xyz' && ! echo "$fixture_missing" | "$GREP" -q 'gsd-next'; then
  ok "T14b (DISCRIMINANT) : ..."
else
  ko "T14b (DISCRIMINANT) : exemption non bornée..."
fi
```
Même patron pour D-02 (assertion : aucun fichier du module ne prescrit `--auto` sur
`plan`/`execute`, mais `--auto` reste valide sur `discuss`) — injecter une fixture qui contient
`--auto` sur `plan-phase` pour prouver que le test la détecte (sinon garde morte, cf. T14c).

**Analogue exact — garde contre les répliques mortes (T14c, lignes 1206-1229)** :
```bash
# T14c — Aucune brique ne dépend d'un repli disparu. Verrouille le constat qui a autorisé la
# suppression des deux gardes mortes de brick_routed()...
if [ -n "$orphan_fallback" ]; then
  ko "T14c : ..."
else
  ok "T14c : ..."
fi
```
Pour D-11 (aucun dispatch direct `Agent(gsd-planner)`/`Agent(gsd-executor)`), réutiliser
`deleted_hits()` (ligne 138, patron grep discriminant déjà câblé sur `AGENT_FILE` en T3) comme
modèle de fonction de détection, appliquée aux corps de prompt de `vf-coder.md`/`vf-dev-manager.md` :
```bash
deleted_hits() { "$GREP" -oE "$DELETED_RE" "$1" 2>/dev/null | "$GREP" -oE 'vf-...' ...; }
```
Prouver la discriminance : fixture temporaire contenant `dispatche l'agent gsd-planner via l'outil
Agent` doit faire échouer le nouveau test (mutation positive), un fichier sans cette phrase doit le
laisser vert (mutation négative) — même exigence que T14b/T14c ci-dessus.

**Emplacement dans le fichier** : la boucle de vérification des références vit ~ligne 923 (T6
install e2e, vérifie la présence des fichiers `references/*` après install) — étendre cette liste
avec `gsd-capabilities-index.md` si le générateur D-07 y écrit. Le test d'exhaustivité de routage
vit ~762-882 (T3/T4) — ne pas y toucher, D-02/D-11 sont des blocs **nouveaux**, ajoutés après T14c
(fin de fichier), jamais une réécriture de T3/T4/T14.

---

### `docs/ADR.md` (extension ADR-061, D-13/D-14/D-16)

**Structure exacte de l'ADR à étendre** (lignes 1098-1165, à reproduire pour le 3ème objet — hooks
GSD) :
```markdown
### Décision

Les deux mécanismes restent des étages **disjoints**, distingués sur trois axes factuels :

1. **Objet revu** — ADR-060/`vf-reviewer` relit un **diff de code déjà exécuté et commité** ;
   `gsd-review`/les lanes cross-AI relisent le **texte d'un `PLAN.md`**, avant toute exécution.
2. **Moment du cycle** — ADR-060 intervient APRÈS `execute-N` ...
3. **Qui déclenche et qui relit** — ADR-060 est posé **systématiquement** par `vf-dev-manager`...
```
D-16 : ajouter un point 3 de comparaison (hook `code-review`/`secure-phase` vs `revue-N`/`vf-auditer`)
sur les **mêmes 3 axes** (objet revu / moment du cycle / déclencheur), dans la **même section**
`### Décision` de l'ADR-061 existante — jamais une nouvelle ADR (D-16 explicite : « une seule voix »).
Section `### Code Impacté` (lignes 1156-1160) à étendre avec les nouveaux fichiers touchés
(`mission-contracts.md` §verdicts hooks, `mission-flow.md` §Pattern E).

## Shared Patterns

### Générateur idempotent, jamais édité à la main (D-07)
**Source :** `plugin/dev-orchestrator/scripts/build-gsd-index.sh`
**S'applique à :** `build-gsd-capabilities-index.sh` (nouveau)
En-tête « auto-généré — NE PAS ÉDITER », variables `VF_*` surchargeables, `mkdir -p` du dossier de
sortie, `date -Iseconds` avec fallback portable, écriture atomique via bloc `{ ... } > "$OUT"`.

### Gate advisory, contrat exit 0/3/64 (D-17/D-20)
**Source :** `plugin/dev-orchestrator/scripts/check-doc-drift.sh`
**S'applique à :** `check-gsd-config.sh` (nouveau)
Parsing d'arguments strict AVANT toute logique (`--flag` sans valeur → 64), `say()` conditionné par
`--quiet`, signal final sur **stdout** (jamais stderr), câblage `hooks.json` `SessionStart` avec
`|| true`.

### Champs optionnels frères du bloc typé, recopiés verbatim (D-01/D-03/D-15/D-28)
**Source :** `mission-contracts.md` §Contrat `estimate:`/`actuals:` (lignes 133-168)
**S'applique à :** `mission-contracts.md` (nouveaux champs `gate`, verdicts hooks, décompte budget),
`vf-coder.md` §Retour, `vf-dev-manager.md` §Rapport de mission
Règle non négociable : présent uniquement si l'amont le portait, jamais recalculé/arrondi/interprété
— une valeur absente reste absente, jamais inventée.

### Table de moments déclencheurs, gabarit `déclencheur | constat` (D-23/D-24)
**Source :** `plugin/dev-orchestrator/references/docs-flow.md` §Déclencheurs (lignes 64-79, D-08 Phase 22)
**S'applique à :** `mission-flow.md` (4 briques dormantes D-23)
Chaque ligne est un FAIT constatable, jamais un jugement (ADR-055 §3) ; « aucun déclencheur qui ne
tombe est un état normal, pas un manque ».

### Discriminance par mutation, jamais un test qui ne peut pas échouer (D-02/D-11)
**Source :** `test-dev-orchestrator.sh` T14b (lignes 1188-1204) et T14c (lignes 1206-1229)
**S'applique à :** blocs de test nouveaux D-02 (`--auto` jamais sur `plan`/`execute`) et D-11
(aucun dispatch direct `gsd-planner`/`gsd-executor`)
Fixture positive (doit échouer) + fixture négative (doit rester verte), jamais une seule assertion
qui ne peut structurellement pas détecter la régression qu'elle prétend couvrir.

### Renvoi plutôt que duplication (ADR-057 « une capacité, une seule voix »)
**Source :** `mission-contracts.md` §Étage revue (lignes 170-177), `vf-dev-manager.md` §Hygiène
documentaire (lignes 210-213)
**S'applique à :** toutes les surfaces qui pointent vers `GSD-PIPELINE.md`/`ADR.md`/`docs-flow.md`
Un pointeur bref (« critère écrit : `docs/ADR.md` ADR-061 ») remplace systématiquement une
reformulation — impératif de densité (`mission-contracts.md` 16.1K, `vf-dev-manager.md` 217/250L).

## No Analog Found

Aucun fichier de la phase n'est sans analogue — les 9 surfaces + `.planning/config.json` +
`docs/ADR.md` s'éditent toutes en place ou suivent un patron déjà présent dans le module
`dev-orchestrator`. Aucune nouvelle catégorie de fichier (pas de nouveau dossier, pas de nouveau
type de rôle) n'est introduite par cette phase.

## Metadata

**Scope de recherche d'analogues :** `plugin/dev-orchestrator/` (agents, scripts, scripts/tests,
references, hooks), `docs/ADR.md`, `.planning/config.json`.
**Fichiers scannés (lecture intégrale ou ciblée) :** `build-gsd-index.sh`, `check-doc-drift.sh`,
`vf-coder.md`, `vf-dev-manager.md`, `mission-contracts.md`, `mission-flow.md`, `GSD-PIPELINE.md`,
`docs-flow.md` (§Déclencheurs), `test-dev-orchestrator.sh` (T3/T4/T14/T14b/T14c, ~750-1230),
`hooks/hooks.json`, ADR-061 (`docs/ADR.md:1098-1165`), `.planning/config.json`.
**Date d'extraction :** 2026-08-01
