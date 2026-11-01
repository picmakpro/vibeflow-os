# Phase 67: Cockpit floorplan sur socle partagé - Context

**Gathered:** 2026-11-01
**Status:** Cadrée — prête pour le plan

Cadrage porté par `vf-dev-manager` (mission-flow §Pattern F), mode superviser, questions relayées à Samuel
par la session principale (escalade SendMessage, AskUserQuestion absent en sous-agent). Entrée unique :
`.planning/notes/2026-11-01-cockpit-facettes.md` (4 arbitrages Samuel, AskUserQuestion session principale,
2026-11-01). Savoir technique prouvé, à ne pas re-spiker : skill local `spike-findings-vibeflow-os` (arbre
principal du dépôt, ignoré par git : `.claude/skills/spike-findings-vibeflow-os/`, 5 références + sources),
`.planning/spikes/` (002-006, `WRAP-UP-SUMMARY.md`), `docs/research/2026-11-01-etude-floorplan-cockpit.md`.
Faits mesurés le 2026-11-01 par un éclaireur en lecture seule (repris en P67-D-xx avec leur source).

**Exigences :** famille `CKPT` (libre le 2026-11-01 : aucune occurrence dans `.planning`, `plugin`, `docs`),
CKPT-01 à CKPT-11 ci-dessous. Le plan les inscrit dans `REQUIREMENTS.md` du compartiment et dans la ligne
`Requirements` de la Phase 67 du ROADMAP.

<domain>
## Phase Boundary

Un module VibeFlow distribué et toggable, `plugin/cockpit`, ouvert par `/vf-cockpit`, qui sert dans tout lab
GSD un cockpit à onglets **Projet** (au cœur) et **Code**, en marque blanche VibeFlow, sur un **socle
partagé** (collecteur « qui est au travail » + graphe Projet) que la Phase 68 (`vf-signal`) réutilisera.
Plus, en plan séparé, le correctif d'écriture atomique de `dag.sh`.

**Hors périmètre :** enrichir l'onglet Code par stack ; embarquer `vf-signal` (Phase 68) ; synchroniser vers
floorplan v0.6.1 (première synchro = suite) ; toute release (geste humain) ; PR amont des patchs génériques.

</domain>

<decisions>
## Implementation Decisions

### Arbitrages de Samuel (AskUserQuestion session principale, 2026-11-01)

- **P67-D-01 (lignée, public, garde-fous, feuille de route).** Les 4 arbitrages de la note d'entrée valent
  tels quels : remplace `vf-cockpit` ; tous les labs, onglet Projet au cœur, Code riche ici / brut ailleurs ;
  agent des questions actif, dernière commande des sessions masquée et jamais exportée ; jalon V2.
- **P67-D-02 (aucune donnée vers Floorplan Cloud — contrainte Samuel, message session principale,
  2026-11-01).** Retrait entier de la fonction Cloud : `assets/ui/50-cloud.js`, endpoints de liste
  d'attente, `claudeEmail()` (`claude auth status --json`), `WAITLIST_URL` / `FLOORPLAN_WAITLIST_URL`,
  invites et `~/.floorplan/settings.json`, résidu CSS `#cloud-card`. Mesure : `serve.mjs` 227-268 et
  563-582 de la copie figée, `50-cloud.js` seul consommateur, aucune autre référence. **Aucun appel réseau
  sortant** hors l'agent `claude -p` des questions. Témoin : grep sans `run.app`, `waitlist`, `auth status`
  dans le module livré, et aucune requête sortante au chargement de la page.
- **P67-D-03 (marque blanche — contrainte Samuel, message session principale, 2026-11-01 ; forme A1).**
  Zéro « Floorplan » visible (UI, titre, logo, favicon, « Made with », export, messages serveur, aide,
  dossiers de sortie, variables `FLOORPLAN_*`, `~/.floorplan/`). Forme retenue (A1) : **copie amont patchée
  intacte dans le module + renommage mécanique à l'assemblage** (script déterministe : identifiants,
  globales `window.Floorplan`/`window.FLOORPLAN*`, `x-floorplan-token`, `__FLOORPLAN_*__`, clés
  `localStorage 'floorplan:'`, chemins, variables d'environnement). Mesure : 100 occurrences d'API sur 83
  lignes / 18 fichiers ; nos patchs touchent 36 lignes dont une sur un identifiant. Témoin : grep insensible
  à la casse sur le rendu servi (HTML + JS chargés) = 0 hors commentaire de licence, par un test qui rougit
  si une occurrence visible réapparaît (synchro amont comprise). **Contrainte légale** : LICENSE MIT et
  copyright d'origine conservés dans la copie vendorisée, plus une ligne dans un fichier de licences tierces
  du module, hors interface.
- **P67-D-04 (logo, A2).** Logo VibeFlow existant `docs/readme/logo-light.svg` / `logo-dark.svg`, inliné
  (logo et favicon).
- **P67-D-05 (nom, A3).** Module `plugin/cockpit`, verbe `/vf-cockpit`. `SEED-004` devient « fermer la
  branche `feat/vf-cockpit-module` » (à la livraison, pas dans cette phase).
- **P67-D-06 (sortie dans le lab, A4).** `.vibeflow/cockpit/` avec son propre `.gitignore` « * »
  (précédent : `.vibeflow/mobile-test.json`). Aucun `floorplan/` ni `CLAUDE.local.md` écrit dans le lab.
- **P67-D-07 (taille des fichiers, A5).** Exemption ADR-035 limitée au code vendorisé : marqueur
  `vibeflow:allow-large-file` (dette tracée, fait partie du jeu de patchs documenté), liste dans
  `VENDORED.txt`. **Notre code reste ≤ 300 lignes par fichier.** Fichiers concernés mesurés : `serve.mjs`
  647, `health.mjs` 1 198, `screens.mjs` 638, `extract.mjs` 598, `build.mjs` 482, `scan.mjs` 316,
  `elk.bundled.js` 6 696 (`viewer.html` 2 394, `.html` hors gate).
- **P67-D-08 (modèle de l'agent, variante B1 de Samuel).** `sonnet` par défaut, réglable par variable
  d'environnement **et par un sélecteur de modèle dans le cockpit**. Proposition du manager (défaut
  raisonnable, à défaut d'autre consigne) : le choix est mémorisé localement **par lab** dans le navigateur
  (clé renommée VibeFlow), envoyé avec chaque question, validé côté serveur contre une liste fermée ;
  préséance sélecteur > variable d'environnement > `sonnet` ; jamais écrit dans un fichier généré ni dans
  l'export.
- **P67-D-09 (correctif `dag.sh`, C1 = option 2).** Dans cette phase, en plan
  séparé : écriture atomique de `save()` (fichier temporaire du même dossier puis `os.replace`), **témoin
  rouge d'abord** (lecture pendant une écriture lente). Cette réponse vaut la validation humaine ADR-031
  pour ce correctif précis, rien au-delà. Mesure : `plugin/conductor/scripts/dag.sh:132-135`
  (`open(file,"w")` puis `json.dump`).
- **P67-D-10 (handoff, C2).** Commiter `.planning/notes/2026-10-29-HANDOFF-jalon-v2.md` tel quel sur
  `feat/v2-cockpit` (il n'existe que dans l'arbre principal, non suivi, et la Phase 68 le cite).
- **P67-D-11 (version amont, C3).** Rester sur floorplan v0.6.0 @ 92d6854 (prouvée par les spikes, patchs
  P1-P8 en diff dans `.planning/spikes/002-cockpit-code-projet/patches/`) et livrer la procédure de
  synchro. Fait : amont très actif (88 commits, 20 tags en 6 jours ; v0.6.1 = 4 commits, merge 3-voies
  simulé sans conflit).

### Décisions du manager validées par Samuel (même canal, même date)

- **P67-D-12 (socle).** Le collecteur « au travail » (`who.mjs`, spike 004) et le graphe Projet
  (`vf-project-graph.mjs`, spike 002) deviennent une bibliothèque node du module, à **interface JSON
  documentée et versionnée** (schéma nommé VibeFlow), consommable par `vf-signal` (Phase 68). Interface de
  fait existante : JSON de `driver-lock.sh status --all` / `orphans` et schéma DAG `nodes[]`. Test de
  forme des transcripts et `meta.json` (format interne de Claude Code ; clés vérifiées sur 2.1.316 :
  transcript `cwd, gitBranch, type, message, timestamp, version, sessionId` ; meta `agentType,
  description, spawnDepth, finished, parentAgentId, toolUseId`).
- **P67-D-13 (serveur unique).** Le direct (`live.mjs`, spike 003) rejoint le serveur patché (P7) : plus de
  second port ni de CORS. Notre code vit dans nos fichiers, branché par un crochet minimal dans `serve.mjs`.
  Bind `127.0.0.1`, jeton par démarrage, contrôle du Host conservés.
- **P67-D-14 (dernière commande).** Le champ `doing` n'est **jamais** dans le flux SSE, dans un fichier
  généré ni dans l'export ; révélé par une requête authentifiée ponctuelle. Test qui le prouve (y compris
  `exportMap`).
- **P67-D-15 (agent confiné).** Lecture bornée à la racine du lab, mode de permission explicite, Bash limité
  aux deux scripts de requête (chemins renommés sous `.vibeflow/cockpit/`). Fait manquant : comportement de
  `claude -p` sur un Bash hors allowlist — à mesurer au plan.
- **P67-D-16 (direct multiplateforme).** `fs.watch` récursif + repli par polling des mtimes (patron de
  `vf-cockpit-watch.mjs`, branche jamais mergée) ; Linux et Windows non mesurés à ce jour.
- **P67-D-17 (onglet Code).** Extracteur VibeFlow (`vf-code-arch.mjs`) si le lab porte des
  `plugin/*/module.json`, sinon scan brut de floorplan ; **aucun LLM** à l'assemblage.
- **P67-D-18 (étage design sauté).** Pas de `DESIGN.md` dans le dépôt ; la DA est celle de floorplan
  (exigence des spikes). DA-INIT proposable plus tard.

### Contraintes d'installation (faits, éclaireur 2026-11-01)

- L'engine (`plugin/_internal/vibeflow-update.sh`) copie `scripts/` **à plat** (`*.sh *.mjs *.js *.txt
  *.json` + `tests/`), sans sous-dossiers ; un dossier `skills/<nom>/` est copié en arbre entier
  (précédent : `plugin/skill-creator/skills/skill-creator/` avec assets HTML). → l'arbre vendorisé se pose
  en skill imbriqué. Non vérifié : pose des binaires (png, woff2) par `vf_place_file` — à tester.
- `check-skills.sh` exige une classe d'invocation en frontmatter de tout `SKILL.md` sous `plugin/` : le
  `SKILL.md` amont de floorplan n'est pas à livrer tel quel.
- Suites découvertes par la CI : `plugin/**/tests/test-*.sh`, Node 24 dans le job tests.

### Exigences CKPT

- **CKPT-01** Socle partagé : collecteur « au travail » + graphe Projet, interface JSON documentée et
  versionnée, test de forme transcripts/meta (P67-D-12).
- **CKPT-02** Vendorisation v0.6.0 @ 92d6854 + patchs rejouables, LICENSE et copyright, licences tierces,
  `VENDORED.txt`, procédure de synchro (P67-D-03, D-07, D-11).
- **CKPT-03** Aucun appel sortant hors `claude -p` ; Cloud retiré ; témoins grep + réseau (P67-D-02).
- **CKPT-04** Marque blanche par renommage mécanique, logo VibeFlow, test qui rougit (P67-D-03, D-04).
- **CKPT-05** Serveur unique (direct SSE, questions, au travail), polling de secours (P67-D-13, D-16).
- **CKPT-06** Onglet Projet sur tout lab GSD (plat ou partitionné) ; onglet Code conditionnel sans LLM
  (P67-D-17).
- **CKPT-07** Questions : formes courantes locales ; agent confiné ; sélecteur de modèle (P67-D-08, D-15).
- **CKPT-08** Dernière commande masquée, jamais exportée, test (P67-D-14).
- **CKPT-09** Chrome en français, 0 anglais visible, test qui rougit (97 des 258 chaînes au dictionnaire au
  spike 006).
- **CKPT-10** Module toggable `plugin/cockpit` (module.json, VERSION, CHANGELOG, README), `/vf-cockpit`,
  posé par l'engine, test d'install ; sortie `.vibeflow/cockpit/` (P67-D-05, D-06).
- **CKPT-11** `dag.sh` écriture atomique, témoin rouge d'abord (P67-D-09).

### Ordre des plans (validé)

Socle d'abord ; le correctif `dag.sh` est indépendant (vague 1 possible) ; puis vendorisation + retrait Cloud +
marque blanche ; serveur unique ; module et install ; chrome français. Revue et audit sécurité après
l'exécution.

</decisions>

<canonical_refs>
## Canonical References

- `.planning/notes/2026-11-01-cockpit-facettes.md` — arbitrages, choix de session, limites connues.
- `.claude/skills/spike-findings-vibeflow-os/references/` (arbre principal) — cockpit-floorplan, cockpit-live,
  questions-projet, signal-au-travail, types-et-chrome-fr.
- `.planning/spikes/002-cockpit-code-projet/` — extensions, patchs P1-P8, `VENDORED.txt`, procédure de
  reconstruction ; `.planning/spikes/003-006/` — `live.mjs`, `who.mjs`, `vf-ask.mjs`, `vf-query.mjs`.
- `docs/research/2026-11-01-etude-floorplan-cockpit.md` — étude de reprise.
- `git show feat/vf-cockpit-module` — `findPlanningRoot`, `resolveReferencesDir`, `safeJoin`,
  `vf-cockpit-watch.mjs` (repli polling).
- `plugin/_internal/vibeflow-update.sh` — règles de pose des modules.

</canonical_refs>

## Addendum post-exécution (2026-11-01)

Décisions prises après l'exécution des plans 67-01 à 67-07, relayées par la session principale.

- **P67-D-19 (gate python, D1 option 1).** `scripts/check-python-isolation.sh` exclut le seul motif
  `*/assets/vendor/*` : `elk.bundled.js` (une ligne de 620 020 caractères) le bloquait plus de 5 min.
  Arbitrage Samuel, AskUserQuestion session principale, 2026-11-01 ; validation ADR-031 pour ce
  correctif seulement (commit `eb2e786d`, témoin rouge joué, gate en 1,7 s). **Resserré** ensuite à
  `*/assets/vendor/*.js` : un `.sh` sous `assets/vendor/` reste contrôlé (arbitrage Samuel,
  AskUserQuestion session principale, 2026-11-01 ; validation ADR-031 pour ce changement précis ;
  commit `7a4b8117`, témoin rouge joué). Même jour : le jeton servi à tout processus local est accepté
  comme limite documentée (0600 + hypothèse mono-utilisateur), même canal.
- **P67-D-20 (anglais de l'onglet Code, E1).** Réponse de Samuel, mot pour mot (AskUserQuestion session
  principale, 2026-11-01) : « on pourrait avoir des gens qui utilise l'anglais, donc en soit l'anglais
  n'est pas dérangeant et peut etre un des langues autorisées ». Lecture du head, retenue par le
  manager (lecture, pas arbitrage) : ni masquage ni traduction du panneau Santé dans la 67. CKPT-09
  devient « chrome en français par défaut ; les textes produits par le moteur (Santé, couverture de
  l'onglet Code) peuvent rester en anglais ». Le choix de langue de l'interface (français / anglais)
  est une suite tracée au BACKLOG, hors 67.
- **P67-D-21 (responsive minimal, CKPT-12).** Demande de Samuel (message session principale,
  2026-11-01) : « au moins pouvoir avoir la fenêtre ajustable ». CKPT-12 : aucune superposition ni
  rognage de l'en-tête, des panneaux et de la barre de question de 1 024 à 2 560 px, au chargement
  comme au redimensionnement ; rendu non cassé en dessous ; test qui mesure les boîtes à 1 024, 1 280,
  1 440 et 1 920 px.
- **P67-D-22 (recette déléguée).** Samuel (message session principale, 2026-11-01) : « Lance le test
  toi-même ». La recette `67-RECETTE-HUMAINE.md` est jouée au navigateur par le head sur délégation ;
  elle est consignée comme « jouée par le head sur délégation de Samuel », jamais comme réponse de
  Samuel. Reste à Samuel : l'appréciation visuelle d'ensemble après les corrections d'interface.
