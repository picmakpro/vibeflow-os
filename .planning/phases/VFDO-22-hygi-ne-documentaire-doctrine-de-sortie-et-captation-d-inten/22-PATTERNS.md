# Phase 22 : Hygiène documentaire — doctrine de sortie et captation d'intention - Pattern Map

**Mapped:** 2026-07-31
**Files analyzed:** 7 (+ triade release)
**Analogs found:** 7 / 7

Ce module n'est pas une application — c'est un plugin Claude Code distribué en markdown +
frontmatter YAML + bash. Les « rôles » ci-dessous sont donc adaptés : `doctrine` (référence
markdown chargée on-demand), `agent` (définition d'agent avec frontmatter), `test` (suite bash
d'assertions).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `plugin/dev-orchestrator/references/docs-flow.md` (création) | doctrine (référence on-demand) | request-response (agent lit → décide → délègue) | `plugin/dev-orchestrator/references/ingestion-flow.md` (94L) | exact — patron explicitement désigné (D-01) |
| `plugin/dev-orchestrator/references/intent-routing.md` (modification, §Contexte & session + §Voir aussi) | doctrine (table de routage) | request-response | lui-même (extension in-place, house style constante) | exact |
| `plugin/dev-orchestrator/AGENT.md` (modification, §Next steps, §Signaux, §Références) | agent (frontmatter + prose) | event-driven (signaux SessionStart) + request-response | lui-même | exact |
| `plugin/dev-orchestrator/agents/vf-dev-manager.md` (modification, §Hygiène documentaire, §Orchestration) | agent (manager, DAG) | event-driven (nœuds DAG) | lui-même + `mission-flow.md` §Pattern B/C/E pour le vocabulaire DAG | exact |
| `plugin/design-orchestrator/agents/vf-design-manager.md` (modification, renvoi + déclencheurs) | agent (manager, DAG) | event-driven | `vf-dev-manager.md` (même contrat kernel) + précédent de renvoi cross-module `mission-cross-team.md` | role-match (structure symétrique, module différent) |
| `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (extension, nouveau bloc `T19` ou suivant) | test (bash, assertions ok/ko) | batch (script séquentiel, compteurs pass/fail) | lui-même — blocs T16/T17 (ingestion) sont le gabarit le plus proche (même forme : bloc de garde-fous + routage + renvoi AGENT.md) | exact |
| Triade release (`VERSION`, `plugin/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, README×2, CHANGELOG dev-orchestrator + design-orchestrator) | config | batch | dernier bump minor du module (git log) | exact (mécanique documentée dans `CLAUDE.md` racine) |

## Pattern Assignments

### `plugin/dev-orchestrator/references/docs-flow.md` (doctrine, création)

**Analog:** `plugin/dev-orchestrator/references/ingestion-flow.md` (94 lignes) — le patron **explicitement désigné** par D-01/D-02 et par `<code_context>` de CONTEXT.md. Pas de recherche à faire : le fichier EST le patron.

**Squelette structurel complet** (à répliquer section par section, titre différent, même ossature) :

```markdown
# <Nom-flow> — doctrine de <objet> (<ID d'exigence si applicable>)

> Source de vérité de la capacité de <X> : <ce que fait l'agent>, <ce qu'il construit>,
> <à quelles conditions il délègue> — sans jamais réimplémenter ni contourner les gates natifs
> de `<skill-moteur>`. Chargée **on-demand** par `vibeflow-dev`, comme `mission-flow.md` et
> `GSD-PIPELINE.md` — coût contexte nul le reste du temps. Le **fait outillé** est produit par
> `<script ou skill>` : ce fichier ne le redéfinit pas, il documente comment l'interpréter.

---

## <Section 1 : Découverte/Discernement>
## <Section 2 : Construction/Routage par famille>
## <Section 3 : Délégation>
## Garde-fous <ID>
## Interdits
```

**Contraintes concrètes tirées de l'analog** (lignes 1-11, encadré de rôle) :
- Titre H1 avec sous-titre citant l'ID d'exigence source (ici `ingestion-flow.md` cite BRDG-01/BRDG-03) ; `docs-flow.md` peut citer les décisions D-01→D-14 ou rester sans ID formel puisqu'aucun ID BRDG-xx n'a été attribué en CONTEXT.md — à trancher au plan.
- Le paragraphe de rôle (blockquote `>`) est **toujours un seul bloc** qui répond à trois questions : quoi (source de vérité de quoi), comment chargé (on-demand, coût contexte nul, cité en pair avec `mission-flow.md`/`GSD-PIPELINE.md`), et qui produit le fait outillé sous-jacent.
- Séparateur `---` après l'encadré de rôle avant la première section (ligne 12-13).
- Sections en `##` (H2), jamais de H3 sauf tableaux internes.
- Chaque section finit sur un paragraphe de garde-fou ou un renvoi explicite, jamais en suspens.
- Dernière section toujours `## Interdits` — ferme le fichier sur ce qui NE DOIT PAS être fait (ici : pas de verbe-façade `/vf-ingest`, pas de réimplémentation du parseur).

**Renvoi obligatoire vers `ingestion-flow.md` pour la famille « entrée »** (D-02) — modèle du renvoi à copier depuis la ligne 54 d'`intent-routing.md` :
```
| intègre cette spec à la feuille de route / importe ce plan (doctrine : `ingestion-flow.md`) | `gsd-ingest-docs`, `gsd-import` |
```
`docs-flow.md` doit produire l'équivalent en prose (pas une table de routage — ADR-057 réserve le routage à `intent-routing.md`) : un paragraphe de type « famille entrée → voir `ingestion-flow.md`, source unique, non dupliquée ici ».

**Frontière transverse à écrire noir sur blanc** (`<specifics>` CONTEXT.md) — absente de l'analog car non pertinente pour l'ingestion, mais structurellement c'est un paragraphe de garde-fou de plus, même famille que « Interdits » :
> `vibeflow-os` maintient CHANGELOG/README/VERSION par module sous gates machine
> (`check-version-sync.sh`) — `gsd-docs-update` ne régénère jamais de CHANGELOG et ne connaît
> que les 9 types canoniques à la racine. Ne jamais lancer `gsd-docs-update` sur ce repo-ci.

**Contrainte de taille** : aucune limite ADR-029 formelle sur les fichiers `references/` (seule limite = agents ≤250L, skills ≤500L) mais la symétrie avec les 94 lignes d'`ingestion-flow.md` est la contrainte de facto (Claude's Discretion, CONTEXT.md).

---

### `plugin/dev-orchestrator/references/intent-routing.md` (modification)

**Analog:** lui-même — extension in-place, respecter le format de table existant.

**Format de table exact** (lignes 93-102, section `## Contexte & session` — celle à enrichir) :
```markdown
## Contexte & session

| Intention | Brique |
|---|---|
| on est où / et après / next / la suite / statut / avancement | `gsd-progress` (+ next step proposé par l'agent) |
| reprends où on en était / on reprend / recharge le contexte | `gsd-resume-work` |
| je m'arrête là / note où on en est / handoff | `gsd-pause-work` |
| comprends ce code / cartographie / c'est quoi ce repo / explique l'archi | `gsd-map-codebase` |
| mets à jour la doc / génère le README / la doc est périmée | `gsd-docs-update` |
| qu'est-ce qu'on a appris / extrais les décisions / le graphe de connaissance | `gsd-extract-learnings`, `gsd-graphify` |
```
La ligne `mets à jour la doc / génère le README / la doc est périmée | gsd-docs-update` est celle à **enrichir** (D-10/D-12) avec les formulations manquantes nommées en D-12 (« la doc est fausse », « --verify-only », « --force », etc.) — chaque formulation garde le format `intention / intention / intention | brique(s)`, colonnes séparées par `|`, une seule ligne de tableau (pas de multi-lignes).

**Contrat de la §Couverture** (lignes 141-167) à respecter si une nouvelle brique ou un nouveau canal de routage est introduit :
```markdown
## Couverture

Ce fichier route **l'intégralité** des skills listés dans `gsd-skills-index.md`, via trois
canaux — tous vérifiés machine (`test-dev-orchestrator.sh`, test d'exhaustivité contre
l'index ; ajouter un skill interne sans le router fait échouer la suite) :

1. **Routage direct** : ...
2. **Porté par un skill du module** : ...
3. **Délégué au module design** : ...
4. **Non routé — une seule voix (ADR-057)** : ...

Toute nouvelle exception doit être écrite ICI (et couverte par le test) — pas seulement dans
la whitelist du test.
```
Puisque D-12 dit « les briques ajoutées sont déjà dans l'index, aucune whitelist nouvelle n'est requise » — aucune modification de §Couverture n'est a priori nécessaire, sauf si `--verify-only`/`--force` sont traités comme des variantes d'appel de `gsd-docs-update` (pas de nouvelle brique) : à confirmer au plan.

**§Voir aussi** (lignes 169-174, renvoi à ajouter pour `docs-flow.md`) :
```markdown
## Voir aussi

- `GSD-PIPELINE.md` — l'ordre canonique du cycle (quoi après quoi), et non quelle intention mène où.
- `mission-contracts.md` — brief et rapport de mission quand le travail part à l'équipe.
```
Ajouter une ligne symétrique : `` - `docs-flow.md` — doctrine des quatre familles documentaires (quoi maintenir, quand, quel régime de confirmation). ``

---

### `plugin/dev-orchestrator/AGENT.md` (modification)

**Analog:** lui-même (181 lignes actuelles) — pattern de citation de doctrine on-demand et de table de signaux déjà établi.

**§Next steps & hygiène documentaire** (lignes 97-109) — pattern de prose à graduer, PAS remplacer par une table lourde (densité) :
```markdown
## Next steps & hygiène documentaire (rôle actif)

- **Après chaque geste fermé** ..., je propose **LE next step** ...
- **Je déclenche l'hygiène documentaire aux bons moments**, jamais au fil de l'eau :
  fin d'étape → `STATE`/`ROADMAP` (fait par la machinerie GSD, je vérifie) ; décision
  structurante → registre des décisions ; drift doc détecté (doc contredite par le code) →
  proposer `gsd-docs-update` ; fin de milestone → bilan + archivage ; spec/plan écrit(e) sans
  être encore dans la feuille de route → proposer l'ingestion (voir `ingestion-flow.md`) ; ...
```
Ce paragraphe reste dense (prose, pas table) — AGENT.md est à 181/250L, marge de ~69 lignes. La table de déclencheurs D-08 est réservée au **manager** (vf-dev-manager), pas à l'agent conversationnel : ici on ajoute seulement le renvoi vers `docs-flow.md` et la mention des familles code/savoir en plus de produit.

**§Signaux de démarrage** (lignes 111-124) — pattern de table à respecter à l'identique si une ligne est ajoutée :
```markdown
| Signal | Geste proposé | Confirmation |
|---|---|---|
| `[bootstrap]` | `gsd-config` puis `gsd-map-codebase` (items manquants listés) | requise avant toute écriture (ADR-031) |
| `[onboard]` | `gsd-onboard` | requise avant toute écriture (ADR-031) |
| `[gsd-engine]` | oriente vers `gsd-discuss-phase` / `gsd-plan-phase` / `gsd-progress` — pas un correctif | orientation seule, rien à écrire |
| `[doc-drift]` | `gsd-docs-update` | requise avant toute écriture (ADR-031) |
```
La ligne `[doc-drift]` existe déjà — D-14 demande qu'elle reste couplée au renvoi `docs-flow.md`, pas une nouvelle ligne de table forcément.

**§Références (chemin d'install D7)** (lignes 175-181) — pattern exact à répliquer pour ajouter `docs-flow.md` :
```markdown
## Références (chemin d'install D7)

- Carte d'intention exhaustive : `.claude/agents/dev-orchestrator-references/intent-routing.md`
- Doctrine pipeline détaillée : `.claude/agents/dev-orchestrator-references/GSD-PIPELINE.md`
- Index factuel des skills installés : `.claude/agents/dev-orchestrator-references/gsd-skills-index.md`
- Contrats de mission (brief + rapport + signaux + seuil) : `.claude/agents/dev-orchestrator-references/mission-contracts.md`
- Doctrine d'ingestion (découverte, manifest, garde-fous BRDG-03) : `.claude/agents/dev-orchestrator-references/ingestion-flow.md`
```
Ajouter une 6e ligne, même format : `` - Doctrine de sortie documentaire (familles, régime de confirmation, déclencheurs) : `.claude/agents/dev-orchestrator-references/docs-flow.md` ``

**Marge de densité** : AGENT.md est à **181/250 lignes** — marge confortable de 69 lignes, contrairement à `vf-dev-manager.md`.

---

### `plugin/dev-orchestrator/agents/vf-dev-manager.md` (modification)

**Analog:** lui-même — **CONTRAINTE DIMENSIONNANTE : 217/250 lignes actuelles, marge de 33 lignes seulement.**

**§Hygiène documentaire & next steps actuelle** (lignes 200-208) — les 3 puces à **REMPLACER** par la table D-08 (pas à côté, ADR-029) :
```markdown
## Hygiène documentaire & next steps (rôle actif)

- **Fin d'étape** : vérifie que la machinerie a mis à jour `STATE`/`ROADMAP` (fait-le sinon) ;
  une **décision structurante** prise en mission → consignée (STATE `### Decisions` ou registre
  du lab).
- **Drift doc détecté** (doc contredite par le code touché) : ajoute un nœud `gsd-docs-update`
  au DAG plutôt que de laisser filer — jamais de réécriture de doc au fil de l'eau.
- **Fin de mission** : propose LE next step depuis la feuille de route (étape suivante, recette
  en attente, milestone à clore) — une proposition ferme, pas un menu.
```
La table de D-08 (4 déclencheurs : surface publique / `[doc-drift]` / fin de milestone / nouveau module) doit remplacer la puce « Drift doc détecté » et absorber le reste en une table compacte — viser un delta net ≤ +15 lignes pour rester sous 250L après le §Orchestration.

**Pattern de nœud DAG agrégé à réutiliser** (§Orchestration par étape, ligne 88 sqq. — le vocabulaire `dag.sh add --deps=` est déjà là) :
```markdown
Dispatche **la frontière `ready` du DAG** (jamais un nœud `blocked`) ; marque `running` au dispatch,
`done`/`failed` au retour.
```
Le nœud `docs` de D-07 (`dag.sh add --file="$DAG" --id=docs --step="hygiène documentaire" --deps=exec-9,exec-10,…`) s'insère comme un point supplémentaire dans cette section, symétrique du point 2 « Revue » (ligne 115-119) qui pose systématiquement un nœud `revue-N` avec `deps=build` — même syntaxe `dag.sh add`, même logique de nœud systématique posé sans condition sauf ici conditionné par D-08 (au moins un déclencheur).

**Pattern de renvoi à une doctrine externe sans la reformuler** (ligne 149-150, précédent exact pour le renvoi vers `docs-flow.md`) :
```markdown
Doctrine complète :
`dev-orchestrator-references/mission-cross-team.md` §Étage design (mission dev).
```
Réutiliser cette forme exacte : `` Doctrine complète : `dev-orchestrator-references/docs-flow.md` §<section>. `` — jamais reformuler le contenu de la doctrine dans le manager.

**Pattern de rapport typé D-09** (déjà établi ligne 152-163 §Contrôle de flux) — aucun nouveau format à inventer, `passed`/`gaps_found`/`action: ask-user` existants couvrent le nœud `docs`.

---

### `plugin/design-orchestrator/agents/vf-design-manager.md` (modification)

**Analog:** `vf-dev-manager.md` (même contrat kernel) + précédent exact de renvoi cross-module.

**Le précédent de renvoi dev→design existe déjà en sens inverse** (ligne 119, `mission-cross-team.md` référencé DANS `vf-design-manager.md` alors que le fichier vit dans `dev-orchestrator`) :
```markdown
`dev-orchestrator-references/mission-cross-team.md` §Étage implémentation (mission design).
```
C'est **exactement** le précédent cité par D-01 : le module design renvoie vers une doctrine hébergée dans `dev-orchestrator`, sans copie locale. `docs-flow.md` suit le même chemin de renvoi : `` `dev-orchestrator-references/docs-flow.md` §<section pertinente> ``.

**161 lignes actuelles — marge large (89L sous le plafond 250L)**, contrairement à `vf-dev-manager.md`. La modification (D-11 : mêmes déclencheurs D-08, même nœud `docs` agrégé) peut être plus verbeuse ici sans risque de densité, mais rester symétrique en forme avec le manager dev pour ne pas diverger doctrinalement.

**Frontmatter inchangé** — vérifié par Samuel en CONTEXT.md (D-11) : `tools:` porte déjà `Skill` (ligne 4). Ne pas toucher au frontmatter dans le plan.

**Point d'ancrage dans le fichier** : la section la plus proche pour insérer le nœud `docs` est `## Fin de mission` (lignes 152-161), qui déjà mentionne « décision structurante → consignée » — c'est là qu'ajouter le renvoi au nœud `docs` agrégé, symétrique à `vf-dev-manager.md` §Hygiène documentaire mais casé en fin de mission plutôt qu'en section dédiée (vf-design-manager n'a pas de section « Hygiène documentaire » actuellement — à créer ou fusionner, au choix du plan).

---

### `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` (extension)

**Analog:** lui-même — blocs **T16/T17** (ingestion, lignes ~1250-1291) sont le gabarit le plus proche structurellement (doctrine récente + garde-fous + renvoi AGENT.md + routage intent-routing.md).

**Idiome `ok()`/`ko()`** (lignes 105-106) :
```bash
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
ko()   { echo "  ✗ $1"; fail=$((fail+1)); }
```

**Idiome T16 — garde-fous d'une doctrine référence, à copier pour `docs-flow.md`** (lignes 1258-1272) :
```bash
t16_ok=1
"$GREP" -q "discover-unintegrated-docs.sh" "$IFLOW" || { ko "T16 ingestion : script non nommé dans ingestion-flow.md"; t16_ok=0; }
"$GREP" -q "exit 0" "$IFLOW" || { ko "T16 ingestion : exit 0 non documenté"; t16_ok=0; }
"$GREP" -q "exit 3" "$IFLOW" || { ko "T16 ingestion : exit 3 non documenté"; t16_ok=0; }
"$GREP" -q "exit 64" "$IFLOW" || { ko "T16 ingestion : exit 64 non documenté"; t16_ok=0; }
"$GREP" -q "type: SPEC" "$IFLOW" || { ko "T16 ingestion : schéma manifest (type: SPEC) absent"; t16_ok=0; }
"$GREP" -q "BLOCKER" "$IFLOW" || { ko "T16 ingestion : garde-fou BLOCKER absent"; t16_ok=0; }
"$GREP" -q "ADR-031" "$IFLOW" || { ko "T16 ingestion : garde-fou ADR-031 absent"; t16_ok=0; }
"$GREP" -q -e "--mode merge" "$IFLOW" || { ko "T16 ingestion : garde-fou --mode merge absent"; t16_ok=0; }
"$GREP" -qE "cap 50|50 doc" "$IFLOW" || { ko "T16 ingestion : garde-fou cap 50 absent"; t16_ok=0; }
"$GREP" -q "ingestion-flow" "$AGENT_FILE" || { ko "T16 ingestion : AGENT.md ne renvoie pas vers ingestion-flow.md"; t16_ok=0; }
[ "$t16_ok" -eq 1 ] && ok "T16 ingestion : ingestion-flow.md complet (script, 3 exits, manifest, 4 garde-fous), AGENT.md y renvoie"
```
Nouveau bloc `T19` (nom exact au plan) à écrire **exactement sur ce moule** : une variable `DOCSFLOW="$REFS_DIR/docs-flow.md"`, une série de `"$GREP" -q "<motif>" "$DOCSFLOW" || { ko ...; t19_ok=0; }` pour :
- présence des 4 familles (`gsd-docs-update`, `gsd-map-codebase`, `gsd-extract-learnings`, renvoi `ingestion-flow`) ;
- la ligne rouge `--force` (D-06 : jamais mission, jamais autonome) — motif du type `"$GREP" -qi "force" "$DOCSFLOW"` **et** vérification textuelle que « mission » et « autonome » apparaissent à proximité de l'interdiction (à affiner au plan, contrainte D-14).

**Idiome T17 — boucle de vérification de renvoi vers `AGENT.md` + `vf-dev-manager.md` + `vf-design-manager.md`, gabarit exact pour la triple référence exigée par D-14** (lignes 1274-1291) :
```bash
t17_ok=1
if "$GREP" -q "ingestion-flow" "$AGENT_FILE" \
   && ("$GREP" -q "gsd-ingest-docs" "$AGENT_FILE" || "$GREP" -q "gsd-import" "$AGENT_FILE"); then
  :
else
  ko "T17 routage : AGENT.md sans ligne d'intention d'ingestion explicite"; t17_ok=0
fi
if [ -f "$ROUTING" ]; then
  routing_gsd=$("$GREP" -c "gsd-ingest-docs" "$ROUTING")
  routing_iflow=$("$GREP" -c "ingestion-flow" "$ROUTING")
  { [ "${routing_gsd:-0}" -ge 1 ] && [ "${routing_iflow:-0}" -ge 1 ]; } || { ko "T17 routage : intent-routing.md sans ligne enrichie (gsd-ingest-docs + ingestion-flow)"; t17_ok=0; }
else
  ko "T17 routage : $ROUTING introuvable"; t17_ok=0
fi
[ "$t17_ok" -eq 1 ] && ok "T17 routage : AGENT.md + intent-routing.md câblent l'intention d'ingestion"
```
À décliner pour `docs-flow.md` en vérifiant grep-count > 0 dans `AGENT_FILE`, `MOD/agents/vf-dev-manager.md` ET `$HOME`-équivalent `DESIGN_MOD/agents/vf-design-manager.md` (résoudre `$DESIGN_MOD` comme `$REPO/design-orchestrator` — variable probablement absente du fichier actuel puisqu'il ne teste QUE dev-orchestrator ; à instancier au plan, potentiellement en `skip` si le module design est absent du repo scanné).

**Boucle de référence existante à ÉTENDRE** (ligne 923, D-14 le nomme explicitement) :
```bash
for ref in GSD-PIPELINE.md gsd-skills-index.md intent-routing.md mission-contracts.md; do
  [ -f "$LAB/.claude/agents/dev-orchestrator-references/$ref" ] || { ko "T6 install : references/$ref manquant"; miss=1; }
done
```
Ajouter `docs-flow.md` à cette liste (c'est le test end-to-end d'installation T6, best-effort) — un seul mot ajouté dans le `for ref in ...` (ligne 923).

**Contrat de densité machine-enforced déjà présent** (T8, lignes 958-972) — aucune modification requise mais **rappel de contrainte** : `a_lines=$(wc -l < "$f") ; [ "$a_lines" -le 250 ]` s'applique tel quel à `vf-dev-manager.md` après modification — le plan doit vérifier ce budget AVANT de committer, la suite le fera échouer sinon.

---

## Shared Patterns

### Renvoi vers doctrine externe (jamais de duplication, ADR-057)
**Source:** `plugin/design-orchestrator/agents/vf-design-manager.md:119`, `plugin/dev-orchestrator/references/intent-routing.md:54`
**Apply to:** `docs-flow.md` (renvoi vers `ingestion-flow.md`), `vf-design-manager.md` (renvoi vers `docs-flow.md` hébergé dans dev-orchestrator), `AGENT.md`/`vf-dev-manager.md` (renvoi §Références)
```markdown
Doctrine complète :
`dev-orchestrator-references/<fichier>.md` §<section>.
```

### Chargement on-demand (coût contexte nul)
**Source:** `plugin/dev-orchestrator/references/ingestion-flow.md:1-10`, `intent-routing.md:8-10`
**Apply to:** `docs-flow.md` doit affirmer la même règle dans son encadré de rôle
```
Chargée **on-demand** par `vibeflow-dev`, comme `mission-flow.md` et `GSD-PIPELINE.md` —
coût contexte nul le reste du temps.
```

### Fait vs jugement (ADR-055 §3)
**Source:** `ingestion-flow.md:19-20` (« le script répond au FAIT ... il ne juge jamais »), CONTEXT.md D-08/D-13
**Apply to:** toute table de déclencheurs (D-08) doit qualifier chaque ligne comme un FAIT constatable, jamais un jugement — le pattern rédactionnel est « le script CONSTATE X, l'agent JUGE Y » répété littéralement dans `vf-dev-manager.md:63-68` (gate d'invariants).

### Assertions bash idiomatiques (ok/ko + compteur booléen local)
**Source:** `test-dev-orchestrator.sh:105-106`, blocs T16/T17
**Apply to:** tout nouveau bloc de test — variable `tNN_ok=1`, une série de `grep -q ... || { ko "..."; tNN_ok=0; }`, puis `[ "$tNN_ok" -eq 1 ] && ok "..."` en clôture. Jamais de `exit` immédiat sur un échec individuel — le compteur global `fail` agrège en fin de script.

### Table de signaux/déclencheurs à 2-3 colonnes
**Source:** `AGENT.md:118-124` (Signal / Geste proposé / Confirmation)
**Apply to:** la table D-08 (Déclencheur / Constat) dans `vf-dev-manager.md` et `vf-design-manager.md` suit ce même moule à colonnes courtes — jamais de prose dans les cellules.

## No Analog Found

Aucun fichier de la liste n'est sans analog — les 7 surfaces ont toutes un patron direct ou un
précédent structurel exact dans le module. Seule zone à trancher au plan sans précédent
mécanique : la résolution de `$DESIGN_MOD` dans `test-dev-orchestrator.sh` (le script actuel ne
référence que `dev-orchestrator`, jamais `design-orchestrator` — à instancier en variable neuve
ou en chemin relatif `$REPO/design-orchestrator`, cohérent avec `$MOD="$REPO/dev-orchestrator"`
déjà en tête de script).

## Metadata

**Analog search scope:** `plugin/dev-orchestrator/`, `plugin/design-orchestrator/agents/`
**Files scanned:** `ingestion-flow.md`, `intent-routing.md`, `AGENT.md`, `vf-dev-manager.md`,
`vf-design-manager.md`, `test-dev-orchestrator.sh` (sections 895-1030, 1258-1300)
**Pattern extraction date:** 2026-07-31
