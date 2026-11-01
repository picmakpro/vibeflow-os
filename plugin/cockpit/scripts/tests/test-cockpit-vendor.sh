#!/usr/bin/env bash
# test-cockpit-vendor.sh — copie vendorisée de floorplan (CKPT-02, CKPT-03 volet code ; P67-D-03, D-07, D-11).
#   V1 sentinelles et licence · V2 licences tierces · V3 rien que check-skills ou la CI jugeraient
#   V4 tailles et marqueurs · V6 amont retrouvé à l'octet · V7 ajouts, patchs, retraits · V8 binaires
# Les contrôles de patchs (V6, V7) sont sautés audiblement quand amont/ est absent (lab installé).
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
MOTEUR="$SCRIPTS/../skills/cockpit-moteur"
AMONT="$SCRIPTS/../amont"
CHKSIZE="$SCRIPTS/../../software-architecture/scripts/check-file-size.sh"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_ge() { if [ "$2" -ge "$3" ] 2>/dev/null; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 ($2 < $3)"; FAIL=$((FAIL+1)); fi; }
skip() { echo "  ⏭  SKIP — $1 (amont/ absent : lab installé)"; }
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
assert_eq "V2 — quatre composants listés" "$n" "4"

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
for f in "$SCRIPTS"/*.mjs; do [ "$(nlines "$f")" -lt 300 ] || { big=$((big+1)); echo "     trop long : $f"; }; done
while read -r k f; do [ "$k" = AJOUT ] || continue; case "$f" in *.js|*.mjs) [ "$(nlines "$MOTEUR/$f")" -lt 300 ] || { big=$((big+1)); echo "     trop long : $f"; } ;; esac; done < "$MOTEUR/VENDORED.txt"
assert_eq "V4 — notre code sous 300 lignes (scripts du module, ajouts de code)" "$big" "0"
if [ -f "$CHKSIZE" ]; then
  FILES=$(find "$SCRIPTS" "$MOTEUR" \( -name '*.mjs' -o -name '*.js' \) -type f)
  # shellcheck disable=SC2086
  bash "$CHKSIZE" $FILES >/dev/null 2>&1; assert_eq "V4 — check-file-size.sh sur tout le code du module" "$?" "0"
  cp "$MOTEUR/assets/serve.mjs" "$WORK/serve-sans-marqueur.mjs"
  grep -v 'vibeflow:allow-large-file' "$MOTEUR/assets/serve.mjs" > "$WORK/serve-sans-marqueur.mjs"
  bash "$CHKSIZE" "$WORK/serve-sans-marqueur.mjs" >/dev/null 2>&1; assert_eq "V4 — témoin : serve.mjs sans marqueur est bloqué (exit 2)" "$?" "2"
fi

echo "=== V6 — amont retrouvé à l'octet ==="
if [ -f "$AMONT/synchro.sh" ]; then
  bash "$AMONT/synchro.sh" verifier "$MOTEUR" >/dev/null 2>&1; assert_eq "V6.1 — synchro.sh verifier rend 0" "$?" "0"
  cp -R "$MOTEUR" "$WORK/alt"
  printf '\n' >> "$WORK/alt/references/schema.md"
  bash "$AMONT/synchro.sh" verifier "$WORK/alt" >/dev/null 2>&1; assert_eq "V6.2 — témoin : un octet amont modifié hors patch rend 1" "$?" "1"
else skip "V6"; fi

echo "=== V7 — ajouts, patchs, retraits ==="
if [ -d "$AMONT/patches" ]; then
  while read -r k f rest; do
    case "$k" in
      AJOUT) assert_eq "V7 — ajout présent : $f" "$([ -e "$MOTEUR/$f" ] && echo oui || echo non)" "oui" ;;
      PATCH) assert_eq "V7 — diff présent pour $f" "$([ -s "$AMONT/patches/$(printf '%s' "$f" | sed 's|/|__|g').diff" ] && echo oui || echo non)" "oui" ;;
      RETRAIT) assert_eq "V7 — retrait effectif : $f" "$([ -e "$MOTEUR/$f" ] && echo present || echo absent)" "absent" ;;
    esac
  done < "$MOTEUR/VENDORED.txt"
else skip "V7"; fi

echo "=== V8 — binaires ==="
assert_eq "V8.1 — quatre .woff2 non vides" "$(find "$MOTEUR" -name '*.woff2' -size +0 | grep -c .)" "4"
assert_eq "V8.2 — deux .png non vides" "$(find "$MOTEUR" -name '*.png' -size +0 | grep -c .)" "2"

#--V5--

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
