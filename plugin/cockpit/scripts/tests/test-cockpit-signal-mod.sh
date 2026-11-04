#!/usr/bin/env bash
# test-cockpit-signal-mod.sh — suite statique du mod vf-signal embarqué (68-04, VFSG-01 ; P68-D-01, D-11, D-12, D-13).
#   M0 contrôles positifs de la suite (extracteur, compteur de lignes : chacun sait rougir)
#   M1 déclaration du mod : aucun plugin/cockpit/hooks/hooks.json, le manifeste pointe un fichier qui ne porte que
#      `modules`, tout plugin/*/hooks/hooks.json porte une clé `hooks` (sinon l'engine meurt à l'install du module)
#   M2 clés d'état : au moins une déclaration d'atome, aucune ne nomme un autre plugin que `vibeflow`, PluginState idem
#   M3 check-machine-paths.sh vert · M4 aucun typing généré suivi par git · M5 chaque fichier du mod ≤ 300 lignes
# Sans `claude`, sans node autre qu'un get.mjs de lecture JSON. Exit 0 si tout passe, 1 sinon, 1 si aucun cas exécuté.
#   M6 détection de l'ancien mod hors dépôt (68-12, VFSG-09 ; P68-D-08) : le chemin `.claude/mods/vf-signal` figure dans un fichier du mod
#   M7 la lecture maison du planning est retirée (68-06, VFSG-03 ; P68-D-17) : `disk.ts` absent, aucun littéral `.planning` ni
#      `current_phase` hors commentaire dans plugin/cockpit/signal/hooks/, `agent.list` seulement dans refresh.ts
#   M8 les gestes et le lanceur ne partent que d'un appui humain (68-07, VFSG-04, VFSG-10 ; ADR-031) : `ouvrirCockpit` n'est appelé que
#      dans boutons.tsx et seulement par la fonction que `onPress` désigne ; `$.session.send` et `$.ui.view` seulement dans views/equipe.tsx
#   M9 aucune valeur de couleur hors de tokens.ts (68-08, VFSG-07 ; P68-D-06) : aucun motif hexadécimal dans plugin/cockpit/signal/hooks/
#      hors de hooks/tokens.ts, commentaires compris
#   M10 tokens.ts égal à DESIGN.md (68-08, VFSG-07 ; P68-D-06) : chaque valeur, sombre et clair, est celle de la ligne de DESIGN.md de
#      son token ; les quatre statuts renvoient bien aux variables que le tableau « Statuts de travail » leur donne
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

echo "=== M6 — détection de l'ancien mod (VFSG-09) ==="
printf "const x = '.claude/mods/vf-signal'\n" > "$WORK/m6.ts"; : > "$WORK/m6vide.ts"
assert_eq "M6.0 — le compteur voit le chemin dans un fichier qui le porte, pas dans un vide" "$(grep -l '\.claude/mods/vf-signal' "$WORK/m6.ts" "$WORK/m6vide.ts" | sed "s#$WORK/##")" "m6.ts"
NM6=$([ -d "$SIGNAL/hooks" ] && grep -l '\.claude/mods/vf-signal' "$SIGNAL"/hooks/*.ts "$SIGNAL"/hooks/*.tsx 2>/dev/null | grep -c .)
[ "${NM6:-0}" -ge 1 ] && ok "M6 — le chemin de l'ancien mod figure dans ${NM6} fichier(s) du mod" || ko "M6 — aucun fichier du mod ne porte .claude/mods/vf-signal (attendu au moins 1, obtenu 0)"

echo "=== M7 — la lecture maison du planning est retirée (VFSG-03) ==="
# fichiers (un chemin par ligne sur l'entrée) dont une ligne de code, commentaires de ligne et de bloc exclus, porte le motif ERE $1
code_avec() {
  local re="$1" f
  while IFS= read -r f; do [ -n "$f" ] || continue; grep -vE '^[[:space:]]*(//|\*|/\*)' "$f" | grep -qE "$re" && echo "${f##*/}"; done
}
printf "// lit .planning/STATE.md\nconst a = '.planning/x'\n * current_phase\nconst b = 'current_phase'\nconst c = $.agent.list()\n" > "$WORK/m7.ts"
printf "// .planning current_phase agent.list\n * .planning\n" > "$WORK/m7com.ts"; : > "$WORK/m7vide.ts"
M7FX="$(printf '%s\n' "$WORK/m7.ts" "$WORK/m7com.ts" "$WORK/m7vide.ts")"
assert_eq "M7.0 — l'extracteur voit le littéral en code, ni en commentaire, ni dans un fichier vide" "$(printf '%s\n' "$M7FX" | code_avec '\.planning' | tr '\n' ',')|$(printf '%s\n' "$M7FX" | code_avec 'current_phase' | tr '\n' ',')|$(printf '%s\n' "$M7FX" | code_avec 'agent\.list' | tr '\n' ',')" "m7.ts,|m7.ts,|m7.ts,"
HOOKS_FILES="$(find "$SIGNAL/hooks" -type f \( -name '*.ts' -o -name '*.tsx' \) 2>/dev/null | LC_ALL=C sort)"
NH=$(printf '%s\n' "$HOOKS_FILES" | grep -c .)
[ "$NH" -ge 5 ] && ok "M7.1 — le balayage voit $NH fichiers de hooks (pas de vert à vide)" || ko "M7.1 — moins de 5 fichiers de hooks vus ($NH) : le balayage serait vide"
assert_eq "M7.2 — hooks/disk.ts est supprimé" "$([ -e "$SIGNAL/hooks/disk.ts" ] && echo present || echo absent)" "absent"
assert_eq "M7.3 — aucun littéral .planning hors commentaire dans les hooks" "$(printf '%s\n' "$HOOKS_FILES" | code_avec '\.planning' | tr '\n' ',')" ""
assert_eq "M7.4 — aucun current_phase hors commentaire dans les hooks" "$(printf '%s\n' "$HOOKS_FILES" | code_avec 'current_phase' | tr '\n' ',')" ""
assert_eq "M7.5 — agent.list n'apparaît que dans refresh.ts" "$(printf '%s\n' "$HOOKS_FILES" | code_avec 'agent\.list' | tr '\n' ',')" "refresh.ts,"

echo "=== M8 — les gestes et le lanceur ne partent que d'un appui humain (VFSG-04, VFSG-10) ==="
printf "const a = ouvrirCockpit($, l, r)\n// ouvrirCockpit($, l, r)\nonPress={ouvrir}\nvoid ouvrir()\n" > "$WORK/m8.ts"; printf "// ouvrirCockpit(\n * ouvrir()\n" > "$WORK/m8com.ts"
M8FX="$(printf '%s\n' "$WORK/m8.ts" "$WORK/m8com.ts" "$WORK/m7vide.ts")"
# occurrences de code (hors commentaires) du motif ERE $1 dans le fichier $2
occ() { grep -vE '^[[:space:]]*(//|\*|/\*)' "$2" | grep -cE "$1"; }
assert_eq "M8.0 — le compteur voit l'appel en code (1), ni le commentaire, ni le fichier de commentaires, ni le vide" "$(occ 'ouvrirCockpit\(' "$WORK/m8.ts")|$(occ 'ouvrirCockpit\(' "$WORK/m8com.ts")|$(occ 'ouvrirCockpit\(' "$WORK/m7vide.ts")" "1|0|0"
assert_eq "M8.0b — une utilisation de la fonction hors de onPress={ouvrir} est vue (1 sur 2 usages)" "$(grep -vE '^[[:space:]]*(//|\*|/\*)' "$WORK/m8.ts" | grep -E '\bouvrir\b' | grep -vcE 'onPress=\{ouvrir\}')" "1"
APPELANTS="$(printf '%s\n' "$HOOKS_FILES" | code_avec 'ouvrirCockpit\(' | tr '\n' ',')"
assert_eq "M8.1 — ouvrirCockpit( n'est appelé (ou défini) que dans actions.ts et boutons.tsx" "$APPELANTS" "actions.ts,boutons.tsx,"
assert_eq "M8.2 — dans boutons.tsx, un seul appel de ouvrirCockpit" "$(occ 'ouvrirCockpit\(' "$SIGNAL/hooks/boutons.tsx")" "1"
assert_eq "M8.3 — la fonction qui l'appelle (ouvrir) n'est référencée que par onPress={ouvrir} (hors sa définition)" "$(grep -vE '^[[:space:]]*(//|\*|/\*)' "$SIGNAL/hooks/boutons.tsx" | grep -E '\bouvrir\b' | grep -vE 'const ouvrir = |onPress=\{ouvrir\}' | grep -c .)" "0"
assert_eq "M8.4 — onPress={ouvrir} est bien là (une fois : le garde ne verdit pas à vide)" "$(occ 'onPress=\{ouvrir\}' "$SIGNAL/hooks/boutons.tsx")" "1"
assert_eq "M8.5 — resoudreLanceur n'est appelé que depuis boutons.tsx (et défini dans actions.ts)" "$(printf '%s\n' "$HOOKS_FILES" | code_avec 'resoudreLanceur' | tr '\n' ',')" "actions.ts,boutons.tsx,"
assert_eq "M8.6 — \$.session.send et \$.ui.view n'apparaissent que dans views/equipe.tsx" "$(printf '%s\n' "$HOOKS_FILES" | code_avec '\$\.session\.send|\$\.ui\.view' | tr '\n' ',')" "equipe.tsx,"

echo "=== M9 — aucune valeur de couleur hors de tokens.ts (VFSG-07) ==="
HEXRE='#([0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\b'
# fichiers (un chemin par ligne sur l'entrée) dont une ligne, commentaires compris, porte un motif hexadécimal de couleur
avec_hex() { local f; while IFS= read -r f; do [ -n "$f" ] || continue; grep -qE "$HEXRE" "$f" && echo "${f##*/}"; done; }
printf "const a = '#4ade80'\n" > "$WORK/m9a.ts"; printf "// teinte #abc en commentaire\n" > "$WORK/m9b.ts"; printf "const c = 'rgba(0,0,0,.5)' // PR 196, id #12\n" > "$WORK/m9c.ts"
assert_eq "M9.0 — le motif voit #rrggbb en code et #rgb en commentaire, pas un id court ni un fichier vide" "$(printf '%s\n' "$WORK/m9a.ts" "$WORK/m9b.ts" "$WORK/m9c.ts" "$WORK/m7vide.ts" | avec_hex | tr '\n' ',')" "m9a.ts,m9b.ts,"
NH9=$(printf '%s\n' "$HOOKS_FILES" | grep -vc '/tokens\.ts$')
[ "$NH9" -ge 5 ] && ok "M9.1 — le balayage voit $NH9 fichiers de hooks hors tokens.ts (pas de vert à vide)" || ko "M9.1 — moins de 5 fichiers balayés ($NH9)"
assert_eq "M9 — aucun hex hors de tokens.ts" "$(printf '%s\n' "$HOOKS_FILES" | grep -v '/tokens\.ts$' | avec_hex | tr '\n' ',')" ""

echo "=== M10 — tokens.ts égal à DESIGN.md (VFSG-07) ==="
# token:variable de DESIGN.md dont il recopie les valeurs ; un statut passe par la variable que le tableau « Statuts de travail » lui donne
MAP10="st-done:--recent st-active:--sev-medium st-todo:--text-4 st-blocked:--sev-high text:--text text-2:--text-2 text-3:--text-3 text-4:--text-4"
# « <thème> <token> <hex> » pour chaque valeur de tokens.ts, hex en minuscules
tokens_lus() { awk '/^  sombre: *\{/ {t="sombre"; next} /^  clair: *\{/ {t="clair"; next}
  t != "" && /^    \x27[a-z0-9-]+\x27: *\x27#[0-9a-fA-F]{6}\x27,?$/ { n = split($0, a, "\x27"); print t, a[2], tolower(a[4]) }' "$1"; }
# la colonne $2 (4 sombre, 5 clair) de la ligne de la variable $3 dans le fichier $1, premier hex trouvé
design_hex() { awk -F'|' -v v="\`$3\`" '$1 ~ /^ *$/ && index($3, v) > 0 { print $'"$2"' }' "$1" | grep -oE '#[0-9a-fA-F]{6}' | head -1 | tr 'A-F' 'a-f'; }
design_statut() { awk -F'|' -v v="\`$2\`" 'index($3, v) > 0 { print $4 }' "$1" | head -1; }
# écarts de $1 (tokens.ts) contre $2 (DESIGN.md) : une ligne par écart, puis « n=<valeurs comparées> »
ecarts_tokens() {
  local n=0 th tok hex var want st
  while read -r th tok hex; do
    var=""; for m in $MAP10; do [ "${m%%:*}" = "$tok" ] && var="${m#*:}"; done
    [ -n "$var" ] || { echo "token inconnu : $tok"; continue; }
    want="$(design_hex "$2" "$([ "$th" = sombre ] && echo 4 || echo 5)" "$var")"
    [ -n "$want" ] || { echo "$tok ($th) : $var absent de DESIGN.md"; continue; }
    n=$((n+1)); [ "$hex" = "$want" ] || echo "$tok ($th) : $hex au lieu de $want"
  done < <(tokens_lus "$1")
  for m in $MAP10; do
    case "${m%%:*}" in st-*) st="$(design_statut "$2" "--${m%%:*}")"
      case "$st" in *"var(${m#*:})"*) : ;; *) echo "${m%%:*} : le tableau des statuts ne dit pas var(${m#*:})" ;; esac ;; esac
  done
  echo "n=$n"
}
cat > "$WORK/d10.md" <<'MD'
| Texte principal | `--text` | `#ECECEC` | `#161616` |
| Récent / fait | `--recent` (texte dessus `--on-recent-text`) | `#4ade80` | `#157a3a` |
| Fait | `--st-done` | `var(--recent)` |
MD
printf "export const TOKENS = {\n  sombre: {\n    'text': '#ececec',\n    'st-done': '#4ade80',\n  },\n  clair: {\n    'text': '#161616',\n    'st-done': '#157a3a',\n  },\n} as const\n" > "$WORK/t10ok.ts"
sed "s/#157a3a/#157a3b/" "$WORK/t10ok.ts" > "$WORK/t10ko.ts"
M10OK="$(ecarts_tokens "$WORK/t10ok.ts" "$WORK/d10.md" | tr '\n' '|')"; M10KO="$(ecarts_tokens "$WORK/t10ko.ts" "$WORK/d10.md" | tr '\n' '|')"
assert_eq "M10.0a — fixture fidèle : quatre valeurs comparées (casse ignorée), aucun écart de valeur" "$(printf '%s' "$M10OK" | tr '|' '\n' | grep -c 'au lieu de')|$(printf '%s' "$M10OK" | tr '|' '\n' | grep -c '^n=4$')" "0|1"
assert_eq "M10.0b — fixture dérivée d'un chiffre : exactement un écart, nommé" "$(printf '%s' "$M10KO" | tr '|' '\n' | grep -c 'st-done (clair) : #157a3b au lieu de #157a3a')" "1"
if [ -f "$SIGNAL/hooks/tokens.ts" ]; then
  E10="$(ecarts_tokens "$SIGNAL/hooks/tokens.ts" "$REPO/DESIGN.md")"
  assert_eq "M10 — aucun écart entre tokens.ts et DESIGN.md" "$(printf '%s\n' "$E10" | grep -v '^n=' | tr '\n' '|')" ""
  assert_eq "M10.1 — seize valeurs comparées (huit tokens, deux thèmes : pas de vert à vide)" "$(printf '%s\n' "$E10" | grep '^n=')" "n=16"
else ko "M10 — hooks/tokens.ts absent"; fi

echo "=== bilan : $PASS ok, $FAIL ko ==="
[ $((PASS + FAIL)) -gt 0 ] || { echo "ÉCHEC ANTI-VERT-À-VIDE : aucun cas exécuté"; exit 1; }
[ "$FAIL" -eq 0 ]
