# Phase 71 : Terminal intégré au cockpit — Spécification d'écran (UI-SPEC)

**Écran :** le tiroir de terminal (côté page Projet / Code) et la page du terminal qu'il encadre (côté serveur Q).
**Direction artistique :** « Graphite » (`DESIGN.md`, PR #196 non mergée). Le CSS de
`plugin/cockpit/skills/cockpit-moteur/assets/viewer.html` (`:root` l.33, `:root[data-theme="light"]` l.66) fait foi : toute valeur
ci-dessous est une variable Graphite existante, ou une valeur dérivée dont le calcul est donné.
**Cadrage :** `71-CONTEXT.md` (P71-D-01, D-05, D-07, D-08, D-12, D-13, D-15, D-16). Exigence d'usage de Samuel : « vraiment je
veux que ça soit comme un terminal. Après dans l'idéal dans la même fenêtre » ; « un peu comme dans VS code et fermer ».
**Nature :** spec multi-stack, aucun code imposé. Stack réelle : HTML/CSS/JS vanilla, xterm.js 6.0 (moteur DOM).

Vocabulaire : **P** = page du cockpit (`http://127.0.0.1:P`, qui porte le tiroir). **Q** = page du terminal
(`http://127.0.0.1:Q`, d'une autre origine, encadrée par P). Le **tiroir** est le conteneur côté P ; le **cadre** est l'`iframe`.

---

## 1. Principes de conception (ce qui tranche les cas limites)

1. **Un terminal, pas un widget.** Le cadre est plein fond, sans décoration propre : pas de titre, pas de bordure, pas de carte
   autour du terminal. Tout le chrome (titre, plein, fermer, redimensionner) est côté P, dans une barre de 36 px. Le terminal
   occupe le reste, bord à bord, avec une marge intérieure de texte seulement.
2. **Rien par défaut.** Sans `--terminal`, zéro trace (§5, état « absent »).
3. **Aucune touche volée au shell.** Quand le focus est dans le terminal, seule une combinaison que les shells ne peuvent pas
   émettre est interceptée (§7).
4. **Aucun piège clavier.** On peut toujours sortir du terminal au clavier (§7). C'est le point d'accessibilité bloquant de
   l'écran, il pèse dans le finding F1.
5. **Graphite, sans accent nouveau.** Monochrome. Le seul accent est le vert `--recent` (session vivante) ; l'ambre et le rouge
   n'apparaissent que pour un état d'alerte, doublés d'un texte (jamais la couleur seule).
6. **Calme.** Aucune animation obligatoire ; le changement de thème n'est jamais animé ; tout mouvement a sa variante
   `prefers-reduced-motion`.

---

## 2. Anatomie

### 2.1 Côté P : le bouton d'ouverture (« poignée »), tiroir fermé

- Pastille fixe en bas à gauche : `left: 16px; bottom: 16px`, `position: fixed`, `z-index: 6` (au-dessus de `#ask` z4, `#panel` z5 ;
  sous menus z30, modales z40, toast z50).
- Hauteur 32 px, rayon 999 px (pilule), padding `0 12px 0 10px`. Icône `svg.i` « invite de commande » (`>_`, trait 1,75,
  16 × 16, `stroke: currentColor`) + libellé « Terminal » 13 px / 500.
- Couleurs : fond `--raise`, texte `--text-2`, filet `1px solid var(--hair-2)`, ombre `--shadow-card`. Survol : fond `--raise-2`,
  texte `--text`. Focus clavier : `outline: 2px solid var(--ring); outline-offset: 2px`.
- Info-bulle (`title`) et `aria-label` : « Ouvrir le terminal (Ctrl+Maj+Espace) ».
- Un point de 6 px `--recent` après le libellé quand une session est vivante alors que le tiroir est fermé (le shell tourne
  encore), avec `aria-label` complété : « Ouvrir le terminal, une session est en cours ». Ce point n'existe que si le canal
  d'état de F1 est accepté.
- Quand le tiroir est ouvert, la pastille est masquée (la barre du tiroir porte « Fermer »).

### 2.2 Côté P : le tiroir ouvert

Conteneur `role="region"`, `aria-label="Terminal"`, fixe, `z-index: 8` (sous les menus, modales, toast ; au-dessus du panneau
latéral). Il se pose au-dessus du plan sans le pousser (règle « Panneau, tiroir » de DESIGN.md §5).

| Propriété | Valeur |
|---|---|
| Gauche / bas | `16px` / `16px` |
| Droite | `16px` si `body.no-panel`, sinon `var(--pw)` (le tiroir s'arrête à 16 px du panneau latéral, qui suit son redimensionnement) |
| Rayon | `--r-panel` (24 px), `overflow: hidden` |
| Ombre | `--shadow-float` (aucune autre ombre) |
| Fond | `--surface` (identique au fond du terminal, pour qu'aucune couture ne se voie) |
| Hauteur par défaut | 320 px (barre de 36 px comprise) |
| Hauteur minimale | 160 px |
| Hauteur maximale | jusqu'à `calc(100dvh - var(--hh, 64px) - 12px - 16px)` (état « plein ») |

**Barre du tiroir** (36 px, fond `--raise`, filet bas `1px solid var(--hair)`, padding `0 8px 0 14px`, items alignés au centre) :

1. Gauche : pastille d'état 8 px (`--text-4` inactif, `--recent` connecté, `--sev-medium` reconnexion, `--sev-high`
   arrêté ou expiré) puis le titre « Terminal » 13 px / 500 `--text`, puis un libellé d'état 12 px / 400 `--text-3`
   (« Connecté », « Reconnexion… », « Terminé », « Arrêté »). L'état n'est jamais porté par la couleur seule.
2. Droite : deux boutons icône 28 × 28 px (cible ≥ 24 px), rayon 8 px, icône 16 px `--text-2`, survol fond `--raise-2` et icône
   `--text`, focus `outline: 2px solid var(--ring); outline-offset: -2px` :
   - **Agrandir / Réduire** (bascule plein) : `aria-label` « Agrandir le terminal » / « Réduire le terminal », `aria-pressed`
     reflète l'état plein.
   - **Fermer** : `aria-label` « Fermer le terminal (Ctrl+Maj+Espace) ».

**Poignée de redimensionnement** : bord supérieur du tiroir, zone active de 24 px de haut centrée sur le bord (12 px de part et
d'autre), `cursor: ns-resize`. Grip visible : pilule 40 × 4 px, `rgba(var(--ink), .14)`, opacité 0 au repos, 1 au survol, au
focus et pendant le glissement (même grammaire que `#panel-resize`). Détails §8.

**Cadre** : `iframe` sous la barre, remplit le tiroir. `title="Terminal"`. `sandbox="allow-scripts allow-same-origin"` (Q a besoin
de son `localStorage` et de `fetch` vers sa propre origine ; rien d'autre : ni `allow-top-navigation`, ni `allow-popups`,
ni `allow-forms`). Si la politique de permissions l'exige pour les liens cliquables du terminal : `allow-popups
allow-popups-to-escape-sandbox` seulement, avec `noopener` (P71-D-16). Pas d'attribut `allow` (pas de presse-papiers : P71-D-16).
Pendant un glissement de la poignée, le cadre reçoit `pointer-events: none` (sinon il avale les mouvements de souris).

### 2.3 Côté Q : la page du terminal

- Pleine page, `background` = fond du terminal (§4), aucune barre, aucun titre. Marges intérieures du terminal : `8px 12px`
  (haut-bas / gauche-droite), prises dans le calcul d'ajustement (`addon-fit` mesure l'élément intérieur, pas la fenêtre).
- Défilement : la barre de défilement de xterm est fine (12 px de zone, curseur arrondi `rgba(var(--ink), .1)` comme `#panel`),
  valeurs au §4.3.
- États non terminal (refusé, expiré, arrêté) : une **carte d'état** centrée (§6.2). États avec contenu à préserver (shell
  terminé, reconnexion) : un **bandeau** bas de 44 px par-dessus la dernière sortie (§6.3).
- La page ne porte aucun lien de navigation, aucun menu : tout geste hors terminal passe par le chrome de P.

---

## 3. Jetons

### 3.1 Variables Graphite utilisées (P et Q)

Aucune couleur en dur. Côté P, les variables existent déjà (le script `9x-vf-terminal.js` n'ajoute que des classes `vf-term-*`,
préfixées, dans sa propre feuille ; il ne touche pas `viewer.html`).

| Rôle dans l'écran | Variable |
|---|---|
| Fond du tiroir et du terminal | `--surface` |
| Barre du tiroir, pastille fermée, carte d'état, bandeau | `--raise` ; survol `--raise-2` |
| Filets | `--hair`, `--hair-2` |
| Texte titre / courant / secondaire / éteint | `--text` / `--text-2` / `--text-3` / `--text-4` |
| Bouton plein (Relancer, Réessayer) | `--on` sur `--on-text`, survol `--on-hover` |
| Focus | `--ring` (2 px) ; fond de halo éventuel `--focus` |
| État connecté | `--recent` |
| État d'attention / reconnexion / refusé | `--sev-medium`, texte d'alerte `--warn-text`, fond `--warn-bg` |
| État d'erreur / expiré / arrêté | `--sev-high`, texte `--err-text` |
| Rayons | `--r-panel` (tiroir), `--r-card` (carte d'état), `--r-ctl` (bandeau), 8 px (boutons icône), 999 px (pastille) |
| Ombres | `--shadow-card` (pastille), `--shadow-float` (tiroir) |
| Animation | `--ease`, 250 ms |
| Polices | `--mono` (terminal), `--sans` (chrome et cartes) |
| Teinte des filets et voiles | `--ink` |

### 3.2 Jetons propres à l'écran (valeurs, pas de nouvelle famille d'ombres, rayons ou courbes)

| Jeton | Valeur | Justification |
|---|---|---|
| `--vf-term-h` | hauteur courante du tiroir en px, posée sur `body` quand il est ouvert, `0px` sinon | laisse le reste de la page réserver la place |
| Barre du tiroir | 36 px | cible ≥ 24 px, assez dense |
| Hauteur par défaut / min | 320 px / 160 px | ≈ 18 lignes de 13 px confortables ; au-dessous, `claude` devient inutilisable |
| Pas de clavier de la poignée | 24 px ; Maj = 96 px | 1 ligne ≈ 13 px, 24 px évite le micro-pas |

### 3.3 Variables recopiées côté Q (la page Q ne peut pas hériter de P)

Q redéclare, dans sa propre feuille, seulement ces variables, sous `:root` (sombre) et `:root[data-theme="light"]`, avec **les
mêmes valeurs** que `viewer.html` : `--ink`, `--surface`, `--raise`, `--raise-2`, `--hair`, `--hair-2`, `--text`, `--text-2`,
`--text-3`, `--text-4`, `--on`, `--on-hover`, `--on-text`, `--ring`, `--recent`, `--sev-medium`, `--sev-high`, `--warn-bg`,
`--warn-text`, `--err-text`, `--r-card`, `--r-ctl`, `--sans`, `--mono`, `--ease`. Le thème vient de `?theme=dark|light`
(valeur absente ou invalide : `dark`) ; il pose `data-theme="light"` sur `<html>` avant le premier rendu (pas de flash).
Risque de dérive : voir F7 (test de parité des valeurs avec `viewer.html`).

---

## 4. Thème xterm.js (valeurs finales, deux thèmes)

### 4.1 Options du terminal

| Option | Valeur | Pourquoi |
|---|---|---|
| `fontFamily` | la pile `--mono` : `"JetBrains Mono", ui-monospace, "Cascadia Code", "SF Mono", Consolas, monospace` | pile de DESIGN.md §3 ; aucune police externe |
| `fontSize` | 13 | niveau « Interface » de DESIGN.md |
| `lineHeight` | **1** | le moteur DOM ne dessine pas les caractères de tracé par lui-même : avec un interlignage > 1 les traits `│ ─ ┌` de l'interface de `claude` se coupent. À valider en recette (F3). |
| `letterSpacing` | 0 | cellules exactes |
| `fontWeight` / `fontWeightBold` | `400` / `600` | seules graisses du système (500 et 600 ; 700 réservé) ; 600 pour le gras |
| `drawBoldTextInBrightColors` | `false` | le gras ne change pas la teinte (évite le saut de contraste) |
| `minimumContrastRatio` | **4.5** | filet de sécurité : tout couple texte/fond d'un programme est relevé à 4,5:1 ; ne touche pas le noir ANSI sur fond coloré (déjà ≥ 4,5) |
| `cursorStyle` / `cursorBlink` | `block` / `false` | pas de clignotement (aucune animation obligatoire) |
| `cursorInactiveStyle` | `outline` | le curseur devient un contour quand le terminal n'a pas le focus : indice de focus sans bordure |
| `macOptionIsMeta` | **`false`** | sur clavier français macOS, `{ [ ] | \ ~ @` passent par Option ; la mettre en Meta les rendrait intapables |
| `scrollback` | 5000 | mémoire du navigateur seulement (TERM-11) |
| `windowOptions` | tout à `false` | pas de CSI 21t ni de manipulation de fenêtre (TERM-10) |
| `screenReaderMode` | `false` | coût de rendu élevé avec l'interface plein écran de `claude` ; lacune tracée (F6) |
| Liens | clic seulement, `noopener` | P71-D-16 |

Attendre `document.fonts.ready` avant le premier ajustement (`fit`) : le moteur DOM mesure la cellule une fois ; une mesure
faite avec la police de secours décale toute la grille quand JetBrains Mono arrive.

### 4.2 Palette (fond, texte, curseur, sélection, 16 ANSI)

Dérivée des variables Graphite. Contrastes WCAG calculés contre le fond du terminal (sombre `#191919` = `--surface`, clair
`#ffffff` = `--surface`). Cible ≥ 4,5:1 pour tout texte, sauf mention.

| Clé xterm | Sombre | Clair | Origine (Graphite) |
|---|---|---|---|
| `background` | `#191919` | `#ffffff` | `--surface` |
| `foreground` | `#ececec` (14,88) | `#161616` (18,10) | `--text` |
| `cursor` | `#ececec` | `#161616` | `--on` |
| `cursorAccent` (glyphe sous le curseur) | `#0f0f0f` | `#ffffff` | `--on-text` |
| `selectionBackground` | `rgba(255,255,255,.12)` | `rgba(0,0,0,.08)` | `rgba(var(--ink), α)` |
| `selectionInactiveBackground` | `rgba(255,255,255,.07)` | `rgba(0,0,0,.05)` | idem |
| `black` (0) | `#2b2b2b` (1,24, voir note) | `#161616` (18,10) | `--raise-2` / `--text` |
| `red` (1) | `#f28b8b` (7,40) | `#c94a4a` (4,60) | `--sev-high` |
| `green` (2) | `#4ade80` (10,09) | `#157a3a` (5,42) | `--recent` |
| `yellow` (3) | `#f0c36b` (10,65) | `#946000` (5,34) | `--sev-medium` |
| `blue` (4) | `#7aa7ff` (7,37) | `#1f5fd6` (5,73) | `--k-http` |
| `magenta` (5) | `#b49cff` (7,65) | `#6a45d6` (6,11) | `--k-call` |
| `cyan` (6) | `#63d2b8` (9,58) | `#0b7f6b` (4,93) | `--k-data` |
| `white` (7) | `#b4b4b4` (8,48) | `#3f3f3f` (10,53) | `--text-2` |
| `brightBlack` (8) | `#8b8b8b` (5,16) | `#595959` (7,00) | `--text-3` |
| `brightRed` (9) | `#f6a5a5` (9,08) | `#b42323` (6,55) | `--err-text` |
| `brightGreen` (10) | `#86efac` (12,52) | `#14603f` (7,57) | `--recent` éclairci / `--ok-text` |
| `brightYellow` (11) | `#f3d79b` (12,56) | `#6b4500` (8,48) | `--warn-text` |
| `brightBlue` (12) | `#9dbcff` (9,27) | `#1747a8` (8,39) | `--k-http` éclairci / assombri |
| `brightMagenta` (13) | `#c7b8ff` (9,82) | `#5233b8` (8,32) | `--n-symbol` / `--k-call` assombri |
| `brightCyan` (14) | `#86e3cd` (11,62) | `#0a6a5a` (6,52) | `--k-data` éclairci / assombri |
| `brightWhite` (15) | `#ececec` (14,88) | `#161616` (18,10) | `--text` |

Notes :
- **Noir ANSI (0), thème sombre : 1,24:1, assumé.** C'est un fond (texte noir sur pastille colorée, 10:1 et plus), pas un texte. Si un
  programme l'imprime en texte, `minimumContrastRatio: 4.5` le relève.
- **Inversion du thème clair.** Les « clairs » (8 à 15) y sont plus *foncés* que les normaux (convention des thèmes clairs) ;
  `white` (7) y est le gris le plus foncé qu'on lit encore comme « blanc cassé » sur du texte, et `brightWhite` est le texte plein.
- **Texte atténué (SGR 2)** : xterm applique une opacité de 0,5, donc sous 4,5:1 par construction. Volontairement faible
  (suggestions de l'invite zsh, aide secondaire). Hors garantie, tracé en F6.
- **Sélection** : un voile léger, texte lisible dessous. Sous la sélection sombre `#353535`, le texte courant garde 10,38:1 et
  les couleurs vives ≥ 5,1:1 ; `brightBlack` tombe à 3,6:1 sous sélection (transitoire, accepté). Clair `#ebebeb` : texte courant 15,18:1,
  rouge 3,86:1 (accepté sous sélection, transitoire).
- Aucune couleur de marque, aucun dégradé. Le vert ANSI est l'accent `--recent`, comme partout dans le cockpit.

### 4.3 Barre de défilement (si exposée par le thème xterm 6.0)

| Clé | Sombre | Clair |
|---|---|---|
| `scrollbarSliderBackground` | `rgba(255,255,255,.10)` | `rgba(0,0,0,.10)` |
| `scrollbarSliderHoverBackground` | `rgba(255,255,255,.18)` | `rgba(0,0,0,.20)` |
| `scrollbarSliderActiveBackground` | `rgba(255,255,255,.28)` | `rgba(0,0,0,.30)` |

(`rgba(var(--ink), α)` : mêmes teintes que la barre de `#panel`.)

### 4.4 Changement de thème

Le thème est lu dans P (`data-theme` sur `<html>`, absent = sombre) à l'ouverture et passé en `?theme=`. À chaque bascule de thème
du cockpit (`html.theme-switching`), P remplace l'adresse du cadre par la même page avec le nouveau paramètre (sans entrée d'historique) ;
Q se rattache à la session et rejoue le tampon de reprise (256 Ko, P71-D-05). Pendant ce rechargement, le fond du tiroir (`--surface`
du nouveau thème, posé par P dans la même image que la bascule) évite tout flash blanc ou noir. **Jamais d'animation** à la bascule.
Conséquence acceptée : l'historique au-delà du tampon est perdu à la bascule (F2).

---

## 5. États du tiroir (côté P)

| État | Déclencheur | Rendu | Texte (FR) | Persistance |
|---|---|---|---|---|
| **Absent** | cockpit lancé sans `--terminal` | **Aucun nœud DOM, aucune feuille de style, aucun écouteur clavier, aucune clé de stockage, aucun cadre.** Le script se retire dès qu'il lit l'absence de configuration. | aucun | aucune |
| **Indisponible (Windows)** | `--terminal` sous Windows (P71-D-07) | une puce non interactive à la place de la pastille (même emplacement, `role="status"`, fond `--raise`, texte `--text-3`, pas de survol, pas de cadre, aucun second serveur) | « Terminal indisponible sous Windows. » | aucune |
| **Fermé** | défaut au premier chargement, ou fermeture | pastille « Terminal » (§2.1) ; le cadre, s'il existe déjà, reste dans le DOM mais `hidden` + `inert` (il garde sa session et son flux ; son contenu n'est plus lisible ni atteignable) | « Terminal » | `vf.terminal.open = 0` |
| **Ouvert** | clic sur la pastille, ou raccourci | tiroir à la hauteur mémorisée, entrée §9 ; le cadre est créé **à la première ouverture seulement** (le shell ne démarre pas avant) ; focus au terminal | « Ouverture du terminal… » (affiché sur `--surface` derrière le cadre après 400 ms de chargement, masqué de lui-même par Q à l'affichage) | `vf.terminal.open = 1`, `vf.terminal.h` |
| **Plein** | bouton « Agrandir », ou double-clic sur la poignée | haut = `calc(var(--hh, 64px) + 12px)`, gauche/droite/bas = 16 px, le panneau latéral passe dessous | « Réduire le terminal » (libellé du bouton) | non mémorisé : retour à la hauteur normale au rechargement |
| **Injoignable** | aucun signal « prêt » de Q après 8 s (F1) | carte d'état de P par-dessus le cadre (même style que §6.2) | « Le terminal ne répond pas. Relancez /vf-cockpit --terminal. » | aucune |

États portés par Q (affichés dans le cadre, §6) : session refusée, secret manquant ou périmé, shell terminé, session fermée,
reconnexion, serveur arrêté.

L'ouverture n'est jamais refusée par P : c'est Q qui sait si une session existe (une seule session par serveur, P71-D-05).

---

## 6. États portés par la page du terminal (Q)

### 6.1 Tableau

| État | Quand | Rendu | Texte (FR) | Action | Pastille de barre |
|---|---|---|---|---|---|
| **Connecté** | session vivante | terminal seul | (libellé d'état de P) « Connecté » | aucune | `--recent` |
| **Reconnexion** | flux coupé, reprise automatique (attentes 0,5 / 1 / 2 / 4 s, puis toutes les 4 s, jusqu'à 30 s) | bandeau §6.3, le terminal reste lisible | « Reconnexion… » | aucune, automatique | `--sev-medium` |
| **Session refusée** | une autre session est déjà ouverte (autre onglet, P71-D-05) | carte §6.2, **pas** de terminal | titre « Terminal déjà ouvert » ; corps « Un terminal est déjà ouvert dans un autre onglet. Fermez-le, puis réessayez. » | bouton « Réessayer » | `--sev-medium` |
| **Secret manquant ou périmé** | pas de secret de session, ou 401 (serveur relancé, F2 de P71-D-13) | carte §6.2 | titre « Session expirée » ; corps « Relancez /vf-cockpit --terminal. » (commande en `--mono`, sélectionnable) | aucune (l'onglet est rouvert par le lanceur) | `--sev-high` |
| **Shell terminé** | le shell est sorti (`exit`, Ctrl-D) | bandeau §6.3 sous la dernière sortie ; le focus passe au bouton | « Le shell s'est terminé (code 0). » ou « (code 130). » ; si tué par signal : « Le shell a été interrompu (signal 1). » | bouton « Relancer le shell » : nouvelle session dans la même page, écran réinitialisé, focus rendu au terminal | `--text-4` |
| **Session fermée** | la grâce de 30 s est dépassée pendant l'absence (rechargement tardif), ou le serveur a tué la session | bandeau §6.3 | « La session a été fermée. » | bouton « Relancer le shell » | `--text-4` |
| **Serveur arrêté** | le flux ne revient pas et le serveur Q ne répond plus | carte §6.2 par-dessus la dernière sortie atténuée (le texte reste lisible dessous, voile `--scrim`) | titre « Serveur arrêté » ; corps « Le cockpit est arrêté. Relancez /vf-cockpit --terminal. » | aucune | `--sev-high` |
| **Chargement** | avant le premier rendu | rien (fond `--surface` uniquement, jamais de spinner) | aucun | aucune | `--text-4` |

### 6.2 Carte d'état

Centrée dans le cadre, largeur `min(360px, 100% - 32px)`, fond `--raise`, rayon `--r-card`, ombre `--shadow-card`, padding 16 × 18 px,
gap 7 px (grammaire des cartes Graphite). Pictogramme `svg.i` 16 px `--text-3` au-dessus du titre ; titre 15 px / 600
`--text` (interlettrage -.015em) ; corps 12,5 px / 400 `--text-2`, interligne 1,5 ; la commande `/vf-cockpit --terminal` en
`--mono` 12 px sur fond `--raise-2`, rayon 8 px, padding 1 × 6 px. Bouton plein 32 px de haut, rayon 10 px, 13 px / 500,
`--on` / `--on-text`, survol `--on-hover`, focus `outline: 2px solid var(--ring); outline-offset: 2px`. Rôle : `role="alert"`
pour « expirée », « arrêté » ; `role="status"` pour « déjà ouvert ». Le focus va au bouton s'il y en a un, sinon à la carte
(`tabindex="-1"`).

### 6.3 Bandeau

En bas, `margin: 8px`, hauteur 44 px, fond `--raise`, rayon `--r-ctl`, filet `1px solid var(--hair-2)`, padding `0 8px 0 14px`.
Pastille d'état 8 px + texte 13 px / 500 `--text` ; le bouton est aligné à droite, 32 px de haut, mêmes règles que §6.2.
`role="status"` (annoncé poliment). Le terminal au-dessus reste défilable et sélectionnable (on peut copier la dernière sortie).

---

## 7. Clavier, focus, raccourci

### 7.1 Raccourci d'ouverture / fermeture : **Ctrl+Maj+Espace**

Détecté sur `event.code === "Space"` avec `ctrlKey && shiftKey && !altKey && !metaKey` (touche physique, indépendante de la disposition
du clavier). Affiché « Ctrl+Maj+Espace » dans les info-bulles ; une seule constante dans le script pour le changer.

Pourquoi ce choix :
- **Ctrl+` (VS Code) écarté** : le guillemet inversé est une touche morte sur clavier AZERTY français (AltGr+7 ou Option+è), donc
  hors de portée en un geste, et Samuel est sur disposition française.
- **Aucune touche de shell n'est volée.** Les terminaux ne distinguent pas Ctrl+Maj+lettre de Ctrl+lettre, et Ctrl+Espace produit NUL ; la
  variante avec Maj n'existe pas pour un shell. Les combinaisons Ctrl+C, D, Z, R, A, E, W, U, K, L, Y et Échap (vim, readline) restent
  intégralement pour le shell. **Échap n'est jamais intercepté.**
- **Pas de Cmd :** les raccourcis Cmd sont ceux du navigateur et de macOS ; on reste sur Ctrl sur toutes les plateformes pour
  qu'une seule règle s'applique.
- À vérifier en recette sur Chrome, Safari et Firefox sous macOS que le navigateur ne capte pas la combinaison avant la page (F5).

Comportement (bascule à trois temps) :
1. Tiroir fermé : ouvre, et donne le focus au terminal.
2. Tiroir ouvert, focus ailleurs dans P : donne le focus au terminal (n'a pas fermé).
3. Tiroir ouvert, focus dans le terminal : ferme, et rend le focus (§7.3).

Le temps 3 se produit dans le cadre (Q), où l'écouteur de P ne voit pas les touches : Q reconnaît la même combinaison, l'empêche
d'atteindre le shell (`preventDefault`, aucun octet envoyé), et envoie à P un message d'une seule valeur fixe (`toggle`).
C'est le canal Q vers P du finding F1.

### 7.2 Entrer dans le terminal et en sortir sans piège

- Atteindre le terminal : Tab depuis le bouton « Fermer » arrive sur le cadre ; ou le raccourci ; ou un clic. Dans Q, le focus
  va à la zone de saisie de xterm au chargement de la fenêtre et à chaque `focus` de la fenêtre.
- xterm capture Tab (c'est de la saisie shell). **Sortie clavier : Ctrl+Maj+Espace** (ferme le tiroir, focus rendu), tracé ainsi
  dans l'info-bulle de la barre. Sans ce canal, un utilisateur clavier seul serait piégé : c'est la raison de F1.
- Ordre de tabulation dans P : poignée de redimensionnement, Agrandir, Fermer, cadre. Fermé : pastille seule.

### 7.3 Focus et retour du focus

- À l'ouverture, P mémorise `document.activeElement` (l'« ouvreur »), puis donne le focus au cadre ; Q donne le focus au terminal.
- À la fermeture (bouton, raccourci, ou message `toggle`) : le focus revient à l'ouvreur s'il est encore dans le DOM, visible et
  activable ; sinon à la pastille. Jamais au `body`.
- Fermé, le tiroir est `inert` : ni tabulation, ni lecteur d'écran, ni clic dans le terminal masqué.
- Focus visible : tous les contrôles (pastille, boutons de barre, poignée, boutons de Q) portent l'anneau `--ring` de 2 px. Le cadre
  lui-même : `outline: 2px solid var(--ring); outline-offset: -2px` en `:focus-visible` seulement (arrivée clavier) ; à la souris, le
  curseur plein (focus) ou en contour (sans focus) suffit.
- Annonces (`role="status"`, région visuellement cachée de P) : « Terminal ouvert », « Terminal fermé », puis les libellés d'état de §6.

---

## 8. Redimensionnement et mémorisation

- **Souris :** glisser la poignée change la hauteur, au pas du pointeur, sans animation. Bornes 160 px (minimum) et le plein. Pendant le
  glissement : `body.resizing` (déjà utilisé par le cockpit), `user-select: none`, `pointer-events: none` sur le cadre.
- **Clavier :** la poignée est un séparateur focalisable (`role="separator"`, `aria-orientation="horizontal"`, `aria-valuenow`,
  `aria-valuemin="160"`, `aria-valuemax` = plein, `aria-label="Hauteur du terminal"`). Flèche haut / bas : ±24 px ; avec Maj ±96 px ;
  Début / Fin : minimum / plein. Double-clic ou Entrée sur la poignée : retour à 320 px.
- **Mémorisation :** la hauteur (px) est écrite dans le `localStorage` de P, clé `vf.terminal.h`, ainsi que `vf.terminal.open`
  (0 ou 1). Ce sont des préférences d'affichage, jamais un secret (le secret de session reste dans le stockage de Q, P71-D-13).
  Au chargement, la hauteur est bornée à la fenêtre actuelle (un écran plus petit ne produit pas un tiroir plus haut que la page).
- **Ajustement du terminal :** Q recalcule colonnes et lignes (`fit`) sur `ResizeObserver` du cadre, regroupé par image
  d'animation, et envoie le redimensionnement au PTY au plus toutes les 100 ms (SIGWINCH). Rien à envoyer quand la taille ne change
  pas. Au retour de l'état fermé, un ajustement est refait.
- **Page hôte :** quand le tiroir est ouvert hors plein, P pose `--vf-term-h`, et le script ajoute (dans sa feuille) : le contenu
  défilant de la page Projet reçoit `padding-bottom: var(--vf-term-h)` pour que son dernier bloc reste atteignable ; la barre
  de question (`#ask`, si présente) monte de cette hauteur (`bottom: calc(var(--vf-term-h) + 28px)`). Sur la page Code, le plan
  garde son cadrage : le tiroir le recouvre sans le recadrer.

---

## 9. Mouvement

| Élément | Normal | `prefers-reduced-motion: reduce` |
|---|---|---|
| Ouverture / fermeture du tiroir | fondu + glissement de 16 px vers le haut, 250 ms, `--ease` | aucun : apparition et disparition instantanées |
| Grip de la poignée | opacité 0 → 1, 200 ms | instantané |
| Survol des boutons | 150 ms | instantané |
| Redimensionnement, plein | aucune animation (suit le pointeur / bascule instantanée) | idem |
| Curseur du terminal | fixe (pas de clignotement) | fixe |
| Changement de thème | **jamais animé** (`html.theme-switching`) | idem |
| Apparition des cartes et bandeaux de Q | aucune | aucune |

Aucune animation obligatoire pour comprendre l'état. Durées < 700 ms. La feuille de Q porte aussi sa propre règle
`prefers-reduced-motion` (elle ne peut pas hériter de celle de P).

---

## 10. Accessibilité (synthèse vérifiable)

- Contraste texte ≥ 4,5:1 : palette §4.2 calculée ; texte de chrome : `--text-3` sur `--raise` = 4,61:1 (sombre), 5,86:1 (clair) ;
  `--text-2` sur `--raise` = 7,58:1 et 8,82:1 ; `--err-text` sur `--surface` = 9,08:1 et 6,55:1 ; `--warn-text` = 12,56:1 et 8,48:1.
- Cibles ≥ 24 px : pastille 32, boutons de barre 28, boutons de Q 32, poignée 24.
- Focus visible partout (`--ring`, 2 px) ; ordre logique ; pas de piège clavier (§7.2).
- Libellés : tout contrôle porte un `aria-label` en français ; le cadre a un `title` ; la région « Terminal » est un repère.
- Couleur jamais seule : chaque pastille d'état est doublée d'un libellé.
- Mouvement : §9. Thème clair complet : palette §4.2 et variables §3.3.
- Limite connue : la sortie du terminal n'est pas exposée au lecteur d'écran (F6).

---

## 11. Responsive

- ≥ 1000 px : disposition de §2.2.
- ≤ 999 px, ou pointeur grossier : le tiroir s'étend de 8 px à 8 px (`left/right/bottom: 8px`), rayon inchangé.
- ≤ 700 px : l'ouverture se fait directement en mode plein ; la pastille monte à `bottom: 72px` pour ne pas recouvrir la barre de
  question qui occupe le bas de l'écran ; le raccourci clavier reste actif. (Le serveur n'écoute qu'en `127.0.0.1` : cas d'une fenêtre
  étroite sur le même poste, pas d'un téléphone.)
- Largeur utile < 480 px (panneau latéral ouvert sur une petite fenêtre) : le tiroir ignore `--pw` et passe en plein.

---

## 12. Catalogue des textes (français, espaces insécables avant `: ; ! ?`, aucun tiret long)

| Clé | Texte |
|---|---|
| Pastille | Terminal |
| Pastille, info-bulle | Ouvrir le terminal (Ctrl+Maj+Espace) |
| Pastille, session en cours | Ouvrir le terminal, une session est en cours |
| Windows | Terminal indisponible sous Windows. |
| Titre de barre | Terminal |
| Boutons | Agrandir le terminal ; Réduire le terminal ; Fermer le terminal (Ctrl+Maj+Espace) |
| Poignée | Hauteur du terminal |
| États de barre | Connecté ; Reconnexion… ; Terminé ; Arrêté |
| Chargement | Ouverture du terminal… |
| Injoignable (P) | Le terminal ne répond pas. Relancez /vf-cockpit --terminal. |
| Refusé, titre / corps / bouton | Terminal déjà ouvert / Un terminal est déjà ouvert dans un autre onglet. Fermez-le, puis réessayez. / Réessayer |
| Expiré, titre / corps | Session expirée / Relancez /vf-cockpit --terminal. |
| Shell terminé | Le shell s'est terminé (code 0). ; Le shell a été interrompu (signal 1). |
| Session fermée | La session a été fermée. |
| Relance | Relancer le shell |
| Serveur arrêté, titre / corps | Serveur arrêté / Le cockpit est arrêté. Relancez /vf-cockpit --terminal. |
| Annonces | Terminal ouvert ; Terminal fermé |

---

## 13. Canal Q vers P (vocabulaire, pas d'implémentation)

Si F1 est accepté, Q envoie à P uniquement des messages à valeur fixe : `ready`, `etat:connecte`, `etat:reconnexion`, `etat:termine`,
`etat:refuse`, `etat:expire`, `etat:arrete`, `toggle`. P ne les accepte que si `event.origin` est exactement l'origine de Q **et** `event.source`
est la fenêtre de son propre cadre, et n'en tire que l'affichage de la barre, le point de la pastille, la fermeture et le retour du focus ;
jamais de donnée, jamais de commande. Q continue d'ignorer tout message entrant (P71-D-15 inchangé). Q connaît l'origine de P par
la configuration de sa page (non sensible), pas par un message.

---

## 14. Constats et décisions à rendre

| id | Constat | Action |
|---|---|---|
| F1 | **Majeur.** Le raccourci de sortie, l'état de la barre et la détection « injoignable » exigent un canal Q vers P (messages à valeur fixe, §13). P71-D-15 dit « Q ignore `postMessage` » (entrant) ; le texte n'interdit pas le sortant, mais la frontière P/Q est un sujet de sécurité : l'audit doit trancher. Sans ce canal : un utilisateur clavier est piégé dans le terminal (aucune sortie hors Tab capturé par le shell), la pastille et la barre perdent l'état, la panne de Q n'est pas détectée (page d'erreur du navigateur dans le cadre). | **ask-user** (manager / audit, ADR-031) |
| F2 | **Mineur.** Le thème passe par l'adresse du cadre : une bascule recharge le cadre et ne rejoue que 256 Ko d'historique. Alternative : un message de thème entrant à deux valeurs, contraire à P71-D-15 tel qu'écrit. | **ask-user** (mineur ; sinon accepté tel que spécifié) |
| F3 | **Mineur.** La police JetBrains Mono est embarquée dans la page P (`/*__FONTS__*/`) ; Q est une autre origine et ne la reçoit pas. Spécifié : embarquer la même police dans la page de Q (`font-src` de la CSP de Q à ouvrir sur `data:` ou `'self'`), faute de quoi la pile retombe sur `ui-monospace` (valable, mais l'aspect change). `lineHeight: 1` et le tracé de `claude` sont à valider en recette. | **auto-fix** (décision de plan) |
| F4 | **Mineur.** Tiroir fermé puis rechargement de P après plus de 30 s : la session est tuée par la grâce, car le cadre n'existe plus pour la tenir. Fermer sans recharger ne coûte rien (le cadre reste vivant, masqué). | **no-op** (comportement cohérent avec P71-D-05, à écrire dans le README) |
| F5 | **Mineur.** Ctrl+Maj+Espace n'est pas garanti libre sur tous les navigateurs et systèmes ; une constante unique permet de le changer. | **no-op** (vérifier en recette) |
| F6 | **Mineur.** Lacunes d'accessibilité connues d'un terminal DOM : pas de mode lecteur d'écran (coût de rendu), texte atténué sous 4,5:1 par nature. Tracées, non traitées en 71. | **no-op** |
| F7 | **Mineur.** Les 25 variables recopiées côté Q (§3.3) peuvent dériver de `viewer.html`. Ajouter à une suite existante un contrôle de parité des valeurs sombre et clair (un contrôle qui doit pouvoir rougir : tester sur un mutant). | **auto-fix** (décision de plan) |
| F8 | **Mineur.** `DESIGN.md` (PR #196) n'est pas mergé ; la spec s'appuie sur `viewer.html`, qui fait foi. À relire contre DESIGN.md quand il sera sur `main`. | **no-op** |

---

## 15. Critères de vérification de l'écran (pour la recette et le juge)

1. Cockpit lancé sans `--terminal` : aucune pastille, aucun nœud `vf-term-*`, aucune clé `vf.terminal.*`, aucun écouteur de clavier.
2. Deux thèmes : sombre et clair, tiroir ouvert, avec `ls --color`, un éditeur plein écran et `claude` ; aucune couleur illisible ;
   les 16 couleurs ANSI affichées ; bascule de thème instantanée, sans flash.
3. Tracé de `claude` (boîtes, traits) continu, sans coupure verticale (`lineHeight: 1`).
4. Ouvrir, fermer, ouvrir : le shell et son historique sont toujours là ; redimensionner à la souris et au clavier ; recharger : même
   hauteur, même session (dans les 30 s).
5. Ctrl+C, Ctrl+R, Ctrl+W, Échap, Tab, flèches : tous atteignent le shell. Ctrl+Maj+Espace ferme depuis le terminal et rend le focus à l'ouvreur.
6. `{ [ ] | \ ~ @` tapés avec Option sur clavier français macOS arrivent au shell.
7. Chaque état de §5 et §6 est provoqué (deuxième onglet, secret supprimé du stockage, `exit`, arrêt du serveur, Windows simulé) et son
   texte correspond au §12.
8. Tabulation complète sans piège ; anneau de focus visible sur chaque contrôle ; `prefers-reduced-motion` coupe l'entrée du tiroir.
9. Contraste : recalculer les couples du §4.2 avec la formule WCAG et le CSS réel de `viewer.html` (le CSS fait foi si un écart apparaît).
