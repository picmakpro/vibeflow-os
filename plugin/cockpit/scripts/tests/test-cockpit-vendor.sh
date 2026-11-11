#!/usr/bin/env bash
# test-cockpit-vendor.sh — copie vendorisée de floorplan (CKPT-02, CKPT-03 volet code ; P67-D-03, D-07, D-11 ; P79-D-07).
#   V1 sentinelles et licence · V2 licences tierces · V3 rien que check-skills ou la CI jugeraient
#   V4 tailles et marqueurs · V8 binaires · V10 fork assumé : ni dossier amont ni journal de patchs, sentinelle du moteur lue (79-01)
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
