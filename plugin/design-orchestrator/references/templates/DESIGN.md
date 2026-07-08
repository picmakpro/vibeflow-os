# {{PROJECT_NAME}} — Design System & Direction Artistique

> **Source de vérité** pour toute décision visuelle. Tout agent qui modifie l'UI respecte ce fichier.
> Généré par `/vf-design` (workflow DA-INIT) — personnalisé pour ce projet et sa stack.
>
> **Stack détectée** : {{STACK}} — le système de design est incarné en conséquence (variables CSS
> pour le web ; tokens Swift / theme object pour le mobile ; tokens neutres sinon).

---

## 1. Identité visuelle

- **Positionnement** : {{PROJECT_NAME}} est un **{{PRODUCT_TYPE}}**. L'interface doit inspirer **{{DESIGN_FEELINGS}}**.
- **Philosophie** : {{THEME_MODE}}-first · {{LAYOUT_STYLE}} · micro-interactions à feedback · zéro bruit visuel.
- **Inspirations** : {{INSPIRATION_1}} · {{INSPIRATION_2}} · {{INSPIRATION_3}}

---

## 2. Palette de couleurs

> Incarnation selon la stack : variables CSS HSL (web) · `Color` extension / asset catalog (SwiftUI) ·
> theme object / `ThemeData` (RN/Flutter). Les **noms de rôles** ci-dessous sont stables ; seule la syntaxe change.

| Rôle | Valeur | Usage |
|---|---|---|
| background | {{HEX_BG}} | fond principal |
| foreground | {{HEX_FG}} | texte principal |
| surface / card | {{HEX_CARD}} | conteneurs, cartes |
| primary | {{HEX_PRIMARY}} | brand, CTAs, accents |
| secondary | {{HEX_SECONDARY}} | actions secondaires |
| muted | {{HEX_MUTED}} | fonds discrets |
| muted-foreground | {{HEX_MUTED_FG}} | texte secondaire, timestamps |
| success | {{HEX_SUCCESS}} | validations |
| warning | {{HEX_WARNING}} | alertes |
| destructive | {{HEX_DESTRUCTIVE}} | erreurs, suppressions |
| border / input | {{HEX_BORDER}} | bordures, champs |
| ring | {{HEX_RING}} | focus visible |

Rayon de base : `{{BORDER_RADIUS}}`.

---

## 3. Typographie

- **Display/Titres** : {{FONT_DISPLAY}} ({{FONT_DISPLAY_SOURCE}})
- **Body** : {{FONT_BODY}} ({{FONT_BODY_SOURCE}})
- **Mono** : {{FONT_MONO}}

| Usage | Taille | Weight |
|---|---|---|
| Titre page | {{SIZE_H1}} | bold |
| Sous-titre | {{SIZE_H2}} | semibold |
| Stats/nombres | {{SIZE_STAT}} | bold |
| Body | {{SIZE_BODY}} | normal |
| Labels/badges | {{SIZE_LABEL}} | medium |
| Micro | {{SIZE_MICRO}} | normal |

---

## 4. Spacing & Layout

- **Layout type** : {{LAYOUT_TYPE}} · **grille/écrans** : {{GRID_CLASSES}}
- **Gaps** : {{GAP_SIZE}} (blocs), {{GAP_INNER}} (sections internes)
- **Radius** : cartes `{{RADIUS_CARD}}` · boutons `{{RADIUS_BUTTON}}` · sub `{{RADIUS_SUB}}`
- **Responsive / tailles cibles** : mobile {{RESPONSIVE_MOBILE}} · tablette {{RESPONSIVE_MD}} · desktop {{RESPONSIVE_LG}}

---

## 5. Composants

- **Champs de saisie** : variant `{{INPUT_VARIANT}}`, fond `{{INPUT_BG}}`, bordure `{{INPUT_BORDER}}`, focus `{{INPUT_FOCUS}}`.
- **Cartes/surfaces** : fond `surface`, bordure `border`, radius `{{RADIUS_CARD}}`.
- **Boutons** : primary / secondary / destructive / ghost — mappés aux rôles couleur.
- **Effets visuels** (optionnel) : {{VISUAL_EFFECTS_SECTION}}

---

## 6. Animations

- **Transitions standard** : hover/layout {{TRANSITION_STD}} (200-300ms max sur interactions directes).
- **Keyframes custom** : {{KEYFRAMES_SECTION}}
- **Loading** : skeleton fidèle au layout final — jamais de spinner générique ni « Loading… ».
- **Reduced motion** : respecter la préférence système.

---

## 7. Icônes

- **Librairie** : {{ICON_LIBRARY}} · tailles : {{ICON_SIZE_DEFAULT}} (standard) · {{ICON_SIZE_SMALL}} (inline) · {{ICON_SIZE_LARGE}} (hero).

---

## 8. Fichiers de référence (selon stack)

| Fichier | Rôle |
|---|---|
| {{TOKENS_FILE}} | système de design incarné (variables CSS / tokens Swift / theme object) |
| {{THEME_CONFIG}} | config thème (tailwind.config / ThemeData / asset catalog) |
| {{COMPONENTS_PATH}} | composants / primitives UI |

---

## 9. Règles strictes

1. **Pas de valeurs en dur** — passer par le système de design (rôles ci-dessus).
2. **Anti-AI-slop** : pas de police générique par défaut, pas de gradient cliché, chaque écran a un point de vue.
3. **Accessibilité** : contraste ≥ 4.5:1, focus visibles, cibles tactiles ≥ 44px, labels d'accessibilité.
4. **Loading fidèle** : skeleton reproduisant le layout final.
5. **{{CUSTOM_RULE_1}}**
6. **{{CUSTOM_RULE_2}}**
