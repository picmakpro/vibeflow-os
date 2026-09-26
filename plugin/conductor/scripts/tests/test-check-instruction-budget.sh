#!/usr/bin/env bash
# test-check-instruction-budget.sh — Suite de vérification de check-instruction-budget.sh
# (BUDG-01, BUDG-02, QUAL-01, plan 25-02). Un cas par état du contrat, chaque cas construit sa
# PROPRE fixture dans un mktemp -d, jamais sur le dépôt réel (patron
# test-check-requirements-survival.sh) ; le gate y est invoqué par --path, la sentinelle de
# fixture par écriture directe du fichier, jamais par le gate (D-04).
#
# Trois issues QUAL-01, chacune sur fixture jetable : PASS (conforme), FAIL (dépassement),
# BRUYANT (imparsable, exit 2). Le cas BRUYANT est exercé par une fixture SYNTHÉTIQUE : aucun des
# 31 fichiers du corpus réel n'a de frontmatter cassé aujourd'hui (25-RESEARCH.md:560-572).
#
# Révision Phase 40.1 (arbitrages Samuel D-01/D-02/D-05/D-07, AskUserQuestion session principale,
# relais SendMessage, 2026-09-16) : le ratchet ne bloque plus QUE les instructions (par fichier,
# D-07) ; le plafond ADR-029 passe à 300 lignes (PLAFOND) avec un avertissement non bloquant dès
# 251 (BORNE_AVERT). La colonne lignes de la baseline reste lue et publiée, jamais comparée pour
# le rc (D-02, D-H6). Sept mutants OPPOSABLES vérifiés par cmp :
#   - MUT-1 neutralise la comparaison de la métrique INSTRUCTIONS à sa baseline.
#   - MUT-2 (remplacé) ré-introduit la comparaison des LIGNES comme verdict bloquant.
#   - MUT-3 force la lecture de la sentinelle à « non armé » (ARMED reste 0 même sentinelle posée).
#   - MUT-4 neutralise la détection du frontmatter jamais refermé (imparsable).
#   - MUT-5 fait tomber l'avertissement de zone dans un libellé bloquant (DEPASSEMENT-*).
#   - MUT-6 décale le plafond d'un cran (`-gt` → `-ge`).
#   - MUT-7 décale le bord bas de la zone d'avertissement d'un cran (`-ge` → `-gt`).
# Chaque mutant est refusé (test en échec) s'il n'a rien changé (cmp -s identique à l'original) ou
# si bash -n échoue sur lui — un mutant non opposable est un échec, pas un succès.
#
# Déviation déclarée minimale au plan (mandat vf-dev-manager, 2026-09-15) : six cas nommés de
# non-régression F1-1/F1-2/F1-3/F1-4/F2/F3, un par défaut réellement trouvé et fermé en vague 1
# (commit cca219b), plus deux contrôles négatifs (baseline zéro-paddée légitime, baseline très
# grande légitime) qui doivent rester OK/exit 0 — un « 2 » de complaisance serait aussi faux qu'un
# « 0 » de complaisance.
#
# Comparaison de fixtures : cmp, comm, cksum uniquement — jamais diff (proxifié menteur sur ce
# poste, cf. test-check-divergence.sh:4-6).
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/check-instruction-budget.sh"
TARGET="$SCRIPT"
# Racine du depot reel (43-04, BOOT-1..5) — pour copier plugin/_internal/resolve-deps.sh dans les
# fixtures synthetiques du bootstrap : le resolveur canonique, jamais un second parseur de requires.
REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"

# Constantes locales de la suite (Phase 40.1) — TOUTES les tailles de fixture de bord se dérivent
# de ces deux valeurs, jamais d'un littéral de l'ancien plafond (constat B1 du checker, révision
# 1 : un littéral ici rougirait le recensement BUDG-04, l'outil qui traque les énoncés vivants de
# l'ancienne charte de densité).
BORNE_AVERT=251
PLAFOND=300
# Plafond SKILL.md (43-04, FABR-09, D-Q4) — ADR-029 : skills ≤ 500 lignes, distinct du plafond
# agent (300). Constante locale de la suite, jamais un littéral disperse dans les cas ci-dessous.
PLAFOND_SKILL=500

PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
# ko <assertion> <attendu> <obtenu> — trace à trois champs distincts, jamais un « KO » muet.
ko() {
  echo "  ✗ $1"
  echo "    assertion : $1"
  echo "    attendu   : $2"
  echo "    obtenu    : $3"
  FAIL=$((FAIL+1))
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ===================================================================================================
# Constructeurs de fixture — arborescences pures sous $TMP, jamais plugin/ ni .planning/ du dépôt.
# ===================================================================================================

# mk_root <name> -> imprime <path> ; crée <path>/plugin/demo/agents/ et <path>/.planning/
mk_root() {
  local d="$TMP/$1"
  mkdir -p "$d/plugin/demo/agents" "$d/.planning" || { echo "  ✗ FIXTURE — mkdir $d impossible" >&2; exit 1; }
  printf '%s' "$d"
}

# w_lines <path> <ligne...> — écrit chaque argument comme une ligne, dans l'ordre, sans heredoc
# (évite tout piège d'apostrophe/backtick dans un bloc quoté).
w_lines() {
  local path="$1"; shift
  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$@" > "$path"
}

# w_armed <root>
w_armed() { : > "$1/.planning/.instruction-budget-armed"; }

# w_baseline <root> — écrit le TSV lu sur stdin (jamais de tabulation littérale dans le script :
# toujours assemblée par printf '\t' côté appelant).
w_baseline() { cat > "$1/.planning/instruction-budget-baselines.tsv"; }

# run <root> [args...] — invocation TOUJOURS via --path, jamais sans (T-25-09).
run() {
  local path="$1"; shift
  bash "$TARGET" --path "$path" "$@" 2>&1
}

# std_agent <root> — écrit plugin/demo/agents/a.md : 4 lignes, 1 instruction (mesuré par
# construction : frontmatter 3 lignes + une ligne de body portant le marqueur « doit »).
std_agent() {
  w_lines "$1/plugin/demo/agents/a.md" \
    '---' \
    'name: demo' \
    '---' \
    'Le manager DOIT valider chaque etape.'
}

# gen_lines <path> <total> — génère un fichier de <total> lignes exactement : frontmatter 3
# lignes + (total - 3) lignes de corps sans aucun marqueur textuel (instr=0 par construction,
# seule la métrique LIGNES est en jeu ici). Affirme la taille obtenue par awk avant de rendre la
# main (Pitfall 2 : une fixture qui ne dépasse plus ce qu'elle prétend dépasser est un ko tracé).
gen_lines() {
  local path="$1" total="$2"
  {
    printf '%s\n' '---' 'name: demo-cap' '---'
    local body=$((total - 3))
    local i=1
    while [ "$i" -le "$body" ]; do
      printf 'Ligne de corps numero %s, sans marqueur textuel.\n' "$i"
      i=$((i + 1))
    done
  } > "$path"
  local got
  got=$(awk 'END{print NR}' "$path")
  if [ "$got" -ne "$total" ]; then
    echo "  ✗ FIXTURE — gen_lines $path $total a produit $got lignes" >&2
    exit 1
  fi
}

# Reproduction EXACTE des fixtures de contrôle du plan 25-01 (verify de la tâche 2) : INSTR=4 et
# INSTR=2, dérivées de leur construction, jamais recopiées d'un document.
F3B="$(printf '\140\140\140')"   # trois accents graves (fence markdown)
XMARK="$(printf '\342\235\214')" # ❌ (croix rouge)

w_metric_demo_a() { # <root> — INSTR attendu = 4
  w_lines "$1/plugin/demo/agents/demo-a.md" \
    '---' \
    'name: demo-a' \
    'description: ne fait JAMAIS le travail metier lui-meme' \
    '---' \
    '## Iron Laws' \
    '- Tout lab embarque ses auditeurs.' \
    "- $XMARK Coder en dur des couleurs alors qu un systeme de design existe." \
    '- Ne declenche JAMAIS un ship sans arbitrage.' \
    '## Retour (bloc type obligatoire)' \
    'Le manager DOIT rendre un rapport de mission.' \
    "$F3B" \
    'echo "le script DOIT sortir 1"' \
    "$F3B" \
    '## References' \
    '- Workflow quotidien : chemin/vers/doc.md'
}

w_metric_demo_b() { # <root> — INSTR attendu = 2
  w_lines "$1/plugin/demo/agents/demo-b.md" \
    '---' \
    'name: demo-b' \
    '---' \
    '## Garde-fous' \
    '- Un seul ecrivain par arbre.' \
    '- Le lock est verifie avant tout checkout.' \
    '## Notes' \
    '- Un chemin de documentation.'
}

# w_nested_subtitle <root> — Open Question 1 (D-01 bis) : un "### Details" sous "## Iron Laws"
# referme le scope (niveau plat, pas récursif). INSTR attendu = 1 (seule la puce du premier
# niveau, sans marqueur, compte ; la puce sous le sous-titre imbriqué ne compte pas).
w_nested_subtitle() {
  w_lines "$1/plugin/demo/agents/demo-c.md" \
    '---' \
    'name: demo-c' \
    '---' \
    '## Iron Laws' \
    '- Regle sans marqueur mais bullet sous scope.' \
    '### Details' \
    '- Puce descriptive sans marqueur, sous un sous-titre imbrique.'
}

echo "== test-check-instruction-budget =="

# ===================================================================================================
# Tâche 1 — trois issues (QUAL-01), trois arêtes (BUDG-02), formes normatives (BUDG-01)
# ===================================================================================================

# --- Issue PASS : fixture armée, baseline reprend les valeurs mesurées → rc 0, verdict OK --------
D="$(mk_root pass)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"plugin/demo/agents/a.md | 4 | 4 | 1 | 1 | OK"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "issue QUAL-01 PASS — fixture armée, baseline = mesure exacte → rc 0, verdict OK"; else ko "issue QUAL-01 PASS — fixture armée, baseline = mesure exacte → rc 0, verdict OK" "rc=0, ligne portant OK" "rc=$rc out=[$out]"; fi

# --- Issue FAIL (instructions) : baseline instr abaissée d'une unité → rc 1, DEPASSEMENT-INSTR ---
D="$(mk_root fail-instr)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t0\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"DEPASSEMENT-INSTR"*) has=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "issue QUAL-01 FAIL (instructions) — baseline abaissee d'une unite → rc 1, DEPASSEMENT-INSTR"; else ko "issue QUAL-01 FAIL (instructions) — baseline abaissee d'une unite → rc 1, DEPASSEMENT-INSTR" "rc=1 verdict DEPASSEMENT-INSTR" "rc=$rc out=[$out]"; fi

# --- BUDG-05 : lignes en hausse SANS instruction, sous le plafond → rc 0, OK+LIGNES-EN-HAUSSE, ---
# --- jamais DEPASSEMENT (D-02/D-H6 : la colonne lignes n'est plus jamais comparee pour le rc) ----
D="$(mk_root budg05-lignes-hausse)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t3\t1\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"plugin/demo/agents/a.md | 4 | 3 | 1 | 1 | OK+LIGNES-EN-HAUSSE"*) has=1 ;; esac
nodep=1; case "$out" in *"DEPASSEMENT"*) nodep=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ] && [ "$nodep" -eq 1 ]; then
  ok "BUDG-05 — lignes en hausse sans instruction, sous le plafond → rc 0, OK+LIGNES-EN-HAUSSE, jamais DEPASSEMENT"
else
  ko "BUDG-05 — lignes en hausse sans instruction, sous le plafond → rc 0, OK+LIGNES-EN-HAUSSE, jamais DEPASSEMENT" "rc=0, ligne OK+LIGNES-EN-HAUSSE, aucun DEPASSEMENT" "rc=$rc out=[$out]"
fi

# --- Issue BRUYANT (1/2) : frontmatter ouvert jamais refermé → rc 2, NON-VERIFIABLE, stderr nomme
# --- le chemin --------------------------------------------------------------------------------
D="$(mk_root bruyant-frontmatter)"
w_lines "$D/plugin/demo/agents/a.md" \
  '---' \
  'name: demo' \
  'Corps sans frontmatter jamais referme.'
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"plugin/demo/agents/a.md : non verifiable — frontmatter jamais referme"*"plugin/demo/agents/a.md | - | - | - | - | NON-VERIFIABLE"*) has=1 ;; esac
if [ "$rc" -eq 2 ] && [ "$has" -eq 1 ]; then ok "issue QUAL-01 BRUYANT (frontmatter jamais referme) — fixture synthetique → rc 2, NON-VERIFIABLE, stderr nomme le chemin"; else ko "issue QUAL-01 BRUYANT (frontmatter jamais referme) — fixture synthetique → rc 2, NON-VERIFIABLE, stderr nomme le chemin" "rc=2, ligne NON-VERIFIABLE + message stderr avec le chemin" "rc=$rc out=[$out]"; fi

# --- Issue BRUYANT (2/2) : fichier illisible (permissions retirées) → rc 2, NON-VERIFIABLE -------
if [ "$(id -u)" -eq 0 ]; then
  echo "  (ignore explicitement : suite executee en root, le cas fichier illisible n'est pas significatif — jamais compte vert)"
else
  D="$(mk_root bruyant-illisible)"
  w_lines "$D/plugin/demo/agents/a.md" '---' 'name: demo' '---' 'Contenu.'
  chmod 000 "$D/plugin/demo/agents/a.md"
  out="$(run "$D")"; rc=$?
  chmod 644 "$D/plugin/demo/agents/a.md"
  has=0; case "$out" in *"plugin/demo/agents/a.md | - | - | - | - | NON-VERIFIABLE"*) has=1 ;; esac
  if [ "$rc" -eq 2 ] && [ "$has" -eq 1 ]; then ok "issue QUAL-01 BRUYANT (fichier illisible) — permissions retirees → rc 2, NON-VERIFIABLE"; else ko "issue QUAL-01 BRUYANT (fichier illisible) — permissions retirees → rc 2, NON-VERIFIABLE" "rc=2, ligne NON-VERIFIABLE" "rc=$rc out=[$out]"; fi
fi

# --- Contre-cas : fichier SANS frontmatter du tout se compte normalement, jamais NON-VERIFIABLE --
D="$(mk_root sans-frontmatter)"
w_lines "$D/plugin/demo/agents/a.md" 'Contenu simple sans frontmatter du tout.'
w_armed "$D"
printf 'plugin/demo/agents/a.md\t1\t0\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
nv=0; case "$out" in *"plugin/demo/agents/a.md"*"NON-VERIFIABLE"*) nv=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$nv" -eq 0 ]; then ok "contre-cas — fichier SANS frontmatter du tout compte normalement, jamais NON-VERIFIABLE"; else ko "contre-cas — fichier SANS frontmatter du tout compte normalement, jamais NON-VERIFIABLE" "rc=0, jamais NON-VERIFIABLE" "rc=$rc out=[$out]"; fi

# --- adjacence : courant == baseline (rc 0), courant = baseline+1 (rc 1), courant = baseline-1 ---
# --- (rc 0, MARGE) — trois sous-cas sur la métrique instructions, un seul cas nommé --------------
D="$(mk_root adjacence-eq)"; std_agent "$D"; w_armed "$D"; printf 'plugin/demo/agents/a.md\t4\t1\n' | w_baseline "$D"
out_eq="$(run "$D")"; rc_eq=$?
D="$(mk_root adjacence-plus1)"; std_agent "$D"; w_armed "$D"; printf 'plugin/demo/agents/a.md\t4\t0\n' | w_baseline "$D"
out_plus1="$(run "$D")"; rc_plus1=$?
D="$(mk_root adjacence-moins1)"; std_agent "$D"; w_armed "$D"; printf 'plugin/demo/agents/a.md\t4\t2\n' | w_baseline "$D"
out_moins1="$(run "$D")"; rc_moins1=$?
has_marge=0; case "$out_moins1" in *"MARGE"*) has_marge=1 ;; esac
if [ "$rc_eq" -eq 0 ] && [ "$rc_plus1" -eq 1 ] && [ "$rc_moins1" -eq 0 ] && [ "$has_marge" -eq 1 ]; then
  ok "adjacence — courant==baseline rc 0 ; courant=baseline+1 rc 1 ; courant=baseline-1 rc 0 verdict MARGE"
else
  ko "adjacence — courant==baseline rc 0 ; courant=baseline+1 rc 1 ; courant=baseline-1 rc 0 verdict MARGE" "rc_eq=0 rc_plus1=1 rc_moins1=0 avec MARGE" "rc_eq=$rc_eq rc_plus1=$rc_plus1 rc_moins1=$rc_moins1 marge=$has_marge"
fi

# --- vide (a) : 0 fichier découvert → rc 2, jamais 0 ----------------------------------------------
D="$(mk_root vide-zero-fichier)"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 2 ]; then ok "vide (a) — aucun fichier d'agent decouvert → rc 2"; else ko "vide (a) — aucun fichier d'agent decouvert → rc 2" "rc=2" "rc=$rc out=[$out]"; fi

# --- vide (b) : armée sans fichier de baselines → rc 2 --------------------------------------------
D="$(mk_root vide-baseline-absente)"
std_agent "$D"
w_armed "$D"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 2 ]; then ok "vide (b) — fixture armee sans fichier de baselines → rc 2"; else ko "vide (b) — fixture armee sans fichier de baselines → rc 2" "rc=2" "rc=$rc out=[$out]"; fi

# --- vide (c) : armée, baseline avec seulement commentaires/lignes vides → rc 2 -------------------
D="$(mk_root vide-baseline-vide-utile)"
std_agent "$D"
w_armed "$D"
printf '# un commentaire\n\n   \n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 2 ]; then ok "vide (c) — fixture armee, baseline reduite a des commentaires/lignes vides → rc 2"; else ko "vide (c) — fixture armee, baseline reduite a des commentaires/lignes vides → rc 2" "rc=2" "rc=$rc out=[$out]"; fi

# --- vide (d) : armée, entrée orpheline (chemin sans fichier découvert correspondant) → rc 2 ------
D="$(mk_root vide-orpheline)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\nplugin/demo/agents/ghost.md\t10\t2\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 2 ]; then ok "vide (d) — fixture armee avec une entree de baseline orpheline → rc 2"; else ko "vide (d) — fixture armee avec une entree de baseline orpheline → rc 2" "rc=2" "rc=$rc out=[$out]"; fi

# --- plafond absolu ADR029 : fichier PLAFOND+1 lignes ET baseline de lignes egale → rc 1, la ------
# --- baseline ne legalise jamais un depassement du plafond ----------------------------------------
D="$(mk_root plafond-adr029)"
gen_lines "$D/plugin/demo/agents/big.md" "$((PLAFOND + 1))"
w_armed "$D"
printf 'plugin/demo/agents/big.md\t%s\t0\n' "$((PLAFOND + 1))" | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"plugin/demo/agents/big.md"*"DEPASSEMENT-ADR029"*) has=1 ;; esac
noav=1; case "$out" in *"AVERTISSEMENT-ADR029"*) noav=0 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ] && [ "$noav" -eq 1 ]; then ok "plafond absolu ADR029 — PLAFOND+1 lignes, baseline egale → rc 1, DEPASSEMENT-ADR029 seul (la baseline ne prime jamais sur le plafond, pas d'avertissement accumule)"; else ko "plafond absolu ADR029 — PLAFOND+1 lignes, baseline egale → rc 1, DEPASSEMENT-ADR029 seul" "rc=1, ligne DEPASSEMENT-ADR029, jamais AVERTISSEMENT-ADR029" "rc=$rc out=[$out]"; fi

# --- sous-zone : taille BORNE_AVERT-1 → rc 0, aucun avertissement --------------------------------
D="$(mk_root sous-zone-avert)"
gen_lines "$D/plugin/demo/agents/a.md" "$((BORNE_AVERT - 1))"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t%s\t0\n' "$((BORNE_AVERT - 1))" | w_baseline "$D"
out="$(run "$D")"; rc=$?
noav=1; case "$out" in *"AVERTISSEMENT-ADR029"*) noav=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$noav" -eq 1 ]; then ok "sous-zone — taille BORNE_AVERT-1 → rc 0, aucun AVERTISSEMENT-ADR029"; else ko "sous-zone — taille BORNE_AVERT-1 → rc 0, aucun AVERTISSEMENT-ADR029" "rc=0, aucun AVERTISSEMENT-ADR029" "rc=$rc out=[$out]"; fi

# --- bord d'avertissement : taille BORNE_AVERT → rc 0, AVERTISSEMENT-ADR029 ----------------------
D="$(mk_root bord-avert)"
gen_lines "$D/plugin/demo/agents/a.md" "$BORNE_AVERT"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t%s\t0\n' "$BORNE_AVERT" | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"AVERTISSEMENT-ADR029"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "bord d'avertissement — taille BORNE_AVERT → rc 0, AVERTISSEMENT-ADR029"; else ko "bord d'avertissement — taille BORNE_AVERT → rc 0, AVERTISSEMENT-ADR029" "rc=0, AVERTISSEMENT-ADR029 present" "rc=$rc out=[$out]"; fi

# --- 260 lignes, baseline lignes 4 (hausse) → rc 0, LIGNES-EN-HAUSSE ET AVERTISSEMENT-ADR029 ------
D="$(mk_root zone-260-hausse)"
gen_lines "$D/plugin/demo/agents/a.md" 260
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t0\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
hasl=0; case "$out" in *"LIGNES-EN-HAUSSE"*) hasl=1 ;; esac
hasa=0; case "$out" in *"AVERTISSEMENT-ADR029"*) hasa=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$hasl" -eq 1 ] && [ "$hasa" -eq 1 ]; then ok "260 lignes, baseline lignes 4 → rc 0, LIGNES-EN-HAUSSE ET AVERTISSEMENT-ADR029"; else ko "260 lignes, baseline lignes 4 → rc 0, LIGNES-EN-HAUSSE ET AVERTISSEMENT-ADR029" "rc=0, LIGNES-EN-HAUSSE et AVERTISSEMENT-ADR029" "rc=$rc out=[$out]"; fi

# --- PLAFOND lignes → rc 0, AVERTISSEMENT-ADR029 (bord haut de la zone, encore non bloquant) ------
D="$(mk_root zone-plafond-avert)"
gen_lines "$D/plugin/demo/agents/a.md" "$PLAFOND"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t%s\t0\n' "$PLAFOND" | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"AVERTISSEMENT-ADR029"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "PLAFOND lignes → rc 0, AVERTISSEMENT-ADR029 (bord haut de la zone)"; else ko "PLAFOND lignes → rc 0, AVERTISSEMENT-ADR029 (bord haut de la zone)" "rc=0, AVERTISSEMENT-ADR029 present" "rc=$rc out=[$out]"; fi

# --- instruction ajoutee a un fichier de 260 lignes → rc 1, DEPASSEMENT-INSTR --------------------
# --- (259 lignes neutres via gen_lines + une ligne d'instruction ajoutee = 260 lignes, INSTR=1) ---
D="$(mk_root instr-sur-260)"
gen_lines "$D/plugin/demo/agents/a.md" 259
printf '%s\n' 'Le manager DOIT valider cette ligne de plus.' >> "$D/plugin/demo/agents/a.md"
got260=$(awk 'END{print NR}' "$D/plugin/demo/agents/a.md")
[ "$got260" -eq 260 ] || { echo "  ✗ FIXTURE — instr-sur-260 a produit $got260 lignes" >&2; exit 1; }
w_armed "$D"
printf 'plugin/demo/agents/a.md\t260\t0\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"DEPASSEMENT-INSTR"*) has=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "instruction ajoutee a un fichier de 260 lignes (baseline instr=0, courant=1) → rc 1, DEPASSEMENT-INSTR"; else ko "instruction ajoutee a un fichier de 260 lignes (baseline instr=0, courant=1) → rc 1, DEPASSEMENT-INSTR" "rc=1, DEPASSEMENT-INSTR" "rc=$rc out=[$out]"; fi

# --- ordre : trois fichiers dont les noms se trient differemment selon la locale — deux executions
# --- rendent le meme cksum, l'ordre des lignes suit LC_ALL=C sort (Banana < Cherry < apple) -------
D="$(mk_root ordre)"
w_lines "$D/plugin/demo/agents/Banana.md" '---' 'name: b' '---' 'Contenu.'
w_lines "$D/plugin/demo/agents/Cherry.md" '---' 'name: c' '---' 'Contenu.'
w_lines "$D/plugin/demo/agents/apple.md" '---' 'name: a' '---' 'Contenu.'
out1="$(run "$D")"; rc1=$?
out2="$(run "$D")"; rc2=$?
c1=$(printf '%s' "$out1" | cksum)
c2=$(printf '%s' "$out2" | cksum)
got_order="$TMP/ordre-got"
printf '%s\n' "$out1" | grep '^plugin/' | awk -F' \\| ' '{print $1}' > "$got_order"
expected_order="$TMP/ordre-expected"
printf '%s\n' 'plugin/demo/agents/Banana.md' 'plugin/demo/agents/Cherry.md' 'plugin/demo/agents/apple.md' | LC_ALL=C sort > "$expected_order"
if [ "$rc1" -eq 3 ] && [ "$rc1" -eq "$rc2" ] && [ "$c1" = "$c2" ] && cmp -s "$got_order" "$expected_order"; then
  ok "ordre — LC_ALL=C sort, deux executions successives cksum identique, ordre Banana/Cherry/apple"
else
  ko "ordre — LC_ALL=C sort, deux executions successives cksum identique, ordre Banana/Cherry/apple" "rc1=rc2=3, cksum identique, ordre = Banana/Cherry/apple" "rc1=$rc1 rc2=$rc2 c1=[$c1] c2=[$c2] ordre_obtenu=[$(printf '%s' "$(cat "$got_order")" | tr '\n' ',')]"
fi

# --- ratchet : fixture en depassement, non armee → rc 3, tableau integral (1 ligne pour 1 fichier)
# --- ; sentinelle posee sur la MEME fixture, sans rien changer d'autre → rc 1 (bascule 3 -> 1) ----
D="$(mk_root ratchet)"
std_agent "$D"
printf 'plugin/demo/agents/a.md\t4\t0\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
rows=$(printf '%s\n' "$out" | grep -c '^plugin/')
w_armed "$D"
out2="$(run "$D")"; rc2=$?
if [ "$rc" -eq 3 ] && [ "$rows" -eq 1 ] && [ "$rc2" -eq 1 ]; then
  ok "ratchet — fixture en depassement non armee → rc 3, tableau integral (1 ligne) ; meme fixture, sentinelle posee → bascule vers rc 1"
else
  ko "ratchet — fixture en depassement non armee → rc 3, tableau integral (1 ligne) ; meme fixture, sentinelle posee → bascule vers rc 1" "rc_avant=3 lignes=1 rc_apres=1" "rc_avant=$rc lignes=$rows rc_apres=$rc2"
fi

# --- métrique BUDG-01 : fixtures de contrôle exactes du plan 25-01 (INSTR=4, INSTR=2) -------------
D="$(mk_root metrique-demo-a)"
w_metric_demo_a "$D"
out="$(run "$D")"; rc=$?
ia=$(printf '%s\n' "$out" | awk -F'|' '/^plugin\/demo\/agents\/demo-a\.md /{gsub(/[[:space:]]/,"",$4); print $4}')
if [ "$ia" = "4" ]; then ok "metrique BUDG-01 — fixture demo-a (controle exact du plan 25-01) → INSTR=4"; else ko "metrique BUDG-01 — fixture demo-a (controle exact du plan 25-01) → INSTR=4" "INSTR=4" "INSTR=$ia rc=$rc out=[$out]"; fi

D="$(mk_root metrique-demo-b)"
w_metric_demo_b "$D"
out="$(run "$D")"; rc=$?
ib=$(printf '%s\n' "$out" | awk -F'|' '/^plugin\/demo\/agents\/demo-b\.md /{gsub(/[[:space:]]/,"",$4); print $4}')
if [ "$ib" = "2" ]; then ok "metrique BUDG-01 — fixture demo-b (controle exact du plan 25-01) → INSTR=2"; else ko "metrique BUDG-01 — fixture demo-b (controle exact du plan 25-01) → INSTR=2" "INSTR=2" "INSTR=$ib rc=$rc out=[$out]"; fi

# --- Open Question 1 (D-01 bis) : "### Details" sous "## Iron Laws" referme le scope, niveau plat,
# --- pas recursif → INSTR=1 (seule la premiere puce, sans marqueur, compte) -----------------------
D="$(mk_root sous-titre-imbrique)"
w_nested_subtitle "$D"
out="$(run "$D")"; rc=$?
ic=$(printf '%s\n' "$out" | awk -F'|' '/^plugin\/demo\/agents\/demo-c\.md /{gsub(/[[:space:]]/,"",$4); print $4}')
if [ "$ic" = "1" ]; then ok "Open Question 1 — sous-titre imbrique (### sous ##) referme le scope, niveau plat → INSTR=1"; else ko "Open Question 1 — sous-titre imbrique (### sous ##) referme le scope, niveau plat → INSTR=1" "INSTR=1" "INSTR=$ic rc=$rc out=[$out]"; fi

# ===================================================================================================
# Non-régression F1-1..F1-4 / F2 / F3 (correctif cca219b, revue vague 1) + deux contrôles négatifs
# — déviation déclarée minimale au plan, mandat vf-dev-manager 2026-09-15.
# ===================================================================================================

# --- F1-1 : baseline avec valeur non numerique ("abc") → NON-VERIFIABLE, rc 2 (avant : rc 0, MARGE)
D="$(mk_root f1-1-non-numerique)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\tabc\t1\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"plugin/demo/agents/a.md | - | - | - | - | NON-VERIFIABLE"*) has=1 ;; esac
if [ "$rc" -eq 2 ] && [ "$has" -eq 1 ]; then ok "F1-1 non-regression — baseline non numerique (abc) → rc 2, NON-VERIFIABLE"; else ko "F1-1 non-regression — baseline non numerique (abc) → rc 2, NON-VERIFIABLE" "rc=2, ligne NON-VERIFIABLE" "rc=$rc out=[$out]"; fi

# --- F1-2 : ligne de baseline a 2 colonnes au lieu de 3 → rc 2 (avant : rc 0) ---------------------
D="$(mk_root f1-2-colonne-manquante)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"plugin/demo/agents/a.md | - | - | - | - | NON-VERIFIABLE"*) has=1 ;; esac
if [ "$rc" -eq 2 ] && [ "$has" -eq 1 ]; then ok "F1-2 non-regression — ligne de baseline a 2 colonnes → rc 2, NON-VERIFIABLE"; else ko "F1-2 non-regression — ligne de baseline a 2 colonnes → rc 2, NON-VERIFIABLE" "rc=2, ligne NON-VERIFIABLE" "rc=$rc out=[$out]"; fi

# --- F1-3 : CR residuel en fin de derniere colonne (CRLF) → rc 2 (avant : rc 0) -------------------
D="$(mk_root f1-3-crlf)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\r\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"plugin/demo/agents/a.md | - | - | - | - | NON-VERIFIABLE"*) has=1 ;; esac
if [ "$rc" -eq 2 ] && [ "$has" -eq 1 ]; then ok "F1-3 non-regression — CR residuel (CRLF) en fin de colonne → rc 2, NON-VERIFIABLE"; else ko "F1-3 non-regression — CR residuel (CRLF) en fin de colonne → rc 2, NON-VERIFIABLE" "rc=2, ligne NON-VERIFIABLE" "rc=$rc out=[$out]"; fi

# --- F1-4 : cle de baseline dupliquee pour un meme chemin → rc 2 (avant : rc 0, 2e entree lue en
# --- silence) ---------------------------------------------------------------------------------
D="$(mk_root f1-4-cle-dupliquee)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\nplugin/demo/agents/a.md\t3\t0\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"plugin/demo/agents/a.md | - | - | - | - | NON-VERIFIABLE"*) has=1 ;; esac
if [ "$rc" -eq 2 ] && [ "$has" -eq 1 ]; then ok "F1-4 non-regression — cle de baseline dupliquee pour le meme chemin → rc 2, NON-VERIFIABLE"; else ko "F1-4 non-regression — cle de baseline dupliquee pour le meme chemin → rc 2, NON-VERIFIABLE" "rc=2, ligne NON-VERIFIABLE" "rc=$rc out=[$out]"; fi

# --- F2 : fichier SANS frontmatter reel mais deux '---' isoles dans le corps → les lignes entre
# --- les deux sont COMPTEES (avant : silencieusement exclues, INSTR=0 au lieu de 1) ---------------
D="$(mk_root f2-faux-frontmatter)"
w_lines "$D/plugin/demo/agents/f2-fausse-frontmatter.md" \
  'Titre de prose, pas de frontmatter ici.' \
  '---' \
  'Le manager DOIT valider cette ligne comptee malgre les tirets isoles.' \
  '---' \
  'Fin de fichier.'
out="$(run "$D")"; rc=$?
i2=$(printf '%s\n' "$out" | awk -F'|' '/^plugin\/demo\/agents\/f2-fausse-frontmatter\.md /{gsub(/[[:space:]]/,"",$4); print $4}')
if [ "$i2" = "1" ]; then ok "F2 non-regression — deux '---' isoles dans un fichier SANS frontmatter reel → contenu COMPTE (INSTR=1), jamais exclu en silence"; else ko "F2 non-regression — deux '---' isoles dans un fichier SANS frontmatter reel → contenu COMPTE (INSTR=1), jamais exclu en silence" "INSTR=1" "INSTR=$i2 rc=$rc out=[$out]"; fi

# --- F3 : fichier > PLAFOND lignes ET sans entree de baseline, mode arme → rc 2 (contrat de -------
# --- couverture incomplete), PAS 1 (avant : DEPASSEMENT-ADR029 masquait SANS-BASELINE et rendait 1)
D="$(mk_root f3-sans-baseline-armee)"
std_agent "$D"
gen_lines "$D/plugin/demo/agents/big.md" "$((PLAFOND + 1))"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 2 ]; then ok "F3 non-regression — fichier >PLAFOND lignes SANS entree de baseline, mode arme → rc 2 (jamais 1, DEPASSEMENT-ADR029 ne masque plus SANS-BASELINE)"; else ko "F3 non-regression — fichier >PLAFOND lignes SANS entree de baseline, mode arme → rc 2 (jamais 1, DEPASSEMENT-ADR029 ne masque plus SANS-BASELINE)" "rc=2" "rc=$rc out=[$out]"; fi

# --- Contrôle négatif A : baseline legitime a zero-padding initial ("007") → reste OK, rc 0 -------
# --- (jamais un 2 de complaisance ; verifie aussi l'evaluation arithmetique bash sur "007" — tous
# --- les chiffres sont dans 0-7, octal valide, evalue correctement a 7) ---------------------------
D="$(mk_root controle-zero-padding)"
w_lines "$D/plugin/demo/agents/a.md" \
  '---' \
  'name: demo-zero' \
  '---' \
  'Ligne de prose sans marqueur numero un.' \
  'Ligne de prose sans marqueur numero deux.' \
  'Ligne de prose sans marqueur numero trois.' \
  'Ligne de prose sans marqueur numero quatre.'
w_armed "$D"
printf 'plugin/demo/agents/a.md\t007\t0\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"plugin/demo/agents/a.md"*" OK"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "controle negatif A — baseline zero-paddee legitime (007) → reste OK, rc 0, jamais un 2 de complaisance"; else ko "controle negatif A — baseline zero-paddee legitime (007) → reste OK, rc 0, jamais un 2 de complaisance" "rc=0, verdict OK" "rc=$rc out=[$out]"; fi

# --- Contrôle négatif B : baseline legitime avec valeur tres grande → reste OK/MARGE, rc 0 --------
D="$(mk_root controle-baseline-tres-grande)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t999999999\t999999999\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"plugin/demo/agents/a.md"*"MARGE"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "controle negatif B — baseline legitime tres grande (999999999) → reste OK/MARGE, rc 0, jamais un 2 de complaisance"; else ko "controle negatif B — baseline legitime tres grande (999999999) → reste OK/MARGE, rc 0, jamais un 2 de complaisance" "rc=0, verdict MARGE" "rc=$rc out=[$out]"; fi

# ===================================================================================================
# SKILL.md (43-04, FABR-09, D-Q4) — seconde découverte récursive et plafond de 500 lignes
# (SKILL-1 à SKILL-6). Fixtures construites avec gen_lines (jamais un littéral de taille dispersé).
# ===================================================================================================
echo ""
echo "== SKILL.md (43-04) =="

# w_skill3_fixture <root> — module doc-only entierement exclu (1 SKILL.md), dossier *-references et
# dossier cache elagues (2 SKILL.md supplementaires, aucun des trois jamais mesure). Reutilisee par
# SKILL-3, MUT-9 et MUT-10.
w_skill3_fixture() {
  local d="$1"
  std_agent "$d"
  w_armed "$d"
  printf 'plugin/demo/agents/a.md\t4\t1\n' | w_baseline "$d"
  mkdir -p "$d/plugin/doc/content/templates/skills/t"
  w_lines "$d/plugin/doc/module.json" '{' '  "type": "doc-only"' '}'
  gen_lines "$d/plugin/doc/content/templates/skills/t/SKILL.md" "$((PLAFOND_SKILL + 1))"
  mkdir -p "$d/plugin/demo/skills/x-references/r" "$d/plugin/demo/.cache/s"
  gen_lines "$d/plugin/demo/skills/x-references/r/SKILL.md" "$((PLAFOND_SKILL + 1))"
  gen_lines "$d/plugin/demo/.cache/s/SKILL.md" "$((PLAFOND_SKILL + 1))"
}

# --- SKILL-1a : SKILL.md a PLAFOND_SKILL lignes exactement, fixture armee + baseline agent exacte -
# --- → rc 0, ligne du fichier en verdict OK ---------------------------------------------------------
D="$(mk_root skill1-ok)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n' | w_baseline "$D"
mkdir -p "$D/plugin/demo/skills/s"
gen_lines "$D/plugin/demo/skills/s/SKILL.md" "$PLAFOND_SKILL"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"plugin/demo/skills/s/SKILL.md | $PLAFOND_SKILL | $PLAFOND_SKILL | OK"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "SKILL-1a — SKILL.md a PLAFOND_SKILL lignes exactement → rc 0, verdict OK"; else ko "SKILL-1a — SKILL.md a PLAFOND_SKILL lignes exactement → rc 0, verdict OK" "rc=0, ligne SKILL OK" "rc=$rc out=[$out]"; fi

# --- SKILL-1b : PLAFOND_SKILL+1 lignes, armee → rc 1, DEPASSEMENT-SKILL-ADR029 ---------------------
D="$(mk_root skill1-depassement)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n' | w_baseline "$D"
mkdir -p "$D/plugin/demo/skills/s"
gen_lines "$D/plugin/demo/skills/s/SKILL.md" "$((PLAFOND_SKILL + 1))"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"plugin/demo/skills/s/SKILL.md"*"DEPASSEMENT-SKILL-ADR029"*) has=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "SKILL-1b — SKILL.md a PLAFOND_SKILL+1 lignes, armee → rc 1, DEPASSEMENT-SKILL-ADR029"; else ko "SKILL-1b — SKILL.md a PLAFOND_SKILL+1 lignes, armee → rc 1, DEPASSEMENT-SKILL-ADR029" "rc=1, DEPASSEMENT-SKILL-ADR029" "rc=$rc out=[$out]"; fi

# --- SKILL-1c : meme fixture PLAFOND_SKILL+1, SANS sentinelle → rc 3, rapport imprime --------------
D="$(mk_root skill1-non-arme)"
std_agent "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n' | w_baseline "$D"
mkdir -p "$D/plugin/demo/skills/s"
gen_lines "$D/plugin/demo/skills/s/SKILL.md" "$((PLAFOND_SKILL + 1))"
out="$(run "$D")"; rc=$?
rows=$(printf '%s\n' "$out" | grep -c '^plugin/demo/skills/s/SKILL.md ')
if [ "$rc" -eq 3 ] && [ "$rows" -eq 1 ]; then ok "SKILL-1c — meme fixture PLAFOND_SKILL+1 SANS sentinelle → rc 3, rapport imprime (1 ligne SKILL)"; else ko "SKILL-1c — meme fixture PLAFOND_SKILL+1 SANS sentinelle → rc 3, rapport imprime" "rc=3, 1 ligne SKILL" "rc=$rc rows=$rows out=[$out]"; fi

# --- SKILL-2 : SKILL.md a la racine d'un module ET a trois niveaux de profondeur, tous deux ---------
# --- mesures et en DEPASSEMENT-SKILL-ADR029 ---------------------------------------------------------
D="$(mk_root skill2-profondeurs)"
std_agent "$D"
mkdir -p "$D/plugin/solo" "$D/plugin/demo/skills/profond/sous"
gen_lines "$D/plugin/solo/SKILL.md" "$((PLAFOND_SKILL + 1))"
gen_lines "$D/plugin/demo/skills/profond/sous/SKILL.md" "$((PLAFOND_SKILL + 1))"
out="$(run "$D")"; rc=$?
has1=0; case "$out" in *"plugin/solo/SKILL.md"*"DEPASSEMENT-SKILL-ADR029"*) has1=1 ;; esac
has2=0; case "$out" in *"plugin/demo/skills/profond/sous/SKILL.md"*"DEPASSEMENT-SKILL-ADR029"*) has2=1 ;; esac
if [ "$has1" -eq 1 ] && [ "$has2" -eq 1 ]; then
  ok "SKILL-2 — SKILL.md a la racine d'un module et a trois niveaux de profondeur, tous deux mesures et en DEPASSEMENT-SKILL-ADR029"
else
  ko "SKILL-2 — trois profondeurs mesurees" "les deux chemins en DEPASSEMENT-SKILL-ADR029" "has1=$has1 has2=$has2 rc=$rc out=[$out]"
fi

# --- SKILL-3 : module doc-only entierement exclu, dossier *-references et dossier cache elagues ----
D="$(mk_root skill3-exclusions)"
w_skill3_fixture "$D"
out="$(run "$D")"; rc=$?
hasexcl=0; case "$out" in *"corpus skills decouvert : 0 SKILL.md (+ 1 exclu(s) sous un module doc-only)"*) hasexcl=1 ;; esac
nodep=1; case "$out" in *"DEPASSEMENT-SKILL"*) nodep=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$hasexcl" -eq 1 ] && [ "$nodep" -eq 1 ]; then
  ok "SKILL-3 — module doc-only entierement exclu (1), dossiers *-references et caches elagues → rc 0, aucun des trois SKILL.md mesure"
else
  ko "SKILL-3 — exclusions doc-only / -references / caches" "rc=0, corpus skills decouvert : 0 SKILL.md (+ 1 exclu(s)...), aucun DEPASSEMENT-SKILL" "rc=$rc out=[$out]"
fi

# --- SKILL-4a : SKILL.md au frontmatter jamais referme → rc 2, NON-VERIFIABLE, jamais ignore --------
D="$(mk_root skill4-frontmatter-ouvert)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n' | w_baseline "$D"
w_lines "$D/plugin/demo/skills/s/SKILL.md" '---' 'name: s' 'Corps sans frontmatter jamais referme.'
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"plugin/demo/skills/s/SKILL.md"*"NON-VERIFIABLE"*) has=1 ;; esac
if [ "$rc" -eq 2 ] && [ "$has" -eq 1 ]; then ok "SKILL-4a — SKILL.md au frontmatter jamais referme → rc 2, NON-VERIFIABLE, jamais ignore en silence"; else ko "SKILL-4a — frontmatter jamais referme" "rc=2, NON-VERIFIABLE" "rc=$rc out=[$out]"; fi

# --- SKILL-4b : SKILL.md en lien symbolique → rc 2, NON-VERIFIABLE, jamais ignore -------------------
D="$(mk_root skill4-symlink)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n' | w_baseline "$D"
mkdir -p "$D/plugin/demo/skills/s" "$D/plugin/demo/elsewhere"
w_lines "$D/plugin/demo/elsewhere/REAL.md" '---' 'name: s' '---' 'Contenu.'
ln -s "../elsewhere/REAL.md" "$D/plugin/demo/skills/s/SKILL.md"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"plugin/demo/skills/s/SKILL.md"*"NON-VERIFIABLE"*) has=1 ;; esac
if [ "$rc" -eq 2 ] && [ "$has" -eq 1 ]; then ok "SKILL-4b — SKILL.md en lien symbolique → rc 2, NON-VERIFIABLE, jamais ignore en silence"; else ko "SKILL-4b — lien symbolique" "rc=2, NON-VERIFIABLE" "rc=$rc out=[$out]"; fi

# --- SKILL-5 : fixture sans aucun SKILL.md, ligne neutre ajoutee a l'agent (cas 2/7 de la CI) → -----
# --- rc 0, LIGNES-EN-HAUSSE, aucune occurrence de DEPASSEMENT, corpus skills decouvert : 0 SKILL.md -
D="$(mk_root skill5-sans-skill-ci-2-7)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t3\t1\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
hasl=0; case "$out" in *"LIGNES-EN-HAUSSE"*) hasl=1 ;; esac
nodep=1; case "$out" in *"DEPASSEMENT"*) nodep=0 ;; esac
hasc=0; case "$out" in *"corpus skills decouvert : 0 SKILL.md"*) hasc=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$hasl" -eq 1 ] && [ "$nodep" -eq 1 ] && [ "$hasc" -eq 1 ]; then
  ok "SKILL-5 — fixture sans SKILL.md, ligne neutre ajoutee a l'agent (cas 2/7 CI) → rc 0, LIGNES-EN-HAUSSE, aucun DEPASSEMENT, corpus skills decouvert : 0 SKILL.md"
else
  ko "SKILL-5 — cas 2/7 CI sans SKILL.md" "rc=0, LIGNES-EN-HAUSSE, aucun DEPASSEMENT, corpus skills decouvert : 0 SKILL.md" "rc=$rc out=[$out]"
fi

# --- SKILL-6 : fixture sans SKILL.md et sans agent (repertoire vide, cas 7/7 de la CI) → rc 2 -------
# --- inchange -----------------------------------------------------------------------------------
D="$(mk_root skill6-vide)"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 2 ]; then ok "SKILL-6 — fixture sans SKILL.md et sans agent (repertoire vide) → rc 2 inchange"; else ko "SKILL-6 — repertoire vide" "rc=2" "rc=$rc out=[$out]"; fi

# --- SKILL-DISC-1 : find echoue (permission refusee, chmod 000) sur un sous-dossier pendant la ----
# --- decouverte SKILL.md → NON-VERIFIABLE, rc 2, meme traitement que BOOTSTRAP_NONVERIF, jamais un
# --- bilan "propre" avec un compte partiel silencieux (correctif revue 43-04, majeur). Droits ----
# --- restaures par un trap RETURN, jamais laisses en l'etat en cas d'echec du cas. ------------------
if [ "$(id -u)" -eq 0 ]; then
  echo "  (ignore explicitement : suite executee en root, le cas find-echec sur permission n'est pas significatif — jamais compte vert)"
else
  D="$(mk_root skill-disc-find-fail)"
  std_agent "$D"
  w_armed "$D"
  printf 'plugin/demo/agents/a.md\t4\t1\n' | w_baseline "$D"
  mkdir -p "$D/plugin/demo/skills/ok" "$D/plugin/demo/skills/blocked/inner"
  gen_lines "$D/plugin/demo/skills/ok/SKILL.md" 10
  w_lines "$D/plugin/demo/skills/blocked/inner/SKILL.md" '---' 'name: hidden' '---' 'Contenu cache par permission.'
  run_skill_disc_find_fail() {
    local blocked="$D/plugin/demo/skills/blocked"
    trap 'chmod 755 "$blocked" 2>/dev/null' RETURN
    chmod 000 "$blocked"
    run "$D"
  }
  out="$(run_skill_disc_find_fail)"; rc=$?
  # Preuve annexe que la restauration a bien eu lieu : le dossier redevient listable.
  restored=0; [ -x "$D/plugin/demo/skills/blocked" ] && restored=1
  has=0; case "$out" in *"decouverte SKILL.md"*"non verifiable"*"find a echoue"*) has=1 ;; esac
  if [ "$rc" -eq 2 ] && [ "$has" -eq 1 ] && [ "$restored" -eq 1 ]; then
    ok "SKILL-DISC-1 — find echoue (chmod 000) pendant la decouverte SKILL.md → rc 2, NON-VERIFIABLE, jamais un bilan propre, droits restaures par trap"
  else
    ko "SKILL-DISC-1 — find echoue pendant decouverte SKILL.md" "rc=2, message find non verifiable, droits restaures" "rc=$rc restored=$restored out=[$out]"
  fi
fi

# ===================================================================================================
# BOOTSTRAP (43-04, FABR-09, D-Q4, ratchet-socle) — BOOT-1 a BOOT-5. Calcul independant du script
# (boot_expected_bytes, reimplementation propre a la suite, jamais un appel a la fonction du
# script) : la definition unique se rejoue a l'execution, jamais recopiee en dur.
# ===================================================================================================
echo ""
echo "== BOOTSTRAP (43-04) =="

# Correctif revue (43-04, finding majeur) : l'ancien boot_expected_bytes() etait une RECOPIE de
# bootstrap_measure_file() du script (meme etat NR==1/in_fm/measuring, meme regex de cle, meme
# regex de continuation) — les cas BOOT-* comparaient donc le script a lui-meme : un bug niche
# dans l'algorithme de mesure (pas dans une comparaison de rc) aurait ete reproduit a l'identique
# dans l'oracle de test, jamais detecte. Remplace par une somme ARITHMETIQUE de longueurs de
# chaines LITTERALES connues a la construction de la fixture (boot_line_bytes) : aucun etat de
# frontmatter, aucune regex de cle, aucune notion de "ligne de continuation" — l'oracle ne rejoue
# plus le parseur du script, il compte les octets des lignes que la fixture est SENSEE mesurer,
# decides au moment ou elles sont ecrites. Les chaines sont pures ASCII (${#s} = octets sous
# LC_ALL=C).
boot_line_bytes() { # <ligne...> -> somme(longueur(ligne)+1), calcul INDEPENDANT du script
  local total=0 line
  for line in "$@"; do
    total=$((total + ${#line} + 1))
  done
  echo "$total"
}

# Lignes litterales du socle bootstrap — SOURCE UNIQUE partagee entre l'ecriture des fixtures
# (w_bootstrap_fixture) et le calcul independant (boot_expected_total) : ce ne sont que des
# chaines de caracteres, jamais une reimplementation de la logique de mesure du script.
BOOT_CONDUCTOR_NAME_LINE='name: conductor-demo'
BOOT_CONDUCTOR_DESC_LINE='description: une description de conductor'
BOOT_CONDUCTOR_CONT_LINE='  qui continue sur une deuxieme ligne'
BOOT_CONDUCTOR_WHEN_LINE='when_to_use: quand on a besoin de conductor'
BOOT_DEP_NAME_LINE='name: dep-demo'
BOOT_DEP_DESC_LINE='description: une description de dep'
BOOT_DEP_WHEN_LINE='when_to_use: quand on a besoin de dep'
BOOT_INSTALLER_NAME_LINE='name: installer-demo'
BOOT_INSTALLER_DESC_LINE='description: une description de installer'
BOOT_INSTALLER_WHEN_LINE='when_to_use: quand on a besoin de installer'
BOOT_CMD_DESC_LINE='description: une description de commande'
BOOT_CMD_WHEN_LINE='when_to_use: quand on a besoin de la commande'

# w_bootstrap_fixture <root> — socle minimal synthetique : conductor requiert dep (deux
# module.json), un SKILL.md sous chacun, skill installer expose par plugin.json (sans
# module.json), une commande, resolve-deps.sh copie du depot reel (REPO_ROOT). Reutilisee par
# BOOT-1, BOOT-2, BOOT-4, BOOT-6, MUT-11, MUT-12, MUT-13.
w_bootstrap_fixture() {
  local d="$1"
  std_agent "$d"
  mkdir -p "$d/plugin/conductor" "$d/plugin/dep" "$d/plugin/installer" "$d/plugin/commands" \
    "$d/plugin/.claude-plugin" "$d/plugin/_internal"
  w_lines "$d/plugin/conductor/module.json" '{' '  "requires": ["dep"]' '}'
  w_lines "$d/plugin/dep/module.json" '{' '  "requires": []' '}'
  w_lines "$d/plugin/conductor/SKILL.md" \
    '---' \
    "$BOOT_CONDUCTOR_NAME_LINE" \
    "$BOOT_CONDUCTOR_DESC_LINE" \
    "$BOOT_CONDUCTOR_CONT_LINE" \
    "$BOOT_CONDUCTOR_WHEN_LINE" \
    '---' \
    'Corps de conductor.'
  w_lines "$d/plugin/dep/SKILL.md" \
    '---' \
    "$BOOT_DEP_NAME_LINE" \
    "$BOOT_DEP_DESC_LINE" \
    "$BOOT_DEP_WHEN_LINE" \
    '---' \
    'Corps de dep.'
  w_lines "$d/plugin/.claude-plugin/plugin.json" '{' '  "skills": "./installer"' '}'
  w_lines "$d/plugin/installer/SKILL.md" \
    '---' \
    "$BOOT_INSTALLER_NAME_LINE" \
    "$BOOT_INSTALLER_DESC_LINE" \
    "$BOOT_INSTALLER_WHEN_LINE" \
    '---' \
    'Corps de installer.'
  w_lines "$d/plugin/commands/c.md" \
    '---' \
    "$BOOT_CMD_DESC_LINE" \
    "$BOOT_CMD_WHEN_LINE" \
    '---' \
    'Corps de commande.'
  cp "$REPO_ROOT/plugin/_internal/resolve-deps.sh" "$d/plugin/_internal/resolve-deps.sh"
  chmod +x "$d/plugin/_internal/resolve-deps.sh"
}

# boot_expected_total — somme INDEPENDANTE (arithmetique de chaines litterales, pas de parseur)
# sur le socle complet de w_bootstrap_fixture (conductor + dep + installer + commande c.md).
boot_expected_total() {
  local total=0
  total=$((total + $(boot_line_bytes "$BOOT_CONDUCTOR_NAME_LINE" "$BOOT_CONDUCTOR_DESC_LINE" "$BOOT_CONDUCTOR_CONT_LINE" "$BOOT_CONDUCTOR_WHEN_LINE")))
  total=$((total + $(boot_line_bytes "$BOOT_DEP_NAME_LINE" "$BOOT_DEP_DESC_LINE" "$BOOT_DEP_WHEN_LINE")))
  total=$((total + $(boot_line_bytes "$BOOT_INSTALLER_NAME_LINE" "$BOOT_INSTALLER_DESC_LINE" "$BOOT_INSTALLER_WHEN_LINE")))
  total=$((total + $(boot_line_bytes "$BOOT_CMD_DESC_LINE" "$BOOT_CMD_WHEN_LINE")))
  echo "$total"
}

# w_bootstrap_fixture_big <root> <n_lignes> — meme socle, description de conductor gonflee de
# <n_lignes> lignes de continuation pour depasser VF_BOOTSTRAP_TOKEN_CAP (2000 tokens, BOOT-5).
w_bootstrap_fixture_big() {
  local d="$1" n="$2" i
  w_bootstrap_fixture "$d"
  {
    printf '%s\n' '---' "$BOOT_CONDUCTOR_NAME_LINE" "$BOOT_CONDUCTOR_DESC_LINE"
    i=1
    while [ "$i" -le "$n" ]; do
      printf '  ligne de remplissage numero %04d pour gonfler le bootstrap au dela du plafond ADR-029.\n' "$i"
      i=$((i + 1))
    done
    printf '%s\n' "$BOOT_CONDUCTOR_WHEN_LINE" '---' 'Corps de conductor.'
  } > "$d/plugin/conductor/SKILL.md"
}

# boot_expected_total_big <n_lignes> — meme calcul independant que boot_expected_total, pour la
# variante w_bootstrap_fixture_big : le filler a une longueur constante (numero %04d, largeur
# fixe pour n < 10000), donc n * (longueur+1) sans reparcourir le fichier.
boot_expected_total_big() {
  local n="$1" total=0 filler
  filler="$(printf '  ligne de remplissage numero %04d pour gonfler le bootstrap au dela du plafond ADR-029.' 1)"
  total=$((total + $(boot_line_bytes "$BOOT_CONDUCTOR_NAME_LINE" "$BOOT_CONDUCTOR_DESC_LINE")))
  total=$((total + n * (${#filler} + 1)))
  total=$((total + $(boot_line_bytes "$BOOT_CONDUCTOR_WHEN_LINE")))
  total=$((total + $(boot_line_bytes "$BOOT_DEP_NAME_LINE" "$BOOT_DEP_DESC_LINE" "$BOOT_DEP_WHEN_LINE")))
  total=$((total + $(boot_line_bytes "$BOOT_INSTALLER_NAME_LINE" "$BOOT_INSTALLER_DESC_LINE" "$BOOT_INSTALLER_WHEN_LINE")))
  total=$((total + $(boot_line_bytes "$BOOT_CMD_DESC_LINE" "$BOOT_CMD_WHEN_LINE")))
  echo "$total"
}

# --- BOOT-1 : ligne BOOTSTRAP porte exactement le nombre de tokens attendu (calcul independant) ---
D="$(mk_root boot1)"
w_bootstrap_fixture "$D"
EXPECTED_BYTES="$(boot_expected_total)"
EXPECTED_TOKENS=$((EXPECTED_BYTES / 4))
out="$(run "$D")"; rc=$?
gotline="$(printf '%s\n' "$out" | grep '^BOOTSTRAP :')"
has=0; case "$gotline" in *"$EXPECTED_TOKENS tokens"*"sur socle (4 fichiers)"*) has=1 ;; esac
if [ "$has" -eq 1 ]; then
  ok "BOOT-1 — ligne BOOTSTRAP porte exactement le nombre de tokens attendu ($EXPECTED_TOKENS), calcule independamment (4 fichiers : 3 SKILL.md + 1 commande)"
else
  ko "BOOT-1 — mesure independante" "BOOTSTRAP : $EXPECTED_TOKENS tokens ... sur socle (4 fichiers)" "rc=$rc ligne=[$gotline]"
fi

# --- BOOT-2a : ligne @bootstrap:socle EGALE a la mesure, armee → rc 0 ------------------------------
D="$(mk_root boot2a-egale)"
w_bootstrap_fixture "$D"
EXPECTED_BYTES="$(boot_expected_total)"
EXPECTED_TOKENS=$((EXPECTED_BYTES / 4))
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n@bootstrap:socle\t0\t%s\n' "$EXPECTED_TOKENS" | w_baseline "$D"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 0 ]; then ok "BOOT-2a — ligne @bootstrap:socle egale a la mesure, armee → rc 0"; else ko "BOOT-2a — ligne egale a la mesure" "rc=0" "rc=$rc out=[$out]"; fi

# --- BOOT-2b : ligne STRICTEMENT SUPERIEURE a la mesure (baisse), armee → rc 0, AUCUNE occurrence -
# --- de DEPASSEMENT (stdout+stderr) — une baisse n'est jamais un depassement ----------------------
D="$(mk_root boot2b-baisse)"
w_bootstrap_fixture "$D"
EXPECTED_BYTES="$(boot_expected_total)"
EXPECTED_TOKENS=$((EXPECTED_BYTES / 4))
LIGNE_BAISSE=$((EXPECTED_TOKENS + 5))
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n@bootstrap:socle\t0\t%s\n' "$LIGNE_BAISSE" | w_baseline "$D"
out="$(run "$D")"; rc=$?
nodep=1; case "$out" in *"DEPASSEMENT"*) nodep=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$nodep" -eq 1 ]; then ok "BOOT-2b — ligne strictement superieure a la mesure (baisse), armee → rc 0, aucune occurrence de DEPASSEMENT"; else ko "BOOT-2b — baisse" "rc=0, aucun DEPASSEMENT" "rc=$rc out=[$out]"; fi

# --- BOOT-2c : description allongee de 8 octets, baseline = mesure ORIGINALE, armee → rc 1, -------
# --- DEPASSEMENT-BOOTSTRAP ; meme croissance SANS sentinelle → rc 3 (contrat existant du ratchet) -
D="$(mk_root boot2c-croissance)"
w_bootstrap_fixture "$D"
EXPECTED_BYTES="$(boot_expected_total)"
EXPECTED_TOKENS=$((EXPECTED_BYTES / 4))
# Allonge la description de dep de 8 octets exacts (" gagnee!" = 8 caracteres).
w_lines "$D/plugin/dep/SKILL.md" \
  '---' \
  'name: dep-demo' \
  'description: une description de dep gagnee!' \
  'when_to_use: quand on a besoin de dep' \
  '---' \
  'Corps de dep.'
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n@bootstrap:socle\t0\t%s\n' "$EXPECTED_TOKENS" | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"DEPASSEMENT-BOOTSTRAP"*) has=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "BOOT-2c — description allongee de 8 octets, baseline = mesure originale, armee → rc 1, DEPASSEMENT-BOOTSTRAP"; else ko "BOOT-2c — croissance armee" "rc=1, DEPASSEMENT-BOOTSTRAP" "rc=$rc out=[$out]"; fi

D="$(mk_root boot2c-non-arme)"
w_bootstrap_fixture "$D"
EXPECTED_BYTES="$(boot_expected_total)"
EXPECTED_TOKENS=$((EXPECTED_BYTES / 4))
w_lines "$D/plugin/dep/SKILL.md" \
  '---' \
  'name: dep-demo' \
  'description: une description de dep gagnee!' \
  'when_to_use: quand on a besoin de dep' \
  '---' \
  'Corps de dep.'
printf 'plugin/demo/agents/a.md\t4\t1\n@bootstrap:socle\t0\t%s\n' "$EXPECTED_TOKENS" | w_baseline "$D"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 3 ]; then ok "BOOT-2c (non arme) — meme croissance SANS sentinelle → rc 3 (contrat existant du ratchet)"; else ko "BOOT-2c non arme" "rc=3" "rc=$rc out=[$out]"; fi

# --- BOOT-2d : ligne @bootstrap:socle ABSENTE, ratchet arme → rc 2 (contrat de baseline incomplet)
D="$(mk_root boot2d-ligne-absente)"
w_bootstrap_fixture "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 2 ]; then ok "BOOT-2d — ligne @bootstrap:socle absente, ratchet arme → rc 2"; else ko "BOOT-2d — ligne absente armee" "rc=2" "rc=$rc out=[$out]"; fi

# --- BOOT-2e : la ligne @bootstrap:socle n'est JAMAIS comptee comme orpheline (cas BOOT-2a rejoue,
# --- verification explicite de l'absence du message d'orpheline) ----------------------------------
D="$(mk_root boot2e-jamais-orpheline)"
w_bootstrap_fixture "$D"
EXPECTED_BYTES="$(boot_expected_total)"
EXPECTED_TOKENS=$((EXPECTED_BYTES / 4))
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n@bootstrap:socle\t0\t%s\n' "$EXPECTED_TOKENS" | w_baseline "$D"
out="$(run "$D")"; rc=$?
noorph=1; case "$out" in *"entree de baseline orpheline : @bootstrap:socle"*) noorph=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$noorph" -eq 1 ]; then ok "BOOT-2e — la ligne @bootstrap:socle n'est jamais comptee comme orpheline"; else ko "BOOT-2e — jamais orpheline" "rc=0, aucun message d'orpheline sur @bootstrap:socle" "rc=$rc out=[$out]"; fi

# --- BOOT-3 : fixture SANS plugin/conductor/module.json (cas des sept bascules de la CI) → --------
# --- BOOTSTRAP non applicable, rc et verdicts identiques a la Tache 1 ------------------------------
D="$(mk_root boot3-sans-socle)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"BOOTSTRAP : non applicable"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "BOOT-3 — fixture sans plugin/conductor/module.json → BOOTSTRAP non applicable, rc et verdicts identiques a la Tache 1"; else ko "BOOT-3 — sans socle" "rc=0, BOOTSTRAP : non applicable" "rc=$rc out=[$out]"; fi

# --- BOOT-4 : socle present, resolveur (resolve-deps.sh) ABSENT → NON-VERIFIABLE avec la cause, ---
# --- rc 2 --------------------------------------------------------------------------------------
D="$(mk_root boot4-resolveur-absent)"
w_bootstrap_fixture "$D"
rm -f "$D/plugin/_internal/resolve-deps.sh"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n@bootstrap:socle\t0\t100\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"BOOTSTRAP"*"non verifiable"*"resolveur absent"*) has=1 ;; esac
if [ "$rc" -eq 2 ] && [ "$has" -eq 1 ]; then ok "BOOT-4 — resolveur (resolve-deps.sh) absent, socle present → rc 2, NON-VERIFIABLE avec la cause"; else ko "BOOT-4 — resolveur absent" "rc=2, cause resolveur absent nommee" "rc=$rc out=[$out]"; fi

# --- BOOT-5a : mesure > 2000, ligne @bootstrap:socle EGALE a la mesure, armee → rc 0, ---------------
# --- AU-DESSUS-PLAFOND-ADR029, aucune occurrence de DEPASSEMENT -----------------------------------
D="$(mk_root boot5a-plafond-egale)"
w_bootstrap_fixture_big "$D" 150
EXPECTED_BYTES="$(boot_expected_total_big 150)"
EXPECTED_TOKENS=$((EXPECTED_BYTES / 4))
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n@bootstrap:socle\t0\t%s\n' "$EXPECTED_TOKENS" | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"AU-DESSUS-PLAFOND-ADR029"*) has=1 ;; esac
nodep=1; case "$out" in *"DEPASSEMENT"*) nodep=0 ;; esac
depasse2000=0; [ "$EXPECTED_TOKENS" -gt 2000 ] && depasse2000=1
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ] && [ "$nodep" -eq 1 ] && [ "$depasse2000" -eq 1 ]; then
  ok "BOOT-5a — mesure > 2000 ($EXPECTED_TOKENS), ligne egale a la mesure, armee → rc 0, AU-DESSUS-PLAFOND-ADR029, aucun DEPASSEMENT"
else
  ko "BOOT-5a — plafond, ligne egale" "rc=0, AU-DESSUS-PLAFOND-ADR029, aucun DEPASSEMENT, mesure>2000" "rc=$rc mesure=$EXPECTED_TOKENS out=[$out]"
fi

# --- BOOT-5b : mesure > 2000, ligne STRICTEMENT SUPERIEURE a la mesure, armee → rc 0, --------------
# --- AU-DESSUS-PLAFOND-ADR029, aucune occurrence de DEPASSEMENT -----------------------------------
D="$(mk_root boot5b-plafond-superieure)"
w_bootstrap_fixture_big "$D" 150
EXPECTED_BYTES="$(boot_expected_total_big 150)"
EXPECTED_TOKENS=$((EXPECTED_BYTES / 4))
LIGNE_SUP=$((EXPECTED_TOKENS + 10))
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n@bootstrap:socle\t0\t%s\n' "$LIGNE_SUP" | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"AU-DESSUS-PLAFOND-ADR029"*) has=1 ;; esac
nodep=1; case "$out" in *"DEPASSEMENT"*) nodep=0 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ] && [ "$nodep" -eq 1 ]; then
  ok "BOOT-5b — mesure > 2000, ligne strictement superieure a la mesure, armee → rc 0, AU-DESSUS-PLAFOND-ADR029, aucun DEPASSEMENT"
else
  ko "BOOT-5b — plafond, ligne superieure" "rc=0, AU-DESSUS-PLAFOND-ADR029, aucun DEPASSEMENT" "rc=$rc out=[$out]"
fi

# --- BOOT-5c : mesure ≤ 2000 et ≤ ligne → verdict OK (contre-cas de BOOT-5a/b) ---------------------
D="$(mk_root boot5c-sous-plafond)"
w_bootstrap_fixture "$D"
EXPECTED_BYTES="$(boot_expected_total)"
EXPECTED_TOKENS=$((EXPECTED_BYTES / 4))
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n@bootstrap:socle\t0\t%s\n' "$EXPECTED_TOKENS" | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"BOOTSTRAP :"*"verdict OK"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then ok "BOOT-5c — mesure <= 2000 et <= ligne → verdict OK"; else ko "BOOT-5c — sous plafond" "rc=0, verdict OK" "rc=$rc out=[$out]"; fi

# --- BOOT-6 : plugin.json "skills" porte un "/" final ("./installer/") → normalise, l'installer ---
# --- reste compte dans le socle exactement comme sans "/" final (correctif revue 43-04, mineur) ---
D="$(mk_root boot6-slash-final)"
w_bootstrap_fixture "$D"
w_lines "$D/plugin/.claude-plugin/plugin.json" '{' '  "skills": "./installer/"' '}'
EXPECTED_BYTES="$(boot_expected_total)"
EXPECTED_TOKENS=$((EXPECTED_BYTES / 4))
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n@bootstrap:socle\t0\t%s\n' "$EXPECTED_TOKENS" | w_baseline "$D"
out="$(run "$D")"; rc=$?
gotline="$(printf '%s\n' "$out" | grep '^BOOTSTRAP :')"
has=0; case "$gotline" in *"$EXPECTED_TOKENS tokens"*"sur socle (4 fichiers)"*) has=1 ;; esac
if [ "$rc" -eq 0 ] && [ "$has" -eq 1 ]; then
  ok "BOOT-6 — plugin.json \"skills\" avec / final (./installer/) → normalise, installer compte comme sans / final ($EXPECTED_TOKENS tokens, 4 fichiers)"
else
  ko "BOOT-6 — / final normalise" "rc=0, BOOTSTRAP : $EXPECTED_TOKENS tokens ... sur socle (4 fichiers)" "rc=$rc out=[$out]"
fi

# ===================================================================================================
# Tâche 2 — quatre mutants vérifiés par cmp
# ===================================================================================================
echo ""
echo "== mutants =="

MUTD="$TMP/mutants"; mkdir -p "$MUTD"

# --- MUT-1 : neutralise la comparaison de la metrique INSTRUCTIONS a sa baseline ------------------
MUT1_OLD='    [ "$instr" -gt "$bl_instr" ] && instr_over=1'
MUT1_NEW='    [ "0" -eq "1" ] && instr_over=1'
awk -v old="$MUT1_OLD" -v new="$MUT1_NEW" '{ if ($0 == old) { print new } else { print } }' "$SCRIPT" > "$MUTD/mut1-instr.sh"
D="$(mk_root mut1)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t0\n' | w_baseline "$D"
if cmp -s "$MUTD/mut1-instr.sh" "$SCRIPT"; then
  ko "MUT-1 comparaison INSTRUCTIONS neutralisee" "mutation differente de l'original (cmp)" "mutant identique a l'original — NON OPPOSABLE"
elif ! bash -n "$MUTD/mut1-instr.sh" 2>/dev/null; then
  ko "MUT-1 comparaison INSTRUCTIONS neutralisee" "bash -n OK sur le mutant" "syntaxe invalide — pas une preuve"
else
  TARGET="$MUTD/mut1-instr.sh"; run "$D" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then
    ok "MUT-1 comparaison INSTRUCTIONS neutralisee (cmp confirme la mutation, bash -n OK) : fixture en depassement d'instructions reste (a tort) VERTE sur le mutant (rc=$rc_mut), ROUGE sur l'original (rc=$rc_orig)"
  else
    ko "MUT-1 comparaison INSTRUCTIONS neutralisee" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"
  fi
fi

# --- MUT-2 (REMPLACE, Phase 40.1) : re-introduit la comparaison des LIGNES comme verdict bloquant,
# --- alors que D-02/D-H6 exigent qu'elle reste purement informative --------------------------------
MUT2_OLD='    [ "$lines" -gt "$bl_lines" ] && verdict="${verdict}+LIGNES-EN-HAUSSE"'
MUT2_NEW='    [ "$lines" -gt "$bl_lines" ] && verdict="DEPASSEMENT-LIGNES"'
awk -v old="$MUT2_OLD" -v new="$MUT2_NEW" '{ if ($0 == old) { print new } else { print } }' "$SCRIPT" > "$MUTD/mut2-lignes.sh"
D="$(mk_root mut2)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t3\t1\n' | w_baseline "$D"
if cmp -s "$MUTD/mut2-lignes.sh" "$SCRIPT"; then
  ko "MUT-2 comparaison LIGNES re-introduite comme bloquante" "mutation differente de l'original (cmp)" "mutant identique a l'original — NON OPPOSABLE"
elif ! bash -n "$MUTD/mut2-lignes.sh" 2>/dev/null; then
  ko "MUT-2 comparaison LIGNES re-introduite comme bloquante" "bash -n OK sur le mutant" "syntaxe invalide — pas une preuve"
else
  TARGET="$MUTD/mut2-lignes.sh"; run "$D" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then
    ok "MUT-2 comparaison LIGNES re-introduite comme bloquante (cmp confirme la mutation, bash -n OK) : fixture lignes en hausse sans instruction devient (a tort) ROUGE sur le mutant (rc=$rc_mut), VERTE sur l'original (rc=$rc_orig)"
  else
    ko "MUT-2 comparaison LIGNES re-introduite comme bloquante" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"
  fi
fi

# --- MUT-3 : force la lecture de la sentinelle a "non arme" (ARMED reste 0 meme sentinelle posee) -
MUT3_OLD='[ -f "$SENTINEL" ] && ARMED=1'
MUT3_NEW='[ -f "/nonexistent-mut3-sentinel-path" ] && ARMED=1'
awk -v old="$MUT3_OLD" -v new="$MUT3_NEW" '{ if ($0 == old) { print new } else { print } }' "$SCRIPT" > "$MUTD/mut3-sentinelle.sh"
D="$(mk_root mut3)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t0\n' | w_baseline "$D"
if cmp -s "$MUTD/mut3-sentinelle.sh" "$SCRIPT"; then
  ko "MUT-3 lecture de la sentinelle neutralisee" "mutation differente de l'original (cmp)" "mutant identique a l'original — NON OPPOSABLE"
elif ! bash -n "$MUTD/mut3-sentinelle.sh" 2>/dev/null; then
  ko "MUT-3 lecture de la sentinelle neutralisee" "bash -n OK sur le mutant" "syntaxe invalide — pas une preuve"
else
  TARGET="$MUTD/mut3-sentinelle.sh"; run "$D" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 3 ] && [ "$rc_orig" -eq 1 ]; then
    ok "MUT-3 lecture de la sentinelle neutralisee (cmp confirme la mutation, bash -n OK) : le gate se croit non arme et n'ose plus bloquer (rc_mutant=$rc_mut au lieu de 1), original ROUGE (rc=$rc_orig)"
  else
    ko "MUT-3 lecture de la sentinelle neutralisee" "rc_mutant=3 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"
  fi
fi

# --- MUT-4 : neutralise la detection du frontmatter jamais referme (imparsable) -------------------
MUT4_OLD='  if [ "$fm_state" = "open" ]; then'
MUT4_NEW='  if [ "$fm_state" = "jamais-egal-mut4" ]; then'
awk -v old="$MUT4_OLD" -v new="$MUT4_NEW" '{ if ($0 == old) { print new } else { print } }' "$SCRIPT" > "$MUTD/mut4-imparsable.sh"
D="$(mk_root mut4)"
w_lines "$D/plugin/demo/agents/a.md" \
  '---' \
  'name: demo' \
  'Corps sans frontmatter jamais referme.'
if cmp -s "$MUTD/mut4-imparsable.sh" "$SCRIPT"; then
  ko "MUT-4 detection du frontmatter imparsable neutralisee" "mutation differente de l'original (cmp)" "mutant identique a l'original — NON OPPOSABLE"
elif ! bash -n "$MUTD/mut4-imparsable.sh" 2>/dev/null; then
  ko "MUT-4 detection du frontmatter imparsable neutralisee" "bash -n OK sur le mutant" "syntaxe invalide — pas une preuve"
else
  TARGET="$MUTD/mut4-imparsable.sh"; run "$D" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -ne 2 ] && [ "$rc_orig" -eq 2 ]; then
    ok "MUT-4 detection du frontmatter imparsable neutralisee (cmp confirme la mutation, bash -n OK) : le fichier a frontmatter jamais referme n'est plus NON-VERIFIABLE (rc_mutant=$rc_mut, different de 2), original ROUGE (rc=$rc_orig)"
  else
    ko "MUT-4 detection du frontmatter imparsable neutralisee" "rc_mutant different de 2, rc_original=2" "rc_mutant=$rc_mut rc_original=$rc_orig"
  fi
fi

# --- MUT-5 : fait tomber l'avertissement de zone dans un libellé bloquant (DEPASSEMENT-*) ---------
MUT5_OLD='    verdict="${verdict}+AVERTISSEMENT-ADR029"'
MUT5_NEW='    verdict="DEPASSEMENT-AVERTISSEMENT"'
awk -v old="$MUT5_OLD" -v new="$MUT5_NEW" '{ if ($0 == old) { print new } else { print } }' "$SCRIPT" > "$MUTD/mut5-avertissement.sh"
D="$(mk_root mut5)"
gen_lines "$D/plugin/demo/agents/a.md" 260
w_armed "$D"
printf 'plugin/demo/agents/a.md\t260\t0\n' | w_baseline "$D"
if cmp -s "$MUTD/mut5-avertissement.sh" "$SCRIPT"; then
  ko "MUT-5 avertissement de zone rendu bloquant" "mutation differente de l'original (cmp)" "mutant identique a l'original — NON OPPOSABLE"
elif ! bash -n "$MUTD/mut5-avertissement.sh" 2>/dev/null; then
  ko "MUT-5 avertissement de zone rendu bloquant" "bash -n OK sur le mutant" "syntaxe invalide — pas une preuve"
else
  TARGET="$MUTD/mut5-avertissement.sh"; run "$D" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then
    ok "MUT-5 avertissement de zone rendu bloquant (cmp confirme la mutation, bash -n OK) : fixture 260/260/0 devient (a tort) ROUGE sur le mutant (rc=$rc_mut), VERTE sur l'original (rc=$rc_orig)"
  else
    ko "MUT-5 avertissement de zone rendu bloquant" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"
  fi
fi

# --- MUT-6 : decale le plafond d'un cran ("-gt" -> "-ge") ------------------------------------------
MUT6_OLD='  if [ "$lines" -gt "$VF_BUDGET_LINE_CAP" ]; then'
MUT6_NEW='  if [ "$lines" -ge "$VF_BUDGET_LINE_CAP" ]; then'
awk -v old="$MUT6_OLD" -v new="$MUT6_NEW" '{ if ($0 == old) { print new } else { print } }' "$SCRIPT" > "$MUTD/mut6-plafond.sh"
D="$(mk_root mut6)"
gen_lines "$D/plugin/demo/agents/a.md" "$PLAFOND"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t%s\t0\n' "$PLAFOND" | w_baseline "$D"
if cmp -s "$MUTD/mut6-plafond.sh" "$SCRIPT"; then
  ko "MUT-6 plafond decale d'un cran" "mutation differente de l'original (cmp)" "mutant identique a l'original — NON OPPOSABLE"
elif ! bash -n "$MUTD/mut6-plafond.sh" 2>/dev/null; then
  ko "MUT-6 plafond decale d'un cran" "bash -n OK sur le mutant" "syntaxe invalide — pas une preuve"
else
  TARGET="$MUTD/mut6-plafond.sh"; run "$D" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then
    ok "MUT-6 plafond decale d'un cran (cmp confirme la mutation, bash -n OK) : fixture PLAFOND/PLAFOND/0 devient (a tort) ROUGE sur le mutant (rc=$rc_mut), VERTE sur l'original (rc=$rc_orig)"
  else
    ko "MUT-6 plafond decale d'un cran" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"
  fi
fi

# --- MUT-7 : decale le bord bas de la zone d'avertissement d'un cran ("-ge" -> "-gt") --------------
MUT7_OLD='  if [ "$verdict" != "DEPASSEMENT-ADR029" ] && [ "$lines" -ge "$VF_BUDGET_LINE_WARN_FROM" ] && [ "$lines" -le "$VF_BUDGET_LINE_CAP" ]; then'
MUT7_NEW='  if [ "$verdict" != "DEPASSEMENT-ADR029" ] && [ "$lines" -gt "$VF_BUDGET_LINE_WARN_FROM" ] && [ "$lines" -le "$VF_BUDGET_LINE_CAP" ]; then'
awk -v old="$MUT7_OLD" -v new="$MUT7_NEW" '{ if ($0 == old) { print new } else { print } }' "$SCRIPT" > "$MUTD/mut7-bord-avert.sh"
D="$(mk_root mut7)"
gen_lines "$D/plugin/demo/agents/a.md" "$BORNE_AVERT"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t%s\t0\n' "$BORNE_AVERT" | w_baseline "$D"
if cmp -s "$MUTD/mut7-bord-avert.sh" "$SCRIPT"; then
  ko "MUT-7 bord bas de la zone d'avertissement decale" "mutation differente de l'original (cmp)" "mutant identique a l'original — NON OPPOSABLE"
elif ! bash -n "$MUTD/mut7-bord-avert.sh" 2>/dev/null; then
  ko "MUT-7 bord bas de la zone d'avertissement decale" "bash -n OK sur le mutant" "syntaxe invalide — pas une preuve"
else
  TARGET="$MUTD/mut7-bord-avert.sh"; out_mut="$(run "$D")"; rc_mut=$?
  TARGET="$SCRIPT"; out_orig="$(run "$D")"; rc_orig=$?
  av_mut=0; case "$out_mut" in *"AVERTISSEMENT-ADR029"*) av_mut=1 ;; esac
  av_orig=0; case "$out_orig" in *"AVERTISSEMENT-ADR029"*) av_orig=1 ;; esac
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 0 ] && [ "$av_mut" -eq 0 ] && [ "$av_orig" -eq 1 ]; then
    ok "MUT-7 bord bas de la zone d'avertissement decale (cmp confirme la mutation, bash -n OK) : fixture BORNE_AVERT/BORNE_AVERT/0 perd (a tort) AVERTISSEMENT-ADR029 sur le mutant, le porte sur l'original"
  else
    ko "MUT-7 bord bas de la zone d'avertissement decale" "rc_mutant=0 rc_original=0, AVERTISSEMENT-ADR029 absent du mutant, present dans l'original" "rc_mutant=$rc_mut rc_original=$rc_orig av_mut=$av_mut av_orig=$av_orig"
  fi
fi

# --- MUT-8 : neutralise la comparaison du plafond SKILL.md ("$lines" -gt "$VF_SKILL_LINE_CAP") ----
MUT8_OLD='  if [ "$lines" -gt "$VF_SKILL_LINE_CAP" ]; then'
MUT8_NEW='  if [ "0" = "1" ]; then'
awk -v old="$MUT8_OLD" -v new="$MUT8_NEW" '{ if ($0 == old) { print new } else { print } }' "$SCRIPT" > "$MUTD/mut8-skill-plafond.sh"
D="$(mk_root mut8)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n' | w_baseline "$D"
mkdir -p "$D/plugin/demo/skills/s"
gen_lines "$D/plugin/demo/skills/s/SKILL.md" "$((PLAFOND_SKILL + 1))"
if cmp -s "$MUTD/mut8-skill-plafond.sh" "$SCRIPT"; then
  ko "MUT-8 plafond SKILL.md neutralise" "mutation differente de l'original (cmp)" "mutant identique a l'original — NON OPPOSABLE"
elif ! bash -n "$MUTD/mut8-skill-plafond.sh" 2>/dev/null; then
  ko "MUT-8 plafond SKILL.md neutralise" "bash -n OK sur le mutant" "syntaxe invalide — pas une preuve"
else
  TARGET="$MUTD/mut8-skill-plafond.sh"; run "$D" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then
    ok "MUT-8 plafond SKILL.md neutralise (cmp confirme la mutation, bash -n OK) : SKILL.md a PLAFOND_SKILL+1 lignes reste (a tort) VERT sur le mutant (rc=$rc_mut), ROUGE sur l'original (rc=$rc_orig)"
  else
    ko "MUT-8 plafond SKILL.md neutralise" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"
  fi
fi

# --- MUT-9 : neutralise la ligne d'exclusion doc-only (le module entier redevient scrute) ----------
MUT9_OLD='  if [ -f "${d}module.json" ] && grep -Eq '"'"'"type"[[:space:]]*:[[:space:]]*"doc-only"'"'"' "${d}module.json" 2>/dev/null; then'
MUT9_NEW='  if [ -f "${d}module.json" ] && grep -Eq '"'"'"type"[[:space:]]*:[[:space:]]*"mut9-neutralise"'"'"' "${d}module.json" 2>/dev/null; then'
awk -v old="$MUT9_OLD" -v new="$MUT9_NEW" '{ if ($0 == old) { print new } else { print } }' "$SCRIPT" > "$MUTD/mut9-doc-only.sh"
D="$(mk_root mut9)"
w_skill3_fixture "$D"
if cmp -s "$MUTD/mut9-doc-only.sh" "$SCRIPT"; then
  ko "MUT-9 exclusion doc-only neutralisee" "mutation differente de l'original (cmp)" "mutant identique a l'original — NON OPPOSABLE"
elif ! bash -n "$MUTD/mut9-doc-only.sh" 2>/dev/null; then
  ko "MUT-9 exclusion doc-only neutralisee" "bash -n OK sur le mutant" "syntaxe invalide — pas une preuve"
else
  TARGET="$MUTD/mut9-doc-only.sh"; run "$D" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then
    ok "MUT-9 exclusion doc-only neutralisee (cmp confirme la mutation, bash -n OK) : fixture SKILL-3 devient (a tort) ROUGE sur le mutant (rc=$rc_mut), VERTE sur l'original (rc=$rc_orig)"
  else
    ko "MUT-9 exclusion doc-only neutralisee" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"
  fi
fi

# --- MUT-10 : neutralise l'elagage des dossiers *-references (partie -references de SKILL-3) -------
MUT10_OLD='  find "$d" '"'"'('"'"' -type d -name '"'"'.*'"'"' -prune '"'"')'"'"' -o '"'"'('"'"' -type d -name '"'"'*-references'"'"' -prune '"'"')'"'"' -o '"'"'('"'"' -type f -name SKILL.md -print '"'"')'"'"' -o '"'"'('"'"' -type l -name SKILL.md -print '"'"')'"'"' 2>/dev/null | while IFS= read -r f; do'
MUT10_NEW='  find "$d" '"'"'('"'"' -type d -name '"'"'.*'"'"' -prune '"'"')'"'"' -o '"'"'('"'"' -type d -name '"'"'*-mut10-neutralise'"'"' -prune '"'"')'"'"' -o '"'"'('"'"' -type f -name SKILL.md -print '"'"')'"'"' -o '"'"'('"'"' -type l -name SKILL.md -print '"'"')'"'"' 2>/dev/null | while IFS= read -r f; do'
awk -v old="$MUT10_OLD" -v new="$MUT10_NEW" '{ if ($0 == old) { print new } else { print } }' "$SCRIPT" > "$MUTD/mut10-references.sh"
D="$(mk_root mut10)"
w_skill3_fixture "$D"
if cmp -s "$MUTD/mut10-references.sh" "$SCRIPT"; then
  ko "MUT-10 elagage *-references neutralise" "mutation differente de l'original (cmp)" "mutant identique a l'original — NON OPPOSABLE"
elif ! bash -n "$MUTD/mut10-references.sh" 2>/dev/null; then
  ko "MUT-10 elagage *-references neutralise" "bash -n OK sur le mutant" "syntaxe invalide — pas une preuve"
else
  TARGET="$MUTD/mut10-references.sh"; run "$D" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then
    ok "MUT-10 elagage *-references neutralise (cmp confirme la mutation, bash -n OK) : fixture SKILL-3 (partie -references) devient (a tort) ROUGE sur le mutant (rc=$rc_mut), VERTE sur l'original (rc=$rc_orig)"
  else
    ko "MUT-10 elagage *-references neutralise" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"
  fi
fi

# --- MUT-11 : neutralise la comparaison de la mesure a la ligne @bootstrap:socle -------------------
MUT11_OLD='  if [ "$BOOTSTRAP_HAS_BASELINE" -eq 1 ] && [ "$BOOTSTRAP_TOKENS" -gt "$BOOTSTRAP_BASELINE_VALUE" ]; then'
MUT11_NEW='  if [ "0" = "1" ] && [ "$BOOTSTRAP_TOKENS" -gt "$BOOTSTRAP_BASELINE_VALUE" ]; then'
awk -v old="$MUT11_OLD" -v new="$MUT11_NEW" '{ if ($0 == old) { print new } else { print } }' "$SCRIPT" > "$MUTD/mut11-bootstrap-cmp.sh"
D="$(mk_root mut11)"
w_bootstrap_fixture "$D"
EXPECTED_BYTES="$(boot_expected_total)"
EXPECTED_TOKENS=$((EXPECTED_BYTES / 4))
w_lines "$D/plugin/dep/SKILL.md" \
  '---' \
  'name: dep-demo' \
  'description: une description de dep gagnee!' \
  'when_to_use: quand on a besoin de dep' \
  '---' \
  'Corps de dep.'
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n@bootstrap:socle\t0\t%s\n' "$EXPECTED_TOKENS" | w_baseline "$D"
if cmp -s "$MUTD/mut11-bootstrap-cmp.sh" "$SCRIPT"; then
  ko "MUT-11 comparaison bootstrap neutralisee" "mutation differente de l'original (cmp)" "mutant identique a l'original — NON OPPOSABLE"
elif ! bash -n "$MUTD/mut11-bootstrap-cmp.sh" 2>/dev/null; then
  ko "MUT-11 comparaison bootstrap neutralisee" "bash -n OK sur le mutant" "syntaxe invalide — pas une preuve"
else
  TARGET="$MUTD/mut11-bootstrap-cmp.sh"; run "$D" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then
    ok "MUT-11 comparaison bootstrap neutralisee (cmp confirme la mutation, bash -n OK) : fixture de croissance BOOT-2 reste (a tort) VERTE sur le mutant (rc=$rc_mut), ROUGE sur l'original (rc=$rc_orig)"
  else
    ko "MUT-11 comparaison bootstrap neutralisee" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"
  fi
fi

# --- MUT-12 : meme ligne de comparaison, -gt (tokens > ligne) reecrit en -ne (tokens != ligne) -----
MUT12_OLD='  if [ "$BOOTSTRAP_HAS_BASELINE" -eq 1 ] && [ "$BOOTSTRAP_TOKENS" -gt "$BOOTSTRAP_BASELINE_VALUE" ]; then'
MUT12_NEW='  if [ "$BOOTSTRAP_HAS_BASELINE" -eq 1 ] && [ "$BOOTSTRAP_TOKENS" -ne "$BOOTSTRAP_BASELINE_VALUE" ]; then'
awk -v old="$MUT12_OLD" -v new="$MUT12_NEW" '{ if ($0 == old) { print new } else { print } }' "$SCRIPT" > "$MUTD/mut12-bootstrap-ne.sh"
D="$(mk_root mut12)"
w_bootstrap_fixture "$D"
EXPECTED_BYTES="$(boot_expected_total)"
EXPECTED_TOKENS=$((EXPECTED_BYTES / 4))
LIGNE_BAISSE=$((EXPECTED_TOKENS + 5))
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n@bootstrap:socle\t0\t%s\n' "$LIGNE_BAISSE" | w_baseline "$D"
if cmp -s "$MUTD/mut12-bootstrap-ne.sh" "$SCRIPT"; then
  ko "MUT-12 comparaison bootstrap -gt reecrite en -ne" "mutation differente de l'original (cmp)" "mutant identique a l'original — NON OPPOSABLE"
elif ! bash -n "$MUTD/mut12-bootstrap-ne.sh" 2>/dev/null; then
  ko "MUT-12 comparaison bootstrap -gt reecrite en -ne" "bash -n OK sur le mutant" "syntaxe invalide — pas une preuve"
else
  TARGET="$MUTD/mut12-bootstrap-ne.sh"; run "$D" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 1 ] && [ "$rc_orig" -eq 0 ]; then
    ok "MUT-12 comparaison bootstrap -gt reecrite en -ne (cmp confirme la mutation, bash -n OK) : fixture de baisse BOOT-2 devient (a tort) ROUGE sur le mutant (rc=$rc_mut), VERTE sur l'original (rc=$rc_orig) — le mutant prend une baisse pour un depassement"
  else
    ko "MUT-12 comparaison bootstrap -gt reecrite en -ne" "rc_mutant=1 rc_original=0" "rc_mutant=$rc_mut rc_original=$rc_orig"
  fi
fi

# old_oracle_bytes_mutated <fichier> <cles> -> octets, RECONSTRUCTION JETABLE de l'ANCIEN oracle
# tautologique (avant le correctif 43-04), a laquelle la MEME mutation que MUT13_NEW ci-dessous a
# ete appliquee a la main (une continuation qui ne matche jamais) — utilisee UNIQUEMENT pour
# prouver la tautologie de MUT-13, jamais reintroduite comme oracle de production. Hardcodee (pas
# de substitution de texte a l'execution) pour rester simple et portable.
old_oracle_bytes_mutated() {
  local f="$1" keys="$2"
  [ -r "$f" ] || { echo 0; return; }
  LC_ALL=C awk -v keys="$keys" '
    BEGIN {
      started = 0; in_fm = 0; measuring = 0; bytes = 0
      n = split(keys, karr, "|")
      for (i = 1; i <= n; i++) keyset[karr[i]] = 1
    }
    NR==1 && /^---[[:space:]]*$/ { started = 1; in_fm = 1; next }
    in_fm && /^---[[:space:]]*$/ { in_fm = 0; next }
    !started { next }
    in_fm {
      if ($0 ~ /^[A-Za-z_][A-Za-z0-9_.-]*:/) {
        key = $0
        sub(/:.*$/, "", key)
        if (key in keyset) { measuring = 1; bytes += length($0) + 1 } else { measuring = 0 }
      } else if ($0 ~ /^JAMAIS-MUT13-NE-MATCHE-RIEN/) {
        if (measuring) { bytes += length($0) + 1 }
      } else {
        measuring = 0
      }
    }
    END { print bytes + 0 }
  ' "$f" 2>/dev/null
}

# --- MUT-13 : neutralise la continuation de ligne dans bootstrap_measure_file (correctif revue ----
# --- 43-04, finding majeur) — preuve que boot_expected_total (calcul litteral independant) --------
# --- DISCRIMINE un bug niche dans l'algorithme de mesure lui-meme, la ou l'ancien boot_expected_bytes
# --- (recopie de bootstrap_measure_file) restait aveugle puisqu'il partageait le meme bug. ---------
# Backslash double (\\t) : passe par "awk -v old=...", qui interprete les echappements — \\t
# redevient \t (deux caracteres, backslash+t) apres cette interpretation, pour matcher au
# caractere pres le texte reel du script (meme piege que documente pour count_instructions()).
MUT13_OLD='      } else if ($0 ~ /^[ \\t]/) {'
MUT13_NEW='      } else if ($0 ~ /^JAMAIS-MUT13-NE-MATCHE-RIEN/) {'
awk -v old="$MUT13_OLD" -v new="$MUT13_NEW" '{ if ($0 == old) { print new } else { print } }' "$SCRIPT" > "$MUTD/mut13-continuation.sh"
D="$(mk_root mut13)"
w_bootstrap_fixture "$D"
EXPECTED_BYTES="$(boot_expected_total)"
EXPECTED_TOKENS=$((EXPECTED_BYTES / 4))
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n@bootstrap:socle\t0\t%s\n' "$EXPECTED_TOKENS" | w_baseline "$D"
if cmp -s "$MUTD/mut13-continuation.sh" "$SCRIPT"; then
  ko "MUT-13 continuation de bootstrap_measure_file neutralisee" "mutation differente de l'original (cmp)" "mutant identique a l'original — NON OPPOSABLE"
elif ! bash -n "$MUTD/mut13-continuation.sh" 2>/dev/null; then
  ko "MUT-13 continuation de bootstrap_measure_file neutralisee" "bash -n OK sur le mutant" "syntaxe invalide — pas une preuve"
else
  TARGET="$MUTD/mut13-continuation.sh"; out_mut="$(run "$D")"; rc_mut=$?
  mutline="$(printf '%s\n' "$out_mut" | grep '^BOOTSTRAP :')"
  # Le nouvel oracle (litteral, independant) reste fixe a EXPECTED_TOKENS quoi qu'il arrive au
  # script : le mutant qui ne compte plus la continuation doit rendre un total different, jamais
  # la meme valeur (sinon le mutant n'a pas ete opposable sur CETTE fixture).
  sous_compte=0
  case "$mutline" in *"$EXPECTED_TOKENS tokens"*) : ;; *) sous_compte=1 ;; esac
  # La MEME mutation appliquee (a la main, hardcodee) a l'ANCIEN oracle tautologique : si l'ancien
  # oracle avait ete utilise comme "independant", il aurait undercompte EXACTEMENT comme le
  # script mutant — les deux se neutralisent, l'ecart disparait, preuve de la tautologie.
  old_oracle_conductor="$(old_oracle_bytes_mutated "$D/plugin/conductor/SKILL.md" "name|description|when_to_use")"
  old_oracle_dep="$(old_oracle_bytes_mutated "$D/plugin/dep/SKILL.md" "name|description|when_to_use")"
  old_oracle_installer="$(old_oracle_bytes_mutated "$D/plugin/installer/SKILL.md" "name|description|when_to_use")"
  old_oracle_cmd="$(old_oracle_bytes_mutated "$D/plugin/commands/c.md" "description|when_to_use")"
  old_oracle_total=$((old_oracle_conductor + old_oracle_dep + old_oracle_installer + old_oracle_cmd))
  old_oracle_tokens=$((old_oracle_total / 4))
  old_oracle_matched_mutant=0
  case "$mutline" in *"$old_oracle_tokens tokens"*) old_oracle_matched_mutant=1 ;; esac
  if [ "$sous_compte" -eq 1 ] && [ "$old_oracle_matched_mutant" -eq 1 ]; then
    ok "MUT-13 continuation de bootstrap_measure_file neutralisee (cmp confirme la mutation, bash -n OK) : boot_expected_total (litteral, independant) rougit pour la BONNE raison — attendu=$EXPECTED_TOKENS tokens, obtenu=[$mutline] ; la MEME mutation appliquee a l'ANCIEN oracle (recopie) produit exactement le meme sous-compte ($old_oracle_tokens tokens), preuve que l'ancien oracle serait reste vert en tautologie"
  else
    ko "MUT-13 continuation neutralisee" "mutant sous-compte face au nouvel oracle (sous_compte=1), ancien oracle mute reproduit le meme sous-compte (old_oracle_matched_mutant=1)" "sous_compte=$sous_compte old_oracle_matched_mutant=$old_oracle_matched_mutant mutline=[$mutline] old_oracle_tokens=$old_oracle_tokens"
  fi
fi

TARGET="$SCRIPT"

# --- Garde finale : le script vivant reste syntaxiquement intact apres le bloc de mutations -------
if bash -n "$SCRIPT" 2>/dev/null; then
  ok "garde finale — le script vivant reste syntaxiquement intact apres le bloc de mutations"
else
  ko "garde finale — le script vivant reste syntaxiquement intact apres le bloc de mutations" "bash -n OK" "bash -n echoue"
fi

echo ""
echo "== resultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
