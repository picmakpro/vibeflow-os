# Rejeu des contournements du driver-lock — Phase 32, research flag bloquant

> **Statut** : clos le 2026-08-16. Le ROADMAP exigeait de « rejouer les 2 contournements réels
> comme cas de test AVANT de choisir le mécanisme ». C'est fait — et la reconstitution **corrige
> le brief** : il n'y a pas deux contournements, mais **quatre incidents répartis sur trois
> gestes distincts**, dont un qui ne passe pas du tout par `Bash`.

---

## 1. Les incidents réels, tracés

| # | Date | Geste | Lock | Trace |
|---|---|---|---|---|
| **I1** | 2026-07-27 | **commit** concurrent | **périmé par TTL** | `.planning/codebase/CONCERNS.md:218-228` · `.planning/missions/2026-07-28-phase-17-…md:142-150` |
| **I2** | 2026-07-31 | **écriture `Write`/`Edit`** dans `.planning/` (ROADMAP + STATE) + 3 commits hors périmètre | tenu | `.planning/STATE.md:591-601` · `.planning/quick/260801-17w-…/PLAN.md:10-21` |
| **I3** | 2026-08-01 (symétrique 2026-08-15) | **checkout** de branche, même arbre | **tenu, non périmé** | mémoire de mission `sessions-concurrentes-verifier-le-lock.md` |
| **I4** | 2026-08-16 | **commit** concurrent × 8 | **tenu, non périmé** | `.planning/missions/2026-08-16-phase-30-portabilite-windows-ii.md:86-90` |

### Deux corrections qui changent le cadrage

1. **I1 et I4 ne sont pas le même mode de défaillance.** I1 passe par un lock **périmé** — c'est
   le domaine de LOCK-01/LOCK-04. I4 passe par un lock **vivant et tenu** — le TTL n'y est pour
   rien, **seul un enforcement à la source l'aurait arrêté** (LOCK-02).
   *Corriger le TTL sans poser le guard laisserait I4 entier.*
2. **I2 n'est pas un geste `Bash`.** C'est une session conversationnelle qui a rédigé la Phase 22
   dans `ROADMAP.md`/`STATE.md` via les outils natifs d'écriture. **Un guard `PreToolUse(Bash)`
   seul ne l'aurait pas vu** — or le critère de succès n°2 du ROADMAP ne parlait que de
   `PreToolUse(Bash)`. C'est l'angle mort de la formulation initiale.
   → **Amendé le 2026-08-16 par Samuel (option 2B)** : le guard couvre `Bash` **plus**
   `Write|Edit` restreint aux chemins `.planning/`, en réutilisant `guard-agent-write.sh`.

### L'illusion de protection, nommée

Le SUMMARY du quick `260801-17w` la formule exactement :
> « `driver-lock.sh` n'est consulté que par les managers. »

Et le seul test qui existe — `plugin/conductor/scripts/tests/test-driver-lock.sh:46-50` (T2) —
n'asserte qu'une chose : **une seconde `acquire` est refusée**. Aucune assertion, nulle part, sur
un geste git.

---

## 2. Les scripts de rejeu

Racine (bac à sable, hors dépôt) :
`/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/cc03f03a-d5b3-4c5e-a3b8-e238279f525d/scratchpad/repro/`

| Fichier | Rôle |
|---|---|
| `repro-A-commit-sous-lock-autrui.sh` | **Scénario A** (I1 + I4, LOCK-02) — exit **1** aujourd'hui |
| `repro-B-checkout-sous-lock-autrui.sh` | **Scénario B** (I3, LOCK-03) — exit **1** aujourd'hui |
| `lib-repro.sh` | socle : dépôt git jetable, copie du SUT, seam `PreToolUse(Bash)` |
| `prove-seam.sh` | preuve que le rouge n'est pas un chemin mort |
| `reference-guard/guard-driver-bash.sh` | guard de référence jetable (~30 l.), sert **uniquement** à la preuve |

> **Ces scripts sont un brouillon de preuve, pas le livrable.** Les cas de test définitifs vivront
> dans `plugin/conductor/scripts/tests/`, à la convention du dossier. Le bac à sable est volatil :
> ce document est ce qui survit.

### Le seam

Les scripts n'appellent **jamais** `git` directement pour le geste de la session Y : ils passent
par `session_bash`, qui reproduit le contrat `PreToolUse(Bash)` de Claude Code et cherche
`plugin/conductor/scripts/guard-driver-bash.sh`. Guard absent → la commande passe → rouge. Le jour
où la Phase 32 pose le guard, **les mêmes scripts virent au vert sans une ligne modifiée**.

Les deux conventions de refus sont acceptées par le harness de rejeu — `exit 2`, **et**
`exit 0` + `{"permissionDecision":"deny"}` (celle déjà employée par `guard-agent-write.sh:127`).
Le rejeu **n'impose donc aucun mécanisme** à la phase.

---

## 3. Traces du rouge

### Scénario A — commit sous le lock d'autrui

```
guard PreToolUse(Bash) 'guard-driver-bash.sh' : absent
  [preflight OK] P0..P6 (7/7)   lock acquis, acquired:true, T2 refuse la 2e acquire,
                                held_by mission-phase17, present:true stale:false
  commande émise par Y : git add INTRUS.md && git commit -m 'commit hors mandat'
  verdict du seam : EXECUTE
  [ASSERT ROUGE] A1 le commit de Y doit être REFUSÉ   attendu='REFUSE'   obtenu='EXECUTE'
  [ASSERT ROUGE] A2 HEAD ne doit pas avoir bougé      attendu='beaf7d9…' obtenu='4fdd412…'
  [ASSERT ROUGE] A3 nombre de commits reste à 1       attendu='1'        obtenu='2'
  [ASSERT VERT]  A4 [discriminance] le commit du DÉTENTEUR passe
SCENARIO A : ROUGE (3 assertions)   exit 1
```

### Scénario B — checkout sous le lock d'autrui

```
  [preflight OK] P0..P8 (9/9)
    P4 claim branch=feat/phase-26-manuel-utilisateur · P5 worktree= écrit
    P6 T2 refuse la 2e acquire · P7 stale:false
    P8 check-branch-claim.sh → exit 3 (SAIN) sur le MÊME arbre   ← aveuglement par design
  commande émise par Y : git checkout -b feat/phase-23-couplage-gsd
  verdict du seam : EXECUTE
  [ASSERT ROUGE] B1 checkout de Y refusé   attendu='REFUSE' obtenu='EXECUTE'
  [ASSERT ROUGE] B2 l'arbre reste sur la branche du lock
                    attendu='feat/phase-26-manuel-utilisateur' obtenu='feat/phase-23-couplage-gsd'
  [ASSERT ROUGE] B3 le commit suivant du DÉTENTEUR atterrit sur SA branche
                    attendu='feat/phase-26-manuel-utilisateur' obtenu='feat/phase-23-couplage-gsd'
  [ASSERT VERT]  B4 [discriminance] le checkout du DÉTENTEUR passe
SCENARIO B : ROUGE (3 assertions)   exit 1
```

**B3 est le dégât réel du 2026-08-15 asserté directement** : le commit du détenteur part sur la
branche de l'autre.

---

## 4. Preuve que le rouge est le bon (leçon Phase 31)

Trois verrous, tous exécutés :

1. **Préflights séparés des assertions.** Un préflight KO sort **exit 2** (« fixture cassé, pas de
   verdict métier »), jamais 1. Le garde-fou s'est déclenché **pour de vrai** au premier run : un
   `case` à motifs cités dans une substitution de commande cassait la syntaxe, P3/P5/P6 sont
   partis KO, et le script a **refusé de rendre un verdict métier**.
2. **Cas de discriminance A4/B4 verts.** Le dépôt jetable fonctionne : le rouge n'est ni un chemin
   introuvable ni un git cassé. Et un guard qui bloquerait tout le monde serait attrapé ici.
3. **Mutation dans les deux sens** (`prove-seam.sh`) :
   ```
   Passe 1 (module réel, guard absent)             A→1  B→1   ROUGE
   Passe 2 (module + guard de référence greffé)    A→0  B→0   VERT
   variante deny-JSON (contrat guard-agent-write)  A→0  B→0   VERT
   SEAM PROUVÉ
   ```

---

## 5. Surface réelle des gestes qui contournent le lock

### A. Passent par `Bash` → interceptables par `PreToolUse(Bash)`

`git commit` (+`--amend`) · `checkout`/`switch`/`restore` · `merge` · `rebase` · `cherry-pick` ·
`revert` · `reset --hard` · `clean -fd` · `push` (+`--force`) · `tag` · `branch -D` · `stash`/`pop` ·
`worktree add/remove` · `gh pr create/merge/close` · `gh release create` · redirections shell
(`cat >`, `sed -i`, `rm`) vers `.planning/` · scripts du dépôt qui commitent en interne.

### B. Passent par un outil Claude Code **autre que `Bash`** → interceptables, mais pas par le matcher `Bash`

| Outil | Geste | Incident |
|---|---|---|
| `Write` | réécriture de `STATE.md` / `ROADMAP.md` | **I2** |
| `Edit` / `NotebookEdit` | modification ciblée des mêmes fichiers | I2 |
| MCP (`mcp__github__*`, serveurs git) | PR, merge, commit hors shell | — |
| sous-agents (`Agent`) | héritent des hooks, mêmes gestes | I4 (8 commits tiers) |

C'est la case que le critère écrit ratait. **Couverte depuis l'arbitrage 2B.**

### C. Ne passent par **aucun** hook → hors de portée d'un guard distribué

- Session Claude Code où le module **n'est pas armé** — c'est la régression #38, et c'est pourquoi
  le critère n°4 (gate armement ↔ précondition) n'est pas décoratif.
- Geste humain dans un terminal ; IDE ou client git tiers.
- Processus lancés en arrière-plan : le hook tire au lancement, pas à chaque action ultérieure.
- Toute machine où `merge-hooks` n'a pas posé l'entrée.

**Portée réaliste : A + B ≈ tout ce qui vient d'un agent Claude Code sur une machine armée.**
C est irréductible. Le guard est un **garde anti-accident, pas anti-adversaire** — vocabulaire
déjà assumé par `guard-agent-write.sh:17-20`.

---

## 6. Fragilités identifiées — à traiter au plan, pas à découvrir en exécution

1. **Le matching de commande par sous-chaîne est une passoire.** `case "$cmd" in *"git commit"*`
   tombe devant `eval`, `$(echo git) commit`, un alias, un `./release.sh` qui commite dedans, ou
   `git -C … commit`. Un cas de test qui n'exerce que la forme littérale donne un vert
   **surestimé**. → Prévoir au moins un cas « commit indirect via script » rouge, **ou** assumer
   la limite en en-tête du guard. Le patron d'analyse existe :
   `guard-bash-registres.sh` (troncature heredoc L73, `command_positions()` L106-133,
   segmentation L178) — à réutiliser, pas à réinventer.
2. **Les scripts de rejeu testent le guard, pas l'armement.** Ils greffent le guard par copie. Le
   vrai risque, prouvé deux fois (#38, v2.49.0→v2.50.1), est que **le guard existe et ne soit pas
   branché**. → Un troisième cas est nécessaire : le gate d'armement sur `merge-hooks`. Sans lui,
   A et B peuvent virer au vert pendant que le contournement reste vivant en production.
3. **B3 pourrait devenir un faux vert** : il passerait aussi au vert avec un guard qui bloque
   *tous* les checkouts, y compris ceux du détenteur. C'est **B4 qui l'attrape — ne jamais le
   retirer.**
4. **Le TTL est un piège de non-déterminisme différé.** Les scénarios tournent en < 2 s avec
   `TTL=1800`, donc pas de péremption accidentelle. Mais dès que la phase ajoutera des cas sur le
   battement (LOCK-01), tout cas `sleep`-dépendant sera **flaky en CI**.
   → **Forger les epochs, ne jamais attendre** (patron existant : `age_stale()`,
   `test-driver-lock.sh:27-39`).
5. **I2 n'est pas encore rejoué.** Le scénario C (écriture `Write`/`Edit` concurrente dans
   `.planning/`) reste à écrire — il est désormais dans le périmètre par l'arbitrage 2B.
