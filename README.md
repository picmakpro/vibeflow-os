# vibeflow-os

> **Modules VibeFlow distribués aux labs** — repo central versionné pour réplication méthodologique.
> Privé. Maintenu par [@picmakpro](https://github.com/picmakpro).

---

## Quoi

Ce repo héberge les **modules réutilisables** de la méthodologie VibeFlow, distribués via un script `vibeflow-update.sh` installé dans chaque lab branché.

## Modules

| Module | Version | Type | Description |
|--------|---------|------|-------------|
| [`consolidator/`](./consolidator/) | v1.0.0 | single-skill + scripts | Consolidation mémoire 4 piliers (Indexation / Archivage / Fusion / Promotion) — ADR-032 |
| [`infrastructure-audit/`](./infrastructure-audit/) | v1.0.0 | single-skill + scripts | Audit automatique infrastructure (hooks, scripts, drift Anthropic) — détecte régressions après update Claude Code |
| [`validator/`](./validator/) | v1.0.0 | agent-only | Agent `vibeflow-validator` (garant alignement technique méthodo ↔ labs) |
| [`skill-creator/`](./skill-creator/) | v1.0.0 | agent + 2 skills | Pattern "agent minimal + 2 skills composables" (Anthropic + workflow) — LRN-101 |
| [`reference/`](./reference/) | v2.0.0 | doc-only | Documentation méthodologique complète (VIBEFLOW_CORE v4.1 + 11 patterns + 33 templates + 1 exemple) |

## Types de modules supportés (depuis v2.0.0)

| Type | Structure module | Cible installation |
|------|------------------|---------------------|
| **single-skill** | `<mod>/SKILL.md` + optionnel `references/`, `scripts/` | `.claude/skills/<mod>/` + `.claude/scripts/` |
| **multi-skills** | `<mod>/skills/<name>/SKILL.md` (multiple) | `.claude/skills/<name>/` (chaque skill séparément) |
| **agent-only** | `<mod>/AGENT.md` | `.claude/agents/<mod>.md` |
| **doc-only** | `<mod>/content/` | `docs/<mod>/` |

Les types sont composables (ex: `skill-creator` = agent + multi-skills).

Chaque module a obligatoirement : `VERSION` (semver), `CHANGELOG.md`, `README.md`.

---

## Installation dans un lab

### Première installation

```bash
cd /chemin/vers/votre-lab
git clone --depth 1 https://github.com/picmakpro/vibeflow-os.git .vibeflow-cache
cp .vibeflow-cache/_internal/vibeflow-update.sh .claude/scripts/
chmod +x .claude/scripts/vibeflow-update.sh
.claude/scripts/vibeflow-update.sh install --all
```

### Installer un module spécifique

```bash
.claude/scripts/vibeflow-update.sh install consolidator
.claude/scripts/vibeflow-update.sh install skill-creator
.claude/scripts/vibeflow-update.sh install reference
```

### Status / mises à jour

```bash
.claude/scripts/vibeflow-update.sh status
.claude/scripts/vibeflow-update.sh update consolidator
.claude/scripts/vibeflow-update.sh update --all
```

### Rollback

```bash
.claude/scripts/vibeflow-update.sh rollback consolidator
```

Voir [INSTALL.md](./INSTALL.md) pour les détails.

---

## Convention versioning

- **Semver** : `vMAJOR.MINOR.PATCH`
- **MAJOR** : breaking change (convention frontmatter, format registre, structure module)
- **MINOR** : nouveau module ou nouvelle capacité majeure
- **PATCH** : bugfix scripts ou amélioration doc

Chaque module a sa propre version. Le repo global est tagué à la version du dernier changement majeur.

### Historique versions repo

| Version | Date | Changement |
|---------|------|------------|
| v1.0.0 | 2026-05-23 | Initial release : consolidator |
| v1.1.0 | 2026-05-24 | + infrastructure-audit |
| v1.2.0 | 2026-05-24 | + validator (agent-only) |
| v1.2.1 | 2026-05-24 | Fix vibeflow-update.sh handle AGENT.md |
| **v2.0.0** | 2026-05-24 | **+ skill-creator (multi-skills), + reference (doc-only), nouveau type module supporté** |

---

## Sécurité

- Repo privé
- Scripts shell + Python uniquement (auditables ligne par ligne)
- Pas de dépendances tierces non vérifiées
- Tests automatisés pour chaque script (`scripts/tests/test-*.sh`)
- skill-creator (Anthropic) sous licence MIT, contenu Anthropic original conservé

---

## Gouvernance

- ADR doit accompagner toute modification structurante (côté Lab VibeFlow)
- Modifications testées dans le Lab VibeFlow (cobaye) avant release
- Tag GitHub Release = changelog officiel
- Cycle de release rapide (multiple releases par session quand justifié)

---

## Références

- [VibeFlow Lab](https://github.com/picmakpro/vibeflow-lab) (privé) — Lab principal
- ADR-029 : Charte de densité agents
- ADR-031 : Garde-fou support runtime
- ADR-032 : Système de Consolidation Mémoire 4 piliers
- ADR-033 : Création repo vibeflow-os (Session 047)
- LRN-101 : Pattern "agent minimal + 2 skills composables"
- LRN-106 : Audit avant fix
- LRN-107 : Repo central versionné > zip ad-hoc
