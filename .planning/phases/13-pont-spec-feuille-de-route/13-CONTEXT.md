# Phase 13: Pont spec → feuille de route - Context (plan 13-02)

**Gathered:** 2026-07-26 (assumptions mode, non-interactif — délégué par `vf-dev-manager` à `vf-coder`,
sans `AskUserQuestion` disponible)
**Status:** Ready for planning
**Portée de ce cadrage** : uniquement le plan **13-02** (câblage de l'ingestion dans l'agent
`vibeflow-dev`, BRDG-01 + BRDG-03). Le plan **13-01** (découverte outillée, BRDG-02) est déjà écrit et
en cours d'exécution en parallèle — non rouvert ici, traité comme fait acquis.

<domain>
## Phase Boundary

Source : `.planning/ROADMAP.md` §Phase 13 (redéfinie le 2026-07-26) + `.planning/REQUIREMENTS.md`
BRDG-01/BRDG-02/BRDG-03.

Le plan 13-02 livre :
1. L'agent `vibeflow-dev` appelle `discover-unintegrated-docs.sh` (contrat du plan 13-01) et
   interprète ses 3 exits.
2. La construction du manifest YAML par l'agent (typage/précédence = jugement, ADR-055 §3).
3. La délégation spec → `gsd-ingest-docs --mode merge --manifest <f>`, plan → `gsd-import --from <chemin>`
   — sans réimplémenter ni contourner ces moteurs.
4. Les garde-fous BRDG-03 (gate BLOCKER, confirmation humaine ADR-031, `--mode merge` par défaut, cap 50).
5. La proposition de l'ingestion comme next step en fin de cadrage.
6. Les axes de test machine + la release-meta du **module** `dev-orchestrator` (VERSION/module.json/
   CHANGELOG/README).

**Ne produit PAS** (hors périmètre explicite de la mission, tranché par le mandat) :
- Aucun verbe-façade `/vf-ingest` (façade supprimée v2.33.0, spec
  `docs/superpowers/specs/2026-07-25-suppression-facade-vf-design.md`).
- Aucun bump de la `VERSION` racine, aucun tag git, aucune modification de
  `plugin/.claude-plugin/plugin.json` ni `.claude-plugin/marketplace.json`. Le critère de succès 5 du
  ROADMAP (« release livrée, tag poussé ») est un **reste-à-faire post-plan**, réservé à une validation
  humaine ultérieure — ne pas le planifier.
- Aucune modification de `plugin/dev-orchestrator/scripts/discover-unintegrated-docs.sh` ni de sa suite
  de test dédiée (13-01, en cours d'exécution en parallèle — zone interdite).
- Aucune réimplémentation du parseur de manifest, du moteur de conflits ou du gate BLOCKER : ils sont
  natifs à `gsd-ingest-docs`/`gsd-import` (voir `<code_context>`).
- Aucune modification de `plugin/_internal/vibeflow-update.sh` : l'installeur copie déjà
  `references/*` par wildcard (confirmé, cf. `<code_context>`) — un nouveau fichier de référence est
  installé sans câblage supplémentaire.
</domain>

<decisions>
## Implementation Decisions

### Emplacement de la doctrine (densité ADR-029)

- **D-01:** La doctrine d'ingestion (découverte, contrat manifest, délégation, garde-fous BRDG-03) est
  écrite dans un **nouveau fichier** `plugin/dev-orchestrator/references/ingestion-flow.md`, chargé
  on-demand — jamais en dur dans `AGENT.md` (152/250 lignes actuelles). `AGENT.md` ne reçoit que : une
  ligne dans la table « Amont & cadrage » des raccourcis dominants, une clause ajoutée à la section
  « Next steps & hygiène documentaire » existante (pas de nouvelle section), une entrée dans
  « Références », et un rappel garde-fou d'une ligne (modèle FIRST-02) sur la confirmation humaine.
  Pattern confirmé par les 5 fichiers déjà présents dans `references/` (`GSD-PIPELINE.md`,
  `mission-flow.md`, `intent-routing.md`, `mission-contracts.md`, `autonomous-guardrails.md`), tous
  chargés on-demand et jamais recopiés dans le corps de `AGENT.md`.
- **D-02:** `references/intent-routing.md` **n'a pas besoin d'une nouvelle ligne** : la ligne existante
  (l.53 : `intègre cette spec à la feuille de route / importe ce plan | gsd-ingest-docs, gsd-import`)
  couvre déjà le routage. Elle est **enrichie** d'un renvoi vers `ingestion-flow.md` pour la doctrine
  (découverte, garde-fous), sur le modèle des renvois déjà présents en bas de fichier (§« Voir aussi »).

### Contrat du manifest et de la délégation (vérifié sur les skills installés, pas supposé)

- **D-03:** Schéma manifest confirmé en lisant `$HOME/.claude/skills/gsd-ingest-docs/SKILL.md` et son
  workflow `$HOME/.claude/get-shit-done/workflows/ingest-docs.md:93-104` : YAML
  `docs: [{path, type, precedence?}]`, `path` relatif à la racine repo, `type` ∈ `ADR|PRD|SPEC|DOC`
  (obligatoire), `precedence` entier optionnel (plus bas = plus prioritaire ; défaut si omis :
  `['ADR','SPEC','PRD','DOC']`). Pour ce module, **seul le grain `spec` produit une entrée manifest**
  (`type: SPEC`), homogène — aucun besoin de `precedence` explicite. Le grain `plan` **ne passe jamais
  par un manifest** : appel direct `gsd-import --from <chemin>` (confirmé par
  `$HOME/.claude/skills/gsd-import/SKILL.md`, argument-hint `--from <filepath>`).
- **D-04:** Le manifest est écrit par l'agent dans un fichier **temporaire hors `.planning/`**
  (`mktemp`), jamais sous `.planning/` — cette zone est réservée aux fichiers que le moteur écrit
  lui-même après ses propres gates. Ce choix évite toute ambiguïté avec ADR-031 (qui protège l'écriture
  des artefacts de planning, pas un fichier d'entrée éphémère).
- **D-05:** `gsd-ingest-docs --mode merge --manifest <f>` — le mode `merge` (jamais `new`, projet déjà
  cadré) est **explicite dans l'appel**, pas seulement documenté (BRDG-03 : « `--mode merge` par défaut
  sur projet existant »).

### Garde-fous BRDG-03 : natifs aux moteurs, pas réimplémentés

- **D-06:** Le gate BLOCKER et la confirmation humaine (`AskUserQuestion` approve-revise-abort) sont
  **déjà portés par `gsd-ingest-docs`/`gsd-import`** (workflow `ingest-docs.md` step `conflict_gate` :
  exit sans écrire PROJECT/REQUIREMENTS/ROADMAP/STATE si `BLOCKERS > 0` ; step `discover_docs` : gate
  d'approbation avant classification ; `import.md` step `plan_conflict_detection` : mêmes sémantiques
  côté plan). Le rôle du plan 13-02 n'est **pas** de recréer ce protocole, mais d'écrire noir sur blanc
  dans `ingestion-flow.md` l'**interdiction de contourner ces gates** (jamais de flag qui les
  court-circuite, jamais de réponse pré-remplie à leur `AskUserQuestion`) — et de documenter le cap 50
  documents (déjà appliqué en interne par `gsd-ingest-docs`, v1 constraint) comme un fait à **signaler**
  à l'utilisateur si le compte de `discover-unintegrated-docs.sh` en approche, pas à re-vérifier en
  double.
- **D-07:** La confirmation humaine **avant tout appel** aux moteurs est portée par le mécanisme déjà
  existant « proposer l'ingestion comme next step » (D-08) : l'agent annonce l'intention (N documents
  trouvés, grains, moteur ciblé) et attend confirmation explicite avant d'invoquer `gsd-ingest-docs` ou
  `gsd-import` — pas de protocole séparé à inventer.

### Next step (réutilisation du mécanisme existant)

- **D-08:** Aucune nouvelle section dans `AGENT.md`. Une clause est ajoutée à la liste d'exemples déjà
  présente en « Next steps & hygiène documentaire » (l.92-100) : *« spec/plan écrit(e) sans être encore
  dans la feuille de route → proposer l'ingestion »*. Le déclencheur est la fin d'un cadrage
  (brainstorm → spec écrite) — moment déjà couvert par la logique « après chaque geste fermé, je
  propose LE next step ».

### Axes de test machine

- **D-09:** Pas de fichier de test dédié (à la différence de 13-01, qui teste un script bash autonome
  avec fixtures `mktemp`). 13-02 modifie des `.md` (doctrine + table de routage) — objet de vérification
  structurellement identique à **T15** (présence de doctrine dans un fichier de référence + renvoi
  croisé depuis un agent). Deux nouveaux axes dans `test-dev-orchestrator.sh`, **T16** et **T17** (T15
  est le dernier pris) :
  - **T16** — `ingestion-flow.md` existe et contient : mention de `discover-unintegrated-docs.sh`, les
    3 exits (0/3/64), le schéma manifest (`type: SPEC`), les 4 garde-fous BRDG-03 textuellement
    (BLOCKER, ADR-031/confirmation humaine, `--mode merge`, cap 50) ; `AGENT.md` renvoie vers ce fichier
    en section Références.
  - **T17** — La table « Amont & cadrage » de `AGENT.md` porte une ligne explicite pour l'intention
    d'ingestion (pas seulement couverte par le comptage générique `intent_lines ≥ 11` de T3) ; et
    `intent-routing.md` conserve sa ligne existante enrichie du renvoi vers `ingestion-flow.md`.
  - T14 (exhaustivité du routage) n'a **rien de nouveau à couvrir** : `gsd-ingest-docs`/`gsd-import`
    sont déjà routés (l.53 d'`intent-routing.md`) — pas de régression attendue, à vérifier en recette
    mais pas un nouvel axe.

### Release-meta du module

- **D-10:** `plugin/dev-orchestrator` : nouvelle **capacité** câblée dans l'agent → bump **mineur**
  (convention `CLAUDE.md` racine : « nouvelle capacité → minor »), `v2.1.1` → **`v2.2.0`**. Les 4
  fichiers : `VERSION`, `module.json` (`"version"`), `CHANGELOG.md` (nouvelle entrée), `README.md`
  (ligne « Version », section « Historique », section « Structure du module » avec le nouveau fichier
  `references/ingestion-flow.md`, section « Références »). **Aucun** bump de la `VERSION` racine ni tag
  (D-08 domain).

### Claude's Discretion

- Formulation exacte de la ligne ajoutée dans la table « Amont & cadrage » d'`AGENT.md` (le plan de
  planification choisira le libellé précis, sous contrainte : verbes NL réels, pas de nom `gsd-*` cru
  hors table de brique — cohérent avec le style des lignes voisines).
- Nom exact des variables internes utilisées par l'agent lors de la construction du manifest (pas de
  contrat machine à vérifier ici, c'est de la prose d'agent).

### Folded Todos

Aucun todo en attente pour la Phase 13 (`gsd-sdk query todo.match-phase "13"` → `todo_count: 0`).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` §Phase 13 (Goal, Success Criteria, Depends on)
- `.planning/REQUIREMENTS.md` BRDG-01, BRDG-02, BRDG-03 (lignes ~168-177)
- `.planning/phases/13-pont-spec-feuille-de-route/13-01-PLAN.md` — contrat exact du script frère
  (sortie, exits, options, variables `VF_INGEST_*`) — **lecture seule, ne pas modifier**
- `plugin/dev-orchestrator/AGENT.md` (152 lignes actuelles, plafond 250 — ADR-029)
- `plugin/dev-orchestrator/references/intent-routing.md` (ligne 53 existante à enrichir)
- `plugin/dev-orchestrator/references/mission-flow.md`, `GSD-PIPELINE.md` — modèles de style pour
  `ingestion-flow.md`
- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` — numérotation T1..T15 prise, T16/T17
  libres
- `plugin/dev-orchestrator/VERSION`, `module.json`, `CHANGELOG.md`, `README.md` (état v2.1.1)
- `$HOME/.claude/skills/gsd-ingest-docs/SKILL.md` + `$HOME/.claude/get-shit-done/workflows/ingest-docs.md`
  — contrat manifest et gates BLOCKER (source de vérité du moteur, hors repo vibeflow-os)
- `$HOME/.claude/skills/gsd-import/SKILL.md` + `$HOME/.claude/get-shit-done/workflows/import.md` —
  contrat `--from` et gates de conflit côté plan (idem, hors repo)
- `docs/superpowers/specs/2026-07-25-routage-fin-verbes-vf-design.md` (§7.2, l.251-264) — schéma
  manifest déjà esquissé lors de la conception de la façade (pré-bascule, cohérent avec le contrat
  vérifié D-03)
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- Pattern « fichier de référence dédié + renvoi depuis AGENT.md » : `mission-flow.md`,
  `GSD-PIPELINE.md`, `autonomous-guardrails.md` sont le gabarit direct pour `ingestion-flow.md` (en-tête
  « chargé on-demand par X », renvoi en fin d'`AGENT.md` §Références).
- `plugin/_internal/vibeflow-update.sh:508,516` copie `$module_dir/references/*` **par wildcard** — un
  nouveau fichier de référence est installé automatiquement, aucune modification de l'installeur requise.

### Established Patterns

- T15 (`test-dev-orchestrator.sh:571-592`) est le gabarit exact pour T16 : vérifie qu'un fichier de
  référence porte une doctrine (greps de mots-clés) ET qu'un fichier consommateur y renvoie
  (`grep -q 'mission-flow'`). À reproduire pour `ingestion-flow.md` ↔ `AGENT.md`.
- Le mécanisme « Next steps & hygiène documentaire » (`AGENT.md:92-100`) est délibérément générique et
  réutilisé pour tout geste fermé — ne jamais dupliquer sa logique dans une nouvelle section.
- Convention de version : `CLAUDE.md` racine — « Nouveau module / nouvelle capacité → minor ; correctif
  / doc / durcissement → patch ». Précédent direct : v2.1.0 (« Pipelining N/N+1 », capacité neuve) a été
  un bump mineur ; v2.1.1 (fixes recette) un patch.

### Integration Points

- `discover-unintegrated-docs.sh` (13-01, EN COURS D'EXÉCUTION EN PARALLÈLE) : point d'entrée FAIT. Le
  plan 13-02 ne le modifie jamais, il consomme son contrat de sortie (`grain<TAB>chemin`, exits 0/3/64)
  tel que figé dans `13-01-PLAN.md`.
- `gsd-ingest-docs` / `gsd-import` : moteurs externes (GSD, hors repo `vibeflow-os`) — le plan délègue,
  ne réimplémente jamais leur logique de classification, de synthèse ou de gate.
</code_context>

<specifics>
## Specific Ideas

Aucune idée particulière hors du périmètre déjà cadré par le mandat et le ROADMAP — la portée est
entièrement dérivée de BRDG-01/BRDG-03 et des interdits doctrinaux (pas de façade, ADR-029/031/044).
</specifics>

<deferred>
## Deferred Ideas

- **Critère de succès 5 du ROADMAP** (release livrée : bump racine + tag annoté poussé) — explicitement
  hors du plan 13-02 par mandat, à traiter en validation humaine post-plan.
- **`--resolve interactive`** de `gsd-ingest-docs` — réservé à une future version du moteur
  (v1 constraint documentée dans son propre `SKILL.md`), rien à câbler côté `vibeflow-dev`.
- Aucun todo en attente n'a été revu/rejeté (aucun todo trouvé pour la Phase 13).

[Aucune autre idée différée — l'analyse est restée dans le périmètre de la phase.]
</deferred>
