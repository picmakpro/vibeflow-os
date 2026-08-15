# Stack Research — fiabilite-v1.0

**Domain:** Plugin Claude Code distribué (bash portable + Markdown + JSON), milestone fiabilité/gouvernance
**Researched:** 2026-08-15
**Confidence:** HIGH (repo + docs officielles Claude Code + npm vérifiés le jour même)

> **Décision d'ensemble : ZÉRO nouvelle dépendance runtime.** Tout ce dont ce milestone a besoin
> existe déjà dans le périmètre ADR-054 (bash portable, python-si-présent via cascade, `jqx`) ou
> dans le harness Claude Code lui-même (hooks forme exec, hook `Notification`, statusline, hooks
> async). Le « stack » de ce milestone est un stack de **techniques**, pas de paquets.

## Recommended Stack

### Core (inchangé — rappel des contraintes qui gouvernent tout le neuf)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Bash | **3.2-compatible** (macOS système) | tout le moteur | macOS livre bash 3.2 en `/bin/bash` : interdits de fait `declare -A`, `mapfile`, `${var,,}`, `${var^^}` — déjà la pratique du repo (`driver-lock.sh` est 3.2-safe) |
| Python | ≥3, **optionnel**, via cascade `vf_python` | JSON (merge-hooks, gardes) | ADR-054 : `python3` → `python` → (`py -3` via le contrat PR #29), stub `WindowsApps` neutralisé. La lib `vf-portable.sh` est **consommée** (produite par le tracer 01-01 de Willy), pas réécrite |
| `jq` via wrapper `jqx()` | agnostique (1.6+) | JSON quand présent | ADR-054 : jq nu interdit (`tr -d '\r'` obligatoire — le jq Windows natif écrit en CRLF by design) |
| Claude Code hooks | forme **exec** (`command` + `args`) | pose des gardes chez l'utilisateur | Doc officielle vérifiée : `args` présent → spawn direct sans shell, chaque élément passe comme argument unique — supprime le quoting des chemins à espaces (cas nominal Windows) |

### Nouvelles techniques par feature (le vrai livrable de cette recherche)

#### 1. Portabilité Windows II (prioritaire) — techniques bash

| Technique | Où | Pourquoi |
|-----------|----|----------|
| **Bloc localisateur `vf-portable.sh` entre marqueurs** `# >>> vf-portable:locator` / `# <<<` | 3 fichiers du périmètre dev (§1.1 de la spec) | Contrat PR #29 : le gate compare des sommes de contrôle entre marqueurs — le copier-coller divergent devient impossible **par la machine** |
| **`vf_python` = fonction, pas variable** | idem | Seule forme qui porte `py -3` (lanceur à argument) ; `"$PYBIN" -c` devient un appel de fonction — édition raisonnée par fichier, pas un `sed` |
| **Forme exec des hooks : `command` = chemin absolu de `bash` résolu à l'install** | `merge-hooks.sh` (§3.2 — trou d'affectation à trancher avec Willy AVANT plan) | Un nom nu `bash` reproduit le bug ADR-054 §8 (`Git\cmd` seul au PATH). Résolution : `command -v bash` à l'install, converti en chemin mixte via `cygpath -m` si dispo (forward slashes — acceptés par les API Windows ET par JSON sans double-échappement) |
| **Ordre strict (a) moteur → (b) codes de sortie → (c) hooks.json** | lot HOOKS | §1.3 de la spec : livrer (c) avant (a) = placeholder `{{VF_SCRIPTS}}` littéral + hooks doublés + **modules non désinstallables** sur le parc |
| **Normalisation exit 0 sur cas silencieux** (exit 3 interne traduit avant la frontière harness) | 4 entrées hook du périmètre dev | `\|\| true` est une construction shell, inexprimable en forme exec ; sans traduction, chaque démarrage de session affiche une erreur (mesuré : 3 hooks SessionStart sortent 3 en nominal) |
| **CRLF : rien de neuf** | — | `test-windows-crlf.sh` reste la garde ; second temps d'ADR-054, pas une révision |

**Piège vérifié à documenter au plan** : `timeout` — Windows a son propre `timeout.exe` (sémantique
« attendre », pas « tuer ») qui peut précéder celui de Git Bash dans le PATH ; la sonde ADR-054
l'a déjà contourné, réutiliser le même patron, ne pas en réintroduire un naïf.

#### 2. File-locking cross-platform (durcissement driver-lock)

| Primitive | macOS | Linux | Git Bash/Windows | Verdict |
|-----------|-------|-------|------------------|---------|
| `flock(1)` | ✗ absent (util-linux) | ✓ | ✗ absent de Git for Windows | **INTERDIT** — non portable, contraire à ADR-054 |
| `mkdir` comme mutex | ✓ atomique | ✓ | ✓ atomique sur NTFS via MSYS | ✓ primitive de base sûre |
| `set -C` + `> fichier` (noclobber / O_EXCL) | ✓ | ✓ | ✓ | ✓ alternative pour lease-files |
| **Symlink + rename(2)** (forme actuelle de `driver-lock.sh`) | ✓ (`ln -sh`, `mv -h`) | ✓ (`ln -sn`, `mv -T`) | ⚠ **MSYS `ln -s` COPIE par défaut** (symlink natif seulement avec Developer Mode + `MSYS=winsymlinks:nativestrict`) | ✓ à garder sur POSIX ; **prévoir la dégradation Windows** |

**Recommandations :**

- **Ne PAS réécrire le cœur du lock.** La forme symlink-génération actuelle est le résultat de
  mesures réelles (24 acquisitions concurrentes, 5 gagnants avec `mkdir` seul, correctifs de
  fenêtre mesurés PIRES — commentaires en tête de `driver-lock.sh`). Le durcissement demandé
  porte sur l'**enforcement**, pas sur l'acquisition.
- **Enforcement des 2 contournements constatés (commit + checkout sous lock) — deux étages :**
  1. **Étage harness (recommandé, cross-platform, distribue via merge-hooks)** : garde
     `PreToolUse` sur l'outil `Bash` qui intercepte `git commit|checkout|switch` quand
     `driver-lock.sh status` montre un lock tenu par un autre owner → **exit 2 bloque l'appel
     d'outil** (mécanisme documenté Claude Code). Précédent maison : `guard-agent-write.sh`.
     C'est le seul étage qui voyage avec le plugin (leçon régression #38 : un réglage settings
     local ne voyage pas — la garde doit être un fragment `hooks.json` posé par l'engine).
  2. **Étage git (défense en profondeur, opt-in)** : `pre-commit` via `core.hooksPath`
     (précédent : `scripts/hooks` pre-push du repo). ⚠ Git n'a **pas** de hook pre-checkout
     bloquant (`post-checkout` ne peut pas annuler) ; `reference-transaction` (git ≥2.28)
     peut refuser des mises à jour de refs mais sa couverture des symrefs/checkout varie selon
     les versions — confiance MEDIUM, à spiker avant d'en dépendre. L'étage 1 reste le filet
     principal pour le checkout.
- **TTL** : la mémoire du repo note TTL 1800 s < durée d'un mandat (2026-08-02). Le heartbeat
  inter-étapes existe déjà — le durcissement doit relever le défaut OU câbler le heartbeat dans
  les protocoles managers, pas les deux à l'aveugle.

#### 3. Heartbeat / notifications de progression (managers) — 100 % dans le harness

| Mécanisme | Disponibilité | Usage recommandé |
|-----------|---------------|------------------|
| **Fichier de progression** `.planning/mission-status/<owner>.json` (écrit par le manager à chaque nœud du DAG / verdict / halt) | partout, zéro dep | canal de vérité — déjà le patron maison (« artefacts inspectables = canal ») ; réutilise `heartbeat_epoch` du driver-lock |
| **Statusline** (`statusLine.type: "command"` → script) | Claude Code natif, vérifié doc officielle | affichage passif permanent : le script lit le fichier de progression + l'âge du heartbeat → « mission X · nœud 3/7 · hb 42 s » ; détecte le stall (âge > seuil) sans aucun service externe |
| **Hook `Notification`** + notification OS native | vérifié doc officielle (exemples macOS/Linux/Windows fournis par Anthropic) | relais quand Claude attend l'utilisateur |
| **Notification poussée par le manager aux jalons** : `osascript -e 'display notification …'` (macOS), `notify-send` (Linux), `powershell.exe -Command '…'` (Windows) | binaires système, zéro install | geste direct dans le protocole manager OU script `notify.sh` posé par l'engine avec cascade par OS (`uname` / `$OSTYPE`) et **fail-open silencieux** si aucun vecteur (ADR-031 : advisory) |
| **Hooks async + `asyncRewake`** (un process background qui sort en code 2 réveille Claude) | Claude Code v2.x, vérifié doc | option pour un watchdog de stall (18 h silencieuses constatées) — à spiker, pas à engager d'office |
| `printf '\a'` (bell) / `terminal-notifier` | fallback / hors périmètre | ne pas ajouter `terminal-notifier` (dépendance brew) — `osascript` suffit |

**Ce qui est exclu par la contrainte « NO external services »** : webhooks, ntfy.sh, Pushover,
tout démon. Le trio fichier + statusline + notif OS native couvre le besoin sans rien installer.

#### 4. Manifeste d'install + --dry-run + nettoyage des chemins disparus (issue #20)

| Choix | Recommandation | Pourquoi |
|-------|----------------|----------|
| **Format** | **Texte plat LF, un chemin RELATIF au scope par ligne, trié (`LC_ALL=C sort`), lignes `#` d'en-tête** (`# vibeflow-manifest v1`, `# module: X`, `# version: Y`) | Lisible, diffable, **zéro jq requis** (ADR-054) ; c'est le format dpkg `.list` — 30 ans de précédent pour exactement ce problème. JSON (façon Homebrew `INSTALL_RECEIPT.json`) obligerait python/jq sur le chemin critique de l'update |
| **Emplacement** | `<scope>/.claude/.vibeflow/manifest-<module>` (un fichier par module, comme proposé au backlog) | par-module = désinstallation/update scopés ; hors de `scripts/` pour ne pas se lister lui-même |
| **Diff ancien/nouveau** | `comm -23 ancien nouveau` (POSIX, présent partout y compris Git Bash) sur fichiers triés | pure-POSIX, pas de tableau associatif (bash 3.2) |
| **Écriture/lecture** | `printf '%s\n'` à l'écriture ; `tr -d '\r'` à la lecture | un manifeste édité/committé sous Windows peut revenir en CRLF — même classe de bug que le `planning-core\r` d'ADR-054 |
| **Gardes de suppression** | rejeter chemins absolus et tout segment `..` ; suppression uniquement sous la racine du scope ; **backup avant suppression** (patron ADR-048/049 existant) | un manifeste corrompu ne doit jamais pouvoir sortir du scope (path traversal) |
| **--dry-run** | séparer « calcul du plan » / « application du plan » dans `vibeflow-update.sh` ; `--dry-run` imprime le plan et s'arrête | c'est une architecture, pas un outil — et elle rend le plan testable (les 55 suites s'appuient sur des sorties texte) |
| **Checksums** | **NON en v1** (pip `RECORD` fait path,hash,size — surdimensionné ici) | le besoin de l'issue #20 est la convergence des chemins, pas l'intégrité du contenu ; un hash imposerait `shasum`/`sha256sum` (divergence macOS/Linux) sur le chemin critique |

#### 5. Features sans ajout de stack (confirmation explicite)

| Feature | Stack | Note |
|---------|-------|------|
| Ledger d'exigences (Phase 18 héritée) | bash + markdown, gate à la clôture de jalon | précédent direct : `check-state-integrity.sh` |
| Budget d'instructions (Phase 25 héritée) | bash (`wc`, `awk`) | précédent direct : gate densité ADR-029 / `check-agents.sh` |
| Skill-installer global | réutilise l'engine scope-aware + UX toggles + **le manifeste du §4** (fondation commune — le construire d'abord) | aucun ajout |
| Gaps `agency-agents` (dont `web-test-team`) | Markdown agents + Pattern 12 ; Playwright serait la seule vraie dépendance nouvelle **côté lab utilisateur** (comme Maestro pour mobile-test), pas côté plugin | à cadrer à la phase, hors stack plugin |
| Ré-armement `isolation: worktree` | `@opengsd/gsd-core` **> 1.10.0** | **Vérifié sur npm le 2026-08-15 : `latest` = 1.10.0, dist-tag `next` périmé (1.7.0-rc.6)** → la précondition dure N'EST PAS satisfaite aujourd'hui. Le gate de la phase doit sonder `npm view @opengsd/gsd-core version`, pas le dist-tag `next` |

## Installation

```bash
# Rien à installer. Aucune dépendance nouvelle.
# Sonde de précondition pour le ré-armement worktree (à câbler dans le gate de phase) :
npm view @opengsd/gsd-core version   # doit rendre > 1.10.0 avant tout ré-armement
```

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `flock(1)` | absent macOS ET Git Bash (util-linux only) | `mkdir`-mutex, noclobber, forme symlink existante |
| `jq` nu, `grep -P`, `sed -i` | ADR-054 (CRLF, PCRE absent BSD, `-i ''` vs `-i`) | `jqx()`, `grep -E`, réécriture via fichier temp |
| `declare -A`, `mapfile`, `${var,,}` | bash 3.2 (macOS système) | boucles + `case`, `tr` |
| `ln -s` comme primitive de lock **côté Windows** | MSYS copie par défaut (symlink natif = Developer Mode + `MSYS=winsymlinks:nativestrict`) | garder la forme actuelle sur POSIX ; l'enforcement Windows passe par l'étage PreToolUse, pas par le symlink |
| `readlink -f` | comportement divergent BSD/GNU historique | `cd`/`pwd -P`, ou tolérer les deux formes comme `stat -c \|\| stat -f` existant |
| `terminal-notifier`, ntfy/webhooks/services | dépendance brew / service externe (contrainte explicite) | `osascript` / `notify-send` / `powershell.exe` |
| Manifeste JSON + hash | met jq/python/shasum sur le chemin critique d'update | texte plat LF trié + `comm` |
| `\|\| true` dans une entrée hook forme exec | construction shell, inexprimable sans shell | normaliser exit 0 sur cas silencieux (ou lanceur `run-hook.sh`, à trancher au plan §3.3 de la spec) |
| Migrer les `hooks.json` avant `merge-hooks.sh` | §1.3 de la spec : hooks doublés + modules **non désinstallables** sur tout le parc | ordre (a) moteur → (b) codes → (c) fragments, dans cette phase, un seul propriétaire |

## Version Compatibility

| Composant | Compatible avec | Notes |
|-----------|-----------------|-------|
| Forme exec hooks (`args`) | Claude Code ≥ 2.x (vérifié doc officielle 2026-08) | `command` = exécutable SEUL — tout token supplémentaire fait échouer le spawn (doc) : le chemin bash absolu va dans `command`, script + options dans `args` |
| `asyncRewake` / hooks async | Claude Code v2.x récent | à sonder au spike watchdog avant d'en dépendre (feature jeune) |
| `reference-transaction` hook git | git ≥ 2.28 ; couverture checkout/symref incertaine | confiance MEDIUM — spike obligatoire, sinon s'en tenir à PreToolUse + pre-commit |
| `vf-portable.sh` (contrat PR #29) | tracer 01-01 Willy **non livré** (`copy_engine_lib`, `VF_GUARD_HEALTH_DIR`, hook doctor : 0 occurrence vérifiée dans la spec) | dépendance calendaire dure du lot PYBIN pour `guard-file-size.sh` ; question ouverte : exit code de `vf_guard_unavailable` sur PreToolUse (2 = bloque, autre = advisory) — à faire trancher au contrat |
| `@opengsd/gsd-core` 1.10.0 | worktree isolation **désarmée** | ré-armement gaté sur release > 1.10.0 installée (preuve exigée par le gate Phase 28) |

## Sources

- `/websites/code_claude` (Context7, docs officielles Claude Code) — forme exec `command`+`args`, hook `Notification` (exemples macOS/Linux/Windows), `statusLine` command, hooks async + `asyncRewake` — **HIGH**
- `npm view @opengsd/gsd-core` (2026-08-15) — latest 1.10.0, `next` = 1.7.0-rc.6 (périmé) — **HIGH**
- Repo : `docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md`, `docs/ADR.md` §ADR-054, `plugin/conductor/scripts/driver-lock.sh` (commentaires de mesure), `plugin/_internal/merge-hooks.sh`, `.planning/BACKLOG.md` — **HIGH** (première main)
- Connaissances système vérifiables : `flock` = util-linux (absent macOS/Git Bash), MSYS `winsymlinks`, atomicité `mkdir`/O_EXCL sur NTFS, bash 3.2 macOS, dpkg `.list` / pip `RECORD` / Homebrew `INSTALL_RECEIPT.json` comme précédents de manifeste — **MEDIUM** (non re-sourcées en ligne, largement documentées)

---
*Stack research for: vibeflow-os — milestone fiabilite-v1.0*
*Researched: 2026-08-15*
