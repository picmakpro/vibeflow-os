# Phase 32 Plan 05 : check-guard-health.sh — le hook doctor générique (QUAL-01) — Summary

**Statut : les 3 tâches exécutées et committées, vertes. Aucun checkpoint bloquant dans ce plan.**

## Ce qui a été livré

`plugin/conductor/scripts/check-guard-health.sh` — un lecteur `SessionStart` **générique** des
marqueurs de santé écrits par `vf_guard_unavailable` (Phase 30, `plugin/_internal/lib/vf-portable.sh`),
jusqu'ici **sans aucun consommateur** dans tout `plugin/` (re-mesuré en tête de mandat :
`grep -rn "guard-health\|VF_GUARD_HEALTH_DIR" plugin/ scripts/` hors `vf-portable.sh` et `tests/` →
zéro résultat). C'est le « hook doctor » spécifié depuis le 2026-08-02
(`docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md:205-207`) et jamais écrit.

Contrat à quatre codes identique à `check-branch-claim.sh` (0 = signal, 3 = SAIN, 4 = INDÉTERMINÉ,
64 = usage), lecture seule stricte, une seule ligne au maximum sur stdout, stdout strictement vide
en nominal. **Générique** (D11) : agrège les marqueurs de TOUS les gardes du parc, pas seulement
celui du driver-lock — c'est ce qui justifie de le loger dans `conductor` (module `mandatory`,
présent dans toute fermeture installée).

## Commits produits

| SHA court | Sujet |
|---|---|
| `476b7eb` | feat(conductor): check-guard-health.sh — le hook doctor générique, quatre codes (QUAL-01) |
| `91173ce` | test(conductor): check-guard-health.sh — D13, boucle bout en bout (QUAL-01) |
| `fc6f78e` | feat(conductor): arme check-guard-health.sh via hooks.json — inventaire durable à jour (QUAL-01) |

## Fichiers modifiés/créés

- `plugin/conductor/scripts/check-guard-health.sh` (neuf)
- `plugin/conductor/scripts/tests/test-check-guard-health.sh` (neuf, cas D1-D13, 31 assertions, exit 0)
- `plugin/conductor/hooks/hooks.json` (une entrée `SessionStart` neuve, forme exec)
- `docs/HOOKS-CONTRAT-SORTIE.md` (inventaire 27 → 28, tableau conductor, décompte advisory)
- `README.md` / `README.fr.md` (compteur de suites 63 → 64)
- `.planning/phases/VFDO-32-durcissement-du-driver-lock/32-05-SUMMARY.md` (ce fichier)

## Ligne de fixture de marqueur au format réel (D-04)

Format écrit par `vf_guard_unavailable` (`plugin/_internal/lib/vf-portable.sh:152`), reproduit à
l'identique par la suite (`write_marker()`) :
```
printf '%s\t%s\t%s\n' "$ts" "$script" "$motif" > "$health_dir/${script}.marker"
```
c'est-à-dire une seule ligne `horodatage-ISO8601-UTC\tscript\tmotif\n`. Toute évolution future du
format côté lib (ex. champ additionnel) est repérable en comparant cette ligne à la fonction citée.

## Écart signalé (constaté sur pièce, pas dans le plan) — 2 entrées à `args` dans conductor, pas 3

Le frontmatter du plan attendait, après la tâche 3, **3 entrées à `args`** dans
`plugin/conductor/hooks/hooks.json` (« les deux entrées du plan 32-03 plus celle-ci »). Vérifié
**sur pièce en tête de mandat** (le mandat lui-même signalait que `hooks.json` avait bougé deux
fois le même jour) : `32-03-SUMMARY.md` documente que le plan 32-03 n'a en réalité posé **QU'UNE
SEULE entrée à `args`** (`guard-driver-lock.sh`, matcher combiné `Bash|Write|Edit` — bug
d'idempotence cross-matcher de `merge-hooks.sh`, deux entrées séparées se purgeant l'une l'autre à
l'installation). Cette tâche 3 en ajoute donc une **seconde**, pas une troisième :

```
$ python3 -c "
import json
d=json.load(open('plugin/conductor/hooks/hooks.json'))
print(sum(1 for gs in d['hooks'].values() for grp in gs for h in grp['hooks'] if 'args' in h))
"
2
```

Acceptance criteria de la tâche 3 réinterprété en conséquence (« recompte = 2 entrées à `args`, pas
3 »). Documenté, pas maquillé — même discipline de franchise que `32-03-SUMMARY.md` §Écart signalé.

## Preuve d'armement — lab jetable

**Chemin du lab** (jetable, hors de ce dépôt, supprimé après la preuve) :
```
/private/tmp/claude-501/-Users-samuel-Documents-dev-vibeflow-os/cc03f03a-d5b3-4c5e-a3b8-e238279f525d/scratchpad/lab-jetable-32-05
```

**Déroulé** : `git init` dans le lab, fermeture de `conductor` résolue par `resolve-deps.sh` (7
modules : `audit-architecture conductor consolidator infrastructure-audit planning-core
skill-creator validator`), installation de chaque module avec `VIBEFLOW_CACHE=<repo>/plugin
VF_SCOPE=project bash plugin/_internal/vibeflow-update.sh install <module>`.

**Entrée posée dans `.claude/settings.local.json` du lab** (cible LOCALE, non commitable) :
```json
{
  "type": "command",
  "command": "/bin/bash",
  "args": ["${CLAUDE_PROJECT_DIR}/.claude/scripts/check-guard-health.sh", "--hook"]
}
```
dans son propre groupe `SessionStart · startup` (à côté du groupe `PreToolUse` de
`guard-driver-lock.sh`, posé par le plan 32-03) — les cinq entrées `SessionStart` shell existantes
du module restent dans `.claude/settings.json` (cible PROJET), comme attendu.

**Cinq assertions PORT-05, toutes vertes** :
1. `command` absolu, existant, exécutable : `/bin/bash`.
2. Aucun métacaractère shell dans `command`/`args` du fragment `conductor`, hors placeholder
   harness `${CLAUDE_PROJECT_DIR}` (grep ciblé, liste vide).
3. Aucun placeholder résiduel (`{{...}}`) dans l'un ou l'autre fichier de réglages du lab.
4. Compte d'entrées `args` dans les deux fichiers réunis == compte réel constaté : **2 = 2**
   (`guard-driver-lock.sh` + `check-guard-health.sh`).
5. Idempotence : réinstallation de `conductor` dans le même lab → toujours exactement 1 occurrence
   de `check-guard-health.sh` (pas de duplication).

**Silence nominal TEL QU'INSTALLÉ, mesuré en octets** : le script installé dans le lab
(`.claude/scripts/check-guard-health.sh`), invoqué avec `--hook` sur un répertoire de santé vide,
rend **0 octet** sur stdout et un code de sortie 0 :
```
bash .claude/scripts/check-guard-health.sh --hook --dir="$EMPTY_DIR"
rc=0 bytes=0
```

**Le dépôt courant N'A PAS été armé** : `git status --porcelain -- .claude/` rend une sortie vide
en fin de tâche 3.

## Boucle producteur → marqueur → lecteur (D13, tâche 2)

D13 reprend le montage du cas Q4 de `test-guard-driver-lock.sh` : un dossier de binaires sans
interprète Python, un répertoire de santé redirigé. Le vrai `guard-driver-lock.sh` est invoqué (pas
de marqueur fabriqué à la main) → code 17, stdout vide, marqueur écrit. Le vrai
`check-guard-health.sh` lit ensuite ce répertoire → exit 0, une ligne nommant `guard-driver-lock.sh`.
D13 rend un **succès réel**, pas un SKIP (le plan 32-03 est présent sur cet arbre, `guard-driver-lock.sh`
et `driver-lock.sh` existent et sont exécutables).

## Traces des mutations exigées

### Tâche 1 (5 mutations — a/b/c/d/e)

- **(a) Filtre de fenêtre de rapport retiré** (`if [ "$age" -le "$WINDOW" ]` → `if true`) : D5
  rougit sur ses 2 assertions (exit et stdout vide). Attendu : exit 3, stdout vide (marqueur
  périmé). Obtenu : exit 0, une ligne signalant `old-guard.sh`. Restauré, revalidé vert.
- **(b) Élagage des marqueurs après lecture** (un `find … -exec rm -f {} \;` injecté juste avant
  l'émission du signal) : D9 rougit (1 FAIL). Attendu : répertoire identique avant/après. Obtenu :
  fichier disparu après exécution. Restauré, revalidé vert.
- **(c) SAIN rendu quand le répertoire est illisible** (`indetermine "..."` remplacé par
  `diag "SAIN (mutation c)…"; hook_exit 3`) : D4 rougit sur 2 assertions (exit et diagnostic
  stderr). Attendu : exit 4, stderr disant INDÉTERMINÉ. Obtenu : exit 3, stderr disant SAIN.
  Restauré, revalidé vert.
- **(d) Une ligne PAR marqueur au lieu d'une seule** (`echo "[guard-health] MUTATION-D …"` injecté
  dans la boucle, avant l'agrégation) : D6 rougit sur son assertion de comptage de lignes
  (`=5 attendu 1`, plus une propagation sur D1). Attendu : 1 ligne. Obtenu : 1 ligne par marqueur
  fraîchement traité + la ligne finale. Restauré, revalidé vert.
- **(e) Diagnostic émis sur stdout dans le chemin SAIN** (`echo "MUTATION-E…"` injecté avant le
  `diag`/`hook_exit 3` du chemin « aucun marqueur frais ») : D2 rougit sur sa moitié « stdout
  strictement vide » (1 FAIL). Attendu : stdout vide. Obtenu : `MUTATION-E diagnostic egare sur
  stdout`. Restauré, revalidé vert.

**Anti-vert-à-vide (D12)** : neutraliser tous les appels `ok`/`ko` de la suite par substitution
regex automatisée **n'a pas fonctionné** (la plupart des invocations sont mid-ligne,
`[ ... ] && ok "…" || ko "…"`, jamais en tête de ligne — le résultat restait 27/0 après
« neutralisation »). Plutôt que de forcer une neutralisation partielle non fiable, la garantie
**structurelle** de l'épilogue (`if [ "$((PASS+FAIL))" -eq 0 ]; then exit 1; fi`, même patron que
`test-guard-driver-lock.sh` Q5) a été prouvée **isolément**, hors du fichier de suite :
```
$ bash -c 'PASS=0; FAIL=0; if [ "$((PASS+FAIL))" -eq 0 ]; then echo "ECHEC ANTI-VERT-A-VIDE"; exit 1; fi; [ "$FAIL" -eq 0 ] && exit 0 || exit 1'
ECHEC ANTI-VERT-A-VIDE
isolated exit=1
```
C'est la garantie réelle : elle ne dépend d'aucun helper d'assertion qui pourrait lui-même être
neutralisé. Même précédent déjà documenté dans `32-03-SUMMARY.md` §Traces (Q5).

### Tâche 2 (1 mutation)

- **`vf_guard_unavailable` remplacé par une sortie zéro muette** dans `guard-driver-lock.sh`
  (`if ! vf_resolve_python --fast; then exit 0; fi`) : D13 rougit sur ses 4 assertions. Attendu :
  code 17, stdout vide, exit 0 du lecteur avec une ligne nommant le garde. Obtenu : code 0 du
  producteur (aucun marqueur écrit), exit 3 du lecteur (SAIN, rien à lire), aucune ligne. Restauré
  (`guard-driver-lock.sh` identique à son état d'avant mutation, `diff` vide), revalidé vert.

### Tâche 3 (2 mutations — a/b)

- **(a) Suffixe d'échappement d'échec ajouté à l'entrée neuve** (`"command": "{{VF_BASH}} || true"`
  au lieu de `"{{VF_BASH}}"`) : installée dans un lab de mutation dédié, un métacaractère shell
  (`||`) apparaît dans `command` de l'entrée `SessionStart` de `check-guard-health.sh` telle
  qu'installée dans `settings.local.json` (`/bin/bash || true`) — exactement la fuite que la forme
  exec existe pour prévenir. Restauré, JSON re-validé, fragment identique (`diff` vide).
- **(b) Inventaire laissé à sa valeur précédente** (assertion `n==28` repassée à `n==27`, ligne
  narrative aussi) : **résultat = SKIP transitoire de T12, pas un KO net** — même mécanisme de
  tolérance `+1` déjà documenté dans `32-03-SUMMARY.md` (« la 26e entrée… l'inventaire durable
  n'est mis à jour QUE par sa tâche 3 »), reproduit ici à l'identique pour l'écart -1 (27 déclaré
  vs 28 réel). **Franchise** : la mutation littéralement décrite par le plan (« déclenche un écart
  T12 avec le message d'écart NON attendu ») ne rougit pas au sens KO avec ce mécanisme de
  tolérance — c'est un SKIP. Le mécanisme de détection d'écart NON attendu a été vérifié
  **séparément et fonctionne** : un écart de 2 (`n==26` déclaré vs 28 réel) rend un KO net
  (« écart NON attendu »). Restauré (`diff` vide), revalidé vert (T12 PASS, 17 OK / 0 KO / 0 SKIP).

## Franchise — le point le plus important de ce mandat

Le mandat demandait explicitement : si un lecteur de marqueurs `SessionStart` ne peut pas être
réellement « bruyant » dans ce harness, le dire franchement. **Ce script L'EST**, et la preuve
tient en une phrase : le silence nominal mesuré tel qu'installé est de **0 octet**, et dès qu'un
marqueur récent existe, il émet **exactement une ligne sur stdout**, qui est injectée comme
contexte de session (documentation officielle Claude Code, citée dans
`docs/HOOKS-CONTRAT-SORTIE.md §3`) — donc **effectivement lue par le modèle au démarrage de la
session suivante**, sans dépendre d'un humain qui irait ouvrir un fichier. C'est exactement le
canal manquant que la mesure de tête de mandat (zéro consommateur du marqueur) signalait comme
absent. La boucle producteur → marqueur → lecteur est prouvée bout en bout par D13 avec les VRAIS
scripts, pas des doublures.

## Vérification — les 8 points du plan

1. `bash -n plugin/conductor/scripts/check-guard-health.sh` → **OK**, exit 0.
2. `bash plugin/conductor/scripts/tests/test-check-guard-health.sh` → **OK**, 31 PASS / 0 FAIL,
   blocs D1-D13 tous verts, D13 en **succès** (pas un saut).
3. `bash plugin/conductor/scripts/tests/test-guard-driver-lock.sh` → **OK**, 80 PASS / 0 FAIL
   (non-régression du producteur de marqueurs).
4. `bash plugin/dev-orchestrator/scripts/tests/test-check-hook-paths.sh` → **OK**, 17 OK / 0 KO /
   0 SKIP. T12 en **PASS net** (28 = 28, pas de skip transitoire — le doc a été mis à jour dans le
   même commit que hooks.json).
5. `bash plugin/_internal/tests/test-merge-hooks.sh` → **OK**, 34 OK / 0 KO.
   `bash plugin/_internal/tests/test-vibeflow-update.sh` → **OK**, 19 OK / 0 KO / 0 SKIP.
6. `bash scripts/check-machine-paths.sh` → **OK** (1062 fichiers balayés, aucun chemin machine).
   `bash scripts/check-version-sync.sh` → **OK** (v2.54.0, 17 modules, 64 suites).
7. Silence nominal tel qu'installé → **OK**, 0 octet mesuré et consigné ci-dessus.
8. Huit mutations exigées (5 tâche 1 + 1 tâche 2 + 2 tâche 3) → **toutes rougissent**, sept
   exactement comme prévu par le plan, une (tâche 3, mutation b) rougit en **SKIP** au lieu d'un
   KO net (conséquence assumée et documentée du même mécanisme de tolérance déjà rencontré et
   documenté par le plan 32-03) ; le mécanisme de détection réel est vérifié séparément et
   fonctionne (KO net à -2). Traces complètes ci-dessus.

## Découverte des suites — bilan post-commit

`find plugin scripts -type f -path '*/tests/test-*.sh' | sort | wc -l` → **64** après le dernier
commit de ce plan (63 avant, +1 : `test-check-guard-health.sh`). Correspond au compteur mis à jour
dans `README.md`/`README.fr.md` (64 suites), gaté vert par `check-version-sync.sh`.

## Coût mesuré du hook au démarrage de session

Silence nominal (cas dominant, aucun marqueur récent) : **0 octet sur stdout**, mesuré sur le
script tel qu'installé dans le lab jetable. Coût de calcul : un `ls -A` sur un répertoire de cache
utilisateur généralement vide ou à quelques entrées, plus au maximum une poignée de lectures de
première ligne de fichier (`read` bash, pas de spawn d'interprète) — aucun `python3`/`jq` invoqué
par ce script (`grep -cE 'python|jq'` sur les lignes de code rend 0). Le coût dominant du démarrage
de session est donc négligeable devant les autres entrées `SessionStart` déjà en place (qui, elles,
spawnent `python3` — `check-agents.sh`, `check-debug-research.sh`).

## Déviations du plan et justification

1. **2 entrées à `args` dans `conductor` après la tâche 3, pas 3** — conséquence directe et
   documentée de la déviation D-32-05 déjà actée par `32-03-SUMMARY.md` (une seule entrée posée par
   le plan 32-03, pas deux). Voir §Écart signalé ci-dessus.
2. **Mutation (b) de la tâche 3 rend un SKIP, pas un KO** — même mécanisme de tolérance `+1` de
   T12 que celui déjà rencontré et documenté par le plan 32-03. Le mécanisme de détection d'écart
   réel est vérifié séparément et fonctionne (KO net à -2). Voir §Traces des mutations, tâche 3.
3. **Fenêtre de rapport par défaut fixée à 86400s (24h)**, valeur non prescrite littéralement par
   le plan (qui ne fixait pas de chiffre) — choisie par analogie d'ordre de grandeur avec un cycle
   de travail quotidien : assez large pour ne pas perdre un marqueur écrit tôt dans une session
   longue, assez étroite pour qu'un problème réglé la veille cesse d'être signalé le lendemain.
   Surchargeable via `--window`.

## Estimate / actuals

Frontmatter : `estimate: {tokens: 85000, tasks: 3, confidence: low}`. Réalisé : **3 tâches sur 3
exécutées** (1 tracer + 2 auto), **3 commits** (un par tâche, discipline de commit respectée —
aucune mutation d'une tâche n'a précédé le commit de la précédente). **0 tâche abandonnée** malgré
le statut `abandonnable: true` du plan (Samuel a explicitement tranché QUAL B avant le mandat).
Écart notable non anticipé par l'estimate : la vérification empirique des compteurs sur pièce
(hooks.json et le document ayant bougé deux fois le même jour, comme signalé par le mandat) a
demandé une relecture complète de `32-03-SUMMARY.md` et plusieurs recomptages machine avant
d'écrire la moindre ligne de `hooks.json` — cohérent avec la confiance « low » déjà signalée par le
frontmatter.
