#!/usr/bin/env bash
# test-cockpit-terminal-serveur.sh — contrôles du serveur du terminal intégré et tenue des secrets
# (TERM-02, TERM-03 ; P71-D-09 à D-11 ; sondes T1 à T5 de 71-RESEARCH §8).
#   T0 le compteur d'assistants PTY voit un PTY (témoin de toutes les assertions « 0 assistant »)
#   T1 Origin tierce, Origin de P, Origin de Q (témoin) · T2 Host de rebinding, Host de P, localhost restreint à GET /
#   T3 sans secret, secret d'une autre longueur, secret faux, sans Origin, OPTIONS, corps bornés, en-têtes de toute réponse
#   T4 amorçage : usage unique, rejeu, suppression, lien symbolique, mode lâche, expiration à 60 s (T4.9), page de redirection retirée/balayée (T4.10, T4.11), absent des pages · T5 aucun secret dans aucune sortie
#   TD `Upgrade: websocket` jamais 101, secret en paramètre d'adresse refusé
#   S2  lecture du mode d'un fichier : même valeur sous macOS, GNU et uutils (faux `stat` des trois familles)
#   TC  T-71-10 : le secret se compare en temps constant (égalité condensée + timingSafeEqual, aucune comparaison directe)
#   TM  moteur : un assistant sous .vibeflow/ ou en lien symbolique est refusé (terminal inerte, rien n'est lancé)
#   M-* mutants (copies du module par cockpit_module_muter) : M-ORIGIN, M-HOST, M-JETON, M-SANSORIGIN, M-EXPIRE, M-RETIRE, M-BALAI, M-REJEU, M-SERVI, M-LOG, M-URL, M-TD1, M-TEMPS-CONSTANT, M-EGAL, M-MOTEUR-VIBEFLOW, M-MOTEUR-LIEN
# Chaque refus a son témoin positif ; « 0 assistant » = aucun enfant du serveur dont la ligne de commande contient vf-cockpit-pty.py.
# Exit 0 si tout passe, 1 sinon.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$SCRIPTS/../skills/cockpit-moteur"; TA="$HERE_T/terminal-aux.mjs"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/bin" "$WORK/run" "$WORK/t3" "$WORK/t5"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"
# P71-D-33 : Q tourne dans un processus enfant du serveur ; « les enfants du serveur » = les assistants, enfants de ce processus (pgrep -P ne voit qu'un étage)
pgrep() { if [ "$1" = "-P" ] && [ $# -eq 2 ]; then local c; for c in $(command pgrep -P "$2"); do if ps -o command= -p "$c" 2>/dev/null | grep -q 'vf-cockpit-terminal-processus.mjs'; then command pgrep -P "$c"; else echo "$c"; fi; done; else command pgrep "$@"; fi; }
PASS=0; FAIL=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
# aide SSE : GET /api/vf/events sous le jeton de P pendant <ms>, octets reçus (statut et en-têtes en tête) écrits dans <fichier>
cat > "$AUX/sse.mjs" <<'JS'
import http from 'node:http'; import fs from 'node:fs';
const [, , port, tok, ms, out] = process.argv; fs.writeFileSync(out, '');
const r = http.get({ host: '127.0.0.1', port: +port, path: '/api/vf/events?token=' + encodeURIComponent(tok), headers: { Host: '127.0.0.1:' + port }, agent: false }, (res) => {
  fs.writeFileSync(out, 'HTTP ' + res.statusCode + '\n' + JSON.stringify(res.headers) + '\n'); res.on('data', (c) => fs.appendFileSync(out, c));
});
r.on('error', () => {}); setTimeout(() => { r.destroy(); process.exit(0); }, +ms);
JS
# aide Upgrade : GET <chemin> avec Upgrade: websocket ; « 101 » si le serveur accepte la montée, sinon le statut
cat > "$AUX/upg.mjs" <<'JS'
import http from 'node:http';
const [, , port, chemin, secret, origine, hote] = process.argv;
const h = { Host: hote || `127.0.0.1:${port}`, Connection: 'Upgrade', Upgrade: 'websocket', 'Sec-WebSocket-Key': 'dGhlIHNhbXBsZSBub25jZQ==', 'Sec-WebSocket-Version': '13' };
if (origine) h.Origin = origine; if (secret) h['X-VF-Terminal'] = secret;
const r = http.request({ host: '127.0.0.1', port: +port, path: chemin, headers: h, agent: false }, (res) => { console.log(res.statusCode); res.resume(); res.on('end', () => process.exit(0)); });
r.on('upgrade', () => { console.log('101'); process.exit(0); }); r.on('error', (e) => { console.log('ERREUR ' + (e.code || 'ECHEC')); process.exit(0); });
setTimeout(() => { console.log('ETIMEDOUT'); process.exit(0); }, 4000); r.end();
JS
# aide capture : écoute, écrit les en-têtes bruts de la première requête, répond 200 (témoin T5.9)
cat > "$AUX/capt.mjs" <<'JS'
import net from 'node:net'; import fs from 'node:fs';
const [, , port, out] = process.argv; const s = net.createServer((c) => { c.once('data', (d) => { fs.writeFileSync(out, d); c.end('HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n'); setTimeout(() => process.exit(0), 100); }); });
s.listen(+port, '127.0.0.1');
setTimeout(() => process.exit(0), 6000);
JS
cat > "$WORK/bin/shell-test" <<SH
#!/bin/sh
echo \$\$ > "$WORK/run/shell.pid"
/bin/sh -i
SH
chmod +x "$WORK/bin/shell-test"; export SHELL="$WORK/bin/shell-test"

rq() { node "$TA" req "$@"; }
sta() { rq "$@" | sed -n 1p; }
amorce_neuve() { node -e "console.log(require('crypto').randomBytes(24).toString('hex'))"; }
mklab() {
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"; printf 'export const u = 1;\n' > "$L/src/u.js"
  printf -- '## Phases\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Goal**: Poser le socle\n' > "$B/ROADMAP.md"
  printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0 MVP\n---\n' > "$B/STATE.md"
  printf -- '---\nwave: 1\nfiles_modified: [src/u.js]\n---\n<objective>Poser le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit.mjs" build --lab "$L" > "$WORK/build-$(basename "$L").out" 2>&1 || cat "$WORK/build-$(basename "$L").out"
}
SRVN=0
# 79-06 : le code ne vit plus dans la sortie. MOD_DEPOT = racine du module du dépôt ; mod_de <sortie> = racine du module que COMMANDE cette sortie
# (table posée par mutant() : sortie TAB module ; par défaut le module du dépôt). ENG0 = le moteur du module du dépôt (ENG peut être remplacé par une copie).
MOD_DEPOT="$(cd "$SCRIPTS/.." && pwd -P)"; MODS_TABLE="$WORK/.mods"; : > "$MODS_TABLE"; export MODS_TABLE MOD_DEPOT; ENG0="$ENG"
mod_de() { local m; m="$(awk -F'\t' -v s="${1:-}" '$1==s{m=$2} END{print m}' "$MODS_TABLE" 2>/dev/null)"; printf '%s\n' "${m:-$MOD_DEPOT}"; }
srv() { # srv <sortie> <0|1> : serveur du MODULE de la sortie visée, lancé par l'aide ; AMORCE posé en 0600 (copie dans $WORK/amorce.copy) ; ENG remplacé = moteur copié (contenu identique : même empreinte)
  local o="$1" term="${2:-0}" lab ev=(); lab="$(cd "$1/../.." && pwd)"
  SRVN=$((SRVN+1)); SRV_O="$o"; SRV_OUT="$WORK/serve-$SRVN-$RANDOM.out"; rm -f "$o/.cache/server.json" "$o/.cache/terminal-amorce"
  local flag=(); mkdir -p "$o/.cache"
  if [ "$term" = 1 ]; then flag=(--terminal); AMORCE="$(amorce_neuve)"; (umask 077; printf '%s' "$AMORCE" > "$o/.cache/terminal-amorce"); (umask 077; printf '%s' "$AMORCE" > "$WORK/amorce.copy"); fi
  [ "$ENG" = "$ENG0" ] || ev=(VF_COCKPIT_ENGINE_DIR="$ENG")
  COCKPIT_MODULE="$(mod_de "$o")" COCKPIT_LOG="$SRV_OUT" cockpit_lancer "$lab" ${ev[@]+"${ev[@]}"} ${flag[@]+"${flag[@]}"}
  if [ "$term" = 1 ]; then attendre 5 grep -qs '"terminal"' "$o/.cache/server.json"; fi # la clé terminal manque quand le moteur refuse l'assistant : attente bornée, sans échec
  SRV_PID="$VF_PID"; SRV_PORT="${VF_PORT:-0}"
}
sj() { node "$AUX/ev.mjs" "$1" < "$SRV_O/.cache/server.json" 2>/dev/null; }
unsrv() { vf_hyg_stop "$SRV_PID"; }
srvq() { srv "${1:-$OUT}" 1; QP="$(sj '(j.terminal&&j.terminal.url)||""')"; QP="${QP##*:}"; QP="${QP:-1}"; TOK="$(sj j.token)"; }
echanger() { local r; r="$(node "$TA" amorcer "$QP" "$WORK/amorce.copy")"; EC_CODE="$(printf '%s\n' "$r" | sed -n 1p)"; SECRET="$(printf '%s\n' "$r" | sed -n 2p)"; }
pty_compte() { local n=0 p; for p in $(pgrep -P "$SRV_PID" 2>/dev/null); do ps -o command= -p "$p" 2>/dev/null | grep -q 'vf-cockpit-pty.py' && n=$((n+1)); done; echo "$n"; }
mutant() { # mutant <nom> <fichier> <expression-sed> -> MUT_OUT (copie du lab : données) et MUT_MOD (racine de la copie du module)
  local d="$WORK/mut-$1" f; rm -rf "$d" "$WORK/mod-$1"; mkdir -p "$d"; cp -R "$LAB/.planning" "$d/.planning"; cp -R "$LAB/.vibeflow" "$d/.vibeflow"
  MUT_OUT="$d/.vibeflow/cockpit"; MUT_MOD=""
  case "$(basename "$2")" in
    serve.mjs|graph-query.js|query-cli.mjs|vf-cockpit-*) cockpit_module_muter "$1" "$2" "$3" || return 1; MUT_MOD="$COCKPIT_MODULE"; unset COCKPIT_MODULE; printf '%s\t%s\n' "$MUT_OUT" "$MUT_MOD" >> "$MODS_TABLE"; return 0 ;;
  esac
  f="$d/.vibeflow/cockpit/$2"; [ -f "$f" ] || return 1   # page de la copie du lab (donnée) : même chemin que MUT_OUT/<fichier>
  cp "$f" "$f.orig"; sed -i.bak "$3" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
temoin_compteur() { # lance un assistant sur un serveur jetable : prouve que pty_compte voit un PTY
  srvq; echanger; local f="$WORK/tc-$RANDOM.out" n=0 fp
  node "$TA" flux "$QP" "$SECRET" tc "$f" 5000 > /dev/null 2>&1 & fp=$!
  for _ in $(seq 1 50); do n="$(pty_compte)"; [ "$n" = 1 ] && break; sleep 0.1; done
  assert_eq "$1 — témoin : un flux valide lance exactement un assistant (le compteur voit un PTY)" "$n" "1"
  unsrv; wait "$fp" 2>/dev/null
}
ent_ok() { # ent_ok <sortie-rq> <1 si GET / de Q> : en-têtes obligatoires, aucun en-tête interdit
  local csp="true"; [ "${2:-0}" = 1 ] || csp="j[\"content-security-policy\"]===\"default-src 'none'; frame-ancestors 'none'\""
  sed -n 2p "$1" | node "$AUX/ev.mjs" "(j[\"x-content-type-options\"]===\"nosniff\"&&j[\"referrer-policy\"]===\"no-referrer\"&&j[\"cache-control\"]===\"no-store\"&&Object.keys(j).every(k=>!/^access-control-|^set-cookie\$|^x-frame-options\$/.test(k))&&($csp))?\"ok\":JSON.stringify(j)"
}
cherche() { # cherche <valeur> <cible…> : noms des cibles (fichier ou dossier) qui contiennent la valeur, une ligne chacune
  local v="$1" f; shift
  for f in "$@"; do if [ -d "$f" ]; then grep -rlF -e "$v" "$f" 2>/dev/null | head -3; elif grep -qF -e "$v" "$f" 2>/dev/null; then echo "$f"; fi; done
}

LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"
EVIL="http://evil.example"

echo "=== T0 — le compteur d'assistants voit un PTY ==="
temoin_compteur T0

echo "=== T1 — Origin (TERM-02, T-71-08) ==="
temoin_compteur T1
srvq; echanger; P1=$SRV_PORT
assert_eq "T1.0 — témoin : l'échange de l'amorçage rend 200 et un secret de 64 hexadécimaux" "$EC_CODE $([[ "$SECRET" =~ ^[0-9a-f]{64}$ ]] && echo secret-64-hex || echo "invalide : ${SECRET:-vide}")" "200 secret-64-hex"
assert_eq "T1.1 — POST /entree avec Origin tierce rend 403" "$(sta "$QP" POST /entree --secret "$SECRET" --onglet o1 --origin "$EVIL" --corps x)" "403"
assert_eq "T1.2 — POST /entree avec Origin http://127.0.0.1:<P> rend 403" "$(sta "$QP" POST /entree --secret "$SECRET" --onglet o1 --origin "http://127.0.0.1:$P1" --corps x)" "403"
assert_eq "T1.1b — GET /flux avec Origin tierce rend 403" "$(sta "$QP" GET /flux --secret "$SECRET" --onglet o1 --origin "$EVIL" --echeance 1500)" "403"
assert_eq "T1.2b — GET /flux avec Origin de P rend 403" "$(sta "$QP" GET /flux --secret "$SECRET" --onglet o1 --origin "http://127.0.0.1:$P1" --echeance 1500)" "403"
assert_eq "T1.2c — POST /taille avec Origin de P rend 403" "$(sta "$QP" POST /taille --secret "$SECRET" --onglet o1 --origin "http://127.0.0.1:$P1" --corps "24 80")" "403"
assert_eq "T1.3 — témoin : GET /etat avec l'Origin de Q et le secret rend 200" "$(sta "$QP" GET /etat --secret "$SECRET")" "200"
assert_eq "T1.pty — T1.1 à T1.2c n'ont lancé aucun assistant (0)" "$(pty_compte)" "0"
unsrv

echo "=== T2 — Host (TERM-02, T-71-09) ==="
temoin_compteur T2
srvq; echanger; P2=$SRV_PORT
assert_eq "T2.1 — POST /entree avec Host evil.example:<Q> rend 403" "$(sta "$QP" POST /entree --secret "$SECRET" --onglet o1 --host "evil.example:$QP" --corps x)" "403"
assert_eq "T2.2 — POST /entree avec Host 127.0.0.1:<P> rend 403" "$(sta "$QP" POST /entree --secret "$SECRET" --onglet o1 --host "127.0.0.1:$P2" --corps x)" "403"
assert_eq "T2.3 — POST /entree avec Host localhost:<Q> rend 403 (localhost réservé à GET /)" "$(sta "$QP" POST /entree --secret "$SECRET" --onglet o1 --host "localhost:$QP" --corps x)" "403"
assert_eq "T2.3b — GET /flux avec Host localhost:<Q> rend 403" "$(sta "$QP" GET /flux --secret "$SECRET" --onglet o1 --host "localhost:$QP" --echeance 1500)" "403"
assert_eq "T2.3c — GET /etat avec Host localhost:<Q> rend 403" "$(sta "$QP" GET /etat --secret "$SECRET" --host "localhost:$QP")" "403"
assert_eq "T2.4 — témoin : GET / avec Host localhost:<Q>, sans Origin, rend 200" "$(sta "$QP" GET / --sans-origin --host "localhost:$QP")" "200"
assert_eq "T2.4b — témoin : GET / avec Host 127.0.0.1:<Q> rend 200" "$(sta "$QP" GET / --sans-origin)" "200"
assert_eq "T2.4c — témoin : GET /etat avec Host 127.0.0.1:<Q> et le secret rend 200" "$(sta "$QP" GET /etat --secret "$SECRET")" "200"
assert_eq "T2.pty — T2.1 à T2.3c n'ont lancé aucun assistant (0)" "$(pty_compte)" "0"
unsrv

echo "=== T3 — secret, sans Origin, OPTIONS, en-têtes (TERM-02, T-71-10, T-71-13) ==="
temoin_compteur T3
srvq; echanger; echo 0 > "$WORK/t3.cnt"
rqf() { local n; n=$(( $(cat "$WORK/t3.cnt") + 1 )); echo "$n" > "$WORK/t3.cnt"; rq "$@" > "$WORK/t3/$n.out"; sed -n 1p "$WORK/t3/$n.out"; } # compteur dans un fichier : rqf s'appelle en sous-shell
cnt() { cat "$WORK/t3.cnt"; }
FAUX="$(printf '%s' "$SECRET" | sed 's/^./Z/;s/^Z/0/')"; [ "$FAUX" = "$SECRET" ] && FAUX="1${SECRET:1}"; FAUX6="$FAUX"
assert_eq "T3.0 — témoin : GET /etat avec le bon secret rend 200" "$(rqf "$QP" GET /etat --secret "$SECRET")" "200"; F200=$(cnt)
assert_eq "T3.1 — POST /entree sans secret rend 401" "$(rqf "$QP" POST /entree --onglet o1 --corps x)" "401"; F401=$(cnt)
assert_eq "T3.1b — GET /flux sans secret rend 401" "$(rqf "$QP" GET /flux --onglet o1 --echeance 1500)" "401"
assert_eq "T3.1c — GET /etat sans secret rend 401" "$(rqf "$QP" GET /etat)" "401"
assert_eq "T3.1d — chemin inconnu sans secret rend 401 (aucune route ne se devine sans secret)" "$(rqf "$QP" GET /inconnu)" "401"
assert_eq "T3.2 — secret plus long (66 caractères) rend 401" "$(rqf "$QP" GET /etat --secret "${SECRET}00")" "401"
assert_eq "T3.2b — secret plus court (3 caractères) rend 401" "$(rqf "$QP" GET /etat --secret abc)" "401"
assert_eq "T3.3 — secret faux de même longueur rend 401" "$(rqf "$QP" GET /etat --secret "$FAUX")" "401"
assert_eq "T3.3b — le secret faux a bien la longueur du vrai" "${#FAUX}" "${#SECRET}"
assert_eq "T3.4 — GET /flux sans Origin (secret valide) rend 403" "$(rqf "$QP" GET /flux --secret "$SECRET" --onglet o1 --sans-origin --echeance 1500)" "403"
assert_eq "T3.4b — POST /entree sans Origin rend 403" "$(rqf "$QP" POST /entree --secret "$SECRET" --onglet o1 --sans-origin --corps x)" "403"
assert_eq "T3.4c — POST /taille sans Origin rend 403" "$(rqf "$QP" POST /taille --secret "$SECRET" --onglet o1 --sans-origin --corps "24 80")" "403"
assert_eq "T3.4d — GET /etat sans Origin rend 403" "$(rqf "$QP" GET /etat --secret "$SECRET" --sans-origin)" "403"; F403=$(cnt)
assert_eq "T3.5 — témoin : GET / sans Origin rend 200" "$(rqf "$QP" GET / --sans-origin)" "200"; FROOT=$(cnt)
for rte in / /flux /entree /taille /amorce /etat /inconnu; do
  assert_eq "T3.6 — OPTIONS $rte (identifiants valides, préflight CORS) rend 403" "$(rqf "$QP" OPTIONS "$rte" --secret "$SECRET" --onglet o1 --entete 'Access-Control-Request-Method:POST')" "403"
done
assert_eq "T3.6b — chemin inconnu avec secret valide rend 404" "$(rqf "$QP" GET /inconnu --secret "$SECRET")" "404"; F404=$(cnt)
assert_eq "T3.6c — GET /entree (méthode inattendue) rend 405" "$(rqf "$QP" GET /entree --secret "$SECRET")" "405"; F405=$(cnt)
SANS_CORS=""; for f in "$WORK/t3/"*.out; do sed -n 2p "$f" | node "$AUX/ev.mjs" 'Object.keys(j).filter(k=>/^access-control-/.test(k)).join(",")' | grep -q . && SANS_CORS="$SANS_CORS $(basename "$f")"; done
assert_eq "T3.6d — aucune des $(cnt) réponses collectées ne porte un en-tête Access-Control-*" "${SANS_CORS# }" ""
for pair in "200:$F200:0" "401:$F401:0" "403:$F403:0" "404:$F404:0" "405:$F405:0" "root:$FROOT:1"; do
  IFS=: read -r nom num root <<<"$pair"; assert_eq "T3.9 — en-têtes de P71-PL-16 sur la réponse $nom (nosniff, no-referrer, no-store, CSP de base, ni CORS ni cookie ni X-Frame-Options)" "$(ent_ok "$WORK/t3/$num.out" "$root")" "ok"
done
assert_eq "T3.pty — T3.1 à T3.6 n'ont lancé aucun assistant (0)" "$(pty_compte)" "0"
unsrv

echo "=== T3b — corps bornés (TERM-02, T-71-14) ==="
temoin_compteur T3b
srvq; echanger; FL="$WORK/t3b-flux.out"; : > "$FL"
# la limite exacte se mesure sans session (rien n'est écrit à un shell) : 65536 octets passent le contrôle du corps (410 : pas de session), 65537 non
assert_eq "T3.7 — sans session, POST /entree de 65536 octets (la limite) passe le contrôle du corps : 410" "$(rqf "$QP" POST /entree --secret "$SECRET" --onglet ob --corps-octets 65536 --echeance 8000)" "410"
assert_eq "T3.7 — sans session, POST /entree de 65537 octets rend 413" "$(rqf "$QP" POST /entree --secret "$SECRET" --onglet ob --corps-octets 65537 --echeance 8000)" "413"
node "$TA" flux "$QP" "$SECRET" ob "$FL" 20000 > /dev/null 2>&1 & FP=$!
for _ in $(seq 1 50); do [ "$(pty_compte)" = 1 ] && break; sleep 0.1; done
assert_eq "T3.7 — témoin : un flux est attaché (un assistant)" "$(pty_compte)" "1"
assert_eq "T3.7 — témoin : POST /entree de 40 octets rend 204" "$(rqf "$QP" POST /entree --secret "$SECRET" --onglet ob --corps wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww)" "204"; F204=$(cnt)
assert_eq "T3.7 — témoin : ces 40 octets reviennent dans le flux (écho du terminal)" "$(node "$TA" attendre "$FL" wwwwwwwwwwwwwwww 5000)" "TROUVE"
sleep 1; : > "$FL"
assert_eq "T3.7 — POST /entree de 65537 octets rend 413" "$(rqf "$QP" POST /entree --secret "$SECRET" --onglet ob --corps-octets 65537 --echeance 8000)" "413"; F413=$(cnt)
sleep 1
assert_eq "T3.7b — le corps refusé n'a rien écrit au shell (aucune suite de x dans le flux, 1 s après)" "$(grep -c 'xxxxxxxx' "$FL" || true)" "0"
assert_eq "T3.8 — témoin : POST /taille « 24 80 » rend 204" "$(rqf "$QP" POST /taille --secret "$SECRET" --onglet ob --corps "24 80")" "204"
assert_eq "T3.8 — POST /taille « 500 1000 » (bornes) rend 204" "$(rqf "$QP" POST /taille --secret "$SECRET" --onglet ob --corps "500 1000")" "204"
for bad in "abc" "0 0" "24 0" "501 80" "24 1001" "99999 80" "24 80 extra" "-1 80" "24.5 80" ""; do
  assert_eq "T3.8 — POST /taille « $bad » rend 400" "$(rqf "$QP" POST /taille --secret "$SECRET" --onglet ob --corps "$bad")" "400"; F400=$(cnt)
done
assert_eq "T3.8 — POST /taille de 40 octets rend 400" "$(rqf "$QP" POST /taille --secret "$SECRET" --onglet ob --corps-octets 40)" "400"
for bad in 501x80 999x999 24x1001 1000x80 0x80 24x0 24x80x1 abc; do # une seule borne (500 x 1000) pour /flux comme pour /taille : refusée, jamais acceptée puis ignorée
  assert_eq "T3.8d — GET /flux, X-VF-Taille « $bad » rend 400" "$(rqf "$QP" GET /flux --secret "$SECRET" --onglet ob --entete "x-vf-taille:$bad" --echeance 3000)" "400"
done
assert_eq "T3.8c — onglet invalide (hors de [A-Za-z0-9_-]) rend 4xx, jamais 204" "$([ "$(sta "$QP" POST /entree --secret "$SECRET" --onglet 'a b' --corps x)" = 204 ] && echo 204 || echo refus)" "refus"
for pair in "204:$F204" "413:$F413" "400:$F400"; do
  IFS=: read -r nom num <<<"$pair"; assert_eq "T3.9 — en-têtes de P71-PL-16 sur la réponse $nom" "$(ent_ok "$WORK/t3/$num.out" 0)" "ok"
done
unsrv; wait "$FP" 2>/dev/null

echo "=== T4 — amorçage à usage unique (TERM-03, T-71-11) ==="
temoin_compteur T4
srvq; AM="$OUT/.cache/terminal-amorce"
mode_de() { # lecture GNU d'abord, valeur validée en octal ; BSD/macOS ensuite (même forme que plugin/consolidator/scripts/reindex.sh, keep_mode) : sous GNU et uutils `stat -f %Lp` imprime sans réussir
  local m; m=$(stat -c %a "$1" 2>/dev/null) || m=""
  case "$m" in [0-7][0-7][0-7]|[0-7][0-7][0-7][0-7]) ;; *) m=$(stat -f %Lp "$1" 2>/dev/null) || m="" ;; esac
  case "$m" in [0-7][0-7][0-7]|[0-7][0-7][0-7][0-7]) echo "$m" ;; *) echo "illisible" ;; esac
}
mode_de_ancien() { stat -f %Lp "$1" 2>/dev/null || stat -c %a "$1" 2>/dev/null; } # forme d'avant la correction, gardée pour prouver que les faux stat reproduisent le défaut
for k in gnu uutils bsd; do # faux `stat` des trois familles : GNU (-f imprime et réussit), uutils (-f imprime puis échoue), BSD (-c échoue)
  mkdir -p "$WORK/fk-$k"; cat > "$WORK/fk-$k/stat" <<SH
#!/bin/sh
octal() { perl -e 'printf "%o\n", (stat \$ARGV[0])[2] & 07777' "\$1"; }
case "$k:\$1" in
  gnu:-c|uutils:-c) octal "\$3" ;;
  gnu:-f) printf '  File: "%s"\n    ID: 0 Namelen: 255 Type: ext2/ext3\n' "\$3"; exit 0 ;;
  uutils:-f) printf '  File: "%s"\n    ID: 0 Namelen: 255 Type: ext2/ext3\n' "\$3"; exit 1 ;;
  bsd:-f) octal "\$3" ;;
  *) echo "stat: option invalide" >&2; exit 1 ;;
esac
SH
  chmod +x "$WORK/fk-$k/stat"
done
printf x > "$WORK/mode-temoin"; chmod 600 "$WORK/mode-temoin"
assert_eq "S2.0 — témoin : l'ancienne forme (stat -f d'abord) se trompe sous les faux GNU et uutils (elle ne rend pas 600)" "$([ "$(PATH="$WORK/fk-gnu:$PATH" mode_de_ancien "$WORK/mode-temoin")" != 600 ] && [ "$(PATH="$WORK/fk-uutils:$PATH" mode_de_ancien "$WORK/mode-temoin")" != 600 ] && echo defaut-reproduit || echo "non reproduit")" "defaut-reproduit"
assert_eq "S2.1 — la lecture du mode rend 600 sous le faux GNU, le faux uutils, le faux BSD et le stat réel du poste" "$(for k in gnu uutils bsd; do PATH="$WORK/fk-$k:$PATH" mode_de "$WORK/mode-temoin"; done | tr '\n' ' ')$(mode_de "$WORK/mode-temoin")" "600 600 600 600"
assert_eq "T4.3 — avant l'échange, le fichier d'amorçage existe en 0600" "$(mode_de "$AM")" "600"
rq "$QP" GET / --sans-origin --corps-vers "$WORK/t4-q.html" > /dev/null; rq "$SRV_PORT" GET / --corps-vers "$WORK/t4-p-index.html" > /dev/null; rq "$SRV_PORT" GET /project.html --corps-vers "$WORK/t4-p-projet.html" > /dev/null
assert_eq "T4.6 — témoin : les trois pages sont lues en entier (Q et les deux pages de P)" "$([ -s "$WORK/t4-q.html" ] && [ "$(wc -c < "$WORK/t4-p-index.html")" -gt 100000 ] && [ "$(wc -c < "$WORK/t4-p-projet.html")" -gt 100000 ] && echo oui || echo non)" "oui"
assert_eq "T4.6 — l'amorçage (présent sur disque) ne figure ni dans GET / de P, ni dans /project.html, ni dans GET / de Q" "$(cherche "$AMORCE" "$WORK/t4-q.html" "$WORK/t4-p-index.html" "$WORK/t4-p-projet.html" | tr '\n' ' ')" ""
assert_eq "T4.0 — POST /amorce avec le bon amorçage mais sans Origin rend 403" "$(sta "$QP" POST /amorce --amorce "$AMORCE" --sans-origin)" "403"
assert_eq "T4.0b — POST /amorce avec le bon amorçage et une Origin tierce rend 403" "$(sta "$QP" POST /amorce --amorce "$AMORCE" --origin "$EVIL")" "403"
assert_eq "T4.0c — POST /amorce avec le bon amorçage et Host de rebinding rend 403" "$(sta "$QP" POST /amorce --amorce "$AMORCE" --host "evil.example:$QP")" "403"
assert_eq "T4.0d — les refus n'ont pas consommé l'amorçage (le fichier existe encore)" "$([ -f "$AM" ] && echo oui || echo non)" "oui"
assert_eq "T4.2a — un mauvais amorçage rend 403" "$(sta "$QP" POST /amorce --amorce "$(amorce_neuve)")" "403"
assert_eq "T4.2b — un amorçage vide rend 403" "$(sta "$QP" POST /amorce --amorce '')" "403"
assert_eq "T4.2c — POST /amorce sans en-tête d'amorçage rend 403" "$(sta "$QP" POST /amorce)" "403"
assert_eq "T4.2d — GET /amorce rend 405 (ou refus), jamais 200" "$([ "$(sta "$QP" GET /amorce)" = 200 ] && echo 200 || echo refus)" "refus"
assert_eq "T4.2e — les échecs laissent l'amorçage valable (le fichier existe encore)" "$([ -f "$AM" ] && echo oui || echo non)" "oui"
echanger
assert_eq "T4.1 — le premier échange du bon amorçage rend 200 et un secret de 64 hexadécimaux" "$EC_CODE $([[ "$SECRET" =~ ^[0-9a-f]{64}$ ]] && echo secret-64-hex || echo "invalide : ${SECRET:-vide}")" "200 secret-64-hex"
assert_eq "T4.3 — le fichier d'amorçage est supprimé après l'échange" "$([ -e "$AM" ] && echo present || echo supprime)" "supprime"
assert_eq "T4.2 — le rejeu du même amorçage rend 403" "$(node "$TA" amorcer "$QP" "$WORK/amorce.copy" | sed -n 1p)" "403"
assert_eq "T4.2 — le rejeu n'a lancé aucun assistant (0)" "$(pty_compte)" "0"
unsrv
# lien symbolique : même contenu, même mode, valeur juste — refusé pour le lien seul ; témoin : le même contenu en fichier ordinaire est accepté
srvq; AM="$OUT/.cache/terminal-amorce"; CIBLE="$WORK/cible-amorce"; mv "$AM" "$CIBLE"; ln -s "$CIBLE" "$AM"
assert_eq "T4.4 — amorçage servi par un lien symbolique : échange refusé (403)" "$(node "$TA" amorcer "$QP" "$WORK/amorce.copy" | sed -n 1p)" "403"
assert_eq "T4.4b — la cible du lien n'est pas consommée" "$([ -f "$CIBLE" ] && echo oui || echo non)" "oui"
rm -f "$AM"; (umask 077; cp "$CIBLE" "$AM"); chmod 600 "$AM"
assert_eq "T4.4c — témoin : le même contenu en fichier ordinaire 0600 est accepté (200)" "$(node "$TA" amorcer "$QP" "$WORK/amorce.copy" | sed -n 1p)" "200"
unsrv
# mode lâche
for md in 644 640 604 660; do
  srvq; AM="$OUT/.cache/terminal-amorce"; chmod "$md" "$AM"
  assert_eq "T4.5 — amorçage en mode 0$md : échange refusé (403)" "$(node "$TA" amorcer "$QP" "$WORK/amorce.copy" | sed -n 1p)" "403"
  chmod 600 "$AM" 2>/dev/null
  assert_eq "T4.5 — témoin : après chmod 600, le même fichier est accepté (200)" "$(node "$TA" amorcer "$QP" "$WORK/amorce.copy" | sed -n 1p)" "200"
  unsrv
done
# dossier à la place du fichier, fichier trop grand
srvq; AM="$OUT/.cache/terminal-amorce"; rm -f "$AM"; mkdir "$AM"
assert_eq "T4.5b — un dossier à la place de l'amorçage : refus (403)" "$(node "$TA" amorcer "$QP" "$WORK/amorce.copy" | sed -n 1p)" "403"
rmdir "$AM"; (umask 077; { cat "$WORK/amorce.copy"; head -c 4096 /dev/zero | tr '\0' ' '; } > "$AM")
assert_eq "T4.5c — un fichier d'amorçage de plus de 128 octets : refus (403)" "$(node "$TA" amorcer "$QP" "$WORK/amorce.copy" | sed -n 1p)" "403"
unsrv
# P71-D-27 : l'amorçage expire 60 s après sa création, côté serveur (âge simulé en reculant la date du fichier : jamais un vrai sleep 60)
vieillir() { node -e "const fs=require('fs');const t=(Date.now()-Number(process.argv[2])*1000)/1000;fs.utimesSync(process.argv[1],t,t)" "$1" "$2"; }
srvq; AM="$OUT/.cache/terminal-amorce"; vieillir "$AM" 50
assert_eq "T4.9 — témoin : un amorçage vieux de 50 s est accepté (200)" "$(node "$TA" amorcer "$QP" "$WORK/amorce.copy" | sed -n 1p)" "200"
unsrv
srvq; AM="$OUT/.cache/terminal-amorce"; vieillir "$AM" 61
assert_eq "T4.9 — un amorçage vieux de 61 s est refusé (403)" "$(node "$TA" amorcer "$QP" "$WORK/amorce.copy" | sed -n 1p)" "403"
assert_eq "T4.9 — le refus pour expiration n'a pas consommé de secret (aucun /etat sans secret admis : 401)" "$(sta "$QP" GET /etat)" "401"
unsrv
srvq; AM="$OUT/.cache/terminal-amorce"; vieillir "$AM" 3600
assert_eq "T4.9 — un amorçage vieux d'une heure est refusé (403)" "$(node "$TA" amorcer "$QP" "$WORK/amorce.copy" | sed -n 1p)" "403"
unsrv
# la page de redirection du lanceur (terminal-ouvrir.html) : retirée dès l'échange, balayée par le serveur 60 s après sa création
posee() { (umask 077; printf '<meta http-equiv="refresh" content="0;url=http://127.0.0.1:1/#t=x">\n' > "$1"); }
disparait() { for _ in $(seq 1 "$2"); do [ -e "$1" ] || { echo oui; return; }; sleep 0.25; done; echo non; }
srvq; PG="$OUT/.cache/terminal-ouvrir.html"; posee "$PG"
assert_eq "T4.10 — témoin : la page existe avant l'échange" "$([ -f "$PG" ] && echo oui || echo non)" "oui"
echanger
assert_eq "T4.10 — l'échange réussi retire la page de redirection" "$EC_CODE $(disparait "$PG" 8)" "200 oui"
unsrv
srvq; PG="$OUT/.cache/terminal-ouvrir.html"; posee "$PG"
assert_eq "T4.10 — un échange REFUSÉ ne retire pas la page" "$(printf 'faux' > "$WORK/faux.copy"; node "$TA" amorcer "$QP" "$WORK/faux.copy" | sed -n 1p) $([ -f "$PG" ] && echo reste || echo retiree)" "403 reste"
unsrv
srvq; PG="$OUT/.cache/terminal-ouvrir.html"; posee "$PG"; vieillir "$PG" 30; sleep 5
assert_eq "T4.11 — balayage : une page de 30 s est conservée" "$([ -f "$PG" ] && echo oui || echo non)" "oui"
vieillir "$PG" 61
assert_eq "T4.11 — balayage : une page de plus de 60 s jamais lue est supprimée par le serveur (8 s au plus)" "$(disparait "$PG" 32)" "oui"
unsrv

echo "=== T5 — aucun secret dans aucune sortie (TERM-03, T-71-12) ==="
temoin_compteur T5
printf 'bruit %s fin\n' "VALEUR-PLANTEE-71" > "$WORK/t5-plante.txt"
assert_eq "T5.0 — témoin : la recherche trouve une valeur plantée dans un fichier jetable" "$(cherche VALEUR-PLANTEE-71 "$WORK/t5-plante.txt" | wc -l | tr -d ' ')" "1"
srvq; P5=$SRV_PORT; echanger; FL5="$WORK/t5-flux.out"; : > "$FL5"
node "$AUX/sse.mjs" "$P5" "$TOK" 3500 "$WORK/t5/sse.out" & SSEP=$!
node "$TA" flux "$QP" "$SECRET" o5 "$FL5" 6000 --taille 30x100 > /dev/null 2>&1 & FP=$!
for _ in $(seq 1 50); do [ "$(pty_compte)" = 1 ] && break; sleep 0.1; done
node "$TA" entree "$QP" "$SECRET" o5 "echo MARQUE-$RANDOM\\r" > /dev/null 2>&1
node "$TA" entree "$QP" "$SECRET" o5 "echo ENV-\$HOME\\r" > /dev/null 2>&1
node "$TA" taille "$QP" "$SECRET" o5 40 120 > /dev/null 2>&1
rq "$QP" GET / --sans-origin --corps-vers "$WORK/t5/q-page.html" > "$WORK/t5/q-root.out"
rq "$QP" GET /etat --secret "$SECRET" > "$WORK/t5/q-etat.out"
rq "$QP" POST /entree --onglet o5 --corps x > "$WORK/t5/q-401.out"
rq "$QP" POST /entree --secret "$SECRET" --origin "$EVIL" --corps x > "$WORK/t5/q-403.out"
rq "$QP" GET /inconnu --secret "$SECRET" > "$WORK/t5/q-404.out"
rq "$QP" POST /amorce --amorce "$AMORCE" > "$WORK/t5/q-rejeu.out"
rq "$P5" GET / --corps-vers "$WORK/t5/p-page.html" > "$WORK/t5/p-root.out"
rq "$P5" GET /project.html --corps-vers "$WORK/t5/p-projet.html" > "$WORK/t5/p-projet.out"
rq "$P5" GET /api/vf/terminal --jeton "$TOK" > "$WORK/t5/p-terminal.out"
rq "$P5" GET /api/vf/etat --jeton "$TOK" > "$WORK/t5/p-etat.out"
rq "$P5" POST /api/export --jeton "$TOK" --corps '{}' --corps-vers "$WORK/t5/export.html" > "$WORK/t5/export.out"
wait "$SSEP" 2>/dev/null; wait "$FP" 2>/dev/null
ps -o command= -p "$SRV_PID" > "$WORK/t5/cmd-serveur.txt" 2>&1
for p in $(pgrep -P "$SRV_PID" 2>/dev/null); do ps -o command= -p "$p" >> "$WORK/t5/cmd-assistant.txt" 2>&1; done; [ -f "$WORK/t5/cmd-assistant.txt" ] || echo "aucun assistant" > "$WORK/t5/cmd-assistant.txt"
assert_eq "T5.1 — témoin : les réponses de P sont complètes (jeton valide : 200 sur /api/vf/etat et /api/vf/terminal, export 200)" "$(sed -n 1p "$WORK/t5/p-etat.out") $(sed -n 1p "$WORK/t5/p-terminal.out") $(sed -n 1p "$WORK/t5/export.out")" "200 200 200"
assert_eq "T5.2 — témoin : les réponses de Q sont celles attendues (page 200, état 200, refus 401 et 403, 404, rejeu 403)" "$(for f in q-root q-etat q-401 q-403 q-404 q-rejeu; do sed -n 1p "$WORK/t5/$f.out"; done | tr '\n' ' ')" "200 200 401 403 404 403 "
assert_eq "T5.3 — témoin : le flux SSE de P a répondu 200 (3 s lues)" "$(sed -n 1p "$WORK/t5/sse.out")" "HTTP 200"
assert_eq "T5.4 — témoin : la commande du parcours est revenue dans le flux du terminal" "$([ -s "$FL5" ] && grep -q 'MARQUE-' "$FL5" && echo oui || echo non)" "oui"
for val in "amorçage:$AMORCE" "secret:$SECRET"; do
  nom="${val%%:*}"; v="${val#*:}"
  assert_eq "T5.1 — $nom : absent de toute réponse de P (corps et en-têtes : pages, état, terminal)" "$(cherche "$v" "$WORK"/t5/p-*.out "$WORK/t5/p-page.html" "$WORK/t5/p-projet.html" | tr '\n' ' ')" ""
  assert_eq "T5.2 — $nom : absent de toute réponse de Q (page, état, refus 401/403/404, rejeu)" "$(cherche "$v" "$WORK"/t5/q-*.out "$WORK/t5/q-page.html" | tr '\n' ' ')" ""
  assert_eq "T5.3 — $nom : absent de 3 s du flux SSE de P" "$(cherche "$v" "$WORK/t5/sse.out" | tr '\n' ' ')" ""
  assert_eq "T5.4 — $nom : absent du journal du serveur" "$(cherche "$v" "$SRV_OUT" | tr '\n' ' ')" ""
  assert_eq "T5.5 — $nom : absent de l'export" "$(cherche "$v" "$WORK/t5/export.out" "$WORK/t5/export.html" | tr '\n' ' ')" ""
  assert_eq "T5.6 — $nom : absent de .vibeflow/cockpit/** (sortie du lab)" "$(cherche "$v" "$OUT" | tr '\n' ' ')" ""
  assert_eq "T5.7 — $nom : absent de la ligne de commande du serveur" "$(cherche "$v" "$WORK/t5/cmd-serveur.txt" | tr '\n' ' ')" ""
  assert_eq "T5.8 — $nom : absent de la ligne de commande de l'assistant" "$(cherche "$v" "$WORK/t5/cmd-assistant.txt" | tr '\n' ' ')" ""
done
unsrv
CP=$(libre); node "$AUX/capt.mjs" "$CP" "$WORK/t5-capt.txt" & CPP=$!; sleep 0.5
node "$TA" req "$CP" GET /etat --secret "SECRET-TEMOIN-71" > /dev/null; wait "$CPP" 2>/dev/null
assert_eq "T5.9 — témoin : le client envoie le secret en en-tête (retrouvé dans les en-têtes bruts capturés)" "$(cherche SECRET-TEMOIN-71 "$WORK/t5-capt.txt" | wc -l | tr -d ' ')" "1"

echo "=== TD — Upgrade et secret en adresse (D-09) ==="
temoin_compteur TD
srvq; echanger
assert_eq "TD.0 — témoin : GET /etat avec le secret en en-tête et sans Upgrade rend 200" "$(sta "$QP" GET /etat --secret "$SECRET")" "200"
assert_eq "TD.1 — Upgrade: websocket sans secret rend 401, jamais 101" "$(node "$AUX/upg.mjs" "$QP" /flux '' "http://127.0.0.1:$QP")" "401"
assert_eq "TD.1b — Upgrade: websocket avec Origin tierce (secret valide) rend 403, jamais 101" "$(node "$AUX/upg.mjs" "$QP" /flux "$SECRET" "$EVIL")" "403"
assert_eq "TD.1c — Upgrade: websocket avec Host de rebinding rend 403, jamais 101" "$(node "$AUX/upg.mjs" "$QP" /flux "$SECRET" "http://127.0.0.1:$QP" "evil.example:$QP")" "403"
assert_eq "TD.1d — Upgrade: websocket sur /etat avec les bons identifiants : jamais 101" "$([ "$(node "$AUX/upg.mjs" "$QP" /etat "$SECRET" "http://127.0.0.1:$QP")" = 101 ] && echo 101 || echo "pas 101")" "pas 101"
for prm in s secret token t; do
  assert_eq "TD.2 — secret en paramètre « ?$prm= » sans en-tête rend 401" "$(sta "$QP" GET "/etat?$prm=$SECRET")" "401"
done
assert_eq "TD.2b — POST /entree?s=<secret> sans en-tête rend 401" "$(sta "$QP" POST "/entree?s=$SECRET" --onglet o1 --corps x)" "401"
assert_eq "TD.pty — TD.1 et TD.2 n'ont lancé aucun assistant (0)" "$(pty_compte)" "0"
unsrv

echo "=== T6 — fetch GET de même origine d'un navigateur : pas d'Origin, Sec-Fetch-Site same-origin (P71-D-24) ==="
cat > "$AUX/nav.mjs" <<'JS'
// nav.mjs <port> <METHODE> <chemin> <secret|-> <sec-fetch-site|-> <origin|-> [onglet] : requête telle que la pose Chrome pour un fetch de même origine ; statut dès les en-têtes
import http from 'node:http';
const [, , port, methode, chemin, secret, sfs, origin, onglet = 'o6'] = process.argv;
const h = { Host: `127.0.0.1:${port}`, 'X-VF-Onglet': onglet };
if (secret !== '-') h['X-VF-Terminal'] = secret; if (sfs !== '-') h['Sec-Fetch-Site'] = sfs; if (origin !== '-') h.Origin = origin;
if (methode === 'POST') h['Content-Length'] = '1';
const r = http.request({ host: '127.0.0.1', port: +port, path: chemin, method: methode, headers: h, agent: false }, (res) => { console.log(res.statusCode); res.destroy(); process.exit(0); });
r.on('error', (e) => { console.log('ERREUR ' + (e.code || e.message)); process.exit(0); });
setTimeout(() => { console.log('ERREUR ETIMEDOUT'); process.exit(0); }, 4000);
if (methode === 'POST') r.write('x'); r.end();
JS
temoin_compteur T6
srvq; echanger; P6=$SRV_PORT; nav() { node "$AUX/nav.mjs" "$QP" "$@"; }
for ch in /etat /flux; do
  assert_eq "T6.1 — GET $ch sans Origin, Sec-Fetch-Site same-site, secret valide : refus 403" "$(nav GET $ch "$SECRET" same-site -)" "403"
  assert_eq "T6.2 — GET $ch sans Origin, Sec-Fetch-Site cross-site, secret valide : refus 403" "$(nav GET $ch "$SECRET" cross-site -)" "403"
  assert_eq "T6.3 — GET $ch sans Origin, Sec-Fetch-Site none, secret valide : refus 403" "$(nav GET $ch "$SECRET" none -)" "403"
  assert_eq "T6.4 — GET $ch sans Origin ni Sec-Fetch-Site, secret valide : refus 403" "$(nav GET $ch "$SECRET" - -)" "403"
  assert_eq "T6.5 — GET $ch sans Origin, same-origin, sans secret : refus 403" "$(nav GET $ch - same-origin -)" "403"
  assert_eq "T6.6 — GET $ch sans Origin, same-origin, faux secret : refus 403" "$(nav GET $ch "$FAUX6" same-origin -)" "403"
  assert_eq "T6.8 — GET $ch avec l'Origin de P (127.0.0.1:<P>), same-origin, secret valide : refus 403" "$(nav GET $ch "$SECRET" same-origin "http://127.0.0.1:$P6")" "403"
done
assert_eq "T6.7 — POST /entree sans Origin, même en same-origin, secret valide : refus 403" "$(nav POST /entree "$SECRET" same-origin -)" "403"
assert_eq "T6.7b — POST /taille sans Origin, même en same-origin, secret valide : refus 403" "$(nav POST /taille "$SECRET" same-origin -)" "403"
assert_eq "T6.pty — les refus n'ont lancé aucun assistant (0)" "$(pty_compte)" "0"
assert_eq "T6.0 — témoin (navigateur réel) : GET /etat sans Origin, same-origin, secret valide rend 200" "$(nav GET /etat "$SECRET" same-origin -)" "200"
assert_eq "T6.0b — témoin (navigateur réel) : GET /flux sans Origin, same-origin, secret valide rend 200" "$(nav GET /flux "$SECRET" same-origin -)" "200"
unsrv

echo "=== TC — T-71-10 : comparaison du secret en temps constant (sonde statique sur le chemin de comparaison) ==="
sonde_tc() { # sonde_tc <dossier de sortie> -> « egal=<n> directes=<n> condense=<oui|non> » : usages de egal() sur le secret, comparaisons directes, timingSafeEqual dans egal()
  local d="$1" e dir c
  [ -f "$d/vf-cockpit-terminal-processus.mjs" ] || d="$(mod_de "$1")/scripts"   # 79-06 : une sortie ne porte plus de code, le module qu'elle commande oui ; un dossier jetable qui porte les fichiers reste lu tel quel
  e="$(grep -c "egal(req.headers\['x-vf-terminal'\], secret)" "$d/vf-cockpit-terminal-processus.mjs" || true)"
  dir="$(grep -v '^ *//' "$d/vf-cockpit-terminal-processus.mjs" | grep -cE "x-vf-terminal'\] *[!=]==?|[!=]==? *req\.headers\['x-vf-terminal'\]|[!=]==? *secret\b|\bsecret *[!=]==" || true)"
  c="$(grep -c 'crypto.timingSafeEqual' "$d/vf-cockpit-terminal-amorce.mjs" || true)"
  echo "egal=$e directes=$dir condense=$([ "$c" -ge 1 ] && echo oui || echo non)"
}
assert_eq "TC.1 — le secret est comparé par egal() (deux sites : contrôle et routage), aucune comparaison directe, et egal() s'appuie sur timingSafeEqual" "$(sonde_tc "$OUT")" "egal=2 directes=0 condense=oui"
assert_eq "TC.0 — témoin : la sonde voit une comparaison directe dans un fichier jetable" "$(mkdir -p "$WORK/tc0"; printf "if (req.headers['x-vf-terminal'] === secret) {}\n" > "$WORK/tc0/vf-cockpit-terminal-processus.mjs"; : > "$WORK/tc0/vf-cockpit-terminal-amorce.mjs"; sonde_tc "$WORK/tc0")" "egal=0 directes=1 condense=non"

echo "=== TM — moteur : assistant sous .vibeflow/ ou en lien symbolique refusé ==="
srv_moteur() { # srv_moteur <sortie> <dossier du moteur> : le serveur démarre avec ce moteur ; rend le journal dans SRV_OUT ; attend server.json (le terminal n'y vient que s'il est actif)
  local save="$ENG"; ENG="$2"; srv "$1" 1; ENG="$save"
}
terminal_actif() { sj '"terminal" in j' ; }
sonde_moteur() { # sonde_moteur <sortie> <dossier du moteur> -> « terminal=<true|false> journal=<refus|autre> »
  srv_moteur "$1" "$2"; local a j=autre; a="$(terminal_actif)"; grep -q 'assistant du terminal introuvable' "$SRV_OUT" && j=refus
  unsrv; echo "terminal=$a journal=$j"
}
MOT_OK="$WORK/moteur-ok"; rm -rf "$MOT_OK"; cp -R "$ENG" "$MOT_OK"
MOT_VF="$LAB/.vibeflow/moteur-copie"; rm -rf "$MOT_VF"; cp -R "$ENG" "$MOT_VF"
MOT_LIEN="$WORK/moteur-lien"; rm -rf "$MOT_LIEN"; cp -R "$ENG" "$MOT_LIEN"; rm "$MOT_LIEN/terminal/vf-cockpit-pty.py"; ln -s "$ENG/terminal/vf-cockpit-pty.py" "$MOT_LIEN/terminal/vf-cockpit-pty.py"
assert_eq "TM.0 — témoin : une copie ordinaire du moteur, hors du lab, donne un terminal actif" "$(sonde_moteur "$OUT" "$MOT_OK")" "terminal=true journal=autre"
# 79-06 (S3f, audit : classe T-79-601) : serve.mjs refuse lui-même un moteur désigné sous <lab>/.vibeflow/ (VF_COCKPIT_ENGINE_DIR) avant tout démarrage ;
# la garde du terminal (celle que TM.1 et M-MOTEUR-VIBEFLOW visent) devient une défense en profondeur. TM.1b : le serveur du module refuse de démarrer ;
# TM.1 : la même garde retirée de serve.mjs dans une copie du module (SANS_GARDE_SERVE) atteint la garde du terminal, qui refuse toujours : même attendu qu'avant.
SANS_GARDE_SERVE='/^{ const vf = path.join(root, .\.vibeflow.); for (const nom of/d'
assert_eq "TM.1b — moteur sous <lab>/.vibeflow/ : serve.mjs refuse de démarrer (aucun terminal, message en français)" "$(r="$(sonde_moteur "$OUT" "$MOT_VF")"; echo "$r $(grep -c 'VF_COCKPIT_ENGINE_DIR désigne un dossier de données du lab' "$(ls -t "$WORK"/serve-*.out | head -1)")")" "terminal= journal=autre 1"
rm -rf "$MOT_VF" # copie de 3 Mo : les mutants qui suivent copient <lab>/.vibeflow
if mutant sansgarde serve.mjs "$SANS_GARDE_SERVE"; then
  cp -R "$ENG" "$MUT_OUT/../moteur-copie"
  assert_eq "TM.1 — moteur sous <lab>/.vibeflow/ (garde de serve.mjs retirée dans la copie du module) : assistant refusé par le terminal, terminal inerte (journal : assistant introuvable)" "$(sonde_moteur "$MUT_OUT" "$MUT_OUT/../moteur-copie")" "terminal=false journal=refus"
  rm -rf "$MUT_OUT/../moteur-copie"
else assert_eq "TM.1 — copie du module sans la garde de serve.mjs : mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
assert_eq "TM.2 — assistant en lien symbolique : refusé, terminal inerte (journal : assistant introuvable)" "$(sonde_moteur "$OUT" "$MOT_LIEN")" "terminal=false journal=refus"

echo "=== Mutants — chacun rougit sa sonde ==="
rouge() { echo "     [mutant] obtenu $1, le code sain rend $2" >&2; [ "$1" != "$2" ] && echo rouge || echo "identique : $1"; }
mut() { mutant "$1" "$2" "$3" && return 0; assert_eq "$1 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; return 1; }
if mut origine vf-cockpit-terminal-processus.mjs "s/else if (o !== origineQ())/else if (false)/"; then
  srvq "$MUT_OUT"; echanger; assert_eq "M-ORIGIN — le mutant rougit T1.1 : une Origin tierce n'est plus refusée (403)" "$(rouge "$(sta "$QP" POST /entree --secret "$SECRET" --onglet o1 --origin "$EVIL" --corps x)" 403)" "rouge"; unsrv; fi
if mut hote vf-cockpit-terminal-processus.mjs "s/!hotes.includes(String(req.headers.host || '').toLowerCase())/!String(req.headers.host || '').endsWith(':' + portQ)/"; then
  srvq "$MUT_OUT"; echanger; assert_eq "M-HOST — le mutant rougit T2.1 : un Host de rebinding n'est plus refusé (403)" "$(rouge "$(sta "$QP" POST /entree --secret "$SECRET" --onglet o1 --host "evil.example:$QP" --corps x)" 403)" "rouge"; unsrv; fi
if mut jeton vf-cockpit-terminal-processus.mjs "s/!egal(req.headers\['x-vf-terminal'\], secret)/(req.headers['x-vf-terminal'] !== undefined \&\& !egal(req.headers['x-vf-terminal'], secret))/"; then
  srvq "$MUT_OUT"; echanger; assert_eq "M-JETON — le mutant rougit T3.1 : l'absence de secret est admise (≠ 401)" "$(rouge "$(sta "$QP" POST /entree --onglet o1 --corps x)" 401)" "rouge"; unsrv; fi
if mut sansorigine vf-cockpit-terminal-processus.mjs "s/if (!page && !navigateur) return /if (false) return /"; then
  srvq "$MUT_OUT"; echanger; assert_eq "M-SANSORIGIN — le mutant rougit T3.4 : POST /entree sans Origin n'est plus refusé (403)" "$(rouge "$(sta "$QP" POST /entree --secret "$SECRET" --onglet o1 --sans-origin --corps x)" 403)" "rouge"; unsrv; fi
if mut expire vf-cockpit-terminal-amorce.mjs "s/age <= DUREE_AMORCE_MS/true/"; then
  srvq "$MUT_OUT"; AM="$MUT_OUT/.cache/terminal-amorce"; vieillir "$AM" 3600
  assert_eq "M-EXPIRE — le mutant rougit T4.9 : un amorçage vieux d'une heure n'est plus refusé (403)" "$(rouge "$(node "$TA" amorcer "$QP" "$WORK/amorce.copy" | sed -n 1p)" 403)" "rouge"; unsrv; fi
if mut retire vf-cockpit-terminal-processus.mjs 's/^      retirerOuvrir();$/      0;/'; then
  srvq "$MUT_OUT"; PG="$MUT_OUT/.cache/terminal-ouvrir.html"; posee "$PG"; echanger
  assert_eq "M-RETIRE — le mutant rougit T4.10 : la page reste après l'échange" "$([ -f "$PG" ] && echo rouge || echo identique)" "rouge"; unsrv; fi
if mut balai vf-cockpit-terminal-processus.mjs 's/> DUREE_AMORCE_MS) retirerOuvrir/> 1e12) retirerOuvrir/'; then
  srvq "$MUT_OUT"; PG="$MUT_OUT/.cache/terminal-ouvrir.html"; posee "$PG"; vieillir "$PG" 61; sleep 6
  assert_eq "M-BALAI — le mutant rougit T4.11 : une page de plus de 60 s n'est plus balayée" "$([ -f "$PG" ] && echo rouge || echo identique)" "rouge"; unsrv; fi
if mut rejeu vf-cockpit-terminal-amorce.mjs "s/fs\.unlinkSync(fichier)/0/"; then
  srvq "$MUT_OUT"; echanger; assert_eq "M-REJEU — le mutant rougit T4.2 : le rejeu de l'amorçage n'est plus refusé (403)" "$(rouge "$(node "$TA" amorcer "$QP" "$WORK/amorce.copy" | sed -n 1p)" 403)" "rouge"; unsrv; fi
if mut servi vf-cockpit-terminal-processus.mjs 's#return res.end(html);#return res.end(html + String(fs.readFileSync(fichierAmorce, "utf8")));#'; then
  srvq "$MUT_OUT"; rq "$QP" GET / --sans-origin --corps-vers "$WORK/mut-servi.html" > /dev/null
  assert_eq "M-SERVI — le mutant rougit T4.6 : la page de Q contient l'amorçage" "$(rouge "$(cherche "$AMORCE" "$WORK/mut-servi.html" | wc -l | tr -d ' ')" 0)" "rouge"; unsrv; fi
if mut journal vf-cockpit-terminal-processus.mjs "s/log('terminal actif (127.0.0.1 seulement).');/log('terminal actif ' + secret);/"; then
  srvq "$MUT_OUT"; echanger; sleep 0.3; assert_eq "M-LOG — le mutant rougit T5.4 : le journal contient le secret" "$(rouge "$(cherche "$SECRET" "$SRV_OUT" | wc -l | tr -d ' ')" 0)" "rouge"; unsrv; fi
if mut url vf-cockpit-terminal-processus.mjs "s/egal(req.headers\['x-vf-terminal'\], secret)/egal(req.headers['x-vf-terminal'] ?? url.searchParams.get('s'), secret)/"; then
  srvq "$MUT_OUT"; echanger; assert_eq "M-URL — le mutant rougit TD.2 : le secret en ?s= est admis (≠ 401)" "$(rouge "$(sta "$QP" GET "/etat?s=$SECRET")" 401)" "rouge"; unsrv; fi

navmut() { # navmut <nom> <expression sed> <statut sain> <argument de nav>... : le mutant doit changer le statut de la requête refusée
  local nom="$1" sedx="$2" sain="$3"; shift 3
  if mut "$nom" vf-cockpit-terminal-processus.mjs "$sedx"; then srvq "$MUT_OUT"; echanger; P6=$SRV_PORT; local a=(); for x in "$@"; do case "$x" in @S) a+=("$SECRET") ;; @P) a+=("http://127.0.0.1:$P6") ;; *) a+=("$x") ;; esac; done # le secret et le port changent à chaque serveur : substitués ici
    assert_eq "M-$nom — le mutant assouplit trop : la requête refusée n'est plus refusée ($sain)" "$(rouge "$(node "$AUX/nav.mjs" "$QP" "${a[@]}")" "$sain")" "rouge"; unsrv; fi
}
navmut NAV-SFS "s/req.headers\['sec-fetch-site'\] === 'same-origin'/req.headers['sec-fetch-site'] !== undefined/" 403 GET /etat @S same-site -
navmut NAV-SANS-SFS "s/ *&& req.headers\['sec-fetch-site'\] === 'same-origin' &&/ \&\&/" 403 GET /etat @S - -
navmut NAV-SANS-SECRET "s/ && egal(req.headers\['x-vf-terminal'\], secret);/;/" 403 GET /etat - same-origin -
navmut NAV-POST "s/req.method === 'GET' \&\& (url.pathname === '\/flux' || url.pathname === '\/etat')/true/" 403 POST /entree @S same-origin -
navmut NAV-ORIGIN "s/else if (o !== origineQ())/else if (o !== origineQ() \&\& !navigateur)/" 403 GET /etat @S same-origin @P

echo "=== M-TD1 / M-TEMPS-CONSTANT / M-EGAL / M-MOTEUR-* — mutants de la tenue du serveur ==="
if mut td1 vf-cockpit-terminal-processus.mjs "s|^\(  const q = http.createServer.*\)\$|\1 q.on('upgrade', (rq2, so) => { so.end('HTTP/1.1 101 Switching Protocols\\\\r\\\\nUpgrade: websocket\\\\r\\\\n\\\\r\\\\n'); });|"; then
  srvq "$MUT_OUT"; echanger; assert_eq "M-TD1 — le mutant (écouteur « upgrade » qui accepte la montée) rougit TD.1 : 101 au lieu de 401" "$(rouge "$(node "$AUX/upg.mjs" "$QP" /flux '' "http://127.0.0.1:$QP")" 401)" "rouge"; unsrv; fi
if mut tc vf-cockpit-terminal-processus.mjs "s/egal(req.headers\['x-vf-terminal'\], secret)/req.headers['x-vf-terminal'] === secret/g"; then
  assert_eq "M-TEMPS-CONSTANT — le mutant (comparaison directe ===) rougit TC.1" "$(rouge "$(sonde_tc "$MUT_OUT")" "egal=2 directes=0 condense=oui")" "rouge"; fi
if mut egal vf-cockpit-terminal-amorce.mjs "s/return crypto.timingSafeEqual(condense(a), condense(b));/return a === b;/"; then
  assert_eq "M-EGAL — le mutant (egal() sans timingSafeEqual) rougit TC.1" "$(rouge "$(sonde_tc "$MUT_OUT")" "egal=2 directes=0 condense=oui")" "rouge"; fi
if mut moteurvf vf-cockpit-terminal.mjs "s/ && !realUnder(f, path.join(root, '.vibeflow'), { siEchec: true })//"; then
  cp -R "$ENG" "$MUT_OUT/../moteur-copie"
  MSV="$MUT_MOD/skills/cockpit-moteur/assets/serve.mjs"; cp "$MSV" "$MSV.orig"; sed -i.bak "$SANS_GARDE_SERVE" "$MSV"; cmp -s "$MSV" "$MSV.orig" && assert_eq "M-MOTEUR-VIBEFLOW — garde de serve.mjs : mutant sans effet" "sans effet" "effet"; rm -f "$MSV.orig" "$MSV.bak"
  assert_eq "M-MOTEUR-VIBEFLOW — le mutant (plus de refus sous .vibeflow/, la garde de serve.mjs retirée dans la même copie) rougit TM.1 : le terminal devient actif" "$(rouge "$(sonde_moteur "$MUT_OUT" "$MUT_OUT/../moteur-copie")" "terminal=false journal=refus")" "rouge"; fi
if mut moteurlien vf-cockpit-terminal.mjs "s/fs.lstatSync(f).isFile()/fs.statSync(f).isFile()/"; then
  assert_eq "M-MOTEUR-LIEN — le mutant (lstat remplacé par stat : le lien est suivi) rougit TM.2 : le terminal devient actif" "$(rouge "$(sonde_moteur "$MUT_OUT" "$MOT_LIEN")" "terminal=false journal=refus")" "rouge"; fi

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
