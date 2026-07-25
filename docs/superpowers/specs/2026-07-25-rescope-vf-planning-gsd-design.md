# Design — Rescope de `vf-planning` : frontière d'altitude avec le moteur de planning GSD

> **Date** : 2026-07-25
> **Modules** : `planning-core` (v2.3.0 → v2.4.0), `plugin/commands/vf-planning.md`
> **ADR à ouvrir** : ADR-055
> **Problème** : `vf-planning` et la chaîne GSD génèrent les **mêmes fichiers** dans le **même
> dossier** avec des **formats incompatibles**. Sur un lab dev, ce sont deux moteurs de planning
> concurrents.

---

## 1. Problème

### 1.1 Recouvrement total sur la génération

Les 7 artefacts du « tronc commun » de `planning-core` ont chacun un producteur GSD :

| Artefact `planning-core` | Producteur GSD équivalent |
|---|---|
| `PROJECT.md` | `gsd-new-project` |
| `ROADMAP.md` | `gsd-roadmapper` (via `new-project` / `new-milestone`) |
| `REQUIREMENTS.md` | `gsd-new-project` |
| `STATE.md` | `gsd-progress` + hook `gsd-session-state.sh` |
| `MILESTONES.md` | `gsd-complete-milestone` |
| `phases/NN/PLAN.md` + `SUMMARY.md` | `gsd-plan-phase` / `gsd-executor` |
| `config.json` | `gsd-config` |

Le recouvrement ne s'arrête pas au tronc. Les trois capacités que `planning-core` présentait comme
sa valeur propre ont **aussi** un équivalent GSD, de nature différente :

| Axe | Équivalent GSD | Nature de l'écart |
|---|---|---|
| Compartiments (`INDEX.md`, `BOARD.md`, seuil d'autonomie) | `gsd-workstreams`, `gsd-workspace` | GSD = parallélisme **dans** un projet (milestones, worktrees). planning-core = pluralité **de projets** dans un lab |
| Pont mémoire | `gsd-extract-learnings`, `gsd-capture`, `gsd-graphify`, `gsd-thread` | GSD capitalise **dans** `.planning/`. planning-core promeut **vers** `.claude/memory/` |
| Fraîcheur / dette | `gsd-health` (`--repair`, `--context`) | GSD = diagnostic **à la demande**. planning-core = **hooks**, dont un `Stop` bloquant |

### 1.2 Les deux formats de `STATE.md` sont incompatibles

Ce n'est pas une redondance cosmétique — les frontmatters divergent :

```yaml
# planning-core (references/templates/STATE.template.md)
planning_version: 1.0
profile: leger | standard | complet
progress: { total_steps, completed_steps, percent }

# GSD (.planning/STATE.md de ce repo)
gsd_state_version: 1.0
milestone_name: …
progress: { total_phases, completed_phases, total_plans, completed_plans, percent }
```

Un `.planning/` posé par `vf-planning` sur un lab dev n'est donc **pas lisible** par l'outillage GSD
(`gsd-sdk query`, `gsd-health`, hook `gsd-session-state.sh`). Inversement, les scripts
`planning-core` ne lisent pas les compteurs GSD. Le premier moteur qui écrit rend l'autre aveugle.

### 1.3 Double injection de contexte au démarrage

Sur un lab dev où les deux sont installés, `SessionStart` empile `gsd-session-state.sh` **et**
`check-planning-state.sh` (+ `planning-context.sh`). Deux digests de la même réalité, coût contexte
payé deux fois.

### 1.4 Concurrence au déclenchement

La description actuelle de `vf-planning` revendique « fais-moi une feuille de route », « pose le
cadre du projet », « où en est-on ? ». Sur un lab dev, elle entre en concurrence directe avec
`gsd-new-project` et `gsd-progress` au matching sémantique. Aucune redirection interne ne rattrape
ce cas : si GSD gagne l'arbitrage, `vf-planning` n'est jamais invoqué ; s'il perd, c'est le mauvais
moteur qui écrit. **Le problème est autant un problème de déclenchement que d'exécution** — et c'est
la raison pour laquelle le rescope touche la description autant que le corps du skill.

---

## 2. Décision — la frontière d'altitude

> **Iron Law** : *« Un projet de code a un seul moteur de planning : GSD. VibeFlow tient l'altitude
> au-dessus (le lab) et la couche à côté (mémoire, enforcement) — jamais la même. »*

Test unique et vérifiable pour trancher n'importe quel geste : **est-ce que ça concerne un projet,
ou le lab ?**

| Geste / artefact | Propriétaire après rescope |
|---|---|
| `PROJECT.md`, `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, `MILESTONES.md`, `phases/NN/*`, `config.json`, `codebase/` d'un projet dev | **GSD**, via les verbes `/vf-init`, `/vf-plan`, `/vf-progress` |
| Santé du `.planning/` d'un projet, learnings de phase, workstreams parallèles | **GSD** (`gsd-health`, `gsd-extract-learnings`, `gsd-workstreams`) |
| `INDEX.md` du lab, typage `deliverable`/`continuous`, `BOARD.md`, seuil d'autonomie, dette de compartiment | **planning-core** — altitude lab |
| Promotion des décisions vers `.claude/memory/` (pont mémoire) | **planning-core** — couche à côté |
| Socle complet d'un lab **non-dev** (contenu, vente, growth, design, dossier, recherche) | **planning-core** — GSD n'y est ni installé ni pertinent |
| `Stop` guard bloquant | **planning-core** — **exception motivée**, cf. §2.2 |

### 2.1 Conséquence sur un lab dev à compartiments

Le lab reçoit `INDEX.md` + `STATE.md` de steering (planning-core, altitude lab). Chaque compartiment
dev reçoit son `.planning/` **écrit par GSD**. Les deux couches ne se croisent sur aucun fichier.

### 2.2 L'exception assumée : le `Stop` guard

`guard-planning-updated.sh` reste actif et **bloquant** sur un lab dev, alors que la frontière
d'altitude l'attribuerait à GSD. Motif : **il ne génère rien**. Il vérifie une propriété du
*résultat* — « des livrables ont changé, le planning suit-il ? » — quel qu'en soit l'auteur, GSD ou
humain. Il ne concurrence donc aucun producteur, et GSD n'offre aucun équivalent bloquant
(`gsd-health` signale à la demande). VibeFlow garantit ici une propriété que GSD ne garantit pas.

### 2.3 Options écartées

| Option | Verdict |
|---|---|
| GSD moteur unique sur **tous** les labs | Rejetée — `gsd-roadmapper`/`phases`/`requirements` sont taillés pour le code ; casserait les 4 bundles non-dev |
| Bascule sur **présence de GSD** au lieu du métier | Rejetée — un lab contenu avec GSD installé hériterait d'un planning dev |
| GSD gagne partout où il a un équivalent | Rejetée — perd l'enforcement automatique (§2.2) et le lien aux registres VibeFlow |
| Coexistence simplement documentée | Rejetée — c'est l'état actuel ; l'ambiguïté de déclenchement (§1.4) reste entière |
| Détecteur bash du **métier** | Rejetée — heurte `domain-detection.md` (« un lab de contenu peut avoir un `package.json` »). Le métier reste du **jugement** ; seul le **fait** « moteur GSD en place » est outillé (§3.1) |

---

## 3. Composants

### 3.1 Nouveau — `scripts/detect-gsd-engine.sh`

Ne détecte **pas** le métier (doctrine `domain-detection.md` préservée : c'est du jugement). Il
répond à une question factuelle et non ambiguë : *le moteur GSD est-il en place ?*

Les exits sont évalués dans cet ordre de priorité, le premier qui matche gagne — un lab peut
satisfaire plusieurs situations à la fois :

| Ordre | Exit | Situation | Ce qu'en fait le skill |
|---|---|---|---|
| 1 | `1` | Chaîne GSD absente de la machine | Aucun moteur disponible. Si le jugement métier dit « dev » → proposer l'amorçage via `/vf-init`, **ne pas** scaffolder un tronc dev à la main. Si non-dev → séquence universelle |
| 2 | `0` | Chaîne GSD installée **et** `STATE.md` porte `gsd_state_version` | Moteur actif → **couche lab uniquement**, aucune génération de tronc |
| 3 | `2` | Chaîne installée, `.planning/` de facture `planning-core` (`planning_version`), et des signaux de code sont présents | **Signalement de migration** → avertir et proposer, jamais réécrire (§3.4) |
| 4 | `3` | Chaîne installée, **aucun moteur en place** : pas de `.planning/`, ou un `.planning/` sans marqueur GSD et sans signal de code | Terrain libre — le jugement métier décide seul : dev → rediriger vers `/vf-init` ; non-dev → séquence universelle |

Advisory : jamais bloquant, `|| true` en hook. Marqueur de détection = première clé du frontmatter
de `STATE.md`, signal binaire et stable.

**Ce que l'exit 2 n'est pas** : un verdict métier. Le script signale une **configuration à examiner**
(deux formats en présence, du code alentour) ; c'est le skill qui juge ensuite s'il s'agit vraiment
d'un lab dev, en appliquant `domain-detection.md`. Un lab de contenu hébergeant un site web
déclenchera un exit 2 et sera classé non-dev par le jugement — comportement attendu, pas un bug.

### 3.2 `SKILL.md` — description désarmée + branchement en étape 0

**Description** (gabarit du spec routage du 2026-07-25 : formulations FR réelles + contre-exemples
nommant les voisins + portée d'invocation) :

- **Garde** les formulations non-dev (« structure la doc de ce lab », « mets en place le suivi », « on
  perd le fil », « pose le cadre ») et les formulations d'**altitude lab**, valables sur tout lab
  (« fais l'index de mes projets », « ce client mérite-t-il son propre plan », « remonte les
  décisions en mémoire »).
- **Abandonne** les formulations qui revendiquent le terrain dev : « fais-moi une feuille de route »,
  « où en est-on ? ».
- **Ajoute** les contre-exemples : `✘ pas pour l'état / la feuille de route / les étapes d'un projet
  de code → /vf-init (démarrage), /vf-progress (où en est-on), /vf-plan (cadrage d'étape)`.

**Corps** — une **étape 0** avant toute autre chose : lancer `detect-gsd-engine.sh`, croiser avec le
jugement métier (`domain-detection.md`), puis brancher sur l'une des deux séquences nommées :

1. **Socle universel (lab non-dev)** — la séquence actuelle, inchangée.
2. **Couche lab au-dessus de GSD (lab dev)** — n'applique que : `INDEX.md` + typage des
   compartiments + pont mémoire + surface de la dette. Toute demande portant sur un projet est
   **redirigée vers le verbe `/vf-*` correspondant**.

### 3.3 Nouveau — `references/gsd-handoff.md`

Chargé on-demand. Contient : la doctrine d'altitude (§2), la table `intention → verbe /vf-*` pour la
redirection, et le protocole de migration (§3.4).

**Conformité au spec routage** : la redirection cible **toujours un verbe `/vf-*`**, jamais un
`gsd-*` en entrée de chaîne — c'est l'Iron Law de `rules/vf-verb-precedence.md`.

### 3.4 Protocole de migration (`exit 2`)

`gsd-import --from` importe un **plan isolé**, pas un `.planning/` entier : aucune automatisation
n'est possible. Le skill **détecte, avertit, propose** ; la reprise se fait par `/vf-init` sous
validation humaine (ADR-031). **Jamais de réécriture ni d'écrasement silencieux** d'un `.planning/`
existant — le contenu appartient à l'utilisateur.

### 3.5 Hooks — ajustement, pas suppression

| Hook | Changement |
|---|---|
| `check-planning-state.sh` | Se tait quand `gsd-session-state.sh` couvre déjà le projet → fin de la double injection (§1.3) |
| `planning-context.sh` | Passe en **digest d'altitude lab** (INDEX) ; **no-op** en mono-projet dev |
| `planning-task-context.sh` | Inchangé — choisir *le* compartiment ciblé est de l'altitude lab |
| `guard-planning-updated.sh` | **Inchangé, toujours bloquant** — exception §2.2 |
| `detect-planning-debt.sh` | Inchangé — la dette de compartiment est de l'altitude lab |

### 3.6 Périphérie

- `plugin/commands/vf-planning.md` — description alignée ; retirer « Réponds aussi à *où en est-on ?* »
  (part à `/vf-progress` sur lab dev).
- `references/domain-detection.md` — ajouter la section « bascule dev → GSD » et le signal factuel du
  §3.1, en réaffirmant que le métier reste du jugement.
- `docs/ADR.md` — **ADR-055** : frontière d'altitude entre `planning-core` et le moteur GSD.
- `CHANGELOG.md` + `README.md` du module ; bump `VERSION` v2.3.0 → **v2.4.0** (capacité rescopée →
  minor) ; bump racine + tag annoté (règle non négociable du `CLAUDE.md`).

---

## 4. Tests

`scripts/tests/test-planning-core.sh` étendu, plus un cas dédié à la bascule :

| Cas | Attendu |
|---|---|
| `STATE.md` avec `gsd_state_version` + GSD installé | `detect-gsd-engine.sh` → exit 0 |
| `STATE.md` avec `planning_version` + code présent + GSD installé | exit 2 (signalement de migration) |
| GSD installé, pas de `.planning/` | exit 3 |
| GSD absent — quel que soit l'état du `.planning/` | exit 1 (priorité 1, §3.1) |
| Lab non-dev (aucun signal de code) | séquence universelle inchangée — non-régression des 4 bundles |
| `SessionStart` avec les deux moteurs | un seul digest injecté |
| Livrables modifiés sans mise à jour du planning, lab dev | `Stop` guard bloque toujours |

Non-régression obligatoire : `test-planning-hooks.sh`, `test-planning-context-hardening.sh`,
`test-detect-planning-debt.sh`, et `plugin/conductor/scripts/check-agents.sh`.

---

## 5. Hors-scope

- **Les 4 bundles** (`content-bundle`, `business-pilot-bundle`, `growth-bundle`, `kpi-analyst`) — tous
  non-dev, ils tombent dans la séquence universelle. Comportement inchangé, aucune modification.
- **Le format `STATE.md` de `planning-core`** — pas d'alignement sur le frontmatter GSD. Les deux
  formats restent distincts, mais ne cohabitent plus jamais dans le même `.planning/`, ce qui rend
  l'incompatibilité (§1.2) sans conséquence.
- **Migration automatique** d'un `.planning/` existant (§3.4) — impossible avec l'outillage actuel.
- **`validator/AGENT.md`** (l. 82-84, dette → `/vf-planning`) — reste valide : la dette de
  compartiment est de l'altitude lab.
