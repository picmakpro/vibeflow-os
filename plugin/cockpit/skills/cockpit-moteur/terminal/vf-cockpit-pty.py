# vibeflow:allow-large-file — dette de taille tracée (72-02) : fichier lancé en `python3 -I` (dossier absent de sys.path, décision de sécurité T-71-16), donc non découpable en modules frères sans changer ce sys.path isolé.
"""Assistant PTY du terminal intégré du cockpit VibeFlow (71-01, complété par 71-03 puis 72-02).

Usage : python3 -I vf-cockpit-pty.py <lignes> <colonnes> <shell>

Lance <shell> -l dans un pseudo-terminal et sert de pont : le descripteur 0 est l'entrée du shell, le 1 sa sortie,
le 2 reçoit l'état (une ligne « FIN <code> » quand le shell sort, « SIG <n> » s'il est tué par un signal),
le 3 reçoit le contrôle (lignes « R <lignes> <colonnes> » : nouvelle taille du terminal ; lignes « L <hex> » : écrire une ligne de commande au shell, voir plus bas).
Le dossier courant et l'environnement sont ceux du processus : le serveur les pose, cet assistant n'invente rien.

Entrées et sorties ne bloquent jamais : le maître et le descripteur 1 sont non bloquants, les octets en attente vont dans deux tampons (ordre
conservé), vidés quand select les dit prêts. Un shell qui ne lit pas son entrée, ou un lecteur lent, laisse donc l'assistant à l'écoute de la fin
du descripteur 0 et de SIGTERM (la lecture du descripteur 0 s'interrompt au-delà de TAMPON_MAX octets en attente : la contre-pression remonte au serveur).

Arrêt : fin du descripteur 0 (le serveur est parti ou a fermé la session), SIGTERM ou fin du shell -> SIGHUP aux groupes du shell et du
premier plan du terminal ET à chaque membre de la SESSION du terminal (le shell est chef de session : pty.fork() le met dans sa propre session),
fermeture du maître, au plus 3 s d'attente (0,5 s si le shell est déjà sorti), puis SIGKILL de tous les membres de la session relevés À CE
MOMENT-LÀ, relevé répété jusqu'à ce qu'il n'en reste aucun : nohup, disown et travaux d'arrière-plan (groupes à part) y sont compris (P71-D-28).
Le relevé s'appuie sur getsid(2) pour chaque PID du système (/proc, sinon ps en chemin absolu) : jamais d'identifiant de groupe figé, jamais de
motif de nom. Un zombie (état Z, lu dans /proc/<pid>/stat ou par `ps -o stat=`) n'est pas un membre vivant : sous Linux sans init il resterait
compté et consommerait la grâce. Un relevé qui ne contient pas l'assistant lui-même est inutilisable (/proc vide d'un bac à sable) : repli sur les
groupes. Garantie après le réapage du chef (réutilisation de PID) : sur le chemin normal (relevé des membres disponible), le PID du chef n'est plus jamais
signalé par kill(2), car chaque envoi relit d'abord la session du PID visé. Elle ne vaut PAS pour le repli (relevé impossible) : killpg(2) vise alors les groupes
relevés au départ, dont celui du chef (identifiant = son PID), même après son réapage ; si ce PID a été réutilisé entre-temps par un autre groupe, ce groupe peut être
signalé. Le repli ne sert que sans /proc ni `ps` utilisable, et le risque est celui d'une réutilisation de PID dans les 3 s de l'arrêt. Limite : un processus sorti de la session par setsid (ou par un double fork suivi de setsid) échappe à l'arrêt, y compris à celui du gardien.
Gardien (plantage de l'assistant : SIGKILL, SIGSEGV, exception Python non rattrapée, où arreter() ne s'exécute pas) : main() forke, AVANT pty.fork() (il ne détient
donc jamais le maître, ce qui supprimerait le SIGHUP noyau à la mort de l'assistant), un petit processus gardien relié par un tube. Le gardien sort de la session et du
groupe de l'assistant (setsid), a ses descripteurs 0, 1 et 2 sur /dev/null et ne garde que l'extrémité de lecture du tube (sinon la fin du serveur Node attendrait le gardien).
Protocole : l'assistant écrit « SID <pid> » après pty.fork(), puis « OK » après un arrêt propre (arreter() et la branche « shell sorti ») : le gardien sort alors sans rien faire.
Fin du tube SANS « OK » après un « SID » : l'assistant est mort. Le gardien rejoue SIGHUP aux membres de la session, la grâce, puis le SIGKILL répété (membres, envoyer_membres,
sigkill_session, getsid relu avant chaque envoi) ; il ne réape pas le shell (il n'est pas son parent) et sort dès que la session est vide, au plus GRACE + environ 2 s.
Limites du gardien : un gardien tué lui-même (SIGKILL avant ou pendant le ménage) laisse les survivants, comme avant ; un processus sorti de la session par setsid échappe au
gardien comme à arreter() ; sans relevé possible (ni /proc ni ps) il ne fait rien ; le fork du gardien échoue-t-il, l'assistant tourne sans lui.
Limites signalées en revue (aucune n'est corrigée ici, elles sont connues) : (1) le gardien n'est pas le parent du shell, donc il ne le réape jamais : le chef de la session n'est visé que par le contrôle
getsid, relu avant chaque envoi, sans le garde-fou « chef réapé » de l'assistant (CHEF_REAPE) ; (2) la borne « au plus GRACE + environ 2 s » suppose un `ps` qui répond vite : chaque relevé lance
`ps` (5 s de délai au plus par appel, sans /proc), la durée réelle de l'arrêt dépend donc de lui ; (3) la fenêtre entre pty.fork() et l'écriture de « SID » n'est pas couverte : un assistant qui meurt dans cet intervalle
laisse un gardien qui voit la fin du tube sans « SID » et ne ramasse rien, le shell déjà né reste alors sans gardien.
Lancement d'une ligne (72-02 ; P72-D-01, D-13, D-14) : « L <hex> » porte les octets d'une ligne de commande en hexadécimal (2 à 800 caractères, pairs). L'assistant la REVALIDE seul, sans faire
confiance à ce qui l'a envoyée : alphabet fermé [A-Za-z0-9 ._:/'-] en correspondance TOTALE (fullmatch : l'ancre de fin de ligne de Python tolère un saut de ligne final), au plus LIGNE_MAX octets, préfixe
« claude --session-id ' » et apostrophe finale. Puis, SEULEMENT si le shell est au premier plan du terminal (tcgetpgrp(maître) == pid du shell) et qu'aucune entrée n'attend déjà d'être écrite, il ajoute Ctrl-C PUIS la
ligne, SANS retour chariot, au tampon vers le shell et tente l'écriture tout de suite : la ligne attend à l'invite, seul un retour chariot humain (descripteur 0) l'exécute. Sinon il n'écrit RIEN (jamais de Ctrl-C
dans un programme de l'utilisateur). Chaque ligne « L » reçoit EXACTEMENT une réponse sur le descripteur 2 : « LANCE ok », « LANCE premier-plan », « LANCE alphabet » ou « LANCE invalide » (le nombre de mots différent
de deux est « invalide »). Limite : une ligne de plus de 1024 octets est abandonnée sans réponse (le reste de tampon est borné) ; la session n'en produit jamais (803 octets au plus). Un shell qui n'est pas le fils direct du
terminal (un $SHELL qui en lance un autre en sous-processus) n'est jamais « au repos » ici : refus sûr.
Aucun octet du shell et aucune ligne lancée ne sont journalisés.
Compatible Python 3.9, aucune dépendance.
"""
import fcntl
import os
import pty
import re
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
LIGNE_MAX = 400  # octets d'une ligne lancée : la même borne que LIGNE_MAX de vf-cockpit-terminal-session.mjs
PREFIXE_LIGNE = b"claude --session-id '"
ALPHABET_LIGNE = re.compile(rb"[A-Za-z0-9 ._:/'-]+")
HEX_LIGNE = re.compile(rb"(?:[0-9A-Fa-f]{2})+")
CTRL_C = bytes([3])
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


def decoder_ligne(hexa):
    """Décode l'hexadécimal d'une ligne « L » : (code, octets). Plus de 2 * LIGNE_MAX caractères, impair, vide ou non hexadécimal : « invalide »."""
    if len(hexa) > 2 * LIGNE_MAX:
        return 'invalide', b''
    if not HEX_LIGNE.fullmatch(hexa):
        return 'invalide', b''
    return 'ok', bytes.fromhex(hexa.decode('ascii'))


def valider_ligne(ligne):
    """Revalidation indépendante de la ligne : « alphabet » (jugé d'abord, correspondance totale), « invalide » (préfixe, apostrophe finale) ou « ok »."""
    if not ALPHABET_LIGNE.fullmatch(ligne):
        return 'alphabet'
    if len(ligne) <= len(PREFIXE_LIGNE):
        return 'invalide'
    if not (ligne.startswith(PREFIXE_LIGNE) and ligne.endswith(b"'")):
        return 'invalide'
    return 'ok'


def premier_plan_libre(maitre, pid):
    """Vrai si le shell lui-même occupe le premier plan du terminal (au repos, à l'invite) ; toute erreur du système vaut faux."""
    try:
        return os.tcgetpgrp(maitre) == pid
    except OSError:
        return False


def lancer_ligne(hexa, maitre, pid, vers_shell):
    """Écrit Ctrl-C puis la ligne (sans retour chariot) au shell s'il est au repos ; rend « ok », « premier-plan », « alphabet », « invalide » ou « ecriture » (écriture au PTY échouée)."""
    code, ligne = decoder_ligne(hexa)
    if code != 'ok':
        return code
    code = valider_ligne(ligne)
    if code != 'ok':
        return code
    if vers_shell:
        return 'premier-plan'  # une entrée déjà en attente d'écriture n'est pas un shell au repos : la file ne grossit pas devant un shell sourd
    if not premier_plan_libre(maitre, pid):
        return 'premier-plan'
    vers_shell += CTRL_C + ligne
    try:
        pousser(maitre, vers_shell)  # même passe de boucle ; le reste part au prochain select
    except OSError:
        del vers_shell[:]  # la ligne n'est pas partie : rien ne reste en file pour un shell qui ne l'a pas reçue
        return 'ecriture'
    return 'ok'


def lire_controle(tampon, maitre, pid=None, vers_shell=None):
    """Applique les lignes « R <lignes> <colonnes> » et « L <hex> » complètes du tampon (une réponse « LANCE … » par ligne L sur le descripteur 2), rend le reste."""
    while b'\n' in tampon:
        ligne, tampon = tampon.split(b'\n', 1)
        mots = ligne.split()
        if len(mots) == 3 and mots[0] == b'R' and mots[1].isdigit() and mots[2].isdigit():
            l, c = int(mots[1]), int(mots[2])
            if 0 < l <= LIGNES_MAX and 0 < c <= COLONNES_MAX:
                taille(maitre, l, c)
        elif mots and mots[0] == b'L':
            code = lancer_ligne(mots[1], maitre, pid, vers_shell) if len(mots) == 2 and vers_shell is not None else 'invalide'
            statut(2, 'LANCE ' + code)
    return tampon[-1024:]


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


PROC = '/proc'
GARDIEN = False  # vrai dans le processus gardien (voir gardien())
SID_CHEF = 0  # PID du shell (chef de sa session), posé par main()
CHEF_REAPE = False  # vrai dès que le chef de session (le shell) est réapé : son PID peut alors être réutilisé, il n'est plus jamais signalé


def etat_proc(p):
    """État d'un processus lu dans /proc/<pid>/stat (le caractère après la parenthèse fermante du nom), ou None s'il a disparu entre-temps."""
    try:
        with open('%s/%d/stat' % (PROC, p), 'rb') as f:
            t = f.read()
    except OSError:
        return None
    i = t.rfind(b')')
    return t[i + 2:i + 3].decode('ascii', 'replace') if i >= 0 else None


def releve():
    """{pid: état} de tous les processus du système, ou None si aucune source ne rend un relevé utilisable. Un relevé qui ne contient pas l'assistant
    lui-même est faux (/proc vide, bac à sable) : il n'est pas pris pour valide, la source suivante (ps par chemin absolu, jamais par PATH) est essayée."""
    moi = os.getpid()
    try:
        noms = [int(n) for n in os.listdir(PROC) if n.isdigit()]
    except OSError:
        noms = []
    r = {}
    for p in noms:
        e = etat_proc(p)
        if e is not None:
            r[p] = e
    if moi in r:
        return r
    for ps in ('/bin/ps', '/usr/bin/ps'):
        try:
            sortie = subprocess.run([ps, '-A', '-o', 'pid=,stat='], stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                                    timeout=5, env={'PATH': '/usr/bin:/bin'})
        except (OSError, subprocess.SubprocessError):
            continue
        if sortie.returncode != 0:
            continue
        r = {}
        for ligne in sortie.stdout.decode('ascii', 'replace').splitlines():
            mots = ligne.split()
            if len(mots) >= 2 and mots[0].isdigit():
                r[int(mots[0])] = mots[1]
        if moi in r:
            return r
    return None


def chef_reape():
    """Réape le chef de session sans bloquer ; vrai s'il est (ou était déjà) réapé."""
    global CHEF_REAPE
    if GARDIEN:
        return CHEF_REAPE  # le gardien n'est pas le parent du shell : jamais de waitpid, le contrôle getsid suffit
    try:
        if os.waitpid(SID_CHEF, os.WNOHANG)[0]:
            CHEF_REAPE = True
    except ChildProcessError:
        CHEF_REAPE = True
    return CHEF_REAPE


def vise(p, sid):
    """Vrai si p est un membre vivant de la session sid : getsid par PID, jamais un zombie, jamais le chef réapé."""
    if CHEF_REAPE and p == sid:
        return False
    try:
        return os.getsid(p) == sid
    except OSError:
        return False


def membres(sid):
    """Membres vivants de la session `sid` (getsid par PID : borné à cette session, rien d'autre n'est visé), ou None si le relevé est impossible."""
    r = releve()
    if r is None:
        return None
    moi = os.getpid()
    return [p for p, e in r.items() if p > 1 and p != moi and not e.startswith('Z') and vise(p, sid)]


def envoyer_membres(sid, sig):
    """Signale chaque membre de la session ; la session est relue juste avant chaque envoi (PID réutilisé entre-temps : ignoré). Rend les membres visés."""
    ms = membres(sid)
    for p in ms or []:
        try:
            if vise(p, sid):
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
        chef_reape()  # le chef de session, s'il vient de tomber, ne reste pas zombie dans le relevé
        ms = envoyer_membres(sid, signal.SIGKILL)
        if ms is None:
            signaler(gs, signal.SIGKILL)  # relevé impossible : repli sur les groupes relevés au départ
            return
        if not ms:
            return
        time.sleep(0.05)


def arreter(pid, maitre):
    """SIGHUP aux groupes et à la session, fermeture du maître, attente de 3 s au plus, SIGKILL de tous les membres de la session s'il en reste."""
    global CHEF_REAPE
    sid = pid  # pty.fork() : le shell est chef de sa propre session, dont l'identifiant est son PID
    gs = groupes(pid, maitre)
    signaler(gs, signal.SIGHUP)
    envoyer_membres(sid, signal.SIGHUP)
    try:
        os.close(maitre)
    except OSError:
        pass
    fin = time.time() + GRACE
    while time.time() < fin:
        reape = chef_reape()
        if reape and not vivants(sid, gs):
            return
        time.sleep(0.05)
    sigkill_session(sid, gs)
    if not chef_reape():
        try:
            os.waitpid(pid, 0)
        except ChildProcessError:
            pass
        CHEF_REAPE = True
    sigkill_session(sid, gs)  # la mort du chef peut libérer des travaux : dernier relevé


def ramasser(sid):
    """Ménage du gardien : SIGHUP aux membres de la session, grâce, puis SIGKILL répété. Sort dès que la session est vide."""
    envoyer_membres(sid, signal.SIGHUP)
    fin = time.time() + GRACE
    while time.time() < fin:
        if not membres(sid):  # vide, ou relevé impossible (rien à faire)
            return
        time.sleep(0.05)
    sigkill_session(sid, set())


def gardien(r):
    """Processus gardien : lit le tube jusqu'à sa fin ; sans « OK » après un « SID <pid> », l'assistant est mort : ramasse la session."""
    global GARDIEN
    GARDIEN = True
    signal.signal(signal.SIGTERM, signal.SIG_DFL)
    signal.signal(signal.SIGHUP, signal.SIG_IGN)
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    os.setsid()
    r = fcntl.fcntl(r, fcntl.F_DUPFD, 10)  # hors de 0-2 et du bas de la table, que le ménage ci-dessous referme
    nul = os.open(os.devnull, os.O_RDWR)
    for fd in (0, 1, 2):
        os.dup2(nul, fd)
    os.closerange(3, r)
    try:
        maxfd = min(os.sysconf('SC_OPEN_MAX'), 65536)
    except (ValueError, OSError):
        maxfd = 4096
    os.closerange(r + 1, maxfd)
    sid = None
    tampon = b''
    while True:
        try:
            donnees = os.read(r, 256)
        except OSError:
            break
        if not donnees:
            break
        tampon += donnees
        while b'\n' in tampon:
            ligne, tampon = tampon.split(b'\n', 1)
            if ligne == b'OK':
                return
            mots = ligne.split()
            if len(mots) == 2 and mots[0] == b'SID' and mots[1].isdigit():
                sid = int(mots[1])
    if sid is not None and sid > 1:
        ramasser(sid)


def lancer_gardien():
    """Forke le gardien AVANT pty.fork() ; rend l'extrémité d'écriture du tube (non héritable : le shell ne la garde pas), ou None si le fork échoue."""
    try:
        r, w = os.pipe()
    except OSError:
        return None
    try:
        g = os.fork()
    except OSError:
        os.close(r)
        os.close(w)
        return None
    if g == 0:
        try:
            os.close(w)
            gardien(r)
        finally:
            os._exit(0)
    os.close(r)
    return w


def dire(w, ligne):
    """Écrit une ligne au gardien (sans effet s'il n'y en a pas)."""
    if w is None:
        return
    try:
        os.write(w, ligne)
    except OSError:
        pass


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
    global CHEF_REAPE, SID_CHEF
    signal.signal(signal.SIGTERM, sur_term)
    avec_controle = True
    try:
        os.set_inheritable(3, False)  # le shell et ses travaux ne gardent pas le canal de contrôle
    except OSError:
        avec_controle = False  # lancé sans canal de contrôle : la taille initiale reste la seule
    garde = lancer_gardien()
    pid, maitre = pty.fork()
    if pid == 0:
        try:
            os.execvp(shell, [shell, '-l'])
        finally:
            os._exit(127)
    SID_CHEF = pid
    dire(garde, b'SID %d\n' % pid)
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
                    controle = lire_controle(controle + donnees, maitre, pid, vers_shell)
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
                CHEF_REAPE = True  # réapé : le PID du chef peut être réutilisé, envoyer_membres ne le signale plus
                vider(maitre, vers_serveur)
                statut(2, fin_du_shell(pid, st))
                gs = groupes(pid, maitre)
                signaler(gs, signal.SIGHUP)
                envoyer_membres(pid, signal.SIGHUP)
                time.sleep(0.5)  # le temps de relayer SIGHUP ; ce qui reste de la session (nohup, disown) est tué
                sigkill_session(pid, gs)
                dire(garde, b'OK\n')
                return 0
    except OSError:
        pass
    arreter(pid, maitre)
    dire(garde, b'OK\n')
    return 0


if __name__ == '__main__':
    code = main()
    sys.stdout.flush()
    os._exit(code)
