---
name: suites-navigateur-cockpit-sous-charge
description: Pièges des suites Chrome du cockpit — reproduire la charge, socle chrome-session, page renommée VibeFlow, assert_eq vide-contre-vide
metadata:
  type: project
---

Les suites navigateur du cockpit (plugin/cockpit/scripts/tests) passent par `chrome-session.mjs` (attendre/stable sur condition, échéances VF_CDP_*), jamais par des délais fixes.

**Why:** `yes` x2 sur 12 cœurs ne reproduit rien ; il faut ~16 `yes` + 3 suites en parallèle pour rougir l'ancien code (chaine-xss C0.3/C4.2). Dans la page construite, `window.Floorplan` s'appelle `window.VibeFlow` (marque blanche). Un `ev.mjs` qui plante imprime vide : `assert_eq ... ""` passe À VIDE — comparer à une chaîne non vide (`0/`) et poser un témoin R7.0 « mesure obtenue ». `innerText` d'un bouton masqué (<1 000 px) est vide : utiliser `textContent` dans une condition d'attente.

**How to apply:** toute nouvelle suite Chrome : importer le socle, `libre()` pour les ports, preuve = rejeu sous 16 yes avant/après sur copie du module d'avant (git archive HEAD vers le scratchpad).
