# 78-06 — traces des rouges (tiroir Git de la page)

Reprise après crash (2026-11-05) : `temoins/git-tiroir.json` laissé par le prédécesseur a été relu contre `vibeflow/cockpit-git@1` servi (`vf-cockpit-interface.json`, 78-05) : toutes les clés requises de la réponse et de chaque rangée y sont (le champ `suite`, issu de `placer`, n'est pas servi : le témoin le porte en trop, le rendu ne le lit pas). Gardé tel quel.
Un brouillon de `77-vf-git-rendu.js` a été écrit par erreur AVANT le témoin ; il a été déplacé hors dépôt (scratchpad `78-06-brouillon/`) avant tout rouge, et n'a servi qu'ensuite (même geste que 78-02).

## Tâche 1 — D1 (tiroir ouvert depuis la seconde ligne, schéma vérifié)

Commande : `bash plugin/cockpit/scripts/tests/test-cockpit-git-tiroir.sh`
Assertions : D1.0 à D1.2 et D1.x (clic sur `#vf-git-ligne` -> `aside#vf-git-tiroir` visible avec 40 rangées ; GET avec jeton ; schéma refusé -> carte indisponible).
Attendu : tout vert. Obtenu (état sans fichier 77) : `scénario interrompu : attente de « tiroir ouvert avec ses rangées » dépassée (25000 ms)` — la page se rend, la seconde ligne existe (l'attente précédente est passée), le clic n'ouvre rien ; 8 échoués, 1 réussi (H0 hygiène). Raison correcte : aucun tiroir.

## Tâche 2 — D2 (sections, graphe, étiquettes, mergées, copie, XSS, états)

Écart d'honnêteté : le code de la tâche 1 (commit c89407b4) est allé plus loin que la coquille demandée (le brouillon de mon prédécesseur-moi couvrait déjà sections, états et commandes). Le rouge de D2 ne peut donc pas être joué sur « aucun fichier » ; il est joué sur une copie du module réduite à la coquille de la tâche 1 (graphe seul : le tiroir n'ajoute ni sections, ni mergées, ni commandes, ni états ; copie hors dépôt, `78-06-rouge-mod`), avec la suite pointée dessus par `TIROIR_SCRIPTS`. Chaque assertion est de plus tuée par un mutant ciblé (ci-dessous).

Commande : `TIROIR_SCRIPTS=<copie>/scripts bash plugin/cockpit/scripts/tests/test-cockpit-git-tiroir.sh`
Attendu : D2.1 à D2.6 verts. Obtenu : `Résultats : 1 réussis, 27 échoués` ; scénarios interrompus nommés `attente de « témoin rétabli » dépassée` (D2 : la section « Tags » n'existe pas, donc ne revient jamais), `attente de « carte indisponible » dépassée` (D2b), `attente de « carte indisponible sur schéma refusé » dépassée` (D1, collatéral : la copie a aussi perdu l'état indisponible). D2.1 à D2.6 rouges ; D1.* rouges par collatéral (même cause).
Première version de D2.2 « couloirs » : verte à vide (deux sorties jq vides comparées entre elles) ; réécrite en `JSON.stringify(...) === ... && new Set(lanes).size === 6` -> « true », rouge ensuite sur la copie réduite (voir la ligne `D2.2 — couloirs` du rejeu).

Verts sur le vrai module (rejeu) : 28 réussis, 0 échoué avant les mutants ; trois échecs d'assertion trouvés au premier vert et corrigés :
- D2.1 « Graphe gardée sans rangée » : bug de TEST (comparait des éléments à une chaîne) — corrigé dans la suite ;
- D2.3 : le « +N » vaut `reste + refsPlus` (2 + 2 servis = +4), non +2 : bug de la SUITE (attendu faux), `title` complété par « et 2 autres » (code : rendu) ;
- D2.6 : la seconde ligne ne disait pas « Branche indisponible » : VRAI défaut du code, `vf-git:entete` n'était émis que pour `ok`/`vide` ; émis dès qu'une réponse conforme porte `entete` (code : tiroir).

### Mutants (sur copie du module, lab et serveur propres ; la suite compte « mutation impossible » comme un échec)

- **M-HTML** : `l1.appendChild(el('span', 'vf-git-msg', r.s))` -> `m.innerHTML = r.s`. Obtenu (`78-06-mutant-M-HTML.json`) : `xss.img = 1`, `xss.surveillants = 1` (attribut `onerror`), `lit` = `true,false,…` (la chaîne `<img src=x onerror=alert(2)>` n'est plus lue en texte), `csp = 3` violations (la CSP bloque l'alerte : `alerte = 0`), `rangees = 40` : seul D2.5 rougit, pas une panne d'un autre ordre.
- **M-COPIE** : `writeText(code.textContent)` -> `writeText(code.textContent.slice(0, -1))`. Obtenu : l'API reçoit `git branch -d --end-of-options '<b>vieille</b>` (apostrophe finale perdue) alors que le `<code>` affiche `…'` ; `retour = « Copiée »` : D2.4 rougit, la copie a bien eu lieu.
