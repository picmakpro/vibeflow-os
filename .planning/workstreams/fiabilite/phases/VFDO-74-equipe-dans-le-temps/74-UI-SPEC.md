# Phase 74 : L'équipe dans le temps — UI-SPEC (craft-equipe-temps)

**Contrat de design** pour la bascule « Régie · Frise », la frise, le curseur, la fiche d'agent (lecteur plein cadre) et le coût.
Direction « Graphite » (`DESIGN.md`, fait foi). Sources lues : `74-CONTEXT.md` (P74-D-01 à D-54 ; D-46 à D-54 amendent le texte d'origine et font foi), les contrats C0 à C6 de la Phase 79 (route de frise `vibeflow/cockpit-frise@1`), `DESIGNS.md` § 2, 4, 5, 9 et la page
d'audit (maquettes 2 et 3), `71-vf-equipe-rendu.js`, `72-vf-equipe.js`, `vf-cockpit-transcript.mjs` (bornes), `78-UI-SPEC.md` (modèle).
Aucune brique externe de craft consultée : dégradation sur les premiers principes (contraste WCAG, grille 2 px, hiérarchie). Aucune
décision du CONTEXT n'est rouverte.

**Règle des espaces insécables, qui prime sur la graphie des chaînes de ce document** : les chaînes ci-dessous sont écrites avec des espaces ordinaires par lisibilité ; à l'écran, toute espace avant `: ; ! ?` et dans les nombres, durées et unités (« 1 h 30 », « 168 k », « 1 204 », « 14 h 32 ») est une espace insécable U+00A0, sans exception. Le témoin de la § 9 mesure le rendu, pas la graphie de la spec.

**Choix de forme acceptés (P74-D-30), inscrits dans le corps :** « attend ses agents » en trait neutre (§ 2) ; clic sur la colonne de gauche = fiche, clic dans la zone des segments = curseur (§ 2, § 3) ; faits de la fiche sur l'horizon de l'index, 24 h, libellé visible (§ 4) ; « autour de t » = ± δ, δ = max(2 min, pas du curseur / 2) (§ 3, P74-D-49) ; synthèse en entrée et sortie, cache dans le détail (§ 5) ; ouverture de la fiche par l'événement `vf-agent:ouvrir` de la régie (§ 4, § 8) ; téléphone : colonne de gauche collante de 120 et pistes en défilement horizontal propre à la frise, largeur minimale 480 (§ 2) ; bascule dessinée et sa position gardée par la régie de la 73, la 74 n'en garde aucune (§ 1). Glyphes : P74-D-29 (§ 2, § 8).

**Règles de lecture.** Libellés en français ; les espaces avant `: ; ! ?` et dans les durées, nombres et unités (« 1 h 30 », « 168 k »,
« 1 024 ») sont insécables (U+00A0) ; aucun tiret cadratin dans le copy. Tout texte venu des traces (nom d'agent, nœud, titre, message,
cible) s'écrit en `textContent` ou `createElementNS` : jamais `innerHTML` d'une chaîne de données (P74-D-27). Classes neuves en `vf-frise-*`
et `vf-fiche-*`, dans des modules neufs `ui/74-vf-*.js` (P74-D-43), qui commencent par `// VibeFlow (`. Rayons : seulement `999px`, `8px` ou `var(--r-card)`, `var(--r-ctl)`, `var(--r-panel)` ; espacements : variables seulement (garde `css-jetons.mjs`). **Données non traduites** : tout nom d'agent, nœud, titre, message, cible, branche ou chemin est posé dans un élément que la traduction de la page (`80-vf-fr.js`) saute déjà (`code`, `pre` ou classe `.mono`) ; pour un texte en police sans (nom, message), la classe `.mono` sert de marque et `.vf-donnee` rétablit `--sans`. Un message « Close » reste « Close ». Aucune couleur par nœud, aucun montant en devise, aucune action sur une
session, aucun quatrième onglet. Le moteur n'est pas modifié (P74-D-31) : tout le rendu vit dans des modules `ui/*vf*`. L'objet global du moteur est gelé : la 74 n'y ajoute aucune fonction, les siennes vivent sous `window.__vfFrise` et `window.__vfFiche` (P74-D-44). **Cycle de vie (P74-D-45)** : la frise, la fiche et le lecteur s'initialisent par `VF_COQUILLE.surOnglet(rappel)` et se nettoient en quittant l'onglet (abonnements `VF_ETAT`, minuteries, observateurs, écouteurs) ; revenir sur Équipe ne double aucun abonnement. Toute lecture de la page passe par `VF_ETAT.jeton()` et `VF_ETAT.lireJson()` (P74-D-37), aucune par un `fetch` direct ni une route posée par la 74. **Échap (P74-D-53)** : la fiche et le lecteur sont des vues de l'onglet Équipe, pas des surcouches ; Échap s'écoute en remontée, sur `document` ou la racine de la vue, jamais en capture ni sur `window` ; un appui dont `defaultPrevented` est vrai est ignoré ; la vue ne lit jamais `VF_SURCOUCHES.ouverte()` (§ 3 Clavier, § 4).

**Typographie par rôle (échelle de `DESIGN.md` § 3, tout le reste en découle).** Une seule taille de mono pour toute la 74 : 11,5 px.
| Rôle | Taille / graisse / hauteur de ligne | Où |
|---|---|---|
| Titre de fiche | 20 px / 600 / 24 | `h2` de la fiche |
| Titre de bloc | 15 px / 600 / 20 | `h3` (encart, coût, fil), valeurs des six chiffres |
| Interface | 13 px / 500 / 18 | positions de la bascule, boutons, « Retour » |
| Courant dense | 12,5 px / 400 ou 500 / 16 (20 en fil, multi-ligne) | noms de voie, lignes de fil et d'encart, cellules de tableau, synthèse, notes, légendes, libellés, intertitres, états de chargement |
| Étiquette | 11,5 px / 500 / 14 | seconde ligne de voie, en-têtes de tableau, étiquettes de filtre |
| Mono | 11,5 px / 400 ou 500 / 14 (16 hors voie) | axe, heures, nœud, branche, chemin, cible, code, « +N », « 14 min », jetons |
Aucune autre taille (ni 10,5, ni 11, ni 15,5).

## 1. Bascule « Régie · Frise » (P74-D-02, amendée par P74-D-51)

**Qui la dessine (P74-D-51).** La bascule est dessinée par la régie de la Phase 73 : la frise se déclare comme une vue
(`window.__vfEquipeVues.declarer({ id: 'frise', libelle: 'Frise', monter, demonter })`, dans `section#vf-equipe`) et la 74 ne pose aucune
bascule propre, aucun fichier de la 73 n'est modifié. Cette section décrit ce que la frise **attend** de cette bascule, et non un composant de la 74 : position
« Frise » à côté de « Régie », libellé exact « Frise », défaut Régie, aucun onglet de page ajouté (P78-D-04). La bascule est un `role="tablist"` de nom accessible
« Vue de l'équipe », avec les onglets « Régie » et « Frise ». **Sa position est gardée par la 73 ; la 74 n'en garde aucune** (aucune clé de stockage, aucun état
de bascule propre). La 74 monte et démonte sa vue à l'appel de la régie et conserve la vue d'origine (`hidden`, `inert`) pendant que la fiche est ouverte. Les états
et tailles ci-dessous sont l'attente de la 74 ; en cas d'écart, la 73 fait foi pour le dessin et la 74 s'y aligne.

**Forme (attendue de la régie).** Groupe à deux positions dans l'en-tête de la zone de contenu de l'onglet Équipe, aligné à droite de la ligne de titre (le titre
de vue de la 73 reste à gauche). Même modèle que `.vf-tabs` : piste `--raise`, rayon `var(--r-ctl)`, `padding var(--sp-4)`, gap `--sp-2` ; positions
« Régie » et « Frise », 13 px / 500 / 18, `padding var(--sp-4) var(--sp-12)`, rayon `8px` (valeur admise par la garde `css-jetons.mjs`, concentrique avec la piste) ; graisse 500 dans tous les états (jamais de changement de graisse, donc aucune variation de largeur) ; la position active se dit par `--surface` et l'ombre de 1 px
du groupe d'onglets. Hauteur de la piste : 36 (taille de contrôle), 44 en `pointer: coarse` (positions 44 de haut).
Ce n'est ni un onglet de page ni un lien : le groupe n'a pas d'URL. Défaut : Régie. Aucun raccourci clavier (`f` est pris par le viewer).

**États.**
| État | Rendu |
|---|---|
| repos | texte `--text-3`, fond transparent |
| survol | texte `--text`, fond `rgba(var(--ink), .06)` (position inactive seulement) |
| actif | `--surface` et ombre de 1 px du groupe, texte `--text`, 500 |
| focus clavier | `outline: 2px solid var(--ring); outline-offset: 2px` |

**Clavier et ARIA.** `role="tablist"` nommé « Vue de l'équipe » ; deux `role="tab"` (`aria-selected`, `aria-controls`),
chacune pilote un `role="tabpanel"` ; tabulation itinérante (une seule position dans l'ordre de tabulation), ← → déplacent ET activent,
Début / Fin. La position choisie est gardée par la 73, pas par la 74. Le changement de vue n'est pas animé.

## 2. Frise

**Surface.** Une carte `--surface`, `--r-card`, `--shadow-card` (seule élévation), `padding var(--inset-card)`, dans la zone de contenu.
Toute teinte d'état de la frise se pose sur `--surface` (jamais sur `--raise`, `--raise-2` ni un fond `rgba(var(--ink), …)` : en clair
`--st-active` y tombe sous 3:1). Rendu des pistes : un `<svg>` purement graphique aux dimensions du conteneur, `aria-hidden`, nœuds créés par `createElementNS`, et par-dessus, dans le même cadre, une couche HTML superposée (`position: absolute`, hors du `svg`) qui porte tout ce qui est focalisable : le repère du curseur (`role="slider"`) et les boutons de commit. Les dimensions lisent les propriétés CSS ci-dessous (aucun nombre de géométrie en dur dans le script hors proportions temporelles).

**Géométrie, en jetons.** Propriétés locales dérivées des jetons existants (aucune valeur neuve) :
| Propriété | Valeur | Rôle |
|---|---|---|
| `--frise-voie` | `var(--sp-32)` ; 44 en `pointer: coarse` | hauteur d'une voie |
| `--frise-barre` | `var(--sp-8)` | épaisseur d'une barre, rayon `999px` |
| `--frise-glyphe` | `var(--sp-12)` | côté d'un événement (viewBox 16, mis à l'échelle) |
| `--frise-trait` | `var(--sp-2)` | trait fin et pointillé |
| `--frise-col` | 240 (dimension, comme `--panel-w`) ; 120 sous 700 px | colonne de gauche |
| `--frise-courbe` | `calc(var(--sp-24) * 2)` | hauteur du bandeau haut |
| `--frise-axe`, `--frise-depot` | `var(--sp-24)` | hauteur de l'axe, d'une sous-voie du Dépôt |
| marges de piste | gauche `--sp-8`, droite `--sp-16` | « maintenant » ne touche pas le bord |

Découpe d'une voie de 32 : 4 de marge, 12 de rail d'événements, 4 d'écart, 8 de barre, 4 de marge. Découpe de la voie de 44 (`pointer: coarse`) : 12 de marge, 12 de rail, 4 d'écart, 8 de barre, 8 de marge. Sous-voie du Dépôt : 24, et 44 en `pointer: coarse`. La barre est donc toujours sous
ses événements : un événement ne recouvre jamais un segment.

**Ordre vertical.** (1) barre d'outils, (2) ligne de synthèse et avis de troncature, (3) bandeau haut (courbe), (4) axe, (5) bandeau « Dépôt »,
(6) voies, (7) légende ; puis l'encart « À cet instant » (§ 3) et la section « Coût » (§ 5). Le bandeau haut et l'axe restent collés en haut
du corps quand les voies défilent verticalement, sur un fond `--surface` opaque (rien ne se lit à travers eux). Frise, encart et section « Coût » sont séparés par `--gap-section`.

**Barre d'outils.** Deux groupes de choix exclusifs (`role="radiogroup"`, `role="radio"` + `aria-checked`, ← → déplacent et choisissent),
même style que la bascule, hauteur 28 (44 coarse), légendés à gauche en 12,5 px `--text-3` : « Lecture » : « Horloge » (défaut), « Événements » ;
« Fenêtre » : « 1 h 30 » (défaut), « 6 h », « 24 h ». Rien au-delà de 24 h (AUDC-Q2). Changer de fenêtre ou de lecture ne déplace pas le curseur s'il reste dans la fenêtre ; si la nouvelle fenêtre l'exclut, le curseur est retiré et l'annonce dit « Le curseur est sorti de la fenêtre ».
**Aller-retour d'onglet (P74-D-55).** Les extensions de la 74 sont rejouées à chaque arrivée sur Équipe. La fenêtre (1 h 30, 6 h, 24 h) et la lecture (Horloge, Événements) survivent à un aller-retour : elles sont gardées en `sessionStorage` sous la clé `vibeflow-cockpit:frise-reglages`, jamais dans un fichier du lab, jamais exportées. Le curseur posé, la fiche ouverte, les dépliages et le défilement ne survivent pas : au retour, la frise est affichée, le curseur est à « maintenant » (aucun instant posé) et la fiche est fermée.

**Colonne de gauche** (une cellule de `--frise-voie` par voie, bouton pleine cellule, `background: transparent` dans tous les états). Rangée : glyphe d'état
actuel 16 (glyphes tirés de la table unique de la régie, Phase 73, ou à défaut de `GLYPHE` de `71-vf-equipe-rendu.js` : la frise n'a aucun jeu propre, P74-D-29), puis deux lignes : ligne 1 le nom
(12,5 px, 500, hauteur de ligne 16, `--text`, ellipsis, écrit une seule fois), ligne 2 (11,5 px, 400, hauteur de ligne 14, `--text-3`) « mot d'état · nœud id » pour un agent
rattaché (identifiant du nœud en mono), « mot d'état · rattaché par ses agents » pour un manager dont `rattachement.source` vaut `enfants` (aucun nœud écrit pour lui, P74-D-34), « mot d'état · tête · arbre principal » pour une session. Hauteurs : 16 + 14 dans les 32.
Le nom est celui de la régie (même fonction de nommage). Enfants : retrait `--sp-16` par niveau et fil vertical 1 px `--text-4` avec
coude de rayon `8px` vers chaque enfant (pas de `opacity` pour l'atténuer). Survol : le nom passe à `--text` et est souligné (jamais un fond) ; focus clavier : contour `2px solid var(--ring)`, `offset -2px`, sans fond. **Aucun fond n'est posé dans la colonne ni derrière les segments** : le glyphe d'état (teinte `--st-active`) reste toujours sur `--surface`. Un clic, Entrée ou Espace ouvre la fiche (P74-D-04).

**Ordre des voies.** Par heure du premier segment de l'arbre, stable (un nouvel arbre s'ajoute en bas) ; enfants sous leur parent, par
heure de dispatch. Une session vivante sans activité dans la fenêtre reste listée, au repos (P74-D-05). Un filet `--hair` sépare deux arbres.

**Couleur (P74-D-01, confirmée par P74-D-46).** La couleur dit l'état, jamais le nœud : le nom du nœud s'écrit en toutes lettres sur chaque voie.
Arbitrage Samuel, AskUserQuestion session principale, 2026-11-11, réponse « Suivre la règle de design (Recommandé) ». Aucune couleur par nœud (`DESIGN.md` § 9) ; le but du ROADMAP n'est pas réécrit (AUDC-V6).

**Segments (P74-D-06).** Lus dans `segments` de la voie (C3, genres `travail`, `attend-humain`, `attend-agents`, `repos`, `silence`), sur la ligne de la barre, une sorte par état, lisible sans la couleur. Le genre `silence` (aucun signe de vie) ne dessine rien : un blanc. Les quatre autres :
| État | Forme | Teinte |
|---|---|---|
| Au travail | barre pleine, hauteur `--frise-barre`, rayon `999px` | `--st-active` |
| Vous attend | même barre remplie du motif de hachures (SVG `<pattern>`, traits à 45°, épaisseur `--sp-2`, pas `--sp-6`, dérivés des jetons), **aucun contour** | `--st-active` |
| Attend ses agents | trait fin, épaisseur `--frise-trait`, extrémités rondes | `--text-3` (neutre) |
| Au repos | pointillé neutre (`stroke-dasharray: 0 var(--sp-8)`, extrémités rondes de `--frise-trait`) | `--text-4` |
Une erreur ne teinte jamais une voie (« échec » vient du réducteur, P74-D-48). Un segment commencé avant la fenêtre est coupé net à gauche (rayon 0 de ce côté) ; un segment en
cours finit sur le trait « maintenant ». `silence` : rien n'est dessiné (un blanc, distinct du repos, P74-D-36). Chaque segment porte un `title` « au travail, 14:02 à 14:40, 38 min » (durées vraies, même en lecture
Événements). Aucune bordure, aucun halo, aucun dégradé.

**Événements (P74-D-07).** Posés dans le rail du haut de la voie, `--frise-glyphe`, un seul rail :
| Événement | Glyphe | Teinte (portée par le glyphe seul) |
|---|---|---|
| Compaction | triangle vide | `--text-2` |
| Erreur d'outil | croix | `--sev-high` |
| Message de l'humain | point plein | `--text` |
| Rapport rendu | coche | `--recent` |
| Lancement d'un agent | trait vertical 1,5 px du parent à la voie de l'enfant | `--text-4` |
Deux événements à moins de `--sp-12` l'un de l'autre se confondent en un seul glyphe (priorité : erreur, compaction, rapport, message) suivi
de « +N » (mono 11,5 px, `--text-3`) : le compte est écrit, rien n'est agrégé en silence. Les événements ne sont pas focalisables un à un
(ils sont dans l'alternative textuelle, § 6 ; l'encart ne liste que l'état des voies, les nœuds et les fichiers) ; leur `title` dit l'événement et l'heure.

**Bandeau haut.** Colonne de gauche : « Agents au travail » puis « jusqu'à 4 en même temps sur 1 h 30 » (la fenêtre est toujours écrite). Piste : courbe en escalier du nombre
d'agents au travail, remplie `--raise-2` (neutre), trait supérieur 1,5 px `--text-3`, échelle 0 à max(4, pic). Pas de teinte, pas de
courbe de coût. `aria-hidden` ; le maximum est dit dans la colonne.

**Bandeau « Dépôt » (P74-D-07).** Colonne : « Dépôt » puis « 7 commits sur 1 h 30 ». Source : la route Git existante (`vibeflow/cockpit-git@1`), jamais la route de frise ; `rangees[].at` est en secondes Unix, converti en millisecondes pour l'axe (P74-D-33). La route Git se lit au montage puis sur `VF_ETAT.abonner('git')`, jamais au rythme de l'événement `frise` (P74-D-50). La marche de la route est bornée à 500 commits et topologique : le plus ancien commit lu ne borne rien seul. Quand la marche est tronquée et que le plus récent des instants entre le plus ancien commit lu et la plus récente rangée dont un parent n'a pas été lu (secondes × 1000) tombe dans la fenêtre, la colonne ajoute une ligne 12,5 px `--text-3` « Dépôt peut-être incomplet avant 14 h 05 » (cette heure) et un filet vertical `--hair-2` à cet instant sur les sous-voies ; aucun commit n'est dessiné avant lui. Une sous-voie de `--frise-depot` par branche (nom mono 11,5 px
`--text-3`, ellipsis), 4 branches visibles puis « + N branches » (bouton `aria-expanded`, `aria-label` « Afficher les N autres branches du dépôt » puis « Replier les branches du dépôt », même mécanique de repli qu'ailleurs ; il entre dans l'ordre de tabulation, après les commits). Dernière sous-voie : « Autres commits (branches fusionnées ou sans nom) », qui reçoit les commits atteints par aucune branche (descente du premier parent : la chaîne de la base d'abord, puis les branches locales, puis les distantes) ; jamais pliée, comptée : seconde ligne en mono 11,5 px `--text-3` « 12 commits » (« 1 commit »). Commit : losange plein
`--frise-glyphe` en `--text-2` (`--recent` est réservé à la coche du rapport rendu), bouton HTML superposé de 24 × 24 (44 en coarse), `aria-label` « Commit a1b2c3d, branche feat/x, 14 h 32. Ouvrir dans le
tiroir Git ». Clic ou Entrée passe UNIQUEMENT par `window.VFGitTiroir.ouvrirSur(sha)`, l'entrée publique de la Phase 80 (80-06), qui rend une promesse : `true` si le détail est affiché, `false` si le SHA est invalide ou introuvable, jamais d'exception ; si `false`, rien d'autre ne se passe que l'annonce de la région `aria-live="polite"` unique « Ce commit n'est pas disponible dans le tiroir Git. » (aucun message visuel) ; si `window.VFGitTiroir.ouvrirSur` est absent, les commits sont des repères non interactifs (aucun bouton, hors de l'ordre de tabulation, `aria-label` sans « Ouvrir dans le tiroir Git ») (les autres appels du tiroir et du volet sont internes à la 80, interdits à la 74) ; aucune insertion sous la rangée, et la 74 ne modifie plus `ui/77-vf-git-vue-detail.js` (P74-D-50, amende D-40). Les commits sont rangés par branche côté page, en descendant le premier parent depuis chaque branche. Jamais rattaché à une voie. Deux commits à moins de `--sp-12` :
un losange et le nombre (« 3 »), un seul bouton par commit ou par groupe, qui ouvre le plus récent ; son `aria-label` liste tous les commits du groupe (« 3 commits, de 14 h 30 à 14 h 32, branche feat/x : a1b2c3d, d4e5f6a, 9b8c7d6. Ouvrir le plus récent dans le tiroir Git »). Sur la ligne « Autres commits », donc sans branche : « Commit a1b2c3d, 14 h 32. Ouvrir dans le tiroir Git » et, pour un groupe, « 3 commits, de 14 h 30 à 14 h 32 : a1b2c3d, d4e5f6a, 9b8c7d6. Ouvrir le plus récent dans le tiroir Git ».

**États du bandeau « Dépôt » (P74-D-50).** Chaque état est propre au bandeau : le reste de la frise continue.
| État | Rendu |
|---|---|
| Chargement | `aria-busy="true"` sur le bandeau, texte 12,5 px `--text-3` « Lecture du dépôt » à la place des sous-voies |
| Échec | texte « Le dépôt n'a pas pu être lu. » (12,5 px `--text-3`) et bouton « Réessayer » (nouvelle lecture GET de la route Git) ; la colonne dit « Dépôt » seule, sans compte |
| Vide | aucun commit sur la fenêtre : texte « Aucun commit sur 1 h 30 » (la fenêtre de la frise, « 6 h », « 24 h ») ; aucune sous-voie |
La liste `.sr` rend ces trois états par l'élément « Dépôt » (« Lecture du dépôt », « Le dépôt n'a pas pu être lu. », « Aucun commit sur 1 h 30 »).

**Axe et « maintenant ».** Graduations : 1 h 30 toutes les 15 min, 6 h toutes les heures, 24 h toutes les 4 h, étiquettes mono 11,5 px
`--text-3` « 14:15 » ; un trait de graduation vertical `--hair` traverse les voies. Passage de minuit : étiquette de date (« 12 nov. »).
Trait « maintenant » : 1 px, `stroke-dasharray: var(--sp-4) var(--sp-4)`, `--text-3`, étiquette « maintenant » à droite de l'axe ; il avance à chaque lecture de la frise,
sans transition. Le curseur (§ 3) est un trait plein : forme distincte, jamais confondue.

**Lecture « Événements » (P74-D-09).** Un silence (aucune voie au travail, aucun événement) de plus de 2 min est raccourci en un repère de
largeur fixe `calc(var(--sp-32) + var(--sp-8))` : deux filets verticaux `--hair-2` et, dans l'axe, la durée vraie (« 14 min », mono 11,5 px, `--text-3`, 4,5:1 sur `--surface`).
La cellule d'axe de la colonne dit « Événements, silences raccourcis » ; en Horloge elle dit « Horloge ». Les graduations de cette lecture
sont les heures réelles au début de chaque tronçon. Les segments restent à l'échelle de leur tronçon, mais l'axe n'est plus linéaire : aucune durée
ne se lit à la longueur (le `title` des segments reste vrai). Le curseur posé dans un repère se cale sur le bord le plus proche.

**Repli (P74-D-10).** Seuil confirmé : 12 voies visibles. Au-delà, les workers d'un manager se replient (managers les plus peuplés
d'abord, tout ou rien par manager) en une ligne « + 7 agents » (bouton, `aria-expanded`, `aria-label` « Afficher les 7 agents de vf-dev-manager »),
dépliable ; la ligne dit le nombre au travail « maintenant ». Si 12 voies ne suffisent pas après repli, le corps des voies défile
verticalement (bandeau haut et axe collés) et la synthèse écrit « 18 voies, 12 repliées ». Les pistes d'une ligne repliée restent vides.

**Lignes sous la synthèse (ordre, P74-D-52).** Dans cet ordre, chacune en 12,5 px `--text-3`, séparées de `--sp-4`, seulement quand elles s'appliquent : (1) la ligne de source (« Lecture des traces en cours : … » ou « Certaines traces n'ont pas pu être lues : … »), (2) la réponse tronquée, (3) la mission tronquée (« … commencées avant la fenêtre … »).

**Réponse tronquée (P74-D-52).** Quand `tronque` est vrai (dont la coupe à 500 voies), une ligne 12,5 px `--text-3` sous la synthèse dit : « N voies ne sont pas montrées : la lecture est tronquée. » (N = `voiesOmises`, le nombre de voies retirées par la borne de 500, entier ≥ 1 ; « 1 voie n'est pas montrée : la lecture est tronquée. » ; si `voiesOmises` n'est pas un entier ≥ 1 : « Des voies ne sont pas montrées : la lecture est tronquée. ») ; les totaux de coût disent « incomplet » (§ 5). `arbre` absent ou nul désigne l'arbre principal : aucun libellé « inconnu » (colonne de gauche, fiche, tableau).

**Mission tronquée (P74-D-08).** Segments coupés à gauche (ci-dessus) et, en troisième ligne sous la synthèse (ordre ci-dessus), une ligne 12,5 px `--text-3` quand au moins une voie est
concernée : « 3 voies commencées avant la fenêtre : elles sont coupées à gauche. » (« 1 voie … : elle est coupée à gauche. »).

**Légende** (sous les voies, une ligne qui passe à la suivante, 12,5 px `--text-3`, échantillons SVG de 24 × 8 dessinés comme les segments) :
« Au travail », « Vous attend », « Attend ses agents », « Au repos » ; puis les glyphes : « Compaction », « Erreur d'outil », « Message de
l'humain », « Rapport rendu », « Commit », « Lancement d'un agent ».

**Téléphone (≤ 700 px, ou tactile sous 1 279 px).** Colonne de gauche collante de 120, pistes dans un conteneur à défilement horizontal propre (largeur minimale 480), page sans défilement horizontal. Au chargement et à chaque changement de fenêtre, le conteneur est défilé tout à droite : « maintenant » est visible. Un toucher dans les pistes pose le curseur ; un glissement fait défiler (`touch-action: pan-x pan-y`) et ne pose rien ; le curseur se déplace en glissant son repère de 44 × 44 (`touch-action: none`). Voies de 44, sous-voies du Dépôt de 44.

**États de la frise.**
| État | Rendu |
|---|---|
| Chargement (au-delà de 150 ms) | `aria-busy="true"` ; trois voies fantômes de `--frise-voie` en `--raise`, sans balayage ; texte « Lecture de la frise » |
| En construction (`source.etat` = `en-construction`) | les voies déjà connues sont dessinées ; ligne neutre 12,5 px `--text-3` sous la synthèse : « Lecture des traces en cours : la frise peut être incomplète. » |
| Partielle (`partielle`) | frise dessinée ; même ligne : « Certaines traces n'ont pas pu être lues : la frise est partielle. » |
| Forme inconnue (`forme-inconnue`) | pas de voies ; carte d'état comme « Indisponible » (titre en `--text`), titre « La frise ne se lit pas », cause « Le format des traces a changé. Mettez VibeFlow à jour. », sans « Réessayer » |
| Indisponible (`indisponible`, ou 503, ou délai, ou 400 `bornes-invalides`) | carte ci-dessous |
| Vide (aucune voie) | titre 15 px 600 « Rien à raconter sur cette fenêtre » ; ligne 12,5 px `--text-3` « Aucune session ni aucun agent n'a été vu sur les dernières 1 h 30. Essayez une fenêtre plus large. » (à 24 h : « … sur les dernières 24 h. » sans la dernière phrase, il n'y a pas de fenêtre plus large) ; la barre d'outils reste active |
| Indisponible | carte `--warn-bg`, `--r-ctl`, `--inset-box` ; titre « La frise est indisponible » (13 px, 600, `--text`) ; cause « La lecture des traces locales a échoué ou dépassé le délai. » ; bouton « Réessayer » (lecture GET) ; le reste de l'onglet continue |
| Synthèse, encart et coût selon l'état | voir le paragraphe « Par état de source » sous ce tableau |
| Direct | abonnement `VF_ETAT.abonner('frise', …)` : l'événement `frise` (signature seule) déclenche une relecture authentifiée de `GET /api/vf/frise` (P74-D-11), `depuis` et `jusqua` suivant la fenêtre ; aucune donnée de frise dans le flux : les voies se remplacent sans fondu, défilement, curseur et dépliages conservés par identifiant d'agent ; annonce `aria-live="polite"` « Frise mise à jour » au plus une fois par minute. Le focus survit à la relecture : l'élément focalisé est retrouvé par son identifiant (`data-id` : agent, sha de commit, manager d'un repli, repère du curseur) ; s'il a disparu, le focus va à la voie du parent, sinon au repère du curseur |

**Par état de source (synthèse, encart, coût).** *Indisponible, forme inconnue* : la carte d'état remplace les voies ; la ligne de synthèse n'est pas écrite ; l'encart dit en une ligne 12,5 px `--text-3` « Aucun instant à relire : la frise n'est pas lue. » ; la section « Coût » est omise (ni tableau ni « Total ») et le lien « Détail du coût » est absent ; la barre d'outils reste active. *Vide* : la synthèse dit « Sur les dernières 1 h 30 : aucun agent vu. » ; l'encart dit « Aucun instant à relire : aucune voie sur cette fenêtre. » ; la section « Coût » est omise (un « Total » de zéro serait un chiffre inventé : règle « inconnu, jamais zéro ») et « Détail du coût » est absent. *En construction, partielle* : synthèse, encart et coût sont rendus avec leur ligne de source ; quand `tronque` est vrai, la ligne « Total » dit « Total (incomplet) » (§ 5).

## 3. Curseur et encart « À cet instant » (P74-D-12, D-13, D-14)

**Curseur.** Sans curseur posé, le repère (poignée verticale arrondie de `--sp-4` de large et de `--frise-axe` de haut, `--text`, rayon `999px`, couche HTML, forme distincte du losange des commits) est déjà visible et focalisable, rangé sur « maintenant » ; aucun trait ne traverse les pistes. Posé : trait plein 1,5 px `--text-2` sur toute la hauteur des pistes. Zone de saisie du repère : 24 × 24 au pointeur fin (contour de focus `2px solid var(--ring)`, `offset 2px`), 44 × 44 en `pointer: coarse`. Poser :
clic (pointeur) dans la zone des segments, du bandeau Dépôt ou de la courbe ; glisser avec le pointeur ; au survol sans clic seul un trait
de repère `--hair-2` et l'heure en `title` suivent le pointeur (l'encart ne bouge pas). Hors fenêtre : si l'instant sort de la fenêtre par la gauche
(frise en direct), le curseur est retiré et l'annonce dit « Le curseur est sorti de la fenêtre ».

**Clavier.** Le repère de l'axe est un `role="slider"`, un seul arrêt de tabulation, nommé « Curseur de la frise », `aria-controls` (l'encart « À cet instant »), `aria-valuemin` /
`aria-valuemax` / `aria-valuenow` en secondes depuis le début de la fenêtre, valeur initiale = `aria-valuemax` (« maintenant »), `aria-valuetext` « 14 h 32 » (« maintenant, aucun instant posé »
tant qu'il n'est pas posé). Au départ seule ← agit (elle pose le curseur un pas avant « maintenant » ; → ne fait rien) ; Début pose au début de la fenêtre. ← → : un pas = 1/90 de la fenêtre (1 min, 4 min, 16 min) ; Maj + flèche : dix pas ; Début pose le curseur au début de la
fenêtre ; Fin retire le curseur et rend le repère à « maintenant » (`aria-valuenow` = `aria-valuemax`, `aria-valuetext` « maintenant, aucun instant posé ») ; Échap (P74-D-53) est écouté en remontée, sur `document` ou la racine de la vue, jamais en capture ni sur `window` : un appui dont `defaultPrevented` est vrai est ignoré (une surcouche vient d'être fermée), sinon, le focus étant sur le repère, il retire le curseur ; la vue ne lit jamais `VF_SURCOUCHES.ouverte()`. À la pose, un résumé est annoncé dans la région `aria-live="polite"` unique : « 14 h 32 : 3 voies au travail, 2 nœuds portés. » En lecture Événements, ← → sautent à l'événement ou à la frontière de segment précédent
ou suivant. Le repère est dans la couche HTML (jamais sous `aria-hidden`).

**Encart « À cet instant ».** Sous la frise, pleine largeur, fond `--surface` séparé par un filet `--hair` (pas de boîte teintée : les glyphes
d'état y restent sur `--surface`). Sans curseur : une ligne 12,5 px `--text-3` « Cliquez dans la frise ou utilisez les flèches du repère pour relire un
instant. » Avec curseur : titre `h3` 15 px 600 « À cet instant, 14 h 32 » et, à droite, bouton « Retirer le curseur » (28, 44 coarse). Trois groupes
en colonnes (≥ 1 000 px), empilés en dessous, intertitres 12,5 px 500 `--text-3` :
1. « Les voies » : une ligne par voie (glyphe, nom, mot d'état à t : « au travail », « vous attend », « attend ses agents », « au repos »,
   « pas encore lancé », « terminé ») ; suffixe « · déduit » en `--text-3` pour l'état présent d'une voie dont `etatOfficiel` est nul (état tiré des segments) ; tout état à un instant passé est tiré des segments et se lit sans suffixe (P74-D-23, D-39 : les segments ne disent pas leur provenance).
2. « Nœuds du plan portés » : par nœud, id mono + l'état de la voie qui porte le nœud (P74-D-49), en quatre formulations : « porté par vf-coder, au travail », « porté par vf-coder, vous attend », « porté par vf-coder, attend ses agents », « porté par vf-coder, au repos » ; chaque id est un lien
   vers sa carte de mission. Une ligne de bilan « 6 autres nœuds du plan : aucun agent ». Un manager rattaché par ses agents n'a pas de ligne ici (aucun nœud). Note 12,5 px `--text-3` : « L'état du plan est déduit
   des voies des agents, il n'est pas rejoué. » (P74-D-13 : jamais `ready` ni `blocked`).
3. « Fichiers écrits autour de cet instant » : jusqu'à 8 chemins (mono 11,5 px, ellipsis à gauche), puis « et 4 autres » ; vide : « Aucun fichier écrit à
   cet instant. » « Autour de t » = ± δ, δ = max(2 min, pas du curseur / 2) (P74-D-49). Sont cherchées, dans l'ordre de la frise (de haut en bas), les voies dont le travail recoupe la plage dans [t − δ, t + δ] ; le premier filtre est `cibles[].dernierMs` (dans la fenêtre : écrit ; avant : non écrit ; après : incertain, et seul ce cas lit le fil réduit, `cockpit-transcript@2`). **Lecture 250 ms après le dernier déplacement du curseur ou au relâché**, jamais à chaque pas ; au plus deux lectures en vol et six par instant, cache par (voie, `fin`) gardé tant que `fin` ne bouge pas (P74-D-35 amendée). Une cible du fil réduit de forme « <chemin> (worktree <nom>) » s'affiche telle quelle ; une cible coupée (finissant par « … », avant un éventuel suffixe de worktree) est listée telle quelle et n'entre dans aucune mise en évidence. **Liste partielle** : au-delà de six voies à lire, la liste montre les fichiers des voies lues et une ligne **sous la liste**, 12,5 px `--text-3`, dit « N voies non lues » (« 1 voie non lue » ; jamais six lectures jetées, jamais la liste entière remplacée). La cause vaut **par voie** : une voie dont le fil est tronqué et dont le premier élément est après t − δ (50 messages, 200 outils) compte dans « N voies non lues ». La phrase « Fichiers non relus : cet instant est plus ancien que l'historique conservé pour cet agent. » ne remplace la liste que si AUCUNE voie ne donne de fichier. Pendant la lecture : `aria-busy="true"` et « Lecture des fichiers » (12,5 px `--text-3`). Si une lecture échoue : « Les fichiers n'ont pas pu être lus. » et bouton « Réessayer » (nouvelle lecture des fils concernés). Bouton « Voir sur la carte » (`.btn.soft`, `aria-label` « Voir ces 8 fichiers
   sur la carte », 8 = nombre de fichiers mis en évidence), présent si et seulement si au moins une cible est posable (une cible coupée ne l'est pas) : il ouvre l'onglet Code, tel que la coquille l'expose, avec ces fichiers mis en évidence (mise en évidence ponctuelle, P74-D-12 et D-37).

## 4. Fiche d'agent, lecteur plein cadre (P74-D-03, D-04, D-15 à D-19)

**Surface.** Une vue qui prend la zone de contenu de l'onglet Équipe (`--surface`, `--r-card`, `--shadow-card`), jamais un tiroir, jamais
au-dessus d'un autre onglet. Ouverture : fondu de 200 ms `--ease` (`prefers-reduced-motion: reduce` : aucune animation), fermeture immédiate.
`role="region"` nommé « Fiche de <nom> » ; à l'ouverture le focus va sur le titre (`tabindex="-1"`). Aucune adresse dans l'URL. Une session
et un sous-agent ont la même fiche ; pour une session, ni intertitre ni ligne « Mandat ».
**En-tête** (`--inset-panel`) : bouton « Retour à la frise » (ou « Retour à la régie » selon l'origine ; 36, 44 coarse, icône flèche
`svg.i`), puis titre `h2` 20 px 600 (le nom, écrit une fois), puis la ligne de rattachement 12,5 px `--text-2` :
« Worker de [vf-dev-manager] · nœud [exec-lot-a] · [Phase 73] ». Chaque terme entre crochets est un lien souligné (jamais la pastille) : fiche
du parent (la vue se remplace, le focus va au titre, « Retour » ramène toujours à la vue d'origine), carte de mission, phase. Session : « Session · arbre
principal · branche feat/x ». Non rattaché : « Pas lié à une phase du projet » ; ambigu : « Non rattaché (ambigu) ». Jamais un lien deviné.
**Ouverture et fermeture.** Depuis une voie de la frise ou une ligne de la régie (même fonction, avec l'élément d'origine). Échap ou « Retour » ferme ; la fiche et le lecteur sont des vues de l'onglet Équipe, pas des surcouches (P74-D-44) : elles ne s'inscrivent pas dans `window.VF_SURCOUCHES`. **Échap** (P74-D-53) s'écoute en phase de remontée, sur `document` ou la racine de la vue, jamais en capture ni sur `window` ; un appui dont `event.defaultPrevented` est vrai (une surcouche vient d'être fermée par la pile) est ignoré ; sinon il ferme la fiche et rend le focus à l'ouvreur (`declencheur` quand la fiche vient de la régie). La vue ne lit jamais `VF_SURCOUCHES.ouverte()`. Une éventuelle surcouche de la 74 passe par `VF_SURCOUCHES.ouvrir(el, { modale, ouvreur, fermer })` ; si l'ouvreur a disparu, le focus va à la voie du même agent, sinon au premier élément focalisable de la vue d'origine. Pendant que la fiche est ouverte, la vue d'origine reste dans le DOM, `hidden` et `inert` : son état (fenêtre, lecture, curseur, défilement, dépliages, filtres de la régie) est conservé et rendu intact au retour ; elle continue de se mettre à jour en tâche de fond.

**Deux colonnes** (au-dessus de 999 px : faits `minmax(280px, 360px)` puis fil `1fr`, gap `--gap-section` ; de 700 à 999 px : faits 280 ;
points de rupture inchangés, Q11). Les deux colonnes ont chacune leur défilement vertical sur toute la hauteur de la zone ; aucune boîte de
hauteur fixe n'en contient une autre. Chaque colonne défilante est `role="region"`, `tabindex="0"` et nommée (« Faits de <nom> », « Fil de <nom> ») pour se défiler au clavier.

**Colonne des faits** (fond `--surface`, `--inset-panel`). Sous-titre 12,5 px `--text-3` « Sur les dernières 24 h » (le libellé de fenêtre est toujours
écrit). La fiche lit la route de frise une fois sur 24 h, quelle que soit la fenêtre de la frise : ses faits sont identiques de 1 h 30 à 24 h. Identité en `dl` : « Rôle », « Nœud du plan » (« rattaché par ses agents » pour un manager, P74-D-34 ; la ligne de rattachement dit alors « Manager · rattaché par ses agents · [Phase 73] »), « Arbre », « Branche », « Modèle » (12,5 px, valeur mono pour nœud, arbre, branche). Puis **six chiffres** en grille de
deux colonnes, libellé 12,5 px / 16 `--text-3` au-dessus, valeur 15 px / 600 / 20 `--text` en chiffres tabulaires :
| Libellé | Valeur | Remarque |
|---|---|---|
| « Au travail » | « 2 h 14 » | `durees.travailS`, somme des segments (P74-D-26), jamais `dureeS` |
| « À vous attendre » | « 18 min » | `durees.attenteHumainS`, somme de segments passés : jamais de mention « déduit » (P74-D-39) |
| « Contexte au dernier tour » | « 168 k jetons » | `jetons.contexteDernier`, toujours en jetons, jamais en pourcentage (aucune taille de fenêtre documentée, P74-D-16) ; `contexteMax` n'est pas affiché |
| « Compactions » | « 3 » | `compteurs.compactions`, comptées seulement, sans taille |
| « Appels d'outil » | « 214 » | `compteurs.appels` |
| « En échec » | « 6 » | `compteurs.erreurs` |
Deux blocs de lignes en dessous : « Jetons » (« Entrée », « Sortie », « Cache lu », « Cache écrit », valeur à droite, mono 11,5 px, 16) et « Fichiers » (« Écrits »,
« Lus »), lus dans `cibles`, comptés par couple (`arbre`, `cible`) ; `cibles.tronque` est un seul drapeau par voie (A48 point 45 de la 79) : « 200 ou plus » ne s'applique qu'au compte dont la liste compte exactement 200 entrées, l'autre compte (écrits ou lus) reste exact ; un fichier d'un worktree s'affiche « <chemin> (worktree <nom>) » (mono), un fichier de l'arbre principal (`arbre` absent ou nul) sans suffixe ; tant que `cibles.etat` vaut `en-construction`, la valeur est « en cours de lecture » (ni zéro ni « inconnu »). Une donnée que la source ne donne pas s'écrit « inconnu » (`--text-3`, même gabarit que la valeur) : jamais un zéro. Aucune action sur la
session, aucun coût en devise, aucune dernière commande.
**États des faits.** Chargement : `aria-busy="true"` et « Lecture des faits » ; échec : « Les faits sont indisponibles. » et bouton « Réessayer » (nouvelle lecture de la route de frise). L'événement `frise` relance, via `VF_ETAT.lireJson()`, la lecture des faits et du fil de la fiche ouverte (le fil gagne ses nouvelles lignes, voir « Direct »).
**Téléphone (≤ 700 px, 390 px visé).** Une colonne ; sous l'en-tête, les faits sont repliés dans un `<details>` « Faits de l'agent » (résumé de 44 de haut :
état et durée au travail), fermé par défaut ; le fil vient dessous et la zone défile en un seul bloc (pas de hauteur propre du fil).

**Colonne du fil** (P74-D-17). En-tête : titre `h3` « Fil », compteur 12,5 px `--text-3` « 34 lignes sur 120 » (filtres actifs), puis trois filtres
cumulables, boutons-bascule (`aria-pressed`), pilule `999px`, 28 de haut (44 coarse), 11,5 px / 500 : « Messages » (messages de l'agent et de l'humain), « Outils » (lignes d'outil), « Erreurs » (lignes `echec`). Les lignes de compaction ne sont couvertes que par l'absence de filtre. Aucun enfoncé : tout est
montré ; enfoncés, ils se cumulent (union). Enfoncé : fond `--on`, texte `--on-text` et coche 12 devant le mot (la forme double la couleur) ; sinon
fond `rgba(var(--ink), .06)`, texte `--text-2`.
**Ligne** : grille heure (mono 11,5 px / 16 `--text-3`, « 14:32:10 », colonne `--sp-24` × 3 en `calc`), glyphe 16 (`svg.i`), texte 12,5 px / 20 `--text`.
Le fil garde ses lignes « Compaction » et « Message de l'humain » (rendu inchangé : ligne `humain`, heure seule, sans texte ; ligne `compaction`, heure seule). Leur source change (P74-D-48) : elles sont fusionnées côté page depuis les `evenements` de la voie, bornées au plus ancien horodatage du fil, et non plus produites par le réducteur ; « échec » (`echec: true`) vient seul du réducteur. Glyphes : message de l'agent deux traits, message de l'humain point plein, compaction triangle vide, outil chevron, échec croix (`--sev-high`, le seul glyphe teinté du
fil). Outil : verbe et cible réduite (« modifie vf-cockpit-equipe.mjs », mono pour la cible), « × 4 » si regroupé ; une ligne d'outil
portant `echec: true` ajoute « échec » en `--text-2` après la cible, jamais le texte de l'erreur (P74-D-19, seul le drapeau est lu). Aucun commit n'est attribué à un agent dans le fil. Survol : fond `rgba(var(--ink), .06)` sauf sur les lignes `echec` (aucun fond : la croix `--sev-high` reste sur `--surface`) ; ces lignes marquent le survol par l'heure en `--text`.
**Message.** Rendu en texte par un sous-ensemble fermé (P74-D-18) : paragraphes, listes, code en ligne, blocs de code, emphase, construits en
nœuds DOM avec `textContent` ; un lien s'écrit « libellé (adresse) », non cliquable ; tout autre balisage s'écrit tel quel, en texte. Code en
ligne : mono 11,5 px, `padding var(--sp-2) var(--sp-6)`, fond `rgba(var(--ink), .05)`, rayon `999px` ; bloc de code : `--well`, `--r-ctl`, `--inset-row`,
`white-space: pre-wrap`, `overflow-wrap: anywhere` (pas de défilement horizontal). Au-delà de 6 lignes, le message est replié avec un bouton
« Afficher tout le message » / « Réduire le message » (`aria-expanded`).
**Mandat** (sous-agent seulement) : première ligne du fil, bouton « Afficher le mandat » / « Replier le mandat » (`aria-expanded`), contenu en
`pre-wrap` sur `--well`, sans hauteur maximale. **Coupe dite** : en tête du fil, 12,5 px `--text-3`, « Plus ancien que la fenêtre lue. Seuls les 50 derniers
messages et les 200 derniers appels d'outil sont affichés. »
**Direct.** Le suivi se mesure sur le conteneur qui défile : la colonne du fil sur ordinateur, la zone de contenu sur téléphone. Tant que ce conteneur est à moins de `--sp-24` du bas, il y reste collé à chaque nouvelle ligne. Dès que l'utilisateur remonte, le suivi
s'arrête et un bouton « Revenir au direct » (pilule `--on` / `--on-text`, 28, 44 coarse, `position: sticky`, collé au bas de la zone visible du conteneur à `--sp-16` du bord) apparaît avec,
quand il y en a, « 3 nouvelles lignes » (région `aria-live="polite"`, une annonce par rafale) ; l'activer remet le fil en bas d'un saut immédiat (aucun défilement animé). Jamais d'export du fil.
**États du fil.** Chargement : trois lignes fantômes, « Lecture du fil ». Vide : « Aucune ligne dans le fil. » Filtres sans résultat : « Aucune ligne ne
correspond aux filtres. » + bouton « Tout afficher ». Hors fenêtre : « Cet agent n'est plus dans la fenêtre de 24 h : rien à montrer. » Erreur : « Le fil est
indisponible. » + « Réessayer ».

## 5. Coût (P74-D-20 à D-23)

**Où il se lit.** (a) Dans la fiche : jetons et durées de l'agent (§ 4). (b) Dans l'en-tête de frise : la ligne de synthèse, 12,5 px / 16 `--text-2`, chiffres
en `--text` 500 : « Sur les dernières 1 h 30 : 4 agents au travail maintenant, 3 h 12 au travail dont 25 min à vous attendre. Jetons sur les dernières 24 h : 420 k en entrée, 96 k en
sortie. » suivie du lien souligné « Détail du coût ». (c) Dans la section « Coût » sous l'encart.
**Section « Coût ».** Intertitre `h3` 15 px 600 dynamique « Coût sur les dernières <fenêtre> » (« 1 h 30 », « 6 h » ou « 24 h » selon la fenêtre de la frise ; jamais omise, jamais « de la phase »), cible du lien « Détail du coût » (`tabindex="-1"`, le focus y est posé, défilement immédiat), sous-titre
12,5 px `--text-3` « Durées lues sur la fenêtre, jetons sur les dernières 24 h (horizon de l'index). Rien n'est estimé. » Choix « Regrouper par » (radiogroup, style de la barre
d'outils) : « Agent », « Mission et phase » (défaut), « Étage ». Tableau `<table>` avec `<caption>` (le titre), colonnes « Au travail », « À vous attendre »,
« Entrée », « Sortie », « Cache lu », « Cache écrit » (en-têtes 11,5 px / 14 `--text-3`, valeurs 12,5 px / 16, chiffres tabulaires alignés à droite), lignes séparées par un
filet `--hair`, `--inset-row`. « Mission et phase » : une ligne par mission (bouton qui déplie ses phases, `aria-expanded`), phases en retrait `--sp-16` ;
« Étage » : « Têtes » (voies de genre session), « Managers » (sous-agent ayant au moins une voie enfant), « Workers » (sous-agent sans voie enfant) ; la profondeur seule ne classe jamais (P74-D-42). Chaque regroupement finit par une ligne « Total » (jamais d'un tableau vide : la section est alors omise, § 2) ; quand `tronque` est vrai (§ 2, P74-D-52), la ligne « Total » dit « Total (incomplet) » et un `title` le précise. « Hors mission » existe dans « Mission et phase » : dernière ligne de niveau mission, jamais découpée par phase, jamais répartie, note 12,5 px `--text-3` « agents sans nœud de plan rattaché » ; un manager rattaché par ses agents compte dans sa mission et sa phase (P74-D-34, jointure par `phaseKey`). Dans « Agent » et « Étage », les agents hors mission figurent à leur place, leur seconde ligne dit « hors mission » ; « Total » vaut la somme des lignes et la même valeur dans les trois regroupements. Tri fixe : « Au travail » décroissant. Les jetons de C3 sont des totaux de l'index sur 24 h, non découpés par la fenêtre : les quatre colonnes de jetons sont coiffées de « Jetons, sur les dernières 24 h », les deux colonnes de durée de la fenêtre (durées coupées à la fenêtre par le serveur) ; sont comptés les agents vus dans la fenêtre. Aucune barre, aucune teinte, aucun total en devise.
**Téléphone.** Chaque ligne devient un bloc (nom, puis liste de définitions sur deux colonnes) ; pas de défilement horizontal.
**Formats (fr).** Jetons : < 1 000 « 842 » ; < 100 000 « 12,4 k » (une décimale) ; < 1 000 000 « 168 k » ; au-delà « 1,8 M » ; « jetons » suit quand il n'y a
pas d'autre libellé ; décimale à virgule, espace insécable avant « k » et « M ». Comptes : séparateur de milliers en espace insécable (« 1 204 »).
Durées : < 90 s « 45 s » ; < 1 h « 12 min » ; ≥ 1 h « 2 h 14 » (minutes sur deux chiffres : « 2 h 05 ») ; jamais de jours dans la 74 (fenêtre de 24 h). Heures
d'axe et de fil : « 14:32 », « 14:32:10 » (mono) ; dans une phrase : « 14 h 32 ».

## 6. Accessibilité

- **Contrastes** : texte ≥ 4,5:1 dans les deux thèmes (`--text-3` pour les étiquettes d'axe et d'encart ; `--text-4` réservé aux traits et aux pointillés,
  jamais à du texte porteur) ; glyphes, traits et barres ≥ 3:1 sur `--surface` (`--st-active`, `--recent`, `--sev-high`, `--text-3`, `--text-4`) : à mesurer
  au rendu, clair et sombre ; aucune teinte d'état sur `--raise`, `--raise-2` ni sur un fond de survol.
- **Rôles** : bascule `tablist` / `tab` / `tabpanel` ; sélecteurs de lecture, de fenêtre et de regroupement `radiogroup` / `radio` ; curseur `slider` (couche HTML) ; voies
  en `list` de boutons ; dépliages `button` + `aria-expanded` ; filtres `aria-pressed` ; fiche `region` nommée ; une région `aria-live="polite"` unique pour
  « Frise mise à jour », « Le curseur est sorti de la fenêtre » et « N nouvelles lignes ».
- **Ordre de tabulation = ordre de lecture = ordre du DOM** : bascule, lecture, fenêtre, « Détail du coût » (cible : le titre de la section « Coût », focus posé dessus), repère du curseur, commits du Dépôt, « + N branches », voies de haut en bas (avec leurs « + N agents »), « Réessayer » éventuel, « Retirer le curseur », liens de nœuds, « Voir sur la carte », regroupement, dépliages et tableau du coût. Dans la fiche : « Retour », liens de rattachement, faits repliés (téléphone), colonne des faits, colonne du fil (`tabindex="0"`), filtres, mandat, messages repliés, « Revenir au direct ». Pas de piège à focus : la fiche n'est pas une modale. Les colonnes et conteneurs défilants (faits, fil, corps des voies, pistes sur téléphone nommées « Frise, défilement horizontal ») sont `tabindex="0"` et nommés.
- **Focus** : `outline: 2px solid var(--ring)`, `offset 2px` hors cellules, `-2px` dans la colonne de gauche et les lignes ; jamais supprimé.
- **Alternative textuelle de la frise** : les pistes sont `aria-hidden` ; une liste `.sr` suit la frise, un élément par voie (« Session principale, au repos »
  puis une sous-liste « de 14 h 02 à 14 h 40, au travail », « 14 h 12, erreur d'outil »…) et un élément « Dépôt » (« 14 h 32, commit a1b2c3d, branche feat/x » ; ses états : « Lecture du dépôt », « Le dépôt n'a pas pu être lu. », « Aucun commit sur 1 h 30 »).
  Titre `h3` `.sr` « Frise en liste, sur les dernières 1 h 30, lecture horloge ». Elle suit la fenêtre et n'est jamais tronquée par le repli visuel.
- **Cibles** : ≥ 44 en `pointer: coarse` (voies 44, boutons, commits, filtres, poignée du repère 44 × 44).
- **Mouvement** : seules animations, fondu d'ouverture de la fiche (200 ms) et pivot de chevron (200 ms) ; « Revenir au direct » saute sans animation ; toutes coupées sous `prefers-reduced-motion: reduce` ;
  le trait « maintenant », le curseur et les voies ne sont jamais animés.
- **Thèmes** : les deux, sans valeur propre à l'un ; `html.theme-switching` coupe déjà les transitions.
- **Texte hostile** : un nom, un nœud, un message ou une cible hostile s'affiche tel quel (texte), sans balisage interprété ni lien actif.

## 7. Textes

Les libellés exacts sont donnés en contexte aux §§ 1 à 5 (guillemets français) ; table des libellés d'action et de nom de région :
| Où | Libellé |
|---|---|
| Bascule (dessinée par la 73) | « Régie », « Frise » ; nom du groupe « Vue de l'équipe » |
| Frise | « Lecture », « Horloge », « Événements », « Fenêtre », « 1 h 30 », « 6 h », « 24 h », « maintenant », « Agents au travail », « Dépôt » |
| Colonne | « Ouvrir la fiche de <nom> » (`aria-label`), « + 7 agents », « Replier les agents » |
| États (mots) | « au travail », « vous attend », « attend ses agents », « au repos », « terminé », « pas encore lancé » |
| Curseur | « Curseur de la frise », « À cet instant, 14 h 32 », « Retirer le curseur », « Voir sur la carte » |
| Fiche | « Retour à la frise », « Retour à la régie », « Fil », « Messages », « Outils », « Erreurs », « Revenir au direct », « Faits de l'agent » |
| Coût | « Coût sur les dernières 6 h », « Regrouper par », « Agent », « Mission et phase », « Étage », « Hors mission », « Détail du coût » |
| Inconnu | « inconnu » (jamais « 0 », « n/a » ni un tiret) |
Aucun texte de la 74 n'emploie « coût estimé », « euro », « tarif » ou un symbole monétaire.

## 8. Ce qui est retiré, ce qui ne change pas (P74-D-28)

**Retiré** : (1) la boîte de transcript de 320 px à défilement imbriqué et son bouton « Lire le transcript » (rendu `transcript()` de `71-vf-equipe-rendu.js`,
`zoneDe` de `72-vf-equipe.js`), remplacés par la fiche ; (2) la durée unique d'un agent qui compte ses veilles, remplacée par la somme des segments ; (3) avec la
73, le pli « Terminés » du tiroir « Au travail » est retiré et le tiroir quitte l'onglet Équipe (P73-D-14, 73-10) : le retrait (3) de la 74 se réduit à la carte « Terminés depuis moins de 24 h » du canevas, si elle existe encore (compensée par la frise sur 24 h, P74-D-51).
**Glyphes** : La table est unique (P74-D-29) : celle de la régie, à défaut `GLYPHE` de `71-vf-equipe-rendu.js` ; un glyphe d'état n'existe qu'à un endroit. Les ouvertures de fiche depuis la régie passent par l'événement de document `vf-agent:ouvrir`, que la fiche annule pour s'ouvrir (déclencheurs convenus avec la 73) ; elle émet `vf-agent:lu` à l'ouverture d'un agent terminé (P74-D-51). Glyphes d'état : `__vfEquipeRendu.GLYPHE_ETAT` (73-04).
**Le tiroir « Au travail » ne fait plus partie de ce que la 74 touche (P74-D-51)** : il quitte l'onglet Équipe, son pli « Terminés » est retiré par la 73, et la durée de ses lignes (ancien P74-D-41) tombe. Le lecteur de repli de la régie (`ouvrirRepli` et son appel dans `ui/72-vf-regie-source.js`) et la propriété `transcript` de `__vfEquipeRendu` sont retirés par 74-10, en un geste, après le témoin d'annulation des trois déclencheurs ; seule exception à P73-D-20 (P73-C2, P74-D-53). La 74 ne modifie, par ailleurs, ne modifie aucun fichier de la 73.
**Inchangé** : les onglets Code et Projet ; `.vf-tabs` et l'en-tête ; les points de rupture (700, 999, 1 279 tactile) ;
la bascule de thème ; la recherche de l'onglet Équipe ; le mode « hérité du poste » ; les routes en GET seules et le contrat de forme (tenu par la 79) ; aucune clé
`doing`, `mandat`, `messages`, `outils`, `fil` dans le flux ; aucun export de frise, fiche ou fil.

## 9. Règle → témoin

Propriétés mesurables qu'un test en navigateur pourrait asserter (pas le test).
| Règle | Témoin mesurable |
|---|---|
| Bascule dessinée par la 73, un seul onglet | `[role=tablist]` de nom « Vue de l'équipe » : onglets « Régie » et « Frise », un seul `aria-selected="true"` ; le nombre d'onglets de page reste 3 ; la frise est montée par `__vfEquipeVues.declarer({ id: 'frise', … })` et les modules de la 74 ne contiennent aucun `role="tablist"` de bascule |
| Position de la bascule gardée par la 73 | les modules de la 74 n'écrivent aucune clé de stockage pour la position de la bascule (seule clé de la 74 : `vibeflow-cockpit:frise-reglages`, fenêtre et lecture, P74-D-55) et aucune dans `localStorage` ; aucun fichier du lab modifié |
| Fil : source des lignes | les lignes « Compaction » et « Message de l'humain » viennent des `evenements` de la voie, bornées au plus ancien horodatage du fil ; « échec » vient du réducteur ; rendu inchangé |
| Autour de t = ± δ | δ = max(2 min, pas du curseur / 2) ; les voies lues sont celles dont le travail recoupe [t − δ, t + δ] ; avec un pas de 16 min, δ = 8 min |
| Nœuds portés : état de la voie | un nœud porté par une voie « vous attend » dit « vous attend », par une voie « attend ses agents » dit « attend ses agents » ; quatre formulations, jamais `ready` ni `blocked` |
| Lecture différée du curseur | des déplacements espacés de moins de 250 ms ne déclenchent aucune lecture de `/api/vf/transcript` avant 250 ms après le dernier, ou le relâché |
| Liste partielle des fichiers | avec 9 voies à lire : six lues, les fichiers de ces six listés, et le texte « 3 voies non lues » ; jamais « Fichiers non lus » pour toute la liste |
| Réponse tronquée | `tronque` vrai : avec `voiesOmises` = 1 « 1 voie n'est pas montrée : la lecture est tronquée. » ; avec 37 « 37 voies ne sont pas montrées : la lecture est tronquée. » ; avec `voiesOmises` nul ou absent « Des voies ne sont pas montrées : la lecture est tronquée. » ; dans tous les cas « Total (incomplet) » dans le coût |
| Ordre sous la synthèse | les lignes de source, de réponse tronquée puis de mission tronquée sont dans cet ordre dans le DOM, 12,5 px `--text-3`, écart `--sp-4` |
| États du bandeau Dépôt | chargement : `aria-busy="true"` et « Lecture du dépôt » ; échec : « Le dépôt n'a pas pu être lu. » et « Réessayer » qui relance la lecture GET, le reste de la frise intact ; vide : « Aucun commit sur 1 h 30 » ; les trois états sont dans la liste `.sr` |
| `ouvrirSur` rend false | un clic sur un commit dont `ouvrirSur(sha)` rend `false` : seule la région live dit « Ce commit n'est pas disponible dans le tiroir Git. », aucun autre élément ajouté |
| `ouvrirSur` absent | sans `window.VFGitTiroir.ouvrirSur`, aucun commit n'est un `button` ni dans l'ordre de tabulation, et leur `aria-label` ne contient pas « Ouvrir dans le tiroir Git » |
| Libellé sans branche | sur la ligne « Autres commits », l'`aria-label` d'un commit est « Commit a1b2c3d, 14 h 32. Ouvrir dans le tiroir Git » et ne contient pas « branche » |
| Source indisponible ou forme inconnue | carte d'état ; aucune ligne de synthèse ; encart « Aucun instant à relire : la frise n'est pas lue. » ; aucune section « Coût », aucun « Total », aucun lien « Détail du coût » |
| Frise vide | synthèse « Sur les dernières 1 h 30 : aucun agent vu. » ; encart « Aucun instant à relire : aucune voie sur cette fenêtre. » ; section « Coût » omise, aucun « Total » égal à zéro |
| Arbre absent ou nul | `arbre` absent ou nul : « arbre principal » ; aucun « inconnu » pour l'arbre |
| Worktree d'un fichier | une cible de forme `<chemin> (worktree <nom>)` s'affiche ainsi, lue `{ arbre: <nom>, cible }` ; une cible finissant par « … » est listée telle quelle et n'entre dans aucune mise en évidence |
| « 200 ou plus » | `cibles.tronque` vrai avec 200 fichiers écrits et 37 lus : « Écrits » dit « 200 ou plus », « Lus » dit « 37 » (deux comptes de valeurs différentes, un seul drapeau par voie) |
| Bornes invalides | réponse 400 `bornes-invalides` : carte « La frise est indisponible » |
| Fiche : retour du tiroir | la fiche s'ouvre sur l'événement `vf-agent:ouvrir` annulé ; `vf-agent:lu` est émis à l'ouverture d'un agent terminé |
| Voie = `--frise-voie` | hauteur de chaque cellule de voie = 32 px (44 en coarse), même valeur que sa piste |
| Barre pleine = au travail | `rect[data-etat="travail"]` : hauteur = `--sp-8`, `fill` résolu = `--st-active`, aucun `stroke` |
| Vous attend hachuré sans contour | `rect[data-etat="attend"]` : `fill="url(#…)"` vers un `<pattern>`, `stroke="none"`, aucun `border` ; la couleur des traits du motif = `--st-active` |
| Attend ses agents = trait fin | `[data-etat="agents"]` : `line`/`path` d'épaisseur `--sp-2`, pas de `rect` plein |
| Au repos = pointillé | `[data-etat="repos"]` : `stroke-dasharray` non vide, couleur `--text-4` |
| Quatre sortes distinctes sans la couleur | les quatre états ont quatre jeux distincts de (hauteur de barre, présence d'un `<pattern>`, `stroke-dasharray`) mesurés dans le DOM ; la légende compte quatre entrées d'état avec échantillons dessinés comme les segments |
| Une erreur ne teinte pas une voie | aucun segment de couleur `--sev-high` ; la croix existe dans le rail d'événements de la voie |
| Événements dans le rail du haut | bas du glyphe < haut de la barre de la même voie ; aucun chevauchement de boîtes |
| Compteur de collision écrit | deux événements à < 12,5 px : un glyphe et un « +N » dans le DOM |
| Commits seulement sur le Dépôt | aucun losange de commit dans une voie d'agent ; chaque commit ou groupe a un bouton ≥ 24 × 24 (44 en coarse) dont l'`aria-label` liste tous les commits du groupe ; losange en `--text-2`, jamais `--recent` |
| Axe dit la lecture | cellule d'axe : « Horloge » ou « Événements, silences raccourcis » selon la lecture |
| Horloge linéaire | en Horloge, `largeur(segment) / durée` constant sur tous les segments d'une même fenêtre |
| Silence raccourci en repère fixe | en Événements, un silence > 2 min : largeur = `calc(--sp-32 + --sp-8)` et texte « N min » ; deux silences de durées différentes ont la même largeur |
| Fenêtres | 3 choix exacts (« 1 h 30 », « 6 h », « 24 h ») ; aucun « 7 j » dans le DOM |
| Repli au-delà de 12 voies | avec 13 voies ou plus, ≤ 12 voies visibles et un bouton « + N agents » dont N = nombre replié, `aria-expanded="false"` ; avec plus de 4 branches au Dépôt, 4 visibles et un bouton « + N branches » de nom « Afficher les N autres branches du dépôt », `aria-expanded="false"`, dans l'ordre de tabulation après les commits |
| Mission tronquée dite | un segment commencé avant la fenêtre : bord gauche carré ; la ligne « commencées avant la fenêtre » est présente et son nombre égale celui des voies concernées |
| Colonne sans fond | en survol et au focus clavier, le `background` du bouton de voie et de ses ancêtres jusqu'à la carte reste transparent ou `--surface` ; le nom est souligné au survol ; la zone des segments garde `--surface` ; une ligne `echec` du fil n'a aucun fond au survol |
| Curseur : trait plein distinct de « maintenant » | trait du curseur sans `stroke-dasharray` ; trait « maintenant » avec `stroke-dasharray` |
| Curseur au clavier | `[role=slider]` focalisable **sans curseur posé** (`tabindex="0"`), hors de tout ancêtre `aria-hidden`, `aria-controls` = id de l'encart, `aria-valuenow` = `aria-valuemax` au départ ; → ne change rien au départ ; ← pose le curseur à un pas (1/90 de la fenêtre) et un résumé « 14 h 32 : … » est annoncé dans la région live ; Fin retire le curseur et `aria-valuenow` revient à `aria-valuemax` ; Échap, focus sur le repère et appui intact, le retire |
| Encart ne déduit pas le plan | aucun mot `ready` ni `blocked` dans l'encart ; la note « déduit des voies » est présente ; états de nœud limités à 3 formulations |
| « Voir sur la carte » | présent si et seulement si au moins une cible est posable ; son `aria-label` compte les fichiers mis en évidence (une cible coupée est listée mais exclue du compte) |
| Fiche = vue pleine, pas un tiroir | la fiche occupe la zone de contenu (rect de la fiche = rect de la zone) ; la carte d'un autre onglet n'est pas recouverte ; `#panel` n'est pas utilisé |
| Retour du focus | après un Échap dont `defaultPrevented` est faux, `document.activeElement` = l'ouvreur (`declencheur` si la fiche vient de la régie), ou la voie du même agent s'il a disparu |
| Deux colonnes, une au téléphone | à 1 280 px : faits et fil côte à côte ; à 390 px : une colonne, `<details>` « Faits de l'agent » fermé, pas de défilement horizontal |
| « inconnu », jamais zéro | pour un champ absent, le texte de la valeur est « inconnu » ; aucun « 0 » pour une donnée non fournie |
| Contexte en jetons | « Contexte au dernier tour » n'a jamais de « % » ; sa valeur vient de `jetons.contexteDernier` |
| Table de glyphes unique | chaque glyphe d'état de la frise et de la fiche est un `<use>` ou un tracé de la table de la régie (ou de `GLYPHE`) ; aucun tracé d'état défini dans les fichiers de la 74 |
| Fichiers à t | si AUCUNE voie ne donne de fichier et qu'au moins un fil est trop court, le texte « Fichiers non relus : cet instant est plus ancien que l'historique conservé pour cet agent. » remplace la liste et « Voir sur la carte » est absent ; si une voie donne des fichiers, la voie trop courte compte dans « N voies non lues » |
| États de source | `source.etat` = `en-construction` : voies dessinées et ligne « Lecture des traces en cours » ; `partielle` : ligne « partielle » ; `forme-inconnue` : carte sans « Réessayer » ; `indisponible` : carte avec « Réessayer » |
| Fichiers écrits et lus en construction | `cibles.etat` = `en-construction` : valeur « en cours de lecture », jamais « 0 » |
| Direct | un événement `frise` provoque une seule relecture de `GET /api/vf/frise` ; le DOM du flux ne contient aucune donnée de frise |
| Dépôt hors frise | les commits viennent de la route Git, aucun appel à la route de frise pour eux ; aucune voie d'agent ne porte de commit |
| Messages et compactions du fil | le fil de la fiche contient des lignes « Message de l'humain » (point plein) et « Compaction » (triangle vide) sans texte ni taille ; sur la frise les messages de l'humain restent des points |
| Durée = somme des segments | « Au travail » de la fiche = somme des durées des segments « travail » de la voie, à la minute près |
| Fil borné et dit | au plus 50 messages et 200 appels d'outil rendus ; la ligne « Plus ancien que la fenêtre lue » est présente quand la réduction est tronquée |
| Aucune sortie d'outil, aucun argument | le DOM de la fiche ne contient ni texte d'erreur d'outil, ni argument de commande : un résultat d'outil porteur d'un secret n'apparaît nulle part, la ligne dit seulement « échec » |
| Markdown en texte | un message contenant `<img onerror=…>` ou `[x](javascript:…)` n'ajoute aucun élément interactif ni attribut d'événement ; le texte s'affiche tel quel |
| Filtres cumulables | `aria-pressed` ; « Messages » rend les messages de l'agent et de l'humain ; « Erreurs » rend les seules lignes `echec` ; « Outils » rend les lignes d'outil ; combinés, union ; sans filtre, tout (compactions comprises) ; le compteur « N lignes sur M » est exact |
| Suivi en direct | fil à moins de 24 px du bas : une ligne ajoutée garde le fil en bas ; après remontée, « Revenir au direct » est présent et le défilement ne bouge pas |
| Libellé de fenêtre toujours visible | synthèse, courbe, colonne « Dépôt », titre de la section Coût (dynamique : change avec la fenêtre), colonnes de durée et fiche contiennent leur fenêtre ; les colonnes de jetons et la fiche disent « 24 h » |
| « Hors mission » et totaux | dans « Mission et phase », dernière ligne « Hors mission » non découpée ; chaque regroupement finit par « Total » ; somme des lignes = « Total », identique dans les trois regroupements |
| Aucun montant en devise | aucun nœud de texte de la frise, de la fiche ou du coût ne contient `€`, `$`, « euro », « tarif » |
| Formats | « 168 k », « 1,8 M », « 2 h 05 », « 12 min » avec espace insécable (U+00A0) avant l'unité ; aucune espace ordinaire avant `: ; ! ?` |
| Aucune valeur d'espacement hors jeton | toutes les valeurs de `padding`, `margin`, `gap`, `top/right/bottom/left` de la feuille neuve ∈ {0, 2, 4, 6, 8, 12, 16, 20, 24, 32, auto} ou un `calc` de jetons ; seuls filets 1 et 1,5 px |
| Aucune couleur, ombre, rayon neufs | `grep` de la feuille neuve : aucune valeur hexadécimale ni `rgb(` hors `rgba(var(--ink), α)` ; ombres = `--shadow-card` ; chaque `border-radius` ∈ {`999px`, `8px`, `var(--r-card)`, `var(--r-ctl)`, `var(--r-panel)`} ; `node css-jetons.mjs ui/74-vf-*.js` sort 0 |
| Aucun contour, liseré, halo, fond teinté d'état | aucun `border-color`, `outline-color`, `box-shadow` ni `filter: drop-shadow` pris d'une variable d'état ; aucun fond de variable `--st-*`, `--sev-*`, `--recent` |
| Aucune couleur par nœud | l'ensemble des couleurs résolues de la frise ⊂ {`--st-active`, `--recent`, `--sev-high`} + neutres |
| Contrastes | texte ≥ 4,5:1 ; glyphes, barres et traits ≥ 3:1 sur `--surface`, thèmes sombre et clair |
| Focus visible | tout élément focalisable a un `outline` résolu de largeur 2 px couleur `--ring` au focus clavier |
| Mouvement réduit | avec `prefers-reduced-motion: reduce`, aucune animation ni transition active dans les surfaces de la 74 ; aucune durée > 700 ms |
| Alternative textuelle | la liste `.sr` contient un élément par voie et par segment affiché ; les pistes sont `aria-hidden` |
| Chargement, vide, indisponible | chaque état a son texte exact et `aria-busy` pendant le chargement ; « Réessayer » déclenche une lecture GET |
| Aucune fuite | aucune clé `doing`, `mandat`, `messages`, `outils`, `fil` dans le flux ; export sans frise ni fiche ; aucun appel réseau sortant |
| XSS | nom d'agent, nœud, titre, message hostiles : aucun élément injecté dans la frise, l'encart, la fiche ni le tableau de coût |
| Repère distinct du commit | le repère du curseur est une poignée verticale (largeur `--sp-4`), pas un losange ; zone de saisie 24 × 24 au pointeur fin, 44 × 44 en coarse ; `outline` de focus 2 px `--ring` |
| Fenêtre excluant le curseur | un changement de fenêtre dont la plage exclut l'instant retire le curseur et annonce « Le curseur est sorti de la fenêtre » |
| Causes de non-lecture | au-delà de six voies à lire (prises dans l'ordre de la frise) : « N voies non lues » (« 1 voie non lue ») sous la liste partielle, 12,5 px `--text-3` ; fil trop court sur toutes les voies sans fichier : « Fichiers non relus : cet instant est plus ancien que l'historique conservé pour cet agent. » |
| États des faits | pendant la lecture : `aria-busy="true"` et « Lecture des faits » ; échec : « Les faits sont indisponibles. » et « Réessayer » qui relance |
| `frise` relance la fiche | un événement `frise` pendant qu'une fiche est ouverte provoque une relecture des faits et du fil par `VF_ETAT.lireJson()` ; une nouvelle ligne du fil apparaît sans fermer la fiche |
| Libellé du retour | « Retour à la frise » si la fiche vient de la frise, « Retour à la régie » si elle vient de la régie ; le focus revient à l'origine |
| Fond des bandes collées | le `background` résolu de la courbe et de l'axe collés est `--surface` opaque (alpha 1) ; l'écart entre frise, encart et coût = `--gap-section` |
| Suivi du bas | sur ordinateur, `scrollTop + clientHeight` de la colonne du fil ≥ `scrollHeight` − 24 px garde le fil en bas ; sur téléphone la mesure est celle de la zone de contenu ; « Revenir au direct » est `position: sticky` au bas du conteneur visible |
| Échap (P74-D-53) | un appui Échap dont `defaultPrevented` est vrai n'a aucun effet sur la fiche ni le curseur ; un appui intact ferme la fiche et le focus revient à l'ouvreur ; aucun écouteur Échap en capture ni sur `window` dans les modules de la 74, aucune lecture de `VF_SURCOUCHES.ouverte()` ; la fiche n'apparaît pas dans la pile de `VF_SURCOUCHES` |
| Espace de noms | après chargement, l'objet global du moteur a les mêmes clés qu'avant ; les fonctions de la 74 sont sous `window.__vfFrise` et `window.__vfFiche` |
| Cycle de vie de l'onglet | quitter l'onglet Équipe puis y revenir ne double aucun abonnement `VF_ETAT`, minuterie, observateur ni écouteur de la frise, de la fiche et du lecteur (même nombre d'abonnés avant et après) ; l'initialisation passe par `VF_COQUILLE.surOnglet(rappel)` |
| Aller-retour d'onglet (P74-D-55) | après Code, Équipe, Code, Équipe : fenêtre et lecture restituées depuis `sessionStorage` (clé `vibeflow-cockpit:frise-reglages`), curseur absent (repère à « maintenant »), fiche fermée, dépliages et défilement réinitialisés, aucun écouteur ni abonnement doublé ; aucune autre clé de stockage écrite par la 74, aucun fichier du lab modifié |
| Commit vers le tiroir | un clic sur un commit passe uniquement par `window.VFGitTiroir.ouvrirSur(sha)` (Phase 80, 80-06) avec le sha de ce commit (et lui seul), aucun autre appel du tiroir ni du volet ; la promesse rendue à `false` (SHA invalide ou introuvable) ne produit rien d'autre et aucun message ; aucune insertion sous la rangée ; aucune modification de `ui/77-vf-git-vue-detail.js` |
| Rangement des commits | commits rangés sous la branche obtenue en descendant les premiers parents (base, puis branches locales, puis distantes) ; les commits atteints par aucune forment la dernière ligne « Autres commits (branches fusionnées ou sans nom) », jamais pliée, avec en seconde ligne mono le compte « 12 commits » (« 1 commit ») |
| Étages | une voie de genre session est « Tête » ; un sous-agent avec au moins une voie enfant est « Manager » ; sans voie enfant « Worker », quelle que soit sa profondeur |
| Données non traduites | un message d'agent, un nom, un nœud ou une cible valant « Close » ou « Search » reste inchangé après l'observateur de traduction ; tout nœud de texte de donnée a un ancêtre `code`, `pre` ou `.mono` |
| « · déduit » | le suffixe n'apparaît que sur l'état présent d'une voie dont `etatOfficiel` est nul, jamais sur un état à un instant passé ni un segment |
| Vide à 24 h | à 24 h, le texte vide ne contient pas « fenêtre plus large » ; à 1 h 30 ou 6 h il la contient |
| Dépôt peut-être incomplet | marche tronquée et plus récent des instants (plus ancien commit lu, plus récente rangée dont un parent n'est pas lu) dans la fenêtre : le texte « Dépôt peut-être incomplet avant <heure> » est présent et l'heure vaut cet instant ; sinon absent ; aucun « Dépôt incomplet avant » ni « 60 derniers commits » ; la route Git est lue au montage et sur `git`, jamais à l'événement `frise` |
| Heure des commits | un commit d'`at` en secondes se pose à l'abscisse de la milliseconde correspondante (pas d'écart d'un facteur 1 000) |
| Manager rattaché par ses agents | voie d'un manager de `rattachement.source = "enfants"` : seconde ligne « rattaché par ses agents », aucun id de nœud ; la fiche porte la même phrase ; son coût figure dans sa mission et sa phase |
| Six lectures par instant | un instant déclenche au plus six lectures de `/api/vf/transcript` et au plus deux en vol ; les voies au-delà de la sixième sont comptées dans « N voies non lues » (liste partielle, pas « Fichiers non lus » pour toute la liste) ; un second déplacement sans que `fin` bouge relit zéro fil déjà en cache (cache par voie et `fin`) |
| Lecture des fichiers | pendant la lecture, `aria-busy="true"` sur le groupe « Fichiers » et le texte « Lecture des fichiers » ; échec : « Les fichiers n'ont pas pu être lus. » et un bouton « Réessayer » qui relance |
| Focus conservé à la relecture | focus sur une voie, un commit, un « + N agents » ou le repère, puis événement `frise` : `document.activeElement` porte le même `data-id` ; élément disparu : focus sur la voie du parent ou le repère |
| Retour intact | après « Retour », fenêtre, lecture, curseur, défilement et dépliages de la frise sont ceux d'avant l'ouverture ; pendant l'ouverture la vue d'origine est `hidden` et `inert` ; `activeElement` = l'élément d'origine |
| Fiche sur 24 h | la fiche demande la frise sur 24 h, quelle que soit la fenêtre : ses faits sont égaux à 1 h 30 et à 24 h |
| Frise à 390 px | à 390 px de large : `document.scrollingElement.scrollWidth` ≤ largeur de la fenêtre ; le conteneur des pistes défile (`scrollWidth` > `clientWidth`) avec `scrollLeft` initial = maximum ; voies de 44 ; repère de 44 × 44 ; un toucher pose le curseur, un glissement ne le pose pas |
| Cibles tactiles en coarse | en `pointer: coarse`, voies, sous-voies du Dépôt, commits, filtres, positions de la bascule, repère : hauteur et largeur ≥ 44 |
| Colonnes défilantes nommées | chaque conteneur à défilement (faits, fil, corps des voies, pistes sur téléphone) a `tabindex="0"` et un nom accessible |
| Ordre de tabulation | la suite des éléments focalisables dans l'ordre de `Tab` = leur ordre dans le DOM = leur ordre visuel (haut vers bas, gauche vers droite), le bouton « + N branches » venant après les commits du Dépôt et avant les voies ; « Détail du coût » place le focus sur le titre de la section Coût |
| Une seule taille de mono | l'ensemble des `font-size` de `font-family` mono de la feuille neuve = {11,5 px} ; toutes les tailles ∈ {11,5, 12,5, 13, 15, 20} ; chaque rôle a une `line-height` déclarée |
| Tirets et motifs dérivés des jetons | `stroke-dasharray` et dimensions de `<pattern>` de la frise ∈ combinaisons de `--sp-2`, `--sp-4`, `--sp-6`, `--sp-8` ; aucun nombre littéral hors filets de 1 et 1,5 px |
| « Revenir au direct » sans animation | l'activation place `scrollTop` au maximum dans la même image (aucun `scroll-behavior: smooth`) |
| Aucune action sur une session | aucun bouton ni lien nommé « Ouvrir dans le terminal », « Lui écrire » ou « Demander l'arrêt » ; aucune requête autre que GET émise par les surfaces de la 74 |
| Aucun cadratin dans les textes | aucun nœud de texte, `aria-label`, `title` ni `placeholder` des surfaces de la 74 ne contient U+2014 |
| Lectures par le socle | aucun appel direct à `fetch` ou `EventSource` dans les modules de la 74 ; toute lecture passe par `VF_ETAT.jeton()` et `VF_ETAT.lireJson()` |
| Espaces insécables | dans les nœuds de texte rendus, aucune espace ordinaire avant `:`, `;`, `!`, `?`, ni entre un nombre et « k », « M », « h », « min », « s », « jetons » |
| Genre `silence` | un segment `silence` ne produit aucun élément dessiné et aucun `title` de segment |

## Points ouverts pour le manager

Aucune décision du CONTEXT n'est intenable en forme. Reste non tranché :
1. **Genre `silence` (P74-D-36).** Rien n'est dessiné : un blanc sur la voie. À confirmer à la recette (un blanc peut se lire comme une donnée manquante).
