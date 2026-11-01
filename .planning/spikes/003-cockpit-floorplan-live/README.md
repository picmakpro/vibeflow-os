---
spike: 003
idea: cockpit-code-projet
name: cockpit-floorplan-live
type: standard
validates: "Given le cockpit floorplan du spike 002 servi, when .planning/ ou le verrou de driver change, then l'onglet Projet met à jour ses statuts dans la page ouverte, sans perdre la vue (zoom, position), en moins de 2 s"
verdict: VALIDATED
related: [001-cockpit-live, 002-cockpit-code-projet]
tags: [cockpit, floorplan, sse, live, driver-lock, integration]
---

# Spike 003 : le direct sur le cockpit floorplan

## Ce qu'on valide

Spike d'intégration entre 001 (direct par SSE et `fs.watch`, Mermaid) et 002 (cockpit floorplan
statique). Given le cockpit 002 servi par `floorplan/serve.mjs`, when `.planning/` ou le verrou de
driver change, then la page ouverte met à jour ses statuts **sans rechargement**, au même zoom,
en moins de 2 s.

## Recherche

Constats tirés du code de floorplan (copie figée v0.6.0) :

- Le direct natif de floorplan recharge **toute la page** (`location.reload()`) quand
  `index.html` change. La vue (conteneur, sélection) survit grâce au hash, mais pas le zoom ni la
  position. En plus, il ne surveille que `index.html` : `project.html` n'est jamais rechargé.
- `render({ keepTransform: true })` existe dans le viewer mais n'est pas exposé. Le patch **P6**
  l'expose : `window.Floorplan.rerender()`.
- Le graphe de l'extension (`Floorplan.graph`) est le même objet que celui du viewer. Le modifier
  en place puis re-rendre suffit : la classe `st-*` (P3) et le pied de carte (P2) sont recalculés.
- Régénérer le graphe Projet coûte **0,1 à 0,17 s**. Le build complet coûte 2,3 s, à cause de
  l'onglet Code. On ne régénère donc que le Projet, jamais le build complet.
- Les verrous vivent dans `<git-common-dir>/vf-driver/` (partagé par tous les worktrees). On les
  lit avec `driver-lock.sh status --all`, qui sort du JSON.

| Approche | Pour | Contre | Statut |
|---|---|---|---|
| Rebuild + reload natif de floorplan | zéro code | perd zoom et position ; 2,3 s ; `project.html` non surveillé | écartée |
| **Sidecar SSE + patch de statuts + `rerender()`** | vue intacte ; ≈ 0,6 s ; floorplan inchangé hors P6 | un 2ᵉ port ; CORS | **retenue** |
| Patcher `serve.mjs` pour y loger le direct | un seul serveur | grossit la copie figée, mélange code tiers et VibeFlow | écartée pour le spike |

## Lancer

```bash
node .planning/spikes/002-cockpit-code-projet/build-cockpit.mjs <root>        # une fois (injecte 70-vf-live.js)
node <root>/floorplan/serve.mjs --no-open                                      # :4378
node .planning/spikes/003-cockpit-floorplan-live/live.mjs <root>               # :4379, SSE /events, /log, /state
node .planning/spikes/003-cockpit-floorplan-live/probe.mjs <bac-à-sable>       # sonde : refuse le dépôt réel
```

## Ce qui a été construit

- `live.mjs` (133 l.) : sidecar sans dépendance.
  - Surveille `.planning/` et `vf-driver/` (`fs.watch` récursif, anti-rebond de 300 ms).
  - Régénère le graphe Projet et calcule le diff des statuts (`st`, `foot`) carte par carte.
  - Pousse en SSE : `patch` (statuts), `structural` (cartes ajoutées ou retirées, avec
    `project.html` réécrit par `rename` atomique) ou `lock`.
  - Journal forensique sur `/log`.
- `002/.../assets/ui/70-vf-live.js` (55 l.) : le client.
  - Applique les patchs au graphe puis appelle `rerender()`.
  - Recharge la page seulement sur un changement de structure (le hash garde la vue).
  - Affiche dans l'en-tête un badge du verrou (owner · étape · âge) qui pulse.
  - Expose une sonde `window.__vfLive`.
- Patch **P6** sur `viewer.html` (une ligne), consigné dans `VENDORED.txt`.
- `probe.mjs` : 9 mutations réelles sur un **bac à sable** (copie git de `.planning/` et
  `plugin/`). Il refuse de tourner sur le dépôt.

## Ce qu'on observe (2026-11-01)

Sonde 2, après les correctifs (`probe.mjs`, exit 0) :

| Mutation | Événement | Délai |
|---|---|---|
| M1 nœud de DAG → `running` | patch (2 cartes) | 563 ms |
| M2 phase cochée dans la ROADMAP | patch (phase + pied du jalon) | 569 ms |
| M3 PLAN ajouté | structural | 580 ms |
| M4 rafale de 21 écritures en 100 ms | **1 seul** patch | 647 ms |
| M5a DAG illisible 150 ms | rien (absorbé par l'anti-rebond) | n/a |
| M5c DAG illisible 450 ms | rien : `hold` puis seconde lecture saine | n/a |
| M5b DAG durablement illisible | structural après seconde lecture ; le serveur survit | 1 308 ms |
| M6 `driver-lock.sh acquire` (dossier `vf-driver/` né après le démarrage) | lock (par le filet de 5 s) | 2 147 ms |
| M7 heartbeat avec nouvelle étape | lock (par `fs.watch`) | 668 ms |
| M8 release | lock | 588 ms |

Rafraîchissement côté serveur : 220 à 289 ms (graphe 120 à 170 ms, puis `driver-lock.sh status`).

**Navigateur (Playwright, Chromium)** : `project.html` ouvert, zoom modifié et un marqueur
`window.__marker` posé. On coche la Phase 51 et on prend un verrou dans le bac à sable :
- la carte `ecc-inspiration-v1.0` passe de « 0/6 · À faire » à « 1/6 phases · 17 % · En cours » ;
- le badge affiche « vf-dev-manager · phase-51-exec · 1 s », puis l'âge avance ;
- le marqueur survit (aucun rechargement) et la transformation `#viewport` est identique au
  pixel près ;
- côté page, le délai entre l'événement SSE et l'application est de 1 ms.

Captures : `captures/1-avant.png` et `captures/2-apres.png`.

## Trace de l'investigation

1. **Sonde 1** : tout vert, mais le journal montre que les 3 événements de verrou venaient de la
   scrutation de 5 s, pas de `fs.watch`. `vf-driver/` n'existe pas tant qu'aucun verrou n'a été
   pris, et un `watch` posé au démarrage sur un dossier absent ne s'accroche jamais.
   → Accrochage tardif dans le filet de 5 s. Après correctif, M7 et M8 passent de 4,5 s à 0,6 s.
2. **DAG illisible = mission qui disparaît** : `dag.sh` `save()` fait `open(file, "w")` puis
   `json.dump`. L'écriture n'est pas atomique : un lecteur qui tombe au milieu lit un JSON
   tronqué, `vf-project-graph` ignore le DAG et ses 32 cartes « disparaissent ». Résultat : un
   rechargement complet, puis un second à la restauration.
   → Hystérésis : un retrait pur de cartes n'est cru qu'après une seconde lecture, 600 ms plus
   tard. M5c (450 ms de corruption) ne produit plus aucun événement.
3. **Piège d'outillage déjà connu** (CONVENTIONS) : l'outil d'écriture a de nouveau converti
   `\u2028`/`\u2029` en caractères réels dans `live.mjs`. Détecté par l'alerte du hook, réparé
   par `perl` et vérifié par décompte (0 caractère réel).
4. **Piège rtk** (déjà en mémoire) : `curl /log` via rtk rend un JSON corrompu. On lit par
   `fetch` Node direct.
5. **Vue d'un DAG par hash** : `#v=dag-MISSION-38` est refusé par `readHash` (ce conteneur n'a pas
   d'enfant nœud). La preuve navigateur s'est donc faite à la racine, où les cartes de jalon
   portent statut et pied.

## Résultats

**VALIDATED** : le direct se greffe sur le cockpit floorplan sans perdre la vue.
- Une ligne de patch (P6) et 55 lignes de client.
- Un sidecar de 133 lignes.
- Environ 0,6 s entre l'écriture d'un fichier et la carte à jour.
- Une rafale de 21 écritures donne un seul rafraîchissement.
- Corruption transitoire absorbée, serveur jamais tombé.
- Le battement du verrou est visible dans l'en-tête.

Limites et suites, à traiter dans la vraie phase :
- **Panneau d'ensemble figé** : « Maintenant », prochaines phases et barres des jalons viennent de
  `G.meta.vf`, que le patch ne touche pas. Le sidecar doit aussi pousser `meta.vf`, et
  l'extension doit redessiner le panneau.
- **`dag.sh` `save()` non atomique** : défaut réel, au-delà du cockpit (tout lecteur concurrent
  du DAG est exposé). Correctif à proposer : écriture dans un fichier temporaire puis
  `os.replace`. L'hystérésis du sidecar reste utile en défense.
- **Onglet Code** : le badge s'y affiche, mais les patchs n'y sont pas appliqués (refs du graphe
  Projet). Le pont « Touché par » ne se met donc pas à jour en direct.
- **Deux ports et CORS** : à fondre en un seul serveur dans le module (le direct dans le serveur
  du cockpit), ou à garder séparé si on veut laisser la copie figée intacte.
- **`fs.watch` récursif** : prouvé sur macOS seulement (même réserve qu'au spike 001 pour Linux et
  Windows).
- **« Qui travaille » reste pauvre** : seul le verrou est lu. Les agents enregistrés
  (`driver-lock.sh register` et `orphans`) et les sessions sans verrou sont l'objet du spike 004.
