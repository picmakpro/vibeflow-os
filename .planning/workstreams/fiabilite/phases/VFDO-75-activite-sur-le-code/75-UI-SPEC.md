# 75-UI-SPEC : l'activité posée sur la carte Code (contrat d'interface)

Auteur : vf-crafter, 2026-11-11. Spec seule, aucun fichier de code touché. Les plans de la Phase 75 la citent par numéro de section.
Décisions tenues, non rouvertes : P75-D-01 à D-06, D-13, D-15, D-17, D-18, D-20 ; Q9 et `DESIGN.md` § 9 ; P71.5-D-01, D-19, D-21, D-28, D-29 ; Q11, Q12, P78-D-04.
Complété le 2026-11-11 après le second amendement de la Phase 79 (commit `6f66d878`, A21 à A28) : § 3.4, § 5.4, § 7.3.
Générique : l'interface décrite ici est vérifiable à l'écran, les noms de classe (`.lm`…) sont des noms de travail. Texte FR : espace insécable avant `: ; ! ?` et `%`, et dans les nombres à partir de 1 000 ; aucun tiret long dans le texte d'interface ; point médian `·` comme séparateur.

## 0. L'écran présent (relevé sur le code et les captures, lecture seule)

- **« Travail récent » aujourd'hui** : le bouton d'en-tête `#btn-recent` (`ui/25-recent.js`), icône « récent » en `--recent`, pastille de compte pleine `--recent` + `--on-recent-text`. En bureau (> 999 px) il est dans l'en-tête, entre Santé (`#btn-health`) et « Par où commencer » (boussole), ouvre un tableau (`showBoard`). Jusqu'à 999 px il vit dans le menu « ⋯ » (`#vf-plus-menu`, `ui/02-vf-telephone.js`), entre « Santé » et « Par où commencer », pastille neutre `--on`. La bascule binaire est la ligne « Highlight recent work » (« Surligner le travail récent ») du menu « Types de liens » (`#legend`).
- **Pied de carte** : `.foot` = `.meta` à gauche (taille : « 8 fichiers », « 3 endpoints »), à droite UN emplacement : `.vst` (statut) sinon `.rw` (« 2 récents »). Le pied n'existe que si la carte a une taille ou une pastille : une carte de fichier sans endpoint n'a aucun pied. Hauteur du pied : 20 (`--sp-20`) + gap 8 = `FOOT_H` 28 ; `lod-mid` et `lod-low` : pastille 17-18 px, padding 4 × 12, `line-height 20`, hauteur 28 (71.5-SPEC-code § 3.1). `lod-low` masque déjà `.meta`.
- **Ce que la retraite libère** : l'emplacement droit du pied (`.rw`, `.rw.soft`, `.card.recent`) et la ligne de la bascule (D-20).
- **Sous-titre de la vue** : `#context p` (« 806 fichiers et 0 route lus dans le dépôt. »), 14 px, tient sur une ligne à 390 px (~ 270 px sur 358).

## 1. Sélecteur de lentilles

### 1.1 Place et forme
| Largeur | Emplacement | Forme |
|---|---|---|
| > 999 px | exactement le créneau de `#btn-recent` : entre Santé et la boussole | bouton d'en-tête carré (même `addHeaderButton`), icône « lentille » (cercle et arc de reflet, 16 px, trait 1,75, `currentColor`, couleur `--text-2` : l'ancien trait `--recent` disparaît) ; ouvre un menu `#lens-menu` posé comme `#legend` : `top` 44, `right` 0, largeur 320, classe `.menu` |
| ≤ 999 px | entrée du « ⋯ » à la place exacte de « Travail récent » (entre Santé et « Par où commencer ») | même mécanique que « Types de liens » : l'entrée clique le bouton d'origine, le menu se pose en `fixed` (`top` = `--hh` + 4, `left` 8, largeur `min(320px, 100% - 16px)`, `max-height 60vh`) ; une ligne de plus dans les sélecteurs de `viewer.html:274` et `:539` |
Libellé du bouton et de l'entrée (relu par le « ⋯ » comme le thème) : **« Lentille : Aucune »**, **« Lentille : Points chauds »**… (l'état est dit dans le libellé, comme « Thème : Clair »). Infobulle : « Lentille d'activité sur le code ». Aucun bouton d'en-tête de plus, aucun onglet, rien ne pousse la carte (Q12 : le menu est un volant au-dessus du plan).
Pastille de compte (D-20) : nombre de fichiers **en cours d'écriture** par un agent actif ; absente à 0. Bureau : pastille actuelle (`--recent` + `--on-recent-text`, 16 px) ; dans le « ⋯ » : pastille neutre `--on`. Écart **confirmé**, pas unifié : tradition 71.5 (`71.5-SPEC-couleurs` § 3 #18 : le badge plein `--recent` reste) et P70-D-01 (pastilles neutres du « ⋯ »). Elle se lit sans lentille active. `aria-label` du bouton : « Lentille : Aucune, 2 fichiers en cours d'écriture ». Le point du « ⋯ » (présence, jamais une somme, Q8) ne change pas.
Choix à l'ouverture de la page : **Aucune**, toujours. Rien n'est mémorisé (pas de nouveau stockage, pas de lentille « qui surprend » au rechargement).

### 1.2 Contenu du menu (de haut en bas)
1. Titre `.lh` (12 px, `--text-3`) : « Lentille d'activité sur le code ».
2. Cinq lignes `role="menuitemradio"`, `aria-checked`, hauteur 44 en toute largeur tactile (≥ 44 comme `.vf-pl-i`), padding `--inset-row`, rayon 12, survol `rgba(var(--ink), .07)`, ligne cochée = même fond + coche neutre 16 px (icône de trait, `currentColor`, aucune teinte). Libellé 13,5 px `--text` ; sous-libellé 12 px `--text-3` ; compte à droite (pastille neutre, 11 px, `--text-2`, chiffres tabulaires).

| Libellé exact | Sous-libellé | Compte à droite |
|---|---|---|
| Aucune | Aucune marque de lentille | (rien) |
| Points chauds | Ce qui change souvent et pèse lourd | fichiers du palier haut |
| Couplage | Ce qui change avec le fichier choisi | (rien : relationnel) |
| Gardes | Ce qu'une suite ou un gate nomme | fichiers sans témoin |
| Empreinte | Ce que les agents lisent et écrivent | fichiers en cours d'écriture |

3. Filet `--hair`, puis **légende de la lentille active** (`role="group"`, `aria-label="Légende de la lentille"`) : § 1.3. Sans lentille : rien.
4. Filet, puis **ligne du radar** (12 px, `--text-3`, toujours présente) : « Radar de collisions : 2 fichiers » ; « Radar de collisions : aucune collision vue » **seulement** quand le calcul est complet ; sinon « Radar incomplet » (§ 5.4). Jamais de zéro affirmé sur un calcul partiel.

### 1.3 États des lignes et légende
| État | Rendu | Règle |
|---|---|---|
| Disponible | ligne normale | |
| **Indisponible** (erreur git, délai, sortie trop longue : P75-D-11, P78-D-22) | ligne atténuée en `--text-4` (couleur, jamais d'opacité), `aria-disabled="true"`, **reste focalisable**, entrer ne fait rien, `aria-describedby` vers « Indisponible pour l'instant » + « Nouvelle lecture au prochain changement du dépôt » (vrai : recalcul sur la signature de HEAD et des refs, P75-D-09) ; sous-libellé « Indisponible pour l'instant » | si c'est la lentille ACTIVE qui devient indisponible : les marques sont retirées (jamais un résultat partiel), la lentille reste cochée, la légende dit « Points chauds indisponibles pour l'instant. » |
| **Absente sur ce lab** (Gardes sur un lab non VibeFlow, P75-D-17) | ligne atténuée comme ci-dessus ; sous-libellé « Gardes non lues sur ce lab » ; jamais « tout est sans témoin » | la ligne reste visible pour dire pourquoi |
| **Git absent** (hors dépôt, P75-D-11) | les lignes **Points chauds** et **Couplage** ne sont pas posées du tout ; le menu garde Aucune, Gardes, Empreinte | mêmes cartes, mêmes liens, aucune marque ; la hauteur des cartes de fichier est celle de la réserve du pied (+28, § 2.3), posée aussi sans git (P78-D-11 lue ainsi) |
| **En cours de relecture** (`cibles.etat: "en-construction"`, quelques secondes) | ligne Empreinte : sous-libellé « En cours de relecture » ; légende : « Empreinte en cours de relecture, radar incomplet » | les marques déjà connues restent ; la phrase dit que la liste n'est pas finie |
| Fenêtre vide | légende « Aucune modification sur 90 jours » | aucune carte marquée ; un fichier sans modification dans la fenêtre ne porte **aucune marque** (jamais « 0 changement ») |

Légende par lentille (les paliers se lisent par FORME, pas par la teinte ; chaque ligne = glyphe 14 px + texte 12 px `--text-2`) :
- **Points chauds** : « Haut : tiers le plus changé et le plus gros » · « Moyen » · « Bas » ; puis « Commits des 90 derniers jours, hors fusions » ; si le plafond mord : « Fenêtre réduite à 5 000 commits » ; clone superficiel : « Historique partiel ».
- **Couplage** : « Haut : 75 % et plus » · « Moyen : 50 à 74 % » · « Bas : 30 à 49 % » ; puis « Sélectionnez un fichier : ceux qui changent avec lui sont marqués. » (seule ligne affichée tant que rien n'est sélectionné ; sur un nœud : « Le couplage se lit sur un fichier. »).
- **Gardes** : « Garde : une suite ou un gate la protège ou la définit » · « Aucune suite ne le nomme » · « Nommé par n suites : pas de glyphe, le mot seul » ; puis « Lecture des noms cités par les suites et les gates, rien n'est exécuté ». L'emplacement du glyphe **n'est pas réservé** : sans glyphe, le mot s'aligne à droite du pied, comme toute marque.
- **Empreinte** : quatre lignes, glyphe de § 2.1 + texte : « En écriture maintenant » · « Modifié par un agent vivant » · « Lu par un agent vivant » · « Fini il y a moins de 24 h » ; puis, en deux phrases distinctes, « Écritures par commande non vues. » et « Écritures hors du lab : 2 comptées, non dessinées. » ; « 3 hors carte. » quand des cibles n'ont pas de carte. Le filtre d'agents (D-13) s'ajoute **seulement** quand un rattachement existe : groupe « Agents », rangées radio « Toute l'équipe » (défaut) puis une rangée par mission rattachée (5 au plus) ; rôle `menuitemradio` dans un `role="group"` nommé « Agents », rangées dans le cycle `↓` `↑`, `Entrée` choisit **sans fermer** le menu.

## 2. Marques de carte

### 2.1 Glyphes (distincts des glyphes d'état existants : coche, demi-disque dans un anneau, anneau-point, anneau, anneau barré horizontal, anneau barré diagonal, disque plein « récent », anneau-i, triangle, losange-croix)
Boîte 1,45 em (= celle de `.vst`, 16 px à l'échelle 1), même technique de masque SVG en `%23`, aucun hexadécimal ni `rgb(` dans le fichier (M5.3).
| Sens | Forme (viewBox 16) | Couleur |
|---|---|---|
| Palier bas | **une barre** pleine, largeur 3, hauteur 5, posée sur la ligne de base (x 2 à 5) | `--text-3` |
| Palier moyen | **deux barres** (hauteurs 5 et 9 ; x 2 à 5 et 6,5 à 9,5) | `--text-3` |
| Palier haut | **trois barres** (5, 9, 13 ; troisième x 11 à 14), silhouette en escalier ; aires 15, 42, 81 unités² | `--text-3` |
| Collision (radar) | **confluent** : deux traits qui se rejoignent en V puis une tige (Y), trait 1,75 | `--text-3` |
| Est une garde | **bouclier**, contour 1,75 | `--text-3` |
| Sans témoin | **bouclier barré** d'une diagonale bas-gauche vers haut-droite | `--text-3` |
| Empreinte : en cours | **disque plein** (r 5) | `--recent` (§ 2.2) |
| Empreinte : modifié | **triangle plein** pointe en haut (base 11) | `--text-3` |
| Empreinte : lu | **carré en contour** (côté 11, trait 2,5) | `--text-4` |
| Empreinte : fini | **tiret plein** (10 × 2,5, centré) | `--text-4` |
| Prévu (§ 7) | **anneau ouvert à trois arcs** (trois traits de 90° séparés de vides, plein pas de pointillé) | `--st-todo` |
**Silhouettes d'Empreinte (F4)** : les quatre degrés ont une silhouette pleine distincte (rond, triangle, carré creux à trait 2,5, tiret) : ni le rond et le carré pleins, qui se confondent à 6 px, ni un contour de 1,75 qui se lit plein ; chaque degré a sa forme propre, dont « fini » ; la nuance de gris n'est qu'un renfort. Barres : largeur 3 au moins (le trait de 2,5 s'estompait à 6 px). Un palier se lit par le nombre de barres : sans couleur, en niveaux de gris et à `lod-low` (la forme tient à 10 px à l'écran : 1,45 em de 18 px = 26 unités du graphe).

### 2.2 Contraste (calculé, WCAG 2.x ; `--surface` / `--raise` / `--bg` = canvas)
| Jeton | Sombre (surface · raise · bg) | Clair (surface · raise · bg) |
|---|---|---|
| `--text-3` (glyphes neutres, mot « lu ») | 7,39 · 6,61 · 8,06 | 7,00 · 5,86 · 6,30 |
| `--text-4` (lu, fini) | 4,58 · 4,09 · 4,99 | 5,74 · 4,81 · 5,17 |
| `--recent` (en cours) | 9,62 · 8,60 · 10,49 | 3,48 · **2,91** · 3,13 |
| `--recent-text` | (identique au `--recent`) | 5,12 · 4,28 · 4,61 |
Tous les glyphes neutres tiennent ≥ 3:1 sur les trois fonds dans les deux thèmes. Seul `--recent` clair échoue sur `--raise` (2,91) : règle (DESIGN § 9) **sur `.card.module` (fond `--raise`) en thème clair, le glyphe « en cours » prend `--recent-text`** (4,28:1). Aucun nouveau jeton. Mot : `--text-2` (≥ 10:1), 11 px, 500.

### 2.3 Place, géométrie invariante (P75-D-03)
- **Place** : l'emplacement droit du pied, celui de `.rw`/`.vst`. Un élément `.lm` (glyphe + mot, sans fond, `gap` `--sp-6`, `padding var(--inset-pill)`, `line-height 16px`, hauteur 20) ; le `.vst` de statut garde la priorité sur lui : une carte à statut (phase, prévue) ne porte pas de marque de lentille.
- **Règle choisie : place RÉSERVÉE, pas contenu de même hauteur.** Raison : une carte de fichier sans endpoint n'a aucun pied, il n'existe donc aucun contenu à remplacer. Au **moment de la construction du graphe** (jamais au changement de lentille ni à une mise à jour en direct), toute carte marquable (fichier, nœud, prévue ; pas connecteur ni externe) reçoit un pied : `cardExtraH` compte `FOOT_H` pour elle même sans taille ni pastille, et le pied a une hauteur plancher (20, et 28 à `lod-mid`/`lod-low`, posé en `calc(var(--sp-24) + var(--sp-4)) /* dérivé : pastille du zoom d'éloignement */`). Effet assumé, **une seule fois à l'ouverture** : les cartes qui n'avaient pas de pied grandissent de 28 ; le placement (ELK) tourne une fois, avec la construction. **Chiffre à relever, non mesurable sans navigateur** : n cartes de fichier sans pied par niveau × 28 = hauteur ajoutée ; l'exécution consigne n et la hauteur totale avant/après du niveau le plus chargé, à 1440 et 390, et l'échelle de l'ajustement automatique de la vue ; rejouer sans les affaiblir `chrome-moteur-carte`, `test-cockpit-responsive.sh` R1, R3, R19, R20, `chrome-equipe-clavier.mjs` (EK10) et le mutant `test-cockpit-equipe.sh:950`, qui doit rester rouge (71.5-SPEC-code § 4.2).
- **Témoin** (P75-D-03) : géométrie de chaque carte (largeur, hauteur, x, y) et hauteur du pied, mesurées avant et après chaque bascule de lentille, après une mise à jour de l'empreinte, à 1440, 1024 et 390, aux trois paliers de zoom : identiques à 0 px.
- **Largeur** : `.lm` rétrécit avant `.meta` (le mot s'ellipse, jamais le glyphe ; mot entier en infobulle et dans le nom accessible) ; `.meta` et `.vst` gardent leur règle actuelle (le mutant EK10.2 reste rouge). Longueur maximale d'un gabarit : 26 caractères au zoom d'ouverture.

### 2.4 Niveaux de zoom
| Niveau | Rendu de la marque |
|---|---|
| Ouverture | glyphe 1,45 em + mot complet, 11 px |
| `lod-mid` | glyphe + **forme courte** (tableau 2.5), 17 px, padding 4 × 12, `line-height 20` (comme `.vst`) |
| `lod-low` | **glyphe seul**, 18 px (comme `.rw`) ; mot, forme courte et chiffre masqués (`display: none`), le glyphe garde sa taille : la forme porte le palier |

### 2.5 Mots chiffrés (gabarits ; un nombre au singulier prend le singulier)
| Lentille | Carte de fichier (mot complet) | Forme courte (lod-mid) | Carte de nœud (agrégat, D-04) |
|---|---|---|---|
| Points chauds | « 41 changements » · « 1 changement » | « 41 » | palier maximal + « 3 chauds » (palier haut), sinon « 5 moyens », sinon « 8 peu changés » ; pas de somme |
| Couplage (voisin) | « 78 % avec la sélection » | « 78 % » | aucun (pas d'agrégat) |
| Gardes | « garde du dépôt » ; « aucune suite ne le nomme » ; « nommé par 3 suites » (sans glyphe) | « garde » · « sans témoin » · « nommé » | « 12 sur 40 sans témoin » (version courte du pied ; la phrase « 12 fichiers sur 40 sans témoin » est dans l'infobulle et le panneau) ; « tous nommés » si 0 |
| Empreinte | « en écriture · vf-coder » · « modifié · vf-coder » · « lu · vf-coder » · « fini · vf-coder » ; plusieurs agents : « modifié · vf-coder et 2 autres » | « écrit » · « modifié » · « lu » · « fini » | glyphe du degré maximal + « 2 en écriture » · « 3 modifiés » · « 5 lus » · « 2 modifiés · finis » |
| Collision | § 5.2 | « 2 » | « 2 collisions » |
Infobulle (`title` du pied + ligne du panneau, jamais l'unique porteuse) : points chauds « 41 changements sur 90 jours · 1 203 lignes · rang 12 sur 340 » ; gardes : liste des 3 premières suites qui le nomment. Les cartes prévues, doc, suites et fixtures ne portent **aucune** marque de points chauds ni de gardes (pas de chiffre inventé). Le texte du mot est posé par `textContent` ; chemins, noms de branche, rôles et titres d'agent sont des données hostiles (chaîne XSS, P75-D-21).

## 3. Empreinte

### 3.1 Degrés (D-13) et teinte
| Degré | Glyphe | Mot | Remarque |
|---|---|---|---|
| En cours | disque plein `--recent` | « en écriture · {nom} » | seule teinte de la phase ; dernier fichier écrit d'un agent actif ; respiration d'échelle (keyframe existant `vfrespire`, `.aw-pulse`, `ui/71-vf-equipe-rendu.js` : 1 → .82, 2,4 s, coupée en mouvement réduit), à réutiliser, jamais d'opacité |
| Modifié | triangle plein `--text-3` | « modifié · {nom} » | agent vivant |
| Lu | **carré en contour** `--text-4` | « lu · {nom} » (glyphe plus discret) | agent vivant, `Read` seul (A24) |
| Fini | tiret plein `--text-4` | « fini · {nom} » | agent terminé dans les 24 h ; grisé ; priorité d'affichage : en cours > modifié > lu > fini |
Aucun minuteur côté page : l'état vient du flux (`window.VF_ETAT`, clé `frise`).

### 3.2 Nom d'agent
« rôle », puis « · nœud X » seulement si le rattachement existe, puis « · arbre » seulement si deux agents du même rôle sont vivants ; une session : son titre, sinon « session · arbre » ; jamais l'identifiant brut ; un agent non rattaché le dit (« vf-coder · non rattaché »), jamais deviné (P69-D-15). Sur la carte : le rôle seul (+ « et n autres »). Nom complet dans l'infobulle et la section « Agents sur ce fichier » du panneau ; les **finis** y sont repliés (`details` « Terminés dans les 24 h (n) », fermé, P69-D-18).

### 3.3 Mentions de limite (toujours dites, jamais seulement en infobulle)
« Écritures par commande non vues. » (légende, § 1.3) · « Écritures hors du lab : n comptées, non dessinées. » · « n hors carte. » (cibles sans carte : comptées, jamais affichées, D-14). Ces trois phrases sont aussi le pied de la section Collisions du panneau (§ 5.3).

### 3.4 Écritures dans un arbre hors du dossier du lab (A22 : la cible devient « un fichier hors du lab »)
Le radar et l'empreinte ne voient pas ces écritures. Texte, à deux endroits : légende de l'Empreinte (§ 3.3, deuxième phrase) et pied de la section Collisions : « Non vu par le radar : écritures par commande, écritures dans un arbre hors du dossier du lab (2 comptées). » Version courte, infobulle du compte de collisions (§ 5.4) : « Non vu : commandes, arbres hors du lab (2) ». Un compte à 0 n'écrit pas la clause « hors du lab ». Aucun chemin hors lab n'apparaît dans l'interface.

## 4. Couplage à la sélection

- Seule une **sélection de fichier** déclenche des marques (D-08). Les voisins (5 au plus, tri par degré décroissant) qui ont une carte **dans la vue courante** portent la marque `.lm` : glyphe du palier (barres, § 1.3) + « 78 % avec la sélection ». Un voisin hors de la vue n'est pas marqué (pas d'agrégat, D-04) : il apparaît dans le panneau seulement. Aucun lien ajouté au graphe (1 905 existent déjà) : les marques sont les seuls signes.
- La carte **sélectionnée** garde son anneau de sélection neutre (déjà là) et prend dans son pied le mot « 5 voisins marqués » (sans glyphe) ; sans voisin : « aucun fichier lié ».
- **Panneau de détail**, nouvelle section d'un fichier, après les sections actuelles : titre `h3` « Change souvent avec » + compte `.c` ; une rangée `.row` (cliquable, `data-go`) par voisin (5 au plus, puis « et 1 autre » en texte) : glyphe de palier · nom du fichier en mono, tronqué à gauche (ellipse du début pour garder le nom) · « 78 % » en `--text-2`, chiffres tabulaires ; infobulle : « Change avec ce fichier dans 78 % des commits, 12 révisions communes ». Vide : « Aucun fichier au-dessus des seuils (5 révisions communes, 30 %) ». Pied 12 px `--text-3` : « Sur 90 jours, d'après l'historique des commits » (+ « Historique partiel » le cas échéant).

## 5. Radar de collisions

### 5.1 Forme
Glyphe **confluent** (neutre, forme distincte de tout glyphe d'état), mot, jamais de teinte d'alerte, jamais de fond. Les lectures n'entrent pas dans une collision (D-15).

### 5.2 Gabarits de mot (carte)
| Source | Mot |
|---|---|
| Deux agents | « écrit par 2 agents » (« 3 agents » au-delà) |
| Deux branches | « modifié sur 2 branches » |
| Deux plans de la même vague | « prévu par 2 plans, vague 3 » |
Plusieurs sources sur un fichier : le pied n'affiche que la première (agents > branches > prévu) ; le nom accessible et le panneau les listent toutes. **Emplacement du mot** : sans lentille active, il occupe l'emplacement droit (libre). Quand une lentille est active, le mot passe en **forme compacte** : glyphe + nombre (« 2 »), posé juste avant la marque de lentille dans le même emplacement ; mot entier dans l'infobulle et le nom accessible. Sur une carte **prévue**, le mot « prévu par 2 plans, vague 3 » prend l'emplacement **gauche** (celui de `.meta`, vide sur une prévue) et laisse `.vst « Prévu »` à droite.

### 5.3 Section du panneau
Titre « Collisions possibles » + compte. Une rangée par collision : glyphe · gabarit · noms : agents « vf-coder (arbre phase-75) et vf-coder (arbre phase-76) » ; branches « feat/phase-75-… et feat/phase-76-… » (nom de branche en mono, tronqué au milieu) ; plans « 75-02 et 75-04 ». Sur un nœud : les collisions de ses fichiers, 5 au plus puis « et n autres » (cliquables, `data-go`). Pied : les phrases de limite de § 3.3 et § 3.4. Plafond de 12 HEAD : « Radar limité à 12 branches » quand il mord.

### 5.4 Compte visible sans lentille, état « incomplet »
- **Emplacement choisi : la rangée `.k` du contexte** (celle du « Code » au-dessus du titre, `inline-flex`, 12,5 px `--text-3`), à droite du mot « Code », en bouton-lien : glyphe confluent + « 3 fichiers en collision possible » (« 1 fichier… »). Le sous-titre `#context p` n'est **pas touché** (ni flex, ni ellipse). Il ouvre le panneau de détail (tiroir latéral : rien n'est poussé, Q12) sur la section « Collisions possibles ».
- **Pourquoi là** : pas d'entrée d'en-tête de plus (D-02) ; la pastille de la lentille est prise par le compte « en écriture » ; le tiroir peut être fermé, donc ne convient pas à un compte lisible sans geste ; la rangée `.k` a de la place et ne dépend d'aucune phrase.
- **Forme courte jusqu'à 999 px** (F2) : au-dessus de 999 px, glyphe + phrase ; à 999 px et moins (seuil du menu « ⋯ ») glyphe + nombre (« 3 »), `aria-label` complet ; zone tactile 44 × 44 par pseudo-élément (comme `.ctx-more`), sans changer la hauteur de la rangée. Hauteur de `#context` mesurée avec et sans compte : identique par construction.
- **Bouton** (F1) : couleur `--text-2`, survol `--text`, focus par anneau `--ring` 2 px posé en pseudo-élément comme `.ctx-more` ; `pointer-events: auto` (`#context` est en `none`). Le compte n'existe que sur l'onglet Code (`#context` est réécrit par l'en-tête git et par les en-têtes Projet et Équipe : il est reposé après chaque réécriture). Portée : **le dépôt entier**, identique dans toutes les vues du Code (racine et plongées).
- À 0 collision, le compte n'est pas affiché (le zéro vit dans la ligne du radar du menu, § 1.2). **En construction ou calcul partiel** : le compte devient « Radar en cours de relecture » (≤ 999 px : glyphe + « … ») et la ligne du menu dit « Radar incomplet » ; **jamais** « aucune collision » à ce moment. Infobulle : version courte de § 3.4.
- **Annonce et focus** (F14 ; décision déléguée par Samuel, message session principale, 2026-11-08, option recommandée) : le passage du compte de 0 à n est annoncé **une seule fois** par la zone `role="status"` polie (« Radar : 3 fichiers en collision possible ») ; les variations suivantes ne le sont pas. À l'ouverture du panneau depuis le compte, le focus va sur le **titre** de la section « Collisions possibles » (`tabindex="-1"`) ; la carte ne bouge pas (Q12).

## 6. Gardes (D-16, D-17)

- Fichiers des six classes de `check-gate-touche.sh` : glyphe **bouclier**, mot « garde du dépôt ». Fichier de code qu'une suite ou un gate nomme : pas de glyphe, mot « nommé par 3 suites » (la liste des 3 premières en infobulle). Fichier de code qu'aucune suite ni aucun gate ne nomme : glyphe **bouclier barré**, mot « aucune suite ne le nomme » ; jamais « non testé » (P69-D-09).
- Carte de nœud : agrégat « 12 sur 40 sans témoin » + glyphe barré ; « tous nommés » sans glyphe si 0 ; la carte « non assignés » suit la même règle, son poids est dit dans la légende, jamais corrigé. Les cartes prévues, doc, suites et fixtures sont hors décompte.
- Lab non VibeFlow : lentille absente et dite (§ 1.3). Panneau d'un fichier : section « Gardes » (« Nommé par : » + au plus 5 suites ou gates en mono, puis « et n autres » ; ou « Aucune suite ni aucun gate ne le nomme »). Le mot reste neutre ; seul le glyphe distingue, par la forme.

## 7. Cartes « prévues » (D-18)

### 7.1 Rendu
Statut `prevu`, mécanisme `st-*` / `.vst` existant : classe `st-prevu` sur la carte, `.vst-prevu` dans le pied, mot **« Prévu »** (`STATE_WORD`), glyphe **anneau ouvert à trois arcs** (trois traits de 90° séparés de vides, plein pas de pointillé) `--st-todo`, mot `--text-2`, 11 px 500. Carte : fond transparent, une seule intention : bordure 1,5 px pointillée `--hair-2`, **sans** ombre (`--shadow-card` retirée) ; le padding perd 1,5 px de compensation (`calc(var(--inset-card) - 1.5px) /* dérivé : bordure 1,5 */`) pour que le contenu ne bouge pas ; titre mono 500 `--text-2` ; icône nue `--text-3` (pas la couleur de famille : le fichier n'existe pas) ; description : « Créé par le plan 75-02 » (`.desc` `--text-3`, une ligne). Aucun lien (la carte n'a pas d'arête).
### 7.2 Actions absentes
« Ouvrir » et « taille » n'existent pas sur une prévue (ni dans le menu contextuel, ni dans le panneau, ni de `.meta` de taille). Le panneau montre : titre, « Prévu par : 75-02, 75-04 » (plans en texte), « Ce fichier n'existe pas encore. ». Un chemin hors du lab ou malformé n'est pas dessiné (compté « n prévus ignorés » dans la légende de Gardes, où ils sont hors décompte).
### 7.3 Fraîcheur
Les cartes prévues ne se rafraîchissent qu'à l'assemblage du graphe ; les collisions « prévues » sont, elles, à jour. Textes : panneau d'une prévue, pied : « Carte lue à l'assemblage du graphe, il y a 12 min. » ; section Collisions, ligne d'un recoupement de plans : « Recoupement des plans : à jour. » Une carte prévue dont le fichier vient d'être créé reste « Prévu » jusqu'au prochain assemblage ; aucun texte ne prétend le contraire.

## 8. Accessibilité

- **Nom accessible de carte** (forme posée par la Phase 80, AUDC-BL2 : rôle bouton, nom) enrichi, dans cet ordre : `titre, type, taille ou statut existant, mot de lentille (complet), mot de collision (complet)` ; les marques visuelles du pied sont `aria-hidden` pour ne pas être lues deux fois. Exemples : « fichier vf-cockpit-git.mjs, 41 changements » ; « nœud cockpit, 3 chauds, 2 collisions ». Prévue : « …, prévu, créé par le plan 75-02 ». Aucune information portée par la teinte seule (glyphe de forme distincte + mot).
- **Ordre de lecture** : en-tête (bouton de lentille à sa place actuelle) → rangée « Code » et son compte de collisions, titre, sous-titre → cartes → panneau (sections : existantes, « Change souvent avec », « Gardes », « Agents sur ce fichier », « Collisions possibles »). Les marques ne sont pas des arrêts de tabulation.
- **Annonce d'un changement de lentille** : zone `role="status"` `aria-live="polite"` (une seule, déjà hors écran) : « Lentille Points chauds : 12 fichiers au palier haut. » ; « Lentille retirée. » ; « Lentille Points chauds indisponible. » ; couplage, à chaque nouvelle sélection (retardé de 300 ms) : « Couplage : 5 fichiers liés. ». Les mises à jour en direct de l'empreinte ne sont **pas** annoncées.
- **Clavier dans le menu** (même contrat que `#vf-plus-menu`) : l'ouverture met le focus sur la ligne cochée ; `↓`/`↑` circulent (bouclent), `Home`/`Fin` aux extrémités ; une ligne désactivée reste atteignable et muette ; `Entrée` ou `Espace` choisit, ferme le menu et rend le focus au bouton (au « ⋯ » quand le bouton est masqué, ≤ 999 px) ; `Échap` ferme et rend le focus ; clic hors du menu ferme. Focus visible `--ring` (2 px, décalage −2 comme `.vf-pl-i`). `aria-haspopup="menu"`, `aria-expanded`.
- Mouvement réduit : aucune animation nouvelle hors la respiration du glyphe « en cours », coupée sous `prefers-reduced-motion`. Cibles ≥ 44 px (lignes du menu, compte de collisions). Le thème ne s'anime jamais (inchangé).

## 9. Tokens utilisés (aucun nouveau jeton)
| Jeton | Usage |
|---|---|
| `--text-2` · `--text-3` · `--text-4` | mot ; glyphes neutres ; lu, fini, sous-libellés |
| `--recent` · `--recent-text` | glyphe « en cours » ; même glyphe sur `.card.module` en clair |
| `--st-todo` · `--hair-2` · `--hair` | glyphe et bordure d'une carte prévue ; filets du menu |
| `--surface` · `--raise` · `--bg` · `--menu-solid` · `--on` · `--on-text` · `--on-recent-text` · `--ring` | fonds de carte, menu, pastilles, focus |
| `--sp-2/4/6/8/12/16/20/24` · `--inset-row` · `--inset-pill` | grille fermée (P71.5-D-01) ; le seul dérivé : pied 28 = `calc(var(--sp-24) + var(--sp-4))` commenté `/* dérivé */` |
Interdits ici : tout `--sev-*` sur une marque, `--st-active`, `--st-blocked`, un fond teinté, liseré, anneau, halo, dégradé ; aucun jeton supprimé ni renommé (P71.5-D-29). `--recent` reste défini (il porte « en cours »). Le menu emploie `.menu`, `--shadow-float` : aucune nouvelle ombre, aucun rayon nouveau.

## 10. Sondes visuelles à rejouer (juges à captures, à l'exécution ; navigateur partagé : aucune capture à la planification)
Chaque sonde : clair et sombre, 1440, 1024, 390 ; une sonde verte sans témoin rouge ne prouve rien (mutant : retirer la règle, la sonde doit rougir).
| # | Sonde | Attendu |
|---|---|---|
| S1 | Créneau : bouton (1440) et entrée du « ⋯ » (1024, 390) | à la place de l'ancien « Travail récent » ; libellé « Lentille : Aucune » ; pastille = fichiers en écriture |
| S2 | Menu ouvert, cinq lentilles, clair et sombre | cinq lignes, légende de la lentille active, ligne radar ; rien ne pousse la carte (rect de la carte inchangé) |
| S3 | États : indisponible, gardes absentes, git absent, relecture, fenêtre vide | les phrases exactes de § 1.3 ; git absent : mêmes cartes, mêmes liens, aucune marque |
| S4 | Bascule de lentille ×5 puis mise à jour de l'empreinte | géométrie de toutes les cartes et pieds identique à 0 px (P75-D-03), aucun nouveau passage ELK |
| S5 | Contraste des glyphes (échantillon de pixels du masque) sur `--surface`, `--raise` (`.module`), `--bg` | ≥ 3:1 partout ; `--recent` clair sur `.module` pris par `--recent-text` |
| S6 | Lecture en niveaux de gris et simulation daltonienne, **rastérisée à 6 px et à l'échelle de seuil de `lod-low`** | silhouettes d'Empreinte deux à deux distinctes (rond, triangle, carré creux, tiret : écart de pixels allumés > 25 %) ; collision, garde, sans témoin distinguables sans la couleur |
| S6b | **Classement par aire** des paliers, rastérisés à 6 px et à l'échelle de seuil de `lod-low` | pixels allumés strictement croissants bas < moyen < haut, rapport ≥ 1,5 entre paliers voisins ; mutant : barres de 2,5 de large, la sonde doit rougir |
| S7 | Trois zooms (`lod` ouverture, `mid`, `low`) × chaque lentille | forme courte à `mid`, glyphe seul à `low`, bord droit de la marque dans la carte (marge ≥ 0, comme EK10), pas de rognage |
| S8 | Largeur : mot le plus long (« aucune suite ne le nomme », « modifié · vf-coder et 2 autres »), nom hostile (U+2028, très long, balises) | ellipse du mot, jamais du glyphe ; texte posé en `textContent` ; la marque ne sort pas de la carte |
| S9 | Couplage : sélection d'un fichier à 5 voisins, à 0, nœud sélectionné | marques seulement sur les voisins visibles ; section du panneau ; légende d'attente |
| S10 | Collisions : compte de la rangée `.k` (1440, 1024, 390), en construction, 0 | `#context` de même hauteur avec et sans compte (forme courte ≤ 999 px) ; annonce unique 0 → n, focus sur le titre de section ; jamais « aucune collision » en relecture ; ouvre la section du panneau |
| S11 | Carte prévue (+ avec collision de plans), paire « Prévu » / « À faire » à 16 px et à `lod-low` : les deux glyphes se distinguent (sinon trois arcs plus espacés) | bordure pointillée neutre, « Prévu » + glyphe pointillé, aucune action d'ouverture ni de taille, texte de fraîcheur |
| S12 | Clavier : menu (↓ ↑ Home Fin Entrée Échap), focus rendu au bon bouton, annonce du changement | conforme § 8 ; zone `role="status"` mise à jour une fois |
| S13 | Retrait : aucun `.rw`, aucune ligne « Surligner le travail récent » dans « Types de liens » | absent ; aucune règle `.recent`/`.recent-in` active |
| S15 | Ouverture du panneau depuis le compte de collisions | rect de chaque carte et transformation de la vue inchangés (Q12) ; focus sur le titre de section |
| S16 | Phrases exactes de § 3.4, § 5.4, § 7.3 et légende d'Empreinte, dans les deux thèmes | présentes mot pour mot, une par état |
| S17 | Collision compacte avec une lentille active, 3 zooms | glyphe + nombre avant la marque de lentille ; bord droit dans la carte ; bord bas dans le pied (marge ≥ 0) à `lod-mid` et `lod-low` |
| S18 | Compte de collisions à 800 px, panneau ouvert (`#context` plafonné) | forme courte, pas de rognage |
| S14 | Chaque marque dans les deux thèmes sur `.card.module` et `.card.dir` | pas d'ombre ni de fond ajoutés ; `--recent` jamais seul sur `--raise` en clair |

## 11. Points tranchés par cette spec, à connaître des plans
1. **Pied réservé à la construction** (§ 2.3) : changement de hauteur ponctuel des cartes sans pied (une fois, avec le placement).
2. **Compte de collisions dans la rangée `.k`** (§ 5.4), sous-titre intact.
3. **Collision compacte quand une lentille est active** (§ 5.2) : un seul emplacement de pied.
4. **Agrégat de gardes en forme courte** dans le pied (« 12 sur 40 sans témoin ») ; la phrase de D-17 vit dans l'infobulle et le panneau.
5. **Lentille non mémorisée** (Aucune au chargement) ; le menu est un volant de bureau et de « ⋯ » à la fois (même mécanique que « Types de liens »).
6. **Paliers du couplage** : 30 à 49 / 50 à 74 / 75 et plus (aucun seuil nouveau pour la sélection des voisins : D-08 en garde le filtre).
7. Dépendances « à revalider » de la 79 : l'empreinte vit sur A21 (signature des cibles), A22 (cible relative à l'arbre) et A24 (outils comptés) ; sans eux : phrases de § 3.4 et § 5.4 inchangées.

## 12. Amendements à `DESIGN.md` (F8 ; à poser par l'exécution, dans le même lot que les marques ; tableaux du § 2 et format M10 intacts)
1. **§ 2, « Graphe de code »** : ajouter une puce « Lentilles d'activité (Phase 75) : points chauds, couplage, gardes, empreinte marquent une carte par un glyphe neutre et un mot, jamais par une teinte ; la seule teinte est `--recent` (écriture en cours). »
2. **§ 5, Carte** : retirer la variante `recent` (anneau, `.rw`, `.recent-in`, retirés par P75-D-20) ; ajouter `st-prevu` : fond transparent, bordure pointillée 1,5 px `--hair-2`, sans ombre, glyphe anneau à trois arcs `--st-todo`, mot « Prévu ».
3. **§ 5, Pastille de statut** : « (`.vst`, `.rw`) » devient « (`.vst`) » ; ajouter la **marque de lentille** (`.lm`) : emplacement droit du pied, glyphe 1,45 em + mot 11 px `--text-2`, sans fond ; glyphes : barres 1/2/3 (largeur ≥ 3), confluent, bouclier, bouclier barré, rond, carré, tiret, triangle pleins, anneau à trois arcs ; `lod-low` : glyphe seul.
4. **§ 4, Carte** : un pied de 28 unités est réservé à toute carte marquable, posé à la construction du graphe (géométrie invariante au changement de lentille).
5. **§ 7, Icônes** : la liste des glyphes de pastille s'allonge de ceux du point 3 ; l'exception « glyphe d'une pastille de statut » couvre le glyphe « en cours » de l'empreinte.
6. **§ 9, Toujours** : « Sur `.card.module` en clair, un glyphe d'état prend la variante texte (`--recent-text`), jamais `--recent` (2,91:1). » **Jamais** inchangé (la bordure pointillée est neutre).
8. **§ 2** : `--recent` = « récent, succès, en cours d'écriture ». **§ 6** : la respiration du glyphe passe des tiroirs aux cartes (glyphe « en cours »). **§ 4** : compensation de la bordure de 1,5 px de la carte prévue, `/* dérivé : bordure 1,5 */`.
7. Le tableau « Statuts de travail » ne reçoit **pas** de ligne `--st-prevu` (le statut reprend `--st-todo`).

## 13. Intégration à la coquille (Phases 79 et 80 ; règles reçues du manager le 2026-11-11)
- **Initialisation par onglet** (A30 de la 79, commit `74501bb0`) : lentilles, empreinte, radar et compte de collisions s'initialisent par `VF_COQUILLE.surOnglet(rappel)` (le rappel reçoit `{onglet}`, appelé après le premier rendu puis à chaque changement d'onglet sans rechargement), jamais au seul chargement. Ils se posent quand l'onglet vaut Code ; la fonction rendue par le rappel, appelée avant le changement suivant, retire écouteurs, minuteries et DOM posé (bouton ou entrée de lentille, marques, compte, menu, zone d'annonce).
- **Objet du moteur gelé** (Phase 80, `Object.freeze`) : rien n'est ajouté à l'objet global du moteur à l'exécution. Le canal de marquage (P75-D-05) vit dans un **espace de noms à part** (nom de travail `VF_MARQUES`) ; son point d'accroche dans le rendu des cartes (lecture de la table `id → marque`) est posé dans le **source du moteur** (fork assumé, AUDC-Q5, tracé dans `VENDORED.txt`).
- **Surcouches** : le menu `#lens-menu` passe par `window.VF_SURCOUCHES` : `ouvrir(el, {modale: false, ouvreur, fermer})`, `dessus()`, `ouverte()` ; Échap, retour du focus et fermeture au clic extérieur viennent de la pile (le contrat du § 8 reste le résultat attendu). Réserve : je n'ai pas pu lire P80-D-33 à D-41 dans `80-CONTEXT.md` (branche `origin/feat/phase-80-trois-formes`) ; l'API est reprise du message du manager.
