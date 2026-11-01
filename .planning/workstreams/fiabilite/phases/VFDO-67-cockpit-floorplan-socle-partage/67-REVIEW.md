# 67-REVIEW — revue de la Phase 67 (nœud revue-67, régime plein)

Revue : `vf-reviewer`, arbre `v2-cockpit`, branche `feat/v2-cockpit`, HEAD `eb2e786d`, diff `e3f3fe24..eb2e786d`.
Statut global : **gaps_found** (axe Standards : gaps_found, 4 majeurs ; axe Spec : gaps_found, 1 majeur). Aucun bloquant.
Lecture seule : aucun fichier de l'arbre relu n'a été modifié ; toutes les sondes ont tourné dans le scratchpad de session.

## Ce qui a été rejoué (et tient)

- Les 11 suites `plugin/cockpit/scripts/tests/test-cockpit-*.sh` : exit 0 chacune. `test-dag-atomic-save.sh`, `scripts/tests/test-check-python-isolation.sh`, `plugin/_internal/tests/test-vibeflow-update-cockpit.sh` : exit 0.
- Gates du job `gates` rejoués : `check-machine-paths`, `check-version-sync` (v2.74.0, 19 modules), `check-blueprints`, `check-manual`, `check-capability-activation`, `check-skills --strict --skills-dir=plugin --callers-root=plugin` (28 SKILL.md), `check-file-size --all` (0 avertissement), `check-gate-touche --base-ref e3f3fe24` (3 marqueurs conformes), `check-ajout-retrait` (couvert), `check-planning-consumers-registered`, `check-python-isolation` (42 invocations, rc 0), `synchro.sh verifier` (amont retrouvé à l'octet, 48 fichiers).
- Marque blanche : sortie assemblée d'un lab jetable, grep insensible à la casse : 1 occurrence dans `index.html` (le commentaire de licence marqué), 0 dans `serve.mjs`, `query.mjs`. Cloud : aucune occurrence de `run.app`, `waitlist`, `auth status`. Aucune URL de requête sortante dans les pages (liens d'aide seulement).
- Serveur réel sur lab jetable : Host étranger → 403 ; origine étrangère → 403 ; jeton absent → 403 ; jeton en query refusé hors flux ; segments cachés et traversée → 404 ; modèle hors liste → refus en SSE sans lancer `claude` ; POST sur `/api/vf/*` → 405 ; `/api/vf/doing?id=../../etc` → `id-invalide` ; `hello` du flux sans clé `doing`.
- Corps de requête limité à 20 000 caractères par l'amont : pas de ReDoS exploitable dans `answerLocally` (19 000 caractères adverses : 191 ms) ni dans le graphe Projet (lignes de 300 000 caractères : 37 ms).

## Axe Standards

### Majeurs

**S1 — Une question courante de l'onglet Projet fait tomber le serveur (`plugin/cockpit/scripts/vf-cockpit-ask.mjs:81,83`, `vf-cockpit-server.mjs:82-87`)**
- Entrée : « Qu'est-ce qui reste ? », « prochaine étape », « next » sur tout lab dont le jalon courant n'est pas reconnu : cas le plus courant d'un lab GSD à un seul jalon (STATE `milestone: v1.0`, ROADMAP à section « Phases », donc `curMs` indéfini).
- Sondé sur le vrai serveur : `TypeError: Cannot read properties of undefined (reading 'p')` à `vf-cockpit-ask.mjs:17` (`ref(t)` avec `t` indéfini), non rattrapée dans le `req.on('end')` de `serve.mjs`, le processus meurt (détaché, personne ne le relance). Fuzz sur deux labs plats : 5 questions sur 27 plantent. Sur ce dépôt (jalon reconnu) : 0 crash.
- Même famille : « Où en est-on ? » sur le même lab répond « Jalon en cours : [[n:undefined]]. Dernière phase :  · , le ? » ; un corps `null` sur `/api/ask` plante à `body.project =` (jeton requis).
- Correction : `if (!t) return null;` après la ligne 81 et traitement de `curMs` absent à la ligne 83 ; `try { … } catch { return 'agent'; }` autour de `answerLocally` dans `avantQuestion` ; rejeter `body` non objet en tête. Test à ajouter : fixture de lab à STATE `milestone: v1.0` sans jalon homonyme dans le ROADMAP, les trois questions ci-dessus.

**S2 — Une page rechargée montre des statuts périmés après un changement non structurel (`vf-cockpit-live.mjs:96`, `vf-cockpit-server.mjs:28-46`)**
- Cause : `ecrirePage(g)` n'est appelé que sur `structural` ; l'événement `patch` met à jour la page ouverte mais ni `project.html` sur disque ni `GP`/`pageP` du serveur ; le `hello` ne rejoue rien.
- Sondé : phase passée à `done` par une SUMMARY, `patch` émis (`{"ref":"n:ph-2","st":"done","foot":"1/1 plans"}`, seq 2), `project.html` sur disque garde `"foot":"0/1 plans"`.
- Conséquences : F5 ou nouvel onglet = dernier instantané structurel ; les réponses locales (`GP`) et `vf-cockpit-query.mjs` (lu par l'agent) répondent sur l'état périmé jusqu'au prochain changement de structure.
- Correction : sur tout refresh qui change `patch.length`, `vfChanged` ou `structural`, appeler `ecrirePage(g)` (déjà atomique) puis recharger `GP`/`pageP`. Test : D2 ne vérifie que l'événement ; servir `/project.html` après un patch et comparer.

**S3 — En lab plat, un verrou driver tenu est invisible (`vf-cockpit-who.mjs:110,115,118`, `70-vf-live.js:35`)**
- Cause : le code lit `st.locks` ; en lab sans compartiment `driver-lock.sh status --all` rend l'objet d'un verrou unique (sans `locks`).
- Sondé : lab plat, `acquire` fait, `status --all` rend `{"present":true,"owner":"rev",…}` ; `collectWho` rend `busy:false`, `workers:[]`, `locks.held:0`. Le badge dit « Driver libre » ; les agents du registre sont marqués orphelins/périmés (`held` faux).
- Conséquence : la page affirme « libre » pendant qu'un driver tourne (le verrou est justement ce qui protège d'un second driver).
- Correction : normaliser à l'entrée `const locks = Array.isArray(st.locks) ? st.locks : st.present ? [st] : []` (côté `who` et côté `lockText` de l'UI). Test : W2 ne simule que le format à `locks`.

**S4 — Un texte de planning contenant `<!--` puis `<script` casse les deux pages (`vf-cockpit-embed.mjs:21`)**
- Cause : `insererGraphe` n'échappe que `</script`. Un champ du graphe (but, résumé, description d'exigence, backlog) contenant `<!--` suivi de `<script` sans `-->` met le parseur HTML en « script data double escaped » : le script de données absorbe le script suivant, le viewer ne démarre pas. La réécriture live rend la panne persistante.
- Sondé (parse5) : `{details:"a <!-- b <script> c"}` → 1 balise script au lieu de 2 ; avec `-->` → 2. Ce dépôt ne porte pas le motif (0 occurrence dans son graphe) : entrée moins fréquente que S1 à S3 (labs web dont le planning parle de HTML), conséquence sans filet.
- Correction : remplacer chaque `<` du JSON sérialisé par `<` (valide en JSON et en JS) en plus de U+2028/2029. Test avec ce texte.

### Mineurs

1. `body.session` non validé (`vf-cockpit-agent.mjs:34,42`) : `session:"--dangerously-skip-permissions"` arrive en argv `--resume --dangerously-skip-permissions --permission-mode dontAsk …` (sondé via `argsAgent`). Aujourd'hui neutralisé par la CLI 2.1.316 (`--resume` sans identifiant valide refuse en `-p`), garde qui n'est pas la nôtre. `model` est validé contre une liste fermée, `session` non : n'accepter que `^[0-9a-f-]{36}$`. Test piège à ajouter (seul `model` l'est, Q4.4).
2. Masque de `revealDoing` incomplet (`vf-cockpit-who.mjs:147-152`) : `GITHUB_TOKEN=…`, `AWS_SECRET_ACCESS_KEY=…`, `API_KEY=…`, `github_pat_…`, `--password x` non masqués (`\b` ne coupe pas après `_`). Exposition limitée au clic local. Test W7 ne couvre que `ghp_` et `sk-`.
3. L'hystérésis du direct ne couvre que le retrait pur (`vf-cockpit-live.mjs:87`) : un ROADMAP lu tronqué (ajout et retrait à la fois) est cru sur-le-champ ; le test D4.1 dépend de l'horloge (corruption 450 ms vs relecture ~900 ms).
4. `diff` ne voit que ids, `st`, `foot` (`vf-cockpit-live.mjs:27`) : un renommage ou un résumé modifié n'émet rien ; pas de resynchronisation après reconnexion (`70-vf-live.js:77` ignore `hello.seq`).
5. Aucune exception rattrapée dans `route()` ni les minuteries ; `fs.realpathSync(root)` (`vf-cockpit-server.mjs:74`) lève si le lab disparaît ; `gather` lève si `meta.json` n'est pas un objet (`in` sur un non-objet) ; aucun `execFileSync` n'a de `timeout`. Un `git` ou `bash` bloqué gèle la boucle d'événements. Mesure : une collecte « qui » prend 0,61 s sur ce dépôt, rejouée toutes les 5 s en synchrone même sans client connecté.
6. `tail()` (`vf-cockpit-who.mjs:29`) ne ferme pas le descripteur si `readSync` lève (fuite sur la boucle de 5 s) : `try/finally`.
7. `80-vf-fr.js:50` : `s.replace(t, out)` interprète `$&`, `$'`, `$$` de `out` (chemins contenant `$`) : `() => out`.
8. `scripts/check-python-isolation.sh` : l'exclusion `*/assets/vendor/*` est par dossier, pas par nature de fichier ; un `.sh` posé sous un `assets/vendor/` échappe au gate (le test couvre `notvendor`, `vendorx`, `vendor.sh`, mais pas `vendor/x.sh`).
9. `test-cockpit-questions.sh:186` : `PASS=$((PASS+1))` inconditionnel après un `echo` (gonfle le compte, ne teste rien) ; `test-cockpit-vendor.sh` V4 impose `-lt 300` alors que l'ADR-035 dit ≤ 300 ; `test-vibeflow-update-cockpit.sh` I7 compare un nombre de fichiers du vrai `~/.claude` (une session concurrente le fait échouer).
10. Divers : `inventaireDeSortie` exporté et absent de l'en-tête `Exports` de `vf-cockpit-fr-inventaire.mjs` ; `activeKeys` retourné par `readPlanning` et jamais lu ; `ID_RE`, `ls`, `read`, `isFile` dupliqués dans plusieurs modules.

## Axe Spec (PLAN 67-01..07, 67-CONTEXT P67-D-01..18, CKPT-01..11)

### Majeur

**P1 — CKPT-06 / P67-D-01 « tous les labs » : un lab sans fichier de code scannable ne s'assemble pas (`vf-cockpit-code.mjs:19-22`, `vf-cockpit-build.mjs:25-28`)** — plan 67-02 l. 28 (« Onglet Projet sur tout lab GSD ») ; CONTEXT CKPT-06 (« onglet Code conditionnel »).
- Entrée : un lab GSD sans code (planning seul ; planning + README/docs en Markdown ; lab métier). Trois labs jetables sondés : `vf-cockpit-build.mjs .` sort en code 4 avec « échec de l'étape build.mjs : Fix the errors above and run build again. » (le moteur rejette `architecture.json` : « nodes must be a non-empty array »), car `architectureBrute` ne produit aucun nœud quand aucun fichier n'est de catégorie `code`.
- Conséquence : `/vf-cockpit` est inutilisable, onglet Projet compris, sur tous les labs sans code ; le message est l'anglais de l'amont (la cause n'est pas remontée : `run()` ne garde que la dernière ligne). Aucun plan ni test (fixtures toutes avec `src/`) ne couvre ce cas.
- Correction : garde sur `nodes.length === 0` (nœud « Racine » de repli, ou onglet Code omis tout en construisant le Projet), et message d'échec en français qui remonte la cause. Test : lab planning seul, assemblage code 0, page Projet servie.

### Couverture des exigences (vérifiée sur disque)

CKPT-01 socle + interface JSON versionnée, validateur et refus de `doing` : conforme (S3 réserve le format de verrou plat). CKPT-02 vendorisation, patchs rejouables, LICENSE et licences tierces : conforme (`synchro.sh verifier` rc 0). CKPT-03 aucun appel sortant, Cloud retiré : conforme (sonde réseau et grep, témoins verts). CKPT-04 marque blanche mécanique : conforme (1 occurrence, le commentaire de licence). CKPT-05 serveur unique, direct, repli polling : conforme sous S2 (statuts périmés après rechargement). CKPT-06 : écart P1. CKPT-07 questions locales, agent confiné (`--permission-mode dontAsk`, Bash limité, `(./**)`), sélecteur validé : conforme à la mesure `67-MESURE-claude-p.md` ; réserve S1 et mineur 1. CKPT-08 dernière commande jamais dans le flux ni un fichier : conforme (réponse ponctuelle authentifiée) ; mineur 2. CKPT-09 chrome en français : non rejoué (anglais résiduel du panneau Santé connu, hors revue). CKPT-10 module et pose par l'engine : conforme (3 scopes, binaires à l'octet). CKPT-11 `dag.sh` atomique : conforme (témoin rouge d'abord, `os.replace`, mode conservé, `*.tmp` ignoré par git).
Non écrit par le diff, attendu du geste de clôture du manager : ROADMAP et REQUIREMENTS portent encore « Planned » / `[ ]` pour la Phase 67.

### Écarts de périmètre notés

Le mandat classait `05-theme.js` et `06-blueprint.js` parmi nos extensions ; `VENDORED.txt` ne les liste pas en AJOUT : ce sont des fichiers amont, non jugés.

## Limites de cette revue

Pas de vérification de compilation outillée (module JavaScript et shell, pas de projet Xcode). Non rejoués : Linux et Windows réels (D-16 déclaré non mesuré), rendu visuel du navigateur, panneau Santé. Sonde de précédence de `--dangerously-skip-permissions` contre `--permission-mode dontAsk` non jouée (aurait coûté un appel de modèle ; la CLI refuse déjà le cas en `-p`).
