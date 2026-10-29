# Phase 60: Gate architecture avant découpage et validation des phases proposées - Pattern Map

**Mapped:** 2026-10-29
**Files analyzed:** 22 (nouveaux ou modifiés, regroupés ci-dessous)
**Analogs found:** 22 / 22 (tous suivis par git, vérifiés par `git ls-files` ; aucun miroir `.claude/` cité)

Tous les chemins sont relatifs à la racine du worktree. Les lignes citées sont celles du worktree au 2026-10-29.

## File Classification

| Fichier nouveau / modifié | Rôle | Data flow | Analogue le plus proche | Qualité |
|---|---|---|---|---|
| `plugin/conductor/scripts/check-phase-validation.sh` | gate (script) | transform, lecture seule | `plugin/product-team-bundle/scripts/check-prd.sh` | exact |
| `plugin/conductor/scripts/check-architecture.sh` (nom libre) | gate (script) | transform, lecture seule | `plugin/product-team-bundle/scripts/check-prd.sh` (volet BRIEF, l. 213-254) | exact |
| `plugin/conductor/scripts/tests/test-check-phase-validation.sh` | test (suite à mutants) | fixtures générées à l'exécution | `plugin/product-team-bundle/scripts/tests/test-check-prd.sh` | exact |
| `plugin/conductor/scripts/tests/test-check-architecture.sh` | test (suite à mutants) | idem | `.../test-check-prd.sh` | exact |
| `plugin/planning-core/references/templates/product/ARCHITECTURE.template.md` | gabarit | document | `.../templates/product/PROJECT.template.md` | role-match |
| `plugin/product-team-bundle/agents/vf-product-architect.md` | agent (worker interne) | request-response | `plugin/product-team-bundle/agents/vf-product-pm.md` | exact |
| `plugin/product-team-bundle/agents/vf-product-manager.md` (allowlist + livrable) | agent (manager) | orchestration | lui-même (ligne 4) + `vf-product-pm` | exact |
| `plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh` (AGENTS, CORPUS) | test | composition | lui-même (l. 39-40) | exact |
| `plugin/dev-orchestrator/agents/vf-coder.md` (porte « phase proposée ») | agent | refus avant brique | lui-même, `§Contrôle de profondeur` (l. 28-36) | role-match |
| `plugin/dev-orchestrator/skills/vf-auto/SKILL.md` (« Étape 0 bis ») | skill | refus avant boucle | lui-même, `### Taille` (l. 30-50) | role-match |
| `plugin/dev-orchestrator/AGENT.md:33` (ligne-pointeur prolongée) | agent (head) | pointeur à la demande | lui-même, l. 31-33 | exact |
| `plugin/dev-orchestrator/references/product-routing.md` (+ `## 5.`) | référence | routage à la demande | lui-même, §1 à §4 | exact |
| `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (cas T45) | test (ablation) | clauses textuelles | cas T44, l. 7318-7451 | exact |
| `plugin/conductor/references/workstream-planning-consumers.md` (+1 ligne si besoin) | doc de recensement | registre | lignes 74-81 (catégorie a2) | exact |
| `plugin/{conductor,planning-core,product-team-bundle,dev-orchestrator}/{module.json,VERSION,CHANGELOG.md,README.md}` | config/doc | bump | Phase 59 (bundle) et en-tête `plugin/conductor/CHANGELOG.md` | exact |
| `.planning/instruction-budget-baselines.tsv` (1 ligne neuve) | config | baseline | lignes 58-62 (product-team-bundle) | exact |
| `manual/fr/**`, `manual/en/**` (agents, concepts, poste) | doc | manuel | pages citées dans RESEARCH § Livraison d'un agent | role-match |
| `ROADMAP.md` du compartiment (champ `**Validation:**`) | donnée de planning | marqueur | champs gras existants (`**Sources:**`, `**Goal:**`) | role-match |
| ledger (STATE, ROADMAP, REQUIREMENTS) | doc | mise à jour manuelle | `59-08-SUMMARY.md` | exact |

## Pattern Assignments

### `plugin/conductor/scripts/check-phase-validation.sh` (gate, lecture seule)

**Analogue :** `plugin/product-team-bundle/scripts/check-prd.sh` (336 lignes).

**En-tête, contrat de codes, sortie (l. 1-59)** : copier la structure. Rôle « CONSTATER, jamais corriger », entrées non fiables jamais réimprimées, codes énumérés, `Le code 2 n'est jamais émis`. Transposition à écrire :

```bash
#   0 = phase validée (marqueur validated, ou marqueur absent)
#   1 = phase proposée
#   3 = INDÉTERMINÉ : phase introuvable, ROADMAP absent, valeur de marqueur inconnue. Jamais un vert à vide.
#   5 = entrée illisible, BRUYANTE (lien symbolique, non régulier, illisible, taille non numérique, > 1048576 octets)
#   64 = erreur d'usage
#   Le code 2 n'est jamais émis : il est réservé au blocage délibéré du harness.
# Entre plusieurs constats, l'ordre 5 > 1 > 3 > 0 décide
```

**Préambule et parseur d'arguments (l. 60-91)** :

```bash
set -uo pipefail
export LC_ALL=C
PRD_MAX_OCTETS=1048576
NL=$'\n'
BOM=$(printf '\357\273\277')
usage_err() { printf '[check-prd] %s\n' "$1" >&2; exit 64; }
say() { printf '[check-prd] %s\n' "$*"; }
while [ "$#" -gt 0 ]; do
  case "$1" in
    --requirements)
      [ "$#" -ge 2 ] && [ -n "$2" ] || usage_err "--requirements nécessite une valeur"
      REQ=$2; HAS_REQ=1; shift 2 ;;
    --requirements=*)
      REQ=${1#--requirements=}; [ -n "$REQ" ] || usage_err "--requirements nécessite une valeur"
      HAS_REQ=1; shift ;;
    -h|--help) awk '/^set -uo/{exit} /^# /{sub(/^# /,""); print}' "$0"; exit 0 ;;
    *) usage_err "argument inconnu (usage : ...)" ;;
  esac
done
```
Adapter : options `--ws <nom>` (ou `--roadmap <f>`) et `--phase <N>`, formes `--x v` et `--x=v`, préfixe `[check-phase-validation]`. Pour le nom de compartiment, valider par `vf_ws_name_valid` et résoudre par `vf_ws_dir_resolve` après avoir sourcé `workstream-policy.sh` comme `plugin/conductor/scripts/split-planning.sh:138-146`. Ne jamais retomber sur le pointeur actif ni sur `GSD_WORKSTREAM` (DLWS-04). Valider `--phase` par regex numérique avant tout usage (V5).

**Bibliothèque awk (l. 93-141)** : reprendre `trim`, `strip_comments` (commentaires HTML multi-ligne, variable `incom`) et la gestion BOM/fences. Retirer `fold`, `nchars` et `isfiller` s'ils ne servent pas.

**Garde d'entrée AVANT lecture (l. 264-280)** : à copier tel quel.

```bash
bump() { # <code> : ordre 5 > 1 > 3 > 0
  case "$1" in
    5) WORST=5 ;;
    1) if [ "$WORST" -ne 5 ]; then WORST=1; fi ;;
    3) if [ "$WORST" -eq 0 ]; then WORST=3; fi ;;
  esac
}
guard() { # <entree> <chemin>
  local name=$1 f=$2 size
  if [ ! -e "$f" ] && [ ! -L "$f" ]; then indetermine "$name" "cible absente"; return 3; fi
  if [ -L "$f" ]; then illisible "$name" "lien symbolique"; return 5; fi
  if [ ! -f "$f" ]; then illisible "$name" "fichier non regulier"; return 5; fi
  if [ ! -r "$f" ]; then illisible "$name" "fichier illisible"; return 5; fi
  size=$(wc -c < "$f" 2>/dev/null | tr -d ' \t')
  case "$size" in ''|*[!0-9]*) illisible "$name" "taille non numerique"; return 5 ;; esac
  if [ "$size" -gt "$PRD_MAX_OCTETS" ]; then illisible "$name" "au-dela de la borne de taille"; return 5; fi
  return 0
}
```

**Analyse awk, dernière ligne de compteurs, ligne `BILAN` (l. 282-292, 294-335)** :

```bash
analyse() { OUT_TXT=$(tr -d '\r' < "$1" | awk -v bom="$BOM" ... "$AWK_LIB$NL$2"); }
...
say "BILAN exigences=${NREQ} ... code=${WORST}"
```
Corps awk neuf, à partir du prototype mesuré (RESEARCH § Recommandation) : repérer la section `### Phase N` (tag de titre toléré, deux-points exigé pour ne pas compter `## Phase 41 — ...` en double), puis lire la ligne `**Validation:**` à l'intérieur de la section. Valeurs ASCII fermées `proposed` et `validated` (jeton replié casse/accents, suffixe `(dev, AAAA-MM-JJ)` toléré). Absent = 0, `proposed` = 1, valeur inconnue = 3, phase absente du ROADMAP = 3 (jamais 0). Ne jamais réimprimer le contenu du ROADMAP : imprimer seulement le numéro de phase (déjà validé par regex) et des étiquettes fixes.

**Pièges propres à ce script :**
- bash 3.2 et mawk : pas de `mapfile`, tableaux associatifs, `${v,,}`, `sed -i`, `grep -P`, intervalles `{n,m}` en awk, `match(s, re, arr)`. Mesurer en `awk`, jamais `grep | wc -l`.
- Lab partitionné sans `--ws` : code 3 ou 64 à trancher (O-5) et à couvrir par mutant.
- Le lint `check-planning-consumers-registered.sh` retient toute ligne (commentaires compris) qui porte `.planning/workstreams`, ou `.planning/` suivi de `STATE.md`, `ROADMAP.md` ou `REQUIREMENTS.md`. Passer le ROADMAP par `--roadmap <f>`, ou recenser le script (catégorie a2, voir plus bas).

---

### `plugin/conductor/scripts/check-architecture.sh` (gate, lecture seule)

**Analogue :** `check-prd.sh`, volet BRIEF (`AWK_BRIEF`, l. 213-254) pour « rubriques minimales avec au moins une ligne de corps ».

**Pattern de rubriques (l. 215-253), à transposer** :

```awk
{
  line = $0
  if (NR == 1 && substr(line, 1, 3) == bom) line = substr(line, 4)
  if (!infence) line = strip_comments(line)
  t = trim(line)
  f3 = substr(t, 1, 3)
  if (infence) { if (f3 == fch) infence = 0; next }
  if (f3 == "```" || f3 == "~~~") { infence = 1; fch = f3; next }
  if (line ~ /^#+[ \t]/) {
    lvl = 0
    while (substr(line, lvl + 1, 1) == "#") lvl++
    lab = tolower(substr(line, lvl + 1)); sub(/^[^a-z]+/, "", lab)
    name = ""
    if (index(lab, "probl") == 1) name = "probleme"
    ...
    if (cur == "" || lvl <= curlvl) { cur = ""; if (name != "") { cur = name; curlvl = lvl; seen[name] = 1 } }
    next
  }
  if (cur == "" || t == "") next
  if (substr(t, 1, 1) == "[") next
  if (hasword(tolower(t), "tbd") || hasword(tolower(t), "todo")) next
  if (t !~ /[^-*_=|#> \t]/) next
  body[cur]++
}
END {
  n = split("probleme utilisateurs valeur contraintes hors_perimetre", names, " ")
  for (i = 1; i <= n; i++) { k = names[i]
    if (!(k in seen)) { m++; printf "[check-prd] ELIMINATOIRE rubrique BRIEF %s : absente\n", k }
    else if (body[k] + 0 == 0) { m++; printf "[check-prd] ELIMINATOIRE rubrique BRIEF %s : vide\n", k } }
  printf "@ %d\n", m + 0
}
```

Adaptations :
- Le script embarque les noms de rubrique (il ne lit jamais le gabarit à l'exécution) ; les fixer depuis `ARCHITECTURE.template.md`.
- Ajouter la lecture du statut du fichier (`**Statut :** proposée | validée (poste, date)`), même grammaire de valeur que le marqueur de phase (O-2).
- Mapping des codes (O-3, à figer avant la suite) : absente, proposée, rubrique manquante = 1 avec étiquettes distinctes ; 3 pour l'indéterminé structurel (fence non fermée, statut illisible) ; 5 et 64 inchangés.
- Le gate ne lit que `.planning/ARCHITECTURE.md` (Pitfall 7 : ne pas confondre avec `.planning/codebase/ARCHITECTURE.md` ni `docs/ARCHITECTURE.md`). Chemin passé en argument (`--architecture <f>`), aucun littéral.
- Guard, `bump`, `say`, ligne `BILAN`, interdiction du code 2 : identiques à `check-prd.sh`.

---

### `plugin/conductor/scripts/tests/test-check-phase-validation.sh` et `test-check-architecture.sh` (suites à mutants)

**Analogue :** `plugin/product-team-bundle/scripts/tests/test-check-prd.sh` (453 lignes).

**Harnais (l. 16-55)** : à copier.

```bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$(cd "$HERE/.." && pwd)/check-prd.sh"   # -> check-phase-validation.sh / check-architecture.sh
TARGET="$SCRIPT"
PASS=0; FAIL=0; SKIPPED=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }
skip() { echo "  ⊘ SKIP $1"; SKIPPED=$((SKIPPED+1)); }
TMP="$(mktemp -d)"
trap 'chmod -R u+rwx "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT
FX="$TMP/fx"; mkdir -p "$FX"
: > "$TMP/rcs"; : > "$TMP/fxlist"; : > "$TMP/fxsum"
mkdir "$TMP/cwd"; cd "$TMP/cwd" || exit 1
run() {
  OUT="$(perl -e 'alarm 10; exec @ARGV' bash "$TARGET" "$@" 2>"$TMP/err")"; RC=$?
  ERR="$(cat "$TMP/err")"; echo "$RC" >> "$TMP/rcs"
}
case_() { if "$2"; then ok "$1"; else ko "$1 — $LASTMSG"; fi; }
```
Fixtures écrites à l'exécution par `w()` (l. 36-43), CRLF et BOM par `printf`, aucun dossier `fixtures/` versionné (P59-PL-07). Alarme généreuse (le plafond d'horloge de 60 s a sauté sous charge, Pitfall 11).

**Cas à reprendre** : TRACE-1..4 (vert / rouge / indéterminé / usage, l. 66-100), ABSENT, LIEN, FIFO, DOSSIER, GROS, ILLISIBLE, EXEC (chemin hostile `a b'c $(touch pwned).md` inerte, l. 340-345), RO (lecture seule par `cksum` et `find`, l. 348-358), CODES (ensemble observé exactement `{0,1,3,5,64}`, l. 359-365).

**Helper `mutant()` (l. 373-403)** : à copier tel quel (altération d'une seule ligne, `cmp -s`, `bash -n`, une seule ligne changée, sonde rouge sur mutant et verte sur l'original).

```bash
mutant CPRD-MUT-3 'if [ "$NREQ" -eq 0 ]; then' '[ "$NREQ" -eq 0 ]' 'false' probe_trace3 \
  "INDÉTERMINÉ : zéro exigence rendu 0"
mutant CPRD-MUT-4 'if [ -L "$f" ]; then illisible' '[ -L "$f" ]' 'false' probe_lien \
  "BRUYANT : refus du lien symbolique retiré"
mutant CPRD-MUT-7 '"$size" -gt "$PRD_MAX_OCTETS"' '"$PRD_MAX_OCTETS"' '99999999999' probe_gros \
  "BRUYANT : borne de taille retirée"
```
Mutants à prévoir pour la phase : phase absente rendue 0 (anti-vert-à-vide), valeur de marqueur inconnue rendue 0, marqueur `proposed` rendu 0, fence ignorée, tag de titre non toléré, double comptage `## Phase 41 —`, validation d'`ARCHITECTURE.md` sans statut, une rubrique retirée de la liste.

**Preuve « lecteurs GSD inchangés » (ARCG-01)** : cas `CPV-GSD-*` qui compare des champs (`phase_name`, `goal`, `phase_count`), pas du texte brut, avec `skip` si `node` ou `~/.claude/gsd-core/bin/gsd-tools.cjs` est absent, sur le modèle de `PTB-GSD` (`test-product-team-bundle.sh:347,431-435`). Témoin positif d'abord pour toute sonde.

**Trailers de commit** : `Gate-Touche: <chemin> — <raison ≥ 10 caractères>` (un trailer par chemin, G-2, `check-gate-touche.sh` doit rendre rc 0), et `Ajout-Retrait: <chemin> — <retrait | aucun : justification> — défaillance : <≥ 10 caractères + date ISO ou SHA>` (SOBR-05, trois segments). Modèle réel, commit `96a64378` :

```
Ajout-Retrait: plugin/product-team-bundle/scripts/check-prd.sh — aucun : capacité de jalon inscrite (SEED-001, ROADMAP 59) — défaillance : sans contrôle déterministe, l'éliminatoire du juge produit serait un vert auto-déclaré (motif de P59-D-06, arbitrage du 2026-10-27)
```

---

### `plugin/planning-core/references/templates/product/ARCHITECTURE.template.md` (gabarit)

**Analogue :** `PROJECT.template.md` (même dossier). Conventions à reprendre : titre `# [Nom du produit]`, bloc `>` d'intention qui dit qui l'instancie, sections `##` aux libellés français, placeholders entre crochets `[...]` (le gate ignore les lignes qui commencent par `[`, donc un gabarit brut rend rouge), tableau `| ID | Décision | Pourquoi | Statut |` pour les décisions.

```markdown
# [Nom du produit] ([CODE])

> Charte produit stable, instanciée par `vf-product-pm` depuis `.planning/BRIEF.md` : ...

## Décisions clés
> Décisions courantes du produit. ...
| ID | Décision | Pourquoi | Statut |
|----|----------|----------|--------|
```
À ajouter : ligne `**Statut :** proposée` (jamais `validée` à l'instanciation), rubriques minimales fixées par le planificateur et reprises à l'identique dans `check-architecture.sh`, mention explicite des trois `ARCHITECTURE.md` homonymes (Pitfall 7), aucun identifiant en gras susceptible d'être lu comme exigence. Fichier neuf seulement, plus bump et changelog de `planning-core` (collision de version possible avec la Phase 45, O-7).

---

### `plugin/product-team-bundle/agents/vf-product-architect.md` (worker interne)

**Analogue :** `plugin/product-team-bundle/agents/vf-product-pm.md` (78 lignes).

**Frontmatter (l. 1-8)** :

```yaml
---
name: vf-product-pm
description: "Worker interne — instancie le PRD (PROJECT.md + REQUIREMENTS.md) depuis le gabarit product de planning-core et le BRIEF, ... ; dispatché uniquement par vf-product-manager, pas en usage direct."
tools: Read, Write, Edit, Glob, Grep
model: sonnet
effort: medium
memory: project
vf-internal: true
---
```
Adapter : `name: vf-product-architect`, description scalaire guillemetée mono-ligne sans `"` interne et contenant « Worker interne » (invariant I1, sensible à la casse), ajouter `skills:` avec `software-architecture` (supprime l'avertissement « aucun skill câblé »). Pas d'outil `Agent` : un worker n'a pas d'allowlist (I6 ne s'applique qu'aux managers).

**Corps (l. 11-40)** : reprendre le découpage `## Entrée` (chemins résolus UNE fois par le manager et transmis, jamais déduits du pointeur actif), `## Gabarit` (cascade « premier dossier existant » : `./.claude/skills/planning-core/references/templates/product/`, `$HOME/.claude/skills/planning-core/...`, `${CLAUDE_PLUGIN_ROOT}/planning-core/...`, « aucun trouvé : statut `blocked`, tu n'improvises pas »), `## Règles de forme`. Phrase de rôle à adapter : « Tu **rédiges, tu ne valides pas** ». Clause de non-auto-validation à porter (le worker écrit `**Statut :** proposée`, jamais `validée`), à prouver par une clause à mutants dans `test-product-team-bundle.sh`. Pour `gsd-map-codebase` : défaut (a) de O-4, l'architecte lit `.planning/codebase/*.md` s'ils existent, sinon un finding demande la cartographie à un poste dev (aucun `Agent`, aucun commit). `gsd-graphify` seulement sous `graphify.enabled` (D-08). Plafond 250 lignes ; mesurer les instructions par `check-instruction-budget.sh`, pas à la main.

**Budget** : ligne de baseline neuve dans `.planning/instruction-budget-baselines.tsv`, format `chemin<TAB>lignes<TAB>instructions` (l. 58-62), placée en ordre `LC_ALL=C` entre `plugin/product-team-bundle/agents/vf-product-analyst.md` et `.../vf-product-manager.md` (ordre alphabétique de `agents/`). Valeurs lues dans la sortie du script. Sans cette ligne : rc 2 `SANS-BASELINE`. Un seul plan est propriétaire du fichier.

---

### `plugin/product-team-bundle/agents/vf-product-manager.md` (allowlist et livrable)

**Analogue :** lui-même.

**Allowlist actuelle (l. 4)** :
```yaml
tools: Read, Write, Bash, Glob, Grep, Skill, AskUserQuestion, SendMessage, Agent(vf-product-analyst, vf-product-pm, prd-gate)
```
Devient `Agent(vf-product-analyst, vf-product-pm, vf-product-architect, prd-gate)` **dans le même commit** que l'agent (invariants I2 et monde fermé `--resolve-agents=strict`, leçon P59-PL-14). Le manager est à 24/24 instructions et 152 lignes : toute phrase ajoutée se mesure (la clause « jamais par toi » a coûté 1 instruction ; reformuler « à son poste »). Le livrable `architecture` s'ajoute à `livrables ∈ {brief, prd, brief+prd}` et à la table de dispatch existante. Ne jamais valider à la place de l'humain (Iron Law 3 existante : le manager propose).

---

### `plugin/product-team-bundle/scripts/tests/test-product-team-bundle.sh`

**Analogue :** lui-même, l. 39-40 :

```bash
AGENTS="vf-product-manager vf-product-analyst vf-product-pm prd-gate"
CORPUS="AGENT.md agents/vf-product-manager.md agents/vf-product-analyst.md agents/vf-product-pm.md agents/prd-gate.md"
```
Étendre les deux listes avec `vf-product-architect` et `agents/vf-product-architect.md`, puis ajouter une clause à mutants par ancre (« ne la valide jamais lui-même », `Worker interne`, allowlist du manager).

---

### `plugin/dev-orchestrator/agents/vf-coder.md` (porte « phase proposée »)

**Analogue :** lui-même. Insérer **avant** `## Le cycle (délégation)` (donc avant les étapes 1 `gsd-plan-phase`, l. 42, et 2 `gsd-execute-phase`, l. 45). Le style « contrôle avant action » existe déjà dans `**Contrôle de profondeur, avant toute action**` (l. 28-36) ; le style de rapport est « rends le retour « bloqué : profondeur » (§Retour), mandat intact ».

Texte mesuré à 0 instruction (RESEARCH § Code Examples) :

```markdown
## Porte « phase proposée » (avant 1 et 2)

Avant `gsd-plan-phase` puis avant `gsd-execute-phase`, constate le marqueur de la phase : `"$S"/check-phase-validation.sh --ws <nom> --phase <N>`
(`$S` résolu comme en `mission-flow.md` §Résolution des scripts). Code 0 : phase validée, poursuis. Code 1 : phase proposée, rends
`"statut": "blocked"` avec un finding `action: ask-user`, aucune brique lancée. Codes 3, 5 et 64 : rends `human_needed`.
```
Contraintes : `vf-coder.md` est à 22/23 instructions (marge 1) ; `MARKER_RE='jamais|toujours|ne .* pas|doit|must|never|always|interdit|obligatoire'` s'applique en sous-chaîne à toute ligne de corps (« une phase … passe » matche `ne .* pas`), sauf blocs fenced et titres ; aucune puce sous un titre contenant `règles|garde-fous|iron law|anti-pattern|lignes rouges|discipline`. Re-mesurer par `check-instruction-budget.sh` après chaque édition. Le mandat sans numéro d'étape ROADMAP (tâche courte, spec du crafter) n'appelle pas le script. Le `--ws` suit la section `## Compartiment de planning — passer --ws, ne jamais présumer` du même fichier.

---

### `plugin/dev-orchestrator/skills/vf-auto/SKILL.md` (« Étape 0 bis »)

**Analogue :** lui-même. Insérer une section « Étape 0 bis » avant `## Moteur direct (mission courte)` (l. 54), après la détermination de `N = étapes restantes ciblées (gsd-tools roadmap analyze …)` (l. 38). Même appel de gate et même mapping de codes que `vf-coder`. Limite à écrire : une phase ajoutée pendant la boucle du moteur n'est pas interceptée (advisory). Pas de ratchet sur les `SKILL.md` (plafond 500 lignes, 79 aujourd'hui) ; aucun skill neuf (D-10).

---

### `plugin/dev-orchestrator/AGENT.md:33` (ligne-pointeur prolongée)

**Analogue :** lui-même, l. 31-33 (`## Garde-fou premier usage (first-use)`).

Ligne actuelle :
```markdown
> **Poste product** — la ligne « Poste : X » du démarrage de session, confirmée par `vf-role.sh get`, décide de la porte : au poste `product`, ou devant une intention produit (brief, PRD, critères d'acceptation), lire d'abord `.claude/agents/dev-orchestrator-references/product-routing.md`, qui prime sur la proposition d'init ci-dessous.
```
Prolonger **cette ligne**, sans ajouter de ligne (AGENT.md est à 33/33), par la variante mesurée : « … Devant une intention de découpage (ajouter, insérer ou découper une étape, ouvrir une milestone), lire aussi sa §5 : gate architecture, phases proposées. ». Le test `T44 (a)` impose que `product-routing.md` figure dans la zone `^## Garde-fou premier usage` avant `FIRST-02`.

---

### `plugin/dev-orchestrator/references/product-routing.md` (+ `## 5.`)

**Analogue :** lui-même (61 lignes). Structure : blockquote d'intention, séparateurs `---`, sections numérotées `## N. Titre`, puces courtes, même sémantique d'override que le §2 : « Sur une **demande explicite réitérée**, le head exécute le routage normal de la carte, avec une phrase qui rappelle le poste. Aucun refus mécanique : l'humain tranche. »

Lecture du poste à réutiliser sans la recopier : `"$S"/vf-role.sh get`, avec `$S` par la cascade de `mission-flow.md` §Résolution des scripts ; codes 1, 5 et 64 jamais repliés sur `solo`. La §5 ajoute un préalable au découpage : poste `product` ou `dev` **et** `.planning/BRIEF.md` présent (P60-H-01), alors appeler le gate architecture ; rc 0 poursuivre, rc 1 une phrase de refus et halte, autres codes `human_needed`, override par demande réitérée tracée au rapport. Au poste `solo`, rien ne change (D-02). **Ajouter la §5 à la fin** : `T44` pince §1 à §4 par les bornes `^## 1[.]` à `^## 4[.]`, une `## 5.` finale n'en touche aucune. La phrase du §4 « Elle ne décide pas du découpage d'une mission, qui reste celui de la règle d'échelle de `head-governance.md` §1 » est à reformuler pour rester cohérente.

---

### `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (cas T45)

**Analogue :** cas T44, l. 7318-7451, et helpers `t414_zone` (l. 7026), `t414_missing` (l. 7036), `t414_order` (l. 7045), `t414_ablate` (l. 7059), `t414_mutant` (l. 7089), `t44_forbidden` (l. 7350).

Déclarer les zones et littéraux en tête (modèle l. 7322-7338) :
```bash
T44_AG_ZS='^## Garde-fou premier usage'
T44_AG_ZE='^## Carte d.intention'
T44_REF="$REFS_DIR/product-routing.md"
T44_P2_LIT=('ne lance aucune équipe' 'oriente vers `/vf-product`' ...)
T44_P2_INTERDIT=('Refus systématique' 'sans rien dire' 'lance l'"'"'équipe normale')
```
Fonction de contrôle qui rend rc 1 avec une trace (modèle `t44_sem_check`, l. 7339-7349), puis une ablation par clause :
```bash
for t44_a in "${T44_P2_LIT[@]}"; do
  t44_k=$((t44_k+1))
  t414_ablate "$T44_REF" "$T414_TMP/t44-p2-$t44_k.md" "$t44_a" "$T44_P2_ZS" "$T44_P2_ZE"
  t414_mutant "T44 mutant §2 : ... privé de « $t44_a » ..." t44_sem_check "$T44_REF" "$T414_TMP/t44-p2-$t44_k.md"
done
```
Plus un mutant d'inversion de sens (`sed -e 's/ne lance aucune équipe/lance l'"'"'équipe normale sans rien dire/'`, l. 7388) et un mutant d'ordre (`t414_move_before`, l. 7399). `t414_mutant` exige un témoin positif (le contrôle accepte le fichier réel) puis rend « DISCRIMINANT » quand le mutant est refusé. Cas T45 à couvrir : `vf-coder` (appel avant `gsd-plan-phase` et `gsd-execute-phase`, codes traités, `blocked` + `ask-user`, mandat sans N non gardé), `vf-auto` (Étape 0 bis avant « Moteur direct »), pointeur `AGENT.md:33` prolongé, §5 (condition poste + `BRIEF.md`, solo inchangé, override réitéré), mutant « BRIEF absent -> gate non appelé » (Pitfall 6). Variables `*TMP*` préfixées `T45`.

---

### `plugin/conductor/references/workstream-planning-consumers.md` (si `check-phase-validation.sh` résout un compartiment)

**Analogue :** lignes 74-81, catégorie `a2`.

```markdown
| plugin/conductor/scripts/split-planning.sh | a2 | exempté — cible le seul sujet que le moteur vient de créer, ... ; Phase 41.2 |
| plugin/conductor/scripts/check-workstream-pointer.sh | a2 | exempté — résout le compartiment ACTIF, jamais un gate CI multi-compartiments |
```
Ajouter une ligne au même format : « exempté — résout le compartiment NOMMÉ par `--ws` ». Le registre est un sur-ensemble tolérant. Si le script reçoit `--roadmap <f>` sans aucun littéral de chemin de planning, aucune ligne n'est nécessaire (cas de `check-prd.sh`, P59-PL-04).

---

### Bumps de modules, compteurs, manuel, porte de phase

**Analogue :** Phase 59 (`59-08-SUMMARY.md`, `59-PLANNING-REGISTRE.md`).
- Minor pour `conductor` (v1.50.2 vers v1.51.0), `planning-core` (v2.9.0 vers v2.10.0), `dev-orchestrator` (v2.29.0), `product-team-bundle` (v1.0.0) ; chaque bump touche `module.json` `version`, `VERSION`, `CHANGELOG.md` (en-tête `## [vX.Y.Z] — date (résumé)`, style de `plugin/conductor/CHANGELOG.md:3`) et `README.md` si l'en-tête `**Version**` existe. Les versions racine ne bougent pas (release du manager, D-14).
- `plugin/conductor/README.md` : `## Scripts (38)` devient 40 ; compteur « N suites » des deux README racine égal à `find plugin scripts -type f -path '*/tests/test-*.sh'` (+2). Tout recompter par `find | awk 'END{print NR}'` dans le plan de porte, ne jamais figer un nombre dans un plan (`check-version-sync.sh`).
- Manuel (D-12) : comptes d'agents (36 vers 37, sonnet 24 vers 25) recomptés par la commande de `manual/fr/06-reference/agents.md`, pas à la main ; pages listées dans RESEARCH § Livraison d'un agent, FR et EN ; `bash manual/.tools/check-manual.sh` (C0 à C6, pages de 300 lignes au plus, 3 H2 au plus, aucune version en dur).
- Porte (D-13) : `replay-ci-jobs.sh --job gates --list` d'abord, puis le rejeu depuis `ci.yml` (jamais une liste recopiée), suites touchées une à une (au plus 2 workers simultanés), `check-gate-touche.sh` rc 0, ledger à la main, arrêt avant PR, merge, tag, release.

## Shared Patterns

### Forme de gate (codes, lecture seule, non-réimpression)
**Source :** `plugin/product-team-bundle/scripts/check-prd.sh:41-50,60-70,264-280`
**À appliquer à :** `check-phase-validation.sh`, `check-architecture.sh`. Codes `0/1/3/5/64`, jamais 2, ordre 5 > 1 > 3 > 0, refus AVANT lecture (lien symbolique, non régulier, illisible, taille non numérique, > 1048576 octets), awk pur sans évaluation, contenu des entrées jamais réimprimé, ligne `BILAN ... code=<rc>`, bash 3.2 et mawk.

### Preuve qu'un gate sait rougir (QUAL-01)
**Source :** `plugin/product-team-bundle/scripts/tests/test-check-prd.sh:373-403` (helper `mutant()`), `:359-365` (`CPRD-CODES`)
**À appliquer à :** les deux suites de gates. Témoin positif avant toute conclusion, mutant « identique à l'original » = NON OPPOSABLE = suite rouge.

### Preuve textuelle par ablation (câblage de doctrine)
**Source :** `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh:7026-7110` (helpers), `:7318-7451` (T44)
**À appliquer à :** cas T45 (vf-coder, vf-auto, AGENT.md:33, product-routing §5) et clauses du bundle produit.

### Lecture du poste
**Source :** `plugin/conductor/scripts/vf-role.sh:11-15` (codes) et `plugin/dev-orchestrator/references/product-routing.md:16-20`
**À appliquer à :** §5 de `product-routing.md`, `vf-coder`, `vf-auto`. Toujours `"$S"/vf-role.sh get`, jamais le fichier de poste lu à la main ; codes 1/5/64 jamais repliés sur `solo`. Le gate de phase ne lit jamais le poste (H-04).

### Résolution de `$S` et de compartiment
**Source :** `plugin/dev-orchestrator/references/mission-flow.md:10-30` (cascade `$S`, « le lab courant PRIME ») ; `plugin/planning-core/scripts/workstream-policy.sh:240-262` (`vf_ws_dir_resolve`, rc 0/1/2) ; `plugin/conductor/scripts/split-planning.sh:138-146` (sourcer la politique).
**À appliquer à :** les deux scripts et leurs appelants. Jamais de nom de compartiment en dur, jamais le pointeur actif ni `GSD_WORKSTREAM` pour la décision du gate (DLWS-04).

### Budget d'instructions (zéro hausse)
**Source :** `plugin/conductor/scripts/check-instruction-budget.sh:133` (`MARKER_RE`), `.planning/instruction-budget-baselines.tsv`
**À appliquer à :** toute édition de `vf-coder.md`, `vf-product-manager.md`, `AGENT.md`, `vf-product-architect.md`. Mesurer avant et après (rc 0 attendu), jamais estimer. `vf-dev-manager.md` n'est pas touché (250 lignes, 46/46). Aucune valeur existante de baseline n'augmente (G-1).

### Trailers de commit (G-1, G-2, SOBR-05)
**Source :** commit `96a64378` (`Ajout-Retrait`), `scripts/check-gate-touche.sh:24-35` (surface).
**À appliquer à :** tout commit qui ajoute un `check-*.sh` (trois segments) ou touche un gate de `plugin/conductor/scripts/` ou sa suite (`Gate-Touche: <chemin> — <raison>`). Commits en français, jamais « arbitrage Samuel » nu ; identifiants préfixés `P60-PL-xx`.

## No Analog Found

| Fichier | Rôle | Data flow | Raison |
|---|---|---|---|
| Écriture du marqueur `**Validation:** proposed` et verbe de validation (O-1) | script d'écriture (option b) | écriture d'une ligne | Aucun script de l'équipe n'écrit un champ de ROADMAP : le moteur ne pose pas de champ à `phase add`, les gates sont en lecture seule. Planificateur : prendre `vf-role.sh` pour la lecture du poste, `workstream-policy.sh` pour la résolution, et tracer le choix `P60-PL-xx`. S'il est livré hors `check-*`, il n'entre pas dans la surface G-2. |
| Assemblage de `gsd-map-codebase` par un worker (O-4) | worker | sous-agents parallèles | Aucun worker du bundle n'invoque un skill qui lance des agents ; défaut recommandé (a) : lecture seule de `.planning/codebase/*.md`. Sonde de profondeur si (b) : `plugin/dev-orchestrator/agents/vf-coder.md:28-36`. |

## Metadata

**Analog search scope :** `plugin/product-team-bundle/`, `plugin/conductor/scripts/`, `plugin/conductor/references/`, `plugin/dev-orchestrator/{agents,skills,references,scripts/tests}/`, `plugin/planning-core/{references/templates/product,scripts}/`, `.planning/instruction-budget-baselines.tsv`, `manual/`.
**Files scanned :** une trentaine, dont 6 lus intégralement ou par blocs (`check-prd.sh`, `test-check-prd.sh`, `vf-product-pm.md`, `vf-product-manager.md`, `product-routing.md`, T44).
**Pattern extraction date :** 2026-10-29
