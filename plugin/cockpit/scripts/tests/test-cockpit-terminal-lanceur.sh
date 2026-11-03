#!/usr/bin/env bash
# test-cockpit-terminal-lanceur.sh — lanceur du terminal intégré : drapeau, amorçage, ouverture de Q, cockpit déjà vivant, Windows, arrêt
# (TERM-01, TERM-03, TERM-04, TERM-07 ; P71-D-02, D-07, D-11, D-12 ; P71-D-21 : O2, O3).
#   L0  témoin : build et status répondent        L1  `open --terminal --no-open` sort 0 (sans drapeau : 64 « argument inconnu »)
#   L2  server.json porte terminal.url            L3  amorçage en mode 600
#   L4  lien préplacé : jamais suivi (O3)         L5  l'amorçage n'est ni dans la sortie, ni dans le journal, ni dans server.json, ni dans ps
#   L6  l'ouvreur reçoit http://127.0.0.1:<Q>/#t=<64 hex>, une seule fois (D-12)
#   L7  O2 a : serveur vivant sans terminal -> relancé    L8 O2 c : serveur vivant avec terminal -> même PID, nouvel amorçage, l'ancien refusé
#   L9  échange, flux, commande, puis `stop` : serveur, assistant et shell disparus   L10 win32 simulé : message, ni amorçage ni ouverture
#   L11 server.json qui désigne un PID leurre : le leurre reste vivant, sortie 5
#   M-*  mutants (copies du module, jamais le module) : M-MODE (L3), M-SUIT-LIEN (L4), M-IMPRIME (L5), M-OUVRE-P (L6), M-LEURRE-TERMINAL (L11b)
#   L5.0 le contrôle de l'environnement du serveur est JOUÉ sous Linux (/proc/<pid>/environ) comme sous macOS (ps -Eww), jamais sauté faute de la forme BSD
# Aucun vrai navigateur : `open` et `xdg-open` factices en tête du PATH. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
MODULE="$(cd "$SCRIPTS/.." && pwd)"; LAUNCH="$SCRIPTS/vf-cockpit.mjs"; TA="$HERE_T/terminal-aux.mjs"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/bin" "$WORK/run" "$WORK/fauxbin"
cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
PIDS=(); PASS=0; FAIL=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }

cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/mode.mjs" <<'JS'
import fs from 'node:fs'; try { console.log((fs.lstatSync(process.argv[2]).mode & 0o777).toString(8)); } catch { console.log('absent'); }
JS
cat > "$AUX/win32.mjs" <<'JS'
Object.defineProperty(process, 'platform', { value: 'win32' });
JS
# ouvreurs factices : jamais le vrai navigateur du poste
for o in open xdg-open; do printf '#!/bin/sh\necho "$@" >> "%s/run/ouvert.txt"\n' "$WORK" > "$WORK/fauxbin/$o"; chmod +x "$WORK/fauxbin/$o"; done
OUVERT="$WORK/run/ouvert.txt"
cat > "$WORK/bin/shell-test" <<SH
#!/bin/sh
echo \$\$ > "$WORK/run/shell.pid"
/bin/sh -i
SH
chmod +x "$WORK/bin/shell-test"; export SHELL="$WORK/bin/shell-test"

NL=0; LRC=0; LOUT=""
lance() { local l="$1"; shift; NL=$((NL+1)); LOUT="$WORK/lance-$NL.out"; (cd "$LAB" && PATH="$WORK/fauxbin:$PATH" node "$l" "$@" --lab "$LAB" --port "$(libre)" > "$LOUT" 2>&1); LRC=$?; }
mklab() {
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"; printf 'export const u = 1;\n' > "$L/src/u.js"
  printf -- '## Phases\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Goal**: Poser le socle\n' > "$B/ROADMAP.md"
  printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0 MVP\n---\n' > "$B/STATE.md"
  printf -- '---\nwave: 1\nfiles_modified: [src/u.js]\n---\n<objective>Poser le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
}
LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"; AM="$OUT/.cache/terminal-amorce"; SJ="$OUT/.cache/server.json"
sj() { [ -f "$SJ" ] && node "$AUX/ev.mjs" "$1" < "$SJ" 2>/dev/null; true; }
nbl() { awk 'END{print NR+0}' "$1" 2>/dev/null || echo 0; }
nbt() { local n; n="$(grep -c "$2" "$1" 2>/dev/null)"; echo "${n:-0}"; }
qport() { local u; u="$(sj '(j.terminal&&j.terminal.url)||""')"; echo "${u##*:}"; }
mode() { node "$AUX/mode.mjs" "$1"; }
arrete() { lance "$LAUNCH" stop; }
attendre_mort() { local p="$1"; for _ in $(seq 1 60); do kill -0 "$p" 2>/dev/null || return 0; sleep 0.1; done; return 1; }
fichier_ouvert() { for _ in $(seq 1 40); do [ -s "$OUVERT" ] && break; sleep 0.1; done; }
mutant() { # mutant <nom> <sed...> -> MUT_L (lanceur de la copie) ; code 1 si la copie n'a pas changé
  local d="$WORK/mut-$1"; shift; rm -rf "$d"; mkdir -p "$d"; cp -R "$MODULE/." "$d/"; MUT_L="$d/scripts/vf-cockpit.mjs"
  cp "$MUT_L" "$MUT_L.orig"; sed -i.bak "$@" "$MUT_L"; local r=0; cmp -s "$MUT_L" "$MUT_L.orig" && r=1; rm -f "$MUT_L.orig" "$MUT_L.bak"; return $r
}

echo "=== L0 — témoin : le lab se construit, status répond ==="
lance "$LAUNCH" build
assert_eq "L0 — build sort 0 et pose la sortie" "$LRC $([ -f "$OUT/serve.mjs" ] && echo serve || echo vide)" "0 serve"
lance "$LAUNCH" status
assert_eq "L0 — status dit « Cockpit arrêté. » avant tout lancement" "$(cat "$LOUT")" "Cockpit arrêté."

echo "=== L1, L2, L3, L5 — open --terminal --no-open ==="
lance "$LAUNCH" open --terminal --no-open; LOUT_A="$LOUT"
assert_eq "L1 — open --terminal --no-open sort 0" "$LRC" "0"
QA="$(qport)"; PA="$(sj j.port)"
assert_eq "L2 — server.json porte terminal.url de forme http://127.0.0.1:<Q>, Q différent de P" "$([[ "$(sj '(j.terminal&&j.terminal.url)||""')" =~ ^http://127\.0\.0\.1:[0-9]+$ ]] && [ "$QA" != "$PA" ] && echo oui || echo "non : $(sj 'j.terminal')")" "oui"
assert_eq "L3 — le fichier d'amorçage est en mode 600" "$(mode "$AM")" "600"
V="$(cat "$AM" 2>/dev/null)"; SPID="$(sj j.pid)"
assert_eq "L5 — témoin : l'amorçage lu est 64 hexadécimaux" "$([[ "$V" =~ ^[0-9a-f]{64}$ ]] && echo oui || echo "non : ${V:-vide}")" "oui"
cherche() { if [ -z "$V" ]; then echo "pas de valeur"; else cat "$@" 2>/dev/null | grep -c -F -e "$V" || true; fi; }
PSCMD="$(ps -o command= -p "$SPID" 2>/dev/null)"
# environnement du serveur : /proc/<pid>/environ (Linux, séparé par NUL) d'abord, `ps -Eww` (BSD, macOS) ensuite ; VF_PROC_ROOT ne sert qu'à la sonde L5.0
env_du_serveur() { local f="${VF_PROC_ROOT:-/proc}/$1/environ"; if [ -r "$f" ]; then tr '\0' '\n' < "$f"; else ps -Eww -o command= -p "$1" 2>/dev/null; fi; }
verdict_env() { # verdict_env <pid> <valeur> -> « saute » (environnement illisible) ou « oui » (valeur absente) / « non » (valeur présente)
  local e; e="$(env_du_serveur "$1")"
  if [[ "$e" == *VF_COCKPIT_SCRIPTS_DIR* ]]; then if [[ "$e" == *"$2"* ]]; then echo non; else echo oui; fi; else echo saute; fi
}
mkdir -p "$WORK/fauxproc/4242" "$WORK/fauxps"; printf 'A=1\0VF_COCKPIT_SCRIPTS_DIR=/x\0B=secret-temoin\0' > "$WORK/fauxproc/4242/environ"
printf '#!/bin/sh\nexit 1\n' > "$WORK/fauxps/ps"; chmod +x "$WORK/fauxps/ps"
assert_eq "L5.0 — sous une forme de ps qui refuse -E (Linux) et avec /proc/<pid>/environ : le contrôle est joué, jamais sauté (valeur absente -> oui, valeur présente -> non)" "$(PATH="$WORK/fauxps:$PATH" VF_PROC_ROOT="$WORK/fauxproc" verdict_env 4242 absente-du-tout) $(PATH="$WORK/fauxps:$PATH" VF_PROC_ROOT="$WORK/fauxproc" verdict_env 4242 secret-temoin) $(PATH="$WORK/fauxps:$PATH" VF_PROC_ROOT="$WORK/inexistant" verdict_env 4242 x)" "oui non saute"
PSENV_V="$(verdict_env "$SPID" "$V")"
assert_eq "L5 — témoin : la recherche trouve la valeur dans le fichier d'amorçage" "$(cherche "$AM")" "1"
assert_eq "L5 — l'amorçage n'est pas dans la sortie du lanceur" "$(cherche "$LOUT_A")" "0"
assert_eq "L5 — l'amorçage n'est pas dans le journal du serveur" "$(cherche "$OUT/.cache/serveur.log")" "0"
assert_eq "L5 — l'amorçage n'est pas dans server.json" "$(cherche "$SJ")" "0"
assert_eq "L5 — l'amorçage n'est pas dans la ligne de commande du serveur (témoin : elle cite serve.mjs)" "$([[ "$PSCMD" == *serve.mjs* ]] && ! [[ "$PSCMD" == *"$V"* ]] && echo oui || echo "non : $PSCMD")" "oui"
if [ "$PSENV_V" != saute ]; then assert_eq "L5 — l'amorçage n'est pas dans l'environnement du serveur (témoin : l'environnement est lisible et porte VF_COCKPIT_SCRIPTS_DIR)" "$PSENV_V" "oui"
else echo "  ⚠ SKIP — L5 environnement : illisible sur ce poste (ni /proc/<pid>/environ ni ps -Eww)"; fi
assert_eq "L6 — témoin : --no-open, aucune ouverture" "$([ -s "$OUVERT" ] && echo ouvert || echo rien)" "rien"
arrete; attendre_mort "$SPID"

echo "=== L6 — l'ouvreur reçoit l'adresse de Q avec l'amorçage dans le fragment ==="
rm -f "$OUVERT"; lance "$LAUNCH" open --terminal; fichier_ouvert; sleep 0.5
QB="$(qport)"; PB="$(sj j.port)"; SPID="$(sj j.pid)"
assert_eq "L6 — une seule ouverture" "$(nbl "$OUVERT")" "1"
ADR="$(sed -n 1p "$OUVERT" 2>/dev/null)"; VB="$(cat "$AM" 2>/dev/null)"
assert_eq "L6 — l'adresse ouverte est http://127.0.0.1:<Q>/#t=<amorçage du fichier>, Q ≠ P" "$([ -n "$QB" ] && [ "$QB" != "$PB" ] && [ "$ADR" = "http://127.0.0.1:$QB/#t=$VB" ] && [[ "$VB" =~ ^[0-9a-f]{64}$ ]] && echo oui || echo "non : [$ADR] Q=$QB P=$PB")" "oui"
arrete; attendre_mort "$SPID"

echo "=== L4 — un lien préplacé n'est jamais suivi (O3) ==="
# deux couches : la garde « aucun lien dans la sortie » (assemblage, puis verifierSortie) et, dans ecrireAmorce, suppression préalable + création exclusive
verdict_lien() { # verdict_lien <sortie du lanceur> : « sur » si la cible est intacte ET (fichier ordinaire OU refus nommé)
  local ok=non; if [ "$(cksum < "$WORK/cible")" = "$EMP" ]; then if [ ! -L "$AM" ] && [ -f "$AM" ]; then ok=sur; elif grep -q -e 'amorçage du terminal impossible' -e 'lien symbolique refusé' "$1"; then ok=sur; fi; fi; echo "$ok"
}
printf 'contenu-cible\n' > "$WORK/cible"; EMP="$(cksum < "$WORK/cible")"; rm -f "$AM"; mkdir -p "$OUT/.cache"; ln -s "$WORK/cible" "$AM"
lance "$LAUNCH" open --terminal --no-open; SPID="$(sj j.pid)"
assert_eq "L4 — serveur arrêté, lien préplacé : la cible est intacte, refus nommé ou fichier ordinaire" "$(verdict_lien "$LOUT")" "sur"
rm -f "$AM"; [ -n "$SPID" ] && { arrete; attendre_mort "$SPID"; }
lance "$LAUNCH" open --terminal --no-open; SPID="$(sj j.pid)"; rm -f "$AM"; ln -s "$WORK/cible" "$AM"
lance "$LAUNCH" open --terminal --no-open
assert_eq "L4 — serveur vivant avec terminal (O2 c), lien préplacé : la cible est intacte, refus nommé ou fichier ordinaire" "$(verdict_lien "$LOUT")" "sur"
rm -f "$AM"; arrete; [ -n "$SPID" ] && attendre_mort "$SPID"

echo "=== L7 — O2 a : serveur vivant sans terminal, relancé avec le drapeau ==="
lance "$LAUNCH" open --no-open; P7="$(sj j.pid)"
assert_eq "L7 — témoin : sans le drapeau, le lanceur se comporte comme en v2.75.0 (sortie 0, pas de clé terminal)" "$LRC $(sj '"terminal" in j')" "0 false"
lance "$LAUNCH" open --terminal --no-open; N7="$(sj j.pid)"
assert_eq "L7 — le PID du serveur a changé, l'ancien est mort, terminal.url est présent" "$([ -n "$N7" ] && [ "$N7" != "$P7" ] && ! kill -0 "$P7" 2>/dev/null && [ -n "$(qport)" ] && echo oui || echo "non : $P7 -> $N7")" "oui"

echo "=== L8 — O2 c : serveur vivant avec terminal, même PID, nouvel amorçage ==="
cp "$AM" "$WORK/amorce1.copy"; Q8="$(qport)"
assert_eq "L8 — l'amorçage 1 est accepté (200)" "$(node "$TA" amorcer "$Q8" "$WORK/amorce1.copy" | sed -n 1p)" "200"
lance "$LAUNCH" open --terminal --no-open; cp "$AM" "$WORK/amorce2.copy" 2>/dev/null
assert_eq "L8 — même PID de serveur, sortie 0" "$LRC $(sj j.pid)" "0 $N7"
assert_eq "L8 — nouvel amorçage en 600, différent du premier" "$(mode "$AM") $([ -s "$WORK/amorce2.copy" ] && ! cmp -s "$WORK/amorce1.copy" "$WORK/amorce2.copy" && echo different || echo identique)" "600 different"
assert_eq "L8 — l'ancien amorçage est refusé (403)" "$(node "$TA" amorcer "$Q8" "$WORK/amorce1.copy" | sed -n 1p)" "403"
read -r C8 SECRET < <(node "$TA" amorcer "$Q8" "$WORK/amorce2.copy" | tr '\n' ' ')
assert_eq "L8 — le nouvel amorçage est accepté (200, secret de 64 hexadécimaux)" "$C8 $([[ "$SECRET" =~ ^[0-9a-f]{64}$ ]] && echo secret-64-hex || echo "invalide : ${SECRET:-vide}")" "200 secret-64-hex"

echo "=== L9 — flux, commande, puis stop : plus rien ne survit ==="
[[ "$SECRET" =~ ^[0-9a-f]{64}$ ]] || SECRET=""
FPID=""; APID=""; TROUVE="pas de secret"
if [ -n "$SECRET" ]; then
  node "$TA" flux "$Q8" "$SECRET" onglet-test-1 "$WORK/flux.out" 25000 > "$WORK/flux.log" 2>&1 & FPID=$!
  for _ in $(seq 1 50); do [ -n "$N7" ] && [ -n "$(pgrep -P "$N7")" ] && break; sleep 0.1; done
  node "$TA" entree "$Q8" "$SECRET" onglet-test-1 "echo TRAC''EUR-OK\\r" > /dev/null 2>&1
  TROUVE="$(node "$TA" attendre "$WORK/flux.out" TRACEUR-OK 10000)"
fi
assert_eq "L9 — une commande envoyée revient dans le flux (TRACEUR-OK)" "$TROUVE" "TROUVE"
APID=""; [ -n "$N7" ] && APID="$(pgrep -P "$N7" | sed -n 1p)"; SHPID="$(cat "$WORK/run/shell.pid" 2>/dev/null)"
arrete
SURV=""; if [ -n "$APID" ] && [ -n "$SHPID" ]; then
  for _ in $(seq 1 50); do SURV=""; for p in $N7 $APID $SHPID; do kill -0 "$p" 2>/dev/null && SURV="$SURV $p"; done; [ -z "$SURV" ] && break; sleep 0.1; done
else SURV="rien à surveiller (assistant=${APID:-aucun} shell=${SHPID:-aucun})"; fi
assert_eq "L9 — stop : serveur, assistant et shell disparus en moins de 5 s" "${SURV:-aucun}" "aucun"
[ -n "$FPID" ] && { wait "$FPID" 2>/dev/null; true; }

echo "=== L10 — plateforme win32 simulée : message, aucun amorçage, aucune ouverture de Q ==="
rm -f "$OUVERT" "$AM"; NL=$((NL+1)); LOUT="$WORK/lance-$NL.out"
(cd "$LAB" && PATH="$WORK/fauxbin:$PATH" node --import "file://$AUX/win32.mjs" "$LAUNCH" open --terminal --lab "$LAB" --port "$(libre)" > "$LOUT" 2>&1); LRC=$?
sleep 0.5; S10="$(sj j.pid)"
assert_has "L10 — le message « Terminal indisponible sous Windows. » est rendu" "$(cat "$LOUT")" "Terminal indisponible sous Windows."
assert_eq "L10 — aucun fichier d'amorçage, aucune ouverture à fragment #t=" "$([ -e "$AM" ] && echo amorce || echo sans-amorce) $(nbt "$OUVERT" '#t=')" "sans-amorce 0"
arrete; [ -n "$S10" ] && attendre_mort "$S10"

echo "=== L11 — server.json désigne un PID leurre : jamais arrêté, sortie 5 ==="
node -e 'setInterval(()=>{},1000)' "$WORK/leurre" & LEURRE=$!; PIDS+=($LEURRE)
mkdir -p "$OUT/.cache"; rm -f "$SJ"
printf '{"pid":%s,"port":9,"url":"http://127.0.0.1:9","token":"x","startedAt":"2026-01-01T00:00:00.000Z"}\n' "$LEURRE" > "$SJ"
lance "$LAUNCH" open --rebuild --no-open
assert_eq "L11 — garde existante : --rebuild sur un PID leurre, sortie 5 et leurre vivant" "$LRC $(kill -0 "$LEURRE" 2>/dev/null && echo vivant || echo mort)" "5 vivant"
lance "$LAUNCH" open --terminal --no-open
assert_eq "L11b — avec --terminal (O2 a), le PID leurre n'est jamais arrêté : sortie 5, leurre vivant, aucun amorçage posé" "$LRC $(kill -0 "$LEURRE" 2>/dev/null && echo vivant || echo mort) $([ -e "$AM" ] && echo amorce || echo sans-amorce)" "5 vivant sans-amorce"
vf_hyg_stop "$LEURRE"; rm -f "$SJ"

echo "=== M-MODE / M-SUIT-LIEN / M-IMPRIME / M-OUVRE-P — mutants du lanceur ==="
if mutant mode 's/MODE_AMORCE = 0o600/MODE_AMORCE = 0o644/'; then
  lance "$MUT_L" open --terminal --no-open; MS="$(sj j.pid)"; MM="$(mode "$AM")"
  assert_eq "M-MODE — le mutant rougit L3 (mode ≠ 600)" "$([ "$MM" != 600 ] && echo rouge || echo "identique : $MM")" "rouge"
  arrete; [ -n "$MS" ] && attendre_mort "$MS"
else assert_eq "M-MODE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant lien -e "s/fs.unlinkSync(f)/0/" -e "s/'wx'/'w'/" -e "s/verifierSortie(lab, sortie); return/return/"; then
  lance "$LAUNCH" open --terminal --no-open; MS="$(sj j.pid)"
  printf 'contenu-cible\n' > "$WORK/cible"; EMP="$(cksum < "$WORK/cible")"; rm -f "$AM"; ln -s "$WORK/cible" "$AM"
  lance "$MUT_L" open --terminal --no-open
  assert_eq "M-SUIT-LIEN — le mutant (sans suppression préalable, sans création exclusive, sans garde) rougit L4 : la cible est écrasée" "$([ "$(cksum < "$WORK/cible")" != "$EMP" ] && echo rouge || echo "identique")" "rouge"
  rm -f "$AM"; arrete; [ -n "$MS" ] && attendre_mort "$MS"
else assert_eq "M-SUIT-LIEN — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant imprime 's|^function ouvrirQ(s, amorce, o) {|& console.log(amorce);|'; then
  rm -f "$AM"; lance "$MUT_L" open --terminal --no-open; MS="$(sj j.pid)"; V="$(cat "$AM" 2>/dev/null)"
  assert_eq "M-IMPRIME — le mutant rougit L5 (valeur dans la sortie du lanceur)" "$([ -n "$V" ] && [ "$(cherche "$LOUT")" != 0 ] && echo rouge || echo "identique")" "rouge"
  arrete; [ -n "$MS" ] && attendre_mort "$MS"
else assert_eq "M-IMPRIME — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant ouvrep 's|s\.terminal\.url}/#t=|s.url}/#t=|'; then
  rm -f "$OUVERT" "$AM"; lance "$MUT_L" open --terminal; fichier_ouvert; sleep 0.5; MS="$(sj j.pid)"; MQ="$(qport)"
  assert_eq "M-OUVRE-P — le mutant rougit L6 (l'adresse ouverte n'est plus celle de Q)" "$([[ "$(sed -n 1p "$OUVERT" 2>/dev/null)" != "http://127.0.0.1:$MQ/#t="* ]] && echo rouge || echo "identique")" "rouge"
  arrete; [ -n "$MS" ] && attendre_mort "$MS"
else assert_eq "M-OUVRE-P — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

echo "=== M-LEURRE-TERMINAL — le garde de l'arrêt n'est plus tenu quand --terminal est donné ==="
if mutant leurreterm 's/if (vif) { if (!arreter(sortie))/if (vif) { if (o.avecQ ? false : !arreter(sortie))/'; then
  node -e 'setInterval(()=>{},1000)' "$WORK/leurre-m" & LEURRE_M=$!; PIDS+=($LEURRE_M)
  mkdir -p "$OUT/.cache"; rm -f "$SJ"
  printf '{"pid":%s,"port":9,"url":"http://127.0.0.1:9","token":"x","startedAt":"2026-01-01T00:00:00.000Z"}\n' "$LEURRE_M" > "$SJ"
  lance "$MUT_L" open --terminal --no-open; RC_M="$LRC"; S_M="$(sj j.pid)"
  assert_eq "M-LEURRE-TERMINAL — le mutant (arrêt sans garde sur la voie --terminal) rougit L11b : la sortie n'est plus 5" "$([ "$RC_M" != 5 ] && echo rouge || echo "identique : $RC_M")" "rouge"
  [ -n "$S_M" ] && [ "$S_M" != "$LEURRE_M" ] && { arrete; attendre_mort "$S_M"; }
  vf_hyg_stop "$LEURRE_M"; rm -f "$SJ"
else assert_eq "M-LEURRE-TERMINAL — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
