# Phase 73 : Gouvernance au cockpit, la régie — UI-SPEC (craft-regie)

**Contrat de design** de l'onglet Équipe devenu une **régie** : une liste par état, quatre sections, à la place du canevas.
Direction « Graphite » (`DESIGN.md`). Format et vocabulaire repris de `78-UI-SPEC.md`. **Cette spec se conforme à `73-CONTEXT.md`
(décisions P73-D-01 à D-28) ; en cas d'écart, le CONTEXT fait foi.**

Sources lues : `DESIGN.md` ; `DESIGNS.md` § 1 à 3 et § 9 ; maquette HTML de l'audit (lecture du code) ; `A4-interface-parcours.md` ;
`REGISTRE.md` (AUDC-I01, I02, I03, I09, I10, I21, I34, I38, D4, M3, F2) ; mission du lot 0 ; code actuel de l'onglet
(`ui/71-vf-equipe-rendu.js`, `ui/72-vf-equipe.js`, `ui/73-vf-tiroir-travail.js`, `ui/70-vf-live.js`) ; `73-CONTEXT.md`. Aucune brique externe de
craft consultée : dégradation sur les premiers principes (contraste WCAG, grille fermée de 8, hiérarchie). Aucun navigateur ouvert.

Règles de copy : texte d'interface en français ; espace insécable avant `: ; ! ?` et entre un nombre et son unité (« 7 min ») ;
aucun tiret cadratin dans le copy ; tout texte venu du disque en `textContent`, jamais en HTML. Classes neuves en `vf-rg-*`, dans des
fichiers `ui/*vf*` neufs, chacun ≤ 300 lignes (P73-D-26).

**Conformité en une ligne par décision de structure.** D-03 : l'enveloppe `cockpit-equipe@1` garde son schéma, `nodes` vide, la page n'y lit
rien. D-18 : la section Santé n'est ni calculée ni injectée sur Équipe. D-22 : le nettoyage d'affichage de la branche et du titre se fait
à l'émission, la régie reçoit des chaînes déjà nettoyées. D-24 : aucun fichier du moteur vendorisé (`viewer.html`…) n'est modifié, tout vit
dans des fichiers d'interface neufs. D-26 : les ajouts vont dans des fichiers neufs ; dans `00-vibeflow.js` et `70-vf-live.js`, une
ligne existante modifiée au plus.

## 1. Principe, périmètre, retraits

**La question de l'onglet** : « Qui m'attend, qui travaille, que s'est-il passé ? ». La régie répond aux deux premières et à ce qui est
fini ; « que s'est-il passé » (le temps) est la Phase 74.

**Livré par cet écran** : les quatre sections (AUDC-I01, I02) ; les états du lot 0 plus la décroissance « silencieux, suspect » (I03) et
« attend ses agents » (I38) ; le tenant du verrou et les marques de gouvernance posés sur la ligne de mission (§ 6) ; les arbres de
travail avec leur travail non commité (§ 6.2) ; « Lire le rapport » (I34) ; un titre d'onglet et une pastille de favicon (I09) ; une
ligne « ailleurs sur ce poste » (I10).

**Hors périmètre, à ne pas dessiner** : « Répondre », « Recetter », « Ouvrir », « Lui écrire », « Demander l'arrêt » (orphelin compris) :
AUDC-Q3 reportée, Phase 81. Pas de terminal (Q8), pas de barre de question (plan 69-05), pas de bloc Santé, pas de zoom, pas de notification
du système (reportée, P73-D-15). Le seul bouton d'étape suivante est « Lire le rapport ».

**Retraits (un ajout = un retrait)** : le canevas d'Équipe (cartes, zoom, ajustement, « Vue d'ensemble », bascule du panneau de détail,
rechargement de page sur changement de structure) ; le nom écrit trois fois ; la carte « Terminés depuis moins de 24 h », le bloc de
chiffres « actifs / en attente / terminés » et le pli homonyme du tiroir « Au travail » ; le panneau d'item et ses trois styles de bouton
(AUDC-F2) ; la section Santé encore calculée sur Équipe.

## 2. Gabarit de page

L'en-tête (marque, onglets, recherche, boutons) est inchangé, sans compteur ajouté sur l'onglet « Équipe ». Le canevas (`#stage`) n'est pas
affiché sur Équipe ; le contenu est un conteneur injecté en JS (P73-D-20).

```
+--------------------------------------------------------------------------+
| [logo] depot   [Code|Projet|Équipe]   [Recherche]                 [..]   |  en-tête 64 px
+--------------------------------------------------------------------------+
|  section#vf-equipe                                                       |
|   #vf-equipe-entete                                                      |
|    Mission : Phase 73, Gouvernance au cockpit              (h1)          |
|    5 agents · 2 vous attendent · 1 à relire    [ Régie | Frise ] (≥ 2 vues)|
|    Verrou du dépôt : <owner> · <étape> · depuis 12 min                   |
|   .vf-vue[data-vf-vue="regie"]                                           |
|    À vous  2    classé par ce que chaque attente retient dans le plan    |
|    +------------------------------------------------------------+       |
|    | ? | nom, ligne 2          | quoi, impact       | attend 14 min |    |
|    +------------------------------------------------------------+       |
|    Au travail  4   (lignes de mission, arbre indenté)                    |
|    Terminé, à relire  1                                                  |
|    Au repos  1                                                           |
|    > Arbres de travail (3)                                  (replié)     |
|    Ailleurs sur ce poste : 1 session vous attend, dans « atelier ».      |
+--------------------------------------------------------------------------+
```

- **Conteneur** : `max-width: 960px` (dimension, comme les 360 px du panneau), aligné à gauche, `padding-inline: var(--edge)`, haut
  `calc(var(--hh, 64px) + var(--gap-section))`, bas `var(--gap-section)`. Défilement de la page, jamais deux défilements imbriqués. Une
  seule région principale (`<main>` = `section#vf-equipe`, AUDC-m4).
- **Bloc de titre** (`#vf-equipe-entete`, en flux : il ne se superpose plus à rien, AUDC-M2). **Pas de surtitre** « Équipe » : l'onglet
  actif le dit déjà. `h1` 24 px/600, interlettrage `-.025em`, interligne 30 px, deux lignes au plus. Gabarit du lot 0 gardé : « Mission :
  <nom> », « N missions en cours », « N agents actifs », « Aucune mission en cours ». Sous-titre en **13,5 px** (corps), interligne 20 px,
  `--text-2`.
- **Sous-titre** : `N agents · P vous attendent · Q à relire`. `N` = agents distincts en vie (au travail, vous attend, attend ses agents,
  au repos, orphelin) ; `P` et `Q` disparaissent à zéro, sauf tout à zéro : « N agents ». Singuliers : « 1 agent », « 1 vous attend », « 1 à
  relire ». Aucun agent : « Aucun agent en vie ». Les compteurs de section, eux, comptent des lignes (P73-D-01).
- **Ligne du verrou de dépôt** sous le sous-titre (§ 6.1), seulement quand un verrou de portée dépôt est tenu.
- **Sections** : `<section aria-labelledby>`, `h2` + compteur en pilule `.meta` ; « À vous » ajoute son aide. Titres 15 px/600 `--text`,
  interligne 20 px, sauf « À vous » en 18 px/600 (interligne 24 px, `DESIGN.md` § 3) : la hiérarchie par la taille et la place, jamais par un
  fond (Q9), jamais en capitales. Écart entre sections `--gap-section` (24) ; titre / liste `--sp-8`.
- **Surface d'une section** : `--surface`, `--r-card`, `--shadow-card` (son unique élévation), `padding: var(--sp-8)` ; lignes séparées par
  un filet `1px solid var(--hair)` (aucun gap ni marge qui s'additionne). Aucun anneau, liseré, fond teinté ou halo coloré.
- **Sections toujours présentes, ordre fixe** : À vous, Au travail, Terminé à relire, Au repos. Section vide : son titre et une ligne d'état vide
  (§ 4). Seule exception : « À vous » vide dit « Rien ne vous attend. » sans autre décor.
- **Typographie de la régie** (une seule échelle, extraite de `DESIGN.md` § 3) : 24/30 (h1), 18/24 (« À vous »), 15/20 (titres de section),
  13,5/20 (sous-titre), 13/20 (nom, 500 ou 600), **12/16 (tout le courant dense : ligne 2, détail, durées, pieds, mono compris)**, 11/16
  (pastilles, compteurs). Plus de demi-pas 11,5.
- **Thèmes** : sombre et clair vérifiés. Les glyphes ne reposent que sur `--surface` (jamais sur `--raise`/`--raise-2` en clair) ; le détail
  de ligne (§ 7), en `--raise`, n'y pose que du texte `--*-text` et des boutons.
- **Aucune animation propre à la régie**, hors la respiration du glyphe « au travail » (§ 3), coupée en mouvement réduit.

## 3. Une ligne

Une ligne = un agent, ou une ligne de phase (§ 4.1). Cinq colonnes en grille CSS (≥ 1 000 px) :

| Colonne | Contenu | Largeur |
|---|---|---|
| Glyphe | forme d'état 16 px (`svg.aw-g` existant), `aria-hidden` | `16px` |
| Qui | ligne 1 : **le nom, écrit une fois** ; ligne 2 : nœud, arbre, branche, lancement | `minmax(0, 1.3fr)` |
| Quoi | ligne 1 : l'état en mots ; ligne 2 (discrète) : détail, impact, marque de gouvernance | `minmax(0, 1.2fr)` |
| Durée | un préfixe qui dit de quoi elle parle, puis la valeur | `auto`, `min-width: 96px` |
| Droite | l'unique bouton « Lire le rapport » (lignes terminées), sinon vide | `152px` |

`gap` de colonnes `var(--sp-12)` ; padding de ligne `--inset-row` (8 × 12) ; hauteur minimale 44 px ; survol `rgba(var(--ink), .05)`, rayon
`--r-ctl`. **Aucune colonne « contexte »** : aucune source n'émet un taux de remplissage (P73-D-27, Phase 74).

**Le nom, une fois.** Ligne 1 de « Qui » : agent = `rôle` (mono 12 px, `--text-2`) puis tâche (13 px/500 `--text`) ; session = titre (`custom-title`,
sinon « Session principale ») en 13 px/600 ; sessions de même titre distinguées par l'arbre puis l'identifiant court (règle `nommer`
existante). Le nom n'est écrit nulle part ailleurs sur la ligne : ni `title`, ni ligne 2, ni bouton ; le bouton « Lire le rapport » se nomme
par `aria-labelledby` vers l'élément du nom plus son propre libellé.
Ligne 2 de « Qui » (12 px `--text-3`, une ligne, ellipsis à droite) : lien `nœud plan-73` (mono, § 8) · `arbre phase-73-a` (seulement s'il diffère de
celui du parent ; une session montre arbre et branche) · **« Lancée depuis la carte : Phase 73 · fiabilite · exécuter »** (champ `lancee`
`{phase, ws, verbe}`, sessions seulement, revalidé à l'émission, P73-D-21) · « non lié à une phase du projet » (texte existant ; raison masquée
si `inconnu` ou `sans-citation`) · « 3 modifiés » quand l'arbre de la ligne a du travail non commité et que les états sont lus (§ 6.2).

**États : glyphe, mot, détail.** Glyphes du lot 0 et du tiroir « Au travail » **repris à l'identique** (un seul jeu de formes, aucune forme
neuve, P73-D-19). La couleur renforce, ne porte jamais seule (forme + mot).

| État | Glyphe (`GLYPHE`) | Teinte | Mot de « Quoi » | Détail (ligne 2) | Durée (préfixe, valeur) |
|---|---|---|---|---|---|
| Vous attend | anneau, point d'interrogation (`attend`) | `--text-2` | « vous attend » | impact (§ 4.1) | « attend depuis », durée de l'attente |
| Au travail | disque plein qui respire (`actif`) | `--st-active` | verbe + cible de la dernière action ; à défaut « au travail » | « commande en cours depuis 7 min » ou « outil en cours depuis 7 min » (appel d'outil sans résultat ; verbe seul, jamais la commande) | « depuis », tenue |
| Silencieux | cadran (`surveiller`) | `--text-2` | « silencieux depuis 4 min » | plus de 120 s sans écriture ni outil en cours (`CALME_S`) | « écrit il y a » |
| Suspect | cadran (`surveiller`) | `--text` | « suspect : aucun signe de vie depuis 18 min », en 600 | au-delà de la fenêtre de stall (§ 6.3, 900 s par défaut) ; inférieur à 1 800 s | « écrit il y a » |
| Commande longue | cadran (`surveiller`) | `--text` | « commande longue : 22 min », en 600 | appel d'outil sans résultat depuis 15 min ou plus (seuil existant) | « depuis » |
| Attend ses agents | anneau, deux barres de pause (`attente`) | `--text-2` | « attend ses agents (3) » | champ `attendAgents` > 0, **sessions seulement**, session non `actif`, dernière ligne du transcript = fin de tour ; `N` absent ou nul : l'état n'est pas dit | « depuis » |
| Au repos | anneau, tiret (`repos`) | `--text-2` | « au repos » | arbre d'origine s'il n'est pas le principal | « au repos depuis » |
| Orphelin | anneau en pointillés (`orphelin`) | `--text-2` | « orphelin » en 600 | « son parent est terminé, cet agent travaille encore » | « depuis » |
| Terminé, à relire | coche (`termine`) | `--st-done` | « rapport rendu » ; **« échec »** ou **« arrêté »** quand `finMotif` vaut `echec` ou `arret` (rien sinon) | « il y a 3 min » | « a duré » |

- Aucune couleur d'alerte (Q9) : suspect et commande longue se distinguent par le mot, son poids et la place, pas par une teinte.
- **Respiration** du glyphe « au travail » : celle du tiroir (échelle 1 à .82 en 2,4 s, `aw-pulse`), coupée en mouvement réduit.
- **Arbre** (section « Au travail ») : un enfant sous son parent, indenté de `--sp-16` par niveau, plafonné à deux niveaux ; fil de 1 px (`--fil`,
  `rgba(var(--ink), .2)`) avec coude de rayon 8 (règles `.r-kids` du tiroir). Un parent qui a des enfants porte un caret 44 × 44 (`aria-expanded`,
  `aria-controls`, `aria-label` « Sous-agents, 3 »), ouvert par défaut. Un agent qui attend figure dans « À vous » **et** à sa place dans
  l'arbre ; la ligne de l'arbre ne répète pas l'impact.
- **Orphelin** (reste d'AUDC-D4) : rendu **sous la ligne grisée de son parent terminé** (parent en `--text-3`, mot « terminé » ; la ligne du parent
  n'a ni bouton ni action), avec le mot « orphelin ». Aucune action (Q3, P68-D-03). Le garde du lot 0 qui nomme l'orphelin est réutilisé.

## 4. Les quatre sections

### 4.1 À vous

Ce qui attend une décision humaine, **classé par ce que l'attente retient en aval** (AUDC-I02). Aide : « classé par ce que chaque attente retient
dans le plan ».

**Deux sources seulement** (P73-D-06) :
1. les sessions à l'état officiel `attend` (lot 0) : ligne d'agent normale ;
2. les phases dont un `*-VERIFICATION.md` porte `status: human_needed` en en-tête : **ligne de phase**, nom « Phase 74 : vérification humaine
   demandée », ligne 2 = lien vers la carte de la phase dans Projet, glyphe `attend`, pas de durée, pas de bouton. Une ligne de session et une
   ligne de phase de la même phase restent deux lignes (P69-D-15).
Ne sont **pas** dans « À vous » : une question sans réponse lue au transcript (décision D2 du lot 0), les sections « À Samuel » en prose, « à
recetter », les orphelins et les suspects (aucune action n'existe, Q3).

**Impact** = nombre de nœuds **non terminés** atteignables en aval du nœud de l'attente dans un DAG de mission déjà découvert (fermeture
transitive inverse des `deps`, le nœud exclu). Le nœud d'une session vient du rattachement existant, jamais deviné (P69-D-15). Sources des
DAG : le résumé de plan publié par la Phase 79 et désigné par le champ `dag` de l'état des verrous, plus les DAG déjà découverts aujourd'hui.
Libellés (« Quoi », ligne 2, `--text-2`) :
- « retient N nœuds » (« retient 1 nœud » au singulier) ;
- « retient toute la mission · N nœuds » : session détentrice du verrou d'une mission, sans nœud rattaché, **seulement si le DAG de la mission
  est visible** (N = ses nœuds non terminés) ;
- « impact inconnu » : pas de nœud rattaché, pas de plan publié ou DAG illisible, ligne de phase.
**Limite à écrire dans l'interface** (infobulle sur « impact inconnu » et phrase de l'aide du pied de section) : l'impact compte des nœuds du plan,
pas leur durée ni leur importance ; sans plan visible, il n'est pas mesuré.

**Ordre de tri, trois rangs** : 1. impact connu > 0, décroissant ; 2. impact inconnu ; 3. impact connu = 0 (« retient 0 nœud » se dit « ne
retient rien »). Dans un rang : **la plus ancienne attente d'abord** (`ageS` décroissant), puis nom, puis identifiant (deux lignes à égalité ne
s'échangent jamais).
Plans qui lisent la forme projetée de la Phase 79 : marqués « à revalider » jusqu'à sa fusion, repli sur la forme présente (§ 13).

**Droite** : aucun bouton. **Densité** : tout est montré. **Vide** : « Rien ne vous attend. » (12 px `--text-3`, `padding: var(--sp-12)`).

### 4.2 Au travail

L'arbre session, manager, workers (§ 3), précédé, par mission dont un verrou est tenu, d'une **ligne de mission** (§ 6.1).
- **Racines** : une session par racine ; ordre alphabétique puis identifiant (stable ; jamais par âge). **Enfants** : tenue décroissante.
- **Densité** : tout est montré ; un parent se replie par son caret.
- **Pied** : « N muets depuis plus de 30 min, retirés » quand `sortisSilence` est présent et non nul (12 px `--text-3`) : la collecte les retire
  au-delà de 1 800 s, la régie le dit au lieu de les faire disparaître en silence.
- **Vide** : « Personne ne travaille en ce moment. »

### 4.3 Terminé, à relire

Les sous-agents terminés (fenêtre de 24 h) dont le rapport n'a pas été ouvert **dans ce navigateur**. Remplace la carte « Terminés depuis moins de 24 h ».
- **Ligne** : coche ; nom (une fois) ; ligne 2 : nœud ; « Quoi » : « rapport rendu », ou « échec » / « arrêté » (`finMotif`) ; détail « il y a 3 min » ;
  durée « a duré 29 min » ; droite : **« Lire le rapport »**. Tri : terminé le plus récemment d'abord. Densité : 8 lignes, puis « Les N
  autres » (« Un autre »).
- **« Lire le rapport »** émet `vf-agent:ouvrir` (§ 9). Sans `preventDefault`, la régie ouvre le lecteur actuel (§ 7) sur le dernier message de
  l'agent (son rapport), puis le fil complet existant, et marque la ligne lue. **Marqué à l'ouverture, jamais au survol** ; émet `vf-agent:lu {id}`.
- **Stockage « lu »** (P73-D-14) : `localStorage`, **une clé par lab**, identifiants et heure seulement (200 au plus), **purge des entrées de plus de 24 h
  au chargement**, jamais exporté. **Repli sans stockage** (refusé, plein, mode privé) : tout terminé de moins de 24 h est « à relire ». Aucune
  route d'écriture.
- **Repli « Relus ou sans rapport · N »** (`details`, replié) : agents lus et sessions closes (une session n'a pas de rapport). Sans bouton.
- **« Tout marquer comme relu »** : même bouton, à droite du titre, visible dès 3 lignes à relire ; ne lit rien.
- **Tiroir « Au travail »** (Code, Projet) : son pli « Terminés depuis moins de 24 h » devient le lien « 3 à relire dans Équipe », vers cette section.
- **Vide** : « Aucun rapport à relire. »

### 4.4 Au repos

Les sessions vivantes sans activité, autres arbres compris (elles ne disparaissent plus après 3 min). Ligne : glyphe repos ; nom ; ligne 2 : arbre
(« autre arbre : phase-73-b ») ; « Quoi » : « au repos » ; durée « au repos depuis 45 min ». Tri : activité la plus récente d'abord. Densité : 6, puis
« Les N autres ». Vide : « Aucune session au repos. »

### 4.5 États de la page et consignes de résolution

| État | Rendu | Se résout quand |
|---|---|---|
| Premier `who` pas reçu | `aria-busy="true"`, « Lecture de l'équipe » (`--text-3`) au-delà de 150 ms | dès le premier `who` |
| Aucun agent dans les 24 h | boîte neutre (`--note-bg`, `--r-ctl`, `--inset-box`) : « Aucun agent dans les dernières 24 h. » puis « Les sessions de ce dépôt apparaîtront ici dès qu'elles écrivent. » ; quatre titres vides gardés | dès qu'un agent entre dans la fenêtre |
| Pas de direct (page exportée, ouverte en fichier) | boîte neutre : « Le direct n'est pas branché. » puis « Ouvrez le cockpit depuis le projet pour voir l'équipe. » | jamais dans cette page |
| Source illisible | pied de page 12 px `--text-4` : « Source illisible : Sessions et sous-agents » (texte existant, un nom par source `erreur` ou `forme-inconnue`) | à la première collecte suivante où la source est `lue` ou `absente` : la ligne disparaît d'elle-même, sans geste |
| Direct coupé | ligne sous le sous-titre : « Direct coupé : durées figées, données d'il y a 2 min » ; les durées cessent d'avancer | quand `__vfLive.connected` redevient vrai (même source et même délai de 15 s que la bannière AUDC-M9, jamais avant) : disparaît seule, durées reprises sans saut |
| Recherche active | le champ existant filtre les lignes par **nom et rôle visibles** (côté page) ; sections vides masquées pendant le filtre ; sans résultat : « Aucun agent ne correspond. » ; choisir un résultat place le focus sur la ligne | en vidant le champ |

## 5. Mise à jour en direct

- Les lignes se mettent à jour **en place** à chaque `who` (clé = identifiant), **sans rechargement de page**. Durées recalculées toutes les 30 s
  (aucun dessin si le texte est identique). La page lit `who` et `lock` par un adaptateur unique (P73-D-02) : le rendu ne sait pas d'où ils viennent.
- Un redessin conserve défilement, lignes ouvertes, replis et **focus** (retrouvé par identifiant ; si la ligne change de section il la suit ; si elle
  disparaît il va au titre de sa section). Jamais de focus volé (Q5).
- Région `aria-live="polite"` unique : « 2 vous attendent » quand le compte d'« À vous » augmente, une fois par rafale, jamais à la baisse.

## 6. Verrou, arbres de travail, marques de gouvernance

### 6.1 Tenant du verrou et ligne de mission

- **Ligne de mission** (section « Au travail », avant l'arbre, une par mission dont un verrou est tenu) : ligne non agent, sans glyphe d'état,
  12 px `--text-2` : **« verrou : <owner réduit> · <étape> · depuis 12 min »**, suivie des marques de § 6.3. `owner réduit` = le nom de la session quand
  la collecte la nomme, sinon la forme courte de l'identifiant, bornée à 80 caractères (champ `owner`) ; **le nom du détenteur n'est écrit
  qu'ici** (ni pastille « tient le verrou » sur sa ligne, ni nom dans l'en-tête). « depuis » = le champ `tenu` (date de prise).
- **Ligne d'en-tête** (§ 2) pour le **seul verrou de portée dépôt** : « Verrou du dépôt : <owner réduit> · <étape> · depuis 12 min » ; sans verrou de
  dépôt, aucune ligne. Aucun repli « 2 autres verrous » : chaque mission porte le sien.
- **Champs lus** (liste blanche de la page, forme projetée par la Phase 79, A15) : `ws`, `scope`, `phase`, `step`, `tenu`, `stale`, `ageS`, `ttl`,
  `progressAgeS`, `owner` (≤ 80), `childrenRunning`, `dag`. **Jamais** `session_ids` ni `lease_seconds` ; aucun autre champ n'entre dans le DOM,
  le stockage ou l'export. Avant la fusion de A15 : mêmes champs lus dans la forme brute présente (`age_seconds`, `progress_age_seconds`,
  `children_running`). Les règles de vivacité de mission du socle (P68-D-05, D-22, D-23, D-26, D-27) s'appliquent telles quelles.

### 6.2 Arbres de travail et travail non commité

Bloc **replié** en pied de page : `details` « Arbres de travail (3) » (P73-D-10). Il joint par chemin `GET /api/vf/git` (branche) et
`GET /api/vf/git/worktrees` (comptes) : **aucun appel git neuf**.
- **Déclencheurs** : l'ouverture du bloc, puis l'événement `git` ; pas de minuterie. Chargement : « Lecture du dépôt ».
- **Ligne d'arbre** (gabarit du tiroir Git) : nom du dossier (mono 12 px/500), pilule « ici », branche (mono 12 px `--text-3`), puis pastilles en
  **texte neutre** (`--text-2`, pas de fond teinté, Q9) : « 3 modifiés », « 2 non suivis », « ↑2 ↓1 », « propre ». **Un worktree non vérifié dit
  « non vérifié »** (P78-D-38) : ni compte ni « propre ». Aucune commande à copier ici ; lien « Ouvrir l'historique Git (g) » en pied.
- Une ligne d'agent dont l'arbre a du travail non commité le dit en ligne 2 (« 3 modifiés ») une fois les états lus ; jamais de chargement forcé.
- Vide : « Un seul arbre de travail. » ; échec : « Git est indisponible » + bouton « Réessayer ». Pas de dépôt git : le bloc n'existe pas.

### 6.3 Marques de gouvernance (watchdog, sans le nommer)

Posées sur la **ligne de mission** et, quand le DAG est visible, sur les lignes des **nœuds `running`** (ligne 2 de « Quoi »). Texte neutre, glyphe
`surveiller` devant, mot en 600, **ni couleur d'alerte ni fond** ; elles **ne reclassent rien**. Le mot « veilleur » n'est pas utilisé : la ligne ne
nomme pas l'outil.
- **« verrou abandonné »** : `stale` vrai (le critère exact du watchdog).
- **« aucun nœud marqué depuis 27 min »** : `progressAgeS` dépasse la fenêtre de stall. Dit au conditionnel de la source : le watchdog compte aussi
  les commits récents, que la page ne lit pas ; ce n'est pas un verdict de stall. Infobulle : « Compté sur les nœuds marqués du plan, pas sur les commits. »
- **Fenêtre de stall, une seule source** : `VF_STALL_WINDOW` de l'environnement du serveur, sinon la valeur par défaut extraite de la ligne
  `STALL_WINDOW=` de `plugin/conductor/scripts/check-guard-health.sh`. **Extraction impossible : seuil inconnu, rien n'est marqué** (ni texte ni
  glyphe). La même fenêtre fonde « suspect » (§ 3).

## 7. Détail de ligne et boutons

Cliquer sur le nom d'une ligne (Entrée, Espace) émet `vf-agent:ouvrir` `{ id, kind, declencheur }` (§ 9). **Sans `preventDefault`**, la régie déplie
le **lecteur actuel** sous la ligne : bloc de détail **en flux**, dans la colonne, un seul ouvert par section. Q12 vise le tiroir latéral, qui ne
pousse jamais la carte ; ce bloc n'est pas un tiroir, il pousse seulement les lignes qui le suivent. La fiche d'agent de la Phase 74 n'est pas un
tiroir non plus (P74-D-03) ; elle annule l'évènement et remplace ce bloc.
- Bloc `--raise`, `--r-ctl`, `--inset-box`, gap `--sp-8`, texte 12 px `--text-2` : identifiant court (mono), branche et arbre, lien « Nœud … »
  (§ 8), puis le transcript réduit existant (texte seulement, borné, sans sortie d'outil, jamais exporté, gardé en mémoire de page, libellé de
  chargement « Lecture du transcript… »). **Plus de bouton « Voir la dernière commande »** sur la ligne (P67-D-14 : la commande n'est dans aucun
  flux ni fichier ; elle reste lisible dans le tiroir, Projet).
- **Un seul style de bouton, le `.btn` doux du viewer** (AUDC-F2, P73-D-17), **aucun style neuf** : « Lire le rapport », « Tout marquer comme
  relu », « Réessayer ». Les boutons-icônes du tiroir (caret, fermeture) restent une catégorie distincte, documentée. Aucun bouton plein `--on`.
  Hauteur de contrôle du `.btn` ; 44 px en `pointer: coarse`. Focus `outline: 2px solid var(--ring)`. Jamais `disabled` : `aria-disabled` +
  `aria-busy`. Les liens (navigation) sont soulignés (`a.vf-link`), pas des boutons.
- Entrée sur un bouton ne remonte pas au raccourci « ouvrir le nœud sélectionné » (garde `UIFN-12` existante).

## 8. Liens entre les trois graphes (AUDC-I21)

Qui lance qui (l'arbre), quel nœud chacun porte (lien « Nœud plan-73 » vers `project.html#r=f:<dag>#<nœud>`), quelle phase avance (le lien « Voir dans
l'onglet Équipe » de Projet garde sa forme `equipe.html#r=n:se-<id>` / `n:ag-<id>`). Sur Équipe, la régie traite ces ancres : **défilement et focus sur
la ligne** (garde `TAB==='equipe'` posée sur une ligne existante de `00-vibeflow.js`), plus de canevas. Aucune couleur par nœud (Graphite). Un lien n'est
jamais deviné : seul un rattachement établi en donne un.

## 9. Points d'accroche de la Phase 74 (P73-D-20, nommés, non dessinés)

| Accroche | Contrat |
|---|---|
| `section#vf-equipe` | conteneur injecté en JS, le `#stage` du canevas n'étant pas affiché sur Équipe |
| `#vf-equipe-entete` | en-tête de la page (titre, sous-titre, verrou de dépôt, bascule) |
| `.vf-vue[data-vf-vue="regie"]` | la vue de la régie, une vue parmi d'autres |
| `window.__vfEquipeVues.declarer({ id, libelle, monter(el), demonter() })` | registre de vues ; la Phase 74 y déclare la sienne (`frise`) sans toucher un fichier de la 73 |
| bascule « Régie · Frise » | **dessinée par la 73, dès que deux vues sont déclarées** (même modèle que `.vf-tabs`, `role="tablist"`) : jamais de bouton mort ; la régie est la vue par défaut et la vue au rechargement |
| `vf-agent:ouvrir` `{ id, kind, declencheur }` | évènement de document **annulable**, émis par le nom d'une ligne, « Lire le rapport » et l'ancre `#r=` ; sans `preventDefault` la 73 ouvre le lecteur actuel (repli, § 7) ; la 74 l'annule et ouvre sa fiche ou son lecteur |
| `vf-agent:lu` `{ id }` | émis à l'ouverture d'un rapport ; alimente « Terminé, à relire » |
| `data-vf-agent`, `data-vf-noeud`, `data-vf-etat` | sur chaque ligne ; `data-vf-etat` = la clé du glyphe (`attend`, `actif`, `surveiller`, `attente`, `repos`, `orphelin`, `termine`) : la frise lit les mêmes formes |
| ancres `#r=n:se-<id>`, `#r=n:ag-<id>` | forme inchangée ; traitées par la régie (§ 8) |

## 10. Notifications (AUDC-I09) et « ailleurs sur ce poste » (AUDC-I10)

**Titre d'onglet.** `(2) vous attendent · Équipe · nom` ; singulier `(1) vous attend · …` ; à zéro, le format existant « <Onglet> · <nom> » (lot 0, X7).
`N` = lignes de « À vous » de **ce** lab (jamais « ailleurs »). Posé sur les trois onglets. Les mots passent avant le reste pour survivre à la
troncature. Un **compositeur unique du titre** remplace les **trois écrivains actuels** : `00-vibeflow.js:13`, `76-vf-git-entete.js:19` et l'observateur
de `80-vf-fr.js:147` ; les trois passent par lui. Témoin : le préfixe survit à un évènement `git` et à la traduction.

**Pastille de favicon** (non optionnelle) : image en `data:` calculée localement (aucune ressource externe), **un point plein neutre** de la couleur du
texte du thème, sans chiffre (le compte est dans le titre), sans teinte ; retirée à zéro.

**Un seul motif de signal : « vous attend ».** « Fin » et « échec » ne changent ni titre ni pastille : ils s'écrivent sur la ligne de « Terminé, à relire »
(mot « échec » ou « arrêté », § 3). Jamais de focus volé (Q5). **Pas de compteur ajouté sur l'onglet « Équipe »** de l'en-tête (non cadré). **Pas de
notification du système** (reportée, P73-D-15).

**« Ailleurs sur ce poste »** (P73-D-16). Une ligne de texte neutre (12 px, `--text-3`, ni encart ni lien) en pied de page :
« Ailleurs sur ce poste : 1 session vous attend, dans « atelier ». » ; pluriel : « 2 sessions vous attendent (« atelier », « notes »). » ; au-delà de 3
labs, trois noms puis « et 2 autres ». **Nombre et nom du lab seulement** : ni titre, ni chemin, ni identifiant, ni transcript. Nom du lab = dernier segment
du chemin après retrait d'un suffixe `/.claude/worktrees/<n>`, borné à 40 caractères et masqué ; dossier personnel, ancêtre de celui-ci ou chemin trop
court : **« un autre dossier »**. Sans état officiel, **pas de ligne** (jamais « 0 »).
- **Route propre, à la demande** : `GET /api/vf/ailleurs` (`vibeflow/cockpit-ailleurs@1`, `[{ lab, n }]`), lue par la page à l'ouverture de l'onglet et sur
  l'évènement `who`. **Le nom d'un autre lab ne vit que dans la page servie** : **jamais** dans `who@2`, le flux, l'objet d'état, `cockpit-signal@1`,
  l'export, ni un fichier du lab (cache du cockpit compris). La ligne n'entre pas dans le compte du titre.

## 11. Responsive (points de rupture inchangés : 700, 999, 1 279 en tactile)

- **≥ 1 000 px** : cinq colonnes (§ 3).
- **701 à 999 px** (et tactile < 1 280 px) : « Droite » passe sous « Quoi » ; trois colonnes (glyphe, qui, durée), « Quoi » sur deux lignes sous « Qui ».
- **≤ 700 px** : une colonne ; glyphe + nom, puis quoi, puis durée et action ; indentation limitée à un niveau (`--sp-16`) ; boutons 44 px ; aucun zoom ;
  aucun défilement horizontal, vérifié à 375, 700, 768 et 1 000 px.
- Le bouton « N au travail » de l'en-tête (réduit à son point, P70-D-22) **mène à la section « Au travail »** sur Équipe (focus sur son titre) et n'y ouvre
  plus le tiroir latéral (doublon). Code et Projet : inchangé.
- Un tiroir latéral (Git) ne pousse jamais la liste (Q12) ; `body.vf-git-ouvert` masque le bloc de titre comme il masque `#context` aujourd'hui.

## 12. Accessibilité

- **Structure** : un `main`, `h1`, `h2` par section, `ul`/`li` (arbre en `ul` imbriquées). Pas de `role="grid"`.
- **Nom accessible d'une ligne** (bouton d'ouverture), composé une fois : « état, nom, détail, durée » (« vous attend, vf-dev-manager Phase 73, retient 4
  nœuds, attend depuis 14 minutes »). Glyphe `aria-hidden` ; l'état est dans le texte (`sr-only` si le mot visible n'est pas l'état).
- **Clavier** : Tab, dans l'ordre visuel, par ligne : bouton d'ouverture, caret, lien « Nœud », « Lire le rapport ». ↑ et ↓ sur un bouton d'ouverture
  vont au précédent ou au suivant (sections confondues), Début et Fin au premier et au dernier ; Entrée et Espace déplient ; Échap replie le détail et
  rend le focus à son bouton. Aucune modale, aucun piège. Focus : `outline: 2px solid var(--ring)`, `-2px` dans les surfaces, `2px` ailleurs. Aucune
  lettre de raccourci nouvelle.
- **Contraste** : texte ≥ 4,5:1 dans les deux thèmes ; `--text-4` réservé au pied « Source illisible » ; glyphes ≥ 3:1 sur `--surface` (en clair
  `--st-active` fait 3,01:1 : écart connu, le mot et la forme portent l'état).
- **Cibles** : lignes ≥ 44 px ; carets et boutons 44 px en tactile. **Mouvement réduit** : respiration coupée, rien d'autre ne bouge.
- **Lecteur d'écran** : `aria-live` (§ 5), `aria-busy` au chargement, titre à jour (§ 10), `aria-expanded` sur ouvertures et replis, `aria-labelledby` sur les
  boutons (le nom n'est jamais dupliqué en texte).

## 13. Données requises

| Besoin | Champ | État |
|---|---|---|
| États, orphelin, outil en cours, action, tenue, âge, rattachement | `etat`, `orphan`, `enCours`, `action`, `dureeS`, `ageS`, `rattachement` | déjà dans `who@2` (lot 0) |
| Attend ses agents | `attendAgents` (session seule, entier, absent = 0) | à produire, facultatif (P73-D-12) |
| Lancée depuis la carte | `lancee` `{ phase, ws, verbe }` | à produire, facultatif, revalidé à l'émission (P73-D-21) |
| Motif de fin | `finMotif` : `echec` ou `arret`, absent sinon | Phase 79, A20 ; à revalider avant sa fusion |
| Muets retirés | `sortisSilence` (entier) | Phase 79, A20 ; à revalider ; absent ou nul : rien dit |
| Verrous | flux `lock`, forme projetée `{ seq, at, verrous }` ; champs de § 6.1 | Phase 79, A15 ; à revalider ; repli : forme brute présente |
| Plan publié (impact) | résumé de plan désigné par `dag` : identifiants, dépendances, statut, compartiment, phase, jamais le texte des nœuds | Phase 79, A16 ; à revalider ; repli : DAG déjà découverts ; sans plan : « impact inconnu » |
| Impact et lignes de phase | `retient` par ligne d'attente, lignes de phase `human_needed` (en-tête de `*-VERIFICATION.md` seul) | module de gouvernance neuf, fonctions pures (P73-D-23) |
| Fenêtre de stall | `VF_STALL_WINDOW`, sinon `STALL_WINDOW=` de `check-guard-health.sh` ; inconnue = rien marqué | à produire |
| Ailleurs | `GET /api/vf/ailleurs` (`cockpit-ailleurs@1`) | route propre, **jamais** dans `who@2` ni le flux ni l'état ni l'export |
| Arbres de travail | `GET /api/vf/git`, `GET /api/vf/git/worktrees` | existent (Phase 78) |
| Rapport | dernier élément `genre: message` du `fil` de `/api/vf/transcript` | existe (`cockpit-transcript@2`) |
| Lu / non lu | `localStorage`, clé par lab, identifiants + heure, purge 24 h | côté page |

Bornes : traces locales, aucun appel réseau sortant, lecture seule sur `.planning/`, dernière commande jamais dans le flux, le fichier ni l'export,
verbe et cible réduite sans argument, transcript sans sortie d'outil et jamais exporté, rien sans `--terminal`. Un champ de la page passe par une
liste blanche ; aucune route d'écriture.

## 14. Libellés neufs et dictionnaire

Tout est écrit en français dans les fichiers de la régie ; le dictionnaire (`78-vf-fr-dict-a.js`, `79-vf-fr-dict-b.js`, `80-vf-fr.js`) ne traduit que des
chaînes anglaises du moteur : aucune entrée à y ajouter. À faire : étendre le test de chrome français à ces libellés (aucune chaîne anglaise visible sur
l'onglet).

| Emplacement | Libellé exact |
|---|---|
| Sous-titre | `N agents · P vous attendent · Q à relire` ; « 1 agent », « 1 vous attend », « 1 à relire », « Aucun agent en vie » |
| Sections | « À vous », « Au travail », « Terminé, à relire », « Au repos » ; aide : « classé par ce que chaque attente retient dans le plan » |
| Vides | « Rien ne vous attend. » · « Personne ne travaille en ce moment. » · « Aucun rapport à relire. » · « Aucune session au repos. » |
| Page | « Aucun agent dans les dernières 24 h. » · « Les sessions de ce dépôt apparaîtront ici dès qu'elles écrivent. » · « Le direct n'est pas branché. » · « Ouvrez le cockpit depuis le projet pour voir l'équipe. » · « Lecture de l'équipe » · « Direct coupé : durées figées, données d'il y a 2 min » · « Aucun agent ne correspond. » |
| États (Quoi) | « vous attend » · « au travail » · « commande en cours depuis 7 min » · « outil en cours depuis 7 min » · « silencieux depuis 4 min » · « suspect : aucun signe de vie depuis 18 min » · « commande longue : 22 min » · « attend ses agents (3) » · « au repos » · « orphelin » · « son parent est terminé, cet agent travaille encore » · « rapport rendu » · « échec » · « arrêté » · « il y a 3 min » |
| Impact | « retient N nœuds » · « retient 1 nœud » · « retient toute la mission · N nœuds » · « ne retient rien » · « impact inconnu » · infobulle de limite : « L'impact compte les nœuds du plan, pas leur durée ni leur importance. » |
| Ligne de phase | « Phase 74 : vérification humaine demandée » |
| Durées (préfixes) | « attend depuis » · « depuis » · « a duré » · « écrit il y a » · « au repos depuis » |
| Verrou | « verrou : <owner> · <étape> · depuis 12 min » · « Verrou du dépôt : <owner> · <étape> · depuis 12 min » |
| Marques | « verrou abandonné » · « aucun nœud marqué depuis 27 min » · infobulle « Compté sur les nœuds marqués du plan, pas sur les commits. » |
| Arbres | « Arbres de travail (3) » · « Un seul arbre de travail. » · « non vérifié » · « Ouvrir l'historique Git (g) » ; reprises : « 3 modifiés », « 2 non suivis », « propre », « ici », « Lecture du dépôt », « Git est indisponible », « Réessayer » |
| Boutons | « Lire le rapport » · « Tout marquer comme relu » · reprise : « Lecture du transcript… » |
| Replis, pieds | « Relus ou sans rapport · N » · « Les N autres » · « Un autre » · « N muets depuis plus de 30 min, retirés » · « 3 à relire dans Équipe » (tiroir) |
| Lancement | « Lancée depuis la carte : Phase 73 · fiabilite · exécuter » (format existant) |
| Notifications | titre `(2) vous attendent · Équipe · nom` / `(1) vous attend · …` · annonce « 2 vous attendent » |
| Ailleurs | « Ailleurs sur ce poste : 1 session vous attend, dans « nom ». » · « Ailleurs sur ce poste : 2 sessions vous attendent (« a », « b »). » · « et 2 autres » · repli « un autre dossier » |

## 15. Variables et espacements (tous existants)

Couleurs et ombres : `--surface`, `--surface-hover`, `--raise`, `--raise-2`, `--hair`, `--ink`, `--text`, `--text-2`, `--text-3`, `--text-4`, `--st-active`,
`--st-done`, `--note-bg`, `--ring`, `--fil` (posé par `.vf-whop`, à reprendre sur le conteneur), `--shadow-card`. Rayons : `--r-card`, `--r-ctl`, 8, 999.
Polices : `--sans`, `--mono`. Aucune variable créée ; jamais `--text-1` ; **`--st-recette` non utilisée** (P73-D-19).
Espacements (grille fermée 2, 4, 6, 8, 12, 16, 20, 24, 32) : `--edge`, `--gap-section` 24, `--inset-row` 8 × 12, `--inset-box` 12, `--inset-pill` 2 × 8, `--sp-4`,
`--sp-8`, `--sp-12`, `--sp-16`. Tailles de contrôle : 16 (glyphe), 44 (tactile, caret, ligne), 96 et 152 (colonnes, dimensions), 960 (conteneur). Aucune
valeur en dur de couleur, d'ombre ni d'espacement.

## 16. Ce que le juge de design doit vérifier

1. Aucune couleur, ombre, rayon ou espacement en dur ; deux thèmes ; aucun fond teinté, liseré, anneau ou halo coloré ; aucun dégradé ; aucun kicker.
2. Quatre sections dans l'ordre fixe, « À vous » en 18 px ; tri en trois rangs (§ 4.1), jeu d'essai : impact 4, impact 1, impact inconnu, impact 0, égalité
   départagée par l'ancienneté.
3. Le nom d'un agent écrit **une fois** par ligne ; le nom du détenteur du verrou écrit une fois ; aucune carte « Terminés depuis moins de 24 h », aucun bloc
   Santé, aucun terminal, aucune barre de question, aucune action d'arrêt, de réponse ou de recette, aucun « Voir la dernière commande ».
4. Un seul style de bouton (`.btn` doux) pour « Lire le rapport », « Tout marquer comme relu », « Réessayer » ; aucun bouton plein.
5. Chaque état se lit sans la couleur ; aucune teinte d'alerte ; glyphes du lot 0 inchangés ; « vous attend » en `--text-2`.
6. Orphelin sous la ligne grisée de son parent ; session au repos d'un autre arbre listée au-delà de 3 min ; « attend ses agents (N) » sur sessions seules.
7. Ligne de mission : verrou « depuis N » (champ `tenu`), jamais `session_ids` ni `lease_seconds` ; marques neutres au conditionnel ; fenêtre inconnue = rien
   marqué. Arbres de travail : replié, « non vérifié » dit, pastilles neutres.
8. Mise à jour sans rechargement : focus, défilement, détails conservés ; annonce `aria-live` unique ; direct coupé : durées figées, ligne qui disparaît seule.
9. Titre `(N) vous attendent · …` via le compositeur unique ; pastille de favicon neutre ; « ailleurs » = nombre et nom du lab seulement, absent de `who@2`, du
   flux et de l'export ; « un autre dossier » en repli.
10. Responsive 375, 700, 768, 1 000 et 1 440 px sans défilement horizontal ; cibles 44 px en tactile ; Q12 respecté pour le tiroir latéral.
11. Clavier seul : parcours complet ; lecteur d'écran : noms composés une fois, états dits.
12. Anti-slop : monochrome, aucune police neuve, aucun tiret cadratin dans le copy, aucun emoji.

## 17. Choix de la première version de la spec, devant le CONTEXT

Chaque choix initial (C-01 à C-16) a été confronté à `73-CONTEXT.md`. Format : issue, décision ; chaque décision est « décision déléguée par Samuel
(message session principale, 2026-11-08), option recommandée ».

| Choix | Issue | Décision |
|---|---|---|
| C-01 glyphe « vous attend » en `--st-recette` | **rejeté** | P73-D-19 : lot 0 gardé, `--text-2` |
| C-02 seuils 2 min, 15 min, 30 min | **retenu, amendé** | P73-D-11 : « suspect » = fenêtre de stall (900 s par défaut, source unique) ; commande en cours « au travail » jusqu'à 15 min |
| C-03 suspect et orphelin neutres, glyphes du lot 0 | **retenu** | P73-D-11, P73-D-19 (Q9) |
| C-04 colonne contexte | **sans objet** | P73-D-27 : aucune source avant la Phase 74 |
| C-05 arbitrages en attente dans « À vous » | **rejeté tel quel** | P73-D-06 : lignes de phase `human_needed` ; le reste est S-3 de Samuel |
| C-06 session détentrice classée « toute la mission » | **retenu, amendé** | P73-D-07 : seulement si le DAG est visible, avec N nœuds |
| C-07 « lu » en `localStorage` | **retenu, amendé** | P73-D-14 : clé par lab, identifiants et heure, purge 24 h, repli sans stockage |
| C-08 « Tout marquer comme relu » | **retenu** | P73-D-14 |
| C-09 arbres de travail en bloc replié | **retenu** | P73-D-10 |
| C-10 pastilles de worktrees neutres | **retenu** | P73-D-10 ; S-1 (correctif du tiroir Git, hors phase) |
| C-11 alerte du watchdog neutre, nom « veilleur » | **retenu, amendé** | P73-D-09 : « veilleur » retiré, « verrou abandonné » (`stale`) et « aucun nœud marqué depuis N min », fenêtre à source unique |
| C-12 un seul motif de notification | **retenu, amendé** | P73-D-15 : fin et échec écrits sur la ligne (`finMotif`) |
| C-13 favicon optionnel | **rejeté** | P73-D-15 : non optionnelle, `data:` |
| C-14 « N au travail » mène à la section | **retenu** | P73-D-14 |
| C-15 « ailleurs » depuis la liste officielle | **retenu, amendé** | P73-D-16 : route propre `GET /api/vf/ailleurs`, jamais dans `who@2` |
| C-16 compte du sous-titre ; export ; recherche | **retenu, fermé** | P73-D-01 (compteurs), P73-D-25 (export sans régie, recherche par nom et rôle) |

Questions restantes (non bloquantes, côté Samuel dans le CONTEXT) : S-1 à S-4. Dépendances à revalider à la fusion de la Phase 79 : A15 (verrous
projetés), A16 (plan publié), A20 (`sortisSilence`, `finMotif`).

## 18. Questions en attente des cadrages (73-11)

Source : `meta.vf.questions` (C76-Q2). Libellés (espace insécable avant chaque deux-points) :

| Emplacement | Libellé exact |
|---|---|
| Repli des décisions appliquées | « Décisions prises pour vous, contestables (N) » (fermé, absent à N = 0, jamais compté) |
| Entrée d'une décision | la question ; « Option appliquée : (a) <texte> » ; « Décision : P90-D-03 » ; lien de phase |
| Repli à vérifier | « À vérifier (N) » ; entrée : identifiant, question, « <fichier relatif>, ligne <n> », défauts en mots |
| Signalement | « Entrée mal formée : <id>, <fichier>, ligne <n> : <défauts> » ou « … <id>, emplacement non affiché : <défauts> » ; cinq au plus puis « et N autres » |
| Bilan | « Cadrages lus : 1 tranchée · 2 à vérifier · 2 mal formées · 2 questions écrites dans un autre format, non lues · 2 entrées de forme inattendue, ignorées » |
| Troncature | « Liste tronquée à N questions : les suivantes ne sont pas lues. » |
| Champ absent | « Lecture des questions des cadrages pas encore livrée (Phase 76) » |
| Lecture en cours | « Lecture des questions des cadrages… » |
| Champ illisible | « Questions des cadrages illisibles : forme inattendue, relue à la prochaine mise à jour. » |
| Recommandation | « recommandée » après l'option recommandée seule ; « Aucune recommandation. » si aucune |
| Ce qu'elle bloque | « bloque : 90-02, Phase 91 » ; rien si vide |
| Lien de phase | « Voir la phase 90 dans Projet » ; sans carte : « Phase 90, sans carte dans Projet » |

Structure d'une ligne : `li[data-vf-cle="a-vous:<id>"][data-vf-question="<id>"][data-vf-etat="attend"]` : glyphe « attend », identifiant en mono, titre, question, options, recommandation, ce qu'elle bloque, lien de phase ; aucun bouton. Replis en flux : `details[data-vf-repli="decisions"|"a-verifier"]` dans le pied de « À vous » (`[data-vf-qpied]`), après la liste, avec message d'état, signalements, bilan, troncature. États de source : absente, lecture, illisible, lue.
