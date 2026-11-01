# Floorplan (haydenschmitty) — étude de reprise pour le cockpit VibeFlow

> Note de recherche, 2026-11-01, session principale (Samuel). Ce n'est **pas** une décision : elle
> pose les faits mesurés, les options, et une recommandation à trancher. Rien n'est inscrit dans
> `.planning/`.

## 1. Ce qu'est Floorplan

`haydenschmitty/floorplan`, MIT, v0.6.0, **créé le 2026-10-27** (5 jours au moment de l'étude),
795 étoiles, 54 forks, 50 commits dont ~43 d'un seul auteur, 9 issues ouvertes. Plugin Claude Code
**et** Codex (`.claude-plugin/`, `.codex-plugin/`, `.agents/plugins/marketplace.json`). Un seul
skill (`skills/floorplan/SKILL.md`, 182 lignes), zéro dépendance, Node ≥ 18, ~11,4 k lignes
(scripts 5,1 k, viewer 2,4 k + 9 extensions UI 1,1 k, serveur 630, ELK vendorisé 1,6 Mo).

**Ce qu'il fait** : une carte interactive du **code** d'une app (une ou plusieurs repos côte à
côte), à plusieurs niveaux de zoom (système → module → dossier → fichier → endpoint), chaque
carte avec un nom et une description en langage clair, reliées par les imports et par les
requêtes HTTP rapprochées des routes serveur, y compris d'une repo à l'autre.

**Le partage du travail** est le cœur du design :

| Étape | Qui | Coût |
|---|---|---|
| `scan.mjs` : repos, fichiers via git, imports résolus (TS, Python, Go, Rust, JVM), routes (Express, Next, FastAPI, Flask, Django, Gin, Axum, Spring, Firebase…), appels HTTP, empreintes | script | 0 token |
| `architecture.json` : les parties de l'app, services externes, liens invisibles (queues, cron, webhooks), flows, tour | agent | faible |
| `build.mjs` : valide tout (« did you mean… »), assigne chaque fichier au nœud le plus profond, Health, écrans, `graph.json` + `index.html` autonome | script | 0 |
| `describe.mjs` : une fiche de travail par module, l'agent remplit `descriptions/<clé>.json` (parallélisable, un fichier par agent, zéro conflit) | agent | le gros du coût, une fois |
| `recent.mjs` → `recent-work.json` : ce qui vient de changer, relié à la demande (« pourquoi ») | script + agent | faible |
| `refresh.mjs` : rescan, empreintes exacte + signature, reporte les descriptions sur les fichiers déplacés, ne signale que ce qui a changé de signature | script | 0 |
| `open.mjs` / `serve.mjs` : serveur local 127.0.0.1, rechargement à chaud, barre « Ask » | script | à l'usage |

**Les fonctions** : carte zoomable ; Health (secrets dans le code ou exposés au navigateur, tables
Supabase sans RLS, règles Firebase ouvertes, webhooks Stripe sans signature, CORS `*`, endpoints
sans authentification, fichiers morts, fichiers > 1 000 lignes — chaque point avec « Show on map »
et un prompt de correction prêt à coller) ; Screens (Next, React Router, Vue, SvelteKit, Remix,
Nuxt, Astro, **Expo**, Angular, TanStack) avec tout ce qu'il y a derrière un écran ; Ask (réponse +
mini-carte des pièces concernées + walkthrough, via `claude -p --json-schema` en lecture seule ou
`codex exec --sandbox read-only`) ; flows guidés et « Request a new flow » ; tour « Start here » ;
Recent work ; Export HTML unique assaini ; publication en Artifact ; **Blueprint** (carte d'un
système pas encore construit, depuis un PRD, avec une revue de conception à la place de Health,
« Build this with Claude » par partie, et un mode Change qui modifie le plan depuis la carte) ;
`query.mjs` (`overview | find | show | path`), une API de la carte que les agents interrogent
avant de grepper ; bloc opt-in dans `CLAUDE.local.md` pour que les sessions suivantes s'en
servent.

## 2. Ce qu'on a mesuré (2026-11-01)

Clone dans un dossier jetable, aucun fichier écrit dans ce dépôt.

- **Suite de tests** : `node --test` → **144/145 verts, 1 skip**, 3,6 s, Node 26.5.
- **Surface d'exécution relue** : les scripts ne lancent que `git` (`execFileSync`, jamais de
  shell), aucun `fetch`. Seul appel réseau du produit : la liste d'attente « Floorplan Cloud »
  (Cloud Run → Google Sheet), opt-in, plus un `claude auth status --json` pour pré-remplir l'e-mail.
- **Scan de ce dépôt (vibeflow-os)** : 0,8 s, 2 002 fichiers (1 574 docs, 262 code dont 245
  shell). **7 liens d'import résolus sur tout le dépôt**, 0 route, 0 point d'entrée. Floorplan est
  aveugle à ce qui relie VibeFlow : `source` bash, références markdown entre agents, skills et
  commandes, allowlists `Agent(...)`, `hooks.json`.
- **Scan d'un lab applicatif (malt-keyword, Next.js + service Python)** : 0,2 s, 66 fichiers de
  code, **66 imports + 11 appels HTTP rapprochés**, dont `src/app/api → profiles-service`
  (Next → Python, d'un service à l'autre), 6 points d'entrée, hôte `www.malt.fr` détecté.
- **Bout en bout sur malt-keyword** : `architecture.json` écrit à la main (9 nœuds, 1 flow),
  `build.mjs` → 80 liens, 9,1 % non assignés, Health « 1 worth fixing » (aucun endpoint ne vérifie
  l'appelant), 3 écrans détectés, `index.html` de 2,1 Mo. Carte servie et rendue dans le navigateur,
  descriptions en français acceptées, `query.mjs path src/app/page.tsx n:malt` rend le chemin
  page → hook → route API → Malt.
- **Le pont avec notre planning existe déjà** : **206 `PLAN.md` déclarent `files_modified`** dans
  leur frontmatter, et chaque nœud de DAG de mission porte un `scope[]` de chemins. Relier une
  phase, un plan ou un nœud de mission aux cartes qu'il touche est donc **mécanique**, sans LLM.

## 3. Les deux cockpits précédents

| | vf-cockpit (2026-08-16) | vf-signal (2026-10-28) |
|---|---|---|
| Où | branche `feat/vf-cockpit-module` (50 commits devant main, jamais mergée) ; spike sur `spike/cockpit-live` | `~/.claude/mods/vf-signal/` (scope user, non embarqué) |
| Forme | serveur Node zéro-dep + page web (Mermaid 3,4 Mo vendorisé), SSE | pane et bandeau **dans** Claude Code (API mods, early access) |
| Montre | trajectoire des phases, chantier (plans), équipe (DAG Mermaid + lock) | mission en vagues, arbre des agents en direct, macro projet → jalon → backlog, refus des gardes, action humaine attendue |
| Qualité | design 95/100, 38/38 tests, garde « n'écrit jamais » prouvée par mutation | `plugin validate` ✔, `tsc` strict ✔, `plugin test` 3/3 |
| Pourquoi arrêté | équipe lue seulement depuis `MISSION-*.dag.json` (faux « personne au travail » en worktree) ; contenu isolé par chirurgie d'historique ; parsers d'avant la partition (`.planning/STATE.md`, `.planning/DRIVER.lock`) donc périmés | pas arrêté : prévu comme Phase 1 du jalon `vibeflow-v2.0` (`.planning/notes/2026-10-29-HANDOFF-jalon-v2.md`) |

Ce qu'aucun des deux ne montre : **le code**. Ils disent où en est le projet et qui travaille,
jamais sur quelle partie de l'app. C'est exactement ce que Floorplan apporte.

## 4. La thèse

Floorplan et nos cockpits répondent à deux questions différentes :

- Floorplan : **le territoire** (comment l'app est construite) ;
- vf-cockpit et vf-signal : **l'activité** (qui fait quoi, où en est le jalon, qu'est-ce qui
  attend un humain).

Le cockpit idéal pose l'activité **sur** le territoire. Les briques sont déjà là :

| Notion VibeFlow | Équivalent Floorplan | Pont |
|---|---|---|
| Plan de phase (`PLAN.md`, `files_modified`) avant exécution | **Blueprint** (cartes en pointillés) | `files_modified` → cartes « prévues » |
| `SUMMARY.md` d'un plan exécuté, commits de la phase | **Recent work** (demande → pourquoi, par carte) | SUMMARY + diff de la branche → `recent-work.json` |
| DAG de mission (`scope[]`, `status`) + driver-lock (`worktree`, `branch`) + registre des agents | aucun | **nouveau calque** : cartes en cours / faites / bloquées, agent par zone |
| `vf-auditer` (findings typés) | **Health** | Health = pré-audit gratuit ; findings de l'auditeur posés sur les cartes |
| `vibeflow-head` (« où en est-on ? ») | **Ask** + `query.mjs` | les agents (vf-coder, chercheurs GSD) interrogent la carte avant de grepper |
| Recette humaine (verify-work) | **flows guidés**, Screens | un flow par critère de succès de la phase |

## 5. Tout ce qu'on peut reprendre, même sans l'outil

1. **Script pour le mécanique, LLM pour le sens** : zéro token sur le comptage, la validation et
   la tenue de registres.
2. **Fiches de travail + sorties disjointes** (`descriptions/<clé>.json`, un fichier par agent) :
   du parallélisme sans conflit de fusion, compatible avec notre plafond de 2 agents en parallèle.
3. **Rafraîchissement incrémental à double empreinte** (contenu exact + signature
   exports/routes) : un modèle réutilisable pour nos registres et notre intel de code.
4. **Validation qui nomme la correction** (« did you mean… », fichiers non assignés listés par
   dossier) : à copier dans nos gates.
5. **`query.mjs`** : une API de lecture du graphe en CLI JSON, donnée aux agents comme outil de
   repérage. Elle réduit la lecture de fichiers des workers.
6. **Bloc marqué opt-in dans `CLAUDE.local.md`** + `.git/info/exclude` + marqueur
   `<!-- floorplan:off -->` : une réponse propre au problème « donnée de lab qui doit atteindre les
   sessions sans être commitée » (mémoire *mémoire per-projet en scope user*).
7. **Dossier qui s'ignore lui-même** (`floorplan/.gitignore` = `*`) : ne salit jamais le dépôt.
8. **Serveur local durci** : contrôle de l'en-tête `Host` (anti DNS-rebinding), jeton, même
   origine, arrêt après inactivité, état dans `.cache/server.json`, rechargement des onglets.
9. **Appels headless propres** : `claude -p --json-schema` / `codex exec --sandbox read-only
   --ephemeral`, détection du moteur, et **purge des variables `CLAUDE_CODE_*` / `CODEX_*`** avant
   de lancer un CLI imbriqué. À reprendre pour nos propres appels headless.
10. **Export assaini** (retire chemin local et remotes porteuses de jeton) et chemin de
    **publication en Artifact**.
11. **« Is it safe? » + test de chaîne d'approvisionnement** : un test affirme « pas de hooks, pas
    de MCP, pas de réseau, pas d'eval, allowlist figée » ; `CHECKSUMS.txt` par release. Utile pour
    notre posture (ADR-072).
12. **Les règles Health pour apps construites avec l'IA** (Supabase RLS, Firebase, Stripe,
    `NEXT_PUBLIC_*`) : directement utiles à `vf-auditer` sur les labs Supabase (LinkedinBot,
    RoastMyRoom).
13. **Détection des écrans, Expo compris** : pertinent pour les labs mobiles et `mobile-test`.
14. **Deux registres de langue** (`audience: everyone | developers`) : la même carte lisible par
    un client non technique.
15. **Matrice CI Windows et Linux sur Node 18/20/22**, avec le seul runner de Node.

## 6. Compatibilités et frictions

- **Doctrine « pas de catalogue tiers en dépendance » (décision du 2026-08-28)** : installer
  Floorplan comme dépendance du plugin la heurte. L'absorber, en vendorisé épinglé, ne la heurte
  pas.
- **Faible sur VibeFlow lui-même** (7 liens sur 2 002 fichiers). Cartographier le framework
  demande **notre** extracteur (agents → `Agent(...)`, skills, commandes, hooks, modules,
  `source`). C'est un travail propre, avec ou sans Floorplan.
- **Labs iOS** : `.swift` est classé comme code, mais Swift n'est pas dans la liste de résolution
  d'imports ni dans les frameworks d'écrans. RoastMyRoom ou FreelanceMoneyCalc auraient peu de
  liens. **Non testé ici.**
- **Barre Ask** : `--tools Read,Grep,Glob,Bash` restreint par `--allowedTools`, sans
  `--permission-mode` explicite. Hypothèse **non vérifiée** : sous un `defaultMode:
  bypassPermissions` utilisateur, la restriction de Bash pourrait ne plus tenir. Il faut une sonde
  avant de conclure dans un sens ou dans l'autre. Dans notre version, on forcerait le mode.
- **À retirer** : la liste d'attente Cloud et la lecture de l'e-mail du compte.
- **Interface en anglais** : la chrome est en anglais, mais les contenus générés suivent la
  langue de l'agent (vérifié en français).
- **Vitesse amont** : 0.1 → 0.6 en 4 jours. Un fork « dur » diverge en une semaine. Il faut
  épingler et suivre l'amont, comme pour gsd-core.
- **Coût** : la première carte décrit chaque fichier, donc elle coûte cher sur un gros lab. Les
  mises à jour sont bon marché.
- **Sobriété (SOBR, « un ajout = un retrait »)** : la vue web de vf-cockpit (Mermaid 3,4 Mo,
  parsers périmés) serait **remplacée**, pas doublée.

**Le point d'extension idéal existe déjà** : `build.mjs` inline toutes les extensions de
`assets/ui/*.js` dans l'ordre (05-theme … 60-export), et chacune ne parle au viewer que par
`window.Floorplan` (`version: 1`, gelé) : `graph`, `query`, `go`, `reveal`, `select`, `showBoard`,
`playFlow`, `addHeaderButton`, `addAskContext`, `ask`… Un calque VibeFlow serait un fichier
`70-vibeflow.js` plus une donnée injectée. Il ne manque en amont que deux crochets : un dossier
d'extensions supplémentaire et un JSON de calque inliné.

## 7. Options

| | A. Tester tel quel | B. Dépendre + calque | C. Fork complet | **D. Vendoriser épinglé + calque** |
|---|---|---|---|---|
| Quoi | `claude plugin install floorplan@floorplan` sur 1-2 labs | plugin amont + notre extension | copie dans `plugin/`, on la fait nôtre | copie épinglée d'une version (comme ELK chez eux), script de synchro, patches minimes, notre calque à côté |
| Coût | ~0 | faible, mais deux crochets amont requis | élevé et croissant | moyen, borné |
| Doctrine | OK (usage perso) | ✘ dépendance tierce | OK | OK |
| Suivi amont | natif | natif | perdu | diff de version relu à chaque synchro |
| Calque VibeFlow | non | oui si l'amont accepte les crochets | oui | oui |

## 8. Recommandation

1. **Tout de suite, A** : installer Floorplan tel quel sur un ou deux labs applicatifs
   (malt-keyword, LinkedinBot), faire une vraie carte complète avec descriptions, et vivre avec
   une semaine. Cela tranche la question du goût et mesure le coût réel d'une première carte.
2. **En parallèle** : proposer en amont les deux crochets (dossier d'UI supplémentaire, JSON de
   calque). Ce sont de petites PR, utiles à tous, et elles rendent D presque sans patch.
3. **Puis D, comme phase du jalon `vibeflow-v2.0`, après vf-signal (Phase 1)** : un module
   `vf-cockpit` renouvelé qui contient :
   - Floorplan vendorisé, épinglé, sans Cloud, avec le mode de permission forcé ;
   - un **générateur de calque** sans LLM, à partir de `.planning/workstreams/<ws>/` (ROADMAP,
     STATE, PLAN `files_modified`, SUMMARY), des DAG (`scope`, `status`), de
     `driver-lock.sh status --all` et du registre des agents. On repart des parsers de
     `feat/vf-cockpit-module`, mis à jour pour la partition et `.git/vf-driver/` ;
   - `70-vibeflow.js` : vues « phase en cours sur la carte », « mission en direct », « prévu /
     fait », Health croisé avec `vf-auditer` ;
   - `query.mjs` offert aux workers comme outil de repérage.

   Le pane vf-signal reste la vue **dans** la session, avec un bouton « ouvrir la carte ». La
   carte est la vue **à côté**.
4. **Plus tard, si l'usage le justifie** : un extracteur VibeFlow pour cartographier le framework
   lui-même.

**Pas de fork complet maintenant** : l'amont a 5 jours et avance d'une version par jour. Le
forker aujourd'hui, c'est porter seul 11 k lignes au moment où elles bougent le plus.

## 9. Questions à trancher

- L'emplacement : module `vf-cockpit` renouvelé, ou fusion avec vf-signal dans un seul module
  « cockpit » (pane + carte) ?
- Le moment : phase 2 du jalon `vibeflow-v2.0`, ou phase dédiée avant ?
- Accepte-t-on l'interface en anglais au début, ou traduit-on la chrome dans la version
  vendorisée ?
- Ouvre-t-on les deux PR amont au nom de Samuel ? C'est un geste public.

## 10. Direction retenue et POC (spike 002, 2026-11-01)

**Direction** (Samuel, session principale, 2026-11-01) : reprendre la DA et le moteur de graphes
de floorplan comme base du cockpit, avec deux sections, comme les onglets d'une application :
**Code** et **Projet**. Le Projet range toute l'information de VibeFlow par thématique, avec des
graphes dans lesquels on plonge en cliquant.

**POC** : `.planning/spikes/002-cockpit-code-projet/` (README, captures). Verdict **VALIDATED**.

- Le viewer de floorplan est générique (nœuds hiérarchiques, éléments rattachés, liens typés, ELK
  qui respecte l'ordre des données). Un jalon, une phase, un plan ou une exigence s'y modélisent
  au format `floorplan/graph@1`, **sans réécrire le viewer**. Il suffit de 5 patchs de quelques
  lignes et d'une extension de 99 lignes par `window.Floorplan`.
- Sur ce dépôt, en **2,3 s et sans LLM** :
  - onglet Code : 528 fichiers, **1 244 liens au lieu de 7** grâce à l'extracteur VibeFlow
    (dispatch `Agent(...)`, scripts appelés), 497 fichiers décrits depuis leur frontmatter ou
    leur en-tête ;
  - onglet Projet : 11 jalons, 65 phases, 263 plans, 281 exigences, 25 DAG, 1 460 liens ;
  - pont : 458 fichiers de code reliés aux plans qui les ont touchés, dans les deux sens ;
  - Recent work de floorplan : il surligne ce que les deux dernières phases ont changé.
- Ce qu'il reste à faire pour une vraie phase :
  - des questions sur l'onglet Projet ;
  - le direct (verrou, agents en vol : le terrain de vf-signal) ;
  - des types et une chrome en français ;
  - un Recent work tiré du diff réel de la branche de phase ;
  - les crochets P1 à P4 proposés en amont.

Cette direction remplace l'option D du § 8 sur un point : la copie figée n'est plus seulement la
carte du code, c'est **le socle du cockpit entier**. La question de l'emplacement (module
`vf-cockpit` renouvelé ou fusion avec vf-signal) reste ouverte.

## Sources

- <https://github.com/haydenschmitty/floorplan> (clone du 2026-11-01, tête `92d6854`, v0.6.0)
- <https://haydenschmitty.github.io/floorplan-demo/>
- `feat/vf-cockpit-module`, `spike/cockpit-live`, `~/.claude/mods/vf-signal/`,
  `.planning/notes/2026-10-29-HANDOFF-jalon-v2.md`
