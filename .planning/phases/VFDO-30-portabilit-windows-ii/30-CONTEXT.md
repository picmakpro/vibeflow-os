# Phase 30: Portabilité Windows II - Context

**Gathered:** 2026-08-15
**Status:** Ready for planning — PORT-04 tranché par Samuel le 2026-08-15 (voir D-01) : le plan est dégaté.

<domain>
## Phase Boundary

Réécrire une fois pour toutes le substrat des hooks pour qu'une install VibeFlow sur Windows pose
des hooks qui fonctionnent : (a) `merge-hooks.sh` apprend la forme exec (`args`), (b) les codes de
sortie des scripts de hooks sont normalisés (0 = silence à la frontière harness), (c) les
`hooks.json` du périmètre dev passent en forme exec, (d) la lib partagée `vf-portable.sh` est
**écrite par cette phase** (conforme au contrat PR #29, tracer 01-01 absorbé — D-04) et les 3
fichiers du lot PYBIN la consomment. Plus deux gestes jour 1 asynchrones : la RFC
upstream `open-gsd/gsd-core` (LEDG-03) et la veille de release gsd-core > 1.10.0 (WKTR-03).

Hors scope : migration des hooks.json de la polarité gouvernance (Willy), partition workstreams,
toute autre migration de forme que celle de la spec.

</domain>

<decisions>
## Implementation Decisions

### PORT-04 — Affectation §3.2 (chemin absolu de bash dans merge-hooks.sh)
- **D-01:** **TRANCHÉ par Samuel le 2026-08-15, sans Willy** (le tracer 01-01 n'a jamais été
  livré, la discussion n'a pas pu avoir lieu) : **la Phase 30 porte l'intégralité du volet
  `merge-hooks.sh`** — apprentissage d'`args` (substitution, `frag_basenames()`, `references()`,
  `remove`) ET résolution du chemin absolu de `bash` à l'install. PORT-04 est satisfait : la
  décision est documentée ici, dans l'amendement de la spec (§3.2) et par commentaire informatif
  sur la PR #29 (draft validé par Samuel avant post — geste externe gaté humain).
  — **Reversibility:** one-way — le `settings.json` produit devient spécifique à la machine chez
  chaque utilisateur qui update ; revenir en arrière exigerait une migration inverse du parc.
- **D-02:** Exit code de `vf_guard_unavailable` sur PreToolUse : **décision maison — code non nul
  ≠ 2** (« dégradé mais utilisable » : l'erreur est visible, l'édition passe). Aligné ADR-031
  (advisory par défaut) — un lab sans Python reste utilisable, la garde hurle sans paralyser.
- **D-03:** Documentation de la décision PORT-04 : **amendement de la spec**
  (`docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md`, encart « tranché le
  2026-08-15 » au §3.2) **+ commentaire informatif sur la PR #29** (visible par Willy). Fait au
  cadrage.

### Dépendance au contrat PR #29 (lot PYBIN)
- **D-04:** **On n'attend plus Willy : la Phase 30 écrit elle-même `vf-portable.sh`**
  (`plugin/_internal/lib/`) **et `copy_engine_lib()`** dans `vibeflow-update.sh`, en conformité
  stricte avec le contrat d'interface de la PR #29 (5 symboles, bloc localisateur à 4 candidats
  entre marqueurs, sémantique `vf_py_probe`). La phase absorbe le tracer 01-01. Si le gate de
  Willy arrive un jour, il doit passer au vert puisque le contrat est suivi à la lettre.
  — **Reversibility:** costly — si le contrat de la PR #29 évolue avant merge, lib et
  consommateurs doivent être réalignés (sommes de contrôle du bloc localisateur recalculées).
- **D-05:** La dépendance dure de `guard-file-size.sh` est **levée par D-04** pour la lib et
  `vf_guard_unavailable`. Reste le **hook doctor de conductor** (agrégation des marqueurs
  `$VF_GUARD_HEALTH_DIR` + escalade après 3 sessions, contrat §4) : la Phase 30 en livre une
  **version minimale** (agrégation en une ligne au SessionStart) ou le diffère avec reliquat tracé
  — au choix du planner sur pièces. Les marqueurs s'accumulent sans casse tant que le doctor
  n'existe pas.

### Codes de sortie (PORT-03)
- **D-06:** Traduction vers le harness : **normalisation dans chaque script** (0 = cas silencieux,
  non nul = vraie erreur) — pas de lanceur `run-hook.sh` (l'indirection shell sous Windows
  contredirait l'objectif de la forme exec). Le contrat interne exit 3 (Phase 17) reste valide *à
  l'intérieur* des scripts ; c'est la sortie vers le harness qui devient 0.
- **D-07:** Périmètre de la normalisation : **tout le parc — les 25 entrées réelles** (gouvernance
  incluse), même si seules les entrées dev passent en forme exec dans cette phase. Willy hérite
  d'un parc déjà propre pour sa migration.
- **D-08:** Écart d'inventaire (19 annoncées roadmap / 22 spec / **25 réelles constatées au
  cadrage** : conductor 6, consolidator 7, dev-orchestrator 4, infrastructure-audit 1,
  planning-core 6, software-architecture 1) : **l'inventaire du plan fait foi** — recompter,
  documenter événement + classement advisory/bloquant par entrée, mettre à jour les chiffres de la
  spec au passage. Pas d'audit préalable de légitimité des entrées apparues depuis la spec.

### Gestes jour 1 (LEDG-03 + WKTR-03)
- **D-09:** RFC upstream `open-gsd/gsd-core` (suppression de `REQUIREMENTS.md` rendue optionnelle) :
  **draft produit par le plan, validé par Samuel avant tout post public** (issue GitHub). Deadline
  amont : 2026-10-26.
- **D-10:** Veille gsd-core > 1.10.0 : **hook SessionStart advisory avec cache quotidien**
  (`npm view @opengsd/gsd-core version`, jamais le dist-tag `next`) qui signale la release —
  déclencheur tracé de la Phase 35. Attention distribution (mémoire « armement sans précondition
  distribuée ») : préciser au plan si le hook est repo-local (`.claude/` de ce repo — suffisant, la
  Phase 35 concerne ce repo) ou distribué.
- **D-11:** Traçabilité de la RFC : lien de l'issue upstream écrit dans **STATE.md (décision datée)
  + ligne LEDG-03 de REQUIREMENTS.md** — les deux endroits où la Phase 18 ira le chercher.

### Claude's Discretion
- Séquencement fin des vagues (a) moteur → (b) codes de sortie → (c) hooks.json — l'ordre est
  imposé par la spec §2, le découpage en plans est libre.
- Détail d'implémentation de la veille (format du cache, emplacement du script).
- Extension des suites de tests (mutations discriminantes, sonde de parc §4 de la spec).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Spec de la phase
- `docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md` — LA référence : périmètre
  (3 fichiers PYBIN, entrées hooks dev), analyse ligne-par-ligne de `merge-hooks.sh` (§1.3, §3.2),
  ordre imposé (a)→(b)→(c), tests par mutation (§4), critères de succès. Le statut « ⏸ EN
  ATTENTE » de l'en-tête est caduc : la phase est inscrite au milestone fiabilite-v1.0.

### Contrat de portabilité (amont, PR ouverte)
- PR #29 (`gh pr view 29`) — `docs/CONTRAT-PORTABILITE.md` (173 lignes, dans la PR, PAS sur main) :
  les 5 symboles de `vf-portable.sh`, bloc localisateur à 4 candidats entre marqueurs
  `# >>> vf-portable:locator`, gate par somme de contrôle, exigence §5 (chemin absolu bash),
  question ouverte exit code `vf_guard_unavailable`.

### Doctrine et antécédents
- ADR-054 (2026-07-23) — premier temps portabilité Windows : CRLF, préflight, gate synchro — reste
  tel quel ; cette phase est le second temps. Un ADR de suite pour la forme exec est probablement
  justifié (spec §5).
- ADR-031 — advisory par défaut : fonde D-02/D-06 (un hook qui échoue ne bloque ni ne pollue).
- Contrat de signaux Phase 17 (exit 3 = silence interne) — reste valide en interne aux scripts.

### Fichiers de code au cœur de la phase
- `plugin/_internal/merge-hooks.sh` — `SCRIPT_RE` l.106, `frag_basenames()` l.108, `references()`
  l.117, substitution l.168 : tout le §3.2 s'ancre là. Régression lookaround à conserver telle
  quelle.
- `plugin/_internal/tests/test-merge-hooks.sh`, `plugin/_internal/tests/test-windows-crlf.sh`,
  `plugin/consolidator/scripts/tests/test-windows-guards.sh` — les 3 suites à garder vertes puis
  étendre.
- Lot PYBIN dev : `plugin/software-architecture/scripts/guard-file-size.sh` (variante A, gaté D-05),
  `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` (variante B, actif en production),
  `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (variante B, non mentionné au
  contrat — à signaler).
- Les 6 `plugin/*/hooks/hooks.json` — 25 entrées réelles (recomptées au cadrage 2026-08-15).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Les 3 suites de tests existantes (ci-dessus) avec convention repo « discrimination par
  mutation » — un test vert sous mutation ne prouve rien.
- `.planning/codebase/CONCERNS.md` — préoccupations connues du parc, à recouper par le researcher.

### Established Patterns
- Gates à trois issues (PASS / FAIL / imparsable BRUYANT) + mutation rouge prouvée — QUAL-01
  transverse s'applique à tout gate né dans cette phase.
- Compatibilité descendante non négociable de `merge-hooks.sh` : lire, dédupliquer et retirer la
  forme shell reste obligatoire (c'est ce que porte le parc installé).

### Integration Points
- `plugin/_internal/vibeflow-update.sh` (l.252-270 : résolution d'`inject-mcp-tools.sh`) —
  l'engine qui posera `vf-portable.sh` via `copy_engine_lib()` (à créer **dans cette phase**, D-04).
- Gate de Willy (sommes de contrôle du bloc localisateur) — critère de succès externe n°0 :
  avertissement jusqu'au merge de cette phase, bascule bloquante dans le même commit que le dernier
  lot (spec §7).

</code_context>

<specifics>
## Specific Ideas

- Le « jour 1 » des gestes LEDG-03/WKTR-03 s'entend jour 1 du *travail* du milestone — la RFC passe
  par un draft validé par Samuel (D-09), la rapidité ne court-circuite pas le gate humain.
- L'effet de bord §3.2 (le `settings.json` produit devient spécifique à la machine) est assumé
  (D-01, one-way) et mentionné dans le commentaire informatif PR #29 pour que Willy le voie.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. (Les 14 fichiers PYBIN gouvernance, le volet Python de
`merge-hooks.sh`/`preflight.sh` et les 20 entrées hooks gouvernance restent à Willy, comme au
contrat §7.)

</deferred>

---

*Phase: 30-Portabilité Windows II*
*Context gathered: 2026-08-15*
