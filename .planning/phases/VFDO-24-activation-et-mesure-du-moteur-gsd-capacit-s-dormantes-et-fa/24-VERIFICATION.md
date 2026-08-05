---
phase: VFDO-24-activation-et-mesure-du-moteur-gsd-capacit-s-dormantes-et-fa
verified: 2026-08-05T00:34:14Z
status: gaps_found
verdict: PASS PARTIEL — CI ROUGE sur la branche poussée, le ship reste bloqué
score: 10/12 constats du tableau de clôture vérifiés (M2 et A9 en échec) — 3 gaps transverses
behavior_unverified: 0
overrides_applied: 0
diff_verified: fbdb300..479eee9 (95 commits, branche feat/phase-24-activation-moteur-gsd)
re_verification:
  previous_verified: 2026-08-04T22:49:02Z
  previous_status: gaps_found
  previous_verdict: PASS PARTIEL
  previous_score: 11/12
  diff_since_previous: 012ce1b..479eee9 (5 commits — e639380, 795b984, 7e3c39c, f738e8c, 479eee9)
  head_note: >
    Le mandat annonçait `HEAD = f738e8c`. **C'est faux au moment de cette re-vérification** :
    `git rev-parse HEAD` rend **`479eee9`** (« docs(24): Pattern G — reveiller un worker coupe
    avant de le redispatcher »), un cinquième commit posé APRÈS la validation Nyquist. Il n'était
    visible ni dans `git log --oneline -12` passé par le proxy (troncature silencieuse), ni dans
    la somme des `git show --stat` des quatre commits annoncés — il a fallu croiser
    `git diff --name-only` et `git log -- <fichier>` en `git` direct pour le voir. Toutes les
    mesures ci-dessous portent sur `479eee9`.
  gaps_closed:
    - "Le Goal ferme les routes qui mènent à un geste inerte — sans en ouvrir une (garde NR>60 de check-dev-bootstrap.sh)"
    - "La phase est validée au sens Nyquist, comme le lab l'exige de lui-même"
  gaps_partially_closed:
    - "M2 — voie 1 (doctrine) LIVRÉE et substantielle ; voie 2 (remontée amont) toujours absente"
    - "Ledger d'exigences GSDA — les 22 cases sont soldées ; la table de mapping :568-589 est INTACTE"
  gaps_remaining:
    - "M2 voie 2 — remontée amont du descripteur backgroundDispatch"
    - "Table de mapping GSDA — 22× « Planned », dont GSDA-04/05 « non activé » contre le config"
  gaps_new:
    - "La CI a TOURNÉ pour de vrai et elle est ROUGE — 2 jobs en échec sur le commit de HEAD"
  regressions:
    - >
      R1 (`ci.yml`, non-régression racine) est passée de **verte à vide** à **rouge
      discriminante** du fait du commit de fermeture du gap 1 (`795b984`). Le commentaire de
      `ci.yml:551-557` avait mesuré et écrit que la comparaison était vide (`len_sans=0
      len_avec=0`) tant que le signal de démarrage était muet. Le signal restauré, R1 mesure enfin
      quelque chose — et rend **écart**. Ce n'est pas la fermeture du gap 1 qui a cassé R1 : c'est
      elle qui a rendu R1 capable de dire non.
  warnings_resolved: [W2, W5, W8]
gaps:
  - truth: "M2 — les deux voies retenues le 2026-07-31 (acter en doctrine · signaler le descripteur en amont) sont livrées"
    status: partial
    reason: >
      **Voie 1 : LIVRÉE, et bien.** `plugin/conductor/references/team-kernel.md:55-89` (commit
      `7e3c39c`, +35 lignes) porte désormais la conséquence doctrinale, **dans `plugin/`, là où un
      agent la lira** : « le parallélisme **intra-étape** […] est **perdu**, et le parallélisme
      **inter-nœuds** porté par la frontière `ready` de `vf-dev-manager` est le **seul effectif** ».
      Elle est opérationnelle, pas décorative — quatre conséquences prescriptives pour un manager
      (« n'attendez aucun gain de parallélisme d'un découpage en plans multiples au sein d'une même
      étape », « sérialisation observée ≠ panne »), le renvoi à la mission horodatée sans recopier
      ses chiffres, et le rappel que `claude_orchestration` reste un opt-in. Le gap est levé sur ce
      volet.
      **Voie 2 : TOUJOURS ABSENTE.** Balayage `awk` fichier par fichier du motif
      `backgroundDispatch` sur les **872 fichiers suivis** (`git ls-files`) → **24 occurrences**,
      dont **0 dans `.planning/upstream/`**. Ce dossier contient toujours **un seul fichier**,
      celui des 42 workflows aveugles (GSDA-19). Aucun brouillon, aucune référence d'issue sur le
      descripteur. Et le tableau qui « fait foi » (`.planning/ROADMAP.md:1622`) écrit **toujours**
      « acté en doctrine (voie 1), **remontée amont déposée (voie 2)** » — cette ligne n'a pas été
      touchée par `7e3c39c`, dont le diff sur le ROADMAP se limite à l'encadré de lettrage A9 et à
      la ligne A9. Aucune des deux sorties offertes (livrer, ou recaler le tableau) n'a été prise.
    artifacts:
      - path: ".planning/upstream/"
        issue: "un seul fichier (workstreams) ; 0 occurrence de backgroundDispatch (M2 voie 2)"
      - path: ".planning/ROADMAP.md"
        issue: "ligne 1622 — affirme toujours « remontée amont déposée (voie 2) », non étayé par l'arbre"
    missing:
      - "Rédiger la remontée amont du descripteur `backgroundDispatch: false` au gabarit de `.planning/upstream/2026-08-04-workflows-aveugles-aux-workstreams.md` (rédigée, non postée, ADR-031)"
      - "Ou recaler `.planning/ROADMAP.md:1622` pour qu'il cesse d'affirmer un livrable absent"
  - truth: "Le ledger d'exigences est soldé à la clôture de la phase"
    status: partial
    reason: >
      **Moitié 1 : SOLDÉE.** Les **22** identifiants `GSDA-01..22` sont **tous à `- [x]`**
      (recompte `awk` : `x=22`, aucun `[ ]`, aucun `[~]`). Le commit `7e3c39c` compte exactement
      **22 hunks d'une ligne**, tous des bascules de case, et les corps d'exigence ont été
      recalés : `GSDA-04` lit désormais « `workflow.windows_enforce` **est activé** » là où il
      décrivait un différé.
      **Moitié 2 : INTACTE.** La table de mapping `.planning/REQUIREMENTS.md:568-589` n'a reçu
      **aucun hunk** — les **22** lignes portent toujours « **Planned** », et **`GSDA-04` / `GSDA-05`
      portent toujours « **différé**, déclencheur objectif — **non activé** »** alors que
      `.planning/config.json` porte `workflow.windows_enforce: true` et `hooks.workflow_guard: true`
      (relu à l'instant). Le même fichier se contredit désormais **à 200 lignes d'écart** : la case
      dit fait, la table dit planifié et non activé. Contraste inchangé avec la Phase 23, dont les
      10 `GSDC` portent « Done — plan 23-0N » (et un « Partiel » motivé pour `GSDC-08`).
    artifacts:
      - path: ".planning/REQUIREMENTS.md"
        issue: "table :568-589 — 22× « Planned » ; GSDA-04/05 « non activé » contre le config ; contredit les 22 cases [x] du même fichier"
    missing:
      - "Passer la colonne de mapping de « Planned » à « Done »/« Partiel » avec le plan porteur, sur les 22 lignes"
      - "Effacer la glose « différé — non activé » de GSDA-04 et GSDA-05 (ADR-066 a levé le différé)"
  - truth: "L'outillage workstream est exercé en CI, et la CI de la branche certifie la phase"
    status: failed
    reason: >
      **Fait nouveau et décisif : la branche est POUSSÉE et la CI a TOURNÉ.**
      `git ls-remote --heads origin feat/phase-24-activation-moteur-gsd` rend **1 référence**,
      identique à `HEAD` (`479eee9…`), et la PR **#34** est ouverte. Le warning **W5** de la
      vérification initiale (« ce job n'aura jamais tourné pour de vrai ») est donc levé — mais ce
      que la CI dit maintenant qu'elle parle est **rouge**, et sur les deux jobs qui portent la
      phase. Sur le run du commit de `HEAD` (`30963489338`, jobs `92172314339` et `92172314385`),
      relu de première main via `gh run view --log-failed`, jamais via un rapport :
      **(1) Job « Gates de qualité (mode strict) » → ÉCHEC.** L'étape « Gates workstream-aware sur
      un arbre RÉELLEMENT partitionné + non-régression racine » sort en 1. Verdicts observés :
      les **six** assertions de capacité **PASSENT sur le runner** (`1/6 rc=3 · 2/6 rc=0 · 3/6 rc=0
      · 4/6 rc=0 · 5/6 rc=0 · 6/6 rc=1`) — c'est un gain réel et il faut le dire. Mais le bloc de
      non-régression racine échoue : `== R1 check-dev-bootstrap racine : rc(sans)=3 rc(avec)=3,
      sorties de 243 et 356 octet(s) ==`, annotation `::error` « la sortie CHANGE selon
      GSD_WORKSTREAM sur un arbre NON partitionné — la résolution de workstream a fui hors de son
      domaine ». `BILAN : 1 écart(s)`. **Reproduit localement** : le delta est **une seule ligne de
      diagnostic sur stderr** — « workstream « dev » résolu mais ./.planning/workstreams/dev absent
      — lecture sur la racine ». La résolution ne fuit donc PAS : elle retombe correctement sur la
      racine et le dit. C'est l'assertion R1 qui est trop stricte (égalité d'octets sur un canal
      **fusionné** stdout+stderr, ce qui interdit toute ligne de diagnostic). Mais le fait
      opposable reste : **le job est rouge**.
      **(2) Job « Suites de tests (découverte non vide) » → ÉCHEC.** `52 suite(s) découverte(s)`,
      un seul cas rouge : `✗ A5d borne du canal nominal — long: rc=0 raison= nom=[] / court: rc=0
      nom=[aaaa]` (`plugin/planning-core/scripts/tests/test-workstream-policy.sh:160-185`). Ce cas
      est **vert sur ce poste** (`14 ok / 0 ko`, rejoué) et **rouge sur le runner Linux**. Lu dans
      le code : `workstream-policy.sh:286-290` borne bien la valeur (`VF_WS_VALUE_MAX_BYTES=4096`,
      raison `valeur-trop-longue`, `return 2`), mais sur le runner la fonction rend `rc=0` avec un
      nom **vide** — soit la branche `:278` `[ -n "$raw" ] || return 0` : la valeur de 200 000
      octets **n'est jamais arrivée** jusqu'à la borne. La borne de sûreté du canal nominal
      `GSD_WORKSTREAM` est donc **non prouvée sur Linux** : la sonde censée l'établir emprunte un
      autre chemin et n'assure rien. C'est exactement la classe « vert chez moi, rouge en CI » que
      la Phase 24 s'était donné pour objet de fermer.
    artifacts:
      - path: ".github/workflows/ci.yml"
        issue: "assertion R1 — égalité d'octets sur stdout+stderr fusionnés, incompatible avec toute ligne de diagnostic ; rouge depuis 795b984"
      - path: "plugin/planning-core/scripts/tests/test-workstream-policy.sh"
        issue: "cas A5d vert sur macOS, rouge sur le runner Linux — la borne du canal nominal n'y est pas exercée"
      - path: "plugin/planning-core/scripts/workstream-policy.sh"
        issue: "borne :286-290 non atteinte sur Linux (raw vide, sortie par :278) — la valeur démesurée ne parvient pas à la garde"
    missing:
      - "Rendre R1 opposable sans être fausse : comparer stdout seul et asserter l'invariance du DIAGNOSTIC séparément, ou tolérer explicitement la ligne « workstream résolu mais … absent — lecture sur la racine »"
      - "Diagnostiquer pourquoi GSD_WORKSTREAM n'atteint pas la borne :286 sur Linux (limite MAX_ARG_STRLEN / substitution de commande dans la chaîne de résolution), puis rendre le cas A5d portable — ou la borne elle-même"
      - "Ne pas fusionner : tant que ces deux points ne sont pas soldés, la phase ne peut pas affirmer « exercés en CI » comme un acquis vert"
deferred:
  - truth: "Publier une release racine (bump VERSION/plugin.json/marketplace.json, tag annoté, release GitHub, check-release-tag.sh --remote ✓)"
    addressed_in: "Geste humain post-fusion, réservé à Samuel (CLAUDE.md § Discipline de release)"
    evidence: >
      Frontière **toujours non franchie et re-vérifiée telle** : `git diff --stat main..HEAD` sur
      les trois fichiers de la triade rend **0 ligne** ; `VERSION` = `v2.47.1`, valeur de `main` ;
      `scripts/check-release-tag.sh` sort en **rc=0**. Ce n'est pas un manque.
warnings:
  - id: W1
    status: toujours ouvert
    severity: fait périmé dans le document qui fait foi — non bloquant
    statement: >
      La note de fin de section ROADMAP (`:1697-1700`) écrit toujours que « le gate de sécurité
      reste **bloquant** (`24-SECURITY.md`, `threats_open: 1`) sur `T-24-02-01` ». **Périmé, et la
      fermeture est réelle** — recomptée indépendamment aujourd'hui, colonne par colonne et non par
      recherche de mot (« open » apparaît dans la prose des mitigations, ce qui produit un faux
      positif si on lit la ligne entière) : sur les **51** lignes `T-24-*` du registre,
      **31 high closed · 13 medium closed · 4 medium open · 3 low closed**, soit **0** menace
      ouverte de sévérité ≥ `high` (seuil `security_block_on` du lab). `threats_open: 0` est
      calculé-cohérent. Le gate amont (`ship.md:112`) ne lit que ce champ : il passerait.
    suggestion: "Recaler la note de fin de § Phase 24 sur threats_open: 0."
  - id: W2
    status: RÉSOLU
    severity: —
    statement: >
      Le contresens de lettrage A9 est **soldé** (`7e3c39c`). Le ROADMAP porte un encadré
      « Lettrage » (`:1584-1602`) avec table de correspondance et la règle « ne jamais désigner une
      voie A9 par une lettre nue » ; `24-ARBITRAGES.md:265-282` porte l'encadré symétrique et
      déclare son propre lettrage normatif ; la ligne de décision (`:1634-1638`) écrit désormais
      « **ADOPTION — option C de l'arbitrage** […] soit la voie (a) du lettrage historique », et
      nomme l'option B (= voie `(c)`) comme **explicitement rejetée**. Conforme à ADR-069
      (`docs/ADR.md:1930-1933`) et au verdict de Samuel. La décision est bien l'**adoption**.
  - id: W3
    status: toujours ouvert
    severity: reproductibilité d'un chiffre gravé — non bloquant
    statement: >
      ADR-067 (`docs/ADR.md:1671-1677`) grave « les **400 derniers commits sans merge** » →
      « sujet dépassant 72 caractères : **275 / 400 — 68 %** ». **Toujours non reproductible.**
      Re-dérivation de première main sur exactement ce corpus (`git log --no-merges -n 400
      --format=%s`, longueur en caractères, `awk`) : **308 / 400 = 77 %** à `HEAD` (305 à la
      vérification initiale — le corpus a glissé de 4 commits, la conclusion pas) ; variante
      `>= 72` → 314. `docs/ADR.md` n'a reçu depuis qu'**un seul hunk d'une ligne** (correction du
      chemin de `check-dev-bootstrap.sh` dans le tableau de livrables d'ADR-069) : le chiffre n'a
      pas été touché. **La conclusion de l'ADR reste renforcée, pas affaiblie.** Corollaire mesuré
      par `24-VALIDATION.md` §G2 : l'assertion `<automated>` du plan 24-02 pin `69 %`, l'ADR écrit
      `68 %`, et la mesure rend `77 %` — trois valeurs, aucune commande rejouable.
    suggestion: "Ajouter à ADR-067 la commande rejouable qu'ADR-069 exige, et recaler 275/400 sur ce qu'elle rend."
  - id: W4
    status: toujours ouvert
    severity: portabilité du canal A2 — non bloquant
    statement: >
      Le slot PLANNER reste peuplé à la forme **globale nue** (`global:software-architecture`,
      `global:audit-architecture` — relu dans `.planning/config.json`), pas à la forme namespacée
      `global:<plugin>:<skill>`. La résolution est donc système de fichiers vers le dossier de
      skills du compte, et un skill absent est **silencieusement écarté** après un `WARNING` sur
      stderr. La dépendance est machine-locale : elle ne voyage pas avec le plugin. Non re-testé en
      exécution cette fois — `gsd-tools` n'est pas sur le `PATH` de ce shell — mais l'exécution
      réelle de la vérification initiale (bloc `<agent_skills>` rendu, 2 entrées, 0 warning) n'est
      pas remise en cause : le config n'a pas changé.
    suggestion: "Écrire cette dépendance d'installation dans GSD-PIPELINE.md §10, ou basculer sur la forme namespacée."
  - id: W5
    status: RÉSOLU — et il ouvre le gap CI
    severity: —
    statement: >
      « Le job n'a jamais tourné » n'est **plus vrai** : la branche est poussée
      (`git ls-remote` → 1 référence, `479eee9…`), la PR #34 est ouverte, et **six runs** existent
      sur la branche. Les **six assertions de capacité workstream** sont donc désormais
      **réellement exercées sur un runner GitHub**, et elles **passent** — c'est un acquis dur que
      la vérification initiale ne pouvait qu'approcher par fixture locale. La contrepartie est le
      gap 3 ci-dessus : le même job échoue sur sa non-régression racine, et la suite
      `test-workstream-policy.sh` échoue sur Linux. La CI a cessé d'être une promesse ; elle est
      devenue un verdict, et il est rouge.
  - id: W6
    status: toujours ouvert
    severity: cohérence de frontmatter — non bloquant
    statement: >
      `24-SECURITY.md` porte toujours `status: draft` avec `audited: 2026-08-05` et
      `threats_open: 0`, pour un registre de 51 menaces intégralement instruit. Le gate de
      `ship:pre` ne lit que `threats_open` — rien ne bloque — mais un document audité et soldé qui
      se déclare brouillon est un piège de relecture.
    suggestion: "Passer status: draft → audited."
  - id: W7
    status: toujours ouvert
    severity: sortie utilisateur — non bloquant
    statement: >
      `plugin/planning-core/scripts/planning-context.sh:183` imprime toujours l'en-tête sans
      borner : `"État courant du lab (${MAX_LINES} premières lignes sur ${total} …)"`, ce qui rend
      « 45 premières lignes sur 13 » quand le fichier est plus court que l'extrait. Texte injecté
      en contexte à chaque `SessionStart`.
    suggestion: "N'annoncer « N premières lignes sur M » que si N < M."
  - id: W8
    status: RÉSOLU
    severity: —
    statement: >
      Le constat périmé « ~70 fichiers suivis portent un chemin absolu contenant le nom
      d'utilisateur » a **disparu de `.planning/STATE.md`** avec la compression du frontmatter
      (`795b984`) — balayage `awk` du motif sur le fichier entier : plus aucune occurrence de ce
      constat. Le fait qu'il décrivait est par ailleurs re-mesuré faux :
      `scripts/check-machine-paths.sh` sort en **rc=0** (« 872 fichier(s) suivi(s) balayé(s), aucun
      chemin absolu de machine »).
  - id: W9
    status: nouveau — résiduel de la fermeture du gap 1
    severity: marge nulle et rationnel périmé — non bloquant
    statement: >
      La fermeture du gap 1 est **réelle et vérifiée par discrimination**, mais elle laisse
      **zéro marge**. Le délimiteur fermant du frontmatter de `.planning/STATE.md` est **exactement
      à la ligne 60**, et la garde de `check-dev-bootstrap.sh:215` est `NR > 60 { exit }` : une
      seule ligne de plus et le signal se retait. **Aucun garde-fou machine** ne surveille cette
      borne — `check-state-integrity.sh` (rc=0) ne mesure que la non-régression des compteurs, et
      la suite `test-check-dev-bootstrap.sh` (35 cas) n'a **aucun cas de dépassement de borne** (ses
      trois cas D-04 couvrent l'absence de fichier, la ligne 1 non conforme et une clé manquante).
      Second point : le commentaire de `ci.yml:532-540` et `:551-557` est désormais **factuellement
      faux** — il écrit « le frontmatter de .planning/STATE.md fait 81 lignes », « stdout VIDE »,
      « `len_sans=0 len_avec=0` ». Un relecteur qui s'y fie conclura que R1 est vide, alors que R1
      est précisément ce qui rougit aujourd'hui.
    suggestion: "Ajouter un cas « frontmatter de 61 lignes → silence » à test-check-dev-bootstrap.sh, et recaler le rationnel de ci.yml sur l'état réel."
  - id: W10
    status: nouveau
    severity: traçabilité de distribution — non bloquant
    statement: >
      Deux modules ont reçu du **contenu distribué après leur bump**, sans entrée de CHANGELOG :
      `plugin/conductor/references/team-kernel.md` **+35 lignes** (`7e3c39c`, la doctrine M2) et
      `plugin/dev-orchestrator/references/mission-flow.md` **+26** / `agents/vf-dev-manager.md`
      **+2** (`479eee9`, Pattern G). Or `plugin/conductor/VERSION` (`v1.20.0`) et
      `plugin/dev-orchestrator/VERSION` (`v2.12.0`) ont été figés au commit `2b95db2` du plan
      24-12. La « correspondance exacte 10 touchés / 10 bumpés / 10 CHANGELOG » que la clôture
      revendiquait n'est **plus vraie**. `scripts/check-version-sync.sh` sort en **rc=0** : il
      vérifie la cohérence de la triade, jamais l'adéquation contenu ↔ bump. Un lab qui installera
      `conductor v1.20.0` après la fusion recevra une doctrine que le CHANGELOG de v1.20.0 ne
      mentionne pas.
    suggestion: "Soit une entrée de CHANGELOG sous la version courante, soit un bump patch des deux modules avant la fusion."
  - id: W11
    status: nouveau
    severity: périmètre de branche — non bloquant
    statement: >
      Le commit `479eee9` (Pattern G — « réveiller un worker coupé avant de le redispatcher »)
      **n'appartient à aucun plan de la phase** : il n'est réclamé par aucune des 22 `GSDA`, ne
      figure dans aucun des 12 `*-PLAN.md`, et est postérieur à la fois à la vérification et à la
      validation Nyquist — laquelle décrit donc un arbre qui n'est plus celui de `HEAD`. Le contenu
      est légitime (retour d'expérience mesuré de la phase, correctement placé en référence, et
      `check-agents.sh --strict` reste **rc=0 sur les 6 modules**), mais il entre en distribution
      sans être passé par un plan. Effet de bord mesuré : `vf-dev-manager.md` passe de 248 à
      **exactement 250 lignes**, soit le plafond ADR-029 pile — **plus aucune marge**, et aucun
      autre agent du dépôt ne dépasse 250 (balayage `awk` des 25 fichiers `plugin/*/agents/*.md`).
    suggestion: "Nommer Pattern G dans le SUMMARY de clôture ou dans le tableau du ROADMAP, pour qu'il ne soit pas du contenu distribué sans porteur."
  - id: W12
    status: nouveau
    severity: écart de mesure sans conséquence — non bloquant
    statement: >
      `24-VALIDATION.md` annonce une latence de retour de **37 s** au pire cas
      (`test-dev-orchestrator.sh`). Re-chronométrée de première main aujourd'hui : **24 s** (184 OK
      / 0 KO). L'écart est une variance de charge machine, pas un chiffre forgé, et le critère du
      sign-off (« Feedback latency < 60 s ») **tient dans les deux cas**. Signalé pour que le
      chiffre ne soit pas cité comme une constante.
    suggestion: "Aucune action — ou écrire « ~25-40 s selon charge » plutôt qu'une valeur unique."
behavior_unverified_items: []
human_verification: []
---

# Phase 24 : Activation et mesure du moteur GSD — Rapport de RE-VÉRIFICATION

**Goal ROADMAP** : cesser de payer l'installation d'un moteur sans en prendre les bénéfices —
**activer** les capacités GSD déjà installées mais dormantes, **mesurer** les faits de runtime que
VibeFlow présume, et **fermer** les routes qui mènent à un geste inerte.

**Re-vérifié** : 2026-08-05T00:34:14Z · **`HEAD` réel** : `479eee9` · **Diff global** :
`fbdb300..479eee9` (95 commits) · **Diff de re-vérification** : `012ce1b..479eee9` (5 commits)
**Verdict** : **PASS PARTIEL — la CI est rouge, le ship reste bloqué.**
**Re-vérification** : oui — après les commits de fermeture des 4 gaps de la vérification initiale
du 2026-08-04T22:49:02Z (`gaps_found`, 11/12).

## Ce que cette re-vérification a trouvé que le mandat ne disait pas

Deux faits, tous deux constatés en croisant les outils parce que le proxy tronque :

1. **`HEAD` n'est pas `f738e8c`.** `git rev-parse HEAD` rend **`479eee9`**. Un cinquième commit
   (Pattern G) existe. `git log --oneline -12` passé par le proxy ne le montrait **pas**, et la
   somme des `git show --stat` des quatre commits annoncés ne totalisait pas les 10 fichiers du
   `git diff --name-only`. C'est ce trou de deux fichiers qui a mené à la découverte.
2. **La branche est poussée, la PR #34 est ouverte, et la CI a tourné — elle est rouge.** Le
   warning W5 (« ce job n'aura jamais tourné pour de vrai ») est levé, et ce qu'il a révélé est le
   gap central de cette re-vérification.

## Les 4 gaps de la vérification initiale, re-mesurés un par un

### Gap 1 — la garde `NR > 60` de `check-dev-bootstrap.sh` : **FERMÉ**

Discrimination rejouée sur fixture jetable — **même script, même `PROJECT.md`, même `config.json`,
même `ROADMAP.md`**, seul le `STATE.md` change :

| Fixture (`STATE.md` de…) | Délimiteur fermant | rc | stdout |
|---|---|---|---|
| `main` (`fbdb300`) | ligne **56** | 3 | `[gsd-engine] Projet piloté par GSD — milestone gsd-migration, phase 26 complete.` |
| `012ce1b` (état vérifié initialement) | ligne **97** | 3 | **vide** — silence D-04 |
| **`479eee9` (`HEAD`)** | ligne **60** | 3 | **`[gsd-engine] Projet piloté par GSD — milestone gsd-migration, phase 26 complete.`** |

Et sur le dépôt réel, exécuté à la racine : **rc=3, signal imprimé**. Le commit `795b984`
(`.planning/STATE.md`, **4 insertions / 41 suppressions**) a sorti les blocs de commentaire de
mission du frontmatter. Le signal d'orientation de session parle de nouveau. **Gap fermé.**

Résiduel en **W9** : le délimiteur ferme à **exactement 60**, la garde est `NR > 60` — marge nulle,
aucun garde-fou machine, et le rationnel de `ci.yml:532-557` décrit encore l'ancien état.

### Gap 2 — M2 : **voie 1 fermée, voie 2 toujours ouverte**

**Voie 1 : livrée, et substantielle.** `team-kernel.md:55-89` porte la conséquence doctrinale
dans `plugin/`, là où un agent la lit au moment de décider comment paralléliser. Elle est
prescriptive, pas descriptive.

**Voie 2 : absente.** `backgroundDispatch` compte **24 occurrences** sur les **872 fichiers
suivis** — **0 dans `.planning/upstream/`**, qui contient toujours **un seul fichier**. Et
`ROADMAP.md:1622` affirme toujours « remontée amont déposée (voie 2) ». Le commit `7e3c39c` n'a pas
touché cette ligne : son diff sur le ROADMAP se limite à l'encadré de lettrage et à la ligne A9.

### Gap 3 — ledger `GSDA` : **cases soldées, table de mapping intacte**

Les deux moitiés ont bien divergé, exactement comme le mandat le pressentait :

| Moitié | Mesure | Verdict |
|---|---|---|
| Cases `- [ ]` / `- [x]` | **22 `[x]` · 0 `[ ]` · 0 `[~]`** — 22 hunks d'une ligne dans `7e3c39c`, corps d'exigence recalés | ✓ **soldée** |
| Table de mapping `:568-589` | **22× « Planned »** ; `GSDA-04` et `GSDA-05` portent toujours « **différé**, déclencheur objectif — **non activé** » | ✗ **intacte** |

Contre le config relu à l'instant : `workflow.windows_enforce: true`, `hooks.workflow_guard: true`.
Le fichier se contredit lui-même à 200 lignes d'écart.

### Gap 4 — validation Nyquist : **FERMÉ**

`24-VALIDATION.md` existe (`f738e8c`, 236 lignes), `status: validated`,
`nyquist_compliant: false`, motif mesuré en frontmatter, au patron de la Phase 23. **Le silence
est rompu, et il l'est par une décision écrite plutôt que par un vert forgé.**

Le mandat demandait de **re-dériver ses chiffres, pas de les recopier**. Fait, un par un :

| Affirmation de `24-VALIDATION.md` | Ma re-dérivation indépendante | Verdict |
|---|---|---|
| **32** blocs `<automated>` sur les 12 plans | balises ouvrantes **32**, fermantes **32**, `<task>` **32** ; répartition par plan identique (3,3,2,3,3,3,2,2,2,3,3,3) | ✓ exact |
| **27 verts / 5 rouges** sur `HEAD` | extraction mécanique + dés-échappement + ré-exécution des 32 : **27 rc=0 / 5 rc=1** | ✓ exact |
| Identité des 5 rouges (24-02 ×3, 24-07 T1, 24-10 T2) | rouges observés : `24-02__1/2/3`, `24-07__1`, `24-10__2` | ✓ **les mêmes** |
| **22 / 22** exigences réclamées | union `GSDA` des 12 plans = **22** ; univers `REQUIREMENTS.md` = **22** ; `comm -23` et `comm -13` rendent **0** des deux côtés | ✓ exact, 0 orpheline |
| **10** suites vertes | 10 suites rejouées : **rc=0 partout**, et **chaque compte d'assertions correspond** (184, 81, 40, 24, 14, 29, 35, 38, 14, 10) | ✓ exact |
| G5 : `### Phase` = 13, `#### Phase` = 13, total 26 | **13 et 13** | ✓ exact |
| G2 : l'ADR écrit 68 %, l'assertion pin 69 % | `ADR.md:1677` → « **275 / 400 — 68 %** » | ✓ exact |
| Latence **37 s** | re-chronométrée : **24 s** | ⚠ **W12** — variance de charge ; le critère « < 60 s » tient |

Un seul écart, de mesure et non de fait, sans effet sur le sign-off. **Le document est honnête :
il déclare sa non-conformité au lieu de la maquiller, et ses chiffres tiennent sous
re-dérivation.** Gap fermé.

## Le gap nouveau, et c'est le plus lourd — la CI parle, et elle dit non

Run du commit de `HEAD` (`30963489338`) et run précédent (`30962911735`) : **mêmes deux échecs**.

### Job « Gates de qualité (mode strict) » — ÉCHEC

Verdicts lus dans le log du runner, pas dans un rapport :

| Assertion | Attendu | Obtenu sur le runner |
|---|---|---|
| 1/6 `check-dev-bootstrap` avec ws | rc 3 | **rc=3** ✓ |
| 2/6 `check-state-integrity` avec ws | rc 0 | **rc=0** ✓ |
| 3/6 `planning-context` avec ws | rc 0 | **rc=0** ✓ |
| 4/6 `check-workstream-pointer` avec ws | rc 0 | **rc=0** ✓ |
| 5/6 `check-dev-bootstrap` sans ws | rc 0 | **rc=0** ✓ |
| 6/6 `check-workstream-pointer` sans ws | rc 1 | **rc=1** ✓ |
| **R1** non-régression racine | sortie invariante | **243 vs 356 octets — ÉCART** ✗ |
| R2 / R3 | rc 3 / rc 0 | ✓ / ✓ |

**Les six assertions de capacité passent réellement sur un runner** — c'est un acquis dur, et il
faut le porter au crédit de la phase : ce que la vérification initiale n'avait pu qu'approcher par
fixture locale est maintenant établi. Mais `BILAN : 1 écart(s)`, et le job sort en 1.

**Diagnostic du R1, reproduit localement.** Le delta entre les deux sorties est **une seule ligne
de diagnostic sur stderr** : « workstream « dev » résolu mais `./.planning/workstreams/dev` absent
— lecture sur la racine ». La résolution **ne fuit pas** : elle retombe correctement sur la racine
et l'annonce. L'assertion R1 exige une **égalité d'octets sur stdout et stderr fusionnés**, ce qui
interdit structurellement toute ligne de diagnostic. **Elle est trop stricte, pas fausse dans son
intention** — et elle n'était verte auparavant que parce qu'elle comparait deux sorties vides
(`ci.yml:551-557` le mesure et l'écrit noir sur blanc). Fermer le gap 1 lui a rendu la parole ;
elle s'en sert pour dire non.

### Job « Suites de tests » — ÉCHEC

`52 suite(s) découverte(s)`, **un seul cas rouge**, et il n'est pas anodin :

```
✗ A5d borne du canal nominal — long: rc=0 raison= nom=[] / court: rc=0 nom=[aaaa]
```

`test-workstream-policy.sh:160-185`. Le cas est **vert sur ce poste** (14 ok / 0 ko, rejoué
aujourd'hui) et **rouge sur le runner Linux**. Ce qu'il prétend prouver est une **borne de
sûreté** : qu'une valeur de `GSD_WORKSTREAM` de 200 000 octets est refusée **pour sa taille** —
son commentaire rappelle que sans elle, 400 Ko partent dans le contexte de session par deux hooks
`SessionStart`.

Lu dans le code : `workstream-policy.sh:286-290` porte bien la borne (`VF_WS_VALUE_MAX_BYTES=4096`,
raison `valeur-trop-longue`, `return 2`). Mais sur le runner, la fonction rend **`rc=0`, raison
vide, nom vide** — la signature exacte de la sortie `:278` `[ -n "$raw" ] || return 0`. **La valeur
n'arrive jamais jusqu'à la borne.** Sur Linux, la borne du canal nominal n'est donc **pas
exercée**, et la sonde qui devait l'établir n'assure rien.

C'est, mot pour mot, le motif que la Phase 24 s'était donné pour objet de fermer : **une couverture
verte qui masque un geste mort**. Cette fois sur son propre banc de test.

## Vérité par constat du tableau de clôture (`ROADMAP.md:1619-1632`)

| # | Constat | Statut | Preuve re-mesurée |
|---|---|--------|--------|
| **M1** | profondeur de dispatch écrite dans les agents | ✓ VERIFIED | `team-kernel.md:34-35` porte les 5 littéraux du descripteur ; `test-check-agents.sh` rejouée → **81 OK / 0 KO** (T76 exige les 5 littéraux et les 6 champs) |
| **M2** | acté en doctrine (voie 1) + remontée amont déposée (voie 2) | ✗ **FAILED (partiel)** | voie 1 ✓ (`team-kernel.md:55-89`) · voie 2 ✗ (`.planning/upstream/` = 1 fichier, 0 `backgroundDispatch`) · `ROADMAP.md:1622` l'affirme toujours |
| **M3** | `effort:` déclaré par **31 agents sur 31** | ✓ VERIFIED | balayage `awk` de `^effort:(low\|medium\|high\|xhigh\|max)$` sur **25 + 6 = 31** : **31 porteurs, 0 manquant** ; `check-agents.sh --strict` **rc=0 sur les 6 modules** |
| **A1** | `windows_enforce` présent et à `true` | ✓ VERIFIED | `.planning/config.json` relu → `workflow.windows_enforce: true` ; `check-state-integrity.sh` rc=0 |
| **A2** | slot PLANNER ouvert (2 skills) | ✓ VERIFIED | `agent_skills.gsd-planner` = 2 entrées. Réserve de portabilité inchangée : **W4** |
| **A3** | `tdd_mode` inchangé, par décision écrite | ✓ VERIFIED | clé **absente** du config ; refus motivé `GSD-PIPELINE.md:268-287` |
| **A4** | profils de contexte refusés, par décision écrite | ✓ VERIFIED | clé `context` **absente** ; ADR-068 volet 1 |
| **A5** | `workflow_guard` à `true` ; `hooks.community` refusé | ✓ VERIFIED | `hooks: { context_warnings: true, workflow_guard: true }` — `community` absent ; ADR-067. Réserve : **W3** |
| **A6** | seuil inline chiffré, laissé au défaut | ✓ VERIFIED | clé non posée ; ADR-068 volet 2 |
| **A7** | `intel.enabled: true` | ✓ VERIFIED | `.planning/config.json` → `intel: { enabled: true }` |
| **A8** | refus indexés, entrées conditionnelles, trou fermé par un gate câblé en CI | ✓ VERIFIED **— et désormais prouvé sur runner** | `intent-routing.md:104,147` conditionnelles ; `check-capability-activation.sh` **rc=0** localement **ET étape ✓ verte dans le job CI** ; `test-check-capability-activation.sh` **29 / 29** |
| **A9** | outillage workstream-aware **exercé en CI** ; adoption acquise | ✗ **FAILED (partiel)** | Adoption ✓ (ADR-069, lettrage corrigé, W2 résolu ; mesure re-dérivée **à l'identique** : `atteinte=91`, `K2=7`, `en dur=45`, `aveugles=42`). Exercice CI : **les 6 assertions passent sur runner**, mais le job **échoue** (R1) et `test-workstream-policy.sh` **échoue sur Linux** (A5d) |

**Score : 10 / 12 constats vérifiés** (contre 11 / 12 à l'initiale — M2 progresse sans être soldé,
A9 régresse parce que la CI a cessé de se taire).

## Gates et suites rejoués sur `479eee9` (poste local)

**20 gates** (`scripts/check-*.sh` = 3 · `plugin/*/scripts/check-*.sh` = 17). Convention : `0` =
conforme, `1` = écart, `3` = sain/silence, `64` = usage. **Aucun `1`.**

| Gate | rc | Note |
|---|---|---|
| `check-machine-paths.sh` | **0** | **872** fichiers suivis balayés, aucun chemin absolu de machine |
| `check-version-sync.sh` | **0** | triade `v2.47.1`, badges, 52 suites |
| `check-release-tag.sh` | **0** | `VERSION` ↔ tag |
| `check-agents.sh --strict` ×6 modules | **0** ×6 | conformes après Pattern G |
| `check-branch-claim.sh` · `check-mission-invariants.sh` · `check-workstream-pointer.sh` · `check-dev-bootstrap.sh` · `check-doc-drift.sh` · `check-gsd-config.sh` · `check-gsd-engine.sh` · `check-file-size.sh` | **3** | sains / silence — `check-dev-bootstrap` **imprime enfin son signal** |
| `check-legacy.sh` · `check-overlaps.sh` · `check-state-integrity.sh` · `check-debug-research.sh` · `check-plugin-update.sh` · `check-registres.sh` · `check-capability-activation.sh` · `check-planning-state.sh` | **0** | conformes |

| Suite rejouée | rc | Résultat | Durée |
|---|---|---|---|
| `test-dev-orchestrator.sh` | 0 | **184 OK / 0 KO / 0 SKIP** | 24 s |
| `test-check-agents.sh` | 0 | **81 OK / 0 KO** | 3 s |
| `test-check-state-integrity.sh` | 0 | **40 ok / 0 ko** | 5 s |
| `test-check-workstream-pointer.sh` | 0 | **24 ok / 0 ko** | 1 s |
| `test-guard-agent-write.sh` | 0 | **14 OK / 0 KO** | 0 s |
| `test-check-capability-activation.sh` | 0 | **29 OK / 0 KO** | 1 s |
| `test-check-dev-bootstrap.sh` | 0 | **35 ok / 0 ko** | 1 s |
| `test-planning-context-hardening.sh` | 0 | **38 passés / 0 échoués** | 1 s |
| **`test-workstream-policy.sh`** | **0** | **14 ok / 0 ko** — ⚠ **rouge sur le runner Linux (A5d)** | 4 s |
| `test-workstream-symlink-escape.sh` | 0 | **10 ok / 0 ko** | 1 s |

**Le poste local ne suffit plus à certifier cette phase** : la ligne `test-workstream-policy.sh` est
verte ici et rouge là-bas. C'est le seul enseignement dont on ne pouvait pas disposer avant le push.

## Menaces — recompte indépendant du registre (`24-SECURITY.md`)

Recompté **par colonne**, pas par recherche du mot « open » dans la ligne (qui produit un faux
positif : la prose des mitigations contient « reopen », « ouvert ») :

| Sévérité | closed | open |
|---|---|---|
| high | **31** | **0** |
| medium | 13 | 4 |
| low | 3 | 0 |
| **Total lignes `T-24-*`** | **51** | |

**0** menace ouverte de sévérité ≥ `high` (seuil `security_block_on` du lab). `threats_open: 0` est
**calculé-cohérent**. L'acquis `T-24-02-01` tient. Seule la note du ROADMAP est en retard (**W1**).

## Univers déclarés

| Univers | Définition exacte | Compte |
|---|---|---|
| Fichiers suivis | `git ls-files` | **872** |
| Fichiers modifiés depuis la vérification initiale | `git diff --name-only 012ce1b..479eee9` | **10** |
| Agents | `plugin/*/agents/*.md` (**25**) + `plugin/*/AGENT.md` (**6**) | **31** |
| Gates | `scripts/check-*.sh` (**3**) + `plugin/*/scripts/check-*.sh` (**17**) | **20** |
| Suites de test | `find plugin scripts -type f -path '*/tests/test-*.sh'` | **52** (confirmé par la CI : « 52 suite(s) découverte(s) ») |
| Blocs `<automated>` de la phase | balises ouvrantes sur les 12 `*-PLAN.md` | **32** (fermantes : 32) |
| Exigences de la phase | `GSDA-\d\d` distincts dans `.planning/REQUIREMENTS.md` | **22** (union des plans : 22, écart nul aux deux sens) |
| Workflows amont | `~/.claude/gsd-core/workflows/*.md`, profondeur 1 | **91** (compteur d'atteinte de la commande ADR-069) |

`grep` et `find` étant proxifiés et tronquants sur ce poste — et `git log` l'ayant démontré en
masquant un commit —, tous les comptes sont faits en `awk` lisant les fichiers lui-même, en `comm`
sur listes triées, ou en `git` invoqué directement, et croisés sur deux formes quand le nombre est
porteur.

## Synthèse — ce qu'il reste avant `/gsd-ship`

1. **Rendre la CI verte** (bloquant, et c'est nouveau). Deux points distincts :
   **(a)** R1 asserte une égalité d'octets sur un canal fusionné et interdit donc toute ligne de
   diagnostic — la rendre opposable sans être fausse ; **(b)** le cas A5d n'exerce pas la borne du
   canal nominal sur Linux : la borne y est **non prouvée**, ce qui est un fait de sûreté, pas un
   fait de test.
2. **M2 voie 2** : rédiger la remontée amont du descripteur au gabarit déjà validé, ou recaler
   `ROADMAP.md:1622` pour qu'il cesse d'affirmer un livrable absent.
3. **Table de mapping des exigences** : 22 lignes « Planned » → état réel, et effacer la glose
   « différé — non activé » de `GSDA-04` / `GSDA-05`.
4. **W1** (note ROADMAP sur `threats_open`), **W9** (marge nulle sur la borne de 60 + rationnel
   `ci.yml` périmé), **W10** (deux modules avec du contenu distribué après leur bump) — à traiter,
   non bloquants.
5. **W3, W4, W6, W7, W11, W12** — signalés, non bloquants.

**La release racine reste hors périmètre et re-vérifiée non franchie** : `0` ligne d'écart depuis
`main` sur la triade, `VERSION = v2.47.1`, `check-release-tag.sh` rc=0. Geste humain gaté, conforme
au contrat.

**Ce que cette phase a gagné depuis la vérification initiale**, et qui mérite d'être dit : le signal
de démarrage parle de nouveau, la doctrine M2 a quitté `.planning/` pour l'endroit où on la lit, le
contresens de lettrage A9 est réparé des deux côtés, les 22 exigences sont soldées sur preuve, la
validation Nyquist existe et refuse de se déclarer conforme, et **les six assertions workstream ont
enfin tourné sur un vrai runner et sont passées**. Ce qu'elle a perdu, c'est le confort de
l'ignorance : la CI a cessé de se taire.

---

_Re-vérifié : 2026-08-05T00:34:14Z_
_Vérificateur : Claude (gsd-verifier) — analyse goal-backward. Gates, suites, mutations, fixtures et
les 32 commandes `<automated>` exécutés de première main ; logs CI lus au runner via
`gh run view --log-failed`, jamais dans un SUMMARY._
