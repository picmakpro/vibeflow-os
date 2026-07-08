# DA-INIT — Initialiser la Direction Artistique (générique multi-stack)

> Référence chargée on-demand par `vibeflow-design` quand l'intention est « définir l'identité
> visuelle / from scratch / on part sur quel style » **ou** quand aucun `DESIGN.md` n'existe et
> qu'une refonte structurante est demandée.
>
> Produit une **bible visuelle** (`DESIGN.md`), une **section design** dans `CLAUDE.md`, et le
> **système de design incarné selon la stack** (variables CSS + config pour le web ; tokens
> Swift / theme object / `ThemeData` pour le mobile ; tokens neutres sinon).

---

## Étape 0 — Chaîne d'outils

Vérifier la présence des outils design internes et **dégrader gracieusement** si absents
(cf. `design-toolchain.md`). Ne jamais bloquer : à défaut, mener la DA sur les premiers principes
(exploration structurée + référentiel UX + jugement) et le signaler.

---

## Workflow

```
Démarrage
  → Exploration (comprendre le produit)
  → Proposer le Visual Companion (mockups comparatifs) si dispo
  → Explorer 3 directions esthétiques
  → Référentiel UX (palettes, typo, guidelines)
  → Direction créative (distinctive, anti-slop — web)
  → Présenter la DA → validation utilisateur
  → Générer DESIGN.md + section CLAUDE.md + système de design (selon stack)
  → Done
```

---

## Phase 1 — Comprendre le projet

Poser les questions **une par une** (multiple choice quand possible) :

### Essentielles
1. **Type de produit** : SaaS dashboard, landing, e-commerce, app mobile, portfolio, blog, outil interne, autre ?
2. **Audience cible** : devs, marketeurs, designers, C-level, grand public, B2B, B2C ?
3. **Émotions à transmettre** : confiance, modernité, luxe, fun, minimalisme, puissance, chaleur, sérieux ?
4. **Références visuelles** : sites/apps aimés ? screenshots ? (proposer le Visual Companion)
5. **Thème** : dark-first, light-first, ou les deux ? Préférence de fond ?
6. **Couleur brand** : couleur principale, logo, charte existante ?
7. **Stack technique** : détecter d'abord (fichiers projet), confirmer — pilote l'incarnation du système de design.
8. **Contraintes** : budget typo (fonts système ? Google Fonts ?), deps limitées, a11y renforcée ?

### Secondaires (selon contexte)
9. **Layout** : bento grid, sidebar + content, top nav + sections, colonnes dashboard, écrans mobiles ?
10. **Effets visuels** : glassmorphism, neumorphism, flat, gradients, glow, minimal ?
11. **Animations** : riches, subtiles, minimales, aucune ?
12. **Densité** : aéré (whitespace) ou dense (beaucoup d'infos) ?

---

## Phase 2 — Explorer 3 directions

Proposer **3 directions esthétiques** (jamais une seule), chacune avec :
- **Nom évocateur** (ex : « Cockpit Nocturne », « Crystal Light », « Brutalist Warm »)
- **Moodboard textuel** : atmosphère + 3-4 références
- **Palette** : 5 couleurs (background, surface/card, primary, accent, muted) + hex
- **Typo** : pairing display + body
- **Layout** : grille, espacement
- **Effets** : glassmorphism, glow, shadows, animations
- **Mockup** : si le Visual Companion est actif, générer un mockup par direction (web) ou une
  maquette d'écran (mobile)

Valider les palettes/pairings via le **référentiel UX**, s'assurer qu'elles sont **distinctives**
via la **direction créative**. **Recommander** une direction avec justification.

---

## Phase 3 — Affiner la DA choisie

1. **Palette complète** : couleurs système (background, foreground, surface, primary, secondary,
   muted, destructive, border, input, ring) + sémantiques (success, warning, info) + features.
2. **Typographie complète** : échelle (h1→micro), weights, line-heights.
3. **Spacing** : grille, gaps, radius par composant.
4. **Composants clés** : inputs, cartes, boutons, navigation.
5. **Effets visuels** : opacité, blur, shadows précis.
6. **Animations** : keyframes, durées, easing.
7. **Responsive / multi-écrans** : breakpoints ou tailles cibles + comportements.
8. **Règles strictes** : les « jamais » et « toujours » du projet.

Présenter section par section, **valider chaque section** avant de figer.

---

## Phase 4 — Générer les fichiers (adaptés à la stack)

### 4.1 — `DESIGN.md` (racine projet)
Bible visuelle complète (identité → palette → typo → spacing → composants → animations → icônes →
fichiers ref → règles). Partir du template `templates/DESIGN.md` et remplacer les placeholders.

### 4.2 — Section design du `CLAUDE.md`
Règles non négociables (tokens, anti-slop, a11y, thème, états de chargement), fichiers clés,
renvoi vers `/vf-design`. Partir de `templates/CLAUDE-design-section.md`.

### 4.3 — Système de design **incarné selon la stack**

| Stack | Fichiers générés |
|---|---|
| Web + Tailwind/shadcn | `globals.css` (variables HSL, keyframes, utilitaires) + `tailwind.config` (couleurs mappées) |
| Web (Vue/Svelte/vanilla) | feuille de variables CSS + guide d'usage (pas de config Tailwind) |
| SwiftUI / iOS | extension `Color`/`Font`, entrées asset catalog, fichier de tokens Swift |
| React Native / Flutter | theme object / `ThemeData` + fichier de tokens partagés |
| Autre / desktop | tokens neutres (JSON/variables) + guide d'application |

> **Ne jamais générer une config Tailwind sur un projet SwiftUI/Flutter.** Détecter, puis incarner.

---

## Règles absolues

1. **Une question à la fois** — ne pas submerger.
2. **Multiple choice préféré**.
3. **Proposer 3 directions** — jamais une seule.
4. **Recommander** — toujours donner un avis justifié.
5. **Valider chaque section** avant de générer.
6. **Anti-AI-slop** — pas de palette générique (bleu/violet sur blanc), pas de police par défaut.
7. **Visual Companion** — le proposer tôt, l'utiliser pour comparer.
8. **Ne toucher qu'aux fichiers design** (DESIGN.md, CLAUDE.md, tokens/CSS/theme) — jamais la logique métier.
9. **Détecter la stack** avant de choisir l'incarnation du système de design.

---

## Sortie attendue

À la fin : le projet a une DA figée (`DESIGN.md`), une section design dans `CLAUDE.md`, et un
système de design incarné dans sa stack. Message de fin (reframé VibeFlow) :

> Direction artistique initialisée. Dis « améliore le design » ou « refais cet écran » pour toute
> évolution visuelle — les agents respecteront automatiquement la DA (`DESIGN.md` + `CLAUDE.md`).
