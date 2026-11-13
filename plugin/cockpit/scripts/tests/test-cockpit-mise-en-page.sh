#!/usr/bin/env bash
# test-cockpit-mise-en-page.sh — la mise en page du canevas (ELK) dans un worker servi par le module (79-18, SOCL-22 ; C5, A4, A30, A40 ; P79-D-15).
#   W0 témoins · W1 le fichier du worker servi (table fermée, ETag, CSP propre) · W2 la CSP de page (worker-src au préfixe) · W3 le worker a vraiment servi
#   W4 le fil principal reste libre (pouls, tâche longue, clic) · W6 l'API du moteur est inchangée (A4)
# Un Chrome par mesure (mise-en-page-chrome.mjs), sonde posée avant tout script de la page. Sans navigateur : saut déclaré (rouge en CI), jamais un vert à vide.
# Lab neutre dans mktemp, HOME jetable, isolation git. Le code testé est celui du dossier de cette suite. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_NAMESPACE GIT_CEILING_DIRECTORIES
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
TESTS="$SCRIPTS/tests"; MOD="$(cd "$SCRIPTS/.." && pwd -P)"; ENG="$MOD/skills/cockpit-moteur"
CHROME=""; for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do [ -n "$c" ] || continue; if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi; done
if [ -z "$CHROME" ]; then . "$TESTS/chrome-saut.sh"; vf_chrome_saut "  ⊘ SUITE SAUTÉE : aucun navigateur (Chrome, Chromium) — la mise en page en worker NON vérifiée, non comptée comme réussie"; exit 0; fi
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude"
export REAL_HOME; REAL_HOME="$(node -e 'console.log(require("os").userInfo().homedir)')"; export HOME="$WORK/home"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$TESTS/hygiene.sh"; vf_hyg_init
. "$TESTS/socle-serveur.sh"
PASS=0; FAIL=0
assert_eq() { if [ "$#" -ne 3 ]; then echo "  ❌ FAIL — $1 (assert_eq a reçu $# arguments au lieu de 3)"; FAIL=$((FAIL+1)); elif [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [${3:0:300}]"; echo "     obtenu:  [${2:0:600}]"; FAIL=$((FAIL+1)); fi; }
TA="$TESTS/terminal-aux.mjs"; OR="$TESTS/coquille-oracle.mjs"; CH="$TESTS/mise-en-page-chrome.mjs"
oj() { node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{let j;try{j=JSON.parse(s)}catch{console.log("illisible");return}if(j&&j.erreur){console.log("mesure indisponible : "+j.erreur);return}const v=new Function("j","return ("+process.argv[1]+")")(j);console.log(typeof v==="string"?v:JSON.stringify(v))})' "$1"; }
rq() { # rq <METHODE> <chemin> <fichier-corps> [options de terminal-aux req] -> RQ_CODE, RQ_H (en-têtes JSON)
  local m="$1" p="$2" f="$3"; shift 3
  node "$TA" req "${PORT:-0}" "$m" "$p" --corps-vers "$f" "$@" > "$WORK/rq.out" 2>&1
  RQ_CODE="$(sed -n 1p "$WORK/rq.out")"; RQ_H="$(sed -n 2p "$WORK/rq.out")"
}
hv() { printf '%s' "$RQ_H" | oj "j[\"$1\"]||\"\""; } # un en-tête de la dernière réponse (nom en minuscules)
chrome() { MEP_LAB="${LAB:-}" node "$CH" "$CHROME" "http://127.0.0.1:$PORT" "$@"; } # chrome <mode> [argument] : une ligne JSON
mklab() { # 90 modules qui s'importent entre voisins dans un même dossier (un niveau de 90 cartes à arêtes), une phase, un titre qui porte le marqueur du lab
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$L/plugin/mod/scripts" "$B/phases/01-socle" "$L/lots"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"
  printf '{"name":"mod","type":"skill","description":"Un module de test."}\n' > "$L/plugin/mod/module.json"; echo 1.0.0 > "$L/plugin/mod/VERSION"
  printf '# Module\n\nLancer `run.sh`.\n' > "$L/plugin/mod/README.md"; printf '#!/usr/bin/env bash\necho run\n' > "$L/plugin/mod/scripts/run.sh"
  for i in $(seq 1 90); do # des imports entre voisins : le niveau a des arêtes, donc un calcul de mise en page qui se mesure
    { printf '// MQ18-LAB module %s\n' "$i"; for d in 1 13; do printf "import './m%02d.js';\n" $(( (i + d - 1) % 90 + 1 )); done; printf 'export const v = %s;\n' "$i"; } > "$L/lots/m$(printf %02d "$i").js"
  done
  printf '# MQ18-LAB titre du projet\n' > "$B/PROJECT.md"
  printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Depends on**: Nothing (first phase)\n' > "$B/ROADMAP.md"
  printf -- '---\nfiles_modified: [plugin/mod/README.md]\n---\n<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"; echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
}
demarrer() { cockpit_lancer "$@"; RL=$?; PORT="${VF_PORT:-0}"; }

echo "=== W0 — témoins : serveur, fixture de 90 cartes, sonde, fenêtre de calcul ==="
LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"
demarrer "$LAB"
assert_eq "W0.1 — témoin : le serveur est prêt" "$RL|$([ "$PORT" -gt 0 ] && echo oui || echo non)" "0|oui"
TR="$(chrome tracer)"; [ -n "${KEEP:-}" ] && printf '%s\n' "$TR" > "$WORK/tracer.json"
assert_eq "W0.2 — témoin : le niveau « lots » compte au moins 90 cartes pour le moteur et la dernière note est dans la sortie assemblée" "$(printf '%s' "$TR" | oj 'j.worker.noeuds >= 90 && j.worker.vus >= 90 && j.ligne.noeuds >= 90')|$(grep -c 'lots/m90.js' "$OUT/graph.json" | sed 's/^[1-9].*/oui/')" "true|oui"
assert_eq "W0.3 — témoin : la sonde est vivante (posée avant le moteur : aucun VibeFlow à son installation ; pouls relevé, balayage disponible)" "$(printf '%s' "$TR" | oj '[j.ligne.avant, j.ligne.vivante, j.worker.avant, j.worker.vivante]')" '["undefined",true,"undefined",true]'
assert_eq "W0.4 — témoin de couverture : la fenêtre de calcul du niveau « lots » dure au moins 400 ms en mode en ligne puis en mode worker (sinon la fixture est trop légère)" "$(printf '%s' "$TR" | oj '[j.ligne.mode, j.ligne.duree >= 400, j.worker.mode, j.worker.duree >= 400]')" '["ligne",true,"worker",true]'

echo "=== W1 — le fichier du worker : table fermée, étiquette forte, CSP propre ==="
rq GET /_vf/elk-fil.js "$WORK/fil.out"; C1="$RQ_CODE"; CT="$(hv content-type)"; ET="$(hv etag)"; CC="$(hv cache-control)"; CS1="$(hv content-security-policy)"
SH="\"$(shasum -a 256 "$WORK/fil.out" | cut -c1-16)\""
assert_eq "W1.1 — GET /_vf/elk-fil.js : 200, JavaScript, ETag de 18 caractères égal au sha256 des octets reçus, no-cache" "$C1|$CT|${#ET}|$([ "$ET" = "$SH" ] && echo egal || echo "$ET")|$CC" "200|text/javascript; charset=utf-8|18|egal|no-cache"
assert_eq "W1.2 — sa CSP propre est exactement : rien par défaut, un seul script admis (le paquet ELK du module, URL exacte)" "$CS1" "default-src 'none'; script-src http://127.0.0.1:$PORT/_vf/vendor/elk.bundled.js"
rq GET /_vf/elk-fil.js "$WORK/fil2.out" --host "localhost:$PORT"
assert_eq "W1.3 — idem pour Host: localhost:<port>, avec ce nom d'hôte" "$(hv content-security-policy)" "default-src 'none'; script-src http://localhost:$PORT/_vf/vendor/elk.bundled.js"
assert_eq "W1.4 — une autre casse, une barre finale, un octet nul, un retour de dossier, un sous-dossier : 404 (table fermée)" "$(for u in /_vf/ELK-FIL.js /_vf/elk-fil.js/ '/_vf/elk-fil.js%00' /_vf/../elk-fil.js /_vf/ui/elk-fil.js; do rq GET "$u" "$WORK/x.out"; printf '%s ' "$RQ_CODE"; done)" "404 404 404 404 404 "
assert_eq "W1.5 — les octets servis sont ceux du fichier du module" "$(cmp -s "$WORK/fil.out" "$ENG/assets/elk-fil.js" && echo egaux || echo differents)" "egaux"
rq POST /_vf/elk-fil.js "$WORK/x.out"; P1="$RQ_CODE"; rq GET /_vf/elk-fil.js "$WORK/x.out" --entete sec-fetch-site:cross-site
assert_eq "W1.6 — POST : 405 ; Sec-Fetch-Site: cross-site : 403" "$P1|$RQ_CODE" "405|403"

echo "=== W2 — la CSP de page : une seule directive de plus, worker-src au préfixe du module ==="
W2A=""; W2B=""; W2C=""
for H in "127.0.0.1:$PORT" "localhost:$PORT"; do
  for U in / /index.html /project.html /equipe.html; do
    rq GET "$U" "$WORK/doc.html" --host "$H"; CSP="$(hv content-security-policy)"
    W2A="$W2A$(printf '%s' "$CSP" | tr ';' '\n' | sed 's/^ //' | grep -c '^worker-src ') $(printf '%s' "$CSP" | tr ';' '\n' | sed 's/^ //' | grep '^worker-src ' | sed "s|^worker-src http://$H/_vf/\$|exact|") "
    W2B="$W2B$([ "$CSP" = "$(node "$TA" csp-v275 "$WORK/doc.html" "http://$H/_vf/")" ] && echo egale || echo differente) "
    node "$OR" csp "$WORK/doc.html" "$CSP" "http://$H/_vf/" > "$WORK/csp.json"; W2C="$W2C$(oj '[j.egales,JSON.stringify(j.autres)].join("|")' < "$WORK/csp.json" | sed "s|\\[\"http://$H/_vf/\"\\]|prefixe|") "
  done
done
assert_eq "W2.1 — quatre adresses, deux noms d'hôte (huit réponses) : une directive worker-src, égale à http://<hôte>/_vf/ (ni source d'origine, ni adresse d'objet local, ni data:)" "$W2A" "$(for i in 1 2 3 4 5 6 7 8; do printf '1 exact '; done)"
assert_eq "W2.2 — oracle indépendant : la chaîne entière égale celle de la formule de terminal-aux sur les scripts en ligne du corps servi (huit réponses)" "$W2B" "$(for i in 1 2 3 4 5 6 7 8; do printf 'egale '; done)"
assert_eq "W2.3 — script-src reste celui de 79-16 : les empreintes des scripts en ligne plus une seule source, le préfixe (huit réponses)" "$W2C" "$(for i in 1 2 3 4 5 6 7 8; do printf 'true|prefixe '; done)"

echo "=== W3 — le worker a vraiment servi le calcul (témoin positif avant toute mesure de blocage) ==="
assert_eq "W3.1 — un Worker est construit, de même origine, au chemin /_vf/elk-fil.js" "$(printf '%s' "$TR" | oj "(() => { const u = new URL(j.worker.resume.urls[0] || 'x:', 'http://127.0.0.1:$PORT/'); return [j.worker.resume.construits, u.origin === 'http://127.0.0.1:$PORT', u.pathname]; })()")" '[1,true,"/_vf/elk-fil.js"]'
assert_eq "W3.2 — au moins une requête de calcul est envoyée au worker et répondue par lui" "$(printf '%s' "$TR" | oj '[j.worker.resume.req >= 1, j.worker.resume.rep >= 1]')" "[true,true]"
assert_eq "W3.3 — aucune violation de CSP, aucune erreur de page ou de console, aucun avertissement de repli" "$(printf '%s' "$TR" | oj '[j.worker.violations.length, j.worker.resume.erreurs.length, j.worker.resume.avert.length]')" "[0,0,0]"
assert_eq "W3.4 — aucun calcul n'a eu lieu sur le fil principal" "$(printf '%s' "$TR" | oj 'j.worker.resume.enLigne')" "0"

echo "=== W4 — le fil principal reste libre pendant le calcul d'un niveau de 90 cartes ==="
assert_eq "W4.0 — témoin de pouvoir : en mode en ligne (Worker retiré avant tout script) le plus grand écart de pouls dans la fenêtre dépasse 400 ms" "$(printf '%s' "$TR" | oj 'j.ligne.ecart > 400')" "true"
assert_eq "W4.1 — en mode worker, le plus grand écart d'un pouls de 10 ms dans la fenêtre est inférieur à 150 ms" "$(printf '%s' "$TR" | oj 'j.worker.ecart < 150')" "true"
assert_eq "W4.2 — … et la plus longue tâche du fil principal est inférieure à 200 ms" "$(printf '%s' "$TR" | oj 'j.worker.tache < 200')" "true"
assert_eq "W4.3 — un clic réel envoyé pendant la fenêtre est traité (après l'envoi, avant la réponse) avec un retard inférieur à 100 ms" "$(printf '%s' "$TR" | oj '(() => { const c = j.worker.clics.filter((x) => x.traite >= j.worker.envoye && x.traite <= j.worker.fin); return [c.length >= 1, c.length > 0 && c.every((x) => x.retard < 100)]; })()')" "[true,true]"

echo "=== W6 — l'API du moteur ne change pas d'une clé (A4) ==="
CLES='["addAskContext","addHeaderButton","addPanelSection","agent","ask","askEngine","canChange","chain","children","closeMenus","closePanel","colorOf","copy","draftChange","exists","exported","files","fit","fmt","freeArea","go","graph","h","icon","iconI","iconKey","icons","info","md","modal","nodes","on","open","parentOf","playFlow","plural","query","refreshPanel","render","rerender","reveal","routes","select","setOverview","setTechnical","showBoard","showPanel","shownName","startFlow","state","stopFlow","store","technical","toast","up","version"]' # les clés de l'objet gelé du moteur, relevées à l'ouverture de la phase (A4)
assert_eq "W6.1 — à la réception de render : state.layout.children non vide, id/x/y/width/height finis, ids = cartes affichées" "$(printf '%s' "$TR" | oj '(() => { const r = j.worker.rendus; return !!r && r.ids.length > 0 && r.pos.every((p) => p.slice(1).every(Number.isFinite)) && JSON.stringify(r.ids) === JSON.stringify(r.vus); })()')" "true"
assert_eq "W6.2 — freeArea() rend { x, y, w, h } finis" "$(printf '%s' "$TR" | oj '(() => { const f = j.worker.rendus && j.worker.rendus.fa; return !!f && ["x", "y", "w", "h"].every((k) => Number.isFinite(f[k])); })()')" "true"
assert_eq "W6.3 — les positions de state.layout sont celles de la dernière réponse du worker : la pose vient du worker" "$(printf '%s' "$TR" | oj '(() => { const r = j.worker.rendus; return !!r && !!r.derniere && JSON.stringify([...r.pos].sort()) === JSON.stringify([...r.derniere].sort()); })()')" "true"
assert_eq "W6.4 — window.VibeFlow est gelé et ses clés sont celles relevées à l'ouverture" "$(printf '%s' "$TR" | oj '[j.worker.gele, JSON.stringify(j.worker.cles)]')" "[true,$(printf '%s' "$CLES" | node -e 'console.log(JSON.stringify(require("fs").readFileSync(0,"utf8")))')]"

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
