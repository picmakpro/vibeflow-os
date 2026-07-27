# Phase 17: Signaux de démarrage du moteur de dev - Context

**Gathered:** 2026-07-27 (assumptions mode, non-interactif — délégué par `vf-dev-manager` (n1) à
`vf-coder`, sans `AskUserQuestion` disponible — même protocole que 13-CONTEXT.md)
**Status:** Ready for planning
**Portée de ce cadrage** : les DEUX plans de la phase — scripts + hooks (création) et doctrine
agent + tests + release-meta module (extension/durcissement). Le découpage exact en 1 ou 2
fichiers `17-NN-PLAN.md` est laissé au planner (`gsd-plan-phase`), sous contrainte de
séquencement D-14.

<domain>
## Phase Boundary

Source : `docs/superpowers/specs/2026-07-27-signaux-demarrage-dev-design.md` (fait foi, 291
lignes, lue intégralement) + `.planning/ROADMAP.md` §Phase 17 (6 critères + 2bis, **SC1 amendé**
par arbitrage humain du 2026-07-27 — voir D-00).

Le phase livre EXACTEMENT les 9 fichiers de la spec §7 :

**Créés**
1. `plugin/dev-orchestrator/hooks/hooks.json`
2. `plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh`
3. `plugin/dev-orchestrator/scripts/check-doc-drift.sh`
4. `plugin/dev-orchestrator/scripts/tests/test-check-dev-bootstrap.sh`
5. `plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh`

**Modifiés**
6. `plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh` (mode `--hook`, additif)
7. `plugin/dev-orchestrator/scripts/tests/test-discover-unintegrated-docs.sh` (cas 17+)
8. `plugin/dev-orchestrator/AGENT.md` (section courte *Signaux de démarrage*)
9. `plugin/dev-orchestrator/README.md`, `CHANGELOG.md`, `VERSION`, `module.json` → **v2.5.0**

**Ne produit PAS** (hors périmètre explicite, mandat n1 + convention repo) :
- Aucun bump de la `VERSION` racine, aucun tag git, aucune modification de
  `plugin/.claude-plugin/plugin.json` ni `.claude-plugin/marketplace.json` — la release racine
  `v2.41.0` proposée en spec §7 est un **reste-à-faire post-exécution**, réservé à validation
  humaine (même patron que Phase 13, D-08 domain de `13-CONTEXT.md`).
- Aucune modification de `.github/workflows/ci.yml` : la découverte de suites est déjà générique
  (`find plugin scripts -type f -path '*/tests/test-*.sh'`, `ci.yml:32`) et ramasse les 3 nouvelles
  suites sans édition. Vérifié en amont (n1), pas à re-découvrir en plan.
- Aucune modification de `plugin/_internal/vibeflow-update.sh` : `merge_module_hooks` /
  `remove_module_hooks` savent déjà fusionner/retirer un fragment `hooks/hooks.json` de module
  (existant, confirmé par le pattern `planning-core`) — aucun câblage supplémentaire requis pour
  qu'un premier fragment apparaisse sur `dev-orchestrator`.
- Aucune réécriture du contrat historique de `discover-unintegrated-docs.sh` (`grain<TAB>chemin`,
  exits 0/3/64) : `--hook` est un flag d'affichage additif, jamais un remplacement.
- Aucune nouvelle référence `references/*.md` pour la doctrine agent : la spec §5 est explicite —
  « un tableau de 4 lignes, pas une doctrine parallèle » directement dans `AGENT.md`.
</domain>

<decisions>
## Implementation Decisions

### D-00 — Arbitrage humain déjà tranché (à appliquer, pas à re-discuter)

- **D-00 [informational]:** SC1 du ROADMAP contredisait la spec (§4.2, §7) et se contredisait
  lui-même avec SC2/SC2bis de la même entrée. Samuel a tranché le 2026-07-27 : SC1 devient *« les
  trois scripts sortent en 3 et la **seule** ligne injectée est le `[gsd-engine]` d'orientation »*.
  Geste 1 (amendement ROADMAP) et geste 2 (trace STATE §Decisions datée, attribuée à Samuel) sont
  **déjà faits par n1** avant d'écrire ce contexte — voir diff `.planning/ROADMAP.md` et
  `.planning/STATE.md`. Le plan et son exécution s'appuient sur la version amendée, jamais sur la
  version contradictoire. Informational : déjà exécuté, aucune tâche de plan n'est requise pour ce
  point, seule la version amendée doit être respectée.

### `check-dev-bootstrap.sh` — continuum à 4 états (spec §3.1)

- **D-01 (ordre d'évaluation, premier qui matche gagne) :**
  0. ni code source ni `.planning/` → silence, exit 3.
  1. code source présent, `.planning/` absent → signal `onboard`, exit 0.
  2. `.planning/PROJECT.md` présent, ≥1 item de démarrage manquant → signal `bootstrap` + liste,
     exit 0.
  3. `.planning/PROJECT.md` présent, tous items posés → signal `engine` (1 ligne), exit **3**
     (c'est une orientation, pas une dette — piège de test D-09).
  argument inconnu → message stderr, exit 64.
- **D-02:** Détection « code source présent » par `find` avec élagage `-prune` AVANT descente —
  réutiliser **textuellement** le motif `PRUNE_VENDOR` de
  `plugin/planning-core/scripts/detect-planning-debt.sh:54` (`.git`, `node_modules`, `.venv`,
  `vendor`, `dist`, `build`, `.next`), **étendu** pour ce script à `docs/`, `.planning/`, `.claude/`
  (spec §3.1 : ces trois dossiers ne comptent pas comme code). Un seul fichier hors élagage suffit
  (`head -n 1`, jamais de comptage exhaustif — même contrainte perf que le script source). Pas de
  dépendance à `git` : un dossier non versionné doit pouvoir être détecté brownfield.
- **D-03:** Items de l'état 2, ordre de restitution figé :
  1. `config` — `.planning/config.json` absent → geste `gsd-config`.
  2. `codebase` — code présent **et** `.planning/codebase/` absent ou vide → geste
     `gsd-map-codebase`. Conditionné à la présence de code (greenfield n'a rien à cartographier).
  3. `roadmap` — `.planning/ROADMAP.md` absent, ou présent sans aucune phase → geste
     `gsd-plan-phase` (ou `gsd-new-milestone`).
- **D-04 (état 3 — signal `[gsd-engine]`)** : lit le frontmatter YAML de `.planning/STATE.md`
  (`milestone`, `current_phase`, `status` — mêmes clés que celles vérifiées en tête de ce fichier
  d'état, ex. `milestone: gsd-migration`, `current_phase: 15`, `status: shipped`). Format de sortie
  fixé par la spec (§3.1) :
  ```
  [gsd-engine] Projet piloté par GSD — milestone <milestone>, phase <current_phase> <état dérivé>.
               → cadrage : gsd-discuss-phase · plan : gsd-plan-phase · état : gsd-progress.
  ```
  Frontmatter absent, illisible, ou une des 3 clés manquante → **silence total**, jamais d'état
  inventé (retombe au comportement générique de l'état 3 : exit 3, pas de ligne).
- **D-05:** Env de surcharge (testabilité) : `VF_BOOTSTRAP_PLANNING_DIR` (défaut `<path>/.planning`)
  — même modèle que `VF_INGEST_*` de `discover-unintegrated-docs.sh`. Flags CLI :
  `[--path <dir>] [--hook] [--quiet]`, défaut `--path .`. `--hook` change uniquement le format
  d'affichage (comme pour les deux autres scripts) — les 4 exits restent identiques avec ou sans.

### `discover-unintegrated-docs.sh --hook` (extension additive, D-06)

- **D-06:** Contrat historique **strictement figé** : sortie `grain<TAB>chemin`, exits 0/3/64,
  sans `--hook`. Aucune ligne du script actuel (`scripts/discover-unintegrated-docs.sh`, lu
  intégralement) n'est modifiée en dehors de l'ajout du flag et de sa branche d'affichage.
- `--hook` : au lieu de la liste triée, émet **une ligne agrégée** `[docs-ingest] N documents de
  cadrage hors feuille de route (X spec, Y plan).` suivie du geste (modèle spec §4.1), sur stdout,
  dans les mêmes conditions d'exit que le mode normal (exit 0 si ≥1 document, exit 3 sinon).
- `--hook` et `--quiet` **ensemble** → exit 64 avec message stderr, avant toute autre logique (gate
  en tête de parsing d'arguments, même position que le gate `--path` sans valeur existant).

### `check-doc-drift.sh` (nouveau, spec §3.3)

- **D-07:** Heuristique : nombre de commits ayant touché du **code source** depuis le dernier
  commit ayant touché `docs/**` (arbre entier) **ou** un `README*` **à la racine seulement** — pas
  les README de module (`plugin/*/README.md` ne comptent PAS comme mise à jour de doc pour cette
  heuristique globale, sans quoi tout commit touchant un des 17 modules ferait taire le signal).
  Aucun commit de doc dans l'historique → silence, exit 3 (jamais de division par un historique
  vide).
- **D-08:** Seuil : `--threshold <N>`, défaut **20**. `compte < seuil` → silence exit 3 ;
  `compte ≥ seuil` → signal `[doc-drift]` exit 0.
- **D-09:** Silence hors dépôt git : pas un dépôt git (`git rev-parse --is-inside-work-tree`
  échoue) → silence, exit 3. Flags : `[--path <dir>] [--threshold <N>] [--hook] [--quiet]`.
  `--hook`/`--quiet` ensemble → exit 64 (même gate que D-06).
- Advisory assumé le plus bruyant des trois (spec §3.3) : jamais « la doc est fausse », seulement
  « la doc n'a pas bougé depuis N commits ».

### `hooks/hooks.json` (nouveau)

- **D-10:** Contenu verbatim de la spec §3.4 (description + `SessionStart:startup` × 3
  commandes, chacune suffixée `|| true`). Aucune conception à refaire — copier tel quel. Modèle de
  gabarit `{{VF_SCRIPTS}}` confirmé identique à `plugin/planning-core/hooks/hooks.json` (lu
  intégralement) : le placeholder est résolu par l'engine à l'install, aucune modification
  `vibeflow-update.sh` requise (`merge_module_hooks`/`remove_module_hooks` gèrent déjà l'ajout d'un
  premier fragment de hooks à un module qui n'en avait aucun).

### Doctrine agent — `AGENT.md` (D-11, densité ADR-029)

- **D-11:** Nouvelle section courte « Signaux de démarrage », insérée entre « Next steps & hygiène
  documentaire » (l.97-109 actuelles) et « Heuristiques de routage » (l.111 actuelles) — pas une
  nouvelle référence externe (spec §5 explicite : 4 lignes dans `AGENT.md`, pas une doctrine
  parallèle). Table de **4 lignes** — les 4 signaux nouveaux de cette phase (`[bootstrap]`,
  `[onboard]`, `[gsd-engine]`, `[doc-drift]`) ; `[docs-ingest]` n'est **pas** dans cette table,
  déjà couvert par la ligne existante l.63 de la table « Amont & cadrage » (renvoi
  `ingestion-flow.md`) — ne pas dupliquer.
- Chaque ligne rappelle : signal → geste proposé → confirmation requise (ADR-031). `AGENT.md` fait
  167 lignes actuellement, plafond 250 (ADR-029) — marge large, pas de risque de dépassement.

### Gate ADR-044 — fait vérifié par n1, à appliquer tel quel (D-12)

- **D-12:** `bash plugin/conductor/scripts/check-agents.sh` **sans argument** sort exit 0 trivialement
  (`.claude/agents` absent dans ce repo — faux vert, critère 6 de la spec tel qu'écrit est
  infalsifiable). L'agent modifié (`plugin/dev-orchestrator/AGENT.md`) est à la racine du module,
  **hors** de `plugin/dev-orchestrator/agents/` — donc hors de la boucle CI `plugin/*/agents`
  (`.github/workflows/ci.yml:76`, vérifié).
- **Invocation correcte, vérifiée par n1** : `bash plugin/conductor/scripts/check-agents.sh --file
  plugin/dev-orchestrator/AGENT.md` → exit 0, **3 warnings baseline** (name≠fichier, aucun skill
  câblé, `tools:` absent). Le plan doit exiger que ces 3 warnings **ne se dégradent pas** (jamais
  plus de 3, jamais un nouveau type de warning) après l'ajout de la section Signaux de démarrage.
- **Fermer le trou structurellement, pas juste le documenter** : ajouter un cas dans
  `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (nouvel axe T20, numérotation
  T1..T19 déjà prise) qui invoque `check-agents.sh --file plugin/dev-orchestrator/AGENT.md` et
  assert `exit 0` **et** le compte de warnings (`grep -c '⚠'` sur la sortie, égal à la baseline).
  Comme ce fichier est ramassé par la découverte générique de `ci.yml:32`, ce test embarqué rend
  la vérification ADR-044 de cet agent **CI-enforced sans toucher `ci.yml`** — ferme le trou plutôt
  que de le documenter seulement (cf. mémoire `check-agents-scope` : le gate module `plugin/*/agents`
  ne couvre jamais un `AGENT.md` racine de module).

### Portabilité Linux — preuve, pas édition CI (D-13, fait vérifié par n1)

- **D-13:** `ci.yml` découvre déjà génériquement (`find plugin scripts -type f -path '*/tests/test-*.sh'`,
  `runs-on: ubuntu-latest`) — les 3 nouvelles suites sont ramassées **sans édition**. Le travail de
  ce plan est de **prouver AVANT push**, pas de modifier la CI :
  1. **Conteneur Linux local** (Docker disponible sur cette machine) : lancer les 3 nouvelles
     suites (+ `test-discover-unintegrated-docs.sh` étendu) dans une image `bash` Linux
     (ex. `debian:bookworm-slim` ou `bash:5` — le planner choisit une image concrète disponible),
     jamais seulement sur macOS.
  2. **Réutiliser les idiomes déjà portables du repo**, ne pas en inventer de nouveaux : le motif
     `PRUNE_VENDOR` de `detect-planning-debt.sh`, `mktemp` + `trap ... EXIT`, `LC_ALL=C sort`, awk
     POSIX (pas de `gsub` global piégeux — cf. commentaire `discover-unintegrated-docs.sh:100-101`),
     `set -uo pipefail`, jamais de `sed -i` sans extension portable, jamais de builtin bash4+
     exclusif (`mapfile`, `${var,,}`) sans vérifier la version bash Linux cible.
  3. **Recherche portabilité en parallèle (n0 du DAG de mission)** : un autre nœud recherche les
     règles précises extraites des 6 fixes CI du 2026-07-27. Son livrable (emplacement encore
     inconnu au moment de ce cadrage — n0 tourne en parallèle) est une **entrée obligatoire** pour
     l'exécution (n2 dépend de n0 ET n1) : le plan doit instruire l'exécuteur de le lire s'il
     existe avant d'écrire les 2 nouveaux scripts, sans bloquer l'écriture du plan lui-même dessus.
  4. Ne jamais cocher SC6/critère 7 sur un run macOS seul — le conteneur (ou la CI elle-même,
     post-push) est la seule preuve valable.

### Piège de test — sortie ET exit asserés séparément (D-14, fait vérifié par n1)

- **D-14:** À l'état 3 de `check-dev-bootstrap.sh`, le script **imprime une ligne ET sort en 3** — rupture de
  la convention « exit 3 ⇔ silence » que suivent les deux autres scripts (et les états 0 de
  `check-dev-bootstrap.sh` lui-même). Toute suite de test doit **asserter séparément**, pour
  **chaque état des 3 scripts** : (a) le code de sortie, (b) le contenu exact de stdout (vide ou
  non), (c) le contenu de stderr le cas échéant. Une assertion combinée du type « exit 3 donc pas
  de sortie » est un piège connu — le cas état-3 le rendrait faussement vert ou faussement rouge
  selon le sens de l'erreur. `test-check-dev-bootstrap.sh` doit avoir un cas dédié qui vérifie
  **positivement** que l'état 3 produit à la fois une sortie non vide ET exit 3.
- Exclusion mutuelle des 3 signaux exclusifs (`bootstrap`/`onboard`/`engine`) — SC2 du ROADMAP —
  est prouvée par des fixtures qui construisent chaque état isolément et vérifient qu'aucun autre
  signal ne fuit dans la sortie.

### Invariants SC5 (lecture seule, advisory) — D-15

- **D-15:** Les 3 scripts (2 nouveaux + `discover-unintegrated-docs.sh` déjà conforme) : **aucune écriture**
  sur le filesystem hors leurs propres fichiers temporaires (`mktemp`, nettoyés par `trap EXIT`),
  **aucun exit 1** dans le contrat de sortie (seuls 0/3/64), et le hook les invoque tous suffixés
  `|| true` (déjà dans le JSON verbatim D-10) — aucun `Stop` hook, aucun blocage de tour. Un test
  dédié peut vérifier qu'aucun des 2 nouveaux scripts ne contient d'`exit 1` littéral et qu'aucun
  n'écrit hors `mktemp`/stdout/stderr (grep structurel, pas juste documentaire).

### Release-meta du module (D-16)

- **D-16:** Nouvelle capacité (hooks + 2 scripts) → bump **mineur** (convention `CLAUDE.md` racine),
  `v2.4.0` → **`v2.5.0`**. 4 fichiers : `VERSION`, `module.json` (`"version"`), `CHANGELOG.md`
  (nouvelle entrée datée), `README.md` (ligne Version, section Historique, section Structure du
  module avec `hooks/hooks.json` + les 2 nouveaux scripts + leurs tests). **Aucun** bump racine, ni
  tag, ni release GitHub (domain, D-08 du mandat n1) — proposition `v2.41.0` remontée à l'humain
  en fin de mission, jamais planifiée ici.

### Claude's Discretion

- Découpage exact en 1 ou 2 `17-NN-PLAN.md` (le planner choisit ; suggestion : un plan pour
  scripts+hooks+tests machine, un pour doctrine agent+release-meta+preuve portabilité — mais pas
  contraignant).
- Formulation exacte des lignes de la table « Signaux de démarrage » d'`AGENT.md` (verbes NL réels,
  cohérents avec le style des tables voisines — pas de nom `gsd-*` cru hors table de brique).
- Choix précis de l'image Docker pour la preuve Linux (D-13.1) — n'importe quelle image bash Linux
  suffisamment récente convient, tant que la preuve est réellement exécutée avant push.

### Folded Todos

Non vérifié via `gsd-sdk query todo.match-phase "17"` dans ce cadrage (pas d'accès à l'outil
depuis ce contexte) — à vérifier par le planner s'il en a l'accès ; aucun todo connu par ailleurs.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `docs/superpowers/specs/2026-07-27-signaux-demarrage-dev-design.md` — fait foi, lue intégralement
  (291 lignes).
- `.planning/ROADMAP.md` §Phase 17 (SC1 amendé D-00, SC2-SC6 + 2bis).
- `.planning/STATE.md` §Decisions (entrée arbitrage SC1 du 2026-07-27) + frontmatter (clés lues par
  D-04 : `milestone`, `current_phase`, `status`).
- `plugin/dev-orchestrator/AGENT.md` (167 lignes, plafond 250 — ADR-029) — insertion D-11.
- `plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh` (142 lignes, lu intégralement) —
  contrat historique à ne jamais casser (D-06).
- `plugin/dev-orchestrator/scripts/tests/test-discover-unintegrated-docs.sh` (16 cas actuels,
  numérotation 17+ libre pour `--hook`).
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (T1..T19 pris, T20 libre —
  D-12).
- `plugin/planning-core/scripts/detect-planning-debt.sh` (motif `PRUNE_VENDOR` l.54, modèle exact
  pour D-02).
- `plugin/planning-core/hooks/hooks.json` (modèle exact confirmé pour le gabarit `{{VF_SCRIPTS}}`,
  pattern `|| true`).
- `plugin/conductor/scripts/check-agents.sh` — invocation `--file` vérifiée par n1 (D-12), exit 0 +
  3 warnings baseline sur `AGENT.md` actuel.
- `.github/workflows/ci.yml:32` (découverte générique des suites), `:66-104` (boucle
  `plugin/*/agents`, hors périmètre de l'`AGENT.md` racine du module — confirme D-12).
- `plugin/dev-orchestrator/VERSION`, `module.json`, `CHANGELOG.md`, `README.md` (état v2.4.0).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `PRUNE_VENDOR` de `detect-planning-debt.sh:54` : motif `find -prune` exact à réutiliser/étendre
  pour `check-dev-bootstrap.sh` (D-02).
- Style manifest `hooks/hooks.json` de `planning-core` : `SessionStart:startup`, description en
  tête, `|| true` sur chaque commande — gabarit direct pour le nouveau fragment (D-10, contenu déjà
  donné verbatim par la spec §3.4).
- Pattern `VF_INGEST_*` (env de surcharge testable) de `discover-unintegrated-docs.sh:30-33` —
  modèle direct pour `VF_BOOTSTRAP_PLANNING_DIR` (D-05).
- Harnais de test maison (`PASS`/`FAIL`, fonctions `ok`/`ko`, `mktemp -d` + `trap ... EXIT`, cas
  numérotés en commentaire `# === Cas N ===`) : gabarit à reproduire tel quel pour
  `test-check-dev-bootstrap.sh` et `test-check-doc-drift.sh` (voir
  `test-discover-unintegrated-docs.sh` intégralement lu).
- awk POSIX portable (échappement caractère par caractère des métacaractères ERE, padding espace
  au lieu d'ancres `^$`) — modèle si `check-doc-drift.sh` ou `check-dev-bootstrap.sh` ont besoin de
  matching textuel (probable pour le parsing du frontmatter YAML de `STATE.md`, D-04).

### Established Patterns

- Convention de version : `CLAUDE.md` racine — « nouvelle capacité → minor ». Précédent direct :
  Phase 13 (`ingestion-flow.md` neuf) → `v2.1.1` → `v2.2.0` mineur. Même patron ici (D-16).
- Le rôle FAIT vs JUGEMENT (ADR-055 §3) traverse toute la spec : les 3 scripts **constatent**,
  l'agent **juge**. Aucune tentation à corriger en plan — c'est déjà l'architecture demandée.
- Précédent Phase 13/15 : le champ ROADMAP « Requirements » a été laissé `TBD` sur des phases
  shippées sans jamais être résolu en IDs `REQUIREMENTS.md` formels — hors-milestone. Ce mandat
  demande explicitement de le résoudre pour la Phase 17 (dérivation inline dans le champ ROADMAP,
  périmètre d'écriture de n1 n'incluant pas `REQUIREMENTS.md`).

### Integration Points

- Hook `SessionStart` injecte dans le contexte de la **session principale** (pas celui de l'agent
  `vibeflow-dev`, chargé seulement à son invocation) — spec §4.1, déjà la raison d'être de toute la
  phase, aucune ambiguïté à lever.
- `merge_module_hooks`/`remove_module_hooks` de `plugin/_internal/vibeflow-update.sh:293,319` —
  moteurs externes au module, jamais réimplémentés ni modifiés par ce plan (D-10).
</code_context>

<specifics>
## Specific Ideas

Aucune idée hors du périmètre déjà cadré par la spec — la portée est entièrement dérivée de sa
§7 (livraison) et des faits vérifiés par n1 (D-12, D-13, D-14).
</specifics>

<deferred>
## Deferred Ideas

- **Release racine `v2.41.0`** (bump `VERSION`, tag annoté, release GitHub) — explicitement hors
  du plan par mandat n1, réservée à validation humaine post-exécution (même patron que Phase 13).
- **Lint réel du contenu `Agent(...)` dans `check-agents.sh`** (Phase 16, en cours/à venir) — hors
  périmètre, ne pas anticiper ici malgré la proximité thématique avec D-12 (celui-ci ne concerne
  que la présence/absence du fichier `--file`, pas le contenu d'une allowlist `tools:`).
- **PostToolUse sur l'écriture d'une spec** (option écartée en spec §6) — confirmé hors scope,
  aucune tentative à planifier.
- **Verbe/skill dédié pour dérouler le parcours** (option écartée en spec §6, façades supprimées
  v2.33.0) — confirmé hors scope.
</deferred>
