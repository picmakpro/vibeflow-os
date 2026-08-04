# Registre des Décisions d'Architecture (ADR) — vibeflow-os

> Registre versionné du repo (le template framework cible `.claude/memory/ADR.md`, mais ce
> chemin est gitignoré ici — le repo de distribution versionne ses ADR dans `docs/`).
> Gestion : lire l'index d'abord, charger le détail d'une ADR seulement si nécessaire.
> Les ADR antérieures à ce registre (ADR-001 → ADR-045) prédatent sa création : leur trace
> vit dans les CHANGELOG des modules, les rules et les specs (`docs/superpowers/specs/`).
> Les plus citées d'entre elles ont désormais une **définition canonique** ci-dessous
> (section « ADR héritées ») — audit 2026-07-25 : 325 citations sans définition, et un
> même identifiant (ADR-031) qui portait deux doctrines. La scission est actée en ADR-056.

---

## Index

| ID | Date | Titre | Statut |
|----|------|-------|--------|
| ADR-046 | 2026-07-09 | Équipe manager de mission — arborescence à contexte minimal | Validée |
| ADR-047 | 2026-07-11 | skill-creator dans la baseline d'install (dépendance du conductor) | Validée |
| ADR-048 | 2026-07-16 | Orchestrateur métier systématique (≥2 agents) + skill boucle de mission | Validée |
| ADR-049 | 2026-07-16 | Backups mémoire isolés + rotation intégrée (anti-pollution registres) | Validée |
| ADR-050 | 2026-07-16 | Hooks planning : lecture index-first au start + mise à jour bloquante au end | Validée — amendée 2026-07-20 (attribution de session, fix faux positifs) |
| ADR-051 | 2026-07-19 | Allowlist MCP des agents exécutants dérivée du lab (injection à l'install) | Validée |
| ADR-052 | 2026-07-22 | Frontmatter mémoire enrichi — trust + confidence à décroissance par catégorie + supersession non destructive | Validée |
| ADR-053 | 2026-07-22 | Volet swarm — lock de driver unique + DAG ready/blocked + rapports de worker typés | Validée |
| ADR-054 | 2026-07-23 | Portabilité Windows — normalisation CRLF, préflight, gardes réellement actives, gate de synchro versions | Validée (2 rapports terrain intégrés) |
| ADR-055 | 2026-07-25 | Frontière d'altitude entre planning-core et le moteur de planning GSD — un projet = un seul moteur | Validée |
| ADR-056 | 2026-07-25 | Vigilance support runtime (scission du double emploi d'ADR-031) | Validée |
| ADR-057 | 2026-07-25 | Frontières avec les briques tierces — détection outillée des recouvrements | Validée |
| ADR-058 | 2026-07-28 | Le moteur GSD entre dans le périmètre de `/vf-update` | Validée |
| ADR-059 | 2026-07-28 | Une mission d'équipe travaille sur sa propre branche, jamais sur la branche par défaut | Validée |
| ADR-060 | 2026-07-29 | La revue devient un étage de premier rang, piloté par le manager | Validée |
| ADR-061 | 2026-07-31 | Les lanes de revue cross-AI de plans (amont) et l'étage de revue de code (ADR-060) sont des objets disjoints | Validée |
| ADR-062 | 2026-07-31 | Les deux hooks 1.9.0 non câblés restent hors périmètre de `merge-hooks.sh` | Validée |
| ADR-063 | 2026-07-31 | Anomalie d'agrégation `.planning/STATE.md` : dette d'artefact locale + bug amont non scopé — gate local, jamais de correction par `gsd-tools state` | Validée |
| ADR-064 | 2026-08-01 | Un écrivain = un worktree : l'isolation des sessions concurrentes devient physique, et le claim de branche se dit à tout le monde (advisory) | Validée |
| ADR-066 | 2026-08-04 | La zone 2 est activée, pas différée : un prérequis de version insatisfiable ne gate pas, et le risque mesuré est inexistant | Validée |
| ADR-067 | 2026-08-04 | `hooks.community` refusé : c'est une mesure de style, pas de conformité — 6 types maison hors liste amont, 68 % des sujets > 72 caractères | Validée |

### ADR héritées les plus citées (définitions canoniques)

| ID | Titre canonique |
|----|-----------------|
| ADR-029 | Charte densité : agents ≤ 250 lignes, skills ≤ 500, bootstrap ≤ 2000 tokens |
| ADR-030 | Architecture skills (révisée) : déléguer aux skills outillés, ne jamais réimplémenter |
| ADR-031 | Jamais de fix / suppression / matérialisation sans validation humaine |
| ADR-032 | Consolidation mémoire : registres indexés, 4 piliers (indexation / archivage / fusion / promotion) |
| ADR-035 | Doctrine architecture logicielle AI-Safe : principes SOLID/SoC portés par `software-architecture`, gates de taille/structure machine-enforced |
| ADR-036 | Doctrine d'architecture d'audit : tout process générateur a une structure d'audit multi-couches |
| ADR-037 | Gate Nyquist de vérification réelle ; fusion feature-dev-gates → software-architecture |
| ADR-040 | Dette de planning = 8e signal de dette, porté par planning-core à l'altitude lab |
| ADR-044 | Agents natifs machine-enforced : `check-agents.sh` (description + model + memory requis, `vf-internal`) |
| ADR-045 | Recherche documentaire AVANT tout debug intensif (lib/framework/natif/version, ou 1er fix échoué) |

> Ces définitions sont la référence en cas de doute ; le détail historique vit dans les
> CHANGELOG des modules et `docs/superpowers/specs/`. **ADR-031 ne désigne QUE la validation
> humaine** — l'ancien second emploi (« vigilance support runtime ») est ADR-056.

---

## ADR-046 : Équipe manager de mission — arborescence à contexte minimal

**Date** : 2026-07-09
**Statut** : Validée
**Décideur** : Samuel (brainstorming + décisions DM1-DM6 verrouillées en session)
**Contexte** : release v2.23.0 — dev-orchestrator v1.5.0 (PR #12)

### Problème

Le pilotage dev de VibeFlow reposait sur un router (`vibeflow-dev`) qui invoque les skills GSD
dans le contexte courant. Sur une mission multi-étapes, ce contexte gonfle, se fait compacter,
et la conversation principale devient illisible ; `gsd-autonomous` (boucle inline) souffre du
même mal et n'embarque aucune doctrine VibeFlow (ADR-045, ADR-031, vocabulaire).

### Options Considérées

| Option | Avantages | Inconvénients |
|--------|-----------|---------------|
| Router = bras coder d'un manager | Zéro duplication du pilotage GSD | Couple le router à l'équipe |
| **Deux entrées parallèles (retenue)** | Router intact pour le quotidien ; équipe dédiée pour les missions | Léger doublon de pilotage GSD router↔coder (assumé, DM1) |
| Manager unique absorbant le router | Un seul sommet | Contredit le besoin de garder le router séparé |

### Raisonnement

> Pattern éprouvé sur un projet interne (`<projet-source>/.claude/agents/`) : main → manager →
> workers spécialisés, chacun à contexte minimal scopé. Analyse comparative avec
> `gsd-autonomous` : même machinerie GSD par phase (qualité identique sur une phase), mais
> l'inline dégrade sur les runs longs (compaction) là où les contextes frais des workers
> restent stables. gsd-autonomous garde l'avantage coût sur 1-2 phases → bascule par taille
> plutôt que remplacement. Le manager reprend les acquis de contrôle de flux de
> gsd-autonomous (routing VERIFICATION, gap-closure 1 retry, handle_blocker, lifecycle)
> pour ne pas les perdre (DM6).

### Décision

1. **Topologie (DM1)** : deux entrées parallèles — router direct (inchangé) ET équipe manager
   (`vf-dev-manager` + workers dédiés `vf-coder`/`vf-reviewer`/`vf-auditer`, `vf-internal`).
2. **Bascule (DM2)** : `vf-auto` aiguille — N < `SEUIL_EQUIPE` (3) et pas de signal durée →
   `gsd-autonomous` inline ; sinon → équipe. Le signal durée gagne.
3. **Packaging (DM3)** : extension du module `dev-orchestrator` (pas de nouveau module).
4. **Invocation (DM4)** : le router détecte les signaux mission et PROPOSE l'équipe — jamais
   de dispatch d'office, pas de verbe nouveau.
5. **Généricité (DM5)** : zéro chemin ni règle spécifique ; conventions `.planning/` de GSD ; les
   règles de livraison viennent du CLAUDE.md du projet cible.
6. **Contrôle de flux (DM6)** : le manager reprend les mécanismes éprouvés de gsd-autonomous.

### Conséquences

**Positives** : conversation principale légère (travail long possible sans saturation),
doctrine VibeFlow portée par le manager, arborescence de sessions lisible, workers isolés.
**Négatives** : doublon assumé de pilotage GSD (router↔coder, mitigé par renvois aux mêmes
références) ; deux moteurs autonomes à maintenir (inline + équipe, rendus explicites par le
seuil) ; ~10-30 % de tokens en plus sur une mission (rechargement de contexte par worker).

### Code Impacté

- `plugin/dev-orchestrator/agents/` — `vf-dev-manager.md`, `vf-coder.md`, `vf-reviewer.md`, `vf-auditer.md`
- `plugin/dev-orchestrator/references/mission-contracts.md` — contrats (source unique)
- `plugin/dev-orchestrator/AGENT.md` — heuristique 7, ligne de table, anti-pattern
- `plugin/dev-orchestrator/skills/vf-auto/SKILL.md` — Étape 0 (aiguillage)
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — T8-T11
- Spec : `docs/superpowers/specs/2026-07-09-dev-manager-team-design.md` · Plan : `docs/superpowers/plans/2026-07-09-dev-manager-team.md`

### Rules Associées

- Aucune rule nouvelle (DM4 : détection côté agent, pas de gate machine). Les gates existants
  s'appliquent : `check-agents.sh` (ADR-044), densité (ADR-029).

---

## ADR-047 : skill-creator dans la baseline d'install (dépendance du conductor)

**Date** : 2026-07-11
**Statut** : Validée
**Décideur** : Willy (retour terrain sur l'install d'un nouveau lab)
**Contexte** : release v2.24.0 — conductor v1.10.0

### Problème

À l'installation d'un nouveau lab, la partie « installation des skills » n'utilise jamais le
skill-creator, alors qu'il devrait être posé d'office comme le conductor et le validator — y compris
pour des skills personnalisés / procédures internes, qui doivent eux aussi passer par sa pipeline
(recherche → draft → eval → itère) pour rester pertinents et fondés sur les données.

Diagnostic : `skill-creator/AGENT.md` s'auto-déclare « Sole authorized channel for skill creation in
this Lab » ; `vf-new-lab` (Lab Factory, ADR-041 Lab) Phase 5 fait un fan-out
`subagent_type: skill-creator` ; le Gate C exige « créer le skill manquant via skill-creator ». MAIS
`skill-creator` n'était ni `mandatory`, ni dans `conductor.requires` (seulement planning-core +
validator), ni dans la liste « Typiquement » de la Phase 7 → l'agent n'était **jamais installé** → le
fan-out tombait sur un `subagent_type` inexistant. La doctrine du canal unique existait ; son moteur
n'était jamais posé (capacité fantôme, régression silencieuse).

### Options Considérées

| Option | Avantages | Inconvénients |
|--------|-----------|---------------|
| `skill-creator` marqué `mandatory: true` | Posé d'office indépendamment | Sémantiquement faux (il n'est pas un orchestrateur baseline) ; incohérent avec le pattern validator |
| **`skill-creator` ajouté à `conductor.requires` (retenue)** | Convention existante (comme validator) ; tiré d'office par la fermeture transitive du conductor `mandatory` ; sémantiquement juste (outil dont le conductor a besoin pour fabriquer un lab) | Aucun notable |
| Laisser en `optional` à-la-carte | Statu quo | Ne corrige rien — le fan-out reste cassé au premier `vf-new-lab` |

### Décision

1. **`skill-creator` ajouté à `conductor.requires`**, au même titre que `validator`. Le conductor
   étant `mandatory`, sa fermeture transitive (tirée par `--with-deps` à chaque install) inclut
   désormais `skill-creator` → posé d'office avant toute création de lab. `skill-creator` reste
   `optional` au catalogue (pas mandatory lui-même) : exactement le statut de `validator`.
2. **Cohérence documentaire** : `vf-new-lab` Phase 7 point 2 liste `skill-creator` ; garde-fou
   « jamais rédiger un skill à la main — canal unique, même pour une procédure interne » ;
   `installer/SKILL.md` récap d'exemple de la fermeture du conductor.

### Conséquences

**Positives** : le canal unique de création de skills est toujours présent dès l'install ; `vf-new-lab`
fabrique réellement les capacités du lab (fan-out opérationnel) ; ajout/màj de skill plus tard passe
aussi par l'eval du skill-creator (qualité). **Négatives** : un module de plus dans la baseline
(coût disque/contexte marginal, assumé). **Migration** : les labs déjà installés reçoivent
skill-creator via `vibeflow-update --all`.

### Code Impacté

- `plugin/conductor/module.json` — `skill-creator` ajouté aux `requires` (v1.9.0 → v1.10.0)
- `plugin/conductor/skills/vf-new-lab/SKILL.md` — Phase 7 point 2 + garde-fou canal unique
- `plugin/installer/SKILL.md` — récap d'exemple de la fermeture du conductor
- `plugin/.claude-plugin/plugin.json` + `VERSION` racine — v2.23.0 → v2.24.0

### Rules Associées

- Aucune rule nouvelle (mécanisme = résolveur de deps existant). Gates inchangés.

---

## ADR-048 : Orchestrateur métier systématique (≥2 agents) + skill boucle de mission

**Date** : 2026-07-16
**Statut** : Validée
**Décideur** : Willy (retour terrain : comportements dégradés dès >2 agents spécialistes sans chef d'orchestre)
**Contexte** : release v2.25.0

### Problème

`vf-new-lab` pose 2-3 agents métier mais **aucun orchestrateur**. Les bundles renvoient « l'orchestration »
au `conductor`, qui documente noir sur blanc qu'il **ne fait pas le travail métier** et n'est pas invoqué
en continu → **renvoi circulaire**, personne n'assume le principe **P3** (« un orchestrateur planifie,
délègue, réconcilie — ne produit jamais »). Les 3 bundles ont 3 postures **incohérentes** (business-pilot
& content délèguent au conductor ; growth code un orchestrateur ad hoc dans `channel-strategist` tout en
prétendant le contraire). C'est le comportement dégradé observé. Une brique existe (`lead-template.md`)
mais elle est **dev-spécifique** (backend/frontend/sprints) et **jamais consommée** par le pipeline.

### Décision

1. **Nouveau template d'orchestrateur métier générique** `orchestrator-template.md` (≤250L, ADR-029) +
   **skill préchargeable** `metier-orchestration` (≤200L, ADR-044) encodant la **boucle de mission** en
   8 phases : Récupération de contexte (index-first) → Cartographie → Clarification (gate) → Planification
   (+ Adversarial Plan-Review si structurant) → Exécution (délégation via Task, mandat écrit) →
   Vérification (agent frais, factuel + **adversarial**) → Navette exec↔vérif **bornée (3)** → Capitalisation
   + **mise à jour `.planning/`**. Livrés dans le module `reference`.
2. **`vf-new-lab` Phase 7 (point 5bis)** : dès **≥2 agents métier**, poser d'office l'orchestrateur — copier
   le skill verbatim + instancier l'agent parametré au métier (nom, spécialistes délégués, gates métier).
   Seuil < 2 → pas d'orchestrateur. Métier = code → rôle tenu par `dev-orchestrator` (ne pas doubler).
3. **Réconciliation doctrinale des 3 bundles** : l'orchestration métier est portée par l'orchestrateur
   métier posé ; le `conductor` reste **méta** (structure/config/audit/migration + escalades C4).
   `channel-strategist` (growth) est déclaré explicitement comme l'instance du pattern (câblé au skill).

### Conséquences

**Positives** : P3 réellement incarné côté métier ; la boucle ouvre sur la lecture du `.planning/` (Phase 0)
et se referme sur sa mise à jour (Phase 7) → cohérence native avec ADR-050 ; doctrine unifiée entre bundles ;
vérification adversariale (déjà dans P3 v4.1) branchée systématiquement. **Négatives** : un agent de plus sur
les labs multi-agents (coût assumé, justifié par la coordination). **Distinct** du `conductor` (méta) et du
`dev-orchestrator` (code).

### Code Impacté

- `plugin/reference/content/methodology/templates/skills/metier-orchestration/` (SKILL.md + 3 references)
- `plugin/reference/content/methodology/templates/agents/orchestrator-template.md`
- `plugin/conductor/skills/vf-new-lab/SKILL.md` (Phase 7 point 5bis)
- `plugin/conductor/references/bootstrap-method.md` (dérivation + exemple)
- `plugin/{business-pilot-bundle,content-bundle,growth-bundle}/content/BUNDLE.md` + `channel-strategist.blueprint.md`

### Rules Associées

- Gate `check-agents.sh` (ADR-044) valide l'orchestrateur posé (frontmatter natif, skill `metier-orchestration`
  EXISTANT + préchargé ≤200L). Aucune rule nouvelle.

---

## ADR-049 : Backups mémoire isolés + rotation intégrée (anti-pollution registres)

**Date** : 2026-07-16
**Statut** : Validée
**Décideur** : Willy (retour terrain : fichiers de backup/réindex qui polluent le dossier mémoire)
**Contexte** : release v2.25.0 — consolidator

### Problème

`reindex.sh --apply` crée un backup horodaté `<registre>.md.bak-reindex-<ts>` **à côté des registres**,
**sans purge** (la rotation « garde 3 » n'existait que dans `post-edit-reindex.sh`, pas dans les `--apply`
manuels). Résultat mesuré dans un lab réel : **14 fichiers `.bak` (1,6 Mo)**, dont **8 committés** — le
`.gitignore` du lab cible n'excluant pas `*.bak-reindex-*`. Les backups noient les registres et entrent
dans l'historique git.

### Décision

1. **Isoler les backups** dans un sous-dossier dédié **`.claude/memory/.backups/`** (dotdir, hors de la vue
   des registres). `reindex.sh` y écrit, et y dépose un **`.gitignore` auto-suffisant** (`*` + `!.gitignore`)
   → le lab cible n'a plus rien à configurer, les backups ne sont **jamais** committés.
2. **Rotation intégrée dans `reindex.sh`** (garde les N derniers, défaut 3, par registre) → **tout** `--apply`
   purge, pas seulement le hook. `post-edit-reindex.sh` simplifié (la rotation n'y est plus dupliquée).

### Conséquences

**Positives** : dossier `memory/` propre (registres seuls) ; zéro backup committé même sans config du lab ;
rotation garantie sur toute voie d'`--apply`. **Négatives** : aucune (les backups restent disponibles en
local dans `.backups/` pour rollback). **Migration** : les labs existants nettoient les `.bak` historiques
+ passent au nouveau consolidator via `vibeflow-update`.

### Code Impacté

- `plugin/consolidator/scripts/reindex.sh` (backups → `.backups/` + rotation + `.gitignore` auto)
- `plugin/consolidator/scripts/post-edit-reindex.sh` (rotation retirée, pointe le nouveau dossier)
- `plugin/consolidator/scripts/tests/` (couverture isolation + rotation)

### Rules Associées

- Aucune rule nouvelle. Le guard lecture registres (ADR-043) est inchangé.

---

## ADR-050 : Hooks planning — lecture index-first au start + mise à jour bloquante au end

**Date** : 2026-07-16
**Statut** : Validée
**Décideur** : Willy (retour terrain : `.planning/` ni lu au début, ni mis à jour à la fin ; un planning pas à jour = dette)
**Contexte** : release v2.25.0 — planning-core

### Problème

Le hook SessionStart `check-planning-state.sh` est **advisory** : il signale la fraîcheur de `STATE.md`
mais **n'injecte aucun contenu**, ne fait **pas d'index-first**, ignore les compartiments. **Aucun** hook
de fin de session ne contrôle la mise à jour du `.planning/` (reconnu « incrément ultérieur » jamais livré).
Le 8e signal de dette (`detect-planning-debt.sh`, ADR-040) n'est câblé à aucun hook. Résultat : le contexte
planning n'est pas chargé au bon moment, et un `.planning/` périmé (= dette) n'est jamais bloqué.

### Options Considérées

| Option (blocage fin de session) | Verdict |
|--------------------------------|---------|
| Hook `SessionEnd` | Rejeté — non conçu pour bloquer (cleanup/advisory, `|| true`) |
| **Hook `Stop` (deny)** | **Retenu** — seul event capable de bloquer réellement la fin (pattern `permissionDecision: deny` déjà éprouvé : `guard-read-registres.sh`, `guard-file-size.sh`) |

### Décision

1. **Lecture au start (index-first, non saturant)** : `planning-context.sh` (SessionStart) **injecte** un
   digest — lab à compartiments : `INDEX.md` (compartiments + statut 1 ligne) ; lab mono : `STATE.md` borné.
   Complété par `planning-task-context.sh` (**UserPromptSubmit**) qui, une fois la tâche connue, injecte le
   `STATE.md` **du compartiment correspondant** (borné). = « index d'abord, puis le bon planning ».
2. **Mise à jour bloquante au end** : `guard-planning-updated.sh` (**Stop**, deny) bloque la fin de session
   si des **livrables** ont changé mais que `STATE.md` du compartiment actif **n'a pas été mis à jour**.
   **Garde-fous anti-piège** (obligatoires) : ne bloque que si `.planning/` existe ET des livrables ont
   changé (session read-only/config → jamais bloquée) ; **échappatoire explicite** (marqueur de session
   no-op) ; motif = instruction actionnable pour sortir de la boucle ; repo non-git → skip (pas de piège).
   Le 8e signal (`detect-planning-debt.sh`) est branché ici.

### Conséquences

**Positives** : le planning est lu au bon grain au démarrage (structuration du contexte respectée) et ne
peut plus rester périmé en silence (dette machine-enforced). Cohérent avec la boucle de mission ADR-048
(Phase 0 lit / Phase 7 met à jour). **Négatives / risque** : un hook `Stop` bloquant est intrusif — mitigé
par les garde-fous anti-piège et un **mode advisory togglable** (`VF_PLANNING_STOP=warn`) pour une montée en
charge progressive. Premier hook `Stop` du plugin.

### Code Impacté

- `plugin/planning-core/scripts/{planning-context.sh, planning-task-context.sh, guard-planning-updated.sh}`
- `plugin/planning-core/hooks/hooks.json` (SessionStart enrichi + UserPromptSubmit + Stop)
- `plugin/planning-core/scripts/detect-planning-debt.sh` (branché au Stop) + tests

### Rules Associées

- Réutilise le pattern de blocage `PreToolUse`→`permissionDecision: deny` (ADR-043) transposé à `Stop`.

### Amendement 2026-07-20 — attribution de session (fix faux positifs terrain)

**Constat terrain (Samuel, dev vibeflow-os via GSD/dev-orchestrator)** : le guard v1 ne regardait que
`git status --porcelain` alors que `Stop` se déclenche **à chaque fin de tour** (et `stop_hook_active`
retombe à `false` après chaque nouveau message utilisateur). Deux faux positifs quasi systématiques :
(1) un `STATE.md` mis à jour **puis committé** pendant la session devient invisible du porcelain →
blocage à tort à chaque tour ; (2) du **dirt préexistant** au démarrage est attribué à tort à la session.

**Correction (v2)** : nouveau hook SessionStart `planning-session-snapshot.sh` (toutes sources,
first-wins au compact) écrit une **baseline de session** (epoch + HEAD de départ + porcelain hashé) dans
`$TMPDIR/vibeflow-planning-guard/`. Le guard raisonne désormais en « changé pendant CETTE session » :
signaux planning **larges** (committé dans la fenêtre `git log --since=début` ∪ sale ∪ mtime strictement
postérieur au début — couvre `.planning/` gitignoré) ; attribution livrables **stricte** (committé dans la
fenêtre — les commits tiers rapatriés par pull/merge sont exclus par committer-date — ∪ dirt absent de la
baseline ou au hash blob modifié). Marqueur `<session>.blocked` : au pire **un blocage par session**.
Baseline absente/périmée (>48h) ou arbre massivement sale (>400 entrées) → fail-open. L'asymétrie
large/strict minimise structurellement les faux positifs (un faux négatif coûte une note de planning,
un faux positif coûte la confiance dans le garde-fou + des tokens).

---

## ADR-051 : Allowlist MCP des agents exécutants dérivée du lab (injection à l'install)

**Date** : 2026-07-19
**Statut** : Validée
**Décideur** : Samuel (brief de correction + choix « A+B complet » verrouillé en session)
**Contexte** : release v2.26.0 — dev-orchestrator v1.6.0, mobile-test-team v1.2.0, conductor v1.11.1

### Problème

Un sous-agent dispatché via l'outil `Task` **n'hérite pas** des serveurs MCP de la session : côté
MCP, il ne voit que ce que son `tools:` autorise explicitement. Les agents **exécutants** de VibeFlow
(`vf-coder`, `vf-app-fixer`, `vf-test-runner`, `vf-test-orchestrator`) portent une allowlist `tools:`
**fermée** sans entrée MCP. Conséquence : sur tout lab dont le projet s'appuie sur un serveur MCP
(XcodeBuildMCP pour l'iOS natif, mais aussi mobile-mcp, une DB, un navigateur, un cloud), l'agent qui
**compile/teste/corrige** ne voit pas l'outil `mcp__<serveur>__*`. Seule la fenêtre principale l'a —
ce qui casse la délégation autonome (`vf-auto`, `vf-dev-manager`). Symptôme réel observé : un lab iOS
Swift où `vf-coder` a rapporté à tort « XcodeBuildMCP absent, redémarrer Claude Code ».

Le même mal touche `gsd-executor`, mais **il n'appartient pas au plugin** (fourni par GSD, posé dans
`~/.claude/agents/`).

### Contrainte technique décisive

Le glob générique **`mcp__*` n'est PAS accepté dans `tools:`** (doc officielle Claude Code : il
n'existe qu'en `disallowedTools`). Seule la forme **par-serveur** `mcp__<serveur>__*` est admise en
allowlist (précédent : `mcp__context7__*`, déjà présent dans plusieurs agents GSD). Le correctif « une
ligne wildcard » du brief initial est donc **impossible** : il faut nommer chaque serveur — sans pour
autant clouer un serveur stack-spécifique (XcodeBuildMCP est Apple ; `dev-orchestrator` est
multi-stack) dans un agent générique.

### Options Considérées

| Option | Avantages | Inconvénients |
|--------|-----------|---------------|
| Hardcoder `mcp__XcodeBuildMCP__*` dans les agents | Immédiat | Couple les agents génériques à Apple ; ne couvre pas les MCP métier ; contredit le multi-stack |
| A seul — liste statique curatée de serveurs par défaut | Aucune logique d'install | Ne couvre pas un MCP custom non listé ; noms stack-spécifiques dans des agents génériques |
| **A+B — défaut minimal + injection dérivée du lab (retenue)** | Vraiment générique (n'importe quel serveur déclaré) ; moindre privilège par lab ; zéro nom en dur | Logique d'install à écrire + un flag agent |

### Décision

1. **Sélecteur data-driven** : les agents exécutants portent `vf-mcp-consumer: true` (analogue à
   `mandatory:` / `vf-internal:`). Les agents de planification et d'audit (`vf-dev-manager`,
   `vf-auditer`) **restent inchangés** (moindre privilège — ils ne compilent jamais). Le relecteur
   (`vf-reviewer`) reçoit une allowlist **NOMMÉE**, portée par la clé de frontmatter `vf-mcp-tools`
   (grammaire `<serveur>:<outil1>,<outil2>,…`, injectée par le même script en mode dédié — Phase 20) :
   un relecteur ne PRODUIT pas un verdict de compilation, il en VÉRIFIE un — le moindre
   privilège reste tenu par une liste explicite d'outils de vérification, pas par l'absence totale
   d'accès MCP. Coût assumé, écrit noir sur blanc : de l'ordre de **+90 secondes** par revue et un
   **slot de simulateur** consommé, uniquement quand la vérification outillée est déclenchée. Champ
   ajouté au `KNOWN` de `check-agents.sh`.
2. **Injecteur idempotent** `dev-orchestrator/scripts/inject-mcp-tools.sh` : lit les serveurs du
   `./.mcp.json` du lab et injecte `mcp__<serveur>__*` dans le `tools:` des fichiers flaggés (ou d'un
   fichier `--force` pour `gsd-executor`). Aucun nom de serveur ni d'agent en dur. Best-effort.
3. **Câblage** : hook post-install dans `vibeflow-update.sh` (à chaque pose d'agents) ; patch
   `gsd-executor` dans `ensure-deps.sh` après l'install GSD (re-jouable → auto-réparateur après une
   réinstall GSD) ; ré-affirmation dans `/vf-calibrate` quand le `.mcp.json` évolue sans bump.

### Conséquences

**Positives** : la délégation autonome fonctionne sur tout lab à MCP (iOS, mobile, métier) ; moindre
privilège réel (chaque lab n'obtient que ses serveurs déclarés) ; générique et sans dépendance Apple
imposée ; enforcement machine cohérent avec la philosophie « scope-aware ».
**Négatives** : le `tools:` est lu au **démarrage de session** → un **redémarrage de Claude Code** est
requis après (ré)install pour que l'allowlist prenne (documenté dans les CHANGELOGs) ; la source est
le `./.mcp.json` **projet** — un serveur configuré uniquement au niveau user n'est pas injecté (par
conception : moindre privilège, alignement sur le brief) ; l'accès nommé du relecteur (Phase 20) porte
deux contraintes de protocole que le mécanisme rend nécessaires : **l'ordre d'appel imposé** (le
nettoyage `clean` précède toute compilation ou exécution de tests de vérification, faute de quoi un
résultat servi par le cache annoncerait zéro avertissement sans avoir rien compilé) et **des
paramètres de projet explicites à chaque appel de build** (le serveur MCP maintient un état de
session global partagé par la fenêtre principale et tous les sous-agents — un appel sans paramètres
peut s'exécuter sur un autre arbre de travail).

### Cloisonnement anti-triche (Pattern 12) — inchangé

La séparation `Read/Write/Edit` entre `vf-test-runner` (écrit les tests) et `vf-app-fixer` (écrit le
code) reste le garde-fou. On n'injecte que des serveurs de **build/test** déclarés par le lab, pas
d'accès web/doc : `vf-app-fixer` conserve son interdiction ADR-045 (pas de context7/web ; escalade
`doc-research-required`). Orthogonal, vérifié.

### Code Impacté

- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` (nouveau) + `scripts/tests/test-inject-mcp-tools.sh` (nouveau, 10 cas)
- `plugin/dev-orchestrator/agents/vf-coder.md` — flag `vf-mcp-consumer: true`
- `plugin/mobile-test-team/agents/` — `vf-app-fixer.md`, `vf-test-runner.md`, `vf-test-orchestrator.md` — flag
- `plugin/conductor/scripts/check-agents.sh` — `KNOWN += vf-mcp-consumer`
- `plugin/_internal/vibeflow-update.sh` — `find_mcp_injector` + `inject_lab_mcp_into_agents` (hook post-install)
- `plugin/dev-orchestrator/scripts/ensure-deps.sh` — `patch_gsd_executor_mcp` (post-install GSD)
- `plugin/conductor/skills/vf-calibrate/SKILL.md` — étape de ré-affirmation MCP
- `plugin/dev-orchestrator/agents/vf-reviewer.md` (Phase 20) — clé `vf-mcp-tools:
  XcodeBuildMCP:test_sim,build_sim,clean` + protocole de vérification outillée
- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` (Phase 20) — second mode d'injection en
  **mode nommé**, déclenché par la clé `vf-mcp-tools`, coexistant avec le mode joker existant
  (le nommé l'emporte si les deux clés sont présentes sur un même fichier)

### Rules Associées

- Aucune rule nouvelle. Gate machine existant : `check-agents.sh` (ADR-044) accepte le flag ; le
  sélecteur `vf-mcp-consumer` EST le point d'enforcement (data-driven, aucun nom en dur).

---

## ADR-052 : Frontmatter mémoire enrichi — trust + confidence à décroissance par catégorie + supersession non destructive

**Date** : 2026-07-22
**Statut** : **Validée** (Samuel, 2026-07-22) — implémentation dans `plugin/consolidator/` autorisée.
**Décideur** : Samuel — validée sur la base du spike Phase 9 (verdict GO) + panel de recalibration des demi-vies
**Contexte** : Phase 9 (R&D, hors chaîne de release). Source : `.planning/research/jcode-memory-swarm-transposition-NOTE.md` + `.planning/phases/VFDO-09-*/09-GO-NOGO-memoire.md`. Panel de recalibration des demi-vies exécuté en session.

### Précision de périmètre (validée 2026-07-22, avant implémentation)

La cartographie du module a révélé **deux systèmes mémoire distincts** que la note du spike conflatait :
- **Registres d'audit tabulaires** (`DECISIONS.md`, `LEARNINGS.md`, `BLOCKERS.md`, `ADR.md`…) — trace
  historique **permanente**, gérée par `reindex.sh`/`archive.sh`. Une décision datée ne « perd pas en
  confiance » → **la décroissance n'a pas de sens ici. Ces registres restent INCHANGÉS.**
- **Mémoire vivante fichier-par-entrée** (un `.md`/fait, frontmatter `name`/`metadata.type` — le format
  natif de la mémoire Claude Code) — le **savoir vivant** de l'agent sur le lab (qui est l'user, ses
  préférences, faits projet, pointeurs). Sa fiabilité **évolue** → **c'est la cible réelle de l'ADR.**

**Décision de périmètre** : introduire cette mémoire vivante comme **nouvelle couche versionnée dans le lab**
(`.claude/memory/knowledge/` : `MEMORY.md` d'index + `<slug>.md` + `archive/`), **à côté** des registres
d'audit — pas à leur place. Elle est gouvernée par une **passe dédiée** du `consolidator` (nouveau script,
pas une extension de `reindex.sh`/`archive.sh` qui sont couplés au format tabulaire). Choix retenu pour la
fidélité à jcode (un nœud riche par mémoire), l'alignement sur le format plateforme Claude Code (pérennité)
et la séparation nette audit vs savoir vivant (maintenabilité).

### Problème

La mémoire fichier de VibeFlow (`memory/*.md` : `name` / `description` / `metadata.type` + liens `[[slug]]`) est une **liste plate sans fiabilité ni fraîcheur**. Trois manques : (1) rien ne distingue un fait **dit** par l'utilisateur d'un fait **inféré** ; (2) rien ne fait **périmer** un fait obsolète (un fait de codebase et une correction durable ont le même poids éternel) ; (3) la seule façon de retirer un souvenir est la **suppression manuelle** — destructive, contraire à ADR-031. jcode (harness Rust) modélise nativement `trust` / `confidence` décroissante / supersession. Le spike Phase 9 a **prouvé mécaniquement** (critère binaire D-05) que les 3 gestes minimaux se transposent **sans runtime** : une passe batch idempotente lit→recalcule→réécrit sans édition humaine, et une entrée `superseded_by` est archivée sans destruction.

### Options Considérées

| Option | Avantages | Inconvénients |
|--------|-----------|---------------|
| Statu quo (liste plate) | Zéro coût | Pas de fiabilité, pas de péremption, retrait = suppression destructive (anti ADR-031) |
| Copier tout jcode (embeddings + RRF + graphe + pipeline par-tour) | Rappel sémantique riche | **Hors runtime** Claude Code (pas d'embeddings intra-session, pas de hook par-tour fiable) — rejeté §note |
| **3 gestes minimaux + décroissance batch dans `consolidator` (retenue)** | Prouvé sans runtime, coût humain nul (idempotent), aligné ADR-031 | Ajoute 5 champs saisis + 2 dérivés au frontmatter (densité à tenir) |

### Décision

1. **Frontmatter enrichi** du format `memory/*.md` (5 saisis + 2 dérivés) :
   ```yaml
   metadata: { type: user | feedback | project | reference }
   trust: high | medium | low        # qui affirme (high=dit / medium=observé / low=inféré)
   confidence: 0.0–1.0               # base, posée à la création/renforcement (non lossy)
   created: YYYY-MM-DD               # ancre de la décroissance
   status: active | superseded       # supersession non destructive
   superseded_by: <slug>             # vide si active
   effective_confidence: 0.0–1.0     # DÉRIVÉ — recalculé à chaque passe (non saisi)
   last_decay_pass: YYYY-MM-DD       # DÉRIVÉ — traçabilité
   ```
2. **Mapping catégories jcode → types VibeFlow (1:1)** : `Correction`→`feedback`, `Preference`→`user`, `Entity`→`reference`, `Fact`→`project`. `Custom` non transposé (retombe sur `project`).
3. **Demi-vies recalibrées multi-métiers** (post-panel) : `feedback` **365 j** (le moat — inchangé) / `user` **180 j** / `reference` **120 j** / `project` **30 j**. Le `project` **revient à 30 j** (le rallongement à 45 j du spike inversait le sens pour de l'état volatil — deadlines, sprints, tendances périment en jours/semaines : consensus du panel).
4. **Formule** (sans access-boost, `reinforced[]` différé) : `effective_confidence = confidence × 0.5 ^ (age_jours / demi_vie[type])`.
5. **Supersession = déplacement** vers `archive/` + `status: superseded` (jamais de suppression — ADR-031). `confidence` reste la **base** ; la décroissance vit dans le champ **dérivé** `effective_confidence` (idempotence : ne pas écraser la base).
6. **Point d'intégration** : un **script dédié** (`decay-pass.sh`, pattern Python-inline du module) applique la décroissance sur `.claude/memory/knowledge/`, exposé comme **pilier 5 du `consolidator`** (« Mémoire vivante », `/consolidate --pillar=decay`) — passe **batch**, pas par-tour. `reindex.sh`/`archive.sh` ne sont **pas** modifiés (couplés au format tabulaire). **Seuil de rétrogradation** retenu : `effective_confidence < 0.2` (`VF_DECAY_REVIEW_THRESHOLD`) → flag `needs_review: true`, jamais suppression.

### Limites reconnues (panel) — hors périmètre de ce GO

`reference` et `project` restent des **buckets à deux vitesses** (ticket éphémère vs infra permanente ; deadline volatile vs insight durable). Extensions **candidates ultérieures, non décidées ici** : sous-type volatil court `signal` (~14–21 j) pour marketing/contenu ; champ `expires_at` (**couperet dur** pour devis/certificats, là où l'exponentielle modélise mal une date d'expiration) ; épinglage `pin` de la master-data non-décroissante ; reset d'âge au ré-accès (= `reinforced[]` / access-boost jcode, déjà différé). Ces pistes ne bloquent pas le GO minimal.

### Conséquences

**Positives** : fiabilité et fraîcheur explicites ; retrait non destructif conforme ADR-031 ; coût de maintenance humain **nul** (passe idempotente prouvée) ; aucun runtime requis (batch consolidator) ; format fichier préservé (une entrée = un `.md`, pas de base binaire).
**Négatives** : +7 lignes de frontmatter par entrée (densité ADR-029 : mesuré ≤ ~12 lignes/entrée, sous les seuils) ; la décroissance ne s'applique qu'à la **passe** `consolidator`, pas en continu (accepté — pas de hook par-tour fiable) ; les demi-vies restent des heuristiques à affiner empiriquement.

### Code Impacté

- **Nouveau** `plugin/consolidator/scripts/decay-pass.sh` (+ suite `scripts/tests/test-decay.sh`) — passe de décroissance + supersession sur `.claude/memory/knowledge/`, modes `--dry-run`/`--apply`, idempotente. S'inspire de l'algo `spike/decay-pass.py` (référence, pas réutilisé tel quel).
- **Nouveau** template + doc de format de la mémoire vivante :
  `plugin/reference/content/methodology/templates/memory/knowledge-entry-template.md` (fichier
  versionné — son miroir installé `docs/reference/…` est gitignoré et n'existe que dans un lab).
- `plugin/consolidator/SKILL.md` + `references/indexation.md` — documente le geste décroissance (pilier Indexation) et la couche mémoire vivante.
- `reindex.sh` / `archive.sh` — **inchangés** (registres tabulaires d'audit, hors périmètre).
- Bump `plugin/consolidator/VERSION` + `module.json` + `CHANGELOG.md` (nouvelle capacité → minor).

### Rules Associées

- S'appuie sur ADR-031 (jamais de destruction/fix sans validation humaine — la supersession EN EST l'application) et ADR-049 (backups mémoire isolés — l'archivage réutilise `.backups/`). Aucune rule nouvelle avant implémentation.

---

## ADR-053 : Volet swarm — lock de driver unique + DAG ready/blocked + rapports de worker typés

**Date** : 2026-07-22
**Statut** : **Validée** (Samuel, 2026-07-22) — périmètre **A+B+C complet** choisi explicitement, le garde-fou YAGNI du cadrage (« pas avant collisions observées ») est **levé en connaissance de cause**.
**Décideur** : Samuel
**Contexte** : Phase 9 (memory-swarm-rnd). Source : `.planning/phases/VFDO-09-*/09-CADRAGE-swarm.md` (transposition swarm jcode §2 + custody no-mistakes §6.6). Cible : module `dev-orchestrator` (équipe `vf-dev-manager` & workers).

### Problème

L'équipe VibeFlow est un **dispatch-and-join** (`Task`), pas des acteurs concurrents. Trois fragilités : (1) **collision de pilotage** — deux missions/sessions qui pilotent la même étape en parallèle se marchent dessus sur les backups isolés (ADR-048/049) ; (2) le **plan de bataille** du manager est une **liste linéaire** — un correctif qui rouvre une étape ne « ré-entre » pas proprement dans le dispatch ; (3) les **rapports de worker sont en prose** — le manager interprète du texte au lieu d'un contrôle de flux déterministe. jcode (verrous + DAG) **et** no-mistakes (custody) convergent : la réponse est une **discipline de verrous + fichiers d'état**, pas un bus temps réel.

### Options Considérées

| Option | Avantages | Inconvénients |
|--------|-----------|---------------|
| Statu quo (dispatch-and-join, plan linéaire, rapport prose) | Zéro coût | Collisions possibles, ré-entrée fragile, contrôle de flux non déterministe |
| Bus temps réel (UDS/channels/dm façon jcode) | Coordination riche | **Hors runtime** Claude Code (pas de socket entre sous-agents) — rejeté |
| **Discipline de verrous + fichiers d'état (A+B+C, retenue)** | Réalisable sans socket, sûr par construction, aligné doctrine | Refonte du contrôle de flux du manager + scripts d'état + typage des 4 workers |

### Décision

1. **Pattern A — Lock de driver unique** : script `driver-lock.sh` (acquisition **atomique** par `mkdir` de `.planning/DRIVER.lock/`, méta owner/étape/heartbeat). `vf-dev-manager` **acquiert avant de dispatcher**, **rafraîchit le heartbeat entre étapes**, **relâche à la clôture** (succès/échec/abandon — release « RAII » porté par le prompt). **Récupération de claim périmé livrée d'emblée** : un lock dont le heartbeat dépasse le TTL (`VF_DRIVER_TTL`, défaut 1800 s) est élagué et ré-acquis, reprise consignée. *(Limite assumée : pas de vrai RAII machine — un agent LLM peut mourir sans release ; le TTL+heartbeat est le filet, d'où recovery obligatoire.)*
2. **Pattern B — DAG ready/blocked** : le plan de bataille devient un graphe persistant (`dag.sh` + `<mission>.dag.json`), nœuds `{id, étape, étage, deps[], status ∈ blocked|ready|running|done|failed}`. Le manager dispatche **la frontière `ready`** (deps `done`) ; un fix qui **rouvre** une étape repasse le nœud (et ses dépendants) à `ready` → **ré-entrée**. Remap déterministe `id::scope` sur collision d'id.
3. **Pattern C — Rapports de worker typés** : `vf-coder`/`vf-reviewer`/`vf-auditer`/`vf-test-orchestrator` rendent `{statut ∈ passed|gaps_found|human_needed|blocked, findings[{severity, action ∈ auto-fix|no-op|ask-user}], nœuds_débloqués[]}` (aligne les statuts existants de `*-VERIFICATION.md` + la taxonomie d'action de la note §6.2). Le manager fait un **contrôle de flux déterministe** dessus.

Protocole détaillé (source de vérité) : `plugin/dev-orchestrator/references/mission-flow.md`.

### Conséquences

**Positives** : plus de collision de pilotage (lock atomique + recovery) ; ré-entrée robuste (boucle fix→re-revue explicite) ; contrôle de flux déterministe (fin de l'interprétation de prose) ; sûr par construction, sans socket.
**Négatives** : le release du lock dépend du prompt (pas de RAII machine) → **recovery obligatoire** ; refonte du manager + 4 workers typés (2 modules touchés : `dev-orchestrator` + `mobile-test-team`) ; état supplémentaire dans `.planning/`.

### Code Impacté

- **Nouveau** `driver-lock.sh` + `dag.sh` (+ tests `test-driver-lock.sh`, `test-dag.sh`) — livrés à
  l'époque dans `plugin/dev-orchestrator/scripts/`, **déménagés en v2.34.0 vers
  `plugin/conductor/scripts/`** (team-kernel transverse, cf. `conductor-references/team-kernel.md`).
- **Nouveau** `plugin/dev-orchestrator/references/mission-flow.md` (protocole A/B/C, contrat de rapport).
- `agents/vf-dev-manager.md` — acquisition/heartbeat/release + pilotage par DAG + consommation des rapports typés.
- `agents/vf-coder.md` / `vf-reviewer.md` / `vf-auditer.md` — section « Retour » typée. `mobile-test-team/agents/vf-test-orchestrator.md` — idem.
- Bump `dev-orchestrator` v1.6.0 → v1.7.0 ; `mobile-test-team` bump mineur. Gate `check-agents.sh` sur chaque agent modifié.

### Rules Associées

- S'appuie sur ADR-048/049 (backups isolés — le lock protège leur intégrité), ADR-044 (agents machine-enforced — les agents modifiés repassent `check-agents.sh`), ADR-031 (la taxonomie `ask-user` raffine « jamais de fix sans validation humaine »). Aucune rule nouvelle.

---

## ADR-054 : Portabilité Windows — normalisation CRLF, préflight, gardes réellement actives, gate de synchro versions

**Date** : 2026-07-23
**Statut** : Validée (2 rapports terrain intégrés)
**Décideur** : Willy (2 rapports terrain rejouables de deux élèves de la formation, Windows 11 + Git Bash ; causes racines reproduites en local)
**Contexte** : release v2.29.0 — conductor v1.12.1, consolidator v1.6.1, software-architecture v1.5.1, planning-core v2.3.1, kpi-analyst v1.0.1

### Problème (rapport 1 — install, 2026-07-22)

1. **jq absent de Git Bash** (jamais inclus par Git for Windows) et documenté NULLE PART comme
   prérequis — angle mort de dev : macOS 15 livre `/usr/bin/jq` en natif. Pire : `resolve-deps.sh`
   n'avait AUCUN guard — sans jq, la process substitution avalait « command not found » et rendait
   une fermeture INCOMPLÈTE avec exit 0 (install silencieusement amputée).
2. **Le jq Windows natif écrit en mode texte** (chaque `\n` → `\r\n`, by design, non corrigeable
   par version — le flag `-b` est opt-in par appel et absent de jq 1.6). `$()` ne retire que le
   `\n` final → `\r` fantôme : `resolve-deps.sh` cherchait `planning-core\r` (crash en pleine
   boucle, symptôme exact du rapport), le catalogue dégradait `conductor` en `optional` et faisait
   fuiter les bundles `proposable:false` (comparaisons `= "true"` cassées — corruption SILENCIEUSE,
   rc=0), `framework-version.sh drift` signalait un écart permanent, `kpis-writer.sh` persistait
   `"domain": "generic\r"` DANS la donnée (KPIS.md, ingéré par le Hub).
3. **`installer/SKILL.md` invoquait ses scripts par nom nu** (12+ sites) → le LLM exécutant
   devinait parmi ~10 dossiers `scripts/` (`installer/build-module-catalog.sh` deviné, inexistant).
4. **Fiche marketplace + badges README dérivés de 2 releases** — `check-release-tag.sh` ne
   vérifiait que VERSION ↔ tag.
5. **`merge-hooks.sh` codait `python3` en dur** : sous Windows le `python3` du PATH peut être le
   stub Microsoft Store (App Execution Alias : `command -v` réussit, l'exécution PEND ou sort en 49
   sans stdout) et python.org ne fournit pas de `python3.exe` → module installé SANS ses hooks de
   gouvernance (perte silencieuse).

### Problème (rapport 2 — runtime, 2026-07-23, amendement)

6. **Gardes runtime inertes en paraissant installées.** Les hooks fail-open (`command -v python3
   || exit 0`) ne testent que la PRÉSENCE : sur Windows le stub Store la satisfait → la branche
   de repli n'est JAMAIS atteinte, le `python3 -c` réel meurt en silence (rc 49, stdout vide),
   l'appel est autorisé. Cas le plus grave signalé : env d'install ≠ env des hooks → harnais
   complet, correctement câblé, entièrement inopérant, sans signal. Principe du rapporteur adopté :
   « une protection annoncée n'est pas une protection tant qu'une tentative de violation n'a pas
   échoué sous nos yeux ».
7. **Préfiltre CSL-13 aveugle aux antislashs.** Les 3 scripts consolidator (guard-read,
   guard-bash, post-edit-reindex) préfiltrent sur la sous-chaîne `.claude/memory/` (slashes) AVANT
   le spawn python. Un chemin Windows arrive en antislashs (JSON-échappés `\\`) → préfiltre
   court-circuite → le python — qui normalisait justement les antislashs (`replace("\\","/")`,
   CSL-12) — n'est jamais atteint. Le traitement Windows existait derrière une porte jamais
   ouverte. (`guard-agent-write` épargné : son motif `.claude` n'a pas de barre.)
8. Annexe : `bash` peut être ABSENT du PATH Windows (seul `Git\cmd` y figure) tout en existant
   (`Git\bin\bash.exe`) → contrôle préflight ajouté.

### Décision — défense en profondeur

1. **Wrapper `jqx() ( set -o pipefail; command jq "$@" | tr -d '\r'; )`** dans les 5 scripts jq —
   normalisation CONSOMMATEUR, version-agnostique, code retour propagé. Règle : jq nu interdit
   (gate T7 de `test-windows-crlf.sh`). Guards + messages d'install par OS ; `resolve-deps.sh` en
   capture explicite (échec jq BRUYANT).
2. **Préflight** (`installer/scripts/preflight.sh`, étape 0 BLOQUANTE) : git, jq (+ sonde CRLF
   informative), python3 RÉEL (sonde d'exécution `timeout`-gardée, rejet `WindowsApps`, version ≥3,
   candidats `python3`→`python`, état « py seul » = KO), `bash` dans le PATH. Même résolution dans
   `merge-hooks.sh`.
3. **Résolution d'interpréteur dans les hooks runtime** (amendement) : détection par CHEMIN — zéro
   spawn ajouté au budget latence — `case "$(command -v python3)" in ''|*WindowsApps*)` → repli
   `python`, sinon fail-open inchangé. Appliquée aux 8 scripts de hooks python3.
4. **Préfiltres CSL-13 compatibles antislashs** (amendement) : normalisation du payload pour le
   MATCH uniquement (`${PAYLOAD//\\//}`) — le python reçoit toujours le payload original. Le
   surensemble strict redevient vrai sur Windows.
5. **Signal de garde inactive** (amendement, suggestion du rapporteur adoptée) :
   `probe-memory-guards.sh` (SessionStart consolidator, advisory) — sonde d'EXÉCUTION une fois par
   session ; si aucun interpréteur utilisable : « ⚠ gardes mémoire INACTIVES : python injoignable ».
6. **`.gitattributes` eol=lf** + **chemins pleinement qualifiés** au point d'usage (installer,
   vf-calibrate, vf-new-lab — pattern du contre-exemple vertueux vf-update).
7. **Gate `check-version-sync.sh`** (pre-push via check-release-tag) : VERSION ↔ plugin.json ↔
   marketplace.json ↔ badges/texte des 2 README ↔ compte réel de module.json.
8. **Licence — grant élèves** (décision Willy) : un élève de la formation est un « authorized
   lab » : usage via le plugin ET réutilisation/adaptation d'éléments de modules dans ses dépôts
   PRIVÉS pour ses propres labs ; redistribution/publication/revente interdites. LICENSE amendée.

### Tests

`plugin/_internal/tests/test-windows-crlf.sh` (shim jq-CRLF + PATH sans jq, 10 asserts, gate T7) +
`plugin/consolidator/scripts/tests/test-windows-guards.sh` (amendement : payload antislashs → deny
effectif ; stub `WindowsApps/python3` factice → repli `python` ; aucun python → fail-open + signal
du probe). Rejouables sur macOS/Linux sans poste Windows.

### Restes assumés

- Comportement pré-existant observé : `install --with-deps` en scope `local` dans un dossier
  non-git s'arrête après le 1er module (rc=1, sans message ni registre) — identique sur main.
- Issue #20 : mode `--dry-run`/manifeste fichier-par-fichier avant pose (demande des mêmes
  testeurs, revue à deux avant écriture).
- Validation terrain réelle par les 2 testeurs Windows au tag v2.29.0 (protocole fourni).

### Rules Associées

- Aucune rule nouvelle. Gates machine : T7 (jq nu interdit) + `check-version-sync.sh` (pre-push) +
  `test-windows-guards.sh` (gardes actives sous chemins Windows).

---

## ADR-055 : Frontière d'altitude entre `planning-core` et le moteur de planning GSD

**Date** : 2026-07-25
**Statut** : Validée
**Décideur** : Samuel (constat : « le vf-planning est en concurrence directe avec le planning de GSD »)
**Contexte** : release v2.29.0 — planning-core v2.4.0

### Problème

`vf-planning` et la chaîne GSD produisent **les mêmes fichiers** dans **le même dossier** avec des
frontmatters **incompatibles** : `planning_version` + `progress.total_steps` d'un côté,
`gsd_state_version` + `progress.total_phases/total_plans` de l'autre. Le premier moteur qui écrit rend
l'autre aveugle (`gsd-sdk query`, `gsd-health`, `gsd-session-state.sh` ne lisent pas le format
`planning-core`, et réciproquement). S'y ajoutent une double injection `SessionStart`
(`gsd-session-state.sh` + `check-planning-state.sh` + `planning-context.sh`) et une concurrence au
matching sémantique : la description de `vf-planning` revendiquait « fais-moi une feuille de route »
et « où en est-on ? », face à `gsd-new-project` et `gsd-progress`.

Le recouvrement dépassait le tronc : compartiments vs `gsd-workstreams`/`workspace`, pont mémoire vs
`gsd-extract-learnings`/`graphify`/`thread`, fraîcheur vs `gsd-health`.

### Options Considérées

| Option | Verdict |
|---|---|
| GSD moteur unique sur tous les labs | Rejetée — `roadmapper`/`phases`/`requirements` sont taillés pour le code ; casse les 4 bundles non-dev |
| Bascule sur la présence de GSD au lieu du métier | Rejetée — un lab contenu avec GSD installé hériterait d'un planning dev |
| GSD gagne partout où il a un équivalent | Rejetée — perd l'enforcement automatique et le lien aux registres VibeFlow |
| Coexistence documentée | Rejetée — c'est l'état de départ ; l'ambiguïté de déclenchement reste entière |
| Détecteur bash du métier | Rejetée — heurte `domain-detection.md` : un lab de contenu peut avoir un `package.json` |
| **Frontière d'altitude** | **Retenue** — test unique et vérifiable : « ça concerne un projet, ou le lab ? » |

### Décision

1. **Un projet de code a un seul moteur de planning : GSD.** `planning-core` ne génère plus aucun
   artefact de projet sur un lab dev ; il redirige vers le verbe `/vf-*` (jamais un `gsd-*` en
   entrée de chaîne).
2. **`planning-core` garde l'altitude lab** (`INDEX.md`, typage `deliverable`/`continuous`, seuil
   d'autonomie, dette) et **la couche à côté** (pont mémoire vers `.claude/memory/`), plus **le socle
   complet des labs non-dev** — où GSD n'est ni installé ni pertinent.
3. **Le métier reste du jugement** ; seul le fait « un moteur GSD est-il en place » est outillé
   (`detect-gsd-engine.sh`, 4 exits par ordre de priorité).
4. **Exception assumée — le `Stop` guard reste bloquant** : `guard-planning-updated.sh` ne génère
   rien, il vérifie une propriété du *résultat* quel qu'en soit l'auteur. GSD n'a aucun équivalent
   bloquant (`gsd-health` signale à la demande).
5. **Aucune réécriture d'un `.planning/` existant** (ADR-031) : le cas migration avertit et propose,
   l'utilisateur décide.

### Conséquences

**Positives** : plus de format concurrent dans un même `.planning/` ; fin de la double injection au
démarrage ; le déclenchement est désambiguïsé côté description, pas seulement côté exécution ;
`planning-core` retrouve un périmètre défendable (le lab, la mémoire, l'enforcement) au lieu d'un
tronc universel qui doublonnait le moteur de dev. **Négatives / risque** : les labs dev déjà porteurs
d'un `.planning/` de facture `planning-core` restent en format non lisible par l'outillage de dev — et
aucune migration automatique n'existe (`gsd-import --from` n'importe qu'un plan isolé). Mitigation :
exit 2 dédié, protocole de reprise documenté, geste humain assisté.

### Code Impacté

- `plugin/planning-core/scripts/detect-gsd-engine.sh` (nouveau) + son test
- `plugin/planning-core/scripts/{check-planning-state.sh, planning-context.sh}` (flag `--defer-to-gsd`)
- `plugin/planning-core/hooks/hooks.json` (SessionStart : `--defer-to-gsd`)
- `plugin/planning-core/SKILL.md` (description rescopée + étape 0 + séquences A/B)
- `plugin/planning-core/references/{gsd-handoff.md (nouveau), domain-detection.md}`
- `plugin/commands/vf-planning.md`

### Rules Associées

- S'appuie sur ADR-031 (« jamais de fix sans validation humaine ») pour le cas migration : on avertit
  et on propose, on ne réécrit pas un `.planning/` existant. Confirme ADR-050 (le `Stop` guard reste
  bloquant, seule exception au retrait de `planning-core` du terrain projet) et ADR-040 (le 8e signal
  de dette reste porté par `planning-core`, à l'altitude lab). Aucune rule nouvelle.


---

## ADR-056 : Vigilance support runtime (scission du double emploi d'ADR-031)

**Date** : 2026-07-25 · **Statut** : Validée

### Contexte

L'audit du 2026-07-25 a révélé qu'**ADR-031 portait deux doctrines incompatibles** selon les
fichiers : « jamais de fix sans validation humaine » (CLAUDE.md, conductor, validator,
vf-decide…) et « vigilance support runtime » (VIBEFLOW_CORE v4.1 §3.2, infrastructure-audit,
templates frontmatter). 325 citations, zéro définition : toute référence était ambiguë.

### Décision

- **ADR-031 ne désigne QUE la validation humaine** : détecter et proposer, jamais corriger /
  supprimer / matérialiser sans feu vert explicite de l'humain.
- **ADR-056 reprend la vigilance support runtime** : avant d'inventer une convention
  (frontmatter, hook, mécanisme de chargement), **vérifier que le runtime Claude Code la
  supporte réellement** — une convention non supportée crée une illusion de structure qui ne
  s'exécute pas. Corollaires : `skills:` en liste plate native (pas de champ deprecated
  `bootstrap_skills`/`on_demand_skills`), croiser toute convention avec la doc officielle,
  re-vérifier après chaque update Claude Code (module infrastructure-audit).

### Conséquences

Les emplois « runtime » d'ADR-031 sont réécrits en ADR-056 dans : VIBEFLOW_CORE.md,
infrastructure-audit (SKILL, README, références), templates lead/CLAUDE/agent_anatomy,
validator. Les CHANGELOG historiques conservent l'ancienne numérotation.

---

## ADR-057 : Frontières avec les briques tierces — détection outillée des recouvrements

**Date** : 2026-07-25
**Statut** : Validée
**Décideur** : Samuel (audit complet 2026-07-25, sections C et G.17)
**Contexte** : branche feat/v3-team-kernel — concurrence de routage avec les briques tierces

### Problème

Des briques VibeFlow/GSD entrent en concurrence de déclenchement avec des briques TIERCES
présentes en session — que VibeFlow ne contrôle pas et ne peut pas dé-publier :

- **3 objets nommés `skill-creator`** (module VibeFlow, skill officiel Anthropic embarqué,
  `superpowers:writing-skills`), avec une revendication « Sole authorized channel for skill
  creation » défendue par rien : aucune machine ne l'applique, les briques tierces ne la lisent pas.
- **`gsd-debug` vs `superpowers:systematic-debugging`** (« Use when encountering ANY bug ») :
  deux candidates au premier geste de dépannage.
- **6 entrées de revue possibles** : `gsd-code-review`, `feature-dev:code-reviewer`,
  `/code-review` natif, `superpowers:requesting-code-review`…
- **Recette mobile** : skill `mobile-test` vs `/vf-test` → `gsd-verify-work` vs équipe
  `mobile-test-team`.

La préséance par prose ne tient pas : rien ne l'exécute, et les descriptions tierces continuent
de matcher au routage sémantique.

### Options Considérées

| Option | Verdict |
|---|---|
| Dé-publier / désinstaller les briques tierces | Rejetée — hors de portée : superpowers, feature-dev et le natif appartiennent à l'utilisateur / à Anthropic |
| Renforcer la prose de préséance (« sole authorized channel », rules) | Rejetée — c'est l'état de départ ; une prose que rien n'exécute ne désambiguïse rien |
| Renommer les briques VibeFlow pour éviter tout mot commun | Rejetée — mutile les descriptions : le routage sémantique a besoin des mots du domaine |
| **Frontière descriptive + détecteur machine** | **Retenue** — même méthode qu'ADR-055 : frontière DÉTECTÉE PAR SCRIPT + doctrine courte |

### Décision

1. **VibeFlow ne revendique jamais l'exclusivité contre une brique tierce.** Il (a) évite le
   recouvrement dans SES PROPRES descriptions (déclencheurs disjoints), (b) documente la
   frontière là où le recouvrement demeure (qui est canon pour quoi), (c) fournit un détecteur
   machine.
2. **`check-overlaps.sh` (conductor)** inventorie les paires de recouvrement CONNUES (table
   interne : brique VibeFlow/GSD ↔ brique tierce ↔ frontière canonique en une ligne) et, pour
   chaque paire dont les DEUX côtés sont présents dans le lab (skills projet/user, agents,
   plugins installés), affiche la frontière. **Advisory par défaut : exit 0 toujours.**
   `--strict` → exit 1 si un recouvrement SANS frontière documentée est détecté (heuristique :
   deux briques locales sur une même racine debug/review/skill-creat) ; cible locale absente en
   `--strict` → exit 3 (INDÉTERMINÉ, F13).
3. **Abandon assumé de la revendication « sole authorized channel »** du skill-creator au profit
   d'une frontière descriptive : le module VibeFlow = **fabrication de capacités de LAB avec
   eval-loop** (recherche par facettes → draft → éval) ; `superpowers:writing-skills` =
   **doctrine d'écriture de skills**. Les deux coexistent.
4. **Frontières canoniques initiales** (table du script) :
   - `systematic-debugging` = méthode dans la session courante ; `gsd-debug` = état persistant
     cross-session (canon dès que le debug survit à un reset de contexte).
   - `gsd-code-review` = canon dans un projet GSD ; `feature-dev:code-reviewer` / `/code-review`
     natif / `requesting-code-review` = revue hors chaîne GSD.
   - `mobile-test` = preuve sur cible mobile réelle (simulateur/émulateur, Maestro) ;
     `gsd-verify-work` = recette conversationnelle ; boucle autonome = équipe `mobile-test-team`.
   - `superpowers:brainstorming` = concevoir une idée avant d'implémenter ; `gsd-explore` =
     exploration socratique et routage d'idée.

### Conséquences

**Positives** : la frontière devient vérifiable (inventaire machine au lieu de 4 tables de prose
à synchroniser) ; la revendication indéfendable du skill-creator disparaît au profit d'une
coexistence assumée ; tout nouveau recouvrement à racine sensible est signalé avant de devenir
une ambiguïté de routage en session. **Négatives / risque** : la table interne est un inventaire
statique — un recouvrement hors racines connues (debug/review/skill-creat) n'est pas détecté par
l'heuristique ; l'advisory ne force rien (choix délibéré : VibeFlow ne bloque pas une session à
cause d'une brique qu'il ne contrôle pas). Mitigation : enrichir la table au fil des audits.

### Code Impacté

- `plugin/conductor/scripts/check-overlaps.sh` (nouveau) +
  `plugin/conductor/scripts/tests/test-check-overlaps.sh` (nouveau)
- `plugin/skill-creator/AGENT.md` + `plugin/skill-creator/README.md` (abandon « sole authorized
  channel » → frontière descriptive)
- `plugin/mobile-test/SKILL.md` (frontière dans la description)

### Rules Associées

- Applique la méthode ADR-055 (frontière détectée par script + doctrine courte, pas de prose de
  préséance) au périmètre des briques tierces. Respecte F13 (vacuous green) : `--strict` sur
  cible vide sort 3, jamais un vert. Aucune rule nouvelle.

---

## ADR-058 : Le moteur GSD entre dans le périmètre de `/vf-update`

**Date** : 2026-07-28
**Statut** : Validée
**Décideur** : Samuel (audit externe migration OpenGSD, 2026-07-28)
**Contexte** : Phase 19 — migration du moteur GSD pilotée par `/vf-update`

### Problème

La version du moteur GSD n'est pas une donnée subie, c'est une décision de VibeFlow — le plafond
de version est posé dans `ensure-deps.sh:166` (`@opengsd/gsd-core@^1`) et a été arbitré après
l'audit de la Phase 11. Or le §Garde-fous du skill de mise à jour plaçait explicitement la chaîne
d'outils interne hors périmètre, au motif qu'elle avait sa propre mise à jour. Conséquence mesurée
sur un poste audité le 2026-07-28 : plugin à jour, moteur resté sur le paquet déprécié
`get-shit-done-cc` posé douze jours plus tôt, et rien dans l'interface ne le disait. Une frontière
de périmètre exacte dans sa formulation et trompeuse dans son effet.

### Options Considérées

| Option | Verdict |
|---|---|
| Laisser le moteur hors périmètre, compter sur `/vf-init` ou `/vf-calibrate` | Rejetée — ce sont des chemins que le régime nominal n'emprunte jamais, c'est précisément le motif du trou |
| Ajouter un hook `SessionStart` sur l'état du moteur | Rejetée — décision de l'utilisateur, une ligne de plus à chaque session pour un fait qui change une fois |
| Migrer automatiquement dès détection | Rejetée — ADR-031 : une install tierce sur le poste de l'utilisateur ne se fait jamais sans accord explicite |
| **Détecter et proposer dans le récapitulatif de `/vf-update`, sous confirmation** | **Retenue** — le régime nominal voit enfin l'état du moteur, sans jamais l'imposer |

### Décision

1. **L'état du moteur GSD est une donnée du diagnostic de `/vf-update`**, au même titre que la
   version du plugin et celle des modules — il n'est plus une chose qu'on découvre par hasard via
   `/vf-init` ou `/vf-calibrate`.
2. **Il est détecté par un gate dédié en lecture seule** (`check-gsd-engine.sh`), dont le
   classement se fait sur le layout et le nom du paquet installé, et **jamais** sur la comparaison
   des numéros de version — un poste legacy figé à `1.42.3` reste actionnable même face à un
   `@opengsd/gsd-core` à `1.8.0`, malgré `1.8.0 < 1.42.3` en semver.
3. **La migration est proposée comme une ligne indépendante** de la confirmation existante de
   `/vf-update` et **n'est jamais exécutée sans accord explicite** de l'utilisateur (ADR-031) — un
   refus n'a aucun effet de bord et n'est jamais relancé.
4. **La détection traverse la frontière de modules par une sonde de présence de fichier**, jamais
   par une dépendance déclarée dans `module.json`, parce que le module qui porte le skill
   (`conductor`) est mandatory et que celui qui porte le moteur (`dev-orchestrator`) ne l'est pas.
5. **Le nettoyage des artefacts legacy est proposé, jamais exécuté** — même doctrine que la
   migration elle-même.
6. **Superpowers reste hors périmètre** : cette décision ne couvre que le moteur GSD.

### Conséquences

**Positives** : le chemin de mise à jour nominal voit enfin l'état du moteur et un poste équipé
cesse de porter le code d'une migration sans en porter l'effet ; le nettoyage devient atteignable
(via `/vf-update`, plus seulement via `/vf-init`/`/vf-calibrate`) et exact.

**Négatives / risque** : `/vf-update` acquiert une dépendance de fait envers un script d'un module
non mandatory, tenue par une sonde best-effort — si la matérialisation à plat des scripts changeait
un jour (nouveau layout d'install), la sonde deviendrait silencieusement aveugle sans qu'aucun gate
ne le signale. Le classement par layout doit rester insensible aux numéros de version dans tout
code futur qui y touche, faute de quoi le piège semver documenté en D-05 se rouvre sans signal.

### Code Impacté

- `plugin/dev-orchestrator/scripts/check-gsd-engine.sh` (gate de détection à 3 états, 19-01)
- `plugin/dev-orchestrator/scripts/ensure-deps.sh` (chemin `--migrate-engine`, 19-02)
- `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` (mode `--verify`, 19-02)
- `plugin/conductor/skills/vf-update/SKILL.md` (diagnostic à deux volets, §Garde-fous, 19-03)

### Rules Associées

- S'appuie sur ADR-031 (jamais d'action sans validation humaine) pour borner la proposition de
  migration à une confirmation explicite, jamais automatique. Applique la méthode d'ADR-055 §3 (le
  script constate le fait, l'agent juge et propose) au périmètre du moteur GSD. Aucune rule
  nouvelle.

## ADR-059 : Une mission d'équipe travaille sur sa propre branche, jamais sur la branche par défaut

**Date** : 2026-07-28
**Statut** : Validée
**Décideur** : Samuel (constat du 2026-07-28 — 32 commits de mission autonome atterris sur `main`)
**Contexte** : release v2.43.0 — dev-orchestrator, design-orchestrator

### Problème

Une mission d'équipe (`vf-dev-manager`, `vf-design-manager`) produit **des dizaines de commits sans
supervision**. Rien, dans le contrat de brief ni dans les garanties des managers, ne disait sur
quelle branche. Le comportement de fait était donc « celle où la session se trouve » — en pratique
la branche par défaut.

Constaté le 2026-07-28 sur ce dépôt : la mission Phase 19 a produit **32 commits directement sur
`main`**, poussés, puis taggés. Aucun dégât — la mission était bonne — mais le recours en cas de
mission ratée était un `revert` en masse d'un historique déjà public, potentiellement déjà consommé
par d'autres clones. Le rapport de fin de mission ne remplace pas un point de relecture groupée : il
est rédigé **par** l'agent qui a fait le travail, et il est déjà trop tard quand on le lit.

Le même dépôt impose pourtant une discipline stricte en aval (« toute VERSION = un tag », gates de
synchro, release GitHub). L'amont — comment le travail arrive sur la branche par défaut — n'était pas
gouverné du tout.

### Options Considérées

| Option | Pour | Contre |
|---|---|---|
| Statu quo (mission sur la branche courante) | zéro friction | pas de point d'annulation, pas de relecture groupée, historique public d'office |
| **Branche + PR pour toute mission d'équipe (retenue)** | annulation = ne pas merger ; relecture groupée ; le merge reste humain (ADR-031) | une branche à gérer par mission ; inopérant sans remote → exige des replis |
| Branche pour tout travail de phase | plus uniforme | un `docs(NN)` d'ouverture de phase deviendrait une PR |
| Branche pour toute modification de code | flux GitHub classique | alourdit chaque correctif d'une ligne et chaque mise à jour de `STATE.md` |

### Décision

**Toute mission d'équipe crée sa branche AVANT son premier commit, y tient tous ses commits, et
termine par une PR laissée ouverte. Le manager ne merge jamais.** Le merge appartient à l'utilisateur
(ADR-031 : jamais d'action irréversible sans validation humaine).

Le déclencheur est le **dispatch d'un manager**, pas la nature du travail : le travail conversationnel
direct (correctif, doc, cadrage mené dans le fil) reste hors de la règle — sinon chaque échange
créerait une branche.

**Une mission n'échoue jamais faute de pouvoir appliquer cette règle.** Quatre replis dégradés, du
plus complet au plus pauvre : pas de dépôt git → aucune branche, signalé ; pas de remote → branche
sans PR ; pas de `gh` → branche poussée, URL de création de PR donnée ; arbre sale au démarrage →
**halt condition**, remontée à l'utilisateur, jamais un `stash` décidé seul. Et le `CLAUDE.md` du
projet cible **prime** s'il impose un autre flux — cohérent avec le contrat de brief, où les
conventions de livraison du projet font déjà foi.

### Conséquences

**Positives** : le recours après une mission ratée devient « ne pas merger » au lieu d'un revert en
masse. La PR fournit le point de relecture groupée que le rapport de mission ne remplace pas. La
branche par défaut cesse de recevoir du travail non supervisé.

**Négatives / risque** : une branche de plus à gérer par mission, et un merge qui peut traîner —
une mission livrée mais non mergée est un travail invisible pour la suivante, qui repartira de la
branche par défaut sans le voir. Le manager doit donc citer l'URL de la PR dans son rapport, et
l'utilisateur reste seul responsable du merge. Sur un lab sans remote, la règle se dégrade en simple
isolation locale — utile, mais sans relecture.

**Ne couvre pas** : l'isolation des vagues parallèles **à l'intérieur** d'une mission, qui partagent
le même arbre de travail. Une branche par mission ne les sépare pas entre elles ; seul
`isolation: worktree` le ferait. Décision distincte, non tranchée ici — signalée par
`vf-dev-manager` lors de la mission Phase 19 et volontairement laissée ouverte.

### Code Impacté

- `plugin/dev-orchestrator/references/mission-contracts.md` — nouvelle section §Isolation de branche
  (protocole en 3 temps, conventions de nom, table des 5 replis).
- `plugin/dev-orchestrator/agents/vf-dev-manager.md` §Garanties — règle câblée, renvoi au contrat.
- `plugin/design-orchestrator/agents/vf-design-manager.md` §Garanties — idem.

### Rules Associées

Applique ADR-031 (jamais d'action irréversible sans validation humaine) au **merge** : le manager
peut tout produire, il ne peut rien intégrer. Complète la discipline de release du `CLAUDE.md`
racine, qui gouvernait l'aval (tag, release) sans rien dire de l'amont. Aucune rule nouvelle.

## ADR-060 : La revue devient un étage de premier rang, piloté par le manager

**Date** : 2026-07-29
**Statut** : Validée
**Décideur** : Samuel (arbitrage de cadrage D-26, `20-CONTEXT.md`), acté par l'exécution du plan 20-06
**Contexte** : Phase VFDO-20 (fluidité du flux de dev) — `dev-orchestrator` v2.8.0 ; release racine
hors périmètre de cette phase, réservée à une validation humaine post-fusion

### Problème

La revue était le **seul** étage à la fois obligatoire — en dur dans le cycle interne du worker
d'exécution (`vf-coder.md:34`) — et **hors de portée du manager**, une règle lui interdisant
explicitement d'en ajouter une (`vf-dev-manager.md:108`, « Pas de double revue »). La seule gradation
existante était indexée sur le **volume** d'étapes restantes (`SEUIL_EQUIPE`), ce qui est le mauvais
axe : trois lignes sur un chemin partagé sont minuscules et à très haut risque, quatre cents lignes de
domaine pur prouvées par mutation sont grosses et à bas risque. Et le meilleur rendement de toute la
tranche auditée venait des jointures entre lots parallèles — un étage qui n'existait que parce qu'il
avait été créé à la main.

### Options Considérées

| Option | Avantages | Inconvénients |
|---|---|---|
| Statu quo (revue en dur dans `vf-coder`, gradation sur le volume `SEUIL_EQUIPE`) | zéro changement | le manager n'a explicitement pas le droit d'en ajouter une ; le volume ne corrèle pas avec le risque réel ; aucune revue de jointure entre lots parallèles hors geste manuel |
| Gradation indexée sur le volume de lignes changées | simple à calculer | mauvais axe — écartée explicitement, cf. Problème |
| Allègement d'un différentiel de comblement | réduirait le coût d'un `reopen` | affaiblirait le seul garde-fou qui empêche un comblement de passer en revue allégée |
| **Nœud de plan de bataille posé systématiquement par le manager, dispatché en direct, gradué par 4 déclencheurs objectifs, jointure sur topologie (retenue)** | la revue devient pilotable, graduée sur le bon axe, jointure garantie machine | un nœud de dispatch de plus par étape — coût réel |

### Décision

La revue devient un nœud `revue-N` de plan de bataille posé **systématiquement** par le manager et
**dispatché en direct** — `vf-coder` ne la dispatche plus. La boucle de correction migre vers le
manager sous forme de mandat de correction ciblée. La gradation s'appuie sur **quatre déclencheurs
objectifs** (jamais le volume) avec défaut sûr (« dans le doute, revue pleine »). Une **revue de
jointure** (`join-N`) est déclenchée par la **topologie du graphe**, jamais par l'intersection des
périmètres. Le garde-fou de comblement est adossé au champ machine `review_regime` que `dag.sh
reopen` écrit lui-même (D-14, plan 20-02) — jamais une consigne de prompt. Protocole complet :
`dev-orchestrator-references/mission-flow.md` §Pattern E, non dupliqué ici.

### Conséquences

**Positives** : un nœud pilotable au lieu d'une sous-phase interne invisible au manager ; la
gradation a enfin un axe où s'appliquer (risque, pas volume) ; la jointure cesse d'être un geste
manuel — elle est garantie par construction du DAG.
**Négatives** : un nœud de dispatch de plus par étape, donc un coût de dispatch réel.
**Explicitement écarté** : l'indexation de la gradation sur le volume d'étapes restantes, et tout
allègement d'un différentiel de comblement.

### Code Impacté

- `plugin/dev-orchestrator/references/mission-flow.md` — §Pattern E (protocole complet de l'étage
  revue de premier rang)
- `plugin/dev-orchestrator/agents/vf-dev-manager.md` — règle `vf-dev-manager.md:108` réécrite en
  place, pilotage direct de `revue-N`/`join-N`
- `plugin/dev-orchestrator/agents/vf-coder.md` — cycle réduit à 3 étapes, ne dispatche plus
  `vf-reviewer`
- `plugin/dev-orchestrator/agents/vf-reviewer.md` — dispatché uniquement en direct par un manager
- `plugin/conductor/scripts/dag.sh` — `review_regime` écrit par `reopen` (D-14) : le mécanisme
  machine du garde-fou de comblement

### Rules Associées

Remplace en place la règle `vf-dev-manager.md:108` (« Pas de double revue »), pas de contournement
par exception. Le rapport typé (Pattern C, ADR-053) reste le socle inchangé du retour de `revue-N`.
Aucune rule nouvelle.

## ADR-061 : Les lanes de revue cross-AI de plans (amont) et l'étage de revue de code (ADR-060) sont des objets disjoints

**Date** : 2026-07-31
**Statut** : Validée
**Décideur** : Samuel (arbitrage de cadrage, mission delta `@opengsd/gsd-core` 1.8.0 → 1.9.0, Phase
VFDO-21 plan 21-02)
**Contexte** : `gsd-core` 1.9.0 déclare `review-lane-descriptor.cjs` (ADR-2782 Phase 1 amont,
#2794, clôt #2690) — le contrat des reviewers cross-AI (`gemini`, `codex`, `coderabbit`, etc.) qui
relisent un **plan** avant exécution, invoqués par le skill `gsd-review`. VibeFlow venait, une
mission plus tôt (Phase 20, `dev-orchestrator` v2.8.0), de poser ADR-060 : la revue de **code**
devient un nœud `revue-N` de premier rang, posé systématiquement par `vf-dev-manager` et relu par
`vf-reviewer` → `gsd-code-reviewer`. Les deux mécanismes partagent le mot « revue » — rien
n'établissait noir sur blanc s'ils se recouvraient.

### Problème

Sans arbitrage écrit, la question « est-ce qu'on double la revue » resterait ouverte à chaque
lecture du delta 1.9.0, avec le risque qu'une phase future la tranche par supposition plutôt que
par constat — ou pire, fusionne deux objets qui ne se comparent pas terme à terme.

### Options Considérées

| Option | Avantages | Inconvénients |
|---|---|---|
| Statu quo silencieux (ne rien écrire) | coût nul dans l'immédiat | la question est précisément ce que la mission demande de fermer — la laisser ouverte la fait ressurgir |
| Fusionner les deux étages en un seul nœud de revue | un seul concept apparent | confond un TEXTE DE PLAN pré-exécution et un DIFF DE CODE post-exécution ; l'amont n'a livré que la couche déclarative (Phase 1/6 de son propre plan) — `invoke_reviewers` reste écrit à la main jusqu'à sa Phase 5b (#2799), rien de stable à intégrer |
| **Documenter la disjonction sur un critère explicite à 3 axes, sans câbler `gsd-review` dans le cycle automatique de l'équipe (retenue)** | ferme la question durablement, coût nul, aucune sur-ingénierie sur une brique amont encore mouvante | aucun — rend explicite un état déjà vrai en pratique |

### Décision

Les deux mécanismes restent des étages **disjoints**, distingués sur trois axes factuels :

1. **Objet revu** — ADR-060/`vf-reviewer` relit un **diff de code déjà exécuté et commité** ;
   `gsd-review`/les lanes cross-AI relisent le **texte d'un `PLAN.md`**, avant toute exécution.
2. **Moment du cycle** — ADR-060 intervient APRÈS `execute-N` (nœud `revue-N`, `deps=exec-N`,
   `mission-flow.md` §Pattern E) ; `gsd-review` intervient AVANT `execute-N`, en option de
   `gsd-plan-phase` (flag `--reviews` consommé par `gsd-planner`).
3. **Qui déclenche et qui relit** — ADR-060 est posé **systématiquement** par `vf-dev-manager`,
   sans condition, et relu par `vf-reviewer` → `gsd-code-reviewer` (Claude, la stack interne) ;
   `gsd-review` est un geste **opt-in** déclenché par un utilisateur/opérateur, relu par des CLIs
   IA tierces (gemini, codex, coderabbit…) — **jamais** déclenché automatiquement par
   `vf-coder`/`vf-dev-manager` aujourd'hui (vérifié : ni `gsd-plan-phase` tel qu'invoqué par
   `vf-coder`, ni aucun nœud du DAG de mission, ne passent `--reviews`).

**Aucune fusion.** `gsd-review` reste hors du cycle automatique de l'équipe VibeFlow : cette
décision ne pose aucun nœud DAG `plan-review-N` — sur-ingénierie évitée tant que l'exécution des
lanes amont (`invoke_reviewers`) reste écrite à la main. Si VibeFlow veut un jour orchestrer ce
review cross-AI automatiquement, c'est une décision distincte, non tranchée ici.

**Extension (Phase 23, plan 23-06, 2026-08-04)** — un **troisième objet** revu rejoint la
disjonction, sur les **mêmes 3 axes**, pour fermer la Lacune 1 (doublons d'étage non arbitrés) : le
workflow d'exécution du moteur rend à lui seul le point de hook de post-exécution ET celui de
post-vérification, donc un seul appel de `gsd-execute-phase` déclenche revue de code, nyquist et
audit de sécurité — un fait qui aggrave le silence si l'arbitrage n'est écrit nulle part.

**Couple 1 (D-13, plan 23-06)** — hook de revue de code du moteur (`gsd-code-reviewer`, inséré par
`gsd-execute-phase`) *versus* nœud `revue-N` du manager (`vf-reviewer`, ADR-060) :

- **Objet revu** — le hook relit le diff **d'un plan**, au moment où ce plan se ferme ; le nœud
  relit le diff de **jointure** d'une étape — l'intégration entre plans et la cohérence avec
  l'existant.
- **Moment du cycle** — le hook tombe sur le point de post-exécution, à l'intérieur du skill ; le
  nœud tombe après le nœud d'exécution, au grain étape.
- **Qui déclenche et qui relit** — le hook est inséré par le moteur selon un toggle ; le nœud est
  posé systématiquement par le manager, sans condition.

Conclusion : **les deux restent**, et le coût devient **assumé et nommé** au lieu d'être une
superposition subie. **Option écartée** : éteindre le toggle de revue du moteur pour « éviter le
doublon » — ferait perdre sa revue à tout appel direct du skill d'exécution par l'utilisateur, hors
mission.

**Couple 2 (D-14, plan 23-06)** — hook d'audit de sécurité du moteur *versus* auditeur VibeFlow
(`vf-auditer`). Le delta est un **FAIT**, pas une préférence, sur les mêmes 3 axes :

- **Objet revu** — le hook vérifie les mitigations du **threat model du plan** ; l'auditeur y
  ajoute le **recoupement avec la dette connue du projet** (`.planning/codebase/CONCERNS.md`), un
  delta que le hook **ne peut pas** produire, parce qu'il ne lit pas ce fichier.
- **Moment du cycle** — les deux tombent en vérification, après `exec-N`, en parallèle de la revue
  (`mission-flow.md` §Pattern E, point 3).
- **Qui déclenche et qui relit** — le hook est inséré par le moteur selon un toggle ; l'auditeur
  (`vf-auditer`) est dispatché par le manager quand l'étape touche sécurité, données sensibles ou
  infra.

**Option écartée** : conditionner l'auditeur au verdict du hook — ferait perdre le recoupement
exactement dans le cas où le hook ne voit rien, or c'est là que la dette connue sert le plus.

### Conséquences

**Positives** : la question ne peut plus être redécouverte — le critère est écrit et vérifiable sur
ses 3 axes. Aucun changement de comportement : ADR-060 continue tel quel, `gsd-review` reste
invocable manuellement par qui veut un second avis cross-AI sur un plan.
**Négatives** : aucune — décision purement documentaire.
**Explicitement écarté** : fusion des deux étages ; câblage automatique de `gsd-review` dans le DAG
de mission.

### Code Impacté

- `docs/ADR.md` (cette entrée)
- `plugin/dev-orchestrator/references/mission-contracts.md` — pointeur bref vers cette ADR
  (§Étage revue — deux objets disjoints), et §Contrat de checkpoint amont pour le champ
  `verdicts` qui rend le coût des deux couples lisible (Phase 23, plan 23-06)
- `plugin/dev-orchestrator/references/mission-flow.md` — §Pattern E (étage revue de premier rang),
  qui documente le comportement réel du nœud `revue-N` distingué au Couple 1 (Phase 23, plan 23-06)

### Rules Associées

Ne modifie ni ADR-060 ni ADR-053 (Pattern E) — clarifie une frontière déjà vraie en pratique,
jamais écrite. Aucune rule nouvelle.

## ADR-062 : Les deux hooks 1.9.0 non câblés (`gsd-ensure-canonical-path.js`, `gsd-update-banner.js`) restent hors périmètre de `merge-hooks.sh`

**Date** : 2026-07-31
**Statut** : Validée
**Décideur** : Samuel (arbitrage de cadrage, mission delta `@opengsd/gsd-core` 1.8.0 → 1.9.0, Phase
VFDO-21 plan 21-03)
**Contexte** : `gsd-core` 1.9.0 pose deux hooks `SessionStart` absents du `settings.json` du poste
courant, qui câble déjà 13 autres hooks `gsd-*` : `gsd-ensure-canonical-path.js` (#997) et
`gsd-update-banner.js` (#2795). Le diagnostic de mission (`.planning/missions/2026-07-31-delta-gsd-core-1.9.0.md`
§Observation annexe) constate le fait sans trancher : « rien n'est cassé, mais une fonctionnalité
amont est peut-être inactive faute de câblage » — à instruire explicitement plutôt que par
omission, sujet que `merge-hooks.sh` (`plugin/_internal/merge-hooks.sh:145-150`) documente déjà
vouloir laisser aux « hooks tiers/gsd-core » sans jamais les avoir confrontés au cas réel.

### Problème

Sans arbitrage écrit, l'absence de ces deux hooks resterait ambiguë à chaque lecture future du
delta : gap VibeFlow à combler, ou comportement gsd-core correct qu'il ne faut surtout pas casser
en le câblant à la main ? Les deux hooks n'ont pas la même nature et ne peuvent pas être tranchés
par une règle unique — chacun est confronté séparément à l'état réel du poste.

### Options Considérées

| Option | Avantages | Inconvénients |
|---|---|---|
| Statu quo silencieux (ne rien écrire) | coût nul | la question du diagnostic reste ouverte — refera surface à chaque delta gsd-core |
| Étendre `merge-hooks.sh` pour câbler les deux hooks dans tout `settings.json` cible | « complet » en apparence | câblerait `gsd-update-banner.js` alors que son propre en-tête dit qu'il doit rester **éteint** quand la statusline GSD est installée (notre cas) — régression, pas un gain ; et `gsd-ensure-canonical-path.js` répare un problème d'install que VibeFlow ne produit pas (voir Décision) |
| **Vérifier séparément chaque hook contre son propre contrat d'activation puis documenter (retenue)** | ferme la question avec preuves, ne câble rien qui casserait un comportement déjà correct | aucun — rend explicite un état déjà correct en pratique |

### Décision

**Aucun câblage n'est ajouté à `merge-hooks.sh`.** Les deux hooks sont restés hors `settings.json`
pour des raisons distinctes, vérifiées séparément sur pièce :

1. **`gsd-update-banner.js` — absence correcte, pas un gap.** Son propre en-tête (`~/.claude/hooks/gsd-update-banner.js:6-9`)
   documente que ce hook n'est enregistré par l'installeur amont QUE si l'utilisateur a décliné (ou
   remplacé) la statusline GSD — « the presence of the SessionStart entry IS the opt-in ». Le
   `settings.json` du poste courant câble déjà `gsd-statusline.js` (bloc `statusLine`) : la
   statusline EST installée, donc la non-registration du banner est exactement le comportement
   voulu par gsd-core lui-même. Le câbler à la main romprait ce contrat amont (double signal de
   mise à jour disponible : statusline + banner).
2. **`gsd-ensure-canonical-path.js` — hors cas d'usage de VibeFlow.** Son propre en-tête
   (`~/.claude/hooks/gsd-ensure-canonical-path.js:4-14`) documente qu'il répare un problème
   d'installation précis : quand `gsd-core` lui-même est posé comme **plugin marketplace Claude
   Code** (`CLAUDE_PLUGIN_ROOT` présent), l'installeur classique ne s'exécute jamais et
   `~/.claude/gsd-core/` n'est jamais matérialisé, cassant les `@`-includes des agents/workflows.
   Ce n'est PAS le chemin d'install de VibeFlow : `ensure-deps.sh:263` bootstrappe `gsd-core` via
   `npx -y "@opengsd/gsd-core@^1" --claude <scope>` — l'installeur npm classique que le hook lui-même
   cite comme cas qui N'A PAS besoin de sa correction (« In a classic `bin/install.js` install the
   canonical path is a real directory holding the bundled tree, so the includes resolve »). Vérifié
   sur le poste courant : `~/.claude/gsd-core/` existe bien comme répertoire réel, pas un lien
   symbolique de secours posé par ce hook.
3. **`merge-hooks.sh` reste inchangé** : son commentaire existant (`:145-150`, « hooks
   tiers/gsd-core ») documentait déjà l'intention de ne pas s'en mêler — cette ADR confirme cette
   intention avec preuves plutôt que de la modifier. Aucune ligne de code n'est ajoutée ou retirée
   du script.

### Conséquences

**Positives** : la question du diagnostic de mission est fermée avec preuves, sans risquer de
casser un comportement amont déjà correct (le banner en double aurait été un vrai régression
utilisateur). Aucun changement de comportement.
**Négatives** : aucune — décision purement documentaire, aucun code touché.
**Explicitement écarté** : étendre `merge-hooks.sh` pour ces deux hooks ; forcer leur câblage dans
`settings.json`.
**Limite assumée** : cette décision est vérifiée sur **ce poste** (statusline installée, install
npm classique). Si un lab VibeFlow installait un jour `gsd-core` via un plugin Claude Code
marketplace, ou déclinait la statusline GSD, la conclusion du point 1/2 changerait — l'ADR ne
prétend pas couvrir ce cas hypothétique, seulement l'état vérifié aujourd'hui.

### Code Impacté

- `docs/ADR.md` (cette entrée)
- `plugin/dev-orchestrator/README.md` — pointeur bref dans la section hooks/scripts du module
  (§Structure du module)

### Rules Associées

Ne modifie ni `merge-hooks.sh` ni son commentaire existant — confirme avec preuves une intention
déjà écrite (`plugin/_internal/merge-hooks.sh:145-150`). Aucune rule nouvelle.

## ADR-063 : Anomalie d'agrégation `.planning/STATE.md` — dette d'artefact locale + bug amont non scopé, gate local, jamais de correction par `gsd-tools state`

**Date** : 2026-07-31
**Statut** : Validée
**Décideur** : Samuel (arbitrage de cadrage, mission delta `@opengsd/gsd-core` 1.8.0 → 1.9.0, Phase
VFDO-21 plan 21-04)
**Contexte** : la clôture de la Phase 20 (20-07) a constaté que `.planning/STATE.md` avait vu son
frontmatter **régresser** silencieusement — `completed_phases` 11→10, `total_plans` 53→49,
`completed_plans` 37→29, `current_phase` resté à 19 — alors que la Phase 20 venait précisément de
se terminer. `.planning/STATE.md:16-20` a recalé les compteurs à la main et inscrit un commentaire
renvoyant l'instruction à la Phase 21. Diagnostic établi sur pièce sur `@opengsd/gsd-core` 1.9.0
(`~/.claude/gsd-core/bin/lib/state.cjs`, `bin/lib/plan-scan.cjs`, `bin/lib/state-document.cjs`) —
aucune supposition, chaque affirmation ci-dessous cite une ligne réelle.

### Problème

Sans arbitrage écrit, chaque nouvelle régression de compteur redéclencherait le même cycle : un
recalage manuel, un commentaire d'intention, et l'anomalie ressurgirait à la prochaine écriture
d'état — exactement le motif « garde-fou documenté mais jamais machine-enforced » déjà rencontré
trois fois sur ce repo (Phase 13, 17, 19). Sans distinguer les deux causes, la remédiation risquait
soit de sur-corriger un défaut d'artefact local en le traitant comme un bug à contourner par du
code, soit de sous-réagir à un vrai bug amont en l'absorbant silencieusement dans un recalage
manuel répété à chaque phase.

### Diagnostic — deux causes distinctes, jamais confondues

**Cause A — dette d'artefact locale, pas un bug.** `state.cjs:1494-1501` + `plan-scan.cjs:158` :
une phase n'est « complète » que si **chaque** `NN-MM-PLAN.md` a son `NN-MM-SUMMARY.md` partenaire
sur le disque — sans repli sur le ROADMAP, alors que `roadmap analyze` (`roadmap.cjs:353-355`)
**a** ce repli (« trust roadmap over disk »). Deux définitions de « complète » coexistent dans le
même moteur. Sur ce repo, les Phases 11, 12, 13, 14 sont shippées et publiées mais n'ont jamais eu
de `SUMMARY.md` (missions d'équipe ou artefacts nommés différemment — Phase 10 : `10-ETUDE.md` /
`10-SOLUTIONS.md` / `10-APPROFONDISSEMENT.md`, Phase 15/16 : listes de checkboxes dans
`ROADMAP.md` sans fichier `PLAN.md` par plan) ; la Phase 1 est en plus filtrée hors du calcul car
enfermée dans un bloc `<details>` de jalon archivé. **Le comportement de `buildStateFrontmatter`
est cohérent avec sa propre règle** — c'est nos artefacts qui ne la satisfont pas.

**Cause B — vrai bug amont, notre fichier est conforme.** `state.cjs:1390-1391` appelle
`stateExtractField(bodyContent, 'Phase')`, qui (`state-document.cjs:214`) prend le **premier**
`^Phase:` du **corps entier**, sans aucun scope. Le corps de `STATE.md` empile un historique de
sections archivées, chacune commençant par `Phase: N …` — la même ancre `^Phase:` pour l'archive
et pour l'actif. Asymétrie décisive : la **même fonction** scope explicitement `Stopped At` et
`Paused At` à la section `## Session` (`state.cjs:1402-1413`), mais **jamais** `Phase`. Notre
fichier respectait le format documenté ; c'est l'extracteur qui n'a pas de scope.

**Déclencheur, commun aux deux causes.** `gsd-tools state record-session` — appelé par
`workflows/discuss-phase.md:480`, `execute-plan.md:443`, `milestone-summary.md:221`,
`ui-phase.md:462`, et d'autres workflows du cycle normal — écrit le frontmatter via
`cmdStateRecordSession` (`state.cjs:915`), qui appelle `readModifyWriteStateMd` **sans `options`** ;
`state.cjs:2024` calcule `resync = !options || options.resync !== false` → **`resync: true` figé,
non désactivable** depuis cette voie d'appel. Ce n'est pas un hook isolé : c'est le chemin
d'écriture normal de chaque cadrage/exécution/clôture de phase. Motif déjà rencontré : 3
régressions sur ce repo, 2 déjà réparées à la main (`63aca55`, `ef8826c`) avant celle-ci.

### Options Considérées

| Option | Avantages | Inconvénients |
|---|---|---|
| Patcher `@opengsd/gsd-core` en local (`~/.claude/gsd-core/**`) | corrigerait les deux causes à la source | interdit par la doctrine du repo (paquet tiers en lecture seule, `~/.claude/gsd-core` régénéré à chaque update — la Phase 21 elle-même documente cette règle en 21-01/21-03) ; corrigerait un fichier qui n'appartient pas à ce repo |
| Backfiller les ~20 `SUMMARY.md` manquants des Phases 11/12/13/14 | rendrait la Cause A auto-cohérente avec le moteur amont, sans aucun gate à écrire | lourd (reconstruction rétroactive de 4 phases shippées il y a des semaines), déborde le périmètre confié à cette mission — **remonté en décision à trancher par Samuel, non tranché ici** (cf. Conséquences) |
| Absorber silencieusement chaque régression par un recalage manuel répété | coût immédiat nul | c'est précisément le motif qui a produit l'incident du 2026-07-31 — un recalage sans gate ne survit pas à la prochaine écriture d'état, et personne ne le détecte avant la prochaine relecture humaine |
| **Gate machine local + interdiction documentée de "réparer" `STATE.md` via `gsd-tools state` + signalement amont à déposer (retenue)** | ferme la classe d'incident sans toucher au paquet tiers ; rend visible la prochaine régression au lieu de la laisser dormir jusqu'à la prochaine lecture humaine | ne corrige pas la cause amont — nécessite un geste humain (dépôt de l'issue/RFC) hors du contrôle de VibeFlow, délai indéterminé |

### Décision

**Aucun patch du paquet tiers.** `~/.claude/gsd-core/**` reste lecture seule, sans exception —
cohérent avec la doctrine déjà posée en Phase 21 (21-01/21-03, purge de la dette de version) et
avec le principe déjà appliqué en ADR-062 (« confirmer avec preuves plutôt que modifier un
comportement amont »).

**Le gate `check-state-integrity.sh`** (`plugin/conductor/scripts/`, module `conductor` v1.18.0)
rend la classe d'incident bruyante des deux côtés : régression de compteur au sein d'un même jalon
(Cause A, tant que le backfill n'est pas tranché) et plus d'une ligne `^Phase:` dans le corps
(Cause B, tant que l'amont n'a pas scopé son extracteur). Deux invariants dans le même script parce
qu'ils protègent le même fichier contre le même défaut de fond — voir son en-tête pour le détail du
contrat.

**Convention d'écriture posée pour ce repo (couvre Cause B en attendant l'amont)** : le corps de
`.planning/STATE.md` ne contient **jamais** plus d'une ligne commençant par `Phase:`. Toute section
narrant une phase **archivée** (non courante) doit utiliser une forme qui ne matche pas l'ancre
`^Phase:` — retenue : **`**Phase archivée :** N …`** (gras, deux-points après le mot « archivée »,
jamais en toute première position de ligne sous la forme `Phase:`). Appliquée rétroactivement aux 4
sections archivées de `.planning/STATE.md` dans ce même plan (21-04) et gardée par le gate
ci-dessus.

**Interdiction documentée : ne jamais invoquer `gsd-tools state <verbe>` pour « réparer »
`.planning/STATE.md`.** Toute invocation de `gsd-tools state record-session` (directe, ou via un
workflow qui l'appelle) force `resync: true` de façon non désactivable (`state.cjs:2024`) — un
agent qui tenterait de corriger un frontmatter erroné en relançant cette commande **régénérerait
la régression qu'il essaie de corriger**, en appliquant à nouveau la Cause A sur l'état courant.
La seule correction sûre d'un frontmatter erroné est l'édition manuelle directe du fichier (comme
ce plan le fait), jamais un appel outillé qui repasse par l'agrégateur défaillant. Cette règle est
propagée dans `plugin/dev-orchestrator/references/mission-contracts.md` (pointeur court, section
dédiée) — c'est la référence que `vf-coder`/`vf-dev-manager` consultent pour les conventions de
mission, l'endroit où un agent la lira avant d'être tenté de « juste relancer la commande ».

**Signalement amont — deux points, à déposer sur `open-gsd/gsd-core` (action humaine, hors
contrôle de VibeFlow, même patron que la RFC de la Phase 18)** :

1. **`stateExtractField(bodyContent, 'Phase')` n'est pas scopée** (`state-document.cjs:214`) —
   prend le premier `^Phase:` du corps entier, alors que la même fonction scope explicitement
   `Stopped At`/`Paused At` à la section `## Session` (`state.cjs:1402-1413`). Un `STATE.md` qui
   accumule un historique de phases archivées (motif courant sur un projet long) casse
   silencieusement `current_phase` dérivé du corps.
2. **`buildStateFrontmatter()` n'a pas le repli ROADMAP que `roadmap analyze` a** (`state.cjs:1494-
   1501` vs `roadmap.cjs:353-355`) — deux définitions de « phase complète » dans le même paquet,
   l'une tolérante aux artefacts manquants, l'autre non. Un projet qui a shippé des phases sans
   `SUMMARY.md` (missions d'équipe, cadrage allégé) voit ses compteurs régresser à chaque écriture
   d'état, sans qu'aucun signal ne le prévienne.

**Déposés le 2026-08-01**, sur accord de Samuel : point 1 → [open-gsd/gsd-core#2956](https://github.com/open-gsd/gsd-core/issues/2956),
point 2 → [#2957](https://github.com/open-gsd/gsd-core/issues/2957), croisées l'une vers l'autre.

La recherche préalable a affiné le point 1 : le défaut a une **lignée établie** en amont —
[#2444](https://github.com/open-gsd/gsd-core/issues/2444) a scopé `Stopped At`,
[#2567](https://github.com/open-gsd/gsd-core/issues/2567) a signalé que les champs frères restaient
exposés. `Last Activity` a alors reçu un garde-fou propre (`preferNewerLastActivity`, sur la
direction de date plutôt que sur la section — son commentaire dit pourquoi : il n'a pas de section
canonique). **`Phase` n'a rien reçu**, alors qu'il vit, lui, dans une section canonique : le
correctif de #2444 s'y applique tel quel. C'est l'argument porté par #2956.

Le point 2 a été porté plus haut que « il manque un repli » : `buildStateFrontmatter` lit le
ROADMAP pour le **dénominateur** (`Math.max(phaseDirs.length, roadmapPhaseCount)`) et refuse de le
lire pour le **numérateur** — ce qui désigne un oubli, pas un choix de conception.

**Sur le backfill des `SUMMARY.md` manquants (Phases 11/12/13/14)** : **non tranché ici,
explicitement remonté à Samuel.** Deux options restent ouvertes — (a) backfiller rétroactivement
les ~20 fichiers manquants pour que la Cause A cesse de produire un écart entre le compteur amont
et le compteur curé à la main ; (b) accepter durablement que le compteur amont sous-évalue et
continuer à curer `.planning/STATE.md` à la main, protégé par le gate. Le coût de (a) est élevé
(reconstruction rétroactive de contenu déjà exécuté et publié) ; le coût de (b) est un entretien
manuel permanent, désormais gardé plutôt qu'invisible.

### Conséquences

**Positives** : la classe d'incident ne peut plus dormir jusqu'à la prochaine relecture humaine —
`check-state-integrity.sh` échoue bruyamment. Le corps de `STATE.md` respecte une convention
vérifiable au lieu de tenir par chance (l'asymétrie de `state.cjs:1402-1413` — qui scope `Stopped
At`/`Paused At` à `## Session` mais ne mentionne jamais `Phase` — établit que le défaut de scope de
`Phase` était déjà vrai avant cette mission ; seul le hasard du contenu du fichier avait empêché la
casse jusqu'ici, pas un choix délibéré du code amont). La distinction Cause A / Cause B empêche de
sur-corriger un défaut d'artefact local avec du code, ou de sous-réagir à un vrai bug amont en
l'absorbant en silence.
**Négatives** : le gate ne corrige rien à la source — une régression continuera de se produire à
chaque écriture d'état tant que Cause A/B ne sont pas résolues en amont ou par backfill ; il la
rend seulement visible. Le signalement amont a un délai et une issue indéterminés (même risque que
documenté pour la RFC de la Phase 18) — VibeFlow reste dépendant d'un tiers pour la correction
définitive.
**Explicitement écarté** : patcher `~/.claude/gsd-core/**` ; trancher seul le backfill des
`SUMMARY.md` manquants ; absorber silencieusement une future régression sans gate.

### Code Impacté

- `docs/ADR.md` (cette entrée)
- `plugin/conductor/scripts/check-state-integrity.sh` + `plugin/conductor/scripts/tests/test-check-state-integrity.sh`
  (gate + suite, 25 cas, 2 discriminations machine par comparaison directe)
- `plugin/conductor/CHANGELOG.md` / `module.json` / `VERSION` / `README.md` — module bumpé v1.18.0
- `plugin/dev-orchestrator/references/mission-contracts.md` — pointeur court (interdiction
  `gsd-tools state` pour « réparer » `STATE.md`)
- `.planning/STATE.md` — 4 sections archivées reformées (`Phase: N` → `**Phase archivée :** N`),
  frontmatter recalé avec commentaire YAML expliquant la curation

### Rules Associées

Nouvelle convention d'écriture de `.planning/STATE.md` (portée par cette ADR, gardée par
`check-state-integrity.sh`) : au plus une ligne `^Phase:` dans le corps, toute section archivée en
`**Phase archivée :**`. Aucune modification de `plugin/_internal/**` ni du moteur GSD — décision
purement locale au repo de distribution.

---

## ADR-064 : Un écrivain = un worktree — l'isolation devient physique, et le claim se dit à tout le monde

**Date** : 2026-08-01 · **Statut** : Validée · **Complète** : ADR-053 (verrou de driver), ADR-059
(une mission = une branche) · **Quick** : `260801-17w`

### Contexte

Le 2026-07-31, entre 18h52 et 19h06, **deux sessions ont écrit sur la même branche**
(`feat/phase-22-hygiene-doc`) sans le savoir. L'une était une mission pilotée par
`vf-dev-manager`, l'autre une session conversationnelle. Trois commits hors périmètre se sont
retrouvés dans la PR d'une mission qui ne les avait pas produits ; le manager a gelé sa lane le
temps de comprendre ce qui bougeait sous ses pieds, puis l'a reprise en trouvant une passation
écrite dans un SUMMARY. Aucun dégât — mais par chance, pas par construction.

Le constat de cause racine, formulé par le manager lui-même :

> le verrou de driver protège la même **étape** contre deux pilotes, rien ne protège la même
> **branche** contre deux écrivains.

Il faut y ajouter le point qui fait vraiment mal, et qu'aucun durcissement du verrou n'aurait
couvert : **`driver-lock.sh` n'est consulté que par les managers**. La session qui est passée
par-dessus n'en était pas un. Un verrou que seule une catégorie d'acteurs interroge ne protège
pas contre les autres — il documente une intention, il ne la fait pas respecter.

ADR-059 avait déjà vu le trou et l'avait **explicitement laissé ouvert** : « ne couvre pas
l'isolation des vagues parallèles à l'intérieur d'une mission […] seul `isolation: worktree` le
ferait. Décision distincte, volontairement laissée ouverte. » Elle est tranchée ici.

### Ce qu'on emprunte, et à qui

- **`shanraisshan/claude-code-best-practice`** (lu le 2026-08-01) — prescrit le **git worktree**
  comme mécanisme d'isolation de premier rang pour le travail parallèle (`--worktree`/`-w`,
  `isolation: "worktree"`, `.worktreeinclude`, hooks `WorktreeCreate`/`WorktreeRemove`). L'idée
  qu'on retient tient en un mot : l'isolation y est **physique**. Deux arbres de travail distincts
  ne peuvent pas se marcher dessus, quelles que soient les intentions de leurs occupants.
- **`1jehuang/jcode`** (étude Phase 9, ADR-053) — d'où vient notre verrou de driver. On ne le
  remplace pas : on **élargit son claim**. Il revendiquait une étape ; il revendique désormais
  aussi une branche et un arbre.

### Décision

**1. Un écrivain = un worktree.** Dès que deux acteurs travaillent en parallèle sur le même dépôt
— deux missions, une mission et une session conversationnelle, deux vagues d'une même mission —
chacun tient **son propre arbre de travail**. C'est la seule barrière qui ne repose pas sur la
bonne volonté de celui qui écrit. La branche (ADR-059) reste nécessaire, elle n'est pas
suffisante : deux sessions peuvent partager une branche depuis un même arbre.

**2. Le claim dit sur quoi il porte.** `driver-lock.sh` enregistre `branch=` et `worktree=` dans
son `meta` à l'acquisition, et les **préserve** au heartbeat — un heartbeat émis après un
`git checkout` ne doit pas revendiquer silencieusement une branche que personne n'a décidé de
piloter. Champs additifs : le contrat JSON de sortie ne bouge pas.

**3. Le signal atteint enfin les sessions ordinaires.** `check-branch-claim.sh` (module
`conductor`) constate qu'un lock **actif** revendique la branche courante **depuis un autre
arbre**, et le dit au `SessionStart`. C'est le geste qui ferme réellement le trou : la session
qui nous est passée dessus aurait vu une ligne au démarrage. Contrat à 4 codes, sur le patron
maintenant établi (`0` signal · `3` SAIN · `4` INDÉTERMINÉ · `64` usage), où SAIN et INDÉTERMINÉ
ne se confondent jamais.

**Le discriminant est l'arbre, pas l'owner.** Deux sessions dans le même arbre se voient déjà :
rien à signaler. C'est l'écriture depuis un arbre **tiers** sur une branche déjà pilotée qui
surprend, et c'est le seul cas signalé.

### Ce que la décision n'est pas

**Aucun blocage dur.** Le gate est **advisory**, comme `check-doc-drift.sh` et
`check-mission-invariants.sh` : il CONSTATE un fait, il ne prononce pas de verdict. Deux sessions
volontairement sur la même branche est un cas **légitime et fréquent** — un hook qui refuserait
d'écrire le casserait. ADR-031 tenu : détecter et prévenir, jamais arbitrer à la place de l'humain.

**On ne réimplémente pas le harness.** `.worktreeinclude` et les hooks `WorktreeCreate`/
`WorktreeRemove` appartiennent à Claude Code. On prescrit l'usage d'`isolation: worktree`, on ne
le refabrique pas.

**Pas de verrou par fichier.** Le grain juste est la branche : c'est là que la collision s'est
produite. Un verrou par fichier serait une usine à faux positifs pour un gain nul.

### Conséquences

Un lock posé par une version antérieure de `driver-lock.sh` ne porte pas de champ `branch` : le
gate rend alors **INDÉTERMINÉ** (4), jamais un SAIN de complaisance. La transition se fait d'
elle-même au premier `acquire` de la nouvelle version.

Le gate compare les chemins **normalisés** (`pwd -P`) et non littéralement : le même arbre se
présente sous deux écritures selon qui l'interroge (`/tmp` est un lien vers `/private/tmp` sur
macOS), et une comparaison brute criait à la collision sur son propre arbre. Ce faux positif a été
débusqué par le cas 2 de la suite, et un cas de régression le tient — discriminance prouvée par
mutation.

Reste non couvert, et assumé : deux sessions dans le **même** arbre sur la **même** branche. Elles
partagent un arbre, elles se voient — mais rien ne les empêche de committer l'une par-dessus
l'autre. C'est le cas que l'utilisateur crée délibérément ; le fermer demanderait un verrou
d'écriture dur, écarté ci-dessus.

---

## ADR-066 : La zone 2 est activée, pas différée — un prérequis insatisfiable ne gate pas

**Date** : 2026-08-04 · **Statut** : Validée · **Décideur** : Samuel (dégel explicite du verdict
`24-ARBITRAGES.md` zone 2) · **Complète** : ADR-063 (dette d'artefact locale vs bug amont)

### Contexte

Le verdict initial de la zone 2 — `workflow.windows_enforce` et `hooks.workflow_guard` — était
**gaté sur un prérequis dur** : ne rien activer tant que `@opengsd/gsd-core` ne serait pas monté
au-delà de **1.9.1**, à cause de l'issue amont **#2893** (`windows append`/`waive`/`fixed`
réécrivent intégralement `WINDOWS.md` via `writeLedgerAtomic` → `renderLedger`, détruisant toute
prose sous le ledger, et rapportant `ok: true`).

Deux faits, re-vérifiés de première main le 2026-08-04, retirent au prérequis sa raison d'être.

**1. Le prérequis est insatisfiable.** Le registre npm donne `dist-tags.latest` = **`1.9.1`**,
publiée le **2026-07-31**, et **aucune version au-delà** : ni `1.9.2`, ni `1.10.x`, ni RC
postérieure. La PR corrective **#2975** est mergée mais **non publiée**. Un gate dont la condition
de levée n'existe pas n'est pas un gate prudent : c'est un **ajournement sans terme**, déguisé en
précaution. La version installée sur la machine est bien 1.9.1 (`~/.claude/gsd-core/VERSION`).

**2. Le risque mesuré est inexistant *sur ce fichier*.** `.planning/WINDOWS.md` fait **87 lignes**
et ne porte **aucune prose libre** sous son ledger : frontmatter, en-tête figé que `renderLedger`
régénère mot pour mot, table, miroir JSON — et rien d'autre. Le bug #2893 **n'a rien à détruire
ici**. La prémisse qui fondait l'ajournement (« notre `WINDOWS.md` porte de la prose sous son
ledger ») était **fausse en l'état**.

### Décision

**Doctrine GSD-first : on n'ajourne pas une capacité native du moteur contre un risque mesuré
inexistant.** En conséquence, et dans cet ordre :

**1. La fenêtre #3 est dérogée** (`gsd-tools windows waive 3`), et non « fermée » : la recette
humaine XcodeBuildMCP (valider `test_sim`/`build_sim`/`clean` contre un serveur vivant) est
**structurellement infermable dans ce dépôt** — aucun `.mcp.json`, aucun projet iOS, aucun
simulateur. `vibeflow-os` est le repo de **distribution** du plugin ; cette recette appartient à un
lab iOS équipé. Une fenêtre qu'aucun travail légitime dans ce dépôt ne peut clore n'est pas une
dette : c'est une dérogation, et elle se dit comme telle, avec sa raison au ledger.

**2. Les deux clés sont posées** dans `.planning/config.json` : `workflow.windows_enforce: true`
et `hooks.workflow_guard: true`.

### Ce qui a été vérifié, et comment

**L'innocuité du `waive`, avant de l'exécuter pour de bon.** La commande a d'abord été **répétée
sur une copie jetable** du fichier (`--cwd` vers un dépôt temporaire), et seulement ensuite jouée
sur le vrai. Constat identique dans les deux cas : **87 lignes avant, 87 après**, fence JSON
unique et refermée, miroir reparsé sans erreur (**5 entrées**, dont les **4 `fixed` intactes**),
`open_count` 1 → 0 et `waived_count` 0 → 1. Le `git diff` ne porte que trois hunks, tous attendus.
**Le bug #2893 ne s'est pas manifesté** — conformément à la mesure ci-dessus, il n'avait aucune
prose à emporter.

**L'armement réel du gate, par la requête même qu'exécute `/gsd-ship`.** Le workflow de ship
n'interroge pas la clé de config : il résout les hooks actifs
(`gsd-tools loop render-hooks ship:pre`) puis cherche un hook `capId == "broken-windows"`,
`kind == "gate"`, `blocking == true`. Cette requête rend désormais ce hook. **Contre-épreuve
jouée** sur une copie de la config **sans** la clé : seul le gate `security` s'y arme,
`broken-windows` est absent. La clé est donc bien la cause, et le gate n'est pas déclaré mais
**actif**. Le prédicat qu'il évaluera est `open_count == 0` en **égalité stricte**, avec `onError:
halt` — sur un ledger illisible il **bloque**, il ne laisse pas passer.

**La garde d'enchaînement, constatée en vol.** `hooks.workflow_guard` s'est manifestée pendant la
rédaction même de cette entrée : l'édition directe de `docs/ADR.md` a déclenché son avis
(« cette édition ne sera pas tracée dans STATE.md »). Elle est **advisory**, non bloquante —
ADR-031 tenu.

### Ce que la décision n'est pas

**Ce n'est pas un blanc-seing sur les commandes `windows`.** Le défaut amont #2893 est **réel** et
non corrigé dans 1.9.1. Ce qui est acté, c'est qu'il est **sans effet sur ce fichier tel qu'il
est** — pas qu'il a disparu. D'où la précaution qui reste due, et qui est le vrai coût de cette
décision : **si `.planning/WINDOWS.md` venait à recevoir de la prose libre sous son ledger, tout
`windows append|waive|fixed` la détruirait silencieusement.** Tant que la version installée est
≤ 1.9.1, le ledger reste un fichier **purement généré** : on n'y écrit pas à la main, et on le
commite avant toute manipulation pour que le dégât reste récupérable.

**Ce n'est pas une fermeture de la fenêtre #3.** Une dérogation n'est pas une résolution. La
recette reste à faire, ailleurs, sur un lab équipé.

### Note de veille — elle ne gate plus rien

Le déclencheur de version qui figurait au verdict initial (« rouvrir ssi une version strictement
supérieure à 1.9.1 portant le correctif #2893 est publiée ») **n'est plus une condition de
reprise** : la zone 2 est activée, elle **n'attend plus rien**. Ce qui subsiste est une simple
**veille d'hygiène** : quand une telle version paraîtra, la monter lèvera la fragilité résiduelle
décrite ci-dessus et rendra le ledger manipulable sans précaution particulière. Aucun travail
n'est suspendu à cette montée. Un lecteur qui croirait la zone 2 « en attente » se tromperait.

---

## ADR-067 : `hooks.community` refusé — c'est une mesure de style, pas de conformité

**Date** : 2026-08-04 · **Statut** : Validée · **Décideur** : Samuel (arbitrage
`24-ARBITRAGES.md`, zone 2) · **Voisine** : ADR-066 (même arbitrage, verdict inverse)

### Contexte

`hooks.community` arme un hook de **Conventional Commits bloquant** : liste de types figée
(`feat|fix|docs|style|refactor|perf|test|build|ci|chore`) et sujet plafonné à **72 caractères**.

Le refus doit être motivé par ce qu'il ferait à **notre** historique, pas par une préférence. La
mesure ci-dessous a été **rejouée le 2026-08-04**, en caractères et non en octets — un décompte en
octets sur des sujets français gonfle mécaniquement la longueur et fabriquerait un faux motif.

### La mesure

Corpus **nommé** : les **400 derniers commits sans merge** du dépôt (la mesure antérieure de la
phase portait sur un corpus de 109 commits qui n'est plus reproductible tel quel ; les deux
convergent sur la conclusion, ce qui compte davantage que le chiffre exact).

| Confrontation à la règle amont | Résultat |
|---|---|
| Sujet dépassant **72 caractères** | **275 / 400 — 68 %** |
| Type hors de la liste amont | **65 / 400 — 16 %** |

Les préfixes fautifs sont **nos six types maison**, et ils ne sont pas anecdotiques :
`release:` (29 occurrences), `planning:` (14), `doctrine:` (3), `plan`, `bump`, `spec`. Ils
décrivent des gestes que la liste amont ne sait pas nommer — publier une version, tenir le
planning, acter une doctrine.

**Ce que dit ce tableau.** Le hook ne détecterait pas des commits négligés : il rejetterait
**plus des deux tiers de notre manière d'écrire**, et six catégories de travail que nous faisons
réellement. Ce n'est pas un gate de **conformité** — rien de ce qu'il refuse n'est incorrect. C'est
un gate de **style**, et il impose un style qui n'est pas le nôtre. Un gate qu'on doit contourner
tous les jours est un gate qu'on finit par désarmer, et le désarmer use la crédibilité de tous les
autres.

### Décision

`hooks.community` **n'est pas posé** dans `.planning/config.json`.

Le refus ne coûte aucune manipulation : `gsd-validate-commit.sh` s'auto-gate sur la config et sort
`0` tant que `hooks.community !== true`. Refuser, c'est **ne pas poser la clé** — l'état de fait,
désormais motivé plutôt que subi.

### Le fait que cette ADR redresse

Le ROADMAP §Phase 24 affirmait que « le lab impose déjà des commits conventionnels en français par
consigne — un gate existe ». **C'est faux.** Aucun `plugin/*/hooks/hooks.json` ne déclare de gate
de message de commit, et `scripts/hooks/pre-push` est le gate de **tag de release**, pas de
message. La convention de commit de ce dépôt est une **consigne du `CLAUDE.md`** (« messages en
français, cohérents avec l'historique »), **jamais une garantie machine**. C'est acté ici pour
qu'on ne puisse plus invoquer un gate qui n'existe pas.

### Déclencheur de réexamen

Rouvrir **ssi** la liste de types amont s'élargit à nos six types maison, **ou** que sa limite de
sujet dépasse 72 caractères, **ou** que nous décidions de réaligner notre convention sur la liste
amont — cette dernière étant une décision de `CLAUDE.md`, pas de configuration.
