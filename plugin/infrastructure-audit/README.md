# infrastructure-audit — Garde-fou technique des labs

> Détecte les régressions silencieuses de l'infrastructure d'un lab après une mise à jour Claude
> Code — *« une infrastructure non auditée est une infrastructure qui dérive silencieusement »*.

> **Type** : single-skill + scripts + hook · **Version** : v1.3.1 · **Dépend de** : aucun (module autonome)
> **ADR** : ADR-056 (vigilance support runtime) · ADR-043 (hooks posés à l'install) · LRN-106 (audit avant fix)

---

## Quoi

Anthropic met à jour Claude Code régulièrement. Sans audit périodique : hooks deprecated qui ne
s'exécutent plus, scripts qui plantent silencieusement, conventions frontmatter qui changent,
conventions inventées qui semblent marcher jusqu'au prochain update (ADR-056).

Ce module audite l'infrastructure d'un lab en **4 axes** — un script mécanique
(`audit-infra.sh`) fait les mesures, le skill porte le jugement et l'orchestration :

| Axe | Vérifie | Sévérité max si fail |
|-----|---------|----------------------|
| 1. Runtime | Version Claude Code vs whitelist (`known-versions.txt`), tools natifs | ERROR (tool absent) |
| 2. Hooks | `settings.json` valide, events reconnus, scripts pointés existants + exécutables | ERROR (script absent) |
| 3. Scripts | Syntaxe bash (`bash -n`), permissions, dépendances binaires, suite `tests/test-*.sh` | ERROR (syntaxe ou test KO) |
| 4. Drift | Snapshot daté vs snapshot précédent (`.prev`) | Selon delta |

**Pour qui** : tout lab branché VibeFlow (dev ou non-dev).
**Quand** : au `/vf-audit` (le validator orchestre cet axe), après un update Claude Code, ou
automatiquement au SessionStart si le dernier audit date de plus de 14 jours.

---

## Installation

```bash
bash .claude/scripts/vibeflow-update.sh install infrastructure-audit
```

Aucune dépendance de module (`requires: []`). L'install pose :

- `.claude/skills/infrastructure-audit/` (SKILL.md + `references/`)
- `.claude/scripts/audit-infra.sh` + `.claude/scripts/tests/test-audit-infra.sh`
- le hook SessionStart, **posé automatiquement** (ADR-043) via `hooks/hooks.json` mergé dans
  `.claude/settings.json` :

```json
"SessionStart": [{
  "matcher": "startup",
  "hooks": [{
    "type": "command",
    "command": "bash .claude/scripts/audit-infra.sh --quick --if-older-than=14d --hook || true"
  }]
}]
```

Rien à copier — vérifier avec `grep audit-infra .claude/settings.json`.

**Prérequis réels** : `bash`, `python3` (parsing robuste des settings JSON), `git`/`jq`
vérifiés par l'axe 3 lui-même. ⚠️ La whitelist `scripts/known-versions.txt` doit être posée à la
main dans `.claude/scripts/` (l'engine d'install ne copie que `.sh`/`.mjs`/`.js`) — sans elle,
l'axe 1 rapporte `version_known: false` **avec `version_ref_present: false`** (voir Limites) : il
n'y a rien pour comparer, ce n'est donc pas un drift. Le bandeau de session se tait dans ce cas —
sans quoi il crierait à chaque audit une alerte que rien ne permet d'actionner.

**Ce que le hook affiche.** Sous `--hook`, le JSON par axe n'est pas injecté tel quel : il est
agrégé en **un seul** `systemMessage` (encodé, jamais concaténé), émis uniquement s'il y a des
findings — hooks en erreur ou en avertissement, scripts en erreur de syntaxe, dépendances
absentes, tests de script en échec, runtime hors référentiel. Sans finding, **stdout est vide**.
Le JSON par axe complet reste la sortie du mode CLI (sans `--hook`), inchangée pour les scripts
et les suites de tests qui le consomment. Voir `docs/HOOKS-CONTRAT-SORTIE.md` §3 et §3 bis.

---

## Démarrer (5 min)

**1. Lance un audit rapide** (ce que le hook fera tout seul tous les 14 jours) :

```bash
bash .claude/scripts/audit-infra.sh --quick
```

**2. Ce qui se passe** : version Claude Code extraite et comparée à la whitelist, settings JSON
validés, hooks/events vérifiés (~5 s, axes 1+2). Un stamp `.claude/.last-audit` est posé — c'est
lui qui fait converger le gate `--if-older-than=14d` du hook.

**3. Ce que tu obtiens** : un JSON par axe avec `errors_count` / `warnings_count` et un tableau
`detections` parseable. Zéro erreur → le lab est sain ; sinon le skill guide le diagnostic
(l'audit **détecte, ne corrige pas** — LRN-106).

**4. Pose une baseline** pour les comparaisons futures :

```bash
bash .claude/scripts/audit-infra.sh --snapshot   # → .claude/INFRASTRUCTURE_SNAPSHOT.md (+ .prev)
```

---

## Usage

```bash
.claude/scripts/audit-infra.sh                    # audit complet (4 axes)
.claude/scripts/audit-infra.sh --quick            # rapide (~5s, axes 1+2, pose le stamp)
.claude/scripts/audit-infra.sh --axis=runtime     # un axe : runtime | hooks | scripts | drift
.claude/scripts/audit-infra.sh --snapshot         # snapshot daté + backup .prev
.claude/scripts/audit-infra.sh --diff             # diff vs snapshot précédent
.claude/scripts/audit-infra.sh --strict           # mode GATE : ERROR → exit 1, lab absent → exit 3
```

- **Après un update Claude Code** : `--snapshot` avant/après, puis `--diff`.
- **En CI / pre-commit** : `--strict` transforme l'advisory en gate (exit 0 = OK, 1 = findings
  bloquants, 3 = INDÉTERMINÉ, rien d'audité). S'applique aux modes full/quick/axis.
- **Maintenance whitelist** : `echo "2.1.216" >> .claude/scripts/known-versions.txt` après avoir
  validé que la nouvelle version ne casse rien. Depuis v1.2.0, une version **plus récente** que
  la dernière validée est considérée `known` avec une note explicite (pas de faux négatif
  permanent).
- **Complémentarité `consolidator`** : `consolidator` maintient la **mémoire** propre,
  `infrastructure-audit` la **mécanique** propre. Bonne pratique : `--snapshot` avant toute passe
  `/consolidator` majeure, pour avoir un état initial à comparer.

---

## Référence

| Fichier | Cible installation | Rôle |
|---------|--------------------|------|
| `SKILL.md` | `.claude/skills/infrastructure-audit/SKILL.md` | Orchestration des 4 axes, quand invoquer, lecture des outputs JSON |
| `references/claude-code-runtime.md` | `.claude/skills/infrastructure-audit/references/` | Axe 1 : version, tools natifs, capacités runtime |
| `references/hooks-contract.md` | idem | Axe 2 : contrat des 8 events lifecycle, validation settings |
| `references/scripts-integrity.md` | idem | Axe 3 : syntaxe, permissions, dépendances, tests |
| `references/snapshot-format.md` | idem | Axe 4 : format `INFRASTRUCTURE_SNAPSHOT.md` et diff |
| `scripts/audit-infra.sh` | `.claude/scripts/audit-infra.sh` | Le moteur mécanique (modes ci-dessus, exit codes 0/1/3) |
| `scripts/tests/test-audit-infra.sh` | `.claude/scripts/tests/` | Suite de 8 checks (stamp, gate, compteurs, whitelist) — 100 % PASS sous bash 3.2 |
| `scripts/known-versions.txt` | `.claude/scripts/` (**pose manuelle**) | Whitelist des versions Claude Code validées |
| `hooks/hooks.json` | mergé dans `.claude/settings.json` | Hook SessionStart `--quick --if-older-than=14d --hook` (ADR-043) |

---

## Limites

- **Whitelist à maintenir à la main** : ajouter une version = valider humainement qu'elle ne
  casse rien. Atténué depuis v1.2.0 (versions plus récentes supposées compatibles, avec note).
- **`known-versions.txt` n'est pas posé par l'engine d'install** (il ne copie que
  `.sh`/`.mjs`/`.js`) — fail-open : sans le fichier, l'axe 1 signale simplement la version comme
  inconnue.
- **Tools natifs et hooks events hardcodés** dans `audit-infra.sh` (arrays
  `tools_natifs_hardcoded` / `hooks_events_hardcoded`) — pas de probing dynamique ; à mettre à
  jour si Anthropic ajoute un tool ou un event.
- **`--diff` produit un diff brut**, sans catégorisation de sévérité.
- **L'audit détecte, ne corrige pas** (LRN-106) — par conception, pas une limite à combler.

## Voir aussi

- ADR-056 — vigilance support runtime · ADR-043 — hooks posés à l'install · ADR-032 — consolidation mémoire
- Doc hooks Anthropic : https://docs.claude.com/en/docs/claude-code/hooks
- Issues : tracker du repo `picmakpro/vibeflow-os`
