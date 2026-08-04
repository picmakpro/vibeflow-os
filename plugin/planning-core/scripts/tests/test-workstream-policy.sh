#!/usr/bin/env bash
# test-workstream-policy.sh — La politique de nom de workstream est-elle UNIQUE, conforme au moteur
# amont, et appliquee A L'IDENTIQUE par les quatre gates qui la consomment ?
#
# POURQUOI CETTE SUITE EXISTE : quatre gates portaient chacun sa COPIE de la politique, en DEUX
# variantes divergentes, et aucune des deux n'etait conforme au moteur. Sur un arbre identique,
# « workstream resolu mais dossier absent » produisait QUATRE verdicts differents. Les copies ont
# diverge en UN SEUL lot de travail parallele : rien n'empeche que cela recommence, sauf une mesure.
# Cette suite est cette mesure. Elle verifie trois choses, dans cet ordre :
#   A. la politique est conforme au moteur amont (table gelee + differentiel reel quand node et le
#      paquet gsd-core sont presents sur la machine) ;
#   B. les QUATRE gates classent le MEME corpus de noms a l'identique (valide / rejete) ;
#   C. aucun gate ne redefinit la politique localement, et tous la sourcent — c'est la garde de
#      non-regression : supprimer les copies ne suffit pas, il faut empecher leur retour.
#
# Portabilite : macOS (bash 3.2) et Linux. Aucun `grep -P`, `readlink -f`, `mapfile`, `declare -A`,
# `sed -i` nu, `stat -c` ni `${x,,}`.

set -uo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
POLICY="$HERE/workstream-policy.sh"
PLUGIN_ROOT="$(cd "$HERE/../.." && pwd)"

SI="$PLUGIN_ROOT/conductor/scripts/check-state-integrity.sh"
WP="$PLUGIN_ROOT/conductor/scripts/check-workstream-pointer.sh"
DB="$PLUGIN_ROOT/dev-orchestrator/scripts/check-dev-bootstrap.sh"
PC="$PLUGIN_ROOT/planning-core/scripts/planning-context.sh"

PASS=0; FAIL=0; SKIP=0
ok()   { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko()   { echo "  ✗ $1 — $2"; FAIL=$((FAIL+1)); }
skip() { echo "  ~ $1"; SKIP=$((SKIP+1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "== test-workstream-policy =="

[ -r "$POLICY" ] || { echo "  ✗ politique introuvable : $POLICY"; exit 1; }
# shellcheck source=/dev/null
. "$POLICY"

# ---------------------------------------------------------------------------------------------
# CORPUS. Chaque entree : <attendu:1=valide,0=rejete> <TAB> <nom>. Le nom est lu en dernier champ
# pour tolerer les espaces internes.
# ---------------------------------------------------------------------------------------------
CORPUS="$TMP/corpus.tsv"
{
  printf '1\tdev\n'
  printf '1\tfeature-x\n'
  printf '1\ta_b\n'
  printf '1\tv1.2\n'
  printf '1\tA1\n'
  printf '1\t9lives\n'
  # 100 caracteres : amont n'a AUCUNE borne de longueur. L'ancienne borne locale de 80 rejetait
  # donc des noms qu'amont ACCEPTE — avec un repli fail-open derriere.
  printf '1\t%s\n' "$(awk 'BEGIN{s="";for(i=0;i<100;i++)s=s"a";print s}')"
  printf '0\t.\n'
  printf '0\t..\n'
  printf '0\t.hidden\n'
  printf '0\t-x\n'
  printf '0\t_lead\n'
  printf '0\ta..b\n'
  printf '0\ta/b\n'
  printf '0\t../evil\n'
  printf '0\ta\\b\n'
  printf '0\tde v\n'
  printf '0\tx;y\n'
  printf '0\tetc\n'
} > "$CORPUS"
# `etc` est VALIDE en realite — entree temoin inversee pour prouver que la table n'est pas ignoree.
awk -F'\t' '{ if ($2 == "etc") $1 = 1; print $1 "\t" $2 }' OFS='' "$CORPUS" > "$TMP/c2" 2>/dev/null
{ awk -F'\t' '$2 != "etc"' "$CORPUS"; printf '1\tetc\n'; } > "$TMP/c3" && mv "$TMP/c3" "$CORPUS"

corpus_names() { awk -F'\t' '{ print $2 }' "$CORPUS"; }
corpus_expect() { awk -F'\t' -v n="$1" '$2 == n { print $1; exit }' "$CORPUS"; }

# =============================================================================================
# A. Conformite au moteur amont
# =============================================================================================
a_ok=1; a_detail=""
while IFS="$(printf '\t')" read -r want name; do
  [ -n "${want:-}" ] || continue
  if vf_ws_name_valid "$name"; then got=1; else got=0; fi
  [ "$got" = "$want" ] || { a_ok=0; a_detail="« $name » → $got (attendu $want)"; }
done < "$CORPUS"
if [ "$a_ok" -eq 1 ]; then
  ok "A1 politique conforme a la table gelee ($(corpus_names | awk 'END{print NR}') noms)"
else ko "A1 politique conforme a la table gelee" "$a_detail"; fi

# --- A2 DIFFERENTIEL : confronter la politique au VRAI module amont, quand il est present ------
# Opportuniste : la machine de dev a gsd-core installe, la CI (Linux, lab vierge) ne l'a pas. Un
# skip propre vaut mieux qu'un rouge d'environnement — et mieux qu'un vert qui n'a rien compare.
UPSTREAM=""
for c in "$HOME/.claude/gsd-core/bin/lib/workstream-name-policy.cjs" \
         "$HOME/.claude/gsd-core/gsd-core/bin/lib/workstream-name-policy.cjs"; do
  [ -r "$c" ] && { UPSTREAM="$c"; break; }
done
if [ -z "$UPSTREAM" ] || ! command -v node >/dev/null 2>&1; then
  skip "A2 differentiel amont — node ou workstream-name-policy.cjs absent de cette machine"
else
  d_ok=1; d_detail=""
  while IFS="$(printf '\t')" read -r want name; do
    [ -n "${want:-}" ] || continue
    up=$(WS_NAME="$name" node -e '
      const p = require(process.argv[1]);
      process.stdout.write(p.isValidActiveWorkstreamName(process.env.WS_NAME) ? "1" : "0");
    ' "$UPSTREAM" 2>/dev/null)
    if vf_ws_name_valid "$name"; then mine=1; else mine=0; fi
    [ -n "$up" ] || continue
    [ "$up" = "$mine" ] || { d_ok=0; d_detail="« $name » : amont=$up local=$mine"; }
  done < "$CORPUS"
  if [ "$d_ok" -eq 1 ]; then
    ok "A2 differentiel — verdict IDENTIQUE au moteur amont reel sur tout le corpus"
  else ko "A2 differentiel amont" "$d_detail"; fi
fi

# --- A3 rognage : les BORDS seulement, jamais l'interieur --------------------------------------
t1="$(vf_ws_trim '  dev  ')"
t2="$(vf_ws_trim 'de v')"
t3="$(vf_ws_trim "$(printf '\n dev \n')")"
if [ "$t1" = "dev" ] && [ "$t2" = "de v" ] && [ "$t3" = "dev" ]; then
  ok "A3 rognage des bords uniquement — « de v » reste « de v » (jamais « dev » fabrique)"
else ko "A3 rognage des bords" "t1=[$t1] t2=[$t2] t3=[$t3]"; fi

# --- A4 vacuite evaluee APRES rognage : une chaine blanche ne court-circuite pas le canal suivant -
# Amont rogne D'ABORD puis retombe sur le store (`env['GSD_WORKSTREAM'].trim()` en condition).
mkdir -p "$TMP/a4/.planning"
printf 'dev\n' > "$TMP/a4/.planning/active-workstream"
( export GSD_WORKSTREAM='   '
  vf_ws_resolve "$TMP/a4/.planning"
  [ "$VF_WS_NAME" = "dev" ] ) \
  && ok "A4 GSD_WORKSTREAM blanc → rogne puis ignore, le pointeur partage est bien consulte" \
  || ko "A4 vacuite apres rognage" "un GSD_WORKSTREAM blanc court-circuite le pointeur"

# --- A5 lecture SURE du pointeur ----------------------------------------------------------------
mkdir -p "$TMP/a5/.planning"
printf 'sk-live-FUITE.SECRET\n' > "$TMP/a5/cible"
ln -sf "$TMP/a5/cible" "$TMP/a5/.planning/active-workstream"
vf_ws_resolve "$TMP/a5/.planning"; r5=$?
if [ "$r5" -eq 2 ] && [ "$VF_WS_REASON" = "pointeur-lien-symbolique" ] && [ -z "$VF_WS_NAME" ]; then
  ok "A5 pointeur = lien symbolique → refus (jamais suivi), aucun nom rendu"
else ko "A5 refus du lien symbolique" "rc=$r5 raison=$VF_WS_REASON nom=[$VF_WS_NAME]"; fi

rm -f "$TMP/a5/.planning/active-workstream"
awk 'BEGIN{s="";for(i=0;i<9000;i++)s=s"a";print s}' > "$TMP/a5/.planning/active-workstream"
vf_ws_resolve "$TMP/a5/.planning"; r5b=$?
if [ "$r5b" -eq 2 ] && [ "$VF_WS_REASON" = "pointeur-trop-long" ]; then
  ok "A5b pointeur au-dela de la borne d'octets → refus de lecture, valeur jamais chargee"
else ko "A5b borne de lecture" "rc=$r5b raison=$VF_WS_REASON"; fi

rm -f "$TMP/a5/.planning/active-workstream"
printf 'dev\nautre\n' > "$TMP/a5/.planning/active-workstream"
vf_ws_resolve "$TMP/a5/.planning"; r5c=$?
if [ "$r5c" -eq 2 ] && [ "$VF_WS_REASON" = "hors-politique" ]; then
  ok "A5c pointeur « dev\\nautre » → rejete : le fichier ENTIER est evalue (parite raw.trim())"
else ko "A5c lecture du fichier entier" "rc=$r5c raison=$VF_WS_REASON nom=[$VF_WS_NAME]"; fi

# =============================================================================================
# B. Les QUATRE gates classent le corpus a l'identique
# =============================================================================================
# Fixture unique satisfaisant les quatre : depot git, .planning PARTITIONNE, STATE.md a la racine,
# PROJECT.md, et AUCUN compartiment portant les noms du corpus. Chaque gate doit donc, pour un nom
# VALIDE, atteindre l'etat « resolu mais dossier absent » ; pour un nom REJETE, l'etat « rejete ».
FIX="$TMP/fix"
mkdir -p "$FIX/.planning/workstreams"
git -C "$FIX" init -q -b main >/dev/null 2>&1 || git -C "$FIX" init -q >/dev/null 2>&1
printf '# Projet\n' > "$FIX/.planning/PROJECT.md"
printf '{}\n' > "$FIX/.planning/config.json"
{
  printf -- '---\n'
  printf 'milestone: m1\n'
  printf 'current_phase: 3\n'
  printf 'progress:\n'
  printf '  completed_phases: 2\n'
  printf '  completed_plans: 5\n'
  printf '  total_plans: 9\n'
  printf -- '---\n\n'
  printf 'Phase: 3\n'
} > "$FIX/.planning/STATE.md"
printf '### Phase 1 — x\n' > "$FIX/.planning/ROADMAP.md"
git -C "$FIX" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$FIX" -c user.email=t@t -c user.name=t commit -q -m base >/dev/null 2>&1

# Chaque classifieur rend exactement REJETE ou VALIDE (ou INDETERMINE, qui fait echouer la suite).
cls_si() { # check-state-integrity : les deux etats sortent en 2, le message les distingue
  local o; o="$(GSD_WORKSTREAM="$1" bash "$SI" --path "$FIX" 2>&1)"
  case "$o" in
    *"rejeté par la politique amont"*) printf 'REJETE' ;;
    *"actif mais .planning/workstreams/"*) printf 'VALIDE' ;;
    *) printf 'INDETERMINE' ;;
  esac
}
cls_wp() { # check-workstream-pointer : rejete=2, resolu-mais-absent=1
  local o rc; o="$(GSD_WORKSTREAM="$1" bash "$WP" --path "$FIX" 2>&1)"; rc=$?
  case "$rc" in
    2) printf 'REJETE' ;;
    1) case "$o" in *"n'existe pas"*) printf 'VALIDE' ;; *) printf 'INDETERMINE' ;; esac ;;
    *) printf 'INDETERMINE' ;;
  esac
}
cls_db() { # check-dev-bootstrap : injecteur, les deux etats repliaient sur la racine
  local o; o="$(GSD_WORKSTREAM="$1" bash "$DB" --path "$FIX" 2>&1)"
  case "$o" in
    *"rejeté par la politique amont"*) printf 'REJETE' ;;
    *"résolu mais"*) printf 'VALIDE' ;;
    *) printf 'INDETERMINE' ;;
  esac
}
cls_pc() { # planning-context : injecteur, note sur stdout
  local o; o="$(GSD_WORKSTREAM="$1" bash "$PC" --path "$FIX/.planning" 2>&1)"
  case "$o" in
    *"rejeté par la politique amont"*) printf 'REJETE' ;;
    *"actif, mais aucun"*) printf 'VALIDE' ;;
    *) printf 'INDETERMINE' ;;
  esac
}

b_ok=1; b_detail=""; b_seen=0
while IFS="$(printf '\t')" read -r want name; do
  [ -n "${want:-}" ] || continue
  [ "$want" = "1" ] && attendu="VALIDE" || attendu="REJETE"
  v_si="$(cls_si "$name")"; v_wp="$(cls_wp "$name")"
  v_db="$(cls_db "$name")"; v_pc="$(cls_pc "$name")"
  b_seen=$((b_seen+1))
  if [ "$v_si" != "$attendu" ] || [ "$v_wp" != "$attendu" ] \
     || [ "$v_db" != "$attendu" ] || [ "$v_pc" != "$attendu" ]; then
    b_ok=0
    b_detail="« $name » attendu=$attendu · state-integrity=$v_si pointer=$v_wp bootstrap=$v_db context=$v_pc"
  fi
done < "$CORPUS"
# Garde anti-vert-a-vide : une boucle qui n'a rien parcouru ne prouve rien.
if [ "$b_seen" -lt 15 ]; then
  ko "B1 les 4 gates classent a l'identique" "corpus non parcouru ($b_seen entrees)"
elif [ "$b_ok" -eq 1 ]; then
  ok "B1 les 4 gates classent les $b_seen noms du corpus A L'IDENTIQUE (valide / rejete)"
else ko "B1 les 4 gates classent a l'identique" "$b_detail"; fi

# --- B2 : la REACTION par role est celle DECLAREE dans workstream-policy.sh ---------------------
# La classification est unique ; la severite, elle, est fonction du role et declaree une seule fois.
# Ce cas gele cette declaration : la faire varier sans toucher a la politique ecrite devient rouge.
rc_si=$(GSD_WORKSTREAM=absentws bash "$SI" --path "$FIX" >/dev/null 2>&1; echo $?)
rc_wp=$(GSD_WORKSTREAM=absentws bash "$WP" --path "$FIX" >/dev/null 2>&1; echo $?)
rc_db=$(GSD_WORKSTREAM=absentws bash "$DB" --path "$FIX" >/dev/null 2>&1; echo $?)
rc_pc=$(GSD_WORKSTREAM=absentws bash "$PC" --path "$FIX/.planning" >/dev/null 2>&1; echo $?)
if [ "$rc_si" -eq 2 ] && [ "$rc_wp" -eq 1 ] && [ "$rc_db" -eq 3 ] && [ "$rc_pc" -eq 0 ]; then
  ok "B2 « resolu mais dossier absent » — severite par role conforme a la politique ecrite (verification=2, constat=1, injecteurs=3/0)"
else
  ko "B2 severite par role" "state-integrity=$rc_si (2) pointer=$rc_wp (1) bootstrap=$rc_db (3) context=$rc_pc (0)"
fi

# --- B3 : aucun des quatre ne NOMME un workstream rejete, tous NOMMENT un workstream valide ------
MARQ='zzMARQUEURzz..q'
b3_ok=1; b3_detail=""
for g in si wp db pc; do
  case "$g" in
    si) o="$(GSD_WORKSTREAM="$MARQ" bash "$SI" --path "$FIX" 2>&1)" ;;
    wp) o="$(GSD_WORKSTREAM="$MARQ" bash "$WP" --path "$FIX" 2>&1)" ;;
    db) o="$(GSD_WORKSTREAM="$MARQ" bash "$DB" --path "$FIX" 2>&1)" ;;
    pc) o="$(GSD_WORKSTREAM="$MARQ" bash "$PC" --path "$FIX/.planning" 2>&1)" ;;
  esac
  printf '%s' "$o" | awk '/zzMARQUEURzz/ { f=1 } END { exit !f }' \
    && { b3_ok=0; b3_detail="$g reimprime la valeur rejetee"; }
done
if [ "$b3_ok" -eq 1 ]; then
  ok "B3 aucun des 4 gates ne reimprime la valeur d'un nom rejete (T-24-04-01 / T-24-05-01)"
else ko "B3 non-reimpression d'une valeur rejetee" "$b3_detail"; fi

# =============================================================================================
# C. Non-regression structurelle : une seule politique, sourcee par les quatre
# =============================================================================================
c_ok=1; c_detail=""
for f in "$SI" "$WP" "$DB" "$PC"; do
  b="$(basename "$f")"
  # (a) le gate source bien la politique partagee
  awk '/workstream-policy\.sh/ { f=1 } END { exit !f }' "$f" \
    || { c_ok=0; c_detail="$b ne reference pas workstream-policy.sh"; }
  # (b) aucune redefinition LOCALE de la politique. On cible les DEFINITIONS de fonction, pas les
  # appels : `vf_ws_name_valid()` vit dans la politique, pas dans les gates.
  awk '/^[[:space:]]*(ws_name_valid|nom_valide|ws_trim|ws_resolve|vf_ws_name_valid|vf_ws_trim|vf_ws_resolve)\(\)/ { f=1 } END { exit !f }' "$f" \
    && { c_ok=0; c_detail="$b redefinit localement la politique"; }
done
if [ "$c_ok" -eq 1 ]; then
  ok "C1 les 4 gates sourcent la politique partagee et aucun ne la redefinit localement"
else ko "C1 politique unique" "$c_detail"; fi

# --- C2 : la politique est definie a UN SEUL endroit dans tout l'arbre plugin/ -------------------
defs=$(for f in "$PLUGIN_ROOT"/*/scripts/*.sh; do
         [ -f "$f" ] || continue
         awk -v F="$f" '/^[[:space:]]*vf_ws_name_valid\(\)/ { print F }' "$f"
       done | awk 'END{print NR+0}')
if [ "$defs" -eq 1 ]; then
  ok "C2 vf_ws_name_valid n'est defini qu'UNE fois dans plugin/*/scripts/ ($defs definition)"
else ko "C2 definition unique de la politique" "$defs definition(s) trouvee(s) (attendu 1)"; fi

# --- C3 DISCRIMINANCE PAR MUTATION : la mesure d'identite sait-elle rougir ? ---------------------
# Sans ce cas, B1 pourrait etre vert parce qu'il ne mesure rien. On mute une COPIE de la politique
# pour y remettre l'ancienne borne locale de 80 caracteres — la divergence exacte que B2 a decrite —
# et on verifie qu'un gate cablé sur cette copie change de verdict sur le nom de 100 caracteres.
MUT="$TMP/mut"; mkdir -p "$MUT"
cp "$WP" "$MUT/check-workstream-pointer.sh"
awk '
  /^  \[ -n "\$n" \] \|\| return 1$/ { print; print "  [ ${#n} -le 80 ] || return 1"; next }
  { print }
' "$POLICY" > "$MUT/workstream-policy.sh"
LONG100="$(awk 'BEGIN{s="";for(i=0;i<100;i++)s=s"a";print s}')"
if awk '/-le 80/ { f=1 } END { exit !f }' "$MUT/workstream-policy.sh"; then
  rc_sain=$(GSD_WORKSTREAM="$LONG100" bash "$WP" --path "$FIX" >/dev/null 2>&1; echo $?)
  rc_mut=$(GSD_WORKSTREAM="$LONG100" bash "$MUT/check-workstream-pointer.sh" --path "$FIX" >/dev/null 2>&1; echo $?)
  if [ "$rc_sain" -eq 1 ] && [ "$rc_mut" -eq 2 ]; then
    ok "C3 mutant (borne locale de 80 reintroduite) → verdict change (sain=$rc_sain, mutant=$rc_mut) : la mesure discrimine"
  else
    ko "C3 discriminance par mutation" "sain=$rc_sain mutant=$rc_mut — le mutant n'est pas opposable"
  fi
else
  ko "C3 discriminance par mutation" "mutation NON APPLIQUEE a la copie — cas non opposable"
fi

echo "== resultat : $PASS ok, $FAIL ko, $SKIP skip =="
[ "$FAIL" -eq 0 ]
