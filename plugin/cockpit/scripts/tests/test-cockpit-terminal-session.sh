#!/usr/bin/env bash
# test-cockpit-terminal-session.sh — session du terminal : une seule, grâce, tampon de reprise, inactivité, rien sur disque
# (TERM-08, TERM-11 ; P71-D-05, P71-D-19 ; plan 71-04). Durée annoncée : environ 90 s, dont 65 s d'attente pour T12.5 (menée en parallèle des autres sondes).
#   T12.1 un autre onglet reçoit 409 sur /flux, sans processus de plus   T12.2 flux fermé, retour avant la grâce : même shell, tampon rejoué
#   T12.3 grâce écoulée : assistant et shell disparus, /etat absente      T12.5 un terminal ouvert empêche l'arrêt sur inactivité
#   T12.6 un autre onglet : 409 sur /entree et /taille, aucun octet écrit T12.7 tampon borné à 256 Kio, la fin de la production présente
#   T12.8 fin du shell rapportée (code), 410 sans session                 T15.1 aucune frappe ni sortie hors de la mémoire de la session
#   T15.2 le tampon est vidé à la fin : une nouvelle session ne rejoue rien de l'ancienne
#   Sp2   la grâce par défaut (sans override) vaut 30 000 ms ; un réglage hors plage retombe sur ce défaut
#   S4    expiration de la grâce : une nouvelle session ne démarre qu'après la fin de l'ancienne (jamais deux assistants)
#   N5    fermeture bornée : un assistant qui ignore SIGTERM reçoit SIGKILL et la place est rendue (réglage de test VF_COCKPIT_TERM_FERMETURE_MS)
#   T15.3 le tampon est aussi vidé à la fin de la grâce       CP   contre-pression sur la réponse : un lecteur à l'arrêt bloque la production du shell
#   M-*   mutants (copies du module par cockpit_module_muter) : M-GRACE0, M-UNIQUE, M-PROPRIO, M-IDLE, M-TAMPON, M-JOURNAL, M-GRACE-DEFAUT, M-EXPIRATION, M-TAMPON-GRACE, M-CONTREPRESSION, M-SANS-SIGKILL
# Chaque témoin négatif a son contrôle positif ; un mutant sans effet est un FAIL. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$SCRIPTS/../skills/cockpit-moteur"; TA="$HERE_T/terminal-aux.mjs"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/home" "$WORK/bin" "$WORK/tmp-serveur"
export HOME="$WORK/home"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"
# P71-D-33 : Q tourne dans un processus enfant du serveur ; « les enfants du serveur » = les assistants, enfants de ce processus (pgrep -P ne voit qu'un étage)
pgrep() { if [ "$1" = "-P" ] && [ $# -eq 2 ]; then local c; for c in $(command pgrep -P "$2"); do if ps -o command= -p "$c" 2>/dev/null | grep -q 'vf-cockpit-terminal-processus.mjs'; then command pgrep -P "$c"; else echo "$c"; fi; done; else command pgrep "$@"; fi; }
PASS=0; FAIL=0
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; } # une valeur longue montre son début ET sa fin
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }

cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/sse.mjs" <<'JS'
// sse.mjs <port> <jeton> <ms> : première ligne « STATUT <code> », puis tout ce que le flux d'événements de P envoie pendant <ms>
import http from 'node:http';
const [, , port, token, ms] = process.argv;
const req = http.get({ host: '127.0.0.1', port: Number(port), path: '/api/vf/events?token=' + token, headers: { Host: `127.0.0.1:${port}` } }, (res) => { console.log('STATUT ' + res.statusCode); res.on('data', (c) => process.stdout.write(c)); });
req.on('error', () => { console.log('STATUT erreur'); process.exit(0); });
setTimeout(() => process.exit(0), Number(ms));
JS
cat > "$AUX/idx.mjs" <<'JS'
// idx.mjs <fichier> <sous-chaine> : décalage en octets de la première occurrence (-1 si absente)
import fs from 'node:fs'; let t = ''; try { t = fs.readFileSync(process.argv[2]).toString('latin1'); } catch {} console.log(t.indexOf(process.argv[3]));
JS
# shell de test (P71-PL-11) : marqué par son chemin, lance un shell interactif SANS exec (PID du script = PID du shell vu par pgrep)
printf '#!/bin/sh\n/bin/sh -i\n' > "$WORK/bin/shell-test"; chmod +x "$WORK/bin/shell-test"
export SHELL="$WORK/bin/shell-test"

# shell obstiné (S4) : ignore SIGHUP/SIGTERM/SIGINT, l'assistant doit attendre sa grâce de 3 s puis envoyer SIGKILL
printf '#!/bin/sh\ntrap "" HUP TERM INT\nexec sleep 30\n' > "$WORK/bin/shell-test-tetu"; chmod +x "$WORK/bin/shell-test-tetu"
cat > "$AUX/lent.mjs" <<'JS'
// lent.mjs <port> <secret> <onglet> <pause-ms> <fichier> : ouvre /flux, NE LIT PAS pendant <pause-ms> (le socket se remplit), puis lit ; écrit le nombre d'octets reçus
import http from 'node:http'; import fs from 'node:fs';
const [, , port, secret, onglet, pause, out] = process.argv;
const r = http.request({ host: '127.0.0.1', port: +port, path: '/flux', method: 'GET', agent: false, headers: { Host: `127.0.0.1:${port}`, Origin: `http://127.0.0.1:${port}`, 'X-VF-Terminal': secret, 'X-VF-Onglet': onglet } }, (res) => {
  let n = 0; res.pause();
  setTimeout(() => { res.on('data', (c) => { n += c.length; }); res.resume(); }, +pause);
  setTimeout(() => { fs.writeFileSync(out, String(n)); process.exit(0); }, +pause + 60000);
});
r.on('error', () => process.exit(0)); r.end();
JS
hex32() { node -e "console.log(require('crypto').randomBytes(16).toString('hex'))"; }
ONG_A="$(hex32)"; ONG_B="$(hex32)"
rq() { node "$TA" req "$@"; }
sta() { rq "$@" | sed -n 1p; }
sj() { node "$AUX/ev.mjs" "$1" < "$SRV_O/.cache/server.json" 2>/dev/null; }
mklab() { # mklab <dir> : lab GSD minimal, construit ; sortie dans <dir>/.vibeflow/cockpit
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"; printf 'export const u = 1;\n' > "$L/src/u.js"
  printf -- '## Phases\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Goal**: Poser le socle\n' > "$B/ROADMAP.md"
  printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0 MVP\n---\n' > "$B/STATE.md"
  printf -- '---\nwave: 1\nfiles_modified: [src/u.js]\n---\n<objective>Poser le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit.mjs" build --lab "$L" > "$WORK/build.out" 2>&1 || cat "$WORK/build.out"
}
SRVN=0; GRACE_T=3000
# 79-06 : le code ne vit plus dans la sortie. MOD_DEPOT = racine du module du dépôt ; mod_de <sortie> = racine du module que COMMANDE cette sortie
# (table posée par mutant() : sortie TAB module ; par défaut le module du dépôt).
MOD_DEPOT="$(cd "$SCRIPTS/.." && pwd -P)"; MODS_TABLE="$WORK/.mods"; : > "$MODS_TABLE"; export MODS_TABLE MOD_DEPOT
mod_de() { local m; m="$(awk -F'\t' -v s="${1:-}" '$1==s{m=$2} END{print m}' "$MODS_TABLE" 2>/dev/null)"; printf '%s\n' "${m:-$MOD_DEPOT}"; }
srv() { # srv <sortie> [arguments du serveur…] -> SRV_PID SRV_O SRV_OUT QP SEC ; serveur du MODULE de la sortie visée, lancé avec --terminal par l'aide
  local o="$1"; shift; local lab mod; lab="$(cd "$o/../.." && pwd)"; mod="$(mod_de "$o")"
  if [ -n "${ENG_SRV:-}" ]; then # moteur dont l'assistant est remplacé (ENG_SRV) : une copie du module (celui de la sortie, muté ou non) dont le moteur est ce moteur — l'empreinte publiée reste celle de la copie visée
    local mc="$WORK/modsrv-$((SRVN+1))"; rm -rf "$mc"; mc="$(cockpit_module_copie "$mc")" || return 1
    ( cd "$mod/scripts" && tar -cf - --exclude=tests . ) | ( cd "$mc/scripts" && tar -xf - ) && rm -rf "$mc/skills/cockpit-moteur" && cp -R "$ENG_SRV" "$mc/skills/cockpit-moteur" || return 1; mod="$mc"
  fi
  SRVN=$((SRVN+1)); SRV_O="$o"; SRV_OUT="$WORK/serve-$SRVN.out"; rm -f "$o/.cache/server.json"; mkdir -p "$o/.cache"
  local amorce; amorce="$(node -e "console.log(require('crypto').randomBytes(24).toString('hex'))")"; (umask 077; printf '%s' "$amorce" > "$o/.cache/terminal-amorce"); (umask 077; printf '%s' "$amorce" > "$WORK/amorce-$SRVN")
  COCKPIT_MODULE="$mod" COCKPIT_PRET=terminal COCKPIT_LOG="$SRV_OUT" cockpit_lancer "$lab" PATH="${PATH_SRV:-$PATH}" VF_COCKPIT_TERM_GRACE_MS="$GRACE_T" VF_COCKPIT_TERM_FERMETURE_MS="${FERM_T:-}" TMPDIR="$WORK/tmp-serveur" --terminal "$@"
  SRV_PID="$VF_PID"
  QP="$(sj '(j.terminal&&j.terminal.url)||""')"; QP="${QP##*:}"; SEC=""
  if [ -n "$QP" ]; then SEC="$(node "$TA" amorcer "$QP" "$WORK/amorce-$SRVN" | sed -n 2p)"; fi
}
unsrv() { vf_hyg_stop "$SRV_PID"; }
mutant() { # mutant <nom> <fichier> <expression-sed> -> MUT_OUT (copie du lab : données) et MUT_MOD (racine de la copie du module) ; code 1 si la cible manque ou si la copie n'a pas changé
  local d="$WORK/mut-$1" f; rm -rf "$d" "$WORK/mod-$1"; mkdir -p "$d"; cp -R "$LAB/.planning" "$d/.planning"; cp -R "$LAB/.vibeflow" "$d/.vibeflow"
  MUT_OUT="$d/.vibeflow/cockpit"; MUT_MOD=""
  case "$(basename "$2")" in
    serve.mjs|graph-query.js|query-cli.mjs|vf-cockpit-*) cockpit_module_muter "$1" "$2" "$3" || return 1; MUT_MOD="$COCKPIT_MODULE"; unset COCKPIT_MODULE; printf '%s\t%s\n' "$MUT_OUT" "$MUT_MOD" >> "$MODS_TABLE"; return 0 ;;
  esac
  f="$d/.vibeflow/cockpit/$2"; [ -f "$f" ] || return 1   # page de la copie du lab (donnée) : même chemin que MUT_OUT/<fichier>
  cp "$f" "$f.orig"; sed -i.bak "$3" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
copie() { local d="$WORK/cp-$1"; rm -rf "$d"; mkdir -p "$d"; cp -R "$LAB/.planning" "$d/.planning"; cp -R "$LAB/.vibeflow" "$d/.vibeflow"; MUT_OUT="$d/.vibeflow/cockpit"; }
# clients : flux en arrière-plan (PID enregistré dans FL), commande tapée par un onglet, attente bornée
flux() { # flux <fichier> <ms> [onglet] -> FL
  node "$TA" flux "$QP" "$SEC" "${3:-$ONG_A}" "$1" "$2" > "$1.log" 2>&1 & FL=$!; PIDS+=($FL); }
tape() { node "$TA" entree "$QP" "$SEC" "${2:-$ONG_A}" "$1"; }
vu() { node "$TA" attendre "$1" "$2" "$3"; }
python_de() { pgrep -P "$SRV_PID" | sed -n 1p; }
# Le shell est l'enfant de l'assistant qui porte le terminal du pty (ps -o tt= : un tty). L'autre enfant, le GARDIEN (forké avant pty.fork, donc au PID le plus bas),
# est sorti de la session par setsid : sans terminal de contrôle (tt= vaut ? sous Linux, ?? sous macOS). Aucune désignation par l'ordre des PID.
shell_sous() { local c; for c in $(pgrep -P "$1"); do [ -n "$(tt_de "$c")" ] && { echo "$c"; return 0; }; done; return 1; }
designation() { # designation <assistant> <shell> : « shell=tty|sans-terminal » puis « autres=<n> sans-terminal=<n> » (les enfants de l'assistant autres que le shell)
  local t c n=0 g=0; t="$(tt_de "${2:-0}")"; [ -n "$t" ] && echo "shell=tty" || echo "shell=sans-terminal"
  for c in $(pgrep -P "${1:-0}"); do [ "$c" = "$2" ] && continue; n=$((n+1)); [ -z "$(tt_de "$c")" ] && g=$((g+1)); done; echo "autres=$n sans-terminal=$g"; }
tt_de() { local t; t="$(ps -o tt= -p "$1" 2>/dev/null | tr -d ' ')"; case "$t" in ''|'?'|'??') ;; *) echo "$t" ;; esac; } # terminal de contrôle du PID, vide s'il n'en a pas
shell_de() { local a; a="$(python_de)"; [ -n "$a" ] && shell_sous "$a"; }
attendre_python() { for _ in $(seq 1 80); do [ -n "$(python_de)" ] && return 0; sleep 0.1; done; return 1; }
corps_etat() { node "$TA" etat "$QP" "$SEC" | sed -n 3p; }
etat_s() { corps_etat | node "$AUX/ev.mjs" 'j.session' 2>/dev/null; }
morts() { local fin=$((SECONDS+${1})); shift; local v; while [ $SECONDS -le $fin ]; do v=""; for p in "$@"; do [ -n "$p" ] && kill -0 "$p" 2>/dev/null && v="$v $p"; done; [ -z "$v" ] && return 0; sleep 0.2; done; return 1; }

LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"

# ----- sondes (rejouées sur le code puis sur les mutants) -----
sonde_unique() { # A attaché ; B -> 409 sur /flux ; rend « B=<statut> assistants=<n> A=<vu> »
  local f="$WORK/f-uniq-$SRVN.bin" st n a
  flux "$f" 40000; attendre_python; tape "echo ATTA''CHE-A\\r" > /dev/null
  a="$(vu "$f" ATTACHE-A 8000)"
  st="$(rq "$QP" GET /flux --secret "$SEC" --onglet "$ONG_B" --echeance 1500 | sed -n 1p)"
  n="$(pgrep -P "$SRV_PID" | grep -c . || true)"
  vf_hyg_stop "$FL"; echo "B=$st assistants=$n A=$a"
}
sonde_proprio() { # A attaché ; B tente /entree (touch) et /taille ; rend « entree=<s> taille=<s> fichierB=<existe|absent> fichierA=<existe|absent> »
  local f="$WORK/f-prop-$SRVN.bin" fb="$WORK/proprio-b-$SRVN.flag" fa="$WORK/proprio-a-$SRVN.flag" se st eb ea
  flux "$f" 40000; attendre_python
  se="$(tape "touch $fb\\r" "$ONG_B")"; st="$(node "$TA" taille "$QP" "$SEC" "$ONG_B" 30 100)"; sleep 1.5
  eb=absent; [ -e "$fb" ] && eb=existe
  tape "touch $fa\\r" > /dev/null; for _ in $(seq 1 60); do [ -e "$fa" ] && break; sleep 0.1; done
  ea=absent; [ -e "$fa" ] && ea=existe
  vf_hyg_stop "$FL"; echo "entree=$se taille=$st fichierB=$eb fichierA=$ea"
}
sonde_grace() { # A tape un marqueur, ferme son flux, revient après 1 s ; rend « memeshell=<oui|non> etat=<s> rejeu=<TROUVE|ABSENT> »
  local f1="$WORK/f-gr1-$SRVN.bin" f2="$WORK/f-gr2-$SRVN.bin" m="MARQ-AVANT-$RANDOM" sh1 sh2 r
  flux "$f1" 60000; attendre_python; tape "echo $m\\r" > /dev/null; vu "$f1" "$m" 8000 > /dev/null
  sh1="$(shell_de)"; vf_hyg_stop "$FL"; sleep 1
  flux "$f2" 20000; r="$(vu "$f2" "$m" 4000)"; sh2="$(shell_de)"
  echo "memeshell=$([ -n "$sh1" ] && [ "$sh1" = "$sh2" ] && echo oui || echo non) etat=$(etat_s) rejeu=$r"
  vf_hyg_stop "$FL"
}
sonde_confid() { # frappe + sortie ; rend « temoin=<oui|non> export=<s> sse=<s> fuites=<n> » (fuites = fichiers qui portent un marqueur hors du flux du client)
  local f="$WORK/f-conf-$SRVN.bin" n=$RANDOM tok p="$(sj j.port)" mf mo tw ex ss fu
  mf="MARQUEUR-FRAPPE-$n"; mo="MARQUEUR-SORTIE-$n"
  flux "$f" 40000; attendre_python; tape "echo $mf\\r" > /dev/null; tape "echo MARQUEUR-SOR''TIE-$n\\r" > /dev/null
  tw=non; [ "$(vu "$f" "$mo" 8000)" = TROUVE ] && [ "$(vu "$f" "$mf" 2000)" = TROUVE ] && tw=oui
  tok="$(sj j.token)"
  node "$AUX/sse.mjs" "$p" "$tok" 3000 > "$WORK/sse-$SRVN.out" 2>&1
  ex="$(rq "$p" POST /api/export --jeton "$tok" --entete "x-floorplan-token:$tok" --corps '{}' --corps-vers "$WORK/export-$SRVN.out" | sed -n 1p)"
  ss="$(sed -n 1p "$WORK/sse-$SRVN.out")"
  fu="$(grep -rlF -e "$mf" -e "$mo" "$(cd "$SRV_O/../.." && pwd)" "$SRV_OUT" "$WORK/tmp-serveur" "$WORK/sse-$SRVN.out" "$WORK/export-$SRVN.out" 2>/dev/null | grep -c . || true)"
  vf_hyg_stop "$FL"; echo "temoin=$tw export=$ex sse=$ss fuites=$fu"
}
sonde_tampon() { # un marqueur dans la session, `exit`, nouvelle session ; rend « ancien=<vu|non> nouvelle=<OK|non> rejeu=<n> »
  local f1="$WORK/f-tp1-$SRVN.bin" f2="$WORK/f-tp2-$SRVN.bin" m="MARQUEUR-ANCIEN-$RANDOM" a rj ok
  flux "$f1" 40000; attendre_python; tape "echo $m\\r" > /dev/null; a="$(vu "$f1" "$m" 8000)"
  tape "exit\\r" > /dev/null; for _ in $(seq 1 80); do [ "$(etat_s)" = terminee ] && break; sleep 0.1; done; vf_hyg_stop "$FL"
  flux "$f2" 20000; attendre_python; tape "echo NOUVEAU-OK\\r" > /dev/null; ok="$(vu "$f2" NOUVEAU-OK 8000)"
  rj="$(node "$AUX/idx.mjs" "$f2" MARQUEUR-ANCIEN)"
  vf_hyg_stop "$FL"; echo "ancien=$([ "$a" = TROUVE ] && echo vu || echo non) nouvelle=$([ "$ok" = TROUVE ] && echo OK || echo non) rejeu=$([ "$rj" = -1 ] && echo aucun || echo "present@$rj")"
}

echo "=== T12.5 — lancement des deux serveurs d'inactivité (code et M-IDLE, en parallèle de la suite) ==="
copie idle-code; IDLE_C="$MUT_OUT"
if mutant idle vf-cockpit-terminal-session.mjs "s/^    occupe: .*/    occupe: () => false,/"; then IDLE_M="$MUT_OUT"; else IDLE_M=""; fi
IDLE_T0=$SECONDS
srv "$IDLE_C" --idle-exit 0.01; IC_PID=$SRV_PID; IC_Q=$QP; IC_S=$SEC; IC_O=$SRV_O
node "$TA" flux "$IC_Q" "$IC_S" "$ONG_A" "$WORK/f-idle-c.bin" 90000 > "$WORK/f-idle-c.log" 2>&1 & PIDS+=($!); IC_F=$!
if [ -n "$IDLE_M" ]; then
  srv "$IDLE_M" --idle-exit 0.01; IM_PID=$SRV_PID; IM_Q=$QP; IM_S=$SEC
  node "$TA" flux "$IM_Q" "$IM_S" "$ONG_A" "$WORK/f-idle-m.bin" 90000 > "$WORK/f-idle-m.log" 2>&1 & PIDS+=($!); IM_F=$!
fi
for _ in $(seq 1 60); do [ -n "$(pgrep -P "$IC_PID" | sed -n 1p)" ] && break; sleep 0.1; done
IDLE_ATTACHE="$([ -n "$(pgrep -P "$IC_PID" | sed -n 1p)" ] && echo oui || echo non)"

echo "=== T12.8 — fin du shell rapportée ; sans session : 410 ==="
srv "$OUT"; MAIN_PID=$SRV_PID
assert_eq "T12.8 — témoin : le serveur a un second écouteur et l'échange de l'amorçage donne un secret de 64 hexadécimaux" "$([[ "$SEC" =~ ^[0-9a-f]{64}$ ]] && echo oui || echo "non : ${SEC:-vide}")" "oui"
assert_eq "T12.8 — sans session : /etat = absente" "$(etat_s)" "absente"
assert_eq "T12.8 — sans session : POST /entree -> 410" "$(tape 'echo x\r')" "410"
assert_eq "T12.8 — sans session : POST /taille -> 410" "$(node "$TA" taille "$QP" "$SEC" "$ONG_A" 30 100)" "410"
flux "$WORK/f-exit.bin" 40000; attendre_python; tape "echo VIVANT-8\\r" > /dev/null
assert_eq "T12.8 — témoin : la session est vivante et répond avant le exit" "$(vu "$WORK/f-exit.bin" VIVANT-8 8000)" "TROUVE"
tape "exit 3\\r" > /dev/null; for _ in $(seq 1 80); do grep -q 'FIN-FLUX' "$WORK/f-exit.bin.log" 2>/dev/null && break; sleep 0.1; done
assert_eq "T12.8 — le flux se termine à la fin du shell (FIN-FLUX fin)" "$(grep -c 'FIN-FLUX fin' "$WORK/f-exit.bin.log" || true)" "1"
assert_eq "T12.8 — /etat = {\"session\":\"terminee\",\"code\":3,\"signal\":null}" "$(corps_etat)" '{"session":"terminee","code":3,"signal":null}'
assert_eq "T12.8 — après la fin : POST /entree -> 410" "$(tape 'echo x\r')" "410"
vf_hyg_stop "$FL"

echo "=== T12.1 / T12.6 — une seule session, propriétaire d'onglet ==="
unsrv; srv "$OUT"
assert_eq "T12.1 — B reçoit 409 sur /flux pendant qu'A est attaché, un seul assistant ; témoin : A reçoit sa propre réponse" "$(sonde_unique)" "B=409 assistants=1 A=TROUVE"
assert_eq "T12.6 — B : 409 sur /entree et /taille, son fichier n'est jamais créé ; témoin : A crée le sien" "$(sonde_proprio)" "entree=409 taille=409 fichierB=absent fichierA=existe"

echo "=== T12.2 / T12.3 — grâce : retour avant l'échéance, puis disparition après ==="
unsrv; srv "$OUT"
assert_eq "T12.2 — A revient après 1 s : même shell, /etat vivante, le marqueur tapé avant la fermeture est rejoué" "$(sonde_grace)" "memeshell=oui etat=vivante rejeu=TROUVE"
flux "$WORK/f-g3.bin" 40000; for _ in $(seq 1 30); do [ "$(etat_s)" = vivante ] && break; sleep 0.1; done
AP3="$(python_de)"; SH3="$(shell_de)"
assert_eq "T12.3 — témoin : un assistant et un shell vivent avant la fermeture du flux" "$([ -n "$AP3" ] && [ -n "$SH3" ] && kill -0 "$AP3" 2>/dev/null && kill -0 "$SH3" 2>/dev/null && echo oui || echo "non (assistant=${AP3:-aucun} shell=${SH3:-aucun})")" "oui"
assert_eq "T12.3 — témoin de désignation : shell_de() rend l'enfant qui porte le terminal du pty (tt= : un tty), pas le gardien ; l'autre enfant de l'assistant, le gardien, n'a pas de terminal" "$(designation "$AP3" "$SH3")" "$(printf 'shell=tty\nautres=1 sans-terminal=1')"
vf_hyg_stop "$FL"; sleep 1
assert_eq "T12.3 — témoin : 1 s après la fermeture, la session est détachée mais l'assistant vit encore" "$(etat_s) $(kill -0 "$AP3" 2>/dev/null && echo vivant || echo mort)" "detachee vivant"
sleep $((GRACE_T/1000+1))
assert_eq "T12.3 — grâce + 2 s : assistant et shell disparus (attente bornée), /etat = absente" "$(morts 8 "$AP3" "$SH3" && echo morts || echo "survivants"; etat_s)" "$(printf 'morts\nabsente')"
flux "$WORK/f-g3b.bin" 20000; attendre_python; SH3B="$(shell_de)"
assert_eq "T12.3 — un nouveau flux crée un nouveau shell (PID différent)" "$([ -n "$SH3B" ] && [ "$SH3B" != "$SH3" ] && echo oui || echo "non (ancien=$SH3 nouveau=${SH3B:-aucun})")" "oui"
vf_hyg_stop "$FL"

echo "=== T12.7 — tampon borné à 256 Kio (400 Kio produits pendant qu'A est détaché) ==="
unsrv; GRACE_T=12000; srv "$OUT"
flux "$WORK/f-t7a.bin" 40000; attendre_python; tape "echo PRET-7\\r" > /dev/null; vu "$WORK/f-t7a.bin" PRET-7 8000 > /dev/null
vf_hyg_stop "$FL"
tape "head -c 409600 /dev/zero | tr '\\0' 'x'; echo FIN-PROD''UCTION\\r" > /dev/null; sleep 2
flux "$WORK/f-t7b.bin" 30000; sleep 1; tape "echo APR''ES-7\\r" > /dev/null
T7V="$(vu "$WORK/f-t7b.bin" APRES-7 10000)"; T7N="$(node "$AUX/idx.mjs" "$WORK/f-t7b.bin" APRES-7)"
assert_eq "T12.7 — témoin : la production a eu lieu pendant le détachement et le rejeu atteint le plafond (≥ 262144 octets)" "$T7V $([ "$T7N" -ge 262144 ] && echo plein || echo "court:$T7N")" "TROUVE plein"
assert_eq "T12.7 — le rejeu ne dépasse pas 262144 octets + 4096" "$([ "$T7N" -le 266240 ] && echo borne || echo "trop long:$T7N")" "borne"
assert_eq "T12.7 — la fin de la production est présente dans le rejeu" "$(vu "$WORK/f-t7b.bin" FIN-PRODUCTION 2000)" "TROUVE"
vf_hyg_stop "$FL"; unsrv; GRACE_T=3000

echo "=== T15 — rien sur disque, rien dans le journal, le SSE, l'export ; tampon vidé à la fin ==="
srv "$OUT"
assert_eq "T15.1 — témoin : les deux marqueurs sont dans le flux du client ; export 200 ; SSE 200 ; aucun fichier ne les porte" "$(sonde_confid)" "temoin=oui export=200 sse=STATUT 200 fuites=0"
unsrv; srv "$OUT"
assert_eq "T15.2 — après exit, une nouvelle session fonctionne et ne rejoue rien de l'ancienne" "$(sonde_tampon)" "ancien=vu nouvelle=OK rejeu=aucun"
unsrv

echo "=== Sp2 — grâce par défaut, lue sans override d'environnement ==="
grace_lue() { # grace_lue <sortie> [valeur de VF_COCKPIT_TERM_GRACE_MS] : GRACE_MS que le module de la sortie calcule
  if [ $# -ge 2 ]; then VF_COCKPIT_TERM_GRACE_MS="$2" node --input-type=module -e "import { pathToFileURL } from 'node:url'; const m = await import(pathToFileURL(process.argv[1] + '/vf-cockpit-terminal-session.mjs').href); console.log(m.GRACE_MS);" "$(mod_de "$1")/scripts"
  else env -u VF_COCKPIT_TERM_GRACE_MS node --input-type=module -e "import { pathToFileURL } from 'node:url'; const m = await import(pathToFileURL(process.argv[1] + '/vf-cockpit-terminal-session.mjs').href); console.log(m.GRACE_MS);" "$(mod_de "$1")/scripts"; fi
}
assert_eq "Sp2.1 — sans override, la grâce par défaut vaut 30000 ms (P71-D-19)" "$(grace_lue "$OUT")" "30000"
assert_eq "Sp2.2 — témoin : un réglage de test valide (250) est pris en compte ; hors plage (50, 40000) ou illisible (abc) : retour au défaut 30000" "$(grace_lue "$OUT" 250) $(grace_lue "$OUT" 50) $(grace_lue "$OUT" 40000) $(grace_lue "$OUT" abc)" "250 30000 30000 30000"

echo "=== S4 — expiration de la grâce : jamais deux sessions en même temps ==="
assistants_vivants() { local p n=0; for p in $(pgrep -P "$SRV_PID"); do case "$(ps -o stat= -p "$p" 2>/dev/null)" in Z*|"") ;; *) n=$((n+1)) ;; esac; done; echo "$n"; } # enfants du serveur vivants : un zombie pas encore réapé n'est pas un shell
sonde_expiration() { # shell obstiné (l'ancien assistant met jusqu'à 3 s à mourir) ; rend « max=<assistants simultanés> ancien=<mort|vivant> nouveau=<oui|non> »
  local f="$WORK/f-exp-$SRVN.bin" ap1 st max=0 n t0=$SECONDS nouveau=non anc=vivant
  flux "$f" 40000; attendre_python; ap1="$(python_de)"
  vf_hyg_stop "$FL"; sleep 1   # la grâce (300 ms) est écoulée : l'ancien assistant est en train de mourir
  while [ $((SECONDS-t0)) -lt 14 ]; do
    st="$(rq "$QP" GET /flux --secret "$SEC" --onglet "$ONG_A" --echeance 700 | sed -n 1p)"   # un client qui retente : 503 tant que l'ancienne vit, puis 200 (le flux reste ouvert : ETIMEDOUT)
    n="$(assistants_vivants)"; [ "$n" -gt "$max" ] && max=$n
    [ "$st" != 503 ] && break
    sleep 0.3
  done
  for _ in 1 2 3 4 5; do n="$(assistants_vivants)"; [ "$n" -gt "$max" ] && max=$n; sleep 0.2; done
  morts 8 "$ap1" && anc=mort
  n="$(python_de)"; [ -n "$n" ] && [ "$n" != "$ap1" ] && nouveau=oui
  echo "max=$max ancien=$anc nouveau=$nouveau"
}
SHELL_SAVE="$SHELL"; export SHELL="$WORK/bin/shell-test-tetu"; GRACE_T=300; srv "$OUT"
assert_eq "S4.1 — grâce écoulée, l'ancien assistant met 3 s à mourir : jamais plus d'un assistant, puis l'ancien est mort et une nouvelle session tourne (témoin : le shell obstiné a bien tenu l'ancien en vie, max vaut 1 et non 0)" "$(sonde_expiration)" "max=1 ancien=mort nouveau=oui"
unsrv; export SHELL="$SHELL_SAVE"; GRACE_T=3000

echo "=== T15.3 — le tampon est vidé à la fin de la grâce ==="
flux_repris() { # flux_repris <fichier> <ms> : un client qui retente tant que le serveur répond 503 (ancienne session en cours de fermeture)
  local i; for i in $(seq 1 40); do flux "$1" "$2"; sleep 0.4; grep -q 'statut 503' "$1.log" 2>/dev/null || return 0; vf_hyg_stop "$FL"; rm -f "$1" "$1.log"; sleep 0.3; done
}
sonde_tampon_grace() { # un marqueur dans la session, flux fermé, grâce écoulée, nouvelle attache ; rend « ancien=<vu|non> nouvelle=<OK|non> rejeu=<aucun|present@n> »
  local f1="$WORK/f-tg1-$SRVN.bin" f2="$WORK/f-tg2-$SRVN.bin" m="MARQUEUR-GRACE-$RANDOM" a ap ok rj
  flux "$f1" 40000; attendre_python; ap="$(python_de)"; tape "echo $m\\r" > /dev/null; a="$(vu "$f1" "$m" 8000)"
  vf_hyg_stop "$FL"; morts 12 "$ap" || true
  flux_repris "$f2" 20000; attendre_python; tape "echo NOUVEAU-OK\\r" > /dev/null; ok="$(vu "$f2" NOUVEAU-OK 8000)"
  rj="$(node "$AUX/idx.mjs" "$f2" MARQUEUR-GRACE)"
  vf_hyg_stop "$FL"; echo "ancien=$([ "$a" = TROUVE ] && echo vu || echo non) nouvelle=$([ "$ok" = TROUVE ] && echo OK || echo non) rejeu=$([ "$rj" = -1 ] && echo aucun || echo "present@$rj")"
}
GRACE_T=300; srv "$OUT"
assert_eq "T15.3 — grâce écoulée puis nouvelle attache : le tampon de l'ancienne session n'est pas rejoué (témoin : le marqueur a été vu dans l'ancien flux, la nouvelle session répond)" "$(sonde_tampon_grace)" "ancien=vu nouvelle=OK rejeu=aucun"
unsrv; GRACE_T=3000

echo "=== N5 — fermeture bornée : un assistant qui n'obéit pas reçoit SIGTERM puis SIGKILL, la place est rendue ==="
ENG_TETU="$WORK/eng-tetu"; rm -rf "$ENG_TETU"; cp -R "$ENG" "$ENG_TETU"
printf 'import signal, time\nsignal.signal(signal.SIGTERM, signal.SIG_IGN)\ntime.sleep(300)\n' > "$ENG_TETU/terminal/vf-cockpit-pty.py"
sonde_escalade() { # assistant factice qui ignore SIGTERM, flux fermé, grâce puis fermeture ; rend « ancien=<mort|vivant> nouvelle=<autre assistant|non> » (la fermeture est réglée à 1 s)
  local f1="$WORK/f-esc1-$SRVN.bin" f2="$WORK/f-esc2-$SRVN.bin" ap np="" ancien nouvelle=non p
  flux "$f1" 40000; attendre_python; ap="$(python_de)"; vf_hyg_stop "$FL"
  morts 8 "$ap" && ancien=mort || ancien=vivant
  if [ "$ancien" = mort ]; then
    flux_repris "$f2" 20000; attendre_python; np="$(python_de)"; [ -n "$np" ] && [ "$np" != "$ap" ] && nouvelle="autre assistant"; vf_hyg_stop "$FL"
  fi
  for p in $ap $np; do case "$(ps -o args= -p "$p" 2>/dev/null)" in *vf-cockpit-pty.py*) kill -KILL "$p" 2>/dev/null ;; esac; done # assistants factices (survivants) : arrêtés par PID, ligne de commande relue
  echo "ancien=$ancien nouvelle=$nouvelle"
}
ENG_SRV="$ENG_TETU"; GRACE_T=300; FERM_T=1000; srv "$OUT"
assert_eq "N5.1 — assistant qui ignore SIGTERM : SIGKILL au-delà de la borne de fermeture, l'ancien est mort en moins de 8 s et la place est rendue (un nouvel assistant démarre)" "$(sonde_escalade)" "ancien=mort nouvelle=autre assistant"
unsrv; ENG_SRV=""; GRACE_T=3000; FERM_T=""

echo "=== CP — contre-pression sur la réponse : un lecteur à l'arrêt bloque la production du shell, sans perte ==="
sonde_contrepression() { # sonde_contrepression <fenetre-s> : un lecteur qui ne lit pas pendant <fenetre-s> + 1,5 s ; le shell produit 40 Mo puis crée un drapeau ; rend « pendant=<absent|present> apres=<present|absent> »
  # Le code sain ne peut pas finir tant que le lecteur ne lit pas : une fenêtre courte suffit à l'absence. Un mutant sans contre-pression finit à la vitesse de la machine :
  # la fenêtre du mutant est large (la sortie dès que le drapeau paraît, lecteur toujours à l'arrêt), donc sa détection ne dépend pas de la charge.
  local fen="${1:-8}" fl="$WORK/cp-drapeau-$SRVN" out="$WORK/cp-octets-$SRVN" pend=absent apres=absent i
  rm -f "$fl" "$out"; node "$AUX/lent.mjs" "$QP" "$SEC" "$ONG_A" $((fen*1000+1500)) "$out" > /dev/null 2>&1 & local lp=$!; PIDS+=($lp)
  attendre_python; tape "head -c 40000000 /dev/zero | tr '\\0' 'x'; touch $fl\\r" > /dev/null
  for i in $(seq 1 $((fen*5))); do [ -e "$fl" ] && break; sleep 0.2; done; [ -e "$fl" ] && pend=present
  if [ "$pend" = absent ]; then for i in $(seq 1 300); do [ -e "$fl" ] && break; sleep 0.2; done; [ -e "$fl" ] && apres=present; else apres=present; fi
  vf_hyg_stop "$lp"; echo "pendant=$pend apres=$apres"
}
srv "$OUT"
assert_eq "CP.1 — lecteur à l'arrêt : la commande qui produit 40 Mo n'a pas fini 8 s après (backpressure) ; le lecteur reprend, elle finit (rien n'est perdu ni abandonné)" "$(sonde_contrepression 8)" "pendant=absent apres=present"
unsrv

echo "=== mutants ==="
GRACE_T=3000
if mutant grace0 vf-cockpit-terminal-session.mjs "s/^export const GRACE_MS = .*/export const GRACE_MS = 0;/"; then
  srv "$MUT_OUT"
  R="$(sonde_grace)"; assert_eq "M-GRACE0 — le mutant rougit T12.2 (grâce nulle : le shell et le tampon ne survivent pas)" "$([ "$R" != "memeshell=oui etat=vivante rejeu=TROUVE" ] && echo rouge || echo "identique : $R")" "rouge"; unsrv
else assert_eq "M-GRACE0 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant unique vf-cockpit-terminal-session.mjs "s/if (s && s.etat !== .terminee. && s.onglet !== onglet) return 409;/if (s) s.onglet = onglet;/"; then
  srv "$MUT_OUT"; R="$(sonde_unique)"; assert_eq "M-UNIQUE — le mutant rougit T12.1 (un autre onglet remplace le propriétaire)" "$([ "$R" != "B=409 assistants=1 A=TROUVE" ] && echo rouge || echo "identique : $R")" "rouge"; unsrv
else assert_eq "M-UNIQUE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant proprio vf-cockpit-terminal-session.mjs "/ecrire(octets, onglet)/,/stdin.write/s/if (s.onglet !== onglet) return 409;//"; then
  srv "$MUT_OUT"; R="$(sonde_proprio)"; assert_eq "M-PROPRIO — le mutant rougit T12.6 (le fichier de B est créé)" "$([ "$R" != "entree=409 taille=409 fichierB=absent fichierA=existe" ] && echo rouge || echo "identique : $R")" "rouge"; unsrv
else assert_eq "M-PROPRIO — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant tampon vf-cockpit-terminal-session.mjs "s/^  const vider = .*/  const vider = () => {};/"; then
  srv "$MUT_OUT"; R="$(sonde_tampon)"; assert_eq "M-TAMPON — le mutant rougit T15.2 (le tampon de l'ancienne session est rejoué)" "$([ "$R" != "ancien=vu nouvelle=OK rejeu=aucun" ] && echo rouge || echo "identique : $R")" "rouge"; unsrv
else assert_eq "M-TAMPON — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant journal vf-cockpit-terminal-session.mjs "s/enfant\.stdout\.on(.data., (b) => {/& console.error(b.toString(\"latin1\"));/"; then
  srv "$MUT_OUT"; R="$(sonde_confid)"; assert_eq "M-JOURNAL — le mutant rougit T15.1 (la sortie du shell est journalisée)" "$([ "$R" != "temoin=oui export=200 sse=STATUT 200 fuites=0" ] && echo rouge || echo "identique : $R")" "rouge"; unsrv
else assert_eq "M-JOURNAL — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

if mutant gracedef vf-cockpit-terminal-session.mjs "s/? n : 30000;/? n : 15000;/"; then
  assert_eq "M-GRACE-DEFAUT — le mutant (défaut 15000) rougit Sp2.1 : la valeur réelle du défaut est lue" "$(grace_lue "$MUT_OUT")" "15000"
else assert_eq "M-GRACE-DEFAUT — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant expiration vf-cockpit-terminal-session.mjs "s/cible.etat = 'fermeture'; vider();/s = null; vider(); cible.etat = 'terminee';/"; then
  export SHELL="$WORK/bin/shell-test-tetu"; GRACE_T=300; srv "$MUT_OUT"
  R="$(sonde_expiration)"; assert_eq "M-EXPIRATION — le mutant (la session est libérée avant la mort de l'assistant) rougit S4.1 : deux assistants coexistent" "$([ "$R" != "max=1 ancien=mort nouveau=oui" ] && echo rouge || echo "identique : $R")" "rouge"; unsrv
  export SHELL="$SHELL_SAVE"; GRACE_T=3000
else assert_eq "M-EXPIRATION — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant tamponGrace vf-cockpit-terminal-session.mjs "s/ vider();/ ;/g"; then
  GRACE_T=300; srv "$MUT_OUT"
  R="$(sonde_tampon_grace)"; assert_eq "M-TAMPON-GRACE — le mutant (aucun vidage, ni à l'expiration ni à la fin) rougit T15.3 : le tampon de l'ancienne session est rejoué" "$([ "$R" != "ancien=vu nouvelle=OK rejeu=aucun" ] && echo rouge || echo "identique : $R")" "rouge"; unsrv
  GRACE_T=3000
else assert_eq "M-TAMPON-GRACE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant contrepression vf-cockpit-terminal-session.mjs "s/if (!r.write(b) \&\& !cible.pause) {/if (!r.write(b) \&\& false) {/"; then
  srv "$MUT_OUT"
  R="$(sonde_contrepression 90)"; assert_eq "M-CONTREPRESSION — le mutant (la sortie du shell n'est plus suspendue quand le client ne lit pas) rougit CP.1 : la production se termine malgré le lecteur à l'arrêt" "$([ "$R" != "pendant=absent apres=present" ] && echo rouge || echo "identique : $R")" "rouge"; unsrv
else assert_eq "M-CONTREPRESSION — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

if mutant sanskill vf-cockpit-terminal-session.mjs "s/try { cible.enfant.kill('SIGKILL'); } catch {}//"; then
  ENG_SRV="$ENG_TETU"; GRACE_T=300; FERM_T=1000; srv "$MUT_OUT"
  R="$(sonde_escalade)"; assert_eq "M-SANS-SIGKILL — le mutant (aucune escalade SIGKILL) rougit N5.1 : l'assistant qui ignore SIGTERM survit à la borne de fermeture" "$([ "$R" != "ancien=mort nouvelle=autre assistant" ] && echo rouge || echo "identique : $R")" "rouge"; unsrv
  ENG_SRV=""; GRACE_T=3000; FERM_T=""
else assert_eq "M-SANS-SIGKILL — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

echo "=== T12.5 — inactivité : un terminal ouvert empêche l'arrêt (attente bornée jusqu'à 65 s après le lancement) ==="
while [ $((SECONDS-IDLE_T0)) -lt 65 ]; do sleep 1; done
assert_eq "T12.5 — témoin : le terminal de la sonde était bien ouvert (un assistant enfant du serveur)" "$IDLE_ATTACHE" "oui"
assert_eq "T12.5 — --idle-exit 0.01, session attachée, aucun onglet P : le serveur est vivant après 65 s" "$(kill -0 "$IC_PID" 2>/dev/null && echo vivant || echo sorti)" "vivant"
if [ -n "$IDLE_M" ]; then assert_eq "M-IDLE — le mutant rougit T12.5 : le même serveur, sans occupe(), est sorti" "$(kill -0 "$IM_PID" 2>/dev/null && echo vivant || echo sorti)" "sorti"
else assert_eq "M-IDLE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
vf_hyg_stop "$IC_PID"; [ -n "$IDLE_M" ] && vf_hyg_stop "$IM_PID"

echo "=== W1 — le terminal dans son processus (P71-D-33, D-34, D-35) ==="
# processus du terminal = l'enfant du serveur dont la ligne de commande porte vf-cockpit-terminal-processus.mjs
proc_q() { local c; for c in $(command pgrep -P "$1" 2>/dev/null); do ps -o command= -p "$c" 2>/dev/null | grep -q 'vf-cockpit-terminal-processus.mjs' && { echo "$c"; return; }; done; }
vivant_w() { kill -0 "$1" 2>/dev/null && echo oui || echo non; }
# E1 : la boucle du serveur est GELÉE (SIGSTOP : plus forte que 4 s de travail synchrone) pendant trois aller-retours de frappe ; Q, dans son processus, répond
sonde_gel() { # -> « <n> échos sur 3 pendant le gel, serveur gelé=<oui|non> »
  local f="$WORK/f-gel-$SRVN.bin" n=0 i m
  flux "$f" 40000; attendre_python; tape "echo PRET-GEL\\r" > /dev/null; vu "$f" PRET-GEL 8000 > /dev/null
  kill -STOP "$SRV_PID"
  for i in 1 2 3; do m="GEL-$i-$RANDOM"; tape "echo $m\\r" > /dev/null; [ "$(vu "$f" "$m" 1500)" = TROUVE ] && n=$((n+1)); done
  local g; g="$(ps -o stat= -p "$SRV_PID" 2>/dev/null | cut -c1)"; kill -CONT "$SRV_PID"; vf_hyg_stop "$FL"
  echo "$n échos sur 3 pendant le gel, serveur gelé=$([ "$g" = T ] && echo oui || echo non)"
}
srv "$OUT"; R="$(sonde_gel)"; assert_eq "E1.1 — serveur gelé (SIGSTOP), trois frappes : les trois échos reviennent en moins de 1,5 s chacun (rouge avec Q dans le processus du serveur : aucun écho)" "$R" "3 échos sur 3 pendant le gel, serveur gelé=oui"; unsrv
# E1 : la mort du parent par SIGKILL n'laisse ni processus du terminal, ni assistant, ni shell
srv "$OUT"; f="$WORK/f-mort.bin"; flux "$f" 40000; attendre_python; QPID="$(proc_q "$SRV_PID")"; APID="$(command pgrep -P "$QPID" | sed -n 1p)"; SPID="$(shell_sous "$APID")"
assert_eq "E1.2 — témoin : avant la mort du parent, le processus du terminal, l'assistant et le shell vivent" "$(vivant_w "${QPID:-0}") $(vivant_w "${APID:-0}") $(vivant_w "${SPID:-0}")" "oui oui oui"
kill -KILL "$SRV_PID"; wait "$SRV_PID" 2>/dev/null; morts 8 "$QPID" "$APID" "$SPID"; vf_hyg_stop "$FL"
assert_eq "E1.3 — serveur tué par SIGKILL : ni processus du terminal, ni assistant, ni shell ne survivent (PID enregistrés)" "$(vivant_w "${QPID:-0}") $(vivant_w "${APID:-0}") $(vivant_w "${SPID:-0}")" "non non non"
vf_hyg_stop "$SRV_PID"
# E1 : le terminal ouvert est annoncé au parent (garde d'inactivité) : couvert par T12.5 ci-dessus
# G2 : arrêt volontaire (SIGTERM du serveur) -> GET /etat rend {"etat":"arret"} pendant plus d'une seconde, flux fermés, puis Q sort
srv "$OUT"; f="$WORK/f-arret.bin"; flux "$f" 40000; attendre_python; QPID="$(proc_q "$SRV_PID")"; APID="$(command pgrep -P "$QPID" | sed -n 1p)"
cat > "$AUX/sonde-arret.mjs" <<'JS'
// sonde-arret.mjs <portQ> <secret> <duree-ms> : interroge GET /etat toutes les 50 ms dans UN processus démarré avant le signal ; rend « <premier> <dernier> », époques en ms de la réponse {"etat":"arret"} (0 0 si jamais vue)
import http from 'node:http';
const [, , port, secret, duree] = process.argv; let premier = 0, dernier = 0;
const un = () => { const r = http.get({ host: '127.0.0.1', port: +port, path: '/etat', agent: false, headers: { Host: `127.0.0.1:${port}`, Origin: `http://127.0.0.1:${port}`, 'X-VF-Terminal': secret } }, (res) => {
  let b = ''; res.on('data', (c) => { b += c; }); res.on('end', () => { if (b === '{"etat":"arret"}') { dernier = Date.now(); if (!premier) premier = dernier; } });
}); r.on('error', () => {}); r.setTimeout(500, () => r.destroy()); };
const iv = setInterval(un, 50);
setTimeout(() => { clearInterval(iv); console.log(`${premier} ${dernier}`); process.exit(0); }, +duree);
JS
node "$AUX/sonde-arret.mjs" "$QP" "$SEC" 6000 > "$WORK/arret.res" & AP=$!; PIDS+=($AP); sleep 0.5
T0="$(python3 -c "import time;print(int(time.time()*1000))")"; kill -TERM "$SRV_PID"; wait "$SRV_PID" 2>/dev/null; wait "$AP" 2>/dev/null
read -r A1 A2 < "$WORK/arret.res"
assert_eq "G2.1 — SIGTERM du serveur : /etat rend {\"etat\":\"arret\"} puis, jusqu'à au moins 1 s après le signal, la même réponse" "$([ "${A1:-0}" -gt 0 ] && echo vu || echo jamais) $([ $((${A2:-0}-T0)) -ge 1000 ] && echo ">=1s" || echo "<1s ($((${A2:-0}-T0)) ms)")" "vu >=1s"
morts 8 "$QPID" "$APID"; vf_hyg_stop "$FL"
assert_eq "G2.2 — puis Q sort : le processus du terminal et l'assistant ont disparu, /etat ne répond plus" "$(vivant_w "${QPID:-0}") $(vivant_w "${APID:-0}") $(node "$TA" etat "$QP" "$SEC" | sed -n 1p | cut -c1-6)" "non non ERREUR"
assert_eq "G2.3 — le flux ouvert a été fermé par Q (le client voit la fin)" "$(grep -c 'FIN-FLUX' "$f.log")" "1"
# SIGKILL : comportement inchangé, aucun état « arret » annoncé, Q disparaît avec son parent
srv "$OUT"; QPID="$(proc_q "$SRV_PID")"; kill -KILL "$SRV_PID"; wait "$SRV_PID" 2>/dev/null; morts 4 "$QPID"
assert_eq "G2.4 — SIGKILL du serveur : Q n'annonce pas « arret » et sort aussitôt" "$(vivant_w "${QPID:-0}") $(node "$TA" etat "$QP" "$SEC" | sed -n 1p | cut -c1-6)" "non ERREUR"
vf_hyg_stop "$SRV_PID"
# E4 : python3 introuvable
mkdir -p "$WORK/pathnopy"; ln -sf "$(command -v node)" "$WORK/pathnopy/node"
PATH_SRV="$WORK/pathnopy"; srv "$OUT"; PATH_SRV=""
assert_eq "E4.1 — PATH sans python3 : GET /etat rend {\"etat\":\"indisponible\",\"raison\":\"python3-absent\"}" "$(node "$TA" etat "$QP" "$SEC" | sed -n 3p)" '{"etat":"indisponible","raison":"python3-absent"}'
assert_eq "E4.2 — l'échec est journalisé UNE fois (« python3 introuvable »)" "$(grep -c 'python3 introuvable : le terminal est indisponible' "$SRV_OUT")" "1"
assert_eq "E4.3 — GET /flux rend 503, pas un 500 muet ni un flux" "$(rq "$QP" GET /flux --secret "$SEC" --onglet "$ONG_A" --echeance 2000 | sed -n 1p)" "503"
unsrv
srv "$OUT"; assert_eq "E4.4 — témoin : avec python3 dans le PATH, /etat rend l'état de session (pas « indisponible »)" "$(node "$TA" etat "$QP" "$SEC" | sed -n 3p | node "$AUX/ev.mjs" 'j.etat===undefined&&j.session!==undefined?"session":"autre"')" "session"; unsrv

# R3 (P71-D-36) : python3 disparaît EN COURS de session ; la relance d'un shell le revérifie comme le premier démarrage
mkdir -p "$WORK/pathdisp"; ln -sf "$(command -v node)" "$WORK/pathdisp/node"
sonde_disparu() { # une session vivante, python3 retiré du PATH résolu, « exit », relance ; rend « avant=<s> apres-exit=<s> relance=<statut> etat=<etat|session> journal=<n> »
  ln -sf "$(command -v python3)" "$WORK/pathdisp/python3"; PATH_SRV="$WORK/pathdisp"; srv "$1"; PATH_SRV=""
  local f="$WORK/f-disp-$SRVN.bin" av ap re et
  flux "$f" 20000; attendre_python; tape "echo VIVANT''OK\\r" > /dev/null; vu "$f" VIVANTOK 8000 > /dev/null
  av="$(etat_s)"; rm -f "$WORK/pathdisp/python3"; tape "exit\\r" > /dev/null
  for _ in $(seq 1 60); do [ "$(etat_s)" = terminee ] && break; sleep 0.2; done; ap="$(etat_s)"; vf_hyg_stop "$FL"
  re="$(rq "$QP" GET /flux --secret "$SEC" --onglet "$ONG_A" --echeance 2000 | sed -n 1p)"
  et="$(corps_etat | node "$AUX/ev.mjs" 'j.etat||j.session' 2>/dev/null)"
  RES_R3="avant=$av apres-exit=$ap relance=$re etat=$et journal=$(grep -c 'python3 introuvable' "$SRV_OUT" || true)" # global : jamais dans un sous-shell (le serveur et le flux lancés doivent rester arrêtables)
}
sonde_disparu "$OUT"; R3="$RES_R3"; unsrv
assert_eq "R3.1 — python3 disparu en cours de session : la session vivait, « exit » la termine, la relance rend 503 et /etat dit « indisponible » (jamais « absente » : pas de boucle « session fermée »), une ligne de journal" "$R3" "avant=vivante apres-exit=terminee relance=503 etat=indisponible journal=1"
srv "$OUT"; ln -sf "$(command -v python3)" "$WORK/pathdisp/python3"
flux "$WORK/f-disp-t.bin" 4000; attendre_python && R32=lance || R32=non
assert_eq "R3.2 — témoin : avec python3 présent, un flux démarre une session (pas de 503)" "$R32" "lance"; vf_hyg_stop "$FL"; unsrv; rm -f "$WORK/pathdisp/python3"
if mutant disparu vf-cockpit-terminal-processus.mjs "s/const pythonAbsent = () => { const a = !resoudrePython3(envOrigine.PATH);/const a0 = !resoudrePython3(envOrigine.PATH); const pythonAbsent = () => { const a = a0;/"; then
  sonde_disparu "$MUT_OUT"; R3M="$RES_R3"; unsrv
  assert_eq "M-PYTHON-FIGE — le mutant (python3 vérifié une seule fois, au démarrage) rougit R3.1 : la relance ne dit plus « indisponible »" "$([[ "$R3M" == *"etat=indisponible"* ]] && echo identique || echo rouge)" "rouge"
else assert_eq "M-PYTHON-FIGE — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

# mutants W1 : copies du module
if mutant parentmort vf-cockpit-terminal-processus.mjs "s/process.on('disconnect', () => { if (phase !== 'arret') sortir(); });//; s/if (process.ppid !== ppid0 \&\& phase !== 'arret') sortir();//"; then
  srv "$MUT_OUT"; f="$WORK/f-mpm.bin"; flux "$f" 40000; attendre_python; QPID="$(proc_q "$SRV_PID")"; APID="$(command pgrep -P "$QPID" | sed -n 1p)"
  kill -KILL "$SRV_PID"; wait "$SRV_PID" 2>/dev/null; morts 4 "$QPID"; MPM="$(vivant_w "${QPID:-0}")"; vf_hyg_stop "$FL"; [ -n "$QPID" ] && kill -KILL "$QPID" 2>/dev/null; [ -n "$APID" ] && kill -KILL "$APID" 2>/dev/null
  assert_eq "M-PARENT-MORT — le mutant (l'enfant ignore la mort du parent) rougit E1.3 : le processus du terminal survit au SIGKILL" "$MPM" "oui"; vf_hyg_stop "$SRV_PID"
else assert_eq "M-PARENT-MORT — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant sansarret vf-cockpit-terminal-processus.mjs "s/if (phase === 'arret') return json(res, 200, { etat: 'arret' });//"; then
  srv "$MUT_OUT"; f="$WORK/f-msa.bin"; flux "$f" 40000; attendre_python; node "$AUX/sonde-arret.mjs" "$QP" "$SEC" 3000 > "$WORK/arret-m.res" & AP=$!; PIDS+=($AP); sleep 0.5; kill -TERM "$SRV_PID"; wait "$SRV_PID" 2>/dev/null; wait "$AP" 2>/dev/null; read -r B1 B2 < "$WORK/arret-m.res"
  assert_eq "M-SANS-ARRET — le mutant (pas d'état « arret ») rougit G2.1 : {\"etat\":\"arret\"} n'est jamais vu" "${B1:-x}" "0"; vf_hyg_stop "$FL"; vf_hyg_stop "$SRV_PID"
else assert_eq "M-SANS-ARRET — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi
if mutant sanspython vf-cockpit-terminal-processus.mjs "s/if (!sessions.occupe() \&\& pythonAbsent() \&\& (refusPython || sessions.etat().session === 'absente')) {.*$//"; then
  PATH_SRV="$WORK/pathnopy"; srv "$MUT_OUT"; PATH_SRV=""
  assert_eq "M-SANS-INDISPO — le mutant rougit E4.1 : /etat ne rend plus « indisponible »" "$(node "$TA" etat "$QP" "$SEC" | sed -n 3p | node "$AUX/ev.mjs" 'j.etat||"sans-etat"')" "sans-etat"; unsrv
else assert_eq "M-SANS-INDISPO — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; fi

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
