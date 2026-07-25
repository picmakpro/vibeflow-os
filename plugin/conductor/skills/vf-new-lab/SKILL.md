---
name: vf-new-lab
description: >
  Utiliser pour créer/initialiser un NOUVEAU lab VibeFlow dans n'importe quel métier — « crée un lab
  d'acquisition », « monte un lab de contenu », « initialise un lab pour mon agence », « je veux un
  espace VibeFlow pour [métier] ». Moteur clarification-first + Lab Factory : clarifie en profondeur
  (gate machine-enforced), dérive un manifeste de capacités, FABRIQUE les skills en parallèle
  (fan-out skill-creator), ficelle les auditeurs des procédures, puis assemble un lab opérationnel —
  pas un squelette. NE PRÉSUME JAMAIS « dev ».
  Mode EXPRESS intégré (lab opérationnel ≤ 15 min, 3 questions max, dégradé assumé) quand
  l'utilisateur exprime l'urgence ou la légèreté — « ce soir », « vite », « simple », « juste pour
  tester » — ou le demande explicitement.
  ✘ pas pour remettre à niveau un lab qui existe déjà → /vf-calibrate · ✘ pas pour amorcer un
  dossier de **code** et son démarrage de projet → brique `gsd-new-project` du moteur de dev ·
  ✘ pas pour poser le socle documentaire d'un lab déjà créé → /vf-planning.
  Invocable par l'utilisateur ET par `vibeflow-conductor`.
---

# vf-new-lab — Lab Factory (init clarification-first + fabrication des capacités)

> **Mission** : transformer un projet flou en un lab VibeFlow **opérationnel et sur-mesure** — clarifié
> en profondeur, **peuplé de ses skills**, ses procédures **déjà auditées**, sa structure dérivée du
> brief (jamais plaquée d'un gabarit). On ne livre pas un squelette : on **compile un lab**.
>
> **Iron Law 1 (clarté)** : *« AUCUNE DÉRIVATION TANT QU'UN MARQUEUR [À CLARIFIER] SUBSISTE. »* La
> clarté est un gate **machine-enforced** (marqueur présent/absent), pas une consigne en prose.
> **Iron Law 2 (fabrication)** : *« On fabrique les capacités JUSTIFIÉES par le brief, jamais le plus
> possible. Une capacité sans justification = pas de skill. »*

Skill **prose agent-driven** + **orchestrateur** : il clarifie, dérive, puis **délègue** la fabrication
aux modules outillés (`skill-creator` en parallèle, `audit-architecture`, `planning-core`, installeur).

---

## Pipeline (7 phases)

```
0. TRIAGE        → greenfield|brownfield ? + profil (power user|découvre) → mode adaptatif
1. SCAN          → (brownfield) cartographie autonome AVANT toute question (délègue explorer)
2. CLARIFICATION → brief construit SECTION PAR SECTION, menu numéroté sur sections critiques
3. GATE A        → tant qu'un [À CLARIFIER] subsiste dans le brief → retour 2. Sinon → 4.
4. MANIFESTE     → dériver les capacités (savoir/compétence/procédure) + GATE B + proportionner
5. FAN-OUT       → fabriquer les skills en parallèle (N × skill-creator) + anti-slop
6. FICELAGE      → câbler un auditeur par procédure générative (audit-architecture)
7. ASSEMBLAGE    → CLAUDE.md, modules, planning v2, registres (EVALS selon profil), agents câblés, garde-fous, stamp + récap
```

Les phases 0-3 sont la **clarté** ; 4-6 la **fabrication** ; 7 l'**assemblage**. Profondeur **adaptative
au profil** : un lab léger fait une clarification courte + 1-3 capacités ; un lab riche va jusqu'à
9-20 capacités. L'utilisateur peut sortir (`x`) à tout moment — la dette restante est listée, jamais masquée.

> **Mode express** (proposé au triage sur signal d'urgence, ou demandé) : les phases 0-4 sont
> remplacées par **3 questions** + une dérivation dégradée ASSUMÉE, le fan-out part en tâche de
> fond, **Gate C reste intact**. Contrat complet : section « Mode express » ci-dessous.

---

## Phase 0 — Triage (2 questions, jamais plus — + détection express)

0. **Détection express (avant tout)** — si la demande exprime l'**urgence ou la légèreté**
   (« ce soir », « vite », « simple », « juste pour tester », « rapide », « sans cérémonie »)
   OU si l'utilisateur demande explicitement le mode express → proposer :
   « **Express** (lab opérationnel en ≤ 15 min, 3 questions, le reste dérivé et marqué à affiner)
   ou **parcours complet** ? ». S'il choisit express → basculer sur la section
   **« Mode express »** ci-dessous (elle remplace les phases 0-4). Sinon, parcours standard :
1. **Greenfield ou brownfield ?** — « Ce lab part de zéro, ou pilote un projet/codebase/process existant ? »
2. **Profil** — déduire (ne pas interroger frontalement) si l'utilisateur **maîtrise** VibeFlow (power
   user) ou le **découvre**. Indices : vocabulaire, mention des registres/principes.

> **Mode adaptatif** : power user → clarification sèche, dense, sans pédagogie. Découvre → chaque section
> **enseigne le pattern** au passage (« 💡 Pourquoi : … »), l'init devient onboarding méthodo. Profil non
> figé : monter/descendre en densité selon les réponses ; détecter la **fatigue cognitive** et resserrer.

## Phase 1 — Scan (brownfield uniquement)

**Iron Law brownfield** : *« On ne demande JAMAIS ce que le projet dit déjà. »*
1. Déléguer un **scan autonome** à l'agent `explorer` (read-only) : stack, structure, conventions, dette.
2. Produire un **état des lieux** (≤1 écran) + **pré-remplir** le brief avec ce qui est dérivable.
3. N'ouvrir l'élicitation que sur les trous que le projet ne dit pas (intention, objectif, non-périmètre…).

Greenfield : sauter, tout est à clarifier. **Si le scan ne dérive rien d'exploitable** (repo quasi-vide
marqué brownfield par erreur) → **basculer en greenfield** et le signaler.

## Phase 2 — Clarification (élicitation section par section)

Construire `docs/LAB_BRIEF.md` **une section à la fois**. Chaque section : `✅ clair` ou
`[À CLARIFIER: question]`. Sections canoniques + critères de clôture : `references/completeness-gate.md`.

| # | Section | # | Section |
|---|---------|---|---------|
| 1 | Problème / valeur cœur | 5 | Process & livrables récurrents |
| 2 | Métier & vocabulaire | 6 | Contraintes |
| 3 | Parties prenantes | 7 | Définition de fini / succès |
| 4 | Périmètre & non-périmètre | 8 | Gates métier & EVALS |

**Mécanique (pattern BMAD)** : sur les sections critiques (problème, périmètre, gates), présenter le
contenu rédigé par l'agent **puis un menu numéroté** :

```
Section [N] — [titre] : [contenu proposé]
  1. ✅ Continuer (section claire)   2. 🔍 Pré-mortem   3. 🔄 Inversion
  4. 👥 Parties prenantes   5. ❓ Socratique   r. ↻ autres méthodes   x. ⏹ terminer
→ Choisis un chiffre, ou écris ta réponse/correction :
```

L'utilisateur **choisit un chiffre, ne rédige rien** — l'agent creuse sous l'angle choisi, met à jour la
section, ré-affiche le menu jusqu'à `1` ou `x`. Méthodes détaillées : `references/elicitation-methods.md`.
Sections non critiques : question directe, pas de menu.

## Phase 3 — Gate A (clarté du brief, machine-enforced)

```bash
grep -nE '^\s*\[À CLARIFIER:' docs/LAB_BRIEF.md   # ancré début de ligne — voir completeness-gate.md
```
- **≥1 marqueur** → bloque. Lister les trous + leur risque, retour Phase 2 sur ces points. Pas de suite.
- **0 marqueur** → passer au manifeste.
- Sortie forcée (`x`) avec marqueurs → brief livré **avec dette** + ouvrir un BLOCKER. **Mode dégradé** :
  les phases 4-7 ne dérivent que des sections `✅` ; rien qui touche une section `[À CLARIFIER]` (backlog).

## Phase 4 — Manifeste de capacités (+ Gate B)

Dériver du brief les **capacités à fabriquer**, classées en 3 natures — **savoir** (connaître),
**compétence** (savoir-faire), **procédure** (workflow répétable). Écrire `docs/CAPABILITY_MANIFEST.md`.
Détail + schéma d'entrée + proportionnalité : `references/capability-manifest.md`.

- **Gate B** : aucune capacité ne part au fan-out sans nature + justification (rattachée à une section du
  brief) + critère de succès. Une capacité injustifiée = `[À CLARIFIER]`, **pas un skill de plus**.
- **Proportionner** au profil (`scripts/proportion-capabilities.sh`) : léger 1-3 · standard 4-8 ·
  complet 9-20. Au-delà → P0/P1/P2 ; seules les **P0 partent au fan-out**, le reste en backlog (logué).
- L'utilisateur **valide/édite** la liste (Red Team possible : « lesquelles en trop / manquantes ? »).

## Phase 5 — Fan-out skill-creator (fabrication parallèle)

Pour chaque capacité **P0** validée : lancer une invocation **`skill-creator`** comme **sous-agent**
(outil `Task`, `subagent_type: skill-creator`), **une par capacité**, **en parallèle** (plusieurs
tool-uses dans un seul message ; par vagues de 5-6 si gros manifeste). **Si `Task` ou le sous-agent
skill-creator est indisponible → fallback séquentiel** (invoquer skill-creator l'un après l'autre).
Le prompt d'invocation **doit injecter** : (a) destination forcée `.claude/skills/<nom>/` (nature META,
ignorer la distinction LIVRABLE du template) ; (b) « escalade ton attribution en retournant la liste
`skill → agents suggérés` dans ton message final à `vf-new-lab` » (ne pas compter sur le placeholder
`[ORCHESTRATING_AGENT]`). Détail : `references/skill-fanout.md`.

**Anti-slop** : (1) gate de capacité + orthogonalité déjà passés (Gate B) ; (2) **eval par skill** borné
(**max 3 passes** ; au-delà → `[À RETRAVAILLER]` + backlog, on continue le reste) ; (3) **critique de
complétude** après le fan-out, **déléguée à un sous-agent frais** (reviewer/explorer, pas l'orchestrateur
juge-et-partie) : « quelle capacité sans skill ? lequel redondant ? ». `skill-creator` **n'attribue
pas** : il escalade → l'attribution se fait en Phase 7.

> Cas limite : **0 capacité P0** → pas de fan-out ; on assume un lab squelette (le signaler au récap,
> proposer d'ajouter des capacités plus tard via skill-creator à la demande).

## Phase 6 — Ficelage des auditeurs

Pour chaque capacité de nature **procédure** avec `auditeur requis: oui` (procédure **générative**) :
déléguer à `audit-architecture` la **conception** de la structure d'audit (Dimension × Auditeur
indépendant × Rubric × **Verdict bloquant** × Anti-boucle). `audit-architecture` *conçoit et propose*
(son Iron Law / ADR-031 : il ne matérialise pas seul) ; **c'est `vf-new-lab` qui matérialise** l'auditeur
en Phase 7 — la **validation du manifeste en Phase 4 fait office de feu vert humain** (ADR-031 respecté).
Détail : `references/procedure-audit-wiring.md`. **Pas de verdict bloquant → pas d'audit.** Ne pas
sur-ficeler : seules les procédures dont la qualité de l'output compte.

## Phase 7 — Assemblage & scaffolding

Dériver puis poser (déléguer, ne pas réinventer) :
1. **`CLAUDE.md` + externalisation doc (ADR-042)** — l'init du `CLAUDE.md` **déclenche** l'externalisation
   de la doc : le `CLAUDE.md` est une **constitution** (< 150 lignes, **P2**) qui **POINTE** vers la doc,
   ne la duplique JAMAIS. Lancer `bash "${CLAUDE_PLUGIN_ROOT}/conductor/scripts/scaffold-docs.sh" <compartiments-qualifiés>`
   (cache plugin — les modules ne sont pas encore posés à cette phase) → crée
   `docs/_transverse/` (doc transverse) + un `docs/<projet>/` **par compartiment qualifié** (même seuil
   d'autonomie que les `.planning/` — proportionné, **jamais un `docs/<projet>/` par micro-dossier**). Le
   `CLAUDE.md` mappe ensuite la doc transverse → `@docs/_transverse/` et **chaque compartiment →
   `@docs/<projet>/`**. Détail : `references/doc-externalization.md`.
2. **Modules** — `vibeflow-install` (résoudre deps : `"${CLAUDE_PLUGIN_ROOT}/_internal/resolve-deps.sh"` —
   voir la table d'invocations exactes du skill `vibeflow-install`). Typiquement `planning-core` +
   `consolidator` + `audit-architecture` + `validator` + **`skill-creator`** (canal unique de création
   de skills — posé d'office car dépendance du conductor `mandatory`, donc disponible dès la Phase 5).
   **Pas `dev-orchestrator`** sauf métier = code.
3. **Socle planning** — **qualifier le métier d'abord** (ADR-055) : *lab non-dev* → `vf-planning` pose le
   socle adapté au métier ; *lab de code* → le socle du **projet** appartient au moteur de développement,
   router la brique **`gsd-new-project`** (`vf-planning` n'y pose plus le tronc, il tient l'altitude lab
   et redirige — carte : `dev-orchestrator/references/intent-routing.md`).
   **Lab à compartiments** (quel que soit le métier) : `.planning/` du lab en *steering +
   `INDEX.md`* (jamais de ROADMAP global) ; un socle par compartiment **qualifié** (seuil d'autonomie),
   typé `deliverable` (roadmap+phases) ou `continuous` (`BOARD.md` + cadence). Sous le seuil / infra →
   ligne d'`INDEX.md`. Réf : planning-core `references/compartments.md`. **Jamais un `.planning/` par
   compartiment systématique.**
4. **Registres mémoire** — DECISIONS / LEARNINGS / BLOCKERS / JOURNAL (+ **EVALS** selon profil) (depuis
   `reference`, templates `memory/*-template.md` — registre décisions : `decisions-template.md`, IDs
   `DEC-XXX`). **EVALS est proportionné au profil** (gouvernance proportionnée, audit 2026-07-25) :
   - **profil `standard`/`complet`** → EVALS posé dès l'init (registre du principe **P8 Évaluer**),
     partie intégrante du socle ;
   - **profil `leger`** → EVALS **optionnel à l'init** : il est créé **à la première éval réelle**
     (première entrée `EVAL-001`), pas vide d'avance. Les gates métier & EVALS du brief (section 8)
     restent définis — seul le registre attend d'avoir quelque chose à consigner.
   Après la pose, **indexer par la machine** : `bash .claude/scripts/reindex.sh --all --apply` (crée/recale
   le bloc `## Index` + colonne `#Ligne` de chaque registre — ne jamais rédiger un index à la main).
5. **Agents métier** (2-3, pattern business-agent ; ou instanciés depuis un bundle si présent) —
   chaque agent posé porte le **frontmatter canonique COMPLET (ADR-044, vérifié machine)** :
   ```yaml
   ---
   name: <kebab-case, = nom du fichier>
   description: <QUAND utiliser cet agent — c'est le déclencheur du routage automatique ; inclure « Use when… »>
   model: <sonnet|opus|haiku|fable|inherit — choix JUSTIFIÉ par la mission>
   memory: project        # souveraineté mémoire — cross-session, versionnable
   skills: [<skills EXISTANTS — fabriqués Phases 5-6 ou créés via skill-creator, JAMAIS une promesse>]
   effort: <optionnel : low|medium|high|xhigh|max>
   tools: <optionnel : restreindre si l'agent est en lecture/analyse>
   ---
   ```
   **Câbler les skills fabriqués** (Phases 5-6) dans `skills:` (attribution décidée ici, d'après les
   escalades du fan-out). Un agent sans `description` n'est JAMAIS auto-routé ; un skill déclaré mais
   non créé est une hallucination (Gate C le bloque).
   **Règle de chargement du contexte (ADR-044, vérité runtime)** : `skills:` injecte le SKILL.md
   ENTIER au startup de l'agent ; le on-demand est le défaut natif (description seule au startup,
   ~zéro coût ; contenu chargé à l'invocation ; `references/` à la demande via Read). Donc :
   **précharger UNIQUEMENT les skills courts (≤ 200L) utilisés à chaque mission de l'agent** ;
   tout le reste vit en on-demand avec une `description` déclenchable ; budget préchargé cumulé
   ≤ 1200 lignes par agent (gate machine `check-agents.sh`). Le **body** de chaque agent se termine par le
   format de retour standard (`**Statut** : FAIT|PARTIEL|BLOQUÉ · **Livrable** · **Décisions (DEC-XXX)**
   · **Reste/risques**) et le pont d'escalade C4 (`@.claude/agents/conductor-references/contracts.md`)
   — Claude Code n'a aucun contrat natif agent↔sous-agent, cette convention est la seule couche.
5bis. **Orchestrateur métier (ADR-048) — posé d'office dès ≥2 agents métier.** Un lab à ≥2 spécialistes a
   besoin d'un **chef d'orchestre métier** : sinon la coordination (qui fait quoi, dans quel ordre, qui
   vérifie et réconcilie) n'est portée par personne — le `conductor` est **méta** et ne fait PAS le travail
   métier. On pose donc, distinct du conductor :
   - **Le skill (générique, verbatim)** : copier
     `${CLAUDE_PLUGIN_ROOT}/reference/content/methodology/templates/skills/metier-orchestration/`
     (SKILL.md + `references/`) dans `.claude/skills/metier-orchestration/`. Il encode la **boucle de
     mission** (contexte → cartographie → clarification → planification → délégation → vérification
     adversariale → navette bornée → capitalisation + mise à jour `.planning/`). ≤200L → **préchargeable**.
   - **L'agent (parametré au métier)** : instancier
     `${CLAUDE_PLUGIN_ROOT}/reference/content/methodology/templates/agents/orchestrator-template.md` →
     `.claude/agents/<orchestrateur-metier>.md`, en remplaçant `[orchestrateur-metier]` (nom kebab marié au
     métier), `[METIER]`, `[SPÉCIALISTES]` (les agents posés au point 5) et `[GATES MÉTIER]` (section
     « Gates métier & EVALS » du brief). Frontmatter canonique ADR-044, `skills: [metier-orchestration]`
     préchargé (+ un éventuel skill de savoir métier ≤200L).
   - **Câblage** : les agents spécialistes deviennent ses **délégués** (mandat écrit via `Task`) ;
     l'orchestrateur devient le **point d'entrée** des missions métier. Sa Phase 0 lit le `.planning/`
     (index-first) et sa Phase 7 le met à jour → cohérent avec les hooks planning-core (Patch C).
   > **Seuil** : **< 2 agents métier** (lab mono-agent) → pas d'orchestrateur (surcoût inutile, l'unique
   > agent est l'exécutant). **Métier = code** → ce rôle est déjà tenu par `dev-orchestrator` (ADR-046) :
   > **ne pas doubler**. L'orchestrateur métier respecte P3 (ne produit jamais) et ADR-029 (≤250L).
6. **Garde-fous** — `vibeflow-validator` + `audit-architecture` (auditeurs toujours présents).
7. **Commandes d'incarnation (ADR-042)** — balayer **tous** les agents posés :
   `VF_TARGET_ROOT=<.claude> bash "${CLAUDE_PLUGIN_ROOT}/conductor/scripts/generate-agent-commands.sh"`. Génère une `/agent` par
   agent (métier + gouvernance) qui l'**incarne dans la fenêtre principale** (session courante), pas en
   sous-agent. Idempotent (ne réécrit pas une commande existante). Détail : `references/agent-command-incarnation.md`.
8. **Stamp framework** — `bash .claude/scripts/framework-version.sh stamp` (rendu **visible au récap**).
9. **GATE C — Conformité machine (ADR-043 + ADR-044, BLOQUANT)** — l'init ne se conclut PAS tant que
   les TROIS vérifications machine ne passent pas :
   1. `bash .claude/scripts/check-registres.sh --strict` → **exit 0** (registres canon présents,
      `## Index` + colonne `#Ligne`, IDs cohérents index↔body, zéro doublon). Le script lit le profil
      du lab (`.planning/config.json`, clé `profile`, ou env `VF_LAB_PROFILE`) : en profil **léger**,
      un `EVALS.md` absent est un **avertissement** (créé à la première éval réelle), pas un échec ;
      en standard/complet les 5 registres restent exigés ;
   2. `bash .claude/scripts/check-agents.sh --strict` → **exit 0** (chaque agent : frontmatter natif
      complet name/description/model/memory, enums valides, skills déclarés EXISTANTS, budget de
      préchargement respecté) ;
   3. hooks de gouvernance câblés : `grep -q guard-read-registres .claude/settings.json` (posés
      automatiquement par `vibeflow-install` via `hooks/hooks.json` + `merge-hooks.sh` — s'ils
      manquent, réinstaller le module, ne JAMAIS les recopier à la main).
   En cas d'échec : corriger (`bash .claude/scripts/reindex.sh --all --apply`, compléter le frontmatter, créer le skill
   manquant via skill-creator) puis relancer le gate. **Comme le Gate A, ces scripts sont la preuve —
   pas ton impression que « ça a l'air bon ».**

> **Bundle métier (raccourci)** : si un bundle est installé (`docs/<metier>-bundle/`), s'en servir comme
> **bibliothèque** — piocher blueprints d'agents + manifeste de capacités suggéré — **jamais comme moule**.
> Le brief clarifié fait autorité en cas de divergence.

### Récap (et ancrage)

Montrer : l'arbo, le métier capté, **les skills fabriqués + leur attribution**, les procédures auditées,
la **première action métier** proposée. En **mode découverte** : mini-récap pédagogique (P1-P9, 5
registres, auditeurs, comment les actionner). Lister la **dette** éventuelle (capacités backlog,
`[À RETRAVAILLER]`, marqueurs restants si sortie forcée).

---

## Mode express — lab opérationnel en ≤ 15 minutes (dégradé ASSUMÉ)

> **Contrat** : time-to-first-value ≤ 15 min (audit 2026-07-25, section F). **3 questions maximum**,
> tout le reste est **dérivé** — et cette dérivation est assumée et affichée, jamais masquée.
> S'appuie intégralement sur la **gouvernance proportionnée** (v2.33.0, profil `leger`) : on ne
> réinvente rien, on pose le profil et l'aval se proportionne tout seul.

### Les 3 questions (jamais plus)

1. **Métier du lab** — « Ce lab fait quoi, comme métier ? » (réponse libre courte).
2. **Objectif** — « Son objectif, en une phrase ? »
3. **Capacités prioritaires** — « Les 1 à 3 choses qu'il doit savoir faire en premier ? »

Aucune relance, aucun menu d'élicitation, aucune section à valider une à une. **Seule exception** :
si l'une des 3 réponses est inexploitable (vide, contradictoire), poser `[À CLARIFIER]` dessus et
redemander — c'est l'unique cas de question supplémentaire.

### Dérivation dégradée (le reste du brief)

- Écrire `docs/LAB_BRIEF.md` avec les 8 sections canoniques : celles couvertes par les 3 réponses
  sont `✅` ; **toutes les autres sont remplies par déduction** (depuis le métier + l'objectif) et
  marquées **`[DÉRIVÉ — à affiner]`** — PAS `[À CLARIFIER]` : une déduction assumée n'est pas un trou.
- **Profil `leger` posé d'office** dans `.planning/config.json` (clé `profile`) — c'est lui qui
  proportionne tout l'aval, déjà câblé en v2.33.0 : plafond 1-3 capacités, Stop-hook en warn,
  validator Phase 4 opt-in, registre EVALS différé à la première éval réelle.

### Gates en express

- **Gate A (assoupli)** : les `[DÉRIVÉ — à affiner]` **ne bloquent pas** (le grep du gate ne matche
  que `[À CLARIFIER:` — un `[DÉRIVÉ]` passe par construction). Seul un `[À CLARIFIER]` portant sur
  **l'une des 3 réponses données** bloque → retour question ciblée, rien d'autre.
- **Gate B (assoupli)** : les capacités sortent de la réponse 3 telles quelles — justification =
  « demandée à l'init express », critère de succès dérivé de l'objectif. Plafond du profil
  `leger` : **3 max** ; au-delà → backlog, logué au récap.
- **Gate C — INTACT, non négociable** : les trois vérifications machine (`check-registres.sh --strict`,
  `check-agents.sh --strict`, hooks de gouvernance câblés) **ne se négocient JAMAIS**, express ou pas.
  La seule souplesse est celle que les scripts accordent déjà au profil `leger` (EVALS absent =
  avertissement) — elle vient des scripts, jamais d'un contournement.

### Fabrication en tâche de fond

Lancer le fan-out `skill-creator` (Phase 5, 1-3 capacités) **en arrière-plan** (sous-agents
`run_in_background`) puis enchaîner IMMÉDIATEMENT l'assemblage (Phase 7 allégée : CLAUDE.md,
modules, socle planning profil `leger`, registres, Gate C). **L'utilisateur peut commencer à
travailler pendant la fabrication** ; à la notification de fin, câbler les skills livrés
(attribution) et le signaler en une ligne. Phase 6 (ficelage auditeurs) : uniquement si une
capacité est une procédure générative — sinon sauter.

### Récap final — « dette d'express » (obligatoire)

Le récap liste **honnêtement** :
1. les 3 réponses sur lesquelles le lab est construit ;
2. chaque section `[DÉRIVÉ — à affiner]` du brief, avec ce qui a été déduit ;
3. les capacités reportées en backlog (si plus de 3 demandées) et les auditeurs non ficelés ;
4. **comment affiner plus tard** : `/vf-calibrate` reprend chaque `[DÉRIVÉ — à affiner]` et
   remonte le lab vers `standard`/`complet` quand le besoin se confirme — l'express est un point
   de départ assumé, pas un plafond.

---

## Garde-fous

- **Jamais dériver/fabriquer avec un marqueur `[À CLARIFIER]` ouvert** (Gate A puis Gate B). En
  express, un `[DÉRIVÉ — à affiner]` n'est **pas** un `[À CLARIFIER]` : il ne bloque pas.
- **Express** : jamais plus de **3 questions** ; jamais un **Gate C** affaibli ; jamais une
  dérivation masquée — tout `[DÉRIVÉ — à affiner]` figure au récap de dette (+ `/vf-calibrate`).
- **Jamais rédiger un skill à la main** : toute création OU mise à jour de skill — y compris une
  procédure interne ou un skill « sur-mesure » — passe par `skill-creator` (canal unique : recherche →
  draft → eval → itère). Le pipeline vaut même sur des données de procédures qu'on a déjà en interne.
- **Jamais fabriquer une capacité injustifiée** ni dépasser le plafond du profil (anti-slop).
- **Jamais présumer dev** ; extension & vocabulaire viennent du brief réel.
- **Jamais un `.planning/` par compartiment systématique** ; jamais de ROADMAP global de lab.
- **Jamais d'auditeur sans verdict bloquant** sur une procédure générative.
- **Jamais inliner la doc dans le `CLAUDE.md`** : externaliser sous `docs/` et y **pointer** (`@docs/...`) ;
  doc contextuelle `docs/<projet>/` réservée aux **compartiments qualifiés** (ADR-042).
- **Toujours générer une commande d'incarnation `/agent` par agent posé** (fenêtre principale, pas Task) ;
  ne jamais écraser une commande existante (ADR-042).
- **Toujours câbler les auditeurs** du lab + **stamper la version**.
- **Toujours offrir la sortie `x`** et afficher la dette en sortant ; adapter la densité au profil.

## Références (on-demand)

- `references/elicitation-methods.md` — les 8 méthodes du menu numéroté (clarification).
- `references/completeness-gate.md` — critères de clôture par section + Gate A (brief) + Gate B (manifeste).
- `references/capability-manifest.md` — dériver/justifier/proportionner les capacités (savoir/compétence/procédure).
- `references/skill-fanout.md` — fabrication parallèle des skills + anti-slop + attribution.
- `references/procedure-audit-wiring.md` — câbler un auditeur par procédure générative (audit-architecture).
- `references/doc-externalization.md` — externalisation doc + topologie contextuelle `docs/_transverse/` + `docs/<projet>/` (ADR-042).
- `references/agent-command-incarnation.md` — commandes `/agent` d'incarnation fenêtre principale vs sous-agent (ADR-042).
- `conductor/scripts/scaffold-docs.sh` (squelette doc) + `conductor/scripts/generate-agent-commands.sh` (commandes d'incarnation).
- `conductor/references/bootstrap-method.md` — méthode de cadrage/dérivation.
- planning-core `references/PROFILES.md` / `domain-detection.md` / **`compartments.md`** (topologie
  compartiments : seuil d'autonomie, typage deliverable/continuous, INDEX) — chargé en Phase 7. Bundles : `docs/<metier>-bundle/`.
- `scripts/proportion-capabilities.sh` — plafond conseillé de capacités P0 selon le profil.
- Outils délégués (chemins) : `_internal/resolve-deps.sh` (deps modules), `conductor/scripts/framework-version.sh` (stamp).
