---
name: vf-cockpit
description: >
  Utiliser pour visualiser en direct le `.planning/` du lab courant dans une page web locale —
  « ouvre le cockpit », « montre-moi où en est le projet », « visualise la roadmap », « où en est
  ma mission », « qu'est-ce qui tourne en ce moment ». Sert la trajectoire (ROADMAP/STATE), le
  chantier en cours (phase active, plans) et l'équipe en mission (DAG, lock) sur un serveur Node
  zéro-dépendance, en lecture seule stricte, sans réseau, en local (127.0.0.1) uniquement.
  ✘ pas pour connaître l'avancement en texte dans la conversation → gsd-progress
  ✘ pas pour modifier la roadmap ou les phases → gsd-phase
  ✘ pas pour auditer la conformité méthodologique du lab → /vf-audit
  Invocable par l'utilisateur via /vf-cockpit.
---

# vf-cockpit — cockpit web local du `.planning/`

Le cockpit est une page web unique qui donne une vue vivante du `.planning/` du lab courant,
sans jamais rien écrire dedans. C'est un miroir, pas un outil d'édition.

## Iron Law

> **Lecture seule stricte.** Le serveur n'exécute aucune écriture disque — ni sur `.planning/`,
> ni ailleurs. Il n'écoute **que** sur `127.0.0.1` : aucun accès réseau externe, aucune
> exposition sur le LAN. Toute correction de plan passe par les briques GSD habituelles
> (`gsd-phase`, `gsd-plan-phase`), jamais par le cockpit.

## Quoi — la hiérarchie à 3 niveaux

Le cockpit organise l'information en trois niveaux d'altitude, du plus stable au plus volatil :

1. **① Trajectoire** — `PROJECT.md`, `STATE.md`, `ROADMAP.md` : où va le projet, où il en est.
2. **② Chantier actuel** — la phase active : son objectif, ses `PLAN.md`, son avancement.
3. **③ Équipe en mission** — le DAG de la mission en cours (`.planning/*.dag.json`) et le
   `DRIVER.lock` : qui travaille sur quoi, en ce moment, dans cette session.

Ces trois niveaux se rafraîchissent en direct (SSE) dès qu'un fichier change sous `.planning/`.

## Comment le lancer

```sh
node .claude/scripts/vf-cockpit-serve.mjs
```

(en dev dans ce dépôt : `node plugin/vf-cockpit/scripts/vf-cockpit-serve.mjs`)

- Écoute sur `http://127.0.0.1:4680` par défaut. Surcharge le port avec `VF_COCKPIT_PORT=<port>`.
- Si le port par défaut est occupé, le serveur tente automatiquement les 10 ports suivants
  (4681, 4682, …) avant d'abandonner — regarde la ligne affichée au boot pour le port réel.
- Résout le `.planning/` à visualiser dans cet ordre de priorité : argument positionnel CLI >
  `--planning-root=<chemin>` > variable d'env `VF_COCKPIT_PLANNING_ROOT` > remontée
  d'arborescence depuis le répertoire courant (comme un outil git-like), en cherchant le premier
  dossier `.planning/` en remontant depuis le `cwd` de l'utilisateur — **jamais** celui de ce
  dépôt vibeflow-os lui-même.
- Pour l'arrêter : `Ctrl+C` dans le terminal qui l'a lancé, ou `kill` le process Node.

## Prérequis réels

- **Node** (le serveur utilise `fetch` global et `fs.watch` récursif — vise Node 18+ ; sur les
  plateformes/versions où `fs.watch({recursive: true})` n'est pas supporté, le module bascule
  seul sur du polling, voir Dépannage).
- Un dossier `.planning/` quelque part dans l'arborescence du lab courant (ou pointé
  explicitement via `--planning-root=` / `VF_COCKPIT_PLANNING_ROOT`).
- **Zéro dépendance npm** : uniquement `node:http`, `node:fs`, `node:path`, `node:url`.
- **Zéro accès réseau** : tout est servi localement, y compris les assets front (Mermaid
  vendorisé dans `references/vendor/`).

## Ce qu'il fait quand des sources manquent

Le module est conçu pour tourner avec un `.planning/` incomplet — chaque source est optionnelle
et son absence est **signalée**, jamais masquée :

- **Aucun `.planning/` trouvé** : le serveur démarre quand même et le dit clairement (message au
  boot + page d'accueil), `planningRoot` vaut `null`, `/api/phase` répond avec un message
  explicite plutôt qu'une erreur muette.
- **`STATE.md` / `ROADMAP.md` / milestones / DAGs / `DRIVER.lock` absents individuellement** :
  chaque section du cockpit affiche son propre état vide au lieu de faire planter le tout — la
  réponse de `/api/state` porte un champ `availability` par source (`state`, `roadmap`,
  `milestones`, `dags`, `lock`) pour que l'UI sache quoi griser.
- **Interface front pas encore posée** (`references/ui/index.html` manquant) : la racine `/`
  répond avec une page de secours minimale plutôt qu'une 404, avec des liens directs vers
  `/api/state` et `/api/log` pour vérifier que le serveur tourne.

## Dépannage

- **Port occupé** : le serveur bascule automatiquement sur les 10 ports suivants. Si aucun n'est
  libre, il rend une erreur explicite au boot — force un port libre avec `VF_COCKPIT_PORT=<port>`.
- **Pas de `.planning/` trouvé** : vérifie que tu lances la commande depuis (ou sous) le lab
  visé, ou passe `--planning-root=<chemin>` / `VF_COCKPIT_PLANNING_ROOT=<chemin>` explicitement.
- **Mode `poll` au lieu de `watch`** : bascule **normale** selon la plateforme — `fs.watch` en
  mode récursif n'est pas garanti partout (notamment certaines versions de Node sous Linux). Le
  cockpit continue de fonctionner, juste avec une latence de rafraîchissement d'environ 2
  secondes au lieu de l'instantané. Le mode actif est visible dans `/api/state` (`watch.mode`).
- **Page blanche** : vérifie d'abord `/api/state` dans le navigateur — si le JSON répond, le
  serveur est sain et le problème vient du front (assets sous `/assets/` non trouvés, vérifie que
  `references/ui/` et `references/vendor/` ont bien été installés à côté du script). Si
  `/api/state` ne répond pas non plus, le serveur n'écoute pas (vérifie le port réel affiché au
  boot, pas forcément 4680 si un fallback a eu lieu).
