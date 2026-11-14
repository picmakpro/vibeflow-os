# 75-09c — trace de rouge (dictionnaires et suites voisines)

Base du rouge : `6e41422f6` (tête après 75-09b). Chemins relativisés.

## Comptes d'assertions (avant -> après) et intention conservée

| suite | avant | après |
|---|---|---|
| `test-cockpit-moteur-carte.sh` | 73 | 74 (+1 : Q12.1) |
| `test-cockpit-chrome-fr.sh` | 141 | 142 (+1 : Q13.1) |
| `test-cockpit-ecrans-recent.sh` | 18 | 21 (+3 : Q14.0, Q14.1, Q14.2) |

| ancienne assertion | nouvelle | intention conservée |
|---|---|---|
| K17.1 « le titre du tableau dit le nombre du badge » | « … le nombre de cartes qu'il porte » | le titre d'un tableau et son nombre de cartes disent la même chose (un tableau de genre neutre « Board », plus la couche retirée) |
| K17.2, K17.3 (coupe à 24) | mêmes attendus sur le tableau neutre | la coupe générique à 24 cartes dit l'écart dans son titre |
| K17.4 « le panneau d'une partie liste deux modifications dedans » | « le tableau des deux README porte deux cartes » | témoin positif des deux homonymes |
| K17.5 « les deux README se distinguent par leur dossier parent » | texte et attendu inchangés | un homonyme porte son dossier parent (désormais lu sur les cartes du tableau) |
| F13.3 « Recent work: Recent work » ne dit qu'une fois « Travail récent » | « Health: Health » ne dit qu'une fois « Santé » | le fil d'Ariane `X: X` se replie en un seul mot traduit |
| F19.5 (valeur de l'essai « Récent ») | valeur « Nouveau » | le contexte `@pastille` et le repli sans contexte |

## Rouge sur la base `6e41422f6`

`test-cockpit-moteur-carte.sh` (K17) sur la base de 75-09a : « attente de « tableau du travail récent » dépassée » (le bouton n'a plus de badge : la couche n'est plus écrite) puis 69 échecs en cascade (une seule mesure Chrome) ; `Q14.1` rouge tant qu'un dictionnaire, `mesures-pied.mjs` ou une suite porte encore un littéral de la couche (8 lignes hors exceptions avant les retraits) ; `Q13.1` rouge tant que les entrées des dictionnaires subsistent.

## Entrées de dictionnaire

Retirées : `Recent work`, `Highlight recent work`, `Recent work inside`, `Changed@pastille` (dictionnaire B : seule entrée contenant « Récent », exigée par le grep final ; plus aucun lecteur dans la page). Conservées, avec leurs assertions F14.7 et F14.9 (qui les exercent par `window.__vfFrTraduire`) : `Changed · {}`, `{} changed inside · {}`, `{} changed` — une première version les retirait, F14.7 et F14.9 ont rougi (140/2), elles sont rétablies : le texte ne se retire pas pour verdir une suite qui l'exerce.
`.rw` -> `Récent` : aucune entrée de ce nom dans `80-vf-fr.js` ; le commentaire « Recent work: Recent work » du repli `X: X` est réécrit.

## Grep d'inventaire final (Q14.1), exceptions nommées avec leur raison

Le grep de la précondition de 75-09a, sur `plugin`, `scripts` et `.github` (DESIGN.md et README réécrits par 75-10), rend ZÉRO ligne hors de : le jeton `--recent` (porte « en cours », P71.5-D-26, D-29) ; « récent » au sens du lancement (`chrome-lancer.mjs`, `RECENCE_MS` de `test-cockpit-lancer-suivi.sh`, la ligne CH7 de `test-cockpit-lancer-bout-en-bout.sh`, la ligne « | Récent / fait » de `test-cockpit-signal-mod.sh`) ; le CHANGELOG ; le mode « Change » du blueprint, inatteignable dans VibeFlow (quatre lignes de `serve.mjs`, deux de `references/schema.md`, la lecture de `showChangeResult` dans `viewer.html`) ; `--recent` et `RECENCE_MS` n'ont aucun rapport avec la couche. Autres retraits faits pour atteindre zéro : `p.recent` de `mesures-pied.mjs` renommé `p.vert` (propriété de mesure, jamais le jeton) ; littéraux des suites construits en deux morceaux.
Sondes : `Q14.0` (racine trouvée), `Q14.1` (zéro), `Q14.2` (contrôle positif : sans la liste d'exceptions le même balayage trouve les exceptions).
