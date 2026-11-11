# Phase 73 : Gouvernance au cockpit, la régie — UI-SPEC (craft-regie)

**Contrat de design** de l'onglet Équipe devenu une **régie** : une liste par état, quatre sections, à la place du canevas.
Direction « Graphite » (`DESIGN.md`). Format et vocabulaire repris de `78-UI-SPEC.md`.

Sources lues : `DESIGN.md` ; `DESIGNS.md` § 1 à 3 et § 9 ; maquette HTML de l'audit (lecture du code) ; `A4-interface-parcours.md` ;
`REGISTRE.md` (AUDC-I01, I02, I03, I09, I10, I21, I34, I38, D4, M3, F2) ; mission du lot 0 (états lus : occupée, au repos, vous attend,
close ; « outil en cours depuis N » ; orphelin nommé ; santé retirée ; titre « N agents actifs ») ; code actuel de l'onglet
(`ui/71-vf-equipe-rendu.js`, `ui/72-vf-equipe.js`, `ui/73-vf-tiroir-travail.js`, `ui/70-vf-live.js`, `vf-cockpit-equipe-carte.mjs`,
`vf-cockpit-who.mjs`) ; captures existantes de l'état présent. Aucune brique externe de craft consultée : dégradation sur les premiers
principes (contraste WCAG, grille fermée de 8, hiérarchie). Aucun navigateur ouvert, aucun serveur lancé.

Règles de copy valables pour tout le document : texte d'interface en français ; espace insécable avant `: ; ! ?` et entre un nombre et son
unité (« 7 min », « 1 h ») ; aucun tiret cadratin dans le copy ; tout texte venu du disque s'écrit en `textContent`, jamais en HTML.
Classes neuves en `vf-rg-*`, dans un fichier `ui/*vf*` (noms de fichiers laissés au plan). Les choix faits faute de décision sont
numérotés **C-01 à C-16** et repris en fin de document (§ 15).

## 1. Principe, périmètre, retraits

**La question de l'onglet** : « Qui m'attend, qui travaille, que s'est-il passé ? ». La régie répond aux trois premiers tiers
(qui m'attend, qui travaille, ce qui est fini) ; le « que s'est-il passé » (le temps) est la Phase 74.

**Ce que la phase livre sur cet écran** (but du ROADMAP inclus) :
1. les quatre sections par état, « À vous » en tête, classée par impact (AUDC-I01, I02) ;
2. les états lus du lot 0 gardés, plus la décroissance « silencieux, suspect » (AUDC-I03) et « attend ses agents » (AUDC-I38) ;
3. le tenant du verrou de driver, les arbres de travail avec leur travail non commité, l'alerte du veilleur posée sur le nœud (§ 6) ;
4. « Lire le rapport » (AUDC-I34), un titre d'onglet et un compteur qui disent quand quelqu'un vous attend (AUDC-I09), une ligne
   « ailleurs sur ce poste » (AUDC-I10).

**Hors périmètre, écrit pour qu'on ne le dessine pas** : « Répondre », « Recetter », « Ouvrir dans le terminal », « Lui écrire »,
« Demander l'arrêt » (y compris d'un orphelin) : AUDC-Q3 reportée, Phase 81. Aucun terminal sur cet onglet (Q8), aucune barre de
question (plan 69-05), aucun bloc Santé, aucun zoom. Le seul bouton d'étape suivante est « Lire le rapport », en lecture seule.

**Retraits annoncés (un ajout = un retrait)** :
- le canevas de l'onglet Équipe (cartes, zoom, ajustement, `plafond()`/cadrage, « Vue d'ensemble », bascule du panneau de détail,
  bloc `~termines`) et le rechargement de page sur changement de structure : la liste se met à jour en place ;
- le nom écrit trois fois (titre de carte, description, panneau) : un nom, une fois, par ligne (§ 3) ;
- la carte « Terminés depuis moins de 24 h » et le bloc de chiffres « actifs / en attente / terminés » du panneau (absorbés par
  « Terminé, à relire » et par le sous-titre) ;
- trois styles de bouton dans le panneau (AUDC-F2) : un seul (§ 7).

## 2. Gabarit de page

L'en-tête (marque, onglets, recherche, boutons) est inchangé. Le canevas, ses commandes de zoom, « Vue d'ensemble » et la bascule du
panneau de détail ne sont pas dans le DOM de cet onglet. Le contenu est une colonne qui défile sous l'en-tête.

```
+--------------------------------------------------------------------------+
| [logo] depot   [Code|Projet|Équipe (2)]   [Recherche]            [..]    |  en-tête 64 px
+--------------------------------------------------------------------------+
|  Équipe                                        (bloc de titre, en flux)  |
|  Mission : Phase 73, Gouvernance au cockpit                              |
|  5 agents · 2 vous attendent · 1 à relire        [ emplacement : vues ]  |
|  Session qui pilote : tête · plan-73 · tenu depuis 12 min   (verrou)     |
|                                                                          |
|  À vous  2    classé par ce que chaque attente retient dans le plan      |
|  +----------------------------------------------------------------+     |
|  | ? | nom, ligne 2          | quoi, impact        | attend 14 min |     |
|  +----------------------------------------------------------------+     |
|  Au travail  4        (arbre indenté, fils entre les glyphes)           |
|  Terminé, à relire  1                                                    |
|  Au repos  1                                                             |
|  > Arbres de travail · 3, dont 1 avec du travail non commité (replié)    |
|  Ailleurs sur ce poste : 1 session vous attend, dans le lab « atelier ». |
+--------------------------------------------------------------------------+
```

- **Conteneur** : `max-width: 960px` (dimension, comme les 360 px du panneau, pas un jeton), aligné à gauche sur le bord de l'en-tête,
  `padding-inline: var(--edge)`, haut `calc(var(--hh, 64px) + var(--gap-section))`, bas `var(--gap-section)`. Le défilement est celui de la
  page, jamais deux défilements imbriqués. `<main id="vf-regie">` (une seule région principale ; AUDC-m4 : pas de `<main>` aujourd'hui).
- **Bloc de titre** (ex-`#context`, désormais en flux : il ne se superpose plus à rien, AUDC-M2) : surtitre « Équipe » (12,5 px,
  `--text-3`), titre `h1` 24 px/600/`-.025em` (le gabarit existant : « Mission : <nom> », « N missions en cours », « N agents actifs »,
  « Aucune mission en cours », lot 0), sous-titre 14 px `--text-2`. Deux lignes au plus (`line-clamp`).
- **Sous-titre** (remplace « Agents : N actifs · … » et le bloc de chiffres) : `N agents · P vous attendent · Q à relire`. `N` compte
  les agents en vie (au travail, vous attend, attend ses agents, au repos, orphelin) ; `P` et `Q` disparaissent à zéro, sauf quand tout
  est à zéro : « N agents ». Singuliers : « 1 agent », « 1 vous attend », « 1 à relire ». Aucun agent : « Aucun agent en vie ».
- **Ligne du verrou** (§ 6.1) sous le sous-titre, 12 px `--text-3`.
- **Sections** : chacune `<section aria-labelledby>` avec un `h2` suivi d'un compteur en pilule `.meta` (existante) et, pour « À vous »,
  d'une aide. Titres en 15 px/600 `--text`, sauf « À vous » en 18 px/600 (le niveau « titre de section » du `DESIGN.md` § 3) : la
  hiérarchie par la taille et la place, jamais par un fond (Q9). Jamais de capitales espacées. Écart entre sections : `--gap-section`
  (24). Écart titre / liste : `--sp-8`.
- **Surface d'une section** : un bloc `--surface`, `--r-card`, `--shadow-card` (son unique élévation), `padding: var(--sp-8)`. Les lignes
  y sont séparées par un filet `1px solid var(--hair)` (pas de gap, pas de marge qui s'additionne). Aucun anneau coloré, aucun fond
  teinté, aucun liseré (DESIGN § 9).
- **Sections toujours présentes, dans l'ordre fixe** : À vous, Au travail, Terminé à relire, Au repos. Une section vide garde son titre
  et dit une ligne (§ 4) : la carte de l'onglet est prévisible, et « rien n'attend votre décision » est une information.
- **Thèmes** : sombre et clair vérifiés. Les glyphes d'état ne reposent que sur `--surface` (jamais sur `--raise` ni `--raise-2` en
  clair, sous 3:1) ; le bloc de détail d'une ligne (§ 7), lui, est en `--raise` et n'y pose que du texte `--*-text`.
- **Aucune animation propre à la régie**, hors la respiration du glyphe « au travail » déjà définie (§ 3), coupée en mouvement réduit.
  Une ligne qui change de section, apparaît ou disparaît le fait sans transition.

## 3. Une ligne

Une ligne = un agent (ou un arbitrage, § 4.1). Cinq colonnes en grille CSS, de gauche à droite :

| Colonne | Contenu | Largeur (≥ 1 000 px) |
|---|---|---|
| Glyphe | forme d'état, 16 px (`svg.aw-g` existant), `aria-hidden` | `16px` |
| Qui | ligne 1 : **le nom, écrit une fois** ; ligne 2 : nœud, arbre, branche, modèle | `minmax(0, 1.3fr)` |
| Quoi | ligne 1 : l'état en mots ; ligne 2 (discrète) : détail, impact, veilleur | `minmax(0, 1.2fr)` |
| Durée | un préfixe qui dit de quoi elle parle, puis la valeur en mono | `auto`, `min-width: 96px` |
| Droite | contexte (barre fine + %) **ou** l'unique bouton « Lire le rapport » | `152px` |

`gap` de colonnes : `var(--sp-12)`. Padding de ligne : `--inset-row` (8 × 12). Hauteur minimale 44 px (deux lignes de 20 + 16 de
padding suffisent). Survol : fond `rgba(var(--ink), .05)`. Rayon de survol `--r-ctl`.

**Le nom, une fois** (corrige « le nom écrit trois fois ») :
- ligne 1 de « Qui » : agent = `rôle` (mono 11,5 px, `--text-2`) puis tâche (13 px/500, `--text`) ; session = titre (`custom-title`,
  sinon « Session principale ») en 13 px/600. Les sessions de même titre se distinguent par leur arbre, puis par l'identifiant court
  (règle existante `nommer`). Le nom n'est écrit nulle part ailleurs sur la ligne : ni `title`, ni sous-titre, ni bouton.
- le bouton « Lire le rapport » et le bouton d'ouverture de ligne se nomment pour un lecteur d'écran par `aria-labelledby` vers
  l'élément du nom (+ leur propre libellé), jamais par une copie du texte.
- ligne 2 de « Qui » (12 px, `--text-3`, une ligne, ellipsis à droite : on coupe la fin, jamais le début qui distingue) : `nœud plan-73`
  (lien, § 8 ; `--mono` 11,5 px) · `arbre phase-73-a` (seulement s'il diffère de celui du parent ; session : arbre et branche toujours) ·
  `modèle` quand la collecte le porte. Un agent non rattaché : « pas lié à une phase du projet » (texte existant, raison masquée si
  `inconnu` ou `sans-citation`).
- pastille « tient le verrou » (§ 6.1) : pilule 999 px, mono 11 px/500, contour `rgba(var(--ink), .2)`, texte `--text-2`, après le nom
  (classe existante `.r-chip`).

**États : glyphe, mot, détail.** On reprend à l'identique les glyphes du lot 0 et du tiroir « Au travail » (un seul jeu de formes dans
tout le cockpit, aucune forme neuve). La couleur renforce, elle ne porte jamais seule (forme + mot).

| État | Glyphe (nom dans `GLYPHE`) | Teinte | Mot de « Quoi » | Détail (ligne 2 de « Quoi ») | Durée (préfixe, valeur) |
|---|---|---|---|---|---|
| Vous attend | anneau et point d'interrogation (`attend`) | `--st-recette` (= `--st-active`) (C-01) | « vous attend », ou « attend une réponse », « attend une permission » si la source le dit | impact (§ 4.1) | « attend depuis », durée de l'attente |
| Au travail | disque plein qui respire (`actif`) | `--st-active` | verbe + cible de la dernière action (jamais « lance une commande » seul) ; à défaut « au travail » | « commande en cours depuis 7 min » / « outil en cours depuis 7 min » quand un appel d'outil est sans résultat | « depuis », tenue de l'agent |
| Silencieux | cadran (`surveiller`) | `--text-2` | « silencieux depuis 4 min » | seuil : 2 min sans écriture, sans appel d'outil en cours (C-02) | « écrit il y a », âge de la dernière écriture |
| Suspect | cadran (`surveiller`) | `--text` | « suspect : aucun signe de vie depuis 18 min », en 600 | seuil : 15 min (C-02) ; au-delà de 30 min l'agent n'est plus dit vivant (règle existante) | idem |
| Commande longue | cadran (`surveiller`) | `--text` | « commande longue : 22 min », en 600 | appel d'outil sans résultat depuis 15 min ou plus (seuil existant) | « depuis » |
| Attend ses agents | anneau et deux barres de pause (`attente`) | `--text-2` | « attend ses agents » | « 3 en cours » (enfants vivants) quand connu | « depuis » |
| Au repos | anneau et tiret (`repos`) | `--text-2` | « au repos » | arbre d'origine si autre que le principal | « au repos depuis » |
| Orphelin | anneau en pointillés (`orphelin`) | `--text-2` | « orphelin » en 600 | « son parent est terminé, cet agent travaille encore » | « depuis » |
| Terminé, à relire | coche (`termine`) | `--st-done` | « rapport rendu » | « il y a 3 min » | « a duré », tenue |

- Un état se lit sans la couleur : formes toutes distinctes (le cadran sert aux trois degrés de silence, qui se distinguent par le mot
  et par l'épaisseur du mot, jamais par une teinte d'alerte : Q9, C-03).
- **Respiration** du glyphe « au travail » : exactement celle du tiroir (échelle 1 à .82 en 2,4 s, `aw-pulse`), coupée en mouvement
  réduit. Aucun autre glyphe ne bouge.
- **Contexte** (colonne droite, optionnelle, C-04) : `.vf-bar` (6 px, piste `--raise-2`, remplissage `--text-3`, neutre) puis le
  pourcentage (11,5 px mono, `--text-3`) ; à 85 % ou plus le pourcentage passe en `--text` 600 et le lecteur d'écran entend « contexte
  presque plein ». La barre ne se teinte pas (la barre d'un élément en cours est le seul cas de `--warn-text`, et le contexte n'en est
  pas un). Le champ absent de la collecte : rien n'est dessiné, ni tiret ni espace réservé.
- **Orphelin** : la ligne est rendue à la racine du « Au travail » (indentation zéro) même si son parent terminé apparaît ailleurs ;
  jamais sous le bloc des terminés (AUDC-D4).
- **Arbre** (section « Au travail » seule) : un enfant sous son parent, indenté de `--sp-16` par niveau, plafonné à deux niveaux
  (au-delà, même retrait) ; un fil de 1 px (`--fil`, `rgba(var(--ink), .2)`) relie les glyphes avec un coude de rayon 8, comme le
  tiroir (mêmes règles `.r-kids`). Un parent qui a des enfants porte un bouton caret 44 × 44 (`aria-expanded`, `aria-controls`,
  `aria-label` « Sous-agents, 3 »), ouvert par défaut. Un agent qui attend figure dans « À vous » **et** à sa place dans l'arbre ; la
  ligne de l'arbre ne répète pas l'impact (« vous attend · depuis 14 min »).

## 4. Les quatre sections

### 4.1 À vous

Ce qui attend une décision humaine, **classé par impact** (AUDC-I02). L'aide à droite du titre : « classé par ce que chaque attente
retient dans le plan ».

**Entrées** (même grammaire de ligne) :
1. agents et sessions à l'état « vous attend » (source : état officiel, lot 0 D2) ;
2. arbitrages en attente reliés à leur phase (idée 9 du ROADMAP) : « identifiant d'arbitrage · titre » en nom, « arbitrage en attente »
   en mot, phase reliée en ligne 2 (lien vers Projet) ; glyphe `attend`. Source et mesure à confirmer au cadrage (C-05) ; sans source,
   cette entrée n'existe pas et la section ne montre que les agents.

**Impact** = nombre de nœuds du plan **retenus en aval** : les nœuds descendants (transitivement, par leurs `deps`) du nœud auquel
l'agent est rattaché, dont l'état n'est pas `done`, le nœud lui-même exclu. Texte (« Quoi », ligne 2, en `--text-2`) :
- tous les nœuds restants du DAG sont en aval : « retient toute la mission » ;
- N > 1 : « retient N nœuds en aval » ; N = 1 : « retient 1 nœud en aval · <étape du nœud> » (étape bornée, masquée) ;
- 0 : « ne retient aucun nœud » ;
- non rattaché, DAG illisible, ou arbitrage sans nœud : « impact non mesuré ».
- une session qui détient le verrou de driver et attend est classée comme « retient toute la mission » (C-06).

**Ordre de tri** (total, stable) : 1. impact décroissant, « non mesuré » en dernier ; 2. attente la plus ancienne d'abord (`ageS`
décroissant) ; 3. agents avant arbitrages ; 4. nom (ordre alphabétique français), puis identifiant. À chaque poussée le tri est
recalculé, mais deux lignes à égalité parfaite ne s'échangent jamais (le dernier critère est l'identifiant).

**Droite** : aucun bouton (« Répondre » est hors périmètre). La ligne s'ouvre (§ 7) ; le lien « Nœud … » mène à Projet (§ 8).
**Densité** : toutes les entrées sont montrées (pas de repli : c'est la file qu'on vide). Au-delà de 12 : la liste défile avec la page.
**Vide** : « Rien n'attend votre décision. » (12,5 px, `--text-3`, `padding: var(--sp-12)`), sans glyphe ni coche.

### 4.2 Au travail

L'arbre : session, managers, workers, indenté (§ 3). Contient les états au travail, silencieux, suspect, commande longue, attend ses
agents, vous attend (à sa place), orphelin.
- **Racines** : une session par racine (plus un orphelin à la racine). Ordre : nom alphabétique puis identifiant (stable ; on ne trie
  jamais les racines par âge, qui changerait à chaque poussée). **Enfants** : tenue décroissante (règle existante).
- **Densité** : tout est montré (les agents vivants, à dix près). Un parent se replie par son caret.
- **Vide** : « Personne ne travaille en ce moment. »
- Le verrou et le veilleur s'y posent comme en § 6.

### 4.3 Terminé, à relire

Les sous-agents terminés (fenêtre de 24 h existante) dont le rapport n'a pas été ouvert **sur ce navigateur** (C-07). Remplace la
carte « Terminés depuis moins de 24 h ».
- **Ligne** : glyphe coche ; nom (une fois) ; ligne 2 : nœud ; « Quoi » : « rapport rendu » / « il y a 3 min » ; durée « a duré 29 min » ;
  droite : **« Lire le rapport »** (le bouton unique, § 7).
- **Tri** : le plus récemment terminé d'abord. **Densité** : 8 lignes, puis « Les N autres » (« Un autre » au singulier), bouton-lien
  existant `.r-more` qui déplie en place.
- **« Lire le rapport »** ouvre le détail de ligne (§ 7) sur le **dernier message de l'agent** (son rapport), puis, repliés, le fil
  complet existant. La ligne passe alors dans le repli « Relus ou sans rapport » (aucun mouvement animé).
- **Repli « Relus ou sans rapport · N »** en pied de section (`details`, replié) : agents dont le rapport a été ouvert, et sessions
  closes (une session n'a pas de rapport). Mêmes lignes, sans bouton.
- **« Tout marquer comme relu »** : même style de bouton, aligné à droite du titre de la section, visible quand 3 lignes ou plus sont à
  relire ; vide la liste vers le repli, sans lire rien (C-08).
- **Vide** : « Aucun rapport à relire. »

### 4.4 Au repos

Les sessions vivantes sans activité, **autres arbres compris** (elles ne disparaissent plus après 3 min).
- **Ligne** : glyphe repos ; nom ; ligne 2 : arbre (« autre arbre : phase-73-b ») ; « Quoi » : « au repos » ; durée « au repos depuis 45 min » ;
  droite : contexte si connu.
- **Tri** : activité la plus récente d'abord. **Densité** : 6 lignes puis « Les N autres ».
- **Vide** : « Aucune session au repos. »

### 4.5 États de la page

| État | Rendu |
|---|---|
| Premier `who` pas encore reçu | `aria-busy="true"` sur le conteneur, texte « Lecture de l'équipe » (`--text-3`) au-delà de 150 ms, aucune ligne fantôme animée |
| Aucun agent dans la fenêtre de 24 h | une seule boîte neutre (`--note-bg`, `--r-ctl`, `--inset-box`) : « Aucun agent dans les dernières 24 h. » puis « Les sessions de ce dépôt apparaîtront ici dès qu'elles écrivent. » ; les quatre titres restent, vides |
| Page exportée ou ouverte en fichier (pas de direct) | boîte neutre : « Le direct n'est pas branché. » puis « Ouvrez le cockpit depuis le projet pour voir l'équipe. » |
| Source illisible | pied de page, 12 px `--text-4` : « Source illisible : Sessions et sous-agents » (texte existant, rien quand tout est lu) |
| Direct coupé | une ligne sous le sous-titre : « Direct coupé : durées figées, données d'il y a 2 min » ; les durées cessent d'avancer (elles n'ajoutent plus le temps écoulé depuis la dernière poussée : elles ne mentent pas) ; la ligne disparaît d'elle-même au retour (même source que la bannière AUDC-M9) |
| Recherche active | le champ existant filtre les lignes (nom, rôle, tâche) ; sections vides masquées pendant le filtre ; aucun résultat : « Aucun agent ne correspond. » ; choisir un résultat place le focus sur la ligne et la déplie |

## 5. Mise à jour en direct

- Les lignes se mettent à jour **en place** à chaque `who` (clé = identifiant d'agent), **sans rechargement de page** (le
  `recharger()` à 15 s disparaît). Les durées avancent toutes les 30 s (cadence existante, aucun dessin si le texte est identique).
- Un redessin conserve : le défilement, les lignes ouvertes, les replis, **le focus** (retrouvé par identifiant ; si la ligne a changé de
  section il la suit ; si elle a disparu, il va au titre de sa section). Aucun focus volé à qui est parti ailleurs (règle `rendreFocus`).
- Région `aria-live="polite"` unique (hors écran), annonces : « 2 vous attendent » quand le compte d'« À vous » augmente, une fois par
  rafale ; jamais à chaque poussée ; jamais à la baisse.

## 6. Verrou, arbres de travail, veilleur (le but du ROADMAP)

### 6.1 Tenant du verrou

- **Ligne de verrou** sous le sous-titre (reprend `driverLigne`) : `Session qui pilote : <nom> · <étape>` + `tenu depuis 12 min`
  (la date de prise, `lease_seconds`, règle PU-G-179) ; sans verrou : « Personne n'a la main ». 12 px, `--text-3`, un petit disque de
  6 px `--st-active` devant seulement quand le verrou est tenu.
- Plusieurs verrous (dépôt, compartiments) : le premier est dit, puis un bouton-lien « 2 autres verrous » (`aria-expanded`) déplie la liste
  existante (portée, détenteur, « tenu depuis », « aucune session active » quand `session_ids` ne nomme aucune session de la collecte).
  L'aide existante est reprise : « Un verrou évite que deux sessions modifient la même chose en même temps : rien à faire de votre côté. »
- **Sur la ligne** de la session qui détient le verrou : la pastille « tient le verrou » (§ 3).

### 6.2 Arbres de travail et travail non commité

Un bloc **replié** en pied de page : `details` « Arbres de travail », compteur « 3, dont 1 avec du travail non commité » (la partie
« dont » n'existe qu'une fois les états lus). Il **lit les routes de la Phase 78** (`/api/vf/git/worktrees`, à la demande, jamais dans le
filet de 5 s) : aucune lecture git nouvelle (C-09).
- Chargement : à la première ouverture du bloc, puis à chaque signature git poussée par le flux et au retour de visibilité de l'onglet ;
  pas plus d'une lecture par minute sinon. Chargement : « Lecture du dépôt » (texte du tiroir Git).
- **Ligne d'arbre** (même gabarit que le tiroir Git, § 3 de `78-UI-SPEC.md`) : nom du dossier (mono 12,5 px/500), pilule « ici » pour l'arbre
  courant, branche (mono 11,5 px `--text-3`), puis pastilles d'état en texte neutre : « 3 modifiés », « 2 non suivis », « ↑2 ↓1 », « propre ».
  **Neutres** : le tiroir Git les pose sur `--warn-bg` ; ici la règle « pas de fond teinté » (Q9) l'emporte, les mots portent l'état
  sur `--text-2` (C-10). Jamais de commande de copie dans ce bloc (le tiroir Git les porte) : un lien « Ouvrir l'historique Git (g) » en pied.
- **Rattachement aux agents** : une fois les états lus, une ligne d'agent (session ou sous-agent) dont l'arbre a du travail non commité
  porte, en ligne 2 de « Qui », « 3 modifiés » à la suite de l'arbre. Sans lecture faite, rien (pas de chargement forcé).
- Vide : « Un seul arbre de travail. » ; erreur ou délai dépassé : « Git est indisponible » (texte du tiroir) avec le bouton de ligne
  « Réessayer ». Dépôt non git : le bloc n'existe pas.

### 6.3 Alerte du veilleur sur le nœud

Le watchdog (consultatif) pose son verdict sur le **nœud de mission concerné**. Rendu : sur toute ligne dont le nœud tourne dans la
mission en alerte, ligne 2 de « Quoi » : **« Veilleur : sans progrès depuis 27 min »** (verdict de blocage), ou **« Veilleur : verrou
abandonné »** (verdict d'abandon). Glyphe `surveiller` devant le mot, `--text-2`, mot en 600 ; **ni couleur d'alerte ni fond** (Q9). Il ne
change ni l'état de l'agent ni sa section : un veilleur consultatif ne reclasse rien. Sans agent sur le nœud, l'alerte est dite sur la
ligne de verrou (§ 6.1) : « Veilleur : sans progrès depuis 27 min ». La phrase ajoute « à vérifier » en infobulle seulement. Le seuil et
le verdict viennent de la sortie du watchdog : la page n'en recalcule aucun (C-11).

## 7. Détail de ligne et bouton unique

Cliquer sur le nom d'une ligne (ou Entrée, Espace) **déplie sous la ligne**, dans la colonne, un bloc de détail (pas de panneau voisin,
pas de décalage de la liste : Q12 ; un seul détail ouvert par section). Il remplace le panneau d'item du canevas, en attendant la fiche
d'agent de la Phase 74 (§ 9).

- Bloc `--raise`, `--r-ctl`, `padding: var(--inset-box)`, `gap: var(--sp-8)`, texte 12 px `--text-2` ; que du texte et des boutons de ligne.
- Contenu : identifiant court (mono) ; branche et arbre ; lien « Nœud … » (§ 8) ; **« Voir la dernière commande »** et **« Lire le
  transcript »**, les deux lectures à la demande **existantes**, inchangées dans leur borne (verbe et cible réduite, jamais un argument ;
  transcript sans sortie d'outil, jamais exporté, texte seulement, réponse gardée en mémoire de page) ; pour un terminé :
  **« Lire le rapport »** (le dernier message de l'agent d'abord, § 4.3).
- **Un seul style de bouton** (AUDC-F2), le « bouton de ligne » : fond transparent, `1px solid rgba(var(--ink), .15)`, rayon 8, 12 px/500 `--text-2`,
  `padding: var(--sp-4) var(--sp-12)`, hauteur 28 px (44 px en `pointer: coarse`), survol `rgba(var(--ink), .07)` + `--text`, focus
  `outline: 2px solid var(--ring)` à 2 px. C'est le style des boutons « Voir la dernière commande » et « Lire le transcript » d'aujourd'hui,
  étendu. Aucun bouton plein `--on` sur cet onglet. Les navigations sont des liens soulignés (`a.vf-link`), pas des boutons.
- Boutons : jamais `disabled` (un bouton désactivé perd le focus) : `aria-disabled` + `aria-busy` pendant la lecture, libellé
  « Lecture du transcript… » (texte existant).
- Entrée sur ces boutons : l'évènement ne remonte pas au raccourci « ouvrir le nœud sélectionné » (garde existante `UIFN-12`).

## 8. Liens entre les trois graphes (AUDC-I21)

Qui lance qui (l'arbre), quel nœud chacun porte (lien « Nœud plan-73 » vers `project.html#r=f:<dag>#<nœud>`, déjà produit par
`versNoeud`), quelle phase avance (depuis Projet, le lien retour « Voir dans l'onglet Équipe » existe : il doit viser la **ligne** de la
régie, `equipe.html#r=n:<carte>` conservé, et déplier la ligne). Aucune couleur par nœud (Graphite : le nœud s'écrit, la couleur reste
aux états). Un lien jamais deviné : seul un rattachement établi donne un lien.

## 9. Points d'accroche de la Phase 74 (nommés, non dessinés)

| Accroche | Où | Contrat |
|---|---|---|
| `vf-equipe-vues` | à droite du sous-titre, même ligne | emplacement vide et masqué ; la Phase 74 y pose un sélecteur « Régie · Frise » (même modèle que `.vf-tabs`). La régie est la vue par défaut et reste la vue au rechargement. |
| `vf-equipe-temps` | région `<section hidden>` frère des quatre sections, après « Au repos » | emplacement de l'axe du temps ; seule la Phase 74 le remplit et le montre ; la régie n'y dessine rien, ni titre ni texte |
| `vf-equipe-fiche` | évènement `vf-equipe:ouvrir` `{ id, vue: 'fiche' }` émis par le bouton nom d'une ligne **si** `window.__vfEquipeRegie.fiche` est enregistré | sinon le détail de ligne (§ 7) s'ouvre ; la fiche (tiroir latéral, ne pousse jamais la liste : Q12) remplace alors le détail |
| `vf-equipe-lecteur` | même évènement, `vue: 'lecteur'`, émis par « Lire le transcript » et « Lire le rapport » si `window.__vfEquipeRegie.lecteur` est enregistré | sinon lecture en ligne (§ 7) |
| contrat de lignes | chaque ligne porte `data-vf-agent` (identifiant), `data-vf-noeud` (si rattaché), `data-vf-etat` (la clé de glyphe : `attend`, `actif`, `surveiller`, `attente`, `repos`, `orphelin`, `termine`) | la frise y lit les mêmes clés d'état (une forme, un mot, partout) |
| registre | `window.__vfEquipeRegie = { lignes(), ouvrir(id), accroche(nom, fn) }` | lecture seule des lignes affichées ; aucune écriture hors de la page |

## 10. Notifications (AUDC-I09) et « ailleurs sur ce poste » (AUDC-I10)

**Notification : ça tient dans la DA, avec trois bornes.** Un seul motif de signal : « quelqu'un vous attend » (la fin d'un agent est le cas
courant et n'attend pas ; l'échec n'a pas de source propre dans la collecte : C-12).
- **Titre de l'onglet du navigateur**, sur les trois onglets du cockpit : `(2) vous attendent · Équipe · nom` ; singulier `(1) vous attend · …` ;
  à zéro, le format existant « <Onglet> · <nom> » (lot 0 X7). Les mots viennent avant le reste pour survivre à la troncature du titre.
  Le compte est celui d'« À vous » de **ce** lab (jamais « ailleurs »).
- **Compteur sur l'onglet « Équipe »** de l'en-tête : une pilule de compte (`2`, 11 px/500, `--text-2` sur `rgba(var(--ink), .1)`, pilule
  `--inset-pill`) quand « À vous » n'est pas vide ; `aria-label` de l'onglet complété « 2 vous attendent ». Neutre, sans teinte ni point orange.
- **Pastille sur l'icône** (favicon) : un point plein de la couleur du texte du thème, sans chiffre, sans teinte ; calculée localement (aucun
  appel réseau). Optionnelle : si le favicon n'est pas modifiable sans CDN ni ressource externe, on la retire, le titre porte le signal (C-13).
- **Notification du système : non retenue** par cette spec. Elle exige une permission du navigateur (un geste que la DA ne couvre pas) et
  sort du cockpit ; si Samuel la veut, c'est un choix à part, jamais activé sans geste.

**« Ailleurs sur ce poste » : ça tient.** Une ligne de texte neutre (12 px, `--text-3`, pas un encart, pas de lien) en pied de page :
« Ailleurs sur ce poste : 1 session vous attend, dans le lab « atelier ». » ; pluriel « 2 sessions vous attendent (labs « atelier », « notes ») » ;
au-delà de 3 labs, trois noms puis « et 2 autres ». **Nombre et nom du lab seulement** : ni titre de session, ni chemin, ni transcript, ni
agent ; le nom du lab est le nom de son dossier, borné à 40 caractères et masqué. Sans source (liste officielle absente ou illisible), la
ligne n'existe pas, rien d'inventé. Elle n'entre pas dans le compte du titre, ni dans l'export, ni dans le flux envoyé à d'autres pages.

## 11. Responsive (points de rupture inchangés : 700, 999, 1 279 en tactile)

- **≥ 1 000 px** : cinq colonnes (§ 3).
- **701 à 999 px** (et tactile < 1 280 px) : la colonne « Droite » passe sous « Quoi » ; la durée reste à droite de « Qui » ; trois colonnes
  (glyphe, qui, durée), « Quoi » sur deux lignes sous « Qui ». Le bouton « Lire le rapport » s'aligne à gauche sous le détail.
- **≤ 700 px** : une colonne ; glyphe + nom, puis quoi, puis durée et action ; indentation de l'arbre limitée à un niveau (`--sp-16`) ; boutons
  44 px ; aucune échelle de zoom, aucun défilement horizontal vérifié à 375, 700, 768 et 1 000 px.
- Le bouton « N au travail » de l'en-tête (réduit à son point, P70-D-22) **mène à la section « Au travail »** sur cet onglet (focus sur son
  titre) et n'ouvre plus le tiroir latéral, qui ferait doublon (C-14). Sur Code et Projet : inchangé.
- Un tiroir latéral (Git) ne pousse jamais la liste (Q12) : il se pose au-dessus ; `body.vf-git-ouvert` masque le bloc de titre comme il
  masque `#context` aujourd'hui.

## 12. Accessibilité

- **Structure** : `main` (1), `h1` (titre), `h2` par section, `ul`/`li` par liste ; l'arbre en `ul` imbriquées. Pas de `role="grid"` : la
  régie est une liste de lignes, pas un tableau de cellules.
- **Nom accessible d'une ligne** (bouton d'ouverture) : « état, nom, détail, durée », composé une fois : « vous attend, vf-dev-manager Phase 73,
  retient 4 nœuds en aval, attend depuis 14 minutes ». Le glyphe est `aria-hidden` ; l'état est dans le texte (`sr-only` si le mot visible
  n'est pas l'état, par ex. un verbe d'action).
- **Clavier** : Tab atteint, dans l'ordre visuel, par ligne : bouton d'ouverture, caret éventuel, lien « Nœud », bouton « Lire le rapport ».
  ↑ et ↓ sur un bouton d'ouverture déplacent vers le précédent ou le suivant (toutes sections confondues), Début et Fin vers le premier et
  le dernier ; Entrée et Espace déplient ; Échap replie le détail et rend le focus à son bouton d'ouverture. Pas de piège à focus (aucune
  modale). Le focus visible : `outline: 2px solid var(--ring)`, `outline-offset: -2px` dans les surfaces, `2px` ailleurs.
- **Touches** : aucune lettre nouvelle (`g` reste le tiroir Git, `/` la recherche) ; le raccourci d'onglet existant inchangé.
- **Contraste** : texte ≥ 4,5:1 dans les deux thèmes (`--text-3` sur `--surface` : 7:1 sombre, 6,4:1 clair) ; `--text-4` réservé à du texte
  non essentiel (pied « Source illisible ») ; glyphes ≥ 3:1 sur `--surface` ; en clair le glyphe `--st-active` fait 3,01:1 (écart connu,
  M5/m5 : le mot et la forme portent l'état).
- **Cibles** : lignes ≥ 44 px, carets et boutons 44 px en tactile ; en bureau, bouton de ligne 28 px (hauteur de contrôle du DESIGN).
- **Mouvement réduit** : la respiration coupée ; aucune autre animation. **Lecteur d'écran** : `aria-live="polite"` (§ 5), `aria-busy` au
  chargement, titre de page à jour (§ 10), `aria-expanded` sur ouvertures, carets et replis, `aria-labelledby` sur les boutons (le nom n'est
  jamais dupliqué en texte).

## 13. Données requises (contrat demandé à la collecte)

| Besoin | Champ | État |
|---|---|---|
| États, orphelin, outil en cours, action, tenue, âge, rattachement | `etat`, `orphan`, `enCours`, `action`, `dureeS`, `ageS`, `rattachement` | déjà dans `who` (lot 0) |
| Verrous, détenteur | flux `lock` (`owner`, `step`, `lease_seconds`, `session_ids`) | déjà dans le flux |
| Impact en aval | `retient` : `{ noeuds, toute, libelle }` par agent rattaché, calculé à la collecte depuis les `deps` et `status` du DAG (lus par `lireDags`) | **à produire** (valeurs bornées et masquées) |
| Nature de l'attente | `attente` : `reponse` ou `permission` ou absent | **à produire**, depuis l'état officiel s'il le porte ; sinon absent et le mot reste « vous attend » |
| Contexte | `contexteP` (0 à 100), absent si inconnu | **à produire** (C-04) |
| Modèle | `modele` (chaîne bornée) | à produire si la collecte le lit déjà ; sinon la ligne 2 s'en passe |
| Verdict du veilleur | `veilleur` : `{ verdict: 'blocage' \| 'abandon', ageS }` rattaché au nœud en alerte | **à produire**, lu de la sortie du watchdog sans recalcul |
| Sessions d'autres labs | `ailleurs` : `[{ lab, n }]` | **à produire** si la liste officielle le permet (C-15) |
| Arbres de travail | `/api/vf/git/worktrees` | existe (Phase 78) |
| Dernier message de l'agent (rapport) | dernier élément `genre: message` du `fil` de `/api/vf/transcript` | existe (schéma `cockpit-transcript@2`) |
| Lu / non lu | liste d'identifiants dans `localStorage` (`vf-equipe-lus`), 200 au plus, purgée des identifiants sortis de la fenêtre de 24 h ; jamais exportée | côté page (C-07) |

Bornes inchangées : traces locales, aucun appel réseau sortant, lecture seule sur `.planning/`, dernière commande jamais dans le flux,
le fichier ni l'export, verbe et cible réduite sans argument, transcript sans sortie d'outil et jamais exporté, rien sans `--terminal`.

## 14. Libellés neufs et dictionnaire

Tout est écrit en français dans les fichiers de la régie (le dictionnaire du module, `78-vf-fr-dict-a.js` / `79-vf-fr-dict-b.js`, ne traduit
que des chaînes **anglaises du moteur** : aucune entrée n'y est nécessaire). À faire : étendre le test de chrome français pour que
ces libellés soient absents de la liste des chaînes anglaises, et vérifier qu'aucune chaîne du moteur n'apparaît non traduite sur l'onglet.

| Emplacement | Libellé exact |
|---|---|
| Sous-titre | `N agents · P vous attendent · Q à relire` ; « 1 agent », « 1 vous attend », « 1 à relire », « Aucun agent en vie » |
| Sections | « À vous », « Au travail », « Terminé, à relire », « Au repos » ; aide : « classé par ce que chaque attente retient dans le plan » |
| Vides | « Rien n'attend votre décision. » · « Personne ne travaille en ce moment. » (existant) · « Aucun rapport à relire. » · « Aucune session au repos. » |
| Page | « Aucun agent dans les dernières 24 h. » · « Les sessions de ce dépôt apparaîtront ici dès qu'elles écrivent. » · « Le direct n'est pas branché. » · « Ouvrez le cockpit depuis le projet pour voir l'équipe. » · « Lecture de l'équipe » · « Direct coupé : durées figées, données d'il y a 2 min » · « Aucun agent ne correspond. » |
| États (Quoi) | « vous attend » · « attend une réponse » · « attend une permission » · « au travail » · « commande en cours depuis 7 min » · « outil en cours depuis 7 min » · « silencieux depuis 4 min » · « suspect : aucun signe de vie depuis 18 min » · « commande longue : 22 min » · « attend ses agents » · « 3 en cours » · « au repos » · « orphelin » · « son parent est terminé, cet agent travaille encore » · « rapport rendu » · « il y a 3 min » |
| Impact | « retient toute la mission » · « retient N nœuds en aval » · « retient 1 nœud en aval » · « ne retient aucun nœud » · « impact non mesuré » · « arbitrage en attente » |
| Durées (préfixes) | « attend depuis » · « depuis » · « a duré » · « écrit il y a » · « au repos depuis » |
| Verrou | « tient le verrou » · « 2 autres verrous » (« 1 autre verrou ») ; reprises : « Session qui pilote : », « tenu depuis », « Personne n'a la main », « aucune session active » |
| Veilleur | « Veilleur : sans progrès depuis 27 min » · « Veilleur : verrou abandonné » · infobulle « à vérifier » |
| Arbres | « Arbres de travail » · « 3, dont 1 avec du travail non commité » · « Un seul arbre de travail. » · « Ouvrir l'historique Git (g) » ; reprises : « 3 modifiés », « 2 non suivis », « propre », « ici », « Lecture du dépôt », « Git est indisponible », « Réessayer » |
| Boutons de ligne | « Lire le rapport » · « Tout marquer comme relu » · reprises : « Voir la dernière commande », « Lire le transcript », « Lecture du transcript… » |
| Replis | « Relus ou sans rapport · N » · « Les N autres » · « Un autre » (existants) |
| Notifications | titre `(2) vous attendent · Équipe · nom` / `(1) vous attend · …` · `aria-label` « 2 vous attendent » · annonce « 2 vous attendent » |
| Ailleurs | « Ailleurs sur ce poste : 1 session vous attend, dans le lab « nom ». » · « Ailleurs sur ce poste : 2 sessions vous attendent (labs « a », « b »). » · « et 2 autres » |

## 15. Variables et espacements (tous existants)

Couleurs et ombres : `--surface`, `--surface-hover`, `--raise`, `--raise-2`, `--hair`, `--ink`, `--text`, `--text-2`, `--text-3`, `--text-4`,
`--st-active`, `--st-recette`, `--st-done`, `--note-bg`, `--ring`, `--fil` (posé par `.vf-whop`, à reprendre sur le conteneur de la régie),
`--shadow-card`. Rayons : `--r-card`, `--r-ctl`, 8 (bouton), 999 (pilule). Police : `--sans`, `--mono`. Courbe : `--ease`.
Aucune variable créée. Jamais `--text-1`.

Espacements autorisés (grille fermée 2, 4, 6, 8, 12, 16, 20, 24, 32) : `--edge` (bord de fenêtre), `--gap-section` 24 (entre sections),
`--inset-row` 8 × 12 (lignes), `--inset-box` 12 (détail de ligne, boîtes), `--inset-pill` 2 × 8 (pilules), `--sp-4`, `--sp-8`, `--sp-12`,
`--sp-16`. Tailles de contrôle : 16 (glyphe), 28 (bouton de ligne bureau), 44 (tactile, caret, ligne), 96 et 152 (colonnes, dimensions).
Rien d'autre ; aucune valeur en dur de couleur, d'ombre ni d'espacement.

## 16. Ce que le juge de design doit vérifier

1. Aucune valeur de couleur, d'espacement, de rayon en dur ; deux thèmes ; `--text-1` absent ; aucun fond teinté, liseré, anneau ou halo
   coloré ; aucun dégradé ; aucun kicker en capitales.
2. Ordre et contenu : quatre sections dans l'ordre fixe, « À vous » en tête avec titre 18 px ; tri par impact conforme à § 4.1 (jeu d'essai :
   impact 4, impact 1, non mesuré, égalité d'impact départagée par l'ancienneté de l'attente).
3. Le nom d'un agent n'est écrit qu'**une fois** par ligne (ni `title`, ni sous-titre, ni bouton) ; aucune carte « Terminés depuis moins de
   24 h » ; aucun bloc Santé ; aucun terminal ni barre de question ; aucune action d'arrêt, de réponse ni de recette.
4. Un seul style de bouton (« bouton de ligne ») : « Lire le rapport », « Tout marquer comme relu », « Voir la dernière commande », « Lire le
   transcript », « Réessayer » ont le même rendu ; aucun bouton plein.
5. Chaque état se lit sans la couleur (forme + mot) ; suspect et commande longue ne dépendent d'aucune teinte d'alerte.
6. Orphelin à la racine de « Au travail », jamais sous un bloc de terminés ; session au repos d'un autre arbre listée au-delà de 3 min.
7. Verrou : tenant nommé, « tenu depuis » = date de prise ; plusieurs verrous dépliables ; pastille sur la ligne du détenteur. Arbres de
   travail : replié, lu à la demande, pastilles neutres. Veilleur : posé sur la ligne du nœud, sans couleur, ne reclasse rien.
8. Mise à jour sans rechargement : focus, défilement, détails ouverts conservés ; annonce `aria-live` unique ; direct coupé : durées figées
   et ligne dite.
9. Notifications : titre `(N) vous attendent · …` sur les trois onglets, compteur neutre sur l'onglet Équipe ; « ailleurs » = nombre et nom du
   lab seulement.
10. Responsive 375, 700, 768, 1 000 et 1 440 px, sans défilement horizontal ; tactile : cibles 44 px ; Q12 respecté (rien ne pousse la liste).
11. Clavier seul : parcours complet, ↑ ↓ entre lignes, Échap, retour du focus ; lecteur d'écran : noms composés une fois, états dits.
12. Anti-slop : monochrome, aucune police neuve, aucun tiret cadratin dans le copy, aucun emoji.

## 17. Questions au cadrage (choix faits faute de décision)

À confirmer ou corriger par le cadrage (`73-CONTEXT.md`) ; format `P73-D-NN`, « décision déléguée par Samuel (message session principale,
2026-11-08), option recommandée » si l'option recommandée est retenue.

- **C-01** Le glyphe « vous attend » prend `--st-recette` (jaune, comme « à recetter », qui est aussi une attente de l'humain). Le lot 0 l'avait
  posé en `--text-2`. DESIGNS § 2 dit jaune. À confirmer.
- **C-02** Seuils de décroissance : 2 min (silencieux), 15 min (suspect, et commande longue), 30 min (plus dit vivant), tous **déjà dans le code**
  (`CALME_S`, `LONGUE_S`, `SILENCE_MAX_S`) ; DESIGNS laissait 2 min et 15 min « à régler ». Une commande en cours reste « au travail » jusqu'à 15 min.
- **C-03** « Suspect » et « orphelin » en **neutre** (mot en 600), pas en corail : DESIGNS § 2 propose le corail, § 9 et Q9 l'interdisent.
  Les glyphes du lot 0 sont gardés (un seul jeu de formes avec le tiroir « Au travail ») ; ceux de la page de maquette (DESIGNS § 2) sont
  donc **abandonnés**, notamment la paire « attend / attend ses agents » (inversée par le lot 0).
- **C-04** Colonne « contexte » : n'existe que si la collecte fournit `contexteP` ; barre toujours neutre (pas de teinte à 86 %), pourcentage en `--text` 600
  dès 85 %. Seuil et champ à fixer (Phase 79 ou ce plan).
- **C-05** « À vous » accueille aussi les **arbitrages en attente** (idée 9, but du ROADMAP) ; source (`*-CONTEXT.md`, DAG) et mesure d'impact restent
  à fixer ; sans source, seuls les agents y figurent.
- **C-06** Une session détentrice du verrou qui attend est classée « retient toute la mission » (sans nœud rattaché, on ne peut pas mesurer).
- **C-07** « À relire » = agent terminé dont le rapport n'a pas été ouvert **dans ce navigateur** (`localStorage`, identifiants seulement,
  jamais exportés, bornés). Alternative écartée : un état serveur (écriture hors `.planning/`).
- **C-08** « Tout marquer comme relu » existe (un second bouton, même style) pour les missions à nombreux agents ; retirable sans casser la spec.
- **C-09** Les arbres de travail sont un bloc **replié** en pied de page, lu à la demande par la route de la Phase 78 (jamais relu côté git).
  Pas une cinquième section : ce ne sont pas des agents.
- **C-10** Les pastilles « modifiés / non suivis / propre » sont **neutres** ici (le tiroir Git les pose sur `--warn-bg`, en tension avec Q9) ;
  à harmoniser par un correctif du tiroir Git, hors de cette phase.
- **C-11** Le veilleur ne reclasse rien et s'écrit en texte neutre sur la ligne du nœud ; « sans progrès » et « verrou abandonné » reprennent ses deux
  verdicts. Le nom d'interface « veilleur » est neuf (le code dit « watchdog »).
- **C-12** Notification : un seul motif (« vous attend ») ; fin et échec ne changent ni le titre ni le compteur. Pas de notification du système.
- **C-13** Pastille de favicon optionnelle (point neutre), retirée si elle exige une ressource externe.
- **C-14** Sur Équipe, le bouton « N au travail » mène à la section « Au travail » et n'ouvre plus le tiroir latéral (doublon). Le fichier
  `73-vf-tiroir-travail.js` garde son rôle sur Code et Projet.
- **C-15** « Ailleurs sur ce poste » : nombre et nom du lab seulement, depuis la liste officielle des sessions ; sans cette source, pas de ligne.
  Les noms d'autres labs apparaissent dans la page locale : à confirmer (la page ne sort jamais du poste).
- **C-16** Compte du sous-titre : « N agents » = agents **en vie** ; la maquette de l'audit comptait aussi un terminé (« 6 agents » pour 5 en vie
  et 1 à relire). « Un agent qui attend figure deux fois » (À vous et l'arbre) : les compteurs de sections comptent les lignes, le sous-titre les agents distincts.
  À trancher aussi : l'export de la page sur Équipe (rien de la régie n'y entre) et la recherche (filtre de lignes, § 4.5).
