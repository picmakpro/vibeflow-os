#!/usr/bin/env bash
# test-cockpit-terminal-pty.sh — assistant PTY et environnement du shell du terminal intégré (TERM-06, TERM-07, TERM-08 orphelins,
# TERM-09 automatisé ; P71-D-03, D-04, D-06, D-14, D-22 puis D-23).
#   T10  environnement filtré (liste noire), shell `-l` lancé dans realpath(lab), TERM/COLORTERM posés, choix du shell, NODE_OPTIONS jamais posé
#   T11  assistant lancé en `python3 -I`, taille par le canal de contrôle (`stty size`), Ctrl-C au premier plan, état `FIN <code>` sur fd 2
#   T12  serveur tué par SIGKILL : assistant, shell et travail d'arrière-plan disparaissent en moins de 5 s ; T12.5 : toute la SESSION, nohup et disown compris
#        (setsid : limite assumée, assertion qui la documente) et un leurre hors session intact
#   T13  programme plein écran témoin, par le flux direct : écran alterné, 256 couleurs, truecolor, SIGWINCH, SIGINT
#   T12.6 chaque branche d'arrêt (sortie du shell, SIGTERM, fin du fd 0) tue la session nohup comprise ; T12.7 relevé : vide = impossible, zombie = mort, chef réapé jamais visé
#   T11.9 le shell n'hérite pas du descripteur 3 (canal de contrôle)     S3  entrée en attente côté serveur bornée : au-delà, 429 explicite
#   T15  python3 du lab jamais exécuté (PATH à élément relatif ou vide), PATH du shell intact
#   M-*  mutants (copies du module par cockpit_module_muter, ou du moteur pour l'assistant ; la sortie ne porte que des données) : M-INHERIT, M-ATTENTE-NON-BORNEE, M-ENVLARGE, M-CWD, M-SI-ABSENT, M-SANS-I, M-SANS-L, M-SIGINT, M-CTRLC, M-RESIZE, M-NOEOF, M-GROUPES-FIGES, M-PYTHON3-CWD, M-SORTIE-SANS-KILL, M-ARRET-SANS-KILL, M-RELEVE-VIDE, M-ZOMBIE, M-ETAT-PROC, M-CHEF-REAPE
# Les attentes cherchent des sous-chaînes (le noyau double les fins de ligne, l'écho ^C précède la sortie). Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$(cd "$SCRIPTS/../skills/cockpit-moteur" && pwd -P)"; TA="$HERE_T/terminal-aux.mjs"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXX")"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/bin" "$WORK/run" "$WORK/temoins" "$WORK/ailleurs"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
. "$(dirname "$0")/socle-serveur.sh"
# P71-D-33 : Q tourne dans un processus enfant du serveur ; « les enfants du serveur » = les assistants, enfants de ce processus (pgrep -P ne voit qu'un étage)
pgrep() { if [ "$1" = "-P" ] && [ $# -eq 2 ]; then local c; for c in $(command pgrep -P "$2"); do if ps -o command= -p "$c" 2>/dev/null | grep -q 'vf-cockpit-terminal-processus.mjs'; then command pgrep -P "$c"; else echo "$c"; fi; done; else command pgrep "$@"; fi; }
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
cp "$HERE_T/temoins/plein-ecran.py" "$WORK/temoins/plein-ecran.py"

cat > "$AUX/ev.mjs" <<'JS'
import fs from 'node:fs'; const j = JSON.parse(fs.readFileSync(0, 'utf8')); const v = new Function('j', 'return (' + process.argv[2] + ')')(j); console.log(typeof v === 'string' ? v : JSON.stringify(v));
JS
cat > "$AUX/aide.mjs" <<'JS'
// aide.mjs : cnt <fichier> <sous-chaine> · attendre-n <fichier> <sous-chaine> <n> <ms> · ordre <fichier> <a> <b> (a avant b) · lignes-non-commentees <nom> <fichier>...
import fs from 'node:fs';
const [, , cmd, ...a] = process.argv; const lire = (f) => { try { return fs.readFileSync(f).toString('latin1'); } catch { return ''; } };
const n = (t, s) => (s ? t.split(s).length - 1 : 0);
if (cmd === 'cnt') console.log(n(lire(a[0]), a[1]));
else if (cmd === 'ordre') { const t = lire(a[0]); const i = t.indexOf(a[1]), j = t.indexOf(a[2]); console.log(i >= 0 && j > i ? 'ok' : `non (a=${i} b=${j})`); }
else if (cmd === 'attendre-n') { const fin = Date.now() + Number(a[3]); for (;;) { if (n(lire(a[0]), a[1]) >= Number(a[2])) { console.log('TROUVE'); break; } if (Date.now() >= fin) { console.log('ABSENT'); break; } await new Promise((r) => setTimeout(r, 50)); } }
else if (cmd === 'lignes-non-commentees') console.log(a.slice(1).reduce((s, f) => s + lire(f).split('\n').filter((l) => l.includes(a[0]) && !/^\s*\/\//.test(l)).length, 0));
JS
cat > "$AUX/unit.mjs" <<'JS'
// unit.mjs <sortie> <cas> : cas de envShell et de choisirShell importés du module que commande la sortie (79-06 : la sortie ne porte plus de code ; table MODS_TABLE : sortie TAB module ; défaut MOD_DEPOT)
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , sortie, cas, ...a] = process.argv;
let racine = process.env.MOD_DEPOT; try { for (const l of fs.readFileSync(process.env.MODS_TABLE, 'utf8').split('\n')) { const [s, r] = l.split('\t'); if (s === sortie && r) racine = r; } } catch {}
const m = await import(pathToFileURL(racine + '/scripts/vf-cockpit-terminal-env.mjs').href);
if (cas === 'filtre') {
  const S = '0123456789abcdef0123';
  const r = m.envShell({ CLAUDECODE: '1', CLAUDE_CODE_X: '1', VF_COCKPIT_Y: '1', CLAUDE_AUTRE: 'z', AUTRE: 'ok', NODE_OPTIONS: '--no-warnings', COURT: 'xcourtx', FUITE: 'a' + S + 'b' }, [S, 'court', '']);
  console.log(Object.keys(r).filter((k) => k !== 'TERM' && k !== 'COLORTERM').sort().join(','));
} else if (cas === 'term') {
  const c = (e) => { const r = m.envShell(e, []); return `${r.TERM}|${r.COLORTERM}`; };
  console.log([c({ TERM: 'vt100' }), c({ TERM: 'dumb', COLORTERM: '24bit' }), c({}), c({ COLORTERM: '24bit' })].join(' '));
} else if (cas === 'shell') {
  const [pasExec, dossier, bon] = a;
  const bien = (p) => { try { return path.isAbsolute(p) && fs.statSync(p).isFile() && (fs.accessSync(p, fs.constants.X_OK), true); } catch { return false; } };
  const repli = (env) => { const s = m.choisirShell(env); return bien(s) && s !== env.SHELL ? 'oui' : 'non:' + s; };
  console.log(`relatif=${repli({ SHELL: 'sh' })} sans-x=${repli({ SHELL: pasExec })} dossier=${repli({ SHELL: dossier })} absent=${bien(m.choisirShell({})) ? 'oui' : 'non'} valide=${m.choisirShell({ SHELL: bon }) === bon ? 'oui' : 'non'}`);
}
JS
cat > "$AUX/pilote.mjs" <<'JS'
// pilote.mjs <assistant> <shell> <sortie1> <sortie2> <action>... : lance l'assistant seul (quatre tubes) ; actions : w:<texte> · W:<n> (n octets 'a') · t (SIGTERM) · s:<ms> · c:<ligne de contrôle> · e (ferme fd 0) · a:<sous-chaîne attendue sur fd 1>
import { spawn } from 'node:child_process'; import fs from 'node:fs';
const [, , assistant, shell, o1, o2, ...actions] = process.argv; fs.writeFileSync(o1, ''); fs.writeFileSync(o2, '');
const e = spawn('python3', ['-I', assistant, '24', '80', shell], { stdio: ['pipe', 'pipe', 'pipe', 'pipe'] });
e.stdout.on('data', (c) => fs.appendFileSync(o1, c)); e.stderr.on('data', (c) => fs.appendFileSync(o2, c)); e.stdin.on('error', () => {}); e.stdio[3].on('error', () => {});
let fini = null; e.on('close', (code, sig) => { fini = `code=${code} sig=${sig}`; });
const interp = (t) => t.replace(/\\x([0-9a-fA-F]{2})/g, (_, h) => String.fromCharCode(parseInt(h, 16))).replace(/\\n/g, '\n').replace(/\\r/g, '\r');
for (const x of actions) {
  if (x.startsWith('W:')) e.stdin.write(Buffer.alloc(Number(x.slice(2)), 97)); else if (x === 't') e.kill('SIGTERM'); else if (x.startsWith('s:')) await new Promise((r) => setTimeout(r, Number(x.slice(2))));
  else if (x.startsWith('w:')) e.stdin.write(interp(x.slice(2))); else if (x.startsWith('c:')) e.stdio[3].write(interp(x.slice(2)) + '\n'); else if (x === 'e') e.stdin.end();
  else if (x.startsWith('a:')) { const fin = Date.now() + 8000; while (Date.now() < fin && !fs.readFileSync(o1).toString('latin1').includes(x.slice(2))) await new Promise((r) => setTimeout(r, 50)); }
}
for (let i = 0; i < 160 && fini === null; i++) await new Promise((r) => setTimeout(r, 50));
console.log(fini === null ? 'vivant' : fini); if (fini === null) e.kill('SIGKILL'); process.exit(0);
JS

cat > "$AUX/rafale.mjs" <<'JS'
// rafale.mjs <port> <secret> <onglet> <n> <taille> : n POST /entree séquentiels de <taille> octets ; une ligne JSON {statut: nombre}
import http from 'node:http';
const [, , port, secret, onglet, n, taille] = process.argv;
const corps = Buffer.alloc(+taille, 97);
const un = () => new Promise((ok) => {
  const r = http.request({ host: '127.0.0.1', port: +port, path: '/entree', method: 'POST', agent: false, headers: { Host: `127.0.0.1:${port}`, Origin: `http://127.0.0.1:${port}`, 'X-VF-Terminal': secret, 'X-VF-Onglet': onglet, 'Content-Length': corps.length } }, (res) => { res.resume(); res.on('end', () => ok(res.statusCode)); });
  r.on('error', () => ok(0)); r.end(corps);
});
const c = {}; for (let i = 0; i < +n; i++) { const s = await un(); c[s] = (c[s] || 0) + 1; }
console.log(JSON.stringify(c)); process.exit(0);
JS

# shell de test (P71-PL-11) : marqué par son chemin, décrit ce qu'il reçoit dans $VFT_RUN, lance bash SANS exec ; `bash --rcfile` porte la marque
cat > "$WORK/bin/shell-test" <<'SH'
#!/bin/sh
R="$VFT_RUN"
echo $$ > "$R/shell.pid"; echo "$*" > "$R/args.txt"; env > "$R/env.txt"; pwd -P > "$R/pwd.txt"
printf "PS1='VFP> '\n" > "$R/rc"
bash --rcfile "$R/rc" -i
SH
cat > "$WORK/bin/dormir" <<'SH'
#!/bin/sh
echo $$ > "$VFT_RUN/$2.pid"
sleep "$1"
SH
cat > "$WORK/bin/shell-sourd" <<'SH'
#!/bin/sh
echo $$ > "$VFT_RUN/sourd.pid"
stty raw -echo
exec sleep 299
SH
# travail sorti de la session par setsid (limite assumée, T12.5) : écrit son PID (inchangé par l'exec) puis dort
cat > "$WORK/bin/hors-session" <<'SH'
#!/bin/sh
exec python3 -I -c 'import os; os.setsid(); open(os.environ["VFT_RUN"] + "/hs.pid", "w").write(str(os.getpid())); os.execvp("sleep", ["sleep", "303"])'
SH
chmod +x "$WORK/bin/shell-test" "$WORK/bin/dormir" "$WORK/bin/shell-sourd" "$WORK/bin/hors-session"; export SHELL="$WORK/bin/shell-test"

rq() { node "$TA" req "$@"; }
amorce_neuve() { node -e "console.log(require('crypto').randomBytes(24).toString('hex'))"; }
mklab() { # mklab <dir> : lab GSD minimal, construit
  local L="$1" B="$1/.planning"; mkdir -p "$L/src" "$B/phases/01-socle"; printf 'export const u = 1;\n' > "$L/src/u.js"
  printf -- '## Phases\n\n- [x] **Phase 1: Socle** - premier jet\n\n### Phase 1: Socle\n**Goal**: Poser le socle\n' > "$B/ROADMAP.md"
  printf -- '---\nstatus: executing\ncurrent_phase: 1\nmilestone: v1.0 MVP\n---\n' > "$B/STATE.md"
  printf -- '---\nwave: 1\nfiles_modified: [src/u.js]\n---\n<objective>Poser le socle</objective>\n' > "$B/phases/01-socle/01-01-PLAN.md"
  git -C "$L" init -q && git -C "$L" add -A && git -C "$L" -c user.email=t@t -c user.name=t commit -q -m init
  node "$SCRIPTS/vf-cockpit.mjs" build --lab "$L" > "$WORK/build-$(basename "$L").out" 2>&1 || cat "$WORK/build-$(basename "$L").out"
}
SRVN=0; ENVX=(); SRV_CWD=""; RUN="$WORK/run/x"
# 79-06 : le code ne vit plus dans la sortie. MOD_DEPOT = racine du module du dépôt ; mod_de <sortie> = racine du module que COMMANDE cette sortie
# (table posée par mutant() : sortie TAB module ; par défaut le module du dépôt). La table est lue par bash (awk) et par les petits scripts node.
MOD_DEPOT="$(cd "$SCRIPTS/.." && pwd -P)"; MODS_TABLE="$WORK/.mods"; : > "$MODS_TABLE"; export MODS_TABLE MOD_DEPOT
mod_de() { local m; m="$(awk -F'\t' -v s="${1:-}" '$1==s{m=$2} END{print m}' "$MODS_TABLE" 2>/dev/null)"; printf '%s\n' "${m:-$MOD_DEPOT}"; }
srv() { # srv <sortie> [moteur] -> SRV_PORT SRV_PID SRV_O SRV_OUT ; ENVX = arguments de env, SRV_CWD = dossier courant du serveur (le lab par défaut)
  local o="$1" eng="${2:-$ENG}" lab; lab="$(cd "$1/../.." && pwd)"; [ -n "$SRV_CWD" ] && lab="$SRV_CWD"
  SRVN=$((SRVN+1)); SRV_O="$o"; SRV_OUT="$WORK/serve-$SRVN-$RANDOM.out"; mkdir -p "$o/.cache" "$RUN"; rm -f "$o/.cache/server.json"
  AMORCE="$(amorce_neuve)"; (umask 077; printf '%s' "$AMORCE" > "$o/.cache/terminal-amorce"; printf '%s' "$AMORCE" > "$WORK/amorce.copy")
  local _ev=() _un=() _sv=() _x _pu=0 _n # ENVX peut porter « -u NOM » (option d'env) : l'aide ne passe que des NOM=valeur, NOM est donc retiré de l'environnement le temps du lancement
  for _x in ${ENVX[@]+"${ENVX[@]}"}; do if [ "$_pu" = 1 ]; then _un+=("$_x"); _pu=0; elif [ "$_x" = -u ]; then _pu=1; else _ev+=("$_x"); fi; done
  for _n in ${_un[@]+"${_un[@]}"}; do if [ -n "${!_n+x}" ]; then _sv+=("$_n=${!_n}"); fi; unset "$_n"; done
  if [ "$eng" = "$ENG" ]; then COCKPIT_MODULE="$(mod_de "$o")" COCKPIT_SORTIE="$o" COCKPIT_PRET=terminal COCKPIT_LOG="$SRV_OUT" cockpit_lancer "$lab" ${_ev[@]+"${_ev[@]}"} VFT_RUN="$RUN" --terminal
  else COCKPIT_SORTIE="$o" COCKPIT_PRET=terminal COCKPIT_LOG="$SRV_OUT" cockpit_lancer "$lab" ${_ev[@]+"${_ev[@]}"} VF_COCKPIT_ENGINE_DIR="$eng" VFT_RUN="$RUN" --terminal; fi   # moteur copié (assistant muté) : le serve.mjs du dépôt, la variable de la suite gagne
  for _x in ${_sv[@]+"${_sv[@]}"}; do export "${_x%%=*}=${_x#*=}"; done
  SRV_PID="$VF_PID"
}
sj() { node "$AUX/ev.mjs" "$1" < "$SRV_O/.cache/server.json" 2>/dev/null; }
unsrv() { vf_hyg_stop "$SRV_PID"; }
sess() { # sess <nom> <sortie> [moteur] : serveur, échange, flux, attente de l'invite ; code 0 si l'invite est arrivée
  S_NOM="$1"; RUN="$WORK/run/$1"; S_FL="$WORK/flux-$1.bin"; rm -f "$S_FL"; S_FPID=""; S_SEC=""
  srv "$2" "${3:-$ENG}"; S_PID=$SRV_PID; S_Q="$(sj '(j.terminal&&j.terminal.url)||""')"; S_Q="${S_Q##*:}"
  [ -n "$S_Q" ] && read -r _c S_SEC < <(node "$TA" amorcer "$S_Q" "$WORK/amorce.copy" | tr '\n' ' ')
  [[ "$S_SEC" =~ ^[0-9a-f]{64}$ ]] || { S_SEC=""; return 1; }
  node "$TA" flux "$S_Q" "$S_SEC" "onglet-$1" "$S_FL" 40000 ${S_TAILLE:+--taille $S_TAILLE} > "$WORK/flux-$1.log" 2>&1 & S_FPID=$!
  [ -n "${SANS_INVITE:-}" ] && return 0 # shell qui ne parle pas (T14) : pas d'invite à attendre
  [ "$(node "$TA" attendre "$S_FL" 'VFP> ' 10000)" = TROUVE ]
}
ent() { node "$TA" entree "$S_Q" "$S_SEC" "onglet-$S_NOM" "$1"; }
tail_() { node "$TA" taille "$S_Q" "$S_SEC" "onglet-$S_NOM" "$1" "$2"; }
wf() { node "$TA" attendre "$S_FL" "$1" "${2:-8000}"; }
fin_sess() { unsrv; [ -n "$S_FPID" ] && { wait "$S_FPID" 2>/dev/null; true; }; }
vivant() { kill -0 "$1" 2>/dev/null && echo oui || echo non; }
attendre_fichier() { local i; for i in $(seq 1 100); do [ -s "$1" ] && return 0; sleep 0.1; done; return 1; }
mutant() { # mutant <nom> <fichier> <expression-sed> [ligne ajoutée] -> MUT_OUT (copie du lab : données) et MUT_MOD (racine de la copie du module) ; code 1 si la cible manque ou si la copie n'a pas changé
  local d="$WORK/mut-$1" f; rm -rf "$d" "$WORK/mod-$1"; mkdir -p "$d"; cp -R "$LAB/.planning" "$d/.planning"; cp -R "$LAB/.vibeflow" "$d/.vibeflow"
  MUT_OUT="$d/.vibeflow/cockpit"; MUT_MOD=""
  case "$(basename "$2")" in
    serve.mjs|graph-query.js|query-cli.mjs|vf-cockpit-*) cockpit_module_muter "$1" "$2" "$3" || return 1; MUT_MOD="$COCKPIT_MODULE"; unset COCKPIT_MODULE
      [ -z "${4:-}" ] || printf '%s\n' "$4" >> "$(_cockpit_module_cible "$MUT_MOD" "$(basename "$2")")"
      printf '%s\t%s\n' "$MUT_OUT" "$MUT_MOD" >> "$MODS_TABLE"; return 0 ;;
  esac
  f="$d/.vibeflow/cockpit/$2"; [ -f "$f" ] || return 1   # page de la copie du lab (donnée) : même chemin que MUT_OUT/<fichier>
  cp "$f" "$f.orig"; sed -i.bak "$3" "$f"; [ -n "${4:-}" ] && printf '%s\n' "$4" >> "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
mutant_eng() { # mutant_eng <nom> <expression-sed> -> MUT_ENG : copie du moteur dont l'assistant est muté
  MUT_ENG="$WORK/eng-$1"; rm -rf "$MUT_ENG"; cp -R "$ENG" "$MUT_ENG"; local f="$MUT_ENG/terminal/vf-cockpit-pty.py"; [ -f "$f" ] || return 1
  cp "$f" "$f.orig"; sed -i.bak "$2" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}
sans_effet() { assert_eq "$1 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; }

LAB="$WORK/lab"; mklab "$LAB"; OUT="$LAB/.vibeflow/cockpit"; ln -s "$LAB" "$WORK/lien"
ENV1=(-u COLORTERM CLAUDECODE=1 CLAUDE_CODE_FOO=x CLAUDE_CODE_ENTRYPOINT=cli VF_COCKPIT_X=y AUTRE=ok NODE_OPTIONS=--no-warnings TERM=vt100)
ENV2=(CLAUDECODE=1 CLAUDE_CODE_FOO=x CLAUDE_CODE_ENTRYPOINT=cli VF_COCKPIT_X=y AUTRE=ok NODE_OPTIONS=--no-warnings TERM=dumb COLORTERM=24bit)
LISTE='^(CLAUDECODE|CLAUDE_CODE_FOO|CLAUDE_CODE_ENTRYPOINT|VF_COCKPIT_X)='
passe1() { # passe1 <nom> <sortie> <lab physique> [moteur] : serveur lancé hors du lab, environnement hostile ; pose P_ENV P_PWD P_ARGS P_OK
  ENVX=("${ENV1[@]}"); SRV_CWD="$WORK/ailleurs"; P_OK=non; sess "$1" "$2" "${4:-$ENG}" && P_OK=oui
  P_ENV="$WORK/run/$1/env.txt"; P_PWD="$(cat "$WORK/run/$1/pwd.txt" 2>/dev/null)"; P_ARGS="$(cat "$WORK/run/$1/args.txt" 2>/dev/null)"; SRV_CWD=""; ENVX=()
}

echo "=== T10 — environnement filtré, shell -l dans realpath(lab) (TERM-06 ; P71-D-03, D-04, D-14, D-22) ==="
passe1 t10a "$WORK/lien/.vibeflow/cockpit" "$LAB"
assert_eq "T10.0 — témoin : le shell de test a démarré et décrit son environnement (PATH présent, une fois)" "$P_OK $(grep -a -c '^PATH=' "$P_ENV" 2>/dev/null)" "oui 1"
assert_eq "T10.1 — absentes du shell : CLAUDECODE, CLAUDE_CODE_FOO, CLAUDE_CODE_ENTRYPOINT, VF_COCKPIT_X" "$(grep -a -c -E "$LISTE" "$P_ENV" 2>/dev/null)" "0"
assert_eq "T10.2 — présentes : AUTRE=ok et NODE_OPTIONS=--no-warnings (liste noire, pas liste blanche)" "$(grep -a -c -x -e 'AUTRE=ok' -e 'NODE_OPTIONS=--no-warnings' "$P_ENV" 2>/dev/null)" "2"
assert_eq "T10.3 — pwd -P du shell = realpath(lab), serveur lancé via un lien symbolique et depuis un dossier hors du lab" "$P_PWD" "$LAB"
assert_eq "T10.4 — le shell reçoit -l (shell de connexion)" "$P_ARGS" "-l"
assert_eq "T10.8 — TERM=vt100 hérité -> xterm-256color ; COLORTERM absent -> truecolor (D-23)" "$(grep -a -x -e 'TERM=.*' -e 'COLORTERM=.*' "$P_ENV" 2>/dev/null | sort | tr '\n' ' ')" "COLORTERM=truecolor TERM=xterm-256color "
fin_sess
ENVX=("${ENV2[@]}"); sess t10b "$OUT"; ENVX=()
assert_eq "T10.8 — TERM=dumb hérité -> xterm-256color ; COLORTERM=24bit hérité -> truecolor (D-23)" "$(grep -a -x -e 'TERM=.*' -e 'COLORTERM=.*' "$WORK/run/t10b/env.txt" 2>/dev/null | sort | tr '\n' ' ')" "COLORTERM=truecolor TERM=xterm-256color "
fin_sess
assert_eq "T10.5 — envShell retire CLAUDECODE, CLAUDE_CODE_*, VF_COCKPIT_*, une valeur qui contient un secret de 16+ caractères ; garde le reste (un secret court n'écarte rien)" "$(node "$AUX/unit.mjs" "$OUT" filtre)" "AUTRE,CLAUDE_AUTRE,COURT,NODE_OPTIONS"
assert_eq "T10.8 — envShell : TERM et COLORTERM posés TOUJOURS (hérités ou non), quatre entrées" "$(node "$AUX/unit.mjs" "$OUT" term)" "xterm-256color|truecolor xterm-256color|truecolor xterm-256color|truecolor xterm-256color|truecolor"
: > "$WORK/bin/pas-exec"; chmod 644 "$WORK/bin/pas-exec"
assert_eq "T10.6 — choisirShell : SHELL relatif, non exécutable ou dossier -> repli exécutable ; SHELL absent -> exécutable ; SHELL valide gardé" "$(node "$AUX/unit.mjs" "$OUT" shell "$WORK/bin/pas-exec" "$WORK/bin" "$WORK/bin/shell-test")" "relatif=oui sans-x=oui dossier=oui absent=oui valide=oui"
assert_eq "T10.7 — le cockpit ne pose pas NODE_OPTIONS (lignes non commentées de vf-cockpit.mjs et de serve.mjs)" "$(node "$AUX/aide.mjs" lignes-non-commentees NODE_OPTIONS "$SCRIPTS/vf-cockpit.mjs" "$ENG/assets/serve.mjs")" "0"
assert_eq "T10.7 — témoin : le compteur voit une ligne qui pose NODE_OPTIONS" "$(printf 'process.env.NODE_OPTIONS = 1\n// NODE_OPTIONS\n' > "$WORK/nodeopt.js"; node "$AUX/aide.mjs" lignes-non-commentees NODE_OPTIONS "$WORK/nodeopt.js")" "1"

echo "=== T11 — assistant isolé, taille, Ctrl-C, état de sortie (TERM-07 ; P71-D-06) ==="
sess t11 "$OUT"
APID="$(pgrep -P "$S_PID" | sed -n 1p)"; ACMD=""; [ -n "$APID" ] && ACMD="$(ps -o args= -p "$APID" 2>/dev/null)"
case "$ACMD" in *ython*" -I $ENG/terminal/vf-cockpit-pty.py "*) CMDOK=oui ;; *) CMDOK="non : ${ACMD:-aucun assistant}" ;; esac
assert_eq "T11.1 — l'assistant se lance « python3 -I <moteur>/terminal/vf-cockpit-pty.py »" "$CMDOK" "oui"
C0="echo SZ0-\$(stty size | tr ' ' x)\\r"; C1="echo SZ1-\$(stty size | tr ' ' x)\\r"
ent "$C0" > /dev/null; wf SZ0-24x80 > /dev/null; tail_ 50 132 > "$WORK/tail.out"; sleep 0.4; ent "$C1" > /dev/null
assert_eq "T11.2 — POST /taille 50 132 : stty size dans le shell = 50 132 (SZ1-50x132)" "$(cat "$WORK/tail.out") $(wf SZ1-50x132)" "204 TROUVE"
ent "$WORK/bin/dormir 30 fg\\r" > /dev/null
attendre_fichier "$WORK/run/t11/fg.pid"; DPID="$(cat "$WORK/run/t11/fg.pid" 2>/dev/null)"; BPID_BASH="$(pgrep -P "$(cat "$WORK/run/t11/shell.pid")" | sed -n 1p)"
ent "\\x03" > /dev/null; ent "echo VIVANT-\$((6*7))\\r" > /dev/null
for _ in $(seq 1 30); do [ "$(vivant "${DPID:-0}")" = non ] && break; sleep 0.1; done
assert_eq "T11.3 — 0x03 interrompt le programme de premier plan (dormir) et laisse le shell vivant (VIVANT-42)" "$(vivant "${DPID:-0}") $(wf VIVANT-42 5000) $(vivant "${BPID_BASH:-0}")" "non TROUVE oui"
fin_sess
SD="$ENG/terminal/vf-cockpit-pty.py"; RUN="$WORK/run/pilote"; mkdir -p "$RUN"
PIL="$(VFT_RUN="$RUN" node "$AUX/pilote.mjs" "$SD" "$WORK/bin/shell-test" "$WORK/pilote1.out" "$WORK/pilote2.out" 'a:VFP> ' 'w:exit 3\r' 2>&1)"
assert_eq "T11.5 — assistant seul : exit 3 -> fd 2 porte exactement « FIN 3 » (aucun octet du shell) et l'assistant sort de lui-même" "$(tr -d '\r' < "$WORK/pilote2.out") | $PIL" "FIN 3 | code=0 sig=null"

S_TAILLE=500x1000 sess t11b "$OUT"; S_TAILLE=""
ent "echo SZB-\$(stty size | tr ' ' x)\\r" > /dev/null
assert_eq "T11.6 — flux ouvert à la borne 500x1000 (X-VF-Taille) : le shell mesure 500x1000 (une seule borne, serveur et assistant)" "$(wf SZB-500x1000 5000)" "TROUVE"
fin_sess
PIL="$(VFT_RUN="$RUN" node "$AUX/pilote.mjs" "$SD" "$WORK/bin/shell-test" "$WORK/pilote3.out" "$WORK/pilote4.out" 'a:VFP> ' 'c:R 500 1000' 's:300' 'c:R 501 80' 'c:R 24 1001' 'c:R 0 80' 's:300' 'w:echo SZC-$(stty size | tr " " x)\r' 'a:SZC-' 'w:exit 0\r' 2>&1)"
assert_eq "T11.7 — assistant seul : R 500 1000 appliquée, R 501 80 / R 24 1001 / R 0 80 ignorées (SZC-500x1000)" "$(grep -a -c 'SZC-500x1000' "$WORK/pilote3.out") $PIL" "1 code=0 sig=null"
python3 -I "$SD" 501 80 /bin/true 3</dev/null </dev/null >/dev/null 2>&1; R1=$?; python3 -I "$SD" 24 1001 /bin/true 3</dev/null </dev/null >/dev/null 2>&1; R2=$?
assert_eq "T11.8 — assistant lancé avec une taille hors borne (501x80, 24x1001) : usage, code 64, aucun shell" "$R1 $R2" "64 64"
fd3() { # fd3 <nom> <sortie> [moteur] -> FD3_RES : « <FERME vu> <OUVERT vu> » ; le shell tente d'écrire (rien) sur le descripteur 3, ouvert chez l'assistant seulement
  sess "$1" "$2" "${3:-$ENG}"; ent "{ : >&3; } 2>/dev/null && echo FD3-OUV\"\"ERT || echo FD3-FER\"\"ME\\r" > /dev/null
  FD3_RES="$(wf FD3-FERME 5000) $(wf FD3-OUVERT 500)"; fin_sess
}
fd3 t11d "$OUT"
assert_eq "T11.9 — le shell n'hérite pas du descripteur 3 : l'écriture sur le descripteur 3 échoue (FD3-FERME vu, FD3-OUVERT jamais) ; témoin : le shell répond" "$FD3_RES" "TROUVE ABSENT"

echo "=== T12 — serveur tué par SIGKILL : rien ne survit (TERM-08 orphelins ; P71-D-05) ==="
orphelins() { # orphelins <nom> <sortie> [moteur] -> O_RES : « <état avant> <survivants> »
  sess "$1" "$2" "${3:-$ENG}"; ent "$WORK/bin/dormir 300 bg &\\r" > /dev/null; ent "echo \$\$ > $WORK/run/$1/bash.pid\\r" > /dev/null
  attendre_fichier "$WORK/run/$1/bg.pid"; attendre_fichier "$WORK/run/$1/bash.pid"
  local a s b d z vivants="" surv="" i p; a="$(pgrep -P "$S_PID" | sed -n 1p)"; s="$(cat "$WORK/run/$1/shell.pid" 2>/dev/null)"; b="$(cat "$WORK/run/$1/bash.pid" 2>/dev/null)"; d="$(cat "$WORK/run/$1/bg.pid" 2>/dev/null)"
  z="$(pgrep -P "${d:-0}" | sed -n 1p)"
  for p in $a $s $b $d $z; do [ "$(vivant "$p")" = oui ] && vivants="$vivants x"; done
  kill -KILL "$S_PID"; wait "$S_PID" 2>/dev/null; vf_hyg_stop "$S_PID"
  for i in $(seq 1 50); do surv=""; for p in $a $s $b $d $z; do [ "$(vivant "$p")" = oui ] && surv="$surv $p"; done; [ -z "$surv" ] && break; sleep 0.1; done
  for p in $surv; do vf_hyg_stop "$p"; done                                         # survivants marqués (mutant) : arrêtés ici
  [ -n "$z" ] && [ "$(ps -o args= -p "$z" 2>/dev/null)" = "sleep 300" ] && kill -KILL "$z" 2>/dev/null   # le sleep seul ne porte pas la marque ; son PID est enregistré
  [ -n "$S_FPID" ] && { wait "$S_FPID" 2>/dev/null; true; }
  if [ -n "$surv" ]; then O_RES="$(echo $vivants | wc -w | tr -d ' ') survivants"; else O_RES="$(echo $vivants | wc -w | tr -d ' ') aucun"; fi
}
orphelins t12 "$OUT"
assert_eq "T12.4 — cinq processus (assistant, shell, bash, travail, sleep) vivaient ; serveur tué par SIGKILL : aucun ne survit après 5 s" "$O_RES" "5 aucun"
session_entiere() { # session_entiere <nom> <sortie> [moteur] -> SE_RES : « <membres vivants avant> <survivants de la session> <hors-session vivant> <leurre vivant> »
  sess "$1" "$2" "${3:-$ENG}"; local R="$WORK/run/$1"
  ent "nohup $WORK/bin/dormir 301 nh >/dev/null 2>&1 &\\r" > /dev/null; ent "nohup $WORK/bin/dormir 302 dis >/dev/null 2>&1 & disown\\r" > /dev/null; ent "$WORK/bin/hors-session &\\r" > /dev/null
  attendre_fichier "$R/nh.pid"; attendre_fichier "$R/dis.pid"; attendre_fichier "$R/hs.pid"; sleep 0.3
  sleep 303 & local leurre=$!    # leurre : dans la session de la suite, pas dans celle du terminal ; son PID est enregistré
  local nh dis hs nhz disz p avant="" surv="" i; nh="$(cat "$R/nh.pid")"; dis="$(cat "$R/dis.pid")"; hs="$(cat "$R/hs.pid")"; nhz="$(pgrep -P "${nh:-0}" | sed -n 1p)"; disz="$(pgrep -P "${dis:-0}" | sed -n 1p)"
  for p in $nh $nhz $dis $disz; do [ "$(vivant "$p")" = oui ] && avant="$avant x"; done
  kill -KILL "$S_PID"; wait "$S_PID" 2>/dev/null; vf_hyg_stop "$S_PID"
  for i in $(seq 1 100); do surv=""; for p in $nh $nhz $dis $disz; do [ "$(vivant "$p")" = oui ] && surv="$surv $p"; done; [ -z "$surv" ] && break; sleep 0.1; done
  SE_RES="$(echo $avant | wc -w | tr -d ' ') $(echo $surv | wc -w | tr -d ' ') $(vivant "${hs:-0}") $(vivant "$leurre")"
  for p in $surv; do tuer_si "$p" "sleep 30"; tuer_si "$p" dormir; done                 # survivants (mutant) : arrêtés par PID, ligne de commande relue
  tuer_si "$hs" "sleep 303"; kill -KILL "$leurre" 2>/dev/null; wait "$leurre" 2>/dev/null
  [ -n "$S_FPID" ] && { wait "$S_FPID" 2>/dev/null; true; }
}
tuer_si() { # tuer_si <pid> <sous-chaîne de sa ligne de commande> : arrête un survivant enregistré, par PID, après avoir relu sa ligne de commande
  [ -n "$1" ] && case "$(ps -o args= -p "$1" 2>/dev/null)" in *"$2"*) kill -KILL "$1" 2>/dev/null ;; esac; true
}
session_entiere t12b "$OUT"
assert_eq "T12.5 — nohup et disown dans le shell (P71-D-28) : quatre processus vivaient, aucun ne survit à l'arrêt du serveur ; le setsid survit (limite assumée, hors session) ; le leurre hors terminal survit (rien d'autre n'est visé)" "$SE_RES" "4 0 oui oui"

echo "=== T12.6 — chaque branche d'arrêt de l'assistant tue la session : sortie du shell, SIGTERM, fin du descripteur 0 (M1) ==="
nohup_fin() { # nohup_fin <nom> <exit|term|eof> [moteur] -> NF_RES : « avant=<n> survivants=<n> fin=<code de l'assistant> » ; un nohup lancé dans le shell, puis la fin choisie
  local n="$1" fin="$2" eng="${3:-$ENG}" act p nh sl avant=0 surv=0 pp
  case "$fin" in exit) act='w:exit\r' ;; term) act=t ;; *) act=e ;; esac
  RUN="$WORK/run/$n"; mkdir -p "$RUN"; rm -f "$RUN/nhq.pid"
  VFT_RUN="$RUN" node "$AUX/pilote.mjs" "$eng/terminal/vf-cockpit-pty.py" "$WORK/bin/shell-test" "$WORK/$n.1" "$WORK/$n.2" 'a:VFP> ' "w:nohup $WORK/bin/dormir 311 nhq >/dev/null 2>&1 &\\r" 's:1500' "$act" > "$WORK/$n.res" 2>&1 & pp=$!; PIDS+=($pp)
  attendre_fichier "$RUN/nhq.pid"; sleep 0.3
  nh="$(cat "$RUN/nhq.pid" 2>/dev/null)"; sl="$(pgrep -P "${nh:-0}" | sed -n 1p)"
  for p in $nh $sl; do [ "$(vivant "$p")" = oui ] && avant=$((avant+1)); done
  wait "$pp" 2>/dev/null; sleep 0.3
  for i in $(seq 1 30); do surv=0; for p in $nh $sl; do [ "$(vivant "$p")" = oui ] && surv=$((surv+1)); done; [ "$surv" = 0 ] && break; sleep 0.1; done
  for p in $nh $sl; do tuer_si "$p" "sleep 311"; tuer_si "$p" dormir; done
  NF_RES="avant=$avant survivants=$surv fin=$(cat "$WORK/$n.res" 2>/dev/null)"
}
nohup_fin t126a exit; NFA="$NF_RES"; nohup_fin t126b term; NFB="$NF_RES"; nohup_fin t126c eof; NFC="$NF_RES"
assert_eq "T12.6a — le shell sort de lui-même (exit) après un nohup : le travail est tué avec la session (deux processus vivaient, aucun ne survit)" "$NFA" "avant=2 survivants=0 fin=code=0 sig=null"
assert_eq "T12.6b — SIGTERM à l'assistant après un nohup : même résultat" "$NFB" "avant=2 survivants=0 fin=code=0 sig=null"
assert_eq "T12.6c — fin du descripteur 0 après un nohup : même résultat" "$NFC" "avant=2 survivants=0 fin=code=0 sig=null"

echo "=== T12.7 — relevé de processus : vide = impossible, zombie = mort, chef réapé = jamais signalé (M2, M3, N4) ==="
cat > "$AUX/unit-pty.py" <<'PY'
# unit-pty.py <vf-cockpit-pty.py> <cas> : fonctions de relevé de l'assistant importées (jamais lancé)
import importlib.util, os, subprocess, sys, time
sys.dont_write_bytecode = True  # jamais de __pycache__ à côté de l'assistant du moteur (synchro.sh verifier)
spec = importlib.util.spec_from_file_location('pty_assistant', sys.argv[1]); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
cas = sys.argv[2]
if cas == 'releve-vide':
    # /proc vide (bac à sable) et ps illisible : le relevé ne contient pas l'assistant, il vaut « impossible » et déclenche le repli sur les groupes
    vivant = subprocess.Popen(['sleep', '30'], start_new_session=True)
    m.os.listdir = lambda p: []
    def boom(*a, **k): raise OSError('ps illisible')
    m.subprocess.run = boom
    try: print('membres=%s vivants=%s' % (m.membres(os.getsid(0)), m.vivants(99999999, {vivant.pid})))
    finally: vivant.kill(); vivant.wait()
elif cas == 'zombie':
    # zombie réel : le relevé en lit l'état Z (/proc ou ps), il n'est pas un membre ; (getsid d'un zombie échoue sous macOS, réussit sous Linux : voir etat-z)
    mort = subprocess.Popen(['true']); vivant = subprocess.Popen(['sleep', '30']); time.sleep(0.6)
    try:
        r = m.releve(); ms = m.membres(os.getsid(0))
        print('etat=%s zombie=%s vivant=%s' % (r.get(mort.pid, '?')[:1], mort.pid in ms, vivant.pid in ms))
    finally: vivant.kill(); vivant.wait(); mort.wait()
elif cas == 'etat-z':
    # relevé qui déclare Z un processus dont getsid réussit (le cas Linux) : il est écarté ; témoin : le même relevé le déclarant S le garde
    vivant = subprocess.Popen(['sleep', '30'])
    try:
        moi = os.getpid(); sid = os.getsid(0)
        m.releve = lambda: {vivant.pid: 'Z', moi: 'S'}; z = vivant.pid in m.membres(sid)
        m.releve = lambda: {vivant.pid: 'S', moi: 'S'}; s_ = vivant.pid in m.membres(sid)
        print('Z=%s S=%s' % (z, s_))
    finally: vivant.kill(); vivant.wait()
elif cas == 'etat-proc':
    import tempfile
    d = tempfile.mkdtemp(); os.mkdir(d + '/4242'); open(d + '/4242/stat', 'w').write('4242 (a) b) Z 1 4242 4242 0\n'); m.PROC = d
    print('Z=%s absent=%s' % (m.etat_proc(4242), m.etat_proc(4243)))
elif cas == 'chef-reape':
    chef = subprocess.Popen(['sleep', '30'], start_new_session=True)
    try:
        avant = chef.pid in m.membres(chef.pid); m.CHEF_REAPE = True; apres = chef.pid in m.membres(chef.pid)
        print('avant=%s apres=%s' % (avant, apres))
    finally: chef.kill(); chef.wait()
PY
mutant_unit() { # mutant_unit <nom> <sed> -> MUT_PTY : copie de l'assistant mutée ; code 1 si la copie n'a pas changé
  MUT_PTY="$WORK/pty-$1.py"; cp "$ENG/terminal/vf-cockpit-pty.py" "$MUT_PTY"; cp "$MUT_PTY" "$MUT_PTY.orig"; sed -i.bak "$2" "$MUT_PTY"
  local r=0; cmp -s "$MUT_PTY" "$MUT_PTY.orig" && r=1; rm -f "$MUT_PTY.orig" "$MUT_PTY.bak"; return $r
}
unit_pty() { python3 -I "$AUX/unit-pty.py" "$1" "$2" 2>&1 | tail -1; }
PTY_REEL="$ENG/terminal/vf-cockpit-pty.py"
assert_eq "T12.7a — relevé vide (/proc vide, ps illisible) : il ne contient pas l'assistant, donc « impossible » (None) et le repli sur les groupes voit le groupe vivant" "$(unit_pty "$PTY_REEL" releve-vide)" "membres=None vivants=True"
assert_eq "T12.7b — un zombie réel : le relevé en lit l'état Z et il n'est pas un membre ; témoin : un processus vivant de la même session l'est" "$(unit_pty "$PTY_REEL" zombie)" "etat=Z zombie=False vivant=True"
assert_eq "T12.7d — un relevé qui déclare Z un processus dont getsid réussit (cas Linux) l'écarte ; témoin : déclaré S, il est gardé" "$(unit_pty "$PTY_REEL" etat-z)" "Z=False S=True"
assert_eq "T12.7e — lecture de /proc/<pid>/stat : l'état suit la DERNIÈRE parenthèse fermante (nom de commande à parenthèses), processus disparu : None" "$(unit_pty "$PTY_REEL" etat-proc)" "Z=Z absent=None"
assert_eq "T12.7c — le chef de session réapé n'est jamais visé (PID réutilisable) ; témoin : tant qu'il n'est pas réapé, il est un membre" "$(unit_pty "$PTY_REEL" chef-reape)" "avant=True apres=False"

echo "=== M-* — mutants de l'arrêt et du relevé de l'assistant (M1, M2, M3, N4) ==="
if mutant_eng sortiesanskill 's/^                sigkill_session(pid, gs)$/                pass/'; then
  nohup_fin m15 exit "$MUT_ENG"; assert_eq "M-SORTIE-SANS-KILL — le mutant retire la mise à mort de la branche « shell sorti » : les deux processus du nohup survivent (T12.6a rouge)" "$NF_RES" "avant=2 survivants=2 fin=code=0 sig=null"
else sans_effet M-SORTIE-SANS-KILL; fi
if mutant_eng arretsanskill 's/^    sigkill_session(sid, gs)/    pass #/'; then
  nohup_fin m16 term "$MUT_ENG"; R16="$NF_RES"; nohup_fin m17 eof "$MUT_ENG"
  assert_eq "M-ARRET-SANS-KILL — le mutant retire la mise à mort de arreter() : SIGTERM et fin du descripteur 0 laissent survivre le nohup (T12.6b et T12.6c rouges)" "$R16 | $NF_RES" "avant=2 survivants=2 fin=code=0 sig=null | avant=2 survivants=2 fin=code=0 sig=null"
else sans_effet M-ARRET-SANS-KILL; fi
if mutant_unit relevevide 's/if moi in r:/if True:/'; then
  assert_eq "M-RELEVE-VIDE — le mutant (un relevé sans l'assistant est pris pour valide) rougit T12.7a : membres = [] et le repli sur les groupes n'a pas lieu" "$(unit_pty "$MUT_PTY" releve-vide)" "membres=[] vivants=False"
else sans_effet M-RELEVE-VIDE; fi
if mutant_unit zombie "s/ and not e.startswith('Z')//"; then
  assert_eq "M-ZOMBIE — le mutant (l'état Z n'écarte plus rien) rougit T12.7d : le processus déclaré Z reste membre" "$(unit_pty "$MUT_PTY" etat-z)" "Z=True S=True"
else sans_effet M-ZOMBIE; fi
if mutant_unit etatproc "s/t\[i + 2:i + 3\]/t[i + 1:i + 2]/"; then
  assert_eq "M-ETAT-PROC — le mutant (état lu un caractère trop tôt) rougit T12.7e" "$(unit_pty "$MUT_PTY" etat-proc)" "Z=  absent=None"
else sans_effet M-ETAT-PROC; fi
if mutant_unit chefreape 's/if CHEF_REAPE and p == sid:/if False:/'; then
  assert_eq "M-CHEF-REAPE — le mutant (le chef réapé reste visé) rougit T12.7c" "$(unit_pty "$MUT_PTY" chef-reape)" "avant=True apres=True"
else sans_effet M-CHEF-REAPE; fi

echo "=== T15 — python3 du lab jamais exécuté par le serveur (F3 ; P71-D-25, P71-D-03 : le PATH du shell reste celui de l'utilisateur) ==="
python3_du_lab() { # python3_du_lab <nom> <sortie> <préfixe de PATH> [moteur] -> PY_RES : « <python3 du lab exécuté> <invite arrivée> <PATH du shell conserve le préfixe> »
  local lab; lab="$(cd "$2/../.." && pwd)"; rm -f "$WORK/leurre-python3.marque"
  printf '#!/bin/sh\necho execute > "%s/leurre-python3.marque"\nexit 1\n' "$WORK" > "$lab/python3"; chmod +x "$lab/python3"
  # P71-D-03 : le serveur est lancé directement ici ; le lanceur, lui, transmet le PATH d'origine dans VF_COCKPIT_PATH_ORIGINE, restitué en PATH au shell
  ENVX=(PATH="$3$PATH" VF_COCKPIT_PATH_ORIGINE="$3$PATH"); local ok=oui; sess "$1" "$2" "${4:-$ENG}" || ok=non; ENVX=()
  local pp="non"; [ "$ok" = oui ] && { ent "echo SHPATH-\"\"[\$PATH]\\r" > /dev/null; wf "SHPATH-[$3" 3000 | grep -q TROUVE && pp="oui"; }
  PY_RES="$([ -e "$WORK/leurre-python3.marque" ] && echo execute || echo non) $ok $pp"; fin_sess; rm -f "$lab/python3"
}
python3_du_lab t15a "$OUT" ".:"
assert_eq "T15.1 — PATH commençant par « . » (« .: ») : le python3 du lab n'est pas exécuté, le terminal démarre, le shell garde le PATH de l'utilisateur" "$PY_RES" "non oui oui"
python3_du_lab t15b "$OUT" ":"
assert_eq "T15.2 — PATH commençant par un élément vide : le python3 du lab n'est pas exécuté, le terminal démarre, le shell garde le PATH de l'utilisateur" "$PY_RES" "non oui oui"
python3_du_lab t15c "$OUT" "relatif/../.:"
assert_eq "T15.3 — PATH à éléments relatifs (« relatif/../. ») puis vide : idem" "$PY_RES" "non oui oui"

echo "=== T13 — programme plein écran témoin par le flux direct (TERM-09 automatisé) ==="
sess t13 "$OUT"; N1=0
ent "python3 -I $WORK/temoins/plein-ecran.py\\r" > /dev/null; PRET="$(wf PRET 10000)"
assert_eq "T13.1 — le témoin démarre (PRET) et passe en écran alterné (ESC[?1049h)" "$PRET $(node "$AUX/aide.mjs" cnt "$S_FL" $'\033[?1049h')" "TROUVE 1"
assert_eq "T13.2 — barre 256 couleurs (48;5;) et truecolor (ESC[38;2;255;100;0m)" "$([ "$(node "$AUX/aide.mjs" cnt "$S_FL" '48;5;')" -gt 0 ] && echo palette) $(node "$AUX/aide.mjs" cnt "$S_FL" $'\033[38;2;255;100;0m')" "palette 1"
tail_ 50 132 > "$WORK/tail13.out"
assert_eq "T13.3 — TAILLE 24x80 au départ puis WINCH 50x132 après POST /taille" "$(wf 'WINCH 50x132' 5000) $(node "$AUX/aide.mjs" ordre "$S_FL" 'TAILLE 24x80' 'WINCH 50x132')" "TROUVE ok"
N1="$(node "$AUX/aide.mjs" cnt "$S_FL" 'VFP> ')"
ent "\\x03" > /dev/null; INT="$(wf SIGINT-RECU 5000)"
assert_eq "T13.4 — 0x03 : SIGINT-RECU, précédé de la sortie d'écran alterné (ESC[?1049l)" "$INT $(node "$AUX/aide.mjs" ordre "$S_FL" $'\033[?1049l' 'SIGINT-RECU')" "TROUVE ok"
assert_eq "T13.5 — après SIGINT-RECU, l'invite du shell revient" "$(node "$AUX/aide.mjs" attendre-n "$S_FL" 'VFP> ' $((N1+1)) 5000)" "TROUVE"
fin_sess

echo "=== T14 — entrées en attente : l'assistant reste réactif, rien ne survit (TERM-08 ; P71-D-05) ==="
attendre_mort() { local i p; for i in $(seq 1 60); do for p in "$@"; do [ -n "$p" ] && [ "$(vivant "$p")" = oui ] && { sleep 0.1; continue 2; }; done; return 0; done; return 1; }
sourd() { # sourd <nom> <sortie> [moteur] -> SO_RES : « avant=<assistant> <shell> <statut POST> apres=<assistant> <shell> » ; serveur tué par SIGKILL après une entrée de 65 536 octets que le shell ne lit pas
  ENVX=(SHELL="$WORK/bin/shell-sourd"); SANS_INVITE=1 sess "$1" "$2" "${3:-$ENG}"; ENVX=(); local a s st av ap
  attendre_fichier "$WORK/run/$1/sourd.pid"; a="$(pgrep -P "$S_PID" | sed -n 1p)"; s="$(cat "$WORK/run/$1/sourd.pid" 2>/dev/null)"
  st="$(ent "$(head -c 65536 /dev/zero | tr '\0' a)")"; sleep 0.5; av="$(vivant "${a:-0}") $(vivant "${s:-0}")"
  # P71-D-33 : le processus du terminal meurt LUI AUSSI par SIGKILL (sinon il arrête l'assistant à la mort du parent et ce test ne mesurerait plus l'autonomie de l'assistant ; la mort du parent seul est mesurée par test-cockpit-terminal-session.sh)
  local qp; qp="$(command pgrep -P "$S_PID" | while read -r c; do ps -o command= -p "$c" 2>/dev/null | grep -q 'vf-cockpit-terminal-processus.mjs' && echo "$c"; done | sed -n 1p)"
  [ -n "$qp" ] && kill -KILL "$qp"
  kill -KILL "$S_PID"; wait "$S_PID" 2>/dev/null; vf_hyg_stop "$S_PID"
  attendre_mort "$a" "$s"; ap="$(vivant "${a:-0}") $(vivant "${s:-0}")"
  tuer_si "$a" vf-cockpit-pty.py; tuer_si "$s" "sleep 299"
  [ -n "$S_FPID" ] && { wait "$S_FPID" 2>/dev/null; true; }
  SO_RES="avant=$av POST=$st apres=$ap"
}
sourd t14 "$OUT"
assert_eq "T14.1 — shell qui ne lit pas, POST /entree de 65 536 octets, serveur tué par SIGKILL : l'assistant et le shell disparaissent en moins de 6 s (PID enregistrés)" "$SO_RES" "avant=oui oui POST=204 apres=non non"
pilote_sourd() { # pilote_sourd <nom> <action>... -> PS_RES : « <fin de l'assistant> shell=<vivant après 6 s> »
  local n="$1"; shift; RUN="$WORK/run/$n"; mkdir -p "$RUN"; rm -f "$RUN/sourd.pid"
  local r s; r="$(SHELL="$WORK/bin/shell-sourd" VFT_RUN="$RUN" node "$AUX/pilote.mjs" "${PIL_SD:-$ENG/terminal/vf-cockpit-pty.py}" "$WORK/bin/shell-sourd" "$WORK/$n.1" "$WORK/$n.2" "$@" 2>&1)"
  s="$(cat "$RUN/sourd.pid" 2>/dev/null)"; attendre_mort "$s"; PS_RES="$r shell=$(vivant "${s:-0}")"; tuer_si "$s" "sleep 299"
}
pilote_sourd t14b s:300 W:65536 s:500 e
assert_eq "T14.2 — assistant seul, 65 536 octets en attente chez un shell sourd, puis fin du fd 0 : il sort de lui-même, le shell aussi" "$PS_RES" "code=0 sig=null shell=non"
pilote_sourd t14c s:300 W:65536 s:500 t
assert_eq "T14.3 — assistant seul, mêmes octets en attente, puis SIGTERM : il sort de lui-même, le shell aussi" "$PS_RES" "code=0 sig=null shell=non"
rafale() { # rafale <nom> <sortie> -> RAF : 60 POST de 64 Kio vers un shell qui ne lit pas ; JSON des statuts
  ENVX=(SHELL="$WORK/bin/shell-sourd"); SANS_INVITE=1 sess "$1" "$2"; ENVX=(); attendre_fichier "$WORK/run/$1/sourd.pid"
  RAF="$(node "$AUX/rafale.mjs" "$S_Q" "$S_SEC" "onglet-$1" 60 65536)"; fin_sess
}
verdict_rafale() { printf '%s\n' "$RAF" | node "$AUX/ev.mjs" '(j["429"]||0)>=1&&(j["204"]||0)>=1&&(j["204"]||0)<=30&&(j["204"]||0)+(j["429"]||0)===60?"borne":JSON.stringify(j)' 2>/dev/null; }
rafale t14d "$OUT"
assert_eq "S3.1 — 60 POST de 64 Kio vers un shell qui ne lit pas : des 204 au début, puis 429 explicite ; jamais plus de 30 acceptés (≈ 1,9 Mio, borne de l'assistant 1 Mio + 256 Kio d'attente côté serveur) ; aucun autre statut" "$(verdict_rafale)" "borne"

echo "=== M-* — mutants du lanceur et du filtre (copies du module) ==="
if mutant envlarge vf-cockpit-terminal-env.mjs 's/export function envShell/function envShellOrig/' 'export const envShell = (env) => ({ PATH: env.PATH, HOME: env.HOME, SHELL: env.SHELL, VFT_RUN: env.VFT_RUN });'; then
  passe1 m1 "$MUT_OUT" "$MUT_OUT"; assert_eq "M-ENVLARGE — le mutant (liste blanche PATH, HOME, SHELL) rougit T10.2 : PATH présent, AUTRE et NODE_OPTIONS absents" "$(grep -a -c '^PATH=' "$P_ENV" 2>/dev/null) $(grep -a -c -x -e 'AUTRE=ok' -e 'NODE_OPTIONS=--no-warnings' "$P_ENV" 2>/dev/null)" "1 0"; fin_sess
else sans_effet M-ENVLARGE; fi
if mutant cwd vf-cockpit-terminal-session.mjs 's/cwd: fs.realpathSync(lab)/cwd: process.cwd()/'; then
  passe1 m2 "$MUT_OUT" "$MUT_OUT"; assert_eq "M-CWD — le mutant (cwd = dossier du serveur) rougit T10.3 : le shell est dans le dossier hors du lab" "$P_PWD" "$WORK/ailleurs"; fin_sess
else sans_effet M-CWD; fi
if mutant siabsent vf-cockpit-terminal-env.mjs 's/Object.assign(sortie, AJOUTS_TOUJOURS);/for (const [k, v] of Object.entries(AJOUTS_TOUJOURS)) if (!(k in sortie)) sortie[k] = v;/'; then
  passe1 m3 "$MUT_OUT" "$MUT_OUT"; assert_eq "M-SI-ABSENT — le mutant (constante posée si la clé manque) garde TERM=vt100 : T10.8 rouge" "$(grep -a -x 'TERM=.*' "$P_ENV" 2>/dev/null)" "TERM=vt100"; fin_sess
else sans_effet M-SI-ABSENT; fi
if mutant sansi vf-cockpit-terminal-session.mjs "s/\['-I', assistant/[assistant/"; then
  sess m4 "$MUT_OUT"; A="$(pgrep -P "$S_PID" | sed -n 1p)"; C="$(ps -o args= -p "${A:-0}" 2>/dev/null)"
  case "$C" in *" -I "*) R=avec-I ;; *) R=sans-I ;; esac
  assert_eq "M-SANS-I — le mutant lance l'assistant sans -I : T11.1 rouge" "$R" "sans-I"; fin_sess
else sans_effet M-SANS-I; fi
if mutant_eng sansl "s/\[shell, .-l.\]/[shell]/"; then
  ENVX=(); sess m5 "$OUT" "$MUT_ENG"; assert_eq "M-SANS-L — le mutant lance le shell sans -l : T10.4 rouge" "$(cat "$WORK/run/m5/args.txt" 2>/dev/null)" ""; fin_sess
else sans_effet M-SANS-L; fi

if mutant python3cwd vf-cockpit-terminal-session.mjs "s#resoudrePython3(env.PATH) || '/dev/null/python3'#'python3'#"; then
  python3_du_lab m14 "$MUT_OUT" ".:"; assert_eq "M-PYTHON3-CWD — le mutant lance « python3 » par le PATH (relatif) : le python3 du lab est exécuté, le terminal ne démarre pas (T15.1 rouge)" "$PY_RES" "execute non non"
else sans_effet M-PYTHON3-CWD; fi

echo "=== M-* — mutants de l'assistant (copies du moteur) ==="
ctrlc() { # ctrlc <nom> <moteur> : lance dormir 30 au premier plan, envoie 0x03 ; rend « <dormir vivant> <shell vivant> »
  sess "$1" "$OUT" "$2"; ent "$WORK/bin/dormir 30 fg\\r" > /dev/null; attendre_fichier "$WORK/run/$1/fg.pid"
  local d b; d="$(cat "$WORK/run/$1/fg.pid" 2>/dev/null)"; b="$(pgrep -P "$(cat "$WORK/run/$1/shell.pid")" | sed -n 1p)"
  ent "\\x03" > /dev/null; sleep 1.5; CC_RES="$(vivant "${d:-0}") $(vivant "${b:-0}")"
  vf_hyg_stop "$d" > /dev/null 2>&1; fin_sess
}
if mutant_eng sigint 's/^                vers_shell += donnees$/                (vers_shell.extend(donnees) if b"\\x03" not in donnees else os.killpg(pid, signal.SIGKILL))/'; then
  ctrlc m6 "$MUT_ENG"; assert_eq "M-SIGINT — le mutant tue le groupe du shell sur 0x03 : le shell ne survit pas, T11.3 rouge" "$CC_RES" "non non"
else sans_effet M-SIGINT; fi
if mutant_eng ctrlc 's/^                vers_shell += donnees$/                vers_shell += donnees.replace(b"\\x03", b"")/'; then
  ctrlc m7 "$MUT_ENG"; assert_eq "M-CTRLC — le mutant retire 0x03 de l'entrée : le programme de premier plan survit, T11.3 rouge" "$CC_RES" "oui oui"
else sans_effet M-CTRLC; fi
if mutant_eng resize 's/^                taille(maitre, l, c)$/                pass/'; then
  sess m8 "$OUT" "$MUT_ENG"; ent "$C0" > /dev/null; wf SZ0-24x80 > /dev/null; tail_ 50 132 > /dev/null; sleep 0.4; ent "$C1" > /dev/null; R1="$(wf SZ1-50x132 2500)"
  ent "python3 -I $WORK/temoins/plein-ecran.py\\r" > /dev/null; wf PRET > /dev/null; tail_ 50 132 > /dev/null; R2="$(wf 'WINCH 50x132' 2500)"
  assert_eq "M-RESIZE — le mutant ignore les lignes R : ni stty size (T11.2) ni WINCH (T13.3)" "$R1 $R2" "ABSENT ABSENT"; fin_sess
else sans_effet M-RESIZE; fi
# Le mutant se juge sur l'assistant SEUL (pilote, fd 1 ouvert) : serveur vivant, Q n'arrête rien, seule la fin du fd 0 peut le faire sortir. Avec un serveur tué (T12.4), Q arrête
# la session de son côté (IPC fermée -> arreterTout, SIGTERM) et le mutant paraît inoffensif ; sur ce chemin-là un EOF ignoré ne se voit pas.
if mutant_eng noeof 's/^                    break$/                    time.sleep(0.05)/'; then
  nohup_fin m9 eof "$MUT_ENG"; assert_eq "M-NOEOF — le mutant ignore l'EOF du fd 0 (assistant seul, fd 1 ouvert) : l'assistant ne sort pas de lui-même, il faut le tuer (T12.6c et T14.2 rouges)" "${NF_RES##* fin=}" "vivant"
else sans_effet M-NOEOF; fi

if mutant_eng groupesfiges 's/ms = envoyer_membres(sid, signal.SIGKILL)/ms = None/'; then
  session_entiere m13 "$OUT" "$MUT_ENG"; assert_eq "M-GROUPES-FIGES — le mutant ne tue que les groupes relevés au départ : les travaux nohup, dans leurs propres groupes, survivent (T12.5 rouge)" "$SE_RES" "4 4 oui oui"
else sans_effet M-GROUPES-FIGES; fi

if mutant_eng bloquant 's/os.set_blocking(maitre, False)/os.set_blocking(maitre, True)/'; then
  sourd m10 "$OUT" "$MUT_ENG"; assert_eq "M-ECRITURE-BLOQUANTE — le mutant remet le maître en écriture bloquante : l'assistant et le shell survivent au serveur (T14.1 rouge)" "$SO_RES" "avant=oui oui POST=204 apres=oui oui"
else sans_effet M-ECRITURE-BLOQUANTE; fi
if mutant_eng inherit "s/os.set_inheritable(3, False)/os.set_inheritable(3, True)/"; then
  fd3 m11 "$OUT" "$MUT_ENG"; assert_eq "M-INHERIT — le mutant (descripteur 3 héritable) rougit T11.9 : le shell écrit sur le canal de contrôle" "$FD3_RES" "ABSENT TROUVE"
else sans_effet M-INHERIT; fi
if mutant attente vf-cockpit-terminal-session.mjs "s/if (s.enfant.stdin.writableLength + octets.length > ENTREE_ATTENTE_MAX) return 429;//"; then
  rafale m12 "$MUT_OUT"; assert_eq "M-ATTENTE-NON-BORNEE — le mutant (aucune borne, aucun 429) rougit S3.1 : les 60 POST sont acceptés" "$([ "$(verdict_rafale)" != borne ] && echo rouge || echo "identique : $RAF")" "rouge"
else sans_effet M-ATTENTE-NON-BORNEE; fi
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ]
