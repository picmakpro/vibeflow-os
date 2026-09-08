# INSTALL — vibeflow-os

> Guide d'installation de VibeFlow — **plugin Claude Code** (runtime de référence), également
> installable et utilisable sur **Codex** et **kimi-code**.

La procédure complète — prérequis, les deux commandes, choix du scope, mise à jour,
désinstallation, dépannage — vit désormais dans le manuel utilisateur, à jour en continu :

- [Prérequis](./manual/fr/01-demarrer/prerequis.md)
- [Installation](./manual/fr/01-demarrer/installation.md)
- [Installer hors Claude Code — Codex, kimi-code](./manual/fr/01-demarrer/autres-runtimes.md)
- [Choisir son scope](./manual/fr/01-demarrer/choisir-son-scope.md)
- [Mettre à jour et désinstaller](./manual/fr/01-demarrer/mettre-a-jour-et-desinstaller.md)
- [Dépannage — installation](./manual/fr/01-demarrer/depannage-installation.md)
- [L'engine d'installation](./manual/fr/07-sous-le-capot/l-engine-d-install.md) (auditabilité, idempotence, sécurité)

*English reader? Start at [manual/en/01-get-started/installation.md](./manual/en/01-get-started/installation.md).*

> **Après toute installation, mise à jour ou modification d'un agent : redémarre la session.** Le
> registre des agents est résolu **au démarrage** — une définition éditée en cours de session n'est
> pas rechargée, et rien ne te le signale : l'agent répond, il se comporte simplement comme avant
> ton édition. Détail et vérification :
> [Mettre à jour et désinstaller](./manual/fr/01-demarrer/mettre-a-jour-et-desinstaller.md).

Pour aller vite, les deux commandes qui posent le plugin (avant de lancer `/vibeflow-install`) :

```bash
claude plugin marketplace add picmakpro/vibeflow-os
claude plugin install vibeflow
```

Sous **Codex**, le canal natif prend le relais — noter le verbe `add`, `codex plugin install`
n'existe pas :

```bash
codex plugin marketplace add picmakpro/vibeflow-os
codex plugin add vibeflow@vibeflow-os
```

Deux préconditions Codex échouent **en silence** si elles manquent : `multi_agent_v2` doit être
actif (sans elle, aucun outil de spawn — l'équipe de mission ne peut pas se déployer) et le dépôt
cible doit être « trusted » (sinon `.codex/agents/` n'est jamais parsé, pendant que `codex doctor`
annonce que tout va bien). Sur un poste qui a aussi `claude`, la détection cascade `claude`,
`codex`, `opencode` — force la cible avec `VF_RUNTIME=codex`.

**kimi-code** n'a pas de canal d'install : un agent VibeFlow se charge par
`kimi --agent-file <chemin>`.

Les **hooks de gouvernance ne sont portés sur aucun runtime autre que Claude Code** (VibeFlow les
pose dans `settings.json`, que les autres n'exécutent pas) et les champs perdus par cible sont
déclarés à l'install. Le détail complet — pertes, confinement des juges, retrait symétrique — est
sur [autres-runtimes.md](./manual/fr/01-demarrer/autres-runtimes.md).
