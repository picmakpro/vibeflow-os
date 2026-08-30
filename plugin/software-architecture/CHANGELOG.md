# Changelog — software-architecture

## [v1.6.1] — 2026-08-30 (Phase 38 — description de frontmatter YAML strict, plan 38-08)

**Patch** :

- **Description de frontmatter passée en scalaire mono-ligne quoté** — la description est désormais un scalaire guillemets doubles mono-ligne (texte strictement inchangé), pour traverser sans perte un parseur YAML strict ET la logique d'extraction de gsd-core (`extractFrontmatterField`). 1 fichier du module concerné. Gate : `plugin/conductor/scripts/check-description-fidelity.sh` (Phase 38, plan 38-08, FIDE-01/FIDE-02).

## [v1.6.0] — 2026-08-16 (Phase 30 tâche 07 — doctrine de la forme exec gravée, PORT-02)

**Minor** (aucun changement de code de ce module — son entrée `guard-file-size.sh` était déjà en
forme exec depuis le plan `30-01`). Ce bump documente que `software-architecture` est désormais
couvert par la doctrine gravée dans **ADR-071** (`docs/ADR.md`) : forme exec, chemin absolu
d'interpréteur résolu et vérifié à l'install (conséquence assumée : `settings.json` devient
spécifique à la machine), contrat de sortie normalisé sans lanceur intermédiaire. Son entrée reste
classée **bloquante** (décision JSON `permissionDecision: deny`, Iron Law 300L) — inchangée par
cette phase.

Référence : `.planning/phases/VFDO-30-portabilit-windows-ii/30-07-PLAN.md`, PORT-02,
`docs/HOOKS-CONTRAT-SORTIE.md`.

## [v1.5.2] — 2026-07-25

### Corrigé
- `check-file-size.sh` sans argument → exit 3 au lieu d'un vert non mérité (F13) ; `--staged`/`--all` vides restent exit 0 (pre-commit légitime).

## [v1.5.1] — 2026-07-23 (portabilité Windows — ADR-054)

### Corrigé
- **`guard-file-size.sh`** : le stub Microsoft Store `python3` (présent dans le PATH mais inerte)
  rendait le guard 300L muet sous Windows sans jamais déclencher son repli fail-open. Résolution
  d'interpréteur par CHEMIN (zéro spawn ajouté, rejet `WindowsApps`, repli `python`).

## [v1.5.0] — 2026-07-20 (audit robustesse hooks — fix faux positifs guard 300L)

### Corrigé
- **`guard-file-size.sh` réécrit : le guard juge désormais le RÉSULTAT de l'édition, plus l'ancien
  état du disque.** Trois défauts démontrés corrigés : (1) le guard bloquait sa propre remédiation
  (Write d'un refactor conforme 150L sur un chemin ≥300L = deny ; Edit ajoutant le marqueur
  d'échappatoire = deny → boucle deny/retry) ; (2) contournable en croissance (fichier 299L + Edit
  ×1000L = allow, Write neuf 2000L = allow) ; (3) fail-closed sur erreur interne (fichier illisible
  → deny à tort). Désormais : Write mesuré sur `tool_input.content` ; Edit : marqueur dans
  `new_string` = allow, delta ≤ 0 (rétrécit) = toujours allow, résultat estimé ≥ seuil = deny ;
  toute exception interne → allow (fail-open strict — seul le deny explicite bloque).
- `check-file-size.sh` : `mapfile` (bash 4+) cassait `--staged`/`--all` sous bash 3.2 macOS
  (rc=127, pre-commit mort) → boucle `read` portable. Off-by-one : fichier de 300 lignes sans
  newline finale compté 299 → comptage `awk END{print NR}` / `splitlines()`.
- Performance : un seul spawn python3 par Edit/Write (parse + décision + deny fusionnés),
  préfiltre bash sans spawn si stdin sans `file_path`.

### Tests
- `test-guard-file-size.sh` 6 → 15 checks (payloads réalistes old_string/new_string/content) ;
  `test-check-file-size.sh` 4 → 9 checks. 100% PASS sous /bin/bash 3.2.

## [v1.4.0] — 2026-07-08 (ADR-045)

### Ajouté
- **Règle path-scopée `rules/doc-research-before-debug.md`** : rend obligatoire une phase de
  recherche documentaire (context7 + issues GitHub / release notes) **avant** tout debug empirique
  intensif, dès qu'un bug touche une lib/framework/natif/version d'OS-SDK ou qu'un correctif a déjà
  échoué. Sortie = pistes priorisées et sourcées (fix robuste → hack fragile, tout hack arbitré).
  Source unique **référencée** (non dupliquée) par `vf-debug`, `vibeflow-dev`, `vf-test-orchestrator`,
  `vf-app-fixer` et le template `debugger`. Prolonge LRN-106 « Audit avant fix ».

### Corrigé
- `module.json` : `type` passé à `single-skill+rules+scripts` (le module shippait déjà une rule
  path-scopée — métadonnée alignée sur la réalité).

## [v1.3.0] — 2026-07-07 (ADR-037 absorbé)

### Ajouté
- **Gates de développement de feature** dans `rules/production-code-architecture.md` : **Gate Nyquist**
  (preuve/commande de vérif avant code) + **Gate Decision Coverage** (traçabilité DEC → code). Repris
  fidèlement de l'ex-module `feature-dev-gates` (ADR-037), désormais **fusionné ici** — foyer unique
  de la rule de code (structure + gates), au lieu de deux rules path-scopées sur les mêmes globs.
- `SKILL.md` Tier 1 : mention des 2 gates.

### Migration
- Le module `feature-dev-gates` est **retiré** (cf. `_internal/retired-modules.txt`). Les labs qui
  l'avaient installé voient leur rule orpheline `rules/feature-dev-gates.md` **nettoyée** au prochain
  `update --all` (convergence vers la version finale).

## [v1.2.0] — 2026-07-07 (ADR-035 étendu)

### Ajouté
- `references/principles.md` — philosophies de dev manquantes : **DRY** (avec la nuance
  dédup-de-savoir vs ressemblance-de-lignes / fausse abstraction), **KISS**, **YAGNI**, et une
  **carte TDD** (Red-Green-Refactor) qui renvoie au skill canonique `superpowers:test-driven-development`
  sans dupliquer sa mécanique.

### Modifié
- `references/solid-soc.md` — la séparation en couches est désormais **nommée Clean Architecture
  (Dependency Rule)** ; la section contrats typés / `Result<T>` est **nommée Clean Code** (nommage
  en place, aucun contenu réécrit).
- `SKILL.md` — Tier 2 enrichi d'items d'audit nommés (DRY, KISS/YAGNI, Clean Code) **sans faux gate
  machine** (audit au jugement, honnêteté de l'Iron Law) ; Tier 1 gagne une ligne TDD/Nyquist ;
  `principles.md` ajouté à la liste des références ; `description` frontmatter élargie.
- `references/universal-vs-dev.md` — table P9 étendue (DRY/KISS/YAGNI + transposition non-dev).

### Note
- Aucun nouvel outillage : les principes non-mécanisables restent au Tier 2 (décision DD4 du spec
  `docs/superpowers/specs/2026-07-07-dev-doctrine-consolidation-design.md`).

## [v1.1.0] — 2026-07-04 (ADR-043)

### Ajouté
- `guard-file-size.sh` — hook PreToolUse(Edit|Write) : DENY l'édition d'un fichier de code
  ≥ 300 lignes sans marqueur `vibeflow:allow-large-file` (porte blindée Iron Law ADR-035).
- `hooks/hooks.json` — gate câblé AUTOMATIQUEMENT dans settings.json à l'install
  (avant : « optionnel mais recommandé » à brancher soi-même = jamais branché).

### Tests
- `test-guard-file-size.sh` (6).

## v1.0.0 — 2026-05-28

Initial release (ADR-035).

- `SKILL.md` : doctrine Architecture Logicielle AI-Safe (Iron Law 300L, Red Flags, validation 3 tiers).
- `references/` : SOLID/SoC, anti-patterns, playbook de restructuration brownfield 6 vagues, transposition universel/dev (P9).
- `rules/production-code-architecture.md` : rule path-scopée (`src/**`, `app/**`, `lib/**`, `features/**`).
- `scripts/check-file-size.sh` : gate de taille (250L warn / 300L block) + test.
- Origine : diagnostic d'architecture Permis Clair (2026-05-27).
