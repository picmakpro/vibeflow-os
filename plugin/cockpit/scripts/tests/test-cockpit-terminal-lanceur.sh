#!/usr/bin/env bash
# test-cockpit-terminal-lanceur.sh — lanceur du terminal intégré : drapeau, amorçage, ouverture de Q, cockpit déjà vivant, Windows, arrêt
# (TERM-01, TERM-03, TERM-04, TERM-07 ; P71-D-02, D-07, D-11, D-12 ; P71-D-21 : O2, O3).
#   L0  témoin : build et status répondent        L1  `open --terminal --no-open` sort 0 (sans drapeau : 64 « argument inconnu »)
#   L2  server.json porte terminal.url            L3  amorçage en mode 600
#   L4  lien préplacé : jamais suivi (O3)         L5  l'amorçage n'est ni dans la sortie, ni dans le journal, ni dans server.json, ni dans ps
#   L6  l'ouvreur reçoit le CHEMIN d'une page de redirection (0600) vers la page Projet http://127.0.0.1:<P>/project.html#t=<64 hex> (SAF-1 : l'échange se fait dans le cadre de Q, jamais au premier niveau), une seule fois ; l'amorçage n'est jamais dans son argv (D-12, D-27)
#   L7  O2 a : serveur vivant sans terminal -> relancé    L8 O2 c : serveur vivant avec terminal -> même PID, nouvel amorçage, l'ancien refusé
#   L9  échange, flux, commande, puis `stop` : serveur, assistant et shell disparus   L10 win32 simulé : message, ni amorçage ni ouverture
#   L11 server.json qui désigne un PID leurre : le leurre reste vivant, sortie 5
#   L12 F1 : server.json planté (PID étranger, terminal.url file:///…) : l'ouvreur ne reçoit jamais cette adresse (D-25)
#   L13 F6 : page de redirection en 0600, jamais suivie par un lien, supprimée à l'échange, balayée à 60 s ; amorçage refusé après 60 s (D-27)
#   L14 ouvreur absent : erreur asynchrone rattrapée, marche à suivre dite (M6)  L15 navigateur qui ne charge pas la page : annoncé, jamais un succès muet ; témoin d'un ouvreur conforme
#   L4  N6a : lien planté sur le chemin de sortie, serveur vivant : message, code 4, aucune trace
#   M-*  mutants (copies du module, jamais le module) : M-MODE (L3), M-SUIT-LIEN (L4), M-IMPRIME (L5), M-OUVRE-P (L6), M-LEURRE-TERMINAL (L11b),
#        M-F1-PID (L12a), M-F1-VALID (L12b), M-ARGV (L6), M-PAGE-MODE, M-PAGE-LIEN (L13), M-OUVREUR-ERREUR (L14), M-SANS-ANNONCE, M-TOUJOURS-ANNONCE (L15), M-SANS-RATTRAPAGE (L4)
#   L19 E4 : --terminal sans python3 : message, aucun amorçage ni Q, cockpit ouvert sans terminal, sortie 0 (M-SANS-PYTHON3)
#   L20 E5 : serveur qui écrit son état après 15 s : attente jusqu'à 30 s, « démarrage lent » une fois, sortie 0 ; la borne reste (M-BORNE-10)
#   L5.0 le contrôle de l'environnement du serveur est JOUÉ sous Linux (/proc/<pid>/environ) comme sous macOS (ps -Eww), jamais sauté faute de la forme BSD
#   L16b N12 : dossier ABSOLU du lab dans le PATH (<lab>/bin) jamais exécuté (open, xdg-open, ps) ni pris pour python3 ; mutant M-PATH-BRUT
#   L16 N2 (P71-D-29) : un lab qui porte open, xdg-open, ps et git exécutables n'en voit aucun lancé sous PATH=.:…, :…, …: et bin:… ; mutants M-OUVRE-NOMNU, M-PS-NOMNU, M-GIT-NOMNU, M-WHO-NOMNU, M-SERVE-OUVRE, M-PS-FINAL
# Aucun vrai navigateur : `open` et `xdg-open` factices en tête du PATH. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export VF_COCKPIT_OUVERTURE_MS=300 # attente de l'ouverture réelle (M6) : 15 s par défaut, ramenée ici (les ouvreurs factices n'échangent jamais l'amorçage) ; L15 la règle à part
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
# l'argv est consigné ; si l'argument est un fichier, son contenu est copié (la page est supprimée après l'échange)
for o in open xdg-open; do printf '#!/bin/sh\necho "$@" >> "%s/run/ouvert.txt"\nfor a in "$@"; do [ -f "$a" ] && cat "$a" > "%s/run/page-ouverte.html"; done\n' "$WORK" "$WORK" > "$WORK/fauxbin/$o"; chmod +x "$WORK/fauxbin/$o"; done
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
rm -f "$OUVERT" "$WORK/run/page-ouverte.html"; lance "$LAUNCH" open --terminal; fichier_ouvert; sleep 0.5
QB="$(qport)"; PB="$(sj j.port)"; SPID="$(sj j.pid)"
assert_eq "L6 — une seule ouverture" "$(nbl "$OUVERT")" "1"
ADR="$(sed -n 1p "$OUVERT" 2>/dev/null)"; VB="$(cat "$AM" 2>/dev/null)"; PAGE="$OUT/.cache/terminal-ouvrir.html"
assert_eq "L6 — l'ouvreur reçoit le chemin de la page de redirection, rien d'autre (D-27)" "$([ "$ADR" = "$PAGE" ] && echo oui || echo "non : [$ADR]")" "oui"
assert_eq "L6 — l'argv de l'ouvreur ne porte pas l'amorçage (témoin : amorçage de 64 hexadécimaux)" "$([[ "$VB" =~ ^[0-9a-f]{64}$ ]] && ! grep -q -F -e "$VB" "$OUVERT" && echo oui || echo "non : $(court "$(cat "$OUVERT")")")" "oui"
assert_eq "L6 — SAF-1 : la page de redirection mène à la page Projet http://127.0.0.1:<P>/project.html#t=<amorçage du fichier>, jamais à Q (Q ≠ P)" "$([ -n "$QB" ] && [ -n "$PB" ] && [ "$QB" != "$PB" ] && grep -q -E "url=http://127\.0\.0\.1:$PB/project\.html\?o=[0-9a-f]{64}#t=$VB\"" "$WORK/run/page-ouverte.html" && ! grep -q -F ":$QB/" "$WORK/run/page-ouverte.html" && echo oui || echo "non : Q=$QB P=$PB $(court "$(cat "$WORK/run/page-ouverte.html" 2>/dev/null)")")" "oui"
assert_eq "L13 — la page de redirection est en mode 600 (jamais lisible d'un autre compte)" "$(mode "$PAGE")" "600"
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
assert_eq "L4 — N6a : lien préplacé sur le chemin de sortie en voie de réutilisation du serveur : message clair, code 4 documenté, aucune trace de pile (jamais le code 1 d'une exception non rattrapée)" "$LRC $(grep -c -e 'node:internal' -e '^ *at ' "$LOUT" || true) $(grep -c 'lien symbolique refusé' "$LOUT" || true)" "4 0 1"
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


echo "=== L12 — F1 : server.json planté, jamais une adresse du lab remise à l'ouvreur (P71-D-25) ==="
PAGE="$OUT/.cache/terminal-ouvrir.html"
vieillir() { node -e "const fs=require('fs');const t=(Date.now()-Number(process.argv[2])*1000)/1000;fs.utimesSync(process.argv[1],t,t)" "$1" "$2"; }
adresse_nue() { # adresse_nue <ouvert.txt> : « oui » si chaque ligne est vide, ou http://127.0.0.1:<port> seul, ou le chemin de la page (jamais autre chose)
  local l ok=oui; while IFS= read -r l; do [ -z "$l" ] && continue; [ "$l" = "$PAGE" ] && continue; [[ "$l" =~ ^http://127\.0\.0\.1:[0-9]{1,5}(/)?$ ]] || ok="non : $l"; done < "$1"; echo "$ok"
}
planter() { mkdir -p "$OUT/.cache"; rm -f "$SJ"; printf '%s\n' "$1" > "$SJ"; }
arrete; sleep 0.3
PLANT_FILE='{"pid":1,"port":1234,"url":"http://127.0.0.1:1234","token":"x","terminal":{"url":"file:///System/Applications/Calculator.app"}}'
PLANT_HTTP='{"pid":1,"port":1234,"url":"http://127.0.0.1:1234","token":"x","terminal":{"url":"http://127.0.0.1:1235"}}'
planter "$PLANT_FILE"; rm -f "$OUVERT" "$AM"; lance "$LAUNCH" open --terminal; sleep 1
assert_eq "L12a — server.json planté (PID 1, terminal.url file:///…) : l'ouvreur ne reçoit rien du lab, sortie 5 sans attente (témoin : l'état planté est toujours là)" "$LRC $(cat "$OUVERT" 2>/dev/null | grep -c 'file:') $( [ -f "$OUVERT" ] && adresse_nue "$OUVERT" || echo oui) $([ -f "$SJ" ] && echo etat)" "5 0 oui etat"
planter "$PLANT_HTTP"; rm -f "$OUVERT" "$AM"; lance "$LAUNCH" open --terminal; sleep 1
assert_eq "L12a — PID étranger même avec une adresse http vraisemblable : rien n'est ouvert (le processus n'est pas le serveur de ce cockpit), aucun amorçage posé" "$LRC $([ -s "$OUVERT" ] && echo ouvert || echo rien) $([ -e "$AM" ] && echo amorce || echo sans-amorce)" "5 rien sans-amorce"
rm -f "$SJ"
lance "$LAUNCH" open --terminal --no-open; S12="$(sj j.pid)"; Q12="$(qport)"
node -e "const fs=require('fs');const f=process.argv[1];const j=JSON.parse(fs.readFileSync(f,'utf8'));j.terminal={url:'file:///System/Applications/Calculator.app'};j.url='file:///System/Applications/Calculator.app';fs.writeFileSync(f,JSON.stringify(j))" "$SJ"
rm -f "$OUVERT" "$WORK/run/page-ouverte.html"; lance "$LAUNCH" open --terminal; fichier_ouvert; sleep 0.5; S12B="$(sj j.pid)"; Q12B="$(qport)"
assert_eq "L12b — serveur à nous, terminal.url remplacé par file:///… : ni l'argv ni la page ne portent file:, la page mène à http://127.0.0.1:<P réel>/project.html" "$(grep -c 'file:' "$OUVERT" 2>/dev/null || true) $(grep -c 'file:' "$WORK/run/page-ouverte.html" 2>/dev/null || true) $(grep -c -E "url=http://127\.0\.0\.1:$(sj j.port)/project\.html\?o=[0-9a-f]{64}#t=" "$WORK/run/page-ouverte.html" 2>/dev/null || true)" "0 0 1"
for v in 'http://127.0.0.1:80@evil.example' 'http://127.0.0.1:99999' 'http://127.0.0.1:1235/x' 'http://evil.example:1235' 'http://127.0.0.1:0x10'; do
  node -e "const fs=require('fs');const f=process.argv[1];const j=JSON.parse(fs.readFileSync(f,'utf8'));j.terminal={url:process.argv[2]};fs.writeFileSync(f,JSON.stringify(j))" "$SJ" "$v"
  rm -f "$OUVERT" "$WORK/run/page-ouverte.html"; lance "$LAUNCH" open --terminal; fichier_ouvert; sleep 0.3; P12C="$(sj j.port)"
  assert_eq "L12c — terminal.url « $v » : l'ouvreur ne reçoit que la page, qui mène à http://127.0.0.1:<P réel>/project.html" "$(grep -c -F "$v" "$OUVERT" "$WORK/run/page-ouverte.html" 2>/dev/null | tr '\n' ' ') $(grep -c -E "url=http://127\.0\.0\.1:$P12C/project\.html\?o=[0-9a-f]{64}#t=" "$WORK/run/page-ouverte.html" 2>/dev/null || true)" "$OUVERT:0 $WORK/run/page-ouverte.html:0  1"
done
arrete; [ -n "$(sj j.pid)" ] && attendre_mort "$(sj j.pid)"

echo "=== L13 — F6 : page de redirection (0600, aucun lien suivi), supprimée à l'échange, balayée à 60 s ; amorçage expiré à 60 s (P71-D-27) ==="
rm -f "$OUVERT" "$WORK/run/page-ouverte.html" "$AM" "$SJ"; lance "$LAUNCH" open --terminal; fichier_ouvert; sleep 0.5; S13="$(sj j.pid)"; Q13="$(qport)"
cp "$AM" "$WORK/amorce13.copy"
assert_eq "L13 — témoin : la page existe avant l'échange (fichier ordinaire, 600)" "$([ -f "$PAGE" ] && [ ! -L "$PAGE" ] && echo "ordinaire $(mode "$PAGE")" || echo absente)" "ordinaire 600"
assert_eq "L13 — l'échange de l'amorçage est accepté (200)" "$(node "$TA" amorcer "$Q13" "$WORK/amorce13.copy" | sed -n 1p)" "200"
disparu() { for _ in $(seq 1 "${2:-30}"); do [ -e "$1" ] || { echo oui; return; }; sleep 0.2; done; echo non; }
assert_eq "L13 — la page de redirection n'existe plus une fois l'amorçage échangé" "$(disparu "$PAGE" 15)" "oui"
rm -f "$OUVERT"; lance "$LAUNCH" open --terminal; fichier_ouvert
assert_eq "L13 — O2 c : même serveur, la page est posée de nouveau (témoin du balayage)" "$([ -f "$PAGE" ] && echo oui || echo non)" "oui"
vieillir "$PAGE" 30; sleep 5
assert_eq "L13 — balayage : une page de 30 s est conservée" "$([ -f "$PAGE" ] && echo oui || echo non)" "oui"
vieillir "$PAGE" 61
assert_eq "L13 — balayage : une page de plus de 60 s qui n'a jamais été lue est supprimée (délai borné, 8 s au plus)" "$(disparu "$PAGE" 40)" "oui"
cp "$AM" "$WORK/amorce13b.copy"; vieillir "$AM" 61
assert_eq "L13 — un amorçage vieux de 61 s est refusé à l'échange (403)" "$(node "$TA" amorcer "$Q13" "$WORK/amorce13b.copy" | sed -n 1p)" "403"
printf 'contenu-cible\n' > "$WORK/cible"; EMP="$(cksum < "$WORK/cible")"; rm -f "$PAGE"; ln -s "$WORK/cible" "$PAGE"
lance "$LAUNCH" open --terminal
# deux couches (comme L4) : la garde « aucun lien dans la sortie » refuse, ou la création exclusive pose un fichier ordinaire ; dans les deux cas la cible est intacte
assert_eq "L13 — page préplacée en lien symbolique : la cible est intacte, refus nommé ou page ordinaire en 600" "$([ "$(cksum < "$WORK/cible")" = "$EMP" ] && { { [ ! -L "$PAGE" ] && [ -f "$PAGE" ] && [ "$(mode "$PAGE")" = 600 ]; } || grep -q -e 'lien symbolique refusé' "$LOUT"; } && echo sur || echo non)" "sur"
rm -f "$PAGE"; arrete; [ -n "$S13" ] && attendre_mort "$S13"

echo "=== L14 — ouvreur absent : l'erreur asynchrone du spawn est rattrapée, la marche à suivre est dite (M6, N6b) ==="
mkdir -p "$WORK/sansouvreur"; for t in node ps git sh env python3 sed cat; do c="$(command -v "$t")"; [ -n "$c" ] && ln -sf "$c" "$WORK/sansouvreur/$t"; done
sans_ouvreur() { # sans_ouvreur <lanceur> [PATH] -> LRC, LOUT : PATH sans open ni xdg-open (ou, avec un PATH donné, un ouvreur présent mais qui ne se lance pas)
  NL=$((NL+1)); LOUT="$WORK/lance-$NL.out"; (cd "$LAB" && PATH="${2:-$WORK/sansouvreur}" node "$1" open --terminal --lab "$LAB" --port "$(libre)" > "$LOUT" 2>&1); LRC=$?
}
sans_ouvreur "$LAUNCH"; S14="$(sj j.pid)"
assert_eq "L14 — aucun ouvreur dans le PATH : le lanceur sort 0 sans trace, dit que l'ouvreur ne se lance pas (ENOENT) et nomme la page à ouvrir à la main" "$LRC trace=$(grep -c -e 'node:internal' -e '^ *at ' "$LOUT" || true) ENOENT=$(grep -c 'ENOENT' "$LOUT" || true) page=$(grep -c -F "$PAGE" "$LOUT" || true) dit=$(grep -c "le terminal ne s'est pas ouvert" "$LOUT" || true)" "0 trace=0 ENOENT=1 page=1 dit=1"
arrete; [ -n "$S14" ] && attendre_mort "$S14"
# ouvreur PRÉSENT mais qui ne se lance pas (interpréteur inexistant) : l'événement 'error' du spawn, rattrapé (le cas « absent » ne passe plus par un spawn depuis N2)
mkdir -p "$WORK/ouvreurcasse"; for o in open xdg-open; do printf '#!/nonexistent/interpreteur\n' > "$WORK/ouvreurcasse/$o"; chmod +x "$WORK/ouvreurcasse/$o"; done
sans_ouvreur "$LAUNCH" "$WORK/ouvreurcasse:$WORK/sansouvreur"; S14="$(sj j.pid)"
assert_eq "L14 — ouvreur présent qui ne se lance pas : le lanceur sort 0 sans trace, dit que l'ouvreur ne se lance pas et nomme la page à ouvrir à la main" "$LRC trace=$(grep -c -e 'node:internal' -e '^ *at ' "$LOUT" || true) dit=$(grep -c "le terminal ne s'est pas ouvert" "$LOUT" || true) page=$(grep -c -F "$PAGE" "$LOUT" || true)" "0 trace=0 dit=1 page=1"
arrete; [ -n "$S14" ] && attendre_mort "$S14"

echo "=== L15 — le navigateur ne charge pas la page : annoncé en clair, jamais un succès muet (M6, N6b) ==="
rm -f "$OUVERT" "$AM" "$SJ"; lance "$LAUNCH" open --terminal; S15="$(sj j.pid)"
assert_eq "L15 — ouvreur qui n'ouvre rien (l'amorçage n'est jamais consommé) : le lanceur sort 0 et le dit, avec la page à ouvrir à la main et la limite Linux (Firefox en snap)" "$LRC dit=$(grep -c "le terminal ne s'est pas ouvert" "$LOUT" || true) navigateur=$(grep -c "le navigateur n'a pas chargé la page" "$LOUT" || true) page=$(grep -c -F "$PAGE" "$LOUT" || true) snap=$(grep -c 'Firefox en snap' "$LOUT" || true)" "0 dit=1 navigateur=1 page=1 snap=1"
arrete; [ -n "$S15" ] && attendre_mort "$S15"
# ouvreur conforme : lit la page, suit sa redirection et échange l'amorçage comme le ferait un navigateur
mkdir -p "$WORK/bonbin"
for o in open xdg-open; do cat > "$WORK/bonbin/$o" <<SH
#!/bin/sh
u="\$(sed -n 's/.*url=\\(http[^"]*\\)".*/\\1/p' "\$1")"; q="\$(node -e "console.log(new URL(JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')).terminal.url).port)" "$SJ")"; a="\${u##*#t=}"
printf '%s' "\$a" > "$WORK/run/amorce-conforme"; node "$TA" amorcer "\$q" "$WORK/run/amorce-conforme" >> "$WORK/run/conforme.log" 2>&1
SH
chmod +x "$WORK/bonbin/$o"; done
rm -f "$AM" "$SJ" "$WORK/run/conforme.log"; NL=$((NL+1)); LOUT="$WORK/lance-$NL.out"; T0=$SECONDS
(cd "$LAB" && VF_COCKPIT_OUVERTURE_MS=20000 PATH="$WORK/bonbin:$PATH" node "$LAUNCH" open --terminal --lab "$LAB" --port "$(libre)" > "$LOUT" 2>&1); LRC=$?; S15B="$(sj j.pid)"
assert_eq "L15 — témoin : un ouvreur conforme qui échange l'amorçage : sortie 0 sans message d'échec, rendue bien avant la borne de 20 s (l'échange a réussi : 200 dans le journal de l'ouvreur)" "$LRC dit=$(grep -c "ne s'est pas ouvert" "$LOUT" || true) rapide=$([ $((SECONDS-T0)) -lt 12 ] && echo oui || echo non) echange=$(sed -n 1p "$WORK/run/conforme.log" 2>/dev/null)" "0 dit=0 rapide=oui echange=200"
arrete; [ -n "$S15B" ] && attendre_mort "$S15B"

echo "=== L16 — N2 (P71-D-29) : le lanceur n'exécute jamais un binaire du lab (open, xdg-open, ps, git) sous un PATH à élément relatif ou vide ==="
MARQ="$WORK/run/marq"; PBASE="$WORK/fauxbin:$PATH"
leurres_lab() { # pose dans le lab (racine et bin/) des open, xdg-open, ps, git qui ne font qu'écrire un marqueur
  local n d; mkdir -p "$LAB/bin"; for n in open xdg-open ps git bash; do for d in "$LAB" "$LAB/bin"; do printf '#!/bin/sh\necho "$0" >> "%s-%s"\nexit 1\n' "$MARQ" "$n" > "$d/$n"; chmod +x "$d/$n"; done; done
}
retire_leurres() { for n in open xdg-open ps git bash; do rm -f "$LAB/$n" "$LAB/bin/$n"; done; rmdir "$LAB/bin" 2>/dev/null; true; }
marqueurs() { local t="" n; for n in open xdg-open ps git bash; do t="$t $n=$(nbl "$MARQ-$n")"; done; echo "${t# }"; }
run_leurres() { # run_leurres <lanceur> <PATH> -> marqueurs ; premier lancement (assemble, ouvre), second (cockpit vivant : estNotre), arrêt (estNotre)
  rm -f "$MARQ"-* "$AM" "$SJ"; local l="$1" pv="$2" r
  for a in "open --terminal --rebuild" "open --terminal" "stop" "open" "stop"; do
    NL=$((NL+1)); LOUT="$WORK/lance-$NL.out"; (cd "$LAB" && PATH="$pv" node "$l" $a --lab "$LAB" --port "$(libre)" > "$LOUT" 2>&1); r=$?
  done
  S16="$(sj j.pid)"; [ -n "$S16" ] && { vf_hyg_stop "$S16"; }
  RES="$(marqueurs)"
}
leurres_lab
mkdir -p "$WORK/minbin"; for t in node sh env; do c="$(command -v "$t")"; [ -n "$c" ] && ln -sf "$c" "$WORK/minbin/$t"; done # sans ps, git ni bash : seul un repli sur le cwd les trouverait
for spec in "point|.:$PBASE" "vide-tete|:$PBASE" "relatif|bin:$PBASE" "vide-final-sans-binaire|$WORK/minbin:$WORK/fauxbin:"; do
  nv="${spec%%|*}"; v="${spec#*|}"
  run_leurres "$LAUNCH" "$v"
  assert_eq "L16 — PATH « $nv » : aucun open, xdg-open, ps ni git du lab n'est exécuté" "$RES" "open=0 xdg-open=0 ps=0 git=0 bash=0"
done
# témoin : le lanceur fonctionne bien sous ces PATH (l'ouvreur factice absolu est atteint, l'arrêt a eu lieu)
rm -f "$OUVERT" "$AM" "$SJ"; NL=$((NL+1)); LOUT="$WORK/lance-$NL.out"; (cd "$LAB" && PATH=".:$PBASE" node "$LAUNCH" open --terminal --lab "$LAB" --port "$(libre)" > "$LOUT" 2>&1); S16="$(sj j.pid)"; fichier_ouvert
assert_eq "L16 — témoin : sous PATH=.:…, l'ouvreur factice ABSOLU du PATH est lancé et le serveur répond" "ouvert=$([ -s "$OUVERT" ] && echo oui || echo non) pid=$([ -n "$S16" ] && echo oui || echo non)" "ouvert=oui pid=oui"
arrete; [ -n "$S16" ] && attendre_mort "$S16"
rm -f "$OUVERT" "$AM" "$SJ"; NL=$((NL+1)); LOUT="$WORK/lance-$NL.out"; (cd "$LAB" && PATH=".:$PBASE" node "$LAUNCH" open --lab "$LAB" --port "$(libre)" > "$LOUT" 2>&1); S16="$(sj j.pid)"; fichier_ouvert
assert_eq "L16 — témoin : « open » sans --terminal sous PATH=.:… : le LANCEUR remet l'adresse du cockpit à l'ouvreur absolu (le serveur ne lance plus d'ouvreur lui-même)" "$(grep -c '^http://127.0.0.1:[0-9]*$' "$OUVERT" 2>/dev/null || true)" "1"
arrete; [ -n "$S16" ] && attendre_mort "$S16"
retire_leurres

echo "=== L16b — N12 (P71-D-29, 2026-11-04) : un dossier ABSOLU du lab dans le PATH (<lab>/bin : npm run, direnv) n'est jamais exécuté non plus (open, xdg-open, ps, python3) ==="
# les ouvreurs factices restent atteints par chemin absolu dans TOUS les cas (jamais l'ouvreur réel du poste, même sous un PATH vidé par l'assainissement)
leurres_abs() { local n; mkdir -p "$LAB/bin"; for n in open xdg-open ps python3; do printf '#!/bin/sh\necho "$0" >> "%s-%s"\nexit 1\n' "$MARQ" "$n" > "$LAB/bin/$n"; chmod +x "$LAB/bin/$n"; done; }
retire_abs() { local n; for n in open xdg-open ps python3; do rm -f "$LAB/bin/$n"; done; rmdir "$LAB/bin" 2>/dev/null; true; }
marq_abs() { local t="" n; for n in open xdg-open ps python3; do t="$t $n=$(nbl "$MARQ-$n")"; done; echo "${t# }"; }
cycle_abs() { # cycle_abs <lanceur> <PATH> -> RES = marqueurs, OUV = nombre d'ouvertures par l'ouvreur factice absolu ; mêmes gestes que L16, plus l'arrêt
  rm -f "$MARQ"-* "$AM" "$SJ" "$OUVERT"; local l="$1" pv="$2" a
  for a in "open --terminal --rebuild" "open --terminal" "stop" "open" "stop"; do
    NL=$((NL+1)); LOUT="$WORK/lance-$NL.out"; (cd "$LAB" && PATH="$pv" node "$l" $a --lab "$LAB" --port "$(libre)" > "$LOUT" 2>&1)
  done
  S16="$(sj j.pid)"; [ -n "$S16" ] && { vf_hyg_stop "$S16"; }
  RES="$(marq_abs)"; OUV="$([ -s "$OUVERT" ] && echo oui || echo non)"
}
leurres_abs
for spec in "lab-bin-en-tete|$LAB/bin:$PBASE" "lab-bin-en-queue|$PBASE:$LAB/bin"; do
  nv="${spec%%|*}"; v="${spec#*|}"
  cycle_abs "$LAUNCH" "$v"
  assert_eq "L16b — PATH « $nv » : aucun open, xdg-open, ps ni python3 du lab n'est exécuté, et le cockpit s'ouvre quand même avec l'ouvreur absolu" "$RES ouvert=$OUV" "open=0 xdg-open=0 ps=0 python3=0 ouvert=oui"
done
# python3 : le lanceur ne fait que le résoudre, il ne l'exécute pas ; le seul python3 est celui du lab -> il est écarté (message, cockpit sans terminal), jamais pris pour bon
rm -f "$AM" "$SJ" "$OUVERT"; NL=$((NL+1)); LOUT="$WORK/lance-$NL.out"; (cd "$LAB" && PATH="$LAB/bin:$WORK/minbin:$WORK/fauxbin" node "$LAUNCH" open --terminal --lab "$LAB" --port "$(libre)" > "$LOUT" 2>&1); LRC=$?; S16="$(sj j.pid)"
assert_eq "L16b — le seul python3 est <lab>/bin/python3 : écarté (« python3 introuvable »), cockpit ouvert sans terminal, code 0" "rc=$LRC dit=$(grep -c 'python3 introuvable' "$LOUT" || true) ouvert=$([ -s "$OUVERT" ] && echo oui || echo non)" "rc=0 dit=1 ouvert=oui"
[ -n "$S16" ] && vf_hyg_stop "$S16"
# mutant M-PATH-BRUT : les trois lectures reviennent au PATH brut (et l'ouvreur à l'environnement hérité) -> L16b rougit
md="$WORK/mut-pathbrut"; rm -rf "$md"; mkdir -p "$md"; cp -R "$MODULE/." "$md/"; cp "$md/scripts/vf-cockpit.mjs" "$md/l.orig"
sed -i.bak "s/, pathSur())/)/g; s/, env: envEnfant(LABV) }/ }/" "$md/scripts/vf-cockpit.mjs"
if ! cmp -s "$md/scripts/vf-cockpit.mjs" "$md/l.orig"; then
  rm -f "$md/l.orig" "$md/scripts/vf-cockpit.mjs.bak"; MR=""
  for spec in "t|$LAB/bin:$PBASE" "q|$PBASE:$LAB/bin"; do cycle_abs "$md/scripts/vf-cockpit.mjs" "${spec#*|}"; MR="$MR ${spec%%|*}:$RES"; done
  assert_eq "M-PATH-BRUT — le mutant (PATH brut aux trois lectures) rougit L16b : un ouvreur ou un ps du lab est exécuté" "$([[ "$MR" == *"open=1"* && "$MR" == *"ps=1"* ]] && echo rouge || echo "identique :$MR")" "rouge"
else assert_eq "M-PATH-BRUT — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
retire_abs

echo "=== L17 — N8 (P71-D-29) : un PATH absent ou entièrement relatif n'est jamais transmis vide à l'assemblage (libuv le lit comme le cwd : le git du lab serait exécuté) ==="
NODE_ABS="$(command -v node)"
git_du_lab() { # git_du_lab <nom> <lanceur> <env|point> -> écrit « git=<n> rc=<n> » dans RES ; env = environnement vide (env -i), point = PATH=.
  rm -f "$MARQ"-*; NL=$((NL+1)); LOUT="$WORK/lance-$NL.out"; rm -rf "$OUT"
  if [ "$3" = env ]; then (cd "$LAB" && env -i "$NODE_ABS" "$2" build --lab "$LAB" > "$LOUT" 2>&1); else (cd "$LAB" && env PATH=. "$NODE_ABS" "$2" build --lab "$LAB" > "$LOUT" 2>&1); fi
  LRC=$?; RES="git=$(nbl "$MARQ-git") rc=$LRC"
}
leurres_lab
for cas in env point; do
  git_du_lab "$cas" "$LAUNCH" "$cas"
  assert_eq "L17 — build sous « $cas » (PATH absent ou « . ») avec un git piégé dans le lab : jamais exécuté, build réussi" "$RES" "git=0 rc=0"
done
retire_leurres
# mutant M-PATH-VIDE : le PATH assaini vide est transmis tel quel (ni repli système ni clé omise : le code d'avant) -> le git du lab est exécuté, sous les deux formes
md="$WORK/mut-pathvide"; rm -rf "$md"; mkdir -p "$md"; cp -R "$MODULE/." "$md/"; cp "$md/scripts/vf-cockpit-env.mjs" "$md/env.orig"
sed -i.bak "s/return gardes.length ? gardes.join(path.delimiter) : PATH_REPLI;/return gardes.join(path.delimiter);/" "$md/scripts/vf-cockpit-env.mjs"
if ! cmp -s "$md/scripts/vf-cockpit-env.mjs" "$md/env.orig"; then
  rm -f "$md/env.orig" "$md/scripts/vf-cockpit-env.mjs.bak"; leurres_lab; MR=""
  for cas in env point; do git_du_lab "$cas" "$md/scripts/vf-cockpit.mjs" "$cas"; MR="$MR $cas:${RES%% *}"; done; retire_leurres
  assert_eq "M-PATH-VIDE — le mutant (PATH assaini vide transmis) rougit L17 : le git du lab est exécuté sous env -i comme sous PATH=." "$([[ "$MR" == *"env:git=0"* || "$MR" == *"point:git=0"* ]] && echo "identique :$MR" || echo rouge)" "rouge"
else assert_eq "M-PATH-VIDE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

echo "=== L18 — sans ps dans le PATH : « arrêt refusé » est dit UNE fois, pas à chaque tour de l'attente du terminal (une centaine) ==="
mkdir -p "$WORK/pybin"; c="$(command -v python3)"; [ -n "$c" ] && ln -sf "$c" "$WORK/pybin/python3" # E4 : L18 veut un terminal ouvrable en principe, donc python3 résoluble (mais pas ps)
sans_ps() { # sans_ps <lanceur> -> LRC, LOUT, S18 ; PATH = node, sh, env seulement (WORK/minbin, sans ps)
  rm -f "$AM" "$SJ"; NL=$((NL+1)); LOUT="$WORK/lance-$NL.out"; (cd "$LAB" && PATH="$WORK/minbin:$WORK/pybin" node "$1" open --terminal --no-open --lab "$LAB" --port "$(libre)" > "$LOUT" 2>&1); LRC=$?
  S18="$(sj j.pid)"; [ -n "$S18" ] && vf_hyg_stop "$S18"; true
}
sans_ps "$LAUNCH"
assert_eq "L18 — sans ps, la raison du refus est dite exactement une fois (témoin : le terminal, lui, n'est pas ouvrable sans ps : message « le terminal n'a pas démarré »)" "refus=$(grep -c 'arrêt refusé' "$LOUT" || true) terminal=$(grep -c "le terminal n'a pas démarré" "$LOUT" || true)" "refus=1 terminal=1"
md="$WORK/mut-psrepete"; rm -rf "$md"; mkdir -p "$md"; cp -R "$MODULE/." "$md/"; cp "$md/scripts/vf-cockpit.mjs" "$md/vf.orig"
sed -i.bak 's/if (!psDit) {/if (true) {/' "$md/scripts/vf-cockpit.mjs"
if ! cmp -s "$md/scripts/vf-cockpit.mjs" "$md/vf.orig"; then
  rm -f "$md/vf.orig" "$md/scripts/vf-cockpit.mjs.bak"; sans_ps "$md/scripts/vf-cockpit.mjs"
  assert_eq "M-PS-REPETE — le mutant (le refus est redit à chaque appel) rougit L18 : plus d'une occurrence" "$([ "$(grep -c 'arrêt refusé' "$LOUT" || true)" -gt 1 ] && echo rouge || echo identique)" "rouge"
else assert_eq "M-PS-REPETE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

echo "=== L19 — E4 : --terminal sans python3 résoluble : message clair, aucun amorçage, aucune ouverture de Q, le cockpit s'ouvre sans terminal (sortie 0) ==="
sans_py() { # sans_py <lanceur> -> LRC, LOUT, S19 ; PATH = node, sh, env + ouvreurs factices, jamais python3
  rm -f "$AM" "$SJ" "$OUVERT" "$WORK/run/page-ouverte.html"; NL=$((NL+1)); LOUT="$WORK/lance-$NL.out"
  (cd "$LAB" && PATH="$WORK/minbin:$WORK/fauxbin" node "$1" open --terminal --lab "$LAB" --port "$(libre)" > "$LOUT" 2>&1); LRC=$?
  S19="$(sj j.pid)"; [ -n "$S19" ] && { PY19="$(sj '(j.terminal&&j.terminal.url)||"aucun"')"; vf_hyg_stop "$S19"; } ; true
}
PY_OK=sans; for d in $(echo "$WORK/minbin" | tr ':' ' '); do [ -e "$d/python3" ] && PY_OK=present; done
sans_py "$LAUNCH"
assert_eq "L19 — témoin : minbin ne porte pas python3" "$PY_OK" "sans"
assert_eq "L19 — sortie 0, message « Terminal indisponible : python3 introuvable » une fois avec la marche à suivre, jamais « n'a pas démarré »" "$LRC dit=$(grep -c 'Terminal indisponible : python3 introuvable' "$LOUT" || true) marche=$(grep -c 'brew install python' "$LOUT" || true) echec=$(grep -c "n'a pas démarré" "$LOUT" || true)" "0 dit=1 marche=1 echec=0"
assert_eq "L19 — aucun amorçage posé, aucune page de Q ouverte, serveur démarré SANS terminal, le cockpit lui-même est ouvert" "amorce=$([ -e "$AM" ] && echo oui || echo non) page=$([ -e "$WORK/run/page-ouverte.html" ] && echo oui || echo non) q=${PY19:-?} ouvert=$(grep -c '^http://127.0.0.1:' "$OUVERT" 2>/dev/null || true)" "amorce=non page=non q=aucun ouvert=1"
if mutant sanspy 's/if (o.terminal \&\& !win \&\& !resoudreBinaire(.python3., pathSur())) {/if (false) {/'; then
  sans_py "$MUT_L"
  assert_eq "M-SANS-PYTHON3 — le mutant (aucune vérification) rougit L19 : le message n'est plus dit" "$([ "$(grep -c 'Terminal indisponible : python3 introuvable' "$LOUT" || true)" = 0 ] && echo rouge || echo identique)" "rouge"
else assert_eq "M-SANS-PYTHON3 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

echo "=== L19b — R4 (P71-D-36) : serveur DÉJÀ vivant + --terminal sans python3 : le message promet « le cockpit s'ouvre sans terminal », donc il s'ouvre (jamais une promesse sans ouverture) ==="
relance_sans_py() { # relance_sans_py <lanceur> [--no-open] -> LRC, LOUT ; le serveur vivant est conservé, PATH sans python3
  rm -f "$OUVERT" "$WORK/run/page-ouverte.html"; NL=$((NL+1)); LOUT="$WORK/lance-$NL.out"
  mkdir -p "$WORK/psbin"; ln -sf "$(command -v ps)" "$WORK/psbin/ps" # N13 : estNotre exige ps, qui existe sur le poste réel (seul python3 manque)
  (cd "$LAB" && PATH="$WORK/minbin:$WORK/psbin:$WORK/fauxbin" node "$1" open --terminal "${@:2}" --lab "$LAB" --port "$(libre)" > "$LOUT" 2>&1); LRC=$?
  [ -s "$OUVERT" ] || sleep 0.5
}
for variante in sans-terminal avec-terminal; do
  rm -f "$AM" "$SJ" "$OUVERT"
  if [ "$variante" = sans-terminal ]; then lance "$LAUNCH" open --no-open; else lance "$LAUNCH" open --terminal --no-open; fi
  S19B="$(sj j.pid)"; P19B="http://127.0.0.1:$(sj j.port)"
  relance_sans_py "$LAUNCH"
  assert_eq "L19b ($variante) — témoin : le serveur est le même (réutilisé), python3 absent du PATH de la relance" "$([ -n "$S19B" ] && [ "$(sj j.pid)" = "$S19B" ] && echo meme || echo "autre : $(sj j.pid)")" "meme"
  assert_eq "L19b ($variante) — sortie 0, message python3 dit une fois, le cockpit EXISTANT est ouvert une fois (adresse de P), aucune page de Q" "$LRC dit=$(grep -c 'Terminal indisponible : python3 introuvable' "$LOUT" || true) ouvert=$(cat "$OUVERT" 2>/dev/null | grep -c -F -e "$P19B" || true) page=$([ -e "$WORK/run/page-ouverte.html" ] && echo oui || echo non)" "0 dit=1 ouvert=1 page=non"
  relance_sans_py "$LAUNCH" --no-open
  assert_eq "L19b ($variante) — avec --no-open : rien n'est ouvert" "$LRC ouvert=$([ -s "$OUVERT" ] && echo oui || echo non)" "0 ouvert=non"
  vf_hyg_stop "$S19B"; rm -f "$SJ"
done
if mutant rquatre 's/if (demande .*) ouvrir(vif.url/if (false) ouvrir(vif.url/'; then
  lance "$LAUNCH" open --no-open; S19B="$(sj j.pid)"; P19B="http://127.0.0.1:$(sj j.port)"; relance_sans_py "$MUT_L"
  assert_eq "M-R4-SANS-OUVERTURE — le mutant (plus d'ouverture) rougit L19b : l'adresse de P n'est plus ouverte" "$([ "$(cat "$OUVERT" 2>/dev/null | grep -c -F -e "$P19B" || true)" = 0 ] && echo rouge || echo identique)" "rouge"
  vf_hyg_stop "$S19B"; rm -f "$SJ"
else assert_eq "M-R4-SANS-OUVERTURE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

echo "=== L19c — N13 (P71-D-25) : un server.json planté (PID étranger vivant, port 1235) n'est jamais ouvert quand --terminal est écarté : l'adresse n'est remise à l'ouvreur que si le processus est le serveur de CETTE sortie (estNotre) ==="
plante_etranger() { rm -f "$SJ" "$OUVERT"; mkdir -p "$(dirname "$SJ")"; /bin/sleep 300 & ETR=$!; printf '{"pid":%s,"port":1235,"url":"http://127.0.0.1:1235","token":"x"}' "$ETR" > "$SJ"; }
plante_etranger; relance_sans_py "$LAUNCH"
assert_eq "L19c — témoin : le PID étranger est vivant et le server.json est celui qu'on a planté" "$(kill -0 "$ETR" 2>/dev/null && echo vivant || echo mort) $(sj j.port)" "vivant 1235"
assert_eq "L19c — sortie 0, adresse imprimée, mais AUCUNE ouverture d'une adresse décrite par un processus étranger" "$LRC ouvert=$([ -s "$OUVERT" ] && echo oui || echo non)" "0 ouvert=non"
kill "$ETR" 2>/dev/null; rm -f "$SJ"
if mutant sansestnotre "s/&& !o.noOpen && estNotre(vif.pid, path.join(sortie, 'serve.mjs'))) ouvrir(vif.url/\&\& !o.noOpen) ouvrir(vif.url/"; then
  plante_etranger; relance_sans_py "$MUT_L"
  assert_eq "M-N13-SANS-ESTNOTRE — le mutant (sans vérification du processus) rougit L19c : l'adresse étrangère est ouverte" "$([ -s "$OUVERT" ] && echo rouge || echo identique)" "rouge"
  kill "$ETR" 2>/dev/null; rm -f "$SJ"
else assert_eq "M-N13-SANS-ESTNOTRE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

echo "=== L20 — E5 : un serveur qui écrit son état après 15 s (machine chargée) : le lanceur attend, dit « démarrage lent » une fois, sort 0 ; la borne existe encore ==="
# serveur factice (copie du module, jamais le module) : écrit server.json après FAKE_SRV_MS, son PID est consigné dès le départ
mkdir -p "$WORK/mut-lent"; rm -rf "$WORK/mut-lent"; mkdir -p "$WORK/mut-lent"; cp -R "$MODULE/." "$WORK/mut-lent/"
cat > "$WORK/mut-lent/skills/cockpit-moteur/assets/serve.mjs" <<'JS'
import fs from 'node:fs'; import path from 'node:path'; import { fileURLToPath } from 'node:url';
const sortie = path.dirname(fileURLToPath(import.meta.url)); const a = process.argv; const port = Number(a[a.indexOf('--port') + 1]);
fs.writeFileSync(process.env.FAKE_SRV_PID, String(process.pid));
setTimeout(() => { fs.mkdirSync(path.join(sortie, '.cache'), { recursive: true });
  fs.writeFileSync(path.join(sortie, '.cache', 'server.json'), JSON.stringify({ pid: process.pid, port, url: `http://127.0.0.1:${port}`, token: 'x', startedAt: new Date().toISOString() })); }, Number(process.env.FAKE_SRV_MS));
process.on('SIGTERM', () => process.exit(0)); setInterval(() => {}, 1000);
JS
lent() { # lent <lanceur> <delai factice ms> [VF_COCKPIT_DEMARRAGE_MS] -> LRC, LOUT, DUREE
  rm -f "$SJ" "$WORK/run/fake.pid"; NL=$((NL+1)); LOUT="$WORK/lance-$NL.out"; local t0=$SECONDS
  (cd "$LAB" && FAKE_SRV_PID="$WORK/run/fake.pid" FAKE_SRV_MS="$2" env ${3:+VF_COCKPIT_DEMARRAGE_MS=$3} PATH="$WORK/fauxbin:$PATH" node "$1" open --no-open --lab "$LAB" --port "$(libre)" > "$LOUT" 2>&1); LRC=$?; DUREE=$((SECONDS-t0))
  [ -s "$WORK/run/fake.pid" ] && vf_hyg_stop "$(cat "$WORK/run/fake.pid")"; true
}
lent "$WORK/mut-lent/scripts/vf-cockpit.mjs" 15000
assert_eq "L20 — serveur qui écrit son état après 15 s : sortie 0 (rc=5 « n'a pas démarré » à 10 s avant E5), « démarrage lent » dit exactement une fois" "$LRC lent=$(grep -c 'démarrage lent' "$LOUT" || true) echec=$(grep -c "n'a pas démarré" "$LOUT" || true) attente=$([ "$DUREE" -ge 14 ] && echo ok || echo courte)" "0 lent=1 echec=0 attente=ok"
lent "$WORK/mut-lent/scripts/vf-cockpit.mjs" 8000 2000
assert_eq "L20 — la borne existe : serveur plus lent que VF_COCKPIT_DEMARRAGE_MS (2 s) : sortie 5 « n'a pas démarré », sans trace" "$LRC echec=$(grep -c "n'a pas démarré" "$LOUT" || true) trace=$(grep -c ' at ' "$LOUT" || true)" "5 echec=1 trace=0"
if mutant borne10 's/^const DEMARRAGE_MS = (() => {.*$/const DEMARRAGE_MS = 10000;/'; then
  cp -R "$WORK/mut-borne10/scripts/." "$WORK/mut-lent/scripts/"; lent "$WORK/mut-lent/scripts/vf-cockpit.mjs" 15000
  assert_eq "M-BORNE-10 — le mutant (borne ramenée à 10 s) rougit L20 : sortie 5 sur le serveur à 15 s" "$([ "$LRC" = 5 ] && echo rouge || echo "identique : $LRC")" "rouge"
else assert_eq "M-BORNE-10 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

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
if mutant imprime 's|^function ouvrirQ(s, amorce, o, sortie) {|& console.log(amorce);|'; then
  rm -f "$AM"; lance "$MUT_L" open --terminal --no-open; MS="$(sj j.pid)"; V="$(cat "$AM" 2>/dev/null)"
  assert_eq "M-IMPRIME — le mutant rougit L5 (valeur dans la sortie du lanceur)" "$([ -n "$V" ] && [ "$(cherche "$LOUT")" != 0 ] && echo rouge || echo "identique")" "rouge"
  arrete; [ -n "$MS" ] && attendre_mort "$MS"
else assert_eq "M-IMPRIME — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant ouvrep 's|s\.url}/project\.html?o=\${secret}#t=|s.terminal.url}/#t=|'; then
  rm -f "$OUVERT" "$WORK/run/page-ouverte.html" "$AM"; lance "$MUT_L" open --terminal; fichier_ouvert; sleep 0.5; MS="$(sj j.pid)"; MQ="$(qport)"
  assert_eq "M-OUVRE-Q — le mutant (SAF-1 défait : le lanceur vise de nouveau Q) rougit L6 : la page de redirection mène à Q, plus à la page Projet" "$(grep -q -F "url=http://127.0.0.1:$MQ/#t=" "$WORK/run/page-ouverte.html" 2>/dev/null && echo rouge || echo "identique")" "rouge"
  arrete; [ -n "$MS" ] && attendre_mort "$MS"
else assert_eq "M-OUVRE-Q — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

echo "=== M-ARGV / M-PAGE-MODE / M-PAGE-LIEN / M-F1-PID / M-F1-VALID — mutants de F1 et F6 ==="
if mutant argv 's|^  ouvrir(page, |  ouvrir(`${s.terminal.url}/#t=${amorce}`, |'; then
  rm -f "$OUVERT" "$AM" "$SJ"; lance "$MUT_L" open --terminal; fichier_ouvert; sleep 0.5; MS="$(sj j.pid)"; V="$(cat "$AM" 2>/dev/null)"
  assert_eq "M-ARGV — le mutant (l'adresse avec l'amorçage dans l'argv) rougit L6 : la valeur est lisible dans l'argv de l'ouvreur" "$([ -n "$V" ] && grep -q -F -e "$V" "$OUVERT" && echo rouge || echo identique)" "rouge"
  arrete; [ -n "$MS" ] && attendre_mort "$MS"
else assert_eq "M-ARGV — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant pagemode 's/MODE_PAGE = 0o600/MODE_PAGE = 0o666/'; then
  rm -f "$OUVERT" "$AM" "$SJ" "$PAGE"; ( umask 022; lance "$MUT_L" open --terminal ); fichier_ouvert; MS="$(sj j.pid)"; MM="$(mode "$PAGE")"
  assert_eq "M-PAGE-MODE — le mutant rougit L13 : la page n'est plus en 600" "$([ "$MM" != 600 ] && echo rouge || echo "identique : $MM")" "rouge"
  arrete; [ -n "$MS" ] && attendre_mort "$MS"; rm -f "$PAGE"
else assert_eq "M-PAGE-MODE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant pagelien -e "/^function ecrirePageOuvrir/,/^}/{s/fs\.unlinkSync(f)/0/;s/'wx'/'w'/;}" -e "s/verifierSortie(lab, sortie); return/return/"; then
  rm -f "$OUVERT" "$AM" "$SJ"; lance "$LAUNCH" open --terminal --no-open; MS="$(sj j.pid)"
  printf 'contenu-cible\n' > "$WORK/cible"; EMP="$(cksum < "$WORK/cible")"; rm -f "$PAGE"; ln -s "$WORK/cible" "$PAGE"
  lance "$MUT_L" open --terminal
  assert_eq "M-PAGE-LIEN — le mutant (sans suppression préalable ni création exclusive) rougit L13 : la cible est écrasée" "$([ "$(cksum < "$WORK/cible")" != "$EMP" ] && echo rouge || echo identique)" "rouge"
  rm -f "$PAGE" "$AM"; arrete; [ -n "$MS" ] && attendre_mort "$MS"
else assert_eq "M-PAGE-LIEN — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant f1pid "s/&& estNotre(s\.pid, path\.join(sortie, 'serve\.mjs'))/\&\& true/"; then
  planter "$PLANT_HTTP"; rm -f "$OUVERT" "$AM"; lance "$MUT_L" open --terminal; sleep 1; MS="$(sj j.pid)"
  assert_eq "M-F1-PID — le mutant (processus non vérifié) rougit L12a : l'ouvreur reçoit une adresse tirée d'un lab dont le PID n'est pas le nôtre" "$([ -s "$OUVERT" ] && echo rouge || echo identique)" "rouge"
  rm -f "$SJ" "$AM" "$PAGE"
else assert_eq "M-F1-PID — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant f1valid -e 's/^const portDeUrl = .*$/const portDeUrl = (u) => (typeof u === "string" ? 1 : null);/' -e 's/terminal: { url: adresseLocale(pq) }/terminal: { url: s.terminal.url }/' -e 's/url: adresseLocale(port), \.\.\./url: s.url, .../'; then
  rm -f "$SJ" "$AM"; lance "$LAUNCH" open --terminal --no-open; MS="$(sj j.pid)"
  node -e "const fs=require('fs');const f=process.argv[1];const j=JSON.parse(fs.readFileSync(f,'utf8'));j.terminal={url:'file:///System/Applications/Calculator.app'};j.url='file:///System/Applications/Calculator.app';fs.writeFileSync(f,JSON.stringify(j))" "$SJ"
  rm -f "$OUVERT" "$WORK/run/page-ouverte.html"; lance "$MUT_L" open --terminal; fichier_ouvert; sleep 0.5; MS2="$(sj j.pid)"
  assert_eq "M-F1-VALID — le mutant (sans validation ni reconstruction du port) rougit L12b : la page mène à file:///…" "$(grep -q 'file:' "$WORK/run/page-ouverte.html" 2>/dev/null && echo rouge || echo identique)" "rouge"
  rm -f "$AM" "$PAGE"; arrete; { [ -n "$MS" ] && attendre_mort "$MS"; [ -n "$MS2" ] && attendre_mort "$MS2"; } 2>/dev/null; true
else assert_eq "M-F1-VALID — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

echo "=== M-OUVREUR-ERREUR / M-SANS-ANNONCE / M-TOUJOURS-ANNONCE / M-SANS-RATTRAPAGE — mutants de M6 et N6a ==="
if mutant ouvreurerreur "s/    enfant.on('error', dire);//"; then
  sans_ouvreur "$MUT_L" "$WORK/ouvreurcasse:$WORK/sansouvreur"; MS="$(sj j.pid)"
  assert_eq "M-OUVREUR-ERREUR — le mutant (aucun écouteur sur l'erreur du spawn) rougit L14 : le lanceur tombe avec la trace de l'exception" "$([ "$LRC" != 0 ] && [ "$(grep -c -e 'node:internal' -e '^ *at ' "$LOUT" || true)" != 0 ] && echo rouge || echo "identique : rc=$LRC")" "rouge"
  arrete; [ -n "$MS" ] && attendre_mort "$MS"
else assert_eq "M-OUVREUR-ERREUR — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant sansannonce "s/^  console.error(\`le terminal ne s'est pas ouvert/  void (\`le terminal ne s'est pas ouvert/"; then
  rm -f "$OUVERT" "$AM" "$SJ"; lance "$MUT_L" open --terminal; MS="$(sj j.pid)"
  assert_eq "M-SANS-ANNONCE — le mutant (l'échec d'ouverture n'est plus dit) rougit L15 : succès muet" "$([ "$(grep -c "ne s'est pas ouvert" "$LOUT" || true)" = 0 ] && echo rouge || echo identique)" "rouge"
  arrete; [ -n "$MS" ] && attendre_mort "$MS"
else assert_eq "M-SANS-ANNONCE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant toujoursannonce 's/  if (!suivi.echec \&\& !fs.existsSync(amorce)) return;//'; then
  rm -f "$AM" "$SJ" "$WORK/run/conforme.log"; NL=$((NL+1)); LOUT="$WORK/lance-$NL.out"
  (cd "$LAB" && VF_COCKPIT_OUVERTURE_MS=20000 PATH="$WORK/bonbin:$PATH" node "$MUT_L" open --terminal --lab "$LAB" --port "$(libre)" > "$LOUT" 2>&1); MS="$(sj j.pid)"
  assert_eq "M-TOUJOURS-ANNONCE — le mutant (annonce même quand l'amorçage a été consommé) rougit le témoin de L15" "$([ "$(grep -c "ne s'est pas ouvert" "$LOUT" || true)" != 0 ] && echo rouge || echo identique)" "rouge"
  arrete; [ -n "$MS" ] && attendre_mort "$MS"
else assert_eq "M-TOUJOURS-ANNONCE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant sansrattrapage 's/^main().catch(.*$/main();/'; then
  lance "$LAUNCH" open --terminal --no-open; MS="$(sj j.pid)"; rm -f "$AM"; ln -s "$WORK/cible" "$AM"
  lance "$MUT_L" open --terminal --no-open
  assert_eq "M-SANS-RATTRAPAGE — le mutant (aucun rattrapage final) rougit L4 : l'exception du lien planté sort avec le code 1 et une trace" "$LRC trace=$([ "$(grep -c -e 'node:internal' -e '^ *at ' "$LOUT" || true)" != 0 ] && echo oui || echo non)" "1 trace=oui"
  rm -f "$AM"; arrete; [ -n "$MS" ] && attendre_mort "$MS"
else assert_eq "M-SANS-RATTRAPAGE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

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

echo "=== L21 — P71-D-03 : le shell du terminal reçoit le PATH d'origine du lanceur (relatif compris) ; le serveur et ses enfants gardent le PATH assaini (H-1) ==="
PABS21="$WORK/pabs21"; mkdir -p "$PABS21"; PO21="$PABS21:.:/usr/bin:/bin"
shell_path() { # shell_path <lanceur> <PATH du lanceur> -> R21 = PATH vu par le shell (ou « absent ») ; S21 = PID du serveur (à arrêter)
  rm -f "$AM" "$SJ"; NL=$((NL+1)); LOUT="$WORK/lance-$NL.out"; S21=""
  (cd "$LAB" && PATH="$2" "$NODE_ABS" "$1" open --terminal --no-open --lab "$LAB" --port "$(libre)" > "$LOUT" 2>&1)
  S21="$(sj j.pid)"; local q sec f="$WORK/run/flux21-$NL.bin" fp v; R21=""
  q="$(qport)"; [ -n "$q" ] || { R21=absent; return; }
  sec="$(node "$TA" amorcer "$q" "$AM" | sed -n 2p)"; [ -n "$sec" ] || { R21=absent; return; }
  node "$TA" flux "$q" "$sec" "$(printf 'a%.0s' $(seq 1 32))" "$f" 15000 > /dev/null 2>&1 & fp=$!
  for _ in $(seq 1 80); do [ -s "$f" ] && break; sleep 0.1; done; sleep 1
  node "$TA" entree "$q" "$sec" "$(printf 'a%.0s' $(seq 1 32))" "echo MQ''X=\$PATH=ZQ''X\\r" > /dev/null
  node "$TA" attendre "$f" "=ZQX" 8000 > /dev/null; kill "$fp" 2>/dev/null; wait "$fp" 2>/dev/null
  v="$(LC_ALL=C tr -d '\r' < "$f" | grep -a -o 'MQX=.*=ZQX' | tail -1)"; v="${v#MQX=}"; R21="${v%=ZQX}"
}
shell_path "$LAUNCH" "$PO21"; SP21="$S21"
assert_eq "L21 — sous PATH=<dossier absolu>:.:/usr/bin:/bin, « echo \$PATH » dans le shell rend exactement le PATH d'origine du lanceur, « . » compris" "$R21" "$PO21"
# le serveur, lui, garde le PATH assaini de H-1 (sans « . ») ; environnement illisible (ni /proc ni ps -Eww) : sauté, dit
E21="$(env_du_serveur "$SP21" | tr '\0' '\n' | tr ' ' '\n' | sed -n 's/^PATH=//p' | head -1)"
if [ -n "$E21" ]; then assert_eq "L21 — le serveur et ses enfants gardent le PATH assaini : aucun élément « . » ni vide, le dossier absolu d'origine gardé" "$([[ ":$E21:" != *":.:"* && ":$E21:" != *"::"* && ":$E21:" == *":$PABS21:"* ]] && echo oui || echo "non : $E21")" "oui"; else echo "  (L21 : environnement du serveur illisible, contrôle du PATH assaini sauté)"; fi
[ -n "$SP21" ] && vf_hyg_stop "$SP21"

echo "=== L22 — l'environnement du processus du terminal est celui de H-1 (envEnfant) : un élément absolu du PATH qui est un lien vers le lab est écarté ==="
LNK22="$WORK/lien22"; ln -s "$LAB/src" "$LNK22"
R22="$(cd "$LAB" && PATH="$LNK22:/usr/bin:/bin" "$NODE_ABS" --input-type=module -e "import { envDuProcessusTerminal } from 'file://$SCRIPTS/vf-cockpit-terminal.mjs'; console.log(envDuProcessusTerminal(process.argv[1]).PATH)" "$LAB" 2>&1)"
assert_eq "L22 — envDuProcessusTerminal écarte un élément absolu du PATH qui résout dans le lab (lien symbolique), comme envEnfant (H-1)" "$R22" "/usr/bin:/bin"

echo "=== M-OUVRE-NOMNU / M-PS-NOMNU / M-GIT-NOMNU / M-WHO-NOMNU / M-SERVE-OUVRE / M-PS-FINAL — mutants de N2 : résolution par nom nu ==="
# nom|fichier|sed|marqueur attendu|PATH ('.' = « .: » en tête ; 'min' = PATH sans binaire du système, élément vide final)
# '@ouvreur' = l'ouvreur de la plateforme, choisi comme le code (vf-cockpit.mjs ouvrir, serve.mjs) : open sous darwin, xdg-open ailleurs (win32 exclu : pas de terminal)
OUVREUR_PF="$([ "$("$NODE_ABS" -p process.platform)" = darwin ] && echo open || echo xdg-open)"
for spec in "ouvrenomnu|vf-cockpit.mjs|s/spawn(exe, op\[1\]/spawn(op[0], op[1]/;s/, env: envEnfant(LABV) })/ })/|@ouvreur|." "psnomnu|vf-cockpit.mjs|s/execFileSync(ps, /execFileSync('ps', /;s/, env: envEnfant(lab) })/ })/|ps|." "gitnomnu|vf-cockpit-paths.mjs|s/timeout: Math.floor(reste), env, maxBuffer })/timeout: Math.floor(reste), maxBuffer })/|git|." "whonomnu|vf-cockpit-paths.mjs|s/timeout: Math.floor(reste), env, maxBuffer })/timeout: Math.floor(reste), maxBuffer })/|git|." "servopen|vf-cockpit.mjs|s/^  args.push('--no-open');.*$/  if (o.avecQ) args.push('--no-open'); else if (o.noOpen) args.push('--no-open');/;s/{ \.\.\.envEnfant(lab), VF_COCKPIT_ENGINE_DIR/{ ...process.env, VF_COCKPIT_ENGINE_DIR/|@ouvreur|." "psfinal|vf-cockpit.mjs|s/const ps = resoudreBinaire('ps', pathSur());/const ps = 'ps';/;s/, env: envEnfant(lab) })/ })/|ps|min"; do
  IFS='|' read -r mn mf msed mk mp <<< "$spec"
  [ "$mk" = "@ouvreur" ] && mk="$OUVREUR_PF"
  md="$WORK/mut-$mn"; rm -rf "$md"; mkdir -p "$md"; cp -R "$MODULE/." "$md/"; cp "$md/scripts/$mf" "$md/scripts/$mf.orig"; sed -i.bak "$msed" "$md/scripts/$mf"
  if [ "$mn" = whonomnu ]; then sed -i.bak 's/{ \.\.\.envEnfant(lab), VF_COCKPIT_ENGINE_DIR/{ ...process.env, VF_COCKPIT_ENGINE_DIR/' "$md/scripts/vf-cockpit.mjs"; rm -f "$md/scripts/vf-cockpit.mjs.bak"; fi
  if [ "$mn" = servopen ] || [ "$mn" = whonomnu ]; then sed -i.bak 's/process\.env\.PATH = (await import(.*assainirPath(process\.env\.PATH, root);//' "$md/skills/cockpit-moteur/assets/serve.mjs"; rm -f "$md/skills/cockpit-moteur/assets/serve.mjs.bak"; fi
  if ! cmp -s "$md/scripts/$mf" "$md/scripts/$mf.orig"; then
    rm -f "$md/scripts/$mf.orig" "$md/scripts/$mf.bak"; leurres_lab
    if [ "$mp" = min ]; then pm="$WORK/minbin:$WORK/fauxbin:"; else pm=".:$PBASE"; fi
    run_leurres "$md/scripts/vf-cockpit.mjs" "$pm"; res=" $RES "; retire_leurres
    assert_eq "$mn — le mutant (nom nu) exécute le leurre « $mk » du lab : le marqueur apparaît (rouge détecté)" "$([[ "$res" == *" ${mk}=0 "* ]] && echo "identique : $RES" || echo rouge)" "rouge"
  else assert_eq "$mn — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
done

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
