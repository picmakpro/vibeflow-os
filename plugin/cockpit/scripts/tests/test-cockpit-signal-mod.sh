#!/usr/bin/env bash
# test-cockpit-signal-mod.sh — suite statique du mod vf-signal embarqué (68-04, VFSG-01 ; P68-D-01, D-11, D-12, D-13).
#   M0 contrôles positifs de la suite (extracteur, compteur de lignes : chacun sait rougir)
#   M1 déclaration du mod : aucun plugin/cockpit/hooks/hooks.json, le manifeste pointe un fichier qui ne porte que
#      `modules`, tout plugin/*/hooks/hooks.json porte une clé `hooks` (sinon l'engine meurt à l'install du module)
#   M2 clés d'état : au moins une déclaration d'atome, aucune ne nomme un autre plugin que `vibeflow`, PluginState idem
#   M3 check-machine-paths.sh vert · M4 aucun typing généré suivi par git · M5 chaque fichier du mod ≤ 300 lignes
# Sans `claude`, sans node autre qu'un get.mjs de lecture JSON. Exit 0 si tout passe, 1 sinon, 1 si aucun cas exécuté.
# (M6, détection de l'ancien mod hors dépôt : 68-12.)
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
TESTS="$(cd "$(dirname "$0")" && pwd)"
PLUGIN="$(cd "$TESTS/../../.." && pwd)"
REPO="$(cd "$PLUGIN/.." && pwd)"
SIGNAL="$PLUGIN/cockpit/signal"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
ok() { echo "  ✅ PASS — $1"; PASS=$((PASS+1)); }
ko() { echo "  ❌ FAIL — $1"; FAIL=$((FAIL+1)); }
assert_eq() { if [ "$2" = "$3" ]; then ok "$1"; else ko "$1 (attendu [$3], obtenu [$2])"; fi; }

# get.mjs : lecture JSON seule. `get.mjs <fichier> <clé>` → valeur (chaîne), `keys` → clés triées, `absent` si manque.
cat > "$WORK/get.mjs" <<'JS'
import fs from 'node:fs';
let j; try { j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')); } catch { console.log('illisible'); process.exit(0); }
const k = process.argv[3];
if (k === 'keys') console.log(Object.keys(j).sort().join(','));
else if (k in j) console.log(typeof j[k] === 'string' ? j[k] : JSON.stringify(j[k])); else console.log('absent');
JS
getj() { node "$WORK/get.mjs" "$@"; }

# déclarations d'atome : un nom de plugin par ligne, lignes de commentaire ignorées
declarations() { grep -rhE "plugin: *['\"][^'\"]+['\"]" "$@" 2>/dev/null | grep -vE '^[[:space:]]*(//|\*|/\*)' | grep -oE "plugin: *['\"][^'\"]+['\"]" | sed -E "s/plugin: *['\"]([^'\"]+)['\"]/\1/"; }
longueurs_ko() { for f in "$@"; do [ "$(awk 'END{print NR}' "$f")" -le 300 ] || echo "$f"; done; }
fichiers_mod() { [ -d "$SIGNAL" ] && find "$SIGNAL" -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.json' -o -name '*.sh' \) | LC_ALL=C sort; }

echo "=== M0 — contrôles positifs de la suite ==="
printf "const a = atom({ plugin: 'vibeflow', key: 'a' } as const, 0)\n// atom({ plugin: 'autre', key: 'c' })\nconst b = atom({ plugin: 'autre', key: 'b' } as const, 0)\n" > "$WORK/fx.ts"
assert_eq "M0.1 — l'extracteur trouve les deux déclarations et ignore le commentaire" "$(declarations "$WORK/fx.ts" | tr '\n' ',')" "vibeflow,autre,"
seq 1 301 > "$WORK/long.txt"; seq 1 300 > "$WORK/court.txt"
assert_eq "M0.2 — le compteur signale 301 lignes et laisse passer 300" "$(longueurs_ko "$WORK/long.txt" "$WORK/court.txt" | sed "s#$WORK/##")" "long.txt"
printf '{"hooks":{}}\n' > "$WORK/h1.json"; printf '{"modules":["./r.tsx"]}\n' > "$WORK/h2.json"
assert_eq "M0.3 — get.mjs distingue un fragment à hooks d'un fragment à modules" "$(getj "$WORK/h1.json" keys)|$(getj "$WORK/h2.json" keys)" "hooks|modules"

echo "=== M1 — déclaration du mod, install du module ==="
assert_eq "M1.1 — aucun plugin/cockpit/hooks/hooks.json (l'engine le fusionnerait comme un fragment)" "$([ -e "$PLUGIN/cockpit/hooks/hooks.json" ] && echo present || echo absent)" "absent"
MH="$(getj "$PLUGIN/.claude-plugin/plugin.json" hooks)"
assert_eq "M1.2 — le manifeste déclare hooks → ./cockpit/signal/hooks/hooks.json" "$MH" "./cockpit/signal/hooks/hooks.json"
if [ "$MH" != absent ] && [ -f "$PLUGIN/${MH#./}" ]; then F="$PLUGIN/${MH#./}"; else F=""; fi
assert_eq "M1.3 — le fichier déclaré existe" "$([ -n "$F" ] && echo oui || echo non)" "oui"
assert_eq "M1.4 — il ne porte que la clé modules" "$([ -n "$F" ] && getj "$F" keys || echo aucun)" "modules"
assert_eq "M1.5 — le manifeste déclare types → ./cockpit/signal/types/index.d.ts" "$(getj "$PLUGIN/.claude-plugin/plugin.json" types)" "./cockpit/signal/types/index.d.ts"
bad=""; n=0
for h in "$PLUGIN"/*/hooks/hooks.json; do [ -f "$h" ] || continue; n=$((n+1)); [ "$(getj "$h" keys | tr ',' '\n' | grep -cx hooks)" = 1 ] || bad="$bad ${h#$PLUGIN/}"; done
assert_eq "M1.6 — tout plugin/*/hooks/hooks.json ($n) porte une clé hooks" "${bad:-aucun}" "aucun"
[ "$n" -ge 1 ] && ok "M1.7 — le balayage a vu au moins un fragment ($n)" || ko "M1.7 — aucun plugin/*/hooks/hooks.json vu : le balayage serait vide"

echo "=== M2 — clés d'état rattachées au plugin vibeflow ==="
if [ -d "$SIGNAL/hooks" ]; then DECL="$(declarations "$SIGNAL"/hooks/*.ts "$SIGNAL"/hooks/*.tsx "$SIGNAL"/hooks/views/*.tsx)"; else DECL=""; fi
NDECL=$(printf '%s' "$DECL" | grep -c .)
[ "$NDECL" -ge 1 ] && ok "M2.1 — $NDECL déclaration(s) d'atome trouvée(s)" || ko "M2.1 — aucune déclaration d'atome trouvée (un vert à vide serait un faux vert)"
assert_eq "M2.2 — aucune déclaration ne nomme un autre plugin que vibeflow" "$(printf '%s\n' "$DECL" | grep -v '^vibeflow$' | grep -c .)" "0"
if [ -f "$SIGNAL/types/index.d.ts" ]; then T="$SIGNAL/types/index.d.ts"; assert_eq "M2.3 — PluginState est rangé sous vibeflow, pas sous un autre nom" "$(grep -cE "^    ['\"]?vibeflow['\"]?: \{" "$T")|$(grep -cE "^    ['\"]?vf-signal['\"]?: \{" "$T")" "1|0"
else ko "M2.3 — types/index.d.ts absent"; fi

echo "=== M3 — chemins de machine ==="
bash "$REPO/scripts/check-machine-paths.sh" > "$WORK/cmp.out" 2>&1; assert_eq "M3 — check-machine-paths.sh sort 0" "$?" "0"

echo "=== M4 — aucun typing généré suivi ==="
assert_eq "M4 — git ls-files plugin/.claude-plugin/types plugin/cockpit/signal/.claude-plugin ne rend rien" "$(git -C "$REPO" ls-files plugin/.claude-plugin/types plugin/cockpit/signal/.claude-plugin | grep -c .)" "0"
if [ -d "$SIGNAL" ]; then ok "M4.1 — le mod existe (le contrôle ci-dessus porte sur quelque chose)"; else ko "M4.1 — plugin/cockpit/signal/ absent"; fi

echo "=== M5 — taille des fichiers du mod ==="
FM="$(fichiers_mod)"; NF=$(printf '%s' "$FM" | grep -c .)
if [ "$NF" -ge 1 ]; then
  ko_l="$(printf '%s\n' "$FM" | while IFS= read -r f; do longueurs_ko "$f"; done)"
  assert_eq "M5 — aucun des $NF fichiers du mod ne dépasse 300 lignes" "${ko_l:-aucun}" "aucun"
else ko "M5 — aucun fichier du mod : plugin/cockpit/signal/ absent ou vide"; fi

echo "=== bilan : $PASS ok, $FAIL ko ==="
[ $((PASS + FAIL)) -gt 0 ] || { echo "ÉCHEC ANTI-VERT-À-VIDE : aucun cas exécuté"; exit 1; }
[ "$FAIL" -eq 0 ]
