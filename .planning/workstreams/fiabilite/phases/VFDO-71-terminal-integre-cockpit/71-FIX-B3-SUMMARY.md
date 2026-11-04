# 71-FIX-B3 — correction ciblée de sécurité (lot B3 : collage, popup, police au premier chargement)

Base : `c00d534a`. Correctifs validés par Samuel au titre d'ADR-031 : P71-D-26 (collage, AskUserQuestion, session principale Claude Code, 2026-11-04) et
P71-D-25 (F4, même canal, même date). F-A1-1 et F-A1-3 viennent de `71-FIX-A1-SUMMARY.md`. Fichiers touchés : `vf-cockpit-terminal-client.mjs`, `-vue.mjs`,
`-style.mjs`, `-tiroir-style.mjs` et les suites `-client.sh`, `-tiroir.sh`, `-xterm.sh` (`-xss.sh` rejouée, inchangée). Aucun fichier de B1 ni de B2.

## Constats, causes, corrections

| Constat | Cause | Correction |
|---|---|---|
| F2 collage piégé (P71-D-26) | le collage d'xterm envoie tout au PTY ; bash 3.2 exécute dès la réception, le collage entre crochets n'y change rien | écoutes en capture sur `#terminal` : `paste`, `drop`, `dragover`, `beforeinput` ; un texte à retour à la ligne (`\r`, `\n`, U+2028/9) ou à caractère de contrôle (C0, DEL, C1, dont ESC et Tab) n'est envoyé (`term.paste`) qu'au clic « Coller » ; bandeau « Annuler / Coller » (focus sur « Annuler »), Échap, un nouveau collage l'abandonnent ; une ligne simple passe directement |
| F4 popup (P71-D-25) | le terminal se connectait où qu'il soit chargé ; `window.open` copie le `sessionStorage` donc l'identifiant d'onglet | hors amorçage, le client exige `window.top !== window && window.opener === null` ; sinon carte « Terminal indisponible », ni secret lu, ni flux, ni shell |
| F-A1-1 police | `new Terminal` + `open` avant la police : la cellule est mesurée en police de secours | `document.fonts.load` (latin et traits de boîte) puis création du terminal, repli borné à 2,5 s (`POLICES_MS`) |
| F-A1-3 pastille | `@media (pointer: coarse)` ne relevait que les boutons de la barre | `.vf-term-pastille { height: 44px }` sous `coarse` |

Rendu du bandeau : variables CSS seulement, boutons de 32 px (44 px sous `coarse`), le texte collé n'entre que par `textContent` (retours à la ligne et contrôles rendus ↵ et ␛), aucun `innerHTML`.
Touche équivalente : les boutons sont natifs (Tab puis Entrée ou Espace) ; Échap annule. Aucune touche de confirmation directe, exprès : Entrée ne doit jamais valider un collage par réflexe.

## Témoins rouges (sur `c00d534a`, copie `git archive` + suites neuves) puis verts

| Constat | Rouge sur `c00d534a` | Vert |
|---|---|---|
| F2, sonde de l'auditeur `p13.mjs` (bash 3.2, `/bin/bash`) | `apres collage (sans Entree) : marqueur cree = true` | `marqueur cree = false` (collage), `false` (Entrée) |
| F2, `p13b.mjs` (témoin positif, tiroir réel, presse-papiers réel) | — | une ligne : passe (marqueur après Entrée) ; multi-ligne puis « Annuler » : bandeau, marqueur absent avant et après ; puis « Coller » : marqueur absent avant le clic, présent après |
| F2, `test-cockpit-terminal-xterm.sh` | T21.2 `bandeau=false entre=[touch …/m1] marqueur=true` ; T21.3, 4, 5, 6, 7, 9, 10 rouges | T21.0 à T21.10 verts (39 PASS / 0 FAIL) |
| F4, `p3b.mjs` | popup : `carte = ""`, terminal xterm présent | `carte = "Terminal indisponible…"`, `terminal-xterm present = false` |
| F4, `p3c.mjs` | le popup prend la session, barre du tiroir `Reconnexion…` | popup sans terminal, barre `Connecté` |
| F4, `test-cockpit-terminal-client.sh` | T6.8 `carte=? session=? cadre=false` ; F4.1 `reconnexion=true` ; F4.2 `shells=1 session=vivante` (un popup lance un shell sans frappe) | T6.8, F4.0 à F4.2 verts (53 PASS / 0 FAIL) |
| F-A1-1, T15.2 | `true/false` aux cinq densités (police NON prête quand xterm ouvre le terminal) | `true/true` |
| F-A1-3, T20.8 du tiroir | `tactile=true false` (pastille 32 px sous `coarse`) | `tactile=true true` (44 px) |

Mutants (copies de la sortie, « sans effet » = FAIL) tous rouges : M-COLLAGE-BANDEAU (envoi sans confirmation), M-COLLAGE-ECOUTE (écoute `paste` retirée), M-DEPOT (écoutes `drop` et `beforeinput` retirées), M-HORS-CADRE (T6.8) et M-POPUP (F4.1 : le popup prend la session, P reçoit `etat:reconnexion`).
Traces : `xterm-old5.out`, `client-old.out`, `tiroir-old.out` du scratchpad de la session (xterm 26 PASS / 13 FAIL dont 3 mutants sans effet attendus sur l'ancien code, client 47 / 6, tiroir 43 / 1).

## Pièges mesurés en route (à garder)

1. **Q ne s'ouvre plus qu'en cadre : toutes les suites qui jouaient Q en premier niveau tombent.** Les trois suites rejouent Q dans un cadre sandbox de P, plein viewport. Le socle `chrome-session.mjs` ne rend pas les évènements : le contexte du cadre est retrouvé en sondant `Runtime.evaluate` par identifiant, et il faut le MONDE PRINCIPAL (les espions, `window.vfTermVue` et un `fetch` surchargé n'existent pas dans un monde isolé). Les identifiants **repartent de 1 à chaque processus de rendu** : balayer depuis le dernier identifiant trouvé rate le cadre (tiroir, `expire-q`). La façade est dupliquée dans les trois suites (aucun fichier d'aide neuf n'était autorisé).
2. **Un cadre de P peut en cacher un second.** Le tiroir de P rouvre son cadre s'il était ouvert : deux cadres Q portent `window.vfTermVue`. Le tiroir marque le sien par `#cadre-test`.
3. **Un popup passe l'onglet de P au second plan** : plus de rendu (rAF), le texte du shell n'arrive plus dans la grille. `Page.bringToFront` avant de saisir.
4. **Une ligne collée sans Entrée reste dans la ligne de commande** : le collage suivant s'y ajoute et le marqueur n'est jamais créé. Ctrl+U avant chaque cas qui crée un marqueur.
5. **La cellule « à froid » ne se reproduit pas dans mon harnais.** Chrome neuf, cadre de P, ancien code : lignes de 17 px même avec la police absente à l'ouverture (`document.fonts.check` faux à l'ouverture, mesuré par un accesseur sur `Terminal`). L'élément `.xterm-char-measure-element` suit la police après coup et ne dit rien de la grille. T15.2 garde donc DEUX mesures : la hauteur de ligne posée par xterm ET l'état de la police au moment de `open` ; seule la seconde rougit sur l'ancien code, et c'est la propriété corrigée. Le constat d'A1 (15 px) vient d'un chargement en premier niveau, qui n'existe plus.
6. **Le glisser-déposer ne se prouve pas en rouge par un évènement synthétique de texte** : un `drop` synthétique n'insère rien de lui-même. T21.9 mesure donc que l'évènement et le `beforeinput` `insertFromDrop` sont ANNULÉS (`dispatchEvent` rend `false`) et ouvrent le bandeau ; M-DEPOT les rend non annulés. Aucun glisser réel au pointeur n'est joué (la zone de saisie d'xterm est hors écran).
7. **Les mutants visent des lignes du client** : la fonction `demarrer` est indentée de deux espaces de plus ; M-LIEN est passé de `^    linkHandler` à `^ *linkHandler`.

## Résultats (arbre de travail, après correctifs)

xterm 39 PASS / 0 FAIL, client 53 / 0, tiroir 44 / 0, xss 17 / 0, page 49 / 0, activation 40 / 0 (sous `zsh -c 'bash …'`). `check-machine-paths`, `check-file-size --all`, `check-python-isolation` verts.
Suites rejouées une à une (jamais deux navigateurs en même temps).

## Findings pour le manager

- **README et CHANGELOG du module (B1) : à compléter.** La confirmation de collage (bandeau, Échap, Tab puis Entrée), le terminal limité à son cadre (une page Q ouverte seule affiche « Terminal indisponible ») et l'attente de la police sont des comportements visibles ; je n'ai pas touché ces fichiers.
- **P71-D-15 / 71-SECURITY** : T-71 « collage » (F2) et « popup » (F4) peuvent passer de ouvert à fermé par les sondes T21.*, T6.8, F4.* ; non édité ici (hors périmètre).
- **Un `drop` réel au pointeur sur la grille** (pas la zone de saisie cachée) est intercepté par la même écoute en capture sur `#terminal`, non joué en navigateur réel (limite 6).
- **Dette** : la façade de contexte du cadre est triplée (xterm, client, tiroir) ; un fichier d'aide partagé dans `tests/` la réduirait à une copie.
