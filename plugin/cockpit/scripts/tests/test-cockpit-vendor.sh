#!/usr/bin/env bash
# test-cockpit-vendor.sh — copie vendorisée de floorplan (CKPT-02, CKPT-03 volet code ; P67-D-03, D-07, D-11 ; P79-D-07).
#   V1 sentinelles et licence · V2 licences tierces · V3 rien que check-skills ou la CI jugeraient
#   V4 tailles et marqueurs (V4c : plafond de 160 colonnes en cliquet) · V11 code navigateur rangé en fichiers (79-11) · V8 binaires · V10 fork assumé : ni dossier amont ni journal de patchs, sentinelle du moteur lue (79-01)
#   V9 vendor xterm, police des traits de boîte, assistant du terminal
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
MOTEUR="$SCRIPTS/../skills/cockpit-moteur"
CHKSIZE="$SCRIPTS/../../software-architecture/scripts/check-file-size.sh"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_ge() { if [ "$2" -ge "$3" ] 2>/dev/null; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 ($2 < $3)"; FAIL=$((FAIL+1)); fi; }
nlines() { awk 'END{print NR}' "$1"; }

echo "=== V1 — sentinelles et licence ==="
for f in VENDORED.txt LICENCES-TIERCES.txt LICENSE assets/serve.mjs assets/viewer.html scripts/build.mjs assets/ui/00-vibeflow.js assets/ui/80-vf-fr.js; do
  assert_eq "V1 — $f présent" "$([ -s "$MOTEUR/$f" ] && echo oui || echo non)" "oui"
done
assert_eq "V1 — LICENSE contient MIT et Copyright" "$(grep -c -E 'MIT|Copyright' "$MOTEUR/LICENSE" | awk '$1>=2{print "oui"}')" "oui"
assert_eq "V1 — VENDORED.txt nomme la version et le commit" "$(head -1 "$MOTEUR/VENDORED.txt" | grep -c 'v0.6.0 @ 92d6854')" "1"

echo "=== V2 — licences tierces ==="
n=0
while IFS= read -r l; do
  case "$l" in *" — "*) p="${l##* — }"; n=$((n+1)); assert_eq "V2 — licence présente : $p" "$([ -s "$MOTEUR/$p" ] && echo oui || echo non)" "oui" ;; esac
done < "$MOTEUR/LICENCES-TIERCES.txt"
assert_eq "V2 — sept composants listés (dont JetBrains Mono 2.304, traits de boîte du terminal)" "$n" "7"

echo "=== V3 — rien que check-skills ou la CI jugeraient ==="
assert_eq "V3.1 — aucun SKILL.md" "$(find "$MOTEUR" -name SKILL.md | grep -c .)" "0"
assert_eq "V3.2 — aucun dossier agents" "$(find "$MOTEUR" -type d -name agents | grep -c .)" "0"
assert_eq "V3.3 — aucun chemin */tests/*" "$(find "$MOTEUR" -path '*/tests/*' | grep -c .)" "0"
assert_eq "V3.4 — le dossier posé ne porte pas le nom du produit amont" "$(basename "$(cd "$MOTEUR" && pwd)" | grep -ci floorplan)" "0"

echo "=== V4 — tailles et marqueurs ==="
nt=0
while read -r k f rest; do
  [ "$k" = TAILLE ] || continue; nt=$((nt+1))
  case "$rest" in *html*) continue ;; esac
  assert_eq "V4 — marqueur de taille dans les 5 premières lignes de $f" "$(head -n 5 "$MOTEUR/$f" | grep -c 'vibeflow:allow-large-file')" "1"
done < "$MOTEUR/VENDORED.txt"
assert_ge "V4 — des lignes TAILLE existent" "$nt" 7
big=0
for f in "$SCRIPTS"/*.mjs; do [ "$(nlines "$f")" -le 300 ] || { big=$((big+1)); echo "     trop long : $f"; }; done
while read -r k f; do [ "$k" = AJOUT ] || continue; case "$f" in *.js|*.mjs) [ "$(nlines "$MOTEUR/$f")" -le 300 ] || { big=$((big+1)); echo "     trop long : $f"; } ;; esac; done < "$MOTEUR/VENDORED.txt"
assert_eq "V4 — notre code sous 300 lignes (scripts du module, ajouts de code)" "$big" "0"
if [ -f "$CHKSIZE" ]; then
  FILES=$(find "$SCRIPTS" "$MOTEUR" \( -name '*.mjs' -o -name '*.js' \) -type f)
  # shellcheck disable=SC2086
  bash "$CHKSIZE" $FILES >/dev/null 2>&1; assert_eq "V4 — check-file-size.sh sur tout le code du module" "$?" "0"
  cp "$MOTEUR/assets/serve.mjs" "$WORK/serve-sans-marqueur.mjs"
  grep -v 'vibeflow:allow-large-file' "$MOTEUR/assets/serve.mjs" > "$WORK/serve-sans-marqueur.mjs"
  bash "$CHKSIZE" "$WORK/serve-sans-marqueur.mjs" >/dev/null 2>&1; assert_eq "V4 — témoin : serve.mjs sans marqueur est bloqué (exit 2)" "$?" "2"
fi

echo "=== V4c — plafond de 160 colonnes en cliquet (AUDC-AM5, P79-D-19) ==="
CLIQUET="${CLIQUET:-$SCRIPTS/tests/colonnes-cliquet.mjs}"
RACINE_MODULE="$(cd "$SCRIPTS/.." && pwd)"
# col_racine <nom> : racine de module jetable (un script, un code et une feuille rangés par des lignes AJOUT) ; imprime son chemin
col_racine() {
  local r="$WORK/col-$1"; rm -rf "$r"; mkdir -p "$r/scripts" "$r/skills/cockpit-moteur/assets/ui"
  printf '%s\n' 'const a = 1;' > "$r/scripts/vf-cockpit-a.mjs"
  printf '%s\n' 'const b = 2;' > "$r/skills/cockpit-moteur/assets/ui/10-b.js"
  printf '%s\n' '.b { color: red; }' > "$r/skills/cockpit-moteur/assets/ui/b.css"
  printf '%s\n' 'x' > "$r/skills/cockpit-moteur/assets/ui/c.css"
  printf '%s\n' 'fixture' '' 'AJOUT assets/ui/10-b.js' 'AJOUT assets/ui/b.css' > "$r/skills/cockpit-moteur/VENDORED.txt"
  printf '%s\n' "$r"
}
# col_ligne <fichier> <n> [x|e|cr] : ajoute une ligne de n points de code (x : lettres simples, e : é de 2 octets, cr : lettres simples puis un retour chariot)
col_ligne() { node -e 'const f=require("fs");const [p,n,m]=process.argv.slice(1);f.appendFileSync(p,(m==="e"?"é":"x").repeat(Number(n))+(m==="cr"?"\r":"")+"\n")' "$1" "$2" "${3:-x}"; }
# col_base <fichier> [ligne…] : un fichier de baseline (en-tête de commentaire puis les lignes données)
col_base() { local f="$1"; shift; { echo '# fixture de baseline'; for l in "$@"; do printf '%s\n' "$l"; done; } > "$f"; }
# col_juger <racine> <baseline> : « ok », « rouge <classes> » ou « erreur <code> » (jamais une sortie vide)
col_juger() {
  local out rc; out="$(node "$CLIQUET" verifier "$1" "$2" 2>&1)"; rc=$?
  case "$rc" in
    0) echo ok ;;
    1) echo "rouge $(printf '%s\n' "$out" | awk '$1 ~ /^(HAUSSE|PERIMEE|ORPHELINE|FORME)$/ {print $1}' | sort -u | paste -sd, -)" ;;
    *) echo "erreur $rc" ;;
  esac
}
col_v() { # <nom> <n> <mode> : un fichier du module porte une ligne de n points de code, baseline vide
  local r; r="$(col_racine "$1")"; col_ligne "$r/scripts/vf-cockpit-a.mjs" "$2" "$3"; col_base "$r/b.txt"; col_juger "$r" "$r/b.txt"
}
assert_eq "V4c.1a — une ligne de 161 points de code, baseline vide : rouge HAUSSE" "$(col_v u161 161 x)" "rouge HAUSSE"
assert_eq "V4c.1b — la borne : 160 points de code exactement passent" "$(col_v u160 160 x)" "ok"
assert_eq "V4c.1c — 150 lettres accentuées (300 octets) passent : la mesure compte des points de code" "$(col_v e150 150 e)" "ok"
assert_eq "V4c.1c' — 161 lettres accentuées : rouge HAUSSE" "$(col_v e161 161 e)" "rouge HAUSSE"
assert_eq "V4c.1d — 160 caractères suivis d'un CR : la fin de ligne CRLF n'est pas comptée" "$(col_v c160 160 cr)" "ok"
assert_eq "V4c.1d' — 161 caractères suivis d'un CR : rouge HAUSSE" "$(col_v c161 161 cr)" "rouge HAUSSE"
r="$(col_racine nomme)"; col_ligne "$r/scripts/vf-cockpit-a.mjs" 161; col_base "$r/b.txt"
assert_eq "V4c.1e — le rouge nomme le fichier fautif" "$(node "$CLIQUET" verifier "$r" "$r/b.txt" 2>&1 | grep -c 'scripts/vf-cockpit-a.mjs')" "1"
# V4c.2 : baseline en cliquet (le réel doit égaler la baseline : la descente est acceptée, la remontée non)
col_v2() { # <nom> <lignes longues réelles> <valeur de baseline> : verdict
  local r i; r="$(col_racine "$1")"; for i in $(seq 1 "$2"); do col_ligne "$r/scripts/vf-cockpit-a.mjs" 161; done
  col_base "$r/b.txt" "scripts/vf-cockpit-a.mjs $3"; col_juger "$r" "$r/b.txt"
}
assert_eq "V4c.2a — baseline à 2, réel 2 : ok" "$(col_v2 c22 2 2)" "ok"
assert_eq "V4c.2a' — baseline à 2, réel 3 : HAUSSE" "$(col_v2 c23 3 2)" "rouge HAUSSE"
assert_eq "V4c.2a'' — baseline à 2, réel 1 : PERIMEE (la baseline doit suivre la baisse)" "$(col_v2 c21 1 2)" "rouge PERIMEE"
r="$(col_racine abaisse)"; col_ligne "$r/scripts/vf-cockpit-a.mjs" 161; col_base "$r/b.txt" "scripts/vf-cockpit-a.mjs 2"
node "$CLIQUET" abaisser "$r" "$r/b.txt" > "$WORK/ab.out" 2>&1; ab_rc=$?
assert_eq "V4c.2a3 — abaisser réécrit la baseline au réel (code 0) puis le verdict est ok" "$ab_rc $(col_juger "$r" "$r/b.txt") $(grep -c '^scripts/vf-cockpit-a.mjs 1$' "$r/b.txt")" "0 ok 1"
r="$(col_racine monte)"; col_ligne "$r/scripts/vf-cockpit-a.mjs" 161; col_ligne "$r/scripts/vf-cockpit-a.mjs" 161; col_ligne "$r/scripts/vf-cockpit-a.mjs" 161; col_base "$r/b.txt" "scripts/vf-cockpit-a.mjs 2"
cp "$r/b.txt" "$r/b.avant"; node "$CLIQUET" abaisser "$r" "$r/b.txt" > "$WORK/ab2.out" 2>&1; ab_rc=$?
assert_eq "V4c.2a4 — abaisser refuse un relèvement : code 1, baseline intacte à l'octet" "$ab_rc $(cmp -s "$r/b.avant" "$r/b.txt" && echo intacte || echo modifiee)" "1 intacte"
col_v2b() { # <nom> <ligne de baseline> : verdict d'un fichier sans ligne longue et d'une baseline à une entrée donnée
  local r; r="$(col_racine "$1")"; col_base "$r/b.txt" "$2"; col_juger "$r" "$r/b.txt"
}
assert_eq "V4c.2b — une entrée pour un fichier hors du périmètre : ORPHELINE" "$(col_v2b orph 'scripts/vf-cockpit-absent.mjs 1')" "rouge ORPHELINE"
assert_eq "V4c.2b' — nombre non entier : FORME" "$(col_v2b f1 'scripts/vf-cockpit-a.mjs 1.5')" "rouge FORME"
assert_eq "V4c.2b'' — zéro : FORME (le fichier ne liste que les fichiers à plus de 0)" "$(col_v2b f2 'scripts/vf-cockpit-a.mjs 0')" "rouge FORME"
assert_eq "V4c.2b3 — chemin absolu : FORME" "$(col_v2b f3 '/scripts/vf-cockpit-a.mjs 1')" "rouge FORME"
assert_eq "V4c.2b4 — segment .. : FORME" "$(col_v2b f4 'scripts/../scripts/vf-cockpit-a.mjs 1')" "rouge FORME"
assert_eq "V4c.2b5 — un champ de trop : FORME" "$(col_v2b f5 'scripts/vf-cockpit-a.mjs 1 2')" "rouge FORME"
col_vdbl() { # <nom> <1re ligne> <2e ligne> : un réel d'une ligne longue, une baseline qui nomme deux fois le même fichier
  local r; r="$(col_racine "$1")"; col_ligne "$r/scripts/vf-cockpit-a.mjs" 161; col_base "$r/b.txt" "$2" "$3"; col_juger "$r" "$r/b.txt"
}
assert_eq "V4c.2b6 — le même fichier nommé deux fois, deux entrées égales au réel : FORME (jamais une entrée écrasée en silence)" "$(col_vdbl dbl 'scripts/vf-cockpit-a.mjs 1' 'scripts/vf-cockpit-a.mjs 1')" "rouge FORME"
assert_eq "V4c.2b7 — le même fichier nommé deux fois, valeurs différentes : FORME" "$(col_vdbl dbl2 'scripts/vf-cockpit-a.mjs 1' 'scripts/vf-cockpit-a.mjs 2')" "rouge FORME"
# initialiser : écrit une baseline neuve à l'état trouvé, ne réécrit JAMAIS une baseline qui existe
col_init_existe() { local r; r="$(col_racine init1)"; col_ligne "$r/scripts/vf-cockpit-a.mjs" 161; col_base "$r/b.txt" 'scripts/vf-cockpit-a.mjs 9'; cp "$r/b.txt" "$r/b.avant"
  node "$CLIQUET" initialiser "$r" "$r/b.txt" > /dev/null 2>&1; local rc=$?; echo "$rc $(cmp -s "$r/b.avant" "$r/b.txt" && echo intacte || echo modifiee)"; }
col_init_neuf() { local r rc; r="$(col_racine init2)"; col_ligne "$r/scripts/vf-cockpit-a.mjs" 161; node "$CLIQUET" initialiser "$r" "$r/neuf.txt" > /dev/null 2>&1; rc=$?; echo "$rc $(col_juger "$r" "$r/neuf.txt")"; }
assert_eq "V4c.2c — initialiser sur une baseline qui existe : code 1, baseline intacte à l'octet" "$(col_init_existe)" "1 intacte"
assert_eq "V4c.2c' — initialiser sur un chemin neuf : code 0 et le verdict de la baseline écrite est ok" "$(col_init_neuf)" "0 ok"
# V4c.3 : le marqueur des gros fichiers n'exempte rien
col_vmarq() { local r; r="$(col_racine marq)"; printf '%s\n' '// vibeflow:allow-large-file' > "$r/scripts/vf-cockpit-a.mjs"; col_ligne "$r/scripts/vf-cockpit-a.mjs" 161; col_base "$r/b.txt"; col_juger "$r" "$r/b.txt"; }
assert_eq "V4c.3 — le marqueur vibeflow:allow-large-file dans les cinq premières lignes n'exempte pas une ligne de 161 : HAUSSE" "$(col_vmarq)" "rouge HAUSSE"
# V4c.4 : le périmètre
loop300() { local f; for f in "$SCRIPTS"/*.mjs; do printf 'scripts/%s\n' "$(basename "$f")"; done; while read -r k f; do [ "$k" = AJOUT ] || continue; case "$f" in *.js|*.mjs) printf 'skills/cockpit-moteur/%s\n' "$f" ;; esac; done < "$MOTEUR/VENDORED.txt"; }
loop300 | LC_ALL=C sort > "$WORK/perim-attendu.txt"
node "$CLIQUET" perimetre "$RACINE_MODULE" --sans-css 2>/dev/null | LC_ALL=C sort > "$WORK/perim-obtenu.txt"
assert_ge "V4c.4 — témoin : la liste de la boucle des 300 lignes a au moins 50 fichiers" "$(nlines "$WORK/perim-attendu.txt")" 50
assert_eq "V4c.4a — le périmètre de l'aide (sans feuilles) égale la liste de la boucle des 300 lignes (écart en lignes)" "$(comm -3 "$WORK/perim-attendu.txt" "$WORK/perim-obtenu.txt" | wc -l | tr -d ' ')" "0"
r="$(col_racine css)"; col_ligne "$r/skills/cockpit-moteur/assets/ui/b.css" 161; col_base "$r/b.txt"
assert_eq "V4c.4b — une ligne AJOUT .css est mesurée : HAUSSE" "$(col_juger "$r" "$r/b.txt")" "rouge HAUSSE"
r="$(col_racine csshors)"; col_ligne "$r/skills/cockpit-moteur/assets/ui/c.css" 161; col_base "$r/b.txt"
assert_eq "V4c.4c — un .css non inscrit n'est pas mesuré : ok" "$(col_juger "$r" "$r/b.txt")" "ok"
r="$(col_racine sous)"; mkdir -p "$r/scripts/sous"; printf '%s\n' 'const z = 1;' > "$r/scripts/sous/z.mjs"; col_ligne "$r/scripts/sous/z.mjs" 161; col_base "$r/b.txt"
assert_eq "V4c.4d — un fichier d'un sous-dossier de scripts/ n'est pas mesuré : ok" "$(col_juger "$r" "$r/b.txt")" "ok"
# V4c.5 : comparaison de deux versions de la baseline (la hausse exige une citation d'arbitrage direct)
col_comparer() { # <avant> <après> <message> : « <code> <classes> »
  local av="$WORK/cmp-av.txt" ap="$WORK/cmp-ap.txt" out rc; printf '%s\n' "$1" > "$av"; printf '%s\n' "$2" > "$ap"
  out="$(node "$CLIQUET" comparer "$av" "$ap" "$3" 2>&1)"; rc=$?
  echo "$rc $(printf '%s\n' "$out" | awk '$1=="HAUSSE-SANS-ARBITRAGE"{print $1}' | sort -u | paste -sd, -)"
}
CITE='arbitrage Samuel, AskUserQuestion session principale, 2026-11-12'
assert_eq "V4c.5a — une baisse est acceptée (code 0)" "$(col_comparer 'scripts/vf-cockpit-a.mjs 3' 'scripts/vf-cockpit-a.mjs 2' 'refactor : replie des lignes')" "0 "
assert_eq "V4c.5b — une hausse sans citation : code 1 et HAUSSE-SANS-ARBITRAGE" "$(col_comparer 'scripts/vf-cockpit-a.mjs 2' 'scripts/vf-cockpit-a.mjs 3' 'refactor : rien à dire')" "1 HAUSSE-SANS-ARBITRAGE"
assert_eq "V4c.5b' — la sortie de la hausse nomme le fichier" "$(node "$CLIQUET" comparer "$WORK/cmp-av.txt" "$WORK/cmp-ap.txt" 'rien' 2>&1 | grep -c 'scripts/vf-cockpit-a.mjs')" "1"
assert_eq "V4c.5c — une hausse avec une citation conforme : code 0" "$(col_comparer 'scripts/vf-cockpit-a.mjs 2' 'scripts/vf-cockpit-a.mjs 3' "$CITE")" "0 "
assert_eq "V4c.5d — une nouvelle entrée à plus de 0 sans citation : code 1" "$(col_comparer '' 'scripts/vf-cockpit-b.mjs 1' 'rien')" "1 HAUSSE-SANS-ARBITRAGE"
assert_eq "V4c.5e — une citation sans date : code 1" "$(col_comparer 'scripts/vf-cockpit-a.mjs 2' 'scripts/vf-cockpit-a.mjs 3' 'arbitrage Samuel, session principale, hier')" "1 HAUSSE-SANS-ARBITRAGE"
assert_eq "V4c.5e' — une citation à une seule virgule : code 1" "$(col_comparer 'scripts/vf-cockpit-a.mjs 2' 'scripts/vf-cockpit-a.mjs 3' 'arbitrage Samuel, 2026-11-12')" "1 HAUSSE-SANS-ARBITRAGE"
assert_eq "V4c.5f — une citation conforme sans hausse : code 0" "$(col_comparer 'scripts/vf-cockpit-a.mjs 3' 'scripts/vf-cockpit-a.mjs 3' "$CITE")" "0 "
DELEG='décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée'
assert_eq "V4c.5g — la ligne de délégation ne vaut pas citation d'une hausse : code 1 et HAUSSE-SANS-ARBITRAGE" "$(col_comparer 'scripts/vf-cockpit-a.mjs 2' 'scripts/vf-cockpit-a.mjs 3' "$DELEG")" "1 HAUSSE-SANS-ARBITRAGE"
assert_eq "V4c.5g' — la délégation et un arbitrage direct sur deux lignes : code 0" "$(col_comparer 'scripts/vf-cockpit-a.mjs 2' 'scripts/vf-cockpit-a.mjs 3' "$DELEG
$CITE")" "0 "
# V4c.5h : toute forme de délégation écarte la ligne, pas seulement « déléguée » : une hausse ne se règle jamais par une ligne de délégation
col_cmp3() { col_comparer 'scripts/vf-cockpit-a.mjs 2' 'scripts/vf-cockpit-a.mjs 3' "$1"; }
DELEG_FORME='décision prise par délégation de Samuel (message session principale, 2026-11-08), option recommandée'
assert_eq "V4c.5h — « par délégation de Samuel » (la forme relevée par la revue rv-11, avec le mot « décision ») ne vaut pas citation d'une hausse : code 1" "$(col_cmp3 "$DELEG_FORME")" "1 HAUSSE-SANS-ARBITRAGE"
assert_eq "V4c.5h' — « DÉLÉGUÉE » en capitales : code 1" "$(col_cmp3 'décision DÉLÉGUÉE par Samuel (message session principale, 2026-11-08), option recommandée')" "1 HAUSSE-SANS-ARBITRAGE"
# chaque message de délégation ci-dessous passe TOUTES les autres conditions (mot-clé, deux virgules, date) : seul le filtre de délégation peut le refuser
col_nondirecte() { node "$CLIQUET" citation "$1" > /dev/null 2>&1; echo $?; }
DELEG_SANS_ACCENT='decision par delegation de Samuel, message session principale, 2026-11-08'
DELEG_A_DELEGUE='arbitrage : Samuel a délégué le choix, session principale, 2026-11-08'
DELEG_GRAVE='arbitrage Samuel, session principale, 2026-11-08 : Samuel délègue le choix'
DELEG_NFD="$(printf 'arbitrage Samuel, session principale, 2026-11-08 : de\xcc\x81le\xcc\x81gue\xcc\x81')"
DELEG_ZW="$(printf 'arbitrage Samuel, session principale, 2026-11-08 : de\xcc\x81\xe2\x80\x8bl\xc3\xa9gation')"
assert_eq "V4c.5h0 — témoin : chacun des messages de délégation ci-dessous est conforme sans le filtre (aucune autre condition ne le refuse)" "$(col_nondirecte "$DELEG_FORME") $(col_nondirecte "$DELEG_SANS_ACCENT") $(col_nondirecte "$DELEG_A_DELEGUE") $(col_nondirecte "$DELEG_GRAVE") $(col_nondirecte "$DELEG_NFD") $(col_nondirecte "$DELEG_ZW")" "0 0 0 0 0 0"
assert_eq "V4c.5h'' — « delegation » sans accents : code 1, refusé par le seul filtre" "$(col_cmp3 "$DELEG_SANS_ACCENT")" "1 HAUSSE-SANS-ARBITRAGE"
assert_eq "V4c.5h3 — « a délégué » : code 1, refusé par le seul filtre" "$(col_cmp3 "$DELEG_A_DELEGUE")" "1 HAUSSE-SANS-ARBITRAGE"
assert_eq "V4c.5h5 — « délègue » (accent grave) : code 1" "$(col_cmp3 "$DELEG_GRAVE")" "1 HAUSSE-SANS-ARBITRAGE"
assert_eq "V4c.5h6 — « délégué » en NFD (accent combinant) : code 1" "$(col_cmp3 "$DELEG_NFD")" "1 HAUSSE-SANS-ARBITRAGE"
assert_eq "V4c.5h7 — « délégation » coupée par un caractère de largeur nulle : code 1" "$(col_cmp3 "$DELEG_ZW")" "1 HAUSSE-SANS-ARBITRAGE"
# V4c.5i : la CLASSE, par un générateur de variantes (radicaux, casse, NFC/NFD, un caractère invisible à chaque position) : toutes refusées ; les citations légitimes restent acceptées
cat > "$WORK/gen-deleg.mjs" <<'FIN'
import fs from 'node:fs'; import { execFileSync } from 'node:child_process';
const [cliquet] = process.argv.slice(2);
// le filtre est relu dans la source de l'aide (le mutant modifie donc ce que le balayage mesure)
const delegation = new Function(`return (${fs.readFileSync(cliquet, 'utf8').match(/^const delegation = (.*);$/m)[1]})`)();
// un point de code est « lettre » s'il l'est après NFKD (hors fillers de Hangul, lettres sans trait) : seul ce qui n'en est pas doit disparaître
const lettre = (s) => /\p{L}/u.test(s.normalize('NFKD').replace(/[ᅟᅠㅤ]/gu, ''));
const mots = ['délégation'.normalize('NFC'), 'délégation'.normalize('NFD')];
const fuites = new Set(); let testes = 0;
for (let cp = 0; cp <= 0x10ffff; cp++) { // balayage complet, surrogates isolés compris
  const z = String.fromCodePoint(cp);
  if (lettre(z)) continue;
  for (const base of mots) { const t = [...base]; for (let i = 1; i < t.length; i++) { testes++; if (!delegation(t.slice(0, i).join('') + z + t.slice(i).join(''))) fuites.add(cp); } }
}
const statut = (m) => { try { execFileSync('node', [cliquet, 'citation', m, '--directe'], { stdio: 'ignore' }); return 0; } catch (e) { return e.status; } };
const legit = ['arbitrage Samuel, AskUserQuestion session principale, 2026-11-12', 'décision de Samuel, message session principale, 2026-11-08', 'arbitrage Samuel, canal WhatsApp, 2026-11-12 : option B'];
console.log(`${testes > 1e7 ? 'balaye' : 'court'} fuites=${fuites.size} legitimes=${legit.filter((m) => statut(m) === 0).length}/${legit.length}`);
FIN
col_generatif() { node "$WORK/gen-deleg.mjs" "$CLIQUET" | awk '{ print ($1=="balaye" ? "balaye" : "court") " " ($2=="fuites=0" ? "sans-fuite" : "fuite") " " ($3=="legitimes=3/3" ? "legitimes-ok" : "legitime-refusee") }'; }
assert_eq "V4c.5i — balayage de U+0000 à U+10FFFF : chaque point de code qui n'est pas une lettre, inséré à chaque position de « délégation » (NFC et NFD), est refusé sans fuite ; les citations légitimes sont toutes acceptées" "$(col_generatif)" "balaye sans-fuite legitimes-ok"
# V4c.5j : limites écrites, jamais corrigées (filtre lexical, ligne par ligne) : une coupure par retour à la ligne et un synonyme passent ; le test les fige pour qu'un changement soit vu
col_directe() { node "$CLIQUET" citation "$1" --directe > /dev/null 2>&1; echo $?; }
GAB='arbitrage Samuel, session principale, 2026-11-08 : '
assert_eq "V4c.5j — limites : « dé » puis « légation » sur deux lignes, « par procuration », « au nom de » passent (code 0, filtre lexical, ligne par ligne)" "$(col_directe "${GAB}dé
légation") $(col_directe "${GAB}par procuration") $(col_directe "${GAB}au nom de Samuel")" "0 0 0"
assert_eq "V4c.5j' — limite, faux positifs assumés : la compaction forme « deleg » à travers les mots (« mode léger », « le code legacy », « de légende ») : refus (code 1, fail-closed : on reformule)" "$(col_directe "${GAB}mode léger") $(col_directe "${GAB}le code legacy") $(col_directe "${GAB}de légende")" "1 1 1"
assert_eq "V4c.5h4 — la délégation et la citation directe sur deux lignes : code 0 (la ligne directe suffit)" "$(col_cmp3 "$DELEG_FORME
$CITE")" "0 "
# V4c.6 : l'historique git du fichier de baseline (dépôt jetable)
col_historique() { # <dépôt> <chemin relatif de la baseline> : « commits=N » puis une ligne par violation ; code 1 s'il y en a
  # « avant » = la version du parent si elle existe, sinon la DERNIÈRE version existante vue plus haut dans l'historique (une baseline supprimée
  # puis recréée plus haut est comparée à celle d'avant la suppression) ; la toute première création n'a rien à comparer
  local d="$1" p="$2" n=0 rc=0 sha out c have=0
  while IFS= read -r sha; do
    n=$((n+1)); git -C "$d" cat-file -e "$sha:$p" 2>/dev/null || continue
    git -C "$d" show "$sha:$p" > "$WORK/h-ap.txt"
    if git -C "$d" cat-file -e "$sha^:$p" 2>/dev/null; then git -C "$d" show "$sha^:$p" > "$WORK/h-av.txt"; elif [ "$have" = 1 ]; then cp "$WORK/h-prev.txt" "$WORK/h-av.txt"; else cp "$WORK/h-ap.txt" "$WORK/h-prev.txt"; have=1; continue; fi
    cp "$WORK/h-ap.txt" "$WORK/h-prev.txt"; have=1
    out="$(node "$CLIQUET" comparer "$WORK/h-av.txt" "$WORK/h-ap.txt" "$(git -C "$d" log -1 --format=%B "$sha")" 2>&1)" || { rc=1; c="$(git -C "$d" rev-parse --short=8 "$sha")"; printf '%s\n' "$out" | sed "s/^/$c /" >> "$WORK/h-viol.txt"; }
  done < <(git -C "$d" log --no-merges --reverse --format=%H -- "$p")
  if git -C "$d" cat-file -e "HEAD:$p" 2>/dev/null && [ -f "$d/$p" ]; then
    git -C "$d" show "HEAD:$p" > "$WORK/h-av.txt"
    out="$(node "$CLIQUET" comparer "$WORK/h-av.txt" "$d/$p" '' 2>&1)" || { rc=1; printf '%s\n' "$out" | sed 's/^/copie-de-travail /' >> "$WORK/h-viol.txt"; }
  fi
  echo "commits=$n"; [ ! -s "$WORK/h-viol.txt" ] || cat "$WORK/h-viol.txt"; return "$rc"
}
col_depot() { # <nom> <message de la hausse> : dépôt jetable à trois commits (création, hausse, baisse) ; imprime le dépôt
  local d="$WORK/dep-$1" g; rm -rf "$d"; mkdir -p "$d"; : > "$WORK/h-viol.txt"
  g() { git -C "$d" -c user.name=essai -c user.email=essai@example.invalid -c commit.gpgsign=false "$@" > /dev/null; }
  git -C "$d" init -q; printf '%s\n' '# base' 'scripts/vf-cockpit-a.mjs 2' > "$d/b.txt"; g add b.txt; g commit -q -m 'creation de la baseline'
  printf '%s\n' '# base' 'scripts/vf-cockpit-a.mjs 3' > "$d/b.txt"; g commit -q -a -m "$2"
  printf '%s\n' '# base' 'scripts/vf-cockpit-a.mjs 1' > "$d/b.txt"; g commit -q -a -m 'baisse de la baseline'
  printf '%s\n' "$d"
}
d="$(col_depot sans 'hausse sans rien')"; : > "$WORK/h-viol.txt"; col_historique "$d" b.txt > "$WORK/h6.out"; h6_rc=$?
assert_eq "V4c.6a — création, hausse sans citation, baisse : code 1 et le commit de la hausse est nommé" "$h6_rc $(grep -c "^$(git -C "$d" log --format=%h --grep='hausse sans rien' --abbrev=8) HAUSSE-SANS-ARBITRAGE" "$WORK/h6.out")" "1 1"
d="$(col_depot cite "hausse citee : $CITE")"; : > "$WORK/h-viol.txt"; col_historique "$d" b.txt > "$WORK/h6b.out"; h6_rc=$?
assert_eq "V4c.6b — le même historique avec une hausse citée : code 0, trois commits examinés" "$h6_rc $(head -1 "$WORK/h6b.out")" "0 commits=3"
d="$WORK/dep-seul"; rm -rf "$d"; mkdir -p "$d"; git -C "$d" init -q; printf '%s\n' 'scripts/vf-cockpit-a.mjs 2' > "$d/b.txt"; : > "$WORK/h-viol.txt"
git -C "$d" -c user.name=essai -c user.email=essai@example.invalid add b.txt; git -C "$d" -c user.name=essai -c user.email=essai@example.invalid -c commit.gpgsign=false commit -q -m 'creation seule'
col_historique "$d" b.txt > "$WORK/h6c.out"; h6_rc=$?
assert_eq "V4c.6c — création seule : code 0, un commit examiné, rien à comparer" "$h6_rc $(head -1 "$WORK/h6c.out")" "0 commits=1"
printf '%s\n' 'scripts/vf-cockpit-a.mjs 5' > "$d/b.txt"; : > "$WORK/h-viol.txt"; col_historique "$d" b.txt > "$WORK/h6d.out"; h6_rc=$?
assert_eq "V4c.6d — une hausse non commitée de la copie de travail est rouge" "$h6_rc $(grep -c '^copie-de-travail HAUSSE-SANS-ARBITRAGE' "$WORK/h6d.out")" "1 1"
col_depot_recree() { # <nom> <message de la recréation> : création à 2, suppression, recréation à 9 (trois commits successifs) ; imprime le dépôt
  local d="$WORK/dep-$1" g; rm -rf "$d"; mkdir -p "$d"; : > "$WORK/h-viol.txt"
  g() { git -C "$d" -c user.name=essai -c user.email=essai@example.invalid -c commit.gpgsign=false "$@" > /dev/null; }
  git -C "$d" init -q; printf '%s\n' '# base' 'scripts/vf-cockpit-a.mjs 2' > "$d/b.txt"; g add b.txt; g commit -q -m 'creation de la baseline'
  g rm -q b.txt; g commit -q -m 'suppression de la baseline'
  printf '%s\n' '# base' 'scripts/vf-cockpit-a.mjs 9' > "$d/b.txt"; g add b.txt; g commit -q -m "$2"
  printf '%s\n' "$d"
}
d="$(col_depot_recree sans 'recreation haute sans rien')"; col_historique "$d" b.txt > "$WORK/h6e.out"; h6_rc=$?
assert_eq "V4c.6e — baseline supprimée puis recréée plus haut (2 à 9), sans citation : code 1 et le commit de la recréation est nommé" "$h6_rc $(grep -c "^$(git -C "$d" log --format=%h --grep='recreation haute' --abbrev=8) HAUSSE-SANS-ARBITRAGE" "$WORK/h6e.out")" "1 1"
d="$(col_depot_recree cite "recreation haute citee : $CITE")"; col_historique "$d" b.txt > "$WORK/h6f.out"; h6_rc=$?
assert_eq "V4c.6f — la même recréation avec une citation d'arbitrage direct : code 0, trois commits examinés" "$h6_rc $(head -1 "$WORK/h6f.out")" "0 commits=3"
d="$(col_depot_recree deux 'recreation haute encore')"; printf '%s\n' '# base' 'scripts/vf-cockpit-a.mjs 1' > "$d/b.txt"; git -C "$d" -c user.name=essai -c user.email=essai@example.invalid -c commit.gpgsign=false commit -q -a -m 'baisse apres recreation'
printf '%s\n' '# base' 'scripts/vf-cockpit-a.mjs 2' > "$d/b.txt"; git -C "$d" -c user.name=essai -c user.email=essai@example.invalid -c commit.gpgsign=false commit -q -a -m 'remontee sans rien'; : > "$WORK/h-viol.txt"
col_historique "$d" b.txt > "$WORK/h6g.out"; h6_rc=$?
assert_eq "V4c.6g — recréation haute sans citation, baisse, puis remontée sans citation : code 1 et les deux hausses sont nommées" "$h6_rc $(grep -c ' HAUSSE-SANS-ARBITRAGE' "$WORK/h6g.out")" "1 2"
# V4c.7 : l'historique réel du fichier de baseline, dans le dépôt de développement seulement
DEPOT_DEV="$(git -C "$SCRIPTS" rev-parse --show-toplevel 2>/dev/null)"
if [ -n "$DEPOT_DEV" ] && [ -f "$DEPOT_DEV/plugin/cockpit/scripts/tests/test-cockpit-vendor.sh" ]; then
  : > "$WORK/h-viol.txt"; col_historique "$DEPOT_DEV" plugin/cockpit/scripts/tests/colonnes-baseline.txt > "$WORK/h7.out"; h7_rc=$?
  echo "     V4c.7 — $(head -1 "$WORK/h7.out") sur l'historique réel de la baseline"
  assert_eq "V4c.7 — l'historique réel du fichier de baseline ne porte aucune hausse sans citation" "$h7_rc" "0"
else echo "  ⏭  SKIP — V4c.7 (module posé hors du dépôt de développement : l'historique de la baseline n'est pas lisible ici, non compté)"; fi

# V4c.7b : deux messages RÉELS de l'historique de la branche (dépôt de développement seulement) : l'un sans citation directe (la hausse est refusée, la baisse acceptée), l'autre avec (la hausse passe)
if [ -n "$DEPOT_DEV" ] && [ -f "$DEPOT_DEV/plugin/cockpit/scripts/tests/test-cockpit-vendor.sh" ]; then
  reel_sans=""; reel_avec=""
  while IFS= read -r sha; do
    m="$(git -C "$DEPOT_DEV" log -1 --format=%B "$sha")"
    if node "$CLIQUET" citation "$m" --directe > /dev/null 2>&1; then [ -n "$reel_avec" ] || reel_avec="$m"; else [ -n "$reel_sans" ] || reel_sans="$m"; fi
    [ -n "$reel_avec" ] && [ -n "$reel_sans" ] && break
  done < <(git -C "$DEPOT_DEV" log --no-merges -n 400 --format=%H)
  assert_eq "V4c.7b.0 — témoin : l'historique porte un message réel sans citation directe et un message réel avec" "$([ -n "$reel_sans" ] && echo sans) $([ -n "$reel_avec" ] && echo avec)" "sans avec"
  assert_eq "V4c.7b.1 — un message réel sans citation directe : une hausse est refusée (code 1)" "$(col_comparer 'scripts/vf-cockpit-a.mjs 2' 'scripts/vf-cockpit-a.mjs 3' "$reel_sans")" "1 HAUSSE-SANS-ARBITRAGE"
  assert_eq "V4c.7b.2 — le même message réel : une baisse est acceptée (code 0)" "$(col_comparer 'scripts/vf-cockpit-a.mjs 3' 'scripts/vf-cockpit-a.mjs 2' "$reel_sans")" "0 "
  assert_eq "V4c.7b.3 — un message réel avec citation directe : une hausse passe (code 0), une citation légitime passe toujours" "$(col_comparer 'scripts/vf-cockpit-a.mjs 2' 'scripts/vf-cockpit-a.mjs 3' "$reel_avec")" "0 "
else echo "  ⏭  SKIP — V4c.7b (module posé hors du dépôt de développement : pas d'historique réel, non compté)"; fi

# V4c.8 : cinq mutants de l'aide (copies jetables, variable CLIQUET) ; chacun change la copie (.0), rougit le témoin qui le vise et laisse son témoin voisin vert
col_mutant() { # <nom> <expression sed> : copie mutée de l'aide dans $WORK/mut-<nom>/ ; code 0 si la copie diffère de l'aide
  mkdir -p "$WORK/mut-$1"; sed "$2" "$CLIQUET" > "$WORK/mut-$1/colonnes-cliquet.mjs" 2>/dev/null
  [ -s "$WORK/mut-$1/colonnes-cliquet.mjs" ] && ! cmp -s "$CLIQUET" "$WORK/mut-$1/colonnes-cliquet.mjs"
}
col_orph() { local r; r="$(col_racine orphm)"; col_base "$r/b.txt" 'scripts/vf-cockpit-absent.mjs 1'; col_juger "$r" "$r/b.txt"; }
col_mutant_temoin() { # <nom> <expression sed> <libellé> <fonction visée> <attendu sain> <fonction voisine> <attendu voisin>
  local m="$WORK/mut-$1/colonnes-cliquet.mjs"
  assert_eq "V4c.8 — M-$1.0 : la substitution change la copie de l'aide" "$(col_mutant "$1" "$2" && echo change || echo identique)" "change"
  assert_eq "V4c.8 — M-$1 : $3" "$(CLIQUET="$m" $4 | sed 's/^/mutant:/')" "mutant:$5"
  assert_eq "V4c.8 — M-$1' : le témoin voisin reste juste (le mutant ne rougit que le sien)" "$(CLIQUET="$m" $6)" "$7"
}
col_v160x() { col_v u160m 160 x; }; col_v161x() { col_v u161m 161 x; }; col_v150e() { col_v e150m 150 e; }; col_v160c() { col_v c160m 160 cr; }
col_mutant_temoin OCTETS 's|\[\.\.\.sansCr(l)\]\.length|Buffer.byteLength(sansCr(l))|' "la mesure compte des octets : 150 lettres accentuées deviennent rouges (V4c.1c)" col_v150e "rouge HAUSSE" col_v160x "ok"
col_mutant_temoin SEUIL 's/SEUIL = 160;/SEUIL = 161;/' "le plafond relâché d'une colonne : 161 passe (V4c.1a)" col_v161x "ok" col_v160x "ok"
col_mutant_temoin MARQUEUR 's|const comptes = (texte) => |const comptes = (texte) => /vibeflow:allow-large-file/.test(texte.split("\\n").slice(0, 5).join("\\n")) ? 0 : |' "le marqueur exempte : 161 sous marqueur passe (V4c.3)" col_vmarq "ok" col_v161x "rouge HAUSSE"
col_mutant_temoin CR "s|l\\.replace(/\\\\r\\$/, '')|l|" "le CR final est compté : 160 plus CR deviennent rouges (V4c.1d)" col_v160c "rouge HAUSSE" col_v160x "ok"
col_mutant_temoin ORPHELINE "s|v\\.push(\\['ORPHELINE', c\\]);|;|" "les entrées orphelines sont ignorées (V4c.2b)" col_orph "ok" col_v160x "ok"
col_deleg_forme() { col_cmp3 "$DELEG_FORME"; }; col_cite_ok() { col_cmp3 "$CITE"; }; col_dbl() { col_vdbl dblm 'scripts/vf-cockpit-a.mjs 1' 'scripts/vf-cockpit-a.mjs 1'; }
col_deleg_sans_accent() { col_cmp3 "$DELEG_SANS_ACCENT"; }
col_mutant_temoin DELEGATION 's|/deleg/i|/dél[ée]gu/i|' "le filtre ne voit que « déléguée » accentué : « delegation » et « par délégation » valent citation (V4c.5h'')" col_deleg_sans_accent "0 " col_cite_ok "0 "
col_mutant_temoin DELEGATION2 's|/deleg/i|/dél[ée]g/i|' "le filtre sans normalisation d'accents : « delegation » sans accent vaut citation (V4c.5h'')" col_deleg_sans_accent "0 " col_cite_ok "0 "
col_mutant_temoin NORMALISATION "s|l\.normalize[(]'NFKD'[)]\.replace|l.replace|" "le filtre lit le texte sans NFKD : « délégation » accentuée vaut citation (V4c.5i)" col_generatif "balaye fuite legitimes-ok" col_cite_ok "0 "
col_mutant_temoin GARDE-P 's|/[[]^[\\]p{L}[]]|/[^\\p{L}\\p{P}]|' "on garde aussi la ponctuation \p{P} : « dé'léguée », « dé/ » valent citation (V4c.5i)" col_generatif "balaye fuite legitimes-ok" col_cite_ok "0 "
col_mutant_temoin GARDE-S 's|/[[]^[\\]p{L}[]]|/[^\\p{L}\\p{S}]|' "on garde aussi les symboles \p{S} (V4c.5i)" col_generatif "balaye fuite legitimes-ok" col_cite_ok "0 "
col_mutant_temoin GARDE-Z 's|/[[]^[\\]p{L}[]]|/[^\\p{L}\\p{Z}]|' "on garde aussi les séparateurs \p{Z} : « dé léguée » vaut citation (V4c.5i)" col_generatif "balaye fuite legitimes-ok" col_cite_ok "0 "
col_mutant_temoin REMPLI 's#[|][[][\\]u115f[\\]u1160[\\]u3164[]]##' "les fillers de Hangul, des lettres sans trait, ne sont plus retirés (V4c.5i)" col_generatif "balaye fuite legitimes-ok" col_cite_ok "0 "
col_mutant_temoin DOUBLON 's/ || entrees\.has(c\[0\])//' "un fichier nommé deux fois est accepté : la seconde entrée écrase la première (V4c.2b6)" col_dbl "ok" col_v160x "ok"
col_mutant_temoin INITIALISER 's|^  if (fs\.existsSync(b)) fin(1,.*$||' "initialiser réécrit une baseline qui existe (V4c.2c)" col_init_existe "0 modifiee" col_init_neuf "0 ok"

# V4c.9 : le réel (armé par 79-11, état trouvé après rangement) : le vrai module contre la vraie baseline, et deux mutations de copie
BASE_REELLE="$SCRIPTS/tests/colonnes-baseline.txt"
assert_ge "V4c.9 — témoin : la vraie baseline liste au moins 50 fichiers" "$(grep -c -v -E '^#|^$' "$BASE_REELLE" 2>/dev/null || echo 0)" 50
assert_eq "V4c.9a — le vrai module égale la vraie baseline (aucune hausse, aucune baisse non suivie)" "$(col_juger "$RACINE_MODULE" "$BASE_REELLE")" "ok"
PREMIERE="$(grep -v -E '^#|^$' "$BASE_REELLE" | sed -n 1p)"; FICHIER_1="${PREMIERE% *}"
grep -v -x -F "$PREMIERE" "$BASE_REELLE" > "$WORK/base-privee.txt"
assert_eq "V4c.9b — une copie de la baseline privée de sa première ligne : HAUSSE, le fichier est nommé" "$(col_juger "$RACINE_MODULE" "$WORK/base-privee.txt") $(node "$CLIQUET" verifier "$RACINE_MODULE" "$WORK/base-privee.txt" 2>&1 | grep -c -F "$FICHIER_1")" "rouge HAUSSE 1"
awk -v f="$FICHIER_1" '$1==f && !fait {print $1, $2+1; fait=1; next} {print}' "$BASE_REELLE" > "$WORK/base-relevee.txt"
assert_eq "V4c.9c — la baseline relevée de 1, sans citation : comparer contre la version en place rougit (code 1)" "$(node "$CLIQUET" comparer "$BASE_REELLE" "$WORK/base-relevee.txt" 'rien' >/dev/null 2>&1; echo $?)" "1"
assert_eq "V4c.9d — la même hausse avec une citation d'arbitrage direct : code 0" "$(node "$CLIQUET" comparer "$BASE_REELLE" "$WORK/base-relevee.txt" 'arbitrage Samuel, AskUserQuestion session principale, 2026-11-13' >/dev/null 2>&1; echo $?)" "0"

echo "=== V11 — code navigateur rangé en fichiers, lu comme texte (AUDC-AM5, P79-D-19) ==="
NAV="$SCRIPTS/vf-cockpit-navigateur.mjs"
# nav_noms <dossier> : noms de FICHIERS_NAVIGATEUR pour ce dossier, triés, séparés par un espace ; « absent » si l'export manque
nav_noms() {
  node --input-type=module -e "import { pathToFileURL } from 'node:url'; const m = await import(pathToFileURL(process.argv[1]).href); console.log(m.FICHIERS_NAVIGATEUR.filter((p) => p[0] === process.argv[2]).map((p) => p[1]).sort().join(' '));" "$NAV" "$1" 2>/dev/null || echo absent
}
dossier_noms() { ls "$MOTEUR/assets/ui/$1" 2>/dev/null | LC_ALL=C sort | paste -sd' ' -; }
ajout_noms() { awk -v d="assets/ui/$1/" '$1=="AJOUT" && index($2, d)==1 {print substr($2, length(d)+1)}' "$MOTEUR/VENDORED.txt" | LC_ALL=C sort | paste -sd' ' -; }
assert_eq "V11.Q1a — FICHIERS_NAVIGATEUR : les noms du dossier terminal" "$(nav_noms terminal)" "client.js q.css vue.js"
assert_eq "V11.Q1b — les fichiers présents du dossier assets/ui/terminal" "$(dossier_noms terminal)" "client.js q.css vue.js"
assert_eq "V11.Q1c — les lignes AJOUT de VENDORED.txt pour le dossier terminal" "$(ajout_noms terminal)" "client.js q.css vue.js"
# q2.mjs <moteur> : la page de Q (sombre et clair) assemble, dans l'ordre, la feuille de Q puis la vue et le client, chacun dans son <script> sans attribut
cat > "$WORK/q2.mjs" <<'FIN'
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [moteur, scripts] = process.argv.slice(2);
const page = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-terminal-page.mjs')).href);
page.preparerPage({ engineDir: moteur });
const lire = (n) => fs.readFileSync(path.join(moteur, 'assets/ui/terminal', n), 'utf8');
const css = lire('q.css'), vue = lire('vue.js').replace(/\n$/, ''), client = lire('client.js').replace(/\n$/, '');
const o = "http://127.0.0.1:4100";
for (const theme of ['dark', 'light']) {
  const cfg = JSON.stringify({ origineP: o, theme }).replace(/</g, '\\u003c');
  const { html } = page.pageTerminal({ theme, origineP: o });
  const pieces = [`\n${css}</style>`, `<script>(${vue})(${cfg});</script>`, `<script>(${client})(${cfg});</script>`];
  let pos = -1, ok = true;
  for (const p of pieces) { const i = html.indexOf(p, pos + 1); if (i <= pos) ok = false; pos = i; }
  console.log(`${theme} ${ok ? 'ordre-ok' : 'ordre-ko'} vue=${vue.length > 1000} client=${client.length > 1000}`);
}
FIN
Q2="$(node "$WORK/q2.mjs" "$MOTEUR" "$SCRIPTS" 2>&1 | tr '\n' '/')"
assert_eq "V11.Q2 — pageTerminal (sombre et clair) : feuille q.css, puis vue.js et client.js dans leurs <script> sans attribut, dans l'ordre" "$Q2" "dark ordre-ok vue=true client=true/light ordre-ok vue=true client=true/"
# q3.mjs : une copie du dossier du moteur dont client.js porte une mutation d'un caractère : la page ET la CSP changent
mkdir -p "$WORK/q3/assets" && cp -R "$MOTEUR/assets/vendor" "$WORK/q3/assets/vendor" && mkdir -p "$WORK/q3/assets/ui" && cp -R "$MOTEUR/assets/ui/terminal" "$WORK/q3/assets/ui/terminal" 2>/dev/null
cat > "$WORK/q3.mjs" <<'FIN'
import fs from 'node:fs'; import path from 'node:path'; import crypto from 'node:crypto'; import { pathToFileURL } from 'node:url';
const [copie, scripts] = process.argv.slice(2), o = 'http://127.0.0.1:4100';
const rendre = async (moteur, v) => { const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-terminal-page.mjs')).href + '?v=' + v); m.preparerPage({ engineDir: moteur }); return m.pageTerminal({ theme: 'dark', origineP: o }); };
const f = path.join(copie, 'assets/ui/terminal/client.js');
const avant = await rendre(copie, 'a'); const t = fs.readFileSync(f, 'utf8');
fs.writeFileSync(f, t.replace('const MODES', 'const MUTE = 1; const MODES'));
const apres = await rendre(copie, 'b');
const empreinte = (h) => { const m = [...h.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((x) => `'sha256-${crypto.createHash('sha256').update(x[1]).digest('base64')}'`); return m[m.length - 1]; };
console.log([avant.html !== apres.html, avant.csp !== apres.csp, apres.html.includes('const MUTE = 1;'), apres.csp.includes(empreinte(apres.html))].join(' '));
FIN
assert_eq "V11.Q3 — client.js muté dans une copie : la page change, la CSP change, la page porte la mutation, la CSP porte l'empreinte du script muté" "$(node "$WORK/q3.mjs" "$WORK/q3" "$SCRIPTS" 2>&1 | tail -1)" "true true true true"
# q4.mjs : le lecteur fermé par défaut, un refus par cause
cat > "$WORK/q4.mjs" <<'FIN'
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [dossierTmp, nav] = process.argv.slice(2);
const m = await import(pathToFileURL(nav).href);
const FONCTION = 'function vue(cfg) {\n  void cfg;\n}\n';
const neuf = (nom) => { const racine = path.join(dossierTmp, nom); fs.mkdirSync(path.join(racine, 'assets/ui/terminal'), { recursive: true }); return racine; };
const ecrire = (racine, nom, contenu) => fs.writeFileSync(path.join(racine, 'assets/ui/terminal', nom), contenu);
const essai = (cas, fn) => { try { const r = fn(); console.log(`${cas}=lu:${r.length}`); } catch (e) { console.log(`${cas}=refus:${/vue\.js|q\.css|autre|hors|liste|terminal|client/.test(String(e.message)) ? 'nomme' : 'muet'}`); } };
const lf = (r, d = 'terminal', n = 'vue.js') => () => m.lireFonction(d, n, { moteur: r });
let r = neuf('intact'); ecrire(r, 'vue.js', FONCTION); essai('intact', lf(r));
console.log(`intact-sans-fin=${(() => { try { return m.lireFonction('terminal', 'vue.js', { moteur: r }) === FONCTION.slice(0, -1); } catch { return 'erreur'; } })()}`);
r = neuf('hors-liste'); ecrire(r, 'autre.js', FONCTION); essai('hors-liste', lf(r, 'terminal', 'autre.js'));
r = neuf('dossier'); essai('dossier-hors-liste', lf(r, 'inconnu', 'vue.js'));
r = neuf('lien'); fs.writeFileSync(path.join(r, 'reel.js'), FONCTION); fs.symlinkSync(path.join(r, 'reel.js'), path.join(r, 'assets/ui/terminal/vue.js')); essai('lien', lf(r));
r = neuf('chemin'); fs.rmSync(path.join(r, 'assets/ui/terminal'), { recursive: true }); fs.mkdirSync(path.join(r, 'ailleurs')); fs.writeFileSync(path.join(r, 'ailleurs/vue.js'), FONCTION); fs.symlinkSync(path.join(r, 'ailleurs'), path.join(r, 'assets/ui/terminal')); essai('chemin-sorti', lf(r));
r = neuf('gros'); ecrire(r, 'vue.js', FONCTION.slice(0, -2) + '/* ' + 'x'.repeat(256 * 1024) + ' */\n}\n'); essai('gros', lf(r));
r = neuf('nul'); ecrire(r, 'vue.js', 'function vue() {\0}\n'); essai('nul', lf(r));
r = neuf('script'); ecrire(r, 'vue.js', 'function vue() { const s = "</SCRIPT>"; }\n'); essai('fermeture-script', lf(r));
r = neuf('absent'); essai('absent', lf(r));
r = neuf('feuille'); ecrire(r, 'q.css', 'a { color: red } </style><script>x</script>'); essai('fermeture-feuille', () => m.lireFeuille('terminal', 'q.css', { moteur: r }));
r = neuf('feuille-ok'); ecrire(r, 'q.css', 'a { color: red }\n'); console.log(`feuille-telle-quelle=${m.lireFeuille('terminal', 'q.css', { moteur: r }) === 'a { color: red }\n'}`);
FIN
mkdir -p "$WORK/q4"; node "$WORK/q4.mjs" "$WORK/q4" "$NAV" > "$WORK/q4.out" 2>&1
q4() { grep -c -x -- "$1" "$WORK/q4.out"; }
assert_eq "V11.Q4a — témoin positif : le fichier intact est lu" "$(q4 'intact=lu:'"$(printf 'function vue(cfg) {\n  void cfg;\n}' | wc -c | tr -d ' ')")" "1"
assert_eq "V11.Q4b — une seule fin de ligne est retirée" "$(q4 'intact-sans-fin=true')" "1"
assert_eq "V11.Q4c — un nom hors liste est refusé, en nommant le fichier" "$(q4 'hors-liste=refus:nomme')" "1"
assert_eq "V11.Q4d — un dossier hors liste est refusé" "$(q4 'dossier-hors-liste=refus:nomme')" "1"
assert_eq "V11.Q4e — un lien symbolique à la place du fichier est refusé" "$(q4 'lien=refus:nomme')" "1"
assert_eq "V11.Q4f — un chemin dont la résolution sort du dossier est refusé" "$(q4 'chemin-sorti=refus:nomme')" "1"
assert_eq "V11.Q4g — un fichier de 256 Kio plus un octet est refusé" "$(q4 'gros=refus:nomme')" "1"
assert_eq "V11.Q4h — un octet nul est refusé" "$(q4 'nul=refus:nomme')" "1"
assert_eq "V11.Q4i — une fermeture de script dans une fonction est refusée (casse ignorée)" "$(q4 'fermeture-script=refus:nomme')" "1"
assert_eq "V11.Q4j — une fermeture de feuille dans une feuille est refusée" "$(q4 'fermeture-feuille=refus:nomme')" "1"
assert_eq "V11.Q4k — un fichier absent est refusé" "$(q4 'absent=refus:nomme')" "1"
assert_eq "V11.Q4l — une feuille intacte est rendue telle quelle" "$(q4 'feuille-telle-quelle=true')" "1"
# q4b.mjs : les gardes du contenu d'une fonction, un fichier par cause (chacune refusée par le lecteur, chacune lue par le mutant qui retire sa garde)
cat > "$WORK/q4b.mjs" <<'FIN'
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [dossierTmp, nav] = process.argv.slice(2);
const m = await import(pathToFileURL(nav).href);
const cas = (nom, contenu) => {
  const racine = path.join(dossierTmp, nom); fs.mkdirSync(path.join(racine, 'assets/ui/terminal'), { recursive: true });
  fs.writeFileSync(path.join(racine, 'assets/ui/terminal/vue.js'), contenu);
  try { m.lireFonction('terminal', 'vue.js', { moteur: racine }); console.log(`${nom}=lu`); } catch (e) { console.log(`${nom}=refus:${/vue\.js/.test(String(e.message)) ? 'nomme' : 'muet'}`); }
};
cas('intact', 'function vue() {\n  return 1;\n}\n');
cas('intact-sans-fin', 'function vue() {\n  return 1;\n}');
cas('utf8', Buffer.concat([Buffer.from('function vue() { /* '), Buffer.from([0xff, 0xfe]), Buffer.from(' */ }\n')]));
cas('deux-fins', 'function vue() {\n}\n\n');
cas('espace-en-tete', ' function vue() {\n}\n');
cas('ligne-vide-en-tete', '\nfunction vue() {\n}\n');
cas('espace-en-queue', 'function vue() {\n} \n');
cas('commentaire-html', 'function vue() { const s = "<!--"; }\n');
cas('sans-accolade', 'function vue() {\n} // fin\n');
cas('sans-function', 'const vue = () => {\n};\nfunction f() {\n}\n');
FIN
mkdir -p "$WORK/q4b"; node "$WORK/q4b.mjs" "$WORK/q4b" "$NAV" > "$WORK/q4b.out" 2>&1
q4b() { grep -c -x -- "$1" "$WORK/q4b.out"; }
assert_eq "V11.Q4m — témoin positif : deux fonctions intactes (avec et sans fin de ligne) sont lues" "$(q4b 'intact=lu') $(q4b 'intact-sans-fin=lu')" "1 1"
assert_eq "V11.Q4n — un fichier qui n'est pas de l'UTF-8 est refusé, en nommant le fichier" "$(q4b 'utf8=refus:nomme')" "1"
assert_eq "V11.Q4o — une seconde fin de ligne n'est pas retirée : refus (la fonction ne finit plus par l'accolade)" "$(q4b 'deux-fins=refus:nomme')" "1"
assert_eq "V11.Q4p — un espace ou une ligne vide avant « function », ou un espace avant la fin de ligne : refus" "$(q4b 'espace-en-tete=refus:nomme') $(q4b 'ligne-vide-en-tete=refus:nomme') $(q4b 'espace-en-queue=refus:nomme')" "1 1 1"
assert_eq "V11.Q4q — un commentaire HTML dans la fonction est refusé" "$(q4b 'commentaire-html=refus:nomme')" "1"
assert_eq "V11.Q4r — une fonction qui ne finit pas par une accolade est refusée" "$(q4b 'sans-accolade=refus:nomme')" "1"
assert_eq "V11.Q4s — un fichier qui ne commence pas à « function » est refusé" "$(q4b 'sans-function=refus:nomme')" "1"
# V11.Q4t : cinq mutants du lecteur (copies jetables) ; chacun change la copie, laisse lire le cas qui le vise et laisse lire le témoin intact
nav_mutant() { # <nom> <expression sed -E> : copie mutée du lecteur dans $WORK/navm-<nom>/ ; code 0 si la copie diffère du lecteur
  mkdir -p "$WORK/navm-$1"; sed -E "$2" "$NAV" > "$WORK/navm-$1/vf-cockpit-navigateur.mjs" 2>/dev/null
  [ -s "$WORK/navm-$1/vf-cockpit-navigateur.mjs" ] && ! cmp -s "$NAV" "$WORK/navm-$1/vf-cockpit-navigateur.mjs"
}
nav_mutant_temoin() { # <nom> <expression sed -E> <cas visé>
  nav_mutant "$1" "$2" && c0=change || c0=identique
  assert_eq "V11.Q4t — M-$1.0 : la substitution change la copie du lecteur" "$c0" "change"
  mkdir -p "$WORK/navm-$1/t"; node "$WORK/q4b.mjs" "$WORK/navm-$1/t" "$WORK/navm-$1/vf-cockpit-navigateur.mjs" > "$WORK/navm-$1/sortie.txt" 2>&1
  assert_eq "V11.Q4t — M-$1 : le cas « $3 » est lu (la garde retirée ne protège plus) et le témoin intact reste lu" "$(grep -c -x -- "$3=lu" "$WORK/navm-$1/sortie.txt") $(grep -c -x -- 'intact=lu' "$WORK/navm-$1/sortie.txt")" "1 1"
}
nav_mutant_temoin UTF8 's/fatal: true/fatal: false/' utf8
nav_mutant_temoin TRIM 's/const texte = brut\.endsWith.*$/const texte = brut.trim();/' deux-fins
nav_mutant_temoin TRIM2 's/const texte = brut\.endsWith.*$/const texte = brut.trim();/' espace-en-tete
nav_mutant_temoin HTML 's/ \|\| texte\.includes\(.<!--.\)//' commentaire-html
nav_mutant_temoin ACCOLADE 's/ \|\| !texte\.endsWith\(.\}.\)//' sans-accolade
nav_mutant_temoin FUNCTION 's/!texte\.startsWith\(.function .\) \|\| //' sans-function
# V11.Q5 : ni conversion de fonction en chaîne ni évaluation dynamique de code dans le lecteur et la page
MOTIF_EVAL='\.toString\(\)|new Function|[^a-zA-Z.]eval\(|node:vm'
printf '%s\n' 'const s = f.toString();' > "$WORK/q5-t1.txt"; printf '%s\n' 'const g = new Function("x");' > "$WORK/q5-t2.txt"; printf '%s\n' 'const r = eval(code);' > "$WORK/q5-t3.txt"; printf '%s\n' "import vm from 'node:vm';" > "$WORK/q5-t4.txt"
assert_eq "V11.Q5 — témoin positif : le motif se déclenche sur ses quatre lignes d'exemple" "$(cat "$WORK"/q5-t[1-4].txt | grep -c -E "$MOTIF_EVAL")" "4"
q5=0; for f in "$NAV" "$SCRIPTS/vf-cockpit-terminal-page.mjs"; do [ -f "$f" ] || { q5=-99; break; }; q5=$((q5 + $(grep -c -E "$MOTIF_EVAL" "$f"))); done
assert_eq "V11.Q5a — le lecteur et la page de Q : aucune conversion de fonction en chaîne, aucune évaluation dynamique" "$q5" "0"
# q6.mjs : la liste du code évalué et l'empreinte du module couvrent les fichiers de Q
cat > "$WORK/q6.mjs" <<'FIN'
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [racine] = process.argv.slice(2), scripts = path.join(racine, 'scripts'), moteur = path.join(racine, 'skills/cockpit-moteur');
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-module.mjs')).href);
const cles = m.fichiersCodeEvalue(scripts, moteur).map((x) => x[0]);
console.log(`liste=${['client.js', 'q.css', 'vue.js'].every((n) => cles.includes(`assets/ui/terminal/${n}`))}`);
const h0 = m.empreinteModule({ dossierScripts: scripts, dossierMoteur: moteur });
const f = path.join(moteur, 'assets/ui/terminal/client.js'), t = fs.readFileSync(f);
fs.writeFileSync(f, Buffer.concat([t, Buffer.from(' ')]));
const h1 = m.empreinteModule({ dossierScripts: scripts, dossierMoteur: moteur });
fs.rmSync(f);
const h2 = m.empreinteModule({ dossierScripts: scripts, dossierMoteur: moteur });
console.log(`stable=${typeof h0 === 'string' && h0.length === 12} octet=${typeof h1 === 'string' && h1 !== h0} supprime=${h2 === null}`);
FIN
# copie jetable : les fichiers demandes ET leur fermeture transitive des imports relatifs (`from './x.mjs'`) ; un import neuf est suivi sans toucher la suite
copier_avec_imports() { # <dossier-cible> <fichier>... (chemins absolus)
  local dest="$1" file dep vus=""; shift
  local file_list=("$@")
  while [ ${#file_list[@]} -gt 0 ]; do
    file="${file_list[0]}"; file_list=("${file_list[@]:1}")
    case " $vus " in *" $file "*) continue;; esac
    vus="$vus $file"; cp "$file" "$dest/" 2>/dev/null || continue
    for dep in $(sed -nE "s/^[[:space:]]*(import|export)[^'\"]*from[[:space:]]+'\.\/([^']+)'.*/\2/p" "$file"); do
      file_list=("${file_list[@]}" "$(dirname "$file")/$dep")
    done
  done
}
rm -rf "$WORK/q6"; mkdir -p "$WORK/q6/scripts" "$WORK/q6/skills/cockpit-moteur/assets/ui"; copier_avec_imports "$WORK/q6/scripts" "$SCRIPTS"/vf-cockpit-module.mjs "$SCRIPTS"/vf-cockpit-navigateur.mjs
cp "$MOTEUR/assets/serve.mjs" "$WORK/q6/skills/cockpit-moteur/assets/"; cp -R "$MOTEUR/assets/ui/terminal" "$WORK/q6/skills/cockpit-moteur/assets/ui/terminal" 2>/dev/null; cp -R "$MOTEUR/assets/ui/tiroir" "$WORK/q6/skills/cockpit-moteur/assets/ui/tiroir" 2>/dev/null   # la liste close porte aussi les neuf fichiers de P
node "$WORK/q6.mjs" "$WORK/q6" > "$WORK/q6.out" 2>&1
assert_eq "V11.Q6a — fichiersCodeEvalue liste les trois fichiers de Q" "$(sed -n 1p "$WORK/q6.out")" "liste=true"
assert_eq "V11.Q6b — l'empreinte est calculée, change d'un octet dans client.js d'une copie, et devient nulle quand client.js manque" "$(sed -n 2p "$WORK/q6.out")" "stable=true octet=true supprime=true"

# --- V11.P : tiroir et lancement de la page hôte P (assets/ui/tiroir, lus à l'injection sous --terminal seulement) ---
NOMS_P="lancer-extraire-chat.js lancer-observer-chat.js lancer-proposition.js lancer.css lancer.js tiroir-construire.js tiroir-message.js tiroir.css tiroir.js"
assert_eq "V11.P1a — FICHIERS_NAVIGATEUR : les neuf noms du dossier tiroir" "$(nav_noms tiroir)" "$NOMS_P"
assert_eq "V11.P1b — les fichiers présents du dossier assets/ui/tiroir" "$(dossier_noms tiroir)" "$NOMS_P"
assert_eq "V11.P1c — les lignes AJOUT de VENDORED.txt pour le dossier tiroir" "$(ajout_noms tiroir)" "$NOMS_P"
retires=""; for m in terminal-client terminal-vue terminal-style terminal-tiroir-ui terminal-tiroir-style lancer-style; do [ -e "$SCRIPTS/vf-cockpit-$m.mjs" ] && retires="$retires $m"; done
assert_eq "V11.P1d — les six modules du plan n'existent plus (client, vue, feuille de Q, interface du tiroir, deux feuilles)" "${retires:-aucun}" "aucun"
# p2.mjs <racine d'un module> : les deux injections sont faites des fichiers rangés, dans l'ordre
cat > "$WORK/p2.mjs" <<'FIN'
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [racine] = process.argv.slice(2), moteur = path.join(racine, 'skills/cockpit-moteur/assets/ui/tiroir');
const charger = (n) => import(pathToFileURL(path.join(racine, 'scripts', n)).href + '?v=' + Math.random());
const t = await charger('vf-cockpit-terminal-tiroir.mjs'), l = await charger('vf-cockpit-lancer-ui.mjs');
const lire = (n, css) => { const x = fs.readFileSync(path.join(moteur, n), 'utf8'); return css || !x.endsWith('\n') ? x : x.slice(0, -1); };
const dans = (h, pieces) => { let pos = -1; for (const p of pieces) { const i = h.indexOf(p, pos + 1); if (i <= pos) return false; pos = i; } return true; };
const it = t.injectionTiroir();
const a = it.indexOf(`(${lire('tiroir.js')})(`), b = it.indexOf(`, ${lire('tiroir-message.js')}, ${lire('tiroir-construire.js')});\n`);
let cfgT = false; try { cfgT = JSON.parse(it.slice(a + lire('tiroir.js').length + 3, b)).indisponible === false; } catch {}
console.log(`tiroir=${dans(it, [`<style>${lire('tiroir.css', true)}</style><script>`, `(${lire('tiroir.js')})(`]) && a > 0 && b > a && cfgT}`);
const il = l.injectionLancer();
const c = il.indexOf(`(${lire('lancer.js')})(`), d = il.indexOf(`, ${lire('lancer-extraire-chat.js')}, ${lire('lancer-observer-chat.js')}, ${lire('lancer-proposition.js')});\n`);
let cfgL = false; try { cfgL = JSON.parse(il.slice(c + lire('lancer.js').length + 3, d)).css === lire('lancer.css', true); } catch {}
console.log(`lancer=${c > 0 && d > c && il.startsWith('<script>') && cfgL}`);
console.log(`indispo=${JSON.stringify(l.injectionLancer({ indisponible: true }))}`);
FIN
node "$WORK/p2.mjs" "$RACINE_MODULE" > "$WORK/p2.out" 2>&1
assert_eq "V11.P2a — injectionTiroir : la feuille tiroir.css dans son <style>, puis (tiroir.js)(configuration JSON, tiroir-message.js, tiroir-construire.js)" "$(sed -n 1p "$WORK/p2.out")" "tiroir=true"
assert_eq "V11.P2b — injectionLancer : (lancer.js)(configuration portant lancer.css, extraire, observer, proposition)" "$(sed -n 2p "$WORK/p2.out")" "lancer=true"
assert_eq "V11.P2c — injectionLancer({ indisponible }) rend la chaîne vide" "$(sed -n 3p "$WORK/p2.out")" 'indispo=""'
# p3 : une copie jetable du module (scripts utiles et moteur réduit) : un fichier muté change l'injection ; un fichier illisible la rend vide avec une ligne d'erreur
mini_module() { # <dossier> : copie réduite du module (le lecteur, le module, les deux injecteurs et le dossier rangé)
  rm -rf "$1"; mkdir -p "$1/scripts" "$1/skills/cockpit-moteur/assets/ui"
  copier_avec_imports "$1/scripts" "$SCRIPTS"/vf-cockpit-module.mjs "$SCRIPTS"/vf-cockpit-navigateur.mjs "$SCRIPTS"/vf-cockpit-terminal-tiroir.mjs "$SCRIPTS"/vf-cockpit-lancer-ui.mjs
  cp "$MOTEUR/assets/serve.mjs" "$1/skills/cockpit-moteur/assets/" 2>/dev/null; cp -R "$MOTEUR/assets/ui/terminal" "$MOTEUR/assets/ui/tiroir" "$1/skills/cockpit-moteur/assets/ui/" 2>/dev/null
}
cat > "$WORK/p3.mjs" <<'FIN'
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [racine] = process.argv.slice(2), f = path.join(racine, 'skills/cockpit-moteur/assets/ui/tiroir/tiroir.js');
const charger = async (v) => import(pathToFileURL(path.join(racine, 'scripts/vf-cockpit-terminal-tiroir.mjs')).href + '?v=' + v);
const avant = (await charger('a')).injectionTiroir();
fs.writeFileSync(f, fs.readFileSync(f, 'utf8').replace('const T = cfg.textes', 'const MUTE_P = 1; const T = cfg.textes'));
const apres = (await charger('b')).injectionTiroir();
console.log(`${avant !== apres} ${apres.includes('const MUTE_P = 1;')}`);
fs.rmSync(f);
const vide = (await charger('c')).injectionTiroir();
console.log(`vide=${JSON.stringify(vide)}`);
FIN
mini_module "$WORK/p3"; node "$WORK/p3.mjs" "$WORK/p3" > "$WORK/p3.out" 2> "$WORK/p3.err"
assert_eq "V11.P3a — tiroir.js muté dans une copie : l'injection change et porte la mutation" "$(sed -n 1p "$WORK/p3.out")" "true true"
assert_eq "V11.P3b — tiroir.js illisible dans une copie : l'injection rend la chaîne vide, le serveur ne plante pas" "$(sed -n 2p "$WORK/p3.out")" 'vide=""'
assert_eq "V11.P3c — une ligne d'erreur nomme le fichier illisible" "$(grep -c 'tiroir/tiroir.js' "$WORK/p3.err")" "1"
# p4 : la liste close a douze entrées ; chacune a son AJOUT, son fichier et une lecture réussie ; un nom de P hors liste est refusé
cat > "$WORK/p4.mjs" <<'FIN'
import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [nav, moteur] = process.argv.slice(2); const m = await import(pathToFileURL(nav).href);
let lus = 0; for (const [d, n] of m.FICHIERS_NAVIGATEUR) { try { (n.endsWith('.css') ? m.lireFeuille : m.lireFonction)(d, n, { moteur }); lus++; } catch (e) { console.log(`echec ${d}/${n} : ${e.message}`); } }
console.log(`entrees=${m.FICHIERS_NAVIGATEUR.length} lus=${lus}`);
try { m.lireFonction('tiroir', 'autre.js', { moteur }); console.log('hors-liste=lu'); } catch { console.log('hors-liste=refus'); }
try { m.lireFonction('tiroir', 'tiroir.css', { moteur }); console.log('css-en-fonction=lu'); } catch { console.log('css-en-fonction=refus'); }
FIN
node "$WORK/p4.mjs" "$NAV" "$MOTEUR" > "$WORK/p4.out" 2>&1
assert_eq "V11.P4a — douze entrées dans FICHIERS_NAVIGATEUR, douze lectures réussies" "$(grep '^entrees=' "$WORK/p4.out")" "entrees=12 lus=12"
assert_eq "V11.P4b — un nom de P hors liste est refusé" "$(grep -c '^hors-liste=refus$' "$WORK/p4.out")" "1"
assert_eq "V11.P4c — une feuille lue comme une fonction est refusée (elle ne commence pas à « function »)" "$(grep -c '^css-en-fonction=refus$' "$WORK/p4.out")" "1"
n_ajout=$(grep -c -E '^AJOUT assets/ui/(terminal|tiroir)/' "$MOTEUR/VENDORED.txt")
assert_eq "V11.P4d — douze lignes AJOUT pour les deux dossiers rangés" "$n_ajout" "12"
# p5 : la liste du code évalué et l'empreinte couvrent les douze
cat > "$WORK/p5.mjs" <<'FIN'
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [racine] = process.argv.slice(2), scripts = path.join(racine, 'scripts'), moteur = path.join(racine, 'skills/cockpit-moteur');
const m = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-module.mjs')).href);
const cles = m.fichiersCodeEvalue(scripts, moteur).map((x) => x[0]).filter((c) => c.startsWith('assets/ui/'));
const h0 = m.empreinteModule({ dossierScripts: scripts, dossierMoteur: moteur });
const f = path.join(moteur, 'assets/ui/tiroir/tiroir.js'); fs.appendFileSync(f, ' ');
const h1 = m.empreinteModule({ dossierScripts: scripts, dossierMoteur: moteur });
console.log(`douze=${cles.length === 12} octet=${typeof h0 === 'string' && h1 !== h0}`);
FIN
mini_module "$WORK/p5"; node "$WORK/p5.mjs" "$WORK/p5" > "$WORK/p5.out" 2>&1
assert_eq "V11.P5 — fichiersCodeEvalue liste les douze fichiers rangés ; un octet changé dans tiroir.js d'une copie change l'empreinte" "$(sed -n 1p "$WORK/p5.out")" "douze=true octet=true"
# V11.P6 : plus aucune conversion de fonction en chaîne dans les trois modules qui servent du code ; le lecteur et les injecteurs sans évaluation dynamique
q6=0; for f in "$SCRIPTS/vf-cockpit-terminal-page.mjs" "$SCRIPTS/vf-cockpit-terminal-tiroir.mjs" "$SCRIPTS/vf-cockpit-lancer-ui.mjs" "$NAV"; do [ -f "$f" ] || { q6=-99; break; }; q6=$((q6 + $(grep -c -E "$MOTIF_EVAL" "$f"))); done
assert_eq "V11.P6 — la page de Q, le tiroir, le lancement et le lecteur : aucune conversion de fonction en chaîne, aucune évaluation dynamique" "$q6" "0"

echo "=== V8 — binaires ==="
assert_eq "V8.1 — cinq .woff2 non vides (quatre polices du cockpit, JetBrains Mono 2.304 Regular)" "$(find "$MOTEUR" -name '*.woff2' -size +0 | grep -c .)" "5"
assert_eq "V8.2 — deux .png non vides" "$(find "$MOTEUR" -name '*.png' -size +0 | grep -c .)" "2"

echo "=== V5 — aucun littéral de la fonction Cloud amont dans le code du module (P67-D-02) ==="
# motif (ERE, insensible à la casse) ::: ligne d'exemple qui doit le déclencher (témoin positif d'abord)
V5=(
  'run\.app ::: https://service.example.run.app/x'
  'waitlist ::: const waitlist = true'
  'auth status ::: claude auth status --json'
  'WAITLIST_URL ::: const WAITLIST_URL = 1'
  'FLOORPLAN_WAITLIST_URL ::: process.env.FLOORPLAN_WAITLIST_URL'
  "['\"/]\.floorplan(['\"/]|\$) ::: path.join(h, '.floorplan', 's')"
  'claudeEmail ::: claudeEmail()'
  'cloud-card ::: #cloud-card { left: 1px; }'
  '50-cloud ::: ui/50-cloud.js'
)
CODE=$(find "$MOTEUR" -type f \( -name '*.mjs' -o -name '*.js' -o -name '*.html' -o -name '*.css' -o -name '*.json' \); find "$SCRIPTS" -maxdepth 1 -type f \( -name '*.mjs' -o -name '*.json' \))
for e in "${V5[@]}"; do
  pat="${e%% ::: *}"; ex="${e#* ::: }"
  printf '%s\n' "$ex" > "$WORK/v5-temoin.txt"
  assert_ge "V5 — témoin positif : « $pat » se déclenche sur sa ligne d'exemple" "$(grep -ciE "$pat" "$WORK/v5-temoin.txt")" 1
  n=0; while IFS= read -r f; do c=$(grep -ciE "$pat" "$f"); n=$((n+c)); done <<< "$CODE"
  assert_eq "V5 — « $pat » : 0 occurrence dans le code du module" "$n" "0"
done

echo "=== V9 — vendor xterm et assistant du terminal (TERM-10, P71-D-16, P71-PL-21) ==="
XT="$MOTEUR/assets/vendor/xterm"
# empreintes épinglées de 71-RESEARCH § Stack standard
PIN_XTERM=14903579ff54664cd72f8e8699e6961a6272c21863ec1c3b118cdc8af5d4a972
PIN_CSS=854a7c0fb70e8b1a083c16797ab827299fb18744f5ad34f227b48337e33293c6
PIN_FIT=ba3ea256ce0620a0992a197d6c9baea64823fc93d8da07a9e366ca9943c18527
sha() { node -e 'try{process.stdout.write(require("crypto").createHash("sha256").update(require("fs").readFileSync(process.argv[1])).digest("hex"))}catch(e){process.stdout.write("absent")}' "$1"; }
pin_of() { case "$1" in xterm.js) printf '%s' "$PIN_XTERM" ;; xterm.css) printf '%s' "$PIN_CSS" ;; addon-fit.js) printf '%s' "$PIN_FIT" ;; esac; }
# témoin M-SHA : un octet changé dans une copie jetable est vu par la même mesure
if [ -f "$XT/xterm.js" ]; then
  mkdir -p "$WORK/xt-mut"; cp "$XT/xterm.js" "$WORK/xt-mut/xterm.js"
  node -e 'const f=require("fs"),p=process.argv[1],b=f.readFileSync(p);b[10]=b[10]^1;f.writeFileSync(p,b)' "$WORK/xt-mut/xterm.js"
  assert_eq "V9 — M-SHA : un octet changé dans xterm.js est vu" "$([ "$(sha "$WORK/xt-mut/xterm.js")" != "$PIN_XTERM" ] && echo vu || echo aveugle)" "vu"
else echo "  ⏭  SKIP — V9 M-SHA (vendor xterm pas encore posé)"; fi
for n in xterm.js xterm.css addon-fit.js; do
  assert_eq "V9.1 — sha256 de $n = valeur épinglée" "$(sha "$XT/$n")" "$(pin_of "$n")"
done
for n in xterm.js xterm.css addon-fit.js; do
  got=$(awk -v n="$n" '$2==n{print $1}' "$XT/SHA256SUMS" 2>/dev/null)
  assert_eq "V9.2 — SHA256SUMS : ligne de $n = valeur épinglée" "${got:-absente}" "$(pin_of "$n")"
done
assert_eq "V9.3 — une ligne AJOUT terminal/vf-cockpit-pty.py" "$(grep -cx 'AJOUT terminal/vf-cockpit-pty.py' "$MOTEUR/VENDORED.txt")" "1"
assert_eq "V9.3 — l'assistant existe sous le moteur" "$([ -s "$MOTEUR/terminal/vf-cockpit-pty.py" ] && echo oui || echo non)" "oui"

echo "--- V9.5 — police des traits de boîte (J3 de la critique 71) ---"
FT="$MOTEUR/assets/vendor/fonts"
PIN_BOITE=a9cb1cd82332b23a47e3a1239d25d13c86d16c4220695e34b243effa999f45f2   # release v2.304 de JetBrains/JetBrainsMono, fonts/webfonts/JetBrainsMono-Regular.woff2
PIN_OFL=30f0c136e3c88e422d0791acd97238870f9054a9729bc34cf2ff0d4ed8cac4ad     # OFL.txt de la même release
assert_eq "V9.5 — sha256 de jetbrains-mono-2.304-regular.woff2 = valeur épinglée (octets de la release officielle)" "$(sha "$FT/jetbrains-mono-2.304-regular.woff2")" "$PIN_BOITE"
assert_eq "V9.5 — sha256 de la licence jetbrains-mono-2.304-OFL.txt = valeur épinglée" "$(sha "$FT/jetbrains-mono-2.304-OFL.txt")" "$PIN_OFL"
assert_eq "V9.5 — SHA256SUMS des polices : ligne de la police = valeur épinglée" "$(awk '$2=="jetbrains-mono-2.304-regular.woff2"{print $1}' "$FT/SHA256SUMS" 2>/dev/null)" "$PIN_BOITE"
assert_eq "V9.5 — SHA256SUMS des polices : ligne de la licence = valeur épinglée" "$(awk '$2=="jetbrains-mono-2.304-OFL.txt"{print $1}' "$FT/SHA256SUMS" 2>/dev/null)" "$PIN_OFL"
assert_eq "V9.5 — la licence nomme son projet et sa licence (SIL Open Font License, JetBrains Mono Project)" "$(grep -c -E 'SIL OPEN FONT LICENSE|JetBrains Mono Project' "$FT/jetbrains-mono-2.304-OFL.txt" | awk '$1>=2{print "oui"}')" "oui"
for f in jetbrains-mono-2.304-regular.woff2 jetbrains-mono-2.304-OFL.txt; do
  assert_eq "V9.5 — une ligne AJOUT pour $f" "$(grep -cx "AJOUT assets/vendor/fonts/$f" "$MOTEUR/VENDORED.txt")" "1"
done
assert_eq "V9.5 — la ligne AJOUT de SHA256SUMS des polices existe" "$(grep -cx 'AJOUT assets/vendor/fonts/SHA256SUMS' "$MOTEUR/VENDORED.txt")" "1"
assert_eq "V9.5 — LICENCES-TIERCES.txt nomme JetBrains Mono 2.304 et sa licence" "$(grep -c 'JetBrains Mono 2.304.*jetbrains-mono-2.304-OFL.txt' "$MOTEUR/LICENCES-TIERCES.txt")" "1"
# témoin : un octet changé dans une copie jetable de la police est vu
cp "$FT/jetbrains-mono-2.304-regular.woff2" "$WORK/boite-mut.woff2"
node -e 'const f=require("fs"),p=process.argv[1],b=f.readFileSync(p);b[10]=b[10]^1;f.writeFileSync(p,b)' "$WORK/boite-mut.woff2"
assert_eq "V9.5 — M-SHA : un octet changé dans la police des traits de boîte est vu" "$([ "$(sha "$WORK/boite-mut.woff2")" != "$PIN_BOITE" ] && echo vu || echo aveugle)" "vu"

echo "=== V10 — fork assumé : aucun appareil de patchs (AUDC-H5, P79-D-07) ==="
# amont_present <racine du module> : « present » si un dossier amont y existe
amont_present() { [ -d "$1/amont" ] && echo present || echo absent; }
# lignes_hors_grammaire <VENDORED.txt> : nombre de lignes dont le premier mot est en capitales seules (verbe machine) et qui ne sont ni
#   AJOUT à deux champs, ni TAILLE dont le troisième champ (s'il existe) ne commence pas par un chiffre
lignes_hors_grammaire() { LC_ALL=C awk '$1 ~ /^[A-Z]+$/ { if ($1=="AJOUT" && NF==2) next; if ($1=="TAILLE" && (NF<3 || $3 !~ /^[0-9]/)) next; n++ } END { print n+0 }' "$1"; }
# lignes_ajout_en_desordre <VENDORED.txt> : nombre de lignes AJOUT dont le chemin n'est pas strictement supérieur à celui de la ligne AJOUT précédente (octet par octet)
lignes_ajout_en_desordre() { LC_ALL=C awk '$1=="AJOUT" { if (vu && !($2 > prev)) n++; prev=$2; vu=1 } END { print n+0 }' "$1"; }
assert_eq "V10.1 — le module n'a pas de dossier amont" "$(amont_present "$SCRIPTS/..")" "absent"
assert_eq "V10.2 — VENDORED.txt : zéro ligne machine hors grammaire (AJOUT à deux champs, TAILLE sans nombre)" "$(lignes_hors_grammaire "$MOTEUR/VENDORED.txt")" "0"
# témoins V10.3 : la mesure sait voir un amont recréé et chaque classe d'écart
mkdir -p "$WORK/m10/avec/amont" "$WORK/m10/sans"
assert_eq "V10.3a — témoin : un dossier amont recréé est vu present" "$(amont_present "$WORK/m10/avec")" "present"
assert_eq "V10.3a' — témoin négatif : sans dossier amont, absent" "$(amont_present "$WORK/m10/sans")" "absent"
conforme10() { printf '%s\n' 'floorplan v0.6.0 @ 92d6854 (origine)' 'Licence : MIT.' '' 'AJOUT assets/a.js' 'AJOUT assets/b.js' 'TAILLE assets/serve.mjs' 'TAILLE assets/viewer.html .html, hors gate'; }
conforme10 > "$WORK/m10/ok.txt"
{ conforme10; echo 'PATCH assets/viewer.html P1 une description'; } > "$WORK/m10/patch.txt"
{ conforme10; echo 'RETRAIT SKILL.md'; } > "$WORK/m10/retrait.txt"
{ conforme10; echo 'TAILLE assets/scan.mjs 320'; } > "$WORK/m10/taille.txt"
assert_eq "V10.3b — témoin : une ligne PATCH ajoutée compte 1" "$(lignes_hors_grammaire "$WORK/m10/patch.txt")" "1"
assert_eq "V10.3c — témoin : une ligne RETRAIT ajoutée compte 1" "$(lignes_hors_grammaire "$WORK/m10/retrait.txt")" "1"
assert_eq "V10.3d — témoin : une ligne TAILLE chiffrée ajoutée compte 1" "$(lignes_hors_grammaire "$WORK/m10/taille.txt")" "1"
assert_eq "V10.3e — témoin positif : un fichier conforme minimal compte 0" "$(lignes_hors_grammaire "$WORK/m10/ok.txt")" "0"
# V10.5 : forme et ordre des lignes AJOUT (chaque phase insère la sienne à sa place alphabétique : fusion sans conflit)
assert_eq "V10.5 — lignes AJOUT de VENDORED.txt : sans doublon et rangées par chemin croissant (insérer à sa place, jamais en fin de fichier)" "$(lignes_ajout_en_desordre "$MOTEUR/VENDORED.txt")" "0"
{ echo 'AJOUT assets/b.js'; echo 'AJOUT assets/c.js'; echo 'AJOUT assets/a.js'; } > "$WORK/m10/desordre.txt"
{ echo 'AJOUT assets/a.js'; echo 'AJOUT assets/b.js'; echo 'AJOUT assets/b.js'; } > "$WORK/m10/doublon.txt"
{ echo 'AJOUT assets/a.js'; echo 'AJOUT assets/b.js'; echo 'AJOUT assets/c.js'; } > "$WORK/m10/trie.txt"
assert_eq "V10.5a — témoin : une ligne AJOUT déplacée en fin de fichier compte 1 désordre" "$(lignes_ajout_en_desordre "$WORK/m10/desordre.txt")" "1"
assert_eq "V10.5b — témoin : un doublon compte 1" "$(lignes_ajout_en_desordre "$WORK/m10/doublon.txt")" "1"
assert_eq "V10.5c — témoin positif : une copie triée compte 0" "$(lignes_ajout_en_desordre "$WORK/m10/trie.txt")" "0"
# V10.4 : VENDORED.txt reste la sentinelle du moteur (engineDir)
etat_moteur() { node --input-type=module -e "import { pathToFileURL } from 'node:url'; import path from 'node:path'; const m = await import(pathToFileURL(path.join(process.argv[1], 'vf-cockpit-paths.mjs')).href); console.log(m.engineDir(process.argv[2]).etat);" "$SCRIPTS" "$1" 2>&1; }
assert_eq "V10.4a — engineDir du vrai module rend trouve avec VENDORED.txt réduit" "$(etat_moteur "$SCRIPTS")" "trouve"
mkdir -p "$WORK/m104/scripts" "$WORK/m104/skills/cockpit-moteur/assets"; echo '<html></html>' > "$WORK/m104/skills/cockpit-moteur/assets/viewer.html"
assert_eq "V10.4b — arbre jetable sans VENDORED.txt : engineDir rend absent" "$(etat_moteur "$WORK/m104/scripts")" "absent"
echo 'floorplan v0.6.0 @ 92d6854' > "$WORK/m104/skills/cockpit-moteur/VENDORED.txt"
assert_eq "V10.4c — le même arbre avec VENDORED.txt : engineDir rend trouve" "$(etat_moteur "$WORK/m104/scripts")" "trouve"

echo ""
echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then
  echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"
  exit 1
fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
