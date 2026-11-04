---
name: temoin-navigateur-get-sans-origin
description: Un client Node qui pose Origin à la main est un témoin aveugle pour un contrôle d'origine — un fetch GET same-origin n'envoie jamais Origin ; exiger un témoin qui reproduit le navigateur
metadata:
  type: feedback
---

Un contrôle serveur qui exige `Origin` sur un GET casse en navigateur réel : un `fetch` GET de même origine
n'envoie pas d'en-tête `Origin` (spec Fetch), seuls les POST/CORS le portent. En Phase 71 (2026-11-03), 151 PASS
sur la suite du second serveur, et `GET /flux` rendait 403 dans Chrome 156 : le client de test Node posait
`Origin` à la main. Découvert par l'exécuteur du client (vague suivante), pas par l'auteur ni par le plan-checker.

**Why:** un témoin qui fabrique l'en-tête que le vrai client n'envoie pas prouve le contrôle, pas l'usage —
vert des deux côtés pour la mauvaise raison (même famille que [[preuve-du-chemin-heureux-ne-couvre-pas-l-echec]]).

**How to apply:** dans tout mandat qui pose un contrôle Origin/Host/en-tête côté serveur, exiger au moins un
témoin qui rejoue la requête telle que le navigateur l'émet (même origine, sans `Origin` sur GET,
`Sec-Fetch-Site`), et interdire dans les suites de navigateur de poser `Origin` à la main sur un GET.
Correctif retenu alors : P71-D-24 (`Sec-Fetch-Site: same-origin` + secret valide, POST gardent Origin).
