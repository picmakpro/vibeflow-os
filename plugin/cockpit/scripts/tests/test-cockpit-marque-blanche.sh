#!/usr/bin/env bash
# test-cockpit-marque-blanche.sh — marque blanche VibeFlow de la sortie (CKPT-04 ; P67-D-03, D-04).
#   M1 aucune occurrence du nom amont dans le rendu servi ni dans les messages du serveur (lab neutre)
#   M2 logo VibeFlow en data:image/svg+xml, jamais le PNG amont · M3 la syntaxe survit au renommage
#   M4 les données du lab ne sont jamais renommées, schéma du graphe Code réécrit
#   M5 conformité à DESIGN.md (UIFN-09, P70-D-07) : statuts sur le thème, variable de texte inexistante, couleurs littérales justifiées ; mutants de M5.1 et M5.2
# Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
MOTEUR="$SCRIPTS/../skills/cockpit-moteur"
WORK="$(mktemp -d)"; AUX="$WORK/aux"; mkdir -p "$AUX"
SRV=""
trap '[ -n "$SRV" ] && { vf_hyg_stop "$SRV"; }; vf_hyg_fin; rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_ge() { if [ "$2" -ge "$3" ] 2>/dev/null; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 ($2 < $3)"; FAIL=$((FAIL+1)); fi; }
# nombre d'occurrences du nom amont (insensible à la casse) hors lignes de licence
occ() { grep -v 'vibeflow:licence-tierce' | grep -ci 'floor''plan'; }

cat > "$AUX/get.mjs" <<'JS'
import http from 'node:http';
const [, , port, p] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}` } }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => process.stdout.write(b)); }).on('error', () => {});
JS
cat > "$AUX/json.mjs" <<'JS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/donnees.mjs" <<'JS'
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const { extraireGraphe } = await import(pathToFileURL(path.join(process.argv[2], 'vf-cockpit-embed.mjs')).href);
const j = extraireGraphe(fs.readFileSync(process.argv[3], 'utf8'));
const v = new Function('j', 'return (' + process.argv[4] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/blocs.mjs" <<'JS'
// blocs.mjs <page.html> : compile chaque bloc <script> en ligne (sans src) par vm.Script ; imprime « compilés=<n> échecs=<n> »
import fs from 'node:fs';
import vm from 'node:vm';
const h = fs.readFileSync(process.argv[2], 'utf8');
let ok = 0, ko = 0;
for (const m of h.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g)) { try { new vm.Script(m[1]); ok++; } catch (e) { ko++; console.error('bloc invalide :', e.message); } }
console.log(`compilés=${ok} échecs=${ko}`);
JS
cat > "$AUX/prefixe.mjs" <<'JS'
import fs from 'node:fs';
console.log(fs.readFileSync(process.argv[2]).toString('base64').slice(0, 64));
JS

mklab() { # $1 = dossier, $2 = nom de la phase
  mkdir -p "$1/src" "$1/.planning/phases/01-x"
  printf 'import { u } from "./util.js";\nconsole.log(u());\n' > "$1/src/app.js"; printf 'export const u = () => 1;\n' > "$1/src/util.js"
  printf -- '- [x] **Phase 1: %s** - premier jet\n' "$2" > "$1/.planning/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$1/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$1/.planning/phases/01-x/01-01-SUMMARY.md"
  git -C "$1" init -q && git -C "$1" add -A && git -C "$1" -c user.email=t@t -c user.name=t commit -q -m init
}
LAB="$WORK/neutre"; mklab "$LAB" "Socle"; OUT="$LAB/.vibeflow/cockpit"
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet >/dev/null 2>&1; BRC=$?

echo "=== M1 — aucune occurrence visible du nom amont ==="
assert_eq "M1.0 — l'assemblage rend 0" "$BRC" "0"
assert_eq "M1.1 — témoin positif : le compteur voit le nom dans une chaîne jetable" "$(printf '%s\n' 'le moteur Floor''plan' | occ)" "1"
assert_eq "M1.2 — témoin : une ligne de licence est exemptée" "$(printf '%s\n' '<!-- vibeflow:licence-tierce floor''plan -->' | occ)" "0"
COCKPIT_LOG="$WORK/serve.out" cockpit_lancer "$LAB"; SRV="$VF_PID"
RP="$VF_PORT"
for _ in $(seq 1 50); do [ -s "$WORK/serve.out" ] && break; sleep 0.1; done
node "$AUX/get.mjs" "$RP" / > "$WORK/racine.html"; node "$AUX/get.mjs" "$RP" /project.html > "$WORK/projet.html"
vf_hyg_stop "$SRV"; SRV=""
assert_ge "M1.3 — la page / est servie (non vide)" "$(wc -c < "$WORK/racine.html" | tr -d ' ')" 1000
assert_ge "M1.4 — la page /project.html est servie (non vide)" "$(wc -c < "$WORK/projet.html" | tr -d ' ')" 1000
assert_eq "M1.5 — GET / : 0 occurrence" "$(occ < "$WORK/racine.html")" "0"
assert_eq "M1.6 — GET /project.html : 0 occurrence" "$(occ < "$WORK/projet.html")" "0"
assert_eq "M1.7 — messages du serveur : 0 occurrence" "$(occ < "$WORK/serve.out")" "0"
assert_ge "M1.8 — le serveur a bien écrit son message de démarrage" "$(grep -c 'VibeFlow' "$WORK/serve.out")" 1
bad=0; for f in "$OUT"/*.mjs "$OUT"/*.html; do [ "$(occ < "$f")" = 0 ] || { bad=$((bad+1)); echo "     occurrence dans $f"; }; done
assert_eq "M1.9 — aucune occurrence dans les fichiers de la sortie (hors licences)" "$bad" "0"

echo "=== M2 — logo VibeFlow inliné ==="
PFX=$(node "$AUX/prefixe.mjs" "$MOTEUR/assets/logo.png")
assert_ge "M2.1 — préfixe du PNG amont non vide" "${#PFX}" 64
assert_eq "M2.2 — témoin : le préfixe est retrouvé dans une chaîne qui le contient" "$(printf 'xx%sxx' "$PFX" | grep -c -F "$PFX")" "1"
assert_ge "M2.3 — data:image/svg+xml dans la page servie" "$(grep -c 'data:image/svg+xml' "$WORK/racine.html")" 1
assert_eq "M2.4 — le PNG amont n'est pas dans la page" "$(grep -c -F "$PFX" "$WORK/racine.html")" "0"
assert_eq "M2.5 — les deux logos sont dans les données" "$(node "$AUX/donnees.mjs" "$OUT" "$OUT/index.html" 'Object.keys(j.meta.vfLogos).sort().join(",")')" "clair,sombre"

echo "=== M3 — la syntaxe survit au renommage ==="
bad=0; for f in "$OUT"/serve.mjs "$OUT"/query.mjs "$OUT"/vf-cockpit-*.mjs; do node --check "$f" 2>/dev/null || { bad=$((bad+1)); echo "     syntaxe invalide : $f"; }; done
assert_eq "M3.1 — node --check sur serve.mjs, query.mjs et chaque vf-cockpit-*.mjs" "$bad" "0"
B=$(node "$AUX/blocs.mjs" "$OUT/index.html" 2>&1)
assert_eq "M3.2 — aucun bloc <script> invalide dans index.html" "$(printf '%s' "$B" | grep -c 'échecs=0')" "1"
assert_ge "M3.3 — au moins 5 blocs compilés (témoin d'exposition)" "$(printf '%s' "$B" | sed -n 's/.*compilés=\([0-9]*\).*/\1/p')" 5
assert_eq "M3.4 — le serveur de la sortie garde le marqueur de taille" "$(head -n 5 "$OUT/serve.mjs" | grep -c 'vibeflow:allow-large-file')" "1"

echo "=== M4 — les données du lab ne sont jamais renommées ==="
LABB="$WORK/lab-b"; mklab "$LABB" "Carte floor""plan du quartier"
node "$SCRIPTS/vf-cockpit-build.mjs" "$LABB" --quiet >/dev/null 2>&1
assert_eq "M4.1 — la phase du lab garde son nom" "$(node "$AUX/donnees.mjs" "$LABB/.vibeflow/cockpit" "$LABB/.vibeflow/cockpit/project.html" 'j.nodes.filter(n=>n.kind==="phase").map(n=>n.label).join(",")' | grep -c 'Carte floor''plan du quartier')" "1"
assert_eq "M4.2 — schéma du graphe Code" "$(node "$AUX/donnees.mjs" "$OUT" "$OUT/index.html" 'j.schema')" "vf-cockpit/graph@1"

echo "=== M5 — conformité à DESIGN.md (UIFN-09, P70-D-07) ==="
UIDIR="$MOTEUR/assets/ui"
# couleur littérale : hexadécimal de 3 à 8 chiffres en fin de mot, ou rgb/rgba/hsl/hsla( suivi d'un chiffre ; lignes `//` et lignes marquées exceptées
m5_couleurs() { grep -nE '#[0-9a-fA-F]{3,8}([^0-9a-zA-Z_-]|$)|(rgb|hsl)a?\([[:space:]]*[0-9]' "$1" | grep -vE '^[0-9]+:[[:space:]]*//' | grep -v 'vf-couleur-ok:'; }
m5_statuts() { if [ "$(grep -c -e '--st-active: var(--sev-medium)' "$1")" = 1 ] && [ "$(grep -c -e '--st-blocked: var(--sev-high)' "$1")" = 1 ]; then echo ok; else echo ko; fi; }
m5_inexistante() { cat "$@" | grep -c -e '--text-''1'; }
M5FILES=$(find "$UIDIR" -maxdepth 1 -type f \( -name '00-vibeflow.js' -o -name '*vf*.js' \) | sort)
M5N=$(printf '%s\n' "$M5FILES" | grep -c .)
assert_ge "M5.00 — la liste des fichiers jugés est calculée et non vide ($M5N)" "$M5N" 3
printf '    color: #ab12cd;\n' > "$WORK/m5-temoin.txt"
printf '    color: #ab12cd; /* vf-couleur-ok: témoin de la sonde, jamais affiché */\n// couleur #ab12cd en commentaire\n    color: rgba(var(--ink), .1);\n' > "$WORK/m5-temoin-ok.txt"
assert_eq "M5.0 — témoin : la sonde voit une couleur hexadécimale et ignore marqueur, commentaire et rgba(var(--…))" "$(m5_couleurs "$WORK/m5-temoin.txt" | wc -l | tr -d ' ')/$(m5_couleurs "$WORK/m5-temoin-ok.txt" | wc -l | tr -d ' ')" "1/0"
assert_eq "M5.1 — --st-active sur --sev-medium et --st-blocked sur --sev-high (thème clair suivi)" "$(m5_statuts "$UIDIR/00-vibeflow.js")" "ok"
mkdir -p "$WORK/m5"; sed 's/--st-active: var(--sev-medium)/--st-active: #f59e0b/' "$UIDIR/00-vibeflow.js" > "$WORK/m5/00-vibeflow.js"
assert_eq "M5.1m — mutant : --st-active en hexadécimal, la sonde M5.1 rougit" "$(m5_statuts "$WORK/m5/00-vibeflow.js")" "ko"
assert_eq "M5.2 — la variable de texte inexistante de DESIGN.md §9 n'est utilisée nulle part" "$(printf '%s\n' "$M5FILES" | xargs cat | grep -c -e '--text-''1')" "0"
sed 's/var(--text)/var(--text-''1)/' "$UIDIR/00-vibeflow.js" > "$WORK/m5/mut2.js"
assert_ge "M5.2m — mutant : la variable inexistante réintroduite, la sonde M5.2 rougit" "$(m5_inexistante "$WORK/m5/mut2.js")" 1
M5C=$(for f in $M5FILES; do m5_couleurs "$f" | sed "s|^|$(basename "$f"):|"; done)
assert_eq "M5.3 — aucune couleur littérale hors lignes marquées vf-couleur-ok:" "$M5C" ""
bad=0; for f in $M5FILES; do while IFS= read -r l; do r=$(printf '%s' "$l" | sed -n 's/.*vf-couleur-ok:[[:space:]]*//p' | sed 's/[[:space:]]*\*\/.*$//'); [ "${#r}" -ge 10 ] || { bad=$((bad+1)); echo "     raison absente ou trop courte : $(basename "$f")"; }; done < <(grep 'vf-couleur-ok:' "$f"); done
assert_eq "M5.4 — chaque marqueur vf-couleur-ok: porte une raison d'au moins 10 caractères" "$bad" "0"


echo "=== AM4 — les noms VibeFlow sont écrits une fois dans les six sources exécutées par Node (P79-D-08 option a, 79-06) ==="
# les six sources : serve.mjs, graph-query.js, query-cli.mjs (moteur) et, côté scripts, vf-cockpit-embed.mjs, vf-cockpit-lancer-post.mjs, vf-cockpit-server.mjs ;
# la liste jugée est CALCULÉE (tout le code d'exécution du dossier de scripts + les trois fichiers du moteur), jamais figée
cat > "$AUX/execution.mjs" <<'JS'
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const m = await import(pathToFileURL(path.join(process.argv[2], 'vf-cockpit-build.mjs')).href);
console.log(m.fichiersExecution(process.argv[2]).join('\n'));
JS
cat > "$AUX/occurrences.mjs" <<'JS'
// occurrences.mjs <dossier de scripts> <dossier du moteur> : compte les occurrences (compterOccurrences, l'outil d'assemblage : lignes de licence exemptées) dans la liste calculée ; « total liste détail »
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , scripts, moteur] = process.argv;
const { compterOccurrences } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-rename.mjs')).href);
const { fichiersExecution } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-build.mjs')).href);
const liste = [...fichiersExecution(scripts).map((f) => path.join(scripts, f)), ...['serve.mjs', 'graph-query.js', 'query-cli.mjs'].map((f) => path.join(moteur, 'assets', f))];
let total = 0; const detail = [];
for (const f of liste) { const c = compterOccurrences(fs.readFileSync(f, 'utf8')); total += c; if (c) detail.push(`${path.basename(f)}=${c}`); }
console.log(`${total} ${liste.length} ${detail.join(',') || 'aucune'}`);
JS
read -r AM4_N AM4_LISTE AM4_DETAIL <<< "$(node "$AUX/occurrences.mjs" "$SCRIPTS" "$MOTEUR")"
echo "     (liste jugée : $AM4_LISTE fichiers ; occurrences par fichier : $AM4_DETAIL)"
assert_ge "AM4.17a — témoin d'exposition : la liste des sources jugées est calculée et non vide" "$AM4_LISTE" 9
assert_eq "AM4.17 — aucune occurrence du nom amont dans les sources exécutées par Node (hors lignes de licence)" "$AM4_N" "0"
assert_eq "AM4.17b — témoin positif : le compteur voit le nom amont dans une chaîne jetable" "$(printf '%s\n' 'le moteur Floor''plan' | occ)" "1"
MODROOT="$(cd "$SCRIPTS/.." && pwd -P)"; ENTETE_ANCIEN="$(printf 'x-%s-token' "floor""plan")"
cat > "$AUX/entete.mjs" <<'JS'
// entete.mjs <port> <chemin> <nom d'en-tête> <jeton> : statut HTTP de la requête portant ce seul en-tête de jeton
import http from 'node:http';
const [, , port, p, nom, jeton] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}`, [nom]: jeton } }, (r) => { r.resume(); r.on('end', () => console.log(r.statusCode)); }).on('error', () => console.log('000'));
JS
COCKPIT_MODULE="$MODROOT" COCKPIT_LOG="$WORK/am418.out" cockpit_lancer "$LAB"; RC418=$?
cockpit_get / > "$WORK/am418.html" 2> /dev/null
P418="$(grep -c 'VF_COCKPIT_SERVER' "$WORK/am418.html")"
cockpit_get /api/vf/etat > /dev/null 2>&1; N418="$VF_CODE"
A418="$(node "$AUX/entete.mjs" "${VF_PORT:-0}" /api/vf/etat "$ENTETE_ANCIEN" "${VF_JETON:-x}")"
cockpit_arreter
assert_eq "AM4.18 — de bout en bout, serveur du module sur la sortie assemblée (rc=$RC418) : la page fournit VF_COCKPIT_SERVER, l'en-tête de jeton VibeFlow reçoit 200 et l'ancien 403" "page=$P418 neuf=$N418 ancien=$A418" "page=1 neuf=200 ancien=403"
assert_eq "M-NOM.0 — ancre présente : l'en-tête de jeton est écrit sous son nom VibeFlow dans vf-cockpit-lancer-post.mjs" "$(grep -cF "ENTETE_JETON = 'x-vf-cockpit-token'" "$SCRIPTS/vf-cockpit-lancer-post.mjs")" "1"

vf_hyg_assert
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
