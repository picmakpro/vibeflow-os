---
name: focus-guard-window-focus-path-from-parent
description: Une garde « armée à chaque retour de focus » doit aussi couvrir le handler window focus : le parent peut donner le focus au cadre (iframe.focus()) et l Entrée tenue suit (lot 8 LB3-S2, cockpit)
metadata:
  type: feedback
---

Quand une revue juge une garde de type « retenue de l Entrée tenue après retour du focus au terminal », ne pas s arrêter aux `.focus()` du fichier : le handler `window.addEventListener('focus', () => term.focus())` est un second chemin, déclenché par `cadre.focus()` du parent (bouton pastille du tiroir P, Entrée = clic au keydown). Les répétitions d Entrée atteignent alors le textarea du cadre sans passer par la garde.

**Why:** lot 8 LB3-S2 (2026-11-07) : le codeur affirme « le window focus n est pas un bouton » ; sonde autonome (page parent + iframe + handler window focus) : 6 répétitions sur 6 reçues par l enfant après `iframe.focus()` depuis un bouton du parent. Mesuré sur une doublure, pas sur le vrai client.

**How to apply:** pour toute garde « armée au retour du focus », lister aussi les chemins déclenchés depuis l extérieur du cadre (parent, raccourci, retour d onglet) ; un test par bouton du cadre ne prouve rien sur eux. Et vérifier qu un mutant isole chaque `rendre(...)` : celui de `garde:apres-usage` n avait que le mutant de ligne entière.
