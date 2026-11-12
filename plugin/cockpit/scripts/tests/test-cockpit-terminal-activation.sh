#!/usr/bin/env bash
# test-cockpit-terminal-activation.sh — activation du terminal intégré côté serveur et tranche traçante
# (TERM-01, T7, T8.1, T11.4 ; P71-D-02, D-07, D-09 à D-11 ; pose de l'assistant, P71-D-06 et P71-PL-21).
#   T7   sans `--terminal` : route 404, un seul écouteur, CSP de v2.75.0, server.json sans clé terminal, aucun script du tiroir
#   T7   avec `--terminal` : second écouteur 127.0.0.1 d'un port distinct, rien de secret dans le journal ni dans server.json
#   T8.1 CSP de P = formule de v2.75.0 + `; frame-src http://127.0.0.1:<Q>` exact · P5.1 route de P sous jeton
#   E2E  amorçage à usage unique, aucun assistant avant le flux, commande aller-retour, ligne de commande de l'assistant, arrêt sans reste
#   T11.4 sous Windows : aucun écouteur, état « indisponible »
#   POSE l'engine pose `terminal/vf-cockpit-pty.py` dans les trois scopes et un serveur INSTALLÉ le lance
#   M-*  mutants (copies du module par cockpit_module_muter ; la sortie ne porte que des données) : M-ACTIF, M-ECOUTE0, M-FRAMESRC, M-WIN, M-HORS-MOTEUR
# Chaque témoin négatif a son contrôle positif ; la suite rougit sur un module antérieur à la tranche. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$SCRIPTS/../skills/cockpit-moteur"; PLUGIN="$(cd "$SCRIPTS/../.." && pwd)"; INSTALLER="$PLUGIN/_internal/vibeflow-update.sh"
TA="$HERE_T/terminal-aux.mjs"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home/.claude/scripts" "$WORK/bin" "$WORK/run"
export REAL_HOME="$HOME"; export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"
# P71-D-33 : Q tourne dans un processus enfant du serveur ; « les enfants du serveur » = les assistants, enfants de ce processus (pgrep -P ne voit qu'un étage)
pgrep() { if [ "$1" = "-P" ] && [ $# -eq 2 ]; then local c; for c in $(command pgrep -P "$2"); do if ps -o command= -p "$c" 2>/dev/null | grep -q 'vf-cockpit-terminal-processus.mjs'; then command pgrep -P "$c"; else echo "$c"; fi; done; else command pgrep "$@"; fi; }
# écouteurs du serveur ET de son processus du terminal (Q y écoute, P71-D-33) ; lignes vides écartées
ecoutes_srv() { local c; { node "$TA" ecoutes "$1"; for c in $(command pgrep -P "$1"); do ps -o command= -p "$c" 2>/dev/null | grep -q 'vf-cockpit-terminal-processus.mjs' && node "$TA" ecoutes "$c"; done; } | sed '/^$/d'; }
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; } # une valeur longue montre son début ET sa fin
assert_has() { if [[ "$2" == *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu (sous-chaîne): [$3]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }
assert_not() { if [[ "$2" != *"$3"* ]]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     sous-chaîne interdite: [$3]"; echo "     obtenu:  [${2:0:300}]"; FAIL=$((FAIL+1)); fi; }

cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
# shell de test (P71-PL-11) : marqué par son chemin, écrit son PID puis lance un shell interactif SANS exec (le PID reste celui du script)
cat > "$WORK/bin/shell-test" <<SH
#!/bin/sh
echo \$\$ > "$WORK/run/shell.pid"
/bin/sh -i
SH
chmod +x "$WORK/bin/shell-test"
export SHELL="$WORK/bin/shell-test"

rq() { node "$TA" req "$@"; }
sta() { rq "$@" | sed -n 1p; }
hdr() { rq "$@" | sed -n 2p; }
amorce_neuve() { node -e "console.log(require('crypto').randomBytes(24).toString('hex'))"; }

mklab() { # mklab <dir> : lab GSD minimal, construit ; sortie dans <dir>/.vibeflow/cockpit
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"; printf 'export const u = 1;\n' > "$L/src/u.js"
  printf -- '## Phases\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Goal**: Poser le socle\n' > "$B/ROADMAP.md"
  printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0 MVP\n---\n' > "$B/STATE.md"
  printf -- '---\nwave: 1\nfiles_modified: [src/u.js]\n---\n<objective>Poser le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit.mjs" build --lab "$L" > "$WORK/build-$(basename "$L").out" 2>&1 || cat "$WORK/build-$(basename "$L").out"
}
SRVN=0
# 79-06 : le code ne vit plus dans la sortie. MOD_DEPOT = racine du module du dépôt ; mod_de <sortie> = racine du module que COMMANDE cette sortie
# (table posée par mutant() : sortie TAB module ; par défaut le module du dépôt). La table est lue par bash (awk) et par les petits scripts node.
MOD_DEPOT="$(cd "$SCRIPTS/.." && pwd -P)"; MODS_TABLE="$WORK/.mods"; : > "$MODS_TABLE"; export MODS_TABLE MOD_DEPOT
mod_de() { local m; m="$(awk -F'\t' -v s="${1:-}" '$1==s{m=$2} END{print m}' "$MODS_TABLE" 2>/dev/null)"; printf '%s\n' "${m:-$MOD_DEPOT}"; }
srv() { # srv <sortie> <0|1 terminal> [moteur] [scripts] [module] -> SRV_PORT SRV_PID SRV_O SRV_OUT ; serveur du MODULE (celui de la sortie visée, ou celui passé), lancé par l'aide
  local o="$1" term="${2:-0}" eng="${3:-}" scr="${4:-}" mod="${5:-}" lab; lab="$(cd "$1/../.." && pwd)"
  SRVN=$((SRVN+1)); SRV_O="$o"; SRV_OUT="$WORK/serve-$SRVN-$RANDOM.out"; rm -f "$o/.cache/server.json" "$o/.cache/terminal-amorce"
  local flag=() ev=(); mkdir -p "$o/.cache"
  if [ "$term" = 1 ]; then flag=(--terminal); AMORCE="$(amorce_neuve)"; (umask 077; printf '%s' "$AMORCE" > "$o/.cache/terminal-amorce"); (umask 077; printf '%s' "$AMORCE" > "$WORK/amorce.copy"); fi
  [ -z "$eng" ] || ev+=(VF_COCKPIT_ENGINE_DIR="$eng"); [ -z "$scr" ] || ev+=(VF_COCKPIT_SCRIPTS_DIR="$scr")
  if [ -n "$mod" ]; then COCKPIT_MODULE="$mod" COCKPIT_LOG="$SRV_OUT" cockpit_lancer "$lab" ${ev[@]+"${ev[@]}"} ${flag[@]+"${flag[@]}"}
  elif [ -n "$eng$scr" ]; then COCKPIT_LOG="$SRV_OUT" cockpit_lancer "$lab" ${ev[@]+"${ev[@]}"} ${flag[@]+"${flag[@]}"}   # dossiers de recherche factices : le serve.mjs du dépôt, les variables de la suite gagnent
  else COCKPIT_MODULE="$(mod_de "$o")" COCKPIT_LOG="$SRV_OUT" cockpit_lancer "$lab" ${flag[@]+"${flag[@]}"}; fi
  if [ "$term" = 1 ]; then attendre 5 grep -qs '"terminal"' "$o/.cache/server.json"; fi # la clé terminal manque quand le moteur refuse l'assistant : attente bornée, sans échec
  SRV_PID="$VF_PID"; SRV_PORT="${VF_PORT:-0}"
}
sj() { node "$AUX/ev.mjs" "$1" < "$SRV_O/.cache/server.json" 2>/dev/null; }
unsrv() { vf_hyg_stop "$SRV_PID"; }
nlignes() { printf '%s\n' "$1" | grep -c . ; }
mutant() { # mutant <nom> <fichier> <expression-sed> -> MUT_OUT (copie du lab : données) et MUT_MOD (racine de la copie du module) ; code 1 si la cible manque ou si la copie n'a pas changé
  local d="$WORK/mut-$1" f; rm -rf "$d" "$WORK/mod-$1"; mkdir -p "$d"; cp -R "$LAB/.planning" "$d/.planning"; cp -R "$LAB/.vibeflow" "$d/.vibeflow"
  MUT_OUT="$d/.vibeflow/cockpit"; MUT_MOD=""
  case "$(basename "$2")" in
    serve.mjs|graph-query.js|query-cli.mjs|vf-cockpit-*) cockpit_module_muter "$1" "$2" "$3" || return 1; MUT_MOD="$COCKPIT_MODULE"; unset COCKPIT_MODULE; printf '%s\t%s\n' "$MUT_OUT" "$MUT_MOD" >> "$MODS_TABLE"; return 0 ;;
  esac
  f="$MUT_OUT/$2"; [ -f "$f" ] || return 1
  cp "$f" "$f.orig"; sed -i.bak "$3" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
# empreinte des fichiers du cockpit du VRAI ~/.claude (la suite ne doit rien y poser)
snap_home() { find "$REAL_HOME/.claude/agents" "$REAL_HOME/.claude/skills" "$REAL_HOME/.claude/scripts" "$REAL_HOME/.claude/rules" "$REAL_HOME/.claude/commands" -iname '*cockpit*' 2>/dev/null | sort | cksum | tr -d ' '; }
HOME_AVANT="$(snap_home)"

LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"

echo "=== T7 — sans le drapeau (TERM-01) ==="
srv "$OUT" 0; P0=$SRV_PORT; PID0=$SRV_PID; TOK0="$(sj j.token)"
assert_eq "T7.0 — témoin : le lab se construit, le serveur démarre, GET /api/vf/etat rend 200 sous le jeton de server.json" "$([ "$P0" -gt 0 ] && sta "$P0" GET /api/vf/etat --jeton "$TOK0" || echo "pas de serveur")" "200"
assert_eq "T7.1 — sans le drapeau, GET /api/vf/terminal sous jeton valide rend 404" "$(sta "$P0" GET /api/vf/terminal --jeton "$TOK0")" "404"
rq "$P0" GET / --corps-vers "$WORK/page-index.html" > "$WORK/r-index.out"; rq "$P0" GET /project.html --corps-vers "$WORK/page-projet.html" > "$WORK/r-projet.out"
for pg in index projet; do
  nom="/"; [ "$pg" = projet ] && nom="/project.html"
  CSPS="$(sed -n 2p "$WORK/r-$pg.out" | node "$AUX/ev.mjs" 'j["content-security-policy"]')"
  assert_eq "T7.2 — $nom : CSP = formule de v2.75.0 appliquée aux scripts de la page servie" "$CSPS" "$(node "$TA" csp-v275 "$WORK/page-$pg.html")"
  assert_not "T7.2 — $nom : aucune sous-chaîne frame-src" "$CSPS" "frame-src"
done
assert_eq "T7.2b — la ligne « const csp = » de la sortie serve.mjs est la copie figée de v2.75.0" "$(node "$TA" ligne-csp "$OUT/serve.mjs")" "$(node "$TA" ligne-csp-v275)"
ECO0="$(node "$TA" ecoutes "$PID0")"
assert_eq "T7.3 — témoin : la mesure des écouteurs voit le port de P" "$ECO0" "127.0.0.1:$P0"
assert_eq "T7.3 — sans le drapeau, un seul écouteur pour le PID du serveur" "$(nlignes "$ECO0")" "1"
assert_eq "T7.4 — témoin : server.json porte la clé port" "$(sj 'typeof j.port')" "number"
assert_eq "T7.4 — sans le drapeau, server.json n'a pas de clé terminal" "$(sj '"terminal" in j')" "false"
assert_eq "T7.5 — témoin : les deux pages servies sont lues en entier" "$([ "$(wc -c < "$WORK/page-index.html")" -gt 100000 ] && [ "$(wc -c < "$WORK/page-projet.html")" -gt 100000 ] && echo oui || echo non)" "oui"
assert_eq "T7.5 — pages servies sans « VibeFlow (71- » ni « vf-term- »" "$(cat "$WORK/page-index.html" "$WORK/page-projet.html" | grep -c -e 'VibeFlow (71-' -e 'vf-term-')" "0"
unsrv

echo "=== M-ACTIF — import du terminal sans le test du drapeau ==="
if mutant actif serve.mjs "s/has('terminal')/true/"; then
  srv "$MUT_OUT" 0; assert_eq "M-ACTIF — le mutant rougit T7.3 : deux écouteurs sans le drapeau" "$(nlignes "$(ecoutes_srv "$SRV_PID")")" "2"; unsrv
else assert_eq "M-ACTIF — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

echo "=== T7.7 / T7.8 / T8.1 / P5.1 — avec le drapeau ==="
srv "$OUT" 1; P1=$SRV_PORT; PID1=$SRV_PID; TOK1="$(sj j.token)"; QURL="$(sj '(j.terminal&&j.terminal.url)||"clé terminal absente de server.json"')"
QPORT=""; [[ "$QURL" =~ ^http://127\.0\.0\.1:[0-9]+$ ]] && QPORT="${QURL##*:}"
assert_eq "T7.7 — server.json porte terminal.url de forme http://127.0.0.1:<Q>, Q différent de P" "$([ -n "$QPORT" ] && [ "$QPORT" != "$P1" ] && echo "oui" || echo "non : $QURL (P=$P1)")" "oui"
QPORT="${QPORT:-1}"
ECO1="$(ecoutes_srv "$PID1")"
assert_eq "T7.8 — exactement deux écouteurs, tous deux 127.0.0.1 (P et Q)" "$(printf '%s\n' "$ECO1" | sort | tr '\n' ' ')" "$(printf '127.0.0.1:%s\n127.0.0.1:%s\n' "$P1" "$QPORT" | sort | tr '\n' ' ')"
rq "$P1" GET / --corps-vers "$WORK/page-index-t.html" > "$WORK/r-index-t.out"
assert_eq "T8.1 — CSP de / avec le drapeau = formule de v2.75.0 + « ; frame-src http://127.0.0.1:<Q> » exact" "$(sed -n 2p "$WORK/r-index-t.out" | node "$AUX/ev.mjs" 'j["content-security-policy"]')" "$(node "$TA" csp-v275 "$WORK/page-index-t.html"); frame-src http://127.0.0.1:$QPORT"
assert_eq "P5.1 — GET /api/vf/terminal sous jeton : {\"etat\":\"actif\",\"port\":<Q>}" "$(rq "$P1" GET /api/vf/terminal --jeton "$TOK1" | sed '1,2d')" "{\"etat\":\"actif\",\"port\":$QPORT}"
assert_eq "P5.1 — sans jeton : 403" "$(sta "$P1" GET /api/vf/terminal)" "403"

echo "=== E2E — amorçage, flux, commande, arrêt ==="
read -r CODE1 SECRET < <(node "$TA" amorcer "$QPORT" "$WORK/amorce.copy" | tr '\n' ' ')
assert_eq "E2E.1 — l'échange de l'amorçage rend 200 et un secret de 64 hexadécimaux" "$CODE1 $([[ "$SECRET" =~ ^[0-9a-f]{64}$ ]] && echo secret-64-hex || echo "secret invalide : ${SECRET:-vide}")" "200 secret-64-hex"
[[ "$SECRET" =~ ^[0-9a-f]{64}$ ]] || SECRET=""
assert_eq "E2E.2 — un second échange du même amorçage rend 403 (usage unique)" "$(node "$TA" amorcer "$QPORT" "$WORK/amorce.copy" | sed -n 1p)" "403"
sleep 20 & SLP=$!; assert_eq "E2E.3 — témoin : pgrep -P voit un enfant du shell de la suite" "$(pgrep -P $$ | grep -c "^$SLP\$")" "1"; kill "$SLP" 2>/dev/null; wait "$SLP" 2>/dev/null
if [ -n "$SECRET" ]; then ENFANTS="$(pgrep -P "$PID1" | grep -c . || true)"; else ENFANTS="pas de secret : échange impossible"; fi
assert_eq "E2E.3 — aucun assistant PTY avant GET /flux (après un échange réussi)" "$ENFANTS" "0"
ONGLET="onglet-test-1"; FPID=""
if [ -n "$SECRET" ]; then
  node "$TA" flux "$QPORT" "$SECRET" "$ONGLET" "$WORK/flux.out" 25000 > "$WORK/flux.log" 2>&1 & FPID=$!
  for _ in $(seq 1 50); do [ -n "$(pgrep -P "$PID1")" ] && break; sleep 0.1; done
  node "$TA" entree "$QPORT" "$SECRET" "$ONGLET" "echo TRAC''EUR-OK\\r" > "$WORK/entree.out" 2>&1
  TROUVE="$(node "$TA" attendre "$WORK/flux.out" TRACEUR-OK 10000)"
else TROUVE="pas de secret : flux impossible"; fi
assert_eq "E2E.4 — une commande envoyée par POST /entree revient dans le flux (TRACEUR-OK en moins de 10 s)" "$TROUVE" "TROUVE"
APID="$(pgrep -P "$PID1" | sed -n 1p)"; ACMD=""; [ -n "$APID" ] && ACMD="$(ps -o args= -p "$APID" 2>/dev/null)"
SANS_ASSISTANT="aucun assistant"; if [[ "$ACMD" == *" -I "* && "$ACMD" == *vf-cockpit-pty.py* ]]; then CMDOK=oui; else CMDOK="non : ${ACMD:-$SANS_ASSISTANT}"; fi
assert_eq "E2E.5 — la ligne de commande de l'assistant contient « -I » et « vf-cockpit-pty.py »" "$CMDOK" "oui"
SHPID="$(cat "$WORK/run/shell.pid" 2>/dev/null)"; SHSUB=""; [ -n "$SHPID" ] && SHSUB="$(pgrep -P "$SHPID" | sed -n 1p)"
if [ -n "$SECRET" ]; then FUITES="$(cat "$SRV_OUT" "$SRV_O/.cache/server.json" | grep -c -F -e "$AMORCE" -e "$SECRET" || true)"; else FUITES="pas de secret : mesure impossible"; fi
assert_eq "T7.10 — l'amorçage et le secret ne figurent ni dans le journal du serveur ni dans server.json" "$FUITES" "0"
unsrv
SURV=""; if [ -n "$APID" ] && [ -n "$SHPID" ]; then
  for _ in $(seq 1 50); do SURV=""; for p in $APID $SHPID $SHSUB; do kill -0 "$p" 2>/dev/null && SURV="$SURV $p"; done; [ -z "$SURV" ] && break; sleep 0.1; done
else SURV="rien à surveiller (assistant=${APID:-aucun} shell=${SHPID:-aucun})"; fi
assert_eq "E2E.6 — à l'arrêt du serveur, l'assistant et le shell disparaissent en moins de 5 s" "${SURV:-aucun}" "aucun"
[ -n "$FPID" ] && { wait "$FPID" 2>/dev/null; true; }

echo "=== M-ECOUTE0 / M-FRAMESRC — mutants du serveur Q ==="
if mutant ecoute0 vf-cockpit-terminal-processus.mjs "s/\.listen(0, '127\.0\.0\.1'/.listen(0, '0.0.0.0'/"; then
  srv "$MUT_OUT" 1; assert_eq "M-ECOUTE0 — le mutant rougit T7.8 : Q n'écoute plus sur 127.0.0.1 seulement" "$(ecoutes_srv "$SRV_PID" | grep -c -v '^127\.0\.0\.1:')" "1"; unsrv
else assert_eq "M-ECOUTE0 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant framesrc vf-cockpit-terminal.mjs 's#frame-src http://127\.0\.0\.1:\${portQ}#frame-src *#'; then
  srv "$MUT_OUT" 1; MP=$SRV_PORT; rq "$MP" GET / > "$WORK/r-mut-fs.out"
  assert_has "M-FRAMESRC — le mutant rougit T8.1 : la CSP de P porte « frame-src * »" "$(sed -n 2p "$WORK/r-mut-fs.out" | node "$AUX/ev.mjs" 'j["content-security-policy"]')" "frame-src *"; unsrv
else assert_eq "M-FRAMESRC — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

echo "=== T11.4 — sous Windows : aucun écouteur, état indisponible ==="
cat > "$AUX/win.mjs" <<'JS'
// win.mjs <sortie> <lab> : appelle preparerTerminal({ plateforme: 'win32' }) de la sortie ; une ligne JSON
import { pathToFileURL } from 'node:url';
const msgs = []; console.error = (...a) => msgs.push(a.join(' '));
const [, , sortie, lab] = process.argv;
// 79-06 : le code n'est plus dans la sortie : le module est celui que commande cette sortie (table MODS_TABLE : sortie TAB module ; défaut MOD_DEPOT)
import fs from 'node:fs';
let racine = process.env.MOD_DEPOT; try { for (const l of fs.readFileSync(process.env.MODS_TABLE, 'utf8').split('\n')) { const [s, r] = l.split('\t'); if (s === sortie && r) racine = r; } } catch {}
let m; try { m = await import(pathToFileURL(racine + '/scripts/vf-cockpit-terminal.mjs').href); } catch { console.log('module introuvable'); process.exit(0); }
const ecoutes = () => process._getActiveHandles().filter((h) => h && h.listening).length;
const t = m.preparerTerminal({ here: racine + '/scripts', root: lab, jetons: () => [], plateforme: 'win32' });
t.demarrer(0); await new Promise((r) => setTimeout(r, 300));
let corps = ''; const res = { setHeader() {}, writeHead() {}, end(b) { corps = String(b || ''); } };
t.routeP({ method: 'GET', url: '/api/vf/terminal', headers: {} }, res);
console.log(`indisponible=${t.indisponible} actif=${t.actif} ecouteurs=${ecoutes()} corps=${corps} message=${msgs.some((x) => x.includes('Terminal indisponible sous Windows.'))}`);
process.exit(0);
JS
ATTENDU_WIN='indisponible=true actif=false ecouteurs=0 corps={"etat":"indisponible"} message=true'
assert_eq "T11.4 — plateforme win32 : indisponible, aucun serveur créé, routeP rend {\"etat\":\"indisponible\"}, message « Terminal indisponible sous Windows. »" "$(node "$AUX/win.mjs" "$OUT" "$LAB")" "$ATTENDU_WIN"
if mutant win vf-cockpit-terminal.mjs "s/plateforme === 'win32'/plateforme === 'win-32'/"; then
  MW="$(node "$AUX/win.mjs" "$MUT_OUT" "$LAB")"; assert_eq "M-WIN — le mutant rougit T11.4 (le test de plateforme est retiré)" "$([ "$MW" != "$ATTENDU_WIN" ] && echo rouge || echo "identique : $MW")" "rouge"
else assert_eq "M-WIN — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

echo "=== POSE — l'engine pose l'assistant dans l'arbre du moteur (P71-D-06, P71-PL-21) ==="
FH="$WORK/fh"; mkdir -p "$FH"; CACHE="$WORK/cache"; CACHE2="$WORK/cache2"
mkdir -p "$CACHE/cockpit" "$CACHE2/cockpit"; cp -R "$PLUGIN/cockpit/." "$CACHE/cockpit/"; cp -R "$PLUGIN/cockpit/." "$CACHE2/cockpit/"
pose() { local scope="$1" lab="$2" cache="${3:-$CACHE}"; (cd "$lab" && HOME="$FH" VF_SCOPE="$scope" VIBEFLOW_CACHE="$cache" bash "$INSTALLER" install cockpit > "$WORK/pose-$scope.out" 2>&1); }
mkposelab() { local d="$WORK/lab-$1"; mkdir -p "$d/src" "$d/.planning/phases/01-x"; printf 'export const u = () => 1;\n' > "$d/src/util.js"; printf -- '- [x] **Phase 1: Socle** - premier jet\n' > "$d/.planning/ROADMAP.md"; printf '<objective>Faire le socle</objective>\n' > "$d/.planning/phases/01-x/01-01-PLAN.md"; git -C "$d" init -q 2>/dev/null; echo "$d"; }
SRC_PY="$PLUGIN/cockpit/skills/cockpit-moteur/terminal/vf-cockpit-pty.py"
empreinte() { [ -f "$1" ] && cksum < "$1" || echo absent; }
LP="$(mkposelab project)"; LU="$(mkposelab user)"; LL="$(mkposelab local)"
pose project "$LP"; pose user "$LU"; pose local "$LL"
EMP_SRC="$(empreinte "$SRC_PY")"; P1R=""
for r in "project:$LP/.claude" "user:$FH/.claude" "local:$LL/.claude"; do
  e="$(empreinte "${r#*:}/skills/cockpit-moteur/terminal/vf-cockpit-pty.py")"; if [ "$EMP_SRC" != absent ] && [ "$e" = "$EMP_SRC" ]; then P1R="$P1R ${r%%:*}:identique"; else P1R="$P1R ${r%%:*}:$([ "$e" = absent ] && echo absent || echo different)"; fi
done
assert_eq "POSE.1 — l'engine pose terminal/vf-cockpit-pty.py dans les scopes project, user et local, identique à la source (cksum)" "${P1R# }" "project:identique user:identique local:identique"

sonde_pose() { # sonde_pose <lab> <moteur> <scripts> : construit avec le lanceur POSÉ, lance le serveur de la sortie avec les chemins POSÉS, rend « ok » ou la raison
  local lab="$1" eng="$2" scr="$3" o="$1/.vibeflow/cockpit" sec fp res=""
  (cd "$lab" && HOME="$FH" node "$scr/vf-cockpit.mjs" build --lab "$lab" > "$WORK/build-pose.out" 2>&1) || { echo "construction impossible"; return; }
  srv "$o" 1 "$eng" "$scr" "${eng%/skills/cockpit-moteur}"; local q; q="$(sj '(j.terminal&&j.terminal.url)||""')"; q="${q##*:}"
  if [ -z "$q" ]; then unsrv; echo "pas de second écouteur (terminal arrêté)"; return; fi
  sec="$(node "$TA" amorcer "$q" "$WORK/amorce.copy" | sed -n 2p)"
  if [ -z "$sec" ]; then unsrv; echo "échange refusé"; return; fi
  rm -f "$WORK/posefl.out"; node "$TA" flux "$q" "$sec" onglet-pose "$WORK/posefl.out" 15000 > /dev/null 2>&1 & fp=$!
  for _ in $(seq 1 50); do [ -n "$(pgrep -P "$SRV_PID")" ] && break; sleep 0.1; done
  node "$TA" entree "$q" "$sec" onglet-pose "echo TRAC''EUR-OK\\r" > /dev/null 2>&1
  if [ "$(node "$TA" attendre "$WORK/posefl.out" TRACEUR-OK 10000)" = TROUVE ]; then
    local a c; a="$(pgrep -P "$SRV_PID" | sed -n 1p)"; c="$(ps -o args= -p "$a" 2>/dev/null)"
    [[ "$c" == *"$eng/terminal/vf-cockpit-pty.py"* ]] && res="ok" || res="la ligne de commande ne cite pas l'assistant posé : $c"
  else res="aucune réponse du shell"; fi
  unsrv; wait "$fp" 2>/dev/null; echo "$res"
}
assert_eq "POSE.2 — serveur INSTALLÉ (scope project) : échange, flux, TRACEUR-OK, la ligne de commande de l'assistant cite le chemin posé" "$(sonde_pose "$LP" "$LP/.claude/skills/cockpit-moteur" "$LP/.claude/scripts")" "ok"
# POSE.3 : moteur posé sans terminal/ -> état arrêté, journal, un seul écouteur, aucun Python lancé
cp -R "$LP/.claude/skills/cockpit-moteur" "$WORK/moteur-sans-terminal"; rm -rf "$WORK/moteur-sans-terminal/terminal"
srv "$LP/.vibeflow/cockpit" 1 "$WORK/moteur-sans-terminal" "$LP/.claude/scripts"; P3=$SRV_PORT; TOK3="$(sj j.token)"
assert_eq "POSE.3 — moteur sans terminal/ : /api/vf/terminal rend {\"etat\":\"arrete\"}" "$(rq "$P3" GET /api/vf/terminal --jeton "$TOK3" | sed '1,2d')" '{"etat":"arrete"}'
assert_has "POSE.3 — le journal dit « assistant du terminal introuvable »" "$(cat "$SRV_OUT")" "assistant du terminal introuvable"
assert_eq "POSE.3 — aucun second écouteur" "$(nlignes "$(ecoutes_srv "$SRV_PID")")" "1"
assert_eq "POSE.3 — aucun processus enfant (aucun Python lancé)" "$(pgrep -P "$SRV_PID" | grep -c .)" "0"
unsrv
assert_eq "POSE.4 — le vrai ~/.claude est inchangé (fichiers du cockpit)" "$(snap_home)" "$HOME_AVANT"

echo "=== M-HORS-MOTEUR — l'assistant sorti de l'arbre du moteur fait rougir POSE.1 et POSE.2 ==="
if [ -f "$CACHE2/cockpit/skills/cockpit-moteur/terminal/vf-cockpit-pty.py" ] && mv "$CACHE2/cockpit/skills/cockpit-moteur/terminal/vf-cockpit-pty.py" "$CACHE2/cockpit/scripts/vf-cockpit-pty.py"; then
  LM="$(mkposelab mutant)"; pose project "$LM" "$CACHE2"
  M1="vert"; [ "$(empreinte "$LM/.claude/skills/cockpit-moteur/terminal/vf-cockpit-pty.py")" = absent ] && M1="rouge"
  M2="$(sonde_pose "$LM" "$LM/.claude/skills/cockpit-moteur" "$LM/.claude/scripts")"; [ "$M2" != ok ] && M2="rouge" || M2="vert"
  assert_eq "M-HORS-MOTEUR — le mutant rougit POSE.1 puis POSE.2" "$M1,$M2" "rouge,rouge"
else assert_eq "M-HORS-MOTEUR — mutant sans effet (assistant absent de terminal/ dans le cache)" "sans effet" "effet"; fi

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
