# Phase 44: Moteur — modèle de données et recalcul d'état dérivé du disque - Research

**Researched:** 2026-09-27
**Domain:** modèle de fichiers `.planning/` métier + moteur de recalcul d'état en Python (stdlib), livré via un point d'entrée bash embarqué
**Confidence:** HIGH sur le patron d'embarquement Python et les gabarits existants (lu ce jour) ; MEDIUM sur les formats de frontmatter non encore écrits nulle part (CADRAGE.md/VERDICT.md/CYCLE.md) — c'est un livrable de CETTE phase, pas une donnée à découvrir.

## Summary

Cette phase a deux livrables distincts et un seul risque d'implémentation concret : le
recalcul doit être écrit en Python (D-12), livré par l'installeur existant sans y toucher
(D-14, voie par défaut a), et l'unique patron du dépôt qui fait exactement ça est
`plugin/conductor/scripts/dag.sh` — Python 3 embarqué en heredoc `<<'PYEOF'` dans un script
bash, siblings résolus par répertoire du script (jamais le cwd), JSON en sortie. La recherche
confirme mécaniquement chaque contrainte de `44-CONTEXT.md` : l'installeur (`vibeflow-update.sh`
lignes 1200/2005/2030/2519/2804/883) ne pose que `*.sh`, `*.mjs`, `*.js` en exécutable et
`*.json`/`*.txt` en données — un `.py` de `scripts/` ne serait effectivement jamais installé,
donc la voie (a) est la seule qui livre sans modifier l'installeur. PyYAML est confirmé absent
de ce poste (`ModuleNotFoundError: No module named 'yaml'`, Python 3.14.5) — le parseur de
frontmatter minimal de D-12 est donc bien nécessaire, pas une précaution excessive.

Le second risque, non nommé explicitement dans `44-CONTEXT.md` mais implicite dans le modèle de
données §3 de la spec, est le **couplage entre le format des fichiers écrits (livrable #1) et
ce que le parseur minimal (livrable #2, D-12) peut lire sans bibliothèque YAML** : le
« registre d'inconnues avec colonne structurante » de `CADRAGE.md` ne doit pas être conçu comme
un tableau Markdown prosaïque à parser — cela sort du périmètre d'un « parser de frontmatter
minimal » et retombe dans le risque bash-like de sur-ingénierie que D-09/D-12 de la spec
cherchent justement à éviter. Le format concret des cinq types de fichiers (CYCLE.md,
CADRAGE.md, PLAN.md, VERDICT.md, SUMMARY.md) n'est écrit nulle part dans le dépôt à ce jour —
c'est un livrable de cette phase, pas une découverte de recherche, et le format choisi doit
rester dans le pouvoir d'un parseur frontmatter+lignes simples.

**Primary recommendation :** un point d'entrée bash mince (`recalc-planning.sh` ou nom
équivalent, sous `plugin/planning-core/scripts/`) qui embarque tout le moteur Python 3.9+ en
heredoc(s) quoté(s) `<<'PYEOF'`, reproduisant le patron `dag.sh` (résolution de siblings par
`$(cd "$(dirname "$0")" && pwd)`, jamais le cwd) ; le modèle de fichiers (livrable #1) est conçu
dès le départ pour rester parsable par un frontmatter YAML minimal + un registre en
liste structurée (pas un tableau Markdown), afin que le parseur du livrable #2 n'ait jamais
besoin de plus que ce que D-12 autorise.

## Architectural Responsibility Map

> Adapté au domaine (CLI/scripts + modèle de fichiers, pas d'application web) : les « tiers »
> web ne s'appliquent pas tels quels. Table adaptée aux couches réelles de ce dépôt.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Modèle de fichiers du lab (`cycles/`, `CADRAGE.md`, `PLAN.md` `ecrit:`, marqueur de clôture, `VERDICT.md`, `SUMMARY.md`) | Référence de modèle (`plugin/planning-core/references/`) | Gabarits (`references/templates/`) | Le format est documentation + gabarits, pas du code — c'est ce que le recalcul lit, jamais l'inverse (D-01d : état dérivé, jamais déclaré) |
| Recalcul d'état (8 états, dont `indéterminé`) | CLI Python embarqué (`plugin/planning-core/scripts/*.sh`) | — | Seul tier qui lit le disque et produit `INDEX.md`/`STATE.md`/`cloture.log` ; D-12 interdit toute logique de recalcul en bash |
| Adhésion / refus d'écriture (D-02, D-02a) | CLI Python embarqué | Config du lab (`config.json` — clé `planning_version`) | Le Python lit `config.json` comme donnée, ne la modifie jamais ; le refus est une décision du moteur, pas de la config |
| Détection « ce planning appartient-il à GSD ? » | Script bash existant (`detect-gsd-engine.sh`, réutilisé en sibling, jamais réimplémenté) | CLI Python embarqué (l'appelle en subprocess) | D-01d interdit toute dépendance de CODE vers gsd-core, mais réutiliser un script du MÊME module planning-core est autorisé et déjà le patron établi (dag.sh appelle ses siblings driver-lock.sh/check-guard-health.sh/notify.sh de la même façon) |
| Livraison au lab installé | Installeur (`plugin/_internal/vibeflow-update.sh`) | — | Non modifié par cette phase (D-14 voie a) — pose `*.sh` tel quel, aucun site nouveau |
| Vérification (banc + labs réels) | Suites bash `plugin/planning-core/scripts/tests/test-*.sh` | CI (`.github/workflows/ci.yml`, découverte auto) | Le banc synthétique gate en CI (D-06) ; le passage sur labs réels est HORS CI, lecture seule (D-06a) |

## Standard Stack

### Core

| Outil | Version | Rôle | Pourquoi standard ici |
|-------|---------|------|------------------------|
| Python | 3.9+ (poste : 3.14.5, `[VERIFIED: python3 --version, exécuté ce jour]`) | Moteur de recalcul | D-12 impose stdlib seule ; aucune dépendance externe à installer |
| bash | `/bin/bash` (CI, `bash -e {0}` `[CITED: .github/workflows/ci.yml]`), `/bin/zsh` (poste local `[CITED: 44-CONTEXT.md code_context]`) | Point d'entrée mince + suites de tests | Seul format que l'installeur pose comme exécutable (D-14) |
| hashlib (stdlib) | — | Hash de contenu pour l'incrémentalité (D-13) | Aucune lib externe requise ; `sha256` est déjà le format utilisé ailleurs dans le corpus (`cloture.log` exemple spec, hash de `.claude-plugin` etc.) |
| json (stdlib) | — | Cache incrémental + sortie JSON de diagnostics | Patron déjà en place dans `dag.sh` (`json.dump(..., indent=2, ensure_ascii=False)`) — à durcir avec `sort_keys=True` pour le déterminisme requis par D-10/MOTR-10 (dag.sh ne le fait PAS aujourd'hui — ne pas copier cet oubli) |

### Supporting

| Outil | Version | Rôle | Quand l'utiliser |
|-------|---------|------|-------------------|
| `argparse` (stdlib) | — | Analyse d'arguments CLI côté Python, si le wrapper bash délègue le parsing | Alternative à la reprise manuelle du patron `case "$arg" in --flag=*)` de `dag.sh` — les deux sont stdlib-only, le choix est du ressort du planificateur (Claude's Discretion, structure interne) |
| `tempfile` + `os.replace` (stdlib) | — | Écriture atomique de `INDEX.md`/`STATE.md` | `dag.sh.save()` n'est PAS atomique (`open(file, "w")` direct) — ne pas reproduire cet oubli pour des fichiers protégés par un futur G6 (Phase 45) ; voir Common Pitfalls |

### Alternatives Considered

| Au lieu de | Pourrait utiliser | Arbitrage |
|------------|--------------------|-----------|
| Parser de frontmatter minimal maison (D-12) | PyYAML | Écarté par contrainte machine : `ModuleNotFoundError: No module named 'yaml'` confirmé sur ce poste `[VERIFIED: python3 -c "import yaml", exécuté ce jour]` — D-12 le documentait déjà, la recherche le confirme mécaniquement |
| Extension `*.py` de l'installeur (D-14 voie b) | Python embarqué en heredoc `.sh` (voie a) | Voie (a) par défaut sauf preuve d'intenabilité ; aucune preuve d'intenabilité trouvée — `dag.sh` prouve le patron déjà en production, livré à tous les labs installés | 

**Installation :** aucune — bibliothèque standard Python 3.9+ uniquement, aucun `pip install`, aucune entrée `requirements.txt`/`pyproject.toml` à créer.

**Version verification :** `python3 --version` → `Python 3.14.5` sur ce poste `[VERIFIED: exécuté ce jour]`. CI installe `python3` via l'image `ubuntu-latest` et vérifie sa présence (`.github/workflows/ci.yml:28-32` `[CITED: .github/workflows/ci.yml]`) — aucune version épinglée côté CI, donc écrire contre la ligne de base 3.9 (D-12) sans dépendre de fonctionnalités > 3.9 (ex. `match` statement de 3.10 à éviter si la CI venait un jour à tourner sur un runner plus ancien — non mesuré ici, prudence).

## Package Legitimacy Audit

**Non applicable.** Cette phase n'installe aucun package externe (Python stdlib seule, D-12 ;
aucune dépendance npm/pip/cargo nouvelle). Le protocole de vérification de légitimité de package
est sauté explicitement pour ce motif.

## Architecture Patterns

### System Architecture Diagram

```
                     ┌─────────────────────────────┐
                     │  vibeflow-update.sh          │
                     │  (installeur, INCHANGÉ D-14) │
                     │  pose *.sh tel quel           │
                     └──────────────┬───────────────┘
                                    │ copie
                                    ▼
        <lab>/.claude/scripts/recalc-planning.sh  (point d'entrée bash mince)
                                    │
                     ┌──────────────┴────────────────┐
                     │ argv → python3 - "$@" <<'PYEOF'│
                     │  (heredoc quoté, patron dag.sh)│
                     └──────────────┬────────────────┘
                                    ▼
              ┌─────────────────────────────────────────┐
              │  Moteur Python (stdlib seule)             │
              │                                           │
              │  1. Lire .planning/config.json             │
              │     → planning_version déclare le schéma ? │
              │        NON → refuse (D-02), exit≠0, RIEN   │
              │              écrit (sauf mode --read-only) │
              │        OUI → suite                          │
              │                                           │
              │  2. Mode écriture ? → appelle en subprocess │
              │     detect-gsd-engine.sh (sibling, D-02a)   │
              │        exit 0 (GSD actif) → refuse           │
              │                                           │
              │  3. Charger le cache incrémental             │
              │     (.planning/<nom délégué>)               │
              │     absent/illisible/mauvais format          │
              │        → recalcul COMPLET (D-13)             │
              │                                           │
              │  4. Parcourir cycles/*/phases/*/            │
              │     (+ plans/*/ imbriqués) — tri déterministe │
              │     hash sha256 de chaque fichier lu          │
              │     (jamais mtime, D-13)                    │
              │                                           │
              │  5. Parser frontmatter minimal (D-12)        │
              │     CADRAGE.md / PLAN.md / VERDICT.md /      │
              │     SUMMARY.md / marqueur de clôture         │
              │                                           │
              │  6. Dériver l'état (8 états, D-08 : toute     │
              │     combinaison non prévue → indéterminé)    │
              │                                           │
              │  7. Générer INDEX.md, STATE.md               │
              │     (déterministe, sort_keys, tri explicite)  │
              │     + append cloture.log (append-only,       │
              │     JAMAIS réécrit, D-11)                    │
              └─────────────────────────────────────────┘
                                    │ mode --read-only
                                    ▼
                          stdout SEUL — aucun fichier,
                          aucun cache (D-02a)
```

### Recommended Project Structure

```
plugin/planning-core/
  scripts/
    recalc-planning.sh          # NOUVEAU — point d'entrée mince, embarque le moteur Python
                                 #   (nom délégué au planificateur, Claude's Discretion)
    detect-gsd-engine.sh        # EXISTANT — réutilisé en sibling subprocess (D-02a)
    tests/
      test-recalc-planning.sh   # NOUVEAU — banc synthétique, 8 états + jumeaux négatifs (D-17)
      fixtures/
        recalc-bench/           # NOUVEAU — arborescence synthétique versionnée (D-06)
  references/
    modele-cycles.md            # NOUVEAU (nom délégué) — la référence du modèle : formats de
                                 #   CYCLE.md, CADRAGE.md (registre), PLAN.md (`ecrit:`), marqueur
                                 #   de clôture, VERDICT.md (hash+tentative), SUMMARY.md, liste
                                 #   fermée des emplacements annexes (D-04)
    templates/
      CYCLE.template.md         # NOUVEAU
      CADRAGE.template.md       # NOUVEAU
      # PLAN.template.md, SUMMARY.template.md EXISTENT déjà (socle v2) — le nouveau modèle
      # vit À CÔTÉ, ne les écrase pas (D-01b : suites existantes vertes sans modification)
```

### Pattern 1 : Python embarqué en heredoc bash (patron `dag.sh`)

**What :** le script bash ne fait QUE parser ses propres arguments (`--flag=valeur`), résoudre
les chemins de siblings par répertoire du script, puis invoquer `python3 - "$ARG1" "$ARG2" ...
<<'PYEOF' ... PYEOF`. Le heredoc est **quoté** (`'PYEOF'`, pas `PYEOF` nu) : sans les quotes,
bash interpolerait `$`, backticks et autres métacaractères dans le corps Python avant de le
passer à l'interpréteur — un bug qui casserait silencieusement toute chaîne Python contenant un
`$` littéral. Les arguments sont passés en `sys.argv` positionnels (jamais via variables
d'environnement pour les données métier), et le script sort via `sys.exit(code)` — le code de
sortie de `python3` devient celui du wrapper bash puisqu'il est le dernier appel du script.

**When to use :** c'est le SEUL patron qui satisfait D-14 voie (a) — aucune autre convention du
dépôt ne livre du Python à un lab sans modifier l'installeur.

**Example (vérifié, lu ce jour) :**
```bash
# Source: plugin/conductor/scripts/dag.sh:69-103 (résolution siblings + invocation)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd 2>/dev/null || dirname "$0")"
DRIVER_LOCK_SH="$SCRIPT_DIR/driver-lock.sh"
CHECK_GUARD_HEALTH_SH="$SCRIPT_DIR/check-guard-health.sh"
NOTIFY_SH="$SCRIPT_DIR/notify.sh"

python3 - "$ACTION" "$FILE" "$ID" "$STEP" "$STAGE" "$DEPS" "$STATUS" "$SCOPE" \
  "$DRIVER_LOCK_SH" "$CHECK_GUARD_HEALTH_SH" "$NOTIFY_SH" <<'PYEOF'
import sys, os, json, subprocess, tempfile, shutil

action, file, nid, step, stage, deps_raw, status, scope_raw = sys.argv[1:9]
driver_lock_sh = sys.argv[9]
# ... logique métier ...
def emit(obj):
    print(json.dumps(obj, indent=2, ensure_ascii=False))
# ...
sys.exit(0)  # ou sys.exit(1) — devient le code de sortie du .sh appelant
PYEOF
```

Pour la Phase 44, le sibling à invoquer en subprocess est `detect-gsd-engine.sh` (D-02a),
exactement comme `dag.sh` invoque `driver-lock.sh`/`check-guard-health.sh`/`notify.sh` par le
même mécanisme `SCRIPT_DIR/<sibling>.sh` — **jamais** un chemin relatif au cwd (c'est le vecteur
de compromission fermé par D-07 de `dag.sh`, commentaire lignes 160-170 : un candidat cwd-relatif
permettrait l'exécution de code arbitraire depuis une branche/PR malveillante).

### Pattern 2 : déterminisme de sortie (D-10, MOTR-10)

**What :** deux recalculs sur le même disque doivent produire des fichiers **identiques octet
pour octet**. `dag.sh.save()` utilise `json.dump(dag, fh, indent=2, ensure_ascii=False)`
**sans** `sort_keys=True` — c'est suffisant pour `dag.sh` parce que l'ordre des clés d'un dict
Python construit par du code déterministe reste stable en pratique (CPython 3.7+ préserve
l'ordre d'insertion), mais ce n'est **pas** une garantie de déterminisme si deux exécutions
peuvent construire le dict dans un ordre différent (ex. itération sur `os.listdir()` ou
`glob.glob()`, qui ne garantissent PAS un ordre stable entre systèmes de fichiers).

**When to use :** partout où le recalcul énumère des fichiers/dossiers sur disque
(`cycles/*/`, `phases/*/`, `plans/*/`) — **toujours** trier explicitement (`sorted(...)`) avant
toute construction de sortie ou de clé de cache.

**Anti-pattern à éviter :**
```python
# ANTI-PATTERN — l'ordre de os.listdir() n'est PAS garanti stable entre systèmes de fichiers
for cycle in os.listdir(cycles_dir):
    ...
```
```python
# Pattern correct
for cycle in sorted(os.listdir(cycles_dir)):
    ...
# Et à l'écriture finale : json.dump(obj, fh, indent=2, ensure_ascii=False, sort_keys=True)
```

### Anti-Patterns to Avoid

- **Confiance au cache sans vérification de format :** un cache absent, illisible OU d'un format
  différent (schéma versionné manquant/mismatch) doit provoquer un recalcul **complet**, jamais
  une lecture partielle optimiste (D-13, MOTR-13 explicite « jamais une confiance aveugle »).
- **Écriture non-atomique de fichiers protégés à venir :** `INDEX.md`/`STATE.md` seront protégés
  par un G6 en Phase 45 — les écrire directement (`open(f, "w")`) sans passage par un fichier
  temporaire + `os.replace()` expose une fenêtre où un crash mid-write laisse un fichier
  tronqué/corrompu, que G6 ne pourra pas distinguer d'une écriture manuelle malveillante.
- **`cloture.log` ouvert en mode `"w"` :** append-only signifie mode `"a"` **exclusivement** —
  une seule ligne de code erronée (`open(path, "w")` au lieu de `"a"`) détruirait tout
  l'historique (D-11, MOTR-11 : « jamais une ligne réécrite ou supprimée »).
- **Tableau Markdown prosaïque pour le registre d'inconnues de `CADRAGE.md` :** parser un
  tableau Markdown générique (colonnes `|`, alignement, cellules multi-mots) dépasse largement
  ce qu'un « parser de frontmatter minimal » (D-12) doit couvrir — concevoir le registre comme
  une liste structurée en frontmatter (YAML minimal : liste de mappings à clés plates) évite ce
  piège dès la conception du gabarit `CADRAGE.template.md` (livrable #1), qui doit être pensé
  EN MÊME TEMPS que le parseur (livrable #2), pas après.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Hash de contenu de fichier | Une fonction de hash maison | `hashlib.sha256(data).hexdigest()` (stdlib) | Déjà le standard implicite du corpus (spec §7.4 montre un format de ligne cohérent avec sha256/verdicts hachés à venir en Phase 46) ; aucune raison de réinventer |
| Sérialisation JSON déterministe | Un sérialiseur maison trié à la main | `json.dumps(obj, sort_keys=True, ensure_ascii=False)` (stdlib) | `sort_keys=True` est le mécanisme stdlib exact pour le déterminisme requis — pas besoin de trier les dicts soi-même avant sérialisation |
| Résolution de sibling scripts | Un chemin cwd-relatif ou une variable d'env obligatoire | `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"` (patron `dag.sh`) | C'est exactement le patron que `dag.sh` a durci après un vecteur de compromission mesuré (chemin cwd-relatif exécutable via `node`) — le reproduire fidèlement, ne pas réinventer une résolution plus faible |
| Analyse d'arguments CLI bash | Un parseur ad hoc avec `getopts` | Le patron `case "$arg" in --flag=*) VAL="${arg#*=}" ;; esac` déjà utilisé par `dag.sh` (lignes 71-85) | Cohérence avec le reste du module ; `getopts` ne gère pas nativement `--flag=valeur` sans complexité ajoutée |

**Key insight :** dans ce domaine (scripts internes à un plugin, jamais publiés comme paquet), le
risque n'est pas d'installer une dépendance non fiable (aucune n'est installée), mais de
**réinventer un mécanisme déjà durci ailleurs dans le même dépôt** — la résolution de siblings et
le patron d'embarquement Python sont des solutions déjà éprouvées en production
(`plugin/conductor/scripts/dag.sh`, livré à tous les labs installés) ; s'en écarter sans raison
mesurée reproduit des bugs déjà corrigés une fois.

## Common Pitfalls

### Pitfall 1 : réintroduire `mtime` par la petite porte

**What goes wrong :** une vérification de fraîcheur de cache codée avec
`os.path.getmtime(path)` au lieu du hash de contenu, même « juste » pour décider s'il faut
recalculer un sous-arbre — cela reproduit exactement le défaut que cette phase existe pour
corriger (le hook `guard-planning-updated.sh` du même module, mesuré défaillant par la spec
§1.2 : `touch` sans changement de contenu → faux négatif).
**Why it happens :** `mtime` est plus rapide à lire qu'un hash (`os.stat()` vs lecture complète
du fichier) — la tentation d'optimiser prématurément est réelle sur de gros plannings (spec
mentionne 3 000 phases).
**How to avoid :** bannir tout appel à `st_mtime`/`getmtime` dans le module de recalcul — grep
`mtime` sur le fichier livré doit renvoyer zéro occurrence, testable en CI.
**Warning signs :** toute variable nommée `*_time`, `*_date`, ou tout `os.stat()` dont seul
`.st_mtime` est lu.

### Pitfall 2 : cache dont le format n'est pas versionné

**What goes wrong :** un cache JSON sans champ de version de schéma explicite — si le format du
cache change entre deux versions du moteur (ex. Phase 45 ajoute un champ), l'ancien cache reste
« lisible » (JSON valide) mais sémantiquement obsolète, et le moteur pourrait s'y fier à tort.
**Why it happens :** un simple `json.load()` réussi est facile à confondre avec « cache valide ».
**How to avoid :** poser une clé `"cache_schema_version": N` dès le premier commit ; tout cache
sans cette clé, ou avec une valeur différente de celle attendue par CE moteur, est traité comme
« illisible » au sens de D-13 → recalcul complet.
**Warning signs :** `json.load(f)` sans vérification de clé de version immédiatement après.

### Pitfall 3 : parser de frontmatter qui devine au lieu de refuser

**What goes wrong :** face à un frontmatter malformé (délimiteurs `---` manquants, valeur
ambiguë), un parseur maison peut être tenté de « deviner » une valeur plausible plutôt que de
signaler l'ambiguïté — exactement le biais que D-08 (« un faux vert est pire qu'un aveu ») et
l'état `indéterminé` existent pour éliminer.
**Why it happens :** un parseur permissif semble plus robuste à l'usage quotidien.
**How to avoid :** toute ambiguïté de parsing sur un champ qui détermine l'état (`statut:`,
présence du marqueur de clôture, constats de `VERDICT.md`) doit se traduire par `indéterminé`,
jamais par une valeur par défaut silencieuse.
**Warning signs :** un `.get(key, valeur_par_défaut)` sur un champ qui conditionne la dérivation
d'état, plutôt qu'un `.get(key, SENTINEL_INDETERMINE)`.

### Pitfall 4 : oublier le jumeau négatif d'un état

**What goes wrong :** D-17/MOTR-16 exige que chaque état naisse avec son jumeau négatif ET que
chaque garde soit prouvée par une mutation rouge tracée. Un banc qui ne teste que les 8 chemins
« heureux » sans les 4 contradictions explicites de D-08 (SUMMARY sans PLAN, VERDICT sans
marqueur, SUMMARY avec verdict en échec, marqueur sans PLAN) laisse `indéterminé` non prouvé.
**Why it happens :** les cas positifs sont plus faciles à écrire en premier et « suffisent » en
apparence à couvrir le banc.
**How to avoid :** construire la matrice de fixtures AVANT le code — chaque ligne du tableau des
8 états + les 4 contradictions D-08 + les 3 dérogations (`abandonné|remplacé|gelé`, avec et sans
auteur) est un cas de fixture nommé.
**Warning signs :** un fichier de fixtures dont le nombre de cas est inférieur à 8+4+3×2=18.

### Pitfall 5 : écriture accidentelle pendant le passage sur labs réels (D-06b)

**What goes wrong :** le mode `--read-only` (D-02a) doit garantir zéro écriture, cache compris —
un bug qui laisse le moteur écrire son cache « juste pour cette fois » lors du passage sur
`~/jarvis-keystone` ou `~/BusinessFlow-Lab` violerait D-06b, dont la preuve est une empreinte
sha256 de l'arbre complet avant/après comparée par `cmp`.
**Why it happens :** un chemin de code qui écrit le cache seulement quand une condition annexe
est vraie (ex. « si le lab a adhéré ») peut oublier de vérifier AUSSI le flag `--read-only`.
**How to avoid :** faire du flag lecture-seule une garde unique, vérifiée en tout premier, qui
court-circuite absolument tout appel d'écriture (fichier de sortie ET cache) — jamais une
vérification dispersée à chaque site d'écriture.
**Warning signs :** plus d'un site de code qui teste `if read_only: ...` avant une écriture —
signe qu'un site a pu être oublié.

## Code Examples

> Aucun exemple ci-dessous n'existe déjà tel quel dans le dépôt pour le domaine « parseur de
> frontmatter minimal » ou « écriture atomique » — ces deux extraits sont des propositions de
> conception `[ASSUMED]`, à valider au plan, construites à partir de patrons stdlib standards et
> du patron `dag.sh` vérifié. Le premier extrait (embarquement + siblings) est repris quasi
> verbatim de code lu ce jour.

### Invocation avec siblings (patron vérifié)

```bash
# Source: plugin/conductor/scripts/dag.sh:90-103 (lu ce jour, adapté au nom du sibling de la Phase 44)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd 2>/dev/null || dirname "$0")"
DETECT_GSD_SH="$SCRIPT_DIR/detect-gsd-engine.sh"

python3 - "$MODE" "$PLANNING_DIR" "$DETECT_GSD_SH" <<'PYEOF'
import sys, subprocess

mode, planning_dir, detect_gsd_sh = sys.argv[1:4]

def gsd_engine_active(path):
    # D-02a : un planning GSD detecte est refuse en mode ecriture — reutilise le script existant
    # en subprocess (sibling), jamais reimplemente (D-01d : aucune dependance de CODE vers gsd-core,
    # mais reutiliser un script DU MEME MODULE planning-core est le patron etabli).
    try:
        r = subprocess.run([detect_gsd_sh, "--quiet", "--path", path],
                            capture_output=True, timeout=5, check=False)
        return r.returncode == 0
    except Exception:
        return False  # degradation : ne bloque jamais le mode read-only sur une panne du sibling

if mode == "write" and gsd_engine_active(planning_dir):
    print("refus: planning GSD actif, ecriture refusee (D-02a)", file=sys.stderr)
    sys.exit(1)
# ... suite du recalcul ...
PYEOF
```

### Cache incrémental versionné (proposition, à valider au plan)

```python
# [ASSUMED] — proposition de conception, pas un extrait du dépôt.
CACHE_SCHEMA_VERSION = 1

def load_cache(cache_path):
    """Retourne un cache vide si absent, illisible, ou d'un schema different — jamais une
    confiance partielle (D-13, MOTR-13)."""
    try:
        with open(cache_path, encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, json.JSONDecodeError):
        return {"cache_schema_version": CACHE_SCHEMA_VERSION, "files": {}}
    if data.get("cache_schema_version") != CACHE_SCHEMA_VERSION:
        return {"cache_schema_version": CACHE_SCHEMA_VERSION, "files": {}}
    return data

def content_hash(path):
    import hashlib
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()
```

### Écriture atomique (proposition, à valider au plan)

```python
# [ASSUMED] — dag.sh.save() n'est PAS atomique ; proposition pour INDEX.md/STATE.md
# (protégés par un futur G6, Phase 45) — cloture.log suit une discipline DIFFÉRENTE (append "a").
import os, tempfile

def write_atomic(path, content):
    d = os.path.dirname(path) or "."
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".tmp-recalc-")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.write(content)
        os.replace(tmp, path)  # atomique sur POSIX ET Windows (os.replace, contrairement à os.rename)
    except Exception:
        try:
            os.remove(tmp)
        except OSError:
            pass
        raise
```

## State of the Art

| Ancien | Nouveau | Depuis | Impact |
|--------|---------|--------|--------|
| `guard-planning-updated.sh` mesure la fraîcheur par `mtime` (socle métier existant, module planning-core v2.7.1) | Recalcul par hash de contenu (D-13) | Cette phase (additive, D-01e : le retrait de l'existant n'a PAS lieu ici) | Le nouveau moteur coexiste avec l'ancien hook tant que le lab n'a pas adhéré (`planning_version` déclaré) ; aucune régression de l'existant (D-01b, prouvé par les suites `test-*.sh` déjà vertes) |
| `planning_version: 1.0`/`2.0` déjà utilisés dans 5 emplacements du dépôt (`[VERIFIED: grep -rn planning_version plugin docs, exécuté ce jour]` — `STATE.template.md:2` = 1.0, `INDEX.template.md:2`/`BOARD.template.md:2`/`config.template.json:2` = 2.0) | D-02 impose une valeur **nouvelle** pour signaler l'adhésion au modèle-cycles — la valeur exacte reste déléguée au planificateur, mais ne doit collisionner avec ni "1.0" ni "2.0" déjà pris | Cette phase | Le planificateur doit choisir une valeur non ambiguë (ex. une chaîne distincte des formats numériques déjà utilisés, ou un numéro de version supérieur clairement au-dessus de 2.0) — spec §11.3 note déjà "deux schémas planning_version (1.0 et 2.0) sans chemin de migration", donc une troisième valeur crée un troisième schéma à documenter, pas un remplacement silencieux |

**Deprecated/outdated :**
- Le socle métier v2.7.1 de `planning-core` (scaffoldeur thin, prose agent-driven) n'est PAS
  retiré par cette phase — D-01e le maintient explicitement en additif jusqu'aux Phases 45+.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Le nom du point d'entrée bash (`recalc-planning.sh`), le nom du fichier de cache, le nom du fichier marqueur de clôture, et la structure interne du module Python sont des propositions — tous explicitement délégués au planificateur par `44-CONTEXT.md` (Claude's Discretion) | Recommended Project Structure | Faible — ce sont des noms, aucune contrainte fonctionnelle n'en dépend, à condition que le fichier marqueur reste séparé de `PLAN.md` (D-03, contraint) |
| A2 | Le registre d'inconnues de `CADRAGE.md` doit être structuré en frontmatter (liste de mappings), pas en tableau Markdown prosaïque, pour rester dans le périmètre d'un « parser de frontmatter minimal » (D-12) | Architecture Patterns, Anti-Patterns | Moyen — si le planificateur choisit un tableau Markdown malgré cette recommandation, le parseur doit couvrir un cas structurel non prévu par D-12 ; à trancher explicitement au plan, pas par défaut |
| A3 | Les extraits Python de cache incrémental et d'écriture atomique (Code Examples) sont des propositions de conception, non extraites du dépôt — aucun code Python de ce type n'existe encore dans le corpus | Code Examples | Faible — ce sont des patrons stdlib standards (hashlib, tempfile+os.replace), largement documentés, le risque est seulement que le planificateur choisisse une variante différente, sans conséquence fonctionnelle |
| A4 | La clé de version de cache (`cache_schema_version`) et son emplacement exact (racine du JSON vs sous-clé) ne sont fixés nulle part dans la spec ou `44-CONTEXT.md` — proposition de recherche pour satisfaire D-13 | Common Pitfalls (Pitfall 2), Code Examples | Faible — le nom exact importe peu, seule la présence d'UN mécanisme de versionnement de schéma est requise par D-13 |

**Si le planificateur choisit une conception différente pour A1-A4, aucune décision D-01 à D-18
n'est remise en cause** — ces quatre points sont hors du périmètre verrouillé par
`44-CONTEXT.md` (Claude's Discretion explicite ou lacune de spec comblée par cette recherche).

## Open Questions

1. **Format exact de frontmatter des cinq types de fichiers (CYCLE.md, CADRAGE.md, PLAN.md,
   VERDICT.md, SUMMARY.md)**
   - What we know : les champs OBLIGATOIRES sont nommés (`ecrit:` sur PLAN.md, D-10 ; `statut:`
     nommant l'auteur sur les dérogations, D-07 ; `hash` + `tentative` sur VERDICT.md, D-09/spec
     §10 — mais sans nom de clé YAML précis donné par la spec) ; le format du registre
     d'inconnues de CADRAGE.md doit porter une "colonne structurante" (spec §7.5) mais aucun nom
     de champ n'est fixé.
   - What's unclear : le nom exact des clés YAML pour `hash`/`tentative` dans VERDICT.md, et la
     structure précise du registre CADRAGE.md (liste vs table).
   - Recommendation : c'est un livrable de CETTE phase (deliverable #1, modèle de données) —
     le planificateur doit le fixer explicitement dans `references/modele-cycles.md`, en gardant
     la contrainte A2 ci-dessus (parsable par frontmatter minimal, pas de table Markdown).

2. **Valeur exacte de `planning_version` signalant l'adhésion (D-02)**
   - What we know : la clé existante `planning_version` doit recevoir une valeur NOUVELLE,
     distincte de "1.0" et "2.0" déjà présents dans 5 emplacements du dépôt `[VERIFIED: grep
     exécuté ce jour]`.
   - What's unclear : la valeur précise (ex. "3.0", "cycles-v1", autre) — non fixée par
     `44-CONTEXT.md` (déléguée) ni par la spec.
   - Recommendation : choisir une valeur qui ne puisse jamais être confondue avec un numéro
     "1.0"/"2.0" incrémenté par erreur — ex. une chaîne non-numérique explicite, à documenter
     dans `references/modele-cycles.md` et dans `config.template.json` du nouveau modèle (à
     créer à côté de l'existant, sans écraser `config.template.json` actuel — D-01b).

3. **Où vit exactement le cache sous `.planning/`**
   - What we know : D-13 exige un cache, nom délégué, « sous `.planning/` ».
   - What's unclear : fichier unique vs répertoire, nom exact — D-04 précise seulement que « le
     cache du recalcul » fait partie du modèle lui-même (pas une entrée « annexe »), donc il doit
     être un emplacement NOMMÉ, pas un fichier ad hoc classé « hors modèle ».
   - Recommendation : un fichier caché unique (ex. `.planning/.recalc-cache.json`), cohérent avec
     les conventions dotfile déjà en usage ailleurs dans le dépôt (`.session-noop`, `.blocked`,
     `.vibeflow-manifest-<mod>` — patrons vus dans `vibeflow-update.sh` `[VERIFIED:
     plugin/_internal/vibeflow-update.sh, lignes 2027-2028, lu ce jour — cite ces deux noms de
     fichiers cachés existants]`).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| python3 (poste local) | Recalcul, tests | ✓ `[VERIFIED: exécuté ce jour]` | 3.14.5 | — |
| python3 (CI) | Suites de tests, découverte CI | ✓ `[CITED: .github/workflows/ci.yml:28-32]` | non épinglée (image `ubuntu-latest`) | — |
| bash (CI) | Exécution des suites `test-*.sh` | ✓ `[CITED: .github/workflows/ci.yml:218-230, "bash \"$t\""]` | non épinglée | — |
| zsh (poste local, D-17) | Boucles de test locales | ✓ (shell par défaut de ce poste, `[CITED: 44-CONTEXT.md code_context]`) | — | — |
| PyYAML | Parsing frontmatter riche | ✗ `[VERIFIED: python3 -c "import yaml" → ModuleNotFoundError, exécuté ce jour]` | — | Parser minimal maison (D-12), pas de PyYAML nécessaire par conception |

**Missing dependencies with no fallback :** aucune — PyYAML absent est le fallback lui-même déjà
prévu par D-12 (parser minimal), pas un blocage.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | suites bash `test-*.sh` maison (PASS/FAIL comptés en shell, patron `check_exit()` — voir `test-detect-gsd-engine.sh` `[VERIFIED: lu ce jour]`) |
| Config file | aucune — découverte par glob CI (`find plugin scripts -type f -path '*/tests/test-*.sh'`) `[CITED: .github/workflows/ci.yml:218]` |
| Quick run command | `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` (nom délégué) |
| Full suite command | `find plugin scripts -type f -path '*/tests/test-*.sh' \| sort \| xargs -I{} bash {}` (reproduction locale du job CI) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MOTR-03 | Refus d'écriture sans `planning_version` adhérent, rien touché | unit (fixture) | `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` | ❌ Wave 0 |
| MOTR-04 | Mode lecture seule — stdout uniquement, refus si GSD détecté | unit (fixture) | idem | ❌ Wave 0 |
| MOTR-05 | Marqueur de clôture = fichier séparé, hash de `PLAN.md` stable | unit (fixture, comparaison hash avant/après création du marqueur) | idem | ❌ Wave 0 |
| MOTR-07/MOTR-08 | 8 états + `indéterminé` sur les 4 contradictions D-08 | unit (banc synthétique, D-06) | idem, fixtures sous `scripts/tests/fixtures/recalc-bench/` | ❌ Wave 0 |
| MOTR-10 | Sortie déterministe (byte-identique sur 2 recalculs) | unit (diff de deux runs successifs) | idem | ❌ Wave 0 |
| MOTR-11 | `cloture.log` append-only, jamais réécrit | unit (mutation rouge : tenter une réécriture, vérifier le refus/l'absence de perte) | idem | ❌ Wave 0 |
| MOTR-13 | Incrémental par hash, `touch` sans effet, contenu modifié détecté même mtime restauré | unit (les deux sens, D-13) | idem | ❌ Wave 0 |
| MOTR-16/17 | Jumeaux négatifs + mutation rouge tracée, CI gate sur le banc seul | CI (découverte auto) | `.github/workflows/ci.yml` job `tests` | ✅ (mécanisme CI déjà en place, seule la nouvelle suite manque) |

### Sampling Rate

- **Per task commit :** `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh`
- **Per wave merge :** reproduction locale de la découverte CI (`find plugin scripts -type f
  -path '*/tests/test-*.sh'`)
- **Phase gate :** CI verte (le job `tests` de `.github/workflows/ci.yml` découvre et exécute
  automatiquement toute nouvelle suite `test-*.sh` sous `plugin/`, aucune modification de
  `ci.yml` requise pour cela — donc **aucun trailer `Gate-Touche:` requis** pour l'ajout de la
  suite elle-même, voir Common Pitfalls / Security Domain plus bas)

### Wave 0 Gaps

- [ ] `plugin/planning-core/scripts/tests/test-recalc-planning.sh` — couvre MOTR-01 à MOTR-17
- [ ] `plugin/planning-core/scripts/tests/fixtures/recalc-bench/` — arborescence synthétique
  versionnée (D-06), au moins 18 cas nommés (8 états + 4 contradictions D-08 + 3 dérogations ×
  avec/sans auteur)
- [ ] Framework install : aucun — `python3`/`bash` déjà présents partout (voir Environment
  Availability)

*(Pas de gap sur l'infrastructure CI elle-même : le mécanisme de découverte est déjà en place et
ne nécessite aucune modification.)*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V1 Architecture | oui | Séparation stricte lecture-seule / écriture (D-02a) — une seule garde de branchement, jamais dispersée (voir Common Pitfalls #5) |
| V5 Input Validation | oui | Parser de frontmatter minimal : toute ambiguïté → `indéterminé`, jamais une valeur devinée (Pitfall 3) ; aucun `eval()`/`exec()` sur le contenu lu depuis le disque (le contenu de `CADRAGE.md`/`PLAN.md`/etc. est une entrée non fiable au sens où elle peut avoir été éditée par n'importe qui) |
| V6 Cryptography | non applicable directement | `hashlib.sha256` utilisé pour l'intégrité de cache, pas pour un usage cryptographique de sécurité (pas de secret à protéger) — usage stdlib standard, pas de primitive à choisir |
| V12 Files and Resources | oui | Construction de chemins toujours par jointure explicite (`os.path.join`), jamais par concaténation de chaînes issues de noms de dossier lus sur disque — un nom de dossier `cycles/../../etc` malformé ne doit jamais produire une lecture/écriture hors de `.planning/` |

### Known Threat Patterns for ce domaine (CLI Python embarqué + modèle de fichiers)

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|-----------------------|
| Traversée de chemin via un nom de dossier `cycles/`/`phases/` malformé (`../`) | Tampering | Valider que chaque segment de nom rencontré via `os.listdir()` ne contient ni `/` ni `..` avant toute jointure de chemin ; sinon signaler « hors modèle » (D-04) plutôt que de suivre le chemin |
| Contenu de fichier conçu pour tromper le parseur de frontmatter vers un faux état `close` | Tampering | L'état `indéterminé` sur toute combinaison non prévue (D-08) est la mitigation de conception principale — ne jamais ajouter de branche « au cas où » qui accepte un format non documenté |
| Exécution de code arbitraire via un candidat de résolution de sibling relatif au cwd | Elevation of Privilege | Résolution de sibling **uniquement** par répertoire du script (`$(cd "$(dirname "$0")" && pwd)`), jamais par cwd — patron déjà durci dans `dag.sh` après un vecteur de compromission mesuré (voir Pattern 1/Don't Hand-Roll) |
| Écriture involontaire pendant le mode `--read-only` sur un lab réel externe (D-06b) | Tampering (sur un dépôt tiers) | Garde unique en tout premier point d'entrée, jamais de site d'écriture non gardé (Pitfall 5) |

**Note sur `check-gate-touche.sh` (question de recherche #8, `44-CONTEXT.md`) :** la surface
surveillée par ce gate est **fermée à cinq classes exactes** — `plugin/conductor/scripts/check-*.sh`,
`scripts/check-*.sh` (racine), leurs suites `tests/test-*.sh` respectives,
`.github/workflows/ci.yml`, et `scripts/hooks/` `[VERIFIED: scripts/check-gate-touche.sh:24-30,
lu ce jour — cite les cinq classes littéralement]`. **`plugin/planning-core/scripts/*` n'appartient
à AUCUNE de ces cinq classes** : les tâches de cette phase (ajout de `recalc-planning.sh`, de sa
suite `test-recalc-planning.sh`, des fixtures) ne nécessitent **aucun trailer `Gate-Touche:`**,
sauf si une tâche modifie explicitement `.github/workflows/ci.yml` ou un `scripts/check-*.sh` à
la racine — ce qu'aucune décision de `44-CONTEXT.md` ne requiert.

## Sources

### Primary (HIGH confidence)

- `plugin/conductor/scripts/dag.sh` (lu intégralement ce jour) — patron d'embarquement Python,
  résolution de siblings, JSON de sortie
- `plugin/planning-core/scripts/detect-gsd-engine.sh` (lu intégralement ce jour) — détection
  moteur GSD, à réutiliser en subprocess
- `plugin/planning-core/references/templates/{INDEX,STATE,PLAN,SUMMARY,config}.template.md|.json`
  (lus ce jour) — gabarits existants du socle v2, à ne pas régresser
- `plugin/planning-core/{SKILL.md,module.json,hooks/hooks.json,VERSION,CHANGELOG.md,README.md}`
  (lus ce jour) — conventions du module cible
- `plugin/_internal/vibeflow-update.sh` (lignes 883, 1180-1220, 1995-2045, 2500-2532, 2790-2820,
  lues ce jour) — confirmation mécanique que seuls `*.sh`/`*.mjs`/`*.js` (exécutables) et
  `*.json`/`*.txt` (données) sont posés par l'installeur
- `.github/workflows/ci.yml` (lignes 1-60, 195-240, lues ce jour) — dépendances CI (bash, jq,
  python3), découverte automatique des suites `test-*.sh`
- `scripts/check-gate-touche.sh` (lu intégralement ce jour) — surface exacte du gate G-2, confirmée hors périmètre pour `plugin/planning-core/`
- `scripts/check-version-sync.sh` (lu ce jour) — triade VERSION↔module.json par module, indépendante du VERSION racine
- `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` (lu intégralement ce jour)
  — modèle de données §3, huit états §3.1, index §7.1, hygiène §7.3, temps §7.4, contraintes
  d'implémentation §10
- Exécution directe sur ce poste : `python3 --version` (3.14.5), `python3 -c "import yaml"`
  (ModuleNotFoundError) — les deux exécutées ce jour
- `~/jarvis-keystone/.planning/` et `~/BusinessFlow-Lab/.planning/` (listing + `config.json`
  inspectés ce jour) — confirment les chiffres de `44-CONTEXT.md` D-06a (BusinessFlow-Lab :
  `config.json` porte bien `"phases_trace": false`)

### Secondary (MEDIUM confidence)

- Formats de frontmatter des cinq types de fichiers du modèle-cycles — extrapolés de la spec
  (§3, §7.4, §7.5) mais non encore écrits concrètement nulle part dans le dépôt ; voir Open
  Questions #1

### Tertiary (LOW confidence)

- Aucune — toutes les affirmations factuelles de cette recherche sont soit vérifiées par lecture
  directe/exécution, soit explicitement marquées `[ASSUMED]` en Code Examples/Assumptions Log.

## Metadata

**Confidence breakdown :**
- Standard stack : HIGH — Python stdlib confirmé, PyYAML confirmé absent, patron d'embarquement lu intégralement
- Architecture : HIGH sur le patron de livraison (dag.sh), MEDIUM sur le format exact des cinq fichiers du modèle (livrable de la phase, pas une découverte)
- Pitfalls : HIGH — dérivés directement des incidents déjà mesurés et documentés dans la spec et dans le code existant du même module (guard-planning-updated.sh, dag.sh non-atomique)

**Research date :** 2026-09-27
**Valid until :** 30 jours (domaine stable — modèle de fichiers et stdlib Python, pas de dépendance externe à surveiller)
