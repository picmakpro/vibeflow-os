#!/usr/bin/env bash
# test-cockpit-lancer-pty.sh — lancement d'une ligne au shell par l'assistant PTY et la session du terminal (LANC-06, LANC-07 ; P72-D-01, D-13, D-14).
# Arguments : (aucun) tout · `pty` sections L et mutants de l'assistant · `session` sections J et mutants de la session. Durée : quelques minutes (vrais shells).
#   L0  la fixture : invite VFP> et faux `claude` dans le PATH du shell       L1  shell au repos : `LANCE ok`, ligne à l'invite sans retour chariot, retour chariot HUMAIN = argv exact
#   L2  lecteur brut au premier plan : 0 octet reçu                           L3  `sleep` canonique au premier plan : aucun Ctrl-C        L4  le test se rejoue après la fin du programme
#   L5  tables hostile / invalide / 256 octets (alphabet fermé, correspondance TOTALE, préfixe, longueur)                 L6  ligne fragmentée en deux écritures
#   L7  le canal `R` de taille intact                                         L8  grammaire fermée du descripteur 2       L9  shell sourd : la file ne grossit pas
#   J1..J7  `sessions.lancer` : transport, délai de 2 s, file FIFO, arrêt, analyse de `FIN`
#   M-* onze mutants : M-PREMIER-PLAN, M-CTRLC-AVEUGLE, M-ALPHABET-PY, M-FIN-DE-LIGNE-PY, M-PREFIXE-PY, M-HEX-BORNE, M-ENTREE-AUTO, M-RESTE-TRONQUE, M-FILE-NON-BORNEE, M-JS-SANS-ATTENTE, M-FIFO
# Les verdicts se lisent sur le descripteur 2 de l'assistant, jamais sur la sortie du shell. Shells exercés : bash puis zsh s'il est installé (imprimés ; la suite échoue si aucun n'a tourné).
# Aucun port, aucun serveur HTTP. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
MODE="${1:-tout}"; case "$MODE" in tout|pty|session) ;; *) echo "usage : $0 [pty|session]" >&2; exit 64 ;; esac
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"; HERE_T="$(cd "$(dirname "$0")" && pwd)"
ENG0="$(cd "$SCRIPTS/../skills/cockpit-moteur" && pwd -P)"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"; AUX="$WORK/aux"; HOMEJ="$WORK/home"
mkdir -p "$AUX" "$WORK/bin" "$WORK/run" "$WORK/temoins" "$WORK/t" "$WORK/sed" "$HOMEJ"
PIDS=(); cleanup() { vf_hyg_fin; [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT
. "$HERE_T/hygiene.sh"; vf_hyg_init
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$(court "$3")]"; echo "     obtenu:  [$(court "$2")]"; FAIL=$((FAIL+1)); fi; }
court() { if [ "${#1}" -gt 300 ]; then printf '%s […] %s' "${1:0:140}" "${1: -140}"; else printf '%s' "$1"; fi; }
sans_effet() { assert_eq "$1 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; }
rougit() { assert_eq "$1" "$([ "$2" != "$3" ] && echo rouge || echo "identique : $2")" "rouge"; echo "     obtenu sous le mutant : [$(court "$2")]"; } # rougit <libellé> <obtenu sous le mutant> <attendu sain>

# Le moteur est copié sous $WORK : l'assistant porte alors la marque de la suite (hygiène : un survivant est vu et nommé).
ENGC="$WORK/eng-ref"; cp -R "$ENG0" "$ENGC"; ASSIST="$ENGC/terminal/vf-cockpit-pty.py"
UUID="$(node -e "console.log(require('crypto').randomUUID())")"
PRE="claude --session-id '"
REF="${PRE}${UUID}' -n 'vf-phase-72-fiabilite' --permission-mode 'acceptEdits' '/vf-dev Cadre la Phase 72 du compartiment fiabilite'"
ARGV_ATTENDU="--session-id|${UUID}|-n|vf-phase-72-fiabilite|--permission-mode|acceptEdits|/vf-dev Cadre la Phase 72 du compartiment fiabilite"

# ---- fixture : HOME jetable (invite, PATH), faux claude, dormir, shell sourd, lecteur brut ----
printf "PS1='VFP> '\nPATH=\"%s/bin:\$PATH\"; export PATH\nunset PROMPT_COMMAND\n" "$WORK" > "$HOMEJ/.bash_profile"
printf "PROMPT='VFP> '\nRPROMPT=''\nunsetopt PROMPT_SP\nPATH=\"%s/bin:\$PATH\"; export PATH\n" "$WORK" > "$HOMEJ/.zshrc"
cat > "$WORK/bin/claude" <<'SH'
#!/bin/sh
printf '%s\0' "$@" > "$VFT_RUN/claude.argv"
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
cat > "$WORK/temoins/horodate.py" <<'PY'
# shell « horodateur » : mode brut (Ctrl-C n'est qu'un octet), consigne chaque lecture du terminal (heure, hexadécimal) dans horo.log ; sort sur Q
import os, sys, time, tty
r = os.environ['VFT_RUN']
tty.setraw(0)
while True:
    d = os.read(0, 4096)
    if not d:
        break
    with open(r + '/horo.log', 'a') as f:
        f.write('%.6f %s\n' % (time.time(), d.hex()))
    if b'Q' in d:
        break
PY
printf '#!/bin/sh\necho $$ > "$VFT_RUN/horo.pid"\nexec python3 -I %s/temoins/horodate.py\n' "$WORK" > "$WORK/bin/shell-horodate"
chmod +x "$WORK/bin/claude" "$WORK/bin/dormir" "$WORK/bin/shell-sourd" "$WORK/bin/shell-horodate"
cat > "$WORK/temoins/lecteur.py" <<'PY'
# lecteur brut : enregistre chaque octet reçu dans lecteur.recu, sort sur Q
import os, tty
r = os.environ['VFT_RUN']
open(r + '/lecteur.pid', 'w').write(str(os.getpid()))
open(r + '/lecteur.recu', 'wb').close()
tty.setraw(0)
os.write(1, b'LECTEUR-PRET\n')
while True:
    d = os.read(0, 4096)
    if not d:
        break
    with open(r + '/lecteur.recu', 'ab') as f:
        f.write(d)
    if b'Q' in d:
        break
PY

# ---- aides Node ----
cat > "$AUX/aide.mjs" <<'JS'
// aide.mjs : cnt <fichier> <sous-chaine> · argv <fichier> (arguments NUL -> « a|b|c » ou « absent »)
import fs from 'node:fs';
const [, , cmd, ...a] = process.argv; const lire = (f) => { try { return fs.readFileSync(f).toString('latin1'); } catch { return null; } };
if (cmd === 'cnt') { const t = lire(a[0]) || ''; console.log(a[1] ? t.split(a[1]).length - 1 : 0); }
else if (cmd === 'argv') { const t = lire(a[0]); console.log(t === null ? 'absent' : t.split('\0').slice(0, -1).join('|')); }
JS
cat > "$AUX/pilote.mjs" <<'JS'
// pilote.mjs <assistant> <shell> <sortie1> <sortie2> <action>... : l'assistant seul (quatre tubes), dossier courant = $VFT_RUN, HOME = $VFT_HOME, terminal de 500 colonnes.
// w:<texte> entrée humaine (descripteur 0) · C:<texte> écriture BRUTE sur le descripteur 3 · c:<texte> idem + saut de ligne · F:<fichier> contenu d'un fichier sur le descripteur 3
// G:<fichier>:<ms> chaque ligne du fichier sur le descripteur 3, <ms> entre deux · s:<ms> · e (ferme fd 0) · t (SIGTERM)
// a:<sous-chaîne> attente sur fd 1 · A:<sous-chaîne> attente sur fd 2 · N:<n> attente de n lignes sur fd 2 · b:<n>:<sous-chaîne> n occurrences sur fd 1 · f:<fichier> attente d'un fichier non vide
// p:<fichier-pid>=<étiquette> et z:<fichier>=<étiquette> (oui|non vivant · taille|absent) et v:<étiquette> (assistant vivant|fini) consignent dans <sortie1>.res ; @RUN@ = $VFT_RUN
import { spawn } from 'node:child_process'; import fs from 'node:fs';
const [, , assistant, shell, o1, o2, ...actions] = process.argv; fs.writeFileSync(o1, ''); fs.writeFileSync(o2, ''); fs.writeFileSync(o1 + '.res', '');
const env = { ...process.env, HOME: process.env.VFT_HOME, ZDOTDIR: process.env.VFT_HOME, TERM: 'xterm-256color', BASH_SILENCE_DEPRECATION_WARNING: '1' }; delete env.TERM_PROGRAM; delete env.TERM_SESSION_ID;
const e = spawn('python3', ['-I', assistant, '24', '500', shell], { cwd: process.env.VFT_RUN, env, stdio: ['pipe', 'pipe', 'pipe', 'pipe'] });
e.stdout.on('data', (c) => fs.appendFileSync(o1, c)); e.stderr.on('data', (c) => fs.appendFileSync(o2, c)); e.stdin.on('error', () => {}); e.stdio[3].on('error', () => {});
let fini = null; e.on('close', (code, sig) => { fini = `code=${code} sig=${sig}`; });
const lire = (f) => { try { return fs.readFileSync(f).toString('latin1'); } catch { return ''; } };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const attendre = async (cond, ms = 8000) => { const fin = Date.now() + ms; while (Date.now() < fin && !cond()) await sleep(40); };
const interp = (t) => t.replace(/\\x([0-9a-fA-F]{2})/g, (_, h) => String.fromCharCode(parseInt(h, 16))).replace(/\\n/g, '\n').replace(/\\r/g, '\r');
const note = (l) => fs.appendFileSync(o1 + '.res', l + '\n');
for (let x of actions) {
  x = x.split('@RUN@').join(process.env.VFT_RUN);
  if (x.startsWith('w:')) e.stdin.write(Buffer.from(interp(x.slice(2)), 'latin1'));
  else if (x.startsWith('C:')) e.stdio[3].write(Buffer.from(interp(x.slice(2)), 'latin1'));
  else if (x.startsWith('c:')) e.stdio[3].write(interp(x.slice(2)) + '\n');
  else if (x.startsWith('F:')) e.stdio[3].write(fs.readFileSync(x.slice(2)));
  else if (x.startsWith('G:')) { const i = x.lastIndexOf(':'); for (const l of lire(x.slice(2, i)).split('\n').filter(Boolean)) { e.stdio[3].write(l + '\n'); await sleep(Number(x.slice(i + 1))); } }
  else if (x.startsWith('s:')) await sleep(Number(x.slice(2)));
  else if (x === 'e') e.stdin.end(); else if (x === 't') e.kill('SIGTERM');
  else if (x.startsWith('a:')) await attendre(() => lire(o1).includes(x.slice(2)));
  else if (x.startsWith('A:')) await attendre(() => lire(o2).includes(x.slice(2)));
  else if (x.startsWith('N:')) await attendre(() => lire(o2).split('\n').filter(Boolean).length >= Number(x.slice(2)));
  else if (x.startsWith('b:')) { const m = /^b:(\d+):([\s\S]*)$/.exec(x); await attendre(() => lire(o1).split(m[2]).length - 1 >= Number(m[1])); }
  else if (x.startsWith('f:')) await attendre(() => lire(x.slice(2)).length > 0);
  else if (x.startsWith('p:') || x.startsWith('z:')) {
    const i = x.lastIndexOf('='); const f = x.slice(2, i), et = x.slice(i + 1);
    if (x[0] === 'p') { let v = 'non'; try { process.kill(Number(lire(f).trim()), 0); v = 'oui'; } catch {} note(`${et}=${v}`); }
    else { let v = 'absent'; try { v = String(fs.statSync(f).size); } catch {} note(`${et}=${v}`); }
  } else if (x.startsWith('v:')) note(`${x.slice(2)}=${fini === null ? 'vivant' : 'fini'}`);
}
for (let i = 0; i < 160 && fini === null; i++) await sleep(50);
console.log(fini === null ? 'vivant' : fini); if (fini === null) e.kill('SIGKILL'); process.exit(0);
JS
cat > "$AUX/table.mjs" <<'JS'
// table.mjs <cas> <fichier...> : fabrique les lignes `L <hex>` envoyées au descripteur 3 et les verdicts attendus (un par ligne, `LANCE …`)
import fs from 'node:fs';
const [, , cas, ...a] = process.argv; const uuid = process.env.VFT_UUID, ref = process.env.VFT_REF; const PRE = "claude --session-id '";
const hex = (b) => Buffer.from(b, 'latin1').toString('hex'); const L = (b) => `L ${hex(b)}`;
const ecrire = (f, lignes) => fs.writeFileSync(f, lignes.join('\n') + '\n');
const classe = /^[A-Za-z0-9 ._:/'-]+$/;
if (cas === 'ref') ecrire(a[0], [L(ref)]);
else if (cas === 'l51') { // alphabet : chaque ligne porte un caractère hors alphabet, ou un saut de ligne final
  const base = (x) => `${PRE}a${x}'`; const hostiles = [';touch M;', '$(touch M)', '`touch M`', '|touch M', '&touch M', '<M', '>M', '\\', '!', '"', '*', '?', '~', '(', ')', '{', '}', '[', ']', '#', '\x00', '\t', '\r', '\x7f', '\x1b'];
  const hauts = Array.from({ length: 128 }, (_, i) => String.fromCharCode(128 + i)).join('');
  const l = hostiles.map(base); l.push(`${PRE}a'\n`, `${PRE}a'\r`, `${PRE}a'\n\n`, base(hauts), base('\u00ff'));
  ecrire(a[0], l.map(L)); ecrire(a[1], l.map(() => 'LANCE alphabet'));
} else if (cas === 'l52') { // forme : hexadécimal impair, non hexadécimal, `L` seul, trop d'arguments, trop long, préfixe faux, casse, apostrophe finale absente
  const long = PRE + 'a'.repeat(401 - PRE.length - 1) + "'";
  const l = ['L abc', 'L zz11', 'L', 'L ', `L ${hex(ref)} ${hex(ref)}`, `L ${hex(long)}`, L("claude --resume 'a'"), L("Claude --session-id 'a'"), L("claude --session-id 'a"), L('ls'), L("claude --session-id 'a' "), L(PRE)];
  ecrire(a[0], l); ecrire(a[1], l.map(() => 'LANCE invalide'));
} else if (cas === 'l53') { // propriété différentielle : les 256 octets, le verdict de l'assistant égale la classe évaluée par Node (lecteur brut au premier plan)
  const l = [], v = [];
  for (let b = 0; b < 256; b++) { const t = `${PRE}a${String.fromCharCode(b)}'`; l.push(L(t)); v.push(classe.test(t) ? 'LANCE premier-plan' : 'LANCE alphabet'); }
  ecrire(a[0], l); ecrire(a[1], v);
} else if (cas === 'l6') { // 390 caractères, deux écritures : `L ` + 500 premiers caractères hexadécimaux, puis le reste
  const t = PRE + 'a'.repeat(390 - PRE.length - 1) + "'"; const h = hex(t); fs.writeFileSync(a[0], `L ${h.slice(0, 500)}`); fs.writeFileSync(a[1], `${h.slice(500)}\n`);
} else if (cas === 'l8') { ecrire(a[0], [L(ref), L(`${PRE}a$(touch M)'`), 'L abc']);
} else if (cas === 'l9') { const t = PRE + 'a'.repeat(390 - PRE.length - 1) + "'"; ecrire(a[0], Array.from({ length: 60 }, () => L(t))); }
JS
export VFT_UUID="$UUID" VFT_REF="$REF"

# ---- pilotage ----
RUNN=0; P_O1=""; P_O2=""; P_RES=""; P_FIN=""; RUN=""
pil() { # pil <shell> <action>... -> P_O1 P_O2 P_RES P_FIN RUN (l'assistant seul, un shell réel)
  local sh="$1"; shift; RUNN=$((RUNN+1)); RUN="$WORK/run/r$RUNN"; mkdir -p "$RUN"
  P_O1="$WORK/p$RUNN.1"; P_O2="$WORK/p$RUNN.2"; P_RES="$P_O1.res"
  P_FIN="$(VFT_RUN="$RUN" VFT_HOME="$HOMEJ" node "$AUX/pilote.mjs" "$ASSIST" "$sh" "$P_O1" "$P_O2" "$@" 2>&1)"
}
fd2() { tr -d '\r' < "$P_O2" | tr '\n' '|'; }
rv() { awk -F= -v k="$1" '$1==k{print $2}' "$P_RES"; }
cnt() { node "$AUX/aide.mjs" cnt "$1" "$2"; }
ref_l="$WORK/t/ref.L"; node "$AUX/table.mjs" ref "$ref_l"
node "$AUX/table.mjs" l51 "$WORK/t/l51.L" "$WORK/t/l51.exp"; node "$AUX/table.mjs" l52 "$WORK/t/l52.L" "$WORK/t/l52.exp"; node "$AUX/table.mjs" l53 "$WORK/t/l53.L" "$WORK/t/l53.exp"
node "$AUX/table.mjs" l6 "$WORK/t/l6.1" "$WORK/t/l6.2"; node "$AUX/table.mjs" l8 "$WORK/t/l8.L"; node "$AUX/table.mjs" l9 "$WORK/t/l9.L"
exp() { tr '\n' '|' < "$WORK/t/$1.exp"; }
N51="$(wc -l < "$WORK/t/l51.L" | tr -d ' ')"; N52="$(wc -l < "$WORK/t/l52.L" | tr -d ' ')"
PYR="python3 -I $WORK/temoins/lecteur.py"
SHELLS="/bin/bash"; [ -x /bin/bash ] || SHELLS="$(command -v bash)"
ZSH="$(command -v zsh || true)"; [ -n "$ZSH" ] && SHELLS="$SHELLS $ZSH"
echo "Shells exercés : $SHELLS$([ -z "$ZSH" ] && echo ' (zsh absent)')"

# ---- sondes (chacune pose ses résultats dans des variables ; les mutants rejouent les mêmes) ----
t_l1() { # L0 + L1 : commande du faux claude, ligne envoyée au repos, retour chariot humain
  pil "$1" 'a:VFP> ' 'w:echo CV-$(command -v claude)\r' "a:CV-$WORK/bin/claude" 'b:2:VFP> ' "F:$ref_l" 'N:1' 's:1000' 'z:@RUN@/claude.argv=ARGV1' 'w:\r' 'f:@RUN@/claude.argv' 's:300' 'e'
  L0_CV="$([ "$(cnt "$P_O1" "CV-$WORK/bin/claude")" -ge 1 ] && echo oui || echo non)"; L1_V="$(fd2)"; L1_A1="$(rv ARGV1)"
  L1_VU="$([ "$(cnt "$P_O1" "$UUID")" -ge 1 ] && echo vue || echo non)"; L1_ARGV="$(node "$AUX/aide.mjs" argv "$RUN/claude.argv")"
}
t_l2() { # lecteur brut au premier plan
  pil "$1" 'a:VFP> ' "w:$PYR\\r" 'a:LECTEUR-PRET' "F:$ref_l" 'N:1' 's:500' 'z:@RUN@/lecteur.recu=R0' 'p:@RUN@/lecteur.pid=V0' 'w:x' 's:400' 'z:@RUN@/lecteur.recu=R1' 'w:Q' 's:300' 'e'
  L2_1="$(fd2) $(rv R0) $(rv V0)"; L2_W="$(rv R1)"
}
t_l3() { # sleep canonique au premier plan, Ctrl-C humain, puis nouvel essai (L4)
  pil "$1" 'a:VFP> ' "w:$WORK/bin/dormir 30 fg\\r" 'f:@RUN@/fg.pid' "F:$ref_l" 'N:1' 's:1000' 'p:@RUN@/fg.pid=D1' 'w:\x03' 'b:2:VFP> ' 's:400' 'p:@RUN@/fg.pid=D2' "F:$ref_l" 'N:2' 'e'
  L3_1="$(fd2 | cut -d'|' -f1) $(rv D1)"; L3_W="$(rv D2)"; L4_1="$(fd2 | cut -d'|' -f2)"
}
t_table() { # t_table <shell> <fichier lignes> <n> : lignes envoyées au shell au repos, puis un retour chariot humain
  pil "$1" 'a:VFP> ' "F:$2" "N:$3" 's:500' 'w:\r' 's:1000' 'z:@RUN@/claude.argv=ARGV' 'z:@RUN@/M=MARQUE' 'e'
  T_RES="$(fd2) | $(rv ARGV) $(rv MARQUE)"
}
t_l53() { # les 256 octets, lecteur brut au premier plan
  pil "$1" 'a:VFP> ' "w:$PYR\\r" 'a:LECTEUR-PRET' "F:$WORK/t/l53.L" 'N:256' 's:500' 'z:@RUN@/lecteur.recu=R0' 'p:@RUN@/lecteur.pid=V0' 'w:Q' 's:300' 'e'
  local egal=different; [ "$(fd2)" = "$(exp l53)" ] && egal=egal; L53_RES="$egal $(rv R0) $(rv V0)"
}
t_l6() { pil "$1" 'a:VFP> ' "F:$WORK/t/l6.1" 's:300' "F:$WORK/t/l6.2" 'N:1' 's:300' 'e'; L6_V="$(fd2)"; }
t_l7() { pil "$1" 'a:VFP> ' "F:$ref_l" 'N:1' 'c:R 50 132' 's:400' 'w:\x03' 's:400' 'w:echo SZ-$(stty size | tr " " x)\r' 'a:SZ-50x132' 'w:exit 0\r' 's:500'; L7_OK="$([ "$(cnt "$P_O1" SZ-50x132)" -ge 1 ] && echo oui || echo non)"; }
t_l8() {
  pil "$1" 'a:VFP> ' "F:$WORK/t/l8.L" 'N:3' 's:300' 'w:\x03' 's:400' 'w:echo LANCE" "ok\r' 'a:LANCE ok' 's:300' 'w:exit 0\r'
  L8_F="$(fd2)"; L8_S="$([ "$(cnt "$P_O1" 'LANCE ok')" -ge 1 ] && echo oui || echo non)"
  L8_G="$(tr -d '\r' < "$P_O2" | grep -a -c -v -E '^(LANCE (ok|premier-plan|alphabet|invalide)|FIN [0-9]+|SIG [0-9]+)$')"
}
t_l11() { # un programme prend le premier plan PENDANT l'attente qui suit Ctrl-C (entrée humaine 5 ms après le L) : rien n'est écrit dans le programme
  pil "$1" 'a:VFP> ' "F:$ref_l" 's:5' "w:$PYR\\r" 'N:1' 'a:LECTEUR-PRET' 's:500' 'z:@RUN@/lecteur.recu=R0' 'p:@RUN@/lecteur.pid=V0' 'w:Q' 's:300' 'e'
  L11_RES="$(fd2) $(rv R0) $(rv V0)"
}
t_l12() { # shell brut horodateur : Ctrl-C SEUL, puis la ligne dans une écriture distincte, au moins 0,2 s plus tard (le shell ne produit aucune sortie : attente maximale)
  pil "$WORK/bin/shell-horodate" 'f:@RUN@/horo.pid' 's:300' "F:$ref_l" 'N:1' 's:300' 'w:Q' 's:300' 'e'
  L12_RES="$(fd2) $(node -e "
const L = require('fs').readFileSync(process.argv[1] + '/horo.log', 'utf8').split('\n').filter(Boolean).map((l) => l.split(' ')); const ref = Buffer.from(process.env.VFT_REF, 'latin1').toString('hex');
const c = L.filter((x) => x[1] !== '51');
console.log(c.length + ' ' + (c[0] && c[0][1]) + ' ' + (c[1] && c[1][1] === ref) + ' ' + (c.length > 1 && Number(c[1][0]) - Number(c[0][0]) >= 0.2));
" "$RUN" 2>&1)"
}
t_l9() {
  pil "$WORK/bin/shell-sourd" 'f:@RUN@/sourd.pid' 's:700' "G:$WORK/t/l9.L:10" 'N:60' 's:300' 'v:A' 'e'
  L9_PP="$(grep -a -c '^LANCE premier-plan$' "$P_O2")"; L9_T="$(grep -a -c '^LANCE ' "$P_O2")"; L9_RES="$([ "$L9_PP" -ge 1 ] && echo oui || echo "non($L9_PP)") $L9_T $(rv A) $P_FIN"
}
# attendus sains (calculés une fois ; les mutants comparent leur résultat à ces valeurs)
OK_L1_ARGV="$ARGV_ATTENDU"

mut_pty() { # mut_pty <nom> <script sed> -> MUT_ASSIST ; code 1 si la cible manque ou si la copie n'a pas changé
  local d="$WORK/eng-$1" f; rm -rf "$d"; cp -R "$ENG0" "$d"; f="$d/terminal/vf-cockpit-pty.py"; MUT_ASSIST="$f"
  cp "$f" "$f.orig"; sed -i.bak -f "$2" "$f"; local r=0; cmp -s "$f" "$f.orig" && r=1; rm -f "$f.orig" "$f.bak"; return $r
}

if [ "$MODE" != session ]; then
echo "=== L — l'assistant seul : premier plan, sans retour chariot, revalidation, FIFO (LANC-06, LANC-07) ==="
NSH=0
for SH in $SHELLS; do
  NSH=$((NSH+1)); B="$(basename "$SH")"; echo "--- shell : $SH ---"
  t_l1 "$SH"
  assert_eq "L0.1 [$B] — témoin de fixture : l'invite VFP> paraît et « command -v claude » rend le faux claude du PATH" "$L0_CV" "oui"
  assert_eq "L1.1 [$B] — shell au repos : « LANCE ok »" "$L1_V" "LANCE ok|"
  assert_eq "L1.2 [$B] — la ligne est à l'invite (l'UUID figure dans la sortie) et le faux claude n'a PAS tourné après 1 s (aucun retour chariot ajouté)" "$L1_VU $L1_A1" "vue absent"
  assert_eq "L1.3 [$B] — un retour chariot HUMAIN (fd 0) exécute la ligne : argv exact, octet pour octet" "$L1_ARGV" "$OK_L1_ARGV"
  t_l2 "$SH"
  assert_eq "L2.1 [$B] — lecteur brut au premier plan : « LANCE premier-plan », 0 octet reçu, lecteur vivant" "$L2_1" "LANCE premier-plan| 0 oui"
  assert_eq "L2.w [$B] — témoin : un octet humain par le descripteur 0 arrive dans lecteur.recu" "$L2_W" "1"
  t_l3 "$SH"
  assert_eq "L3.1 [$B] — sleep en mode canonique au premier plan : « LANCE premier-plan » et le programme vit encore après 1 s (aucun Ctrl-C)" "$L3_1" "LANCE premier-plan oui"
  assert_eq "L3.w [$B] — témoin : un Ctrl-C humain tue le programme" "$L3_W" "non"
  assert_eq "L4.1 [$B] — après la fin du programme, retour de l'invite puis « LANCE ok » : le test se rejoue" "$L4_1" "LANCE ok"
  t_table "$SH" "$WORK/t/l51.L" "$N51"
  assert_eq "L5.1 [$B] — table hostile ($N51 lignes : ; \$( ) \` | & < > \\ ! \" * ? ~ ( ) { } [ ] # NUL tab CR, saut de ligne final, octets 0x80-0xFF) : « LANCE alphabet » dans l'ordre, rien tapé : ni argv ni marqueur après un retour chariot humain" "$T_RES" "$(exp l51) | absent absent"
  t_table "$SH" "$WORK/t/l52.L" "$N52"
  assert_eq "L5.2 [$B] — table invalide (hex impair, non hex, L seul, trop d'arguments, 802 caractères hex, préfixe faux, casse, apostrophe finale absente, préfixe nu) : « LANCE invalide » dans l'ordre, rien exécuté" "$T_RES" "$(exp l52) | absent absent"
  t_l53 "$SH"
  assert_eq "L5.3 [$B] — propriété différentielle : pour chacun des 256 octets, le verdict égale la classe [A-Za-z0-9 ._:/'-] évaluée par Node (alphabet -> premier-plan : le lecteur occupe le premier plan ; hors alphabet -> alphabet), 0 octet reçu, lecteur vivant" "$L53_RES" "egal 0 oui"
  t_l6 "$SH"
  assert_eq "L6.1 [$B] — ligne de 390 caractères en deux écritures (500 caractères hex, 300 ms, le reste) : « LANCE ok »" "$L6_V" "LANCE ok|"
  t_l7 "$SH"
  assert_eq "L7.1 [$B] — une ligne « R 50 132 » après un L redimensionne toujours (stty size = 50 132)" "$L7_OK" "oui"
  t_l8 "$SH"
  assert_eq "L8.1 [$B] — grammaire fermée du descripteur 2 : autant de lignes que de lignes L envoyées (3) puis FIN 0, aucune autre ligne" "$L8_F $L8_G" "LANCE ok|LANCE alphabet|LANCE invalide|FIN 0| 0"
  assert_eq "L8.2 [$B] — un shell qui imprime « LANCE ok » ne produit aucune ligne de plus sur le descripteur 2 (témoin : la sortie du shell, descripteur 1, la porte)" "$L8_S $L8_F" "oui LANCE ok|LANCE alphabet|LANCE invalide|FIN 0|"
done
assert_eq "L0.0 — au moins un shell a été exercé (anti-vert-à-vide)" "$([ "$NSH" -ge 1 ] && echo oui || echo non)" "oui"
t_l9
assert_eq "L9.1 — shell sourd (stty raw -echo puis exec sleep) : 60 lignes de 390 caractères, au moins un « LANCE premier-plan » (la file ne grossit pas), 60 réponses, l'assistant reste vivant puis sort de lui-même" "$L9_RES" "oui 60 vivant code=0 sig=null"

echo "=== L10 — écriture au PTY refusée : jamais « LANCE ok » pour une ligne non poussée (ST-4) ==="
cat > "$AUX/ecriture.py" <<'PY'
# ecriture.py <assistant> <ligne> : importe l'assistant, force le test du premier plan à « libre » et fait échouer pousser() (tube rompu, EIO) ; un témoin réussit
import importlib.util, sys
spec = importlib.util.spec_from_file_location('assist', sys.argv[1]); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
hexa = sys.argv[2].encode().hex().encode()
m.premier_plan_libre = lambda maitre, pid: True
def casse(fd, t): raise BrokenPipeError(32, 'tube rompu')
def eio(fd, t): raise OSError(5, 'EIO')
def passe(fd, t): del t[:]
res = []
for nom, f in (('casse', casse), ('eio', eio), ('temoin', passe)):
    m.pousser = f; v = bytearray(); r = m.lancer_ligne(hexa, -1, 1, v); res.append('%s:%s:%d' % (nom, r, len(v)))
sorties = []; m.statut = lambda fd, t: sorties.append(t); m.pousser = casse
m.DIFFEREE['ligne'] = None  # le témoin ci-dessus a laissé une ligne différée : l'état est remis à zéro, ce cas-ci juge l'échec d'écriture
m.lire_controle(b'L ' + hexa + b'\n', -1, 1, bytearray())
print(' '.join(res) + ' | ' + ';'.join(sorties))
PY
ecr() { python3 -I "$AUX/ecriture.py" "$1" "$REF" 2>&1 | tail -1; }
L10_ATT="casse:ecriture:0 eio:ecriture:0 temoin:ok:0 | LANCE ecriture"
assert_eq "L10.1 — un échec d'écriture (tube rompu, EIO) rend le motif « ecriture » et ne laisse rien en file ; la réponse du descripteur 2 est « LANCE ecriture », jamais « LANCE ok » (témoin : une écriture réussie rend ok)" "$(ecr "$ASSIST")" "$L10_ATT"

echo "=== L11 / L12 — l'attente entre Ctrl-C et la ligne : premier plan retesté, écritures distinctes et espacées, échec d'écriture différée ==="
cat > "$AUX/differe.py" <<'PY'
# differe.py <assistant> <ligne> : fonctions de l'assistant seules, horloge passée en argument (aucun shell, aucun délai réel)
import importlib.util, sys, time
spec = importlib.util.spec_from_file_location('assist', sys.argv[1]); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
lig = sys.argv[2].encode(); hexa = lig.hex().encode()
m.premier_plan_libre = lambda maitre, pid: True
sorties = []; m.statut = lambda fd, t: sorties.append(t)
ecr = []
def trace(fd, t): ecr.append(bytes(t)); del t[:]
def casse(fd, t): raise BrokenPipeError(32, 'tube rompu')
def amorcer(v):
    m.DIFFEREE.update(ligne=None, suite=[], vu=0.0); del ecr[:]; del sorties[:]; m.pousser = trace
    return m.lancer_ligne(hexa, -1, 1, v)
res = []
v = bytearray(); r = amorcer(v); m.lire_controle(b'L ' + hexa + b'\n', -1, 1, v); m.pousser = casse; m.liberer_ligne(v, -1, 1, time.time() + 1)  # (a) la ligne différée ne peut pas être écrite
res.append('a:%s:%s:%s:%d' % (r, ','.join(sorties), ecr == [b'\x03'], len(v)))
v = bytearray(); r = amorcer(v); m.premier_plan_libre = lambda maitre, pid: False; m.liberer_ligne(v, -1, 1, time.time() + 1); m.premier_plan_libre = lambda maitre, pid: True  # (b) un programme a pris le terminal
res.append('b:%s:%s:%s:%d' % (r, ','.join(sorties), ecr == [b'\x03'], len(v)))
v = bytearray(); r = amorcer(v); t0 = m.DIFFEREE['t0']  # (c) horloge explicite : ni sortie ni 0,3 s -> rien ; sortie sans calme -> rien ; calme -> la ligne, seule, après Ctrl-C
m.liberer_ligne(v, -1, 1, t0 + 0.001); c1 = (len(ecr), len(sorties))
m.DIFFEREE['vu'] = t0 + 0.01; m.liberer_ligne(v, -1, 1, t0 + 0.02); c2 = (len(ecr), len(sorties))
m.liberer_ligne(v, -1, 1, t0 + 0.05)
res.append('c:%s:%s:%s:%s' % (c1, c2, ecr == [b'\x03', lig], ','.join(sorties)))
v = bytearray(); r = amorcer(v); t0 = m.DIFFEREE['t0']; m.liberer_ligne(v, -1, 1, t0 + 0.31)  # (d) sans aucune sortie : attente maximale
res.append('d:%s:%s' % (ecr == [b'\x03', lig], ','.join(sorties)))
v = bytearray(b'x'); m.DIFFEREE.update(ligne=None, suite=[], vu=0.0); del ecr[:]; m.pousser = trace  # (e) une entrée déjà en attente d'écriture : refus, rien de plus en file
r = m.lancer_ligne(hexa, -1, 1, v)
res.append('e:%s:%s:%s:%d' % (r, m.DIFFEREE['ligne'] is None, ecr == [], len(v)))
print(' '.join(res))
PY
L11_ATT="a:ok:LANCE ecriture,LANCE premier-plan:True:0 b:ok:LANCE premier-plan:True:0 c:(1, 0):(1, 0):True:LANCE ok d:True:LANCE ok e:premier-plan:True:True:1"
dif() { python3 -I "$AUX/differe.py" "$1" "$REF" 2>&1 | tail -1; }
assert_eq "L11.1 — fonctions seules, horloge explicite : (a) échec d'écriture de la ligne DIFFÉRÉE -> « LANCE ecriture » puis la demande en file, jamais « ok » ; (b) premier plan perdu pendant l'attente -> « LANCE premier-plan » et seul Ctrl-C est écrit ; (c) ni sortie ni 0,3 s -> rien, sortie sans 30 ms de calme -> rien, calme -> la ligne dans une écriture distincte de Ctrl-C ; (d) sans sortie, 0,31 s suffit ; (e) entrée déjà en attente -> refus sans rien mettre en file" "$(dif "$ASSIST")" "$L11_ATT"
for SH in $SHELLS; do
  B="$(basename "$SH")"; t_l11 "$SH"
  assert_eq "L11.2 [$B] — un programme (lecteur brut) lancé 5 ms après le L prend le premier plan pendant l'attente : « LANCE premier-plan », 0 octet reçu par le programme (ni la ligne), lecteur vivant" "$L11_RES" "LANCE premier-plan| 0 oui"
done
t_l12
assert_eq "L12.1 — shell brut horodateur : « LANCE ok », deux lectures du terminal seulement, la première est Ctrl-C (03) SEULE, la seconde est exactement la ligne, au moins 0,2 s plus tard" "$L12_RES" "LANCE ok|FIN 0| 2 03 true true"

echo "=== M-* — mutants de l'assistant (copies du moteur, bash seul) ==="
SAV="$SHELLS"; SHELLS="/bin/bash"; [ -x /bin/bash ] || SHELLS="$(command -v bash)"; MSH="${SHELLS%% *}"; ASSIST0="$ASSIST"
cat > "$WORK/sed/premier.sed" <<'SED'
s|^    if not premier_plan_libre(maitre, pid):$|    if False:|
SED
cat > "$WORK/sed/ctrlc.sed" <<'SED'
/^    if not premier_plan_libre(maitre, pid):$/{
n
s|^.*$|        vers_shell += CTRL_C; return 'premier-plan'|
}
SED
cat > "$WORK/sed/alphabet.sed" <<'SED'
s|^    if not ALPHABET_LIGNE.fullmatch(ligne):$|    if False:|
SED
cat > "$WORK/sed/fin.sed" <<'SED'
s|^    if not ALPHABET_LIGNE.fullmatch(ligne):$|    if not re.match(rb"^[A-Za-z0-9 ._:/'-]+$", ligne):|
SED
cat > "$WORK/sed/prefixe.sed" <<'SED'
s|^    if not (ligne.startswith(PREFIXE_LIGNE) and ligne.endswith(b"'")):$|    if False:|
SED
cat > "$WORK/sed/hex.sed" <<'SED'
s|^    if len(hexa) > 2 \* LIGNE_MAX:$|    if False:|
SED
cat > "$WORK/sed/auto.sed" <<'SED'
s|^        vers_shell += ligne$|        vers_shell += ligne + bytes([13])|
SED
cat > "$WORK/sed/reste.sed" <<'SED'
s|^    return tampon\[-1024:\]$|    return tampon[-256:]|
SED
cat > "$WORK/sed/file.sed" <<'SED'
s|^    if vers_shell or DIFFEREE\['ligne'\] is not None:$|    if False:|
SED
if mut_pty premierplan "$WORK/sed/premier.sed"; then
  ASSIST="$MUT_ASSIST"; t_l2 "$MSH"; X2="$L2_1"; t_l3 "$MSH"; ASSIST="$ASSIST0"
  rougit "M-PREMIER-PLAN — le mutant saute le test du premier plan : le lecteur reçoit Ctrl-C et la ligne (L2.1 rouge)" "$X2" "LANCE premier-plan| 0 oui"
  rougit "M-PREMIER-PLAN — le mutant saute le test du premier plan : Ctrl-C tue le programme (L3.1 rouge)" "$L3_1" "LANCE premier-plan oui"
else sans_effet M-PREMIER-PLAN; fi
if mut_pty ctrlcaveugle "$WORK/sed/ctrlc.sed"; then
  ASSIST="$MUT_ASSIST"; t_l3 "$MSH"; ASSIST="$ASSIST0"
  rougit "M-CTRLC-AVEUGLE — le mutant écrit Ctrl-C sans test avant de répondre premier-plan : le programme meurt (L3.1 rouge)" "$L3_1" "LANCE premier-plan oui"
else sans_effet M-CTRLC-AVEUGLE; fi
if mut_pty alphabetpy "$WORK/sed/alphabet.sed"; then
  ASSIST="$MUT_ASSIST"; t_table "$MSH" "$WORK/t/l51.L" "$N51"; ASSIST="$ASSIST0"
  rougit "M-ALPHABET-PY — le mutant ne revalide plus l'alphabet : les lignes hostiles ne sont plus refusées pour l'alphabet (L5.1 rouge)" "$T_RES" "$(exp l51) | absent absent"
else sans_effet M-ALPHABET-PY; fi
if mut_pty findeligne "$WORK/sed/fin.sed"; then
  ASSIST="$MUT_ASSIST"; t_table "$MSH" "$WORK/t/l51.L" "$N51"; ASSIST="$ASSIST0"
  rougit "M-FIN-DE-LIGNE-PY — le mutant juge l'alphabet par l'ancre de fin de ligne de Python, qui tolère un saut de ligne final : ce cas n'est plus refusé pour l'alphabet (L5.1 rouge)" "$T_RES" "$(exp l51) | absent absent"
else sans_effet M-FIN-DE-LIGNE-PY; fi
if mut_pty prefixepy "$WORK/sed/prefixe.sed"; then
  ASSIST="$MUT_ASSIST"; t_table "$MSH" "$WORK/t/l52.L" "$N52"; ASSIST="$ASSIST0"
  rougit "M-PREFIXE-PY — le mutant ne contrôle plus le préfixe ni l'apostrophe finale (L5.2 rouge)" "$T_RES" "$(exp l52) | absent absent"
else sans_effet M-PREFIXE-PY; fi
if mut_pty hexborne "$WORK/sed/hex.sed"; then
  ASSIST="$MUT_ASSIST"; t_table "$MSH" "$WORK/t/l52.L" "$N52"; ASSIST="$ASSIST0"
  rougit "M-HEX-BORNE — le mutant retire la borne de 800 caractères hexadécimaux : la ligne de 401 octets est acceptée (L5.2 rouge)" "$T_RES" "$(exp l52) | absent absent"
else sans_effet M-HEX-BORNE; fi
cat > "$WORK/sed/ecriture.sed" <<'SED'
s|^        return 'ecriture'$|        pass|
SED
if mut_pty ecritureavalee "$WORK/sed/ecriture.sed"; then
  rougit "M-ECRITURE-AVALEE — le mutant avale l'échec d'écriture et répond ok (L10.1 rouge)" "$(ecr "$MUT_ASSIST")" "$L10_ATT"
else sans_effet M-ECRITURE-AVALEE; fi
cat > "$WORK/sed/ecrdiff.sed" <<'SED'
s|^            reponse = 'ecriture'$|            reponse = 'ok'|
SED
cat > "$WORK/sed/retest.sed" <<'SED'
s|^    libre = premier_plan_libre(maitre, pid)|    libre = True|
SED
cat > "$WORK/sed/attente.sed" <<'SED'
s|^    if not (calme or maintenant - DIFFEREE\['t0'\] >= ATTENTE_MAX_CTRLC):$|    if False:|
SED
cat > "$WORK/sed/uneecr.sed" <<'SED'
s|^    vers_shell += CTRL_C$|    vers_shell += CTRL_C + ligne|
SED
cat > "$WORK/sed/vsh.sed" <<'SED'
s|^    if vers_shell or DIFFEREE\['ligne'\] is not None:$|    if DIFFEREE['ligne'] is not None:|
SED
if mut_pty ecrdiff "$WORK/sed/ecrdiff.sed"; then
  rougit "M-ECRITURE-DIFFEREE — le mutant répond ok quand l'écriture de la ligne différée échoue (L11.1 rouge)" "$(dif "$MUT_ASSIST")" "$L11_ATT"
else sans_effet M-ECRITURE-DIFFEREE; fi
if mut_pty retest "$WORK/sed/retest.sed"; then
  rougit "M-RETEST-PREMIER-PLAN — le mutant ne reteste plus le premier plan au moment d'écrire la ligne différée (L11.1 rouge)" "$(dif "$MUT_ASSIST")" "$L11_ATT"
  ASSIST="$MUT_ASSIST"; t_l11 "$MSH"; ASSIST="$ASSIST0"
  rougit "M-RETEST-PREMIER-PLAN — même mutant, vrai shell : la ligne est écrite dans le programme au premier plan (L11.2 rouge)" "$L11_RES" "LANCE premier-plan| 0 oui"
else sans_effet M-RETEST-PREMIER-PLAN; fi
if mut_pty sansattente "$WORK/sed/attente.sed"; then
  rougit "M-SANS-ATTENTE — le mutant écrit la ligne sans attendre la réaction du shell (L11.1 rouge)" "$(dif "$MUT_ASSIST")" "$L11_ATT"
  ASSIST="$MUT_ASSIST"; t_l12; ASSIST="$ASSIST0"
  rougit "M-SANS-ATTENTE — même mutant, shell horodateur : la ligne suit Ctrl-C de moins de 0,2 s (L12.1 rouge)" "$L12_RES" "LANCE ok|FIN 0| 2 03 true true"
else sans_effet M-SANS-ATTENTE; fi
if mut_pty uneecriture "$WORK/sed/uneecr.sed"; then
  rougit "M-UNE-ECRITURE — le mutant écrit Ctrl-C et la ligne ensemble, comme avant le correctif Linux (L11.1 rouge)" "$(dif "$MUT_ASSIST")" "$L11_ATT"
  ASSIST="$MUT_ASSIST"; t_l12; ASSIST="$ASSIST0"
  rougit "M-UNE-ECRITURE — même mutant, shell horodateur : la première lecture porte déjà la ligne (L12.1 rouge)" "$L12_RES" "LANCE ok|FIN 0| 2 03 true true"
else sans_effet M-UNE-ECRITURE; fi
if mut_pty filedemie "$WORK/sed/vsh.sed"; then
  rougit "M-FILE-ENTREE-EN-ATTENTE — le mutant ne refuse plus une entrée déjà en attente d'écriture, seule la ligne différée garde (L11.1 rouge ; L9.1 reste vert : un shell sourd ne remplit jamais le tampon avec une ligne à la fois)" "$(dif "$MUT_ASSIST")" "$L11_ATT"
else sans_effet M-FILE-ENTREE-EN-ATTENTE; fi
if mut_pty entreeauto "$WORK/sed/auto.sed"; then
  ASSIST="$MUT_ASSIST"; t_l1 "$MSH"; ASSIST="$ASSIST0"
  rougit "M-ENTREE-AUTO — le mutant ajoute un retour chariot : le faux claude tourne sans geste humain (L1.2 rouge)" "$L1_VU $L1_A1" "vue absent"
else sans_effet M-ENTREE-AUTO; fi
if mut_pty restetronque "$WORK/sed/reste.sed"; then
  ASSIST="$MUT_ASSIST"; t_l6 "$MSH"; ASSIST="$ASSIST0"
  rougit "M-RESTE-TRONQUE — le mutant garde 256 octets de reste de tampon : la ligne fragmentée n'est plus reconstituée (L6.1 rouge)" "$L6_V" "LANCE ok|"
else sans_effet M-RESTE-TRONQUE; fi
if mut_pty filenonbornee "$WORK/sed/file.sed"; then
  ASSIST="$MUT_ASSIST"; t_l9; ASSIST="$ASSIST0"
  rougit "M-FILE-NON-BORNEE — le mutant retire le refus d'une entrée déjà en attente : la file grossit devant le shell sourd (L9.1 rouge)" "$L9_RES" "oui 60 vivant code=0 sig=null"
else sans_effet M-FILE-NON-BORNEE; fi
SHELLS="$SAV"
fi

if [ "$MODE" != pty ]; then
echo "=== J — sessions.lancer : transport, délai, file FIFO, arrêt, analyse de FIN (LANC-06, LANC-07 ; P72-D-14) ==="
cat > "$AUX/session-lancer.mjs" <<'JS'
// session-lancer.mjs <dossier des scripts> <moteur> <dossier courant> <HOME> <lecteur> <ligne de référence> : joue J1..J7, une ligne « <id><tab><JSON> » par assertion
import fs from 'node:fs'; import path from 'node:path'; import { pathToFileURL } from 'node:url'; import { EventEmitter } from 'node:events'; import { execFileSync } from 'node:child_process';
const [, , scripts, moteur, run, home, lecteur, LIGNE] = process.argv;
const { creerSessions } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-terminal-session.mjs')).href);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const attendre = async (cond, ms = 10000) => { const fin = Date.now() + ms; while (Date.now() < fin) { if (cond()) return true; await sleep(40); } return !!cond(); };
const out = (id, v) => console.log(id + '\t' + JSON.stringify(v));
const essai = async (f) => { try { return await f(); } catch (e) { return { erreur: String((e && e.message) || e).slice(0, 80) }; } };
const env = { ...process.env, HOME: home, ZDOTDIR: home, SHELL: '/bin/bash', VFT_RUN: run, BASH_SILENCE_DEPRECATION_WARNING: '1' }; delete env.TERM_PROGRAM; delete env.TERM_SESSION_ID;
const S = creerSessions({ engineDir: moteur, lab: run, env });
let sortie = ''; const faux = () => Object.assign(new EventEmitter(), { writeHead() {}, write(b) { sortie += Buffer.from(b).toString('latin1'); return true; }, end() {} });
const invites = () => sortie.split('VFP> ').length - 1; const present = (f) => fs.existsSync(path.join(run, f));
const argv = () => { try { return fs.readFileSync(path.join(run, 'claude.argv')).toString('latin1').split('\0').slice(0, -1).join('|'); } catch { return 'absent'; } };
const enfants = () => execFileSync('ps', ['-axo', 'pid=,ppid=,args='], { encoding: 'utf8' }).split('\n').map((l) => /^\s*(\d+)\s+(\d+)\s+(.*)$/.exec(l)).filter((m) => m && Number(m[2]) === process.pid && m[3].includes('vf-cockpit-pty.py')).map((m) => Number(m[1]));
const PRE = "claude --session-id '"; const HOSTILE = `${PRE}a$(touch M)'`; const tous = new Set();
out('J1.1', await essai(() => S.lancer(LIGNE, 'onglet-a')));
S.attacher({}, faux(), { onglet: 'onglet-a', lignes: 24, colonnes: 500 }); await attendre(() => sortie.includes('VFP> '));
out('J1.2', await essai(() => S.lancer(LIGNE, 'onglet-b')));
out('J1.3', [await essai(() => S.lancer('', 'onglet-a')), await essai(() => S.lancer(42, 'onglet-a')), await essai(() => S.lancer('x'.repeat(401), 'onglet-a'))]);
out('J1.4', await essai(() => S.lancer('claude\x01', 'onglet-a')));
const r21 = await essai(() => S.lancer(LIGNE, 'onglet-a')); await sleep(1000); out('J2.1', { r: r21, argv: present('claude.argv') ? 'present' : 'absent' });
S.ecrire(Buffer.from('\r'), 'onglet-a'); await attendre(() => present('claude.argv'), 5000); await sleep(300); await attendre(() => invites() >= 2, 3000); out('J2.2', argv());
S.ecrire(Buffer.from(`python3 -I ${lecteur}\r`), 'onglet-a'); await attendre(() => sortie.includes('LECTEUR-PRET'), 8000);
out('J3.1', await essai(() => S.lancer(LIGNE, 'onglet-a')));
const n0 = invites(); S.ecrire(Buffer.from('Q'), 'onglet-a'); await attendre(() => invites() > n0, 5000); await sleep(300);
out('J4.1', { r: await essai(() => S.lancer(HOSTILE, 'onglet-a')), M: present('M') ? 'present' : 'absent' });
const pid = enfants()[0]; enfants().forEach((p) => tous.add(p));
if (pid) {
  process.kill(pid, 'SIGSTOP'); const t0 = Date.now(); const r1 = await essai(() => S.lancer(LIGNE, 'onglet-a')); const ms = Date.now() - t0;
  out('J5.1', { r: r1, delai_2s: ms >= 1800 && ms < 3500 });
  const p2 = essai(() => S.lancer(HOSTILE, 'onglet-a')); await sleep(200); process.kill(pid, 'SIGCONT'); out('J5.2', { premier: r1, second: await p2 });
} else { out('J5.1', { erreur: 'assistant introuvable' }); out('J5.2', { erreur: 'assistant introuvable' }); }
await sleep(600); S.ecrire(Buffer.from('\x03'), 'onglet-a'); await sleep(400); S.ecrire(Buffer.from('exit 3\r'), 'onglet-a');
await attendre(() => S.etat().code === 3, 10000); out('J7.1', S.etat().code); await attendre(() => S.etat().session === 'terminee', 6000);
sortie = ''; S.attacher({}, faux(), { onglet: 'onglet-a', lignes: 24, colonnes: 500 }); await attendre(() => sortie.includes('VFP> '));
const nouveau = enfants().filter((p) => !tous.has(p))[0] || enfants()[0];
if (nouveau) {
  process.kill(nouveau, 'SIGSTOP'); const p6 = essai(() => S.lancer(LIGNE, 'onglet-a')); await sleep(300); const t1 = Date.now(); S.arreterTout(); const r6 = await p6;
  out('J6.1', { r: r6, rapide: Date.now() - t1 < 1500 }); process.kill(nouveau, 'SIGCONT'); await sleep(1500); try { process.kill(nouveau, 'SIGKILL'); } catch {}
} else out('J6.1', { erreur: 'assistant introuvable' });
S.arreterTout(); await sleep(1000); for (const p of enfants()) { try { process.kill(p, 'SIGKILL'); } catch {} } await sleep(500); process.exit(0);
JS
t_j() { # t_j <dossier des scripts> -> J_OUT
  RUNN=$((RUNN+1)); RUN="$WORK/run/j$RUNN"; mkdir -p "$RUN"; J_OUT="$WORK/j$RUNN.out"
  node "$AUX/session-lancer.mjs" "$1" "$ENGC" "$RUN" "$HOMEJ" "$WORK/temoins/lecteur.py" "$REF" > "$J_OUT" 2> "$J_OUT.err"
}
jv() { awk -F'\t' -v k="$1" '$1==k{print $2}' "$J_OUT"; }
t_j "$SCRIPTS"
R_ABS='{"ok":false,"motif":"absente"}'
assert_eq "J1.1 — aucune session : { ok:false, motif:'absente' }" "$(jv J1.1)" "$R_ABS"
assert_eq "J1.2 — mauvais onglet : absente" "$(jv J1.2)" "$R_ABS"
assert_eq "J1.3 — chaîne vide, non chaîne, 401 caractères : invalide (trois fois)" "$(jv J1.3)" '[{"ok":false,"motif":"invalide"},{"ok":false,"motif":"invalide"},{"ok":false,"motif":"invalide"}]'
assert_eq "J1.4 — caractère de contrôle : alphabet" "$(jv J1.4)" '{"ok":false,"motif":"alphabet"}'
assert_eq "J2.1 — session à l'invite : { ok:true }, le faux claude n'a pas tourné" "$(jv J2.1)" '{"r":{"ok":true},"argv":"absent"}'
assert_eq "J2.2 — puis ecrire('\\r') : argv exact" "$(jv J2.2)" "\"$ARGV_ATTENDU\""
assert_eq "J3.1 — lecteur brut au premier plan : { ok:false, motif:'premier-plan' }" "$(jv J3.1)" '{"ok":false,"motif":"premier-plan"}'
assert_eq "J4.1 — ligne imprimable hostile (\$(touch M) après un préfixe valide) : alphabet rendu par la revalidation Python, rien d'exécuté" "$(jv J4.1)" '{"r":{"ok":false,"motif":"alphabet"},"M":"absent"}'
assert_eq "J5.1 — assistant suspendu (SIGSTOP) : delai après environ 2 s" "$(jv J5.1)" '{"r":{"ok":false,"motif":"delai"},"delai_2s":true}'
assert_eq "J5.2 — second appel (ligne hostile) pendant la suspension puis SIGCONT : le premier a eu delai, le second alphabet (réponse tardive du premier consommée sans lui être attribuée)" "$(jv J5.2)" '{"premier":{"ok":false,"motif":"delai"},"second":{"ok":false,"motif":"alphabet"}}'
assert_eq "J6.1 — assistant suspendu puis arreterTout() : l'appel en attente rend absente en moins de 1,5 s" "$(jv J6.1)" '{"r":{"ok":false,"motif":"absente"},"rapide":true}'
assert_eq "J7.1 — après des lancer, exit 3 dans le shell : etat().code vaut 3 (l'analyse de FIN est intacte)" "$(jv J7.1)" "3"

echo "=== J8 — l'écriture refusée par l'assistant (« LANCE ecriture ») ressort en motif « ecriture », jamais en ok (ST-4) ==="
mkdir -p "$WORK/eng-faux/terminal"
cat > "$WORK/eng-faux/terminal/vf-cockpit-pty.py" <<'PY'
# assistant factice : répond à chaque ligne « L <hex> » du canal 3 par la réponse choisie (descripteur 2), sans shell
import os, sys, time
rep = os.environ.get('VFT_REPONSE', 'ecriture')
for l in os.fdopen(3, 'r'):
    if l.startswith('L '):
        sys.stderr.write('LANCE ' + rep + '\n'); sys.stderr.flush()
PY
cat > "$AUX/session-faux.mjs" <<'JS'
// session-faux.mjs <dossier des scripts> <moteur factice> <run> <reponse> : S.lancer face à un assistant factice qui répond « LANCE <reponse> »
import path from 'node:path'; import { pathToFileURL } from 'node:url'; import { EventEmitter } from 'node:events';
const [, , scripts, moteur, run, rep] = process.argv;
const { creerSessions } = await import(pathToFileURL(path.join(scripts, 'vf-cockpit-terminal-session.mjs')).href);
const S = creerSessions({ engineDir: moteur, lab: run, env: { ...process.env, SHELL: '/bin/bash', VFT_REPONSE: rep } });
S.attacher({}, Object.assign(new EventEmitter(), { writeHead() {}, write() { return true; }, end() {} }), { onglet: 'a', lignes: 24, colonnes: 80 });
const r = await S.lancer(process.argv[6] || "claude --session-id 'x'", 'a'); console.log(JSON.stringify(r)); S.arreterTout(); setTimeout(() => process.exit(0), 300);
JS
sfaux() { RUNN=$((RUNN+1)); mkdir -p "$WORK/run/j$RUNN"; node "$AUX/session-faux.mjs" "$1" "$WORK/eng-faux" "$WORK/run/j$RUNN" "$2" 2>/dev/null | tail -1; }
assert_eq "J8.1 — assistant factice qui répond « LANCE ecriture » : { ok:false, motif:'ecriture' } ; qui répond « LANCE ok » : { ok:true } (témoin)" "$(sfaux "$SCRIPTS" ecriture) $(sfaux "$SCRIPTS" ok)" '{"ok":false,"motif":"ecriture"} {"ok":true}'
cat > "$WORK/sed/regex.sed" <<'SED'
s#alphabet|invalide|ecriture)\$/#alphabet|invalide)$/#
SED
echo "=== M-* — mutants de la session (copie des trois fichiers) ==="
mut_session() { # mut_session <nom> <script sed> -> MUT_S ; code 1 si la cible manque ou si la copie n'a pas changé
  MUT_S="$WORK/mut-s-$1"; rm -rf "$MUT_S"; mkdir -p "$MUT_S"; local f; for f in vf-cockpit-terminal-session.mjs vf-cockpit-terminal-env.mjs vf-cockpit-terminal-amorce.mjs; do cp "$SCRIPTS/$f" "$MUT_S/$f"; done
  local g="$MUT_S/vf-cockpit-terminal-session.mjs"; cp "$g" "$g.orig"; sed -i.bak -f "$2" "$g"; local r=0; cmp -s "$g" "$g.orig" && r=1; rm -f "$g.orig" "$g.bak"; return $r
}
cat > "$WORK/sed/jssans.sed" <<'SED'
s|^        c.attentes.push(entree);$|        c.attentes.push(entree); entree.finir({ ok: true });|
SED
cat > "$WORK/sed/fifo.sed" <<'SED'
s|^        entree.minuterie = setTimeout(() => entree.finir({ ok: false, motif: 'delai' }), LANCER_DELAI_MS);$|        entree.minuterie = setTimeout(() => { const i = c.attentes.indexOf(entree); if (i >= 0) c.attentes.splice(i, 1); entree.finir({ ok: false, motif: 'delai' }); }, LANCER_DELAI_MS);|
SED
if mut_session regexecriture "$WORK/sed/regex.sed"; then
  rougit "M-REGEX-ECRITURE — le mutant ne reconnaît plus « LANCE ecriture » : l'attente expire (delai) au lieu du motif ecriture (J8.1 rouge)" "$(sfaux "$MUT_S" ecriture)" '{"ok":false,"motif":"ecriture"}'
else sans_effet M-REGEX-ECRITURE; fi
if mut_session jssansattente "$WORK/sed/jssans.sed"; then
  t_j "$MUT_S"
  rougit "M-JS-SANS-ATTENTE — le mutant rend { ok:true } sans attendre l'assistant : un lecteur au premier plan n'est plus refusé (J3.1 rouge)" "$(jv J3.1)" '{"ok":false,"motif":"premier-plan"}'
else sans_effet M-JS-SANS-ATTENTE; fi
if mut_session fifo "$WORK/sed/fifo.sed"; then
  t_j "$MUT_S"
  rougit "M-FIFO — le mutant retire l'entrée expirée de la file : la réponse tardive du premier appel est attribuée au second (J5.2 rouge)" "$(jv J5.2)" '{"premier":{"ok":false,"motif":"delai"},"second":{"ok":false,"motif":"alphabet"}}'
else sans_effet M-FIFO; fi
fi
vf_hyg_assert
echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ]
