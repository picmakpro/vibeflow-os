---
phase: 75-activite-sur-le-code
plan: 09a
type: execute
wave: 5
depends_on: ["75-06", "75-07", "75-08"]
cross_phase:
  - "79-01 (appareil de patchs `plugin/cockpit/amont/` retiré, `VENDORED.txt` réduit : aucun diff de patch régénéré ; la trace du retrait côté `VENDORED.txt` est dans 75-09b)"
  - "79-02 (`socle-serveur.sh` : migration des suites qui lancent le serveur, déjà faite)"
  - "79-15 (`serve.mjs`, export : état livré relu ; `serve.mjs` n'est PAS modifié ici)"
files_modified:
  - plugin/cockpit/scripts/vf-cockpit-build.mjs
  - plugin/cockpit/skills/cockpit-moteur/scripts/build.mjs
  - plugin/cockpit/skills/cockpit-moteur/scripts/recent.mjs
  - plugin/cockpit/skills/cockpit-moteur/scripts/refresh.mjs
  - plugin/cockpit/skills/cockpit-moteur/assets/graph-query.js
  - plugin/cockpit/skills/cockpit-moteur/assets/ui/60-export.js
  - plugin/cockpit/scripts/tests/test-cockpit-securite.sh
  - plugin/cockpit/scripts/tests/test-cockpit-onglet-code.sh
  - .planning/workstreams/fiabilite/phases/VFDO-75-activite-sur-le-code/75-09a-RED-TRACE.md
autonomous: true
requirements: [ACTV-12]
must_haves:
  truths:
    - "P75-D-20, première moitié (scission J16 : 75-09a assemblage et moteur, 75-09b page ; même lot et même PR que 75-07 et 75-08, jamais avant) : l'écriture de `recent-work.json` (`vf-cockpit-build.mjs:70-80`), la lecture et la ligne de rapport du moteur (`scripts/build.mjs`), `scripts/recent.mjs` (jamais appelé par l'assemblage VibeFlow), l'étape « Mark recent work » de `scripts/refresh.mjs:173` (elle demande d'exécuter `recent.mjs` : sans elle, un moteur à jour guiderait vers un script supprimé), `recentWork` de `graph-query.js` et la partie d'export « Recent work » de `ui/60-export.js` sont retirés ; le jeton `--recent` RESTE (P71.5-D-26, D-29)"
    - "Doctrine du 2026-09-16 (« ne pas supprimer pour verdir ») : `test-cockpit-securite.sh` et `test-cockpit-onglet-code.sh` sont ADAPTÉS, jamais supprimés ni affaiblis ; le nombre d'assertions de chacune ne baisse pas ; chaque assertion modifiée garde son intention, nommée dans la trace"
    - "ACTV-12, série de sondes « Y » de `test-cockpit-securite.sh` (et non « M4 » : la lettre M4 y désigne autre chose) : le lien symbolique posé sur `recent-work.json` est reporté sur `.gitignore` SEUL (écrit par le socle, `vf-cockpit-build.mjs:82` ; pas `graph.json`) ; Y1 et Y2 inchangés ; témoin rouge : `verifierSortie` neutralisé, `dehors.txt` réécrit"
    - "`recent-work.json` hérité d'un assemblage précédent est supprimé au prochain assemblage (`rmSync` avec `force`, APRÈS `verifierSortie`) ; aucune migration"
    - "Aucun diff de patch n'est régénéré ; les suites par `socle-serveur.sh` ; 75-RESEARCH O-4 (forme de `VENDORED.txt`) est revalidé par 75-09b"
    - "Exceptions nommées du grep d'inventaire : Exceptions NOMMÉES du grep d'inventaire (commande de 75-RESEARCH § Retrait), identiques dans 75-09a, 75-09b et 75-10 : (1) le jeton `--recent` ; (2) « récent » au sens du lancement (`chrome-lancer.mjs`, `test-cockpit-lancer-suivi.sh`, `test-cockpit-lancer-bout-en-bout.sh:283`, `test-cockpit-signal-mod.sh:164`) ; (3) le CHANGELOG ; (4) le mode « Change » du blueprint, inatteignable dans VibeFlow : `assets/serve.mjs:62,399,445` (tenu par la 79), `references/schema.md:5,103`, `const PLAN = !!G.meta.blueprint` de `viewer.html:671` ; (5) la clé inerte `recent-hl` du `localStorage` (aucune lecture). (6) les mentions du NOM de fichier `refresh.mjs`, conservé (`test-cockpit-git-env.sh:213`, `references/blueprint.md:76`, `scripts/status.mjs`, `ui/00-vibeflow.js`). `scripts/refresh.mjs` n'est PAS une exception : son étape « Mark recent work » (l. 173) est retirée par 75-09a."
  artifacts:
    - path: plugin/cockpit/scripts/vf-cockpit-build.mjs
      provides: "assemblage sans `recent-work.json` ; suppression du fichier hérité"
    - path: plugin/cockpit/scripts/tests/test-cockpit-securite.sh
      provides: "sonde Y reportée sur `.gitignore`, mutant `verifierSortie` neutralisé"
  key_links:
    - from: plugin/cockpit/scripts/tests/test-cockpit-securite.sh
      to: plugin/cockpit/scripts/vf-cockpit-build.mjs
      via: "lien symbolique posé sur `.gitignore` : `verifierSortie` refuse avant toute écriture"
      pattern: "verifierSortie"
---

<objective>
Retirer côté assemblage et moteur la couche déclarative « Travail récent » et `scripts/recent.mjs` (ACTV-12). Moitié « données » du retrait ; la moitié « page » est 75-09b. Un ajout, un retrait : contrepartie de 75-07 et 75-08, dans le même lot.

Placement : après la Phase 79 ENTIÈRE, après la Phase 74, après 75-06, 75-07, 75-08 (le sélecteur existe déjà). Fichiers disjoints de 75-09b ; `vf-cockpit-build.mjs` : ligne d'annotateur de 75-06 (vague 2) puis retrait ici. Aucun diff de patch ; suites par `socle-serveur.sh`.

Purpose: tenir « un ajout = un retrait » sans rien perdre des preuves.
Output: retrait dans l'assemblage et le moteur, deux suites adaptées, une trace avant/après.
</objective>

<conventions>
Suites NOUVELLES de ce plan : ligne `PASS — <id> : <texte>` (un espace après l'identifiant), `❌ FAIL — <id> : <texte>`, `MUTANT-ROUGE — <nom>`, ligne finale `BILAN : <n> PASS, <m> FAIL`. Suites EXISTANTES (aucune assertion existante n'est modifiée pour y gagner une ligne) : format réel `Résultats : N PASS / M FAIL`, identifiants SUFFIXÉS (`E1.1`, `K17.1`, `C0.1`) contrôlés par `PASS — E1\.` ; les assertions et mutants ajoutés à une suite existante portent aussi un identifiant suffixé (`Q3.1`). Chaque trace de `75-NN-RED-TRACE.md` relativise tout chemin absolu, nomme `f763b556` comme base, et associe à chaque témoin rouge sur « module absent » le mutant ou l'état intermédiaire qui établit la BONNE raison de l'échec.
</conventions>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/workstreams/fiabilite/phases/VFDO-75-activite-sur-le-code/75-CONTEXT.md
@.planning/workstreams/fiabilite/phases/VFDO-75-activite-sur-le-code/75-RESEARCH.md
@plugin/cockpit/scripts/vf-cockpit-build.mjs
@plugin/cockpit/skills/cockpit-moteur/VENDORED.txt
</context>

## Artifacts this phase produces

- retrait dans `vf-cockpit-build.mjs` et le source du moteur (liste de `files_modified`) ; `scripts/recent.mjs` supprimé
- deux suites adaptées ; `75-09a-RED-TRACE.md`

<precondition>
75-06, 75-07 et 75-08 livrés ET verts (rejouer leurs suites en tête) : sinon arrêt, le retrait ne part jamais avant la mise en service. Refaire la mesure d'inventaire : `rtk proxy grep -rnI -E "recent-work|25-recent|recentTip|recent\.mjs|no-recent|Travail récent|Recent work|graph\.recent|\.recent-in|\.recent\b|'rw'|\.rw\b|Récent|btn-recent" plugin scripts .github DESIGN.md README.md README.fr.md` (hors CHANGELOG), la comparer à la table de 75-RESEARCH § Retrait (numéros de ligne périmés par la 79 et la 80) : toute différence est consignée. Compter les assertions de chaque suite à adapter AVANT. Relever les autres consommateurs de `.cache/changes.json` (écrit par `refresh.mjs:137` « for recent.mjs ») : s'il n'y en a aucun, le dire dans la trace et retirer l'écriture et son commentaire ; sinon la laisser et corriger le commentaire.
</precondition>

<tasks>

<task type="tdd" tdd="true">
  <name>Tâche 1 (tracer) : l'assemblage n'écrit plus `recent-work.json` et supprime l'ancien, la sonde Y reportée sur `.gitignore`</name>
  <files>plugin/cockpit/scripts/vf-cockpit-build.mjs, plugin/cockpit/skills/cockpit-moteur/scripts/build.mjs, plugin/cockpit/scripts/tests/test-cockpit-onglet-code.sh, plugin/cockpit/scripts/tests/test-cockpit-securite.sh, .planning/workstreams/fiabilite/phases/VFDO-75-activite-sur-le-code/75-09a-RED-TRACE.md</files>
  <read_first>
  - plugin/cockpit/scripts/vf-cockpit-build.mjs (l. 70-82 : `recent`, `recent-work.json`, `GITIGNORE`) et le moteur `scripts/build.mjs` (lecture de `recent-work.json`, ligne de rapport)
  - plugin/cockpit/scripts/tests/test-cockpit-securite.sh (série Y, sonde du lien symbolique, l. ~360 à la base) et test-cockpit-onglet-code.sh (C6.3 : lit `recent-work.json`)
  </read_first>
  <behavior>
  - Q1 : un assemblage d'un lab fixture n'écrit AUCUN `recent-work.json` (rouge sur la base : fichier présent) ; un `recent-work.json` laissé par un assemblage antérieur est supprimé (rouge sur la base : conservé) ; la suppression n'a lieu qu'APRÈS `verifierSortie` (un lien symbolique en son lieu est refusé, jamais suivi)
  - Q2 (C6.3 adaptée) : « aucun `recent-work.json` écrit » ET « un plan non fait dont `files_modified` vise un fichier absent donne une carte `st: prevu` » (fixture : ROADMAP non cochée) ; l'intention de C6.3 est remplacée par l'assertion équivalente sur l'empreinte et les prévues, nommée dans la trace
  - Q3 (sonde Y reportée) : lien symbolique posé sur `.gitignore` de la sortie : `verifierSortie` refuse avant toute écriture, `dehors.txt` jamais réécrit ; Y1 et Y2 inchangés ; TÉMOIN ROUGE : `verifierSortie` neutralisé (mutant) : `dehors.txt` réécrit
  - Q4 : le moteur ne lit plus `recent-work.json` ni n'écrit sa ligne de rapport ; son comportement sur un `graph.json` sans `recent` est inchangé (suite du moteur rejouée)
  </behavior>
  <action>
  Étape 0 : en-tête de la trace : inventaire (avant), comptes d'assertions avant par suite.
  Étape 1, témoin : adapter `test-cockpit-securite.sh` (Q3) et `test-cockpit-onglet-code.sh` (Q2), ajouter Q1 et Q4, rouges sur la base. Le compte d'assertions de chaque suite ne baisse pas.
  Étape 2, code : retirer l'écriture de `vf-cockpit-build.mjs:70-80` ; `rmSync(..., {force: true})` du fichier hérité après `verifierSortie` ; retirer la lecture et la ligne de rapport du moteur.
  Mutants : suppression avant `verifierSortie` (Q1 rouge sur lien symbolique), `verifierSortie` neutralisé (Q3 rouge).
  </action>
  <verify>
    <automated>O="${TMPDIR:-/tmp}/75-09a-t1.out"; bash plugin/cockpit/scripts/tests/test-cockpit-securite.sh > "$O" 2>&1 || exit 1; test "$(rtk proxy grep -c '❌ FAIL' "$O")" -eq 0 || exit 1; rtk proxy grep -q 'Résultats : ' "$O" || exit 1; for g in Y1 Y2 Q3; do rtk proxy grep -q "PASS — $g\." "$O" || exit 1; done; test "$(rtk proxy grep -c 'MUTANT-ROUGE' "$O")" -ge 1 || exit 1; O2="${TMPDIR:-/tmp}/75-09a-t1b.out"; bash plugin/cockpit/scripts/tests/test-cockpit-onglet-code.sh > "$O2" 2>&1 || exit 1; test "$(rtk proxy grep -c '❌ FAIL' "$O2")" -eq 0 || exit 1; rtk proxy grep -q 'Résultats : ' "$O2" || exit 1; rtk proxy grep -q "PASS — Q2\." "$O2" || exit 1; bash scripts/check-machine-paths.sh || exit 1</automated>
    <fails_when>le nombre d'assertions d'une suite adaptée baisse (suite affaiblie pour verdir), Q3 reste vert avec `verifierSortie` neutralisé, ou le fichier hérité est supprimé sans passer par `verifierSortie`</fails_when>
  </verify>
  <acceptance_criteria>
  - `75-09a-RED-TRACE.md` contient, pour les deux suites, le compte d'assertions avant et après (après >= avant) et les traces rouges de Q1 (attendu : absent ; obtenu : présent) et de Q3
  - `rtk proxy grep -c "recent-work" plugin/cockpit/scripts/vf-cockpit-build.mjs` rend 1 au plus (la suppression du fichier hérité), 0 dans le moteur
  </acceptance_criteria>
  <done>La couche n'est plus écrite, l'ancienne est effacée, la sonde de lien symbolique protège un autre fichier du socle.</done>
</task>

<task type="tdd" tdd="true">
  <name>Tâche 2 : `recent.mjs`, l'étape de `refresh.mjs`, `recentWork` et la partie d'export retirés</name>
  <files>plugin/cockpit/skills/cockpit-moteur/scripts/recent.mjs, plugin/cockpit/skills/cockpit-moteur/scripts/refresh.mjs, plugin/cockpit/skills/cockpit-moteur/assets/graph-query.js, plugin/cockpit/skills/cockpit-moteur/assets/ui/60-export.js, plugin/cockpit/scripts/tests/test-cockpit-onglet-code.sh, .planning/workstreams/fiabilite/phases/VFDO-75-activite-sur-le-code/75-09a-RED-TRACE.md</files>
  <read_first>
  - plugin/cockpit/skills/cockpit-moteur/scripts/refresh.mjs (l. ~137 écriture de `changes.json` « for recent.mjs », l. ~173 l'étape « Mark recent work »)
  - plugin/cockpit/skills/cockpit-moteur/assets/graph-query.js (l. ~101-102, ~172 : `recentWork`), plugin/cockpit/skills/cockpit-moteur/assets/ui/60-export.js (l. ~35 : « Recent work »)
  </read_first>
  <behavior>
  - Q5 : `scripts/recent.mjs` n'existe plus ; `refresh.mjs` ne mentionne plus `recent.mjs` ni `recent-work.json` (sa sortie ne contient plus l'étape « Mark recent work », rouge sur la base) ; aucun appelant de `recent.mjs` (grep des appelants, vide)
  - Q6 : `graph-query.js` ne porte plus `recentWork`, `60-export.js` plus la partie « Recent work » ; l'export autonome d'un lab ne la contient plus ; les autres parties d'export inchangées (comparaison)
  - Q7 : le grep d'inventaire de la précondition ne rend, pour les fichiers de ce plan, que les exceptions nommées (`serve.mjs`, `references/schema.md`)
  </behavior>
  <action>
  Témoin d'abord (Q5 à Q7, rouges sur la tâche 1 seule), puis retraits. Mutants : étape de `refresh.mjs` conservée (Q5 rouge), `recentWork` conservé (Q6 rouge).
  </action>
  <verify>
    <automated>O="${TMPDIR:-/tmp}/75-09a-t2.out"; bash plugin/cockpit/scripts/tests/test-cockpit-onglet-code.sh > "$O" 2>&1 || exit 1; test "$(rtk proxy grep -c '❌ FAIL' "$O")" -eq 0 || exit 1; rtk proxy grep -q 'Résultats : ' "$O" || exit 1; for g in Q2 Q5 Q6 Q7; do rtk proxy grep -q "PASS — $g\." "$O" || exit 1; done; test "$(rtk proxy grep -c 'MUTANT-ROUGE' "$O")" -ge 2 || exit 1; test ! -e plugin/cockpit/skills/cockpit-moteur/scripts/recent.mjs || exit 1; bash scripts/check-machine-paths.sh || exit 1</automated>
    <fails_when>un appelant de `recent.mjs` subsiste, ou l'étape de `refresh.mjs` guide encore vers un script supprimé</fails_when>
  </verify>
  <acceptance_criteria>
  - la trace consigne les deux mutants et la liste des appelants de `recent.mjs` (vide)
  - `git diff --stat` ne liste ni `viewer.html`, ni `DESIGN.md`, ni `README*`, ni `CHANGELOG.md`
  </acceptance_criteria>
  <done>Le moteur ne produit, ne lit ni ne recommande plus la couche.</done>
</task>

</tasks>

<threat_model>
Suppression d'un fichier de sortie par suivi d'un lien symbolique (V12) : `rmSync` seulement après `verifierSortie`, sonde reportée ; suites affaiblies pour verdir : comptes d'assertions et intention nommée ; chemin du poste dans une trace : relativisé.
</threat_model>

<success_criteria>
ACTV-12, moitié assemblage et moteur : couche retirée, fichier hérité effacé, sonde Y reportée avec témoin rouge, suites adaptées sans perte d'assertion.
</success_criteria>

<output>
`75-09a-SUMMARY.md` ; y consigner l'inventaire avant/après, le sort de `changes.json`, la liste des exceptions restantes du grep.
</output>
