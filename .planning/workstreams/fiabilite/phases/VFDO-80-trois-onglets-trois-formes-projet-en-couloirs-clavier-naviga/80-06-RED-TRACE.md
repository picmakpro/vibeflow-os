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

Vert après la tâche 1 : GP1.1 à GP1.5 et l'absence d'erreur de page (8 PASS avec H0), `test-cockpit-git-tiroir.sh` 194 PASS, 0 FAIL.

## Tâche 2 — volet bas, worktrees repliés, ouvrirSur (GP2, GP4, D2.1, D7.1, D8.1, D9.1), rouges sur la base

Base : tête de la tâche 1 (pagination faite, volet absent). Suite neuve jouée avec `GP_SCRIPTS=<copie de la base>` ; suite du tiroir jouée avec
`TIROIR_SCRIPTS=<copie de la base>` (copie `git archive` de la tête, hors de l'arbre).

| Cas | Attendu | Obtenu sur la base |
|-----|---------|--------------------|
| GP2.1 sections et nom | `Worktrees:false:3\|Graphe:true:\|…#Worktrees · 3` | `Worktrees:true:3\|Graphe:true:\|…#` (ouverte, sans nom) |
| GP2.2 Entrée | volet fils du tiroir (`vf-git-tiroir`), hors liste | parent vide : le détail est inséré sous la rangée |
| GP2.3 1024 x 768 | `352\|true\|true\|false\|true\|true` | `352\|false\|false\|false\|true\|false` (pas de volet, Worktrees ouverte) |
| GP2.4 copie du sha | `Copié\|Sha copié\|true\|true` | `\|\|false\|false` (aucun bouton « Copier le sha ») |
| GP4.1 hors des 100 rangées | `true\|true\|true\|true\|1\|1` | `\|false\|false\|false\|0\|0` (ouvrirSur absente, `TypeError`) |
| GP4.2 neuf shas refusés | neuf `false`, 0 exception | 9 exceptions (`TypeError`) |
| GP4.3 à GP4.6 | voir la suite | `ouvrirSur` absente : `[\|0\|\|false\|false\|false\|0]`, `[\|false\|1\|-1\|…]`, `[]`, `[\|false\|\|0\|0]` |

Anciennes et nouvelles assertions de `test-cockpit-git-tiroir.sh` (même mesure, nouvelle valeur) :

| Cas | Ancien texte | Nouveau texte | Obtenu sur la base |
|-----|--------------|---------------|--------------------|
| D2.1 | `Worktrees et Graphe ouvertes` ; attendu `Worktrees:true:3\|Graphe:true:…` | `Worktrees repliée au départ` ; attendu `Worktrees:false:3\|Graphe:true:…` | `Worktrees:true:3\|…` |
| D7.1 | `détail déplié juste sous la rangée` : `apresRangee` (`d.previousElementSibling.lastElementChild === L`) | `détail dans le volet bas` : `dansVolet` (`d.parentNode.id === 'vf-git-tiroir'`, région présente, hors liste et hors corps) | `[false\|1]` |
| D8.1 | `un seul détail ouvert : … déplace le détail` : `sous3` (détail adjacent à la rangée 3) | `… déplace le volet sur cette rangée` : `volet3` (région nommée d'après la rangée 3, fille du volet du tiroir, hors liste) | `[1\|false]` |
| D9.1 | `… son détail dessous …` : `detailSous` | `… le volet reste ouvert sur cette sha …` : `voletSha` (région nommée d'après cette sha, volet fils du tiroir) | `[true\|false\|2929…]` |

Un premier jet de D8.1 et de D9.1 (région nommée d'après la sha, sans exiger le volet comme fils du tiroir) restait vert sur la base :
la mesure a été durcie (parent = tiroir) avant de compter pour un témoin rouge. Sur la base, D2.6 a aussi rougi une fois sous charge
(l'en-tête « non confirmée »), vert à chaque rejeu sur le code final : aucun lien avec ce plan.

## Tâche 3 — poignée (GP3) et mutants

Sur la base : GP3 rouge (poignée absente, scénario interrompu à la première lecture : `Cannot read properties of undefined`), GP3.2 « aucun fichier
sous .planning » vert (témoin d'invariance). Le témoin GP3.3 du plan (« vert sur la base ») n'a pas pu être mesuré : le scénario s'arrête avant.
Deux témoins vides repérés et corrigés avant le verdict : GP3.3 comparait `undefined === undefined` (le lecteur `window.Floorplan.state` ne rendait
rien dans `s.ev`) ; il lit maintenant `window.VibeFlow.state.t` et `window.VibeFlow.freeArea()` et exige `typeof avant === "string"`.
Le mutant M-POUSSE du plan (appeler `fit`) est inobservable : le viewer se recadre seul (« fit(false) à chaque mise en page »), l'état final est le
même ; le mutant écrit donc `--panel-w` (le panneau grandit avec le tiroir), ce que mesure `freeArea()`.

Mutants (copie du module dans `$WORK`, le module n'est jamais muté ; une mutation qui ne s'applique pas ou une copie inchangée est un échec) :
M-TOUT, M-EPUISE, M-BORNE, M-POUSSE, M-PAGINE, M-MOTIF, M-VOLET-LIE, M-PASTILLE : huit « le mutant rougit », chacun avec son témoin vert sur le même scénario.

Vert final : `test-cockpit-git-pagination.sh` 39 PASS, 0 FAIL ; `test-cockpit-git-tiroir.sh` 194 PASS, 0 FAIL ;
`test-cockpit-surcouches.sh` 45 PASS ; `test-cockpit-git-entete.sh` 81 PASS ; `test-cockpit-vendor.sh` 138 PASS sur la tête plus les fichiers de ce plan
(dans l'arbre partagé V6.1 rougit sur des fichiers d'un voisin, aucun des miens : `synchro.sh verifier` rend 0 sur la copie tête plus mes fichiers).
