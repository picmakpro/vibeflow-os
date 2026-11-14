# 80-a51 — trace des rouges (idiome A51 sur les extensions de 80-01 à 80-08)

Témoin : `a51-rejeu.mjs` (un Chrome, la sonde de la coquille) jugé par `a51-verdict.mjs`. Base = la tête de départ 68343e27, servie depuis une
copie de `plugin/cockpit` extraite de cette tête (aucune extension modifiée) ; le témoin et son verdict sont ceux du dépôt.

Deux mesures par famille : `retours` (Code/Projet/Code/Projet/Code : arrivée 1 contre arrivées 2 et 3) et `rejeu` (chaque fichier de la famille
réévalué deux fois par un `<script src>` du préfixe de la coquille, après les allers-retours).

## Sur la base

| Famille (suite) | retours | rejeu (même fichier, deux réévaluations) |
|---|---|---|
| couloirs (CL5) : `41-vf-projet-{vue,clavier,formes}` | ok | ROUGE : `section.vf-projet` 1 -> 3, `.vp-status` 1 -> 3, `#vf-projet-flottant` 1 -> 3, `<style>` 31 -> 33, `document:click` 7 -> 13, `window:keydown` 8 -> 10, observateurs 45 -> 51 |
| projet-liste (PL5) : `41-vf-projet-{liste,phase,formes}` | ok | ROUGE : feuilles `.vp-table` et `.vp-etat-l` 1 -> 3, `document:click` 7 -> 9, `document:keydown` 10 -> 12, `window:keydown` 8 -> 10 |
| panneau-retour (PR5) : `42-vf-panneau-retour` | ok | ROUGE : feuille `.vf-retour-barre` 1 -> 3, `document:keydown` 10 -> 12, `document:vf:onglet` 1 -> 3, observateurs 45 -> 47 |
| coin (CN6) : `02-vf-{reperes,coin,ligne-etat}` | ok | ROUGE : feuilles `.vf-repere`, `#vf-coin`, `.vf-ls` 1 -> 3 chacune, `#vf-coin` (nœud) 1 -> 3, `.vf-ls` (nœud) 1 -> 3, observateurs 40 -> 64, `window:vf-git:etat` 7 -> 11 |
| git (GP7) : `77-vf-git-{poignee,rendu,tiroir,volet,vue-detail}`, tiroir ouvert, volet ouvert deux fois | ROUGE à l'arrivée même : `.vf-git-detail` ×2 pour un seul volet demandé (ouverture non idempotente) | ROUGE : `#vf-git-tiroir` 1 -> 3, `.vf-git-poignee` 1 -> 3, quatre feuilles 1 -> 3, `window:vf-git:basculer` 1 -> 3, `document:vf-git:signal` 2 -> 4, `document:keydown` 7 -> 11 |

Lecture : sous la coquille, un changement d'onglet est propre (`retours` : ok) parce que la portée d'onglet défait les écouteurs, la tête, les classes du
corps et les propriétés de `window` posés pendant la vie de l'onglet. Ce que la portée ne couvre pas, c'est la réévaluation d'un fichier SANS changement
d'onglet : sans `cle`, `surOnglet` empile une seconde inscription et l'ancienne n'est jamais nettoyée. C'est ce que `rejeu` mesure.

## Sur le code livré

Les cinq familles : `retours` = ok, `rejeu` = ok (écouteurs, observateurs, feuilles, nœuds, classes du corps, propriétés `VF*` et `__vf*` identiques avant
et après). Seule différence de la tête du document entre avant et après le rejeu : les `<script>` des réévaluations elles-mêmes (retirés au changement d'onglet).

## Surcouches (SU6.1, M-PERSISTANT)

Les quinze mutants de `test-cockpit-surcouches.sh` rougissaient déjà sur la tête de départ, avant toute modification de cette tâche :
`❌ FAIL — mutant M-INERT-TOUT : 1 ligne(s) du module, -1 de la page rebâtie` (la page ne porte plus le texte des extensions : la coquille les sert par
`/_vf/`). Résultat sur la base : 30 PASS / 15 FAIL. La preuve de chargement du mutant est désormais l'empreinte publiée (code 5 de `cockpit_lancer`).
