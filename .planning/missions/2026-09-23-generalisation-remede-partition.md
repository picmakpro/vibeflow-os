# Mission — généraliser le remède de partition + ergonomie du choix (2026-09-23)

**Manager** : `vf-dev-manager` · **Verrou de driver** : `mission-partition-2026-09-23`,
génération `DRIVER.lock.gen.1790180290.84488` · **Base de mission** : `a962065` (= `origin/main`
au moment du cadrage, v2.65.0) · **Mode** : autonome, avec relais d'arbitrage vers la session
principale.

**Brief** : Samuel, session principale, 2026-09-23 — « généralise le remède à VibeFlow, ça ne doit
plus se reproduire ou être corrigé simplement. Et go sur le chantier et l'ergonomie du choix,
parallélise si possible. »

**Limites posées au brief** : aucune release, aucun tag, aucun merge de PR ; tout arbitrage de
doctrine remonte ; l'oracle d'une PR est la CI GitHub, pas un rejeu local.

---

## Plan de bataille (DAG `.planning/MISSION-PARTITION.dag.json`)

```
recon-A ─┐                        ┌─ discuss-A → plan-A → exec-A → revue-A + audit-A ─┐
         ├─ (inscription) ────────┤                                                    ├─ docs
recon-B ─┘                        └─ discuss-B → plan-B → exec-B ────────→ revue-B ────┘
```

`exec-B` dépend d'`exec-A` : la preuve d'usage de la 41.2 n'est pas mesurable sans le balayage de
la 41.1. Le reste est parallèle.

**Isolation** : un worktree par agent, sans exception (`.claude/worktrees/partition-inscription`,
`partition-a`, `partition-b`). Motif : deux workers ont partagé un arbre le 2026-09-23 lors de la
partition D-02 — signalé à temps, sans perte, mais le manager n'en reprend pas le risque. Et l'arbre
principal a effectivement changé de branche sous la mission en cours de route (merge de la PR #97
par une session concurrente), ce qui a obligé à ré-ancrer les deux reconnaissances sur un commit figé.

**Écriture du planning** : le manager est le seul écrivain de `ROADMAP.md`, `STATE.md`,
`REQUIREMENTS.md` et `BACKLOG.md`. Les workers remontent, il écrit. C'est ce qui rend la
parallélisation possible sans conflit.

---

## Gate de démarrage

| Geste | Résultat |
|---|---|
| `driver-lock.sh acquire` | `acquired: true`, génération `…1790180290.84488`, 0 orphelin |
| `check-mission-invariants.sh` | **rc=3 — SAIN** (tous les globs matchent au moins un fichier suivi) |
| `workflow._auto_chain_active` | déjà `false` — lu dans `.planning/config.json` (`gsd_run` absent de ce poste) |
| `workflow.auto_advance` | déjà `false` — même lecture |
| Arbre de départ | sale (mémoire d'agent `vf-reviewer` d'une autre session) — **non touché**, travail conduit en worktrees |

---

## État mesuré — ce qui motive les deux phases

### Consommateurs d'artefacts de planning (19, hors 22 suites de tests)

Établi par `git ls-files` + `awk` puis reclassé par lecture individuelle et **rejeu réel** de chaque
candidat. Le premier jeu de motifs, mesuré par `rtk proxy grep -rln`, rendait **45** fichiers contre
**46** par `awk` — `check-workstream-pointer.sh` manquait. L'écart valide la consigne de double mesure.

| Catégorie | Nombre | Détail |
|---|---|---|
| **(a1)** balaie **tous** les compartiments du disque | **1** | `check-divergence.sh` — glob `for _wsdir in "$WS_ROOT"/*/` **inline et écrit deux fois** (corps principal ~l.295-311 et dans `check_s5()` ~l.246-263), jamais factorisé. **Zéro compartiment découvert ⇒ `CHECKED=0` ⇒ exit 0** : un verdict vide passe pour un verdict vert. |
| **(a2)** workstream-aware, résout le **seul compartiment actif** par environnement | **8** | `check-state-integrity.sh`, `check-workstream-pointer.sh`, `check-dev-bootstrap.sh`, `check-mission-exit.sh` (E4), `check-requirements-survival.sh`, `restore-requirements-ledger.sh`, `requirements-survival-detect.sh`, `planning-context.sh` |
| **(b)** câblé en dur sur `fiabilite` | **2 sites, 1 fichier** | `.github/workflows/ci.yml:353` et `ci.yml:844` (verdict R5). Conséquence : **`gouvernance/STATE.md` n'est vérifié nulle part en CI.** |
| **(c)** suppose encore la racine `.planning/` | **5** | dont **3 faux aujourd'hui** (ci-dessous) et 2 muets par conception d'altitude lab (`detect-planning-debt.sh`, `planning-task-context.sh`) |
| *(d) hors périmètre (racine partagée, ou mention en commentaire)* | *8* | `config.json`, `DRIVER.lock`, baseline du budget d'instructions… |

`plugin/planning-core/scripts/workstream-policy.sh` — **aucune primitive d'énumération**. Toute son
API est singulière (`vf_ws_resolve`, `vf_ws_dir_resolve`, `vf_ws_file_in_ws`). La seule brique
réutilisable pour un balayage est `vf_ws_path_nolink`, filtre par entrée. **C'est le trou.**

### Les trois défauts réels de catégorie (c), rejoués

| Script | Verdict rendu | Nature |
|---|---|---|
| `plugin/planning-core/scripts/check-planning-state.sh` | **rc=2** — « `.planning/` existe mais STATE.md (clé de voûte) est ABSENT. Le recréer via /vf-planning. » | **Rouge à tort.** Sous `--hook` le code est traduit en 0 **mais la ligne fausse est imprimée quand même** → pollue chaque `SessionStart`. |
| `plugin/planning-core/scripts/detect-gsd-engine.sh` | **rc=3** — « Aucun moteur de planning en place » | **Verdict faux** : `--path .planning/workstreams/fiabilite` rend rc=0 « Moteur GSD actif ». **Cause amont du précédent.** Impacte aussi le routage de `vf-planning`, dont la table attend exit 0. |
| `plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh` | **rc=0**, 5 documents « non intégrés » | **Faux positifs** : **4 des 5** sont réellement cités dans un ROADMAP/REQUIREMENTS de compartiment. Son registre concaténé ne lit que les fichiers racine, absents de HEAD depuis la partition. |

### Le pivot des deux chantiers

```
$ check-state-integrity.sh --file .planning/workstreams/gouvernance/STATE.md
[check-state-integrity] milestone introuvable ou illisible (HEAD="" ↔ courant="") — intégrité du frontmatter compromise ; RC=2
$ check-state-integrity.sh --file .planning/workstreams/fiabilite/STATE.md
[check-state-integrity] ✓ conforme (compteurs non régressés, 1 ligne '^Phase:') ; RC=0
```

Le frontmatter entier de `gouvernance/STATE.md` est `workstream: gouvernance` + `created: 2026-09-23`
— c'est le **stub codé en dur** du moteur (`~/.claude/gsd-core/bin/lib/workstream.cjs` ~l.159-181),
sans `milestone:` et sans ligne `^Phase:`. Ce n'est pas une résolution ratée : le fichier est lu, il
existe aussi dans HEAD, l'invariant s'arme et la garde fail-closed se déclenche des deux côtés.

**Donc généraliser le balayage ferait passer `gouvernance` de « muet » à « rouge », pas à vert.**

### Le coût réel qu'on cherche à épargner

PR #94 (partition D-02) : **14 commits exclusifs** — **4** de partition (dont un seul pour la
commande, 292 entrées / 279 renommages R100 ; puis **3 de découpage manuel**, parce que
`migrateToWorkstreams` déplace en bloc et **ne sait pas scinder** un ROADMAP ni un REQUIREMENTS entre
deux compartiments), **5** de réparation sur **8 fichiers de machinerie** (`ci.yml` deux fois, dont le
second était un **finding bloquant de revue non anticipé** ; le ledger d'exigences sur 3 scripts + 2
suites ; `check-mission-exit.sh` E4, **finding majeur de revue**), **5** de traçabilité.
**Les deux findings de revue portaient sur la même classe de défaut** — du hard-coding
`.planning/<fichier>` — dans deux modules différents. Deux arrêts humains avant exécution. Un
incident de process (deux workers, un seul worktree).

### Délimitation du périmètre face à la release du jour

v2.65.0 (mergée en cours de mission) est un **pur rattrapage de publication** : 11 fichiers, aucun
`.sh`, aucun `ci.yml`. Le contenu « workstream-aware » de `dev-orchestrator` v2.23.1 est exactement
les commits de la PR #94 déjà comptés. **Aucune primitive d'énumération n'y a été ajoutée** ; tout y
est résolu par environnement, en best-effort fail-open. Le périmètre de la mission est intact.

---

## Correction de la prémisse du brief

Le brief attribuait le remède à **ADR-063** : la cible en dur serait « le bon remède contre un
`export GSD_WORKSTREAM` qui détournerait le gate (ADR-063) ». **Mesuré : faux.**

1. **ADR-063 ne parle pas de compartiments.** Datée du 2026-07-31, elle fonde l'anti-régression du
   frontmatter de `STATE.md` et la convention `^Phase:` unique. Zéro occurrence de « workstream ».
   Le lien « ADR-063 » dans le titre de l'étape CI désigne **ce qui est protégé**, pas le mode de
   résolution.
2. **Aucun texte doctrinal n'interdit la résolution par environnement — ils la prescrivent.**
   `workstreams.md` §3 : « chaque worktree **exporte `GSD_WORKSTREAM=<nom>`** ». ADR-069,
   § amendement d'ADR-064 : « `GSD_WORKSTREAM` n'est donc **pas un contournement** : c'est le **canal
   nominal** ».
3. **La seule interdiction existante vit dans un commentaire de `ci.yml:345-346`**, et seulement pour
   un gate.

L'intention du brief restait juste — un gate ne doit pas être détournable par un `export` — mais son
ancrage était fabriqué. Remonté par `SendMessage` à la session principale avant tout dispatch de
code ; elle a confirmé point par point et tranché.

---

## Décisions de la session principale (`vibeflow-head`), 2026-09-23

Attribution exacte, à ne pas déformer : **décisions de la session principale**, *pas* des arbitrages
de Samuel — il n'a pas tranché ces questions, elles lui sont signalées.

1. **Écrire la frontière gate / workflow** (option (a)) dans `workstreams.md` et `docs/ADR.md`, en
   **posant** la règle et non en la rappelant ; formulée **par le rôle** (canal nominal de ce qui
   travaille, versus cible d'un gate qui juge celui-là même qui pourrait l'exporter) ; en
   **précision** d'ADR-069, dans la forme d'ADR-074 précisant ADR-031 sans l'abroger ; datée, origine
   nommée, et **constat explicite que l'ancrage ADR-063 initial était erroné** — sans quoi le prochain
   lecteur refera le raccourci. → `WSAW-06`.
2. **Trois états, pas deux** : conforme / **non initialisé** / corrompu. Un compartiment neuf est un
   fait, pas une faute. Motif : rougir sur la sortie **nominale** d'une commande du moteur que
   VibeFlow ne contrôle pas ferait hériter à chaque lab d'un rouge qu'il n'a pas causé, et lui
   apprendrait à ignorer le gate — le mode de mort d'une garde. → `WSAW-05`.
3. **Une seule vérité sur « compartiment conforme »**, portée par la 41.1 et **consommée** par la
   41.2. Deux définitions concurrentes = condition d'arrêt, pas arbitrage d'exécution.

## Décision du manager, 2026-09-23

`WSAW-06` et `WSCH-05` visaient tous deux `workstreams.md` et `docs/ADR.md`. **La 41.1 devient le
seul écrivain de la doctrine pour les deux phases** (`WSAW-07`) ; la 41.2 lui fournit le contenu sans
toucher aux fichiers. Sans cela, les deux chantiers n'étaient pas parallélisables : deux agents sur
un même fichier de doctrine, c'est l'incident de la PR #94 rejoué.

`WSAW-07` couvre aussi deux défauts que l'inscription initiale ne voyait pas : `workstreams.md` est
**muet sur le choix** (les mots « choix », « démarrage », « init » n'y figurent pas), sa §1 ne donne
aucune procédure ni précondition de bascule, et sa §3 affirme « sur un dépôt non partitionné il sort
en 3 sans un mot : c'est l'état nominal de tous nos labs à ce jour » — **affirmation devenue fausse
pour ce dépôt** depuis la PR #94.

---

## Phases inscrites (PR #98)

- **Phase 41.1** — Gates de planning workstream-aware par balayage du disque · `WSAW-01..07`
- **Phase 41.2** — Choisir la partition du planning au démarrage d'un lab · `WSCH-01..05`

Numérotation : 42-50 sont pris par le jalon `gouvernance-labs-v1.0` (compartiment `gouvernance`,
exécution gelée jusqu'à la clôture de `fiabilite-v1.0`). Les deux chantiers s'insèrent donc dans
`fiabilite-v1.0` après la Phase 41, en `.1` et `.2` — précédent `40.1`. Préfixes d'exigences vérifiés
libres sur tout le dépôt (43 préfixes déjà occupés dans le ledger).

---

## Preuves E6

| # | Affirmation | Commande | Résultat |
|---|---|---|---|
| E6-01 | Invariants de mission sains au démarrage | `check-mission-invariants.sh` | **rc=3 (SAIN)** |
| E6-02 | `gouvernance/STATE.md` n'est pas vérifiable en l'état | `check-state-integrity.sh --file .planning/workstreams/gouvernance/STATE.md` | **rc=2**, « milestone introuvable ou illisible » |
| E6-03 | `fiabilite/STATE.md` est conforme | `check-state-integrity.sh --file .planning/workstreams/fiabilite/STATE.md` | **rc=0** |
| E6-04 | Les préfixes `WSAW`/`WSCH` sont libres | `rtk proxy grep -rIn -e WSAW -e WSCH . --exclude-dir=.git` | aucune occurrence |
| E6-05 | L'inscription n'est qu'une insertion | `git diff --stat` (1ᵉʳ commit) | 175 ajouts, **0 suppression** |
| E6-06 | v2.65.0 ne touche aucun script | `git show --stat 3617ec0` | 11 fichiers, 0 `.sh`, 0 `ci.yml` |

*(les preuves des chantiers A et B s'ajoutent ci-dessous à mesure de leur exécution)*
