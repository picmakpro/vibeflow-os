---
phase: 75-activite-sur-le-code
plan: 09b
type: execute
wave: 6
depends_on: ["75-07", "75-08", "75-09a"]
cross_phase:
  - "79-01 (`VENDORED.txt` réduit à l'origine, la sentinelle et l'inventaire du plafond : ligne `RETRAIT` à confirmer sur la forme livrée, 75-RESEARCH O-4 ; aucun diff de patch)"
  - "79-02 (`socle-serveur.sh`)"
  - "79-11 (cliquet du plafond de lignes de `viewer.html` : le retrait ne fait que le BAISSER)"
  - "79-16 (`viewer.html`, coquille : état livré relu)"
  - "Phase 80 (`ui/80-vf-fr.js`, composition de l'en-tête et du « ⋯ », `ui/00-vibeflow.js`, `chrome-moteur-carte.mjs` : relire l'état livré ; ce plan ne retire que ce qui touche « récent »)"
  - "Phase 74 (dictionnaires éventuellement touchés : relire)"
files_modified:
  - plugin/cockpit/skills/cockpit-moteur/assets/viewer.html
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/25-recent.js
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/00-vibeflow.js
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/01-vf-responsive.js
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/02-vf-telephone.js
  - plugin/cockpit/skills/cockpit-moteur/VENDORED.txt
  - plugin/cockpit/scripts/tests/test-cockpit-ecrans-recent.sh
  - plugin/cockpit/scripts/tests/fixtures/test-cockpit-ecrans-recent/recent-doublons.json
  - plugin/cockpit/scripts/tests/test-cockpit-responsive.sh
  - .planning/workstreams/fiabilite/phases/VFDO-75-activite-sur-le-code/75-09b-RED-TRACE.md
autonomous: true
requirements: [ACTV-12, ACTV-01]
must_haves:
  truths:
    - "P75-D-20, seconde moitié (scission J16) : retirés, dans le MÊME LOT que la mise en service de l'empreinte (75-07, 75-08, jamais avant) : `ui/25-recent.js`, les classes `.recent` et `.recent-in`, `.rw`, `recentTip`, la bascule binaire « Travail récent » du menu « Types de liens », `#btn-recent` ; le jeton `--recent` RESTE (il porte « en cours »)"
    - "Un ajout, un retrait : le créneau d'en-tête et l'entrée du « ⋯ » qui portaient « Travail récent » deviennent `#btn-lentilles` à la MÊME place (P70-D-01 tenue) ; toutes les références à `#btn-recent` sont migrées, `ui/00-vibeflow.js:111` (`#btn-recent:hover svg.i`) comprise (B2) ; budget de largeur de l'en-tête à 1 024 px tenu (R13.3) ; « huit entrées » tenu"
    - "Doctrine du 2026-09-16 : suites ADAPTÉES, JAMAIS supprimées ni affaiblies ; nombre d'assertions de chaque suite avant et après (après >= avant) ; intention de chaque assertion modifiée nommée dans la trace"
    - "Dictionnaires et suites voisines (`moteur-carte`, `chrome-moteur-carte`, `chrome-fr`) : retirés par 75-09c (scission Q7), jamais par ce plan"
    - "`VENDORED.txt` : une ligne `RETRAIT` par fichier retiré si la forme livrée par 79-01 en porte, sinon l'inventaire du plafond et le CHANGELOG (75-10) ; le nombre de lignes de `viewer.html` avant et après est consigné"
    - "Exceptions nommées du grep d'inventaire : Exceptions NOMMÉES du grep d'inventaire (commande de 75-RESEARCH § Retrait), identiques dans 75-09a, 75-09b et 75-10 : (1) le jeton `--recent` ; (2) « récent » au sens du lancement (`chrome-lancer.mjs`, `test-cockpit-lancer-suivi.sh`, `test-cockpit-lancer-bout-en-bout.sh:283`, `test-cockpit-signal-mod.sh:164`) ; (3) le CHANGELOG ; (4) le mode « Change » du blueprint, inatteignable dans VibeFlow : `assets/serve.mjs:62,399,445` (tenu par la 79), `references/schema.md:5,103`, `const PLAN = !!G.meta.blueprint` de `viewer.html:671` et la lecture de `G.recent?.items` de `showChangeResult` (mode blueprint seulement, laissée, filtrée par son CONTENU) ; (5) la clé inerte `recent-hl` du `localStorage` (aucune lecture). (6) les lignes dont le CONTENU cite le NOM de fichier `refresh.mjs`, conservé (`test-cockpit-git-env.sh:213`, `references/blueprint.md:76`, `scripts/status.mjs`, `ui/00-vibeflow. (7) les ASSERTIONS D'ABSENCE que les plans écrivent eux-mêmes : `test-cockpit-securite.sh`, `test-cockpit-onglet-code.sh`, `test-cockpit-ecrans-recent.sh`, `test-cockpit-chrome-fr.sh`, `test-cockpit-responsive.sh`, `test-cockpit-activite-lentilles.sh` (L1 cite `#btn-recent` pour dire où le bouton se place) ; (8) les lignes `RETRAIT` de `VENDORED.txt` (trace du retrait, 79-01 O-4).js`). `scripts/refresh.mjs` n'est PAS une exception : son étape « Mark recent work » (l. 173) est retirée par 75-09a."
  artifacts:
    - path: plugin/cockpit/skills/cockpit-moteur/assets/ui/00-vibeflow.js
      provides: "règle de survol migrée vers `#btn-lentilles` ; jeton `--recent` intact"
    - path: plugin/cockpit/scripts/tests/test-cockpit-ecrans-recent.sh
      provides: "R1 et R2 lus sur le canal ; E1 à E4 intacts"
  key_links:
    - from: plugin/cockpit/scripts/tests/test-cockpit-responsive.sh
      to: plugin/cockpit/skills/cockpit-moteur/assets/ui/74-vf-activite.js
      via: "`#btn-lentilles` injecté à la place de `btn-recent` ; « huit entrées »"
      pattern: "btn-lentilles"
---

<objective>
Retirer côté page la couche déclarative « Travail récent » : page, bouton, jetons de survol (ACTV-12 ; ACTV-01 pour la place exacte du sélecteur). Le retrait se répartit en 75-09a (assemblage et moteur), 75-09b (page et jetons, ce plan) et 75-09c (dictionnaires et suites voisines).

Placement : après la Phase 79 ENTIÈRE, après la Phase 74, après 75-09a (donc après 75-07 et 75-08). `viewer.html` : touché en vagues 3, 4 et ici (6) seulement ; `02-vf-telephone.js` : 75-08 (vague 4) puis commentaires ici. Aucun diff de patch ; suites par `socle-serveur.sh`.

Purpose: tenir « un ajout = un retrait » côté page sans rien perdre des preuves.
Output: retrait dans le source de la page, deux suites adaptées, une trace avant/après.
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
@.planning/workstreams/fiabilite/phases/VFDO-75-activite-sur-le-code/75-UI-SPEC.md
@plugin/cockpit/skills/cockpit-moteur/VENDORED.txt
</context>

## Artifacts this phase produces

- retrait dans le source de la page (liste de `files_modified`) ; `ui/25-recent.js` supprimé
- deux suites adaptées (`test-cockpit-ecrans-recent.sh` et sa fixture, `test-cockpit-responsive.sh`) ; sans changement : `test-cockpit-signal-mod.sh:164`, `chrome-lancer.mjs:122`, `test-cockpit-lancer-suivi.sh:169`
- `75-09b-RED-TRACE.md`

<precondition>
75-09a, 75-07, 75-08 livrés ET verts. Relire `VENDORED.txt` livré (O-4). Refaire le grep d'inventaire (commande de 75-09a, `btn-recent` compris) et consigner l'écart avec la table de 75-RESEARCH § Retrait. Compter les assertions de chaque suite à adapter AVANT. Mesurer les lignes de `viewer.html` (cliquet 79-11).
</precondition>

<tasks>

<task type="tdd" tdd="true">
  <name>Tâche 1 (tracer) : la page ne porte plus la couche : en-tête, légende, classes, `#btn-recent` migré, `25-recent.js`</name>
  <files>plugin/cockpit/skills/cockpit-moteur/assets/viewer.html, plugin/cockpit/skills/cockpit-moteur/assets/ui/25-recent.js, plugin/cockpit/skills/cockpit-moteur/assets/ui/00-vibeflow.js, plugin/cockpit/skills/cockpit-moteur/assets/ui/01-vf-responsive.js, plugin/cockpit/skills/cockpit-moteur/assets/ui/02-vf-telephone.js, plugin/cockpit/skills/cockpit-moteur/VENDORED.txt, plugin/cockpit/scripts/tests/test-cockpit-ecrans-recent.sh, plugin/cockpit/scripts/tests/fixtures/test-cockpit-ecrans-recent/recent-doublons.json, plugin/cockpit/scripts/tests/test-cockpit-responsive.sh, .planning/workstreams/fiabilite/phases/VFDO-75-activite-sur-le-code/75-09b-RED-TRACE.md</files>
  <read_first>
  - 75-RESEARCH.md § « Retrait » (table des fichiers) ; 75-UI-SPEC « Sondes visuelles à rejouer » (S1, S13) et « Sélecteur de lentilles » (Place et forme : références à migrer)
  - test-cockpit-ecrans-recent.sh (E1 à E4, R1, R2), fixture `recent-doublons.json`, test-cockpit-responsive.sh (`btn-recent` injecté, « huit entrées », R13.3)
  </read_first>
  <behavior>
  - Q8 (S13) : la page ne contient plus `#btn-recent`, `.rw`, `.recent`, `.recent-in`, `no-recent`, `recentTip`, la ligne « Surligner le travail récent » de « Types de liens » ; `rtk proxy grep -rn "btn-recent" assets/ui assets/viewer.html` vide (B2) ; aucune règle `.recent` ou `.recent-in` active ; le jeton `--recent` défini et employé par le glyphe « en cours » ; l'ensemble des jetons identique (P71.5-D-29)
  - Q9 (S1) : `#btn-lentilles` à la place EXACTE : bureau, créneau ancien (entre Santé et la boussole) ; jusqu'à 999 px, entrée du « ⋯ » entre « Santé » et « Par où commencer » ; « huit entrées » et budget de 1 024 px tenus (R13.3) ; règle de survol `#btn-lentilles:hover svg.i` posée (mutant « règle de survol non migrée » rouge)
  - Q10 (ecrans-recent) : E1 à E4 intacts ; R1 et R2 deviennent « compte du sélecteur = cartes (un fichier écrit par deux agents = une carte) » et « agrégat du nœud = cartes » lus sur le canal ; `recent-doublons.json` devient une table de marques ; assertions après >= avant
  - Q11 (responsive) : `btn-recent` injecté remplacé par `btn-lentilles` ; R1, R3, R19, R20 et « huit entrées » non affaiblis
  </behavior>
  <action>
  Étape 1, témoin : adapter `test-cockpit-ecrans-recent.sh` et `test-cockpit-responsive.sh` d'abord (rouge sur la base : la couche existe, `btn-recent` trouvé), garder chaque intention, consigner assertions avant et après et la correspondance ancienne -> nouvelle.
  Étape 2, code : retraits selon la table de 75-RESEARCH (lignes relues) ; migrer `ui/00-vibeflow.js:111` ; commentaires de `01-vf-responsive.js` et `02-vf-telephone.js` ; `VENDORED.txt` ; lignes de `viewer.html` avant et après.
  Mutants : `btn-recent` laissé (Q8), jeton `--recent` supprimé (Q8), entrée du « ⋯ » déplacée (Q9), survol non migré (Q9).
  </action>
  <verify>
    <automated>O="${TMPDIR:-/tmp}/75-09b-t1.out"; bash plugin/cockpit/scripts/tests/test-cockpit-ecrans-recent.sh > "$O" 2>&1 || exit 1; test "$(rtk proxy grep -c '❌ FAIL' "$O")" -eq 0 || exit 1; rtk proxy grep -q 'Résultat : ' "$O" || exit 1; rtk proxy grep -q "PASS — E1\." "$O" || exit 1; rtk proxy grep -q "PASS — R1\." "$O" || exit 1; rtk proxy grep -q "PASS — Q8\." "$O" || exit 1; rtk proxy grep -q "PASS — Q10\." "$O" || exit 1; test "$(rtk proxy grep -c 'PASS — Q[0-9]*\.[0-9]* — mutant' "$O")" -ge 2 || exit 1; O2="${TMPDIR:-/tmp}/75-09b-t1b.out"; bash plugin/cockpit/scripts/tests/test-cockpit-responsive.sh > "$O2" 2>&1 || exit 1; test "$(rtk proxy grep -c '❌ FAIL' "$O2")" -eq 0 || exit 1; rtk proxy grep -q 'Résultats : ' "$O2" || exit 1; rtk proxy grep -q "PASS — R1 " "$O2" || exit 1; rtk proxy grep -q "PASS — R3 " "$O2" || exit 1; rtk proxy grep -q "PASS — R13\." "$O2" || exit 1; rtk proxy grep -q "PASS — R19\." "$O2" || exit 1; rtk proxy grep -q "PASS — Q11\." "$O2" || exit 1; test ! -e plugin/cockpit/skills/cockpit-moteur/assets/ui/25-recent.js || exit 1; test "$(rtk proxy grep -rc btn-recent plugin/cockpit/skills/cockpit-moteur/assets/ui plugin/cockpit/skills/cockpit-moteur/assets/viewer.html | rtk proxy grep -v ':0$' | rtk proxy grep -c .)" -eq 0 || exit 1; O3="${TMPDIR:-/tmp}/75-vendor.out"; bash plugin/cockpit/scripts/tests/test-cockpit-vendor.sh > "$O3" 2>&1 || exit 1; test "$(rtk proxy grep -c '❌ FAIL' "$O3")" -eq 0 || exit 1; rtk proxy grep -q 'Résultats : ' "$O3" || exit 1; rtk proxy grep -q "PASS — V4 " "$O3" || exit 1; bash scripts/check-machine-paths.sh || exit 1</automated>
    <fails_when>le nombre d'assertions baisse, une référence à `#btn-recent` subsiste (dont `00-vibeflow.js:111`), ou le jeton `--recent` a disparu</fails_when>
  </verify>
  <acceptance_criteria>
  - la trace contient, pour les deux suites, une table « avant / après / intention conservée »
  - le nombre de lignes de `viewer.html` après <= avant
  </acceptance_criteria>
  <done>La couche et son bouton sont retirés, le sélecteur occupe la place exacte, aucune preuve n'a été perdue.</done>
</task>

</tasks>

<threat_model>
Suites affaiblies pour verdir : comptes d'assertions et intention nommée ; régression de jeton : comparaison des jetons avant et après ; en-tête qui déborde à 1 024 px : R13.3 ; référence orpheline à `#btn-recent` (règle de survol) : grep.
</threat_model>

<success_criteria>
ACTV-12, moitié page : couche, bouton et dictionnaires retirés dans le même lot, suites adaptées jamais supprimées, `--recent` gardé ; ACTV-01 : sélecteur à la place exacte, « huit entrées » tenu.
</success_criteria>

<output>
`75-09b-SUMMARY.md` ; y consigner l'inventaire avant/après, la forme de `VENDORED.txt`, le nombre de lignes de `viewer.html` et les exceptions restantes.
</output>
