#!/usr/bin/env bash
# test-cockpit-cycle-serveur.sh — le cycle du serveur du cockpit : coût du direct (AUDC-H2) et vie du serveur (AUDC-H3).
#   H2.1-H2.4  un seul appel au verrou par cycle du filet ; aucune collecte quand aucun onglet n'est connecté (témoin positif : un onglet connecté collecte)
#   H2.8       la connexion d'un onglet relit l'état une fois (au plus un tour par période du filet)
#   H2.5-H2.6  un changement de planning relit le planning UNE fois (exigences), sans interroger le verrou quand personne n'écoute
#   AM7.*      en CI, une suite qui dépend de Chrome sort non-zéro sans lui (garde de hygiene.sh) ; hors CI le saut reste permis
#   H3.*       journal daté avec motif d'arrêt, verrou de lanceur, relance identique / relance à option changée, activité authentifiée
# Le test COMPTE des appels (faux verrou, lectures de fichier), il ne mesure aucun temps.
# Lab neutre dans mktemp, HOME jetable, isolation git. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home" "$WORK/scripts-faux"
export HOME="$WORK/home"
trap 'vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
assert_eq() { if [ "$#" -ne 3 ]; then echo "  ❌ FAIL — $1 (assert_eq a reçu $# arguments au lieu de 3 : expansion d'accolades de bash 3.2 ?)"; FAIL=$((FAIL+1)); elif [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }
assert_ge() { if [ "${2:--1}" -ge "$3" ] 2>/dev/null; then echo "  ✅ PASS — $1 ($2 >= $3)"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1 (obtenu $2, attendu >= $3)"; FAIL=$((FAIL+1)); fi; }

# --- faux verrou : chaque appel est consigné dans le lab observé (cwd de l'appel), la forme rendue est celle d'un lab sans verrou ---
cat > "$WORK/scripts-faux/driver-lock.sh" <<'SH'
#!/usr/bin/env bash
mkdir -p "$PWD/.vibeflow"; echo "$1" >> "$PWD/.vibeflow/compteur-verrou"
case "$1" in status) echo '{"locks":[]}' ;; orphans) echo '{"orphans":[]}' ;; *) echo '{}' ;; esac
SH
chmod +x "$WORK/scripts-faux/driver-lock.sh"

# --- harnais : démarre le direct réel sur un lab, mesure sur une fenêtre, rend un JSON ---
cat > "$AUX/cycle.mjs" <<'JS'
// cycle.mjs <scripts> <lab> <client|sans> : le direct réel (startLive), un lab, un faux verrou. Sortie : un JSON de comptes.
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , scripts, lab, mode] = process.argv;
const compteur = path.join(lab, '.vibeflow', 'compteur-verrou');
let req = 0; const lire = fs.readFileSync;
fs.readFileSync = function (f, ...r) { if (String(f).endsWith('REQUIREMENTS.md')) req++; return lire.call(this, f, ...r); };
const { startLive } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-live.mjs')).href);
const appels = (nom) => (fs.existsSync(compteur) ? fs.readFileSync(compteur, 'utf8').split('\n').filter((l) => l === nom).length : 0);
const evs = [];
const live = startLive({ root: lab, sortie: path.join(lab, '.vibeflow', 'cockpit'), onEvent: (n) => evs.push(n), log: () => {}, aClient: () => mode === 'client' });
const dormir = (ms) => new Promise((r) => setTimeout(r, ms));
// fenêtre 1 : le filet seul (5 s de période), sans rien changer
fs.rmSync(compteur, { force: true }); await dormir(5700);
const filet = { status: appels('status'), orphans: appels('orphans') };
// fenêtre 2 : un changement de planning ; le prochain tour du filet tombe 4 s plus tard, hors de la fenêtre
fs.rmSync(compteur, { force: true }); req = 0; evs.length = 0;
fs.writeFileSync(path.join(lab, '.planning', 'ROADMAP.md'), '- [x] **Phase 1: Socle** - premier jet\n- [x] **Phase 2: Suite** - deuxième jet\n');
for (let i = 0; i < 40 && !evs.some((e) => e === 'patch' || e === 'structural'); i++) await dormir(100);
const changement = { evenement: evs.some((e) => e === 'patch' || e === 'structural'), status: appels('status'), exigences: req };
// fenêtre 3 : la connexion d'un onglet après un silence relit l'état une fois, et pas deux (deux onglets coup sur coup)
fs.rmSync(compteur, { force: true }); live.reveil?.(); live.reveil?.();
const reveil = { status: appels('status') };
live.stop();
console.log(JSON.stringify({ filet, changement, reveil }));
process.exit(0);
JS

mklab() {
  local L="$1"; mkdir -p "$L/.planning/phases/01-x" "$L/.vibeflow/cockpit"
  printf -- '- [x] **Phase 1: Socle** - premier jet\n- [ ] **Phase 2: Suite** - deuxième jet\n' > "$L/.planning/ROADMAP.md"
  printf -- '- [x] **REQ-01**: premier\n- [ ] **REQ-02**: second\n' > "$L/.planning/REQUIREMENTS.md"
  printf '<objective>socle</objective>\n' > "$L/.planning/phases/01-x/01-01-PLAN.md"; echo ok > "$L/.planning/phases/01-x/01-01-SUMMARY.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
}

echo "=== H2 — cycle du filet et lecture du planning ==="
mklab "$WORK/labc"; mklab "$WORK/labs"
VF_COCKPIT_SCRIPTS_DIR="$WORK/scripts-faux" node "$AUX/cycle.mjs" "$SCRIPTS" "$WORK/labc" client > "$WORK/c.json" 2> "$WORK/c.err" &
PC=$!
VF_COCKPIT_SCRIPTS_DIR="$WORK/scripts-faux" node "$AUX/cycle.mjs" "$SCRIPTS" "$WORK/labs" sans > "$WORK/s.json" 2> "$WORK/s.err" &
PS_=$!
wait "$PC"; wait "$PS_"
jq_() { node -e "const j=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'));const v=new Function('j','return ('+process.argv[2]+')')(j);console.log(typeof v==='string'?v:JSON.stringify(v))" "$1" "$2" 2>/dev/null || echo "illisible"; }
echo "  (avec onglet : $(cat "$WORK/c.json" 2>/dev/null) · sans onglet : $(cat "$WORK/s.json" 2>/dev/null))"
assert_ge "H2.0 — témoin positif : avec un onglet connecté, le filet a collecté (au moins un appel au verrou)" "$(jq_ "$WORK/c.json" 'j.filet.status')" 1
assert_eq "H2.1 — un seul appel au verrou par cycle du filet (appels 'status' = 1 sur la fenêtre d'un cycle)" "$(jq_ "$WORK/c.json" 'j.filet.status')" "1"
assert_eq "H2.2 — aucune collecte sans onglet : zéro appel au verrou sur la fenêtre du filet" "$(jq_ "$WORK/s.json" 'j.filet.status')" "0"
assert_eq "H2.3 — aucune collecte sans onglet : zéro lecture du registre des orphelins" "$(jq_ "$WORK/s.json" 'j.filet.orphans')" "0"
assert_eq "H2.4 — un changement de planning est annoncé même sans onglet (la page sur disque suit)" "$(jq_ "$WORK/s.json" 'j.changement.evenement')" "true"
assert_eq "H2.5 — un changement de planning relit le planning UNE fois : REQUIREMENTS.md ouvert au plus 2 fois (1 lecture du planning + 1 contrôle de format brut ; trois fois = planning relu)" "$(jq_ "$WORK/c.json" 'j.changement.exigences >= 1 && j.changement.exigences <= 2')" "true"
assert_eq "H2.6 — sans onglet, un changement de planning n'interroge pas le verrou" "$(jq_ "$WORK/s.json" 'j.changement.status')" "0"
assert_eq "H2.7 — avec un onglet, un changement de planning interroge le verrou une fois" "$(jq_ "$WORK/c.json" 'j.changement.status')" "1"

assert_eq "H2.8 — la connexion d'un onglet après un silence relit le verrou une fois (le second onglet coup sur coup ne relit pas)" "$(jq_ "$WORK/s.json" 'j.reveil.status')" "1"

echo "=== H3 — vie du serveur : lanceurs, journal, inactivité ==="
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
cat > "$AUX/get.mjs" <<'JS'
// get.mjs <port> <chemin> [jeton] : le corps ; le jeton est celui de la page servie (en-tête x-vf-cockpit-token)
import http from 'node:http';
const [, , port, p, jeton] = process.argv;
http.get({ host: '127.0.0.1', port: Number(port), path: p, headers: { Host: `127.0.0.1:${port}`, ...(jeton ? { 'x-vf-cockpit-token': jeton } : {}) } }, (r) => { let b = ''; r.on('data', (c) => (b += c)); r.on('end', () => { process.stdout.write(b, () => process.exit(0)); }); }).on('error', () => process.exit(1));
JS
jeton_de() { node "$AUX/get.mjs" "$1" / | node -e "let s='';process.stdin.on('data',c=>s+=c).on('end',()=>console.log((/VF_COCKPIT_SERVER=\\{\"token\":\"([0-9a-f]+)\"/.exec(s)||[])[1]||''))"; }
nserv() { pgrep -f -- "$1/.vibeflow/cockpit/serve.mjs" | wc -l | tr -d ' '; }
pid_etat() { node -e "try{console.log(JSON.parse(require('fs').readFileSync('$1/.vibeflow/cockpit/.cache/server.json','utf8')).pid)}catch{console.log('')}"; }
LAN="node $SCRIPTS/vf-cockpit.mjs"
LH="$WORK/labh"; mklab "$LH"; node "$SCRIPTS/vf-cockpit-build.mjs" "$LH" --quiet > "$WORK/build-h.out" 2>&1 || cat "$WORK/build-h.out"
PH=$(libre)
# H3.1 deux lanceurs lancés ensemble : un seul serveur
$LAN open --lab "$LH" --no-open --port "$PH" > "$WORK/l1.out" 2>&1 & L1=$!
$LAN open --lab "$LH" --no-open --port "$PH" > "$WORK/l2.out" 2>&1 & L2=$!
wait "$L1"; R1=$?; wait "$L2"; R2=$?
assert_eq "H3.1 — deux lanceurs lancés ensemble : les deux réussissent (rc 0 et 0)" "$R1 $R2" "0 0"
assert_eq "H3.2 — deux lanceurs lancés ensemble : UN seul serveur pour le lab (verrou de lanceur)" "$(nserv "$LH")" "1"
assert_eq "H3.3 — les deux lanceurs rendent la même adresse" "$([ "$(grep -o 'http://127.0.0.1:[0-9]*' "$WORK/l1.out" | sed -n 1p)" = "$(grep -o 'http://127.0.0.1:[0-9]*' "$WORK/l2.out" | sed -n 1p)" ] && echo oui || echo non)" "oui"
PID1="$(pid_etat "$LH")"; LOG="$LH/.vibeflow/cockpit/.cache/serveur.log"
# H3.4 relance à options identiques : le serveur n'est pas remplacé
$LAN open --lab "$LH" --no-open --port "$PH" > "$WORK/l3.out" 2>&1
assert_eq "H3.4 — relance à options et code identiques : même serveur (PID inchangé)" "$(pid_etat "$LH")" "$PID1"
assert_eq "H3.5 — relance identique : rien n'est écrit au journal sur un remplacement" "$(grep -c 'remplacé' "$LOG")" "0"
# H3.6 relance qui change une option : remplacé, et écrit au journal
$LAN open --lab "$LH" --no-open --terminal --port "$PH" > "$WORK/l4.out" 2>&1
PID2="$(pid_etat "$LH")"
assert_eq "H3.6 — relance avec --terminal : le serveur est remplacé (PID différent)" "$([ -n "$PID2" ] && [ "$PID2" != "$PID1" ] && echo oui || echo non)" "oui"
assert_has "H3.7 — le remplacement est écrit au journal avec son motif exact (aucun terminal enregistré)" "$(cat "$LOG")" "lanceur : relance : serveur PID $PID1 remplacé (--terminal demandé, aucun terminal enregistré"
assert_eq "H3.8 — le journal porte la date de l'arrêt de l'ancien serveur et son motif (signal)" "$(grep -cE "^20[0-9]{2}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z arrêt : signal SIGTERM \(PID $PID1\)" "$LOG")" "1"
assert_eq "H3.9 — le journal porte la date du démarrage du nouveau serveur" "$(grep -cE "^20[0-9]{2}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z démarrage : PID $PID2" "$LOG")" "1"
# H3.10 serveur orphelin (server.json perdu) : repris, pas doublé
rm -f "$LH/.vibeflow/cockpit/.cache/server.json"
$LAN open --lab "$LH" --no-open --port "$PH" > "$WORK/l5.out" 2>&1
assert_eq "H3.10 — server.json perdu, serveur du lab déjà à l'écoute : aucun second serveur lancé" "$(nserv "$LH")" "1"
assert_eq "H3.11 — le serveur repris est le même (PID de server.json = PID d'avant) et la reprise est au journal" "$(pid_etat "$LH") $(grep -c 'sans server.json : repris' "$LOG")" "$PID2 1"
# H3.19-H3.21 empreinte du code : un serveur chargé avec un autre code que la sortie assemblée est remplacé et le journal le dit ; la relance suivante, à code identique, ne remplace pas
echo '// empreinte changée' >> "$LH/.vibeflow/cockpit/serve.mjs"
$LAN open --lab "$LH" --no-open --port "$PH" > "$WORK/l7.out" 2>&1
PID3="$(pid_etat "$LH")"
assert_eq "H3.19 — code de la sortie changé depuis le démarrage du serveur : le serveur est remplacé (PID différent)" "$([ -n "$PID3" ] && [ "$PID3" != "$PID2" ] && echo oui || echo non)" "oui"
assert_has "H3.20 — le remplacement pour code changé est écrit au journal avec les deux empreintes" "$(cat "$LOG")" "remplacé (code du serveur changé, empreinte "
$LAN open --lab "$LH" --no-open --port "$PH" > "$WORK/l8.out" 2>&1
assert_eq "H3.21 — relance suivante, code identique : même serveur (le test H3.19 ne remplace pas à chaque relance)" "$(pid_etat "$LH")" "$PID3"
assert_eq "H3.22 — le verrou de lanceur vit sous .cache : rien n'est posé à côté du dossier du cockpit dans .vibeflow" "$(ls -A "$LH/.vibeflow" | tr '\n' ' ')" "cockpit "
$LAN stop --lab "$LH" > "$WORK/l6.out" 2>&1
for _ in $(seq 1 30); do [ "$(nserv "$LH")" = 0 ] && break; sleep 0.2; done
assert_has "H3.12 — « stop » : l'arrêt demandé et le signal reçu sont au journal" "$(cat "$LOG")" "lanceur : arrêt demandé"
assert_eq "H3.13 — après « stop », plus aucun serveur" "$(nserv "$LH")" "0"

# H3.23-H3.24 verrou créé à l'instant (PID pas encore écrit) : jamais pris pour un verrou périmé
LV="$WORK/labv"; mklab "$LV"; node "$SCRIPTS/vf-cockpit-build.mjs" "$LV" --quiet > "$WORK/build-v.out" 2>&1 || cat "$WORK/build-v.out"
LKV="$LV/.vibeflow/cockpit/.cache/lanceur.lock"; mkdir -p "$(dirname "$LKV")"; : > "$LKV"
$LAN open --lab "$LV" --no-open --port "$(libre)" > "$WORK/lv.out" 2>&1 & LVP=$!
sleep 1
assert_eq "H3.23 — verrou fraîchement créé et vide : le second lanceur attend, il ne le reprend pas (le fichier reste vide)" "$([ -s "$LKV" ] && echo repris || echo vide) $(kill -0 "$LVP" 2>/dev/null && echo attend || echo sorti)" "vide attend"
rm -f "$LKV"; wait "$LVP"
assert_eq "H3.24 — témoin : le verrou libéré, le lanceur finit et un seul serveur tourne" "$(nserv "$LV")" "1"
$LAN stop --lab "$LV" > /dev/null 2>&1

# H3.14-H3.16 inactivité : une requête authentifiée compte comme activité ; le motif d'arrêt est au journal ; un terminal ouvert retient l'arrêt et le dit
LI="$WORK/labi"; mklab "$LI"; node "$SCRIPTS/vf-cockpit-build.mjs" "$LI" --quiet > "$WORK/build-i.out" 2>&1 || cat "$WORK/build-i.out"
OUTI="$LI/.vibeflow/cockpit"; PI=$(libre)
VF_COCKPIT_IDLE_TICK_MS=300 node "$OUTI/serve.mjs" --no-open --port "$PI" --idle-exit 0.05 > "$WORK/srv-i.out" 2>&1 & SI=$!
for _ in $(seq 1 100); do [ -s "$OUTI/.cache/server.json" ] && break; sleep 0.1; done
TOK="$(jeton_de "$PI")"
assert_eq "H3.14a — témoin : le jeton de la page est lu" "$([ ${#TOK} -ge 16 ] && echo oui || echo non)" "oui"
T0=$SECONDS; while [ $((SECONDS-T0)) -lt 8 ]; do node "$AUX/get.mjs" "$PI" /api/vf/etat "$TOK" > /dev/null; sleep 0.5; done
assert_eq "H3.14 — idle-exit 3 s, une requête authentifiée toutes les 0,5 s pendant 8 s : le serveur vit" "$(kill -0 "$SI" 2>/dev/null && echo vivant || echo sorti)" "vivant"
for _ in $(seq 1 40); do kill -0 "$SI" 2>/dev/null || break; sleep 0.5; done
assert_eq "H3.15 — témoin : sans plus de requête, le même serveur s'arrête sur inactivité" "$(kill -0 "$SI" 2>/dev/null && echo vivant || echo sorti)" "sorti"
assert_has "H3.16 — le motif de l'arrêt (inactivité) est daté au journal" "$(cat "$WORK/srv-i.out")" "Z arrêt : inactivité ("
# terminal factice qui se déclare occupé : la rétention est dite au journal, le serveur reste
LT="$WORK/labt"; mklab "$LT"; node "$SCRIPTS/vf-cockpit-build.mjs" "$LT" --quiet > "$WORK/build-t.out" 2>&1 || cat "$WORK/build-t.out"
OUTT="$LT/.vibeflow/cockpit"; PT=$(libre)
cat > "$OUTT/vf-cockpit-terminal.mjs" <<'JS'
export const preparerTerminal = () => ({ injection: () => '', occupe: () => true, demarrer() {}, frameSrc: () => '', routeP() {} });
JS
VF_COCKPIT_IDLE_TICK_MS=300 node "$OUTT/serve.mjs" --no-open --port "$PT" --idle-exit 0.05 --terminal > "$WORK/srv-t.out" 2>&1 & ST=$!
for _ in $(seq 1 100); do [ -s "$OUTT/.cache/server.json" ] && break; sleep 0.1; done
for _ in $(seq 1 30); do grep -q 'retenu' "$WORK/srv-t.out" && break; sleep 0.3; done
assert_has "H3.17 — un terminal ouvert retient l'arrêt sur inactivité, et le journal le dit" "$(cat "$WORK/srv-t.out")" "arrêt sur inactivité retenu : un terminal est ouvert"
assert_eq "H3.18 — le serveur au terminal ouvert est encore vivant" "$(kill -0 "$ST" 2>/dev/null && echo vivant || echo sorti)" "vivant"
vf_hyg_stop "$ST" 2>/dev/null; vf_hyg_stop "$SI" 2>/dev/null

# H3.25-H3.27 un flux de page (celui du direct, seul flux d'une page) ouvert plus longtemps que idle-exit puis fermé : le délai d'inactivité repart de la FERMETURE
cat > "$AUX/flux.mjs" <<'JS'
// flux.mjs <port> <jeton> <ms> : ouvre le flux du direct, le garde <ms> millisecondes, le ferme.
import http from 'node:http';
const [, , port, jeton, ms] = process.argv;
const r = http.get({ host: '127.0.0.1', port: Number(port), path: '/api/vf/events', headers: { Host: `127.0.0.1:${port}`, 'x-vf-cockpit-token': jeton } }, (res) => { res.on('data', () => {}); setTimeout(() => { r.destroy(); setTimeout(() => process.exit(0), 100); }, Number(ms)); });
r.on('error', () => process.exit(1));
JS
LF="$WORK/labf"; mklab "$LF"; node "$SCRIPTS/vf-cockpit-build.mjs" "$LF" --quiet > "$WORK/build-f.out" 2>&1 || cat "$WORK/build-f.out"
OUTF="$LF/.vibeflow/cockpit"; PF=$(libre)
VF_COCKPIT_IDLE_TICK_MS=300 node "$OUTF/serve.mjs" --no-open --port "$PF" --idle-exit 0.05 > "$WORK/srv-f.out" 2>&1 & SF=$!
for _ in $(seq 1 100); do [ -s "$OUTF/.cache/server.json" ] && break; sleep 0.1; done
TOKF="$(jeton_de "$PF")"
node "$AUX/flux.mjs" "$PF" "$TOKF" 4500 > /dev/null 2>&1
sleep 1.5
assert_eq "H3.25 — flux du direct gardé 4,5 s (plus que idle-exit, 3 s) puis fermé : 1,5 s après, le serveur vit (le délai repart de la fermeture)" "$(kill -0 "$SF" 2>/dev/null && echo vivant || echo sorti)" "vivant"
for _ in $(seq 1 40); do kill -0 "$SF" 2>/dev/null || break; sleep 0.5; done
assert_eq "H3.26 — témoin : sans plus aucun flux ni requête, le même serveur s'arrête sur inactivité" "$(kill -0 "$SF" 2>/dev/null && echo vivant || echo sorti)" "sorti"
assert_has "H3.27 — le motif de l'arrêt (inactivité) est daté au journal" "$(cat "$WORK/srv-f.out")" "Z arrêt : inactivité ("
vf_hyg_stop "$SF" 2>/dev/null

echo "=== AM7 — en CI, l'absence de Chrome fait échouer une suite qui en dépend ==="
HYG="$(cd "$(dirname "$0")" && pwd)/hygiene.sh"
cat > "$WORK/mini-chrome.sh" <<'SH'
#!/usr/bin/env bash
# suite factice : la forme des vraies suites (WORK, trap EXIT, hygiene.sh, CHROME="" puis recherche, saut + exit 0)
set -uo pipefail
WORK="$(mktemp -d)"; trap 'vf_hyg_fin; rm -rf "$WORK"' EXIT
. "$HYG"; vf_hyg_init
CHROME=""
[ -n "${FAUX_CHROME:-}" ] && CHROME="$FAUX_CHROME"
if [ -z "$CHROME" ]; then echo "  ⊘ SUITE SAUTÉE : aucun navigateur"; exit 0; fi
echo "  navigateur : $CHROME"; exit 0
SH
rc_mini() { env -u CI -u VF_CHROME_OPTIONNEL -u CHAINE_SANS_NAVIGATEUR HYG="$HYG" "$@" bash "$WORK/mini-chrome.sh" > "$WORK/mini.out" 2>&1; echo $?; }
assert_eq "AM7.1 — hors CI, sans Chrome : le saut local sort 0" "$(rc_mini)" "0"
assert_eq "AM7.2 — en CI, sans Chrome : la suite sort non-zéro (1)" "$(rc_mini CI=true)" "1"
assert_has "AM7.3 — le message dit l'absence de navigateur en CI" "$(cat "$WORK/mini.out")" "AM7 aucun navigateur"
assert_eq "AM7.4 — témoin positif : en CI, avec un Chrome trouvé, la suite sort 0" "$(rc_mini CI=true FAUX_CHROME=/usr/bin/chrome-factice)" "0"
assert_eq "AM7.5 — échappatoire explicite VF_CHROME_OPTIONNEL en CI : sort 0" "$(rc_mini CI=true VF_CHROME_OPTIONNEL=1)" "0"
# couverture : toute suite qui cherche un navigateur est classée (helper, filet ou hors) ; une suite « hors » rougit ; chaque suite qui appelle vf_chrome_saut (chrome-saut.sh, le mécanisme du point de saut) est jouée en CI=true sur une copie dont la
# recherche de Chrome est neutralisée (chemin macOS retiré, noms du PATH remplacés) : elle doit sortir non-zéro avec le message AM7, APRÈS avoir écrit son saut « aucun navigateur »
CP="$(cd "$(dirname "$0")/.." && pwd)"; trap 'rm -f "$CP"/tests/zz-am7-*.sh; vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"' EXIT # copies neutralisées posées à côté des suites (leurs chemins relatifs doivent résoudre), retirées à la sortie
# critère sur le CODE (jamais sur une formule de message) : toute suite qui CHERCHE un navigateur pose CHROME="" (ou EKCHROME="") avant sa recherche
# classer <suite> : « helper » (appelle vf_chrome_saut : jouée plus bas), « filet » (hygiene.sh sourcé AVANT la recherche + vf_hyg_fin dans un trap EXIT), « hors » (rien ne la fait échouer en CI)
classer() {
  local f="$1" lh lc
  grep -q 'vf_chrome_saut' "$f" && { echo helper; return; }
  lh="$(grep -n 'hygiene.sh' "$f" | sed -n 1p | cut -d: -f1)"; lc="$(grep -n 'CHROME=""' "$f" | sed -n 1p | cut -d: -f1)"
  if [ -n "$lh" ] && [ -n "$lc" ] && [ "$lh" -lt "$lc" ] && grep -q 'vf_hyg_fin' "$f" && grep -Eq 'trap .*EXIT' "$f"; then echo filet; else echo hors; fi
}
# le classeur lui-même doit pouvoir rougir : suites factices à formulations de saut différentes
printf '%s\n' 'CHROME=""' 'echo "  pas de navigateur, on passe"; exit 0' > "$WORK/f-hors.sh"
printf '%s\n' '. "$(dirname "$0")/hygiene.sh"; vf_hyg_init' 'trap vf_hyg_fin EXIT' 'CHROME=""' 'echo saut' > "$WORK/f-filet.sh"
printf '%s\n' '. "$(dirname "$0")/hygiene.sh"; vf_hyg_init' 'trap "echo fin" EXIT' 'CHROME=""' 'echo saut' > "$WORK/f-sansfin.sh"
printf '%s\n' 'CHROME=""' '[ -z "$CHROME" ] && { . "$(dirname "$0")/chrome-saut.sh"; vf_chrome_saut "x"; }' > "$WORK/f-helper.sh"
assert_eq "AM7.6b — le classeur sépare : formulation libre sans filet = hors ; filet complet = filet ; filet sans vf_hyg_fin = hors ; helper = helper" "$(classer "$WORK/f-hors.sh") $(classer "$WORK/f-filet.sh") $(classer "$WORK/f-sansfin.sh") $(classer "$WORK/f-helper.sh")" "hors filet hors helper"
NSAUT=0; NSUITES=0; BAD=""
for f in "$(dirname "$0")"/test-*.sh; do
  b="$(basename "$f")"; [ "$b" = test-cockpit-cycle-serveur.sh ] && continue
  grep -q 'CHROME=""' "$f" || continue
  NSUITES=$((NSUITES+1))
  case "$(classer "$f")" in
    hors) BAD="$BAD $b(rien ne la fait échouer en CI sans Chrome)"; continue ;;
    filet) continue ;;
  esac
  NSAUT=$((NSAUT+1))
  sed 's#"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ##; s#google-chrome google-chrome-stable chromium chromium-browser#navigateur-inexistant-xyz#' "$f" > "$CP/tests/zz-am7-$b"
  cmp -s "$f" "$CP/tests/zz-am7-$b" && { BAD="$BAD $b(recherche non neutralisée)"; continue; }
  env -u CHROME_BIN -u VF_CHROME_OPTIONNEL CI=true bash "$CP/tests/zz-am7-$b" > "$WORK/am-$b.out" 2> "$WORK/am-$b.err" < /dev/null; rc=$?
  { [ "$rc" -ne 0 ] && grep -q 'AM7 aucun navigateur' "$WORK/am-$b.err"; } || BAD="$BAD $b(rc=$rc)"
done
rm -f "$CP"/tests/zz-am7-*.sh
assert_ge "AM7.6a — témoin : au moins vingt suites cherchent un navigateur, dont au moins six appellent le helper du point de saut" "$NSUITES" 20
assert_ge "AM7.6c — au moins six suites appellent le helper" "$NSAUT" 6
assert_eq "AM7.6 — chaque suite qui saute sa moitié navigateur sort non-zéro en CI sans Chrome, sur place (rouge : aucune)" "${BAD:-aucune}" "aucune"

echo "=== AM7.S — aide commune socle-serveur.sh : lancer, interroger, arrêter sous l'hygiène (A6, SOCL-02) ==="
SOCLE="$(cd "$(dirname "$0")" && pwd)/socle-serveur.sh"
AIDE=absente
{ [ -f "$SOCLE" ] && bash -n "$SOCLE" 2>/dev/null; } && { . "$SOCLE"; AIDE=oui; }
fonctions_manquantes() { local f r=""; for f in cockpit_lancer cockpit_arreter cockpit_get attendre cockpit_lancement_brut; do [ "$(type -t "$f")" = function ] || r="$r $f"; done; echo "${r:-aucune}"; }
assert_eq "AM7.S1 — socle-serveur.sh existe, passe bash -n, et ses cinq fonctions sont définies (manquantes : aucune)" "$AIDE$(fonctions_manquantes | sed 's/^/ /')" "oui aucune"
# formes de lancement assemblées à l'exécution (aucun littéral) pour que cette suite ne se détecte pas elle-même
PJ=".mjs\""; SV="serve"; NO1="--no"; NO2="-open"; IMP="--imp"; ORT="ort"
if [ "$AIDE" != oui ]; then # aide absente : des remplaçants qui échouent, pour que chaque témoin rougisse nommément au lieu d'arrêter la suite
  cockpit_lancer() { echo "aide absente" >&2; VF_PORT=0; VF_JETON=""; VF_PID=""; VF_SORTIE=""; return 127; }
  cockpit_arreter() { return 127; }
  cockpit_get() { VF_CODE=000; return 127; }
  attendre() { return 127; }
  cockpit_lancement_brut() { return 0; }
fi
nproc_sortie() { ps -eo args | S="$1/serve.mjs" awk 'index($0, ENVIRON["S"]) { n++ } END { print n + 0 }'; }  # le motif passe par l'environnement : jamais dans la ligne de commande d'awk, qui se compterait elle-même
LS="$WORK/labs2"; mklab "$LS"; node "$SCRIPTS/vf-cockpit-build.mjs" "$LS" --quiet > "$WORK/build-s2.out" 2>&1 || cat "$WORK/build-s2.out"
export VF_AM7_TEMOIN=temoin-env-ok
cockpit_lancer "$LS" > "$WORK/s2.out" 2> "$WORK/s2.err"; RC2=$?
PIDJ="$(node -e 'try{console.log(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).pid)}catch{console.log("")}' "$LS/.vibeflow/cockpit/.cache/server.json")"
SORTIE_REELLE="$(cd "$LS/.vibeflow/cockpit" && pwd -P)"
ENV_OK="$(ps eww -p "${VF_PID:-0}" 2>/dev/null | grep -c 'VF_AM7_TEMOIN=temoin-env-ok')"
assert_eq "AM7.S2 — cockpit_lancer : rend 0, port > 0, jeton >= 16, pid vivant = pid de server.json, sortie = chemin réel, rien sur stdout, variable héritée vue du serveur" "$RC2 $([ "${VF_PORT:-0}" -gt 0 ] && echo oui || echo non) $([ "${#VF_JETON}" -ge 16 ] && echo oui || echo non) $({ [ -n "${VF_PID:-}" ] && [ "$VF_PID" = "$PIDJ" ] && ps -p "$VF_PID" > /dev/null 2>&1; } && echo oui || echo non) $([ "${VF_SORTIE:-}" = "$SORTIE_REELLE" ] && echo oui || echo non) $([ ! -s "$WORK/s2.out" ] && echo oui || echo non) $([ "$ENV_OK" = 1 ] && echo oui || echo non)" "0 oui oui oui oui oui oui"
unset VF_AM7_TEMOIN
INSCRIT=non; for q in ${PIDS[@]+"${PIDS[@]}"}; do [ "$q" = "${VF_PID:-x}" ] && INSCRIT=oui; done
assert_eq "AM7.S3 — hygiène : vf_hyg_vivants liste VF_PID, PIDS le contient, un seul processus pour la sortie" "$(vf_hyg_vivants | awk '{print $1}' | grep -cx "${VF_PID:-x}") $INSCRIT $(nproc_sortie "$SORTIE_REELLE")" "1 oui 1"
cockpit_get /api/vf/etat > "$WORK/s4.json" 2> /dev/null; C1="$VF_CODE"
cockpit_get /api/vf/inconnu-am7 > /dev/null 2>&1; C2="$VF_CODE"
assert_eq "AM7.S4 — cockpit_get : /api/vf/etat rend un JSON non vide et VF_CODE=200 ; un chemin inconnu rend VF_CODE=404" "$C1 $(node -e 'try{JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));console.log("json")}catch{console.log("nonjson")}' "$WORK/s4.json") $C2" "200 json 404"
sleep 300 & ETR=$!
cockpit_arreter "$ETR"
ETR_ETAT="$(ps -p "$ETR" > /dev/null 2>&1 && echo vivant || echo mort)"
SERVEUR_PID="${VF_PID:-0}"; AVANT="$(ps -p "$SERVEUR_PID" > /dev/null 2>&1 && echo vivant || echo absent)"; cockpit_arreter
APRES="$(ps -p "$SERVEUR_PID" > /dev/null 2>&1 && echo vivant || echo sorti)"; DANS=non; for q in ${PIDS[@]+"${PIDS[@]}"}; do [ "$q" = "$SERVEUR_PID" ] && DANS=oui; done
kill "$ETR" 2> /dev/null; wait "$ETR" 2> /dev/null
assert_eq "AM7.S5 — cockpit_arreter : le serveur marqué est arrêté (VF_PID vidé, absent de PIDS) ET le processus étranger sans la marque survit" "avant=$AVANT serveur=$APRES vide=$([ -z "${VF_PID:-}" ] && echo oui || echo non) pids=$([ "$DANS" = oui ] && echo avec || echo sans) etranger=$ETR_ETAT" "avant=vivant serveur=sorti vide=oui pids=sans etranger=vivant"
t_s() { local a=$SECONDS; "$@"; echo "$? $((SECONDS - a))"; }
SA="$(t_s attendre 5 true)"
SB="$(t_s attendre 2 false)"
( sleep 1; : > "$WORK/pret-s6" ) & SBG=$!
SC="$(t_s attendre 6 test -e "$WORK/pret-s6")"; wait "$SBG" 2> /dev/null
assert_eq "AM7.S6 — attendre : (a) vraie : 0 en moins de 2 s ; (b) jamais vraie, délai 2 s : 1 entre 2 et 4 s ; (c) vraie après 1 s : 0 avant le délai" "$([ "${SA%% *}" = 0 ] && [ "${SA##* }" -lt 2 ] && echo ok || echo "a=$SA") $([ "${SB%% *}" = 1 ] && [ "${SB##* }" -ge 2 ] && [ "${SB##* }" -le 4 ] && echo ok || echo "b=$SB") $([ "${SC%% *}" = 0 ] && [ "${SC##* }" -lt 6 ] && echo ok || echo "c=$SC")" "ok ok ok"
cp -R "$LS/.vibeflow/cockpit" "$WORK/sortie-sans"; rm -f "$WORK/sortie-sans/vf-cockpit-server.mjs"
T0=$SECONDS; COCKPIT_SORTIE="$WORK/sortie-sans" COCKPIT_ATTENTE=20 COCKPIT_LOG="$WORK/s7-serve.out" cockpit_lancer "$LS" > /dev/null 2> "$WORK/s7.err"; RC7=$?; D7=$((SECONDS - T0))
assert_eq "AM7.S7 — serveur mort avant d'écouter : retour 1, en moins de 15 s, VF_PID vide, VF_PORT=0, journal non vide" "$RC7 $([ "$D7" -lt 15 ] && echo oui || echo non) $([ -z "${VF_PID:-}" ] && echo oui || echo non) ${VF_PORT:-?} $([ -s "$WORK/s7-serve.out" ] && echo oui || echo non)" "1 oui oui 0 oui"
RC8="$(env -u VF_HYG_TAG bash -c '. "$1"; cockpit_lancer "$2" > /dev/null 2>&1; echo $?' x "$SOCLE" "$LS" 2> /dev/null)"
assert_eq "AM7.S8 — hygiène non initialisée (bash enfant) : retour 2 et aucun processus de la sortie (ps + awk)" "$RC8 $(nproc_sortie "$SORTIE_REELLE")" "2 0"
HORS="$(mktemp -d)"; cp -R "$LS/.vibeflow/cockpit" "$HORS/sortie"
COCKPIT_SORTIE="$HORS/sortie" cockpit_lancer "$LS" > /dev/null 2>&1; RC9=$?
assert_eq "AM7.S9 — sortie hors de la marque de la suite : retour 3 et rien lancé (ps + awk)" "$RC9 $(nproc_sortie "$HORS/sortie")" "3 0"
# sonde des effets de bord : trois clés indépendantes (inscrit / invisible / stale), jouée avec l'aide puis avec ses mutants
sonde_aide() {
  ( . "$1"; local r_i=non r_v r_s q
    cockpit_lancer "$LS" > /dev/null 2>&1; for q in ${PIDS[@]+"${PIDS[@]}"}; do [ "$q" = "${VF_PID:-x}" ] && r_i=oui; done; cockpit_arreter
    COCKPIT_SORTIE="$HORS/sortie" cockpit_lancer "$LS" > /dev/null 2>&1; r_v=$?
    [ "$r_v" = 0 ] && { kill "$VF_PID" 2> /dev/null; wait "$VF_PID" 2> /dev/null; ps -p "$VF_PID" > /dev/null 2>&1 && r_v="$r_v(survit)"; }
    printf '{"pid":2147483000,"port":9,"token":"perime","url":"http://127.0.0.1:9"}\n' > "$LS/.vibeflow/cockpit/.cache/server.json"
    cockpit_lancer "$LS" > /dev/null 2>&1; r_s="$([ "${VF_PORT:-0}" = 9 ] && echo suivi || echo ignoré)"; cockpit_arreter
    echo "inscrit=$r_i invisible=$r_v stale=$r_s" )
}
mutant_de() { sed "/$1/d" "$SOCLE" > "$WORK/mut-$1.sh"; echo "$(cmp -s "$SOCLE" "$WORK/mut-$1.sh" && echo identique || echo different) $(bash -n "$WORK/mut-$1.sh" 2> /dev/null && echo valide || echo invalide) $(sonde_aide "$WORK/mut-$1.sh")"; }
if [ "$AIDE" = oui ]; then
  BASE_SONDE="$(sonde_aide "$SOCLE")"
  M_PIDS="$(mutant_de am7:pids)"; M_VIS="$(mutant_de am7:visible)"; M_STALE="$(mutant_de am7:stale)"
else BASE_SONDE="aide absente"; M_PIDS="aide absente"; M_VIS="aide absente"; M_STALE="aide absente"; fi
assert_eq "AM7.S10 — mutant am7:pids (inscription à PIDS retirée) : seule la clé inscrit change (oui -> non), l'aide intacte donne les trois clés attendues" "$BASE_SONDE | $M_PIDS" "inscrit=oui invisible=3 stale=ignoré | different valide inscrit=non invisible=3 stale=ignoré"
assert_eq "AM7.S11 — mutant am7:visible (refus hors marque retiré) : seule la clé invisible change (3 -> 0), le serveur lancé hors marque est arrêté par la suite" "$M_VIS" "different valide inscrit=oui invisible=0 stale=ignoré"
assert_eq "AM7.S12 — mutant am7:stale (effacement et contrôle du pid retirés) : seule la clé stale change (ignoré -> suivi)" "$M_STALE" "different valide inscrit=oui invisible=3 stale=suivi"
rm -rf "$HORS"

echo "=== AM7.K — la classe « lancement direct du serveur » est fermée (A6, P79-D-23) ==="
# Exceptions : suites que le plan 79-01 édite et que 79-06 migre. Liste écrite une seule fois, elle ne peut que rétrécir.
EXC_LANCEMENT="test-cockpit-questions.sh test-cockpit-git-env.sh"
DIR_T="$(cd "$(dirname "$0")" && pwd)"
printf '%s\n' "node \"\$O/$SV$PJ $NO1$NO2 --port 1" "\"\$NODE\" \$NA \"\$O/$SV$PJ $NO1$NO2" "node $IMP$ORT /x/sonde.mjs $NO1$NO2 --port 2" "# node \"\$O/$SV$PJ $NO1$NO2 (commentaire : jamais compté)" > "$WORK/k1.txt"
assert_eq "AM7.K1 — le détecteur nomme les trois formes brutes (node, \$NODE avec arguments, --import) et ignore le commentaire ; il voit une ligne dans test-cockpit-questions.sh (pas aveugle)" "$(cockpit_lancement_brut "$WORK/k1.txt" | grep -c .) $([ "$(cockpit_lancement_brut "$DIR_T/test-cockpit-questions.sh" | grep -c .)" -ge 1 ] && echo voit || echo aveugle)" "3 voit"
cp "$DIR_T/test-cockpit-assemblage.sh" "$WORK/k2-intacte.sh"; cp "$WORK/k2-intacte.sh" "$WORK/k2-augmentee.sh"
printf '%s\n' "node \"\$OUT/$SV$PJ $NO1$NO2 --port 1 &" >> "$WORK/k2-augmentee.sh"
assert_eq "AM7.K2 — copie de test-cockpit-assemblage.sh (migrée) : intacte non nommée, augmentée d'une ligne de lancement brute nommée" "intacte=$(cockpit_lancement_brut "$WORK/k2-intacte.sh" | grep -c .) augmentee=$(cockpit_lancement_brut "$WORK/k2-augmentee.sh" | grep -c .)" "intacte=0 augmentee=1"
K3_FICHIERS=""; for f in "$DIR_T"/test-*.sh; do case " $EXC_LANCEMENT " in *" $(basename "$f") "*) continue ;; esac; K3_FICHIERS="$K3_FICHIERS $f"; done
# base (aide absente) : même motif posé en ligne, pour mesurer la classe avant la migration
brut_base() { local f; for f in "$@"; do grep -n -E "$SV\\$PJ[^|]* $NO1$NO2|$IMP$ORT [^|]* $NO1$NO2" "$f" 2> /dev/null | grep -v -E '^[0-9]+:[[:space:]]*#' | sed "s#^#$f:#"; done; }
DET=cockpit_lancement_brut; [ "$AIDE" = oui ] || DET=brut_base
# shellcheck disable=SC2086
K3_N="$($DET $K3_FICHIERS | cut -d: -f1 | sort -u | awk 'END { print NR }')"
assert_eq "AM7.K3 — aucune suite hors exceptions ne lance le serveur à la main (suites nommées par le détecteur ; base : 43)" "$K3_N" "0"
vf_hyg_assert

echo "== bilan : $PASS réussi(s), $FAIL échec(s) =="
[ "$FAIL" -eq 0 ]
