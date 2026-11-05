---
name: cwd-des-workers-herite-du-manager
description: les workers dispatchés partent dans le répertoire de travail du MANAGER, pas dans le worktree nommé par le mandat ; 3 vf-coder ont commité dans le worktree du cockpit de test de Samuel
metadata:
  type: project
---

Un worker dispatché par Task démarre dans le répertoire de travail principal du manager. Nommer un autre worktree dans le digest ne suffit pas. Mission Phase 71 (2026-11-05) : le manager tournait depuis `phase-71-test4456`, le worktree détaché qui sert le cockpit de test de Samuel (port 4456). Le mandat nommait `phase-71`, et les trois vf-coder ont quand même commité en HEAD détaché dans `test4456`. Deux d'entre eux l'ont signalé, le troisième non. Le manager a dû cherry-pick les commits sur la branche, puis remettre `test4456` sur son commit d'origine.

**Why:** `git branch --contains <sha>` vide après le retour d'un worker. C'est ce qui a révélé le défaut : le commit annoncé n'était sur aucune branche.

**How to apply:** écrire dans chaque mandat « préfixe CHAQUE commande par `cd <chemin absolu du worktree> &&` ». Au retour, vérifier avec `git branch --contains <sha>` que le commit est sur la branche visée. Si le manager démarre dans un worktree qui appartient à l'humain, ne jamais y laisser un worker écrire. Voir aussi [[sessions-concurrentes-sur-le-repo]].
