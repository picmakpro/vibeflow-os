#!/usr/bin/env bash
# test-cockpit-mise-en-page.sh — la mise en page du canevas (ELK) dans un worker servi par le module (79-18, SOCL-22 ; C5, A4, A30, A40 ; P79-D-15).
#   W0 témoins · W1 le fichier du worker servi (table fermée, ETag, CSP propre) · W2 la CSP de page (worker-src à l'URL exacte du fil) · W3 le worker a vraiment servi
#   W4 le fil principal reste libre (pouls, tâche longue, clic) · W5 le worker rend ce que rend le calcul en ligne (propriété à graine) · W6 l'API du moteur (A4)
#   W7 repli et export · W8 cycle de vie (propriété à graine) · W9 messages bornés · X mutants (copies du module : une garde, une raison)
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
chrome() { VF_CDP_ECHEANCE_MS="${VF_CDP_ECHEANCE_MS:-240000}" VF_CDP_GLOBAL_MS="${VF_CDP_GLOBAL_MS:-1500000}" MEP_LAB="${LAB:-}" node "$CH" "$CHROME" "http://127.0.0.1:$PORT" "$@"; } # chrome <mode> [argument] : une ligne JSON
# une session d'équipe (un manager, deux workers) : la page Équipe n'est servie que s'il y a de quoi la bâtir
cat > "$AUX/mk-agents.mjs" <<'JS'
import fs from 'node:fs'; import path from 'node:path';
const [, , home, lab, sid] = process.argv; const now = Date.now();
const dir = path.join(home, '.claude', 'projects', '-lab'); const sub = path.join(dir, sid, 'subagents'); fs.mkdirSync(sub, { recursive: true });
const iso = (ms) => new Date(ms).toISOString(); const base = (o) => ({ cwd: lab, sessionId: sid, gitBranch: 'main', version: '2.1.317', ...o });
const put = (f, lignes) => fs.writeFileSync(f, lignes.map((l) => JSON.stringify(l)).join('\n') + '\n');
put(path.join(dir, sid + '.jsonl'), [base({ type: 'user', timestamp: iso(now - 600000), message: { content: 'salut' } }), base({ type: 'assistant', timestamp: iso(now - 5000), message: { content: [{ type: 'tool_use', name: 'Bash', input: { command: 'echo bonjour' } }] } })]);
const agents = [{ id: 'mgr1', d: 1, role: 'vf-dev-manager' }, { id: 'act1', d: 2, parent: 'mgr1', role: 'vf-coder' }, { id: 'act2', d: 2, parent: 'mgr1', role: 'vf-coder' }];
for (const a of agents) {
  const meta = { agentType: a.role, isBuiltIn: false, launchedWithDefaults: false, description: 'tâche synthétique ' + a.id, toolUseId: 'toolu_' + a.id, spawnDepth: a.d, requestShape: 'background', requestNonInteractive: true };
  if (a.d >= 2) meta.parentAgentId = a.parent;
  fs.writeFileSync(path.join(sub, `agent-${a.id}.meta.json`), JSON.stringify(meta));
  put(path.join(sub, `agent-${a.id}.jsonl`), [base({ type: 'user', isSidechain: true, agentId: a.id, parentUuid: null, timestamp: iso(now - 300000), message: { role: 'user', content: 'mandat de ' + a.id } }), base({ type: 'assistant', isSidechain: true, agentId: a.id, timestamp: iso(now - 4000), message: { content: [{ type: 'tool_use', name: 'Read', input: { file_path: '/x' } }] } })]);
}
JS
mklab() { # 90 modules qui s'importent entre voisins dans un même dossier (un niveau de 90 cartes à arêtes), une phase, un titre qui porte le marqueur du lab
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$L/plugin/mod/scripts" "$B/phases/01-socle" "$L/lots"
  printf 'export const u = () => 1;\n' > "$L/src/util.js"
  printf '{"name":"mod","type":"skill","description":"Un module de test."}\n' > "$L/plugin/mod/module.json"; echo 1.0.0 > "$L/plugin/mod/VERSION"
  printf '# Module\n\nLancer `run.sh`.\n' > "$L/plugin/mod/README.md"; printf '#!/usr/bin/env bash\necho run\n' > "$L/plugin/mod/scripts/run.sh"
  for i in $(seq 1 90); do # des imports entre voisins : le niveau a des arêtes, donc un calcul de mise en page qui se mesure
    { printf '// MQ18-LAB module %s\n' "$i"; for d in 1 2 $([ $((i % 3)) -eq 0 ] && echo 3); do printf "import './m%02d.js';\n" $(( (i + d - 1) % 90 + 1 )); done; printf 'export const v = %s;\n' "$i"; } > "$L/lots/m$(printf %02d "$i").js"
  done
  printf '# MQ18-LAB titre du projet\n' > "$B/PROJECT.md"
  printf '# Roadmap\n\n## Jalon démo\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Depends on**: Nothing (first phase)\n' > "$B/ROADMAP.md"
  printf -- '---\nfiles_modified: [plugin/mod/README.md]\n---\n<objective>Faire le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"; echo ok > "$B/phases/01-socle/01-01-SUMMARY.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit-build.mjs" "$L" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
}
demarrer() { cockpit_lancer "$@"; RL=$?; PORT="${VF_PORT:-0}"; }

echo "=== W0 — témoins : serveur, fixture de 90 cartes, sonde, fenêtre de calcul ==="
LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"; node "$AUX/mk-agents.mjs" "$HOME" "$LAB" aaaa1111-2222-3333-4444-555555555555
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

echo "=== W2 — la CSP de page : une seule directive de plus, worker-src à l'URL exacte du fil ==="
W2A=""; W2B=""; W2C=""
for H in "127.0.0.1:$PORT" "localhost:$PORT"; do
  for U in / /index.html /project.html /equipe.html; do
    rq GET "$U" "$WORK/doc.html" --host "$H"; CSP="$(hv content-security-policy)"
    W2A="$W2A$(printf '%s' "$CSP" | tr ';' '\n' | sed 's/^ //' | grep -c '^worker-src ') $(printf '%s' "$CSP" | tr ';' '\n' | sed 's/^ //' | grep '^worker-src ' | sed "s|^worker-src http://$H/_vf/elk-fil.js\$|exact|") "
    W2B="$W2B$([ "$CSP" = "$(node "$TA" csp-v275 "$WORK/doc.html" "http://$H/_vf/")" ] && echo egale || echo differente) "
    node "$OR" csp "$WORK/doc.html" "$CSP" "http://$H/_vf/" > "$WORK/csp.json"; W2C="$W2C$(oj '[j.egales,JSON.stringify(j.autres)].join("|")' < "$WORK/csp.json" | sed "s|\\[\"http://$H/_vf/\"\\]|prefixe|") "
  done
done
assert_eq "W2.1 — quatre adresses, deux noms d'hôte (huit réponses) : une directive worker-src, égale à http://<hôte>/_vf/elk-fil.js, sans barre finale donc correspondance exacte (ni autre entrée de la table, ni préfixe, ni source d'origine, ni adresse d'objet local, ni data:)" "$W2A" "$(for i in 1 2 3 4 5 6 7 8; do printf '1 exact '; done)"
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

PR="$TESTS/mise-en-page-propriete.mjs"
prop() { MEP_LAB="$LAB" node "$PR" "$@" > "$WORK/prop.out" 2>&1; PG="$(sed -n 1p "$WORK/prop.out")"; PL="$(tail -n 1 "$WORK/prop.out")"; }
FRAIS="$(( (RANDOM % 9000) + 10 ))"; GRAINES="1 2 3 $FRAIS"
SEQ_ALL=""; SOMME_FUITES="$(printf '%s' "$TR" | oj 'j.worker.resume.fuites')"

echo "=== W5 — le worker rend ce que rend le calcul en ligne (propriété à graine) ==="
EQ="$(chrome equivalence)"; [ -n "${KEEP:-}" ] && printf '%s\n' "$EQ" > "$WORK/equivalence.json"
assert_eq "W5.1 — moteur entier, trois niveaux (code, lots, équipe) : positions des cartes et sections des arêtes égales entre le mode worker et le mode en ligne ; le mode worker a bien construit un worker, le mode en ligne aucun" "$(printf '%s' "$EQ" | oj 'Object.entries(j.niveaux).map(([k, v]) => k + ":" + (v.cartes > 0 && v.egalCartes && v.egalAretes && v.construitsWorker === 1 && v.construitsLigne === 0)).join(" ")')" "code:true lots:true equipe:true"
for G in $GRAINES; do
  prop graphes "$CHROME" "http://127.0.0.1:$PORT" "$G"
  echo "  $PG"
  assert_eq "W5.2 ($PG) — 40 graphes de classes nommées : le worker égale le paquet ELK du module appelé dans la même page, erreurs comprises (message égal)" "$(printf '%s' "$PL" | oj '[j.plantage, j.echecs.length, j.nombre]')" "[false,0,40]"
  assert_eq "W5.3 ($PG) — couverture comptée par le générateur : chacune des sept classes au moins 5 fois" "$(printf '%s' "$PL" | oj 'JSON.stringify(j.refuse) + "|" + Object.keys(j.couverture).length')" "[]|7"
done
prop temoin x graphes; assert_eq "W5.4 — témoin rouge : un générateur à classe unique est refusé par la vérification de couverture" "$(printf '%s' "$PL" | oj 'j.refuse')" "true"

echo "=== W7 — repli et export : le calcul en ligne quand il le faut, un texte quand ELK échoue ==="
RP="$(chrome repli sans)"
assert_eq "W7.1 — Worker retiré avant tout script : le canevas s'affiche (cartes, state.layout), aucun Worker construit, aucune erreur, aucun avertissement" "$(printf '%s' "$RP" | oj '[j.noeuds > 0, j.layout > 0, j.resume.construits, j.resume.erreurs.length, j.resume.avert.length, j.resume.enLigne >= 1]')" "[true,true,0,0,0,true]"
cockpit_exporter "$LAB" "$WORK/export.html" > "$WORK/export.out" 2>&1
EX="$(chrome export "$WORK/export.html")"
assert_eq "W7.2 — export autonome ouvert en file: : canevas affiché, zéro Worker, aucune violation ; témoin : la page est en file: et l'export ne contient ni elk-fil, ni worker-src, ni le préfixe /_vf/" "$(printf '%s' "$EX" | oj '[j.protocole, j.noeuds > 0, j.layout > 0, j.resume.construits, j.violations.length]')|$(for m in elk-fil worker-src /_vf/; do grep -c -F -- "$m" "$WORK/export.html"; done | tr '\n' ' ')" '["file:",true,true,0,0]|0 0 0 '
ER="$(chrome erreur)"
assert_eq "W7.4 — requête altérée en vol (arête vers un nœud inconnu portant un balisage) : l'élément d'erreur affiche le message en TEXTE (aucun élément enfant), la page reste vivante et un redessin non altéré réussit" "$(printf '%s' "$ER" | oj '[j.echec.texte.startsWith("Layout failed:"), j.echec.texte.includes("<b>MQ18-ECHEC"), j.echec.enfants, j.echec.balises, j.vivante]')" '[true,true,0,0,true]'
assert_eq "W7.5 — le texte d'erreur reçu du worker est une chaîne de 200 caractères au plus (témoin : l'identifiant altéré était plus long, donc tronqué à 200)" "$(printf '%s' "$ER" | oj '[j.resume.erreurMax <= 200, j.resume.erreurMax === 200]')" "[true,true]"

echo "=== W8 — cycle de vie : un seul worker, rien d'écrit par un onglet démonté, la même mise en page qu'à froid ==="
COUV='{"onglet":0,"redessin":0,"pendant":0,"vers_code":0,"vers_projet":0,"vers_equipe":0,"pendantEffectif":0}'
for G in $GRAINES; do
  prop sequences "$CHROME" "http://127.0.0.1:$PORT" "$G"
  echo "  $PG"
  assert_eq "W8.1 ($PG) — quatre suites d'opérations tirées : exactement un worker vivant après chaque opération, aucune erreur ni « Layout failed », mise en page égale à celle d'un chargement à froid" "$(printf '%s' "$PL" | oj '[j.plantage, j.echecs.length, JSON.stringify(j.parClasse)]')$(printf '%s' "$PL" | oj 'j.echecs.length ? JSON.stringify(j.echecs) : ""')" '[false,0,"{}"]'
  COUV="$(printf '%s' "$PL" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const c=JSON.parse(process.argv[1]),j=JSON.parse(s);for(const k in j.couverture)c[k]=(c[k]||0)+j.couverture[k];console.log(JSON.stringify(c))})' "$COUV")"
  FU="$(printf '%s' "$PL" | oj 'j.msgs.fuites')"; case "$FU" in ''|*[!0-9]*) FU=1 ;; esac # une mesure indisponible compte comme une fuite : jamais un vert à vide
  SOMME_FUITES=$((SOMME_FUITES + FU))
  SEQ_ALL="$SEQ_ALL$(printf '%s' "$PL" | oj 'JSON.stringify([j.msgs.reqTop, j.msgs.repTop, j.msgs.interdites, j.msgs.req])') "
done
assert_eq "W8.2 — couverture comptée sur l'ensemble des graines : chaque type d'opération, chaque onglet d'arrivée et au moins 3 changements pendant un calcul effectif, au moins 3 fois" "$(printf '%s' "$COUV" | oj 'Object.values(j).every((n) => n >= 3)')" "true"
prop temoin x sequences; assert_eq "W8.3 — témoin rouge : un générateur sans changement pendant un calcul est refusé" "$(printf '%s' "$PL" | oj 'j.refuse')" "true"
assert_eq "W8.4 — les jetons, le chemin du lab et le marqueur MQ18-LAB n'apparaissent dans aucun message du worker (suites, mesure du niveau lourd)" "$SOMME_FUITES" "0"
assert_eq "W8.5 — la sonde sait voir : un message de test qui porte le marqueur est détecté (témoin positif)" "$(printf '%s' "$TR" | oj 'j.worker.temoinFuite.fuites >= 1')" "true"

echo "=== W9 — le protocole est borné : { id, graphe } dans un sens, { id, resultat | erreur } dans l'autre ==="
assert_eq "W9.1 — clés des requêtes dans {id, graphe}, des réponses dans {id, resultat, erreur}, aucune des cinq clés interdites à aucune profondeur ; témoin : des messages ont bien été balayés" "$(printf '%s %s' "$SEQ_ALL" "$(printf '%s' "$TR" | oj 'JSON.stringify([j.worker.resume.reqTop, j.worker.resume.repTop, j.worker.resume.interdites, j.worker.resume.req])')" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const L=s.trim().split(/ (?=\[)/).map((x)=>JSON.parse(x));console.log(L.length>=5&&L.every(([q,r,i,n])=>n>0&&i===0&&q.every((k)=>["id","graphe"].includes(k))&&r.every((k)=>["id","resultat","erreur"].includes(k))))})')" "true"
assert_eq "W9.2 — témoin positif : une requête de test qui porte une clé interdite est signalée par le balayage" "$(printf '%s' "$TR" | oj 'j.worker.temoinCle.interdites >= 1')" "true"

echo "=== W10 — l'empreinte du module couvre le fil et son paquet : un serveur dont l'un des deux a changé est jugé périmé (AU18-02) ==="
emp() { node --input-type=module -e "const m=await import('file://$1/scripts/vf-cockpit-module.mjs');console.log(m.empreinteModule({dossierScripts:'$1/scripts',dossierMoteur:'$1/skills/cockpit-moteur'})||'nul')"; }
chg() { # chg <racine d'une copie du module> <fichier sous assets/> : l'empreinte avant et après un ajout au fichier -> « change » ou « <avant>/<après> »
  local a b; a="$(emp "$1")"; printf '\n// un octet de plus\n' >> "$1/skills/cockpit-moteur/assets/$2"; b="$(emp "$1")"
  if [[ "$a" =~ ^[0-9a-f]{12}$ && "$b" =~ ^[0-9a-f]{12}$ ]]; then [ "$a" != "$b" ] && echo change || echo identique; else echo "$a/$b"; fi
}
E1="$WORK/emp1"; cockpit_module_copie "$E1" > /dev/null; E2="$WORK/emp2"; cockpit_module_copie "$E2" > /dev/null
assert_eq "W10.1 — un octet de plus dans elk-fil.js change l'empreinte du module (deux empreintes de 12 hexadécimaux)" "$(chg "$E1" elk-fil.js)" "change"
assert_eq "W10.2 — un octet de plus dans vendor/elk.bundled.js (le paquet que le fil importe) change l'empreinte du module" "$(chg "$E2" vendor/elk.bundled.js)" "change"

echo "=== X — mutants : chaque garde rougit pour sa seule raison (copies du module, jamais le module du dépôt) ==="
verif_csp() { # l'état des gardes de CSP sur le serveur lancé : W1.2 W1.3 W2.1 W2.2 W2.3 (ok|ko)
  local r="" H U CSP e1 e2; rq GET /_vf/elk-fil.js "$WORK/x.out"; [ "$(hv content-security-policy)" = "default-src 'none'; script-src http://127.0.0.1:$PORT/_vf/vendor/elk.bundled.js" ] && r="$r W1.2=ok" || r="$r W1.2=ko"
  rq GET /_vf/elk-fil.js "$WORK/x.out" --host "localhost:$PORT"; [ "$(hv content-security-policy)" = "default-src 'none'; script-src http://localhost:$PORT/_vf/vendor/elk.bundled.js" ] && r="$r W1.3=ok" || r="$r W1.3=ko"
  e1=ok; e2=ok; local e3=ok
  for H in "127.0.0.1:$PORT" "localhost:$PORT"; do for U in / /index.html /project.html /equipe.html; do
    rq GET "$U" "$WORK/doc.html" --host "$H"; CSP="$(hv content-security-policy)"
    [ "$(printf '%s' "$CSP" | tr ';' '\n' | sed 's/^ //' | grep -c "^worker-src http://$H/_vf/elk-fil.js\$")" = 1 ] || e1=ko
    [ "$CSP" = "$(node "$TA" csp-v275 "$WORK/doc.html" "http://$H/_vf/")" ] || e2=ko
    node "$OR" csp "$WORK/doc.html" "$CSP" "http://$H/_vf/" > "$WORK/csp.json"; [ "$(oj '[j.egales,JSON.stringify(j.autres)].join("|")' < "$WORK/csp.json")" = "true|[\"http://$H/_vf/\"]" ] || e3=ko
  done; done
  printf '%s W2.1=%s W2.2=%s W2.3=%s' "${r# }" "$e1" "$e2" "$e3"
}
mutant() { # mutant <nom> <cible : module|page> <fichier-ou-motif> <expression sed> : copie, lancement ; MR = 0 si la copie diffère et que son serveur démarre
  cockpit_arreter; unset COCKPIT_MODULE
  if [ "$2" = page ]; then cockpit_module_muter_page "$1" "$4"; else cockpit_module_muter "$1" "$3" "$4"; fi; MR=$?
  [ "$MR" -eq 0 ] && { demarrer "$LAB"; MR=$RL; }
}
mutant X-CSP-ORIGINE module vf-cockpit-mise-en-page.mjs "s#worker-src \${prefixeScripts(hote)}\${NOM_FIL}#& 'self'#"
assert_eq "X-CSP-ORIGINE — la source d'origine du document ajoutée à worker-src : la copie diffère et démarre ; W2.1 et W2.2 rouges (la directive et la chaîne), le reste vert" "$MR|$(verif_csp)" "0|W1.2=ok W1.3=ok W2.1=ko W2.2=ko W2.3=ok"
mutant X-CSP-OBJET module vf-cockpit-mise-en-page.mjs "s#worker-src \${prefixeScripts(hote)}\${NOM_FIL}#& blob:#"
assert_eq "X-CSP-OBJET — une adresse d'objet local ajoutée à worker-src : W2.1 et W2.2 rouges, le reste vert" "$MR|$(verif_csp)" "0|W1.2=ok W1.3=ok W2.1=ko W2.2=ko W2.3=ok"
mutant X-CSP-PREFIXE module vf-cockpit-mise-en-page.mjs "s#worker-src \${prefixeScripts(hote)}\${NOM_FIL}#worker-src \${prefixeScripts(hote)}#"
assert_eq "X-CSP-PREFIXE — worker-src rouvert au préfixe entier de /_vf/ (AU18-01 : toute entrée de la table serait admise comme worker) : W2.1 et W2.2 rouges, le reste vert" "$MR|$(verif_csp)" "0|W1.2=ok W1.3=ok W2.1=ko W2.2=ko W2.3=ok"
mutant X-CSP-FIL-LARGE module vf-cockpit-mise-en-page.mjs "s#script-src \${prefixeScripts(hote)}vendor/elk.bundled.js#script-src \${prefixeScripts(hote)} https:#"
assert_eq "X-CSP-FIL-LARGE — la CSP du worker élargie au préfixe et au réseau : W1.2 et W1.3 rouges seuls (la CSP de page est intacte)" "$MR|$(verif_csp)" "0|W1.2=ko W1.3=ko W2.1=ok W2.2=ok W2.3=ok"

mutant X-FIL-404 module vf-cockpit-coquille-assets.mjs "/ENTREE_FIL\\.nom/d"
M1="$(chrome tracer)"; M2="$(chrome repli serveur)"
assert_eq "X-FIL-404 — l'entrée de table retirée : /_vf/elk-fil.js introuvable, le worker échoue : plus de réponse (W3.2), un avertissement (W3.3), calcul en ligne (W3.4), fil bloqué (W4.1) — tout rouge" "$MR|$(printf '%s' "$M1" | oj '[j.worker.resume.rep >= 1, j.worker.resume.avert.length === 0, j.worker.resume.enLigne === 0, j.worker.ecart < 150]')" "0|[false,false,false,false]"
assert_eq "W7.3 — fichier du worker introuvable (X-FIL-404) : le canevas s'affiche par repli en ligne ET exactement un avertissement de texte fixe est émis" "$(printf '%s' "$M2" | oj '[j.noeuds > 0, j.layout > 0, j.resume.avert.length, j.resume.avert[0], j.resume.enLigne >= 1]')" "[true,true,1,\"vf-cockpit : mise en page en ligne (le fil de calcul n'a pas démarré)\",true]"

mutant X-RESULTAT module elk-fil.js "s#poste({ id: r.id, resultat: r.data })#poste({ id: r.id, resultat: JSON.parse(JSON.stringify(r.data, (k, v) => (typeof v === 'number' ? Math.round(v / 10) * 10 : v))) })#"
EQ2="$(chrome equivalence)"; prop graphes "$CHROME" "http://127.0.0.1:$PORT" 1
assert_eq "X-RESULTAT — le worker arrondit les positions : W5.1 rouge (au moins un niveau diffère) et W5.2 rouge (des graphes diffèrent de l'oracle)" "$MR|$(printf '%s' "$EQ2" | oj 'Object.values(j.niveaux).some((v) => !v.egalCartes || !v.egalAretes)')|$(printf '%s' "$PL" | oj 'j.echecs.length > 0')" "0|true|true"

mutant X-FUITE page x "s#if (f) f.terminate(); ##"
prop sequences "$CHROME" "http://127.0.0.1:$PORT" 1
assert_eq "X-FUITE — le nettoyage ne termine pas le worker : W8.1 rouge dans la classe « workers vivants », sans la classe « erreur »" "$MR|$(printf '%s' "$PL" | oj '[!!j.parClasse.vivants, !j.parClasse.erreur]')" '0|[true,true]'

mutant X-INTERROMPU page x 's#attente.clear(); if (f)#for (const [, p] of attente) p.ko(new Error("interrompu")); attente.clear(); if (f)#'
prop sequences "$CHROME" "http://127.0.0.1:$PORT" 1
assert_eq "X-INTERROMPU — la terminaison rejette les requêtes en attente : W8.1 rouge dans la classe « erreur dans l'onglet courant », sans la classe « workers vivants »" "$MR|$(printf '%s' "$PL" | oj '[!!j.parClasse.erreur, !j.parClasse.vivants]')" '0|[true,true]'

mutant X-A4-VIDE page x "s#p.ok(d.resultat)#p.ok(p.graphe)#"
M3="$(chrome tracer)"
assert_eq "X-A4-VIDE — l'adaptateur résout avec le graphe de la requête (sans positions) : W6.1 et W6.3 rouges" "$MR|$(printf '%s' "$M3" | oj '[(() => { const r = j.worker.rendus; return !!r && r.ids.length > 0 && r.pos.every((p) => p.slice(1).every(Number.isFinite)); })(), (() => { const r = j.worker.rendus; return !!r && !!r.derniere && JSON.stringify([...r.pos].sort()) === JSON.stringify([...r.derniere].sort()); })()]')" "0|[false,false]"

vemp() { # vemp <nom> <expression sed sur vf-cockpit-module.mjs> <fichier sous assets/> : « change » ou « identique » sur la copie du module muté (aucun serveur)
  cockpit_module_muter "$1" vf-cockpit-module.mjs "$2" > /dev/null 2>&1 || { echo "copie inchangée"; unset COCKPIT_MODULE; return; }
  local r="$COCKPIT_MODULE"; unset COCKPIT_MODULE; chg "$r" "$3"
}
assert_eq "X-EMP-FIL — le motif de elk-fil.js ne désigne plus le fil : un octet de plus dans le fil ne change plus l'empreinte, W10.1 rouge" "$(vemp X-EMP-FIL 's#/\^elk-fil#/^elk-fiX#' elk-fil.js)" "identique"
assert_eq "X-EMP-PAQUET — le paquet vendor/elk.bundled.js retiré de l'empreinte : un octet de plus dans le paquet ne change plus l'empreinte, W10.2 rouge" "$(vemp X-EMP-PAQUET '/garde:empreinte-vendus/d' vendor/elk.bundled.js)" "identique"
cockpit_arreter; unset COCKPIT_MODULE

cockpit_arreter; unset COCKPIT_MODULE
bash "$TESTS/test-cockpit-accessibilite.sh" > "$WORK/acc-base.out" 2>&1; ACB=$?
cockpit_module_muter_page X-M7 "s#if (gros) { indicateur.classList.add('on', 'now'); await#if (gros) { await#"; MR=$?
[ "$MR" -eq 0 ] && { bash "$TESTS/test-cockpit-accessibilite.sh" > "$WORK/acc-mut.out" 2>&1; ACM=$?; } || ACM=99
unset COCKPIT_MODULE
assert_eq "X-M7 — la mesure M7 alignée sur l'envoi au worker : verte sur le module, rouge pour sa seule raison (M7.1) sur la copie dont l'indicateur du gros niveau n'est plus allumé avant le calcul" "$ACB|$MR|$([ "$ACM" -ne 0 ] && [ "$ACM" -ne 99 ] && echo rouge)|$(grep -c 'FAIL — M7.1' "$WORK/acc-mut.out")|$(grep -c 'FAIL — M7.0' "$WORK/acc-mut.out")" "0|0|rouge|1|0"

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
