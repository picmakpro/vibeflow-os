## Choisir la partition du planning AU DÉMARRAGE, pas après coup — demandé 2026-09-23 — CLOS (2026-10-08)

**Clos le 2026-10-08** : livré par la Phase 41.2 (WSCH-01..05, PR #130, mergée le 2026-10-02). Réserve de recette
en session : sujet « Recette réelle de `/vf-split-planning` » plus bas.

**Statut : besoin exprimé par Samuel (session principale, 2026-09-23), non cadré.** À passer par
`/gsd-discuss-phase` avant toute écriture de code — rien n'est décidé ici.

**Le besoin, dans ses mots** : « on devrait pouvoir choisir si on partitionne ou pas dès le début,
et proposer des skills et scripts pour ça. On doit faciliter le travail. »

**Ce qui le motive, mesuré le jour même.** La partition réelle de ce dépôt (D-02, PR #94) a coûté
**13 commits**. Le geste de partition lui-même tenait en une commande : `workstream create`. Tout
le reste — l'essentiel — a consisté à réparer ce qui **supposait un planning unique** : la CI qui
traitait la racine comme l'oracle de sa propre non-partition, le ledger d'exigences, `E4` de
`check-mission-exit.sh`, `check-state-integrity`. Partitionner au démarrage n'économise pas la
commande, il économise **cette réparation**, parce que rien n'a encore eu le temps de supposer le
contraire.

**Ce qui va dans le même sens** : ADR-069 interdit déjà de partitionner tant qu'une phase est en
vol. Le seul moment structurellement sûr est donc le démarrage — la doctrine pointe déjà vers ce
besoin sans le servir.

**La réserve, à trancher au cadrage.** Partitionner un lab que personne ne travaille à plusieurs
n'apporte rien et coûte : il faut passer `--ws` partout, ou vivre avec un pointeur qu'on oublie.
La valeur apparaît quand **deux flux avancent en parallèle sur des périmètres disjoints** — c'est
exactement le cas de ce dépôt avec Willy, et ce n'est pas le cas de la plupart des labs. Un
« partitionner par défaut » serait une sur-ingénierie ; un « choix éclairé posé au bon moment »
est le vrai besoin. La question à poser à l'initialisation n'est donc pas « veux-tu des
workstreams ? » (jargon) mais « plusieurs personnes ou agents vont-ils travailler en parallèle sur
des sujets séparés ? ».

**Le piège à ne pas multiplier.** La partition de ce dépôt a laissé un angle mort déjà consigné
plus bas dans ce fichier : un gate câblé en dur sur un compartiment laisse les autres **sans
garde** (`ci.yml` vise `fiabilite`, `gouvernance` n'est jamais vérifié). Si VibeFlow se met à
proposer la partition dès le départ, ce défaut se reproduira dans chaque lab qui accepte. Le
remède connu — itérer sur les compartiments présents sur le disque, jamais revenir à une
résolution par `GSD_WORKSTREAM` — devrait être livré **avec** la capacité, pas après elle.

**Pistes, non arbitrées :**
- Une question à l'initialisation d'un lab (`vibeflow-conductor`), formulée en langage d'usage et
  non en jargon de moteur.
- Des gabarits de gates et de CI **nés workstream-aware**, plutôt que réparés après coup.
- Un skill qui porte le geste de bascule pour un lab déjà démarré, avec la précondition d'ADR-069
  vérifiée par machine (aucune phase en vol) plutôt que rappelée en prose.
- La partie distribuable existe déjà : le moteur `@opengsd/gsd-core` fournit `workstream
  create/list` et `--ws` ; VibeFlow fournit déjà la doctrine (`workstreams.md`, ADR-069) et les
  gardes (`check-divergence.sh`, `check-workstream-pointer.sh`, `workstream-policy.sh`). Le
  manquant est **l'ergonomie du choix**, pas la mécanique.

**Preuve d'usage à exiger au cadrage** : un lab neuf initialisé en mode partitionné dont les gates
passent au vert sur **chaque** compartiment, sans réparation manuelle — sinon la capacité ne fait
que déplacer les 13 commits chez l'utilisateur.

## Un gate câblé sur un seul compartiment de workstream laisse les autres sans garde — DIFFÉRÉ (2026-09-23) — CLOS (2026-10-08)

**Clos le 2026-10-08** : livré par la Phase 41.1 (WSAW-01..07, PR #100, release `v2.66.0`) ; `ci.yml:353` est nommé
par WSAW-02 et passe par le fan-out de compartiments.

**Capturé :** 2026-09-23, mission « partition réelle du planning D-02 » (`.planning/missions/2026-09-23-partition-planning-d02.md`).

**Le défaut :** l'étape CI « check-state-integrity (anti-régression du frontmatter … ADR-063) »
(`.github/workflows/ci.yml:353`) cible explicitement `.planning/workstreams/fiabilite/STATE.md` —
en dur, pas résolu par `GSD_WORKSTREAM` ni par le pointeur partagé. C'est le bon remède contre le
détournement du gate par l'environnement (défense en profondeur ADR-063, déjà la doctrine avant
cette mission) — mais son effet de bord est que la CI ne vérifie QUE ce compartiment. Mesuré
concret : `.planning/workstreams/gouvernance/STATE.md` (compartiment tout juste créé, gabarit frais
du moteur, pas encore de champ `milestone:` ni de ligne `^Phase:`) rend `rc=2` (« milestone
introuvable ») si on le vérifie explicitement — et la CI ne le verra JAMAIS, ni pour le dire cassé
ni pour le dire bon. L'angle mort grandit mécaniquement avec chaque compartiment ajouté (aujourd'hui
2 : `fiabilite`/`gouvernance` ; demain N).

**Piste de fix :** ne pas revenir à une résolution par `GSD_WORKSTREAM`/pointeur (c'est précisément
le vecteur de détournement qu'ADR-063 a fermé). À la place, itérer sur les compartiments PRÉSENTS
SUR LE DISQUE (`.planning/workstreams/*/`) au moment du run CI et appeler
`check-state-integrity.sh --file .planning/workstreams/<nom>/STATE.md` pour chacun explicitement —
chemins toujours en dur, énumération dynamique. Même logique que `check-divergence.sh`, qui
inspecte déjà tous les compartiments présents sans se fier à un pointeur.

**Déclencheur de reprise :** l'ajout d'un troisième compartiment, ou le premier incident réel où un
compartiment autre que `fiabilite` régresse sans que la CI ne le voie.

