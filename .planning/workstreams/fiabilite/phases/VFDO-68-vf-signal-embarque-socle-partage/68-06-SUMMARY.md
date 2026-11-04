---
phase: 68-vf-signal-embarque-socle-partage
plan: 06
requirements: [VFSG-03, VFSG-06]
status: complete
---

# 68-06 — Retrait de `disk.ts`, vues mission et macro sur le socle (VFSG-03, VFSG-06 ; P68-D-13, P68-D-17, P68-D-24, P68-D-30)

Trace du rouge, du vert et des mutants : `68-06-RED-TRACE.md`. Claude Code 2.1.318. Branche `feat/phase-68-w06`, partie de `cad735be`.
Après ce plan, le mod n'a plus qu'une source de données : l'émetteur `signal@1`. `disk.ts` est supprimé.

## Commits (ordre : tests, trace, code)

| Empreinte | Objet |
|-----------|-------|
| `24e71a83` | test : témoins R6-K5, K10 (b, c), K11 (b), J1..J3, M7 ; les trois tests d'origine réalignés sur `signal@1` (par conception : plus de backlog, plus de registre de mission) |
| `c815fd3c` | docs : trace du rouge avant le code |
| `f9922469` | feat : la vue mission lit la mission courante de `signal@1` ; types étendus |
| `1a059b78` | refactor : `derive.ts`, `actions.ts`, `boutons.tsx`, bandeau, brief, vue macro, élagage sur `signal@1` |
| `fd4b3834` | feat : `disk.ts` supprimé, rafraîchissements et types de l'ancien disque retirés |
| `58e89b59` | feat : l'en-tête dit le jalon de la phase active de l'arbre courant (P68-D-30) |
| `46182014` | test : R6-A1, R6-A2 (la prochaine action humaine ignore une mission abandonnée) |

## Résultats

- `claude plugin test plugin` : 35 pass, 0 fail ; `claude plugin validate --strict plugin` rc=0.
- `test-cockpit-signal-mod.sh` : 25 ok / 0 ko sous bash et sous zsh (M0 à M7) ; `check-machine-paths.sh` rc=0.
- Longueurs : `derive.ts` 173, `register.tsx` 197, `pane.tsx` 145, `boutons.tsx` 63, `actions.ts` 27 (plafond 300).
- Mutants : 11 + 4 pour M7, chacun rougit sur l'assertion visée (annexe de la trace).

## Écarts au plan

1. **Identifiants `R6-K5`, `R6-K10`, `R6-K11`** au lieu de `K5`, `K10`, `K11` : ces trois identifiants existent déjà dans `socle.test.tsx` (68-05) ; `verdict.sh` compare le titre par son début et rend exit 2 sur un identifiant à la fois en succès et en échec. Les `<verify>` du plan qui citent K5 et K11 visent donc le test de 68-05 : lus avec le préfixe, ils passent (`OK-T1` rejoué avec `R6-K11 succes` et `R6-K5 echec`).
2. **Harnais** : `labSignal` ne laisse pas d'espion (second `on('fs.exists')` refusé : « registered twice ») et `fixture-signal.ts` n'est pas dans le périmètre : `vf-signal.test.tsx` porte son propre `lab()` (mêmes réponses, plus l'enregistrement des lectures `fs.*` et des appels `bash`, plus un leurre d'ancien disque).
3. **Fichiers touchés hors `files_modified`** : `plugin/cockpit/signal/types/index.d.ts` (le type `Signal` s'étend aux nœuds, à la liste des verrous et aux jalons ; `Disk`, `Macro`, `Milestone`, `LockInfo`, `RegistryAgent` disparaissent) ; `hooks/en-tete.tsx` (ajout autorisé par P68-D-30). `hooks/ds.ts` non touché.
4. **Témoins ajoutés** au plan : R6-K10b et R6-K10c (ordre projet puis compte), R6-K11b (mission `inconnu`, P68-D-23), R6-J1..J3 (jalon de l'en-tête, P68-D-30), R6-A1 et R6-A2 (action humaine d'une mission vivante / abandonnée), M7.0..M7.5.
5. **Gardes verts avant le code** : R6-J2, R6-J3 et M7.5 (prouvés par mutant) ; R6-K10b et R6-K10c rougissent avant le code par la source du verrou (`signal.verrous`) et non par l'ordre des candidats, l'ordre est prouvé par mutant.
6. **Changement de comportement assumé** : le registre de mission (`driver-lock.sh orphans`, agents sous leur nœud) n'est plus affiché dans la vue mission, ni `stoppedAt` du STATE ; l'arbre des agents vient de `who@2` en 68-07. `attention` : une mission abandonnée ou d'état inconnu ne dicte plus d'arbitrage ni de nœud en échec (R6-A2).
7. **Attentes du test d'origine changées par conception** : (a) vue macro, `/backlog/` défini devient `/Jalon d essai/` défini et `/backlog/` indéfini (P68-D-24) ; (b) pane : `/plan Phase 59/` et `/vf-coder/` (registre) deviennent `/exécution/` (nœud de `signal@1`) ; (c) bandeau et pane : `verrou périmé de vf-dev-manager-p59` devient `verrou périmé de mgr68` (verrou de `signal.verrous.liste`).
8. **Test de 68-05 encore valable** : `embarque.test.tsx` (E1..E4b) et `socle.test.tsx` passent sans retouche.
9. **Rappel de 68-05** : le test réel de l'ENOENT par le moteur reste non prouvé sous `claude plugin test` (recette 68-09).

## Artefacts posés d'office dans le dossier de phase

`68-06-RED-TRACE.md`, `68-06-SUMMARY.md` (aucun autre).

## Estimate / actuals

estimate du plan : 95 000 tokens, 3 tâches, confiance basse. actuals : non mesurés (exécution inline, pas de `gsd-execute-phase`).
