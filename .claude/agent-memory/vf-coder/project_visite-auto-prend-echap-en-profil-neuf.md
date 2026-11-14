---
name: visite-auto-prend-echap-en-profil-neuf
description: Dans un Chrome à profil neuf, la visite guidée du cockpit s'ouvre seule 700 ms après `ready` et avale Échap (elle ramène à la racine) — fermer la visite avant tout témoin clavier.
metadata:
  type: project
---

Un témoin navigateur sur le moteur du cockpit (`window.VibeFlow`) démarre dans un profil jetable : `ui/40-tour.js` lance la visite
toute seule (`maybeAuto`, 700 ms après `ready`, tant que `tour-seen:<nom du projet>` n'est pas posé et que le hash est vide) et son
écouteur d'Échap en phase de capture appelle `end()` → `go('root')`. Un témoin « Échap ne remonte pas d'un niveau » rouge sur la
bonne règle vient donc de la visite, pas du moteur : trace = `history.pushState` instrumenté, pile `end` → `go`.

**Why:** perdu une heure sur K7.2 (PU-G-175, lot 1 M4) : l'assertion rougissait alors que le garde du moteur était juste.
**How to apply:** en tête du helper, attendre `#tour` non caché (borné, `.catch`) puis presser Échap et attendre `#tour` caché ;
ou poser `floorplan:tour-seen:<nom>` avant le chargement. Les ids de conteneur sont `n:<id>` (`VibeFlow.go('n:ag-mgr1')`), pas
l'id nu ; `VibeFlow.select(id)` ne montre pas la fiche d'une carte hors de la vue courante — `VibeFlow.reveal(id)`.
