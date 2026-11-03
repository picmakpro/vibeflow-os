#!/usr/bin/env bash
# test-cockpit-terminal-pty.sh — assistant PTY et environnement du shell du terminal intégré (TERM-06, TERM-07, TERM-08 orphelins,
# TERM-09 automatisé ; P71-D-03, D-04, D-06, D-14, D-22 puis D-23).
#   T10  environnement filtré (liste noire), shell `-l` lancé dans realpath(lab), TERM/COLORTERM posés, choix du shell, NODE_OPTIONS jamais posé
#   T11  assistant lancé en `python3 -I`, taille par le canal de contrôle (`stty size`), Ctrl-C au premier plan, état `FIN <code>` sur fd 2
#   T12  serveur tué par SIGKILL : assistant, shell et travail d'arrière-plan disparaissent en moins de 5 s
#   T13  programme plein écran témoin, par le flux direct : écran alterné, 256 couleurs, truecolor, SIGWINCH, SIGINT
#   M-*  mutants (copies de la sortie ou du moteur, jamais le module) : M-ENVLARGE, M-CWD, M-SI-ABSENT, M-SANS-I, M-SANS-L, M-SIGINT, M-CTRLC, M-RESIZE, M-NOEOF
# Les attentes cherchent des sous-chaînes (le noyau double les fins de ligne, l'écho ^C précède la sortie). Exit 0 si tout passe, 1 sinon.
set -uo pipefail
libre() { node -e "const s=require('net').createServer().listen(0,'127.0.0.1',()=>{console.log(s.address().port);s.close()})"; } # port libre choisi à l'exécution
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG="$(cd "$SCRIPTS/../skills/cockpit-moteur" && pwd -P)"; TA="$HERE_T/terminal-aux.mjs"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; mkdir -p "$AUX" "$WORK/bin" "$WORK/run" "$WORK/temoins" "$WORK/ailleurs"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$(dirname "$0")/hygiene.sh"; vf_hyg_init
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
// unit.mjs <sortie> <cas> : cas de envShell et de choisirShell importés de la sortie
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url';
const [, , sortie, cas, ...a] = process.argv;
const m = await import(pathToFileURL(sortie + '/vf-cockpit-terminal-env.mjs').href);
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
// pilote.mjs <assistant> <shell> <sortie1> <sortie2> <action>... : lance l'assistant seul (quatre tubes) ; actions : w:<texte> · c:<ligne de contrôle> · e (ferme fd 0) · a:<sous-chaîne attendue sur fd 1>
import { spawn } from 'node:child_process'; import fs from 'node:fs';
const [, , assistant, shell, o1, o2, ...actions] = process.argv; fs.writeFileSync(o1, ''); fs.writeFileSync(o2, '');
const e = spawn('python3', ['-I', assistant, '24', '80', shell], { stdio: ['pipe', 'pipe', 'pipe', 'pipe'] });
e.stdout.on('data', (c) => fs.appendFileSync(o1, c)); e.stderr.on('data', (c) => fs.appendFileSync(o2, c)); e.stdin.on('error', () => {}); e.stdio[3].on('error', () => {});
let fini = null; e.on('close', (code, sig) => { fini = `code=${code} sig=${sig}`; });
const interp = (t) => t.replace(/\\x([0-9a-fA-F]{2})/g, (_, h) => String.fromCharCode(parseInt(h, 16))).replace(/\\n/g, '\n').replace(/\\r/g, '\r');
for (const x of actions) {
  if (x.startsWith('w:')) e.stdin.write(interp(x.slice(2))); else if (x.startsWith('c:')) e.stdio[3].write(interp(x.slice(2)) + '\n'); else if (x === 'e') e.stdin.end();
  else if (x.startsWith('a:')) { const fin = Date.now() + 8000; while (Date.now() < fin && !fs.readFileSync(o1).toString('latin1').includes(x.slice(2))) await new Promise((r) => setTimeout(r, 50)); }
}
for (let i = 0; i < 160 && fini === null; i++) await new Promise((r) => setTimeout(r, 50));
console.log(fini === null ? 'vivant' : fini); if (fini === null) e.kill('SIGKILL'); process.exit(0);
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
chmod +x "$WORK/bin/shell-test" "$WORK/bin/dormir"; export SHELL="$WORK/bin/shell-test"

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
srv() { # srv <sortie> [moteur] -> SRV_PORT SRV_PID SRV_O SRV_OUT ; ENVX = arguments de env, SRV_CWD = dossier courant du serveur (le lab par défaut)
  local o="$1" eng="${2:-$ENG}" lab; lab="$(cd "$1/../.." && pwd)"; [ -n "$SRV_CWD" ] && lab="$SRV_CWD"
  SRVN=$((SRVN+1)); SRV_O="$o"; SRV_OUT="$WORK/serve-$SRVN-$RANDOM.out"; mkdir -p "$o/.cache" "$RUN"; rm -f "$o/.cache/server.json"
  AMORCE="$(amorce_neuve)"; (umask 077; printf '%s' "$AMORCE" > "$o/.cache/terminal-amorce"; printf '%s' "$AMORCE" > "$WORK/amorce.copy")
  ( cd "$lab" && exec env ${ENVX[@]+"${ENVX[@]}"} VF_COCKPIT_ENGINE_DIR="$eng" VF_COCKPIT_SCRIPTS_DIR="$SCRIPTS" VFT_RUN="$RUN" node "$o/serve.mjs" --no-open --terminal --port "$(libre)" > "$SRV_OUT" 2>&1 ) </dev/null >/dev/null 2>&1 &
  SRV_PID=$!; PIDS+=($SRV_PID)
  for _ in $(seq 1 100); do grep -q '"terminal"' "$o/.cache/server.json" 2>/dev/null && break; sleep 0.1; done
}
sj() { node "$AUX/ev.mjs" "$1" < "$SRV_O/.cache/server.json" 2>/dev/null; }
unsrv() { vf_hyg_stop "$SRV_PID"; }
sess() { # sess <nom> <sortie> [moteur] : serveur, échange, flux, attente de l'invite ; code 0 si l'invite est arrivée
  S_NOM="$1"; RUN="$WORK/run/$1"; S_FL="$WORK/flux-$1.bin"; rm -f "$S_FL"; S_FPID=""; S_SEC=""
  srv "$2" "${3:-$ENG}"; S_PID=$SRV_PID; S_Q="$(sj '(j.terminal&&j.terminal.url)||""')"; S_Q="${S_Q##*:}"
  [ -n "$S_Q" ] && read -r _c S_SEC < <(node "$TA" amorcer "$S_Q" "$WORK/amorce.copy" | tr '\n' ' ')
  [[ "$S_SEC" =~ ^[0-9a-f]{64}$ ]] || { S_SEC=""; return 1; }
  node "$TA" flux "$S_Q" "$S_SEC" "onglet-$1" "$S_FL" 40000 > "$WORK/flux-$1.log" 2>&1 & S_FPID=$!
  [ "$(node "$TA" attendre "$S_FL" 'VFP> ' 10000)" = TROUVE ]
}
ent() { node "$TA" entree "$S_Q" "$S_SEC" "onglet-$S_NOM" "$1"; }
tail_() { node "$TA" taille "$S_Q" "$S_SEC" "onglet-$S_NOM" "$1" "$2"; }
wf() { node "$TA" attendre "$S_FL" "$1" "${2:-8000}"; }
fin_sess() { unsrv; [ -n "$S_FPID" ] && { wait "$S_FPID" 2>/dev/null; true; }; }
vivant() { kill -0 "$1" 2>/dev/null && echo oui || echo non; }
attendre_fichier() { local i; for i in $(seq 1 100); do [ -s "$1" ] && return 0; sleep 0.1; done; return 1; }
mutant() { # mutant <nom> <fichier-relatif-à-la-sortie> <expression-sed> [ligne ajoutée] -> MUT_OUT ; code 1 si la cible manque ou si la copie n'a pas changé
  local d="$WORK/mut-$1" f; rm -rf "$d"; mkdir -p "$d"; cp -R "$LAB/.planning" "$d/.planning"; cp -R "$LAB/.vibeflow" "$d/.vibeflow"
  MUT_OUT="$d/.vibeflow/cockpit"; f="$MUT_OUT/$2"; [ -f "$f" ] || return 1
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

echo "=== M-* — mutants du lanceur et du filtre (copies de la sortie) ==="
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

echo "=== M-* — mutants de l'assistant (copies du moteur) ==="
ctrlc() { # ctrlc <nom> <moteur> : lance dormir 30 au premier plan, envoie 0x03 ; rend « <dormir vivant> <shell vivant> »
  sess "$1" "$OUT" "$2"; ent "$WORK/bin/dormir 30 fg\\r" > /dev/null; attendre_fichier "$WORK/run/$1/fg.pid"
  local d b; d="$(cat "$WORK/run/$1/fg.pid" 2>/dev/null)"; b="$(pgrep -P "$(cat "$WORK/run/$1/shell.pid")" | sed -n 1p)"
  ent "\\x03" > /dev/null; sleep 1.5; CC_RES="$(vivant "${d:-0}") $(vivant "${b:-0}")"
  vf_hyg_stop "$d" > /dev/null 2>&1; fin_sess
}
if mutant_eng sigint 's/^                ecrire(maitre, donnees)$/                ecrire(maitre, donnees) if b"\\x03" not in donnees else os.killpg(pid, signal.SIGKILL)/'; then
  ctrlc m6 "$MUT_ENG"; assert_eq "M-SIGINT — le mutant tue le groupe du shell sur 0x03 : le shell ne survit pas, T11.3 rouge" "$CC_RES" "non non"
else sans_effet M-SIGINT; fi
if mutant_eng ctrlc 's/^                ecrire(maitre, donnees)$/                ecrire(maitre, donnees.replace(b"\\x03", b""))/'; then
  ctrlc m7 "$MUT_ENG"; assert_eq "M-CTRLC — le mutant retire 0x03 de l'entrée : le programme de premier plan survit, T11.3 rouge" "$CC_RES" "oui oui"
else sans_effet M-CTRLC; fi
if mutant_eng resize 's/^                taille(maitre, l, c)$/                pass/'; then
  sess m8 "$OUT" "$MUT_ENG"; ent "$C0" > /dev/null; wf SZ0-24x80 > /dev/null; tail_ 50 132 > /dev/null; sleep 0.4; ent "$C1" > /dev/null; R1="$(wf SZ1-50x132 2500)"
  ent "python3 -I $WORK/temoins/plein-ecran.py\\r" > /dev/null; wf PRET > /dev/null; tail_ 50 132 > /dev/null; R2="$(wf 'WINCH 50x132' 2500)"
  assert_eq "M-RESIZE — le mutant ignore les lignes R : ni stty size (T11.2) ni WINCH (T13.3)" "$R1 $R2" "ABSENT ABSENT"; fin_sess
else sans_effet M-RESIZE; fi
if mutant_eng noeof 's/^                    break$/                    entrees.remove(0)/'; then
  orphelins m9 "$OUT" "$MUT_ENG"; assert_eq "M-NOEOF — le mutant ignore l'EOF du fd 0 : l'assistant et le shell survivent (T12.4 rouge)" "$O_RES" "5 survivants"
else sans_effet M-NOEOF; fi

vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ]
