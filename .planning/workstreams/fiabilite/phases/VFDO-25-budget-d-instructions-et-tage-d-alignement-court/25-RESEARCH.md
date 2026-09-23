# Phase 25 : Budget d'instructions — Recherche

**Researched:** 2026-09-15
**Domain:** Gate machine bash (comptage de texte + ratchet versionné), conducteur = `plugin/conductor/`
**Confidence:** HIGH (mécanisme et précédents) / MEDIUM (forme exacte de la « puce impérative »,
tranchée ici par mesure mais reste un choix éditorial à valider au plan)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Métrique BUDG-01 — formes normatives comptées**
- **D-01:** Une **instruction** = une ligne du **body** (hors frontmatter YAML) qui porte un
  **marqueur normatif** — liste versée au gate, re-dérivable, insensible à la casse, FR + EN :
  `JAMAIS`, `TOUJOURS`, `NE … PAS`, `DOIT`, `MUST`, `NEVER`, `ALWAYS`, `interdit`, `obligatoire`
  (liste de départ = celle de la mesure du 2026-09-14 ; le plan peut l'étendre, jamais la réduire
  sans consigner pourquoi) — **ou** une puce impérative sous un titre de règles (forme à préciser
  au plan, avec contrôle positif et négatif). Le compte est **par fichier**, publié dans la sortie
  du gate. La métrique **tokens estimés** (piste F3) est **écartée** : elle mesure la taille, pas
  l'adhérence. — **Reversibility:** costly — la définition fonde la baseline (D-02) ; la changer
  après armement invalide toutes les valeurs publiées.
- **D-02:** **Seuil = baseline par ratchet vers le bas.** Au jour 1, le seuil de chaque fichier
  vaut son **maximum mesuré sur le corpus final** du milestone (aucun rouge à l'armement) ; une
  baseline **ne peut que descendre** ; toute hausse d'un fichier au-dessus de sa baseline rougit
  une fois le gate armé. Le seuil absolu « ~150-200 instructions » de la source est écarté (le max
  mesuré aujourd'hui est 44, un tel seuil serait inerte). Le seuil par rôle est écarté aussi. —
  **Reversibility:** costly — les baselines sont un contrat publié (README, CHANGELOG) ; une
  remontée demanderait un arbitrage humain consigné.

**Portée**
- **D-03:** **Agents distribués seulement** : `plugin/*/agents/*.md` (25 au 2026-09-14) et
  `plugin/*/AGENT.md` (6), soit **31 fichiers, 3 603 lignes, 463 lignes impératives** au comptage
  brut du 2026-09-14. **Découverte non vide obligatoire** (0 fichier découvert = issue « non
  vérifiable », jamais un vert). `SKILL.md` et bootstrap : hors phase.

**Ratchet BUDG-02 — sentinelle versionnée, patron Phase 18**
- **D-04:** Le ratchet suit **le seul précédent maison** : `check-requirements-survival.sh` — un
  **fichier-sentinelle versionné** (`.planning/.instruction-budget-armed` ou nom équivalent, **lu,
  jamais écrit par le gate**). **Non armé → exit 3, rapport imprimé intégralement** (avertissement
  audible, jamais silencieux) ; **armé → bloquant** en CI. L'armement se fait **dans le même commit
  que la remédiation** (spec Windows II §7) — ici, le commit qui grave les baselines. —
  **Reversibility:** reversible — désarmer = retirer la sentinelle, geste visible en diff.

**ADR-029 — les 250 lignes deviennent machine-enforced, même gate, même ratchet**
- **D-05:** Fait d'entrée établi le 2026-09-14 : **aucun gate distribué ne mesure le plafond de
  250 lignes** — `check-agents.sh` ne compte ni lignes ni instructions, seule la suite
  `test-dev-orchestrator.sh` (T3/T5) le fait pour son propre module ; `plugin/conductor/README.md`
  attribue à tort un « budget de préchargement » à `check-agents.sh`. **Décision : le gate budget
  publie lignes ET instructions par fichier ; le plafond de lignes (250, agents) est armé par la
  même sentinelle** ; le README conductor est **corrigé** dans la phase. Une seule brique, deux
  métriques, trois issues chacune.

**Séquencement avec la Phase 34**
- **D-06:** Cadrage rendu maintenant, planification possible dès maintenant ; la **tâche de
  calibration** (mesure du corpus, gravure des baselines, armement) **n'est exécutable qu'après la
  clôture de la Phase 34** — le seul ajout d'agents possible en 34 est `web-test-team` sur run
  mobile vert. **Mise à jour du 2026-09-15 (arbitrage Samuel, AskUserQuestion session principale) :
  la Phase 34 a clôturé le 2026-09-15 sans créer aucun agent (voir `## Ce qui attend la Phase 40`
  ci-dessous : la dépendance de calibration s'est reportée sur la Phase 40, qui elle modifie le
  corpus).** Le plan porte cette dépendance comme un **checkpoint bloquant**, pas comme une note.
  Tout ce qui précède la calibration (script, suite, trois issues, mutation rouge, câblage CI en
  mode non armé, README) peut s'exécuter avant. — **Reversibility:** one-way — graver les baselines
  sur un corpus qui bouge ensuite rendrait la publication fausse dès la première hausse.

**QUAL-01 (transverse, critère de chaque gate du milestone)**
- Le gate naît avec ses **trois issues** — PASS / FAIL / **imparsable BRUYANT** (un frontmatter
  YAML cassé ou un body illisible = « non vérifiable », jamais compté vert) — et sa **mutation
  rouge prouvée** (patron Phase 39 : mutant vérifié muté par `cmp`, rouge sur l'original et vert à
  tort sur le mutant).

### Claude's Discretion
- Nom et emplacement du script (`plugin/conductor/scripts/check-instruction-budget.sh` est la
  lecture naturelle), forme du fichier de baselines (versionné, lisible en diff, une ligne par
  fichier).
- Forme exacte de la « puce impérative sous un titre de règles » (D-01) et contrôles associés.
- Rendu de la sortie (tableau fichier | lignes | instructions | baseline | verdict).
- Étape CI : pattern d'étape simple avec le commentaire « POURQUOI CE GATE EXISTE », découverte non
  vide assertée, exit 2/3 traités selon l'état armé.

### Deferred Ideas (OUT OF SCOPE)
- **Budget des `SKILL.md` (≤ 500 L) et du bootstrap (≤ 2000 tokens)** — même absence d'enforcement
  machine, hors périmètre BUDG-01 ; dette à inscrire au BACKLOG.
- **Métrique en tokens estimés** (F3) — écartée, pas différée.
- **BUDG-03 / G2 étage d'alignement court** — Out of Scope du ledger, inchangé.
- **Remédiation des fichiers les plus chargés** (`vf-dev-manager.md`) — geste ultérieur, par lot.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BUDG-01 | Le budget d'instructions par fichier d'agent distribué est mesuré et publié (métrique tranchée au cadrage de la phase) | Corpus mesuré ci-dessous (31 fichiers) ; définition D-01 vérifiée sur disque (comptage marqueurs FR/EN) ; candidats pour la forme « puce sous titre de règles » mesurés avec contrôle positif/négatif ; idiome de comptage portable (`awk 'END{print NR}'`, frontmatter awk 2-délimiteurs) repris de `check-file-size.sh`/`check-divergence.sh` |
| BUDG-02 | Le gate est en ratchet — avertit d'abord, bloque au merge, jamais rouge des semaines | Mécanisme de sentinelle cloné de `check-requirements-survival.sh` (lu jamais écrit, exit 3 non armé) ; doctrine d'armement au commit de remédiation citée depuis la spec Windows II §7 ; proposition de format de baseline (TSV, `.planning/instruction-budget-baselines.tsv`) et de règle de comparaison |
| QUAL-01 (transverse) | Tout nouveau gate du milestone naît avec ses trois issues (PASS / FAIL / imparsable BRUYANT) et sa mutation rouge prouvée | Patron `check-divergence.sh` + `test-check-divergence.sh` (codes énumérés, mutants `cmp`) repris comme squelette ; section Validation Architecture ci-dessous détaille les trois issues et deux mutants proposés |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Racine `~/Documents/dev`** : dossier parent, ne rien créer ici — sans objet pour cette phase
  (tout le travail vit dans `vibeflow-os/`).
- **`vibeflow-os/CLAUDE.md` (racine du dépôt)** : toute release (bump de `VERSION`) DOIT créer et
  pousser un tag annoté. Sans objet pour la mécanique du gate lui-même (aucune release n'est livrée
  par cette phase), mais s'applique si/quand le module `conductor` est bumpé et livré.
  - Densité (ADR-029) : agents ≤ 250 lignes, skills ≤ 500, bootstrap ≤ 2000 tokens — **directement
    l'objet de la phase** (D-05 rend ce plafond machine-enforced pour la première fois).
  - Jamais de fix sans validation humaine (ADR-031) — le gate signale, il ne corrige jamais un
    fichier trop chargé lui-même.
  - Agents natifs machine-enforced (ADR-044) : tout agent posé passe `check-agents.sh` — sans
    objet ici (le gate budget n'ajoute aucun agent).
  - Commits en français, cohérents avec l'historique.
  - Traçabilité des arbitrages : un commit qui invoque une décision humaine nomme le canal et la
    date (« arbitrage Samuel, AskUserQuestion session principale, 2026-09-14 » pour les cinq
    arbitrages D-01..D-05, « …2026-09-15 » pour D-06/le séquencement).

## Summary

La Phase 25 livre un **gate machine unique** (`check-instruction-budget.sh`, siège naturel
`plugin/conductor/scripts/`) qui mesure, pour les **31 fichiers d'agents distribués**
(`plugin/*/agents/*.md` + `plugin/*/AGENT.md`), **deux métriques par fichier** — le nombre total de
lignes (frontmatter inclus, précédent T3/T5) et le nombre de « lignes-instruction » du body (hors
frontmatter, marqueurs normatifs FR/EN + puces impératives sous titre de règles) — et les compare à
une **baseline versionnée qui ne peut que descendre**. Le gate est **désarmé** tant qu'un
fichier-sentinelle (`.planning/.instruction-budget-armed`, clone exact du mécanisme de
`check-requirements-survival.sh`) n'existe pas : en son absence, il imprime le rapport complet et
sort en 3 (avertissement audible, jamais silencieux, jamais bloquant) ; une fois la sentinelle
posée, tout dépassement de baseline rougit (exit 1) et bloque le job CI `gates`.

La mesure du corpus d'aujourd'hui (31 fichiers, 3 603 lignes totales, 433 instructions body-only
selon la lecture stricte de D-01 — voir écart avec le chiffre « 463 » cité en CONTEXT.md,
documenté et expliqué ci-dessous) confirme les ordres de grandeur cités au cadrage et fournit au
plan un jeu de contrôles positifs/négatifs pour la forme alternative « puce impérative sous titre
de règles » : elle ajoute **+68 lignes-instruction supplémentaires** (16 % du total body-only) sur
12 des 31 fichiers si le plan l'adopte, tout en soustrayant potentiellement **25 faux positifs**
(titres de section contenant le mot « obligatoire », comme `## Retour (bloc typé obligatoire)`) si
le plan choisit de les exclure explicitement. Aucun des 31 fichiers n'a aujourd'hui de frontmatter
cassé — le cas « imparsable BRUYANT » n'a pas d'exemple réel dans le corpus et doit être une
fixture synthétique dans la suite de tests, au même patron que `check-divergence.sh`.

La **calibration réelle** (mesure figée, gravure des baselines, armement de la sentinelle) reste un
**checkpoint bloquant** : au moment de cette recherche (2026-09-15), la Phase 34 — qui bloquait la
calibration selon D-06 — **a clôturé le même jour sans créer aucun agent**, mais la Phase 40
(renommage `vibeflow-dev` → `vibeflow-head`, rewrite du body de `plugin/dev-orchestrator/AGENT.md`,
+20 fichiers touchés par le renommage sans alias) est désormais la dépendance réelle qui rend toute
calibration prématurée avant sa clôture — voir `## Ce qui attend la Phase 40`.

**Primary recommendation:** livrer dans une seule PR tout ce qui ne dépend pas du corpus figé
(script à deux métriques, suite de tests à trois issues + deux mutants `cmp`, câblage CI en mode
non-armé, correction du README conductor sur `check-agents.sh`, note ADR-029) ; traiter la
calibration comme un plan/checkpoint séparé, explicitement bloqué sur la clôture de la Phase 40,
jamais exécuté par anticipation.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Comptage lignes/instructions par fichier d'agent | Outillage local (script bash, `plugin/conductor/scripts/`) | — | Lecture pure de fichiers versionnés sur disque, aucune dépendance réseau/service — le siège naturel est le même dossier que `check-agents.sh` (densité ADR-029 déjà portée là) |
| Comparaison à la baseline (ratchet) | Outillage local (même script) | Fichier de données versionné (`.planning/`) | La logique de comparaison est du code ; les valeurs de baseline sont des données qui doivent voyager indépendamment du code (calibrées après la Phase 40, pas au même commit que le script) |
| Armement du ratchet | Fichier-sentinelle versionné (`.planning/`) | — | Précédent unique du dépôt : `.planning/.requirements-survival-armed`, lu jamais écrit par le gate, écrit à la main par qui arme |
| Exécution CI (bloquant/avertissement) | CI / Backend | — | Job `gates` de `.github/workflows/ci.yml`, `runs-on: ubuntu-latest` — aucun composant navigateur/frontend impliqué |
| Publication du rapport | Sortie stdout/stderr du script | Catalogue `plugin/conductor/README.md` | Le rapport lui-même est éphémère (CI logs) ; le contrat de baseline publié est ce qui doit être documenté durablement |

## Corpus mesuré (2026-09-15, re-dérivé par exécution — jamais recopié du cadrage)

Commande d'énumération exacte (glob à un seul niveau, jamais `find … -path '*/agents/*.md'` qui
capture aussi `content/agents/*.blueprint.md`, les exemples `reference/`, et les agents imbriqués
de `skill-creator/skills/*/agents/` — mesuré : cette forme large rend **54 fichiers**, pas 31) :

```bash
{ for f in plugin/*/agents/*.md; do [ -f "$f" ] && echo "$f"; done
  for f in plugin/*/AGENT.md;    do [ -f "$f" ] && echo "$f"; done; } | sort
```

**31 fichiers découverts** [VERIFIED: exécution `find`/glob sur ce dépôt, 2026-09-15] — confirme
exactement le chiffre D-03 du cadrage (25 `agents/*.md` + 6 `AGENT.md`).

Comptage des lignes **totales** (frontmatter inclus, `awk 'END{print NR}'` — robuste à l'absence de
`\n` final, idiome repris de `check-file-size.sh:45-48`, jamais `wc -l` qui sous-compte dans ce
cas) et des **instructions body-only** (frontmatter exclu par un awk à deux délimiteurs `---`,
motif D-01 `JAMAIS|TOUJOURS|NE .* PAS|DOIT|MUST|NEVER|ALWAYS|interdit|obligatoire`,
`grep -ciE`) :

| Fichier | Lignes (fichier entier) | Instructions (body-only, D-01 strict) |
|---|---:|---:|
| `plugin/business-pilot-bundle/agents/quality-gate-client.md` | 91 | 11 |
| `plugin/business-pilot-bundle/agents/vf-business-commercial.md` | 97 | 19 |
| `plugin/business-pilot-bundle/agents/vf-business-delivery.md` | 90 | 16 |
| `plugin/business-pilot-bundle/agents/vf-business-finance.md` | 113 | 16 |
| `plugin/business-pilot-bundle/agents/vf-business-manager.md` | 183 | 16 |
| `plugin/conductor/AGENT.md` | 130 | 18 |
| `plugin/content-bundle/agents/content-clarity-judge.md` | 82 | 8 |
| `plugin/content-bundle/agents/vf-content-manager.md` | 151 | 11 |
| `plugin/content-bundle/agents/vf-content-repurposer.md` | 84 | 10 |
| `plugin/content-bundle/agents/vf-content-strategist.md` | 78 | 9 |
| `plugin/content-bundle/agents/vf-content-writer.md` | 83 | 11 |
| `plugin/design-orchestrator/AGENT.md` | 193 | 21 |
| `plugin/design-orchestrator/agents/vf-crafter.md` | 77 | 10 |
| `plugin/design-orchestrator/agents/vf-design-judge.md` | 85 | 8 |
| `plugin/design-orchestrator/agents/vf-design-manager.md` | 192 | 27 |
| `plugin/dev-orchestrator/AGENT.md` | 205 | 16 |
| `plugin/dev-orchestrator/agents/vf-auditer.md` | 49 | 2 |
| `plugin/dev-orchestrator/agents/vf-coder.md` | 108 | 20 |
| `plugin/dev-orchestrator/agents/vf-dev-manager.md` | **250** | **43** |
| `plugin/dev-orchestrator/agents/vf-reviewer.md` | 69 | 8 |
| `plugin/growth-bundle/agents/campaign-analyst.md` | 111 | 17 |
| `plugin/growth-bundle/agents/channel-strategist.md` | 87 | 15 |
| `plugin/growth-bundle/agents/copywriter-sequences.md` | 99 | 15 |
| `plugin/growth-bundle/agents/growth-quality-judge.md` | 84 | 9 |
| `plugin/growth-bundle/agents/vf-growth-manager.md` | 167 | 20 |
| `plugin/kpi-analyst/AGENT.md` | 96 | 10 |
| `plugin/mobile-test-team/agents/vf-app-fixer.md` | 48 | 6 |
| `plugin/mobile-test-team/agents/vf-test-orchestrator.md` | 60 | 8 |
| `plugin/mobile-test-team/agents/vf-test-runner.md` | 56 | 4 |
| `plugin/skill-creator/AGENT.md` | 135 | 20 |
| `plugin/validator/AGENT.md` | **250** | 9 |
| **TOTAL (31 fichiers)** | **3 603** | **433** |

[VERIFIED: exécution locale des commandes `awk`/`grep` ci-dessus sur `vibeflow-os` HEAD au
2026-09-15 — sortie complète disponible dans le scratchpad de session, reproductible par n'importe
qui avec les deux commandes citées]

**Deux fichiers sont déjà au plafond ADR-029 (250/250 lignes) aujourd'hui** : `vf-dev-manager.md`
(43 instructions) et `plugin/validator/AGENT.md` (9 instructions, pas mesuré au cadrage — le
cadrage ne citait que `vf-dev-manager.md`). **Le gate D-05, une fois armé, doit donc rougir sur ces
deux fichiers dès le jour 0 si un octet y est ajouté** — la baseline à 250 pour ces deux fichiers
n'a **aucune marge**, contrairement aux 29 autres.

### Écart avec le chiffre « 463 » cité en CONTEXT.md — trouvé et expliqué, pas silencieusement corrigé

Le total « **433** » ci-dessus (body-only, hors frontmatter, lecture stricte de D-01 : « une ligne
du **body** ») diffère du total « **463** » cité en CONTEXT.md D-03. Mesuré : la source de l'écart
est que le comptage du 2026-09-14 a été fait sur le **fichier entier, frontmatter INCLUS** — un
`grep -ciE` sur le fichier complet donne exactement 463 [VERIFIED: rejoué à l'identique,
`grep -ciE 'JAMAIS|TOUJOURS|NE .* PAS|DOIT|MUST|NEVER|ALWAYS|interdit|obligatoire' <chaque fichier>`
sans exclusion de frontmatter → total 463, et `vf-dev-manager.md` seul → 44, exactement le chiffre
cité]. La cause : les champs `description:` du frontmatter contiennent eux-mêmes des marqueurs
normatifs en prose libre — ex. `vf-dev-manager.md` : *« planifie **TOUJOURS** d'abord […] Ne code,
ne teste, n'audite **JAMAIS** lui-même »* dans la ligne `description:` (`vf-dev-manager.md:3`, une
seule ligne physique très longue). Ces occurrences sont comptées par `grep -ciE` sur fichier entier
(463, 44) mais **exclues** par une lecture stricte de D-01 (« une ligne du body […] hors
frontmatter YAML » — 433, 43).

**Ce que le plan doit trancher explicitement** (ce n'est pas à cette recherche de le faire à la
place du plan, D-01 étant un arbitrage verrouillé sur le texte, pas sur le chiffre) :
- Si le plan applique **D-01 à la lettre** (body hors frontmatter) → la baseline gravée à la
  calibration sera **433** au global, **43** pour `vf-dev-manager.md`, jamais 463/44. Les chiffres
  « 463 »/« 44 » cités au cadrage étaient une mesure rapide (probablement `grep` sans isoler le
  body), pas la valeur qu'implémentera un gate conforme à D-01.
- Le README/CHANGELOG qui annoncera la baseline **doit citer les chiffres réellement gravés par le
  script implémenté**, jamais recopier « 463 »/« 44 » du cadrage sans re-vérification — la baselise
  se calibre par exécution du script fini, pas par copie de ce document.

## Candidats pour la forme « puce impérative sous un titre de règles » (D-01, Claude's Discretion)

### Titres de règles trouvés dans le corpus [VERIFIED: grep exécuté sur les 31 fichiers]

```
Iron Law(s) · Garde-fous · Règles absolues · Règles de commit · Anti-patterns · Discipline …
```
23 occurrences de ces titres à travers 15 des 31 fichiers (`plugin/conductor/AGENT.md`,
`plugin/design-orchestrator/AGENT.md`, `plugin/dev-orchestrator/AGENT.md`,
`plugin/validator/AGENT.md`, `plugin/kpi-analyst/AGENT.md`, et plusieurs `agents/*.md`).

### Candidat retenu et mesuré

**Règle :** une ligne body qui (a) commence par un marqueur de liste — `- `, `* `, `❌ `, ou
`N. ` (liste numérotée) — **et** (b) se trouve, sans interruption par un autre titre `#+`, sous un
titre de section (`^#+ …`) dont le texte matche (insensible à la casse/accents)
`R[eè]gles|Garde-fous|Iron Law|Anti-pattern|Lignes rouges|Discipline` — compte comme instruction
**même si elle ne porte aucun des huit marqueurs textuels D-01**. Le scope de section se ferme au
prochain titre `#+`, quel que soit son texte (donc un titre `## Retour` ou `## Références` après
`## Anti-patterns` arrête bien le comptage — vérifié, voir contrôle négatif ci-dessous).

### Contrôle positif — bullets normatifs sans marqueur D-01, actuellement invisibles au gate

```markdown
# plugin/conductor/AGENT.md:129 (sous « ## Iron Laws »)
1. **Je configure et garde le lab ; je ne fais pas le travail métier.**
   # ⚠️ contient "ne fais pas" → matche DÉJÀ "NE .* PAS" (double-compté si on ne déduplique pas)

# plugin/conductor/AGENT.md:132 (sous « ## Iron Laws »)
4. **Tout lab embarque ses auditeurs** — pas de configuration sans filet.
   # ✅ AUCUN marqueur D-01 ("pas de" ≠ "NE...PAS") → capturé UNIQUEMENT par la règle bullet

# plugin/design-orchestrator/AGENT.md:174 (sous « ## Anti-patterns »)
- ❌ Coder en dur des couleurs alors qu'un système de design existe.
   # ✅ AUCUN marqueur D-01 → capturé UNIQUEMENT par la règle bullet
```
[VERIFIED: lu et cité verbatim depuis `plugin/conductor/AGENT.md` et
`plugin/design-orchestrator/AGENT.md`, 2026-09-15]

### Contrôle négatif — bullets sous un titre voisin qui NE doivent PAS compter

```markdown
# plugin/design-orchestrator/AGENT.md:184-186 (sous « ## Références (chemin d'install D7) »,
# titre distinct, APRÈS « ## Anti-patterns » — le scope s'est refermé)
- Workflow design quotidien : `.claude/agents/design-orchestrator-references/DESIGN-WORKFLOW.md`
- Initialisation de la DA : `.claude/agents/design-orchestrator-references/DA-INIT.md`
   # ✅ ne comptent PAS : purement descriptif (liste de chemins), sous un titre non-règles
```
[VERIFIED: lu verbatim depuis `plugin/design-orchestrator/AGENT.md:184-189`]

### Impact mesuré (exécution complète sur les 31 fichiers)

En excluant les lignes déjà comptées par les huit marqueurs D-01 (pour ne pas double-compter),
**+68 lignes-instruction supplémentaires** sur **12 des 31 fichiers** [VERIFIED: awk exécuté sur le
corpus, sortie complète en scratchpad] :

| Fichier | +bullets sans marqueur D-01 |
|---|---:|
| `plugin/business-pilot-bundle/agents/vf-business-manager.md` | +5 |
| `plugin/conductor/AGENT.md` | +7 |
| `plugin/content-bundle/agents/vf-content-manager.md` | +3 |
| `plugin/design-orchestrator/AGENT.md` | +11 |
| `plugin/design-orchestrator/agents/vf-crafter.md` | +3 |
| `plugin/design-orchestrator/agents/vf-design-manager.md` | +3 |
| `plugin/dev-orchestrator/AGENT.md` | +10 |
| `plugin/dev-orchestrator/agents/vf-dev-manager.md` | +5 |
| `plugin/growth-bundle/agents/vf-growth-manager.md` | +6 |
| `plugin/kpi-analyst/AGENT.md` | +4 |
| `plugin/mobile-test-team/agents/vf-app-fixer.md` | +3 |
| `plugin/validator/AGENT.md` | +8 |
| **TOTAL** | **+68** (16 % au-dessus du total body-only 433) |

**Conséquence directe pour la baseline** : si le plan adopte la règle bullet, `vf-dev-manager.md`
passe de 43 à **48** instructions (déjà au plafond 250 lignes) et `plugin/dev-orchestrator/AGENT.md`
de 16 à **26**. Le choix change matériellement les valeurs gravées à la calibration — c'est
pourquoi D-06 interdit de calibrer avant que le plan ait tranché ce point ET que le corpus post-
Phase 40 soit stable.

### Faux positifs identifiés dans le comptage D-01 de base (marqueurs textuels seuls)

Sur les 433 lignes comptées par les huit marqueurs D-01 seuls :
- **25 lignes sont des titres de section** (`^#+ `) contenant un marqueur dans leur libellé, pas
  une instruction — ex. `## Retour (bloc typé obligatoire)` (7 occurrences identiques à travers le
  corpus), `## Signal mission design → équipe (proposer, jamais imposer)`. [VERIFIED: grep exécuté,
  liste complète en scratchpad]
- **4 lignes sont à l'intérieur d'un bloc de code fenced** (```` ``` ````). [VERIFIED: awk à suivi
  d'état de fence exécuté sur les 31 fichiers]
- **4 lignes sont des cellules de tableau** (`| … |`).

**Recommandation (à trancher au plan, pas verrouillée ici) :** exclure les titres `^#+` du
comptage (ils ne sont jamais des instructions, quel que soit leur libellé) et stripper les blocs
fenced avant comptage (idiome awk déjà utilisé pour la détection de scope de règles ci-dessus,
réutilisable tel quel) — cela retire 25+4=29 faux positifs bruts, mais certains titres/lignes de
fence se recoupent avec les 68 ajouts de la règle bullet (un contenu ne peut pas être à la fois
titre ET bullet). Le chiffre net exact dépend de l'ordre d'application des deux filtres — **à
calculer par le script lui-même au moment du plan**, pas à figer ici en dur.

## Package Legitimacy Audit

**Sans objet.** Cette phase n'installe aucun package externe (npm/PyPI/crates) — le gate est un
script bash pur consommant uniquement les outils déjà requis par le dépôt (`awk`, `grep`, `sed`,
`git`), tous déjà couverts par le préflight existant (`plugin/installer/scripts/preflight.sh`).
Aucune ligne du tableau standard n'est applicable.

## Standard Stack

**Sans objet au sens "librairie tierce".** Le "stack" de cette phase est la discipline bash
portable déjà en vigueur dans `plugin/conductor/scripts/` — voir `## Code Examples` pour les
idiomes exacts à réutiliser (jamais de nouvelle dépendance).

## Architecture Patterns

### Diagramme de flux

```
                     ┌─────────────────────────────────────────┐
                     │  plugin/*/agents/*.md (25)               │
                     │  plugin/*/AGENT.md (6)                   │
                     │  = 31 fichiers d'agents distribués       │
                     └───────────────────┬───────────────────────┘
                                          │ découverte glob (échec si 0 → exit 2)
                                          ▼
                     ┌─────────────────────────────────────────┐
                     │ check-instruction-budget.sh              │
                     │  1. isole le body (awk 2 délimiteurs ---) │
                     │  2. compte lignes totales (awk NR)        │
                     │  3. compte instructions (grep -ciE +      │
                     │     règle bullet sous titre de règles)    │
                     └───────────────────┬───────────────────────┘
                                          │ par fichier : {path, lignes, instr}
                                          ▼
                     ┌─────────────────────────────────────────┐
                     │ .planning/instruction-budget-baselines.tsv│  ← lu, jamais écrit
                     │ (1 ligne/fichier, {path, lignes, instr})  │     par le gate lui-même
                     └───────────────────┬───────────────────────┘
                                          │ comparaison courant > baseline ?
                                          ▼
                     ┌─────────────────────────────────────────┐
                     │ .planning/.instruction-budget-armed       │  ← sentinelle, lue seule
                     │ (présence = armé)                         │
                     └───────────────────┬───────────────────────┘
                          absent ─────────┼───────── présent
                          │                            │
                          ▼                            ▼
                 exit 3, rapport imprimé      dépassement ? → exit 1 (bloquant)
                 intégralement (avertissement  sinon → exit 0
                 audible, CI ne bloque PAS)
                                          │
                                          ▼
                     ┌─────────────────────────────────────────┐
                     │ job `gates` de .github/workflows/ci.yml   │
                     │ étape dédiée, découverte non vide assertée│
                     └─────────────────────────────────────────┘
```

### Structure de fichiers recommandée

```
plugin/conductor/
├── scripts/
│   ├── check-instruction-budget.sh          # le gate (code)
│   └── tests/
│       └── test-check-instruction-budget.sh # suite (3 issues + 2 mutants cmp)
.planning/
├── instruction-budget-baselines.tsv         # données (calibrées à part, post Phase 40)
└── .instruction-budget-armed                # sentinelle (posée au commit de calibration)
```

**Rationale de séparation code/données** : le script (dans `plugin/conductor/scripts/`) est livré
dans CETTE phase, sans corpus figé. Les baselines et la sentinelle (dans `.planning/`, hors
`plugin/`) sont gravées dans un **commit séparé et ultérieur**, celui de la calibration
post-Phase-40 — c'est la même séparation que `.planning/.requirements-survival-armed` (sentinelle
hors `plugin/`, écrite à la main par qui arme, jamais par l'engine). Colocaliser baseline et
sentinelle dans `.planning/` permet au plan de livrer 100% du mécanisme maintenant sans toucher à
un seul octet de données qui deviendrait fausse dès que la Phase 40 modifie le corpus.

### Pattern 1 : sentinelle versionnée, lue jamais écrite par le gate

**What:** le gate lit `[ -f "$SENTINEL" ]` pour décider avertissement (3, jamais bloquant) vs
bloquant (1 sur dépassement). Il n'écrit **jamais** la sentinelle lui-même.

**When to use:** tout gate qui doit ratchetter sans rougir des semaines dès son introduction —
patron QUAL-01/BUDG-02 de ce milestone.

**Example (idiome exact, copié de `check-requirements-survival.sh:26-72`) :**
```bash
# Source: plugin/dev-orchestrator/scripts/check-requirements-survival.sh:26-72 (VERIFIED, lu ce jour)
ROOT="."
HOOK=0
# ... parsing args ...
SENTINEL="${VF_BUDGET_PLANNING_DIR:-$ROOT/.planning}/.instruction-budget-armed"
ARMED=0
[ -f "$SENTINEL" ] && ARMED=1

# ... mesure, comparaison à la baseline, construction de $FAIL_MSGS[] ...

if [ "${#FAIL_MSGS[@]}" -gt 0 ]; then
  for m in "${FAIL_MSGS[@]}"; do echo "[check-instruction-budget] $m" >&2; done
  if [ "$ARMED" -eq 1 ]; then
    exit 1          # bloquant : au moins une baseline dépassée, sentinelle posée
  else
    exit 3           # avertissement : dépassement détecté MAIS non armé — jamais silencieux
  fi
fi
exit 0
```

### Pattern 2 : isolation du body hors frontmatter (awk 2-délimiteurs)

**What:** isoler les lignes du body pour respecter D-01 (« hors frontmatter YAML ») sans dépendre
d'un parseur YAML (aucun n'est disponible portable dans ce dépôt).

**Example (repris et vérifié fonctionnel sur les 31 fichiers du corpus, BSD awk ET GNU awk) :**
```bash
# Source: idiome dérivé de check-divergence.sh:150-155 (frontmatter_block(), pattern similaire)
body_only() { # <file> -> body sur stdout, frontmatter exclu, lignes vides préservées
  awk '
    /^---[[:space:]]*$/ { n++; if (n==1) {infm=1; next}; if (n==2) {infm=0; next} }
    infm { next }
    { print }
  ' "$1"
}
```

### Pattern 3 : comptage de lignes robuste sans newline final

**Example (repris tel quel de `check-file-size.sh:45-48`, VERIFIED) :**
```bash
# `wc -l` sous-compte un fichier sans \n final (un fichier de 250 lignes réel en compte 249) —
# mesuré comme piège documenté dans check-file-size.sh:45-46.
n=$(awk 'END { print NR }' "$f" 2>/dev/null || echo 0)
```

### Anti-Patterns to Avoid

- **`2>/dev/null || true` sur le comptage** : fabrique un vert à vide (fail-open) — interdit ici
  comme sur tout gate du dépôt (`.planning/research/PITFALLS.md:436`, table Technical Debt).
- **Réutiliser `check-file-size.sh` tel quel** : son `is_code_file()` ne reconnaît que les
  extensions de code (`ts|tsx|js|…`), jamais `.md` — il ne verra **aucun** des 31 fichiers.
  Patron de marqueur d'exception à observer, jamais le script à invoquer directement (confirmé
  D-05/canonical_refs).
- **Compter les instructions sur le fichier entier** : contredit D-01 explicitement (« hors
  frontmatter ») et gonfle artificiellement le total de 433 à 463 par la seule prose du champ
  `description:` — voir section écart ci-dessus.
- **Écrire la sentinelle depuis le script lui-même** ou depuis un hook automatique : rejoue la
  régression #38 (armement en settings local qui ne voyage pas) — la sentinelle est **toujours**
  un geste humain versionné, jamais un effet de bord du gate.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|--------------|-----|
| Ratchet avertissement→bloquant | Un mécanisme de seuil ad hoc, une variable d'environnement custom | Sentinelle-fichier versionnée, patron `check-requirements-survival.sh` | Seul précédent maison éprouvé (Phase 18) ; toute variante réinvente le même problème (armement qui ne voyage pas — leçon #38) |
| Parsing YAML du frontmatter | Un mini-parseur YAML bash | awk à 2 délimiteurs `---` (compte les occurrences, jamais n'interprète les clés) | Le dépôt n'a aucune dépendance YAML portable ; le besoin réel est "où commence/finit le body", pas une lecture structurée du frontmatter |
| Comptage de lignes | `wc -l` nu | `awk 'END{print NR}'` | `wc -l` sous-compte silencieusement un fichier sans `\n` final — piège déjà documenté et corrigé dans `check-file-size.sh` |
| Détection de "non vérifiable" | Un `|| true` qui avale l'erreur | Contrat de 3 (ou 4) codes de sortie explicites, jamais un défaut vert | L'ennemi n°1 documenté du dépôt (`PITFALLS.md` Pitfall 9) — trois incidents du milestone précédent partagent cette racine |

**Key insight:** ce dépôt a déjà un précédent EXACT pour chacun des trois sous-problèmes de cette
phase (ratchet, comptage robuste, contrat de sortie à issues multiples) — la tâche de recherche
n'était pas de concevoir, mais de **retrouver et citer** ces précédents avec leurs numéros de
ligne, puis de les recomposer.

## Portabilité — idiomes vérifiés sur ce poste (BSD grep/awk, macOS) et attendus GNU en CI

[VERIFIED: `grep --version` → `BSD grep 2.6.0-FreeBSD` ; `awk --version` → `awk 20200816`,
`uname -a` → Darwin — mesuré sur cette machine, 2026-09-15]

D'après `.planning/codebase/CONVENTIONS.md` (§Portabilité bash, ADR-054) et
`plugin/_internal/lib/vf-portable.sh` :
- `set -uo pipefail` **sans** `-e` — préambule standard, chaque échec doit être capturé
  explicitement (jamais un abort implicite).
- **Jamais `grep -P`** — aucune occurrence dans `plugin/` ; le motif D-01 est déjà en ERE pur
  (`grep -E`), compatible BSD et GNU tel quel — confirmé par exécution réussie sur ce poste.
- **Jamais `mapfile`/`readarray`** (bash 3.2 macOS = rc 127) — le patron `while IFS= read -r` +
  process substitution est utilisé partout dans ce dépôt (`check-divergence.sh` en fait un usage
  massif) et doit l'être ici aussi pour lire la liste de fichiers découverts.
- **`[[:space:]]` plutôt que `\s`** — déjà respecté dans les regex proposées ci-dessus.
- Ce gate ne dépend d'aucun interpréteur externe (pas de `python3`, pas de `jq`) : aucun besoin de
  `vf-portable.sh` (`vf_python`/`jqx`) — c'est une simplification par rapport aux gates qui en
  dépendent (`guard-file-size.sh`, `inject-mcp-tools.sh`).
- **Codes de sortie normalisés du dépôt** (CONVENTIONS.md) : `0` conforme · `1` non conforme ·
  `2` erreur d'usage · `3` INDÉTERMINÉ. Le gate budget doit s'y conformer : `2` = découverte vide
  (0 fichier trouvé, jamais un vert) ou fichier illisible/frontmatter cassé (imparsable BRUYANT) ;
  `1` = dépassement de baseline **et** sentinelle armée ; `3` = dépassement détecté **mais** non
  armé (avertissement), ou aucun dépassement mais gate non armé (silence avec rapport imprimé selon
  le patron `--hook`) ; `0` = conforme, armé, aucun dépassement.

## Common Pitfalls

### Pitfall 1 : compter le frontmatter gonfle silencieusement le budget

**What goes wrong:** un `grep -ciE` naïf sur le fichier entier (sans isoler le body) compte les
marqueurs présents dans le champ `description:` — qui est écrit en prose libre et contient
fréquemment des mots comme "TOUJOURS"/"JAMAIS" pour orienter le routage automatique de l'agent.
Mesuré : cet écart vaut exactement **30 lignes** sur 31 fichiers (463 vs 433) et change la baseline
de `vf-dev-manager.md` de 43 à 44.

**Why it happens:** grep ne sait rien du YAML — sans filtre explicite, il traite le frontmatter
comme n'importe quelle ligne de texte.

**How to avoid:** toujours passer par `body_only()` (Pattern 2 ci-dessus) avant tout comptage
d'instructions. Le comptage de LIGNES (métrique "densité", plafond 250) reste, lui, sur le fichier
entier — précédent T3/T5 explicite, ne pas les confondre.

**Warning signs:** un total qui ne correspond pas à ce qu'un `grep -c` manuel body-only rendrait.

### Pitfall 2 : le corpus n'a aucun cas réel d'« imparsable BRUYANT » — le laisser non testé

**What goes wrong:** les 31 fichiers actuels ont tous un frontmatter bien formé (ouvrant et
fermant `---` vérifiés par exécution). Un plan qui teste uniquement contre le corpus réel du
dépôt n'exercera jamais le code path « imparsable » — c'est exactement le mode d'échec de
Pitfall 9 (`PITFALLS.md`) : un gate qui ne peut jamais rendre rouge sur ce cas n'a rien prouvé.

**Why it happens:** le corpus réel est propre ; sans discipline explicite, personne ne pense à
fabriquer une fixture cassée.

**How to avoid:** patron `test-check-divergence.sh`/`test-check-requirements-survival.sh` — chaque
cas construit sa PROPRE fixture dans un `mktemp -d`, jamais sur le dépôt réel. Fabriquer au moins
une fixture avec frontmatter tronqué (un seul `---`, jamais fermé) et une avec frontmatter absent.

### Pitfall 3 : ratchet armé prématurément sur un corpus qui va bouger (Phase 40)

**What goes wrong:** si la calibration grave des baselines avant la clôture de la Phase 40, la
baseline de `plugin/dev-orchestrator/AGENT.md` (renommé et réécrit en tant que `vibeflow-head`) et
potentiellement d'autres fichiers référençant l'ancien nom deviennent fausses dès le premier commit
de la Phase 40 — soit un dépassement forcé et immédiat (Phase 40 casse son propre premier commit
sur un gate qu'elle ne visait pas), soit un contournement (désarmer, refaire) qui rejoue la
« fenêtre rouge » que D-06 existe pour fermer.

**Why it happens:** deux phases voisines au ROADMAP, l'une (25) mesure un plafond, l'autre (40)
modifie le contenu mesuré — sans dépendance explicite, l'ordre d'exécution est un pari.

**How to avoid:** le plan de la Phase 25 pose la tâche de calibration comme un
**checkpoint:human-verify bloquant**, explicitement gaté sur "Phase 40 shippée" (pas seulement
"phases planifiées"), jamais une simple note dans le SUMMARY.

## Code Examples

### Détection de scope "titre de règles" (pour la règle bullet du D-01 alternatif)

```awk
# Source: dérivé et vérifié sur le corpus réel (2026-09-15), pattern de "under" repris de la
# logique de section-scope déjà présente ailleurs dans le dépôt (check-divergence.sh frontmatter_block)
awk '
  BEGIN { under=0 }
  /^#+[[:space:]]/ {
    if (tolower($0) ~ /r.gles|garde-fous|iron law|anti-pattern|lignes rouges|discipline/) { under=1 }
    else { under=0 }
    next
  }
  under && ($0 ~ /^[[:space:]]*[-*][[:space:]]/ || $0 ~ /^[[:space:]]*❌/ || $0 ~ /^[[:space:]]*[0-9]+\.[[:space:]]/) { print }
'
```

### Découverte non vide (F13, contrat de tout le dépôt)

```bash
# Source: patron repris de ci.yml:256-259 et check-agents.sh (contrat --strict)
found=0
for f in plugin/*/agents/*.md; do [ -f "$f" ] && found=$((found+1)); done
for f in plugin/*/AGENT.md;    do [ -f "$f" ] && found=$((found+1)); done
if [ "$found" -eq 0 ]; then
  echo "[check-instruction-budget] aucun fichier d'agent distribué découvert — non vérifiable" >&2
  exit 2
fi
```

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bash pur, zéro dépendance externe — patron `ok()/ko()` de toutes les suites du dépôt |
| Config file | aucun (chaque suite est un exécutable autonome, découvert par `*/tests/test-*.sh`) |
| Quick run command | `bash plugin/conductor/scripts/tests/test-check-instruction-budget.sh` |
| Full suite command | `find plugin scripts -type f -path '*/tests/test-*.sh' \| sort \| while IFS= read -r t; do bash "$t"; done` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BUDG-01 | Comptage lignes/instructions correct sur fixture connue (compter à la main, comparer) | unit | `bash plugin/conductor/scripts/tests/test-check-instruction-budget.sh` (cas 1-4) | ❌ Wave 0 |
| BUDG-01 | Découverte vide → exit 2, jamais un vert | unit | même suite (cas 5) | ❌ Wave 0 |
| BUDG-01 | Frontmatter cassé (fixture synthétique, jamais le dépôt réel) → imparsable BRUYANT, jamais vert | unit | même suite (cas 6-7) | ❌ Wave 0 |
| BUDG-02 | Non armé + dépassement → exit 3, rapport imprimé, CI ne bloque pas | unit | même suite (cas 8) | ❌ Wave 0 |
| BUDG-02 | Armé + dépassement → exit 1, bloquant | unit | même suite (cas 9) | ❌ Wave 0 |
| BUDG-02 | Armé + baisse de baseline → exit 0, remédiation acceptée | unit | même suite (cas 10) | ❌ Wave 0 |
| QUAL-01 | Mutation rouge #1 : neutraliser la détection d'un dépassement dans le script → fixture qui rougissait doit rester (à tort) verte sur le mutant, rouge sur l'original | mutation | même suite (bloc `== mutants ==`) | ❌ Wave 0 |
| QUAL-01 | Mutation rouge #2 : neutraliser la lecture de la sentinelle (le gate croit toujours "non armé") → une fixture armée+dépassée doit rester (à tort) verte sur le mutant | mutation | même suite (bloc `== mutants ==`) | ❌ Wave 0 |
| D-05 | `check-agents.sh` toujours 0 comptage — non-régression documentée | manual | lecture du diff `plugin/conductor/README.md` (`check-agents.sh` ne prétend plus porter le "budget de préchargement") | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `bash plugin/conductor/scripts/tests/test-check-instruction-budget.sh`
- **Per wave merge:** boucle complète de découverte (`find plugin scripts -path '*/tests/test-*.sh'`)
- **Phase gate:** suite complète verte avant `/gsd-verify-work` ; job `gates` CI vert en mode
  non-armé (le job ne doit **jamais** échouer tant que la sentinelle n'est pas posée)

### Wave 0 Gaps
- [ ] `plugin/conductor/scripts/check-instruction-budget.sh` — n'existe pas encore
- [ ] `plugin/conductor/scripts/tests/test-check-instruction-budget.sh` — n'existe pas encore,
      squelette à copier depuis `test-check-divergence.sh` (mutants `cmp`, fixtures `mktemp -d`)
      et `test-check-requirements-survival.sh` (issues multiples, cas armé/non-armé)
- [ ] `.planning/instruction-budget-baselines.tsv` — **n'existe pas, et ne doit PAS être créé par
      cette Wave** (dépend de la clôture de la Phase 40 — voir section suivante)
- [ ] `.planning/.instruction-budget-armed` — **idem, checkpoint bloquant**

## Ce qui attend la Phase 40

La Phase 40 (`.planning/phases/VFDO-40-vibeflow-head-head-of-minds-du-dev-orchestrator/40-CONTEXT.md`,
cadrée le 2026-09-15) renomme `vibeflow-dev` en **`vibeflow-head`** :

- **`plugin/dev-orchestrator/AGENT.md` est réécrit en profondeur** (`name: vibeflow-head`, nouveau
  rôle de "head of minds" : allocation d'équipe, séquencement, gouvernance de sortie, économie) —
  aujourd'hui mesuré à **205 lignes / 16 instructions** (body-only) ; ce nombre **va bouger** dès
  le premier commit de la Phase 40. C'est le fichier le plus directement affecté.
- Un **nouveau fichier** `plugin/dev-orchestrator/references/head-governance.md` est ajouté — **hors
  scope D-03** (ce n'est ni `agents/*.md` ni `AGENT.md`), donc **n'ajoute pas** de 32e fichier au
  corpus du gate budget. Bon à savoir pour ne pas s'étonner d'un compte qui ne change pas.
- **20 fichiers dans `plugin/`** sont touchés par "le renommage sans alias survivant" — le
  cadrage 40 ne détaille pas encore la liste exacte, mais toute référence croisée à
  `vibeflow-dev` dans un AUTRE agent (ex. une table de dispatch mentionnant le head) est
  susceptible de changer de longueur, potentiellement dans un fichier du corpus des 31.
- Un **nouveau script** `check-mission-exit.sh` est ajouté par la Phase 40 — hors périmètre du
  gate budget (ce n'est pas un fichier d'agent).

**Ce que le checkpoint de calibration doit faire, dans cet ordre, une fois la Phase 40 shippée :**
1. Ré-exécuter la commande d'énumération exacte de ce document (`plugin/*/agents/*.md` +
   `plugin/*/AGENT.md`) — vérifier que le compte est toujours 31 (ou documenter le nouveau compte
   si la Phase 40 en a changé le nombre — improbable vu son périmètre, mais à vérifier plutôt que
   supposer).
2. Ré-exécuter la mesure lignes/instructions **avec le script du plan** (pas avec les commandes ad
   hoc de cette recherche) — le script du plan peut avoir tranché différemment le point "règle
   bullet" et/ou "titres de section" détaillé plus haut, donc les chiffres finaux peuvent différer
   de ceux mesurés ici.
3. Graver `.planning/instruction-budget-baselines.tsv` avec ces valeurs fraîches — jamais recopier
   les tableaux de cette recherche tels quels.
4. Poser `.planning/.instruction-budget-armed` **dans le même commit**.
5. Mettre à jour `plugin/conductor/README.md`/`CHANGELOG.md` avec les valeurs réellement gravées
   (jamais "463"/"44" de ce cadrage, ni "433"/"43" de cette recherche si le script a tranché
   différemment le point "puce sous règles").

## Existant à réconcilier (D-05) — état vérifié sur disque

- **`check-agents.sh` ne compte aujourd'hui ni lignes ni instructions** [VERIFIED:
  `plugin/conductor/scripts/check-agents.sh:23-77` lu intégralement — le contrat documenté couvre
  frontmatter/`name`/`description`/`model`/`memory`/`effort`/`permissionMode`/`isolation`/
  `background`/`maxTurns`/allowlists `Agent(...)`, aucune mention de comptage de lignes ou de
  marqueurs normatifs].
- **`plugin/conductor/README.md:95-99` attribue à tort un « budget de préchargement » à
  `check-agents.sh`** [VERIFIED, citation verbatim] :
  > `check-agents.sh` — lint de conformité native des agents (ADR-044) : frontmatter, champs
  > requis, skills déclarés existants, **budget de préchargement**, `vf-internal`, et depuis la
  > Phase 16 le contenu du champ `tools:`/`disallowedTools:`…

  Cette phrase doit être corrigée dans le cadre de la phase (retirer "budget de préchargement" de
  la description de `check-agents.sh`, l'attribuer au nouveau gate).
- **Seul `test-dev-orchestrator.sh` (T3/T5) enforce aujourd'hui le plafond 250, et seulement pour
  le module `dev-orchestrator`** [VERIFIED, citations verbatim] :
  > `agent_lines=$(wc -l < "$AGENT_FILE" | tr -d ' ')` … `[ "$agent_lines" -le 250 ] || { ko "T3
  > agent : AGENT.md = ${agent_lines}L (>250)"; t3_ok=0; }` (`test-dev-orchestrator.sh:1241,1249`)
  > `if [ "$agent_lines" -le 250 ]; then ok "T5 densité agent…` (`test-dev-orchestrator.sh:1360`)
  > `a_lines=$(wc -l < "$f" | tr -d ' ')` … `[ "${a_lines:-999}" -le 250 ] ||` (`:1448-1449`, sur
  > l'équipe `vf-coder`/`vf-reviewer`/`vf-auditer`)

  **Cette enforcement mesure le fichier ENTIER (`wc -l` sans exclure le frontmatter)** — cohérent
  avec la métrique "lignes" recommandée dans cette recherche (fichier entier), donc **aucun
  conflit** de définition entre le nouveau gate et T3/T5 sur la métrique lignes.
- **Décision de coexistence (confirmée par cette recherche) :** le nouveau gate **coexiste** avec
  T3/T5 plutôt que de les remplacer — T3/T5 sont un test unitaire du module `dev-orchestrator`
  (exécuté par la suite du module, `wc -l` brut, pas de baseline ni de ratchet, pas de sentinelle),
  le nouveau gate est un gate transverse à tous les modules avec ratchet. Les deux mesurent la même
  chose (lignes totales ≤ 250) sur un sous-ensemble commun (les 5 fichiers de `dev-orchestrator`)
  sans jamais se contredire, puisque les deux utilisent la même définition "fichier entier". Les
  remplacer supprimerait un test qui a sa propre valeur de non-régression locale au module.

## Câblage CI et catalogue — état vérifié

- **Job `gates` de `.github/workflows/ci.yml:244-370`** : chaque étape porte un commentaire
  « POURQUOI CE GATE EXISTE/EST BLOQUANT », asserte une découverte non vide avant de rendre un
  verdict (`found=0` → `exit 1`, jamais un vert par absence de cible), et un `exit 2` échoue le job
  au même titre qu'un `exit 1` — aucune étape actuelle ne traite `3` comme un succès explicite
  dans ce job (le seul précédent de "exit 3 attendu et accepté" mesuré est la preuve `check-
  divergence.sh` en item 3/3, où `rc -eq 3` est l'attendu **correct**, donc si ce n'est pas 3
  → note d'échec). **Il n'existe aujourd'hui aucun précédent CI d'un step "non-armé, ne doit jamais
  faire échouer le job"** — le plan doit écrire ce traitement explicitement dans l'étape dédiée :
  ```bash
  rc=0
  out="$(bash plugin/conductor/scripts/check-instruction-budget.sh)" || rc=$?
  echo "$out"
  case "$rc" in
    0) : ;;                                    # conforme, armé (ou rien à signaler)
    3) echo "::warning::budget d'instructions non armé — avertissement, pas un blocage" ;;
    *) exit 1 ;;                                # 1 (dépassement armé) ou 2 (non vérifiable)
  esac
  ```
- **Catalogue `plugin/conductor/README.md:86-131`** : 26 scripts recensés au 2026-09-10 (compte
  re-dérivable : `find plugin/conductor/scripts -maxdepth 1 -type f -name '*.sh' | wc -l`). Le
  nouveau `check-instruction-budget.sh` porte ce compte à 27 — le plan doit re-dériver le compte
  par exécution au moment de la tâche catalogue, jamais recopier "27" à la main sans revérifier
  (la note existante signale déjà 5 scripts non catalogués avant la Phase 25, hors mandat de
  cette phase de les rattraper).
- **VERSION module `conductor`** : `v1.36.0` [VERIFIED: `plugin/conductor/VERSION`, lu ce jour] —
  un gate neuf est un **minor** (nouvelle capacité, aucun script existant modifié de façon
  incompatible) → `v1.37.0`.
- **Compteur de suites des deux README** : « **77 suites** en CI » (`README.md:140`,
  `README.fr.md:145`) [VERIFIED: `grep -c` sur les deux fichiers, texte cité verbatim]. Non
  vérifié par un gate machine (aucun script du dépôt ne compare ce chiffre à
  `find plugin scripts -path '*/tests/test-*.sh' | wc -l`, confirmé par grep négatif) — une
  nouvelle suite `test-check-instruction-budget.sh` porte ce compte à **78** ; mise à jour manuelle
  des deux README requise, mais non bloquante pour la CI (hygiène, pas un gate).
- **ADR-029 (`docs/ADR.md:52`)** : entrée d'index actuelle, citation verbatim :
  > | ADR-029 | Charte densité : agents ≤ 250 lignes, skills ≤ 500, bootstrap ≤ 2000 tokens |

  Le plan ajoute une note datée sous cette entrée (« enforcement machine à partir de la Phase 25 »)
  — l'index n'a pas de corps détaillé pour ADR-029 dans ce fichier (fait déjà noté ailleurs dans
  `docs/ADR.md` : les trous d'index sont un fait bénin, ne pas les combler par erreur — n'ajouter
  QUE la note datée, ne pas réécrire l'entrée existante).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | script + suite de tests | ✓ | 3.2.57 (macOS) / bash récent (CI ubuntu-latest) | — |
| awk | comptage de lignes/instructions | ✓ | BSD awk 20200816 (macOS) / GNU awk (CI) | — |
| grep | motifs D-01, ERE | ✓ | BSD grep 2.6.0 (macOS) / GNU grep (CI) | — |
| git | découverte de fichiers, `git ls-files` optionnel | ✓ | présent (dépôt git) | — |

**Missing dependencies with no fallback:** aucune — tous les outils requis sont déjà des
prérequis du dépôt entier (`preflight.sh`), aucun ajout.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | La métrique "lignes" (plafond 250, D-05) doit être comptée sur le **fichier entier**, frontmatter inclus (pas body-only), pour rester cohérente avec le précédent T3/T5 déjà en production | Corpus mesuré / Anti-Patterns | Si le plan tranche body-only pour les deux métriques par souci de cohérence interne, les deux fichiers déjà à 250/250 (`vf-dev-manager.md`, `validator/AGENT.md`) auraient une marge de frontmatter (7-9 lignes) qu'ils n'ont pas aujourd'hui dans T3/T5 — écart de définition entre gates à documenter explicitement si choisi |
| A2 | Le format de baseline recommandé (TSV, une ligne par fichier, colonnes path/lignes/instructions, dans `.planning/instruction-budget-baselines.tsv`) est une proposition de cette recherche, **aucun précédent exact** de ce format n'existe dans le dépôt (contrairement à la sentinelle, qui a un précédent exact) | Structure de fichiers recommandée | Le plan peut légitimement choisir un autre format (JSON, un fichier par module) sans que cela contredise aucune décision verrouillée — Claude's Discretion explicite au cadrage |
| A3 | La définition "bullet impératif sous titre de règles" proposée (liste de titres `R[eè]gles\|Garde-fous\|Iron Law\|Anti-pattern\|Lignes rouges\|Discipline`) est un candidat mesuré, pas un choix verrouillé — le plan peut retenir une liste de titres différente ou refuser la règle bullet entièrement (la garder en marqueurs textuels seuls) | Candidats pour la forme bullet | Change les baselines finales gravées à la calibration (jusqu'à +68 lignes-instruction / +16 %) |
| A4 | Le chiffre de baseline "463 instructions / 44 pour vf-dev-manager.md" cité au cadrage (CONTEXT.md D-03) a été obtenu par un comptage qui INCLUT le frontmatter, contredisant la lettre de D-01 ; cette recherche recommande de recalibrer body-only (433/43) au moment du script fini, mais le point n'a pas été re-tranché par un arbitrage humain explicite | Écart 433 vs 463 | Si personne ne relit cette section, le plan pourrait implémenter body-only (contredisant silencieusement le chiffre cité en CONTEXT.md) sans que quiconque n'ait validé ce choix — recommandé de le soumettre explicitement au discuss/plan-checker |

**Si cette table devait être vide :** elle ne l'est pas — les quatre assomptions ci-dessus
nécessitent une confirmation explicite avant que la calibration ne grave des valeurs définitives.

## Open Questions

1. **La règle "puce impérative sous titre de règles" doit-elle s'appliquer récursivement à des
   sous-titres (`### …`) sous un titre de règles `## …`, ou seulement au niveau direct ?**
   - What we know : tous les titres de règles mesurés dans le corpus sont des `##` (niveau 2),
     aucun `###` imbriqué observé sous eux.
   - What's unclear : un futur agent pourrait structurer ses règles avec des sous-sections.
   - Recommendation : traiter tout titre `#+` (quel que soit son niveau) comme fermant/ouvrant le
     scope — c'est déjà ce que fait l'awk proposé (`/^#+[[:space:]]/`), donc un `###` sous un `##
     Iron Laws` fermerait le scope à tort si son propre texte ne matche pas la liste. À valider
     explicitement au plan avec un cas de test dédié si cette structure apparaît un jour.

2. **Le fichier de baseline doit-il être un artefact du module `conductor` (`plugin/conductor/`)
   ou rester dans `.planning/` comme recommandé ici ?**
   - What we know : la sentinelle a un précédent exact dans `.planning/` ; aucun précédent de
     baseline "données mesurées" n'existe dans ce dépôt pour trancher par analogie.
   - What's unclear : si `.planning/` est considéré comme "état de planification éphémère" par
     d'autres parties du tooling GSD (ex. purgé lors d'un `gsd-complete-milestone`), un fichier de
     contrat durable pourrait être mal placé là.
   - Recommendation : vérifier au plan si `.planning/REQUIREMENTS.md`/`ROADMAP.md` (qui survivent
     aux clôtures de milestone) donnent un précédent de "fichier durable dans .planning/" — sinon
     confirmer explicitement que ce choix est acceptable avant de graver le premier commit de
     calibration.

## Sources

### Primary (HIGH confidence)
- Lecture directe et exécution sur le dépôt `vibeflow-os` (2026-09-15) : `25-CONTEXT.md`,
  `ROADMAP.md` §Phase 25, `REQUIREMENTS.md` (BUDG-01/02, QUAL-01), `STATE.md`,
  `check-requirements-survival.sh`, `requirements-survival-detect.sh`, `dev-orchestrator/AGENT.md`
  (§sentinelle), `check-divergence.sh` + `test-check-divergence.sh`, `check-agents.sh`,
  `conductor/README.md`, `test-dev-orchestrator.sh` (T3/T5/T8), `check-file-size.sh`,
  `vf-portable.sh`, `check-version-sync.sh`, `.github/workflows/ci.yml`,
  `docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md` §7,
  `.planning/research/PITFALLS.md` (Pitfall 9, Technical Debt Patterns),
  `.planning/research/ARCHITECTURE.md`, `.planning/research/FEATURES.md` (F3),
  `.planning/codebase/CONVENTIONS.md`, `.planning/codebase/TESTING.md`, `docs/ADR.md`,
  `plugin/reference/content/methodology/patterns/03-agents.md`,
  `docs/reference/methodology/templates/skills/agent-density-auditor/references/thresholds.md`,
  `40-CONTEXT.md` (Phase 40, §domain + D-01/D-04).
- Mesure directe par exécution de commandes `awk`/`grep` sur les 31 fichiers du corpus
  (2026-09-15, reproductible par les commandes citées dans ce document).

### Secondary (MEDIUM confidence)
- Aucune — cette phase n'a nécessité aucune recherche externe (pas de librairie tierce, pas de
  documentation d'API externe).

### Tertiary (LOW confidence)
- Aucune.

## Metadata

**Confidence breakdown:**
- Mécanisme de ratchet/sentinelle : HIGH — précédent exact cloné, ligne par ligne
- Comptage lignes/instructions : HIGH — mesuré par exécution réelle, reproductible
- Forme "puce impérative sous titre de règles" : MEDIUM — candidat mesuré avec contrôles
  positif/négatif, mais reste un choix éditorial que le plan doit ratifier explicitement
- Câblage CI en mode non-armé : MEDIUM — aucun précédent exact du traitement "exit 3 = job vert",
  la proposition est cohérente avec la doctrine mais inédite dans ce dépôt

**Research date:** 2026-09-15
**Valid until:** jusqu'à la clôture de la Phase 40 (le corpus mesuré ici devient obsolète dès que
`plugin/dev-orchestrator/AGENT.md` est réécrit) — au-delà, re-mesurer avant toute calibration,
jamais recopier les tableaux de ce document.
