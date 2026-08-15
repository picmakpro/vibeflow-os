# vf-cockpit — cockpit web local du `.planning/`

> `gsd-progress` répond en texte, mais un lab avec plusieurs phases, un DAG de mission actif et un
> `DRIVER.lock` en vie mérite une vue d'ensemble en un coup d'œil. Ce module ouvre une page web
> locale qui donne cette vue — sans jamais rien écrire dans le `.planning/` qu'elle affiche.

**Type** : skill + script + assets · **Version** : v1.0.0 · **Dépend de** : aucun

---

## Quoi

Un serveur Node **zéro dépendance npm** (`node:http` + SSE + `fs.watch`) qui parse le
`.planning/` du lab courant et sert une page unique, en **lecture seule stricte**, écoutant
**uniquement sur `127.0.0.1`** — aucun accès réseau externe, aucune exposition LAN.

Il organise l'information en trois niveaux d'altitude, du plus stable au plus volatil, chacun un
zoom du précédent :

1. **① Trajectoire** — les phases du milestone (`PROJECT.md`, `STATE.md`, `ROADMAP.md`).
2. **② Chantier actuel** — la phase active : son objectif, ses `PLAN.md`/`SUMMARY.md`.
3. **③ Équipe en mission** — le DAG de la mission active (`.planning/*.dag.json`) et le
   `DRIVER.lock` au heartbeat : qui travaille sur quoi, en ce moment.

Les niveaux ① et ② sont rendus en HTML/CSS natif — plus lisibles et contrôlables qu'un graphe.
Mermaid n'est employé qu'au niveau ③, pour le DAG de mission. Tout est cliquable : un clic ouvre
un drawer latéral avec deep-link (`#/phase/N`, `#/node/<id>`) et le contenu réel lu depuis les
fichiers système — jamais un texte rédigé en dur.

Le tout se rafraîchit en direct par SSE (`/api/events`, debounce 300 ms) dès qu'un fichier change
sous `.planning/`, avec un repli automatique en polling (~2 s) si `fs.watch({recursive: true})`
n'est pas disponible sur la plateforme (portabilité Linux/Windows) — le mode réellement actif est
exposé dans `/api/state`.

## Pourquoi

- **Miroir, pas outil d'édition** : toute correction de plan continue de passer par les briques
  GSD habituelles (`gsd-phase`, `gsd-plan-phase`) — le cockpit ne les remplace pas, il les rend
  visibles.
- **Tolérant à l'absence** : un lab sans DAG, sans lock, sans `MILESTONES.md`, voire sans
  `.planning/` du tout, affiche des états vides soignés — jamais une erreur qui bloque la vue.
- **Hors ligne par construction** : aucune dépendance CDN, y compris pour Mermaid (vendorisé en
  local) — le cockpit fonctionne sans connexion réseau.

## Comment ça marche

- 4 modules dans `scripts/` : `vf-cockpit-serve.mjs` (serveur), `-parsers.mjs` (lecture des
  fichiers `.planning/`), `-security.mjs` (allowlist d'écriture + garde anti-traversée),
  `-watch.mjs` (SSE + repli polling).
- **Garde d'invariant machine-enforced** : une suite de tests en **allowlist** des membres `fs`
  autorisés — tout appel à une API d'écriture non listée échoue par défaut, y compris une API
  future non anticipée. Prouvé par 5 mutations qui font échouer le test si la garde est retirée.
- API HTTP : `GET /`, `/api/state`, `/api/phase?num=N` (400 si `num` invalide), `/api/log`,
  `/api/events` (SSE), `/assets/<chemin>` (allowlist d'extensions, garde anti-traversée).
- **Mermaid v11.16.1 vendorisé** en `references/vendor/mermaid.min.js`, bundle **UMD**
  auto-suffisant (licence MIT), chargé par `<script src>` et consommé via `window.mermaid`. Le
  build ESM officiel de Mermaid importe des chunks relatifs et casserait le fonctionnement hors
  ligne — l'UMD est le choix qui le garantit.

## Utilisation

```sh
node .claude/scripts/vf-cockpit-serve.mjs
```

Depuis n'importe quel dossier sous un lab avec `.planning/` :

> « ouvre le cockpit », « montre-moi où en est le projet », « où en est ma mission »

Écoute par défaut sur `http://127.0.0.1:4680`, surchargeable par `VF_COCKPIT_PORT`, avec repli
automatique sur les 10 ports suivants si le port par défaut est occupé.

Vérifier la suite de tests :

```sh
bash plugin/vf-cockpit/scripts/tests/test-vf-cockpit.sh    # 38 tests
```

## Prérequis

- **Node 18+** (utilise `fetch` global et `fs.watch` récursif ; repli polling automatique là où
  ce n'est pas supporté).
- Un dossier `.planning/` quelque part dans l'arborescence du lab courant (ou pointé
  explicitement via `--planning-root=` / `VF_COCKPIT_PLANNING_ROOT`).
- **Zéro dépendance npm.**

`requires: []` dans `module.json` — aucune dépendance à un autre module VibeFlow.

## Limites

- **Poids du bundle Mermaid vendorisé : 3 566 058 octets ≈ 3,40 Mo.** C'est significatif pour un
  module VibeFlow, et c'est un choix assumé plutôt qu'un oubli : le fonctionnement 100 % hors
  ligne (Iron Law du module) exclut le CDN, et le build ESM aurait cassé cette garantie via ses
  imports relatifs. Le coût est payé une fois à l'installation, jamais au runtime réseau.
- **Suit les liens symboliques** rencontrés dans `.planning/` — assumé pour un outil 100 % local,
  mono-utilisateur, en lecture seule (worktrees, `.planning/` partagé), pas un oubli de garde.
- **Pas de gestion multi-utilisateurs** : `DRIVER.lock` est lu, jamais arbitré — le cockpit ne
  décide rien, il montre l'état.
- Le mode `poll` (au lieu de `watch`) ajoute une latence de rafraîchissement d'environ 2 secondes
  — visible et attendu sur certaines plateformes/versions Node, pas un bug.
