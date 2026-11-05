#!/usr/bin/env bash
# test-cockpit-terminal-pty-plantage.sh — l'assistant PTY qui PLANTE (SIGKILL, exception non rattrapée) ne laisse aucun survivant (TERM-08 orphelins ; P71-D-05, D-28).
#   T12.8a  assistant tué par SIGKILL : le shell et ses travaux (arrière-plan, nohup + disown, trap '' HUP), chacun dans un groupe à part, disparaissent en moins de 5 s
#   T12.8b  assistant qui plante sur une exception Python non rattrapée (COPIE de l'assistant sous le scratch, jamais le module) : même résultat
#   M-GARDIEN-ABSENT, M-GARDIEN-SANS-SID  mutants (copies de l'assistant sous le scratch) : sans gardien, ou gardien jamais prévenu du PID de la session, T12.8a rougit (survivants nohup et trap)
#   T12.8c  témoin de la sonde : fin du descripteur 0 puis SIGTERM (arrêt propre par arreter()) : zéro survivant, la sonde sait donc verdir
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
# sonde.py <assistant.py> <scénario> <scratch> : lance l'assistant (quatre tubes), démarre quatre travaux dans des groupes distincts, applique la fin choisie,
# attend 5 s au plus, relève les survivants PAR LES PID NOTÉS, les tue un par un (ligne de commande relue) et imprime « avant=<n> groupes=<n> survivants=<n> fin=<…> ».
import os, signal, subprocess, sys, time
assistant, scenario, scratch = sys.argv[1:4]
shell = os.environ['SHELL']
def ps(pid):
    r = subprocess.run(['/bin/ps', '-o', 'pid=,ppid=,pgid=,sess=,tt=,stat=,command=', '-p', str(pid)], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    t = r.stdout.decode().strip()
    return t or None
def vivant(pid):
    t = ps(pid)
    return t is not None and t.split()[5][0] != 'Z'
def attendre(f, delai=8.0):
    fin = time.time() + delai
    while time.time() < fin:
        try:
            v = open(f).read().strip()
            if v.isdigit(): return int(v)
        except OSError: pass
        time.sleep(0.05)
    return None
os.makedirs(scratch, exist_ok=True)
p = subprocess.Popen([sys.executable, '-I', assistant, '24', '80', shell], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, pass_fds=(), close_fds=True, preexec_fn=None)
# le descripteur 3 (contrôle) est absent : l'assistant tourne sans canal de contrôle (cas déjà admis par main())
def ecrire(s): p.stdin.write(s.encode()); p.stdin.flush()
time.sleep(0.8)
ecrire("echo $$ > %s/shell.pid\n" % scratch)
ecrire("sleep 311 & echo $! > %s/bg.pid\n" % scratch)
ecrire("nohup sleep 312 >/dev/null 2>&1 & echo $! > %s/nh.pid; disown\n" % scratch)
ecrire("(trap '' HUP; exec sleep 313) & echo $! > %s/ign.pid\n" % scratch)
noms = ['shell', 'bg', 'nh', 'ign']
pids = {n: attendre('%s/%s.pid' % (scratch, n)) for n in noms}
time.sleep(0.4)
if None in pids.values():
    print('SONDE-MORTE pids=%r' % pids); sys.exit(0)
vus = [n for n in noms if vivant(pids[n])]
groupes = {ps(pids[n]).split()[2] for n in vus}
chef_sess = ps(pids['shell']).split()[3]
dedans = [n for n in vus if ps(pids[n]).split()[3] == chef_sess]
if os.environ.get('VFT_TRACE'):
    print('--- AVANT la fin (assistant %d)' % p.pid)
    for n in noms: print('  %-5s %s' % (n, ps(pids[n])))
    print('  ast   %s' % ps(p.pid))
if scenario == 'kill': p.kill(); fin = 'kill'
elif scenario == 'crash':
    open(scratch + '/crash', 'w').close(); time.sleep(1.0); fin = 'crash'
elif scenario == 'eof': p.stdin.close(); fin = 'eof'
elif scenario == 'term': p.terminate(); fin = 'term'
try: code = p.wait(timeout=10)
except subprocess.TimeoutExpired: code = 'vivant'
err = b''
try: err = p.stderr.read()
except Exception: pass
fin_txt = 'code=%s' % code
if scenario == 'crash': fin_txt += ' traceback=%s' % ('oui' if b'Traceback' in err and b'plantage injecte' in err else 'non')
debut = time.time()
while time.time() - debut < 5.0:
    if not any(vivant(pids[n]) for n in noms): break
    time.sleep(0.1)
surv = [n for n in noms if vivant(pids[n])]
if os.environ.get('VFT_TRACE'):
    print('--- APRES (5 s au plus)')
    for n in noms: print('  %-5s %s' % (n, ps(pids[n]) or 'disparu'))
for n in surv: print('  SURVIVANT pid=%d %s' % (pids[n], ps(pids[n])))
for n in surv:                                   # nettoyage par PID noté, ligne de commande relue (sleep 31x ou bash de la sonde)
    t = ps(pids[n]) or ''
    if ('sleep 31' in t) or (n == 'shell' and 'bash' in t): os.kill(pids[n], signal.SIGKILL)
time.sleep(0.2)
reste = [n for n in surv if vivant(pids[n])]
print('RESULTAT avant=%d groupes=%d dans-session=%d survivants=%d fin=%s%s' % (len(vus), len(groupes), len(dedans), len(surv), fin_txt, (' NETTOYAGE-INCOMPLET=%r' % reste) if reste else ''))
PY

# COPIE de l'assistant plantant sur demande : le fichier du module n'est jamais modifié
sed "s/^            pret, pret_e, _ = select.select(lire, ecrire, \[\], 0.2)$/            os.path.exists(os.environ['VFT_CRASH']) and (_ for _ in ()).throw(RuntimeError('plantage injecte'))\n&/" "$PTYPY" > "$WORK/assistant-plante.py"
INJ="$(grep -c 'plantage injecte' "$WORK/assistant-plante.py")"
assert_eq "T12.8-0 — l'injection d'exception est présente dans la copie (une ligne) et absente du module" "$INJ $(grep -c 'plantage injecte' "$PTYPY")" "1 0"

lancer() { # lancer <assistant> <scénario> <nom> -> SONDE_RES (ligne RESULTAT), détail des survivants affiché
  local out; out="$(VFT_CRASH="$WORK/$3/crash" python3 -I "$WORK/sonde.py" "$1" "$2" "$WORK/$3" 2>&1)"
  printf '%s\n' "$out" | grep -v '^RESULTAT' | sed 's/^/     /'
  SONDE_RES="$(printf '%s\n' "$out" | grep '^RESULTAT' | sed 's/^RESULTAT //')"; [ -n "$SONDE_RES" ] || SONDE_RES="sonde muette : $out"
}
echo "=== T12.8 — l'assistant PTY plante : le shell et ses travaux (groupes à part, nohup, disown, trap '' HUP) ne survivent pas ==="
lancer "$PTYPY" eof t128c-eof;  EOF_RES="$SONDE_RES"
lancer "$PTYPY" term t128c-term; TERM_RES="$SONDE_RES"
assert_eq "T12.8c — témoin de la sonde : fin du descripteur 0 (arrêt propre) : quatre processus vivaient dans quatre groupes et une session, aucun ne survit" "$EOF_RES" "avant=4 groupes=4 dans-session=4 survivants=0 fin=code=0"
assert_eq "T12.8c' — témoin de la sonde : SIGTERM (arrêt propre) : même résultat" "$TERM_RES" "avant=4 groupes=4 dans-session=4 survivants=0 fin=code=0"
lancer "$PTYPY" kill t128a;     KILL_RES="$SONDE_RES"
assert_eq "T12.8a — assistant tué par SIGKILL : quatre processus vivaient dans quatre groupes et une session, aucun ne survit après 5 s" "$KILL_RES" "avant=4 groupes=4 dans-session=4 survivants=0 fin=code=-9"
lancer "$WORK/assistant-plante.py" crash t128b; CRASH_RES="$SONDE_RES"
assert_eq "T12.8b — assistant planté par une exception Python non rattrapée (copie sous le scratch, traceback vu) : aucun survivant après 5 s" "$CRASH_RES" "avant=4 groupes=4 dans-session=4 survivants=0 fin=code=1 traceback=oui"

echo "=== M-* — mutants du gardien (copies de l'assistant : le module n'est jamais modifié) ==="
mutant_ast() { # mutant_ast <nom> <expression-sed> -> MUT_AST ; code 1 si la copie n'a pas changé
  MUT_AST="$WORK/assistant-$1.py"; cp "$PTYPY" "$MUT_AST"; cp "$MUT_AST" "$MUT_AST.orig"; sed -i.bak "$2" "$MUT_AST"
  local r=0; cmp -s "$MUT_AST" "$MUT_AST.orig" && r=1; rm -f "$MUT_AST.orig" "$MUT_AST.bak"; return $r
}
sans_effet() { assert_eq "$1 — mutant sans effet (cible absente ou inchangée)" "sans effet" "effet"; }
if mutant_ast gardien-absent 's/^    garde = lancer_gardien()$/    garde = None/'; then
  lancer "$MUT_AST" kill m128a
  assert_eq "M-GARDIEN-ABSENT — le mutant (aucun gardien) rougit T12.8a : nohup et trap '' HUP survivent au SIGKILL de l'assistant" "$SONDE_RES" "avant=4 groupes=4 dans-session=4 survivants=2 fin=code=-9"
else sans_effet "M-GARDIEN-ABSENT"; fi
if mutant_ast gardien-sans-sid 's/^    dire(garde, b.SID .*$/    dire(garde, b"")/'; then
  lancer "$MUT_AST" kill m128b
  assert_eq "M-GARDIEN-SANS-SID — le mutant (le gardien ne reçoit jamais le PID de la session) rougit T12.8a : mêmes survivants" "$SONDE_RES" "avant=4 groupes=4 dans-session=4 survivants=2 fin=code=-9"
else sans_effet "M-GARDIEN-SANS-SID"; fi

echo ""; echo "=================================="; echo "  Résultats : $PASS PASS / $FAIL FAIL"; echo "=================================="
[ $((PASS+FAIL)) -eq 0 ] && { echo "  ❌ ÉCHEC ANTI-VERT-À-VIDE"; exit 1; }
[ "$FAIL" -eq 0 ]
