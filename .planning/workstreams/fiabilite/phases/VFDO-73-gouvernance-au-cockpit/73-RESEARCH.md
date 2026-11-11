# Phase 73 : Gouvernance au cockpit (la régie) - Research

**Researched:** 2026-11-11 (tête de branche e34fe859, base f763b556 = intégration `cockpit-audit`)
**Domain:** onglet Équipe du cockpit VibeFlow : page JS inlinée (moteur vendorisé + extensions `ui/*vf*`), serveur Node ESM sans dépendance, flux SSE, lecture de transcripts et de verrous
**Confidence:** HIGH sur les points d'ancrage du code (lus ce jour, lignes citées) ; MEDIUM sur la forme de `claude agents --json` (sources tierces, une sonde réelle manque) ; MEDIUM sur tout ce qui dépend de la Phase 79 (branche parallèle non fusionnée)

Conventions de preuve de ce fichier. `[VERIFIED: chemin:lignes]` = fichier ouvert cette session, valeur citée mot pour mot à côté. `[CITED: source]` = document lu, pas rejoué. `[ASSUMED]` = hypothèse documentée : le CONTEXT interdit toute question, donc chaque hypothèse porte sa recommandation et son repli. Chemins relatifs à la racine du dépôt ; aucun identifiant de session ni chemin du poste n'est écrit ici (dépôt public). Aucun code, test, serveur ni navigateur n'a été lancé (phase de planification seule).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
P73-D-01 à P73-D-32 de `73-CONTEXT.md` (section « Decisions », y compris « Décisions déjà rendues » : direction « régie » du 2026-11-11, AUDC-Q2, Q3, Q4, lot 0) sont verrouillées. Elles ne sont PAS recopiées ici : le fichier source fait foi (PREAMBLE : « décisions P73-D-01..28 : FAIT FOI », complétées par D-26 précisée et D-29 à D-32 à la tête e34fe859) et une copie résumée créerait une dérive. Chaque décision est rappelée, avec son ancrage code vérifié, dans « Points d'ancrage par exigence ». Aucune alternative n'est explorée pour elles ; là où une décision se heurte au code présent, l'écart est dit dans « Constats structurants » et jamais tranché contre le CONTEXT.

### Claude's Discretion
Noms internes des fonctions et modules neufs, découpage fin des fichiers d'interface, forme exacte des fixtures (noms inventés seulement : dépôt public), ordre des tâches dans une vague.

### Deferred Ideas (OUT OF SCOPE)
- Notification du système (AUDC-I09, part).
- Convention structurée pour les arbitrages en attente écrits dans les CONTEXT (S-3).
- Actions sur une session, dont « Demander l'arrêt » d'un orphelin et « Répondre » (Phase 81, AUDC-Q3).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description (REQUIREMENTS.md, compartiment fiabilite, lignes 1689-1704) | Research Support |
|----|-----|------------------|
| REGI-01 | Quatre sections, compteurs, sous-titre, état vide | Helpers réutilisables dans `ui/71-vf-equipe-rendu.js` (`actif`, `titreEquipe`, `nommer`, `GLYPHE`) ; observation `window.__vfLive.who` ; constat C7 (clé de ligne) |
| REGI-02 | Rendu côté page, adaptateur unique de source | `window.VF_ETAT` absent du code présent (grep vide) ; événement `vf-who` et `window.__vfLive` présents (`ui/70-vf-live.js:14,199`) ; événement `lock` sans relais DOM (constat C9) |
| REGI-03 | Retrait du canevas, enveloppe `cockpit-equipe@1` gardée | `vf-cockpit-server.mjs:143-155`, `vf-cockpit-equipe-carte.mjs:34-89`, `ui/72-vf-equipe.js` entier ; inventaire des témoins qui rougissent (section dédiée) |
| REGI-04 | « À vous » : sessions `attend` + phases `human_needed` | `vf-cockpit-etat-officiel.mjs:21-34`, `vf-cockpit-equipe.mjs:93-96`, `vf-cockpit-avancement.mjs:83` (présence seule) ; constats C2 et C6 |
| REGI-05 | Classement par impact | DAG déjà découverts (`vf-cockpit-who.mjs:130-138`), `rattacher` limité aux sous-agents (`vf-cockpit-equipe.mjs:137`) ; constat C2 ; champ `dag` de la 79 absent |
| REGI-06 | Tenant du verrou, liste blanche | Flux `lock` brut (`vf-cockpit-live.mjs:63-68,150`), champs bruts de `driver-lock.sh:765` ; constat C3 (`tenu` / « depuis ») |
| REGI-07 | Alerte du watchdog, fenêtre à source unique | `plugin/conductor/scripts/check-guard-health.sh:127` ; `vf-cockpit-paths.mjs:72-87` (résolution du dossier de scripts) |
| REGI-08 | Arbres de travail | `vf-cockpit-git.mjs:192,215`, schéma `cockpit-git-worktrees@1`, événement DOM `vf-git:signal` (`ui/70-vf-live.js:269`) ; constat C11 (jointure agent → arbre) |
| REGI-09 | Vivacité, orphelin, glyphes | Constantes `CALME_S` 120, `LONGUE_S` 900 (`ui/71:61,63`), `SILENCE_MAX_S` 1800 (`vf-cockpit-equipe-etat.mjs:7`) ; constat C4 (âge périmé au `hello`) |
| REGI-10 | « Attend ses agents » | Lecteur `cherche` (`vf-cockpit-lecture.mjs:20-34`) et patron `outilEnCours` (`vf-cockpit-equipe-etat.mjs:13-30`) ; champ à ajouter au contrat (`vf-cockpit-interface.json:30`) |
| REGI-11 | « Terminé, à relire », « lu », titre | `GET /api/vf/transcript` (`vf-cockpit-server.mjs:104-110`), lecteur `ui/72:179-192` et `ui/71:152-170`, étiquette de lab `GET /api/vf/modeles` (`:111-115`) |
| REGI-12 | Titre et favicon, compositeur unique | Quatre écrivains du titre (pas trois) : `viewer.html:2375`, `00-vibeflow.js:13`, `76-vf-git-entete.js:19`, `80-vf-fr.js:147,159` ; CSP `img-src 'self' data:` (`serve.mjs:514`) |
| REGI-13 | « Ailleurs sur ce poste » | `vf-cockpit-etat-officiel.mjs:21-63` (cwd jeté), route à ajouter dans `vf-cockpit-server.mjs:80-119` ; collisions de nom (constat C1) |
| REGI-14 | Un style de bouton, nom écrit une fois, santé | Quatre styles recensés (`ui/70:32-33`, `.btn` viewer, `a.vf-link`, `.r-doing/.r-tog`) ; santé = `ui/20-health.js` vendorisé (constat C6bis) |
| REGI-15 | Accroches de la Phase 74 | Ancres `#r=n:se-` / `n:ag-` (`00-vibeflow.js:282-286`), `74-CONTEXT.md` (préfixe `ui/74-vf-*`, table de glyphes unique) |
| REGI-16 | Non-régression, LE → LR, nettoyage à l'émission, compteur 214 | Inventaire des témoins, `scripts/check-version-sync.sh:134`, mutants de `test-cockpit-who.sh:679-681` |
</phase_requirements>

## Summary

La régie est une page de rendu pur : elle lit `who@2` et le flux `lock` déjà poussés par le serveur, et le serveur n'a besoin que de trois ajouts de données (champs facultatifs de `who@2` : `attendAgents`, `lancee`, plus la fenêtre de stall et l'impact ; une route `GET /api/vf/ailleurs`). Presque tout le risque est dans les jointures : (a) ce que le code présent permet de dire sur une session qui attend (une session n'a jamais de `rattachement`, donc l'impact d'une ligne « À vous » est, au mieux, « retient toute la mission » ; la détention du verrou ne peut se décider que côté serveur, avant que `session_ids` quitte le flux) ; (b) le retrait du canevas, qui fait rougir une quinzaine de suites dont plusieurs ne figurent pas dans la liste de P73-D-04 ; (c) quelques contrats du CONTEXT qui ne tiennent pas tels quels contre le code (voir « Constats structurants » C1 à C14).

La Phase 79 n'est pas fusionnée : aucun de ses contrats (`VF_ETAT`, `lock` projeté, champ `dag`, `sortisSilence`, `finMotif`, table de routes, `socle-serveur.sh`) n'existe dans le code. Toute lecture de l'un d'eux est « à revalider » et se plie sur la forme présente. La régie peut et doit être livrée sans elle (P73-D-02, P73-D-23).

**Primary recommendation :** planifier en trois vagues (données pures, rendu, retraits + témoins), ne rien faire dépendre de la 79 sans repli, créer la suite unique `test-cockpit-regie.sh` avec un harnais VM + un harnais CDP partagés (fichiers `tests/*.mjs` ≤ 300 lignes), écrire les témoins rouges AVANT le code, et traiter dès la vague 1 les cinq décisions à hypothèse documentée de « Open Questions » (A1 à A8) pour qu'aucun plan ne les découvre en cours d'exécution.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Collecte des agents, états, orphelins | API / Backend (`vf-cockpit-who.mjs`, `vf-cockpit-equipe.mjs`) | Local OS (`claude agents --json`, transcripts) | Seul le serveur lit le disque ; la page ne lit jamais un transcript brut |
| Nouveaux champs `attendAgents`, `lancee`, impact, détention de verrou | API / Backend (module de gouvernance neuf, appelé par `who.mjs`) | — | `session_ids` et les DAG n'existent que côté serveur (constat C2) ; liste blanche à l'émission |
| Fenêtre de stall | API / Backend | — | `VF_STALL_WINDOW` est l'environnement du serveur ; la page reçoit un nombre ou `null` |
| Décroissance silencieux/suspect, orphelin affiché | Browser / Client | API (âge à jour) | Dépend du temps écoulé entre deux poussées (`ecoule()`), donc côté page ; exige un âge frais (constat C4) |
| Tri par impact, quatre sections, arbre, clés de ligne | Browser / Client | — | Le tri dépend de l'ancienneté qui avance |
| Tenant du verrou | Browser / Client (liste blanche) | API (projection, 79 A15) | Défense en profondeur des deux côtés (P73-D-08) |
| « Ailleurs sur ce poste » | API / Backend (cwd ne sort pas du module, route dédiée) | Browser (affichage seul) | Le nom d'un autre lab ne vit que dans la page servie |
| État « lu » | Browser (`localStorage` par lab) | — | Aucune route d'écriture admise (P73-D-14) |
| Titre d'onglet, favicon | Browser (compositeur unique) | — | Aucun appel réseau, CSP `data:` suffisante |
| Worktrees et travail non commité | API (routes Phase 78, déjà là) | Browser (jointure) | Aucun appel git neuf |
| Coquille d'Équipe sans cartes | API (`pageEquipe` ou, après la 79, `graphe?onglet=equipe`) | — | Même constructeur, même schéma `@1` |

## Standard Stack

Aucun paquet externe n'entre dans cette phase. Tout le code du module est Node ESM sans dépendance externe (imports `node:*` et modules frères du dossier seulement, `[VERIFIED: plugin/cockpit/scripts/vf-cockpit-who.mjs:11-21]`) ; les pages sont du JS inliné sans framework.

### Core
| Brique | Version | Rôle | Pourquoi |
|--------|---------|------|----------|
| Node.js (ESM, sans dépendance) | 26.5.0 sur le poste de recherche ; les suites passent sur Node 22+ en CI [ASSUMED] | modules `vf-cockpit-*.mjs` | Règle du module : zéro dépendance, `fichiersExecution` copie tout `vf-cockpit-*.mjs` (`vf-cockpit-build.mjs:22`) |
| Extensions `ui/*vf*.js` | — | rendu de la régie | Seul lieu de code d'interface sans toucher le moteur (P73-D-24) |
| bash + node + Chrome headless (CDP) | — | suites | `chrome-session.mjs` (`executer`, `attendre`, `stable`, `stabiliser`) ; sans navigateur la suite est sautée hors CI et échoue en CI (`chrome-saut.sh`) |

### Supporting
| Brique | Rôle | Quand |
|--------|------|-------|
| `vf-cockpit-lecture.mjs` (`cherche`, `masque`, `nettoieTitre`, `retireAffichage`, `ID_RE`) | lecture de fin de transcript, nettoyage d'affichage | `attendAgents`, nettoyage de la branche (D-22) |
| `vf-cockpit-paths.mjs` (`driverLockScript`, `resolveScriptsDir`, `shBorne`) | localisation de `check-guard-health.sh` à côté de `driver-lock.sh`, sous-processus bornés | fenêtre de stall |
| `vf-cockpit-lancer-suivi.mjs` (`entreeLanceeValide`) | revalidation de `lancee` | D-21 |
| `ui/71-vf-equipe-rendu.js` (`glyphe`, `GLYPHE_ETAT`, `titreEquipe`, `duree`, `transcript`) | table de glyphes unique (P74-D-29), rendu du transcript | régie, tiroir |

### Alternatives Considered
| Au lieu de | Alternative | Compromis |
|------------|-------------|-----------|
| Page `GET /api/vf/graphe?onglet=equipe` de la 79 | `pageEquipe` actuelle | Même constructeur ; choisir selon l'ordre de fusion (P73-D-23) |
| Calcul de la décroissance côté serveur | côté page | Rejeté : le temps qui passe ne change pas `whoSig`, le serveur ne repousse rien |

**Installation :** aucune. **Version verification :** sans objet (pas de paquet).

## Package Legitimacy Audit

Aucune installation de paquet externe dans cette phase. Le seam `package-legitimacy` n'a pas été interrogé (rien à vérifier) ; tout nom de paquet qu'un plan introduirait devra repasser par la porte avant d'être recommandé.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (aucun) | — | — | — | — | — | — |

**Packages removed due to [SLOP] verdict:** none. **Packages flagged as suspicious [SUS]:** none.

## Constats structurants

Ces points ne sont pas des questions (le CONTEXT interdit d'en poser) : ce sont des faits du code qui contraignent les plans. Chacun dit sa conséquence et son repli.

**C1. Collision de noms « ailleurs ».** Le module `plugin/cockpit/scripts/vf-cockpit-ailleurs.mjs` existe déjà (avancement d'une phase menée dans un autre worktree : `export const ETAT_ORDRE`, `lireAilleurs`, `fusionner`), avec sa suite `tests/test-cockpit-ailleurs.sh` (120 lignes) et un champ de donnée `avancement.ailleurs = { arbre, branche }` (`vf-cockpit-ailleurs.mjs:46`). La fonction `ailleurs()` de P73-D-16 (sessions d'AUTRES labs) est un autre sujet. Pas de conflit d'import (autre module), mais : ne pas ajouter la fonction dans ce fichier, nommer la suite et les témoins « régie » (jamais `test-cockpit-ailleurs`), et dire la distinction dans l'en-tête du README du module. [VERIFIED: vf-cockpit-ailleurs.mjs:1-3,46]

**C2. Une session n'a jamais de `rattachement`, et `session_ids` quitte le flux avec la 79.** `rattacher` saute tout ce qui n'est pas sous-agent : `if (w.kind !== 'subagent') continue;` `[VERIFIED: vf-cockpit-equipe.mjs:137]`. Or les lignes de « À vous » issues de l'état officiel sont des SESSIONS (la clé de `claude agents --json` est `sessionId`, `vf-cockpit-interface.json:109`). Conséquence : pour une ligne « À vous » de session, le libellé « retient N nœuds » est inatteignable avec le code présent ; restent « retient toute la mission · N nœuds » (session détentrice du verrou, DAG visible) et « impact inconnu ». Décider qu'une session détient le verrou d'une mission demande `session_ids` (champ du statut brut de `driver-lock.sh`, `"session_ids": %s`, ligne 765), que l'amendement A15 de la 79 retire du flux. Recommandation : le module de gouvernance (côté serveur, appelé depuis `gather` de `vf-cockpit-who.mjs` qui lit déjà `st.locks`, lignes 107-113) calcule la détention AVANT la projection et n'émet que `{ws, phase}` sur le travailleur session (champ facultatif). Repli côté page, sans `session_ids` : détention seulement si `owner` égale l'identifiant d'une session collectée (règle de `detenteur`, `ui/70:81`), sinon « impact inconnu ». [VERIFIED: vf-cockpit-equipe.mjs:137 ; driver-lock.sh:765 ; ui/70-vf-live.js:81]

**C3. « depuis N » du verrou : `tenu` est un booléen, la prise est `lease_seconds`, que A15 exclut.** `vie.mjs` pose `tenu: true` (booléen) et `ageS: num(l.age_seconds)` (âge du dernier battement) `[VERIFIED: vf-cockpit-vie.mjs:33 « tenu: true, stale: bool(l.stale), ageS: num(l.age_seconds) »]` ; le contrat `signal` déclare `"verrou": { "requis": ["ws", "scope", "phase", "tenu", "stale", "ageS", "ttl", "progressAgeS", "owner"] }` (`vf-cockpit-interface.json:20`). Le tiroir actuel dit « tenu depuis » avec `lease_seconds` (PU-G-179, `ui/70:74-76`). Le CONTEXT (P73-D-08) et la spec (§ 6.1) écrivent « depuis = le champ `tenu` (date de prise) » : ce champ n'est pas une date. A15 (79) liste `tenu, stale, ageS, ttl, progressAgeS, owner, childrenRunning, dag` et exclut `lease_seconds`. Conséquence : la durée « depuis N » de la ligne de mission n'a aucune source dans la liste blanche. Repli retenu (hypothèse A3) : afficher `ageS` sous un autre libellé (« dernier signe il y a N min ») tant que la 79 n'a pas ajouté un champ numérique de prise (demande à renvoyer à la session principale : `priseS`, entier, ni chemin ni identifiant) ; ne JAMAIS étendre la liste blanche de la page à `lease_seconds` sous ce nom brut. [VERIFIED ci-dessus ; 79-CONTEXT A15 lu via git show]

**C4. `snapshot().who` peut porter des âges périmés.** `tour()` ne remplace `who` que si la signature change : `if (whoSig(nw) !== whoSig(who)) { who = nw; emit('who', …) }` `[VERIFIED: vf-cockpit-live.mjs:149]`, et `whoSig` exclut les âges (`:51`). Un onglet qui se connecte après une longue accalmie reçoit un `hello` dont `who.workers[].ageS` date de la dernière poussée, alors que la page y ajoute seulement le temps écoulé depuis la RÉCEPTION (`ui/71:15-17`, `whoAt`). La décroissance « silencieux > 120 s, suspect > fenêtre » (P73-D-11) serait fausse pour ce second onglet. Repli sans toucher la 79 : une ligne d'`live.mjs` (`who = nw` hors de la condition, l'émission restant conditionnelle) ; à défaut, le serveur horodate `at` par collecte et la page corrige par `Date.now() - Date.parse(who.at)`. Témoin obligatoire : deux onglets, le second connecté après 10 min de silence. (A79 réécrit `whoSig` : même ligne, résolution à la jointure.)

**C5. `whoSig` ignore tous les champs que la régie ajoute.** Il ne retient que `kind, id, tree, branch, stale, titre, task, parent, etat, action, rattachement` `[VERIFIED: vf-cockpit-live.mjs:51]`. `attendAgents`, `lancee`, l'impact, la détention, `enCours` et `orphan` n'y figurent pas : sans extension de `whoSig`, aucun `who` n'est poussé quand seuls ces champs changent. L'amendement A17 de la 79 le réécrit (« objet entier moins une liste de champs volatils ») ; avant sa fusion, la vague 1 étend la ligne 51 (un plan, un fichier) et le témoin de mutation `M-W23-SIG` (qui ancre sur `x.titre || ''`, `test-cockpit-who.sh`, section W23) doit suivre.

**C6. Phases `human_needed` périmées dans les données réelles.** Les VERIFICATION des phases 60 et 69 portent `status: human_needed` (en-têtes ouverts : lignes 4) alors que ces phases sont cochées `[x]` au ROADMAP (lignes 113 et 122 de `ROADMAP.md` du compartiment). Une lecture naïve de P73-D-06 ajouterait « Phase 60 » et « Phase 69 : vérification humaine demandée » à « À vous » de ce dépôt pour toujours, et le titre d'onglet compterait ces lignes (P73-D-15). Hypothèse A1 : une ligne de phase n'est émise que si la phase n'est NI `done` NI archivée (`ph.done` posé par `parseRoadmap`, `vf-cockpit-planning.mjs:44`, et `archive: true`, `:126`). Témoin : un dossier de phase cochée avec VERIFICATION `human_needed` ne produit aucune ligne (rouge avant : la ligne existe). Transport : la lecture d'en-tête se branche sur `reste` de `vf-cockpit-avancement.mjs` (qui a déjà `lire`, ligne 83) ; le résultat voyage dans `who@2` (champ facultatif de premier niveau) car aucun autre canal vivant n'atteint la page Équipe (le patch `vf` du flux est ignoré hors Projet, `ui/70:273`) ; la collecte réutilise le graphe déjà construit par `live.mjs` à chaque changement de `.planning/` pour ne pas relire le planning toutes les 5 s.

**C6bis. « Santé ni calculée ni injectée » se heurte à D-24.** `ui/20-health.js` est un fichier du MOTEUR (ligne `PATCH assets/ui/20-health.js P27,P29` de `VENDORED.txt`). Il s'exécute dès qu'il y a un graphe : sa garde de sortie est `if (!SC || (SC.exported && !SC.graph.health)) return;` `[VERIFIED: ui/20-health.js:7]`, et `EXPORTED = G.meta.exported` côté viewer (`viewer.html:673`), drapeau qui change toute la page. L'enveloppe d'Équipe n'a pas de `health`, donc le calcul est déjà vide (liste de 0 problème) ; ce qui reste est le bouton et la section, masqués par `00-vibeflow.js:134`. Hypothèse A2 : rester dans D-24 (aucun fichier du moteur), garder cette règle CSS telle quelle (M3.8 inchangé, aucune ligne ajoutée à `00`) et documenter que « pas calculée » est vrai par construction (pas de `health` dans l'enveloppe) ; retirer vraiment le bouton demanderait un patch de `20-health.js` et un diff à régénérer, c'est-à-dire l'inverse de D-24.

**C7. Un agent affiché deux fois.** P73-D-29 impose la clé `section + identifiant`. Le code présent porte `data-vf-agent="<id>"` seul sur chaque `li` du tiroir (`ui/71:110`) et `cleBtn`/`rendreFocus` de `70` retrouvent par identifiant : ne pas réutiliser ces sélecteurs, ils seraient ambigus sur la régie (deux lignes même id dans « À vous » et l'arbre).

**C8. Fichiers modifiés par D-26 : le pli des terminés est dans `71`, pas dans `70`.** Le pli « Terminés depuis moins de 24 h » du tiroir est produit par `arbre()` dans `ui/71-vf-equipe-rendu.js:141-142` ; `70` ne fait que mémoriser son état ouvert (`:133-135`). La liste de D-26 (« pli du tiroir et bouton N au travail dans 70 ») est donc inexacte : le pli se retouche dans `71` (231 lignes, marge de 69), le bouton « N au travail » dans `70` (`:190 onClick: whoPanel`, 285 lignes). `00-vibeflow.js` : deux lignes existantes (`:13` titre, `:282-286` ancres), 298 lignes. L'exportation de nouveaux helpers de `71` (orphelin, GLYPHE_ETAT, MOT) se fait en réécrivant la ligne 230 (`window.__vfEquipeRendu = {…}`), sans ligne neuve.

**C9. L'événement `lock` n'a aucun relais DOM.** `showLock(l)` met `probe.lock = l` (`ui/70:189`) mais seul `setWho` émet un événement de document (`vf-who`, `:199`). Une régie qui lit `__vfLive.lock` à chaque `vf-who` et toutes les 30 s ignore un changement de verrou isolé (cas fréquent : le battement bouge, `who` non). Sans ajouter de ligne à `70` : relire `lock` sur la minuterie de 30 s et à `vf-who` (latence ≤ 30 s, acceptée en hypothèse A4) ; avec la 79 : abonnement `VF_ETAT.abonner('etat', …)`. Il n'existe pas non plus d'instant de réception du verrou (`whoAt` seulement) : la durée « il y a » d'un verrou se calcule depuis son `ageS` + temps écoulé depuis le dernier relevé de la régie.

**C10. Nom de l'événement `git`.** D-10 dit « l'événement `git` » ; dans la page c'est l'événement de document `vf-git:signal` (`ui/70:269`, relais de l'événement SSE `git`). Avec la 79 : clé `git` de `VF_ETAT`.

**C11. Jointure agent → arbre de travail.** La ligne d'un agent porte `tree` (libellé relatif au premier arbre, `vf-cockpit-who.mjs:67`) et `branch` ; les routes de la 78 portent `chemin` absolu et `branche` (`vf-cockpit-git.mjs:192`, qui émet `chemin: net(w.chemin)` : l'absolu est déjà servi à la page, la régie ne doit pas le copier dans le DOM). Aucune clé commune sûre côté page (la page ne connaît pas l'arbre principal absolu). Hypothèse A5 : joindre par nom de branche quand il est unique parmi les worktrees, sinon rien (jamais deviné) ; le compte « N modifiés » de la ligne 2 n'apparaît que si la jointure est établie.

**C12. Le moteur garde son chrome sur Équipe.** `#stage` (`<main id="stage">`, `viewer.html:620`) contient le canevas (`#svg`, `#viewport`) ET le bloc de titre `#context` ; zoom, ajustement, résultats de recherche, panneau et boutons d'en-tête sont du chrome moteur. Les masquer se fait en CSS/DOM par les extensions (D-24), et touche des témoins : `R14.1-R14.3` (zoom de l'onglet Équipe), `R13`, `R17-R20`, `EK10/13/14/17`, `H6.2` (lit `#context h1`), `X4.5` (compte `<main>` : 1 passe encore, mais la région principale devient `section role=main` ; le témoin doit compter `main, [role=main]` visibles pour rester un vrai témoin). `window.FLOORPLAN_SERVER` et `window.Floorplan` s'écrivent ainsi dans le source ; la sortie assemblée les renomme (`VF_COCKPIT_SERVER`, `VibeFlow`, en-tête `x-vf-cockpit-token`) `[VERIFIED: serve.mjs:533 « req.headers['x-floorplan-token'] » ; build.mjs:112-117 renommerHtml ; tests/test-cockpit-chaine-xss.sh:57 « 'x-vf-cockpit-token' »]` : les fichiers `ui/` neufs se rédigent avec les noms du source, les harnais de page voient les noms renommés.

**C13. Marqueurs de fichier.** Chaque `ui/*.js` neuf doit commencer par `// VibeFlow (` (sinon l'inventaire anglais de `test-cockpit-chrome-fr.sh` le lit comme chrome du moteur : `vf-cockpit-fr-inventaire.mjs`, en-tête « un marqueur d'extension VibeFlow (déjà en français) »), et prendre une ligne `AJOUT assets/ui/<nom>` dans `VENDORED.txt` : `synchro.sh verifier` retire les fichiers AJOUT avant de hacher l'arbre, un fichier non listé fait échouer `V6.1` `[VERIFIED: plugin/cockpit/amont/synchro.sh:100-108]`. Préfixe de nom : la 74 réserve `ui/74-vf-*` (`74-CONTEXT.md`, P74-D-43) ; la régie prend `72-vf-regie-*` (tri après `72-vf-equipe.js`, avant `73-` et `74-`, donc le registre `window.__vfEquipeVues` existe avant que la 74 s'y déclare).

**C14. Hypothèse documentée sur le flux `lock` avant 79.** Le payload brut contient, pour un verrou ABSENT du dépôt, le champ `"lock": "<chemin absolu du dossier de verrou>"` et pour chaque entrée un champ `location` (`git-common-dir` ou `checkout`) ; pour un verrou présent, `generation`, `session_ids`, `lease_seconds`, `guard_effective`, `progress_epoch` `[VERIFIED: driver-lock.sh:744,765 ; LOCATION= lignes 361,363]`. La liste blanche de la régie est donc un vrai filtre aujourd'hui, pas une formalité.

## Points d'ancrage par exigence

Abréviations : S/ = `plugin/cockpit/scripts/vf-cockpit-`, U/ = `plugin/cockpit/skills/cockpit-moteur/assets/ui/`, C/ = `plugin/conductor/scripts/`, T/ = `plugin/cockpit/scripts/tests/`. Chaque entrée dit : où le code vit, la forme de donnée présente, ce qui manque, le témoin qui rougit sur le code actuel (rouge avant : assertion, attendu, obtenu à consigner).

### REGI-01 : quatre sections, compteurs, sous-titre, état vide
- **Ancrage.** Nouveau rendu dans `U/72-vf-regie-*.js` (fichiers neufs ≤ 300 lignes). Source des données : `window.__vfLive.who` posé par `setWho` (`U/70-vf-live.js:199`, `probe.who = w; probe.whoAt = Date.now()`) ; événement de document `vf-who`. Helpers existants à réutiliser, pas à recopier : `actif` (`U/71:9`), `nommer` (`U/71:72-76`, nom d'une session par titre puis arbre puis identifiant court), `titreEquipe` (`U/71:122-125`), `glyphe` et `GLYPHE_ETAT` (`U/71:46-59`).
- **Forme présente.** `who@2` : `workers[]` avec `kind` ∈ `["session", "subagent", "lock", "registered", "dag-node"]` `[VERIFIED: vf-cockpit-interface.json:38]` ; états `"etats": ["actif", "en-attente", "au-repos", "attend", "termine"]` `[VERIFIED: vf-cockpit-interface.json:31]` ; champs facultatifs `["role", "task", "titre", "parent", "depth", "background", "branch", "treeBy", "cwd", "ageS", "lastAt", "stale", "orphan", "children", "dag", "etat", "dureeS", "finAt", "action", "rattachement", "enCours"]` `[VERIFIED: vf-cockpit-interface.json:30]`.
- **À noter.** `cwd` figure déjà dans `who@2` pour les sessions (`LIBRES … cwd: 200`, `vf-cockpit-who.mjs:161`) : c'est le cwd d'un agent DU LAB ; il ne doit pas être affiché par la régie (aucun chemin d'arbre) et n'a aucun rapport avec `ailleurs()`.
- **Rouge avant.** Sur le code actuel, `section#vf-equipe` n'existe pas : attendu 4 `h2` (« À vous », « Au travail », « Terminé, à relire », « Au repos »), obtenu 0 (l'onglet rend un canevas `#viewport .node .card`).

### REGI-02 : rendu côté page, adaptateur unique
- **Ancrage.** Adaptateur = un seul fichier, une fonction `source()` qui lit `window.VF_ETAT.lire('who')` / `abonner` s'ils existent, sinon `vf-who` + `window.__vfLive` ; le rendu prend `(who, lock)` en arguments purs. `window.VF_ETAT` : absent du code `[VERIFIED: recherche textuelle `VF_ETAT` sous plugin/ : aucun résultat]` (contrat C4 de la 79, non fusionné).
- **Lecture du verrou.** `window.__vfLive.lock` (`U/70:14`, posé par `showLock`, `:189`). Forme brute aujourd'hui, `{seq, at, verrous}` après A15 : l'adaptateur normalise les deux vers la liste blanche (hypothèse A4 pour la fraîcheur).
- **Jeton.** Les requêtes de la page lisent `SRV.token` avec l'en-tête du source `x-floorplan-token` (`U/70:178`, `U/72:187`) ; avec la 79, `VF_ETAT.jeton()` / `lireJson` (A13). La régie ne lit le jeton que dans l'adaptateur.
- **Rouge avant.** Témoin « même entrée, même DOM par les deux sources » : sur le code actuel la fonction de rendu n'existe pas (attendu : deux DOM identiques, obtenu : `window.__vfRegie` indéfini).

### REGI-03 : retrait du canevas, enveloppe `@1` gardée
- **Ancrage.** `S/server.mjs:143-155` (`pageEquipe`, appelle `buildEquipeGraph`) ; `S/equipe-carte.mjs:34-89` (`buildEquipeGraph`), `:20-32` (`missionsEnCours`, à garder) ; `U/72-vf-equipe.js` (193 lignes) : tout sauf ce que la régie reprend (libellé de recherche `:29-33`).
- **Forme présente.** `cockpit-equipe@1` : `"requis": { "schema": "string", "meta": "object", "project": "object", "nodes": "array", "files": "array", "links": "array", "flows": "array" }`, `"interdits": ["doing", "mandat", "messages", "outils", "fil"]`, `"meta": { "requis": ["vfTab", "vf", "kindLabels"] }` `[VERIFIED: vf-cockpit-interface.json:53-60]`. `meta.vf = { compte, fenetre, sources, missions }` (`S/equipe-carte.mjs:85`), `meta.vfGit` (en-tête Git). `compte` est calculé UNE fois à la construction de la page (statique, mémoïsée `memoE`) : la régie recalcule ses effectifs depuis `who`, elle ne lit pas `meta.vf.compte` pour ses compteurs (l'en-tête `76-vf-git-entete.js:35-40` continue, lui, de s'en servir tant que `#context` existe).
- **Mémo de page.** `memoE` est invalidé par `who` (`:150 memoE.who === who`) : sans cartes, la page ne dépend plus de `who` ; supprimer cette clé du mémo (sinon reconstruction inutile de 2,5 Mo à chaque poussée). Le témoin `D3.3` de `test-cockpit-demander-bornes.sh` (« la page Équipe n'est construite qu'une fois ») reste vrai et vérifie justement cela.
- **Rouge avant.** `test-cockpit-equipe.sh E23.4` (cartes présentes) devient « 0 carte » ; nouveau témoin : `nodes.length === 0` et schéma `@1` valide (`validate2.mjs`, E23.5 conservé tel quel), rouge avant : `nodes.length` vaut le nombre d'agents.

### REGI-04 : « À vous »
- **Sessions `attend`.** `S/etat-officiel.mjs:21-34` (`formeEtats`, mappage du contrat `vueAgents`), consommé à `S/equipe.mjs:93-96` (`const off = officiel?.get(id)?.etat …`). Mapping verbatim `[VERIFIED: vf-cockpit-interface.json:110-111]` : `"etats": { "working": "actif", "blocked": "attend", "done": "termine", "failed": "termine", "stopped": "termine" }`, `"statuts": { "busy": "actif", "waiting": "attend", "idle": "au-repos" }`. D2 du lot 0 reste vrai : « vous attend » ne vient QUE de là.
- **Lignes de phase `human_needed`.** `S/avancement.mjs:83` ne lit que la présence : `if (!fs.some((f) => f.endsWith('-VERIFICATION.md'))) r.push('verification');` ; `reste({ph, fichiers, lire, vivante})` reçoit déjà `lire(nom)` (utilisé pour `-RECETTE-HUMAINE.md`, lignes 78-81, avec `**Statut :`). Format réel d'un en-tête : frontmatter YAML, ligne `status: human_needed` en ligne 4 ou 5 (`41.2-VERIFICATION.md`, `60-VERIFICATION.md`, `69-VERIFICATION.md`) ; les valeurs rencontrées : `passed`, `gaps_found`, `human_needed`. Lire l'en-tête seul (borné, premières lignes entre `---` et `---`), refuser tout le reste. Constat C6 (phases cochées) et C2 (transport par `who@2`).
- **Rouge avant.** Une phase non cochée avec `status: human_needed` ne produit rien : attendu 1 ligne de phase, obtenu 0 ; plus le témoin négatif de C6 (phase cochée : 0 ligne).

### REGI-05 : classement par impact
- **DAG disponibles.** `lireDags` (`S/planning.mjs:91-105`, appelé par `gather` à `S/who.mjs:131`), plus les `*.dag.json` du dossier commun des verrous (`S/who.mjs:136-138`) ; nœud = `{id, deps, status, step, stage, …}` (contrat `noeud` : `"requis": ["id", "status", "step", "stage", "deps"]`, `vf-cockpit-interface.json:19`). Aucun champ `ws`/`phase` dans les DAG du scratchpad de session (invisibles du cockpit, FAITS-ÉCLAIREURS).
- **Fermeture inverse.** Fonction pure sur `{id, deps, status}` : aval(n) = nœuds non `done` atteignables en suivant les `deps` en sens inverse, `n` exclu ; protéger contre les cycles (ensemble de visités), contre un `deps` non tableau et contre les identifiants dupliqués (une `Map`, jamais un objet indexé par une valeur du disque, T-69-09 `S/equipe.mjs:122-131`).
- **Rattachement.** Seuls les sous-agents ont un `rattachement` (C2). Pour une session `attend` : détention du verrou (C2) puis « retient toute la mission · N » seulement si le DAG de la mission est visible ; sinon « impact inconnu ». `etat` d'un nœud terminé : `status === 'done'` (vocabulaire de `dag.sh` : `running > failed > done > ready`, `S/avancement.mjs` `etatMission`).
- **Tri.** Trois rangs (connu > 0 décroissant, inconnu, connu = 0), puis `ageS` décroissant (plus ancienne attente d'abord), puis nom, puis identifiant : comparateur total (jamais deux lignes à égalité).
- **Rouge avant.** Jeu d'essai de la spec § 16 point 2 (impact 4, 1, inconnu, 0, égalité départagée par l'ancienneté) : attendu l'ordre 4, 1, inconnu, 0 ; obtenu : fonction absente.

### REGI-06 : tenant du verrou, liste blanche
- **Flux.** `lockStatus()` (`S/live.mjs:63-68`) : `JSON.parse(execFileSync('bash', [dl.chemin, 'status', '--all'], …))` ; émis tel quel (`:150 emit('lock', { seq, at, lock })`) et dans `hello` (`S/server.mjs:87-89`). Forme brute (C14). Précédent de liste blanche côté serveur : `garde` de `S/vie.mjs:33` (`{ ws, scope, phase, tenu, stale, ageS, ttl, progressAgeS, owner }`, `chaine`/`num`/`bool` typés).
- **Page.** Lecteurs actuels du flux brut : `lockText`, `verrouDe`, `detenteur`, `sansSession`, `driverLigne` (`U/70:53-93`), dont certains lisent `session_ids` et `lease_seconds`. La régie ne s'appuie sur aucun d'eux : sa liste blanche est un module à elle (`champ par champ`, types vérifiés, `owner` borné à 80 et sans caractère de contrôle, rendu en `textContent`).
- **Mission ↔ verrou.** Cascade de `vieDe` (`S/vie.mjs:58-72`) : verrou de phase (même périmé), puis compartiment, puis dépôt ; une ligne de mission est tenue si `estVivante` ou verrou présent ; règles P68-D-05, D-22, D-23, D-26, D-27 réutilisées telles quelles.
- **Rouge avant.** Sentinelles (identifiant de session, chemin du dossier de verrou, nom de lab voisin, jamais un vrai nom) injectées dans un événement `lock` : sur le code actuel `window.__vfLive.lock` les contient (attendu : absentes du DOM, du stockage, de l'export ; obtenu pour l'objet brut : présentes) ; le témoin positif d'abord : la ligne de mission s'affiche pour le verrou injecté.

### REGI-07 : alerte du watchdog
- **Source unique.** `C/check-guard-health.sh:127` : `STALL_WINDOW="${VF_STALL_WINDOW:-900}"` `[VERIFIED: ligne 127]`. La ligne 135 (`    --stall-window=*) STALL_WINDOW="${arg#*=}" ;;`, indentée) et le commentaire ligne 27 contiennent aussi `STALL_WINDOW` : l'extraction doit s'ancrer sur le début de ligne, la forme entière et un entier seul, sinon un mutant inoffensif passe. Validation du script (`case … ''|*[!0-9]*) … exit 64`, ligne 143) : l'extraction accepte des chiffres seuls, strictement positifs ; tout autre cas = fenêtre INCONNUE (rien marqué, pas de « suspect », P73-D-31).
- **Localisation.** `driverLockScript` (`S/paths.mjs:72-87`) trouve `driver-lock.sh` par le dossier du module, puis le `conductor` voisin, puis `~/.claude/scripts` ; `check-guard-health.sh` est son voisin dans `conductor/scripts` : réutiliser le même dossier et les mêmes interdits (jamais un fichier pris dans l'arbre observé, T-67-06). Absent (module conductor non installé) = inconnue.
- **`VF_STALL_WINDOW`.** Variable de l'environnement du SERVEUR du cockpit ; le watchdog tourne dans un autre processus (la session) : les deux peuvent diverger, d'où le libellé conditionnel (D-09). Transport : champ facultatif de premier niveau de `who@2` (`fenetreStallS`, entier ou `null`) : hors de la liste blanche A15 de la 79, donc le seul canal propre (hypothèse A6).
- **Rouge avant (mutant de la ligne source).** Copier `check-guard-health.sh` dans un dossier de scripts jetable, changer le défaut 900 en 600 : la fenêtre servie vaut 600 (si le code lit la ligne) ; si le code a 900 en dur le test voit 900 et rougit. Retirer la ligne : fenêtre `null` et aucune marque.
- **Ne pas modifier `check-guard-health.sh`** (classe 1 de la surface Gate-Touche, voir « Gates de dépôt »).

### REGI-08 : arbres de travail
- **Routes.** `GET /api/vf/git` (`S/git.mjs:192` : `worktrees: worktrees.map((w, i) => ({ nom: net(path.basename(w.chemin)), chemin: net(w.chemin), branche: …, detache, ici, principal, verifie, …` ) ; `GET /api/vf/git/worktrees` (`:215`, `etatWorktrees`, asynchrone) ; schéma `cockpit-git-worktrees@1` `"worktree": { "requis": ["chemin", "nom", "verifie", "modifies", "nonSuivis", "plus", "propre", "avance", "retard", "avanceOrigin", "retardOrigin", "commande"] }` `[VERIFIED: vf-cockpit-interface.json:81]`. Un worktree non vérifié : `verifie === false`, comptes à `null` : la régie dit « non vérifié », jamais « propre » (P78-D-38).
- **Déclencheurs.** Ouverture du `details` + événement de document `vf-git:signal` (C10). Pas de minuterie. La commande `commande` (`cd …`) ne doit PAS entrer dans la régie (« Aucune commande à copier ici »).
- **Rouge avant.** Fixture à deux worktrees dont un non vérifié (lien `gitdir` forgé, déjà outillé par les suites Git) : attendu 2 lignes dont une « non vérifié » ; obtenu : bloc absent.

### REGI-09 : vivacité, orphelin, glyphes
- **Constantes.** `export const SILENCE_MAX_S = 1800;` (`S/equipe-etat.mjs:7`) ; `const CALME_S = 120;` et `const LONGUE_S = 900;` (`U/71:61,63`) ; `const SILENCE_PARENT_S = 1800;` (`U/71:78`). `LONGUE_S` (commande longue, Q13) et la fenêtre de stall valent 900 par coïncidence : ne pas les unifier (deux sources, deux sens ; un mutant « LONGUE_S := fenêtre de stall » doit rougir sur la spec : commande en cours 15 min reste « au travail »).
- **Orphelin.** Collecte : `for (const w of workers) if (w.kind === 'subagent' && w.etat !== 'termine' && etatDe.get(w.parent) === 'termine') w.orphan = true;` `[VERIFIED: vf-cockpit-equipe.mjs:117]`. Page : la formule `orphe` (`U/71:91`) ajoute la règle « parent muet > 30 min » du tiroir ; D-13 dit « le garde du lot 0 est réutilisé » : l'exporter depuis `71`, pas de copie (ligne 230).
- **Décroissance.** Page seulement (C4), avec `ageDe` (`U/71:16-17`) et la fenêtre reçue ; fenêtre inconnue → l'état s'arrête à « silencieux » (D-31). « Suspect » n'existe qu'en dessous de 1 800 s (`SILENCE_MAX_S`), car au-delà la collecte retire l'agent non fini (`S/equipe.mjs:78` : `if (etat === 'en-attente' && c.sAge >= SILENCE_MAX_S) continue;`).
- **Glyphes** : table `GLYPHE` inchangée (`actif, attente, termine, bloque, orphelin, repos, attend, repli, surveiller, commande`, `U/71:46-57`) ; `--st-recette` non utilisée (D-19).
- **Rouge avant.** Fixture « actif, 4 min sans écriture » : attendu mot « silencieux depuis 4 min » ; obtenu : `calme()` ne produit que le libellé du tiroir (« sans nouvelle depuis ») et aucun état « silencieux » ; plus le cas à deux onglets du constat C4.

### REGI-10 : « attend ses agents (N) »
- **Source.** Dernière ligne `system` / `turn_duration` d'un transcript de SESSION, champ `pendingBackgroundAgentCount`, absent quand 0 (`A1-donnees-agents-sessions.md:62`, « Fiable, sessions seules » ; aucun fichier du dépôt ne lit encore ce champ : recherche `pendingBackgroundAgentCount` hors `.planning/` = 0 résultat). Sous-agents : jamais.
- **Lecteur.** `cherche(f, accepte, fenetres, etat)` (`S/lecture.mjs:20-34`) : remonte depuis la fin sur 256 Kio puis 2 puis 8 Mio, `accepte` rend la première valeur non nulle. « Cette ligne est la dernière écriture » = le prédicat doit décider sur la PREMIÈRE ligne analysable en partant de la fin (rendre `{n: null}` dès qu'une autre ligne passe en premier), jamais continuer vers une ancienne `turn_duration` (même technique que `outilEnCours`, `S/equipe-etat.mjs:13-30`).
- **Contrat.** Ajouter `attendAgents` (entier ≥ 1) aux `optionnels` du travailleur (`vf-cockpit-interface.json:30`) : le témoin `W23.14` (« toute clé d'un travailleur est déclarée ») rougit sinon. Borne : entier fini, plafonné (ex. 999) ; non fini = absent. `state` `actif` ou écrit depuis : pas d'état « attend ses agents ».
- **Rouge avant.** Fixture : session dont la dernière ligne est `system`/`turn_duration` avec `pendingBackgroundAgentCount: 3` : attendu `attendAgents === 3`, obtenu champ absent ; fixture miroir : une écriture plus récente après la ligne → absent.

### REGI-11 : « Terminé, à relire », « lu », titre de l'onglet
- **Rapport.** `GET /api/vf/transcript?id=` (`S/server.mjs:104-110`, `revealTranscript`), schéma `cockpit-transcript@2` (`"optionnels": ["mandat", "fil", "tronque", "erreur"]`) ; rendu en texte seulement par `transcript(d, doc)` (`U/71:152-170`) ; l'ouverture actuelle (`U/72:179-192`) est le patron (aria-disabled, jamais `disabled`).
- **« Lu ».** Aucun stockage « lu » n'existe. `localStorage` : une clé par lab. Étiquette de lab disponible : `GET /api/vf/modeles` renvoie `lab` = sha256 tronqué à 12 caractères de la racine réelle (`S/server.mjs:111-115`). Le port d'un lab est stable (`S/port.mjs`, base 4378 + empreinte), donc `localStorage` (par origine) survit aux relances ; deux labs au même port de repli partageraient l'origine, d'où la clé par lab. Contenu : identifiants et heure uniquement, ≤ 200 entrées, purge > 24 h au chargement, tolérant (valeurs lues revalidées : forme, `ID_RE`, nombre fini ; un objet inattendu est jeté, jamais évalué).
- **Titre.** Quatre écrivains (voir REGI-12). Fonction unique `composerTitre()` ; le motif des mots avant le reste est testé sur le `document.title` final.
- **Rouge avant.** Titre : `(2) vous attendent` n'apparaît nulle part ; après un événement `git` ou la traduction le préfixe disparaît (attendu : survit, obtenu : réécrit par `76:19` et `80:147`).

### REGI-12 : compositeur de titre et favicon
- **Les quatre écrivains.** `viewer.html:2375` (`document.title = \`${G.project.name} map\`;`, moteur, ne se modifie pas), `U/00-vibeflow.js:13`, `U/76-vf-git-entete.js:19` (`const m = /^(Code|Projet|Équipe) · /.exec(document.title); if (m) document.title = m[0] + nom.textContent;`), `U/80-vf-fr.js:147` (observateur de `<title>`) et `:159` (réécriture unique). La spec dit « trois » : il y en a quatre côté extensions et un cinquième côté moteur qui s'exécute avant (P31 : les `ui/*.js` attendent `DOMContentLoaded`). Le compositeur ne peut pas empêcher l'écrasement initial du moteur ; il doit se placer en observateur du `<title>` (comme `80`) et réécrire en dernier, avec une garde de non-récursion.
- **Réécritures concernées** : `00:13` et `76:19` sont des lignes existantes à convertir en appel du compositeur (deux modifications de lignes dans deux fichiers à plafond, sans ligne neuve) ; `80:147,159` : le compositeur doit être appelé APRÈS la traduction (la traduction ne doit pas défaire le préfixe : `tr` découpe sur ` · ` et traduit chaque segment, `80-vf-fr.js` `noyau`).
- **Favicon.** Lien existant `<link rel="icon" type="image/svg+xml" href="__FLOORPLAN_FAVICON__">` (`viewer.html:30`) ; CSP verbatim `[VERIFIED: serve.mjs:514 « img-src 'self' data: »]` : une URL `data:` passe. Remise à zéro : restaurer la valeur d'origine lue au chargement.

### REGI-13 : « ailleurs sur ce poste »
- **Données.** `rafraichir` (`S/etat-officiel.mjs:41-57`) exécute `claude agents --json` (`execFile` sans shell, `timeout: DELAI_MS`, `HOME` fixé, PATH assaini) et rend `formeEtats(j)` : une `Map` `sessionId → { etat }` qui JETTE `cwd`. Forme d'une entrée vue par les suites `{ sessionId, kind: 'interactive', pid: 1, cwd: lab, state/status }` `[VERIFIED: T/test-cockpit-equipe-etats.sh:225]`. Documentation publique incomplète : la commande accepte `--cwd <path>` (filtre) et `--all`, et les champs `id, sessionId, name, cwd, kind, startedAt, state, status` sont décrits par des tiers (`claudeissues.com`, `claude-wrapper` hexdocs) tandis que la doc officielle ne documente pas la sortie JSON : `[CITED: claudeissues.com/issue/66384-… et /60685-…]`, MEDIUM. Que la liste couvre TOUT le poste sans `--cwd` est une déduction (le code n'ajoute pas `--cwd`) : `[ASSUMED]` jusqu'à une sonde réelle (Wave 0, hors de cette phase).
- **Ajout.** Une fonction exportée en FIN de fichier (D-16, A18) ; mais elle a besoin du JSON brut : une ligne de `rafraichir` doit mémoriser, dans le cache privé du module, la liste `[{cwd, etat}]` restreinte aux sessions `attend` ET le `cwd` jamais exporté (point de conflit avec le plan « collecte » de la 79 sur A20 : même fonction ; résoudre à la jointure). `formeEtats` n'est pas touché.
- **Hors des arbres du lab.** Liste d'arbres : `arbresGit(root)` (`S/arbres.mjs:25-39`, vérifie le lien retour des worktrees, P78-D-38) ; comparaison sur `realpath` (même règle que `inScope` de `S/who.mjs:66`). Le dossier personnel, un de ses ancêtres, un chemin trop court → « un autre dossier » (hypothèse A7 : « trop court » = moins de deux segments significatifs ; à fixer par un témoin). Nom du lab : dernier segment après retrait de `/.claude/worktrees/<n>`, nettoyé par `nettoie` (`S/arbres.mjs:68`, classe Cf et masque) et borné à 40.
- **Route.** Ajout d'un bloc dans la chaîne `route()` de `S/server.mjs:80-119` (la table de la 79 n'existe pas : A10 à revalider) ; passer par `porteInterdit` (`:35`) et `json()` (`:78`). Lecture seule du cache (jamais de lancement de commande par requête : un `claude agents` par requête serait un déni de service local). `Cache-Control: no-store` déjà posé par `json()`.
- **Rouge avant.** Fixture de HOME avec une session `attend` dans un dossier hors du lab : attendu `[{ lab: <nom>, n: 1 }]` sur la route, obtenu 404. Mutants et sentinelles : section « Validation Architecture ».

### REGI-14 : un seul style de bouton, nom une fois, santé
- **Styles recensés.** (1) `.btn` doux du viewer (`SC.addHeaderButton`), (2) `.sec button[data-vf-doing], .sec button[data-vf-transcript]` (`U/70:32-33`, à retirer avec le panneau), (3) `a.vf-link`, (4) `.r-doing`, `.r-tog` (icônes du tiroir, catégorie distincte documentée). Les liens ne sont pas des boutons (spec § 7).
- **Nom une fois.** Le nom d'un agent s'écrit trois fois aujourd'hui (`title` de la ligne `U/71:104`, description, titre du panneau) : sur la régie, un seul élément porte le nom ; `aria-labelledby` pour les boutons (spec § 3).
- **Santé.** Constat C6bis.

### REGI-15 : accroches de la Phase 74
- **Ancres.** `arriver` (`U/00:282-286`) : `if (SC.exists(id)) SC.reveal(id); else SC.toast(\`Pas sur cette carte : ${r}\`);` : avec `nodes` vide, toute ancre `#r=n:…` finit en toast « Pas sur cette carte » ; la garde `TAB==='equipe'` se pose sur la ligne 286 existante et délègue à la régie (défilement + focus). `72:100-110` (`arrivee`) disparaît avec le canevas ; ses témoins `EUI2.14-16` sont à re-pointer sur la régie (arrivée sur `#r=n:ag-A` : la ligne est révélée une fois).
- **Registre.** `window.__vfEquipeVues.declarer({id, libelle, monter(el), demonter()})` posé par la régie avant `74-` ; bascule dessinée seulement quand deux vues sont déclarées ; événements `vf-agent:ouvrir` (annulable, repli sur le lecteur) et `vf-agent:lu` ; attributs `data-vf-agent`, `data-vf-noeud`, `data-vf-etat` (valeurs de `GLYPHE_ETAT`). Table de glyphes unique exposée (P74-D-29).
- **Rouge avant.** Témoin d'accroche : déclarer une vue factice appelle `monter` une fois et dessine la bascule ; sans seconde vue, aucun bouton (jamais de bouton mort).

### REGI-16 : non-régression
- Voir « Inventaire des témoins ». Compteur : `scripts/check-version-sync.sh:134` calcule `find "$ROOT/plugin" "$ROOT/scripts" -path '*/tests/test-*.sh' | grep -c .` (vérifié : 213 aujourd'hui) et compare à « N suites » de `README.md:65` et `README.fr.md:67` ; une suite neuve = 214 dans les deux (recomptage au rebase final, car 74, 79 et 80 le touchent). Nettoyage de la branche à l'émission : `who.mjs` (`bornes` + `retireAffichage`) ; export d'Équipe : la régie est construite en JS dans la page, jamais dans le graphe, donc rien à retirer de l'export si aucun champ n'est écrit dans `SC.graph` (témoin : l'export de la page Équipe ne contient aucun marqueur de régie).

## Inventaire des témoins existants (ce qui rougit quand le canevas d'Équipe part)

Méthode : recherche textuelle de `equipe.html`, `buildEquipeGraph`, `equipe-carte`, `72-vf-equipe`, `~termines`, `data-vf-doing`, `Voir la dernière commande`, `Lire le transcript`, `#r=n:` sous `T/`, puis lecture de chaque suite concernée. P73-D-04 en liste six ; il y en a davantage. Règle de P73-D-04 : mettre en conformité, jamais supprimer pour verdir ; une mise en conformité dit dans l'en-tête de la suite quelle propriété suit quel support. Les cases « Dans D-04 ? » signalent les oublis.

### Suites à re-pointer (le support disparaît)
| Suite (T/) | Identifiants touchés | Ce qui les fait rougir | Dans D-04 ? | Re-pointage proposé (même propriété, nouveau support) |
|---|---|---|---|---|
| `test-cockpit-equipe.sh` | E23.4 (cartes : arbre, terminés sous un bloc, `st`) | `nodes` vide | oui | E23.4 devient « 0 carte, `meta` conservée » ; arbre session → manager → worker testé sur le DOM de la régie (VM) |
| idem | EUI2.8, EUI2.9, EUI2.23, EUI2.24 (panneau d'un agent piégé, mutants pied et nœud bruts) | `V72` joue `72-vf-equipe.js` (`SC.addPanelSection('item')`) | non (D-04 cite EUI2.10-16) | mêmes entrées piégées jouées sur la ligne de régie ; mutants « pied brut », « nœud brut » repris sur le nouveau fichier de rendu |
| idem | EUI2.10-EUI2.13, EUI2.25, EUI2.26 (0 rechargement, borne de 15 s, signature des terminés) | le rechargement de page n'existe plus | oui | propriété inverse : « changement de l'ensemble des agents = 0 rechargement, 1 redessin en place, focus conservé » ; les mutants de signature deviennent des mutants de clé de ligne (`section + id`, D-29) |
| idem | EUI2.14-EUI2.16 (arrivée sur `#r=n:ag-A`, révélée une fois) | `SC.reveal` sans carte | oui | ancre traitée par la régie : défilement + focus sur la ligne, une fois ; `ready` déjà émis : pas de seconde révélation |
| idem | EUI2.18c (effectifs « actifs » de l'onglet = badge) | `V72 … compte` | non | effectif lu dans le sous-titre de la régie (agents distincts en vie) ; le badge (`vm70`) est inchangé |
| idem | EK1, EK1.1, EK2.x, EK3.x, EK5.x, EK8 (`focus-puis-who`), EK8.x | boutons du panneau (`#panel [data-vf-transcript]`), clé `vf-equipe-ouvert`, `[data-vf-doing]` | partiel (EK10/13/14/17 cités) | focus conservé sur « Lire le rapport » et sur la ligne après un `who` ; la clé `vf-equipe-ouvert` (sessionStorage) disparaît (témoin : plus aucune clé écrite) ; commande en texte brut : plus de bouton « Voir la dernière commande » sur Équipe (P67-D-14) : témoin négatif |
| idem | EK10, EK13, EK14, EK17 | badge dans la carte, échelle du canevas, titre qui grandit, frappe qui ne déclenche pas le canevas | oui | EK10 : pastille d'état dans la ligne à 390/1024/1440 px ; EK13/EK14 : titre de la régie ne recouvre pas la première section ; EK17 : sans canevas la frappe `f`, `p`, `+` n'agit sur rien (témoin positif sur Projet et Code conservé) |
| idem | EK12 (libellé « Chercher un agent ou une session ») | posé par `72:29-33` | non | libellé posé par le fichier de la régie, même texte |
| idem | EK18 (titre `#context h1` arrêt de Tab sous le tiroir Git) | lit `#context` | non | même propriété sur `#vf-equipe-entete h1` |
| `chrome-moteur-carte.mjs` + `test-cockpit-moteur-carte.sh` | K13.1-K13.3 (« une seule colonne de cartes », `j.equipe.cartes >= 3`) | `#viewport .node .card` vide | oui | « une colonne de lignes à 390 px, aucune ne déborde » (mesure des lignes de la régie) |
| `test-cockpit-who.sh` | W23.1-W23.11 (titre, détail « Identifiant : », branche nettoyée via `buildEquipeGraph`) ; mutants `M-W23-BRANCHE`, `M-W23-BRANCHE-DETAIL` (ancres dans `vf-cockpit-equipe-carte.mjs`) | l'ancre disparaît : `mutsub.mjs` rend « ancre absente » et le test attendu rouge devient faux | oui (613-681) | propriétés lues sur `who@2` (`titre`, `branch`, déjà nettoyés à l'émission, D-22) et sur le rendu VM de la ligne ; mutants re-ancrés dans `who.mjs` ; W23.14 inchangé (étendu aux clés neuves) |
| `test-cockpit-equipe-etats.sh` | M3.6, M3.7 (titre et ligne d'agents via `buildEquipeGraph`/`meta.vf.compte`) ; M3.8 (règle CSS Santé) ; D2c (panneau suit l'état à chaque poussée) ; D3b (minuterie de `72`) | D2c et D3b jouent `72-vf-equipe.js` | oui (M3.6, M3.8, D2c) ; D3b non | M3.6/M3.7 restent valides tant que `meta.vf.compte` est gardé (D-03) ; M3.8 inchangé si hypothèse A2 ; D2c : la ligne dit le même état que la section à chaque poussée ; D3b : minuterie de 30 s de la régie (0 dessin si le texte est identique) |
| `test-cockpit-lecture-fil.sh` | l. 147 : D8.9 « les quatre schémas (equipe, git, signal, who) qui interdisent messages et outils interdisent aussi fil » | rien tant que `cockpit-equipe@1` garde ses `interdits` (c'est une des raisons de D-03) | oui | aucun changement ; le garder vert prouve que le schéma est resté |
| `test-cockpit-lancer-suivi.sh` | LE.0, LE.0b, LE.0c, LE.1-LE.6, `mut_le` `M-LANCEES-HORS-SESSION`, `M-LIGNE-SANS-VALIDATION`, `M-LIGNE-VIDE-TOUJOURS` | `buildEquipeGraph` perd `lancees` et les marqueurs `garde:lancees`, `garde:ligne-valide`, `garde:ligne-insert` | oui | voir « LE → LR » ci-dessous |

### Suites qui lisent la page Équipe sans dépendre de ses cartes, mais qui doivent être revérifiées
| Suite | Identifiants | Risque |
|---|---|---|
| `test-cockpit-responsive.sh` | R13.1, R13.2, R13.4 (en-tête, trois onglets) ; R14.1-R14.3 (zoom en pile à 390 px, **boucle `for onglet in index project equipe`**) ; R17.0-R17.2, R17.1b, R18, R19.1-R19.2, R20 | Absents de D-04. R17.0 (`nCartes>=1`), R17.1/R17.1b (zoom en rangée, P70-D-20), R19 (titre vs première carte) sont « devenus sans objet » selon le CONTEXT : il faut les re-pointer (R17 : « aucun zoom de canevas sur Équipe », témoin négatif ; R19 : `#vf-equipe-entete` ne recouvre pas la première section ; R20 : matrice 390/768/1024/1440 sur les surfaces de la régie) et NON les supprimer. R14.1-R14.3 : si le zoom est masqué sur Équipe, la boucle doit retirer `equipe` avec une raison écrite |
| `test-cockpit-projet-visite.sh` | O6.14, O6.14a, O6.14b (« l'onglet Équipe a au moins deux cartes », `e768.cartes>=2`) | O6.14a rougit : « cartes » doit devenir « lignes de régie » ; la propriété de fond (aucune visite d'office sur Équipe) est conservée |
| `test-cockpit-git-entete.sh` | H6.2 (3 cas : « Aucune mission en cours / L'équipe est au repos. », « Mission : x », « 2 missions en cours », et la ligne « Agents : 0 actif · … ») ; H2.2, H7.x (suffixe, nom du dépôt) | H6.2 lit `#context h1/.k/p` : à re-pointer sur `#vf-equipe-entete` (la spec garde le gabarit de titre du lot 0) |
| `test-cockpit-transcript.sh` | T26.8 (arriver sur `equipe.html#r=n:ag-ximg` sélectionne la carte), T27.B2, T27.C1, T27.C2 (transcript et commande restent affichés après 4 `who`, redemandés après rechargement), T27.F1 (badge = actifs de l'onglet) | cartes et panneau ; C1/C2 deviennent « lecture du rapport conservée après des `who`, jamais gardée dans un stockage » ; la clé `sessionStorage` de `72` disparaît |
| `chrome-accessibilite.mjs` / `test-cockpit-accessibilite.sh` | X4.0-X4.2b (parcours Tab, anneau unique sur les trois pages), X4.4 (`aria-current`), X4.5 (« un seul `<main>` par page », `main.length`), X7.3-X7.5 (titre `Équipe · <nom>`) | X4.5 compte l'ÉLÉMENT `<main>` : la régie en ajoute une région `role=main` ; sans changement de la sonde, le test reste vert à vide. Compter `main, [role=main]` visibles. X7.3 : le titre avec préfixe `(N) vous attendent · ` change la forme ; à zéro attente le format `Équipe · <nom>` est conservé (lot 0 X7) |
| `test-cockpit-demander-bornes.sh` D3.3, `test-cockpit-serveur.sh` EQ.0-EQ.3, `test-cockpit-securite.sh` H4bis, `test-cockpit-reseau.sh` R1.4-R1.5, `chrome-flux-unique.mjs`, `test-cockpit-git-e2e.sh` | pages servies, garde d'émission, CSP identique à v2.75.0, 0 connexion sortante, un seul flux | Doivent rester verts sans changement. EQ.1 (« un who propre donne la page Équipe ») et EQ.3 (« contrat illisible : aucune donnée d'équipe ») exigent que `pageEquipe` garde `porteInterdit(who)` même sans cartes (fermé par défaut) |
| `test-cockpit-git-commandes.sh` | R4.1 (parité de la classe d'affichage sur QUATRE copies, dont `vf-cockpit-equipe-carte.mjs`), `M-CLASSE-EQUIPE` | Si `missionsEnCours` reste dans `equipe-carte.mjs` (D-23), la copie y reste : rien à faire. Si un plan la déplace, la parité passe à trois copies et le témoin doit le dire |
| `test-cockpit-chrome-fr.sh`, `test-cockpit-fr-donnees.sh`, `chrome-fr-*.mjs` | F2, F4 (inventaire anglais, exclusions), D1-D5 de `fr-donnees` (données du lab non traduites) | À étendre aux libellés et aux lignes de la régie (spec § 14) ; les fichiers neufs portent `// VibeFlow (` (C13) |
| `test-cockpit-vendor.sh` | V4 (≤ 300 lignes des AJOUT `.js`), V6.1 (`synchro.sh verifier`), V7 (chaque AJOUT existe) | Chaque fichier `ui/` neuf prend sa ligne `AJOUT` (C13) |
| `test-cockpit-direct.sh`, `test-cockpit-signal.sh`, `test-cockpit-signal-mod.sh` | forme du flux, `signal.equipe` = `who@2` | `who@2` s'enrichit de champs facultatifs : valider contre `vf-cockpit-interface.json` mis à jour ; `S2.2` valide `equipe` |

### LE → LR (P73-D-04, D-21)
La copie figée de `vf-cockpit-equipe-carte.mjs` et son SHA256 `7679d717…` (`test-cockpit-lancer-suivi.sh:30-41`) ne sont ni re-figés ni supprimés. Constat : LE.0b affirme que la copie « ne diffère du module courant que par l'import 72-07 et les trois lignes `garde:` » ; dès que le module est réduit à la coquille et aux missions (D-23), cette comparaison est FAUSSE par construction, et LE.1 (« sept jeux `who` × neuf valeurs de paramètre : sortie identique octet pour octet à la copie figée ») aussi, puisque la sortie n'a plus de cartes. Ce ne sont pas des suppressions : c'est une propriété qui change de support. Proposition (hypothèse A8, à confirmer dans le plan de la vague 3) : (1) la copie figée et LE.0 (le SHA de la copie) restent dans l'en-tête de la suite comme document de provenance avec leur raison ; (2) LR.1 : `collectWho` appelé sans option `lancees` rend un `who` identique octet pour octet à celui d'avant (jeu de fixtures `who` fixe, valeur saine capturée AVANT le code, tracée) ; (3) LR.2-LR.4 : une `Map` valide ajoute `lancee: { phase, ws, verbe }` à la session visée, UNIQUEMENT à une session, et la ligne de régie dit « Lancée depuis la carte : Phase N · ws · verbe » (formes LE.2/LE.3) ; (4) LR.5 : valeurs hostiles → aucun champ, aucune exception ; (5) mutants re-ancrés sur de nouveaux marqueurs `// garde:lancee`, `// garde:lancee-valide`, `// garde:lancee-session` dans `who.mjs` (la garde est `entreeLanceeValide`, `vf-cockpit-lancer-suivi.mjs:23-27`, qui n'importe rien : `who.mjs` peut l'importer sans cycle). La correspondance LE → LR s'écrit dans l'en-tête de la suite ET au CHANGELOG (§ Non publié). Câblage manquant à prévoir : `lancer.lancees()` n'est lisible que dans `S/server.mjs` (`creerLancer`, ligne 51) ; il faut le passer à `startLive` puis à `collectWho` (option `lancees`) ; sans cela `lancee` ne sort jamais.

### Harnais disponibles et leur portée
- **VM Node** : `vm-rendu.mjs`, `vm72.mjs`, `vm70.mjs`, `juge71.mjs`, `libelles71.mjs` sont des heredocs écrits PAR `test-cockpit-equipe.sh` (`$AUX`), pas des fichiers partagés : une suite neuve ne peut pas les appeler. Wave 0 : extraire/recréer un harnais VM de la régie sous `tests/` (`vm-regie.mjs`, ≤ 300 lignes, document et fenêtre factices). Même contrainte pour `chrome-equipe-clavier.mjs` (292 lignes : toute extension doit RETIRER des lignes, la jauge est 300).
- **Chrome headless** : `chrome-session.mjs` (`executer`, `attendre`, `ev`, `stable`, `stabiliser`, `attendreValeur`, `attendreEtStabiliser`, `positionPosee`) et `chrome-cdp.mjs`. Patron d'injection d'événements dans la vraie page : `Page.addScriptToEvaluateOnNewDocument` enveloppant `EventSource` avec `__emit(nom, donnees)` (`chrome-verrou.mjs`, `chrome-verrou-prefixe.mjs`) : c'est le moyen de livrer `who`, `lock`, `git` sentinelles à la régie réelle, sans serveur factice.
- **Serveur réel de test** : lancement par `<sortie>/serve.mjs --no-open --port <libre>` (patron `ek_demarrer`, `test-cockpit-equipe.sh:884-888`) ; l'aide `socle-serveur.sh` de la 79 (A6) n'existe pas : « à revalider », repli sur ce patron.
- **Faux `claude`** : `T/temoins/fauxbin-claude` et la variable `VF_FAKE_SORTIE` (`test-cockpit-equipe-etats.sh`, D2b) : un `claude agents --json` factice dont la sortie est un fichier ; à réutiliser pour `ailleurs()` (entrées `{ sessionId, kind, pid, cwd, state/status }`).
- **Mutants** : `mutsub.mjs` (`FROM`/`TO`, « ancre absente » si absent : un mutant dont l'ancre disparaît doit FAIRE ROUGIR la suite, jamais passer en silence), `ek-sub.mjs` (ancre unique, « ancre ambiguë » si deux occurrences).

## Écarts entre les contrats de la Phase 79 et le code présent (« à revalider »)

Lecture : `git show origin/feat/phase-79-socle-cockpit:…/79-CONTEXT.md` (tête `6f66d878`, trois commits `3119d82a`, `2ae6607a`, `6f66d878`), rien n'est fusionné. Vérifié sur le code de la tête e34fe859 : aucun de ces éléments n'existe.

| Contrat 79 | Ce que la 73 voudrait lire | Présent dans le code ? | Repli sur la forme présente | Plans concernés |
|---|---|---|---|---|
| C4 `window.VF_ETAT` (`lire`, `abonner`, clés `etat`, `who`, `frise`, `git`, `connexion`) | source de `who` et `lock` | non (recherche vide) | événement `vf-who` + `window.__vfLive` (`U/70:14,199`) ; `lock` relu sur minuterie (C9) | adaptateur (vague 2) |
| A15 flux `lock` projeté `{seq, at, verrous}` | liste blanche déjà construite côté serveur | non : `emit('lock', { seq, at, lock })` brut (`S/live.mjs:150`) | liste blanche de la page sur la forme brute (`age_seconds`, `progress_age_seconds`, `children_running`) | verrou (vagues 1-2) |
| A15 champ `dag` d'une entrée de verrou ; A16 résumé de plan publié par `driver-lock.sh` (plan 79-03) | DAG d'une mission en cours, pour l'impact | non : `driver-lock.sh` ne publie rien (les champs de `json_status`, ligne 765, ne contiennent pas de plan) | DAG déjà découverts (`lireDags`, `*.dag.json` du dossier commun) ; sans plan visible : « impact inconnu » | impact (vague 1) |
| A20 `sortisSilence` (entier de premier niveau) et `finMotif` (`echec` \| `arret` \| null) | pied « N muets depuis plus de 30 min, retirés » ; mot « échec »/« arrêté » | non : `S/equipe.mjs:78` écarte les muets sans les compter ; `formeEtats` mappe `failed` et `stopped` sur `termine` sans motif (`S/etat-officiel.mjs:26-28`) | rien n'est dit (champ absent) ; jamais deviné depuis le transcript | rendu (vague 2) |
| A10 table de routes + A11 réponse gardée commune | `GET /api/vf/ailleurs` en une ligne de table | non : chaîne de `if` dans `route()` (`S/server.mjs:80-119`) | bloc dans la chaîne actuelle, via `porteInterdit` et `json()` ; ordre alphabétique à rétablir à la jointure | route `ailleurs` (vague 1) |
| A13 `VF_ETAT.jeton()` / `lireJson` | lecture authentifiée côté page | non : `SRV.token` + en-tête `x-floorplan-token` (renommé à l'assemblage) | lecture directe isolée dans l'adaptateur | adaptateur |
| A6 `tests/socle-serveur.sh` | lancement des suites | non (aucun fichier de ce nom) | patron `ek_demarrer` | suite neuve |
| C0 en-tête de jeton `x-vf-cockpit-token` | requêtes de la page | à la sortie assemblée seulement ; le source dit `x-floorplan-token` (C12) | écrire les noms du source | tous les fichiers `ui/` neufs |
| C5 coquille statique + `GET /api/vf/graphe?onglet=equipe` | enveloppe d'Équipe | non : `pageEquipe` construit la page (`S/server.mjs:143-155`) | « avant la coquille » : l'enveloppe sort de `pageEquipe` ; « après » : de la route `graphe` ; même constructeur `buildEquipeGraph`, même schéma `@1` | coquille d'Équipe (vague 3) |
| A17 `whoSig` sur l'objet entier moins une liste de champs volatils | champs ajoutés couverts | non : `whoSig` énumère 11 champs (`S/live.mjs:51`) | étendre la ligne 51 (C5) | gouvernance (vague 1) |
| A18 : la 79 ne touche `etat-officiel.mjs` qu'au plan de la collecte (3e vague) | `ailleurs()` en fin de fichier | sans objet ici | une ligne de `rafraichir` doit aussi mémoriser les `cwd` : conflit probable avec A20 sur la même fonction, résolution à la jointure | ailleurs (vague 1) |
| C6 retrait de `plugin/cockpit/amont/` en première vague | pas de diff de patch à régénérer | non : `amont/` présent, `synchro.sh verifier` joue | aucun fichier du moteur n'est modifié (D-24) : neutre dans les deux ordres ; chaque `ui/` neuf prend `AJOUT` | vendorisation |
| C4 événements ajoutés `etat`, `vie`, `frise` | (aucune lecture prévue) | non | sans objet pour la régie | — |

Contradiction interne de la 79 à signaler au plan 79 : A15 exclut `lease_seconds` alors que l'interface de la 73 veut « depuis N » (C3). Non résolue ici : le repli retenu est l'âge du dernier battement sous un autre libellé (hypothèse A3).

Chaque plan de la 73 qui lit l'un de ces contrats dit, dans sa section « Coquille et Phase 79 », (a) s'il se pose AVANT ou APRÈS la coquille C5, et (b) ce qui change dans l'autre cas (P73-D-23). Pour la vague 3 : « avant la coquille », `pageEquipe` ne construit plus que l'enveloppe sans cartes (retrait de la dépendance à `who` dans le mémo) ; « après », le même constructeur est appelé par la route `graphe` (étiquette `ETag` = signature de l'enveloppe) et `pageEquipe` disparaît : aucune logique propre à la régie n'y vit dans les deux cas.

## Gates de dépôt touchés

| Gate | Seuil / règle (lu) | Effet de la phase | Action |
|---|---|---|---|
| `scripts/check-version-sync.sh` (point 9, ligne 134-139) | « N suites » des deux README = `find plugin scripts -path '*/tests/test-*.sh'` (213 mesuré ce jour) | une suite neuve : 214 | modifier `README.md:65` et `README.fr.md:67` dans le commit qui ajoute la suite ; recompter au rebase final (74, 79, 80 y touchent aussi) |
| Version racine, `VERSION`, tag | gel des publications (décision du 2026-11-08, `STATE.md`) | aucune release dans la 73 (« rien de publié depuis ») | pas de bump ; `CHANGELOG.md` du module § « Non publié » seulement |
| `scripts/check-gate-touche.sh` (G-2) | six classes : `plugin/conductor/scripts/check-*.sh`, `scripts/check-*.sh`, `plugin/conductor/scripts/tests/test-*.sh` et `scripts/tests/test-*.sh`, `.github/workflows/ci.yml`, `scripts/hooks/`, fixtures de ces suites | **non déclenché** tant que la 73 ne touche aucun de ces chemins : les suites du cockpit vivent sous `plugin/cockpit/scripts/tests/`, hors surface `[VERIFIED: scripts/check-gate-touche.sh, en-tête « SIX CLASSES »]` | ne pas modifier `check-guard-health.sh` (classe 1), ni `ci.yml`, ni `scripts/check-version-sync.sh` : sinon trailer `Gate-Touche: <chemin> — <raison de ≥ 10 caractères>` dans un commit de la branche. Lire une ligne de `check-guard-health.sh` n'est pas la modifier |
| Budget d'instructions (`check-instruction-budget.sh`) | agents `plugin/*/agents/*.md` et `AGENT.md`, plafond ADR-029 | aucun agent ni skill touché | sans objet |
| Taille de fichier (`plugin/software-architecture/scripts/check-file-size.sh`) | 300 lignes bloque (`VF_ARCH_BLOCK`), 250 avertit ; `.js .mjs` ; marqueur `vibeflow:allow-large-file` dans les 5 premières lignes ; appelé par `test-cockpit-vendor.sh` V4 sur TOUT `*.mjs`/`*.js` du module, `tests/` compris | `00-vibeflow.js` 298, `70-vf-live.js` 285, `71-vf-equipe-rendu.js` 231, `72-vf-equipe.js` 193 (à réduire), `vf-cockpit-who.mjs` 244, `vf-cockpit-server.mjs` 164, `vf-cockpit-live.mjs` 169, `vf-cockpit-etat-officiel.mjs` 63, `chrome-equipe-clavier.mjs` 292 | tout ajout dans un fichier proche du plafond va dans un fichier neuf ; `who.mjs` (244) ne peut recevoir qu'environ 50 lignes : le module de gouvernance neuf porte la logique, `who.mjs` n'appelle que ; les `.sh` ne sont pas jaugés (`test-cockpit-equipe.sh` : 1200 lignes) |
| `scripts/check-machine-paths.sh` | aucun chemin absolu de poste dans un fichier SUIVI (`git ls-files`), segment de compte `[A-Za-z0-9._-]` ; échappatoires : segment placeholder (`dev`, `user`…), segment non identifiant (`<user>`), marqueur `vf-allow-machine-path` | les sentinelles « chemin absolu » des témoins REGI-06 et REGI-13, les plans, ce fichier | construire les chemins sentinelles À L'EXÉCUTION (concaténation de fragments) ou utiliser un segment placeholder ; jamais un vrai nom de compte dans un fichier suivi |
| `scripts/ci-suites-perimetre.sh`, `ci-shard-suites.sh` | une suite sans ligne dans la table des durées prend `DEFAUT=7` s ; « module + dépendances citées » | la suite neuve est jouée sur toute PR qui touche `plugin/cockpit/` | optionnel : ajouter une ligne de durée mesurée ; ne rien faire sinon (ces fichiers ne sont pas dans la surface Gate-Touche, mais `ci-shard-suites.sh` est partagé) |
| `VENDORED.txt` / `amont/synchro.sh` | un `AJOUT` par fichier d'extension ; `TAILLE` seulement pour les fichiers au-dessus de 300 lignes | chaque `ui/72-vf-regie-*.js` | ajouter `AJOUT assets/ui/<nom>` ; si la 79 a réduit `VENDORED.txt` à l'origine : rien |
| `vf-cockpit-interface.json` | contrat versionné lu par `vf-signal` | `optionnels` du travailleur : `attendAgents`, `lancee`, (A20 `finMotif`) ; premier niveau de `who@2` : champs facultatifs (impact, détention, phases, `fenetreStallS`) | ajouts facultatifs seulement : pas de bump de version (règle C0) ; description de `cockpit-equipe@1` : « coquille sans cartes depuis la Phase 73 » ; `W23.14` impose la déclaration |
| CHANGELOG et README du module | § « Non publié » ; section « Interface du socle » | fichier partagé avec 74, 79, 80 : conflit de fusion probable | une entrée en tête de sous-section, jamais au milieu d'une phrase d'une autre phase |

## Risques de non-fuite

Règle du dépôt : un sujet de sécurité se décrit par sa CLASSE, sans recette. Pour chaque risque : classe, où le code le porte aujourd'hui, protection prévue, et ce qui reste sans recette (fermeture partielle ou dépendante).

| # | Risque (classe) | Porté aujourd'hui par | Protection | Résiduel sans recette |
|---|---|---|---|---|
| N1 | Exposition d'identifiants du poste vers un client local (chemins de dossier de verrou, identifiants de session) par le flux `lock` | `emit('lock', …)` brut (`S/live.mjs:150`) ; `session_ids`, `lease_seconds`, `lock`, `location` du statut brut (C14) ; `U/70` les lit pour sa logique | liste blanche champ par champ dans un module de page ; rien d'autre n'entre dans le DOM, le stockage ni l'export ; avec la 79 la projection serveur double la défense | un champ libre PERMIS (`owner`, `step`) peut lui-même contenir un chemin ou un identifiant écrit par le manager : borne de longueur et nettoyage ne suffisent pas à le qualifier ; **classe sans recette complète** (mitigation : même nettoyage + masque que `bornes`, refus des valeurs qui ressemblent à un chemin absolu) |
| N2 | Fuite du nom d'un autre projet, ou d'un chemin hors du lab, par `ailleurs()` | `cwd` de `claude agents --json`, jeté aujourd'hui par `formeEtats` | `cwd` ne sort jamais du module ; route propre à la demande ; nom du lab = dernier segment nettoyé (Cf, masque, ≤ 40) ; « un autre dossier » pour le dossier personnel/ancêtres/chemin court ; jamais de git dans un autre dépôt ; sans état officiel : pas de ligne | le nom d'un lab ne peut pas être garanti « non sensible » (il est affiché volontairement) : sa non-fuite se juge par SUPPORT (page servie seule), pas par contenu ; **un lab sans nom exploitable** (dossier générique) retombe sur « un autre dossier » mais la liste des segments reconnus comme « trop courts » reste une heuristique (A7) |
| N3 | Fuite par contournement de support : le nom d'un autre lab écrit dans un cache, un fichier du lab, un export, un journal, `who@2`, `signal`, `state` | `memoE` (page Équipe mémoïsée en mémoire), `journal` du direct (`S/server.mjs:59-65` : ne garde que des comptes), `project.html` réécrit par `live.mjs` (`ecrirePage`) | la route `ailleurs` ne passe ni par `diffuser` ni par `noter` ni par `snapshot()` ; aucune écriture disque ; témoin à sentinelles qui scanne le lab entier après un parcours | un futur lecteur (la 79 : `cockpit-state`, `vf-signal`) peut agréger sans le savoir : borne portée par un témoin de structure (la route est la seule émettrice) |
| N4 | Injection par texte du disque (noms d'agents, titres, tâches, branche) interprété comme balisage | `h()` d'échappement, `textContent` partout (`U/71:152-170`) | tout texte venu du disque en `textContent` ; jamais `innerHTML` pour un champ du lab ; les gabarits en chaîne HTML (comme le tiroir) passent par `h()` | un nom hostile qui imite une instruction destinée à un LLM (injection de consigne par un agent lu ensuite) : hors du périmètre d'un rendu local |
| N5 | Empoisonnement du stockage navigateur (`localStorage` « lu ») | inexistant aujourd'hui (aucune écriture dans `localStorage` des extensions de la régie) | valeurs relues revalidées (forme, `ID_RE`, nombre fini), 200 entrées, purge 24 h, clé par lab ; un objet inattendu est jeté ; jamais exporté | page ouverte dans un autre onglet du même lab qui écrit : dernier écrit gagne (acceptable, jamais une donnée sensible) |
| N6 | Déni de service local : une collecte ou un `claude agents` par requête | `demander` limite à 1 appel / 10 s (`S/etat-officiel.mjs:13`) | la route `ailleurs` lit le cache ; aucune exécution de commande par requête ; le résumé de DAG est calculé sur la collecte déjà faite | un `claude` absent ou lent : état inconnu, pas de ligne |
| N7 | Contrôle d'accès de la route neuve | `serve.mjs:533-537` : hôte, `Origin`, jeton comparé en temps constant (`memeJeton`, `S/server.mjs:38`) avant `VF.route` | la route est derrière ces contrôles ; méthode non GET : 405 ; test sans jeton : 403 (patron `test-cockpit-securite.sh`) | — |
| N8 | Données de planning lues sans confinement | `read` confiné (`S/planning.mjs:17-22`, `lireConfine`) | l'en-tête de VERIFICATION se lit par le point de lecture confiné, taille bornée, jamais un lien sortant (AUDC-A-02) | — |

Ce que les témoins prouvent et ne prouvent pas : un témoin de non-fuite est VALIDE seulement s'il a un témoin positif (« la page affiche bien `1` et le nom du lab ») et si le négatif cherche des sentinelles aux endroits RÉELS d'écriture (export, fichiers écrits sous le lab pendant le test, trames du flux, `who`, objet d'état). Un négatif sans positif est aveugle (règle du jalon : « un négatif aveugle ne prouve rien »).

## Architecture Patterns

### System Architecture Diagram

```
 disque du poste                          serveur du cockpit (Node, sans dépendance)                       page Équipe (JS inliné)
 ───────────────                          ──────────────────────────────────────────                       ───────────────────────
 transcripts (.jsonl, meta.json) ──┐
 claude agents --json (1 / 10 s) ──┼──> vf-cockpit-equipe.mjs (états, orphelins)
   (cwd gardé en privé, jamais     │         │
    exporté : ailleurs())          │         v
 driver-lock.sh status --all ──────┼──> vf-cockpit-who.mjs: gather() ──> collectWho() ──> who@2 ─────────> SSE `who`/`hello` ──> adaptateur de source
 *.dag.json (lireDags, vf-driver)──┤         │  + module de gouvernance neuf (impact, détention,                   │  (VF_ETAT si présent, sinon
 *-VERIFICATION.md (en-tête seul)──┤         │    attendAgents, lancee, phases human_needed, fenetreStallS)        │   vf-who + __vfLive)
 check-guard-health.sh (1 ligne) ──┘         │                                                                      v
                                             ├──> vf-cockpit-live.mjs: lockStatus() ─────────────────> SSE `lock` ──> liste blanche du verrou ──┐
                                             │      (brut avant 79, projeté A15 après)                                                         │
                                             ├──> routes Git (78) : /api/vf/git, /api/vf/git/worktrees ──────────────> jointure arbres ───────┤
                                             ├──> /api/vf/transcript?id= (à la demande) ─────────────────────────────> lecteur « Lire le rapport »
                                             └──> GET /api/vf/ailleurs (neuve, lit le cache) ───────────────────────> ligne « ailleurs » (jamais dans who/flux/export)
                                                                                                                       │
                              rendu pur (who, lock) : quatre sections, arbre, lignes de mission, marques ──────────────┤
                              décroissance silencieux/suspect (temps écoulé) · tri par impact · clé section+id          │
                              compositeur du titre + favicon data: · « lu » en localStorage (clé par lab)               v
                                                                                                          section#vf-equipe (canevas masqué)
```

### Recommended Project Structure
```
plugin/cockpit/scripts/
├── vf-cockpit-gouvernance.mjs   # NEUF : fonctions pures (aval, détention, rang d'impact, phases human_needed, fenêtre de stall, attendAgents)
├── vf-cockpit-who.mjs           # appelle le module (≤ 50 lignes ajoutées : 244 aujourd'hui) ; nettoyage branche/titre à l'émission
├── vf-cockpit-etat-officiel.mjs # + ailleurs() en fin de fichier, + une ligne de rafraîchissement
├── vf-cockpit-server.mjs        # + route GET /api/vf/ailleurs ; pageEquipe sans cartes ; lancees -> startLive
├── vf-cockpit-live.mjs          # whoSig étendu (ou résolu à la jointure avec A17) ; option lancees ; (C4)
├── vf-cockpit-equipe-carte.mjs  # réduit à la coquille, compte, missionsEnCours
└── vf-cockpit-interface.json    # optionnels facultatifs ; description de cockpit-equipe@1
plugin/cockpit/skills/cockpit-moteur/assets/ui/
├── 72-vf-regie-source.js        # NEUF : adaptateur (VF_ETAT | vf-who + __vfLive), liste blanche du verrou, registre __vfEquipeVues
├── 72-vf-regie-rendu.js         # NEUF : sections, lignes, arbre, états ; fonction pure rendre(who, lock)
├── 72-vf-regie-pied.js          # NEUF : ligne de mission, arbres de travail, ailleurs, pieds
├── 72-vf-regie-titre.js         # NEUF : compositeur du titre + favicon ; état « lu » (localStorage)
├── 72-vf-regie-style.js         # NEUF : feuille (jetons existants seulement, garde css-jetons.mjs)
├── 00-vibeflow.js, 70-vf-live.js, 71-vf-equipe-rendu.js, 76-vf-git-entete.js, 80-vf-fr.js  # lignes existantes modifiées, sans ajout net
└── 72-vf-equipe.js              # canevas retiré ; ne garde que le libellé de recherche (ou y renonce)
plugin/cockpit/scripts/tests/
├── test-cockpit-regie.sh        # NEUF (une seule suite, P73-D-05)
├── vm-regie.mjs, chrome-regie.mjs   # NEUFS, partagés, ≤ 300 lignes
└── temoins/regie-*             # fixtures (noms inventés)
```
Les noms sont indicatifs (discrétion du CONTEXT) ; les contraintes ne le sont pas : préfixe `72-vf-regie-` (C13), un seul fichier par responsabilité, chacun ≤ 300 lignes et ouvert par `// VibeFlow (`.

### Pattern 1 : fonction de rendu pure, source injectée (P73-D-02)
**What :** `rendre(who, lock, ctx)` ne lit ni `window`, ni `document` global ; l'adaptateur appelle `rendre` ; le test joue deux sources et compare les DOM.
**When :** toujours. **Pourquoi :** la 79 remplace la source sans toucher le rendu.

### Pattern 2 : liste blanche champ par champ
**What :** un objet neuf construit en lisant chaque champ permis avec son type ; jamais `{...entree}`, jamais `Object.assign`. Même patron que `garde` de `vf-cockpit-vie.mjs:33`. **Pourquoi :** une clé ajoutée plus tard au flux brut n'entre pas par accident.

### Pattern 3 : clé de ligne `section + identifiant` (P73-D-29)
**What :** `data-vf-cle="<section>:<id>"` sur chaque `li` ; mise à jour en place par `Map` clé → nœud ; focus restitué à la ligne de même section, sinon au titre de section (`tabindex="-1"`), jamais à la jumelle ; défilement et `details` conservés. Reprise du patron `cleFocus` de `70-vf-live.js:153-162` mais sur une clé composée.

### Pattern 4 : un témoin rouge d'abord, joué sur le code actuel
**What :** pour chaque comportement : écrire le témoin, le jouer sur le code actuel, consigner « assertion, attendu, obtenu », puis le code. Mutants nommés pour chaque garde (voir « Validation Architecture »). Les sondes de `sondes/` mesurent, elles ne prouvent pas.

### Pattern 5 : donnée absente = rien dit
**What :** un champ facultatif absent (`attendAgents`, `fenetreStallS`, `sortisSilence`, `finMotif`, `impact`) ne produit ni texte, ni état, ni valeur par défaut inventée. **Pourquoi :** ne pas casser avec un serveur assemblé plus ancien (copies d'exécution dans `<lab>/.vibeflow/cockpit/`) et ne pas affirmer ce que personne n'a mesuré.

### Anti-patterns à éviter
- **Recopier un helper de `71`** (orphelin, glyphes, durées) : l'exporter par la ligne 230 de `71` ; une copie divergente casse P74-D-29 (« un glyphe n'existe qu'à un endroit »).
- **Lire `session_ids`, `lease_seconds` ou `location` côté page** pour la régie (N1).
- **Un appel `claude agents` ou `git` par requête** (N6, P73-D-10).
- **Décider la décroissance côté serveur** : le serveur ne repousse pas sur le seul passage du temps (C4, C5).
- **Compter sur `meta.vf.compte` de la coquille** pour les compteurs vivants : il est figé à la construction de la page.
- **Unifier `LONGUE_S` et la fenêtre de stall** (REGI-09).

## Don't Hand-Roll

| Problème | Ne pas construire | Utiliser | Pourquoi |
|----------|-------------------|----------|----------|
| Nom d'affichage, masque de secrets, borne | un nouveau nettoyeur | `nettoie`/`retireAffichage`/`masque`/`nettoieTitre` (`vf-cockpit-arbres.mjs:68`, `vf-cockpit-lecture.mjs`) | la classe Cf/bidi et les secrets ont des témoins de parité (R4.1, quatre copies) ; une cinquième copie est une dette que R4.1 compte |
| Lecture de la fin d'un transcript | un lecteur ligne à ligne | `cherche` (fenêtres 256 Kio → 8 Mio, ignore les lignes trop longues) | `E-5` : une ligne géante masquait une session très active |
| Liste des arbres du lab, lien retour vérifié | `git worktree list` maison | `arbresGit` (P78-D-38) | un arbre déclaré mais non vérifié n'entre pas |
| Résolution du dossier de scripts du conductor | chemin relatif en dur | `driverLockScript` / `resolveScriptsDir` (T-67-06) | jamais un script pris dans l'arbre observé |
| Sous-processus borné | `execSync` | `shBorne` / `lancerGitAsync` | échéance globale, PATH assaini (H-1) |
| Garde d'émission | filtre local | `porteInterdit` (`vf-cockpit-server.mjs:35`) | fermé par défaut si le contrat est illisible |
| Revalidation de `lancee` | regex locale | `entreeLanceeValide` | une seule garde, déjà testée (LE.4) |
| Fermeture transitive des DAG | bibliothèque de graphes | 12 lignes pures (voir Code Examples) | aucune dépendance ; le cycle et le doublon sont les seuls cas |
| Suites navigateur | Puppeteer/Playwright | `chrome-session.mjs` (CDP brut) | le dépôt n'ajoute aucune dépendance ; Playwright est partagé avec d'autres managers et interdit ici |

**Key insight :** presque tout ce que la régie affiche existe déjà sous une forme ou une autre (états, glyphes, transcript, verrous, worktrees). Le risque n'est pas de manquer de code, c'est d'en copier une version qui dérive.

## Runtime State Inventory

La phase retire un canevas et ajoute un stockage ; ce n'est pas un renommage, mais l'inventaire de ce qui survit au changement est utile.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `sessionStorage` : clés `vf-equipe-rechargement` et `vf-equipe-ouvert` écrites par `72-vf-equipe.js` (`:16`, `:116`) restent dans les onglets déjà ouverts ; `localStorage` : aucune clé de la régie n'existe encore | code edit : plus aucune lecture ni écriture de ces clés (témoin : zéro clé `vf-equipe-*` après un parcours) ; création de la clé « lu » par lab ; aucune migration |
| Live service config | aucun (le cockpit est local, aucun service externe) | none — verified by code reading |
| OS-registered state | aucun | none |
| Secrets/env vars | `VF_STALL_WINDOW` (lue, jamais écrite, par le serveur) ; `VF_COCKPIT_*` inchangées | lecteur neuf ; documentée au README du module |
| Build artifacts | copies d'exécution `<lab>/.vibeflow/cockpit/vf-cockpit-*.mjs`, `index.html`, `project.html` (assemblage) ; `equipe.html` n'est jamais écrite (E23.9) | un lab déjà assemblé garde l'ancien serveur jusqu'à `/vf-cockpit build` : la page neuve doit tolérer des champs absents (Pattern 5) ; aucun artefact stale à supprimer |

## Common Pitfalls

### Pitfall 1 : un témoin négatif aveugle (non-fuite)
**What goes wrong :** « le nom du lab n'est pas dans l'export » est vrai parce que l'export n'est pas produit, ou parce que la page n'a rien affiché. **How to avoid :** le témoin positif d'abord (la page affiche `1` et le nom), puis la recherche des sentinelles dans TOUS les supports réels. **Warning signs :** un négatif qui passe au premier essai sans témoin positif associé.

### Pitfall 2 : une durée « depuis » qui ne dit pas de quoi elle parle
**What goes wrong :** « depuis 12 min » sur un verrou sans source de prise (C3). **How to avoid :** libellé qui nomme la grandeur réellement lue (« dernier signe il y a »), tant que A3 n'est pas levée.

### Pitfall 3 : un second onglet qui ment sur les âges
**What goes wrong :** C4. **How to avoid :** témoin à deux onglets ; âge corrigé par l'horodatage de collecte ou `who` rafraîchi à chaque tour.

### Pitfall 4 : un mutant dont l'ancre disparaît
**What goes wrong :** après un déplacement de code, `mutsub.mjs` rend « ancre absente » et le test « doit rougir » devient faux sans que rien n'avertisse. **How to avoid :** re-ancrer chaque mutant AVANT de déplacer le code ; vérifier que le mutant a un effet (patron `LE.0c`, « mutant sans effet »).

### Pitfall 5 : `Date.now()` et temps
**What goes wrong :** une sonde qui lit avant le rendu (géométrie, titre) rougit en CI Linux seulement. **How to avoid :** `stabiliser`/`attendreValeur` (règle « mesurer une fois posé », `chrome-session.mjs`) ; une pause fixe n'est juste que pour PROUVER UNE ABSENCE.

### Pitfall 6 : portabilité Linux (CI `ubuntu-latest` = 26.04, coreutils uutils ; [CITED: mémoire du projet, non revérifiée ici])
**What goes wrong :** `ln -sh`, `mv -h` et d'autres options BSD ne font pas ce qu'on croit ; un verrou n'est jamais posé en CI. **How to avoid :** dans la suite neuve, `mktemp -d`, pas d'option propre à macOS, et un témoin positif de chaque fixture (le verrou réel existe vraiment : patron W17.0).

### Pitfall 7 : `20-health.js` et le reste du chrome moteur
**What goes wrong :** retirer le canevas laisse le zoom, « Vue d'ensemble », la recherche et la santé du moteur. **How to avoid :** C6bis, C12 ; masquer par règle de feuille portée par `body.vf-tab-equipe` (déjà posé par `00:11`), jamais en modifiant un fichier du moteur.

### Pitfall 8 : la traduction réécrit les données
**What goes wrong :** `80-vf-fr.js` traduit toute phrase connue du dictionnaire dans tout nœud de texte non exclu (`SKIP`, `DONNEE`). Une tâche d'agent nommée comme une clé du dictionnaire (« Files ») deviendrait « Fichiers ». **How to avoid :** étendre `test-cockpit-fr-donnees.sh` aux lignes de la régie ; `SKIP` couvre `.mono`, `.rp`, `.pp`, `.card .title`… : poser sur les éléments à texte du disque une classe déjà exclue plutôt que d'éditer `80` (partagé avec 79 et 74).

### Pitfall 9 : région principale doublée et recherche du moteur
**What goes wrong :** `#stage` reste `<main>` ; `section#vf-equipe role="main"` en fait une seconde région ; la recherche (`#search`, `#results`) interroge un graphe vide. **How to avoid :** C12 ; filtre de la régie sur l'événement `input`, panneau de résultats du moteur masqué sur Équipe ; test de clavier avec un résultat choisi → focus sur la ligne (spec § 4.5).

## Code Examples

Formes vérifiées sur le code présent ; les noms sont libres.

### Aval d'un nœud (REGI-05), fonction pure
```js
// nœuds non terminés atteignables en suivant les `deps` à l'envers, le nœud de départ exclu ; Map et Set seulement (T-69-09)
export function aval(noeuds, depart) {
  const enfants = new Map(), statut = new Map();
  for (const n of Array.isArray(noeuds) ? noeuds : []) {
    if (!n || typeof n.id !== 'string') continue;
    statut.set(n.id, n.status);
    for (const d of Array.isArray(n.deps) ? n.deps : []) if (typeof d === 'string') enfants.set(d, [...(enfants.get(d) || []), n.id]);
  }
  const vus = new Set([depart]), pile = [depart];
  while (pile.length) for (const c of enfants.get(pile.pop()) || []) if (!vus.has(c)) { vus.add(c); pile.push(c); }
  vus.delete(depart);
  return [...vus].filter((id) => statut.get(id) !== 'done').length;
}
```

### Liste blanche du verrou (REGI-06)
```js
// source : lignes de `lock` ; objet NEUF, champ par champ (jamais `{ ...e }`) ; la forme brute et la forme projetée de la 79 sont lues
const num = (v) => (typeof v === 'number' && Number.isFinite(v) && v >= 0 ? v : null);
const txt = (v, n) => (typeof v === 'string' ? v.replace(/[\u0000-\u001f\u007f-\u009f  \p{Cf}]/gu, '').slice(0, n) : '');
export const verrouBlanc = (e) => ({ ws: txt(e.ws, 80), scope: txt(e.scope, 16), phase: txt(e.phase, 16), step: txt(e.step, 80), stale: e.stale === true,
  ageS: num(e.ageS ?? e.age_seconds), ttl: num(e.ttl), progressAgeS: num(e.progressAgeS ?? e.progress_age_seconds), owner: txt(e.owner, 80), childrenRunning: num(e.childrenRunning ?? e.children_running) });
```

### Fenêtre de stall à source unique (REGI-07)
```js
// la seule ligne qui compte dans check-guard-health.sh (ligne 127) : ancrée en début de ligne, entier seul ; la ligne 135 (`--stall-window=*) STALL_WINDOW=…`) est indentée et ne correspond pas
const LIGNE = /^STALL_WINDOW="\$\{VF_STALL_WINDOW:-(\d+)\}"$/m;
export function fenetreStall({ env = process.env, texteScript } = {}) {
  const e = env.VF_STALL_WINDOW;
  if (typeof e === 'string' && /^\d+$/.test(e) && Number(e) > 0) return Number(e);
  const m = typeof texteScript === 'string' ? LIGNE.exec(texteScript) : null;
  return m && Number(m[1]) > 0 ? Number(m[1]) : null; // null = inconnue : aucune marque, aucun « suspect » (D-09, D-31)
}
```

### « Attend ses agents » (REGI-10)
```js
// la PREMIÈRE ligne analysable en partant de la fin décide : turn_duration -> N, toute autre ligne -> 0 ; jamais une remontée vers une ancienne turn_duration
export const attendAgents = (fichier) => (cherche(fichier, (d) => {
  if (d.type === 'system' && d.subtype === 'turn_duration') { const n = d.pendingBackgroundAgentCount; return { n: Number.isInteger(n) && n > 0 ? Math.min(n, 999) : 0 }; }
  return { n: 0 };
}) || { n: 0 }).n;
```
`subtype === 'turn_duration'` : [VERIFIED: .planning/research/2026-11-10-audit-cockpit/sondes/index-proto.mjs:47 « d.subtype === 'turn_duration' »]. Si une ligne `system` d'un autre sous-type suit couramment `turn_duration` en fin de tour, la règle « dernière écriture » doit les sauter : à mesurer sur de vrais transcripts avant d'écrire le prédicat (A12).

### Livrer des événements sentinelles à la vraie page (harnais CDP)
```js
// patron de chrome-verrou.mjs : EventSource enveloppé, __emit(nom, données) rejoue un événement du flux dans la page réelle
const INJ = `(() => { const R = window.EventSource; window.__es = []; window.EventSource = class extends R {
  constructor(u, o) { super(u, o); this.__l = {}; window.__es.push(this); }
  addEventListener(n, f, o) { (this.__l[n] ||= []).push(f); super.addEventListener(n, f, o); }
  __emit(n, d) { for (const f of this.__l[n] || []) f({ data: JSON.stringify(d) }); } }; })();`;
// await s.send('Page.addScriptToEvaluateOnNewDocument', { source: INJ }); puis s.ev(`window.__es[0].__emit('lock', {...})`)
```
Sentinelles : construites à l'exécution (`['', 'Users', 'a-sentinelle'].join('/')`) pour ne pas écrire un chemin de poste dans un fichier suivi (`check-machine-paths.sh`).

### Mutant à ancre vérifiée (patron des suites)
```bash
# mutsub.mjs : sort 1 « ancre absente » si FROM n'est pas dans le fichier ; le mutant doit avoir un effet et son témoin doit rougir
FROM='<texte exact du code>' TO='<texte muté>' node "$AUX/mutsub.mjs" "$COPIE/vf-cockpit-<module>.mjs" || echo "ancre absente"
```

## State of the Art

| Ancienne approche | Approche présente | Changée | Impact |
|--------------|------------------|--------------|--------|
| Équipe = canevas de cartes (graphe ELK, P69-D-17) | régie en liste (direction retenue le 2026-11-11) | cette phase | amende P69-D-17 ; le moteur n'a plus rien à dessiner sur Équipe |
| État « vous attend » lu dans les transcripts | état officiel `claude agents --json`, transcripts en repli (AUDC-Q4) | lot 0 | `cwd` et `name` y sont disponibles (sources tierces) mais jetés ; `waitingFor` non observé |
| Verrou lu en brut dans la page | liste blanche, puis projection serveur (79 A15) | 73 puis 79 | la page ne dépend plus de champs du poste |
| Un flux par page | un flux partagé (79 C4) | 79 | la régie lit `VF_ETAT` quand il existe |

**Deprecated/outdated :** le panneau d'item d'Équipe et ses trois styles de bouton ; la carte « Terminés depuis moins de 24 h » ; la règle P70-D-20 (zoom d'Équipe en bas à gauche) et UIFN-14 ; la section Santé masquée en CSS (voir C6bis).

## Fichiers partagés et propriété par vague

Règle (P73-D-23) : deux plans d'une même vague ne modifient pas le même fichier. Les fichiers ci-dessous sont partagés avec les Phases 74, 79 ou 80 (ou entre plans de cette phase) ; un seul plan par fichier et par vague.

| Fichier | Vague | Modifications attendues | Voisins |
|---|---|---|---|
| `plugin/cockpit/scripts/vf-cockpit-gouvernance.mjs` (neuf) | V1 | fonctions pures | — |
| `vf-cockpit-who.mjs` (244 l.) | V1 | appels au module, option `lancees`, nettoyage branche/titre (D-22), limites `LIBRES`/`NOMBRES` | 79 : plans « environnement git » (2e vague) et « collecte » (3e) — jointure libre (A17) |
| `vf-cockpit-interface.json` | V1 | `optionnels` du travailleur, premier niveau de `who@2` (facultatifs), description `cockpit-equipe@1` | 79 : blocs de schémas neufs ; A20 ajoute `sortisSilence`/`finMotif` : deux listes sur la même ligne 30, résolution à la jointure |
| `vf-cockpit-etat-officiel.mjs` (63 l.) | V1 | `ailleurs()` en fin de fichier + mémorisation privée des `cwd` dans `rafraichir` | 79 : plan « collecte » (A20), même fonction |
| `vf-cockpit-server.mjs` (164 l.) | V1 (route, `lancees`) puis V3 (`pageEquipe` sans cartes) : DEUX plans, deux vagues | route `GET /api/vf/ailleurs`, passage de `lancer.lancees` à `startLive`, mémo `memoE` sans `who` | 79 : table de routes (A10), coquille (C5) |
| `vf-cockpit-live.mjs` (169 l.) | V1 | `whoSig`, option `lancees` de `whoNow`, (C4) `who = nw` | 79 : réécrit `whoSig`, flux partagé, `lock` projeté |
| `ui/72-vf-regie-*.js` (neufs) | V2 | tout le rendu | 74 : `ui/74-vf-*` (prefixe distinct) |
| `ui/00-vibeflow.js` (298 l.) | V2 (un seul plan) | ligne 13 (titre → compositeur) ET ligne 286 (garde d'ancre `TAB==='equipe'`) : un seul plan pour les deux lignes | 79/80 |
| `ui/70-vf-live.js` (285 l.) | V3 (un seul plan) | ligne 190 (`onClick` « N au travail » : section sur Équipe) | 79 (réécrit en partie : `VF_ETAT`) |
| `ui/71-vf-equipe-rendu.js` (231 l.) | V2 pour les exports (ligne 230), V3 pour le pli des terminés (lignes 141-142) : DEUX plans, deux vagues | exports (orphelin, `GLYPHE_ETAT`, `MOT`, `glyphe`), pli → lien « N à relire dans Équipe » | 74 lit la table de glyphes |
| `ui/76-vf-git-entete.js` (205 l.) | V2 | ligne 19 (titre → compositeur) ; la branche Équipe de `texteVue` (lignes 35-40) tombe ou se replie | 78 |
| `ui/72-vf-equipe.js` (193 l.) | V3 | canevas retiré ; libellé de recherche repris | — |
| `ui/80-vf-fr.js`, `78-`, `79-vf-fr-dict-*` | aucun | aucune entrée à ajouter (texte déjà français) ; ne PAS l'éditer pour exclure les données (Pitfall 8) | 79 les modifie |
| `scripts/vf-cockpit-fr-exclusions.json` | V3 si une exclusion pointe un texte retiré | contrôle `F4` : chaque exclusion garde son texte dans l'inventaire | — |
| `VENDORED.txt` | V2 (une ligne `AJOUT` par fichier neuf), tri à sa place | — | 74, 79 (réduit le fichier) |
| `CHANGELOG.md`, `README.md` du module | V3 | § « Non publié » ; description de `cockpit-equipe@1` ; correspondance LE → LR ; `VF_STALL_WINDOW` | 74, 79, 80 |
| `README.md`, `README.fr.md` racine | V3 (après rebase) | compteur 213 → 214 | 74, 79, 80 |
| `tests/test-cockpit-equipe.sh`, `-equipe-etats.sh`, `-who.sh`, `-lancer-suivi.sh`, `-responsive.sh`, `-projet-visite.sh`, `-git-entete.sh`, `-transcript.sh`, `-moteur-carte.sh`, `chrome-moteur-carte.mjs`, `chrome-equipe-clavier.mjs` | V3 | re-pointages (inventaire) | 79 (lancement des suites), 80 |

Ordre de pose relatif à la coquille de la 79 (C5) : V1 et V2 sont indépendants d'elle ; V3 (`pageEquipe`) dépend de l'ordre de fusion et dit les deux cas.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Une ligne de phase `human_needed` n'est émise que pour une phase ni cochée ni archivée | Constats C6 ; REGI-04 | Si faux : le titre de l'onglet compte de vieilles phases (60, 69 aujourd'hui) pour toujours |
| A2 | « Santé ni calculée ni injectée » se tient sans modifier `20-health.js` (règle CSS de `00:134` gardée, pas de `health` dans l'enveloppe) | C6bis | Si faux : il faut un patch du moteur et un diff régénéré, contraire à D-24 |
| A3 | Sans champ numérique de prise de verrou dans la liste blanche, la ligne de mission dit « dernier signe il y a N » (`ageS`) au lieu de « depuis N » | C3 | Si faux : l'interface ment sur la durée du verrou, ou la liste blanche s'élargit à `lease_seconds` |
| A4 | Un changement de verrou isolé peut attendre ≤ 30 s (minuterie) avant la mise à jour de la ligne de mission, tant que `VF_ETAT` n'existe pas | C9 | Si faux : ligne obsolète visible ; correction = relais d'événement `lock` dans `70` (3e ligne modifiée) |
| A5 | La jointure agent → arbre se fait par nom de branche unique, sinon aucun compte (jamais deviné) | C11 | Si faux : « N modifiés » absent de nombreuses lignes (sans conséquence de sécurité) |
| A6 | La fenêtre de stall voyage dans `who@2` au premier niveau (`fenetreStallS`), pas dans le flux `lock` | REGI-07 | Si faux : la 79 doit l'ajouter à la projection A15 |
| A7 | « Chemin trop court » = moins de deux segments significatifs ; le dossier personnel et ses ancêtres sont détectés par `os.homedir()` | REGI-13 ; N2 | Si faux : un nom de dossier générique ou personnel est affiché au lieu de « un autre dossier » |
| A8 | LE.* se transforment en LR.* selon la proposition de « LE → LR » (copie figée gardée, comparaison A/B sur `who`, mutants re-ancrés) | Inventaire | Si faux : LE.0b/LE.1 rougissent à la réduction de `equipe-carte.mjs` |
| A9 | L'impact et la détention du verrou se calculent côté serveur et voyagent en champs facultatifs du travailleur session (`retient`, `detient`) ; seul le tri est côté page | C2 | Si faux : la page ne peut pas décider la détention après A15 (plus de `session_ids`) |
| A10 | La recherche du moteur sur un graphe vide est neutralisée par le filtre de la régie et le masquage de `#results` | Pitfall 9 | Si faux : « No results » du moteur visible au-dessus de la régie |
| A11 | La correction C4 (`who = nw` hors de la condition) est acceptable ; sinon horodatage de collecte | C4 | Si faux : seconde onglet à âges faux (« au travail » au lieu de « suspect ») |
| A12 | D'autres lignes `system` peuvent suivre `turn_duration` en fin de tour ; non mesuré | REGI-10 | Si faux (elles existent) : « attend ses agents » n'apparaît presque jamais avec la règle « dernière écriture » stricte |
| A13 | `claude agents --json` sans `--cwd` liste tout le poste, et chaque entrée porte `cwd` | REGI-13 | Si faux : la ligne « ailleurs » est vide (jamais fausse) ; à lever par une sonde réelle |
| A14 | Node ≥ 22 suffit pour les modules neufs (aucun syntaxe récente) | Standard Stack | Faible |

## Open Questions

1. **Que faire du couple `tenu` / « depuis » avec la 79 ?** — RESOLVED (73-04, hypothèse A3 résolue par A36 et A39 de la 79@6fb94fb7 : `leaseS` = temps depuis la prise, `ageS` = dernier battement ; aucune demande de `priseS` à renvoyer ; repli sur `lease_seconds` brut avant la fusion)
   - Ce qu'on sait : `tenu` est un booléen ; A15 exclut `lease_seconds` ; la spec veut « depuis N » (C3).
   - Ce qui manque : un champ numérique de prise dans la projection.
   - Recommandation : plan de verrou en V1/V2 avec repli A3 (libellé « dernier signe ») et une demande, à renvoyer par la session principale à la 79, d'un champ `priseS` ; le plan est marqué « à revalider ».

2. **Faut-il rouvrir D-24 pour la santé ?** — RESOLVED (non : P73-D-24 tient ; 73-08, hypothèse A2, garde de non-régression)
   - Ce qu'on sait : C6bis.
   - Recommandation : non. Hypothèse A2 ; si le jugement de design exige le retrait réel, le dire dans « À Samuel », pas dans un plan.

3. **LE → LR : garder LE.0b ?** — RESOLVED (73-09, hypothèse A8 : les LR s'écrivent avant la réduction d'`equipe-carte.mjs`, valeur saine de LR.1 capturée par 73-03)
   - Ce qu'on sait : LE.0b et LE.1 ne peuvent pas tenir tels quels.
   - Recommandation : A8 ; la vague 3 écrit les LR AVANT de réduire `equipe-carte.mjs` et consigne la valeur saine de LR.1 capturée sur le code actuel.

4. **Forme réelle de `claude agents --json` sur ce poste ?** — RESOLVED (aucune sonde dans cette phase : la forme est couverte par le contrat de forme du lot 0 et AUDC-Q4, avec les transcripts en repli ; 73-02 traite une liste absente, une entrée sans `cwd` chaîne ou une forme inattendue comme « pas de ligne » (RG13.6) et ne s'appuie que sur des fixtures ; la sonde sur un poste vivant reste une vérification manuelle listée dans 73-VALIDATION.md)
   - Ce qu'on sait : sources tierces (A13), fixtures des suites.
   - Recommandation : une sonde réelle en Wave 0, hors de cette phase de planification (aucun processus lancé ici) ; tant qu'elle manque, la régie traite une liste absente ou de forme inattendue comme « pas de ligne ».

5. **Quelle part de la jointure agent → arbre est utile ?** — RESOLVED (73-07, hypothèse A5 : une branche unique, jamais devinée)
   - Recommandation : A5, ne pas investir plus (l'information est secondaire, ligne 2).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | modules `.mjs`, suites | oui | 26.5.0 (poste de recherche) | — |
| bash | suites | oui (`/bin/bash`, macOS 3.2 : pas de fonctionnalité bash 4+) | — | — |
| git | routes Git, fixtures | oui | système | — |
| jq | suites existantes | oui | système | — |
| python3 | `check-guard-health.sh`, hooks | oui | 3.14 | — |
| Chrome headless | harnais CDP (suites navigateur) | oui sur ce poste (non lancé) | — | hors CI : suite sautée « non compté réussi » ; en CI : échec (jamais de vert à vide) |
| binaire `claude` | `claude agents --json` réel | oui (non lancé) | — | faux `claude` des suites (`fauxbin-claude`, `VF_FAKE_SORTIE`) |
| Playwright / navigateur partagé | — | interdit pour cette mission | — | CDP brut de `chrome-session.mjs` |

**Missing dependencies with no fallback:** aucune. **Missing dependencies with fallback:** navigateur sur un poste sans Chrome (suite sautée hors CI).

## Validation Architecture

`workflow.nyquist_validation` vaut `true` dans `.planning/config.json` du dépôt (lu). Rien ci-dessous n'a été exécuté : les commandes sont celles à jouer en exécution.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | suites bash du module cockpit (`assert_eq`, `assert_has`, `assert_not`, compteurs `PASS`/`FAIL`, sortie 0/1) ; modules Node joués en `vm` ou importés ; Chrome headless par CDP brut (`chrome-session.mjs`), sauté hors CI sans navigateur et échec en CI (`chrome-saut.sh`) |
| Config file | aucun fichier de config ; `tests/hygiene.sh` (`vf_hyg_init`/`vf_hyg_fin`, arrêt des serveurs) |
| Quick run command | `bash plugin/cockpit/scripts/tests/test-cockpit-regie.sh` (la suite accepte des noms de sections, p. ex. `RG4 RG5`, pour rejouer une couche : à prévoir en Wave 0) ; couche données : `bash plugin/cockpit/scripts/tests/test-cockpit-who.sh && bash plugin/cockpit/scripts/tests/test-cockpit-equipe-etats.sh` |
| Full suite command | `for s in plugin/cockpit/scripts/tests/test-cockpit-*.sh; do bash "$s" || echo "ROUGE $s"; done` (durées CI mesurées, `scripts/ci-shard-suites.sh` : `test-cockpit-equipe.sh` 148 s, `-git-e2e` 250 s, `-lancer-bandeau` 311 s, `-direct` 62 s ; le périmètre d'une PR : `bash scripts/ci-suites-perimetre.sh --liste <base> HEAD`) |
| Gates de dépôt | `bash scripts/check-version-sync.sh` · `bash scripts/check-machine-paths.sh` · `bash plugin/software-architecture/scripts/check-file-size.sh <fichiers .js/.mjs touchés>` · `bash plugin/cockpit/scripts/tests/test-cockpit-vendor.sh` |

### Phase Requirements → Test Map
Identifiants `RGn.m` = sections de la suite neuve ; `LRn` = propriétés issues de LE.* ; « rouge avant » = ce que le témoin doit rendre sur le code actuel (à consigner : assertion, attendu, obtenu). Un mutant est un test qui DOIT rougir (nom `M-…`).

| Req | Comportement | Type | Témoin (commande rapide) | Rouge avant (attendu / obtenu) | Fichier existe ? |
|-----|--------------|------|--------------------------|--------------------------------|------------------|
| REGI-01 | quatre sections dans l'ordre, compteurs en lignes, sous-titre en agents distincts, états vides, clé `section+id`, focus conservé | VM + CDP | RG1.0 (témoin positif : fixture 5 états) ; RG1.1-RG1.4 | 4 `h2` / 0 (`section#vf-equipe` absente) ; sous-titre « 4 agents · 1 vous attend » / absent | ❌ Wave 0 |
| REGI-02 | même entrée → même DOM par `VF_ETAT` factice et par `vf-who` | VM | RG2.1 ; mutant `M-ADAPTATEUR-DIVERGE` | DOM égal / fonction absente | ❌ |
| REGI-03 | `nodes` vide, `meta` gardée, schéma `@1` valide, 0 rechargement, moteur intact | serveur réel + VM | RG3.1 (enveloppe) ; RG3.2 (`validate2.mjs`) ; RG3.3 (3 changements d'ensemble → 0 `location.reload`) ; RG3.4 (`git diff --stat -- plugin/cockpit/skills/cockpit-moteur/assets/viewer.html` vide) ; `test-cockpit-vendor.sh` V6.1 | `nodes.length === 0` / N agents ; rechargements 0 / ≥ 1 | ❌ ; existants re-pointés |
| REGI-04 | « À vous » = sessions `attend` + phases `human_needed` ; rien d'autre | VM + fixture disque | RG4.0 positif ; RG4.1 (phase non cochée → 1 ligne) ; RG4.2 (cochée → 0 ligne, A1) ; RG4.3 (négatifs : orphelin, suspect, « à recetter », question sans réponse) | 1 ligne de phase / 0 ; phase cochée 0 / 0 (rouge seulement après un code naïf : le témoin est écrit pour attraper A1) | ❌ |
| REGI-05 | impact, trois rangs, ancienneté, jamais deviné | VM pur | RG5.1 jeu d'essai spec § 16.2 (4, 1, inconnu, 0 + égalité) ; RG5.2 (cycle, doublon, `deps` invalide) ; RG5.3 (détenteur : « retient toute la mission · N » seulement si DAG visible) ; mutants `M-IMPACT-TRI`, `M-IMPACT-TERMINES`, `M-IMPACT-DEVINE` | ordre 4,1,inconnu,0 / fonction absente | ❌ |
| REGI-06 | tenant du verrou, liste blanche, non-fuite | CDP + vrai `driver-lock.sh` | RG6.0 (positif : la ligne de mission du verrou réel) ; RG6.1 (sentinelles : session, chemin du dossier de verrou, `location`, `lease_seconds` : absentes du DOM, de `localStorage`/`sessionStorage`, de l'export) ; mutants `M-VERROU-ENTREE-BRUTE`, `M-VERROU-SESSION-IDS`, `M-VERROU-CHEMIN` | sentinelles absentes du DOM / `__vfLive.lock` brut les contient | ❌ |
| REGI-07 | « verrou abandonné », « aucun nœud marqué depuis N min », fenêtre à source unique, inconnue = rien | Node + VM | RG7.1 (ligne source → fenêtre, mutants sur COPIE du script) ; RG7.2 (`VF_STALL_WINDOW`) ; RG7.3 (inconnue → ni marque ni « suspect ») ; RG7.4 (`stale` → « verrou abandonné », texte neutre, aucun reclassement) ; mutants `M-STALL-LIGNE`, `M-STALL-ABSENT`, `M-STALL-ENV`, `M-STALL-INCONNU-MARQUE` | fenêtre servie / absente ; 900 en dur serait vert, d'où `M-STALL-LIGNE` (600 attendu) | ❌ |
| REGI-08 | bloc replié, jointure, « non vérifié », aucun appel git neuf | serveur réel + faux `git` journal | RG8.1 (2 worktrees, 1 non vérifié) ; RG8.2 (faux `git` qui journalise : 0 appel hors routes 78) ; RG8.3 (aucune commande `cd` dans la régie) | 2 lignes / bloc absent | ❌ |
| REGI-09 | décroissance, commande longue, orphelin neutre, `sortisSilence`, glyphes du lot 0, second onglet | VM temps contrôlé + CDP | RG9.1 (120 s → silencieux ; fenêtre → suspect ; < 1800 s) ; RG9.2 (commande en cours « au travail » jusqu'à 15 min) ; RG9.3 (fenêtre inconnue : jamais « suspect », D-31) ; RG9.4 (orphelin sous le parent grisé, aucun bouton) ; RG9.5 (second onglet, C4) ; RG9.6 (aucune couleur d'alerte : jetons seuls) ; mutants `M-CALME`, `M-LONGUE-EGALE-STALL`, `M-ORPHELIN-ACTION` | « silencieux depuis 4 min » / libellé de tiroir seul | ❌ |
| REGI-10 | `attendAgents` | Node + fixture transcript | RG10.1 (dernière ligne `turn_duration` N=3 → 3) ; RG10.2 (écriture plus récente → absent) ; RG10.3 (sous-agent → jamais) ; RG10.4 (clé déclarée au contrat : `W23.14` étendu) ; mutant `M-ATTEND-REMONTE` | 3 / champ absent | ❌ |
| REGI-11 | « lu » à l'ouverture seulement, purge 24 h, repli sans stockage, « Tout marquer », `finMotif`, lien du tiroir | CDP | RG11.1 (survol : non lu ; ouverture : lu) ; RG11.2 (purge) ; RG11.3 (stockage refusé : tout < 24 h « à relire ») ; RG11.4 (aucune requête non GET, aucune écriture serveur) ; RG11.5 (`finMotif`, à revalider 79) ; RG11.6 (tiroir : « N à relire dans Équipe ») ; mutants `M-LU-SURVOL`, `M-LU-SANS-PURGE` | pas d'état « lu » / aucun stockage | ❌ |
| REGI-12 | compositeur unique, favicon, singulier, zéro, survie à `git` et à la traduction | CDP | RG12.1 (préfixe après `vf-git:signal`) ; RG12.2 (après la traduction `80-vf-fr.js`) ; RG12.3 (zéro → format `Équipe · nom`, favicon d'origine rendu) ; RG12.4 (aucun focus volé) ; mutants `M-TITRE-ECRIVAIN` (un des quatre écrit hors compositeur), `M-TITRE-ZERO` | préfixe survivant / réécrit par `76:19` | ❌ ; `X7.3` adapté |
| REGI-13 | « ailleurs » : nombre et nom seulement, route propre, non-fuite | serveur réel + faux `claude` | RG13.0 (positif : la page affiche « 1 » et le nom) ; RG13.1 (sentinelles : identifiant, titre, chemin complet, dossier parent, nom du lab : absentes de l'export, de tout fichier écrit sous le lab pendant le test, des trames du flux, de `who@2`, de l'objet d'état) ; RG13.2 (`/api/vf/transcript?id=<sentinelle>` → `inconnu`) ; RG13.3 (faux `git` journal : jamais appelé hors des arbres du lab) ; RG13.4 (sans jeton : 403 ; non GET : 405) ; RG13.5 (« un autre dossier » : dossier personnel, ancêtre, chemin court) ; mutants `M-AILLEURS-CWD`, `M-AILLEURS-DANS-WHO`, `M-AILLEURS-FLUX`, `M-AILLEURS-TITRE`, `M-AILLEURS-SOUS-ARBRE`, `M-AILLEURS-GIT` | `[{lab, n}]` / 404 | ❌ |
| REGI-14 | un style de bouton, nom une fois, santé | CDP + VM | RG14.1 (inventaire des contrôles de la régie : seul `.btn` doux) ; RG14.2 (nom d'une ligne : un seul élément de texte) ; RG14.3 (`M3.8` conservé, A2) ; mutant `M-BOUTON-STYLE-NEUF` | 3 styles / 1 | ❌ ; `M3.8` existe |
| REGI-15 | registre, bascule, événements annulables, attributs, ancres | VM | RG15.1 (`declarer` + 1 vue : aucune bascule ; 2 vues : bascule, `monter` une fois) ; RG15.2 (`vf-agent:ouvrir` annulé → pas de lecteur ; non annulé → lecteur) ; RG15.3 (`data-vf-*` sur chaque ligne) ; RG15.4 (ancre `#r=n:ag-A` : défilement + focus, une fois ; ligne de « À vous » préférée) | `__vfEquipeVues` indéfini | ❌ |
| REGI-16 | LE → LR, nettoyage à l'émission, export, recherche, compteur, suites vertes | suites existantes + gates | LR1-LR5 (`test-cockpit-lancer-suivi.sh`) ; `W23.*` re-pointés ; RG16.1 (export Équipe sans marqueur de régie) ; RG16.2 (recherche filtre nom et rôle) ; `check-version-sync.sh` (214) | `lancee` absent de `who@2` / présent | existants à modifier |

### Mutants à nommer (gardes)
Non-fuite d'`ailleurs` : `M-AILLEURS-CWD` (laisse passer `cwd`), `M-AILLEURS-DANS-WHO` (verse la liste dans `who@2`), `M-AILLEURS-FLUX` (dans `hello`/`snapshot`), `M-AILLEURS-TITRE` (titre ou nom de session), `M-AILLEURS-SOUS-ARBRE` (sous-dossier d'un arbre du lab compté « ailleurs »), `M-AILLEURS-HOME` (dossier personnel non masqué), `M-AILLEURS-GIT` (git hors du lab). Liste blanche du verrou : `M-VERROU-ENTREE-BRUTE` (`{...e}`), `M-VERROU-SESSION-IDS`, `M-VERROU-CHEMIN`, `M-VERROU-OWNER-SANS-BORNE`. Fenêtre de stall : `M-STALL-LIGNE` (défaut altéré dans la copie du script), `M-STALL-ABSENT` (ligne retirée : rien marqué, pas de 900 en dur), `M-STALL-ENV`, `M-STALL-INCONNU-MARQUE`. Compositeur du titre : `M-TITRE-ECRIVAIN` (un des quatre écrivains sorti du compositeur), `M-TITRE-ZERO`, `M-TITRE-PLURIEL`. Impact : `M-IMPACT-TRI`, `M-IMPACT-TERMINES` (compte les terminés), `M-IMPACT-DEVINE`. Vivacité : `M-CALME`, `M-LONGUE-EGALE-STALL`, `M-ORPHELIN-ACTION`. « Lu » : `M-LU-SURVOL`, `M-LU-SANS-PURGE`, `M-LU-EXPORT`. Lignes : `M-CLE-ID-SEUL` (D-29), `M-FOCUS-JUMELLE`. Données : `M-SIG-CHAMP` (champ ajouté hors `whoSig`), `M-HUMAN-NEEDED-COCHEE` (A1), `M-ATTEND-REMONTE`, `M-LANCEE-HORS-SESSION`, `M-LANCEE-SANS-VALIDATION`. Route : `M-ROUTE-SANS-JETON`. Chaque mutant a une ancre vérifiée (« ancre absente » = échec de la suite) et un témoin vert sur le dépôt non muté.

### Sampling Rate
- **Per task commit :** la suite de la couche touchée (`test-cockpit-regie.sh` rejouée par sections ; `test-cockpit-who.sh` et `-equipe-etats.sh` pour la donnée), plus `check-file-size.sh` sur les fichiers touchés.
- **Per wave merge :** toutes les suites `test-cockpit-*.sh` (boucle ci-dessus) + `test-cockpit-vendor.sh`.
- **Phase gate :** suites cockpit vertes sous macOS ET Linux (REGI-16 ; CI `ubuntu-latest` 26.04 à coreutils uutils : Pitfall 6), `check-version-sync.sh` (214), `check-machine-paths.sh`, tailles ≤ 300, puis `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `plugin/cockpit/scripts/tests/test-cockpit-regie.sh` : squelette (hygiène, `chrome-saut.sh`, assertions, sections nommables, en-tête listant LE → LR) : couvre tout REGI.
- [ ] `plugin/cockpit/scripts/tests/vm-regie.mjs` : harnais VM de la régie (document et fenêtre factices, horloge injectée), ≤ 300 lignes.
- [ ] `plugin/cockpit/scripts/tests/chrome-regie.mjs` : harnais CDP (EventSource enveloppé, sentinelles, deux onglets, `localStorage` refusé), ≤ 300 lignes.
- [ ] Fixtures (`tests/temoins/`, noms inventés) : lab avec VERIFICATION `human_needed` (cochée et non cochée), DAG aux quatre profils d'impact, verrou RÉEL par `driver-lock.sh` (patron W17.0), faux `claude agents --json` avec `cwd` hors du lab, deux worktrees dont un à lien forgé, transcript de fin de tour avec `pendingBackgroundAgentCount`.
- [ ] Valeur saine de LR.1 capturée AVANT toute modification de `who.mjs` (trace conservée avec la commande).
- [ ] Sonde réelle de `claude agents --json` et des lignes qui suivent `turn_duration` (A12, A13) : à jouer hors de cette phase, sur un poste avec une session vivante.
- [ ] Étendre : `test-cockpit-fr-donnees.sh` et `test-cockpit-chrome-fr.sh` (libellés et lignes de la régie), `test-cockpit-accessibilite.sh` (X4.5 → régions principales visibles).

## Security Domain

`security_enforcement` n'est pas désactivé (absent ou vrai) ; `security_asvs_level: 1`, `security_block_on: high`.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | non (serveur local, jeton de page existant) | — |
| V3 Session Management | non | — |
| V4 Access Control | oui (route `ailleurs`) | contrôles de `serve.mjs:533-537` (hôte, `Origin`, jeton en temps constant) devant `VF.route` ; GET seul |
| V5 Input Validation | oui | texte du disque en `textContent` ; liste blanche champ par champ ; `ID_RE`, nombres finis ; env `VF_STALL_WINDOW` validée (chiffres, > 0) ; `localStorage` relu revalidé |
| V6 Cryptography | non (aucun secret nouveau ; le haché de lab de `/api/vf/modeles` existe déjà) | — |
| V8 Data Protection | oui | aucun chemin du poste, identifiant de session ni nom d'un autre projet dans `who@2`, flux, export, fichiers du lab ; lecture seule sur `.planning/` |
| V12 Files and Resources | oui | lecture confinée au lab (`lireConfine`, AUDC-A-02) pour l'en-tête de VERIFICATION ; fichier borné, régulier |
| V13 API | oui | `cockpit-ailleurs@1` déclaré ; `Cache-Control: no-store` ; réponse passée par `porteInterdit` |
| V14 Configuration | oui | CSP inchangée (`script-src` par hachage des scripts inlinés ; `img-src 'self' data:` couvre la pastille) |

### Known Threat Patterns for ce stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Texte hostile d'un agent ou d'un titre rendu comme HTML | Tampering / XSS | `textContent`, `h()` des gabarits, nettoyage Cf à l'émission (D-22) ; témoin `chaine-xss` étendu à la régie |
| Fuite du nom d'un autre projet par un support non prévu | Information disclosure | route dédiée, aucune écriture disque, témoin à sentinelles précédé de son témoin positif (N2, N3) |
| Champ libre du verrou (`owner`, `step`) portant un chemin ou un identifiant | Information disclosure | borne, nettoyage, masque ; classe sans recette complète (N1) |
| Requête qui déclenche un sous-processus | Denial of service | route qui lit le cache, 1 appel / 10 s existant (N6) |
| Valeur de `localStorage` forgée | Tampering | revalidation, jet de tout objet inattendu, aucune évaluation (N5) |
| Lecture d'un fichier lié hors du lab | Elevation / Information disclosure | `lireConfine` (N8) |
| Requête inter-sites vers la route | Spoofing | contrôle d'hôte, `Origin`, jeton (N7) ; `test-cockpit-securite.sh` joué sur la route |

## Sources

### Primary (HIGH confidence)
- Code du dépôt à la tête e34fe859, fichiers ouverts cette session : `plugin/cockpit/scripts/vf-cockpit-{who,equipe,equipe-etat,equipe-carte,etat-officiel,live,server,vie,arbres,avancement,planning,paths,lecture,lancer-suivi,git,build}.mjs`, `vf-cockpit-interface.json`, `vf-cockpit-fr-inventaire.mjs`, `vf-cockpit-port.mjs` ; `plugin/cockpit/skills/cockpit-moteur/assets/ui/{00-vibeflow,70-vf-live,71-vf-equipe-rendu,72-vf-equipe,73-vf-tiroir-travail,76-vf-git-entete,80-vf-fr,20-health,60-export}.js`, `assets/viewer.html` (titre, favicon, structure `#stage`), `assets/serve.mjs` (CSP, contrôles de route), `VENDORED.txt`, `amont/synchro.sh` ; `plugin/conductor/scripts/{driver-lock.sh,check-guard-health.sh,check-gate-touche.sh}` ; `scripts/{check-version-sync,check-machine-paths,ci-suites-perimetre,ci-shard-suites}.sh` ; `plugin/software-architecture/scripts/check-file-size.sh` ; suites sous `plugin/cockpit/scripts/tests/` citées dans l'inventaire.
- `73-CONTEXT.md`, `73-UI-SPEC.md`, `REQUIREMENTS.md` (REGI-01 à 16), `STATE.md`, `ROADMAP.md` du compartiment fiabilite.
- `79-CONTEXT.md` (branche `feat/phase-79-socle-cockpit`, commits `3119d82a`, `2ae6607a`, `6f66d878`, lu par `git show`, rien fusionné) et `74-CONTEXT.md` (branche `feat/phase-74-equipe-dans-le-temps`).
- Annexes d'audit `.planning/research/2026-11-10-audit-cockpit/A1-donnees-agents-sessions.md` (ligne 62, `turn_duration`), `A6-surface-claude-code.md` (ligne 88, sortie JSON), `REGISTRE.md`, `sondes/index-proto.mjs` (ligne 47).

### Secondary (MEDIUM confidence)
- [claudeissues.com : docs omit `claude agents --json` flag and fields (issue 66384)](https://claudeissues.com/issue/66384-docs-claude-agents-json-docs-omit-all-flag-new-id-and-state-fields-and-which-ses) et [issue 60685](https://claudeissues.com/issue/60685-docs-agent-view-docs-omit-claude-agents-json-for-scripted-session-listing) : champs `cwd`, `kind`, `startedAt`, `sessionId`, `name`, `status`, options `--cwd` et `--all`.
- [ClaudeWrapper.Commands.Agents (hexdocs)](https://claude-wrapper.hexdocs.pm/ClaudeWrapper.Commands.Agents.html) : description tierce de la commande.
- [claudeissues.com issue 87883](https://claudeissues.com/issue/87883-claude-agents-json-reports-state-stopped-but-the-state-set-is-undocumented-and-h) : l'ensemble des valeurs de `state` n'est pas documenté.

### Tertiary (LOW confidence)
- Aucune source non vérifiée n'est utilisée comme fait ; les points non mesurés sont dans l'Assumptions Log (A12, A13).

Context7 n'a pas été utilisé : aucune bibliothèque externe n'entre dans la phase.

## Metadata

**Confidence breakdown :**
- Standard stack : HIGH, aucune dépendance, code lu.
- Architecture : HIGH sur les ancrages et jointures, MEDIUM sur la forme finale du transport de données (A6, A9) qui relève du plan.
- Pitfalls : HIGH, chaque pitfall est tiré d'un fait du code ou d'une règle du dépôt.
- Contrats de la 79 : MEDIUM, branche non fusionnée et amendée trois fois en un jour.
- `claude agents --json` : MEDIUM, sources tierces.

**Research date :** 2026-11-11
**Valid until :** 2026-11-25 (14 jours : les Phases 74, 79 et 80 sont en cours de cadrage et amendent leurs contrats ; relire `79-CONTEXT.md` avant chaque plan qui lit A15, A16, A20 ou C4/C5)

