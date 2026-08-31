---
name: sessions-concurrentes-sur-le-repo
description: Le verrou de driver n'empêche PAS une autre session de committer sur vibeflow-os — commits intercalés dans l'historique et fichiers .planning/ modifiés non commités pendant une mission
metadata:
  type: project
---

Le `driver-lock.sh` garantit qu'**une seule mission pilote** ; il ne garantit **rien** sur le dépôt.
Une autre session Claude Code peut travailler sur `vibeflow-os` en même temps, committer, et laisser
des **modifications non commitées** sur des fichiers partagés.

**Why:** Mission Phase 16 (2026-07-27). Lock acquis proprement (`acquired:true`). Pendant la mission,
une session parallèle a produit 4 commits (Phases 17 et 18 : `1e263bd`, `fb80177`, `9d1828e`,
`d937174`) **intercalés** dans l'historique entre les miens, plus des modifications **non commitées**
sur `.planning/ROADMAP.md` et `.planning/STATE.md`, et des fichiers non suivis sous
`.planning/phases/VFDO-17-*` / `VFDO-18-*` qui apparaissaient au fil des minutes. Un juge a aussi
observé un échec de gate **non reproductible** (1 fois sur 15+) sur un fichier d'agent, avec un
`.bak` d'éditeur à côté — trace d'une écriture concurrente sur le même module.

**How to apply:**
1. **`HEAD~n` est faux** pour mesurer une régression : des commits étrangers sont intercalés.
   Toujours mesurer contre le **commit de base relevé au démarrage** (corollaire de
   [[verifier-contre-le-commit-de-base]], qui vaut ici même sans worker fautif).
2. **Relever `git status` AVANT de dispatcher un nœud d'hygiène.** Un fichier `.planning/` déjà
   modifié = travail concurrent non sauvegardé : le sortir du périmètre du worker et **escalader**
   plutôt que d'écrire. En Phase 16 j'ai retiré `ROADMAP.md`/`STATE.md` du mandat `hygiene` pour
   cette raison ; le reste (`CONCERNS.md`, `BACKLOG.md`, `16-CONTEXT.md`) est passé sans collision.
3. **Nommer les commits et fichiers étrangers dans CHAQUE mandat**, avec « ce n'est pas un conflit à
   résoudre » — sinon un worker consciencieux essaie de les réconcilier, de les réviser, ou s'arrête.
4. Un échec de gate **non reproductible** sur un fichier partagé : suspecter l'écriture concurrente
   avant de suspecter le code. En CI (checkout propre, process unique) le risque n'existe pas.

## Le TTL du lock est plus court qu'une frontière de nœuds

`driver-lock.sh` a un **TTL de 1800 s (30 min)**. Un heartbeat *entre* les frontières ne suffit pas :
en Phase 16, des workers ont tourné 10, 12 et **22 minutes** chacun, et une frontière parallèle
dépasse facilement la demi-heure. Mon lock a **expiré en cours de mission** ; la session Phase 17 l'a
récupéré (`recovered`), et mon `release` final a rendu `{"released": false, "reason": "not-owner",
"held_by": "mission-phase17"}`. Deux managers ont donc tourné en parallèle — l'invariant « un seul
manager actif » a cédé, sans dégât ici (périmètres de fichiers disjoints) mais par chance.

**How to apply:** heartbeat **avant chaque dispatch long**, pas seulement entre les étapes ; et au
moment du `release`, **vérifier le retour** — un `released:false / not-owner` signifie que le lock a
été perdu en route, ce qui doit apparaître dans le rapport de mission, jamais être avalé en silence.
