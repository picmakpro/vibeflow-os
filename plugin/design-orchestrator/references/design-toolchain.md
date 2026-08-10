# Chaîne d'outils design (interne) + dégradation gracieuse

> **Usage** : référence consultée par `vibeflow-design` pour SON usage. Elle mappe le vocabulaire
> reframé (que voit l'utilisateur) aux **plugins réels** (que l'agent pilote en coulisse), donne la
> commande de vérification, et la conduite à tenir si un outil est **absent**.
>
> **Iron Law** : ces noms de plugins ne sont **jamais** prononcés à l'utilisateur — plomberie interne.

---

## Mapping reframe → plugin réel

| Vocabulaire VibeFlow (exposé) | Plugin réel (coulisse) | Rôle | Portée |
|---|---|---|---|
| **référentiel UX** | `ui-ux-pro-max:ui-ux-pro-max` | palettes (161), font pairings (57), styles (50+), guidelines UX (99), a11y, charts | web **+ mobile** (SwiftUI, RN, Flutter) |
| **direction créative** | `frontend-design:frontend-design` | direction distinctive anti-esthétique-IA (typo, composition, motion) | web |
| **atelier de craft** | `impeccable` (23 gestes) | gestes ciblés par dimension (voir table ci-dessous) | web |
| **exploration** | `superpowers:brainstorming` | exploration structurée de directions visuelles | universel |
| **gate de vérification** | `superpowers:verification-before-completion` | garde de sortie avant claim | universel |

### Gestes de l'atelier de craft (`impeccable`)

| Catégorie | Commandes | Quand |
|---|---|---|
| Build | `craft`, `shape`, `teach`, `document`, `extract` | concevoir de A à Z, planifier l'UX, générer/mettre à jour DESIGN.md, extraire des tokens |
| Evaluate | `critique`, `audit` | revue heuristique scorée, audit a11y/perf/responsive |
| Refine | `polish`, `bolder`, `quieter`, `distill`, `harden`, `onboard` | finition, amplifier, calmer, simplifier, edge cases, états vides |
| Enhance | `animate`, `colorize`, `typeset`, `layout`, `delight`, `overdrive` | motion, couleur, typo, rythme spatial, personnalité, pousser les conventions |
| Fix | `clarify`, `adapt`, `optimize` | copy UX, responsive/devices, perfs UI |
| Iterate | `live` | mode visuel : pick d'éléments dans le browser, variantes |

> `impeccable` exige `PRODUCT.md` (ou équivalent) en racine. Si `DESIGN.md` sert de référence
> produit, le signaler à l'outil. Sinon lancer `teach` **une fois** pour générer la fiche, puis reprendre.

---

## Vérification de présence (machine-vérifiée)

```bash
bash .claude/scripts/ensure-design-deps.sh
```

Contrat du script (`scripts/ensure-design-deps.sh` du module) :

1. **Présence ET activation** — un plugin installé mais **désactivé** compte comme manquant et
   fait l'objet d'un `claude plugin enable … --scope …`, **jamais** d'un `install` nu. C'est le
   trou fermé : `claude plugin list | grep <nom>` (ancienne détection outillée du repo) est aveugle
   à l'état enabled/disabled.
2. **Au moins une entrée active suffit** — un plugin dont une entrée du même nom est active compte
   comme présent, même si une AUTRE entrée du même nom est désactivée (cas réel : `frontend-design`
   installé à la fois sur `claude-code-plugins` désactivé et `claude-plugins-official` actif).
3. **Aucun contrôle de version/fraîcheur** — hors périmètre assumé : la moitié des plugins portent
   une version `unknown`, un contrôle de version serait du bruit.
4. **Ne dégrade jamais en silence** — tout part sur stderr. `--quiet` (ce que passe le hook
   d'install) supprime la routine mais laisse TOUJOURS passer les anomalies : plugin absent ou
   désactivé, geste réellement exécuté, étape manuelle. Un appelant ne doit donc jamais rediriger
   stderr vers `/dev/null` — ce serait reproduire, un cran plus haut, le silence que ce script ferme.

Marketplaces / commandes d'install (posées automatiquement par le script ci-dessus ; à proposer
manuellement si le script est indisponible, jamais à imposer en silence) :

| Plugin | Install |
|---|---|
| `superpowers` | `claude plugin install superpowers@claude-plugins-official` |
| `ui-ux-pro-max` | `claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill` |
| `frontend-design` | `claude plugin install frontend-design@claude-plugins-official` |
| `impeccable` | `claude plugin marketplace add pbakaus/impeccable && claude plugin install impeccable@impeccable` |

> **Note de non-divergence** : cette table et la table littérale de `ensure-design-deps.sh` sont
> **jumelles** — modifier l'une (nouveau plugin, marketplace renommé) impose de reporter le
> changement dans l'autre (même forme que la note de non-divergence portée par `sanitize_version()`
> dans le bootstrap de dev).

---

## Dégradation gracieuse (ne JAMAIS bloquer)

> Cette section reste **inchangée et prioritaire** : le script d'auto-install ci-dessus corrige ce
> qu'il peut, mais il n'a **jamais** le droit de bloquer un geste design. Script absent, CLI
> `claude` absente ou geste en échec → on dégrade ici, exactement comme avant.

L'objectif prime sur l'outillage. Ordre de priorité et repli :

1. **`ui-ux-pro-max` absent** → mener la validation sur les **premiers principes** (contraste WCAG,
   échelle typo modulaire, espacement 4/8px, hiérarchie). C'est le seul outil couvrant le mobile ;
   sur SwiftUI/Flutter, s'il manque, on s'appuie sur les Human Interface Guidelines / Material.
2. **`frontend-design` absent** (ou stack non-web) → appliquer directement les bans anti-slop
   (pas de police par défaut, pas de gradient cliché, pas de layout copié) sans le plugin.
3. **`impeccable` absent** (ou stack non-web) → exécuter le geste équivalent à la main
   (ex. « polish » = passe de finition manuelle guidée par la checklist du gate de sortie).
4. **`superpowers` absent** → mener l'exploration de directions en conversation structurée (3 pistes).

**Toujours** : si un outil a manqué, le mentionner **dans le rapport final** (« passe menée sans
l'atelier de craft — sur premiers principes »), **jamais à mi-course**, et sans nommer le plugin brut.

---

## Quand quel outil (résumé)

- **Référentiel UX** : au **début de chaque** tâche design (validation systématique).
- **Direction créative** : PLAN MODE + FULL DESIGN, stack **web**.
- **Atelier de craft** : à la demande, sur diagnostic précis (web).
- **Exploration** : INSPIRATION + FULL DESIGN.
- **Gate de vérification** : **avant** tout claim de complétion (universel).
