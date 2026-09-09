# Phase 39 — Workstreams : mesures de cadrage

**Date** : 2026-09-09 · **Moteur** : `@opengsd/gsd-core` **1.13.0** (`~/.claude/gsd-core/`, `latest`
publiée le 2026-09-06) · **Node** : v26.5.0 · **Méthode** : quatre mesures parallèles, toutes par
**exécution réelle** ou lecture de code avec `fichier:ligne`.

> **Statut de ce document** : c'est la *recherche préalable sur le fonctionnement réel de GSD* que le
> périmètre arrêté le 2026-08-30 pose comme **précondition du cadrage**. Tout ce qui suit est mesuré.
> Aucune affirmation ne repose sur un `.md` de doc amont seul — leçon des Phases 37/38, où un
> descripteur `gsd-core` sur trois a été démenti en exécution.
>
> **Contrainte respectée** : aucune partition n'a été créée dans ce dépôt (condition dure d'ADR-069,
> « aucune partition tant qu'une phase est en vol »). Toutes les manipulations ont eu lieu dans des
> dépôts git jetables hors dépôt.

---

## 1. Résolution du pointeur de workstream — les cinq niveaux existent

Code : `~/.claude/gsd-core/bin/lib/active-workstream-store.cjs` (445 l.) + point d'entrée
`bin/gsd-tools.cjs:4717-4738`.

| Niveau | Mécanisme | Code | Mesuré |
|---|---|---|---|
| 1 | `--ws <nom>` / `--ws=<nom>` | `active-workstream-store.cjs:369-397`, `:403-406` | oui |
| 2 | `GSD_WORKSTREAM` | `:407-410` | oui |
| 3 | pointeur session-scopé | `:220-249`, `:273-285` | oui |
| 4 | `.planning/active-workstream` hérité | `:286-290` | **oui — voir §2** |
| 5 | `null` / mode plat | `:291` | oui |

### Trois écarts doc → code

1. **`workstream.get` ne reflète pas la cascade.** `workstream.cjs:346-350` appelle
   `getActiveWorkstream(cwd)` — le **store seul**, sans lire `--ws` ni `GSD_WORKSTREAM`. Mesuré :
   `workstream.get --ws default` rend `{"active":"alpha"}` pendant que `phases.list --ws default`
   route correctement sur `01-alpha`. **C'est un rapporteur d'état de pointeur, pas de résolution
   effective** — piège de diagnostic direct, à ne jamais utiliser comme oracle.
2. **`--ws <nom-inexistant>` n'erreure jamais.** `:415-417` ne valide que le *format*. Mesuré :
   `phases.list --ws nope` → `{"directories":[],"count":0}`, **exit 0**. Une faute de frappe rend un
   planning vide silencieux.
3. **`.planning/active-workstream` n'est jamais écrit par un runtime moderne** (`:187-202` :
   l'adaptateur partagé n'est choisi que si l'identité de session est `null` ; sous Claude Code,
   `CLAUDE_CODE_SESSION_ID` est toujours là). Le marker de niveau 4 doit être **posé à la main**.

## 2. Le niveau 4 — il EXISTE et il FONCTIONNE

Dépôt jetable partitionné en `workstreams/{alpha,default}`.

```
SESS-B (jamais posé) sans marker          → active: null
printf 'default' > .planning/active-workstream
SESS-B (jamais posé) avec marker          → active: default    ← NIVEAU 4
SESS-A (pointeur=alpha) avec le marker    → active: alpha      ← isolation préservée
aucune identité de session (env -u ×15)   → active: default
```

Routage effectif confirmé sur `phases.list --raw`. **L'héritage ne franchit jamais un pointeur
existant**, y compris périmé : `resolveFromChain` (`:273-292`) ne consulte les fallbacks que si
`chain[0].read()` est vide. `--clear` rend la session à l'héritage, pas au mode plat. Un pointeur
dont le workstream a disparu est auto-nettoyé (le fichier et son répertoire tmp sont supprimés).

## 3. Composabilité avec ADR-064 — refermée pour le cas nominal, OUVERTE pour le modèle d'équipe VF

**Où vit le pointeur** (`:104-126`) : hors du dépôt, indexé par chemin —
`os.tmpdir()/gsd-workstream-sessions/<sha1(realpath(<cwd>/.planning)).slice(0,16)>/<sessionKey>`.

`resolveMainWorktreeCwd` (`gsd-tools.cjs:4567-4586`) rebase le cwd sur la racine du worktree
principal **si et seulement si** le worktree courant n'a pas son propre `.planning/`. D'où deux
régimes mesurés :

- **Cas A — `.planning/` commité dans chaque worktree** : projectId distinct par arbre. Même clé de
  session, `alpha` dans wt1 et `default` dans wt2 → chacun relit le sien. **Isolation parfaite.**
- **Cas B — `.planning/` non commité (le cas réel ici)** : les arbres rebasent sur un projectId
  unique. Même clé de session, deux worktrees → `set alpha` puis `set beta` : **les deux relisent
  `beta`**, et wt1 route sur le mauvais workstream. Avec des **clés de session différentes**, dans
  ce même cas B : deux pointeurs coexistent, isolation préservée.

**Le facteur discriminant est la clé de session, pas le worktree.** Et la mesure décisive : un
sous-agent lancé depuis cette session rend **exactement le même `CLAUDE_CODE_SESSION_ID`** que son
parent (avec `CLAUDE_CODE_CHILD_SESSION=1`). **Tous les sous-agents d'une session Claude Code
partagent un unique pointeur de workstream.**

> **Verdict pour le critère de succès 2** : la collision est **refermée** entre deux sessions Claude
> distinctes (deux écrivains = deux worktrees = deux pointeurs), et **reste ouverte** pour le modèle
> d'équipe VibeFlow — un manager qui dispatche des workers sur des worktrees différents leur fait
> tous partager son pointeur, et le dernier `set` gagne pour tout le monde.
> **Refermable sans patcher `gsd-core`** : `GSD_SESSION_KEY` distinct par mandat (première clé de
> `WORKSTREAM_SESSION_ENV_KEYS`, `:22`), ou `--ws` explicite sur chaque appel.

## 4. La surface `--ws`

**`--ws` est un drapeau GLOBAL**, parsé et retiré d'argv au point d'entrée unique
(`gsd-tools.cjs:4733-4738`) puis reprojeté dans `process.env.GSD_WORKSTREAM`, que `planningDir`
(`planning-workspace.cjs:103-122`) consomme. **Toute sous-commande `gsd_run query …` l'accepte**,
formes `--ws X` et `--ws=X`. Équivalent d'environnement : `GSD_WORKSTREAM`, mesuré strictement
équivalent. Priorité `--ws` > `GSD_WORKSTREAM` (`:403-410`), non observable via `workstream.get`.

**Côté workflows, la propagation est une convention de PROMPT, pas un câblage.** 22 fichiers touchent
`GSD_WS` ; **3 seulement le fabriquent** depuis `$ARGUMENTS` (`new-milestone.md:34`,
`plan-review-convergence.md:33`, `verify-work.md:41`). Les **17 autres l'interpolent sans jamais
l'assigner** — ce sont des gabarits de suggestion de commande suivante rendus par le modèle
(`/gsd-plan-phase {X} ${GSD_WS}`). **La variable s'expanse à vide : le scope se perd en silence à
chaque saut.** C'est le point de fragilité principal pour l'adoption VF.

## 5. Layout d'un dépôt partitionné — migration clé en main, mais résolveur désaligné

**`workstream.create` déclenche `migrateToWorkstreams`** (`workstream.cjs:46-94`), avec rollback
transactionnel. Mesuré : `files_moved: ["ROADMAP.md","STATE.md","REQUIREMENTS.md","phases"]`.
Restent à la racine : `PROJECT.md`, `config.json`, `milestones/`, `research/`, `codebase/`, `todos/`.

**Mais `planningPaths` (`planning-workspace.cjs:287-304`) rebase NEUF clés sous le workstream**, dont
trois que la migration laisse à la racine. `config.json` a une fédération scoped→root qui marche
(`:249-260`). **`PROJECT.md` n'en a AUCUNE** — défaut mesuré :

```
gsd_run query init.progress --ws default
  → "project_exists": false
    "project_path": ".planning/workstreams/default/PROJECT.md"
```

…alors que `.planning/PROJECT.md` existe, exactement là où la migration officielle l'a laissé. Le
code compose le chemin des deux façons selon le site d'appel (`planningDir` scopé dans `init.cjs`
contre `planningRoot` dans `planning-snapshot.cjs:447`, et un `path.join` en dur dans
`profile-output.cjs:303`). **Un dépôt partitionné voit son `PROJECT.md` tantôt trouvé, tantôt
déclaré manquant, selon la commande.** Reproductible en trois commandes — candidat de remontée amont.

Détail : un workstream **neuf** (non issu de migration) ne reçoit que `STATE.md` + `phases/`
(`:156-185`) — ni `ROADMAP.md` ni `REQUIREMENTS.md`, contrairement au schéma de `workstream-flag.md`.

---

## 6. Couverture amont — le chiffre dépend du critère, et le critère n'était pas publié

**Méthode** (les cinq éléments sans lesquels un chiffre de couverture est inexploitable) :
(a) racine `~/.claude/gsd-core/workflows` · (b) `-maxdepth 1`, glob `*.md`, compteur de garde
`seen=89` · (c) critère de conscience, voir table · (d) « en dur » =
`/\.planning\/(ROADMAP\.md|STATE\.md|phases)/` · (e) moteur 1.13.0.

**Dénominateur : 89.** (Le dossier contient 91 fichiers *tous types* à cette profondeur — c'est très
probablement là qu'est né le « 91 » du 2026-08-04, qui ne comptait pas la même chose.)

| Critère | Définition | Conscients | En dur | Aveugles |
|---|---|---|---|---|
| K1 | le mot `workstream` présent | **7** (7,9 %) | 43 | 40 |
| **K2** — *celui dont se réclame `GSDA-19`* | K1 **ou** l'option `--ws` | **9** (10,1 %) | 43 | **39** |
| K3 | K2 **ou** `GSD_WS` | 18 | 43 | 32 |
| K4 — sémantique | **résout réellement** un scope | 7 | 43 | 40 |

**L'écart K1→K2 est nominatif** : `plan-review-convergence.md` et `verify-work.md` **parsent et
assignent `--ws` sans jamais écrire le mot « workstream »** (`verify-work.md:41-43`) — faux négatifs
de K1. À l'inverse `health.md:84` et `pr-branch.md:408` ne comptent **que par de la prose**.

> **« La couverture amont n'a pas bougé en cinq semaines » est vraie par accident** : la phrase
> compare un K1 de 2026-09-09 à un K2 de 2026-08-04. Sous K1 : 5 → 7. Sous K2 : 7 → 9. Sous K4 :
> 7 → 7 **mais avec un échange** (`transition.md` sort, `health.md` entre). Deux mesures de « 7 » qui
> ne désignent pas les mêmes fichiers. **Ne pas graver « couverture figée » comme propriété stable.**

**Contre-mesure qui change la conclusion** : **82 des 89 workflows passent par le SDK**
(`gsd_run`/`gsd-tools`). Le comptage lexical est donc un **plancher de risque**, pas la vérité — un
workflow sans marqueur peut être scope-correct si toute sa résolution transite par l'outil. **Le vrai
trou, ce sont les 43 chemins littéraux écrits dans le corps des workflows, hors SDK.**

**L'amont n'est pas immobile** : `#4455` (« autonomous and complete-milestone workflows still read
and edit root planning paths after workstream resolution »), `#4456`, `#4225` — **fermées les 7-8
septembre 2026, par d'autres auteurs**. Mais **non distribuées** : 1.13.0 date du 6 septembre.

### Les aveugles qui comptent pour VibeFlow

| Workflow | Statut K2 | Chemin `.planning/` en dur |
|---|---|---|
| `discuss-phase.md` | aveugle (interpole `${GSD_WS}`) | **écrit** `.planning/phases/${PADDED_PHASE}-${SLUG}/…-CONTEXT.md` |
| `plan-phase.md` | aveugle (interpole) | **écrit** `.planning/phases/{dir}/*-PLAN.md` |
| `execute-phase.md`, `progress.md`, `ship.md`, `quick.md`, `resume-project.md`, `validate-phase.md` | aveugles (interpolent) | `STATE.md`, `ROADMAP.md`, `phases/` |
| `add-phase.md` | aveugle | **crée** `.planning/phases/{NN}-{slug}/` |
| `pause-work.md` | aveugle | **écrit** `.planning/phases/XX-name/.continue-here.md` |
| `complete-milestone.md`, `audit-milestone.md`, `cleanup.md`, `next.md`, `autonomous.md` | aveugles | oui |
| `new-milestone.md`, `verify-work.md` | **conscients** (K2+K4) | résiduel |
| `pr-branch.md` | K1 par prose seule | regex ancrées racine |
| `code-review.md`, `docs-update.md`, `manager.md` | aveugles **sans chemin en dur** | — (sans risque) |

## 7. `pr-branch` sur dépôt partitionné — le risque (b) a MIGRÉ, il n'a pas disparu

`~/.claude/gsd-core/workflows/pr-branch.md` (459 l.). **L'ancrage `:250-270` du ROADMAP est
CORRECT** ; ceux de `REQUIREMENTS.md:454` (`:235-236`) et du ROADMAP de jalon (`:232-234`) sont
**périmés**.

- `TRANSIENT_DIRS` (**l. 250**) : `phases quick research threads todos debug seeds codebase ui-reviews` — **`workstreams` n'y figure pas**.
- `STRUCTURAL_RE` (**l. 255**) : `^\.planning/(STATE|ROADMAP|MILESTONES|PROJECT|REQUIREMENTS)\.md$|^\.planning/milestones/`
- `FORBIDDEN_RE` (**l. 261-272**) : strict → `^\.planning/` ; défaut → dérivée de `TRANSIENT_DIRS`.
- Bloc `$OTHER` (**l. 410**, commentaire l. 407-409 qui **nomme `workstreams/`**) : préservé **et
  signalé** à l'écran (l. 439-444) avec suggestion de `pr_strict`.
- `pr_strict` : défaut `false` (`bin/shared/config-defaults.manifest.json:65`).

**Table chemin → classe (mode défaut), workflow EXÉCUTÉ sur dépôt partitionné jetable :**

| chemin | classe |
|---|---|
| `.planning/ROADMAP.md`, `STATE.md`, `milestones/**` | STRUCTURAL — préservé |
| `.planning/phases/**`, `quick/`, `research/` | TRANSIENT — filtré |
| `.planning/config.json`, `intel/**` | OTHER — préservé + signalé |
| **`.planning/workstreams/alpha/{STATE.md,ROADMAP.md,phases/**,quick/*}`** | **OTHER — préservé + signalé** |
| `src/**` | CODE — inclus |

En `pr_strict=true`, toutes ces lignes basculent en EXCLUDED.

### Verdict sur les trois conséquences

- **(i) FAUSSE À MOITIÉ — le fait le plus important de la mesure.** Le silence est levé au niveau
  **chemin**, mais il **subsiste au niveau COMMIT** : `.planning/workstreams/<nom>/ROADMAP.md` **ne
  matche pas** `STRUCTURAL_RE` (ancré `^\.planning/ROADMAP\.md$`). Un commit qui ne touche **que** la
  feuille de route d'un workstream sort à `NON_PLANNING=0, STRUCTURAL=0` → « transient planning
  commit » → **EXCLU DANS LES DEUX MODES**, et il n'apparaît dans aucun rapport (jamais dans le diff,
  seulement dans un compteur anonyme `Commits to exclude: {N}`).
  **Le commit de feuille de route d'un workstream disparaît donc toujours silencieusement.**
- **(ii) VRAIE**, mesurée (`A1-PLAN.md` entré dans le diff de PR) — via les **commits mixtes**, qui
  sont le cas nominal du travail réel.
- **(iii) VRAIE**, mesurée (`PLANNING_TOTAL=0`, diff réduit à `src/`).

## 8. Split-brain — reproduit, et sa signature observable

| Variante | `git merge-tree` | `git merge` | Résultat |
|---|---|---|---|
| **orphan** (Y n'enregistre pas au ROADMAP du workstream) | **exit 0** | **exit 0** | 3 dossiers, ROADMAP n'en connaît que 2 → phase orpheline |
| **rootonly** (Y enregistre au ROADMAP **racine**) | **exit 0** | **exit 0** | phase de workstream fuitée au niveau racine |
| **roadmap** (les deux écrivent le même fichier) | exit 1 | exit 1 | conflit Git — **seul cas détecté nativement** |

Reproduit aussi sur les compteurs : deux branches passent `completed_phases: 1 → 2` de façon
identique → aucun conflit, STATE fusionné dit **2** quand le disque porte **3** dossiers.

**Signature observable = spécification du filet** (prototype validé, exit 1 sur les deux variantes
silencieuses) :

- **S2 — numéro de phase dupliqué dans un même workstream.** *Signal primaire* : tire sur les trois
  variantes, ne dépend d'aucun format de ROADMAP.
- **S4 — cardinalité incohérente** : `#dossiers ≠ #entrées de ROADMAP du compartiment`, et/ou
  compteurs `progress:` du STATE < nombre de dossiers.
- **S5 — fuite de niveau** : phase de workstream référencée dans le `ROADMAP.md` racine.
- **S1/S3 (orphelin / fantôme)** : bons signaux conceptuellement, **fragiles en l'état** — la clé
  « numéro seul » est masquée par le doublon (faux négatif), la clé « nom de dossier complet » ne
  matche pas le libellé du ROADMAP (faux positif 3/3). À **normaliser** (numéro + slug) ou à
  remplacer par S2+S4+S5, qui suffisent et sont robustes.

## 9. Les gardes VF existantes ne couvrent RIEN de cela

Aucun des trois scripts ne lit `ROADMAP.md` ni les dossiers de phase (occurrences en commentaire
seulement).

| Garde | Verdict | Preuve |
|---|---|---|
| `conductor/scripts/check-workstream-pointer.sh` | **ne couvre pas** | sur le dépôt en split-brain : `conforme … dossier présent`, **exit 0** |
| `planning-core/scripts/workstream-policy.sh` | **hors sujet** | fichier sourcé, politique de **nom** uniquement |
| `conductor/scripts/check-state-integrity.sh` | **ne couvre pas — et rend un vert trompeur** | 3 dossiers / STATE=2 / doublon : `✓ conforme (compteurs non régressés)`, **exit 0** |

**Le filet de détection de divergence n'existe pas** : zéro des trois gardes ne le couvre, même
partiellement, et **deux rendent explicitement « conforme » sur un dépôt divergé**. Point de
branchement naturel : **post-merge**, pas `SessionStart`.

## 10. Espace de noms des exigences

**40 préfixes occupés** dans `REQUIREMENTS.md` (194 identifiants), pas 42. Les chiffres « 42 » et
« 36 » sont le **même biais de méthode** à deux dates : `STATUT-BLOC-3` lu comme un `BLOC-3`, et les
chemins de dossier de phase `VFDO-xx`. Méthode : extraction `awk` vers fichier, comptage sur fichier,
comparaison d'ensembles par `comm` — jamais un `grep | sort -u`.

**Le ledger ne suffit pas à dériver l'espace de noms.** Dérivation étendue à `.planning/` + `plugin/`
(826 fichiers) : **`SIG-01`→`SIG-06`** (Phase 17, jalon `agentique-v1.0`) est une famille **livrée**,
citée dans les `*-PLAN.md`/`*-SUMMARY.md` et gravée jusque dans des en-têtes de scripts
(`check-dev-bootstrap.sh:2`), **absente des deux ledgers** — vivant et archivé.
**Espace réellement occupé : 41 familles.**

**`WSTR` est libre** (4 occurrences dans tout le dépôt, toutes la proposition elle-même ; zéro
`WSTR-<chiffre>`). Réserve de lisibilité : `WSTR` est à une **transposition de lettre** de `WKTR`
(worktree, vivant), et cette phase fera cohabiter les deux mots dans la même phrase (critère 2,
ADR-064 « un écrivain = un worktree ») ; une troisième famille en `W` existe (`WTCH`). Alternatives
vérifiées libres : **`PART`**, `WSTM`.

---

## Ce que ces mesures changent au plan de la phase

1. **La migration est fournie** (`workstream.create`) — rien à fabriquer de ce côté.
2. **Le niveau 4 fonctionne** : le critère 1 est mesuré, et le critère 2 se tranche en
   « refermée pour deux sessions Claude distinctes / **ouverte pour le modèle d'équipe VF** », avec
   un remède qui ne touche pas l'amont.
3. **Le vrai travail d'adoption est côté VF** : passer `--ws` explicitement sur les appels
   `gsd_run` de VibeFlow, parce que la propagation amont est une convention de prompt.
4. **Le filet de divergence est à créer intégralement**, sur la signature S2+S4+S5, branché
   post-merge.
5. **`pr-branch` demande une décision neuve** : le commit de feuille de route d'un workstream
   disparaît silencieusement **dans les deux modes** — soit on corrige, soit on le déclare coût
   assumé daté.
6. **Deux candidats de remontée amont** mesurés de première main : `PROJECT.md` non résolu sous
   workstream, et la classification de commit de `pr-branch`.
