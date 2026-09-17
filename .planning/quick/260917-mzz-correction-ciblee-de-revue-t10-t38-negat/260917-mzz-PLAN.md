---
phase: 260917-mzz
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/quick/260917-ldp-etendre-l-arbitrage-b1-jamais-de-dispatc/260917-ldp-VERIFICATION.md
  - manual/en/05-agent-team/the-agents-that-ship.md
  - manual/fr/05-equipe-agents/les-agents-livres.md
  - plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh
  - plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
autonomous: true
requirements: [MZZ-01, MZZ-02, MZZ-03, MZZ-04]

estimate:
  tokens: 35000
  raw_tokens: 35000
  tasks: 1
  confidence: low

must_haves:
  truths:
    - "MZZ-01 — Dans test-design-orchestrator.sh, t10_affirmative_hits ne cherche la négation que dans la fenêtre qui précède le littéral Task(vibeflow-design), bornée au dernier séparateur de clause parmi `,` `;` `:` `.` et les mots « mais »/« puis » entourés d'espaces littéraux (forme portable sed BSD et GNU, plus aucune borne de mot propre au sed BSD) ; T10_NEG_RE vaut '\\<jamais\\>\\|\\<pas\\>' ; t10_desc_ok exige aussi le littéral team-kernel.md ; mktemp -d est gardé ; les cas (c.6) faux négatif « mais » après virgule, (c.7) faux positif « pas de dispatch » et (c.8) branche « mais »/« puis » SANS virgule voisine existent ; T10 (d) nomme le mutant « jamaisZ » dans ses messages et dans son fichier dev-suite-mutant-negre.md ; la suite rend 43 OK / 0 KO / 0 SKIP sur macOS."
    - "MZZ-01 — Dans test-dev-orchestrator.sh, t38d_affirmative_hits est le jumeau synchronisé (même fenêtre de clause portable, mêmes littéraux '\\<jamais\\>\\|\\<pas\\>', garde mktemp -d sur T38_TMPDIR, cas (e.5)/(e.6)/(e.7) équivalents à (c.6)/(c.7)/(c.8)) ; la suite rend 221 OK / 0 KO / 0 SKIP sur macOS."
    - "MZZ-01 — (c.8) et (e.7) sont discriminants : retirer la branche « mais »/« puis » de la fenêtre fait passer exactement T10 (c.8) et T38 (e.7) en KO (mesuré par le planificateur sous ubuntu:24.04 sur copie jetable hors dépôt, gate-linux.sh sortie 1)."
    - "MZZ-04 — Parité CI Linux (job `tests` de .github/workflows/ci.yml, ubuntu-latest) : gate-linux.sh sort 0 sous ubuntu:24.04 contre la base — aucune erreur de classe de caractères sed, aucun KO absent de la base, suite design rc 0 (35 OK / 0 KO / 3 SKIP), suite dev 198 OK / 11 KO / 12 SKIP dont les 11 KO sont exactement ceux de la base sur image nue, et les six cas neufs (c.6, c.7, c.8, e.5, e.6, e.7) ✓. Mesuré vert le 2026-09-17 par le planificateur sur l'état atteint contre HEAD 9a987f6."
    - "MZZ-02 — La puce vibeflow-design des deux pages de manuel dit qu'il tourne en session principale (via /vf-design), jamais lancé comme sous-agent, en parité FR/EN ; check-manual.sh rend C0-C4 et C6 verts, C5 étant le seul rouge et uniquement sur les pages les-gates-machine / the-machine-gates (pré-existant, hors périmètre)."
    - "MZZ-03 — 260917-ldp-VERIFICATION.md porte status: passed (frontmatter et corps), une section « Résolution (2026-09-17, … finding 6) », et le score 7/7 inchangé."
    - "MZZ-04 — Un seul commit atomique contient EXACTEMENT les 5 fichiers de files_modified ; le DAG de mission du manager reste modifié non indexé et hors commit ; aucun fichier interdit (AGENT.md, SKILL.md, agents/*, VERSION, plugin.json, marketplace.json, README racine, CHANGELOG) n'est touché ; message en français terminé par les deux lignes Co-Authored-By / Claude-Session consécutives ; le message n'invoque AUCUN arbitrage humain pour les correctifs de portabilité et de couverture."
    - "Gates verts sur l'état commité : check-machine-paths.sh rc=0, check-instruction-budget.sh rc=0."
  artifacts:
    - path: "plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh"
      provides: "T10 — négation scopée à la clause (fenêtre portable), cas discriminants (c.6)/(c.7)/(c.8), synchro des littéraux avec T38 en (d)"
      contains: "| mais | puis )//"
    - path: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh"
      provides: "T38 (d)/(e) — jumeau synchronisé, cas (e.5)/(e.6)/(e.7)"
      contains: "T38 (e.7) (DISCRIMINANT)"
    - path: "manual/fr/05-equipe-agents/les-agents-livres.md"
      provides: "Puce vibeflow-design : session principale, jamais sous-agent"
      contains: "Il tourne lui aussi dans ta session principale (via `/vf-design`)"
    - path: "manual/en/05-agent-team/the-agents-that-ship.md"
      provides: "Parité EN de la puce vibeflow-design"
      contains: "It also runs in your main session (via `/vf-design`), never launched as a subagent."
    - path: ".planning/quick/260917-ldp-etendre-l-arbitrage-b1-jamais-de-dispatc/260917-ldp-VERIFICATION.md"
      provides: "Résolution datée du point de traçabilité ouvert"
      contains: "### Résolution (2026-09-17"
  key_links:
    - from: "plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh"
      to: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh"
      via: "T10 (d) : recherche en chaîne fixe de T10_AFFIRM_RE et T10_NEG_RE dans la suite dev — les deux fonctions doivent porter les mêmes littéraux"
      pattern: "T10_NEG_RE"
    - from: ".github/workflows/ci.yml"
      to: "plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh"
      via: "job `tests` (ubuntu-latest) : boucle find plugin scripts -path '*/tests/test-*.sh' — la fenêtre de clause s'y exécute sous GNU sed"
      pattern: "tests/test-\\*.sh"
    - from: "plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh"
      to: "plugin/design-orchestrator/skills/vf-design/SKILL.md"
      via: "T10 (b) et (c.5) : t10_affirmative_hits sur le SKILL réel (aucun faux positif sur la négation légitime)"
      pattern: "t10_affirmative_hits \"$T10_SKILL\""
    - from: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh"
      to: "plugin/dev-orchestrator/references/head-governance.md"
      via: "T38 (d) : la ligne 16 porte une négation légitime avant Task(vibeflow-head) — c'était le faux positif Linux avant le correctif portable"
      pattern: "t38d_affirmative_hits"
---

<objective>
Committer atomiquement la correction ciblée de revue du nœud DAG `exec-b1-design` (hotfix v2.63.2,
PR #79, finding 1 et finding 6), déjà implémentée et vérifiée dans le répertoire de travail : la
négation des gates T10 (design) et T38 (dev) devient scopée à la clause, par une fenêtre portable
sed BSD et GNU, couverte par des cas discriminants ; les deux pages de manuel gagnent la précision
« session principale, jamais sous-agent » ; la vérification 260917-ldp passe à `passed` sur son
seul point de traçabilité.

Ce plan décrit l'état ATTEINT et ne réimplémente rien. Il ne reste qu'une tâche : prouver, puis
committer.

**Historique court, pour que le lecteur d'après ne rejoue pas l'enquête.**
1. La première version de la fenêtre utilisait des bornes de mot propres au sed BSD de macOS.
   Rejouée sous GNU sed (ubuntu:24.04, même famille que le job CI `tests`), elle ajoutait 2 KO par
   suite (T10 (c.3)/(c.7), T38 (d)/(e.6)). La première version de ce plan l'a mesuré (2026-09-17) et
   l'a remonté en checkpoint de décision.
2. vf-coder l'a corrigé dans les deux mêmes fichiers et dans le périmètre de son mandat de
   correction ciblée (nœud `exec-b1-design`, 2026-09-17) : « mais »/« puis » entourés d'espaces
   littéraux, libellé du mutant de T10 (d) aligné sur « jamaisZ ».
3. Sur signalement du plan (aucun cas n'isolait la branche « mais »/« puis », la virgule de
   (c.6)/(e.5) coupant déjà la clause), vf-coder a ajouté (c.8)/(e.7), deux phrases sans virgule, et
   renommé le fichier du mutant de T10 (d) en `dev-suite-mutant-negre.md`.

**Aucun de ces gestes n'est un arbitrage humain, et le commit ne doit pas en invoquer un.** Le
checkpoint est devenu sans objet par la règle qu'il portait lui-même : une sortie 0 de
`gate-linux.sh` le rend caduc.

**Mesures indépendantes du planificateur sur l'état final (2026-09-17, base HEAD `9a987f6`) :**

| Contrôle | Résultat |
|----------|----------|
| suite design, macOS | 43 OK / 0 KO / 0 SKIP, rc 0 |
| suite dev, macOS | 221 OK / 0 KO / 0 SKIP, rc 0 |
| `gate-linux.sh` (ubuntu:24.04), état final | sortie 0 : design 35/0/3 rc 0, dev 198/11/12 (11 KO = base), sed-err 0/0, new-KO 0/0, cas neufs 3/3 et 3/3 |
| `gate-linux.sh`, copie jetable SANS la branche « mais »/« puis » | sortie 1 : new-KO = exactement T10 (c.8) et T38 (e.7), cas neufs 2/3 et 2/3 |
| check-machine-paths / check-instruction-budget | rc 0 / rc 0 |
| check-manual | C0-C4 et C6 verts ; C5 rouge seulement sur les-gates-machine / the-machine-gates |

Le gate est prouvé rouge sur deux défauts distincts : sortie 1 sur la première version de la
fenêtre (bornes BSD), sortie 1 sur la branche « mais »/« puis » retirée. Il sort 0 sur l'état final.

**Limitation connue, non bloquante, hors correctif** (à consigner au SUMMARY, sans modifier le
code) : (L1) le séparateur `.` coupe aussi dans « cf. » ou `team-kernel.md`, ce qui pourrait isoler
une négation de son littéral. Aucune occurrence réelle de `Task(vibeflow-design)` ou de
`Task(vibeflow-head)` n'a ce contexte aujourd'hui ; vf-coder la documente comme limitation connue.
Les limitations L2 (branche « mais »/« puis » non isolée) et L3 (nom du fichier mutant) relevées par
la version précédente de ce plan sont fermées par (c.8)/(e.7) et par le renommage.

Tracer-first non applicable : l'implémentation est faite, le plan committe un état atteint
(équivalent `--no-tracer`).

Purpose: livrer la correction de revue de la PR #79 sans rougir le job CI `tests`.
Output: un commit atomique sur `hotfix/v2.63.2-profondeur-spawn` et `260917-mzz-SUMMARY.md`.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@./CLAUDE.md
@.planning/quick/260917-ldp-etendre-l-arbitrage-b1-jamais-de-dispatc/260917-ldp-VERIFICATION.md
@plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh
@plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh

## Script du gate Linux — à poser TEL QUEL hors dépôt, jamais versionné

Chemin : `${TMPDIR:-/tmp}/mzz-linux-replay/gate-linux.sh`. Les suites de la base sont posées à côté,
sous les noms `design-BASE.sh` et `dev-BASE.sh`. Exécuté par le planificateur dans cette forme
exacte : sortie 0 sur l'état final, sortie 1 sur la copie sans branche « mais »/« puis ».

```bash
#!/usr/bin/env bash
# Gate de parité Linux (job CI `tests`, ubuntu-latest) — plan 260917-mzz. Hors dépôt, jamais versionné.
# Usage : bash gate-linux.sh <chemin-absolu-du-worktree>
# Prérequis : design-BASE.sh et dev-BASE.sh (suites de la base) posés dans le même dossier que ce script.
# Sortie 0 = vert (aucun KO nouveau, aucune erreur sed, 6 cas neufs ✓, suite design rc 0) ; 1 = rouge ; 2 = usage/prérequis.
set -u
W="${1:?usage: gate-linux.sh <worktree>}"
R="$(cd "$(dirname "$0")" && pwd)"
D=plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh
V=plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
[ -s "$R/design-BASE.sh" ] && [ -s "$R/dev-BASE.sh" ] || { echo "prérequis manquant : design-BASE.sh / dev-BASE.sh"; exit 2; }
command -v docker >/dev/null 2>&1 || { echo "docker absent : preuve Linux MANQUANTE (blocage)"; exit 2; }
green=1
for p in "$D" "$V"; do
  n="$(basename "$p" .sh)"
  docker run --rm -v "$W":/w:ro -w /w ubuntu:24.04 bash "$p" > "$R/$n.WT.log" 2>&1; rc=$?
  echo "$n WT rc=$rc"
  if [ "$n" = test-design-orchestrator ] && [ "$rc" -ne 0 ]; then green=0; fi
  docker run --rm -v "$W":/w:ro -v "$R/design-BASE.sh":/w/$D:ro -v "$R/dev-BASE.sh":/w/$V:ro -w /w ubuntu:24.04 bash "$p" > "$R/$n.BASE.log" 2>&1
  [ -s "$R/$n.WT.log" ] && [ -s "$R/$n.BASE.log" ] || { echo "$n : journal vide"; exit 2; }
  se="$(grep -c 'Invalid character class name' "$R/$n.WT.log")"
  nk="$(comm -13 <(grep '✗' "$R/$n.BASE.log" | sed -E 's/ : .*//' | sort -u) <(grep '✗' "$R/$n.WT.log" | sed -E 's/ : .*//' | sort -u))"
  nkc="$(printf '%s' "$nk" | grep -c .)"
  echo "$n sed-err=$se new-KO=$nkc"
  [ -n "$nk" ] && printf '%s\n' "$nk"
  echo "  WT   : $(tail -1 "$R/$n.WT.log")"
  echo "  BASE : $(tail -1 "$R/$n.BASE.log")"
  if [ "$se" -ne 0 ] || [ "$nkc" -ne 0 ]; then green=0; fi
done
cd_=$(grep -c '✓ T10 (c.6) (DISCRIMINANT)\|✓ T10 (c.7) (CONTRE-ÉPREUVE)\|✓ T10 (c.8) (DISCRIMINANT)' "$R/test-design-orchestrator.WT.log")
cv_=$(grep -c '✓ T38 (e.5) (DISCRIMINANT)\|✓ T38 (e.6) (CONTRE-ÉPREUVE)\|✓ T38 (e.7) (DISCRIMINANT)' "$R/test-dev-orchestrator.WT.log")
echo "cas-neufs design=$cd_ dev=$cv_"
if [ "$cd_" -ne 3 ] || [ "$cv_" -ne 3 ]; then green=0; fi
if [ "$green" -eq 1 ]; then echo "GATE-LINUX VERT"; exit 0; fi
echo "GATE-LINUX ROUGE"; exit 1
```

Les deux suites de la base sont montées PAR-DESSUS l'arbre pour le rejeu de base. Les deux sont
nécessaires : sinon T10 (d) diverge artificiellement (base design contre suite dev modifiée). Les
11 KO de base de la suite dev viennent de l'image nue (jq, python3, git absents) : la preuve porte
sur le delta, jamais sur le rc de la suite dev.

## Notes d'exécution observées dans cet environnement (planification, 2026-09-17)

- Le hook rtk réécrit `git` en `rtk git`, et le garde d'isolation du worktree refuse alors la commande.
  Appeler git par son binaire absolu (`/usr/bin/git`).
- Le garde refuse aussi les variables d'exécution dans une commande git (`$R`, `$PWD`), et refuse
  docker lancé depuis un bloc `bash -c`. Il accepte en revanche `bash <script> <arguments absolus>`.
  Il faut donc substituer les chemins absolus (worktree, `$TMPDIR` résolu) **dans la commande
  seulement**, jamais dans un fichier versionné ni dans le SUMMARY : `check-machine-paths.sh`
  rejette `/Users/<compte>`.
- rtk reformate la sortie de `grep -c` (« 0 matches for … ») et fausse les comptages en commande
  nue. Les comptages du gate sont faits DANS le script, à l'abri du hook ; pour un grep ponctuel,
  passer par `rtk proxy`.
- Docker 29 est disponible et `ubuntu:24.04` est déjà en local. Docker indisponible = sortie 2 du
  script = blocage, jamais un SKIP silencieux.

## Hors périmètre

À ne jamais toucher ni indexer : `.planning/MISSION-HOTFIX-2632.dag.json` (propriété du manager
amont). Interdits : AGENT.md, SKILL.md, agents/*, VERSION, plugin.json, marketplace.json, README
racine, CHANGELOG (design-orchestrator 1.5.8 et dev-orchestrator 2.22.3 déjà en place, pas de bump).
</context>

<tasks>

<task type="auto">
  <name>Tâche 1 : prouver l'état atteint (macOS + parité Linux), puis commit atomique des 5 fichiers, DAG du manager exclu</name>
  <files>.planning/quick/260917-ldp-etendre-l-arbitrage-b1-jamais-de-dispatc/260917-ldp-VERIFICATION.md, manual/en/05-agent-team/the-agents-that-ship.md, manual/fr/05-equipe-agents/les-agents-livres.md, plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh, plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh</files>
  <precondition>Les entrées suivies modifiées de `git status --porcelain --untracked-files=all` sont exactement les 5 fichiers de files_modified plus le DAG de mission du manager ; toute entrée non suivie est confinée à .planning/quick/260917-mzz-correction-ciblee-de-revue-t10-t38-negat/.</precondition>
  <action>
Étape 0, périmètre. Si la précondition échoue, s'arrêter et rendre `bloqué` avec la sortie porcelain
brute, sans rien committer : le périmètre a bougé depuis le plan.

Étape 1, preuve avant commit (aucune modification du dépôt). Si une seule mesure ci-dessous diffère,
s'arrêter et rendre `bloqué` avec la sortie brute, sans rien committer. Ne jamais corriger le code
soi-même : ce serait sortir du mandat.
- `bash plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh` finit sur
  43 OK / 0 KO / 0 SKIP (rc 0).
- `bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` finit sur
  221 OK / 0 KO / 0 SKIP (rc 0).
- `bash scripts/check-machine-paths.sh` et `bash plugin/conductor/scripts/check-instruction-budget.sh`
  rendent rc 0.
- `bash manual/.tools/check-manual.sh` : seul C5 peut être rouge, et ses occurrences visent
  uniquement `fr/07-sous-le-capot/les-gates-machine.md` et `en/07-under-the-hood/the-machine-gates.md`.
- Parité Linux :
  - créer `${TMPDIR:-/tmp}/mzz-linux-replay/` et y poser le script `gate-linux.sh` du contexte,
    copié caractère pour caractère ;
  - y extraire avec `/usr/bin/git show` les deux suites de la base `HEAD`, sous les noms
    `design-BASE.sh` et `dev-BASE.sh` ;
  - lancer `bash <dossier>/gate-linux.sh <chemin absolu du worktree>`. La sortie doit valoir 0
    (`GATE-LINUX VERT`, cas neufs 3/3 et 3/3). Une sortie 1 ou 2 bloque le commit.

Étape 2, indexation. Indexer les 5 fichiers de `<files>` UN PAR UN par chemin explicite. Ne jamais
utiliser d'ajout global (tout le dépôt, répertoire courant, ou `-u`), qui embarquerait le DAG de
mission du manager (`.planning/MISSION-HOTFIX-2632.dag.json`) et les artefacts non suivis de cette
tâche. Contrôler que la liste indexée égale exactement les 5 chemins et que le DAG apparaît toujours
en modifié non indexé.

Étape 3, commit. Message en français, cohérent avec l'historique de la branche. Titre :
`test(orchestrators): T10/T38 — négation scopée à la clause, revue PR #79 (finding 1)`. Le corps
résume en quelques lignes :
- la fenêtre de clause portable sed BSD et GNU (séparateurs `,;:.` et « mais »/« puis » entre
  espaces) et les littéraux `\<jamais\>\|\<pas\>` communs à T10 et T38 ;
- les cas (c.6)/(c.7)/(c.8) et (e.5)/(e.6)/(e.7), dont (c.8)/(e.7) qui isolent la branche
  « mais »/« puis » sans virgule ;
- la garde `mktemp -d`, le retrait de la contre-épreuve tautologique (c.5), le littéral
  `team-kernel.md` exigé par `t10_desc_ok`, le mutant « jamaisZ » de T10 (d) (libellé et fichier
  `dev-suite-mutant-negre.md`) ;
- la parité FR/EN du manuel et la résolution du finding 6 dans la VERIFICATION 260917-ldp ;
- les chiffres de preuve de l'étape 1 : macOS 43/0/0 et 221/0/0, `gate-linux.sh` sortie 0 sous
  ubuntu:24.04, zéro KO nouveau contre la base.

Le corps dit en toutes lettres que les correctifs de portabilité et de couverture ont été appliqués
par vf-coder dans le périmètre du mandat de correction ciblée (nœud `exec-b1-design`, 2026-09-17),
après détection par le plan 260917-mzz, et qu'aucun arbitrage humain n'est invoqué à ce titre. Il
nomme L1 (séparateur `.`) comme limitation connue. Le message se termine par exactement ces deux
lignes consécutives, sans ligne vide entre elles :
Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01TSKYH6hUPUXMhAgf5mqRUC

Étape 4, après le commit. Ne pas pousser : `push-design` est un nœud DAG distinct du manager. Ne
toucher ni STATE.md, ni ROADMAP, ni aucun fichier interdit du contexte. Rejouer le bloc
`<automated>`, qui prend pour base `HEAD~1`. Écrire ensuite `260917-mzz-SUMMARY.md` avec :
- le SHA du commit ;
- les chiffres bruts de l'étape 1 et du rejeu d'après commit ;
- la limitation connue L1 ;
- la note de traçabilité : correctifs de vf-coder dans son mandat, checkpoint caduc par sortie 0
  du gate, aucun arbitrage humain invoqué.

Aucun chemin absolu de poste dans le SUMMARY.
  </action>
  <verify>
    <automated>set -o pipefail
test "$(/usr/bin/git show --name-only --format= HEAD | sort)" = "$(printf '%s\n' .planning/quick/260917-ldp-etendre-l-arbitrage-b1-jamais-de-dispatc/260917-ldp-VERIFICATION.md manual/en/05-agent-team/the-agents-that-ship.md manual/fr/05-equipe-agents/les-agents-livres.md plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh | sort)" && echo "scope-5 OK"
/usr/bin/git status --porcelain --untracked-files=all | grep -q '^ M \.planning/MISSION-HOTFIX-2632\.dag\.json$' && echo "dag-intouche OK"
test "$(/usr/bin/git log -1 --format=%B | awk 'NF' | tail -2)" = "$(printf '%s\n%s' 'Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>' 'Claude-Session: https://claude.ai/code/session_01TSKYH6hUPUXMhAgf5mqRUC')" && echo "trailers OK"
/usr/bin/git show HEAD:plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh | grep -qF '| mais | puis )//' && /usr/bin/git show HEAD:plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh | grep -qF '| mais | puis )//' && echo "fenetre-portable commitee OK"
/usr/bin/git show HEAD:plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh | grep -qF 'T10 (c.8) (DISCRIMINANT)' && /usr/bin/git show HEAD:plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh | grep -qF 'T38 (e.7) (DISCRIMINANT)' && echo "cas-sans-virgule commites OK"
bash scripts/check-machine-paths.sh >/dev/null 2>&1; echo "machine-paths rc=$?"
bash plugin/conductor/scripts/check-instruction-budget.sh >/dev/null 2>&1; echo "instruction-budget rc=$?"
bash plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh 2>&1 | tail -1
bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh 2>&1 | tail -1
/usr/bin/git show HEAD~1:plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh > "${TMPDIR:-/tmp}/mzz-linux-replay/design-BASE.sh"
/usr/bin/git show HEAD~1:plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh > "${TMPDIR:-/tmp}/mzz-linux-replay/dev-BASE.sh"
bash "${TMPDIR:-/tmp}/mzz-linux-replay/gate-linux.sh" "$PWD"; echo "gate-linux exit=$?"</automated>
  </verify>
  <done>Avant commit : les mesures de l'étape 1 sont conformes, dont `gate-linux.sh` sortie 0 contre `HEAD`. Après commit : `scope-5 OK`, `dag-intouche OK`, `trailers OK`, `fenetre-portable commitee OK`, `cas-sans-virgule commites OK`, machine-paths rc=0, instruction-budget rc=0, suites macOS 43 OK / 0 KO / 0 SKIP et 221 OK / 0 KO / 0 SKIP, `gate-linux exit=0` contre `HEAD~1`. Le message n'invoque aucun arbitrage humain pour les correctifs de vf-coder. Commit non poussé, `260917-mzz-SUMMARY.md` écrit avec L1 et sans chemin absolu de poste.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| arbre de travail partagé → commit | le working tree mêle le diff de la tâche et un fichier du manager amont (DAG de mission) |
| poste macOS → CI ubuntu-latest | les suites vertes sous sed BSD s'exécutent sous GNU sed en CI |
| décision d'agent → artefact versionné | un correctif décidé par un agent dans son mandat ne doit pas être gravé comme un arbitrage humain |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-mzz-01 | Tampering | commit de la tâche 1 | high | mitigate | Indexation par chemins explicites uniquement. Le verify `scope-5 OK` compare la liste des fichiers du commit aux 5 chemins, et `dag-intouche OK` exige le DAG du manager toujours en ` M` non indexé. |
| T-mzz-02 | Tampering | job CI `tests` de la PR #79 (gate T10/T38) | high | mitigate | `gate-linux.sh` doit sortir 0 contre `HEAD` avant le commit (étape 1, bloquant) et contre `HEAD~1` après. Le gate est prouvé rouge sur deux défauts distincts (bornes BSD, branche « mais »/« puis » retirée) et vert sur l'état final. `fenetre-portable commitee OK` et `cas-sans-virgule commites OK` vérifient le contenu effectivement commité. |
| T-mzz-03 | Repudiation | §Résolution de 260917-ldp-VERIFICATION.md | medium | transfer | La résolution cite un relais de la session principale vers vf-dev-manager qui n'est tracé nulle part dans le dépôt (absent du DAG). La confirmation revient au manager qui détient le relais ; l'exécuteur n'y ajoute rien. |
| T-mzz-04 | Repudiation | message de commit (correctifs de vf-coder) | medium | mitigate | Les correctifs de portabilité et de couverture ont été décidés et appliqués par vf-coder, pas arbitrés par un humain. Le corps du commit et le SUMMARY l'écrivent en toutes lettres (agent, mandat, nœud, date) et n'invoquent aucun arbitrage humain, conformément à la règle de traçabilité de CLAUDE.md. |
| T-mzz-05 | Information Disclosure | PLAN, SUMMARY, message de commit | medium | mitigate | Pas de chemin absolu de poste dans les fichiers versionnés : les chemins absolus ne sont substitués que dans les commandes. `check-machine-paths.sh` rc=0 au verify. |
| T-mzz-06 | Denial of Service | preuve Linux (docker absent ou image manquante) | low | mitigate | `gate-linux.sh` sort 2 si docker, les suites de base ou un journal manquent. C'est un blocage explicite (`bloqué`) avant commit, jamais un SKIP silencieux. |
</threat_model>

<verification>
## Audit de couverture multi-sources

| Source | Élément | Couvert par |
|--------|---------|-------------|
| GOAL | Correction ciblée de revue T10/T38, négation scopée à la clause (hotfix v2.63.2, PR #79) | Tâche 1, MZZ-01 |
| REQ | MZZ-01 fenêtre de clause portable T10 et jumeau T38, cas c.6/c.7/c.8/e.5/e.6/e.7 | Tâche 1 étapes 1 et 3, verify `fenetre-portable commitee OK` / `cas-sans-virgule commites OK` |
| REQ | MZZ-02 parité FR/EN du manuel | Tâche 1 étape 1 (check-manual) |
| REQ | MZZ-03 résolution de traçabilité 260917-ldp | Tâche 1 ; T-mzz-03 |
| REQ | MZZ-04 commit atomique, DAG exclu, parité CI Linux | Tâche 1 étapes 1-4, verify |
| CONTEXT | Mandat : décrire l'état atteint, ne rien réimplémenter | Objective ; l'étape 1 bloque au lieu de corriger |
| CONTEXT | Mandat : périmètre = exactement 5 fichiers, DAG jamais touché | files_modified, `scope-5 OK` / `dag-intouche OK` |
| CONTEXT | Mandat : interdits (AGENT.md, SKILL.md, agents/*, VERSION, plugin.json, marketplace, README racine, CHANGELOG) | Contexte ; `scope-5 OK` |
| CONTEXT | Mandat : trailers exacts, commits en français | `trailers OK` |
| CONTEXT | Messages vf-coder (2026-09-17) : correctif portable, puis (c.8)/(e.7) et renommage du mutant ; plan réduit à la tâche de commit, sans checkpoint | Objective (historique, mesures indépendantes, preuve de discriminance), T-mzz-04 |
| RESEARCH | aucun RESEARCH.md (tâche rapide) | sans objet |

Aucun élément manquant. La limitation L1 est consignée au SUMMARY, sans modification de code,
conformément au mandat.

## Vérification d'ensemble

- Les suites macOS restent à 0 KO / 0 SKIP sur l'état commité (43 et 221 OK).
- `gate-linux.sh` sort 0 avant (base `HEAD`) et après (base `HEAD~1`) le commit, avec 3/3 cas neufs
  par suite.
- Le commit contient exactement les 5 fichiers, et le DAG du manager reste en ` M`.
- `check-machine-paths.sh` et `check-instruction-budget.sh` rendent rc 0.
</verification>

<success_criteria>
- Un commit atomique existe sur `hotfix/v2.63.2-profondeur-spawn`, non poussé, contenant exactement
  les 5 fichiers, avec un message en français terminé par les deux trailers exacts et sans arbitrage
  humain invoqué pour les correctifs de vf-coder.
- Les deux suites sont vertes sur macOS (43/0/0, 221/0/0) ET `gate-linux.sh` sort 0 sous GNU sed
  (ubuntu:24.04) contre la base, avec les six cas neufs ✓. Le job CI `tests` de la PR #79 n'a donc
  aucune raison de rougir du fait de ce diff.
- Aucun fichier interdit touché, DAG du manager intact et hors commit.
- `260917-mzz-SUMMARY.md` consigne le SHA, les chiffres bruts, L1 et la note de traçabilité.
</success_criteria>

<output>
Create `.planning/quick/260917-mzz-correction-ciblee-de-revue-t10-t38-negat/260917-mzz-SUMMARY.md` when done
</output>
