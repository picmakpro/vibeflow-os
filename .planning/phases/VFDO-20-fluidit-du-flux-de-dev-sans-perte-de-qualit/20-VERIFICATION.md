---
phase: VFDO-20-fluidit-du-flux-de-dev-sans-perte-de-qualit
verified: 2026-07-31T10:46:28Z
status: gaps_found
score: 5/7 critères de succès vérifiés
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "SC7 — portabilité macOS + Linux prouvée par EXÉCUTION"
    status: partial
    reason: >-
      Le versant macOS est prouvé (44 suites, 0 KO ; 6 suites critiques de la phase relancées
      par le vérificateur, 0 KO). Le versant Linux n'a JAMAIS été exécuté. La branche
      `feat/phase-20-fluidite-flux` n'existe pas sur `origin` (`git ls-remote --heads origin`
      ne la connaît pas) : le job CI `tests` (ubuntu-latest) auquel les 4 plans délèguent
      explicitement la preuve ne s'est jamais déclenché. Docker reste injoignable localement
      (sonde relancée par le vérificateur : `docker info` n'a pas rendu la main en 120 s,
      confirmant le constat des 4 workers du 2026-07-29). Le critère exige « prouvée par
      exécution » — l'audit manuel des bashismes, si soigneux soit-il, est une lecture.
    artifacts:
      - path: ".github/workflows/ci.yml"
        issue: "Jamais déclenché pour cette phase — aucun push de la branche"
    missing:
      - "Pousser la branche et constater le job `tests` vert sur ubuntu-latest, OU produire la preuve Linux par un autre conteneur"
  - truth: "SC7 — release racine + tag annoté, `check-release-tag.sh --remote` ✓"
    status: failed
    reason: >-
      Non satisfait, et l'écart est double. (1) `bash scripts/check-release-tag.sh` sort
      **exit 1** : « VERSION=v2.44.0 mais AUCUN tag local v2.44.0 ». Aucun tag `v2.44.0`
      n'existe (dernier tag : `v2.43.1`), aucune release GitHub. (2) Plus délicat : le bump
      racine est présent dans l'ARBRE DE TRAVAIL mais **non committé** — `VERSION`,
      `plugin/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `README.md`,
      `README.fr.md` sont modifiés en v2.44.0 avec les compteurs de suites passés à 44 et les
      deux lignes d'historique ajoutées. Le plan 20-07 s'était explicitement interdit ces
      cinq fichiers (P-01, P-03) et avait consigné le compteur de README en différé nommé
      (WINDOWS #2). L'état actuel n'est donc ni le « hors périmètre » annoncé, ni la release
      faite : c'est une release à mi-chemin, non traçable.
    artifacts:
      - path: "VERSION"
        issue: "v2.44.0 non committé, sans tag correspondant"
      - path: "README.md / README.fr.md"
        issue: "Compteur passé à 44 et ligne d'historique ajoutée hors commit de release — contredit P-03 et le différé WINDOWS #2"
    missing:
      - "Committer la release racine, créer et pousser le tag annoté `v2.44.0`, créer la release GitHub, puis `bash scripts/check-release-tag.sh --remote` → ✓"
      - "Ou, si la release reste hors périmètre : réverter les 5 fichiers de l'arbre de travail pour que l'état sur disque corresponde au différé déclaré"
  - truth: "SC5 — `check-mission-invariants.sh` gate réellement §1 (mécanisme de mise à jour spécifié ET opérant)"
    status: partial
    reason: >-
      Le gate FONCTIONNE — prouvé par exécution sur 4 chemins discriminants (glob mort → exit 0
      + signal ; globs vivants → exit 3 SAIN, stdout vide ; §1 sans glob → exit 4 INDÉTERMINÉ ;
      fichier désigné illisible → exit 64). Mais **rien ne l'appelle**. Un `grep` exhaustif sur
      `plugin/`, `.github/` et `scripts/` ne trouve aucun appelant hors sa propre suite de test :
      pas de hook (interdit par P-05, à raison), pas de CI, et surtout pas le manager. Le
      mécanisme de mise à jour spécifié par le plan est « l'invocation par le manager au
      démarrage de mission » — or `vf-dev-manager.md:33-35` lui dit de **LIRE** le fichier, et
      ne lui dit nulle part de **LANCER** le gate ; les seuls scripts que son corps lui prescrit
      d'invoquer sont `driver-lock.sh` et `dag.sh`. La phrase de `MISSION-INVARIANTS.md:66`
      « §1 est gatée par `check-mission-invariants.sh` » décrit donc une capacité, pas un
      câblage. Un invariant périmé est *détectable à la demande*, il n'est pas *détecté*.
      C'est le motif exact du défaut de Phase 19 que la phase se donnait pour mission d'éviter
      — la version bénigne (le gate n'est pas inerte, il n'est pas branché).
    artifacts:
      - path: "plugin/dev-orchestrator/agents/vf-dev-manager.md"
        issue: "§Sources de connaissance dit de lire .planning/MISSION-INVARIANTS.md, jamais d'exécuter check-mission-invariants.sh"
      - path: ".planning/MISSION-INVARIANTS.md"
        issue: "Ligne 66 : « §1 est gatée par check-mission-invariants.sh » — aucun appelant n'existe"
    missing:
      - "Une ligne dans le corps du manager (ou dans mission-flow.md §démarrage de mission) qui prescrit l'invocation du gate, avec la lecture de ses 4 codes de sortie"
  - truth: "SC5 — `MISSION-INVARIANTS.md` porte les 3 invariants"
    status: partial
    reason: >-
      2 des 3 invariants nommés par le ROADMAP sont portés : les motifs de risque récurrents
      (§1, globs falsifiables) et la table des fichiers gelés (§2, sous forme de convention de
      dérivation adossée à une commande réelle — `dag.sh status` rend bien un tableau `frozen`,
      vérifié par exécution). Le troisième, **le seuil de tests courant, est délibérément exclu**
      (P-02 du plan 20-05, exclusion écrite en tête du fichier). L'argument est solide et
      s'aligne sur la condition de falsifiabilité que le ROADMAP pose lui-même (« s'il ment, il
      est pire que rien ») — mais c'est une réduction du critère décidée en planification, pas
      un arbitrage humain tracé. À accepter explicitement (override) ou à combler.
    artifacts:
      - path: ".planning/MISSION-INVARIANTS.md"
        issue: "Invariant « seuil de tests courant » absent — exclusion documentée mais non arbitrée par l'humain"
    missing:
      - "Un override daté et signé actant l'exclusion, ou un mécanisme falsifiable pour le seuil de tests"
deferred: []
human_verification:
  - test: "Recette XcodeBuildMCP sur un lab iOS réellement équipé — vérifier que `test_sim`, `build_sim` et `clean` sont bien les noms d'outils exposés par le serveur, et que `vf-reviewer` les reçoit après injection"
    expected: "Les 3 outils répondent ; `inject-mcp-tools.sh --verify` sort 0 sur vf-reviewer"
    why_human: "Ce dépôt n'a pas de `.mcp.json` et le serveur ne se connecte pas dans cet environnement. Déjà consigné en différé nommé (WINDOWS #3) et dit honnêtement dans l'en-tête du script et dans les Conséquences d'ADR-051."
  - test: "Arbitrer l'affirmation « anti-triche vérifié par les suites de test de chaque module » (team-kernel.md:23)"
    expected: "Soit les 4 modules porteurs d'un juge couvrent `disallowedTools` dans leur suite, soit la phrase est corrigée"
    why_human: "Constat indépendamment reproduit par le vérificateur : 0 occurrence de `disallowedTools` dans les suites de design-orchestrator, business-pilot-bundle, content-bundle et growth-bundle (1 seule dans dev-orchestrator). La phase a ÉDITÉ cette ligne même pour y ajouter le mécanisme réel, en laissant la clause fausse en place. Consigné en différé (WINDOWS #1) plutôt que corrigé — c'est un arbitrage, pas un fait."
  - test: "Trancher le sort de la release racine v2.44.0 restée dans l'arbre de travail"
    expected: "Soit release committée + taguée + publiée, soit les 5 fichiers révertés"
    why_human: "ADR-031 : la release racine est réservée à une validation humaine post-fusion. L'état intermédiaire actuel n'est ni l'un ni l'autre."
---

# Phase 20 : Fluidité du flux de dev sans perte de qualité — Rapport de vérification

**But de la phase :** rendre le flux de dev plus rapide et plus fluide **sans perdre en qualité**,
par quatre changements indépendants dont deux touchent la doctrine.
**Vérifié le :** 2026-07-31T10:46:28Z
**Statut :** `gaps_found`
**Re-vérification :** non — vérification initiale.

**Verdict global : PASS partiel — 5/7 critères de succès atteints.**
SC1, SC2, SC3, SC4 et SC6 sont atteints, et l'essentiel l'est **par exécution**, pas par lecture.
SC5 est atteint dans sa substance mais son mécanisme de mise à jour n'est pas câblé. SC7 échoue sur
deux de ses six clauses : la preuve Linux et la release taguée.

---

## Atteinte du but — les 7 critères

| # | Critère (ROADMAP) | Statut | Preuve |
|---|---|---|---|
| SC1 | ADR-051 révisée sur ce seul point + `vf-reviewer` seul obtient l'accès MCP, granularité tranchée par un test réel | ✓ VÉRIFIÉ | `docs/ADR.md` §ADR-051 porte l'argument littéral et le coût chiffré ; `vf-reviewer` est le SEUL fichier de `plugin/*/agents/` à porter `vf-mcp-tools:` ; `vf-auditer` et `vf-dev-manager` : 0 occurrence de `mcp` |
| SC2 | L'écart `tools:` déclaré/runtime est **traité**, pas seulement constaté | ✓ VÉRIFIÉ | Les 4 juges portent `disallowedTools: Write, Edit` ; la description de `vf-design-judge` dit le fait exact ; le dépôt ne se contente pas de le *dire*, il l'**impose** (sonde ci-dessous) |
| SC3 | La revue est un étage de premier rang piloté par le manager ; la règle « pas de double revue » **réécrite**, pas contournée | ✓ VÉRIFIÉ | `vf-dev-manager.md:105-109` pose `revue-N` systématiquement ; la chaîne « Pas de double revue » n'existe plus que dans le `.bak` non suivi ; cycle `vf-coder` à 3 étapes ; ADR-060 posée |
| SC4 | Critères de déclenchement objectifs + revue de jointure en nœud séparé + défaut sûr | ✓ VÉRIFIÉ | `mission-flow.md` §Pattern E porte les 4 déclencheurs (a)-(d) verbatim, la jointure sur topologie et « dans le doute, revue pleine » — et les 3 mécanismes machine sont prouvés par exécution |
| SC5 | `MISSION-INVARIANTS.md` porte les 3 invariants + la contrainte d'outillage, mécanisme de mise à jour **spécifié** | ⚠ PARTIEL | Fichier créé, gate discriminant prouvé sur 4 codes de sortie. **2 réserves** : le seuil de tests est exclu (3ᵉ invariant absent) ; le gate n'a **aucun appelant** |
| SC6 | Scope des 2 hooks corrigé, silencieux en nominal et utile sur les dérives, sans mécanisme d'exclusion redondant | ✓ VÉRIFIÉ | Les 2 commandes `SessionStart` portent les 2 flags ; silence à 0/0 et 1 ligne à ≥1 avertissement, prouvés ; **30 avertissements réels** produits sur le vrai `~/.claude/agents` où l'ancien hook rendait 0 ligne |
| SC7 | Gouvernance tenue (6 clauses) | ⚠ PARTIEL (4/6) | `check-agents.sh` vert, densité ADR-029, modules bumpés : ✓. **Linux non prouvé** et **release non taguée** : ✗ |

**Score : 5/7.**

---

## Ce qui est prouvé par EXÉCUTION (et non par lecture)

C'est la distinction que le mandat demandait. Voici ce que le vérificateur a fait tourner lui-même.

### SC2 — la barrière d'écriture n'est pas déclarative : elle bloque

Le point le plus fort de la phase, et il dépasse la lettre du critère. SC2 demandait que « le repo
dise quelque part que `memory:` rouvre ces outils ». Le dépôt ne le dit pas seulement — il le
**refuse**, à deux étages :

```
# 1) check-agents.sh, mode normal, agent avec memory: + tools: sans Write/Edit, sans barrière
⚠ warnonly.md : memory: + tools: sans Write/Edit exige disallowedTools: Write, Edit
  (memory: reinjecte silencieusement ces outils au runtime — barriere structurelle requise)

# 2) guard-agent-write.sh, PreToolUse(Write) d'un faux juge sans barrière
{"permissionDecision": "deny", "permissionDecisionReason":
 "Agent NON NATIF refuse (ADR-044) — ✗ faux-juge.md : memory: + tools: sans Write/Edit
  exige disallowedTools: Write, Edit …"}

# 3) le MÊME agent, `disallowedTools: Write, Edit` posé → stdout vide, écriture autorisée
```

Ce dernier point mérite d'être souligné : le rapport de mission du 2026-07-29 (§4.2) signalait que
`guard-agent-write.sh` appelait le checker **sans `--strict`**, donc qu'un futur juge sans barrière
« ne serait pas bloqué à l'écriture » — un garde-fou livré inerte, exactement le défaut de Phase 19.
Le commit `447e75a` l'a corrigé, et **la sonde ci-dessus confirme que le correctif mord**. Le
discriminant est propre : le cas conforme passe, le cas non conforme est dénié.

### SC4 — les 3 mécanismes machine du plan de bataille

Sondés sur un DAG jetable, pas lus dans la doctrine :

| Mécanisme | Sonde | Résultat |
|---|---|---|
| `dag.sh add --scope` | 5 nœuds, périmètres variés | `scope[]` écrit ; absent → `[]`, jamais d'erreur |
| `reopen` force `review_regime=full` | `reopen revue-1` | `review_regime_full: ["revue-1"]` ; **`exec-3`, dépendant non-revue, ne reçoit RIEN** (P-04 tenu) |
| …en transitif | `reopen exec-1` sur `exec-1 → revue-1 → join-1` | `review_regime_full: ["join-1","revue-1"]` — les deux descendants de revue/jointure |
| `status` expose les périmètres gelés | `status` | clé `frozen: [{id, status, scope}]` présente |
| Rétro-compatibilité | `status`/`ready`/`tree` sur les 4 DAG suivis `dag-phase13/17/19/20.json` (sans clé `scope`) | 12/12 OK, aucune levée |

C'est la traduction exécutable du garde-fou non négociable « aucun allègement ne s'applique jamais à
un diff de comblement » : un champ écrit par l'outil, pas une consigne de prompt.

### SC5 — le gate d'invariants discrimine bien (mais personne ne l'appelle)

| Situation | Exit | Sortie |
|---|---|---|
| Fichier réel du dépôt | 3 | `SAIN — tous les globs … matchent encore` |
| Fixture à glob mort | 0 | `[mission-invariants] zone morte (glob sans correspondance) : plugin/zzz-nexiste-pas/**` |
| Fixture §1 sans aucun glob | 4 | `INDÉTERMINÉ, rien n'a été vérifié` |
| `--file` désigné illisible | 64 | `fichier introuvable ou illisible` |

Le contrat à quatre codes (0/3/4/64) est bien celui livré — la scission SAIN/INDÉTERMINÉ issue du
correctif de revue est réelle, et le PLAN comme le SUMMARY ont été réalignés dessus (commit
`c9c43b4`). Le fichier `MISSION-INVARIANTS.md` ne ment pas : il exclut explicitement le seuil de
tests et étiquette §3 comme non gatée. **Réserve** : voir les lacunes, rien n'invoque ce gate.

### SC6 — le hook produisait 0 ligne, il en produit une qui compte

| Sonde | Exit | Sortie |
|---|---|---|
| `check-agents.sh --strict`, cwd sans `.claude/agents`, **sans flag** | 3 | `INDETERMINE … aucun verdict rendu` — jamais un vert |
| idem `check-debug-research.sh --strict` | 3 | `INDETERMINE` |
| Brique NON conforme dans `<cwd>/.claude/agents/`, **sans flag** | 1 | 3 non-conformités bloquantes — la sonde du chemin par défaut qui manquait en Phase 16 |
| `--hook`, 0 erreur 0 avertissement | 0 | **stdout strictement vide** (silence nominal conservé) |
| `--hook`, 0 erreur ≥1 avertissement | 0 | `⚠ 2 avertissement(s) — detail : …` (1 ligne) |
| **`--hook` tel que câblé, sur le VRAI `~/.claude/agents` (49 agents)** | 0 | `⚠ 30 avertissement(s)` + `34 agent(s) tiers non lintés (préfixe : gsd-)` |
| **`check-debug-research.sh --hook`, idem** | 0 | 2 briques debug sans recherche documentaire, nommées |
| **Simulation d'AVANT le correctif** : `--hook` sans flag, cwd sans `.claude/agents` | 0 | **0 ligne** |

La dernière ligne est la preuve du diagnostic du ROADMAP, et l'avant-dernière celle du gain. Le
câblage tient parce que `merge-hooks.sh` résout `{{VF_SCRIPTS}}` en
`"$HOME"/.claude/scripts` (scope user) ou `"$CLAUDE_PROJECT_DIR"/.claude/scripts` (scope projet) —
donc `{{VF_SCRIPTS}}/../agents` désigne bien le dossier où les agents sont réellement posés.
Aucune ligne de `merge-hooks.sh` n'a été touchée (P-03 tenu, absent du diff de branche).

### SC7 — les gates de gouvernance qui passent

```
check-agents.sh --strict :  6/6 dossiers → rc=0
  dev-orchestrator (7 warn) · design-orchestrator (5) · business-pilot-bundle (5)
  content-bundle (5) · growth-bundle (5) · mobile-test-team (3)

Densité ADR-029 : 0 agent > 250 lignes (max : vf-dev-manager.md = 207)

Triades des 6 modules bumpés : VERSION ↔ module.json ↔ CHANGELOG, toutes cohérentes
  conductor v1.17.0 · dev-orchestrator v2.8.0 · design-orchestrator v1.3.2
  business-pilot-bundle / content-bundle / growth-bundle v2.0.3

Suites critiques de la phase relancées : 6/6 vertes
  test-check-agents 75 OK/0 KO · test-check-debug-research 23/0 · test-dag OK
  test-check-mission-invariants 16/0 · test-guard-agent-write 14/0 · test-inject-mcp-tools OK

check-version-sync.sh : exit 0, tout vert (y compris « README suites 44 »)
```

---

## Ce qui est seulement PRÉSENT dans un fichier

Aucun critère n'est atteint sur la seule présence. Deux affirmations, en revanche, sont **présentes
sans être portées par une preuve reproductible dans ce dépôt** :

1. **La granularité tranchée « par un test réel » (SC1).** `20-CONTEXT.md` D-03 rapporte une sonde
   A/B/C du 2026-07-28 sur 3 process `claude -p` frais, concluant qu'une allowlist
   `mcp__<serveur>__<outil>` restreint réellement et que `ToolSearch` ne la contourne pas. **Le
   critère est donc satisfait** — la question posée était fine-vs-joker, et elle a bien été tranchée
   par expérience et non par lecture de doc. Mais la preuve vit dans un document de cadrage, pas
   dans un artefact rejouable. Ce qui reste ouvert est une **autre** question, correctement séparée
   et honnêtement dite : que XcodeBuildMCP nomme réellement ses outils `test_sim`/`build_sim`/`clean`
   n'a jamais été confronté à un serveur vivant. C'est écrit dans l'en-tête d'`inject-mcp-tools.sh`,
   dans les Conséquences d'ADR-051, dans le corps de `vf-reviewer` (« l'absence du serveur est
   normale … n'invente jamais un verdict de compilation non constaté ») et consigné en WINDOWS #3.
   Cette honnêteté-là est exemplaire et ne doit pas être confondue avec un manque.

2. **La portabilité Linux (SC7).** Voir les lacunes — c'est le seul endroit où « prouvé par
   exécution » est écrit dans le critère et n'a pas eu lieu.

---

## Les 3 points de vigilance du mandat, instruits

### 1. Le SUMMARY de 20-04, rattrapé après coup — correspond-il au disque ?

**Oui, entièrement.** Il déclare 8 fichiers modifiés (4 juges + 4 managers) alors que le commit
`e270254` « fix(judges) » n'en touche que 4. La tentation est de crier au SUMMARY complaisant :
c'est faux. Les 4 managers ont bien été modifiés, par un **second commit du même jour**, `8ec2f99`
« fix(managers): la justification du dispatch parallèle des juges cite le mécanisme réel » — dont le
diff remplace bien l'adjectif « read-only » par le mécanisme (`disallowedTools: Write, Edit`,
contrainte runtime) dans les 4 fichiers, description comprise. Le SUMMARY décrit donc l'état du
disque, pas une intention. La key-decision « extension hors `files_modified` assumée » est exacte et
justifiée : rendre la barrière réelle sans corriger la justification qu'elle rend enfin vraie aurait
laissé une doc à moitié menteuse.

### 2. Les deux écarts assumés de 20-07 — le report est-il acceptable ?

**Écart A — compteur de suites du module obligatoire : non-sujet, et mieux que prévu.** Le
`must_have` du plan annonçait « quatorze scripts, onze suites ». Le disque porte 14 scripts et
**12** suites, et `conductor/README.md:104,117` affiche bien « 12 suites » et « 14 scripts ». La
valeur livrée est la valeur *juste* : c'est le `must_have` qui était périmé, pas la livraison. Rien
à reprocher.

**Écart B — « anti-triche vérifié par les suites de test de chaque module » : constat confirmé, et
le report est le point faible de la phase.** Vérifié indépendamment :

| Module | Occurrences de `disallowedTools` dans sa suite |
|---|---|
| dev-orchestrator | 1 |
| design-orchestrator | **0** |
| business-pilot-bundle | **0** |
| content-bundle | **0** |
| growth-bundle | **0** |
| mobile-test-team | **0** (aucun `scripts/tests/`) |

La phrase de `team-kernel.md:23` est donc fausse pour 5 modules sur 6. **Ce report vide-t-il un
critère de sa substance ?** Non, et c'est important de le dire nettement : SC2 exige deux choses
précises — que `vf-design-judge` cesse d'affirmer une barrière que le runtime ne pose pas (fait), et
que le dépôt dise que `memory:` rouvre ces outils (fait, et enforced). Les deux sont atteintes. La
clause « vérifié par les suites de chaque module » appartient à une affirmation de doctrine plus
large, antérieure à la phase.

**Mais la circonstance est aggravante** : la phase a **édité cette ligne même** — le commit `2e1e7dd`
y a ajouté « juges via `disallowedTools: Write, Edit` (contrainte runtime, Phase 20) » — en laissant
la clause fausse intacte à quelques mots de là. Une phase dont le fil rouge est « la doc ne doit pas
mentir » a réécrit une ligne menteuse sans la désarmer. Le second demi-membre (« ET par
`check-agents.sh` ») est, lui, rigoureusement vrai et je l'ai prouvé. Recommandation : ne pas laisser
ce différé traîner au-delà de la prochaine phase, et le fermer par la voie la moins chère — corriger
la phrase, pas écrire 5 suites.

### 3. L'arrêt volontaire sur D-11 — la décision prise est-elle celle qui a été implémentée ?

**Oui.** Le rapport de mission `2026-07-29-phase-20-execution-vagues-1-3.md` §4.1 pose D-11 comme
décision one-way : sortir la revue du cycle interne de `vf-coder`. Ce qui est sur disque :

- `vf-coder.md` — cycle à **3** étapes ; l'étape 4 a disparu ; la description dit « Ne dispatche plus
  la revue lui-même » ; le corps renvoie à `mission-flow.md` §Pattern E.
- `vf-coder.md` `tools:` — **`Agent(vf-reviewer, …)` conservé** : le piège nommé par le cadrage
  (retirer l'allowlist en supprimant le texte du cycle) a été évité.
- `vf-dev-manager.md` — la chaîne « Pas de double revue » n'apparaît plus dans le fichier vivant.
  Elle ne subsiste que dans `vf-dev-manager.md.bak`, **non suivi** (`.gitignore:6 *.bak`). Règle
  réécrite en place, pas contournée par exception (P-01 tenu).
- ADR-060 posée, statut Validée, décideur Samuel, et sa section « Rules Associées » dit explicitement
  « Remplace **en place** la règle `vf-dev-manager.md:108` … pas de contournement par exception ».

Les autres points ouverts du même rapport ont également été traités : §4.2 (garde inerte) corrigé et
vérifié ci-dessus ; §4.5 (dérive documentaire du contrat 0/3/64) fermé par `c9c43b4`. Restent §4.3
(Linux) et §4.4 (noms d'outils MCP), tous deux dans les lacunes ou la vérification humaine.

---

## Lacunes bloquantes

### G-1 · SC7 — la preuve Linux n'a jamais eu lieu

Le critère dit « portabilité macOS + Linux **prouvée par exécution** ». Les 4 plans concernés
délèguent tous explicitement cette preuve au job CI `tests` (ubuntu-latest), « déclenché au push ».
Or `git ls-remote --heads origin` ne connaît aucune branche `phase-20` : **la branche n'a jamais été
poussée**, la CI n'a jamais tourné. La sonde `docker info` relancée par le vérificateur n'a pas rendu
la main en 120 s — le démon est bien injoignable, confirmant les 4 constats du 2026-07-29. Il ne
s'agit pas d'un doute sur la qualité du code (l'audit manuel des bashismes a été fait quatre fois) :
il s'agit du fait que le critère exige une exécution et qu'aucune n'a eu lieu.

**Pour combler :** pousser la branche et constater le job `tests` vert.

### G-2 · SC7 — release racine non taguée, et à mi-chemin

`bash scripts/check-release-tag.sh` → **exit 1**, `VERSION=v2.44.0 mais AUCUN tag local v2.44.0`.
Le dernier tag du dépôt est `v2.43.1`. Le critère exige `check-release-tag.sh --remote` ✓.

Le plan 20-07 avait déclaré la release racine hors périmètre (P-01, P-02) et réservé le rattrapage du
compteur de README au commit de release (P-03, différé WINDOWS #2). **Un plan ne peut pas réduire le
périmètre du ROADMAP** — mais surtout, l'état sur disque ne correspond plus à ce différé : les 5
fichiers de release (`VERSION`, `plugin/.claude-plugin/plugin.json`,
`.claude-plugin/marketplace.json`, `README.md`, `README.fr.md`) sont **modifiés et non committés**,
avec la bascule 42→44 suites et les deux lignes d'historique v2.44.0 déjà écrites. C'est un troisième
état, ni « hors périmètre » ni « fait » : un bump non traçable, exactement ce que la règle non
négociable du `CLAUDE.md` du dépôt cherche à empêcher (« une version sans tag n'est ni traçable ni
installable par référence », divergence de juillet 2026).

**Pour combler :** trancher — committer la release + tag annoté `v2.44.0` + release GitHub, puis
`check-release-tag.sh --remote` ✓ ; **ou** réverter les 5 fichiers pour que le disque dise la même
chose que le différé déclaré.

### G-3 · SC5 — le gate d'invariants n'a aucun appelant

Le fichier `MISSION-INVARIANTS.md:66` affirme « §1 est gatée par `check-mission-invariants.sh` ». Le
gate existe, il est correct, il est testé (16 OK / 0 KO) et je l'ai fait tourner sur quatre chemins
distincts. Mais un `grep` sur `plugin/`, `.github/` et `scripts/` ne trouve **aucun appelant** hors
sa propre suite. Le câblage par hook a été écarté à raison (P-05). Le mécanisme retenu par le plan
est « l'invocation par le manager au démarrage de mission » — or le corps de `vf-dev-manager.md` ne
lui prescrit d'invoquer que `driver-lock.sh` et `dag.sh` ; le fichier d'invariants y figure comme
**lecture** (§Sources de connaissance, l.33-35), jamais comme exécution.

Conséquence exacte, à ne pas surestimer : le garde-fou n'est **pas inerte** — il fonctionne dès qu'on
l'appelle. Il n'est **pas branché**. Un invariant périmé est détectable, il n'est pas détecté. C'est
la version bénigne du défaut de Phase 19, et il vaut mieux le fermer maintenant qu'à la neuvième
occurrence.

**Pour combler :** une ligne dans le corps du manager ou dans `mission-flow.md` §démarrage de
mission, prescrivant l'invocation et la lecture des 4 codes de sortie.

### G-4 · SC5 — le 3ᵉ invariant est absent, par décision de planification

Le ROADMAP nomme trois invariants « qui ne vivent nulle part sur disque » : le seuil de tests courant,
la table des fichiers gelés, les motifs de risque récurrents. Le fichier porte les deux derniers (le
second sous forme de convention de dérivation adossée à une commande réelle — meilleur que la copie,
et conforme à la mise en garde du ROADMAP). Le **seuil de tests est délibérément exclu** (P-02),
exclusion argumentée en tête du fichier : invérifiable sans exécution, mouvant à l'échelle de la
journée.

L'argument est bon et s'aligne sur la condition de falsifiabilité que le ROADMAP pose lui-même. Mais
la réduction a été décidée en planification, pas arbitrée par l'humain qui a écrit le critère. Elle
mérite un override daté plutôt qu'un silence.

---

## Artefacts requis

| Artefact | Attendu | Statut | Détails |
|---|---|---|---|
| `docs/ADR.md` §ADR-051 | Révisée sur ce seul point, argument + coût | ✓ VÉRIFIÉ | Argument littéral présent ; « +90 secondes » et « slot de simulateur » écrits ; section Code Impacté enrichie des 2 entrées Phase 20 |
| `docs/ADR.md` §ADR-060 | Numéro libre suivant, revue en étage de premier rang | ✓ VÉRIFIÉ | ADR-060, statut Validée, ne duplique pas le protocole (renvoi à Pattern E) |
| `plugin/dev-orchestrator/agents/vf-reviewer.md` | `vf-mcp-tools` + protocole d'appel | ✓ VÉRIFIÉ | `vf-mcp-tools: XcodeBuildMCP:test_sim,build_sim,clean` ; §Vérification outillée impose `clean` d'abord et les paramètres explicites |
| `plugin/dev-orchestrator/scripts/inject-mcp-tools.sh` | Mode nommé générique, idempotent | ✓ VÉRIFIÉ | `NAMED_FLAG_RE` ; aucun nom d'agent/serveur/outil en dur ; suite verte ; en-tête porte la clause d'honnêteté D-03 |
| Les 4 juges | `disallowedTools: Write, Edit` | ✓ VÉRIFIÉ | 4/4 ; `tools:` inchangés ; `Bash` conservé sur `vf-design-judge` (P-01 tenu) |
| `plugin/design-orchestrator/agents/vf-design-judge.md` | Description + corps disent le fait exact | ✓ VÉRIFIÉ | §Domaine d'action nomme le canal `Bash` ouvert et l'effet de bord mémoire |
| `plugin/conductor/scripts/dag.sh` | `--scope`, `review_regime`, `frozen` | ✓ VÉRIFIÉ | Les 3 prouvés par sonde ; rétro-compatibilité sur 4 DAG suivis |
| `plugin/conductor/scripts/check-mission-invariants.sh` | Gate lecture seule, contrat de sortie | ✓ VÉRIFIÉ | 4 codes discriminants prouvés ; distinction FAIT/JUGEMENT tenue dans la sortie |
| `.planning/MISSION-INVARIANTS.md` | 3 invariants + contrainte d'outillage | ⚠ PARTIEL | 2/3 invariants + §3 étiquetée ; seuil de tests exclu (G-4) ; §1 non branchée (G-3) |
| `plugin/conductor/hooks/hooks.json` | Les 2 commandes portent les 2 flags | ✓ VÉRIFIÉ | Geste additif, JSON non restructuré, `\|\| true` conservés (P-05, P-07 tenus) |
| `plugin/conductor/scripts/check-debug-research.sh` | `--third-party-prefix` même sémantique | ✓ VÉRIFIÉ | Défaut `gsd-`, `--no-third-party-prefix`, aucun second mécanisme d'exclusion |
| `plugin/conductor/references/team-kernel.md` | Cite le mécanisme réel | ⚠ PARTIEL | Mécanisme cité (l.23) et sens fermeture documenté (l.24) ; clause « suites de chaque module » fausse et laissée (vérif. humaine) |
| `plugin/dev-orchestrator/references/mission-flow.md` §Pattern E | Protocole complet | ✓ VÉRIFIÉ | Pose, dispatch, boucle à budget 3, 4 déclencheurs, jointure topologique, garde-fou machine |
| Les 6 `CHANGELOG.md` + triades | Bumps cohérents | ✓ VÉRIFIÉ | 6/6 ; `check-version-sync.sh` exit 0 |
| Release racine + tag | `check-release-tag.sh --remote` ✓ | ✗ ÉCHEC | exit 1, aucun tag v2.44.0 (G-2) |

## Liens critiques

| De | Vers | Via | Statut |
|---|---|---|---|
| `hooks.json` | `merge-hooks.sh` | Remplacement global `{{VF_SCRIPTS}}` | ✓ CÂBLÉ — résolu en `$HOME/.claude/scripts` ou `$CLAUDE_PROJECT_DIR/.claude/scripts`, `merge-hooks.sh` non modifié |
| `check-agents.sh` set `KNOWN` | `vf-reviewer.md` clé `vf-mcp-tools` | Dépendance de mesure 20-01 → 20-03 | ✓ CÂBLÉ — `--strict` sur dev-orchestrator : rc=0, aucun avertissement de champ inconnu |
| `dag.sh --scope` | `mission-flow.md` §Pattern E | Le manager déclare le périmètre à la pose | ✓ CÂBLÉ — la doctrine cite la commande réelle, testée |
| `dag.sh reopen` | Garde-fou de comblement | `review_regime=full` écrit par l'outil | ✓ CÂBLÉ — prouvé, y compris en transitif |
| `dag.sh status` | `MISSION-INVARIANTS.md` §2 | Table des fichiers gelés dérivée | ✓ CÂBLÉ — clé `frozen` présente, la §2 ne renvoie pas à un geste inexistant |
| `check-mission-invariants.sh` | Un appelant quelconque | Invocation par le manager au démarrage | **✗ NON CÂBLÉ** (G-3) |
| `MISSION-INVARIANTS.md` | `vf-dev-manager.md` §Sources | Lecture au démarrage | ✓ CÂBLÉ (lecture seulement) |
| Les 4 juges | Les 4 managers | Justification du dispatch parallèle | ✓ CÂBLÉ — commit `8ec2f99`, les 4 citent le mécanisme |
| ADR-060 | `mission-flow.md` §Pattern E | L'ADR acte, la référence détaille | ✓ CÂBLÉ — pas de duplication du protocole |

## Anti-patterns

| Fichier | Motif | Sévérité | Impact |
|---|---|---|---|
| `quality-gate-client.md:36,82` · `vf-business-manager.md:104` | `CLI-XXX` | ℹ Info | Gabarit d'identifiant client, pas un marqueur de dette — antérieur à la phase |
| `conductor/CHANGELOG.md:378` | `DEC-XXX` | ℹ Info | Motif d'identifiant de décision — idem |
| `plugin/*/agents/*.md.bak` (2) | Fichiers de sauvegarde résiduels | ℹ Info | **Non suivis** (`.gitignore:6`) — n'entrent ni dans le paquet ni dans les gates. Encombrement local seulement |

Aucun `TODO`/`FIXME`/`TBD` non référencé sur les 52 fichiers source du diff de branche. Aucun stub,
aucune implémentation vide, aucun retour statique.

---

## Synthèse

La phase livre ce qu'elle promettait sur ses quatre changements de fond, et elle le livre **avec des
preuves d'exécution là où ça compte** : la barrière d'écriture des juges bloque réellement à
l'écriture, le régime de revue est écrit par l'outil et non par un prompt, le hook de conformité qui
regardait le vide produit maintenant 30 avertissements réels sur le vrai dossier d'agents. Le point
le plus remarquable est que le défaut de Phase 19 — un garde-fou livré inerte — a été **débusqué en
cours de phase** (rapport de mission §4.2), corrigé, et que le correctif tient à la sonde.

Deux réserves de nature différente restent.

La première est **contenue et fermable en une ligne** : le gate d'invariants n'a aucun appelant. Le
fichier affirme être gaté ; il est gatable. C'est la version douce du même piège, et il vaut mieux la
fermer tout de suite.

La seconde est **la sortie de phase elle-même** : SC7 exige une preuve Linux par exécution et un tag
annoté, et ni l'une ni l'autre n'existe. La branche n'a jamais été poussée — ce qui explique
mécaniquement l'absence de preuve CI. Et l'arbre de travail porte un bump v2.44.0 non committé qui
place le dépôt dans un état intermédiaire que sa propre règle non négociable proscrit. Ces deux
points sont hors du travail d'ingénierie de la phase et appartiennent à la validation humaine
post-fusion — mais ils sont écrits dans le critère, et un plan ne peut pas rétrécir le ROADMAP.

**Verdict : PASS partiel, 5/7.** Aucune régression, aucune fiction dans le code livré. Ce qui manque
est un geste de clôture (pousser, taguer) et un fil resté pendant (brancher le gate d'invariants) —
pas une reprise de conception.

---

_Vérifié le 2026-07-31T10:46:28Z_
_Vérificateur : Claude (gsd-verifier) — vérification goal-backward, aucun correctif appliqué (ADR-031)_
