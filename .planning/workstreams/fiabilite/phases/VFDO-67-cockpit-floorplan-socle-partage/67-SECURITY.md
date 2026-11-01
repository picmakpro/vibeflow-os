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
