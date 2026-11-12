---
phase: 80
slug: trois-onglets-trois-formes
status: draft
shadcn_initialized: false
preset: none
created: 2026-11-11
---

# Phase 80 : UI-SPEC navigation et chrome (clavier, surcouches, palette, minicarte, ligne d'état, tiroir Git, jetons)

> Contrat de design pour le planificateur. Spec seulement : aucun code, aucune valeur nouvelle hors jetons. Les couloirs et la
> liste de l'onglet Projet sont dans `80-UI-SPEC.md` ; ce fichier n'en dessine rien. Hors de ce fichier aussi : la section
> « À Samuel » du CONTEXT (S80-1 à S80-4 : titre de vue, en-tête, Santé, pastille du terminal), désormais tranchés : titre P80-D-52 (zone réservée ≤ 130 px, flou et texte court gardés), en-tête P80-D-53 (trois groupes libellés au-delà de 1 280 px, chevron, trois icônes remplacées, badge et troncature inchangés), terminal P80-D-55 (arbitrage Samuel, AskUserQuestion session principale, 2026-11-11), ouvreur Git P80-D-56.
> Décisions tenues : P80-D-10 à D-22, D-25, D-26. Direction « Graphite » (`DESIGN.md` racine) fait foi.
> Les contrastes marqués « calc. » sont calculés à la main (luminance relative WCAG) : le plan les remesure sur rendu, dans les deux thèmes.

## 0. Design System et règles transverses

| Propriété | Valeur |
|---|---|
| Outil | aucun (HTML, CSS et JS vanilla du cockpit ; pas de bibliothèque, pas de registre tiers) |
| Police | `--sans` (Inter) pour le texte, `--mono` (JetBrains Mono) pour sha, chemins, branche, touches ; graisses employées 400 (corps, champ, messages), 500, 600 (titres), jamais 700 |
| Échelle de texte | 18 / 24 (titre de modale, 600) · 13 / 20 (libellés, rangées, champ ; 500, champ 400) · 12 / 16 (détails ; 12 / 18 pour un message de commit) · 11 / 16 (touches, ligne d'état, intertitres ; 500) ; aucun demi-point (ni 11, ni 12, ni 13) |
| Icônes | pictos au trait 16 × 16, `stroke: currentColor`, épaisseur 1,75 (§7 de DESIGN.md) ; aucune icône neuve en couleur |
| Grille | 2, 4, 6, 8, 12, 16, 20, 24, 32 ; jetons `--sp-*`, `--edge` 16, `--inset-panel` 20, `--inset-row` 8 × 12 |
| Hauteurs de contrôle | liste fermée 24, 28, 32, 36, 44 ; exception à proposer pour DESIGN.md § 4 : la rangée de liste dense de 40 (44 tactile), déjà celle du graphe Git |
| Rayons | tiroir, modale, panneau : `--r-panel` ; contrôle : `--r-ctl` ; carte : `--r-card` ; petit bouton 8 à 10 ; pilule 999 |
| Points de rupture | ≤ 700, ≤ 999, 1 000, 1 280, 1 600 / 1 640 : inchangés (Q11) |
| Couleur | ni couleur d'alerte, ni fond teinté, ni halo, ni liseré coloré (Q9) ; un état = glyphe de forme distincte + mot |
| Mouvement | toute transition neuve ≤ 200 ms et nulle sous `prefers-reduced-motion` (la règle `!important` de `03-vf-accessibilite.js` suffit pour le CSS ; aucune animation par `element.animate()` ni `requestAnimationFrame` : X6 les compterait) |
| Langue | français, espace insécable avant `: ; ! ?` et dans « 1 024 px » ; tout libellé neuf passe par le dictionnaire de la 80 (P80-D-27) |

Anneau de focus unique pour tout ce que ce fichier ajoute : `outline: 2px solid var(--ring); outline-offset: 2px` (décalage négatif
`-2px` à l'intérieur d'une rangée ou d'un conteneur qui rogne). `--ring` = encre à 88 % en sombre, noir à 85 % en clair : au moins
12:1 sur `--bg` et `--surface` dans les deux thèmes (calc.). Aucun autre style de focus, aucun `box-shadow` de focus. Exemption à écrire dans DESIGN.md § 9 par le lot jetons : « L'anneau de focus (2 px `--ring`, décalage 2) est un état d'interaction, pas une intention d'élévation : il peut se poser sur une carte qui porte `--shadow-card`. »

---

## 1. Carte du canevas : focus, nom, plongée et remontée

**Portée** : cartes de Code et du graphe de Projet (`g.node`). Équipe n'a plus de canevas ; couloirs et liste sont à `80-UI-SPEC.md`.

**Anneau.** Le nœud tabulable est le `g.node` (un seul arrêt itinérant, `tabindex=0` ; les autres `-1`). L'anneau se dessine sur la
`.card` HTML interne, pas sur le `g` (un contour de `g` SVG est un rectangle droit qui ignore le rayon) :
`g.node:focus { outline: none }` puis `g.node:focus-visible .card { outline: 2px solid var(--ring); outline-offset: 2px }`. Le rayon suit
`--r-card` (20). L'anneau tient dans la gouttière `--gutter` (24 px, réserve d'ombre) : 4 px de contour et de décalage, aucun rognage
par le `foreignObject`.

| État de la carte | Rendu | Thème sombre | Thème clair |
|---|---|---|---|
| Repos | `--shadow-card` seule | inchangé | inchangé |
| Sélectionnée, sans focus clavier | anneau doux du moteur (`.sel`) inchangé | inchangé | inchangé |
| Focalisée au clavier (`:focus-visible`) | anneau `--ring` 2 px, décalage 2 px | ≥ 12:1 sur `--bg` | ≥ 12:1 sur `--bg` |
| Sélectionnée ET focalisée (bureau : la sélection suit le focus) | anneau `--ring` seul ; sous `:focus-visible` l'anneau doux ET le halo de `.sel` sont retirés (une seule intention ; un halo diffus resté dans `.sel` hors focus relève du lot jetons, DESIGN.md § 9) | idem | idem |
| Estompée (voisinage d'une sélection) | texte à 4,5:1 minimum et glyphe d'état à `opacity: 1` (X5, § 6) ; le focus clavier sur une carte estompée la rend pleine (`opacity: 1`) | idem | idem |

Le focus ne s'obtient pas au clic : un clic pose le focus DOM sur la carte (pour que les flèches marchent ensuite) avec
`focus({ focusVisible: false })` ; l'anneau n'apparaît qu'à la première touche. Pas de halo, pas de couleur d'état sur l'anneau.

**Nom accessible.** Construit par UNE fonction (la 75 peut l'enrichir d'un mot d'activité) : `<titre>, <mot d'état>, <compte du pied>,
reliée à <N> carte(s)`. Exemples : « cockpit, 2 composants, reliée à 4 cartes » ; « Phase 80, en cours, 3 plans sur 5, reliée à 2 cartes » ;
« validator, 2 fichiers, aucune liaison ». Le mot d'état est celui du glyphe de la carte (jamais la couleur seule). Chaque `option` porte
`aria-posinset` et `aria-setsize` (« 3 sur 26 »). Le canevas est un `listbox` nommé « Carte : <niveau>, N cartes » (D-10), `aria-orientation`
absent (grille spatiale). Les arêtes, les connecteurs et le fond sont `aria-hidden`. Un niveau sans carte : région `aria-live="polite"`
« Niveau <nom>, aucune carte » (seul cas où l'annonce n'est pas portée par le focus).

**Plongée.** `Entrée` plonge. Après le rendu du niveau d'arrivée, le focus va sur la première carte en ordre de lecture (haut puis gauche),
sans second fondu : le focus est posé à `render`, pas à la fin du fondu de 340 ms ; mouvement réduit : posé immédiatement, vue changée d'un coup.
L'annonce vient du focus (nom de la carte) précédé du nom du `listbox` ; aucune région live supplémentaire.

**Remontée.** `Échap` ou Retour arrière remonte. Le focus revient sur la carte qu'on vient de quitter (elle existe maintenant comme carte du
niveau supérieur) ; à défaut (carte absente d'un niveau filtré), sur la première carte. Le titre de vue ne prend jamais le focus.
En forme Graphe, la cible de repli est la carte itinérante, sinon `#stage` (`tabindex=-1`), jamais `body` ni un `h1` qui n'existe pas dans cette forme : règle unique « cible de repli du focus » de `80-UI-SPEC.md` § 5.

**Flèches.** ←/→ : voisin spatial entre couches ; ↑/↓ : dans la colonne ; Origine/Fin : première et dernière en ordre de lecture ; aucune boucle
aux extrémités (la flèche est sans effet, aucun son). La carte focalisée est ramenée dans le champ de lecture (§ 4.6 : marge 16, jamais sous une surcouche), sans changer le zoom.

**Téléphone.** Même anneau et même nom. La sélection ne suit pas le focus : `Espace` sélectionne (ouvre la feuille), `Entrée` plonge. Tactile pur : le
geste direct (toucher) est inchangé ; rien de ce paragraphe n'est requis pour lui.

---

## 2. Surcouches : piège, Échap, retour du focus, panneau fermé

**Rien de visible pour le piège.** Le piège à focus n'ajoute aucun élément ni aucun style : seul le focus visible (anneau § 0) prouve où l'on est.
Le voile existant `--scrim` des modales reste le seul signe de modalité. Les éléments hors surcouche modale reçoivent `inert` (suivi à part
par la pile : jamais le `inert` du terminal).

| Classe | Membres | Piège de Tab | `inert` ailleurs | Focus à l'ouverture | Échap |
|---|---|---|---|---|---|
| Modale | palette, aide `?`, export, santé, visite ouverte par le bouton, blueprint | oui, Tab et Maj+Tab bouclent | oui | palette : le champ ; aide `?` : son titre `h2` (`tabindex=-1`) ; export et santé : leur boîte (comportement actuel) | ferme celle du dessus |
| Menu / bulle | Écrans, Parcours, Types de liens, « ⋯ », contextuel, définition de glossaire | non (flèches dans le menu) | non | premier item (menus) | ferme le menu, rend le focus à son bouton |
| Non modale | tiroir Git, tiroir « Au travail », visite d'elle-même | non | non | ouvert par l'humain (`g`, bouton) : le titre `h2` comme aujourd'hui ; ouvert par une proposition ou un événement : **jamais de focus** (Q5) | ferme |
| Exclue | terminal | sans objet | sans objet | sans objet | **n'écoute pas** Échap (le shell en a besoin) |

**Ordre d'Échap (un cran par appui, du plus récent au plus ancien), avec la cible qui l'autorise.** 1 modale du dessus de pile (toute cible : elle contient le focus) ; 2 menu ou bulle ouvert (toute cible) ;
3 parcours `#flowbar` (toute cible) ; 4 volet bas du tiroir Git (focus dans le volet ou sur sa rangée) ; 5 tiroir non modal du dessus de pile (focus dans le tiroir, sur son ouvreur, ou sur `body` ou le canevas) ;
6 feuille de détail (≤ 999 px ou pointeur grossier ; toute cible, comme aujourd'hui) ; 7 désélectionner, puis 8 remonter d'un niveau : **réservés aux cibles `body`, `documentElement`, canevas et éléments de la vue DOM de Projet (cartes de couloir, rangées de liste, intérieur de phase : cette vue compte comme canevas, `80-UI-SPEC.md` § 5)** (garde PU-G-175 du moteur, inchangée : un Échap venu d'un bouton du
panneau ou d'un menu ne perd pas ce qu'il vient d'afficher). Un champ de saisie (barre de question, `<select>`, `<textarea>`, champ éditable) hors palette : Échap ne descend pas la chaîne et ne vide pas le champ ; seule la surcouche
qui le contient (crans 1 à 5) le consomme. Au bureau, le panneau de détail ne se ferme pas par Échap (`p` et son bouton, comme aujourd'hui) ; il n'est pas une surcouche. Écouté au document, en capture ; `stopPropagation` quand la pile a consommé l'appui.

**Retour du focus.** À la fermeture : à l'ouvreur s'il est dans le DOM et visible ; sinon la carte itinérante du canevas ; sinon `#stage` (`tabindex=-1`). Le focus qui n'était pas dans la surcouche fermée ne bouge pas.
**Une action de palette qui change la vue pose le focus propre à l'action, qui l'emporte sur le retour à l'ouvreur** : Ajuster, Cadrer, Zoom, Monter : la carte itinérante (la sélectionnée si visible ; Monter : la carte quittée) ; Basculer couloirs, liste, graphe :
l'élément équivalent de la nouvelle vue, sinon la cible de repli de sa forme (couloirs et liste : élément sélectionné, sinon `h1` ; Graphe : carte itinérante, sinon `#stage` ; même règle que `v` dans `80-UI-SPEC.md`) ; Ouvrir l'historique Git : le titre du tiroir ; Afficher ou masquer le détail : `#btn-panel` ; Poser une question : le champ de la barre ; Aller à un onglet : la règle de repli unique de `80-UI-SPEC.md` § 5 sur la vue chargée (D-22, P80-D-50 e : élément sélectionné, sinon `h1` en couloirs ou en liste ; Graphe et Code : carte itinérante, sinon `#stage`) ;
Afficher les raccourcis : l'aide ; Copier le lien : l'élément actif d'avant. Sans règle propre, retour à l'ouvreur.
**Focus dans le panneau à sa fermeture** (`p`, son bouton, ou sélection vidée) : `#btn-panel` s'il est visible, sinon la carte itinérante ; jamais `body`.

**Panneau fermé (bureau).** Aujourd'hui `opacity: 0; pointer-events: none` : 43 arrêts invisibles. Cible : `visibility: hidden` posé à la fin de
la transition de fermeture (`transitionend`, repli à 300 ms), levé avant la transition d'ouverture ; mouvement réduit : posé tout de suite.
Rien à l'écran ne change. Critère : aucun élément focalisable à l'intérieur de `#panel` quand `body.no-panel` (§ 8).

---

## 3. Palette et aide des raccourcis

### 3.1 Palette (champ unique, existant)

Conteneur inchangé : `#palette` plein écran, `--scrim` + flou 4 px, boîte `min(640px, 100% - 32px)`, `--r-panel`, fond `--palette-bg`, haut à 14vh.
Rôles : champ `role="combobox"` (`aria-expanded`, `aria-controls`, `aria-activedescendant`), résultats `role="listbox"`, groupes
`role="group"` + `aria-labelledby`, boîte `role="dialog" aria-modal="true" aria-label="Rechercher ou lancer une action"`.

| Zone | Contenu et mesures |
|---|---|
| Champ | hauteur 44, icône loupe 16 à gauche, `--text`, 13 / 400, invite « Chercher un fichier, une phase, ou taper > pour les actions » ; touche `/` en `kbd` à droite si le champ est vide ; croix de fermeture 36 (44 au tactile) |
| Mode actions | si le champ commence par `>` : pastille « Actions » (12 / 500, `--text-2`, fond `--raise`, pilule) avant le texte ; le `>` reste saisi ; seuls les résultats d'actions apparaissent, sans intitulés de groupe |
| Intitulé de groupe | 11 / 500, `--text-3`, casse normale (jamais de capitales espacées), 8 px au-dessus, 4 px en dessous ; affiché seulement si au moins deux groupes ont des résultats |
| Rangée | hauteur 36 (44 tactile), padding `--inset-row`, icône 16 · libellé 13 / 500 `--text` (partie correspondante en 600, jamais colorée) · détail 12 / 400 `--text-3` à droite du libellé, ellipse · raccourci à l'extrême droite |
| Raccourci | `kbd` : mono 11 / 500, `--text-3`, hauteur 20, padding 0 6, contour 1 px `--hair-2`, rayon 8, un `kbd` par touche, « + » en `--text-4` entre deux |
| Rangée active | fond `--raise` ET contour `--ring` 2 px décalage -2 (le fond seul n'atteint pas 3:1 ; la couleur ne dit pas l'état) |
| Pied | 12 / 400 `--text-3` : « ↑ ↓ Choisir · ↵ Ouvrir · > Actions · Échap Fermer », filet haut 1 px `--hair` ; masqué au téléphone |
| Annonce | région `aria-live="polite"` cachée visuellement : « 7 résultats » ou « Aucun résultat » (au plus une annonce par pause de saisie de 300 ms) |

**Groupes, ordre fixe** : Entités (comme aujourd'hui : nœuds, fichiers, routes, symboles ; 40 résultats au plus, tri par score) ; Actions ; Onglets.
Champ vide : Actions d'abord (les huit usuelles), puis Onglets, puis les enfants de la racine (Entités, 8 visibles, défilement). Champ saisi :
Entités, Actions et Onglets qui correspondent.
Les entités des autres onglets attendent la coquille de la 79 (D-14) : aucun groupe « Phases » ni « Agents » avant.

**Actions** (une entrée de registre = un seul libellé, repris tel quel par la palette et l'aide ; verbe à l'infinitif, sans point ; une action sans effet sur la vue courante est absente, jamais grisée). Champ vide, les huit usuelles dans cet ordre :
Ajuster à l'écran (F) · Cadrer la sélection et ses voisins (C) · Monter d'un niveau (Retour arrière) · Afficher ou masquer le détail (P) · Zoom avant (+) · Zoom arrière (-) · Ouvrir l'historique Git (G) · Afficher les raccourcis (?).
Au-delà, à la saisie : Basculer couloirs, liste, graphe (V, Projet seulement) · Poser une question à l'agent (remplit la barre, ne l'envoie jamais : Q4) · Copier le lien de cette vue.
**Touche de « Cadrer la sélection et ses voisins » : `C`** (décision déléguée, à consigner par le manager). Vérifiée libre : l'écouteur global du moteur ne traite que `/`, `k` avec ⌘ ou Ctrl, Retour arrière, Échap, `f`/`F`, `p`/`P`, Entrée, `=`/`+`, `-` et les flèches d'un parcours ;
aucun module `ui/` n'en écoute d'autre ; le registre de cette spec ne porte que `/`, `?`, `g`, `v`, `f`, `p`, `+`, `-`. `C` est lue sans distinguer la casse (`c` et `C`, donc sans dépendre de Maj ni de Verr. Maj, comme `f`/`F` du moteur), ignorée avec ⌘, Ctrl ou Alt
(⌘C et Ctrl+C restent la copie, D-12) et neutralisée sur Équipe comme `f` (PU-G-137). Mnémonique : Cadrer.
**Onglets** : Aller à Code, Aller à Projet, Aller à Équipe (pas de raccourci inventé ; l'onglet courant est absent).
Aucune action « envoi » n'existe ; aucune action ne prend le focus d'une proposition (Q5). **Copier le lien de cette vue** : la palette se ferme, le toast du moteur dit « Lien copié » (annonce polie) ; en cas d'échec du presse-papiers, le toast dit « Copie impossible. Le lien est dans la barre d'adresse. ».

**État vide** (requête sans résultat) : bloc à 24 de padding, deux lignes à gauche : « Aucun résultat pour « <requête> » » (13 / 500 `--text`) puis
« Essayez un nom de fichier, ou tapez > pour les actions. » (12 / 400 `--text-3`). Pas d'illustration, pas d'icône colorée.

### 3.2 Aide `?`

Modale, `--r-panel`, fond `--modal-bg`, `--shadow-deep`, sur `--scrim` ; largeur `min(720px, 100% - 32px)`, hauteur max `80vh`, défilement interne ;
padding `--inset-panel` (20). Ouverte par `?` (hors saisie), par la palette, jamais au premier lancement. `role="dialog" aria-modal="true"
aria-labelledby=<titre>`.

- **En-tête** : titre « Raccourcis clavier » (18 / 600, `--text`) à gauche ; à droite le bouton « Fermer » (icône croix, 36, 44 tactile, `aria-label`).
  Sous le titre : « Vue : <Onglet> » (12 / 400 `--text-3`) qui dit quel filtre s'applique.
- **Corps** : une section par groupe ; intitulé du groupe 13 / 600 `--text`, 24 d'écart entre groupes, 8 sous l'intitulé ; liste de définitions (`<dl>`), deux
  colonnes de rangées dès 600 px de large, une seule en dessous ; chaque rangée : définition 13 / 400 `--text-2` à gauche, touches en `kbd` (§ 3.1) à droite ;
  rangée de 32 de haut.
- **Pied** : une ligne 12 / 400 `--text-3` : « Tout est aussi dans la palette : ⌘K ou /. » (« Ctrl K » hors macOS).

| Groupe | Visible sur | Rangées (libellé du registre : touche) |
|---|---|---|
| Partout | les trois onglets | Rechercher : / ou ⌘K · Afficher les raccourcis : ? · Ouvrir l'historique Git : G · Fermer ou remonter d'un cran : Échap · Zone suivante : Tab |
| La carte | Code, graphe de Projet | Carte voisine : ← ↑ ↓ → · Première carte, Dernière carte : Origine, Fin · Plonger dans la carte : Entrée · Monter d'un niveau : Retour arrière · Ajuster à l'écran : F · Cadrer la sélection et ses voisins : C · Zoom avant, Zoom arrière : + et - · Afficher ou masquer le détail : P |
| Projet : couloirs et liste | Projet | Changer de vue : V · Phase voisine : ← ↑ ↓ → · Première phase, Dernière phase : Origine, Fin · Plonger dans la phase : Entrée ; Sélectionner : Espace (toutes largeurs et toutes formes, P80-D-51 ; au toucher un appui sélectionne, la feuille de détail porte « Ouvrir la phase »). « Sélectionner : Espace » est `palette: false` comme « Plonger » (rangée d'aide seule, pas une action de palette) · Désélectionner puis monter d'un niveau : Échap (la vue DOM compte comme canevas) ; libellés neufs au dictionnaire 80, déclarés par le plan des couloirs dans le même registre (`80-UI-SPEC.md`) |
| Équipe | Équipe | les raccourcis propres de l'onglet, déclarés dans le registre par ses plans (+ - F P C y sont neutralisés, PU-G-137, donc absents) |

Registre unique des raccourcis : une entrée = `{ groupe, onglets, touche, libellé, action, palette }` (`palette: false` pour une rangée d'aide seule : Plonger, Sélectionner, Tab, Échap) ; l'aide, la palette (colonne raccourci) et le test de
cohérence lisent ce registre. Un raccourci absent du registre n'existe pas pour l'utilisateur. Libellé neuf = entrée du dictionnaire 80.
Noms de touches : Échap, Entrée, Retour arrière, Origine, Fin, Maj, Ctrl, ⌘ ; flèches par glyphe avec `aria-label` (« flèche gauche »).
**Ligne sur le terminal (P80-D-55, arbitrage Samuel, AskUserQuestion session principale, 2026-11-11 : « Une ligne dans l'aide (Recommandé) »).** L'aide `?` et la palette portent, **seulement quand le cockpit tourne sans `--terminal`**, la ligne de texte seul « Le terminal s'active avec --terminal » : aucune pastille, aucun port, aucune route, aucune action ; rangée `palette: false` dans l'aide, résultat d'information non exécutable dans la palette (« Terminal ») ; avec `--terminal`, la ligne est absente.

---

## 4. Coin bas-droit : minicarte, repères de bord, ligne d'état

### 4.1 Géométrie commune

Le bloc « bord de carte » (`#vf-coin`) vit dans `#stage`, donc il monte avec la réserve du tiroir du terminal (`body.vf-term-ouvert #stage { bottom }`) : il ne
le recouvre jamais (P71-D-35, sans rien déduire d'autre). Position, `position: absolute` : `right: calc(var(--pw) + var(--edge))` (bord droit de la zone
libre, à gauche du panneau ouvert ; 16 du bord quand `body.no-panel`) ; `bottom: calc(<hauteur de #ask> + var(--edge) + var(--sp-8))` quand la barre de question existe
(mesurée, relue à chaque changement de hauteur, comme `--vf-ask-h` en feuille de détail), sinon `var(--edge)` (Équipe, export). Même transition de `right`
que `#ask` (nulle en mouvement réduit). `z-index: 3` (sous `#ask` 4, panneau 5, tiroirs 7 et 8, palette 40). Il se pose par-dessus le canevas sans le pousser ni
changer `freeArea()`.

Pourquoi au-dessus de la barre de question et non à côté : à 1 440 px panneau ouvert la barre (700 px, centrée dans 1 048) laisse 158 px à sa droite, moins que les 176 du bloc ; de 1 000 à 1 279 px la barre vaut `min(700, 100% - panneau - 48)`
(`01-vf-responsive.js`), soit 584 à 1 024 panneau ouvert (de 24 à 608 dans 632) : elle ne laisse rien à côté. Une seule règle vaut à toute largeur.

Fond : `.glass` (`--elev`, flou 20, `--shadow-float`), rayon `--r-ctl` (12), padding 8, largeur 176 (144 de minicarte + 16 d'air), `pointer-events` actifs sur le
bloc entier. Aucune bordure colorée, aucun halo.

### 4.2 Minicarte (1 000 px et plus, souris ; absente sous 1 000 px et au tactile pur)

- Surface 144 × 96 maximum, rayon 8, fond `rgba(var(--ink), .06)` sur `.glass` ; contenu en SVG, le rapport de la carte entière tient dans la surface (marge 4).
- **Cartes** : rectangles pleins `--text-4` (sombre #828282 : 4,0:1 ; clair #666666 : 5,0:1, sur le fond de la surface, calc. ; 3:1 requis) ; la carte sélectionnée en `--text`. Pas de teinte d'état.
- **Cadre du champ** : rectangle sans remplissage, trait 1,5 px `--text-2` (3:1 requis, atteint largement), coins à 2. Il représente la zone libre
  (`freeArea()`), pas la fenêtre.
- **Part du champ sous le tiroir Git** : quand le tiroir est ouvert, la portion du cadre recouverte est hachurée (traits 1 px à 45°, pas de 4, `--text-3` pleine opacité : 3:1 sur le fond de la surface, calc. 7,3 en sombre, 6,2 en clair), jamais
  grisée par un fond teinté ; le cadre reste visible autour. `freeArea()` ne la déduit pas (PU-G-204). Fermé, aucune hachure.
- **Interaction** : clic ou glissement = recentrer le champ sur ce point (déplacement sans changement de zoom ; mouvement réduit : saut). Pas dans l'ordre de Tab
  (le clavier a ses flèches et les repères) : `role="img"` + `aria-label` « Minicarte : 12 cartes visibles sur 26 » (+ « ; une partie du champ est sous l'historique Git »
  quand c'est vrai). Le clavier n'en dépend pas.
- Affichée en permanence sur les vues à canevas (pas d'apparition conditionnelle : la mise en page ne saute pas).
- Masquée quand la hauteur utile de la scène (au-dessus de la barre de question) tombe sous 360 px (tiroir du terminal haut sur un écran bas) ; la ligne d'état reste.

### 4.3 Ligne d'état (jointe à la minicarte)

Sous la minicarte, dans le même bloc, filet haut 1 px `--hair`, padding-top 8, trois rangées de 16 de hauteur de ligne, 11 px :

| Rangée | Contenu | Police | Couleur |
|---|---|---|---|
| 1 | icône branche 16 + nom de branche entier, ellipse **au milieu** (début 10 caractères, « … », fin 8 ; coupure calculée en JS d'après la largeur mesurée, jamais par `direction`) ; nom complet en `title` et dans l'étiquette | mono 500 | `--text-2` |
| 2 | glyphe du direct + mot : « Direct » ou « Direct coupé » (glyphe de M9 : point plein, anneau vide si coupé) | sans 500 | glyphe `--st-done` ou `--text-4`, mot `--text-2` |
| 3 | « Mis à jour à 14:32 » (heure locale 24 h, à chaque événement `graphe`) ; direct coupé : « Reprise en cours, mise à jour à 14:32 » (deux lignes, le bloc grandit de 16) | sans 400, tabulaire | `--text-3` |

Hauteur utile de la scène sous 480 px ou minicarte masquée sans place : mode compact, deux rangées (branche ; « ● Direct · 14:32 »), l'heure en toutes lettres dans l'étiquette.
Sans minicarte (Projet en couloirs, Équipe, tactile à partir de 1 000 px) : le bloc ne contient que la ligne d'état. Sans `--terminal`, aucun segment du terminal (P71-D-02) ;
« Terminer » reste dans la barre du tiroir. La dernière commande n'apparaît nulle part (P67-D-14). Direct coupé : glyphe, mot et rangée 3 changent ; pas de couleur d'alerte ; `title` et annonce : « Direct coupé. Reprise automatique ; si elle échoue, rechargez la page. ».
Seule la rangée 2 est `role="status"` (lecture polie ; ni l'heure ni la branche ne sont annoncées).

### 4.4 Repères de bord (« N cartes par là »)

À toute largeur ; seuls dispositifs sous 1 000 px et au tactile. Un repère par bord du champ qui a au moins une carte entièrement hors champ de ce côté ; le nombre est celui des cartes
entièrement hors champ de ce côté (une carte coupée ne compte pas).

- **Forme** : pilule `.glass`, hauteur 28 (32 au tactile), padding 0 12, chevron 16 tourné vers le bord + texte 12 / 500 `--text-2` ; « 16 cartes par là » / « 1 carte par là ». Zone d'appui 44 × 44 minimum
  (pseudo-élément qui déborde de 8 de chaque côté ; jamais de recouvrement entre deux zones d'appui).
- **Place** : au milieu du bord correspondant du champ de lecture (§ 4.6) rentré de 8 ; le repère gauche se pose donc au bord droit du tiroir Git quand il est ouvert, jamais dessous. Le compte inclut les cartes cachées sous une surcouche. Haut : sous le titre ; bas : au bord haut de la zone basse (jamais sur la barre de question) ; droite : avant le panneau.
  Le repère droit remonte pour rester à 8 de `#vf-coin` ; le repère gauche pour rester à 8 de `#zoom` quand celui-ci est en pile verticale (largeur ≤ 700 px).
- **Geste** : clic ou Entrée = amener la carte hors champ la plus proche de ce bord dans le champ (`bringIntoView`), sans changer la sélection ni le zoom.
- **Clavier** : ce sont des `button` dans l'ordre de Tab, juste après l'arrêt du canevas ; `aria-label` « 16 cartes hors champ à gauche. Aller à la plus proche. ».
  Annonce quand le nombre change : aucune (éviter le bavardage).
- **Focus orphelin.** Un repère dont le compte tombe à 0 disparaît avec le focus dessus : instance de la règle de famille « focus orphelin » de `80-UI-SPEC.md` § 5, dont l'ordre de repli est unique (P80-D-50 d) et n'est pas réécrit ici ; le fruit du geste est la carte ramenée.
- **Mouvement réduit** : pas de fondu, pas d'apparition animée ; compte et présence mis à jour d'un coup. Forme statique gardée (le repère est le même, immobile).
- Un repère qui recouvrirait la carte sélectionnée ou la carte focalisée est masqué le temps du recouvrement (jamais de carte cachée par un repère).

### 4.5 Compositions par largeur

| Largeur | Panneau | Bloc bas-droit | Zoom | Pastille terminal | Barre de question |
|---|---|---|---|---|---|
| 1 440 | ouvert (392 de réserve) : bloc à `right: 408`, 176 de large, soit x de 856 à 1 032 ; minicarte 144 × 96 + ligne d'état, soit 176 × 168 (+ 16 si « Direct coupé ») | oui | bas gauche, inchangé | bas gauche, inchangé | 700 centrée dans 1 048 (174 à 874), le bloc est au-dessus d'elle (bas du bloc à 8 au-dessus de son bord haut) |
| 1 440 | fermé | `right: 16` | idem | idem | 700 centrée dans 1 440 |
| 1 024 | ouvert : zone libre de 632, bloc de 440 à 616 ; barre de 584 (24 à 608), le bloc est au-dessus d'elle | oui ; avec tiroir Git ouvert (352, de 16 à 368) la hachure couvre 59 % du cadre (352 sur 600) | idem | idem | 584 |
| 1 024 | fermé | `right: 16` | idem | idem | 700 |
| 1 000 à 1 279, tactile | selon l'état | ligne d'état seule (pas de minicarte au doigt) | selon l'existant | idem | idem |
| ≤ 999 | feuille de détail | aucun bloc ; repères seuls | colonne verticale à gauche au-dessus de la barre (existant) | existant | existant |

**Feuille de détail** (≤ 999 px ou pointeur grossier, `80-UI-SPEC.md` § 0 point 6 ; zone basse testée à 390 et 800 px) : zone basse dégagée, de bas en haut : barre de question, zoom, rien d'autre ; pastille « Terminal » au bord gauche bas (existant).
Aucun élément ne recouvre la carte sélectionnée : les repères gardent 8 d'écart avec zoom et pastille et se masquent si la feuille de détail est ouverte
(`body:not(.no-panel)`). Cibles ≥ 44 × 44 (repères, boutons de zoom portés de 34 à 44 de zone d'appui sans changer leur taille visible de 34 si la pile l'exige).

**Tiroir du terminal ouvert** : la scène est relevée ; le bloc et les repères suivent le bas de la scène, donc restent au-dessus du tiroir (aucune intersection de rectangles).
Sous 360 px de hauteur utile : minicarte masquée, ligne d'état compacte, repères gardés. Hauteur rehaussée du tiroir : AUDC-M11, pas dans ce fichier.

### 4.6 Règle unique : une surcouche n'est pas une zone de lecture

Le bloc `#vf-coin` et le tiroir Git recouvrent le canevas sans le pousser (PU-G-204) : `freeArea()` reste intact. La couche VF en tire un **champ de lecture** = `freeArea()` moins ces deux surcouches quand elles sont affichées
(tiroir Git : bande gauche, `x` portée à son bord droit + 16 ; bloc : coin bas-droit). Ce champ, et non `freeArea()`, sert à : `bringIntoView` (ramener une carte focalisée ou sélectionnée), le focus itinérant, « Ajuster » et « Cadrer la sélection »,
le placement et le compte des repères. Un déplacement minimal sort la cible de toute surcouche (horizontal pour le tiroir, vertical pour le bloc) ; une carte focalisée n'est jamais laissée dessous. Pour « Ajuster » et « Cadrer », le champ est le meilleur de deux découpes
du coin (largeur moins le bloc, ou hauteur moins le bloc), par le plus grand `kFit`. Le plancher 11/13 (PU-G-026) reste : ce que la formule rogne est atteint par les repères. Ouvrir ou fermer le tiroir ne recadre jamais la carte (aucun appel à `fit`) ;
seul le prochain geste utilise le champ de lecture. Un repère dont la position tomberait sous une surcouche est décalé (§ 4.4) ou masqué s'il n'y a pas de place.

**Extension aux vues DOM de Projet (couloirs, liste, intérieur de phase).** La règle vaut aussi pour un contenu défilant sous des éléments fixes : le champ de lecture d'une vue DOM est sa zone de défilement moins `#ask`, `#vf-coin`
(en bas), la pastille « Terminal » (bas gauche), le tiroir Git (à gauche, quand il est ouvert), le panneau (à droite, quand il est ouvert) et, en feuille de détail (≤ 999 px ou pointeur grossier, `80-UI-SPEC.md` § 0 point 6), cette feuille ouverte. La vue le dit en CSS : `padding-bottom` et
`scroll-padding-block-end` dérivés de `#ask` + `#vf-coin` mesurés, plus la feuille de détail ouverte (y compris tactile ≥ 1 000 px) et la pastille « Terminal », toujours (P80-D-50 a, c) ; `scroll-padding-inline-start`/`-end` égaux à la
largeur du tiroir Git (+ `--edge`) et à `--pw` quand ils sont ouverts, avec une extrémité défilable de la même largeur pour que le défilement soit possible, **seulement en panneau latéral (≥ 1 000 px et pointeur fin) ; aucun défilement horizontal en feuille de détail, à 390 comme à 800 px** (P80-D-50 b ; aucun couloir ne bouge : `80-UI-SPEC.md` § 1.1 et § 3). Une carte ou rangée focalisée, sélectionnée ou
atteinte par Fin n'est jamais laissée dessous.

---

## 5. Tiroir Git

Position, `z-index` et rôle inchangés (`aside`, `position: fixed`, par-dessus la carte, ne la pousse jamais : PU-G-204). Un seul latéral sous 1 280 px (Q12) : inchangé.

**Rangées paginées.** Au départ ≤ 110 rangées de commits ; sous la dernière, une rangée-bouton « Afficher 100 de plus » : hauteur 36, pleine largeur du corps, fond `--raise`, rayon 10,
12 / 500 `--text-2`, à droite « 502 restants » en mono 11 `--text-3` (tabulaire) ; moins de 100 restants : « Afficher les 37 derniers ». Une fois tout affiché : pied « Tous les 612 commits sont affichés ».
Le pied permanent devient « 110 commits affichés sur 612 ». Au clic : le focus va sur la première rangée ajoutée (tabulation itinérante gardée), annonce polie « 100 commits de plus affichés, 502 restants ». Quand ce clic épuise la liste, le bouton disparaît avec le focus dessus : instance de la règle de famille « focus orphelin » de `80-UI-SPEC.md` § 5 (ordre unique, P80-D-50 d, non réécrit ici ; le fruit du geste est la première rangée ajoutée).
Même règle pour Tags, Stash et Auteurs au-delà de 110 lignes. Le bouton a l'anneau § 0.

**Worktrees repliés.** Section fermée au départ ; titre « Worktrees · 7 » (compte en `--text-3`, tabulaire). Les autres sections gardent leur état actuel (Graphe ouvert, Tags, Stash, Auteurs fermés).
Chevron de section : composant du § 6 (F1).

**Volet bas de détail.** Un commit s'ouvre par `Entrée` ou clic sur sa rangée : la liste garde sa place, un volet apparaît au bas du tiroir (jamais dans le panneau ni inséré sous la rangée).
- Hauteur : `clamp(192px, 35%, 256px)` du tiroir (≈ 239 à 1 024 × 768 : tiroir de 684) ; défilement interne ; filet haut 1 px `--hair-2` ; même fond que le tiroir.
  > Amendement du 2026-11-12 : voir § « Amendement du 2026-11-12 » en fin de fichier (tiroir mesuré 580 avec CLI, 511 sans ; volet 203 ou 192).
- Contenu : ligne 1 sha court mono 12 / 500 `--text` + bouton « Copier le sha » (28 ; au clic le libellé devient « Copié » pendant 2 s puis revient, annonce polie « Sha copié » ; échec : « Copie impossible », le sha est sélectionné et l'annonce dit « Copie impossible. Copiez le sha sélectionné à la main. ») + bouton « Fermer le détail » (icône croix 28, 44 tactile) ; message complet 13 / 400 `--text-2`, 3 lignes visibles puis défilement ;
  « Auteur · date » 12 / 400 `--text-3` (date absolue en `title`) ; « N fichiers modifiés » 12 / 500 `--text-2` puis liste : nom du fichier mono 12 / 500 `--text`, dossier mono 11 `--text-3` (c'est le dossier qui reçoit l'ellipse,
  jamais le nom), à droite `+12 −3` tabulaire, statut en lettre avec mot (« Ajouté », « Modifié », « Supprimé ») jamais en couleur seule.
- Rôle : `role="region" aria-label="Détail du commit <sha>"`. Le focus reste sur la rangée à l'ouverture (les flèches continuent) ; Tab depuis la liste entre dans le volet. Échap ferme le volet (cran 4 de § 2) et rend le focus à la rangée.
- Lisible à 1 024 × 768 : tiroir de 352 de large (corps de 320), texte du volet ≥ 12 px, `scrollWidth` ≤ `clientWidth` du volet, liste restante ≥ 240 px de haut (6 rangées de 40), Worktrees fermé.
  > Amendement du 2026-11-12 : le plancher de 240 px ne vaut qu'avec le CLI `claude` présent (295 ou 272) ; sans CLI : au moins 3 rangées entières (§ en fin de fichier).
- Sous 1 000 px : volet `clamp(160px, 45%, 320px)`.

**Poignée de largeur.** Bord droit du tiroir, à l'intérieur (2 px de retrait) ; `role="separator" aria-orientation="vertical" tabindex="0"`, `aria-label="Largeur de l'historique Git"`, `aria-valuemin/max/now`,
`aria-valuetext` « 352 pixels ». Zone d'appui 12 de large (24 au tactile) sur toute la hauteur moins 24 en haut et en bas ; visuel : pilule 4 × 32 `--text-4` au repos (≥ 3:1 sur `--bg` et `--surface`, calc. 5,0 et 4,6 en sombre, 5,2 en clair),
`--text-3` au survol, `--text-2` pendant le glisser ; au focus clavier la pilule passe à 6 × 32 avec l'anneau § 0. Curseur `col-resize`.
Bornes : minimum 280 ; maximum `max(280px, 100vw - panneau ouvert - 312px)` (formule existante sans son plafond de 360 : 352 à 1 024 panneau ouvert, 768 à 1 440) ; défaut `min(360px, maximum)` (352 à 1 024 panneau ouvert) ; clavier : ←/→ de 16, Maj de 64, Origine/Fin = bornes,
Entrée ou double clic = retour au défaut ; mémorisée en `localStorage` par lab ; absente sous 1 000 px. Le tiroir ne pousse jamais la carte pendant le glisser ; la hachure de la minicarte suit en direct.

---

## 6. Jetons et finitions

Jeton visé, valeur actuelle (lue dans le code), valeur proposée, contraste visé. « Sur » = fond de lecture. `DESIGN.md` est mis à jour pour chaque ligne qui change (§ 2, § 5).

| Réf. | Jeton ou règle | Actuel | Proposé | Contraste visé sombre | Contraste visé clair |
|---|---|---|---|---|---|
| X5 a | `--st-active` en clair (glyphe « En cours », `--st-recette` le suit) | `var(--sev-medium)` = `#b88100` | valeur propre au thème clair `#a37100` ; `--sev-medium` et ses familles (`--n-worker`, `--m-PUT`, `--k-queue`) inchangés ; sombre inchangé (`#ffe08a`) | ≥ 13:1 sur `--surface` (calc.) | ≥ 3,5:1 sur `--bg` (calc. 3,85), 4,27 sur `--surface` ; actuel 3,40 et 3,04 |
| X5 b | carte `st-active` et `st-recette` en clair | fond `color-mix(--raise 70%, --surface)` (gris lu « désactivé ») | fond `var(--surface)` ; l'état se dit par glyphe, mot et titre 600 `--text` ; sombre : inchangé (`--raise` allégé) | inchangé | titre `--text` sur `--surface` ≥ 15:1 ; aucun contour ni fond teinté ajouté (Q9) |
| X5 c | cartes estompées (`svg.dim`) | `opacity: .55` sur les enfants de la carte ; WebKit `.28` sur le `foreignObject` | `.72` sur les enfants de la carte SAUF la pastille d'état (`.vst`, `.rw`), laissée à `opacity: 1` pour que le glyphe garde 3:1 (3,5:1 pour « En cours ») ; WebKit : même règle sur les enfants, plus sur le `foreignObject` ; les textes `--text-3` et `--text-4` y sont ramenés à `--text-2` | texte ≥ 4,5:1 (calc. 5,9) | texte ≥ 4,5:1 (calc. 4,7 pour `--text-2`) |
| F1 | `<details>` et `<select>` | triangle natif ; `<select>` natifs (`#vf-modele`, `#proposition-mode` de la page du terminal) | composants à la charte ci-dessous | non-texte ≥ 3:1 | idem |
| F3 | taille du bouton de thème (l'ouvreur Git : dessiné à 36 px, P80-D-56) | 44 par défaut (`05-theme.js`), 36 de 1 000 à 1 279 souris seulement | un jeton `--hdr-btn` : 36 à partir de 1 000 px sans tactile, 44 en dessous et au tactile ; tout bouton d'en-tête le lit (`.btn`, `.btn.icon`, `#theme-toggle`, `#flows-btn`, `#filters-btn`, `#btn-panel`, `#hdr-ext > button`) | cible ≥ 36, ≥ 44 tactile | idem |
| F4 | chiffres dans des phrases | `font-family: var(--mono)` sur `#vf-lock`, `.aw-driver .n`, `.r-t`, `.r-meta b`, `.r-verr .n` | `font-family: inherit` (Inter) + `font-variant-numeric: tabular-nums`, graisse 500 ; le mono reste pour sha, chemins, branche et touches | sans objet (couleur héritée) | idem |
| F5 | pastilles du menu « ⋯ » (`#vf-plus .badge`, `.vf-pl-i .badge`) | `background: var(--on)` : noir en clair, quasi blanc en sombre | par source, comme au bureau : Santé `--hc-badge` (sévérité) avec `--on-sev-text` ; Récent `--recent` avec `--on-recent-text` ; le point de 8 sur « ⋯ » prend la teinte de la pastille la plus haute, sinon `--on` | `--on-recent-text` sur `--recent` ≥ 9:1 ; encre sur sévérité ≥ 7:1 (calc.) | `--on-recent-text` `#161616` sur `#009e5a` 5,2:1 ; `--on-sev-text` sur `#b88100` 5,3:1 |
| X8 | hauteur des onglets (largeur ≤ 700 px) | `padding: var(--sp-4) var(--sp-8); 13px` ≈ 26 | onglet visuel 36 de haut, zone d'appui 44 (pseudo-élément) ; piste `--raise` de 44 ; en-tête sur une rangée (P70-D-01) | cible ≥ 44 | idem |

**Disclosure `<details>` (F1).** Marqueur natif retiré (`list-style: none`, `::-webkit-details-marker`). Chevron 16 (icône §7) en `currentColor`, `--text-3` ; fermé : vers la droite ; ouvert : tourné de 90°
(transition 150 ms, nulle en mouvement réduit). Zone du `summary` ≥ 32 de haut (44 tactile), 13 / 500, anneau § 0 en décalage -2. Étendu aux « Détails techniques », au menu du lancement, aux sections du tiroir Git, à « Historique »
des couloirs. Jamais un triangle natif.

**Sélecteur `<select>` (F1).** `appearance: none`, hauteur 28 (36 tactile), fond `--raise`, contour 1 px `--hair-2`, rayon 10, padding 0 28 0 12, 12 / 500 `--text-2`, chevron bas 16 à droite en `--text-3`,
`color-scheme` posé par thème pour que la liste native suive le sombre et le clair ; focus : anneau § 0 ; désactivé : `--text-4`, pas d'opacité. La liste déroulante garde l'apparence du système (accepté). La
page du terminal est une autre origine : elle reprend les mêmes valeurs dans sa feuille (seule exception à « zéro valeur en dur », à signaler au plan) ou reçoit les jetons du thème si le mécanisme existe.

**Une seule hauteur de bouton d'en-tête.** Cf. F3. Tranché (P80-D-56) : l'ouvreur Git `#vf-git-ouvreur`, à 44 parmi des boutons à 36 de 701 à 1 279 px (P78-D-20, P78-D-34), est **dessiné à 36 px, avec une zone d'appui de 44 px** par pseudo-élément ; il lit `--hdr-btn` comme les autres boutons d'en-tête.
Le plan ne touche pas à cet ouvreur avant réponse (D-20).

---

## 7. Contrat de libellés (français, dictionnaire de la 80)

| Élément | Texte |
|---|---|
| Nom du canevas | « Carte : <niveau>, N cartes » |
| Nom d'une carte | « <titre>, <état>, <compte>, reliée à N carte(s) » ou « …, aucune liaison » |
| Niveau vide | « Niveau <nom>, aucune carte » |
| Invite de la palette | « Chercher un fichier, une phase, ou taper > pour les actions » (invite de champ, hors registre) |
| Groupes | « Entités », « Actions », « Onglets » |
| Vide | « Aucun résultat pour « <requête> » » / « Essayez un nom de fichier, ou tapez > pour les actions. » |
| Pied de la palette | « ↑ ↓ Choisir · ↵ Ouvrir · > Actions · Échap Fermer » |
| Annonce de la palette | « N résultats » / « 1 résultat » / « Aucun résultat » |
| Aide | titre « Raccourcis clavier » ; « Vue : Code » ; groupes « Partout », « La carte », « Projet : couloirs et liste », « Équipe » ; « Fermer » ; pied « Tout est aussi dans la palette : ⌘K ou /. » ; libellés de rangées = ceux du registre (ci-dessous) |
| Registre (palette et aide, un libellé par entrée) | « Rechercher », « Afficher les raccourcis », « Ouvrir l'historique Git », « Ajuster à l'écran », « Cadrer la sélection et ses voisins », « Monter d'un niveau », « Afficher ou masquer le détail », « Zoom avant », « Zoom arrière », « Basculer couloirs, liste, graphe », « Poser une question à l'agent », « Copier le lien de cette vue », « Carte voisine », « Première carte », « Dernière carte », « Plonger dans la carte », « Fermer ou remonter d'un cran », « Zone suivante » |
| Ligne terminal (sans `--terminal` seulement) | « Le terminal s'active avec --terminal » |
| Onglets | « Aller à Code », « Aller à Projet », « Aller à Équipe » |
| Minicarte | « Minicarte : N cartes visibles sur M » ; « ; une partie du champ est sous l'historique Git » |
| Repères | « N cartes par là » / « 1 carte par là » ; étiquette « N cartes hors champ à gauche. Aller à la plus proche. » (gauche, droite, en haut, en bas) |
| Touche C | `c` et `C` (Verr. Maj) cadrent ; ⌘C, Ctrl+C et Alt+C ne cadrent pas ; sans effet dans un champ de saisie et sur Équipe |
| Ligne d'état | « Direct », « Direct coupé », « Mis à jour à HH:MM », « Reprise en cours, mise à jour à HH:MM » ; étiquette de la branche : nom complet |
| Tiroir Git | « Afficher 100 de plus », « Afficher les N derniers », « N restants », « N commits affichés sur M », « Tous les M commits sont affichés », « Worktrees · N », « Détail du commit <sha> », « Copier le sha », « Copié », « Copie impossible », « Sha copié », « Fermer le détail », « N fichiers modifiés », « Ajouté », « Modifié », « Supprimé » |
| Poignée | « Largeur de l'historique Git » ; valeur « 352 pixels » |
| Copies | « Lien copié » ; « Copie impossible. Le lien est dans la barre d'adresse. » ; « Copie impossible. Copiez le sha sélectionné à la main. » |
| Annonce de pagination | « 100 commits de plus affichés, N restants » |

Aucun tiret cadratin dans ces textes. Les libellés d'actions n'emploient pas « Envoyer » ni « Lancer » (Q4).

---

## 8. Critères vérifiables (par élément)

| Élément | Critère (mesure) |
|---|---|
| Carte focalisée | sous Tab puis flèche : `getComputedStyle(.card).outlineWidth` = 2 px et `outlineColor` = `--ring`, dans les deux thèmes ; aucun `box-shadow` coloré ; aucun anneau après un simple clic |
| Nom de carte | l'arbre d'accessibilité donne rôle `option`, nom conforme au gabarit, `aria-posinset/setsize` ; le canevas est un `listbox` nommé |
| Tabulation | un seul arrêt pour le canevas (une seule carte à `tabindex=0`) ; les suites X4.0-X4.2 et EK18 sont mises à jour sans être affaiblies |
| Plongée, remontée | après `Entrée` puis `Échap`, `document.activeElement` est la carte quittée ; à l'arrivée, une carte du niveau ; mouvement réduit : focus posé sans attendre 340 ms |
| Piège | Tab 30 fois dans la palette ou l'aide : `document.activeElement` reste dans la boîte ; Maj+Tab depuis le premier élément bouclé ; le `inert` du terminal n'est jamais levé par la pile |
| Échap | chaîne modale > menu > parcours > volet > tiroir > feuille > désélection > niveau : un appui = un cran, vérifié pour chaque paire ; palette + Tab hors du champ + Échap ferme (AUDC-M6) ; terminal focalisé : Échap n'atteint pas la pile ; focus sur un bouton du panneau, dans la barre de question ou un `<select>` : ni désélection ni remontée (PU-G-175) ; au bureau, Échap ne ferme pas le panneau |
| Retour du focus | après fermeture, focus sur l'ouvreur ; ouvreur disparu : sur la carte itinérante ; panneau fermé avec le focus dedans : `document.activeElement` = `#btn-panel` ou la carte itinérante, jamais `body` ; chacune des actions de palette ci-dessus (§ 2) laisse le focus où sa règle le dit |
| Panneau fermé | `body.no-panel` : 0 élément focalisable dans `#panel` ; `visibility: hidden` après la transition |
| Copies | « Copier le sha » : libellé « Copié » 2 s (±0,5 s) puis restauré, région live polie renseignée ; presse-papiers refusé : « Copie impossible » + sha sélectionné ; « Copier le lien de cette vue » : toast « Lien copié » ou, sur échec, le message d'adresse |
| Palette | `role=combobox/listbox`, `aria-activedescendant` suit les flèches ; `>` ne montre que des actions ; état vide conforme ; aucune action n'appelle `fetch` ni ne remplit autre chose que la barre (Q4) |
| Aide `?` | s'ouvre par `?` hors saisie, jamais dans un champ ; groupes filtrés par onglet ; chaque ligne vient du registre ; à 1 024 × 768 `scrollWidth` ≤ `clientWidth`, hauteur ≤ 80vh avec défilement interne ; chaque rangée a le libellé du registre, identique dans la palette ; champ vide : les huit actions usuelles listées au § 3.1, dans l'ordre |
| Ligne terminal | sans `--terminal` : l'aide `?` et la palette contiennent « Le terminal s'active avec --terminal », texte seul, ni pastille, ni port, ni route, ni action ; avec `--terminal` : absente |
| Vue DOM de Projet (champ de lecture) | à 1 440, 1 024 et 390 px, tiroir Git, panneau et tiroir du terminal ouverts : après Fin, ↓ sur la dernière rangée ou une flèche, le rectangle de l'élément focalisé ou sélectionné n'intersecte ni `#ask`, ni `#vf-coin`, ni la pastille « Terminal », ni la feuille de détail, ni le tiroir Git, ni le panneau ; aucun défilement horizontal en feuille de détail (390 et 800 px, `80-UI-SPEC.md` § 7) |
| Focus orphelin (famille) | repère de bord tombé à 0 et « Afficher 100 de plus » épuisé, avec le focus dessus : `document.activeElement` suit l'ordre unique de `80-UI-SPEC.md` § 5 (critère « Focus orphelin » de ce fichier) ; jamais `body` ; forme Graphe : jamais un `h1` absent |
| Champ de lecture | après « Ajuster », « Cadrer », une flèche ou un repère : aucune carte focalisée, sélectionnée ou cible n'intersecte `#vf-coin` ni le tiroir Git ouvert (rectangles), le plancher 11/13 tenu ; ouvrir ou fermer le tiroir laisse `state.t` inchangé (PU-G-204) ; un repère n'intersecte aucune surcouche |
| Zoom | `+` puis `-` rend `state.t` identique (aller-retour exact) ; le centre est la carte sélectionnée visible |
| Bloc bas-droit | à 1 440 et 1 024, panneau ouvert et fermé, tiroir Git ouvert et fermé, terminal ouvert : aucune intersection entre `#vf-coin`, `#zoom`, `#ask`, pastille et tiroir du terminal (rectangles) ; minicarte ≤ 144 × 96 ; absente < 1 000 px |
| Minicarte | le cadre = le champ de lecture normalisé ; traits de la hachure ≥ 3:1 sur le fond ; hachure présente seulement tiroir Git ouvert et couvrant la même portion que le tiroir ; un clic recentre sans changer `state.t.k` ; hors tab order |
| Repères | pour chaque bord, le compte = nombre de cartes entièrement hors champ ; zone d'appui ≥ 44 × 44 au tactile ; aucun recouvrement de la carte sélectionnée ; en mouvement réduit `document.getAnimations()` actives = 0 |
| Ligne d'état | branche entière en `title`, ellipse au milieu ; heure au format `HH:MM` ; sans `--terminal`, aucun nœud du terminal dans le bloc ; la dernière commande n'y figure nulle part ; seule la rangée 2 est `role=status` ; direct coupé : la rangée 3 dit « Reprise en cours » |
| Tiroir Git | à l'ouverture ≤ 110 rangées ; un clic sur « Afficher 100 de plus » en ajoute 100 et le focus va sur la première ; worktrees fermés ; volet bas : critères chiffrés du § 5 à 1 024 × 768 ; la carte ne bouge pas quand on ouvre, ferme ou redimensionne le tiroir |
| Poignée | `role=separator`, valeurs dans [280, max], clavier ←/→ 16, Origine/Fin, retour 360 ; mémorisée ; absente < 1 000 px |
| X5 | contraste mesuré du glyphe « En cours » ≥ 3,5:1 sur `--bg` en clair ; glyphe d'état d'une carte estompée : `opacity` calculée 1 et ≥ 3:1 ; carte active claire de fond `--surface` ; texte estompé ≥ 4,5:1 dans les deux thèmes |
| F1, F3, F4, F5, X8 | pas de marqueur natif de `<details>` ; `<select>` à 28 (36 tactile) sans `appearance` natif ; boutons d'en-tête, hors ouvreur Git (S80-5), de même hauteur à une largeur donnée ; chiffres : `font-variant-numeric: tabular-nums`, pas de mono ; badges du menu « ⋯ » de la teinte du bureau ; onglets ≥ 44 de zone d'appui au téléphone |
| Grille et jetons | `css-jetons.mjs` vert sur chaque fichier neuf : aucune couleur littérale, aucun espacement hors {2…32}, rayon dans la liste |
| Mouvement réduit (X6) | zéro animation active après chaque geste neuf ; repères et hachure gardés en forme statique |

**Registry Safety** : aucun registre, aucune bibliothèque, aucun appel réseau, aucune route neuve.

---

## 9. Écarts relevés (signalés, non tranchés)

1. **DESIGN.md § 5 contre DESIGNS § 8 (carte active en clair).** § 5 définit `st-active` comme « palier neutre un cran au-dessus de `--surface-hover` (`--raise` allégé) », c'est-à-dire le gris que l'audit juge « lu comme désactivé ». X5 b change cette ligne de DESIGN.md pour le thème clair seulement.
2. **DESIGN.md § 9 (3:1 pour un glyphe) contre D-20 (≥ 3,5:1).** Le glyphe « En cours » clair mesure 3,04 sur `--bg`, ce qui satisfait déjà la charte ; la cible de 3,5 est plus stricte qu'elle. DESIGN.md § 2 (« Doit valoir `var(--sev-medium)` ») doit gagner une exception claire.
3. **DESIGN.md § 9 (« deux intentions d'élévation ») contre l'anneau de focus sur une carte qui porte `--shadow-card`.** Le focus étant un état d'interaction et non d'élévation, la spec garde l'anneau (cohérent avec X4 du lot 0) et propose l'exemption écrite du § 0 pour DESIGN.md § 9. À confirmer par le juge de design.
4. **DESIGNS § 7 « Barre d'état en pied » contre P80-D-18** : une ligne jointe à la minicarte, pas une bande pleine largeur. La décision prime ; le texte de DESIGNS est périmé sur ce point. DESIGNS § 7 range aussi « agents » et « phases » dans la palette : D-14 les repousse après la 79.
5. **DESIGN.md § 4 (hauteurs de contrôle 24, 28, 32, 36, 44) contre les rangées de 40 px du tiroir Git** (existantes) : elles sont gardées ; la spec propose d'ajouter « rangée de liste dense : 40, 44 tactile » aux exceptions écrites de § 4 (lot jetons). La palette, nouvelle, reste à 36.
6. **Ouvreur Git** : dessiné à 36 px, zone d'appui de 44 px (P80-D-56), aligné sur `--hdr-btn`.
7. **Touche « Cadrer la sélection »** : `C` est choisie par cette spec (D-17 ne donne pas de touche ; `Maj+F` écarté : `F` majuscule appelle déjà « Ajuster » dans l'écouteur global) ; décision déléguée à consigner.

## Amendement du 2026-11-12 — P80-D-19 : hauteur du volet bas et plancher de 240 px de la liste

Décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée ; prise par la session principale le 2026-11-12. Elle amende, sans les réécrire, la ligne « Hauteur : clamp(192px, 35%, 256px) du tiroir (≈ 239 à 1 024 × 768 : tiroir de 684) » et la ligne « liste restante ≥ 240 px de haut (6 rangées de 40) ». L'arithmétique d'origine était fausse : elle comptait un tiroir de 684 px (scène 768, haut 68, bas 16, aucun obstacle). Le tiroir se cale au-dessus des petits éléments du coin bas-gauche (zoom, pastille du terminal, avertissement), donc il est plus court.

Mesure du 2026-11-12, 1 024 × 768, panneau ouvert, volet de détail ouvert, tiroir de 352 px de large, deux lectures stables par configuration (hauteurs en px, tiroir = barre 36 + aide 46 + volet + liste) :

| CLI `claude` | `--terminal` | tiroir | volet | liste | barre de question | bas du tiroir |
|---|---|---|---|---|---|---|
| présent | non | 580 | 203 | 295 | 40 | 120 (obstacle retenu : l'infobulle à 656) |
| présent | oui | 546 | 192 | 272 | 40 | 154 (zoom à 622, au-dessus de la pastille à 672) |
| absent | non | 511 | 192 | 237 | 115 | 189 (zoom à 587, au-dessus de la barre à 115) |
| absent | oui | 471 | 192 | 197 | 115 | 229 (zoom à 547, au-dessus de la pastille à 597) |

Arithmétique corrigée : tiroir = 768 − 68 − bas ; volet = clamp(192, 35 % du tiroir, 256) ; liste = tiroir − 36 − 46 − volet. Le volet vaut 203 avec un tiroir de 580 et reste au plancher de 192 dans les trois autres cas.

Domaine de validité du plancher de 240 px : il tient avec le CLI présent, avec ou sans terminal (295 et 272). Il ne tient pas sans CLI : sans CLI le serveur affiche l'avertissement au-dessus de la barre de question à plus de 700 px (comportement amont voulu), la barre passe de 40 à 115 px, le zoom remonte et le tiroir perd 69 px (liste à 237, puis 197 avec la pastille du terminal). Le produit ne s'en défend pas (l'ordre zoom, pastille, barre vient de PU-G-021, arbitrage Samuel, AskUserQuestion session principale, 2026-11-08). Sans CLI, la garantie s'exprime en rangées entières de 40 px, la première rangée commençant à 76 px du haut de la liste : au moins 3 rangées entières à 1 024 × 768 sans terminal (4 mesurées). Le cas GP2.3b de `test-cockpit-git-pagination.sh` la porte ; il n'affirme jamais 240.

Interrupteur du CLI dans la suite : `serve.mjs` ne lit que l'option `--claude <chemin>` (ni `FLOORPLAN_CLAUDE` ni `VF_COCKPIT_CLAUDE` n'ont d'effet, mesuré) ; la suite la passe désormais au lieu de `VF_COCKPIT_CLAUDE`, qui laissait GP2.3 rouge sur un poste sans CLI.
