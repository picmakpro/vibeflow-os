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
# Quatre mutants OPPOSABLES vérifiés par cmp (D-05 : les DEUX métriques ont chacune le leur) :
#   - MUT-1 neutralise la comparaison de la métrique INSTRUCTIONS à sa baseline.
#   - MUT-2 neutralise la comparaison de la métrique LIGNES à sa baseline.
#   - MUT-3 force la lecture de la sentinelle à « non armé » (ARMED reste 0 même sentinelle posée).
#   - MUT-4 neutralise la détection du frontmatter jamais refermé (imparsable).
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

# gen_251 <path> — génère un fichier de 251 lignes : frontmatter 3 lignes + 248 lignes de corps
# sans aucun marqueur textuel (instr=0 par construction, seule la métrique LIGNES est en jeu ici).
gen_251() {
  {
    printf '%s\n' '---' 'name: demo-cap' '---'
    local i=1
    while [ "$i" -le 248 ]; do
      printf 'Ligne de corps numero %s, sans marqueur textuel.\n' "$i"
      i=$((i + 1))
    done
  } > "$1"
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

# --- Issue FAIL (lignes) : baseline lignes abaissée d'une unité → rc 1, DEPASSEMENT-LIGNES -------
D="$(mk_root fail-lignes)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t3\t1\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"DEPASSEMENT-LIGNES"*) has=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "issue QUAL-01 FAIL (lignes) — baseline abaissee d'une unite → rc 1, DEPASSEMENT-LIGNES"; else ko "issue QUAL-01 FAIL (lignes) — baseline abaissee d'une unite → rc 1, DEPASSEMENT-LIGNES" "rc=1 verdict DEPASSEMENT-LIGNES" "rc=$rc out=[$out]"; fi

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

# --- plafond absolu ADR029 : fichier 251 lignes ET baseline de lignes = 251 → rc 1, la baseline ---
# --- ne legalise jamais un depassement du plafond -------------------------------------------------
D="$(mk_root plafond-adr029)"
gen_251 "$D/plugin/demo/agents/big.md"
w_armed "$D"
printf 'plugin/demo/agents/big.md\t251\t0\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
has=0; case "$out" in *"plugin/demo/agents/big.md"*"DEPASSEMENT-ADR029"*) has=1 ;; esac
if [ "$rc" -eq 1 ] && [ "$has" -eq 1 ]; then ok "plafond absolu ADR029 — 251 lignes, baseline egale a 251 → rc 1, DEPASSEMENT-ADR029 (la baseline ne prime jamais sur le plafond)"; else ko "plafond absolu ADR029 — 251 lignes, baseline egale a 251 → rc 1, DEPASSEMENT-ADR029 (la baseline ne prime jamais sur le plafond)" "rc=1, ligne DEPASSEMENT-ADR029" "rc=$rc out=[$out]"; fi

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

# --- F3 : fichier > 250 lignes ET sans entree de baseline, mode arme → rc 2 (contrat de couverture
# --- incomplete), PAS 1 (avant : DEPASSEMENT-ADR029 masquait SANS-BASELINE et rendait 1) ----------
D="$(mk_root f3-sans-baseline-armee)"
std_agent "$D"
gen_251 "$D/plugin/demo/agents/big.md"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t4\t1\n' | w_baseline "$D"
out="$(run "$D")"; rc=$?
if [ "$rc" -eq 2 ]; then ok "F3 non-regression — fichier >250 lignes SANS entree de baseline, mode arme → rc 2 (jamais 1, DEPASSEMENT-ADR029 ne masque plus SANS-BASELINE)"; else ko "F3 non-regression — fichier >250 lignes SANS entree de baseline, mode arme → rc 2 (jamais 1, DEPASSEMENT-ADR029 ne masque plus SANS-BASELINE)" "rc=2" "rc=$rc out=[$out]"; fi

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

# --- MUT-2 : neutralise la comparaison de la metrique LIGNES a sa baseline ------------------------
MUT2_OLD='    [ "$lines" -gt "$bl_lines" ] && line_over=1'
MUT2_NEW='    [ "0" -eq "1" ] && line_over=1'
awk -v old="$MUT2_OLD" -v new="$MUT2_NEW" '{ if ($0 == old) { print new } else { print } }' "$SCRIPT" > "$MUTD/mut2-lignes.sh"
D="$(mk_root mut2)"
std_agent "$D"
w_armed "$D"
printf 'plugin/demo/agents/a.md\t3\t1\n' | w_baseline "$D"
if cmp -s "$MUTD/mut2-lignes.sh" "$SCRIPT"; then
  ko "MUT-2 comparaison LIGNES neutralisee" "mutation differente de l'original (cmp)" "mutant identique a l'original — NON OPPOSABLE"
elif ! bash -n "$MUTD/mut2-lignes.sh" 2>/dev/null; then
  ko "MUT-2 comparaison LIGNES neutralisee" "bash -n OK sur le mutant" "syntaxe invalide — pas une preuve"
else
  TARGET="$MUTD/mut2-lignes.sh"; run "$D" >/dev/null 2>&1; rc_mut=$?
  TARGET="$SCRIPT"; run "$D" >/dev/null 2>&1; rc_orig=$?
  if [ "$rc_mut" -eq 0 ] && [ "$rc_orig" -eq 1 ]; then
    ok "MUT-2 comparaison LIGNES neutralisee (cmp confirme la mutation, bash -n OK) : fixture en depassement de lignes reste (a tort) VERTE sur le mutant (rc=$rc_mut), ROUGE sur l'original (rc=$rc_orig)"
  else
    ko "MUT-2 comparaison LIGNES neutralisee" "rc_mutant=0 rc_original=1" "rc_mutant=$rc_mut rc_original=$rc_orig"
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
