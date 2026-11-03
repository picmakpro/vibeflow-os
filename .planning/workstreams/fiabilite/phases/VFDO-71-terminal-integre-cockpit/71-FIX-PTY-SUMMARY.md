---
phase: 71
plan: FIX-PTY
status: passed
requirements: [TERM-08]
commits:
  fix: 2a69a139
---

# 71-FIX-PTY — correction ciblée de l'assistant PTY : résumé

Mandat de correction ciblée (constats F2 et F3 de 71-02). Base de mesure : `6389c3d2`.

## Défaut 1 — écriture bloquante

- Re-mesuré : sur `6389c3d2`, un shell qui ne lit pas (`stty raw -echo; exec sleep 299`) et 65 536 octets POSTés : serveur tué par SIGKILL, l'assistant et le shell vivent encore
  après 6 s ; assistant seul, ni la fin du descripteur 0 ni SIGTERM ne le font sortir (`vivant`). Un shell en mode canonique avec écho ne le reproduit pas (le noyau jette l'excédent
  au lieu de bloquer) : la première version de la sonde, verte à vide, a été durcie en conséquence.
- Correction : maître et descripteur 1 non bloquants, deux tampons FIFO (entrée vers le shell, sortie vers le serveur) vidés quand `select` les dit prêts ; lecture du descripteur 0
  suspendue au-delà de 1 Mio en attente. Un `OSError` d'écriture au maître vide le tampon d'entrée (le shell est parti : `waitpid` le constate, `FIN`/`SIG` reste émis).
- Témoin rouge (`6389c3d2` + suite nouvelle) : `T14.1` obtenu `avant=oui oui POST=204 apres=oui oui` (attendu `... apres=non non`) ; `T14.2` et `T14.3` obtenu `vivant shell=non`
  (attendu `code=0 sig=null shell=non`). Vert : `test-cockpit-terminal-pty.sh` 39 PASS / 0 FAIL.
- Mutant `M-ECRITURE-BLOQUANTE` (`os.set_blocking(maitre, False)` -> `True` sur une copie du moteur) : `apres=oui oui`, la sonde rougit.
- Les mutants `M-SIGINT` et `M-CTRLC` visent désormais `vers_shell += donnees` (l'ancienne ligne n'existe plus).

## Défaut 2 — bornes de taille

- Re-mesuré : à `6389c3d2` l'assistant tenait déjà `0 < c <= 1000` (le constat F3 était périmé sur ce point). L'incohérence réelle était ailleurs : `GET /flux` acceptait jusqu'à 999 x 999
  (501 lignes et plus passaient, ETIMEDOUT = flux ouvert) et refusait 1000 colonnes (regex à 3 chiffres) ; l'assistant ne bornait pas sa taille de lancement.
- Borne unique retenue : 500 lignes x 1000 colonnes, celle du plan 71-02 et de l'assistant (choix : c'est la plus large des deux déjà tenues, aucun client existant n'est restreint).
  `TAILLE_MAX` est définie dans la session, réexportée par `vf-cockpit-terminal.mjs`, tenue par `/flux` (400), `/taille` (400) et l'assistant (ligne `R` ignorée hors borne, lancement hors borne : code 64).
- Témoin rouge : `T3.8d` 501x80 et 999x999 -> `ERREUR ETIMEDOUT` (attendu 400) ; `T11.6` (flux 500x1000) ABSENT ; `T11.8` obtenu `0 0` (attendu `64 64`). Vert : serveur 159 PASS / 0 FAIL.
- `T11.7` (ligne `R` hors borne ignorée) est une garde : déjà verte sur la base.

## Écarts

- Un `T12.4` a rougi une fois sur trois rejeux complets du lot (survivants), vert aux deux rejeux suivants et sur le vert de référence ; le code d'arrêt sur fin du descripteur 0 est inchangé.
  Hypothèse : charge concurrente (autre exécuteur dans l'arbre). Non établi, à surveiller.
- Fichiers hors liste : aucun. Aucun trailer `Gate-Touche` posé : les suites ne sont pas dans la surface de `check-gate-touche.sh` selon `71-02-SUMMARY.md` (non revérifié ici).
