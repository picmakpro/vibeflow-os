# DESIGN-SPEC — vf-cockpit

Spécification design complète et implémentable du module `vf-cockpit`. Périmètre : la page
unique servie par le serveur zéro-dépendance (`node:http` + SSE + `fs.watch`), visualisation en
lecture seule du `.planning/` du lab courant. Aucun framework, aucun build, aucun CDN — CSS écrit
à la main en custom properties, Mermaid v11.16.1 vendorisé en bundle UMD auto-suffisant
(`references/vendor/mermaid.min.js`, 3,40 Mo) — chargé par `<script src>` classique puis consommé
via le global `window.mermaid`, JAMAIS par `import` ESM : le build ESM de Mermaid v11 importe des
chunks relatifs et casserait le hors-ligne (constaté empiriquement au nœud de vendorisation).

Contrat de données de référence (spike 001, validé) : `GET /api/state` → `{generatedAt, state,
phases[], milestones[], dags[], lock}` ; `GET /api/phase?num=N` → `{num, name, goal, body, dir,
plans[]}` ; `GET /api/log` → `{count, events[]}` ; `GET /events` → SSE `{reason, at}`. Cette spec
n'affiche rien que ce contrat ne fournit pas.

Il n'existe pas de `DESIGN.md` lab-wide : la DA ci-dessous est scopée au module `vf-cockpit`
(décision actée au MANIFEST du spike : « DA sombre simple type cockpit »).

---

## 0. Parti pris

### La question des 3 secondes

L'utilisateur ouvre `/vf-cockpit` pour une seule question : **« où en est ma mission, là,
maintenant ? »**. En 3 secondes, sans scroll ni clic, il doit lire trois faits, dans cet ordre de
priorité visuelle :

1. **Le milestone et la phase courante** — quel chantier, quel numéro, quel pourcentage.
2. **Qui travaille en ce moment** — un agent est-il actif (lock vivant), ou le lab est-il au repos.
3. **Ce que fait la phase courante concrètement** — ses plans, combien sont clos.

Tout le reste est du bruit à cet instant : les 35 phases de la roadmap, les 8 milestones clos,
le détail d'un nœud du DAG, le journal forensique. Ces informations restent accessibles — au clic,
jamais imposées au premier écran. La vue par défaut n'affiche donc **jamais** la liste complète
des phases ; elle affiche la position courante avec un contexte étroit (±2), et un point d'entrée
explicite vers le reste (`voir les 35 phases`, replié par défaut).

### Nommage des niveaux

« Roadmap / Phase courante / Agents en cours » est un triplet de labels d'implémentation, pas une
hiérarchie lisible : « Roadmap » est un anglicisme de gestion de projet, « Agents en cours »
présuppose que le lecteur sait ce qu'est un DAG de mission. Renommage retenu, pensé comme un
**zoom continu du macro au micro** (chaque niveau est littéralement contenu dans le précédent) :

| # | Nom retenu | Ce qu'il montre | Pourquoi ce mot |
|---|---|---|---|
| ① | **Trajectoire** | L'arc du milestone courant : les phases, dans l'ordre, avec leur état | Évoque un chemin parcouru + à parcourir, pas une liste de tickets |
| ② | **Chantier actuel** | La phase en cours et ses plans (● terminé / ○ à venir) | « Chantier » est concret, borné dans le temps, contient plusieurs plans comme un chantier contient plusieurs lots |
| ③ | **Équipe en mission** | Le DAG de la mission active, un nœud = un mandat d'agent | « Équipe » nomme des acteurs, pas une abstraction technique ; se lit sans savoir ce qu'est un DAG |

Chaque niveau est un zoom du précédent : la Trajectoire contient le Chantier actuel (une des
phases) ; le Chantier actuel, quand une mission tourne dessus, est éclaté par l'Équipe en mission.
Le layout matérialise cette relation (§1) au lieu de juxtaposer trois panneaux au même rang.

### Modèle d'interaction

**Drawer latéral droit, tranché** — contre modale (interromprait le contexte : on perd de vue le
niveau qui a déclenché le clic, alors que la valeur du clic est justement de comparer la fiche au
contexte) et contre navigation plein écran (rupture trop lourde pour une lecture d'appoint,
lecture seule sans formulaire à protéger). Le drawer garde le niveau cliqué visible en arrière-plan
et referme sans perte de position de scroll.

- **Retour arrière** : ouverture du drawer = `history.pushState(null, '', '#/phase/30')` (ou
  `#/node/<id>`). Le bouton retour du navigateur ferme le drawer (`popstate` → si le hash devient
  vide, on ferme). Fermeture par `✕`, `Échap`, ou clic sur l'overlay ⇒ `history.back()` si un état
  a été poussé, sinon retrait direct du hash.
- **État d'URL / deep-link** : `#/phase/<num>` et `#/node/<id>` sont résolus au chargement — un
  lien partagé rouvre directement la bonne fiche après le premier `refresh()`. Format choisi (hash,
  pas de vraie route) parce qu'il n'y a aucun serveur de routage à consulter : le hash ne déclenche
  aucune requête, cohérent avec un serveur zéro-dépendance qui ne sert qu'un seul document.
- **Focus clavier** : à l'ouverture, focus déplacé sur le bouton `✕` du drawer (`role="dialog"
  aria-modal="true" aria-labelledby="drawer-title"`). Le contenu de fond n'est pas rendu `inert`
  (il reste lisible), mais le `Tab` est piégé dans le drawer tant qu'il est ouvert (premier/dernier
  élément focalisable rebouclent). À la fermeture, le focus revient à l'élément déclencheur (la
  carte ou le nœud cliqué), jamais au `body`.

### Densité d'information

35 phases et un DAG pouvant compter jusqu'à une quinzaine de nœuds ne se donnent pas d'un bloc.

- **Niveau ① (Trajectoire)** : jamais les 35 phases à plat. Seules deux familles sont visibles par
  défaut — celles du milestone courant, en ordre, et un compteur replié pour le reste :
  - *Chantier* : phases ≥ phase courante appartenant au milestone actif (celles qui restent à
    faire + la courante), affichées en chaîne horizontale de chips compactes.
  - *Héritées* : phases < phase courante non closes (reportées d'un milestone précédent, cas réel
    du lab : Phase 18 et 25) — un second groupe visuellement distinct, jamais mélangé à la chaîne
    principale (elles n'ont pas de relation de dépendance ordonnée entre elles).
  - *Clos* : repliés sous un `<details>` natif fermé par défaut, `◈ Terminées (N)` — jamais rendus
    tant que l'utilisateur n'a pas cliqué.
- **Niveau ② (Chantier actuel)** : une seule phase à la fois, jamais de liste. La densité y est
  déjà bornée par construction.
- **Niveau ③ (Équipe en mission)** : le DAG rendu tel quel (rarement > 16 nœuds dans ce lab) ; au
  départ, aucune limite artificielle n'est nécessaire — mais chaque nœud porte un libellé tronqué
  à 55 caractères (cohérent avec la troncature déjà pratiquée par le spike) pour ne pas faire
  exploser la largeur du diagramme.
- **Historique (milestones clos)** : replié par défaut sous un second `<details>`, jamais affiché
  en clair au premier écran — c'est strictement de l'archive.

Pas de virtualisation : à cette échelle (35 lignes max, repliées par défaut), une liste HTML
native suffit et reste plus simple à maintenir qu'un mécanisme de fenêtrage.

### Rôle de Mermaid

Mermaid est un moteur disponible, pas une réponse par défaut. Décision par niveau :

- **① Trajectoire** : **HTML natif**, pas Mermaid. La chaîne de phases est fonctionnellement
  linéaire (une dépendance simple, num croissant) — un `flowchart LR` avec des sous-graphes pour
  représenter ça est une hiérarchie visuelle mensongère (SVG au comportement de graphe) pour une
  donnée qui est une liste. Une rangée de chips HTML avec connecteurs `→` en `::before` CSS est
  plus lisible, plus dense, se reflow nativement en `flex-wrap`, et chaque chip est un vrai
  `<button>` focalisable — le clic Mermaid du spike (regex sur `g.id`, `flowchart-<id>-<n>`) n'est
  pas accessible au clavier.
- **② Chantier actuel** : HTML natif (carte + liste de puces de plans). Aucune structure de graphe
  à représenter.
- **③ Équipe en mission** : **Mermaid, seul niveau où il est justifié**. C'est la seule vue où la
  topologie compte réellement — un DAG peut forker et fusionner (`exec-ui` dépend de trois nœuds à
  la fois dans `MISSION-COCKPIT.dag.json`), une information qu'une liste linéaire ne peut pas
  représenter sans perdre le sens des dépendances croisées. Le rendu SVG de Mermaid reste
  **illustratif** ; l'interaction réelle passe par une liste HTML accessible en doublon (§4.6) —
  jamais par un clic uniquement possible sur un `<g>` SVG.
- **Historique** : **HTML natif** (timeline verticale simple), pas `timeline` Mermaid. Une
  succession de dates est une liste, pas un diagramme — et la timeline Mermaid ne peut pas porter
  de lien cliquable ni de troncature contrôlée.

### Le pouls live

Le heartbeat du `DRIVER.lock` (âge en secondes qui s'incrémente, broadcast SSE à chaque écriture)
est un signal de vie gratuit — pas une simulation, une vraie preuve que la mission avance. Deux
règles pour le rendre perceptible sans distraire :

1. **Jamais de re-rendu global clignotant.** Un `refresh()` ne doit jamais provoquer un flash de
   toute la page. Seul ce qui a effectivement changé entre deux snapshots reçoit une micro-animation
   ciblée (§6) — le badge de verrou, l'horodatage, et le ou les nœuds du DAG dont le `status` a
   changé (bordure qui pulse une fois, 600 ms, puis se stabilise).
2. **Un seul indicateur ambiant continu** : un point (`●`) de 6px dans le badge de verrou, dont
   l'opacité respire doucement (2.4 s, `ease-in-out`, infini) tant que le lock est présent et non
   périmé. C'est le seul élément en boucle infinie de toute la page — tout le reste du motion
   budget est réservé aux transitions déclenchées par un événement réel.

---

## 1. Architecture d'information

### Hiérarchie et rapport entre niveaux

```
┌─────────────────────────────────────────────────────────────────────┐
│ EN-TÊTE : milestone · phase courante · badge verrou (pouls) · maj    │
├─────────────────────────────────────────────────────────────────────┤
│ ① TRAJECTOIRE                                                        │
│   [P28●]──[P29●]──▶(P30◉ courante)──[P31○]──[P32○]   ◈ Terminées (24)│
│   ┆ héritées : [P18○] [P25○]  (groupe distinct, pas de flèches)      │
├─────────────────────────────────────────────────────────────────────┤
│ ② CHANTIER ACTUEL — Phase 30 · Portabilité Windows II                │
│   ● 30-01  ● 30-03  ● 30-04  ● 30-05  ○ 30-02  ○ 30-06  ○ 30-07 ○30-08│
│   5/8 plans terminés — clic → fiche complète                         │
├─────────────────────────────────────────────────────────────────────┤
│ ③ ÉQUIPE EN MISSION                                                   │
│   [Mermaid SVG illustratif]     |  Liste accessible (doublon focus)  │
│                                  |  ◉ design-spec — craft — running   │
├─────────────────────────────────────────────────────────────────────┤
│ ▸ Historique — milestones clos (replié)                              │
└─────────────────────────────────────────────────────────────────────┘
```

Layout : colonne unique (`.stack`), `max-width: 76rem`, centrée, `padding-inline` fluide
(`clamp(1rem, 3vw, 2rem)`). Chaque niveau est une `<section>` avec `aria-labelledby` sur son titre
numéroté. Pas de grille multi-colonnes au niveau macro : la lecture est **verticale et
séquentielle**, du zoom le plus large au plus étroit — une grille juxtaposerait les niveaux au lieu
de les hiérarchiser. Seul le niveau ③ (Équipe en mission) est en grille interne deux colonnes
(`grid-template-columns: minmax(0,1fr) minmax(220px, 320px)`) : SVG Mermaid à gauche, liste
accessible à droite ; passe en une colonne sous 900px (§7).

Scroll : la page défile normalement (pas de zones à scroll interne piégées), sauf le corps du
drawer (`overflow-y: auto`, hauteur `100vh` moins son padding).

---

## 2. Tokens

### 2.1 Couleurs — surfaces et texte

```css
:root {
  --vf-bg:             #0b0d12; /* fond de page */
  --vf-surface-1:      #12151b; /* panneaux (sections) */
  --vf-surface-2:      #171b23; /* drawer, éléments surélevés */
  --vf-surface-3:      #1d222b; /* état hover d'une surface */

  --vf-border:         #262c37; /* bordure décorative (1.3:1 — jamais seule porteuse de sens) */
  --vf-border-strong:  #5a6479; /* bordure d'un composant interactif (3.08:1, focus/hover) */

  --vf-text-primary:   #e8ecf1; /* corps de texte, titres */
  --vf-text-secondary: #9aa4b2; /* méta, labels secondaires */
  --vf-text-tertiary:  #6b7280; /* glyphes/séparateurs décoratifs seuls (→, pouls statique) — sous
                                    le plancher AA (§3), jamais sur un libellé lisible */

  --vf-accent:         #e0a92d; /* accent cockpit — amber, phase courante, focus ring */
  --vf-accent-soft:    #2b2109; /* fond teinté pour chips d'accent */
}
```

### 2.2 Couleurs sémantiques de statut

Six statuts, texte + fond dédié (paires conçues pour ≥ 4.5:1 chacune, cf. §3) :

```css
:root {
  --vf-status-done:        #3fd67a; --vf-status-done-bg:        #10261a;
  --vf-status-running:     #e0a92d; --vf-status-running-bg:     #2b2109;
  --vf-status-ready:       #5aa9ff; --vf-status-ready-bg:       #0e1e33;
  --vf-status-blocked:     #7b8494; --vf-status-blocked-bg:     #161a21;
  --vf-status-failed:      #f0605a; --vf-status-failed-bg:      #2c1211;
  --vf-status-stale:       #d97a3d; --vf-status-stale-bg:       #2c1c10;
}
```

`--vf-status-failed` n'a pas de source dans le contrat de données actuel (ni les nœuds de DAG ni
les phases n'exposent d'état d'échec aujourd'hui) — le token est posé par anticipation, documenté
comme **non alimenté** ; ne pas câbler de composant dessus tant qu'aucun champ ne le porte (à
signaler si `exec-core` découvre un champ `status: failed` en cours de route).

### 2.3 Typographie

Pile système uniquement (hors-ligne, zéro webfont) :

```css
:root {
  --vf-font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  --vf-font-mono: ui-monospace, "SF Mono", Menlo, Consolas, "Liberation Mono", monospace;

  --vf-text-xs:   0.75rem;   /* 12px — badges, hints, meta */
  --vf-text-sm:   0.8125rem; /* 13px — chips, lignes de log, ids de plan */
  --vf-text-base: 0.875rem;  /* 14px — corps par défaut */
  --vf-text-md:   1rem;      /* 16px — titres de carte */
  --vf-text-lg:   1.25rem;   /* 20px — titres de section (①②③) */
  --vf-text-xl:   1.5rem;    /* 24px — nom du milestone en en-tête, seul élément à ce corps */

  --vf-weight-regular:  400;
  --vf-weight-medium:   500; /* chips actives (§4.2, §4.3) — poids de base de toute chip cliquable */
  --vf-weight-semibold: 600; /* titres, statut courant */

  --vf-leading-tight:   1.25; /* titres */
  --vf-leading-normal:  1.5;  /* corps */
  --vf-leading-relaxed: 1.6;  /* texte long du drawer (fiche de phase) */
}
```

`--vf-font-mono` porte les identifiants techniques uniquement (id de plan `30-01`, id de nœud DAG,
horodatages ISO du journal) — jamais le texte de lecture courante.

### 2.4 Espacement, rayons, élévation

```css
:root {
  --vf-space-1: 0.25rem; /* 4px  */
  --vf-space-2: 0.5rem;  /* 8px  */
  --vf-space-3: 0.75rem; /* 12px */
  --vf-space-4: 1rem;    /* 16px */
  --vf-space-5: 1.5rem;  /* 24px */
  --vf-space-6: 2rem;    /* 32px */
  --vf-space-7: 3rem;    /* 48px */

  --vf-radius-sm:   4px;   /* chips, badges de statut */
  --vf-radius-md:   8px;   /* cartes, panneaux */
  --vf-radius-lg:   12px;  /* drawer */
  --vf-radius-pill: 999px; /* pastilles de statut, badge verrou */

  --vf-shadow-drawer: -16px 0 32px -8px rgba(0, 0, 0, .55);
}
```

Aucune autre élévation : les panneaux se distinguent par `--vf-border` + `--vf-surface-1` sur
`--vf-bg`, jamais par une ombre portée (l'ombre décorative sur des cartes plates est un des motifs
génériques identifiés dans l'anti-esthétique — §9).

---

## 3. Contrastes et accessibilité

Ratios calculés (WCAG relative luminance), tous les seuils appliqués sont **4.5:1 texte
courant**, **3:1 gros texte (≥ 18.66px gras ou ≥ 24px)** et **3:1 éléments d'interface / limites de
composant** (SC 1.4.11).

| Paire | Ratio | Usage | Conformité |
|---|---|---|---|
| `--vf-bg` / `--vf-text-primary` | 16.38:1 | texte sur page | AAA |
| `--vf-surface-1` / `--vf-text-primary` | 15.41:1 | texte sur panneau | AAA |
| `--vf-surface-2` / `--vf-text-primary` | 14.54:1 | texte sur drawer | AAA |
| `--vf-surface-1` / `--vf-text-secondary` | 7.25:1 | méta, labels | AAA |
| `--vf-surface-1` / `--vf-text-tertiary` | 3.78:1 | glyphes/séparateurs décoratifs seuls (`→`, pouls statique) — **jamais un libellé lisible** | AA gros texte, pas AA texte courant → ne jamais l'utiliser sous `--vf-text-sm`, et jamais sur un libellé (voir note ci-dessous) |
| `--vf-surface-1` / `--vf-accent` | 8.60:1 | libellés d'accent, focus | AAA |
| `--vf-surface-1` / `--vf-status-done` | 9.67:1 | texte statut done | AAA |
| `--vf-surface-1` / `--vf-status-ready` | 7.45:1 | texte statut ready | AAA |
| `--vf-surface-1` / `--vf-status-blocked` | 4.85:1 | texte statut blocked | AA |
| `--vf-surface-1` / `--vf-status-failed` | 5.68:1 | texte statut failed | AA |
| `--vf-surface-1` / `--vf-status-stale` | 5.92:1 | texte statut stale | AA |
| `--vf-status-done-bg` / `--vf-status-done` | 8.45:1 | pastille pleine | AAA |
| `--vf-status-running-bg` / `--vf-status-running` | 7.46:1 | pastille pleine | AAA |
| `--vf-status-ready-bg` / `--vf-status-ready` | 6.83:1 | pastille pleine | AAA |
| `--vf-status-blocked-bg` / `--vf-status-blocked` | 4.63:1 | pastille pleine | AA |
| `--vf-status-failed-bg` / `--vf-status-failed` | 5.43:1 | pastille pleine | AA |
| `--vf-status-stale-bg` / `--vf-status-stale` | 5.31:1 | pastille pleine | AA |
| `--vf-border-strong` / `--vf-surface-1` | 3.08:1 | bordure de composant interactif, focus ring | AA (1.4.11) |
| `--vf-accent` / `--vf-bg` | 9.15:1 | anneau de focus sur fond de page | AAA |
| `--vf-border` / `--vf-surface-1` | 1.30:1 | bordure décorative de panneau | **non conforme — décoratif uniquement, jamais seul porteur de limite fonctionnelle** |

Conséquence directe : `--vf-border` délimite un panneau passif (lecture), `--vf-border-strong`
délimite tout ce qui est cliquable, focalisable, ou change d'état.

**Le plancher AA de ce §3 prime sur tout détail de composant du §4.** `--vf-text-tertiary` ne doit
jamais porter un libellé lisible (horodatage, source, label de champ, lien de journal, libellé
« héritées », orientation de légende) — ces éléments passent tous à `--vf-text-secondary` (7.25:1
sur `--vf-surface-1`, 6.84:1 sur `--vf-surface-2`, 7.71:1 sur `--vf-bg` — AA/AAA selon fond). Ils
restent volontairement discrets par la taille (`--vf-text-xs`) et l'absence de graisse, jamais par
une couleur sous le seuil AA — c'est ce qui a fait dériver §4.1/§4.6/§4.7 avant correction (fix
a11y, cf. CHANGELOG).

### Statut jamais porté par la couleur seule

Chaque statut porte **trois signaux redondants** — couleur, glyphe, texte :

| Statut | Glyphe | Texte (FR) |
|---|---|---|
| done | `●` (plein) | « terminé » |
| running | `◉` (plein cerclé) | « en cours » |
| ready | `○` (vide, contour marqué) | « prêt » |
| blocked | `┄` (tiret pointillé) | « en attente » |
| failed | `✕` | « échoué » |
| stale | `⚠` | « périmé » |

Ces glyphes apparaissent en préfixe de chaque libellé de statut, jamais en unique porteur (le texte
d'accompagnement — « terminé », « en cours »… — reste toujours présent, y compris dans les chips
compactes du niveau ①, en `aria-label` si la place manque visuellement).

### Focus, cibles, mouvement

- **Focus visible** : `outline: 2px solid var(--vf-accent); outline-offset: 2px` sur tout élément
  interactif (`:focus-visible` uniquement — pas de contour permanent au clic souris). Jamais
  `outline: none` sans remplacement.
- **Ordre de tabulation** : suit l'ordre du DOM = ordre visuel (en-tête → ①→②→③ → historique).
  Le drawer, une fois ouvert, insère son focus trap sans réordonner le reste du DOM (il est en
  fin de document, positionné en `fixed`).
- **Cibles tactiles** : toute chip, bouton, nœud de liste cliquable a une zone d'au moins
  `44×44px` (padding compensant si le contenu visuel est plus petit) — dépassement volontaire du
  plancher de 24px du SC 2.5.8 pour rester confortable en usage tactile/trackpad.
- **`prefers-reduced-motion: reduce`** : toutes les transitions et animations en boucle (le pouls
  du badge de verrou, le flash de l'horodatage, le highlight de nœud changé) sont désactivées ;
  les changements d'état s'appliquent instantanément (`transition: none`). Voir §6.

---

## 4. Composants

### 4.1 En-tête / barre d'état

Anatomie : `<header>` sticky (`position: sticky; top: 0; z-index: 5`), fond `--vf-surface-1` avec
`border-bottom: 1px solid var(--vf-border)`, hauteur `56px`, padding horizontal `--vf-space-5`.

Contenu, de gauche à droite :
1. Nom du module (`vf-cockpit`), `--vf-text-md`, `--vf-weight-semibold`, discret — ce n'est pas
   l'information qu'on vient chercher.
2. **Badge milestone** — traitement typographique **dominant**, pas un badge générique (§0 : c'est
   la priorité n°1 de la lecture en 3 secondes) : `milestone · fiabilite-v1.0 — phase 30
   (planning) · 0/8 phases`, `--vf-text-xl`, `--vf-weight-semibold`, `--vf-text-primary`, sans fond
   ni pilule (`.vf-badge-milestone` sort du gabarit `.vf-badge` générique).
3. **Badge verrou** (pouls, §0/§6) : `🔒 owner · step · 4s` sur fond `--vf-status-done-bg` /
   couleur `--vf-status-done` si vivant ; `--vf-status-stale-bg`/`stale` avec glyphe `⚠` si périmé
   (`age_seconds > 1800`) ; `🔓 aucune mission` sur `--vf-surface-2`/`--vf-text-secondary` si
   `lock.present === false`. Reste sur le gabarit `.vf-badge` (`--vf-text-xs`, pilule) — lui n'est
   pas l'information n°1, juste un état secondaire.
4. **Horodatage `maj HH:MM:SS`**, poussé à droite (`margin-left: auto`), `--vf-text-xs`,
   `--vf-font-mono`, `--vf-text-secondary` (le plancher a11y du §3 exclut `--vf-text-tertiary` sur
   un libellé lisible, même discret).

Dimensions : badge verrou en `--vf-text-xs`, hauteur de ligne `1.4` ; badge milestone en
`--vf-text-xl` (seul élément de l'en-tête à ce corps, cf. §2.3) — jamais tronqués (le nom du
milestone peut passer à la ligne suivante sous 640px, cf. §7).

### 4.2 Carte de phase (niveau ① — chip de Trajectoire)

Chaque phase est un `<button class="vf-phase-chip">` (pas un `<div onclick>` — sémantique native
focalisable) : `min-width: 8rem`, padding `--vf-space-2 --vf-space-3`, `--vf-radius-md`, fond
`--vf-surface-1`, bordure `1px solid var(--vf-border)`.

- État `done` : bordure `--vf-status-done`, glyphe `●` devant `Phase N`.
- État courante (`running`, phase = `current_phase`) : bordure `2px solid var(--vf-accent)`, fond
  `--vf-accent-soft`, glyphe `◉`, `--vf-weight-semibold` — seule chip visuellement dominante du
  niveau, c'est elle qui ancre le regard.
- État `ready`/à venir : bordure `--vf-border`, glyphe `○`, `--vf-text-secondary`.
- Connecteur entre chips consécutives de la même chaîne : `::after { content: "→"; color:
  var(--vf-text-tertiary) }` (glyphe décoratif, pas un libellé — le plancher a11y du §3 ne
  s'applique pas), jamais entre le groupe *chantier* et le groupe *héritées* (rupture visuelle :
  `gap: --vf-space-5` + libellé `« héritées »` en `--vf-text-xs --vf-text-secondary` au-dessus du
  groupe).

### 4.3 Carte du chantier actuel (niveau ②)

`<section class="vf-current-phase">`, fond `--vf-surface-1`, padding `--vf-space-5`, bordure
`1px solid var(--vf-border)`, `--vf-radius-md`.

- Titre : `◉ Phase {num} — {name}`, `--vf-text-lg`, `--vf-weight-semibold`, couleur
  `--vf-status-running`.
- Ligne de progression plans : `{doneN}/{total} plans terminés`, `--vf-text-sm`,
  `--vf-text-secondary`.
- Rangée de puces plan (`<ul>` de `<li><button></button></li>`) : chaque puce `30-01` en
  `--vf-font-mono --vf-text-sm`, glyphe `●`/`○` + couleur `--vf-status-done`/`--vf-text-secondary`.
- But (`goal`) : `--vf-text-sm`, `--vf-text-secondary`, `max-width: 62ch`, 3 lignes max
  (`-webkit-line-clamp: 3`) avec `…` — le texte complet vit dans la fiche (drawer).
- Toute la carte est cliquable (`role="button"` sur le conteneur en plus des puces individuelles)
  → ouvre la fiche complète de la phase courante.

### 4.4 Nœud de DAG (niveau ③, dans le SVG Mermaid)

Défini par les `classDef` Mermaid (§8), un nœud = un rectangle arrondi (`rx:6`), libellé tronqué à
55 caractères, couleurs exactement les tokens de statut (§2.2). Le SVG est **illustratif** —
`aria-hidden="true"` sur le conteneur Mermaid — l'interaction réelle vit dans la liste jumelle
(§4.6). Survol/focus d'une entrée de la liste met en évidence (`outline` amber temporaire) le
rectangle correspondant dans le SVG, par `id` partagé (`data-node-id`).

### 4.5 Légende

`<div class="vf-legend">` en tête de la Trajectoire (une seule fois, pas répétée par section) :
fond `--vf-surface-1`, bordure **pointillée** `1px dashed var(--vf-border)` (signale visuellement
« ceci est un mode d'emploi, pas une donnée »), `--vf-text-xs`, `--vf-text-secondary`. Contenu :
les six glyphes + libellé (§3), plus la phrase d'orientation de la hiérarchie : « ① Trajectoire →
② Chantier actuel → ③ Équipe en mission — clic sur une case pour sa fiche ».

### 4.6 Fiche détaillée (drawer)

`<aside id="drawer" role="dialog" aria-modal="true" aria-labelledby="drawer-title">`, position
`fixed; top:0; right:0; bottom:0`, largeur `min(560px, 92vw)`, fond `--vf-surface-2`, bordure
gauche `1px solid var(--vf-border-strong)`, `box-shadow: var(--vf-shadow-drawer)`, padding
`--vf-space-6 --vf-space-5`.

Anatomie :
- Bouton fermeture (`✕`), coin haut-droit, cible 44×44px, premier élément focalisable.
- Titre `<h3 id="drawer-title">` : `Phase {num} — {name}` ou `{node.id}`.
- Ligne de provenance (`--vf-text-xs --vf-text-secondary` — plancher a11y du §3, discrétion portée
  par la taille pas par la couleur) : `source : ROADMAP.md + .planning/phases/{dir}/` (fiche de
  phase) ou `source : .planning/{file}` (fiche de nœud) — tracer systématiquement d'où vient la
  donnée, cohérent avec la nature lecture-seule de l'outil.
- Pour une phase : rangée de puces plans (identique à §4.3 mais complète, jamais tronquée) puis le
  corps Markdown-léger de la section ROADMAP (gras/`code` uniquement, pas de rendu Markdown complet
  — cohérent avec le parseur `md()` du spike).
- Pour un nœud DAG : `Mandat`, `Étage`, `Statut` (glyphe + texte), `Dépend de` (liste), `Périmètre`
  (liste à puces des chemins déclarés) — champs directement mappés sur le schéma
  `MISSION-*.dag.json`. Libellés de champ (`dt`) en `--vf-text-xs --vf-text-secondary` (idem
  provenance, plancher a11y du §3).

Ouverture : `transform: translateX(0)` depuis `translateX(105%)`, `--vf-motion-base` ease-decel
(§6). Le drawer se ferme sur `Échap`, clic sur `✕`, ou clic sur un overlay semi-transparent
(`background: rgba(0,0,0,.4)`) posé derrière lui dès `> 640px` de large — sous ce seuil, pas
d'overlay (le drawer occupe déjà l'essentiel de l'écran).

### 4.7 Ligne de journal (accès secondaire, pas un panneau principal)

Un simple lien texte discret en pied de page (`--vf-text-xs`, `--vf-text-secondary` — plancher
a11y du §3, discrétion portée par la taille), `voir le journal (N événements)`, qui ouvre le même
drawer avec une liste de lignes `HH:MM:SS [cat] msg` en
`--vf-font-mono --vf-text-sm`, catégorie colorée en `--vf-text-secondary` sauf `parse`/`watch`
en erreur → `--vf-status-failed`. Volontairement en retrait : c'est un outil de diagnostic, pas
un panneau de lecture régulière (cf. §0, « ce qui est bruit »).

---

## 5. États

### Page entière

| État | Rendu |
|---|---|
| **Chargement initial** | Squelette minimal : en-tête déjà peint avec badges `…`, sections ①②③ avec un bandeau `--vf-surface-1` pulsé une fois (pas de spinner — le premier `fetch('/api/state')` est local et rapide) |
| **Vide — pas de `.planning/`** | Toute la page laisse place à un état centré unique : icône `⌁` discrète + « Aucun dossier `.planning/` trouvé à la racine du lab. Ce cockpit visualise un projet piloté par GSD — lancez-le depuis un lab qui en a un. » Aucune section vide n'est rendue en dessous. |
| **Erreur serveur (`/api/state` 5xx ou réseau)** | Bandeau pleine largeur en tête, fond `--vf-status-failed-bg`, texte `--vf-status-failed` : « Impossible de lire l'état du lab. Nouvelle tentative automatique… » — la dernière donnée connue reste affichée en dessous, légèrement estompée (`opacity: .55`), jamais remplacée par un écran blanc. |
| **Hors-ligne / SSE déconnecté** | Le point de pouls du badge verrou passe en `--vf-text-tertiary` fixe (plus d'animation), et un petit texte apparaît sous l'horodatage : « connexion perdue — dernière donnée à HH:MM:SS ». `EventSource` réessaie nativement (`retry: 1000`) ; dès un message reçu, le bandeau disparaît sans rechargement de page. |
| **Lock périmé (stale)** | Badge verrou en `--vf-status-stale`/`stale-bg`, glyphe `⚠`, texte : « verrou périmé ({age}s) — probablement une mission interrompue. Lecture seule, rien n'est bloqué ici. » Le reste de la page fonctionne normalement (dernier snapshot connu). |

### Trajectoire (①)

| État | Rendu |
|---|---|
| Vide (`phases: []`, `ROADMAP.md` absent ou sans checklist) | Message inline dans la section : « Aucune phase trouvée dans `ROADMAP.md` — ce lab n'a pas encore de feuille de route GSD. » |
| Toutes phases closes (aucune en cours) | Le libellé de la chip courante disparaît (pas de phase à mettre en avant) ; texte de section : « Toutes les phases du milestone sont terminées. » remplace la ligne de chaîne. |

### Chantier actuel (②)

| État | Rendu |
|---|---|
| Chargement de la fiche (`/api/phase?num=N` en vol) | Carte présente avec titre déjà connu (vient de `state.current_phase_name`), zone plans + but en placeholder `--vf-surface-3` (pas de layout shift à l'arrivée des données) |
| Vide — pas de dossier `VFDO-N-*` | `dir: null` → aucune rangée de puces plans, texte : « Aucun plan posé pour cette phase pour l'instant. » |
| Vide — pas de section `### Phase N` dans ROADMAP.md | `body: null` → dans le drawer : « Pas de fiche trouvée pour cette phase dans `ROADMAP.md` — seules les phases documentées y ont une fiche détaillée. » |

### Équipe en mission (③)

| État | Rendu |
|---|---|
| **Vide — aucune mission active** (`dags: []`) | Pas de SVG ni de liste : bloc centré, icône `◌`, texte : « Personne au travail pour l'instant. La prochaine mission apparaîtra ici automatiquement, sans rechargement. » |
| Chargement / re-rendu Mermaid en cours | Le SVG précédent reste affiché (`aria-busy="true"` sur le conteneur) jusqu'à ce que le nouveau soit prêt — jamais de vide intermédiaire pendant un `refresh()`. |
| Erreur de rendu Mermaid (definition invalide) | Le conteneur SVG affiche un message discret `--vf-status-failed` : « Le diagramme n'a pas pu être généré — voir le journal. » La liste accessible jumelle (§4.6), elle, reste fonctionnelle indépendamment du SVG (elle est construite depuis les mêmes données brutes, pas depuis le SVG). |

### Historique (milestones clos)

| État | Rendu |
|---|---|
| Vide — pas de `MILESTONES.md` ou aucun `✅` | `<details>` désactivé visuellement (`opacity: .5`), pas d'ouverture possible, texte au survol/aria : « Historique vide : ce lab n'a pas encore clos de jalon. » |

### Composants transverses (hover / focus / actif / sélectionné)

| État | Rendu générique (chips, boutons, nœuds de liste) |
|---|---|
| `:hover` | `background: var(--vf-surface-3)`, `border-color: var(--vf-border-strong)`, `--vf-motion-fast` |
| `:focus-visible` | `outline: 2px solid var(--vf-accent); outline-offset: 2px` |
| `:active` | `transform: scale(.98)`, `--vf-motion-fast` |
| Sélectionné (fiche ouverte sur cet élément) | `border-color: var(--vf-accent)`, `background: var(--vf-accent-soft)`, `aria-current="true"` |

---

## 6. Motion

Budget volontairement sobre — rien ne doit distraire d'une page qu'on consulte en tâche de fond.

```css
:root {
  --vf-motion-fast: 120ms;
  --vf-motion-base: 200ms;
  --vf-motion-slow: 320ms;
  --vf-ease-standard: cubic-bezier(.4, 0, .2, 1);
  --vf-ease-decel:    cubic-bezier(0, 0, .2, 1); /* entrées */
  --vf-ease-accel:    cubic-bezier(.4, 0, 1, 1);  /* sorties */
}
```

Ce qui s'anime :
- **Ouverture/fermeture du drawer** : `transform` seul (`translateX`), `--vf-motion-base`,
  `--vf-ease-decel` à l'ouverture / `--vf-ease-accel` à la fermeture.
- **Hover/focus** de tout élément interactif : `--vf-motion-fast`, `--vf-ease-standard`, propriétés
  `background-color`, `border-color`, `outline-color` uniquement (jamais `box-shadow` animée).
- **Pouls du badge de verrou** (seule boucle infinie de la page) : `opacity` du point `●` entre
  `.5` et `1`, `2.4s ease-in-out infinite`.
- **Highlight ciblé d'un nœud/chip qui vient de changer de statut** (diff entre deux snapshots) :
  `outline` amber qui apparaît puis s'efface, `--vf-motion-slow`, une seule fois par changement —
  jamais répété tant que le statut ne change pas à nouveau.
- **Horodatage `maj HH:MM:SS`** : la classe `.flash` colore le texte en `--vf-accent` pendant
  `400ms` puis repasse à `--vf-text-secondary` (plancher a11y du §3) — signal minimal, local,
  jamais un flash de page.

Ce qui ne s'anime jamais : le re-rendu du SVG Mermaid lui-même (remplacement direct du DOM, pas de
fondu — un crossfade sur un diagramme technique ajoute de la charge cognitive sans bénéfice), le
scroll (pas de smooth-scroll forcé), l'apparition du contenu au chargement initial (pas de
fade-in générique — motif d'« AI slop » identifié explicitement à proscrire).

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.001ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.001ms !important;
  }
}
```

---

## 7. Responsive

Cible principale : écran large de développeur (≥ 1280px). Doit rester pleinement utilisable en
fenêtre partagée à ~1024px et en fenêtre étroite (moitié d'écran sur un 13", ~680px).

| Rupture | Comportement |
|---|---|
| `≥ 1280px` | Layout de référence (§1). Colonne unique `max-width: 76rem` centrée, niveau ③ en deux colonnes (SVG + liste). |
| `1024–1279px` | Identique, `max-width` fluide (`100% - 2 × padding`). Aucun réagencement structurel. |
| `768–1023px` | Le niveau ③ passe en une colonne (`grid-template-columns: 1fr`) : SVG Mermaid au-dessus, liste accessible en dessous, dans cet ordre pour préserver la lecture visuelle avant le détail textuel. Les chips de la Trajectoire restent en rangée avec `flex-wrap: wrap`. |
| `640–767px` | En-tête passe en deux lignes (`flex-wrap: wrap`) : ligne 1 = nom du module + badge verrou, ligne 2 = badge milestone + horodatage. Le drawer perd son overlay de fond (occupe déjà l'essentiel de la largeur) et sa largeur passe à `100vw`. |
| `< 640px` | Les chips de phase passent enétiquette compacte (numéro + glyphe seuls, nom complet en `title=`/`aria-label`) pour éviter le débordement horizontal ; le connecteur `→` devient vertical (`↓`) et la chaîne se lit de haut en bas. |

Aucune media query ne change les tokens de couleur ou de statut : seule la mise en page réagit,
jamais la palette (pas de « mode clair forcé mobile »).

---

## 8. Thème Mermaid

Mermaid détonne par défaut (thème clair/violet). Configuration exacte pour s'accorder aux tokens
(§2), appliquée une fois à `mermaid.initialize` — les valeurs sont dupliquées en littéral parce que
Mermaid ne lit pas les custom properties CSS au moment du rendu SVG :

```js
mermaid.initialize({
  startOnLoad: false,
  theme: 'base',
  themeVariables: {
    background:            '#12151b', // --vf-surface-1
    primaryColor:           '#171b23', // --vf-surface-2
    primaryTextColor:       '#e8ecf1', // --vf-text-primary
    primaryBorderColor:     '#5a6479', // --vf-border-strong
    lineColor:              '#5a6479', // --vf-border-strong (arêtes)
    secondaryColor:         '#171b23',
    tertiaryColor:           '#12151b',
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
    fontSize:               '13px',
    edgeLabelBackground:     '#12151b',
    clusterBkg:              '#171b23', // subgraphes (Trajectoire, si jamais réintroduits en Mermaid)
    clusterBorder:           '#262c37',
  },
});
```

`classDef` par statut (appliqués sur chaque nœud du DAG, `:::done`/`:::running`/`:::ready`/
`:::blocked`/`:::failed`/`:::stale`), valeurs identiques aux tokens §2.2 :

```
classDef done    fill:#10261a,stroke:#3fd67a,color:#3fd67a
classDef running fill:#2b2109,stroke:#e0a92d,color:#e0a92d,stroke-width:2px
classDef ready   fill:#0e1e33,stroke:#5aa9ff,color:#5aa9ff
classDef blocked fill:#161a21,stroke:#7b8494,color:#7b8494
classDef failed  fill:#2c1211,stroke:#f0605a,color:#f0605a,stroke-width:2px
classDef stale   fill:#2c1c10,stroke:#d97a3d,color:#d97a3d,stroke-dasharray:3 2
```

`stroke-width:2px` sur `running`/`failed` : ces deux statuts demandent une attention immédiate,
la bordure plus épaisse est un quatrième signal (au-delà couleur + texte + position dans la liste
jumelle) sans dépendre uniquement de la couleur.

---

## 9. Anti-objectifs

- **Pas de police décorative ni de webfont** — pile système uniquement (le module doit fonctionner
  hors-ligne, sans requête réseau autre que `localhost`).
- **Pas de gradient** sur les surfaces, badges ou boutons — aplat uni + bordure, cohérent avec un
  cockpit lisible plutôt qu'un produit marketing.
- **Pas d'ombre portée décorative** sur les cartes plates — seule le drawer, qui se superpose
  réellement au contenu, porte une ombre directionnelle fonctionnelle.
- **Pas de fade-in générique au chargement** — le contenu apparaît net, immédiatement disponible.
- **Pas de statut porté par la seule couleur** — toujours glyphe + texte en doublon (§3).
- **Pas de mur de 35 phases ni de DAG replié dans un coin** — la densité est gérée par groupement
  et repli explicite (§0), jamais par miniaturisation illisible.
- **Pas de clic uniquement accessible à la souris** — tout élément interactif du SVG Mermaid a un
  doublon HTML focalisable (§4.4, §4.6) ; aucune fonctionnalité n'existe *seulement* dans le SVG.
- **Pas de rafraîchissement live qui clignote** — un `refresh()` ne provoque jamais de flash
  pleine page, seulement des micro-signaux ciblés (§6).
- **Pas d'écran d'erreur qui remplace la dernière donnée connue** — une erreur réseau/serveur
  s'affiche en surimpression, jamais en effaçant ce qui était déjà lisible (§5).
- **Pas de sur-affirmation du diagnostic** — le module reste un miroir en lecture seule de
  `.planning/` : aucune action, aucun bouton d'écriture, aucune suggestion « corriger » n'apparaît
  nulle part dans l'interface.
