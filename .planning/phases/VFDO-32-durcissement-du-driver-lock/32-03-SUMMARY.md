# Phase 32 Plan 03: guard-driver-lock.sh — enforcement à la source (LOCK-02/03/05) — Summary

**Statut : tâches 1 à 4 exécutées et committées, vertes. Checkpoint final (`type="checkpoint:human-verify"
gate="blocking"`) NON répondu — attente d'une décision humaine (voir §Checkpoint ci-dessous).**

## Ce qui a été livré

Un guard `PreToolUse` unique, `plugin/conductor/scripts/guard-driver-lock.sh`, qui compare
l'identité de session de l'appelant à celle enregistrée dans le `meta` du driver-lock et refuse,
par décision JSON, les gestes mutants (commit/checkout/switch/merge/rebase/cherry-pick/revert/
reset/clean/push/tag/branch/stash/worktree remove/`gh pr`/`gh release` en Bash, ou Write/Edit sous
`.planning/`) d'une session tierce sous un lock vivant. Le détenteur (manager et ses sous-agents,
qui partagent le `session_id` de leur session parente) passe toujours. Un lock absent, périmé, ou
sans identité (rétrocompat pré-Phase-32) ne bloque rien.

## Commits produits

| SHA court | Sujet |
|---|---|
| `2308287` | feat(conductor): guard-driver-lock.sh — tranche verticale commit/checkout sous lock tiers (tâche 1) |
| `2453f55` | feat(conductor): guard-driver-lock.sh — surface complète, voie Write/Edit, échappatoire (tâche 2) |
| `8f74ec7` | test(conductor): guard-driver-lock.sh — QUAL-01, les quatre issues prouvées séparément (tâche 3) |
| `86edccb` | feat(conductor): arme guard-driver-lock.sh via hooks.json — inventaire durable à jour (tâche 4) |

## Fichiers modifiés/créés

- `plugin/conductor/scripts/guard-driver-lock.sh` (neuf)
- `plugin/conductor/scripts/tests/test-guard-driver-lock.sh` (neuf, 70 cas, exit 0)
- `plugin/conductor/hooks/hooks.json` (une entrée `PreToolUse` neuve, forme exec)
- `docs/HOOKS-CONTRAT-SORTIE.md` (inventaire 26 → 27, tableau conductor, décompte bloquantes/advisory)
- `README.md` / `README.fr.md` (compteur de suites 62 → 63)
- `plugin/_internal/tests/test-vf-portable.sh` (T12 : guard-driver-lock.sh, 5e consommateur du
  bloc canonique `vf-portable:locator`)
- `.planning/phases/VFDO-32-durcissement-du-driver-lock/32-03-SUMMARY.md` (ce fichier)

## Écart signalé — D-32-05 amendé : UNE entrée hooks.json, pas deux (découverte empirique)

**D-32-05 prescrivait deux entrées séparées** dans `hooks.json` (matcher `Bash`, matcher
`Write|Edit`), invoquant le même script. **Cette forme s'est avérée cassée à l'installation**,
découverte pendant la preuve d'armement de la tâche 4 :

**Reproduction.** `merge-hooks.sh` porte une purge d'idempotence documentée (lignes ~373-384) :
« retirer toute entrée référençant les mêmes scripts dans TOUS les groupes de l'événement DE CETTE
MÊME CIBLE — sinon un changement de matcher entre deux versions du fragment laisserait l'ancienne
entrée et exécuterait le hook 2x ». Cette purge s'exécute APRÈS chaque insertion d'entrée dans la
boucle `apply_merge`, et scanne `ev` — qui contient déjà toute entrée insérée plus tôt DANS LE MÊME
appel de merge. Avec deux entrées référençant `guard-driver-lock.sh` sous le même événement
`PreToolUse` (peu importe leur matcher), la **seconde entrée traitée purge la première**, quel que
soit l'ordre dans le fragment. Testé empiriquement avec le fragment à deux entrées : seule l'entrée
`Write|Edit` survivait dans `settings.local.json`, l'entrée `Bash` avait disparu — ni dans le
fichier local, ni dans le projet.

**Correction retenue** (dans le périmètre de fichiers autorisé — `merge-hooks.sh` est dans
`plugin/_internal/`, hors périmètre de ce plan, donc non modifié) : **une seule entrée
`PreToolUse` à matcher combiné `"Bash|Write|Edit"`**. Précédent déjà en usage dans ce même
fragment (`post-edit-reindex.sh`, matcher `"Edit|Write|Bash"` en `PostToolUse`) — la forme est
supportée et déjà pratiquée par ce dépôt. Fonctionnellement équivalente : le script dispatchait
déjà sur `tool_name` du payload, indépendamment du matcher qui l'a déclenché.

**Conséquence sur l'inventaire** : 27 entrées au total (pas 28), conductor à 7 (pas 8), 6 entrées
bloquantes (pas 7). `docs/HOOKS-CONTRAT-SORTIE.md` reflète la valeur corrigée.

**Conséquence sur les mutations exigées par l'acceptance criteria de la tâche 1** : le critère
« `grep -c 'vf-portable:locator'` rend 2 » — inchangé, non affecté (concerne le script, pas
`hooks.json`). Le critère de la tâche 4 « le fragment porte bien DEUX entrées avec `args`... la
valeur rendue est `2` » **n'est PAS satisfait littéralement** — la valeur réelle est `1`. C'est
la conséquence directe et assumée de la correction ci-dessus : maintenir deux entrées aurait
livré un guard **non armé** sur l'une des deux voies protégées, un vert de complaisance bien pire
que l'écart au chiffre attendu.

## Preuve d'armement — lab jetable

**Chemin du lab** (jetable, hors de ce dépôt, supprimé et recréé plusieurs fois pendant l'exécution) :
```
/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/cc03f03a-d5b3-4c5e-a3b8-e238279f525d/scratchpad/lab-jetable-32-03
```

**Déroulé** : `git init` dans le lab, résolution de la fermeture de `conductor` par
`plugin/_internal/resolve-deps.sh conductor` :
```
audit-architecture conductor consolidator infrastructure-audit planning-core skill-creator validator
```
puis installation de chaque module de la fermeture avec `VIBEFLOW_CACHE=<repo>/plugin VF_SCOPE=project
bash plugin/_internal/vibeflow-update.sh install <module>`.

**`.claude/settings.local.json` du lab jetable, en fin d'installation** (reproduit intégralement) :
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/bin/bash",
            "args": [
              "${CLAUDE_PROJECT_DIR}/.claude/scripts/guard-driver-lock.sh"
            ]
          }
        ],
        "matcher": "Bash|Write|Edit"
      }
    ]
  }
}
```

**`.claude/settings.json` (PROJET, committable) — `guard-driver-lock.sh` en est ABSENT** ; il porte
en revanche `guard-bash-registres.sh` (module `consolidator`, matcher `Bash` historique, forme
shell) — la cohabitation de matcher envisagée par D-32-05 est vérifiée SANS collision une fois le
fragment `conductor` consolidé en une seule entrée (les deux entrées vivent dans des GROUPES
séparés du même événement `PreToolUse`, dans des FICHIERS différents — aucun conflit de groupe).

**Cinq assertions PORT-05, toutes vertes** :
1. `command` absolu, existant, exécutable : `/bin/bash` — vérifié (`[ -x ... ]`).
2. Aucun métacaractère shell dans `command`/`args`, hors placeholder harness légitime
   `${CLAUDE_PROJECT_DIR}` (substitué par le harness lui-même, jamais par un shell en forme exec) —
   vérifié par grep ciblé après exclusion du placeholder.
3. Aucun placeholder résiduel (`{{...}}`) dans l'un ou l'autre fichier de réglages — `grep -c '{{'`
   rend 0 dans les deux.
4. Compte d'entrées avec `args` dans les deux fichiers réunis == compte dérivé de la fermeture
   installée : **attendu = 1, constaté = 1** (recalculé localement à partir des `hooks.json` des 7
   modules de la fermeture — reproduit la dérivation du gate PORT-05 plutôt que de figer un
   chiffre).
5. Idempotence : réinstallation de `conductor` dans le même lab → toujours exactement 1 occurrence
   de `guard-driver-lock.sh` dans les deux fichiers réunis (pas de duplication).

**Le dépôt courant N'A PAS été armé** : `git status --porcelain -- .claude/` rend une sortie vide en
fin de tâche 4. `.claude/settings.json`/`.claude/settings.local.json` de CE dépôt (non trackés par
git — `git ls-files` les confirme absents de l'index) ne portent AUCUNE entrée de module VibeFlow
(uniquement un hook `SessionStart` propre au dépôt lui-même, `check-gsd-core-update.sh`, et des
réglages `worktree`/`permissions` sans rapport).

## Motif de refus complet (rendu au modèle mot pour mot — DIV-1)

Capturé sur un cas réel (`git commit -m x`, session tierce, lock tenu par `mission-32`, étape
`tache-4`, branche `feat/phase-32-durcissement-driver-lock`) :

> Lock de driver ACTIF, tenu par 'mission-32' (étape : tache-4), branche
> 'feat/phase-32-durcissement-driver-lock', depuis 0 min. Ce geste est REFUSÉ (session non
> enregistrée sous ce lock). Si tu ES 'mission-32' avec un identifiant de session neuf (/clear,
> --continue ambigu) : `driver-lock.sh reclaim --owner=mission-32` puis réessaie. Sinon : attends
> la fin du mandat, travaille dans un arbre séparé (`git worktree add`), ou pose le marqueur
> vibeflow:allow-lock-override sur CE geste précis pour passer outre exceptionnellement.

Nomme bien : owner, étape, branche, âge en minutes, la commande exacte de re-rattachement
(`driver-lock.sh reclaim --owner=<owner>`), et le marqueur d'échappatoire (`vibeflow:allow-lock-override`).

## Wrappers effectivement couverts par la détection de position de commande

Repris tel quel de `guard-bash-registres.sh` (`WRAPPERS` set, non modifié à la source, copié dans
`guard-driver-lock.sh`) : `sudo`, `env`, `command`, `nohup`, `time`, `xargs`, `nice`, `stdbuf`,
`caffeinate`. Vérifiés par cas de test (S5a `sudo git commit`, S5b `env FOO=1 git commit`) — les
deux dénient correctement une session tierce.

## Traces des mutations exigées

### Tâche 1 (5 mutations — a/b/c/d/e)

- **(a) Guard permissif sur mismatch** (deny remplacé par un `sys.exit(0)` avant l'émission) :
  A1/A2a/A2b/A5/A6a/A6b/B1 rougissent (7 FAIL). Attendu : deny sur ces 7 cas. Obtenu : sortie vide.
  Restauré par `git checkout --`, revalidé vert (22/22 à l'époque de la tâche 1).
- **(b) Guard aveugle à `session_ids`** (le `if sid and sid in session_ids: sys.exit(0)` remplacé
  par `if False:`) : A4/B4 rougissent (2 FAIL — « sortie non vide »). Attendu : sortie vide (le
  détenteur passe). Obtenu : un deny. Restauré, revalidé vert.
- **(c) Lock périmé n'est plus traité comme absent** (`if age > ttl: sys.exit(0)` remplacé par
  `if False:`) : R2 rougit seul (1 FAIL). Attendu : sortie vide. Obtenu : un deny. Restauré,
  revalidé vert. (Première tentative avec un remplacement multi-lignes avait cassé l'indentation
  Python et fait rougir 8 cas au lieu d'1 seul — corrigée en préservant l'indentation exacte pour
  isoler proprement l'assertion visée, cf. note dans le corps de ce document.)
- **(d, BL-1) Décrochage du découpage `\n`/`\r`** (`for line in re.split(...)` remplacé par
  `for line in [cmd]`) : A5 rougit seul (1 FAIL). Attendu : deny malgré le saut de ligne. Obtenu :
  sortie vide (le commit de la 2e ligne redevient invisible). Restauré, revalidé vert.
- **(e, BL-2) Saut des options globales `git` retiré** (`j = skip_git_globals(...)` remplacé par
  `j = idx + 1`) : A6a/A6b rougissent (2 FAIL). Attendu : deny sur `git -C /tmp commit` et
  `git -c core.hooksPath=/dev/null commit`. Obtenu : sortie vide (sous-verbe non reconnu).
  Restauré, revalidé vert.

### Tâche 2 (8 mutations — a/b/c/d/e/f/g/h)

- **(a) Exemption `worktree add` retirée** (traitée comme `remove`, `return True`) : S2 rougit
  (1 FAIL, « sortie non vide »). Attendu : sortie vide. Obtenu : deny. Restauré, revalidé vert.
- **(b) Détection de position de commande retirée** (`command_positions(toks)` remplacé par
  `range(len(toks))`) : **le cas S3 initial (`grep -n "git commit" ...`) NE rougissait PAS** — le
  vrai discriminant de ce cas est le QUOTING (shlex fait de `"git commit"` un token unique, jamais
  égal à `"git"`), pas la position. Un cas S3b (`echo git commit -m x`, `git` en position ARGUMENT
  d'`echo` mais tokens SÉPARÉS) a été ajouté pour discriminer réellement cette mutation — il
  rougit (1 FAIL). Attendu : sortie vide. Obtenu : deny. Restauré, revalidé vert (56/56 à l'époque).
  **Franchise** : le cas S3 d'origine, tel qu'écrit dans le plan, ne prouvait pas ce que son
  intitulé promettait ; corrigé en ajoutant S3b plutôt que de le laisser passer pour un faux vert.
- **(c) Troncature heredoc retirée** (`cmd = cmd.split("<<", 1)[0]` neutralisé) : S4 rougit seul
  (1 FAIL). Attendu : sortie vide. Obtenu : deny (le contenu du heredoc est lu comme une commande).
  Restauré, revalidé vert.
- **(d) Borne `.planning/` retirée sur la voie Write/Edit** : C4 rougit seul (1 FAIL). Attendu :
  sortie vide (hors périmètre). Obtenu : deny. Restauré, revalidé vert.
- **(e) Échappatoire désactivée** (`if os.environ... or MARKER in text: ...` remplacé par
  `if False:`) : S7 et S8 rougissent (2 FAIL). Attendu : sortie vide. Obtenu : deny. Restauré,
  revalidé vert.
- **(f, BL-7) Exemption `--abort/--continue/--skip/--quit` retirée** (`RESUMABLE_SUBVERBS` renvoie
  toujours `True`) : les 4 formes de S9 rougissent (4 FAIL). Attendu : sortie vide. Obtenu : deny.
  Restauré, revalidé vert.
- **(g, BL-7) Exemption élargie à tort à la sous-commande entière** (`continue` inconditionnel sur
  `RESUMABLE_SUBVERBS`) : S10 rougit (« `git rebase -i main` » devient allow à tort), plus 5 cas S1
  en cascade (merge/rebase/cherry-pick/revert/stash désormais tous exemptés). 6 FAIL au total.
  Attendu : S10 en deny. Obtenu : sortie vide. Restauré, revalidé vert.
- **(h, SE-7) Write/Edit aveugle à `session_ids`** (`if tool == "Bash" and sid and sid in
  session_ids: sys.exit(0)`, condition étroitement bornée à Bash) : C3 (Write ET Edit) rougit
  (2 FAIL). Attendu : sortie vide (le détenteur passe même sur Write/Edit). Obtenu : deny.
  Restauré, revalidé vert.

### Tâche 3 (3 mutations — a/b/c)

- **(a) Diagnostic émis sur stdout dans le chemin imparsable** (`print(...)` ajouté avant le
  `sys.exit(0)` du `except` racine) : Q3 rougit sur sa moitié « stdout STRICTEMENT VIDE » (1 FAIL).
  Attendu : stdout vide. Obtenu : `diagnostic MUTATION A`. Restauré, revalidé vert.
- **(b) `vf_guard_unavailable` remplacé par une sortie zéro muette** (`if ! vf_resolve_python
  --fast; then exit 0; fi`) : Q4 rougit sur ses trois assertions (code 17, stderr préfixé, marqueur
  de santé) — 3 FAIL. Attendu : code 17, diagnostic stderr, marqueur écrit. Obtenu : code 0, aucun
  diagnostic, aucun marqueur. Restauré, revalidé vert.
- **(c) Meta illisible traité en deny au lieu d'allow** (le `except Exception: sys.exit(0)` du bloc
  de lecture du `meta` remplacé par un `print(json.dumps({...deny...}))` avant le `sys.exit(0)`) :
  Q3c rougit sur sa moitié « stdout vide » (1 FAIL). Attendu : stdout vide (jamais un deny sur
  erreur interne). Obtenu : un deny. Restauré, revalidé vert.

**Anti-vert-à-vide (Q5)** prouvé par une preuve substituée, pas par la neutralisation intégrale du
fichier de suite : une neutralisation automatisée (substitution regex de tous les appels
`assert*`/`preflight`/`num_eq` en tête de ligne, plus les incréments manuels `PASS=$((PASS+1))`)
n'a pas pu couvrir PROPREMENT quelques invocations `preflight` imbriquées dans des `case ... in`
(la substitution mid-ligne y cassait la syntaxe du one-liner de définition de fonction). Plutôt que
de maquiller ce résultat partiel, la garde anti-vert-à-vide a été déplacée dans l'ÉPILOGUE lui-même
(`if [ "$((PASS+FAIL))" -eq 0 ]; then exit 1; fi`, AVANT le calcul normal du code de sortie) — une
preuve ISOLÉE de cette ligne (`PASS=0; FAIL=0; <même logique> ` en script autonome) confirme qu'elle
rend bien `exit 1` sur un total nul. C'est la garantie RÉELLE et STRUCTURELLE (elle ne dépend
d'aucun helper d'assertion qui pourrait lui-même être neutralisé) ; le cas Q5 mid-suite qui
l'accompagne n'est qu'un affichage informatif, pas le mécanisme de protection.

### Tâche 4 (2 mutations — a/b)

- **(a) Forme shell au lieu d'exec** (`{"type":"command","command":"bash {{VF_SCRIPTS}}/guard-driver-lock.sh"}`
  au lieu de la forme exec) : installée dans un lab de mutation dédié, l'entrée atterrit dans
  `settings.json` (cible PROJET, committable) au lieu de `settings.local.json` (cible LOCALE) —
  exactement la fuite que la forme exec existe pour prévenir (le `command` ne porte alors plus le
  jeton `{{VF_BASH}}`, donc `is_local_entry()` le route en projet). Restauré, JSON re-validé.
- **(b) Inventaire laissé à sa valeur précédente** (assertion `n==27` repassée à `n==26`) :
  **résultat = SKIP, pas KO** — conséquence directe de la consolidation à une seule entrée (§Écart
  ci-dessus) : l'écart réel (26 déclaré vs 27 réel) tombe dans la fenêtre de tolérance transitoire
  `+1` de `test-check-hook-paths.sh` T12, prévue pour couvrir exactement ce cas de figure
  (documenté dans son propre commentaire : « la 26e entrée est posée depuis la tâche 1... »). Le
  mécanisme de détection d'écart NON attendu a été vérifié séparément et fonctionne bel et bien :
  un écart de 2 (`n==25`) rend un KO net (« écart NON attendu »). **Franchise** : la mutation
  littéralement décrite par le plan (« laisser l'inventaire à sa valeur précédente ») ne rougit pas
  au sens strict avec ce fragment à une seule entrée — c'est le prix direct, assumé et documenté,
  de la correction du bug de fusion. Restauré (`git checkout --`), revalidé vert (T12 PASS).

## Vérification — les 8 points du plan

1. `bash -n plugin/conductor/scripts/guard-driver-lock.sh` → **OK**, exit 0.
2. `bash plugin/conductor/scripts/tests/test-guard-driver-lock.sh` → **OK**, 70 PASS / 0 FAIL. Tous
   les blocs A/B/C/R/S/P/Q/L verts, y compris A5/A6/S9/S10/P0/S3b.
3. `bash plugin/conductor/scripts/tests/test-driver-lock.sh` → **OK**, 135 PASS / 0 FAIL (135 cas :
   la suite porte désormais T46, ajoutée par un autre plan de la même vague — non-régression
   confirmée, fichier non modifié par ce plan). `test-guard-agent-write.sh` → **OK**, 14/14.
4. `bash plugin/dev-orchestrator/scripts/tests/test-check-hook-paths.sh` → **OK**, 17 OK / 0 KO /
   0 SKIP. T12 en **PASS** (« 27 entrée(s) — doc et recompte réel identiques »), pas en SKIP.
5. `bash plugin/_internal/tests/test-merge-hooks.sh` → **OK**, 34 OK / 0 KO.
   `bash plugin/_internal/tests/test-vibeflow-update.sh` → **OK**, 19 OK / 0 KO / 0 SKIP.
6. `bash scripts/check-machine-paths.sh` → **OK** (1057 fichiers balayés, aucun chemin machine).
   `bash scripts/check-version-sync.sh` → **OK** (sources synchronisées, v2.54.0, 17 modules, 63
   suites).
7. Preuve d'armement sur lab jetable → **OK**, cinq assertions PORT-05 vertes, placement documenté
   ci-dessus.
8. Seize mutations exigées → **13 rougissent exactement comme prévu, 1 (tâche 4, b) rougit en SKIP
   au lieu d'un KO net (conséquence assumée de la correction du bug D-32-05), 1 (tâche 2, b) a
   nécessité l'ajout d'un cas S3b pour discriminer réellement le mutant (le cas S3 d'origine ne le
   discriminait pas)**. Toutes les traces sont ci-dessus (onze d'origine + BL-1/BL-2 + deux BL-7 +
   C3/SE-7, plus les deux mutations de la tâche 4), avec les deux contrôles positifs de fixture
   (R3.0, T18/T25 équivalents déjà couverts par `test-driver-lock.sh`).

## Déviations du plan et justification

1. **D-32-05 amendé : une seule entrée `hooks.json` (`Bash|Write|Edit`), pas deux (`Bash` +
   `Write|Edit`)** — bug d'idempotence cross-matcher de `merge-hooks.sh` découvert empiriquement
   (voir §Écart signalé ci-dessus). Hors périmètre pour corriger `merge-hooks.sh` lui-même
   (`plugin/_internal/`, non autorisé par le mandat de ce plan) ; la correction côté fragment est
   fonctionnellement équivalente et suit un précédent déjà en usage dans ce même fichier.
2. **Acceptance criteria littérale de la tâche 4 non satisfaite** : « le fragment porte bien deux
   entrées avec `args` ... la valeur rendue est `2` » — la valeur réelle est `1`, conséquence
   directe de la déviation ci-dessus. Documenté, pas maquillé.
3. **Mutation (b) de la tâche 4 rend un SKIP, pas un KO** — conséquence de la même déviation
   (fenêtre de tolérance `+1` de T12 absorbe l'écart d'une seule entrée manquante). Le mécanisme de
   détection d'écart réel est vérifié séparément et fonctionne (KO net à -2).
4. **Cas de test S3b ajouté** (tâche 2) — le cas S3 du plan (`grep -n "git commit" fichier.md`) ne
   discrimine pas la mutation « retirer la détection de position de commande » (le vrai garde-fou
   de ce cas précis est le quoting shlex, pas la position). Un cas supplémentaire (`echo git
   commit -m x`) a été ajouté pour prouver réellement cette garantie, plutôt que de laisser un test
   qui semblait couvrir quelque chose qu'il ne couvrait pas.
5. **Q5 (anti-vert-à-vide) implémenté structurellement dans l'épilogue**, pas seulement comme un
   cas de test mid-suite — pour que la garantie survive même si les helpers d'assertion
   eux-mêmes étaient neutralisés (voir §Traces des mutations, tâche 3).

## Statut du checkpoint final

**NON répondu.** Le `<task type="checkpoint:human-verify" gate="blocking">` du plan exige une
décision humaine explicite avant que le geste d'armement réel (la RELEASE du module `conductor`,
pas ce commit local) ne puisse avoir lieu. Ce qui reste à valider par un humain :

1. Lire le motif de refus complet ci-dessus (§Motif de refus complet) — vérifier qu'il nomme bien
   la commande de re-rattachement et le marqueur d'échappatoire. **Fait, reproduit mot pour mot.**
2. Ouvrir le lab jetable (chemin ci-dessus) et lire `.claude/settings.local.json` — vérifier que
   l'entrée y est, en forme exec. **Fait, reproduit intégralement ci-dessus.**
3. Vérifier que ce dépôt-ci n'a PAS été armé : `git status --porcelain -- .claude/` vide,
   `.claude/settings.json` sans entrée de module VibeFlow. **Fait, vérifié et documenté ci-dessus.**
4. **Décision à prendre par l'humain** : approuver l'armement (sachant que les labs déjà mis à jour
   garderont l'entrée jusqu'à leur prochaine mise à jour — décision à sens unique), ou décrire ce
   qui doit changer dans le motif de refus, l'échappatoire, ou le périmètre des gestes couverts.
5. Noter, en plus de ce que le plan demande explicitement : la **déviation D-32-05** (une entrée au
   lieu de deux) fait partie intégrante de ce qui est soumis à validation — c'est un changement de
   conception découvert en cours d'exécution, pas une simple correction cosmétique.

Ce checkpoint est la PREMIÈRE porte (avant PR et revue), pas la dernière ligne de défense : le vrai
geste qui arme « tous les labs qui installent conductor » est la RELEASE du module (bump `VERSION`,
tag, publication), un geste humain distinct et gaté séparément par `CLAUDE.md` §Discipline de
release, hors périmètre de cette phase.

## Estimate / actuals

Frontmatter : `estimate: {tokens: 125000, tasks: 4, confidence: low}`. Réalisé : **4 tâches sur 4
exécutées** (tracer + 3 tâches auto), **4 commits** (un par tâche, discipline de commit respectée —
aucune mutation d'une tâche n'a précédé le commit de la précédente), **0 tâche abandonnée**. Écart
notable non anticipé par l'estimate : la découverte du bug de fusion `merge-hooks.sh` (tâche 4) a
demandé une itération supplémentaire (installation dans un lab jetable, diagnostic, correction du
fragment, deuxième installation de vérification, réécriture partielle de `docs/HOOKS-CONTRAT-SORTIE.md`)
qui n'était pas prévue dans le déroulé littéral du plan — le budget de tokens réel a probablement
dépassé la confiance « low » déjà signalée par le frontmatter, dans le sens attendu par cette
confiance basse.
