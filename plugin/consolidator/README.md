# consolidator — Consolidation Mémoire 5 Piliers

> Skill VibeFlow qui maintient les registres mémoire structurés (DECISIONS / LEARNINGS / BLOCKERS / EVALS / JOURNAL) scalables et propres au fil des sessions, plus la couche « mémoire vivante » fichier-par-entrée.

**Version** : v1.9.0
**Référence** : ADR-032 (piliers 1-4) + ADR-052 (pilier 5) du Lab VibeFlow
**Iron Law** : *"La lecture d'un registre = lecture de l'index uniquement par défaut."*

---

## Quoi

Les registres mémoire VibeFlow grossissent en mode append-only. Sans consolidation, ils deviennent illisibles. Ce skill orchestre 5 mécanismes :

| Pilier | Problème adressé | Mécanisme |
|--------|------------------|-----------|
| 1. Indexation | Lecture index sans `#Ligne` = parcours body inutile | Convention header strict + script `reindex.sh` |
| 2. Archivage | Entrées obsolètes s'accumulent | Script `archive.sh` (3 critères AND) + hook SessionEnd async |
| 3. Fusion | Collisions IDs + doublons sémantiques | Skill `/consolidator --pillar=fusion` (LLM-based) |
| 4. Promotion | Learnings restent passifs (pas de comportement) | Skill `/consolidator --pillar=promote` (semi-auto + validation humaine) |
| 5. Mémoire vivante | Une mémoire figée ment avec le temps | Couche fichier-par-entrée `.claude/memory/knowledge/` : décroissance de confiance par catégorie + supersession **non destructive** (`decay-pass.sh`, ADR-052) |

La gouvernance est **machine-enforced** par hooks (`hooks/hooks.json`) : lecture index-first
bloquante (`guard-read-registres.sh`, `guard-bash-registres.sh`), index auto-maintenu après
édition (`post-edit-reindex.sh`), lint format au démarrage (`check-registres.sh`), archivage en
fin de session.

---

## Installation

Module **`mandatory`** depuis v1.9.0 : il fait partie de la baseline du lab et arrive d'office,
sans toggle. Rien à lancer à la main — la commande ci-dessous n'est utile qu'en réparation.

```bash
.claude/scripts/vibeflow-update.sh install consolidator
```

Le module embarque les **5 gabarits de registres** (`references/templates-memoire/`) et, depuis
v1.9.0, les **instancie** réellement : `seed-registres.sh` crée `.claude/memory/DECISIONS.md`,
`LEARNINGS.md`, `BLOCKERS.md`, `JOURNAL.md`, `EVALS.md` s'ils manquent. Il est appelé par l'engine
à l'install **et** à chaque `update`, y compris quand la version du module n'a pas bougé — un lab
configuré avant cette version reçoit donc sa mémoire tout seul.

> **Non destructif, sans exception.** Le seeder ne sait que créer ce qui manque. Un registre déjà
> présent n'est jamais écrasé, fusionné ni réordonné : les registres sont append-only et portent
> l'historique réel du lab. Idempotent, donc sûr à rejouer.

```bash
.claude/scripts/seed-registres.sh --check   # diagnostic : exit 3 s'il manque des registres
.claude/scripts/seed-registres.sh           # instancie les manquants
```

### Scope `user` : une mémoire par projet

En scope `user`, les scripts vivent dans `~/.claude/` — mais le lint et les guards résolvent
`.claude/memory` **relativement au projet ouvert**. L'install seule remplirait donc la mémoire du
compte en laissant chaque projet vide. Un hook `SessionStart` appelle `seed-registres.sh --project`
à chaque ouverture : **chaque lab reçoit sa propre mémoire, cloisonnée**, quel que soit le scope.

- Le cwd n'est traité comme un lab que s'il porte `.planning/` ou `.claude/` — un dépôt git
  quelconque n'est jamais semé.
- `VF_NO_AUTO_SEED=1` coupe ce comportement sans désinstaller le module.

---

## Usage

### Audit (read-only)

```bash
.claude/scripts/reindex.sh --register=LEARNINGS --audit
# → JSON avec index_count, body_count, orphans
```

### Reindex apply (préserve Date + Resume + orphelins)

```bash
.claude/scripts/reindex.sh --register=DECISIONS --apply
# Backup auto. Idempotent.
```

### Archive auto (hook SessionEnd) ou manuel

```bash
.claude/scripts/archive.sh --dry-run --threshold-days=90
.claude/scripts/archive.sh --apply
```

### Détecter doublons / promotions

```bash
.claude/scripts/detect-duplicates.sh    # → candidats fusion (collisions + titres similaires)
.claude/scripts/detect-promotions.sh    # → candidats learning → rule
```

### Passe de mémoire vivante (pilier 5)

```bash
.claude/scripts/decay-pass.sh --dry-run   # décroissance de confiance + supersession, idempotent
.claude/scripts/decay-pass.sh --apply
```

### Skill complet via Claude Code

```
/consolidator
```

Le skill `consolidator` (chargé via le système de skills Claude Code) orchestre les 5 piliers de
manière interactive.

---

## Tests

6 suites dans `scripts/tests/` (toutes branchées en CI) :

```bash
for t in .claude/scripts/tests/test-*.sh; do bash "$t"; done
# test-consolidator · test-check-registres · test-decay · test-guard-bash-registres
# test-guard-read-registres · test-windows-guards
```

---

## Structure

```
consolidator/
├── SKILL.md                          # Skill principal (359 lignes)
├── VERSION                           # version courante (gate check-version-sync)
├── CHANGELOG.md                      # Historique
├── README.md                         # Ce fichier
├── module.json                       # Manifeste (name, version, requires)
├── hooks/
│   └── hooks.json                    # gouvernance machine-enforced (guards + reindex + lint)
├── references/
│   ├── indexation.md                 # Pilier 1
│   ├── archivage.md                  # Pilier 2
│   ├── fusion.md                     # Pilier 3
│   ├── promotion.md                  # Pilier 4
│   ├── memoire-vivante.md            # Pilier 5 (ADR-052)
│   └── templates-memoire/            # 5 gabarits de registres (DECISIONS, LEARNINGS, …)
└── scripts/
    ├── reindex.sh                    # Pilier 1
    ├── archive.sh                    # Pilier 2
    ├── detect-duplicates.sh          # Pilier 3
    ├── detect-promotions.sh          # Pilier 4
    ├── decay-pass.sh                 # Pilier 5
    ├── check-registres.sh            # lint format des registres (hook SessionStart)
    ├── guard-read-registres.sh       # garde lecture index-first (hook PreToolUse)
    ├── guard-bash-registres.sh       # garde cat/sed/awk sur registres (hook PreToolUse)
    ├── post-edit-reindex.sh          # ré-indexation auto (hook PostToolUse)
    ├── probe-memory-guards.sh        # sonde d'auto-diagnostic des guards
    └── tests/                        # 6 suites + fixtures
```

---

## Compatibilité

- macOS (testé Darwin 25.4.0)
- Linux (compatible — utilise BSD/GNU utilities communes)
- Windows : guards portés (suite `test-windows-guards.sh`, ADR-054)
- bash 4+ ; Claude Code v2+ (hooks lifecycle + skills natifs)

---

## Limites

Voir `CHANGELOG.md` section "Limites connues".

---

## Support

Issues : tracker du repo `picmakpro/vibeflow-os`.
