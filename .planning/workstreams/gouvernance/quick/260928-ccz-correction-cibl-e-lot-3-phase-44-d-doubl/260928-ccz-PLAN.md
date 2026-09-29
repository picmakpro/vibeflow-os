---
quick_id: 260928-ccz
type: quick-full
files_modified:
  - plugin/planning-core/scripts/recalc-planning.sh
  - plugin/planning-core/scripts/tests/test-recalc-planning.sh
  - plugin/planning-core/references/modele-cycles.md
  - plugin/planning-core/CHANGELOG.md
autonomous: true

must_haves:
  truths:
    - "Constat 1 (revue) : le dédoublonnage de `lignes_a_journaliser` compare la valeur ASSAINIE des deux côtés (celle qui est ou serait écrite) — une `tentative` piégée contenant un espace ou un `=` ne rejournalise plus à chaque exécution (P44-D-11 tenue)."
    - "Test de régression réel (round-trip, pas un appel de fonction isolé) : deux exécutions successives de recalc-planning.sh sur un lab dont une unité close porte la `tentative` piégée exacte de la revue → une seule ligne dans cloture.log, cloture_ajouts=0 au 2e run."
    - "Constat 2 (audit) : le refus « migration à examiner » (Q1 c, P44-D-01c) tient quelle que soit la valeur de GSD_HOME ou de l'environnement hérité — y compris quand la chaîne GSD est absente de la machine (détecteur sorti en code 1 avant sa priorité 3)."
    - "detect-gsd-engine.sh et ses suites restent INCHANGÉS (P44-D-01b) ; aucune dépendance de code vers gsd-core (P44-D-01d)."
    - "Les cas légitimes du banc qui écrivent aujourd'hui (terrain libre, code 3, sans signal de code) continuent d'écrire — R13 (b) reste vert."
    - "modele-cycles.md (table des codes du détecteur, l.60-61 avant fix) est aligné sur le comportement réel."
    - "Aucune régression : les 8 suites sœurs de planning-core restent vertes et non modifiées ; la sonde PY39 reste verte sous bash et sous zsh ; 171 → au moins 180 OK sur test-recalc-planning.sh."
  artifacts:
    - path: "plugin/planning-core/scripts/recalc-planning.sh"
      provides: "lignes_a_journaliser (comparaison sur chemin_jeton/couple_jeton), detection_gsd (motif-code-1-socle-et-signal, _porte_planning_version, _a_signal_de_code), bash résolu par shutil.which"
      contains: "motif-code-1-socle-et-signal"
    - path: "plugin/planning-core/scripts/tests/test-recalc-planning.sh"
      provides: "R-DEDOUBLONNAGE-ASSAINI (round-trip réel), MUT-DEDOUBLONNAGE-BRUT, R-GSD-HOME-SIGNAL (a)/(b), MUT-CODE1-SOCLE-SIGNAL"
      contains: "R-GSD-HOME-SIGNAL"
  key_links: []

estimate:
  tokens: 0
  raw_tokens: 0
  tasks: 2
  confidence: n/a
---

# Plan — correction ciblée lot 3, Phase 44 (nœud `exec-44` rouvert)

Note de méthode (identique au lot 2, `260928-b4c-PLAN.md`) : ce plan est rédigé APRÈS coup —
vf-coder (mandat de correction ciblée du manager `vf-dev-manager-g44`) a directement appliqué les
correctifs, écrit les tests de régression et de mutation AVANT d'invoquer `gsd-quick --validate`
pour la traçabilité (commits atomiques, `gsd-verifier`). Aucun agent `gsd-planner`/`gsd-executor`
n'a été dispatché : ces types ne figurent pas dans l'allowlist de vf-coder, et le travail était
déjà écrit et vérifié sur disque avant l'invocation du skill. `gsd-verifier` (dans l'allowlist de
vf-coder) est dispatché directement depuis la session vf-coder.

## Tâche 1 — Dédoublonnage du journal comparé sur la valeur assainie (constat 1, revue)

**files:** plugin/planning-core/scripts/recalc-planning.sh,
plugin/planning-core/scripts/tests/test-recalc-planning.sh
**action:** Dans `lignes_a_journaliser`, comparer `dernier_couple.get(chemin_jeton)` à
`(_jeton_journal(verdict, "-"), _jeton_journal(tentative, "-"))` au lieu de la valeur brute — le
journal relu ne contient que des jetons déjà assainis, comparer une valeur brute d'un côté rejoue
l'écriture à chaque exécution dès qu'un champ contient un espace ou un `=`. Mettre à jour le motif
ciblé par MUT-DEDOUBLONNAGE (suit le renommage de la ligne) et ajouter
R-DEDOUBLONNAGE-ASSAINI (round-trip réel, valeur piégée exacte de la revue) +
MUT-DEDOUBLONNAGE-BRUT (réintroduit le bug exact, tué par le round-trip).
**verify:** `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` — R-DEDOUBLONNAGE-ASSAINI
vert (1 ligne après chacun des deux runs réels, cloture_ajouts=0 au 2e), MUT-DEDOUBLONNAGE et
MUT-DEDOUBLONNAGE-BRUT tués.
**done:** Le round-trip réel sur la valeur piégée espaces+`=` est vert ; le mutant qui réintroduit
exactement le bug de la revue est tué.

## Tâche 2 — Refus « migration à examiner » indépendant de GSD_HOME (constat 2, audit)

**files:** plugin/planning-core/scripts/recalc-planning.sh,
plugin/planning-core/scripts/tests/test-recalc-planning.sh,
plugin/planning-core/references/modele-cycles.md, plugin/planning-core/CHANGELOG.md
**action:** Ajouter `_porte_planning_version` et `_a_signal_de_code` (reproduction Python pure de
la priorité 3 de `detect-gsd-engine.sh`, jamais un sourcing ni une dépendance de code — P44-D-01b,
P44-D-01d) ; dans `detection_gsd()`, la branche code==1 refuse désormais l'écriture
(`non-concluante`) quand STATE.md porte `planning_version` ET qu'un signal de code est présent à
la racine du lab, avant de retomber sur `non-gsd`. Résoudre `bash` par `shutil.which` plutôt que
par le PATH hérité (accessoire, à faible coût). Documenter le changement dans `modele-cycles.md`
(table des codes) et le CHANGELOG (entrée v2.8.0, non publiée).
**verify:** `bash plugin/planning-core/scripts/tests/test-recalc-planning.sh` — R-GSD-HOME-SIGNAL
(a) et (b) verts (code 3 dans les deux cas, empreinte identique), MUT-CODE1-SOCLE-SIGNAL tué, R13
(a)/(b)/(c) toujours verts (aucune régression sur le comportement existant du code 1).
**done:** Le refus tient identiquement en environnement normal et avec `GSD_HOME` inexistant ; le
cas légitime « terrain libre, code 1, aucun signal » continue d'écrire.
