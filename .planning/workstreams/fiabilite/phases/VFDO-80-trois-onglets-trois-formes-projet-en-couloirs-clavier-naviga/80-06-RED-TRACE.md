# 80-06 — Trace du rouge

Base : branche `feat/phase-80-trois-formes` avant le code de 80-06 (tête 7fb284e2 plus l'amendement 08c489a5). Chaque témoin est rejoué
par `test-cockpit-git-pagination.sh` ; le scénario ne s'interrompt pas au premier manque (chaque attente est bornée à 4 s et se lit
dans la mesure), si bien que chaque rouge porte une valeur réelle, jamais une panne de fixture.

## Tâche 1 — pagination (GP1), rouges sur la base

| Cas | Attendu | Obtenu sur la base |
|-----|---------|--------------------|
| GP1.1 612 commits | `100 / Afficher 100 de plus / 512 restants / 100 commits affichés sur 612` | `612` rangées, ni bouton ni pied |
| GP1.2 clic | `200 / focus rangée 100 / 1 arrêt / 412 restants / annonce` | `612`, focus nulle part (-1), aucune annonce |
| GP1.3 105 commits | `105 / aucun bouton / Tous les 105 commits sont affichés` | `105 / false /` (pied absent) |
| GP1.4 210 commits | `100 / 110 restants / 200 / 100 / Afficher les 10 derniers / 10 restants` | `210` rangées d'un coup, aucun bouton |
| GP1.4 clic qui épuise | `210 / focus 200 / pas body / 1 arrêt / bouton retiré / pied complet` | `210 / -1 / false / 1 / false /` |
| GP1.5 bouton disparu sans clic | `105 / focus 104 / pas body` | `105 / -1 / false` |
| GP1 erreurs de page | 0 | 0 (vert, témoin d'invariance) |
