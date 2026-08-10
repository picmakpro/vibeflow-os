# INSTALL — vibeflow-os

> Guide d'installation de VibeFlow comme **plugin Claude Code**.

La procédure complète — prérequis, les deux commandes, choix du scope, mise à jour,
désinstallation, dépannage — vit désormais dans le manuel utilisateur, à jour en continu :

- [Prérequis](./manual/fr/01-demarrer/prerequis.md)
- [Installation](./manual/fr/01-demarrer/installation.md)
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
