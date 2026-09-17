---
phase: 260917-ogv
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh
  - plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh
  - plugin/design-orchestrator/CHANGELOG.md
autonomous: true
requirements: [OGV-01, OGV-02, OGV-03, OGV-04]

estimate:
  tokens: 110000
  raw_tokens: 110000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "OGV-01 — Dans test-dev-orchestrator.sh, t38d_affirmative_hits (nom inchangé) détecte en monde fermé : le grep des deux littéraux interdits partout est inchangé ; ensuite, par fichier, nombre d'occurrences non chevauchantes de Task(vibeflow-head) (t38_count_literal, awk + index() en boucle) moins la somme des occurrences de chaque forme de T38_CANON_FORMS ; une différence > 0 ajoute les lignes grep -n -F du littéral à la trace. Plus aucune fenêtre de clause, plus aucun heredoc de lignes, plus aucune regex de négation dans les lignes exécutables."
    - "OGV-01 — T38_CANON_FORMS contient exactement une forme, identique au texte de head-governance.md:16 sans le gras : jamais dispatché lui-même comme sous-agent (`Task(vibeflow-head)`). Les 4 fichiers de doctrine réels (AGENT.md, head-governance.md, vf-dev/SKILL.md, vf-auto/SKILL.md) restent NON détectés ; les 6 phrases de repro sont TOUTES détectées (e.5.1 à e.5.6) ; forme canonique seule NON détectée (e.6) ; forme + occurrence affirmative sur la même ligne détectée (e.7, 2 − 1 = 1) ; deux formes sur la même ligne NON détectées (e.8, 2 − 2 = 0) ; (e.1) à (e.4c) inchangés et verts. Suite dev macOS : 0 KO / 0 SKIP (total attendu 227 OK)."
    - "OGV-02 — Dans test-design-orchestrator.sh, t10_affirmative_hits suit la même propriété avec T10_TASK_LIT = Task(vibeflow-design) et T10_CANON_FORMS (forme posée par anticipation) ; t10_count_literal a un corps STRICTEMENT identique à t38_count_literal ; la constante de négation, la fenêtre de clause et le heredoc de lignes ont disparu des lignes exécutables ; (c.3.1) à (c.3.6) détectent les 6 phrases, (c.6)/(c.8) contre-épreuves non détectées, (c.7) détecté ; (c.1)/(c.2)/(c.4) inchangés ; (c.5) garde la contre-épreuve sur le SKILL réel. Suite design macOS : 0 KO / 0 SKIP (total attendu 49 OK)."
    - "OGV-02 — T10 (d) vérifie la synchro en 4 lignes ✓ : littéral T10_AFFIRM_RE en chaîne fixe dans la suite dev, témoin « Invocable via Tache », corps de t38_count_literal (extrait de la suite dev) et de t10_count_literal (extrait de $0) non vides et identiques, témoin sur COPIE où « count + 0 » devient « count + 1 » et n'est plus jugé identique. Le mutant « jamaisZ » n'existe plus."
    - "OGV-03 — Preuve de rouge sur les vrais fichiers : une ligne affirmative ajoutée en fin de vf-design/SKILL.md rend la suite design rc 1 avec un ✗ T10 (b) citant la ligne ajoutée ; idem vf-dev/SKILL.md → suite dev rc 1 avec un ✗ T38 (d) citant la ligne ajoutée ; chaque SKILL est ensuite restauré et cmp-identique à HEAD. check-machine-paths rc 0, check-instruction-budget rc 0, gate-linux.sh (ubuntu:24.04) sortie 0 contre la base."
    - "OGV-04 — Un seul commit contient EXACTEMENT les 3 fichiers de files_modified ; plugin/dev-orchestrator/CHANGELOG.md est intact (aucune ligne de v2.22.3 ne décrit la négation) ; la puce v1.5.8 du CHANGELOG design dit « monde fermé » en une phrase, sans bump ; le DAG du manager n'est ni indexé ni committé ; message en français terminé par les deux lignes Co-Authored-By / Claude-Session ; aucun arbitrage humain n'y est invoqué."
  artifacts:
    - path: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh"
      provides: "T38 (d)/(e) en monde fermé : T38_CANON_FORMS, t38_count_literal, t38d_affirmative_hits réécrite, cas (e.5.1-6)/(e.6)/(e.7)/(e.8)"
      contains: "t38_count_literal() {"
    - path: "plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh"
      provides: "T10 en monde fermé : T10_CANON_FORMS, t10_count_literal, t10_affirmative_hits réécrite, cas (c.3.1-6)/(c.6)/(c.7)/(c.8), synchro T10 (d) par corps de fonction"
      contains: "t10_count_literal() {"
    - path: "plugin/design-orchestrator/CHANGELOG.md"
      provides: "puce v1.5.8 de test-design-orchestrator.sh alignée sur le monde fermé"
      contains: "monde fermé"
  key_links:
    - from: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh"
      to: "plugin/dev-orchestrator/references/head-governance.md"
      via: "T38 (d) : l'unique occurrence réelle de Task(vibeflow-head) (ligne 16) est exemptée parce qu'elle contient la forme de T38_CANON_FORMS"
      pattern: "T38_CANON_FORMS"
    - from: "plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh"
      to: "plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh"
      via: "T10 (d) : extraction sed du corps de t38_count_literal comparée au corps de t10_count_literal"
      pattern: "t38_count_literal() {"
    - from: "plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh"
      to: "plugin/design-orchestrator/skills/vf-design/SKILL.md"
      via: "T10 (b) : t10_affirmative_hits sur le SKILL réel (vert), rougi par la preuve de la tâche 3"
      pattern: "t10_affirmative_hits \"$T10_SKILL\""
---

<objective>
Hotfix v2.63.2, correction ciblée, tour 3. Remplacer la détection affirmatif/négatif en langue
naturelle de T38 (d) (suite dev, head `vibeflow-head`) et de T10 (a)/(b)/(c) (suite design, head
`vibeflow-design`) par un comptage en monde fermé, déterministe, par fichier. Seules des chaînes
négatives CANONIQUES exactes, énumérées dans une liste courte, échappent à la détection.

**Pourquoi un 3e tour change de modèle au lieu d'ajouter un patch.**
1. Tour 1 : négation cherchée sur la ligne entière. Une négation dans une autre clause masquait
   une occurrence affirmative.
2. Tour 2 (commit `7bbaeea`) : négation bornée à une fenêtre de clause (séparateurs de ponctuation
   et « mais »/« puis » entre espaces, portable sed BSD/GNU).
3. Tour 3 (revue) : nouvelles repros. L'expansion `%%` coupe à la 1re occurrence du littéral ;
   « Mais » et « JAMAIS » en capitales passent ; une négation d'une autre clause sans séparateur
   passe ; « n'est pas de dispatch » neutralise une vraie prescription.

Chaque patch a fermé des cas et en a rouvert d'autres. On abandonne donc l'analyse de négation.
Conséquence assumée : toute nouvelle tournure négative qui cite le littéral est détectée tant que sa
forme exacte n'est pas ajoutée à la liste. Ajouter une forme devient un diff relu, pas une
heuristique.

**Couverture du mandat :**

| Point du mandat | Tâche |
|---|---|
| 1-6 dev (littéraux interdits inchangés, T38_CANON_FORMS, t38_count_literal, réécriture, suppressions, commentaires) + cas (i)-(iv) dev + contre-épreuve (e.4c) | 1 (OGV-01) |
| 1-6 design + cas (i)-(iv) design + contre-épreuve (c.5) + synchro T10 (d) par corps de fonction + CHANGELOG design | 2 (OGV-02) |
| Exécutions et preuves à rapporter mot pour mot (suites, rouge sur vrais SKILL, deux gates) + parité Linux du job CI `tests` | 3 (OGV-03) |
| Commit atomique, périmètre strict, CHANGELOG dev laissé intact après relecture | 3 (OGV-04) |

Purpose : fermer la classe de faux négatifs et de faux positifs de T38/T10 au lieu de patcher un cas
de plus, sans rougir le job CI `tests` (ubuntu-latest).
Output : un commit atomique de 3 fichiers sur `hotfix/v2.63.2-profondeur-spawn`, plus
`260917-ogv-SUMMARY.md` qui recopie les preuves mot pour mot.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@./CLAUDE.md
@.planning/STATE.md
@plugin/dev-orchestrator/references/head-governance.md

## Zones à lire (lecture ciblée, ne pas relire le reste des 6950 lignes)

- `plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh` : lignes 6686-6946 (bloc T38).
  `$GREP`, `ok`/`ko`/`skip` et `vf_tmp_track` (l. 296) sont déjà définis plus haut.
- `plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh` : lignes 40-75 (en-tête
  T10, `set -uo pipefail`, `MOD` résolu depuis `$0`, `REPO`, `AGENT_FILE`, `GREP`) et 814-1060
  (bloc T10).
- `plugin/design-orchestrator/CHANGELOG.md` : lignes 3-18 (entrée [v1.5.8]).
- `plugin/dev-orchestrator/CHANGELOG.md` : lignes 3-19 (entrée [v2.22.3]), relecture seulement.

## Corps imposé de la fonction de comptage (dev ; côté design, seul le nom change en t10_count_literal)

Colonne 0 pour la ligne de signature et pour l'accolade fermante : T10 (d) les extrait par
`sed -n '/^<nom>() {/,/^}/p' | tail -n +2`. Le corps doit être identique caractère pour caractère
dans les deux suites, indentation comprise. Pas de `grep -o`, pas de rtk.

```bash
t38_count_literal() { # <file> <literal> -> imprime le nombre d'occurrences non chevauchantes
  local f="$1" lit="$2"
  [ -f "$f" ] || { printf '0'; return; }
  awk -v lit="$lit" '
    { line = $0; start = 1; n = length(lit)
      while (1) {
        idx = index(substr(line, start), lit)
        if (idx == 0) break
        count++
        start = start + idx + n - 1
      }
    }
    END { print count + 0 }
  ' "$f"
}
```

## Mesures du planificateur (2026-09-17, HEAD `df28b9b`, arbre non modifié)

| Contrôle | Résultat |
|----------|----------|
| suite design, macOS | 43 OK / 0 KO / 0 SKIP, rc 0 |
| suite dev, macOS | 221 OK / 0 KO / 0 SKIP, rc 0, environ 35 s |
| prototype du corps imposé, awk BSD macOS + mawk et gawk (C.UTF-8) sous ubuntu:24.04 | mêmes chiffres sur les trois : forme seule 1 − 1, forme + affirmatif 2 − 1, deux formes 2 − 2, phrase 1 : 2 − 0, head-governance.md 1 − 1, fichier absent 0 |
| occurrences réelles de `Task(vibeflow-head)` / `Task(vibeflow-design)` hors suites de test | une seule : `head-governance.md:16`. La forme canonique y est une sous-chaîne du gras `**…**` : couverte. Aucune occurrence dans les AGENT.md et SKILL.md des deux modules. |
| octets de head-governance.md:16 | « é », « ê » et « — » en UTF-8 précomposé ; tiret de « lui-même » et espaces en ASCII |
| gates négatifs des `<automated>` des tâches 1 et 2, sur l'arbre NON modifié | tous rouges : lignes non commentées de la suite dev (heredoc 2, fenêtre 1, regex de négation 1) et de la suite design (constante de négation 7, heredoc 2, mutant 3, fenêtre 1, regex 1) ; corps de `t38_count_literal` vide ; CHANGELOG design sans « monde fermé » |
| `gate-linux.sh` ci-dessous sur l'arbre NON modifié | sortie 1 (`cas-neufs design=3 dev=2 synchro-T10d=3`), design 35/0/3, dev 198/11/12 : preuve que le gate peut rougir. Les 11 KO dev (dont T38 (b)) viennent de l'image nue, présents à l'identique dans la base, hors périmètre. |

Totaux attendus après édition, macOS. Dev : 221 − 3 (anciens e.5/e.6/e.7) + 9 = **227 OK**.
Design : 43 − 4 (anciens c.3/c.6/c.7/c.8) + 9 − 3 (ancien d) + 4 (nouveau d) = **49 OK**.
Les verrous durs sont 0 KO / 0 SKIP et les comptes de cas neufs. Un total d'OK différent doit être
expliqué ligne à ligne dans le SUMMARY par un diff des libellés ✓ contre le journal de base.

## Notes d'exécution observées sur ce poste

- Le hook rtk réécrit `git` et `grep` dans une commande Bash directe. Pour git, le garde d'isolation
  du worktree refuse alors la commande : appeler `/usr/bin/git`. Pour un grep de comptage ponctuel,
  passer par `rtk proxy grep`.
- Le garde refuse `cd … &&`, les variables en position d'option et `bash -c '<texte>'`. Il accepte
  `bash <script> <arguments>`. Pour rejouer un bloc `<automated>`, le poser tel quel dans un fichier
  sous `${TMPDIR:-/tmp}/ogv-verify/` puis lancer `bash <fichier>` depuis la racine du worktree.
  L'intérieur d'un script échappe au hook.
- Substituer les chemins absolus (worktree, TMPDIR résolu) **dans la commande seulement**, jamais dans
  un fichier versionné ni dans le SUMMARY. `scripts/check-machine-paths.sh` rejette les chemins de
  compte utilisateur.
- `check-machine-paths.sh` est à la racine (`scripts/`), pas sous `plugin/conductor/scripts/`.
  `check-instruction-budget.sh` est sous `plugin/conductor/scripts/`, et la sentinelle
  `.planning/.instruction-budget-armed` est présente (rc 0 attendu).
- `.planning/MISSION-HOTFIX-2632.dag.json` est modifié non indexé : c'est le fichier du manager
  amont. Ne jamais l'indexer ni le restaurer.
- Tant que la tâche 2 n'est pas faite, T10 (d) de la suite design est ROUGE : la suite dev ne porte
  plus la regex de négation et la synchro n'est pas encore réécrite. C'est attendu. Ne pas lancer la
  suite design comme gate de la tâche 1.

## Script du gate Linux (job CI `tests`, ubuntu-latest) — à poser TEL QUEL hors dépôt, jamais versionné

Chemin : `${TMPDIR:-/tmp}/ogv-linux-replay/gate-linux.sh`. Poser à côté `design-BASE.sh` et
`dev-BASE.sh`, extraits par `/usr/bin/git show HEAD:<chemin>` AVANT toute édition. Exécuté par le
planificateur dans cette forme exacte sur l'arbre non modifié : sortie 1 (voir mesures).

```bash
#!/usr/bin/env bash
# Gate de parité Linux (job CI `tests`, ubuntu-latest) — plan 260917-ogv. Hors dépôt, jamais versionné.
# Usage : bash gate-linux.sh <chemin-absolu-du-worktree>
# Prérequis : design-BASE.sh et dev-BASE.sh (suites de la base, AVANT édition) posés à côté de ce script.
# Sortie 0 = vert (aucun KO nouveau contre la base, suite design rc 0, 9+9 cas neufs ✓, 4 ✓ T10 (d)) ;
# 1 = rouge ; 2 = prérequis manquant (jamais un SKIP).
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
  nk="$(comm -13 <(grep '✗' "$R/$n.BASE.log" | sed -E 's/ : .*//' | sort -u) <(grep '✗' "$R/$n.WT.log" | sed -E 's/ : .*//' | sort -u))"
  nkc="$(printf '%s' "$nk" | grep -c .)"
  echo "$n new-KO=$nkc"
  [ -n "$nk" ] && printf '%s\n' "$nk"
  echo "  WT   : $(tail -1 "$R/$n.WT.log")"
  echo "  BASE : $(tail -1 "$R/$n.BASE.log")"
  if [ "$nkc" -ne 0 ]; then green=0; fi
done
cd_=$(grep -c '✓ T10 (c\.3\.[1-6])\|✓ T10 (c\.6)\|✓ T10 (c\.7)\|✓ T10 (c\.8)' "$R/test-design-orchestrator.WT.log")
cv_=$(grep -c '✓ T38 (e\.5\.[1-6])\|✓ T38 (e\.6)\|✓ T38 (e\.7)\|✓ T38 (e\.8)' "$R/test-dev-orchestrator.WT.log")
sy_=$(grep -c '✓ T10 (d)' "$R/test-design-orchestrator.WT.log")
echo "cas-neufs design=$cd_ dev=$cv_ synchro-T10d=$sy_"
if [ "$cd_" -ne 9 ] || [ "$cv_" -ne 9 ] || [ "$sy_" -ne 4 ]; then green=0; fi
if [ "$green" -eq 1 ]; then echo "GATE-LINUX VERT"; exit 0; fi
echo "GATE-LINUX ROUGE"; exit 1
```

## Hors périmètre (interdit de toucher)

AGENT.md, SKILL.md (hors preuve de rouge temporaire restaurée), `agents/*`, `head-governance.md`,
README, VERSION, `plugin.json`, `marketplace.json`, `.planning/STATE.md`, ROADMAP, le DAG du manager.
Aucun bump de version. Si une occurrence réelle non couverte par la forme canonique apparaît, ne pas
modifier le texte : la laisser détectée et la signaler dans le SUMMARY.

<!-- planner-discipline-allow: T38D_HEADLINES -->
<!-- planner-discipline-allow: T10_TASKLINES -->
<!-- planner-discipline-allow: T10_NEG_RE -->
<!-- planner-discipline-allow: jamaisZ -->
<!-- planner-discipline-allow: ✗ -->
</context>

<tasks>

<task type="tracer">
  <name>Tâche 1 (tracer) : T38 en monde fermé de bout en bout dans la suite dev (constante, comptage, détection, cas, suite verte)</name>
  <files>plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh</files>
  <precondition>`/usr/bin/git diff --quiet HEAD -- plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh plugin/design-orchestrator/CHANGELOG.md plugin/dev-orchestrator/CHANGELOG.md` rend 0, et docker répond (`docker info`).</precondition>
  <read_first>plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh (lignes 6686-6946 seulement), plugin/dev-orchestrator/references/head-governance.md (ligne 16)</read_first>
  <action>
Étape 0, base (avant toute édition).
- Lancer les deux suites et garder leurs journaux complets hors dépôt, sous
  `${TMPDIR:-/tmp}/ogv-base/`. Attendu : 43/0/0 et 221/0/0 (mesures du planificateur).
- Créer `${TMPDIR:-/tmp}/ogv-linux-replay/`. Y poser `gate-linux.sh`, copié caractère pour caractère
  depuis le contexte.
- Y écrire `design-BASE.sh` et `dev-BASE.sh` avec `/usr/bin/git show HEAD:<chemin>`.
- Si la base n'est pas verte sur macOS, s'arrêter et rendre `bloqué` avec les journaux.

Étape 1, constante. Juste avant la fonction `t38d_affirmative_hits`, en colonne 0, poser un tableau
bash à un élément nommé `T38_CANON_FORMS`. L'élément est entre apostrophes simples, pour que les
backticks restent littéraux sans échappement. Sa valeur est exactement :
jamais dispatché lui-même comme sous-agent (`Task(vibeflow-head)`)
Cette valeur est le texte de head-governance.md:16 sans les `**`. Avant d'écrire, relire la ligne 16
pour confirmer qu'elle contient cette sous-chaîne à l'octet près.

Étape 2, fonction de comptage. Juste après la constante, poser `t38_count_literal` avec le corps
imposé du contexte, copié caractère pour caractère : signature et accolade fermante en colonne 0,
awk + `index()` en boucle, pas de `grep -o`, pas de rtk.

Étape 3, réécrire le CORPS de `t38d_affirmative_hits`. Le nom ne change pas : la boucle (d) sur les
4 fichiers de doctrine et les mutants (e.4a)/(e.4b)/(e.4c) l'appellent.
- Garder tel quel le premier grep des deux littéraux interdits partout, affecté à `hits`.
- Déclarer en local `task_count`, `canon_total=0` et la variable de boucle.
- `task_count` reçoit `t38_count_literal "$f" 'Task(vibeflow-head)'`.
- Pour chaque forme de `"${T38_CANON_FORMS[@]}"`, ajouter `t38_count_literal "$f" "$forme"` à
  `canon_total` par arithmétique shell.
- Si `task_count − canon_total` est strictement positif, ajouter à `hits` la sortie de
  `"$GREP" -n -F -- 'Task(vibeflow-head)' "$f"` (trace fichier:ligne), avec le même assemblage
  `printf '%s\n%s'` qu'aujourd'hui.
- Terminer comme aujourd'hui par l'impression de `hits` sans lignes vides.
- Supprimer entièrement l'ancien mécanisme : la variable locale des lignes, la boucle `while IFS= read`,
  l'expansion `%%`, la fenêtre `sed -E` qui coupait au dernier séparateur de clause, le grep de
  négation et le heredoc nommé T38D_HEADLINES.

Étape 4, commentaire de la section (d) (lignes 6764-6785). Le réécrire pour décrire le monde fermé
et garder l'historique :
- niveau 1 inchangé ;
- niveau 2 = comptage `Task(vibeflow-head)` moins les formes canoniques, par fichier ;
- tours 1 et 2 résumés, puis motif du tour 3 : repros `%%`, « Mais »/« JAMAIS » en capitales, clause
  voisine sans séparateur, « pas de dispatch » neutralisant ; abandon de l'analyse de négation en
  langue naturelle ;
- conséquence assumée : une nouvelle tournure négative citant le littéral reste détectée jusqu'à
  l'ajout de sa forme exacte ;
- jumeau `t10_affirmative_hits`/`t10_count_literal` dans la suite design, corps de comptage vérifié
  identique par T10 (d).
Ne plus y citer les littéraux de l'ancienne regex de négation.

Étape 5, cas. Garder (e.1), (e.2), (e.3), (e.4a), (e.4b) et (e.4c) sans changement. (e.4c) est la
contre-épreuve « SKILL réel non détecté ». Supprimer les anciens (e.5), (e.6) et (e.7) et leurs
commentaires. Les remplacer par les cas ci-dessous, tous écrits sous `$T38_TMPDIR`, un fichier
distinct par entrée, par `printf '%s\n'`, sans heredoc nommé. Chaque ✓ et chaque ✗ imprime le motif
(la phrase, ou la 1re ligne de trace `numéro:texte`), jamais un simple « non vide ». Chaque ✗ remet
`t38_ok=0`.
- (e.5.1) à (e.5.6), DISCRIMINANT, en boucle sur un tableau bash de 6 phrases (index 1 à 6), fichiers
  `synthetic-closed-<k>.md`. Toutes DOIVENT être détectées. Libellés exacts `T38 (e.5.<k>)
  (DISCRIMINANT) : phrase non canonique détectée — <trace>` et `T38 (e.5.<k>) NON DISCRIMINANTE :
  phrase non canonique non détectée — « <phrase> »`. Les phrases, à la lettre :
  1. On dit jamais Task(vibeflow-head), pourtant le manager appelle bel et bien Task(vibeflow-head) chaque nuit.
  2. on ne fait jamais ca Mais on lance quand meme Task(vibeflow-head) chaque nuit
  3. on ne fait JAMAIS ca mais on lance quand meme Task(vibeflow-head) chaque nuit
  4. Le crafter n'est jamais dispatché seul, mais le manager lance Task(vibeflow-head) chaque nuit.
  5. vibeflow-head n'est pas de dispatch via Task(vibeflow-head).
  6. le manager attend jamais bien longtemps puis dispatche Task(vibeflow-head) sans discuter.
- (e.6), CONTRE-ÉPREUVE. Fichier contenant « vibeflow-head est incarné en session principale — »
  suivi de `${T38_CANON_FORMS[0]}` et d'un point. Il est construit depuis la constante, jamais retapé :
  des backticks retapés entre guillemets doubles seraient exécutés. Attendu NON détecté (1 − 1 = 0).
  Libellés `T38 (e.6) (CONTRE-ÉPREUVE) : forme canonique seule non détectée (1 − 1 = 0)` et
  `T38 (e.6) : faux positif — forme canonique seule détectée — <trace>`.
- (e.7), DISCRIMINANT. `${T38_CANON_FORMS[0]}` suivi de « mais aussi via Task(vibeflow-head) en
  direct. » sur la même ligne. Attendu détecté (2 − 1 = 1). Libellés `T38 (e.7) (DISCRIMINANT) :
  forme canonique + occurrence affirmative sur la même ligne détectée (2 − 1 = 1) — <trace>` et
  `T38 (e.7) NON DISCRIMINANTE : forme canonique + occurrence affirmative non détectée — « <ligne> »`.
- (e.8), CONTRE-ÉPREUVE. Deux fois `${T38_CANON_FORMS[0]}` sur la même ligne, séparées par une
  espace. Attendu NON détecté (2 − 2 = 0). Libellés `T38 (e.8) (CONTRE-ÉPREUVE) : deux formes
  canoniques sur la même ligne non détectées (2 − 2 = 0)` et `T38 (e.8) : faux positif — deux formes
  canoniques détectées — <trace>`.
Le `rm -rf "$T38_TMPDIR"` et la ligne ✓ récapitulative de T38 restent en place.

Étape 6, preuve. Lancer la suite dev et comparer les libellés ✓/✗ au journal de base. Seuls
disparaissent les anciens (e.5)/(e.6)/(e.7) ; s'ajoutent (e.5.1-6), (e.6), (e.7) et (e.8). Ne pas
lancer la suite design comme gate (voir les notes d'exécution).
  </action>
  <verify>
    <automated>F=plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh; G=plugin/dev-orchestrator/references/head-governance.md; L="${TMPDIR:-/tmp}/ogv-t1-dev.log"
[ -s "$F" ] && [ -s "$G" ] || { echo "entrees KO"; exit 1; }
[ "$(grep -c '^t38_count_literal() {' "$F")" -ge 1 ] && echo "fonction-comptage OK" || { echo "fonction-comptage KO"; exit 1; }
grep -q '^T38_CANON_FORMS=(' "$F" && grep -qF 'jamais dispatché lui-même comme sous-agent (`Task(vibeflow-head)`)' "$F" && grep -qF 'jamais dispatché lui-même comme sous-agent (`Task(vibeflow-head)`)' "$G" && echo "forme-canonique OK" || { echo "forme-canonique KO"; exit 1; }
[ "$(grep -v '^[[:space:]]*#' "$F" | grep -cF 'T38D_HEADLINES')" = 0 ] && echo "heredoc-retire OK" || { echo "heredoc-residuel KO"; exit 1; }
[ "$(grep -v '^[[:space:]]*#' "$F" | grep -cF ' mais | puis ')" = 0 ] && echo "fenetre-clause-retiree OK" || { echo "fenetre-clause-residuelle KO"; exit 1; }
[ "$(grep -v '^[[:space:]]*#' "$F" | grep -cF 'jamais\>')" = 0 ] && echo "regex-negation-retiree OK" || { echo "regex-negation-residuelle KO"; exit 1; }
bash "$F" > "$L" 2>&1; rc=$?; tail -1 "$L"; echo "rc=$rc"
[ "$rc" = 0 ] && [ "$(grep -c '✗' "$L")" = 0 ] && grep -q '0 KO / 0 SKIP ==$' "$L" && echo "suite-dev-verte OK" || { grep '✗' "$L"; echo "suite-dev KO"; exit 1; }
[ "$(grep -c '✓ T38 (e\.5\.[1-6]) (DISCRIMINANT)' "$L")" -ge 6 ] && echo "six-phrases OK" || { echo "six-phrases KO"; exit 1; }
grep -q '✓ T38 (e\.6) (CONTRE-ÉPREUVE)' "$L" && grep -q '✓ T38 (e\.7) (DISCRIMINANT)' "$L" && grep -q '✓ T38 (e\.8) (CONTRE-ÉPREUVE)' "$L" && echo "cas-ii-iii-iv OK" || { echo "cas-ii-iii-iv KO"; exit 1; }
grep -q '✓ T38 (d) ' "$L" && grep -q '✓ T38 (e\.4b) (DISCRIMINANT)' "$L" && grep -q '✓ T38 (e\.4c) (CONTRE-ÉPREUVE)' "$L" && echo "reel-non-detecte-et-invocable-detecte OK" || { echo "d-e4 KO"; exit 1; }</automated>
  </verify>
  <done>La suite dev rend 0 KO / 0 SKIP, rc 0, avec un total attendu de 227 OK ; tout écart est expliqué par un diff des libellés. (e.5.1) à (e.5.6), (e.6), (e.7), (e.8), (d), (e.4b) et (e.4c) sont ✓. L'ancien mécanisme de négation n'existe plus dans les lignes exécutables. La base (journaux macOS, BASE Linux et gate-linux.sh) est posée hors dépôt.</done>
</task>

<task type="auto">
  <name>Tâche 2 : T10 en monde fermé dans la suite design, synchro T10 (d) par corps de fonction, CHANGELOG design</name>
  <files>plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh, plugin/design-orchestrator/CHANGELOG.md</files>
  <read_first>plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh (lignes 40-75 et 814-1060), plugin/design-orchestrator/CHANGELOG.md (lignes 3-18), plugin/dev-orchestrator/CHANGELOG.md (lignes 3-19)</read_first>
  <action>
Étape 1, constantes. `T10_AFFIRM_RE` et `T10_TASK_LIT` restent inchangées : la première sert
toujours au grep des littéraux interdits. Supprimer la constante T10_NEG_RE. Juste après
`T10_TASK_LIT`, poser en colonne 0 un tableau bash à un élément `T10_CANON_FORMS`, entre apostrophes
simples, de valeur exacte :
jamais dispatché lui-même comme sous-agent (`Task(vibeflow-design)`)
Cette forme est posée par anticipation : aucune occurrence réelle aujourd'hui (mesure du
planificateur).

Étape 2, fonction de comptage. Poser `t10_count_literal` en colonne 0. Son corps est STRICTEMENT
identique à `t38_count_literal`, caractère pour caractère, indentation comprise : seul le nom change
sur la ligne de signature. Copier le corps depuis la suite dev déjà modifiée par la tâche 1, pas en
le retapant.

Étape 3, réécrire le CORPS de `t10_affirmative_hits`. Le nom ne change pas : (a), (b), (c.1), (c.2)
et (c.5) l'appellent.
- Même structure que la tâche 1 : grep de `T10_AFFIRM_RE` inchangé, puis `task_count` sur
  `"$T10_TASK_LIT"`.
- `canon_total` = somme sur `"${T10_CANON_FORMS[@]}"` via `t10_count_literal`.
- Si la différence est > 0, ajouter `"$GREP" -n -F -- "$T10_TASK_LIT" "$f"` à `hits`.
- Supprimer la boucle `while IFS= read`, l'expansion `%%`, la fenêtre `sed -E` de clause et le
  heredoc nommé T10_TASKLINES.

Étape 4, commentaires.
- En-tête du fichier, lignes 43-46 : remplacer « contre-épreuve sur la négation … » par le comptage
  en monde fermé (formes négatives canoniques). Garder « mêmes littéraux que T38 (d) », « synchro
  vérifiée machine » et « discriminants par mutation ».
- En-tête de section T10, lignes 815-838 : décrire le monde fermé, le motif du tour 3 (abandon de
  l'analyse de négation en langue naturelle, même historique que le commentaire jumeau de T38 (d)) et
  la synchro machine de T10 (d) : littéral affirmatif + corps de la fonction de comptage.
- La ligne ✓ récapitulative finale de T10 peut dire « mêmes littéraux et même mécanique de comptage
  que T38 ».

Étape 5, cas (c). (c.1), (c.2) et (c.4) restent inchangés.
- Remplacer l'ancien (c.3) et son commentaire par (c.3.1) à (c.3.6), DISCRIMINANT. Même boucle que
  (e.5.k) de la tâche 1, fichiers `synthetic-closed-<k>.md` sous `$T10_TMPDIR`, libellés `T10 (c.3.<k>)
  (DISCRIMINANT) : …` / `T10 (c.3.<k>) NON DISCRIMINANTE : … « <phrase> »`. Ce sont les 6 mêmes phrases
  que la tâche 1, avec vibeflow-design à la place de vibeflow-head partout, y compris en tête de la
  phrase 5.
- (c.5) : garder la contre-épreuve SKILL réel telle quelle (garde `t10b_hit` comprise). Garder la
  ligne synthétique sans littéral, mais reformuler son commentaire et ses messages : elle ne prouve
  plus qu'une négation est tolérée, seulement qu'une phrase négative sans le littéral
  `Task(vibeflow-design)` n'est pas détectée. Libellé ✓ : `T10 (c.5) (CONTRE-ÉPREUVE) : …`.
- Remplacer les anciens (c.6), (c.7) et (c.8) et leurs commentaires par les jumeaux de (e.6)/(e.7)/(e.8),
  construits depuis `${T10_CANON_FORMS[0]}` avec vibeflow-design :
  - (c.6) CONTRE-ÉPREUVE : forme seule, NON détectée (1 − 1 = 0) ;
  - (c.7) DISCRIMINANT : forme + « mais aussi via Task(vibeflow-design) en direct. » sur la même
    ligne, détectée (2 − 1 = 1) ;
  - (c.8) CONTRE-ÉPREUVE : deux formes sur la même ligne, NON détectées (2 − 2 = 0).
  Même règle d'impression du motif, chaque ✗ remet `t10_ok=0`.

Étape 6, T10 (d). Garder `T10_DEV_SUITE`, la branche SKIP (disposition lab) et `T10_TMPDIR`. Toutes
les vérifications ci-dessous restent DANS la branche où la suite dev existe. Commentaire de section :
« synchro des littéraux ET de la mécanique de comptage avec T38 ». Dans l'ordre, 4 lignes ✓ possibles,
toutes préfixées `T10 (d)` :
1. `grep -qF -- "$T10_AFFIRM_RE" "$T10_DEV_SUITE"`. ✓ `T10 (d) : T10_AFFIRM_RE trouvé en chaîne fixe
   dans test-dev-orchestrator.sh — littéral affirmatif synchronisé avec T38`, sinon ✗.
2. Témoin « Invocable via Tache » existant, inchangé. Supprimer le témoin jamaisZ, son fichier
   mutant et toute mention de T10_NEG_RE.
3. Extraire le corps de `t38_count_literal` depuis `"$T10_DEV_SUITE"` et celui de
   `t10_count_literal` depuis `"$0"`, par `sed -n '/^<nom>() {/,/^}/p' <fichier> | tail -n +2`. `$0`
   est déjà la convention de résolution du script, ligne 56.
   - Si l'un des deux corps est vide, ✗ `T10 (d) : extraction vide (dev=<n> lignes, design=<n>
     lignes) — la synchro ne peut pas se prononcer`. Sans cette garde, deux corps vides seraient
     jugés identiques : vert à vide.
   - Sinon, si `[ "$a" = "$b" ]`, ✓ `T10 (d) : corps de t38_count_literal (dev) et t10_count_literal
     (design) identiques caractère pour caractère — mécanique de comptage synchronisée`.
   - Sinon, ✗ `T10 (d) : mécanique de comptage divergée entre t38_count_literal et t10_count_literal`.
4. Témoin sur COPIE, jamais sur le fichier réel.
   - Écrire `$T10_TMPDIR/dev-suite-mutant-count.sh` = la suite dev passée par `sed` qui remplace
     « count + 0 » par « count + 1 », puis extraire le corps muté par le même `sed | tail`.
   - Si le corps muté est vide ou égal au corps dev d'origine, ✗ `T10 (d) : mutation « count + 1 »
     sans effet sur le corps extrait — témoin inopérant`.
   - Sinon, s'il est égal au corps design, ✗ `T10 (d) NON DISCRIMINANTE : le corps muté « count + 1 »
     reste jugé identique`.
   - Sinon, ✓ `T10 (d) (DISCRIMINANT) : le corps muté « count + 1 » n'est plus jugé identique au
     corps design`.
Chaque ✗ remet `t10_ok=0`. Le `rm -rf "$T10_TMPDIR"` final reste en place.

Étape 7, CHANGELOG design, entrée [v1.5.8] uniquement, puce `scripts/tests/test-design-orchestrator.sh`
(lignes 16-18). Une seule phrase, sans bump, rien d'autre dans le fichier. Garder « mêmes littéraux
que T38 de `test-dev-orchestrator.sh` », « synchro vérifiée machine » et « discriminants par mutation
permanents ». Remplacer la fin « contre-épreuve sur la négation … » par le comptage en monde fermé,
où seules des formes négatives canoniques exactes échappent à la détection. Le texte doit contenir
les mots « monde fermé ».

Étape 8, CHANGELOG dev : NE PAS modifier. Le planificateur a relu l'entrée [v2.22.3] (lignes 3-19).
Aucune ligne n'y décrit le mécanisme de négation : la puce T38 parle seulement d'un « discriminant
par mutation sur le contrôle de profondeur B1/B2 ». Relire pour confirmer. Si une ligne le décrivait
malgré tout, la consigner dans le SUMMARY au lieu d'élargir le commit.

Étape 9, preuve. Lancer la suite design et la suite dev, qui doit rester inchangée depuis la tâche 1.
  </action>
  <verify>
    <automated>F=plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh; V=plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh; C=plugin/design-orchestrator/CHANGELOG.md; L="${TMPDIR:-/tmp}/ogv-t2-design.log"
[ -s "$F" ] && [ -s "$V" ] && [ -s "$C" ] || { echo "entrees KO"; exit 1; }
[ "$(grep -c '^t10_count_literal() {' "$F")" -ge 1 ] && grep -q '^T10_CANON_FORMS=(' "$F" && grep -qF 'jamais dispatché lui-même comme sous-agent (`Task(vibeflow-design)`)' "$F" && grep -q '^T10_AFFIRM_RE=' "$F" && echo "constantes-fonction OK" || { echo "constantes-fonction KO"; exit 1; }
A="$(sed -n '/^t38_count_literal() {/,/^}/p' "$V" | tail -n +2)"; B="$(sed -n '/^t10_count_literal() {/,/^}/p' "$F" | tail -n +2)"
[ -n "$A" ] && [ "$A" = "$B" ] && printf '%s' "$A" | grep -qF 'idx = index(substr(line, start), lit)' && echo "corps-identiques OK" || { echo "corps-identiques KO"; exit 1; }
for lit in T10_NEG_RE T10_TASKLINES jamaisZ ' mais | puis ' 'jamais\>'; do [ "$(grep -v '^[[:space:]]*#' "$F" | grep -cF -- "$lit")" = 0 ] || { echo "residu-ancien-mecanisme KO : $lit"; exit 1; }; done; echo "ancien-mecanisme-retire OK"
bash "$F" > "$L" 2>&1; rc=$?; tail -1 "$L"; echo "rc=$rc"
[ "$rc" = 0 ] && [ "$(grep -c '✗' "$L")" = 0 ] && grep -q '0 KO / 0 SKIP ==$' "$L" && echo "suite-design-verte OK" || { grep '✗' "$L"; echo "suite-design KO"; exit 1; }
[ "$(grep -c '✓ T10 (c\.3\.[1-6]) (DISCRIMINANT)' "$L")" -ge 6 ] && grep -q '✓ T10 (c\.6) (CONTRE-ÉPREUVE)' "$L" && grep -q '✓ T10 (c\.7) (DISCRIMINANT)' "$L" && grep -q '✓ T10 (c\.8) (CONTRE-ÉPREUVE)' "$L" && echo "cas-neufs-design OK" || { echo "cas-neufs-design KO"; exit 1; }
[ "$(grep -c '✓ T10 (d)' "$L")" -ge 4 ] && grep -q '✓ T10 (d) (DISCRIMINANT) : le corps muté' "$L" && echo "synchro-T10d OK" || { echo "synchro-T10d KO"; exit 1; }
grep -q '✓ T10 (a) ' "$L" && grep -q '✓ T10 (b) ' "$L" && grep -q '✓ T10 (c\.1) (DISCRIMINANT)' "$L" && grep -q '✓ T10 (c\.5) (CONTRE-ÉPREUVE)' "$L" && echo "reels-et-invocable OK" || { echo "reels-et-invocable KO"; exit 1; }
grep -qF 'monde fermé' "$C" && [ "$(grep -cF 'négation légitime' "$C")" = 0 ] && echo "changelog-design OK" || { echo "changelog-design KO"; exit 1; }
/usr/bin/git diff --quiet HEAD -- plugin/dev-orchestrator/CHANGELOG.md && echo "changelog-dev-intact OK" || { echo "changelog-dev-modifie KO"; exit 1; }
bash "$V" > "${TMPDIR:-/tmp}/ogv-t2-dev.log" 2>&1; echo "dev rc=$? $(tail -1 "${TMPDIR:-/tmp}/ogv-t2-dev.log")"</automated>
  </verify>
  <done>La suite design rend 0 KO / 0 SKIP, rc 0, avec un total attendu de 49 OK ; tout écart est expliqué par un diff des libellés. (c.3.1) à (c.3.6), (c.6), (c.7) et (c.8) sont ✓. T10 (d) porte exactement 4 ✓, dont le témoin « count + 1 ». Les corps des deux fonctions de comptage sont identiques et non vides. Le CHANGELOG design dit « monde fermé » en une phrase ; le CHANGELOG dev est intact. La suite dev reste rc 0.</done>
</task>

<task type="auto">
  <name>Tâche 3 : preuves à rapporter mot pour mot (rouge sur vrais SKILL, gates, parité Linux), puis commit atomique des 3 fichiers</name>
  <files>plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh, plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh, plugin/design-orchestrator/CHANGELOG.md</files>
  <precondition>`/usr/bin/git status --porcelain --untracked-files=all` liste en suivi modifié exactement les 3 fichiers de files_modified plus `.planning/MISSION-HOTFIX-2632.dag.json`. Les deux SKILL.md sont identiques à HEAD (`/usr/bin/git diff --quiet HEAD -- plugin/design-orchestrator/skills/vf-design/SKILL.md plugin/dev-orchestrator/skills/vf-dev/SKILL.md`). Toute entrée non suivie est confinée à `.planning/quick/260917-ogv-t38-t10-monde-ferme-comptage-par-formes-/`.</precondition>
  <action>
Toutes les sorties citées ci-dessous vont dans le SUMMARY MOT POUR MOT : lignes ✗, dernière ligne
`== résultat : …`, code de sortie. Chemins absolus retirés.

Étape 1, preuve de rouge côté design.
- Ajouter en fin de `plugin/design-orchestrator/skills/vf-design/SKILL.md`, par `printf '%s\n' … >>`,
  la ligne exacte : On dit jamais Task(vibeflow-design), pourtant le manager appelle bel et bien
  Task(vibeflow-design) chaque nuit.
- Lancer la suite design vers un journal hors dépôt. Capturer toutes les lignes ✗, la ligne de
  totaux et le code de sortie.
- IMMÉDIATEMENT après, sans autre geste entre les deux, restaurer par `/usr/bin/git checkout --`
  sur ce seul fichier.
- Écrire `/usr/bin/git show HEAD:plugin/design-orchestrator/skills/vf-design/SKILL.md` dans un
  fichier hors dépôt et le comparer par `cmp` au fichier restauré ; rapporter la sortie de `cmp`.
- Attendu : rc 1 et au moins un ✗ `T10 (b)` dont la trace cite `<n>:On dit jamais
  Task(vibeflow-design)…`, `<n>` étant le numéro de la ligne ajoutée. Tout autre ✗ est rapporté et
  expliqué.
- Si `cmp` diffère, s'arrêter et rendre `bloqué` sans committer.

Étape 2, preuve de rouge côté dev. Même protocole sur
`plugin/dev-orchestrator/skills/vf-dev/SKILL.md`, avec la ligne exacte : On dit jamais
Task(vibeflow-head), pourtant le manager appelle bel et bien Task(vibeflow-head) chaque nuit.
Attendu : rc 1 et un ✗ `T38 (d)` citant vf-dev/SKILL.md et la ligne ajoutée. Un ✗ `T38 (e.4c)` est
probable, car le SKILL réel est alors détecté. Tout autre ✗ est rapporté verbatim et expliqué.
Restauration et `cmp` identiques à l'étape 1.

Étape 3, rejeu propre. Les deux suites sur l'arbre restauré : 0 KO / 0 SKIP, rc 0. Rapporter les
deux lignes de totaux (attendu 49 et 227 OK).

Étape 4, gates.
- `bash scripts/check-machine-paths.sh` : rc 0.
- `bash plugin/conductor/scripts/check-instruction-budget.sh` : rc 0.
Rapporter leur dernière ligne et leur code.

Étape 5, parité Linux. `bash ${TMPDIR:-/tmp}/ogv-linux-replay/gate-linux.sh <chemin absolu du
worktree>`, avec la base posée en tâche 1. Attendu : sortie 0 (`GATE-LINUX VERT`), `new-KO=0` sur les
deux suites et `cas-neufs design=9 dev=9 synchro-T10d=4`. Rapporter la sortie complète. Une sortie
1 ou 2 bloque le commit : rendre `bloqué` avec la sortie, sans corriger au-delà du mandat.

Étape 6, indexation. Indexer les 3 fichiers de `<files>` UN PAR UN, par chemin explicite. Jamais
d'ajout global (dépôt entier, répertoire courant ou `-u`), qui embarquerait le DAG du manager.
Contrôler que la liste indexée égale exactement ces 3 chemins et que le DAG n'est pas indexé.

Étape 7, commit. Message en français, cohérent avec `7bbaeea`.
- Titre : `test(orchestrators): T10/T38 — monde fermé, comptage par formes canoniques (hotfix v2.63.2, tour 3)`.
- Le corps résume :
  - l'abandon de l'analyse de négation en langue naturelle et le motif du tour 3 (repros `%%`,
    capitales, clause voisine sans séparateur, « pas de dispatch ») ;
  - le mécanisme : littéraux interdits inchangés, puis par fichier occurrences non chevauchantes de
    `Task(<head>)` moins les formes de `T38_CANON_FORMS`/`T10_CANON_FORMS`, via
    `t38_count_literal`/`t10_count_literal` en awk portable ;
  - les cas (e.5.1-6)/(e.6)/(e.7)/(e.8) et (c.3.1-6)/(c.6)/(c.7)/(c.8) ;
  - la synchro T10 (d) par corps de fonction, avec témoin « count + 1 » ;
  - la puce CHANGELOG design ;
  - les chiffres de preuve : totaux macOS, rouge sur les deux SKILL réels puis restauration
    cmp-identique, gates rc 0, gate-linux sortie 0.
- Le message n'attribue la décision à aucun humain : le mandat n'en transmet ni canal ni date
  (CLAUDE.md, traçabilité des arbitrages).
- Il se termine par exactement ces deux lignes consécutives, rien après :
Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01TSKYH6hUPUXMhAgf5mqRUC

Étape 8, après le commit.
- Ne pas pousser. Ne toucher ni STATE.md, ni ROADMAP.
- Rejouer le bloc `<automated>` ; la base Linux reste celle d'avant édition, donc `HEAD~1`.
- Écrire `260917-ogv-SUMMARY.md` avec : le SHA ; les preuves mot pour mot des étapes 1 à 5 ; les
  totaux avant/après ; la confirmation que l'unique occurrence réelle (head-governance.md:16) est
  couverte par la forme canonique, ou le signalement de toute occurrence réelle restée détectée,
  sans l'avoir modifiée ; la relecture du CHANGELOG dev (laissé intact). Aucun chemin absolu de poste.
  </action>
  <verify>
    <automated>S="$(/usr/bin/git show --name-only --format= HEAD | sort)"; E="$(printf '%s\n' plugin/design-orchestrator/CHANGELOG.md plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh | sort)"
[ -n "$S" ] && [ "$S" = "$E" ] && echo "scope-3 OK" || { echo "scope-3 KO : $S"; exit 1; }
I="$(/usr/bin/git diff --cached --name-only)" || { echo "git-diff-cached KO"; exit 1; }
[ -z "$I" ] && echo "index-vide OK" || { echo "index-non-vide KO : $I"; exit 1; }
/usr/bin/git diff --quiet HEAD -- plugin/design-orchestrator/skills/vf-design/SKILL.md plugin/dev-orchestrator/skills/vf-dev/SKILL.md && echo "skills-restaures OK" || { echo "skills-modifies KO"; exit 1; }
[ "$(/usr/bin/git log -1 --format=%B | awk 'NF' | tail -2)" = "$(printf '%s\n%s' 'Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>' 'Claude-Session: https://claude.ai/code/session_01TSKYH6hUPUXMhAgf5mqRUC')" ] && [ "$(/usr/bin/git log -1 --format=%B | grep -c 'Co-Authored-By')" = 1 ] && echo "trailers OK" || { echo "trailers KO"; exit 1; }
/usr/bin/git show HEAD:plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh | grep -q '^t38_count_literal() {' && /usr/bin/git show HEAD:plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh | grep -q '^t10_count_literal() {' && echo "comptage-commite OK" || { echo "comptage-commite KO"; exit 1; }
bash scripts/check-machine-paths.sh >/dev/null 2>&1; echo "machine-paths rc=$?"
bash plugin/conductor/scripts/check-instruction-budget.sh >/dev/null 2>&1; echo "instruction-budget rc=$?"
bash plugin/design-orchestrator/scripts/tests/test-design-orchestrator.sh > "${TMPDIR:-/tmp}/ogv-t3-design.log" 2>&1; echo "design rc=$? $(tail -1 "${TMPDIR:-/tmp}/ogv-t3-design.log")"
bash plugin/dev-orchestrator/scripts/tests/test-dev-orchestrator.sh > "${TMPDIR:-/tmp}/ogv-t3-dev.log" 2>&1; echo "dev rc=$? $(tail -1 "${TMPDIR:-/tmp}/ogv-t3-dev.log")"
bash "${TMPDIR:-/tmp}/ogv-linux-replay/gate-linux.sh" "$PWD"; echo "gate-linux exit=$?"</automated>
  </verify>
  <done>Avant commit, les preuves sont capturées mot pour mot :
- rouge sur vf-design/SKILL.md (rc 1, ✗ T10 (b) citant la ligne ajoutée) et sur vf-dev/SKILL.md (rc 1, ✗ T38 (d) citant la ligne ajoutée), chacun restauré et cmp-identique à HEAD ;
- suites propres 0 KO / 0 SKIP ;
- machine-paths rc 0, instruction-budget rc 0, gate-linux sortie 0.
Après commit : `scope-3 OK`, `index-vide OK`, `skills-restaures OK`, `trailers OK`, `comptage-commite OK`, les deux gates rc 0, les deux suites rc 0 et `gate-linux exit=0`. Commit non poussé, aucun arbitrage humain invoqué, `260917-ogv-SUMMARY.md` écrit sans chemin absolu de poste.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| texte de doctrine → gate de test | une prose rédigée par un humain ou un agent décide si le gate rougit : c'est la surface de contournement |
| poste macOS → CI ubuntu-latest | awk et sed diffèrent (BSD / mawk / gawk) ; un vert local peut rougir en CI |
| arbre de travail partagé → commit | le working tree porte aussi le DAG du manager amont |
| décision d'agent → artefact versionné | un choix transmis par mandat ne doit pas être gravé comme un arbitrage humain |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-ogv-01 | Tampering | t38d_affirmative_hits / t10_affirmative_hits | high | mitigate | Monde fermé : seule une forme exacte de T38_CANON_FORMS/T10_CANON_FORMS décompte une occurrence. 6 repros de contournement du tour 3 prouvées rouges par (e.5.k)/(c.3.k), et (e.7)/(c.7) prouvent qu'une forme canonique ne blanchit pas une occurrence affirmative voisine. |
| T-ogv-02 | Tampering | T10 (d) synchro | medium | mitigate | Corps extraits exigés non vides avant comparaison (pas de vert à vide sur deux chaînes vides), et témoin « count + 1 » sur copie qui doit rougir la comparaison. |
| T-ogv-03 | Tampering | preuve de rouge sur SKILL réels | medium | mitigate | Restauration immédiate par `/usr/bin/git checkout --` sur le seul fichier, `cmp` contre `git show HEAD:`, précondition « SKILL identique à HEAD » avant l'ajout, et verify post-commit `skills-restaures OK`. |
| T-ogv-04 | Denial of Service | job CI `tests` (ubuntu) | medium | mitigate | Corps de comptage prototypé par le planificateur sur awk BSD, mawk et gawk C.UTF-8 ; gate-linux.sh, déjà prouvé rouge sur l'arbre non modifié, exige sortie 0 avant commit. |
| T-ogv-05 | Repudiation | message de commit | low | mitigate | Aucun arbitrage humain invoqué : le mandat n'en transmet ni canal ni date (CLAUDE.md, traçabilité des arbitrages). |
| T-ogv-06 | Tampering | index git | low | mitigate | Indexation fichier par fichier, verify `scope-3 OK` : le DAG du manager ne peut pas entrer dans le commit. |
</threat_model>

<verification>
- Suites macOS : design 0 KO / 0 SKIP (attendu 49 OK), dev 0 KO / 0 SKIP (attendu 227 OK), rc 0.
- Cas neufs : 9 ✓ par suite ; T10 (d) : 4 ✓, dont le témoin « count + 1 ».
- Rouge prouvé sur les deux SKILL réels, puis restauration cmp-identique à HEAD.
- `scripts/check-machine-paths.sh` rc 0 ; `plugin/conductor/scripts/check-instruction-budget.sh` rc 0.
- `gate-linux.sh` (ubuntu:24.04) sortie 0 : new-KO 0/0, cas neufs 9/9, synchro 4.
- Commit : exactement 3 fichiers, trailers exacts, CHANGELOG dev intact, DAG hors commit.
</verification>

<success_criteria>
La détection T38/T10 ne dépend plus d'aucune analyse de négation en langue naturelle. Une occurrence
de `Task(<head>)` n'échappe au gate que si elle appartient à une forme canonique exacte, et chaque
forme ne blanchit qu'une seule occurrence. Les 6 repros de contournement rougissent. Les formes
canoniques seules ou répétées restent vertes, comme les fichiers de doctrine réels. La synchro dev ↔
design porte sur la mécanique de comptage et peut rougir. Le tout est livré en un commit de 3
fichiers, vert sur macOS et sur la parité Linux du job CI.
</success_criteria>

<output>
Créer `.planning/quick/260917-ogv-t38-t10-monde-ferme-comptage-par-formes-/260917-ogv-SUMMARY.md`
une fois terminé, avec les preuves mot pour mot exigées par la tâche 3.
</output>
