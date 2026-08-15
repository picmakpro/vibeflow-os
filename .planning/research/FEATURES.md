# Feature Research — fiabilite-v1.0

**Domain:** Fiabilité/gouvernance d'un plugin Claude Code distribué (17 modules, engine d'install scopé, team-kernel)
**Researched:** 2026-08-15
**Confidence:** HIGH sur les patterns systèmes (package managers, locks, heartbeats — corroborés multi-sources) · MEDIUM sur l'écosystème plugins Claude Code (mouvant)

> Milestone SUBSÉQUENT : seules les 9 features NOUVELLES sont couvertes. L'existant (toggle
> install, team-kernel, gate armement↔précondition, ledger broken-windows, CI 5 gates) est
> traité comme fondation, pas re-recherché.

---

## Analyse par feature — comment les systèmes comparables font

### F1 — Portabilité Windows II (spec existante, priorité client)

**Comparables.** Le passage forme shell → forme exec est exactement l'histoire de Docker
`ENTRYPOINT` : la forme exec (vecteur d'arguments, pas de shell) est la recommandation
officielle car elle supprime le re-parsing des chemins — et, par définition, elle interdit les
constructions shell (`|| true`, redirections). Le launcher Windows `py -3` (lanceur à argument)
est la raison canonique pour laquelle une résolution Python doit être une **fonction**, pas une
variable — la spec l'a déjà intégré (§3.1). La neutralisation du stub Microsoft Store est un
problème documenté de tout outillage cross-platform (pyenv-win, VS Code le gèrent).

**Comportement attendu (état de l'art).**
- Résolution centralisée dans une lib unique, dérive interdite **par la machine** (checksum
  entre marqueurs — la spec le prévoit, c'est le pattern `size-limit`/gate, pas la convention).
- Migration de forme de hook : l'outil qui *écrit* la config apprend la nouvelle forme **avant**
  que quiconque ne l'émette — sinon triple casse documentée §1.3 (placeholder littéral, hook
  doublé, module non désinstallable). C'est l'équivalent du « reader before writer » des
  migrations de schéma (expand/contract).
- Codes de sortie : la traduction exit 3 (silence interne) → exit 0 (harness) est le pendant
  du précédent ESLint (exit 2 config fatale ≠ exit 1 findings) déjà cité par la spec.

**Classement.** Lot PYBIN = table stakes (3 fichiers, mécanique, défaut réel déjà divergé).
Lot HOOKS = table stakes sur (a) `merge-hooks.sh` apprend `args` + compat descendante, puis
(b) normalisation exit codes, puis (c) les 4 entrées dev — **l'ordre est le contrat**.
**Anti-feature :** livrer (c) avant (a) ; redéfinir `IS_WINDOWS` localement ; migrer
`guard-file-size.sh` avant que `vf-portable.sh` + hook doctor conductor n'existent (dépendance
dure vers la polarité gouvernance, §3.1).
**Complexité :** MEDIUM (PYBIN LOW, HOOKS MEDIUM — traverse `_internal/`, engage le parc).
**Dépendances :** contrat PR #29 (Willy), `_internal/merge-hooks.sh`, tests
`test-merge-hooks.sh` ; **point non attribué à trancher avant plan** : chemin absolu de `bash`
résolu à l'install (§3.2, trou d'affectation).

### F2 — Survie du ledger d'exigences à la clôture de jalon

**Comparables.** GitHub Milestones : fermer un milestone **ne ferme jamais** les issues
ouvertes — elles restent visibles et réassignables. Keep-a-Changelog : la section `Unreleased`
est **roulée**, jamais recopiée à la main. Les RTM (requirements traceability matrix) des
industries régulées imposent qu'aucune exigence ne disparaisse sans disposition explicite
(done / carried / dropped-with-rationale).

**Comportement attendu.** À la clôture : chaque case non cochée doit avoir un devenir explicite
et **machine-vérifié** — un gate qui diffe le ledger avant/après archivage et échoue si une
exigence non soldée a disparu sans trace. La dérive a été constatée **deux fois** parce que
l'opération est aujourd'hui un copier-coller humain : le remède comparable est toujours le même
(l'outil fait le roll-over, l'humain arbitre les exceptions).

**Classement.** Table stakes : roll-over outillé + gate de non-disparition dans le chemin
`gsd-complete-milestone`/`gsd-audit-milestone`. Différenciateur : trace `carried-from:` par
exigence (auditabilité type RTM). **Anti-feature :** re-copier à la main avec « plus de
vigilance » (déjà échoué 2×) ; bloquer la clôture sur exigences ouvertes (il faut pouvoir
clore avec des exigences *explicitement* reportées).
**Complexité :** LOW-MEDIUM. **Dépendances :** flux GSD de clôture (amont — vérifier ce que
`gsd-core` expose avant de sur-outiller localement, doctrine GSD-first), gates conductor.

### F3 — Budget d'instructions pour les fichiers d'agents distribués

**Comparables.** Les *performance budgets* front-end sont le modèle exact : `size-limit`,
`bundlesize`, Lighthouse `budgets.json` — un budget chiffré par artefact, mesuré en CI, avec
**ratchet** (on ne bloque que les régressions, on ne rougit pas l'existant d'un coup). Le repo
applique déjà ce pattern (ADR-029 : agents ≤ 250 L, bootstrap ≤ 2000 tokens ; précédent §7 de
la spec Windows II : « avertissement d'abord, blocage après »).

**Comportement attendu.** Budget par fichier distribué (tokens estimés, pas seulement lignes —
c'est le coût réel en contexte), rapport par fichier, baseline committée, échec CI sur
dépassement de la baseline. L'« étage d'alignement court » (Phase 25 héritée) est le pendant
qualitatif : les comparables (danger-js) montrent qu'un gate quantitatif + une checklist courte
battent un lint sémantique ambitieux.

**Classement.** Table stakes : mesure + gate + ratchet. Différenciateur : budget en tokens
(≈ mots × facteur, sans dépendance à un tokenizer — rester Bash portable ADR-054).
**Anti-feature :** blocage dur immédiat sur l'existant (gate rouge des semaines = CI ignorée,
précédent documenté §7 spec) ; tokenizer exact en dépendance lourde pour un budget qui n'a
besoin que d'un ordre de grandeur stable.
**Complexité :** LOW-MEDIUM. **Dépendances :** `check-density`/gates conductor existants, CI.

### F4 — Durcissement du driver-lock (2 contournements réels)

**Comparables.** Trois familles, trois leçons :
- **Terraform state lock** : advisory mais avec *takeover cérémoniel* — `force-unlock` exige
  l'**ID du lock**, preuve qu'on sait ce qu'on casse. Jamais d'auto-steal.
- **DynamoDB Lock Client / leases distribuées** : séparer **durée de lease** et **heartbeat**
  — lease longue (couvre une mission de plusieurs heures), heartbeat court (détection de
  vivacité en secondes/minutes). Résout directement la note mémoire « TTL 1800 s < durée d'un
  mandat » : un lock sans heartbeat récent est *suspect*, un lock dont la lease court est
  *vivant*, même vieux.
- **Fencing tokens** : un lock advisory ne suffit jamais seul ; il faut un point d'**enforcement
  côté ressource** qui rejette les écritures d'un porteur périmé. Les deux contournements
  observés (commit sous le lock d'autrui, checkout de branche en pleine mission) sont
  précisément des écritures non fencées.

**Comportement attendu.** Le point d'enforcement naturel ici est **git lui-même** : hooks
`pre-commit` et `post-checkout`/`pre-checkout` (le repo a déjà le précédent
`core.hooksPath scripts/hooks` pour `pre-push`) qui vérifient l'identité du porteur avant
d'autoriser commit/checkout dans l'arbre principal. Échappatoire explicite et tracée
(variable d'env ou takeover avec ID), jamais silencieuse.

**Classement.** Table stakes : (1) heartbeat séparé de la lease (renouvellement par le
manager), (2) enforcement commit+checkout via git hooks, (3) takeover explicite avec preuve
(ID du lock) + trace dans le ledger. Différenciateur : jeton de fence dans le trailer de
commit (audit post-mortem : quel commit sous quel mandat). **Anti-features :** auto-steal à
l'expiration du TTL (mémoire 2026-08-02 : lock périmé ≠ mission morte) ; enforcement qui casse
le flux solo sans échappatoire ; **compter sur un réglage settings local pour armer les hooks**
(régression #38 : un réglage non distribué ne voyage pas — l'armement doit suivre le gate
armement↔précondition existant).
**Complexité :** MEDIUM. **Dépendances :** `driver-lock.sh` (team-kernel/conductor),
`scripts/hooks/` existant, gate `lab-frais-arme` (pattern de précondition distribuée), engine
d'install (qui pose/câble les hooks → lien avec F6).

### F5 — Notifications de progression des missions managers longues

**Comparables.** La leçon unanime des orchestrateurs : **la détection de stall se fait par
absence de signal, jamais par auto-déclaration**. Airflow marque *zombie* une tâche dont le
heartbeat manque ; Step Functions tue une tâche qui dépasse `HeartbeatSeconds` sans
`sendTaskHeartbeat` ; Travis tuait un job après 10 min sans output ; les monitors externes de
cron (healthchecks.io) surveillent l'absence de ping. Le stall silencieux de 18 h est
exactement le cas que « notifier à la fin » ne couvre pas : un manager bloqué ne notifie rien.

**Comportement attendu.** Deux moitiés distinctes :
1. **Progression** (push) : le manager écrit un battement sur disque à chaque passage de nœud
   du DAG / verdict de juge / checkpoint — artefact inspectable, dans l'esprit des digests de
   mission existants — et émet une notification OS aux jalons choisis (`osascript` /
   `terminal-notifier`, précédent `stop-notify`).
2. **Stall** (watchdog) : un mécanisme **extérieur au manager** constate l'absence de battement
   au-delà d'un seuil et alerte. Sans cette moitié, le cas des 18 h reste ouvert.

**Classement.** Table stakes : battement fichier par nœud DAG + notification fin de mission +
détection d'absence (le watchdog est LA feature, pas le bonus). Différenciateur : granularité
configurable (fin seule vs jalons), halt conditions notifiées. **Anti-features :** notification
à chaque tour (spam — `stop-notify` couvre déjà ce besoin, ne pas le dupliquer) ; armement via
settings local non distribué (régression #38) ; auto-kill du manager sur stall (ADR-031 : on
signale, l'humain tranche).
**Complexité :** MEDIUM (le push est LOW ; le watchdog pose la question du vecteur — hook
SessionStart/périodique vs process — à trancher au cadrage). **Dépendances :** protocoles
managers (team-kernel), heartbeat du F4 (même battement peut servir les deux — synergie
forte), engine d'install pour la distribution, portabilité macOS/Linux (notification native).

### F6 — Manifeste d'install + `--dry-run` + nettoyage des chemins disparus (issue #20 fusionnée)

**Comparables.** C'est le problème le plus normalisé du lot :
- **Manifeste par paquet** : dpkg garde la liste exacte des fichiers posés (`dpkg -L`,
  `/var/lib/dpkg/info/*.list`) ; RPM a `%files` ; Homebrew écrit `INSTALL_RECEIPT.json` par
  keg. **À l'upgrade, les fichiers de l'ancienne liste absents de la nouvelle sont retirés**
  — c'est exactement le remède au bug réel (12 verbes-façades v1.x survivants à l'update).
- **Dry-run** : `apt-get -s`, `npm install --dry-run`, `rsync -n`, et surtout **`terraform
  plan`** — le standard d'or : le plan et l'apply partagent le **même moteur**, le plan est le
  même chemin de code avec l'écriture débranchée. Symboles `+`/`~`/`-` par ressource. L'issue
  #20 propose déjà ce format et ce principe (« brancher un mode annonce sans écrire sur les
  mêmes chemins »).
- **Fichiers modifiés par l'utilisateur** : dpkg ne remplace/supprime jamais silencieusement un
  *conffile* modifié — comparaison de hash, puis prompt. Le manifeste doit porter un hash par
  fichier posé pour distinguer « fichier VF intact » de « fichier modifié par le lab ».

**Comportement attendu.** Manifeste par module écrit à l'install (chemins + hash + version),
`--dry-run` sur `install`/`update` émettant le manifeste exact sans écrire, consommé par
l'étape 5 de `/vibeflow-install` et l'étape 4 de `/vf-calibrate` (présenter PUIS poser après
accord — c'est la demande terrain : revue croisée des hooks **avant** écriture, les hooks
s'exécutant hors couche de permissions). À l'update : suppression des chemins de l'ancien
manifeste absents du nouveau, avec backup, et refus/signalement si hash divergent.

**Classement.** Table stakes : manifeste posé, dry-run même-chemin-de-code, cleanup à l'update
avec backup, entrées `settings.json` (hooks mergés) représentées dans le manifeste — pas
seulement les fichiers. Différenciateur : hash par fichier façon conffile (aucun engine
d'install de plugin Claude Code observé ne le fait) ; `vf-calibrate` consommateur du même
manifeste. **Anti-features :** dry-run en chemin de code séparé (dérive plan/pose garantie —
l'anti-pattern que terraform a éliminé) ; suppression silencieuse de fichiers modifiés ;
manifeste « documentation » non lu par la machine (anti-hallucination : tout index exposé est
généré depuis le disque).
**Complexité :** MEDIUM. **Dépendances :** `vibeflow-update.sh` + `merge-hooks.sh`
(`_internal`) — **mêmes fichiers que le lot HOOKS de F1 : à séquencer, pas à paralléliser** ;
fondation requise par F8 (désinstallation propre de skills) et utile à F4/F5 (pose des hooks
d'enforcement/watchdog).

### F7 — Ré-armement `isolation: worktree` (précondition gsd-core > 1.10.0)

**Comparables.** Ré-activation de feature flag après fix upstream : la pratique sobre est le
**version gate** (pattern `engines`/`peerDependencies` npm, `required_version` terraform) — on
vérifie la **version installée qui contient le fix**, jamais le statut d'une issue. Issue close
≠ releasé ≠ installé (la charte le dit : « fix releasé ET installé, le gate de la Phase 28
exigera cette preuve »).

**Comportement attendu.** Gate machine : `gsd-core --version` > 1.10.0 vérifié à l'endroit où
l'isolation s'arme, sinon l'armement reste inerte — c'est l'application directe du pattern
armement↔précondition distribuée déjà construit (job `lab-frais-arme`). Ré-armement dans les
13 agents concernés = revert contrôlé du fix #38/#39, gaté.

**Classement.** Table stakes : précondition versionnée machine-vérifiée + preuve as-installed
(run réel en worktree avec merge-back vert) avant généralisation. Différenciateur : aucun —
c'est de la remise en service disciplinée. **Anti-features :** ré-armer sur foi de l'issue
close ; ré-armer sans le gate distribué (re-régression #38) ; porter le ré-armement dans la
Phase 28 (mémoire : la 28 porte le gate, jamais le ré-armement).
**Complexité :** LOW (mécanique) mais **bloquée par un événement externe** (release
gsd-core > 1.10.0) — à planifier comme phase conditionnelle en fin de milestone.
**Dépendances :** `ensure-deps.sh`/détection de version, gate Phase 28, les 13 agents touchés
par #39, dossier `.planning/research/2026-08-10-agents-paralleles-etat-de-l-art.md`.

### F8 — Skill-installer global (multi-agents, UX à toggles)

**Comparables.** L'écosystème a bougé depuis la capture (2026-06-04) : Claude Code a désormais
un marketplace natif (`/plugin`, scopes user/project, marketplaces tiers par repo Git), et des
annuaires communautaires agrègent des milliers de skills. Le modèle dominant : **plugin =
format de distribution, skill = contenu** ; l'installation par scope existe nativement.
VS Code (extensions par profil/workspace) et `mise`/`asdf` (outil global vs par-projet)
confirment le même schéma scope-aware que l'engine VF possède déjà.

**Comportement attendu.** Réutiliser la fondation existante (engine scope-aware +
`/vibeflow-install` à toggles) pour poser des **skills hors modules VF** disponibles à tous
les agents : catalogue, toggles, scope, et — grâce à F6 — manifeste + désinstallation propre.

**Classement.** Table stakes : toggles + scope + manifeste/uninstall (F6 requis).
Différenciateur réel : le rendu « disponible à **tous les agents** » (les skills d'un plugin ne
sont pas automatiquement dans le contexte des sous-agents — c'est le gap que VF peut fermer,
dans la ligne du bootstrap `agent_skills`). **Anti-features :** re-créer un marketplace
concurrent du `/plugin` natif (duplication, maintenance sans fin) ; mirrorer/curer des skills
tiers (charge de maintenance, qualité non gouvernée) ; toute résurgence de couche de synonymes
(interdit charte). Le périmètre défendable : **l'installeur/le câblage**, pas le catalogue.
**Complexité :** MEDIUM. **Dépendances :** **F6 dur** (manifeste), engine
`vibeflow-update.sh`, `/vibeflow-install`, `check-agents.sh` si des agents sont posés.

### F9 — Gaps de couverture vs catalogue `agency-agents`

**Comparables.** Le BACKLOG a déjà fait l'analyse : catalogue plat de 230+ personas sans
orchestration — modèle inverse du team-kernel. La valeur est la **taxonomie** (matrice de
couverture), pas le contenu. Priorisation déjà posée : (1) `web-test-team` (Playwright, calqué
sur `mobile-test-team`, Pattern 12 — comble un trou de NOTRE chaîne dev), (2) blueprints
Sales/Paid Media sur crochets existants, (3) `SupportFlow` si ouverture labs non-dev.

**Classement.** Table stakes : chaque ajout passe `check-agents.sh` (ADR-044) + ADR-029 + le
budget F3 (synergie : F3 devrait être livré avant pour gater les nouveaux agents dès leur
pose). Différenciateur : `web-test-team` (usage interne immédiat, seul test réel = mobile
aujourd'hui). **Anti-features :** import du catalogue plat ; copier-coller de personas
(densité incompatible) ; ouvrir les 3 pistes dans le même milestone (élargissement de
périmètre dans un milestone de *fiabilité* — tension à arbitrer, la piste 1 seule est
défendable comme dette de chaîne dev).
**Complexité :** MEDIUM (web-test-team) à HIGH (SupportFlow). **Dépendances :** team-kernel,
mobile-test-team comme moule, F3 (gate des nouveaux fichiers), sortie du statut expérimental
de mobile-test (requirement Actif de la charte — le moule doit être prouvé avant d'être copié).

---

## Feature Landscape (synthèse)

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| F1 lot PYBIN (3 fichiers → lib) | Défaut réel, divergence déjà constatée, gate Willy | LOW | Consommer le contrat PR #29, pas le réinventer |
| F1 lot HOOKS ordre (a)→(b)→(c) | Moteur avant émetteurs = non-régression du parc | MEDIUM | §1.3 : sinon hooks doublés + modules non désinstallables |
| F2 roll-over outillé + gate de non-disparition | Dérive humaine constatée 2× ; standard GitHub/RTM | LOW-MEDIUM | Dans le chemin de clôture de jalon |
| F3 budget mesuré + gate CI + ratchet | Pattern performance-budget établi ; ADR-029 déjà en place | LOW-MEDIUM | Avertissement d'abord, blocage après (précédent §7) |
| F4 heartbeat ≠ lease + enforcement git hooks + takeover tracé | 2 contournements réels ; advisory seul est prouvé insuffisant | MEDIUM | Enforcement au point d'écriture (commit/checkout) |
| F5 battement par nœud DAG + watchdog par absence | Stall 18 h : l'auto-déclaration ne détecte pas un bloqué | MEDIUM | Le watchdog est la feature, la notif est le confort |
| F6 manifeste + dry-run même-code + cleanup avec backup | dpkg/brew/terraform : problème résolu partout ailleurs ; demande terrain #20 | MEDIUM | Bug réel (verbes v1.x survivants) + revue hooks avant pose |
| F7 version gate machine (gsd-core > 1.10.0 installé) | Issue close ≠ releasé ≠ installé ; leçon #38 | LOW | Phase conditionnelle, dépend d'une release externe |
| F8 réutilisation toggles+scope+manifeste | La fondation existe ; uninstall sans manifeste = re-bug F6 | MEDIUM | F6 prérequis dur |
| F9 conformité ADR-044/029/F3 de tout nouvel agent | Gates existants non négociables | — | S'applique quel que soit le gap comblé |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| F6 hash par fichier (conffile-style) | Aucun engine de plugin observé ne protège les fichiers modifiés par le lab | LOW (sur F6) | Distinction « intact » vs « modifié » avant suppression |
| F4 jeton de fence en trailer de commit | Audit post-mortem : quel commit sous quel mandat | LOW (sur F4) | Unique dans l'écosystème agents observé |
| F5 granularité configurable + halt conditions notifiées | Mission longue pilotable à distance sans spam | LOW (sur F5) | Extension naturelle du battement |
| F8 skills rendus disponibles à TOUS les agents | Gap réel de l'écosystème (skills ⊄ contexte sous-agents) | MEDIUM | Ligne du bootstrap `agent_skills` existant |
| F2 trace `carried-from:` par exigence | Auditabilité RTM inter-jalons | LOW (sur F2) | |
| F9 `web-test-team` | Comble le trou test web de la propre chaîne dev | MEDIUM | Seule piste F9 alignée « fiabilité » |

### Anti-Features

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Migrer les `hooks.json` avant `merge-hooks.sh` | « C'est juste du JSON » | Parc cassé : hooks doublés, modules non désinstallables (§1.3) | Ordre (a)→(b)→(c) imposé |
| Auto-steal du lock à l'expiration TTL | « Lock périmé = mission morte » | Faux (constaté 2026-08-02) ; corruption si le porteur vit | Heartbeat court + takeover explicite avec ID |
| Notification à chaque tour / auto-kill sur stall | Visibilité maximale | Spam (couvert par `stop-notify`) ; ADR-031 violé | Battement DAG + watchdog advisory |
| Dry-run en chemin de code séparé | Plus vite à écrire | Dérive plan/pose garantie dans le temps | Même moteur, écriture débranchée (modèle terraform) |
| Suppression silencieuse de fichiers modifiés à l'update | Convergence « propre » | Perte de travail utilisateur | Hash conffile-style + backup + signalement |
| Armement de F4/F5 via settings local | Simple, immédiat | Ne voyage pas — régression #38 rejouée | Gate armement↔précondition distribuée existant |
| Ré-armer worktree sur issue close | « C'est fixé upstream » | Close ≠ releasé ≠ installé | Version gate + preuve as-installed |
| Marketplace de skills maison / mirroring tiers | « UX unifiée » | Duplique `/plugin` natif ; maintenance sans fin | Installeur/câblage seulement, catalogue = natif |
| Import du catalogue agency-agents | 230 personas gratuites | Densité ADR-029 incompatible, zéro gouvernance | Distiller la taxonomie, construire au moule VF |
| Blocage CI dur immédiat (F3, gate Willy) | Rigueur affichée | Gate rouge des semaines = CI ignorée | Ratchet / avertissement puis blocage au merge |

## Feature Dependencies

```
F6 (manifeste/dry-run) ──requires──> _internal (vibeflow-update.sh + merge-hooks.sh)
F1 lot HOOKS ──────────requires──> _internal (merge-hooks.sh apprend `args`)
        └── F1 et F6 touchent les MÊMES fichiers moteur → séquencer, ne pas paralléliser

F8 (skill-installer) ──requires──> F6 (manifeste = uninstall propre)
F4 (enforcement lock) ──requires──> pattern armement↔précondition (existant)
                      ──enhanced by──> F6 (pose/câblage des git hooks par l'engine)
F5 (watchdog) ──shares──> heartbeat de F4 (même battement, deux consommateurs)
              ──requires──> pattern armement↔précondition (existant)
F7 (worktree) ──requires──> release externe gsd-core > 1.10.0 + gate Phase 28
F9 (nouveaux agents) ──enhanced by──> F3 (budget gate les nouveaux fichiers dès la pose)
F9 web-test-team ──requires──> sortie du statut expérimental de mobile-test (moule prouvé)
F1 guard-file-size ──requires──> vf-portable.sh + hook doctor conductor (polarité Willy)
```

### Dependency Notes

- **F1 ⟂ F6 sur `_internal`** : la seule vraie contrainte d'ordonnancement interne du
  milestone. Faire apprendre `args` à `merge-hooks.sh` (F1a) et lui faire émettre un manifeste
  (F6) dans deux phases parallèles = conflit garanti sur le même fichier. Recommandation :
  une seule phase « moteur d'install » ou séquence stricte F1a → F6 (ou l'inverse).
- **F4/F5 partagent le battement** : le heartbeat que le manager écrit pour renouveler son
  lock EST le signal de vivacité que le watchdog surveille. Concevoir ensemble, livrer
  éventuellement séparément.
- **F7 est événementiel** : aucune date maîtrisée. Phase à précondition, en queue de milestone,
  jamais bloquante pour le reste.

## MVP Definition

### Launch With (v1 du milestone)

- [ ] F1 — Portabilité Windows II (PYBIN + HOOKS ordonné) — **demande client, prioritaire charte**
- [ ] F6 — Manifeste + dry-run + cleanup — demande terrain (#20), fondation de F8, corrige un bug réel
- [ ] F4 — Durcissement driver-lock — 2 contournements réels = dette de correction, pas de confort

### Add After Validation (v1.x)

- [ ] F2 — Survie du ledger — au plus tard AVANT la clôture de ce milestone (sinon 3e dérive)
- [ ] F3 — Budget d'instructions — avant F9 idéalement (gate les nouveaux agents)
- [ ] F5 — Notifications/watchdog — après F4 (réutilise le battement)
- [ ] F7 — Ré-armement worktree — dès que gsd-core > 1.10.0 est releasé ET installé

### Future Consideration (v2+ / fin de milestone si capacité)

- [ ] F8 — Skill-installer global — après F6, périmètre « câblage pas catalogue »
- [ ] F9 — Gap-fill — seule la piste `web-test-team` est alignée fiabilité ; Sales/Paid/Support
      = élargissement de périmètre, candidats naturels au report

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| F1 Windows II | HIGH (client) | MEDIUM | P1 |
| F6 Manifeste/dry-run/cleanup | HIGH (terrain + fondation) | MEDIUM | P1 |
| F4 Driver-lock | HIGH (correctness) | MEDIUM | P1 |
| F2 Ledger survivant | MEDIUM | LOW-MEDIUM | P2 (dur avant clôture) |
| F3 Budget instructions | MEDIUM | LOW-MEDIUM | P2 |
| F5 Notifications/watchdog | MEDIUM | MEDIUM | P2 |
| F7 Worktree re-arm | MEDIUM | LOW (gaté externe) | P2 conditionnelle |
| F8 Skill-installer | MEDIUM | MEDIUM | P3 |
| F9 Gap-fill (web-test-team) | MEDIUM | MEDIUM-HIGH | P3 |

## Competitor Feature Analysis

| Feature | dpkg/apt | Homebrew | terraform | Airflow/Step Functions | Notre approche |
|---------|----------|----------|-----------|------------------------|----------------|
| Manifeste fichiers | `.list` par paquet, retiré à l'upgrade | `INSTALL_RECEIPT.json` | state = manifeste | — | Manifeste par module + hash conffile-style |
| Dry-run | `apt-get -s` | `--dry-run` partiel | `plan` = même moteur que `apply` | — | Mode annonce sur les mêmes chemins d'écriture |
| Lock/lease | — | — | force-unlock avec ID | Lease + heartbeat séparés | Heartbeat court + takeover avec ID + fence git-hook |
| Stall detection | — | — | — | Zombie par absence de heartbeat | Watchdog par absence de battement DAG |
| Budget artefact | — | — | — | — | Ratchet type size-limit sur tokens estimés |

## Sources

- Spec interne : `docs/superpowers/specs/2026-08-02-portabilite-windows-ii-design.md` (lu intégralement)
- Issue terrain : [picmakpro/vibeflow-os#20](https://github.com/picmakpro/vibeflow-os/issues/20) (lue via `gh`)
- Backlog : `.planning/BACKLOG.md` (notifications, manifeste, skill-installer, agency-agents)
- Locks/leases : [Lease Pattern in Distributed Systems](https://singhajit.com/distributed-systems/lease/) · [The Fencing Gap](https://hackernoon.com/the-fencing-gap-why-your-distributed-lock-isnt-safe-and-how-to-fix-it) · [DynamoDB Lock Client — heartbeat vs lease](https://github.com/awslabs/amazon-dynamodb-lock-client/issues/34) · [AWS blog — Building Distributed Locks](https://aws.amazon.com/blogs/database/building-distributed-locks-with-the-dynamodb-lock-client/)
- Progression/stall : [Airflow Tasks (zombie/heartbeat)](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/tasks.html) · [Step Functions sendTaskHeartbeat](https://docs.aws.amazon.com/sdk-for-kotlin/api/latest/sfn/aws.sdk.kotlin.services.sfn/-sfn-client/send-task-heartbeat.html) · [monitor GitHub Actions par absence de ping](https://cronjobpro.com/guides/monitor-github-actions-scheduled-workflows)
- Package managers : [brew Manpage (cleanup/autoremove)](https://docs.brew.sh/Manpage) · connaissance vérifiée dpkg `-L`/conffiles, `apt purge`/`autoremove` ([guide](https://khimananda.com/blog/remove-ubuntu-packages-correctly))
- Écosystème Claude Code : [Plugin Marketplace Guide 2026](https://www.agensi.io/learn/claude-code-plugin-marketplace-guide) · [Marketplace & Skills Guide](https://www.alexcloudstar.com/blog/claude-code-plugin-marketplace-skills-2026/) — confiance MEDIUM (sources communautaires)

---
*Feature research for: fiabilite-v1.0 (vibeflow-os)*
*Researched: 2026-08-15*
