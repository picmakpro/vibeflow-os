---
phase: 71
plan: FIX-A2
status: passed
requirements: [TERM-02, TERM-08]
commits:
  client: 1807edc0
  session: 59aabd29
  tests: a658f9ec
---

# 71-FIX-A2 — correction ciblée (lot A2) : robustesse du client et de la session, dette de test

Base de mesure : `3af2cdb9` (code des deux modules identique à `01fb340b`). Les témoins rouges viennent de deux sources : la suite NOUVELLE rejouée sur une extraction
`git archive 3af2cdb9 plugin/cockpit` (code d'avant), et, pour la dette de test, des mutants nommés sur copie. Aucun mutant ne tourne dans l'arbre.

## Constats de comportement

| Constat | Témoin rouge (code d'avant) | Correction | Vert |
|---|---|---|---|
| J2 secret périmé | J2.1 obtenu `erreurs={"carte-expiree":"attente de « carte Session expirée (secret périmé) » dépassée (20000 ms)"} carte=Reconnexion…` | `/flux` rendant 403 : le client interroge `POST /taille` (corps vide) ; 401 = secret périmé -> carte « Session expirée » ; sinon réessai comme avant. Serveur inchangé. Serveur réellement arrêté : le `fetch` échoue, la sonde n'est pas appelée, « Serveur arrêté » reste atteint (J2.2, garde déjà verte sur la base) | J2.1 (< 10 s), J2.2 |
| J12 « Terminé » | J12.2 obtenu `bandeau=false session=vivante` | l'état (`termine` avec code/signal, ou `fermee`) est retenu dans le sessionStorage de Q (clé `vf.terminal.fin`) ; au chargement le bandeau est rejoué sans appeler `/flux` ; « Relancer le shell » l'efface et relance ; un nouvel amorçage l'efface | J12.1 à J12.3 |
| S5 onBinary | S5.1 obtenu `erreurs={"souris":"attente de « rapport de souris (onBinary) revenu du shell » dépassée"} rapport=false` (suivi souris en codage par défaut, que xterm émet par `onBinary`, écho du noyau `^[[M`) | `term.onBinary` relayé en octets bruts dans la même file que `onData` | S5.1 |
| S3 entrée non bornée | S3.1 (pty) obtenu `{"204":60}` (60 POST de 64 Kio vers un shell sourd, tous acceptés) | `ecrire` rend 429 quand `writableLength + octets > ENTREE_ATTENTE_MAX` (262 144) ; rien n'est écrit ; le client garde ses octets (`unshift`) et réessaie après 100 ms. Test client S3.1 : `fetch` truqué rendant 429 deux fois, la commande saisie s'exécute quand même (trois POST au moins) | S3.1 serveur : `borne` (429 présents, 204 <= 30, somme 60) ; S3.1 client |
| S4 deux shells | S4.1 obtenu `max=2 ancien=mort nouveau=oui` (shell qui ignore SIGHUP : l'ancien assistant met 3 s à mourir, grâce de 300 ms) | `expirer` met la session en `fermeture` (la place reste prise, `/etat` dit `absente`) ; `attacher` rend 503 tant que l'ancienne n'est pas morte ; `terminer` libère la place ; garde-fou SIGTERM à 6 s | S4.1 `max=1 ancien=mort nouveau=oui` |
| Sp2 grâce par défaut | aucune assertion (la suite fixe la grâce par variable d'environnement) | Sp2.1 importe le module de la sortie sans override et lit `GRACE_MS` ; Sp2.2 : réglage valide pris, hors plage ou illisible = 30 000 | M-GRACE-DEFAUT (défaut 15 000) rougit Sp2.1 |
| S2 `mode_de` | S2.0 : l'ancienne forme rend du bruit sous le faux GNU (`File: "…" ID: 0 …`, exit 0) et `bruit + 600` sous le faux uutils (imprime puis échoue) | GNU d'abord, validé en octal, BSD ensuite (`reindex.sh:90-98`) | S2.1 : 600 sous faux GNU, faux uutils, faux BSD et le `stat` réel |
| S6 L5 sous Linux | forme d'avant sous un `ps` qui refuse `-E` : `SKIP (PSENV vide)` (tracé à la main, voir ci-dessous) | `env_du_serveur` lit `/proc/<pid>/environ` d'abord, `ps -Eww` ensuite ; L5.0 prouve, avec faux `ps` et faux `/proc`, que le contrôle est joué (oui / non / saute) | L5.0 `oui non saute` ; L5 réel joué sous macOS |

Trace S2 (code d'avant, reproduite à la main sur faux `stat`) : `ancien/gnu: [  File: "…/f"| ID: 0 Namelen: 255|]` · `ancien/uutils: [  File: … |600|]` · `nouveau/*: [600]`.
Trace S6 (forme d'avant) : `ps -Eww` refusé -> `PSENV` vide -> `ancien L5 environnement : SKIP`.

## Dette de test F7 (assertion rouge sur mutant, toujours sur copie)

| Cible | Assertion | Mutant (rouge) |
|---|---|---|
| T-71-10 temps constant | TC.1 : `egal=2 directes=0 condense=oui` (deux sites `egal(…secret)`, aucune comparaison directe hors commentaires, `timingSafeEqual` dans `egal`) ; TC.0 témoin (la sonde voit un `===` dans un fichier jetable) | M-TEMPS-CONSTANT (`===` aux deux sites), M-EGAL (`a === b` dans `egal`) |
| Moteur sous `.vibeflow/` / assistant en lien | TM.0 témoin (moteur ordinaire = terminal actif), TM.1, TM.2 (terminal inerte, journal « assistant introuvable ») | M-MOTEUR-VIBEFLOW (garde `realUnder` retirée), M-MOTEUR-LIEN (`lstat` -> `stat`) |
| `set_inheritable(3)` | T11.9 : `{ : >&3; }` échoue dans le shell (`FD3-FERME` vu, `FD3-OUVERT` jamais) | M-INHERIT (`True`) : `ABSENT TROUVE` |
| Vidage du tampon à la fin de la grâce | T15.3 : nouvelle attache après expiration, aucun rejeu (témoins : marqueur vu avant, nouvelle session répond) | M-TAMPON-GRACE (tout appel à `vider()` retiré) |
| Contre-pression sur la réponse | CP.1 : lecteur à l'arrêt 5 s, le shell produit 40 Mo : drapeau absent à 3,5 s, présent après reprise (rien de perdu) | M-CONTREPRESSION (`!cible.pause` neutralisé) |
| TD.1 | M-TD1 : écouteur `upgrade` qui accepte -> 101 au lieu de 401 | rougit TD.1 |
| L11b | M-LEURRE-TERMINAL : arrêt sans garde sur la voie `--terminal` seule -> sortie ≠ 5 (L11, voie `--rebuild`, reste verte) | rougit L11b |
| S3 (serveur) | M-ATTENTE-NON-BORNEE : borne retirée -> 60 acceptés | rougit S3.1 |
| Client | M-J2, M-J12, M-S5, M-429 | rougissent J2.1, J12.2, S5.1, S3.1 |

## Écarts et limites

- `terminal-aux.mjs` (hors liste) n'a pas été touché : les clients de rafale et de lecteur lent sont des fichiers jetables de chaque suite (`rafale.mjs`, `lent.mjs`).
- Sous charge (deux suites dont une navigateur en parallèle) les scénarios Chrome `termine`, `binaire`, `pression` ont une fois manqué l'invite du shell en 20 s, et T12.5 de la suite session est sortie ; rejoués seuls, tout est vert. Les suites ne doivent pas se rejouer en parallèle.
- L5 sous Linux n'a pas pu être joué sur un vrai Linux depuis ce poste : la preuve est la sonde L5.0 (faux `ps`, faux `/proc`), à confirmer par la CI Linux.
- Le 503 d'une attache pendant la fermeture est invisible pour l'utilisateur dans la boucle de reconnexion du client (échec -> nouvel essai) ; il dure au plus 3 s (6 s au pire, garde-fou).
- Non traité (hors mandat) : F1 et F2 de l'audit, réservés au lot de sécurité.
- Un zombie pas encore réapé fausse un compte d'assistants par `pgrep -P` : la sonde S4 ne compte que les enfants vivants, et `terminer` ne rend la place qu'après l'événement `exit` de l'assistant.

## Suites rejouées en série sur le code final (aucune en parallèle)

client 47 PASS / 0 FAIL · session 38 / 0 · serveur 196 / 0 · pty 43 / 0 · lanceur 37 / 0 · activation 40 / 0.
Gates : `check-machine-paths.sh` ✓ (2445 fichiers), `check-file-size.sh --all` ✓ (0 avertissement), `check-python-isolation.sh` OK.
