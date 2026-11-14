# Phase 76 : Traçabilité au cockpit — exigences, décisions, mémoire — Recherche

**Recherché :** 2026-11-11 (base `integration/cockpit-audit`, worktree `feat/phase-76-tracabilite`, CONTEXT amendé `74c37166`)
**Domaine :** route de lecture `GET /api/vf/tracabilite` du cockpit + sections de panneau Projet (couche VF, `plugin/cockpit/`), lecture seule
**Confiance :** HAUTE sur les formats et le code présent (mesurés et lus cette session) ; MOYENNE sur les contrats 79 et 80 (branches non fusionnées, lues par `git show`)

Conventions de preuve : `[VERIFIED: fichier:lignes]` = ligne ouverte avec `Read` cette session, valeur citée entre guillemets ; `[MESURÉ: commande]` = comptage rejoué cette session (commande donnée) ; `[CITED: fichier]` = texte d'un CONTEXT d'une autre phase lu par `git show` sans fusion ; `[ASSUMED]` = recommandation ou hypothèse à confirmer (tableau final). Aucun chemin absolu du poste : tous les chemins sont relatifs au dépôt.

<user_constraints>
## User Constraints (from CONTEXT.md)

Le CONTEXT fait foi : `76-CONTEXT.md` (§ Decisions, P76-D-01 à P76-D-29, amendé le 2026-11-11 par `74c37166`). Il n'est pas recopié en entier ici (273 lignes) ; les décisions verrouillées sont rappelées par leur titre exact, sans en rouvrir aucune. Toutes sont « décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée », aucune n'est un arbitrage de Samuel.

### Locked Decisions (titres verbatim)
- P76-D-01 (forme : voisinage en panneaux reliés, pas de canevas) · P76-D-02 (emplacement : `SC.addPanelSection('item'|'overview')`, `SC.showPanel`, jamais `setOverview`, aucune modification de `viewer.html`) · P76-D-03 (navigation : `select(id)`/`reveal(id)` et pile Retour commune de la Phase 80, `VibeFlow.panneau.retour()`, pas de pile propre) · P76-D-04 (trous : glyphe et mot, trait corail seulement pour une contradiction lue) · P76-D-05 (échelle : agréger d'abord, 30 voisins puis « + N autres »)
- P76-D-06 (route à la demande, cache par empreinte, un calcul en vol, `cockpit-project@1` non étendu) · P76-D-07 (schéma `vibeflow/cockpit-trace@1`, `bornes.tronque`) · P76-D-08 (règles C0 de la Phase 79) · P76-D-09 (lecture confinée, git par le seul point durci) · P76-D-10 (commits citants : un passage `git log … --max-count=2000`) · P76-D-11 (rien dans l'export, aucun chemin absolu, `textContent`) · P76-D-12 (dégradation par cas, « Étape N »)
- P76-D-13 (rattachement : table `## Traceability`, à défaut `requirements:` d'un PLAN) · P76-D-14 (maillons lus : plan, SUMMARY, VERIFICATION, recette, avec niveau) · P76-D-15 (contradictions du ledger montrées, jamais corrigées)
- P76-D-16 (corpus : `## ADR-NNN` et définitions des `*-CONTEXT.md`) · P76-D-17 (arêtes lues dans un texte, jamais inférées) · P76-D-18 (extracteur partagé avec la Phase 73, `vf-cockpit-registres.mjs`)
- P76-D-19 à P76-D-23 (mémoire : périmètre git-suivi, champs montrés, liens, trois états distincts, doublon avec `check-method-budget.sh`)
- P76-D-24 (preuves attachées, AUDC-I33) · P76-D-25 (un ajout, un retrait : nœud « Exigences » du graphe Projet) · P76-D-26 (étage design : `76-UI-SPEC.md`) · P76-D-27 (preuves : témoin rouge par exigence, mutants, lab jetable, Chrome à l'exécution seulement) · P76-D-28 (ordre et revalidation) · P76-D-29 (CHANGELOG, aucun bump)

### Claude's Discretion
« Découpage exact en fichiers sous `plugin/cockpit/scripts/` (chaque fichier ≤ 300 lignes, gate V4), numéro des fichiers `ui/`, format interne du cache, libellés exacts dans le cadre de l'UI-SPEC. »

### Deferred Ideas (OUT OF SCOPE)
Registres hors phase (`PU-G-…`, `AUDC-…`, `DEC-…` des labs non-dev) dans le corpus des décisions ; un dessin de l'îlot de mémoire d'un agent (A-2 b) ; une vue plein cadre de la traçabilité du jalon si la Phase 80 ouvre un emplacement de vue enregistrable ; toute écriture (cocher une exigence, réparer un lien).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description (ledger) | Ce que la recherche apporte |
|----|----------------------|------------------------------|
| TRAC-01 | Section « Traçabilité » du panneau d'une phase : bande de quatre maillons, niveau, premier trou | Formats SUMMARY/VERIFICATION/recette mesurés (§ 3), `decompte`/`reste` réutilisables (§ 2), répartition réelle des trous 67-78 |
| TRAC-02 | Contradictions du ledger montrées, jamais corrigées | Vocabulaire libre de la colonne statut (13 premiers mots), 23 cas case/statut, 51 cases sans ligne, 4 lignes sans case (§ 3) |
| TRAC-03 | Vue « Jalon » : une ligne par phase, trous par maillon | `active` non exporté (project.mjs:171) : extraction nécessaire (§ 2, § 11), coût `readPlanning` 513 ms |
| TRAC-04 | Preuves attachées (VERIFICATION, recette, RED-TRACE, SECURITY, VALIDATION, `must_haves`) | Comptes de fichiers de preuve, `must_haves` imbriqué illisible par `fm` (§ 3, § 10) |
| TRAC-05 | ADR et décisions de registre, arêtes lues | 32 ADR (titre `## ADR-NNN :`), 396 lignes de définition, 6 doublons, citations nues (§ 3) |
| TRAC-06 | Commits citants, passage `git log` borné | 4 085 commits / 1 048 citants / 0,12 s / 1,58 Mo de sortie, `--no-renames`, `maxBuffer` (§ 3, § 10) |
| TRAC-07 | Mémoire : périmètre et champs | 277 suivis (268 entrées + 9 index), `metadata.type` imbriqué, `ls-files -o -i` pour l'ignoré (§ 3, § 10) |
| TRAC-08 | Mémoire : liens et états | 399/7/61/32, hors index 0 par égalité exacte, 12 entrées citant un chemin disparu (§ 3) |
| TRAC-09 | Navigation de proche en proche, clavier | API `SC` lue (viewer.html:2555-2563, 1648-1686), contrats 80 (§ 6) |
| TRAC-10 | Route, schéma, C0, cache, un calcul en vol | Modèle `routeGit`, `monoVol`, contrats 79 A10-A13, écarts du code présent (§ 2, § 6) |
| TRAC-11 | Confidentialité et dégradation | Marque blanche, interdits, export, `Étape N` mesuré sur le gabarit (§ 2, § 10) |
| TRAC-12 | Un ajout, un retrait, non-régression | Retrait du nœud `.req` : 5 tests + `vf-cockpit-ask.mjs` touchés (non cités au CONTEXT), compteur de suites 213 (§ 4, § 5) |
</phase_requirements>

## Résumé

La phase est faisable avec ce que le socle fournit déjà : `readPlanning` (phases, dossiers, exigences, jalons), `decompte` et `reste` (appariement PLAN/SUMMARY, ligne `**Statut :`), le point de lecture confiné, `lancerGitAsync`, le modèle de route `routeGit`, et l'API de page `SC.addPanelSection`/`showPanel`. Aucun paquet externe : Node, git et bash suffisent. Tout le travail est de l'extraction de texte (frontmatter imbriqué, tables, identifiants), de l'agrégation et de l'affichage.

Les prémisses chiffrées du CONTEXT tiennent à ±1 près (§ 12), mais la mesure fait ressortir **six écarts que le CONTEXT ne dit pas** et que le planificateur doit traiter : (1) la clé de cache listée au P76-D-06 omet PLAN, SUMMARY, VERIFICATION et recette — le cœur de TRAC-01 — donc un SUMMARY écrit sans commit resterait périmé ; (2) `lireConfine` pose un état de module **synchrone** : un `await` en perd le confinement, il faut lire d'abord (synchrone, 50 ms) puis lancer git (asynchrone) ; (3) le retrait du nœud `.req` (P76-D-25) casse aussi `vf-cockpit-ask.mjs` (réponses locales du chat Projet) et 5 assertions de 2 suites ; (4) `fm()` ne lit que des lignes plates : `metadata.type` des mémoires (268/268) et `must_haves` des PLAN (151/152) sont imbriqués, un lecteur dédié est nécessaire ; (5) `reste()` ne reconnaît que le mot FAITE et que `-RECETTE-HUMAINE.md` ; 3 des 7 fichiers de recette de la phase 61-72 n'ont pas cette forme ; (6) `git ls-files -o --exclude-standard` ne compte pas un `.claude/` ignoré (il faut `-o -i`).

La 79 et la 80 ne sont pas fusionnées. Les plans doivent se brancher sur deux états : le code présent (route en chaîne de `if` dans `vf-cockpit-server.mjs`, contrôles d'accès dans `serve.mjs`, `window.Floorplan` figé) et les contrats amendés (table des routes, fonction de réponse gardée, `VF_ETAT`, `VibeFlow.panneau.retour()`). § 6 donne la façon d'écrire pour les deux.

**Recommandation principale :** un seul module orchestrateur `vf-cockpit-trace.mjs` (route + cache + un vol) qui appelle des fonctions pures par domaine (chaîne d'exigences, registres, mémoire) et un module git asynchrone ; lecture confinée **avant** tout `await` ; clé de cache = sha de HEAD + max des mtime de tout `.planning/`, `docs/ADR.md` et `.claude/agent-memory/` (1 864 fichiers en 13,5 ms) ; trois fichiers `ui/74-vf-trace*.js` marqués `// VibeFlow (` en première ligne et listés `AJOUT` dans `VENDORED.txt` tant que `amont/` existe.

## Architectural Responsibility Map

| Capacité | Tier principal | Tier secondaire | Raison |
|----------|----------------|-----------------|--------|
| Extraction exigences/plan/SUMMARY/VERIFICATION/recette | API / Backend (module du serveur) | — | Lecture de fichiers du lab sous confinement ; la page ne lit jamais `.planning/` |
| Commits citants, chemins disparus | API / Backend (git durci asynchrone) | — | Seul `lancerGitAsync` lance git ; borne et délai côté serveur |
| Cache par empreinte, un calcul en vol | API / Backend | — | État partagé entre requêtes, hors page |
| Garde d'émission, contrôle d'accès | API / Backend | Frontal serveur (`serve.mjs`) | Hôte/Origin/jeton avant `VF.route` ; `porteInterdit` et `no-store` dans le crochet |
| Sections et panneaux, navigation, Retour | Browser / Client (`ui/74-vf-trace*.js`) | — | Seule l'API `SC` ; texte rendu en `textContent` |
| Contrat de forme du schéma | API / Backend | CDN/Static (README, JSON copié dans la sortie) | `vf-cockpit-interface.json` copié à l'identique dans la sortie |
| Retrait du nœud « Exigences » | API / Backend (`vf-cockpit-project.mjs`, `vf-cockpit-ask.mjs`) | Browser (chat) | Le graphe est produit côté serveur ; le chat local lit ce graphe |

## Standard Stack

### Core (réutilisables, tous présents dans `plugin/cockpit/`)

| Brique | Lieu : signature | Contrainte à connaître |
|--------|------------------|------------------------|
| `lireConfine(racine, fn)` | `scripts/vf-cockpit-planning.mjs:21` | `CONFINE` est une variable de module (`:19`) ; posée pendant `fn()` **synchrone**, remise dans `finally`. Un `await` dans `fn` sort du confinement. Hors `lireConfine`, `read`/`lister` ne confinent rien (`dedans = !CONFINE \|\| …`, `:20`) |
| `read(f)`, `lister(d)` | `:23`, `:22` | `read` rend `''` hors confinement, non régulier ou > 8 Mio (`MAX_LECTURE = 8 << 20`, `:17`) ; `lister` rend `[]` ; `ls` interne non exporté (`:24`) |
| `fm(txt)` | `:31` | Lit seulement `^([\w-]+):[ \t]*([^\n]*)$` : valeur vide pour `metadata:` et `must_haves:` (blocs). `list(v)` (`:32`) retire `[`…`]`, coupe sur la virgule |
| `readPlanning(root, layout, opts)` | `:110` | S'enveloppe elle-même dans `lireConfine` si rien n'est posé (`:113`). Rend `{ phases, phaseDirs, reqs, milestones, state, dags, backlog, seeds, tags, projectName, activeKeys, rel }` (`:177`). Option `sansTags` évite l'appel git (`:171`). **513 ms** mesurés ici (87 phases, 488 exigences) |
| `decompte(fichiers)` | `scripts/vf-cockpit-avancement.mjs:25-35` | PLAN fait = `<id>-PLAN.md` ET `<id>-SUMMARY.md` ; SUMMARY sans PLAN = correctif. Appariement par préfixe : c'est la règle d'« apparié à ce plan » de P76-D-14 |
| `reste({ph, fichiers, lire, vivante})` | `:74-86` | Recette : `fs.filter((f) => f.endsWith('-RECETTE-HUMAINE.md')).sort()[0]`, ligne `l.startsWith('**Statut :')`, verdict si `split(/[^\p{L}\p{N}]+/u).includes('FAITE')` (`:78-81`). Phase `done` : `[]` (`:75`) |
| `reExigences()`, `idExigence`, `texteExigence`, `reTraceabilite()` | `scripts/vf-cockpit-formats.mjs:67, 68, 69, 70` | `reTraceabilite` : `^\|…ID…\|…Phase NUM`, drapeaux `gim`, appliqué au **fichier entier** (pas à la seule section `## Traceability`). `normNum` `:10`, `texte` `:11` (BOM, CRLF) |
| `lancerGitAsync(dir, args, {lab, maxBuffer = 4 << 20, binaire, fin})` | `scripts/vf-cockpit-paths.mjs:249-261` | Rend `{ ok, sortie, code, tronque, absent, delai }` (+ `refuse`). `fin = finDans(ms)` (`:177`). `ls-files` est une « sous-commande filtrante » (`:152` : `['status', 'diff', 'ls-files', 'stash']`) : un `git config --get-regexp ^filter\.` part avant, refus au-delà de `MAX_FILTRES = 256` |
| `routeGit(req, res, url, {root, json})` | `scripts/vf-cockpit-git.mjs:207-219` | Modèle : `false` si le chemin n'est pas le sien ; 405 `Allow: GET` ; `.then(r => json(res, 200, r), () => json(res, 200, {schema, etat:'indisponible'}))` ; `catch` rend 200 indisponible |
| `monoVol(cle, lire)` | `vf-cockpit-git.mjs:34-41` | Non exporté. Un appel arrivé pendant une lecture partage UNE lecture suivante. À exporter (zéro ligne) ou recopier le motif |
| `BORNES`, bornes `tronque` | `vf-cockpit-git.mjs:19, 197` | `bornes: { base, nonMergees, tronque: … \|\| j1.commits.length >= BORNES.base \|\| … }` : même sémantique « borne atteinte = tronqué » |
| `porteInterdit(o)`, `INTERDITS` | `scripts/vf-cockpit-server.mjs:33-35` | Constante locale, non exportée. Lit **uniquement** `schemas['vibeflow/cockpit-who@2'].interdits` ; liste vide ou contrat illisible : tout est refusé (`!INTERDITS.length \|\|`). Clés vérifiées à toute profondeur |
| `memeJeton`, `json(res, code, obj)` | `vf-cockpit-server.mjs:38, 78` | `json` pose `'Content-Type': 'application/json', 'Cache-Control': 'no-store'` |
| `nettoie(s, n)` / `masque` / `masqueCoupe` | `vf-cockpit-arbres.mjs:68` / `vf-cockpit-lecture.mjs:62, 68` | `nettoie` retire contrôles et `\p{Cf}`, masque les secrets, borne : à appliquer à tout sujet de commit, nom, titre servi |
| `SC.addPanelSection(where, fn)` | `skills/cockpit-moteur/assets/viewer.html:2555` | `fn(target)` appelée **synchroniquement à chaque `renderPanel`** (`:1661-1672`) ; rend `string` ou `{ html, bind, top }` ; `bind(el)` reçoit le conteneur `[data-ext=i]`. `where` : `'item'` si sélection ou conteneur non racine, `'overview'` à la racine (`:1657`) |
| `SC.showPanel(html, bind)`, `closePanel()` | `viewer.html:2556-2557` | Remplace tout le panneau (`custom.panel`) jusqu'au prochain `select`/`go` (`custom.panel = null`, `:1469, :1527`) : un panneau d'objet ouvert par `showPanel` n'a pas de pile native |
| `SC.select`, `SC.reveal`, `SC.go`, `SC.open`, `SC.refreshPanel`, `SC.on('panel')` | `viewer.html:2528, 2562` | Exportés par `window.Floorplan = Object.freeze({…})` (`:2519`) : **objet gelé**, une extension n'y ajoute rien |

### Supporting
`validate.mjs` (clés requises et typées, `interdits` à toute profondeur) et `mutsub.mjs` (substitution de chaîne dans une copie), tous deux écrits en ligne par `tests/test-cockpit-who.sh:38-66, 398-404` ; `hygiene.sh` (processus) ; `chrome-session.mjs` (`stabiliser`, `attendreEtStabiliser`) ; modèle de suite sans navigateur `tests/test-cockpit-git-details.sh:10-60`. Aide commune `socle-serveur.sh` **de la 79 : absente aujourd'hui** (§ 6).

### Alternatives Considered
| Au lieu de | Alternative | Verdict |
|------------|-------------|---------|
| Étendre `cockpit-project@1` | Route à part | Décidé (P76-D-06) : `project.html` ne grossit pas |
| `buildProjectGraph` pour le jalon actif | `readPlanning` seul + règle extraite | `buildProjectGraph` coûte **6 378 ms** ici (209 nœuds, 1 814 éléments) contre 513 ms pour `readPlanning` : ne jamais l'appeler depuis la route |
| Parseur YAML externe | Lecteur dédié de 30 lignes pour `metadata.type` et `must_haves.truths` | Aucun paquet : formes mesurées stables (§ 3), jamais d'évaluation |

**Installation :** aucune. **Version verification :** `git --version` rend 2.50.1 ; `node --version` rend v26.5.0 sur ce poste (aucune observation de plancher de version dans `module.json` : la CI reste `[ASSUMED]`).

## Package Legitimacy Audit

Aucun paquet externe n'est installé par cette phase (modules `node:fs`, `node:path`, `node:crypto`, `node:child_process` via `lancerGitAsync`). La section est sans objet ; `gsd-tools query package-legitimacy` n'a rien à juger.

**Packages removed due to [SLOP] verdict :** aucun. **Packages flagged as suspicious [SUS] :** aucun.

## Architecture Patterns

### Diagramme de flux

```
page Projet (ui/74-vf-trace*.js)                       serveur du lab (vf-cockpit-server.mjs → route)
  ouverture d'une section / d'un panneau
        │ GET /api/vf/tracabilite?vue=…&cle=…  (jeton en en-tête)
        ▼
  serve.mjs : hôte exact, Origin, jeton (403) ──► VF.route ──► [A10/A11 : table des routes + réponse gardée]
                                                                  │ paramètres : vue ∈ liste fermée, cle ∈ motif strict (400)
                                                                  ▼
                                        empreinte = sha HEAD (git async) + max mtime (.planning, ADR, mémoire)
                                                │ égale à l'entrée en cache ? ──oui──► réponse en cache
                                                │ non / un calcul déjà en vol ? ──► partage du vol
                                                ▼
        1. LECTURE SYNCHRONE sous lireConfine(root) : readPlanning({sansTags}), fichiers de phase,
           docs/ADR.md, CONTEXT, mémoires (lister + read)  ──► fonctions pures (chaîne, registres, mémoire)
        2. GIT ASYNCHRONE (hors confinement, seul point durci) : rev-parse HEAD → git log citants (≤ 2000)
           → ls-files agent-memory → log des suppressions (--no-renames)
        3. assemblage { schema, etat, bornes{tronque}, … } ──► garde porteInterdit (503 emission-refusee)
                                                │
                                                ▼  JSON no-store ──► page : textContent, SC.select(id) pour naviguer
```

### Structure recommandée (découpage, voir § 4 pour les marges)
```
plugin/cockpit/scripts/
├── vf-cockpit-registres.mjs      # pur : ADR (## ADR-NNN) + définitions de CONTEXT (partagé 73/76, P76-D-18)
├── vf-cockpit-trace-chaine.mjs   # pur : exigence → plan → SUMMARY → VERIFICATION → recette, contradictions, preuves
├── vf-cockpit-trace-memoire.mjs  # pur : frontmatter imbriqué, liens, états hors index / sans entrant / chemin absent
├── vf-cockpit-trace-git.mjs      # asynchrone : citants, suppressions, ls-files (lancerGitAsync uniquement)
└── vf-cockpit-trace.mjs          # orchestrateur : empreinte, cache, un vol, routeTrace(req,res,url,{root,json})
plugin/cockpit/skills/cockpit-moteur/assets/ui/
└── 74-vf-trace.js · 74-vf-trace-rendu.js · 74-vf-trace-panneaux.js   # numéro à confirmer au plan (§ 9)
```
Tout fichier nommé `vf-cockpit-*.mjs` est copié dans la sortie par `fichiersExecution` (`vf-cockpit-build.mjs:22, 111`) sans liste à tenir ; il y subit `renommerTexte` (`:117`).

### Pattern 1 : lire d'abord (confiné, synchrone), lancer git ensuite
**Quoi :** toute lecture de fichier du lab dans un seul `lireConfine(root, () => …)` synchrone qui rend des structures ; git vient après, sans `read`. **Pourquoi :** `CONFINE` ne survit pas à un `await` (`planning.mjs:19-21`). Ordre des étapes dans le diagramme.
```js
// [ASSUMED] squelette — noms libres ; voir planning.mjs:21 et paths.mjs:249
const lu = lireConfine(root, () => ({ P: readPlanning(root, undefined, { sansTags: true }), /* + fichiers */ }));
const g = await lancerGitAsync(root, ['rev-parse', '--verify', '--end-of-options', 'HEAD'], { fin });
```

### Pattern 2 : route calquée sur `routeGit`
`routeTrace(req, res, url, { root, json })` rend `false` hors de son chemin ; 405 `Allow: GET` ; validation avant tout calcul ; `.then(json 200, → json 200 { schema, etat:'indisponible' })`. Aujourd'hui : une ligne après `vf-cockpit-server.mjs:116` (`if (routeGit(…)) return true;`). Après la 79 : une ligne de la table (§ 6).

### Anti-patterns
- Appeler `buildProjectGraph` (6,4 s) ou `lireVerrous` depuis la route ; passer `sansTags: true`.
- `git log --all`, `git grep`, ou toute référence non résolue en sha ; sortie de `%B` servie telle quelle.
- Servir un champ nommé `description`, `corps`, `texte`, `fil`, `messages`, `outils`, `doing`, `mandat` à n'importe quelle profondeur : la garde ferme la route entière (503).
- Compter « sans lien entrant » sur les liens d'index (P76-D-22 les exclut).

## Don't Hand-Roll

| Problème | Ne pas écrire | Utiliser | Pourquoi |
|----------|---------------|----------|----------|
| Appariement PLAN/SUMMARY | un second appariement | `decompte` (avancement.mjs:25) | Une seule règle de « plan fait » |
| Statut de recette | une seconde lecture de `**Statut :` | extraire la ligne de `reste` (`:80`) dans une fonction exportée appelée par `reste` ET par la 76 | P76-D-14 : « réutilisée, jamais réécrite » ; `reste` ne lit que `-RECETTE-HUMAINE.md` (§ 3) |
| Motifs d'exigence et de traçabilité | de nouvelles RegExp | `reExigences`, `reTraceabilite` (formats.mjs) | Même grammaire que le diagnostic de dérive |
| Lancement de git | `execFile('git', …)` | `lancerGitAsync` | Environnement durci, `GIT_*` retirés, filtres vidés (paths.mjs:128-146) |
| Garde d'émission | un second contrôle de clés | la fonction de réponse gardée (A11) ; aujourd'hui `porteInterdit` à exporter | Un seul point de refus |
| Nettoyage de texte servi | un échappement maison | `nettoie` (arbres.mjs:68) côté serveur, `textContent` côté page | Masque les secrets, retire les contrôles |

## Runtime State Inventory

Phase de lecture : ni renommage ni migration. **Stored data :** aucune (aucune écriture ; le cache est en mémoire du serveur, rien sur disque). **Live service config :** aucune. **OS-registered state :** aucune. **Secrets/env vars :** aucune nouvelle (jeton de page existant). **Build artifacts :** la sortie `.vibeflow/cockpit/` reçoit les nouveaux `vf-cockpit-*.mjs` à l'assemblage (`vf-cockpit-build.mjs:111`) ; un lab déjà assemblé garde l'ancienne copie jusqu'à la prochaine assemblage (nouvelle assemblage du lab) : une page neuve face à un serveur ancien doit dire « route absente » sans casser (404 → ligne neutre).

## Formats mesurés (tableau)

Mesures sur ce dépôt, base `integration/cockpit-audit` + `76-CONTEXT`. « Périmètre » = `.planning/workstreams/fiabilite/phases` sauf mention. Les scripts de mesure sont des lecteurs Node jetables (frontmatter via `^---\n([\s\S]*?)\n---` après normalisation BOM/CRLF, comme `fm`).

### 3.1 SUMMARY et PLAN

| Objet | Variante | Compte | Commande de mesure |
|-------|----------|-------:|--------------------|
| SUMMARY (tout `.planning`, 413) | frontmatter `requirements: [..]` rempli | 119 | lecteur : ligne `requirements:` du frontmatter |
| | `requirements-completed: [..]` rempli | 139 | idem |
| | `requirements-completed:` **scalaire sans crochets** | 11 | idem (`list()` le lit : split virgule) |
| | `requirements-completed: []` vide | 7 | idem |
| | frontmatter sans champ d'exigence | 52 | idem |
| | **sans frontmatter** | 85 | première ligne ≠ `---` |
| | les deux champs dans un même SUMMARY | 0 | idem |
| SUMMARY (périmètre, 177) | `requirements` 81 · `requirements-completed` 42 + 5 scalaires + 2 vides · sans champ 9 · sans frontmatter 38 | | idem |
| Phases 67-78 (SUMMARY) | 67: 7 `requirements`, 4 sans fm · 68: 10, 9 · 69: 7, 2 · 70: 3 `-completed` + 7, 2 · 71: 17, 16 · 72: 11, 5 · 78: 10 `-completed` + 1 | | idem par dossier |
| SUMMARY sans fm | dont **correctifs sans PLAN** 26/38 ; **appariés à un PLAN** 12 (donc « non lisible » ≠ « manque » : 12 cas réels) | 12 | `decompte` rejoué : 32 SUMMARY sans PLAN, 177 au total |
| PLAN (tout, 411) | `requirements: [..]` rempli 389 · scalaire 8 · vide 2 · sans champ 7 · sans fm 5 | | idem |
| PLAN (périmètre, 152) | `requirements:` inline rempli 152/152 ; `must_haves:` 151 ; `truths:` 151 (1 031 entrées, max 16) ; `artifacts:` 151 ; `key_links:` 149 ; `truths` jamais en ligne `[…]` | | `must_haves` est un bloc imbriqué : **`fm()` rend une valeur vide**, lecteur dédié obligatoire |

### 3.2 Ledger (`REQUIREMENTS.md` du compartiment `fiabilite`)

| Objet | Mesure | Commande |
|-------|--------|----------|
| Cases à cocher (`reExigences`) | **394**, dont 375 cochées | lecteur sur le fichier entier |
| Lignes de traçabilité (`reTraceabilite`, fichier entier) | **347** (le tableau `## Traceability` démarre à la ligne 703 ; d'autres lignes de même forme existent plus bas) | idem |
| Premier mot de la colonne statut | Complete 231 · Done 69 · Planned 19 · Pending 15 · Partial 3 · Livré 3 · Spike, Partiel, Tranché, Superseded, Ouverte, Requalifié, Reportée 1 chacun ; forme `Complete—2026-11-05(PR#203…)` : texte libre après le mot | **vocabulaire non fermé** : classer par préfixe |
| Cas case cochée × statut non-Complete/Done/Livré | **23** (RND-01 « Spike done », DOCF-01..07 « Planned », ICMD-01..12 « Planned », PORT-04, MANI-04, LEDG-03) ; case non cochée × statut Complete : 0 | règle « premier mot ∈ {Complete, Done, Livré} » |
| Cases sans ligne de traçabilité | **51** (PAEX, ARMD, FIDE, RUNT, ROLL, TGT, ADPT, MIGR, HEAD) dont 1 citée par un PLAN ; lignes sans case : **4** | idem |
| Phases 67-72, 71.5, 78 | **93** exigences rattachées par la table ; 92 ont un PLAN du même numéro de phase (`CKPT-12@67` est la seule sans) ; 90 ont un SUMMARY lisible du même numéro | idem |
| Gabarit `planning-core` | `\| REQ-01 \| Étape 1 \| À faire / Fait \|` (`plugin/planning-core/references/templates/REQUIREMENTS.template.md:23-26`) : `reTraceabilite` exige `Phase ` → une ligne « Étape » n'est **pas** lue, l'exigence n'a pas de `phase` | lecture du gabarit |

### 3.3 VERIFICATION, recette, preuves

| Objet | Variante | Compte |
|-------|----------|-------:|
| `*-VERIFICATION.md` (tout `.planning`) | `-VERIFICATION.md` + variantes à suffixe aléatoire | 28 + 9 |
| Périmètre `fiabilite` | fichiers : 41, 57, 58, 60, 69 ; `status:` `passed` 3, `human_needed` 2 ; frontmatter présent 5/5 ; autres clés : `verified`, `score`, `covered_files` (liste ou ligne), `covered_digest`, `behavior_unverified` | 5 |
| Phases 67-78 | VERIFICATION présente : **69 seule** (0 pour 67, 68, 70, 71, 72, 78) → « manque : VERIFICATION » sera le premier trou de 6 phases sur 7 exécutées, c'est attendu | 1/7 |
| Identifiant dans la table de couverture | cellule 1 (`\| CKPT-13 \| … \|` : 16/16 pour la 69) ou autre cellule (`\| 1 \| ARCG-01 marqueur … \|`, 60) ou ligne libre (`\| G2 \| …`, 57) : **balayer toute la ligne de table, mot entier** ; verdict de ligne : `VERIFIED`, `✓ VERIFIED`, `✓ VERIFIED (reprise)`, `PRESENT_BEHAVIOR_UNVERIFIED` → « cité » ≠ « vérifié » | |
| Recette (périmètre) | fichiers : `67/68/69/71-RECETTE-HUMAINE.md`, `70-RECETTE-JUGES.md`, `72-RECETTE-REGLAGES.md`, `61-RECETTE-LAB-REEL.md` ; 78 et 71.5 : aucun | 7 |
| Ligne `**Statut :` (début de ligne) | `**Statut : FAITE — close le …**` (67, 71) · `**Statut : FAITE PAR JUGES — …**` (68) · `**Statut :** CLOSE — déroulée…` (69) · `**Statut : procédure livrée, jamais exécutée…**` (61) · `Statut : recette jouée …` **sans gras** (70) · aucune ligne (72) | 4 / 1 / 1 / 1 / 1 / 1 |
| Preuves (périmètre) | `*-RED-TRACE.md` 74 · `*-VALIDATION.md` 6 · `*-SECURITY.md` 4 · `*-UI-SPEC.md` 2 · `*-REVIEW*` 2 · `*-UAT` 0 | |

### 3.4 Décisions et ADR

| Objet | Variante | Compte |
|-------|----------|-------:|
| `## ADR-NNN : titre` (`docs/ADR.md`, 3 344 lignes) | sections, séparateur « : » | **32** (ADR-046 à ADR-078, **ADR-065 absent**) ; un tableau `## Index` (ID, Date, Titre, Statut) existe aussi |
| ADR citées dans les messages de commit (HEAD) | identifiants distincts | 46 → 14 ou plus **sans section** (`ADR-001`..`045` : « identifiant cité, sans panneau », P76-D-16) |
| `*-CONTEXT.md` du compartiment | fichiers 16 | 16 |
| Définition `- **<ID>` en début de ligne (`^[-*+] \*\*((?:[A-Z][A-Z0-9]*-)*D-\d+[a-z]?(?:bis)?)`) | préfixée `Pnn-D-nn` (14 fichiers, préfixes P57..P62, P67..P72, P76, P78) | **386** |
| | nue `D-nn` (tous dans `41-CONTEXT.md`, dont `D-02bis` et suffixes) | **10** |
| | **même identifiant défini deux fois dans un fichier** (`P78-D-20`, `P78-D-34`, `P71-D-15`, `P60-D-01`, `P59-D-01`, `P59-D-23`) : amendement ou doublon | 6 lignes |
| | identifiants distincts (fichier + ID) | 390 |
| Formes voisines | titres `### … D-nn …` (5 lignes, 2 fichiers) ; `### Arbitrages D-01 à D-08 — SUSPENDUS` (41) | à ne pas lire comme définition |
| Autres compartiments | `gouvernance` (4 CONTEXT), archives `milestones/*-phases/` (31) : hors périmètre de lecture décidé | |

### 3.5 Commits citants (`git log`, HEAD)

| Mesure | Valeur | Commande |
|--------|-------:|----------|
| Commits atteignables | 4 085 | `git rev-list --count <sha>` |
| Citants (ADR ou `<préfixe>-D-nn`) | **1 048** (< 2 000 : borne non atteinte) ; ADR seul 369 ; décisions préfixées 707 | `git log <sha> -E --grep='ADR-[0-9]{3}\|[A-Z][A-Z0-9.]*-D-[0-9]+' --max-count=2000 --format=%H` |
| Durée du passage | 0,12 s (liste de sha) | idem, `time` |
| Taille de la sortie avec corps complets | **1 581 476 octets** ; plus gros message 215 174 o ; `lancerGitAsync` plafonne à `4 << 20` (4 194 304) : marge ×2,6 seulement | `--format='%H%x00%ad%x00%s%x00%B%x1e' --date=short` |
| Base ancienne de la borne 2 000 | le 2000ᵉ commit date du 2026-10-10 ; premier commit 2026-06-03 | `git log --max-count=2000 --format=%ad` |
| `--end-of-options` | accepté (git 2.50.1) ; `git log -E --grep=… --max-count=1 --end-of-options <sha> --` valide | essai |

### 3.6 Mémoire des agents (`.claude/agent-memory/`)

| Mesure | Valeur |
|--------|-------:|
| Fichiers suivis | **277** (9 `MEMORY.md` + **268** entrées), tous `.md`, profondeur agent/fichier ; `agent-memory-local` suivi : 0 ; non suivis : 0 |
| Entrées par agent | vf-dev-manager 131 (index inclus), vf-coder 57, vf-reviewer 48, vf-auditer 19, vibeflow-dev 9, vibeflow-validator 4, vf-design-manager 4, vibeflow-head 3, vf-test-runner 2 |
| Frontmatter | 268/268 : `name`, `description`, `metadata:` (bloc) avec `type:` imbriqué ; **aucun** `type:` à plat. Types : project 146, feedback 117, reference 4, user 1 |
| `name:` ≠ nom de fichier (basename sans `.md`) | **244/268** : la résolution « par `name:` d'abord » n'est pas décorative |
| Liens `[[…]]` bruts / classes POSIX `[[:alpha:]]` | 399 / 7 |
| Dans un passage de code (blocs ou accents graves) | 1 : `[[memory:rtk-fausse-les-verifications-d-etat]]` (forme à préfixe `memory:`, non résolue) |
| Retenus après retrait du code et du POSIX | 391 |
| Résolus par `name:` / par nom de fichier seulement / cassés | 298 / **61** / **32** sur **21** cibles (le « 33 sur 22 » du CONTEXT compte le lien en passage de code) ; aucun `\|`, `#`, `.md`, `/` ou espace de bord dans une cible |
| Cibles cassées les plus fréquentes | `preuve-incapable-de-rendre-rouge` ×6, `liste-de-gates-jamais-la-reference` ×5 |
| Sans lien entrant (index exclus, auto-lien exclu) | **143/268** |
| Hors index | **0** par égalité exacte du nom de fichier d'un lien d'index `](fichier.md)` comme par sous-chaîne (règle `grep -qF` de `check-method-budget.sh:756`) : aucun témoin réel, **le témoin rouge est à fabriquer** |
| Entrées qui citent un chemin du dépôt (motif `(plugin\|docs\|.planning\|.claude\|.github\|scripts\|software-architecture)/…ext`) | 72 entrées, 117 chemins, **25 absents de HEAD**, 19 entrées concernées |
| … absents de HEAD ET présents dans l'historique | 15 chemins, **12 entrées** (ex. `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md` : layout plat, aujourd'hui partitionné) ; **sans `--no-renames`, `--diff-filter=D` ne voit que 64 chemins supprimés (au lieu de 1 179) et ces cas deviennent invisibles** |
| 7 chemins absents jamais présents dans l'historique | à ne pas signaler (P76-D-22 exige « présent dans l'historique lu ») |

### 3.7 Lecture globale
Lire tout ce que la route lit (775 fichiers, 8,7 Mo) prend 49 ms ; statuer 1 864 fichiers 13,5 ms ; `readPlanning` 513 ms (sans tags). La lecture synchrone bloque donc ~0,6 s la boucle, une fois par empreinte : acceptable avec le cache, à écrire sans second passage.

## Découpage en modules et marges

Gate V4 (`scripts/tests/test-cockpit-vendor.sh`) : `for f in "$SCRIPTS"/*.mjs` ≤ 300 lignes ; `AJOUT` `.js`/`.mjs` de `VENDORED.txt` ≤ 300 ; puis `check-file-size.sh` sur **tout** `.mjs`/`.js` de `scripts/` **récursif** (donc `scripts/tests/chrome-*.mjs` compris) et du moteur : avertissement dès 250, blocage au-delà de 300 (`VF_ARCH_WARN`/`VF_ARCH_BLOCK`), marqueur `vibeflow:allow-large-file` dans les 5 premières lignes = dette tracée. Seules les **lignes** comptent : les lignes très longues du dépôt (certaines > 600 caractères) ne sont pas bornées. Les suites `.sh` ne sont pas gatées.

| Fichier (état présent) | Lignes | Marge | Touché par la 76 ? |
|------------------------|-------:|------:|--------------------|
| `scripts/vf-cockpit-server.mjs` | 164 | 136 | +1 ligne de route (aujourd'hui) ou +1 ligne de table (après 79) |
| `scripts/vf-cockpit-project.mjs` | 239 | 61 | retrait du nœud `.req` (`:133, :135-138`) ; **extraction de `active`** (`:171`) si retenue |
| `scripts/vf-cockpit-planning.mjs` | 178 | 122 | oui si on y exporte un lecteur ; sinon non |
| `scripts/vf-cockpit-avancement.mjs` | 104 | 196 | export de la ligne de statut de recette (`:80`) |
| `scripts/vf-cockpit-ask.mjs` | 179 | 121 | retrait/adaptation des lignes `:84, :97, :108, :133, :169` |
| `scripts/vf-cockpit-git.mjs` | 219 | 81 | `export` de `monoVol` (0 ligne) |
| `scripts/vf-cockpit-paths.mjs` | **296** | **4** | **ne pas y toucher** |
| `scripts/vf-cockpit-formats.mjs` | 109 | 191 | non |
| `ui/00-vibeflow.js` | **298** | **2** | **ne pas y toucher** ; `ui/70-vf-live.js` 285 (marge 15) idem |
| `scripts/vf-cockpit-terminal-vue.mjs` | 299 | 1 | hors sujet, rappel du niveau de pression |

Proposition [ASSUMED] (cible ≤ 220 lignes par fichier pour garder 80 lignes de marge au rebase) : `vf-cockpit-registres.mjs` ~120 · `vf-cockpit-trace-chaine.mjs` ~220 · `vf-cockpit-trace-memoire.mjs` ~220 · `vf-cockpit-trace-git.mjs` ~120 · `vf-cockpit-trace.mjs` ~200 ; UI : `74-vf-trace.js` (données, pile, aiguillage) ~180 · `74-vf-trace-rendu.js` (sections) ~220 · `74-vf-trace-panneaux.js` (objets) ~220. Chaque suite Chrome ou `.mjs` d'appoint < 300 lignes (`chrome-equipe-clavier.mjs` en a 292, `chrome-moteur-carte.mjs` 256).

**Marqueurs et inscriptions propres aux fichiers `ui/` neufs :**
- Première ligne `// VibeFlow (…` : sans elle, `MARQUEURS_FR` (`vf-cockpit-fr-inventaire.mjs:124`, motif `^\s*(?:\/\* ui\/[\w.-]+ \*\/\s*)?\/\/ (?:vibeflow:fr|vibeflow:allow-large-file|VibeFlow \()`) compte tout littéral du fichier comme chaîne anglaise et `test-cockpit-chrome-fr.sh` rougit.
- Ligne `AJOUT assets/ui/<fichier>` dans `skills/cockpit-moteur/VENDORED.txt` **tant que `amont/` existe** : `synchro.sh verifier` retire les `AJOUT` listés avant de comparer au manifeste amont (`amont/synchro.sh:98-105`) ; un fichier non listé fait rendre 1 (V6.1). Après la 79 (C6 : `VENDORED.txt` ne garde que l'origine et l'inventaire du plafond) : **à revalider**.
- Écrire `window.Floorplan`, `window.FLOORPLAN_SERVER`, `x-floorplan-token` comme les voisins (`ui/76-vf-git-entete.js:198`, `ui/77-vf-git-tiroir.js:150`) : l'assemblage renomme `Floorplan`→`VibeFlow`, `floorplan`→`vf-cockpit`, `FLOORPLAN`→`VF_COCKPIT` (`vf-cockpit-rename.mjs:12-18`). Le nom **servi** de l'en-tête est donc `x-vf-cockpit-token` (CONFIRMÉ : `serve.mjs:533` lit `x-floorplan-token`), et les tests écrivent le nom servi.
- Chargement : tous les `ui/*.js` triés par nom, injectés en `<script>` (`scripts/build.mjs:447-448`) : l'ordre d'enregistrement des sections `overview` suit l'ordre alphabétique des fichiers.

## Motif de suite et compteurs

**Motif de suite (modèle `tests/test-cockpit-git-details.sh`, `tests/test-cockpit-who.sh`).** Bash `set -uo pipefail` ; `WORK="$(mktemp -d)"` (+ `pwd -P`), `AUX="$WORK/aux"` ; trap qui arrête serveurs et `rm -rf "$WORK"` ; `. "$(dirname "$0")/hygiene.sh"; vf_hyg_init` (marque `tmp.<alnum>` dans la ligne de commande des processus, `vf_hyg_stop`/`vf_hyg_assert`) ; `assert_eq` ; outils Node écrits par la suite dans `$AUX` par `cat > … <<'JS'` (`req.mjs`, `j.mjs`, `validate.mjs`, `mutsub.mjs`) ; git de la suite isolé par emballage de PATH (`GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null`) parce que le serveur retire tout `GIT_*` ; mutant = copie jetable de `"$SCRIPTS"/*.mjs` + `vf-cockpit-interface.json` puis `FROM=… TO=… node "$AUX/mutsub.mjs" <fichier>` (`test-cockpit-who.sh:404`), la sonde rejouée sur la copie doit rougir ; chaque assertion « absent/aucun » est doublée d'un **témoin positif** dans le même lab. Rendu : harnais Chrome sans tête (`chrome-session.mjs`, port éphémère, mesurer « une fois posé »), **à l'exécution seulement** (aucun navigateur ni suite pendant la recherche).

**Découpage de suites proposé [ASSUMED] :** `test-cockpit-tracabilite.sh` (données, route, git, mutants ; sans navigateur) et `test-cockpit-tracabilite-page.sh` (Chrome : sections, panneaux, clavier, `textContent`, 30 voisins, export). Elles sont découvertes par `find plugin scripts -path '*/tests/test-*.sh'`.

**Compteur de suites (deux README).** `scripts/check-version-sync.sh` § 9 (`:131-139`) : `suites_real="$(find "$ROOT/plugin" "$ROOT/scripts" -path '*/tests/test-*.sh' 2>/dev/null | grep -c .)"` ; pour `README.md` et `README.fr.md`, `grep -o '[0-9][0-9]* suites' … | head -1` doit égaler `suites_real`. Aujourd'hui **213** réelles (dont 79 du cockpit) ; chiffre cité `README.md:65` et `README.fr.md:67` (la première mention « N suites » de chaque fichier). Ajouter **k** suites `test-*.sh` = passer les deux README de 213 à 213 + k ; les `chrome-*.mjs` et `projet-commun.sh`/`hygiene.sh` ne comptent pas. **Piège de concurrence :** la 73 annonce 214 (`P73-D-05` : « recompté au rebase de la dernière vague (la 74, la 79 et la 80 le touchent aussi) » `[CITED: 73-CONTEXT]`) : la valeur finale est à **recompter au rebase** avec la commande ci-dessus, jamais écrite d'avance.

**Autres inscriptions.** `scripts/ci-shard-suites.sh` : une suite absente de la table des durées prend `DEFAUT=7` s (`:57-58` du fichier) : aucune ligne obligatoire ; en ajouter une pour la suite Chrome évite un déséquilibre des shards. Zone CI : `plugin/cockpit/**` déjà couvert par le périmètre « module + dépendances citées ». `scripts/check-machine-paths.sh` : aucun chemin absolu de poste dans les fixtures et fabrications de la suite (chemins fabriqués par la suite avec un segment de compte placeholder, énumération fermée du gate). Commit : trailer `Gate-Touche: <chemin> — <raison>` si un plan touche un gate, sa suite (`test-cockpit-vendor.sh`) ou un hook ; mutants : `scripts/ci-mutants-perimetre.sh` ne concerne que le guard de verrou.

## Contrats 79 et 80

Sources : `79-CONTEXT.md` amendement `2ae6607a` (A10 à A13), second amendement `6f66d878` (A15 à A28) ; `80-CONTEXT.md` § Contrats fournis à la Phase 76 (`f10ba2c7`, P80-C76-1 à 4) ; lus par `git show`, **aucune fusion**. La 79 n'est pas exécutée : tout chemin de fonction ci-dessous est « à revalider » après son exécution.

| Contrat | Texte (cité) | Code présent (lu) | Comment écrire pour les deux états |
|---------|--------------|-------------------|-------------------------------------|
| **A10** table des routes alphabétique, plan 79-05, 1ʳᵉ vague | « une route GET `/api/vf/*` s'ajoute par une entrée d'une ligne (chemin, lecteur) … ordre alphabétique » | Chaîne de `if` dans `route()` (`vf-cockpit-server.mjs:80-119`) ; `routeGit` inséré en `:116` | Écrire `routeTrace(req, res, url, { root, json })` **autonome** (même signature que `routeGit`) ; l'insertion = 1 ligne. Une tâche d'insertion, rédigée « à la place alphabétique : après `/api/vf/methode` (77), avant rien d'autre connu » ; voisines : `/api/vf/activite` (75), `/api/vf/ailleurs` (73) |
| **A11** fonction exportée unique : contrôles C0, `porteInterdit`, `no-store`, 503 | « une route neuve l'appelle et ne recopie aucun contrôle » | Hôte exact, `Origin`, jeton (403) : `serve.mjs:525-534`, **avant** `VF.route` ; `porteInterdit` local `server.mjs:35` ; `no-store` dans `json` `:78` ; **le corps `{ "erreur": "emission-refusee" }` n'existe pas** (aucune occurrence dans `scripts/*.mjs` ni `serve.mjs`) ; la garde lit la liste de `who@2` seulement | Isoler `reponseTrace(res, objet)` (calcule la garde, rend 200 ou 503) dans `vf-cockpit-trace.mjs`, qui **appelle** la fonction de la 79 si elle existe, sinon l'équivalent local de 6 lignes à retirer au rebase. **La liste d'interdits propre au schéma** (`description`, `corps`, `texte` en plus des cinq clés, P76-D-07) n'est lue par aucun appel actuel : la tâche doit dire comment la fonction de la 79 la reçoit (paramètre) ; sinon garde locale en plus |
| **A12** lecture confinée = API unique, toute la racine réelle, cachés compris | « change la façon de juger un chemin (résolution physique), pas ce qu'il couvre » | `read`/`lister`/`lireConfine` (`planning.mjs:21-23`) | Appeler **uniquement** ces trois noms depuis un seul module importé (`import { read, lister, lireConfine } from './vf-cockpit-planning.mjs'`) ; si la 79 les renomme, un seul import à changer. Jamais `fs.readFileSync` direct |
| **A13** `VF_ETAT.jeton()`, `VF_ETAT.lireJson(chemin)`, clé `planning` `{seq, at}` | « aucun script de page ne lit le jeton autrement » ; « la 76 relance l'appel ouvert sur cette clé » | Aucun `VF_ETAT` ; les pages lisent `SRV.token` (`window.FLOORPLAN_SERVER`) et envoient `x-floorplan-token` (`ui/77-vf-git-tiroir.js:150`) ; l'événement `structural` **recharge la page Projet** (`ui/70-vf-live.js:281` : « Projet modifié : rechargement », `location.reload`) | Une seule fonction `lire(vue, cle)` dans `ui/74-vf-trace.js` : `window.VF_ETAT?.lireJson ? VF_ETAT.lireJson(url) : fetch(url, { headers: { 'x-floorplan-token': SRV.token } })`. Relance sur `VF_ETAT.abonner('planning', …)` si présent ; sans lui, le rechargement existant suffit |
| **A15-A28** (second amendement) | A25 : rien de l'état entre dans l'export autonome ; A27 : annotateurs de graphe dans `vf-cockpit-build.mjs` | Export : seul l'onglet Code | Cadre de P76-D-11 : témoin d'export dédié |
| **P80-C76-1** `addPanelSection('item'\|'overview', fn)` garde signature et rappel `fn(cible)` à chaque rendu ; une carte de couloir ou une ligne de liste ouvre le même panneau par `select(id)` ; id `ph-<N>` ou `ph-<N>@<ws>` | tenu tel quel | Signature présente `viewer.html:2555` ; `fn(target)` à chaque `renderPanel` (`:1661-1672`) ; côté page l'identifiant porte le préfixe `n:` (`n:ph-72`, voir `00-vibeflow.js:208`, `V.next[].id = 'n:' + phId`) | Accepter `n:ph-<N>[@<ws>]` en entrée de section ; envoyer à la route la forme sans préfixe `ph-<N>[@<ws>]` (motif strict `^ph-\d+(?:\.\d+)?(?:@[\w.-]+)?$`) |
| **P80-C76-2** `setOverview` ne remplace que le corps ; les sections `overview` restent ajoutées après | tenu tel quel | `ext.overview` puis sections (`viewer.html:1655, 1661`) | Rien à écrire : ne jamais appeler `setOverview` |
| **P80-C76-3** pas de `SC.openNode` : `select(id)` / `reveal(id)` ; Retour par la pile **commune** `VibeFlow.panneau.retour()`, bouton « Retour » dans l'en-tête du panneau | tenu sous une autre forme | `select`, `reveal` exportés (`viewer.html:2528`) ; **aucune pile Retour** ; `window.Floorplan` est `Object.freeze` (`:2519`) : une extension n'y ajoute pas `panneau` | Naviguer **seulement** par `SC.select(id)` (empiler = laisser la 80 observer la sélection) ; un panneau d'objet non-nœud (ADR, décision, mémoire) n'a pas d'id de nœud : voir Q1 (§ 11). Ne tester `VibeFlow.panneau?.retour` qu'avec repli sans Retour ; **où vit `panneau` (objet gelé) est à revalider après la 80** |
| **P80-C76-4** `piedExigences` reste le « x/y exigences » ; champ `exigences {faits,total}` ajouté par la 80, même calcul | tenu tel quel | `piedExigences` `project.mjs:48-53` | Le retrait (P76-D-25) garde `piedExigences` et ne recalcule rien |
| **Séquence** | « les plans de la 76 qui se branchent sur le panneau dépendent de la **80 exécutée** » | | Vagues du plan : (1) modules purs et route (après 79 vague 1 : table et fonction), (2) UI (après la 80), (3) retrait `.req` + README/CHANGELOG + compteur |

Autres points des contrats consommés par la 76 : C0 « Versions » : ajouter un champ facultatif à un schéma ne change pas sa version ; un schéma neuf `@1` est libre. C6-1 : `amont/` retiré en 1ʳᵉ vague de la 79 : pas de diff à régénérer ; **avant**, un fichier moteur modifié exige un diff (la 76 n'en modifie aucun).

## Fichiers partagés et revalidations

| Fichier | Autres phases | Risque / revalidation après leur exécution |
|---------|---------------|---------------------------------------------|
| `scripts/vf-cockpit-server.mjs` | 79 (table, réponse gardée), 73 (`/api/vf/ailleurs`), 75 (`/api/vf/activite`), 77 (`/api/vf/methode`) `[CITED: 73, 75, 77-CONTEXT]` | Une ligne de route par phase ; revérifier le nom de la fonction de réponse gardée et sa façon de recevoir une liste d'interdits |
| `scripts/vf-cockpit-interface.json` | 73 (`ailleurs@1`, description d'`equipe@1`), 74 (`frise@1`), 75 (`activite@1`), 77, 79 (`state@1`, `index`) | Conflits de fusion sur `schemas` : ajouter `vibeflow/cockpit-trace@1` en **fin** de bloc ou en place alphabétique ; relancer `validate.mjs` sur la sortie réelle |
| `scripts/vf-cockpit-project.mjs` | 77 (retire `lastDesc`), 80 (champ `exigences`), 76 (retire le nœud `.req`, `:133, 135-138`) | Trois retraits dans le même fichier : revalider les numéros de ligne ; `piedExigences` doit rester appelé par la carte de phase |
| `scripts/vf-cockpit-planning.mjs` | 79 (renomme `lireConfine`/`read`/`lister` peut-être) | Un seul import côté 76 |
| `scripts/vf-cockpit-ask.mjs` | aucune annoncée | Voir Q2 : la 76 est seule à le retoucher, mais la 80 réécrit le panneau Projet : relire l'impact |
| `ui/` (numéros) | 73 (`70`, `72`, `76`, `78-80`), 75 (`25`, `70`, `78`, `79`, `80`), 77 (`00`, `20`, `25`, `75` en lecture), 80 (`00`, `70`, `73`, `75`, `76`, `77`, `78-80`) ; fichiers neufs de 73/74/75/77/80 : numéros non fixés dans leurs CONTEXT | Vérifier `ls ui/` sur la base portant 79 et 80 avant de fixer `74-vf-trace*` (aujourd'hui `70 71 72 73 75 76 77×3 78 79 80` : **74 est libre**) |
| `ui/78-vf-fr-dict-a.js`, `79-…-b`, `80-vf-fr.js` | toutes | Non touchés : les fichiers à marqueur `// VibeFlow (` sont exclus de l'inventaire anglais. La 80 écrit « tout libellé neuf passe par le dictionnaire français » : à confirmer contre `test-cockpit-chrome-fr.sh` après la 79 (traduction en vague 3) |
| `viewer.html`, `40-tour.js`, `05-theme.js` | 79 (vague 3), 80 | La 76 ne les modifie pas (P76-D-02) ; vérifier qu'aucun diff de la 76 ne les touche |
| `README.md` (module), `CHANGELOG.md` § Non publié, README racine (compteur) | toutes | Ajouter, ne pas réécrire ; compteur recompté au rebase |
| Extracteur de registres | 73 (aucun module de ce nom dans son CONTEXT : sa S-3 reporte « les arbitrages écrits dans les CONTEXT » en BACKLOG) | **Constat :** la 73 ne livre pas d'extracteur ; la 76 crée `vf-cockpit-registres.mjs` et l'écrit « À verser par la jointure » ; si la 73 en pose un, l'importer |
| `plugin/cockpit/scripts/tests/` | toutes | Nouvelles suites : numérotation libre, mais compteur et shards |

À revalider à l'exécution des plans, contre la base portant 79 et 80 (P76-D-28) : (1) nom et emplacement de la fonction de réponse gardée et de la table de routes ; (2) `VF_ETAT.*` et sa clé `planning` ; (3) `VibeFlow.panneau.retour` (existence, lieu) ; (4) le comportement de `renderPanel` après la 80 (sections appelées à chaque rendu, absence de rechargement de page) ; (5) `VENDORED.txt` et V6/V7 ; (6) le jeton d'en-tête côté page ; (7) numéros `ui/` ; (8) compteur de suites ; (9) lignes de `project.mjs` retirées par 77 et 80.

## Validation Architecture

### Test Framework
| Propriété | Valeur |
|-----------|--------|
| Framework | Bash (`assert_eq`) + harnais Node écrits dans `$AUX` ; mutants par copie + `mutsub.mjs` ; Chrome sans tête via `chrome-session.mjs` (exécution seulement) |
| Fichier de config | aucun ; aide commune `plugin/cockpit/scripts/tests/socle-serveur.sh` **livrée par la 79 (plan 79-02) : absente aujourd'hui** `[CITED: 79-CONTEXT A6]` |
| Commande rapide | `bash plugin/cockpit/scripts/tests/test-cockpit-tracabilite.sh` |
| Suite complète | `bash plugin/cockpit/scripts/tests/test-cockpit-tracabilite-page.sh` puis `bash plugin/cockpit/scripts/tests/test-cockpit-vendor.sh`, `bash scripts/check-version-sync.sh`, et les suites touchées par le retrait (`test-cockpit-projet-graphe.sh`, `test-cockpit-questions.sh`) |

Règle commune : chaque témoin rouge est **joué avant le code** (la suite rougit : route 404 ou fonction absente) puis verdit ; chaque assertion négative a son témoin positif dans le même lab fabriqué (ledger, dossiers de phase, ADR, registres, commits citants fabriqués par `git commit` dans le lab, mémoire avec liens cassés, hors index et chemin disparu). Le lab doit contenir le cas qui fait rougir **et** le cas voisin qui ne le doit pas.

### Phase Requirements → Test Map (témoin rouge par exigence)

| Req | Témoin rouge (cas qui doit rougir) | Mutant (doit rougir la sonde) | Commande |
|-----|------------------------------------|-------------------------------|----------|
| TRAC-01 | Lab : REQ-A (ligne de traçabilité + `requirements:` d'un PLAN + SUMMARY `requirements-completed:` scalaire sans crochets), REQ-B (rattachée **seulement** par le PLAN), un SUMMARY sans frontmatter apparié à un PLAN, pas de VERIFICATION : la ligne de REQ-A dit « manque : VERIFICATION » avec ses quatre glyphes ; SUMMARY sans fm = « non lisible », jamais « manque » ; niveau exigence vs phase distingués | M-SUMMARY-CLE (ne lire que `requirements:`), M-NIVEAU (toujours « exigence »), M-NONLISIBLE (traiter sans fm comme absent) | `bash …/test-cockpit-tracabilite.sh` (sections T1.x) |
| TRAC-02 | Lab des quatre contradictions : case cochée sans SUMMARY, case non cochée avec SUMMARY, ligne de traçabilité sans exigence, exigence sans ligne ; plus une **absence simple** voisine : les quatre portent le drapeau « contradiction », l'absence simple non ; `sha256` de tous les fichiers du lab identiques avant/après (jamais corrigé) | M-ABSENCE-ROUGE (classer l'absence simple en contradiction), M-ECRITURE (une écriture dans `.planning/` rougit le contrôle de hachage) | idem (T2.x) |
| TRAC-03 | Lab à deux jalons : le jalon actif porte 3 phases, un autre jalon 1 ; comptes de trous par maillon exacts ; la ligne porte l'id `ph-<N>[@<ws>]` ouvrable ; témoin positif sur le dépôt réel (jalon `vibeflow-v2.0`) | M-AUTRE-JALON (compter toutes les phases) | idem (T3.x) |
| TRAC-04 | Lab : phase avec VERIFICATION (`status: passed`), recette `**Statut : FAITE`, `*-RED-TRACE.md`, `*-SECURITY.md`, `*-VALIDATION.md`, PLAN `must_haves.truths` de 3 lignes : chaque fichier en lien relatif, `status` lu, 3 critères comptés et listés ; fichier absent = pas de lien ; aucun corps servi | M-CORPS (servir le texte d'un fichier : la garde `texte`/`corps` ferme la réponse), M-DEDUIT (créer un lien non lu) | idem (T4.x) |
| TRAC-05 | Lab : `docs/ADR.md` à 2 sections + une ADR citée sans section ; CONTEXT avec `P90-D-01` défini deux fois (amendement) et une `D-04` nue ; commits citant `ADR-001`, `P90-D-01` et « D-04 » : une seule entrée par identifiant, ADR sans section = « cité, sans panneau », `D-04` qualifiée « D-04, Phase 90 », **aucun commit relié à la nue** | M-NUE-RELIEE (relier la nue aux commits), M-DOUBLON (deux entrées) | idem (T5.x) |
| TRAC-06 | Lab git jetable : 5 commits citants (corps avec identifiants) ; la réponse porte sha court, jour, sujet nettoyé, **aucun corps** ; avec une borne abaissée par injection de test, `bornes.tronque: true` ; git muet (emballage `sleep`) → `tronque`/indisponible, jamais « complet » ; argv journalisé par un git factice : jamais `--all`, présence de `--end-of-options` et `--`, référence = sha de 40 | M-ALL (`--all`), M-BORNE (retirer `--max-count`), M-CORPS-SERVI, M-NOREF (ref non résolue) | idem (T6.x) |
| TRAC-07 | Lab : mémoire suivie (2 agents), un `agent-memory-local/` suivi ou non, `description` unique repérable : la réponse a `name`, agent, `metadata.type`, jour, liens entrants/sortants, chemins absents relatifs ; **aucune** occurrence de la description, du corps, de `~/` ni d'un chemin absolu (corps contenant un chemin absolu de poste fabriqué) ; lab avec `.claude/` **ignoré** : état vide + nombre de fichiers non suivis (par `ls-files -o -i --exclude-standard` ou `lister`), sans noms | M-DESCRIPTION (servir `description` : 503), M-LOCAL (lire `agent-memory-local`), M-NOMS (nommer les non suivis) | idem (T7.x) |
| TRAC-08 | Lab mémoire : `[[x]]` en bloc et en accents graves ignorés ; `[[:alpha:]]` ignoré ; résolu par `name:` ≠ nom de fichier ; résolu par nom de fichier **compté à part** ; cassé ; **hors index** par égalité exacte avec `a.md` et `aa.md` dont l'index ne cite que `aa.md` (hors index pour la 76, présent pour une sous-chaîne) ; « sans lien entrant » sans compter l'index ; « cite un chemin absent » avec un fichier supprimé **et un renommé** (`git mv`) ; chemin jamais présent non signalé ; aucun champ « périmée » | M-SOUSCHAINE (règle `grep -qF`), M-CODE (ne pas retirer le code), M-RENAMES (sans `--no-renames`), M-DATE (verdict par la date) | idem (T8.x) |
| TRAC-09 | Chrome : le panneau d'une phase porte la section ; un clic sur un voisin appelle `SC.select(id)` ; Tab parcourt les liens dans l'ordre, Échap ferme ; **31 voisins → 30 + « + 1 autre »** ; aucun `<canvas>`/`<svg>` de nœuds ajouté par la phase ; trois onglets ; `git diff` de `viewer.html` vide ; `setOverview` jamais appelé (grep statique) | M-PLAFOND (retirer le plafond 30), M-SETOVERVIEW | `bash …/test-cockpit-tracabilite-page.sh` (C1.x) |
| TRAC-10 | Serveur de test : sans jeton 403, Host faux 403, Origin étrangère 403, POST 405, `vue=zzz` 400, `cle` hors motif (`../x`, `ph-1;ls`, 300 car.) 400 ; JSON `no-store` ; chaque champ de la réponse est déclaré au contrat (`validate.mjs`) ; objet portant `corps` → 503 `{"erreur":"emission-refusee"}` ; contrat illisible (copie sans `interface.json`) → 503 ; **deux requêtes simultanées = un seul `git log`** (compteur d'un git factice) ; seconde requête identique = 0 lancement ; **un SUMMARY modifié à HEAD constant provoque un recalcul** (témoin du trou de la clé de cache) | M-JETON (`===`), M-GARDE (retirer `porteInterdit`), M-CLE (assouplir le motif), M-VOL (retirer le partage), M-EMPREINTE (clé = HEAD seul), M-BORNE | idem (T10.x) |
| TRAC-11 | Lab marqueur : une chaîne unique dans une ADR et dans une mémoire est **absente** de l'export (`60-export`) et d'une page autonome (témoin positif : la chaîne est lue par la route) ; ADR citant un chemin absolu de poste fabriqué : aucun chemin absolu ni `~/` dans la réponse ; titre d'ADR `<img onerror=…>` rendu en texte (Chrome, `textContent`) ; **cinq labs dégradés** (sans `docs/ADR.md`, sans compartiment, sans mémoire, sans git, traçabilité « Étape N » du gabarit) : une ligne neutre par cas, 200, rien ne casse ailleurs | M-EXPORT (ajouter la donnée à l'export), M-INNERHTML, M-ABSOLU | idem (T11.x, C11.x) |
| TRAC-12 | Graphe Projet du lab : aucun nœud `kind: 'exigences'`, aucun `req/…`, aucun lien « couvre » ; le pied `x/y exigences` reste ; **réponses locales du chat** (« exigences de la phase N », « REQ-01 ») : à rebaser sur la décision de Q2 ; ligne au `CHANGELOG.md` § Non publié ; `bash scripts/check-version-sync.sh` vert avec le nouveau compteur ; toutes les suites cockpit vertes (macOS, Linux en CI) | M-RETRAIT (rétablir le nœud : P1.4 rougit), M-COMPTEUR (ne pas bumper : `check-version-sync` rougit) | `bash …/test-cockpit-projet-graphe.sh && bash …/test-cockpit-questions.sh && bash scripts/check-version-sync.sh` |

### Sampling Rate
- **Par commit de tâche :** `bash plugin/cockpit/scripts/tests/test-cockpit-tracabilite.sh`
- **Par fusion de vague :** suites touchées (`test-cockpit-projet-graphe.sh`, `test-cockpit-questions.sh`, `test-cockpit-vendor.sh`, `test-cockpit-chrome-fr.sh`, `test-cockpit-serveur.sh`, `test-cockpit-confinement.sh`) + `check-version-sync.sh`
- **Gate de phase :** toutes les suites `plugin/cockpit/scripts/tests/test-*.sh` vertes avant `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `plugin/cockpit/scripts/tests/test-cockpit-tracabilite.sh` — TRAC-01, 02, 03, 04, 05, 06, 07, 08, 10, 11
- [ ] `plugin/cockpit/scripts/tests/test-cockpit-tracabilite-page.sh` + `chrome-tracabilite.mjs` — TRAC-09, 11
- [ ] Fabrication du lab (aux Node ou bloc `cat > … <<'JS'` de la suite) : ledger, dossiers de phase, ADR, CONTEXT à doublon, commits citants, mémoire (liens cassés, hors index `a.md`/`aa.md`, fichier supprimé et renommé)
- [ ] Mise à jour des assertions retirées : `test-cockpit-projet-graphe.sh:58` (P1.4), `:135` (P5.3), `:352` (R1.9), `:416` (R2.9) ; `test-cockpit-questions.sh:270-272, 287, 330-331`
- [ ] Framework : aucun à installer

## Security Domain

| Catégorie ASVS | S'applique | Contrôle standard |
|----------------|-----------|-------------------|
| V2 Authentification | non (jeton de page existant) | — |
| V3 Session | non | — |
| V4 Contrôle d'accès | oui | hôte exact, `Origin`, jeton comparé par `memeJeton` (temps constant, `server.mjs:38`) ; GET seul ; route absente hors module |
| V5 Validation d'entrée | oui | `vue` liste fermée ; `cle` motif strict (`^ph-…`, `^ADR-\d{3}$`, `^P[\w.]+-D-\d+$`, mémoire par chemin relatif validé) → 400 ; aucune RegExp construite depuis une valeur du lab (règle T-69-08 de `avancement.mjs:38`) |
| V6 Cryptographie | non | — |
| V7/V8 Données | oui | `nettoie`/`masque` sur tout texte servi ; clés interdites refusées par la garde ; aucun chemin absolu ni `~/` ; description et corps de mémoire jamais servis |
| V12 Fichiers | oui | lecture confinée à la racine réelle ; liens symboliques sortants jamais suivis ; `MAX_LECTURE` 8 Mio |

| Menace | STRIDE | Mitigation |
|--------|--------|------------|
| Contenu de fichier du lab injecté dans la page (ADR, mémoire, sujet de commit) | Tampering / XSS | `textContent` côté page, `nettoie` côté serveur ; suite Chrome (C11.x) |
| Fuite de la description ou du corps d'une mémoire | Information disclosure | clés `description`, `corps`, `texte` dans `interdits` ; exclusion testée par mutant |
| Lecture hors du lab par lien symbolique | Elevation | `lireConfine` ; lecture avant tout `await` ; test de confinement existant à étendre |
| Dépôt leurre (`GIT_DIR`, `core.fsmonitor`) | Tampering | `lancerGitAsync` seul (`envGit`, `GIT_SUR`) ; jamais `--all` |
| Déni de service par `git log` ou lecture massive | DoS | `--max-count=2000`, `fin = finDans(…)`, `maxBuffer`, un calcul en vol, cache par empreinte, `bornes.tronque` |
| Lecture réseau | — | aucune (P67-D-02, P78-D-05) |

## Common Pitfalls

### Pitfall 1 : le confinement ne survit pas à un `await`
**Quoi :** `lireConfine(root, fn)` pose `CONFINE` pendant `fn()` synchrone et le remet aussitôt (`planning.mjs:19-21`). Une lecture après un `await` est **non confinée** (`dedans` vrai si `CONFINE === null`, `:20`). **Éviter :** une phase de lecture synchrone qui rend des objets, puis git. **Signe :** un témoin de confinement (lien symbolique sortant) qui passe en test unitaire mais pas via la route.

### Pitfall 2 : clé de cache incomplète
**Quoi :** P76-D-06 liste HEAD + `docs/ADR.md` + `*-CONTEXT.md` + ledger + `.claude/agent-memory/`, mais ni PLAN, SUMMARY, VERIFICATION, recette, preuves (le cœur de TRAC-01/03/04), ni les fichiers non commités ; et le mtime d'un **dossier** ne change pas quand un fichier y est modifié. **Éviter :** max des mtime (fichiers, pas dossiers) de `.planning/` + `docs/ADR.md` + `.claude/agent-memory/` + sha de HEAD : 1 864 fichiers en 13,5 ms. **Témoin :** T10.x « SUMMARY modifié à HEAD constant ».

### Pitfall 3 : `fm()` est plat
`metadata.type` (268/268) et `must_haves.truths` (151/152) sont imbriqués ; `fm` rend `''`. Écrire un lecteur de blocs indentés borné (jamais d'évaluation YAML). 85 SUMMARY n'ont aucun frontmatter : « non lisible ».

### Pitfall 4 : vocabulaire de recette et de statut
`reste()` ne reconnaît que `FAITE` et que `-RECETTE-HUMAINE.md` : `69` dit `**Statut :** CLOSE`, `70` `Statut : recette jouée` (sans gras), `72` n'a pas de ligne, `61` dit « procédure livrée, jamais exécutée ». Trois états distincts à servir : « faite », « lue, non faite », « non lisible » ; le niveau « phase » vs « exigence » par identifiant cité. La colonne statut du ledger a 13 premiers mots : classer par préfixe, jamais par égalité.

### Pitfall 5 : `.claude/` ignoré invisible à `ls-files -o --exclude-standard`
Vérifié sur un lab jetable : avec `.claude/` dans `.gitignore`, `git ls-files -o --exclude-standard -- .claude/agent-memory` rend 0, `-o -i --exclude-standard` rend 1. `check-method-budget.sh` utilise la première forme (`:744`). Pour « le nombre de fichiers non suivis » de P76-D-19, prendre `-o -i` ou `lister`.

### Pitfall 6 : `--diff-filter=D` et les renommages
Sans `--no-renames`, les chemins déplacés ne comptent pas comme supprimés : 64 chemins vus au lieu de 1 179. La borne `--max-count` s'applique aussi à ce passage : le 2 000ᵉ commit date du 2026-10-10 ici ; un chemin supprimé avant n'est pas vu → à dire dans `tronque` ou borner à part (Q4).

### Pitfall 7 : `maxBuffer`
Les corps complets des 1 048 citants pèsent 1,58 Mo pour un plafond de `4 << 20` ; à 2 000 citants ≈ 3 Mo. Dépassement → `tronque: true` côté `lancerGitAsync` (`ERR_CHILD_PROCESS_STDIO_MAXBUFFER`) : le dire, ou passer `maxBuffer` explicite, ou extraire par `--format` plus court (`%s` + `%b` borné n'est pas possible : il faut le corps pour les identifiants).

### Pitfall 8 : la garde ferme la route entière
`porteInterdit` refuse une clé interdite à toute profondeur ; une seule clé `texte`, `description`, `corps`, `fil`, `messages`, `outils`, `doing` ou `mandat` dans un objet de réponse (même un champ d'ADR) donne 503 pour tout le monde. Nommer les champs (`libelle`, `sujet`, `resume`…). Aujourd'hui la liste lue est celle de `who@2`, pas celle du schéma de la 76.

### Pitfall 9 : marque blanche et inventaire français
Les modules sont renommés à l'assemblage (`floorplan` → `vf-cockpit`) : jamais le mot « floorplan » dans un texte servi ou testé tel quel ; l'en-tête servi est `x-vf-cockpit-token`. Les fichiers `ui/` neufs : `// VibeFlow (` en première ligne, ligne `AJOUT` dans `VENDORED.txt` tant que `amont/` existe, ≤ 300 lignes.

### Pitfall 10 : le retrait du nœud `.req` casse le chat local
`vf-cockpit-ask.mjs` lit `G.files` à `req/<ID>` (`:84, :97`), `I.files.get(phase.id + '.req')` (`:133`), `exigPhaseFaite` sur `/\.req$/` (`:108`) et l'invite de l'agent cite `n:ph-<N>.req` et `f:req/<ID>` (`:169`). Sans ce nœud, « exigences de la phase N » et « REQ-01 ? » ne répondent plus localement (retombée sur l'agent). 5 assertions de 2 suites visent le nœud (§ 12). La décision n'est pas rouverte : c'est un **périmètre de retrait plus large** que celui écrit au CONTEXT (Q2).

### Pitfall 11 : identifiants de phase
`ph-<N>` ou `ph-<N>@<ws>` quand le numéro existe dans plusieurs compartiments (`project.mjs:76`, `count.get(ph.n) > 1 && ph.ws`) ; la règle est déjà recopiée dans `vf-cockpit-lancer-cibles.mjs:104`. Côté page l'id porte `n:`. Ici `ph-36` (compartiment fiabilité) coexiste avec `ph-46`…`ph-50` (gouvernance) : un `cle` ambigu doit rendre 400 ou une liste, jamais un choix.

### Pitfall 12 : `showPanel` perd la sélection, `Object.freeze` interdit l'ajout
`showPanel` pose `custom.panel` jusqu'au prochain `select`/`go` ; un panneau d'ADR ou de mémoire n'a pas de nœud. Pas de pile native : ne pas en bâtir une (P76-D-03 amendé) ; `window.Floorplan` est gelé : `panneau.retour` n'existe pas tant que la 80 n'a pas livré.

### Pitfall 13 : concurrence des numéros et des compteurs
Fichiers `ui/` et compteur de suites : valeurs à fixer au rebase, pas au plan. Chaque phase annonce son propre bump (73 : 214).

### Pitfall 14 : rattachements ambigus et doublons
Six identifiants de décision définis deux fois dans un fichier (amendement) : garder la première définition et marquer l'amendement. ADR-065 n'a pas de section. La forme `[[memory:nom]]` existe (une fois, en code).

## Code Examples

Motifs sûrs, sources lues :

```js
// Source : plugin/cockpit/scripts/vf-cockpit-git.mjs:207-219 (modèle de route, à décalquer)
export function routeGit(req, res, url, { root, json }) {
  if (p !== '/api/vf/git' && !p.startsWith('/api/vf/git/')) return false;
  if (req.method !== 'GET') { res.writeHead(405, { Allow: 'GET' }); res.end(); return true; }
  lireGit(root).then((r) => json(res, 200, r), () => json(res, 200, { schema: SCHEMA, etat: 'indisponible' }));
}
```
```js
// Source : plugin/cockpit/scripts/vf-cockpit-paths.mjs:249-261 — appel de git borné et résolu en sha (squelette [ASSUMED])
const ref = (await lancerGitAsync(root, ['rev-parse', '--verify', '--end-of-options', 'HEAD'], { fin })).sortie.trim();
const citants = await lancerGitAsync(root, ['log', '-E', '--grep=ADR-[0-9]{3}|[A-Z][A-Z0-9.]*-D-[0-9]+', '--max-count=2000',
  '--format=%H%x00%ad%x00%s%x00%B%x1e', '--date=short', '--end-of-options', ref, '--'], { fin, maxBuffer: 8 << 20 });
// citants.tronque ou citants.delai → bornes.tronque = true ; le corps (%B) ne sert qu'à extraire les identifiants puis est jeté
```
```js
// Source : mesure de cette recherche — suppressions vues avec renommages comptés (squelette [ASSUMED])
['log', '--no-renames', '--diff-filter=D', '--name-only', '--format=', '--max-count=…', '--end-of-options', ref, '--']
```

## State of the Art

| Ancien | Actuel | Quand | Impact |
|--------|--------|-------|--------|
| Chaîne de `if` dans `route()` | Table des routes alphabétique + fonction de réponse gardée | 79, plan 79-05 (1ʳᵉ vague) | La 76 s'y ajoute par une ligne ; à revalider |
| Rechargement de la page Projet sur `structural` | `VF_ETAT` clé `planning`, onglets sans rechargement | 79 + 80 | La page relance l'appel ouvert au lieu de se recharger |
| Pile propre aux panneaux de la 76 | Pile de sélections commune `VibeFlow.panneau.retour()` | Amendement `74c37166` | Pas de pile locale |
| `amont/` + `AJOUT` obligatoires | Appareil de patchs retiré | 79, vague 1 | Ligne `AJOUT` à retirer du plan si `amont/` a disparu |

**Obsolète pour cette phase :** nœud « Exigences » du graphe (retiré par la 76), canevas pour la traçabilité (écarté), `lastDesc` (retiré par la 77).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | La fonction de réponse gardée de la 79 accepte (ou acceptera) une liste d'interdits propre au schéma ; sinon la 76 ajoute une garde locale pour `description`, `corps`, `texte` | Contrats 79 | Trois clés non gardées : fuite possible de contenu |
| A2 | `VibeFlow.panneau` sera accessible à la 76 malgré `Object.freeze(window.Floorplan)` (la 80 modifie `viewer.html` ou l'expose ailleurs) | Contrats 80 | Pas de Retour commun ; la 76 se limite à `select` |
| A3 | Le numéro `74` reste libre pour `ui/74-vf-trace*.js` au rebase | Fichiers partagés | Collision de nom avec 73/74/75/77/80 |
| A4 | Un panneau d'objet non-nœud (ADR, décision, mémoire) s'ouvre par `showPanel` et son retour s'appuie sur `select` du nœud d'origine, faute d'id de nœud | Contrats 80 / Q1 | Retour absent pour ces objets |
| A5 | La CI Linux fournit `git` ≥ 2.24 (`--end-of-options`) et Node récent ; le module ne déclare pas de plancher | Standard Stack | Rouge CI Linux seulement |
| A6 | Découpage en cinq modules purs/asynchrones et trois fichiers UI, et noms de suites `test-cockpit-tracabilite*` | Découpage, Motif de suite | Libres (discrétion de Claude), à ajuster au plan |
| A7 | `ls-files` passant par le contrôle de filtres du dépôt (`config --get-regexp`) reste acceptable en coût (un lancement de plus) | Standard Stack | Latence d'une dizaine de ms |
| A8 | La table de la 79 (A10) place `/api/vf/tracabilite` entre `/api/vf/methode` et d'éventuelles routes `/api/vf/t…` | Contrats 79 | Mauvais ordre : rouge d'un test d'ordre éventuel |

## Open Questions

1. **Panneau d'un objet qui n'est pas un nœud (ADR, décision, entrée de mémoire, exigence) : comment l'ouvrir par `select(id)` ?** Le CONTEXT (P76-D-03 amendé) dit « `select(id)` / `reveal(id)` » ; or `select` n'accepte que des ids du graphe (`Q.exists`, `viewer.html:2541`-sq). Les phases et fichiers de plan ont un id (`n:ph-72`, `f:<chemin>-PLAN.md`) ; une ADR ou une mémoire n'en a pas. **Prémisse PÉRIMÉE sans rouvrir la décision :** la pile commune de la 80 empile des sélections de nœuds, pas des panneaux libres. Recommandation : le plan traite phase et plan par `select`, et les autres objets par `SC.showPanel` avec un lien « Retour » qui rappelle `select` du nœud d'origine ; dire « à revalider » ; confirmer avec la 80 (`VibeFlow.panneau`).
2. **Retrait du nœud `.req` : périmètre incomplet au CONTEXT.** P76-D-25 cite `vf-cockpit-project.mjs` seul. Mesuré : `vf-cockpit-ask.mjs` (5 lignes) dépend du nœud et des cartes `req/…`, et 5 assertions (`projet-graphe` 4, `questions` 1 bloc de fixtures) aussi. Recommandation : le plan de retrait inclut ces fichiers, ré-ancre « exigences de la phase N » et « REQ-01 ? » sur la route (ou les laisse à l'agent) et met à jour l'invite (`:169`). Sans cela le chat Projet régresse en silence.
3. **Clé de cache de P76-D-06 : PÉRIMÉE.** Voir Pitfall 2. Recommandation : max des mtime de fichiers sous `.planning/`, `docs/ADR.md`, `.claude/agent-memory/` + sha de HEAD.
4. **Borne du passage « chemins supprimés » (P76-D-22 « borne du P76-D-10 »).** Ici le 2 000ᵉ commit date de 2026-10-10 ; la liste de suppressions avec `--max-count=2000` donne le même résultat (1 179) parce que les suppressions sont récentes, mais ce n'est pas garanti. Recommandation : borne propre (suppressions seulement, sortie courte : 186 ms pour tout l'historique ici) et dite dans `bornes`.
5. **Jalon actif (TRAC-03).** La règle vit dans une variable locale de `construireGraphe` (`project.mjs:171`, `active = msList.find(…)`), non exportée, et `msList` n'est pas calculable sans `phases[].avancement`. Recommandation : extraire une fonction pure `jalonActif(P, layout)` (retrait équivalent de ~6 lignes dans `project.mjs`, qui a 61 lignes de marge) ; à coordonner avec 77 et 80 qui retouchent ce fichier.
6. **Recette : étendre `reste` ou lire à part ?** P76-D-14 veut `*-RECETTE-*.md` et « la règle de `reste()` réutilisée ». `reste` ne lit que `-RECETTE-HUMAINE.md` et que le mot FAITE ; la 76 doit donc extraire la lecture de la ligne `**Statut :` en fonction exportée (appelée par `reste`) sans changer son verdict. Le mot `CLOSE` (69) reste « lu, non faite » pour `reste` ; la 76 le sert tel quel sans le réinterpréter. Non bloquant.
7. **Gate G-2 / marqueur :** si un plan modifie `test-cockpit-vendor.sh` ou un hook, le commit porte `Gate-Touche:` ; ajouter des lignes `AJOUT` à `VENDORED.txt` n'en est pas un. Non bloquant.

### Prémisses du CONTEXT re-mesurées

| Prémisse (CONTEXT) | Statut | Mesure |
|--------------------|--------|--------|
| 93 exigences Phases 67-78, 92 rattachées par champ | **CONFIRMÉ** | 93 ; 92 par PLAN du même numéro (`CKPT-12@67` seule exception) |
| 24 cas case/statut | **CONFIRMÉ ±1** | 23 par la règle « premier mot ∈ {Complete, Done, Livré} » |
| 50 exigences sans ligne (ledger `fiabilite`) | **CONFIRMÉ ±1** | 51 (394 cases, 347 lignes) ; 4 lignes sans case |
| 32 ADR | **CONFIRMÉ** | 32, ADR-065 absent |
| 0,08 s / 3 619 commits / 1 014 citants | **CONFIRMÉ (ordre de grandeur), chiffres PÉRIMÉS** | 4 085 / 1 048 / 0,12 s |
| 268 entrées de mémoire | **CONFIRMÉ** | 277 suivis = 268 + 9 index |
| 399 liens, 7 POSIX, 61 par nom de fichier | **CONFIRMÉ** | 399 / 7 / 61 |
| 33 cassés sur 22 cibles | **CONFIRMÉ à ±1** | 32 sur 21 après retrait du code (le 33ᵉ est le lien en passage de code) |
| 143 sans lien entrant sur 268 | **CONFIRMÉ** | 143 |
| Clé de cache : HEAD + dates de ADR, CONTEXT, ledger, mémoire | **PÉRIMÉ (incomplet)** | omet PLAN, SUMMARY, VERIFICATION, recette, preuves ; mtime de dossier insuffisant (Q3) |
| « Calcul asynchrone » enveloppé dans le confinement (P76-D-09) | **PÉRIMÉ (à nuancer)** | `lireConfine` synchrone ; lire d'abord, git ensuite (Pitfall 1) |
| Retrait du nœud `.req` limité à `project.mjs` (P76-D-25) | **PÉRIMÉ (incomplet)** | + `vf-cockpit-ask.mjs` et 5 assertions (Q2) |
| Critères `must_haves` « comptés et listés » (P76-D-24) | **CONFIRMÉ, outil à écrire** | 151/152 PLAN ; 1 031 entrées ; `fm` illisible |
| Recette « règle de `reste()` réutilisée » (P76-D-14) | **PÉRIMÉ (à nuancer)** | `reste` limité à `-RECETTE-HUMAINE.md` + FAITE (Q6) |
| Fichiers non suivis comptés par git (P76-D-19) | **PÉRIMÉ (à nuancer)** | `-o -i` requis pour un `.claude/` ignoré (Pitfall 5) |
| P76-D-03 : navigation par `select/reveal` et Retour commun | **CONFIRMÉ pour phases et plans, PÉRIMÉ pour ADR/décision/mémoire** | Q1 |
| En-tête de jeton `x-vf-cockpit-token` (C0) | **CONFIRMÉ** | nom servi ; source `x-floorplan-token` renommée à l'assemblage |
| `piedExigences` reste | **CONFIRMÉ** | `project.mjs:48-53`, appelé `:125` |
| P76-D-18 : la 73 livre peut-être l'extracteur | **PÉRIMÉ** | le CONTEXT de la 73 ne mentionne aucun module de ce nom (S-3 reportée en BACKLOG) : la 76 le crée |

## Environment Availability

| Dépendance | Requis par | Disponible | Version | Repli |
|------------|------------|------------|---------|-------|
| git | route, suites, lab jetable | oui | 2.50.1 (Apple Git-155) | — |
| node | route, suites, harnais | oui | v26.5.0 | — |
| bash | suites | oui | /bin/bash | — |
| jq | quelques suites | oui | présent | — |
| python3 | non requis par la 76 | oui | 3.14 | — |
| Chrome (suite page) | TRAC-09, TRAC-11 (rendu) | présent (non lancé ici) | non sondé | suites Chrome sautées audiblement hors exécution |

Aucune dépendance bloquante. Rien n'a été lancé : pas de navigateur, pas de serveur, pas de suite.

## Sources

### Primaires (lues cette session)
- `plugin/cockpit/scripts/` : `vf-cockpit-planning.mjs`, `vf-cockpit-avancement.mjs`, `vf-cockpit-formats.mjs`, `vf-cockpit-server.mjs`, `vf-cockpit-project.mjs`, `vf-cockpit-git.mjs`, `vf-cockpit-paths.mjs`, `vf-cockpit-ask.mjs`, `vf-cockpit-rename.mjs`, `vf-cockpit-build.mjs`, `vf-cockpit-fr-inventaire.mjs`, `vf-cockpit-interface.json`
- `plugin/cockpit/skills/cockpit-moteur/assets/` : `viewer.html` (API `SC`, `renderPanel`), `serve.mjs` (:525-537), `ui/00-vibeflow.js`, `ui/70-vf-live.js` ; `VENDORED.txt` ; `plugin/cockpit/amont/synchro.sh`
- `plugin/cockpit/scripts/tests/` : `test-cockpit-vendor.sh`, `test-cockpit-who.sh`, `test-cockpit-git-details.sh`, `hygiene.sh`, `chrome-session.mjs`, `projet-commun.sh`
- `scripts/check-version-sync.sh` (§ 9), `scripts/ci-shard-suites.sh`, `plugin/conductor/scripts/check-method-budget.sh` (`rangement_memoires`), `plugin/planning-core/references/templates/REQUIREMENTS.template.md`
- `.planning/workstreams/fiabilite/` : `REQUIREMENTS.md`, `STATE.md`, `phases/VFDO-76-…/76-CONTEXT.md` (amendé `74c37166`), dossiers de phase 41, 57-72, 78
- Branches lues sans fusion : `79-CONTEXT.md` (`2ae6607a`, `6f66d878`), `80-CONTEXT.md` (`f10ba2c7`), CONTEXT des Phases 73, 74, 75, 77

### Secondaires
Mesures rejouables (lecteurs Node jetables, hors dépôt) : comptes de § 3 ; essai de `git ls-files -o -i` sur un lab jetable ; temps de `readPlanning`, `buildProjectGraph`, lecture et `stat` globaux.

### Tertiaires (LOW)
Comportement des CI Linux et de Node non sondé (A5).

## Metadata

**Confidence breakdown :**
- Standard stack / réutilisables : HAUTE (lignes relues)
- Formats : HAUTE (comptes rejoués ; seuils ±1 expliqués)
- Contrats 79/80 : MOYENNE (branches non fusionnées, noms de fonctions encore libres)
- Pitfalls : HAUTE (chacun appuyé sur une ligne ou une mesure)

**Research date :** 2026-11-11
**Valid until :** ré-évaluer à l'exécution de la 79 et de la 80 (P76-D-28) ; les comptes de § 3 bougent à chaque commit (borne `--max-count=2000` : 1 048 citants aujourd'hui).

## Project Constraints (from CLAUDE.md)

- Commits et messages en **français**, cohérents avec l'historique ; pas de release ni de bump dans la phase (P76-D-29) : seule la ligne `CHANGELOG.md` § Non publié ; une PR de planning/doc se merge sans release.
- Dépôt public : aucun chemin absolu de poste, identifiant de session, nom d'un autre projet ni montant dans les fichiers versionnés (`scripts/check-machine-paths.sh`).
- Traçabilité des arbitrages : un commit qui invoque une décision humaine nomme le **canal et la date** (« décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée ») ; identifiants de décision **préfixés** (`P76-D-nn`).
- Jamais de fix sans validation humaine (ADR-031) ; ADR-029 (densité) s'applique aux agents, non à ce code ; fichiers de code ≤ 300 lignes (gate V4).
- Gardes in-repo : trailer `Gate-Touche: <chemin> — <raison>` sur tout commit qui touche un gate, sa suite, le workflow CI ou un hook ; une hausse de baseline exige une citation d'arbitrage avec canal et date.
- Conception : toute interface suit `DESIGN.md` (« Graphite ») ; UI neuve : `76-UI-SPEC.md` critiqué avant les plans (P76-D-26) ; ni couleur d'alerte ni fond teinté (glyphe et mot).
- Discipline de preuve : un témoin doit pouvoir rendre rouge ; mesurer une fois posé (sondes cockpit) ; `git -C` et chemins relatifs au worktree, jamais `cd` dans un autre arbre.
