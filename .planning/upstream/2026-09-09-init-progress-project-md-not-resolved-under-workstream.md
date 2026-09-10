> ## ⛔ BANDEAU DE STATUT — pour nos agents, PAS pour l'amont
>
> **Ce texte est rédigé et prêt à poster. Il n'a PAS été posté.** Son **dépôt est réservé à
> validation humaine** (**ADR-031**) : aucun agent ne l'ouvre en issue, aucun appel d'API de forge
> n'est exécuté. Le corps ci-dessous commence à la ligne « --- » et est **en anglais**, langue du
> dépôt amont ; ce bandeau est le seul passage en français et **ne fait pas partie du texte à
> poster**.
>
> **Ceci EST un rapport de comportement fautif** — pas la forme du précédent **#2598** (« descriptive
> gap », capacité qui fait ce qu'elle est codée pour faire). `#2598` est cité ci-dessous uniquement
> comme **antériorité de FORME acceptée en amont** (issue bien reçue, bien structurée), jamais comme
> le cadrage de CE rapport : ici, une commande officielle de résolution de portée (`init.progress`)
> renvoie un résultat mesurablement faux pour un fichier que la migration officielle a laissé en
> place. C'est l'angle que portait `GSDA-19` sous #2598 ; il vit désormais ici, sous `PART-06`
> (Phase 39, 2026-09-09), après supersession explicite dans notre propre ledger.
>
> **Mesuré le 2026-09-09**, sur `@opengsd/gsd-core` **1.13.0**. Reproduit trois fois avant rédaction.

---

# `init.progress --ws <name>` reports `project_exists: false` for a `PROJECT.md` the official migration left in place

## Summary

`workstream.create` migrates a repository into a partitioned layout via `migrateToWorkstreams`
(`workstream.cjs:46-94`), moving `ROADMAP.md`, `STATE.md`, `REQUIREMENTS.md`, and `phases/` under
`.planning/workstreams/<name>/`, while deliberately leaving `PROJECT.md`, `config.json`,
`milestones/`, `research/`, `codebase/`, and `todos/` at the repository root. This is the
documented, official shape of a migrated repository.

`init.progress`, when called with `--ws <name>`, does not know about that shape for `PROJECT.md`.
It reports the project as non-existent even though the file is present exactly where the migration
left it.

The root cause is call-site inconsistency across three modules composing the same logical path
differently: `planningDir` (scoped to the workstream) in `init.cjs`, versus `planningRoot`
(repository root) in `planning-snapshot.cjs:447`, versus a hard-coded `path.join` in
`profile-output.cjs:303`. `config.json` already solves this with a working scoped-to-root
federation (`planning-workspace.cjs:249-260`); `PROJECT.md` has no equivalent fallback.

## Reproduction

```
gsd_run query init.progress --ws default
```

renders:

```
project_exists: false
```

against a repository where `.planning/PROJECT.md` exists, unmoved, at the path the official
migration left it — `.planning/workstreams/default/PROJECT.md` does not exist and was never meant
to, per the migration's own documented file list.

## What we are asking for

Extend the root-fallback federation `config.json` already has (`planning-workspace.cjs:249-260`)
to cover `PROJECT.md` as well: when a workstream-scoped `PROJECT.md` is absent, resolve to the
repository-root `PROJECT.md` before declaring `project_exists: false`. This mirrors the exact
mechanism already proven correct for `config.json`, applied to the one other root-resident file the
official migration deliberately does not move.

## Prior art and non-duplication

- **#2598** — closest precedent for accepted *form* (a well-received, well-structured issue), not
  for framing: `#2598` reported a descriptive gap ("the capability does what it's coded to do, but
  the documented surface doesn't describe it"). This report is different in kind: a command returns
  a factually wrong answer (`project_exists: false`) about a file that is actually present. The form
  is reused; the framing is not.
- No open issue found addressing `PROJECT.md`'s specific absence from the root-fallback federation
  `config.json` already has.

*Measured on `@opengsd/gsd-core` 1.13.0, 2026-09-09.*
