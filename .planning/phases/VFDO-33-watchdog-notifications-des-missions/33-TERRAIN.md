# Terrain — surfaces réelles que la Phase 33 doit consommer

> Relevé le 2026-08-17 par recon lecture seule, en ouverture de mission. Chaque fait porte son
> chemin et sa ligne. À relire AVANT de planifier : trois prémisses courantes sont fausses.

## 1. Le battement (LOCK-01) — `plugin/conductor/scripts/driver-lock.sh` (569 l.)

**Verbes** : `acquire | heartbeat | release | status | recover | takeover | reclaim`
(parseur L49). Flags : `--owner=`, `--step=`. Sortie = **JSON une ligne**, exit 0 = succès,
exit 1 = refus.

- `heartbeat --owner=` → `{"ok": true, "owner": "...", "heartbeat_epoch": <epoch>}` (L505) ;
  refus `{"ok":false,"reason":"no-lock"}` (L499) ou `"not-owner"` + `held_by` (L508).
- `status` (L300-318) →
  `{"present","owner","step","age_seconds","ttl","stale","generation","session_ids","lease_seconds","guard_effective"}`.

**Persistance** : le lock public est un **lien symbolique** vers un dossier de génération, remplacé
atomiquement par `rename(2)`. Le meta (`$LOCK_DIR/meta`, L41) est en `clé=valeur`, une par ligne,
coupure sur le **premier `=`** :
```
owner= / step= / branch= / worktree= / session_ids= / acquired_epoch= / acquired_iso= / heartbeat_epoch=
```
**Journal append-only** : `.planning/DRIVER.lock.events.log` (frère du lock, jamais dedans — le
dossier de génération est détruit par les reprises). Une ligne JSON par événement
`takeover|reclaim|recover` uniquement — **jamais `acquire`, jamais `heartbeat`**. Best-effort, sans
rotation ni plafond (MI-4 assumé). Un 4ᵉ producteur y écrit un format ad hoc :
`guard-driver-lock.sh:163-179` (`"event":"override"`).

**Deux horloges découplées, à ne pas confondre** :
- `heartbeat_epoch` → `age_seconds` → `stale` → **TTL (1800 s)**. Seule source de péremption.
- `acquired_epoch` → `lease_seconds`. **INFORMATIONNEL SEUL** — n'entre dans aucun calcul de
  péremption ni refus (docstring L173-180 ; 2 mutations rouges le prouvent). Une borne de durée
  totale contredirait frontalement « lock périmé ≠ mission morte ».

**Contrat changé en Phase 32 (LOCK-04)** : `acquire` face à un lock périmé **REFUSE** —
`{"acquired": false, "reason": "stale-requires-takeover", "held_by", "age_seconds", "hint"}`
(L365-374), le `hint` nommant `takeover --owner=… --step=…`. La danse mutex + double revalidation
a déménagé telle quelle sous `takeover`.

> ### Réponse sans ambiguïté à WTCH-01
> **Il n'existe AUCUNE notion de battement par NŒUD. Le battement est strictement par
> DRIVER/MISSION** — un seul `meta`, un seul `heartbeat_epoch`. `--step` n'est qu'un champ texte
> écrasé en place, pas une clé d'indexation. `dag.sh` n'appelle jamais `driver-lock.sh`.
> Le grain nœud est **du neuf** : soit `driver-lock.sh heartbeat` gagne un grain (`--node=`), soit
> `dag.sh mark` appelle `driver-lock.sh heartbeat`. Rien n'existe aujourd'hui.

## 2. Le DAG — `plugin/conductor/scripts/dag.sh` (359 l.)

Bash mince + un heredoc python qui porte tout. Actions : `init|add|ready|mark|reopen|status|tree`.
Schéma d'un nœud (L223-225), **union des clés vérifiée sur un DAG réel de 17 nœuds** :
`{id, step, stage, deps[], scope[], status}` (+ `review_regime:"full"` écrit **uniquement** par
`reopen` sur les nœuds `revue-`/`join-`).

**Points de transition d'état — accroches naturelles du battement et de la notification** :
1. `recompute()` L90-96 — `blocked ↔ ready` en masse, ne touche jamais `running/done/failed` ;
2. `add` L226 (`status="blocked"`) ;
3. **`mark` L246 — `idx[nid]["status"] = status`** : point d'entrée UNIQUE des transitions
   explicites `running`/`done`/`failed`. **C'est l'accroche de WTCH-01 et de la notification
   « fin de nœud » (WTCH-03)** ;
4. `reopen` L268-270.

> **`dag.sh` n'écrit AUCUN horodatage** — zéro import `time`/`datetime` (L67 :
> `sys, os, json, subprocess, tempfile, shutil`). Confirmé sur DAG réel. Le seul horodatage
> exploitable aujourd'hui est le `mtime` du fichier `.dag.json` — grain fichier, pas grain nœud.

⚠ `save(dag)` L78-82 est une **réécriture complète NON atomique** (`open(file,"w")`, pas de
tmp+rename) — à considérer si un lecteur watchdog concurrent lit le fichier.

## 3. Le gate armement ↔ précondition (WTCH-04) — le poste de coût caché

- **Gate** : `plugin/dev-orchestrator/scripts/check-capability-activation.sh` (779 l.)
- **Suite** : `.../tests/test-check-capability-activation.sh` (1494 l.) — **60 cas, 60 OK / 0 KO**
- Codes : `0` conforme · `1` écart · `2` NON VÉRIFIABLE · `64` usage.

**Règle 4** (L723-754) : tout artefact distribué portant une clé de la **liste close** d'armements
(`ARM[]` L494-505 : `isolation`, `vf-mcp-consumer`, `vf-mcp-tools` — **jamais surchargeable par
env**) est ROUGE sans sa précondition distribuée. Le rouge naît de l'**armement seul** ;
`vf-requires` ne fait que le lever. **Règle 4bis** (L756-769) : un `vf-requires:` citant un id
absent de `OKID[]` (`worktree-baseref`, `mcp-servers`) est halluciné → rouge.
Quatre planchers anti-vert-à-vide (L657-675) → sortie **2**, jamais 0.

**Recette pour armer légalement** :
(a) l'artefact déclare `vf-requires: <id>` en frontmatter ;
(b) l'`<id>` doit figurer dans `OKID[]` — **aujourd'hui seuls `worktree-baseref` et `mcp-servers`
existent**, donc un nouvel id **exige d'éditer la table L508-509 du gate lui-même + un cas de
test** ;
(c) un script **distribué** porte en tête la ligne littérale `# vf-provides: <id>` (regex L612 ;
exemple vivant unique : `inject-mcp-tools.sh:106`) ;
(d) le nouvel armement doit entrer dans `ARM[]` sinon la règle 4 ne le voit pas.

**Borne à citer** (L113-116) : la règle 4 établit une **couverture déclarée, pas effective** — elle
vérifie qu'un `# vf-provides:` existe, pas que la précondition est satisfaite chez l'utilisateur.

## 4. Pose par l'engine et hooks

**Pose** : `plugin/_internal/vibeflow-update.sh:1204-1211` pose `plugin/<mod>/scripts/*.sh|*.mjs|*.js`
**par GLOB**, à plat en `$TARGET_ROOT/scripts/`, mode exec. Sites voisins : `scripts/*.txt`
(données, L1219), **`scripts/tests/*.sh` + fixtures (L1231-1247)**. Le même glob alimente le
`.gitignore` (L881) et le backup pré-update (L1672).
→ **Aucune liste blanche à amender : déposer `plugin/conductor/scripts/notify.sh` SUFFIT**, et sa
suite de tests est posée automatiquement elle aussi.
La lib `vf-portable.sh` suit un autre chemin : `copy_engine_lib()` L995-1045, non exécutable,
exclue du manifeste (L229).

**Format `hooks.json`, forme exec (D-32-C)** — `plugin/conductor/hooks/hooks.json` :
```json
"PreToolUse": [
  { "matcher": "Bash|Write|Edit",
    "hooks": [ { "type": "command", "command": "{{VF_BASH}}",
                 "args": ["{{VF_SCRIPTS}}/guard-driver-lock.sh"] } ] } ],
"SessionStart": [
  { "matcher": "startup",
    "hooks": [ { "type": "command", "command": "{{VF_BASH}}",
                 "args": ["{{VF_SCRIPTS}}/check-guard-health.sh", "--hook"] } ] } ]
```
Placeholders `{{VF_BASH}}` / `{{VF_SCRIPTS}}`. **Forme exec = zéro expansion shell**, donc pas de
`|| true` : chaque script porte sa propre traduction de code (`hook_exit`).

> ### ⚠ Bug d'idempotence cross-matcher — `CONCERNS.md:28-53`, sévérité HIGH, NON CORRIGÉ
> Deux entrées référençant le **même script** sous le **même événement**, même avec des matchers
> différents, **se purgent l'une l'autre à l'installation** — seule la dernière survit, **sans
> erreur ni avertissement**. Découvert en 32-03 : la forme à deux entrées (`Bash` puis
> `Write|Edit`) faisait disparaître l'entrée `Bash`, désarmant la moitié d'un garde de sécurité.
> Contournement retenu (pas une correction) : **une seule entrée à matcher combiné**, le script
> dispatchant lui-même sur `tool_name`. Le trou de test subsiste dans
> `plugin/_internal/tests/test-merge-hooks.sh` : il couvre l'upgrade en deux appels, jamais le
> même-run, qui est le scénario mordant.
> **Règle opérationnelle Phase 33 : jamais deux entrées séparées, même événement, même script.**

## 5. Le canal « bruyant non bloquant » — hook doctor de la Phase 32, à RÉUTILISER

**Producteur** : `vf_guard_unavailable <script> <motif>` — `plugin/_internal/lib/vf-portable.sh:145-158`.
Trois actions toujours ensemble : (1) écrit le marqueur en **écriture atomique** (tmp `$$` + `mv -f`),
(2) imprime `[$script] $motif` sur **stderr**, (3) **retourne** (jamais `exit`)
`VF_GUARD_UNAVAILABLE_EXIT_CODE=17` (jamais 0 ni 2 — sur un PreToolUse, 2 bloquerait).

Marqueur — **une ligne, trois champs séparés par TABULATION** (L152) :
```
<ts ISO UTC %Y-%m-%dT%H:%M:%SZ>\t<nom du script>\t<motif>
```
Chemin, dérivation à respecter au caractère près (L147) :
```
${VF_GUARD_HEALTH_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/vibeflow/guard-health}/<script>.marker
```
Le marqueur est **RÉÉCRIT** (jamais append) — c'est ce qui donne un sens à la fenêtre de fraîcheur.

**Consommateur** : `plugin/conductor/scripts/check-guard-health.sh` (185 l.), **`SessionStart`
matcher `startup`**, forme exec, `--hook`. Flags : `--hook`, `--quiet`, `--dir=`, `--window=`
(défaut 86400 s). Contrat à **4 codes** : `0` signal · `3` SAIN vérifié · `4` INDÉTERMINÉ
(répertoire illisible — jamais confondu avec sain) · `64` usage ; `hook_exit()` traduit 3 et 4 → 0
sous `--hook` seulement. Sortie : **UNE SEULE ligne** stdout, jamais une par marqueur.
**Lecture seule stricte** : jamais de `rm`/`mv`/`touch` — un lecteur qui élaguerait serait un
correcteur déguisé (ADR-031).

Le lecteur est **générique** : il agrège les marqueurs de **tout** le parc. → un producteur
Phase 33 (heartbeat illisible) **n'a rien à câbler** : il appelle `vf_guard_unavailable`, le doctor
l'affiche. **Couplage critique** : la dérivation du répertoire est dupliquée à l'identique chez
l'écrivain et le lecteur — un écart rendrait le doctor aveugle sans jamais le signaler.

## 6. Facture de référence — `guard-driver-lock.sh` + sa suite

Script 444 l. (bash mince + **un seul** spawn python qui porte toute la décision) ; suite
`tests/test-guard-driver-lock.sh` 413 l. → **80 assertions, 80 PASS / 0 FAIL** (mesuré).

Conventions (pas de harness partagé, « convention du dossier ») : `set -uo pipefail` **sans `-e`** ;
`mktemp -d` + `trap` ; **5 helpers** (`assert`, `assert_empty`, `assert_exit`, `num_eq`,
**`preflight`** — séparé des assertions métier : « fixture cassé, pas de verdict métier ») ;
**4 fabriques de payload en python** (échappement JSON fiable, jamais par concaténation) ; familles
nommées `A/B/R/P/S1-S12/C1-C5/L1/Q3-Q5` ; **cas de DISCRIMINANCE marqués « ne JAMAIS retirer »**
(sans eux la suite serait verte avec un guard qui refuse tout) ; limites **assumées** testées en
ALLOW et nommées.

**Les QUATRE issues (jamais trois — D-32-QUAL)** :
| Issue | Assertion |
|---|---|
| PASS (allow silencieux) | `assert_empty` — stdout **strictement vide** |
| DENY | `'"permissionDecision": "deny"'` |
| imparsable → fail-open **SILENCIEUX** | **code 0 ET stdout vide**, les deux assertés |
| interprète indisponible → fail-open **BRUYANT** | **4 assertions liées** : `exit 17` · stdout vide · stderr préfixé du nom du script · **marqueur présent** dans un `VF_GUARD_HEALTH_DIR` de bac à sable, avec préflight vérifiant que le PATH est *réellement* privé de python |
| anti-vert-à-vide | double garde : cas mid-suite **et** garde structurelle d'épilogue (`PASS+FAIL == 0` → exit 1) |

**Mutation rouge** : elle n'est **pas** dans la suite — c'est une exigence de **process**, consignée
en SUMMARY avec pour chaque mutation *assertion exacte, attendu, obtenu*
(`32-01-SUMMARY.md:136-160`). ⚠ Piège documenté : `git checkout -- <script>` pour restaurer après
mutation a **effacé du travail non commité** — **committer AVANT toute mutation destructive**.

Suites sœurs mesurées : `test-driver-lock.sh` **151 PASS**, `test-dag.sh` **99 PASS**,
`test-check-capability-activation.sh` **60 OK**.

## 7. Découverte complète des suites (non-régression)

```
find plugin scripts -type f -path '*/tests/test-*.sh' | wc -l   →   64
```
Runner CI : `.github/workflows/ci.yml`, étape « Découvrir et lancer toutes les suites » ;
**ligne de découverte L213** : `suites=$(find plugin scripts -type f -path '*/tests/test-*.sh' | sort)`.
Assertion F13 (L216-219) : `count == 0` → erreur, « la CI refuse de rendre un verdict vide ».
→ une nouvelle suite `plugin/conductor/scripts/tests/test-<x>.sh` est découverte **et** posée
automatiquement. Aucun registre à amender. Deux suites Windows sont lancées en plus (L915, L917).

## 8. Versions

Racine **v2.55.0** · `plugin/conductor` **v1.26.0** · `plugin/dev-orchestrator` **v2.17.3**
(17 modules portent un `VERSION` ; `_internal` et `installer` n'en ont pas).

## Trois faits à retenir

1. **WTCH-01 part de zéro** : le battement est per-mission, jamais per-nœud, et `dag.sh`
   n'horodate rien. L'accroche unique et propre est `dag.sh:246` (`mark`), qui est aussi le point
   naturel de la notification « fin de nœud » (WTCH-03).
2. **WTCH-03 est presque gratuit côté engine** — mais le bug cross-matcher de `merge-hooks.sh`
   peut désarmer le hook **en silence** si on pose deux entrées.
3. **WTCH-04 exigera d'ÉDITER le gate** : `ARM[]` et `OKID[]` sont littérales et explicitement non
   surchargeables. Nouvel armement ou nouvel id = modification du gate + cas dans sa suite de 60.
