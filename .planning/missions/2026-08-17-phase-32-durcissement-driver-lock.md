# Mission — Phase 32 « Durcissement du driver-lock »

**Date** : 2026-08-16 → 2026-08-17 · **Branche** : `feat/phase-32-durcissement-driver-lock`
**Milestone** : `fiabilite-v1.0` · **Module** : `conductor` (v1.25.0 → **v1.26.0**)
**Verrou de driver** : `mission-32`, tenu du début à la fin, relâché à la clôture.
**DAG** : `.planning/MISSION-32.dag.json`

---

## 1. Le problème, tel qu'il était

Le driver-lock était **purement déclaratif** — prouvé trois fois pendant `agentique-v1.0`. Le rejeu
a d'ailleurs **corrigé le brief** : il n'y avait pas deux contournements mais **quatre incidents
sur trois gestes** —

| # | Date | Geste | Lock |
|---|---|---|---|
| I1 | 2026-07-27 | commit concurrent | **périmé par TTL** |
| I2 | 2026-07-31 | écriture `Write`/`Edit` dans `.planning/` | tenu — **hors de portée d'un guard Bash** |
| I3 | 2026-08-01 / 08-15 | checkout de branche | tenu |
| I4 | 2026-08-16 | commit concurrent × 8 | **tenu, vivant** |

I1 et I4 sont **deux modes de défaillance distincts** : corriger le TTL sans poser de guard aurait
laissé I4 entier. Et I2 échappait à la formulation initiale du critère 2.

## 2. Les deux research flags, levés AVANT de planifier

- **Spike `reference-transaction`** (`32-SPIKE-reference-transaction.md`) — **PAS SÛR pour bloquer**.
  Le doute du ROADMAP est levé (le hook *voit* bien un checkout depuis git 2.46), mais le blocage
  wedge `rebase` **en refusant son propre `--abort`**, casse `worktree add` en fuitant la branche,
  se contourne par `-c core.hooksPath=/dev/null` — que **quatre de nos propres `check-*.sh`
  utilisent déjà** —, est aveugle sur git < 2.46, et ne voyage pas avec le plugin.
- **Rejeu des contournements** (`32-REJEU-contournements.md`) — deux scénarios rouges pour la bonne
  raison, mutation prouvée dans les deux sens.
- **Terrain** (`32-TERRAIN.md`) — anatomie mesurée, contrat des hooks, coûts, et le trou de QUAL-01.

## 3. Décisions (4 arbitrages humains, 7 de discrétion)

| Réf | Décision | Motif |
|---|---|---|
| **1B** | Blocage du checkout porté par le guard `PreToolUse`, **pas** par `reference-transaction` | le critère conditionnait le blocage à la sûreté d'un mécanisme précis, jugé non sûr ; le second n'a aucun de ses défauts |
| **2B** | Le guard couvre `Bash` **+** `Write\|Edit` restreint à `.planning/` | incident I2, hors de portée d'un guard Bash seul |
| **QUAL B** | Livrer le **hook doctor `SessionStart` générique** — extension de périmètre assumée | aucun canal « bruyant non bloquant » n'existait : `exit 17`+stderr n'atteint personne, `systemMessage` sur `allow` non plus, et les marqueurs de santé n'avaient **aucun lecteur** |
| **3B** | Synchronisation doctrinale **complète** : 7 fichiers, 4 modules tiers, 5 bumps | sans elle, un manager sur lock périmé ignorait `takeover` → critère 4 vert dans le code, **faux en production** |
| **4A** | Corriger le trou de la **voie legacy** du protocole d'acquisition | mesuré : lock legacy frais tenu par ALICE, `acquire --owner=BOB` rendait `acquired:true` — **deux détenteurs**, et T12 passait *par* ce bug |

Discrétion documentée : `.planning` retiré du préfiltre Bash (payer un spawn pour une commande
indécidable était le pire des deux mondes, la limite est nommée) · `bash -c`/`eval` **nommés** hors
de portée plutôt que couverts (analyse récursive = faux positifs) · gate d'armement = **PORT-05** et
non la règle 4 (qui ne connaît pas les hooks) · déviations transverses acceptées car imposées par
des gates existants (`HOOKS-CONTRAT-SORTIE.md`, READMEs, `test-vf-portable.sh`).

## 4. Le fait marquant : la re-validation externe

**Deux fois, un vérificateur interne a dit « PASSED, 0 blocker ». Deux fois, des juges frais
dispatchés en direct ont trouvé des bloquants.**

- Au **plan** : **9 bloquants + 15 findings**, la plupart vérifiés *par exécution*. Puis 2 bloquants
  de plus nés du 7ᵉ plan.
- Au **code** : trois juges (revue, audit, vérification goal-backward) ont trouvé **un bloquant que
  personne n'avait vu** — le guard tronquait la commande **au premier `<<`**, donc
  `cat <<EOF > f … EOF` **suivi** d'un `git commit` passait **en silence**. Pattern d'usage courant,
  pas une contorsion : c'était **I4 rouvert, avec tous les cas de test verts**.

Autres trouvailles de juges : `recover` n'avait pas le `trap` de ses deux frères (un process tué
rendait le lock **définitivement non reprenable**) · `owner`/`step` non assainis cassaient le JSON
(`acquire --owner='a"b'`) — or ce JSON est **lu mot pour mot par le modèle** · quatre angles morts
de segmentation mesurés (`&`, sous-shell, groupe, `if`/`for`) · l'ordre `stat -f`/`stat -c` inversé,
**anti-motif déjà corrigé deux fois** dans ce dépôt, et CI sous Linux.

Et une ironie relevée par le vérificateur : **le lock qui protégeait cette mission avait
`session_ids` vide**, donc le guard aurait été **inerte dessus**, sans que rien ne le signale.
C'est désormais observable, sans durcir la rétrocompatibilité.

## 5. Ce qui est livré

`driver-lock.sh` : `session_ids` (LRU) · `generation` exposée · `lease_seconds` **observable, jamais
un calcul de péremption**, TTL **inchangé à 1800 s** · **auto-steal supprimé** (`stale-requires-takeover`
+ champ `hint`) · `takeover` / `reclaim` · `trap` sur les **trois** verbes de reprise · garde
d'existence (voie legacy) · `owner`/`step` assainis · journal append-only avec identité du repreneur
· observabilité de l'opposabilité au guard.

`guard-driver-lock.sh` (neuf) : `PreToolUse` `Bash|Write|Edit`, forme exec, entrée née de
`merge-hooks`, commande en `--settings-local` · `deny` + `exit 0` · motif nommant la commande de
reprise · heredocs correctement tronqués · options globales git sautées · exemptions
`--abort/--continue/--skip/--quit` **bornées** · échappatoire journalisée · **quatre** issues QUAL-01.

`check-guard-health.sh` (neuf) : hook doctor `SessionStart` **générique**, premier lecteur des
marqueurs de santé du parc. **Mesuré réellement bruyant** : silence nominal à 0 octet, signal injecté
comme contexte de session — un canal que le modèle lit.

Doctrine : 5 agents managers de 4 modules tiers + `mission-flow.md` (convention `Fence:`) +
`team-kernel.md`. `vf-dev-manager.md` reste **exactement à 250 lignes** (ADR-029) par remplacement
net-neutre. Aucune prose morte (`grep -c recovered` = 0 sur les 11 fichiers).

**Mesure de clôture : 64 suites, 64 exécutées, 0 échec**, sur l'arbre commité, après le dernier
commit. `check-version-sync`, `check-machine-paths`, `check-release-tag` → 0.

## 6. Reliquats — détail dans `32-RELIQUATS.md`

1. **Bug d'idempotence cross-matcher de `merge-hooks.sh`** — deux entrées référençant le même script
   sous le même événement se purgent l'une l'autre à l'installation, **sans erreur**. Découvert
   empiriquement, **contourné**, **non corrigé**. Aucun autre module exposé aujourd'hui, mais
   `test-merge-hooks.sh` ne couvre **jamais** le scénario même-run. Tracé en `CONCERNS.md`.
2. **Catégorie C hors de portée** : session non armée, terminal humain, IDE/client git tiers,
   processus en arrière-plan, MCP, autre machine, `bash -c`, `eval`. Le guard est **anti-accident,
   pas anti-adversaire** — écrit dans son en-tête.
3. **Un lock né sans identité** reste non opposable au guard pour toute sa vie (`heartbeat` ne le
   repeuple jamais, seul `reclaim` le fait). Observable, pas rattrapable automatiquement.
4. **LOCK-05 est posé en partiel, pas en Done** : la convention `Fence:` est écrite et exécutable,
   mais **aucun commit ne porte encore le trailer** — y compris ceux de cette phase. Elle entre en
   vigueur au prochain mandat.

## 7. Gates humains — les deux ouverts ont été fermés le 2026-08-17

- **Checkpoint du plan 32-03** (armement du guard) — ✅ **APPROUVÉ par Samuel**, sur pièces : motif
  de refus mot pour mot, `.claude/settings.local.json` du lab jetable (unique entrée matcher
  `"Bash|Write|Edit"`, forme exec, placeholder `${CLAUDE_PROJECT_DIR}`), et confirmation que ce
  dépôt n'est pas armé. La **déviation D-32-05** (une entrée au lieu de deux) était explicitement
  soumise avec, donc approuvée avec. Trace : `32-03-SUMMARY.md` §Statut du checkpoint final.
- **Arbitrage `merge-hooks`** — ✅ **option 1A retenue** : dette tracée en `CONCERNS.md` + cas de
  régression documenté, **correction hors Phase 32**. C'était la recommandation, et elle avait été
  exécutée telle quelle : **rien à modifier**.
- **Restent gatés, non faits, réservés à Samuel** : PR, merge, **release racine**, tag, publication
  GitHub. L'**armement réel des labs** passe par la release du module `conductor` — le bump
  `v1.26.0` livré ici n'arme personne en lui-même.
- **Push de la branche** pour preuve CI : autorisé par le brief, **effectué par la session
  principale**, pas par la mission.

## 8. Calibration (verbatim, par plan, sans recalcul)

- 32-01 — `estimate {tokens: 78000, tasks: 2, confidence: low}` → `actuals {tokens: 4571, tasks: 2, commits: 2}`
- 32-02 — `estimate 105k` → `actuals 12k tokens, 3 tâches, 5 commits`
- 32-03 — `estimate {tokens: 125000, tasks: 4, confidence: low}` → `actuals {tasks 4/4, commits 5, abandonnées 0}`
- 32-04 — pas d'`actuals` explicite (non inventé)
- 32-05 — `estimate {tokens: 85000, tasks: 3, confidence: low}` → `actuals {tasks 3/3, commits 4, abandonnées 0}`
- 32-06 — `estimate {tokens: 55000, tasks: 3, confidence: low}` → `actuals {tasks 3/3, commits 2}`
- 32-07 — `estimate {tokens: 58000, tasks: 2, confidence: low}` → `actuals` non produits (exécution inline)

## 9. Leçons de méthode

1. **Le plan-checker interne juge le plan qu'il vient de produire.** Deux « PASSED, 0 blocker »
   internes, 11 bloquants trouvés par des juges externes. Le nœud de re-validation externe n'est pas
   une précaution : c'est le filet.
2. **Un test vert ne prouve pas qu'il mord.** Deux workers ont signalé honnêtement qu'une mutation
   **ne rougissait pas** ; l'un a été regravé en cas durable (T46), l'autre prouvé par un **stub
   émulant GNU** quand macOS ne pouvait pas exposer le défaut. C'est la bonne réaction.
3. **`timeout` n'existe pas sur macOS** — il a produit un faux `0/63` dans cette phase.
4. **Les workers n'ont pas de canal de retour** : leur rapport doit être leur message final ; deux
   se sont endormis en attendant un balayage de fond, et il a fallu constater le disque puis les
   réveiller.
