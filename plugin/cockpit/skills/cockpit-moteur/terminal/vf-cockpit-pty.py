"""Assistant PTY du terminal intégré du cockpit VibeFlow (71-01, complété par 71-03).

Usage : python3 -I vf-cockpit-pty.py <lignes> <colonnes> <shell>

Lance <shell> -l dans un pseudo-terminal et sert de pont : le descripteur 0 est l'entrée du shell, le 1 sa sortie,
le 2 reçoit l'état (une ligne « FIN <code> » quand le shell sort, « SIG <n> » s'il est tué par un signal),
le 3 reçoit le contrôle (lignes « R <lignes> <colonnes> » : nouvelle taille du terminal).
Le dossier courant et l'environnement sont ceux du processus : le serveur les pose, cet assistant n'invente rien.

Arrêt : fin du descripteur 0 (le serveur est parti ou a fermé la session) ou SIGTERM -> SIGHUP au groupe du shell ET au groupe de
premier plan du terminal (un shell interactif se met dans son propre groupe : seul ce second groupe l'atteint, et il relaie SIGHUP à ses
travaux), fermeture du maître, au plus 3 s d'attente, SIGKILL des mêmes groupes, sortie. Limite : un processus détaché volontairement
(nohup, setsid, disown) ou un travail d'un shell qui ne relaie pas SIGHUP peut survivre. Aucun octet du shell n'est journalisé.
Compatible Python 3.9, aucune dépendance.
"""
import fcntl
import os
import pty
import select
import signal
import struct
import sys
import termios
import time

GRACE = 3.0
arret = False


def sur_term(signum, frame):
    global arret
    arret = True


def taille(maitre, lignes, colonnes):
    fcntl.ioctl(maitre, termios.TIOCSWINSZ, struct.pack('HHHH', lignes, colonnes, 0, 0))


def ecrire(fd, octets):
    while octets:
        n = os.write(fd, octets)
        octets = octets[n:]


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
            if 0 < l <= 500 and 0 < c <= 1000:
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


def vivants(gs):
    for g in gs:
        if g > 1:
            try:
                os.killpg(g, 0)
                return True
            except ProcessLookupError:
                pass
            except OSError:
                return True
    return False


def arreter(pid, maitre):
    """SIGHUP aux groupes, fermeture du maître, attente de 3 s au plus, SIGKILL des mêmes groupes si quelque chose reste."""
    gs = groupes(pid, maitre)
    signaler(gs, signal.SIGHUP)
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
        if reape and not vivants(gs):
            return
        time.sleep(0.05)
    signaler(gs, signal.SIGKILL)
    if not reape:
        try:
            os.waitpid(pid, 0)
        except ChildProcessError:
            pass


def vider(maitre):
    """Sortie restante du maître après la fin du shell."""
    for _ in range(64):
        pret, _, _ = select.select([maitre], [], [], 0.05)
        if not pret:
            return
        try:
            donnees = os.read(maitre, 65536)
        except OSError:
            return
        if not donnees:
            return
        ecrire(1, donnees)


def main():
    if len(sys.argv) != 4 or not sys.argv[1].isdigit() or not sys.argv[2].isdigit():
        sys.stderr.write('usage : vf-cockpit-pty.py <lignes> <colonnes> <shell>\n')
        return 64
    lignes, colonnes, shell = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
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
    entrees = [0, maitre, 3] if avec_controle else [0, maitre]
    controle = b''
    try:
        while not arret:
            pret, _, _ = select.select(entrees, [], [], 0.2)
            if 0 in pret:
                donnees = os.read(0, 65536)
                if not donnees:
                    break
                ecrire(maitre, donnees)
            if maitre in pret:
                try:
                    donnees = os.read(maitre, 65536)
                except OSError:
                    donnees = b''
                if donnees:
                    ecrire(1, donnees)
            if avec_controle and 3 in pret:  # sans canal de contrôle, le descripteur 3 peut être le maître lui-même
                donnees = os.read(3, 4096)
                if donnees:
                    controle = lire_controle(controle + donnees, maitre)
                else:
                    entrees.remove(3)
                    avec_controle = False
            termine, st = os.waitpid(pid, os.WNOHANG)
            if termine:
                vider(maitre)
                statut(2, fin_du_shell(pid, st))
                signaler(groupes(pid, maitre), signal.SIGHUP)
                return 0
    except OSError:
        pass
    arreter(pid, maitre)
    return 0


if __name__ == '__main__':
    code = main()
    sys.stdout.flush()
    os._exit(code)
