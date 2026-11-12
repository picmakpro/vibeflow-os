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
for f in index.html project.html graph.json architecture.json LICENSE LICENCES-TIERCES.txt .cache/vf-cockpit.json; do   # 79-06 : la sortie ne porte que des données (aucun code : AM4.16)
  assert_eq "A1 — $f présent" "$([ -s "$OUT/$f" ] && echo oui || echo non)" "oui"
done
assert_eq "A1.2 — .cache/vf-cockpit.json porte scriptsDir" "$(node "$AUX/json.mjs" "$OUT/.cache/vf-cockpit.json" 'typeof j.scriptsDir')" "string"
assert_eq "A1.3 — .gitignore à deux lignes dont la seconde est *" "$(awk 'END{print NR}' "$OUT/.gitignore")$(sed -n 2p "$OUT/.gitignore")" "2*"
assert_eq "A1.4 — aucun dossier floorplan dans le lab" "$([ -e "$LAB/floorplan" ] && echo oui || echo non)" "non"
assert_eq "A1.5 — aucun CLAUDE.local.md dans le lab" "$([ -e "$LAB/CLAUDE.local.md" ] && echo oui || echo non)" "non"
assert_eq "A1.6 — aucun outil d'assemblage recopié" "$(ls "$OUT" | grep -cE '^vf-cockpit-(build|rename|code)')" "0"
assert_eq "A1.7 — l'état git du lab est inchangé (sortie ignorée)" "$(git -C "$LAB" status --porcelain | grep -c .)" "0"

echo "=== A2 — données des deux pages ==="
assert_eq "A2.1 — index.html : onglet code" "$(node "$AUX/donnees.mjs" "$SCRIPTS" "$OUT/index.html" 'j.meta.vfTab')" "code"
assert_eq "A2.2 — project.html : schéma Projet" "$(node "$AUX/donnees.mjs" "$SCRIPTS" "$OUT/project.html" 'j.schema')" "vibeflow/cockpit-project@1"
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

# AM6.F1 (79-06, S3, audit au06a) : un module sans son serve.mjs n'est pas lancé, et le lanceur ne retombe JAMAIS sur <sortie>/serve.mjs (un fichier du lab)
F1M="$(cockpit_module_copie)"; rm -f "$F1M/skills/cockpit-moteur/assets/serve.mjs"
F1L="$WORK/f1-lab"; mkdir -p "$F1L/.planning"; printf '# Projet\n' > "$F1L/.planning/PROJECT.md"
F1OUT=$(cd "$F1L" && VF_COCKPIT_DEMARRAGE_MS=2000 node "$F1M/scripts/vf-cockpit.mjs" open --lab "$F1L" --no-open 2>&1); F1RC=$?
assert_eq "AM6.F1a — module sans serve.mjs : refus code 3" "$F1RC" "3"
assert_has "AM6.F1b — message en français, dit le fichier manquant" "$F1OUT" "serve.mjs"
assert_eq "AM6.F1c — rien n'a été lancé (ni server.json ni journal de serveur)" "$([ -e "$F1L/.vibeflow/cockpit/.cache/server.json" ] || [ -s "$F1L/.vibeflow/cockpit/.cache/serveur.log" ] && echo lancé || echo rien)" "rien"
assert_eq "AM6.F1d — le refus précède l'assemblage (aucune page assemblée dans le lab)" "$([ -e "$F1L/.vibeflow/cockpit/index.html" ] && echo assemblé || echo rien)" "rien"
# AM6.F1 mutant (S3b) : la copie du module sans SEULE la ligne de refus de main() (celle qui précède assemblerLab) ; le garde de demarrer() retient le lancement (code 3 conservé), donc AM6.F1a-c restent verts : seul AM6.F1d rougit, pour la bonne raison (le lab est assemblé avant le refus)
F1MM="$(cockpit_module_copie)"; sed -i.avant '/^  if (!serveDuModule()) { console.error/d' "$F1MM/scripts/vf-cockpit.mjs"; cmp -s "$F1MM/scripts/vf-cockpit.mjs.avant" "$F1MM/scripts/vf-cockpit.mjs" && echo "ancre absente : le mutant F1 n'a rien changé" >&2; rm -f "$F1MM/scripts/vf-cockpit.mjs.avant"; rm -f "$F1MM/skills/cockpit-moteur/assets/serve.mjs"
F1ML="$WORK/f1m-lab"; mkdir -p "$F1ML/.planning"; printf '# Projet\n' > "$F1ML/.planning/PROJECT.md"
F1MOUT=$(cd "$F1ML" && VF_COCKPIT_DEMARRAGE_MS=2000 node "$F1MM/scripts/vf-cockpit.mjs" open --lab "$F1ML" --no-open 2>&1); F1MRC=$?
assert_eq "AM6.F1-mutant — sans la ligne de refus de main() : la copie est valide, le code reste 3 (garde de demarrer), la page est pourtant assemblée (AM6.F1d rougirait)" "$(node --check "$F1MM/scripts/vf-cockpit.mjs" 2> /dev/null && echo valide || echo invalide) rc=$F1MRC $([ -e "$F1ML/.vibeflow/cockpit/index.html" ] && echo assemblé || echo rien)" "valide rc=3 assemblé"
assert_eq "AM6.F1-témoin du mutant — le module réel, lui, n'assemble rien avant le refus" "$([ -e "$F1L/.vibeflow/cockpit/index.html" ] && echo assemblé || echo rien)" "rien"

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
sed 's#, /^vf-cockpit-fr-.\*\\.mjs$/##' "$MUT/vf-cockpit-module.mjs" > "$MUT/b.tmp" && mv "$MUT/b.tmp" "$MUT/vf-cockpit-module.mjs"   # 79-06 : fichiersExecution vit dans vf-cockpit-module.mjs
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
assert_eq "A6.5 — le diagnostic est aussi dans les données de la page Projet (interface)" "$(node "$AUX/donnees.mjs" "$SCRIPTS" "$LAB6/.vibeflow/cockpit/project.html" 'j.meta.vf.drift.nonComprises.map(x=>x.fichier+":"+x.ligne).join(",")')" ".planning/ROADMAP.md:2,.planning/ROADMAP.md:8"
assert_eq "A6.6 — .planning intact après deux assemblages (liste et cksum avant/après)" "$(find "$LAB6/.planning" | sort | while read -r f; do [ -f "$f" ] && cksum "$f" || echo "$f"; done | cmp -s - <(printf '%s\n' "$AV6") && echo identique)" "identique"
assert_eq "A6.7 — témoin : le lab canonique de A1 ne dit rien de non compris" "$(grep -c 'non comprise' "$WORK/build.out")" "0"
MUT6="$WORK/mut6"; mkdir -p "$MUT6"; cp "$SCRIPTS"/vf-cockpit-*.mjs "$SCRIPTS/vf-cockpit-interface.json" "$MUT6/"
sed 's#^  if (diagnostic && !quiet) console.log(diagnostic);$##' "$MUT6/vf-cockpit-build.mjs" > "$MUT6/b.tmp" && mv "$MUT6/b.tmp" "$MUT6/vf-cockpit-build.mjs"
assert_eq "A6.8 — mutant (affichage du diagnostic retiré : 0 occurrence restante) : plus aucune ligne « non comprise » en sortie, A6.2 rougirait" "$(grep -c 'console.log(diagnostic)' "$MUT6/vf-cockpit-build.mjs")|$(node "$AUX/asm.mjs" "$MUT6" "$LAB6" "$SCRIPTS" 2>&1 | grep -c 'non comprise')" "0|0"
assert_eq "A6.9 — témoin du mutant : le build réel, lui, affiche le diagnostic par le même chemin" "$(node "$AUX/asm.mjs" "$SCRIPTS" "$LAB6" "$SCRIPTS" 2>&1 | grep -c 'non comprise')" "1"


echo "=== AM4 — la sortie ne porte plus que des données : purge du code des versions précédentes, aucun code à l'assemblage (SOCL-07, P79-D-26, 79-06) ==="
am4_code() { ls -A "$1" | grep -E '\.mjs$|^vf-cockpit-interface\.json$' | tr '\n' ' '; } # fichiers de code présents à la racine d'une sortie
L15="$WORK/lab15"; cp -R "$LAB" "$L15"; rm -rf "$L15/.vibeflow"; O15="$L15/.vibeflow/cockpit"
node "$SCRIPTS/vf-cockpit-build.mjs" "$L15" --quiet > "$WORK/am15-a.out" 2>&1
# sortie d'une version précédente : du code, le contrat ET des données du lab (custom-flows.json) ; l'assemblage suivant purge le code seulement
for f in serve.mjs query.mjs vf-cockpit-server.mjs vf-cockpit-terminal-processus.mjs vf-cockpit-interface.json; do printf '// code d une version précédente\n' > "$O15/$f"; done
printf '{"flows":[{"id":"gardé"}]}\n' > "$O15/custom-flows.json"; AV15="$(cksum < "$O15/custom-flows.json")"
node "$SCRIPTS/vf-cockpit-build.mjs" "$L15" --quiet > "$WORK/am15-b.out" 2>&1; RC15=$?
assert_eq "AM4.15a — après assemblage, la sortie d'une version précédente ne porte plus aucun fichier de code ni de contrat (assemblage rc=$RC15)" "$RC15|$(am4_code "$O15")" "0|"
assert_eq "AM4.15b — témoin positif : les données restent (custom-flows.json identique, LICENSE et graph.json présents) : une purge de tout le dossier rougit" "$([ "$(cksum < "$O15/custom-flows.json" 2> /dev/null)" = "$AV15" ] && echo identique || echo perdu) $([ -s "$O15/LICENSE" ] && echo licence || echo sans) $([ -s "$O15/graph.json" ] && echo graphe || echo sans)" "identique licence graphe"
L16="$WORK/lab16"; cp -R "$LAB" "$L16"; rm -rf "$L16/.vibeflow"; O16="$L16/.vibeflow/cockpit"
node "$SCRIPTS/vf-cockpit-build.mjs" "$L16" --quiet > "$WORK/am16.out" 2>&1
assert_eq "AM4.16 — une sortie fraîchement assemblée ne contient aucun *.mjs ni vf-cockpit-interface.json (témoin d'exposition : la liste des fichiers de la sortie n'est pas vide)" "$(ls -A "$O16" | awk 'END{print (NR >= 5) ? "liste-non-vide" : "liste-vide"}') code=[$(am4_code "$O16")]" "liste-non-vide code=[]"
# ancres des mutants de la tâche 4a (écrites ici, jouées avec le code) ; elles rougissent tant que le code visé n'existe pas
assert_eq "M-PURGE-LARGE.0 — ancre présente : la purge de l'assemblage vise une liste de motifs de code (CODE_ANCIEN dans vf-cockpit-build.mjs)" "$(grep -cF 'const CODE_ANCIEN =' "$SCRIPTS/vf-cockpit-build.mjs")" "1"
assert_eq "M-ORDRE.0 — ancre présente : la page du moteur est renommée par renommerPageMoteur avant l'insertion des données (vf-cockpit-rename.mjs)" "$(grep -cF 'export function renommerPageMoteur' "$SCRIPTS/vf-cockpit-rename.mjs")" "1"

# ---- mutants de la tâche 4a (79-06) : l'assemblage est rejoué par une COPIE du module mutée (cockpit_module_muter) ----
am4_asm() { # <racine du module muté> <lab> : assemble le lab avec le lanceur d'assemblage de cette copie ; rend le code de sortie
  node "$1/scripts/vf-cockpit-build.mjs" "$2" --quiet > "$WORK/am4m-$(basename "$2").out" 2>&1; echo $?
}
cockpit_module_muter mpurge vf-cockpit-build.mjs 's#^const CODE_ANCIEN = .*#const CODE_ANCIEN = [/./];#'; MP="$COCKPIT_MODULE"; unset COCKPIT_MODULE
LMP="$WORK/lab-mpurge"; cp -R "$LAB" "$LMP"; rm -rf "$LMP/.vibeflow"; OMP="$LMP/.vibeflow/cockpit"; am4_asm "$MP" "$LMP" > /dev/null
printf '{"flows":[{"id":"gardé"}]}\n' > "$OMP/custom-flows.json"; AVMP="$(cksum < "$OMP/custom-flows.json")"; RCMP="$(am4_asm "$MP" "$LMP")"
assert_eq "M-PURGE-LARGE — purge de tout le dossier : la copie est valide (node --check), AM4.15b rougit (données perdues : custom-flows.json)" "$(node --check "$MP/scripts/vf-cockpit-build.mjs" 2> /dev/null && echo valide || echo invalide) $([ "$(cksum < "$OMP/custom-flows.json" 2> /dev/null)" = "$AVMP" ] && echo identique || echo perdu)" "valide perdu"
cockpit_module_muter mordre vf-cockpit-build.mjs "s#const html = renommerPageMoteur(read(path.join(sortie, 'index.html')));#const html = read(path.join(sortie, 'index.html'));#"; MR="$COCKPIT_MODULE"; unset COCKPIT_MODULE
LMR="$WORK/lab-mordre"; cp -R "$LAB" "$LMR"; rm -rf "$LMR/.vibeflow"; RCMR="$(am4_asm "$MR" "$LMR")"
assert_eq "M-ORDRE — insertion des données avant le renommage de la page du moteur : la copie est valide, l'assemblage échoue (code non nul) et la page n'a pas de données lisibles (A2.1 rougit)" "$(node --check "$MR/scripts/vf-cockpit-build.mjs" 2> /dev/null && echo valide || echo invalide) rc=$([ "$RCMR" != 0 ] && echo non-nul || echo nul) A2.1=$([ "$(node "$AUX/donnees.mjs" "$SCRIPTS" "$LMR/.vibeflow/cockpit/index.html" 'j.meta.vfTab' 2> /dev/null | tail -1)" = code ] && echo vert || echo rouge)" "valide rc=non-nul A2.1=rouge"

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
