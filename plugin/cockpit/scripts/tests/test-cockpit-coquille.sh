#!/usr/bin/env bash
# test-cockpit-coquille.sh — la coquille statique du cockpit (79-16, SOCL-20 ; C5, A1 à A3, A30, A37, A40, A41, A48, A51, A53, A55).
#   K0 témoins · K1 document aux quatre adresses · K2 fichiers de /_vf/ (table fermée, ETag, 304, lien) · K3 CSP · K4 E9 (fichier planté) · K5 service retiré
#   K6 module servi = module lancé · A37 gardes de chemin · C1 à C8 navigateur (onglet rendu, adresses, chargerOnglet, surOnglet, persistants, classe, terminal, échec)
#   P aide de mutation de page · M-* mutants (copies du module par cockpit_module_muter, jamais le module du dépôt)
# Lab neutre dans mktemp, HOME jetable, isolation git. Le code testé est celui du dossier de cette suite. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE GIT_CEILING_DIRECTORIES
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
TESTS="$SCRIPTS/tests"; MOD="$(cd "$SCRIPTS/.." && pwd -P)"; ENG="$MOD/skills/cockpit-moteur"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home"
export HOME="$WORK/home"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"

PASS=0; FAIL=0
assert_eq() { if [ "$#" -ne 3 ]; then echo "  ❌ FAIL — $1 (assert_eq a reçu $# arguments au lieu de 3)"; FAIL=$((FAIL+1)); elif [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [${3:0:300}]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     sous-chaîne interdite présente: [$3]"; FAIL=$((FAIL+1)); fi; }
TA="$TESTS/terminal-aux.mjs"; OR="$TESTS/coquille-oracle.mjs"; CH="$TESTS/coquille-chrome.mjs"

# --- aides ---
oj() { node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{let j;try{j=JSON.parse(s)}catch{console.log("illisible");return}const v=new Function("j","return ("+process.argv[1]+")")(j);console.log(typeof v==="string"?v:JSON.stringify(v))})' "$1"; }
rq() { # rq <METHODE> <chemin> <fichier-corps> [options de terminal-aux req] -> RQ_CODE, RQ_H (en-têtes JSON), corps dans le fichier
  local m="$1" p="$2" f="$3"; shift 3
  node "$TA" req "${PORT:-0}" "$m" "$p" --corps-vers "$f" "$@" > "$WORK/rq.out" 2>&1
  RQ_CODE="$(sed -n 1p "$WORK/rq.out")"; RQ_H="$(sed -n 2p "$WORK/rq.out")"
}
hv() { printf '%s' "$RQ_H" | oj "j[\"$1\"]||\"\""; } # valeur d'un en-tête de la dernière réponse (nom en minuscules)
taille() { wc -c < "$1" | tr -d ' '; }
mklab() { # lab neutre : phases 1 (faite) et 2 (marqueur), un plan, une mission, un dépôt dont le remote porte un marqueur
  local L="$1"; mkdir -p "$L/src" "$L/.planning/phases/01-x" "$L/.planning/missions"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"; printf 'export const m = 2;\n' > "$L/src/MQ16-fichier.js"
  printf -- '- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: MQ16-PHASE** - deuxième jet\n- [ ] **Phase 3: Fin** - dernier jet\n' > "$L/.planning/ROADMAP.md"
  printf '<objective>Faire le socle</objective>\n' > "$L/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$L/.planning/phases/01-x/01-01-SUMMARY.md"
  printf '{"nodes":[{"id":"a","step":"un","deps":[],"status":"running"},{"id":"b","step":"deux","deps":["a"],"status":"ready"}]}\n' > "$L/.planning/missions/MISSION-1-x.dag.json"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  git -C "$L" remote add origin "https://example.invalid/MQ16-REMOTE/depot.git"
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || { echo "assemblage KO"; cat "$WORK/build.out"; }
}
demarrer() { cockpit_lancer "$@"; RL=$?; PORT="${VF_PORT:-0}"; }
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
REAL_HOME="$HOME"; REAL_HOME="$(node -e 'console.log(require("os").userInfo().homedir)')"
chrome() { local m="$1"; shift; REAL_HOME="$REAL_HOME" node "$CH" "$m" "$CHROME" "$@"; } # chrome <mode> <args…>

echo "=== K0 — témoins : serveur, sortie assemblée, marqueurs du lab ==="
LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"
demarrer "$LAB"
assert_eq "K0.1 — témoin : le serveur est prêt" "$RL|$([ "$PORT" -gt 0 ] && echo oui || echo non)" "0|oui"
assert_eq "K0.2 — témoin de présence : la sortie contient index.html, project.html (marqueur de phase) et graph.json (marqueur de remote)" "$(for f in index.html project.html graph.json; do [ -s "$OUT/$f" ] && echo oui || echo non; done | tr '\n' ' ')$(node "$OR" marque "$OUT/project.html" MQ16-PHASE) $(node "$OR" marque "$OUT/graph.json" MQ16-REMOTE)" "oui oui oui oui oui"
assert_eq "K0.3 — témoin : le chemin du lab est dans graph.json (meta.root)" "$(node "$OR" marque "$OUT/graph.json" "$LAB")" "oui"

echo "=== K1 — le document : composé du module, sans donnée du lab ==="
rq GET /project.html "$WORK/doc-p.html"; K1CODE="$RQ_CODE"; K1CT="$(hv content-type)"; K1CC="$(hv cache-control)"; K1CL="$(hv content-length)"; K1CSP="$(hv content-security-policy)"
TP="$(taille "$WORK/doc-p.html")"
assert_eq "K1.1 — /project.html : 200, text/html, no-store, Content-Length exact, entre 100 000 et 700 000 octets, un seul bloc de manifeste, aucun marqueur du lab ni son chemin" "$K1CODE|$K1CT|$K1CC|$([ "$K1CL" = "$TP" ] && echo exact || echo "$K1CL/$TP")|$([ "$TP" -ge 100000 ] && [ "$TP" -le 700000 ] && echo borne || echo "hors:$TP")|$(node "$OR" manifeste "$WORK/doc-p.html" | oj 'j.erreur||"un"')|$(node "$OR" marque "$WORK/doc-p.html" MQ16-PHASE)|$(node "$OR" marque "$WORK/doc-p.html" MQ16-fichier)|$(node "$OR" marque "$WORK/doc-p.html" "$LAB")" "200|text/html; charset=utf-8|no-store|exact|borne|un|non|non|non"

echo "=== K2 — les fichiers de /_vf/ : étiquette forte, 304 ==="
UIN="$(ls "$ENG/assets/ui" | grep -c '\.js$')"
node "$OR" manifeste "$WORK/doc-p.html" > "$WORK/man.json"
assert_eq "K2.1 — le manifeste nomme coquille-portee.js, coquille.js, moteur.js, graph-query.js, vendor/elk.bundled.js et une entrée par fichier de ui/ du module" "$(oj 'j.noms?(["coquille-portee.js","coquille.js","moteur.js","graph-query.js","vendor/elk.bundled.js"].every((n)=>j.noms.includes(n))&&j.noms.filter((n)=>n.startsWith("ui/")).length):"pas de manifeste"' < "$WORK/man.json")" "$UIN"
assert_has "K2.1 — chaque fichier du manifeste : 200, JavaScript, étiquette = sha256 des octets reçus, no-cache" "$(node "$OR" assets "$PORT" "$WORK/doc-p.html")" "ok "
assert_eq "K2.2 — If-None-Match : égale, faible, liste, * → 304 sans corps avec l'étiquette ; une autre étiquette → 200" "$(node "$OR" inm "$PORT" moteur.js)" "ok"

echo "=== K3 — la CSP : empreintes des scripts en ligne et une seule source, le préfixe ==="
node "$OR" csp "$WORK/doc-p.html" "$K1CSP" "http://127.0.0.1:$PORT/_vf/" > "$WORK/csp.json"
assert_eq "K3.1 — empreintes de script-src = celles des scripts en ligne du corps servi ; une seule autre source, http://127.0.0.1:<port>/_vf/ ; valeur servie = valeur reconstruite" "$(oj '[j.egales,JSON.stringify(j.autres),j.servi===j.attendu].join("|")' < "$WORK/csp.json")" "true|[\"http://127.0.0.1:$PORT/_vf/\"]|true"
assert_eq "K3.1 — script-src sans 'self', sans 'unsafe-', sans *" "$(oj '/\x27self\x27|unsafe-|\*/.test(j.servi)?"interdit":"propre"' < "$WORK/csp.json")" "propre"
cat > "$AUX/ligne.mjs" <<'JS'
// ligne.mjs <serve.mjs> : la ligne « const csp = » du serveur égale la copie figée de v2.75.0 avec la seule insertion de la source du préfixe
import fs from 'node:fs'; import { execFileSync } from 'node:child_process';
const [, , serve, aux] = process.argv;
const ancien = "  const csp = `default-src 'none'; script-src ${[...new Set(hashes)].join(' ')}; style-src 'unsafe-inline'; img-src 'self' data:; font-src data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'; object-src 'none'`;";
const ligne = fs.readFileSync(serve, 'utf8').split('\n').find((x) => x.startsWith('  const csp = ')) || '';
const attendu = ancien.replace(".join(' ')}; style-src", ".join(' ')} ${source}; style-src");
const figee = execFileSync('node', [aux, 'ligne-csp-v275'], { encoding: 'utf8' }).trimEnd();
console.log([ligne === attendu ? 'serveur' : 'serveur-different', figee === attendu ? 'figee' : 'figee-differente'].join(' '));
JS
assert_eq "K3.3 — la ligne « const csp = » de serve.mjs ne diffère de la copie de v2.75.0 que par la source du préfixe, et terminal-aux en porte la copie figée neuve" "$(node "$AUX/ligne.mjs" "$ENG/assets/serve.mjs" "$TA")" "serveur figee"

echo "=== K1 (suite) — les quatre adresses, les méthodes, les jetons ==="
rq GET / "$WORK/doc-r.html"; rq GET /index.html "$WORK/doc-i.html"; rq GET /equipe.html "$WORK/doc-e.html"; rq GET /project.html "$WORK/doc-p.html"
assert_eq "K1.1 — les quatre adresses rendent les mêmes octets une fois retirés le <title> et le script de jeton" "$(node "$OR" memes "$WORK/doc-r.html" "$WORK/doc-i.html" "$WORK/doc-p.html" "$WORK/doc-e.html")" "oui"
assert_eq "K1.1 — chaque adresse porte le titre de son onglet" "$(for f in r i p e; do node "$OR" titre "$WORK/doc-$f.html"; done | tr '\n' '|')" "VibeFlow · Code|VibeFlow · Code|VibeFlow · Projet|VibeFlow · Équipe|"
TOKC="$(node "$OR" jetons "$WORK/doc-r.html" | oj 'j.token')"; TOKP="$(node "$OR" jetons "$WORK/doc-p.html" | oj 'j.token')"
assert_eq "K1.1 — le champ token est la première clé : jeton Code pour /, /index.html et /equipe.html, jeton Projet pour /project.html, deux jetons distincts" "$(for f in r i e p; do node "$OR" jetons "$WORK/doc-$f.html" | oj 'j.premiere'; done | tr '\n' ' ')$([ "$TOKC" != "$TOKP" ] && [ "${#TOKC}" -ge 16 ] && [ "$(node "$OR" jetons "$WORK/doc-i.html" | oj 'j.token')" = "$TOKC" ] && [ "$(node "$OR" jetons "$WORK/doc-e.html" | oj 'j.token')" = "$TOKC" ] && echo oui || echo non)" "true true true true oui"
rq GET /project.html "$WORK/doc-p.html"
assert_eq "K1.2 — en-têtes : no-store, nosniff, DENY, CSP présente" "$(hv cache-control)|$(hv x-content-type-options)|$(hv x-frame-options)|$([ -n "$(hv content-security-policy)" ] && echo csp)" "no-store|nosniff|DENY|csp"
rq HEAD /project.html "$WORK/head.out"; HC="$(hv content-length)"; HT="$(hv content-type)"
assert_eq "K1.3 — HEAD : 200, mêmes en-têtes, corps vide ; POST, PUT, DELETE : 405" "$RQ_CODE|$HC|$HT|$(taille "$WORK/head.out")|$(for m in POST PUT DELETE; do rq "$m" /project.html "$WORK/m.out"; printf '%s ' "$RQ_CODE"; done)" "200|$(taille "$WORK/doc-p.html")|text/html; charset=utf-8|0|405 405 405 "
J="$(node "$OR" jetons "$WORK/doc-p.html")"
assert_eq "K1.4 — un seul script de jeton, les trois jetons y sont (equipe = code), nulle part ailleurs dans le document" "$(printf '%s' "$J" | oj '[j.nbScripts,j.jetons.code===j.jetons.equipe,j.jetons.projet.length>=16,j.dehors]')" "[1,true,true,0]"
assert_eq "K1.4 — ni le manifeste ni aucun fichier de /_vf/ ne porte un jeton, le chemin du lab, un marqueur du lab, une clé interdite" "$(node "$OR" contient "$PORT" "$WORK/doc-p.html" "$TOKC" "$TOKP" "$LAB" MQ16-PHASE MQ16-fichier MQ16-REMOTE '"doing"' '"mandat"' '"messages"' '"outils"' '"fil"' | sed 's/^document$//;s/,document//;s/document,//')" ""
assert_eq "K1.5 — Sec-Fetch-Site: cross-site : 403 sur les quatre adresses et sur /_vf/" "$(for u in / /index.html /project.html /equipe.html /_vf/moteur.js; do rq GET "$u" "$WORK/x.out" --entete sec-fetch-site:cross-site; printf '%s ' "$RQ_CODE"; done)" "403 403 403 403 403 "

echo "=== K2 (suite) — table fermée, lien symbolique, liste calculée au démarrage ==="
FERME="$(for u in /_vf/ /_vf//moteur.js /_vf/../serve.mjs /_vf/ui/../moteur.js /_vf/%2e%2e/serve.mjs '/_vf/moteur.js%00' /_vf/MOTEUR.js /_vf/ui/ "/_vf/$(printf 'a%.0s' $(seq 1 4096))"; do rq GET "$u" "$WORK/x.out"; printf '%s ' "$RQ_CODE"; done)"
assert_eq "K2.3 — table fermée : /_vf/, //, .., ui/.., %2e%2e, NUL, majuscules, ui/, 4 Kio → 404 chacun" "$FERME" "404 404 404 404 404 404 404 404 404 "
rq GET "/_vf/moteur.js?x=1" "$WORK/x.out"; Q1="$RQ_CODE"; rq POST /_vf/moteur.js "$WORK/x.out"
assert_eq "K2.3 — témoin positif : ?x=1 est ignoré (200) ; K2.4 — POST /_vf/moteur.js : 405" "$Q1|$RQ_CODE" "200|405"
# fichiers plantés dans la SORTIE, après le démarrage (E9, A40)
for f in plante.js plante.mjs serve.mjs vf-cockpit-server.mjs index.html.bak project.html.old; do printf 'window.__plante16 = 1; // MQ16-PLANTE\n' > "$OUT/$f"; done
cp "$OUT/graph.json" "$WORK/graph-copie.json"; ln -sf "$OUT/graph.json" "$OUT/lien-interne.json"; printf 'MQ16-CREDS\n' > "$WORK/creds-hors.txt"; ln -sf "$WORK/creds-hors.txt" "$OUT/creds.txt"
rq GET /_vf/plante.js "$WORK/x.out"; PA="$RQ_CODE"; rq GET /_vf/ui/plante.js "$WORK/x.out"
assert_eq "K2.6 — un plante.js posé dans la sortie : /_vf/plante.js et /_vf/ui/plante.js → 404" "$PA|$RQ_CODE" "404|404"
printf 'window.__ajout_apres = 1;\n' > "$ENG/assets/ui/zz-plante-ui-tmp.js"; rq GET /_vf/ui/zz-plante-ui-tmp.js "$WORK/x.out"; rm -f "$ENG/assets/ui/zz-plante-ui-tmp.js"
assert_eq "K2.6 — un fichier ajouté au ui/ du module APRÈS le démarrage : 404 (liste calculée au démarrage)" "$RQ_CODE" "404"

echo "=== K4 — E9 : un fichier planté dans la sortie n'est ni servi, ni lu, ni exécuté ==="
assert_eq "K4.0 — témoin de présence : le marqueur et le script planté sont bien dans la sortie" "$(node "$OR" marque "$OUT/plante.js" MQ16-PLANTE)" "oui"
sed 's|</body>|<script>window.__plante16 = 1</script></body>|' "$WORK/doc-p.html" > "$OUT/project.html"; cp "$OUT/project.html" "$OUT/index.html"
assert_eq "K4.1 — ni le document, ni le manifeste, ni un fichier de /_vf/ ne contient le marqueur planté" "$(node "$OR" contient "$PORT" "$WORK/doc-p.html" MQ16-PLANTE __plante16)" ""
assert_eq "K4.2 — /plante.js, /plante.mjs, /serve.mjs, /vf-cockpit-server.mjs, /index.html.bak, /project.html.old : 404" "$(for u in /plante.js /plante.mjs /serve.mjs /vf-cockpit-server.mjs /index.html.bak /project.html.old; do rq GET "$u" "$WORK/x.out"; printf '%s ' "$RQ_CODE"; done)" "404 404 404 404 404 404 "
rq GET /project.html "$WORK/doc-p2.html"
assert_eq "K4.2 — /project.html servi après la plantation ne contient pas le script planté" "$(node "$OR" marque "$WORK/doc-p2.html" __plante16)" "non"

echo "=== K5 — le service statique de la sortie est retiré (A41) ==="
K5="$(for u in /graph.json /projet.json /recent-work.json /architecture.json /custom-flows.json /LICENSE /LICENCES-TIERCES.txt /lien-interne.json /creds.txt /.cache/server.json; do rq GET "$u" "$WORK/x.out"; a="$RQ_CODE"; rq GET "$u" "$WORK/x.out" --jeton "$TOKP"; printf '%s/%s ' "$a" "$RQ_CODE"; done)"
assert_eq "K5.1 — /graph.json, /projet.json, /recent-work.json, /architecture.json, /custom-flows.json, licences, lien interne, lien sortant, .cache/server.json : 404 sans jeton comme avec" "$K5" "$(printf '404/404 %.0s' $(seq 1 10))"
assert_eq "K5.1 — témoin de présence : graph.json, le lien interne et le fichier visé par le lien sortant existent sur disque" "$([ -s "$OUT/graph.json" ] && [ -e "$OUT/lien-interne.json" ] && [ -s "$WORK/creds-hors.txt" ] && echo oui || echo non)" "oui"
assert_eq "K5.2 — ni le remote du dépôt, ni le chemin du lab, ni un jeton dans le document ou un fichier de /_vf/ (ils sont dans graph.json, K0.2)" "$(node "$OR" contient "$PORT" "$WORK/doc-p.html" MQ16-REMOTE "$LAB" "$TOKC" "$TOKP" | sed 's/^document$//;s/,document//;s/document,//')" ""

echo "=== K3 (suite) — la source du préfixe suit l'hôte validé ==="
rq GET /project.html "$WORK/x.out" --host "localhost:$PORT"; HL="$(hv content-security-policy)"
assert_eq "K3.2 — Host: localhost:<port> : la source est http://localhost:<port>/_vf/ ; script-src sans 'self', 'unsafe-, *, blob:, data:" "$(printf '%s' "$HL" | sed -n "s|.*script-src \([^;]*\);.*|\1|p" | tr ' ' '\n' | grep -v "^'sha256-" | tr '\n' ' ')|$(printf '%s' "$HL" | sed -n 's|.*script-src \([^;]*\);.*|\1|p' | grep -c "'self'\|unsafe-\|\*\|blob:\|data:")" "http://localhost:$PORT/_vf/ |0"

echo "=== C1 — l'onglet Projet rendu dans le navigateur depuis le document ==="
if [ -z "$CHROME" ]; then . "$TESTS/chrome-saut.sh"; vf_chrome_saut "  ⊘ C SAUTÉ : aucun navigateur (Chrome, Chromium) — la moitié navigateur de la coquille NON vérifiée"
else
  rq GET "/api/vf/graphe?onglet=projet" "$WORK/route-p.json" --jeton "$(node "$OR" jetons "$WORK/doc-p.html" | oj 'j.token')"
  NP="$(oj 'j.nodes.length' < "$WORK/route-p.json")"
  chrome charger "http://127.0.0.1:$PORT/project.html" "http://127.0.0.1:$PORT/project.html" > "$WORK/c1.json"
  assert_eq "C1.1 — le moteur est rendu depuis le document : vfTab project, mise en page posée, autant de nœuds que la route" "$(oj '[j.res?.[0]?.tab,j.res?.[0]?.layout,j.res?.[0]?.noeuds]' < "$WORK/c1.json")" "[\"project\",true,$NP]"
  assert_eq "C1.2 — aucune violation de CSP, aucune erreur de page, onglet() = projet, data-vf-pret = oui" "$(oj '[j.res?.[0]?.violations.length,j.res?.[0]?.erreursPage.length,j.res?.[0]?.onglet,j.res?.[0]?.pret]' < "$WORK/c1.json")" "[0,0,\"projet\",\"oui\"]"
  assert_eq "C1.3 — au second chargement, au moins un fichier de /_vf/ est revalidé en 304" "$(oj 'j.res?.[1]?.reponses.some((r)=>r.statut===304)' < "$WORK/c1.json")" "true"
fi

Q="$(printf '\047')"  # apostrophe : les expressions sed des mutants la portent
cat > "$AUX/lien-sortie.mjs" <<'JS'
// lien-sortie.mjs <serve.mjs> <sortie> : lance le serveur sur une sortie donnée par un chemin non réel ; « refus » (sortie 1, message) ou « demarre » (tué après 8 s)
import { spawn } from 'node:child_process';
const [, , serve, sortie] = process.argv;
const c = spawn(process.execPath, [serve, '--no-open', '--port', '0', `--sortie=${sortie}`], { stdio: ['ignore', 'ignore', 'pipe'] });
let err = ''; c.stderr.on('data', (d) => { err += d; });
const t = setTimeout(() => { c.kill('SIGKILL'); console.log('demarre'); }, 8000);
c.on('exit', (code) => { clearTimeout(t); console.log(code === 1 && /chemin r/.test(err) ? 'refus' : `autre ${code}`); });
JS
# état de départ de la boucle de serveurs : serveur de base (module du dépôt) sur le lab
base_srv() { cockpit_arreter; unset COCKPIT_MODULE; demarrer "$LAB"; }
v_service() { local u r=""; for u in /graph.json /lien-interne.json /plante.js /creds.txt /.cache/server.json; do rq GET "$u" "$WORK/x.out"; r="$r$RQ_CODE "; done; printf '%s' "$r"; }
v_csp() { rq GET /project.html "$WORK/x.out"; printf '%s' "$(hv content-security-policy)" | sed -n 's|.*script-src \([^;]*\);.*|\1|p' | grep -c "'self'\|unsafe-\|\*\|blob:\|data:" | sed 's/^0$/propre/;s/^[1-9].*$/interdit/'; }

echo "=== A37 — les gardes de chemin jugent la résolution physique, jamais la forme écrite ==="
node "$TESTS/coquille-propriete.mjs" gardes "$SCRIPTS" "$WORK/a37" > "$WORK/a37.json" 2>"$WORK/a37.err"
assert_eq "A37.1 — moduleAdmis : le verdict égale celui du noyau (realpath natif) pour neuf dispositions de liens (intérieur, chaîne, extérieur, pendant, boucle, sain, deux orthographes)" "$(oj 'Object.entries(j.cas).filter(([,c])=>!c.ok).map(([n])=>n).join(",")||"tous"' < "$WORK/a37.json")" "tous"
assert_eq "A37.2 — identité du serveur : deux orthographes d'un même lab = une identité ; un lab préfixe d'un autre = deux identités ; une sortie pendante n'a pas d'identité" "$(oj '[j.identites.memeLab,j.identites.prefixe,j.identites.pendante]' < "$WORK/a37.json")" "[true,true,true]"
assert_eq "A37.3 — couverture : au moins quatre refus et trois accords parmi les dispositions (la propriété n'est pas vide)" "$(oj '[Object.values(j.cas).filter(c=>c.oracle==="refus").length>=4,Object.values(j.cas).filter(c=>c.oracle==="accord").length>=3]' < "$WORK/a37.json")" "[true,true]"
ln -sfn "$OUT" "$WORK/lien-sortie"
assert_eq "A37.4 — serve.mjs --sortie= donné par un chemin qui traverse un lien : refus (code 1, message)" "$(node "$AUX/lien-sortie.mjs" "$ENG/assets/serve.mjs" "$WORK/lien-sortie")" "refus"
mut_a37() { # <nom> <sed> : le modèle de jugement muté, rejoué sur les mêmes dispositions
  cockpit_module_muter "$1" vf-cockpit-module.mjs "$2" || return 1
  rm -rf "$WORK/a37m"; node "$TESTS/coquille-propriete.mjs" gardes "$COCKPIT_MODULE/scripts" "$WORK/a37m" 2>/dev/null | oj 'Object.entries(j.cas).filter(([,c])=>!c.ok).map(([n])=>n).join(",")||"tous"'
}
assert_eq "M-LEXICAL — moduleAdmis jugeant des chemins normalisés : rougit A37.1 sur les liens vers l'intérieur et vers l'extérieur (jamais sur les cas sains)" "$(mut_a37 lexical 's|const r = cheminPhysique(d); // garde:coquille-chemin|const r = path.resolve(d);|')" "lien-vers-interieur,chaine-de-deux,lien-vers-exterieur"
assert_eq "M-ECHEC-OUVERT — un échec de résolution vaut accord : rougit A37.1 sur le lien pendant et la boucle" "$(mut_a37 ouvert 's|if (r === null) throw refus(.dossier du module introuvable : refus.); // garde:coquille-echec|if (r === null) continue;|')" "pendant,boucle"

echo "=== K6 — le module servi est celui que cockpit_lancer démarre (A48, point 41) ==="
rq GET /_vf/ui/25-recent.js "$WORK/k6-base.js"; E0="$(hv etag)"
cockpit_arreter
if cockpit_module_muter k6 ui/25-recent.js '1s|^|/* MQ16-MUTANT */ |'; then
  MUT6="$COCKPIT_MODULE"; demarrer "$LAB"; rq GET /_vf/ui/25-recent.js "$WORK/k6-mut.js"; E1="$(hv etag)"
  assert_eq "K6.1 — le ui/*.js muté dans la copie est celui servi sous /_vf/ (contenu et étiquette changés)" "$(node "$OR" marque "$WORK/k6-mut.js" MQ16-MUTANT)|$([ "$E0" != "$E1" ] && [ -n "$E1" ] && echo diff || echo meme)" "oui|diff"
  assert_eq "K6.1 — témoin : le module d'origine ne porte pas la mutation, la copie diffère par cmp" "$(node "$OR" marque "$ENG/assets/ui/25-recent.js" MQ16-MUTANT)|$(node "$OR" marque "$WORK/k6-base.js" MQ16-MUTANT)|$(cmp -s "$ENG/assets/ui/25-recent.js" "$MUT6/skills/cockpit-moteur/assets/ui/25-recent.js" && echo egal || echo diff)" "non|non|diff"
else assert_eq "K6.1 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

echo "=== K2 (liens et liste) — un lien hors du moteur refuse le démarrage ; un fichier ajouté avant le démarrage entre dans la liste ==="
cockpit_arreter; unset COCKPIT_MODULE
CP="$(cockpit_module_copie)"; printf 'hors\n' > "$WORK/hors.js"; ln -sf "$WORK/hors.js" "$CP/skills/cockpit-moteur/assets/ui/05-theme.js"
COCKPIT_MODULE="$CP" COCKPIT_LOG="$WORK/lien.log" demarrer "$LAB"; K25="$RL|$(grep -c 'dossier des assets du moteur' "$WORK/lien.log")|$PORT"
assert_eq "K2.5 — un fichier d'asset relié à un fichier hors du moteur : le serveur refuse de démarrer (code 1, message français, rien n'écoute)" "$K25" "1|1|0"
CP2="$(cockpit_module_copie)"; ln -sf ../graph-query.js "$CP2/skills/cockpit-moteur/assets/ui/05-theme.js"
COCKPIT_MODULE="$CP2" demarrer "$LAB"; rq GET /_vf/ui/05-theme.js "$WORK/x.out"
assert_eq "K2.5 — témoin positif : un lien dont la cible reste sous le dossier des assets est accepté et servi" "$RL|$RQ_CODE" "0|200"
cockpit_arreter
CP3="$(cockpit_module_copie)"; printf 'window.__avant16 = 1;\n' > "$CP3/skills/cockpit-moteur/assets/ui/zz-vf-plante-avant.js"
base_srv; rq GET /project.html "$WORK/x.out"; CSPB="$(hv content-security-policy | sed "s/'sha256-[^']*'//g; s/:$PORT/:PORT/g; s/  */ /g")"; cockpit_arreter
COCKPIT_MODULE="$CP3" demarrer "$LAB"; rq GET /project.html "$WORK/doc-c3.html"; CSP3="$(hv content-security-policy | sed "s/'sha256-[^']*'//g; s/:$PORT/:PORT/g; s/  */ /g")"; rq GET /_vf/ui/zz-vf-plante-avant.js "$WORK/x.out"
assert_eq "K2.6 — le même nom ajouté AVANT le démarrage est servi (200), nommé au manifeste, sans que la CSP change (hors empreintes et port)" "$RQ_CODE|$(node "$OR" manifeste "$WORK/doc-c3.html" | oj 'j.noms.includes("ui/zz-vf-plante-avant.js")')|$([ "$CSP3" = "$CSPB" ] && echo meme || echo diff)" "200|true|meme"
cockpit_arreter

echo "=== M-MARQUEUR — un marqueur de gabarit absent : le serveur refuse de démarrer et le nomme ==="
if cockpit_module_muter marq viewer.html 's|/\*__FONTS__\*/||'; then
  COCKPIT_LOG="$WORK/marq.log" demarrer "$LAB"
  assert_eq "M-MARQUEUR — viewer.html sans __FONTS__ : démarrage refusé (code 1), message qui nomme le marqueur" "$RL|$(grep -c '__FONTS__' "$WORK/marq.log")" "1|1"
else assert_eq "M-MARQUEUR — mutant sans effet" "sans effet" "effet"; fi
unset COCKPIT_MODULE

echo "=== K4.3, K4.4, K5.3 — les deux couches de l'E9, chacune avec son mutant ==="
cat > "$AUX/planter.js" <<'JS'
// echec: false
const ins = await s.ev(`new Promise((ok) => { const x = document.createElement('script'); x.src = '/plante.js'; x.onload = () => ok('charge'); x.onerror = () => ok('refuse'); document.head.appendChild(x); })`);
await pause(300);
return { insere: ins, plante: await s.ev('typeof window.__plante16'), violations: s.violations.length };
JS
if [ -n "$CHROME" ]; then
  base_srv; chrome avec "http://127.0.0.1:$PORT/project.html" "$AUX/planter.js" > "$WORK/k43.json"
  assert_eq "K4.3 — /project.html : window.__plante16 indéfini et le script inséré par la page est refusé par la CSP (une violation), le service ne le sert pas" "$(oj '[j.plante,j.violations>0]' < "$WORK/k43.json")" "[\"undefined\",true]"
fi
base_srv; BASE_SERVICE="$(v_service)"; BASE_CSP="$(v_csp)"
assert_eq "K5.3 — témoin : le serveur de base ne sert rien de la sortie et sa CSP est propre" "$BASE_SERVICE|$BASE_CSP" "404 404 404 404 404 |propre"
cockpit_arreter
NAIF="if (!path.relative(here, path.join(here, decodeURIComponent(url.pathname))).split(path.sep).some((x) => x.startsWith('.'))) { let r = ''; try { r = fs.realpathSync(path.join(here, decodeURIComponent(url.pathname))); } catch {} if (r.startsWith(here + path.sep)) { res.writeHead(200, { 'Content-Type': 'text/javascript' }); return fs.createReadStream(r).pipe(res); } } res.writeHead(404); return res.end(); // garde:coquille-404"
if cockpit_module_muter service serve.mjs "s|res.writeHead(404); return res.end(); // garde:coquille-404|$NAIF|"; then
  MS="$COCKPIT_MODULE"; demarrer "$LAB"
  assert_eq "M-SERVICE — service de la sortie rétabli : K5.1 rougit pour /graph.json, le lien interne et /plante.js (200), pas pour le lien sortant ni .cache/" "$(v_service)" "200 200 200 404 404 "
  rq GET /project.html "$WORK/x.out"; assert_eq "M-SERVICE — témoin positif : /project.html répond 200 dans le même serveur muté" "$RQ_CODE" "200"
  if [ -n "$CHROME" ]; then chrome avec "http://127.0.0.1:$PORT/project.html" "$AUX/planter.js" > "$WORK/k44.json"
    assert_eq "K4.4 — service ouvert (200 sur /plante.js), la CSP seule suffit : le script inséré est refusé, __plante16 indéfini (couche CSP)" "$(oj '[j.plante,j.violations>0]' < "$WORK/k44.json")" "[\"undefined\",true]"; fi
  cockpit_arreter
  sed -i.avant "s|\${PREFIXE}\`; // garde:coquille-source|\${PREFIXE} ${Q}self${Q}\`; // garde:coquille-source|" "$MS/scripts/vf-cockpit-coquille.mjs"
  if ! cmp -s "$MS/scripts/vf-cockpit-coquille.mjs.avant" "$MS/scripts/vf-cockpit-coquille.mjs"; then
    COCKPIT_MODULE="$MS" demarrer "$LAB"
    assert_eq "M-CSP-SELF — la source 'self' ajoutée : K3.2 rougit (script-src porte 'self')" "$(v_csp)" "interdit"
    if [ -n "$CHROME" ]; then chrome avec "http://127.0.0.1:$PORT/project.html" "$AUX/planter.js" > "$WORK/k44s.json"
      assert_eq "M-CSP-SELF — service ouvert ET 'self' : K4.4 rougit, le marqueur s'exécute (la CSP est bien la seconde couche)" "$(oj 'j.plante' < "$WORK/k44s.json")" "number"; fi
    cockpit_arreter
  else assert_eq "M-CSP-SELF — mutant sans effet (ancre absente)" "sans effet" "effet"; fi
else assert_eq "M-SERVICE — mutant sans effet (ancre garde:coquille-404 absente ou inchangée)" "sans effet" "effet"; fi
unset COCKPIT_MODULE

# FIN
cockpit_arreter
vf_hyg_assert
echo ""; echo "=================================="
echo "  Résultats : $PASS PASS / $FAIL FAIL"
echo "=================================="
TOTAL=$((PASS+FAIL))
if [ "$TOTAL" -eq 0 ]; then echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée, résultat non fiable"; exit 1; fi
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
