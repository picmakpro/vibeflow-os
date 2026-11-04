"""Assistant PTY du terminal intégré du cockpit VibeFlow (71-01, complété par 71-03).

Usage : python3 -I vf-cockpit-pty.py <lignes> <colonnes> <shell>

Lance <shell> -l dans un pseudo-terminal et sert de pont : le descripteur 0 est l'entrée du shell, le 1 sa sortie,
le 2 reçoit l'état (une ligne « FIN <code> » quand le shell sort, « SIG <n> » s'il est tué par un signal),
le 3 reçoit le contrôle (lignes « R <lignes> <colonnes> » : nouvelle taille du terminal).
Le dossier courant et l'environnement sont ceux du processus : le serveur les pose, cet assistant n'invente rien.

Entrées et sorties ne bloquent jamais : le maître et le descripteur 1 sont non bloquants, les octets en attente vont dans deux tampons (ordre
conservé), vidés quand select les dit prêts. Un shell qui ne lit pas son entrée, ou un lecteur lent, laisse donc l'assistant à l'écoute de la fin
du descripteur 0 et de SIGTERM (la lecture du descripteur 0 s'interrompt au-delà de TAMPON_MAX octets en attente : la contre-pression remonte au serveur).

Arrêt : fin du descripteur 0 (le serveur est parti ou a fermé la session), SIGTERM ou fin du shell -> SIGHUP aux groupes du shell et du
premier plan du terminal ET à chaque membre de la SESSION du terminal (le shell est chef de session : pty.fork() le met dans sa propre session),
fermeture du maître, au plus 3 s d'attente (0,5 s si le shell est déjà sorti), puis SIGKILL de tous les membres de la session relevés À CE
MOMENT-LÀ, relevé répété jusqu'à ce qu'il n'en reste aucun : nohup, disown et travaux d'arrière-plan (groupes à part) y sont compris (P71-D-28).
Le relevé s'appuie sur getsid(2) pour chaque PID du système (/proc, sinon ps en chemin absolu) : jamais d'identifiant de groupe figé, jamais de
motif de nom. Limite : un processus sorti de la session par setsid (ou par un double fork suivi de setsid) échappe à l'arrêt.
Aucun octet du shell n'est journalisé.
Compatible Python 3.9, aucune dépendance.
"""
import fcntl
import os
import pty
import select
import signal
import struct
import subprocess
import sys
import termios
import time

GRACE = 3.0
LIGNES_MAX = 500  # bornes de taille : les mêmes que TAILLE_MAX du serveur (vf-cockpit-terminal-session.mjs)
COLONNES_MAX = 1000
TAMPON_MAX = 1 << 20
MORCEAU = 65536
arret = False


def sur_term(signum, frame):
    global arret
    arret = True


def taille(maitre, lignes, colonnes):
    fcntl.ioctl(maitre, termios.TIOCSWINSZ, struct.pack('HHHH', lignes, colonnes, 0, 0))


def pousser(fd, tampon):
    """Une tentative d'écriture non bloquante : retire du tampon ce qui est parti. BrokenPipeError / EIO remontent à l'appelant."""
    try:
        n = os.write(fd, bytes(tampon[:MORCEAU]))
    except BlockingIOError:
        return
    del tampon[:n]


def purger(fd, tampon, delai):
    """Vide le tampon vers fd en attendant au plus `delai` secondes (fin du shell : sortie restante)."""
    fin = time.time() + delai
    while tampon and time.time() < fin:
        _, pret, _ = select.select([], [fd], [], 0.05)
        if pret:
            pousser(fd, tampon)


def statut(fd, code):
    try:
        os.write(fd, code.encode() + b'\n')
    except OSError:
        pass


def fin_du_shell(pid, st):
    if os.WIFSIGNALED(st):
        return 'SIG %d' % os.WTERMSIG(st)
    return 'FIN %d' % os.WEXITSTATUS(st)


def lire_controle(tampon, maitre):
    """Applique les lignes « R <lignes> <colonnes> » complètes du tampon, rend le reste."""
    while b'\n' in tampon:
        ligne, tampon = tampon.split(b'\n', 1)
        mots = ligne.split()
        if len(mots) == 3 and mots[0] == b'R' and mots[1].isdigit() and mots[2].isdigit():
            l, c = int(mots[1]), int(mots[2])
            if 0 < l <= LIGNES_MAX and 0 < c <= COLONNES_MAX:
                taille(maitre, l, c)
    return tampon[-256:]


def groupes(pid, maitre):
    """Groupe du shell et groupe de premier plan du terminal (distincts dès que le shell interactif a son propre groupe)."""
    gs = {pid}
    try:
        gs.add(os.tcgetpgrp(maitre))
    except OSError:
        pass
    return gs


def signaler(gs, sig):
    for g in gs:
        if g > 1:
            try:
                os.killpg(g, sig)
            except OSError:
                pass


def pids_systeme():
    """Tous les PID du système, ou None si aucune source n'est lisible (/proc, sinon ps par chemin absolu : jamais une résolution par PATH)."""
    try:
        return [int(n) for n in os.listdir('/proc') if n.isdigit()]
    except OSError:
        pass
    for ps in ('/bin/ps', '/usr/bin/ps'):
        try:
            r = subprocess.run([ps, '-A', '-o', 'pid='], stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                               timeout=5, env={'PATH': '/usr/bin:/bin'})
            if r.returncode == 0:
                return [int(x) for x in r.stdout.split() if x.isdigit()]
        except (OSError, subprocess.SubprocessError):
            continue
    return None


def membres(sid):
    """Membres vivants de la session `sid` (getsid par PID : borné à cette session, rien d'autre n'est visé), ou None si le relevé est impossible."""
    tous = pids_systeme()
    if tous is None:
        return None
    moi = os.getpid()
    sortie = []
    for p in tous:
        if p > 1 and p != moi:
            try:
                if os.getsid(p) == sid:
                    sortie.append(p)
            except OSError:
                pass
    return sortie


def envoyer_membres(sid, sig):
    """Signale chaque membre de la session ; la session est relue juste avant chaque envoi (PID réutilisé entre-temps : ignoré). Rend le nombre de membres visés."""
    ms = membres(sid)
    for p in ms or []:
        try:
            if os.getsid(p) == sid:
                os.kill(p, sig)
        except OSError:
            pass
    return ms


def vivants(sid, gs):
    ms = membres(sid)
    if ms is not None:
        return bool(ms)
    for g in gs:  # relevé impossible : repli sur les groupes relevés au départ
        if g > 1:
            try:
                os.killpg(g, 0)
                return True
            except ProcessLookupError:
                pass
            except OSError:
                return True
    return False


def sigkill_session(sid, gs):
    """SIGKILL de tous les membres de la session, relevés au moment de l'arrêt, répété tant qu'il en reste (un fork en cours de route est repris au tour suivant)."""
    for _ in range(40):
        try:
            os.waitpid(sid, os.WNOHANG)  # le chef de session, s'il vient de tomber, ne reste pas zombie dans le relevé
        except ChildProcessError:
            pass
        ms = envoyer_membres(sid, signal.SIGKILL)
        if ms is None:
            signaler(gs, signal.SIGKILL)  # relevé impossible : repli sur les groupes relevés au départ
            return
        if not ms:
            return
        time.sleep(0.05)


def arreter(pid, maitre):
    """SIGHUP aux groupes et à la session, fermeture du maître, attente de 3 s au plus, SIGKILL de tous les membres de la session s'il en reste."""
    sid = pid  # pty.fork() : le shell est chef de sa propre session, dont l'identifiant est son PID
    gs = groupes(pid, maitre)
    signaler(gs, signal.SIGHUP)
    envoyer_membres(sid, signal.SIGHUP)
    try:
        os.close(maitre)
    except OSError:
        pass
    reape = False
    fin = time.time() + GRACE
    while time.time() < fin:
        if not reape:
            try:
                reape = bool(os.waitpid(pid, os.WNOHANG)[0])
            except ChildProcessError:
                reape = True
        if reape and not vivants(sid, gs):
            return
        time.sleep(0.05)
    sigkill_session(sid, gs)
    if not reape:
        try:
            os.waitpid(pid, 0)
        except ChildProcessError:
            pass
    sigkill_session(sid, gs)  # la mort du chef peut libérer des travaux : dernier relevé


def vider(maitre, sortie):
    """Sortie restante du maître après la fin du shell, poussée vers le descripteur 1 (2 s au plus)."""
    for _ in range(64):
        pret, _, _ = select.select([maitre], [], [], 0.05)
        if not pret:
            break
        try:
            donnees = os.read(maitre, 65536)
        except OSError:
            break
        if not donnees:
            break
        sortie += donnees
    purger(1, sortie, 2.0)


def main():
    if len(sys.argv) != 4 or not sys.argv[1].isdigit() or not sys.argv[2].isdigit():
        sys.stderr.write('usage : vf-cockpit-pty.py <lignes> <colonnes> <shell>\n')
        return 64
    lignes, colonnes, shell = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
    if not (0 < lignes <= LIGNES_MAX and 0 < colonnes <= COLONNES_MAX):
        sys.stderr.write('taille hors bornes\n')
        return 64
    signal.signal(signal.SIGTERM, sur_term)
    avec_controle = True
    try:
        os.set_inheritable(3, False)  # le shell et ses travaux ne gardent pas le canal de contrôle
    except OSError:
        avec_controle = False  # lancé sans canal de contrôle : la taille initiale reste la seule
    pid, maitre = pty.fork()
    if pid == 0:
        try:
            os.execvp(shell, [shell, '-l'])
        finally:
            os._exit(127)
    taille(maitre, lignes, colonnes)
    os.set_blocking(maitre, False)
    os.set_blocking(1, False)
    controle = b''
    vers_shell = bytearray()  # entrée reçue, pas encore écrite au maître
    vers_serveur = bytearray()  # sortie du shell, pas encore écrite sur le descripteur 1
    try:
        while not arret:
            lire = [maitre] if len(vers_serveur) < TAMPON_MAX else []
            if len(vers_shell) < TAMPON_MAX:
                lire.append(0)
            if avec_controle:
                lire.append(3)  # sans canal de contrôle, le descripteur 3 peut être le maître lui-même
            ecrire = ([maitre] if vers_shell else []) + ([1] if vers_serveur else [])
            pret, pret_e, _ = select.select(lire, ecrire, [], 0.2)
            if 0 in pret:
                donnees = os.read(0, 65536)
                if not donnees:
                    break
                vers_shell += donnees
            if maitre in pret:
                try:
                    donnees = os.read(maitre, 65536)
                except OSError:
                    donnees = b''
                if donnees:
                    vers_serveur += donnees
            if avec_controle and 3 in pret:
                donnees = os.read(3, 4096)
                if donnees:
                    controle = lire_controle(controle + donnees, maitre)
                else:
                    avec_controle = False
            if maitre in pret_e:
                try:
                    pousser(maitre, vers_shell)
                except OSError:
                    del vers_shell[:]  # le shell n'est plus là : waitpid le dit ci-dessous
            if 1 in pret_e:
                pousser(1, vers_serveur)  # BrokenPipeError : le serveur est parti -> arrêt
            termine, st = os.waitpid(pid, os.WNOHANG)
            if termine:
                vider(maitre, vers_serveur)
                statut(2, fin_du_shell(pid, st))
                gs = groupes(pid, maitre)
                signaler(gs, signal.SIGHUP)
                envoyer_membres(pid, signal.SIGHUP)
                time.sleep(0.5)  # le temps de relayer SIGHUP ; ce qui reste de la session (nohup, disown) est tué
                sigkill_session(pid, gs)
                return 0
    except OSError:
        pass
    arreter(pid, maitre)
    return 0


if __name__ == '__main__':
    code = main()
    sys.stdout.flush()
    os._exit(code)
