# design-orchestrator — Orchestrateur de design (VFDO-design)

> Module VibeFlow qui route les requêtes de **design en langage naturel** vers le bon workflow —
> via un **agent routeur** (`vibeflow-design`), les verbes **`/vf-design`** et **`/vf-sketch`**, et
> une chaîne d'outils design pilotée en coulisse. L'utilisateur ne parle que VibeFlow ; la plomberie
> (référentiel UX, direction créative, atelier de craft) reste invisible.

**Version** : v1.2.0
**Type** : agent + skills + équipe de mission

---

## Vue d'ensemble

Dire « rends ça plus beau », « c'est moche », « refais cet écran », « on part sur quel style » ou
« audite cette page » déclenche le cycle design complet **sans jamais connaître les outils
sous-jacents**. Le module fournit :

1. **Agent `vibeflow-design`** (`AGENT.md`) — le cerveau routeur. Il porte la table de routage
   (intention NL → geste coulisse), la doctrine (DA avant refonte, diagnostic avant geste,
   vérification après craft) et la **généricité multi-stack**.
2. **Verbes `/vf-design` et `/vf-sketch`** (`skills/`) — délégateurs minces à description riche en
   wording, auto-invocables en langage naturel. `/vf-design` est le point d'entrée design (DA,
   refonte, critique, craft) ; `/vf-sketch` couvre la **maquette jetable** (« montre-moi à quoi ça
   ressemblerait »), le seul geste que l'utilisateur formule assez spontanément pour mériter sa
   propre porte. Contrat UI et revue UI restent routés en interne depuis `/vf-design`.
3. **Références on-demand** (`references/`) — workflow quotidien (`DESIGN-WORKFLOW.md`),
   initialisation de la DA (`DA-INIT.md`), chaîne d'outils + dégradation (`design-toolchain.md`),
   reframe (`design-vocabulary-map.md`), templates génériques.
4. **Équipe de mission design** (`agents/`) — trois agents natifs instanciés sur le
   **team-kernel** du conductor (voir ci-dessous).

---

## Équipe de mission design (team-kernel)

Première instanciation **non-dev** du team-kernel (`conductor-references/team-kernel.md`,
extrait du dev-orchestrator — ADR-053) : le pattern manager → worker → juge est réutilisé tel
quel, seule la **définition du « vert »** change — pas de test automatique en design, le vert
est une **critique scorée contre la direction artistique**.

| Agent | Modèle | Rôle |
|---|---|---|
| `vf-design-manager` | opus | Manager de mission : lit la DA + `.planning/`, plan de bataille en DAG (`dag.sh`), lock de driver, dispatch de la frontière **en parallèle** sur écrans disjoints, digest ≤ 30 lignes par mandat, contrôle de flux sur rapports typés, halt conditions, next step. Ne produit JAMAIS de design. |
| `vf-crafter` | sonnet, interne | Worker de production : applique la chaîne d'outils design (référentiel UX, direction créative, atelier de craft) sur UN écran/composant, produit specs + tokens multi-stack. Sans Task — dispatché uniquement par le manager. |
| `vf-design-judge` | sonnet, interne | Juge critique **frais** : score l'écran contre la DA (/40) et les 6 dimensions qualité (copy, hiérarchie visuelle, couleur, typographie, spacing, accessibilité — /10 chacune). Sans Write/Edit : il ne corrige jamais. |

**« Vert » design** : score du juge **≥ 70/100** (seuil par défaut, durcissable par brief) ;
**3 tours max** de craft → re-critique par écran (anti-thrash). Les corrections repartent
toujours à `vf-crafter` via le manager.

**Déclenchement** : sur signal mission design (multi-écrans, refonte complète, « toute
l'app »), l'agent `vibeflow-design` **propose** l'équipe (`Task(vf-design-manager)`) — jamais
d'office. Écran unique → workflow direct, zéro friction.

---

## Généricité multi-stack

Le module **ne présume jamais Next.js/Tailwind**. Il détecte la stack et adapte le système de
design produit : variables CSS + config (web) · tokens Swift / asset catalog (SwiftUI) ·
theme object / `ThemeData` (React Native / Flutter) · tokens neutres (desktop / autre). Il produit
des **specs + tokens**, pas du code framework-locké.

---

## Installation

Ce module est **installé d'office avec `dev-orchestrator`** (il figure dans ses `requires`) : tout
lab de développement dispose donc de `/vf-design` sans action supplémentaire. Il reste disponible
en à-la-carte avancé (« ajoute design-orchestrator »).

---

## Chaîne d'outils (interne, jamais exposée)

| Reframe VibeFlow | Plugin réel (coulisse) | Portée |
|---|---|---|
| référentiel UX | `ui-ux-pro-max` | web + mobile |
| direction créative | `frontend-design` | web |
| atelier de craft | `impeccable` (23 gestes) | web |
| exploration | `superpowers:brainstorming` | universel |

Si un outil est absent, l'agent **dégrade gracieusement** sur les premiers principes design et le
signale dans le rapport final (jamais à mi-course, jamais en nommant le plugin brut). Détail :
`references/design-toolchain.md`.

---

## Intégration avec dev-orchestrator

`vibeflow-dev` route les intentions de design (« améliore l'UI », « la DA », « c'est moche ») vers
`/vf-design` — la phase de design du cycle de développement est ainsi couverte sans quitter le
vocabulaire VibeFlow.
