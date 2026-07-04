---
name: vf-new-lab
description: >
  Utiliser pour créer/initialiser un NOUVEAU lab VibeFlow dans n'importe quel métier — « crée un lab
  d'acquisition », « monte un lab de contenu », « initialise un lab pour mon agence », « je veux un
  espace VibeFlow pour [métier] ». Moteur clarification-first + Lab Factory : clarifie en profondeur
  (gate machine-enforced), dérive un manifeste de capacités, FABRIQUE les skills en parallèle
  (fan-out skill-creator), ficelle les auditeurs des procédures, puis assemble un lab opérationnel —
  pas un squelette. NE PRÉSUME JAMAIS « dev ». Invocable par l'utilisateur ET par `vibeflow-conductor`.
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
7. ASSEMBLAGE    → CLAUDE.md, modules, planning v2, 5 registres, agents câblés, garde-fous, stamp + récap
```

Les phases 0-3 sont la **clarté** ; 4-6 la **fabrication** ; 7 l'**assemblage**. Profondeur **adaptative
au profil** : un lab léger fait une clarification courte + 1-3 capacités ; un lab riche va jusqu'à
9-20 capacités. L'utilisateur peut sortir (`x`) à tout moment — la dette restante est listée, jamais masquée.

---

## Phase 0 — Triage (2 questions, jamais plus)

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
   ne la duplique JAMAIS. Lancer `conductor/scripts/scaffold-docs.sh <compartiments-qualifiés>` → crée
   `docs/_transverse/` (doc transverse) + un `docs/<projet>/` **par compartiment qualifié** (même seuil
   d'autonomie que les `.planning/` — proportionné, **jamais un `docs/<projet>/` par micro-dossier**). Le
   `CLAUDE.md` mappe ensuite la doc transverse → `@docs/_transverse/` et **chaque compartiment →
   `@docs/<projet>/`**. Détail : `references/doc-externalization.md`.
2. **Modules** — `vibeflow-install` (résoudre deps : `resolve-deps.sh`). Typiquement `planning-core` +
   `consolidator` + `audit-architecture` + `validator`. **Pas `dev-orchestrator`** sauf métier = code.
3. **Socle planning** — `vf-planning`. **Lab à compartiments** : `.planning/` du lab en *steering +
   `INDEX.md`* (jamais de ROADMAP global) ; un socle par compartiment **qualifié** (seuil d'autonomie),
   typé `deliverable` (roadmap+phases) ou `continuous` (`BOARD.md` + cadence). Sous le seuil / infra →
   ligne d'`INDEX.md`. Réf : planning-core `references/compartments.md`. **Jamais un `.planning/` par
   compartiment systématique.**
4. **5 registres mémoire** — DECISIONS / LEARNINGS / BLOCKERS / JOURNAL / **EVALS** (depuis `reference`,
   templates `memory/*-template.md` — registre décisions : `decisions-template.md`, IDs `DEC-XXX`).
   EVALS posé dès l'init (registre du principe **P8 Évaluer**), partie intégrante du socle. Après la
   pose, **indexer par la machine** : `bash .claude/scripts/reindex.sh --all --apply` (crée/recale le
   bloc `## Index` + colonne `#Ligne` de chaque registre — ne jamais rédiger un index à la main).
5. **Agents métier** (2-3, pattern business-agent ; ou instanciés depuis un bundle si présent) —
   **câbler les skills fabriqués** (Phases 5-6) dans leur frontmatter `skills:` (attribution décidée ici,
   d'après les escalades du fan-out).
6. **Garde-fous** — `vibeflow-validator` + `audit-architecture` (auditeurs toujours présents).
7. **Commandes d'incarnation (ADR-042)** — balayer **tous** les agents posés :
   `VF_TARGET_ROOT=<.claude> conductor/scripts/generate-agent-commands.sh`. Génère une `/agent` par
   agent (métier + gouvernance) qui l'**incarne dans la fenêtre principale** (session courante), pas en
   sous-agent. Idempotent (ne réécrit pas une commande existante). Détail : `references/agent-command-incarnation.md`.
8. **Stamp framework** — `framework-version.sh stamp` (rendu **visible au récap**).
9. **GATE C — Conformité machine (ADR-043, BLOQUANT)** — l'init ne se conclut PAS tant que :
   `bash .claude/scripts/check-registres.sh --strict` sort en **exit 0** (5 registres canon présents,
   `## Index` + colonne `#Ligne`, IDs cohérents index↔body, zéro doublon) **ET** que les hooks de
   gouvernance sont câblés : `grep -q guard-read-registres .claude/settings.json` (posés automatiquement
   par `vibeflow-install` via `hooks/hooks.json` + `merge-hooks.sh` — s'ils manquent, réinstaller le
   module `consolidator`, ne JAMAIS les recopier à la main). En cas d'échec : corriger
   (`reindex.sh --all --apply`, re-poser le registre manquant) puis relancer le gate. **Comme le Gate A,
   ce grep/script est la preuve — pas ton impression que « ça a l'air bon ».**

> **Bundle métier (raccourci)** : si un bundle est installé (`docs/<metier>-bundle/`), s'en servir comme
> **bibliothèque** — piocher blueprints d'agents + manifeste de capacités suggéré — **jamais comme moule**.
> Le brief clarifié fait autorité en cas de divergence.

### Récap (et ancrage)

Montrer : l'arbo, le métier capté, **les skills fabriqués + leur attribution**, les procédures auditées,
la **première action métier** proposée. En **mode découverte** : mini-récap pédagogique (P1-P9, 5
registres, auditeurs, comment les actionner). Lister la **dette** éventuelle (capacités backlog,
`[À RETRAVAILLER]`, marqueurs restants si sortie forcée).

---

## Garde-fous

- **Jamais dériver/fabriquer avec un marqueur `[À CLARIFIER]` ouvert** (Gate A puis Gate B).
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
