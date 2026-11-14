# A2 — Architecture et performance du cockpit

> Annexe de `.planning/research/2026-11-10-audit-cockpit-etude.md`. Rapport brut de l'agent d'audit d'architecture. Dans le registre, ses constats M1 à M7 et B1 portent les identifiants `AUDC-AM1` à `AUDC-AM7` et `AUDC-AB1`, pour ne pas se confondre avec les constats d'interface. Rendu le 2026-11-10 sur `release/v2.77.0` (cockpit v1.4.0 et retours du panel non publiés). Texte de l'agent, chemins ramenés à la racine du dépôt. Les identifiants de suivi (`AUDC-…`) et la destination de chaque constat sont dans `REGISTRE.md`.

---

# Audit d'architecture du cockpit (`plugin/cockpit`, branche release/v2.77.0)

**[V]** = vérifié pendant l'audit (lu ou mesuré sur ce poste) · **[I]** = inféré. Les preuves citent `fichier:ligne` par nom de fichier ; les chemins absolus sont en fin de rapport. Rien n'a été écrit dans le dépôt : mesures par GET, par import en lecture seule des modules, et par un Chrome headless à moi, refermé. Aucun assemblage ni suite de tests n'a été lancé.

## 1. Schéma

```
ASSEMBLAGE (complet à chaque fois) — vf-cockpit.mjs open → vf-cockpit-build.mjs:54-129
  moteur scan.mjs → scan.json · vf-cockpit-code.mjs → architecture.json · vf-cockpit-project.mjs → graphe Projet
  moteur build.mjs:426-450 → index.html = viewer.html + ELK + polices + ui/NN-*.js + données, tout en ligne
  puis project.html (même page, autres données), copie de 52 vf-cockpit-*.mjs dans <lab>/.vibeflow/cockpit/,
  renommage par regex floorplan→vf-cockpit du HTML ET du code copié (vf-cockpit-rename.mjs:11-19)
SERVICE — un serveur par lab ou worktree : node <sortie>/serve.mjs --idle-exit 60 --port 4378 + sha1(lab) % 100
  serve.mjs (amont, 20 hunks) → crochet P13 → vf-cockpit-server.mjs : /api/vf/*, project.html, equipe.html (en mémoire)
                              → crochet P26 → processus enfant du terminal, second port
DIRECT — 2 flux SSE par page, aucun WebSocket
  /api/events (amont)     fs.watchFile(index.html, 1 s) → « reload »
  /api/vf/events (maison) fs.watch(.planning), anti-rebond 300 ms → patch ou structural ; filet de 5 s → who, lock, git
  page : patch → graphe muté en place + rerender() · structural → location.reload() · git → relit ses routes
GREFFE — API d'extension amont window.Floorplan + 16 fichiers maison sous ui/, chargés par ordre numérique
  + 19 diffs sur l'amont + globales window.__vf* + code navigateur de scripts/ sérialisé par .toString() au service
vf-signal — hors serveur : relance vf-cockpit-signal.mjs (0,82 s mesuré) toutes les 10 s, pane ouverte (cadence.ts:43)
```

## 2. Constats

**H1 · haute · Trois onglets saturent le navigateur [V mesuré].** Chaque page tient 2 flux SSE (`viewer.html:1958`, `70-vf-live.js:257`) et Chrome plafonne à 6 connexions par origine. Code, Projet et Équipe ouverts : `fetch /api/vf/etat` sans réponse en 5 s, quatrième page jamais chargée ; un onglet fermé, 2 ms. Conséquence : tiroir Git, questions et « dernière commande » figés sans message. Proposition : un seul flux par page (porter `reload` dans `/api/vf/events`), puis un flux partagé entre onglets (BroadcastChannel). Effort S.

**H2 · haute · Le serveur est sourd 9 % du temps [V mesuré].** Le filet (`vf-cockpit-live.mjs:142-153`) enchaîne en synchrone `collectWho` (318 ms, dont 87 % de sous-processus ; 1 959 `statSync` ; 9,8 Mio de queues de transcripts relus) puis un second `driver-lock.sh status` (`:62-67`). Mesuré de l'extérieur : GET à 2,6 ms de médiane, pics de 416 à 470 ms toutes les 5,0 s ; le filet tourne même sans client. Un changement de `.planning` ajoute 901 ms : planning lu deux fois (`vf-cockpit-project.mjs:64-65`), une fois par autre worktree (`:66`), quatre `status` identiques (741 ms). Le terminal a déjà été isolé dans un processus pour cette raison (`vf-cockpit-terminal.mjs:5`). Proposition : un `status` mémoïsé par cycle, lectures asynchrones (comme `lancerGitAsync`), cache par mtime, pas de filet sans client. Effort S, puis M.

**H3 · haute · Cycle de vie : le dernier lanceur gagne, sans trace [V observé].** Pendant l'audit, le PID 41271 (20:57:21, sans terminal) a été remplacé à 21:06:51 par le PID 95947 (`--terminal`), après réassemblage complet. Mécanisme : `open --terminal` sur un serveur sans terminal, ou tout `--rebuild`, l'arrête et le relance (`vf-cockpit.mjs:239-250`) avec un jeton neuf (`serve.mjs:91`). C'est la cause la plus probable de l'arrêt que tu as vu [I]. L'arrêt sur inactivité existe aussi et il est voulu : `--idle-exit 60` (`vf-cockpit.mjs:176`), contrôlé chaque minute (`serve.mjs:220`) ; seuls les flux `/api/events` comptent (`serve.mjs:521`), donc un serveur lu par curl s'arrête 60 min après son démarrage. Dans les deux cas `serveur.log` ne porte ni date ni motif. Aucun verrou autour d'assemblage et démarrage ; un `server.json` perdu laisse un orphelin jusqu'à l'inactivité ; 195 + 58 Mo de RSS par lab. Proposition : journal daté avec motif d'arrêt, verrou de lanceur, relance seulement si le code a changé (le `hash` écrit `serve.mjs:601` n'est jamais lu), toute requête authentifiée compte comme activité. Effort S.

**H4 · haute · La traduction réécrit les données du lab [V mesuré].** `80-vf-fr.js:142-146` traduit tout nœud de texte après rendu (463 entrées, 99 clés d'un seul mot). Dans la page servie, `tokens.ts` s'affiche « Jetons », `open.mjs` « Ouvrir », `health.mjs` « Santé » ; 11 libellés de données sur 1 547 sont touchés, dont une description devenue « a copy sur the map » et un mot supprimé en pleine phrase (règle `:36`). À l'inverse, une chaîne amont nouvelle reste en anglais sans alerte : seul l'inventaire statique la voit. Le coût est faible : 45 ms au chargement, 14 à 18 ms par rendu. Proposition : exclure titres et descriptions de cartes (S), puis une fonction `t()` aux points d'émission (M).

**H5 · haute · Couplage à l'amont [V lu ; coût I].** `assets__viewer.html.diff` : 63 hunks, +483 −297 sur 2 573 lignes, dont 15 hunks de CSS ; 10 lignes seulement portent un marqueur `vibeflow P`. `40-tour.js` est réécrit à plus de moitié. La base n'a jamais bougé (v0.6.0) ; la reproductibilité est solide (`synchro.sh`, rejouée en CI). Une montée de version demande des fusions à trois voies sur 83 hunks, un nouvel inventaire du dictionnaire et de ses 143 exclusions, des ancres de mutants à reposer : plusieurs jours [I]. Proposition : sortir le CSS dans une extension, proposer P1-P4, P6, P8 à l'amont, marquer chaque ligne maison, jouer une synchro à blanc ; ou assumer le fork et retirer l'appareil de patchs. Effort M à L.

**M1 · moyenne · La page sert de base de données [V].** Le graphe Projet ne vit que dans `project.html` : chaque patch relit puis réécrit 3,66 Mo (`vf-cockpit-live.mjs:78-85`), le serveur relit et reparse (`vf-cockpit-server.mjs:40-45`), `vf-cockpit-query.mjs:19` lit le HTML. Aucune route JSON pour `project@1`, `who@2`, `signal@1`, pourtant décrits dans `vf-cockpit-interface.json` ; vf-signal refait donc toute la collecte dans un processus neuf. Proposition : chantier 3. Effort M.

**M2 · moyenne · Poids [V mesuré].** `index.html`, 3,37 Mo : ELK 47,7 %, données 26,6 %, extensions 11,6 %, polices 7,5 %, viewer 4,2 %. 2,47 Mo identiques dans les trois pages, renvoyés à chaque navigation (`no-store`, `serve.mjs:500`). Environ 1,1 Ko de JSON par fichier : 11 Mo en ligne pour 10 000 fichiers [I]. Proposition : chantier 3.

**M3 · moyenne · ELK sur le fil principal [V mesuré].** `viewer.html:678`, sans worker (la CSP actuelle ne l'autorise pas). Vue de 100 cartes et 216 liens : 1 228 ms de gel ; un dossier de 300 fichiers gèlerait plusieurs secondes [I]. Un patch en direct sur l'onglet Projet coûte 14 à 30 ms, c'est sain. Aucune fuite : nœuds et écouteurs stables après 120 rendus et ramasse-miettes forcé. Proposition : ELK en worker, avec le chantier 3. Effort M.

**M4 · moyenne · Le code exécuté n'est pas celui du dépôt [V].** 52 modules copiés dans chaque lab puis renommés par regex (`vf-cockpit-build.mjs:111-117`) ; le renommage est porteur (chemins, en-tête de jeton, globales). Un serveur vivant garde l'ancien code après une mise à jour du plugin. Proposition : lancer le serveur depuis le module (chantier 5).

**M5 · moyenne · Plafond tenu par la longueur des lignes [V mesuré].** 58 fichiers, 6 831 lignes, mais 13 % dépassent 160 caractères (maximum 761) : 9 667 lignes à 100 colonnes. Plusieurs découpes suivent la taille, pas une frontière : dictionnaire `78` et `79`, `vf-cockpit-lancer-style.mjs` (12 lignes), trois fichiers `77-`. Environ 1 100 lignes de code navigateur vivent dans `scripts/` et partent par `.toString()` (`vf-cockpit-lancer-ui.mjs:250`), sans fermeture ni import possibles : une référence oubliée ne casse qu'à l'exécution. Proposition : plafonner en colonnes aussi, ranger ce code sous `ui/`. Effort M.

**M6 · moyenne · Pas d'état client [V].** 21 `MutationObserver` maison ; `70-vf-live.js:115-161` ne fait que restaurer focus, défilement et replis après chaque redessin ; `window.fetch` est enveloppé (`75-vf-modele.js:14-23`), `SC.store` remplacé (`:37-39`). Chaque nouvelle vue recode sa propre réparation. Proposition : chantier 4.

**M7 · moyenne · Tests solides mais chers [V compté, non rejoués].** 68 suites bash, 4 130 assertions, des mutants dans 52 suites sur 68 : la capacité à rougir est prise au sérieux. En contrepartie : 3,2 Mo de tests (3,7 fois le code), environ 6 950 s sur 9 040 s de CI (77 %, table de `ci-shard-suites.sh`), 400 pauses fixes, ancres de mutants collées au texte source, donc tout remaniement casse des suites. Sans Chrome, 28 suites sautent leur moitié navigateur et sortent 0, sans garde en CI (`ci.yml:402-446`). Non couverts : trois onglets, deux lanceurs concurrents, collision de port, réactivité pendant le filet, budgets de poids et de mise en page. Proposition : Chrome exigé en CI (S), socle de test partagé (M).

**B1 · basse · Assemblage et démarrage [V lu ; détail I].** Scan sans cache. Sur les 4,7 s, `buildProjectGraph` pèse 0,9 s [V], dont 0,74 s de verrous ; le reste n'a pas été mesuré. Avant d'écouter, le serveur lance en synchrone `claude --version` (délai 15 s, `serve.mjs:168`) ; le lanceur attend jusqu'à 30 s. En cas de collision de port (repli +1, `serve.mjs:590-593`) l'origine change, donc le `localStorage` aussi [I].

**Ce qui tient [V] :** vendoring reproductible, routes Git asynchrones, terminal isolé, contrat de schémas versionné, aucune fuite au rendu.

## 3. Cinq chantiers, du plus rentable au moins rentable

1. **Une collecte, un flux, une API d'état (S puis M).** D'abord quatre gestes : un flux par page, un `status` par cycle, planning lu une fois, pas de filet sans client. Ensuite un curseur par transcript (taille, décalage) qui alimente un index incrémental des sessions, et une route `GET /api/vf/state` aux schémas existants. La frise et le graphe de sessions deviennent des lectures d'index, les notifications des événements du flux, et vf-signal lit la route au lieu de relancer un processus.
2. **Cycle de vie explicite (S).** Verrou de lanceur, journal daté, plus de remplacement pour un simple drapeau, activité comptée sur toute requête ; en CI, Chrome exigé et deux scénarios (trois onglets, deux lanceurs).
3. **Données hors de la page (M).** Une coquille statique mise en cache une fois, plus `graph.json`, `project.json` et l'équipe en JSON. Fin des réécritures de 3,66 Mo ; une vue multi-lab devient une coquille et N sources ; ELK peut passer en worker au même moment.
4. **Magasin d'état client (M).** Un magasin alimenté par le flux, des panneaux abonnés rendus par clés. Il supprime les observateurs de réparation, et les prochaines vues s'y branchent sans toucher au viewer.
5. **Désendettement de l'amont (M à L).** CSS hors de `viewer.html`, traduction par `t()`, serveur lancé depuis le module (fin de la copie renommée), une synchro à blanc pour chiffrer le vrai coût.

## Chemins

- Scripts maison et tests : `plugin/cockpit/scripts/`
- Moteur (viewer.html, serve.mjs, ui/) : `plugin/cockpit/skills/cockpit-moteur/assets/`
- Patchs : `plugin/cockpit/amont/patches/`
- Cadence de vf-signal : `plugin/cockpit/signal/hooks/cadence.ts`
- CI : `.github/workflows/ci.yml` et `scripts/ci-shard-suites.sh`
- Mesures rejouables : `sondes/mesure-page.mjs`, `sondes/mesure-2.mjs`, `sondes/sonde-boucle.mjs`, `sondes/cout-direct.mjs`
