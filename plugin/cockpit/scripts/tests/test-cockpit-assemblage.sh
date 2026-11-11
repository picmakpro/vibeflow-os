#!/usr/bin/env bash
# test-cockpit-assemblage.sh — assemblage du cockpit dans .vibeflow/cockpit (CKPT-03/04 ; P67-D-06).
#   A1 sortie et contenu · A2 données des deux pages · A3 serveur local et contrôle du Host
#   A4 refus en français, aucun appel à `claude` · A5 liste du code d'exécution (et son témoin rouge)
# Isolation git, aucun timeout externe, attente bornée par sleep 0.1. Exit 0 si tout passe, 1 sinon.

set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"; AUX="$WORK/aux"; mkdir -p "$AUX"
SRV=""
trap '[ -n "$SRV" ] && { vf_hyg_stop "$SRV"; }; vf_hyg_fin; rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"

PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }

cat > "$AUX/get.mjs" <<'JS'
// get.mjs <port> <chemin> <hôte> -> « <statut> » puis le corps
import http from 'node:http';
const [, , port, p, host] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: host } }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => { console.log(r.statusCode); process.stdout.write(b); }); }).on('error', (e) => { console.log('ERR ' + e.message); });
JS
cat > "$AUX/json.mjs" <<'JS'
// json.mjs <fichier> <expression sur j>
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const v = new Function('j', 'return (' + process.argv[3] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/donnees.mjs" <<'JS'
// donnees.mjs <page.html> <expression sur j> : lit la zone de données par vf-cockpit-embed.mjs
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const { extraireGraphe } = await import(pathToFileURL(path.join(process.argv[2], 'vf-cockpit-embed.mjs')).href);
const j = extraireGraphe(fs.readFileSync(process.argv[3], 'utf8'));
const v = new Function('j', 'return (' + process.argv[4] + ')')(j);
console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS

# --- lab neutre : git, un fichier de code qui en importe un autre, .planning plat minimal ---
LAB="$WORK/lab"; mkdir -p "$LAB/src" "$LAB/.planning/phases/01-x"
printf 'import { u } from "./util.js";\nconsole.log(u());\n' > "$LAB/src/app.js"
printf 'export const u = () => 1;\n' > "$LAB/src/util.js"
printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$LAB/.planning/ROADMAP.md"
printf '<objective>Faire le socle</objective>\n' > "$LAB/.planning/phases/01-x/01-01-PLAN.md"
echo ok > "$LAB/.planning/phases/01-x/01-01-SUMMARY.md"
git -C "$LAB" init -q && git -C "$LAB" add -A && git -C "$LAB" -c user.email=t@t -c user.name=t commit -q -m init
OUT="$LAB/.vibeflow/cockpit"

echo "=== A1 — assemblage et contenu de la sortie ==="
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" > "$WORK/build.out" 2>&1; assert_eq "A1.1 — l'assemblage rend 0" "$?" "0"
for f in index.html project.html serve.mjs query.mjs graph.json architecture.json LICENSE LICENCES-TIERCES.txt .cache/vf-cockpit.json \
  vf-cockpit-paths.mjs vf-cockpit-who.mjs vf-cockpit-planning.mjs vf-cockpit-project.mjs vf-cockpit-types.mjs vf-cockpit-embed.mjs vf-cockpit-interface.json; do
  assert_eq "A1 — $f présent" "$([ -s "$OUT/$f" ] && echo oui || echo non)" "oui"
done
assert_eq "A1.2 — .cache/vf-cockpit.json porte scriptsDir" "$(node "$AUX/json.mjs" "$OUT/.cache/vf-cockpit.json" 'typeof j.scriptsDir')" "string"
assert_eq "A1.3 — .gitignore à deux lignes dont la seconde est *" "$(awk 'END{print NR}' "$OUT/.gitignore")$(sed -n 2p "$OUT/.gitignore")" "2*"
assert_eq "A1.4 — aucun dossier floorplan dans le lab" "$([ -e "$LAB/floorplan" ] && echo oui || echo non)" "non"
assert_eq "A1.5 — aucun CLAUDE.local.md dans le lab" "$([ -e "$LAB/CLAUDE.local.md" ] && echo oui || echo non)" "non"
assert_eq "A1.6 — aucun outil d'assemblage recopié" "$(ls "$OUT" | grep -cE '^vf-cockpit-(build|rename|code)')" "0"
assert_eq "A1.7 — l'état git du lab est inchangé (sortie ignorée)" "$(git -C "$LAB" status --porcelain | grep -c .)" "0"

echo "=== A2 — données des deux pages ==="
assert_eq "A2.1 — index.html : onglet code" "$(node "$AUX/donnees.mjs" "$OUT" "$OUT/index.html" 'j.meta.vfTab')" "code"
assert_eq "A2.2 — project.html : schéma Projet" "$(node "$AUX/donnees.mjs" "$OUT" "$OUT/project.html" 'j.schema')" "vibeflow/cockpit-project@1"
assert_eq "A2.3 — architecture brute : un nœud par dossier de code" "$(node "$AUX/json.mjs" "$OUT/architecture.json" 'j.nodes.map(n=>n.label).join(",")')" "src"

echo "=== A3 — serveur local et contrôle du Host ==="
cockpit_lancer "$LAB"; SRV="$VF_PID"
RP="$VF_PORT"
assert_eq "A3.1 — le port réel est lu dans server.json" "$([ "${RP:-0}" -gt 0 ] && echo oui || echo non)" "oui"
for page in / /project.html; do
  R=$(node "$AUX/get.mjs" "$RP" "$page" "127.0.0.1:$RP")
  assert_eq "A3 — GET $page rend 200" "$(sed -n 1p <<<"$R")" "200"
  assert_has "A3 — GET $page rend du HTML" "$R" "<html"
done
assert_eq "A3.4 — Host étranger rend 403" "$(node "$AUX/get.mjs" "$RP" / "evil.example:$RP" | head -1)" "403"
vf_hyg_stop "$SRV"; SRV=""

echo "=== A4 — refus en français, aucun appel à claude ==="
NOLAB="$WORK/sans-planning"; mkdir -p "$NOLAB"
MSG=$(node "$SCRIPTS/vf-cockpit-build.mjs" "$NOLAB" 2>&1); RC=$?
assert_eq "A4.1 — lab sans .planning : exit 2" "$RC" "2"
assert_has "A4.2 — message en français" "$MSG" "aucun dossier .planning"
ISO="$WORK/iso"; mkdir -p "$ISO"; cp "$SCRIPTS"/vf-cockpit-*.mjs "$SCRIPTS/vf-cockpit-interface.json" "$ISO/"
MSG=$(node "$ISO/vf-cockpit-build.mjs" "$LAB" 2>&1); RC=$?
assert_eq "A4.3 — moteur absent : exit 3" "$RC" "3"
assert_has "A4.4 — message en français" "$MSG" "moteur du cockpit introuvable"
FAKE="$WORK/fake"; mkdir -p "$FAKE"; printf '#!/bin/sh\ntouch "%s/CLAUDE-APPELE"\n' "$WORK" > "$FAKE/claude"; chmod +x "$FAKE/claude"
PATH="$FAKE:$PATH" node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet >/dev/null 2>&1
assert_eq "A4.5 — le faux claude n'est jamais appelé" "$([ -e "$WORK/CLAUDE-APPELE" ] && echo oui || echo non)" "non"

echo "=== A5 — liste du code d'exécution ==="
D5="$WORK/d5"; mkdir -p "$D5"
for f in vf-cockpit-build vf-cockpit-rename vf-cockpit-code-vf vf-cockpit-fr-inventaire vf-cockpit-who; do echo "export {};" > "$D5/$f.mjs"; done
cat > "$AUX/liste.mjs" <<'JS'
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const m = await import(pathToFileURL(path.join(process.argv[2], 'vf-cockpit-build.mjs')).href);
console.log(m.fichiersExecution(process.argv[3]).join(','));
JS
assert_eq "A5.1 — seul vf-cockpit-who.mjs est du code d'exécution" "$(node "$AUX/liste.mjs" "$SCRIPTS" "$D5")" "vf-cockpit-who.mjs"
MUT="$WORK/mut"; mkdir -p "$MUT"; cp "$SCRIPTS"/vf-cockpit-*.mjs "$SCRIPTS/vf-cockpit-interface.json" "$MUT/"
sed 's#, /^vf-cockpit-fr-.\*\\.mjs$/##' "$MUT/vf-cockpit-build.mjs" > "$MUT/b.tmp" && mv "$MUT/b.tmp" "$MUT/vf-cockpit-build.mjs"
assert_eq "A5.2 — témoin rouge : sans le motif fr-, le leurre fr-inventaire est recopié" "$(node "$AUX/liste.mjs" "$MUT" "$D5")" "vf-cockpit-fr-inventaire.mjs,vf-cockpit-who.mjs"

echo "=== A6 — diagnostic des lignes non comprises (premier assemblage et --rebuild) ; .planning jamais écrit ==="
# Les motifs sont éprouvés en bibliothèque par test-cockpit-projet-graphe.sh (P8) ; ici la sortie du lanceur et la lecture seule du chemin `build --rebuild`.
cat > "$AUX/asm.mjs" <<'JS'
// asm.mjs <dossier de scripts à tester> <lab> <dossier de scripts du moteur> : assemble avec le build du dossier donné (mutant) et le moteur réel
import path from 'node:path';
import { pathToFileURL } from 'node:url';
const [, , dir, lab, scripts] = process.argv;
const m = await import(pathToFileURL(path.join(dir, 'vf-cockpit-build.mjs')).href);
m.assembler({ lab, scriptsDir: scripts });
JS
LAB6="$WORK/lab6"; mkdir -p "$LAB6/src" "$LAB6/.planning/phases/01-x"; cp "$LAB/src/"*.js "$LAB6/src/"
printf '%s\n' '- [x] **Phase 1: Socle** - premier jet' '- [ ] **Phase 2 Suite** - illisible' '' '### Phase 1: Socle' '**Goal**: ok' '' '### Phase 2: Suite' '**Goal** — non lu' > "$LAB6/.planning/ROADMAP.md"
printf '<objective>Faire le socle</objective>\n' > "$LAB6/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$LAB6/.planning/phases/01-x/01-01-SUMMARY.md"
git -C "$LAB6" init -q && git -C "$LAB6" add -A && git -C "$LAB6" -c user.email=t@t -c user.name=t commit -q -m init
AV6="$(find "$LAB6/.planning" | sort | while read -r f; do [ -f "$f" ] && cksum "$f" || echo "$f"; done)"
node "$SCRIPTS/vf-cockpit.mjs" build --lab "$LAB6" > "$WORK/a6a.out" 2>&1; assert_eq "A6.1 — premier assemblage : rend 0" "$?" "0"
assert_has "A6.2 — premier assemblage : « 2 ligne(s) non comprise(s) » nommées fichier:ligne (CLI)" "$(cat "$WORK/a6a.out")" "2 ligne(s) non comprise(s) du planning : .planning/ROADMAP.md:2 .planning/ROADMAP.md:8"
node "$SCRIPTS/vf-cockpit.mjs" build --rebuild --lab "$LAB6" > "$WORK/a6b.out" 2>&1; assert_eq "A6.3 — build --rebuild : rend 0" "$?" "0"
assert_has "A6.4 — build --rebuild : le même diagnostic" "$(cat "$WORK/a6b.out")" "2 ligne(s) non comprise(s) du planning : .planning/ROADMAP.md:2 .planning/ROADMAP.md:8"
assert_eq "A6.5 — le diagnostic est aussi dans les données de la page Projet (interface)" "$(node "$AUX/donnees.mjs" "$LAB6/.vibeflow/cockpit" "$LAB6/.vibeflow/cockpit/project.html" 'j.meta.vf.drift.nonComprises.map(x=>x.fichier+":"+x.ligne).join(",")')" ".planning/ROADMAP.md:2,.planning/ROADMAP.md:8"
assert_eq "A6.6 — .planning intact après deux assemblages (liste et cksum avant/après)" "$(find "$LAB6/.planning" | sort | while read -r f; do [ -f "$f" ] && cksum "$f" || echo "$f"; done | cmp -s - <(printf '%s\n' "$AV6") && echo identique)" "identique"
assert_eq "A6.7 — témoin : le lab canonique de A1 ne dit rien de non compris" "$(grep -c 'non comprise' "$WORK/build.out")" "0"
MUT6="$WORK/mut6"; mkdir -p "$MUT6"; cp "$SCRIPTS"/vf-cockpit-*.mjs "$SCRIPTS/vf-cockpit-interface.json" "$MUT6/"
sed 's#^  if (diagnostic && !quiet) console.log(diagnostic);$##' "$MUT6/vf-cockpit-build.mjs" > "$MUT6/b.tmp" && mv "$MUT6/b.tmp" "$MUT6/vf-cockpit-build.mjs"
assert_eq "A6.8 — mutant (affichage du diagnostic retiré : 0 occurrence restante) : plus aucune ligne « non comprise » en sortie, A6.2 rougirait" "$(grep -c 'console.log(diagnostic)' "$MUT6/vf-cockpit-build.mjs")|$(node "$AUX/asm.mjs" "$MUT6" "$LAB6" "$SCRIPTS" 2>&1 | grep -c 'non comprise')" "0|0"
assert_eq "A6.9 — témoin du mutant : le build réel, lui, affiche le diagnostic par le même chemin" "$(node "$AUX/asm.mjs" "$SCRIPTS" "$LAB6" "$SCRIPTS" 2>&1 | grep -c 'non comprise')" "1"

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
