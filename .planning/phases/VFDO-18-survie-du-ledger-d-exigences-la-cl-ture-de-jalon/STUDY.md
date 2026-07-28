# Phase 18 — Étude de faisabilité : ledger de specs vivantes par capability

**Question tranchée** : doter les labs VibeFlow d'un ledger de specs vivantes accumulées par
capability, en volant les conventions d'OpenSpec sans son outil, améliore-t-il réellement (a) ce
repo, (b) l'expérience de dev quotidienne dans un lab, (c) la qualité du spec-driven development ?
Critère : **valeur ajoutée nette**, pas faisabilité technique.

**Base** : `/Users/samuel/Documents/dev/vibeflow-os` @ `9b50891`, `VERSION` = `v2.42.0`.
**Moteur lu** : `/Users/samuel/.claude/gsd-core/` (`VERSION` = `1.8.0`).
**Date** : 2026-07-28. **Aucune écriture hors de ce fichier.**

Convention de lecture : les blocs **FAITS SOURCÉS** sont vérifiables par chemin + commande ; les
blocs **JUGEMENT** sont mon arbitrage et sont contestables sans contester les faits.

---

## 1. Verdict

> ## **GO-RÉDUIT**
>
> **NO-GO sur la Phase 18 telle qu'écrite** (les quatre briques : grammaire delta, ledger accumulé
> par capability, ancrage capability overlay `@ ship:post`, skill de spec-sync agent-driven) —
> **GO sur un seul geste résiduel** : faire survivre `.planning/REQUIREMENTS.md` à la clôture de
> jalon, sans nouveau fichier, sans nouvelle grammaire, sans overlay.

**Les trois raisons qui portent ce verdict**

1. **Le plan crée mécaniquement un quatrième registre sans en retirer aucun.** `ROUT-01` existe
   déjà en 3 copies aujourd'hui, sans la Phase 18 ; son Goal promet « zéro double état » mais ne
   nomme aucun fichier à supprimer → **double état = NO-GO** par la règle de décision du mandat.
   *(fait 7 ; preuve §4 ligne 1)*
2. **La brique visée est la moitié fragile d'OpenSpec, privée de la moitié qui la rattrape.** Les
   ~2 253 lignes TS et 16 garde-fous d'OpenSpec sont sur le chemin `archive` déterministe ; la
   Phase 18 vise le chemin `/opsx:sync` agent-driven — nommément celui qu'incrimine le seul
   témoignage d'abandon trouvé. *(faits 2 et 3 ; preuve §3.3)*
3. **L'ancrage est réel mais inopérant ici, et sa panne serait muette.** `ship:post` ne fire que
   dans `/gsd-ship`, chemin que ce repo n'emprunte pas (0 trace d'exécution, chemin de release
   alternatif documenté dans son propre `CLAUDE.md`) ; s'il firait, `onError: skip` rendrait tout
   échec silencieux et le gate `bundleContentHash` désarmerait la capability à la première édition
   du bundle. En parallèle, le repo laisse dériver le registre d'état qu'il a adopté
   (`.planning/codebase/ARCHITECTURE.md:8` annonce `v2.36.1` contre `VERSION` = `v2.42.0`).
   *(faits 10 et 11 ; preuves §5 et §6.4)*

**Ce que le GO-réduit autorise** : un seul geste, chiffré §7, sur un fichier qui existe déjà, écrit
par des skills qui existent déjà, sans introduire de nouvel objet dans le socle.

---

## 2. Ce que la Phase 18 propose vraiment

**FAITS SOURCÉS** — texte du Goal, `/Users/samuel/Documents/dev/vibeflow-os/.planning/ROADMAP.md:591`
(`### Phase 18: Capability living-specs (conventions OpenSpec)`) :

> « Doter les labs d'un ledger de specs vivantes accumulées par capability — « ce que le système
> EST », tenu à jour à la clôture de phase — en volant les conventions d'OpenSpec sans en installer
> l'outil : grammaire delta (ADDED/MODIFIED/REMOVED/RENAMED Requirements), merge par bloc
> `### Requirement:` + `#### Scenario:` (Given/When/Then), cycle delta → merge → archive. Ancrage :
> capability overlay `.gsd/capabilities/` accrochée à `ship:post` (ADR-1244 D2 côté gsd-core), specs
> sous `.planning/specs/<capability>/`, skill de spec-sync agent-driven. Contraintes : zéro
> dépendance externe, zéro double état, gouvernance conductor applicable (densité ADR-029). »
>
> `**Requirements**: TBD` · `**Plans:** 0 plans`. Dossier de phase :
> `.planning/phases/VFDO-18-capability-living-specs-conventions-openspec/` (chemin au moment de
> l'étude ; **renommé après coup** en `VFDO-18-survie-du-ledger-d-exigences-la-cl-ture-de-jalon`
> quand le ROADMAP a été requalifié — slug régénéré par
> `gsd-tools query generate-slug`, donc conforme à ce que le moteur recalculerait)
> → contient `.gitkeep` **et le présent `STUDY.md`**, tous deux non trackés. **Aucun plan, aucune
> exigence, aucune exécution** : la phase n'a jamais tourné.

**Reformulé sans jargon, en quatre briques indépendantes** :

| # | Brique | En clair | Verdict |
|---|---|---|---|
| **(i)** | **Grammaire delta** | Écrire les changements d'exigences dans un dialecte Markdown fixe (`## ADDED Requirements`, `### Requirement: X`, `#### Scenario: Y` + Given/When/Then) plutôt qu'en prose libre. | **NO-GO** |
| **(ii)** | **Ledger accumulé par capability** | Un fichier durable par domaine fonctionnel (`.planning/specs/<capability>/spec.md`) qui répond « qu'est-ce que ce système garantit **aujourd'hui** », par opposition aux artefacts de phase qui disent « ce qu'on a fait à l'étape N ». | **NO-GO tel qu'écrit / GO en variante réduite** |
| **(iii)** | **Ancrage capability overlay `@ ship:post`** | Un paquet `capability.json` posé sous `.gsd/capabilities/` que le moteur gsd-core charge et déclenche automatiquement en fin de cycle de livraison, pour lancer le merge sans geste humain. | **NO-GO** |
| **(iv)** | **Skill de spec-sync agent-driven** | Un skill VibeFlow qui demande à un agent LLM de fusionner « intelligemment » le delta de la phase dans le ledger durable. | **NO-GO** |

**JUGEMENT** — Le verdict diffère brique par brique et c'est le cœur de l'analyse. La brique (ii)
répond à un **vrai trou structurel** (§4, ligne 1 ; §6.1). Les briques (i), (iii), (iv) sont
respectivement du cérémonial sans consommateur, un ancrage inopérant sur ce repo, et la
réimplémentation manuelle d'un moteur déjà livré. Le trou réel se réduit à **un geste**, pas à un
sous-système — c'est l'objet du §7.

---

## 3. État de l'art OpenSpec

### 3.1 Ce qu'OpenSpec est — FAITS SOURCÉS

| Attribut | Valeur | Source |
|---|---|---|
| Dépôt | `Fission-AI/OpenSpec`, licence MIT, non archivé | https://github.com/Fission-AI/OpenSpec |
| Étoiles / forks / issues ouvertes | 62 878 / 4 347 / **332** | `gh api repos/Fission-AI/OpenSpec` (2026-07-28) |
| Créé | 2025-08-05 · dernier push 2026-07-28 | idem |
| Dernière release | **v1.6.0**, 2026-07-10 | https://github.com/Fission-AI/OpenSpec/releases |
| npm | `@fission-ai/openspec`, **1 167 577 dl/mois**, 41 versions | `api.npmjs.org/downloads` |

Le projet est **réel, vivant et massivement téléchargé**. La grammaire est du Markdown pur,
publique, sans runtime : elle est **volable gratuitement**. Confirmé verbatim :

- `docs/writing-specs.md` : « **`## ADDED Requirements`** — brand-new behavior… **`## MODIFIED
  Requirements`** — behavior that already existed and is changing. Include the full new version…
  **`## REMOVED Requirements`** — behavior going away »
- `src/core/parsers/requirement-blocks.ts:33` :
  `const REQUIREMENT_HEADER_REGEX = /^###\s*Requirement:\s*(.+)\s*$/i;`
- `src/core/specs-apply.ts:586` : `/^####\s*Scenario:\s*(.+)\s*$/`
- `RENAMED` **n'est documenté ni dans `docs/writing-specs.md` ni dans `docs/concepts.md`** — il
  n'existe que dans le code et le template de skill. Une reprise « par convention » fondée sur la
  doc publique le manquerait.

### 3.2 Convention vs outil — le fait décisif

**FAITS SOURCÉS.** La grammaire volable tient en ~25 lignes de doc. Le code qui la rend *fiable*
pèse **~2 253 lignes TypeScript** sur le seul chemin delta→spec vivante :

| Fichier | Lignes |
|---|---|
| `src/core/specs-apply.ts` (merge) | 607 |
| `src/core/validation/validator.ts` | 602 |
| `src/core/archive.ts` | 639 |
| `src/core/parsers/requirement-blocks.ts` | 323 |
| `src/core/parsers/spec-structure.ts` | 82 |

Ce code encode **16 garde-fous distincts**, dont les cinq qui protègent réellement le ledger contre
un agent LLM :
1. garde anti-perte de scénarios **multiplicity-aware** (`findMissingCurrentScenarios`, déclarée
   `specs-apply.ts:556`) ;
2. cinq règles de conflits inter-sections (MODIFIED∩REMOVED, ADDED∩REMOVED, RENAMED.TO∩ADDED…) ;
3. validation **pré-écriture transactionnelle** — « Aborted. No files were changed. »
   (`archive.ts:489` et `:513`, précédées des messages d'échec `:485` et `:504`) ;
4. détection de typo par fold casse/espaces (`foldRequirementName`) ;
5. masquage des blocs de code et des commentaires HTML **non terminés** (issue #1413).

Les commentaires du code citent nominativement les issues qui ont motivé chaque garde : **#498,
#1246, #1252, #1332, #1353, #1376, #1391, #1402, #1413** — soit **~7 correctifs de sémantique de
merge sur mai→juillet 2026**, sur un projet à 62,9k étoiles.

**JUGEMENT** — « Voler les conventions sans l'outil » revient à prendre la carte sans le moteur. Une
réimplémentation par convention repart au niveau de fiabilité d'OpenSpec v0.x et devra redécouvrir
les mêmes modes de défaillance, à la main, sans base d'utilisateurs pour les remonter.

### 3.3 Les deux sémantiques de merge — la contradiction

**FAITS SOURCÉS.** OpenSpec a **deux chemins de merge qui ne veulent pas dire la même chose**.

| Situation | `openspec archive` (CODE déterministe) | `/opsx:sync` (AGENT LLM) |
|---|---|---|
| MODIFIED partiel (n'inclut pas les scénarios existants) | **ABORT** : « current spec contains scenario(s) not present in the modified block » | **Comportement recommandé** : « don't copy existing scenarios » |
| ADDED d'une exigence déjà présente, contenu différent | **ABORT** : « already exists » | « update it to match (treat as implicit MODIFIED) » |
| Doctrine MODIFIED | `writing-specs.md` : « **Include the full new version** » | « The delta represents *intent*, not a wholesale replacement » |

Le template `src/core/templates/workflows/sync-specs.ts` (449 lignes) dit verbatim :
« This is an **agent-driven** operation… **Use your judgment to merge changes sensibly** ».

**Le seul témoignage d'abandon trouvé incrimine nommément ce chemin.** HN 47999279, 2026-05-03
(https://news.ycombinator.com/item?id=47999279), verbatim :

> « I enjoy the OpenSpec format but **I think maintaining the main specs is not worth it. I've
> stopped doing it entirely and just archive directly after implementation. When you do the sync
> process, it just keeps drifting and drifting until you have duplication and contradictions across
> specs.** I agree that tying the specs and code together helps for that but it still seems like
> extra overhead, even if the value is better justified here. »

Le témoignage est cité **intégralement**, dernière phrase incluse : elle nuance (« the value is
better justified here ») sans renverser le grief, et elle chiffre le motif d'abandon en
**overhead**, ce qui rejoint directement le §9(c).

Cet utilisateur **aime la grammaire** et abandonne **spécifiquement le ledger vivant** — c'est-à-dire
exactement le livrable de la Phase 18. Il garde les deltas archivés, il jette la spec accumulée.

Le témoignage inverse, honnêtement rapporté — HN 47427078, 2026-03-18 : « I do like the basic
concept and directory structure, but **those are easy enough to adopt without all the cruft** »,
avec critique de la verbosité (>1 000 mots pour le seul prompt `explore`).

### 3.4 Le pattern « ledger vivant accumulé » n'est pas éprouvé — FAITS SOURCÉS

- **spec-kit** (`github/spec-kit`, **124 218 étoiles**, ~2× OpenSpec) documente trois modèles de
  persistance et déclare, `docs/concepts/spec-persistence.md`, verbatim : « **None is the default,
  and none is required by Spec Kit** » et « **The model is a team convention, not a CLI setting.** »
  Il **n'a aucun ledger accumulé par capability, aucun merge de deltas**.
- **Böckeler** (martinfowler.com, `exploring-gen-ai/sdd-3-tools.html`), l'analyse indépendante de
  référence, sur le niveau exact visé (« spec-anchored ») : « spec-as-source, and even
  **spec-anchoring**, might end up with the downsides of both MDD and LLMs: **Inflexibility *and*
  non-determinism.** » — « Are we making something worse in the attempt of making it better? »
- **Tessl**, seul outil visant explicitement le spec-anchoring, est en **beta fermée depuis ~9
  mois**, pas de disponibilité générale.
- **Datation** : OpenSpec créé 2025-08-05, spec-kit 2025-08-21 → **tout l'écosystème a moins de
  12 mois**.
- Aucun contrôle spec↔code n'existe chez OpenSpec : issue #381 fermée sans livraison ; le mainteneur
  TabishB (discussion #169) : « **up till then this process has to be manual unfortunately** ».
- Bake-off chiffré (discussion #1159) : **+50 % de code, ×2 temps, ×3 coût API** vs Claude Code nu —
  mais l'auteur liste lui-même 6 caveats invalidants ; à ne prendre que comme indication.

**JUGEMENT** — La grammaire delta (filiation RFC 2119 / Gherkin) est solide et ancienne. Le
**ledger accumulé par capability tenu par merge de deltas** est spécifique à OpenSpec, âgé de moins
d'un an, non répliqué par ses concurrents, refusé délibérément par le plus gros acteur du marché, et
jugé non rentable par le seul praticien qu'on ait trouvé en train de le pratiquer. C'est une pratique
**émergente non éprouvée**.

---

## 4. Cartographie de l'existant et analyse de redondance

**FAITS SOURCÉS.** Légende : **TOTAL** = déjà servi, ne rien construire · **PARTIEL** = équivalent
existant qui ne couvre pas l'axe décisif · **NUL** = rien n'existe · **COLLISION** = le nom est déjà
pris avec un autre sens.

| # | Brique visée | Équivalent existant (chemin absolu) | Recouvrement | Commentaire |
|---|---|---|---|---|
| 1 | **Ledger d'exigences accumulé et durable** | `/Users/samuel/Documents/dev/vibeflow-os/.planning/REQUIREMENTS.md` — 21 133 octets (20,6 KiB), **5 blocs de jalon** (`## v1 Requirements`, `## Milestone 2`, `## Milestone 3`, `## Milestone gsd-migration`, `## Milestone vf-routing`), **18 préfixes d'ID stables** (`ABS ALTI BOOT BRDG CONS FIRST GSDM IDX INST MANIF PHIL PLUG RND ROUT SCOPE VERB VERIF VOC`), table `## Traceability` | **PARTIEL (fort)** | Indexé par **milestone**, pas par capability. Surtout : `/Users/samuel/.claude/gsd-core/workflows/complete-milestone.md:527,530,864` le **supprime** (`git rm .planning/REQUIREMENTS.md`, « fresh for next milestone »). Sa survie ici est une **déviation manuelle non reproductible**. |
| 2 | **Description de « ce que le système EST »** | `/Users/samuel/Documents/dev/vibeflow-os/.planning/codebase/` (7 docs, `gsd-map-codebase`) | **PARTIEL** | Descriptif, sans ID, non falsifiable, **régénéré en bloc** → dérive prouvée : `.planning/codebase/ARCHITECTURE.md:8` dit « (v2.36.1) » contre `VERSION` = `v2.42.0`. |
| 3 | **Spec falsifiable au grain exigence** | `gsd-spec-phase` → `{phase_dir}/{padded_phase}-SPEC.md` (`/Users/samuel/.claude/gsd-core/workflows/spec-phase.md:453`), template `Current` / `Target` / `Acceptance` | **PARTIEL** | Grain **phase**, **jetable**, et **aucune écriture vers `REQUIREMENTS.md` depuis `spec-phase.md`** : le fichier n'y est cité qu'une fois, en **lecture** (`spec-phase.md:118`, « based only on what ROADMAP.md and REQUIREMENTS.md say »). *Portée de l'affirmation* : le reste de gsd-core y écrit bien — `new-milestone.md:475` le **génère de zéro**, `complete-milestone.md:118` en parse la traçabilité — mais **aucun chemin ne remonte une spec de phase vers le ledger**. Et `gsd-spec-phase` est **jamais utilisé ici** : `find .planning/phases -name '*SPEC*'` → **0** sur **17 phases exécutées** (18 dossiers, dont celui de la Phase 18, non tracké et jamais exécuté). |
| 4 | **Grammaire delta ADDED/MODIFIED/REMOVED/RENAMED** | Rien d'outillé. Pratiqué **en prose** : `.planning/PROJECT.md:84` « D2 … ✗ Renversée (v2.33.0) » ; `.planning/REQUIREMENTS.md` (tail) « VERB-02 … caduc depuis v2.33.0 » | **NUL (outillé) / PARTIEL (manuel)** | La sémantique de révision est déjà pratiquée. Manque uniquement la **parsabilité machine** — sans valeur si aucun parseur ne la consomme. |
| 5 | **Grammaire `#### Scenario:` Given/When/Then** | Aucune. Dans tout gsd-core, GWT n'apparaît que dans deux fichiers : `/Users/samuel/.claude/gsd-core/workflows/spike.md` (9 lignes — l. 73, 85, 153, 156 = **mentions** de la formule à employer ; l. 158-160, 292, 301 = **exemples** de questions de spike) et `workflows/help/modes/full.md:341` (texte d'aide). **Aucune ne porte une exigence.** | **NUL** | Fonction équivalente déjà assurée par `Acceptance:` du template `spec.md`. Gain net = comparabilité, pas capacité neuve. |
| 6 | **Merge accumulatif à la clôture** | `gsd-complete-milestone` (archive puis **supprime**) ; **`gsd-ingest-docs --mode merge`** + `/Users/samuel/.claude/gsd-core/references/doc-conflict-engine.md` (artefact **gsd-core**, pas de ce repo) + agents `gsd-doc-classifier` / `gsd-doc-synthesizer` (précédence `ADR > SPEC > PRD > DOC`, gate BLOCKER, rapport `.planning/INGEST-CONFLICTS.md`) | **PARTIEL** | **Le moteur de merge d'exigences avec détection de contradiction existe déjà et est déjà câblé ici** (Phase 13, `BRDG-01`, `.planning/REQUIREMENTS.md:168`). Il est orienté ingestion ponctuelle, pas clôture récurrente. Le réimplémenter violerait l'Iron Law 2 de `/Users/samuel/Documents/dev/vibeflow-os/plugin/conductor/AGENT.md:114` (« **Router, jamais réimplémenter.** »). |
| 7 | **Archive du delta consommé** | `/Users/samuel/Documents/dev/vibeflow-os/.planning/milestones/` (4 fichiers : 2 `*-ROADMAP.md` + 2 `*-REQUIREMENTS.md`) + `.planning/MILESTONES.md` (**7** entrées de jalon marquées closes, `grep -c "^## " ` → 7) | **TOTAL** | Rien à construire — et **à corriger** : sur 7 jalons clos, **2 seulement** ont une archive d'exigences ; et ces archives sont des **supersets emboîtés**, pas des instantanés disjoints (`install-ux-v1.0-REQUIREMENTS.md` contient les 6 préfixes de `vfdo-v1.0-REQUIREMENTS.md` **plus** 5 autres), sans en-tête d'archive alors que `complete-milestone.md:450` en promet un, et avec un **titre erroné** (les 9 premières lignes de l'archive `install-ux` sont celles de l'archive `vfdo`). `ROUT-01` est donc en **3 copies indiscernables**, cf. ci-dessous. |
| 8 | **Ancrage capability overlay `.gsd/capabilities/` @ `ship:post`** | Mécanisme réel de gsd-core 1.8.0 : `/Users/samuel/.claude/gsd-core/bin/lib/capability-loader.cjs:12-13`, `POINT_ORDER` (`capability-validator.cjs:28-41`, 12 points), dispatch `/Users/samuel/.claude/gsd-core/workflows/ship.md:458` | **NUL (place libre)** | `/Users/samuel/Documents/dev/vibeflow-os/.gsd` **n'existe pas**. Faisabilité confirmée, mais l'ancrage est **inopérant sur ce repo** — voir §5. |
| 9 | **Gate de cohérence spec ↔ code** | `/Users/samuel/Documents/dev/vibeflow-os/plugin/dev-orchestrator/scripts/check-doc-drift.sh` (**153 l.**, Phase 17) | **NUL sur le fond / PARTIEL sur le déclencheur** | Son propre en-tête, **l. 4-6** : « **Ce script ne dit JAMAIS que la doc est fausse ou périmée — seulement qu'elle N'A PAS BOUGÉ depuis N commits de code.** » Compteur de commits, seuil 20, périmètre `docs/` + `README*` **racine** → **`.planning/` hors champ**. Ce n'est pas un concurrent — et son refus explicite de conclure au « périmé » depuis un « n'a pas bougé » est une **contrainte de conception** reprise au §7.2. |
| 10 | **Le mot « capability » comme clé d'indexation** | `/Users/samuel/Documents/dev/vibeflow-os/plugin/conductor/skills/vf-new-lab/references/capability-manifest.md:11` : « **Une capacité = un skill à créer.** » Sortie `docs/CAPABILITY_MANIFEST.md`, entrées `### CAP-01 — …` | **COLLISION** | Deux sens de « capability », deux `CAP-xx`, dans un repo qui a `docs/ADR.md:770` (ADR-057, frontières entre briques) et `plugin/conductor/scripts/check-overlaps.sh` **précisément pour interdire ça**. |

**Le double état existe déjà, sans la Phase 18** — `grep -rn "ROUT-01" .planning/` →
le texte intégral de l'exigence est présent dans **3 fichiers**, tous à la ligne 10 :
`/Users/samuel/Documents/dev/vibeflow-os/.planning/REQUIREMENTS.md:10`,
`/Users/samuel/Documents/dev/vibeflow-os/.planning/milestones/vfdo-v1.0-REQUIREMENTS.md:10`,
`/Users/samuel/Documents/dev/vibeflow-os/.planning/milestones/install-ux-v1.0-REQUIREMENTS.md:10`.

Et ce ne sont **pas** trois strates historiques distinctes : aucun des deux fichiers d'archive ne
porte d'en-tête signalant qu'il est mort, l'archive du jalon 2 est un **superset** de celle du
jalon 1, et elle porte le **titre du jalon 1**. Trois fichiers, même texte, aucun marqué
non-autoritatif → **trois candidats indiscernables à la vérité**, pas un archivage sain.

**JUGEMENT** — Le Goal Phase 18 dit « zéro double état » mais **ne nomme aucun fichier à retirer**.
Introduire `.planning/specs/<capability>/spec.md` par-dessus les trois copies existantes produit
mécaniquement une **quatrième**. Par la règle de décision du mandat (« un ledger qui duplique
STATE/ROADMAP/REQUIREMENTS = double état = NO-GO »), la Phase 18 telle qu'écrite est un NO-GO
mécanique, indépendamment de tout le reste. La condition de sortie serait de désigner explicitement
ce que `.planning/specs/` **remplace** — ce que fait la variante réduite du §7, en ne créant rien.

---

## 5. Vérification du point d'ancrage technique

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  VERDICT D'ANCRAGE :  EXISTE MAIS INSTABLE                                   ║
║  (et, sur CE repo précisément : réel mais inopérant)                         ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

**FAITS SOURCÉS — ce qui existe vraiment, rien n'est fabriqué**

- `@opengsd/gsd-core` installé = **1.8.0** (`/Users/samuel/.claude/gsd-core/VERSION`), publié
  2026-07-22 (6 jours avant la sonde).
- Le sous-système de capabilities est **complet** : 13 modules `capability-*.cjs` (**792 Ko**) sous
  `/Users/samuel/.claude/gsd-core/bin/lib/`. `capability-loader.cjs:12-13` lit bien
  `$GSD_HOME/.gsd/capabilities/<id>/capability.json` (global) et
  `<projectRoot>/.gsd/capabilities/<id>/capability.json` (projet).
- `ship:post` est le **12ᵉ et dernier** point de `POINT_ORDER`
  (`/Users/samuel/.claude/gsd-core/bin/lib/capability-validator.cjs:28-41` — ouverture l. 28,
  `'discuss:pre'` l. 29, `'ship:post'` l. 40, fermeture l. 41), dispatché par
  `/Users/samuel/.claude/gsd-core/workflows/ship.md:458`.
- **ADR-1244 est authentique** : `https://github.com/open-gsd/gsd-core/blob/next/docs/adr/1244-capability-ecosystem.md`,
  **Status: Accepted — ratifié 2026-07-17**, target release 1.6.0. Son **D2** (« Runtime Capability
  Registry overlay… first-party ∪ installed overlay… `~/.gsd/capabilities/<id>/` ;
  `.gsd/capabilities/<id>/` ») **dit exactement ce que la ROADMAP lui fait dire. Aucune
  fabrication.** Seul raccourci de citation : `ship:post` relève du contrat de boucle
  (`loop-host-contract`), pas de D2 stricto sensu — nuance de sourcing, pas erreur de fond.
- `.planning/specs/` est **libre** : `grep -rn "\.planning/specs" ~/.claude/gsd-core/` → 0 résultat ;
  `/Users/samuel/Documents/dev/vibeflow-os/.planning/specs` n'existe pas.
- Patron de référence disponible : `mempalace` (`capability-registry.cjs:1744`) + agent
  `/Users/samuel/.claude/agents/gsd-mempalace-curator.md` (**48 lignes**).

**FAITS SOURCÉS — les six preuves d'instabilité**

**(a) `ship:post` ne fire que dans `/gsd-ship`, chemin que ce repo n'emprunte pas.**
`/Users/samuel/.claude/gsd-core/workflows/ship.md` en-tête l. 3 : `points: ship:pre, ship:post`. Le
workflow exige préflight + remote + `gh` + **création de PR**. Le non-usage repose sur **trois
mesures convergentes**, pas sur une seule :

1. `grep -c "gsd-ship" /Users/samuel/Documents/dev/vibeflow-os/.planning/STATE.md` → **0** ;
2. les **9** occurrences de `gsd-ship` sous `.planning/` (hors le présent STUDY.md) sont **toutes**
   dans `.planning/phases/01-dev-orchestrator/` (`01-03-PLAN.md:82,86,98,145`,
   `01-04-PLAN.md:107,162`, `01-04-SUMMARY.md:47,85`, `01-05-PLAN.md:125`) et **toutes** des cibles
   de table de routage ou des greps de gate — **aucune n'est une trace d'exécution** ;
3. le chemin de livraison réel est **documenté ailleurs** : le `CLAUDE.md` de ce repo prescrit
   `git tag -a vX.Y.Z` + `gh release create --verify-tag` + `bash scripts/check-release-tag.sh`,
   sans jamais mentionner `/gsd-ship`.

La skill est bien routée (`plugin/dev-orchestrator/AGENT.md:78`) mais ce projet livre par un autre
chemin, écrit et outillé. **Un ledger accroché à `ship:post` ne se mettrait jamais à jour sur ce
repo.**

**(b) `ship:post` fire APRÈS la création de la PR.** Le step `ship_post_capability_dispatch` est
l'avant-dernier, après push de branche → création PR → mise à jour STATE.md → commit ship-note. Tout
fichier de specs écrit par le hook arrive **hors PR**, sauf à ajouter un commit après ouverture.

**(c) Le scope projet est gaté par un `bundleContentHash`.** `capability-loader.cjs:618,641` :
`contentHash: consentMod.bundleContentHash(capDir)` — sinon
`warnings.push({ kind: 'unconsented', … }); continue;`. **Toute édition du bundle** (manifeste,
fragment, script) change le hash → la capability redevient **inactive silencieusement** jusqu'à
re-consentement, **sur chaque machine et chaque clone**. Le scope global (`~/.gsd/capabilities/`)
y échappe.

**(d) `onError: skip` → échec silencieux.** `ship.md:458` : « All `ship:post` hooks are post-ship and
additive (`onError: skip`); a failure here never affects the already-created PR. » Un merge de spec
qui échoue **passe inaperçu**.

**(e) Zéro capability tierce publiée au monde.** `docs/registries/capabilities.json` (upstream) =
`[]`. Les **38** capabilities listées par
`node ~/.claude/gsd-core/bin/gsd-tools.cjs capability list --json` sont **toutes `first-party`**.
`~/.gsd/capabilities/` n'existe pas ; `/Users/samuel/Documents/dev/vibeflow-os/.gsd` n'existe pas.
**`mempalace` est first-party, compilée dans `capability-registry.cjs` — ce n'est pas une
implémentation de référence du chemin overlay tiers.** VibeFlow serait le **premier consommateur
tiers au monde** de ce contrat.

**(f) Cinq correctifs « installé mais inerte » dans la 1.8.0, publiée il y a 6 jours.** CHANGELOG
upstream : `#1938` (capabilities « silently discarded »), `#2054` (skills « never reached the runtime
surface »), `#2340` (`installed: true, surfaced: true, active: true` et **pourtant jamais sur
disque**), `#2362`/`#2434` (même bug non couvert pour OpenCode/Kilo), `#2009`/`#2075` (une capability
tierce en échec **bloquait tous les `ship:pre` et `verify:post` du projet**). L'epic de durcissement
**#1900 est encore OPEN**.

**Contraintes de nommage relevées** (à noter même en NO-GO) : `id` interdit de préfixe `gsd-` /
`gsd-core-` / `anthropic-` ; un `skills[]` déclaré est résolu sous `<configDir>/skills/gsd-<stem>/`
— layout documenté en clair à `capability-state.cjs:220` (« gsd skills live as
`configDir/skills/gsd-STEM/SKILL.md` ») et **appliqué en code** l. **248-251**
(`if (!entry.name.startsWith('gsd-')) continue;` puis `const stem = entry.name.slice(4);`).
**Collision frontale avec la doctrine `vf-*`**, contournable par `skills: []` + `agents: [...]`.

**JUGEMENT** — La faisabilité technique est **acquise** et l'honnêteté impose de le dire : rien dans
la ROADMAP n'est inventé. Mais l'ancrage déclaré (`ship:post`) est **inopérant sur ce repo** (a),
livrerait le ledger **hors PR** (b), échouerait **en silence** (d), et exposerait VibeFlow au rôle de
**cobaye d'un contrat corrigé cinq fois en une semaine** (e, f). Ce n'est pas un obstacle
insurmontable — `verify:post` serait le point correct, le scope global évite (c) — mais c'est un
coût de pionnier assumé pour une brique dont §4 montre qu'elle n'a pas de valeur nette.

---

## 6. Coût d'implémentation estimé

### 6.1 Briques à poser — FAITS SOURCÉS pour les ordres de grandeur

| Brique | Ordre de grandeur | Point d'appui du chiffrage |
|---|---|---|
| **Skill de spec-sync** (`SKILL.md` + références) | **400-600 lignes** | Le template équivalent d'OpenSpec, `src/core/templates/workflows/sync-specs.ts`, pèse **449 lignes** — et il ne contient **aucune** des 16 gardes du §3.2 : il ne fait que *décrire* le merge à l'agent. |
| **Manifeste capability** + fragments | 60-150 lignes JSON + prose | Patron `mempalace` : 5 `steps`, `contributions` avec fragments inline (le seul fragment `discuss:pre` ≈ 3 500 caractères), 9 clés de config. |
| **Agent curateur** | ≤ 250 lignes (plafond ADR-029) | `gsd-mempalace-curator.md` = **48 lignes**, mais il ne fait qu'appeler des skills ; un curateur de specs a besoin de `Write`/`Edit` et d'une doctrine de merge. |
| **Parseur + gate de la grammaire delta** | **300-500 lignes bash** (ou renoncement) | Équivalents OpenSpec : `requirement-blocks.ts` 323 l. + `spec-structure.ts` 82 l. = 405 l. **TypeScript**. En bash, davantage. |
| **Doc** (README module, CHANGELOG, référence doctrine, 2 README racine) | 150-250 lignes | Convention du repo : `plugin/conductor/CHANGELOG.md` = 25,5 K. |
| **Tests** | 150-300 lignes | Convention : **10** fichiers de test sous `/Users/samuel/Documents/dev/vibeflow-os/plugin/conductor/scripts/tests/`. |
| **Total** | **≈ 1 300 - 2 000 lignes de surface neuve** | |

### 6.2 Impact ADR-029 — FAIT + JUGEMENT

**FAIT** : `docs/ADR.md:35` — « ADR-029 | Charte densité : agents ≤ 250 lignes, skills ≤ 500,
bootstrap ≤ 2 000 tokens ». Le `sync-specs.ts` d'OpenSpec pèse **449 lignes sans aucune garde**.

**JUGEMENT** : un skill VibeFlow qui porterait les mêmes règles de merge **plus** la grammaire delta,
**plus** la doctrine locale (nommage, collision « capability », interdiction de réimplémenter),
consommerait **la quasi-totalité du budget de 500 lignes avant d'avoir ajouté le moindre garde-fou**.
Soit on déporte en `references/` (et l'ADR-029 est respectée en lettre mais pas en esprit), soit on
livre un skill dense et fragile. Aucune des deux issues n'est bonne.

### 6.3 Points de maintenance ajoutés

**JUGEMENT.** La Phase 18 complète ajoute **cinq objets à maintenir en permanence** : (1) un
manifeste pinné sur `engines.gsd` — donc à re-tester à chaque montée de gsd-core, avec le
`bundleContentHash` à re-consentir à chaque édition en scope projet ; (2) un agent curateur soumis à
`check-agents.sh` (ADR-044) ; (3) un skill soumis à ADR-029 et à `check-overlaps.sh` (ADR-057, cf.
collision #10 du §4) ; (4) un parseur bash de la grammaire delta, ou l'aveu que la grammaire est
décorative ; (5) le ledger lui-même, `N` fichiers `.planning/specs/<capability>/spec.md`, qui doivent
rester vrais.

### 6.4 Risque de drift silencieux — FAITS + JUGEMENT

**FAITS — le socle mécanique, en trois faits indépendants.** C'est lui qui neutralise la riposte
automatiste (« la discipline manuelle échoue, c'est justement l'argument POUR ancrer le merge à
`ship:post` ») :

1. **`ship:post` ne se déclencherait pas** sur ce repo — `/gsd-ship` n'est pas son chemin de release
   (§5-a, trois mesures convergentes) ;
2. **s'il se déclenchait, son échec serait muet** — `onError: skip`, verbatim dans
   `/Users/samuel/.claude/gsd-core/workflows/ship.md:458` (§5-d) ;
3. **il se désarmerait à la première édition du bundle** — gate `bundleContentHash`
   (`capability-loader.cjs:618,641`), silencieusement, sur chaque machine et chaque clone (§5-c).

Une automatisation qui ne se déclenche pas, échoue en silence et se désarme à la première édition
n'est pas une réponse au défaut de discipline.

**FAITS — l'état des registres, en distinguant deux constats de nature différente.** Le tableau
précédent de cette étude confondait « jamais allumé » et « laissé dériver ». Séparés :

*Registres adoptés, en dérive réelle (2)* :

| Registre | Constat mesuré | Pourquoi c'est une dérive |
|---|---|---|
| `.planning/codebase/ARCHITECTURE.md:8` | annonce `v2.36.1` · `VERSION` = `v2.42.0` → **6 mineures d'écart** | le doc porte `<!-- refreshed: 2026-07-26 -->` : **rafraîchi 2 jours avant la sonde et laissé faux** |
| `.planning/phases/*/*VERIFICATION*.md` | **5** sur **17** phases exécutées | `"verifier": true` dans `.planning/config.json` → la fonction est **adoptée et sous-tenue** |

*Options jamais activées (5)* — elles ne mesurent pas une négligence :

| Registre absent | Cause mesurée |
|---|---|
| `.planning/phases/*/*SPEC*.md` — **0** | `gsd-spec-phase` est un workflow **opt-in** ; aucun gate ne l'exige |
| `.planning/**/*LEARNINGS*` — **0** | `gsd-extract-learnings` est **opt-in** |
| `.planning/graphs/` | **aucune clé `graphify`** dans `.planning/config.json` (fichier lu intégralement) |
| `.planning/intel/` | **aucune clé `intel`** dans `.planning/config.json` — **absent ≠ désactivé** |
| `docs/ARCHITECTURE.md` | `gsd-docs-update` **jamais lancé** ici |

**JUGEMENT** — Ce n'est **pas** l'argument le plus lourd contre le GO : c'est le **troisième**,
derrière le quadruple registre (§4 ligne 1) et l'ancrage inopérant (§5-a). Sa force a été
surestimée, mais il ne disparaît pas — il change de nature, et se dédouble :

- **Cinq lignes mesurent une appétence faible** pour l'outillage de spec. C'est un argument
  légitime et pertinent : un repo qui, en 17 phases, n'a jamais voulu d'un `SPEC.md` ni d'un
  `LEARNINGS.md` alors que les deux étaient disponibles à coût nul ne voudra probablement pas d'un
  ledger de specs par capability. Mais c'est une preuve de **préférence**, pas de défaillance.
- **Deux lignes mesurent une discipline défaillante** — et ce sont les deux seules qui portent :
  un document d'architecture rafraîchi puis laissé mentir de 6 versions, et une couverture de
  vérification à 5/17 alors que le verifier est explicitement activé.

Ces deux-là suffisent au constat qui compte : un ledger non tenu est **pire qu'absent** — il devient
une source de vérité fausse, que les agents consommeront avec confiance. Ajouter un registre à
tenir, dans un repo qui laisse dériver celui qu'il a adopté, est un **pari sur une discipline non
démontrée**.

---

## 7. Alternative réduite — le GO

### 7.1 Le trou résiduel, réduit à l'os

**FAIT** — `/Users/samuel/.claude/gsd-core/workflows/complete-milestone.md` :

| Ligne | Contenu |
|---|---|
| 22 | « Archive requirements to `.planning/milestones/v[X.Y]-REQUIREMENTS.md` » |
| 30 | « Archives keep ROADMAP.md constant-size and **REQUIREMENTS.md milestone-scoped**. » |
| 450 | « Archiving REQUIREMENTS.md to `milestones/v[X.Y]-REQUIREMENTS.md` **with archive header** » |
| 474 | « Safety commit of archive files + updated ROADMAP.md, **then `git rm .planning/REQUIREMENTS.md`** » |
| 522 | commit de sécurité des archives, **avant** toute suppression |
| 527 | « **Remove REQUIREMENTS.md via `git rm`** (preserves history, stages deletion atomically) » |
| 530 | `git rm .planning/REQUIREMENTS.md` |
| 786 | `git commit -m "chore: remove REQUIREMENTS.md for v[X.Y] milestone"` |
| 864 | « REQUIREMENTS.md removed via `git rm` (**fresh for next milestone**, history preserved) » |

**La suppression est inconditionnelle.** Le step `reorganize_roadmap_and_delete_originals` exécute
`git rm` en séquence droite : **aucun flag, aucune gate, aucun `AskUserQuestion`, aucune branche**.
Le seul flag du workflow, `--no-archive-phases` (l. 461-464), porte sur les **dossiers de phase**,
pas sur `REQUIREMENTS.md` ; il n'existe **pas** d'option `--keep-requirements`. L'archivage précède
bien la suppression (l. 522 avant l. 530) : la donnée n'est pas perdue au sens git, mais le **ledger
vivant**, lui, disparaît à coup sûr.

**L'autre bout du cycle confirme** : `/Users/samuel/.claude/gsd-core/workflows/new-milestone.md:475`
(« **Generate REQUIREMENTS.md:** ») **régénère le fichier de zéro** au jalon suivant, avec une
section de traçabilité vide ; le seul report d'un jalon au suivant est la numérotation des IDs. Le
fichier n'est donc **jamais amendé**, il est détruit puis recréé.

**Conséquence factuelle** : dans **tout lab GSD conforme**, il n'existe, **par conception**, aucune
réponse durable à « qu'est-ce que ce système garantit aujourd'hui ? » — seulement une pile d'archives
par jalon, fragmentées et jamais fusionnées. Le `REQUIREMENTS.md` à 5 blocs de jalon de ce repo est
une **déviation manuelle**, non reproductible dans les labs clients.

**JUGEMENT** — C'est **le seul trou réel** de toute la Phase 18. Il ne se comble pas avec une
grammaire, un overlay et un skill de merge agentique : il se comble avec **un geste**.

### 7.2 La variante — description précise

> **Faire survivre les exigences à la clôture de jalon. Un fichier qui existe déjà, aucun nouveau
> registre, aucune nouvelle grammaire, aucun overlay.**

| Question | Réponse |
|---|---|
| **Quel fichier ?** | `/Users/samuel/Documents/dev/vibeflow-os/.planning/REQUIREMENTS.md` — **aucun fichier créé**. |
| **Quel skill l'écrit déjà ?** | `gsd-new-milestone` (génération, `new-milestone.md:475`), `gsd-roadmapper` (traçabilité), `gsd-complete-milestone` (archivage + parsing, `complete-milestone.md:118` « Parse REQUIREMENTS.md traceability table »), `gsd-ingest-docs --mode merge` (fusion avec détection de contradiction, précédence `ADR > SPEC > PRD > DOC`, gate BLOCKER — déjà câblé ici en Phase 13, `BRDG-01`, `.planning/REQUIREMENTS.md:168`). **Rien à réimplémenter.** |
| **Quel geste à la clôture ?** | Au lieu de `git rm .planning/REQUIREMENTS.md`, le fichier **reste** : les exigences du jalon clos y sont conservées avec leur statut final (`Livré vX.Y.Z` / `caduc depuis vX.Y.Z`), sémantique déjà pratiquée en prose (`.planning/REQUIREMENTS.md` tail : « VERB-02 … caduc depuis v2.33.0 »). L'archive `milestones/v[X.Y]-REQUIREMENTS.md` garde son rôle d'instantané. |
| **Ce que VibeFlow livre concrètement** | (1) **un gate machine** dans `/Users/samuel/Documents/dev/vibeflow-os/plugin/dev-orchestrator/scripts/` — sur le modèle exact de `check-doc-drift.sh` — qui **échoue si `.planning/MILESTONES.md` déclare un jalon clos alors que `.planning/REQUIREMENTS.md` est absent**. **Détection d'absence uniquement.** *Motif du périmètre* : le volet « ou n'a pas bougé », envisagé d'abord, est exactement l'heuristique que `check-doc-drift.sh` **se refuse explicitement** en en-tête (l. 4-6 : « ce script ne dit JAMAIS que la doc est fausse ou périmée — seulement qu'elle N'A PAS BOUGÉ ») ; un non-mouvement ne peut pas fonder l'**échec** d'un gate sans reproduire le défaut que le repo a identifié et neutralisé en Phase 17. L'absence, elle, est binaire et falsifiable. (2) **une ligne de doctrine** dans `plugin/dev-orchestrator/AGENT.md` : « à la clôture de jalon, le ledger d'exigences survit ; l'archive est un instantané, pas un déménagement ». (3) **une RFC upstream** vers `open-gsd/gsd-core` proposant de rendre la suppression optionnelle (`complete-milestone.md:530`) — **ce n'est pas un bonus, c'est la dépendance critique de la variante, et elle est hors du contrôle de VibeFlow** (voir encadré ci-dessous). |
| **Pourquoi elle échappe au double état** | Elle **n'introduit aucun objet**. Elle **réduit** même le double état existant : le rôle de `.planning/milestones/*-REQUIREMENTS.md` devient explicitement « instantané historique », donc `.planning/REQUIREMENTS.md` redevient la **seule** source vivante — les 3 copies de `ROUT-01` cessent d'être 3 candidats à la vérité. |
| **Pourquoi elle échappe au chemin fragile** | Aucun merge agent-driven de deltas Markdown : la mise à jour reste le geste déjà pratiqué (édition d'une ligne à IDs stables), avec le moteur `doc-conflict-engine` disponible pour les fusions lourdes. Aucune des 16 gardes d'OpenSpec n'est nécessaire, parce qu'aucune opération de merge structurel n'est introduite. |

#### Le risque porteur de la variante : la RFC est une dépendance, pas un bénéfice

**FAIT.** `complete-milestone.md` exécute `git rm .planning/REQUIREMENTS.md` **sans flag ni gate**
(l. 474, 527, 530, 786) et il n'existe **aucune option `--keep-requirements`** (§7.1). Le seul levier
qui rende le geste durable est donc **chez un tiers** : `open-gsd/gsd-core`. VibeFlow ne contrôle ni
l'acceptation de la RFC, ni son délai, ni sa forme.

**JUGEMENT.** C'est le point aveugle qu'il faut nommer : sans la RFC, le gate proposé **entre en
conflit direct avec le moteur**. À chaque clôture de jalon, le moteur supprimerait le fichier et le
gate échouerait — VibeFlow se retrouverait à planter un piquet contre sa propre chaîne d'outils,
c'est-à-dire dans le cas précisément interdit par l'Iron Law 2 que cette étude invoque contre la
Phase 18 (`/Users/samuel/Documents/dev/vibeflow-os/plugin/conductor/AGENT.md:114`, « **Router, jamais
réimplémenter.** »). La déviation manuelle actuelle survit précisément parce qu'aucun gate ne
l'oppose au moteur ; l'ajouter sans le levier upstream **transforme une déviation tolérée en
conflit récurrent**.

Conséquence : la RFC est reclassée en **risque de livraison** dans le chiffrage du §7.3, et elle
reçoit sa propre condition d'invalidation, **D3** au §8.

### 7.3 Chiffrage de la variante

| Livrable | Lignes | Point d'appui du chiffrage |
|---|---|---|
| Gate `check-requirements-survival.sh` | **~100-150** | `/Users/samuel/Documents/dev/vibeflow-os/plugin/dev-orchestrator/scripts/check-doc-drift.sh` = **153 l.** |
| **Tests du gate** | **~150-230** | Convention réelle mesurée sur l'analogue exact : `/Users/samuel/Documents/dev/vibeflow-os/plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh` = **232 lignes** de test pour un script de **153** → **ratio 1,5×**. Un gate de 100-150 l. demande donc 150-230 l. de tests. |
| Doctrine (`AGENT.md` + référence) | ~20-30 | |
| Doc module (README + CHANGELOG + bump `VERSION`) | ~40 | |
| RFC upstream (hors repo) | ~60 | **hors du contrôle de VibeFlow** — coût d'écriture borné, mais **délai et issue indéterminés** (§7.2, encadré) |
| **Total** | **≈ 370-470 lignes**, **1 module bumpé en patch/minor** | contre **≈ 1 300-2 000 lignes** et **5 objets à maintenir** pour la Phase 18 complète |

**JUGEMENT** — Ratio ≈ **25-30 % du coût** de la Phase 18 complète. Le poste qui décide de ce ratio
est celui des tests : le chiffrer sans mesurer la convention du repo conduit à un total flatteur
d'environ 20 %. L'analogue exact impose 1,5× le script testé, et le ratio réel est donc **d'un quart
à un tiers**, pas d'un cinquième. L'ordre de grandeur (≈ ⅓ contre ×5) tient ; le chiffre plus
optimiste, non.

**Bénéfice capté**, formulé sans pourcentage inventé — parce qu'aucune donnée ne permet d'en dériver
un : la variante comble **la totalité du seul trou structurel prouvé** (la perte inconditionnelle du
ledger à la clôture, §7.1), et **réduit** le double état existant en rendant explicite le rôle
d'instantané des archives.

**Bénéfice explicitement non capté** — et il faut le dire, parce que la variante ne peut pas prétendre
répondre au Goal : (1) la **parsabilité machine** des exigences, dont §4 lignes 4-5 montre qu'elle n'a
aucun consommateur ; (2) et surtout **l'indexation par capability**. Un `REQUIREMENTS.md` qui survit
reste **indexé par jalon** (§4 ligne 1) : il livre une pile chronologique, pas la réponse directe à
« que garantit le routage aujourd'hui ? ». Cette question exige encore aujourd'hui de réconcilier
`ROUT-01..04` (`.planning/REQUIREMENTS.md:10`, marqués Complete), `VERB-02` (`:282`, « caduc depuis
v2.33.0 ») et `.planning/PROJECT.md:84` (« D2 … ✗ Renversée (v2.33.0) ») — trois emplacements et un
renversement. La survie du fichier **ne résout pas ça**. C'est la part du besoin que le GO-réduit
laisse ouverte, et la raison pour laquelle la brique (ii) peut légitimement être rouverte
(condition **E1** du §8) plutôt que déclarée sans objet.

La RFC, enfin, n'est **pas** comptée en bénéfice : elle est la condition de viabilité du geste
central, chez un tiers (§7.2, encadré).

---

## 8. Ce qui invaliderait ce verdict

Conditions falsifiables. Chacune est vérifiable par **une commande, une observation ou une procédure
bornée dans le temps** — aucune n'est laissée à l'impression. La révision de la Phase 18 est
justifiée dès qu'une condition d'un même bloc bascule ; **chaque bloc porte sa propre conséquence**,
et le bloc E est le seul dont la bascule n'invalide rien mais **rouvre** une brique.

### Bloc A — invalide le NO-GO sur l'ancrage (brique iii)

| # | Condition | Vérification |
|---|---|---|
| A1 | `/gsd-ship` devient le chemin de release réel de ce repo | `grep -c "gsd-ship" /Users/samuel/Documents/dev/vibeflow-os/.planning/STATE.md` **> 0**, ou une entrée `ship` dans `.planning/phases/*/*-SUMMARY.md` |
| A2 | Le registre des capabilities tierces se peuple — VibeFlow n'est plus pionnier | `curl -s https://raw.githubusercontent.com/open-gsd/gsd-core/next/docs/registries/capabilities.json \| jq 'length'` **> 0** |
| A3 | L'epic de durcissement est close et le contrat stabilisé | `gh issue view 1900 --repo open-gsd/gsd-core --json state` → `CLOSED`, **et** un CHANGELOG gsd-core sans nouveau correctif « installed but inert » sur 2 releases consécutives |
| A4 | Le gate de consentement cesse de désactiver silencieusement sur édition | `grep -n "bundleContentHash" ~/.claude/gsd-core/bin/lib/capability-loader.cjs` → absent, ou remplacé par un mécanisme qui échoue bruyamment |

### Bloc B — invalide le NO-GO sur le merge agent-driven (briques i et iv)

| # | Condition | Vérification |
|---|---|---|
| B1 | OpenSpec dote `/opsx:sync` de gardes déterministes (le chemin agent cesse d'être le chemin nu) | Présence d'un appel au moteur de `specs-apply.ts` depuis `src/core/templates/workflows/sync-specs.ts` sur `main`, ou fermeture de l'issue #1387 avec livraison |
| B2 | Un retour d'expérience chiffré et indépendant, > 6 mois, documente la tenue du ledger | **Procédure bornée** (à re-lancer au **2026-10-26** au plus tard) : (1) `curl -s "https://hn.algolia.com/api/v1/search?query=openspec%20specs%20drift&tags=comment"` → un `hit` postérieur au 2026-07-28 rapportant ≥ 6 mois de tenue chiffrée (aujourd'hui : `nbHits: 0`) ; (2) `gh api repos/Fission-AI/OpenSpec/discussions --paginate` filtré sur la catégorie retours d'usage → une discussion équivalente ; (3) index `martinfowler.com/articles/exploring-gen-ai/` → une mise à jour de Böckeler chiffrant le coût de tenue. **Trois sources, une échéance : si les trois sont vides au 2026-10-26, la condition est réputée non remplie et le NO-GO tient.** |
| B3 | Un concurrent majeur adopte le ledger accumulé par capability | `github/spec-kit` retire « none is the default, and none is required » de `docs/concepts/spec-persistence.md`, **ou** Tessl Framework passe en disponibilité générale |

### Bloc C — invalide le NO-GO sur la discipline de tenue (fait 11)

| # | Condition | Vérification |
|---|---|---|
| C1 | Ce repo prouve qu'il consomme son propre outillage de spec | `find /Users/samuel/Documents/dev/vibeflow-os/.planning/phases -name '*SPEC*' \| wc -l` **≥ 3**, sur 3 phases consécutives |
| C2 | Ce repo prouve qu'il tient ses registres d'état | La version citée dans `/Users/samuel/Documents/dev/vibeflow-os/.planning/codebase/ARCHITECTURE.md:8` **égale** le contenu de `/Users/samuel/Documents/dev/vibeflow-os/VERSION` |
| C3 | La couverture de vérification remonte | `find .planning/phases -name '*VERIFICATION*' \| wc -l` **≥ 12** (aujourd'hui : **5 / 17 phases exécutées**) |

### Bloc D — rend la variante réduite du §7 caduque (donc annule aussi le GO)

| # | Condition | Vérification |
|---|---|---|
| D1 | gsd-core cesse de supprimer le ledger d'exigences à la clôture — le geste devient sans objet | `grep -n "git rm .planning/REQUIREMENTS.md" ~/.claude/gsd-core/workflows/complete-milestone.md` → **0 résultat** dans une version ≥ 1.9 |
| D3 | **La RFC upstream est refusée ou reste sans réponse à 90 jours**, soit **avant le 2026-10-26** — le gate n'a alors plus de levier et **combat le moteur au lieu de s'y intégrer** (§7.2, encadré) | État de la PR/issue déposée sur `open-gsd/gsd-core` : `closed as not planned`, ou aucun commentaire de mainteneur au 2026-10-26. **Conséquence : la variante réduite doit être intégralement ré-arbitrée** — soit renoncement au gate (doctrine seule, sans machine), soit acceptation assumée d'un gate en conflit récurrent avec `complete-milestone`. |

*(La condition anciennement numérotée D2 — résolution de la collision de vocabulaire « capability » —
a été **reclassée en E1** : sa réalisation ne rend pas la variante caduque, elle rouvre la brique (ii).
La numérotation est laissée non contiguë pour que la référence croisée reste traçable.)*

### Bloc E — invalide le NO-GO sur la brique (ii), sans toucher au GO-réduit

Ce bloc est distinct des précédents : ses conditions ne rendent **rien caduc**, elles **rouvrent** la
question du ledger indexé par capability, que le §7.3 laisse explicitement ouverte. La variante
réduite n'introduit **aucun** vocabulaire « capability » : sa validité ne dépend donc pas d'eux.

| # | Condition | Vérification |
|---|---|---|
| E1 | La collision de vocabulaire « capability » est résolue de part et d'autre | `docs/glossary.md` d'OpenSpec réintroduit « capability » comme terme canonique (aujourd'hui : **0 occurrence**, seul « **Domain.** » est défini, l. 19), **et** `/Users/samuel/Documents/dev/vibeflow-os/plugin/conductor/skills/vf-new-lab/references/capability-manifest.md:11` cesse de définir « **Une capacité = un skill à créer.** » → l'indexation par capability redevient nommable sans violer ADR-057 |
| E2 | Le besoin d'indexation par domaine devient mesurable ici | Une question du type « que garantit le routage aujourd'hui ? » exige de réconcilier ≥ 3 emplacements **plus de 2 fois** dans l'historique documenté (aujourd'hui : 1 cas relevé, `ROUT-01..04` / `VERB-02` / `PROJECT.md:84`) → le coût de la pile chronologique cesse d'être anecdotique |

---

## 9. Réponse directe aux trois volets de la question

**FAITS + JUGEMENT.**

**(a) Le repo vibeflow-os** — **Non, pas de gain net.** Le trou qu'il ressent (`REQUIREMENTS.md`
maintenu à la main) est déjà comblé chez lui par de l'artisanat qui fonctionne ; ce qui lui manque
n'est pas un ledger de plus mais la garantie que cet artisanat survive (§7). L'ancrage `ship:post`
y est inopérant, et sa panne serait muette (§5-a, §5-c, §5-d). Quant à sa capacité à tenir un
registre de plus : **deux registres adoptés y sont en dérive** (`ARCHITECTURE.md:8` faux de 6
mineures malgré un rafraîchissement 2 jours avant la sonde ; vérification à 5/17 alors que
`"verifier": true`) et **cinq options n'y ont jamais été activées** (`*SPEC*`, `*LEARNINGS*`,
`graphs/`, `intel/`, `docs/ARCHITECTURE.md`). Les cinq mesurent une **appétence faible** pour
l'outillage de spec, les deux une **discipline défaillante** — les deux inférences sont différentes
et il ne faut pas les additionner (§6.4).

**(b) L'expérience de dev quotidienne dans un lab** — **Coût > gain sur le plan complet, gain net
sur la variante.**

> **Limite méthodologique, déclarée avant l'argument** : **aucun lab installé n'a été observé.**
> Toutes les mesures du §6.4 portent sur `/Users/samuel/Documents/dev/vibeflow-os`, dont le
> `CLAUDE.md` (l. 3-4) précise qu'il est « *le repo de distribution du plugin VibeFlow, **pas un lab
> qui l'installe*** ». Le sujet mesuré est donc **atypique par construction** : il produit le
> framework, il ne le consomme pas. Ce volet est **inféré a priori**, pas mesuré, et il ne doit pas
> être lu comme aussi sourcé que (a) et (c). Ce qui le rendrait décidable : instrumenter un lab
> client réel sur ≥ 3 clôtures de jalon et mesurer le temps passé à arbitrer un merge de deltas.

Sous cette réserve : le plan complet ajoute une grammaire à respecter, un merge à arbitrer à chaque
clôture, et cinq objets à maintenir, pour une capacité que `Current` / `Target` / `Acceptance` rend
déjà (§4, ligne 5). La variante réduite, elle, supprime une perte subie sans rien demander à
l'utilisateur : le ledger cesse simplement de disparaître. L'asymétrie de charge cognitive est
qualitative et assumée comme telle, faute d'observation.

**(c) La qualité du spec-driven development** — **Le vrai gain de VibeFlow ne se joue pas là.** Aucun
des 16 garde-fous d'OpenSpec ne vérifie que le code fait ce que la spec dit (issue #381 fermée sans
livraison ; le mainteneur : « this process has to be manual unfortunately »). Un ledger vivant
améliore la cohérence **interne** des specs, jamais leur correspondance au code. Ce que le repo a
déjà livré en Phase 17 (`check-dev-bootstrap.sh`, `check-doc-drift.sh`, gates ADR-044) va, lui,
directement dans le sens de la vérification machine — c'est cette ligne-là qui produit du SDD de
qualité, pas un registre de plus.

---

## 10. Sources

**Primaires — repo `/Users/samuel/Documents/dev/vibeflow-os`**
`VERSION` · `.planning/ROADMAP.md` (Phase 18) · `.planning/STATE.md` · `.planning/REQUIREMENTS.md` ·
`.planning/PROJECT.md` · `.planning/MILESTONES.md` · `.planning/milestones/` ·
`.planning/codebase/ARCHITECTURE.md` · `.planning/config.json` · `CLAUDE.md` · `docs/ADR.md` ·
`plugin/conductor/AGENT.md` · `plugin/conductor/skills/vf-new-lab/references/capability-manifest.md` ·
`plugin/conductor/scripts/check-overlaps.sh` · `plugin/conductor/scripts/tests/` (10 fichiers) ·
`plugin/dev-orchestrator/scripts/check-doc-drift.sh` ·
`plugin/dev-orchestrator/scripts/tests/test-check-doc-drift.sh` · `plugin/dev-orchestrator/AGENT.md` ·
`.planning/phases/01-dev-orchestrator/` (occurrences `gsd-ship`)

**Primaires — moteur `/Users/samuel/.claude/gsd-core/` (1.8.0)**
`VERSION` · `workflows/complete-milestone.md` · `workflows/new-milestone.md` ·
`workflows/spec-phase.md` · `workflows/ship.md` · `workflows/spike.md` ·
`workflows/help/modes/full.md` · `bin/lib/capability-loader.cjs` ·
`bin/lib/capability-validator.cjs` · `bin/lib/capability-registry.cjs` ·
`bin/lib/capability-state.cjs` · `references/loop-hook-dispatch.md` ·
`references/doc-conflict-engine.md` · `agents/gsd-mempalace-curator.md`

**Primaires — OpenSpec** (`Fission-AI/OpenSpec`)
`README.md` · `docs/writing-specs.md` · `docs/concepts.md` · `docs/glossary.md` · `docs/cli.md` ·
`docs/agent-contract.md` · `src/core/specs-apply.ts` · `src/core/archive.ts` ·
`src/core/validation/validator.ts` · `src/core/parsers/requirement-blocks.ts` ·
`src/core/parsers/spec-structure.ts` · `src/core/templates/workflows/sync-specs.ts`

**Primaires — retours d'expérience et comparaison**
https://news.ycombinator.com/item?id=47999279 (abandon du ledger vivant) ·
https://news.ycombinator.com/item?id=47427078 (« adoptable sans le fatras ») ·
https://github.com/Fission-AI/OpenSpec/discussions/169 (réconciliation manuelle) ·
https://github.com/Fission-AI/OpenSpec/discussions/1159 (bake-off) ·
https://github.com/Fission-AI/OpenSpec/issues/381 (pas de vérification impl↔spec) ·
https://github.com/open-gsd/gsd-core/blob/next/docs/adr/1244-capability-ecosystem.md (ADR-1244 D2) ·
https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html (taxonomie Böckeler) ·
https://github.com/github/spec-kit/blob/main/docs/concepts/spec-persistence.md ·
`https://hn.algolia.com/api/v1/search?query=openspec%20specs%20drift&tags=comment` (corpus de
recherche de la condition B2 du §8 — `nbHits: 0` au 2026-07-28)

**Dossiers de recherche amont** (scratchpad de session, non versionnés)
`rech-openspec.md` (861 l.) · `carto-existant.md` (573 l.) · `sonde-ancrage.md` (444 l.)

**Non trouvé — l'absence est une donnée**
Aucun benchmark rigoureux et indépendant du coût de tenue d'un ledger de specs vivantes · aucun
retour d'expérience chiffré > 6 mois · aucune capability tierce publiée au monde · aucune doc Kiro
décrivant un merge de deltas dans une spec accumulée.
