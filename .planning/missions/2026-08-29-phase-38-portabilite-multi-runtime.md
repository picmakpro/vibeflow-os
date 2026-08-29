# Mission — Phase 38 : portabilité multi-runtime (livraison)

**Branche** `feat/phase-38-portabilite-multi-runtime` · worktree `phase-38` · base `4ebd700`
**Milestone** `fiabilite-v1.0` · **Non shippé** : aucune PR, aucun tag, aucun bump de `VERSION`
racine, aucune release. `VERSION` = **v2.58.1**, inchangée.

---

## Verdict sur les six critères de Samuel

| # | critère | verdict |
|---|---|---|
| 1 | lab installé sur Codex, skills **déclenchables**, agents **enregistrés**, hooks portés, désinstallation réversible | ⚠️ **partiel** — voir détail |
| 2 | aller-retour **réel** manager → worker sur Codex, profondeur ≥ 2 | ❌ **NON ATTEINT — inconnu déclaré** |
| 3 | gate de fidélité rendant les champs perdus et marqueurs morts, **vide ou assumé, jamais silencieux** | ✅ **atteint** |
| 4 | OpenCode et kimi-code **installés** et pose **mesurée** | ✅ **atteint** (exécution : inconnu déclaré) |
| 5 | lab migrable **ou** coexistant sans se croire entier, runtime **inscrit**, réversibilité prouvée | ✅ **atteint** |
| 6 | aucune régression Claude | ✅ **atteint** |

### Critère 1 — le détail, sans arrondi
**Mesuré sur une install réelle** (309 chemins posés, rc=0) : pose ✅ · skills **réellement
déclenchables** ✅ (témoin découvert **par sa description**, Codex a lu le fichier de lui-même) ·
agents enregistrés ✅ (corrigé : un rôle **par agent**, plus un par module) · gate de fidélité ✅
(corrigé : il mesure l'artefact **réellement posé**) · désinstallation ✅ (corrigée : les rôles
Codex sont retirés) · **hooks ❌ non portés** — la surface Codex existe et est **prouvée
exécutante**, VibeFlow ne la vise pas ; la perte est désormais **déclarée à l'install ET au
`status`**, avec un texte vrai.

### Critère 2 — pourquoi il n'est pas atteint
Profondeur **1 sur 2**. Deux causes successives, la seconde **externe** :
1. `model = "opus"` était recopié littéralement dans les rôles Codex, où ce modèle n'existe pas —
   **tout spawn échouait**. **Corrigé** (table de mapping explicite, inconnu → rouge).
2. Le run témoin de réparation a été coupé **avant le second spawn** : **quota ChatGPT épuisé**,
   réarmement annoncé au **27 septembre 2026**, confirmé par sonde de contrôle indépendante.

**Ce qui EST prouvé** : rôle chargé et **spawnable par son nom** · **modèle par worker honoré**
(2 valeurs distinctes lues en base sur 2 runs) · rapport typé `--output-schema` conforme 2/2.
**Ce qui ne l'est pas** : la chaîne root → manager → **worker**.
→ **`38-RUNBOOK-MESURE-CODEX.md`** rend la preuve faisable **en une séance** dès qu'un quota existe :
commandes exactes, banc, **5 critères 0/N sans moyenne possible**, et les **neuf pièges déjà payés**.

---

## Les sept lots livrés

| Lot | Objet | Sortie constatée |
|---|---|---|
| `38-01` | Gate de fidélité | mesure le **TOML posé** (`MODE=adapter`), 4 verdicts, marqueurs morts comptés |
| `38-02` | **Installeur multi-runtime** | table de dispatch à 4 verbes, **12 sites** CLI-couplés désaccouplés |
| `38-03` | Rollback | agents + hooks + `mark_installed` + glob ancré, `--dry-run` |
| `38-04` | `--target` injectable | site d'injection unique + **réécriture du payload à la copie** + sonde cross-module |
| `38-05` | Adaptateur Codex minimal | rôle `.toml` dispatchable, limite de confinement **déclarée** |
| `38-06` | Migration de lab | runtime dans `config.json`, coexistence gatée, réversibilité prouvée |
| `38-07` | 3 bloquants de la mesure | 12 agents enregistrés, uninstall symétrique, perte hooks déclarée |

### Lot 2 (`38-02`, RUNT-01/02) — le lot qui manquait au rapport

Le seul plan de la phase resté **sans SUMMARY** jusqu'à la clôture : livré, puis corrigé par des
mandats ciblés successifs (revue, revue de jointure, mesure OpenCode/kimi), si bien que le cycle
plan→exécution ne s'est jamais refermé sur lui. Régularisé sur pièces en `9dda4b8`, écriture tardive
**déclarée en tête** plutôt que maquillée.

- **Périmètre réel plus large que le cadrage** : **12 sites exécutables sur 4 fichiers**, 4 verbes —
  contre 11 sites sur 2 fichiers annoncés. L'écart est venu de la mesure, pas d'une extension de scope.
- **Fichiers** : `plugin/_internal/runtime-cli-dispatch.sh` (créé, + sa suite), `ensure-deps.sh`,
  `ensure-design-deps.sh` (**5 sites**), `check-plugin-update.sh`, `vf-update-run.sh` (+ garde T9e).
- **Commits** : `2d392a7` (dispatch + test) · `877a97d` (`ensure-deps`) · `d6ff0d4` (`ensure-design-deps`
  5 sites + `check-plugin-update` + `vf-update-run` + garde T9e) · `f9f7dc4` (compteur README, à part).
  Correctifs post-revue : `40c8f0f`, `c6e5c60`, **`c8dea13`** (bloquant de jointure), `45cb868`, `f0973f1`.
- **Décisions** : sonde kimi-code **par capacité** (`--output-format`) et non par nom de binaire —
  validée contre le vrai binaire avec un PATH isolé ; `trust_level` **déclaré, jamais écrit** ; aucune
  grammaire d'install Codex inventée.
- **Le défaut le plus cher** est né ici : `runtime-cli-dispatch.sh` **n'était posé nulle part** — la
  capacité n'existait qu'à la première install. Trouvé par la **revue de jointure**, pas par les suites,
  qui étaient vertes. Origine : une fausse analogie (« cascade EXACTE de `find_hooks_merger()` »).
  D-38-M et D-38-N en sont sortis.
- **Garde T9e** : trois trous successifs, refermés seulement après avoir **refusé un troisième
  point-fix** et exigé une preuve générative — 60 combinaisons, 8 rouges, 0 après.

---

## Ce que la mesure a démenti — 8 prémisses documentaires tombées
Aucun descripteur consulté n'a survécu intact. Par ordre de coût évité :

1. **La contrainte de nommage `[a-z0-9_]+`** portait sur le `task_name` du spawn, **pas** sur le nom
   de rôle → **une table de mapping de 31 agents supprimée**, remplacée par une normalisation d'une
   ligne. *Mesure juste, attribution fausse.*
2. **`fork_turns:"all"` n'écrase pas** le `model` du rôle → risque n° 1 écarté.
3. **Tout ce qui restreint dans un rôle Codex est décoratif** — `sandbox_mode`, `approval_policy`,
   `[permissions]`, `[skills] enabled` : acceptés puis **inertes**. Un rôle `read-only` a **écrit sur
   le disque**. → architecture des juges changée (session séparée, D-38-E).
4. **`multi_agent_v2` est une précondition dure** : sans lui, **aucun outil de spawn n'existe**.
5. **Les rôles de scope projet sont gatés par `trust_level`** : sans trust, ils ne sont **même pas
   parsés** et `doctor` répond `overall: ok`.
6. **OpenCode a un bus de hooks vivant** (plugin JS chargé, factory exécutée) — « 6 fragments perdus
   par construction » était faux : perdus **par le canal choisi**.
7. **kimi-code honore réellement `disallowedTools`** — mieux que Codex **et** OpenCode — mais son
   `tools` est une **allowlist**, donc `Agent(...)` y devient invalide : dispatch perdu.
8. **kimi-code enregistre des sous-agents nommés custom** et **a** `update` — descripteur gsd-core
   **et** notre propre `team-kernel.md` étaient périmés.

---

## Défauts trouvés par les étages de contrôle
**11 revues**, dont une **revue de jointure** et un **audit sécurité**. Les trois plus coûteux
n'étaient visibles par **aucune suite** :

- **`runtime-cli-dispatch.sh` n'était posé nulle part** → toute la capacité multi-runtime ne
  s'activait **qu'au premier run d'install**. Trouvé par la **revue de jointure** : chaque relecteur
  de lot voyait un code correct dans son périmètre.
- **Traversée de chemin** — un champ `name:` de frontmatter suffisait à **écrire ET supprimer** un
  fichier arbitraire. Trouvé par l'**audit**, reproduit par le manager. Le seul filet existant
  (regex de `check-agents.sh`) **n'est jamais invoqué par l'engine**.
- **Le gate de fidélité mesurait un artefact jamais posé** (Markdown gsd-core au lieu du TOML
  installé) → verdicts **contradictoires** dans le même log. L'outil anti-dégradation-silencieuse
  était **aveugle à ce qu'il installe**.

**Cinq fois**, un test vert n'a pas démontré son énoncé : fixture idéalisée · capture `2>&1` ·
test **encodant** le bug · test **skippé sur la plateforme du bug** · commandes documentées
inexécutables en lab. C'est la régularité dominante de cette phase.

---

## Garde-fous posés (le vrai héritage)
- **Assertion d'accord** `[fidelity]` ↔ `[codex-adapter]` — a **immédiatement** attrapé un désaccord
  introduit par un worker qui ignorait son existence.
- **Assertion d'ensembles install ⊆ `status`** (T28) — ferme la **classe** de la mitigation déclarée
  à un seul point d'observation, rencontrée **deux fois**.
- **Garde de convention** sur les `SKILL.md` : aucun chemin `plugin/*/scripts/` documenté.
- **Preuve générative** sur le garde T9e : 60 combinaisons, 8 rouges avant / 0 après — après trois
  trous successifs, la méthode de preuve a changé plutôt que le énième point-fix.
- **Test par hardlink** au lieu de la casse : tourne sur **toute** plateforme, y compris la CI Linux
  où le défaut vivait et où l'ancien test **skippait**.

---

## Inconnus déclarés — jamais comblés par inférence
- **Critère 2** (profondeur ≥ 2) — quota épuisé jusqu'au **2026-09-27**. Runbook prêt.
- **kimi-code** : enregistrement des agents posés, `disallowedTools` en session, firing des
  `[[hooks]]` — **login OAuth en échec serveur, 3 tentatives**. Voie restante : `kimi provider add`
  (clé API), **geste de Samuel**.
- **Canal hooks/plugins/`.rules` du dépôt jugé** : levier statique **trouvé** et vérifié à coût nul
  (`-c features.hooks=false`, `-c features.plugins=false`, acceptés en ligne) — mais la **fermeture
  du canal** exige une session (protocole ADPT-06, ≥ 3 répétitions, 0/N).
- **Hypothèse non tranchée** : la mesure a-t-elle **consommé** la fin du quota, ou la fenêtre
  était-elle déjà entamée ? La date de réarmement suggère la seconde, sans preuve.

---

## Dettes nommées
`D-38-R` (pose vers `hooks.json` Codex) · option A du rollback (staging atomique) · garde de cible
unifiée `--scope`/`--target` · **aucune primitive partagée de confinement de chemin côté engine**
(`CONCERNS.md`) · issue amont gsd-core **rédigée, NON envoyée** (`38-UPSTREAM-GSD-CORE-ISSUE.md`).

## État de la branche
**82 commits**, arbre propre. **75 suites / 0 échec** · `check-version-sync` **0** ·
`check-release-tag` **0** · `check-mission-invariants` **SAIN** · `check-agents` sur **lab
réellement installé** rc=0, **falsifiable** (témoin `model:` retiré → rc=1, dossier vide → rc=3).
**Aucune fuite Codex** dans un lab Claude : 0 `.toml`, 0 artefact `codex`, aucun registre écrit.
