# RFC upstream — `open-gsd/gsd-core` (LEDG-03)

## Statut

**postée le 2026-08-15 — https://github.com/open-gsd/gsd-core/issues/3556**

Brouillon validé par Samuel tel quel (D-09, AskUserQuestion 2026-08-15, relayée par la session
principale) avant tout post public. Corps posté vérifié bit-à-bit identique au corps validé
(`gh issue view --json body` diffé contre la section « Corps de l'issue » ci-dessous — aucune
différence). Aucune RFC équivalente ne préexistait (consultation en lecture seule menée avant
rédaction : `gh search issues --repo open-gsd/gsd-core` sur "REQUIREMENTS.md", "git rm
REQUIREMENTS", "keep-requirements", "optional deletion milestone complete" — aucun résultat
pertinent).

Traçabilité D-11 posée aux deux endroits : `.planning/REQUIREMENTS.md` (ligne LEDG-03 du tableau +
puce de section) et `.planning/STATE.md` (§Decisions, entrée du 2026-08-15, avec le repli
GO-RÉDUIT écrit).

**Version `@opengsd/gsd-core` relevée sur ce poste** : `1.10.0` (fichier `~/.claude/gsd-core/VERSION`).
Commande de relevé : `cat ~/.claude/gsd-core/VERSION` (aucun `package.json` accessible localement
pour ce paquet — la version installée fait foi).

---

## Corps de l'issue

### Title

`Make REQUIREMENTS.md deletion optional at milestone completion (currently unconditional)`

### Observed behavior

In `~/.claude/gsd-core/workflows/complete-milestone.md` (v1.10.0, as installed), the
`reorganize_roadmap_and_delete_originals` step deletes `.planning/REQUIREMENTS.md` **unconditionally**
after archiving it. Exact lines (relative to the installed workflow file):

- Step `archive_milestone` documents the behavior in prose (line 433):
  > "Safety commit of archive files + updated ROADMAP.md, then `git rm .planning/REQUIREMENTS.md`"
- Step `reorganize_roadmap_and_delete_originals` executes it (lines 498-501):
  ```
  **Remove REQUIREMENTS.md via git rm** (preserves history, stages deletion atomically):

  git rm .planning/REQUIREMENTS.md
  ```
- The archival contract earlier in the same file states the design intent explicitly (line 30):
  > "Archives keep ROADMAP.md constant-size and REQUIREMENTS.md milestone-scoped."

There is no flag, gate, or `AskUserQuestion` guarding this deletion. The one flag the workflow
does expose, `--no-archive-phases` (lines 420-424), controls whether phase directories are
archived — it has no effect on `REQUIREMENTS.md`. No `--keep-requirements` (or equivalent)
option exists.

On the other end of the milestone cycle, `~/.claude/gsd-core/workflows/new-milestone.md` (line
~475, "Generate REQUIREMENTS.md:") regenerates the file from scratch for the next milestone, with
an empty traceability section. The only thing that survives across milestones today is requirement
ID numbering — the file itself is destroyed, then recreated, never amended.

### Why this is a problem

`REQUIREMENTS.md` is the only living register of "what this system currently guarantees." Once a
milestone closes, any requirement that was tracked but not yet delivered (deferred, partially
done, or superseded) loses its home: it exists only inside a dated, milestone-scoped archive
(`milestones/v[X.Y]-REQUIREMENTS.md`), never merged forward into the next milestone's ledger.

This is not a hypothetical gap. In this repo (`vibeflow-os`), the milestone `agentique-v1.0`
closed on 2026-08-15 with two requirements not delivered — internally tracked as requirement IDs
`18` and `25` — that had to be manually carried forward into the next milestone's roadmap, outside
of any tooling. The deletion-then-regeneration cycle in `complete-milestone.md` /
`new-milestone.md` gives no structural support for this carry-forward; it happens only because a
human noticed and did it by hand. A team relying purely on the documented workflow would silently
lose track of undelivered requirements at every milestone boundary.

### Proposal

Make the deletion of `.planning/REQUIREMENTS.md` at milestone completion **optional**, so that
projects that want the ledger to persist across milestones can opt in to keeping it. We are
deliberately not prescribing the mechanism — plausible options include (any of these, or another
approach the maintainers prefer):

- A config flag (e.g. `workflow.keep_requirements_on_milestone_complete`) that, when true, skips
  the `git rm` step and instead updates in-place statuses for delivered/carried-over requirements.
- A `--keep-requirements` CLI flag on `milestone complete`, symmetric to the existing
  `--no-archive-phases`.
- Built-in roll-over: undelivered requirement rows survive into the next milestone's
  `REQUIREMENTS.md` automatically, tagged with a `carried-from:` marker, while delivered rows are
  archived as today.

This is a request for a capability, not a specific implementation — the maintainers are better
placed to decide which shape fits the existing archival design.

### What this repo does in the meantime

We are not blocked on this RFC landing. We have already scoped a reduced local workaround (verdict
**GO-RÉDUIT**, decided 2026-07-28, full study in this repo's
`.planning/phases/VFDO-18-survie-du-ledger-d-exigences-la-cl-ture-de-jalon/STUDY.md`): a local gate
script that fails only when `.planning/MILESTONES.md` declares a milestone closed while
`.planning/REQUIREMENTS.md` is absent (absence-only detection, never "hasn't moved"), plus a
doctrine line documenting that the ledger is meant to survive milestone closure locally. This local
workaround does not require any upstream change — it is a stopgap layered on top of the existing
unconditional deletion, not a replacement for it. If this RFC is rejected or times out, we keep
this reduced local variant, re-arbitrated as needed (see "Fallback" below) — this issue is not a
blocker for our own progress, and we want maintainers to see that up front.

### Deadline (requester side)

**2026-10-26.** Internally, we have a dependent piece of work that reaches its own gate decision
on this date: if this RFC has not landed (or received a maintainer signal) by then, our fallback
plan (below) is what we execute instead — without waiting further.

---

## Traçabilité à poser après le post (D-11)

**Reliquat assumé** : ce plan (30-02) ne peut pas écrire ces deux traces maintenant — le lien de
l'issue n'existe qu'après le post, qui est gaté humain (D-09, tâche 2 du plan) et hors du périmètre
de fichiers autorisé pour ce mandat (`.planning/REQUIREMENTS.md` et `.planning/STATE.md` ne sont
pas dans le périmètre écrit ici). Texte exact à insérer aux deux endroits une fois l'issue postée,
`<URL_ISSUE>` étant l'URL réelle de l'issue GitHub :

### 1. `.planning/REQUIREMENTS.md` — ligne LEDG-03 du tableau de traçabilité (actuellement ligne 839)

Remplacer :
```
| LEDG-03 | Phase 30 | Pending — geste jour 1 (RFC upstream, deadline amont 2026-10-26) |
```
par :
```
| LEDG-03 | Phase 30 | Ouverte le <DATE_POST> — <URL_ISSUE> — deadline amont 2026-10-26 |
```

Et dans la section « Survie du ledger d'exigences » (actuellement ligne 934), compléter la puce
`LEDG-03` avec le lien :
```
- [ ] **LEDG-03**: La RFC upstream est ouverte dès le jour 1 du milestone (deadline amont
  2026-10-26) — <URL_ISSUE>, ouverte le <DATE_POST>.
```

### 2. `.planning/STATE.md` — section « Decisions », nouvelle entrée datée

```
- <DATE_POST> : **RFC upstream `open-gsd/gsd-core` déposée** (LEDG-03) — <URL_ISSUE>. Demande : rendre
  optionnelle la suppression inconditionnelle de `.planning/REQUIREMENTS.md` à la clôture de
  jalon (`complete-milestone.md`, `git rm` sans flag ni gate). Échéance amont : **2026-10-26**.
  **Repli si l'amont refuse ou ignore avant l'échéance** : la variante réduite locale déjà arbitrée
  le 2026-07-28 (`STUDY.md`, verdict GO-RÉDUIT, condition D3) — un gate local d'absence
  (`.planning/MILESTONES.md` déclare un jalon clos alors que `.planning/REQUIREMENTS.md` est
  absent) doit alors être intégralement ré-arbitré : soit renoncement au gate (doctrine seule,
  sans machine), soit acceptation assumée d'un gate en conflit récurrent avec `complete-milestone`
  (le moteur continuerait de supprimer le fichier à chaque clôture, sans le flag demandé par cette
  RFC). Ce repli est écrit ici au moment du dépôt, pas découvert à l'échéance (Phase 18 n'a pas à
  re-décider dans l'urgence).
```
