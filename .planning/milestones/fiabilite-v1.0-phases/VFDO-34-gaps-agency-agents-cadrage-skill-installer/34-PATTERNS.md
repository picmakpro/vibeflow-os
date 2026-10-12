# Phase 34 : Gaps agency-agents & cadrage skill-installer — Carte des patterns

**Cartographié le :** 2026-09-15
**Fichiers analysés :** 8 livrables potentiels (3 notes de décision + 1 mise à jour ledger + 1
module conditionnel de 9 fichiers)
**Analogs trouvés :** 8 / 8 (dont 1 groupe conditionnel — `web-test-team` — dont la construction
dépend elle-même du verdict D-04/D-05 rendu par le plan)

**Note de méthode :** la Phase 34 est **documentaire à une exception** (D-10). La quasi-totalité
du travail est de la prose Markdown dans `.planning/`, pas du code sous `plugin/`. Les patterns ci-
dessous portent donc majoritairement sur la **forme des notes de décision** (structure, ton,
niveau de preuve) plutôt que sur des conventions de code. Le seul groupe de fichiers « code » est
`web-test-team`, **conditionnel** au run vert (D-05) — inclus ici pour que le planner n'ait pas à
redécouvrir le moule si le run est vert, mais à traiter comme une branche du plan, pas un livrable
garanti.

Tous les chemins d'analogs ci-dessous sont **suivis par git** (`git ls-files` vérifié) — aucun
n'est un miroir d'installation sous `.gsd/` ou `~/.claude/`.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/VFDO-34-.../34-AUDIT-AGTS.md` | config (note de décision/gouvernance) | batch (re-mesure + verdict par gap) | `.planning/BACKLOG.md:303-348` (item d'origine, matrice) | role-match |
| `.planning/phases/VFDO-34-.../34-RUN-MOBILE.md` | test (trace de run réel) | event-driven (boucle test→corrige→re-test tracée) | `.planning/phases/VFDO-32-.../32-SPIKE-reference-transaction.md` | exact (spike/trace figée sur disque) |
| `.planning/phases/VFDO-34-.../34-SPIKE-SKIL.md` | test (spike jetable, findings consignés) | event-driven (protocole mesure : contrôle négatif + cas cible) | `.planning/phases/VFDO-37-.../SPIKE-REPORT.md` | exact |
| `.planning/BACKLOG.md` (entrées AGTS-01 gaps, item skill-installer 258-273) | config (ledger) | CRUD (update d'items existants) | lui-même (édition sur place, style déjà établi) | exact |
| `.planning/REQUIREMENTS.md` (cases à cocher AGTS-01/02/SKIL-01, `:958-963`) | config (ledger) | CRUD | lui-même | exact |
| `.planning/PROJECT.md:82` (item actif → coché SI run vert) | config (ledger) | CRUD | lui-même | exact |
| `plugin/mobile-test/README.md` + `module.json` (sortie d'expérimental SI vert) | config/doc | CRUD (édition de statut) | `plugin/mobile-test/CHANGELOG.md` (précédents de statut) | exact |
| `plugin/mobile-test-team/README.md` + `module.json` (sortie d'expérimental SI vert) | config/doc | CRUD | `plugin/mobile-test-team/CHANGELOG.md` | exact |
| `plugin/web-test-team/module.json` (SI run vert, D-05/D-09) | config | CRUD | `plugin/mobile-test-team/module.json` | exact |
| `plugin/web-test-team/agents/vf-web-test-orchestrator.md` (SI run vert) | controller (orchestrateur, dispatch) | event-driven | `plugin/mobile-test-team/agents/vf-test-orchestrator.md` | exact |
| `plugin/web-test-team/agents/vf-web-test-runner.md` (SI run vert) | service (worker cloisonné, Pattern 12) | event-driven | `plugin/mobile-test-team/agents/vf-test-runner.md` | exact |
| `plugin/web-test-team/agents/vf-web-app-fixer.md` (SI run vert) | service (worker cloisonné, Pattern 12) | event-driven | `plugin/mobile-test-team/agents/vf-app-fixer.md` | exact |
| `plugin/web-test-team/rules/web-verify-gate.md` (SI run vert) | middleware (rule path-scopée) | event-driven (auto-chargement sur pattern de chemin) | `plugin/mobile-test-team/rules/mobile-verify-gate.md` | exact |
| `plugin/web-test-team/references/test-loop-protocol.md` (SI run vert) | utility (référence chargée on-demand) | transform (doc → contexte injecté) | `plugin/mobile-test-team/references/test-loop-protocol.md` | exact (réutilisable quasi tel quel) |
| `plugin/web-test-team/CHANGELOG.md` (SI run vert) | config | batch | `plugin/mobile-test-team/CHANGELOG.md` (entrée v1.0.0) | exact |
| `plugin/web-test-team/README.md` (SI run vert) | config/doc | batch | `plugin/mobile-test-team/README.md` | exact |
| `plugin/web-test-team/VERSION` (SI run vert) | config | — | `plugin/mobile-test-team/VERSION` | exact |

## Pattern Assignments

### `34-AUDIT-AGTS.md` (note d'audit AGTS-01)

**Analog :** `.planning/BACKLOG.md:303-348` (matrice division → module, item du 2026-07-20)

**Structure à reprendre** (extrait, `BACKLOG.md:320-331`) :
```markdown
**Mapping divisions → modules (au 2026-07-20) :**

| Division agency-agents | Module VibeFlow | Statut |
|---|---|---|
| Testing | `mobile-test`(-team) | 🟡 Mobile only, expérimental |
| Support | — | ❌ Manquant |
```
Re-mesurer chaque ligne à la date de la phase (le corpus n'a pas bougé — 25+6=31 fichiers,
`RESEARCH.md` § Volet 1 le confirme) ; ajouter une colonne ou un paragraphe **verdict par gap**
(combler / reporter / refuser) — absente de la matrice d'origine, exigée par D-01.

**Règle de preuve à citer explicitement pour chaque refus** (D-02, ton à reprendre tel quel,
`34-CONTEXT.md:44-48`) :
> « Un ❌ dans la matrice du catalogue **ne suffit pas** — la couverture du catalogue est une
> source d'inspiration, jamais une référence d'exigence. »
Reprendre cette formule **en toutes lettres pour chaque gap refusé**, avec la preuve précise qui
manque (Specific Ideas, `34-CONTEXT.md:169`).

**Pitfall 12 — signal d'alarme à nommer explicitement** (D-03) : reprendre le ton de mise en garde
de `PITFALLS.md:377-408` — « plus de 2-3 agents d'un coup » et « un agent à la fois, gaté
`check-agents.sh` ».

**Format de sortie du gap « à combler » :** un **item BACKLOG daté avec sa preuve**, jamais un
fichier `plugin/`. Reprendre le format d'entrée BACKLOG déjà en place (`## Titre` / `**Capturé :**
date` / `**Pourquoi différé :**` / `**Déclencheur de resurgence :**`), visible en tête de
`BACKLOG.md:295-301` (entrée précédente, structure complète à imiter) et dans l'entrée
`agency-agents` elle-même (`:303-320`).

---

### `34-RUN-MOBILE.md` (trace du run réel AGTS-02)

**Analog :** `.planning/phases/VFDO-32-durcissement-du-driver-lock/32-SPIKE-reference-transaction.md`

**En-tête de statut et verdict tranché dès le chapeau** (lignes 1-8, pattern à reprendre) :
```markdown
# Spike `reference-transaction` — Phase 32, research flag bloquant

> **Statut** : clos le 2026-08-16. **Verdict : PAS SÛR pour bloquer.**
> Le ROADMAP (§Phase 32, critère de succès n°3) conditionnait le blocage du checkout à ce que
> « le spike `reference-transaction` le prouve sûr ». Il ne le prouve pas. Ce document est la
> preuve mesurée qui ferme la question ; il est consigné sur disque à la demande explicite de
> Samuel (2026-08-16) pour que la conclusion ne se rejoue pas de mémoire à la phase suivante.
```
→ Pour `34-RUN-MOBILE.md` : même gabarit — statut (vert/rouge), date, verdict en une phrase,
rappel de la condition ROADMAP/CONTEXT qui déclenchait ce run (D-04), traçabilité de l'arbitrage
si applicable (règle CLAUDE.md racine « traçabilité des arbitrages » : canal + date).

**Section environnement mesuré** (ligne 10, à adapter) :
```markdown
Environnement mesuré : **git 2.50.1 (Apple Git-155)**, macOS, backends `files` **et** `reftable`,
7 dépôts jetables (labs 1→7). Aucun fichier du dépôt modifié pendant le spike.
```
→ Adapter : Maestro 2.6.1, JDK 17 Homebrew, Node v26.5.0, UDID du simulateur retenu (Pitfall 1/2
de `34-RESEARCH.md`), lab `Scroll-Off/frontend`, garantie « aucun `clearState`/`clearKeychain` ».

**Table de mesures avec commandes verbatim et sorties exactes** (lignes 22-27, pattern à reprendre
pour documenter chaque étape du run — build, install, Maestro, rapport) :
```markdown
**Mesuré : sur git ≥ 2.46, le hook VOIT bien le checkout de branche.**
`git checkout feat` émet en phase `prepared` :

```
0000000000000000000000000000000000000000 ref:refs/heads/feat HEAD
```
```

**Cause d'arrêt propre, si rouge** (D-05) — reprendre le ton factuel et daté de la conclusion de
raisonnement (« Raison n°1 », « Raison n°2 » du spike 32) : nommer la cause précise, pas un
« ça n'a pas marché » vague. Écrire le **déclencheur de reprise daté** au ledger (BACKLOG.md,
même gabarit que les entrées existantes).

**Déviation assumée à documenter explicitement (Open Question 3 de RESEARCH.md)** : si le run ne
force pas de rebuild (app déjà installée, session préservée), le documenter comme déviation
assumée et datée — pas un contournement silencieux, cohérent avec la discipline CLAUDE.md.

---

### `34-SPIKE-SKIL.md` (verdict SKIL-01)

**Analog :** `.planning/phases/VFDO-37-portabilit-multi-runtime-spike-codex-opencode-kimi/SPIKE-REPORT.md`

**Chapeau factuel + verdict séparé, pas un go/no-go sec sans nuance** (lignes 1-9) :
```markdown
# SPIKE-REPORT — Phase 37 : portabilité multi-runtime (Codex, OpenCode, kimi-code)

Milestone `fiabilite-v1.0`. Base factuelle unique : `DISCUSS.md` (même dossier, version courante
du fichier — 6 questions ROADMAP mesurées). Ce rapport n'ajoute aucune donnée absente de ce
document — tout point non couvert y est marqué « non mesuré ».

## Verdict — en deux morceaux, pas un go/no-go sec
```
→ Pour SKIL-01 : verdict GO/NO-GO explicite (D-07/D-09 : GO seulement si trou mesuré ET engine
peut le fermer), avec citation verbatim du **protocole de spike déjà écrit dans `34-RESEARCH.md`**
§ Volet 3 (contrôle négatif → cas cible A/B → verdict) — ne pas réinventer le protocole, l'exécuter
et consigner le résultat.

**Table de non-fiabilité des sources / distinction canal vs architecture** (pattern findings
autonomes réutilisable ailleurs, lignes 40-49 du spike 37) — à reprendre pour distinguer
explicitement, comme le fait déjà `34-RESEARCH.md` Pitfall 5 : « le canal atteint-il un sous-agent
qui A l'outil `Skill` » (la vraie question) vs « tous les agents VF peuvent-ils déjà invoquer des
skills » (non — choix d'architecture séparé, hors périmètre).

**Citation verbatim de la doc officielle comme preuve tertiaire, jamais suffisante seule** (D-07
exige une mesure, pas une lecture) — reprendre le ton `[CITED: ...]` / `[VERIFIED: ...]` déjà
utilisé dans `34-RESEARCH.md:350-364` pour la doc officielle Claude Code.

**Si NO-GO :** clôturer explicitement l'item BACKLOG du 2026-06-04 (`BACKLOG.md:258-273`) — même
mécanique de fermeture qu'un spike NO-GO structurel (cf. spike 37 : « no-go structurel envisagé…
» retourné par la mesure). Reprendre le paragraphe de clôture d'item BACKLOG déjà en place plus
haut dans le fichier (voir édition BACKLOG ci-dessous).

---

### Édition `.planning/BACKLOG.md` (clôture/mise à jour d'items)

**Analog :** le fichier lui-même — entrée `## Combler les gaps de couverture inspirés du catalogue
agency-agents` (`:303-348`) et l'entrée skill-installer (`:258-273`, à lire avant modification).

**Gabarit d'entrée BACKLOG déjà établi** (à reprendre pour tout nouvel item « gap à combler ») :
```markdown
## <Titre du gap>
**Capturé :** <date> · **À explorer :** <déclencheur>

> **Source :** ...

**Cadrage.** ...

**Pourquoi différé :** ...

**Déclencheur de resurgence :** ...
```

**Ton de clôture d'un item (SI SKIL-01 = NO-GO)** — reprendre la manière dont un item passé est
clos ailleurs dans le repo (voir `.planning/PROJECT.md` § Résolved / Out of Scope, extrait) :
```markdown
### Out of Scope

- Fork/réécriture des skills GSD — on délègue, on n'absorbe pas (maintenir GSD à jour gratuitement)
- Support multi-runtime au-delà de ce que GSD fait déjà — hors périmètre VibeFlow
```
→ Une ligne factuelle, la raison entre parenthèses, jamais de prose longue pour un item clos.

---

### Édition `.planning/REQUIREMENTS.md` (cases AGTS-01/02, SKIL-01) et `.planning/PROJECT.md:82`

**Analog :** le fichier lui-même, section « Milestone fiabilite-v1.0 » (`:955-963` déjà lu) et
`PROJECT.md` § Active/Résolved (`:81-86` déjà lu).

**Pattern de case à cocher avec preuve inline** (`REQUIREMENTS.md:961-963`) :
```markdown
### Skill-installer global (réduit à un cadrage)
- [ ] **SKIL-01**: Un cadrage go/no-go répond à « que fait-il de plus que le natif `/plugin` ? » — abandon documenté si la réponse est creuse ; aucun code avant le go

### Gaps agency-agents (réduit)
- [ ] **AGTS-01**: Les gaps sont arbitrés en distillant la taxonomie du catalogue — jamais d'import des personas
- [ ] **AGTS-02**: `web-test-team` est construite SI mobile-test sort du statut expérimental pendant le milestone (seule piste alignée fiabilité) ; sinon l'exigence est reportée avec trace
```
→ Cocher `[x]` avec renvoi à la note qui prouve chaque ID, jamais cocher sans preuve écrite (cf.
mémoire de session « une preuve doit pouvoir rendre rouge »).

**`PROJECT.md:82`** — pattern de case Active → Résolved (`:70-84` déjà lu) : l'item migre de
`### Active` vers un bloc daté équivalent à `### Résolved`/`### Active` déjà en tête du fichier
(`:70-77`, style « soldées : ... » avec verdict motivé) **seulement si le run est vert**.

---

### Sortie d'expérimental — `plugin/mobile-test/module.json` + `README.md` (SI run vert)

**Analog :** `plugin/mobile-test/module.json` (propre historique de statut) et
`plugin/mobile-test/CHANGELOG.md` (dernier patch de statut, v1.0.2).

**Description `module.json` actuelle, phrase de statut à retirer** (ligne 5 complète) :
```json
"description": "Pipeline de test mobile réel (iOS simulateur / Android émulateur) : détection de cible, build-if-absent, régression Maestro, rapport horodaté + artefacts, diagnostic visuel mobile-mcp sur échec. Script mécanique + skill jugement. Statut expérimental jusqu'au premier run réel vert. Toute valeur projet en config, aucune constante machine."
```
→ Retirer « Statut expérimental jusqu'au premier run réel vert. » ; **bump de version** (au
minimum patch, cf. convention `CHANGELOG.md` : le passage v1.0.1→v1.0.2 était déjà un patch pour un
changement de doc de statut — pattern directement applicable ici aussi).

**README — section Limites à réécrire** (`README.md:117-123`, bloc `⚠️ Statut expérimental`) :
```markdown
## Limites

- ⚠️ **Statut expérimental.** ... La condition de sortie du statut
  est précisément ce run : `detect` → `run --platform ios` (build depuis zéro) → rapport généré.
  Tant qu'il n'existe pas, considère le module comme une base solide **à confirmer**.
```
→ Remplacer par une ligne factuelle de sortie, datée, renvoyant à `34-RUN-MOBILE.md` — pattern
déjà observé pour d'autres transitions de statut dans ce repo (jamais de suppression silencieuse
de la mention, toujours un enregistrement daté de la sortie, cf. `CHANGELOG.md` de
`mobile-test-team` v1.4.4 : chaque correctif de statut est tracé avec sa cause).

**Entrée CHANGELOG à ajouter** — reprendre le gabarit déjà utilisé (`CHANGELOG.md:3-8`, v1.0.2) :
```markdown
## v1.0.3 — 2026-09-15 (Phase 34 — sortie du statut expérimental)

### Modifié
- Statut expérimental levé : premier run réel vert tracé (`34-RUN-MOBILE.md`, lab
  `Scroll-Off/frontend`, iOS). ...
```

---

### Sortie d'expérimental — `plugin/mobile-test-team/module.json` + `README.md` (SI run vert)

**Analog :** mêmes fichiers, miroir exact du traitement `mobile-test` ci-dessus. Voir
`module.json:5` (phrase « Statut expérimental jusqu'au premier run réel vert. ») et
`README.md:120-127` (bloc Limites), `CHANGELOG.md:1-8` (gabarit d'entrée patch).

---

### `plugin/web-test-team/*` — SI le run est vert (D-05/D-09)

**Analog :** `plugin/mobile-test-team/*` en bloc — inventaire fichier par fichier déjà établi par
`34-RESEARCH.md` § Volet 2 (« Le moule `mobile-test-team` — inventaire fichier par fichier »),
repris ici tel quel.

**`module.json`** — analog `plugin/mobile-test-team/module.json` (lu intégralement) :
```json
{
  "name": "mobile-test-team",
  "version": "v1.4.5",
  "type": "agents + rules",
  "description": "Équipe de test mobile autonome : la boucle test → corrige → re-test (vf-test-orchestrator + workers cloisonnés vf-test-runner / vf-app-fixer, Pattern 12) qui manquait pour qu'un mode autonome aille jusqu'à « l'app marche vraiment ». Rule path-scopée qui invoque la doctrine de vérification réelle dès qu'on développe du mobile. Statut expérimental jusqu'au premier run réel vert.",
  "requires": [
    "mobile-test"
  ]
}
```
→ Pour `web-test-team` : `"requires": []` (Playwright est une dépendance **lab**, pas plugin —
cf. `34-RESEARCH.md:154` et `STACK.md:105`), nouvelle description sur le même gabarit (rôle +
Pattern 12 + condition de sortie), `"version": "v1.0.0"`.

**Imports/frontmatter agents — pattern exact à cloner puis renommer (Pitfall 4)** :
```yaml
---
name: vf-test-orchestrator
description: "Orchestrateur de la boucle de test autonome pour projets MOBILES (Expo/React Native). ..."
tools: Read, Write, Bash, Glob, Grep, WebSearch, WebFetch, Agent(vf-test-runner, vf-app-fixer)
model: sonnet
effort: high
memory: project
vf-mcp-consumer: true
vf-requires: mcp-servers
---
```
→ Renommer `name:` en `vf-web-test-orchestrator` (Pitfall 4, collision de `name:` entre modules,
`check-agents.sh --resolve-agents=strict` gate ça en CI) ; `Agent(vf-web-test-runner,
vf-web-app-fixer)` ; description adaptée web (Playwright au lieu de Maestro/simulateur).

**Garde « projet applicable »** (`vf-test-orchestrator.md:14-20`, à adapter) :
```markdown
## Garde — projet applicable

Cet agent ne s'applique qu'à un **projet mobile** (Expo / React Native). ... En début de mission,
vérifie la présence de marqueurs (`app.json` avec clé `expo`, ou `.vibeflow/mobile-test.json`, ou
un dossier de flows Maestro). Si aucun n'est présent → **décline** la tâche...
```
→ Marqueurs web : `playwright.config.*`, `package.json` avec dépendance `@playwright/test`, un
dossier `e2e/**` (cf. `34-RESEARCH.md` § Recommended Project Structure).

**Cloisonnement worker test (`vf-test-runner.md:21-29`, pattern exact à cloner)** :
```markdown
## Domaine d'action (STRICT — Pattern 12)

Tu écris UNIQUEMENT dans le dossier des flows de test (par défaut `.maestro/**`, ou
`maestroFlowsDir` de la config mobile-test).

**INTERDIT absolu** : modifier le code app (`src/**`, `app/**`, `components/**`, backend). Tu ne
corriges jamais l'app : si un test échoue à cause de l'app, tu le **rapportes** — c'est
`vf-app-fixer` qui corrige. Tu n'as pas l'outil `Task` : tu ne peux pas escalader ni te déléguer.
```
→ Remplacer `.maestro/**` par le dossier de specs Playwright (ex. `e2e/**`), reste identique
(cloisonnement, pas de `Task`, règle anti-triche : ne jamais affaiblir un assert).

**Cloisonnement worker fixer (`vf-app-fixer.md:19-31`, pattern exact à cloner)** — inclut le gate
ADR-045 (pas de web côté fixer, `doc-research-required` remonté à l'orchestrateur) : reprendre
verbatim, seul le domaine `src/**`/`app/**` change de nature (web plutôt que mobile), pas la règle.

**Rule path-scopée (`rules/mobile-verify-gate.md:1-6`, frontmatter à adapter)** :
```yaml
---
paths:
  - "app/**/_layout.tsx"
  - "src/screens/**"
  - ".maestro/**"
---
```
→ Marqueurs web discriminants (éviter la même erreur que la version mobile — cf.
`mobile-test-team/CHANGELOG.md` v1.3.1 : globs génériques `app/**/*.tsx` retirés car ils
matchaient tout projet Next.js). Proposer par ex. `playwright.config.*`, `e2e/**/*.spec.ts` —
**jamais** de glob générique `src/**` qui chargerait la rule sur tout projet web non testé par
Playwright.

**`references/test-loop-protocol.md`** — réutilisable quasi tel quel (`34-RESEARCH.md` le
confirme) : seule la ligne « Pipeline mécanique : module `mobile-test`, skill `vf-mobile-test` »
change vers l'équivalent web (module `web-test`, si créé séparément, ou directement Playwright
inline si aucun module mécanique séparé n'est construit — **à trancher par le plan**, absent des
verrous D-04 à D-09).

**CHANGELOG — première entrée (`v1.0.0`, pattern exact)** :
```markdown
## v1.0.0 — <date>

Création du module (Phase 34, AGTS-02 vert). Équipe de test web autonome, calquée sur
`mobile-test-team` (moule prouvé par le run mobile).

- **3 agents cloisonnés** (Pattern 12) : `vf-web-test-orchestrator`, `vf-web-test-runner`,
  `vf-web-app-fixer`.
- **Rule path-scopée** `web-verify-gate.md` : ...
- **Référence** `test-loop-protocol.md` : ...
```

**README** — structure exacte de `mobile-test-team/README.md` (tagline, Quoi, Installation,
Démarrer, Usage, Référence en tableau agents avec `tools:`, Limites) : reprendre section par
section, retirer le bloc « ⚠️ Statut expérimental » (ou l'adapter si `web-test-team` naît elle-même
en statut à confirmer — **à trancher par le plan**, la Phase 34 ne fixe pas cette question pour le
nouveau module).

## Shared Patterns

### Discipline de traçabilité des arbitrages
**Source :** `CLAUDE.md` racine du repo (§ Conventions transverses, « Traçabilité des arbitrages »)
**Apply to :** les trois notes de décision (34-AUDIT-AGTS, 34-RUN-MOBILE, 34-SPIKE-SKIL) dès
qu'elles invoquent un arbitrage humain — nommer **canal et date** (« arbitrage Samuel,
AskUserQuestion session principale, 2026-09-14 »), jamais « arbitrage Samuel » nu.

### Preuve mesurée, jamais lue seule
**Source :** mémoire de session `[[preuve-incapable-de-rendre-rouge]]`, appliquée dans
`34-RESEARCH.md` Volet 3 et dans le spike Phase 37 (`SPIKE-REPORT.md`, table de non-fiabilité des
descripteurs)
**Apply to :** `34-SPIKE-SKIL.md` — la citation de la doc officielle Claude Code
(`34-RESEARCH.md:350-364`) est un point de départ, jamais une conclusion ; le contrôle négatif fait
partie de la mesure, pas seulement le cas positif.

### Statut expérimental — cycle de vie (`module.json` + `README.md` + `CHANGELOG.md`)
**Source :** `plugin/mobile-test/module.json:5`, `plugin/mobile-test/README.md:117-123`,
`plugin/mobile-test-team/module.json:5`, `plugin/mobile-test-team/README.md:120-133`
**Apply to :** les deux modules `mobile-test`/`mobile-test-team` si le run est vert — retirer la
phrase de statut de `module.json.description`, remplacer le bloc `⚠️ Statut expérimental` du
README par la mention datée de sortie, ajouter une entrée CHANGELOG (patch), jamais de suppression
silencieuse de la trace de statut antérieur.

### Cloisonnement Pattern 12 (workers `vf-internal: true`)
**Source :** `plugin/mobile-test-team/agents/vf-test-runner.md`,
`plugin/mobile-test-team/agents/vf-app-fixer.md` (cf. extraits ci-dessus)
**Apply to :** tout nouvel agent worker de `web-test-team` — `tools:` sans `Task`, `vf-internal:
true`, domaine d'écriture strictement disjoint entre le worker tests et le worker code app, ADR-045
(le fixer n'a pas le web, remonte `doc-research-required`).

### Gabarit d'entrée BACKLOG
**Source :** `.planning/BACKLOG.md` (n'importe quelle entrée `##`, ex. `:295-348`)
**Apply to :** tout gap AGTS-01 jugé « à combler » qui devient un item backlog daté avec sa preuve
(D-01) — `**Capturé :**` / `**Cadrage.**` / `**Pourquoi différé :**` / `**Déclencheur de
resurgence :**`.

## No Analog Found

Aucun fichier de la phase n'est sans analog — la phase est délibérément conçue pour ne rien créer
qui n'ait pas déjà un moule proche (D-10 : documentaire à une exception, et l'exception clone un
module existant).

## Metadata

**Analog search scope :** `plugin/mobile-test/`, `plugin/mobile-test-team/`, `.planning/BACKLOG.md`,
`.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `.planning/phases/VFDO-32-*/`,
`.planning/phases/VFDO-37-*/`, `CLAUDE.md` racine du repo.
**Files scanned :** 15 fichiers lus intégralement ou par extrait ciblé (offsets non chevauchants).
**Pattern extraction date :** 2026-09-15

## PATTERN MAPPING COMPLETE
