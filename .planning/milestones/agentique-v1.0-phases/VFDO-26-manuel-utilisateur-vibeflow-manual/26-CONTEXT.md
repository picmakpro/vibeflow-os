# Phase 26: Manuel utilisateur VibeFlow (manual/) - Context

**Gathered:** 2026-08-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Produire un manuel utilisateur bilingue (FR + EN) sous `manual/`, à l'usage d'un humain qui
découvre VibeFlow — distinct de `docs/` et `.planning/` qui restent la mémoire de travail des
agents. Un lecteur qui arrive sur le repo doit pouvoir installer, comprendre et opérer VibeFlow
sans jamais ouvrir `.planning/` ni `docs/`.

**Amendement en cours de mission (2026-08-01) : `manual/` reste local, hors git.** L'exclusion
`.git/info/exclude:7` (`manual/`) est déjà posée et vérifiée (`git check-ignore` rc=0). Aucun
fichier sous `manual/` ne doit jamais être `git add`é ni commité. `README.md`, `README.fr.md`,
`INSTALL.md`, `scripts/`, `.github/ci.yml` sont **hors périmètre d'écriture** de cette phase (le
volet « les README pointent vers le manuel » est suspendu — cf. mission §3bis, D-7/D-8 gelées).

Périmètre écrivain réel de cette phase :
- **sans commit** : `manual/**` (tout le contenu du manuel + `manual/.tools/`)
- **avec commit** : `.planning/phases/VFDO-26-manuel-utilisateur-vibeflow-manual/**`,
  `.planning/ROADMAP.md`, `.planning/STATE.md`

</domain>

<decisions>
## Implementation Decisions

Toutes les zones grises ont déjà été tranchées par deux panels de recherche indépendants
(`gsd-advisor-researcher`) avant l'ouverture de cette phase — voir le détail sourcé, complet, dans
`.planning/missions/2026-08-01-phase-26-manuel-utilisateur.md` (D-1 à D-13). Rien n'est rejoué ici ;
ce qui suit résume l'exécutable.

### Structure et navigation
- **D-01 (=D-1 mission) :** Miroir de dossiers `manual/fr/` + `manual/en/`, jamais de suffixes
  `.fr.md`. Tout lien de navigation intra-page est relatif et **intra-langue**. Seul le sélecteur
  de langue en tête de page traverse (miroir exact du chemin, `fr`↔`en` au 2ᵉ segment).
  — **Reversibility:** costly — changer de disposition après coup impose de réécrire tous les
  liens relatifs des ~40 pages.
- **D-02 (=D-2) :** Profondeur 2 niveaux : `manual/<lang>/NN-theme/slug.md`. Le préfixe numérique
  est **sur le dossier seulement** ; les fichiers gardent un slug stable, jamais de préfixe
  numérique (GitHub n'a pas de build step, un numéro dans le nom de fichier entrerait dans l'URL).
- **D-03 (=D-3) :** `manual/toc.yml` porte la séquence complète (un seul fichier, modèle mdBook
  SUMMARY.md). Le bandeau `← Précédent · ↑ Sommaire · Suivant →` est **généré** par
  `manual/.tools/build-nav.sh` depuis ce fichier, dans un bloc délimité par marqueurs HTML —
  jamais écrit à la main page par page.
- **D-04 (=D-4) :** Page = 100-200 lignes (~400-800 mots). Bascule ferme à >300 lignes ou >3 H2 de
  même rang → on scinde. Max 7 pages par dossier thème (plafond dur 9).
- **D-05 (=D-5) :** 7 thèmes, ordre fixe (trajectoire Diátaxis tutoriel→référence) :
  `01-demarrer` · `02-concepts` · `03-modules` · `04-cycle-de-dev` · `05-equipe-agents` ·
  `06-reference` · `07-sous-le-capot`. Slugs de dossiers identiques FR/EN.
- **D-06 (=D-6) :** La carte mermaid (`flowchart LR`, ≤20 nœuds = les 7 thèmes + leurs entrées, pas
  les ~40 pages) est **décorative** — sur GitHub les liens relatifs et emoji cassent dans un
  diagramme mermaid. Elle est **immédiatement suivie** d'une liste markdown de liens relatifs, qui
  porte la navigation réelle et l'accessibilité.

### Contenu et doctrine
- **D-09 (=D-9) :** Le manuel documente **9 principes**, sourcés de
  `plugin/reference/content/methodology/VIBEFLOW_CORE.md` (le canon, module v2.5.2). Les « 7
  principes » de `VIBEFLOW_EXPLAINED.md` sont qualifiés d'**historiques** par le canon lui-même
  (ligne 308) — ne pas les documenter comme actuels, et **ne pas corriger** ce fichier (hors
  périmètre).
- **D-11 (=D-11) :** Aucun contenu de référence n'est recopié — tout se **dérive du disque**
  (`module.json`, frontmatter des skills, `plugin/commands/`). Le README actuel ment sur 13/17
  versions de modules ; ne jamais reproduire cette dette. Aucune page du manuel ne porte de numéro
  de version en dur — elle pointe vers `module.json` et `CHANGELOG.md`.
- **D-12 (=D-12) :** Le manuel EN se **produit**, il ne se traduit pas — aux profondeurs 2-3 il
  n'existe aucune matière source EN. C'est le principal risque de budget de la phase.

### Outillage
- **D-13 (=D-13) :** L'outillage vit **sous `manual/.tools/`** (`build-nav.sh`,
  `check-manual.sh`), jamais dans `scripts/`, et **rien n'entre dans `ci.yml`**. Le gate doit
  refuser un verdict vide (échouer s'il ne découvre aucune page — même principe que le job
  `tests` de la CI qui refuse une découverte de suites vide).
  Le gate `check-manual.sh` doit vérifier et échouer (exit 1) sur :
  (a) arbres `manual/fr` et `manual/en` non isomorphes (page manquante d'un côté) ;
  (b) `.md` du manuel absent de `toc.yml`, ou entrée de `toc.yml` sans fichier ;
  (c) lien relatif mort ;
  (d) bandeau de navigation divergent de l'ordre de `toc.yml`.

### Exécution — contrainte machine non négociable (spécifique à cette phase)
- **D-14 [Claude's discretion, contrainte technique constatée] :** `git add` sur un chemin sous
  `manual/` échoue immédiatement (`error: The following paths are ignored...`, testé sur pièce le
  2026-08-01). **Aucune tâche du plan ne doit prévoir de commit sur un fichier `manual/**`.** Les
  tâches d'écriture de pages/outillage sous `manual/` sont des tâches de **contenu pur** (Write
  seul, sans étape git). Seules les tâches touchant `.planning/**` (mise à jour de suivi) sont
  commitées, avec le protocole habituel. Le plan DOIT distinguer explicitement, tâche par tâche,
  celles qui commitent de celles qui n'écrivent que sous `manual/`.
  — **Reversibility:** one-way si ignoré — un `git add -f`/`-A` accidentel sur `manual/`
  romprait la confidentialité locale demandée par l'amendement de mission et laisserait une trace
  irréversible dans l'historique git (nécessiterait une réécriture d'historique pour corriger).

### Manques prioritaires à combler (cœur de la valeur du manuel)
- **M-1** — « Et maintenant ? » : le premier quart d'heure après l'install (zéro ligne existante).
- **M-2** — Glossaire produit : lab, scope, bundle, team-kernel, driver lock, DAG, halt condition,
  juge frais, gate machine, rapport typé, worktree, anti-thrash (≠ lexique méthodologique déjà
  écrit dans `vocabulary/lexique.md`).
- **M-3** — Qu'est-ce qu'un « lab », concrètement (mot central jamais défini).
- **M-4** — Anatomie d'un lab installé (la seule trace actuelle est le tableau de désinstallation
  d'`INSTALL.md` §3.7, à l'envers).
- **M-5** — VibeFlow ↔ GSD (`@opengsd/gsd-core`) ↔ Superpowers, jamais expliqué pour un humain.

### Claude's Discretion
- Formulation exacte des pages, longueur précise dans la fourchette 100-200 lignes, choix des
  exemples concrets et du ton pédagogique.
- Répartition fine des pages par thème (dans la limite 5-9, plafond dur 9) tant que les manques
  M-1 à M-5 sont couverts en priorité.
- Ordre d'écriture des thèmes secondaires (03, 05, 06, 07) si le budget se resserre — priorité
  fixée par le digest de mandat : `toc.yml` + outillage + `01-demarrer` + `02-concepts` complets
  dans les deux langues d'abord.

</decisions>

<specifics>
## Specific Ideas

- `manual/README.md` est le **seul fichier bilingue** : titre, une phrase, deux liens vers
  `fr/README.md` et `en/README.md`. Rien d'autre.
- `manual/fr/README.md` et `manual/en/README.md` portent la carte mermaid décorative (D-06) + la
  liste de liens réelle + les tutos d'entrée.
- Écrire pour un humain qui découvre : phrases complètes, exemples concrets et copiables, aucun
  jargon non défini à sa première occurrence — c'est la raison d'être du manuel face à `docs/` et
  `.planning/` qui parlent aux agents.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Cadrage et décisions déjà tranchées
- `.planning/missions/2026-08-01-phase-26-manuel-utilisateur.md` — décisions D-1 à D-13 complètes,
  sourcées, avec rationale et reversibility ; amendement §3bis (manual/ hors git) ; à lire en
  entier avant tout écrit.
- `.planning/phases/VFDO-26-manuel-utilisateur-vibeflow-manual/26-INVENTAIRE-MATIERE.md` —
  cartographie complète de la matière source (96 unités / 8 sources), table des 12 doublons
  (§10), table des 12 manques (§11, M-1 à M-12), constat de parité FR/EN (§12).

### Doctrine produit à citer (jamais recopier intégralement)
- `plugin/reference/content/methodology/VIBEFLOW_CORE.md` — canon des 9 principes (P1-P9),
  architecture 5 composants, 5 registres.
- `plugin/reference/content/methodology/patterns/11-halt-conditions.md` et
  `12-cloisonnement-outils.md` — matière directement utile à l'utilisateur (pourquoi un agent
  s'arrête, pourquoi le juge n'est jamais l'auteur).
- `plugin/reference/content/AXIOMES-ENFORCEMENT.md` — 3 axiomes (enforcement > prose).
- `docs/ADR.md` — 15 ADR à valeur utilisateur listées en inventaire §7 (ADR-029, 031, 032, 035,
  044, 045, 051, 053, 054, 055, 057, 058, 059, 060, 064).

### Source de vérité "disque" pour le catalogue (D-11 — jamais recopier une version)
- `plugin/*/module.json` (17 modules) — nom, version, description.
- `plugin/commands/*.md` (6 commandes) — frontmatter description.
- Skills livrés : `plugin/*/skills/*/SKILL.md` (18 au total, cf. inventaire §9.b).
- Agents livrés : `plugin/*/agents/*.md` (22, cf. inventaire §9.d).

### Contrainte git (D-14)
- `.git/info/exclude` — ligne `manual/`, à ne jamais retirer ni modifier.
- Aucune entrée à créer dans `.gitignore` (fichier versionné — trace publique interdite par
  l'amendement de mission).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `plugin/reference/content/examples/PetitsCoursFlow/` — seul exemple « bout en bout » existant
  du repo (lab fictif complet). Matière de tuto pour `01-demarrer`, à adapter, jamais à copier
  tel quel (c'est un exemple de lab *fini*, pas de *création* de lab — M-9 de l'inventaire).
- `plugin/reference/content/README-CLIENT.md` — la matière la plus proche d'un manuel déjà
  écrite ; bonne base de ton pour `manual/fr/README.md`.

### Established Patterns
- Gates `check-*.sh` du repo (`scripts/check-release-tag.sh`, `scripts/check-state-integrity.sh`)
  — modèle de style pour `manual/.tools/check-manual.sh` : sortie `✓`/`✗` claire, exit 1 sur
  échec, jamais de vert sur un cas non testé.
- `.planning/phases/*/*-CONTEXT.md` et `*-PLAN.md` — format GSD standard de ce repo, à respecter
  pour les artefacts committables de cette phase.

### Integration Points
- Aucune intégration code — cette phase est purement documentaire, aucun test automatisé
  applicatif à faire passer.

</code_context>

<deferred>
## Deferred Ideas

- **D-7/D-8 de la mission (dégraissage README/INSTALL)** — gelées par l'amendement §3bis, pas
  abandonnées. À reprendre dans une phase dédiée le jour où `manual/` est publié.
- **D-10 de la mission (duplication `docs/reference/` ↔ `plugin/reference/content/`, 9 820
  lignes)** — hors périmètre, nécessite une suppression de contenu réservée à validation humaine
  (ADR-031). Proposé comme phase dédiée future.
- **Doc-drift `VIBEFLOW_EXPLAINED.md`** (« 7 principes », périmé face au canon) — nommé, non
  traité ici (édite `plugin/reference/content/`, hors périmètre, corpus versionné séparément).

</deferred>

---

*Phase: VFDO-26-manuel-utilisateur-vibeflow-manual*
*Context gathered: 2026-08-01*
