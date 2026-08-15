# Phase 9: Spike transposition jcode (mémoire + swarm) - Context

**Gathered:** 2026-07-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Spike **R&D** (hors chaîne de release) qui livre une **décision go/no-go** écrite sur la
transposition du modèle mémoire riche de jcode dans le skill `consolidator`. On prototype un
sous-ensemble minimal du frontmatter mémoire + une règle de décroissance par catégorie sur **un
lab témoin**, on mesure le coût de maintenance réel, et on tranche : (a) écrire un ADR + toucher le
format mémoire officiel, ou (b) archiver.

**Ne produit PAS** : de release, de changement du format mémoire officiel de VibeFlow, ni
d'implémentation du volet swarm. Le socle `conductor` n'est pas touché sans ADR.
</domain>

<decisions>
## Implementation Decisions

### Lab témoin
- **D-01:** Prototyper sur **ce repo (vibeflow-os)** — sa mémoire de session
  (`~/.claude/projects/-Users-samuel-Documents-dev-vibeflow-os/memory/`, dont `MEMORY.md` +
  `projet-alpha-emplacement.md`). Boucle courte, zéro risque sur un lab de prod. Contrepartie assumée :
  peu d'entrées → signal de coût de maintenance faible ; compenser en ajoutant quelques entrées
  synthétiques calibrées (mix des 4 catégories) si nécessaire pour rendre la mesure significative.

### Périmètre du spike
- **D-02:** **Mémoire + cadrage swarm léger.** Le cœur est le spike mémoire. En complément, produire
  un **mini-cadrage écrit** du volet swarm (lock de driver unique RAII + DAG ready/blocked) — **écrit,
  NON implémenté** — pour que les deux volets soient prêts à décider ensemble. L'invariant tient : le
  swarm reste non implémenté tant que des collisions ne sont pas observées sur les backups isolés
  (ADR-048/049).

### Set de champs à prototyper
- **D-03:** **Minimal — 3 gestes** : `trust` (high/medium/low), `confidence` (0–1) + règle de
  **décroissance par catégorie** dans `consolidator`, et `superseded_by` (supersession non
  destructive). On **exclut** `reinforced[]` (breadcrumbs) et les arêtes typées `Contradicts`/
  `DerivedFrom` de ce spike — pour ne pas biaiser le go/no-go vers « trop cher ». Ils restent des
  candidats pour l'ADR si le spike est concluant.
- **D-04:** Demi-vies de départ = valeurs jcode (Correction 365 j / Preference 90 j / Fact 30 j /
  Entity 60 j) MAIS **recalibrées** pour l'usage VibeFlow multi-métiers en sortie de spike (les labs
  ne sont pas que du code). La recalibration est un **livrable de la note go/no-go**, pas un préalable.

### Barre de décision go/no-go
- **D-05:** Critère **binaire et vérifiable** : une passe `consolidator` **lit → recalcule →
  réécrit** les 3 champs sur **toutes** les entrées du lab témoin **sans édition humaine**, ET une
  entrée marquée `superseded_by` est correctement **archivée** (statut basculé, contenu conservé —
  pas supprimée). Si les deux sont vrais → **go ADR**. Sinon → **no-go documenté** (avec la raison).

### Claude's Discretion
- Le mapping exact entre les catégories jcode (`Fact/Preference/Entity/Correction`) et les `type`
  VibeFlow existants (`user/feedback/project/reference`) est laissé au planner/researcher — à
  proposer, pas à imposer.
- La forme précise du frontmatter enrichi (noms de clés YAML) est ouverte, tant qu'elle reste sous
  les seuils de densité ADR-029.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Note de cadrage (source primaire de cette phase)
- `.planning/research/jcode-memory-swarm-transposition-NOTE.md` — dissection des modules jcode
  `memory/` et `communicate/`, modèle de données `MemoryEntry`, verdict adopter/différer/rejeter,
  et tableau de synthèse. **À lire en premier.**

### Source externe (référence, pas à installer)
- `https://github.com/1jehuang/jcode` @ `master` — spécifiquement `crates/jcode-memory-types/src/lib.rs`
  (`MemoryEntry`, `TrustLevel`, `effective_confidence`, demi-vies) et `graph.rs` (`EdgeKind`).

### Doctrine VibeFlow à respecter
- `CLAUDE.md` (racine repo) — densité ADR-029 (skills ≤ 500 lignes), « jamais de fix sans validation
  humaine » (ADR-031), discipline de release (toute version = un tag).
- ADR-048 / ADR-049 — backups isolés (contexte du volet swarm différé). *(Chemin exact à confirmer au
  research — référencés dans l'historique git / le module conductor.)*

### Cible du prototype
- Skill `consolidator` (module conductor) — c'est le composant qui doit tenir les nouveaux champs à
  jour automatiquement. *(Localiser le SKILL.md exact au research — probablement
  `plugin/conductor/.../consolidator/`.)*
- Mémoire de session témoin : `~/.claude/projects/-Users-samuel-Documents-dev-vibeflow-os/memory/`
  (`MEMORY.md` + fichiers d'entrées).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Skill `consolidator`** : consolide déjà la mémoire structurée d'un lab sur 4 piliers
  (Indexation / DECISIONS / LEARNINGS / BLOCKERS…). La décroissance de confiance et la supersession
  s'ajoutent comme **règles du pilier Indexation** — pas un nouveau composant.
- **Format mémoire fichier existant** : frontmatter `name`/`description`/`metadata.type` +
  corps avec liens `[[slug]]`. Le graphe de liens existe déjà — il manque le **typage** des champs.

### Established Patterns
- Une entrée = un fichier `.md` + une ligne d'index dans `MEMORY.md`. Le spike doit préserver ce
  contrat (pas de base binaire, pas d'embeddings — hors runtime Claude Code).
- Supersession non destructive s'aligne nativement avec ADR-031 (jamais de destruction sans humain).

### Integration Points
- Le `consolidator` lit/écrit les fichiers `memory/*.md` et `MEMORY.md`. C'est le seul point de
  couplage du spike. Aucun hook par-tour (le pipeline 4-étapes de jcode est **différé** → travail
  par passe consolidator, pas par tour).
</code_context>

<specifics>
## Specific Ideas

- Reproduire la **récupération de claim périmé** de jcode dans le cadrage swarm : un `vf-dev-manager`
  qui meurt ne doit pas laisser un lock mort qui gèle les missions (point de vigilance explicite).
- Garder le critère go/no-go **binaire** (D-05) pour éviter une décision floue : le spike réussit ou
  échoue mécaniquement, la valeur qualitative est un bonus documenté, pas le juge.
</specifics>

<deferred>
## Deferred Ideas

- **Volet swarm — implémentation** (lock de driver unique + DAG ready/blocked dans `vf-dev-manager`)
  → propre phase, conditionnée à des collisions observées sur les backups isolés (ADR-048/049). Cette
  phase 9 n'en produit que le **cadrage écrit**.
- **Champs mémoire étendus** : `reinforced[]` (breadcrumbs), arêtes typées `Contradicts`/`DerivedFrom`,
  clusters → candidats pour l'ADR si le spike minimal est concluant, hors périmètre du spike.
- **Pipeline mémoire par-tour** (search→verify→inject→maintain) → nécessiterait un runtime que Claude
  Code n'expose pas ; rejeté pour VibeFlow-sur-Claude-Code.
- **Embeddings / RRF / sidecar de verify** → rejeté (pas de runtime intra-session).

</deferred>

---

*Phase: 9-Spike transposition jcode (mémoire + swarm)*
*Context gathered: 2026-07-20*
