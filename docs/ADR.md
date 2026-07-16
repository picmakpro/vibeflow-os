# Registre des Décisions d'Architecture (ADR) — vibeflow-os

> Registre versionné du repo (le template framework cible `.claude/memory/ADR.md`, mais ce
> chemin est gitignoré ici — le repo de distribution versionne ses ADR dans `docs/`).
> Gestion : lire l'index d'abord, charger le détail d'une ADR seulement si nécessaire.
> Les ADR antérieures à ce registre (ADR-001 → ADR-045) prédatent sa création : leur trace
> vit dans les CHANGELOG des modules, les rules et les specs (`docs/superpowers/specs/`).

---

## Index

| ID | Date | Titre | Statut |
|----|------|-------|--------|
| ADR-046 | 2026-07-09 | Équipe manager de mission — arborescence à contexte minimal | Validée |
| ADR-047 | 2026-07-11 | skill-creator dans la baseline d'install (dépendance du conductor) | Validée |
| ADR-048 | 2026-07-16 | Orchestrateur métier systématique (≥2 agents) + skill boucle de mission | Validée |
| ADR-049 | 2026-07-16 | Backups mémoire isolés + rotation intégrée (anti-pollution registres) | Validée |
| ADR-050 | 2026-07-16 | Hooks planning : lecture index-first au start + mise à jour bloquante au end | Validée |

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

> Pattern éprouvé sur le projet Reviz (`WillHosting/.claude/agents/`) : main → manager →
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
5. **Généricité (DM5)** : zéro chemin/règle Reviz ; conventions `.planning/` de GSD ; les
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
