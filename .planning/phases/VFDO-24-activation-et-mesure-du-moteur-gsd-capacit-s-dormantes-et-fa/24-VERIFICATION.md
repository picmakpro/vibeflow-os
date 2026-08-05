---
phase: VFDO-24-activation-et-mesure-du-moteur-gsd-capacit-s-dormantes-et-fa
verified: 2026-08-05T01:17:56Z
status: gaps_found
verdict: PASS — la CI est VERTE et gagnée par mutation ; 1 gap résiduel de ledger, non bloquant pour le Goal
score: 12/12 constats du tableau de clôture vérifiés — 1 gap transverse restant (contre 3)
behavior_unverified: 0
overrides_applied: 0
diff_verified: fbdb300..9889fa0 (101 commits, branche feat/phase-24-activation-moteur-gsd, PR #34)
re_verification:
  previous_verified: 2026-08-05T00:34:14Z
  previous_status: gaps_found
  previous_verdict: PASS PARTIEL — CI ROUGE
  previous_score: 10/12
  previous_measurement_base: 479eee9
  diff_since_previous_document: f18b744..9889fa0 (4 commits — b25ed19, e6ac65b, 9be2552, 9889fa0)
  diff_since_previous_measurement_base: 479eee9..9889fa0 (6 commits, 6 fichiers)
  gaps_closed:
    - "L'outillage workstream est exercé en CI, et la CI de la branche certifie la phase — VERTE sur les 3 jobs, et la fermeture est prouvée par mutation des DEUX assertions concernées"
    - "M2 — le tableau qui fait foi cesse d'affirmer un livrable absent (`ROADMAP.md:1622` recalé sur la mesure)"
  gaps_partially_closed:
    - "Ledger GSDA — la colonne de mapping passe de 22× « Planned » à 22× « Done » ; la glose « non activé » de GSDA-04/05 SUBSISTE et reste fausse contre le config"
  gaps_remaining:
    - "REQUIREMENTS.md:571-572 — GSDA-04/05 portent « non activé » alors que les deux clés sont à true"
  gaps_new: []
  regressions: []
  warnings_resolved: [W5, W9b-partiel]
  warnings_new: [W13, W14, W15, W16, W17]
gaps:
  - truth: "Le ledger d'exigences ne se contredit pas lui-même"
    status: partial
    severity: "non bloquant pour le Goal — falsité vive dans le document de record"
    reason: >
      **La moitié qui manquait a été livrée.** Le commit `9be2552` a fait passer les **22** lignes de
      la table de mapping `.planning/REQUIREMENTS.md:568-589` de « **Planned** » à « **Done —
      plan 24-0N** » : recompte indépendant par colonne (`awk -F'|'` sur la 4ᵉ cellule des lignes
      `^| GSDA-\d\d |`) → **Done = 22, Planned = 0, total = 22**. La contradiction de masse avec les
      **22** cases `- [x]` (recomptées : `x=22`, `0` `[ ]`, `0` `[~]`, **22** identifiants distincts)
      est **levée**. Contraste avec la Phase 23 rétabli.
      **Ce qui reste, et qui était nommé mot pour mot dans le `missing` de la passe précédente :**
      les lignes **571** et **572** portent toujours la glose « (**différé**, déclencheur objectif —
      **non activé**, gaté sur GSDA-01) ». Cette glose est **fausse à `HEAD`**, et sur trois plans à
      la fois : (1) `.planning/config.json` relu à l'instant porte `workflow.windows_enforce: true`
      et `hooks.workflow_guard: true` ; (2) les corps d'exigence du **même fichier** (`:374`, `:379`)
      écrivent « **est activé** » ; (3) le tableau de clôture du ROADMAP (`A1`, `A5`) écrit
      « **PÉRIMÉ** — présent et à `true` ». Le volet le plus lourd de `GSDA-04` est par ailleurs
      **soldé sur pièce** : `.planning/WINDOWS.md` porte `open_count: 0`, `waived_count: 1`, et
      l'entrée **#3** est en `waived` avec sa raison horodatée du 2026-08-04 — exactement ce que
      l'exigence demande. Un relecteur du ledger conclurait le contraire de ce que la machine dit.
      **Pourquoi ce gap n'est pas un blocker et le reste quand même.** La substance EST livrée et
      vérifiable par machine ; le Goal de la phase ne dépend pas de cette prose. Mais c'est un
      `missing` explicitement posé par la vérification précédente, resté non fait, et il fait mentir
      le document que `/gsd-audit-milestone` lira. Le refus tient parce que la correction coûte
      deux lignes, pas parce que le défaut est grave.
    artifacts:
      - path: ".planning/REQUIREMENTS.md"
        issue: "lignes 571-572 — « différé … non activé » contre config.json true/true, contre les corps :374/:379, et contre le ROADMAP A1/A5"
    missing:
      - "Effacer la glose « différé, déclencheur objectif — non activé » de GSDA-04 et GSDA-05 (:571-572) — ADR-066 a levé le gate, la clause de repli de GSDA-01 ne s'applique plus"
      - "Accessoirement recaler :618-622, qui écrit encore « GSDA-04 et GSDA-05 sont planifiés en DIFFÉRÉ ÉCRIT, pas en activation » — vrai du CADRAGE, trompeur en l'état pour un lecteur de clôture"
deferred:
  - truth: "Publier une release racine (bump de la triade, tag annoté, release GitHub, check-release-tag.sh --remote ✓)"
    addressed_in: "Geste humain post-fusion, réservé à Samuel (CLAUDE.md § Discipline de release)"
    evidence: >
      Frontière re-vérifiée **non franchie** : `git diff --stat main..HEAD` sur `VERSION`,
      `plugin/.claude-plugin/plugin.json` et `.claude-plugin/marketplace.json` rend **0 ligne** ;
      `VERSION` = `v2.47.1` des deux côtés ; `scripts/check-release-tag.sh` sort en **rc=0**.
      Ce n'est pas un manque, c'est le contrat.
  - truth: "M2 voie 2 — remonter en amont que `backgroundDispatch: false` est fail-closed et non descriptif du runtime Claude Code"
    addressed_in: "Aucune phase, aucun BACKLOG — **non-livrable désormais déclaré**, mais sans successeur"
    evidence: >
      `ROADMAP.md:1622` déclare désormais explicitement « **voie 2 non livrée** ». La mesure le
      confirme : `.planning/upstream/` contient **un seul fichier**
      (`2026-08-04-workflows-aveugles-aux-workstreams.md`, GSDA-19) et **0** occurrence de
      `backgroundDispatch`. Le fait n'est plus travesti — voir **W15** pour le fait qu'il n'est
      suivi nulle part.
warnings:
  - id: W1
    status: toujours ouvert
    severity: fait périmé dans le document qui fait foi — non bloquant
    statement: >
      La note de fin de section ROADMAP (`:1697-1700`) écrit toujours que « le gate de sécurité reste
      **bloquant** (`24-SECURITY.md`, `threats_open: 1`) sur `T-24-02-01` ». **Périmé.** Recompté
      indépendamment aujourd'hui par position de colonne (sévérité = 5ᵉ cellule, statut = premier mot
      de la 7ᵉ — jamais par recherche du mot « open » dans la ligne, qui produit un faux positif dans
      la prose des mitigations) : sur les **51** lignes `T-24-*`, **31 high closed · 13 medium
      closed · 4 medium open · 3 low closed**. Soit **0** menace ouverte de sévérité ≥ `high`
      (`security_block_on` du lab). `threats_open: 0` est calculé-cohérent ; le gate de `ship:pre`
      passerait.
    suggestion: "Recaler la note de fin de § Phase 24 sur threats_open: 0."
  - id: W3
    status: toujours ouvert
    severity: reproductibilité d'un chiffre gravé — non bloquant
    statement: >
      ADR-067 (`docs/ADR.md:1677`) grave « les **400 derniers commits sans merge** » → « sujet
      dépassant 72 caractères : **275 / 400 — 68 %** ». **Toujours non reproductible.**
      Re-dérivation sur exactement ce corpus (`git log --no-merges -n 400 --format=%s`, longueur en
      caractères, `awk`) : **306 / 400 = 77 %** à `HEAD` (308 à la passe précédente, 305 à
      l'initiale — le corpus glisse, la conclusion pas) ; variante `>= 72` → **312**. La conclusion
      de l'ADR (« le hook rejetterait plus des deux tiers de notre manière d'écrire ») en sort
      **renforcée**, jamais affaiblie. Corollaire machine : c'est ce chiffre qui fait rougir
      l'assertion `<automated>` `24-02__2`, laquelle épingle `69 %` — **trois valeurs pour un même
      fait** (69 pinné, 68 gravé, 77 mesuré).
    suggestion: "Ajouter à ADR-067 la commande rejouable qu'ADR-069 exige, et recaler 275/400 sur ce qu'elle rend."
  - id: W4
    status: toujours ouvert
    severity: portabilité du canal A2 — non bloquant
    statement: >
      Le slot PLANNER reste peuplé à la forme **globale nue** (`global:software-architecture`,
      `global:audit-architecture` — relu dans `.planning/config.json`), pas à la forme namespacée
      `global:<plugin>:<skill>`. La résolution passe donc par le système de fichiers du compte, et un
      skill absent est **silencieusement écarté** après un `WARNING` sur stderr. La dépendance est
      machine-locale : elle ne voyage pas avec le plugin.
    suggestion: "Écrire cette dépendance d'installation dans GSD-PIPELINE.md §10, ou basculer sur la forme namespacée."
  - id: W6
    status: toujours ouvert
    severity: cohérence de frontmatter — non bloquant
    statement: >
      `24-SECURITY.md` porte toujours `status: draft` avec `audited: 2026-08-05` et
      `threats_open: 0`, pour un registre de **51** menaces intégralement instruit. Le gate de
      `ship:pre` ne lit que `threats_open` — rien ne bloque — mais un document audité et soldé qui se
      déclare brouillon est un piège de relecture.
    suggestion: "Passer status: draft → audited."
  - id: W7
    status: toujours ouvert
    severity: sortie utilisateur — non bloquant
    statement: >
      `plugin/planning-core/scripts/planning-context.sh:183` imprime toujours l'en-tête sans borner :
      `"État courant du lab (${MAX_LINES} premières lignes sur ${total} …)"`, ce qui rend « 45
      premières lignes sur 13 » quand le fichier est plus court que l'extrait. Texte injecté en
      contexte à chaque `SessionStart`.
    suggestion: "N'annoncer « N premières lignes sur M » que si N < M."
  - id: W9
    status: partiellement résolu — volet (a) ouvert, volet (b) à moitié refait
    severity: marge nulle et rationnel encore périmé en amont du bloc — non bloquant
    statement: >
      **(a) Marge nulle, inchangée.** Le délimiteur fermant du frontmatter de `.planning/STATE.md`
      est **exactement à la ligne 60** (`awk` sur le 2ᵉ `^---$`), et la garde de
      `check-dev-bootstrap.sh:215` est `NR > 60 { exit }`. Une ligne de plus et le signal se retait.
      Aucun garde-fou machine ne surveille cette borne : `test-check-dev-bootstrap.sh` n'a toujours
      **aucun cas de dépassement** (balayage du motif « 61 » / « borne » : les seules occurrences
      portent sur la borne d'octets du pointeur, pas sur celle du frontmatter).
      **(b) Rationnel de `ci.yml` : la moitié qui rougissait est refaite, celle qui précède ne l'est
      pas.** Le bloc `:543-563` a été intégralement réécrit par `e6ac65b` et décrit désormais l'état
      réel. Mais `:527-540`, juste au-dessus, écrit encore « **CE JOB N'AURA JAMAIS TOURNÉ POUR DE
      VRAI** » (il a tourné **8 fois** sur cette branche) et « le frontmatter de `.planning/STATE.md`
      fait **81 lignes** […] **stdout VIDE** » (il fait **60**, et stdout porte **169** caractères).
      Un relecteur qui commence par le haut se forme l'inverse de l'état courant.
    suggestion: "Ajouter un cas « frontmatter de 61 lignes → silence » à test-check-dev-bootstrap.sh, et purger le rationnel périmé de ci.yml:527-540."
  - id: W10
    status: toujours ouvert — et le périmètre s'est ÉLARGI
    severity: traçabilité de distribution — non bloquant
    statement: >
      Trois modules portent désormais du **contenu distribué posé après leur bump**, sans entrée de
      CHANGELOG. Les `VERSION` des trois ont été figées au commit `2b95db2` (plan 24-12) ; depuis :
      `plugin/conductor` (**4** commits de contenu, dont la doctrine M2 de `team-kernel.md`),
      `plugin/dev-orchestrator` (**3**, dont Pattern G), et — **nouveau et le plus lourd** —
      `plugin/planning-core` (**4**, dont **`b25ed19`, une correction de COMPORTEMENT** : la borne de
      sûreté `VF_WS_VALUE_MAX_BYTES` ne s'appliquait pas sur Linux). Le CHANGELOG de
      `planning-core v2.6.0` ne mentionne **pas** ce correctif : un seul commit a touché les trois
      CHANGELOG depuis le bump (`55d1c58`, sur le correctif symlink). `scripts/check-version-sync.sh`
      sort en **rc=0** — il vérifie la cohérence de la triade, jamais l'adéquation contenu ↔ bump.
    suggestion: "Une entrée de CHANGELOG sous la version courante des trois modules, ou un bump patch avant la fusion."
  - id: W11
    status: toujours ouvert
    severity: périmètre de branche — non bloquant
    statement: >
      Le commit `479eee9` (Pattern G) n'est toujours réclamé par aucun plan, aucune `GSDA`, aucun
      `*-SUMMARY.md` : balayage `awk` de « Pattern G » sur les **872** fichiers suivis → **8**
      emplacements, dont **6 dans ce seul document** et **2 dans le contenu distribué**
      (`vf-dev-manager.md:176`, `mission-flow.md:350`). Le contenu est légitime et sa conformité
      tient (`check-agents.sh --strict --agents-dir` → **rc=0** sur les **6** modules porteurs d'un
      dossier `agents/`), mais il entre en distribution sans porteur documentaire.
    suggestion: "Nommer Pattern G dans le SUMMARY de clôture ou dans le tableau du ROADMAP."
  - id: W12
    status: toujours ouvert — et l'écart se confirme
    severity: écart de mesure sans conséquence — non bloquant
    statement: >
      `24-VALIDATION.md` annonce une latence de retour de **37 s** au pire cas
      (`test-dev-orchestrator.sh`). Re-chronométrée de première main aujourd'hui : **22 s**
      (184 OK / 0 KO / 0 SKIP) — après **24 s** hier. Deux mesures indépendantes sous la moitié de
      la valeur annoncée : ce n'est plus du bruit, c'est une valeur unique qui ne décrit pas la
      distribution. Le critère de sign-off (« Feedback latency < 60 s ») tient dans tous les cas.
    suggestion: "Écrire « ~20-40 s selon charge » plutôt qu'une valeur unique."
  - id: W13
    status: nouveau
    severity: fait périmé dans un document de gouvernance — non bloquant
    statement: >
      `24-VALIDATION.md` motive sa non-conformité Nyquist par **trois motifs cumulés**, et son
      motif **(a)** est désormais **FAUX** : « **La CI est ROUGE sur la branche poussée** […] les 2
      derniers sur la tête poussée `7e3c39c` ». Le document le qualifie lui-même de « **le plus
      grave des trois** ». Il est mort avec `b25ed19` et `e6ac65b`. Les motifs **(b)** et **(c)**
      **tiennent**, re-dérivés ici : (b) les **32** blocs `<automated>` ré-extraits, dés-échappés et
      ré-exécutés rendent **27 rc=0 / 5 rc=1**, et ce sont **les mêmes cinq** ; (c) le document reste
      renseigné a posteriori. `nyquist_compliant: false` reste donc **juste** — mais pour deux
      motifs, plus trois. **Ce n'est pas un gap** : la passe précédente demandait l'existence du
      document, elle est acquise, et le refus de forger un `true` reste le bon geste.
    suggestion: "Barrer le motif (a) en le datant, sans toucher à nyquist_compliant."
  - id: W14
    status: nouveau
    severity: chiffre auto-référentiel — non bloquant
    statement: >
      `ROADMAP.md:1622`, écrit par `9889fa0`, affirme « `backgroundDispatch` compte **24
      occurrences** sur 872 fichiers suivis ». Re-dérivé à `HEAD` par balayage `awk` de **toutes**
      les occurrences (pas des lignes porteuses) sur `git ls-files` : **25**. Le compte était juste
      **au commit parent** (`9be2552` : le ROADMAP en portait 4, il en porte 5) — **c'est l'écriture
      du chiffre qui a changé le chiffre**. Le fait porteur, lui, est intact et c'est celui qui
      compte : **0** occurrence dans `.planning/upstream/`, qui contient **un seul fichier**.
      Le même piège vaut pour ce document-ci, qui en ajoute d'autres.
    suggestion: "Écrire « 0 dans .planning/upstream/ » sans total absolu, ou dater le total et nommer le commit de mesure."
  - id: W15
    status: nouveau
    severity: livrable abandonné sans successeur — non bloquant
    statement: >
      La recalibration de `ROADMAP.md:1622` supprime la falsité, mais **n'ouvre aucune suite** :
      balayage de `.planning/BACKLOG.md` (0 occurrence de `backgroundDispatch` ni de « remontée
      amont »), et les deux seules phases postérieures du jalon (**25** budget d'instructions,
      **26** manuel utilisateur) ne la couvrent pas. La voie 2 était présentée au cadrage
      (`ROADMAP.md:1435-1437`) comme un **bénéfice collectif** (« débloquerait le parallélisme
      intra-étape pour tous les labs ») et l'option 3 (`claude_orchestration`) est écartée « **à
      reconsidérer si la voie 2 échoue** » — ce conditionnel n'a plus de branche vivante.
    suggestion: "Une entrée BACKLOG nommant la voie 2 et son déclencheur, pour qu'elle ne s'évapore pas avec la clôture."
  - id: W16
    status: nouveau
    severity: chiffre de commentaire non reproductible — non bloquant
    statement: >
      Le rationnel réécrit de `ci.yml:550-551` affirme que le stdout du gate porte « le signal métier
      réel (« … orientation gsd-engine », **137 octets**) ». Mesuré de première main sur l'arbre
      courant : le stdout fait **169 caractères** (`${#var}` sous locale UTF-8 — c'est la grandeur
      que l'étape imprime réellement) et **177 octets** (`wc -c`). **137 ne correspond à ni l'un ni
      l'autre.** Le label de l'étape dit « octet(s) » là où bash compte des caractères. Sans effet
      sur l'assertion, qui compare des chaînes et non des longueurs.
    suggestion: "Recaler 137 → 169, et dire « caractère(s) » dans le label de l'étape."
  - id: W17
    status: nouveau
    severity: plafond ADR-029 atteint hors du périmètre gardé — non bloquant
    statement: >
      Deux agents sont **exactement à 250 lignes**, le plafond ADR-029 : `vf-dev-manager.md`
      (marge 0, **machine-gardée** — `test-dev-orchestrator.sh` T35 (d) et (e) prouvent le plafond
      détectable par mutation à 255) et **`plugin/validator/AGENT.md`**, passé de **249 à 250** par
      `a781090` (effort par rôle sur les `AGENT.md`) et **gardé par rien**. Corollaire : la passe
      précédente écrivait « aucun autre agent du dépôt ne dépasse 250 (balayage des **25** fichiers
      `plugin/*/agents/*.md`) » — **balayage juste sur le mauvais ensemble**, celui-là même que la
      phase s'est donné pour règle de ne plus commettre : les **6** `AGENT.md` en étaient exclus.
    suggestion: "Étendre le contrôle de plafond aux 31 agents (25 + 6), ou reprendre une ligne à validator/AGENT.md."
behavior_unverified_items: []
human_verification: []
---

# Phase 24 : Activation et mesure du moteur GSD — Rapport de RE-VÉRIFICATION (2ᵉ passe)

**Goal ROADMAP** : cesser de payer l'installation d'un moteur sans en prendre les bénéfices —
**activer** les capacités GSD déjà installées mais dormantes, **mesurer** les faits de runtime que
VibeFlow présume, et **fermer** les routes qui mènent à un geste inerte.

**Re-vérifié** : 2026-08-05T01:17:56Z · **`HEAD`** : `9889fa0` (confirmé par `git rev-parse`, arbre
de travail **propre**, `git ls-remote` rend la **même** empreinte que le local)
**Diff global** : `fbdb300..9889fa0` (**101** commits) · **Depuis le document précédent** :
`f18b744..9889fa0` (**4** commits, **4** fichiers) · **Depuis sa base de mesure `479eee9`** :
**6** commits, **6** fichiers.
**Verdict** : **PASS — le motif dominant a disparu, et sa disparition est prouvée par mutation.**
**Statut** : `gaps_found` pour **un** gap résiduel de ledger, non bloquant pour le Goal.

---

## Le motif dominant de la passe précédente a disparu — et je l'ai vérifié en essayant de le faire revenir

La passe du 2026-08-05T00:34 refusait sur un fait unique et opposable : **la CI était rouge**. Le
mandat de cette passe annonçait la réparation. Une réparation annoncée n'est pas une réparation :
un vert peut s'obtenir en **désarmant l'assertion** aussi bien qu'en corrigeant le sujet. C'est
exactement ce que j'ai cherché.

### 1. La CI est verte, et elle l'est sur la tête courante

| Fait | Mesure de première main |
|---|---|
| Runs sur `9889fa0` | `30965106744` (push) et `30965108999` (pull_request) — **`success` tous les deux** |
| Jobs par run | **3 / 3 verts** : « Suites de tests », « Gates de qualité (mode strict) », « Lab frais » |
| PR #34 | `OPEN`, `MERGEABLE`, **8 / 8** checks `SUCCESS` (les 3 jobs × 2 runs + 2 Socket) |
| Runs rouges antérieurs | 6, dont les 2 sur `479eee9` que la passe précédente a lus |

Verdicts lus **dans le log du runner** (`gh run view --log`), jamais dans un rapport :

```
== R1 check-dev-bootstrap racine : rc(sans)=3 rc(avec)=3, stdout 169/169 octet(s),
   stderr hors-repli 73/73 octet(s) ==
== BILAN : 0 écart(s) sur 6 verdicts partitionnés + 3 verdicts racine ==
== 52 suite(s) découverte(s) ==
== bilan : 52 suite(s), 0 échec(s) ==
  ✓ A5d GSD_WORKSTREAM de 200000 octets → refus POUR SA TAILLE (raison distincte de
    hors-politique), aucun nom rendu ; la MEME forme en 4 octets reste acceptee
```

### 2. R1 n'a pas été désarmée — quatre mutants le prouvent

J'ai rejoué le bloc `ci.yml:564-588` **verbatim** en local, avec le **sujet substituable**. Résultat
nominal identique au runner (**stdout 169/169, stderr hors-repli 73/73, 0 écart**). Puis j'ai
substitué quatre sujets simulés :

| Mutant | Ce qu'il simule | Verdict de R1 | Attendu |
|---|---|---|---|
| **A** | le gate **fuit** `GSD_WORKSTREAM` dans **stdout** | **ROUGE** — « le stdout CHANGE selon GSD_WORKSTREAM » | rouge ✓ |
| **B** | stderr change **hors** du motif de repli documenté | **ROUGE** — « le stderr change AU-DELÀ de la ligne de repli » | rouge ✓ |
| **C** | les **deux** stdout sont vides | **ROUGE** — « NON OPPOSABLE » (plancher conservé) | rouge ✓ |
| **D** | **seule** la ligne de repli documentée diffère | **VERT** | vert ✓ |

Le plancher de non-opposabilité — le garde-fou qui interdit à l'assertion d'être verte en comparant
deux chaînes vides — **a été conservé** dans la réécriture, et il mord (mutant C). Le filtre `grep
-Ev` ne blanchit **que** les lignes préfixées `[check-dev-bootstrap] ` **et** terminées par
« lecture sur la racine. » : tout autre écart de stderr est attrapé (mutant B). **R1 est plus
opposable qu'avant, pas moins** : avant `795b984` elle comparait deux sorties vides et n'aurait rien
pu dire ; elle compare aujourd'hui deux canaux **non vides** (169 et 73), sur deux axes distincts.

### 3. La borne du canal nominal est réellement exercée — la mutation le prouve

Le défaut Linux était le plus intéressant de la phase : `vf_ws_trim` forkait `awk` avec
`GSD_WORKSTREAM` (200 000 octets) **exportée** ; le noyau Linux borne chaque chaîne d'`envp` à
`MAX_ARG_STRLEN` ; `execve` échouait en `E2BIG` ; la substitution de commande rendait vide ; `raw`
repartait vide et sortait par `:293` **avant** d'atteindre la borne `:301`. La borne de sûreté
n'avait donc **rien à refuser** — et le test était vert sur macOS, qui n'impose pas cette limite.

La réécriture (`b25ed19`) est en **builtins bash purs** (`[[ =~ ]]` + découpage par indices, classe
de blancs explicite plutôt que `[[:space:]]` dépendant de la locale) : **aucun `execve()`**, donc la
taille de la valeur n'entre plus en jeu pour l'outil qui la rogne. Lu dans le code, pas dans le
message de commit.

**Contre-épreuve par mutation, jouée ici** : borne portée de `4096` à `10^9` dans
`workstream-policy.sh:91`, suite rejouée → **13 ok / 1 ko, rc=1**, le cas rouge étant `A5d` avec la
signature `rc=0 … nom=[aaaa…]`. Fichier restauré, `git status` propre. La borne est donc **vivante
et mesurée** : la valeur **atteint** désormais la garde (le nom est porté jusqu'à elle), là où sur
le runner d'hier elle rendait `nom=[]` — la signature exacte de la sortie prématurée. **La sonde
prouve ce qu'elle prétend prouver.**

---

## Vérité par constat du tableau de clôture (`ROADMAP.md:1619-1632`)

| # | Constat | Statut | Preuve re-dérivée |
|---|---|--------|--------|
| **M1** | profondeur de dispatch écrite dans les agents | ✓ VERIFIED | `team-kernel.md:33-36` porte le descripteur verbatim ; `T76` exige **5 littéraux** (`maxDepth`, « deux niveaux de marge », « sous-worker », `2026-08-04`, `1.9.1`) **et 7 champs** ; `test-check-agents.sh` rejouée → **81 OK / 0 KO** |
| **M2** | voie 1 livrée · **voie 2 non livrée** | ✓ VERIFIED **en tant que constat** | Voie 1 sur pièce : `team-kernel.md:55-89`, prescriptive (« n'attendez aucun gain de parallélisme d'un découpage en plans multiples », « sérialisation observée ≠ panne »). Voie 2 : `.planning/upstream/` = **1** fichier, **0** `backgroundDispatch` — et `:1622` **le dit désormais**. Réserves : **W14** (chiffre), **W15** (pas de successeur) |
| **M3** | `effort:` déclaré par **31 agents sur 31** | ✓ VERIFIED | Univers redéfini à la main (le glob `git ls-files 'plugin/*/agents/*.md'` traverse les `/` et rend **49** : piège écarté) → **25** à profondeur exacte + **6** `AGENT.md` = **31** ; balayage fichier par fichier : **31 porteurs, 0 manquant** |
| **A1** | `windows_enforce` présent et à `true` | ✓ VERIFIED | `config.json` → `true` ; **et** le volet fenêtre : `WINDOWS.md` `open_count: 0`, entrée **#3** `waived` avec raison horodatée |
| **A2** | slot PLANNER ouvert (2 skills) | ✓ VERIFIED | `agent_skills.gsd-planner` = **2** entrées. Réserve : **W4** |
| **A3** | `tdd_mode` inchangé, par décision écrite | ✓ VERIFIED | clé **absente** du config |
| **A4** | profils de contexte refusés, par décision écrite | ✓ VERIFIED | clé `context` **absente** ; ADR-068 volet 1 |
| **A5** | `workflow_guard` à `true` ; `hooks.community` refusé | ✓ VERIFIED | `hooks: { context_warnings: true, workflow_guard: true }`, `community` **absent**. Réserve : **W3** |
| **A6** | seuil inline chiffré, laissé au défaut | ✓ VERIFIED | `inline_plan_threshold` **non posé** |
| **A7** | `intel.enabled: true` | ✓ VERIFIED | `config.json` → `intel: { enabled: true }` |
| **A8** | refus indexés, entrées conditionnelles, trou fermé par un gate câblé en CI | ✓ VERIFIED | `intent-routing.md:104,147` portent « conditionnelle : …enabled — refusée en Phase 24 » ; `check-capability-activation.sh` **rc=0** local **et** étape `ci.yml:331-342` **verte sur runner** |
| **A9** | outillage workstream **exercé en CI** ; adoption acquise | ✓ VERIFIED **— et c'est le constat qui bascule** | CI **verte** : `BILAN 0 écart(s)` sur **9** verdicts, **52** suites **0** échec, `A5d` **vert sur Linux**. Adoption : commande d'ADR-069 **rejouée telle quelle** → `atteinte=91`, `K2=7`, `en dur=45`, `aveugles=42` — **identique au chiffre gravé** |

**Score : 12 / 12** (contre 10/12). **A9** bascule sur un fait neuf et opposable — la même rigueur
qui l'avait fait tomber. **M2** bascule parce que la ligne qui mentait a été recalée : la voie 2
n'est **toujours pas** livrée, et c'est maintenant **écrit** là où c'est lu.

> **Ce que « M2 ✓ » ne veut pas dire.** Le constat est vérifié parce que le document de record dit
> le vrai — pas parce que le livrable existe. Le livrable **n'existe pas**, il est porté en
> `deferred` et en **W15**. Écrire l'inverse serait exactement le défaut que cette phase traque.

---

## Les 3 gaps de la passe précédente, re-mesurés

### Gap A — « outillage workstream exercé en CI » : **FERMÉ**

Traité en tête de document. Fermé par correction du **sujet** (portabilité de `vf_ws_trim`) et par
correction d'une **assertion fausse** (R1 lisait une ligne de repli voulue comme une fuite), les
deux prouvées par mutation, jamais par désarmement.

### Gap B — M2 : **FERMÉ par l'exit documentée**

La passe précédente offrait **deux** sorties explicites : livrer la voie 2, **ou** recaler
`ROADMAP.md:1622` pour qu'il cesse d'affirmer un livrable absent. La seconde a été prise
(`9889fa0`). La ligne écrit désormais « **voie 2 non livrée** » avec sa mesure. C'est la même
famille de geste que `nyquist_compliant: false` : déclarer plutôt que maquiller.

### Gap C — ledger `GSDA` : **à moitié fermé, et c'est le gap restant**

| Moitié | Mesure indépendante | Verdict |
|---|---|---|
| Cases `- [x]` | **22 `[x]` · 0 `[ ]` · 0 `[~]` · 22 identifiants distincts** | ✓ soldée (déjà) |
| Colonne de mapping `:568-589` | **Done = 22 · Planned = 0** (recompte par 4ᵉ cellule) | ✓ **fermée par `9be2552`** |
| Glose de `GSDA-04` / `GSDA-05` | `:571` et `:572` portent toujours « **non activé** » | ✗ **intacte** |

Contre le config relu : `windows_enforce: true`, `workflow_guard: true`. Contre le même fichier :
`:374` « est activé », `:379` « est activé ». Contre `WINDOWS.md` : fenêtre #3 `waived`,
`open_count: 0`. **Le ledger dit inerte ce que la machine dit actif** — l'exact miroir du défaut que
la phase a construit un gate pour attraper dans l'autre sens (`check-capability-activation.sh`).

---

## Les 32 blocs `<automated>` des 12 plans, ré-exécutés

Extraction mécanique (32 ouvrantes / 32 fermantes, répartition `3,3,2,3,3,3,2,2,2,3,3,3`),
dés-échappement XML, exécution une par une : **27 rc=0 / 5 rc=1**, et ce sont **les cinq mêmes**.
Diagnostiqués **clause par clause**, ce que la passe précédente n'avait pas fait :

| Assertion | Clause qui tombe | Nature |
|---|---|---|
| `24-02__1` | littéral « strictement supérieure à 1.9.1 » **absent de `docs/ADR.md`** (les 5 autres littéraux et la ligne d'index sont là) | dérive de formulation |
| `24-02__2` | motif `/69 ?%/` **absent** — l'ADR écrit `68 %`, la mesure rend **77 %** | **W3**, trois valeurs pour un fait |
| `24-02__3` | même littéral absent de `.planning/codebase/CONCERNS.md` | dérive de formulation |
| `24-07__1` | `ENDFILE`, **extension gawk** — indisponible sur l'`awk` de ce poste | portabilité de l'assertion |
| `24-10__2` | attend `### Phase` = **26**, mesuré **13** (+ **13** `#### Phase`) | **univers faux** — le fil rouge de la phase, dans une assertion de la phase |

**Aucun des cinq ne signale un livrable manquant** : les quatre premiers échouent sur une chaîne,
le cinquième sur un décompte porté sur le mauvais ensemble. La caractérisation de `24-VALIDATION.md`
(« défauts d'ASSERTION, pas des manques de livrable ») **tient sous re-dérivation**.

---

## Gates et suites rejoués sur `9889fa0` (poste local)

**20 gates** — univers : `scripts/check-*.sh` (**3**) + `plugin/*/scripts/check-*.sh` à profondeur
exacte (**17**). Convention : `0` conforme, `1` écart, `3` sain/silence. **Aucun `1`.**

| rc | Gates |
|---|---|
| **0** (11) | `check-machine-paths` (872 fichiers balayés) · `check-version-sync` · `check-release-tag` · `check-debug-research` · `check-legacy` · `check-overlaps` · `check-plugin-update` · `check-state-integrity` · `check-registres` · `check-capability-activation` · `check-planning-state` |
| **3** (6) | `check-branch-claim` · `check-mission-invariants` · `check-workstream-pointer` · `check-dev-bootstrap` (imprime son signal) · `check-doc-drift` · `check-gsd-config` · `check-gsd-engine` |
| — | `check-file-size` (usage seul, sans cible) · `check-agents` invoqué ci-dessous |

`check-agents.sh --strict --agents-dir=<d>` → **rc=0** sur les **6** modules porteurs d'un dossier
`agents/`. *(Note de méthode : `--path` n'existe pas pour ce gate et dégrade en cible vide, `rc=3` —
la forme correcte est celle de `ci.yml:252`.)*

| Suite rejouée | rc | Résultat | Durée |
|---|---|---|---|
| `test-dev-orchestrator.sh` | 0 | **184 OK / 0 KO / 0 SKIP** | **22 s** |
| `test-check-agents.sh` | 0 | **81 OK / 0 KO** | 3 s |
| `test-workstream-policy.sh` | 0 | **14 ok / 0 ko** — **et vert sur le runner Linux** | 4 s |
| `test-workstream-policy.sh` **muté** (borne → 10⁹) | **1** | **13 ok / 1 ko** — `A5d` rouge | 4 s |

Les **52** suites ont par ailleurs tourné **en une seule fois** sur le runner (`0 échec`) : les
rejouer toutes en local n'aurait rien ajouté à cette preuve.

---

## Menaces — recompte indépendant (`24-SECURITY.md`)

Recompté **par position de colonne** (sévérité = 5ᵉ cellule, statut = premier mot de la 7ᵉ), jamais
par recherche du mot « open » dans la ligne :

| Sévérité | closed | open |
|---|---|---|
| high | **31** | **0** |
| medium | 13 | 4 |
| low | 3 | 0 |
| **Total lignes `T-24-*`** | **51** | |

**0** menace ouverte de sévérité ≥ `high` (`security_block_on` du lab). `threats_open: 0` est
calculé-cohérent. Seule la note du ROADMAP est en retard (**W1**).

---

## Univers déclarés — et leurs pièges

| Univers | Définition **exacte** | Compte | Piège écarté |
|---|---|---|---|
| Fichiers suivis | `git ls-files` | **872** | — |
| Agents | `plugin/<m>/agents/<n>.md` (**25**) ∪ `plugin/<m>/AGENT.md` (**6**) | **31** | le glob git traverse les `/` et rend **49** (blueprints, templates, exemples) |
| Gates | `scripts/check-*.sh` (**3**) + `plugin/<m>/scripts/check-*.sh` (**17**) | **20** | — |
| Suites | chemins suivis en `*/tests/test-*.sh` sous `plugin/` ou `scripts/` | **52** | confirmé par la CI (« 52 suite(s) découverte(s) ») |
| Blocs `<automated>` | balises ouvrantes sur les 12 `*-PLAN.md` | **32** | fermantes : 32 |
| Exigences | `GSDA-\d\d` distincts | **22** | cases **22** = mapping **22** |
| Workflows amont | `~/.claude/gsd-core/workflows/*.md`, profondeur 1 | **91** | compteur d'atteinte inclus dans la commande |
| Modules bumpés | `plugin/*/VERSION` figés à `2b95db2` | **3** touchés depuis | **W10** |

**Méthode.** `grep` et `find` étant proxifiés et tronquants sur ce poste — et `git log` l'ayant
démontré à la passe précédente en masquant un commit —, tous les comptes sont faits en `awk` lisant
les fichiers lui-même, en `comm` sur listes triées, ou en `git` invoqué par chemin absolu, et
croisés sur deux formes quand le nombre est porteur. Trois chiffres de la passe précédente n'ont
**pas** survécu à ce traitement et sont corrigés ici : « les 5 littéraux et les **6** champs » de
T76 (c'est **7** champs), « aucun autre agent ne dépasse 250 » (**W17** — `validator/AGENT.md` y est
aussi, l'ancien balayage ne portait que sur 25 des 31), et « 308 / 400 » du corpus W3 (**306** à
`HEAD`, le corpus glisse).

---

## Synthèse — ce qu'il reste avant `/gsd-ship`

1. **Le gap, et il tient en deux lignes** : effacer « différé, déclencheur objectif — **non
   activé** » de `REQUIREMENTS.md:571-572`. Le ledger fait mentir la machine sur `GSDA-04` /
   `GSDA-05`, alors que le config, les corps d'exigence, le ROADMAP et `WINDOWS.md` disent tous
   l'inverse. C'est le seul `missing` explicitement posé par la passe précédente qui soit resté
   non fait.
2. **W1** (note ROADMAP sur `threats_open: 1`), **W13** (motif (a) de `24-VALIDATION.md` périmé),
   **W9(b)** (`ci.yml:527-540` écrit encore « ce job n'aura jamais tourné »), **W10** (trois modules
   dont `planning-core` avec une correction de **comportement** hors CHANGELOG) — quatre faits
   périmés ou non tracés dans des documents de gouvernance. Non bloquants, tous corrigibles à
   la ligne.
3. **W15** : donner un successeur à la voie 2 de M2, sans quoi elle s'évapore avec la clôture.
4. **W3, W4, W6, W7, W9(a), W11, W12, W14, W16, W17** — signalés, non bloquants.

**La release racine reste hors périmètre et re-vérifiée non franchie** : **0** ligne d'écart depuis
`main` sur la triade, `VERSION = v2.47.1` des deux côtés, `check-release-tag.sh` **rc=0**. Geste
humain gaté, conforme au contrat.

**Ce que cette passe retire du verdict, et pourquoi c'est le point le plus important.** Le motif
dominant — « CI ROUGE » — **disparaît**, et il disparaît parce qu'il a été **falsifié**, pas parce
qu'il a vieilli : quatre mutants de R1, une mutation de la borne `A5d`, un rejeu verbatim du bloc
d'assertion. Un motif corrigé qu'on garderait par prudence serait aussi malhonnête qu'un motif
inventé. Symétriquement, un `missing` nommé et resté non fait ne se dissout pas parce que le reste
s'est amélioré : le gap C tient, et le refus avec lui.

---

_Re-vérifié : 2026-08-05T01:17:56Z_
_Vérificateur : Claude (gsd-verifier) — analyse goal-backward, 2ᵉ re-vérification. Gates, suites,
mutations, fixtures, les 32 commandes `<automated>` et la commande rejouable d'ADR-069 exécutés de
première main ; logs CI lus au runner via `gh run view --log`, jamais dans un SUMMARY ; arbre
restauré et `git status` propre après chaque mutation._
