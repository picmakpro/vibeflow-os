---
name: dg08-reconnexion-taille-pty
description: DG-08 (écran vide après rechargement du terminal) — le client ne redisait pas sa taille à la reconnexion ; le serveur ignore X-VF-Taille sur un shell déjà ouvert
metadata:
  type: project
---

À la reconnexion à un shell déjà ouvert, `/flux` ignore l'en-tête `X-VF-Taille` (session.mjs, `attacher`) et le client posait `derniere = rows+cols` sans POST /taille : un cadre d'une autre hauteur que le premier laissait le PTY à 40 lignes pendant que l'écran en avait 22 (`stty size` après rechargement). Un programme plein écran dessine alors pour une grille absente (« écran vide »). Fix : `derniere = ''; taille();` à chaque connexion (un TIOCSWINSZ de même taille ne signale rien au shell).

**Why:** rejeu du tampon de 256 Kio OK (prouvé : l'historique revient) ; la contradiction entre juges venait de la taille, pas du tampon. Sonde : `stty size` dans le shell réel du poste, premier cadre privé de `/taille` par un fetch surchargé.

**How to apply:** tout changement de /flux ou de /taille garde le scénario DG08.1 de test-cockpit-terminal-client.sh ; ne pas conclure « rejeu cassé » sans comparer `stty size` et les lignes xterm.
