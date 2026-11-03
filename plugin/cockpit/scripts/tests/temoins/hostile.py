# hostile.py : témoin de TERM-10 (séquences hostiles émises par un programme du terminal, entrée brute relevée en hexadécimal).
# Mode par défaut : <fichier> [secondes] — passe le terminal en brut, émet OSC 52 (écriture puis lecture), OSC 8 (lien « LIEN » vers
#   https://exemple.test/), un DCS quelconque, XTGETTCAP, CSI 21t/18t/14t/16t, DECRQSS puis DA1 (ESC[c) ; relève tout ce qui revient dans son entrée
#   et l'écrit en hexadécimal (un seul mot, minuscules) dans <fichier> ; s'arrête quand la réponse à DA1 est complète suivie d'un court
#   silence, ou à l'échéance (4 secondes par défaut). Écrit HOSTILE-FIN une fois le terminal restauré.
# Mode --recepteur <fichier> <secondes> : lecture brute seule (touches), même sortie ; s'arrête sur l'octet « z » (0x7a, sentinelle) ou à l'échéance ;
#   écrit RECEPTEUR-PRET quand il est prêt à lire et RECEPTEUR-FIN une fois le terminal restauré.
# Bibliothèque standard seulement, Python 3.9 ; le terminal est restauré même sur exception.
import os
import select
import sys
import termios
import time
import tty


def ecrire(s):
    sys.stdout.write(s)
    sys.stdout.flush()


def lire(fichier, echeance, fin_sur):
    """Le terminal est DÉJÀ en mode brut (l'appelant) : lit l'entrée jusqu'à `fin_sur(octets)` vrai ou l'échéance ; écrit l'hexadécimal dans `fichier`."""
    fd = sys.stdin.fileno()
    recu = b""
    try:
        limite = time.time() + echeance
        silence = None
        while time.time() < limite:
            pret, _, _ = select.select([fd], [], [], 0.05)
            if pret:
                recu += os.read(fd, 4096)
            if fin_sur(recu):
                silence = silence or time.time() + 0.4
            if silence and time.time() >= silence:
                break
    finally:
        with open(fichier, "w") as f:
            f.write(recu.hex())
    return recu


def emettre_hostile():
    ecrire("\x1b]52;c;aG9zdGlsZQ==\x1b\\")  # OSC 52 : écriture dans le presse-papiers
    ecrire("\x1b]52;c;?\x1b\\")  # OSC 52 : lecture du presse-papiers
    ecrire("\x1b]8;;https://exemple.test/\x1b\\LIEN\x1b]8;;\x1b\\\r\n")  # OSC 8 : lien
    ecrire("\x1bP0;0|414243\x1b\\")  # DCS quelconque
    ecrire("\x1bP+q436f\x1b\\")  # XTGETTCAP
    ecrire("\x1b[21t")  # CSI 21t : lecture du titre de la fenêtre
    ecrire("\x1b[18t")  # CSI 18t : taille de la fenêtre en caractères (le xterm.js livré répond à 14t, 16t et 18t, pas à 21t)
    ecrire("\x1b[14t")  # CSI 14t : taille en pixels
    ecrire("\x1b[16t")  # CSI 16t : taille d'une cellule
    ecrire("\x1bP$qm\x1b\\")  # DECRQSS : requête d'état (SGR)
    ecrire("\x1b[c")  # DA1 : seule requête dont la réponse est légitime


def da1_complet(octets):
    i = octets.rfind(b"\x1b[?")
    return i >= 0 and octets.endswith(b"c") and len(octets) - i > 3


def main(argv):
    fd = sys.stdin.fileno()
    ancien = termios.tcgetattr(fd)
    recepteur = len(argv) >= 4 and argv[1] == "--recepteur"
    try:
        tty.setraw(fd)  # brut AVANT d'émettre : les réponses ne sont ni écho ni retenues par la discipline de ligne
        if recepteur:
            ecrire("RECEPTEUR-PRET\r\n")
            lire(argv[2], float(argv[3]), lambda o: b"z" in o)
        else:
            emettre_hostile()
            lire(argv[1], float(argv[2]) if len(argv) > 2 else 4.0, da1_complet)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, ancien)
    ecrire("\r\n" + ("RECEPTEUR-FIN" if recepteur else "HOSTILE-FIN") + "\r\n")


if __name__ == "__main__":
    main(sys.argv)
