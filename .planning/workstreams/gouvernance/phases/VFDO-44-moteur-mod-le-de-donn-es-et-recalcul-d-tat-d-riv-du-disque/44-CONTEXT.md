# Phase 44: Moteur — modèle de données et recalcul d'état dérivé du disque - Context

**Gathered:** 2026-09-27
**Status:** Ready for planning
**Compartiment :** `gouvernance` — toute commande GSD de cette phase passe `--ws gouvernance`.
**Décisions humaines :** Q1 à Q6 tranchées par Willy, AskUserQuestion session principale,
2026-09-27 (relayées par la session principale au manager de mission). Les décisions marquées
« délégué » sont celles du manager, validées telles que listées par Willy, même canal, même date.

<domain>
## Phase Boundary

La phase livre deux choses, et rien de plus :

1. **Le modèle de données d'un lab métier**, écrit et outillé : `cycles/`, `phases/`,
   `CYCLE.md`, `CADRAGE.md` (registre d'inconnues avec colonne structurante), `PLAN.md` avec le
   champ de périmètre `ecrit:`, le **fichier marqueur de clôture de plan**, `VERDICT.md`,
   `SUMMARY.md`, et la liste fermée des emplacements annexes.
2. **Un recalcul en Python** qui dérive du disque les huit états (dont `indéterminé`) et génère
   `INDEX.md`, `STATE.md` et `cloture.log` — incrémental par **hash du contenu**, jamais par
   `mtime`.

Hors de cette phase : tout refus au passage d'une écriture (hooks, gates G1 à G7, D1 — Phases 45
à 47), les baux (47), l'injection de l'index et le pont mémoire (48), les cycles récurrents (§8).
La 44 ne refuse rien sur le contenu d'un planning : son seul refus est de **ne pas écrire** sur un
planning qui n'a pas adhéré au nouveau schéma (D-02).

</domain>

<decisions>
## Implementation Decisions

### Frontière avec le moteur de développement (Q1)

- **D-01 :** le moteur vit dans le module **`plugin/planning-core/`** et remplace son socle
  **métier**. Frontière posée par Willy : le planning du module de développement (moteur GSD,
  gsd-core) n'est **pas** touché ; le socle métier de `planning-core` est remplacé ; les deux
  sont distincts, même s'ils partagent la même base. — **Reversibility:** costly — le modèle et
  le recalcul deviennent le contrat que consomment les Phases 45 à 50.
- **D-01a (contrainte) :** **aucun fichier** du moteur GSD (`~/.claude/gsd-core/`,
  `.claude/gsd-core/`) ni de `plugin/dev-orchestrator/` n'est modifié par cette phase. Vérifié
  au diff complet de la phase (`git diff --name-only <base>..HEAD`), en commande de vérification
  d'un plan.
- **D-01b (contrainte) :** l'**altitude lab** que `planning-core` sert aussi aux labs dev (index
  des projets, compartiments, `workstream-policy.sh`, `detect-planning-debt.sh`, hooks
  existants) reste **inchangée à l'identique**, prouvée par ses suites existantes
  (`plugin/planning-core/scripts/tests/*.sh`) vertes sans modification de ces suites.
- **D-01c (contrainte) :** un lab dev n'est **jamais** réécrit — garanti par D-02 (adhésion
  explicite) et par la détection d'un planning GSD, qui refuse l'écriture.
- **D-01d (ce qui est commun — « même base ») :** le principe **état dérivé du disque, jamais
  déclaré** (spec §1.1) et le **vocabulaire des états**. La réutilisation porte sur les principes
  et le déroulé de GSD (spec §1.1, §5, table des gestes du §4 : état dérivé, planifier et juger
  séparés, contrôleur de plan), **pas sur son code** : aucune dépendance de code vers gsd-core
  (ni `require`, ni appel à `gsd-tools`, ni lecture de ses fichiers).
- **D-01e :** retrait du socle métier existant (`guard-planning-updated.sh` et sa mesure par
  `mtime`, prose « scaffoldeur » du `SKILL.md`) : **pas dans cette phase**. En 44, le
  remplacement est additif — les labs qui adhèrent au nouveau schéma passent au moteur, les
  autres restent sur l'existant (D-02). Tout retrait de code existant arrive avec les gates
  (45+) et passe par une validation humaine (ADR-031 : suppression de code).

### Adhésion explicite (Q2)

- **D-02 :** le recalcul n'**écrit** que si `.planning/config.json` déclare le nouveau schéma.
  Sans cette déclaration, il **refuse sans rien toucher** : aucun fichier créé, modifié ou
  supprimé, cache compris ; code de sortie non nul, message qui nomme la déclaration attendue.
  Clé et valeur **déléguées** au planificateur, avec une contrainte : réutiliser la clé
  `planning_version` que le corpus porte déjà (spec §11.3 : schémas 1.0 et 2.0), en lui donnant
  une valeur nouvelle, plutôt qu'inventer une seconde clé. — **Reversibility:** costly — la clé
  devient le contrat d'adhésion des labs.
- **D-02a (délégué, dérivé de Q2 et Q6) :** un **mode lecture seule** calcule la dérivation sur
  n'importe quel planning, adhérent ou non, et l'écrit sur la sortie standard **uniquement** :
  aucun fichier écrit, pas même le cache. C'est lui qui sert aux passages sur les labs réels
  (D-06). Un planning GSD détecté est refusé en mode écriture même s'il déclare le schéma.

### Marqueur de clôture de plan (Q3)

- **D-03 :** le marqueur de clôture d'un plan est un **fichier à côté du plan**. `PLAN.md` n'est
  **jamais** modifié pour marquer la clôture : son hash reste stable, ce que consommeront les
  verdicts hachés de la Phase 46. Nom et contenu du fichier **délégués** au planificateur, décrits
  dans la référence du modèle. `à exécuter` = `PLAN.md` présent, marqueur absent (spec §3.1).

### Emplacements hors modèle (Q4)

- **D-04 :** une **liste fermée** d'emplacements annexes nommés à la racine de `.planning/`. Le
  recalcul les ignore ; **tout le reste** qui n'est ni un emplacement du modèle ni un emplacement
  annexe est **signalé « hors modèle »** dans `INDEX.md` (signalé, jamais refusé, jamais
  déplacé). Contenu de la liste : les six dossiers du §7.3 (`_bancs/`, `recherches/`, `intel/`,
  `sketches/`, `_archive/`, `registres/`). Les emplacements du modèle lui-même (`cycles/`,
  `baux/`, `missions/`, `PROJECT.md`, `REQUIREMENTS.md`, `config.json`, `INDEX.md`, `STATE.md`,
  `cloture.log`, cache du recalcul) ne sont pas « annexes », ils sont le modèle. La liste vit dans
  le code et dans la référence du modèle, pas dans `config.json` (option écartée par Willy).

### Arbitrage d'usage `phases_trace: false` (Q5)

- **D-05 :** **non tranché en 44.** Le recalcul ne refuse rien, il ne coûte que sa dérivation. Le
  drapeau n'est pas lu par la 44. L'arbitrage (§11.2 : que doit rendre le traçage pour valoir son
  prix, à quelle frontière on le limite) **passe au cadrage de la Phase 45**, qui armera les gates.

### Banc d'essai (Q6)

- **D-06 :** un **banc synthétique versionné** dans le dépôt couvre les huit états, les
  dérogations et les contradictions qui rendent `indéterminé`. **Il est le seul à gater en CI.**
- **D-06a :** plus un **passage en lecture seule, hors CI**, sur **deux labs réels** du poste :
  **Jarvis Keystone** (`~/jarvis-keystone`, `.planning/` de 2 020 fichiers au 2026-09-27) **et
  BusinessFlow-Lab** (`~/BusinessFlow-Lab`, `.planning/` racine de 4 fichiers,
  `"phases_trace": false`). Chemins localisés par le manager le 2026-09-27 (`.claude/` et
  `.planning/` présents dans les deux). Ils mesurent le **temps** du recalcul et le **nombre
  d'`indéterminé`**. Ces chemins sont propres à ce poste : ils ne vivent que dans les artefacts de
  phase (SUMMARY, rapport de mission), **toujours** sous la forme `~/…` (jamais un chemin absolu
  de compte : gate `check-machine-paths`), **jamais** dans le code livré ni dans une suite de CI.
- **D-06b :** **aucune écriture** dans ces labs, et c'est **prouvé** : empreinte de l'arbre
  complet de chaque lab (chemins + sha256 de chaque fichier) prise avant et après le passage,
  comparée octet par octet (`cmp`) — l'écart attendu est vide. Aucune commande `git` n'est lancée
  dans ces labs (ce sont d'autres dépôts). Les deux labs n'ont pas adhéré au nouveau schéma : seul
  le mode lecture seule (D-02a) y tourne.
- **D-06c :** les « quatre retenus » de la spec (§13, « premier banc d'essai à choisir parmi les
  quatre retenus ») **restent non nommés** : aucun fichier du dépôt ne les liste au 2026-09-27.
  Consigné ici ; Willy a désigné les deux labs réels sans les rattacher à cette liste.

### États et altitudes (délégué)

- **D-07 :** les huit états du §3.1 s'appliquent aux **phases** et aux **plans** (`plans/NN-<nom>/`
  sous une phase). L'état d'un **cycle** est une agrégation de ses phases, règle déléguée au
  planificateur et écrite dans la référence du modèle. Les dérogations `abandonné | remplacé |
  gelé` (non dérivables) sont lues dans un champ `statut:` qui doit **nommer son auteur**
  (dérogation nominative, D-03 de la spec) ; une dérogation sans auteur rend `indéterminé`.
- **D-08 :** **toute combinaison de signaux non prévue rend `indéterminé`**, jamais une
  supposition (« un faux vert est pire qu'un aveu », spec §3.2). Exemples à couvrir au banc :
  `SUMMARY.md` sans `PLAN.md`, `VERDICT.md` sans marqueur de clôture, `SUMMARY.md` avec un verdict
  en échec, marqueur sans `PLAN.md`.
- **D-09 :** `VERDICT.md` : en 44, le recalcul **lit ses constats** (passé / échec) pour dériver
  `à corriger` et `close`. Le format porte les champs `hash` de l'artefact jugé et `tentative`
  (spec §3, §10) ; leur **vérification** (hash contre l'artefact) relève de la Phase 46 — la 44 les
  lit s'ils sont présents, sans les contrôler.

### Sorties générées (délégué)

- **D-10 :** `INDEX.md` : par cycle, état dérivé, phase courante, dernier signe de vie (lu dans
  `cloture.log`), bail en cours (« aucun » en 44 : les baux arrivent en 47), plus la liste des
  entrées « hors modèle » (D-04). `STATE.md` : position courante. Sortie **déterministe** — deux
  recalculs sur le même disque produisent des fichiers identiques octet pour octet.
- **D-11 :** `cloture.log` est **append-only** : le recalcul ajoute une ligne quand il **observe**
  l'entrée d'une phase ou d'un plan en `close` (ou en état de dérogation), **datée au moment de
  l'observation et signalée comme telle** dans la ligne. Jamais une ligne réécrite ou supprimée.
  Format de ligne conforme au §7.4 (horodatage ISO avec fuseau, chemin, auteur, verdict), auteur
  résolu sans git (source déléguée au planificateur, « inconnu » explicite à défaut).

### Implémentation (délégué)

- **D-12 :** **Python 3.9+, bibliothèque standard seule** (PyYAML absent de ce poste ; parser de
  frontmatter minimal écrit pour le modèle). Aucun recalcul en bash (D-09 de la spec). Un point
  d'entrée shell mince est admis s'il ne fait que lancer Python.
- **D-13 :** **incrémental par hash du contenu, jamais par `mtime`** (spec §10). Cache sous
  `.planning/` (nom délégué). Un cache absent, illisible ou d'un autre format provoque un
  **recalcul complet**, jamais une confiance aveugle. Preuve au banc, dans les deux sens : un
  `touch` sans changement de contenu ne change rien ; un changement de contenu à `mtime` restauré
  est vu.
- **D-14 :** **livraison dans un lab.** L'installeur (`plugin/_internal/vibeflow-update.sh`,
  l.1200, 2005, 2030, 2519, 2804) ne pose aujourd'hui que `*.sh`, `*.json`, `*.mjs`, `*.js` : un
  fichier `.py` de `scripts/` **ne serait pas installé**. La recherche compare deux voies : (a)
  Python embarqué dans un `.sh`, motif déjà en place dans `plugin/conductor/scripts/dag.sh` —
  aucun changement d'installeur ; (b) extension de l'installeur à `*.py`, **sur tous ses sites**
  (sinon cascade par fausse analogie), tests sous `HOME=$(mktemp -d)` et audit obligatoire. **Voie
  par défaut : (a)**, sauf si la recherche la montre intenable ; le choix est motivé dans le plan.
- **D-15 :** **aucun hook ni gate câblé** dans cette phase : le recalcul est une commande. Où il
  tournera (SessionStart, clôture, écriture) se décide en 45/48 (spec §10 « dire où le recalcul
  tourne »). Les fichiers générés ne sont pas encore protégés contre l'écriture à la main (G6 = 45).
- **D-16 :** **exigences** de la phase sous le préfixe **`MOTR`**, vérifié libre par `git grep -E
  'MOTR-[0-9]'` le 2026-09-27 (0 fichier ; témoin `FABR-[0-9]` : 64 fichiers). Posées dans le
  `REQUIREMENTS.md` du compartiment avant le plan.
- **D-17 :** **tests** : suites bash découvertes par la CI sous
  `plugin/planning-core/scripts/tests/`, fixtures du banc synthétique versionnées ; chaque état
  naît avec son **jumeau négatif**, et chaque garde est prouvée par une **mutation rouge**, avec la
  trace du rouge (assertion, attendu, obtenu). Commandes de boucle rejouées sous zsh **et** bash
  avec au moins deux éléments.
- **D-18 :** **version** : bump **mineur** de `planning-core` (nouvelle capacité), CHANGELOG et
  README du module. **Aucune release** (pas de bump de la `VERSION` racine, pas de tag) : aucune
  release du jalon gouvernance avant la clôture de `fiabilite-v1.0`. Si une PR ouverte de
  `fiabilite` bumpe aussi `planning-core`, la PR de la 44 se renumérote après son merge.

### Claude's Discretion

Nom exact des fichiers générés annexes (cache), nom du fichier marqueur, clé et valeur de
l'adhésion (sous la contrainte de D-02), règle d'agrégation de l'état d'un cycle, source de
l'auteur dans `cloture.log`, structure interne du module Python, découpage en plans et vagues.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Spec source
- `docs/superpowers/specs/2026-09-22-moteur-planning-metier-design.md` §3 (modèle), §3.1 (huit
  états), §3.2 (pourquoi : marqueur, abandon, `indéterminé`), §7.1 (index), §7.3 (hygiène,
  emplacements hors modèle), §7.4 (le temps, `cloture.log`), §10 (contraintes d'implémentation),
  §11.2 (`phases_trace`), §11.3 (trous nommés), D-03, D-09, D-10 (§2).
- Même spec §1.1 et §4 (table des gestes) : ce que « même base » que GSD veut dire (D-01d).
- Même spec §5 (table des gates) : ce que la 44 ne fait **pas** encore, pour ne pas l'anticiper.

### Planning du compartiment
- `.planning/workstreams/gouvernance/ROADMAP.md` § Phase 44 (goal), en-tête du jalon (garde-fous
  de l'exécution anticipée : pas de release, gates rejoués à la main).
- `.planning/workstreams/gouvernance/REQUIREMENTS.md` (famille `MOTR`, D-16).
- `.planning/workstreams/gouvernance/STATE.md` (tenu à la main ; frontmatter fermé avant la
  ligne 60).

### Module cible et voisins
- `plugin/planning-core/SKILL.md`, `module.json`, `hooks/hooks.json`, `references/`,
  `scripts/` et `scripts/tests/` — l'existant à ne pas régresser (D-01b).
- `plugin/conductor/scripts/dag.sh` — motif Python embarqué dans un `.sh` (D-14 voie a).
- `plugin/_internal/vibeflow-update.sh` l.883, 1200, 2005, 2030, 2519, 2804 — ce que l'installeur
  pose (D-14).
- `CLAUDE.md` racine (densité ADR-029, trailers `Gate-Touche:`, traçabilité des arbitrages).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `plugin/conductor/scripts/dag.sh` : Python 3 embarqué en heredoc dans un script bash, sortie
  JSON, déjà livré aux labs par l'installeur.
- `plugin/planning-core/scripts/detect-gsd-engine.sh` : détection d'un planning tenu par GSD, à
  réutiliser pour refuser l'écriture sur un planning dev (D-02a).
- `plugin/planning-core/references/templates/` : gabarits existants (`INDEX`, `STATE`, `PLAN`,
  `SUMMARY`) du socle v2 — à ne pas casser ; les gabarits du nouveau modèle vivent à côté.

### Established Patterns
- Suites de test bash `test-*.sh` découvertes par la CI, contrat de sortie 0/1/3 des gates.
- `python3` déjà dépendance de la CI (`.github/workflows/ci.yml` « Dépendances (bash, jq,
  python3) »).
- Le Bash tool de ce poste tourne sous `/bin/zsh` ; la CI sous `bash -e {0}`.

### Integration Points
- Installeur (D-14) ; `module.json` / `VERSION` / `CHANGELOG.md` / `README.md` de `planning-core`
  (D-18) ; compteurs des README racine si une suite est ajoutée (`scripts/check-version-sync.sh`).

</code_context>

<specifics>
## Specific Ideas

- Mesure de référence de la spec : INDEX généré pour Keystone ≈ 1 392 octets ; recalcul Python
  9,7 à 12,4 s à 3 000 phases ; signature par hash ~66 ms à 3 000 phases. Les passages sur labs
  réels (D-06a) rapportent leurs propres chiffres, sans les comparer au-delà de l'ordre de
  grandeur : ces labs ne sont pas au nouveau modèle (0 `CYCLE.md`, 0 `VERDICT.md`, 0 `PLAN.md`
  avec périmètre, spec §11.3), donc la mesure dit surtout ce que le moteur fait d'un planning
  ancien — c'est son intérêt.

</specifics>

<deferred>
## Deferred Ideas

- Arbitrage `phases_trace: false` → cadrage de la Phase 45 (D-05).
- Retrait du socle métier existant de `planning-core` (garde par `mtime`) → avec les gates, sous
  validation humaine (D-01e).
- Protection des fichiers générés (G6), gates G1-G7, D1 → Phases 45-47.
- Où tourne le recalcul (hook) → Phases 45/48.
- Cycles récurrents, cadence, `bloqué par un tiers` (§8) ; pont mémoire (§7.5) ; migration des
  plannings existants au nouveau modèle, labs imbriqués, renommage de cycle (§11.3) → hors 44.
- Les « quatre retenus » de la spec (§13) : à nommer par Willy si la liste doit vivre (D-06c).

</deferred>

---

*Phase: 44-moteur-modele-de-donnees-et-recalcul-d-etat-derive-du-disque*
*Context gathered: 2026-09-27*
