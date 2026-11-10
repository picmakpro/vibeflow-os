# A3 — Sécurité du cockpit

> Annexe de `.planning/research/2026-11-10-audit-cockpit-etude.md`. Rapport de l'agent d'audit de sécurité, version versée au dépôt : le dépôt est public et les correctifs ne sont pas livrés, donc les scénarios de A-01, A-02, A-03, B-01 et B-05 sont ramenés à leur classe ; preuves (`fichier:ligne`) et corrections sont entières. Le détail de reproduction est gardé hors dépôt, sur le poste de l'audit : copie des rapports bruts dans le dossier non suivi `.playwright-mcp/audit/rapports-bruts/` de l'arbre principal, et transcripts de la session. Dans ce rapport, « M7 », « M8 », « N3 », « N7 » et « A5 » désignent des constats de sécurité antérieurs (Phases 67, 71 et 72), pas des lignes du registre de cet audit. Rendu le 2026-11-10 sur `release/v2.77.0` (cockpit v1.4.0 et retours du panel non publiés). Texte de l'agent, chemins ramenés à la racine du dépôt. Les identifiants de suivi (`AUDC-…`) et la destination de chaque constat sont dans `REGISTRE.md`.

---

# Audit de sécurité du cockpit VibeFlow (`plugin/cockpit`)

Aucun constat critique ni haut : trois moyens, six bas, tous nouveaux. Les contrôles réseau tiennent sur toutes les sondes.

Racine : `<racine du dépôt>`. Abréviations : `S/` = `<racine>/plugin/cockpit/scripts/`, `M/` = `<racine>/plugin/cockpit/skills/cockpit-moteur/`.

Rien n'a été modifié dans le dépôt. Sondes HTTP sur l'instance 4457 (GET, OPTIONS, requêtes invalides). Sondes de lecture dans un dossier jetable hors dépôt, sans serveur. Une autre session a relancé l'instance à 21:06:51 avec `--terminal` (PID 41271 puis 95947), ce qui a permis de sonder le terminal Q (port 53006).

## 1. Dispositif en place

- **Liaison** : P écoute sur `127.0.0.1` seul (`M/assets/serve.mjs:596`), port stable par lab (`S/vf-cockpit-port.mjs:18-23`), repli +1 sur 20 essais (`serve.mjs:590-595`). Q écoute sur `127.0.0.1`, port éphémère, dans un processus enfant (`S/vf-cockpit-terminal-processus.mjs:179`).
- **P, Host / Origin / jeton** : Host exact (`serve.mjs:508`). Sur `/api/*`, Origin absente ou identique et jeton de 128 bits en en-tête (`serve.mjs:91,510-514`). Aucun en-tête CORS. `server.json` en 0600 (`serve.mjs:601-602`).
- **POST de lancement** : hôte, origine obligatoire, jeton de la page Projet en temps constant, type, 512 octets, schéma fermé (`S/vf-cockpit-lancer-post.mjs:84-107`).
- **Q** : Host et Origin exacts, secret de 256 bits en temps constant, amorçage 0600 à usage unique valable 60 s (`processus.mjs:88-99,126-131`, `S/vf-cockpit-terminal-amorce.mjs:18-46`).
- **CSP** : toute réponse porte `default-src 'none'`, `nosniff`, `X-Frame-Options: DENY` (`serve.mjs:490,502`). Les pages ajoutent des scripts par empreinte, `connect-src 'self'`, `frame-ancestors 'none'` (`serve.mjs:492-500`). Q limite `frame-ancestors` à l'origine de P (`S/vf-cockpit-terminal-page.mjs:66-69`).
- **Assainissement** :
  - échappement `h()` (`M/assets/viewer.html:689`) et `<` rendu en `\u003c` (`S/vf-cockpit-embed.mjs:21`) ;
  - segments cachés et liens sortants refusés par le serveur statique (`serve.mjs:576-582`) ;
  - masques de secrets (`S/vf-cockpit-lecture.mjs:43-62`) et transcript à liste blanche (`S/vf-cockpit-transcript.mjs:83-115`) ;
  - git durci (`S/vf-cockpit-paths.mjs:126-156`), sha strict (`S/vf-cockpit-git-details.mjs:68-79`), citation shell (`S/vf-cockpit-git-commandes.mjs:10`).
- **Agent `claude -p`** : `dontAsk`, outils de lecture, `--setting-sources ""`, `--strict-mcp-config` (`S/vf-cockpit-agent.mjs:14-20`). La question passe par stdin, 4 000 caractères (`serve.mjs:283`).
- **Terminal** : seul le détenteur du secret ouvre un PTY, par `python3 -I` du moteur (`S/vf-cockpit-terminal-session.mjs:95-96`). Le shell reçoit l'environnement d'origine moins `CLAUDECODE`, `CLAUDE_CODE_*`, `VF_COCKPIT_*` et toute valeur portant un jeton (`S/vf-cockpit-terminal-env.mjs:14-28`).
- **Lancement** : ligne à grammaire fermée, revalidée par l'assistant, armée après 1 s, sans retour chariot (`S/vf-cockpit-lancer-gabarit.mjs:30-31,83-88`, `M/terminal/vf-cockpit-pty.py:131-139`, `S/vf-cockpit-lancer-q.mjs:114`).
- **Bornes** : corps de 20 000, 50 000 et 500 000 (`serve.mjs:566,531,549`) ; entrée du terminal 65 536, tampon 262 144, session unique, grâce de 30 s (`processus.mjs:25`, `session.mjs:21,32,131`) ; git 10 s (`paths.mjs:167`) ; arrêt après 60 min sans onglet (`serve.mjs:220`) ; gardien du PTY et arrêt à la mort du parent (`vf-cockpit-pty.py:413-449`, `processus.mjs:184-186`).

Sondes, toutes conformes :

```
curl -H 'Host: evil.example:4457' http://127.0.0.1:4457/                 -> 403
curl …/api/status (sans jeton ; Origin tiers ; Origin null ; jeton faux)  -> 403
curl -X OPTIONS -H 'Origin: http://evil.example' …/api/ask                -> 403, aucun Access-Control-*
curl -X POST -H 'Origin: http://evil.example' --data x …/api/flows        -> 403
…/.cache/server.json · /%2ecache/… · /x%2f..%2f.cache%2fserver.json · /%E2%80%8C.cache/… -> 404
Q : GET /etat sans Origin -> 403 ; Origin de Q sans secret -> 401 ; GET /flux secret faux -> 401 ;
    POST /entree Origin de P -> 403 ; Host tiers -> 403
curl …/graph.json (sans jeton)                                            -> 200, 895 267 octets (M7, accepté)
```

## 2. Constats

### Moyenne

**A-01 — « Demander » reprend n'importe quelle session du lab.**
- Scénario : qui tient le jeton d'une page peut désigner à « Demander » une autre session du lab que la sienne. Le modèle répond alors avec tout le contexte de cette session, sorties d'outils comprises, donc au-delà de la liste blanche du transcript, et le tour s'ajoute à la session d'origine.
- Preuve : `serve.mjs:280` ne contrôle que le format ; aucun registre des sessions rendues (`serve.mjs:288`). Non sondé, aucune question n'a été envoyée. `claude --help` 2.1.322 dit de `--fork-session` : « create a new session ID instead of reusing the original ».
- Statut : nouveau. M8 de la 67 n'a fermé que l'injection de drapeau ; BACKLOG l.373 ne le cite pas.
- Correction : n'accepter que les identifiants rendus par ce serveur (ensemble en mémoire). Effort S.

**A-02 — Les liens symboliques du lab sont suivis à la lecture.**
- Scénario : un dépôt porte un lien symbolique vers un fichier situé hors du lab. L'assemblage copie le début de la cible dans la description de la carte, donc dans les fichiers servis sans jeton, puis dans l'export partagé. Un lien placé dans `.planning/` atteint de même la page Projet.
- Preuve : le confinement n'est actif que sous `lireConfine` (`S/vf-cockpit-planning.mjs:18-21`) ; voir aussi `S/vf-cockpit-build.mjs:87-94`, `M/scripts/scan.mjs:69-75`, `serve.mjs:57`.
- Sonde : assemblage d'un lab jetable portant un tel lien vers un faux fichier marqué. Le marqueur ressort deux fois dans la page assemblée et dans l'objet d'export reconstitué ; avec un lien dans `.planning/`, il ressort dans la page Projet. Le détail de reproduction reste hors dépôt jusqu'au correctif.
- Limite : le cas ne se produit que dans une configuration donnée du lab.
- Statut : nouveau. README l.78 ne promet le confinement que pour les autres worktrees.
- Correction : confinement par défaut à la racine réelle du lab, `lstat` dans le scan, masque sur les descriptions. Effort M.

**A-03 — Le dossier de sortie du lab reste du code exécuté.**
- Scénario : un agent qui n'a que le droit d'écrire dans le projet (`acceptEdits`, bac à sable) modifie un module du dossier de sortie du lab. Le serveur le recharge et l'évalue, hors de tout contrôle de permission ; l'agent de « Demander » lance le même module.
- Preuve : `serve.mjs:183-184,214-219`, `S/vf-cockpit-query.mjs:21-22`, `S/vf-cockpit-agent.mjs:17`, `S/vf-cockpit.mjs:176,186`. Lecture du code, non sondé (aucun serveur lancé).
- Statut : nouveau. README l.204 affirme que le lab n'est jamais une source de code ; l'assistant PTY, lui, vient déjà du moteur (T-71-48).
- Correction : charger le cœur de requête et les scripts de l'agent depuis le module, puis servir depuis le module avec la sortie en simples données. Effort M.

### Basse

**B-01 — Un worktree forgé élargit « qui est au travail ».**
- Scénario : une archive de lab peut déclarer un worktree qui pointe vers un autre projet du poste. Les sessions de ce projet et leur transcript réduit apparaissent alors dans le cockpit du lab piégé.
- Preuve : `S/vf-cockpit-arbres.mjs:25-33` garde même l'entrée `prunable`, sans `worktreeVerifie` ; portée dans `S/vf-cockpit-who.mjs:57-65,219-228`.
- Sonde (dossier personnel factice) : avec l'entrée forgée, le collecteur rend une session de l'autre projet et son mandat ; sans elle, 0 travailleur.
- Statut : nouveau, même famille que P78-D-38, corrigé pour le tiroir seulement.
- Correction : `worktreeVerifie` dans `arbresGit`. Effort S.

**B-02 — `/api/ask` sans plafond ni délai.**
- Scénario : chaque requête lance un `claude -p`, sans limite de nombre ni de durée, ce qui coûte en quota et en processeur.
- Preuve : `serve.mjs:323-363,564-568`. Lecture du code.
- Statut : nouveau.
- Correction : deux exécutions au plus, délai global, réponse 429. Effort S.

**B-03 — Pages sans jeton coûteuses, joignables depuis un site tiers.**
- Scénario : une page web quelconque enchaîne des GET sans CORS et occupe la boucle de P. Q, dans son processus, n'est pas touché.
- Preuve : `/equipe.html` est reconstruite à chaque requête (`S/vf-cockpit-server.mjs:136-143`, `serve.mjs:572`) et le mémo de CSP ne garde que 4 entrées (`serve.mjs:491-498`).
- Sonde : `curl -w '%{time_starttransfer}' …/equipe.html` rend 0,011 à 0,013 s pour 2,5 Mo ; `/` rend 0,455 s à froid puis 0,006 s. La rafale n'a pas été jouée.
- Statut : nouveau.
- Correction : refuser `Sec-Fetch-Site: cross-site` hors `/api`, mémoriser la page Équipe. Effort S.

**B-04 — L'export ne filtre pas les métadonnées VibeFlow.**
- Scénario : `meta.vfTouch` (titres et chemins de plans) et `meta.vfGit` (dépôt, worktree, branche) partent quel que soit `include`.
- Preuve : `serve.mjs:51-60`, `S/vf-cockpit-build.mjs:100`. Vérifié sur le `graph.json` de l'instance : 532 entrées dans `vfTouch`.
- Statut : nouveau.
- Correction : retirer les clés `vf*` par défaut. Effort S.

**B-05 — `.cache/terminal-mode` peut être pré-planté.**
- Scénario : le fichier du mode retenu n'est pas purgé au démarrage, contrairement à `skill.json` (`serve.mjs:380`) ; un fichier arrivé avec une archive du lab peut donc présélectionner un mode (`S/vf-cockpit-lancer-mode.mjs:24-27`). Le clic et l'Entrée humains restent requis.
- Preuve : lecture du code, non sondé.
- Statut : nouveau. T-72-127 ne visait qu'un tiers local.
- Correction : purge à l'assemblage, ou fichier hors du lab. Effort S.

**B-06 — Durcissements.** Lecture du code ; effort S.
- `inject` n'échappe pas `<` (`serve.mjs:174`) ; `version` et `model` sont aujourd'hui de source sûre.
- Le jeton de P est comparé par `!==` (`serve.mjs:514`).
- Le lanceur croit un `VF_COCKPIT_SCRIPTS_DIR` hérité (`S/vf-cockpit-paths.mjs:57-63`) ; le mod, lui, le vide.
- La citation shell diffère sous fish pour un chemin de worktree portant `\` (`S/vf-cockpit-git-commandes.mjs:10`) ; inféré.
- `CLAUDE_EFFORT` et `CLAUDE_PID` ne sont pas filtrés (`S/vf-cockpit-terminal-env.mjs:18`) : cela confirme BACKLOG l.383.

### Déjà acceptés, non rouverts

- **M7** : jeton et fichiers statiques lisibles par tout processus local, hypothèse mono-utilisateur (README l.204-207, arbitrage du 2026-11-06). A-01 et B-01 en élargissent la portée au-delà de ce que l'arbitrage décrit.
- **T-67-28** : injection de consigne dans l'agent.
- **Limite de fond du terminal** : le shell tourne sous votre compte dans un dépôt potentiellement hostile.
- **P72-D-02bis** : clic détourné.
- **P72-D-22** : reprise forgée du chat.
- **P69-D-27** : masque des transcripts fait au mieux.
- **A5** : `setsid` échappe à l'arrêt.
- **N3 et N7 de la 71** : `estNotre` par sous-chaîne, `serveur.log` en 0644.

Constats divers sans gravité :
- Le mod `signal/hooks` assainit `PATH`, `NODE_OPTIONS` et `BASH_ENV`, et ne cherche rien sous le lab : rien à signaler.
- Un `terminal-amorce` non consommé reste dans `.cache` après la relance de 21:06 ; il est périmé (60 s) et en 0600.

## 3. Non vérifié

- Tout ce qui exige un vrai `claude` : effet réel de `--resume` (A-01), tenue de `Bash(node …query.mjs:*)` face à un chemin collé, confinement de `Read` par lien symbolique.
- A-03 de bout en bout et la rafale de B-03, faute de pouvoir lancer un serveur ou charger l'instance.
- Aucun navigateur : exécution réelle de la CSP, comportement de Safari et Firefox, stockage du cadre Q, xterm.js.
- Les 28 points `innerHTML` de `viewer.html` : lus par échantillon (cartes, infobulles, menus, flux, réponses), sans fuzz par champ.
- Linux et Windows ; un second compte local (M7 et droits déduits des modes de fichier).
- `plugin/conductor/scripts/driver-lock.sh` : seuls l'origine de `workstream-policy.sh` et ses appels `git rev-parse` ont été lus.
- `health.mjs`, `screens.mjs` et `extract.mjs` du moteur : coût sur fichiers hostiles non mesuré.
