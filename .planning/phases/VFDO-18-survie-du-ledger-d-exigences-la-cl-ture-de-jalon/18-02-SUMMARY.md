# 18-02 — SUMMARY

**Requirement** : LEDG-01 (rattrapage outillé du ledger d'exigences à la clôture d'un jalon)
**Statut** : livré, testé, rejoué sur données réelles

## Commits

- `ae5fa39` — `feat(18-02): rattrapage outillé du ledger d'exigences (LEDG-01)` : `restore-requirements-ledger.sh`, extension `vf_ledger_classify` de `requirements-survival-detect.sh`, suite `test-restore-requirements-ledger.sh`.
- `4355a3a` — `docs(18-02): aligne la casse de l'amendement §7.2 sur l'assertion de recomptage du plan`.

## Ce qui a été livré

- `restore-requirements-ledger.sh` — roll-forward depuis l'archive d'un jalon clos, diff par défaut, écriture uniquement sous `--write`. Garde de non-écrasement : `--write` refuse si `.planning/REQUIREMENTS.md` existe déjà ; `--overwrite-live` (jamais impliqué par `--write` seul) autorise avec sauvegarde `REQUIREMENTS.md.bak-<jalon>` tracée en sortie.
- `vf_ledger_classify` (extension de `requirements-survival-detect.sh`) — classification statut→destin, **corrigée deux fois sur mesure** (voir Déviations).
- `test-restore-requirements-ledger.sh` — 438 lignes, 26 assertions, 0 ko. Rejeu réel sur l'archive `agentique-v1.0-REQUIREMENTS.md` (copie jetable), présence ET destination vérifiées par oracle indépendant re-dérivé par la suite, jamais un nombre codé en dur.
- `STUDY.md` §7.2 — amendement déjà posé au cadrage, casse alignée sur l'assertion machine du plan.
- `AGENT.md` — ligne `[ledger-absent]` déjà posée dans le commit de la vague 1 (`65a4edd`).

## Compteurs réels

```
$ bash plugin/dev-orchestrator/scripts/tests/test-restore-requirements-ledger.sh
== résultat : 26 ok, 0 ko ==

$ bash plugin/dev-orchestrator/scripts/tests/test-check-requirements-survival.sh   (re-vert amont)
== résultat : 41 ok, 0 ko ==

$ bash plugin/dev-orchestrator/scripts/tests/test-hook-exit-contract.sh
== résultat : 40 OK / 0 KO ==
```

Rejeu réel (`--write` sur copie jetable d'`agentique-v1.0-REQUIREMENTS.md`) :
`Garanties: 93, Voyage: 42, Caduques laissées en archive: 1, Forme non reconnue (stderr): 0` —
93+42+1 = 136/136, zéro perte.

## Déviations déclarées

1. **A-18-06 rouverte deux fois sur mesure** (documenté dans `18-02-PLAN.md`, section « Correction
   du 2026-08-18 »). Le contrat initial du plan (garantie = `[x]` + `Complete`/`Livré v` littéraux,
   repli code 3) perdait **86/136 IDs (63 %)** rejoué sur l'archive réelle — le corpus parle
   `Done`/`Planned`/prose, jamais `Pending`. Une route intermédiaire (case à cocher seule comme
   signal primaire) a été essayée, mesurée à 136/136 en présence mais fausse en destination : 134/136
   IDs de l'archive sont cochés à la clôture (structurel), donc la case n'a aucun pouvoir
   discriminant — les 19 IDs `Planned` (tous cochés) auraient été classés garantie à tort, zéro
   exigence n'aurait voyagé (inverse de D-18-11). Contrat retenu : caduc (précédence absolue) >
   case explicitement non cochée = voyage > case cochée + statut reconnu livré (`complete`/`done`
   insensible à la casse, ou `Livré v`) = garantie > repli voyage par défaut > forme non reconnue
   (case ni `x`/vide/`~`, seul cas réel restant en code 3). D-18-13 (zéro normalisation) tenu à
   l'identique — les lignes restent réimprimées verbatim, seul le code de décision a changé.
2. **Garde de non-écrasement ajoutée hors périmètre initial du plan** (`--write`/`--overwrite-live`,
   sauvegarde `.bak-<jalon>`), en défense en profondeur au-delà du contrat déjà tenu par
   `vf_ledger_state` (qui ne rend `absent_after_close` que si `REQUIREMENTS.md` est absent).
3. **STUDY.md §7.2** : l'amendement demandé par la tâche 3 existait déjà (posé au cadrage, plus
   complet que le gabarit du plan) ; un seul mot recasé plutôt qu'un second encadré redondant.

## Non-régression amont

Extension additive de `requirements-survival-detect.sh` (vf_ledger_classify ajoutée, `vf_ledger_state`
intact — 0 ligne supprimée dans la fonction existante, vérifié par `git diff`) : la suite de la vague
1 (`test-check-requirements-survival.sh`) re-testée après chaque extension, reste à **41 ok, 0 ko**.

## Reliquat

Aucun. LEDG-01 est couvert dans son périmètre complet, rejoué sur données réelles, garde de
non-écrasement testée dans le sens chronologique (rouge sans la garde, vert avec).
