# 80-14 : la recherche devient une palette de commandes, registre unique des raccourcis (SUMMARY)

## Livré
- `viewer.html` : `ajouterSource(fn)` exposé sur l'objet du moteur (`VibeFlow.ajouterSource` une fois rendu) ; une source reçoit `{ q, termes, actions, vide }` et rend des
  résultats `{ groupe, titre, id, libelle, detail, touches, icone, executer, avant, info }` ; choisir un résultat ferme la palette puis appelle `executer(q)` (`avant` rend
  d'abord le focus d'avant, `info` ne fait que fermer). Mode `>` (pastille « Actions », actions seules), groupes dans l'ordre Entités, Actions, Onglets, Phases, Agents
  (champ vide : Actions, Onglets, Entités), intitulés affichés à partir de deux groupes. Rôles ARIA : boîte `dialog` modale nommée, champ `combobox`
  (`aria-expanded`, `aria-controls`, `aria-activedescendant` qui suit les flèches), `listbox`, `group` (`aria-labelledby`), `option` ; rangée active fond `--raise` + contour
  `--ring` ; état vide en deux lignes ; région live polie (une annonce 300 ms après la dernière saisie) ; pied « ↑ ↓ Choisir · ↵ Ouvrir · > Actions · Échap Fermer », masqué à 700 px
  et moins ; rangées 36 px (44 au pointeur grossier). Aucune balise `<script>` ajoutée (6 avant, 6 après).
- `ui/07-vf-raccourcis.js` (163 lignes, neuf) : `window.VF_RACCOURCIS` et les sources Actions, Onglets, Phases (lues dans `VF_ETAT.lire('etat').signal.phases`), Agents (`VF_ETAT.lire('who')` :
  rôle et nom court seulement). Aucune requête, aucun envoi ; 0 occurrence de `.req`, `couvre`, `fetch(`, des clés interdites.
- `ui/79-vf-fr-dict-c.js` (neuf) : onze phrases neuves du moteur ; `VENDORED.txt` : les deux lignes `AJOUT`, à leur place alphabétique.
- Suite `test-cockpit-palette.sh` (25 assertions) et pilote `chrome-palette.mjs` ; trace rouge `80-14-RED-TRACE.md` (6 PASS / 19 FAIL sur la base).

## Forme du registre (contrat lu par 80-15 et 80-21)
- Global : `window.VF_RACCOURCIS = Object.freeze({ entrees(onglet?), libelle(id), ajouter(entree) })`. `entrees(onglet)` rend des copies gelées des entrées dont `onglets` contient
  `onglet` (toutes sans argument) ; `libelle(id)` rend le libellé ou `null` ; `ajouter(entree)` rend la fonction qui retire l'entrée (valide `id` unique, `libelle`, `onglets`).
- Une entrée : `{ id, groupe, onglets, touche, libelle, action, palette, [usuelle], [info], [visible], [libre], [avant] }`. `groupe` : « Partout », « La carte »,
  « Projet : couloirs et liste » (le groupe « Équipe » est vide : ses plans l'ajoutent) ; `onglets` : sous-ensemble de `code`, `projet`, `equipe` (sans accent, comme `VF_ONGLETS`) ;
  `touche` : texte affiché (« F », « Retour arrière », « / ou ⌘K », « ← ↑ ↓ → »), `null` s'il n'y en a pas (« Poser une question à l'agent », « Copier le lien de cette vue », la ligne
  du terminal) ; `action` : fonction ou `null` ; `palette: false` = rangée d'aide seule (Rechercher, Échap, Tab, Carte voisine, Première et Dernière carte, Plonger, Sélectionner la carte,
  les cinq entrées « Phase… ») ; `usuelle` : rang 1 à 8 des huit actions du champ vide ; `info: true` : la ligne du terminal, libellé exact « Le terminal s'active avec --terminal » (id `terminal`,
  `palette: true`, sans action) ; `visible()` : l'action a un effet sur la vue courante, sinon absente de la palette ; `libre: true` : la saisie qui commence par le libellé la garde
  (la question) ; `avant: true` : le focus d'avant revient avant l'action (la copie du lien).
- Une extension ajoute une entrée : `const retirer = window.VF_RACCOURCIS.ajouter({ id: 'x', groupe: 'Équipe', onglets: ['equipe'], touche: 'Y', libelle: 'Voir…', action: () => {}, palette: true });`
  (le registre est refait à chaque onglet avec le moteur : l'appel se fait à l'évaluation de l'extension, qui doit se charger après `07-`).
- 80-21 (« Réessayer ») : même chemin, `ajouter({ …, palette: true, action })`, ou sa propre source par `VibeFlow.ajouterSource`.

## Écarts
- Écart : le moteur est `window.Floorplan` en source (rendu `VibeFlow` par le serveur) : `07-vf-raccourcis.js` lit `window.Floorplan`, comme les autres fichiers de `ui/`. « Copier le lien » appelle `navigator.clipboard`
  directement (`VibeFlow.copy` avale l'échec et ne permet pas de dire « Copie impossible »).
- Écart : « Afficher les raccourcis » est toujours présente (PA2.1 exige les huit usuelles) ; sans `VF_AIDE` (80-15) elle ferme la palette et ne fait rien d'autre. À reprendre par 80-15.
- Écart : `n` des phases de `VF_ETAT` est une chaîne (« 1 ») : le filtre accepte une chaîne numérique (une première version `Number.isFinite` rendait 0 phase).
- Écart : un `>` ne passe ni dans une valeur du dictionnaire ni dans l'attribut d'un balisage statique (F5, F2, F16.2 le lisent comme une balise) : l'invite et l'état vide reçoivent le `>` comme variable
  (`type {} for actions`), l'invite est posée par le script. L'état vide s'écrit « No matches for “{}” » (F21.2 lit `No matches` sous `?lang=en`).
- Écart : `test-cockpit-chrome-fr.sh` : F5.2 étendue au fichier neuf (aucune assertion retirée) ET les comptes de blocs `vibeflow:fr` de F18.1 et F18.2 portés de 3 à 4 (un quatrième bloc existe maintenant).
- Écart : hauteur du champ gardée à 58 px (la spec dit 44) pour ne pas bouger les suites de mesure des autres plans ; à reprendre par la passe de jetons si Samuel la veut.
- Écart : PA2.3 observe l'écriture dans le presse-papiers (`writeText` enveloppé) plutôt que sa relecture : la permission de lecture n'est pas accordée en Chrome sans tête. PA2.5 pose la pile Retour par `VF_PANNEAU.empiler`.
  Le `who` de PA3.1b est une fixture qui enveloppe `window.VF_ETAT.lire` (le registre lit `window.VF_ETAT` à la saisie, jamais à l'évaluation).
- Écart : l'action « Monter d'un niveau » pose son focus après le rendu, en microtâche : l'écouteur `render` du fichier est posé à l'évaluation, celui du clavier du canevas à l'arrivée de l'onglet (il passe après).
- Écart : requête hostile : la première version du moteur insérait la requête sans l'échapper dans l'état vide (le témoin PA3.3 l'a rougi : `<img>` rendu) ; corrigée par `h()`.
- Cas non écrits : mutants M-ENVOI, M-ACTIVEDESC, M-GRISE : levés (régime allégé) ; aucune ligne « le mutant rougit ». PA3.1b (agents) n'utilise pas un `who` produit par le serveur.

## Suites (sur la tête commitée)
- test-cockpit-palette 25/0 ; test-cockpit-chrome-fr 141/0 (F5.2, F16.2, F18, F21 verts) ; test-cockpit-moteur-carte 73/0 (K18, K19) ; test-cockpit-onglets 29/0.
- test-cockpit-surcouches 47/1 : SU6.1 (tiroir Git rouvert par la mémoire de 80-13 après deux allers-retours), identique sur la tête d'avant ce plan (75a527f9b, rejeu isolé) : pas de ce plan ; SU1.x, SU2.4 (piège et Échap de la palette) verts.
- test-cockpit-vendor 251/1 : V4c.9a (HAUSSE de `01-vf-responsive.js`, 64 pour 63, fichier du nœud p20), hors de ce plan ; V4 et la ligne `AJOUT` verts.

## Rituel
rituel levé : régime allégé (consigne de Samuel, message session principale, 2026-11-13, appliquée par la session principale)

## CHANGELOG demandé (80-18)
Cockpit : la recherche (`/`, ⌘K) devient une palette de commandes : vues, actions (ajuster, cadrer, monter, détail, zoom, Git, aide, basculer, question, lien), onglets, phases et agents des autres onglets,
au clavier, avec ses rôles ARIA ; `>` ne garde que les actions ; aucune action n'envoie rien ; un registre unique des raccourcis (`window.VF_RACCOURCIS`) nourrit la palette et l'aide.
