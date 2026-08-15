# 23-02 — REVIEW (regard frais, régime plein)

Revue de `3b68a02` · `9f235e0` · `9c756aa`. Read-only : aucun fichier du livrable n'a été modifié.
Périmètre : `check-gsd-config.sh`, `test-check-gsd-config.sh`, `hooks/hooks.json`, `.planning/config.json`.

**Verdict : correctifs requis.** 2 bloquants, 7 majeurs, 7 mineurs.

Toute affirmation ci-dessous est une **exécution**, jamais une relecture. Les mutants sont ancrés par
remplacement à occurrence unique (échec dur si l'ancre n'est pas unique) et comparés au fichier
d'origine (`cmp`) avant chaque mesure.

---

## Ce qui est vérifié SOLIDE (pour cadrer le reste)

Le worker a été honnête sur l'essentiel. J'ai rejoué et confirmé :

| Affirmation du SUMMARY | Vérification | Résultat |
|---|---|---|
| 26 cas, 0 KO | comptage indépendant des lignes `✓`/`✗` | **26 / 0**, exact |
| 6 mutations tuées par le cas prévu | 6 mutants rejoués un par un | **les 6 mordent**, cas exacts |
| union à 3 sources nécessaire | `_auto_chain_active` cherché dans le moteur installé | VALID `false`, configKeys `false`, CONFIG_DEFAULTS `true` — **le fait tient** |
| `|| true` du hook (`key_link`) | exécuté sur exit 3, 64, 127 et 2 | **tous ramenés à 0** |
| `engineExtra` = mirroir du moteur | comparé à `config-loader.cjs:654-655` | **10 littéraux, identiques et dans l'ordre** |
| cas 26 bidirectionnel dans un seul fichier | M5 (mirroir vidé) et M6 (`KNOWN_TOP` universel) | **chaque moitié tuée séparément — c'est bien deux sens, pas une co-présence** |
| rejet de l'élagage d'`engineExtra` | motif réexaminé | **motif juste**, et il devient *obligatoire* avec le correctif M-1 |
| bascule 0 → 3 sur ce lab | exécutée | **confirmée** |

Également vérifié et propre : aucun `eval`/`bash -c`/backtick hors commentaire ; aucune injection par
`--path '$(touch …)'` ; ADR-054 respecté (ni `grep -P`, ni `sed -i`, ni `mapfile`/`declare -A`/`${v,,}`) ;
suite verte sous **bash 3.2.57** réel ; latence du hook **0,06 s** (fourchette des 3 hooks existants :
0,03–0,12 s) ; `hooks.json` à 4 entrées, JSON valide, `description` remise à jour ; `.planning/config.json`
ne porte **que** les deux gestes prescrits (aucune clé hors périmètre déplacée) ; le mode 644 de la suite
est normalisé à l'install (`vibeflow-update.sh:342-343, 358`).

Le SUMMARY sur-déclare sur **une seule** ligne (`23-02-SUMMARY.md:118`) : le mutant « `gates`/`safety`
en dur » **additif** ne rougit que le cas 2 ; il faut la forme **substitutive** (la comparaison remplacée
par la liste) pour rougir 2/18/20/26. Détail de forme, pas de fond.

---

## BLOQUANT

### B-1 — Exécution de code arbitraire au `SessionStart` depuis le dépôt **audité**

`plugin/dev-orchestrator/scripts/check-gsd-config.sh:152-158` (cascade) + `:287` (`node -e` → `require`)

La cascade commence par `$ROOT/.claude/gsd-core/bin/lib`, **à l'intérieur du dépôt audité**, et le
programme node fait `require()` de ce fichier. Le hook tourne avec `--path .` = le cwd de la session.

Preuve exécutée :

```
$ cat "$EVIL/.claude/gsd-core/bin/lib/config.cjs"
require('fs').writeFileSync('/tmp/VF-RCE-PROOF','execute au SessionStart depuis le depot audite\n');
module.exports = { VALID_CONFIG_KEYS: new Set(['mode']) };

$ bash check-gsd-config.sh --path "$EVIL" --hook   # exit=0
$ cat /tmp/VF-RCE-PROOF
execute au SessionStart depuis le depot audite
```

Ouvrir une session dans un dépôt cloné non maîtrisé qui embarque ce fichier exécute son code, sans
confirmation, sans signal — et le `|| true` du câblage **masque** l'incident.

C'est l'exact inverse de la doctrine du script frère : `check-doc-drift.sh:39-45` (T-17-06) écrit noir
sur blanc que « `--path` pointe potentiellement vers un dépôt cloné non maîtrisé — sa configuration ne
doit jamais pouvoir faire exécuter un programme lors d'une simple lecture au SessionStart », et pose
`git_safe()` pour ça. Ici le threat model du plan (T-23-02-01/02/03) ne modélise comme hostile que le
**fichier audité** ; le **moteur résolu depuis le dépôt audité** n'y figure nulle part.

**Zone grise assumée → `ask-user`.** La cascade lab-first est **explicitement prescrite** par le plan
(`23-02-PLAN.md:186-187`, « le lab courant PRIME »). Le durcissement contredit donc le plan, et il y a
un vrai arbitrage : un lab légitime en `VF_SCOPE=project` a son moteur **dans** le dépôt. Trois formes
possibles, à trancher par l'humain :
1. retirer `$ROOT/...` de la cascade par défaut (le moteur local ne reste accessible que via
   `VF_GSD_CORE_LIB`, opt-in explicite) ;
2. garder la cascade mais refuser un candidat sous `$ROOT` (`case "$candidate" in "$ROOT"/*) continue ;;`) ;
3. ne pas `require()` : extraire les listes par lecture de texte.

Dans les trois cas, **documenter le vecteur** dans la section Sécurité de l'en-tête, comme T-17-06 le
fait pour git, et l'ajouter au threat model de la phase.

### B-2 — La suite rend la CI **rouge** : elle exige un `gsd-core` installé dans `$HOME`

`plugin/dev-orchestrator/scripts/tests/test-check-gsd-config.sh:273-276` et `:332-333`
+ `.github/workflows/ci.yml:19-32`

Les cas 20 et 26 résolvent le moteur sur **une seule** branche (`$HOME/.claude/gsd-core/bin/lib`) et
partent en `ko` s'il manque. Le job `tests` tourne sur `ubuntu-latest` et n'installe que
`bash`/`jq`/`python3` — **rien n'installe `@opengsd/gsd-core`**.

Preuve exécutée (HOME pointé sur un dossier vide = l'état du runner) :

```
✗ 20 ATTEINTE sur le moteur réel — moteur installé introuvable
✗ 26 mirroir engineExtra contre le moteur réel — moteur installé introuvable
== résultat : 24 ok, 2 ko ==
EXIT DE LA SUITE = 1        ← ce que ci.yml:44 lit
```

La suite frère `test-check-doc-drift.sh` est intégralement auto-portée. Écart net au patron, même classe
d'incident que les 6 fixes portabilité macOS→Linux déjà tracés.

Second défaut du même bloc : la boucle n'essaie que `$HOME`, alors que le script sous test a une cascade
**à trois branches**. Un poste où `gsd-core` vit en `node_modules/@opengsd/gsd-core` est déclaré
« moteur introuvable » à tort.

**Correctif** : (a) ajouter l'installation de `gsd-core` au job `tests` de `ci.yml` — c'est la bonne
direction, elle préserve le sens du compteur d'atteinte ; (b) faire résoudre `REAL_LIB` sur les **trois**
branches de la cascade. **Ne pas** dégrader le `ko` en `ok` : ce serait rouvrir le « vert à vide » que
l'en-tête de la suite prétend interdire. `ci.yml` est hors des `files_modified` du plan — à arbitrer par
le dispatcheur (ici ou au plan 23-08).

> À vérifier au passage : `test-check-gsd-engine.sh` (plan 23-01, même arbre) porte probablement le
> même trait. Hors de mon périmètre, signalé.

---

## MAJEUR

### M-1 — « faux positif possible, **jamais faux négatif** » est FAUX, prouvé

`check-gsd-config.sh:46` (l'affirmation) · `:238-239` (la cause) · `23-02-SUMMARY.md:170-176` (repris)

Le moteur bâtit son `KNOWN_TOP_LEVEL` (`config-loader.cjs:651-656`) à partir de **`VALID_CONFIG_KEYS`
+ `DYNAMIC_KEY_PATTERNS` + les 10 littéraux** — **ni** `configKeys`, **ni** `CONFIG_DEFAULTS`. Le script,
lui, dérive `KNOWN_TOP` de l'**union des trois sources** : il est un **sur-ensemble**.

Diff calculé contre le moteur installé :

```
script connaît, moteur PAS (⇒ faux négatifs) :
  _comment, claude_orchestration, external_job, intel, mempalace, profile-pipeline
moteur connaît, script PAS : []
```

Preuve de bout en bout, sur une config par ailleurs parfaitement alignée :

```
$ bash check-gsd-config.sh --path "$LAB"
[check-gsd-config] …/config.json est aligné sur le moteur — rien à signaler.   exit=3

$ node -e 'require(".../config-loader.cjs").loadConfig(process.cwd())'
gsd-tools: warning: unknown config key(s) in .planning/config.json: _comment — these will be ignored
```

Le gate dit « aligné » sur un lab où le moteur avertit. C'est un **faux négatif**, et il ne passe pas par
la fédération : `_comment` est une **chaîne de documentation** dans `CONFIG_DEFAULTS`, jamais une clé de
config. La ligne `:56` (« reproduit ce comportement à l'identique pour le premier niveau ») est démentie
par la construction même de `KNOWN_TOP`. Ceci vise directement le `must_have` truth #5 du plan.

Conséquence de second ordre, mesurée : un bloc non-moteur est rendu comme **conteneur connu**, donc ses
sous-clés sont signalées à sa place — `[gsd-config] sous-clés inconnues sous un conteneur connu : intel.x`.
Le conseil rendu porte alors sur la mauvaise cible.

**Correctif mesuré** (dissocier les deux ensembles — `KNOWN_TOP` en parité stricte avec le moteur,
l'union à 3 sources ne servant plus qu'à `KNOWN`/`hasChildren`) :

```js
const KNOWN_TOP = new Set([].concat(
  validArr.map(k => k.split('.')[0]), dynTop, engineExtra));
```

J'ai exécuté ce correctif : la suite reste à **26 ok / 0 ko** (elle ne résiste pas au correctif, donc
elle n'enshrine pas le bug), le faux négatif `_comment` est **rattrapé**, et ce lab **reste à exit 3**.

**Zone grise → `ask-user`** sur la *direction* : la parité stricte rouvre des faux positifs sur les labs
où des capabilities tierces (`mempalace`, `intel`…) sont résolues par l'overlay **fédéré** — bruit à
chaque `SessionStart`. Trois formes légitimes : (a) parité stricte + assumer les FP fédérés ;
(b) ne corriger que l'en-tête et le SUMMARY (dire la vérité : les deux sens sont atteignables) ;
(c) lire aussi l'overlay fédéré (4ᵉ source, hors périmètre 23-02 — c'est le GSDC-07 à instruire).
Ce qui n'est **pas** négociable dans les trois cas : l'en-tête `:46` et le SUMMARY `:170` doivent
cesser d'affirmer un fait faux.

### M-2 — Exit **1**, hors contrat, si `HOME` n'est pas défini

`check-gsd-config.sh:155`

Le script protège partout (`${VF_CONFIG_PATH:-…}`, `${VF_GSD_CORE_LIB:-}`) sauf `$HOME`, référencé nu
sous `set -u`. Prouvé :

```
$ env -u HOME bash check-gsd-config.sh --quiet
check-gsd-config.sh: line 159: HOME: unbound variable     ← stderr MALGRÉ --quiet
exit=1                                                     ← hors {0,3,64}
```

**Correctif** : `"${HOME:-}/.claude/gsd-core/bin/lib"` — le `[ -f … ]` fait le reste. Ajouter le cas.

### M-3 — Une **clé vide** dans le fichier audité fait taire le volet « clés inconnues »

`check-gsd-config.sh:310` et `:313` (`if [ -z "$BLOCKS" ]` confond accumulateur vide et valeur vide)

Mesuré, sur une entrée que l'en-tête `:75-76` déclare hostile par hypothèse :

| Fixture | Sortie |
|---|---|
| `{"zzz":1}` (témoin) | `… clés inconnues … : zzz` |
| `{"":{"a":1}}` | **aucune ligne « clés inconnues »** — signal perdu |
| `{"zzz":1,"":2}` | `… : zzz, ` (séparateur orphelin) |
| `{"workflow":{"":1}}` | `… : workflow.` |

**Correctif** : compter (`N_BLOCKS=$((N_BLOCKS+1))`) plutôt que tester la vacuité de la chaîne.

### M-4 — Le script **fabrique une cause** sur le volet toggles

`check-gsd-config.sh:320`

Le message d'état 3 affirme « **résolu par la capability elle-même** ». Le script n'observe que
« absent de `CONFIG_DEFAULTS` ». Prouvé sur un moteur dont `node_repair` n'a pas de défaut :

```
- workflow.node_repair : non écrit, et absent des défauts amont — résolu par la capability elle-même…
- workflow.node_repair_budget : non écrit, et absent des défauts amont — résolu par la capability elle-même…
```

Or l'en-tête du script lui-même (`:31`) dit que ces deux-là « ne vivent que dans la source 1 » — ce ne
sont pas des capabilities. C'est exactement l'ADR-055 §3 que l'en-tête `:71-72` se félicite de respecter
pour `ui_review`. Latent contre le moteur actuel (seul `ui_review` emprunte la branche, où la cause se
trouve vraie), mais faux par construction.

**Correctif** : s'en tenir au fait — « non écrit, et sans défaut lisible dans le moteur — aucune valeur
à afficher ».

### M-5 — Cas 13 **tautologique** : token au lieu de relation

`test-check-gsd-config.sh:190-191`

```sh
has_true=0; case "$out" in *"workflow.code_review"*"true"*) has_true=1 ;; esac
```

`true` est cherché **n'importe où après** `workflow.code_review` dans tout le blob — donc il est fourni
par la ligne `pattern_mapper` suivante. Deux mutants le prouvent :

| Mutant | Attendu si l'assertion mord | Mesuré |
|---|---|---|
| M11 — valeur de `code_review` falsifiée en `XXX` (les autres restent `true`) | cas 13 rouge | **26 ok, 0 ko** |
| M12 — ordre des toggles inversé | cas 13 rouge | **26 ok, 0 ko** |

Le cas 14 fait bien les choses (`awk '/ui_review/{print}'` = ancrage à la ligne) — le cas 13 doit
l'imiter : extraire la ligne de `code_review` puis y chercher `(true)`, idem `(2)` pour le budget.

### M-6 — Le cas 26 ne détecte pas la dérive qu'il annonce

`test-check-gsd-config.sh:324-342`

L'en-tête promet : « une dérive du moteur (littéral **ajouté** ou retiré) passerait en silence » sans ce
cas. Le cas ne compare jamais `engineExtra` à la liste réelle du moteur : il échantillonne deux littéraux.
Vérifié par mutation — il mord si on **vide** `engineExtra` (M5) ou si `KNOWN_TOP` devient universel (M6),
mais un littéral **ajouté** par le moteur (le cas de dérive le plus probable, celui qui produit des faux
positifs) le laisse **vert**.

**Correctif** : extraire les littéraux réels du bloc `KNOWN_TOP_LEVEL` de `config-loader.cjs` (c'est du
texte) et asserter l'**égalité d'ensemble** avec `engineExtra`.

### M-7 — Huit cas n'assertent aucun code de retour ; chemins nominaux non couverts

`test-check-gsd-config.sh` cas 2 (`:130`), 11 (`:178`), 13 (`:192`), 14 (`:199`), 15 (`:220`), 22 (`:304`),
25 (`:322`), 26 (`:339`) — `rc` est calculé puis n'apparaît que dans le message d'échec. Un script sortant
en 1 sur ces fixtures resterait vert : c'est ce qui a laissé passer **M-2**.

Non couvert du tout : `HOME` non défini ; `node` absent du PATH (rend bien 3, vérifié à la main, mais
rien ne le garde) ; **`--path <dir>` nominal** — toute la suite passe par `VF_CONFIG_PATH` +
`VF_GSD_CORE_LIB`, c'est-à-dire par les deux surcharges qui **court-circuitent le chemin exact du hook**
(dérivation `$ROOT/.planning/config.json` et cascade `$ROOT/.claude/gsd-core/…`, celle-là même de B-1) ;
config présente mais illisible.

**Correctif** : ajouter `[ "$rc" -eq N ]` aux huit cas ; ajouter un cas `--path` nominal sur une fixture
portant `.planning/config.json` **et** `.claude/gsd-core/bin/lib` ; ajouter `env -u HOME` et un PATH sans
node ; ajouter un balayage final qui rejoue toutes les fixtures et échoue sur tout `rc ∉ {0,3,64}`.

---

## MINEUR

- **m-1** — `check-gsd-config.sh:118-122` : `--path ""` passe le gate `[ "$#" -lt 2 ]` et audite
  `/.planning/config.json` (vérifié, exit 3). Hérité du patron `check-doc-drift.sh:71-76`, mais ici il
  déplace silencieusement la cible. Correctif : refuser aussi la valeur vide.
- **m-2** — `check-gsd-config.sh:122` : `--path --hook` avale le flag comme valeur (exit 3 silencieux).
  Hérité du patron, déjà tracé « no-op » au SUMMARY `:162` — d'accord, à traiter au niveau du patron commun.
- **m-3** — `test-…:264-267` (cas 19) : n'asserte pas la propriété annoncée (« `--hook` n'altère aucun
  rendu »), seulement que la sortie est non vide. Correctif : `[ "$outh" = "$out_sans_hook" ]`.
- **m-4** — `check-gsd-config.sh:125` : `grep '^# '` ramasse aussi les commentaires d'implémentation
  (`:147`, `:171-175`, `:178-183`, `:226-235`, `:249-250`, `:295-298`) et écrase la mise en page. Le cas 23
  (`test-…:309-310`) n'asserte que « non vide » — tautologique. Borner l'extraction au bloc d'en-tête et
  asserter la présence de `Exit codes:`. (Le `exit 0` de `--help`, hors contrat en apparence, est le
  patron maison partagé par les **trois** scripts frères — **no-op**.)
- **m-5** — `test-…:234-258` (cas 18) : le canari sur les **valeurs** hostiles ne peut pas se déclencher —
  les valeurs du fichier audité ne franchissent **jamais** la frontière vers bash (seules les clés sont
  émises ; les valeurs affichées viennent de `CONFIG_DEFAULTS`). Ce qui mord réellement, c'est
  l'assertion `` échappé / jamais brut, qui est excellente. Déplacer la charge hostile dans une
  **clé** pour rendre le canari discriminant.
- **m-6** — mode 644 sur la suite (les frères sont 755). Normalisé à l'install
  (`vibeflow-update.sh:358`) et la CI invoque `bash "$t"` — **no-op** cosmétique, mais le cas 24 vérifie
  justement ce bit sur le script sous test.
- **m-7** — `23-02-SUMMARY.md:118` sur-déclare la ligne « `gates`/`safety` en dur » (cf. supra). **no-op**.

---

## Réponses explicites aux points du mandat

- **Le `|| true` est-il réel ?** Oui, vérifié par exécution sur les exits 3, 64, 127 et 2 → tous ramenés
  à 0. `key_link` tenu.
- **L'union à 3 sources est-elle un fait ?** Oui, vérifié dans le moteur installé.
  **Mais** l'extraction périme partiellement en silence : si `config.cjs` **et** `configuration.cjs`
  cessaient d'exporter `VALID_CONFIG_KEYS`, le script sort en 3 (silence) avec un `say()` sur stderr —
  ce qui, au `SessionStart` sous `|| true`, est en pratique invisible. Non bloquant, à noter.
- **La doc de la limite fédérée dit-elle ce que le code fait ?** **Non** — voir M-1, l'inverse est
  atteignable et prouvé.
- **Cas 26 : deux sens ou co-présence ?** **Deux sens réels**, chaque moitié tuée par un mutant distinct.
- **Le rejet de l'élagage d'`engineExtra` tient-il ?** **Oui**, et il devient obligatoire avec M-1.
- **Le compteur ment-il ?** Non cette fois : 26/0 recomptés indépendamment, et les 6 mutations annoncées
  mordent réellement. Le seul écart est la *forme* d'un mutant (m-7).

---

## Bloc typé

```json
{
  "statut": "gaps_found",
  "findings": [
    { "severity": "bloquant", "action": "ask-user",  "ref": "plugin/dev-orchestrator/scripts/check-gsd-config.sh:152" },
    { "severity": "bloquant", "action": "auto-fix",  "ref": "plugin/dev-orchestrator/scripts/tests/test-check-gsd-config.sh:274" },
    { "severity": "majeur",   "action": "ask-user",  "ref": "plugin/dev-orchestrator/scripts/check-gsd-config.sh:46" },
    { "severity": "majeur",   "action": "auto-fix",  "ref": "plugin/dev-orchestrator/scripts/check-gsd-config.sh:155" },
    { "severity": "majeur",   "action": "auto-fix",  "ref": "plugin/dev-orchestrator/scripts/check-gsd-config.sh:310" },
    { "severity": "majeur",   "action": "auto-fix",  "ref": "plugin/dev-orchestrator/scripts/check-gsd-config.sh:320" },
    { "severity": "majeur",   "action": "auto-fix",  "ref": "plugin/dev-orchestrator/scripts/tests/test-check-gsd-config.sh:190" },
    { "severity": "majeur",   "action": "auto-fix",  "ref": "plugin/dev-orchestrator/scripts/tests/test-check-gsd-config.sh:324" },
    { "severity": "majeur",   "action": "auto-fix",  "ref": "plugin/dev-orchestrator/scripts/tests/test-check-gsd-config.sh:130" },
    { "severity": "mineur",   "action": "auto-fix",  "ref": "plugin/dev-orchestrator/scripts/check-gsd-config.sh:118" },
    { "severity": "mineur",   "action": "no-op",     "ref": "plugin/dev-orchestrator/scripts/check-gsd-config.sh:122" },
    { "severity": "mineur",   "action": "auto-fix",  "ref": "plugin/dev-orchestrator/scripts/tests/test-check-gsd-config.sh:264" },
    { "severity": "mineur",   "action": "auto-fix",  "ref": "plugin/dev-orchestrator/scripts/check-gsd-config.sh:125" },
    { "severity": "mineur",   "action": "auto-fix",  "ref": "plugin/dev-orchestrator/scripts/tests/test-check-gsd-config.sh:234" },
    { "severity": "mineur",   "action": "no-op",     "ref": "plugin/dev-orchestrator/scripts/tests/test-check-gsd-config.sh:1" },
    { "severity": "mineur",   "action": "no-op",     "ref": ".planning/phases/VFDO-23-couplage-explicite-au-moteur-gsd-capabilities-flags-et-voie-/23-02-SUMMARY.md:118" }
  ],
  "noeuds_debloques": []
}
```
