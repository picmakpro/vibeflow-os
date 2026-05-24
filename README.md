# vibeflow-os

> **Modules VibeFlow distribués aux labs** — repo central versionné pour réplication méthodologique.
> Privé. Maintenu par [@picmakpro](https://github.com/picmakpro).

---

## Quoi

Ce repo héberge les **modules réutilisables** de la méthodologie VibeFlow, distribués via un script `vibeflow-update.sh` installé dans chaque lab branché.

Chaque module = un sous-dossier auto-suffisant avec :
- `SKILL.md` (skill Claude Code natif) ou contenu équivalent
- `references/` (documentation détaillée)
- `scripts/` (scripts bash, idempotents, testés)
- `VERSION` (semver)
- `CHANGELOG.md`
- `README.md` + `INSTALL.md`

## Modules

| Module | Version | Description |
|--------|---------|-------------|
| [`consolidator/`](./consolidator/) | v1.0.0 | Consolidation mémoire 4 piliers (Indexation / Archivage / Fusion / Promotion) — ADR-032 |
| [`infrastructure-audit/`](./infrastructure-audit/) | _à venir_ | Audit automatique infrastructure (hooks, scripts, drift Anthropic) |
| [`validator/`](./validator/) | _à venir_ | Agent vibeflow-validator (garant alignement technique méthodo ↔ labs) |
| [`reference/`](./reference/) | _à venir_ | Documentation canonique méthodologie (VIBEFLOW_CORE, DEVFLOW V4) |

## Installation dans un lab

### Première installation

```bash
cd /chemin/vers/votre-lab
git clone --depth 1 https://github.com/picmakpro/vibeflow-os.git .vibeflow-cache
cp .vibeflow-cache/_internal/vibeflow-update.sh .claude/scripts/
chmod +x .claude/scripts/vibeflow-update.sh
.claude/scripts/vibeflow-update.sh install consolidator
```

### Mise à jour d'un module

```bash
.claude/scripts/vibeflow-update.sh update consolidator
```

### Mise à jour de tous les modules installés

```bash
.claude/scripts/vibeflow-update.sh update --all
```

Voir [INSTALL.md](./INSTALL.md) pour les détails.

## Convention versioning

- **Semver** : `vMAJOR.MINOR.PATCH`
- **MAJOR** : breaking change (convention frontmatter, format registre, etc.)
- **MINOR** : nouveau pilier ou skill ajouté
- **PATCH** : bugfix scripts ou amélioration doc

Chaque module a sa propre version. Le repo global est tagué à la version du dernier module modifié.

## Sécurité

- Repo privé
- Scripts shell uniquement (auditables ligne par ligne)
- Pas de dépendances tierces non vérifiées
- Tests automatisés pour chaque script (`scripts/tests/test-*.sh`)

## Gouvernance

- ADR doit accompagner toute modification structurante
- Modifications testées dans le Lab VibeFlow (cobaye) avant release
- Tag GitHub Release = changelog officiel

## Références

- [VibeFlow Lab](https://github.com/picmakpro/vibeflow-lab) (privé) — Lab principal
- ADR-032 : Système de Consolidation Mémoire 4 piliers
- ADR-029 : Charte de densité agents
- ADR-031 : Garde-fou support runtime
