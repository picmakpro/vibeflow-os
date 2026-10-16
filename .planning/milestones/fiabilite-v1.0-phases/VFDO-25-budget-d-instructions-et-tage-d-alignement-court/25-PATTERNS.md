# Phase 25 : Budget d'instructions - Carte des patrons

**Mappé le :** 2026-09-15
**Fichiers analysés :** 10 (2 nouveaux fichiers de code, 1 donnée versionnée + 1 sentinelle
différées au checkpoint de calibration, 1 étape CI, 5 fichiers de documentation/catalogue)
**Analogues trouvés :** 8 / 10 (2 sans précédent exact — voir `## Sans analogue`)

Rappel de portée (25-CONTEXT.md D-06 bis) : cette carte couvre **tout ce qui est livrable avant la
calibration** — script, suite, câblage CI en mode non armé, catalogue, README, note ADR-029. Les
deux fichiers de données (`.planning/instruction-budget-baselines.tsv` et
`.planning/.instruction-budget-armed`) sont **gravés dans une seconde PR**, après la clôture de la
Phase 40 (checkpoint bloquant) — ils figurent ici pour leur *forme*, pas pour leur contenu.

## File Classification

| Fichier nouveau/modifié | Rôle | Flux de données | Analogue le plus proche | Qualité du match |
|---|---|---|---|---|
| `plugin/conductor/scripts/check-instruction-budget.sh` | gate machine (utility/config) | batch (scan de fichiers + comparaison de seuil) | `plugin/dev-orchestrator/scripts/check-requirements-survival.sh` (sentinelle/ratchet) **+** `plugin/conductor/scripts/check-divergence.sh` (codes énumérés, bash portable) **+** `plugin/software-architecture/scripts/check-file-size.sh` (comptage de lignes robuste) | composite (rôle exact, trois analogues complémentaires) |
| `plugin/conductor/scripts/tests/test-check-instruction-budget.sh` | test (mutation + issues multiples) | batch | `plugin/conductor/scripts/tests/test-check-divergence.sh` (mutants vérifiés par `cmp`) **+** `plugin/dev-orchestrator/scripts/tests/test-check-requirements-survival.sh` (cinq issues, harness `ok()/ko()`) | exact |
| `.planning/.instruction-budget-armed` | config (sentinelle versionnée) | event-driven (armé/non armé) | `.planning/.requirements-survival-armed` | exact (précédent unique du dépôt) |
| `.planning/instruction-budget-baselines.tsv` | config/données (contrat versionné) | batch | aucun précédent de *format de données* — voir `## Sans analogue` | aucun (Claude's Discretion, A2 de RESEARCH.md) |
| `.github/workflows/ci.yml` (job `gates`, étape neuve) | CI (request-response, étape de pipeline) | request-response | étapes existantes du même job : `check-agents --strict sur chaque plugin/*/agents`, `check-agents --strict sur chaque plugin/*/AGENT.md` (découverte non vide, commentaire « POURQUOI ») | exact |
| `plugin/conductor/README.md` (catalogue + correction `:95-99`) | doc/catalogue | — | l'entrée `check-divergence.sh` déjà catalguée (Phase 39) comme modèle d'ajout ; correction ponctuelle de la phrase `check-agents.sh` | exact |
| `plugin/conductor/VERSION` + `plugin/conductor/module.json` | config (version module) | — | bump Phase 39 (`v1.34.0` → `v1.35.0` pour `check-divergence.sh`) | exact |
| `plugin/conductor/CHANGELOG.md` | doc | — | entrée `[v1.35.0]` (Phase 39, nouveau script + nouvelle suite) comme gabarit | exact |
| `README.md` / `README.fr.md` (compteur de suites) | doc | — | ligne « 77 suites in CI » (`README.md:140`) / équivalent FR | exact |
| `docs/ADR.md` (note datée sous ADR-029) | doc | — | bloc `> **ADR-065 : numéro non attribué**` (note ajoutée après le tableau, sans réécrire l'entrée) **+** le motif « amendée le AAAA-MM-JJ (…) » du statut d'ADR-069 dans le tableau principal | role-match |

## Pattern Assignments

### `plugin/conductor/scripts/check-instruction-budget.sh` (gate machine, batch)

**Analogue principal :** `plugin/dev-orchestrator/scripts/check-requirements-survival.sh`
**Analogues secondaires :** `plugin/conductor/scripts/check-divergence.sh`,
`plugin/software-architecture/scripts/check-file-size.sh`

**En-tête / doctrine du script** (patron à reproduire, `check-requirements-survival.sh:1-37`) :
```bash
#!/usr/bin/env bash
# check-instruction-budget.sh — mesure et publie, par fichier d'agent distribué, la charge
# d'instructions et le nombre de lignes (ADR-029, BUDG-01/02), comparées à une baseline en ratchet.
#
# Rôle : ce gate CONSTATE un dépassement de baseline ; il ne réécrit jamais un fichier lui-même
# (ADR-031). Trois issues (QUAL-01) : conforme / dépassement / imparsable BRUYANT.
#
# Usage:
#   check-instruction-budget.sh [--path <dir>]
#
# Exit codes (contrat interne, tous énumérés — patron check-divergence.sh) :
#   0  = conforme, armé (ou rien à signaler)
#   1  = dépassement de baseline ET sentinelle armée (bloquant)
#   2  = NON VÉRIFIABLE — découverte vide (0 fichier) ou frontmatter/body illisible (imparsable BRUYANT)
#   3  = dépassement détecté MAIS non armé (avertissement), rapport imprimé intégralement
set -uo pipefail
```

**Idiome d'arguments / usage** (repris tel quel, `check-requirements-survival.sh:40-62`) :
```bash
ROOT="."
while [ "$#" -gt 0 ]; do
  case "$1" in
    --path)
      if [ "$#" -lt 2 ]; then
        echo "[check-instruction-budget] --path nécessite une valeur" >&2
        exit 64
      fi
      ROOT="$2"; shift 2 ;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0 ;;
    *) echo "[check-instruction-budget] argument inconnu : $1" >&2; exit 64 ;;
  esac
done
```

**Sentinelle lue, jamais écrite** (idiome exact, `check-requirements-survival.sh:74,90-127` — même
mécanisme déjà cité et vérifié par RESEARCH.md « Pattern 1 ») :
```bash
SENTINEL="${VF_BUDGET_PLANNING_DIR:-$ROOT/.planning}/.instruction-budget-armed"
ARMED=0
[ -f "$SENTINEL" ] && ARMED=1
# ... mesure, comparaison à la baseline, construction de FAIL_MSGS[] ...
if [ "${#FAIL_MSGS[@]}" -gt 0 ]; then
  for m in "${FAIL_MSGS[@]}"; do echo "[check-instruction-budget] $m" >&2; done
  if [ "$ARMED" -eq 1 ]; then exit 1; else exit 3; fi
fi
exit 0
```
Point de vigilance repris de l'en-tête `check-requirements-survival.sh:8-9` : « il ne dit JAMAIS
qu'un [fichier] est faux [...] — seulement la présence ou l'absence » — transposé ici, le gate
budget ne réécrit et n'estime jamais une remédiation, il publie un delta chiffré.

**Découverte non vide obligatoire** (idiome `check-divergence.sh:76-92` pour la forme « `[ -d ... ]
|| exit 2` » + « Code Examples » de RESEARCH.md, déjà vérifié exécutable sur ce dépôt) :
```bash
found=0
for f in plugin/*/agents/*.md; do [ -f "$f" ] && found=$((found+1)); done
for f in plugin/*/AGENT.md;    do [ -f "$f" ] && found=$((found+1)); done
if [ "$found" -eq 0 ]; then
  echo "[check-instruction-budget] aucun fichier d'agent distribué découvert — non vérifiable" >&2
  exit 2
fi
```

**Codes de sortie tous énumérés, jamais implicites** (patron `check-divergence.sh:44-52`, à
reproduire dans l'en-tête du nouveau script — voir gabarit ci-dessus).

**Comptage de lignes robuste sans newline final** (repris tel quel de
`check-file-size.sh:45-48`, déjà cité vérifié fonctionnel par RESEARCH.md « Pattern 3 ») :
```bash
# `wc -l` sous-compte un fichier sans \n final — piège documenté ici.
n=$(awk 'END { print NR }' "$f" 2>/dev/null || echo 0)
```

**Isolation du body hors frontmatter** (dérivé de `frontmatter_block()`,
`check-divergence.sh:150-155`, adapté pour exclure plutôt qu'extraire — RESEARCH.md « Pattern 2 »,
déjà vérifié fonctionnel BSD/GNU awk sur les 31 fichiers du corpus) :
```bash
body_only() { # <file> -> body sur stdout, frontmatter exclu
  awk '
    /^---[[:space:]]*$/ { n++; if (n==1) {infm=1; next}; if (n==2) {infm=0; next} }
    infm { next }
    { print }
  ' "$1"
}
```

**Anti-pattern à éviter** (cité verbatim `check-file-size.sh:47` commentaire + RESEARCH.md
« Anti-Patterns ») : jamais de `2>/dev/null || true` sur le comptage lui-même — seul le calcul de
secours `|| echo 0` (fail visible dans le compte, pas un skip silencieux du fichier) est admis, sur
le même modèle que `check-file-size.sh:48`.

**Marqueur d'exception explicite si besoin** (patron `vibeflow:allow-large-file`,
`check-file-size.sh:16-17,35-38`) — à réutiliser SEULEMENT si le plan retient une exclusion de
ligne explicite (ex. une ligne de citation contenant un marqueur hors contexte normatif, cf.
`specifics` de CONTEXT.md) :
```bash
has_optout() {
  head -n 5 "$1" 2>/dev/null | grep -q 'vibeflow:allow-large-file'
}
```

**Portabilité** (idiomes déjà vérifiés dans `check-divergence.sh` et cités par RESEARCH.md, aucun
besoin de `vf-portable.sh` ici — le gate ne dépend d'aucun interpréteur externe) : `set -uo
pipefail` sans `-e` ; jamais `grep -P` ; jamais `mapfile`/`readarray` (bash 3.2 macOS = rc 127),
utiliser `while IFS= read -r … done < <(process substitution)` comme dans `check-divergence.sh:170-175,257-263`.

---

### `plugin/conductor/scripts/tests/test-check-instruction-budget.sh` (test, batch + mutation)

**Analogues :** `plugin/conductor/scripts/tests/test-check-divergence.sh` (mutants `cmp`),
`plugin/dev-orchestrator/scripts/tests/test-check-requirements-survival.sh` (cinq issues,
constructeurs de fixture)

**En-tête / doctrine de la suite** (patron `test-check-divergence.sh:1-21`) :
```bash
#!/usr/bin/env bash
# test-check-instruction-budget.sh — Suite de vérification de check-instruction-budget.sh
# (BUDG-01, BUDG-02, QUAL-01). Un cas par état du contrat, chaque cas construit sa propre fixture
# dans un mktemp -d, jamais sur le dépôt réel (patron test-check-requirements-survival.sh).
#
# Deux mutations OPPOSABLES (QUAL-01) :
#   - MUT-1 neutralise la comparaison à la baseline dans le SCRIPT : une fixture qui dépasse doit
#     rester (à tort) verte sur le mutant, rouge sur l'original.
#   - MUT-2 neutralise la lecture de la sentinelle (le gate croit toujours "non armé") : une
#     fixture armée+dépassée doit rester (à tort) verte (exit 3 au lieu de 1) sur le mutant.
set -uo pipefail
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-instruction-budget.sh"
TARGET="$SCRIPT"
PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
```

**Trace d'échec à champs distincts** (jamais un « KO » muet — repris tel quel de
`test-check-requirements-survival.sh:34-41`) :
```bash
ko() { # <assertion> <attendu> <obtenu>
  echo "  ✗ $1"
  echo "    assertion : $1"
  echo "    attendu   : $2"
  echo "    obtenu    : $3"
  FAIL=$((FAIL+1))
}
```

**Constructeurs de fixture jetables** (patron `mk_root()`/`w_*()`,
`test-check-requirements-survival.sh:50-79`) — à adapter en `mk_agent_file()` qui écrit un
frontmatter + body synthétiques dans un `mktemp -d`, jamais dans `plugin/` réel :
```bash
mk_root() {
  local d="$TMP/$1"
  mkdir -p "$d" || { echo "  ✗ FIXTURE — mkdir $d impossible" >&2; exit 1; }
  printf '%s' "$d"
}
w_armed() { : > "$1/.planning/.instruction-budget-armed"; }   # patron w_armed(), ligne 72-74
```

**Cas « imparsable BRUYANT » — fixture synthétique obligatoire** (RESEARCH.md Pitfall 2 : le
corpus réel n'a aucun exemple, il faut le fabriquer, patron
`test-check-requirements-survival.sh` cas 1-4 pour la forme « stdout vide/rc attendu ») : au moins
une fixture à frontmatter tronqué (un seul `---`, jamais fermé) et une à frontmatter absent, chacune
devant produire `exit 2`, jamais un compte silencieux à zéro.

**Bloc mutants, patron `cmp` exact** (repris de `test-check-divergence.sh:240-273`, à adapter sur
la comparaison de baseline plutôt que sur `check_s2`) :
```bash
MUTD="$TMP/mutants"; mkdir -p "$MUTD"
cat > "$MUTD/neutralise-comparaison.awk" <<'AWKEOF'
{
  if (!fait && index($0, "MARQUEUR_LIGNE_COMPARAISON_A_CIBLER") > 0) {
    sub(/PATRON_A_REMPLACER/, "PATRON_NEUTRALISE")
    fait = 1
  }
  print
}
AWKEOF
MUTANT="$MUTD/check-instruction-budget.mut.sh"
awk -f "$MUTD/neutralise-comparaison.awk" "$SCRIPT" > "$MUTANT"

if cmp -s "$MUTANT" "$SCRIPT"; then
  ko "MUT-1 comparaison neutralisée" "la mutation n'a RIEN changé — mutant NON OPPOSABLE" "identique"
elif ! bash -n "$MUTANT" 2>/dev/null; then
  ko "MUT-1 comparaison neutralisée" "script bash valide" "syntaxe invalide"
else
  TARGET="$MUTANT"; run "$D" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT";  run "$D" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then
    ok "MUT-1 comparaison neutralisée (cmp: script bien muté) : fixture dépassée reste verte à tort sur le mutant, rouge sur l'original"
  else
    ko "MUT-1" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"
  fi
fi
```

**Comparaison de fixtures, jamais `diff`** (avertissement explicite,
`test-check-divergence.sh:4-6` — ce poste a un `diff` proxifié mesuré menteur) : utiliser `cmp`,
`comm`, `cksum`, jamais `diff` pour toute assertion de contenu.

---

### `.planning/.instruction-budget-armed` (sentinelle versionnée)

**Analogue :** `.planning/.requirements-survival-armed` (précédent unique du dépôt, doctrine
`plugin/dev-orchestrator/AGENT.md:139-146`)

**Contrat** (déjà cité intégralement dans le script ci-dessus) : fichier vide, versionné, **lu,
jamais écrit par le gate lui-même** — posé à la main, dans le même commit que la remédiation/la
calibration (D-04, D-06 bis). Ne pas créer ce fichier dans la présente PR (checkpoint bloquant post
Phase 40) ; seul le code qui sait le *lire* est livré maintenant.

---

### `.github/workflows/ci.yml` (job `gates`, étape neuve)

**Analogue :** étapes `check-agents --strict sur chaque plugin/*/agents` /
`… plugin/*/AGENT.md` (`ci.yml:251-291`)

**Squelette d'étape** (commentaire « POURQUOI CE GATE EXISTE », découverte non vide assertée,
patron repris du corps même des étapes voisines + traitement 2/3 proposé par RESEARCH.md « Câblage
CI et catalogue ») :
```yaml
      - name: check-instruction-budget (BUDG-01/02, ADR-029 machine-enforced)
        # POURQUOI CE GATE EXISTE : aucun gate distribué ne mesurait jusqu'ici la charge
        # d'instructions ni le plafond de 250 lignes hors du module dev-orchestrator (D-05,
        # 25-CONTEXT.md). Non armé (sentinelle .planning/.instruction-budget-armed absente) :
        # avertissement audible, jamais bloquant (exit 3). Armé : tout dépassement de baseline
        # bloque (exit 1).
        run: |
          set -u
          rc=0
          out="$(bash plugin/conductor/scripts/check-instruction-budget.sh)" || rc=$?
          echo "$out"
          case "$rc" in
            0) : ;;
            3) echo "::warning::budget d'instructions non armé — avertissement, pas un blocage" ;;
            *) exit 1 ;;
          esac
```

**Précédent « découverte non vide » à respecter** (cité verbatim, `ci.yml:256-259`) :
```bash
if [ "$found" -eq 0 ]; then
  echo "::error::aucun dossier plugin/*/agents découvert — la CI refuse de rendre un verdict vide"
  exit 1
fi
```
À transposer dans le script lui-même (déjà fait ci-dessus, exit 2) plutôt que dans l'étape YAML
— cohérent avec le fait que le script porte SA propre discipline de découverte non vide (patron
`check-divergence.sh`), l'étape CI se contente de traiter le code retour.

---

### `plugin/conductor/README.md` (catalogue + correction `:95-99`)

**Analogue :** entrée `check-divergence.sh` déjà catalguée (Phase 39, citation verbatim) — gabarit
d'ajout dans la même liste « Gates machine (`check-*`) » :
```markdown
- `check-divergence.sh` — filet de détection de divergence de workstream (Phase 39) : signature
  S2 + S4(a) + S4(b) + S5 (…). Quatre codes de sortie : `0` conforme, `1` divergence,
  `2` non vérifiable, `3` silence (dépôt non partitionné). Consommé par … et par le job CI
  `gates` (preuve locale par bascule de mutation …).
```

**Correction ponctuelle requise** (D-05, citation verbatim exacte à corriger, `README.md:95-99`) :
```markdown
- `check-agents.sh` — lint de conformité native des agents (ADR-044) : frontmatter, champs requis,
  skills déclarés existants, budget de préchargement, `vf-internal`, et depuis la Phase 16 le
  contenu du champ `tools:`/`disallowedTools:` …
```
→ retirer « budget de préchargement » de cette phrase (le contrat réel de `check-agents.sh`,
vérifié `check-agents.sh:23-77`, ne compte ni lignes ni instructions) ; l'attribuer explicitement
au nouveau `check-instruction-budget.sh` dans sa propre entrée de catalogue.

**Compte de scripts à re-dériver, jamais recopier** (patron déjà présent dans le fichier,
`README.md` note du compte) : `find plugin/conductor/scripts -maxdepth 1 -type f -name '*.sh' |
wc -l` → 26 avant cette phase, 27 après l'ajout — exécuter la commande au moment de la tâche
catalogue plutôt que d'écrire « 27 » en dur.

---

### `plugin/conductor/VERSION` + `plugin/conductor/module.json` (bump minor)

**Analogue :** bump Phase 39 pour `check-divergence.sh` (nouveau script, aucune modification
incompatible d'un script existant → minor). État actuel vérifié : `VERSION` = `v1.36.0`,
`module.json.version` = `"v1.36.0"` → cible `v1.37.0` (un gate neuf = minor, cohérent avec le
précédent Phase 39 `v1.34.0` → `v1.35.0`). Les deux fichiers doivent rester synchronisés (gate
`scripts/check-version-sync.sh`, triade par module, source #6 du script).

---

### `plugin/conductor/CHANGELOG.md` (entrée neuve)

**Analogue :** entrée `[v1.35.0]` du même fichier (Phase 39, citation verbatim comme gabarit) :
```markdown
## [v1.35.0] — 2026-09-14 (Phase 39 — filet de détection de divergence de workstream, PART-04)

**Minor** (nouveau script, nouvelle suite, nouveau signal observable) :

- **`scripts/check-divergence.sh`** (neuf, 334 lignes) : … Trois signaux distincts : **S2** (…),
  **S4a/S4b** (…), **S5** (…).
```
→ entrée `[v1.37.0]` à rédiger sur ce gabarit : nom du script (neuf, N lignes), les deux métriques
publiées (lignes + instructions), le mécanisme de ratchet (sentinelle `.instruction-budget-armed`,
non armée aujourd'hui), et la mention explicite que la calibration reste un checkpoint séparé
(D-06 bis) — ne jamais laisser croire au lecteur du CHANGELOG que des baselines sont déjà gravées.

---

### `README.md` / `README.fr.md` (compteur de suites)

**Analogue :** ligne existante (citée verbatim, `README.md:140`) : « bash + `jq`, every script
covered by its suite (**77 suites** in CI — the newest … ». Une nouvelle suite
`test-check-instruction-budget.sh` porte ce compte à **78** — re-dériver par
`find plugin scripts -type f -path '*/tests/test-*.sh' | wc -l` avant d'écrire le chiffre (jamais
recopier « 78 » sans réexécution, même discipline que le compte de scripts du README conductor).
**Non gaté par un gate machine** (`check-version-sync.sh` ne compare pas ce chiffre — confirmé par
lecture du script, aucune ligne n'y fait référence) : mise à jour manuelle, hygiène documentaire,
non bloquante pour la CI.

---

### `docs/ADR.md` (note datée sous ADR-029)

**Analogues :** bloc `> **ADR-065 : numéro non attribué**` (note ajoutée APRÈS le tableau, sans
réécrire l'entrée existante, citation verbatim `docs/ADR.md` juste après le tableau des ADR
numérotées) + motif « statut amendé daté » du tableau principal, ADR-069 (`docs/ADR.md:40`,
citation verbatim) :
```markdown
| ADR-069 | 2026-08-04 | … | Validée — amendée le 2026-09-09 (risque (b) migré au niveau commit, D-10 rouverte en équipe, couverture re-mesurée) |
```

**Entrée actuelle à ne PAS réécrire** (`docs/ADR.md:52`, table « ADR héritées les plus citées »,
citation verbatim) :
```markdown
| ADR-029 | Charte densité : agents ≤ 250 lignes, skills ≤ 500, bootstrap ≤ 2000 tokens |
```

**Forme de la note à ajouter** (calquée sur le patron `ADR-065`, blockquote immédiatement après le
tableau, jamais une réécriture de la ligne d'index) :
```markdown
> **ADR-029 : enforcement machine à partir de la Phase 25 (2026-09-XX)** — le plafond de lignes et
> la charge d'instructions des agents distribués sont désormais mesurés et publiés par
> `plugin/conductor/scripts/check-instruction-budget.sh` (BUDG-01/02, ratchet par sentinelle
> `.planning/.instruction-budget-armed`, non armée avant la calibration post-Phase 40). Jusqu'ici,
> seule la suite mono-module `test-dev-orchestrator.sh` (T3/T5) enforçait le plafond de lignes, et
> aucun gate ne mesurait la charge d'instructions.
```
Ne pas combler ni renuméroter l'entrée existante (même discipline que la note `ADR-065` : « un
registre qui saute est un fait bénin ; le combler [...] casserait des références existantes »).

## Shared Patterns

### Sentinelle versionnée, lue jamais écrite par le gate (ratchet BUDG-02)
**Source :** `plugin/dev-orchestrator/scripts/check-requirements-survival.sh:74,90-127`, doctrine
`plugin/dev-orchestrator/AGENT.md:139-146`
**S'applique à :** `check-instruction-budget.sh` (lecture), `.planning/.instruction-budget-armed`
(écriture manuelle uniquement, jamais par le gate ni par un hook — régression #38 à ne pas rejouer).
```bash
SENTINEL="$ROOT/.planning/.instruction-budget-armed"
ARMED=0
[ -f "$SENTINEL" ] && ARMED=1
```

### Codes de sortie tous énumérés, aucun implicite
**Source :** `plugin/conductor/scripts/check-divergence.sh:44-52`
**S'applique à :** `check-instruction-budget.sh` (en-tête + suite de tests) et à l'étape CI
(traitement explicite de 0/1/2/3, jamais un `|| true` qui avale un code).

### Comptage de lignes robuste sans newline final
**Source :** `plugin/software-architecture/scripts/check-file-size.sh:45-48`
**S'applique à :** la métrique « lignes » (fichier entier, cohérente avec T3/T5 déjà en
production — voir Assumption A1 de RESEARCH.md) du gate neuf.
```bash
n=$(awk 'END { print NR }' "$f" 2>/dev/null || echo 0)
```

### Découverte non vide obligatoire, jamais un vert par absence de cible
**Source :** `.github/workflows/ci.yml:251-260,275-291` + `check-divergence.sh:76-92`
**S'applique à :** le script lui-même (exit 2 sur 0 fichier) et implicitement à l'étape CI (pas de
duplication de la vérification côté YAML, elle vit dans le script — cohérent avec le choix déjà
fait pour `check-divergence.sh`).

### Comparaison de fixtures/contenu, jamais `diff`
**Source :** `plugin/conductor/scripts/tests/test-check-divergence.sh:4-6`
**S'applique à :** `test-check-instruction-budget.sh` (utiliser `cmp`/`comm`/`cksum`) — `diff` est
mesuré proxifié menteur sur ce poste de développement.

### Marqueur d'exception explicite et greppable, jamais une exclusion implicite
**Source :** `plugin/software-architecture/scripts/check-file-size.sh:16-17,35-38`
(`vibeflow:allow-large-file`)
**S'applique à :** SEULEMENT si le plan retient un mécanisme d'exclusion de ligne pour le contrôle
négatif D-01 (ex. une citation contenant un marqueur hors contexte normatif) — sinon sans objet.

## Sans analogue

Fichiers sans précédent exact dans le dépôt (le planificateur doit s'appuyer sur RESEARCH.md plutôt
que sur un analogue de code) :

| Fichier | Rôle | Flux de données | Raison |
|---|---|---|---|
| `.planning/instruction-budget-baselines.tsv` | config/données (contrat versionné) | batch | Aucun fichier du dépôt ne porte aujourd'hui un contrat « une ligne par fichier, valeurs entières mesurées » — la sentinelle (`.requirements-survival-armed`) a un précédent exact, mais elle est un booléen de présence, pas un tableau de valeurs. RESEARCH.md (Assumption A2, Open Question 2) documente déjà que le format TSV est une proposition, pas un choix verrouillé — Claude's Discretion explicite au cadrage. |

Note : ce fichier n'est **pas livré dans la première PR** (D-06 bis) — son absence d'analogue est
donc sans conséquence immédiate pour le plan de cette PR ; elle redevient pertinente uniquement
pour le plan du checkpoint de calibration, après la Phase 40.

## Metadata

**Périmètre de recherche d'analogues :** `plugin/conductor/scripts/`,
`plugin/dev-orchestrator/scripts/`, `plugin/software-architecture/scripts/`,
`plugin/_internal/lib/`, `.github/workflows/ci.yml`, `docs/ADR.md`, `README.md`/`README.fr.md`,
`plugin/conductor/{README,CHANGELOG,VERSION,module.json}`.
**Fichiers lus intégralement :** `check-requirements-survival.sh` (128L), `check-divergence.sh`
(334L, + suite de test 300L extraits), `check-file-size.sh` (109L),
`test-check-requirements-survival.sh` (120L extraits), `check-agents.sh` (90L extraits, en-tête +
contrat).
**Date d'extraction des patrons :** 2026-09-15
**Vérification git-tracked :** tous les chemins cités sont sous `plugin/`, `.github/`, `docs/`,
`README*.md`, `scripts/` — code source suivi par git, aucun n'est sous `.gsd/` (répertoire non
suivi présent dans le statut git de la session) ; confirmé par `git ls-files` sur les fichiers de
test cités.

## PATTERN MAPPING COMPLETE

**Phase :** 25 - budget-d-instructions-et-tage-d-alignement-court
**Fichiers classifiés :** 10
**Analogues trouvés :** 8 / 10

### Couverture
- Fichiers avec analogue exact ou composite fort : 8
- Fichiers avec analogue de rôle (role-match) : 1 (`docs/ADR.md`, note datée)
- Fichiers sans analogue : 1 (`.planning/instruction-budget-baselines.tsv`, format de données)

### Patrons clés identifiés
- Le mécanisme de ratchet (sentinelle versionnée, lue jamais écrite par le gate, exit 3 non armé /
  exit 1 armé) a un précédent UNIQUE et EXACT dans ce dépôt : `check-requirements-survival.sh` +
  `.planning/.requirements-survival-armed` — à cloner, pas à réinventer.
- `check-divergence.sh` fournit le patron le plus récent de codes de sortie tous énumérés et de
  bash portable (BSD/GNU), et sa suite `test-check-divergence.sh` fournit le patron de mutation
  prouvée par `cmp` (QUAL-01) — deux mutants distincts (comparaison de baseline neutralisée,
  lecture de sentinelle neutralisée) sur le modèle exact de MUT-1/MUT-2.
- `check-file-size.sh` fournit l'idiome de comptage de lignes robuste (`awk 'END{print NR}'`,
  jamais `wc -l` nu) déjà en production pour la même métrique (plafond 250, T3/T5) — cohérence à
  préserver entre le nouveau gate et l'enforcement mono-module existant.
- Le fichier de baselines (TSV ou autre) est la seule pièce sans précédent structurel dans le
  dépôt — reste Claude's Discretion, et de toute façon hors de la première PR (D-06 bis).

### Fichier créé
`.planning/phases/VFDO-25-budget-d-instructions-et-tage-d-alignement-court/25-PATTERNS.md`

### Prêt pour la planification
La carte des patrons est complète. Le planificateur peut référencer les analogues et extraits
ci-dessus dans les actions des PLAN.md, en gardant la séparation stricte posée par D-06 bis : tout
ce qui précède la calibration (script, suite, câblage CI non armé, catalogue, README, note
ADR-029) dans une première PR ; le fichier de baselines et la sentinelle armée dans une seconde PR,
après la clôture de la Phase 40.
