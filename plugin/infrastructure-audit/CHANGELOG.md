# CHANGELOG — infrastructure-audit

## [v1.3.2] — 2026-08-30 (Phase 38 — description de frontmatter YAML strict, plan 38-08)

**Patch** :

- **Description de frontmatter passée en scalaire mono-ligne quoté** — la description est désormais un scalaire guillemets doubles mono-ligne (texte strictement inchangé), pour traverser sans perte un parseur YAML strict ET la logique d'extraction de gsd-core (`extractFrontmatterField`). 1 fichier du module concerné. Gate : `plugin/conductor/scripts/check-description-fidelity.sh` (Phase 38, plan 38-08, FIDE-01/FIDE-02).

## [v1.3.1] — 2026-08-28 (Correctif — contrat de flux du hook SessionStart)

### Corrigé
- **`SessionStart` ne casse plus au parsing** — « Hook output looks like a JSON object but is not
  valid JSON » au démarrage de Claude Code. Chaque axe écrit **son propre** objet JSON sur stdout,
  donc `--quick` (runtime + hooks) en émettait **deux collés** : ce n'est pas un document JSON
  valide, et le harness injecte le stdout d'un hook `SessionStart` en contexte. Symptôme
  intermittent par construction — le gate `--if-older-than=14d` ne laisse l'audit tourner qu'une
  session sur ~14 jours, les autres démarrages sortant à stdout vide.
  Le défaut passait inaperçu parce que `jq` **accepte** cette sortie : il lit un *flux* d'objets,
  là où le harness parse un *document*. Toute vérification au `jq` était donc un vert creux.

### Changé
- **`--hook` est désormais réellement câblé** dans le fragment `hooks.json`
  (`--quick --if-older-than=14d --hook`) et porte une seconde responsabilité, le **flux** de
  sortie (`hook_render`) en plus du code de sortie (`hook_exit`) : le flux des axes est capturé,
  puis rendu en **un seul** objet encodé par `json.dumps` (jamais par concaténation), émis
  uniquement s'il y a des findings — hooks en erreur/avertissement, scripts en erreur de syntaxe,
  dépendances absentes, tests en échec, runtime hors référentiel. Sans finding, **stdout est
  strictement vide** (contrat §3). Repli silencieux si aucun interprète Python n'est joignable
  (ADR-054, détection par chemin du stub Microsoft Store) : le silence vaut mieux qu'un JSON cassé.
- **La sortie CLI est inchangée** — sans `--hook`, `--quick`/`--axis` rendent toujours le flux
  d'objets par axe que consomment les scripts et la suite de tests. Le correctif ne vit que sous
  `--hook`.
- **Nouveau champ `version_ref_present`** dans le JSON de l'axe runtime. Sans
  `known-versions.txt` (jamais posé par l'engine d'install), `version_known: false` ne signifie
  pas « drift » mais « rien pour comparer » : le bandeau se tait dans ce cas, au lieu de crier à
  chaque audit une alerte que rien ne permet d'actionner.

### Ajouté
- **4 tests de non-régression** (T10a–T10d) : document JSON valide au parseur **strict** quand il
  y a des findings, stdout strictement vide sur le chemin nominal, silence quand le référentiel
  de versions est absent, et sortie CLI inchangée. Vérifiés en réintroduisant le défaut — ils
  virent au rouge (3 KO), donc ils mordent. Suite : 16 OK · 0 KO.
- **`docs/HOOKS-CONTRAT-SORTIE.md` §3 bis** — la règle qui manquait : quand le stdout d'un hook
  n'est pas vide, il doit porter **un seul** objet, **encodé**. Avec le piège `jq` documenté et la
  commande de vérification correcte. Le §3 n'avait été appliqué à l'entrée #18 que sur son code de
  sortie, jamais sur son flux — c'est ce trou qui a laissé passer le défaut.

## [v1.3.0] — 2026-08-16 (Portabilité Windows II — codes de sortie, PORT-03/D-07)

### Changé
- **`audit-infra.sh` gagne le drapeau `--hook`** (parité d'interface avec le reste du parc), pas
  encore passé par son fragment `hooks.json` (qui reste `--quick --if-older-than=14d`) — ce
  câblage appartient à la migration en forme exec de la polarité gouvernance, hors périmètre de
  ce plan. Sous `--hook`, le code INDÉTERMINÉ (3, `--strict` + `.claude/` absent) devient 0 à la
  frontière du harness — par parité structurelle avec le reste du parc, même si l'invocation
  réelle du fragment n'atteint jamais `--strict` aujourd'hui. Les findings bloquants (`--strict`,
  exit 1) et les erreurs d'usage de `--diff`/`--axis` ne sont jamais traduits. Sans `--hook` (CLI,
  suites de tests), aucun code ne change.

Voir `docs/HOOKS-CONTRAT-SORTIE.md` pour le contrat complet.

## [v1.2.2] — 2026-07-26

### Modifié
- README monté au standard de doc du repo (tagline, Quoi, Installation avec prérequis réels,
  Démarrer en 5 min, Usage — dont `--strict` et exit codes 0/1/3, Référence exhaustive vérifiée
  sur disque, Limites). Découverte documentée : `known-versions.txt` n'est pas posé par l'engine
  d'install (qui ne copie que `.sh`/`.mjs`/`.js`) → pose manuelle signalée, fail-open côté axe 1.

## [v1.2.1] — 2026-07-25

### Modifié
- Scission ADR-031/ADR-056 : toutes les références « vigilance support runtime » passent à ADR-056 ; `audit-infra.sh` gagne `--strict` (lab absent → exit 3, ERROR → exit 1) ; `/checkpoint` → `/vf-audit`.

## [v1.2.0] — 2026-07-20 (audit robustesse hooks — convergence du gate 14 jours)

### Corrigé
- **Le gate `--if-older-than=14d` ne convergeait jamais** : il ne s'appliquait que si un SNAPSHOT
  existait, or `--quick` n'en écrit pas → tout lab sans snapshot manuel subissait l'audit complet
  (17 lignes injectées au contexte) à CHAQUE SessionStart. Désormais `--quick` réussi pose un stamp
  `.last-audit` et le gate porte sur le plus récent de {stamp, snapshot}.
- **Compteurs mensongers** : les détections python (`ERR|…`/`WARN|…`) fuyaient brutes sur stdout
  sans jamais alimenter `errors_count`/`warnings_count` (toujours 0). Désormais capturées, comptées
  et émises dans un tableau JSON `detections` parseable.
- `--if-older-than=2w` : erreur bash (`integer expression expected`) → sanitisation, fail-open
  silencieux. Ordre `stat` GNU-first (`stat -c %Y || stat -f %m`) — l'ordre BSD-first renvoyait
  silencieusement le mount point sur GNU/Linux.
- `known-versions.txt` complété (2.1.163 → 2.1.215) + règle `semver_ge` : version plus récente que
  la dernière validée = `version_known: true` avec `version_note` explicite (fin du
  `version_known: false` permanent).

### Tests
- `test-audit-infra.sh` créé (8 checks, 100% PASS sous /bin/bash 3.2).

## [v1.1.0] — 2026-07-04 (ADR-043)

### Ajouté
- `hooks/hooks.json` — SessionStart → `audit-infra.sh --quick --if-older-than=14d || true`
  posé AUTOMATIQUEMENT à l'install (avant : snippet à copier-coller).

## [v1.0.1] — 2026-06-11

### Corrigé
- `audit-infra.sh` : portabilité Bash Windows (msys 5.2). `${#array[@]:-0}` (modificateur de défaut
  sur une longueur de tableau) provoquait `bad substitution` et cassait les axes 2 (hooks) et 3
  (scripts) → remplacé par `${#array[@]}` (lignes 180, 181, 229). Détecté par l'audit du lab Permis
  Clair (Windows). `bash -n` OK, exécution `--quick` vérifiée.

## [v1.0.0] — 2026-05-24

### Initial release

**Skill principal**
- `SKILL.md` (449 lignes, charte ADR-029 ≤500L)
- 4 références : claude-code-runtime, hooks-contract, scripts-integrity, snapshot-format

**Script audit-infra.sh**
- 4 modes : `--quick`, `--axis=X`, `--snapshot`, `--diff`
- Mode `--if-older-than=14d` pour hook SessionStart non bloquant
- Génère `.claude/INFRASTRUCTURE_SNAPSHOT.md` au format Markdown

**4 axes d'audit**

1. **Runtime Claude Code**
   - Extraction version via regex semver (gère "2.1.150 (Claude Code)")
   - Comparaison à whitelist `known-versions.txt`
   - Liste tools natifs + hooks events hardcoded (à maintenir)

2. **Hooks contract**
   - Validation JSON `settings.json` + `settings.local.json`
   - Events reconnus (8 events lifecycle Anthropic)
   - Validation scripts pointés (existence + exécutable)
   - Parsing via Python pour robustesse

3. **Scripts intégrité**
   - Syntaxe bash (`bash -n`)
   - Permissions exécutables
   - Dépendances binaires (bash, awk, grep, sed, python3, jq, git, date)
   - Suite de tests si présente (`scripts/tests/test-*.sh`)

4. **Drift Anthropic (snapshot + diff)**
   - Génère INFRASTRUCTURE_SNAPSHOT.md daté
   - Backup auto vers `.prev` à chaque snapshot
   - Mode `--diff` pour détecter régressions

**Iron Laws**
- Audit détecte, ne corrige pas (LRN-106)
- Snapshot avant audit, snapshot après
- Un WARNING ignoré est une ERROR en gestation
- Tests scripts intégrés au pipeline

**Pré-requis installation**
- `.claude/scripts/audit-infra.sh` + `known-versions.txt`
- Hook SessionStart `--if-older-than=14d` (optionnel)

### Validé en production
- Lab VibeFlow (cobaye) — Session 047
- Détection automatique version 2.1.150 non whitelist (warning expected)
- Hook SessionStart fonctionne sans bloquer (skip si snapshot < 14j)

### Limites connues v1.0.0
- Whitelist `known-versions.txt` à maintenir manuellement (process humain)
- Tools natifs et hooks events hardcoded en bash array — pas de probing dynamique
- Mode `--diff` génère diff brut (pas de severité catégorisée)
- Le hook fork bash sur SessionEnd async peut ne pas survivre à un crash kernel

### Références
- ADR-031 — Vigilance support runtime
- ADR-032 — Système Consolidation Mémoire
- LRN-106 — Audit avant fix
- Anthropic doc hooks : https://docs.claude.com/en/docs/claude-code/hooks
