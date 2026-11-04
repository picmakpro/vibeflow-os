# plein-ecran.py : témoin de TERM-09 (écran alterné, 256 couleurs, truecolor, SIGWINCH, SIGINT).
# Programme plein écran minimal que la suite test-cockpit-terminal-pty.sh lance dans le terminal intégré ; il écrit ce qu'il observe
# (taille lue sur le terminal, signaux reçus) pour que la suite le retrouve dans le flux. Bibliothèque standard seulement, Python 3.9.
import os
import signal
import sys
import time


def w(s):
    sys.stdout.write(s)
    sys.stdout.flush()


def taille():
    c, l = os.get_terminal_size(sys.stdout.fileno())  # pas shutil : il lit COLUMNS et LINES d'abord
    return "%dx%d" % (l, c)


def winch(*_):
    w("WINCH %s\r\n" % taille())


def intr(*_):
    w("\x1b[?1049l")
    w("SIGINT-RECU\r\n")
    os._exit(0)


w("\x1b[?1049h\x1b[2J\x1b[H")
w("TEMOIN-PLEIN-ECRAN-DEBUT\r\n")
w("".join("\x1b[48;5;%dm \x1b[0m" % n for n in range(16, 232, 6)) + "\r\n")
w("\x1b[38;2;255;100;0mTRUECOLOR\x1b[0m\r\n")
w("TAILLE %s\r\n" % taille())
signal.signal(signal.SIGWINCH, winch)
signal.signal(signal.SIGINT, intr)
w("PRET\r\n")
while True:
    time.sleep(0.05)
