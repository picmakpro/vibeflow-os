# Phase 79 : Socle du cockpit — une collecte, un flux, une route d'état - Research

**Researched:** 2026-11-11
**Domain:** serveur Node local du cockpit (module `cockpit`), page navigateur vanilla, registre du verrou (`conductor`), doctrine des mandats (`dev-orchestrator`)
**Confidence:** HIGH sur l'état du code et les recouvrements (lu dans la base `f763b556` + commit `3119d82a`) ; MEDIUM sur trois mécanismes à éprouver (élection d'onglet, ELK en worker, confinement de l'agent avec chemins de module) ; LOW sur rien qui engage un plan sans checkpoint.

## Summary

La Phase 79 est d'abord un **déménagement de code** (le serveur et tout ce qu'il évalue quittent `.vibeflow/cockpit/` pour être lancés depuis le module), puis une **refonte de la collecte** (index incrémental des transcripts, collecte hors de la boucle d'événements, une route d'état), puis une **refonte du transport côté page** (flux partagé, coquille en cache, magasin d'état). Le code présent fixe trois contraintes que le découpage provisoire ignorait : (1) le plafond **dur** de 300 lignes de `test-cockpit-vendor.sh` V4 frappe déjà `vf-cockpit-paths.mjs` (296 lignes), `vf-cockpit.mjs` (273), `ui/70-vf-live.js` (285) et `vf-cockpit-who.mjs` (244) : tout ajout dans ces fichiers passe par un module neuf ; (2) le code exécuté aujourd'hui est la **copie renommée** (`x-floorplan-token` → `x-vf-cockpit-token`, `window.FLOORPLAN` → `VF_COCKPIT`) : lancer le module tel quel ferait diverger le serveur des pages ; (3) `scripts/` est posé **à plat** par l'engine, un sous-dossier de `scripts/` n'arrive jamais dans un lab.

Le second constat structurant est l'**ordre** : l'aide commune de lancement des suites (AM7) doit précéder AM4, parce qu'elle fait de « lancer depuis le module » un changement en un seul point au lieu de 51 suites ; le retrait de l'appareil de patchs (H5) doit précéder tout plan qui touche `serve.mjs` ou `viewer.html`, sinon chaque plan régénère un diff. Quatre fichiers sont des goulets (`vf-cockpit-server.mjs`, `vf-cockpit-interface.json`, `serve.mjs`, `viewer.html`) : ils imposent neuf vagues au lieu de six, ou des découpes de plans.

La collecte hors boucle (H2) a une forme peu coûteuse : faire tourner les collecteurs synchrones existants (`collectWho`, `buildProjectGraph`, `driver-lock.sh status --all`, l'index) dans un **`worker_threads`** de Node, sans réécrire leur code en asynchrone. `vf-signal` lit la route d'état en gardant son émetteur comme repli, sans changer le mod : c'est l'émetteur (`vf-cockpit-signal.mjs`) qui délègue au serveur vivant.

**Primary recommendation:** suivre les vagues corrigées (§ Ordre des vagues), poser d'abord 79-01 (fork), 79-02 (aide de lancement, migration des suites), 79-03 (registre) ; garder `?lang=en` (arbitrage P67-D-20 / P70-D-03 / SEED-005) ; refaire la mesure de confinement de l'agent dans un `79-MESURE-claude-p.md` avant de changer `ARGS_CONFINEMENT` ; ne pas livrer I18 dans cette phase (recommandation, au manager de trancher).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
Copie de `79-CONTEXT.md` § Implementation Decisions :

> Toutes « décision déléguée par Samuel (message session principale, 2026-11-08), option recommandée », sauf mention.
> Aucune ne vaut arbitrage de Samuel.
>
> - **P79-D-01 (contrats).** Les sections C0 à C6 sont figées ; un écart se consigne ici en amendement daté.
> - **P79-D-02 (route d'état).** Enveloppe `cockpit-state@1` autour d'un `cockpit-signal@1` inchangé : la Phase 73 et
>   `vf-signal` gardent leurs lecteurs.
> - **P79-D-03 (index).** C1 : cache du lab, non fiable à la lecture, un seul écrivain, 24 h, sans cible.
> - **P79-D-04 (cibles).** En mémoire seulement (arbitrage AUDC-Q2 en vigueur) ; question S-1.
> - **P79-D-05 (coût).** Sur la fenêtre de 24 h (arbitrage AUDC-Q2 en vigueur) ; question S-2.

**Contrats C0 à C6** : figés (P79-D-01), source unique `79-CONTEXT.md` § « Contrats fournis ». Ils ne sont pas recopiés ici
pour ne pas créer une seconde source ; cette recherche dit **comment les tenir**, plan par plan.

**Décisions rendues du jalon (digest de mission, à ne pas rouvrir)** : AUDC-Q5 fork assumé ; AUDC-Q2 index sur disque
borné à heures, durées, jetons et verbes, fenêtre 24 h ; AUDC-Q4 `claude agents --json` source de référence derrière le
contrat de forme ; AUDC-Q3 actions sur une session reportées (Phase 81) ; AUDC-Q1 mode « hérité du poste » tel que livré.
Bornes : P67-D-14, P69-D-16, P69-D-19, P69-D-23 ; clés `doing`, `mandat`, `messages`, `outils`, `fil` refusées à l'émission.

### Claude's Discretion
Le CONTEXT n'a pas de section « Claude's Discretion ». Laissé au découpage : forme des plans, ordre des vagues,
mécanismes internes qui tiennent les contrats (worker, élection d'onglet, aide de test). Questions ouvertes à Samuel,
non bloquantes : **S-1** (persister les cibles réduites ? en vigueur : non) et **S-2** (coût au-delà de 24 h ? en vigueur :
non) — `79-CONTEXT.md` § « À Samuel ».

### Deferred Ideas (OUT OF SCOPE)
Copie de `79-CONTEXT.md` § Phase Boundary, « Hors périmètre » :

> la régie et l'onglet Équipe (Phase 73) ; la frise, la fiche d'agent, le coût affiché (Phase 74) ;
> le radar et l'empreinte en direct (Phase 75) ; la synthèse (Phase 77) ; les onglets sans rechargement (Phase 80,
> AUDC-I30, sur la coquille fournie ici) ; toute action sur une session (Phase 81, AUDC-Q3 « plus tard »).
</user_constraints>

<phase_requirements>
## Phase Requirements

La famille `SOCL` est réservée mais pas encore posée (ROADMAP « Requirements: TBD »). Correspondance provisoire avec les
lignes du registre absorbées, pour que le manager pose les identifiants :

| Ligne absorbée | Description (registre) | Plan(s) | Appui de recherche |
|---|---|---|---|
| AUDC-H5 | fork assumé, retrait de l'appareil de patchs | 79-01 | § 79-01 |
| AUDC-AM7 (reste) | socle de test partagé | 79-02 | § 79-02 |
| AUDC-D5, I37 | registre conservé, nœud dans le mandat | 79-03, 79-04, 79-07b | § 79-03, § 79-04 |
| AUDC-AM4, A-03, H3 reste, D-M13 | serveur lancé depuis le module, empreinte, orphelin | 79-05 | § 79-05 |
| AUDC-A-02 reste, D-M15, A-04 limites | résolution physique, cible interne protégée, environnement git des enfants shell | 79-06 (+ 79-07b pour `live.mjs:66`) | § 79-06 |
| AUDC-I20, D9, AB1 | index incrémental, segments, version asynchrone, cache de scan | 79-07a, 79-07b, 79-05 (AB1) | § 79-07 |
| AUDC-H2 reste | collecte hors boucle | 79-07b | § 79-07b |
| AUDC-I19, AM1 | route d'état, `vf-signal` la lit | 79-08 | § 79-08 |
| AUDC-I20 (route) | route de frise | 79-09 | § 79-09 |
| AUDC-H1 reste, I22, D-M2 | flux partagé, battement nommé | 79-08 (serveur), 79-10 (page) | § 79-10 |
| AUDC-AM1, AM2, I31 | coquille, route graphe, fin de la réécriture de `project.html` | 79-11a, 79-11b | § 79-11 |
| AUDC-AM6, I32 | magasin côté page | 79-12 | § 79-12 |
| AUDC-AM3, M7 reste | mise en page dans un worker | 79-13 | § 79-13 |
| AUDC-H4 reste | traduction au point d'émission | 79-14 | § 79-14 |
| AUDC-AM5 | plafond en colonnes, code navigateur rangé | 79-15 | § 79-15 |
| AUDC-I18 | journal par les hooks | 79-16 (décision) | § 79-16 |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Commits en français ; un commit qui invoque une décision humaine nomme **canal et date** ; identifiants de décision
  **préfixés** (`P79-D-02`, pas `D-02`).
- **Gate-Touche** : tout commit qui touche une suite `plugin/conductor/scripts/tests/test-*.sh`, un `check-*.sh`, le
  workflow CI, un hook ou une fixture surveillée porte `Gate-Touche: <chemin-ou-motif> — <raison>` (CLAUDE.md du dépôt).
- **Densité ADR-029** : agents alerte à 251, refus au-delà de 300 lignes ; **budget d'instructions armé**
  (`check-instruction-budget.sh`) : aucune instruction ajoutée au corps d'un agent sans retrait ; une hausse de baseline
  exige une citation d'arbitrage (G-1).
- **ADR-031** : jamais de correctif sans validation humaine ; **ADR-044** : `check-agents.sh` si un agent est touché.
- **Pas de release** dans cette phase (ADR-073 : une PR de phase n'est pas une release ; la release est un geste humain).
- **Dépôt public** : aucun chemin du poste, identifiant de session, nom d'autre projet, montant ; sécurité décrite par
  sa classe, jamais de recette d'exploitation (vaut pour `79-MESURE-claude-p.md`, fixtures, messages de commit).
- **DESIGN.md** direction « Graphite » ; ni couleur d'alerte ni fond teinté.
- Mémoire du projet à tenir : « une preuve doit pouvoir rendre rouge », « une liste de cas ne ferme pas une classe »,
  « rejouer les commandes du job `gates` de `ci.yml`, jamais une liste de rapport », filtres de kill jamais vides
  (incident du 2026-11-02, `hygiene.sh` G1-G5).

## Architectural Responsibility Map

| Capacité | Tier principal | Tier secondaire | Raison |
|---|---|---|---|
| Lancement, empreinte, reprise d'orphelin | Lanceur CLI (`vf-cockpit.mjs`, processus du poste) | Serveur (`/api/status`) | le lanceur décide ; le serveur ne fait que se déclarer |
| Collecte (who, verrous, planning, index) | Serveur — thread de travail (`worker_threads`) | Serveur — boucle principale (surveillance de fichiers, diffusion) | le calcul lourd quitte la boucle ; la boucle garde le HTTP et le SSE |
| Index des transcripts (C1) | Serveur (écrivain unique, `.cache/`) | — | donnée privée, jamais servie telle quelle |
| Route d'état, route de frise, route graphe | API locale (`vf-cockpit-server.mjs`) | — | lecture d'instantané, aucune collecte à la requête |
| Garde d'émission `porteInterdit` | API locale | — | point unique de sortie |
| Flux partagé entre onglets, magasin `VF_ETAT` | Navigateur | API (événements `vie`, `etat`, `frise`) | élection d'onglet et relais sont des primitives de la page |
| Mise en page ELK | Navigateur — Web Worker | Navigateur — fil principal (repli export) | calcul long hors du fil d'interface |
| Traduction | Navigateur (au point d'émission) | Serveur (messages renvoyés) | la chaîne naît traduite |
| Registre du verrou conservé | Conductor (`driver-lock.sh`) | Cockpit (lecteur) | un seul écrivain du registre |
| Nœud dans le mandat | Doctrine (références kernel et dev) | Cockpit (`citationsDuMandat`) | la forme écrite doit être la forme lue |
| `vf-signal` | Mod (inchangé) → émetteur Node | Serveur (route d'état) | l'émetteur délègue quand un serveur vit |

## Standard Stack

### Core
| Composant | Version | Rôle | Pourquoi |
|---|---|---|---|
| Node.js, modules intégrés seulement (`node:http`, `node:fs`, `node:child_process`, `node:worker_threads`, `node:crypto`) | CI : `node-version: "24"` [VERIFIED: `.github/workflows/ci.yml:228`] ; poste : v26.5.0 [VERIFIED: `node --version`] | serveur, lanceur, collecte | aucune dépendance npm dans le module (seuls `node:` et imports relatifs ; recherche d'imports nus vide) [VERIFIED: grep des `from` de `plugin/cockpit/scripts/*.mjs`, `serve.mjs`, moteur] |
| `worker_threads` (intégré) | — | collecte hors boucle (H2) | les collecteurs synchrones existants tournent tels quels dans un fil de travail [ASSUMED : comportement standard de Node, non mesuré ici] |
| JS navigateur vanilla, `EventSource`, `BroadcastChannel`, Web Locks (`navigator.locks`) | — | flux partagé (C4) | `BroadcastChannel` : « any browsing context of a given origin can subscribe » [CITED: developer.mozilla.org/en-US/docs/Web/API/BroadcastChannel] ; Web Locks « available only in secure contexts », verrous « scoped to origins » [CITED: developer.mozilla.org/en-US/docs/Web/API/Web_Locks_API] ; `http://127.0.0.1` et `http://localhost` sont des contextes sûrs (`127.0.0.0/8`, `localhost`) [CITED: developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts] ; à la décharge d'un document, ses verrous sont relâchés [CITED: w3c.github.io/web-locks § 2.6] |
| elkjs 0.9.3 vendoré (`assets/vendor/elk.bundled.js`) | 0.9.3 | mise en page | l'en-tête UMD pose `g.ELK` sur `self` hors `window` [VERIFIED: tête de `assets/vendor/elk.bundled.js`] → chargeable par `importScripts` dans un worker |

**Version de Node exigée par le module :** aucune déclaration VibeFlow. Seule la phrase amont « needs only Node 18+ »
existe [VERIFIED: `skills/cockpit-moteur/assets/serve.mjs:4`]. Pas de champ `engines`, pas de contrôle
`process.versions` dans le module [VERIFIED: grep vide]. **Toute affirmation « le module marche sous Node X » au-delà de
ce qui tourne en CI (24) et sur le poste (26) reste [ASSUMED]** (absence de métadonnée). Recommandation : ne pas
introduire d'API plus récente que Node 20 sans la déclarer ; `worker_threads` et `BroadcastChannel` (Node) existent
bien avant [ASSUMED].

### Supporting
| Outil | Rôle | Quand |
|---|---|---|
| `plugin/software-architecture/scripts/check-file-size.sh` | plafond de lignes (WARN 250, BLOCK 300) | appelé par `test-cockpit-vendor.sh` V4 |
| `scripts/check-version-sync.sh` § 9 | compteur « N suites » des deux README racine | toute suite ajoutée |
| `plugin/conductor/scripts/check-ajout-retrait.sh --ci` | consultatif (SOBR-05) : ajout de gate, règle, mémoire d'agent, SKILL.md | mémoires d'agents écrites par les workers |

### Alternatives Considered
| Au lieu de | Possible | Arbitrage |
|---|---|---|
| `worker_threads` pour H2 | réécrire `collectWho`, `readPlanning`, `driverLockScript` en asynchrone | rejeté : réécriture large de code testé, et la collecte resterait par morceaux sur la boucle |
| Web Locks + `BroadcastChannel` | `SharedWorker` | rejeté : un `SharedWorker` exige `worker-src` et un fichier servi, absent de Safari iOS historiquement [ASSUMED] ; le contrat C4 prévoit déjà le repli « un flux par page » |
| Renommer les sources une fois (fork assumé) | renommer en mémoire au chargement | rejeté : rompt les imports relatifs (scout-secu § 1.5) |

**Installation :** aucune. Aucun `npm install`, aucun fichier tiers nouveau.

## Package Legitimacy Audit

Aucun paquet externe n'est installé par cette phase (aucune dépendance npm, PyPI ou crate). L'ELK en worker réutilise le
fichier déjà vendoré. **Packages removed :** none. **Packages flagged :** none.

## Architecture Patterns

### System Architecture Diagram

```
 lanceur (vf-cockpit.mjs, code du module)
   │ open : empreinte du code du MODULE ── détecte serveur vivant / orphelin (même fonction pour status, stop)
   │ spawn node <module>/serve.mjs --sortie <lab>/.vibeflow/cockpit   (sortie en ARGUMENT : visible de ps et de hygiene.sh)
   ▼
 serve.mjs (module) ── Host, Origin, jeton ──► routes /api/vf/* (vf-cockpit-server.mjs, module)
   │                                              │  state  : lit l'instantané ─────────────┐
   │                                              │  frise  : projette l'index ─────────────┤
   │                                              │  graphe : JSON + ETag ───────────────────┤
   │                                              │  events : hello · vie(15 s) · etat · frise · who · lock · git · patch · structural · reload
   │                                              ▼                                          │
   │                             garde porteInterdit (5 clés, fermée par défaut) ◄──────────┘
   │
   ├── fs.watch .planning + vf-driver (boucle) ──► demande de collecte
   ▼
 fil de travail (worker_threads) : collectWho · buildProjectGraph · driver-lock status --all (shBorne + envGit)
   · index incrémental (.cache/index-transcripts.json, 0600, tmp+rename) · signal@1
   └──► instantané immuable → boucle : signatures → événements sans contenu

 navigateur (même origine 127.0.0.1:<port>)
   onglet élu (Web Lock) ── EventSource unique ──► BroadcastChannel ──► autres onglets
   VF_ETAT.lire / abonner (etat, who, frise, git, connexion) ── veille 45 s sans événement → « perdu » → sondage existant
   coquille servie du module (ETag) + données GET /api/vf/graphe ; ELK dans un Worker (repli en ligne pour l'export)

 vf-signal (mod, inchangé) ── node vf-cockpit-signal.mjs <racine>
   └─ serveur du lab vivant et reconnu ? GET /api/vf/state (jeton de server.json, Host explicite) : sinon collecte locale (repli)
```

### Recommended Project Structure (fichiers nouveaux)

```
plugin/cockpit/scripts/
├── vf-cockpit-module.mjs          # 79-05 : dossier du module, liste du code évalué, empreinte partagée (lanceur + serveur)
├── vf-cockpit-serveur-vivant.mjs  # 79-05 : serveurVivant, estNotre, détection d'orphelin sans adoption (status/stop/open, émetteur)
├── vf-cockpit-git-lanceur.mjs     # 79-06 : lancer/lancerGit/shBorne extraits de paths.mjs (paths.mjs les ré-exporte)
├── vf-cockpit-index.mjs           # 79-07a : lecture incrémentale par curseur, chargement non fiable, purge 24 h
├── vf-cockpit-index-voie.mjs      # 79-07a : réduction ligne → voie (segments, événements, compteurs) — pure
├── vf-cockpit-jetons.mjs          # 79-07a : dédoublonnage par message.id — pure, exportée (demande de la Phase 74, point E)
├── vf-cockpit-collecte.mjs        # 79-07b : pilote du fil de travail, instantané, signatures
├── vf-cockpit-collecte-fil.mjs    # 79-07b : point d'entrée du worker_threads
├── vf-cockpit-registre.mjs        # 79-07b : lecture des entrées closes du registre (D5 lecture)
├── vf-cockpit-etat.mjs            # 79-08 : route /api/vf/state + signature etat
├── vf-cockpit-frise.mjs           # 79-09 : route /api/vf/frise (bornes, projection)
└── tests/serveur-commun.sh        # 79-02 : aide de lancement (hors motif test-*.sh : ne compte pas comme suite)
plugin/cockpit/skills/cockpit-moteur/assets/
├── ui/69-vf-flux.js               # 79-10 : élection, relais, veille (chargé avant 70 : ordre alphabétique, build.mjs)
├── ui/0x-vf-etat.js               # 79-12 : magasin VF_ETAT
├── elk-fil.js                     # 79-13 : worker de mise en page (importScripts du vendor)
└── q/…                            # 79-15 : code de la page Q et du tiroir, en fichiers (skills/ est posé en arbre)
```

**Piège d'installation (vérifié)** : l'engine copie `scripts/` **à plat** (`*.sh *.mjs *.js *.txt *.json` + `tests/`),
tandis qu'un dossier `skills/<nom>/` est copié en arbre [VERIFIED: `67-CONTEXT.md` « Contraintes d'installation »]. Tout
fichier de code navigateur rangé « en fichiers » va sous `skills/cockpit-moteur/assets/`, jamais sous `scripts/<sous-dossier>/`.

### Pattern 1 : collecte dans un fil de travail, instantané immuable dans la boucle
**What :** la boucle principale garde `fs.watch`, l'anti-rebond, le HTTP et la diffusion ; un `Worker` exécute les
collecteurs synchrones existants et rend un objet sérialisable ; la boucle calcule les signatures et émet.
**When :** 79-07b (H2), puis 79-08/79-09 s'y branchent.
**Exemple (forme, à adapter) :**
```js
// vf-cockpit-collecte.mjs — [ASSUMED] squelette ; collectWho, buildProjectGraph, ID_RE : noms lus dans le code présent
import { Worker } from 'node:worker_threads';
export function creerCollecte({ racine, sortie, dossierModule }) {
  const fil = new Worker(new URL('./vf-cockpit-collecte-fil.mjs', import.meta.url), { workerData: { racine, sortie, dossierModule } });
  let enVol = null;
  const demander = (motif) => enVol ??= new Promise((ok) => { fil.once('message', (m) => { enVol = null; ok(m); }); fil.postMessage({ motif }); });
  return { demander, arreter: () => fil.terminate() };
}
```
Le chemin du fil vient du **module** (`import.meta.url` du module, AM4), jamais de la sortie.

### Pattern 2 : élection d'onglet (C4)
```js
// ui/69-vf-flux.js — [ASSUMED] squelette ; repli « un flux par page » si navigator.locks ou BroadcastChannel manque
const canal = new BroadcastChannel('vf-cockpit-flux');
navigator.locks.request('vf-cockpit-flux', () => new Promise(() => { /* élu : ouvrir l'EventSource, relayer chaque événement sur `canal` */ }));
canal.onmessage = (e) => { /* non élu : distribuer comme un événement du flux */ };
```
La promesse jamais résolue tient le verrou jusqu'à la décharge du document, puis un autre onglet l'obtient [CITED:
w3c.github.io/web-locks § 2.6]. Un lab = un port = une origine : le canal ne mélange jamais deux labs. `127.0.0.1` et
`localhost` sont deux origines : deux flux, admis.

### Anti-Patterns à éviter
- **Ajouter du code dans un fichier proche de 300 lignes** : V4 de `test-cockpit-vendor.sh` échoue sur tout
  `scripts/*.mjs` de plus de 300 lignes [VERIFIED: `test-cockpit-vendor.sh:52`, `for f in "$SCRIPTS"/*.mjs; do [ "$(nlines "$f")" -le 300 ]`].
- **Passer la sortie au serveur par une variable d'environnement** : `hygiene.sh` reconnaît les serveurs d'une suite par
  la marque de son dossier temporaire « dans la ligne de commande de ses serveurs (chemin absolu du lab) »
  [VERIFIED: `scripts/tests/hygiene.sh:2-3`] et `estNotre` par la ligne de commande ; une sortie en environnement rend les
  fuites invisibles et confond deux labs servis par le même module.
- **Écrire la règle « nœud dans le mandat » dans le corps d'un agent** : budget d'instructions armé,
  `vf-dev-manager.md` à 250 lignes (scout-secu § 4.3).
- **Une assertion qui saute en silence** : `test-cockpit-questions.sh:90` détecte « dépôt de dev » par
  `[ -f "$SCRIPTS/../amont/synchro.sh" ]` ; après 79-01, Q11 sauterait (« non comptée comme réussie ») et la suite
  resterait verte. À corriger dans 79-01.

## Plans — réalisation, témoin, fichiers

Abréviations : `S/` = `plugin/cockpit/scripts/`, `M/` = `plugin/cockpit/skills/cockpit-moteur/`, `T/` = `S/tests/`.
« Témoin » = assertion qui **rougit sur le code présent** et verdit après le plan.

### 79-01 — Fork assumé : retrait de l'appareil de patchs (H5) — vague 1

**Réalisation.**
1. Supprimer `plugin/cockpit/amont/` (19 diffs, `synchro.sh`, `SYNCHRO.md`, manifeste).
2. `M/VENDORED.txt` : garder l'en-tête d'origine (ligne 1, lue par V1 : `head -1 … | grep -c 'v0.6.0 @ 92d6854'`
   [VERIFIED: `test-cockpit-vendor.sh:28`]), les lignes `AJOUT` (inventaire du plafond, lues par V4 l. 53 et V9.3/V9.5) et
   les lignes `TAILLE` (marqueur `vibeflow:allow-large-file`, V4 l. 45-49) ; retirer `PATCH` et `RETRAIT`.
   `VENDORED.txt` reste la **sentinelle du moteur** : `engineDir` exige `VENDORED.txt` et `assets/viewer.html`
   [VERIFIED: `S/vf-cockpit-paths.mjs:118-122`, `isFile(path.join(d, 'VENDORED.txt')) && isFile(path.join(d, 'assets', 'viewer.html'))`].
3. `T/test-cockpit-vendor.sh` : retirer V6 (l. 64-70), V7 PATCH/RETRAIT (l. 72-81), V9.4 (citation P26 et égalité
   `TAILLE assets/serve.mjs` = lignes réelles, l. 132-137 — sinon chaque édition de `serve.mjs` réécrit `VENDORED.txt`,
   coût que le fork doit retirer) ; garder V1-V5, V8, V9.1-V9.3, V9.5.
4. `T/test-cockpit-git-env.sh` E8.4 (l. 430-432) lit la ligne `PATCH scripts/lib/common.mjs` : la remplacer par le seul
   commentaire de `common.mjs`.
5. `T/test-cockpit-questions.sh:90` : détecteur de dépôt de dev = présence de `.planning/` trois niveaux au-dessus, plus
   `amont/synchro.sh` ; chercher la mesure par motif `*-MESURE-claude-p.md` (la plus récente : 79-05 en pose une).
6. `DESIGN.md` racine l. 221 (table : « journal des patchs ») et l. 234-235 (règle « le tracer dans `VENDORED.txt` dès
   qu'on touche un fichier du moteur ») : réécrire « inventaire de nos fichiers ». `S/vf-cockpit-fr-inventaire.mjs:3`
   (commentaire « base de la synchro amont ») : facultatif.

**Témoin.** Dans `test-cockpit-vendor.sh`, nouvelles assertions « V10 — `amont/` absent du dépôt » et « V10 — aucune ligne
`PATCH` ni `RETRAIT` dans `VENDORED.txt` » : rouges aujourd'hui (le dossier existe, 13 lignes `PATCH`). Dans
`test-cockpit-questions.sh`, « Q11.0 — dans le dépôt, la mesure est trouvée » (échoue si `.planning/` existe et que
`MESURE` est vide) : sans ce témoin le saut silencieux passerait.

**Fichiers.** `plugin/cockpit/amont/**` (suppression), `M/VENDORED.txt`, `T/test-cockpit-vendor.sh`,
`T/test-cockpit-git-env.sh`, `T/test-cockpit-questions.sh`, `DESIGN.md`, (`S/vf-cockpit-fr-inventaire.mjs`).
**Pas** de CHANGELOG ni README du module ici (79-17).
**Pièges.** `plugin/_internal/tests/test-vibeflow-update-cockpit.sh:62,85,94` exige `VENDORED.txt` posé dans les trois
scopes : le garder. Aucun gate `scripts/check-*.sh` ne lit `amont/` (scout-front § 1) : pas de Gate-Touche.

### 79-02 — Aide commune de lancement des suites (AM7 reste) — vague 1

**Réalisation.** Créer `T/serveur-commun.sh` (nom hors motif `test-*.sh` : pas de compteur) qui expose
`vf_serveur_lancer <sortie> [args…]` (lance aujourd'hui `node "<sortie>/serve.mjs"`, rend le PID, l'inscrit pour
`hygiene.sh`), `vf_serveur_attendre <sortie>` (attente active de `server.json` bornée, au lieu des `sleep` fixes),
`vf_serveur_port`, `vf_serveur_jeton`. Migrer **toutes** les suites qui lancent `<sortie>/serve.mjs` (51 fichiers citent
`serve.mjs` [VERIFIED: grep]) **sauf** `test-cockpit-questions.sh`, `test-cockpit-git-env.sh` (79-01 les touche, 79-05
les migre) et `test-cockpit-vendor.sh` (ne lance rien). But : en 79-05, « lancer depuis le module » ne change que l'aide.
Les autres mutualisations (préambule, `assert_eq` redéfini dans 77 suites) restent hors de ce plan : la classe est
« lancement du serveur », pas « tout le préambule ».

**Témoin.** Un témoin de l'aide elle-même, dans une suite existante peu chargée (ex. `test-cockpit-flux-unique.sh`) :
« le serveur lancé par l'aide est vu par `vf_hyg_vivants` » (sinon une fuite ne rougirait plus). Rouge aujourd'hui :
la fonction n'existe pas. Témoin global : `grep -L serveur-commun.sh` sur les suites migrées = vide.
**Fichiers.** `T/serveur-commun.sh` (nouveau) + ≈ 47 suites `T/test-cockpit-*.sh` et `T/terminal-aux.mjs` si concerné.
**Pièges.** Ne pas toucher le filtre de kill de `hygiene.sh` (G1-G5) ; la sortie reste un **argument** du lanceur de
serveur (la marque y figure). Conflits textuels probables avec les Phases 73/74/80 qui éditent les mêmes suites (table
finale) : changement mécanique d'une ligne par suite, à rebaser.

### 79-03 — Registre du verrou conservé, rétention 24 h, lecture des entrées closes (D5, I37 conductor) — vague 1

**Réalisation.** Dans `plugin/conductor/scripts/driver-lock.sh`, `release` supprime aujourd'hui le registre sans enfant
ouvert [VERIFIED: l. 1239-1240, `else` / `rm -f "$REG"`]. Le garder ; purger à chaque `register`, `close` et `release`
les entrées dont `epoch` date de plus de 86 400 s (chaque ligne porte `"epoch": %s` [VERIFIED: l. 1312 (`register`), l. 1337 (`close`)]),
par écriture d'un fichier temporaire puis renommage (le registre est en ajout seul ; la purge est la seule réécriture,
à faire hors du chemin d'ajout concurrent : relire, filtrer, renommer, sous le même verrou d'écriture que les autres
réécritures de `driver-lock.sh` s'il en existe un, sinon dire la course en limite). Ajouter un verbe de lecture
`registre` (JSON une ligne : dernier état par agent, `node`, `role`, `parent`, `status`, `epoch`, fenêtre 24 h) qui
réutilise `registry_fold` (lecteur unique [VERIFIED: l. 641, « `registry_fold` ci-dessous est l'unique lecteur, jamais un parse a la main ailleurs. »]).
Mettre à jour l'en-tête des verbes (l. 32-35).

**Témoin.** `test-driver-lock.sh` T63.7 affirme aujourd'hui la suppression
[VERIFIED: l. 950-951, `assert "T63.7, registre supprimé par un release propre" "$_t63_gone" 'no'`] : le réécrire en
« conservé » (rouge aujourd'hui) ; ajouter T63.8 « `registre` rend l'entrée close avec son `node` après le release »
et T63.9 « une entrée de plus de 24 h est purgée au `register` suivant » (horloge injectée par la variable de temps du
script s'il en a une, sinon `epoch` écrit à la main dans le fichier). `test-driver-lock-ws.sh` WS-VERBS-3.22 (l. 916)
affirme la suppression du registre d'un compartiment : même réécriture.
Effet de bord connu : T64.4 (`close` sans registre → `no-registry`) reste vrai seulement sans registre ; à rejouer.

**Fichiers.** `plugin/conductor/scripts/driver-lock.sh`, `plugin/conductor/scripts/tests/test-driver-lock.sh`,
`…/test-driver-lock-ws.sh` (+ `…/test-driver-lock-phase.sh` si PH-REG suppose la suppression), `plugin/conductor/VERSION`,
`CHANGELOG.md`, `README.md` du conductor (en-tête `**Version**` gaté par `check-version-sync.sh`).
**Gate-Touche obligatoire** (suites conductor surveillées). À rejouer : `test-driver-lock-consumers-ws.sh`,
`test-driver-lock-phase-consumers.sh`, `test-guard-driver-lock*.sh`, `test-runtime-registry.sh`,
`plugin/dev-orchestrator/scripts/tests/test-check-mission-exit*.sh` (lit `children_running`, inchangé).

### 79-04 — Nœud écrit dans chaque mandat (I37 doctrine) — vague 2 (pas 1 : recouvrement)

**Recouvrement corrigé.** 79-03 et 79-04 touchent tous deux le module `conductor` (VERSION, CHANGELOG, README) : en
vague 1 ensemble, ils se recouvrent. 79-04 passe en vague 2.
**Réalisation.** Une ligne au gabarit du digest de `plugin/dev-orchestrator/references/mission-contracts.md` (bloc
l. 75-83 [VERIFIED]) : ``- Nœud : `<id du nœud DAG>` `` ; une phrase au kernel (`plugin/conductor/references/team-kernel.md`,
ligne de table « Digest de mission » l. 22 ou puce « Digest dans chaque mandat » l. 193) qui vaut pour les deux managers ;
rien dans les corps d'agents. La forme doit être celle que lit le cockpit :
`CITATION = /n(?:[œŒ]|oe|OE)ud\s{0,8}:?\s{0,8}`([A-Za-z0-9][A-Za-z0-9._-]{0,63})`/gi` [VERIFIED: `S/vf-cockpit-transcript.mjs:63`].
**Témoin.** Extraire la ligne « Nœud » du gabarit de `mission-contracts.md`, y substituer un identifiant d'essai, la
passer à `citationsDuMandat` : rend `[id]`. Rouge aujourd'hui (aucune ligne). À placer dans une suite du dev-orchestrator
(`plugin/dev-orchestrator/scripts/tests/…`) avec chemin du cockpit résolu dans le dépôt, saut **compté rouge** si le
fichier manque dans le dépôt.
**Fichiers.** `mission-contracts.md`, `team-kernel.md`, VERSION/CHANGELOG/README de `dev-orchestrator` et de
`conductor`, une suite dev-orchestrator. **Jamais** `plugin/*/agents/*.md`.

### 79-05 — Serveur lancé depuis le module (AM4, A-03, H3 reste, D-M13, AB1) — vague 2

**Ce qui est évalué depuis la sortie aujourd'hui** (scout-secu § 1.3, vérifié par lecture) : `spawn(process.execPath, args…)`
avec `args = [path.join(sortie, 'serve.mjs'), '--idle-exit', '60']` [VERIFIED: `S/vf-cockpit.mjs:181,192`] ;
`serve.mjs` importe `./vf-cockpit-env.mjs`, `./vf-cockpit-terminal.mjs`, `./vf-cockpit-server.mjs` à côté de lui
[VERIFIED: `M/assets/serve.mjs:24,176,182`] et évalue le cœur de `query.mjs` par `new Function` [VERIFIED: l. 186-187] ;
l'agent lance `node .vibeflow/cockpit/query.mjs` et `…/vf-cockpit-query.mjs` [VERIFIED: `S/vf-cockpit-agent.mjs:17`].

**Réalisation, dans cet ordre.**
1. **Noms VibeFlow dans les sources du code exécuté côté serveur** (fork assumé) : appliquer `renommerTexte` une fois à
   `M/assets/serve.mjs`, `M/assets/graph-query.js`, `M/assets/query-cli.mjs` et aux trois modules écrits sous l'ancien nom
   (`S/vf-cockpit-embed.mjs:6`, `S/vf-cockpit-lancer-post.mjs:13`, `S/vf-cockpit-server.mjs:123`). Les **pages**
   (`viewer.html`, `ui/*.js`) restent renommées à l'assemblage dans ce plan (elles sont des données servies) : les
   renommer ici toucherait 20 fichiers `ui/` partagés avec 73, 74 et 80.
   **Piège d'ordre** : `assembler` insère les données **avant** le renommage des pages
   [VERIFIED: `S/vf-cockpit-build.mjs:106-116`] avec le `DATA_START` de `embed.mjs`. Une fois `embed.mjs` renommé
   (`window.VF_COCKPIT = `), insérer **après** `renommerHtml`, ou le gabarit amont ne contient plus le marqueur attendu.
   Même piège à l'exécution : `live.mjs` relit `project.html` (renommé) avec `extraireGraphe` [VERIFIED: `S/vf-cockpit-live.mjs:82-84`].
2. **Séparer code et données dans `serve.mjs`** : `here` (module, `import.meta.url`) ≠ `sortie` (argument `--sortie`,
   posé par le lanceur) ; `root` dérivé de la sortie réelle et revérifié (`verifierSortie`) ; imports dynamiques depuis
   le dossier de scripts **de confiance** (`VF_COCKPIT_SCRIPTS_DIR`, déjà posé par le lanceur
   [VERIFIED: `S/vf-cockpit.mjs:188`]) — en pose `user`, `serve.mjs` (sous `skills/`) et les modules (sous `scripts/`)
   ne sont pas voisins. `attach({ here, root, … })` reçoit `sortie` en plus ; `server.mjs:46` lit `project.html` dans la
   sortie. Le cœur de requête se lit dans `M/assets/graph-query.js` (module), plus dans `<sortie>/query.mjs`.
3. **Assemblage** : `vf-cockpit-build.mjs` ne copie plus aucun code (l. 111, 117, et le contrat l. 118) ; `M/scripts/build.mjs`
   n'écrit plus `query.mjs` ni `serve.mjs` dans la sortie (l. 455-458, scout-secu) ; **purger** de la sortie, à chaque
   assemblage, les fichiers de code laissés par une version précédente (`*.mjs`, `query.mjs`, `vf-cockpit-interface.json`)
   — sinon un lab mis à jour garde un `serve.mjs` périmé (§ Runtime State Inventory).
4. **Agent confiné** : `query.mjs` et `vf-cockpit-query.mjs` lancés depuis le module, la sortie trouvée par `findLabRoot(cwd)`.
   `ARGS_CONFINEMENT` change ; il « recopie » la « Combinaison retenue » de la mesure [VERIFIED: `S/vf-cockpit-agent.mjs:2-3`]
   et Q11 le compare élément par élément [VERIFIED: `T/test-cockpit-questions.sh:254`]. **Refaire la mesure** (§ 79-05 mesure).
5. **Empreinte (H3)** : `vf-cockpit-module.mjs` exporte `empreinteCode(dossierModule)` = sha sur la liste triée du code
   évalué (`serve.mjs`, `graph-query.js`, `query-cli.mjs`, chaque `vf-cockpit-*.mjs` exécuté, `vf-cockpit-interface.json`) ;
   le serveur la publie (aujourd'hui `selfHash` = sha1 de `serve.mjs` seul [VERIFIED: `M/assets/serve.mjs:92`]) et le
   lanceur la compare (aujourd'hui `empreinteCode(sortie)` = sha1 de `<sortie>/serve.mjs` [VERIFIED: `S/vf-cockpit.mjs:69`]).
6. **Reconnaissance du processus** : `estNotre` vérifie aujourd'hui `cmd.includes(serve)` avec `serve = <sortie>/serve.mjs`
   [VERIFIED: `S/vf-cockpit.mjs:85,90`]. Nouveau critère : chemin réel du `serve.mjs` du module **et** `--sortie <sortie réelle>`
   dans la même ligne de commande. **Transition** : accepter aussi l'ancienne forme `<sortie>/serve.mjs`, sinon un serveur
   lancé par la version précédente n'est ni arrêté (`stop` → « PID non reconnu », exit 5) ni remplacé (second serveur sur port+1).
7. **D-M13** : `status` et `stop` passent par la détection d'orphelin (`serveurOrphelin`, aujourd'hui seulement dans `open`
   et seulement si `<sortie>/serve.mjs` existe [VERIFIED: `S/vf-cockpit.mjs:247`]) ; séparer « détecter » (sans écriture,
   pour `status`) de « adopter » (réécrit `server.json`, `S/vf-cockpit-lanceur-verrou.mjs:78-80`).
   `vf-cockpit.mjs` est à 273 lignes : extraire `serveurVivant`, `estNotre`, `arreter` dans `vf-cockpit-serveur-vivant.mjs`
   (79-08 le réutilise pour l'émetteur).
8. **AB1** (déplacé ici depuis 79-07 pour libérer `serve.mjs` en vague 3) : `claude --version` passe de `execFileSync`
   (`timeout: 15000`) à `execFile` [VERIFIED: `M/assets/serve.mjs:171`] ; `version` n'est lu par aucune page
   (scout-front § 7) : seul `/api/health` le rend, `null` jusqu'à la réponse.
9. `README.md` du module l. 204-205 (« aucun de ses scripts n'est exécuté ») est faux aujourd'hui : réécriture en 79-17,
   même PR.

**Mesure de confinement (obligatoire, AM4).** `67-MESURE-claude-p.md` a été prise sous Claude Code 2.1.316 avec des
chemins relatifs `Bash(node .vibeflow/cockpit/query.mjs:*)` [VERIFIED: `67-MESURE-claude-p.md:4,99-100`] ; le poste
porte 2.1.322 [VERIFIED: `claude --version`]. Un chemin **absolu** du module dans une règle `Bash(node <chemin>:*)` n'a
jamais été mesuré (chemin avec espace, guillemets ajoutés par l'agent, lien symbolique du scope). Plan : tâche
`checkpoint:human-verify` ou tâche d'exécuteur qui rejoue le harnais de la 67 (cas B1, B2, B3, R1, R2, R3, M1, M2 et les
variantes du mode explicite) avec la nouvelle liste, et écrit `79-MESURE-claude-p.md` (même format, section
`## Combinaison retenue`, chemins du poste masqués comme dans la 67). Si le verdict n'est pas CONFINABLE : garder l'agent
sur des chemins relatifs n'est pas une option (code du lab), le repli est « agent sans Bash » (réponse locale seule) —
décision à remonter, pas à prendre dans le plan.

**Témoins.**
- A-03 : nouveau cas dans `test-cockpit-securite.sh` : planter un marqueur dans `<sortie>/vf-cockpit-server.mjs` et
  `<sortie>/query.mjs` d'une sortie assemblée, lancer par le lanceur, constater que le marqueur ne s'exécute jamais
  (fichier témoin non créé) — rouge aujourd'hui (la copie est importée). Témoin positif : le même marqueur posé dans une
  copie du **module** s'exécute.
- H3 : modifier un octet d'un module autre que `serve.mjs` dans une copie du module → `open` relance (« code du serveur
  changé ») — rouge aujourd'hui (seul `serve.mjs` est haché).
- D-M13 : serveur vivant, `server.json` supprimé → `status` le dit vivant, `stop` l'arrête — rouge aujourd'hui
  (« Cockpit arrêté. » / « déjà arrêté »).
- Q11 : `ARGS_CONFINEMENT` = « Combinaison retenue » de `79-MESURE` (le détecteur de 79-01 prend la plus récente).

**Fichiers.** `M/assets/serve.mjs`, `M/assets/graph-query.js`, `M/assets/query-cli.mjs`, `M/scripts/build.mjs`,
`S/vf-cockpit.mjs`, `S/vf-cockpit-lanceur-verrou.mjs`, `S/vf-cockpit-build.mjs`, `S/vf-cockpit-embed.mjs`,
`S/vf-cockpit-lancer-post.mjs`, `S/vf-cockpit-server.mjs`, `S/vf-cockpit-query.mjs`, `S/vf-cockpit-agent.mjs`,
`S/vf-cockpit-drift.mjs` (commande affichée, `import.meta.url` l. 27), `S/vf-cockpit-terminal*.mjs` si leurs chemins
supposent la sortie, `S/vf-cockpit-module.mjs` et `S/vf-cockpit-serveur-vivant.mjs` (nouveaux), `T/serveur-commun.sh`,
`T/test-cockpit-questions.sh`, `T/test-cockpit-git-env.sh`, `T/test-cockpit-assemblage.sh`, `-cycle-serveur.sh`,
`-demander-bornes.sh`, `-lancer-post.sh`, `-securite.sh`, `-marque-blanche.sh` (compte désormais dans les **sources**
du code serveur), `plugin/_internal/tests/test-vibeflow-update-cockpit.sh` si la pose change, phase :
`79-MESURE-claude-p.md`. **Interdit dans ce plan** : `S/vf-cockpit-paths.mjs` (79-06), `S/vf-cockpit-live.mjs` (79-07b),
`S/vf-cockpit-interface.json` (79-07a).
**Pièges.** `live.mjs:58` résout `scriptsDir` par `resolveScriptsDir(sortie)` : avec `sortie` = données, hors lanceur
(suites) il rendrait la sortie ; corrigé en 79-07b (le fil de collecte reçoit `dossierModule`). En pose `project`, le
module vit sous `<lab>/.claude/` : AM4 retire la **sortie** comme source de code, pas le lab tout entier — limite à
écrire (README, 79-17).

### 79-06 — Résolution physique (A-02 reste), cible interne protégée (D-M15), pilotes nommés et enfants shell (A-04) — vague 2

**Réalisation.**
1. **G1** : la cible d'un lien se juge par sa résolution **physique** : `dans(path.resolve(d, fs.readlinkSync(…)), g)`
   [VERIFIED: `S/vf-cockpit-git-sortant.mjs:30`] devient « `fs.realpathSync` du lien lui-même comparé à `realpath(g)` ; lien
   pendant ou en boucle = sortant », sauf la forme exacte du verrou de pilotage (`.git/vf-driver/**/DRIVER.lock` → nom de
   génération relatif sans `/`, scout-secu § 2). Copie octet pour octet dans `M/scripts/lib/vf-git-sortant.mjs` (consommée
   par `M/scripts/lib/common.mjs:5,210`).
2. **G2** : `real()` replie sur `path.resolve` quand `realpath` échoue [VERIFIED: `S/vf-cockpit-git-sortant.mjs:16`,
   `S/vf-cockpit-paths.mjs:68`] ; dans tout contexte de garde (`realUnder`, inclusions de configuration, `core.worktree`),
   un échec vaut « dehors ». Garder le repli là où il ne garde rien (affichage).
3. **D-M15** : `M/scripts/scan.mjs:70` admet un lien dont la cible réelle est dans le lab, quelle qu'elle soit ; le juger
   comme son chemin cible le serait (segment caché, sortie du cockpit, dossier git, fichier ignoré), mêmes exclusions que
   la marche et que le service statique (`M/assets/serve.mjs:599`).
4. **A-04 pilotes** : les options de lecture ne sont insérées que pour `log`, `show`, `diff-tree`, `diff`, `status`, et
   les filtres vidés seulement pour `['status', 'diff', 'ls-files', 'stash']`
   [VERIFIED: `S/vf-cockpit-paths.mjs:150-152`]. Règle de classe : lire une fois les pilotes nommés déclarés
   (`filter.*`, `diff.*.textconv`, `diff.*.command`, `merge.*.driver`) et les vider pour **tout** lancement, quelle que soit
   la sous-commande ; refuser une sous-commande absente d'une liste fermée des sous-commandes utilisées.
5. **A-04 enfants shell** : `shBorne` lance tout non-git avec `envEnfant(lab)` [VERIFIED: `S/vf-cockpit-paths.mjs:220`] ;
   `driver-lock.sh` (qui appelle git) reçoit donc les `GIT_*` hérités. Donner `envGit(lab)` à `shBorne('bash', …)`. Le
   lancement direct de `live.mjs:66` (`execFileSync('bash', …, { env: envEnfant(root) })` [VERIFIED]) est repris en
   79-07b (le fil de collecte passe par `shBorne`) : `live.mjs` n'est pas un fichier de ce plan.
6. `vf-cockpit-paths.mjs` est à 296 lignes : extraire `lancer`, `lancerAsync`, `shBorne`, `lancerGit`, `lancerGitAsync`,
   `filtres*` dans `vf-cockpit-git-lanceur.mjs`, ré-exportés par `paths.mjs` (aucun import des consommateurs ne change).

**Témoin (A-02 : génératif, pas une liste).** Dans `T/test-cockpit-confinement.sh`, section neuve « G15 » :
générateur à graine (graine imprimée pour rejouer) qui construit, sous un `.git` d'essai, des arbres de dossiers et des
chaînes de liens internes de profondeurs variées dont les cibles combinent noms de liens existants et segments `..` ;
**oracle** = résolution réelle (`fs.realpathSync` de chaque lien, ou échec) ; **propriété** = pour chaque arbre,
`gitSortant` dit « sortant » si et seulement si au moins un lien résout physiquement hors de `G`/`C` ou ne résout pas.
Deux contrôles rendent la preuve capable de rougir : (a) **témoin de couverture** : sur N graines, au moins K arbres ont
une résolution lexicale ≠ physique (sinon le générateur ne produit pas la classe et la suite échoue) ; (b) **témoin
rouge** : la même propriété jouée contre la règle lexicale actuelle (copie de la fonction d'avant, gardée dans la suite)
trouve au moins un contre-exemple. Rouge aujourd'hui : la propriété échoue sur `git-sortant` présent.
D-M15 : cas section A, lien du lab vers un fichier interne protégé (contenu marqué) absent des pages ; témoin positif :
le même contenu en fichier normal y est. A-04 : dans `T/test-cockpit-git-config-depot.sh` (pas `-git-env.sh`, pris par
79-05), un pilote `diff.<n>.textconv` et un `merge.<n>.driver` déclarés par le dépôt ne s'exécutent sous **aucune**
sous-commande lancée par le socle ; un `driver-lock.sh` d'essai lancé par `shBorne` ne voit aucun `GIT_*` hérité.

**Fichiers.** `S/vf-cockpit-git-sortant.mjs`, `M/scripts/lib/vf-git-sortant.mjs`, `M/scripts/lib/common.mjs`,
`M/scripts/scan.mjs`, `S/vf-cockpit-paths.mjs`, `S/vf-cockpit-git-lanceur.mjs` (nouveau), `S/vf-cockpit-git-durci.mjs`
(si la liste des pilotes y vit), `T/test-cockpit-confinement.sh`, `T/test-cockpit-git-config-depot.sh`.
**Pièges.** `M/scripts/lib/vf-git-sortant.mjs` doit rester identique octet pour octet à la copie du socle (une suite le
vérifie, scout-secu § 2) ; la course contrôle/lecture reste une limite nommée (commentaire l. 10-11).

### 79-07a — Index incrémental pur + contrat de forme étendu (I20, D9) — vague 2

**Réalisation.** Modules purs, testables sans serveur :
- `vf-cockpit-index-voie.mjs` : réduction d'une ligne de transcript dans une voie (C3 sans `etatOfficiel` ni `cibles`) ;
  **jamais** de clé `outils`, `messages`, `fil`, `mandat`, `doing` (la garde refuse ces clés à toute profondeur
  [VERIFIED: `S/vf-cockpit-server.mjs:34-35`]) — le prototype nomme `outils` et `msgs` (scout-index Q3) : renommer.
- Segments typés (règle de scout-index Q5) : appel `AskUserQuestion` ouvert ou refus/permission en cours →
  `attend-humain` ; `Agent/Task/SendMessage` ouvert ou fin de tour avec `pendingBackgroundAgentCount > 0` →
  `attend-agents` ; autre appel ouvert → `travail` même long ; écart ≤ 180 s → `travail` ; `stop_reason: end_turn` puis
  écart → `repos` ; autre écart > 180 s → `silence`. Bornes ≤ 500 segments et événements, `tronque` sinon.
- `vf-cockpit-jetons.mjs` (exporté, pur) : dédoublonnage par `message.id`, dernière ligne gagne, curseur garde
  `dernierMsgId` + `usage` (un message à cheval sur deux lectures n'est jamais compté deux fois). La Phase 74 le réutilise.
- `vf-cockpit-index.mjs` : patron de lecture par décalage déjà livré (`dernierArbre`, `S/vf-cockpit-who.mjs:36-55`, lecture
  de `st.size - m.taille` octets depuis `m.taille`, plafond `AJOUT_MAX = 8 << 20`, scout-index Q1) ; chargement **non
  fiable** (C1) ; fenêtre 24 h ; identifiants filtrés par `ID_RE` (`S/vf-cockpit-lecture.mjs`) ; écriture tmp + rename,
  0600 ; aucune cible persistée (P79-D-04).
- `vf-cockpit-interface.json` : bloc `claudeCode.index` (C6 : `message.id`, `message.model`, `message.usage`,
  `stop_reason`, blocs d'appel et de résultat limités aux identifiants et à `is_error`, `compact_boundary`,
  `turn_duration`) ; description de `vueAgents` réécrite selon AUDC-Q4 (aujourd'hui « enrichissement optionnel … jamais
  la source unique » [VERIFIED: `S/vf-cockpit-interface.json:108`]) ; `verifieSur` aujourd'hui `"2.1.317"`
  [VERIFIED: l. 93] → revérifié sur la version mesurée (le poste porte 2.1.322) **par la suite de forme**, pas à la main.
  Un champ requis absent → voie `forme-inconnue`, jamais un zéro (P69-D-22).

**Témoins.**
- **Propriété d'incrémentalité (générative)** : pour des transcripts de fixture et des points de coupe aléatoires (graine
  imprimée), y compris au milieu d'une ligne et entre deux lignes d'un même `message.id`, l'index construit par ajouts
  successifs est égal à l'index construit en une passe. Rouge aujourd'hui : module absent ; rouge aussi contre une
  variante sans `dernierMsgId` (témoin gardé dans la suite : jetons comptés deux fois).
- Fichier raccourci, tête changée, taille < décalage → relu depuis zéro ; index au mauvais schéma ou hors bornes → écarté.
- **Balayage de contenu** : un marqueur posé dans le texte d'un message, une entrée d'outil et un `file_path` du lab
  n'apparaît jamais dans `index-transcripts.json` ; témoin positif : le marqueur est bien dans le transcript.
  (`test-cockpit-transcript.sh` T25.11 balaie déjà `.vibeflow/cockpit/` pour mandat et messages : le rejouer.)
- `test-cockpit-forme-claude.sh` : le bloc `index` est déclaré et chaque champ lu par l'index y figure (miroir de F11).

**Fichiers.** `S/vf-cockpit-index.mjs`, `S/vf-cockpit-index-voie.mjs`, `S/vf-cockpit-jetons.mjs` (nouveaux),
`S/vf-cockpit-interface.json`, `T/test-cockpit-forme-claude.sh`, **`T/test-cockpit-index.sh` (nouvelle suite : compteur
213 → 214 dans `README.md` et `README.fr.md`)**, fixtures `T/fixtures/test-cockpit-index/**`.

### 79-07b — Collecte hors boucle, lecture du registre, cache de scan (H2 reste, D5 lecture, AB1 rendu en 79-05) — vague 3

**Réalisation.**
- `vf-cockpit-collecte.mjs` + `vf-cockpit-collecte-fil.mjs` (Pattern 1) : le fil exécute `buildProjectGraph`,
  `driver-lock.sh status --all` **via `shBorne`** (fin de `live.mjs:66`, A-04), `collectWho(officiel)`, la mise à jour de
  l'index (écrivain unique : seul le serveur qui tient le verrou du lanceur écrit, C1) et produit l'instantané. Une seule
  demande en vol, les demandes suivantes se coalescent.
- `vf-cockpit-live.mjs` : garde `fs.watch`/scrutation, anti-rebond et confirmation de retrait (`HOLD_MS`), remplace les
  appels synchrones des l. 72, 92, 101, 147-148 par des demandes au fil ; l'état de démarrage devient `collecte.etat:
  "en-cours"` (C2), plus une collecte synchrone complète au démarrage [VERIFIED: l. 72 `let graph = buildProjectGraph(root), …, lock = lockStatus(), who = whoNow(lock)`].
  Le filet garde ses règles AUDC-H2 (`aClient()`), le réveil aussi.
- `vf-cockpit-registre.mjs` : lit le verbe `registre` de 79-03 ; `rattacher` (`S/vf-cockpit-equipe.mjs:135-151`) consulte
  les entrées closes avant les citations du mandat. `who.mjs` (244 lignes) ne reçoit qu'un import.
- Cache de scan : `vf-cockpit-build.mjs:67` relance `scan.mjs` à chaque assemblage ; cache par date de modification des
  dossiers (côté `vf-cockpit-build.mjs`, pas `scan.mjs` : 79-06 tient `scan.mjs` en vague 2, et c'est fini en vague 3 —
  l'un ou l'autre convient, choisir `vf-cockpit-build.mjs`).

**Témoin (H2).** Nouvelle suite `T/test-cockpit-collecte.sh` : dossier de scripts de confiance d'essai portant un
`driver-lock.sh` qui dort 3 s (`VF_COCKPIT_SCRIPTS_DIR`), serveur lancé par l'aide ; pendant la collecte,
`GET /api/vf/etat` répond en moins de 200 ms. Rouge aujourd'hui : la collecte synchrone bloque la boucle 3 s. Témoin
positif : le `driver-lock.sh` lent a bien été appelé (journal d'appel). D5 : un agent consigné puis clos, verrou relâché
→ l'onglet Équipe le rattache encore à son nœud (rouge aujourd'hui : registre supprimé, rattachement perdu).

**Fichiers.** `S/vf-cockpit-collecte.mjs`, `S/vf-cockpit-collecte-fil.mjs`, `S/vf-cockpit-registre.mjs` (nouveaux),
`S/vf-cockpit-live.mjs`, `S/vf-cockpit-equipe.mjs`, `S/vf-cockpit-who.mjs` (import), `S/vf-cockpit-build.mjs`,
**`T/test-cockpit-collecte.sh` (compteur +1)**, `T/test-cockpit-direct.sh`, `T/test-cockpit-who.sh`,
`T/test-cockpit-equipe*.sh` à rejouer (touchés seulement si une assertion suppose la collecte synchrone).
**Pièges.** `process.chdir` est indisponible dans un fil ; tout `cwd` passe en option ; le fil reçoit `dossierModule`
(module) et `sortie` (données), jamais un chemin lu d'un fichier du lab. Un fil qui meurt : relancé une fois, puis
`collecte.etat: "indisponible"`, jamais un serveur muet.

### 79-08 — Route d'état, événements `etat` et `vie`, `vf-signal` par la route (I19, AM1, D-M2 serveur) — vague 4

**Réalisation.**
- `vf-cockpit-etat.mjs` : `GET /api/vf/state` → enveloppe C2 autour du `signal@1` produit **dans le fil de collecte**
  (`collectSignal` existant [VERIFIED: `S/vf-cockpit-signal.mjs:36-40`], même échéance de 15 s, `ECHEANCE_MS = 15000`
  [VERIFIED: l. 32]) ; la route lit le dernier instantané, ne déclenche rien ; 503 `emission-refusee` si `porteInterdit`.
- `vf-cockpit-server.mjs` : route branchée en une ligne ; le battement passe du commentaire `: ka` toutes les 15 s
  [VERIFIED: l. 91, `setInterval(() => res.write(': ka\n\n'), 15000)`] à `event: vie` `{seq, at}` (passé par
  `diffuser`, donc par la garde) ; événement `etat` `{seq, at, sig}` au seul changement.
- Interface : schéma `vibeflow/cockpit-state@1` déclaré dans `vf-cockpit-interface.json` (C0 « Versions »).
- `vf-signal` sans changer le mod : l'**émetteur** `vf-cockpit-signal.mjs <racine>` (CLI sans option, P68-D-28) regarde
  d'abord si un serveur du lab vit et est reconnu (`vf-cockpit-serveur-vivant.mjs` de 79-05 : PID vivant, ligne de
  commande du `serve.mjs` du module avec cette sortie) ; si oui, `GET /api/vf/state` sur `127.0.0.1:<port>` (port seul
  lu de `server.json`, adresse reconstruite comme P71-D-25), jeton en `x-vf-cockpit-token`, `Host` explicite, pas
  d'`Origin` ; rend `signal` si `schema` et forme sont bons, sinon collecte locale (repli inchangé, P68-D-41). Le mod
  valide déjà `schema === 'vibeflow/cockpit-signal@1'` [VERIFIED: `plugin/cockpit/signal/hooks/socle.ts:11,68`] et la
  complétude (l. 38-49) : rien à changer côté mod.

**Témoins.**
- Route : 200 + `schema` + `signal` complet ; 403 sans jeton, Origin étrangère, Host inconnu ; 405 en POST ;
  503 contrat illisible (copie de la sortie avec contrat vidé, patron EQ.3 de `test-cockpit-serveur.sh`) ; **aucune
  collecte déclenchée** : N requêtes ne font pas bouger le compteur de collectes. Rouge aujourd'hui : 404.
- `vf-signal` : `driver-lock.sh` d'essai qui journalise ses appels ; serveur vivant → l'émetteur ne l'appelle **pas**
  (0 ligne) ; serveur arrêté → il l'appelle (repli). Rouge aujourd'hui : l'émetteur appelle `driver-lock.sh` deux fois
  (scout-socle § 4). Leurre : un `server.json` qui désigne le port d'un autre processus local → repli, jamais la réponse
  de ce processus.
- Battement : un client lit au moins un `event: vie` en 16 s (rouge aujourd'hui : seul `: ka`, invisible au JavaScript).

**Fichiers.** `S/vf-cockpit-etat.mjs` (nouveau), `S/vf-cockpit-server.mjs`, `S/vf-cockpit-signal.mjs`,
`S/vf-cockpit-collecte*.mjs` (production du signal et de sa signature), `S/vf-cockpit-interface.json`,
**`T/test-cockpit-etat.sh` (compteur +1)**, `T/test-cockpit-signal.sh`, `T/test-cockpit-serveur.sh`.
**Pièges.** `pageEquipe` (« page Équipe sans reconstruction par requête », découpage provisoire) dépend de la coquille :
le déplacer en 79-11a. `vf-cockpit-signal.mjs` ajoute un appel HTTP : borne 1,5 s comme `lireHttp`
(`S/vf-cockpit-lanceur-verrou.mjs`), jamais une attente du mod au-delà de ses 15 s.

### 79-09 — Route de frise et événement `frise` (I20 route) — vague 5

**Réalisation.** `vf-cockpit-frise.mjs` : bornes C3 (`depuis`, `jusqua` entiers en ms, ramenés à [maintenant − 24 h,
maintenant], 400 `bornes-invalides`), projection des voies de l'index **sans** `curseur`, `etatOfficiel` joint en direct
(`claude agents --json`, déjà lu par `S/vf-cockpit-etat-officiel.mjs`), `cibles` en mémoire (passe de fond au démarrage,
`etat: "en-construction"` pendant) ; garde `porteInterdit` ; événement `frise {seq, at, sig}` (16 caractères, patron
`git` [VERIFIED: `S/vf-cockpit-live.mjs:153`, `sig: gs.slice(0, 16)`]) émis par la collecte au seul changement.
Schéma `vibeflow/cockpit-frise@1` au contrat.
**Témoins.** 400 sur `depuis` non entier et `depuis ≥ jusqua` ; `depuis` vieux de 48 h ramené à 24 h ; aucune clé
`curseur` ni `octets` dans la réponse ; balayage : aucun chemin absolu dans `cibles` (« un fichier hors du lab ») ; index
en construction → 200 `en-construction`. Rouge aujourd'hui : 404.
**Fichiers.** `S/vf-cockpit-frise.mjs` (nouveau), `S/vf-cockpit-server.mjs`, `S/vf-cockpit-collecte.mjs`,
`S/vf-cockpit-interface.json`, **`T/test-cockpit-frise.sh` (compteur +1)**.

### 79-10 — Flux partagé entre onglets, veille de silence (H1 reste, I22, D-M2 page) — vague 5

**Réalisation.** `ui/69-vf-flux.js` (nouveau, chargé avant `70` : les `ui/*.js` sont chargés triés
[VERIFIED: `M/scripts/build.mjs:448`, `fs.readdirSync(uiDir).filter((n) => n.endsWith('.js')).sort()`]) : élection par Web
Lock, relais `BroadcastChannel`, repli « un flux par page » si l'une des primitives manque (C4) ; veille : au-delà de
45 s sans **aucun** événement (dont `vie`), `perdu('direct', connecter)` (fonction existante
[VERIFIED: `ui/70-vf-live.js:249-254`]). `70-vf-live.js` (285 lignes) ne garde que les abonnements ; la connexion
(`connecter`, l. 259-283) part dans le nouveau fichier.
**Témoins.** Deux pages du même lab ouvertes → le serveur compte **un** flux (`/api/vf/etat` `clients: 1`) ; fermer
l'onglet élu → l'autre reprend sans rechargement ; un serveur qui garde la connexion ouverte sans rien envoyer pendant
46 s → la pastille passe à « Direct coupé ». Rouge aujourd'hui : deux flux ; aucun passage à « coupé » sur silence.
Suites existantes : `test-cockpit-flux-unique.sh`, `test-cockpit-direct-coupe.sh`, `test-cockpit-reconnexion.sh`
(Chrome, saut **compté rouge** en CI selon `chrome-saut.sh`).
**Fichiers.** `M/assets/ui/69-vf-flux.js` (nouveau, ligne `AJOUT` dans `VENDORED.txt`), `M/assets/ui/70-vf-live.js`,
les trois suites citées, `M/VENDORED.txt`.
**Pièges.** Un onglet en arrière-plan voit ses minuteries ralenties : la veille compare des instants, elle ne compte pas
des ticks. Le jeton Code et le jeton Projet diffèrent : l'élu ouvre le flux avec **son** jeton ; un relais n'emporte
jamais de jeton.

### 79-11a — Route graphe, fin de la réécriture de `project.html`, Équipe sans reconstruction (AM1, I31) — vague 6

**Réalisation.** `GET /api/vf/graphe?onglet=code|projet|equipe` (C5 : `ETag` = signature, `If-None-Match` → 304,
400 `onglet-invalide`) ; `live.mjs` ne réécrit plus `project.html` (aujourd'hui `ecrirePage` à tout changement
[VERIFIED: `S/vf-cockpit-live.mjs:106`]) ; la page Équipe n'est plus construite en mémoire à 2,5 Mo par changement
(`pageEquipe`, `S/vf-cockpit-server.mjs:143-155`) ; l'outil de l'agent (`vf-cockpit-query.mjs`) lit l'état Projet dans
un **fichier de données** écrit au changement (`projet.json`, 0600, tmp + rename) — sinon l'agent verrait un
`project.html` figé. L'export reste une page autonome (coquille + données incluses).
**Témoins.** 304 sur `If-None-Match` égal ; `project.html` inchangé (mtime) après un changement de planning ; l'agent
(outil de requête lancé en processus) voit le nouveau statut ; l'export garde ses exclusions (`vfTouch`, `vfGit`,
`test-cockpit-confinement.sh` D). Rouge aujourd'hui : 404 ; `project.html` réécrit.
**Fichiers.** `S/vf-cockpit-server.mjs`, `S/vf-cockpit-live.mjs`, `S/vf-cockpit-collecte.mjs`, `S/vf-cockpit-query.mjs`,
`S/vf-cockpit-embed.mjs`, `M/assets/serve.mjs` (`/project.html`, `/equipe.html`), suite `T/test-cockpit-serveur.sh` +
`T/test-cockpit-equipe.sh` (assertions sur la page construite).

### 79-11b — Coquille statique servie du module, `ETag`, CSP (AM2) — vague 7

**Réalisation.** Une coquille par onglet servie depuis le module, assets lourds (ELK, polices, `ui/*.js`) en fichiers
sous un préfixe dédié (ex. `/_vf/`), mis en cache par `ETag` ; la page garde un petit script en ligne pour l'injection du
jeton. CSP de page : aujourd'hui `script-src <empreintes>` seulement [VERIFIED: `M/assets/serve.mjs:514`] ; passer à
empreintes + **source restreinte au préfixe** (`http://127.0.0.1:<port>/_vf/`, expression de source avec chemin), pas
`'self'` (qui admettrait tout `.js` servi depuis la sortie). Le service statique de la sortie (l. 596-605) ne sert plus
aucun type de code après AM4 (seulement ce que la page lit, s'il en reste). README l. 36 promet « la politique de contenu
de la page est celle de la v1.0.x » sans `--terminal` : amendement à écrire (79-17).
**Témoins.** Deuxième chargement → 304 sur les assets ; un `.js` planté dans la sortie n'est jamais exécutable par la
page (CSP + service) ; `test-cockpit-securite.sh` (CSP mesurée), `test-cockpit-lancer-serveur.sh:100,134` (empreintes).
**Fichiers.** `M/assets/serve.mjs`, `M/scripts/build.mjs` (coquille sans données), `S/vf-cockpit-build.mjs`,
`S/vf-cockpit-server.mjs` si les pages y passent, **`T/test-cockpit-coquille.sh` (compteur +1)**, suites CSP.

### 79-12 — Magasin `VF_ETAT` côté page, retrait des observateurs de réparation (AM6, I32) — vague 7

**Réalisation.** `ui/0x-vf-etat.js` : `VF_ETAT.lire(cle)`, `VF_ETAT.abonner(cle, rappel)` → désabonnement ; clés `etat`,
`who`, `frise`, `git`, `connexion` (C4). Les composants qui redessinent par `MutationObserver` pour réparer après un
redessin (23 observateurs dans `ui/*.js`, scout-front § 5 ; ex. `70-vf-live.js:115-163`) s'abonnent au magasin et
rendent leur état eux-mêmes. Événements de document `vf-who`, `vf-git:signal` gardés (C4).
**Témoins.** Compte des `new MutationObserver` dans `ui/70..77` en baisse, ratchet dans `test-cockpit-vendor.sh` ou une
suite UI ; un abonné reçoit `etat` après un `etat` du flux (VM Node, patron `vm72.mjs`).
**Fichiers.** `M/assets/ui/0x-vf-etat.js` (nouveau), `ui/70-vf-live.js`, `ui/72-vf-equipe.js`, `ui/73-vf-tiroir-travail.js`,
`ui/76-vf-git-entete.js`, `ui/77-vf-git-tiroir.js`, `ui/75-vf-modele.js`, `M/VENDORED.txt`.

### 79-13 — Mise en page dans un worker (AM3, M7 reste) — vague 8

**Réalisation.** `M/assets/elk-fil.js` : `importScripts('<préfixe>/vendor/elk.bundled.js')` (le bundle pose `self.ELK`,
§ Standard Stack), `onmessage` → `elk.layout` → `postMessage` ; `viewer.html` (aujourd'hui `const elk = new ELK();` l. 679 et
`return elk.layout({` l. 1093 [VERIFIED: `M/assets/viewer.html`]) passe par le worker, repli en ligne si `Worker` échoue ou en `file:` (export). CSP :
`worker-src` au préfixe du module ; sans `worker-src`, le navigateur retombe sur `child-src` puis `script-src` puis
`default-src` [CITED: developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Security-Policy/worker-src].
**À éprouver** (MEDIUM) : `importScripts` d'un fichier de 1,5 Mo dans le worker sous la CSP du worker ; le faux worker
interne d'elkjs tourne alors dans le fil du worker [ASSUMED].
**Témoin.** Pendant une mise en page longue (graphe de fixture), la page traite un clic en moins de 100 ms (rouge
aujourd'hui : ELK bloque le fil principal) ; export ouvert en `file:` → carte affichée (repli).
**Fichiers.** `M/assets/viewer.html`, `M/assets/serve.mjs` (CSP, route du worker), `M/assets/elk-fil.js` (nouveau,
`AJOUT`), `M/VENDORED.txt`, suite CSP.

### 79-14 — Traduction au point d'émission (H4 reste) — vague 3

**`?lang=en` : arbitrage en vigueur, à tenir.** P67-D-20, réponse de Samuel mot pour mot : « on pourrait avoir des gens
qui utilise l'anglais, donc en soit l'anglais n'est pas dérangeant et peut etre un des langues autorisées »
[VERIFIED: `67-CONTEXT.md:175-181`] ; P70-D-03 : « `?lang=en` n'est pas touché » [VERIFIED: `70-CONTEXT.md:43-45`] ;
SEED-005 (dormante) prend `?lang=en` comme point d'appui du futur choix de langue
[VERIFIED: `.planning/seeds/SEED-005-langue-interface-cockpit.md:30-33`]. Aucune phase 71-78 ne le rouvre (recherche
`lang=en` dans les CONTEXT : 67, 70 seulement). Conséquence : la traduction au point d'émission garde le texte source
anglais comme **clé** et une table française ; `?lang=en` rend la clé. Deux harnais lisent les libellés anglais du moteur
par `?lang=en` (`T/chrome-moteur-carte.mjs:3,10`, `T/chrome-accessibilite.mjs:3,15` [VERIFIED]) : ils restent valides.
**Réalisation.** Fonction `t(cle)` posée en tête du viewer (ou `ui/00`), appelée aux points d'émission des chaînes du
moteur (`viewer.html`, `ui/05,10,20,25,30,40,60`), table = dictionnaire actuel (`ui/78`, `ui/79`) ; messages de
`serve.mjs` (ex. l. 496, 564, 580) traduits à la source ; retrait du `MutationObserver` global de `80-vf-fr.js`
(l. 147, 150) et des motifs `R`/`P` devenus inutiles ; `window.__vfFrTraduire` gardé (lu par `test-cockpit-chrome-fr.sh`,
`chrome-fr-donnees.mjs`, `chrome-statut.mjs`). L'inventaire statique (`S/vf-cockpit-fr-inventaire.mjs`) reste le gate
« aucune chaîne anglaise » et ajoute : toute chaîne passée à `t()` a une entrée française.
**Témoin.** Une chaîne nouvelle du moteur sans entrée → la suite d'inventaire rougit **avec son nom** (aujourd'hui elle
n'est vue qu'après rendu) ; une donnée du lab contenant un mot du dictionnaire n'est jamais traduite (aucun observateur
global) — rouge aujourd'hui hors des sélecteurs listés ; `?lang=en` affiche les libellés sources.
**Fichiers.** `M/assets/viewer.html`, `M/assets/ui/05-theme.js`, `10-glossary.js`, `20-health.js`, `25-recent.js`,
`30-screens.js`, `40-tour.js`, `60-export.js`, `78-vf-fr-dict-a.js`, `79-vf-fr-dict-b.js`, `80-vf-fr.js`, `M/assets/serve.mjs`,
`S/vf-cockpit-fr-exclusions.json`, `S/vf-cockpit-fr-inventaire.mjs`, `T/test-cockpit-chrome-fr.sh`, `T/chrome-fr-donnees.mjs`.
**Pièges.** Plan le plus exposé aux collisions avec la Phase 80 (viewer.html) et 73/74 (dictionnaire) : à exécuter tôt
(vague 3) et en un seul commit de rebasage facile par fichier. Les textes produits à l'assemblage par
`M/scripts/lib/health.mjs` sont des données (P70-D-04) : hors de ce plan.

### 79-15 — Plafond en colonnes, code navigateur rangé en fichiers (AM5) — vague 3

**Réalisation.** Plafond en colonnes **en ratchet** : aucun plafond n'existe aujourd'hui (scout-front § 4 : 1 721 lignes
de plus de 160 caractères, max 962) ; reformater 81 fichiers toucherait tout le module et chaque phase parallèle. Une
baseline par fichier (nombre de lignes > 160) qui ne peut que baisser, nouveaux fichiers à 0, dans `test-cockpit-vendor.sh`
V4. Code navigateur sérialisé par `.toString()` (`S/vf-cockpit-lancer-ui.mjs`, `-terminal-tiroir.mjs`,
`-terminal-tiroir-ui.mjs`, `-terminal-client.mjs`, `-terminal-vue.mjs`) : en fichiers sous `M/assets/q/` (page Q) et
`M/assets/p-terminal/` (tiroir, page P), lus comme **texte** à l'injection, injection toujours conditionnée par
`--terminal` (README l. 36 : sans le drapeau « rien de ce qui suit n'existe » ; P71). Jamais sous `scripts/<sous-dossier>/`
(non posé par l'engine).
**Témoin.** Le ratchet rougit sur une ligne de 161 caractères ajoutée à un fichier à baseline 0 (témoin dans la suite) ;
sans `--terminal`, aucune des chaînes du tiroir dans la page servie (déjà testé, à rejouer).
**Fichiers.** les 5 `.mjs` + styles (`-lancer-style.mjs`, `-terminal-style.mjs`, `-terminal-tiroir-style.mjs`),
`S/vf-cockpit-terminal-page.mjs`, `M/assets/q/**`, `M/assets/p-terminal/**`, `M/VENDORED.txt`, `T/test-cockpit-vendor.sh`.
**Recouvrement** : `M/VENDORED.txt` aussi touché par 79-14 ? Non — 79-14 n'ajoute pas de fichier `ui/` ; s'il en ajoute
un, sa ligne `AJOUT` passe par 79-15 ou en vague suivante.

### 79-16 — Journal d'événements par les hooks (I18) — décision, pas de code (recommandation)

**Le module cockpit peut-il porter des hooks ?** Mécaniquement oui : « Un module peut déclarer hooks/hooks.json » et
l'install le fusionne dans le `settings.json` du scope [VERIFIED: `plugin/_internal/vibeflow-update.sh:2445-2448`] ;
le cockpit n'en porte pas aujourd'hui (seuls conductor, consolidator, dev-orchestrator, infrastructure-audit,
planning-core, software-architecture en ont) ; le plugin déclare déjà le mod `vf-signal` comme hooks en processus
(`"hooks": "./cockpit/signal/hooks/hooks.json"` [VERIFIED: `plugin/.claude-plugin/plugin.json`]), qui reçoit
`tool.call` et `agent.spawn` mais n'écrit aucun fichier (scout-front § 8).
**Recommandation : ne pas livrer I18 dans la 79.** L'index incrémental (79-07a/b) couvre le besoin (« le serveur suit
au lieu de relire ») ; I18 exige un hook `command` (un hook `http` échoue serveur arrêté), un **second écrivain** dans
le lab, la réduction verbe + cible à l'écriture (P67-D-14 : jamais `tool_input` dans un fichier), une précondition
d'armement qui voyage avec le scope (mémoire « armement sans précondition distribuée »), le régime ADR-031/ADR-043.
Plan 79-16 = une ligne au BACKLOG ou au CONTEXT (le manager tient ces fichiers), pas de code.

### 79-17 — Documentation et version du module — vague 9

README du module (l. 36 CSP, l. 204-205 « jamais une source de code » à réécrire avec la limite du scope `project`,
§ Code tiers l. 345-350 sans `amont/`, § `vf-signal` route d'état, mesure 79), `CHANGELOG.md` du module, `VERSION` et
`module.json` (capacité nouvelle : minor), en-tête `**Version**` du README (gaté). **Seul plan** de la phase qui touche
le CHANGELOG et le README du module : les autres consignent dans leur SUMMARY. Pas de release (ADR-073).

## Ordre des vagues (corrigé)

| Vague | Plans | Recouvrement vérifié |
|---|---|---|
| 1 | 79-01, 79-02, 79-03 | 01 et 02 disjoints parce que 02 **exclut** `test-cockpit-questions.sh` et `test-cockpit-git-env.sh` ; 03 = conductor seul |
| 2 | 79-04, 79-05, 79-06, 79-07a | 05 n'édite ni `paths.mjs` (06), ni `live.mjs` (07b), ni `interface.json` (07a) ; 06 met son témoin A-04 dans `git-config-depot.sh`, pas `git-env.sh` (05) ; 04 = références + dev-orchestrator ; seule 07a ajoute une suite |
| 3 | 79-07b, 79-14, 79-15 | AB1 déplacé en 05 libère `serve.mjs` pour 14 ; 15 ne touche ni `viewer.html` ni `ui/` ; seule 07b ajoute une suite |
| 4 | 79-08 | seul porteur de `server.mjs` + `interface.json` |
| 5 | 79-09, 79-10 | 09 = serveur ; 10 = page (`ui/69`, `ui/70`) |
| 6 | 79-11a | `server.mjs`, `live.mjs`, `serve.mjs` |
| 7 | 79-11b, 79-12 | 11b = `serve.mjs`/coquille ; 12 = `ui/70..77` ; `VENDORED.txt` : seule 12 y ajoute une ligne |
| 8 | 79-13 | `viewer.html` + CSP |
| 9 | 79-16 (décision), 79-17 | docs |

**Écarts au découpage provisoire** : 79-04 de la vague 1 à 2 (module conductor partagé avec 03) ; 79-07 coupé en 07a
(vague 2) et 07b (vague 3) ; AB1 de 07 vers 05 ; « page Équipe sans reconstruction » de 08 vers 11a ; `live.mjs:66` de
06 vers 07b ; 79-10 sans `server.mjs` (le battement nommé est en 08) ; 79-11 coupé en 11a/11b ; 79-14 avancé en vague 3 ;
79-15 avancé en vague 3 ; 79-16 réduit à une décision ; 79-17 ajouté (docs, CHANGELOG unique).

## Don't Hand-Roll

| Problème | Ne pas construire | Utiliser | Pourquoi |
|---|---|---|---|
| Collecte non bloquante | réécriture async de tout le socle | `worker_threads` autour des collecteurs existants | code testé gardé tel quel |
| Élection d'onglet | battements en `localStorage`, horodatages | Web Locks + `BroadcastChannel` | libération à la décharge garantie par la spec |
| Lecture par décalage | nouveau lecteur | patron `dernierArbre` (`who.mjs:36-55`) | déjà éprouvé, plafond d'ajout |
| Dédoublonnage des jetons | un compteur par ligne | `message.id`, dernière ligne gagne + curseur | 2 à 8 lignes par message (A1) |
| Lecture du registre | parse JSON Lines à la main | `registry_fold` (lecteur unique) | doctrine du script |
| Lancement git et shell | `execFileSync` direct | `shBorne` / `lancerGit` (échéance, PATH assaini, `envGit`) | point unique A-04 |
| Écriture d'un fichier du lab | `writeFileSync` direct | `ouvrirSur` (`lanceur-verrou.mjs`) ou tmp + rename + `confiner` | liens, liens durs, 0600 |
| Reconnaissance du serveur | lecture de `server.json` seul | `estNotre` (ligne de commande, PID) | `server.json` est un fichier du lab |
| Validation des réponses à `vf-signal` | nouvelle garde | `complet()` de `socle.ts` | déjà en place |

**Key insight :** tout ce que la 79 déplace a déjà un point unique dans le code présent ; le travail est de faire passer
les chemins restants par ces points, pas d'en écrire de nouveaux.

## Runtime State Inventory

| Catégorie | Trouvé | Action |
|---|---|---|
| Données stockées | `.vibeflow/cockpit/` de chaque lab : copies de code (`serve.mjs`, `query.mjs`, 57 `vf-cockpit-*.mjs`, `vf-cockpit-interface.json`) ; `.cache/vf-cockpit.json` ; registres `*.children.jsonl` aujourd'hui supprimés au `release` | **purge des fichiers de code** à l'assemblage (79-05, code) ; nouveau `.cache/index-transcripts.json` (79-07, donnée) ; registres conservés 24 h (79-03) |
| Config de service vivante | serveurs du cockpit lancés par la version précédente, ligne de commande `<sortie>/serve.mjs` | `estNotre` accepte les deux formes pendant la transition (79-05) ; sinon `stop` refuse et `open` double le serveur |
| État enregistré par l'OS | aucun (ni launchd, ni systemd, ni tâche planifiée : serveur détaché, arrêt sur inactivité) — vérifié par lecture de `vf-cockpit.mjs` | aucune |
| Secrets et variables | `server.json` (jeton, 0600), `.cache/terminal-amorce` ; `VF_COCKPIT_SCRIPTS_DIR`, `VF_COCKPIT_ENGINE_DIR` posés par le lanceur | inchangés ; ajouter l'argument `--sortie` (pas une variable) |
| Artefacts installés | module posé par `/vf-update` dans trois scopes ; liste blanche de l'agent liée à `.vibeflow/cockpit/query.mjs` | `ARGS_CONFINEMENT` + nouvelle mesure (79-05) ; le module mis à jour change l'empreinte (relance automatique, H3) |

## Common Pitfalls

### Pitfall 1 : plafond de 300 lignes franchi par un « petit » ajout
**What goes wrong :** V4 rougit (`paths.mjs` 296, `vf-cockpit.mjs` 273, `70-vf-live.js` 285).
**How to avoid :** chaque plan qui touche ces fichiers crée d'abord le module d'extraction ; contrôle `awk 'END{print NR}'` en vérification de tâche.

### Pitfall 2 : pages renommées, code serveur non renommé
**What goes wrong :** serveur lancé du module lit `x-floorplan-token`, la page envoie `x-vf-cockpit-token` → 403 partout ; `extraireGraphe` ne trouve plus les données.
**How to avoid :** 79-05 étape 1 et le piège d'ordre `insererGraphe` / `renommerHtml`.

### Pitfall 3 : sortie passée en variable d'environnement
**What goes wrong :** `hygiene.sh` ne voit plus les serveurs fuités ; `estNotre` confond deux labs.
**How to avoid :** `--sortie <chemin absolu>` en argument.

### Pitfall 4 : preuve qui saute en silence
**What goes wrong :** Q11 (`test-cockpit-questions.sh:90`) saute après le retrait d'`amont/` ; une suite Chrome saute en local.
**How to avoid :** témoin « Q11.0 » (79-01) ; sauts Chrome via `chrome-saut.sh`, comptés rouges en CI.

### Pitfall 5 : nom de clé interdit dans une donnée neuve
**What goes wrong :** une voie de frise avec un champ `outils` ou `messages` → la garde refuse **tout** l'événement ou la route (503), sans erreur visible côté code.
**How to avoid :** noms de C3 (`compteurs.appels`, `jetons`…) ; un test de la garde sur une voie complète.

### Pitfall 6 : CHANGELOG, README et compteur de suites édités par plusieurs plans d'une vague
**How to avoid :** CHANGELOG/README du module en 79-17 seulement ; une seule suite ajoutée par vague (tableau des vagues) ; `bash scripts/check-version-sync.sh` en fin de chaque plan qui ajoute une suite.

### Pitfall 7 : mesure de confinement recopiée à la main
**What goes wrong :** `ARGS_CONFINEMENT` change sans mesure ; Q11 compare à une mesure périmée.
**How to avoid :** `79-MESURE-claude-p.md` avant le changement de constante ; Q11 lit la plus récente.

### Pitfall 8 : `rtk` fausse les comptes
**How to avoid :** compter ou prouver une absence par `rtk proxy grep|find` (mémoire du projet).

## Code Examples

### Garde d'émission (à réutiliser telle quelle, ne pas dupliquer)
```js
// Source : plugin/cockpit/scripts/vf-cockpit-server.mjs:34-35 (lu dans cette session)
const porteInterdit = (o) => !INTERDITS.length || (!!o && typeof o === 'object' && Object.entries(o).some(([k, v]) => INTERDITS.includes(k) || porteInterdit(v)));
```

### Réponse JSON des routes (même forme pour state, frise, graphe)
```js
// Source : plugin/cockpit/scripts/vf-cockpit-server.mjs:78
const json = (res, code, obj) => { res.writeHead(code, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' }); res.end(JSON.stringify(obj)); };
```

### Signal d'événement sans contenu (patron `git`, à reprendre pour `frise` et `etat`)
```js
// Source : plugin/cockpit/scripts/vf-cockpit-live.mjs:153
if (gs && gs !== gitSig) { gitSig = gs; emit('git', { seq: ++state.seq, at: Date.now(), sig: gs.slice(0, 16) }); }
```

## State of the Art

| Ancien | Actuel (79) | Effet |
|---|---|---|
| moteur vendoré + patchs rejouables (P67-D-11) | fork assumé (AUDC-Q5) | une édition de `serve.mjs`/`viewer.html` ne régénère plus de diff |
| code exécuté depuis la sortie du lab | code du module, sortie = données | A-03 fermée côté processus ; limite scope `project` |
| `: ka` invisible au JS | `event: vie` + veille 45 s | coupure muette détectée (D-M2) |
| `vf-signal` relance une collecte de ~2 s toutes les 10 s | lecture de la route quand le serveur vit | un seul calcul par lab |

**Déprécié :** `plugin/cockpit/amont/`, `synchro.sh`, lignes `PATCH`/`RETRAIT`, `query.mjs` dans la sortie, réécriture
de `project.html` en direct, `MutationObserver` global de traduction.

## Assumptions Log

| # | Claim | Section | Risque si faux |
|---|---|---|---|
| A1 | `worker_threads` exécute les collecteurs synchrones (execFileSync, fs) sans bloquer la boucle principale | 79-07b | H2 à refaire en asynchrone ; le témoin de 200 ms le dira |
| A2 | `importScripts` du bundle elkjs dans un worker pose `self.ELK` et sa mise en page tourne dans le fil du worker | 79-13 | vendorer `elk-worker` d'elkjs 0.9.3 (fichier tiers, licence) ; spike court en tête de plan |
| A3 | Une règle `Bash(node <chemin absolu>:*)` confine l'agent comme la forme relative | 79-05 | agent sans Bash ; décision à remonter |
| A4 | Le module tourne sous Node 20+ (aucune déclaration) | Standard Stack | utilisateur sous Node 18 : erreur au lancement ; dire le minimum au README (79-17) |
| A5 | Safari et Firefox de bureau gèrent Web Locks + `BroadcastChannel` sur `127.0.0.1` | 79-10 | repli « un flux par page » déjà prévu par C4 |
| A6 | Purger le registre par réécriture ne perd pas d'ajout concurrent | 79-03 | ligne `register` perdue → orphelin invisible ; à tenir par un verrou d'écriture ou à dire en limite |

## Open Questions

1. **Agent confiné avec chemins du module** — mesure à faire (79-05) ; si non confinable, agent sans Bash : décision humaine.
2. **I18** — recommandation : hors 79 (79-16 = décision). Au manager.
3. **`projet.json` écrit au changement (79-11a)** — C5 interdit la réécriture de `project.html`, pas un fichier de données : à consigner en amendement daté du CONTEXT si le manager le retient.
4. **S-1, S-2** — en vigueur, non bloquants.

## Environment Availability

| Dépendance | Requise par | Disponible | Version | Repli |
|---|---|---|---|---|
| Node.js | tout | ✓ | v26.5.0 (poste), 24 (CI) | — |
| Claude Code CLI | mesure de confinement (79-05), `claude agents --json` (79-09) | ✓ | 2.1.322 | checkpoint humain si la mesure ne peut pas tourner |
| git | socle, suites | ✓ | 2.50.1 | — |
| python3 | suites du terminal | ✓ | 3.14.6 | suites terminal sautées audiblement |
| Google Chrome | suites navigateur (79-10, 11b, 12, 13, 14) | ✓ (application présente) | — | saut via `chrome-saut.sh`, compté rouge en CI |
| jq | outillage | ✓ | 1.7.1 | — |

Aucune dépendance bloquante. Cette recherche n'a lancé ni serveur ni navigateur.

## Validation Architecture

### Test Framework
| Propriété | Valeur |
|---|---|
| Framework | suites bash `plugin/**/tests/test-*.sh` + harnais Node (`.mjs`) + Chrome headless (CDP) ; Node 24 en CI |
| Config | `.github/workflows/ci.yml` (shards, `scripts/ci-shard-suites.sh`), périmètre `scripts/ci-suites-perimetre.sh` |
| Quick run | `bash plugin/cockpit/scripts/tests/test-cockpit-<suite>.sh` |
| Périmètre d'une branche | `bash scripts/ci-suites-perimetre.sh --liste <base> HEAD` puis jouer la liste |
| Gates | rejouer les commandes du job `gates` de `ci.yml` (dont `check-version-sync.sh`, `check-machine-paths.sh`, `check-ajout-retrait.sh --ci`) |

### Phase Requirements → Test Map
| Ligne | Comportement | Type | Commande | Fichier existe ? |
|---|---|---|---|---|
| H5 | `amont/` absent, `VENDORED.txt` sans PATCH/RETRAIT, Q11 non sauté | unitaire | `test-cockpit-vendor.sh`, `test-cockpit-questions.sh` | ✅ (assertions V10, Q11.0 à ajouter) |
| AM7 | serveurs des suites lancés par l'aide et vus par `hygiene.sh` | intégration | `test-cockpit-flux-unique.sh` | ✅ |
| D5/I37 | registre conservé, verbe `registre`, purge 24 h ; nœud du gabarit lu par `citationsDuMandat` | unitaire | `test-driver-lock.sh` T63, `test-driver-lock-ws.sh` ; suite dev-orchestrator | ✅ |
| AM4/A-03 | aucun fichier de la sortie évalué ; témoin positif module | intégration | `test-cockpit-securite.sh` | ✅ |
| H3/D-M13 | empreinte de tout le code ; `status`/`stop` sans `server.json` | intégration | `test-cockpit-cycle-serveur.sh` | ✅ |
| A-02 | propriété verdict = résolution physique (générative, couverture + témoin rouge) | propriété | `test-cockpit-confinement.sh` G15 | ✅ (section à ajouter) |
| D-M15, A-04 | cible interne protégée ; pilotes nommés et enfants shell | intégration | `test-cockpit-confinement.sh` A, `test-cockpit-git-config-depot.sh` | ✅ |
| I20/D9 | incrémental = une passe (générative), dédoublonnage, non fiable, aucun texte | propriété | `test-cockpit-index.sh` | ❌ vague 2 |
| H2 | `/api/vf/etat` < 200 ms pendant une collecte lente | intégration | `test-cockpit-collecte.sh` | ❌ vague 3 |
| I19/AM1 | route d'état, codes, aucune collecte à la requête ; émetteur sans `driver-lock` quand le serveur vit | intégration | `test-cockpit-etat.sh`, `test-cockpit-signal.sh` | ❌ vague 4 / ✅ |
| I20 route | bornes, projection sans curseur ni chemin absolu | intégration | `test-cockpit-frise.sh` | ❌ vague 5 |
| H1/I22/D-M2 | un flux pour deux onglets, reprise, veille 45 s | navigateur | `test-cockpit-flux-unique.sh`, `-direct-coupe.sh`, `-reconnexion.sh` | ✅ |
| AM1/I31/AM2 | 304, `project.html` figé, agent à jour, CSP au préfixe | intégration + navigateur | `test-cockpit-serveur.sh`, `test-cockpit-coquille.sh` | ✅ / ❌ vague 7 |
| AM6/I32 | magasin, ratchet des observateurs | VM Node | suite UI existante | ✅ |
| AM3/M7 | clic < 100 ms pendant la mise en page ; repli export | navigateur | suite CSP / moteur-carte | ✅ |
| H4 | chaîne sans entrée nommée ; donnée jamais traduite ; `?lang=en` | statique + navigateur | `test-cockpit-chrome-fr.sh` | ✅ |
| AM5 | ratchet colonnes ; rien du terminal sans `--terminal` | statique | `test-cockpit-vendor.sh` | ✅ |

### Sampling Rate
- **Par tâche :** la ou les suites du fichier touché + `awk 'END{print NR}'` sur les fichiers proches du plafond.
- **Par vague :** `scripts/ci-suites-perimetre.sh --liste` sur la branche + commandes du job `gates`.
- **Fin de phase :** toutes les suites cockpit + conductor touchées vertes, `check-version-sync.sh` vert, avant `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `T/serveur-commun.sh` (79-02) — prérequis de 79-05.
- [ ] `T/test-cockpit-index.sh` + fixtures (79-07a), `test-cockpit-collecte.sh` (07b), `test-cockpit-etat.sh` (08),
  `test-cockpit-frise.sh` (09), `test-cockpit-coquille.sh` (11b) : compteur 213 → 218 au total (deux README racine),
  une suite au plus par vague.
- [ ] `79-MESURE-claude-p.md` (79-05).

## Security Domain

`security_enforcement: true`, ASVS niveau 1, blocage sur « high » [VERIFIED: `.planning/config.json` workflow].

### Applicable ASVS Categories
| Catégorie | S'applique | Contrôle |
|---|---|---|
| V1 Architecture | oui | code chargé du module, jamais de la sortie (79-05) ; écrivain unique de l'index |
| V2 Authentification | non (jeton de page, inchangé) | — |
| V3 Session | non | — |
| V4 Contrôle d'accès | oui | contrôles C0 sur toute route neuve (Host, Origin, jeton en temps constant), GET seul |
| V5 Validation | oui | index non fiable à la lecture ; paramètres de frise entiers bornés ; réponse du serveur relue par l'émetteur comme non fiable |
| V6 Cryptographie | non (sha pour empreintes, `timingSafeEqual` existant) | ne rien écrire à la main |
| V8 Protection des données | oui | 5 clés refusées ; aucun texte, entrée ou sortie d'outil, aucune cible dans l'index ; dernière commande jamais dans un fichier |
| V12 Fichiers | oui | résolution physique (A-02), cible interne protégée (D-M15), tmp + rename, 0600, aucun lien suivi |
| V14 Configuration | oui | CSP (préfixe du module, `worker-src`), environnement git durci pour tout enfant |

### Known Threat Patterns
| Motif | STRIDE | Mitigation |
|---|---|---|
| fichier de code planté dans la sortie du lab | Elevation | aucune évaluation depuis la sortie ; purge à l'assemblage ; témoin A-03 |
| `server.json` planté désignant un autre processus local | Spoofing | `estNotre` (ligne de commande + PID) avant toute lecture de la route par l'émetteur |
| index du cache pré-planté (archive du lab) | Tampering | schéma, version, bornes, curseur revérifiés ; voie relue depuis zéro ; identifiants `ID_RE` ; rendu texte |
| lien interne qui rebondit hors du dossier git | Information disclosure | résolution physique, preuve générative |
| fuite de contenu par une clé neuve | Information disclosure | garde `porteInterdit` sur toute route et tout événement ; noms C3 |
| script de page chargé depuis la sortie | Elevation | CSP au préfixe du module, service statique sans type de code |
| pilote git nommé hors liste de sous-commandes | Elevation | pilotes vidés pour tout lancement |

## Fichiers partagés avec d'autres phases du jalon (73, 74, 75, 77, 80)

| Fichier | Plans 79 | Autres phases | Règle de résolution |
|---|---|---|---|
| `M/assets/viewer.html` | 79-14, 79-13 (79-11b éventuellement) | 80 (couloirs, clavier, palette), 73 (régie Équipe) | la 79 édite tôt (vague 3) et par commits ciblés ; garder la suppression d'`amont/` en cas de conflit |
| `M/assets/serve.mjs` | 79-05, 79-14, 79-11a, 79-11b, 79-13 | 80 (onglets I30), 74 (route de frise : fournie ici) | 74 ne crée pas de route : elle lit C3 |
| `plugin/cockpit/amont/**`, `M/VENDORED.txt` | 79-01 (retrait), 79-10, 79-12, 79-13 (lignes `AJOUT`) | 80, 73 (tout `ui/` ajouté) | avant le merge de 79-01 une autre phase régénère son diff ; après, elle ajoute seulement sa ligne `AJOUT` |
| `ui/78-vf-fr-dict-a.js`, `79-…-b.js`, `80-vf-fr.js`, `S/vf-cockpit-fr-exclusions.json` | 79-14 | 80, 73, 74 (toute chaîne nouvelle) | après 79-14, une chaîne nouvelle passe par `t()` ; avant, par le dictionnaire |
| `M/assets/ui/70-vf-live.js` | 79-10, 79-12 | 73 (régie, vivacité), 74 | 79-10 en extrait la connexion : une phase qui l'édite rebase sur l'extraction |
| `S/vf-cockpit-server.mjs` | 79-05, 08, 09, 11a | 73, 74, 75 | une route = un module + une ligne de branchement |
| `S/vf-cockpit-live.mjs` | 79-07b, 79-11a | 73, 74, 75 | la collecte passe par le fil (07b) |
| `S/vf-cockpit-interface.json` | 79-07a, 08, 09 | 74 (`usage` : fourni par 07a), 73 | 74 n'étend plus le contrat pour les jetons (C6) |
| `S/vf-cockpit-who.mjs`, `S/vf-cockpit-equipe*.mjs` | 79-07b | 73 (régie, états), 74 | import seul côté 79 |
| suites `T/test-cockpit-*.sh` lançant `serve.mjs` | 79-02 (≈ 47 suites), 79-05 | 73 (`-equipe`, `-who`, `-lancer-suivi`), 74, 80 (suites Chrome) | ligne de lancement mécanique : rebaser |
| `README.md`, `README.fr.md` racine (« 213 suites ») | 79-07a, 07b, 08, 09, 11b | toute phase qui ajoute une suite | recompter au merge (`check-version-sync.sh` § 9) |
| `plugin/cockpit/CHANGELOG.md`, `README.md`, `VERSION`, `module.json` | 79-17 | 73, 74, 75, 77, 80 | section « Non publié » : ajouts en fin de section |
| `DESIGN.md` racine | 79-01 (§ 9, table) | 80, 71.5 | ligne isolée |
| `plugin/conductor/scripts/driver-lock.sh` + suites | 79-03 | 73 (verrous lus, pas écrits) | lecture seule côté 73 |

## Sources

### Primary (HIGH)
- Code du worktree de phase (base `f763b556`, commit `3119d82a`), lu dans cette session : `vf-cockpit-server.mjs`,
  `vf-cockpit-live.mjs`, `vf-cockpit.mjs`, `vf-cockpit-build.mjs`, `vf-cockpit-paths.mjs`, `vf-cockpit-git-sortant.mjs`,
  `vf-cockpit-git-durci.mjs`, `vf-cockpit-signal.mjs`, `vf-cockpit-agent.mjs`, `vf-cockpit-lanceur-verrou.mjs`,
  `vf-cockpit-rename.mjs`, `vf-cockpit-interface.json`, `vf-cockpit-transcript.mjs`, `M/assets/serve.mjs`,
  `ui/70-vf-live.js`, `signal/hooks/socle.ts`, `T/test-cockpit-vendor.sh`, `T/test-cockpit-questions.sh`, `T/hygiene.sh`,
  `driver-lock.sh`, `test-driver-lock.sh`, `scripts/check-version-sync.sh`, `vibeflow-update.sh`, `67-MESURE-claude-p.md`,
  `67-CONTEXT.md`, `70-CONTEXT.md`, `SEED-005`.
- Relevés `scout-socle`, `scout-index`, `scout-secu`, `scout-front` (repris, non refaits).

### Secondary (MEDIUM)
- developer.mozilla.org : Web Locks API, BroadcastChannel, Secure Contexts, CSP `worker-src` ; w3c.github.io/web-locks § 2.6.

### Tertiary (LOW)
- aucune affirmation de cette classe n'engage un plan sans checkpoint (Assumptions Log).

## Metadata

**Confidence breakdown :**
- Stack : HIGH (aucune dépendance, versions mesurées) ; minimum Node : ASSUMED (absence de déclaration).
- Architecture et vagues : HIGH (fichiers et lignes lus ; recouvrements calculés plan par plan).
- Pièges : HIGH (plafond, renommage, saut de Q11, `hygiene.sh` vérifiés) ; worker ELK et confinement absolu : MEDIUM.

**Research date :** 2026-11-11
**Valid until :** 2026-11-25 (code très actif : six phases en parallèle sur la même base)
