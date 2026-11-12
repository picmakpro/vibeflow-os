#!/usr/bin/env bash
# test-cockpit-lancer-xss.sh — la chaîne XSS prolongée jusqu'au LANCEMENT : « page P compromise -> serveur P -> Q -> shell -> faux claude »
# (TERM-12 étendue ; LANC-04, LANC-05, LANC-07, LANC-09 ; P72-D-09 à P72-D-14 ; plan 72-11).
# Hypothèse : la charge S'EXÉCUTE dans P (échappement et CSP retirés : M-ESC et M-CSP). Elle peut FAIRE NAÎTRE une proposition (POST /api/vf/lancer, jeton de la page) ;
# elle ne peut ni la confirmer, ni l'écrire au shell, ni lire ou écrire le mode retenu dans Q. Le succès de la chaîne est l'argv du faux `claude` (écrit par le shell).
# Manches (serveur P et processus de Q réels, vrai shell, faux claude ; mutants posés sur une COPIE de la sortie construite) :
#   LEG   chaîne légitime (témoin positif : proposition de P, lecture, armement, 204, ligne à l'invite, argv absent sans Entrée, présent et conforme après)
#   C0l   témoin : Q privée de ses contrôles -> la chaîne ABOUTIT (argv présent, ligne à l'invite) ; sans lui, aucune manche d'absence ne prouve rien
#   C1l   code livré : argv absent, ligne absente, stockage et mode de Q illisibles, cadre, messages et fenêtres sans effet
#   C2l à C5l   un seul contrôle gardé (Origin, secret, onglet, identifiant) : chacun, seul, casse la chaîne
#   DORIG dégradée : secret, onglet et identifiant connus, Origin de P : 403 ; puis M-ORIGINE-LANCER : 204 (l'Origin de /lancer tient seule)
#   M-SANS-CONFIRM (Q écrit sans POST /lancer) · M-ENTREE-AUTO (retour chariot ajouté) · M-INTERPOLE (le titre de la carte traverse le canal) : chacun rougit sa sonde
#   RES   RÉSIDUEL ACCEPTÉ (P72-D-22), CARACTÉRISATION, jamais une protection : un script de P sans geste pose sa question au chat, POSTe /api/vf/lancer avec l'UUID lu : 202, case DÉCOCHÉE dans Q, aucun octet au shell, aucun argv ;
#         mutants M-CASE-COCHEE, M-SANS-CONFIRM, M-SANS-CONFIRM + M-ENTREE-AUTO : chacun rougit sa sonde
#   TIT   titres hostiles : 0 violation CSP, window.__titre3 indéfini (CSP en place, puis CSP retirée), témoin de la mesure
# Mutants de la 71 recopiés tels quels de test-cockpit-terminal-xss.sh (M-ESC, M-CSP, M-ORIGINE-TERM, M-SECRET-TERM, M-ONGLET-TERM) ; ceux de la 72 viennent des ancres de 72-09 et 72-10 ;
# M-ONGLET-SESSION (contrôle d'onglet propre de sessions.lancer, 72-02) s'y ajoute chaque fois que l'onglet est retiré. Un mutant sans effet est un FAIL nommé.
# Sans Chrome (ou CHAINE_SANS_NAVIGATEUR=1) : SIMULATION FIDÈLE de la partie HTTP (un client node rejoue les requêtes de la charge) ; la partie navigateur est annoncée « NON vérifiée, non comptée ».
# Volet terminal : test-cockpit-terminal-xss.sh (Phase 71), qui n'est pas modifié.
# Exit 0 si tout passe, 1 sinon.
set -uo pipefail
libre() { local p; while :; do p="$(node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})")"; [ "$p" -ge 4600 ] && [ "$p" -ne 4456 ] && { echo "$p"; return; }; done; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"; TA="$HERE_T/terminal-aux.mjs"
ENG="$(cd "$SCRIPTS/../skills/cockpit-moteur" && pwd -P)"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude/scripts" "$WORK/bin" "$WORK/fauxbin"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
export VF_COCKPIT_MODE_DIR="$WORK/etat"; unset XDG_CACHE_HOME # AUDC-B-05 : le mode retenu d'un lancement accepté va dans un dossier jetable, jamais dans le dossier d'état réel de l'utilisateur ni de la CI
export CHROME_SESSION="$HERE_T/chrome-session.mjs"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"
PASS=0; FAIL=0; NONVERIF=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
nonverif() { echo "  ⊘ $1 — NON vérifiée sans navigateur, non comptée comme réussie"; NONVERIF=$((NONVERIF+1)); }

CHROME=""
for c in "${CHROME_BIN:-}" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome google-chrome-stable chromium chromium-browser; do
  [ -n "$c" ] || continue
  if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then CHROME="$c"; break; fi
done
[ -n "${CHAINE_SANS_NAVIGATEUR:-}" ] && CHROME=""
echo "navigateur : ${CHROME:-aucun (simulation fidèle de la partie HTTP)}"
command -v python3 >/dev/null 2>&1 || { echo "  ❌ python3 introuvable : le terminal est indisponible" >&2; exit 1; }

# clé de stockage de Q sondée par la charge de P (LANC-09) : relevée dans le client de Q, jamais écrite ici.
# 72-16 a retiré la constante CLE_MODE (le mode est servi par Q et persisté dans un fichier du lab, P72-D-20) : on sonde donc une clé VIVANTE, le secret de session de Q.
CLE_STOCK="$(sed -n "s/^.*CLE_SECRET = '\\([^']*\\)'.*\$/\\1/p" "$SCRIPTS/../skills/cockpit-moteur/assets/ui/terminal/client.js" | head -1)"
assert_eq "clé de stockage de Q sondée relevée dans client.js de la page de Q (constante CLE_SECRET, clé vivante) : clé introuvable sinon" "$CLE_STOCK" "vf.terminal.secret"

# faux claude (témoin neuf), shell de test (PL-11.4 : echo $$ puis exec bash, invite VFP> ), PATH d'ORIGINE du shell seulement (PL-11.3)
cp "$HERE_T/temoins/lancer-fauxbin/claude" "$WORK/fauxbin/claude"; chmod +x "$WORK/fauxbin/claude"
cat > "$WORK/bin/rc" <<'SH'
PS1='VFP> '; unset PROMPT_COMMAND; bind 'set enable-bracketed-paste off' 2>/dev/null
SH
cat > "$WORK/bin/shell-test" <<SH
#!/bin/sh
echo \$\$ > "\$FAUX_CLAUDE_SORTIE/shell.pid"
exec /bin/bash --rcfile "$WORK/bin/rc" -i
SH
chmod +x "$WORK/bin/shell-test"; export SHELL="$WORK/bin/shell-test"
export VF_COCKPIT_PATH_ORIGINE="$WORK/fauxbin:$PATH"

# --- aides node ---
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
rj() { printf '%s\n' "$1" | node "$AUX/ev.mjs" "$2" 2>/dev/null; }
cat > "$AUX/payload.mjs" <<'JS'
// payload.mjs <charge.js> <cible> <cle> <id1> <id2> : la balise <img onerror=eval(atob('…'))> (commentaires de ligne retirés, constantes posées, base64 sans remplissage)
import fs from 'node:fs';
const [, , f, cible, cle, id1, id2] = process.argv;
let js = fs.readFileSync(f, 'utf8').split('\n').filter((l) => !/^\s*\/\//.test(l)).join('\n').replace(/__CIBLE__/g, cible).replace(/__CLE_STOCK__/g, cle).replace(/__ID1__/g, id1).replace(/__ID2__/g, id2);
js = js.replace(/\s*\n\s*/g, ' ').trim(); while (Buffer.byteLength(js) % 3) js += ' ';
console.log(`<img src=x onerror=eval(atob('${Buffer.from(js).toString('base64')}'))>`);
JS
cat > "$AUX/legit.mjs" <<'JS'
// legit.mjs : le client légitime de Q (secret et onglet de la session ; Origin de Q), pour la proposition.
//   lire <q> <secret> <onglet>            : corps JSON de GET /proposition (une ligne), « ERREUR » sinon
//   armer <q> <secret> <onglet> <ms>      : sonde GET /proposition jusqu'à « en-attente » (échéance <ms>), attend arme_apres_ms (lu dans la réponse) plus 400 ms, rend le corps ; « ABSENTE » sinon
import http from 'node:http';
const [, , cmd, q, secret, onglet, ms] = process.argv;
const lire = () => new Promise((resolve) => {
  const r = http.request({ host: '127.0.0.1', port: Number(q), path: '/proposition', method: 'GET', agent: false,
    headers: { Host: `127.0.0.1:${q}`, Origin: `http://127.0.0.1:${q}`, 'X-VF-Terminal': secret, 'X-VF-Onglet': onglet } }, (res) => {
    const m = []; res.on('data', (c) => m.push(c)); res.on('end', () => { try { resolve(JSON.parse(Buffer.concat(m).toString('utf8'))); } catch { resolve(null); } });
  });
  r.setTimeout(5000, () => { r.destroy(); resolve(null); }); r.on('error', () => resolve(null)); r.end();
});
const pause = (t) => new Promise((r) => setTimeout(r, t));
if (cmd === 'lire') { const c = await lire(); console.log(c ? JSON.stringify(c) : 'ERREUR'); }
else if (cmd === 'armer') {
  const fin = Date.now() + Number(ms); let c = null;
  while (Date.now() < fin) { c = await lire(); if (c && c.etat === 'en-attente') break; c = null; await pause(100); }
  if (!c) console.log('ABSENTE'); else { await pause(Number(c.arme_apres_ms) + 400); console.log(JSON.stringify(c)); }
}
JS

# --- lab piégé PARTITIONNÉ (PL-11.1) : phase 1 porte la charge dans `wave:` ; titres hostiles aux phases 2 à 4 ; phase 4 lançable ---
ID1=0123456789abcdef0123456789abcdef; ID2=fedcba9876543210fedcba9876543210
PAYLOAD="$(node "$AUX/payload.mjs" "$HERE_T/temoins/lancer-charge.js" ph-1 "$CLE_STOCK" "$ID1" "$ID2")"
LAB="$WORK/lab"; B="$LAB/.planning/workstreams/fiabilite"; mkdir -p "$LAB/src" "$B/phases/01-x" "$B/phases/04-y"
printf 'export const util = () => 1;\n' > "$LAB/src/util.js"; printf 'fiabilite\n' > "$LAB/.planning/active-workstream"
cat > "$B/ROADMAP.md" <<'RM'
## Phases

- [ ] **Phase 1: Socle** - premier jet
- [ ] **Phase 2: "; touch MARQ-TITRE #** - titre hostile
- [ ] **Phase 3: <img src=x onerror=window.__titre3=1>** - titre hostile
- [ ] **Phase 4: x' --permission-mode 'bypassPermissions** - rupture de guillemet

### Phase 1: Socle
**Goal**: Poser le socle

### Phase 2: "; touch MARQ-TITRE #
**Goal**: Autre

### Phase 3: <img src=x onerror=window.__titre3=1>
**Goal**: Autre

### Phase 4: x' --permission-mode 'bypassPermissions
**Goal**: Autre
RM
printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0 MVP\n---\n' > "$B/STATE.md"
printf -- '---\nwave: %s\n---\n<objective>Faire le socle</objective>\n' "$PAYLOAD" > "$B/phases/01-x/01-01-PLAN.md"
printf -- '---\nwave: 1\nfiles_modified: [src/util.js]\n---\n<objective>Quatre</objective>\n' > "$B/phases/04-y/04-01-PLAN.md"
git -C "$LAB" init -q && git -C "$LAB" add -A && git -C "$LAB" -c user.email=t@t -c user.name=t commit -q -m init
node "$SCRIPTS/vf-cockpit-build.mjs" "$LAB" --quiet > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
SORTIE="$LAB/.vibeflow/cockpit"
[ -f "$SCRIPTS/vf-cockpit-lancer.mjs" ] || echo "  ❌ le module testé ne porte pas vf-cockpit-lancer.mjs" >&2   # 79-06 : le code vit dans le module, la sortie ne porte que des données

# --- mutants (liste du plan) ; sed -i.bak ; un mutant sans effet ou à ancre absente est un FAIL nommé ---
cat > "$AUX/interp-p.sed" <<'SED'
s#t: 'proposition',#t: 'proposition', titre: String(([...dernier.phases.values()].find((p) => p.n === cible.phase \&\& (p.ws || null) === cible.ws) || {}).name || ''),#
SED
cat > "$AUX/interp-q.sed" <<'SED'
s#^( *)const recevoirProposition = (.*);$#\1const recevoirProposition = (m) => { globalThis.__titre = String(m.titre || ""); (\2)(m); };#
s#^( *)const gabaritQ = (.*);$#\1const gabaritQ = { ...(\2), lignesParModes: (a) => { const r = (\2).lignesParModes(a); if (r.ok) for (const k of Object.keys(r.lignes)) r.lignes[k] = r.lignes[k].slice(0, -1) + " " + String(globalThis.__titre || "") + r.lignes[k].slice(-1); return r; }, validerLigne: () => ({ ok: true }) };#
SED
cat > "$AUX/sans-confirm.sed" <<'SED'
s#^( *)const recevoirProposition = (.*);$#\1const recevoirProposition = (m) => { (\2)(m); const t = setInterval(async () => { if ((await lancer({ id: lireProposition().id, mode: "herite" }, proprietaire)) === 204) clearInterval(t); }, 200); setTimeout(() => clearInterval(t), 20000); };#
SED
cat > "$AUX/entree-auto.sed" <<'SED'
s|^        vers_shell += ligne$|        vers_shell += ligne + bytes([13])|
SED
MUTFILES=(serve.mjs index.html project.html vf-cockpit-terminal-processus.mjs vf-cockpit-terminal-session.mjs vf-cockpit-lancer.mjs vue.js)
# 79-06 : la sortie (MUT_OUT) ne porte que des pages ; le code muté vit dans une COPIE du module (MUT_MOD), une par manche, mutée sur place
MUT_OUT=""; MUT_MOD=""
fichier_de() { case "$1" in index.html|project.html) printf '%s\n' "$MUT_OUT/$1" ;; serve.mjs) printf '%s\n' "$MUT_MOD/skills/cockpit-moteur/assets/serve.mjs" ;; vue.js) printf '%s\n' "$MUT_MOD/skills/cockpit-moteur/assets/ui/terminal/vue.js" ;; *) printf '%s\n' "$MUT_MOD/scripts/$1" ;; esac; }
empreinte() { local f; for f in "${MUTFILES[@]}"; do cat "$(fichier_de "$f")"; done | cksum; } # chaque fichier ; une pièce d'un mutant qui touche deux fichiers se contrôle à part
# mutant <sortie> <nom> : 0 si le texte a changé ; 1 sinon (message sur stderr) ; le code est muté dans MUT_MOD, les pages dans la sortie
mutant() {
  local o="$1" m="$2" p="$MUT_MOD/scripts/vf-cockpit-terminal-processus.mjs" s="$MUT_MOD/scripts/vf-cockpit-terminal-session.mjs" l="$MUT_MOD/scripts/vf-cockpit-lancer.mjs" sv="$MUT_MOD/skills/cockpit-moteur/assets/serve.mjs" avant apres a2 b2
  avant="$(empreinte "$o")"
  case "$m" in
    M-ESC) for f in index.html project.html; do sed -i.bak 's#<span class="meta">${h(size)}</span>#<span class="meta">${size}</span>#' "$o/$f"; done ;;
    M-CSP) sed -i.bak "s#res.setHeader('Content-Security-Policy'#res.setHeader('X-Mutant-Csp'#g" "$sv" ;;
    M-ORIGINE-TERM) sed -i.bak "s/if (!page \&\& !navigateur) return /if (false) return /; s/else if (o !== origineQ())/else if (false)/" "$p" ;;
    M-SECRET-TERM) sed -i.bak "s/if (!egal(req.headers\['x-vf-terminal'\], secret)) return refus(res, 401, 'secret');//" "$p" ;;
    M-ONGLET-TERM) sed -i.bak "s/if (s.onglet !== onglet) return 409;//g" "$s" ;;
    M-ONGLET-LANCER) sed -i.bak 's#if (onglet !== proprietaire) return 409;##' "$p" ;;
    M-ID-LIBRE) sed -i.bak 's#const idDemande = demande.id;#const idDemande = lireProposition().id;#' "$p" ;;
    M-ONGLET-SESSION) sed -i.bak "s#if (!actif(c) || c.onglet !== onglet) return non('absente');#if (!actif(c)) return non('absente');#" "$s" ;;
    M-ORIGINE-LANCER) sed -i.bak "s#else if (o !== origineQ())#else if (o !== origineQ() \\&\\& !(url.pathname === '/lancer' \\&\\& o === 'http://127.0.0.1:' + portP))#" "$p" ;;
    M-SANS-CONFIRM) sed -i.bak -E -f "$AUX/sans-confirm.sed" "$p" ;;
    M-CASE-COCHEE) sed -i.bak "s#caseChat.type = 'checkbox';#caseChat.type = 'checkbox'; caseChat.checked = true;#" "$MUT_MOD/skills/cockpit-moteur/assets/ui/terminal/vue.js" ;;
    M-INTERPOLE)
      # trois remplacements, un seul mutant : chacun doit avoir un effet
      a2="$(cksum < "$l")"; sed -i.bak -E -f "$AUX/interp-p.sed" "$l"; [ "$a2" != "$(cksum < "$l")" ] || { echo "  ❌ mutant M-INTERPOLE (P) sans effet : ancre absente (t: 'proposition',)" >&2; return 1; }
      a2="$(cksum < "$p")"; sed -i.bak -E -e "$(sed -n 1p "$AUX/interp-q.sed")" "$p"; [ "$a2" != "$(cksum < "$p")" ] || { echo "  ❌ mutant M-INTERPOLE (Q1) sans effet : ancre absente (const recevoirProposition)" >&2; return 1; }
      b2="$(cksum < "$p")"; sed -i.bak -E -e "$(sed -n 2p "$AUX/interp-q.sed")" "$p"; [ "$b2" != "$(cksum < "$p")" ] || { echo "  ❌ mutant M-INTERPOLE (Q2) sans effet : ancre absente (const gabaritQ)" >&2; return 1; } ;;
    *) echo "  ❌ mutant inconnu : $m" >&2; return 1 ;;
  esac
  apres="$(empreinte "$o")"
  [ "$avant" != "$apres" ] || { echo "  ❌ mutant $m sans effet (motif absent du module ou de la sortie)" >&2; return 1; }
}
nassistants() { ps -eo pid=,ppid=,args= | awk -v p="$1" '$2 == p && /vf-cockpit-pty\.py/ { n++ } END { print n + 0 }'; }
assistants_srv() { local c n=0; for c in $(pgrep -P "$1" 2>/dev/null); do ps -o command= -p "$c" 2>/dev/null | grep -q 'vf-cockpit-terminal-processus.mjs' && n=$((n + $(nassistants "$c"))); done; echo $((n + $(nassistants "$1"))); }

ptok() { node -e "
  const http=require('http');http.get({host:'127.0.0.1',port:$1,path:'/project.html',headers:{Host:'127.0.0.1:$1'}},r=>{let b='';r.on('data',c=>b+=c);r.on('end',()=>{const m=/VF_COCKPIT_SERVER=\{\"token\":\"([0-9a-f]*)\"/.exec(b);console.log(m?m[1]:'')})})"; }
cible_body() { node "$TA" req "$1" GET /api/vf/lancer/cibles --jeton "$2" | sed '1,2d' | node "$AUX/ev.mjs" '(c=>c?JSON.stringify({cible:c.id,verbe:c.principal}):"")(j.cibles.find(x=>x.id==="'"$3"'"))' 2>/dev/null; }
proposer() { local b; b="$(cible_body "$1" "$2" "$3")"; [ -n "$b" ] || { echo "cible-absente"; return; }; node "$TA" req "$1" POST /api/vf/lancer --jeton "$2" --entete 'Content-Type:application/json' --corps "$b" | sed -n 1p; }
attend_argv() { local i; for i in $(seq 1 $(( $1 * 5 ))); do [ -e "$RUN/argv" ] && return 0; sleep 0.2; done; return 1; }
etat_prop() { rj "$(node "$AUX/legit.mjs" lire "$q" "$sec" onglet-A)" '(j.etat==="en-attente"?"en-attente phase="+j.phase+" ws="+j.ws:j.etat)'; }

# --- scénarios (jouent après l'invite ; posent R_*) ---
sc_legit() { # LEG : cible ph-4, client légitime
  local tok body arm id lj; tok="$(ptok "$port")"
  R_S202="$(proposer "$port" "$tok" ph-4)"
  arm="$(node "$AUX/legit.mjs" armer "$q" "$sec" onglet-A 15000)"; R_ARM="$arm"
  id="$(rj "$arm" 'j.id' 2>/dev/null)"; R_LH="$(rj "$arm" 'j.lignes.herite')"; R_PHASE="$(rj "$arm" '"phase="+j.phase+" ws="+j.ws+" etat="+j.etat')"
  lj="$(printf '{"id":"%s","mode":"herite"}' "$id")"
  R_S204="$(node "$TA" req "$q" POST /lancer --secret "$sec" --onglet onglet-A --corps "$lj" | sed -n 1p)"
  R_LIGNE_OK="$(node "$TA" attendre "$FLUX" "${R_LH:-LIGNE-ABSENTE}" 8000)"
  sleep 2; R_ARGV_AVANT=non; [ -e "$RUN/argv" ] && R_ARGV_AVANT=oui
  node "$TA" entree "$q" "$sec" onglet-A '\r' > /dev/null
  attend_argv 10 && R_ARGV_APRES=oui || R_ARGV_APRES=non
  R_ARGV_TXT=""; [ -e "$RUN/argv" ] && R_ARGV_TXT="$(tr '\0' '|' < "$RUN/argv")"
  R_ARGV_N=0; [ -e "$RUN/argv" ] && R_ARGV_N="$(tr -cd '\0' < "$RUN/argv" | wc -c | tr -d ' ')"
}
sc_degradee() { # DORIG : tout est connu de l'attaquant sauf l'Origin de Q (secret, onglet, identifiant) ; Origin de P
  local tok arm id lj; tok="$(ptok "$port")"
  R_S202="$(proposer "$port" "$tok" ph-4)"; arm="$(node "$AUX/legit.mjs" armer "$q" "$sec" onglet-A 15000)"
  id="$(rj "$arm" 'j.id' 2>/dev/null)"; R_LH="$(rj "$arm" 'j.lignes.herite')"; lj="$(printf '{"id":"%s","mode":"herite"}' "$id")"
  R_D_P="$(node "$TA" req "$q" POST /lancer --origin "http://127.0.0.1:$port" --secret "$sec" --onglet onglet-A --corps "$lj" | sed -n 1p)"
  R_D_PL="$(node "$TA" attendre "$FLUX" "${R_LH:-LIGNE-ABSENTE}" 3000)"
  R_D_Q="-"; R_D_QL="-"
  if [ "$R_D_P" != 204 ]; then
    R_D_Q="$(node "$TA" req "$q" POST /lancer --secret "$sec" --onglet onglet-A --corps "$lj" | sed -n 1p)"
    R_D_QL="$(node "$TA" attendre "$FLUX" "${R_LH:-LIGNE-ABSENTE}" 8000)"
  fi
}
sc_auto() { # M-SANS-CONFIRM : une proposition, lue et armée, AUCUN POST /lancer
  local tok arm; tok="$(ptok "$port")"
  R_S202="$(proposer "$port" "$tok" ph-4)"; arm="$(node "$AUX/legit.mjs" armer "$q" "$sec" onglet-A 15000)"; R_ARM="$arm"
  R_AUTO_L="$(node "$TA" attendre "$FLUX" 'claude --session-id' 3000)"
}
sc_titres() { # TIT : page P non compromise, CSP en place (ou retirée par le mutant de la manche)
  [ -n "$CHROME" ] || return 0
  R_XSS="$(node "$HERE_T/temoins/lancer-xss.mjs" "$CHROME" "{\"mode\":\"titres\",\"url\":\"http://127.0.0.1:$port/project.html#v=n:ph-3\"}")"
}
sc_charge() { # la charge de P compromise (Chrome), ou la partie HTTP rejouée par un client node
  local tok
  if [ -n "$CHROME" ]; then
    R_XSS="$(node "$HERE_T/temoins/lancer-xss.mjs" "$CHROME" "{\"mode\":\"charge\",\"url\":\"http://127.0.0.1:$port/project.html#v=n:ph-1\",\"q\":\"$q\",\"secret\":\"$sec\",\"onglet\":\"onglet-A\",\"cle\":\"$CLE_STOCK\"}")"
  else
    local a b c d e lj1 lj2 pr arm; tok="$(ptok "$port")"; pr="$(proposer "$port" "$tok" ph-1)"
    arm="$(node "$AUX/legit.mjs" armer "$q" "$sec" onglet-A 15000)"
    lj1="$(printf '{"id":"%s","mode":"herite"}' "$ID1")"; lj2="$(printf '{"id":"%s","mode":"herite"}' "$ID2")"
    a="$(node "$TA" req "$q" POST /lancer --origin "http://127.0.0.1:$port" --corps "$lj1" | sed -n 1p)"
    # l'identifiant deviné ne vaut rien sans M-ID-LIBRE : la requête rejouée est la même que celle du navigateur
    b="$(node "$TA" req "$q" POST /lancer --origin "http://127.0.0.1:$port" --corps "$lj2" | sed -n 1p)"
    c="$(node "$TA" req "$q" POST /lancer --origin "http://127.0.0.1:$port" --secret "$tok" --onglet forge --corps "$lj1" | sed -n 1p)"
    d="$(node "$TA" req "$q" GET /proposition --origin "http://127.0.0.1:$port" --secret "$tok" | sed -n 1p)"
    e="$(node "$TA" req "$q" POST /entree --origin "http://127.0.0.1:$port" --corps '\r' | sed -n 1p)"
    R_XSS="{\"simule\":true,\"propose\":\"$pr\",\"arme\":$([ "$arm" != ABSENTE ] && echo '"armee"' || echo '"proposition-jamais-vue"'),\"lancer1\":\"$a\",\"lancer2\":\"$b\",\"lancerJeton\":\"$c\",\"proposition\":\"$d\",\"entree\":\"$e\"}"
  fi
}

# manche <étiquette> <scénario> <mutants...> : sortie copiée, mutants posés, serveur avec --terminal, session légitime, scénario, observables (PL-11.6)
# résultat : R_ERR (vide si la manche s'est jouée), R_ARGV, R_LIGNE, R_MARQ, R_AV, R_AP, R_SESS, R_PROP, R_XSS et ceux du scénario
manche() {
  local label="$1" scen="$2"; shift 2
  R_ERR=""; R_XSS=""; R_ARGV=non; R_LIGNE=non; R_MARQ=non; R_AV=?; R_AP=?; R_SESS=?; R_PROP=?
  # le moteur déduit la racine du lab de l'emplacement de la sortie (<lab>/.vibeflow/cockpit) : chaque manche a donc sa copie complète du lab
  local L="$WORK/lab-$label" ENG_USE m o; rm -rf "$L"; cp -R "$LAB" "$L"; o="$L/.vibeflow/cockpit"
  MUT_OUT="$o"; rm -rf "$WORK/mod-$label"; MUT_MOD="$(cockpit_module_copie "$WORK/mod-$label")" || R_ERR="copie du module impossible"; ENG_USE="$MUT_MOD/skills/cockpit-moteur"
  RUN="$WORK/run-$label"; rm -rf "$RUN"; mkdir -p "$RUN"; export FAUX_CLAUDE_SORTIE="$RUN"
  for m in "$@"; do
    [ -z "$R_ERR" ] || break
    if [ "$m" = M-ENTREE-AUTO ]; then # même fichier cible, même expression que test-cockpit-lancer-pty.sh (72-02) : le moteur de la copie du module
      local f="$ENG_USE/terminal/vf-cockpit-pty.py"; cp "$f" "$f.orig"; sed -i.bak -f "$AUX/entree-auto.sed" "$f"
      cmp -s "$f" "$f.orig" && { R_ERR="mutant M-ENTREE-AUTO sans effet"; echo "  ❌ mutant M-ENTREE-AUTO sans effet (expression absente de vf-cockpit-pty.py)" >&2; break; }; rm -f "$f.orig" "$f.bak"
    else mutant "$o" "$m" || { R_ERR="mutant $m sans effet"; break; }; fi
  done
  assert_eq "[$label] — la manche se joue : tous les mutants posés ont un effet" "$R_ERR" ""
  [ -z "$R_ERR" ] || return 0
  rm -f "$o/.cache/server.json"; mkdir -p "$o/.cache"
  local amorce; amorce="$(node -e "console.log(require('crypto').randomBytes(24).toString('hex'))")"; (umask 077; printf '%s' "$amorce" > "$o/.cache/terminal-amorce"; printf '%s' "$amorce" > "$WORK/amorce.copy")
  COCKPIT_MODULE="$MUT_MOD" COCKPIT_SORTIE="$o" COCKPIT_PRET=terminal COCKPIT_LOG="$WORK/serve-$label.out" cockpit_lancer "$L" VF_COCKPIT_ENGINE_DIR="$ENG_USE" VF_COCKPIT_SCRIPTS_DIR="$MUT_MOD/scripts" --terminal
  local pid="$VF_PID"
  port="${VF_PORT:-0}"; q="$(node "$AUX/ev.mjs" '(j.terminal&&j.terminal.url)||""' < "$o/.cache/server.json")"; q="${q##*:}"
  local _c; sec=""; read -r _c sec < <(node "$TA" amorcer "$q" "$WORK/amorce.copy" | tr '\n' ' ')
  [[ "$sec" =~ ^[0-9a-f]{64}$ ]] || { R_ERR="session-impossible"; assert_eq "[$label] — session légitime établie" "$R_ERR" ""; vf_hyg_stop "$pid"; return 0; }
  FLUX="$WORK/flux-$label.bin"; rm -f "$FLUX"
  node "$TA" flux "$q" "$sec" onglet-A "$FLUX" 120000 --taille 24x400 > "$WORK/flux-$label.log" 2>&1 & local fpid=$!; PIDS+=($fpid)
  [ "$(node "$TA" attendre "$FLUX" 'VFP> ' 15000)" = TROUVE ] || { R_ERR="pas-d-invite"; assert_eq "[$label] — invite du shell vue" "$R_ERR" ""; vf_hyg_stop "$fpid"; vf_hyg_stop "$pid"; return 0; }
  R_AV="$(assistants_srv "$pid")"
  "$scen"
  # observables, après une courte grâce pour constater une ABSENCE (le témoin positif est joué par LEG et C0l)
  if [ "$scen" = sc_charge ] && { [ "$label" = C0l ] ; }; then attend_argv 20 || true; else sleep 3; fi
  [ -e "$RUN/argv" ] && R_ARGV=oui
  [ "$(node "$TA" attendre "$FLUX" 'claude --session-id' 300)" = TROUVE ] && R_LIGNE=oui
  [ -n "$(find "$WORK" -name 'MARQ-TITRE*' 2>/dev/null | head -1)" ] && R_MARQ=oui
  R_AP="$(assistants_srv "$pid")"; R_SESS="$(rj "$(node "$TA" etat "$q" "$sec" | sed -n 3p)" 'j.session')"; R_PROP="$(etat_prop)"
  echo "     [$label] mesure : argv=$R_ARGV ligne-à-l'invite=$R_LIGNE marqueur-titre=$R_MARQ assistants=$R_AV/$R_AP session=$R_SESS proposition=[$R_PROP] charge=${R_XSS:0:420}"
  vf_hyg_stop "$fpid"; vf_hyg_stop "$pid"
}
charge_ok() { # charge_ok <étiquette>
  if [ -n "$CHROME" ]; then assert_eq "$1.T0 — la charge s'exécute dans P compromise (drapeau posé, jeton lu, terminal actif, proposition née 202, armement passé, signal reçu)" "$(rj "$R_XSS" 'j.erreur||("debut="+j.debut+" jeton="+j.jeton+" terminal="+j.etat+" propose="+j.propose+" arme="+j.arme+" go="+j.go+" fin="+j.fin)')" "debut=true jeton=true terminal=actif propose=202 arme=armee go=true fin=true"
  else nonverif "$1.T0 la charge s'exécute dans P compromise"; assert_eq "$1.T0s — simulation HTTP : la proposition naît (202) et l'armement est passé" "$(rj "$R_XSS" 'j.propose+" "+j.arme')" "202 armee"; fi
}
LEG_OK=0; C0L_OK=0
blind() { # blind <étiquette> : une assertion d'absence sans témoin positif de la même observation est un FAIL nommé
  [ "$LEG_OK" = 1 ] && [ "$C0L_OK" = 1 ] || assert_eq "$1 — témoin positif (LEG, C0l) absent : l'absence ne prouve rien" "absent" "present"
}

echo "=== LEG — chaîne légitime (témoin positif : la ligne, l'argv, l'Entrée) ==="
manche LEG sc_legit
assert_eq "LEG.1 — POST /api/vf/lancer de P (Origin de P, jeton de page) pour ph-4 : 202 (P propose seulement)" "$R_S202" "202"
assert_eq "LEG.2 — le client légitime lit la proposition : en attente, phase 4, compartiment fiabilite" "$R_PHASE" "phase=4 ws=fiabilite etat=en-attente"
assert_eq "LEG.3 — après armement : POST /lancer {id, mode:herite} de l'onglet propriétaire : 204" "$R_S204" "204"
assert_eq "LEG.4 — la ligne herite de GET /proposition figure dans le flux du client (écrite à l'invite)" "$R_LIGNE_OK" "TROUVE"
assert_eq "LEG.5 — aucune Entrée tapée : l'argv du faux claude est ABSENT après 2 s (LANC-07)" "$R_ARGV_AVANT" "non"
LEGUU="$(printf '%s' "$R_LH" | sed -n "s/^claude --session-id '\\([0-9a-f-]*\\)'.*\$/\\1/p")"
LEGV="n=$R_ARGV_N"
[[ "$R_ARGV_TXT" =~ ^--session-id\|([0-9a-f-]{36})\|-n\|vf-phase-4-fiabilite\|/vf-dev\ (Cadre|Planifie|Execute|Verifie|Reprends)\ la\ Phase\ 4\ du\ compartiment\ fiabilite\|$ ]] && [ "${BASH_REMATCH[1]}" = "$LEGUU" ] && LEGV="$LEGV forme=oui" || LEGV="$LEGV forme=non"
case "$R_ARGV_TXT" in *permission-mode*) LEGV="$LEGV permission=oui" ;; *) LEGV="$LEGV permission=non" ;; esac
case "$R_ARGV_TXT" in *bypassPermissions*) LEGV="$LEGV bypass=oui" ;; *) LEGV="$LEGV bypass=non" ;; esac
case "$R_ARGV_TXT" in *touch*) LEGV="$LEGV touch=oui" ;; *) LEGV="$LEGV touch=non" ;; esac
assert_eq "LEG.6 — après l'Entrée du client : argv PRÉSENT, exactement cinq éléments (--session-id, UUID de la ligne, -n, vf-phase-4-fiabilite, /vf-dev …), ni --permission-mode, ni bypassPermissions, ni touch" "$R_ARGV_APRES $LEGV" "oui n=5 forme=oui permission=non bypass=non touch=non"
assert_eq "LEG.7 — le titre de rupture de guillemet n'a rien exécuté : aucun fichier MARQ-TITRE" "$R_MARQ" "non"
[ "$R_S202 $R_LIGNE_OK $R_ARGV_APRES" = "202 TROUVE oui" ] && LEG_OK=1

echo "=== C0l — témoin : Q privée de ses contrôles (Origin, secret, onglet de la 71 et de /lancer, identifiant), la chaîne doit ABOUTIR ==="
manche C0l sc_charge M-ESC M-CSP M-ORIGINE-TERM M-SECRET-TERM M-ONGLET-TERM M-ONGLET-LANCER M-ONGLET-SESSION M-ID-LIBRE
charge_ok C0l
assert_eq "C0l.1 — Q sans ses contrôles : l'argv du faux claude est PRÉSENT sans geste humain (la chaîne aboutit : sans ce témoin, les manches suivantes ne prouvent rien)" "$R_ARGV" "oui"
assert_eq "C0l.2 — la ligne claude --session-id a été écrite à l'invite par la charge" "$R_LIGNE" "oui"
[ "$R_ARGV$R_LIGNE" = "ouioui" ] && C0L_OK=1
[ "$C0L_OK" = 1 ] || echo "  ❌ chaîne incapable d'aboutir : les autres manches ne prouvent rien" >&2

echo "=== C1l — code livré (P compromise : M-ESC et M-CSP) : la proposition naît, jamais le lancement ==="
manche C1l sc_charge M-ESC M-CSP
charge_ok C1l; blind C1l
assert_eq "C1l.1 — argv ABSENT et aucune ligne claude --session-id à l'invite (no-cors, jeton de page, en-têtes forgés, identifiants devinés)" "$R_ARGV/$R_LIGNE" "non/non"
assert_eq "C1l.2 — aucun marqueur MARQ-TITRE, assistants 1/1, session vivante" "$R_MARQ/$R_AV/$R_AP/$R_SESS" "non/1/1/vivante"
assert_eq "C1l.3 — la charge a fait naître la proposition (ph-1) et ne l'a ni consommée ni remplacée : toujours en attente" "$R_PROP" "en-attente phase=1 ws=fiabilite"
if [ -n "$CHROME" ]; then
  assert_eq "C1l.4a — LANC-09 : depuis P, le stockage du cadre de Q lève SecurityError en lecture ET en écriture de la clé du secret de Q (témoin : le stockage de P lui-même est lisible)" "$(rj "$R_XSS" 'j.stockageLecture+"/"+j.stockageEcriture+"/"+j.stockageP')" "SecurityError/SecurityError/lisible"
  assert_eq "C1l.4b — le contenu du cadre de Q est illisible depuis P (null ou SecurityError)" "$(rj "$R_XSS" '(j.contenu==="null"||j.contenu==="SecurityError")')" "true"
  assert_eq "C1l.5 — iframe.click() et postMessage (chaîne, objet {id, mode}) : envoyés, sans effet (aucune ligne, proposition intacte)" "$(rj "$R_XSS" 'j.clicCadre+"/"+j.postMessage')/$R_LIGNE/$R_PROP" "envoye/envoye/non/en-attente phase=1 ws=fiabilite"
  assert_eq "C1l.5b — les tentatives de confirmation ont bien été faites (no-cors deux fois, jeton de page, lecture, écriture) : l'absence d'effet n'est pas une absence de tentative" "$(rj "$R_XSS" 'j.lancerNoCors1+"/"+j.lancerNoCors2+"/"+j.entree+"/"+(j.lancerJeton!==undefined)+"/"+(j.proposition!==undefined)')" "envoye/envoye/envoye/true/true"
  assert_eq "C1l.6a — window.open vers Q sans geste : bloqué, ou stockage de la fenêtre en SecurityError" "$(rj "$R_XSS" 'j.open==="bloque"||j.stockageFenetre==="SecurityError"')" "true"
  assert_eq "C1l.6b — window.open vers Q AVEC geste : la fenêtre s'ouvre (témoin), stockage lu et écrit en SecurityError ; aucun assistant de plus, aucun argv" "$(rj "$R_XSS" '(j.geste&&j.geste.open)+"/"+(j.geste&&j.geste.stockage)+"/"+(j.geste&&j.geste.ecriture)')/$R_AV/$R_AP/$R_ARGV" "ouvert/SecurityError/SecurityError/1/1/non"
else nonverif "C1l.4-C1l.6 (stockage, cadre, messages, fenêtres)"; fi

echo "=== C2l-C5l — un seul contrôle de Q gardé : chacun, seul, casse la chaîne ==="
manche C2l sc_charge M-ESC M-CSP M-SECRET-TERM M-ONGLET-TERM M-ONGLET-LANCER M-ONGLET-SESSION M-ID-LIBRE
charge_ok C2l; blind C2l
assert_eq "C2l — Origin SEULE gardée (secret, onglet et identifiant retirés) : argv absent, aucune ligne à l'invite" "$R_ARGV/$R_LIGNE" "non/non"
manche C3l sc_charge M-ESC M-CSP M-ORIGINE-TERM M-ONGLET-TERM M-ONGLET-LANCER M-ONGLET-SESSION M-ID-LIBRE
charge_ok C3l; blind C3l
assert_eq "C3l — secret SEUL gardé (Origin, onglet et identifiant retirés) : argv absent, aucune ligne à l'invite" "$R_ARGV/$R_LIGNE" "non/non"
manche C4l sc_charge M-ESC M-CSP M-ORIGINE-TERM M-SECRET-TERM M-ID-LIBRE
charge_ok C4l; blind C4l
assert_eq "C4l — onglet SEUL gardé (Origin, secret et identifiant retirés) : argv absent, aucune ligne à l'invite" "$R_ARGV/$R_LIGNE" "non/non"
manche C5l sc_charge M-ESC M-CSP M-ORIGINE-TERM M-SECRET-TERM M-ONGLET-TERM M-ONGLET-LANCER M-ONGLET-SESSION
charge_ok C5l; blind C5l
assert_eq "C5l — identifiant SEUL gardé (Origin, secret et onglet retirés) : argv absent, aucune ligne à l'invite" "$R_ARGV/$R_LIGNE" "non/non"

echo "=== DORIG — dégradée : secret, onglet et identifiant connus de l'attaquant, seule l'Origin de Q manque ==="
manche DORIG sc_degradee
assert_eq "DORIG.1 — Origin de P, secret, onglet et identifiant VALIDES, proposition armée : 403 et aucune ligne à l'invite" "$R_D_P/$R_D_PL" "403/ABSENT"
assert_eq "DORIG.2 — témoin : le même appel en Origin de Q rend 204 et la ligne apparaît" "$R_D_Q/$R_D_QL" "204/TROUVE"
manche DORIG-MUT sc_degradee M-ORIGINE-LANCER
assert_eq "M-ORIGINE-LANCER — le mutant rougit DORIG.3 : 204 au lieu de 403, et la ligne est à l'invite" "$R_D_P/$R_D_PL" "204/TROUVE"

echo "=== M-SANS-CONFIRM — Q écrit dès qu'une proposition est armée, sans geste ==="
manche MSC0 sc_auto
assert_eq "M-SANS-CONFIRM — code livré (témoin) : proposition armée et vue, aucun POST /lancer : aucune ligne à l'invite, proposition toujours en attente" "$R_AUTO_L/$R_PROP" "ABSENT/en-attente phase=4 ws=fiabilite"
manche MSC sc_auto M-SANS-CONFIRM
assert_eq "M-SANS-CONFIRM — le mutant rougit : une ligne à l'invite sans POST /lancer" "$R_AUTO_L" "TROUVE"

echo "=== M-ENTREE-AUTO — un retour chariot est ajouté à la ligne ==="
manche MEA sc_legit M-ENTREE-AUTO
assert_eq "M-ENTREE-AUTO — le mutant rougit LEG.5 : argv présent sans Entrée du client" "$R_S204/$R_ARGV_AVANT" "204/oui"

echo "=== M-INTERPOLE — le titre de la carte traverse le canal et entre dans la ligne ==="
manche MINT sc_legit M-INTERPOLE
MINTV="n=$R_ARGV_N"; case "$R_ARGV_TXT" in *bypassPermissions*) MINTV="$MINTV bypass=oui" ;; *) MINTV="$MINTV bypass=non" ;; esac
assert_eq "M-INTERPOLE — le mutant rougit LEG.6 : argv à plus de cinq éléments (le titre de rupture ferme le guillemet) et bypassPermissions présent" "$R_S204/$MINTV" "204/n=7 bypass=oui"

echo "=== TIT — titres hostiles : inertes, aucune violation de la CSP ==="
manche TIT sc_titres
if [ -n "$CHROME" ]; then
  assert_eq "TIT.0 — témoin : le titre hostile de la phase 3 est AFFICHÉ en texte (sans lui, zéro violation ne prouverait rien)" "$(rj "$R_XSS" 'j.erreur||j.affiche')" "true"
  assert_eq "TIT.1 — page P non compromise, CSP en place : 0 violation" "$(rj "$R_XSS" 'j.violations')" "0"
  assert_eq "TIT.2 — window.__titre3 est indéfini (la balise du titre ne s'exécute pas)" "$(rj "$R_XSS" 'j.titre3')" "undefined"
  assert_eq "TIT.3 — témoin de la mesure : une balise à gestionnaire en ligne insérée par la suite est comptée comme violation" "$(rj "$R_XSS" 'j.temoin>=1')" "true"
  manche TIT-CSP sc_titres M-CSP
  assert_eq "TIT.2b — CSP retirée (M-CSP) mais échappement en place : window.__titre3 reste indéfini, le titre est inerte" "$(rj "$R_XSS" 'j.erreur||j.titre3+"/"+j.affiche')" "undefined/true"
else nonverif "TIT.0-TIT.3 (titres hostiles rendus par la page, violations CSP)"; fi

echo "=== ACT — F-1 : la reprise du chat ne retient que l'UUID d'une question envoyée par un VRAI geste (P72-D-21) ==="
# Page hôte jetable (le vrai /api/ask exige claude) : elle installe installerObservateurChat du MODULE sur la vraie fenêtre ; un FAUX /api/ask (SSE, un UUID neuf par requête, documenté ici) tient la place du chat.
# La charge de P est jouée sans geste (script, puis click() programmatique) ; le témoin positif est un clic de confiance (Input.dispatchMouseEvent), qui produit une activation réelle.
cat > "$AUX/hote.mjs" <<'JS'
// hote.mjs <dossier-de-scripts-du-module> <port> : sert /hote.html, /ui.mjs (les deux fichiers du chat du moteur du module) et un FAUX POST /api/ask (SSE, événement answer, UUID neuf par requête)
import http from 'node:http'; import fs from 'node:fs'; import crypto from 'node:crypto';
const [, , dossier, port] = process.argv;
const PAGE = `<!doctype html><meta charset="utf-8"><body><button id="envoi" style="position:fixed;left:10px;top:10px;width:90px;height:40px">envoi</button><script type="module">
import { installerObservateurChat } from '/ui.mjs'; window.__retenu = []; installerObservateurChat(window, (id) => window.__retenu.push(id));
document.getElementById('envoi').addEventListener('click', () => { fetch('/api/ask', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ question: 'question humaine', mode: 'ask' }) }); });
window.__pret = true;</script>`;
http.createServer((req, res) => {
  const u = new URL(req.url, 'http://x');
  if (req.method === 'GET' && u.pathname === '/hote.html') { res.writeHead(200, { 'content-type': 'text/html' }); res.end(PAGE); return; }
  // 79-11 : les deux fonctions du chat sont des fichiers du moteur ; /ui.mjs les met bout à bout (même portée : l'une est la valeur par défaut de l'autre) et les exporte
  if (req.method === 'GET' && u.pathname === '/ui.mjs') { const d = dossier + '/../skills/cockpit-moteur/assets/ui/tiroir/'; res.writeHead(200, { 'content-type': 'text/javascript' }); res.end(fs.readFileSync(d + 'lancer-extraire-chat.js', 'utf8') + fs.readFileSync(d + 'lancer-observer-chat.js', 'utf8') + 'export { installerObservateurChat, extraireSessionChat };\n'); return; }
  if (req.method === 'POST' && u.pathname === '/api/ask') { req.resume(); req.on('end', () => { res.writeHead(200, { 'content-type': 'text/event-stream' }); res.end(`event: answer\ndata: ${JSON.stringify({ title: 'OK', answer: 'OK', items: [], session: crypto.randomUUID() })}\n\n`); }); return; }
  res.writeHead(404); res.end();
}).listen(Number(port), '127.0.0.1');
JS
if [ -n "$CHROME" ]; then
  act() { # act <dossier de scripts du module> -> UNE ligne JSON
    local hp hpid res; hp="$(libre)"; node "$AUX/hote.mjs" "$1" "$hp" & hpid=$!; PIDS+=($hpid)
    for _ in $(seq 1 50); do curl -s -o /dev/null "http://127.0.0.1:$hp/hote.html" && break; sleep 0.1; done
    res="$(node "$HERE_T/temoins/lancer-xss.mjs" "$CHROME" "{\"mode\":\"activation\",\"url\":\"http://127.0.0.1:$hp/hote.html\"}")"; vf_hyg_stop "$hpid"; printf '%s' "$res"
  }
  RACT="$(act "$SCRIPTS")"
  assert_eq "ACT.0 — témoin : avant tout geste la page n'a AUCUNE activation (sans lui, l'absence de reprise forgée ne prouverait rien)" "$(rj "$RACT" 'j.erreur||j.actif0')" "false"
  assert_eq "ACT.1 — la charge poste sa propre question (script, puis click() programmatique) : aucun UUID retenu, donc aucune reprise forgée à proposer" "$(rj "$RACT" 'j.erreur||j.forge+"/"+j.forgeClic')" "0/0"
  assert_eq "ACT.2 — témoin positif : un VRAI clic (Input.dispatchMouseEvent) sur l'envoi retient l'UUID de cette conversation, une activation est active" "$(rj "$RACT" 'j.erreur||j.humain+"/"+j.actifApresClic+"/"+/^[0-9a-f-]{36}$/.test(j.premier)')" "1/true/true"
  assert_eq "ACT.3 — activation expirée : une nouvelle requête de la charge n'efface ni ne remplace l'UUID retenu par le geste humain (rien n'est retenu de plus)" "$(rj "$RACT" 'j.erreur||j.inchange+"/"+j.apres')" "true/$(rj "$RACT" 'j.humain+j.residuel')"
  echo "  ℹ résiduel accepté (P72-D-21, Samuel, 2026-11-06) : pendant l'activation laissée par un geste réel, une requête de la charge est retenue — mesuré : $(rj "$RACT" 'j.residuel') UUID de plus"
  rm -rf "$WORK/mod-act"; MODACT="$(cockpit_module_copie "$WORK/mod-act")"; cp "$MODACT/skills/cockpit-moteur/assets/ui/tiroir/lancer-observer-chat.js" "$WORK/ui.orig"
  sed -i.bak 's/const humain = actif();/const humain = true;/' "$MODACT/skills/cockpit-moteur/assets/ui/tiroir/lancer-observer-chat.js"
  if cmp -s "$WORK/ui.orig" "$MODACT/skills/cockpit-moteur/assets/ui/tiroir/lancer-observer-chat.js"; then assert_eq "M-ACTIVATION-RETIREE — mutant sans effet (ancre absente)" "sans effet" "effet"
  else
    RMUT="$(act "$MODACT/scripts")"
    assert_eq "M-ACTIVATION-RETIREE — garde d'activation retirée : la charge fait retenir l'UUID de SA conversation (ACT.1 rougit : retenu au lieu de 0/0)" "$(rj "$RMUT" 'j.erreur||(j.forge>0)+"/"+(j.forgeClic>0)')" "true/true"
  fi
else nonverif "ACT.0-ACT.3 et M-ACTIVATION-RETIREE (activation utilisateur réelle sous navigateur)"; fi

echo "=== RES — RÉSIDUEL ACCEPTÉ P72-D-22 (caractérisation) : ce n'est PAS une protection ==="
# Un script qui s'exécute dans la page Projet, SANS aucune activation, pose sa question au chat (faux `claude -p` dans le PATH du SERVEUR : la vraie route /api/ask), lit l'UUID de la réponse,
# puis POSTe lui-même /api/vf/lancer {cible, verbe, chat:<uuid>} avec le jeton de la page. Comportement ACCEPTÉ (arbitrage Samuel, AskUserQuestion, session principale, 2026-11-06) : 202, la case « continuer le chat »
# apparaît dans Q, DÉCOCHÉE ; la seule barrière réelle est le clic et l'Entrée dans le terminal. Les sondes d'absence (case décochée, aucun octet, aucun argv) ont chacune leur mutant.
UUID_RES='5a5a5a5a-1111-4222-8333-444455556666'
mkdir -p "$WORK/askbin"; cp "$HERE_T/temoins/lancer-fauxbin/claude-ask" "$WORK/askbin/claude"; chmod +x "$WORK/askbin/claude"
# manche_res <étiquette> <mutants...> -> R_ERR R_RES R_ARGV ; serveur --terminal réel, AUCUN client node : le seul client de Q est Chrome
manche_res() {
  local label="$1"; shift
  R_ERR=""; R_RES=""; R_ARGV=non
  local L="$WORK/lab-$label" ENG_USE m o; rm -rf "$L"; cp -R "$LAB" "$L"; o="$L/.vibeflow/cockpit"
  MUT_OUT="$o"; rm -rf "$WORK/mod-$label"; MUT_MOD="$(cockpit_module_copie "$WORK/mod-$label")" || R_ERR="copie du module impossible"; ENG_USE="$MUT_MOD/skills/cockpit-moteur"
  RUN="$WORK/run-$label"; rm -rf "$RUN"; mkdir -p "$RUN"; export FAUX_CLAUDE_SORTIE="$RUN" FAUX_ASK_SESSION="$UUID_RES"
  for m in "$@"; do
    [ -z "$R_ERR" ] || break
    if [ "$m" = M-ENTREE-AUTO ]; then
      local f="$ENG_USE/terminal/vf-cockpit-pty.py"; cp "$f" "$f.orig"; sed -i.bak -f "$AUX/entree-auto.sed" "$f"
      cmp -s "$f" "$f.orig" && { R_ERR="mutant M-ENTREE-AUTO sans effet"; echo "  ❌ mutant M-ENTREE-AUTO sans effet (expression absente de vf-cockpit-pty.py)" >&2; break; }; rm -f "$f.orig" "$f.bak"
    else mutant "$o" "$m" || { R_ERR="mutant $m sans effet"; break; }; fi
  done
  assert_eq "[$label] — la manche se joue : tous les mutants posés ont un effet" "$R_ERR" ""
  [ -z "$R_ERR" ] || return 0
  rm -f "$o/.cache/server.json"; mkdir -p "$o/.cache"
  local amorce; amorce="$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")"; (umask 077; printf '%s' "$amorce" > "$o/.cache/terminal-amorce")
  COCKPIT_MODULE="$MUT_MOD" COCKPIT_SORTIE="$o" COCKPIT_PRET=terminal COCKPIT_LOG="$WORK/serve-$label.out" cockpit_lancer "$L" PATH="$WORK/askbin:$PATH" VF_COCKPIT_ENGINE_DIR="$ENG_USE" VF_COCKPIT_SCRIPTS_DIR="$MUT_MOD/scripts" --terminal
  local pid="$VF_PID"
  local rport rq; rport="${VF_PORT:-0}"; rq="$(node "$AUX/ev.mjs" '(j.terminal&&j.terminal.url)||""' < "$o/.cache/server.json")"; rq="${rq##*:}"
  R_RES="$(node "$HERE_T/temoins/lancer-xss.mjs" "$CHROME" "{\"mode\":\"residuel\",\"P\":$rport,\"Q\":$rq,\"amorce\":\"$amorce\",\"cible\":\"ph-4\"}")"
  sleep 2; [ -e "$RUN/argv" ] && R_ARGV=oui
  echo "     [$label] mesure : argv=$R_ARGV charge=${R_RES:0:900}"
  vf_hyg_stop "$pid"
}
res_charge() { rj "$R_RES" '(j.erreur ? "plante: "+j.erreur : (j.erreurs&&Object.keys(j.erreurs).length ? "erreurs: "+JSON.stringify(j.erreurs) : j.actifAvant+"/"+(j.charge&&j.charge.actif)+"/"+(j.charge&&j.charge.ask)+"/"+(j.charge&&j.charge.session)+"/"+(j.charge&&j.charge.lancer)))'; }
RES_CHARGE_ATTENDU="false/false/200/$UUID_RES/202"
if [ -n "$CHROME" ]; then
  manche_res RES
  assert_eq "RES.0 — témoin : la charge s'exécute SANS activation (avant et pendant), le chat répond (200, UUID de sa conversation), POST /api/vf/lancer avec ce chat : 202 (comportement accepté)" "$(res_charge)" "$RES_CHARGE_ATTENDU"
  assert_eq "RES.1 — [RÉSIDUEL ACCEPTÉ P72-D-22] la case « continuer le chat » apparaît dans le bandeau de Q, DÉCOCHÉE" "$(rj "$R_RES" 'JSON.stringify(j.case)')" '{"type":"checkbox","coche":false,"texte":"Continuer la conversation du chat"}'
  assert_eq "RES.2 — la ligne affichée (case décochée) est la ligne standard : ni -r, ni --fork-session, ni l'identifiant du chat de la charge" "$(rj "$R_RES" '(typeof j.ligne==="string"&&j.ligne.startsWith("claude --session-id ")&&!j.ligne.includes(" -r ")&&!j.ligne.includes("--fork-session")&&!j.ligne.includes("'"$UUID_RES"'"))')" "true"
  assert_eq "RES.2b — l'identifiant est affiché : une fois la case cochée (par script, dans Q seulement : geste humain simulé), la ligne porte -r '<identifiant>' --fork-session ; rien n'est envoyé" "$(rj "$R_RES" '(j.ligneCochee&&j.ligneCochee.coche===true&&j.ligneCochee.ligne.includes(" -r '"'$UUID_RES'"' --fork-session"))')" "true"
  assert_eq "RES.3 — aucun octet n'atteint le shell : le terminal de Q (invite lue, témoin) ne montre ni claude, ni --session-id, ni l'identifiant, après l'armement et une marge" "$(rj "$R_RES" '(typeof j.terminal==="string"&&/VFP>/.test(j.terminal)&&!/claude|--session-id|'"$UUID_RES"'/.test(j.terminal))')" "true"
  assert_eq "RES.4 — aucun argv : le faux claude du shell n'a rien reçu, faute de clic « Lancer » et d'Entrée dans Q (la charge a bien eu lieu : l'absence n'est pas une absence de tentative)" "$(res_charge)/$R_ARGV" "$RES_CHARGE_ATTENDU/non"
  manche_res RES-CASE M-CASE-COCHEE
  assert_eq "RES.1 / M-CASE-COCHEE — le mutant rougit la sonde : la case est COCHÉE par défaut et la ligne affichée porte l'identifiant" "$(rj "$R_RES" '(j.case&&j.case.coche)+"/"+(typeof j.ligne==="string"&&j.ligne.includes(" -r '"'$UUID_RES'"' --fork-session"))')" "true/true"
  manche_res RES-SANSCONF M-SANS-CONFIRM
  assert_eq "RES.3 / M-SANS-CONFIRM — le mutant rougit la sonde d'octets : Q écrit la ligne au shell sans POST /lancer (le terminal montre claude --session-id) ; la charge a bien fait naître la proposition" "$(res_charge)/$(rj "$R_RES" '(typeof j.terminal==="string"&&j.terminal.includes("claude --session-id"))')" "$RES_CHARGE_ATTENDU/true"
  assert_eq "RES.4 / M-SANS-CONFIRM — sans Entrée, l'argv reste ABSENT : la sonde d'argv ne rougit que si une Entrée existe (témoin de séparation des deux sondes)" "$(res_charge)/$R_ARGV" "$RES_CHARGE_ATTENDU/non"
  manche_res RES-ENTREE M-SANS-CONFIRM M-ENTREE-AUTO
  assert_eq "RES.4 / M-SANS-CONFIRM + M-ENTREE-AUTO — le mutant rougit la sonde d'argv : le faux claude du shell a reçu son argv sans clic ni Entrée dans Q (la charge a eu lieu, la ligne est au terminal)" "$(res_charge)/$R_ARGV/$(rj "$R_RES" '(typeof j.terminal==="string"&&j.terminal.includes("claude --session-id"))')" "$RES_CHARGE_ATTENDU/oui/true"
else nonverif "RES (résiduel accepté P72-D-22 : script de P, POST direct, case de Q, octets au shell)"; fi

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL ($NONVERIF non vérifiées sans navigateur)"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE — zéro assertion exécutée"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
