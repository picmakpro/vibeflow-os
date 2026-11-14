# regie-commun.sh — socle COMMUN de la suite unique de la régie (test-cockpit-regie.sh), SOURCÉ par le lanceur ; nom hors du motif test-*.sh :
# ce n'est pas une suite (même régime que projet-commun.sh). Phase 73, P73-D-05, REGI-16.
# Fournit : SCRIPTS, TESTS_DIR, UI, WORK jetable (et son trap), AUX, un HOME jetable, PASS/FAIL, assert_eq/assert_has/assert_not/assert_ok,
#   G (getter JSON), rg_node (harnais Node), rg_mut (mutant à ancre vérifiée), rg_mutant (mutant + sonde), rg_copie (copie jetable d'un fichier).
# Forme d'une ligne : `  ✅ PASS — <id> — <libellé>` ou `  ❌ FAIL — <id> — <libellé>` suivie de `attendu:` et `obtenu:` ; l'appelant écrit « <id> — <libellé> ».
# Bash 3.2 (macOS) et coreutils de la CI Linux : ni tableau associatif, ni mapfile, ni option propre à un seul système.

export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$(cd "$TESTS_DIR/.." && pwd)"
UI="$SCRIPTS/../skills/cockpit-moteur/assets/ui"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export HOME="$WORK/home"   # la suite ne dépend jamais du driver-lock.sh du poste
unset VF_COCKPIT_SCRIPTS_DIR

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (a trouvé [$3])"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_ok() { if [ "$2" = 0 ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [code 0]"; echo "     obtenu:  [code $2]"; FAIL=$((FAIL+1)); fi; }

cat > "$AUX/get.mjs" <<'JS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
# mutsub.mjs <fichier> — remplace UNE occurrence exacte de $FROM par $TO dans une COPIE ; « ancre absente » / « ancre ambiguë » (sortie 1) sinon
cat > "$AUX/mutsub.mjs" <<'JS'
import fs from 'node:fs';
const f = process.argv[2];
let t; try { t = fs.readFileSync(f, 'utf8'); } catch { console.log('ancre absente'); process.exit(1); }
const n = process.env.FROM ? t.split(process.env.FROM).length - 1 : 0;
if (n === 0) { console.log('ancre absente'); process.exit(1); }
if (n > 1) { console.log('ancre ambiguë'); process.exit(1); }
fs.writeFileSync(f, t.replace(process.env.FROM, () => process.env.TO)); console.log('muté');
JS

# G <fichier.json> <expression sur j> : getter JSON
G() { node "$AUX/get.mjs" "$@"; }

# rg_node <harnais.mjs> [args…] : lance un harnais Node qui écrit des lignes au format des assertions ; les recopie et les compte ;
# un code non nul sans ligne FAIL compte un FAIL « harnais <nom> : code N »
rg_node() {
  local out rc p f nom; nom="$(basename "$1")"
  out="$(node "$@" 2>&1)"; rc=$?
  printf '%s\n' "$out"
  p="$(printf '%s\n' "$out" | grep -c '✅ PASS — ')"; f="$(printf '%s\n' "$out" | grep -c '❌ FAIL — ')"
  PASS=$((PASS+p)); FAIL=$((FAIL+f))
  if [ "$rc" -ne 0 ] && [ "$f" -eq 0 ]; then echo "  ❌ FAIL — harnais $nom : code $rc"; FAIL=$((FAIL+1)); fi
  return 0
}

# rg_mut <nom> <dossier source> <fichier> <ancre> <remplacement> : copie les fichiers du dossier dans $WORK/mut-<nom>/, remplace l'ancre UNE fois ;
# ancre absente ou ambiguë : l'écrit et rend 1
rg_mut() {
  local d="$WORK/mut-$1" f
  rm -rf "$d"; mkdir -p "$d"
  for f in "$2"/*; do [ -f "$f" ] && cp "$f" "$d/"; done
  FROM="$4" TO="$5" node "$AUX/mutsub.mjs" "$d/$3"
}

# rg_mutant <NOM> <libellé> <dossier source> <fichier> <ancre> <remplacement> <sonde> <valeur saine> : un mutant est une assertion nommée M-<NOM> ;
# la sonde (fonction : dossier de scripts -> sortie) rejouée sur la copie mutée doit différer de la valeur saine ; ancre absente ou ambiguë : FAIL
rg_mutant() {
  local nom="$1" lib="$2" msg got
  msg="$(rg_mut "$nom" "$3" "$4" "$5" "$6")" || { assert_eq "M-$nom — $lib (ancre)" "$msg" "muté"; return 0; }
  got="$("$7" "$WORK/mut-$nom")"
  if [ "$got" != "$8" ]; then echo "  ✅ PASS — M-$nom — $lib (mutant tué : sonde $got, saine $8)"; PASS=$((PASS+1))
  else echo "  ❌ FAIL — M-$nom — $lib (mutant survivant)"; echo "     attendu: [différent de $8]"; echo "     obtenu:  [$got]"; FAIL=$((FAIL+1)); fi
  return 0
}

# rg_copie <fichier> : copie jetable d'un fichier quelconque (variante de script) ; rend son chemin
rg_copie() { local c; c="$(mktemp "$WORK/copie-XXXXXX")" && cp "$1" "$c" && printf '%s\n' "$c"; }
