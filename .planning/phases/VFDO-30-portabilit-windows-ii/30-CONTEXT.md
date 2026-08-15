# Phase 30: Portabilité Windows II - Context

**Gathered:** 2026-08-15
**Status:** Ready for planning — **SAUF PORT-04** (gate de plan : l'affectation §3.2 doit être tranchée avec Willy et documentée AVANT le plan — voir D-01)

<domain>
## Phase Boundary

Réécrire une fois pour toutes le substrat des hooks pour qu'une install VibeFlow sur Windows pose
des hooks qui fonctionnent : (a) `merge-hooks.sh` apprend la forme exec (`args`), (b) les codes de
sortie des scripts de hooks sont normalisés (0 = silence à la frontière harness), (c) les
`hooks.json` du périmètre dev passent en forme exec, (d) les 3 fichiers du lot PYBIN consomment la
lib partagée `vf-portable.sh` (contrat PR #29). Plus deux gestes jour 1 asynchrones : la RFC
upstream `open-gsd/gsd-core` (LEDG-03) et la veille de release gsd-core > 1.10.0 (WKTR-03).

Hors scope : migration des hooks.json de la polarité gouvernance (Willy), partition workstreams,
toute autre migration de forme que celle de la spec.

</domain>

<decisions>
## Implementation Decisions

### PORT-04 — Affectation §3.2 (chemin absolu de bash dans merge-hooks.sh)
- **D-01:** L'affectation §3.2 n'a **pas encore été discutée avec Willy** — la discussion est à
  lancer. **Le plan de phase reste gaté tant que la réponse n'est pas écrite** (exigence PORT-04 :
  « tranchée et documentée avant le plan »). Geste immédiat de sortie de cadrage : rédiger le
  commentaire pour la PR #29 posant la question d'affectation (draft validé par Samuel avant tout
  post — geste externe gaté humain).
- **D-02:** Exit code de `vf_guard_unavailable` sur PreToolUse : **pas de position maison — à faire
  trancher par le contrat** (PR #29). La question est poussée dans le même commentaire que D-01 ;
  le plan hérite de ce que le contrat écrira.
- **D-03:** Documentation de la décision PORT-04 une fois tranchée : **amendement de la spec**
  (`docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md`, encart « tranché le… » au
  §3.2) **+ commentaire sur la PR #29** (visible par Willy). Le CONTEXT/plan la reprennent.

### Dépendance au contrat PR #29 (lot PYBIN)
- **D-04:** Le lot PYBIN **s'implémente contre le contrat tel qu'écrit dans la PR #29 ouverte**
  (sans attendre le merge ni la livraison de `vf-portable.sh` sur `main`) — risque de rebase
  accepté si le contrat bouge avant merge. — **Reversibility:** costly — si le contrat change
  (noms de symboles, bloc localisateur), chaque fichier consommateur édité doit être realigné et
  les sommes de contrôle du gate de Willy recalculées.
- **D-05:** `guard-file-size.sh` est **gaté séparément** si la lib tarde (dépendance dure :
  `vf-portable.sh` + `vf_guard_unavailable` + `$VF_GUARD_HEALTH_DIR` + hook doctor conductor,
  aucun n'existant à ce jour) : la phase peut se clore avec ce fichier non migré, exigence tracée
  en reliquat explicite (`carried` trace), jamais un vert par défaut.

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
  l'engine qui posera `vf-portable.sh` via `copy_engine_lib()` (à créer, côté Willy/gouvernance).
- Gate de Willy (sommes de contrôle du bloc localisateur) — critère de succès externe n°0 :
  avertissement jusqu'au merge de cette phase, bascule bloquante dans le même commit que le dernier
  lot (spec §7).

</code_context>

<specifics>
## Specific Ideas

- Le « jour 1 » des gestes LEDG-03/WKTR-03 s'entend jour 1 du *travail* du milestone — la RFC passe
  par un draft validé par Samuel (D-09), la rapidité ne court-circuite pas le gate humain.
- L'effet de bord §3.2 (le `settings.json` produit devient spécifique à la machine) est à instruire
  explicitement dans le commentaire PR #29 — Willy doit le voir avant de trancher.

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
