---
phase: 71
plan: FIX-W4
status: passed
requirements: [TERM-02, TERM-08]
---

# 71-FIX-W4 — correction ciblée (lot W4, page du terminal, côté Q)

Arbitrages : P71-D-34 « Corriger E2 à E5 (Recommandé) » et P71-D-35 « G1 tiroir et cadrage, G2 arrêt immédiat, G3 défilement discret »
(AskUserQuestion, session principale Claude Code, 2026-11-04 ; texte dans `71-CONTEXT.md`).

## Constats de comportement

| Constat | Témoin rouge (code d'avant) | Correction | Vert |
|---|---|---|---|
| E3 dernière ligne coupée | mutant M-SANS-MARGE (= le code d'avant : addon-fit seul) rougit E3.1 ; débordement de 1 à 6 px mesuré par le juge A | `ajuster()` : après `fit.fit()`, le nombre de lignes est recalculé sur la hauteur utile (`clientHeight` moins les marges internes de `#terminal`), jamais augmenté | E3.1 (160, 208, 280, 328, 570 px), E3.2 |
| G2 arrêt volontaire | `etat.mjs arret` sur HEAD : `cartes=@jamais bandeaux=oui flux=3` (reconnexion) | à la fin du flux, `/etat` = `{"etat":"arret"}` : carte « Serveur arrêté » + `etat:arrete`, sortie de la boucle | G2.1 (carte en moins de 500 ms, un flux), témoin G2.2 (vraie coupure : reconnexion gardée) |
| E4 Python 3 absent | `etat.mjs python` sur HEAD : `cartes=@jamais bandeaux=oui` (boucle de reconnexion) | `/etat` = `indisponible` / `python3-absent` : carte `python` (« Terminal indisponible », « Python 3 est introuvable sur ce poste. Installez-le, puis relancez /vf-cockpit --terminal. »), aucun `etat:arrete`, pas de boucle | E4.1 à E4.3 |
| G3 barre de défilement | mutant M-BARRE-VISIBLE (= le code d'avant) rougit G3.1 : opacité 1 hors survol | feuille : barre à opacité 0, 1 au survol de `#terminal` ou pendant la classe `vf-q-defile` (molette ou Maj+PageUp/PageDown/Début/Fin, une seconde) ; molette et clavier inchangés | G3.1 à G3.5 |

Contrats serveur (W1) simulés par doublure de `fetch` (`etat.mjs`, sans navigateur) : `{"etat":"arret"}` et `{"etat":"indisponible","raison":"python3-absent"}`.
Le canal vers P reste la liste fermée (T17.Q3 inchangé : aucune nouvelle valeur `etat:*`) ; la carte Python n'émet rien.

## Suites

- `test-cockpit-terminal-client.sh` : 65 PASS / 2 FAIL, les deux hors périmètre (voir findings). Nouvelles : G2.1, G2.2, E4.1 à E4.3, M-G2, M-E4. N11 reste vert (doublure `queue.mjs` complétée).
- `test-cockpit-terminal-xterm.sh` : 66 PASS / 0 FAIL. Nouvelles : T22.0, E3.1, E3.2, G3.1 à G3.5, M-SANS-MARGE, M-BARRE-VISIBLE, M-BARRE-JAMAIS, M-BARRE-CLAVIER.
- `test-cockpit-terminal-page.sh` : 47 PASS / 2 FAIL (M-XFO, TV.0b), hors périmètre.
- Gates : check-machine-paths, check-python-isolation, check-file-size --all verts.

## Phrases de doc

- Page du terminal : le nombre de lignes de la grille se calcule sur la hauteur utile du cadre, marges internes déduites ; la dernière ligne ne déborde jamais.
- Quand le serveur du terminal est arrêté volontairement, la page affiche « Serveur arrêté » aussitôt ; une coupure inattendue garde la reconnexion pendant 30 s.
- Si Python 3 est introuvable, la page affiche « Terminal indisponible : Python 3 est introuvable sur ce poste » avec la marche à suivre, sans boucle de reconnexion.
- La barre de défilement du terminal n'apparaît qu'au survol ou pendant un défilement (molette, Maj+PageUp/PageDown).
