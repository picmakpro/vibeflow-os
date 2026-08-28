---
name: gsd-tools-ecrase-state
description: gsd-tools query state.* réécrit le frontmatter de .planning/STATE.md et fait régresser les compteurs progress — relire et restaurer après tout appel, ou interdire l'outil aux workers
metadata:
  type: project
---

`gsd-tools query state.record-session` (et les autres verbes `state.*`) **réécrit le frontmatter de
`.planning/STATE.md`** et fait **régresser les compteurs `progress`**. Régressions mesurées le
2026-07-28 sur ce repo : `total_phases` 19→18, `completed_phases` 10→8, `total_plans` 50→39,
`completed_plans` 34→19 — plus une bannière narrative rétrogradée à « 50% ». **Trois occurrences dans
la même journée** (cadrage, puis exécution du plan 19-02 : commits de restauration `ef8826c`,
`f9a0f45`, `63aca55`).

**Why — mécanisme établi sur pièce le 2026-07-31** (gsd-core 1.9.0, reproduit à l'identique en bac à
sable ; l'explication « il recalcule depuis le ROADMAP » qui figurait ici était FAUSSE). Deux causes
distinctes, à ne jamais confondre :

- **Compteurs** — `buildStateFrontmatter` (`bin/lib/state.cjs:1494-1501` + `plan-scan.cjs:158`) ne
  compte QUE les paires **`NN-MM-PLAN.md` ↔ `NN-MM-SUMMARY.md` présentes sur le disque**, et n'a
  **aucun repli sur le ROADMAP** — alors que `roadmap analyze` (`roadmap.cjs:353-355`) l'a. Deux
  définitions de « phase complète » dans le même moteur. Nos phases 11/12/13/14 sont shippées **sans
  aucun SUMMARY** : le moteur ne peut pas savoir qu'elles sont finies. Ses chiffres sont *justes selon
  sa règle* — c'est une **dette d'artefact locale**, pas un bug amont.
- **`current_phase`** — `stateExtractField(bodyContent, 'Phase')` (`state-document.cjs:214`) prend le
  **premier `^Phase:` du corps entier, sans scope**, donc une ligne d'archive. **Vrai bug amont** :
  la même fonction scope pourtant `Stopped At` et `Paused At` à `## Session`.

Déclencheur : `state record-session`, appelé par `workflows/discuss-phase.md`, `execute-plan.md`,
`milestone-summary.md`, `ui-phase.md`… `cmdStateRecordSession` appelle `readModifyWriteStateMd` **sans
`options`**, et `state.cjs:2024` fait `resync = !options || options.resync !== false` → **resync forcé,
non désactivable**. Perte silencieuse : rien n'échoue, et le chiffre faux est indiscernable du juste
sans la baseline. Les commentaires YAML curés à la main sont détruits au passage.

Symptôme adjacent, non destructif : `state.advance-plan` échoue nativement sur ce repo (le
`STATE.md` est narratif, pas au schéma générique attendu) — ne pas le forcer, marquer à la main.
De même, `requirements mark-complete` sur des IDs `SC*` est un no-op : le `ROADMAP.md` porte des
Success Criteria, pas des `REQ-IDs` dans un `REQUIREMENTS.md` (cf. [[requirements-supprime-a-la-cloture]]).

**Garde-fou posé (Phase 21, PR #22)** : `plugin/conductor/scripts/check-state-integrity.sh` — au sein
d'un même jalon, `completed_phases`/`completed_plans`/`total_plans`/`current_phase` ne décroissent
jamais, et le corps ne porte qu'une seule ligne `^Phase:`. Câblé au job `gates` de la CI. Vérifier
qu'il existe toujours avant de s'y fier ; il rend l'incident **bruyant**, il ne l'empêche pas.

**How to apply:** dans **chaque mandat de worker** qui touche à une phase, inscrire la baseline
courante des 4 compteurs et la consigne « après tout appel à un outil de la chaîne, relis le
frontmatter et restaure s'il a bougé ». Aux juges read-only (vérificateur, auditeur, gate), interdire
purement et simplement les outils `state.*`. En clôture de mission, relire le frontmatter **soi-même**
avant de rédiger le rapport — c'est le même réflexe que [[relire-le-disque-avant-tout-rapport]], et
la seule valeur qui a le droit d'avoir bougé est celle que la mission a légitimement fait bouger.
