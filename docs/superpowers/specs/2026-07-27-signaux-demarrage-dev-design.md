# Design — Signaux de démarrage `dev-orchestrator` : rendre onboard / ingest / hygiène doc implicites

> **Date** : 2026-07-27
> **Modules** : `dev-orchestrator` (v2.4.0 → v2.5.0)
> **Problème** : les gestes de démarrage et d'hygiène documentaire (`gsd-onboard`,
> `gsd-ingest-docs`, `gsd-map-codebase`, `gsd-config`, `gsd-docs-update`) ne se déclenchent
> aujourd'hui que si le modèle **y pense**. Aucun fait ne les provoque. L'utilisateur qui vient
> d'initialiser un projet n'est guidé nulle part au-delà de l'init lui-même.

---

## 1. Problème

### 1.1 Le seul module structurant sans hooks

| Module | Hooks câblés |
|---|---|
| `conductor` | `PreToolUse` (Write) + 3 × `SessionStart` |
| `planning-core` | 4 × `SessionStart` + `UserPromptSubmit` + `Stop` (bloquant) |
| **`dev-orchestrator`** | **aucun** (pas de dossier `hooks/`) |

Conséquence directe : `discover-unintegrated-docs.sh` — livré en phase 13, contrat de sortie
propre, testé — **n'est jamais appelé automatiquement**. Il attend que `vibeflow-dev` décide de
l'appeler, sur la foi d'une ligne de prose dans son `AGENT.md`.

### 1.2 Ce que la doctrine promet, et que rien ne garantit

`plugin/dev-orchestrator/AGENT.md` § *Next steps & hygiène documentaire* promet quatre
déclenchements : drift doc → `gsd-docs-update` ; spec orpheline → ingestion ; nouveau projet →
proposition de `config.json` ; fin de milestone → bilan. Ce sont des **intentions écrites**, pas
des garanties. Le garde-fou first-use (FIRST-01/02) est le seul mécanisme réellement systématique,
et il ne se déclenche qu'au moment où une intention de dev structurante arrive — pas au démarrage
de session, et pas du tout après l'init.

### 1.3 Le trou du post-init

FIRST-02 s'arrête à `gsd-onboard` / `gsd-new-project`. Une fois `.planning/PROJECT.md` posé, plus
aucun signal n'existe : ni pour `config.json`, ni pour la cartographie du code, ni pour l'ingestion
des documents déjà présents dans le repo. L'utilisateur ignore ce qu'il lui reste à faire, et le
modèle n'a aucun fait pour le lui dire.

---

## 2. Décision

Poser à `dev-orchestrator` un fragment `hooks/hooks.json` sur le modèle exact de `planning-core` :
au `SessionStart:startup`, des scripts constatent des **faits** et injectent un signal court et
**auto-portant**. L'agent réagit au signal au lieu de devoir y penser.

Quatre faits, **trois scripts** :

| Script | Faits couverts | État |
|---|---|---|
| `check-dev-bootstrap.sh` | repo brownfield non initialisé **+** bootstrap incomplet | à créer |
| `discover-unintegrated-docs.sh` | documents orphelins de la feuille de route | existe — ajouter `--hook` |
| `check-doc-drift.sh` | documentation potentiellement périmée | à créer |

### 2.1 Pourquoi deux faits dans un seul script

« Code présent, `.planning/` absent » et « `.planning/` présent mais incomplet » sont deux états
d'un même continuum — *où en est le démarrage de ce projet ?* — et sont **mutuellement
exclusifs**. Deux scripts séparés devraient chacun tester l'état de l'autre pour savoir s'ils ont
le droit de parler.

---

## 3. Composants

### 3.1 `check-dev-bootstrap.sh` (nouveau)

**Rôle (ADR-055 §3)** : répondre au FAIT. Il constate quels artefacts de démarrage existent. Il ne
juge jamais si le projet « mérite » un onboarding — c'est le jugement de l'agent.

```
Usage : check-dev-bootstrap.sh [--path <dir>] [--hook] [--quiet]
Défaut : --path .
```

Continuum d'états, évalués dans cet ordre, le premier qui matche gagne :

| # | Condition constatée | Sortie | Exit |
|---|---|---|---|
| 0 | ni code source ni `.planning/` | silence | 3 |
| 1 | code source présent, `.planning/` absent | signal `onboard` | 0 |
| 2 | `.planning/PROJECT.md` présent, ≥ 1 item de démarrage manquant | signal `bootstrap` + liste des items | 0 |
| 3 | `.planning/PROJECT.md` présent, tous items posés | silence | 3 |
| — | argument inconnu | message sur stderr | 64 |

**Détection « code source présent »** : au moins un fichier existe hors des dossiers
vendorés/générés (`.git`, `node_modules`, `.venv`, `vendor`, `dist`, `build`, `.next`) et hors
`docs/`, `.planning/`, `.claude/`. Un repo qui ne contient que de la documentation n'est pas un
brownfield. Détection par `find` avec élagage `-prune` **avant** descente, jamais par filtre post
— même contrainte de performance que `detect-planning-debt.sh` (un `node_modules` réel gèlerait le
`SessionStart`). Pas de dépendance à git : un projet non versionné doit être détecté comme
brownfield au même titre qu'un dépôt.

**Items de démarrage vérifiés à l'état 2**, dans cet ordre de restitution :

| Item | Fait constaté | Geste associé |
|---|---|---|
| `config` | `.planning/config.json` absent | `gsd-config` |
| `codebase` | code source présent **et** `.planning/codebase/` absent ou vide | `gsd-map-codebase` |
| `roadmap` | `.planning/ROADMAP.md` absent, ou présent sans aucune phase | `gsd-plan-phase` (ou `gsd-new-milestone`) |

L'item `codebase` est conditionné à la présence de code : sur un greenfield fraîchement initialisé,
il n'y a rien à cartographier et le signaler serait du bruit.

**Env de surcharge** (testabilité, modèle `VF_INGEST_*` de `discover-unintegrated-docs.sh`) :
`VF_BOOTSTRAP_PLANNING_DIR` (défaut `<path>/.planning`).

### 3.2 `discover-unintegrated-docs.sh` — mode `--hook` (extension)

Le contrat actuel (`grain<TAB>chemin` sur stdout, exits 0/3/64) est consommé tel quel par la
doctrine `ingestion-flow.md`. Il ne bouge pas.

`--hook` est un **nouveau flag d'affichage uniquement** : au lieu de la liste, il émet une ligne
agrégée. Exits **strictement inchangés** — les mêmes trois codes, dans les mêmes conditions.
`--hook` et `--quiet` sont mutuellement exclusifs : les passer ensemble sort en 64.

### 3.3 `check-doc-drift.sh` (nouveau)

**Rôle** : constater qu'une documentation n'a pas suivi le code, sans jamais juger si elle est
réellement fausse.

```
Usage : check-doc-drift.sh [--path <dir>] [--threshold <N>] [--hook] [--quiet]
Défaut : --path .  --threshold 20
```

**Heuristique** : nombre de commits ayant touché du code source depuis le dernier commit ayant
touché `docs/**` ou un `README*` à la racine. Au-delà du seuil → signal.

| Condition | Sortie | Exit |
|---|---|---|
| pas un dépôt git, ou aucun commit de doc dans l'historique | silence | 3 |
| compte < seuil | silence | 3 |
| compte ≥ seuil | signal `doc-drift` | 0 |
| argument inconnu | message sur stderr | 64 |

C'est le plus heuristique des trois signaux, donc celui qui peut faire du bruit. Le seuil par
défaut est délibérément haut (20) et réglable par flag. Il est **advisory** : il dit « la doc n'a
pas bougé depuis longtemps », jamais « la doc est fausse ».

### 3.4 `hooks/hooks.json` (nouveau)

```json
{
  "description": "Signaux de démarrage du moteur de dev : état du bootstrap projet, documents de cadrage orphelins de la feuille de route, dérive documentaire. Advisory (ADR-031) — chaque signal propose un geste, aucun ne l'exécute.",
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          { "type": "command", "command": "bash {{VF_SCRIPTS}}/check-dev-bootstrap.sh --hook || true" },
          { "type": "command", "command": "bash {{VF_SCRIPTS}}/discover-unintegrated-docs.sh --hook || true" },
          { "type": "command", "command": "bash {{VF_SCRIPTS}}/check-doc-drift.sh --hook || true" }
        ]
      }
    ]
  }
}
```

L'engine (`plugin/_internal/vibeflow-update.sh`) sait déjà merger et retirer ce fragment
(`merge_module_hooks` / `remove_module_hooks`), et la gouvernance légère le re-pose sur les labs
déjà installés sans exiger de bump — aucune modification de l'engine n'est requise.

---

## 4. Contrat de sortie des signaux

### 4.1 Les signaux doivent être auto-portants

Le hook `SessionStart` injecte dans le contexte de la **session principale**, pas dans celui de
l'agent `vibeflow-dev` — dont l'`AGENT.md` n'est lu qu'à son invocation. Un signal qui se contente
d'énoncer un fait (`3 documents non intégrés`) ne déclenchera rien.

Chaque ligne porte donc **son propre geste**, sur le modèle de `[planning-debt]` :

```
[bootstrap] Projet initialisé, démarrage inachevé : config.json absent, codebase non cartographié.
            → propose gsd-config puis gsd-map-codebase (confirmation requise).
[onboard]   Code présent, aucun .planning/ — projet non cadré.
            → propose gsd-onboard (confirmation requise).
[docs-ingest] 3 documents de cadrage hors feuille de route (2 spec, 1 plan).
            → propose l'ingestion (gsd-ingest-docs --mode merge / gsd-import), jamais sans confirmation.
[doc-drift] 24 commits de code depuis la dernière mise à jour de la doc.
            → propose gsd-docs-update.
```

### 4.2 Invariants tenus par les trois scripts

- **Silence par défaut** : rien à dire → aucune sortie, exit 3. Le coût contexte d'un projet sain
  est nul.
- **Advisory, jamais bloquant** : aucun script ne sort en 1 ; le hook est suffixé `|| true`.
  Aucun `Stop` hook, aucun blocage de tour.
- **Aucune écriture** : les trois scripts sont en lecture seule. La confirmation humaine reste
  devant chaque geste proposé (ADR-031, et pour l'ingestion les garde-fous BRDG-03 déjà écrits
  dans `ingestion-flow.md`).
- **Densité** : ≤ 2 lignes par signal. `[bootstrap]` et `[onboard]` étant exclusifs, une session
  ne peut porter que **3 signaux au maximum**.
- **Le fait, jamais le métier** (ADR-055 §3) : les scripts constatent, l'agent juge.

---

## 5. Doctrine agent

`AGENT.md` de `vibeflow-dev` gagne une section courte **Signaux de démarrage**, qui mappe chaque
signal au geste correspondant et rappelle que la confirmation reste requise. Objectif : cohérence
du routage quand c'est bien `vibeflow-dev` qui est aux commandes, sans dupliquer la carte
d'intention existante — un tableau de 4 lignes, pas une doctrine parallèle.

La contrainte de densité ADR-029 (agent ≤ 250 lignes) est respectée : `AGENT.md` fait 168 lignes.

---

## 6. Choix écartés

| Option | Raison de l'écart |
|---|---|
| Durcir la doctrine `AGENT.md` sans hooks | C'est exactement le mécanisme actuel, et c'est ce qui ne fonctionne pas : rien ne garantit qu'un modèle applique une ligne de prose. |
| `PostToolUse` sur l'écriture d'une spec | Surface supplémentaire sur chaque `Write`. Conséquence assumée : une spec écrite en cours de session est signalée à la session **suivante** ; la doctrine agent couvre déjà le cas à chaud. |
| Un verbe/skill dédié pour dérouler le parcours | Les verbes-façade ont été supprimés en v2.33.0 (arbitrage direct, aucun retour arrière). L'entrée reste le langage naturel. |
| Deux scripts séparés pour brownfield et bootstrap | États mutuellement exclusifs du même continuum ; chacun devrait tester la condition de l'autre. |
| Exécution automatique du geste proposé | Interdit par ADR-031 (jamais de fix sans validation humaine) et par BRDG-03 pour l'ingestion. |

---

## 7. Livraison

**Fichiers créés**

- `plugin/dev-orchestrator/hooks/hooks.json`
- `plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh`
- `plugin/dev-orchestrator/scripts/check-doc-drift.sh`
- `plugin/dev-orchestrator/scripts/tests/test-check-dev-bootstrap.sh`
- `plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh`

**Fichiers modifiés**

- `plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh` (mode `--hook`)
- `plugin/dev-orchestrator/scripts/tests/test-discover-unintegrated-docs.sh` (couverture `--hook`)
- `plugin/dev-orchestrator/AGENT.md` (section *Signaux de démarrage*)
- `plugin/dev-orchestrator/README.md`, `CHANGELOG.md`, `VERSION`, `module.json` → **v2.5.0**

**Release** (règle non négociable du repo)

`VERSION` racine → **v2.41.0**, plus `plugin/.claude-plugin/plugin.json`,
`.claude-plugin/marketplace.json`, historique et badges des deux README. Après merge : tag annoté
`v2.41.0`, release GitHub sur le tag, puis `bash scripts/check-release-tag.sh --remote` → `✓`.

**Critères d'acceptation**

1. Sur un repo sain et complètement cadré : les trois scripts sortent en 3, **aucune ligne**
   injectée au démarrage.
2. Sur un repo de code sans `.planning/` : signal `[onboard]` unique — aucun signal `[bootstrap]`
   (exclusion mutuelle vérifiée par test).
3. Sur un projet fraîchement initialisé sans `config.json` : signal `[bootstrap]` listant les items
   manquants, et lui seul.
4. Sur un repo avec 3 specs non citées : signal `[docs-ingest]` annonçant 3 documents, et
   `discover-unintegrated-docs.sh` **sans** `--hook` sort toujours son contrat historique
   `grain<TAB>chemin` inchangé.
5. `--hook` et `--quiet` ensemble → exit 64.
6. `bash plugin/conductor/scripts/check-agents.sh` passe après modification d'`AGENT.md`.
7. Les tests des trois scripts passent sous `bash` macOS **et** Linux (portabilité CI — cf.
   régression du 2026-07-27).
