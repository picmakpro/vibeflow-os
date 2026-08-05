---
phase: VFDO-24-activation-et-mesure-du-moteur-gsd-capacit-s-dormantes-et-fa
verified: 2026-08-05T01:27:19Z
status: passed
verdict: PASS — CI verte prouvée par mutation, ledger cohérent, 12/12, 0 gap
score: 12/12 constats du tableau de clôture vérifiés — 0 gap
behavior_unverified: 0
overrides_applied: 0
diff_verified: fbdb300..0a875ef (103 commits, branche feat/phase-24-activation-moteur-gsd, PR #34)
re_verification:
  passes: 3
  previous_verified: 2026-08-05T01:17:56Z
  previous_status: gaps_found
  previous_verdict: PASS — 1 gap de ledger
  previous_score: 12/12 avec 1 gap transverse
  diff_since_previous_document: 9723e92..0a875ef (1 commit — 0a875ef, 1 fichier, +9/-3)
  gaps_closed:
    - "L'outillage workstream est exercé en CI, et la CI de la branche certifie la phase (passe 2 — fermé par correction du sujet ET d'une assertion fausse, les deux prouvées par mutation)"
    - "M2 — le tableau qui fait foi cesse d'affirmer un livrable absent (passe 2)"
    - "Le ledger d'exigences ne se contredit pas lui-même (passe 3 — `0a875ef` : les 2 lignes de mapping ET la note d'ordre imposé qui en était la source amont)"
  gaps_remaining: []
  gaps_new: []
  regressions: []
  warnings_new: [W18]
gaps: []
deferred:
  - truth: "Publier une release racine (bump de la triade, tag annoté, release GitHub, check-release-tag.sh --remote ✓)"
    addressed_in: "Geste humain post-fusion, réservé à Samuel (CLAUDE.md § Discipline de release)"
    evidence: >
      Frontière re-vérifiée **non franchie** à `0a875ef` : `git diff --name-only main..HEAD` sur
      `VERSION`, `plugin/.claude-plugin/plugin.json` et `.claude-plugin/marketplace.json` rend
      **0 fichier** ; `VERSION` = `v2.47.1` des deux côtés ; `scripts/check-release-tag.sh` sort en
      **rc=0**. Ce n'est pas un manque, c'est le contrat.
  - truth: "M2 voie 2 — remonter en amont que `backgroundDispatch: false` est fail-closed et non descriptif du runtime Claude Code"
    addressed_in: "Aucune phase, aucun BACKLOG — **non-livrable désormais déclaré**, mais sans successeur"
    evidence: >
      `ROADMAP.md:1622` déclare explicitement « **voie 2 non livrée** ». La mesure le confirme :
      `.planning/upstream/` contient **un seul fichier** (`2026-08-04-workflows-aveugles-aux-workstreams.md`,
      GSDA-19) et **0** occurrence de `backgroundDispatch`. Le fait n'est plus travesti — voir
      **W15** pour le fait qu'il n'est suivi nulle part.
warnings:
  - id: W1
    status: toujours ouvert
    severity: fait périmé dans le document qui fait foi — non bloquant
    statement: >
      La note de fin de section ROADMAP (`:1697-1700`) écrit toujours que « le gate de sécurité reste
      **bloquant** (`24-SECURITY.md`, `threats_open: 1`) sur `T-24-02-01` ». **Périmé.** Recompté
      indépendamment par position de colonne (sévérité = 5ᵉ cellule, statut = premier mot de la 7ᵉ —
      jamais par recherche du mot « open » dans la ligne, qui produit un faux positif dans la prose
      des mitigations) : sur les **51** lignes `T-24-*`, **31 high closed · 13 medium closed ·
      4 medium open · 3 low closed**. Soit **0** menace ouverte de sévérité ≥ `high`
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
      caractères, `awk`) : **306 / 400 = 77 %** (308 à la passe 2, 305 à l'initiale — le corpus
      glisse, la conclusion pas) ; variante `>= 72` → **312**. La conclusion de l'ADR (« le hook
      rejetterait plus des deux tiers de notre manière d'écrire ») en sort **renforcée**, jamais
      affaiblie. Corollaire machine : c'est ce chiffre qui fait rougir l'assertion `<automated>`
      `24-02__2`, laquelle épingle `69 %` — **trois valeurs pour un même fait** (69 pinné, 68 gravé,
      77 mesuré).
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
      `24-SECURITY.md:4` porte toujours `status: draft` avec `audited: 2026-08-05` et
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
      est **exactement à la ligne 60**, et la garde de `check-dev-bootstrap.sh:215` est
      `NR > 60 { exit }`. Une ligne de plus et le signal de démarrage se retait. Aucun garde-fou
      machine ne surveille cette borne : `test-check-dev-bootstrap.sh` n'a **aucun cas de
      dépassement** (ses seules occurrences de « borne » portent sur la borne d'octets du pointeur).
      **(b) Rationnel de `ci.yml` : la moitié qui rougissait est refaite, celle qui précède ne l'est
      pas.** Le bloc `:543-563` a été intégralement réécrit par `e6ac65b` et décrit l'état réel. Mais
      `:527-540`, juste au-dessus, écrit encore « **CE JOB N'AURA JAMAIS TOURNÉ POUR DE VRAI** » (il
      a tourné **10 fois** sur cette branche) et « le frontmatter de `.planning/STATE.md` fait
      **81 lignes** […] **stdout VIDE** » (il fait **60**, et stdout porte **169** caractères). Un
      relecteur qui commence par le haut se forme l'inverse de l'état courant.
    suggestion: "Ajouter un cas « frontmatter de 61 lignes → silence » à test-check-dev-bootstrap.sh, et purger le rationnel périmé de ci.yml:527-540."
  - id: W10
    status: toujours ouvert
    severity: traçabilité de distribution — non bloquant
    statement: >
      Trois modules portent du **contenu distribué posé après leur bump**, sans entrée de CHANGELOG.
      Les `VERSION` des trois ont été figées au commit `2b95db2` (plan 24-12) ; depuis :
      `plugin/conductor` (**4** commits de contenu, dont la doctrine M2 de `team-kernel.md`),
      `plugin/dev-orchestrator` (**3**, dont Pattern G), et — le plus lourd — `plugin/planning-core`
      (**4**, dont **`b25ed19`, une correction de COMPORTEMENT** : la borne de sûreté
      `VF_WS_VALUE_MAX_BYTES` ne s'appliquait pas sur Linux). Le CHANGELOG de `planning-core v2.6.0`
      ne mentionne **pas** ce correctif : un seul commit a touché les trois CHANGELOG depuis le bump
      (`55d1c58`, sur le correctif symlink). `scripts/check-version-sync.sh` sort en **rc=0** — il
      vérifie la cohérence de la triade, jamais l'adéquation contenu ↔ bump.
    suggestion: "Une entrée de CHANGELOG sous la version courante des trois modules, ou un bump patch avant la fusion."
  - id: W11
    status: toujours ouvert
    severity: périmètre de branche — non bloquant
    statement: >
      Le commit `479eee9` (Pattern G) n'est réclamé par aucun plan, aucune `GSDA`, aucun
      `*-SUMMARY.md` : balayage `awk` de « Pattern G » sur les **872** fichiers suivis → les seules
      occurrences hors de ce document sont les **2** du contenu distribué (`vf-dev-manager.md:176`,
      `mission-flow.md:350`). Le contenu est légitime et sa conformité tient
      (`check-agents.sh --strict --agents-dir` → **rc=0** sur les **6** modules porteurs d'un dossier
      `agents/`), mais il entre en distribution sans porteur documentaire.
    suggestion: "Nommer Pattern G dans le SUMMARY de clôture ou dans le tableau du ROADMAP."
  - id: W12
    status: toujours ouvert
    severity: écart de mesure sans conséquence — non bloquant
    statement: >
      `24-VALIDATION.md` annonce une latence de retour de **37 s** au pire cas
      (`test-dev-orchestrator.sh`). Re-chronométrée de première main : **22 s** (184 OK / 0 KO /
      0 SKIP), après **24 s** la veille. Deux mesures indépendantes sous la moitié de la valeur
      annoncée : ce n'est plus du bruit, c'est une valeur unique qui ne décrit pas la distribution.
      Le critère de sign-off (« Feedback latency < 60 s ») tient dans tous les cas.
    suggestion: "Écrire « ~20-40 s selon charge » plutôt qu'une valeur unique."
  - id: W13
    status: toujours ouvert
    severity: fait périmé dans un document de gouvernance — non bloquant
    statement: >
      `24-VALIDATION.md` motive sa non-conformité Nyquist par **trois motifs cumulés**, et son
      motif **(a)** est **FAUX** depuis `b25ed19`/`e6ac65b` : « **La CI est ROUGE sur la branche
      poussée** […] les 2 derniers sur la tête poussée `7e3c39c` ». Le document le qualifie lui-même
      de « **le plus grave des trois** ». Les motifs **(b)** et **(c)** **tiennent**, re-dérivés
      ici : (b) les **32** blocs `<automated>` ré-extraits, dés-échappés et ré-exécutés rendent
      **27 rc=0 / 5 rc=1**, et ce sont **les mêmes cinq** ; (c) le document reste renseigné a
      posteriori. `nyquist_compliant: false` reste donc **juste** — mais pour deux motifs, plus
      trois. **Ce n'est pas un gap** : le gap Nyquist était l'**absence** du document, elle est
      soldée, et le refus de forger un `true` reste le bon geste.
    suggestion: "Barrer le motif (a) en le datant, sans toucher à nyquist_compliant."
  - id: W14
    status: toujours ouvert
    severity: chiffre auto-référentiel — non bloquant
    statement: >
      `ROADMAP.md:1622`, écrit par `9889fa0`, affirme « `backgroundDispatch` compte **24
      occurrences** sur 872 fichiers suivis ». Re-dérivé par balayage `awk` de **toutes** les
      occurrences (pas des lignes porteuses) sur `git ls-files` : **25**. Le compte était juste **au
      commit parent** (`9be2552` : le ROADMAP en portait 4, il en porte 5) — **c'est l'écriture du
      chiffre qui a changé le chiffre**. Le fait porteur, lui, est intact et c'est celui qui compte :
      **0** occurrence dans `.planning/upstream/`, qui contient **un seul fichier**. Le même piège
      vaut pour ce document-ci, qui en ajoute d'autres.
    suggestion: "Écrire « 0 dans .planning/upstream/ » sans total absolu, ou dater le total et nommer le commit de mesure."
  - id: W15
    status: toujours ouvert
    severity: livrable abandonné sans successeur — non bloquant
    statement: >
      La recalibration de `ROADMAP.md:1622` supprime la falsité, mais **n'ouvre aucune suite** :
      `.planning/BACKLOG.md` ne porte aucune occurrence de `backgroundDispatch` ni de « remontée
      amont », et les deux seules phases postérieures du jalon (**25** budget d'instructions,
      **26** manuel utilisateur) ne la couvrent pas. La voie 2 était présentée au cadrage
      (`ROADMAP.md:1435-1437`) comme un **bénéfice collectif** (« débloquerait le parallélisme
      intra-étape pour tous les labs ») et l'option 3 (`claude_orchestration`) est écartée « **à
      reconsidérer si la voie 2 échoue** » — ce conditionnel n'a plus de branche vivante.
    suggestion: "Une entrée BACKLOG nommant la voie 2 et son déclencheur, pour qu'elle ne s'évapore pas avec la clôture."
  - id: W16
    status: toujours ouvert
    severity: chiffre de commentaire non reproductible — non bloquant
    statement: >
      Le rationnel réécrit de `ci.yml:550-551` affirme que le stdout du gate porte « le signal métier
      réel (« … orientation gsd-engine », **137 octets**) ». Mesuré de première main : le stdout fait
      **169 caractères** (`${#var}` sous locale UTF-8 — c'est la grandeur que l'étape imprime
      réellement, et le runner affiche bien 169) et **177 octets** (`wc -c`). **137 ne correspond à
      ni l'un ni l'autre.** Le label de l'étape dit « octet(s) » là où bash compte des caractères.
      Sans effet sur l'assertion, qui compare des chaînes et non des longueurs.
    suggestion: "Recaler 137 → 169, et dire « caractère(s) » dans le label de l'étape."
  - id: W17
    status: toujours ouvert
    severity: plafond ADR-029 atteint hors du périmètre gardé — non bloquant
    statement: >
      Deux agents sont **exactement à 250 lignes**, le plafond ADR-029 : `vf-dev-manager.md`
      (marge 0, **machine-gardée** — `test-dev-orchestrator.sh` T35 (d) et (e) prouvent le plafond
      détectable par mutation à 255) et **`plugin/validator/AGENT.md`**, passé de **249 à 250** par
      `a781090` et **gardé par rien**. Corollaire : la passe 2 écrivait « aucun autre agent du dépôt
      ne dépasse 250 (balayage des **25** fichiers `plugin/*/agents/*.md`) » — **balayage juste sur
      le mauvais ensemble**, celui-là même que la phase s'est donné pour règle de ne plus commettre :
      les **6** `AGENT.md` en étaient exclus.
    suggestion: "Étendre le contrôle de plafond aux 31 agents (25 + 6), ou reprendre une ligne à validator/AGENT.md."
  - id: W18
    status: nouveau — résiduel de la fermeture du gap de ledger
    severity: lisibilité d'un record de cadrage — non bloquant
    statement: >
      `0a875ef` a levé la contradiction **là où elle était fausse** (les deux lignes de mapping et la
      note d'ordre imposé qui en était la source amont). **Trois formulations de cadrage
      subsistent**, et elles ne sont pas fausses — elles décrivent l'état **au plan du 2026-08-04**,
      avant ADR-066 — mais un lecteur de clôture les prendra pour l'état courant :
      `REQUIREMENTS.md:383` et `:387` portent « **Gaté sur `GSDA-01`.** » dans les corps de
      `GSDA-04`/`GSDA-05`, et `:624-628` écrit « **`GSDA-04` et `GSDA-05` sont planifiés en DIFFÉRÉ
      ÉCRIT, pas en activation** […] la clause de repli de `GSDA-01` **s'applique** ». Le même
      fichier écrit désormais, 263 lignes plus haut (`:361`), « **activés**, pas différés ».
      **Pourquoi c'est un warning et pas un gap** : le défaut que la vérification opposait était une
      **falsité** (« non activé » sur une clé à `true`) ; elle est supprimée. Ce qui reste est un
      record de cadrage dont la lecture temporelle est exacte — même famille que **W1**, **W6**,
      **W9(b)** et **W13**, tous classés warnings. En faire un blocage après avoir classé W1 (une
      affirmation **fausse** dans un document qui fait foi) en warning serait incohérent, et
      l'incohérence est ce qui fait perdre sa valeur à un verdict.
    suggestion: "Mettre :383/:387/:624-628 à l'imparfait, comme :353 vient de l'être, ou y renvoyer à ADR-066."
behavior_unverified_items: []
human_verification: []
---

# Phase 24 : Activation et mesure du moteur GSD — Rapport de VÉRIFICATION (3ᵉ passe)

**Goal ROADMAP** : cesser de payer l'installation d'un moteur sans en prendre les bénéfices —
**activer** les capacités GSD déjà installées mais dormantes, **mesurer** les faits de runtime que
VibeFlow présume, et **fermer** les routes qui mènent à un geste inerte.

**Vérifié** : 2026-08-05T01:27:19Z · **`HEAD`** : `0a875ef` (`git rev-parse`, arbre de travail
**propre**, `git ls-remote` rend la **même** empreinte) · **Diff global** : `fbdb300..0a875ef`
(**103** commits) · **Depuis la passe 2** : **1** commit, **1** fichier (+9 / −3).
**Verdict** : **PASS — 12 / 12 constats, 0 gap.**

---

## Le dernier gap est fermé — et il l'est à sa source, pas seulement à sa surface

Le gap de la passe 2 tenait en une falsité : `.planning/REQUIREMENTS.md:571-572` déclarait
`GSDA-04` / `GSDA-05` « **différé**, déclencheur objectif — **non activé** » alors que les deux clés
étaient à `true`. Le commit `0a875ef` (`+9 / −3`, **un seul fichier**) fait deux choses, dont **une
que je n'avais pas demandée** :

1. **Les deux lignes de mapping** portent l'état réel — et rien d'autre.
2. **La note d'« ordre imposé »** (`:353`), qui posait `GSDA-01` en prérequis dur **au présent**,
   passe à l'imparfait et gagne un paragraphe qui **écrit pourquoi** le gate a été relâché. C'était
   la source amont de l'incohérence : recaler les deux lignes sans elle aurait laissé la
   contradiction se reformer à la première relecture.

### Les six sources doivent dire la même chose — re-dérivées une par une

| Source | Ce qu'elle dit à `0a875ef` | Mesure |
|---|---|---|
| Table de mapping `:577-578` | « `windows_enforce: true`, fenêtre #3 dérogée » · « `workflow_guard: true` » — les deux renvoient à **ADR-066** | balayage : **0** ligne `GSDA-\d\d` portant encore « non activé » |
| Note d'ordre imposé `:353-361` | « **était** un prérequis dur » + « Gate relâché le 2026-08-04 (ADR-066) […] **activés**, pas différés » | lu sur pièce |
| Corps d'exigence `:380`, `:385` | « `workflow.windows_enforce` **est activé** » · « `hooks.workflow_guard` **est activé** » | lu sur pièce |
| `.planning/config.json` | `workflow.windows_enforce: true` · `hooks.workflow_guard: true` (et `community` **absent**) | relu à `HEAD` |
| `ROADMAP.md:1624`, `:1628` | A1 « **PÉRIMÉ** — présent et à **`true`** (dégel, ADR-066) » · A5 « **à `true`** » | lu sur pièce |
| `.planning/WINDOWS.md` | `open_count: 0`, `waived_count: 1`, entrée **#3** en `waived` | frontmatter + 8ᵉ cellule de la ligne 3 |

**Les six concordent.** La contradiction est levée.

### Les faits que la nouvelle note invoque — re-dérivés, pas crus

Elle ne se contente pas d'affirmer : elle renvoie à ADR-066 et en reprend les deux fondements. J'ai
mesuré les deux moi-même :

| Affirmation | Ma mesure indépendante | Verdict |
|---|---|---|
| « `WINDOWS.md` ne porte **aucune prose sous son ledger** » — c'est ce que le bug amont #2893 détruirait | balayage des lignes non vides **après** la fin du bloc `json` : **0** | ✓ le risque protégé est **absent de ce dépôt** |
| « **87 lignes** et miroir JSON intacts » | `awk END{NR}` → **87** ; bloc JSON `:24-87` extrait et parsé par `node` → **valide, 5 entrées, 1 `waived` (id 3), 0 `open`** — cohérent avec `total_count: 5` / `waived_count: 1` / `open_count: 0` | ✓ exact |
| ADR-066 existe et dit cela | `docs/ADR.md:1565` — « **La zone 2 est activée, pas différée — un prérequis insatisfiable ne gate pas** », **Statut : Validée**, 2026-08-04, et ses deux motifs sont mot pour mot ceux repris dans la note | ✓ |
| « aucune version npm > 1.9.1 » | **non re-testé ici** (fait externe, daté du 2026-08-04, établi par `24-RESEARCH.md` R-1 et gravé dans ADR-066 avec `dist-tags.latest = 1.9.1`) | fait hérité, non contredit |

### Ce qui reste, et pourquoi ce n'est pas un gap

Trois formulations de **cadrage** subsistent (`:383`, `:387` « Gaté sur `GSDA-01`. » ; `:624-628`
« sont planifiés en DIFFÉRÉ ÉCRIT, pas en activation »). Elles ne sont **pas fausses** : elles
décrivent l'état au plan du 2026-08-04, avant ADR-066 — et je les avais moi-même adjugées « **vrai
du CADRAGE** » et leur remédiation « accessoire » à la passe 2. Le défaut que la vérification
opposait était une **falsité**, et la falsité est supprimée.

**Le test de cohérence qui tranche** : `W1` — la note ROADMAP qui écrit `threats_open: 1` quand la
mesure rend `0` — est une affirmation **plainement fausse** dans un document qui fait foi, et elle
est classée **warning**. Bloquer sur un record de cadrage temporellement exact tout en laissant
passer une falsité serait incohérent. Le résiduel devient **W18**.

---

## Vérité par constat du tableau de clôture (`ROADMAP.md:1619-1632`)

| # | Constat | Statut | Preuve re-dérivée |
|---|---|--------|--------|
| **M1** | profondeur de dispatch écrite dans les agents | ✓ VERIFIED | `team-kernel.md:33-36` porte le descripteur verbatim ; `T76` exige **5 littéraux** et **7 champs** ; `test-check-agents.sh` → **81 OK / 0 KO** |
| **M2** | voie 1 livrée · **voie 2 non livrée** | ✓ VERIFIED **en tant que constat** | Voie 1 sur pièce : `team-kernel.md:55-89`, prescriptive. Voie 2 : `.planning/upstream/` = **1** fichier, **0** `backgroundDispatch` — et `:1622` **le dit**. Réserves : **W14**, **W15** |
| **M3** | `effort:` déclaré par **31 agents sur 31** | ✓ VERIFIED | univers redéfini à la main (le glob git traverse les `/` et rend **49** : piège écarté) → **25** + **6** = **31** ; **31 porteurs, 0 manquant** |
| **A1** | `windows_enforce` présent et à `true` | ✓ VERIFIED | config `true` ; `WINDOWS.md` `open_count: 0`, fenêtre **#3** `waived` ; ledger désormais concordant |
| **A2** | slot PLANNER ouvert (2 skills) | ✓ VERIFIED | `agent_skills.gsd-planner` = **2**. Réserve : **W4** |
| **A3** | `tdd_mode` inchangé, par décision écrite | ✓ VERIFIED | clé **absente** |
| **A4** | profils de contexte refusés, par décision écrite | ✓ VERIFIED | clé `context` **absente** ; ADR-068 volet 1 |
| **A5** | `workflow_guard` à `true` ; `hooks.community` refusé | ✓ VERIFIED | `workflow_guard: true`, `community` **absent**. Réserve : **W3** |
| **A6** | seuil inline chiffré, laissé au défaut | ✓ VERIFIED | `inline_plan_threshold` **non posé** |
| **A7** | `intel.enabled: true` | ✓ VERIFIED | `intel: { enabled: true }` |
| **A8** | refus indexés, entrées conditionnelles, trou fermé par un gate câblé en CI | ✓ VERIFIED | `intent-routing.md:104,147` conditionnelles ; `check-capability-activation.sh` **rc=0** **et** étape `ci.yml:331-342` **verte sur runner** |
| **A9** | outillage workstream **exercé en CI** ; adoption acquise | ✓ VERIFIED | CI **verte** ; commande d'ADR-069 rejouée → `atteinte=91`, `K2=7`, `en dur=45`, `aveugles=42` — **identique au chiffre gravé** |

**Score : 12 / 12 · 0 gap.**

> **Ce que « M2 ✓ » ne veut pas dire.** Le constat est vérifié parce que le document de record dit
> le vrai — pas parce que le livrable existe. Le livrable **n'existe pas**, il est porté en
> `deferred` et en **W15**.

---

## La CI, re-vérifiée sur la tête courante — et gagnée par mutation, pas par désarmement

Un vert s'obtient aussi bien en désarmant l'assertion qu'en corrigeant le sujet. C'est ce que la
passe 2 a cherché, et le résultat tient à `0a875ef`.

| Fait | Mesure |
|---|---|
| Runs sur **`0a875ef`** | `30966241888` (push) et `30966243730` (pull_request) — **`success`**, **3 jobs sur 3** chacun |
| PR #34 | `OPEN`, `MERGEABLE`, **8 / 8** checks `SUCCESS` |
| Historique de la branche | **10** runs : **4 verts** (les 2 têtes récentes), **6 rouges** (jusqu'à `479eee9` inclus) |

**R1 n'a pas été désarmée** — bloc `ci.yml:564-588` rejoué verbatim en local à `HEAD` (**stdout
169/169, stderr hors-repli 73/73, 0 écart**, identique au runner), puis quatre sujets mutants :

| Mutant | Ce qu'il simule | Verdict | Attendu |
|---|---|---|---|
| **A** | le gate **fuit** `GSD_WORKSTREAM` dans **stdout** | **ROUGE** | rouge ✓ |
| **B** | stderr change **hors** du motif de repli documenté | **ROUGE** | rouge ✓ |
| **C** | les **deux** stdout sont vides | **ROUGE** — plancher « NON OPPOSABLE » conservé | rouge ✓ |
| **D** | **seule** la ligne de repli documentée diffère | **VERT** | vert ✓ |

**La borne du canal nominal est vivante** — `VF_WS_VALUE_MAX_BYTES` portée de `4096` à `10⁹` →
suite à **13 ok / 1 ko, rc=1**, `A5d` rouge avec `nom=[aaaa…]` : la valeur **atteint** désormais la
garde, là où le runner d'avant `b25ed19` rendait `nom=[]` (signature de la sortie prématurée `:293`,
`execve(awk)` en `E2BIG` sous `MAX_ARG_STRLEN`). Arbre restauré, `git status` propre.

---

## Gates, suites et frontière — rejoués à `0a875ef`

**18 gates exécutables** (`scripts/check-*.sh` = 3 · `plugin/*/scripts/check-*.sh` = 17, moins
`check-agents.sh` et `check-file-size.sh` qui exigent une cible) : **11 en `rc=0`**, **7 en `rc=3`**
(sain / silence), **0 écart**. `check-agents.sh --strict --agents-dir` → **rc=0** sur les **6**
modules porteurs d'un dossier `agents/`.

| Suite | rc | Résultat |
|---|---|---|
| `test-dev-orchestrator.sh` | 0 | **184 OK / 0 KO / 0 SKIP** (22 s) |
| `test-check-agents.sh` | 0 | **81 OK / 0 KO** |
| `test-workstream-policy.sh` | 0 | **14 ok / 0 ko** — **et vert sur le runner Linux** |
| `test-workstream-policy.sh` **muté** | **1** | **13 ok / 1 ko** — `A5d` rouge : la sonde discrimine |

Les **52** suites ont tourné en un seul passage sur le runner (`0 échec`).

**Ledger d'exigences** : **22** cases `- [x]` · **0** `[ ]` · **0** `[~]` · **22** identifiants
distincts · table de mapping **22 « Done », 0 « Planned »**, **0** ligne portant « non activé ».

**Menaces** : **51** lignes `T-24-*` → **31 high closed · 13 medium closed · 4 medium open ·
3 low closed**. **0** ouverte de sévérité ≥ `high`. `threats_open: 0` calculé-cohérent.

**Marqueurs de dette** : `0a875ef` n'en introduit **aucun** (`TBD`/`FIXME`/`XXX`/`TODO` sur les
lignes ajoutées : néant). Les `TBD` présents dans `ROADMAP.md` / `REQUIREMENTS.md` sont les
placeholders idiomatiques des phases **non encore planifiées** (`TBD (run /gsd-plan-phase 25 to
break down)`) et préexistent à cette phase.

**Frontière de release — non franchie** : `git diff --name-only main..HEAD` sur la triade rend
**0 fichier** ; `VERSION = v2.47.1` des deux côtés ; `check-release-tag.sh` **rc=0**. Geste humain
gaté, conforme au contrat.

---

## Ce qui reste à faire — 0 bloquant, 14 warnings

Aucun n'empêche la fusion. Par ordre d'utilité :

1. **Faits périmés dans des documents qui font foi** : **W1** (note ROADMAP `threats_open: 1` quand
   la mesure rend 0), **W13** (motif (a) de `24-VALIDATION.md` : « la CI est ROUGE » ne l'est plus),
   **W9(b)** (`ci.yml:527-540` : « ce job n'aura jamais tourné », il a tourné 10 fois), **W18**
   (trois formulations de cadrage au présent dans `REQUIREMENTS.md`). Quatre corrections à la ligne.
2. **W10** — trois modules avec du contenu distribué après leur bump, dont `planning-core` avec une
   correction de **comportement** absente de son CHANGELOG. Le seul warning qui touche ce qu'un lab
   recevra après la fusion.
3. **W15** — donner un successeur à la voie 2 de M2, sans quoi elle s'évapore avec la clôture.
4. **W3, W4, W6, W7, W9(a), W11, W12, W14, W16, W17** — signalés, sans effet sur la fusion.

---

## Note de méthode

`grep` et `find` étant proxifiés et tronquants sur ce poste — et `git log` l'ayant démontré à la
passe 2 en masquant un commit —, tous les comptes sont faits en `awk` lisant les fichiers lui-même,
en `comm` sur listes triées, en `node` pour parser le JSON, ou en `git` invoqué par chemin absolu, et
croisés sur deux formes quand le nombre est porteur. **Quatre chiffres n'ont pas survécu à ce
traitement au fil des trois passes et sont corrigés** : « les 5 littéraux et les **6** champs » de
T76 (c'est **7**), « aucun autre agent ne dépasse 250 » (**W17** — le balayage ne portait que sur 25
des 31), « 308 / 400 » du corpus W3 (**306**), et « 24 occurrences » de `backgroundDispatch`
(**25** — **W14**, le chiffre a changé en s'écrivant). C'est la règle que la phase s'est donnée, et
elle mord d'abord sur ses propres documents de vérification.

**Trois refus de forger ont tenu** au long de cette phase — l'absence de `24-VERIFICATION.md`, un
`threats_open: 0` non calculé, un `nyquist_compliant: true` de confort. Le `passed` posé ici n'a de
valeur que parce que ces trois refus l'ont précédé, et parce que le motif dominant de la passe 2 a
été **falsifié** avant d'être retiré, jamais laissé s'éteindre.

---

_Vérifié : 2026-08-05T01:27:19Z_
_Vérificateur : Claude (gsd-verifier) — analyse goal-backward, 3ᵉ passe. Gates, suites, mutations,
fixtures, les 32 commandes `<automated>` et la commande rejouable d'ADR-069 exécutés de première
main ; logs CI lus au runner via `gh run view --log`, jamais dans un SUMMARY ; arbre restauré et
`git status` propre après chaque mutation._
