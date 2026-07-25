# Rescope `vf-planning` — Plan d'implémentation

> **Pour les workers agentiques :** SOUS-SKILL REQUIS — utiliser `superpowers:subagent-driven-development`
> (recommandé) ou `superpowers:executing-plans` pour implémenter ce plan tâche par tâche. Les étapes
> utilisent la syntaxe checkbox (`- [ ]`) pour le suivi.

**Goal :** faire cesser la concurrence entre `vf-planning` et le moteur de planning GSD en appliquant
une frontière d'altitude — GSD est seul moteur d'un projet de code, `planning-core` tient le lab
au-dessus et la mémoire/l'enforcement à côté.

**Architecture :** un script de détection factuelle (`detect-gsd-engine.sh`) fournit un signal binaire
« le moteur GSD est-il en place ». Deux hooks existants reçoivent un flag `--defer-to-gsd` qui les fait
se taire quand GSD couvre déjà le terrain. Le `SKILL.md` reçoit une étape 0 de branchement vers deux
séquences nommées, et sa description cesse de revendiquer les intentions dev. Aucun script existant ne
change de comportement par défaut : le nouveau comportement est **opt-in par flag**, ce qui préserve
les usages manuels et au `/checkpoint`.

**Tech Stack :** bash portable (BSD/macOS **et** GNU/Linux), markdown, tests bash maison à compteurs
`PASS`/`FAIL`. Aucune dépendance réseau, aucun runtime node requis côté `planning-core`.

**Spec de référence :** `docs/superpowers/specs/2026-07-25-rescope-vf-planning-gsd-design.md`

## Global Constraints

- **Langue** : tout le contenu produit (code, commentaires, docs, messages de commit) est en **français**.
- **Portabilité bash** : chaque commande `date`/`stat`/`find` doit avoir son repli BSD **et** GNU, sur le
  modèle de `date_to_epoch()` dans `check-planning-state.sh:42-46`.
- **Fail-open absolu** : tout script appelé en hook sort `0` en cas d'erreur inattendue. Seule exception
  du module : `guard-planning-updated.sh` (hook `Stop`), **qu'on ne touche pas dans ce plan**.
- **`set -uo pipefail`** en tête de chaque script (jamais `set -e` : incompatible avec le fail-open).
- **Aucune modification du comportement par défaut** des scripts existants : le nouveau comportement
  passe par le flag `--defer-to-gsd`, ajouté aux appels dans `hooks/hooks.json` uniquement.
- **Densité (ADR-029)** : skills ≤ 500 lignes. `SKILL.md` fait actuellement 137 lignes — le budget est large,
  mais le détail de la doctrine va dans `references/gsd-handoff.md`, pas dans le SKILL.
- **Jamais de fix sans validation humaine (ADR-031)** : aucune réécriture automatique d'un `.planning/`
  existant. Le cas migration **avertit et propose**, il n'agit pas.
- **Préséance des verbes** : toute redirection cible un verbe `/vf-*`, **jamais** un `gsd-*` en entrée de
  chaîne (Iron Law de `rules/vf-verb-precedence.md`).
- **Version cible du module** : `planning-core` v2.3.0 → **v2.4.0**.

---

### Task 1 : Script de détection du moteur GSD

**Files :**
- Create : `plugin/planning-core/scripts/detect-gsd-engine.sh`
- Create : `plugin/planning-core/scripts/tests/test-detect-gsd-engine.sh`

**Interfaces :**
- Consomme : rien (première tâche).
- Produit : le contrat sur lequel toutes les tâches suivantes s'appuient —
  `detect-gsd-engine.sh [--path <dir>] [--quiet]`, exit `1` = chaîne GSD absente,
  `0` = moteur GSD actif, `2` = signalement de migration, `3` = aucun moteur en place.
  Variable d'environnement `GSD_HOME` (défaut `$HOME/.claude/get-shit-done`) surchargeable pour les tests.

- [ ] **Étape 1 : écrire le test qui échoue**

Créer `plugin/planning-core/scripts/tests/test-detect-gsd-engine.sh` :

```bash
#!/usr/bin/env bash
# test-detect-gsd-engine.sh — Tests du détecteur de moteur de planning GSD.
# Portable, sans réseau. Fixtures temporaires + vérification des exit codes.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DETECT="$SCRIPT_DIR/detect-gsd-engine.sh"
PASS=0; FAIL=0

check_exit() { # <description> <expected_code> <actual_code>
  if [ "$2" -eq "$3" ]; then echo "  ✓ $1 (exit $3)"; PASS=$((PASS+1));
  else echo "  ✗ $1 — attendu $2, obtenu $3"; FAIL=$((FAIL+1)); fi
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Faux GSD_HOME présent (le script ne teste que l'existence du dossier).
FAKE_GSD="$TMP/gsd-home"; mkdir -p "$FAKE_GSD"
ABSENT_GSD="$TMP/nulle-part"

mk_state() { # <dir> <première_clé_frontmatter>
  mkdir -p "$1/.planning"
  printf -- '---\n%s: 1.0\nlast_updated: "2026-07-25"\n---\n\n# État\n' "$2" > "$1/.planning/STATE.md"
}

echo "== test-detect-gsd-engine =="

# Cas 1 : chaîne GSD absente → exit 1, priorité maximale (même avec un STATE GSD parfait).
LAB="$TMP/lab1"; mk_state "$LAB" "gsd_state_version"
( cd "$LAB" && GSD_HOME="$ABSENT_GSD" bash "$DETECT" --quiet ); check_exit "chaîne GSD absente" 1 $?

# Cas 2 : moteur GSD actif (STATE porte gsd_state_version) → exit 0.
LAB="$TMP/lab2"; mk_state "$LAB" "gsd_state_version"
( cd "$LAB" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet ); check_exit "moteur GSD actif" 0 $?

# Cas 3 : format planning-core + signal de code → signalement de migration → exit 2.
LAB="$TMP/lab3"; mk_state "$LAB" "planning_version"; echo '{}' > "$LAB/package.json"
( cd "$LAB" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet ); check_exit "migration à examiner" 2 $?

# Cas 4 : format planning-core SANS aucun signal de code (lab non-dev) → terrain libre → exit 3.
LAB="$TMP/lab4"; mk_state "$LAB" "planning_version"
( cd "$LAB" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet ); check_exit "lab non-dev, terrain libre" 3 $?

# Cas 5 : aucun .planning/ → terrain libre → exit 3.
LAB="$TMP/lab5"; mkdir -p "$LAB"
( cd "$LAB" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet ); check_exit "pas de .planning/" 3 $?

# Cas 6 : .planning/ présent mais STATE.md absent → terrain libre → exit 3.
LAB="$TMP/lab6"; mkdir -p "$LAB/.planning"
( cd "$LAB" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet ); check_exit "STATE.md absent" 3 $?

# Cas 7 : le marqueur GSD prime sur les signaux de code (projet dev déjà sous GSD) → exit 0.
LAB="$TMP/lab7"; mk_state "$LAB" "gsd_state_version"; echo '{}' > "$LAB/package.json"
( cd "$LAB" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet ); check_exit "marqueur GSD prime sur le code" 0 $?

# Cas 8 : --path explicite (socle hors du cwd).
LAB="$TMP/lab8"; mk_state "$LAB" "gsd_state_version"
( cd "$TMP" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet --path "$LAB/.planning" ); check_exit "--path explicite" 0 $?

# Cas 9 : argument inconnu → exit 64 (convention des scripts frères).
( cd "$TMP" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --nawak 2>/dev/null ); check_exit "argument inconnu" 64 $?

# Cas 10 : signal de code alternatif (go.mod) reconnu comme les autres.
LAB="$TMP/lab10"; mk_state "$LAB" "planning_version"; echo 'module x' > "$LAB/go.mod"
( cd "$LAB" && GSD_HOME="$FAKE_GSD" bash "$DETECT" --quiet ); check_exit "signal de code go.mod" 2 $?

echo ""
echo "== résultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
```

- [ ] **Étape 2 : lancer le test pour vérifier qu'il échoue**

```bash
bash plugin/planning-core/scripts/tests/test-detect-gsd-engine.sh
```

Attendu : ÉCHEC — tous les cas en `✗` (le script n'existe pas, `bash` sort 127 pour chacun),
puis `== résultat : 0 ok, 10 ko ==`.

- [ ] **Étape 3 : écrire le script**

Créer `plugin/planning-core/scripts/detect-gsd-engine.sh` :

```bash
#!/usr/bin/env bash
# detect-gsd-engine.sh — Le MOTEUR de planning GSD est-il en place sur ce lab ?
#
# Rôle (ADR-055) : répondre à une question FACTUELLE, jamais à une question de métier.
# Le métier d'un lab relève du JUGEMENT du skill (references/domain-detection.md) — un
# détecteur bash s'y tromperait (un lab de contenu peut avoir un package.json). Ce script
# ne dit donc PAS « ce lab est dev » : il dit « il y a (ou non) un moteur GSD en place »,
# et le skill décide ensuite.
#
# Usage:
#   detect-gsd-engine.sh [--path <dir>] [--quiet]
# Defaults: --path .planning
# Env: GSD_HOME (défaut $HOME/.claude/get-shit-done) — surchargeable pour les tests.
#
# Exit codes, évalués dans CET ordre (le premier qui matche gagne) :
#   1 = chaîne GSD absente de la machine — aucun moteur disponible
#   0 = moteur GSD ACTIF (STATE.md porte gsd_state_version)
#   2 = signalement de MIGRATION (STATE.md de facture planning-core + signaux de code)
#   3 = aucun moteur en place (pas de .planning/, ou socle sans marqueur ni signal de code)
#  64 = argument inconnu
set -uo pipefail

PLANNING_DIR=".planning"
GSD_HOME="${GSD_HOME:-$HOME/.claude/get-shit-done}"
QUIET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path) PLANNING_DIR="${2:?--path nécessite une valeur}"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[detect-gsd-engine] argument inconnu : $1" >&2; exit 64 ;;
  esac
done

say() { [ "$QUIET" -eq 1 ] || echo "[gsd-engine] $*"; }

# --- Priorité 1 : la chaîne GSD est-elle installée ? ---
if [ ! -d "$GSD_HOME" ]; then
  say "Chaîne GSD absente ($GSD_HOME) — aucun moteur de planning disponible."
  exit 1
fi

STATE_FILE="$PLANNING_DIR/STATE.md"

# --- Priorité 2 : moteur GSD actif ? (marqueur = clé du frontmatter) ---
if [ -f "$STATE_FILE" ] && grep -qE '^gsd_state_version:' "$STATE_FILE" 2>/dev/null; then
  say "Moteur GSD actif — le planning de ce projet appartient à GSD."
  exit 0
fi

# --- Priorité 3 : socle planning-core + signaux de code → migration à examiner ---
# Les signaux de code sont un indice de SURFACE : ils déclenchent un examen, jamais un verdict.
has_code_signal() {
  local f
  for f in package.json go.mod Cargo.toml pyproject.toml pom.xml build.gradle \
           build.gradle.kts composer.json Gemfile tsconfig.json Package.swift; do
    [ -f "./$f" ] && return 0
  done
  # Projet Xcode : dossier *.xcodeproj à la racine.
  for f in ./*.xcodeproj; do [ -d "$f" ] && return 0; done
  return 1
}

if [ -f "$STATE_FILE" ] && grep -qE '^planning_version:' "$STATE_FILE" 2>/dev/null; then
  if has_code_signal; then
    say "Socle de facture planning-core en présence de code — migration à examiner (ne rien réécrire)."
    exit 2
  fi
fi

# --- Priorité 4 : terrain libre — le jugement métier décide seul ---
say "Aucun moteur de planning en place."
exit 3
```

- [ ] **Étape 4 : lancer le test pour vérifier qu'il passe**

```bash
chmod +x plugin/planning-core/scripts/detect-gsd-engine.sh
bash plugin/planning-core/scripts/tests/test-detect-gsd-engine.sh
```

Attendu : `== résultat : 10 ok, 0 ko ==`, exit 0.

- [ ] **Étape 5 : vérifier la non-régression des tests existants**

```bash
for t in plugin/planning-core/scripts/tests/*.sh; do echo "--- $t"; bash "$t" || echo "ÉCHEC: $t"; done
```

Attendu : aucun `ÉCHEC:` (le nouveau script n'est encore appelé par personne).

- [ ] **Étape 6 : commit**

```bash
git add plugin/planning-core/scripts/detect-gsd-engine.sh \
        plugin/planning-core/scripts/tests/test-detect-gsd-engine.sh
git commit -m "feat(planning-core): détection factuelle du moteur de planning GSD

Répond à « y a-t-il un moteur GSD en place », jamais à « ce lab est-il dev » —
le métier reste du jugement (domain-detection.md). 4 exits par ordre de priorité,
10 cas de test dont la primauté du marqueur GSD sur les signaux de code."
```

---

### Task 2 : Fin de la double injection au démarrage

**Files :**
- Modify : `plugin/planning-core/scripts/check-planning-state.sh` (bloc d'arguments l. 29-38, puis insertion après)
- Modify : `plugin/planning-core/scripts/planning-context.sh` (bloc d'arguments l. 27-34, puis insertion après l. 37)
- Modify : `plugin/planning-core/hooks/hooks.json` (bloc `SessionStart`)
- Modify : `plugin/planning-core/scripts/tests/test-planning-hooks.sh` (ajout de cas en fin de fichier, avant le résumé)

**Interfaces :**
- Consomme : `detect-gsd-engine.sh` de la Task 1 (exit 0 = moteur GSD actif).
- Produit : le flag `--defer-to-gsd` sur ces deux scripts. Sémantique commune : « si le moteur GSD
  est actif et qu'aucune altitude lab n'est en jeu, sortir 0 en silence ». Comportement **sans** le
  flag : strictement inchangé.

- [ ] **Étape 1 : écrire les tests qui échouent**

Lire d'abord la fin de `test-planning-hooks.sh` pour repérer le bloc de résumé (`== résultat :`) et
insérer les cas **juste avant** :

```bash
# --- ADR-055 : --defer-to-gsd met fin à la double injection SessionStart ---
DETECT_TMP=$(mktemp -d)
FAKE_GSD2="$DETECT_TMP/gsd-home"; mkdir -p "$FAKE_GSD2"

mk_gsd_lab() { # <dir> — lab mono-projet dont le planning appartient à GSD
  mkdir -p "$1/.planning"
  printf -- '---\ngsd_state_version: 1.0\nlast_updated: "2026-07-25"\n---\n\n# État\n' \
    > "$1/.planning/STATE.md"
}

# Cas A : check-planning-state --defer-to-gsd sur un lab sous GSD → silencieux, exit 0.
LAB="$DETECT_TMP/a"; mk_gsd_lab "$LAB"
out=$( cd "$LAB" && GSD_HOME="$FAKE_GSD2" bash "$SCRIPTS/check-planning-state.sh" --defer-to-gsd 2>&1 )
code=$?
if [ "$code" -eq 0 ] && [ -z "$out" ]; then
  echo "  ✓ check-planning-state se tait sous moteur GSD"; PASS=$((PASS+1))
else
  echo "  ✗ check-planning-state devait se taire — exit $code, sortie: '$out'"; FAIL=$((FAIL+1))
fi

# Cas B : SANS le flag, le comportement est inchangé (il parle).
out=$( cd "$LAB" && GSD_HOME="$FAKE_GSD2" bash "$SCRIPTS/check-planning-state.sh" 2>&1 )
if [ -n "$out" ]; then echo "  ✓ comportement par défaut inchangé"; PASS=$((PASS+1));
else echo "  ✗ sans flag, le script devait parler"; FAIL=$((FAIL+1)); fi

# Cas C : planning-context --defer-to-gsd sur un lab MONO sous GSD → aucune injection.
out=$( cd "$LAB" && GSD_HOME="$FAKE_GSD2" bash "$SCRIPTS/planning-context.sh" --defer-to-gsd 2>&1 )
if [ -z "$out" ]; then echo "  ✓ planning-context n'injecte rien en mono-projet GSD"; PASS=$((PASS+1));
else echo "  ✗ planning-context devait rester muet — sortie: '$out'"; FAIL=$((FAIL+1)); fi

# Cas D : ALTITUDE LAB — avec un INDEX.md, l'injection a lieu MALGRÉ le flag.
LAB="$DETECT_TMP/d"; mk_gsd_lab "$LAB"
printf '# Index du lab\n\n| Compartiment | Statut |\n|---|---|\n| client-a | actif |\n' \
  > "$LAB/.planning/INDEX.md"
out=$( cd "$LAB" && GSD_HOME="$FAKE_GSD2" bash "$SCRIPTS/planning-context.sh" --defer-to-gsd 2>&1 )
if echo "$out" | grep -q "client-a"; then
  echo "  ✓ altitude lab : l'INDEX est injecté même sous GSD"; PASS=$((PASS+1))
else
  echo "  ✗ l'INDEX du lab devait être injecté — sortie: '$out'"; FAIL=$((FAIL+1))
fi

# Cas E : lab NON-dev (pas de moteur GSD) → le flag ne change rien, ça parle.
LAB="$DETECT_TMP/e"; mkdir -p "$LAB/.planning"
printf -- '---\nplanning_version: 1.0\nlast_updated: "2026-07-25"\n---\n\n# État\n' \
  > "$LAB/.planning/STATE.md"
out=$( cd "$LAB" && GSD_HOME="$FAKE_GSD2" bash "$SCRIPTS/planning-context.sh" --defer-to-gsd 2>&1 )
if [ -n "$out" ]; then echo "  ✓ lab non-dev : injection préservée"; PASS=$((PASS+1));
else echo "  ✗ lab non-dev, l'injection devait avoir lieu"; FAIL=$((FAIL+1)); fi

rm -rf "$DETECT_TMP"
```

**Note pour l'implémenteur** : `$SCRIPTS` et `$PASS`/`$FAIL` existent déjà dans ce fichier de test —
vérifier le nom exact de la variable de chemin en tête de `test-planning-hooks.sh` et l'utiliser telle
quelle plutôt que d'en introduire une nouvelle.

- [ ] **Étape 2 : lancer le test pour vérifier qu'il échoue**

```bash
bash plugin/planning-core/scripts/tests/test-planning-hooks.sh
```

Attendu : ÉCHEC sur les cas A, C et D — `--defer-to-gsd` est un argument inconnu (`check-planning-state.sh`
sort 64 en écrivant sur stderr ; `planning-context.sh` l'ignore silencieusement via son `*) shift`).
Les cas B et E passent déjà.

- [ ] **Étape 3 : implémenter dans `check-planning-state.sh`**

Ajouter la variable près des autres défauts (avant la boucle `while`) :

```bash
DEFER_TO_GSD=0
```

Ajouter le cas dans la boucle `while`, avant le `-h|--help` :

```bash
    --defer-to-gsd) DEFER_TO_GSD=1; shift ;;
```

Puis, juste après la définition de `say()` et **avant** le test `if [ ! -d "$PLANNING_DIR" ]` :

```bash
# --- ADR-055 : ne pas doubler le digest de GSD ---
# Si le moteur GSD est actif, gsd-session-state.sh porte déjà le signal de fraîcheur de ce
# projet : on se retire en silence (exit 0). Appelé avec --defer-to-gsd depuis hooks.json
# uniquement — l'usage manuel et le /checkpoint gardent le comportement complet.
if [ "$DEFER_TO_GSD" -eq 1 ]; then
  DETECT="$(dirname "$0")/detect-gsd-engine.sh"
  if [ -x "$DETECT" ] || [ -f "$DETECT" ]; then
    bash "$DETECT" --quiet --path "$PLANNING_DIR" && exit 0
  fi
fi
```

Mettre à jour l'en-tête `# Usage:` du script pour mentionner `[--defer-to-gsd]`.

- [ ] **Étape 4 : implémenter dans `planning-context.sh`**

Même ajout de variable et de cas d'argument (`--defer-to-gsd) DEFER_TO_GSD=1; shift ;;`), placé **avant**
le `*) shift ;;` existant. Puis, après la ligne `[ -d "$PLANNING_DIR" ] || exit 0` et après la définition
de `INDEX_FILE` / `STATE_FILE` :

```bash
# --- ADR-055 : altitude lab uniquement quand GSD tient le projet ---
# Lab à compartiments (INDEX.md présent) → l'INDEX est de l'altitude LAB, GSD ne le produit
# pas : on injecte. Lab mono-projet sous moteur GSD → gsd-session-state.sh a déjà injecté
# l'état du projet : on se retire pour ne pas payer le contexte deux fois.
if [ "$DEFER_TO_GSD" -eq 1 ] && [ ! -f "$INDEX_FILE" ]; then
  DETECT="$(dirname "$0")/detect-gsd-engine.sh"
  if [ -f "$DETECT" ]; then
    bash "$DETECT" --quiet --path "$PLANNING_DIR" && exit 0
  fi
fi
```

Mettre à jour l'en-tête `# Usage:` et le commentaire de rôle pour documenter le cas.

- [ ] **Étape 5 : câbler le flag dans `hooks/hooks.json`**

Dans le bloc `SessionStart` / `matcher: "startup"`, ajouter `--defer-to-gsd` aux **deux** premières
commandes (laisser `detect-planning-debt.sh` intact — la dette de compartiment est de l'altitude lab) :

```json
          { "type": "command", "command": "bash {{VF_SCRIPTS}}/check-planning-state.sh --defer-to-gsd || true" },
          { "type": "command", "command": "bash {{VF_SCRIPTS}}/planning-context.sh --defer-to-gsd || true" },
```

Mettre à jour le champ `description` du fichier pour citer ADR-055 à côté des ADR déjà listées.

- [ ] **Étape 6 : lancer les tests pour vérifier qu'ils passent**

```bash
bash plugin/planning-core/scripts/tests/test-planning-hooks.sh
bash plugin/planning-core/scripts/tests/test-detect-gsd-engine.sh
```

Attendu : les deux à `0 ko`.

- [ ] **Étape 7 : non-régression complète du module**

```bash
for t in plugin/planning-core/scripts/tests/*.sh; do echo "--- $t"; bash "$t" || echo "ÉCHEC: $t"; done
python3 -c "import json; json.load(open('plugin/planning-core/hooks/hooks.json')); print('hooks.json valide')"
```

Attendu : aucun `ÉCHEC:`, et `hooks.json valide`.

- [ ] **Étape 8 : commit**

```bash
git add plugin/planning-core/scripts/check-planning-state.sh \
        plugin/planning-core/scripts/planning-context.sh \
        plugin/planning-core/hooks/hooks.json \
        plugin/planning-core/scripts/tests/test-planning-hooks.sh
git commit -m "feat(planning-core): fin de la double injection SessionStart sous moteur GSD

--defer-to-gsd (opt-in, câblé dans hooks.json uniquement) fait taire
check-planning-state et planning-context quand gsd-session-state couvre déjà
le projet. L'INDEX du lab reste injecté : c'est de l'altitude lab, GSD ne le
produit pas. Comportement manuel et /checkpoint inchangés."
```

---

### Task 3 : Doctrine de la frontière et table de redirection

**Files :**
- Create : `plugin/planning-core/references/gsd-handoff.md`

**Interfaces :**
- Consomme : les exits de `detect-gsd-engine.sh` (Task 1).
- Produit : la référence que le `SKILL.md` de la Task 4 chargera on-demand, et la table
  `intention → verbe /vf-*` que l'étape 0 applique.

- [ ] **Étape 1 : écrire la référence**

Créer `plugin/planning-core/references/gsd-handoff.md` :

```markdown
# GSD-HANDOFF — Frontière d'altitude entre `planning-core` et le moteur de planning GSD

> Référence du skill `vf-planning`. Chargée **on-demand**, quand `detect-gsd-engine.sh` renvoie
> 0 ou 2, ou quand le jugement métier conclut « lab dev ».
>
> **Iron Law** : *« Un projet de code a un seul moteur de planning : GSD. VibeFlow tient l'altitude
> au-dessus (le lab) et la couche à côté (mémoire, enforcement) — jamais la même. »*

---

## Le test unique

Pour trancher n'importe quel geste : **est-ce que ça concerne un projet, ou le lab ?**

| Geste | Propriétaire |
|---|---|
| `PROJECT.md`, `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, `MILESTONES.md`, `phases/NN/*`, `config.json`, `codebase/` d'un projet dev | **GSD** |
| Santé du `.planning/` d'un projet, learnings de phase, workstreams parallèles | **GSD** |
| `INDEX.md` du lab, typage `deliverable`/`continuous`, `BOARD.md`, seuil d'autonomie, dette de compartiment | **planning-core** |
| Promotion des décisions vers `.claude/memory/` (pont mémoire) | **planning-core** |
| Socle complet d'un lab **non-dev** | **planning-core** |
| `Stop` guard bloquant (`guard-planning-updated.sh`) | **planning-core** — exception motivée |

**Pourquoi le `Stop` guard est une exception** : il ne génère rien. Il vérifie une propriété du
*résultat* — « des livrables ont changé, le planning suit-il ? » — quel qu'en soit l'auteur, GSD ou
humain. Il ne concurrence donc aucun producteur, et GSD n'offre aucun équivalent bloquant.

## Table de redirection — intention → verbe

Sur un lab dev, ces intentions **ne sont pas traitées** par `vf-planning`. Elles partent au verbe.

| L'utilisateur demande | Rediriger vers |
|---|---|
| démarrer le projet, poser la charte, faire la feuille de route, lister les exigences | `/vf-init` |
| où en est-on, statut, avancement, la suite, next | `/vf-progress` |
| cadrer une étape, découper, préparer le sprint, planifier la feature | `/vf-plan` |
| comprendre le code existant, cartographier, « c'est quoi ce repo » | `/vf-map` |
| clôturer un jalon, archiver le milestone, démarrer le suivant | `/vf-progress` (qui route la clôture) |
| vérifier la santé du `.planning/`, réparer une incohérence | `/vf-progress` |

**Toujours un verbe `/vf-*`, jamais un `gsd-*` en entrée de chaîne** — Iron Law de
`rules/vf-verb-precedence.md`. Ne jamais nommer GSD à l'utilisateur.

## Ce que `vf-planning` fait encore sur un lab dev

La **couche lab**, et rien d'autre :

1. `INDEX.md` du lab et son actualisation (tableau de bord qui POINTE vers les plans).
2. Typage des compartiments (`deliverable` / `continuous`) et application du seuil d'autonomie —
   voir `compartments.md`.
3. Surface de la dette de compartiment (`detect-planning-debt.sh`).
4. Pont mémoire vers `.claude/memory/` — voir `bridge-memory.md`.

Un compartiment dev reçoit son `.planning/` **écrit par GSD** (via `/vf-init` depuis ce
compartiment). `vf-planning` ne pose jamais le tronc d'un projet de code.

## Protocole de migration (exit 2)

`detect-gsd-engine.sh` renvoie 2 : un `.planning/` de facture `planning-core`
(`planning_version:`) coexiste avec des signaux de code.

1. **Ne rien réécrire.** Le contenu appartient à l'utilisateur (ADR-031). Aucun écrasement, aucune
   conversion de frontmatter automatique.
2. **Juger le métier d'abord** (`domain-detection.md`). Un lab de contenu qui héberge un site web
   déclenche un exit 2 et reste **non-dev** : dans ce cas, séquence universelle, fin de l'histoire.
3. **Si le lab est bien dev** : exposer le constat en langage utilisateur — « le suivi de ce projet
   est dans un format que l'outillage de développement ne sait pas lire » — et **proposer**
   `/vf-init` pour que le moteur reprenne la main.
4. **Ce qui se perd, le dire.** Les compteurs `progress.total_steps` et le champ `profile` n'ont pas
   d'équivalent GSD. Les décisions clés de `PROJECT.md` méritent d'être promues en mémoire (pont)
   **avant** la reprise. Le dire à l'utilisateur, le laisser décider.
5. **Aucune automatisation disponible** : `gsd-import --from` importe un plan isolé, pas un
   `.planning/` entier. La reprise est un geste humain assisté, pas un script.
```

- [ ] **Étape 2 : vérifier la cohérence des chemins cités**

```bash
cd plugin/planning-core/references
for f in compartments.md bridge-memory.md domain-detection.md; do
  [ -f "$f" ] && echo "✓ $f" || echo "✗ RÉFÉRENCE CASSÉE: $f"
done
grep -c "" gsd-handoff.md   # taille indicative, doit rester sous ~120 lignes
```

Attendu : trois `✓`, aucun `✗`.

- [ ] **Étape 3 : commit**

```bash
git add plugin/planning-core/references/gsd-handoff.md
git commit -m "docs(planning-core): doctrine de la frontière d'altitude avec GSD

Le test unique (projet ou lab ?), la table intention → verbe /vf-*, le
périmètre résiduel sur lab dev, et le protocole de migration exit 2 —
qui avertit et propose, sans jamais réécrire un .planning/ existant."
```

---

### Task 4 : Rescope du `SKILL.md` — description et branchement

**Files :**
- Modify : `plugin/planning-core/SKILL.md` (frontmatter `description` l. 2-12 ; insertion d'une section « Étape 0 » avant « Séquence — Mise en place » ; ajout aux garde-fous, anti-patterns et références)

**Interfaces :**
- Consomme : `detect-gsd-engine.sh` (Task 1), `references/gsd-handoff.md` (Task 3).
- Produit : la surface publique rescopée du skill. Aucune autre tâche n'en dépend.

- [ ] **Étape 1 : remplacer la description du frontmatter**

Remplacer intégralement le bloc `description:` par :

```yaml
description: >
  Utiliser pour poser ou tenir à jour le socle de planning et de documentation d'un lab NON-DEV —
  contenu, vente, growth, design, montage de dossier, recherche : « structure la doc de ce lab »,
  « mets en place le suivi », « on perd le fil / le contexte », « pose le cadre du lab »,
  « initialise le .planning ». Utiliser aussi, sur TOUT lab y compris dev, pour l'altitude LAB :
  « fais l'index de mes projets », « quel compartiment suit quoi », « ce client mérite-t-il son
  propre plan », « remonte les décisions en mémoire », « qu'est-ce qui traîne sans plan ».
  ✘ PAS pour le planning d'un projet de code — la charte, la feuille de route, les exigences,
  l'état et les étapes d'un projet dev appartiennent au moteur de développement : démarrage →
  `/vf-init`, état et avancement → `/vf-progress`, cadrage d'une étape → `/vf-plan`, comprendre
  l'existant → `/vf-map`. Invocable par l'utilisateur ET par un agent en autonomie.
```

- [ ] **Étape 2 : insérer l'étape 0 de branchement**

Insérer cette section **juste avant** `## Séquence — Mise en place` :

```markdown
---

## Étape 0 — Qui tient le planning de ce lab ? (TOUJOURS en premier)

> **Iron Law du rescope (ADR-055)** : *« Un projet de code a un seul moteur de planning : GSD.
> VibeFlow tient l'altitude au-dessus (le lab) et la couche à côté (mémoire, enforcement) — jamais
> la même. »*

Avant toute autre chose, croiser **un fait** et **un jugement** :

1. **Le fait** — lancer `scripts/detect-gsd-engine.sh`. Il ne dit PAS si le lab est dev : il dit
   si un moteur GSD est en place.

   | Exit | Signification | Suite |
   |---|---|---|
   | `0` | moteur GSD actif | → **Séquence B**, couche lab uniquement |
   | `2` | socle `planning-core` + code alentour | → juger le métier, puis protocole de migration (`gsd-handoff.md`) |
   | `3` | aucun moteur en place | → le jugement métier décide seul |
   | `1` | chaîne de dev absente de la machine | → si le métier est dev, proposer l'amorçage via `/vf-init` ; **ne jamais** scaffolder un tronc dev à la main |

2. **Le jugement** — appliquer `references/domain-detection.md` (lire `CLAUDE.md`, les registres, le
   vocabulaire dominant). Le métier n'est **jamais** déduit d'un `package.json` seul.

3. **Brancher** :
   - **Lab non-dev** → **Séquence A** (socle universel) ci-dessous. Comportement historique intact.
   - **Lab dev** → **Séquence B** : appliquer **uniquement** la couche lab (`INDEX.md`, typage des
     compartiments, pont mémoire, surface de la dette) et **rediriger** toute demande portant sur un
     projet vers son verbe, selon la table de `references/gsd-handoff.md`. Ne pas générer
     `PROJECT.md` / `ROADMAP.md` / `REQUIREMENTS.md` / `STATE.md` / `phases/` d'un projet de code.

**Sur un lab dev à compartiments** : le lab reçoit `INDEX.md` + `STATE.md` de steering (à nous) ;
chaque compartiment dev reçoit son `.planning/` **écrit par GSD**, depuis ce compartiment. Les deux
couches ne se croisent sur aucun fichier.

Charger `references/gsd-handoff.md` dès que l'exit vaut 0 ou 2, ou que le jugement conclut « dev ».
```

Renommer les deux titres de séquence existants pour que le branchement soit lisible :
`## Séquence — Mise en place (.planning/ absent)` → `## Séquence A — Socle universel, lab non-dev (.planning/ absent)`,
et `## Séquence — Maintenance (.planning/ déjà là)` → `## Séquence A (suite) — Maintenance du socle universel`.
Puis ajouter, après la section maintenance :

```markdown
## Séquence B — Couche lab au-dessus de GSD (lab dev)

1. **Ne générer aucun artefact de projet.** Le tronc d'un projet de code appartient à GSD.
2. **Poser ou rafraîchir l'altitude lab** si le lab a plusieurs compartiments : `INDEX.md`, typage
   `deliverable`/`continuous`, seuil d'autonomie (`references/compartments.md`).
3. **Surface de la dette** : `scripts/detect-planning-debt.sh` (advisory).
4. **Pont mémoire** : promouvoir les décisions structurantes vers `.claude/memory/`
   (`references/bridge-memory.md`) — référencer, jamais recopier.
5. **Rediriger** ce qui concerne un projet vers son verbe (table de `references/gsd-handoff.md`),
   en vocabulaire VibeFlow, sans jamais nommer l'outillage sous-jacent.
```

- [ ] **Étape 3 : compléter garde-fous, anti-patterns et références**

Ajouter aux **Garde-fous** :

```markdown
- **Ne jamais poser le tronc d'un projet de code** (ADR-055). Sur un lab dev, la charte, la feuille
  de route, les exigences, l'état et les étapes appartiennent au moteur de développement — on
  redirige vers le verbe, on ne génère pas.
```

Ajouter aux **Anti-patterns** :

```markdown
- ❌ Écrire un `STATE.md` au format `planning_version:` dans un `.planning/` que l'outillage de dev
  pilote (les deux frontmatters sont incompatibles — le premier qui écrit rend l'autre aveugle).
- ❌ Réécrire ou convertir un `.planning/` existant pour « aligner le format » (ADR-031 : on avertit
  et on propose, l'utilisateur décide).
- ❌ Répondre « où en est-on ? » soi-même sur un lab dev au lieu de rediriger vers `/vf-progress`.
```

Ajouter aux **Références** :

```markdown
- `references/gsd-handoff.md` — frontière d'altitude avec le moteur de dev : test unique, table de
  redirection intention → verbe, périmètre résiduel sur lab dev, protocole de migration (ADR-055).
- `scripts/detect-gsd-engine.sh` — fait vérifiable « un moteur de planning est-il en place » (advisory).
```

- [ ] **Étape 4 : vérifier la densité et la cohérence**

```bash
wc -l plugin/planning-core/SKILL.md   # ADR-029 : ≤ 500 lignes
grep -n "gsd-handoff\|detect-gsd-engine\|Séquence A\|Séquence B\|Étape 0" plugin/planning-core/SKILL.md
grep -c "gsd-new-project\|gsd-progress\|get-shit-done" plugin/planning-core/SKILL.md
```

Attendu : moins de 500 lignes ; les cinq ancrages présents ; **0** occurrence de nom `gsd-*`
utilisateur-visible dans le SKILL (la plomberie ne fuite pas — seul `detect-gsd-engine.sh`, qui est
un script du module, porte « gsd » dans son nom).

- [ ] **Étape 5 : commit**

```bash
git add plugin/planning-core/SKILL.md
git commit -m "feat(planning-core)!: rescope vf-planning sur le lab, plus sur le projet dev

La description cesse de revendiquer les intentions dev (feuille de route,
où en est-on) et nomme ses voisins en contre-exemples — c'était la moitié
du conflit : au matching, vf-planning concurrençait le moteur de dev.

Étape 0 de branchement (fait + jugement) puis deux séquences : socle
universel non-dev, ou couche lab au-dessus de GSD."
```

---

### Task 5 : Périphérie — commande, détection de domaine, ADR-055

**Files :**
- Modify : `plugin/commands/vf-planning.md`
- Modify : `plugin/planning-core/references/domain-detection.md` (après la section « Grille de lecture »)
- Modify : `docs/ADR.md` (ligne d'index après ADR-053, puis corps en fin de fichier)

**Interfaces :**
- Consomme : tout ce qui précède (le vocabulaire et les exits doivent être cités à l'identique).
- Produit : la trace décisionnelle et la surface `/vf-planning` alignées.

- [ ] **Étape 1 : réécrire la commande**

Remplacer le contenu de `plugin/commands/vf-planning.md` par :

```markdown
---
description: Met en place ou tient à jour le socle de planning d'un lab non-dev, et l'altitude lab (index des projets, compartiments, pont mémoire) sur tous les labs.
argument-hint: "[optionnel : mets en place le planning / fais l'index de mes projets / qu'est-ce qui traîne sans plan]"
---

Invoque le skill **`vf-planning`** : $ARGUMENTS

Le skill commence **toujours** par déterminer qui tient le planning de ce lab (étape 0), puis :

- **lab non-dev** (contenu, vente, growth, design, dossier, recherche) → il pose ou maintient le
  tronc `.planning/` adapté au métier (`PROJECT`, `STATE` ★ clé de voûte, `ROADMAP`, etc.) — jamais
  une forme dev imposée ;
- **lab dev** → il n'écrit **pas** le planning du projet : il tient l'altitude lab (index des
  projets, typage des compartiments, pont mémoire, dette) et redirige vers le bon verbe.

Pour un projet de code : démarrage → `/vf-init`, état et avancement → `/vf-progress`, cadrage d'une
étape → `/vf-plan`, comprendre l'existant → `/vf-map`.

Si le module `planning-core` n'est pas installé, lance d'abord `vibeflow-install`.
```

- [ ] **Étape 2 : compléter `domain-detection.md`**

Insérer après la « Grille de lecture », avant « Auto-infusion à l'installation » :

```markdown
## Bascule dev → moteur de développement (ADR-055)

La première ligne de la grille (« Code source, stack technique, tests, `src/`, build → Dev ») ne
conduit **plus** à scaffolder un tronc `.planning/`. Sur un lab dev, le planning du projet appartient
au moteur de développement ; `vf-planning` tient l'altitude lab et redirige. Voir `gsd-handoff.md`.

Ce que cela ne change pas : **le métier reste du jugement.** `scripts/detect-gsd-engine.sh` n'infère
aucun métier — il constate un fait (« un moteur de planning est-il en place ? »). Ses signaux de code
(`package.json`, `go.mod`, `*.xcodeproj`…) servent à déclencher un **examen**, jamais à rendre un
verdict : un lab de contenu qui héberge un site web les déclenche et reste non-dev. Le principe de
cette référence est intact — on lit le sens du lab, pas sa surface.
```

- [ ] **Étape 3 : ajouter ADR-055 à l'index de `docs/ADR.md`**

Ajouter la ligne à la suite de celle d'ADR-053 dans le tableau d'index :

```markdown
| ADR-055 | 2026-07-25 | Frontière d'altitude entre planning-core et le moteur de planning GSD — un projet = un seul moteur | Validée |
```

- [ ] **Étape 4 : écrire le corps de l'ADR-055**

Ajouter en fin de `docs/ADR.md`, en suivant exactement le gabarit d'ADR-050 :

```markdown
## ADR-055 : Frontière d'altitude entre `planning-core` et le moteur de planning GSD

**Date** : 2026-07-25
**Statut** : Validée
**Décideur** : Samuel (constat : « le vf-planning est en concurrence directe avec le planning de GSD »)
**Contexte** : release v2.29.0 — planning-core v2.4.0

### Problème

`vf-planning` et la chaîne GSD produisent **les mêmes fichiers** dans **le même dossier** avec des
frontmatters **incompatibles** : `planning_version` + `progress.total_steps` d'un côté,
`gsd_state_version` + `progress.total_phases/total_plans` de l'autre. Le premier moteur qui écrit rend
l'autre aveugle (`gsd-sdk query`, `gsd-health`, `gsd-session-state.sh` ne lisent pas le format
`planning-core`, et réciproquement). S'y ajoutent une double injection `SessionStart`
(`gsd-session-state.sh` + `check-planning-state.sh` + `planning-context.sh`) et une concurrence au
matching sémantique : la description de `vf-planning` revendiquait « fais-moi une feuille de route »
et « où en est-on ? », face à `gsd-new-project` et `gsd-progress`.

Le recouvrement dépassait le tronc : compartiments vs `gsd-workstreams`/`workspace`, pont mémoire vs
`gsd-extract-learnings`/`graphify`/`thread`, fraîcheur vs `gsd-health`.

### Options Considérées

| Option | Verdict |
|---|---|
| GSD moteur unique sur tous les labs | Rejetée — `roadmapper`/`phases`/`requirements` sont taillés pour le code ; casse les 4 bundles non-dev |
| Bascule sur la présence de GSD au lieu du métier | Rejetée — un lab contenu avec GSD installé hériterait d'un planning dev |
| GSD gagne partout où il a un équivalent | Rejetée — perd l'enforcement automatique et le lien aux registres VibeFlow |
| Coexistence documentée | Rejetée — c'est l'état de départ ; l'ambiguïté de déclenchement reste entière |
| Détecteur bash du métier | Rejetée — heurte `domain-detection.md` : un lab de contenu peut avoir un `package.json` |
| **Frontière d'altitude** | **Retenue** — test unique et vérifiable : « ça concerne un projet, ou le lab ? » |

### Décision

1. **Un projet de code a un seul moteur de planning : GSD.** `planning-core` ne génère plus aucun
   artefact de projet sur un lab dev ; il redirige vers le verbe `/vf-*` (jamais un `gsd-*` en
   entrée de chaîne).
2. **`planning-core` garde l'altitude lab** (`INDEX.md`, typage `deliverable`/`continuous`, seuil
   d'autonomie, dette) et **la couche à côté** (pont mémoire vers `.claude/memory/`), plus **le socle
   complet des labs non-dev** — où GSD n'est ni installé ni pertinent.
3. **Le métier reste du jugement** ; seul le fait « un moteur GSD est-il en place » est outillé
   (`detect-gsd-engine.sh`, 4 exits par ordre de priorité).
4. **Exception assumée — le `Stop` guard reste bloquant** : `guard-planning-updated.sh` ne génère
   rien, il vérifie une propriété du *résultat* quel qu'en soit l'auteur. GSD n'a aucun équivalent
   bloquant (`gsd-health` signale à la demande).
5. **Aucune réécriture d'un `.planning/` existant** (ADR-031) : le cas migration avertit et propose,
   l'utilisateur décide.

### Conséquences

**Positives** : plus de format concurrent dans un même `.planning/` ; fin de la double injection au
démarrage ; le déclenchement est désambiguïsé côté description, pas seulement côté exécution ;
`planning-core` retrouve un périmètre défendable (le lab, la mémoire, l'enforcement) au lieu d'un
tronc universel qui doublonnait le moteur de dev. **Négatives / risque** : les labs dev déjà porteurs
d'un `.planning/` de facture `planning-core` restent en format non lisible par l'outillage de dev — et
aucune migration automatique n'existe (`gsd-import --from` n'importe qu'un plan isolé). Mitigation :
exit 2 dédié, protocole de reprise documenté, geste humain assisté.

### Code Impacté

- `plugin/planning-core/scripts/detect-gsd-engine.sh` (nouveau) + son test
- `plugin/planning-core/scripts/{check-planning-state.sh, planning-context.sh}` (flag `--defer-to-gsd`)
- `plugin/planning-core/hooks/hooks.json` (SessionStart : `--defer-to-gsd`)
- `plugin/planning-core/SKILL.md` (description rescopée + étape 0 + séquences A/B)
- `plugin/planning-core/references/{gsd-handoff.md (nouveau), domain-detection.md}`
- `plugin/commands/vf-planning.md`
```

- [ ] **Étape 5 : vérifier**

```bash
grep -n "ADR-055" docs/ADR.md | head
grep -n "où en est-on" plugin/commands/vf-planning.md   # doit ne RIEN renvoyer
grep -n "vf-progress\|vf-init" plugin/commands/vf-planning.md
```

Attendu : ADR-055 présent à l'index **et** en corps ; plus aucune revendication de « où en est-on ? »
dans la commande ; les verbes de redirection cités.

- [ ] **Étape 6 : commit**

```bash
git add plugin/commands/vf-planning.md \
        plugin/planning-core/references/domain-detection.md \
        docs/ADR.md
git commit -m "docs(adr-054): frontière d'altitude planning-core / moteur GSD

Trace décisionnelle : le problème factuel (formats incompatibles, double
injection, concurrence au matching), les 6 options pesées, l'exception
motivée du Stop guard, et le risque assumé (pas de migration automatique).
Commande /vf-planning et domain-detection.md alignés."
```

---

### Task 6 : Release du module et du plugin

**Files :**
- Modify : `plugin/planning-core/VERSION`, `plugin/planning-core/module.json`, `plugin/planning-core/CHANGELOG.md`, `plugin/planning-core/README.md`
- Modify : `VERSION`, `plugin/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `README.md`, `README.fr.md`

**Interfaces :**
- Consomme : les cinq tâches précédentes, toutes commitées.
- Produit : la release taguée. Rien ne dépend de cette tâche.

- [ ] **Étape 1 : bump du module**

`plugin/planning-core/VERSION` → `v2.4.0`. Dans `module.json`, passer `"version": "v2.4.0"` et
réécrire la `description` pour refléter le rescope :

```json
  "description": "Socle de planning & gestion documentaire des labs NON-DEV (tronc commun .planning/ adapté au métier) + altitude LAB sur tous les labs : index des projets, compartiments typés deliverable/continuous, seuil d'autonomie, dette, pont mémoire et enforcement par hooks. Sur un lab dev, le planning du projet appartient au moteur de développement — ce module redirige (ADR-055).",
```

- [ ] **Étape 2 : entrée de CHANGELOG du module**

Ajouter en tête de `plugin/planning-core/CHANGELOG.md`, en suivant le format des entrées existantes
(les relire d'abord pour calquer le style exact) :

```markdown
## v2.4.0 — Rescope : frontière d'altitude avec le moteur de développement (ADR-055)

**Le conflit** : `vf-planning` et la chaîne de dev produisaient les mêmes fichiers dans le même
dossier avec des frontmatters incompatibles (`planning_version` vs `gsd_state_version`) — le premier
moteur qui écrivait rendait l'autre aveugle. S'y ajoutaient une double injection `SessionStart` et
une concurrence au matching sémantique.

**La règle** : un projet de code a un seul moteur de planning. `planning-core` tient désormais
l'altitude **lab** (index des projets, compartiments typés, seuil d'autonomie, dette), la couche **à
côté** (pont mémoire, enforcement), et le **socle complet des labs non-dev**.

- **Ajouté** — `scripts/detect-gsd-engine.sh` : fait vérifiable « un moteur de planning est-il en
  place ? », 4 exits par ordre de priorité. N'infère aucun métier (le métier reste du jugement).
- **Ajouté** — `references/gsd-handoff.md` : test unique, table de redirection intention → verbe,
  périmètre résiduel sur lab dev, protocole de migration.
- **Ajouté** — flag `--defer-to-gsd` sur `check-planning-state.sh` et `planning-context.sh`, câblé
  dans `hooks/hooks.json` : fin de la double injection au démarrage. **Comportement par défaut
  inchangé** (usage manuel et `/checkpoint` intacts). L'`INDEX.md` du lab reste injecté — altitude lab.
- **Changé** — `SKILL.md` : description rescopée (les intentions dev partent avec des contre-exemples
  nommant `/vf-init`, `/vf-progress`, `/vf-plan`, `/vf-map`), étape 0 de branchement, séquences A
  (socle universel non-dev) et B (couche lab au-dessus du moteur de dev).
- **Inchangé** — `guard-planning-updated.sh` reste **bloquant** sur tous les labs : il ne génère rien,
  il vérifie un résultat. Exception motivée d'ADR-055.
- **Inchangé** — les 4 bundles non-dev (`content`, `business-pilot`, `growth`, `kpi-analyst`) : tous
  passent par la séquence A, aucune régression.
- **Limite connue** — pas de migration automatique d'un `.planning/` existant : `gsd-import --from`
  n'importe qu'un plan isolé. Exit 2 signale, le skill avertit et propose (ADR-031).
```

- [ ] **Étape 3 : mettre le README du module à jour**

Le README porte encore `**Version** : v1.1.0` alors que le module est en v2.3.0 — corriger en
`v2.4.0` au passage. Ajuster l'accroche et la section « L'idée » : le socle universel concerne les
labs **non-dev**, et sur un lab dev le module tient l'altitude lab et redirige (citer ADR-055 et
`references/gsd-handoff.md`).

- [ ] **Étape 4 : bump du plugin (les 3 fichiers + les 2 README)**

Version racine v2.28.0 → **v2.29.0** (capacité rescopée → minor, par la règle du `CLAUDE.md`) :

```bash
echo "v2.29.0" > VERSION
```

Puis passer `"version": "v2.29.0"` dans `plugin/.claude-plugin/plugin.json` **et**
`.claude-plugin/marketplace.json`, et ajouter la ligne d'historique + le badge de version dans
`README.md` **et** `README.fr.md`, en calquant la forme des entrées v2.28.0 existantes.

- [ ] **Étape 5 : vérification complète avant release**

```bash
# Cohérence des trois versions
cat VERSION
grep -h '"version"' plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json
grep -h '"version"' plugin/planning-core/module.json
cat plugin/planning-core/VERSION

# Suite de tests du module + agents natifs
for t in plugin/planning-core/scripts/tests/*.sh; do echo "--- $t"; bash "$t" || echo "ÉCHEC: $t"; done
bash plugin/conductor/scripts/check-agents.sh

# JSON valides
python3 -c "import json;[json.load(open(p)) for p in ['plugin/planning-core/hooks/hooks.json','plugin/planning-core/module.json','plugin/.claude-plugin/plugin.json','.claude-plugin/marketplace.json']];print('tous les JSON valides')"
```

Attendu : `VERSION` = `v2.29.0` et les deux `"version"` du plugin identiques ; module en `v2.4.0`
partout ; aucun `ÉCHEC:` ; `check-agents.sh` OK ; `tous les JSON valides`.

- [ ] **Étape 6 : commit de release**

```bash
git add VERSION plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json \
        README.md README.fr.md \
        plugin/planning-core/VERSION plugin/planning-core/module.json \
        plugin/planning-core/CHANGELOG.md plugin/planning-core/README.md
git commit -m "release: v2.29.0 — rescope vf-planning, frontière d'altitude avec GSD (ADR-055)"
```

- [ ] **Étape 7 : tag annoté après merge sur `main` (règle non négociable du `CLAUDE.md`)**

À faire **après** le merge, pas avant :

```bash
git tag -a v2.29.0 -m "v2.29.0 — rescope vf-planning : frontière d'altitude avec le moteur GSD (ADR-055)"
git push origin v2.29.0
bash scripts/check-release-tag.sh --remote
```

Attendu : `✓`.

---

## Vérification finale du plan

Une fois les 6 tâches faites, ces invariants doivent tenir :

| Invariant | Commande |
|---|---|
| Aucun nom `gsd-*` utilisateur-visible dans le SKILL | `grep -c "gsd-new-project\|gsd-progress\|get-shit-done" plugin/planning-core/SKILL.md` → 0 |
| La commande ne revendique plus l'état d'un projet | `grep -c "où en est-on" plugin/commands/vf-planning.md` → 0 |
| Densité ADR-029 respectée | `wc -l plugin/planning-core/SKILL.md` → < 500 |
| Suite de tests verte | `for t in plugin/planning-core/scripts/tests/*.sh; do bash "$t" || echo ÉCHEC; done` |
| Tag présent | `bash scripts/check-release-tag.sh --remote` → `✓` |
