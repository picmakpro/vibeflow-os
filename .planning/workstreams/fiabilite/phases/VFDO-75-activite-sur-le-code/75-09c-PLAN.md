---
phase: 75-activite-sur-le-code
plan: 09c
type: execute
wave: 7
depends_on: ["75-09b"]
cross_phase:
  - "79-01 (aucun diff de patch ; `VENDORED.txt` : pas touché ici, 75-09b l'a fait)"
  - "80-14 (palette de commandes : touche `test-cockpit-chrome-fr.sh` et `ui/79-vf-fr-dict-c.js` ; relire l'état livré avant d'adapter F13.3 : fichier commun)"
  - "Phase 74 (dictionnaires éventuellement touchés : relire)"
files_modified:
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/78-vf-fr-dict-a.js
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/80-vf-fr.js
  - plugin/cockpit/scripts/tests/test-cockpit-moteur-carte.sh
  - plugin/cockpit/scripts/tests/chrome-moteur-carte.mjs
  - plugin/cockpit/scripts/tests/test-cockpit-chrome-fr.sh
  - .planning/workstreams/fiabilite/phases/VFDO-75-activite-sur-le-code/75-09c-RED-TRACE.md
autonomous: true
requirements: [ACTV-12]
must_haves:
  truths:
    - "Scission Q7 (75-09b : page et jetons ; 75-09c : dictionnaires et suites voisines) : même lot et même PR que 75-07, 75-08, 75-09a, 75-09b, jamais avant"
    - "Dictionnaires : les entrées `Recent work`, `Highlight recent work`, `Recent work inside` et `.rw` -> `Récent` sont retirées de `78-vf-fr-dict-a.js` et `80-vf-fr.js` ; `79-vf-fr-dict-b.js` n'est pas touché ; ces deux fichiers ne sont touchés que par CE plan dans la phase"
    - "Doctrine du 2026-09-16 : suites ADAPTÉES, JAMAIS supprimées ni affaiblies ; assertions après >= avant ; intention de chaque assertion modifiée nommée dans la trace"
    - "Exceptions du grep d'inventaire : celles de 75-09a, épinglées par contenu, identiques dans les quatre plans du retrait ; la commande de la dernière `<automated>` rejoue le grep et exige ZÉRO ligne"
  artifacts:
    - path: plugin/cockpit/skills/cockpit-moteur/assets/ui/80-vf-fr.js
      provides: "dictionnaire sans entrée « recent » ; F2 (non-traduits) vert"
  key_links:
    - from: plugin/cockpit/scripts/tests/test-cockpit-chrome-fr.sh
      to: plugin/cockpit/skills/cockpit-moteur/assets/ui/80-vf-fr.js
      via: "`window.__vfFrTraduire` évaluée en vm sur le rendu servi"
      pattern: "__vfFrTraduire"
---

<objective>
Aligner les dictionnaires français et les suites voisines sur le retrait de la couche « Travail récent » (ACTV-12), moitié « dictionnaires et suites voisines » de l'ancien 75-09b.

Placement : après 75-09b (la page ne porte plus la couche), donc après la Phase 79 entière, la Phase 74 et 75-07 à 75-09b ; dernier plan du lot retrait. `ui/80-vf-fr.js` et `test-cockpit-chrome-fr.sh` sont aussi modifiés par la Phase 80 (80-14) : relire l'état livré. Aucun diff de patch ; suites par `socle-serveur.sh` (livré par 79-02).

Purpose: fermer le retrait, grep d'inventaire à zéro.
Output: dictionnaires nettoyés, trois suites adaptées, une trace.
</objective>

<conventions>
Suites NOUVELLES de ce plan : ligne `PASS — <id> : <texte>` (un espace après l'identifiant), `❌ FAIL — <id> : <texte>`, `MUTANT-ROUGE — <nom>`, ligne finale `BILAN : <n> PASS, <m> FAIL`. Suites EXISTANTES (aucune assertion existante n'est modifiée pour y gagner une ligne) : format réel `Résultats : N PASS / M FAIL`, identifiants SUFFIXÉS (`E1.1`, `K17.1`, `C0.1`) contrôlés par `PASS — E1\.` ; les assertions et mutants ajoutés à une suite existante portent aussi un identifiant suffixé (`Q3.1`). Chaque trace de `75-NN-RED-TRACE.md` relativise tout chemin absolu, nomme le SHA RÉELLEMENT mesuré comme base du rouge (`git rev-parse --short HEAD` à la mesure : la branche part de `f763b556`, le rouge est mesuré après les Phases 79, 80 et 74), et associe à chaque témoin rouge sur « module absent » le mutant ou l'état intermédiaire qui établit la BONNE raison de l'échec.
</conventions>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/workstreams/fiabilite/phases/VFDO-75-activite-sur-le-code/75-CONTEXT.md
@.planning/workstreams/fiabilite/phases/VFDO-75-activite-sur-le-code/75-RESEARCH.md
</context>

<precondition>
75-09b livré et vert. Compter les assertions de `test-cockpit-moteur-carte.sh` et `test-cockpit-chrome-fr.sh` AVANT adaptation. Relire `ui/80-vf-fr.js` et `test-cockpit-chrome-fr.sh` tels que livrés par 80-14.
</precondition>

<tasks>

<task type="tdd" tdd="true">
  <name>Tâche 1 (CONDITIONNÉE) : dictionnaires, cartes du moteur et fils d'Ariane : `moteur-carte`, `chrome-moteur-carte`, `chrome-fr`</name>
  Condition de départ : réponse de Samuel à Q-75-3 consignée, option (a) ; à défaut de réponse ou si (b), appliquer le repli de P75-D-20 : « Récent » reste une lentille de plus, même canal, même emplacement, le retrait se réduit à `recent.mjs`.
  Sous le repli : les entrées « Recent work » des dictionnaires et les suites `moteur-carte`, `chrome-moteur-carte` et `chrome-fr` restent telles quelles (F13.3 inchangée) ; le grep d'inventaire n'exige plus zéro pour les motifs de la couche, seulement pour `recent.mjs`. Plan VIDE sous le repli : aucune tâche non conditionnée.
  <files>plugin/cockpit/skills/cockpit-moteur/assets/ui/78-vf-fr-dict-a.js, plugin/cockpit/skills/cockpit-moteur/assets/ui/80-vf-fr.js, plugin/cockpit/scripts/tests/test-cockpit-moteur-carte.sh, plugin/cockpit/scripts/tests/chrome-moteur-carte.mjs, plugin/cockpit/scripts/tests/test-cockpit-chrome-fr.sh, .planning/workstreams/fiabilite/phases/VFDO-75-activite-sur-le-code/75-09c-RED-TRACE.md</files>
  <read_first>
  - test-cockpit-moteur-carte.sh (K17), chrome-moteur-carte.mjs (l. ~242-254), test-cockpit-chrome-fr.sh (F13.3 « Recent work: Recent work », F2 non-traduits)
  </read_first>
  <behavior>
  - Q12 (moteur-carte, chrome-moteur-carte) : K17.1 le badge devient la pastille du sélecteur ; K17.2 et K17.3 (`showBoard` coupé à 24) gardés avec un `kind` neutre : la coupe est générique
  - Q13 (chrome-fr) : F13.3 remplacé par un autre fil d'Ariane `X: X` encore servi ; F2 (non-traduits) vert avec les entrées « Recent work », « Highlight recent work », « Recent work inside » et `.rw` -> `Récent` retirées des dictionnaires (aucune entrée orpheline)
  - Q14 : le grep d'inventaire final, filtré par la liste des exceptions nommées (commande de la dernière `<automated>`, `DESIGN.md` et `plugin/cockpit/README.md` exclus car réécrits par 75-10), rend ZÉRO ligne ; chaque exception est nommée dans la trace avec sa raison
  </behavior>
  <action>
  Témoin d'abord, adaptations sans affaiblir, puis retraits. Rejouer, SANS les affaiblir, `chrome-moteur-carte`, `test-cockpit-responsive.sh` (R1, R3, R19, R20), `chrome-equipe-clavier.mjs` (EK10) et le mutant d'équipe (qui reste rouge). Mutants : entrée de dictionnaire orpheline (Q13 rouge), `kind` neutre retiré (Q12 rouge).
  </action>
  <verify>
    <automated>O="${TMPDIR:-/tmp}/75-09c-t2.out"; bash plugin/cockpit/scripts/tests/test-cockpit-moteur-carte.sh > "$O" 2>&1 || exit 1; test "$(rtk proxy grep -c '❌ FAIL' "$O")" -eq 0 || exit 1; rtk proxy grep -q 'Résultats : ' "$O" || exit 1; rtk proxy grep -q "PASS — K17\." "$O" || exit 1; rtk proxy grep -q "PASS — Q12\." "$O" || exit 1; test "$(rtk proxy grep -c 'PASS — Q[0-9]*\.[0-9]* — mutant' "$O")" -ge 1 || exit 1; O2="${TMPDIR:-/tmp}/75-09c-t2b.out"; bash plugin/cockpit/scripts/tests/test-cockpit-chrome-fr.sh > "$O2" 2>&1 || exit 1; test "$(rtk proxy grep -c '❌ FAIL' "$O2")" -eq 0 || exit 1; rtk proxy grep -q 'Résultats : ' "$O2" || exit 1; rtk proxy grep -q "PASS — F13\." "$O2" || exit 1; rtk proxy grep -q "PASS — Q13\." "$O2" || exit 1; test "$(rtk proxy grep -rnI -E "recent-work|25-recent|recentTip|recent\.mjs|no-recent|Travail récent|Recent work|graph\.recent|\.recent-in|\.recent\b|'rw'|\.rw\b|Récent|btn-recent" plugin scripts .github DESIGN.md README.md README.fr.md | rtk proxy grep -v -E 'CHANGELOG|--recent|chrome-lancer\.mjs:[0-9]+:.*ch7\.recent|test-cockpit-lancer-suivi\.sh:[0-9]+:.*RECENCE_MS|test-cockpit-lancer-bout-en-bout\.sh:[0-9]+:.*CH7 — seconde proposition|test-cockpit-signal-mod\.sh:[0-9]+:.*\| Récent / fait|serve\.mjs:[0-9]+:.*(delete out\.recent|const PLAN_FILES = |the Recent work panel shows|write\(.recent-work\.json.)|references/schema\.md:[0-9]+:.*(Contents: \[Top level\]|floorplan/recent-work\.json. is a separate file)|viewer\.html:[0-9]+:.*const items = \(G\.recent\?\.items \|\| \[\]\)\.filter\(\(x\) => parentOf|VENDORED\.txt:[0-9]+:.*RETRAIT|^(DESIGN\.md|plugin/cockpit/README\.md):' | rtk proxy grep -c .)" -eq 0 || exit 1; O3="${TMPDIR:-/tmp}/75-vendor.out"; bash plugin/cockpit/scripts/tests/test-cockpit-vendor.sh > "$O3" 2>&1 || exit 1; test "$(rtk proxy grep -c '❌ FAIL' "$O3")" -eq 0 || exit 1; rtk proxy grep -q 'Résultats : ' "$O3" || exit 1; rtk proxy grep -q "PASS — V4 " "$O3" || exit 1; bash scripts/check-machine-paths.sh || exit 1</automated>
    <fails_when>le mutant d'équipe cesse d'être rouge, une suite voisine est modifiée pour verdir, ou une entrée « recent » subsiste dans un dictionnaire</fails_when>
  </verify>
  <acceptance_criteria>
  - la trace contient la table « avant / après / intention conservée » des trois suites et le grep final avec ses exceptions nommées
  - `git diff --stat` ne liste ni `DESIGN.md`, ni `README*`, ni `CHANGELOG.md` (75-10)
  </acceptance_criteria>
  <done>Dictionnaires et suites voisines sont alignés, la couche n'a plus aucune trace hors des exceptions nommées.</done>
</task>

</tasks>

<threat_model>
Suites affaiblies pour verdir : comptes d'assertions et intention nommée ; entrée de dictionnaire orpheline (faux « non traduit ») : F2.
</threat_model>

<success_criteria>
ACTV-12, moitié dictionnaires et suites voisines : entrées « recent » retirées, `moteur-carte`, `chrome-moteur-carte` et `chrome-fr` adaptées sans perte d'assertion, grep d'inventaire à zéro hors exceptions nommées.
</success_criteria>

<output>
`75-09c-SUMMARY.md` ; y consigner le grep final avec ses exceptions et les comptes d'assertions.
</output>
