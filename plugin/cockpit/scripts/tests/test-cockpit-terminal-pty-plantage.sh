#!/usr/bin/env bash
# test-cockpit-terminal-pty-plantage.sh — l'assistant PTY qui PLANTE (SIGKILL, exception non rattrapée) ne laisse aucun survivant (TERM-08 orphelins ; P71-D-05, D-28).
#   T12.8a  assistant tué par SIGKILL : le shell et ses travaux (arrière-plan, nohup + disown, trap '' HUP), chacun dans un groupe à part, disparaissent en moins de 5 s
#   T12.8b  assistant qui plante sur une exception Python non rattrapée (COPIE de l'assistant sous le scratch, jamais le module) : même résultat
#   M-GARDIEN-ABSENT, M-GARDIEN-SANS-SID  mutants (copies de l'assistant sous le scratch) : sans gardien, ou gardien jamais prévenu du PID de la session, T12.8a rougit (survivants nohup et trap)
#   T12.8c  témoin de la sonde : fin du descripteur 0 puis SIGTERM (arrêt propre par arreter()) : zéro survivant, la sonde sait donc verdir
#   T12.8d  la session se prouve par os.getsid(2) (jamais par `ps -o sess=`, qui vaut 0 sous macOS) : six processus dans la session du shell, un processus hors session vu hors session ;
#           le contrôle sait rougir (témoin M-CONTROLE-SESSION : un processus hors session noté parmi les membres fait différer « avant » et « dans-session »)
#   T12.8e  témoin hors session : un processus créé par la sonde, sorti de la session par setsid (fils d'un membre de la session), SURVIT au ménage du gardien et à arreter()
#   T12.8f  la fin de l'assistant VUE PAR LE SERVEUR (fin de fichier de ses descripteurs 1 et 2, tels que le serveur les lit) tombe en moins de 1,5 s, malgré le survivant têtu qui impose la grâce de 3 s
#   T12.8g  borne d'arrêt du gardien : il sort au plus GRACE + 2 s (5,2 s mesurées depuis le SIGKILL de l'assistant)
#   T12.8h  chaque étape du ménage a son témoin positif : SIGHUP (un membre docile disparaît en moins de 1,5 s), grâce (un membre qui nettoie en 0,8 s après SIGHUP a le temps de le faire), SIGKILL (T12.8a : zéro survivant)
#   M-GARDIEN-ABSENT, M-GARDIEN-SANS-SID  mutants (copies de l'assistant sous le scratch) : sans gardien, ou gardien jamais prévenu du PID de la session, T12.8a rougit (survivants nohup, trap, disown, trap HUP à nettoyage)
#   M-SANS-DUP2 (gardien gardant les descripteurs hérités), M-SANS-SIGHUP, M-GRACE-RETIREE, M-SANS-SIGKILL, M-BORNE (le gardien s'attarde après le ménage), M-CIBLAGE-PARENT (ciblage élargi aux fils d'un
#           membre) : un mutant par étape ou propriété du ménage ; chacun fait rougir la mesure qui lui revient et laisse les autres vertes (la ligne RESULTAT complète est dans chaque assertion :
#           une copie cassée n'est pas un mutant tué). Le mutant « contrôle getsid retiré » littéral n'est PAS joué : il viserait tous les processus de l'utilisateur (voir M-CIBLAGE-PARENT).
# Suite autonome, séparée de test-cockpit-terminal-pty.sh : elle ne partage ni son serveur ni son hygiène, ne modifie aucune de ses assertions, et se rejoue seule.
# Les survivants se relèvent par les PID que la sonde a elle-même notés (jamais par motif de nom) ; chacun est tué par PID, ligne de commande relue, avant la sortie.
# Aucun timeout/gtimeout (absents du poste) : toutes les bornes sont en Python. Exit 0 si tout passe, 1 sinon.
set -uo pipefail
HERE_T="$(cd "$(dirname "$0")" && pwd)"; SCRIPTS="$(cd "$HERE_T/.." && pwd)"
ENG="$(cd "$SCRIPTS/../skills/cockpit-moteur" && pwd -P)"; PTYPY="$ENG/terminal/vf-cockpit-pty.py"
WORK="$(mktemp -d)"; WORK="$(cd "$WORK" && pwd -P)"
PASS=0; FAIL=0
assert_eq() { if [ "$2" = "$3" ]; then echo "  ✅ PASS — $1"; PASS=$((PASS+1)); else echo "  ❌ FAIL — $1"; echo "     attendu: [$3]"; echo "     obtenu:  [$2]"; FAIL=$((FAIL+1)); fi; }
cleanup() { [ -n "${KEEP:-}" ] || rm -rf "$WORK"; }; trap cleanup EXIT

cat > "$WORK/shell-test" <<'SH'
#!/bin/bash
exec bash --norc --noprofile -i
SH
chmod +x "$WORK/shell-test"
export SHELL="$WORK/shell-test" PS1='VFP> '

cat > "$WORK/sonde.py" <<'PY'
# sonde.py <assistant.py> <scénario> <scratch> : lance l'assistant (quatre tubes), démarre six travaux dans la session du shell (groupes distincts) et un témoin hors session (setsid),
# applique la fin choisie, mesure (fin de fichier des descripteurs 1 et 2 de l'assistant, mort de chaque travail, mort du gardien), relève les survivants PAR LES PID NOTÉS, les tue un par un
# (ligne de commande relue) et imprime « MESURE … » puis « RESULTAT avant=<n> groupes=<n> dans-session=<n> survivants=<n> fin=<…> ».
import os, select, signal, subprocess, sys, time
assistant, scenario, scratch = sys.argv[1:4]
signal.signal(signal.SIGHUP, signal.SIG_DFL)   # lancée sous nohup (SIGHUP ignoré, hérité par tout l'arbre), la sonde le rétablit : sinon les trap HUP du shell ne se posent pas et l'étape « grâce » rougit à tort
shell = os.environ['SHELL']
horssrc = os.environ['VFT_HORS']
def ps(pid):
    r = subprocess.run(['/bin/ps', '-o', 'pid=,ppid=,pgid=,sess=,tt=,stat=,command=', '-p', str(pid)], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    t = r.stdout.decode().strip()
    return t or None
def vivant(pid):
    t = ps(pid)
    return t is not None and t.split()[5][0] != 'Z'
def etats():                                     # {pid: (ppid, stat)} de tout le système, un seul ps
    r = subprocess.run(['/bin/ps', '-A', '-o', 'pid=,ppid=,stat='], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    d = {}
    for l in r.stdout.decode().splitlines():
        m = l.split()
        if len(m) >= 3 and m[0].isdigit() and m[1].isdigit(): d[int(m[0])] = (int(m[1]), m[2])
    return d
def attendre(f, delai=8.0):
    fin = time.time() + delai
    while time.time() < fin:
        try:
            v = open(f).read().strip()
            if v.isdigit(): return int(v)
        except OSError: pass
        time.sleep(0.05)
    return None
def sid(pid):
    try: return os.getsid(pid)
    except OSError: return -1
os.makedirs(scratch, exist_ok=True)
p = subprocess.Popen([sys.executable, '-I', assistant, '24', '80', shell], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, pass_fds=(), close_fds=True, preexec_fn=None)
# le descripteur 3 (contrôle) est absent : l'assistant tourne sans canal de contrôle (cas déjà admis par main())
def ecrire(s): p.stdin.write(s.encode()); p.stdin.flush()
time.sleep(0.8)
# une ligne à la fois, la suivante après le PID de la précédente : la file d'entrée d'un terminal est bornée (1 024 octets sous macOS), des lignes en rafale s'y perdent
travaux = [('shell', "echo $$ > %s/shell.pid" % scratch),
           ('bg', "sleep 311 & echo $! > %s/bg.pid" % scratch),
           ('nh', "nohup sleep 312 >/dev/null 2>&1 & echo $! > %s/nh.pid; disown" % scratch),
           ('ign', "(trap '' HUP; exec sleep 313) & echo $! > %s/ign.pid" % scratch),
           ('dis', "python3 -I %s %s & echo $! > %s/dis.pid; disown" % (horssrc, scratch, scratch)),   # membre docile, disowné (ni SIGHUP de bash ni du noyau) ; père du témoin hors session (hors.pid)
           ('gra', "(trap 'sleep 0.8; echo ok > %s/grace.marq; exit 0' HUP; while :; do sleep 0.2; done) & echo $! > %s/gra.pid; disown" % (scratch, scratch))]   # nettoie en 0,8 s après SIGHUP
noms = [n for n, _ in travaux]
pids = {}
for n, ligne in travaux:
    ecrire(ligne + "\n")
    pids[n] = attendre('%s/%s.pid' % (scratch, n))
    if pids[n] is None: break
if pids.get('dis') is not None: pids['hors'] = attendre('%s/hors.pid' % scratch)
time.sleep(0.4)
def tuer(paires):                                # tue par PID noté, ligne de commande relue (sleep 31x, bash de la sonde, hors.py, copie de l'assistant)
    for n, q in paires:
        t = ps(q) or ''
        if ('sleep 31' in t) or (n in ('shell', 'gra') and 'bash' in t) or (n in ('dis', 'hors') and 'hors.py' in t) or (n == 'garde' and assistant in t): os.kill(q, signal.SIGKILL)
if len(pids) != len(noms) + 1 or None in pids.values():
    os.set_blocking(p.stdout.fileno(), False)
    try: sortie = os.read(p.stdout.fileno(), 4000)
    except OSError: sortie = b''
    p.kill(); time.sleep(0.3); tuer([(n, q) for n, q in pids.items() if q]); time.sleep(0.3)
    print('SONDE-MORTE pids=%r sortie-du-shell=%r' % (pids, sortie[-600:])); sys.exit(0)
if os.environ.get('VFT_HORS_DANS_NOMS'): noms = noms + ['hors']      # contrôle : un processus hors session noté parmi les membres
vus = [n for n in noms if vivant(pids[n])]
groupes = {ps(pids[n]).split()[2] for n in vus}
chef_sess = sid(pids['shell'])                    # os.getsid(2), pas `ps -o sess=` (vaut 0 partout sous macOS)
dedans = [n for n in vus if sid(pids[n]) == chef_sess]
chef = 'oui' if chef_sess == pids['shell'] else 'non'
hors_session = 'oui' if sid(pids['hors']) not in (-1, chef_sess) else 'non'
et0 = etats()
fils = [q for q, (pp, st) in et0.items() if pp == p.pid and q != pids['shell']]   # le gardien : l'autre enfant de l'assistant
garde = fils[0] if len(fils) == 1 else None
if os.environ.get('VFT_TRACE'):
    print('--- AVANT la fin (assistant %d)' % p.pid)
    for n in noms + ['hors']: print('  %-5s sid=%d %s' % (n, sid(pids[n]), ps(pids[n])))
    print('  ast   %s' % ps(p.pid)); print('  garde %s' % (ps(garde) if garde else 'aucun'))
T0 = time.time()
if scenario == 'kill': p.kill(); fin = 'kill'
elif scenario == 'crash':
    open(scratch + '/crash', 'w').close(); time.sleep(1.0); fin = 'crash'
elif scenario == 'eof': p.stdin.close(); fin = 'eof'
elif scenario == 'term': p.terminate(); fin = 'term'
try: code = p.wait(timeout=10)
except subprocess.TimeoutExpired: code = 'vivant'
t_wait = time.time()
fds = {p.stdout.fileno(): 'out', p.stderr.fileno(): 'err'}   # ce que le serveur lit : la fin de fichier arrive quand plus personne n'écrit
err = b''; t_eof = None; mort = {}; g_mort = None
fin_boucle = max(T0 + 9.0, t_wait + 5.5)
while True:
    if fds:
        r, _, _ = select.select(list(fds), [], [], 0.05)
        for fd in r:
            d = os.read(fd, 65536)
            if not d: del fds[fd]
            elif fds[fd] == 'err': err += d
        if not fds and t_eof is None: t_eof = time.time() - T0
    else: time.sleep(0.05)
    et = etats(); now = time.time()
    for n in noms:
        if n not in mort and not (pids[n] in et and not et[pids[n]][1].startswith('Z')): mort[n] = now - T0
    if garde and g_mort is None and not (garde in et and not et[garde][1].startswith('Z')): g_mort = now - T0
    if len(mort) == len(noms) and not fds and (garde is None or g_mort is not None): break
    if now > fin_boucle: break
limite = (t_wait - T0) + 5.0
surv = [n for n in noms if n not in mort or mort[n] > limite]
fin_txt = 'code=%s' % code
if scenario == 'crash': fin_txt += ' traceback=%s' % ('oui' if b'Traceback' in err and b'plantage injecte' in err else 'non')
if os.environ.get('VFT_TRACE'):
    print('--- APRES')
    for n in noms: print('  %-5s %s' % (n, ('mort a %.2f s' % mort[n]) if n in mort else 'vivant'))
def f2(x): return ('%.2f' % x) if x is not None else None
print('MESURE eof=%s gardien=%s dis=%s grace=%s hors=%s hors-session=%s chef=%s surv=%s' % (
    f2(t_eof) or 'jamais', f2(g_mort) or ('vivant' if garde else 'aucun'), f2(mort.get('dis')) or 'vivant',
    'oui' if os.path.exists(scratch + '/grace.marq') else 'non', 'vivant' if vivant(pids['hors']) else 'mort', hors_session, chef, ','.join(surv) or 'aucun'))
for n in surv: print('  SURVIVANT pid=%d %s' % (pids[n], ps(pids[n])))
cibles = [(n, pids[n]) for n in noms if vivant(pids[n])] + [('hors', pids['hors'])] + ([('garde', garde)] if garde else [])
tuer(cibles)                                     # nettoyage par PID noté
time.sleep(0.2)
reste = [n for n, q in cibles if vivant(q)]
print('RESULTAT avant=%d groupes=%d dans-session=%d survivants=%d fin=%s%s' % (len(vus), len(groupes), len(dedans), len(surv), fin_txt, (' NETTOYAGE-INCOMPLET=%r' % reste) if reste else ''))
PY

# témoin hors session : le père reste dans la session du shell (disowné, docile) ; son fils sort de la session par setsid et note son PID. Le fils n'est jamais visé par le ménage.
cat > "$WORK/hors.py" <<'PY'
import os, sys, time
pid = os.fork()
if pid == 0:
    os.setsid()
    open(sys.argv[1] + '/hors.pid', 'w').write(str(os.getpid()))
    time.sleep(317)
    os._exit(0)
time.sleep(316)
PY
export VFT_HORS="$WORK/hors.py"
# mut.py <source> <copie> <fonction> <ancien> <nouveau> [préfixe] : remplace <ancien> (exactement une fois) DANS le corps de <fonction> seulement ; le préfixe (définitions) est inséré avant « def <fonction> » ; code 1 sinon
cat > "$WORK/mut.py" <<'PY'
import re, sys
src, dst, fonction, ancien, nouveau = sys.argv[1:6]
prefixe = sys.argv[6] if len(sys.argv) > 6 else ''
t = open(src).read()
m = re.search(r'^def %s\(.*?(?=^def |^if __name__|\Z)' % re.escape(fonction), t, re.S | re.M)
if not m or m.group(0).count(ancien) != 1: sys.exit(1)
corps = m.group(0).replace(ancien, nouveau)
open(dst, 'w').write(t[:m.start()] + (prefixe + '\n' if prefixe else '') + corps + t[m.end():])
PY

# COPIE de l'assistant plantant sur demande : le fichier du module n'est jamais modifié
sed "s/^            pret, pret_e, _ = select.select(lire, ecrire, \[\], 0.2)$/            os.path.exists(os.environ['VFT_CRASH']) and (_ for _ in ()).throw(RuntimeError('plantage injecte'))\n&/" "$PTYPY" > "$WORK/assistant-plante.py"
INJ="$(grep -c 'plantage injecte' "$WORK/assistant-plante.py")"
assert_eq "T12.8-0 — l'injection d'exception est présente dans la copie (une ligne) et absente du module" "$INJ $(grep -c 'plantage injecte' "$PTYPY")" "1 0"

lancer() { # lancer <assistant> <scénario> <nom> [VAR=valeur] -> SONDE_RES (ligne RESULTAT), SONDE_MES (ligne MESURE), détail affiché
  local out; out="$(env VFT_CRASH="$WORK/$3/crash" ${4:-VFT_X=1} python3 -I "$WORK/sonde.py" "$1" "$2" "$WORK/$3" 2>&1)"
  printf '%s\n' "$out" | grep -v '^RESULTAT' | sed 's/^/     /'
  SONDE_RES="$(printf '%s\n' "$out" | grep '^RESULTAT' | sed 's/^RESULTAT //')"; [ -n "$SONDE_RES" ] || SONDE_RES="sonde muette : $out"
  SONDE_MES="$(printf '%s\n' "$out" | grep '^MESURE' | sed 's/^MESURE //')"
}
mes() { printf '%s\n' "$SONDE_MES" | tr ' ' '\n' | sed -n "s/^$1=//p"; }                       # mes <clé> : valeur de la mesure
sous() { awk -v a="$1" -v b="$2" 'BEGIN { print (a ~ /^[0-9]+(\.[0-9]+)?$/ && a + 0 < b + 0) ? "oui" : "non" }'; }   # sous <valeur> <seuil> : oui si numérique et < seuil (« jamais », « vivant », « aucun » : non)
RES6="avant=6 groupes=6 dans-session=6 survivants=0"
echo "=== T12.8 — l'assistant PTY plante : le shell et ses travaux (groupes à part, nohup, disown, trap '' HUP) ne survivent pas ==="
lancer "$PTYPY" eof t128c-eof;  EOF_RES="$SONDE_RES"; EOF_MES="$SONDE_MES"
lancer "$PTYPY" term t128c-term; TERM_RES="$SONDE_RES"
assert_eq "T12.8c — témoin de la sonde : fin du descripteur 0 (arrêt propre) : six processus vivaient dans six groupes et une session (os.getsid), aucun ne survit" "$EOF_RES" "$RES6 fin=code=0"
assert_eq "T12.8c' — témoin de la sonde : SIGTERM (arrêt propre) : même résultat" "$TERM_RES" "$RES6 fin=code=0"
assert_eq "T12.8e' — témoin hors session : arrêt propre (arreter()) : le processus sorti de la session par setsid survit" "$(mes hors)" "vivant"
lancer "$PTYPY" kill t128a;     KILL_RES="$SONDE_RES"; KILL_MES="$SONDE_MES"
assert_eq "T12.8a — assistant tué par SIGKILL : six processus vivaient dans six groupes et une session (os.getsid), aucun ne survit après 5 s" "$KILL_RES" "$RES6 fin=code=-9"
assert_eq "T12.8d — la session se prouve par os.getsid : le shell est chef de sa session (getsid = son PID) et le processus hors session est vu hors de cette session" "chef=$(mes chef) hors-session=$(mes hors-session)" "chef=oui hors-session=oui"
assert_eq "T12.8e — témoin hors session : un processus sorti de la session par setsid, fils d'un membre, SURVIT au ménage du gardien (tué ensuite par son PID noté)" "$(mes hors)" "vivant"
MES_KILL_SAVE="$SONDE_MES"
assert_eq "T12.8f — la fin de l'assistant vue par le serveur (fin de fichier de ses descripteurs 1 et 2) tombe en moins de 1,5 s, malgré le survivant têtu qui impose la grâce de 3 s (obtenu : $(mes eof) s)" "$(sous "$(mes eof)" 1.5)" "oui"
assert_eq "T12.8g — borne d'arrêt du gardien : il sort au plus GRACE + 2 s, soit 5,2 s après le SIGKILL de l'assistant (obtenu : $(mes gardien) s) ; il a bien existé (jamais « aucun »)" "$(sous "$(mes gardien)" 5.2)" "oui"
assert_eq "T12.8h — étape SIGHUP : un membre docile (hors SIGHUP du noyau et de bash) disparaît en moins de 1,5 s, bien avant la grâce (obtenu : $(mes dis) s)" "$(sous "$(mes dis)" 1.5)" "oui"
assert_eq "T12.8h' — étape grâce : le membre qui nettoie en 0,8 s après SIGHUP a eu le temps de le faire avant le SIGKILL (marqueur écrit)" "$(mes grace)" "oui"
lancer "$PTYPY" kill t128d-ctl VFT_HORS_DANS_NOMS=1
CTL_AV="$(printf '%s\n' "$SONDE_RES" | sed -n 's/^avant=\([0-9]*\) .*/\1/p')"; CTL_DS="$(printf '%s\n' "$SONDE_RES" | sed -n 's/.* dans-session=\([0-9]*\) .*/\1/p')"
assert_eq "T12.8d' — le contrôle de session peut rougir : avec le processus hors session noté parmi les membres, « avant » ($CTL_AV) et « dans-session » ($CTL_DS) diffèrent" "$([ -n "$CTL_AV" ] && [ "$CTL_AV" = 7 ] && [ "$CTL_DS" = 6 ] && echo "differents" || echo "identiques ou sonde muette : $SONDE_RES")" "differents"
lancer "$WORK/assistant-plante.py" crash t128b; CRASH_RES="$SONDE_RES"
assert_eq "T12.8b — assistant planté par une exception Python non rattrapée (copie sous le scratch, traceback vu) : aucun survivant après 5 s" "$CRASH_RES" "$RES6 fin=code=1 traceback=oui"

echo "=== M-* — mutants du gardien (copies de l'assistant : le module n'est jamais modifié) ==="
mutant_ast() { # mutant_ast <nom> <expression-sed> -> MUT_AST ; code 1 si la copie n'a pas changé
  MUT_AST="$WORK/assistant-$1.py"; cp "$PTYPY" "$MUT_AST"; cp "$MUT_AST" "$MUT_AST.orig"; sed -i.bak "$2" "$MUT_AST"
  local r=0; cmp -s "$MUT_AST" "$MUT_AST.orig" && r=1; rm -f "$MUT_AST.orig" "$MUT_AST.bak"; return $r
}
mutant_fn() { # mutant_fn <nom> <fonction> <ancien> <nouveau> [préfixe] -> MUT_AST ; confiné au corps de <fonction> ; code 1 si absent, ambigu, inchangé ou si la copie ne compile plus
  MUT_AST="$WORK/assistant-$1.py"
  python3 -I "$WORK/mut.py" "$PTYPY" "$MUT_AST" "$2" "$3" "$4" "${5:-}" || return 1
  cmp -s "$MUT_AST" "$PTYPY" && return 1
  python3 -I -c "import ast,sys; ast.parse(open(sys.argv[1]).read())" "$MUT_AST" 2>/dev/null
}
sans_effet() { assert_eq "$1 — mutant sans effet (cible absente, ambiguë, inchangée, ou copie cassée)" "sans effet" "effet"; }
if mutant_ast gardien-absent 's/^    garde = lancer_gardien()$/    garde = None/'; then
  lancer "$MUT_AST" kill m128a
  assert_eq "M-GARDIEN-ABSENT — le mutant (aucun gardien) rougit T12.8a : nohup, trap '' HUP, le membre disowné et celui qui nettoie survivent au SIGKILL de l'assistant" "$SONDE_RES $(mes surv)" "avant=6 groupes=6 dans-session=6 survivants=4 fin=code=-9 nh,ign,dis,gra"
else sans_effet "M-GARDIEN-ABSENT"; fi
if mutant_ast gardien-sans-sid 's/^    dire(garde, b.SID .*$/    dire(garde, b"")/'; then
  lancer "$MUT_AST" kill m128b
  assert_eq "M-GARDIEN-SANS-SID — le mutant (le gardien ne reçoit jamais le PID de la session) rougit T12.8a : mêmes survivants" "$SONDE_RES $(mes surv)" "avant=6 groupes=6 dans-session=6 survivants=4 fin=code=-9 nh,ign,dis,gra"
else sans_effet "M-GARDIEN-SANS-SID"; fi
if mutant_fn sans-dup2 gardien '        os.dup2(nul, fd)' '        pass'; then
  lancer "$MUT_AST" kill m128f
  assert_eq "M-SANS-DUP2 — le gardien garde les descripteurs 1 et 2 hérités : la fin de l'assistant n'est vue par le serveur qu'avec la fin du gardien (T12.8f rougit : eof >= 1,5 s, obtenu $(mes eof) s) ; rien d'autre ne change" "$(sous "$(mes eof)" 1.5) $SONDE_RES $(mes surv)" "non $RES6 fin=code=-9 aucun"
else sans_effet "M-SANS-DUP2"; fi
if mutant_fn sans-sighup ramasser '    envoyer_membres(sid, signal.SIGHUP)' '    pass'; then
  lancer "$MUT_AST" kill m128h
  assert_eq "M-SANS-SIGHUP — sans SIGHUP du gardien, le membre docile ne tombe qu'au SIGKILL de fin de grâce (T12.8h rougit : dis >= 1,5 s, obtenu $(mes dis) s) et le membre qui nettoie n'a rien à nettoyer (T12.8h' rougit)" "$(sous "$(mes dis)" 1.5) grace=$(mes grace) $SONDE_RES" "non grace=non $RES6 fin=code=-9"
else sans_effet "M-SANS-SIGHUP"; fi
if mutant_fn grace-retiree ramasser '    while time.time() < fin:' '    while False:'; then
  lancer "$MUT_AST" kill m128i
  assert_eq "M-GRACE-RETIREE — sans attente, SIGKILL aussitôt après SIGHUP : le membre docile tombe vite (T12.8h tient) mais le membre qui nettoie est tué avant d'avoir fini (T12.8h' rougit : marqueur absent)" "$(sous "$(mes dis)" 1.5) grace=$(mes grace) $SONDE_RES" "oui grace=non $RES6 fin=code=-9"
else sans_effet "M-GRACE-RETIREE"; fi
if mutant_fn sans-sigkill ramasser '    sigkill_session(sid, set())' '    pass'; then
  lancer "$MUT_AST" kill m128j
  assert_eq "M-SANS-SIGKILL — SIGHUP seul : nohup et trap '' HUP survivent (T12.8a rougit pour la bonne raison : ce sont les deux seuls survivants, les membres dociles sont tombés)" "$SONDE_RES $(mes surv)" "avant=6 groupes=6 dans-session=6 survivants=2 fin=code=-9 nh,ign"
else sans_effet "M-SANS-SIGKILL"; fi
if mutant_fn borne ramasser '    sigkill_session(sid, set())' '    sigkill_session(sid, set())
    time.sleep(10)'; then
  lancer "$MUT_AST" kill m128k
  assert_eq "M-BORNE — le ménage est complet mais le gardien s'attarde 10 s : seule la borne d'arrêt rougit (T12.8g : gardien >= 5,2 s, obtenu $(mes gardien)), zéro survivant" "$(sous "$(mes gardien)" 5.2) $SONDE_RES" "non $RES6 fin=code=-9"
else sans_effet "M-BORNE"; fi
PREFIXE_PARENT='_PP = {"t": 0.0, "m": {}}


def _ppid(p):
    if time.time() - _PP["t"] > 0.3:
        m = {}
        r = subprocess.run(["/bin/ps", "-A", "-o", "pid=,ppid="], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        for l in r.stdout.decode().splitlines():
            w = l.split()
            if len(w) == 2:
                m[int(w[0])] = int(w[1])
        _PP["m"] = m
        _PP["t"] = time.time()
    return _PP["m"].get(p, 0)

'
if mutant_fn ciblage-parent vise '        return os.getsid(p) == sid' '        return os.getsid(p) == sid or os.getsid(_ppid(p)) == sid' "$PREFIXE_PARENT"; then
  lancer "$MUT_AST" kill m128l
  assert_eq "M-CIBLAGE-PARENT — ciblage élargi aux fils d'un membre de la session (borné à la session de la sonde) : le témoin hors session est tué (T12.8e rougit : hors=$(mes hors)), le reste est vert" "$(mes hors) $SONDE_RES" "mort $RES6 fin=code=-9"
else sans_effet "M-CIBLAGE-PARENT"; fi

echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ]
