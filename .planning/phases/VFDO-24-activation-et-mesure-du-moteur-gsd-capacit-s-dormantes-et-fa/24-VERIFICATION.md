---
phase: VFDO-24-activation-et-mesure-du-moteur-gsd-capacit-s-dormantes-et-fa
verified: 2026-08-04T22:49:02Z
status: gaps_found
verdict: PASS PARTIEL
score: 11/12 constats du tableau de clôture vérifiés (M2 non livré) — 3 gaps transverses en sus
behavior_unverified: 0
overrides_applied: 0
diff_verified: fbdb300..012ce1b (90 commits, branche feat/phase-24-activation-moteur-gsd)
re_verification: null
gaps:
  - truth: "Le Goal ferme les routes qui mènent à un geste inerte — sans en ouvrir une"
    status: failed
    reason: >
      La phase a rendu MUET, sur le dépôt réel, le signal d'orientation de démarrage qu'elle
      prétend par ailleurs durcir. `check-dev-bootstrap.sh` borne la lecture du frontmatter de
      `.planning/STATE.md` à 60 lignes (soupape D-04, `:203-227`) ; ce frontmatter fermait à la
      ligne 56 sur `main` (`fbdb300`) et ferme à la ligne 97 sur `HEAD` (`012ce1b`). Discrimination
      jouée sur fixture, MÊME script, MÊME arbre de config, seul le STATE.md change :
      version `main` → rc=3 + « [gsd-engine] Projet piloté par GSD — milestone gsd-migration,
      phase 26 complete » ; version `HEAD` → rc=3 + « frontmatter illisible ou invalide — silence
      (D-04) », stdout VIDE. Le premier dépassement est attribuable au commit `05ec458`
      (« docs(24): etat — mission Phase 24 en pause sur checkpoint humain »), délimiteur porté à
      la ligne 64, puis 97 à HEAD. Le défaut EST connu — `.github/workflows/ci.yml:532-540` le
      décrit exactement — mais il n'est ni corrigé ni porté par un ledger : `WINDOWS.md` est à
      `open_count: 0`, `.planning/codebase/CONCERNS.md` n'en dit rien, `REQUIREMENTS.md` non plus.
      Il ne vit que dans un commentaire de CI. C'est le motif A8 du cadrage (« une entrée qui
      promet un geste inerte ») reproduit au niveau du signal de session.
    artifacts:
      - path: ".planning/STATE.md"
        issue: "frontmatter de 97 lignes (56 sur main) — au-delà de la garde anti-gel de 60 lignes"
      - path: "plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh"
        issue: "soupape D-04 atteinte sur l'arbre réel : le gate est armé mais rendu silencieux"
      - path: ".github/workflows/ci.yml"
        issue: "lignes 532-540 : le défaut est documenté en commentaire, jamais inscrit en dette"
    missing:
      - "Sortir les ~85 lignes de commentaire de mission du frontmatter de .planning/STATE.md (les déplacer sous le délimiteur fermant, ou dans .planning/missions/), pour repasser sous la garde de 60 lignes"
      - "Ou relever la borne de check-dev-bootstrap.sh et l'asserter dans test-check-dev-bootstrap.sh"
      - "Dans les deux cas : inscrire la dette au ledger (WINDOWS ou CONCERNS.md) tant qu'elle est ouverte — un commentaire de ci.yml n'est lu par aucun workflow"
  - truth: "M2 — les deux voies retenues le 2026-07-31 (acter en doctrine · signaler le descripteur en amont) sont livrées"
    status: failed
    reason: >
      Aucune des deux n'existe dans l'arbre. **Voie 1** — la doctrine à écrire (« sur ce runtime le
      parallélisme inter-nœuds porté par `vf-dev-manager` est le seul effectif, et le parallélisme
      intra-étape des vagues GSD est perdu par décision du moteur ») : balayage `awk` fichier par
      fichier sur les **870 fichiers suivis**, motifs `intra-.tape|inter-n.uds` → **14 occurrences,
      toutes dans `.planning/`** (ROADMAP, mission du 2026-07-31, 24-ARBITRAGES, 24-COLLISIONS),
      **zéro dans `plugin/` et zéro dans `docs/`**. `team-kernel.md:28-53` porte le descripteur
      (dont `backgroundDispatch: false`) au titre de M1, pas la conséquence doctrinale de M2.
      **Voie 2** — la remontée amont du descripteur : `.planning/upstream/` ne contient qu'un seul
      fichier, celui des 42 workflows aveugles aux workstreams (GSDA-19). Aucun brouillon, aucune
      référence d'issue sur `backgroundDispatch`. Corroboration : `M2` n'apparaît **pas une seule
      fois** dans `24-01-PLAN.md`, `24-10-PLAN.md` ni `24-10-SUMMARY.md` — les deux nœuds que le
      tableau de clôture désigne en colonne « Où » —, et **aucune des 22 exigences `GSDA` ne couvre
      M2** (zone 6 = GSDA-20/21/22 = M1 + M3). Les deux voies n'ont jamais été des tâches de plan.
    artifacts:
      - path: "plugin/conductor/references/team-kernel.md"
        issue: "porte le descripteur de dispatch (M1) mais aucune conséquence doctrinale sur le parallélisme (M2 voie 1)"
      - path: ".planning/upstream/"
        issue: "un seul fichier — workstreams ; rien sur backgroundDispatch (M2 voie 2)"
      - path: ".planning/ROADMAP.md"
        issue: "ligne 1602, tableau de clôture : « acté en doctrine (voie 1), remontée amont déposée (voie 2) | 24-01, 24-10 » — non étayé par ces deux nœuds"
    missing:
      - "Écrire la conséquence doctrinale de M2 là où un agent la lira (team-kernel.md ou mission-flow.md), pas seulement dans .planning/"
      - "Rédiger la remontée amont du descripteur `backgroundDispatch: false` au même gabarit que celle des workstreams (rédigée, non postée, ADR-031)"
      - "Ou recaler le tableau de clôture pour qu'il cesse d'affirmer deux livrables absents"
  - truth: "Le ledger d'exigences est soldé à la clôture de la phase"
    status: failed
    reason: >
      Les **22 identifiants distincts `GSDA-01..22`** de `.planning/REQUIREMENTS.md` (univers =
      ce seul fichier, comptés par `awk` + `sort -u`) sont **tous à `- [ ]`** : `0` coché, `0` en
      `[~]`, `22` vides. La table de mapping (`:568-589`) porte « Planned » sur les 22. Contraste
      immédiat dans le même fichier : les **10** exigences `GSDC` de la Phase 23 sont toutes
      `- [x]` avec « Done — plan 23-0N ». Deux entrées sont en outre **factuellement fausses au
      regard du config** : `GSDA-04` et `GSDA-05` sont décrites « **différé**, déclencheur objectif
      — **non activé** » alors que `.planning/config.json` porte `workflow.windows_enforce: true`
      et `hooks.workflow_guard: true`, dégel acté par ADR-066. Le ledger décrit un état que la
      phase a dépassé il y a plusieurs jours.
    artifacts:
      - path: ".planning/REQUIREMENTS.md"
        issue: "22/22 GSDA non cochées ; table de mapping « Planned » sur les 22 ; GSDA-04/05 décrites « non activé » contre le config"
    missing:
      - "Passer les 22 GSDA à [x] / [~] selon leur état réel, et la colonne de mapping de « Planned » à « Done »/« Partiel » avec le plan porteur"
      - "Recaler GSDA-01/04/05 sur ADR-066 (dégel), qui a levé le différé"
  - truth: "La phase est validée au sens Nyquist, comme le lab l'exige de lui-même"
    status: failed
    reason: >
      `.planning/config.json` porte `workflow.nyquist_validation: true`, et
      `plugin/dev-orchestrator/references/gsd-capabilities-index.md:199,211` rattache
      `gsd-validate-phase` et `gsd-nyquist-auditor` à la capability `nyquist` gouvernée par ce
      toggle — la capacité est donc **active**. Or **aucun `24-VALIDATION.md` n'existe** : balayage
      `ls .planning/phases/*/*VALIDATION*.md` → **2 fichiers**, ceux des Phases **20** et **23**,
      aucun pour la 24. Et `nyquist` compte **0 occurrence** sur les **31 fichiers** du dossier de
      phase (`awk` fichier par fichier, insensible à la casse). L'angle mort relevé sur la Phase 23
      n'est donc pas seulement reproduit : il est **aggravé** — la 23 avait au moins un
      `23-VALIDATION.md` en `status: validated` / `nyquist_compliant: false`, la 24 n'a rien.
      Une phase de 12 plans sur laquelle la continuité d'échantillonnage n'a jamais été posée.
    artifacts:
      - path: ".planning/phases/VFDO-24-activation-et-mesure-du-moteur-gsd-capacit-s-dormantes-et-fa/"
        issue: "aucun 24-VALIDATION.md ; 0 occurrence de « nyquist » sur les 31 fichiers de la phase"
      - path: ".planning/config.json"
        issue: "workflow.nyquist_validation: true — capacité active, jamais employée sur cette phase"
    missing:
      - "Lancer /gsd-validate-phase 24 (ou acter par écrit, ADR ou ligne de ROADMAP, que la validation Nyquist est renoncée pour cette phase et pourquoi) — le silence n'est pas une décision"
deferred:
  - truth: "Publier une release racine (bump VERSION/plugin.json/marketplace.json, tag annoté, release GitHub, check-release-tag.sh --remote ✓)"
    addressed_in: "Geste humain post-fusion, réservé à Samuel (CLAUDE.md § Discipline de release)"
    evidence: >
      Frontière **non franchie et vérifiée telle** : `git diff main..HEAD` sur les trois fichiers de
      la triade rend **0 ligne** ; `VERSION` = `v2.47.1`, valeur de `main`. C'est exactement le
      contrat écrit du plan 24-12 et de la note de fin de section ROADMAP. Ce n'est pas un manque.
warnings:
  - id: W1
    severity: documentaire — non bloquant
    statement: >
      La note de fin de section ROADMAP (`:1673-1676`) écrit encore que « le gate de sécurité reste
      **bloquant** (`24-SECURITY.md`, `threats_open: 1`) sur `T-24-02-01` ». **C'est périmé, et la
      fermeture est RÉELLE, pas cosmétique** — vérifié de première main, contrôle par contrôle,
      sans faire confiance au fichier : (1) `git show --numstat 7b96e34` → **1 fichier, 7
      insertions, 7 suppressions**, exactement ce que la mitigation réécrite annonce ; (2)
      `.planning/WINDOWS.md` compté par `awk` à **87 lignes avant (`7b96e34^`), 87 après
      (`7b96e34`), 87 aujourd'hui** ; (3) `d89a60e` est bien un commit antérieur et propre ; (4)
      recomptage indépendant du registre — sur les **51 lignes `T-24-*`** du fichier, **0** porte
      simultanément un statut `open` et une sévérité `high`/`critical`, donc `threats_open: 0` est
      **calculé-cohérent**, jamais posé pour satisfaire un gate. Le workflow amont
      (`ship.md:112-114`) ne lit que `threats_open` : le gate passerait. Seule la ROADMAP est
      en retard.
    suggestion: "Recaler la note de fin de § Phase 24 sur threats_open: 0 (hors périmètre de cette vérification — signalé, non corrigé)."
  - id: W2
    severity: contradiction interne au tableau qui « fait foi » — non bloquant
    statement: >
      Le tableau de clôture (`:1614`) écrit « **La décision A9, écrite : voie (c) bornée** ». Dans
      la numérotation du cadrage ROADMAP (`:1574-1582`), **(c) = « borner — workstreams réservés à
      un usage où les 42 workflows aveugles ne sont jamais sollicités, ce qui demande de dire
      lesquels »**. Or l'arbitrage et l'ADR disent l'inverse : `24-ARBITRAGES.md:265` porte
      « **VERDICT SAMUEL — OPTION C : ADOPTION** », et `docs/ADR.md:1930-1933` écrit « *Les
      workstreams du moteur GSD sont adoptés. Le mot est adoption* […] ni **l'usage restreint sous
      liste d'exclusions (option B)** », option B qui est précisément le « borner » du ROADMAP,
      rejeté comme intenable (`24-ARBITRAGES.md:339-340` : « maintenir à la main une liste de 42
      exclusions contre une cible qui bouge à chaque version amont : c'est un gate qu'on ne peut
      pas tenir »). Il n'existe donc **aucune liste d'exclusion de workflows hors périmètre**, et
      il ne doit pas en exister. Ce qui existe — et qui est **substantiel** — est le bornage par
      limites écrites : `plugin/dev-orchestrator/references/workstreams.md` (166 lignes, 4 risques
      chacun avec son geste, 10 workflows aveugles nommés, critère K2 déclaré) et ADR-069. La
      **condition dure « aucune partition tant qu'une phase est en vol »** est portée par
      `workstreams.md:159-166` **et** `docs/ADR.md:2087-2096`, **par écrit et non par un gate** —
      aucun script ne l'enforce ; le seul garde-fou machine adjacent est
      `check-workstream-pointer.sh`, qui échoue bruyamment quand un arbre partitionné n'a aucun
      canal résolvant (vérifié rc=1 sur fixture). Le mandat demandait si le bornage est écrit :
      la réponse est **oui pour les limites, non pour la liste d'exclusions — et c'est délibéré**,
      mais le tableau de clôture nomme mal sa propre décision.
    suggestion: "Remplacer « voie (c) bornée » par « option C de l'arbitrage — ADOPTION, avec quatre limites datées et une condition dure », pour que le tableau qui fait foi cesse de contredire l'ADR qu'il cite."
  - id: W3
    severity: reproductibilité d'un chiffre gravé — non bloquant
    statement: >
      ADR-067 (`docs/ADR.md:1669-1678`) grave « corpus nommé : les **400 derniers commits sans
      merge** du dépôt » → « sujet dépassant 72 caractères : **275 / 400 — 68 %** ». **Non
      reproductible.** Re-dérivation de première main sur exactement ce corpus
      (`git log --no-merges -n 400 --format=%s`, longueur en caractères puis en octets, `awk`) :
      **305 / 400 = 76 %** à `HEAD`, **302 / 400** au commit d'écriture de la zone 5 (`1fe5317`) ;
      la variante `>= 72` donne 311. Aucune lecture naturelle de la définition ne rend 275. Le
      second chiffre, lui, tient : **63 / 400 = 15 %** de types hors liste amont contre 65 / 400 =
      16 % annoncés (écart de régex sur le scope/`!`). **La conclusion de l'ADR n'est pas
      affectée — elle est renforcée** (76 % rejetés au lieu de 68 %). Mais c'est exactement le
      défaut qu'ADR-069 érige en règle deux entrées plus loin (« tout chiffre gravé dans une ADR
      porte son corpus, son critère d'inclusion nommé et **sa commande rejouable** ») : ADR-067
      nomme son corpus et ne porte pas sa commande.
    suggestion: "Ajouter à ADR-067 la commande rejouable, et recaler 275/400 sur la valeur qu'elle rend."
  - id: W4
    severity: portabilité du canal A2 — non bloquant
    statement: >
      Le slot PLANNER est peuplé avec la forme **globale nue** `global:software-architecture` /
      `global:audit-architecture`, **pas** la forme de plugin namespacée `global:<plugin>:<skill>`
      qu'annonçait le cadrage A2. Lu dans le moteur (`init.cjs:1765-1816`) : sans second `:`,
      `isNamespaced` est faux et la résolution est **système de fichiers**, vers le dossier de
      skills globales du compte ; un skill absent produit un `WARNING` sur stderr et est
      **silencieusement écarté**. Ici les deux résolvent — vérifié en exécution réelle,
      `gsd-tools agent-skills gsd-planner` rend le bloc `<agent_skills>` avec les deux entrées et
      **0 warning**. Mais la doctrine du lab n'atteint `gsd-planner` que **si ces deux skills sont
      posées dans le compte** : la dépendance est machine-locale, elle ne voyage pas avec le
      plugin.
    suggestion: "Écrire cette dépendance d'installation dans GSD-PIPELINE.md §10 (une ligne), ou basculer sur la forme namespacée si les deux skills sont distribuées par un plugin."
  - id: W5
    severity: preuve d'exécution — non bloquant
    statement: >
      Le tableau de clôture écrit que les quatre gates workstream sont « **exercés en CI** sur un
      arbre réellement partitionné » (A9) et que `check-capability-activation.sh` est « câblé au
      job `gates` de la CI » (A8). Le **câblage est réel** (`ci.yml:331-342` et `:361-596`), mais
      **le job n'a jamais tourné** : `git ls-remote --heads origin
      feat/phase-24-activation-moteur-gsd` → **0 référence**, la branche n'est pas poussée. Le
      fichier l'écrit d'ailleurs lui-même (`ci.yml:527-530` : « CE JOB N'AURA JAMAIS TOURNÉ POUR DE
      VRAI »). **J'ai donc rejoué les six assertions à la main**, sur une fixture partitionnée
      construite au même patron (`mktemp -d`, dépôt git initialisé et commité) — résultats en
      section « Gates rejoués ». Elles passent toutes et sont discriminantes. Le constat reste :
      « exercé en CI » sera vrai au premier push, pas avant.
    suggestion: "Aucune action de code — la formulation du tableau de clôture devance d'un push l'état des faits."
  - id: W6
    severity: cohérence de frontmatter — non bloquant
    statement: >
      `24-SECURITY.md` porte `status: draft` alors qu'il porte aussi `audited: 2026-08-05` et
      `threats_open: 0`, et qu'il relate un audit complet de 51 menaces. Le gate de `ship:pre` ne
      lit que `threats_open` (`ship.md:112-114`), donc rien ne bloque — mais un document audité et
      soldé qui se déclare brouillon est un piège de relecture. C'est le seul `*-SECURITY.md` du
      dépôt : aucun précédent de forme ne tranche.
    suggestion: "Passer status: draft → audited (ou la valeur que le gabarit amont prescrit)."
  - id: W7
    severity: sortie utilisateur — non bloquant
    statement: >
      `planning-context.sh` (rendu workstream-aware au plan 24-04, injecté à chaque session) imprime
      un en-tête inversé quand le fichier est plus court que la borne : « État courant du lab
      (**45 premières lignes sur 13** — lis le reste à la demande) ». Constaté en exécution réelle
      sur la fixture partitionnée (STATE.md de 13 lignes, borne d'extrait 45). Cosmétique, mais
      c'est du texte injecté en contexte de session à chaque démarrage.
    suggestion: "Borner l'affichage : n'annoncer « N premières lignes sur M » que si N < M."
  - id: W8
    severity: constat périmé dans l'état — non bloquant
    statement: >
      `.planning/STATE.md:37-38` inscrit comme reste à arbitrer : « ~70 fichiers suivis portent un
      chemin absolu contenant le nom d'utilisateur — dépôt PUBLIC, classe non couverte par le
      scrub ». **Mesuré faux aujourd'hui, deux fois** : `scripts/check-machine-paths.sh` sort en
      **rc=0** (« 870 fichier(s) suivi(s) balayé(s), aucun chemin absolu de machine ») et mon
      balayage indépendant `awk` du littéral de chemin de compte sur les **870 fichiers suivis**
      rend **0**. Soit le constat a été soldé sans être effacé, soit il visait une autre classe
      (par ex. `$HOME` interpolé) qu'il ne nomme pas.
    suggestion: "Effacer l'entrée ou la requalifier avec la classe exacte qu'elle vise."
behavior_unverified_items: []
human_verification: []
---

# Phase 24 : Activation et mesure du moteur GSD — Rapport de vérification

**Goal ROADMAP** : cesser de payer l'installation d'un moteur sans en prendre les bénéfices —
**activer** les capacités GSD déjà installées mais dormantes, **mesurer** les faits de runtime que
VibeFlow présume, et **fermer** les routes qui mènent à un geste inerte.

**Vérifié** : 2026-08-04T22:49:02Z · **Diff** : `fbdb300..012ce1b` (90 commits)
**Verdict** : **PASS PARTIEL** — l'axe **activer** est livré, éprouvé et substantiel (11 constats
sur 12) ; l'axe **mesurer** est amputé de M2, dont les deux voies retenues n'ont jamais été des
tâches de plan ; et l'axe **fermer** est **contredit par la phase elle-même**, qui a rendu muet le
signal d'orientation de session sur le dépôt réel.
**Re-vérification** : non — vérification initiale.

## Comment cette vérification a été conduite

Le tableau « État à la clôture » du ROADMAP (`:1599-1612`) fait foi : ses **12 lignes** (M1, M2, M3,
A1→A9) sont la liste de must-haves. Elles n'ont pas été recopiées — chacune affirme un état de
l'arbre, et chacune a été constatée sur pièce. Aucun `SUMMARY.md` n'a été accepté comme preuve.

**Univers déclarés** (ce dépôt a payé quatre fois le piège d'univers ; chaque nombre ci-dessous
porte le sien) :

| Univers | Définition exacte | Compte |
|---|---|---|
| Fichiers suivis | `git ls-files` | **870** |
| Fichiers modifiés par la phase | `git diff --name-only fbdb300..012ce1b` | **159** |
| Agents | `plugin/*/agents/*.md` (**25**) **+** `plugin/*/AGENT.md` (**6**) | **31** |
| Modules | `plugin/*/module.json` | **17** (dont **10** touchés) |
| Gates | `scripts/check-*.sh` (**3**) **+** `plugin/*/scripts/check-*.sh` (**17**) | **20** |
| Suites de test | `find plugin scripts -path '*/tests/test-*.sh'` (**récursif** — le glob à profondeur 1 n'en rend que 46) | **52** |
| Exigences de la phase | identifiants `GSDA-\d\d` distincts dans `.planning/REQUIREMENTS.md` | **22** |
| Workflows amont | `~/.claude/gsd-core/workflows/*.md`, profondeur 1, gsd-core **1.9.1** | **91** |

`grep` et `find` étant proxifiés et tronquants sur ce poste, tous les comptes ci-dessus sont faits
en `awk` lisant les fichiers lui-même, ou en `comm` sur listes triées, et croisés sur deux formes
quand le nombre est porteur.

## Vérité par constat du tableau de clôture

| # | Constat | Statut | Preuve |
|---|---|--------|--------|
| **M1** | profondeur de dispatch écrite dans les agents | ✓ VERIFIED | `plugin/conductor/references/team-kernel.md:28-53` — descripteur recopié verbatim (`maxDepth: 5`, `backgroundDispatch: false`, `subagentToolkit: "full"`), consommation nommée (**3 sur 5**), marge écrite **comme une permission** (« un worker peut légitimement dispatcher un sous-worker »), et **sa borne** (la marge n'autorise ni le contournement de la voie unique GSDC-05 ni celui des allowlists P12). Gardé par assertion machine : `test-check-agents.sh:1391-1414` (T76) exige les 5 littéraux et les 6 champs du descripteur. Suite rejouée : **81 OK / 0 KO**. |
| **M2** | acté en doctrine (voie 1) + remontée amont déposée (voie 2) | ✗ **FAILED** | **Ni l'un ni l'autre.** Balayage `awk` des **870 fichiers suivis** sur `intra-.tape\|inter-n.uds` → **14 hits, tous dans `.planning/`**, **0 dans `plugin/`, 0 dans `docs/`**. `.planning/upstream/` ne contient qu'un fichier (workstreams). `M2` est absent de `24-01-PLAN.md`, `24-10-PLAN.md` et `24-10-SUMMARY.md` — les deux nœuds cités en colonne « Où » — et aucune des 22 `GSDA` ne le couvre. Voir `gaps`. |
| **M3** | « `effort:` déclaré par aucun agent » → **31 sur 31** | ✓ VERIFIED | Balayage `awk` de `^effort:\s*(low\|medium\|high\|xhigh\|max)$` sur l'univers **25 + 6 = 31** : **31 porteurs, 0 manquant**. Gate durci et **discriminant par mutation réelle** : copie de `plugin/dev-orchestrator/agents/` avec `^effort:` retiré d'un fichier → `check-agents.sh --strict` sort en **rc=1**, « `vf-auditer.md` : effort absent — bareme par role requis ». Sur l'arbre réel, les **6** modules à dossier `agents/` sortent tous en **rc=0**. Réserve de forme : `24-01-SUMMARY.md:13,36` dit encore « les 25 agents » — le second balayage (`AGENT.md`) n'y est pas ; le tableau de clôture l'a corrigé, le SUMMARY non. |
| **A1** | `windows_enforce` **présent et à `true`** (dégel, ADR-066) | ✓ VERIFIED | `.planning/config.json` → `workflow.windows_enforce: true`. Ledger cohérent : `open_count: 0`, `waived_count: 1`, `fixed_count: 4`, `total_count: 5`. Fenêtre **#3** effectivement `"status": "waived"` avec motif écrit (recette XcodeBuildMCP structurellement infermable — aucun `.mcp.json`, aucun projet iOS). Intégrité du waive re-vérifiée indépendamment : commit `7b96e34` = **1 fichier / 7+ / 7−**, fichier à **87 lignes avant, après et aujourd'hui**. ADR-066 (`docs/ADR.md:1565-1653`) motive le dégel et pose le résiduel opposable (« la première prose écrite sous le ledger rouvre l'entrée »). |
| **A2** | slot **PLANNER** ouvert (2 skills) ; `gsd-executor` délibérément non câblé | ✓ VERIFIED | **Résolution éprouvée en exécution réelle**, pas lue : `gsd-tools agent-skills gsd-planner` rend le bloc `<agent_skills>` avec les **deux** entrées et **0 warning** (`buildAgentSkillsBlock` appelé directement rend le même bloc, `diagnostics.warnings = []`). Les deux `SKILL.md` existent. Slot consommé par **3** workflows amont sur 91 (`plan-phase.md`, `quick.md`, `verify-work.md`). **Le non-câblage de l'exécuteur est écrit, motivé et opposable** — `plugin/dev-orchestrator/references/GSD-PIPELINE.md:246-258` : l'injection ne vit que dans le prompt de dispatch d'`execute-phase.md:715`, `gsd-executor` est hors de l'allowlist de `vf-coder` depuis GSDC-05, et le repli inline n'emprunte aucun prompt de dispatch → « peupler le slot exécuteur serait un **vert à vide** ». Suivi d'une **interdiction** explicite et d'une charge de la preuve inversée. Ce n'est pas un abandon silencieux. Réserve de portabilité : **W4**. |
| **A3** | `tdd_mode` inchangé, **par décision écrite** | ✓ VERIFIED | Clé **absente** du config (défaut amont `false` s'applique). Refus écrit avec **quatre faits mesurés** : `GSD-PIPELINE.md:268-287` — `references/tdd.md` (330 l.) déjà injecté sans condition (`execute-phase.md:693`), hook `execute:post` `blocking: false` / `onError: skip`, ce que le toggle ajoute réellement, et l'inadéquation de l'heuristique amont à un dépôt bash + markdown. |
| **A4** | profils de contexte **refusés**, par décision écrite | ✓ VERIFIED | **ADR-068** (`docs/ADR.md:1717-1822`, enregistrée `:39`). Substantielle et **auto-corrective** : elle rectifie le nom de la clé porteuse (`context_profile`, et non `context:` comme l'écrivaient les trois fichiers livrés), refuse d'écrire « dépréciée » que l'amont n'a jamais dit, motive par « il n'y a rien à activer » (6 occurrences amont, toutes dans `docs/`), et pose un **déclencheur de réexamen objectif et sans date**. Clé `context` **absente** du config — cohérent. |
| **A5** | `workflow_guard` **à `true`** ; `hooks.community` **refusé** | ✓ VERIFIED | `.planning/config.json` → `hooks.workflow_guard: true`, `hooks.community` absent. Refus acté par **ADR-067** (`docs/ADR.md:1655-1716`, enregistrée `:38`) avec corpus nommé et les six types maison énumérés. Réserve sur un chiffre : **W3**. |
| **A6** | seuil inline **chiffré**, laissé au défaut | ✓ VERIFIED | **ADR-068 volet 2** (`docs/ADR.md:1824-1910`) : mesure sur les `*-PLAN.md`, regex du moteur, **4 / 28 = 14 %** sous le seuil, **mode à 3 tâches — juste au-dessus**, ré-instrumentée à 8 / 40 = 20 % après extension du corpus. Résout la contradiction apparente avec la doctrine de délégation (la doctrine vise l'**acteur**, le seuil se lit **dans** la brique). Clé non posée → défaut `2`. A6 n'est plus un « levier inconnu ». |
| **A7** | `intel.enabled: true` | ✓ VERIFIED | `.planning/config.json` → `intel: { enabled: true }`. Frontière écrite là où elle sera lue : `plugin/dev-orchestrator/references/docs-flow.md:73-93` — `.planning/codebase/` = jugement humain daté, lecteurs prescrits ; `.planning/intel/` = cinq JSON machine, fait dérivé rafraîchissable. La promesse publiée par notre propre doc (le mode `--query` comme l'un des deux modes normaux) devient tenue. |
| **A8** | refus indexés, entrées **conditionnelles**, trou fermé par un **gate** câblé en CI | ✓ VERIFIED | Entrées marquées à la forme littérale contractuelle : `intent-routing.md:104` (« `gsd-graphify` (conditionnelle : graphify.enabled) — refusée en Phase 24 ») et `:147` (idem `gsd-profile-user` / `profile-pipeline.enabled`). `gsd-capabilities-index.md` porte les toggles (`:196`, `:200`, `:213`). Gate câblé au job `gates` : `ci.yml:331-342`. **Discriminance prouvée par mutation réelle** — sur une copie de l'arbre, retrait du seul parenthétique `(conditionnelle : graphify.enabled)` de la ligne 104 → **rc=1**, « ECART regle 2bis : la brique « gsd-graphify » est promise par une entree de table alors que son toggle « graphify.enabled » est INACTIF ». Sur l'arbre réel : **rc=0**, univers balayé annoncé (23 toggles, 7 inactifs, 10 briques routées dont 6 sous toggle inactif, 2 toggles sous marqueur). Suite : **29 / 29**. |
| **A9** | outillage **workstream-aware**, exercé sur un arbre partitionné ; adoption non acquise | ✓ VERIFIED | Les **quatre** gates sont workstream-aware et **je les ai exercés moi-même** sur une fixture réellement partitionnée (section suivante) : les six assertions passent, la discriminance est réelle. Iron Law 2 révisée et **lue à l'ancre annoncée** : `plugin/conductor/AGENT.md:115`, avec sa **trace de révision** `:119-126` conservant la formulation antérieure. **ADR-069** (`docs/ADR.md:1921-2140`) est substantielle : prix de l'adoption tabulé, méthode avant les chiffres, quatre risques chacun avec sa mitigation, condition dure motivée, ADR-064 amendée. **Sa mesure se re-dérive exactement** : commande d'ADR-069 rejouée telle quelle → `atteinte=91`, `K2=7`, `en dur=45`, `aveugles=42`. Réserves de nommage et d'exécution : **W2**, **W5**. |

**Score : 11 / 12 constats du tableau de clôture vérifiés.**

## Le point qui coûte le plus — l'axe « fermer » retourné contre la phase

C'est le seul gap que je n'attendais pas, et c'est le plus sérieux.

`check-dev-bootstrap.sh` est le gate qui, au `SessionStart`, dit à l'agent où en est le lab. Sa
lecture du frontmatter de `.planning/STATE.md` est **bornée à 60 lignes** (soupape D-04,
`:203-227`) : au-delà, il ne rend **rien**, délibérément, pour ne jamais imprimer une valeur non
assainie.

Le frontmatter de `.planning/STATE.md` fermait à la **ligne 56** sur `main` (`fbdb300`, qui est
aussi le `merge-base`). Il ferme à la **ligne 97** sur `HEAD`. **+41 lignes**, toutes des blocs de
commentaire de mission Phase 24 (`:11-96`), le premier dépassement étant attribuable au commit
`05ec458` (« docs(24): etat — mission Phase 24 en pause sur checkpoint humain »), qui porte le
délimiteur à 64.

Discrimination jouée en zone temporaire, **même script, même `PROJECT.md`, même `config.json`,
même `ROADMAP.md`** — seul le `STATE.md` change :

| Fixture | rc | stdout |
|---|---|---|
| `STATE.md` de `main` (`fbdb300`) | 3 | `[gsd-engine] Projet piloté par GSD — milestone gsd-migration, phase 26 complete.` |
| `STATE.md` de `HEAD` (`012ce1b`) | 3 | **vide** — `[check-dev-bootstrap] frontmatter […] illisible ou invalide — silence (D-04).` |

Sur le dépôt réel, aujourd'hui, le signal d'orientation de session est **mort**.

Ce n'est pas une découverte : `ci.yml:532-540` décrit exactement le mécanisme, nomme la fiche
`F-35` comme périmée, et **choisit d'écrire l'assertion autour du défaut** plutôt que de le
corriger — pour de bonnes raisons de CI (asserter la sous-chaîne rougirait le job ; asserter
« stdout vide » graverait l'état dégradé comme norme). Le choix est défendable **pour l'assertion**.
Ce qui ne l'est pas, c'est que la dette n'existe **nulle part où un workflow la lira** :
`WINDOWS.md` est à `open_count: 0`, `.planning/codebase/CONCERNS.md` n'en dit pas un mot,
`REQUIREMENTS.md` non plus. Un commentaire de `ci.yml` n'est pas un ledger.

Le cadrage A8 nommait le motif : « une couverture verte peut masquer un geste mort ». La phase a
fermé ce trou pour la documentation (gate d'activation, mutation à l'appui) et l'a **rouvert d'un
cran plus haut**, sur son propre signal de démarrage.

## Gates rejoués sur `HEAD` — codes de sortie observés

Univers : **20** gates (`scripts/check-*.sh` = 3, `plugin/*/scripts/check-*.sh` = 17). Convention du
dépôt : `0` = conforme, `1` = écart, `3` = sain/silence, `64` = usage.

| Gate | rc | Verdict observé |
|---|---|---|
| `scripts/check-machine-paths.sh` | **0** | 870 fichiers suivis balayés, aucun chemin absolu de machine |
| `scripts/check-version-sync.sh` | **0** | triade 2.47.1, badges, **52 suites** ✓ |
| `scripts/check-release-tag.sh` | **0** | `VERSION=v2.47.1 ↔ tag v2.47.1` |
| `plugin/conductor/scripts/check-agents.sh --strict` (×6 modules) | **0** ×6 | conformes ; mutation « effort retiré » → **1** |
| `plugin/conductor/scripts/check-branch-claim.sh` | **3** | branche pilotée depuis cet arbre |
| `plugin/conductor/scripts/check-legacy.sh` | **0** | à jour (ADR-052/053) |
| `plugin/conductor/scripts/check-mission-invariants.sh` | **3** | tous les globs matchent |
| `plugin/conductor/scripts/check-overlaps.sh` | **0** | recouvrements connus (ADR-057) |
| `plugin/conductor/scripts/check-state-integrity.sh` | **0** | `.planning/STATE.md` conforme |
| `plugin/conductor/scripts/check-workstream-pointer.sh` | **3** | silence — dépôt non partitionné |
| `plugin/conductor/scripts/check-debug-research.sh` | **0** | rien à vérifier |
| `plugin/conductor/scripts/check-plugin-update.sh` | **0** | — |
| `plugin/consolidator/scripts/check-registres.sh` | **0** | rien à vérifier |
| `plugin/dev-orchestrator/scripts/check-capability-activation.sh` | **0** | conforme ; **mutation → 1** |
| `plugin/dev-orchestrator/scripts/check-dev-bootstrap.sh` | **3** | ⚠ **silence D-04** — voir le gap ci-dessus |
| `plugin/dev-orchestrator/scripts/check-doc-drift.sh` | **3** | 4 commits < seuil 20 |
| `plugin/dev-orchestrator/scripts/check-gsd-engine.sh` | **3** | moteur `@opengsd/gsd-core` détecté |
| `plugin/planning-core/scripts/check-planning-state.sh` | **0** | STATE.md frais |
| `plugin/software-architecture/scripts/check-file-size.sh` | **3** | usage (attend `--staged`/`--all`/fichiers) |

### Suites de la phase, rejouées

| Suite | Résultat |
|---|---|
| `test-check-agents.sh` | **81 OK / 0 KO** |
| `test-check-capability-activation.sh` | **29 OK / 0 KO** |
| `test-check-workstream-pointer.sh` | **24 ok / 0 ko** |
| `test-check-dev-bootstrap.sh` | **35 ok / 0 ko** |
| `test-check-state-integrity.sh` | **40 ok / 0 ko** |
| `test-planning-context-hardening.sh` | **38 passés / 0 échoués** |
| `test-workstream-policy.sh` | **14 ok / 0 ko / 0 skip** |
| `test-workstream-symlink-escape.sh` | **10 ok / 0 ko** |

### Le job CI workstream, rejoué à la main (il n'a jamais tourné — W5)

Fixture reconstruite au patron de `ci.yml:379-428` : `mktemp -d`, `.planning/workstreams/dev/`
peuplé, racine du `.planning` **vide** de `ROADMAP.md` et `STATE.md` (c'est ce qui rend la fixture
discriminante), dépôt git initialisé et commité.

| # | Assertion | Attendu | Obtenu |
|---|---|---|---|
| 1/6 | `check-dev-bootstrap` avec `GSD_WORKSTREAM=dev` | rc 3 + orientation gsd-engine | **rc=3** — « [gsd-engine] Projet piloté par GSD — milestone fixture, phase 1 en cours. » |
| 2/6 | `check-state-integrity` avec ws | rc 0 sur le fichier du compartiment | **rc=0** — « ✓ `.planning/workstreams/dev/STATE.md` conforme » |
| 3/6 | `planning-context` avec ws | rc 0, en-tête nommant le compartiment | **rc=0** — « STATE.md du workstream `dev` » |
| 4/6 | `check-workstream-pointer` avec ws | rc 0, canal nommé | **rc=0** — « résolu par le canal env (GSD_WORKSTREAM) […] composable avec ADR-064 » |
| 5/6 | `check-dev-bootstrap` **sans** ws (discriminance) | rc 0 + « feuille de route absente » | **rc=0** — « [bootstrap] démarrage inachevé : feuille de route absente » |
| 6/6 | `check-workstream-pointer` **sans** ws | rc 1 + remède + motif + ADR-064 | **rc=1** — « `.planning/` est PARTITIONNÉ mais aucun canal composable ne résout de workstream » |

Les six passent. **1/6 ≠ 5/6 et 4/6 ≠ 6/6** : la fixture discrimine réellement, ces gates ne sont
pas verts à vide. La mesure d'ADR-069 se re-dérive à l'identique (`atteinte=91`, `K2=7`,
`en dur=45`, `aveugles=42`).

## Couverture des exigences

Les **22** identifiants `GSDA-01..22` (univers = `.planning/REQUIREMENTS.md`) ont été confrontés au
code, pas à leur case.

| Exigence | Statut dans le code | Preuve |
|---|---|---|
| GSDA-01 | ✓ SATISFAITE (par dégel) | ADR-066 : prérequis déclaré **insatisfiable** (npm `latest` = 1.9.1), risque #2893 mesuré nul sur un `WINDOWS.md` sans prose, résiduel opposable écrit |
| GSDA-02 | ✓ SATISFAITE | slot résolu en exécution réelle, 0 warning ; portée réelle et **interdiction** écrites (`GSD-PIPELINE.md:246-258`) |
| GSDA-03 | ✓ SATISFAITE | clé absente ; refus + 4 faits mesurés (`GSD-PIPELINE.md:268-287`) |
| GSDA-04 | ✓ SATISFAITE | `windows_enforce: true` ; #3 `waived` avec motif ; intégrité du waive re-vérifiée (87/87/87, 7+/7−) |
| GSDA-05 | ✓ SATISFAITE | `hooks.workflow_guard: true`, aucune édition de `settings.json` |
| GSDA-06 | ✓ SATISFAITE (chiffre à recaler) | ADR-067 ; le taux gravé n'est pas reproductible → **W3**, conclusion inchangée |
| GSDA-07 | ✓ SATISFAITE | `intel.enabled: true` + frontière `docs-flow.md:73-93` |
| GSDA-08 | ✓ SATISFAITE | `intent-routing.md:104,147` conditionnelles ; index porteur des toggles |
| GSDA-09 | ✓ SATISFAITE | gate créé, câblé `ci.yml:331-342`, **discriminance par mutation** (rc=1), suite 29/29 |
| GSDA-10 | ✓ SATISFAITE | ADR-068 volet 1, factuellement auto-corrigée, déclencheur objectif |
| GSDA-11 | ✓ SATISFAITE | ADR-068 volet 2, 4/28 = 14 %, mode à 3, seuil laissé à 2 |
| GSDA-12 | ✓ SATISFAITE | Iron Law 2 révisée, `conductor/AGENT.md:115` + trace `:119-126` |
| GSDA-13 | ✓ SATISFAITE | assertions 1/6, 2/6, 5/6 rejouées ci-dessus |
| GSDA-14 | ✓ SATISFAITE | assertion 3/6 rejouée |
| GSDA-15 | ✓ SATISFAITE | `--ws`/`GSD_WORKSTREAM` portés par **2** agents sur 31 — `vf-dev-manager.md:34`, `vf-coder.md:42`, les deux du chemin de dev, périmètre écrit en ADR-069 ; référence de module `workstreams.md` (166 l.) ; **23** fichiers de `plugin/` mentionnent « workstream » contre **3** au cadrage |
| GSDA-16 | ✓ SATISFAITE | `check-workstream-pointer.sh` (assertions 4/6 et 6/6), suite 24/24 |
| GSDA-17 | ⚠ SATISFAITE EN CODE, **jamais exécutée** | `ci.yml:361-596` ; branche non poussée → **W5**. Les six assertions rejouées à la main passent |
| GSDA-18 | ✓ SATISFAITE | ADR-069, quatre risques + condition dure ; mesure re-dérivée à l'identique |
| GSDA-19 | ✓ SATISFAITE | `.planning/upstream/2026-08-04-workflows-aveugles-aux-workstreams.md`, **178 lignes**, bandeau « rédigé, non posté » (ADR-031) — exactement ce que l'exigence demande |
| GSDA-20 | ✓ SATISFAITE | `team-kernel.md:28-53` + garde T76 |
| GSDA-21 | ✓ SATISFAITE | 31/31 (l'exigence dit « 25 » — l'univers a été corrigé en cours de phase) |
| GSDA-22 | ✓ SATISFAITE | durcissement + mutation rc=1 |

**22 / 22 satisfaites dans le code.** Mais **0 / 22 soldées au ledger** : les 22 cases sont à
`- [ ]` et la table de mapping (`:568-589`) porte « Planned » sur les 22, dont deux entrées
(`GSDA-04`, `GSDA-05`) qui décrivent un différé que le config a levé. Voir `gaps`. Aucune exigence
orpheline : la ROADMAP annonce `GSDA-01 → GSDA-22`, les 22 sont réclamées par au moins un plan.

## M2 — pourquoi c'est un manque et pas une omission de rédaction

Le lot MESURE avait trois faits. M1 et M3 sont livrés, et bien. M2 avait été **mesuré** le
2026-07-31 (sondes horodatées, 91 % et 92 % de recouvrement) — ce travail est réel et n'est pas en
cause. Ce qui est en cause, ce sont les **deux voies retenues par arbitrage** sur cette mesure :

1. **Acter et documenter** que sur ce runtime le parallélisme inter-nœuds de `vf-dev-manager` est le
   seul effectif, et que celui, intra-étape, des vagues GSD est perdu par décision du moteur.
   → **Absent de `plugin/` et de `docs/`.** Le constat ne vit que dans `.planning/`, c'est-à-dire
   là où aucun agent ne le lira au moment de décider comment paralléliser. Le ROADMAP écrivait
   pourtant « écrire **en doctrine** », et qualifiait la voie de « gratuite, immédiate ».
2. **Signaler le descripteur en amont** (`backgroundDispatch: false` est *fail-closed*, non
   descriptif du runtime Claude Code), mesure horodatée à l'appui.
   → **Aucun artefact.** Le seul fichier de `.planning/upstream/` porte les workstreams. Le gabarit
   de forme (issue amont `#2598`) a bien été réutilisé — mais pour GSDA-19, pas pour M2.

Aucune des deux n'a été inscrite comme tâche : `M2` compte **zéro occurrence** dans `24-01-PLAN.md`,
`24-10-PLAN.md` et `24-10-SUMMARY.md`, et aucune des 22 exigences ne la porte. Le tableau de clôture
affirme donc deux livrables qui n'ont jamais eu de porteur. Sur un axe du Goal qui s'appelle
**mesurer**, c'est le seul des trois faits dont la conclusion n'a pas été rendue opposable.

## Densité (ADR-029) et anti-patterns

| Fichier touché | Lignes | Plafond | Statut |
|---|---|---|---|
| `plugin/dev-orchestrator/agents/vf-dev-manager.md` | **248** | 250 | ✓ — 2 lignes de marge |
| `plugin/dev-orchestrator/agents/vf-coder.md` | 107 | 250 | ✓ |
| `plugin/dev-orchestrator/references/workstreams.md` | 166 | — (référence) | ✓ |

Marqueurs de dette sur les **159** fichiers du diff, hors `.planning/` : **19 correspondances
`TBD|FIXME|XXX`, toutes des faux positifs de forme** — gabarits d'identifiants (`CLI-XXX`,
`EVAL-XXX`, `DEC-XXX`, `ADR-XXX`), un motif `mktemp … XXXXXX`, et deux chaînes de mutation de test
(`GSD_XXXXXXXXXX`). **Aucun marqueur de dette réel.**

Cohérence de distribution : **10** modules touchés, **10** `VERSION` bumpés, **10** `CHANGELOG.md`
mis à jour — correspondance exacte, aucun module sous-recensé (le plan 24-12 avait rattrapé
`kpi-analyst` et `validator`, invisibles au balayage `plugin/*/agents/`). `VERSION` ↔ `module.json`
cohérents sur les **17** modules, **0 écart**.

## Synthèse — ce qu'il reste à faire avant `/gsd-ship`

1. **Rendre la parole au gate de démarrage** (bloquant, et c'est l'axe « fermer » du Goal) : sortir
   les blocs de commentaire de mission du frontmatter de `.planning/STATE.md`, ou relever la borne
   de `check-dev-bootstrap.sh` **et l'asserter**. Puis inscrire la dette au ledger tant qu'elle est
   ouverte.
2. **Livrer M2**, ou recaler le tableau de clôture pour qu'il cesse d'affirmer deux livrables
   absents. Une ligne de doctrine dans `team-kernel.md` et un brouillon dans `.planning/upstream/`
   au gabarit déjà validé suffisent — c'est le coût que le ROADMAP lui-même qualifiait de « gratuit,
   immédiat ».
3. **Solder le ledger d'exigences** : 22 cases, la table de mapping, et le recalage de
   `GSDA-01/04/05` sur ADR-066.
4. **Trancher la validation Nyquist** : la lancer, ou écrire qu'on y renonce et pourquoi. Deux
   phases de suite sans, dont une sans document du tout, ce n'est plus un oubli.
5. **W1 / W2** (ROADMAP périmée sur `threats_open`, et « voie (c) bornée » qui contredit l'ADR
   qu'elle cite) — hors périmètre de cette vérification, signalés et non corrigés.
6. **W3** (chiffre d'ADR-067 non rejouable), **W4** (dépendance d'installation du canal A2),
   **W6** (`status: draft`), **W7** (« 45 premières lignes sur 13 »), **W8** (constat périmé dans
   `STATE.md`) — non bloquants.

**La release racine reste hors périmètre** : frontière vérifiée non franchie, `0` ligne d'écart
depuis `main` sur les trois fichiers de la triade. Geste humain gaté, conforme au contrat.

---

_Vérifié : 2026-08-04T22:49:02Z_
_Vérificateur : Claude (gsd-verifier) — analyse goal-backward ; gates, suites, mutations et fixture
partitionnée exécutés de première main, jamais lus dans un SUMMARY_
