---
name: sonde-cockpit-port-pinne-et-rerendu-live
description: Épingler un cockpit sur un port imposé (base = voulu − sha1(lab)%100) et sonder le panneau Projet sans nœud périmé (re-rendu live) ni textContent collé.
metadata:
  type: project
---

Deux pièges de sonde sur le cockpit (lot 6 « Projet », 2026-11-06).

1. **Port imposé** : `portPrefere(lab)` = `VF_COCKPIT_PORT_BASE + sha1(realpath lab) % 100`. Pour tenir dans une plage réservée (47210-47229), calculer `h = portPrefere(lab, {BASE:'10000'}) - 10000` puis lancer avec `BASE = voulu - h`. Deux copies de lab de même nom de dossier retombent sur le repli (port+1 …) hors plage sinon.
2. **Sonde navigateur** : le panneau d'ensemble est réécrit par le direct (70-vf-live) peu après le chargement ; un nœud capturé avant ce re-rendu est détaché et `.click()` dessus ne remonte plus au `document` (copie = 0). Toujours ré-interroger l'élément au moment du clic, après une pause. Et lire `innerText` (pas `textContent`) pour comparer une phrase faite de plusieurs `<span>` : `textContent` les colle sans espace.

**Why:** deux faux rouges d'affilée (R3.14/R3.18) sur une UI correcte, trois relances de suite de ~20 min chacune sous file d'attente.
**How to apply:** avant d'écrire une assertion de rendu, rejouer la sonde seule sur un serveur déjà levé, hors suite (une sonde n'est pas une suite).
