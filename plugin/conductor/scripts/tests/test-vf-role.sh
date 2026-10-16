#!/usr/bin/env bash
# Test de vf-role.sh (Phase 58, RLPO-02) — autonome.
# Cas VR-TRACE-1..4, VR-CRLF, VR-BOM, VR-VIDE, VR-INV, VR-MULTI, VR-LIEN, VR-BORNE, VR-DOSSIER,
# VR-ILLISIBLE, VR-RACINE-ENV/GIT/POINT, VR-COPIE, VR-USAGE, VR-CODES, VR-RO ; mutants VR-MUT-1..5.
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/vf-role.sh"
PASS=0; FAIL=0
ok() { echo "  ✓ $1"; PASS=$((PASS+1)); }
ko() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }

TMP="$(mktemp -d)"
trap 'chmod -R u+rwx "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT
: > "$TMP/rcs"; : > "$TMP/ro-bad"

note_rc() { echo "$RC" >> "$TMP/rcs"; }
snap() { (cd "$1" && find . -print | LC_ALL=C sort | cksum); }

# runr <cwd> <script> <assignations d'environnement|-> args... -> $RC, $TMP/out, $ERR
runr() {
  local cwd="$1" sc="$2" ev="$3" before after; shift 3
  [ "$ev" = "-" ] && ev=""
  before="$(snap "$cwd")"
  (cd "$cwd" && env -u VF_ROLE -u CLAUDE_PROJECT_DIR $ev bash "$sc" "$@" >"$TMP/out" 2>"$TMP/errf"); RC=$?
  ERR="$(cat "$TMP/errf")"
  after="$(snap "$cwd")"
  [ "$before" = "$after" ] || echo "$cwd" >> "$TMP/ro-bad"
}
out_is() { printf '%s\n' "$1" > "$TMP/exp"; cmp -s "$TMP/exp" "$TMP/out"; }
out_empty() { [ ! -s "$TMP/out" ]; }
mklab() { mkdir -p "$TMP/$1/.claude"; printf '%s' "$TMP/$1"; }
setrole() { printf "$2" > "$1/.claude/vibeflow-role"; } # setrole <lab> <printf-format>

echo "== test-vf-role =="

# --- tracer
L="$(mklab t1)"; rm -rf "$L/.claude"
runr "$L" "$SCRIPT" - get --path "$L"; note_rc
{ [ $RC -eq 0 ] && out_is solo; } && ok "VR-TRACE-1 fichier absent => solo" || ko "VR-TRACE-1 attendu solo rc 0, obtenu rc $RC [$(cat "$TMP/out")]"
L="$(mklab t2)"; setrole "$L" 'product\n'
runr "$L" "$SCRIPT" - get --path "$L"; note_rc
{ [ $RC -eq 0 ] && out_is product; } && ok "VR-TRACE-2 fichier product" || ko "VR-TRACE-2 attendu product rc 0, obtenu rc $RC [$(cat "$TMP/out")]"
runr "$L" "$SCRIPT" VF_ROLE=dev get --path "$L"; note_rc
{ [ $RC -eq 0 ] && out_is dev; } && ok "VR-TRACE-3 la variable l'emporte sur le fichier" || ko "VR-TRACE-3 attendu dev rc 0, obtenu rc $RC [$(cat "$TMP/out")]"
runr "$L" "$SCRIPT" VF_ROLE=qa get --path "$L"; note_rc
if [ $RC -eq 1 ] && out_empty && printf '%s' "$ERR" | grep -q 'valeur invalide' && ! printf '%s' "$ERR" | grep -q 'qa'; then ok "VR-TRACE-4 VF_ROLE invalide => rc 1 sans réimprimer"
else ko "VR-TRACE-4 attendu rc 1 stdout vide 'valeur invalide' sans qa ; obtenu rc $RC err [$ERR]"; fi

# --- tolérances
L="$(mklab crlf)"; setrole "$L" 'product\r\n'
runr "$L" "$SCRIPT" - get --path "$L"; note_rc
{ [ $RC -eq 0 ] && out_is product; } && ok "VR-CRLF CRLF toléré" || ko "VR-CRLF attendu product rc 0, obtenu rc $RC [$(cat "$TMP/out")]"
L="$(mklab bom)"; setrole "$L" '\357\273\277dev\n'
runr "$L" "$SCRIPT" - get --path "$L"; note_rc
{ [ $RC -eq 0 ] && out_is dev; } && ok "VR-BOM BOM UTF-8 toléré" || ko "VR-BOM attendu dev rc 0, obtenu rc $RC [$(cat "$TMP/out")]"

# --- refus
L="$(mklab vide)"; : > "$L/.claude/vibeflow-role"
runr "$L" "$SCRIPT" - get --path "$L"; note_rc
{ [ $RC -eq 1 ] && out_empty; } && ok "VR-VIDE fichier vide => rc 1" || ko "VR-VIDE attendu rc 1 stdout vide, obtenu rc $RC"
L="$(mklab inv)"; setrole "$L" 'zzSECRETzz\n'
runr "$L" "$SCRIPT" - get --path "$L"; note_rc
if [ $RC -eq 1 ] && out_empty && ! printf '%s' "$ERR" | grep -q zzSECRETzz; then ok "VR-INV valeur invalide => rc 1, marqueur non réimprimé"
else ko "VR-INV attendu rc 1 stdout vide sans marqueur ; obtenu rc $RC err [$ERR] out [$(cat "$TMP/out")]"; fi
L="$(mklab multi)"; setrole "$L" 'product\nconsigne-piege zzSECRETzz\n'
runr "$L" "$SCRIPT" - get --path "$L"; note_rc
if [ $RC -eq 5 ] && out_empty && ! printf '%s' "$ERR" | grep -q zzSECRETzz; then ok "VR-MULTI plusieurs lignes => rc 5"
else ko "VR-MULTI attendu rc 5 stdout vide sans marqueur ; obtenu rc $RC err [$ERR]"; fi
L="$(mklab lien)"; printf 'product\n' > "$TMP/cible"; ln -s "$TMP/cible" "$L/.claude/vibeflow-role"
runr "$L" "$SCRIPT" - get --path "$L"; note_rc
{ [ $RC -eq 5 ] && out_empty; } && ok "VR-LIEN lien symbolique refusé avant lecture" || ko "VR-LIEN attendu rc 5 stdout vide, obtenu rc $RC [$(cat "$TMP/out")]"
L="$(mklab borne)"; { printf 'product'; head -c 5000 /dev/zero | tr '\0' ' '; printf '\n'; } > "$L/.claude/vibeflow-role"
runr "$L" "$SCRIPT" - get --path "$L"; note_rc
{ [ $RC -eq 5 ] && out_empty; } && ok "VR-BORNE 5000 octets => rc 5" || ko "VR-BORNE attendu rc 5, obtenu rc $RC"
L="$(mklab dossier)"; mkdir "$L/.claude/vibeflow-role"
runr "$L" "$SCRIPT" - get --path "$L"; note_rc
{ [ $RC -eq 5 ] && out_empty; } && ok "VR-DOSSIER répertoire => rc 5" || ko "VR-DOSSIER attendu rc 5, obtenu rc $RC"
if [ "$(id -u)" -eq 0 ]; then echo "  - VR-ILLISIBLE SKIP (suite lancée en root)"
else
  L="$(mklab illis)"; setrole "$L" 'dev\n'; chmod 000 "$L/.claude/vibeflow-role"
  runr "$L" "$SCRIPT" - get --path "$L"; note_rc
  { [ $RC -eq 5 ] && out_empty; } && ok "VR-ILLISIBLE chmod 000 => rc 5" || ko "VR-ILLISIBLE attendu rc 5, obtenu rc $RC"
  chmod 600 "$L/.claude/vibeflow-role"
fi

# --- racine
A="$(mklab labA)"; setrole "$A" 'product\n'
B="$(mklab labB)"; setrole "$B" 'dev\n'
runr "$B" "$SCRIPT" CLAUDE_PROJECT_DIR="$A" get; note_rc
a1=$RC; out_is product && o1=1 || o1=0
runr "$B" "$SCRIPT" CLAUDE_PROJECT_DIR="$A" get --path "$B"; note_rc
{ [ $a1 -eq 0 ] && [ $o1 -eq 1 ] && [ $RC -eq 0 ] && out_is dev; } && ok "VR-RACINE-ENV CLAUDE_PROJECT_DIR puis --path l'emporte" || ko "VR-RACINE-ENV attendu product puis dev ; obtenu rc $a1/$o1 puis rc $RC [$(cat "$TMP/out")]"
G="$(mklab gitlab)"; setrole "$G" 'dev\n'; (cd "$G" && git init -q); mkdir -p "$G/sous/dossier"
runr "$G/sous/dossier" "$SCRIPT" - get; note_rc
{ [ $RC -eq 0 ] && out_is dev; } && ok "VR-RACINE-GIT racine git depuis un sous-dossier" || ko "VR-RACINE-GIT attendu dev rc 0, obtenu rc $RC [$(cat "$TMP/out")] err [$ERR]"
P="$(mklab point)"; setrole "$P" 'product\n'
runr "$P" "$SCRIPT" - get; note_rc
{ [ $RC -eq 0 ] && out_is product; } && ok "VR-RACINE-POINT hors git, lecture de ./.claude/vibeflow-role" || ko "VR-RACINE-POINT attendu product rc 0, obtenu rc $RC [$(cat "$TMP/out")]"
C="$(mklab copie)"; setrole "$C" 'product\n'; (cd "$C" && git init -q); mkdir -p "$C/.claude/scripts"; cp "$SCRIPT" "$C/.claude/scripts/vf-role.sh"
runr "$C" "$C/.claude/scripts/vf-role.sh" - get; note_rc
{ [ $RC -eq 0 ] && out_is product; } && ok "VR-COPIE la copie installée lit le fichier de son lab" || ko "VR-COPIE attendu product rc 0, obtenu rc $RC [$(cat "$TMP/out")]"

# --- usage
U="$(mklab usage)"; rcs=""
runr "$U" "$SCRIPT" -; note_rc; rcs="$rcs $RC"
runr "$U" "$SCRIPT" - set; note_rc; rcs="$rcs $RC"
runr "$U" "$SCRIPT" - get --path; note_rc; rcs="$rcs $RC"
runr "$U" "$SCRIPT" - get --bidule; note_rc; rcs="$rcs $RC"
[ "$rcs" = " 64 64 64 64" ] && ok "VR-USAGE usages => rc 64" || ko "VR-USAGE attendu 64 64 64 64, obtenu$rcs"
hlp="$(bash "$SCRIPT" --help)"
{ printf '%s\n' "$hlp" | grep -q '^  0  = ' && printf '%s\n' "$hlp" | grep -q '^  64 = '; } && ok "VR-HELP codes documentés" || ko "VR-HELP lignes de codes absentes"

# --- couverture des codes + lecture seule
printf '0\n1\n5\n64\n' > "$TMP/codes-exp"; LC_ALL=C sort -un "$TMP/rcs" > "$TMP/codes-obs"
if [ -z "$(comm -13 "$TMP/codes-exp" "$TMP/codes-obs")" ] && [ -z "$(comm -23 "$TMP/codes-exp" "$TMP/codes-obs")" ]; then ok "VR-CODES ensemble observé = {0,1,5,64}"
else ko "VR-CODES attendu {0 1 5 64} obtenu {$(tr '\n' ' ' < "$TMP/codes-obs")}"; fi
[ ! -s "$TMP/ro-bad" ] && ok "VR-RO aucun cas n'a modifié l'arborescence du lab" || ko "VR-RO arborescence modifiée : $(cat "$TMP/ro-bad")"

# --- mutants : remplacement de la première occurrence du fragment exact sur une ligne
mutate() { # <fragment> <remplacement> <sortie>
  awk -v pat="$1" -v rep="$2" '{ i=index($0, pat); if (i>0 && !done) { $0=substr($0,1,i-1) rep substr($0,i+length(pat)); done=1 } print }' "$SCRIPT" > "$3"
}
# mut <id> <fragment> <remplacement> <lab> <env|-> "<desc cas>" <rc attendu orig> <verif stdout orig: solo|dev|product|vide>
mut() {
  local id="$1" frag="$2" rep="$3" lab="$4" ev="$5" desc="$6" rco="$7" outo="$8" m="$TMP/mut/$1.sh" rm_ ro_ dm
  mkdir -p "$TMP/mut"; mutate "$frag" "$rep" "$m"
  if cmp -s "$m" "$SCRIPT"; then ko "$id : mutation sans effet, mutant NON OPPOSABLE"; return; fi
  if ! bash -n "$m" 2>/dev/null; then ko "$id : mutant invalide"; return; fi
  runr "$lab" "$m" "$ev" get --path "$lab"; rm_=$RC; dm="$(cat "$TMP/out")"
  runr "$lab" "$SCRIPT" "$ev" get --path "$lab"; ro_=$RC
  local origin_ok=0
  if [ "$ro_" -eq "$rco" ]; then
    if [ "$outo" = vide ]; then out_empty && origin_ok=1; else out_is "$outo" && origin_ok=1; fi
  fi
  local mut_red=0
  if [ "$rm_" -ne "$rco" ]; then mut_red=1
  elif [ "$outo" = vide ]; then [ -n "$dm" ] && mut_red=1
  else [ "$dm" != "$outo" ] && mut_red=1; fi
  if [ $mut_red -eq 1 ] && [ $origin_ok -eq 1 ]; then ok "$id mutant tué ($desc) : rc_mutant=$rm_ stdout_mutant=[$dm], original rc=$ro_ conforme"
  else ko "$id ($desc) attendu_original rc=$rco/$outo ; obtenu_mutant rc=$rm_ [$dm] ; obtenu_original rc=$ro_ (mutant vert ou original rouge)"; fi
}
mut VR-MUT-1 '[ -n "${VF_ROLE:-}" ]' '[ -n "${VF_ROLE:-}" ] && [ ! -e "$file" ]' "$TMP/t2" VF_ROLE=dev "priorité fichier avant variable" 0 dev
mut VR-MUT-2 '*) return 1 ;;' "*) printf 'solo\\n'; return 0 ;;" "$TMP/inv" - "valeur invalide repliée sur solo" 1 vide
mut VR-MUT-3 'echo solo; exit 0' 'echo; exit 0' "$TMP/t1" - "fichier absent rendu vide" 0 solo
mut VR-MUT-4 '*"$nl"*)' '*"@@jamais@@"*)' "$TMP/multi" - "contrôle multi-ligne neutralisé" 5 vide
mut VR-MUT-5 '[ -L "$file" ]' 'false' "$TMP/lien" - "refus du lien neutralisé" 5 vide

echo "== resultat : $PASS ok, $FAIL ko =="
[ "$FAIL" -eq 0 ]
