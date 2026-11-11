# Lexique de craft UI — 20 concepts à connaître, appliquer et doser

> **Rôle** : vocabulaire de finition d'interface partagé par l'équipe dev. `vf-dev-manager` le
> cite dans le digest de toute étape qui touche une UI, `vf-coder` l'applique en implémentant,
> `vf-reviewer` le vérifie sur l'axe Standards. Générique multi-stack (web, iOS, Android, React
> Native) — les exemples nomment l'API de chaque stack, aucune n'est imposée.
>
> **Ce n'est pas une direction artistique.** Le `DESIGN.md` du projet (la DA) prime toujours :
> ce lexique dit *comment bien exécuter*, jamais *quel style adopter*. En cas de conflit, la DA
> gagne et le conflit est signalé au rapport.

## Règle de dosage (avant les 20 termes)

1. **Pertinence d'abord** : un concept s'applique quand l'écran en a besoin, pas parce qu'il est
   dans la liste. Un écran de réglages n'appelle ni stagger ni shared element transition. Le
   digest du manager cite les quelques termes que l'étape appelle — jamais les 20 par réflexe ;
   le manager juge leur application au retour des workers, il ne la fait pas.
2. **Le geste le plus discret qui règle le problème** : 1–2 px de correction optique, pas 8 ; une
   animation de 200 ms, pas 600 ; un niveau de divulgation, pas trois.
3. **Mouvement = sens** : toute animation explique une relation (d'où vient l'élément, où il va).
   Une animation qui ne dit rien est retirée. `prefers-reduced-motion` (web) / *Reduce Motion*
   (iOS) / *Remove animations* (Android) est respecté **toujours** : fondu court ou rien.
4. **Ne jamais réimplémenter un composant accessible** qu'une librairie du projet fournit déjà
   (combobox, menu, dialog) : on le configure.
5. **Déclarer ce qu'on a appliqué** : `vf-coder` liste au rapport les termes appliqués et ceux
   écartés à dessein (« stagger écarté : liste rechargée à chaque frappe »). Un écart motivé n'est
   pas un manque.

## Quels termes pour quel écran (aide au digest)

| L'étape touche… | Termes à citer dans le digest |
|---|---|
| Chiffres qui changent, tableaux, prix, compteurs | 3, 4 |
| Chargement asynchrone, images, polices web | 4 |
| Texte long, article, documentation, onboarding | 7, 9, 12, 15 |
| Titres, hero, marque | 1, 5, 7, 12 |
| Formulaire, saisie, recherche | 8, 16, 17 |
| Menus, popovers, tooltips, panneaux | 10, 18 |
| Listes qui apparaissent, navigation entre écrans | 14, 18, 20 |
| Écran mobile ou tactile | 8, 13 |
| Action réseau déclenchée par l'utilisateur | 6, 4 |
| Couleurs, thème, états (hover, focus, sombre) | 11, 16 |
| Écran dense, options avancées | 19 |
| Icône dans un bouton, contenu centré | 2 |

---

## Typographie

### 1. Kerning
**Quoi** : ajustement de l'espace entre *deux lettres précises* (« AV », « To ») défini par la
police. **Appliquer** : laisser le kerning de la police actif (`font-kerning: normal`, défaut des
navigateurs ; actif par défaut sous iOS/Android). Retoucher à la main seulement un logotype ou un
titre très grand où une paire bâille visiblement. **Doser** : jamais de kerning manuel sur du texte
courant. **Contrôle** : aucun `font-kerning: none` ni `font-feature-settings: "kern" 0` hors motif écrit.

### 5. Tracking
**Quoi** : espacement *uniforme* de toutes les lettres d'un bloc (`letter-spacing`, `tracking()`
en SwiftUI, `letterSpacing` en Android/RN). **Appliquer** : légèrement positif sur les capitales
et petits libellés (+0,04 à +0,1 em) ; légèrement négatif sur les grands titres (−0,01 à −0,03 em) ;
zéro sur le texte courant. **Doser** : au-delà de ±0,1 em le texte se désagrège. **Contrôle** : tout
`text-transform: uppercase` porte un tracking positif ; aucun tracking non nul sur un paragraphe.

### 7. x-height
**Quoi** : hauteur des minuscules (le « x ») ; c'est elle, plus que la taille nominale, qui fait la
lisibilité perçue. **Appliquer** : pour les petites tailles d'interface, une police à grand
x-height ; quand deux polices cohabitent sur une ligne, égaliser leur x-height
(`font-size-adjust` en CSS, ou ajuster la taille de la seconde à l'œil). **Doser** : ne change pas
de police pour ça si la DA en impose une. **Contrôle** : texte d'UI ≥ 14 px (web) / 11 pt (iOS)
/ 12 sp (Android) quand la police a un petit x-height.

### 9. Leading
**Quoi** : interligne (`line-height`, `lineSpacing` SwiftUI, `lineHeight` RN/Android).
**Appliquer** : texte courant 1,4–1,6 ; titres 1,1–1,25 ; libellés d'une ligne ≈ 1,2. Plus la
ligne est longue, plus l'interligne augmente. En CSS, valeur sans unité (`1.5`) pour qu'elle
suive la taille. **Doser** : un interligne de paragraphe sur un titre l'éclate. **Contrôle** :
aucun `line-height` en `px` fixe sur un texte dont la taille varie.

### 12. Widow (veuve)
**Quoi** : mot isolé seul sur la dernière ligne d'un titre ou paragraphe. **Appliquer** :
`text-wrap: balance` sur les titres courts, `text-wrap: pretty` sur les paragraphes (web) ;
espace insécable entre les deux derniers mots d'un titre critique. **En français** : espace
insécable (fine de préférence) avant `: ; ! ?` et à l'intérieur des guillemets « », sinon la
ponctuation part seule à la ligne. **Doser** : ne pas truffer le texte de `&nbsp;` ; les
propriétés `text-wrap` suffisent la plupart du temps. **Contrôle** : titres avec `balance`,
ponctuation française sans retour à la ligne orphelin.

### 15. Line length (mesure)
**Quoi** : nombre de caractères par ligne. **Appliquer** : 45–75 caractères, ~66 idéal en
lecture continue ; `max-width: 65ch` sur le bloc de texte, 35–50 sur mobile. **Doser** : les
tableaux, listes et UI denses n'obéissent pas à cette règle — elle vise la lecture continue.
**Contrôle** : aucun paragraphe pleine largeur sur un écran de bureau.

### 3. Tabular numbers
**Quoi** : chiffres à chasse fixe — chaque chiffre occupe la même largeur. **Appliquer** :
compteurs, minuteurs, prix en colonne, tableaux, toute valeur qui change en direct
(`font-variant-numeric: tabular-nums` ; `.monospacedDigit()` SwiftUI ;
`fontVariant: ['tabular-nums']` RN ; `fontFeatureSettings = "tnum"` Android). **Doser** : pas
dans la prose ni les titres, où les chiffres proportionnels sont plus beaux. **Contrôle** : une
valeur qui s'incrémente ne fait pas bouger le texte voisin.

## Mise en page et géométrie

### 2. Optical centre
**Quoi** : le centre *perçu* diffère du centre géométrique — il est un peu plus haut, et une
forme asymétrique (triangle « lecture ») paraît décentrée quand elle est mathématiquement
centrée. **Appliquer** : décaler l'icône « play » de ~1–2 px vers la pointe ; placer un contenu
seul dans un grand cadre (modale, état vide) légèrement au-dessus du centre ; vérifier les
capitales sans descendantes dans un bouton. **Doser** : corrections de 1–2 px, jamais un décalage
visible comme tel. **Contrôle** : l'œil, sur capture — ce terme se juge en rendu, pas en code.

### 4. Layout shift
**Quoi** : contenu qui saute pendant ou après le chargement (métrique web CLS, cible < 0,1).
**Appliquer** : réserver la place des images et médias (`width`/`height` ou `aspect-ratio`) ;
squelettes de la taille du contenu final ; polices web avec `font-display: swap` et police de
repli aux métriques ajustées (`size-adjust`) ; ne jamais insérer de contenu *au-dessus* de ce que
l'utilisateur lit ; ne pas changer la graisse ou la largeur d'un élément au survol. **Doser** :
un saut déclenché par l'utilisateur lui-même (dérouler un accordéon) n'est pas un défaut.
**Contrôle** : aucune `<img>` sans dimensions ; rendu observé pendant le chargement.

### 13. Safe area
**Quoi** : zone non masquée par l'encoche, la Dynamic Island, la barre d'accueil ou les coins
arrondis. **Appliquer** : web `viewport-fit=cover` + `env(safe-area-inset-*)` ; SwiftUI zones
sûres respectées par défaut (`safeAreaInset` pour une barre) ; RN
`react-native-safe-area-context` ; Android `WindowInsets`. Les fonds peuvent déborder sous les
bords ; le contenu interactif et le texte, jamais. **Contrôle** : aucun bouton sous la barre
d'accueil ni sous l'encoche, en portrait et en paysage.

### 8. Touch target
**Quoi** : zone touchable d'un élément. **Appliquer** : 44×44 pt (iOS), 48×48 dp (Android),
24×24 px minimum en web (WCAG 2.5.8), 44 px recommandé ; agrandir la *zone* sans grossir le
*visuel* (padding, pseudo-élément, `hitSlop` RN, `contentShape` SwiftUI) ; ≥ 8 px entre deux
cibles voisines. **Contrôle** : aucune icône cliquable de 16 px sans zone étendue.

## Couleur

### 11. OKLCH
**Quoi** : espace colorimétrique perceptuellement uniforme — L (luminosité), C (chroma), H
(teinte). À L égal, deux teintes paraissent aussi claires l'une que l'autre, ce que HSL ne
garantit pas. **Appliquer** : construire les échelles (50→900) en faisant varier L à teinte
fixe ; dériver les états (survol, pressé) par un pas de L ; générer un thème sombre en
déplaçant L. **Doser** : ne pas convertir une palette hex existante qui fonctionne ; une chroma
élevée sort du gamut sRGB → prévoir un repli ; le contraste WCAG reste à **mesurer**, OKLCH le
rend prévisible, pas garanti. **Contrôle** : contraste texte ≥ 4,5:1 (≥ 3:1 en grand texte).

## Interaction et composants

### 16. Affordance
**Quoi** : ce que l'apparence d'un élément promet de faire (un bouton a l'air pressable, une
poignée a l'air saisissable). **Appliquer** : chaque élément interactif a ses états survol,
focus visible, pressé, désactivé ; les liens se distinguent autrement que par la seule couleur ;
le curseur suit. **Doser** : pas de *fausse* affordance — un texte souligné non cliquable, une
carte avec ombre et curseur main qui ne mène nulle part. **Contrôle** : navigation au clavier,
focus visible sur chaque élément interactif.

### 17. Combobox
**Quoi** : champ de saisie couplé à une liste de suggestions filtrée (autocomplétion), motif
ARIA `role="combobox"` avec `aria-expanded`, `aria-controls`, `aria-activedescendant`, et
clavier ↑ ↓ Entrée Échap. **Appliquer** : à partir de ~10–15 options, un select devient
combobox ; utiliser le composant accessible déjà présent dans le projet (Radix, React Aria,
Headless UI, cmdk…), jamais une réimplémentation maison. **Contrôle** : utilisable entièrement
au clavier, annoncé par un lecteur d'écran.

### 6. Optimistic update
**Quoi** : l'interface reflète l'action *avant* la réponse du serveur, puis annule si elle échoue.
**Appliquer** : actions fréquentes, réversibles, quasi toujours réussies (aimer, cocher,
réordonner, renommer). Annulation visible et message clair en cas d'échec. **Doser** : jamais pour
un paiement, une suppression définitive, ou une action dont le serveur décide le résultat.
**Contrôle** : chaque mise à jour optimiste a son chemin d'annulation testé (réseau coupé).

### 19. Progressive disclosure
**Quoi** : montrer l'essentiel, révéler le reste à la demande (« Options avancées », détails
repliés, étapes). **Appliquer** : ce dont la majorité des utilisateurs a besoin reste visible ;
le rare et l'expert se replient. **Doser** : deux niveaux au plus ; ne jamais cacher une action
primaire ni une information qui conditionne une décision (prix, conséquence d'une suppression).
**Contrôle** : la tâche principale de l'écran se fait sans rien déplier.

## Mouvement

### 10. Origin-aware animation
**Quoi** : un élément qui apparaît part de ce qui l'a déclenché — un menu grandit depuis son
bouton, pas depuis le centre de l'écran. **Appliquer** : `transform-origin` calé sur
l'ancre (Radix expose `--radix-*-content-transform-origin`) ; échelle de départ 0,95–0,98 plutôt
que 0. **Doser** : une modale centrée sans déclencheur spatial reste centrée. **Contrôle** : un
popover ouvert vers le haut ne grandit pas vers le bas.

### 14. Stagger
**Quoi** : décalage temporel entre les éléments d'un groupe qui entrent l'un après l'autre.
**Appliquer** : 20–50 ms par élément, plafonné (au-delà de ~8 éléments, les suivants entrent
ensemble ; durée totale < 400 ms). **Doser** : à l'entrée d'un écran seulement — jamais à chaque
rafraîchissement, filtrage ou frappe. **Contrôle** : rien ne rejoue l'animation sur une mise à
jour de données.

### 18. Interruptible animation
**Quoi** : animation qu'on peut interrompre ou inverser en vol sans saut, en repartant de l'état
courant. **Appliquer** : transitions CSS (pas `@keyframes`) pour les bascules d'état ; ressorts
(springs) de Framer Motion / Reanimated / SwiftUI, qui repartent de la vitesse en cours ;
l'interface reste réactive pendant l'animation. **Doser** : ne jamais bloquer une saisie le temps
qu'une animation finisse. **Contrôle** : un double clic rapide sur une bascule ne produit ni saut
ni état incohérent.

### 20. Shared element transition
**Quoi** : un élément présent sur deux écrans se transforme de l'un à l'autre (vignette →
détail) pour garder la continuité. **Appliquer** : View Transitions API
(`view-transition-name`) en web, `layoutId` Framer Motion, `matchedGeometryEffect` /
`navigationTransition(.zoom)` SwiftUI, transitions partagées Reanimated en RN. **Doser** : un
seul élément héros par transition ; repli propre sans support (simple fondu) ; désactivé en
mouvement réduit. **Contrôle** : la navigation reste correcte quand l'API n'est pas disponible.

---

## Durées de référence (mouvement)

Micro-retour (pression, survol) 100–150 ms · apparition de menu ou popover 150–250 ms ·
changement d'écran 250–400 ms. Sortie plus rapide que l'entrée. Courbe d'accélération qui
décélère à l'arrivée (`ease-out` ou ressort amorti) pour ce qui entre.
