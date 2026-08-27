# Mission — Phase 35, ré-armement worktree (conditionnelle)

**Date** : 2026-08-26 · **Branche** : `feat/phase-35-rearmement-worktree` (basée sur `main` =
`f170ee0`) · **Verrou de driver** : `mission-phase-35`, generation `1787758635.53887`
**Issue** : COMPLÈTE — arbitrage rendu par Samuel (**option A**), appliqué et vérifié.

## Plan de bataille (DAG `.planning/MISSION-35.dag.json`, 13 nœuds)

`mesure-baseref` → `cadrage` → `plan` → `plancheck` → {`exec-qual01`, `exec-gate`} →
`exec-wktr01` → `exec-rearm` → {`revue`, `audit`, `docs`}, plus `fix-rouges` (indépendant).
Faits : `mesure-baseref` ✅, `fix-rouges` ✅. Gelés : tout le reste, en aval de l'arbitrage.

## Gate d'entrée

- `check-mission-invariants.sh` → **exit 3 = SAIN** (mesuré hors pipe : `cmd | head` rendait le rc
  de `head`, pas celui du gate).
- Flags d'enchaînement : `auto_advance: false` et `_auto_chain_active: false` déjà désarmés dans
  `.planning/config.json` (`gsd_run` absent sur ce poste — constat, pas une escalade).
- Précondition externe re-mesurée : `npm view @opengsd/gsd-core version` → **1.11.0** ;
  `dist-tags` → `latest: 1.11.0`, `next: 1.7.0-rc.6` (donc `npm view … version` lit bien `latest`,
  jamais `next`) ; `~/.claude/gsd-core/VERSION` → **1.11.0**. Les deux volets sont tombés.

## Le résultat central — la prémisse de la phase est démentie

La preuve WKTR-02 du 2026-08-23 est **dégénérée sur leg B** (la base de fork) : la branche jetable
et `main` pointaient toutes deux sur `e69631c`, rendant « fork depuis le HEAD courant » et « fork
depuis la branche par défaut » indistinguables. Or leg B est la cause *immédiate* de #38.

Rejeu non dégénéré (branche réellement divergente) + mesure directe sur le moteur 1.11.0 installé :

| Situation | Résultat mesuré |
|---|---|
| Ce dépôt (porte `baseRef: "head"` en settings local) | fork depuis le HEAD courant ; 2 commits ramenés en fast-forward |
| Lab PROPRE (`effectiveBaseRef: null`), HEAD divergent | `shouldDegrade = true`, `reason = head-diverged-from-fork`, « Running this phase sequentially on the main working tree » |
| Même HEAD, `effectiveBaseRef: 'head'` | `shouldDegrade = false`, `reason = baseref-head` |

**Le vert de la première ligne est contaminé** : `.claude/settings.local.json` de ce dépôt porte
`"worktree": {"baseRef": "head"}` — exactement le réglage repo-local qui a causé #38. Ce dépôt est
encore aujourd'hui dans la configuration qui fait mentir les tests d'isolation locaux.

Conséquences : **sûreté acquise** (le moteur dégrade en séquentiel, le symptôme catastrophique de
#38 ne peut plus se reproduire) mais **efficacité nulle en conditions de mission** (ADR-059 impose
une branche dédiée, donc HEAD diverge toujours, donc dégradation systématique). Le seul levier
serait `baseRef: "head"`, doublement disqualifié : aucun vecteur de distribution par l'engine, et
le moteur écrit lui-même qu'il *« silences this check without verifying the base »*.

WKTR-01 tel qu'écrit n'est donc pas satisfiable honnêtement : `ensure-deps.sh` ne peut pas attester
une clé de settings qu'il ne doit pas écrire. Preuve détaillée :
`.planning/research/2026-08-26-wktr-02-leg-b-base-de-fork.md`.

## Escalade et arbitrage rendu

Options soumises : **A** ne pas ré-armer et clore sur la preuve (recommandée) · **B** ré-armer en
connaissance de cause (sûr mais inerte, + un avertissement par dispatch) · **C** ré-armer et
distribuer `baseRef: head` (déconseillé formellement — anti-pattern #38).

**Samuel a tranché : option A**, plus le **retrait** de `worktree.baseRef: "head"` du
`.claude/settings.local.json` de ce dépôt, au motif qu'il fait mentir tous les tests d'isolation
joués localement. Les deux consignes ont été appliquées.

Retrait vérifié par mesure, pas par lecture : `resolveEffectiveBaseRef` rend désormais `null`, et
sur un HEAD divergent le moteur rend `shouldDegrade = true` / `head-diverged-from-fork`. Le bloc
`permissions` du fichier est intact ; une sauvegarde a été prise avant édition (le fichier est
gitignoré, donc sans historique).

## Clôture option A — ce qui a été écrit

| Geste | Commit |
|---|---|
| Amendement de la preuve dégénérée du 2026-08-23 (valide leg A, dégénérée leg B) — mesures d'origine non touchées | `2cdda8c` |
| Requalification du ledger : WKTR-01 requalifié non livré, WKTR-02 done, QUAL-01 **non déclenché**, anti-feature renforcée | `ce98647` |
| Doctrine `team-kernel.md` : pourquoi les deux gates RESTENT + contrainte des commandes composées | `c6cddd1` |
| ROADMAP Phase 35 close (`Plans: aucun`) + STATE recalé (Phase 18 releasée, progress 6/8) | `f9666ef` |

## Vérification finale — mesurée par le manager, pas reprise du worker

- Suite complète sur la découverte **exhaustive** (68 suites, périmètre CI exact) : **68 / 68 vertes**.
- `check-machine-paths.sh` **rc 0** · `check-agents.sh` **rc 0** · `check-state-integrity.sh` **rc 0**
  · `check-capability-activation.sh` **rc 0** (codes réels capturés hors pipe).
- `STATE.md` **non écrasé** : 80,5 Ko → 83,4 Ko, 990 lignes, édité à la main (`gsd-tools state`
  jamais employé). `ROADMAP.md` modifié en **2 hunks seulement** (la case + la section Phase 35).
- Diff total : 8 fichiers. **Aucune** zone de risque de `MISSION-INVARIANTS.md` touchée (ni
  `check-*.sh`, ni `hooks.json`, ni `dag.sh`/`driver-lock.sh`, ni un agent manager).

## Livré et mesuré vert

`main` était **rouge** sur 2 des 68 suites du périmètre CI, sans rapport avec ce travail :

| Défaut | Cause | Commit | Vérification indépendante |
|---|---|---|---|
| `check-machine-paths` rouge | chemin machine ligne 32 du doc de preuve WKTR-02, introduit par `f170ee0` | `3d78414` | gate **rc 0**, 1116 fichiers suivis balayés |
| `test-dev-orchestrator` T28-F | index de capabilities versionné dérivé depuis la montée gsd-core 1.11.0 | `a388c7d` | suite **184 OK / 0 KO / 0 SKIP**, rc 0 |

Baseline établie avant intervention sur la découverte **complète** (68 suites, `find plugin scripts
-type f -path '*/tests/test-*.sh'`) : 66 vertes / 2 rouges — les 2 rouges étant exactement celles
corrigées. Les deux verts ci-dessus ont été **re-mesurés par le manager sur l'état commité**, pas
repris du rapport du worker.

Également livré : `0525e5a`, le document de preuve leg B.

## Constats reportés (non corrigés)

1. **La veille WKTR-03 n'a pas fonctionné.** Cache à `2026-08-17`, `dernière_version_vue=1.10.0`,
   `dépassement=false` : elle n'a **jamais** signalé la sortie de 1.11.0 — la phase a été
   débloquée à la main. Le script est sain (un `--refresh` manuel rend immédiatement
   `1.11.0 / dépassement=true`, cache réactualisé au passage) ; le hook `SessionStart` de
   `.claude/settings.json` est bien câblé mais son matcher ne couvre que `startup`, pas la reprise
   de session. Cause exacte non prouvée.
2. **Le palier dur de `check-agents.sh`** (interdiction de toute valeur d'`isolation:` dans un
   agent distribué) devra être levé explicitement si l'option B est retenue — ce livrable n'est
   nommé nulle part dans WKTR-01.
3. **Trou de test** : `test-check-agents.sh` T44 ne couvre que `isolation: sandbox` ; la branche
   `iso == "worktree"` n'a **aucun** test de discriminance, et le commentaire de T44 est périmé.
4. Une suite archivée hors périmètre CI (`.planning/milestones/agentique-v1.0-phases/VFDO-15-…`)
   est rouge de longue date. Hors CI, donc sans effet — signalée pour mémoire.

## Garanties tenues

Branche dédiée créée avant le premier commit ; **aucune PR, aucun tag, aucune release, aucun
merge** (gestes humains). Les fichiers non suivis d'une autre session (`.gsd/`, `MISSION-*.dag.json`,
`VFDO-36-*`) n'ont été ni commités ni supprimés ; le worktree `feat/vf-cockpit-module` n'a jamais
été touché. Worktree et branches jetables de l'expérience supprimés, arbre propre.
